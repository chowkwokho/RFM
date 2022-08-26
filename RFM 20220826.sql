SELECT [ORDERNUMBER],
      [QUANTITYORDERED],
      [PRICEEACH],
      [ORDERLINENUMBER],
      [SALES],
      [ORDERDATE],
      [STATUS],
      [QTR_ID],
      [MONTH_ID],
      [YEAR_ID],
      [PRODUCTLINE],
      [MSRP],
      [PRODUCTCODE],
      [CUSTOMERNAME],
      [PHONE],
      [ADDRESSLINE1],
      [ADDRESSLINE2],
      [CITY],
      [STATE],
      [POSTALCODE],
      [COUNTRY],
      [TERRITORY],
      [CONTACTLASTNAME],
      [CONTACTFIRSTNAME],
      [DEALSIZE]
  FROM [Sales].[dbo].[sales_data_sample]

SELECT * INTO #Sales FROM [Sales].[dbo].[sales_data_sample]

-- Inspecting Data
SELECT * FROM #Sales

-- Checking unique values
SELECT DISTINCT [STATUS] FROM #Sales
SELECT DISTINCT [YEAR_ID] FROM #Sales ORDER BY 1
SELECT DISTINCT [PRODUCTLINE] FROM #Sales ORDER BY 1
SELECT DISTINCT [COUNTRY] FROM #Sales ORDER BY 1
SELECT DISTINCT [TERRITORY] FROM #Sales ORDER BY 1

--Checking data range
SELECT 'Order Date From' = MIN([ORDERDATE]), 'Order Date To' = MAX([ORDERDATE]) FROM #Sales

--Summary statistics
SELECT 'Total Sales (by number of order)' = COUNT(DISTINCT [ORDERNUMBER]), 'Total Revenue' = SUM([SALES]) FROM #Sales

--No of Order by Country
SELECT TOP 3 [COUNTRY], 'Total Order' = COUNT(DISTINCT [ORDERNUMBER])
FROM #Sales
GROUP BY [COUNTRY]
ORDER BY 2 DESC
--Findings: The first 3 country with highest number of order is USA, France and Spain

--Total Sale by year
SELECT [YEAR_ID], 'Total Month' = COUNT(DISTINCT [MONTH_ID]), 'Total Order' = COUNT(DISTINCT [ORDERNUMBER])
FROM #Sales
GROUP BY [YEAR_ID]
ORDER BY [YEAR_ID]
/*Findings:
The sales data included the whole year in 2003 to 2004 and 5 months data in 2005
*/
--Revenue by Deal Size
SELECT [DEALSIZE], sum (sales) Revenue
FROM #Sales
GROUP BY [DEALSIZE]
ORDER BY 2 DESC
-- Medium dealsizes brought in the most revenue


--Top Customer in 2003 by Sales (Status is Shipped)
SELECT TOP 3 /*1*/[YEAR_ID],
/*2*/[CUSTOMERNAME],
/*3*/'Total Order' = COUNT(DISTINCT [ORDERNUMBER]),
/*4*/'Total Sales'= SUM([SALES])
FROM #Sales
WHERE [STATUS] = 'Shipped' AND [YEAR_ID] = 2003
GROUP BY [YEAR_ID], [CUSTOMERNAME]
ORDER BY 1, 4 DESC, 2

--Top Customer in 2003 by Sales (Status is Shipped)
SELECT TOP 3 /*1*/[YEAR_ID],
/*2*/[CUSTOMERNAME],
/*3*/'Total Order' = COUNT(DISTINCT [ORDERNUMBER]),
/*4*/'Total Sales'= SUM([SALES])
FROM #Sales
WHERE [STATUS] = 'Shipped' AND [YEAR_ID] = 2004
GROUP BY [YEAR_ID], [CUSTOMERNAME]
ORDER BY 1, 4 DESC, 2

--Top Customer in 2005 by Sales (Status is Shipped)
SELECT TOP 3 /*1*/[YEAR_ID],
/*2*/[CUSTOMERNAME],
/*3*/'Total Order' = COUNT(DISTINCT [ORDERNUMBER]),
/*4*/'Total Sales'= SUM([SALES])
FROM #Sales
WHERE [STATUS] = 'Shipped' AND [YEAR_ID] = 2005
GROUP BY [YEAR_ID], [CUSTOMERNAME]
ORDER BY 1, 4 DESC, 2

-- Who is our best customer?
--Create temp table #rfm first
--DROP TABLE IF EXISTS #rfm
;WITH rfm as 
(
SELECT 
		CUSTOMERNAME, 
		SUM(sales) MonetaryValue,
		AVG(sales) AvgMonetaryValue,
		COUNT(ORDERNUMBER) Frequency,
		MAX(ORDERDATE) last_order_date,
		(SELECT MAX(ORDERDATE) FROM #Sales) max_order_date,
		DATEDIFF(DD, max(ORDERDATE), (SELECt max(ORDERDATE) FROM #Sales)) Recency
	FROM #Sales
	GROUP BY CUSTOMERNAME
),
rfm_calc as 
(
    SELECT r.*,
            NTILE(4) OVER (ORDER BY Recency DESC) rfm_recency,
            NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
            NTILE(4) OVER (ORDER BY MonetaryValue) rfm_monetary
        FROM rfm r
)
SELECT
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary  as varchar)rfm_cell_string
INTO #rfm
FROM rfm_calc c

-- Creating case statement for customer segmentation
SELECT customername , rfm_recency, rfm_frequency, rfm_monetary,
	case 
		when rfm_cell_string in (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) then 'lost_customers'  --lost customers
		when rfm_cell_string in (133, 134, 143, 244, 334, 343, 344, 144) then 'slipping away, cannot lose' -- (Big spenders who haven¡¦t purchased lately) slipping away
		when rfm_cell_string in (311, 411, 331) then 'new customers' --Customers who have only made a couple purchases
		when rfm_cell_string in (222, 223, 233, 322) then 'potential churners'
		when rfm_cell_string in (323, 333,321, 422, 332, 432) then 'active' --(Customers who buy often & recently, but at low price points)
		when rfm_cell_string in (433, 434, 443, 444) then 'loyal'
	end rfm_segment

FROM #rfm

-- What products are most often sold together? 
SELECT DISTINCT ordernumber, stuff(

	(SELECT ',' + PRODUCTCODE
	FROM #Sales p
	WHERE ordernumber in 
		(

			SELECT ordernumber
			FROM (
				SELECT ordernumber, count(*) rn
				FROM #Sales
				WHERE status = 'Shipped'
				GROUP BY ordernumber
			)m
			WHERE rn = 3
		)
		AND p.ordernumber = s.ordernumber
		for xml path (''))

		, 1, 1, '') ProductCodes

FROM #Sales s
ORDER BY 2 DESC

-- What city has the highest number of sales in a specific country?
select city, sum (sales) Revenue
from #Sales
where country = 'USA'
group by city
order by 2 desc
-- San Rafael has the highest number of sales in the US

--- What is the best product in USA?
select country, YEAR_ID, PRODUCTLINE, sum(sales) Revenue
from #Sales
where country = 'USA'
group by  country, YEAR_ID, PRODUCTLINE
order by 4 desc
-- Classic Cars are the best selling products in the US

-- What coutnry has the highest number of sales?
select country, sum (sales) Revenue
from #Sales
group by country
order by 2 desc
-- The US has the highest revenue