-- Importing data from CSV files into respective tables
.mode csv
.import 'Order_Items.csv' Order_Items
.import 'Customers.csv' Customers
.import 'Staffs.csv' Staffs
.import 'Categories.csv' Categories
.import 'Products.csv' Products
.import 'Orders.csv' Orders
.import 'Stores.csv' Stores
.import 'Brands.csv' Brands
.import 'Stocks.csv' Stocks
.mode tables

-- Query to know the number of distinct staffs who have placed orders
SELECT DISTINCT staff_id FROM Orders;

-- Query to see the top performing products by sales
SELECT Products.product_id, product_name, SUM(quantity) AS total_quantity_sold
FROM Order_Items
JOIN Products ON Order_Items.product_id = Products.product_id
GROUP BY Order_Items.product_id, product_name
ORDER BY total_quantity_sold DESC
LIMIT 5;

-- Query to see the top performing staff by sales
SELECT Staffs.staff_id, first_name, last_name, COUNT(order_id) AS total_sales
FROM Staffs
JOIN Orders ON Staffs.staff_id = Orders.staff_id
GROUP BY Orders.staff_id
ORDER BY total_sales DESC;

-- Query to see average stock of products in stores
SELECT category_name, product_name, model_year, AVG(quantity) AS average_stock
FROM Products
JOIN Categories ON Products.category_id = Categories.category_id
JOIN Stocks ON Products.product_id = Stocks.product_id
GROUP BY category_name, product_name, model_year;

-- Query to see the top performing store by sales
SELECT store_id, COUNT(order_id) AS total_sales
FROM Orders
GROUP BY store_id
ORDER BY total_sales DESC;

-- Query to see the top performing category by sales
SELECT Categories.category_name, SUM(Order_Items.quantity) AS total_sales
FROM Products
JOIN Categories ON Products.category_id = Categories.category_id
JOIN Order_Items ON Products.product_id = Order_Items.product_id
GROUP BY Categories.category_name
ORDER BY total_sales DESC;

-- Query to see the top three performing customers by spending
SELECT Customers.customer_id, Customers.first_name, Customers.last_name, SUM(Order_Items.quantity * Products.list_price) AS total_spent
FROM Customers
JOIN Orders ON Customers.customer_id = Orders.customer_id
JOIN Order_Items ON Orders.order_id = Order_Items.order_id
JOIN Products ON Order_Items.product_id = Products.product_id
GROUP BY Customers.customer_id, Customers.first_name, Customers.last_name
ORDER BY total_spent DESC
LIMIT 3;

-- Query to find staffs whose orders are pending
SELECT 
    Staffs.staff_id, Staffs.first_name, Staffs.last_name, 
    COUNT(Orders.order_id) AS total_pending_orders,
    GROUP_CONCAT(Orders.order_id) AS order_ids
FROM Staffs
JOIN Orders ON Staffs.staff_id = Orders.staff_id
WHERE Orders.order_status = 'pending'
GROUP BY Staffs.staff_id;

-- Query to find staffs whose orders are processing
SELECT 
    Staffs.staff_id, 
    Staffs.first_name, 
    Staffs.last_name, 
    COUNT(Orders.order_id) AS total_processing_orders,
    (SELECT order_id FROM Orders 
     WHERE Orders.staff_id = Staffs.staff_id AND Orders.order_status = 'processing' 
     ORDER BY Orders.order_date ASC LIMIT 1) AS oldest_order_id
FROM Staffs
JOIN Orders ON Staffs.staff_id = Orders.staff_id
WHERE Orders.order_status = 'processing'
GROUP BY Staffs.staff_id;

-- Query to find staffs who does not have any orders
SELECT 
    Staffs.staff_id, 
    Staffs.first_name, 
    Staffs.last_name
FROM Staffs
LEFT JOIN Orders ON Staffs.staff_id = Orders.staff_id
WHERE Orders.order_id IS NULL;

-- Query to send sorry mails to customers whose orders are rejected
SELECT 
    Customers.customer_id, Customers.first_name, Customers.last_name
FROM Customers
JOIN Orders ON Customers.customer_id = Orders.customer_id
WHERE Orders.order_status = 'rejected'
ORDER BY Orders.order_date DESC;

-- Query to send congratulatory mails to customers whose orders are completed
SELECT Customers.customer_id, Customers.first_name, Customers.last_name
FROM Customers
JOIN Orders ON Customers.customer_id = Orders.customer_id
WHERE Orders.order_status = 'completed';

-- Example transactions for inserting new orders and items
BEGIN TRANSACTION;
INSERT INTO Orders (order_id, customer_id, order_status, order_date, required_date, shipped_date, store_id, staff_id)
VALUES (1624, 1, 'completed', '2024-03-13', '2024-03-20', null, 1, 1);

INSERT INTO Order_Items (order_id, item_id, product_id, quantity, list_price, discount)
VALUES (1624, 1, 3, 6, 100.00, 0.00);
COMMIT;