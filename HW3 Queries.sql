-- Query Number 1 - Top 2 countries by revenue
with 
country_revenue as (
  SELECT sum(quantity*unitprice) as revenue, country
  from Sales join Products USING(stockcode) JOIN Customers USING(customerid)
  group by 2
)

select country, revenue_rank
FROM (
  select country, revenue, row_number() over(ORDER by revenue desc) as revenue_rank
  from country_revenue
)
where revenue_rank in  (1,2)
order by 2

-------------------------------------------------------------------------------------

-- Query Number 2 - Top sales product (maximum quantity) over time
with 
data as (
  SELECT *, substr(invoicedate,4,8) as monthyear
  from Sales join Products USING(stockcode)
)

select monthyear, description
from (
  select *, row_number() over(partition by monthyear order by quantity desc) as Q_rank
  from data
 )
where Q_rank = 1
order by 1

-------------------------------------------------------------------------------------

--  Query Number 3 - MAU
with 
data as (
  SELECT *, substr(invoicedate,4,8) as monthyear
  from Sales JOIN Customers USING(customerid)
  group by 2
)

select monthyear, count(DISTINCT customerid)
from data
group by 1
order by 1

-------------------------------------------------------------------------------------

-- Query Number 4 - Rate of customers that increased their next purchase value on the same day with diffrent product
with 
data as (
  SELECT *, lead(quantity) over(partition by customerid  order by invoicedate) as lead_quantity
      ,lead(unitprice) over(partition by customerid  order by invoicedate) as lead_unitprice 
      ,lead(invoicedate) over(partition by customerid  order by invoicedate) as lead_invoicedate
      ,lead(description) over(partition by customerid  order by invoicedate) as lead_description
      ,row_number() over(partition by customerid  order by invoicedate) as invoice_num
      
  from Sales join Products USING(stockcode) JOIN Customers USING(customerid)
  group by 2
)
,purchases as (
  select *, quantity*unitprice as revenue
          , lead_quantity*lead_unitprice as lead_revenue
  from data
  where substr(invoicedate,1,10) = substr(lead_invoicedate,1,10) -- next purchase is on the same day
  and lead_description != description -- different products
  order by invoicedate 
)

select 
  round(cast(sum(case when lead_revenue > revenue then 1 else 0 end) as double)/count(*),2)*100 as rate
from purchases

-------------------------------------------------------------------------------------

-- Query Number 5 - Daily revenue 
with 
data as (
  SELECT *
  from Sales join Products USING(stockcode) JOIN Customers USING(customerid)
  group by 2
)

select substr(invoicedate,1,10), sum(quantity*unitprice)
from data
group by 1

-------------------------------------------------------------------------------------

-- Query Number 6 - Daily revenue per customer 
with 
data as (
  SELECT *
  from Sales join Products USING(stockcode) JOIN Customers USING(customerid)
  group by 2
)

select substr(invoicedate,1,10), round(cast(sum(quantity*unitprice) as double)/count(*))
from data
group by 1

