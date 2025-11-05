-- =====================================================
-- DB2 Sample Tables Setup Script
-- =====================================================
-- Creates comprehensive sample schema for examples
-- =====================================================

-- Set schema (adjust as needed)
SET SCHEMA = SAMPLES;

-- -----------------------------------------------------
-- Drop existing tables if they exist
-- -----------------------------------------------------
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS bill_of_materials;
DROP TABLE IF EXISTS graph_edges;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS stock_prices;
DROP TABLE IF EXISTS transactions;

-- -----------------------------------------------------
-- Departments Table
-- -----------------------------------------------------
CREATE TABLE departments (
    dept_id INTEGER NOT NULL PRIMARY KEY,
    dept_name VARCHAR(100) NOT NULL,
    location VARCHAR(100),
    budget DECIMAL(15,2)
);

-- -----------------------------------------------------
-- Employees Table (with self-referencing hierarchy)
-- -----------------------------------------------------
CREATE TABLE employees (
    emp_id INTEGER NOT NULL PRIMARY KEY,
    emp_name VARCHAR(100) NOT NULL,
    manager_id INTEGER,
    dept_id INTEGER,
    hire_date DATE,
    salary DECIMAL(10,2),
    email VARCHAR(100),
    FOREIGN KEY (manager_id) REFERENCES employees(emp_id),
    FOREIGN KEY (dept_id) REFERENCES departments(dept_id)
);

CREATE INDEX idx_emp_manager ON employees(manager_id);
CREATE INDEX idx_emp_dept ON employees(dept_id);

-- -----------------------------------------------------
-- Categories Table (hierarchical product categories)
-- -----------------------------------------------------
CREATE TABLE categories (
    cat_id INTEGER NOT NULL PRIMARY KEY,
    cat_name VARCHAR(100) NOT NULL,
    parent_cat_id INTEGER,
    description VARCHAR(500),
    FOREIGN KEY (parent_cat_id) REFERENCES categories(cat_id)
);

CREATE INDEX idx_cat_parent ON categories(parent_cat_id);

-- -----------------------------------------------------
-- Products Table
-- -----------------------------------------------------
CREATE TABLE products (
    product_id INTEGER NOT NULL PRIMARY KEY,
    product_name VARCHAR(200) NOT NULL,
    category_id INTEGER,
    unit_price DECIMAL(10,2),
    stock_quantity INTEGER DEFAULT 0,
    reorder_level INTEGER DEFAULT 10,
    discontinued CHAR(1) DEFAULT 'N',
    created_date DATE DEFAULT CURRENT DATE,
    FOREIGN KEY (category_id) REFERENCES categories(cat_id)
);

CREATE INDEX idx_prod_category ON products(category_id);
CREATE INDEX idx_prod_price ON products(unit_price);

-- -----------------------------------------------------
-- Customers Table
-- -----------------------------------------------------
CREATE TABLE customers (
    customer_id INTEGER NOT NULL PRIMARY KEY,
    customer_name VARCHAR(200) NOT NULL,
    email VARCHAR(100),
    phone VARCHAR(20),
    address VARCHAR(500),
    city VARCHAR(100),
    country VARCHAR(100),
    customer_since DATE,
    customer_status VARCHAR(20) DEFAULT 'ACTIVE',
    credit_limit DECIMAL(15,2)
);

CREATE INDEX idx_cust_status ON customers(customer_status);
CREATE INDEX idx_cust_country ON customers(country);

-- -----------------------------------------------------
-- Orders Table
-- -----------------------------------------------------
CREATE TABLE orders (
    order_id INTEGER NOT NULL PRIMARY KEY,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL,
    ship_date DATE,
    order_status VARCHAR(20) DEFAULT 'PENDING',
    total_amount DECIMAL(15,2),
    payment_method VARCHAR(50),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE INDEX idx_order_customer ON orders(customer_id);
CREATE INDEX idx_order_date ON orders(order_date);
CREATE INDEX idx_order_status ON orders(order_status);

-- -----------------------------------------------------
-- Order Items Table
-- -----------------------------------------------------
CREATE TABLE order_items (
    item_id INTEGER NOT NULL PRIMARY KEY,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    discount_pct DECIMAL(5,2) DEFAULT 0,
    line_total DECIMAL(15,2) GENERATED ALWAYS AS (
        quantity * unit_price * (1 - discount_pct / 100)
    ),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX idx_item_order ON order_items(order_id);
CREATE INDEX idx_item_product ON order_items(product_id);

-- -----------------------------------------------------
-- Bill of Materials (BOM) Table
-- -----------------------------------------------------
CREATE TABLE bill_of_materials (
    bom_id INTEGER NOT NULL PRIMARY KEY,
    parent_part_id VARCHAR(50) NOT NULL,
    component_part_id VARCHAR(50) NOT NULL,
    quantity INTEGER NOT NULL,
    unit_of_measure VARCHAR(20),
    effective_date DATE,
    end_date DATE
);

CREATE INDEX idx_bom_parent ON bill_of_materials(parent_part_id);
CREATE INDEX idx_bom_component ON bill_of_materials(component_part_id);

-- -----------------------------------------------------
-- Graph Edges (for graph traversal examples)
-- -----------------------------------------------------
CREATE TABLE graph_edges (
    edge_id INTEGER NOT NULL PRIMARY KEY,
    from_node VARCHAR(50) NOT NULL,
    to_node VARCHAR(50) NOT NULL,
    weight DECIMAL(10,2) DEFAULT 1,
    edge_type VARCHAR(50)
);

CREATE INDEX idx_graph_from ON graph_edges(from_node);
CREATE INDEX idx_graph_to ON graph_edges(to_node);

-- -----------------------------------------------------
-- Sales Table (for time-series analysis)
-- -----------------------------------------------------
CREATE TABLE sales (
    sale_id INTEGER NOT NULL PRIMARY KEY,
    sale_date DATE NOT NULL,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    quantity_sold INTEGER NOT NULL,
    sale_amount DECIMAL(15,2) NOT NULL,
    cost_amount DECIMAL(15,2),
    profit_amount DECIMAL(15,2) GENERATED ALWAYS AS (
        sale_amount - cost_amount
    ),
    sales_rep_id INTEGER,
    region VARCHAR(50),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE INDEX idx_sales_date ON sales(sale_date);
CREATE INDEX idx_sales_product ON sales(product_id);
CREATE INDEX idx_sales_customer ON sales(customer_id);
CREATE INDEX idx_sales_region ON sales(region);

-- -----------------------------------------------------
-- Stock Prices (for moving average examples)
-- -----------------------------------------------------
CREATE TABLE stock_prices (
    price_id INTEGER NOT NULL PRIMARY KEY,
    stock_symbol VARCHAR(10) NOT NULL,
    trade_date DATE NOT NULL,
    open_price DECIMAL(10,2),
    high_price DECIMAL(10,2),
    low_price DECIMAL(10,2),
    close_price DECIMAL(10,2) NOT NULL,
    volume BIGINT,
    UNIQUE (stock_symbol, trade_date)
);

CREATE INDEX idx_stock_symbol_date ON stock_prices(stock_symbol, trade_date);

-- -----------------------------------------------------
-- Transactions (for employee transaction tracking)
-- -----------------------------------------------------
CREATE TABLE transactions (
    transaction_id INTEGER NOT NULL PRIMARY KEY,
    employee_id INTEGER NOT NULL,
    transaction_date TIMESTAMP NOT NULL,
    transaction_type VARCHAR(50) NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    reference_number VARCHAR(50),
    notes VARCHAR(500),
    FOREIGN KEY (employee_id) REFERENCES employees(emp_id)
);

CREATE INDEX idx_trans_emp ON transactions(employee_id);
CREATE INDEX idx_trans_date ON transactions(transaction_date);
CREATE INDEX idx_trans_type ON transactions(transaction_type);

-- -----------------------------------------------------
-- Summary Views for Convenience
-- -----------------------------------------------------

-- Customer Summary View
CREATE VIEW customer_summary AS
SELECT 
    c.customer_id,
    c.customer_name,
    c.customer_since,
    c.country,
    COUNT(o.order_id) AS total_orders,
    COALESCE(SUM(o.total_amount), 0) AS total_purchases,
    COALESCE(AVG(o.total_amount), 0) AS avg_order_value,
    MAX(o.order_date) AS last_order_date
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name, c.customer_since, c.country;

-- Product Sales View
CREATE VIEW product_sales AS
SELECT 
    p.product_id,
    p.product_name,
    c.cat_name AS category_name,
    COUNT(DISTINCT o.order_id) AS orders_count,
    SUM(oi.quantity) AS total_quantity_sold,
    SUM(oi.line_total) AS total_sales
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
LEFT JOIN categories c ON p.category_id = c.cat_id
GROUP BY p.product_id, p.product_name, c.cat_name;

-- Daily Sales View
CREATE VIEW daily_sales AS
SELECT 
    s.sale_date,
    s.product_id,
    p.product_name,
    SUM(s.quantity_sold) AS quantity_sold,
    SUM(s.sale_amount) AS sales_amount,
    SUM(s.profit_amount) AS profit_amount
FROM sales s
JOIN products p ON s.product_id = p.product_id
GROUP BY s.sale_date, s.product_id, p.product_name;

-- Product Revenue View
CREATE VIEW product_revenue AS
SELECT 
    p.product_name,
    SUM(oi.line_total) AS revenue,
    COUNT(DISTINCT o.order_id) AS num_orders,
    SUM(oi.quantity) AS units_sold
FROM products p
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
GROUP BY p.product_name;

-- -----------------------------------------------------
-- Grant Permissions (adjust as needed)
-- -----------------------------------------------------
-- GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA SAMPLES TO PUBLIC;

COMMIT;

-- =====================================================
-- Summary
-- =====================================================
-- Tables Created:
-- - departments: Department information
-- - employees: Employee hierarchy
-- - categories: Product category hierarchy
-- - products: Product catalog
-- - customers: Customer master data
-- - orders: Order headers
-- - order_items: Order line items
-- - bill_of_materials: BOM hierarchy
-- - graph_edges: Graph relationships
-- - sales: Sales transactions
-- - stock_prices: Stock market data
-- - transactions: Employee transactions
--
-- Views Created:
-- - customer_summary: Aggregated customer metrics
-- - product_sales: Product sales statistics
-- - daily_sales: Daily sales aggregation
-- - product_revenue: Product revenue summary
-- =====================================================