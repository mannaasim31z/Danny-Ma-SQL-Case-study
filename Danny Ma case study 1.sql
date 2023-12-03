-- 1. What is the total amount each customer spent at the restaurant?
SELECT customer_id,SUM(price) AS spent_amount
FROM menu m 
JOIN sales s 
ON m.product_id=s.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?
SELECT customer_id,COUNT(DISTINCT(order_date)) AS days_visited
FROM sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?
WITH x AS (
SELECT m.customer_id,product_name,RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS rnk
FROM members m 
JOIN sales s 
ON m.customer_id=s.customer_id
JOIN menu me
ON s.product_id=me.product_id)
SELECT customer_id,GROUP_CONCAT(product_name) AS first_purchase
FROM x
WHERE rnk=1
GROUP BY customer_id;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT product_name,COUNT(*) AS purchase_number
FROM menu m 
JOIN sales s 
ON m.product_id=s.product_id
GROUP BY product_name;

-- 5. Which item was the most popular for each customer?
WITH x AS (
SELECT customer_id,product_name,COUNT(*) AS times_purchase
FROM menu m 
JOIN sales s 
USING (product_id)
GROUP BY customer_id,product_name
ORDER BY customer_id),
y AS (
SELECT customer_id,product_name,DENSE_RANK() OVER(PARTITION BY customer_id ORDER BY times_purchase DESC) AS rnk
FROM x)
SELECT customer_id,GROUP_CONCAT(product_name) AS most_purchased_items
FROM y 
WHERE rnk=1
GROUP BY customer_id;

-- 6. Which item was purchased first by the customer after they became a member?
WITH x AS (
SELECT m.customer_id,join_date,order_date,product_name,TIMESTAMPDIFF(DAY,join_date,order_date) AS days
FROM members m 
JOIN sales s 
ON m.customer_id=s.customer_id
JOIN menu me 
ON me.product_id=s.product_id
WHERE order_date>join_date),
y AS (
SELECT customer_id,product_name,RANK() OVER(PARTITION BY customer_id ORDER BY days ASC) AS rnk
FROM x)
SELECT customer_id,product_name
FROM y
WHERE rnk=1;

-- 7. Which item was purchased just before the customer became a member?
WITH x AS (
SELECT m.customer_id,product_name,order_date,RANK() OVER(PARTITION BY customer_id ORDER BY order_date ASC) AS rnk
FROM members m 
JOIN sales s 
ON m.customer_id=s.customer_id
JOIN menu me 
ON me.product_id=s.product_id
WHERE order_date<join_date
ORDER BY m.customer_id)
SELECT customer_id,GROUP_CONCAT(product_name) AS first_orders
FROM x
WHERE rnk=1
GROUP BY customer_id;

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT m.customer_id,product_name,SUM(price) AS spent
FROM members m 
JOIN sales s 
ON m.customer_id=s.customer_id
JOIN menu me 
ON me.product_id=s.product_id
WHERE order_date<join_date
GROUP BY m.customer_id,product_name
ORDER BY m.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
WITH x AS (
SELECT m.customer_id,product_name,SUM(price) AS spent
FROM members m 
JOIN sales s 
ON m.customer_id=s.customer_id
JOIN menu me 
ON me.product_id=s.product_id
GROUP BY m.customer_id,product_name
ORDER BY m.customer_id),
y AS (
SELECT customer_id,product_name,spent,
CASE 
WHEN product_name='sushi' THEN spent*20
ELSE spent*10 END AS coins
FROM x)
SELECT customer_id,SUM(coins) AS Total_coins
FROM y
GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi 
-- how many points do customer A and B have at the end of January?
WITH x AS(
SELECT m.customer_id,join_date,order_date,price
FROM members m 
JOIN sales s 
ON m.customer_id=s.customer_id
JOIN menu me
ON me.product_id=s.product_id
WHERE order_date>join_date AND order_date<'2021-01-31')
SELECT customer_id,
SUM(CASE WHEN order_date BETWEEN '2021-01-01' AND '2021-01-07' THEN price*20 ELSE price*10 END) AS coins
FROM x
GROUP BY customer_id
ORDER BY customer_id;
