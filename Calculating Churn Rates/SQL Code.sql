--Calculating the range of data provided
select MIN(subscription_start), max(subscription_start)
from subscriptions

--Creating a temporary months table to segment data into each month
WITH months AS
(SELECT
  '2017-01-01' as first_day,
  '2017-01-31' as last_day
UNION
  SELECT
  '2017-02-01' as first_day,
  '2017-02-28' as last_day
UNION
  SELECT
  '2017-03-01' as first_day,
  '2017-03-31' as last_day),
  
--Cross Joining subscription data with months
cross_join AS
  (SELECT * FROM subscriptions
  CROSS JOIN months
  ),
  
--Creating a status temporary table to see how many are active in each month
status AS
  (SELECT id, first_day AS month,
CASE
  WHEN (subscription_start <      first_day) AND (subscription_end > first_day) OR (subscription_end IS NULL)AND (segment = 87) THEN 1
  ELSE 0
  END AS is_active_87,
CASE 
  WHEN (subscription_start < first_day) AND (subscription_end > first_day) OR (subscription_end IS NULL) AND (segment = 30) THEN 1
    ELSE 0
  END AS is_active_30,
CASE
  WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 87) THEN 1 
  ELSE 0
  END AS is_cancelled_87,
CASE
  WHEN (subscription_end BETWEEN first_day AND last_day) AND (segment = 30) THEN 1 
  ELSE 0
  END AS is_cancelled_30
FROM cross_join),

--Calculating total active users and total user cancelled for each month
status_aggregate AS
(SELECT month, SUM(is_active_87) as sum_active_87,
 sum(is_active_30) as sum_active_30,
 sum(is_cancelled_87) as sum_cancelled_87,
 sum(is_cancelled_30) as sum_cancelled_30
FROM status
GROUP by month)

--Statement to calculate churn rate
SELECT month, 1.0 * sum_cancelled_87/sum_active_87 as Churn_rate_87,
1.0 * sum_cancelled_30/sum_active_30 as Churn_rate_30
FROM status_aggregate

/* Output
month	      Churn_rate_87	      Churn_rate_30
2017-01-01	0.0793650793650794	0.0181219110378913
2017-02-01	0.149494949494949	  0.0287443267776097
2017-03-01	0.302107728337237	  0.0708263069139966
*/
