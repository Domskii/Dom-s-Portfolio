
Select *
FROM PortfolioProject..[Nashville-housing]

-- Standardize Date format

Select SaleDateConverted, Convert(Date,Saledate)
FROM PortfolioProject..[Nashville-housing]

Update [Nashville-housing]
SET SaleDate = CONVERT (Date,Saledate)

Alter Table [Nashville-housing]
Add SaledateConverted Date;

Update [Nashville-housing]
Set SaledateConverted = Convert(Date,SaleDate)

--Populate Property Address data
--Join  the table with the same Parcel ID but separate out with UniqueID
Select a.parcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..[Nashville-housing] a
JOIN PortfolioProject..[Nashville-housing] b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[uniqueid]
WHERE a.PropertyAddress is null

--IF Propertyaddress data is null, populate the (Propertyaddress) value from rows with the same ParcelID
Update a
SET Propertyaddress = ISNULL (a.propertyaddress,b.propertyaddress)
FROM PortfolioProject..[Nashville-housing] a
JOIN PortfolioProject..[Nashville-housing] b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null	;


--Breaking out Address into individual columns
-- Propertyaddress contains both address and city information. (,) is the delimiter
Select Propertyaddress
FROM PortfolioProject..[Nashville-housing]

--Testing the code before updating (Using Substring)
SELECT 
SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1) as Address
, SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1, LEN(propertyaddress)) as Address
FROM PortfolioProject..[Nashville-housing]


-- Updating table
ALTER TABLE [Nashville-housing]
Add Split_PropertyAddress nvarchar(255)

Update [Nashville-housing]
SET Split_PropertyAddress = SUBSTRING(PropertyAddress,1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE [Nashville-housing]
Add Split_PropertyCity nvarchar(255)

Update [Nashville-housing]
SET Split_Propertycity = SUBSTRING(PropertyAddress,CHARINDEX(',', PropertyAddress) +1, LEN(propertyaddress))

--Testing
Select *
FROM PortfolioProject..[Nashville-housing]


--Breaking out Owneraddress into individual Columns
Select Owneraddress
From PortfolioProject..[Nashville-housing]

--Testing the code before updating (Using Parsename function)
Select
PARSENAME(REPLACE(Owneraddress,',', '.'), 3),
PARSENAME(REPLACE(Owneraddress,',', '.'), 2),
PARSENAME(REPLACE(Owneraddress,',', '.'), 1)
From PortfolioProject..[Nashville-housing]

-- Updating table
ALTER TABLE [Nashville-housing]
Add Split_OwnerAddress nvarchar(255)

Update [Nashville-housing]
SET Split_OwnerAddress = PARSENAME(REPLACE(Owneraddress,',', '.'), 3)

ALTER TABLE [Nashville-housing]
Add Split_OwnerCity nvarchar(255)

Update [Nashville-housing]
SET Split_OwnerCity = PARSENAME(REPLACE(Owneraddress,',', '.'), 2)

ALTER TABLE [Nashville-housing]
Add Split_OwnerState nvarchar(255)

Update [Nashville-housing]
SET Split_OwnerState = PARSENAME(REPLACE(Owneraddress,',', '.'), 1)

Select*
FROM PortfolioProject..[Nashville-housing]


---------------------------------------------------------------------------------------------------------------------------


-- Change Y and N to YES and No in "Sold as Vacant" field

Select Distinct(SoldASVacant), Count(SoldasVacant)
FROM PortfolioProject..[Nashville-housing]
Group by SoldAsVacant
order by 2

Select SoldasVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
		when Soldasvacant = 'N' THEN 'No'
		Else Soldasvacant
		END
FROM PortfolioProject..[Nashville-housing]

Update [Nashville-housing]
SET SoldasVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		when Soldasvacant = 'N' THEN 'No'
		Else Soldasvacant
		END

Select *
FROM PortfolioProject..[Nashville-housing]

---------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates

WITH RowNum_CTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID) row_num

FROM PortfolioProject..[Nashville-housing])
--ORDER by ParcelID

Select *
FROM RowNum_CTE
where row_num >1
Order by Propertyaddress


--Code to delete duplicates
WITH RowNum_CTE AS(
Select *, 
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY UniqueID) row_num

FROM PortfolioProject..[Nashville-housing])
--ORDER by ParcelID
DELETE 
FROM RowNum_CTE
WHERE row_num > 1



---------------------------------------------------------------------------------------------------------------------------

--Delete Unused Columns

Select *
FROM PortfolioProject..[Nashville-housing]

ALTER TABLE PortfolioProject..[Nashville-housing]
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject..[Nashville-housing]
DROP Column SaleDate
