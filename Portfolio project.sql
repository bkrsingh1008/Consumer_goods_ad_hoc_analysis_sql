-- Codebasics SQL portfolio project resume challenge 4 --
-- request 1
select distinct market from dim_customer where customer = 'Atliq Exclusive' and region = 'APAC';

-- request 2
with cte as (
SELECT 
    fiscal_year,
    COUNT(distinct product_code) AS unique_product_2021
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2021),
cte1 as (
SELECT 
    fiscal_year,
    COUNT(distinct product_code) AS unique_product_2020
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020)
SELECT 
    unique_product_2021,
    unique_product_2020,
   round((unique_product_2021 - unique_product_2020) * 100 / unique_product_2020,2) AS pct_change
FROM
    cte
        CROSS JOIN
    cte1;
    
-- request 3
SELECT 
    segment, COUNT(product_code) AS product_count
FROM
    dim_product
GROUP BY segment
ORDER BY product_count DESC;

-- request 4
with unique_product_2021 as (
  select 
    segment, 
    count(distinct p.product_code) as product_count_2021 
  from 
    dim_product p 
    join fact_sales_monthly s on p.product_code = s.product_code 
  where 
    fiscal_year = 2021 
  group by 
    segment 
  order by 
    segment
), 
unique_product_2020 as (
  select 
    segment, 
    count(distinct p.product_code) as product_count_2020 
  from 
    dim_product p 
    join fact_sales_monthly s on p.product_code = s.product_code 
  where 
    fiscal_year = 2020 
  group by 
    segment 
  order by 
    segment
) 
select 
  c1.segment, 
  product_count_2021, 
  product_count_2020, 
  (
    product_count_2021 - product_count_2020
  ) as difference 
from 
  unique_product_2021 c1 
  join unique_product_2020 c2 on c1.segment = c2.segment 
group by 
  segment;

-- request 5  
SELECT 
    p.product_code, p.product, f.manufacturing_cost
FROM
    dim_product p
        JOIN
    fact_manufacturing_cost f ON p.product_code = f.product_code
WHERE
    manufacturing_cost IN (SELECT 
            MAX(manufacturing_cost)
        FROM
            fact_manufacturing_cost UNION SELECT 
            MIN(manufacturing_cost)
        FROM
            fact_manufacturing_cost);

-- request 6
with avg_pre_invoice_dis_pct as (
  select 
    c.customer_code as customer_code, 
    c.customer as customer, 
    round(
      avg(f.pre_invoice_discount_pct), 
      4
    ) as average_high_discount 
  from 
    dim_customer c 
    join fact_pre_invoice_deductions f on c.customer_code = f.customer_code 
  where 
    f.fiscal_year = 2021 
    and c.market = 'India' 
  group by 
    c.customer, 
    c.customer_code
) 
select 
  customer_code, 
  customer, 
  average_high_discount 
from 
  avg_pre_invoice_dis_pct 
order by 
  average_high_discount desc 
limit 
  5;
-- Alternative with subquery
select 
  customer_code, 
  customer, 
  average_high_discount 
from 
  (
    select 
      c.customer_code as customer_code, 
      c.customer as customer, 
      round(
        avg(f.pre_invoice_discount_pct), 
        4
      ) as average_high_discount 
    from 
      dim_customer c 
      join fact_pre_invoice_deductions f on c.customer_code = f.customer_code 
    where 
      f.fiscal_year = 2021 
      and c.market = 'India' 
    group by 
      c.customer, 
      c.customer_code
  ) as A 
order by 
  average_high_discount desc 
limit 
  5;
  
-- request 7
SELECT 
    MONTHNAME(s.date) AS 'Month',
    s.fiscal_year AS 'year',
    ROUND(SUM(s.sold_quantity * g.gross_price), 2) AS gross_sales_amount
FROM
    fact_sales_monthly s
        JOIN
    dim_customer c ON s.customer_code = c.customer_code
        JOIN
    fact_gross_price g ON s.product_code = g.product_code
        AND s.fiscal_year = g.fiscal_year
WHERE
    c.customer = 'Atliq Exclusive'
GROUP BY month , year
ORDER BY gross_sales_amount DESC;

-- request 8
select 
  get_fiscal_quarter(date) as 'quarter', 
  sum(sold_quantity) as 'total_sold_quantity' 
from 
  fact_sales_monthly 
where 
  fiscal_year = 2020 
group by 
  get_fiscal_quarter(date) 
order by 
  total_sold_quantity desc;

-- Alternative using case and cte
with cte as (
SELECT 
    CASE
        WHEN date BETWEEN '2019-09-01' AND '2019-11-30' THEN 'Q1'
        WHEN date BETWEEN '2019-12-01' AND '2020-02-29' THEN 'Q2'
        WHEN date BETWEEN '2020-03-01' AND '2020-05-31' THEN 'Q3'
        WHEN date BETWEEN '2020-06-01' AND '2020-08-31' THEN 'Q4'
    END AS 'Quarters',
    sold_quantity
FROM
    fact_sales_monthly
WHERE
    fiscal_year = 2020)
select quarters, sum(sold_quantity) as quantity from cte GROUP BY Quarters ORDER BY quantity DESC;

-- request 9
with cte as (
  select 
    c.channel as channel, 
    round(
      sum(s.sold_quantity * g.gross_price)/ 100000, 
      2
    ) as gross_sales_mln 
  from 
    fact_sales_monthly s 
    join dim_customer c on s.customer_code = c.customer_code 
    join fact_gross_price g on g.product_code = s.product_code 
    and g.fiscal_year = s.fiscal_year 
  where 
    s.fiscal_year = 2021 
  group by 
    c.channel
) 
select 
  channel, 
  gross_sales_mln, 
  gross_sales_mln * 100 / sum(gross_sales_mln) over() as 'percentage' 
from 
  cte 
order by 
  gross_sales_mln desc;

-- request 10
with cte as (
  select 
    p.product_code as product_code, 
    p.product as product, 
    p.division as 'division', 
    sum(s.sold_quantity) as 'total_sold_quantity' 
  from 
    fact_sales_monthly s 
    join dim_product p on s.product_code = p.product_code 
  where 
    s.fiscal_year = 2021 
  group by 
    p.product_code, 
    p.product, 
    p.division
), 
cte2 as (
  select 
    *, 
    dense_rank() over(partition by division order by total_sold_quantity desc) as 'rank_order' 
  from 
    cte
) 
select 
  *
from 
  cte2 
where 
  rank_order <= 3;











