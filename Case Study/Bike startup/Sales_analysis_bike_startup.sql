/* 
Case study: Sales Analysis for a bike company
In this noteook, we're going to analyse sales performance for an Australian-based start-up company 
who provies outdoor adventure and sporting products nation-wide.

My dashboard should
- Provide a fundamental overview of the company's sales. So any CEO can identify the problem at a glance.
- Contain minimal filtering options as they will not be interested in too many details yet.

We'll provide the following metrics in te dahsboard

- Revenue / profit / expenses (in $ and %)
- Sales & Profit margin breakdown by Product Category and the best selling ones
- Sales volume by location
- Customer Acquisition Cost (CAC): Cost to acquire a new customer (Sales expense) / New customers acquired)
- The average revenue per customer
- Sales % by New vs existing customer
- Product return rate

Reviewing Data & Data Cleaning
Ensured data is clean by removing duplicated columns 
*/ 
--Identified and deleted duplicated rows in 'Product_Subcategories' Table

WITH RowNum_CTE AS(
Select *,
ROW_NUMBER() OVER (
PARTITION BY productSubcategoryKey,
SubcategoryName,
ProductCategoryKey
ORDER BY ProductSubcategoryKey) row_num
FROM [Wonderland].dbo.Product_Subcategories

DELETE
FROM RowNum_CTE
WHERE row_num > 1

  
/*3. Data Wrangling to get the following metrics */

-- Revenue / profit / expenses by Location and Category
With Categories_Merged AS (
Select B.ProductKey, C.ProductCategoryKey, C.CategoryName
FROM [Wonderland].dbo.Product_Subcategories$ A
LEFT join [Wonderland].dbo.Products$ B ON A.ProductSubcategoryKey = B.ProductSubcategoryKey
LEFT Join [Wonderland].dbo.Product_Categories$ C ON A.ProductCategoryKey = C.ProductCategoryKey
)

Select CAST(A.OrderDate as Date) as OrderDate,A.Ordernumber, A.OrderQuantity, B.ProductKey, b.ProductName, b.ProductPrice, B.ProductCost, (A.OrderQuantity * B.ProductPrice) as SalesAmount, ((B.ProductPrice - B.ProductCost)*A.Orderquantity) As Profit,
 C.State, D.CategoryName
FROM [Wonderland].dbo.Product_Sales_2015$ A
Inner join [Wonderland].dbo.Products$ B ON A.ProductKey = B.ProductKey
Inner join [Wonderland].dbo.State_Mapping$ C ON A.TerritoryKey = C.SalesTerritoryKey
Inner Join Categories_Merged D ON A.ProductKey = D.ProductKey
Order By A.OrderNumber

-- New Customers in 2015
With First_Purchase as ( 
	Select  distinct a.CustomerKey, a.OrderDate, Min(a.OrderDate) Over (Partition By a.CustomerKey) as First_Purchase_Date, a.OrderNumber
From [NAB Job assessment].dbo.Product_Sales_FULL a)

Select COUNT(DISTINCT A.CustomerKey) as New_Customers
FROM First_Purchase A
Inner join Product_Sales_Full B on B.OrderNumber = A.OrderNumber 
WHERE Datediff(second, A.OrderDate,A.First_Purchase_Date) = 0
Group By YearMonth(a.First_Purchase_Date)

-- Customer Acquisition Cost (CAC) ((Sales expense) / New customers acquired

-- Total sales /  profit / cost per month
Select SUM(A.OrderQuantity * C.ProductPrice) as Total_Revenue, SUM(C.ProductCost) as Total_Expenses, 
  (SUM(A.OrderQuantity * C.ProductPrice))-SUM(C.ProductCost) as Total_Profit ,
  COUNT(DISTINCT A.CustomerKey) as Number_Of_Customers, 
  (SUM(A.OrderQuantity * C.ProductPrice)/COUNT(DISTINCT A.CustomerKey)) as Average_Revenue_Per_Customer,
  D.YearMonth
FROM [NAB Job assessment].dbo.Product_Sales_FULL A
Inner Join [Wonderland].dbo.Products$ C ON A.ProductKey = C.ProductKey
Inner join [Wonderland].dbo.Customers$ B ON A.CustomerKey = B.CustomerKey
Inner Join [Wonderland].dbo.CalendarDate$ D ON D.Date = A.OrderDate
group by D.YearMonth
Order by D.YearMonth


-- Monthly return
Select SUM(A.ReturnQuantity *B.Productprice) as ReturnAmount, c.YearMonth
from [NAB Job assessment].dbo.Product_Returns$ A
Inner Join [Wonderland].dbo.Products$ B ON A.ProductKey = B.ProductKey
Inner Join [Wonderland].dbo.CalendarDate$ C ON C.Date = A.ReturnDate
Group By Yearmonth(C.CalendarDate)
  

/*
Insights

1. Sales and profit
Company's revenue started growing since January 2016, but not so much with profit. 
This could mean either product cost is too expensive or the price is too low which would need to be reivewed. 

2. New vs Return customer
Majority of customers make one-off purchases only and not returning for more.
This could be because of many reasons such as poor product quality, customer service or simply because of the nature of business; as bike is their main product.

3. Sales % by Product
Company's revenue stream is highly-focused on bike sales. But the profit margin % is the lowest (41.15%)
On the other hand, accessories are not being sold as much (at 3.3%). Its profit margin % is highest at 62.8%

This could be an opportunity for the company to upsell or cross-sell these products. They can start by creating targeted campaigns.

4. No sales with 'Component' product category.
The company has made 0 sales on component-type product; bike parts, wheels, etc. 
This could imply there are already better products in the market, or customers go somewhere else to buy parts.
To boost sales with component-type products, they can consider partnering with bike mechanics or hire their own. 

Recommendation

The problem of the company is their profit margin rate is suffering due to a lack of returning customers. 
Rather than trying to reach out to new customers, Wonderland should really focus on selling products with healthier margins (Like Accessories) to existing customers. 

This can be done by 
- Reviewing their customer service.
- Reviewing their cost and prices
- Providing good deals on accessories or component type products.

They can start targeting the regions with the most sales like  NSW or Victoria. 

