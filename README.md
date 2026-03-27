# 📊 SQL Cohort Analysis Pipeline (1M+ rows)

## 🚀 Project Overview
This project demonstrates a **production-style SQL analytics pipeline** built on large-scale e-commerce data (~1M rows).

The goal is to transform raw transactional data into **actionable business insights** through cohort analysis.

The pipeline is designed to mimic a real-world analytics workflow used in product and marketing teams.

The pipeline calculates key product and marketing metrics:
- Retention Rate
- Lifetime Value (LTV)
- ARPU (Average Revenue Per User)
- Churn Rate

The final output is a **BI-ready cohort table (M0–M3 format)** suitable for dashboards in Power BI or Tableau.

---

## 💼 Business Value
This analysis helps answer critical business questions:

- How well do we retain users after their first purchase?
- Which cohorts generate the highest revenue over time?
- How quickly do users churn?
- Are there differences in performance across countries?

These insights can be used by:
- Product teams → improve retention
- Marketing teams → evaluate acquisition quality
- Finance teams → forecast revenue (LTV)

---

## ⚙️ Tech Stack
- **PostgreSQL**
- SQL (window functions, aggregations, joins)
- Performance optimization (indexes)
- (Optional) Power BI / Tableau

---

## 📂 Dataset
- `sales` — transactional data (**~1M rows**)
- `stores` — store metadata (country, etc.)

### Key fields:
- `customer_id`
- `order_date`
- `revenue`
- `store_id`
- `country`

---

## ⚡ Performance Optimization
To ensure scalability on a large dataset (~1M rows), indexes were added to improve query performance, window function execution, and aggregations on large datasets

---

## ⚙️ Pipeline Steps

### 1. Data Cleaning
Removed invalid records:
- `revenue <= 0`
- `customer_id IS NULL`
- `order_date IS NULL`

### 2. First Orders & Cohorts
- Identified each customer’s first purchase
- Assigned `cohort_month`
- Added geographic dimension (`country`)

### 3. Customer Lifetime
- Calculated number of months since first purchase (`month_number`)
- Built customer lifecycle timeline

### 4. Cohort Size

Counted unique users per cohort

### 5. Retention

Retention Rate = Active Users / Cohort Size

### 6. Revenue (LTV)

Aggregated revenue per cohort over time

### 7. Final Metrics

ARPU = Revenue / Cohort Size
Churn = 1 - Retention

---

### 8. BI-Ready Output

Final dataset transformed into cohort matrix:

| Metric     | Country | M0 | M1  | M2 | M3  |
|------------|---------|----|-----|----|-----|
| Retention  |         | ✔️ | ✔️ | ✔️ | ✔️ |
| LTV        |         | ✔️ | ✔️ | ✔️ | ✔️ |
| ARPU       |         | ✔️ | ✔️ | ✔️ | ✔️ |
| Churn      |         | ✔️ | ✔️ | ✔️ | ✔️ |

---

## 📸 Example Pivot Table

![Cohort Pivot](images/pivot_table.png)

---

## 📊 Visualization (Power BI / Tableau)

- Retention heatmap (cohort analysis)
- LTV growth curves
- ARPU trends over time
- Churn dynamics

---

## 🧠 Key Skills Demonstrated

- Cohort Analysis (product analytics)
- SQL pipelines (end-to-end data transformation)
- Window functions (ROW_NUMBER, partitions)
- Aggregations & joins on large datasets
- Performance optimization (indexes)
- Data modeling for BI tools

---

## 🚀 How to Run

1. Load data into PostgreSQL:
   - `sales_10k`
   - `stores_10k`
2. Run SQL script:
   cohort_pipeline.sql
3. Query results:
   `SELECT * FROM metrics_temp;`
3. Export final table to:
   - Power BI / Tableau
   - CSV for visualization

---

## 🔥 Impact & Insights (Example)

- Identified retention drop after Month 1 → potential onboarding issue
- Compared cohort performance across countries
- Evaluated revenue contribution over customer lifetime

---

## 🔄 Possible Improvements

- Add A/B testing analysis
- Automate pipeline using Python
- Extend to BigQuery
- Add deeper segmentation (e.g., marketing channels)

---

## 📌 Author

**Yuliia Nadtocha**  
[LinkedIn](https://www.linkedin.com/in/yuliia-nadtocha)
