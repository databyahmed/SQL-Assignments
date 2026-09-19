				--SQL Practice Questions--
	--BikeStores Dataset: Joins, GROUP BY, Subqueries & CTEs--

					--Joins--
					---------

/*	1.  (Easy)  List every order with the customer's full name, store name,
	and the full name of the staff member who handled it.*/

	SELECT 
	c.first_name + ' ' + c.last_name AS [Customer_Name],
	st.store_name AS [Store_Name],
	s.first_name + ' '+ s.last_name AS [Staff_Name]

	FROM sales.customers AS c
	inner join  sales.orders o
	on c.customer_id = o.customer_id
	inner join sales.staffs s
	on o.staff_id = s.staff_id
	inner join sales.stores st
	on s.store_id = st.store_id;

	/*2.  (Easy)  Show each product with its brand name and category name.
		Include products even if they have no brand or category assigned.*/

	SELECT 
	p.product_name,
	c.category_name,
	b.brand_name
	FROM production.products p
	left join production.categories c
	on p.category_id = c.category_id
	left join production.brands b
	on p.brand_id = b.brand_id;

	/*3.  (Medium)  Find all customers who have never placed an order.
		Return their name, city, and email.*/

		SELECT 
		c.first_name + ' ' + c.last_name AS [Customer_Name],
		c.city,
		c.email
		FROM sales.customers c
		left join sales.orders o
		on c.customer_id = o.customer_id
		where o.order_id is null

			--	-GROUP BY- --
	/*4.  (Easy)  Calculate total revenue per store
		. Revenue = quantity * list_price * (1 - discount). Sort from highest to lowest.*/

		SELECT 
		s.store_name,
		sum(oi.quantity * oi.list_price * (1 - oi.discount) ) AS [Total Reveneu]
		FROM sales.stores s
		left join sales.orders o
		on s.store_id = o.store_id
		inner join sales.order_items oi
		on o.order_id = oi.order_id
		group by s.store_name
		order by [Total Reveneu] desc;
 
		/*5.  (Medium)  For each brand, show the number of products, the average list price, 
			and the highest list price. Only include brands with more than 5 products.*/

		SELECT 
		count(p.product_id ) AS product_count,  
		avg(p.list_price) AS average_price ,
		max(p.list_price) AS highest_price
		FROM production.products as p
		inner join production.brands as b
		on p.brand_id = b.brand_id
		group by b.brand_name
		HAVING COUNT(p.product_id) > 5;

		/*6. (Medium) Show the number of orders and total revenue per month 
		for the year 2017, ordered chronologically.*/
	
	SELECT 
	    MONTH(o.order_date) AS [month_number],
		DATENAME(month, o.order_date) AS [month_name],
		COUNT(DISTINCT o.order_id) AS total_orders,
		SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
FROM sales.orders o
INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
WHERE YEAR(o.order_date) = 2017
GROUP BY MONTH(o.order_date),
		 DATENAME(month, o.order_date)
ORDER BY MONTH(o.order_date);
	

								--Subqueries--
								-------------

	/*7. (Medium) Find all products priced above the average 
	list price of their own category.Hint: Use a correlated subquery.*/


	SELECT 
    p1.product_id,
    p1.product_name,
    p1.category_id,
    p1.list_price
	FROM production.products p1
	WHERE p1.list_price > (
    SELECT AVG(p2.list_price)
    FROM production.products p2
    WHERE p2.category_id = p1.category_id);


	/*8. (Medium) List the customers who have placed more orders 
		than the average number of orders per customer.*/

		SELECT 
		c.customer_id,
		(c.first_name + ' '+ c.last_name) AS [customer_name],
		(o.order_id) AS order_count
	FROM sales.customers c
	INNER JOIN sales.orders o ON c.customer_id = o.customer_id
	GROUP BY c.customer_id, c.first_name, c.last_name
	HAVING COUNT(o.order_id) > (
    SELECT AVG(CAST(order_count AS DECIMAL(10,2)))
    FROM (
        SELECT COUNT(order_id) AS order_count
        FROM sales.orders
        GROUP BY customer_id
    ) AS sub
	);


										--CTEs--
									   ----------

	/*9. (Hard) Using a CTE, calculate each customer&#39;s total spend,
	then return the top 10 customers with their spend and rank.
	Add a second CTE that labels each customer as &quot;High&quot;
	(above the overall average spend) or &quot;Regular&quot;.*/


	WITH CustomerSpend AS (
    SELECT 
        o.customer_id,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_spend
    FROM sales.orders o
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY o.customer_id
),
CustomerMetrics AS (
		SELECT 
        cs.customer_id,
        cs.total_spend,
        DENSE_RANK() OVER (ORDER BY cs.total_spend DESC) AS spend_rank,
        CASE 
          WHEN cs.total_spend > (SELECT AVG(total_spend) FROM CustomerSpend) THEN 'High'
          ELSE 'Regular'
		  END AS customer_segment
	 FROM CustomerSpend cs
	)
	SELECT TOP 10 
    cm.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    cm.total_spend,
    cm.spend_rank,
    cm.customer_segment
	FROM CustomerMetrics cm
	INNER JOIN sales.customers c ON cm.customer_id = c.customer_id
	ORDER BY cm.spend_rank;
	

	/*10. (Hard) Using CTEs, find the best-selling product (by quantity) in each category,
	and show how much of that product&#39;s stock is currently available across all stores.
	Hint: Use ROW_NUMBER() or RANK() partitioned by category, then join to production.stocks.*/


	WITH ProductSales AS (
    SELECT 
        p.category_id,
        p.product_id,
        p.product_name,
        SUM(oi.quantity) AS total_quantity_sold
    FROM sales.order_items oi
    INNER JOIN production.products p ON oi.product_id = p.product_id
    GROUP BY p.category_id, p.product_id, p.product_name
),
RankedProducts AS (
    SELECT 
        category_id,
        product_id,
        product_name,
        total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY category_id ORDER BY total_quantity_sold DESC) AS rn
    FROM ProductSales
),
ProductStocks AS (
    SELECT 
        product_id,
        SUM(quantity) AS total_stock_available
    FROM production.stocks
    GROUP BY product_id
)
SELECT 
    cat.category_name,
    rp.product_name,
    rp.total_quantity_sold,
    ISNULL(ps.total_stock_available, 0) AS total_stock_available
FROM RankedProducts rp
INNER JOIN production.categories cat ON rp.category_id = cat.category_id
LEFT JOIN ProductStocks ps ON rp.product_id = ps.product_id
WHERE rp.rn = 1;


					--Bonus Challenges--
					-------------------

	/*• Rewrite Q8 using a CTE instead of a subquery and compare readability.*/

	WITH CustomerOrderCounts AS (
    SELECT 
        customer_id,
        COUNT(order_id) AS order_count
    FROM sales.orders
    GROUP BY customer_id
),
AverageOrders AS (
    SELECT AVG(CAST(order_count AS DECIMAL(10,2))) AS avg_orders_per_cust
    FROM CustomerOrderCounts
)
SELECT 
    c.customer_id,
    CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    coc.order_count
FROM CustomerOrderCounts coc
INNER JOIN sales.customers c ON coc.customer_id = c.customer_id
CROSS JOIN AverageOrders ao
WHERE coc.order_count > ao.avg_orders_per_cust;


/*• For Q4, add a column showing each store&#39;s percentage share of total company revenue.*/

WITH StoreRevenue AS (
    SELECT 
        s.store_name,
        SUM(oi.quantity * oi.list_price * (1 - oi.discount)) AS total_revenue
    FROM sales.orders o
    INNER JOIN sales.stores s ON o.store_id = s.store_id
    INNER JOIN sales.order_items oi ON o.order_id = oi.order_id
    GROUP BY s.store_name
),
TotalCompanyRevenue AS (
    SELECT SUM(total_revenue) AS grand_total FROM StoreRevenue
)
SELECT 
    sr.store_name,
    sr.total_revenue,
    FORMAT((sr.total_revenue / tcr.grand_total), 'P2') AS revenue_percentage_share
FROM StoreRevenue sr
CROSS JOIN TotalCompanyRevenue tcr
ORDER BY sr.total_revenue DESC;

						--QUIZ ASSIGNMENT COMPLETED HERE--
