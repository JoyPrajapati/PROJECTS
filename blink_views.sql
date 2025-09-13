use blinkit;

-- SALES TABLE -----

select * from blinkit_customers;
select * from blinkit_orders;
select * from blinkit_products;
select * from blinkit_order_items;


-- FILTERING AND PROCESSING DATA ---

-- main table ( i.e union of orders,order_items,products)

CREATE OR REPLACE VIEW main AS
SELECT
    oi.order_id,
    o.customer_id,
    o.store_id,
    o.delivery_partner_id,
    o.order_date,
    o.promised_delivery_time,
    o.actual_delivery_time,
    o.delivery_status,
    o.payment_method,
    oi.product_id,
    p.product_name,
    p.category,
    p.brand,
    p.shelf_life_days,
    p.margin_percentage,
    oi.quantity,
    oi.unit_price,
    CAST((oi.quantity * oi.unit_price )AS decimal(18,2)) AS main_revenue,
    CAST((oi.quantity * (p.margin_percentage / 100.0)) * oi.unit_price AS decimal(18,2)) AS main_margin
FROM blinkit_order_items oi
JOIN blinkit_orders o on oi.order_id = o.order_id
JOIN blinkit_products p on oi.product_id = p.product_id;


select * from main;

-- Orders Table for one order per row 

CREATE OR REPLACE VIEW orders_main AS 
SELECT 
	o.order_id,
    o.customer_id,
	o.order_date,
	o.promised_delivery_time,
    o.actual_delivery_time,
    o.delivery_status,
    o.payment_method,
    o.store_id,
    o.delivery_partner_id,
    sum(m.main_revenue) as order_revenue,
    sum(m.main_margin) as order_margin,
    count(distinct m.product_id) as unique_products,
    sum(m.quantity) as total_items
    from blinkit_orders o 
    join main m on o.order_id = m.order_id
    group by o.order_id,  o.customer_id,
	o.order_date,o.promised_delivery_time,o.actual_delivery_time,o.delivery_status,
    o.payment_method,o.store_id,o.delivery_partner_id;
    
select * from orders_main;

-- Customers Table ( for customer analysis)

select * from blinkit_customers ;

create or replace view customers_main as
select 
		c.customer_id,
        c.customer_name,
        c.area,
        c.pincode,
        c.registration_date,
        c.customer_segment,
		COUNT(DISTINCT o.order_id) AS total_orders,
		coalesce(sum(o.order_revenue),0) AS total_spent,
		coalesce(AVG(o.order_revenue),0) AS avg_order_value,
		coalesce(MAX(o.order_date),c.registration_date) AS last_order_date
from blinkit_customers c
left join orders_main o
	on c.customer_id = o.customer_id 
group by c.customer_id,
        c.customer_name,
        c.area,
        c.pincode,
        c.registration_date,
        c.customer_segment;

-- review 

select * from customers_main;

-- Products Table ( for Products Sales analysis)


create or replace view products_main as
select 
		p.product_id,
        p.product_name,
        p.category,
        p.brand,
		coalesce(sum(m.quantity),0) as total_units_sold,
		coalesce(sum(m.main_revenue),0) AS total_revenue,
		coalesce(sum(m.main_margin),0) AS total_margin,
        coalesce(avg(m.unit_price),0) AS avg_selling_price
from blinkit_products p
left join main m
	on p.product_id = m.product_id
group by p.product_id,
        p.product_name,
        p.category,
        p.brand;

-- table review

select * from products_main;


-- STORES TABLE  ( for operations analysis)

create or replace view stores_main as
select 
		om.store_id,
        COUNT(om.order_id) AS total_orders,
		coalesce(sum(om.order_revenue),0) AS total_revenue,
		coalesce(sum(om.order_margin),0) AS total_margin,
    AVG(TIMESTAMPDIFF(MINUTE, om.order_date, om.actual_delivery_time)) AS avg_delivery_time_minutes
from orders_main om
group by om.store_id
order by total_orders desc;

-- review table
select * from stores_main;

