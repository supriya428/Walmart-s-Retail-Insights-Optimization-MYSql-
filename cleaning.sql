USE walmartsales;

--- Basic check
SELECT COUNT(*) AS rows_loaded FROM sales;
SELECT * FROM sales LIMIT 10;

SHOW COLUMNS FROM sales;

-- Descriptive stats
-- Unique branches
SELECT DISTINCT Branch FROM sales;

-- Unique cities
SELECT DISTINCT City FROM sales;

-- Unique product lines
SELECT DISTINCT `Product line` FROM sales;

-- Analysis Queries (examples)
-- Monthly sales
SELECT MONTH(Date) AS month, SUM(Total) AS monthly_sales FROM sales GROUP BY MONTH(Date) ORDER BY month;

-- Top 5 customers (by Total spending)
SELECT `Customer ID`, SUM(Total) AS total_spent FROM sales GROUP BY `Customer ID` ORDER BY total_spent DESC LIMIT 5;





