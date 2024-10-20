-- Creating table for Customers
CREATE TABLE Customers (
    customer_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    phone TEXT,
    email TEXT ,
    street TEXT,
    city TEXT,
    "state" TEXT,
    zip_code INTEGER
);

-- Creating table for Staffs
CREATE TABLE Staffs (
    staff_id INTEGER PRIMARY KEY,
    first_name TEXT NOT NULL,
    last_name TEXT NOT NULL,
    email TEXT UNIQUE,
    phone TEXT,
    active INTEGER,
    store_id INTEGER,
    manager_id INTEGER,
    FOREIGN KEY (store_id) REFERENCES Stores(store_id),
    FOREIGN KEY (manager_id) REFERENCES Staffs(staff_id)
);

-- Creating table for Categories
CREATE TABLE Categories (
    category_id INTEGER PRIMARY KEY,
    category_name TEXT NOT NULL UNIQUE
);

-- Creating table for Products
CREATE TABLE Products (
    product_id INTEGER PRIMARY KEY,
    product_name TEXT NOT NULL,
    brand_id INTEGER,
    category_id INTEGER,
    model_year INTEGER,
    list_price REAL NOT NULL,
    FOREIGN KEY (brand_id) REFERENCES Brands(brand_id),
    FOREIGN KEY (category_id) REFERENCES Categories(category_id)
);

-- Creating table for Orders
CREATE TABLE Orders (
    order_id INTEGER PRIMARY KEY,
    customer_id INTEGER,
    order_status TEXT NOT NULL,
    order_date TEXT NOT NULL,
    required_date TEXT,
    shipped_date TEXT,
    store_id INTEGER,
    staff_id INTEGER,
    FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
    FOREIGN KEY (store_id) REFERENCES Stores(store_id),
    FOREIGN KEY (staff_id) REFERENCES Staffs(staff_id)
);

-- Creating table for Stores
CREATE TABLE Stores (
    store_id INTEGER PRIMARY KEY,
    store_name TEXT NOT NULL,
    phone TEXT,
    email TEXT UNIQUE,
    street TEXT,
    city TEXT,
    state TEXT,
    zip_code TEXT
);

-- Creating table for Brands
CREATE TABLE Brands (
    brand_id INTEGER PRIMARY KEY,
    brand_name TEXT NOT NULL UNIQUE
);

-- Creating table for Stocks
CREATE TABLE Stocks (
    store_id INTEGER,
    product_id INTEGER,
    quantity INTEGER NOT NULL,
    PRIMARY KEY (store_id, product_id),
    FOREIGN KEY (store_id) REFERENCES Stores(store_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Creating table for Order_Items
CREATE TABLE Order_Items (
    order_id INTEGER,
    item_id INTEGER,
    product_id INTEGER,
    quantity INTEGER NOT NULL,
    list_price REAL NOT NULL,
    discount REAL NOT NULL,
    PRIMARY KEY (order_id, item_id),
    FOREIGN KEY (order_id) REFERENCES Orders(order_id),
    FOREIGN KEY (product_id) REFERENCES Products(product_id)
);

-- Creating view for ProductSales
CREATE VIEW ProductSalesView AS
SELECT Products.product_id, product_name, SUM(quantity) AS total_quantity_sold
FROM Order_Items
JOIN Products ON Order_Items.product_id = Products.product_id
GROUP BY Order_Items.product_id, product_name
ORDER BY total_quantity_sold DESC;

-- Creating view for StaffSales
CREATE VIEW StaffSalesView AS
SELECT 
    Staffs.staff_id, 
    first_name, 
    last_name, 
    COUNT(order_id) AS total_sales
FROM Staffs
JOIN Orders ON Staffs.staff_id = Orders.staff_id
GROUP BY Orders.staff_id
ORDER BY total_sales DESC;

-- Creating view for AvailableProducts
CREATE VIEW AvailableProductsView AS
SELECT category_name, product_name, model_year, AVG(quantity) AS average_stock
FROM Products
JOIN Categories ON Products.category_id = Categories.category_id
JOIN Stocks ON Products.product_id = Stocks.product_id
GROUP BY category_name, product_name, model_year;

-- Creating view for TopSalesByStore
CREATE VIEW TopSalesByStore AS
SELECT store_id, COUNT(order_id) AS total_sales
FROM Orders
GROUP BY store_id
ORDER BY total_sales DESC;

-- Creating view for TopSalesByCategory
CREATE VIEW TopSalesByCategory AS
SELECT Categories.category_name, SUM(Order_Items.quantity) AS total_sales
FROM Products
JOIN Categories ON Products.category_id = Categories.category_id
JOIN Order_Items ON Products.product_id = Order_Items.product_id
GROUP BY Categories.category_name
ORDER BY total_sales DESC;

-- Creating view for TopSalesByBrand
CREATE VIEW TopSalesByBrand AS
SELECT Brands.brand_name, SUM(Order_Items.quantity) AS total_sales
FROM Products
JOIN Brands ON Products.brand_id = Brands.brand_id
JOIN Order_Items ON Products.product_id = Order_Items.product_id
GROUP BY Brands.brand_name
ORDER BY total_sales DESC;

-- Creating trigger for stock reduction after an order is placed
CREATE TRIGGER reduce_stock_after_order
AFTER INSERT ON Order_Items
FOR EACH ROW
BEGIN
    UPDATE Stocks
    SET quantity = quantity - NEW.quantity
    WHERE product_id = NEW.product_id AND store_id = (SELECT store_id FROM Orders WHERE order_id = NEW.order_id);
END;

-- Creating index for better performance on Order_Items table
CREATE INDEX idx_order_items_products_brands ON Order_Items(product_id, quantity);

-- Creating trigger for soft deleting a product
CREATE TRIGGER soft_delete_product
INSTEAD OF DELETE ON Active_Products
FOR EACH ROW
BEGIN
    UPDATE Products
    SET is_deleted = 1
    WHERE product_id = OLD.product_id;
END;

-- Creating trigger for re-inserting a temporarily removed product
CREATE TRIGGER soft_insert_product
INSTEAD OF INSERT ON Active_Products
FOR EACH ROW
BEGIN
    INSERT OR IGNORE INTO Products (product_id, product_name, is_deleted)
    VALUES (NEW.product_id, NEW.product_name, 0);

    UPDATE Products
    SET is_deleted = 0, product_name = NEW.product_name
    WHERE product_id = NEW.product_id;
END;