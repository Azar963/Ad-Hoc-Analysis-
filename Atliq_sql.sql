# 1. Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

SELECT DISTINCT
    market
FROM
    dim_customer
WHERE
    customer = 'Atliq Exclusive'
        AND region = 'APAC';

# 2. What is the percentage of unique product increase in 2021 vs. 2020? The
# final output contains these fields,
# unique_products_2020
# unique_products_2021
# percentage_chg

with unique_products_2020 AS(
select count(distinct product_code) as unique_products_2020
from gdb023.fact_sales_monthly
where fiscal_year = 2020
), unique_products_2021 as (
select count(distinct product_code) as unique_products_2021
from gdb023.fact_sales_monthly
where fiscal_year = 2021
)
select unique_products_2020, unique_products_2021, round((unique_products_2021 - unique_products_2020)*100/unique_products_2020, 2)  as percentage_change
from unique_products_2020, unique_products_2021;

# 3. Provide a report with all the unique product counts for each segment and
# sort them in descending order of product counts. The final output contains
# 2 fields,
# segment
# product_count

SELECT 
    segment, COUNT(DISTINCT product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

# 4. Follow-up: Which segment had the most increase in unique products in
#  vs 2020? The final output contains these fields,
# segment
# product_count_2020
# product_count_2021
# difference

with unique_products_2020 as (
select segment, count(distinct fact_sales_monthly.product_code) as product_count_2020
from fact_sales_monthly
join dim_product
on fact_sales_monthly.product_code = dim_product.product_code
where fiscal_year = 2020
group by segment
), unique_products_2021 as (
select segment, count(distinct fact_sales_monthly.product_code) as product_count_2021
from fact_sales_monthly
join dim_product
on fact_sales_monthly.product_code = dim_product.product_code
where fiscal_year = 2021
group by segment
)
select unique_products_2020.segment,
unique_products_2020.product_count_2020,
unique_products_2021.product_count_2021,
round((unique_products_2021.product_count_2021 - unique_products_2020.product_count_2020)*100/unique_products_2020.product_count_2020, 2) as difference
from unique_products_2020
join unique_products_2021
on unique_products_2020.segment = unique_products_2021.segment
order by difference desc;

# 5. Get the products that have the highest and lowest manufacturing costs.
# The final output should contain these fields,
# product_code
# product
# manufacturing_cost

with highest_cost as (
select product_code, manufacturing_cost
from fact_manufacturing_cost
order by manufacturing_cost desc
limit 1
), lowest_cost as (
select product_code, manufacturing_cost
from fact_manufacturing_cost
order by manufacturing_cost asc
limit 1
)
select highest_cost.product_code,dim_product.product, highest_cost.manufacturing_cost
from highest_cost
join dim_product
on highest_cost.product_code = dim_product.product_code
union
select lowest_cost.product_code, dim_product.product, lowest_cost.manufacturing_cost
from lowest_cost
join dim_product
on lowest_cost.product_code = dim_product.product_code;

# 6. Generate a report which contains the top 5 customers who received an
# average high pre_invoice_discount_pct for the fiscal year 2021 and in the
# Indian market. The final output contains these fields,
# customer_code
# customer
# average_discount_percentage

SELECT 
    fact_pre_invoice_deductions.customer_code,
    customer,
    fiscal_year,
    pre_invoice_discount_pct,
    market
FROM
    fact_pre_invoice_deductions
        JOIN
    dim_customer ON fact_pre_invoice_deductions.customer_code = dim_customer.customer_code
WHERE
    market = 'India' AND fiscal_year = 2021
ORDER BY pre_invoice_discount_pct DESC
LIMIT 5;


# 7. Get the complete report of the Gross sales amount for the customer “Atliq
# high-performing months and take strategic decisions.
# The final report contains these columns:
# Month
# Year
# Gross sales Amount

WITH sales_monthly AS (
SELECT
MONTH(date) as month,
YEAR(date) as year,
SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) as gross_sales_amount
FROM fact_sales_monthly
JOIN dim_customer
ON fact_sales_monthly.customer_code = dim_customer.customer_code
JOIN fact_gross_price
ON fact_sales_monthly.product_code = fact_gross_price.product_code
WHERE dim_customer.customer = 'Atliq Exclusive'
GROUP BY MONTH(date), YEAR(date)
)

SELECT sales_monthly.month, sales_monthly.year, sales_monthly.gross_sales_amount
FROM sales_monthly
ORDER BY sales_monthly.year, sales_monthly.month;

# 8. In which quarter of 2020, got the maximum total_sold_quantity? The final
# output contains these fields sorted by the total_sold_quantity,
# Quarter
# total_sold_quantity

WITH total_sold_quantity_quarter AS (
    SELECT
    CASE
        WHEN MONTH(date) BETWEEN 1 AND 3 THEN 'Q1'
        WHEN MONTH(date) BETWEEN 4 AND 6 THEN 'Q2'
        WHEN MONTH(date) BETWEEN 7 AND 9 THEN 'Q3'
        ELSE 'Q4'
    END as quarter,
    SUM(sold_quantity) as total_sold_quantity
    FROM fact_sales_monthly
    WHERE YEAR(date) = 2020
    GROUP BY quarter
)

SELECT quarter, total_sold_quantity
FROM total_sold_quantity_quarter
ORDER BY total_sold_quantity DESC
LIMIT 4;

# 9. Which channel helped to bring more gross sales in the fiscal year 2021
# and the percentage of contribution? The final output contains these fields,
# channel
# gross_sales_mln
# percentage

WITH gross_sales_channel AS (
    SELECT dim_customer.channel, SUM(fact_gross_price.gross_price * fact_sales_monthly.sold_quantity) as gross_sales_mln
    FROM fact_sales_monthly
    JOIN dim_customer
    ON fact_sales_monthly.customer_code = dim_customer.customer_code
    JOIN fact_gross_price
    ON fact_sales_monthly.product_code = fact_gross_price.product_code
    WHERE YEAR(fact_sales_monthly.date) = 2021
    GROUP BY dim_customer.channel
), total_sales AS (
    SELECT SUM(gross_sales_mln) as total_sales_mln
    FROM gross_sales_channel
)
 SELECT gross_sales_channel.channel, gross_sales_channel.gross_sales_mln, round(gross_sales_channel.gross_sales_mln*100/total_sales.total_sales_mln, 2) as percentage
 FROM gross_sales_channel
 JOIN total_sales
 ORDER BY gross_sales_channel.gross_sales_mln DESC;
 
# 10. Get the Top 3 products in each division that have a high
# total_sold_quantity in the fiscal_year 2021? The final output contains these
# fields,
# division
# product_code
# product
# total_sold_quantity
# rank_order

WITH total_sold_quantity_division as (
   SELECT dim_product.division, dim_product.product_code, dim_product.product, SUM(fact_sales_monthly.sold_quantity) as total_sold_quantity,
   RANK() OVER (PARTITION BY division ORDER BY SUM(fact_sales_monthly.sold_quantity) DESC) as rank_order
   FROM fact_sales_monthly
   JOIN dim_product
   ON fact_sales_monthly.product_code = dim_product.product_code
   WHERE fiscal_year = 2021
   GROUP BY dim_product.division, dim_product.product_code, dim_product.product
 )
  SELECT division, product_code, product, total_sold_quantity, rank_order
  FROM total_sold_quantity_division
  WHERE rank_order <=3;
