# 📊 Cohort Analysis & Product Metrics (SQL Project)

## 🔍 Overview

This project demonstrates an end-to-end SQL pipeline for cohort analysis using e-commerce data (~10k orders).  

The goal is to analyze user behavior over time and calculate key product metrics such as retention, LTV, ARPU, and churn.

The pipeline is designed to simulate a real-world analytics workflow, including data cleaning, cohort creation, metric calculation, and BI-ready output.

---

## 🧰 Tech Stack

- PostgreSQL
- SQL (window functions, aggregations, joins)
- Power BI / Tableau (for visualization)

---

## 📁 Dataset

- Source: `orders_10k`
- Size: ~10,000 rows
- Key fields:
  - `user_id`
  - `order_date`
  - `total_price`
  - `country`
  - `product_id`

---

## ⚙️ Pipeline Steps

### 1. Data Cleaning
- Removed invalid records:
  - NULL user_id
  - NULL order_date
  - non-positive revenue

---

### 2. First Orders & Cohorts
- Identified the first purchase per user
- Assigned users to **cohorts by month**
- Optional segmentation:
  - by `country`
  - by `product_id`

---

### 3. Lifetime Calculation
- Calculated `month_number`:
  - number of months since first purchase
- Enables tracking user behavior over time (M0, M1, M2, ...)

---

### 4. Cohort Size
- Counted unique users per cohort

---

### 5. Retention Rate
- Formula:

retention = active_users / cohort_size

---

### 6. Revenue
- Aggregated revenue per cohort and month

---

### 7. Metrics Calculation

Combined all metrics into one dataset:

- **Retention Rate**
- **Revenue**
- **LTV (Cumulative Revenue)**  
- **ARPU**

ARPU = revenue / cohort_size

- **Churn**

churn = 1 - retention

---

### 8. BI-ready Pivot

Final dataset contains:

| Metric     | M0 | M1  | M2 | M3  |
|------------|----|-----|----|-----|
| Retention  | ✔️ | ✔️ | ✔️ | ✔️ |
| LTV        | ✔️ | ✔️ | ✔️ | ✔️ |
| ARPU       | ✔️ | ✔️ | ✔️ | ✔️ |
| Churn      | ✔️ | ✔️ | ✔️ | ✔️ |

This format is ready for:
- Heatmaps
- Cohort charts
- Revenue curves

---

## 📈 Example Insights

- Retention typically drops after M1 → common behavior in e-commerce
- Some cohorts generate higher LTV → potential high-value segments
- ARPU trends show monetization dynamics over time
- Churn highlights user drop-off points

---

## 🚀 How to Run

1. Open PostgreSQL / DBeaver
2. Import dataset (`orders_10k`)
3. Run SQL script:


cohort_pipeline.sql


4. Export final table to:
- Power BI / Tableau
- CSV for visualization

---

## 📊 Visualization (Power BI / Tableau)

Recommended dashboards:

- Retention heatmap (Cohort vs Month)
- LTV growth curve
- ARPU trend
- Churn dynamics

---

## 🧠 Key Skills Demonstrated

- Cohort analysis
- Product metrics (LTV, ARPU, retention, churn)
- SQL pipeline design
- Window functions
- Data transformation
- BI data preparation

---

## ⚡ Optimization

- Used TEMP tables for modular pipeline
- Created indexes for scalability:
  - `(user_id, order_date)`
- Designed pipeline to scale to larger datasets

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
