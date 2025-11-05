-- =====================================================
-- DB2 Cleanup Script
-- =====================================================
-- Removes all sample tables, views, indexes, and data
-- =====================================================

-- WARNING: This script will permanently delete all sample
-- data and objects. Use with caution!

SET SCHEMA = SAMPLES;

-- -----------------------------------------------------
-- Drop Views First (due to dependencies)
-- -----------------------------------------------------

DROP VIEW IF EXISTS customer_summary;
DROP VIEW IF EXISTS product_sales;
DROP VIEW IF EXISTS daily_sales;
DROP VIEW IF EXISTS product_revenue;

-- -----------------------------------------------------
-- Drop Materialized Query Tables
-- -----------------------------------------------------

DROP TABLE IF EXISTS customer_order_summary;

-- -----------------------------------------------------
-- Drop Temporal Tables (System-Versioned)
-- -----------------------------------------------------

-- Disable versioning first
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    ALTER TABLE employee_history DROP VERSIONING;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    ALTER TABLE department_history DROP VERSIONING;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    ALTER TABLE product_pricing DROP VERSIONING;
END;

-- Drop temporal tables and their history tables
DROP TABLE IF EXISTS employee_history;
DROP TABLE IF EXISTS employee_history_HIST;
DROP TABLE IF EXISTS department_history;
DROP TABLE IF EXISTS department_history_HIST;
DROP TABLE IF EXISTS product_pricing;
DROP TABLE IF EXISTS product_pricing_HIST;

-- -----------------------------------------------------
-- Drop Partitioned Tables
-- -----------------------------------------------------

DROP TABLE IF EXISTS sales_partitioned;

-- -----------------------------------------------------
-- Drop XML/JSON Tables
-- -----------------------------------------------------

DROP TABLE IF EXISTS customer_profiles;
DROP TABLE IF EXISTS product_catalog;

-- -----------------------------------------------------
-- Drop Regular Tables (in dependency order)
-- -----------------------------------------------------

-- Drop child tables first
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS transactions;
DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS stock_prices;

-- Drop parent tables
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;

-- Drop utility tables
DROP TABLE IF EXISTS bill_of_materials;
DROP TABLE IF EXISTS graph_edges;

-- -----------------------------------------------------
-- Drop Indexes (if not dropped with tables)
-- -----------------------------------------------------

-- Most indexes are automatically dropped with tables
-- Manual cleanup for any remaining indexes

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_orders_customer_date;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_orders_status_date;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_order_items_product;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_sales_date_product_customer;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_sales_clustered;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_emp_manager;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_emp_dept;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_cat_parent;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_prod_category;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_prod_price;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_cust_status;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_cust_country;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_order_customer;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_order_date;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_order_status;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_item_order;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_item_product;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_bom_parent;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_bom_component;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_graph_from;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_graph_to;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_sales_date;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_sales_product;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_sales_customer;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_sales_region;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_stock_symbol_date;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_trans_emp;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_trans_date;
END;

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
    DROP INDEX idx_trans_type;
END;

-- -----------------------------------------------------
-- Drop Buffer Pools (if created)
-- -----------------------------------------------------

-- Uncomment if you created custom buffer pools
-- BEGIN
--     DECLARE CONTINUE HANDLER FOR SQLSTATE '42704' BEGIN END;
--     DROP BUFFERPOOL bp_hot;
-- END;

-- -----------------------------------------------------
-- Verify Cleanup
-- -----------------------------------------------------

-- Check remaining tables in SAMPLES schema
SELECT 
    'Tables remaining: ' || COUNT(*) AS status
FROM SYSCAT.TABLES
WHERE TABSCHEMA = 'SAMPLES'
  AND TYPE = 'T';

-- Check remaining views
SELECT 
    'Views remaining: ' || COUNT(*) AS status
FROM SYSCAT.VIEWS
WHERE VIEWSCHEMA = 'SAMPLES';

-- Check remaining indexes
SELECT 
    'Indexes remaining: ' || COUNT(*) AS status
FROM SYSCAT.INDEXES
WHERE TABSCHEMA = 'SAMPLES';

-- List any remaining objects for manual cleanup
SELECT 
    'TABLE' AS object_type,
    TABNAME AS object_name
FROM SYSCAT.TABLES
WHERE TABSCHEMA = 'SAMPLES'
  AND TYPE = 'T'

UNION ALL

SELECT 
    'VIEW' AS object_type,
    VIEWNAME AS object_name
FROM SYSCAT.VIEWS
WHERE VIEWSCHEMA = 'SAMPLES'

UNION ALL

SELECT 
    'INDEX' AS object_type,
    INDNAME AS object_name
FROM SYSCAT.INDEXES
WHERE TABSCHEMA = 'SAMPLES';

-- -----------------------------------------------------
-- Clean Up Explain Tables (Optional)
-- -----------------------------------------------------

-- Remove old explain data
DELETE FROM EXPLAIN_STATEMENT
WHERE EXPLAIN_TIME < CURRENT TIMESTAMP - 7 DAYS;

DELETE FROM EXPLAIN_INSTANCE
WHERE EXPLAIN_TIME < CURRENT TIMESTAMP - 7 DAYS;

COMMIT;

-- -----------------------------------------------------
-- Reset Configuration (Optional)
-- -----------------------------------------------------

-- Reset explain mode if it was left on
SET CURRENT EXPLAIN MODE = NO;

-- Reset query optimization level to default
SET CURRENT QUERY OPTIMIZATION = 5;

-- Reset isolation level to default
-- SET CURRENT ISOLATION = CS;

-- -----------------------------------------------------
-- Reclaim Storage (Optional)
-- -----------------------------------------------------

-- Note: These commands may require elevated privileges

-- Reclaim unused space in tablespace
-- CALL SYSPROC.ADMIN_CMD('ALTER TABLESPACE USERSPACE1 REDUCE MAX');

-- Update catalog statistics
-- CALL SYSPROC.ADMIN_CMD('RUNSTATS ON TABLE SYSCAT.TABLES');

-- Reorganize system catalog if needed
-- CALL SYSPROC.ADMIN_CMD('REORGCHK UPDATE STATISTICS ON TABLE SYSCAT.TABLES');

COMMIT;

-- =====================================================
-- Cleanup Complete
-- =====================================================
-- Summary of actions:
-- - All sample tables dropped
-- - All sample views dropped
-- - All custom indexes dropped
-- - Temporal table versioning disabled
-- - Explain data older than 7 days removed
-- - Configuration reset to defaults
--
-- To verify cleanup:
-- SELECT * FROM SYSCAT.TABLES WHERE TABSCHEMA = 'SAMPLES';
-- 
-- To reinstall sample data:
-- 1. Run setup/01_create_sample_tables.sql
-- 2. Run setup/02_load_sample_data.sql
-- =====================================================

-- Display cleanup summary
VALUES (
    'Cleanup completed at: ' || CHAR(CURRENT TIMESTAMP)
);

-- Final verification query
SELECT 
    CASE 
        WHEN COUNT(*) = 0 THEN '✓ All sample objects successfully removed'
        ELSE '⚠ Warning: ' || CAST(COUNT(*) AS VARCHAR(10)) || ' objects still exist'
    END AS cleanup_status
FROM (
    SELECT TABNAME FROM SYSCAT.TABLES WHERE TABSCHEMA = 'SAMPLES' AND TYPE = 'T'
    UNION ALL
    SELECT VIEWNAME FROM SYSCAT.VIEWS WHERE VIEWSCHEMA = 'SAMPLES'
    UNION ALL
    SELECT INDNAME FROM SYSCAT.INDEXES WHERE TABSCHEMA = 'SAMPLES'
) AS remaining_objects;

-- =====================================================
-- Additional Manual Cleanup (if needed)
-- =====================================================

/*
If objects remain after running this script, you can
manually drop them using:

DROP TABLE SAMPLES.tablename;
DROP VIEW SAMPLES.viewname;
DROP INDEX SAMPLES.indexname;

To force drop tables with dependencies:
DROP TABLE SAMPLES.tablename CASCADE;

To drop the entire schema:
DROP SCHEMA SAMPLES RESTRICT;
-- or
DROP SCHEMA SAMPLES CASCADE;
*/

-- =====================================================
-- Backup Reminder
-- =====================================================

/*
Before running this cleanup script in a production
environment, always ensure you have:

1. A recent database backup
2. Confirmation from all stakeholders
3. Documented list of objects to be removed
4. Tested the cleanup on a dev/test environment
5. Scheduled appropriate downtime if needed

To backup before cleanup:
db2 backup database <dbname> to /backup/path

To restore if needed:
db2 restore database <dbname> from /backup/path
*/