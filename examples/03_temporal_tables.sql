-- =====================================================
-- DB2 Temporal Tables Examples
-- =====================================================
-- Demonstrates: System-versioned tables, time-travel
-- queries, point-in-time analysis, and audit trails
-- =====================================================

-- DB2 requires at least version 10.1 for temporal tables
-- Temporal tables automatically track historical changes

-- -----------------------------------------------------
-- Example 1: Create System-Versioned Table
-- -----------------------------------------------------
-- Create a table that tracks all historical changes

CREATE TABLE employee_history (
    emp_id INTEGER NOT NULL,
    emp_name VARCHAR(100) NOT NULL,
    salary DECIMAL(10,2),
    department VARCHAR(50),
    -- Temporal columns
    sys_start TIMESTAMP(12) NOT NULL GENERATED ALWAYS AS ROW BEGIN,
    sys_end TIMESTAMP(12) NOT NULL GENERATED ALWAYS AS ROW END,
    trans_id TIMESTAMP(12) GENERATED ALWAYS AS TRANSACTION START ID,
    PERIOD SYSTEM_TIME (sys_start, sys_end)
)
WITH SYSTEM VERSIONING;

-- DB2 automatically creates a history table
-- Named: employee_history_HIST by default

-- -----------------------------------------------------
-- Example 2: Insert and Update Data
-- -----------------------------------------------------
-- Insert initial records

INSERT INTO employee_history (emp_id, emp_name, salary, department) VALUES
(1001, 'John Smith', 75000.00, 'Sales'),
(1002, 'Jane Doe', 82000.00, 'Engineering'),
(1003, 'Bob Wilson', 68000.00, 'Marketing');

COMMIT;

-- Wait a moment, then update some records
CALL SYSPROC.ADMIN_CMD('RUNSTATS ON TABLE employee_history WITH DISTRIBUTION');

UPDATE employee_history 
SET salary = 80000.00 
WHERE emp_id = 1001;

UPDATE employee_history 
SET department = 'Senior Engineering', salary = 95000.00 
WHERE emp_id = 1002;

COMMIT;

-- Another update
UPDATE employee_history 
SET salary = 72000.00 
WHERE emp_id = 1003;

DELETE FROM employee_history WHERE emp_id = 1001;

COMMIT;

-- -----------------------------------------------------
-- Example 3: Query Current State
-- -----------------------------------------------------
-- Query shows only current/active records

SELECT 
    emp_id,
    emp_name,
    salary,
    department,
    sys_start,
    sys_end
FROM employee_history
ORDER BY emp_id;

-- -----------------------------------------------------
-- Example 4: Query Historical Data (Time Travel)
-- -----------------------------------------------------
-- See the state of data as it was at a specific point in time

SELECT 
    emp_id,
    emp_name,
    salary,
    department,
    sys_start,
    sys_end
FROM employee_history
    FOR SYSTEM_TIME AS OF TIMESTAMP('2024-01-01-12.00.00.000000')
ORDER BY emp_id;

-- -----------------------------------------------------
-- Example 5: Query Data During a Time Period
-- -----------------------------------------------------
-- Get all versions of records that existed during a time range

SELECT 
    emp_id,
    emp_name,
    salary,
    department,
    sys_start,
    sys_end
FROM employee_history
    FOR SYSTEM_TIME FROM TIMESTAMP('2024-01-01-00.00.00') 
                     TO TIMESTAMP('2024-12-31-23.59.59')
ORDER BY emp_id, sys_start;

-- -----------------------------------------------------
-- Example 6: Query All Historical Changes
-- -----------------------------------------------------
-- Get complete history including all changes

SELECT 
    emp_id,
    emp_name,
    salary,
    department,
    sys_start,
    sys_end,
    CASE 
        WHEN sys_end = TIMESTAMP('9999-12-30-00.00.00.000000') THEN 'CURRENT'
        ELSE 'HISTORICAL'
    END AS record_status
FROM employee_history
    FOR SYSTEM_TIME FROM TIMESTAMP('1900-01-01-00.00.00') 
                     TO TIMESTAMP('9999-12-31-23.59.59')
ORDER BY emp_id, sys_start;

-- -----------------------------------------------------
-- Example 7: Audit Trail Report
-- -----------------------------------------------------
-- Track salary changes for a specific employee

SELECT 
    emp_id,
    emp_name,
    salary AS old_salary,
    LEAD(salary) OVER (PARTITION BY emp_id ORDER BY sys_start) AS new_salary,
    salary - LEAD(salary) OVER (PARTITION BY emp_id ORDER BY sys_start) AS salary_change,
    sys_start AS change_date,
    sys_end AS valid_until
FROM employee_history
    FOR SYSTEM_TIME FROM TIMESTAMP('1900-01-01-00.00.00') 
                     TO TIMESTAMP('9999-12-31-23.59.59')
WHERE emp_id = 1002
ORDER BY sys_start;

-- -----------------------------------------------------
-- Example 8: Compare Current vs Historical State
-- -----------------------------------------------------
-- Compare current state with state 90 days ago

WITH current_state AS (
    SELECT emp_id, emp_name, salary, department
    FROM employee_history
),
historical_state AS (
    SELECT emp_id, emp_name, salary, department
    FROM employee_history
        FOR SYSTEM_TIME AS OF CURRENT TIMESTAMP - 90 DAYS
)
SELECT 
    COALESCE(c.emp_id, h.emp_id) AS emp_id,
    COALESCE(c.emp_name, h.emp_name) AS emp_name,
    h.salary AS salary_90_days_ago,
    c.salary AS current_salary,
    c.salary - h.salary AS salary_change,
    h.department AS old_department,
    c.department AS current_department,
    CASE 
        WHEN c.emp_id IS NULL THEN 'TERMINATED'
        WHEN h.emp_id IS NULL THEN 'NEW HIRE'
        WHEN c.salary <> h.salary OR c.department <> h.department THEN 'CHANGED'
        ELSE 'NO CHANGE'
    END AS status
FROM current_state c
FULL OUTER JOIN historical_state h ON c.emp_id = h.emp_id
ORDER BY emp_id;

-- -----------------------------------------------------
-- Example 9: Business-Time Temporal Table
-- -----------------------------------------------------
-- Track when information is valid in business terms
-- (different from system time)

CREATE TABLE product_pricing (
    product_id INTEGER NOT NULL,
    product_name VARCHAR(100),
    price DECIMAL(10,2),
    -- Business time period
    valid_from DATE NOT NULL,
    valid_to DATE NOT NULL,
    -- System time period
    sys_start TIMESTAMP(12) GENERATED ALWAYS AS ROW BEGIN,
    sys_end TIMESTAMP(12) GENERATED ALWAYS AS ROW END,
    PERIOD BUSINESS_TIME (valid_from, valid_to),
    PERIOD SYSTEM_TIME (sys_start, sys_end),
    PRIMARY KEY (product_id, BUSINESS_TIME WITHOUT OVERLAPS)
)
WITH SYSTEM VERSIONING;

-- Insert pricing with different business validity periods
INSERT INTO product_pricing (product_id, product_name, price, valid_from, valid_to) VALUES
(2001, 'Widget A', 99.99, '2024-01-01', '2024-06-30'),
(2001, 'Widget A', 109.99, '2024-07-01', '2024-12-31'),
(2002, 'Widget B', 149.99, '2024-01-01', '2024-03-31'),
(2002, 'Widget B', 139.99, '2024-04-01', '2024-12-31');

COMMIT;

-- -----------------------------------------------------
-- Example 10: Query Business-Time Data
-- -----------------------------------------------------
-- Get price valid on a specific business date

SELECT 
    product_id,
    product_name,
    price,
    valid_from,
    valid_to
FROM product_pricing
    FOR BUSINESS_TIME AS OF DATE('2024-08-15')
ORDER BY product_id;

-- -----------------------------------------------------
-- Example 11: Bi-Temporal Query
-- -----------------------------------------------------
-- Query both system time and business time
-- "What did we think the price would be on 2024-08-15, 
--  as of system time 2024-06-01?"

SELECT 
    product_id,
    product_name,
    price,
    valid_from,
    valid_to,
    sys_start,
    sys_end
FROM product_pricing
    FOR BUSINESS_TIME AS OF DATE('2024-08-15')
    FOR SYSTEM_TIME AS OF TIMESTAMP('2024-06-01-12.00.00')
ORDER BY product_id;

-- -----------------------------------------------------
-- Example 12: Track Record Lifecycle
-- -----------------------------------------------------
-- Identify when records were created, modified, deleted

WITH record_lifecycle AS (
    SELECT 
        emp_id,
        emp_name,
        MIN(sys_start) AS first_seen,
        MAX(CASE WHEN sys_end < TIMESTAMP('9999-01-01') THEN sys_end END) AS last_seen,
        COUNT(*) AS total_versions,
        MAX(CASE WHEN sys_end = TIMESTAMP('9999-12-30-00.00.00.000000') THEN 1 ELSE 0 END) AS is_active
    FROM employee_history
        FOR SYSTEM_TIME FROM TIMESTAMP('1900-01-01') TO TIMESTAMP('9999-12-31')
    GROUP BY emp_id, emp_name
)
SELECT 
    emp_id,
    emp_name,
    first_seen AS created_date,
    last_seen AS deleted_date,
    total_versions - 1 AS number_of_changes,
    CASE is_active
        WHEN 1 THEN 'ACTIVE'
        ELSE 'DELETED'
    END AS current_status,
    CASE 
        WHEN last_seen IS NOT NULL THEN 
            DAYS(last_seen) - DAYS(first_seen)
        ELSE 
            DAYS(CURRENT TIMESTAMP) - DAYS(first_seen)
    END AS days_active
FROM record_lifecycle
ORDER BY emp_id;

-- -----------------------------------------------------
-- Example 13: Version Comparison
-- -----------------------------------------------------
-- Compare consecutive versions to see what changed

WITH versioned_data AS (
    SELECT 
        emp_id,
        emp_name,
        salary,
        department,
        sys_start,
        LAG(salary) OVER (PARTITION BY emp_id ORDER BY sys_start) AS prev_salary,
        LAG(department) OVER (PARTITION BY emp_id ORDER BY sys_start) AS prev_department,
        ROW_NUMBER() OVER (PARTITION BY emp_id ORDER BY sys_start) AS version_num
    FROM employee_history
        FOR SYSTEM_TIME FROM TIMESTAMP('1900-01-01') TO TIMESTAMP('9999-12-31')
)
SELECT 
    emp_id,
    emp_name,
    version_num,
    sys_start AS change_date,
    CASE 
        WHEN prev_salary IS NULL THEN 'INITIAL'
        WHEN salary <> prev_salary AND department <> prev_department THEN 'SALARY & DEPT'
        WHEN salary <> prev_salary THEN 'SALARY'
        WHEN department <> prev_department THEN 'DEPARTMENT'
        ELSE 'OTHER'
    END AS change_type,
    prev_salary,
    salary,
    salary - prev_salary AS salary_diff,
    prev_department,
    department
FROM versioned_data
WHERE version_num > 1
ORDER BY emp_id, sys_start;

-- -----------------------------------------------------
-- Example 14: Temporal Join
-- -----------------------------------------------------
-- Join temporal tables considering their time periods

-- Create another temporal table
CREATE TABLE department_history (
    dept_id INTEGER NOT NULL PRIMARY KEY,
    dept_name VARCHAR(100),
    manager_name VARCHAR(100),
    budget DECIMAL(15,2),
    sys_start TIMESTAMP(12) GENERATED ALWAYS AS ROW BEGIN,
    sys_end TIMESTAMP(12) GENERATED ALWAYS AS ROW END,
    PERIOD SYSTEM_TIME (sys_start, sys_end)
)
WITH SYSTEM VERSIONING;

-- Join employees with departments at specific point in time
SELECT 
    e.emp_id,
    e.emp_name,
    e.salary,
    d.dept_name,
    d.manager_name,
    d.budget
FROM employee_history 
    FOR SYSTEM_TIME AS OF TIMESTAMP('2024-06-01-12.00.00') e
LEFT JOIN department_history 
    FOR SYSTEM_TIME AS OF TIMESTAMP('2024-06-01-12.00.00') d
    ON e.department = d.dept_name
ORDER BY e.emp_id;

-- -----------------------------------------------------
-- Example 15: Calculate Average Tenure
-- -----------------------------------------------------
-- Calculate average time records spent in each state

WITH state_durations AS (
    SELECT 
        emp_id,
        emp_name,
        department,
        sys_start,
        COALESCE(
            NULLIF(sys_end, TIMESTAMP('9999-12-30-00.00.00.000000')),
            CURRENT TIMESTAMP
        ) AS sys_end_adjusted,
        DAYS(
            COALESCE(
                NULLIF(sys_end, TIMESTAMP('9999-12-30-00.00.00.000000')),
                CURRENT TIMESTAMP
            )
        ) - DAYS(sys_start) AS days_in_state
    FROM employee_history
        FOR SYSTEM_TIME FROM TIMESTAMP('1900-01-01') TO TIMESTAMP('9999-12-31')
)
SELECT 
    department,
    COUNT(DISTINCT emp_id) AS employee_count,
    AVG(days_in_state) AS avg_days_in_dept,
    MIN(days_in_state) AS min_days_in_dept,
    MAX(days_in_state) AS max_days_in_dept
FROM state_durations
WHERE department IS NOT NULL
GROUP BY department
ORDER BY avg_days_in_dept DESC;

-- -----------------------------------------------------
-- Example 16: Disable and Enable Versioning
-- -----------------------------------------------------
-- Temporarily disable versioning for bulk operations

-- Disable versioning
ALTER TABLE employee_history DROP VERSIONING;

-- Perform bulk operations without history tracking
UPDATE employee_history SET salary = salary * 1.03;

-- Re-enable versioning
ALTER TABLE employee_history ADD VERSIONING USE HISTORY TABLE employee_history_HIST;

-- -----------------------------------------------------
-- Example 17: Clean Up Old History
-- -----------------------------------------------------
-- Delete historical records older than retention period
-- (Be careful with this in production!)

-- Delete history older than 7 years
DELETE FROM employee_history_HIST
WHERE sys_end < CURRENT TIMESTAMP - 7 YEARS;

COMMIT;

-- =====================================================
-- Best Practices for Temporal Tables:
-- =====================================================
-- 1. Plan retention policies before implementation
-- 2. Consider storage impact of history tables
-- 3. Index temporal columns (sys_start, sys_end)
-- 4. Use appropriate timestamp precision
-- 5. Document business rules for business-time periods
-- 6. Regular archival of old historical data
-- 7. Test point-in-time queries for performance
-- 8. Consider partitioning for large history tables
-- 9. Monitor history table growth
-- 10. Use compression for history tables
-- =====================================================

-- Drop temporal tables for cleanup
-- DROP TABLE product_pricing;
-- DROP TABLE department_history;
-- DROP TABLE employee_history;