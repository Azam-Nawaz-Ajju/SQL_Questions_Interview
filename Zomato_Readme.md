# 🍽️ Zomato Data Analysis – SQL & Python Practice

This repository contains **concept-driven analytical questions** designed around a Zomato-like restaurant dataset. The goal is to practice **SQL (PostgreSQL)** and **Python (Pandas)** concepts commonly tested in **data analyst interviews** and **real-world analytics projects**.

---

## 📂 Dataset Assumptions

Typical columns used across questions:

* `restaurant_id`
* `restaurant_name`
* `country`, `city`, `locality`
* `cuisines`
* `average_cost_for_two`
* `price_range`
* `aggregate_rating`
* `votes`
* `has_table_booking` (Yes/No)
* `has_online_delivery` (Yes/No)
* `is_delivering_now` (Yes/No)
* `created_date` / `opening_date`

> Column names may vary slightly — adapt queries accordingly.

---

## ⭐ 1. Filtering / Selection

**Concepts:** `WHERE`, `LIKE`, `IN`, conditional filtering

* **Q1:** List all restaurants in a specific locality
* **Q2:** Show the name and city of restaurants with a rating lower than 3
* **Q4:** Display restaurants that have an average cost for two less than $50
* **Q5:** Find restaurants with more than 100 votes
* **Q6:** List the names of restaurants offering both table booking and online delivery
* **Q7:** Show the cuisines offered by restaurants in **Paris**
* **Q10:** List all restaurants with **'Cafe'** in their cuisine type
* **Q14:** Display the average rating of **Chinese** cuisine restaurants
* **Q15:** Find the most common price range for restaurants in **London**
* **Q19:** Calculate the percentage of restaurants delivering now in each city
* **Q39:** Calculate the percentage of restaurants in each locality with a rating above **4.5**

---

## 📊 2. Aggregation (COUNT, SUM, AVG)

**Concepts:** `COUNT`, `AVG`, `SUM`, `DISTINCT`

* **Q3:** Count the number of restaurants that do not offer table booking
* **Q8:** Count the number of restaurants in each price range
* **Q11:** Calculate the average votes for restaurants in each locality
* **Q12:** Show the total number of restaurants offering online delivery in each city
* **Q16:** Show the total number of cuisines available in each country
* **Q20:** Show the price range distribution for restaurants in a specific locality
* **Q23:** Show the yearly growth in the number of new cuisines introduced
* **Q25:** Display the change in the number of table booking restaurants over the years
* **Q30:** Calculate the year-over-year growth in the average rating of restaurants
* **Q33:** Find the average time between the opening of new restaurants offering online delivery
* **Q38:** Identify the cities with the highest fluctuation in the number of restaurants

---

## 🧠 3. Grouping & GroupBy

**Concepts:** `GROUP BY`, `HAVING`

* **Q13:** List the cities with the most restaurants offering table booking
* **Q18:** Display the top 5 localities by the number of restaurants they have
* **Q21:** Rank the cities based on the total number of restaurants they have
* **Q24:** List the top 5 cuisines by average cost for two in each country
* **Q29:** Show the total number of **Italian** cuisine restaurants in each price range
* **Q34:** List the localities and their most popular restaurant cuisines

---

## 🏆 4. Sorting & Ranking

**Concepts:** `ORDER BY`, `LIMIT`, `RANK`, `DENSE_RANK`

* **Q9:** Display the top 10 restaurants by rating in a specific country
* **Q22:** Using a CTE, find the localities with the highest average restaurant rating
* **Q28:** Rank countries by the total number of votes received by their restaurants
* **Q32:** Using a CTE, rank restaurants by popularity (votes) within each city
* **Q37:** Rank localities based on the average price range of restaurants

---

## 🔗 5. Join / Subqueries

**Concepts:** `JOIN`, `SUBQUERY`, comparative analysis

* **Q40:** Using subqueries, list cuisines that are **more common in a specific city** than the national average

---

## 🔍 6. Window Functions

**Concepts:** `OVER()`, `PARTITION BY`, `LAG`, `LEAD`

* **Q27:** Calculate the running total of cuisines in each city
* **Q36:** Calculate the month-over-month change in average cost for two

---

## 🗓️ 7. Date / Time & Trend Analysis

**Concepts:** `EXTRACT`, `DATE_TRUNC`, time-series analysis

* **Q23:** Show yearly growth in the number of new cuisines introduced
* **Q25:** Display the change in table booking restaurants over the years
* **Q30:** Calculate year-over-year growth in average ratings
* **Q31:** Identify months with the highest number of new cuisines introduced
* **Q35:** Show the trend in online delivery restaurants over time
* **Q36:** Month-over-month change in average cost for two

---

## 📈 8. Statistical Analysis

**Concepts:** Percentages, variance, fluctuation analysis

* **Q19:** Percentage of restaurants delivering now in each city
* **Q39:** Percentage of high-rated restaurants (>4.5) in each locality
* **Q38:** Cities with the highest fluctuation in restaurant count

---

## 🥇 9. Top / Best / Most Common

**Concepts:** Mode, ranking, frequency analysis

* **Q9:** Top 10 restaurants by rating
* **Q15:** Most common price range in London
* **Q18:** Top 5 localities by restaurant count
* **Q26:** Restaurant with the biggest increase in average cost for two
* **Q34:** Most popular cuisine per locality
* **Q31:** Months with highest new cuisine introductions

---

## 📊 10. Advanced Analytics (YoY / MoM)

**Concepts:** Time-based window functions, trend comparison

* **Q23:** Yearly growth of new cuisines
* **Q30:** Year-over-year growth in average ratings
* **Q36:** Month-over-month cost analysis
* **Q38:** City-wise restaurant count volatility

---

## 🚀 How to Use This Repository

1. Load the dataset into **PostgreSQL**
2. Solve questions using:

   * SQL (`psql`, VS Code PostgreSQL extension)
   * Python (`pandas`, `numpy`)
3. Store solutions in:

   * `/sql/`
   * `/python/`
4. Add insights and optimizations

---

## 🎯 Ideal For

* Data Analyst interviews
* SQL & Python practice
* Portfolio projects
* Dashboard & BI preparation (Power BI / Looker / Tableau)

---
