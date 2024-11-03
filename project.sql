-- Provide the list of markets in which customer "Atliq Exclusive" 
-- operates its business in the APAC region.

select distinct market from dim_customer
where customer="Atliq Exclusive" and region="APAC";


-- 2. What is the percentage of unique product increase in 2021 vs. 2020? 
-- The final output contains these fields,
 -- unique_products_2020 
 -- unique_products_2021 
 -- percentage_chg
 
 with cte1 as (select count(distinct product_code) as unique_products_2020 from fact_sales_monthly
 where fiscal_year = 2020),
  cte2 as (select count(distinct product_code) as unique_products_2021 from fact_sales_monthly
 where fiscal_year=2021)
 select cte1.unique_products_2020,
 cte2.unique_products_2021,
 round((cte2.unique_products_2021 - cte1.unique_products_2020)*100/cte1.unique_products_2020,2) as percentage_change
 from cte1,cte2;
 
 -- Provide a report with all the unique product counts for each segment 
 -- and sort them in descending order of product counts. The final output 
 -- contains 2 fields, segment product_count
 
 select segment ,count(distinct product_code) as product_count
 from dim_product
 group by segment
 order by product_count desc;
 
 -- 4. Follow-up: Which segment had the most increase in unique products in 2021 vs 2020?
 -- The final output contains these fields, 
 -- segment 
 -- product_count_2020 
 -- product_count_2021 ,difference
 
with cte1 as (select segment , count(distinct p.product_code) as product_count_2020
 from dim_product p 
 join fact_sales_monthly s on
 p.product_code=s.product_code
 where s.fiscal_year=2020
 group by segment),
 cte2 as ( select segment ,count(distinct p.product_code) as product_count_2021
 from dim_product p join
 fact_sales_monthly s on
 s.product_code=p.product_code
 where s.fiscal_year=2021
 group by segment)
 select distinct cte1.segment, cte1.product_count_2020, cte2.product_count_2021,
 (cte2.product_count_2021 - cte1.product_count_2020) as difference
 from cte1 join
 cte2 on cte1.segment = cte2.segment;
 
 -- 5 Get the products that have the highest and lowest manufacturing costs.
 -- The final output should contain these fields, 
 -- product_code
 -- product 
 -- manufacturing_cost
 
(select m.product_code, p.product,p.category, max(manufacturing_cost) as manufacturing_cost
 from fact_manufacturing_cost m
 join dim_product p on m.product_code = p.product_code
 group by m.product_code, p.product ,p.category
 order by manufacturing_cost desc limit 1)
union all
(select m.product_code, p.product,p.category ,min(manufacturing_cost) as manufacturing_cost
 from fact_manufacturing_cost m 
 join dim_product p on m.product_code = p.product_code
 group by m.product_code, p.product,p.category
 order by manufacturing_cost limit 1);

-- 6. Generate a report which contains the top 5 customers who received 
-- an average high pre_invoice_discount_pct for the fiscal year 2021 and in the Indian market.
 -- The final output contains these fields, 
 -- customer_code
 -- customer 
 -- average_discount_percentage
 
 
 select i.customer_code, c.customer, 
 round(avg(pre_invoice_discount_pct)*100 ,2) as average_discount_percentage
 from fact_pre_invoice_deductions i join
 dim_customer c on i.customer_code=c.customer_code
 where i.fiscal_year=2021 and c.market="India"
 group by i.customer_code , c.customer
 order by average_discount_percentage desc limit 5;
 
 
 -- 7 Get the complete report of the Gross sales amount for the customer “Atliq Exclusive” for each month . 
 -- This analysis helps to get an idea of low and high-performing months and take strategic decisions. 
 -- The final report contains these columns: 
 -- Month 
 -- Year 
 -- Gross sales Amount
 
 select monthname(date) as month,
 year(date) as year,
 round(sum(sold_quantity*gross_price),2) as gross_sales_amount
 from fact_sales_monthly s
 join fact_gross_price g on
 s.product_code=g.product_code
 join dim_customer c on
 s.customer_code=c.customer_code
 where customer="Atliq Exclusive"
 group by monthname(date), year(date);
 
 -- 8 In which quarter of 2020, got the maximum total_sold_quantity?
 -- The final output contains these fields sorted by the total_sold_quantity,
-- Quarter 
 -- total_sold_quantity
 
 select concat('Q',quarter(date)) as Quarter,
 round(sum(sold_quantity)/1000000,2) as total_sold_quantity_in_mln
 from fact_sales_monthly
 where year(date)=2020
 group by concat('Q',quarter(date));
 
 -- 9 Which channel helped to bring more gross sales in the fiscal year 2021 and 
 -- the percentage of contribution? The final output contains these fields,
 -- channel 
 -- gross_sales_mln 
 -- percentage
 
 select 
 c1.channel , 
round(sum(sold_quantity*gross_price)/1000000,2) as gross_sales_mln,
round((sum(sold_quantity*gross_price)/
(select sum(sold_quantity*gross_price) from fact_sales_monthly s join
fact_gross_price g on s.product_code=g.product_code
join dim_customer c on s.customer_code= c.customer_code
where s.fiscal_year = 2021))*100,2) as percentage_contribution
from fact_sales_monthly s1 join
fact_gross_price g1 on s1.product_code=g1.product_code
join dim_customer c1 on s1.customer_code=c1.customer_code
where s1.fiscal_year=2021
group by channel
order by gross_sales_mln desc;


-- 10. Get the Top 3 products in each division that have a high total_sold_quantity 
-- in the fiscal_year 2021? The final output contains these fields,
-- division 
-- product_code 
-- product 
-- total_sold_quantity 
-- rank_order

with cte as  (select 
p.division,
p.product_code,
p.product,
sum(sold_quantity) as total_sold_quantity,
dense_rank() over(partition by division order by sum(sold_quantity) desc )  as rank_order
from fact_sales_monthly s
join dim_product p on s.product_code=p.product_code
where s.fiscal_year=2021
group by p.division , p.product_code, p.product
order by total_sold_quantity )
select division,
product_code,
product,
total_sold_quantity,
rank_order
from cte
where rank_order <=3
order by division, rank_order ;


 
 