# 📊 SQL Window Functions & Advanced Analytics Practice

This repository contains a comprehensive set of **advanced SQL analytical problems** designed to practice **window functions, ranking, cumulative metrics, time-based analysis, and performance optimization**.
All queries can be executed using **SQLite Online**:

🔗 **SQL Editor:** [https://sqliteonline.com/](https://sqliteonline.com/)



## 🧠 Dataset Context

The problems are based on a **DVD Rental–style database**, involving:

# Tables Schema: 
# 📊 SQL Window Functions & Advanced Analytics Practice

This repository contains a **comprehensive collection of advanced SQL analytical problems** designed to strengthen your skills in:

- Window functions
- Ranking & Top-N analysis
- Cumulative & rolling metrics
- Time-based analysis
- Customer behavior analytics
- Performance tuning & indexing

All queries can be executed using **SQLite Online**:

🔗 **SQL Editor:** https://sqliteonline.com/

---

## 🧠 Dataset Context

The problems are based on a **DVD Rental (Sakila-style) database**, commonly used for SQL analytics practice.

The dataset includes information about:
- Movies & categories
- Customers & rentals
- Payments & revenue
- Stores, staff, inventory
- Actors & film participation

---

## 🗄️ Tables Schema (PostgreSQL – Sakila)

```sql
CREATE SCHEMA IF NOT EXISTS sakila;
SET search_path TO sakila;

CREATE TABLE country (
    country_id SMALLINT PRIMARY KEY,
    country VARCHAR(50) NOT NULL,
    last_update TIMESTAMP
);

CREATE TABLE city (
    city_id INT PRIMARY KEY,
    city VARCHAR(50) NOT NULL,
    country_id SMALLINT REFERENCES country(country_id),
    last_update TIMESTAMP
);

CREATE TABLE address (
    address_id INT PRIMARY KEY,
    address VARCHAR(50),
    address2 VARCHAR(50),
    district VARCHAR(20),
    city_id INT REFERENCES city(city_id),
    postal_code VARCHAR(10),
    phone VARCHAR(20),
    last_update TIMESTAMP
);

CREATE TABLE category (
    category_id SMALLINT PRIMARY KEY,
    name VARCHAR(25),
    last_update TIMESTAMP
);

CREATE TABLE actor (
    actor_id INT PRIMARY KEY,
    first_name VARCHAR(45),
    last_name VARCHAR(45),
    last_update TIMESTAMP
);

CREATE TABLE language (
    language_id SMALLINT PRIMARY KEY,
    name VARCHAR(20),
    last_update TIMESTAMP
);

CREATE TABLE film (
    film_id INT PRIMARY KEY,
    title VARCHAR(255),
    description TEXT,
    release_year INT,
    language_id SMALLINT REFERENCES language(language_id),
    rental_duration INT,
    rental_rate NUMERIC(4,2),
    length INT,
    replacement_cost NUMERIC(5,2),
    rating VARCHAR(10),
    last_update TIMESTAMP
);

CREATE TABLE film_actor (
    actor_id INT REFERENCES actor(actor_id),
    film_id INT REFERENCES film(film_id),
    last_update TIMESTAMP,
    PRIMARY KEY (actor_id, film_id)
);

CREATE TABLE film_category (
    film_id INT REFERENCES film(film_id),
    category_id SMALLINT REFERENCES category(category_id),
    last_update TIMESTAMP,
    PRIMARY KEY (film_id, category_id)
);

CREATE TABLE customer (
    customer_id INT PRIMARY KEY,
    store_id INT,
    first_name VARCHAR(45),
    last_name VARCHAR(45),
    email VARCHAR(50),
    address_id INT REFERENCES address(address_id),
    active BOOLEAN,
    create_date DATE,
    last_update TIMESTAMP
);

CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY,
    film_id INT REFERENCES film(film_id),
    store_id INT,
    last_update TIMESTAMP
);

CREATE TABLE rental (
    rental_id INT PRIMARY KEY,
    rental_date TIMESTAMP,
    inventory_id INT REFERENCES inventory(inventory_id),
    customer_id INT REFERENCES customer(customer_id),
    return_date TIMESTAMP,
    staff_id INT,
    last_update TIMESTAMP
);

CREATE TABLE payment (
    payment_id INT PRIMARY KEY,
    customer_id INT REFERENCES customer(customer_id),
    staff_id INT,
    rental_id INT REFERENCES rental(rental_id),
    amount NUMERIC(5,2),
    payment_date TIMESTAMP
);

---

## 📈 Section 1: Cumulative & Running Totals

1. Calculate cumulative rental revenue for each store ordered by payment date
2. Find running total of rentals per customer ordered by rental date
3. Compute cumulative number of rentals per film over time
4. Determine total revenue collected by each staff member (running total)
5. Find running total of rentals per film category ordered by rental date

---

## 📅 Section 2: Date, Time & Period Analysis

6. Number of rentals made each month in 2005
7. Average rental duration per film category
8. Customers renting in the same month across multiple years
9. Day of the week with highest rentals
10. Total revenue per quarter for each store

---

## 🏆 Section 3: Ranking & Top-N Analysis

11. Rank movies by total rental count
12. Top 3 most rented movies per store
13. Rank customers by total spending per store
14. Customer with most rentals each month
15. Staff member with highest revenue per year

---

## 📉 Section 4: Growth, Trends & Comparisons

16. Year-over-Year (YoY) % change in rental revenue
17. Month-over-Month (MoM) change in rental count (last 12 months)
18. YoY rental count change per film category
19. Compare same-month revenue across years
20. Revenue difference between current and previous month per store

---

## 🔄 Section 5: Advanced Cumulative Logic

21. Cumulative revenue per customer (reset after 3 months inactivity)
22. Cumulative rental count per store
23. Running payment total per customer (reset yearly)
24. Cumulative rentals per film (customers with >5 rentals)
25. Rolling 3-month revenue per store (excluding current month)

---

## 👥 Section 6: Customer Behavior & Retention

26. Customer with longest total rental duration
27. Difference between first and last rental per customer
28. Best revenue month per store (only growth years)
29. Movies most rented on Fridays & Saturdays
30. Quarter with highest revenue growth

---

## 🎬 Section 7: Movies, Categories & Inventory

31. Rank customers within store by payments (ties allowed)
32. Top 3 rented movies per category (dense rank)
33. Rank customers by spending (exclude one-time renters)
34. Most rented movie per month
35. Rolling 6-month average rental count per category

---

## 📊 Section 8: Store, Staff & Performance

36. YoY rental growth per store
37. MoM revenue change per staff member
38. YoY change in average rental duration per category
39. Month with biggest rental drop across years
40. Customer spending difference vs previous year

---

## 🧑‍🤝‍🧑 Section 9: Customer Segmentation

41. Customers renting from every category
42. Actors generating highest rental revenue
43. Avg revenue per customer per category (ranked)
44. Customers renting more in last 6 months
45. Store with highest % of one-time renters

---

## 🏪 Section 10: Store & Cross-Store Analysis

46. Customers renting from both stores
47. Top 3 customers per store by revenue
48. Customers renting from ≥3 categories
49. Customers never renting from signup store
50. Customers renting from only one store

---

## 📦 Section 11: Inventory & Availability

51. Movies never rented from a store despite inventory
52. High-rental but low-inventory movies
53. Film availability per store
54. Films most frequently returned late
55. Category with lowest return rate

---

## 🎭 Section 12: Actor-Based Analysis

56. Top 5 rented movies per actor
57. Actors generating most revenue
58. Actor appearing in most rented films
59. Least-rented actor movies (past year)
60. Actors across most categories

---

## 👨‍💼 Section 13: Staff Analytics

61. Staff member with highest total revenue
62. Revenue per staff per store
63. Staff handling most peak-hour rentals
64. Store with highest repeat-customer revenue
65. Store with highest late-fee collection

---

## ⏱️ Section 14: Window Functions (LAG / LEAD / NTILE)

66. Customers renting same actor multiple times
67. Customers renting all store categories
68. Revenue by decade & category
69. Most popular category per store
70. Store with most high-frequency customers
71. Previous & next rental date per customer
72. Time gap between rentals (LAG)
73. Revenue trend using LEAD & LAG
74. Rank films per category (DENSE_RANK)
75. Top 3 customers per store (RANK)
---

## ⚙️ Section 15: Performance & Indexing

76. Top staff per month (DENSE_RANK)
77. Rolling 3-month avg revenue per store
78. Quartile assignment using NTILE(4)
79. Most rented movie per month
80. Customers inactive for last 3 months
81. Queries benefiting from indexes
82. Index optimization on rental_date
83. Performance impact of indexing last_name
84. Inventory_id indexing impact
85. Payment_date indexing for revenue queries

---

## 🔍 Section 16: Advanced Insights

86. Previous & next rental dates per customer
87. Customers with rental gaps >30 days
88. Most recent & second recent rentals
89. Rank customers per store with ties
90. Top 3 frequent renters per store
91. Customer loyalty segmentation
92. Spending growth in last 6 months
93. Repeat film rentals & time gaps
94. First vs most recent rental per customer
95. Customers renting in 3 consecutive months

---

## 📌 Section 17: Final Business Insights

96. Most rented movie per store vs runner-up
97. Avg rental duration (movies with >20 rentals)
98. Movie with highest MoM rental jump
99. Frequently co-rented movies
100. Previous & next rental per film per store
101. High-demand, low-availability films
102. Most popular category per month
103. QoQ revenue change per movie
104. Films rented every month in a year
105. Store with highest % of first-time renters
106. Top revenue staff per store
107. Monthly rentals per staff vs previous month
108. Staff with longest processing gap
109. Stores with 3-month consecutive growth
110. Staff with most late rentals
111. Monthly revenue YoY comparison
112. Months with rental decline %
113. Films with major popularity growth
114. Best revenue month per store
115. Highest & lowest revenue months per category

---

## 🚀 Skills Practiced

* `SUM() OVER()`
* `RANK()`, `DENSE_RANK()`
* `LAG()`, `LEAD()`
* `NTILE()`
* Rolling averages
* Time-series analysis
* Index performance optimization

---

⭐ **Perfect for SQL interviews, analytics portfolios, and advanced practice.**
