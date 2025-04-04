-- Define a set of months with their first and last day
WITH months AS (
    SELECT DATE('2017-01-01') AS first_day, DATE('2017-01-31') AS last_day
    UNION
    SELECT DATE('2017-02-01'), DATE('2017-02-28')
    UNION
    SELECT DATE('2017-03-01'), DATE('2017-03-31')
), 

-- Cross join the subscriptions table with the months table to create all possible combinations
cross_join AS (
    SELECT * 
    FROM subscriptions 
    CROSS JOIN months
), 

-- Determine the status of each subscription for each month 
status AS (
    SELECT 
        id,
        first_day AS month, -- Assigning the month's first day as the reference point
        CASE 
            WHEN segment = 87 -- Check if the subscription is active in segment 87
            AND subscription_start < first_day 
            AND (subscription_end IS NULL OR subscription_end > first_day) 
            THEN 1 ELSE 0 
        END AS is_active_87,
        CASE 
            WHEN segment = 30  -- Check if the subscription is active in segment 30
            AND subscription_start < first_day 
            AND (subscription_end IS NULL OR subscription_end > first_day) 
            THEN 1 ELSE 0 
        END AS is_active_30,
        
        -- Check if the subscription was canceled in segment 87 during the month
        CASE 
            WHEN segment = 87 
            AND subscription_end BETWEEN first_day AND last_day 
            THEN 1 ELSE 0 
        END AS is_canceled_87,

         -- Check if the subscription was canceled in segment 30 during the month
        CASE 
            WHEN segment = 30 
            AND subscription_end BETWEEN first_day AND last_day 
            THEN 1 ELSE 0 
        END AS is_canceled_30
    FROM cross_join
), 

-- Aggregate the active and canceled subscriptions per month
status_aggregate AS (
    SELECT 
        month, 
        SUM(is_active_87) AS sum_active_87, 
        SUM(is_active_30) AS sum_active_30, 
        SUM(is_canceled_87) AS sum_canceled_87, 
        SUM(is_canceled_30) AS sum_canceled_30
    FROM status
    GROUP BY month
) 

-- Calculate the churn rate for each segment
SELECT 
    month, 
    100.0 * sum_canceled_30 / CASE WHEN sum_active_30 = 0 THEN NULL ELSE sum_active_30 END AS churn_rate_30,
    100.0 * sum_canceled_87 / CASE WHEN sum_active_87 = 0 THEN NULL ELSE sum_active_87 END AS churn_rate_87
FROM status_aggregate
ORDER BY month;
