-- =========================================
-- SQL Pipeline: Cohort + Retention + Revenue
-- Данные: sales (~1M rows) + stores
-- =========================================

-- Indexes for acceleration
CREATE INDEX IF NOT EXISTS idx_sales_customer_date
    ON sales_10k(customer_id, order_date);
CREATE INDEX IF NOT EXISTS idx_sales_customer
    ON sales_10k(customer_id);
CREATE INDEX IF NOT EXISTS idx_sales_store
    ON sales_10k(store_id);
-- Сlean_sales
DROP TABLE IF EXISTS clean_sales_temp;
CREATE TEMP TABLE clean_sales_temp AS
SELECT *
FROM sales_10k
WHERE revenue > 0
  AND customer_id IS NOT NULL
  AND order_date IS NOT NULL;
-- First_orders
DROP TABLE IF EXISTS first_orders_temp;
CREATE TEMP TABLE first_orders_temp AS
SELECT
    c.customer_id,
    c.order_date AS first_order_date,
    DATE_TRUNC('month', c.order_date)::date AS cohort_month,
    s.country
FROM (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY order_date, order_id) AS rn
    FROM clean_sales_temp
) c
JOIN stores_10k s USING(store_id)
WHERE rn = 1;
-- Orders_lifetime
DROP TABLE IF EXISTS lifetime_temp;
CREATE TEMP TABLE lifetime_temp AS
SELECT 
    o.customer_id,
    o.order_date,
    o.revenue,
    f.cohort_month,
    f.country,
    (DATE_PART('year', o.order_date) - DATE_PART('year', f.cohort_month)) * 12
      + (DATE_PART('month', o.order_date) - DATE_PART('month', f.cohort_month)) AS month_number
FROM clean_sales_temp o
JOIN first_orders_temp f USING(customer_id);
-- Cohort_size
DROP TABLE IF EXISTS cohort_size_temp;
CREATE TEMP TABLE cohort_size_temp AS
SELECT 
    cohort_month,
    country,
    COUNT(DISTINCT customer_id) AS cohort_size
FROM first_orders_temp
GROUP BY cohort_month, country;
-- Retention
DROP TABLE IF EXISTS retention_temp;
CREATE TEMP TABLE retention_temp AS
SELECT
    l.cohort_month,
    l.country,
    l.month_number,
    c.cohort_size,
    ROUND(COUNT(DISTINCT l.customer_id)::numeric / c.cohort_size, 2) AS retention_rate
FROM lifetime_temp l
JOIN cohort_size_temp c
  ON l.cohort_month = c.cohort_month
 AND l.country = c.country
GROUP BY l.cohort_month, l.country, l.month_number, c.cohort_size;
-- Revenue
DROP TABLE IF EXISTS revenue_temp;
CREATE TEMP TABLE revenue_temp AS
SELECT
    cohort_month,
    country,
    month_number,
    SUM(revenue) AS revenue
FROM lifetime_temp
GROUP BY cohort_month, country, month_number;
-- Metrics
DROP TABLE IF EXISTS metrics_temp;
CREATE TEMP TABLE metrics_temp AS
SELECT r.*,
       rev.revenue,
       ROUND(rev.revenue * 1.0 / r.cohort_size, 2) AS ARPU,
       1 - r.retention_rate AS churn_rate
FROM retention_temp r
LEFT JOIN revenue_temp rev
  ON r.cohort_month = rev.cohort_month
 AND r.country = rev.country
 AND r.month_number = rev.month_number
ORDER BY r.cohort_month, r.country, r.month_number;
-- Pivot for BI
SELECT
    cohort_month AS cohort,
    country AS country,
    MAX(CASE WHEN month_number = 0 THEN retention_rate END) AS M0_ret,
    MAX(CASE WHEN month_number = 1 THEN retention_rate END) AS M1_ret,
    MAX(CASE WHEN month_number = 2 THEN retention_rate END) AS M2_ret,
    MAX(CASE WHEN month_number = 3 THEN retention_rate END) AS M3_ret,
    SUM(CASE WHEN month_number = 0 THEN revenue END) AS LTV_M0,
    SUM(CASE WHEN month_number = 1 THEN revenue END) AS LTV_M1,
    SUM(CASE WHEN month_number = 2 THEN revenue END) AS LTV_M2,
    SUM(CASE WHEN month_number = 3 THEN revenue END) AS LTV_M3,
    MAX(CASE WHEN month_number = 0 THEN ARPU END) AS ARPU_M0,
    MAX(CASE WHEN month_number = 1 THEN ARPU END) AS ARPU_M1,
    MAX(CASE WHEN month_number = 2 THEN ARPU END) AS ARPU_M2,
    MAX(CASE WHEN month_number = 3 THEN ARPU END) AS ARPU_M3,
   -MAX(CASE WHEN month_number = 0 THEN churn_rate END) AS Churn_M0,
    MAX(CASE WHEN month_number = 1 THEN churn_rate END) AS Churn_M1,
    MAX(CASE WHEN month_number = 2 THEN churn_rate END) AS Churn_M2,
    MAX(CASE WHEN month_number = 3 THEN churn_rate END) AS Churn_M3
FROM metrics_temp
GROUP BY cohort_month, country
ORDER BY cohort_month, country;
