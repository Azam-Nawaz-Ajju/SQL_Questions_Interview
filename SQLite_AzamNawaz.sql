-- 1. Cumulative / Running Totals (Window Functions)
    -- These involve SUM() OVER(), COUNT() OVER(), or other cumulative calculations.

-- Q1: Cumulative rental revenue for each store, ordered by payment date
SELECT
    s.store_id,
    p.payment_date,
    p.amount,
    SUM(p.amount) OVER (PARTITION BY s.store_id ORDER BY p.payment_date) AS cumulative_revenue
FROM payment p
JOIN staff st ON p.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
ORDER BY s.store_id, p.payment_date;

-- Q2: Running total of rentals per customer, ordered by rental date
select customer_id,rental_date,
count(*) over (partition by customer_id order by rental_date) as running_rentals from rental
ORDER by customer_id,rental_date;
-- Q3: Cumulative number of rentals per film over time
select i.film_id, r.rental_date, count(*) OVER (partition by i.film_id order by rental_date) as cum_total_rentals 
from rental r
LEFT join inventory i 
on r.inventory_id = i.inventory_id;
-- Q4: Total revenue collected by each staff member, maintaining a running total
select staff_id, payment_date, 
amount,
sum(amount) over (partition by staff_id order by payment_date) as running_revenue 
from payment;

-- Q5: Running total of rentals per film category, ordered by rental date
select fc.category_id,r.rental_date, count(r.rental_id) OVER (partition by fc.category_id order by r.rental_date) as running_tot_rentals
from rental r
join inventory i on r.inventory_id = i.inventory_id
JOIN film_category fc on i.film_id = fc.film_id;

-- Q22: Cumulative rental count per store, partitioned by store, ordered by rental date
select r.rental_date, s.store_id,
count(r.rental_id) over (PARTITION by s.store_id order by r.rental_date) as cumm_rentals

from rental r
join staff st on r.staff_id = st.staff_id
join store s on st.store_id = s.store_id

-- Q23: Running total of payments per customer, ordered by payment date, reset at start of year

select customer_id, payment_date,
sum(amount) over (PARTITION by customer_id, strftime('%Y', payment_date) order by payment_date) as running_total_payments
from payment

-- Q24: Cumulative rental count per film, considering customers with more than 5 rentals
with cust_morethan_5 as 
(
select customer_id,count(*) as total_rents_cust
from rental
group by 1
having count(*) > 5
)

select r.inventory_id,
count(*) over (PARTITION by r.inventory_id order by r.rental_date) as cumm_running_total_film
from rental r
join cust_morethan_5 c
on r.customer_id = c.customer_id


-- Q25: Rolling 3-month total revenue per store, excluding current month


WITH monthly_revenue AS (
    SELECT
        r.store_id,
        CAST(strftime('%Y', p.payment_date) AS INTEGER) AS revenue_year,
        CAST(strftime('%m', p.payment_date) AS INTEGER) AS revenue_month,
        SUM(p.amount) AS total_revenue
    FROM payment p
    JOIN rental r
        ON p.rental_id = r.rental_id
    GROUP BY r.store_id, revenue_year, revenue_month
)

SELECT
    store_id,
    revenue_year,
    revenue_month,
    SUM(total_revenue) OVER (
        PARTITION BY store_id
        ORDER BY revenue_year, revenue_month
        ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
    ) AS rolling_3_month_revenue
FROM monthly_revenue
ORDER BY store_id, revenue_year, revenue_month;
 
-- Q21: Cumulative revenue per customer, resetting if no rental in 3 months

WITH payments_with_lag AS (
    SELECT
        customer_id,
        payment_date,
        amount,
        LAG(payment_date) OVER (
            PARTITION BY customer_id
            ORDER BY payment_date
        ) AS prev_payment_date
    FROM payment
),
reset_flags AS (
    SELECT
        customer_id,
        payment_date,
        amount,
        CASE
            WHEN prev_payment_date IS NULL THEN 0
            WHEN julianday(payment_date) - julianday(prev_payment_date) > 90 THEN 1
            ELSE 0
        END AS reset_flag
    FROM payments_with_lag
),
reset_groups AS (
    SELECT
        customer_id,
        payment_date,
        amount,
        SUM(reset_flag) OVER (
            PARTITION BY customer_id
            ORDER BY payment_date

        ) AS reset_group
    FROM reset_flags
)
SELECT
    customer_id,
    payment_date,
    SUM(amount) OVER (
        PARTITION BY customer_id, reset_group
        ORDER BY payment_date

    ) AS cumulative_revenue
FROM reset_groups
ORDER BY customer_id, payment_date;



-- ======================================================================

                                GROUP B

-- ======================================================================


-- 2. Aggregation (SUM, AVG, COUNT, MIN, MAX, GROUP BY)
        --> These use basic aggregate functions without window partitions.

--6. Find the number of rentals made each month in the year 2005. 
SELECT strftime('%Y', rental_date) as Year, strftime('%m',rental_date) as Month, count(*) as total_rents
from rental
WHERE strftime('%Y', rental_date) = '2005'
group by Month
;

--7. Determine the average rental duration per film category, considering the rental and return dates. 
select fc.category_id,     AVG(
        julianday(r.return_date) - julianday(r.rental_date)
    ) AS avg_rental_duration_days
FROM rental r
join inventory i on r.inventory_id = i.inventory_id
JOIN film_category fc on i.film_id = fc.film_id
JOIN film f on fc.film_id = f.film_id
where return_date is NOT NULL
group by 1;

-- Q10: Total revenue per quarter for each store

SELECT
    s.store_id,
    strftime('%Y', p.payment_date) AS year,
    ((CAST(strftime('%m', p.payment_date) AS INTEGER) - 1) / 3) + 1 AS quarter,
    SUM(p.amount) AS total_revenue
FROM payment p
JOIN staff st ON p.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
GROUP BY s.store_id, year, quarter
ORDER BY s.store_id, year, quarter;

-- Q12: Top 3 most rented movies per store (requires aggregation + ranking)

with rentals_per_store as 
(select s.store_id,i.film_id,f.title,
count(r.rental_id) as total_rents,
dense_rank() over (PARTITION by s.store_id order by count(r.rental_id) desc) as rnk
from rental r
join inventory i on r.inventory_id = i.inventory_id
join staff st on r.staff_id = st.staff_id
join store s on st.store_id = s.store_id
join film f on i.film_id = f.film_id
group by 1,2,3
)
select store_id,film_id,title, total_rents
from rentals_per_store
where rnk <= 3;


-- Q14: Customer who rented the most movies each month
select customer_id, 
strftime('%m',rental_date) as month,count(rental_id) as total_rents,
row_number() over (PARTITION by strftime('%m',rental_date) order by count(rental_id)) as rank
from rental
group by 1,2


-- Q16: YoY percentage change in rental revenue
WITH Yearly_revenue as 
(
    SELECT 
        strftime('%Y',payment_date) as Year, count(rental_id) as total_rents, SUM(amount) as total_revenue
    FROM payment
    GROUP BY strftime('%Y',payment_date)
)
SELECT Year,total_rents,((Total_revenue - LAG(Total_revenue) OVER (ORDER BY YEAR) )/(LAG(Total_revenue) OVER (ORDER BY YEAR)) )*100 as YOy_change
from yearly_revenue


-- Q17: MoM change in rental count for the last 12 months

WITH monthly_rentals AS (
    SELECT
        strftime('%Y-%m', rental_date) AS month,
        COUNT(rental_id) AS total_rents
    FROM rental
    WHERE rental_date <= '2006-01-01'
    GROUP BY strftime('%Y-%m', rental_date)
),
mom_change AS (
    SELECT
        month,
        total_rents,
        LAG(total_rents) OVER (ORDER BY month) AS prev_month_rents,
        total_rents - LAG(total_rents) OVER (ORDER BY month) AS mom_change
    FROM monthly_rentals
)
SELECT *
FROM mom_change
ORDER BY month;

-- Q18: YoY change in number of rentals per film category
WITH rental_per_filmCategory as 
(
    SELECT 
        strftime('%Y',r.rental_date) as rental_year,
        fc.category_id,
        COUNT(r.rental_id) as total_rents
    FROM rental r 
    JOIN  inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film_category fc 
        ON i.film_id = fc.film_id
    GROUP by strftime('%Y',r.rental_date), fc.category_id
)
SELECT 
    rental_year,
    category_id, 
    total_rents,
    LAG(total_rents) OVER (PARTITION BY category_id ORDER BY rental_year) as prev_year_total_rents,
    total_rents - LAG(total_rents) OVER (PARTITION BY category_id ORDER BY rental_year) as yoy_change_total
FROM rental_per_filmCategory;

-- Q19: Compare monthly revenue for same month across different years
WITH revenue_year_month as 
(
    SELECT 
        strftime('%Y',payment_date) as payment_year, 
        strftime('%m',payment_date) as payment_month, 
        sum(amount) as total_revenue
    FROM payment p
    GROUP BY strftime('%Y-%m',payment_date),strftime('%m',payment_month)
) 
SELECT 
    payment_year, 
    payment_month,
    total_revenue, 
    total_revenue - LAG(total_revenue) OVER (PARTITION BY payment_month ORDER BY payment_year) as prev_month_revenue_change
FROM revenue_year_month;


-- Q20: Difference in rental revenue between current and previous month per store
WITH month_rental_revenue as 
(
    SELECT 
        s.store_id, 
        strftime('%m',r.rental_date) as rental_month,
        strftime('%Y',r.rental_date) as rental_year,
        count(r.rental_id) as total_rents,
        sum(p.amount) as rental_revenue
    FROM rental r
    JOIN staff st 
        ON r.staff_id = st.staff_id
    JOIN payment p
        ON r.rental_id = p.rental_id
    JOIN store s
        ON st.store_id = s.store_id
    GROUP by  s.store_id, strftime('%m',r.rental_date),strftime('%Y',r.rental_date) 
)

SELECT store_id, rental_month,rental_year,total_rents,rental_revenue, 
LAG(rental_revenue) OVER (PARTITION BY store_id,rental_year  ORDER BY rental_year) as lag_revenue
FROM month_rental_revenue


-- Q26: Customer who rented movies for the longest total duration
SELECT 
    r.customer_id,c.first_name,c.last_name,
    CAST(sum(julianday(return_date) - julianday(rental_date)) as INTEGER)  as rented_duration 

FROM rental r
JOIN customer c
    ON r.customer_id = c.customer_id
GROUP BY r.customer_id,c.first_name,c.last_name
ORDER BY rented_duration
LIMIT 1


-- Q27: Difference in days between first and last rental per customer
WITH diff_days as 
(
    SELECT 
        customer_id, 
        min(rental_date) as first_rental_date, 
        max(rental_date) as last_rental_date
    
    FROM rental
    GROUP BY customer_id
)
SELECT 
    customer_id,
    CAST((julianday(last_rental_date) - julianday(first_rental_date)) as INTERGER)  as days_diff
FROM diff_days
ORDER BY 2 DESC


-- Q28: Month with highest rental revenue for each store, considering only years with revenue growth

WITH yearly_revenue as 
(
    SELECT 
        s.store_id, 
        strftime('%Y', p.payment_date) as payment_year, 
        sum(p.amount) as rental_revenue
    FROM rental r 
    JOIN payment p
        ON r.rental_id = P.rental_id
    JOIN staff st
        ON p.staff_id = st.staff_id
    JOIN store s 
        ON st.store_id = s.store_id
    GROUP BY s.store_id, strftime('%m', p.payment_date) 
),

yearly_growth as 
(
    SELECT 
        store_id, 
        payment_year, 
        rental_revenue, 
        lag(rental_revenue) OVER (PARTITION BY store_id ORDER BY payment_year) as prev_year_revenue
    FROM yearly_revenue

),
yearly_rev_growth as 
(
    SELECT store_id, payment_year
    FROM yearly_growth
    WHERE prev_year_revenue IS NOT NULL 
    AND rental_revenue > prev_year_revenue
), 
monthly_revenue AS (
    SELECT

-- Q30: Total revenue per quarter and quarter with highest increase vs previous quarter
WITH quarterly_revenue AS (
    SELECT
        CAST(strftime('%Y', payment_date) AS INTEGER) AS revenue_year,
        CAST(strftime('%m', payment_date) AS INTEGER) AS revenue_month,
        ( (CAST(strftime('%m', payment_date) AS INTEGER) - 1) / 3 + 1 ) AS revenue_quarter,
        SUM(amount) AS total_revenue
    FROM payment
    GROUP BY revenue_year, revenue_quarter
),

quarterly_diff AS (
    SELECT
        revenue_year,
        revenue_quarter,
        total_revenue,
        total_revenue - LAG(total_revenue) OVER (
            ORDER BY revenue_year, revenue_quarter
        ) AS revenue_change
    FROM quarterly_revenue
)

SELECT
    revenue_year,
    revenue_quarter,
    total_revenue,
    revenue_change
FROM quarterly_diff
ORDER BY revenue_change DESC
LIMIT 1; 

-- Q35: Rolling 6-month average rental count for each category
WITH rental_count_month as 
(
    SELECT 
        fc.category_id, 
        strftime('%Y-%m', rental_date) as year_month,
        count(r.rental_id) as rental_count
    FROM rental r
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film_category fc 
        ON i.film_id = fc.film_id
    GROUP BY fc.category_id,strftime('%Y-%m', rental_date)
),
row_numbers as 
(
SELECT 
    category_id,
    year_month, 
    rental_count, 
    ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY year_month) as rn 
FROM rental_count_month
)

SELECT category_id, year_month,rental_count,
    AVG(rental_count) OVER (PARTITION BY category_id ORDER BY rn
    ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
        ) as rolling_avg
FROM row_numbers



-- Q36: YoY % change in number of rentals per store, find stores with highest growth

WITH store_rentals AS (
    SELECT
        s.store_id,
        CAST(strftime('%Y', r.rental_date) AS INTEGER) AS rental_year,
        COUNT(*) AS rental_count
    FROM rental r
    JOIN staff st   
        ON r.staff_id = st.staff_id
    JOIN store s 
        ON st.store_id = s.store_id
    GROUP BY s.store_id, rental_year
),

store_rentals_yoy AS (
    SELECT
        store_id,
        rental_year,
        rental_count,
        LAG(rental_count) OVER (
            PARTITION BY store_id
            ORDER BY rental_year
        ) AS prev_year_count
    FROM store_rentals
)

SELECT
    store_id,
    rental_year,
    rental_count,
    prev_year_count,
    CASE
        WHEN prev_year_count IS NULL THEN NULL
        ELSE ROUND( (rental_count - prev_year_count) * 100.0 / prev_year_count, 2)
    END AS yoy_pct_change
FROM store_rentals_yoy
ORDER BY yoy_pct_change DESC


-- Q37: MoM change in total revenue per staff member, ordered by payment date

WITH staff_revenue as 
(
    SELECT 
        st.staff_id,
        --p.payment_date,
        strftime('%Y', payment_date) as payment_year,
        strftime('%m', payment_date) as payment_month,
        sum(amount) as total_revenue 
    FROM payment p 
    JOIN staff st 
        ON p.staff_id = st.staff_id
    GROUP BY st.staff_id, 
    --p.payment_date, 
    strftime('%Y-%m', payment_date)
)
SELECT 
    staff_id, 
    payment_year,
    payment_month, 
    total_revenue, 
    LAG(total_revenue) OVER (PARTITION BY staff_id ORDER BY payment_year, payment_month) as lag_rental_revenue,
    total_revenue - LAG(total_revenue) OVER (PARTITION BY staff_id ORDER BY payment_year, payment_month) as change
FROM staff_revenue
;

-- Q38: YoY change in average rental duration per category
WITH rental_duration AS (
    SELECT 
        fc.category_id,
        CAST(strftime('%Y', r.rental_date) AS INTEGER) AS rental_year,
        julianday(r.return_date) - julianday(r.rental_date) AS days_diff
    FROM rental r
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
    JOIN film_category fc
        ON i.film_id = fc.film_id
   -- WHERE r.return_date IS NOT NULL
),

avg_rental_duration_per_year AS (
    SELECT 
        category_id,
        rental_year,
        AVG(days_diff) AS avg_rental_duration
    FROM rental_duration
    GROUP BY category_id, rental_year
)

SELECT 
    category_id,
    rental_year,
    avg_rental_duration,
    avg_rental_duration - LAG(avg_rental_duration)
          OVER (PARTITION BY category_id ORDER BY rental_year) AS yoy_change
FROM avg_rental_duration_per_year
ORDER BY category_id, rental_year;

-- Q39: Compare monthly rental count for same month across years, find month with biggest drop

WITH monthly_rentals AS 
(
    SELECT 
        CAST(strftime('%Y', rental_date) AS INTEGER) AS rental_year,
        CAST(strftime('%m', rental_date) AS INTEGER) AS rental_month,
        COUNT(*) AS rental_count
    FROM rental
    GROUP BY rental_year, rental_month
),

monthly_diff AS (
    SELECT
        rental_month,
        rental_year,
        rental_count,
        rental_count - LAG(rental_count) OVER (
            PARTITION BY rental_month
            ORDER BY rental_year
        ) AS diff_from_prev_year
    FROM monthly_rentals
)

SELECT
    rental_month,
    rental_year,
    rental_count,
    diff_from_prev_year
FROM monthly_diff
ORDER BY diff_from_prev_year ASC
LIMIT 1;


-- Q40: Difference in customer spending compared to previous year (only for recurring customers)

WITH recurring_customers as 
(
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    HAVING count(strftime('%Y',payment_date)) > 1
), 
cust_spend as 
(
    SELECT  strftime('%Y', p.payment_date) as payment_year, 
    sum(p.amount) as amount_spent
    FROM payment p 
    JOIN recurring_customers rc 
        ON p.customer_id = rc.customer_id
    GROUP BY strftime('%Y',p.payment_date) 
    
)

SELECT payment_year, amount_spent- LAG(amount_spent) OVER (ORDER BY payment_year) as change
FROM cust_spend


-- Q43: Average revenue per customer per film category, rank customers within category

WITH avg_revenue as 
(
SELECT 
    fc.category_id,
    r.customer_id,  
    avg(p.amount) as revenue

FROM payment p
JOIN rental r 
    ON p.rental_id = r.rental_id
JOIN inventory i 
    ON r.inventory_id = i.inventory_id
JOIN film_category fc 
    ON i.film_id = fc.film_id
GROUP BY fc.category_id, r.customer_id
)

SELECT 
    category_id, 
    customer_id, 
    revenue,
    RANK() OVER (PARTITION BY category_id ORDER BY revenue DESC) as rank 
FROM avg_revenue

-- Q44: Customers who rented more in last 6 months than previous 6 months

WITH rental_counts AS (
    SELECT
        customer_id,
        SUM(
            CASE 
                WHEN rental_date >= DATE('now', '-6 months') 
                THEN 1 ELSE 0 
            END
        ) AS last_6_months,
        SUM(
            CASE 
                WHEN rental_date >= DATE('now', '-12 months')
                 AND rental_date <  DATE('now', '-6 months')
                THEN 1 ELSE 0 
            END
        ) AS prev_6_months
    FROM rental
    GROUP BY customer_id
)

SELECT
    customer_id,
    last_6_months,
    prev_6_months
FROM rental_counts
WHERE last_6_months > prev_6_months
ORDER BY customer_id;

-- Q68: Total revenue by movies released in each decade, broken down by category

SELECT 
    ((CAST(strftime('%Y', p.payment_date) as INTEGER))/10 ) * 10 as payment_year, 
    fc.category_id, 
    sum(p.amount) as revenue

FROM payment p 
JOIN rental r 
    ON p.rental_id = r.rental_id
JOIN inventory i 
    ON r.inventory_id = i.inventory_id
JOIN film f 
    ON i.film_id = f.film_id
JOIN film_category fc 
    ON f.film_id = fc.film_id

GROUP BY 1,2 

-- Q70: Store with highest number of unique customers who rented at least 10 times
WITH cus_rental as 
(
    SELECT 
        s.store_id, 
        r.customer_id, 
        count(r.rental_id) as rental_count
    FROM rental r 
    JOIN staff st 
        ON r.staff_id = st.staff_id
    JOIN store s
        ON st.store_id = s.store_id 
    GROUP BY s.store_id,r.customer_id
    HAVING count(r.rental_id) >= 10
) 
SELECT 
    store_id, 
    count(DISTINCT customer_id) as cust_count
FROM cus_rental
ORDER BY cust_count DESC 
LIMIT 1

-- Q114: Month generating highest rental revenue per store
WITH month_revenue as 
(
    SELECT 
        s.store_id,
        strftime('%Y-%m', payment_date) as rental_month, 
        sum(p.amount) as rental_revenue
    FROM payment p 
    JOIN staff st 
        ON p.staff_id = st.staff_id
    JOIN store s
        ON st.store_id = s.store_id 
    GROUP BY s.store_id, strftime('%m',payment_date)
),

highest_revenue as 
(
    SELECT store_id,
        rental_month, 
        rental_revenue, 
        ROW_NUMBER() OVER (PARTITION BY store_id ORDER BY rental_revenue DESC) as rank 
    FROM Month_revenue
) 
SELECT store_id, 
    rental_month, 
    rental_revenue
FROM highest_revenue
WHERE rank = 1
ORDER BY store_id

-- Q115: Highest and lowest revenue-generating months per category

WITH month_revenue as 
(
    SELECT 
        fc.category_id,
        strftime('%Y-%m', payment_date) as payment_month, 
        sum(p.amount) as rental_revenue
    FROM payment p 
    JOIN rental r 
        ON p.rental_id = r.rental_id
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film_category fc 
        ON i.film_id = fc.film_id
    
    GROUP BY fc.category_id, strftime('%Y-%m',payment_date)
),

highest_lowest_revenue as 
(
    SELECT category_id,
        payment_month, 
        rental_revenue, 
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY rental_revenue DESC) as higheset_rank,
        ROW_number() OVER (PARTITION BY category_id ORDER BY rental_revenue ASC) as lowest_rank 
    FROM Month_revenue
) 
SELECT category_id, 
    payment_month, 
    rental_revenue, 
    higheset_rank, 
    lowest_rank
FROM highest_lowest_revenue
WHERE (higheset_rank = 1 OR lowest_rank = 1)
ORDER BY category_id
;

-- ========================================

                 GROUP - C 

-- ========================================

-- 3. Ranking / Top-N Queries (RANK, DENSE_RANK, NTILE)

-- Q11: Rank movies by total rental count (highest first)
WITH rental_count_by_movie as 
(
    SELECT 
        f.film_id, 
        f.title, 
        count(r.rental_id) as rental_count
        
    FROM rental r
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
    JOIN film f 
        ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title
    ORDER BY rental_count DESC
)
SELECT 
    film_id, title, rental_count,
    DENSE_RANK() OVER (ORDER BY rental_count DESC) as rank 
FROM rental_count_by_movie

-- Q12: Top 3 most rented movies per store
WITH rented_count_store as 
(
    SELECT
        s.store_id,
        f.film_id,
        f.title,
        count(r.rental_id) as rental_count, 
        DENSE_RANK() OVER (PARTITION BY s.store_id ORDER BY count(r.rental_id) DESC) as Rank 
    FROM rental r
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film f
        ON i.film_id = f.film_id
    JOIN store s 
        ON i.store_id = s.store_id
    GROUP BY s.store_id, f.film_id, f.title
) 
SELECT store_id, 
    film_id, 
    title, 
    rental_count, rank
FROM rented_count_store
WHERE rank <= 3


-- Q13: Rank customers by total spending per store
WITH cust_spends as 
(
    SELECT 
        s.store_id, 
        r.customer_id, 
        sum(p.amount) as cust_spent_amount
    FROM payment p 
    JOIN rental r 
        ON p.rental_id = r.rental_id 
    JOIN staff st
        ON r.staff_id = st.staff_id
    JOIN store s 
        ON st.store_id = s.store_id
    GROUP BY s.store_id, r.customer_id
)
SELECT store_id, 
customer_id, 
cust_spent_amount, 
RANK() OVER (PARTITION BY store_id ORDER BY cust_spent_amount DESC) as rank 
FROM cust_spends

-- Q31: Rank customers within their store based on total rental payments, considering ties
WITH cust_spends as 
(
    SELECT 
        s.store_id, 
        r.customer_id, 
        sum(p.amount) as cust_spent_amount
    FROM payment p 
    JOIN rental r 
        ON p.rental_id = r.rental_id 
    JOIN staff st
        ON r.staff_id = st.staff_id
    JOIN store s 
        ON st.store_id = s.store_id
    GROUP BY s.store_id, r.customer_id
)
SELECT store_id, 
customer_id, 
cust_spent_amount, 
DENSE_RANK() OVER (PARTITION BY store_id ORDER BY cust_spent_amount DESC) as rank 
FROM cust_spends

-- Q32: Top 3 rented movies per category, dense ranking

WITH cat_rents as 
(
    SELECT   
        f.film_id, 
        f.title, 
        fc.category_id,
        COUNT(r.rental_id) as rental_count
    FROM rental r 
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film f
        ON i.film_id = f.film_id
    JOIN film_category fc 
        ON f.film_id = fc.film_id
    GROUP BY f.film_id, f.title, fc.category_id 
), 
rank_movies as 
(
    SELECT 
        film_id, 
        title, 
        category_id, rental_count, 
        DENSE_RANK() OVER (PARTITION BY category_id ORDER BY rental_count DESC) as Rank 
    FROM cat_rents
) 
select film_id, 
title, 
category_id, rental_count
FROM rank_movies 
WHERE rank <=3

-- Q33: Rank customers by total spending, excluding one-time renters
WITH customers_one as 
(

    SELECT 
        customer_id
    FROM payment 
    GROUP BY customer_id
    HAVING count(payment_date) > 1

),
total_spend as 
(
    SELECT p.customer_id,
        sum(p.amount) as total_spend,
        RANK() OVER (ORDER BY sum(p.amount) DESC) as rank 
    
    FROM payment p
    JOIN customers_one c
        ON p.customer_id = c.customer_id
    GROUP BY p.customer_id
)
SELECT customer_id, total_spend, rank
FROM total_spend

-- Q34: Most rented movie per month, ranking by rental count
WITH rented_movies as 
(
    SELECT strftime('%Y-%m', r.rental_date) as rental_year_month, 
    f.film_id,
    f.title, 
    count(r.rental_id) as total_rent
    -- RANK() OVER(PARTITION BY strftime('%Y-%m', r.rental_date) ORDER BY count(r.rental_id) DESC) as rank 
    FROM rental r
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film f 
        ON i.film_id = f.film_id
    GROUP BY strftime('%Y-%m', r.rental_date), f.film_id, f.title
), 
rents as 
(
    SELECT rental_year_month, 
    film_id, 
    title, 
    total_rent, 
    RANK() OVER (PARTITION BY rental_year_month ORDER BY total_rent DESC) as RANK 
    FROM rented_movies
)
SELECT rental_year_month, 
film_id, 
title, 
total_rent 
FROM rents 
WHERE RANK =1 


-- Q74: Rank films by rental count per category using DENSE_RANK
WITH cat_rents as 
(
    SELECT   
        f.film_id, 
        f.title, 
        fc.category_id,
        COUNT(r.rental_id) as rental_count
    FROM rental r 
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film f
        ON i.film_id = f.film_id
    JOIN film_category fc 
        ON f.film_id = fc.film_id
    GROUP BY f.film_id, f.title, fc.category_id 
) 
SELECT 
    film_id, 
    title, 
    category_id, rental_count, 
    DENSE_RANK() OVER (PARTITION BY category_id ORDER BY rental_count DESC) as Rank 
FROM cat_rents

-- Q75: Top 3 customers with highest rental payments per store using RANK
WITH cust_spends as 
(
    SELECT 
        s.store_id, 
        r.customer_id, 
        sum(p.amount) as cust_spent_amount,
        RANK() OVER (PARTITION BY s.store_id ORDER BY sum(p.amount) DESC) as rank 
    FROM payment p 
    JOIN rental r 
        ON p.rental_id = r.rental_id 
    JOIN staff st
        ON r.staff_id = st.staff_id
    JOIN store s 
        ON st.store_id = s.store_id
    GROUP BY s.store_id, r.customer_id
)
SELECT store_id, 
customer_id, 
cust_spent_amount,
rank
FROM cust_spends
wHERE rank <=3

-- Q76: Staff member with most rentals per month, ranked using DENSE_RANK
WITH staff_rents as 
(
    SELECT 
        st.staff_id, 
        first_name || ' ' || last_name as staff_name,
        strftime('%Y-%m',r.rental_date) as rental_year_month,
        count(rental_id) as rental_count
    FROM rental r
    JOIN staff st
        ON r.staff_id = st.staff_id
    GROUP BY st.staff_id, first_name || ' ' || last_name,  strftime('%Y-%m',r.rental_date) 
) 
SELECT 
    staff_id, staff_name, 
    rental_year_month, 
    rental_count, 
    DENSE_RANK() OVER (PARTITION BY rental_year_month ORDER BY rental_count DESC) as rank 
FROM staff_rents
ORDER BY rental_year_month, rank


-- Q78: Assign each rental to a quartile (NTILE(4)) based on payment amount

SELECT
    p.payment_id,
    p.rental_id,
    p.customer_id,
    p.amount,
    NTILE(4) OVER (
        ORDER BY p.amount DESC
    ) AS payment_quartile
FROM payment p
ORDER BY p.amount DESC;

-- Q79: Most rented movie per month using RANK() OVER(PARTITION BY month)

WITH monthly_rentals AS (
    SELECT
        strftime('%Y-%m', r.rental_date) AS rental_month,
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
    JOIN film f
        ON i.film_id = f.film_id
    GROUP BY rental_month, f.film_id, f.title
),
ranked_movies AS (
    SELECT
        rental_month,
        film_id,
        title,
        rental_count,
        RANK() OVER (
            PARTITION BY rental_month
            ORDER BY rental_count DESC
        ) AS rank
    FROM monthly_rentals
)
SELECT
    rental_month,
    film_id,
    title,
    rental_count,
    rank
FROM ranked_movies
WHERE rank = 1
ORDER BY rental_month;



-- Q89: Rank customers within each store based on total payments (ties considered)
WITH cust_store as 
(
SELECT 
    
    s.store_id,
    p.customer_id, 
    sum(p.amount) as total_payment
FROM payment p 
JOIN staff st 
    ON p.staff_id = st.staff_id
JOIN store s 
    ON st.store_id = s.store_id
GROUP BY s.store_id,p.customer_id
) 
SELECT store_id, 
customer_id, 
total_payment, 
DENSE_RANK() OVER(PARTITION BY store_id ORDER BY total_payment DESC) as rank 
FROM cust_store


-- Q90: Top 3 most frequent renters in each store

WITH customer_rentals AS (
    SELECT
        i.store_id,
        r.customer_id,
        COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
    GROUP BY i.store_id, r.customer_id
),
ranked_customers AS (
    SELECT
        store_id,
        customer_id,
        rental_count,
        DENSE_RANK() OVER (
            PARTITION BY store_id
            ORDER BY rental_count DESC
        ) AS rank
    FROM customer_rentals
)
SELECT
    store_id,
    customer_id,
    rental_count
FROM ranked_customers
WHERE rank <= 3
ORDER BY store_id, rental_count DESC;



-- Q96: Most rented movie per store, compared with second-most rented
WITH movie_rentals AS (
    SELECT
        i.store_id,
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i
        ON r.inventory_id = i.inventory_id
    JOIN film f
        ON i.film_id = f.film_id
    GROUP BY i.store_id, f.film_id, f.title
),
ranked_movies AS (
    SELECT
        store_id,
        film_id,
        title,
        rental_count,
        DENSE_RANK() OVER (
            PARTITION BY store_id
            ORDER BY rental_count DESC
        ) AS rank
    FROM movie_rentals
)
SELECT
    m1.store_id,
    m1.film_id   AS top_movie_id,
    m1.title     AS top_movie_title,
    m1.rental_count AS top_rentals,
    m2.film_id   AS second_movie_id,
    m2.title     AS second_movie_title,
    m2.rental_count AS second_rentals,
    (m1.rental_count - m2.rental_count) AS rental_difference
FROM ranked_movies m1
LEFT JOIN ranked_movies m2
    ON m1.store_id = m2.store_id
   AND m2.rank = 2
WHERE m1.rank = 1
ORDER BY m1.store_id;


-- ==========================

            GROUP - D 
-- 4. Date/Time Analysis (DATE functions, LAG, LEAD, Gaps)
-- ==========================




-- Q9: Day of the week with highest number of rentals
WITH week_count_rentals as 
(
    SELECT 
        strftime('%w',rental_date) as day_of_week, 
        count(rental_id) as rental_count
        
    FROM rental
    GROUP by 1
),
rank_week_rental as 
(
    SELECT day_of_week, rental_count, 
    ROW_NUMBER() OVER (ORDER BY rental_count DESC) as rank 
    FROM week_count_rentals
)
SELECT day_of_week, rental_count,rank
FROM rank_week_rental
WHERE rank =1 
-- Q71: Previous and next rental date per customer using LAG and LEAD

SELECT 
    customer_id, 
    rental_date, 
    LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as prev_rental_date, 
    LEAD(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as next_rental_date
FROM rental 

-- Q72: Time difference (days) between each rental for a customer using LAG

SELECT 
    customer_id, 
    rental_date, 
    LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as prev_rental_date,
    ROUND((julianday(rental_date) -  julianday(LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date))),2) as diff
FROM rental 


-- Q73: Rental revenue trend per store, previous and next month using LEAD/LAG
WITH rental_reve_month as 
(
    SELECT 
    
        s.store_id,
        strftime('%Y-%m',p.payment_date) as payment_month,
        sum(p.amount) as rental_revenue
    FROM payment p
    JOIN staff st  
        ON p.staff_id = st.staff_id
    JOIN store s 
        ON st.store_id = s.store_id
    GROUP BY 1,2
),
lag_lead_revenue as 
(
    SELECT store_id, 
    payment_month,
    rental_revenue, 
    (LAG(rental_revenue) OVER (PARTITION BY store_id ORDER BY payment_month)) as prev_revenue, 
    (LEAD(rental_revenue) OVER(PARTITION BY store_id ORDER BY payment_month))as next_revenue
    FROM rental_reve_month
)
SELECT store_id, payment_month, rental_revenue, prev_revenue, 
prev_revenue - rental_revenue as prev_change, next_revenue, 
next_revenue - rental_revenue as next_change 
FROM lag_lead_revenue

-- Q80: Customers who haven’t rented in last 3 months using LAG
WITH custmer_rental as 
(
    SELECT 
        customer_id, 
        rental_date,
        LAG(rental_date) OVER (PARTITION BY customer_id ORDER BY rental_date) as prev_rental_date
    FROM rental
), 

last_rental as 
(
    SELECT 
        customer_id, 
        rental_date
    FROM custmer_rental
    WHERE prev_rental_date IS NULL 
)
SELECT 
    c.customer_id, 
    c.first_name, 
    c.last_name, 
    lr.rental_date as last_rented_on
FROM last_rental lr
JOIN customer c 
    ON lr.customer_id = c.customer_id
WHERE date(lr.rental_date) < date('now','-3 months')

-- Q86: Previous and next rental dates per customer, with difference in days
SELECT customer_id, 
rental_date, prev_rental_date, next_rental_date, 
-- Days since previous rental
    CASE 
        WHEN prev_rental_date IS NOT NULL 
        THEN CAST((julianday(rental_date) - julianday(prev_rental_date)) AS INTEGER) 
    END AS days_since_prev,
    -- Days until next rental
    CASE 
        WHEN next_rental_date IS NOT NULL 
        THEN CAST( (julianday(next_rental_date) - julianday(rental_date)) AS INTEGER) 
    END AS days_until_next
FROM(
    SELECT 
        customer_id, 
        rental_date, 
        LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as prev_rental_date, 
        LEAD(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as next_rental_date

    FROM rental
    )

-- Q87: Customers with gap >30 days between rentals
WITH diffIn_rentals as 
(
SELECT customer_id, 
rental_date, prev_rental_date, next_rental_date, 
-- Days since previous rental
    CASE 
        WHEN prev_rental_date IS NOT NULL 
        THEN CAST((julianday(rental_date) - julianday(prev_rental_date)) AS INTEGER) 
    END AS days_since_prev,
    -- Days until next rental
    CASE 
        WHEN next_rental_date IS NOT NULL 
        THEN CAST( (julianday(next_rental_date) - julianday(rental_date)) AS INTEGER) 
    END AS days_until_next
FROM(
    SELECT 
        customer_id, 
        rental_date, 
        LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as prev_rental_date, 
        LEAD(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as next_rental_date

    FROM rental
    )
) 

SELECT customer_id, 
rental_date, prev_rental_date, days_since_prev as gap
FROM 
diffIn_rentals
WHERE days_since_prev > 30
ORDER BY days_since_prev;

-- Q88: Most recent and second-most recent rental per customer
-- corelated query 

SELECT
    r1.customer_id,
    r1.rental_id,
    r1.rental_date
FROM rental r1
WHERE
    (
        SELECT COUNT(*)
        FROM rental r2
        WHERE r2.customer_id = r1.customer_id
          AND r2.rental_date > r1.rental_date
    ) < 2
ORDER BY r1.customer_id, r1.rental_date DESC;

-- Q95: Customers who rented in three consecutive months
WITH customer_month_rents as 
(
    SELECT 
        customer_id, 
        strftime('%Y-%m',rental_date) as rental_month
    FROM rental 
    GROUP by customer_id, strftime('%Y-%m',rental_date) 
), 
customer_rank as 
(
    SELECT customer_id, 
        rental_month, 
        ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY rental_month) as rank 
    FROM customer_month_rents

)
SELECT  customer_id, rental_month, rank
FROM customer_rank 
WHERE rank <=3 
GROUP bY customer_id

-- Q98: Movie with highest difference in rental count between consecutive months

WITH movie_monthly_rents as 
(
    SELECT 
        f.film_id, 
        f.title, 
        strftime('%Y-%m',r.rental_date) as rental_month,
        count(r.rental_id) as rental_count
    FROM rental r
    JOIN inventory i 
        ON r.inventory_id = i.inventory_id
    JOIN film f 
        ON i.film_id = f.film_id
    GROUP BY f.film_id, f.title, strftime('%Y-%m',r.rental_date)
),
movie_monthly_diff as
(
    SELECT 
        film_id, 
        title, 
        rental_month, 
        rental_count,
        LAG(rental_count) OVER (PARTITION BY film_id ORDER BY rental_month) as prev_month_rentals
    FROM movie_monthly_rents
)
SELECT 
    film_id, 
    title, 
    rental_month, 
    rental_count,
    prev_month_rentals,
    ABS(rental_count - prev_month_rentals) as rental_diff
FROM movie_monthly_diff
ORDER BY rental_diff DESC
LIMIT 1;
-- Q103: Rental revenue change per movie compared to previous quarter

-- ====================
 -- GROUP - E 
-- ====================


-- 4. Date/Time Analysis (DATE functions, LAG, LEAD, Gaps)
-- Q9: Day of the week with highest number of rentals
WITH week_count_rentals as 
(
    SELECT 
        strftime('%w',rental_date) as day_of_week, 
        count(rental_id) as rental_count
        
    FROM rental
    GROUP by 1
),
rank_week_rental as 
(
    SELECT day_of_week, rental_count, 
    ROW_NUMBER() OVER (ORDER BY rental_count DESC) as rank 
    FROM week_count_rentals
)
SELECT day_of_week, rental_count,rank
FROM rank_week_rental
WHERE rank =1 

-- Q71: Previous and next rental date per customer using LAG and LEAD



-- Q72: Time difference (days) between each rental for a customer using LAG
-- Q80: Customers who haven’t rented in last 3 months using LAG


-- Q86: Previous and next rental dates per customer, with difference in days
-- Q87: Customers with gap >30 days between rentals
-- Q88: Most recent and second-most recent rental per customer
-- Q95: Customers who rented in three consecutive months
-- Q98: Movie with highest difference in rental count between consecutive months
-- Q103: Rental revenue change per movie compared to previous quarter



-- 5. Join / Multi-Table Queries

-- Q8: Customers who rented in same month across multiple years
WITH customer_months AS (
    SELECT
        customer_id,
        strftime('%m', rental_date) AS rental_month,
        strftime('%Y', rental_date) AS rental_year
    FROM rental
    GROUP BY customer_id, rental_month, rental_year
)

SELECT
    customer_id,
    rental_month,
    COUNT(DISTINCT rental_year) AS years_rented
FROM customer_months
GROUP BY customer_id, rental_month
HAVING COUNT(DISTINCT rental_year) > 1
ORDER BY customer_id, rental_month;


-- Q41: Customers who rented from every category at least once
WITH category_count AS (
    SELECT COUNT(*) AS total_categories
    FROM category
),
customer_category AS (
    SELECT
        r.customer_id,
        fc.category_id
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY r.customer_id, fc.category_id
)

SELECT
    cc.customer_id
FROM customer_category cc
JOIN category_count c ON 1=1
GROUP BY cc.customer_id
HAVING COUNT(DISTINCT cc.category_id) = c.total_categories
ORDER BY cc.customer_id;


-- Q42: Actors whose movies generate highest revenue (movies rented >50 times)
WITH film_rentals AS (
    SELECT
        f.film_id,
        f.rental_rate,
        COUNT(*) AS rental_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    GROUP BY f.film_id
    HAVING COUNT(*) > 50
),

film_revenue AS (
    SELECT
        film_id,
        rental_rate * rental_count AS revenue
    FROM film_rentals
)

SELECT
    a.actor_id,
    a.first_name || ' ' || a.last_name AS actor_name,
    SUM(fr.revenue) AS total_revenue
FROM actor a
JOIN film_actor fa ON a.actor_id = fa.actor_id
JOIN film_revenue fr ON fa.film_id = fr.film_id
GROUP BY a.actor_id, actor_name
ORDER BY total_revenue DESC;




-- Q46: Customers who rented movies from both stores, total rentals per customer
WITH store_1 as 
(
SELECT 
    r.customer_id,
    s.store_id,
    count(r.rental_id) as rental_count

FROM rental r 
JOIN staff st  
    ON r.staff_id = st.staff_id
JOIN store s 
    ON st.store_id = s.store_id
GROUP BY 1,2
)
SELECT customer_id,
sum(rental_count) as total_rents
FROM store_1
GROUP BY 1
HAVING count(DISTINCT store_id) =2

-- Q48: Customers who rented movies in ≥3 categories, count rentals per category
WITH cust_cat AS (
    SELECT
        r.customer_id,
        fc.category_id,
        COUNT(*) AS rentals_in_category
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY r.customer_id, fc.category_id
),
cust_cat_count AS (
    SELECT
        customer_id,
        COUNT(DISTINCT category_id) AS categories_rented
    FROM cust_cat
    GROUP BY customer_id
    HAVING categories_rented >= 3
)
SELECT
    c.customer_id,
    c.category_id,
    c.rentals_in_category
FROM cust_cat c
JOIN cust_cat_count cc ON c.customer_id = cc.customer_id
ORDER BY c.customer_id, c.category_id;

-- Q49: Customers who never rented from their original store
WITH customer_orig AS (
    SELECT customer_id, store_id AS original_store
    FROM customer
),
cust_rented_stores AS (
    SELECT DISTINCT
        r.customer_id,
        s.store_id
    FROM rental r
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
)
SELECT
    co.customer_id
FROM customer_orig co
LEFT JOIN cust_rented_stores cr
    ON co.customer_id = cr.customer_id
GROUP BY co.customer_id
HAVING SUM(CASE WHEN cr.store_id = co.original_store THEN 1 ELSE 0 END) = 0;


-- Q50: Customers who rented from only one store
SELECT
    r.customer_id,
    COUNT(DISTINCT s.store_id) AS store_count
FROM rental r
JOIN staff st ON r.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
GROUP BY r.customer_id
HAVING store_count = 1;


-- Q51: Movies in inventory but never rented from that store
SELECT
    i.store_id,
    i.film_id
FROM inventory i
LEFT JOIN rental r
    ON i.inventory_id = r.inventory_id
WHERE r.rental_id IS NULL
ORDER BY i.store_id, i.film_id;


-- Q52: Movies rented most but with least inventory per store
WITH store_movie_rentals AS (
    SELECT
        s.store_id,
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN store s ON i.store_id = s.store_id
    GROUP BY s.store_id, f.film_id
),
store_movie_inventory AS (
    SELECT
        store_id,
        film_id,
        COUNT(*) AS inventory_count
    FROM inventory
    GROUP BY store_id, film_id
),
combined AS (
    SELECT
        r.store_id,
        r.film_id,
        r.title,
        r.rental_count,
        COALESCE(i.inventory_count, 0) AS inventory_count,
        (r.rental_count * 1.0) / COALESCE(i.inventory_count, 1) AS rent_to_inv_ratio
    FROM store_movie_rentals r
    LEFT JOIN store_movie_inventory i
        ON r.store_id = i.store_id AND r.film_id = i.film_id
)
SELECT *
FROM combined
ORDER BY store_id, rent_to_inv_ratio DESC
LIMIT 1;


-- Q53: Availability of each film per store, show store with most copies
WITH film_inventory AS (
    SELECT
        store_id,
        film_id,
        COUNT(*) AS copies
    FROM inventory
    GROUP BY store_id, film_id
),
top_store AS (
    SELECT
        film_id,
        store_id,
        copies,
        ROW_NUMBER() OVER (
            PARTITION BY film_id
            ORDER BY copies DESC
        ) AS rank
    FROM film_inventory
)
SELECT film_id, store_id, copies
FROM top_store
WHERE rank = 1
ORDER BY film_id;


-- Q54: Films returned late most, include category and actor
WITH late_rentals AS (
    SELECT
        r.inventory_id,
        i.film_id,
        COUNT(*) AS late_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    WHERE r.return_date > DATE(r.rental_date, '+' || r.rental_duration || ' days')
    GROUP BY r.inventory_id, i.film_id
),
film_info AS (
    SELECT
        f.film_id,
        f.title,
        fc.category_id,
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        lr.late_count
    FROM late_rentals lr
    JOIN film f ON lr.film_id = f.film_id
    JOIN film_category fc ON f.film_id = fc.film_id
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
)
SELECT *
FROM film_info
ORDER BY late_count DESC
LIMIT 10;


-- Q55: Category with lowest return rate (rental vs return count)
WITH category_stats AS (
    SELECT
        fc.category_id,
        COUNT(r.rental_id) AS rentals,
        SUM(CASE WHEN r.return_date IS NOT NULL THEN 1 ELSE 0 END) AS returns
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY fc.category_id
)
SELECT
    category_id,
    rentals,
    returns,
    (returns * 1.0 / rentals) AS return_rate
FROM category_stats
ORDER BY return_rate ASC
LIMIT 1;


-- Q56: Top 5 most rented movies per actor
WITH actor_movie_rentals AS (
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        f.film_id,
        f.title,
        COUNT(r.rental_id) AS rental_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film f ON i.film_id = f.film_id
    JOIN film_actor fa ON f.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
    GROUP BY a.actor_id, f.film_id
),
ranked AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            PARTITION BY actor_id
            ORDER BY rental_count DESC
        ) AS rank
    FROM actor_movie_rentals
)
SELECT actor_id, actor_name, film_id, title, rental_count
FROM ranked
WHERE rank <= 5
ORDER BY actor_id, rank;


-- Q57: Actors whose movies generated most rental revenue
WITH film_revenue AS (
    SELECT
        i.film_id,
        SUM(p.amount) AS revenue
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
),
actor_revenue AS (
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        SUM(fr.revenue) AS total_revenue
    FROM film_revenue fr
    JOIN film_actor fa ON fr.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
    GROUP BY a.actor_id
)
SELECT *
FROM actor_revenue
ORDER BY total_revenue DESC
LIMIT 10;


-- Q58: Actor appearing in most rented films
WITH film_rental_counts AS (
    SELECT
        i.film_id,
        COUNT(r.rental_id) AS rentals
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
),
actor_films AS (
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        COUNT(DISTINCT fa.film_id) AS films_rented
    FROM film_rental_counts frc
    JOIN film_actor fa ON frc.film_id = fa.film_id
    JOIN actor a ON fa.actor_id = a.actor_id
    GROUP BY a.actor_id
)
SELECT *
FROM actor_films
ORDER BY films_rented DESC
LIMIT 1;


-- Q59: Actors whose movies rented least in past year, list movies
WITH last_year_rentals AS (
    SELECT
        i.film_id,
        COUNT(r.rental_id) AS rentals
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    WHERE r.rental_date >= DATE('now', '-1 year')
    GROUP BY i.film_id
),
actor_rental AS (
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        f.film_id,
        f.title,
        COALESCE(lyr.rentals, 0) AS rentals_last_year
    FROM film_actor fa
    JOIN actor a ON fa.actor_id = a.actor_id
    JOIN film f ON fa.film_id = f.film_id
    LEFT JOIN last_year_rentals lyr ON f.film_id = lyr.film_id
)
SELECT *
FROM actor_rental
ORDER BY rentals_last_year ASC
LIMIT 20;


-- Q60: Actors in movies belonging to most categories
WITH actor_categories AS (
    SELECT
        a.actor_id,
        a.first_name || ' ' || a.last_name AS actor_name,
        COUNT(DISTINCT fc.category_id) AS category_count
    FROM film_actor fa
    JOIN actor a ON fa.actor_id = a.actor_id
    JOIN film_category fc ON fa.film_id = fc.film_id
    GROUP BY a.actor_id
)
SELECT *
FROM actor_categories
ORDER BY category_count DESC
LIMIT 10;



-- 6. Staff / Store Analysis
-- Q61: Staff with highest revenue in total rentals
SELECT
    p.staff_id,
    st.first_name || ' ' || st.last_name AS staff_name,
    SUM(p.amount) AS total_revenue
FROM payment p
JOIN staff st ON p.staff_id = st.staff_id
GROUP BY p.staff_id
ORDER BY total_revenue DESC
LIMIT 1;


-- Q62: Total revenue per staff, broken down by store
SELECT
    s.store_id,
    p.staff_id,
    st.first_name || ' ' || st.last_name AS staff_name,
    SUM(p.amount) AS total_revenue
FROM payment p
JOIN staff st ON p.staff_id = st.staff_id
JOIN store s ON st.store_id = s.store_id
GROUP BY s.store_id, p.staff_id
ORDER BY s.store_id, total_revenue DESC;


-- Q63: Staff handling most rentals during peak hours
WITH peak_rentals AS (
    SELECT
        st.staff_id,
        st.first_name || ' ' || st.last_name AS staff_name,
        COUNT(*) AS rental_count
    FROM rental r
    JOIN staff st ON r.staff_id = st.staff_id
    WHERE CAST(strftime('%H', r.rental_date) AS INTEGER) BETWEEN 18 AND 21
    GROUP BY st.staff_id
)
SELECT *
FROM peak_rentals
ORDER BY rental_count DESC
LIMIT 1;


-- Q64: Store with highest % revenue from repeat customers
WITH customer_store_rentals AS (
    SELECT
        s.store_id,
        r.customer_id,
        COUNT(*) AS rental_count
    FROM rental r
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY s.store_id, r.customer_id
),
repeat_customers AS (
    SELECT
        store_id,
        customer_id,
        CASE WHEN rental_count > 1 THEN 1 ELSE 0 END AS is_repeat
    FROM customer_store_rentals
),
store_revenue AS (
    SELECT
        s.store_id,
        SUM(p.amount) AS total_revenue
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY s.store_id
),
repeat_revenue AS (
    SELECT
        s.store_id,
        SUM(p.amount) AS repeat_revenue
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    JOIN repeat_customers rc
      ON rc.store_id = s.store_id
     AND rc.customer_id = r.customer_id
     AND rc.is_repeat = 1
    GROUP BY s.store_id
)
SELECT
    sr.store_id,
    repeat_revenue * 100.0 / total_revenue AS repeat_revenue_pct
FROM store_revenue sr
JOIN repeat_revenue rr ON sr.store_id = rr.store_id
ORDER BY repeat_revenue_pct DESC
LIMIT 1;


-- Q65: Store with highest late fee collection
WITH late_payments AS (
    SELECT
        s.store_id,
        SUM(p.amount) AS late_fees
    FROM payment p
    JOIN rental r ON p.rental_id = r.rental_id
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    WHERE r.return_date > DATE(r.rental_date, '+' || r.rental_duration || ' days')
    GROUP BY s.store_id
)
SELECT *
FROM late_payments
ORDER BY late_fees DESC
LIMIT 1;


-- Q66: Customers renting movies featuring same actor more than once
WITH customer_actor_rents AS (
    SELECT
        r.customer_id,
        fa.actor_id,
        COUNT(*) AS actor_rent_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_actor fa ON i.film_id = fa.film_id
    GROUP BY r.customer_id, fa.actor_id
)
SELECT customer_id, actor_id, actor_rent_count
FROM customer_actor_rents
WHERE actor_rent_count > 1
ORDER BY customer_id, actor_rent_count DESC;


-- Q67: Customers renting movies from every category in a particular store
WITH store_categories AS (
    SELECT DISTINCT fc.category_id
    FROM film_category fc
),
customer_store_category AS (
    SELECT
        r.customer_id,
        s.store_id,
        fc.category_id
    FROM rental r
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY r.customer_id, s.store_id, fc.category_id
),
category_count AS (
    SELECT COUNT(*) AS total_categories
    FROM store_categories
)
SELECT
    csc.customer_id,
    csc.store_id
FROM customer_store_category csc
JOIN category_count cc ON 1=1
GROUP BY csc.customer_id, csc.store_id
HAVING COUNT(DISTINCT csc.category_id) = cc.total_categories;


-- Q106: Staff member with highest revenue contribution per store
WITH staff_store_revenue AS (
    SELECT
        s.store_id,
        p.staff_id,
        SUM(p.amount) AS staff_revenue
    FROM payment p
    JOIN staff st ON p.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY s.store_id, p.staff_id
),
staff_rank AS (
    SELECT
        store_id,
        staff_id,
        staff_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY store_id
            ORDER BY staff_revenue DESC
        ) AS rank
    FROM staff_store_revenue
)
SELECT
    store_id,
    staff_id,
    staff_revenue
FROM staff_rank
WHERE rank = 1
ORDER BY store_id;


-- Q107: Rentals handled per staff per month, compare to previous month
SELECT 
    p.staff_id,
    st.first_name || ' ' || st.last_name as staff_name,
    sum(p.amount) as total_revenue,
    strftime('%Y-%m', p.payment_date) as payment_year_month,
    LAG(sum(p.amount)) OVER (PARTITION BY p.staff_id ORDER BY strftime('%Y-%m', p.payment_date)) as prev_month_revenue,
    COALESCE((sum(p.amount) - LAG(sum(p.amount)) OVER (PARTITION BY p.staff_id ORDER BY strftime('%Y-%m', p.payment_date))),0) as revenue_change
FROM payment p
JOIN staff st 
    ON p.staff_id = st.staff_id
GROUP BY p.staff_id, strftime('%Y-%m', p.payment_date)



-- Q108: Staff member with longest gap between rentals
WITH staff_rentals AS (
    SELECT
        staff_id,
        rental_date,
        LAG(rental_date) OVER (
            PARTITION BY staff_id
            ORDER BY rental_date
        ) AS prev_rental
    FROM rental
),
gaps AS (
    SELECT
        staff_id,
        JULIANDAY(rental_date) - JULIANDAY(prev_rental) AS gap_days
    FROM staff_rentals
    WHERE prev_rental IS NOT NULL
)
SELECT
    staff_id,
    MAX(gap_days) AS longest_gap_days
FROM gaps
GROUP BY staff_id
ORDER BY longest_gap_days DESC
LIMIT 1;


-- Q110: Staff with highest number of late rentals, compare to second-highest
WITH late_rentals AS (
    SELECT
        staff_id,
        COUNT(*) AS late_count
    FROM rental
    WHERE return_date > DATE(rental_date, '+' || rental_duration || ' days')
    GROUP BY staff_id
),
ranked AS (
    SELECT
        staff_id,
        late_count,
        DENSE_RANK() OVER (ORDER BY late_count DESC) AS rank
    FROM late_rentals
)
SELECT
    staff_id,
    late_count,
    rank
FROM ranked
WHERE rank <= 2
ORDER BY rank;



-- 7. Analytical / Trend Calculations (YoY, MoM, Rolling Avg)

-- Q16: YoY % change in rental revenue
WITH revenue_per_year AS (
    SELECT
        strftime('%Y', payment_date) AS year,
        SUM(amount) AS revenue
    FROM payment
    GROUP BY year
)
SELECT
    year,
    revenue,
    LAG(revenue) OVER (ORDER BY year) AS prev_year_revenue,
    (revenue - LAG(revenue) OVER (ORDER BY year)) * 100.0 /
    LAG(revenue) OVER (ORDER BY year) AS yoy_pct_change
FROM revenue_per_year
ORDER BY year;

-- Q17: MoM change in rental count last 12 months
WITH monthly_rentals AS (
    SELECT
        strftime('%Y-%m', rental_date) AS month,
        COUNT(*) AS rentals
    FROM rental
    WHERE rental_date >= DATE('now', '-12 months')
    GROUP BY month
)
SELECT
    month,
    rentals,
    LAG(rentals) OVER (ORDER BY month) AS prev_month_rentals,
    rentals - LAG(rentals) OVER (ORDER BY month) AS mom_change
FROM monthly_rentals
ORDER BY month;

-- Q18: YoY change in number of rentals per category
WITH cat_year_rentals AS (
    SELECT
        fc.category_id,
        strftime('%Y', r.rental_date) AS year,
        COUNT(*) AS rentals
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY fc.category_id, year
)
SELECT
    category_id,
    year,
    rentals,
    LAG(rentals) OVER (
        PARTITION BY category_id
        ORDER BY year
    ) AS prev_year_rentals,
    rentals - LAG(rentals) OVER (
        PARTITION BY category_id
        ORDER BY year
    ) AS yoy_change
FROM cat_year_rentals
ORDER BY category_id, year;


-- Q25: Rolling 3-month total revenue per store, excluding current month
WITH monthly_store_revenue AS (
    SELECT
        s.store_id,
        strftime('%Y-%m', p.payment_date) AS month,
        SUM(p.amount) AS revenue
    FROM payment p
    JOIN staff st ON p.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY s.store_id, month
)
SELECT
    store_id,
    month,
    SUM(revenue) OVER (
        PARTITION BY store_id
        ORDER BY month
        ROWS BETWEEN 3 PRECEDING AND 1 PRECEDING
    ) AS rolling_3mo_revenue_excluding_current
FROM monthly_store_revenue
ORDER BY store_id, month;


-- Q35: Rolling 6-month average rental count per category
WITH monthly_cat_rentals AS (
    SELECT
        fc.category_id,
        strftime('%Y-%m', r.rental_date) AS month,
        COUNT(*) AS rentals
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY fc.category_id, month
)
SELECT
    category_id,
    month,
    rentals,
    AVG(rentals) OVER (
        PARTITION BY category_id
        ORDER BY month
        ROWS BETWEEN 5 PRECEDING AND CURRENT ROW
    ) AS rolling_6mo_avg
FROM monthly_cat_rentals
ORDER BY category_id, month;


-- Q36: YoY % change in rentals per store, find highest growth
WITH store_year_rentals AS (
    SELECT
        s.store_id,
        strftime('%Y', r.rental_date) AS year,
        COUNT(*) AS rentals
    FROM rental r
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY s.store_id, year
),
growth AS (
    SELECT
        store_id,
        year,
        rentals,
        LAG(rentals) OVER (
            PARTITION BY store_id
            ORDER BY year
        ) AS prev_year_rentals
    FROM store_year_rentals
)
SELECT
    store_id,
    year,
    rentals,
    prev_year_rentals,
    (rentals - prev_year_rentals) * 100.0 / prev_year_rentals AS yoy_pct_change
FROM growth
ORDER BY yoy_pct_change DESC
LIMIT 1;


-- Q37: MoM change in revenue per staff
WITH staff_revenue as 
(
    SELECT
        p.staff_id,
        strftime('%Y-%m', p.payment_date) as payment_year_month,
        sum(p.amount) as revenue
    FROM payment p 
    JOIN staff st 
        ON p.staff_id = st.staff_id
    GROUP BY p.staff_id, strftime('%Y-%m', p.payment_date)
)

SELECT 
    staff_id,
    payment_year_month,
    revenue,
    LAG(revenue) OVER (PARTITION BY staff_id ORDER BY payment_year_month) as prev_mon_revenue,
    COALESCE((revenue - LAG(revenue) OVER (PARTITION BY staff_id ORDER BY payment_year_month)),0) as mom_change
FROM staff_revenue

-- Q38: YoY change in average rental duration per category
WITH cat_year_avg AS (
    SELECT
        fc.category_id,
        strftime('%Y', r.rental_date) AS year,
        AVG(r.rental_duration) AS avg_duration
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    JOIN film_category fc ON i.film_id = fc.film_id
    GROUP BY fc.category_id, year
)
SELECT
    category_id,
    year,
    avg_duration,
    LAG(avg_duration) OVER (
        PARTITION BY category_id
        ORDER BY year
    ) AS prev_year_avg,
    avg_duration - LAG(avg_duration) OVER (
        PARTITION BY category_id
        ORDER BY year
    ) AS yoy_change
FROM cat_year_avg
ORDER BY category_id, year;

-- Q39: Monthly rental comparison across years, biggest drop
WITH monthly_rentals AS (
    SELECT
        strftime('%m', rental_date) AS month,
        strftime('%Y', rental_date) AS year,
        COUNT(*) AS rentals
    FROM rental
    GROUP BY year, month
),
month_comparison AS (
    SELECT
        month,
        year,
        rentals,
        LAG(rentals) OVER (
            PARTITION BY month
            ORDER BY year
        ) AS prev_year_rentals
    FROM monthly_rentals
)
SELECT
    month,
    year,
    rentals,
    prev_year_rentals,
    rentals - prev_year_rentals AS yoy_change
FROM month_comparison
WHERE prev_year_rentals IS NOT NULL
ORDER BY yoy_change ASC
LIMIT 1;

-- Q40: Customer spending difference compared to previous year
WITH cust_spend AS (
    SELECT 
        customer_id,
        strftime('%Y', payment_date) AS payment_year,
        SUM(amount) AS spend_cust
    FROM payment 
    GROUP BY customer_id, strftime('%Y', payment_date)
)

SELECT
    customer_id,
    payment_year,
    spend_cust,
    LAG(spend_cust) OVER (
        PARTITION BY customer_id 
        ORDER BY payment_year
    ) AS prev_year_spend,
    spend_cust - LAG(spend_cust) OVER (
        PARTITION BY customer_id 
        ORDER BY payment_year
    ) AS spend_difference
FROM cust_spend;

-- Q73: Revenue trend per store, previous & next month
WITH rental_reve_month as 
(
    SELECT 
    
        s.store_id,
        strftime('%Y-%m',p.payment_date) as payment_month,
        sum(p.amount) as rental_revenue
    FROM payment p
    JOIN staff st  
        ON p.staff_id = st.staff_id
    JOIN store s 
        ON st.store_id = s.store_id
    GROUP BY 1,2
),
lag_lead_revenue as 
(
    SELECT store_id, 
    payment_month,
    rental_revenue, 
    (LAG(rental_revenue) OVER (PARTITION BY store_id ORDER BY payment_month)) as prev_revenue, 
    (LEAD(rental_revenue) OVER(PARTITION BY store_id ORDER BY payment_month))as next_revenue
    FROM rental_reve_month
)
SELECT store_id, payment_month, rental_revenue, prev_revenue, 
prev_revenue - rental_revenue as prev_change, next_revenue, 
next_revenue - rental_revenue as next_change 
FROM lag_lead_revenue



-- 8. Optimization / Index Analysis
-- Q81: Identify queries benefiting from index based on common searches
-- Q82: Queries optimized by indexing rental_date
-- Q83: Performance of searching by last name before/after index
-- Q84: Most frequently rented movies, test inventory_id index performance
-- Q85: Indexing payment_date effect on monthly revenue calculations



-- 9. Customer Behavior / Loyalty Analysis
-- Q91: Classify customers by loyalty: Premium, Regular, Low-spending
WITH cust_spend as 
(
    SELECT 
        p.customer_id,
        sum(p.amount) as total_spent
    FROM payment p 
    GROUP BY p.customer_id
)
SELECT 
    customer_id, 
    total_spent,
    CASE 
        WHEN total_spent >= 500 THEN 'Premium'
        WHEN total_spent >= 200 THEN 'Regular'
        ELSE 'Low-spending'
    END as loyalty_segment
FROM cust_spend


-- Q92: Customers who spent more last 6 months than previous 6 months
WITH last_6 AS (
    SELECT
        customer_id,
        SUM(amount) AS spend_last_6
    FROM payment
    WHERE payment_date >= DATE('now', '-6 months')
    GROUP BY customer_id
),
prev_6 AS (
    SELECT
        customer_id,
        SUM(amount) AS spend_prev_6
    FROM payment
    WHERE payment_date >= DATE('now', '-12 months')
      AND payment_date < DATE('now', '-6 months')
    GROUP BY customer_id
)

SELECT
    l.customer_id,
    l.spend_last_6,
    COALESCE(p.spend_prev_6, 0) AS spend_prev_6
FROM last_6 l
LEFT JOIN prev_6 p
    ON l.customer_id = p.customer_id
WHERE l.spend_last_6 > COALESCE(p.spend_prev_6, 0)
ORDER BY (l.spend_last_6 - COALESCE(p.spend_prev_6, 0)) DESC;


-- Q93: Customers renting same film multiple times, time between rentals
WITH customer_film_rentals AS (
    SELECT
        r.customer_id,
        i.film_id,
        r.rental_date,
        LAG(r.rental_date) OVER (
            PARTITION BY r.customer_id, i.film_id
            ORDER BY r.rental_date
        ) AS prev_rental_date
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
)
SELECT
    customer_id,
    film_id,
    rental_date,
    prev_rental_date,
    JULIANDAY(rental_date) - JULIANDAY(prev_rental_date) AS days_between
FROM customer_film_rentals
WHERE prev_rental_date IS NOT NULL
ORDER BY customer_id, film_id, rental_date;

-- Q94: First and most recent rental per customer
WITH customer_rentals AS (
    SELECT
        customer_id,
        rental_date,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY rental_date
        ) AS rn_asc,
        ROW_NUMBER() OVER (
            PARTITION BY customer_id
            ORDER BY rental_date DESC
        ) AS rn_desc
    FROM rental
)
SELECT
    customer_id,
    MAX(CASE WHEN rn_asc = 1 THEN rental_date END) AS first_rental,
    MAX(CASE WHEN rn_desc = 1 THEN rental_date END) AS most_recent_rental
FROM customer_rentals
GROUP BY customer_id;


-- Q97: Avg rental duration per movie, only if rented >20 times
WITH movie_rentals AS (
    SELECT
        i.film_id,
        COUNT(*) AS rental_count,
        AVG(r.rental_duration) AS avg_duration
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
)
SELECT
    film_id,
    avg_duration,
    rental_count
FROM movie_rentals
WHERE rental_count > 20
ORDER BY avg_duration DESC;


-- Q100: Previous and next rental instance per film per store
WITH film_store_rentals AS (
    SELECT
        i.store_id,
        i.film_id,
        r.rental_id,
        r.rental_date,
        LAG(r.rental_date) OVER (
            PARTITION BY i.store_id, i.film_id
            ORDER BY r.rental_date
        ) AS prev_rental_date,
        LEAD(r.rental_date) OVER (
            PARTITION BY i.store_id, i.film_id
            ORDER BY r.rental_date
        ) AS next_rental_date
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
)
SELECT
    store_id,
    film_id,
    rental_id,
    rental_date,
    prev_rental_date,
    next_rental_date
FROM film_store_rentals
ORDER BY store_id, film_id, rental_date;


-- Q101: Movies with high rentals but low inventory
WITH movie_rentals AS (
    SELECT
        i.film_id,
        COUNT(*) AS rental_count
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
    GROUP BY i.film_id
),
movie_inventory AS (
    SELECT
        film_id,
        COUNT(*) AS inventory_count
    FROM inventory
    GROUP BY film_id
)
SELECT
    mr.film_id,
    mr.rental_count,
    mi.inventory_count,
    (mr.rental_count * 1.0) / mi.inventory_count AS rental_to_inventory_ratio
FROM movie_rentals mr
JOIN movie_inventory mi ON mr.film_id = mi.film_id
ORDER BY rental_to_inventory_ratio DESC
LIMIT 20;


-- Q102: Most popular film category per month
WITH film_category_monthly as 
(
SELECT 
    fc.category_id,
    strftime('%Y-%m', r.rental_date) as rental_month,
    count(r.rental_id) as total_rents
FROM rental r
JOIN inventory i 
    ON r.inventory_id = i.inventory_id
JOIN film_category fc 
    ON i.film_id = fc.film_id
GROUP BY fc.category_id,strftime('%Y-%m', r.rental_date)
),
ranked_category as 
(
SELECT 
    category_id,
    rental_month,
    total_rents,
    RANK() OVER (PARTITION BY rental_month ORDER BY total_rents DESC) as rank 
FROM film_category_monthly
)
SELECT 
    category_id,
    rental_month,
    total_rents
FROM ranked_category
WHERE rank =1
-- Q104: Films rented every month in a given year
SELECT 
    strftime('%Y-%m',r.rental_date) as rental_year_month,
    count(f.film_id) as films_rented_count
FROM rental r
JOIN inventory i 
    ON r.inventory_id = i.inventory_id
JOIN film f
    ON i.film_id = f.film_id
GROUP BY strftime('%Y-%m',r.rental_date) 

-- Q105: Store with highest % rentals from first-time customers
WITH cust_rentals AS (
    SELECT
        s.store_id,
        r.customer_id,
        COUNT(*) AS rentals_per_customer
    FROM rental r
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY s.store_id, r.customer_id
)

SELECT
    store_id,
    SUM(CASE WHEN rentals_per_customer = 1 THEN 1 ELSE 0 END) * 100.0 /
    COUNT(*) AS pct_unique_customers_renting_once
FROM cust_rentals
GROUP BY store_id
ORDER BY pct_unique_customers_renting_once DESC
LIMIT 1;


-- 10. Advanced Analysis / Complex Metrics
-- Q29: Movies most frequently rented on Fridays & Saturdays

SELECT film_id,title,
CASE WHEN rental_weekday = '5' THEN 'Friday' 
    WHEN rental_weekday = '6' THEN 'Saturday' ELSE rental_weekday END as rental_weekday, rental_count
FROM 
(
SELECT
    f.film_id, 
    f.title,
    strftime('%w',r.rental_date) as rental_weekday, 
    count(r.rental_id) as rental_count,
    DENSE_RANK() OVER (PARTITION BY strftime('%w',r.rental_date) ORDER BY count(r.rental_id) DESC) as rank
FROM rental r
JOIN inventory i ON r.inventory_id = i.inventory_id
JOIN film f ON i.film_id = f.film_id
GROUP BY 1,2,3
)
WHERE rank =1
AND rental_weekday in ('5','6')


-- Q44: Customers renting more in last 6 months than previous 6 months
WITH rentals_by_customer AS (
    SELECT
        r.customer_id,
        r.rental_date,
        COUNT(*) OVER (PARTITION BY r.customer_id) AS total_rentals
    FROM rental r
),

last_6_months AS (
    SELECT
        customer_id,
        COUNT(*) AS last6
    FROM rental
    WHERE rental_date >= DATE('now', '-6 months')
    GROUP BY customer_id
),

prev_6_months AS (
    SELECT
        customer_id,
        COUNT(*) AS prev6
    FROM rental
    WHERE rental_date >= DATE('now', '-12 months')
          AND rental_date < DATE('now', '-6 months')
    GROUP BY customer_id
)

SELECT
    l.customer_id,
    l.last6,
    COALESCE(p.prev6, 0) AS prev6
FROM last_6_months l
LEFT JOIN prev_6_months p
    ON l.customer_id = p.customer_id
WHERE l.last6 > COALESCE(p.prev6, 0)
ORDER BY (l.last6 - COALESCE(p.prev6, 0)) DESC;


-- Q45: Store with highest % unique customers renting only once
WITH cust_rentals AS (
    SELECT
        s.store_id,
        r.customer_id,
        COUNT(*) AS rentals_per_customer
    FROM rental r
    JOIN staff st ON r.staff_id = st.staff_id
    JOIN store s ON st.store_id = s.store_id
    GROUP BY s.store_id, r.customer_id
)

SELECTs
    store_id,
    SUM(CASE WHEN rentals_per_customer = 1 THEN 1 ELSE 0 END) * 100.0 /
    COUNT(*) AS pct_unique_customers_renting_once
FROM cust_rentals
GROUP BY store_id
ORDER BY pct_unique_customers_renting_once DESC
LIMIT 1;


-- Q47: Top 3 customers per store by total rental payments
WITH cust_payments as 
(
SELECT 
    s.store_id,
    p.customer_id,
    sum(p.amount) as total_payment
FROM payment p
JOIN staff st 
    ON p.staff_id = st.staff_id
JOIN store s 
    ON st.store_id = s.store_id
GROUP BY s.store_id, p.customer_id
),
cust_payments_ranked as 
(
    SELECT store_id,
    customer_id,
    total_payment,
    DENSE_RANK() OVER (PARTITION BY store_id ORDER BY total_payment DESC) as rank
    FROM cust_payments
)
SELECT store_id,
customer_id,
total_payment
FROM cust_payments_ranked
WHERE rank <=3

-- Q72: Time difference (days) between each rental for a customer
SELECT 
    customer_id, 
    rental_date, 
    LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date) as prev_rental_date,
    ROUND((julianday(rental_date) -  julianday(LAG(rental_date) OVER(PARTITION BY customer_id ORDER BY rental_date))),2) as diff
FROM rental 

-- Q99: Films frequently rented together by same customer
WITH cust_day_films AS (
    SELECT
        r.customer_id,
        DATE(r.rental_date) AS rent_day,
        i.film_id
    FROM rental r
    JOIN inventory i ON r.inventory_id = i.inventory_id
),
film_pairs AS (
    SELECT
        c1.film_id AS film_id_1,
        c2.film_id AS film_id_2,
        COUNT(*) AS times_rented_together
    FROM cust_day_films c1
    JOIN cust_day_films c2
        ON c1.customer_id = c2.customer_id
       AND c1.rent_day = c2.rent_day
       AND c1.film_id < c2.film_id
    GROUP BY film_id_1, film_id_2
)
SELECT
    fp.film_id_1,
    f1.title AS film_title_1,
    fp.film_id_2,
    f2.title AS film_title_2,
    fp.times_rented_together
FROM film_pairs fp
JOIN film f1 ON fp.film_id_1 = f1.film_id
JOIN film f2 ON fp.film_id_2 = f2.film_id
ORDER BY fp.times_rented_together DESC
LIMIT 20;



Trips Table:- 
                trip_id,
                driver_id,
                trip_date timestamp, 
                status, 
                trip_city, 
                trip_country 
  
-- write a query to find out drivers who took at least 20 trips in each month for the year of 2024.
WITH trip_count_driver as 
(
SELECT 
    driver_id,
    strftime('%Y-%m',trip_date) as trip_year_month, 
    count(trip_id) as trip_count
FROM trips
WHERE strftime('%Y', trip_date) = '2024'
GROUP BY driver_id,  strftime('%Y-%m',trip_date)
)

drivers_20_trips as 
(
    SELECT 
        driver_id, 
        trip_year_month, 
        trip_count
    FROM trip_count_driver
    WHERE trip_count >= 20
)
SELECT 
    driver_id
FROM drivers_20_trips 
GROUP BY driver_id
HAVING COUNT(DISTINCT trip_year_month) = 12 
