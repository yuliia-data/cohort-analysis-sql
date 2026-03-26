-- ================================================================
-- Cohort Analysis & Product Metrics (SQL Project)
-- Data: ecommerce_orders_10k (~10k rows)
-- Using TEMP tables for session cleanliness
-- ================================================================
-- Indexes added to demonstrate scalability
CREATE INDEX IF NOT EXISTS idx_orders_user_date
    ON orders_10k(user_id, order_date);
CREATE INDEX IF NOT EXISTS idx_orders_user
    ON orders_10k(user_id);
-- ================================================================
-- Clean Orders
DROP TABLE IF EXISTS clean_orders_temp;
CREATE TEMP TABLE clean_orders_temp AS
SELECT *
FROM orders_10k
WHERE total_price > 0
  AND user_id IS NOT NULL
  AND order_date IS NOT NULL;
-- ================================================================
-- First Orders / Cohorts
DROP TABLE IF EXISTS first_orders_temp;
CREATE TEMP TABLE first_orders_temp AS
SELECT
    user_id,
    order_date AS first_order_date,
    DATE_TRUNC('month', order_date)::date AS cohort_month,
    country,
    product_id
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY order_date, order_id) AS rn
    FROM clean_orders_temp
) t
WHERE rn = 1;
-- ================================================================
-- Lifetime Orders + Month Number
DROP TABLE IF EXISTS lifetime_temp;
CREATE TEMP TABLE lifetime_temp AS
SELECT 
    o.user_id,
    o.order_date,
    o.total_price,
    f.cohort_month,
    f.country,
    f.product_id,
    (DATE_PART('year', o.order_date) - DATE_PART('year', f.cohort_month)) * 12
      + (DATE_PART('month', o.order_date) - DATE_PART('month', f.cohort_month)) AS month_number
FROM clean_orders_temp o
JOIN first_orders_temp f USING(user_id);
-- ================================================================
-- Cohort Size
DROP TABLE IF EXISTS cohort_size_temp;
CREATE TEMP TABLE cohort_size_temp AS
SELECT 
    cohort_month,
    country,
    product_id,
    COUNT(DISTINCT user_id) AS cohort_size
FROM first_orders_temp
GROUP BY cohort_month, country, product_id;
-- ================================================================
-- Retention
DROP TABLE IF EXISTS retention_temp;
CREATE TEMP TABLE retention_temp AS
SELECT
    l.cohort_month,
    l.country,
    l.product_id,
    l.month_number,
    c.cohort_size,
    ROUND(COUNT(DISTINCT l.user_id)::numeric / c.cohort_size, 2) AS retention_rate
FROM lifetime_temp l
JOIN cohort_size_temp c
  ON l.cohort_month = c.cohort_month
 AND l.country = c.country
 AND l.product_id = c.product_id
GROUP BY l.cohort_month, l.country, l.product_id, l.month_number, c.cohort_size;
-- ================================================================
-- Revenue per month
DROP TABLE IF EXISTS revenue_temp;
CREATE TEMP TABLE revenue_temp AS
SELECT
    cohort_month,
    country,
    product_id,
    month_number,
    SUM(total_price) AS revenue
FROM lifetime_temp
GROUP BY cohort_month, country, product_id, month_number;
-- ================================================================
-- Metrics (ARPU, Churn, Cumulative LTV)
DROP TABLE IF EXISTS metrics_temp;
CREATE TEMP TABLE metrics_temp AS
SELECT 
    r.cohort_month,
    r.country,
    r.product_id,
    r.month_number,
    r.cohort_size,
    r.retention_rate,
    rev.revenue,
    SUM(rev.revenue) OVER (PARTITION BY r.cohort_month, r.country, r.product_id ORDER BY r.month_number) AS ltv_cumulative,
    ROUND(rev.revenue * 1.0 / r.cohort_size, 2) AS ARPU,
    ROUND(1 - r.retention_rate, 2) AS churn_rate
FROM retention_temp r
LEFT JOIN revenue_temp rev
  ON r.cohort_month = rev.cohort_month
 AND r.country = rev.country
 AND r.product_id = rev.product_id
 AND r.month_number = rev.month_number
ORDER BY r.cohort_month, r.country, r.product_id, r.month_number;
-- ================================================================
-- Pivot for BI (M0–M3)
SELECT
    cohort_month,
    country,
    product_id,
    -- Retention
    MAX(CASE WHEN month_number = 0 THEN retention_rate END) AS M0_retention,
    MAX(CASE WHEN month_number = 1 THEN retention_rate END) AS M1_retention,
    MAX(CASE WHEN month_number = 2 THEN retention_rate END) AS M2_retention,
    MAX(CASE WHEN month_number = 3 THEN retention_rate END) AS M3_retention,
    -- Cumulative LTV
    MAX(CASE WHEN month_number = 0 THEN ltv_cumulative END) AS LTV_M0,
    MAX(CASE WHEN month_number = 1 THEN ltv_cumulative END) AS LTV_M1,
    MAX(CASE WHEN month_number = 2 THEN ltv_cumulative END) AS LTV_M2,
    MAX(CASE WHEN month_number = 3 THEN ltv_cumulative END) AS LTV_M3,
    -- ARPU
    MAX(CASE WHEN month_number = 0 THEN ARPU END) AS ARPU_M0,
    MAX(CASE WHEN month_number = 1 THEN ARPU END) AS ARPU_M1,
    MAX(CASE WHEN month_number = 2 THEN ARPU END) AS ARPU_M2,
    MAX(CASE WHEN month_number = 3 THEN ARPU END) AS ARPU_M3,
    -- Churn
    MAX(CASE WHEN month_number = 0 THEN churn_rate END) AS Churn_M0,
    MAX(CASE WHEN month_number = 1 THEN churn_rate END) AS Churn_M1,
    MAX(CASE WHEN month_number = 2 THEN churn_rate END) AS Churn_M2,
    MAX(CASE WHEN month_number = 3 THEN churn_rate END) AS Churn_M3
FROM metrics_temp
GROUP BY cohort_month, country, product_id
ORDER BY cohort_month, country, product_id;