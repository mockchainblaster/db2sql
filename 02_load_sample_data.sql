-- =====================================================
-- DB2 Sample Data Loading Script
-- =====================================================
-- Loads realistic test data into sample tables
-- =====================================================

SET SCHEMA = SAMPLES;

-- -----------------------------------------------------
-- Load Departments
-- -----------------------------------------------------
INSERT INTO departments (dept_id, dept_name, location, budget) VALUES
(1, 'Executive', 'New York', 5000000.00),
(2, 'Sales', 'Chicago', 3000000.00),
(3, 'Marketing', 'Los Angeles', 2000000.00),
(4, 'Engineering', 'San Francisco', 4500000.00),
(5, 'Human Resources', 'New York', 1500000.00),
(6, 'Finance', 'New York', 2500000.00),
(7, 'Operations', 'Dallas', 3500000.00),
(8, 'Customer Service', 'Austin', 1800000.00),
(9, 'IT', 'Seattle', 4000000.00),
(10, 'Research', 'Boston', 3200000.00);

-- -----------------------------------------------------
-- Load Employees (hierarchical structure)
-- -----------------------------------------------------
-- CEO (no manager)
INSERT INTO employees (emp_id, emp_name, manager_id, dept_id, hire_date, salary, email) VALUES
(1, 'Sarah Johnson', NULL, 1, '2015-01-15', 250000.00, 'sarah.johnson@company.com');

-- C-Level Executives (report to CEO)
INSERT INTO employees (emp_id, emp_name, manager_id, dept_id, hire_date, salary, email) VALUES
(2, 'Michael Chen', 1, 2, '2015-03-20', 180000.00, 'michael.chen@company.com'),
(3, 'Emily Rodriguez', 1, 3, '2015-06-10', 175000.00, 'emily.rodriguez@company.com'),
(4, 'David Kim', 1, 4, '2015-02-28', 200000.00, 'david.kim@company.com'),
(5, 'Jennifer Smith', 1, 6, '2015-04-15', 185000.00, 'jennifer.smith@company.com');

-- Managers (report to C-Level)
INSERT INTO employees (emp_id, emp_name, manager_id, dept_id, hire_date, salary, email) VALUES
(6, 'Robert Brown', 2, 2, '2016-01-10', 120000.00, 'robert.brown@company.com'),
(7, 'Lisa Anderson', 2, 2, '2016-03-15', 115000.00, 'lisa.anderson@company.com'),
(8, 'James Wilson', 3, 3, '2016-05-20', 110000.00, 'james.wilson@company.com'),
(9, 'Maria Garcia', 4, 4, '2016-02-01', 140000.00, 'maria.garcia@company.com'),
(10, 'Thomas Lee', 4, 4, '2016-04-12', 135000.00, 'thomas.lee@company.com'),
(11, 'Patricia Martinez', 5, 6, '2016-06-30', 105000.00, 'patricia.martinez@company.com');

-- Team Members
INSERT INTO employees (emp_id, emp_name, manager_id, dept_id, hire_date, salary, email) VALUES
(12, 'Christopher Taylor', 6, 2, '2017-01-15', 85000.00, 'christopher.taylor@company.com'),
(13, 'Nancy Thomas', 6, 2, '2017-03-20', 82000.00, 'nancy.thomas@company.com'),
(14, 'Daniel Jackson', 7, 2, '2017-05-10', 88000.00, 'daniel.jackson@company.com'),
(15, 'Karen White', 7, 2, '2017-07-22', 86000.00, 'karen.white@company.com'),
(16, 'Matthew Harris', 8, 3, '2017-02-14', 78000.00, 'matthew.harris@company.com'),
(17, 'Betty Clark', 8, 3, '2017-04-18', 75000.00, 'betty.clark@company.com'),
(18, 'Steven Lewis', 9, 4, '2017-01-20', 110000.00, 'steven.lewis@company.com'),
(19, 'Helen Robinson', 9, 4, '2017-03-25', 105000.00, 'helen.robinson@company.com'),
(20, 'Paul Walker', 10, 4, '2017-05-30', 108000.00, 'paul.walker@company.com');

-- -----------------------------------------------------
-- Load Categories (hierarchical)
-- -----------------------------------------------------
-- Top Level Categories
INSERT INTO categories (cat_id, cat_name, parent_cat_id, description) VALUES
(1, 'Electronics', NULL, 'Electronic devices and accessories'),
(2, 'Clothing', NULL, 'Apparel and fashion'),
(3, 'Home & Garden', NULL, 'Home improvement and garden supplies'),
(4, 'Sports', NULL, 'Sports equipment and accessories');

-- Level 2 Categories
INSERT INTO categories (cat_id, cat_name, parent_cat_id, description) VALUES
(5, 'Computers', 1, 'Desktop and laptop computers'),
(6, 'Mobile Devices', 1, 'Phones and tablets'),
(7, 'Audio', 1, 'Headphones and speakers'),
(8, 'Men Clothing', 2, 'Mens apparel'),
(9, 'Women Clothing', 2, 'Womens apparel'),
(10, 'Furniture', 3, 'Home furniture'),
(11, 'Tools', 3, 'Hand and power tools'),
(12, 'Fitness', 4, 'Fitness equipment'),
(13, 'Outdoor', 4, 'Outdoor sports gear');

-- Level 3 Categories
INSERT INTO categories (cat_id, cat_name, parent_cat_id, description) VALUES
(14, 'Laptops', 5, 'Portable computers'),
(15, 'Desktops', 5, 'Desktop computers'),
(16, 'Smartphones', 6, 'Mobile phones'),
(17, 'Tablets', 6, 'Tablet devices'),
(18, 'Headphones', 7, 'Over-ear and in-ear headphones'),
(19, 'Speakers', 7, 'Bluetooth and wired speakers');

-- -----------------------------------------------------
-- Load Products
-- -----------------------------------------------------
INSERT INTO products (product_id, product_name, category_id, unit_price, stock_quantity) VALUES
-- Laptops
(1, 'UltraBook Pro 15', 14, 1299.99, 45),
(2, 'Business Laptop X1', 14, 899.99, 62),
(3, 'Gaming Laptop Beast', 14, 1899.99, 28),
-- Desktops
(4, 'Workstation Pro', 15, 1599.99, 35),
(5, 'Home Desktop Basic', 15, 599.99, 78),
-- Smartphones
(6, 'SmartPhone X Pro', 16, 999.99, 120),
(7, 'SmartPhone Lite', 16, 499.99, 180),
(8, 'SmartPhone Ultra', 16, 1299.99, 95),
-- Tablets
(9, 'Tablet Pro 12', 17, 799.99, 88),
(10, 'Tablet Mini', 17, 399.99, 145),
-- Headphones
(11, 'Noise Cancel Pro', 18, 349.99, 210),
(12, 'Wireless Buds', 18, 149.99, 340),
-- Speakers
(13, 'Portable Speaker XL', 19, 199.99, 125),
(14, 'Smart Speaker Home', 19, 99.99, 280),
-- Clothing
(15, 'Men Business Suit', 8, 399.99, 45),
(16, 'Men Casual Jeans', 8, 79.99, 156),
(17, 'Women Summer Dress', 9, 89.99, 98),
(18, 'Women Winter Coat', 9, 249.99, 67),
-- Furniture
(19, 'Office Chair Ergonomic', 10, 299.99, 56),
(20, 'Standing Desk', 10, 599.99, 34);

-- -----------------------------------------------------
-- Load Customers
-- -----------------------------------------------------
INSERT INTO customers (customer_id, customer_name, email, phone, city, country, customer_since, credit_limit) VALUES
(1, 'Acme Corporation', 'orders@acme.com', '555-0101', 'New York', 'USA', '2020-01-15', 50000.00),
(2, 'Tech Solutions Inc', 'sales@techsol.com', '555-0102', 'San Francisco', 'USA', '2020-02-20', 75000.00),
(3, 'Global Traders Ltd', 'info@globaltraders.com', '555-0103', 'London', 'UK', '2020-03-10', 100000.00),
(4, 'MegaMart Retail', 'purchasing@megamart.com', '555-0104', 'Chicago', 'USA', '2020-04-05', 150000.00),
(5, 'European Imports', 'orders@euroimports.eu', '555-0105', 'Paris', 'France', '2020-05-12', 80000.00),
(6, 'Asia Pacific Trading', 'sales@aptrading.com', '555-0106', 'Tokyo', 'Japan', '2020-06-18', 120000.00),
(7, 'Southwest Distributors', 'orders@swdist.com', '555-0107', 'Dallas', 'USA', '2020-07-22', 60000.00),
(8, 'Nordic Supply Co', 'info@nordicsupply.com', '555-0108', 'Stockholm', 'Sweden', '2020-08-30', 70000.00),
(9, 'Canadian Wholesale', 'orders@canwholesale.ca', '555-0109', 'Toronto', 'Canada', '2020-09-14', 90000.00),
(10, 'Southern Ventures', 'sales@southvent.com', '555-0110', 'Miami', 'USA', '2020-10-20', 55000.00);

-- -----------------------------------------------------
-- Load Orders (spread across 2024)
-- -----------------------------------------------------
INSERT INTO orders (order_id, customer_id, order_date, ship_date, order_status, total_amount, payment_method) VALUES
(1, 1, '2024-01-05', '2024-01-07', 'DELIVERED', 15679.85, 'CREDIT'),
(2, 2, '2024-01-12', '2024-01-15', 'DELIVERED', 28945.50, 'WIRE'),
(3, 3, '2024-01-20', '2024-01-23', 'DELIVERED', 45123.75, 'CREDIT'),
(4, 4, '2024-02-03', '2024-02-06', 'DELIVERED', 67890.20, 'WIRE'),
(5, 5, '2024-02-15', '2024-02-18', 'DELIVERED', 34567.80, 'CREDIT'),
(6, 1, '2024-03-01', '2024-03-04', 'DELIVERED', 21345.60, 'CREDIT'),
(7, 2, '2024-03-12', '2024-03-15', 'DELIVERED', 39876.45, 'WIRE'),
(8, 6, '2024-04-05', '2024-04-08', 'DELIVERED', 52341.90, 'WIRE'),
(9, 7, '2024-04-18', '2024-04-21', 'DELIVERED', 18765.30, 'CREDIT'),
(10, 8, '2024-05-02', '2024-05-05', 'SHIPPED', 29876.55, 'CREDIT'),
(11, 9, '2024-05-15', '2024-05-18', 'SHIPPED', 41234.70, 'WIRE'),
(12, 10, '2024-05-28', NULL, 'PENDING', 15678.90, 'CREDIT');

-- -----------------------------------------------------
-- Load Order Items
-- -----------------------------------------------------
INSERT INTO order_items (item_id, order_id, product_id, quantity, unit_price, discount_pct) VALUES
-- Order 1
(1, 1, 1, 5, 1299.99, 10),
(2, 1, 11, 10, 349.99, 5),
(3, 1, 13, 8, 199.99, 0),
-- Order 2
(4, 2, 3, 10, 1899.99, 15),
(5, 2, 9, 15, 799.99, 10),
-- Order 3
(6, 3, 6, 25, 999.99, 12),
(7, 3, 12, 40, 149.99, 8),
(8, 3, 14, 30, 99.99, 5),
-- Order 4
(9, 4, 4, 20, 1599.99, 15),
(10, 4, 19, 35, 299.99, 10),
(11, 4, 20, 25, 599.99, 12),
-- Order 5
(12, 5, 7, 50, 499.99, 18),
(13, 5, 10, 30, 399.99, 10);

-- -----------------------------------------------------
-- Load Bill of Materials (simple BOM structure)
-- -----------------------------------------------------
INSERT INTO bill_of_materials (bom_id, parent_part_id, component_part_id, quantity, unit_of_measure) VALUES
(1, 'PRODUCT-001', 'PART-A', 2, 'EA'),
(2, 'PRODUCT-001', 'PART-B', 4, 'EA'),
(3, 'PRODUCT-001', 'PART-C', 1, 'EA'),
(4, 'PART-A', 'PART-D', 3, 'EA'),
(5, 'PART-A', 'PART-E', 2, 'EA'),
(6, 'PART-B', 'PART-F', 1, 'EA'),
(7, 'PART-C', 'PART-G', 5, 'EA'),
(8, 'PART-D', 'PART-H', 2, 'EA');

-- -----------------------------------------------------
-- Load Graph Edges (for path finding examples)
-- -----------------------------------------------------
INSERT INTO graph_edges (edge_id, from_node, to_node, weight, edge_type) VALUES
(1, 'A', 'B', 4, 'ROUTE'),
(2, 'A', 'C', 2, 'ROUTE'),
(3, 'B', 'D', 5, 'ROUTE'),
(4, 'C', 'D', 8, 'ROUTE'),
(5, 'C', 'E', 10, 'ROUTE'),
(6, 'D', 'E', 2, 'ROUTE'),
(7, 'D', 'F', 6, 'ROUTE'),
(8, 'E', 'Z', 3, 'ROUTE'),
(9, 'F', 'Z', 1, 'ROUTE'),
(10, 'START', 'A', 1, 'ROUTE'),
(11, 'B', 'END', 7, 'ROUTE');

-- -----------------------------------------------------
-- Load Sales Data (for time series analysis)
-- -----------------------------------------------------
-- Generate sales for January through October 2024
INSERT INTO sales (sale_id, sale_date, product_id, customer_id, quantity_sold, sale_amount, cost_amount, sales_rep_id, region) VALUES
-- January 2024
(1, '2024-01-05', 1, 1, 2, 2599.98, 1800.00, 12, 'Northeast'),
(2, '2024-01-08', 6, 2, 5, 4999.95, 3500.00, 13, 'West'),
(3, '2024-01-12', 11, 3, 10, 3499.90, 2450.00, 14, 'Midwest'),
(4, '2024-01-15', 3, 4, 3, 5699.97, 4200.00, 15, 'South'),
(5, '2024-01-20', 7, 5, 8, 3999.92, 2800.00, 12, 'Northeast'),
-- February 2024
(6, '2024-02-03', 9, 1, 4, 3199.96, 2240.00, 13, 'West'),
(7, '2024-02-10', 12, 6, 15, 2249.85, 1575.00, 14, 'Midwest'),
(8, '2024-02-14', 4, 7, 2, 3199.98, 2240.00, 15, 'South'),
(9, '2024-02-18', 19, 8, 6, 1799.94, 1260.00, 12, 'Northeast'),
(10, '2024-02-25', 6, 9, 12, 11999.88, 8400.00, 13, 'West');

-- -----------------------------------------------------
-- Load Stock Prices (for moving average examples)
-- -----------------------------------------------------
INSERT INTO stock_prices (price_id, stock_symbol, trade_date, open_price, high_price, low_price, close_price, volume) VALUES
-- TECH stock - 30 days
(1, 'TECH', '2024-01-02', 150.00, 152.50, 149.00, 151.25, 5000000),
(2, 'TECH', '2024-01-03', 151.50, 153.75, 150.50, 152.80, 5200000),
(3, 'TECH', '2024-01-04', 152.80, 155.00, 152.00, 154.60, 5500000),
(4, 'TECH', '2024-01-05', 154.50, 156.25, 153.75, 155.90, 5800000),
(5, 'TECH', '2024-01-08', 156.00, 157.50, 154.50, 156.75, 6000000),
(6, 'TECH', '2024-01-09', 156.75, 158.00, 155.25, 157.40, 5900000),
(7, 'TECH', '2024-01-10', 157.25, 159.50, 156.50, 158.90, 6200000),
(8, 'TECH', '2024-01-11', 158.75, 160.00, 157.75, 159.50, 6100000),
(9, 'TECH', '2024-01-12', 159.50, 161.25, 158.50, 160.80, 6400000),
(10, 'TECH', '2024-01-15', 160.75, 162.00, 159.50, 161.30, 6300000);

-- -----------------------------------------------------
-- Load Transactions
-- -----------------------------------------------------
INSERT INTO transactions (transaction_id, employee_id, transaction_date, transaction_type, amount, reference_number) VALUES
(1, 12, '2024-01-05 10:30:00', 'SALE', 2599.98, 'TXN-001'),
(2, 13, '2024-01-08 14:15:00', 'SALE', 4999.95, 'TXN-002'),
(3, 14, '2024-01-12 09:45:00', 'SALE', 3499.90, 'TXN-003'),
(4, 12, '2024-01-15 16:20:00', 'REFUND', 299.99, 'TXN-004'),
(5, 15, '2024-01-18 11:00:00', 'SALE', 5699.97, 'TXN-005'),
(6, 13, '2024-01-22 13:30:00', 'SALE', 3999.92, 'TXN-006'),
(7, 14, '2024-01-25 10:15:00', 'SALE', 1799.94, 'TXN-007'),
(8, 12, '2024-01-28 15:45:00', 'REFUND', 149.99, 'TXN-008');

COMMIT;

-- =====================================================
-- Data Loading Complete
-- =====================================================
-- Verify row counts:
SELECT 'departments' AS table_name, COUNT(*) AS row_count FROM departments
UNION ALL
SELECT 'employees', COUNT(*) FROM employees
UNION ALL
SELECT 'categories', COUNT(*) FROM categories
UNION ALL
SELECT 'products', COUNT(*) FROM products
UNION ALL
SELECT 'customers', COUNT(*) FROM customers
UNION ALL
SELECT 'orders', COUNT(*) FROM orders
UNION ALL
SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL
SELECT 'bill_of_materials', COUNT(*) FROM bill_of_materials
UNION ALL
SELECT 'graph_edges', COUNT(*) FROM graph_edges
UNION ALL
SELECT 'sales', COUNT(*) FROM sales
UNION ALL
SELECT 'stock_prices', COUNT(*) FROM stock_prices
UNION ALL
SELECT 'transactions', COUNT(*) FROM transactions;
-- =====================================================