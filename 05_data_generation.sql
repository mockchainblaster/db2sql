-- =====================================================
-- DB2 Data Generation Examples
-- =====================================================
-- Demonstrates: Generating test data, random values,
-- synthetic datasets, and data seeding techniques
-- =====================================================

-- -----------------------------------------------------
-- Example 1: Generate Number Sequence
-- -----------------------------------------------------

-- Create sequence of numbers from 1 to 1000
WITH RECURSIVE number_gen (n) AS (
    SELECT 1 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT n + 1 FROM number_gen WHERE n < 1000
)
SELECT n AS number
FROM number_gen;

-- -----------------------------------------------------
-- Example 2: Generate Date Range
-- -----------------------------------------------------

-- Generate all dates in a year
WITH RECURSIVE date_gen (dt) AS (
    SELECT DATE('2024-01-01') FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT dt + 1 DAY FROM date_gen 
    WHERE dt < DATE('2024-12-31')
)
SELECT 
    dt AS calendar_date,
    DAYNAME(dt) AS day_name,
    DAYOFWEEK(dt) AS day_number,
    WEEK(dt) AS week_number,
    MONTH(dt) AS month_number,
    MONTHNAME(dt) AS month_name,
    QUARTER(dt) AS quarter,
    YEAR(dt) AS year,
    CASE WHEN DAYOFWEEK(dt) IN (1, 7) THEN 'Y' ELSE 'N' END AS is_weekend,
    CASE 
        WHEN DAYOFWEEK(dt) = 1 THEN 'Sunday'
        WHEN DAYOFWEEK(dt) = 7 THEN 'Saturday'
        ELSE 'Weekday'
    END AS day_type
FROM date_gen;

-- -----------------------------------------------------
-- Example 3: Generate Random Customer Data
-- -----------------------------------------------------

-- Generate 100 synthetic customers
WITH RECURSIVE num_seq (n) AS (
    SELECT 1 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT n + 1 FROM num_seq WHERE n < 100
),
random_data AS (
    SELECT 
        n,
        RAND(n) AS rand1,
        RAND(n * 7) AS rand2,
        RAND(n * 13) AS rand3,
        RAND(n * 19) AS rand4
    FROM num_seq
)
SELECT 
    n AS customer_id,
    'Customer_' || LPAD(CAST(n AS VARCHAR(10)), 5, '0') AS customer_name,
    'customer' || n || '@email.com' AS email,
    '555-' || LPAD(CAST(INT(rand1 * 9000) + 1000 AS VARCHAR(4)), 4, '0') AS phone,
    CASE INT(rand2 * 10)
        WHEN 0 THEN 'New York'
        WHEN 1 THEN 'Los Angeles'
        WHEN 2 THEN 'Chicago'
        WHEN 3 THEN 'Houston'
        WHEN 4 THEN 'Phoenix'
        WHEN 5 THEN 'Philadelphia'
        WHEN 6 THEN 'San Antonio'
        WHEN 7 THEN 'San Diego'
        WHEN 8 THEN 'Dallas'
        ELSE 'San Jose'
    END AS city,
    CASE INT(rand3 * 5)
        WHEN 0 THEN 'USA'
        WHEN 1 THEN 'Canada'
        WHEN 2 THEN 'UK'
        WHEN 3 THEN 'Germany'
        ELSE 'France'
    END AS country,
    DATE('2020-01-01') + INT(rand4 * 1500) DAYS AS customer_since,
    DECIMAL(10000 + (rand1 * 90000), 10, 2) AS credit_limit
FROM random_data;

-- -----------------------------------------------------
-- Example 4: Generate Random Transaction Data
-- -----------------------------------------------------

-- Generate 1000 random sales transactions
WITH RECURSIVE num_seq (n) AS (
    SELECT 1 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT n + 1 FROM num_seq WHERE n < 1000
),
random_trans AS (
    SELECT 
        n,
        RAND(n) AS rand1,
        RAND(n * 3) AS rand2,
        RAND(n * 5) AS rand3,
        RAND(n * 7) AS rand4
    FROM num_seq
)
SELECT 
    10000 + n AS transaction_id,
    DATE('2024-01-01') + INT(rand1 * 300) DAYS AS transaction_date,
    1 + INT(rand2 * 20) AS product_id,  -- Assuming 20 products
    1 + INT(rand3 * 10) AS customer_id,  -- Assuming 10 customers
    1 + INT(rand4 * 10) AS quantity,
    DECIMAL(50 + (rand1 * 450), 10, 2) AS unit_price,
    DECIMAL((1 + INT(rand4 * 10)) * (50 + (rand1 * 450)), 15, 2) AS total_amount
FROM random_trans;

-- -----------------------------------------------------
-- Example 5: Generate Time Series Data
-- -----------------------------------------------------

-- Generate hourly data points for 30 days
WITH RECURSIVE hour_gen (dt) AS (
    SELECT TIMESTAMP('2024-01-01-00.00.00') FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT dt + 1 HOUR FROM hour_gen 
    WHERE dt < TIMESTAMP('2024-01-31-23.00.00')
),
metrics AS (
    SELECT 
        dt,
        RAND(HOUR(dt) * DAY(dt)) AS rand1,
        RAND(HOUR(dt) + DAY(dt) * 100) AS rand2
    FROM hour_gen
)
SELECT 
    dt AS timestamp,
    DATE(dt) AS date,
    HOUR(dt) AS hour,
    DECIMAL(18 + (rand1 * 7), 5, 2) AS temperature,
    DECIMAL(40 + (rand2 * 40), 5, 2) AS humidity,
    INT(rand1 * 100) AS sensor_reading,
    CASE 
        WHEN rand1 > 0.8 THEN 'HIGH'
        WHEN rand1 < 0.3 THEN 'LOW'
        ELSE 'NORMAL'
    END AS alert_level
FROM metrics
ORDER BY dt;

-- -----------------------------------------------------
-- Example 6: Generate Hierarchical Organization Data
-- -----------------------------------------------------

-- Generate employee hierarchy
WITH RECURSIVE levels (level_id, level_name, parent_level, employee_count) AS (
    -- Level 1: CEO
    SELECT 1, 'CEO', 0, 1 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    -- Level 2: VPs
    SELECT 2, 'VP', 1, 5 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    -- Level 3: Directors
    SELECT 3, 'Director', 2, 20 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    -- Level 4: Managers
    SELECT 4, 'Manager', 3, 100 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    -- Level 5: Staff
    SELECT 5, 'Staff', 4, 500 FROM SYSIBM.SYSDUMMY1
),
num_seq AS (
    SELECT ROW_NUMBER() OVER () AS n
    FROM levels l1, levels l2, levels l3
    FETCH FIRST 626 ROWS ONLY
)
SELECT 
    1000 + n AS emp_id,
    'Employee_' || LPAD(CAST(n AS VARCHAR(10)), 4, '0') AS emp_name,
    CASE 
        WHEN n = 1 THEN NULL
        WHEN n <= 6 THEN 1001
        WHEN n <= 26 THEN 1001 + ((n - 7) / 4) + 1
        WHEN n <= 126 THEN 1001 + ((n - 27) / 5) + 6
        ELSE 1001 + ((n - 127) / 5) + 26
    END AS manager_id,
    CASE 
        WHEN n = 1 THEN 'CEO'
        WHEN n <= 6 THEN 'VP'
        WHEN n <= 26 THEN 'Director'
        WHEN n <= 126 THEN 'Manager'
        ELSE 'Staff'
    END AS job_level,
    DATE('2015-01-01') + INT(RAND(n) * 3500) DAYS AS hire_date,
    CASE 
        WHEN n = 1 THEN 300000
        WHEN n <= 6 THEN 180000 + INT(RAND(n * 2) * 40000)
        WHEN n <= 26 THEN 130000 + INT(RAND(n * 3) * 30000)
        WHEN n <= 126 THEN 90000 + INT(RAND(n * 5) * 30000)
        ELSE 50000 + INT(RAND(n * 7) * 40000)
    END AS salary
FROM num_seq
WHERE n <= 626;

-- -----------------------------------------------------
-- Example 7: Generate Product Catalog
-- -----------------------------------------------------

-- Generate 50 products across categories
WITH num_seq AS (
    SELECT ROW_NUMBER() OVER () AS n
    FROM SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1
    FETCH FIRST 50 ROWS ONLY
),
product_data AS (
    SELECT 
        n,
        RAND(n) AS rand1,
        RAND(n * 11) AS rand2,
        RAND(n * 13) AS rand3
    FROM num_seq
)
SELECT 
    5000 + n AS product_id,
    CASE INT(rand1 * 5)
        WHEN 0 THEN 'Laptop'
        WHEN 1 THEN 'Phone'
        WHEN 2 THEN 'Tablet'
        WHEN 3 THEN 'Monitor'
        ELSE 'Accessory'
    END || ' Model ' || LPAD(CAST(n AS VARCHAR(10)), 3, '0') AS product_name,
    1 + INT(rand1 * 10) AS category_id,
    DECIMAL(99.99 + (rand2 * 1900), 10, 2) AS unit_price,
    INT(rand3 * 500) AS stock_quantity,
    INT(10 + (rand1 * 50)) AS reorder_level,
    CASE WHEN rand2 > 0.95 THEN 'Y' ELSE 'N' END AS discontinued,
    DATE('2020-01-01') + INT(rand3 * 1500) DAYS AS created_date
FROM product_data;

-- -----------------------------------------------------
-- Example 8: Generate Order Data with Line Items
-- -----------------------------------------------------

-- Generate realistic order data
WITH order_headers AS (
    SELECT 
        ROW_NUMBER() OVER () AS n,
        RAND(ROW_NUMBER() OVER ()) AS rand1,
        RAND(ROW_NUMBER() OVER () * 17) AS rand2
    FROM SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1
    FETCH FIRST 200 ROWS ONLY
)
SELECT 
    20000 + n AS order_id,
    1 + INT(rand1 * 10) AS customer_id,
    DATE('2024-01-01') + INT(rand1 * 300) DAYS AS order_date,
    DATE('2024-01-01') + INT(rand1 * 300) DAYS + INT(1 + rand2 * 7) DAYS AS ship_date,
    CASE INT(rand2 * 4)
        WHEN 0 THEN 'PENDING'
        WHEN 1 THEN 'SHIPPED'
        WHEN 2 THEN 'DELIVERED'
        ELSE 'CANCELLED'
    END AS order_status,
    DECIMAL(100 + (rand1 * 4900), 15, 2) AS total_amount,
    CASE INT(rand2 * 3)
        WHEN 0 THEN 'CREDIT'
        WHEN 1 THEN 'DEBIT'
        ELSE 'WIRE'
    END AS payment_method
FROM order_headers;

-- -----------------------------------------------------
-- Example 9: Generate Random Text Data
-- -----------------------------------------------------

-- Generate product descriptions
WITH num_seq AS (
    SELECT ROW_NUMBER() OVER () AS n
    FROM SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1
    FETCH FIRST 20 ROWS ONLY
)
SELECT 
    n AS product_id,
    'Product ' || n AS product_name,
    CASE INT(RAND(n) * 5)
        WHEN 0 THEN 'High-quality product with excellent features and performance. Perfect for professional use.'
        WHEN 1 THEN 'Budget-friendly option with great value. Ideal for everyday tasks and home use.'
        WHEN 2 THEN 'Premium product with cutting-edge technology. Best-in-class performance and reliability.'
        WHEN 3 THEN 'Compact and portable design. Easy to use with intuitive controls and setup.'
        ELSE 'Versatile product suitable for various applications. Durable construction and long-lasting.'
    END AS description,
    CASE INT(RAND(n * 3) * 4)
        WHEN 0 THEN 'electronics, gadget, technology'
        WHEN 1 THEN 'home, office, productivity'
        WHEN 2 THEN 'professional, business, enterprise'
        ELSE 'consumer, personal, lifestyle'
    END AS tags
FROM num_seq;

-- -----------------------------------------------------
-- Example 10: Generate Weighted Random Distribution
-- -----------------------------------------------------

-- Generate data with realistic distribution (Pareto principle)
WITH num_seq AS (
    SELECT ROW_NUMBER() OVER () AS n
    FROM SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1
    FETCH FIRST 1000 ROWS ONLY
),
weighted_data AS (
    SELECT 
        n,
        RAND(n) AS rand1,
        POWER(RAND(n * 7), 2) AS weighted_rand  -- Squared for skewed distribution
    FROM num_seq
)
SELECT 
    n AS customer_id,
    INT(weighted_rand * 100) AS purchase_count,
    DECIMAL(weighted_rand * 50000, 15, 2) AS lifetime_value,
    CASE 
        WHEN weighted_rand > 0.95 THEN 'PLATINUM'
        WHEN weighted_rand > 0.80 THEN 'GOLD'
        WHEN weighted_rand > 0.50 THEN 'SILVER'
        ELSE 'BRONZE'
    END AS customer_tier
FROM weighted_data
ORDER BY purchase_count DESC;

-- -----------------------------------------------------
-- Example 11: Generate Correlated Data
-- -----------------------------------------------------

-- Generate sales data with seasonal patterns
WITH dates AS (
    SELECT 
        DATE('2024-01-01') + ROW_NUMBER() OVER () - 1 DAYS AS sale_date
    FROM SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1
    FETCH FIRST 365 ROWS ONLY
),
seasonal_data AS (
    SELECT 
        sale_date,
        DAYOFYEAR(sale_date) AS day_num,
        RAND(DAYOFYEAR(sale_date)) AS base_rand,
        -- Seasonal multiplier (higher in Q4)
        CASE 
            WHEN MONTH(sale_date) IN (11, 12) THEN 1.5
            WHEN MONTH(sale_date) IN (6, 7, 8) THEN 1.2
            ELSE 1.0
        END AS seasonal_factor,
        -- Weekend multiplier
        CASE 
            WHEN DAYOFWEEK(sale_date) IN (1, 7) THEN 1.3
            ELSE 1.0
        END AS weekend_factor
    FROM dates
)
SELECT 
    sale_date,
    DAYNAME(sale_date) AS day_name,
    INT(50 + (base_rand * 200 * seasonal_factor * weekend_factor)) AS sales_count,
    DECIMAL(5000 + (base_rand * 25000 * seasonal_factor * weekend_factor), 15, 2) AS sales_amount,
    seasonal_factor,
    weekend_factor
FROM seasonal_data
ORDER BY sale_date;

-- -----------------------------------------------------
-- Example 12: Generate Test Data Insert Script
-- -----------------------------------------------------

-- Create reusable insert script for test data
SELECT 
    'INSERT INTO test_customers VALUES (' ||
    n || ', ' ||
    '''Customer_' || LPAD(CAST(n AS VARCHAR(5)), 5, '0') || ''', ' ||
    '''customer' || n || '@test.com'', ' ||
    '''555-' || LPAD(CAST(INT(RAND(n) * 9000) + 1000 AS VARCHAR(4)), 4, '0') || ''', ' ||
    'DATE(''2024-01-01'') + ' || INT(RAND(n * 7) * 365) || ' DAYS);'
    AS insert_statement
FROM (
    SELECT ROW_NUMBER() OVER () AS n
    FROM SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1
    FETCH FIRST 50 ROWS ONLY
);

-- -----------------------------------------------------
-- Example 13: Generate Sparse Data (with NULLs)
-- -----------------------------------------------------

-- Generate data with realistic NULL patterns
WITH num_seq AS (
    SELECT ROW_NUMBER() OVER () AS n
    FROM SYSIBM.SYSDUMMY1, SYSIBM.SYSDUMMY1
    FETCH FIRST 100 ROWS ONLY
)
SELECT 
    n AS record_id,
    'Record_' || n AS record_name,
    CASE WHEN RAND(n) > 0.3 THEN 'value_' || n ELSE NULL END AS optional_field1,
    CASE WHEN RAND(n * 3) > 0.5 THEN INT(RAND(n) * 100) ELSE NULL END AS optional_field2,
    CASE WHEN RAND(n * 7) > 0.7 THEN DATE('2024-01-01') + INT(RAND(n) * 365) DAYS ELSE NULL END AS optional_date
FROM num_seq;

-- =====================================================
-- Data Generation Best Practices:
-- =====================================================
-- 1. Use RAND() with different seeds for variety
-- 2. Create realistic distributions (not just uniform)
-- 3. Add seasonal patterns for time-series data
-- 4. Include appropriate NULL values
-- 5. Generate hierarchical data correctly
-- 6. Use CTEs for complex generation logic
-- 7. Add constraints to match production data
-- 8. Generate correlated fields logically
-- 9. Include edge cases in test data
-- 10. Document data generation rules
-- =====================================================