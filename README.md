# DB2 SQL Examples Repository

A comprehensive collection of DB2 SQL examples demonstrating advanced SQL features, best practices, and common use cases.

## 📚 Contents

- **Recursive SQL** - Hierarchical queries, graph traversal, and recursive CTEs
- **OLAP Functions** - Window functions, ranking, and analytical queries
- **Temporal Tables** - System-versioned tables and time-travel queries
- **Advanced Joins** - Complex join patterns and optimization techniques
- **Data Generation** - Sample data creation and test data utilities
- **Performance Tuning** - Query optimization examples and explain plans
- **XML/JSON** - Working with semi-structured data in DB2

## 🚀 Getting Started

### Prerequisites

- DB2 11.1 or higher (some features require 11.5+)
- Database with appropriate privileges (CREATE TABLE, SELECT, INSERT, etc.)
- Optional: DB2 Command Line Processor (CLP) or any SQL client

### Setup

1. Clone this repository:
```bash
git clone https://github.com/yourusername/db2-sql-examples.git
cd db2-sql-examples
```

2. Connect to your DB2 database:
```bash
db2 connect to  user 
```

3. Run the setup script to create sample tables:
```bash
db2 -tvf setup/01_create_sample_tables.sql
db2 -tvf setup/02_load_sample_data.sql
```

## 📖 Usage Examples

### Recursive SQL
```sql
-- Find all employees in a manager's hierarchy
db2 -tvf examples/01_recursive_sql.sql
```

### OLAP Functions
```sql
-- Calculate running totals and rankings
db2 -tvf examples/02_olap_functions.sql
```

### Temporal Tables
```sql
-- Query historical data
db2 -tvf examples/03_temporal_tables.sql
```

## 📂 Repository Structure

```
db2-sql-examples/
├── README.md
├── setup/
│   ├── 01_create_sample_tables.sql
│   └── 02_load_sample_data.sql
├── examples/
│   ├── 01_recursive_sql.sql
│   ├── 02_olap_functions.sql
│   ├── 03_temporal_tables.sql
│   ├── 04_advanced_joins.sql
│   ├── 05_data_generation.sql
│   ├── 06_xml_json.sql
│   └── 07_performance_tuning.sql
└── cleanup/
    └── cleanup_all.sql
```

## 🎯 Key Features Demonstrated

### Recursive SQL
- Hierarchical data traversal
- Bill of materials (BOM) explosion
- Graph path finding
- Cycle detection
- Depth and breadth-first search

### OLAP Functions
- ROW_NUMBER, RANK, DENSE_RANK
- Window frames (ROWS, RANGE)
- Moving averages and cumulative sums
- LEAD/LAG for time series analysis
- NTILE for bucketing
- FIRST_VALUE/LAST_VALUE

### Temporal Tables
- System-versioned tables
- Point-in-time queries
- Historical data analysis
- Audit trail queries

### Advanced Features
- Common Table Expressions (CTEs)
- MERGE statements
- Table functions
- ARRAY and MULTISET operations
- Regular expressions
- Full-text search

## 💡 Tips and Best Practices

1. **Use EXPLAIN** - Always check execution plans for complex queries
2. **Index Strategy** - Create appropriate indexes for recursive and window queries
3. **Statistics** - Keep RUNSTATS up to date for optimal performance
4. **Memory Configuration** - Adjust SHEAPTHRES_SHR for complex sorts
5. **Commit Points** - Use appropriate commit frequency for large operations

## 🔧 Performance Considerations

```sql
-- Enable query optimization
SET CURRENT QUERY OPTIMIZATION = 9;

-- Check execution plan
db2exfmt -d  -g TIC -w -1 -n % -s % -# 0 -o explain.out

-- Monitor statement execution
db2 get snapshot for dynamic sql on 
```

## 📊 Sample Data

The repository includes scripts to generate realistic sample data:
- Employee hierarchy (1000+ employees)
- Sales transactions (10000+ records)
- Product catalog with categories
- Customer orders with line items
- Time dimension table

## 🐛 Troubleshooting

### Common Issues

**SQL0440N - No authorized routine found**
```sql
-- Grant execute on functions
GRANT EXECUTE ON FUNCTION SYSFUN.GENERATE_UNIQUE TO PUBLIC;
```

**SQL0952N - Processing was cancelled**
```sql
-- Increase agent stack size
db2set DB2_HASH_JOIN=Y
```

**SQL1585W - Recursive SQL with no termination condition**
```sql
-- Always include proper WHERE clause in recursive anchor
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🔗 Resources

- [DB2 SQL Reference](https://www.ibm.com/docs/en/db2/11.5?topic=reference-sql)
- [DB2 Performance Best Practices](https://www.ibm.com/docs/en/db2/11.5?topic=performance)
- [DB2 Community](https://community.ibm.com/community/user/datamanagement/communities/community-home?CommunityKey=ea909850-39ea-4ac4-9512-8e2eb37ea09a)

## 📧 Contact

Florian 

Project Link: [https://github.com/mockchainblaster/db2sql]((https://github.com/mockchainblaster/db2sql))

## ⭐ Acknowledgments

- IBM DB2 Documentation Team
- DB2 Community Contributors
- Stack Overflow DB2 Community
