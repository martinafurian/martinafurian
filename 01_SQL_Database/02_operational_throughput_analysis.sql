-- ====================================================================================
-- PROJECT STAGE 2: OPERATIONAL THROUGHPUT & WORKLOAD ANALYSIS
-- OBJECTIVE: Map Hourly Order Distribution across Departments to Identify Bottlenecks
-- TECHNICAL STACK: Window Functions (COUNT OVER), Hourly Extracting, Dense Ranking
-- ====================================================================================

WITH HourlyLogistics AS (
  SELECT 
    `Department Name` AS department_name,
    -- Extract the hour from the timestamp to analyze shift patterns
    EXTRACT(HOUR FROM `order date _DateOrders_`) AS order_hour,
    `Order Id` AS order_id
  FROM 
    `project-github-furian-martina.supply_chain_project.raw_data`
  WHERE 
    `Order Status` = 'COMPLETE'
),

AggregatedThroughput AS (
  SELECT 
    department_name,
    order_hour,
    COUNT(DISTINCT order_id) AS hourly_orders_processed,
    
    -- Window Function: Calculate total department volume to get hourly weights
    SUM(COUNT(DISTINCT order_id)) OVER(PARTITION BY department_name) AS total_dept_volume
  FROM 
    HourlyLogistics
  GROUP BY 
    department_name, 
    order_hour
)

SELECT 
  department_name,
  order_hour,
  hourly_orders_processed,
  -- Calculate the percentage of daily workload hitting the department in that specific hour
  ROUND((hourly_orders_processed / total_dept_volume) * 100, 2) AS workload_percentage,
  
  -- Rank hours within each department to instantly surface peak activity shifts
  DENSE_RANK() OVER(PARTITION BY department_name ORDER BY hourly_orders_processed DESC) AS peak_hour_rank
FROM 
  AggregatedThroughput
ORDER BY 
  hourly_orders_processed DESC;
