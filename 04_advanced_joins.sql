-- =====================================================
-- DB2 Advanced Joins Examples
-- =====================================================
-- Demonstrates: Complex join patterns, cross joins,
-- self-joins, lateral joins, and optimization techniques
-- =====================================================

-- -----------------------------------------------------
-- Example 1: Multiple Table Joins with Aggregation
-- -----------------------------------------------------
-- Join multiple tables with complex aggregations

SELECT 
    c.customer_name,
    c.country,
    COUNT(DISTINCT o.order_id) AS total_orders,
    COUNT(oi.item_id) AS total_items,
    SUM(oi.quantity) AS total_units,
    SUM(oi.line_total) AS total_revenue,
    AVG(o.total_amount) AS avg_order_value,
    STRING_AGG(DISTINCT p.product_name, ', ') AS products_purchased
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
LEFT JOIN order_items oi ON o.order_id = oi.order_id
LEFT JOIN products p ON oi.product_id = p.product_id
GROUP BY c.customer_id, c.customer_name, c.country
HAVING COUNT(o.order_id) > 0
ORDER BY total_revenue DESC;

-- -----------------------------------------------------
-- Example 2: Self-Join for Hierarchical Data
-- -----------------------------------------------------
-- Find employees and their managers

SELECT 
    e.emp_id,
    e.emp_name AS employee,
    e.salary AS emp_salary,
    m.emp_name AS manager,
    m.salary AS mgr_salary,
    e.salary - m.salary AS salary_difference,
    CASE 
        WHEN e.salary > m.salary THEN 'HIGHER THAN MANAGER'
        WHEN e.salary = m.salary THEN 'EQUAL TO MANAGER'
        ELSE 'LOWER THAN MANAGER'
    END AS salary_comparison
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.emp_id
ORDER BY e.emp_id;

-- -----------------------------------------------------
-- Example 3: Finding Gaps - Anti Join Pattern
-- -----------------------------------------------------
-- Find customers who never placed an order

SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    c.customer_since,
    DAYS(CURRENT DATE) - DAYS(c.customer_since) AS days_since_registration
FROM customers c
WHERE NOT EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id
)
ORDER BY c.customer_since;

-- Alternative using LEFT JOIN
SELECT 
    c.customer_id,
    c.customer_name,
    c.email
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_id IS NULL;

-- -----------------------------------------------------
-- Example 4: Finding Overlaps - Intersection Pattern
-- -----------------------------------------------------
-- Find customers who bought products from multiple categories

WITH customer_categories AS (
    SELECT DISTINCT 
        o.customer_id,
        p.category_id
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    JOIN products p ON oi.product_id = p.product_id
)
SELECT 
    c.customer_name,
    COUNT(DISTINCT cc.category_id) AS categories_purchased,
    STRING_AGG(cat.cat_name, ', ') AS category_names
FROM customers c
JOIN customer_categories cc ON c.customer_id = cc.customer_id
JOIN categories cat ON cc.category_id = cat.cat_id
GROUP BY c.customer_id, c.customer_name
HAVING COUNT(DISTINCT cc.category_id) >= 3
ORDER BY categories_purchased DESC;

-- -----------------------------------------------------
-- Example 5: Cross Join - Cartesian Product
-- -----------------------------------------------------
-- Generate all possible product-customer combinations

SELECT 
    c.customer_id,
    c.customer_name,
    p.product_id,
    p.product_name,
    p.unit_price,
    CASE 
        WHEN EXISTS (
            SELECT 1 
            FROM orders o 
            JOIN order_items oi ON o.order_id = oi.order_id
            WHERE o.customer_id = c.customer_id 
              AND oi.product_id = p.product_id
        ) THEN 'PURCHASED'
        ELSE 'NOT PURCHASED'
    END AS purchase_status
FROM customers c
CROSS JOIN products p
WHERE c.customer_id <= 5  -- Limit for demonstration
  AND p.product_id <= 10
ORDER BY c.customer_id, p.product_id;

-- -----------------------------------------------------
-- Example 6: Lateral Join (DB2 11.1+)
-- -----------------------------------------------------
-- Get top 3 orders for each customer

SELECT 
    c.customer_id,
    c.customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    o.order_rank
FROM customers c,
LATERAL (
    SELECT 
        order_id,
        order_date,
        total_amount,
        ROW_NUMBER() OVER (ORDER BY total_amount DESC) AS order_rank
    FROM orders
    WHERE customer_id = c.customer_id
    ORDER BY total_amount DESC
    FETCH FIRST 3 ROWS ONLY
) AS o
ORDER BY c.customer_id, o.order_rank;

-- -----------------------------------------------------
-- Example 7: Inequality Joins
-- -----------------------------------------------------
-- Find all pairs of employees in the same department
-- with different salaries

SELECT 
    e1.emp_name AS employee1,
    e1.salary AS salary1,
    e2.emp_name AS employee2,
    e2.salary AS salary2,
    e1.dept_id AS department,
    ABS(e1.salary - e2.salary) AS salary_gap
FROM employees e1
JOIN employees e2 
    ON e1.dept_id = e2.dept_id 
    AND e1.emp_id < e2.emp_id  -- Avoid duplicates
    AND e1.salary <> e2.salary
ORDER BY e1.dept_id, salary_gap DESC;

-- -----------------------------------------------------
-- Example 8: Range Joins
-- -----------------------------------------------------
-- Find orders placed within 7 days of each other

SELECT 
    o1.order_id AS order1,
    o1.order_date AS date1,
    o2.order_id AS order2,
    o2.order_date AS date2,
    DAYS(o2.order_date) - DAYS(o1.order_date) AS days_apart,
    o1.customer_id
FROM orders o1
JOIN orders o2 
    ON o1.customer_id = o2.customer_id
    AND o1.order_id < o2.order_id
    AND o2.order_date BETWEEN o1.order_date AND o1.order_date + 7 DAYS
ORDER BY o1.customer_id, o1.order_date;

-- -----------------------------------------------------
-- Example 9: Join with Aggregation in ON Clause
-- -----------------------------------------------------
-- Get customers with their average order size

SELECT 
    c.customer_id,
    c.customer_name,
    ao.avg_order_amount,
    ao.order_count,
    CASE 
        WHEN ao.avg_order_amount >= 50000 THEN 'PREMIUM'
        WHEN ao.avg_order_amount >= 20000 THEN 'STANDARD'
        ELSE 'BASIC'
    END AS customer_tier
FROM customers c
LEFT JOIN (
    SELECT 
        customer_id,
        AVG(total_amount) AS avg_order_amount,
        COUNT(*) AS order_count
    FROM orders
    GROUP BY customer_id
) ao ON c.customer_id = ao.customer_id
ORDER BY ao.avg_order_amount DESC NULLS LAST;

-- -----------------------------------------------------
-- Example 10: Complex Multi-Level Aggregation
-- -----------------------------------------------------
-- Category performance with product details

SELECT 
    cat.cat_name AS category,
    COUNT(DISTINCT p.product_id) AS product_count,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity) AS total_units_sold,
    SUM(oi.line_total) AS total_revenue,
    AVG(oi.line_total) AS avg_line_value,
    MAX(oi.line_total) AS max_line_value,
    STRING_AGG(
        DISTINCT p.product_name || ' ($' || CAST(p.unit_price AS VARCHAR(20)) || ')', 
        '; '
    ) AS products
FROM categories cat
LEFT JOIN products p ON cat.cat_id = p.category_id
LEFT JOIN order_items oi ON p.product_id = oi.product_id
LEFT JOIN orders o ON oi.order_id = o.order_id
GROUP BY cat.cat_id, cat.cat_name
HAVING SUM(oi.line_total) IS NOT NULL
ORDER BY total_revenue DESC;

-- -----------------------------------------------------
-- Example 11: Conditional Joins
-- -----------------------------------------------------
-- Join with different conditions based on status

SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_name,
    COALESCE(s1.sale_amount, s2.sale_amount, 0) AS matched_sale_amount,
    CASE 
        WHEN s1.sale_id IS NOT NULL THEN 'EXACT MATCH'
        WHEN s2.sale_id IS NOT NULL THEN 'DATE MATCH'
        ELSE 'NO MATCH'
    END AS match_type
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
LEFT JOIN sales s1 
    ON o.customer_id = s1.customer_id 
    AND o.order_date = s1.sale_date
    AND o.order_status = 'DELIVERED'
LEFT JOIN sales s2
    ON o.customer_id = s2.customer_id
    AND o.order_date = s2.sale_date
    AND o.order_status <> 'DELIVERED'
ORDER BY o.order_id;

-- -----------------------------------------------------
-- Example 12: Join with Window Functions
-- -----------------------------------------------------
-- Running totals per customer with joins

SELECT 
    c.customer_name,
    o.order_id,
    o.order_date,
    o.total_amount,
    SUM(o.total_amount) OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date
        ROWS UNBOUNDED PRECEDING
    ) AS running_total,
    ROW_NUMBER() OVER (
        PARTITION BY c.customer_id 
        ORDER BY o.order_date
    ) AS order_sequence
FROM customers c
JOIN orders o ON c.customer_id = o.customer_id
ORDER BY c.customer_id, o.order_date;

-- -----------------------------------------------------
-- Example 13: Recursive Join Pattern
-- -----------------------------------------------------
-- Find all products in the same category tree

WITH RECURSIVE category_tree AS (
    SELECT 
        cat_id,
        cat_name,
        parent_cat_id,
        1 AS level,
        CAST(cat_id AS VARCHAR(1000)) AS path
    FROM categories
    WHERE cat_id = 1  -- Start with Electronics
    
    UNION ALL
    
    SELECT 
        c.cat_id,
        c.cat_name,
        c.parent_cat_id,
        ct.level + 1,
        ct.path || '/' || CAST(c.cat_id AS VARCHAR(10))
    FROM categories c
    JOIN category_tree ct ON c.parent_cat_id = ct.cat_id
)
SELECT 
    ct.cat_name,
    ct.level,
    COUNT(p.product_id) AS product_count,
    STRING_AGG(p.product_name, ', ') AS products
FROM category_tree ct
LEFT JOIN products p ON ct.cat_id = p.category_id
GROUP BY ct.cat_id, ct.cat_name, ct.level, ct.path
ORDER BY ct.path;

-- -----------------------------------------------------
-- Example 14: Full Outer Join with COALESCE
-- -----------------------------------------------------
-- Compare two datasets completely

WITH jan_sales AS (
    SELECT product_id, SUM(sale_amount) AS amount
    FROM sales
    WHERE MONTH(sale_date) = 1
    GROUP BY product_id
),
feb_sales AS (
    SELECT product_id, SUM(sale_amount) AS amount
    FROM sales
    WHERE MONTH(sale_date) = 2
    GROUP BY product_id
)
SELECT 
    COALESCE(j.product_id, f.product_id) AS product_id,
    p.product_name,
    COALESCE(j.amount, 0) AS jan_sales,
    COALESCE(f.amount, 0) AS feb_sales,
    COALESCE(f.amount, 0) - COALESCE(j.amount, 0) AS difference,
    CASE 
        WHEN j.amount IS NULL THEN 'NEW IN FEB'
        WHEN f.amount IS NULL THEN 'ONLY IN JAN'
        WHEN f.amount > j.amount THEN 'INCREASED'
        WHEN f.amount < j.amount THEN 'DECREASED'
        ELSE 'UNCHANGED'
    END AS trend
FROM jan_sales j
FULL OUTER JOIN feb_sales f ON j.product_id = f.product_id
LEFT JOIN products p ON COALESCE(j.product_id, f.product_id) = p.product_id
ORDER BY difference DESC;

-- -----------------------------------------------------
-- Example 15: Join with CASE in ON Clause
-- -----------------------------------------------------
-- Conditional join logic

SELECT 
    o.order_id,
    o.order_date,
    o.order_status,
    c.customer_name,
    p.product_name,
    oi.quantity,
    oi.unit_price,
    CASE o.order_status
        WHEN 'DELIVERED' THEN 'COMPLETED'
        WHEN 'SHIPPED' THEN 'IN TRANSIT'
        ELSE 'PROCESSING'
    END AS status_category
FROM orders o
JOIN customers c ON o.customer_id = c.customer_id
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
    AND (
        CASE 
            WHEN o.order_status = 'DELIVERED' THEN p.stock_quantity >= 0
            ELSE p.stock_quantity > 10
        END
    )
ORDER BY o.order_date DESC;

-- -----------------------------------------------------
-- Example 16: Join Performance Optimization
-- -----------------------------------------------------
-- Use EXISTS instead of IN for better performance

-- Less efficient (IN with subquery)
SELECT c.customer_name, c.email
FROM customers c
WHERE c.customer_id IN (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE order_status = 'DELIVERED'
);

-- More efficient (EXISTS)
SELECT c.customer_name, c.email
FROM customers c
WHERE EXISTS (
    SELECT 1 
    FROM orders o 
    WHERE o.customer_id = c.customer_id 
      AND o.order_status = 'DELIVERED'
);

-- Most efficient (INNER JOIN with DISTINCT)
SELECT DISTINCT c.customer_name, c.email
FROM customers c
INNER JOIN orders o ON c.customer_id = o.customer_id
WHERE o.order_status = 'DELIVERED';

-- -----------------------------------------------------
-- Example 17: Join with GROUPING SETS
-- -----------------------------------------------------
-- Multi-level aggregation in one query

SELECT 
    cat.cat_name,
    p.product_name,
    o.order_status,
    COUNT(DISTINCT o.order_id) AS order_count,
    SUM(oi.quantity) AS total_quantity,
    SUM(oi.line_total) AS total_revenue
FROM categories cat
JOIN products p ON cat.cat_id = p.category_id
JOIN order_items oi ON p.product_id = oi.product_id
JOIN orders o ON oi.order_id = o.order_id
GROUP BY GROUPING SETS (
    (cat.cat_name, p.product_name, o.order_status),
    (cat.cat_name, p.product_name),
    (cat.cat_name),
    ()
)
ORDER BY cat.cat_name, p.product_name, o.order_status;

-- =====================================================
-- Join Optimization Tips:
-- =====================================================
-- 1. Create indexes on join columns
-- 2. Use appropriate join types (INNER vs OUTER)
-- 3. Filter early (WHERE before JOIN when possible)
-- 4. Consider EXISTS over IN for subqueries
-- 5. Use EXPLAIN to analyze join strategies
-- 6. Avoid functions on join columns
-- 7. Keep statistics up to date (RUNSTATS)
-- 8. Consider materialized query tables (MQTs)
-- 9. Use FETCH FIRST for limiting results
-- 10. Monitor buffer pool hit ratios
-- =====================================================