create database supply_chain_management;
use supply_chain_management;

create table supply_chain (
product_type varchar(50),
SKU varchar(20) primary key,
price decimal(12,6),
availability int,
number_of_products_sold int,
revenue_generated decimal(14,6),
customer_demographics varchar(50),
stock_level int,
lead_times int,
order_quantities int,
shipping_times int,
shipping_carriers varchar(50),
shipping_costs decimal(12,6),
supplier_name varchar(50),
location varchar(50),
lead_time int,
production_volumes int,
manufacturing_lead_time int,
manufacturing_costs decimal(12,6),
inspection_results varchar(20),
defect_rates decimal(10,8),
transportation_modes varchar(20),
routes varchar(20),
costs decimal(14,6)
);


-- Table inspection
select*from supply_chain;

-- Describing the data type
describe supply_chain;

-- Total Records 
select count(*) as total_records 
from supply_chain;

-- Finding unique/distinct value
select count(distinct  sku) as unique_skus, 
count(distinct supplier_name) as supplier_count,
count(distinct shipping_carriers) as unique_carriers,
count(distinct location) as unique_location
from supply_chain;

-- Business KPIs 
select sum(number_of_products_sold) as 'total products sold',
sum(revenue_generated) as 'total revenue',
sum(manufacturing_costs) as 'total manufacturing cost',
sum(stock_level) as 'total stock level',
avg(defect_rates) as 'avg defect rate',
avg(manufacturing_costs) as 'avg manufacturing cost',
avg(lead_time) as 'avg lead time',
avg(shipping_times) as 'avg shipping time',
avg(stock_level) as 'avg stock level'
from supply_chain;

-- Product Performance
-- Highest revenue by product type 
select product_type, sum(revenue_generated) as Total_Revenue
from supply_chain
group by product_type 
order by Total_Revenue desc;

-- Highest sales volume product 
select product_type, sum(number_of_products_sold) as total_number_of_products_sold
from supply_chain
group by product_type
order by total_number_of_products_sold desc;

-- Highest manufacturing cost
select sku, product_type, manufacturing_costs
from supply_chain
order by manufacturing_costs desc
limit 3;

-- Highest defect rate 
select supplier_name, product_type, avg(defect_rates) as avg_defect_rate
from supply_chain
group by product_type, supplier_name
order by avg_defect_rate desc
limit 3;

-- High stock with low sales (overstock risk) top 3
select sku, stock_level, number_of_products_sold 
from supply_chain 
where stock_level > ( select avg(stock_level) from supply_chain )
and  number_of_products_sold < (select avg(number_of_products_sold) from supply_chain )
order by stock_level desc
limit 3;

-- Low stock with high sales (stockout risk) top 3
select sku, stock_level, number_of_products_sold
from supply_chain 
where stock_level < (select avg(stock_level) from supply_chain)
and number_of_products_sold > ( select avg( number_of_products_sold) from supply_chain)
order by stock_level
limit 3; 


-- Inventory Analysis
-- Stock below overall average 
select sku, product_type, stock_level
from supply_chain
where stock_level < (select avg(stock_level) 
from supply_chain )
order by stock_level;


-- Stock above overall average 
select sku, product_type, stock_level
from supply_chain
where stock_level > (select avg(stock_level)
from supply_chain)
order by stock_level desc;


-- Supplier Performance
-- Supplier and product with defect count and failed inspection 
select supplier_name, product_type, count(*) as defective_products
from supply_chain 
where inspection_results = 'Fail'
group by supplier_name, product_type
order by defective_products desc
limit 3;

-- Supplier with lowest defect rate 
select supplier_name, product_type, avg(defect_rates) as avg_defect_rate
from supply_chain
group by product_type, supplier_name
order by avg_defect_rate 
limit 3;

-- Supplier with high cost and high defect rate
select supplier_name, product_type, max(manufacturing_costs) as highest_cost,
max(defect_rates) as highest_defect_rate
from supply_chain
group by supplier_name, product_type
order by highest_cost desc
limit 3;

-- Supplier with low cost and low rate
select supplier_name, product_type, min(manufacturing_costs) as lowest_cost,
min(defect_rates) as lowest_defect_rate
from supply_chain
group by supplier_name, product_type
order by lowest_cost
limit 5;

-- Shipping and Transportation 
-- Best mode of transport for time 
select transportation_modes, avg(shipping_times) as time_score
from supply_chain
group by transportation_modes 
order by time_score;

-- Cost and Revenue Analysis
-- Highest revenue by product type 
select product_type, sum(revenue_generated) as total_revenue
from supply_chain
group by product_type 
order by total_revenue desc;

-- Highest manufacturing cost relative to revenue
select sku, manufacturing_costs, revenue_generated,
manufacturing_costs/revenue_generated as cost_to_revenue_ratio
from supply_chain 
order by cost_to_revenue_ratio desc
limit 5;

-- Revenue to manufacturing cost ratio by product type
select product_type, 
sum(revenue_generated) / sum(manufacturing_costs) as revenue_to_manufacturing_cost
from supply_chain 
group by product_type
order by revenue_to_manufacturing_cost desc;

-- Supplier with highest total supply chain costs
select supplier_name,
sum(manufacturing_costs + shipping_costs + costs) as total_sc_cost
from supply_chain 
group by supplier_name
order by total_sc_cost desc;

-- Percentage of total shipping cost for each mode of Transportation
select transportation_modes, sum(shipping_costs) as total_shippping_cost,
sum(shipping_costs) / sum(sum(shipping_costs)) over () * 100 as total_cost
from supply_chain 
group by transportation_modes;


-- Second highest manufacturing cost
select sku, manufacturing_costs
from ( select sku, manufacturing_costs,
dense_rank() over (order by manufacturing_costs desc) as rnk
from supply_chain )
i where rnk = 2;

-- Total revenue by transportation mode
select  transportation_modes, sum(revenue_generated) as total_revenue 
from supply_chain 
group by transportation_modes;

-- Highest defect rate product for every supplier
select sku, supplier_name, defect_rates
from (select sku,supplier_name, defect_rates,
row_number() over(partition by supplier_name order by defect_rates desc) as rnk
from supply_chain )
i where rnk = 1;

--  Ranking top 3 products by revenue within every transportation mode 
select*from (
select sku, transportation_modes, revenue_generated,
row_number () over(partition by transportation_modes 
order by revenue_generated desc) as rn
from supply_chain )
i where rn <=3;

-- Product types that drive revenue and sales
create view vw_product_performance as 
select sku, product_type, supplier_name, location, number_of_products_sold, revenue_generated,
production_volumes, manufacturing_costs, manufacturing_lead_time, defect_rates, stock_level,
round(revenue_generated / nullif(number_of_products_sold,0),2) as revenue_per_unit,
round(manufacturing_costs / nullif(revenue_generated,0) *100,2) as manufacturing_cost_pct_revenue,
round(revenue_generated / nullif(manufacturing_costs, 0) , 2) as revenue_to_manuf_cost_ratio,
rank() over(partition by product_type order by revenue_generated desc) as revenue_rank_in_type,
rank() over(partition by product_type order by number_of_products_sold desc) as sales_rank_in_type,
rank() over(partition by product_type order by defect_rates desc) as defect_rank_in_type
from supply_chain;

-- Products that are overstocked and stockout risk
create or replace view vw_inventory_risk as
select s.sku, s.product_type, s.supplier_name, s.stock_level, s.number_of_products_sold, 
s.revenue_generated, s.order_quantities,
round(avg_vals.avg_stock, 1) as overall_avg_stock,
round(avg_vals.avg_sales, 1) as overall_avg_sales,
case when s.number_of_products_sold > avg_vals.avg_sales 
and s.stock_level < avg_vals.avg_stock 
then 'Replenishment Risk (Stockout)'
when s.number_of_products_sold < avg_vals.avg_sales 
and s.stock_level > avg_vals.avg_stock 
then 'Overstock Risk'
when s.number_of_products_sold > avg_vals.avg_sales 
and s.stock_level > avg_vals.avg_stock 
then 'Healthy'
else 'Low Priority'
end as inventory_risk_status,
round(s.stock_level - avg_vals.avg_stock, 1) AS stock_vs_avg,
round(s.number_of_products_sold - avg_vals.avg_sales, 1) AS sales_vs_avg
FROM supply_chain s
cross join (
select avg(stock_level) as avg_stock, avg(number_of_products_sold) as avg_sales
from supply_chain)
avg_vals;

-- Supplier's performance 
create or replace view vw_supplier_performance as
select supplier_name,
count(*) as total_products,
sum(number_of_products_sold) as total_units_sold,
sum(revenue_generated) as total_revenue,
round(avg(lead_time), 1) as avg_lead_time,
round(avg(manufacturing_lead_time), 1) as avg_manufacturing_lead_time,
round(avg(manufacturing_costs), 2) as avg_manufacturing_cost,
round(sum(manufacturing_costs), 2) as total_manufacturing_cost,
round(avg(defect_rates), 3) as avg_defect_rate,
sum(case when inspection_results = 'Fail' then 1 else 0 end) as fail_count,
sum(case when inspection_results = 'Pass' then 1 else 0 end) as pass_count,
round((select avg(lead_time) from supply_chain), 1) as company_avg_lead_time,
round((select avg(defect_rates) from supply_chain), 3) as company_avg_defect_rate,
round((select avg(manufacturing_costs) from supply_chain), 2) as company_avg_manuf_cost,
case when avg(lead_time) > (select avg(lead_time) from supply_chain) 
then 'Above Avg Lead Time'
else 'Acceptable Lead Time'
end as lead_time_flag,

case when avg(defect_rates) > (select avg (defect_rates) from supply_chain)
then 'Above Avg Defect Rate'
else 'Acceptable Quality'
end as quality_flag,

case when avg(manufacturing_costs) > (select avg(manufacturing_costs) from supply_chain)
then 'Above Avg Cost'
else 'Acceptable Cost'
end as cost_flag
from supply_chain
group by supplier_name;

-- Transportation modes having high shipping cost and time
create or replace view vw_logistics_performance as
select shipping_carriers, transportation_modes, routes,
count(*) as shipment_count,
round(avg(shipping_costs), 2) as avg_shipping_cost,
round(sum(shipping_costs), 2) as total_shipping_cost,
round(avg(costs), 2) as avg_total_cost,          
round(sum(costs), 2) as total_costs,
round(avg(shipping_times), 1) as avg_shipping_time,    
round(sum(shipping_costs) / (select SUM(shipping_costs) from supply_chain) * 100, 1) as pct_of_total_shipping_cost
from supply_chain
group by shipping_carriers, transportation_modes, routes;

-- Products that generate strong revenue 
create or replace view vw_cost_efficiency as
select sku, product_type, supplier_name, transportation_modes, revenue_generated, manufacturing_costs,
shipping_costs, costs as other_costs,
round(manufacturing_costs + shipping_costs + costs, 2) as total_supply_chain_cost,
round(revenue_generated / nullif(manufacturing_costs, 0), 2) as revenue_to_manuf_cost,
round(revenue_generated / nullif(manufacturing_costs + shipping_costs + costs, 0), 2) as revenue_to_total_cost,
round((manufacturing_costs + shipping_costs + costs) / nullif(revenue_generated, 0) *100, 2) as total_cost_to_revenue
from supply_chain;

-- Which product / supplier need management attention 
create or replace view vw_management_attention as
select sku, product_type, supplier_name, revenue_generated, defect_rates, manufacturing_costs, 
stock_level, number_of_products_sold, lead_time, inspection_results,
case when revenue_generated > (select avg(revenue_generated) from supply_chain)
and defect_rates > (select avg(defect_rates) from supply_chain)
then 'CRITICAL - High Revenue | High Defect'
when revenue_generated > (select avg(revenue_generated) from supply_chain)
and defect_rates < (select avg(defect_rates) from supply_chain)
then 'HEALTHY - High Revenue | Low Defect'
when revenue_generated <= (select avg(revenue_generated) from supply_chain)
and defect_rates > (select avg(defect_rates) from supply_chain)
then 'REVIEW - Low revenue | High Defect'
else 'LOW PRIORITY'
end as product_risk_class,

case when number_of_products_sold > (select avg(number_of_products_sold) from supply_chain)
and stock_level < (select avg(stock_level) from supply_chain)
then 'Stockout Risk'
when number_of_products_sold < (select avg(number_of_products_sold) from supply_chain)
and stock_level > (select avg(stock_level) from supply_chain)
then 'Overstock Risk'
else 'Balanced'
end as inventory_risk,

case when lead_time > (select avg(lead_time) from supply_chain) 
and defect_rates > (select avg(defect_rates) from supply_chain)
then 'Supplier Concern - High Lead | High Defect'
else 'Supplier OK'
end as supplier_risk_flag
from supply_chain;

-- Analysing the product
create or replace view vw_quality_analysis as 
select product_type, supplier_name, inspection_results,
count(*) as product_count,
round(avg(defect_rates), 3) as avg_defect_rate,
round(avg(manufacturing_costs), 2) as avg_manufacturing_cost,
round(avg(production_volumes), 0) as avg_production_volume,
sum(number_of_products_sold) as total_units_sold 
from supply_chain 
group by product_type, supplier_name, inspection_results;

