CREATE DATABASE walmartsales;
USE walmartsales;

--------------------------------------------------
-- Task 1: Identifying the Top Branch by Sales Growth Rate 
--------------------------------------------------
WITH monthly_sales AS (
    SELECT 
        Branch,
        DATE_FORMAT(Date, '%Y-%m') AS sales_month,
        SUM(Total) AS monthly_sales
    FROM sales
    GROUP BY Branch, DATE_FORMAT(Date, '%Y-%m')
),
with_lag AS (
    SELECT 
        Branch,
        sales_month,
        monthly_sales,
        LAG(monthly_sales) OVER (PARTITION BY Branch ORDER BY sales_month) AS prev_month_sales
    FROM monthly_sales
)
SELECT 
    Branch,
    ROUND(AVG((monthly_sales - prev_month_sales) / NULLIF(prev_month_sales,0) * 100),2) AS avg_growth_pct
FROM with_lag
WHERE prev_month_sales IS NOT NULL
GROUP BY Branch
ORDER BY avg_growth_pct DESC;

--------------------------------------------------
-- Task 2: Most Profitable Product Line for Each Branch 
--------------------------------------------------
-- Profit = Total - COGS (same as gross income)
SELECT s.Branch, s.`Product line`, s.total_profit
FROM (
    SELECT Branch, `Product line`, 
           SUM(Total - cogs) AS total_profit
    FROM sales
    GROUP BY Branch, `Product line`
) s
JOIN (
    SELECT Branch, MAX(profit_calc) AS max_profit
    FROM (
        SELECT Branch, `Product line`, 
               SUM(Total - cogs) AS profit_calc
        FROM sales
        GROUP BY Branch, `Product line`
    ) t
    GROUP BY Branch
) m
ON s.Branch = m.Branch AND s.total_profit = m.max_profit;

--------------------------------------------------
-- Task 3: Customer Segmentation (High / Medium / Low spenders) 
--------------------------------------------------
WITH cust_totals AS (
    SELECT 
        `Customer ID`,
        ROUND(SUM(Total),2) AS total_spent
    FROM sales
    GROUP BY `Customer ID`
),
ranked AS (
    SELECT 
        `Customer ID`,
        total_spent,
        NTILE(3) OVER (ORDER BY total_spent DESC) AS tier
    FROM cust_totals
)
SELECT 
    `Customer ID`,
    total_spent,
    CASE 
        WHEN tier = 1 THEN 'High'
        WHEN tier = 2 THEN 'Medium'
        ELSE 'Low'
    END AS segment
FROM ranked
ORDER BY total_spent DESC;


--------------------------------------------------
-- Task 4: Detect Anomalies in Sales Transactions 
--------------------------------------------------
WITH stats AS (
    SELECT 
        `Product line`,
        ROUND(AVG(Total),2) AS avg_sales,
        ROUND(STDDEV(Total),2) AS std_sales
    FROM sales
    GROUP BY `Product line`
)
SELECT 
    s.`Invoice ID`,
    s.`Product line`,
    ROUND(s.Total,2) AS Total,
    st.avg_sales,
    st.std_sales,
    CASE 
        WHEN s.Total > st.avg_sales + 2 * st.std_sales THEN 'High Anomaly'
        WHEN s.Total < st.avg_sales - 2 * st.std_sales THEN 'Low Anomaly'
        ELSE 'Normal'
    END AS anomaly_flag
FROM sales s
JOIN stats st 
  ON s.`Product line` = st.`Product line`
ORDER BY s.`Product line`, s.Total DESC;


--------------------------------------------------
-- Task 5: Most Popular Payment Method by City 
--------------------------------------------------
SELECT t.City, t.Payment, t.method_count
FROM (
    SELECT 
        City,
        Payment,
        COUNT(*) AS method_count,
        ROW_NUMBER() OVER (PARTITION BY City ORDER BY COUNT(*) DESC) AS rn
    FROM sales
    GROUP BY City, Payment
) t
WHERE t.rn = 1
ORDER BY t.City;

--------------------------------------------------
-- Task 6: Monthly Sales Distribution by Gender 
--------------------------------------------------
SELECT 
    DATE_FORMAT(Date, '%Y-%m') AS sales_month,
    Gender,
    SUM(Total) AS total_sales
FROM sales
GROUP BY DATE_FORMAT(Date, '%Y-%m'), Gender
ORDER BY sales_month ASC, Gender;

--------------------------------------------------
-- Task 7: Best Product Line by Customer Type 
--------------------------------------------------
SELECT t.`Customer type`, t.`Product line`, t.total_sales
FROM (
    SELECT 
        `Customer type`,
        `Product line`,
        SUM(Total) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY `Customer type` ORDER BY SUM(Total) DESC) AS rn
    FROM sales
    GROUP BY `Customer type`, `Product line`
) t
WHERE t.rn = 1
ORDER BY t.`Customer type`;

--------------------------------------------------
-- Task 8: Identifying Repeat Customers (purchases within 30 days) 
--------------------------------------------------
WITH cust_dates AS (
    SELECT 
        `Customer ID`,
        Date,
        LEAD(Date) OVER (PARTITION BY `Customer ID` ORDER BY Date) AS next_date
    FROM sales
)
SELECT DISTINCT `Customer ID`
FROM cust_dates
WHERE DATEDIFF(next_date, Date) <= 30;

--------------------------------------------------
-- Task 9: Top 5 Customers by Sales Volume 
--------------------------------------------------
SELECT 
    `Customer ID`, 
    SUM(Total) AS total_revenue
FROM sales
GROUP BY `Customer ID`
ORDER BY total_revenue DESC
LIMIT 5;

--------------------------------------------------
-- Task 10: Sales Trends by Day of the Week 
--------------------------------------------------
SELECT 
    DAYNAME(Date) AS day_of_week,
    SUM(Total) AS total_sales
FROM sales
GROUP BY DAYOFWEEK(Date), day_of_week
ORDER BY total_sales DESC;
