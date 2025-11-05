-- =====================================================
-- DB2 XML and JSON Processing Examples
-- =====================================================
-- Demonstrates: XML storage, XQuery, JSON functions,
-- and semi-structured data handling
-- =====================================================

-- -----------------------------------------------------
-- Setup: Create Tables with XML and JSON
-- -----------------------------------------------------

CREATE TABLE customer_profiles (
    customer_id INTEGER NOT NULL PRIMARY KEY,
    customer_name VARCHAR(100),
    profile_xml XML,
    preferences_json VARCHAR(4000)
);

CREATE TABLE product_catalog (
    product_id INTEGER NOT NULL PRIMARY KEY,
    product_name VARCHAR(200),
    specifications_xml XML,
    metadata_json VARCHAR(4000)
);

-- -----------------------------------------------------
-- Example 1: Insert XML Data
-- -----------------------------------------------------

INSERT INTO customer_profiles (customer_id, customer_name, profile_xml) VALUES
(1, 'John Smith', XMLPARSE(DOCUMENT '
<profile>
    <personal>
        <age>35</age>
        <email>john.smith@email.com</email>
        <phone>555-0101</phone>
    </personal>
    <address>
        <street>123 Main St</street>
        <city>New York</city>
        <state>NY</state>
        <zip>10001</zip>
        <country>USA</country>
    </address>
    <preferences>
        <newsletter>true</newsletter>
        <sms_alerts>false</sms_alerts>
    </preferences>
</profile>')),
(2, 'Jane Doe', XMLPARSE(DOCUMENT '
<profile>
    <personal>
        <age>28</age>
        <email>jane.doe@email.com</email>
        <phone>555-0102</phone>
    </personal>
    <address>
        <street>456 Oak Ave</street>
        <city>San Francisco</city>
        <state>CA</state>
        <zip>94102</zip>
        <country>USA</country>
    </address>
    <preferences>
        <newsletter>true</newsletter>
        <sms_alerts>true</sms_alerts>
    </preferences>
</profile>'));

-- -----------------------------------------------------
-- Example 2: Query XML Data with XQuery
-- -----------------------------------------------------

-- Extract specific XML elements
SELECT 
    customer_id,
    customer_name,
    XMLCAST(XMLQUERY('$p/profile/personal/email' 
        PASSING profile_xml AS "p") AS VARCHAR(100)) AS email,
    XMLCAST(XMLQUERY('$p/profile/address/city' 
        PASSING profile_xml AS "p") AS VARCHAR(50)) AS city,
    XMLCAST(XMLQUERY('$p/profile/personal/age' 
        PASSING profile_xml AS "p") AS INTEGER) AS age
FROM customer_profiles;

-- -----------------------------------------------------
-- Example 3: XQuery with Predicates
-- -----------------------------------------------------

-- Find customers in specific city
SELECT 
    customer_id,
    customer_name,
    XMLCAST(XMLQUERY('$p/profile/address/city' 
        PASSING profile_xml AS "p") AS VARCHAR(50)) AS city
FROM customer_profiles
WHERE XMLEXISTS('$p/profile/address[city="New York"]' 
    PASSING profile_xml AS "p");

-- -----------------------------------------------------
-- Example 4: Extract Multiple XML Elements
-- -----------------------------------------------------

SELECT 
    customer_id,
    XMLCAST(XMLQUERY('$p/profile/address/street' 
        PASSING profile_xml AS "p") AS VARCHAR(100)) AS street,
    XMLCAST(XMLQUERY('$p/profile/address/city' 
        PASSING profile_xml AS "p") AS VARCHAR(50)) AS city,
    XMLCAST(XMLQUERY('$p/profile/address/state' 
        PASSING profile_xml AS "p") AS VARCHAR(20)) AS state,
    XMLCAST(XMLQUERY('$p/profile/address/zip' 
        PASSING profile_xml AS "p") AS VARCHAR(10)) AS zip
FROM customer_profiles;

-- -----------------------------------------------------
-- Example 5: Update XML Data
-- -----------------------------------------------------

-- Update specific XML element
UPDATE customer_profiles
SET profile_xml = XMLQUERY('
    copy $new := $old
    modify do replace value of $new/profile/personal/age with 36
    return $new'
    PASSING profile_xml AS "old")
WHERE customer_id = 1;

-- -----------------------------------------------------
-- Example 6: Insert JSON Data
-- -----------------------------------------------------

INSERT INTO customer_profiles (customer_id, customer_name, preferences_json) VALUES
(3, 'Bob Wilson', '{"theme": "dark", "language": "en", "notifications": {"email": true, "push": false, "sms": true}, "privacy": {"profile_visible": true, "show_email": false}}'),
(4, 'Alice Brown', '{"theme": "light", "language": "es", "notifications": {"email": true, "push": true, "sms": false}, "privacy": {"profile_visible": false, "show_email": false}}');

-- -----------------------------------------------------
-- Example 7: Query JSON Data (DB2 11.1+)
-- -----------------------------------------------------

-- Extract JSON fields using JSON_VALUE
SELECT 
    customer_id,
    customer_name,
    JSON_VALUE(preferences_json, '$.theme') AS theme,
    JSON_VALUE(preferences_json, '$.language') AS language,
    JSON_VALUE(preferences_json, '$.notifications.email') AS email_notifications
FROM customer_profiles
WHERE preferences_json IS NOT NULL;

-- -----------------------------------------------------
-- Example 8: JSON_QUERY for Complex Objects
-- -----------------------------------------------------

-- Extract JSON objects and arrays
SELECT 
    customer_id,
    customer_name,
    JSON_QUERY(preferences_json, '$.notifications') AS notifications_obj,
    JSON_QUERY(preferences_json, '$.privacy') AS privacy_obj
FROM customer_profiles
WHERE preferences_json IS NOT NULL;

-- -----------------------------------------------------
-- Example 9: JSON Array Processing
-- -----------------------------------------------------

INSERT INTO product_catalog (product_id, product_name, metadata_json) VALUES
(101, 'Laptop Pro', '{"tags": ["electronics", "computers", "business"], "ratings": [5, 4, 5, 5, 4], "features": ["16GB RAM", "512GB SSD", "Intel i7"]}'),
(102, 'Smartphone X', '{"tags": ["electronics", "mobile", "5G"], "ratings": [5, 5, 4, 5], "features": ["6.5 inch screen", "128GB storage", "5G capable"]}');

-- Query JSON arrays
SELECT 
    product_id,
    product_name,
    JSON_QUERY(metadata_json, '$.tags') AS tags,
    JSON_QUERY(metadata_json, '$.features') AS features
FROM product_catalog
WHERE metadata_json IS NOT NULL;

-- -----------------------------------------------------
-- Example 10: JSON Path Expressions
-- -----------------------------------------------------

-- Complex JSON path queries
SELECT 
    customer_id,
    customer_name,
    JSON_VALUE(preferences_json, '$.notifications.email') AS email_enabled,
    JSON_VALUE(preferences_json, '$.notifications.push') AS push_enabled,
    JSON_VALUE(preferences_json, '$.privacy.profile_visible') AS profile_public
FROM customer_profiles
WHERE JSON_VALUE(preferences_json, '$.theme') = 'dark';

-- -----------------------------------------------------
-- Example 11: JSON_EXISTS for Filtering
-- -----------------------------------------------------

-- Check if JSON path exists
SELECT 
    customer_id,
    customer_name,
    preferences_json
FROM customer_profiles
WHERE JSON_EXISTS(preferences_json, '$.notifications.sms');

-- -----------------------------------------------------
-- Example 12: Create JSON from Relational Data
-- -----------------------------------------------------

-- Build JSON from query results
SELECT 
    customer_id,
    '{"customer_id": ' || customer_id || 
    ', "name": "' || customer_name || 
    '", "email": "' || email || '"}' AS customer_json
FROM (
    SELECT 
        customer_id,
        customer_name,
        'customer@example.com' AS email
    FROM customers
    FETCH FIRST 5 ROWS ONLY
);

-- -----------------------------------------------------
-- Example 13: XML to JSON Conversion Concept
-- -----------------------------------------------------

-- Extract XML data and format as JSON-like structure
SELECT 
    customer_id,
    customer_name,
    '{"email": "' || 
    XMLCAST(XMLQUERY('$p/profile/personal/email' 
        PASSING profile_xml AS "p") AS VARCHAR(100)) ||
    '", "city": "' ||
    XMLCAST(XMLQUERY('$p/profile/address/city' 
        PASSING profile_xml AS "p") AS VARCHAR(50)) ||
    '"}' AS profile_json
FROM customer_profiles
WHERE profile_xml IS NOT NULL;

-- -----------------------------------------------------
-- Example 14: Complex XML Query with Multiple Paths
-- -----------------------------------------------------

SELECT 
    customer_id,
    customer_name,
    XMLSERIALIZE(XMLQUERY('$p/profile/address' 
        PASSING profile_xml AS "p") AS VARCHAR(500)) AS address_xml,
    CASE 
        WHEN XMLCAST(XMLQUERY('$p/profile/preferences/newsletter' 
            PASSING profile_xml AS "p") AS VARCHAR(10)) = 'true' 
        THEN 'Subscribed'
        ELSE 'Not Subscribed'
    END AS newsletter_status
FROM customer_profiles
WHERE profile_xml IS NOT NULL;

-- -----------------------------------------------------
-- Example 15: XML Aggregation
-- -----------------------------------------------------

-- Create XML from aggregated data
SELECT 
    XMLELEMENT(NAME "customers",
        XMLAGG(
            XMLELEMENT(NAME "customer",
                XMLATTRIBUTES(c.customer_id AS "id"),
                XMLELEMENT(NAME "name", c.customer_name),
                XMLELEMENT(NAME "orders", 
                    XMLAGG(
                        XMLELEMENT(NAME "order",
                            XMLATTRIBUTES(o.order_id AS "id"),
                            XMLELEMENT(NAME "date", o.order_date),
                            XMLELEMENT(NAME "amount", o.total_amount)
                        )
                    )
                )
            )
        )
    ) AS customers_xml
FROM customers c
LEFT JOIN orders o ON c.customer_id = o.customer_id
WHERE c.customer_id <= 3
GROUP BY c.customer_id, c.customer_name;

-- -----------------------------------------------------
-- Example 16: Insert Complex XML Structure
-- -----------------------------------------------------

INSERT INTO product_catalog (product_id, product_name, specifications_xml) VALUES
(201, 'Enterprise Server', XMLPARSE(DOCUMENT '
<specifications>
    <hardware>
        <cpu>
            <model>Intel Xeon Gold 6248R</model>
            <cores>24</cores>
            <threads>48</threads>
            <clock_speed>3.0 GHz</clock_speed>
        </cpu>
        <memory>
            <capacity>256GB</capacity>
            <type>DDR4</type>
            <speed>2933MHz</speed>
        </memory>
        <storage>
            <drives>
                <drive type="SSD" capacity="2TB" interface="NVMe"/>
                <drive type="HDD" capacity="8TB" interface="SATA"/>
            </drives>
        </storage>
    </hardware>
    <software>
        <os>Red Hat Enterprise Linux 8</os>
        <included>
            <item>Database Server</item>
            <item>Web Server</item>
            <item>Monitoring Tools</item>
        </included>
    </software>
</specifications>'));

-- -----------------------------------------------------
-- Example 17: Query Nested XML Structures
-- -----------------------------------------------------

SELECT 
    product_id,
    product_name,
    XMLCAST(XMLQUERY('$s/specifications/hardware/cpu/model' 
        PASSING specifications_xml AS "s") AS VARCHAR(100)) AS cpu_model,
    XMLCAST(XMLQUERY('$s/specifications/hardware/cpu/cores' 
        PASSING specifications_xml AS "s") AS INTEGER) AS cpu_cores,
    XMLCAST(XMLQUERY('$s/specifications/hardware/memory/capacity' 
        PASSING specifications_xml AS "s") AS VARCHAR(20)) AS memory,
    XMLCAST(XMLQUERY('$s/specifications/software/os' 
        PASSING specifications_xml AS "s") AS VARCHAR(100)) AS operating_system
FROM product_catalog
WHERE specifications_xml IS NOT NULL;

-- -----------------------------------------------------
-- Example 18: XML Validation
-- -----------------------------------------------------

-- Check if XML is well-formed
SELECT 
    customer_id,
    customer_name,
    CASE 
        WHEN profile_xml IS NOT NULL THEN 'Valid XML'
        ELSE 'No XML Data'
    END AS xml_status
FROM customer_profiles;

-- -----------------------------------------------------
-- Example 19: JSON Array Length
-- -----------------------------------------------------

-- Count elements in JSON array (using string functions)
SELECT 
    product_id,
    product_name,
    metadata_json,
    LENGTH(metadata_json) - LENGTH(REPLACE(metadata_json, ',', '')) + 1 AS approx_array_elements
FROM product_catalog
WHERE metadata_json LIKE '%[%'
  AND metadata_json IS NOT NULL;

-- -----------------------------------------------------
-- Example 20: Hybrid XML and JSON Query
-- -----------------------------------------------------

-- Combine XML and JSON data in one query
SELECT 
    cp.customer_id,
    cp.customer_name,
    XMLCAST(XMLQUERY('$p/profile/personal/email' 
        PASSING cp.profile_xml AS "p") AS VARCHAR(100)) AS email_from_xml,
    JSON_VALUE(cp.preferences_json, '$.theme') AS theme_from_json,
    CASE 
        WHEN cp.profile_xml IS NOT NULL AND cp.preferences_json IS NOT NULL 
        THEN 'Complete Profile'
        WHEN cp.profile_xml IS NOT NULL 
        THEN 'XML Only'
        WHEN cp.preferences_json IS NOT NULL 
        THEN 'JSON Only'
        ELSE 'Incomplete'
    END AS profile_status
FROM customer_profiles cp;

-- =====================================================
-- Best Practices for XML/JSON in DB2:
-- =====================================================
-- 1. Use XML indexes for frequently queried paths
-- 2. Validate JSON structure before insertion
-- 3. Consider VARCHAR vs CLOB for JSON storage
-- 4. Use XML schema validation when appropriate
-- 5. Keep XML/JSON documents reasonably sized
-- 6. Index frequently accessed JSON paths
-- 7. Use XMLTABLE for shredding XML to relational
-- 8. Consider performance impact of parsing
-- 9. Use appropriate data types for extracted values
-- 10. Document XML/JSON structure for maintenance
-- =====================================================

-- Cleanup
-- DROP TABLE customer_profiles;
-- DROP TABLE product_catalog;