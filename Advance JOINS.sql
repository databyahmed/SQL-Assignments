

use bikestores;

		--	      		SECTION 4				--

					 -----Advance JOINs-----

	/*Task 41: List each staff member alongside their manager's full name.
	If a staff member has no manager (top-level),
	still show them with NULL for manager name.*/

	-- SOLUTION:

	SELECT 
    s.first_name + ' ' + s.last_name AS [Staff Member],
    m.first_name + ' ' + m.last_name AS [Manager Name]
	FROM sales.staffs AS s
	left JOIN sales.staffs AS m
	ON s.manager_id = m.staff_id;	
	-----------------------------------------------------------------------------------------------

	/*Task 42: Find pairs of products from the same brand that
	have the exact same list price.
	Show both product names and the brand name.*/

	-- SOLUTION:

	select 
	b.brand_name,
	p1.product_name,
	p2.product_name,
	p1.list_price
	from production.products p1
	join production.products p2
	on p1.brand_id = p2.brand_id
	and p1.list_price = p2.list_price
	and p1.product_id < p2.product_id
	join production.brands b 
	on p1.brand_id = b.brand_id
	order by brand_name asc
	-----------------------------------------------------------------------------------------------

	/*Task 45: Generate a list of every possible combination of brand and category.
	Show brand name and category name.*/

	-- SOLUTION:

	select
	c.category_name,
	b.brand_name
	from production.categories c
	cross join production.brands b
		
	-----------------------------------------------------------------------------------------------

	/*Task 46: Using the result of a CROSS JOIN between brands and categories,
	find brand-category combinations that have NO products
	(LEFT JOIN the cross join result against products and filter for NULLs).*/

	-- SOLUTION:

	SELECT 
    b.brand_name,
    c.category_name
	FROM production.brands b
	CROSS JOIN production.categories c
	LEFT JOIN production.products p 
    ON b.brand_id = p.brand_id 
    AND c.category_id = p.category_id
	WHERE p.product_id IS NULL;

	-----------------------------------------------------------------------------------------------
	
	/*Task 49: List all brands and the products that belong to them.
	Ensure ALL brands appear, even if they have no products.
	Use a RIGHT JOIN (products RIGHT JOIN brands).*/

	-- SOLUTION:

	select
	b.brand_name,
	p.product_name
	from production.products p
	right join production.brands b
	on p.brand_id = b.brand_id
	-----------------------------------------------------------------------------------------------

	/*Task 50: Show all stores and the orders placed at each store.
	Use a RIGHT JOIN so that stores with zero orders still appear.*/

	-- SOLUTION:

	select 
	s.store_name,
	o.order_id
	from sales.orders o
	right join sales.stores s
	on s.store_id = o.store_id	
	order by store_name asc
	-----------------------------------------------------------------------------------------------
	
	/*Task 53: Find all customers who have NEVER placed an order.*/

	-- SOLUTION:

	select 
	c.customer_id,
	c.first_name + ' ' + c.last_name as [Customer Name],
	o.order_id
	from sales.customers c 
	left join sales.orders o
	on c.customer_id = o.customer_id 
	where o.order_id is null
	
	-----------------------------------------------------------------------------------------------
	
	/*Task 54: Find all products that are NOT currently in stock at ANY store.*/

	-- SOLUTION:

	select 
	p.product_id,
	p.product_name,
	s.quantity
	from production.products p
	left join production.stocks s
	on p.product_id = s.product_id
	where s.store_id is null

	-----------------------------------------------------------------------------------------------

	/*Task 56: Find all products that have never been ordered.*/

	-- SOLUTION:

	select 
	p.product_id,
	p.product_name
	from production.products p
	left join sales.order_items o
	on p.product_id = o.product_id
	where o.order_id is null
	
	-----------------------------------------------------------------------------------------------
	
	/*Task 59: Find categories where no product has a list price above 2000.*/

	-- SOLUTION:

	SELECT 
    c.category_id,
    c.category_name
	FROM production.categories c
	LEFT JOIN (
    SELECT DISTINCT category_id 
    FROM production.products 
    WHERE list_price > 2000) p 
	ON c.category_id = p.category_id
	WHERE p.category_id IS NULL;

	-----------------------------------------------------------------------------------------------
	
	/*Task 60: Find customers who placed orders but
	never ordered any product from the brand 'Trek'*/

	-- SOLUTION:
	SELECT DISTINCT
    c.customer_id,
    (c.first_name +' '+ c.last_name) AS [Customer_Name]
	FROM sales.customers c
	JOIN sales.orders o 
    ON c.customer_id = o.customer_id
	LEFT JOIN (
    SELECT DISTINCT o2.customer_id
    FROM sales.orders o2
    JOIN sales.order_items oi ON o2.order_id = oi.order_id
    JOIN production.products p ON oi.product_id = p.product_id
    JOIN production.brands b ON p.brand_id = b.brand_id
    WHERE b.brand_name = 'Trek'
) trek_buyers 
    ON c.customer_id = trek_buyers.customer_id
WHERE trek_buyers.customer_id IS NULL;

	-----------------------------------------------------------------------------------------------
								---ASSIGNMENT ENDED---