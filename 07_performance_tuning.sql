-- =====================================================
-- DB2 Performance Tuning Examples
-- =====================================================
-- Demonstrates: Query optimization, indexing strategies,
-- explain plans, monitoring, and tuning techniques
-- =====================================================

-- -----------------------------------------------------
-- Example 1: Create Indexes for Performance
-- -----------------------------------------------------

-- Before optimization: Table scan on large table
-- Check existing indexes
SELECT 
    INDNAME AS index_name,
    TABNAME AS table_name,
    COLNAMES AS column_names,
    UNIQUERULE AS is_unique,
    INDEXTYPE AS index_type
FROM SYSCAT.INDEXES
WHERE TABNAME = 'ORDERS'
ORDER BY INDNAME;

-- Create strategic indexes
CREATE INDEX idx_orders_customer_date 
    ON orders(customer_id, order_date);

CREATE INDEX idx_orders_status_date 
    ON orders(order_status, order_date);

CREATE INDEX idx_order_items_product 
    ON order_items(product_id, order_id);

-- Create covering index for common query pattern
CREATE INDEX idx_sales_date_product_customer 
    ON sales(sale_date, product_id, customer_id) 
    INCLUDE (sale_amount, quantity_sold);

-- -----------------------------------------------------
-- Example 2: Query Optimization - Rewrite Inefficient Query
-- -----------------------------------------------------

-- INEFFICIENT: Subquery in SELECT list
SELECT 
    o.order_id,
    o.order_date,
    (SELECT customer_name FROM customers WHERE customer_id = o.customer_id) AS customer_name,
    (SELECT COUNT(*) FROM order_items WHERE order_id = o.order_id) AS item_count
FROM orders o;

-- OPTIMIZED: Use JOIN instead
SELECT 
    o.order_id,
    o.order_date,
    c.customer_name,
    COUNT(oi.item_id) AS item_count
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
GROUP BY o.order_id, o.order_date, c.customer_name;

-- -----------------------------------------------------
-- Example 3: Using FETCH FIRST for Pagination
-- -----------------------------------------------------

-- Efficient top-N query
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
ORDER BY unit_price DESC
FETCH FIRST 10 ROWS ONLY;

-- Pagination with OFFSET
SELECT 
    product_id,
    product_name,
    unit_price
FROM products
ORDER BY product_id
OFFSET 20 ROWS
FETCH NEXT 10 ROWS ONLY;

-- -----------------------------------------------------
-- Example 4: EXPLAIN Plan Analysis
-- -----------------------------------------------------

-- Enable explain
SET CURRENT EXPLAIN MODE = EXPLAIN;

-- Run query to capture explain
SELECT 
    c.customer_name,
    COUNT(o.order_id) AS order_count,
    SUM(o.total_amount) AS total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.country = 'USA'
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 10000
ORDER BY total_spent DESC;

-- Disable explain
SET CURRENT EXPLAIN MODE = NO;

-- View explain data
SELECT 
    EXPLAIN_TIME,
    EXPLAIN_LEVEL,
    EXPLAIN_OPTION,
    QUERYNO,
    QUERYTAG
FROM EXPLAIN_STATEMENT
ORDER BY EXPLAIN_TIME DESC
FETCH FIRST 5 ROWS ONLY;

-- -----------------------------------------------------
-- Example 5: Statistics and RUNSTATS
-- -----------------------------------------------------

-- Update table statistics for better query plans
CALL SYSPROC.ADMIN_CMD('RUNSTATS ON TABLE samples.orders 
    WITH DISTRIBUTION AND DETAILED INDEXES ALL');

-- Update statistics for specific columns
CALL SYSPROC.ADMIN_CMD('RUNSTATS ON TABLE samples.sales 
    ON COLUMNS (sale_date, product_id, customer_id) 
    WITH DISTRIBUTION');

-- -----------------------------------------------------
-- Example 6: Optimize JOIN Order
-- -----------------------------------------------------

-- INEFFICIENT: Large table first
SELECT /*+ inefficient */
    s.sale_date,
    p.product_name,
    c.customer_name,
    s.sale_amount
FROM sales s  -- Large table
JOIN customers c ON s.customer_id = c.customer_id
JOIN products p ON s.product_id = p.product_id
WHERE c.country = 'USA'
  AND p.category_id = 5;

-- OPTIMIZED: Filter first, then join
SELECT 
    s.sale_date,
    p.product_name,
    c.customer_name,
    s.sale_amount
FROM (
    SELECT customer_id, customer_name 
    FROM customers 
    WHERE country = 'USA'
) c
JOIN sales s ON c.customer_id = s.customer_id
JOIN (
    SELECT product_id, product_name 
    FROM products 
    WHERE category_id = 5
) p ON s.product_id = p.product_id;

-- -----------------------------------------------------
-- Example 7: Using EXISTS vs IN
-- -----------------------------------------------------

-- LESS EFFICIENT: IN with subquery
SELECT customer_name
FROM customers
WHERE customer_id IN (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE order_date >= CURRENT DATE - 30 DAYS
);

-- MORE EFFICIENT: EXISTS
SELECT customer_name
FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id 
      AND o.order_date >= CURRENT DATE - 30 DAYS
);

-- -----------------------------------------------------
-- Example 8: Avoid Functions on Indexed Columns
-- -----------------------------------------------------

-- INEFFICIENT: Function on indexed column
SELECT * 
FROM orders
WHERE YEAR(order_date) = 2024 
  AND MONTH(order_date) = 6;

-- OPTIMIZED: Use range instead
SELECT * 
FROM orders
WHERE order_date >= DATE('2024-06-01')
  AND order_date < DATE('2024-07-01');

-- -----------------------------------------------------
-- Example 9: Materialized Query Table (MQT)
-- -----------------------------------------------------

-- Create summary table for frequently accessed aggregation
CREATE TABLE customer_order_summary AS (
    SELECT 
        c.customer_id,
        c.customer_name,
        c.country,
        COUNT(o.order_id) AS order_count,
        SUM(o.total_amount) AS total_spent,
        AVG(o.total_amount) AS avg_order_value,
        MAX(o.order_date) AS last_order_date
    FROM customers c
    LEFT JOIN orders o ON c.customer_id = o.customer_id
    GROUP BY c.customer_id, c.customer_name, c.country
) DATA INITIALLY DEFERRED REFRESH DEFERRED;

-- Refresh the MQT
REFRESH TABLE customer_order_summary;

-- Enable MQT for query optimization
SET CURRENT QUERY OPTIMIZATION = 5;
SET CURRENT REFRESH AGE = ANY;

-- Query automatically uses MQT when appropriate
SELECT customer_name, total_spent
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.customer_name
HAVING SUM(o.total_amount) > 50000;

-- -----------------------------------------------------
-- Example 10: Query Performance Monitoring
-- -----------------------------------------------------

-- Monitor currently executing statements
SELECT 
    AGENT_ID,
    APPL_NAME,
    CLIENT_APPLNAME,
    SUBSTR(STMT_TEXT, 1, 100) AS statement,
    ROWS_READ,
    ROWS_RETURNED,
    TOTAL_CPU_TIME / 1000 AS cpu_seconds,
    POOL_DATA_L_READS + POOL_INDEX_L_READS AS logical_reads,
    POOL_DATA_P_READS + POOL_INDEX_P_READS AS physical_reads
FROM TABLE(MON_GET_PKG_CACHE_STMT(NULL, NULL, NULL, -2))
ORDER BY TOTAL_CPU_TIME DESC
FETCH FIRST 10 ROWS ONLY;

-- -----------------------------------------------------
-- Example 11: Identify Missing Indexes
-- -----------------------------------------------------

-- Find columns frequently used in WHERE but not indexed
SELECT 
    TABSCHEMA,
    TABNAME,
    COLNAME,
    COLCARD AS distinct_values,
    NUMNULLS AS null_count
FROM SYSCAT.COLUMNS
WHERE TABSCHEMA = 'SAMPLES'
  AND TABNAME IN ('ORDERS', 'SALES', 'CUSTOMERS')
  AND COLNAME NOT IN (
    SELECT SUBSTR(COLNAMES, 2, LENGTH(COLNAMES)-2)
    FROM SYSCAT.INDEXES
    WHERE TABSCHEMA = 'SAMPLES'
      AND TABNAME = SYSCAT.COLUMNS.TABNAME
  )
ORDER BY TABNAME, COLCARD DESC;

-- -----------------------------------------------------
-- Example 12: Partition Table for Performance
-- -----------------------------------------------------

-- Create partitioned table by date range
CREATE TABLE sales_partitioned (
    sale_id INTEGER NOT NULL,
    sale_date DATE NOT NULL,
    product_id INTEGER,
    customer_id INTEGER,
    sale_amount DECIMAL(15,2),
    PRIMARY KEY (sale_id, sale_date)
)
PARTITION BY RANGE (sale_date)
(
    PARTITION q1_2024 STARTING '2024-01-01' ENDING '2024-03-31',
    PARTITION q2_2024 STARTING '2024-04-01' ENDING '2024-06-30',
    PARTITION q3_2024 STARTING '2024-07-01' ENDING '2024-09-30',
    PARTITION q4_2024 STARTING '2024-10-01' ENDING '2024-12-31'
);

-- Queries automatically use partition elimination
SELECT * 
FROM sales_partitioned
WHERE sale_date BETWEEN '2024-04-01' AND '2024-04-30';

-- -----------------------------------------------------
-- Example 13: Optimize Aggregation Queries
-- -----------------------------------------------------

-- Create clustering index for better data locality
CREATE INDEX idx_sales_clustered 
    ON sales(sale_date, product_id, customer_id) 
    CLUSTER;

-- Reorganize table to physically cluster data
CALL SYSPROC.ADMIN_CMD('REORG TABLE samples.sales 
    INDEX idx_sales_clustered');

-- This query now benefits from clustered data
SELECT 
    sale_date,
    SUM(sale_amount) AS daily_total,
    COUNT(*) AS transaction_count
FROM sales
WHERE sale_date BETWEEN CURRENT DATE - 30 DAYS AND CURRENT DATE
GROUP BY sale_date
ORDER BY sale_date;

-- -----------------------------------------------------
-- Example 14: Buffer Pool Configuration
-- -----------------------------------------------------

-- Check buffer pool hit ratios
SELECT 
    BP_NAME,
    POOL_DATA_L_READS + POOL_INDEX_L_READS AS total_logical_reads,
    POOL_DATA_P_READS + POOL_INDEX_P_READS AS total_physical_reads,
    CASE 
        WHEN (POOL_DATA_L_READS + POOL_INDEX_L_READS) > 0
        THEN DECIMAL(
            (1 - (DECIMAL(POOL_DATA_P_READS + POOL_INDEX_P_READS) / 
                  DECIMAL(POOL_DATA_L_READS + POOL_INDEX_L_READS))) * 100,
            5, 2
        )
        ELSE 0
    END AS hit_ratio_pct
FROM TABLE(MON_GET_BUFFERPOOL(NULL, -2))
WHERE POOL_DATA_L_READS + POOL_INDEX_L_READS > 0;

-- Create separate buffer pool for frequently accessed tables
-- CREATE BUFFERPOOL bp_hot PAGESIZE 8K SIZE 10000 AUTOMATIC;
-- ALTER TABLESPACE tablespace_name BUFFERPOOL bp_hot;

-- -----------------------------------------------------
-- Example 15: Lock Monitoring and Deadlock Detection
-- -----------------------------------------------------

-- Monitor lock waits
SELECT 
    AGENT_ID,
    APPL_NAME,
    SUBSTR(TABNAME, 1, 30) AS table_name,
    LOCK_MODE,
    LOCK_STATUS,
    LOCK_WAIT_START_TIME
FROM TABLE(MON_GET_LOCKS(NULL, -2))
WHERE LOCK_STATUS = 'W'  -- Waiting
ORDER BY LOCK_WAIT_START_TIME;

-- Check for deadlocks
SELECT 
    SUBSTR(APPL_NAME, 1, 20) AS application,
    AGENT_ID,
    DEADLOCK_ID,
    PARTICIPANT_NO,
    STMT_TEXT
FROM TABLE(MON_GET_DEADLOCK(NULL))
ORDER BY DEADLOCK_ID, PARTICIPANT_NO;

-- -----------------------------------------------------
-- Example 16: Query Rewrite with Common Table Expression
-- -----------------------------------------------------

-- INEFFICIENT: Multiple subqueries
SELECT 
    o.order_id,
    (SELECT customer_name FROM customers WHERE customer_id = o.customer_id) AS customer,
    (SELECT COUNT(*) FROM order_items WHERE order_id = o.order_id) AS items,
    (SELECT SUM(line_total) FROM order_items WHERE order_id = o.order_id) AS total
FROM orders o
WHERE o.order_date >= CURRENT DATE - 30 DAYS;

-- OPTIMIZED: Single CTE with JOIN
WITH order_summary AS (
    SELECT 
        oi.order_id,
        COUNT(*) AS item_count,
        SUM(oi.line_total) AS order_total
    FROM order_items oi
    GROUP BY oi.order_id
)
SELECT 
    o.order_id,
    c.customer_name,
    COALESCE(os.item_count, 0) AS items,
    COALESCE(os.order_total, 0) AS total
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN order_summary os ON o.order_id = os.order_id
WHERE o.order_date >= CURRENT DATE - 30 DAYS;

-- -----------------------------------------------------
-- Example 17: Compression for Storage and Performance
-- -----------------------------------------------------

-- Enable table compression
ALTER TABLE sales COMPRESS YES ADAPTIVE;

-- Reorganize to apply compression
CALL SYSPROC.ADMIN_CMD('REORG TABLE samples.sales');

-- Check compression statistics
SELECT 
    TABSCHEMA,
    TABNAME,
    COMPRESSION,
    PCTPAGESSAVED AS pct_space_saved,
    AVGCOMPRESSEDROWSIZE AS avg_compressed_size,
    AVGROWSIZE AS avg_uncompressed_size
FROM SYSCAT.TABLES
WHERE TABSCHEMA = 'SAMPLES'
  AND COMPRESSION = 'Y';

-- -----------------------------------------------------
-- Example 18: Query Governor and Resource Limits
-- -----------------------------------------------------

-- Set query timeout (in seconds)
SET CURRENT QUERY OPTIMIZATION = 5;

-- Limit query execution time
-- SET CURRENT DEGREE = '1';  -- Disable intra-partition parallelism

-- -----------------------------------------------------
-- Example 19: Monitoring Table Access Patterns
-- -----------------------------------------------------

-- View table access statistics
SELECT 
    TABSCHEMA,
    TABNAME,
    ROWS_READ,
    ROWS_INSERTED,
    ROWS_UPDATED,
    ROWS_DELETED,
    TABLE_SCANS,
    CASE 
        WHEN ROWS_READ > 0 
        THEN DECIMAL((TABLE_SCANS * 100.0) / ROWS_READ, 5, 2)
        ELSE 0
    END AS scan_ratio
FROM TABLE(MON_GET_TABLE('SAMPLES', NULL, -2))
WHERE ROWS_READ > 0
ORDER BY ROWS_READ DESC
FETCH FIRST 20 ROWS ONLY;

-- -----------------------------------------------------
-- Example 20: Performance Checklist Query
-- -----------------------------------------------------

-- Comprehensive performance health check
WITH perf_metrics AS (
    SELECT 
        'Buffer Pool Hit Ratio' AS metric_name,
        CAST(AVG(
            CASE 
                WHEN (POOL_DATA_L_READS + POOL_INDEX_L_READS) > 0
                THEN (1 - (DECIMAL(POOL_DATA_P_READS + POOL_INDEX_P_READS) / 
                           DECIMAL(POOL_DATA_L_READS + POOL_INDEX_L_READS))) * 100
                ELSE 0
            END
        ) AS DECIMAL(5,2)) AS metric_value,
        'Should be > 95%' AS recommendation
    FROM TABLE(MON_GET_BUFFERPOOL(NULL, -2))
    
    UNION ALL
    
    SELECT 
        'Active Connections',
        CAST(COUNT(*) AS DECIMAL(5,2)),
        'Monitor for connection leaks'
    FROM TABLE(MON_GET_CONNECTION(NULL, -2))
    
    UNION ALL
    
    SELECT 
        'Lock Waits',
        CAST(COUNT(*) AS DECIMAL(5,2)),
        'Should be minimal'
    FROM TABLE(MON_GET_LOCKS(NULL, -2))
    WHERE LOCK_STATUS = 'W'
)
SELECT * FROM perf_metrics;

-- =====================================================
-- Performance Tuning Checklist:
-- =====================================================
-- 1. Keep RUNSTATS up to date (weekly for active tables)
-- 2. Monitor buffer pool hit ratios (target > 95%)
-- 3. Create appropriate indexes (but avoid over-indexing)
-- 4. Use EXPLAIN to understand query execution plans
-- 5. Rewrite inefficient queries (avoid subqueries in SELECT)
-- 6. Use partitioning for large tables
-- 7. Enable compression for large tables
-- 8. Monitor lock contention and deadlocks
-- 9. Use MQTs for frequently accessed aggregations
-- 10. Regular REORG for fragmented tables
-- 11. Set appropriate isolation levels
-- 12. Use connection pooling in applications
-- 13. Monitor slow queries in package cache
-- 14. Optimize JOIN order for large tables
-- 15. Use FETCH FIRST for limiting results
-- =====================================================