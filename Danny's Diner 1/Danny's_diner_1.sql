create database dannys_dinner;

use dannys_dinner;
CREATE SCHEMA dannys_diner;
SET search_path = dannys_diner;

CREATE TABLE sales (
  customer_id VARCHAR(1),
  order_date DATE,
  product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
  product_id INTEGER,
  product_name VARCHAR(5),
  price INTEGER
);

INSERT INTO menu
  (product_id, product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
  customer_id VARCHAR(1),
  join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
select * from sales;
select * from menu;
select * from members;

-- 1.What is the total amount each customer spent at the restaurant?
select customer_id, sum(price) as "total amount" from sales s
join menu m
on s.product_id = m.product_id
group by customer_id;

-- How many days has each customer visited the restaurant?
select customer_id, count(distinct(order_date))
from sales
group by customer_id;

-- What was the first item from the menu purchased by each customer?
select distinct customer_id, product_name from sales s
join menu m
on s.product_id = m.product_id
where order_date = (select min(order_date) from sales)
order by customer_id;


-- What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name, count(product_name) from sales s
join menu m
on s.product_id = m.product_id
group by product_name
order by count(product_name) desc
limit 1;

-- Which item was the most popular for each customer?
with cte4 as (
select customer_id, product_name, count(product_name) as order_count,
RANK() OVER(partition by customer_id order by count(product_name) desc) as item_rank
from sales s
join menu m
on s.product_id = m.product_id
group by customer_id,product_name)

select * from cte4;


-- Which item was purchased first by the customer after they became a member?
-- solution using group by
select s.customer_id, product_name, min(s.order_date)
from menu m
join sales s
on s.product_id = m.product_id
join members 
on members.customer_id = s.customer_id
where order_date >= members.join_date
group by customer_id
order by customer_id;
-- solution using dense rank
CREATE VIEW problem6 as
select s.customer_id, product_name, 
dense_rank() OVER(partition by customer_id order by s.order_date) as itee_rank_after_membership
from menu m
join sales s
on s.product_id = m.product_id
join members 
on members.customer_id = s.customer_id
where s.order_date>= members.join_date;

select customer_id,product_name from problem6
where itee_rank_after_membership = 1;

-- Which item was purchased just before the customer became a member?
with cte7 as( 
select s.customer_id, product_name, s.order_date,
dense_rank() OVER(partition by s.customer_id order by order_date desc) as item_bought_before_membership
from menu m
join sales s
on s.product_id = m.product_id
join members 
on members.customer_id = s.customer_id
where order_date < members.join_date)

select customer_id,product_name from problem7
where  item_bought_before_membership = 1;

-- What is the total items and amount spent for each member before they became a member?

select s.customer_id,count(distinct(product_name)) as items_bought, sum(price) as price from sales s
join menu m
on s.product_id = m.product_id
join members
on members.customer_id = s.customer_id
where order_date < members.join_date
group by customer_id;

/* If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points 
would each customer have? */

with cte9 as(
select s.customer_id, product_name,
CASE
    WHEN  m.product_name = 'sushi' then concat(price*20, ' points')
    else concat(m.price*10, ' points')
    end as points
    from sales s
    join menu m
    on s.product_id = m.product_id
    )
select customer_id, sum(points)
from cte9
group by customer_id;

/* In the first week after a customer joins the program (including their join date) 
they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January? */
with jan_points as(
		SELECT *,
				DATE_ADD(join_date,interval +6 day) valid_date,
               LAST_DAY("2021-01-1") as last_date
		FROM members
        )
SELECT s.customer_id,
       SUM(case 
		WHEN s.product_id = 1 THEN price*20
	    WHEN s.order_date between j.join_date and j.valid_date then price*20
		ELSE price*10
		END) as total_points
 FROM jan_points j, sales s, menu m
 WHERE j.customer_id=s.customer_id and
       m.product_id =s.product_id and
       s.order_date <= j.last_date
GROUP BY s.customer_id
order by customer_id;

-- bonus
-- join all the things

select s.customer_id, order_date,product_name, price,
CASE
 when s.customer_id = members.customer_id and s.order_date >= members.join_date then 'Y'
 ELSE 'N'
 end members_
 from sales s
 join menu m
 on s.product_id = m.product_id
 left join members
 on s.customer_id  = members.customer_id
 order by s.customer_id;
 
 
 with bonus_ as (
select s.customer_id, order_date,product_name, price,
CASE
 when s.customer_id = members.customer_id and s.order_date >= members.join_date then 'Y'
 ELSE 'N'
 end members_
 from sales s
 join menu m
 on s.product_id = m.product_id
 left join members
 on s.customer_id  = members.customer_id
 order by s.customer_id)
 
 select *, 
 case
	when members_ = 'N' then NULL
    else 
		DENSE_rank() OVER(Partition by customer_id, members_ order by order_date)
        end ranking
        from bonus_;


