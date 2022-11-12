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

# 1. Trendline Graph

The company had ups and downs with its sales revenue until January 2016 and then they started to grow.
The company's profit is not growing as much as its revenue, in fact, the gap is getting larger. Company's profit is suffering

This could mean either product cost is too expensive or the price is too low, which CEO would need to review in further detail.

# 2. Average revenue vs Customer Acquisition cost

Explain ARPC & CAC→ Difference between these two, for now, seems ok (about 38%) → Set date range to 2017  
The difference between the two is $100, which is about 12% profit margin from new customers.

This indicates acquiring new customers is not efficient. It appears targeting existing customers is the smarter move here.

# 3. Sales % by New customers

The why new customers are expensive could be because they already have new customers. But didn't manage to retain them.
This pie graph shows lots of customers only made one-off purchases which indicates customers are not really coming back for more.

This could be because of many reasons such as poor product quality, customer service or simply because of the nature of business. 

# 4. Sales % by Product

What I mean by this is if you have at the table above, you can see that the company's revenue stream is highly-focused on bike sales. But the profit margin % is the lowest (41.15%).
On the other hand, Accessories sales are only at 3.3% although the profit margin % is highest at 62.8%

This could be an opportunity for the company to upsell or cross-sell these products that as they have healthier margins %. They can start by creating a very targeted campaign.

# 5. 0 sales in the 'Component' product category.

And there is another problem, you may not have noticed from the Visuals, but the company has made 0 sales on component products.
This means two things, their components are not competitive in the market or customers don't know what to do with the components. What they really need can be a bike-repair service, not just parts. Also, components themselves can be bought easily online.
This can be an opportunity to consider providing bike-repair services that entail three benefits for the company.

1. The company can sell components.
2. With good product and services quality, customers will be returning.
3. The company gains a competitive advantage in the market as its service is more personalized to each individual customer which will help with engagement.

But this is only a suggestion and it is up to the CEO to decide the company's directions.

# 6. Recommendation

The problem of the company is their profit margin rate is suffering due to a lack of returning customers. Rather than trying to branch or reach out to new customers, Wonderland should really focus on selling products with healthier margins (Like Accessories) to existing customers. This can be done by 

- Reviewing their customer service.
- Reviewing their cost and prices
- Providing good deals on accessories products to customers who need them.
- Providing bike-repair services to customers.

They can start targeting the regions with the most sales like  NSW or Victoria. 

