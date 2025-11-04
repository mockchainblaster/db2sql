-- =====================================================
-- DB2 OLAP (Window) Functions Examples
-- =====================================================
-- Demonstrates: Ranking, aggregations, lead/lag,
-- moving averages, and advanced analytical functions
-- =====================================================

-- -----------------------------------------------------
-- Example 1: Basic Ranking Functions
-- -----------------------------------------------------
-- Compare ROW_NUMBER, RANK, and DENSE_RANK

SELECT 
    employee_name,
    department,
    salary,
    ROW_NUMBER() OVER (ORDER BY salary DESC) AS row_num,
    RANK() OVER (ORDER BY salary DESC) AS rank,
    DENSE_RANK() OVER (ORDER BY salary DESC) AS dense_rank,
    PERCENT_RANK() OVER (ORDER BY salary DESC) AS percent_rank
FROM employees
ORDER BY salary DESC;

-- -----------------------------------------------------
-- Example 2: Partitioned Ranking
-- -----------------------------------------------------
-- Rank employees within each department

SELECT 
    department,
    employee_name,
    salary,
    RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_rank,
    DENSE_RANK() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_dense_rank,
    ROW_NUMBER() OVER (PARTITION BY department ORDER BY salary DESC) AS dept_row_num
FROM employees
ORDER BY department, salary DESC;

-- -----------------------------------------------------
-- Example 3: Running Totals and Cumulative Sum
-- -----------------------------------------------------
-- Calculate cumulative sales by date

SELECT 
    sale_date,
    product_name,
    sale_amount,
    SUM(sale_amount) OVER (
        ORDER BY sale_date 
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS running_total,
    SUM(sale_amount) OVER (
        PARTITION BY product_name 
        ORDER BY sale_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS product_running_total
FROM sales
ORDER BY sale_date;

-- -----------------------------------------------------
-- Example 4: Moving Averages
-- -----------------------------------------------------
-- Calculate 7-day moving average for stock prices

SELECT 
    trade_date,
    stock_symbol,
    close_price,
    AVG(close_price) OVER (
        PARTITION BY stock_symbol
        ORDER BY trade_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS moving_avg_7day,
    AVG(close_price) OVER (
        PARTITION BY stock_symbol
        ORDER BY trade_date
        ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
    ) AS moving_avg_30day,
    close_price - AVG(close_price) OVER (
        PARTITION BY stock_symbol
        ORDER BY trade_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS deviation_from_avg
FROM stock_prices
ORDER BY stock_symbol, trade_date;

-- -----------------------------------------------------
-- Example 5: LEAD and LAG Functions
-- -----------------------------------------------------
-- Compare current value with previous and next values

SELECT 
    sale_date,
    product_id,
    sales_amount,
    LAG(sales_amount, 1) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS previous_day_sales,
    LEAD(sales_amount, 1) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS next_day_sales,
    sales_amount - LAG(sales_amount, 1, 0) OVER (
        PARTITION BY product_id 
        ORDER BY sale_date
    ) AS day_over_day_change,
    CASE 
        WHEN LAG(sales_amount) OVER (PARTITION BY product_id ORDER BY sale_date) > 0
        THEN ((sales_amount - LAG(sales_amount) OVER (PARTITION BY product_id ORDER BY sale_date)) 
              / LAG(sales_amount) OVER (PARTITION BY product_id ORDER BY sale_date)) * 100
        ELSE NULL
    END AS pct_change
FROM daily_sales
ORDER BY product_id, sale_date;

-- -----------------------------------------------------
-- Example 6: FIRST_VALUE and LAST_VALUE
-- -----------------------------------------------------
-- Get first and last values in a window

SELECT 
    employee_name,
    department,
    hire_date,
    salary,
    FIRST_VALUE(employee_name) OVER (
        PARTITION BY department 
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS first_hired_in_dept,
    LAST_VALUE(employee_name) OVER (
        PARTITION BY department 
        ORDER BY hire_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS last_hired_in_dept,
    FIRST_VALUE(salary) OVER (
        PARTITION BY department 
        ORDER BY salary DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
    ) AS highest_salary_in_dept
FROM employees
ORDER BY department, hire_date;

-- -----------------------------------------------------
-- Example 7: NTILE - Divide into Quartiles
-- -----------------------------------------------------
-- Segment customers into quartiles by purchase amount

SELECT 
    customer_id,
    customer_name,
    total_purchases,
    NTILE(4) OVER (ORDER BY total_purchases DESC) AS quartile,
    NTILE(10) OVER (ORDER BY total_purchases DESC) AS decile,
    CASE NTILE(4) OVER (ORDER BY total_purchases DESC)
        WHEN 1 THEN 'Top 25%'
        WHEN 2 THEN 'Upper Middle'
        WHEN 3 THEN 'Lower Middle'
        WHEN 4 THEN 'Bottom 25%'
    END AS customer_segment
FROM customer_summary
ORDER BY total_purchases DESC;

-- -----------------------------------------------------
-- Example 8: Year-over-Year Comparison
-- -----------------------------------------------------
-- Compare sales with same period last year

SELECT 
    YEAR(sale_date) AS sale_year,
    MONTH(sale_date) AS sale_month,
    SUM(sale_amount) AS monthly_sales,
    LAG(SUM(sale_amount), 12) OVER (ORDER BY YEAR(sale_date), MONTH(sale_date)) AS same_month_last_year,
    SUM(sale_amount) - LAG(SUM(sale_amount), 12) OVER (ORDER BY YEAR(sale_date), MONTH(sale_date)) AS yoy_change,
    CASE 
        WHEN LAG(SUM(sale_amount), 12) OVER (ORDER BY YEAR(sale_date), MONTH(sale_date)) > 0
        THEN ROUND(
            ((SUM(sale_amount) - LAG(SUM(sale_amount), 12) OVER (ORDER BY YEAR(sale_date), MONTH(sale_date))) 
            / LAG(SUM(sale_amount), 12) OVER (ORDER BY YEAR(sale_date), MONTH(sale_date))) * 100, 2)
        ELSE NULL
    END AS yoy_pct_change
FROM sales
GROUP BY YEAR(sale_date), MONTH(sale_date)
ORDER BY sale_year, sale_month;

-- -----------------------------------------------------
-- Example 9: Ratio to Report
-- -----------------------------------------------------
-- Calculate percentage of total for each row

SELECT 
    department,
    employee_name,
    salary,
    SUM(salary) OVER (PARTITION BY department) AS dept_total_salary,
    ROUND(
        (salary * 100.0) / SUM(salary) OVER (PARTITION BY department), 
        2
    ) AS pct_of_dept_salary,
    ROUND(
        (salary * 100.0) / SUM(salary) OVER (), 
        2
    ) AS pct_of_company_salary
FROM employees
ORDER BY department, salary DESC;

-- -----------------------------------------------------
-- Example 10: Top N per Group
-- -----------------------------------------------------
-- Get top 3 products per category by sales

WITH ranked_products AS (
    SELECT 
        category_name,
        product_name,
        total_sales,
        ROW_NUMBER() OVER (
            PARTITION BY category_name 
            ORDER BY total_sales DESC
        ) AS rank_in_category
    FROM product_sales
)
SELECT 
    category_name,
    product_name,
    total_sales,
    rank_in_category
FROM ranked_products
WHERE rank_in_category <= 3
ORDER BY category_name, rank_in_category;

-- -----------------------------------------------------
-- Example 11: Running Percentage
-- -----------------------------------------------------
-- Calculate cumulative percentage of total

SELECT 
    product_name,
    revenue,
    SUM(revenue) OVER (ORDER BY revenue DESC) AS cumulative_revenue,
    SUM(revenue) OVER () AS total_revenue,
    ROUND(
        (SUM(revenue) OVER (ORDER BY revenue DESC) * 100.0) / 
        SUM(revenue) OVER (), 
        2
    ) AS cumulative_pct
FROM product_revenue
ORDER BY revenue DESC;

-- -----------------------------------------------------
-- Example 12: Complex Window Frames
-- -----------------------------------------------------
-- Different window frame specifications

SELECT 
    order_date,
    order_id,
    order_amount,
    -- Current row only
    SUM(order_amount) OVER (
        ORDER BY order_date
        ROWS CURRENT ROW
    ) AS current_row_only,
    -- Last 3 rows including current
    SUM(order_amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS last_3_rows,
    -- Symmetric window (2 before and 2 after)
    AVG(order_amount) OVER (
        ORDER BY order_date
        ROWS BETWEEN 2 PRECEDING AND 2 FOLLOWING
    ) AS symmetric_avg,
    -- Range-based window (all rows within 7 days)
    COUNT(*) OVER (
        ORDER BY order_date
        RANGE BETWEEN INTERVAL 7 DAYS PRECEDING AND CURRENT ROW
    ) AS orders_last_7days
FROM orders
ORDER BY order_date;

-- -----------------------------------------------------
-- Example 13: Multiple Aggregations in One Query
-- -----------------------------------------------------
-- Calculate various statistics over different windows

SELECT 
    sale_date,
    product_id,
    quantity_sold,
    -- Daily stats
    SUM(quantity_sold) OVER (
        PARTITION BY sale_date
    ) AS daily_total,
    -- Weekly rolling stats
    SUM(quantity_sold) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS weekly_rolling_sum,
    AVG(quantity_sold) OVER (
        ORDER BY sale_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS weekly_rolling_avg,
    -- Monthly stats
    SUM(quantity_sold) OVER (
        PARTITION BY YEAR(sale_date), MONTH(sale_date)
    ) AS monthly_total,
    -- Product-specific running total
    SUM(quantity_sold) OVER (
        PARTITION BY product_id
        ORDER BY sale_date
    ) AS product_running_total
FROM sales
ORDER BY sale_date, product_id;

-- -----------------------------------------------------
-- Example 14: Median Calculation
-- -----------------------------------------------------
-- Calculate median using PERCENTILE_CONT

SELECT 
    department,
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY salary) AS median_salary,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY salary) AS q1_salary,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY salary) AS q3_salary,
    MIN(salary) AS min_salary,
    MAX(salary) AS max_salary,
    AVG(salary) AS avg_salary
FROM employees
GROUP BY department
ORDER BY median_salary DESC;

-- -----------------------------------------------------
-- Example 15: Gap and Island Detection
-- -----------------------------------------------------
-- Find continuous sequences in data

WITH numbered_dates AS (
    SELECT 
        sale_date,
        product_id,
        ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY sale_date) AS rn,
        sale_date - (ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY sale_date)) DAYS AS grp
    FROM sales
)
SELECT 
    product_id,
    MIN(sale_date) AS sequence_start,
    MAX(sale_date) AS sequence_end,
    COUNT(*) AS consecutive_days
FROM numbered_dates
GROUP BY product_id, grp
HAVING COUNT(*) >= 7  -- Sequences of 7+ consecutive days
ORDER BY product_id, sequence_start;

-- -----------------------------------------------------
-- Example 16: Conditional Aggregation with Windows
-- -----------------------------------------------------
-- Calculate conditional sums and counts

SELECT 
    employee_id,
    transaction_date,
    transaction_type,
    amount,
    SUM(CASE WHEN transaction_type = 'SALE' THEN amount ELSE 0 END) OVER (
        PARTITION BY employee_id
        ORDER BY transaction_date
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_sales,
    SUM(CASE WHEN transaction_type = 'REFUND' THEN amount ELSE 0 END) OVER (
        PARTITION BY employee_id
        ORDER BY transaction_date
        ROWS UNBOUNDED PRECEDING
    ) AS cumulative_refunds,
    COUNT(CASE WHEN transaction_type = 'SALE' THEN 1 END) OVER (
        PARTITION BY employee_id
        ORDER BY transaction_date
        ROWS UNBOUNDED PRECEDING
    ) AS total_sales_count
FROM transactions
ORDER BY employee_id, transaction_date;

-- =====================================================
-- Performance Tips:
-- =====================================================
-- 1. Create indexes on PARTITION BY and ORDER BY columns
-- 2. Use appropriate window frames (ROWS vs RANGE)
-- 3. Avoid using UNBOUNDED FOLLOWING when not needed
-- 4. Consider materializing complex window calculations
-- 5. Use FETCH FIRST for pagination with ROW_NUMBER
-- 6. Monitor SHEAPTHRES_SHR for sort memory
-- =====================================================