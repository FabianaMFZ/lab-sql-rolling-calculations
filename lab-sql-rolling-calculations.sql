-- Get number of monthly active customers.
select * from sakila.rental;

create or replace view sakila.user_activity as
with cte_user_activity as (
select distinct customer_id, date_format(rental_date, '%m') as activity_month,
date_format(rental_date, '%Y') as activity_year
from sakila.rental)
select activity_year, activity_month, count(distinct customer_id) as active_users
from cte_user_activity
group by 1,2
order by 1,2 asc;

select * from sakila.user_activity;

-- Get active users in the previous month.
-- Get the change in the number of active customers.
with cte_user_activity as (
select 
   activity_year, 
   activity_month,
   active_users, 
   lag(active_users, 1) over (order by activity_year, activity_month) as previous_month_users
from sakila.user_activity)
select 
	activity_year, 
	activity_month,
	active_users,  
	previous_month_users, 
   (active_users - previous_month_users) as difference 
from cte_user_activity
;

-- Get retained customers for every month.
create or replace view sakila.retained_customers as
WITH cte_retained_customers as (
SELECT customer_id, 
date_format(rental_date, '%Y') as activity_year,
date_format(rental_date, '%m') as activity_month
FROM sakila.rental)
SELECT  distinct A.customer_id, A.activity_year, A.activity_month, B.customer_id AS next_month_users
FROM cte_retained_customers A
INNER JOIN cte_retained_customers B
ON A.customer_id = B.customer_id
AND A.activity_month = B.activity_month + 1
ORDER BY A.customer_id;

select * from sakila.retained_customers;

create or replace view sakila.retention_difference as
select activity_year, activity_month, count(distinct next_month_users) as retained_customers
from sakila.retained_customers
group by 1,2
order by 1,2;

with cte_retention as (
select 
   activity_year, 
   activity_month,
   retained_customers, 
   lag(retained_customers, 1) over (order by activity_year, activity_month) as previous_month_users
from sakila.retention_difference)
select 
	activity_year, 
	activity_month,
	retained_customers,  
	previous_month_users, 
   (retained_customers - previous_month_users) as difference 
from cte_retention
;
