

/*
 * Project Name:  Order Flow: A Relational Sales Data Exploration
 * Author: Mohammad Jawad Nayosh
 * Date: 04/18/2025 
*/

/*Case Development
In this project, I worked with an open-source sales dataset consisting of two relational tables: 
OrderList and EachOrderBreakdown. The main goal was to analyze customer orders and product-level sales data to uncover 
key business insights. Through data cleaning, I prepared the dataset by standardizing fields, removing duplicates, and 
structuring the data with primary and foreign keys to enable meaningful joins. My analysis aimed to answer questions such as:
Which products or sub-categories drive the most profit? Who are the top customers by sales? What months or segments perform best?
From this, we can recommend strategies like focusing on high-performing product lines, identifying peak sales periods for 
marketing efforts, and targeting loyal customers who place multiple orders. This project demonstrates how relational data and 
thoughtful exploration can lead to actionable business recommendations.*/


-- First, I upload tables to the database. We have two tables: 
-- 1 - OrderList and 2 - EachOrderBreakdown

SELECT* FROM EachOrderBreakdown; 
SELECT* FROM OrderList; 

-- The 'OrderList' table contains order-level information, such as order ID, customer details, 
-- and order dates. The 'EachOrderBreakdown' table provides item-level details for each order, 
-- including product names, sales, quantity, and profit.

--A: 
-- To properly analyze and manage this data, I need to establish a relational structure 
-- between the two tables. This will be done by assigning a primary key to the 'OrderList' table 
-- and a foreign key in the 'EachOrderBreakdown' table referencing the corresponding order ID. 
-- This relationship ensures data integrity and allows for accurate analysis and visualization.

ALTER TABLE OrderList 
ADD CONSTRAINT pk_orderid PRIMARY KEY (OrderId); 

ALTER TABLE EachOrderBreakdown
ADD CONSTRAINT fk_orderid FOREIGN KEY (OrderId) REFERENCES OrderList(OrderId); 


--B🧹 Data Cleaning

-- Before I analyze the data, it's important to clean and prepare it to ensure accuracy and consistency.
-- In this step, we split the combined 'City, State, Country' field into three separate columns 
-- so that location data can be filtered, grouped, and visualized more effectively.
--B1: 

ALTER TABLE OrderList
ADD city VARCHAR (50),
    state VARCHAR (50),
	country VARCHAR (50) 
    
UPDATE OrderList
SET 
  Country = PARSENAME(REPLACE(City_State_Country, ',','.'),1),
  State = PARSENAME(REPLACE(City_State_Country, ',','.'),2),
  City = PARSENAME(REPLACE(City_State_Country, ',','.'),3); 

ALTER TABLE OrderList
DROP COLUMN City_State_Country; 



--B2: I Add a new 'Category' column to the EachOrderBreakdown table
-- The category will be assigned based on the first three characters of the 'ProductName' column, using the following mapping:
-- 'TEC' → Technology
-- 'OFS' → Office Supplies
-- 'FUR' → Furniture

ALTER TABLE EachOrderBreakDown
ADD Category VARCHAR (50); 

UPDATE EachOrderBreakdown
SET Category = CASE  WHEN LEFT(ProductName, 3) = 'OFS' THEN 'Office Supply'
                     WHEN LEFT(ProductName, 3) = 'FUR' THEN 'Furnature'
			         WHEN LEFT(ProductName, 3)= 'TEC' THEN 'Technology'
			  END; 

--Note: What is a CASE statement?
--CASE works like an IF-ELSE IF ladder. It checks conditions one by one, and as soon as one is true, it returns the matching result.


--B3: Extract the characters after the '-' from the 'ProductName' column
-- This step helps isolate specific product details for better analysis
UPDATE EachOrderBreakdown
SET ProductName = RIGHT (ProductName, LEN(ProductName) - CHARINDEX('-', ProductName)); 


--B4: Now we remove duplicate rows from the EachOrderBreakdown table
-- Duplicates will be removed only if all column values are identical across rows

WITH CTE_duplicate AS(
SELECT* , ROW_NUMBER() OVER (PARTITION BY OrderId, ProductName, Discount, Sales,
                              profit, quantity, SubCategory, Category ORDER BY OrderID) AS RN
FROM EachOrderBreakdown
)
DELETE FROM CTE_duplicate
WHERE RN > 1; 


--B5: We should replace NULL values with 'NA' in the OrderPriority column of the OrderList table
-- This ensures consistency and avoids issues during analysis and visualization

UPDATE OrderList
SET OrderPriority = 'NA'
WHERE OrderPriority IS NULL; 

-- Data Exploration

--Q-1 List the top 10 orders with the highest slaes from the EachOrderBreakdown table

--C: 
-- 🔍 Data Exploration

-- After cleaning the data, the next step is to explore it to uncover patterns, trends, and key insights.
-- Data exploration helps us understand the structure, distribution, and relationships within the dataset, 
-- and guides us toward meaningful analysis and visualizations.

--C1: Let us list the top 10 orders with the highest sales from the EachOrderBreakdown table

SELECT TOP 10 *
FROM EachOrderBreakdown
ORDER BY Sales DESC; 


--C2: Now we will show the number of orders for each product category in the EachOrderBreakdown table
-- This helps identify which categories are ordered most frequently

SELECT Category, COUNT(Category) AS  Total_Orders
FROM EachOrderBreakdown
GROUP BY Category; 

--Answer:
--Technology	1523
--Furnature	1238
--Office Supply	5284


--C3: It is time to calculate the total profit for each sub-category in the EachOrderBreakdown table
-- This helps understand which sub-categories are contributing most to overall profitability

SELECT SubCategory, SUM(Profit) AS Total_Profit
FROM EachOrderBreakdown
GROUP BY SubCategory
ORDER BY Total_Profit DESC; 


--C4: Identify the customer with the highest total sales across all orders
-- Since customer information and sales data are stored in two different tables, we need to join them to perform this analysis
 
SELECT TOP 1 Customername, SUM(sales) AS TotalSales
FROM OrderList ol
JOIN EachOrderBreakdown ob
ON ol. OrderID = ob.OrderID
GROUP BY CustomerName
ORDER BY TotalSales DESC; 

-- Answer: CustomerName: Angie Massengill TotalSales: 16146.00


--C5: Let us find the months with the highest average sales in the OrderList table
-- This helps identify seasonal trends and peak sales periods

SELECT MONTH(OrderDate) AS MonthOrder, AVG(Sales) AS AverageSAles
FROM OrderList ol
JOIN EachOrderBreakdown ob 
ON ol.OrderID = ob. OrderID
GROUP BY MONTH(OrderDate)
ORDER BY AverageSAles DESC; 


--C6: Let us find the average quantity ordered by customers whose first name starts with the letter 'S'
-- This gives insight into ordering patterns based on customer name segments
SELECT AVG(Quantity) AS AvgQuantity
FROM OrderList ol 
JOIN EachOrderBreakdown ob
ON ol.OrderID = ob.OrderID
WHERE LEFT(Customername,1) = 'S'; 


--C7: Now we will find out how many new customers were acquired in the year 2014
-- This helps measure customer growth during that year
SELECT COUNT(*) AS NumberOfNewCustumers
FROM(
   SELECT CustomerName, MIN(OrderDate) AS FirstOrderDate
   FROM OrderList
   GROUP BY  CustomerName
   HAVING YEAR(MIN(OrderDate)) = '2014'
    ) AS Customer2014; 

-- Answer: 204 

--Calculate the percentage of total profit contributed by each subcategory to the overall profit.
--C8: Let us check what percentage of total profit contributed by each sub-category to the overall profit
-- This reveals which sub-categories are driving profitability within the business

	SELECT* FROM EachOrderBreakdown

	SELECT SubCategory, SUM(Profit) AS TotalProfit,
	       SUM(Profit)/(SELECT SUM(Profit) FROM EachOrderBreakdown) * 100 AS Percent_Of_Total
		   FROM  EachOrderBreakdown
		   GROUP BY SubCategory; 


--C9: Finding the average sales per customer, considering only customers who have made more than one order
-- This helps understand the spending behavior of repeat customers
WITH CustomerAvgSales AS (
SELECT CustomerName,COUNT(DISTINCT ol.OrderID) AS NoOfOrders, AVG(Sales) AS Avg_Sales
FROM OrderList ol 
JOIN EachOrderBreakdown ob
ON ol.OrderID = ob.OrderID
GROUP BY CustomerName
)
SELECT CustomerName,NoOfOrders, Avg_Sales
FROM CustomerAvgSales
Where NoOfOrders > 1; 


--C10: Identifing the top-performing sub-category in each category based on total sales
-- Including the sub-category name, total sales, and the ranking of each sub-category within its category
-- This helps highlight the best-selling sub-categories across different product categories

WITH TopPerformer AS(
SELECT Category, SubCategory, SUM(Sales) AS TotalSales,
       RANK()OVER (PARTITION BY Category ORDER BY SUM(Sales) DESC) AS SubCategoryRank
FROM EachOrderBreakdown
GROUP BY Category, SubCategory
)
SELECT *
FROM TopPerformer
WHERE SubCategoryRank = 1; 

--Answer: 
-- Category        SubCategory       TotalSales      SubCXategoryRank 
--Furnature   	   Bookcases	     294396.00      	1
--Office Supply	   Storage	         272489.00      	1
--Technology	   Copiers	         290081.00	        1


-- 🧾 Insights and Recommendations from Analysis: 
/*Based on the data analysis, several key insights emerged. Sub-categories like Copiers, Bookcases, and Storage were 
top performers in their respective categories, suggesting these products should be prioritized in marketing and inventory
strategies. The majority of orders came from the Office Supplies category, indicating steady demand in that segment. 
Additionally, customer Angie Massengill generated the highest total sales, highlighting opportunities for loyalty programs
targeting high-value customers. The analysis also showed that customer acquisition was strong in 2014, and repeat customers 
tend to have higher average sales, reinforcing the importance of retention efforts. Overall, the business can benefit by 
focusing on profitable sub-categories, optimizing seasonal sales strategies, and nurturing repeat customer relationships.*/