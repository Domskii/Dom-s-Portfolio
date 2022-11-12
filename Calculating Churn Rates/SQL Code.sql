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
  (SELECT id, first_day AS month,segment,
CASE
  WHEN (subscription_start < first_day) AND (subscription_end > first_day) OR (subscription_end IS NULL) THEN 1
  ELSE 0
END AS is_active,
CASE
  WHEN (subscription_end BETWEEN first_day AND last_day) THEN 1 
  ELSE 0
END AS is_cancelled
FROM cross_join),

--Temp table to calculate total active users and total user cancelled for each month
status_aggregate AS
(SELECT month,segment, SUM(is_active) as sum_active,sum(is_cancelled) as sum_cancelled
FROM status
GROUP by month, segment)

--Statement to calculate churn rate
SELECT month, segment, 1.0 * sum_cancelled/sum_active as churn_rate
FROM status_aggregate
ORDER by Segment

/* Output
month	    segment	  churn_rate
2017-01-01	30	    0.0232804232804233
2017-02-01	30	    0.039460020768432
2017-03-01	30	    0.0895522388059701
2017-01-01	87	    0.0882723833543506
2017-02-01	87	    0.167610419026048
2017-03-01	87	    0.33419689119171

Based on the output, we can tell Churn_rate_30 is out-performing Segment 87.
This could imply products in segment 30 is better, or their marketing is working better.
*/
