-- =====================================================
-- DB2 Recursive SQL Examples
-- =====================================================
-- Demonstrates: Recursive CTEs, hierarchical queries,
-- graph traversal, and advanced recursive patterns
-- =====================================================

-- -----------------------------------------------------
-- Example 1: Basic Employee Hierarchy
-- -----------------------------------------------------
-- Find all employees reporting to a specific manager

WITH RECURSIVE emp_hierarchy (emp_id, emp_name, manager_id, level, path) AS (
    -- Anchor member: Start with top-level manager
    SELECT 
        emp_id,
        emp_name,
        manager_id,
        1 AS level,
        CAST(emp_name AS VARCHAR(1000)) AS path
    FROM employees
    WHERE manager_id IS NULL
    
    UNION ALL
    
    -- Recursive member: Find all direct reports
    SELECT 
        e.emp_id,
        e.emp_name,
        e.manager_id,
        eh.level + 1,
        eh.path || ' > ' || e.emp_name
    FROM employees e
    INNER JOIN emp_hierarchy eh ON e.manager_id = eh.emp_id
    WHERE eh.level < 10  -- Prevent infinite recursion
)
SELECT 
    emp_id,
    REPEAT('  ', level - 1) || emp_name AS hierarchy_view,
    level,
    path
FROM emp_hierarchy
ORDER BY path;

-- -----------------------------------------------------
-- Example 2: Bill of Materials (BOM) Explosion
-- -----------------------------------------------------
-- Calculate total parts needed for a product assembly

WITH RECURSIVE bom_explosion (
    parent_part,
    component_part,
    quantity_needed,
    level,
    total_quantity
) AS (
    -- Anchor: Top-level product
    SELECT 
        parent_part_id,
        component_part_id,
        quantity,
        1 AS level,
        quantity AS total_quantity
    FROM bill_of_materials
    WHERE parent_part_id = 'PRODUCT-001'
    
    UNION ALL
    
    -- Recursive: Explode sub-components
    SELECT 
        bom.parent_part_id,
        bom.component_part_id,
        bom.quantity,
        be.level + 1,
        be.total_quantity * bom.quantity
    FROM bill_of_materials bom
    INNER JOIN bom_explosion be ON bom.parent_part_id = be.component_part
    WHERE be.level < 20
)
SELECT 
    component_part,
    SUM(total_quantity) AS total_needed,
    MAX(level) AS max_depth,
    COUNT(*) AS occurrences
FROM bom_explosion
GROUP BY component_part
ORDER BY total_needed DESC;

-- -----------------------------------------------------
-- Example 3: Graph Path Finding
-- -----------------------------------------------------
-- Find all possible paths between two nodes in a graph

WITH RECURSIVE path_finder (
    start_node,
    end_node,
    path,
    path_length,
    visited_nodes
) AS (
    -- Anchor: Start with source node
    SELECT 
        from_node,
        to_node,
        CAST(from_node || ' -> ' || to_node AS VARCHAR(4000)),
        1 AS path_length,
        CAST(from_node || ',' || to_node AS VARCHAR(4000))
    FROM graph_edges
    WHERE from_node = 'A'
    
    UNION ALL
    
    -- Recursive: Traverse to next nodes
    SELECT 
        pf.start_node,
        ge.to_node,
        pf.path || ' -> ' || ge.to_node,
        pf.path_length + 1,
        pf.visited_nodes || ',' || ge.to_node
    FROM graph_edges ge
    INNER JOIN path_finder pf ON ge.from_node = pf.end_node
    WHERE pf.path_length < 10
      AND LOCATE(',' || ge.to_node || ',', ',' || pf.visited_nodes || ',') = 0  -- Cycle detection
)
SELECT 
    start_node,
    end_node,
    path,
    path_length
FROM path_finder
WHERE end_node = 'Z'  -- Destination node
ORDER BY path_length, path;

-- -----------------------------------------------------
-- Example 4: Organizational Chart with Metrics
-- -----------------------------------------------------
-- Calculate team size and depth for each manager

WITH RECURSIVE org_metrics (
    emp_id,
    emp_name,
    manager_id,
    level,
    direct_reports,
    total_reports,
    max_depth
) AS (
    -- Anchor: Top management
    SELECT 
        e.emp_id,
        e.emp_name,
        e.manager_id,
        1 AS level,
        0 AS direct_reports,
        0 AS total_reports,
        1 AS max_depth
    FROM employees e
    WHERE e.manager_id IS NULL
    
    UNION ALL
    
    -- Recursive: Calculate metrics down the hierarchy
    SELECT 
        e.emp_id,
        e.emp_name,
        e.manager_id,
        om.level + 1,
        (SELECT COUNT(*) FROM employees WHERE manager_id = e.emp_id),
        0,  -- Will be calculated in outer query
        om.max_depth + 1
    FROM employees e
    INNER JOIN org_metrics om ON e.manager_id = om.emp_id
)
SELECT 
    emp_id,
    emp_name,
    level,
    direct_reports,
    (SELECT COUNT(*) 
     FROM org_metrics om2 
     WHERE om2.manager_id = om1.emp_id) AS subordinate_count,
    max_depth
FROM org_metrics om1
ORDER BY level, emp_name;

-- -----------------------------------------------------
-- Example 5: Number Series Generation
-- -----------------------------------------------------
-- Generate a sequence of numbers recursively

WITH RECURSIVE number_series (n) AS (
    SELECT 1 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT n + 1 FROM number_series WHERE n < 100
)
SELECT n AS number FROM number_series;

-- -----------------------------------------------------
-- Example 6: Date Series Generation
-- -----------------------------------------------------
-- Generate a series of dates for calendar tables

WITH RECURSIVE date_series (dt) AS (
    SELECT DATE('2024-01-01') FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT dt + 1 DAY FROM date_series WHERE dt < DATE('2024-12-31')
)
SELECT 
    dt AS calendar_date,
    DAYNAME(dt) AS day_name,
    DAYOFWEEK(dt) AS day_of_week,
    WEEK(dt) AS week_number,
    MONTH(dt) AS month_number,
    QUARTER(dt) AS quarter,
    CASE WHEN DAYOFWEEK(dt) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS day_type
FROM date_series;

-- -----------------------------------------------------
-- Example 7: Fibonacci Sequence
-- -----------------------------------------------------
-- Generate Fibonacci numbers recursively

WITH RECURSIVE fibonacci (n, fib_current, fib_next) AS (
    SELECT 1, 0, 1 FROM SYSIBM.SYSDUMMY1
    UNION ALL
    SELECT 
        n + 1,
        fib_next,
        fib_current + fib_next
    FROM fibonacci
    WHERE n < 20
)
SELECT 
    n AS position,
    fib_current AS fibonacci_number
FROM fibonacci;

-- -----------------------------------------------------
-- Example 8: Category Tree with Aggregation
-- -----------------------------------------------------
-- Calculate product counts up through category hierarchy

WITH RECURSIVE category_tree AS (
    -- Anchor: Leaf categories with products
    SELECT 
        cat_id,
        cat_name,
        parent_cat_id,
        1 AS level,
        CAST(cat_name AS VARCHAR(1000)) AS path,
        (SELECT COUNT(*) FROM products WHERE category_id = categories.cat_id) AS product_count
    FROM categories
    WHERE parent_cat_id IS NULL
    
    UNION ALL
    
    -- Recursive: Parent categories
    SELECT 
        c.cat_id,
        c.cat_name,
        c.parent_cat_id,
        ct.level + 1,
        ct.path || ' / ' || c.cat_name,
        (SELECT COUNT(*) FROM products WHERE category_id = c.cat_id)
    FROM categories c
    INNER JOIN category_tree ct ON c.parent_cat_id = ct.cat_id
)
SELECT 
    cat_id,
    REPEAT('  ', level - 1) || cat_name AS category_hierarchy,
    level,
    product_count AS direct_products,
    (SELECT SUM(product_count) 
     FROM category_tree ct2 
     WHERE ct2.path LIKE ct1.path || '%') AS total_products_in_tree
FROM category_tree ct1
ORDER BY path;

-- -----------------------------------------------------
-- Example 9: Shortest Path Algorithm
-- -----------------------------------------------------
-- Find the shortest path between nodes using weights

WITH RECURSIVE shortest_path (
    node,
    total_cost,
    path
) AS (
    -- Anchor: Start node
    SELECT 
        from_node,
        0 AS total_cost,
        CAST(from_node AS VARCHAR(1000)) AS path
    FROM graph_edges
    WHERE from_node = 'START'
    
    UNION ALL
    
    -- Recursive: Find minimum cost paths
    SELECT 
        ge.to_node,
        sp.total_cost + ge.weight,
        sp.path || ' -> ' || ge.to_node
    FROM graph_edges ge
    INNER JOIN shortest_path sp ON ge.from_node = sp.node
    WHERE sp.total_cost + ge.weight < 1000
      AND LOCATE(ge.to_node, sp.path) = 0
)
SELECT 
    node,
    MIN(total_cost) AS min_cost,
    path
FROM shortest_path
WHERE node = 'END'
GROUP BY node, path
ORDER BY min_cost
FETCH FIRST 1 ROW ONLY;

-- -----------------------------------------------------
-- Example 10: Recursive Delete Cascade Simulation
-- -----------------------------------------------------
-- Find all records that would be deleted in a cascade

WITH RECURSIVE cascade_delete AS (
    -- Anchor: Records to delete
    SELECT 
        order_id,
        customer_id,
        1 AS level,
        'orders' AS table_name
    FROM orders
    WHERE order_id = 12345
    
    UNION ALL
    
    -- Recursive: Find dependent records
    SELECT 
        oi.item_id,
        cd.customer_id,
        cd.level + 1,
        'order_items'
    FROM order_items oi
    INNER JOIN cascade_delete cd ON oi.order_id = cd.order_id
    WHERE cd.table_name = 'orders'
)
SELECT 
    table_name,
    COUNT(*) AS records_affected,
    level
FROM cascade_delete
GROUP BY table_name, level
ORDER BY level;

-- =====================================================
-- Notes and Best Practices:
-- =====================================================
-- 1. Always include a termination condition (WHERE clause)
-- 2. Use cycle detection for graph traversal
-- 3. Limit recursion depth to prevent runaway queries
-- 4. Consider performance implications for large datasets
-- 5. Create appropriate indexes on join columns
-- 6. Test with EXPLAIN to understand execution plan
-- =====================================================