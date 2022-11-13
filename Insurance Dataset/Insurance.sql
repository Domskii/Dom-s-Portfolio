CREATE PROCEDURE SPGetOutstandingRTPublish (
	@DaysToComplete as INT = null
	,@DaysOverdue as INT = NULL
	,@Office AS VARCHAR(31) = NULL
	,@ManagerCode AS VARCHAR(31) = NULL
	,@SupervisorCode AS VARCHAR(31) = NULL
	,@ExaminerCode AS VARCHAR(31) = NULL
	,@Team AS VARCHAR(250) = NULL
	,@ClaimsWithoutRTPublish AS BIT = 0
)
As
BEGIN
		DECLARE @DateAsOf DATE
		SET @DateAsOf = '1/1/2019'

		DECLARE @ReservingToolPbl TABLE
		(
			Claimnumber VARCHAR(30)
			, LastPublishedDate DATETIME
		)

		DECLARE @AssignedDateLog Table
		(
			PK INT
			, ExaminerAssignedDate DATETIME
		)

		--The last date an examiner published on the Reserving Tool for each Claim
		Insert Into @ReservingToolPbl
		SELECT ClaimNumber, max(EnteredOn) as LastPublished
		FROM ReservingTool
		WHERE IsPublished = 1
		Group by ClaimNumber

		--The date an examiner was assigned a claim
		Insert INTO @AssignedDateLog
		SELECT PK, max(entrydate) as ExaminerAssignedDate
		FROM claimlog
		WHERE FieldName = 'ExaminerCode'
		GROUP BY PK

	SELECT *
	FROM 
	(
		--Gather information on underlying claims - Joining different tables & Filtering out irrelevant information
		SELECT ClaimNumber, 
		ManagerCode,ManagerTitle,ManagerFullName,
		SupervisorCode,supervisorTitle,SupervisorFullName,
		ExaminerCode,ExaminerTitle,ExaminerFullName,
		OfficeDesc, ClaimStatusDesc, FirstName, LastName, ClaimantTypeDesc, ExaminerAssignedDate, ReopenedDate,
		AdjustedassignedDAte, LastpublishedDate, DaysSinceAdjustedAssignedDate, DaysSinceLastPublishedDate,
		CASE WHEN DaysSinceAdjustedAssignedDate > 14 AND (DaysSinceLastPublishedDate > 90 OR DaysSinceLastPublishedDate is null) THEN 0
			WHEN 91 - DaysSinceLastPublishedDate >= 15 - DaysSinceAdjustedAssignedDate AND DaysSinceLastPublishedDate is not null
			THEN 91 - DaysSinceLastPublishedDate ELSE 15 - DaysSinceAdjustedAssignedDate END AS DaysToComplete,

		CASE WHEN DaysSinceAdjustedAssignedDate <= 14 OR (DaysSinceLastPublishedDate <= 90 AND DaysSinceLastPublishedDate is not null) THEN 0 
			WHEN DaysSinceLastPublishedDate - 90 <= DaysSinceAdjustedAssignedDate - 14 AND DaysSinceLastPublishedDate is not null
				THEN DaysSinceLastPublishedDate - 90 
				ELSE DaysSinceAdjustedAssignedDate - 14 END AS DaysOverDue
		FROM
		(
		SELECT C.ClaimNumber, O.OfficeDesc, O.State, 
		U.LastFirstName as ExaminerFullName, U.UserName as ExaminerCode, U.Title as ExaminerTitle, 
		U2.LastFirstName as SupervisorFullName, U2.UserName as SupervisorCode, U2.Title as supervisorTitle,
		U3.LastFirstName as ManagerFullName, U3.UserName as ManagerCode, U3.Title as ManagerTitle,
		CLS.ClaimStatusDesc, P.FirstName, P.LastName, CL.ReopenedDate, CLT.ClaimantTypeDesc, 
		ADL.ExaminerAssignedDate, 
		CASE WHEN CLS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN
			CL.ReopenedDate ELSE ADL.ExaminerAssignedDate END AS AdjustedassignedDAte,
		RTP.LastPublishedDate,
		CASE WHEN CLS.ClaimStatusDesc = 'Re-Open' AND CL.ReopenedDate > ADL.ExaminerAssignedDate THEN
			DATEDIFF(DAY,ReopenedDate,@DateAsOf)
			ELSE DATEDIFF(DAY,ExaminerAssignedDate,@DateAsOf)
			END AS DaysSinceAdjustedAssignedDate,
			DATEDIFF(DAY,LastPublishedDate,@DateAsOf) as DaysSinceLastPublishedDate,
			U.ReserveLimit, R.ReserveAmount,
			CASE
				WHEN RT.parentID IN (1,2,3,4,5) THEN RT.ParentID
				ELSE RT.ReserveTypeID
				END as ReserveTypeBucketID
		FROM Claimant CL
		JOIN Claim C ON C.ClaimID = CL.ClaimID
		JOIN USERS U ON U.UserName = C.ExaminerCode
		JOIN USERS U2 ON U2.UserName = U.Supervisor
		JOIN USERS U3 ON U3.UserName = U2.Supervisor
		JOIN OFFICE O ON O.OfficeID = U.OfficeID
		JOIN CLAIMSTATUS CLS ON CLS.ClaimStatusID = CL.claimStatusID
		JOIN ClaimantType CLT ON CLT.ClaimantTypeID = CL.ClaimantTypeID
		JOIN PATIENT P ON P.PatientID = CL.PatientID
		JOIN RESERVE R ON R.ClaimantID = CL.ClaimantID
		JOIN ReserveType RT ON RT.ReservetypeID = R.ReserveTypeID
		LEFT JOIN @ReservingToolPbl RTP ON C.ClaimNumber = RTP.Claimnumber
		JOIN @AssignedDateLog ADL ON C.ClaimID = ADL.PK
		WHERE O.OfficeDesc IN ('San Francisco', 'San Diego','Sacramanto') AND
		(RT.reserveTypeID IN (1,2,3,4,5) OR rt.ParentID IN (1,2,3,4,5))
		AND (CL.claimstatusid = 1 or  (CL.claimstatusID = 2 AND CL.ReopenedReasonID != 3))
		) Basedata
		--Pivoting ReserveTypeBucketID & Amount
		PIVOT 
		 (Sum(ReserveAmount)
			FOR ReserveTypeBucketID IN ([1],[2],[3],[4],[5])
		) PivotTable
		/* Only keep the claim in the results if one of the following is true
		1. Claimant type is either Medical only or first Aid
		2. The examiner is greater tha nthe examiner's reserve limit
		3. The examiner is in either Sacramento or San Francisco, and at least one of:
			a. The total medical reserves (Reserve Bucket 1) is greater than 800
			b. The totla expensive reserves (Reserve Bucket 5) is greater than 100
			c. There are positive reserves in any of the remaining reserve buckets (TD, PD, Rehab) */
		WHERE Pivottable.ClaimantTypeDesc IN ('First Aid', 'Medical-Only')
			OR (PivotTable.OfficeDesc = 'San Diego' AND ISNULL([1],0) + ISNULL([2],0) + ISNULL([3],0) + ISNULL([4],0) + ISNULL([5],0)
			 >= PivotTable.ReserveLimit)
			OR (PivotTable.OfficeDesc IN ('Sacramento','San Francisco') AND 
			(ISNULL([1],0) > 800 OR ISNULL([5],0) > 100 OR ISNULL([2],0) > 0 OR ISNULL([3],0) > 0 OR ISNULL([4],0) > 0))

	) MainQuery
WHERE (@DaysTocomplete IS Null or DaysToComplete <= @DaysToComplete)
		AND (@DaysOverdue IS Null or DaysOverdue = @DaysOverdue)
		AND (@Office IS NULL OR OfficeDesc = @Office)
		AND (@ExaminerCode IS NULL OR ExaminerCode = @ExaminerCode)
		AND (@SupervisorCode IS NULL OR SupervisorCode = @SupervisorCode)
		AND (@ManagerCode IS NULL OR ManagerCode= @ManagerCode)
		AND (@Team IS NULL OR ExaminerTitle Like '%' + @Team + '%'
				OR SupervisorTitle Like '%' + @Team + '%'
				OR ManagerTitle Like '%' + @Team + '%')
		AND (@ClaimsWithoutRTPublish = 0 OR LastPublishedDate IS NULL)

END
