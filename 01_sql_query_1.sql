--Exploring Data-- 
---Number of Rows 541,909
---135,080 Records have no customerid
---406,829 Records have customerid
---397,884 Records have customerid , quantity , unitprice
---392,669 Final  Records 
SELECT * 
  FROM online_retail
 WHERE customerid is not null

--Cleaning Data--
WITH cte_online_retail AS
(
SELECT * 
  FROM online_retail
 WHERE CustomerID IS NOT NULL AND Quantity > 0 AND UnitPrice > 0 
)

--Duplicate Check--
---5215 Duplicated Records 
,cte_online_retail_2 AS
(
SELECT * , ROW_NUMBER () OVER (PARTITION BY invoiceno,stockcode,quantity ORDER BY invoicedate ) row_number
  FROM cte_online_retail
)
,online_retail_final AS
(
SELECT * 
  FROM cte_online_retail_2
 WHERE row_number = 1
)

-- COHORT Data Analysis-- understand the behaiour of customers (time-based cohort , size-based cohort , segment-based cohort)
--what is a cohort : a group of people with something in common
/*what is a cohort analysis : an analysis of several differenct cohorts to get a better understanding of behaviors , 
patterns and trends*/
---Unique Identifier (customerID)
---Initital Start Date (First Invoice Date)
---Revenue Data

--Create Cohort Group

SELECT customerid , MIN(invoicedate) first_purchase_date , 
	   DATEFROMPARTS(YEAR(MIN(invoicedate)),MONTH(MIN(invoicedate)),1) cohort_date
  FROM online_retail_final 
 GROUP BY CustomerID

--Create Cohort index (is an integer representation of the number of months thst has passed since the customers first engagement)--
WITH cte_online_retail AS
(
SELECT * 
  FROM online_retail
 WHERE CustomerID IS NOT NULL AND Quantity > 0 AND UnitPrice > 0 
)
,cte_online_retail_2 AS
(
SELECT * , ROW_NUMBER () OVER (PARTITION BY invoiceno,stockcode,quantity ORDER BY invoicedate ) row_number
  FROM cte_online_retail
)
,f_online_retail_1 AS
(
SELECT * 
  FROM cte_online_retail_2
 WHERE row_number = 1
)
,f_online_retail_2 AS
(
SELECT customerid , MIN(invoicedate) first_purchase_date , 
	   DATEFROMPARTS(YEAR(MIN(invoicedate)),MONTH(MIN(invoicedate)),1) cohort_date
  FROM f_online_retail_1  
 GROUP BY CustomerID
)


SELECT mm.* , (year_diff * 12 + month_diff + 1) cohort_index  
  FROM (
SELECT * , invoice_year  - cohort_year year_diff ,invoice_month - cohort_month month_diff 
  FROM (
SELECT a.invoiceno,a.stockcode,a.description,a.quantity,a.invoicedate,a.unitprice,a.customerid,a.country, b.cohort_date ,
	   YEAR(a.invoicedate) invoice_year,
	   MONTH(a.invoicedate) invoice_month,
	   YEAR(b.cohort_date) cohort_year ,
	   MONTH(b.cohort_date) cohort_month
  FROM f_online_retail_1 a
  JOIN f_online_retail_2 b
    ON a.customerid = b.customerid
	   ) m
	   ) mm

-- GROUPING CUSTOMERS BY COHORT INDEX--

WITH cte_online_retail AS
(
SELECT * 
  FROM online_retail
 WHERE CustomerID IS NOT NULL AND Quantity > 0 AND UnitPrice > 0 
)
,cte_online_retail_2 AS
(
SELECT * , ROW_NUMBER () OVER (PARTITION BY invoiceno,stockcode,quantity ORDER BY invoicedate ) row_number
  FROM cte_online_retail
)
,f_online_retail_1 AS
(
SELECT * 
  FROM cte_online_retail_2
 WHERE row_number = 1
)
,f_online_retail_2 AS
(
SELECT customerid , MIN(invoicedate) first_purchase_date , 
	   DATEFROMPARTS(YEAR(MIN(invoicedate)),MONTH(MIN(invoicedate)),1) cohort_date
  FROM f_online_retail_1  
 GROUP BY CustomerID
)
,f_online_retail_3 AS
(
SELECT mm.* , (year_diff * 12 + month_diff + 1) cohort_index  
  FROM (
SELECT * , invoice_year  - cohort_year year_diff ,invoice_month - cohort_month month_diff 
  FROM (
SELECT a.invoiceno,a.stockcode,a.description,a.quantity,a.invoicedate,a.unitprice,a.customerid,a.country, b.cohort_date ,
	   YEAR(a.invoicedate) invoice_year,
	   MONTH(a.invoicedate) invoice_month,
	   YEAR(b.cohort_date) cohort_year ,
	   MONTH(b.cohort_date) cohort_month
  FROM f_online_retail_1 a
  JOIN f_online_retail_2 b
    ON a.customerid = b.customerid
	   ) m
	   ) mm
)

SELECT DISTINCT customerid , cohort_date, cohort_index 
  FROM f_online_retail_3
 ORDER BY 1,3 




--Pivot table-- Cohort table

WITH cte_online_retail AS
(
SELECT * 
  FROM online_retail
 WHERE CustomerID IS NOT NULL AND Quantity > 0 AND UnitPrice > 0 
)
,cte_online_retail_2 AS
(
SELECT * , ROW_NUMBER () OVER (PARTITION BY invoiceno,stockcode,quantity ORDER BY invoicedate ) row_number
  FROM cte_online_retail
)
,f_online_retail_1 AS
(
SELECT * 
  FROM cte_online_retail_2
 WHERE row_number = 1
)
,f_online_retail_2 AS
(
SELECT customerid , MIN(invoicedate) first_purchase_date , 
	   DATEFROMPARTS(YEAR(MIN(invoicedate)),MONTH(MIN(invoicedate)),1) cohort_date
  FROM f_online_retail_1  
 GROUP BY CustomerID
)
,f_online_retail_3 AS
(
SELECT mm.* , (year_diff * 12 + month_diff + 1) cohort_index  
  FROM (
SELECT * , invoice_year  - cohort_year year_diff ,invoice_month - cohort_month month_diff 
  FROM (
SELECT a.invoiceno,a.stockcode,a.description,a.quantity,a.invoicedate,a.unitprice,a.customerid,a.country, b.cohort_date ,
	   YEAR(a.invoicedate) invoice_year,
	   MONTH(a.invoicedate) invoice_month,
	   YEAR(b.cohort_date) cohort_year ,
	   MONTH(b.cohort_date) cohort_month
  FROM f_online_retail_1 a
  JOIN f_online_retail_2 b
    ON a.customerid = b.customerid
	   ) m
	   ) mm
)
,f_online_retail_4 AS
(
SELECT DISTINCT customerid , cohort_date, cohort_index 
  FROM f_online_retail_3
)

SELECT * 
  FROM f_online_retail_4 
 PIVOT(COUNT(customerid) FOR cohort_index IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])) AS pivot_table
 ORDER BY cohort_date


--CREATE COHORT RETENTION RATE-- (convert count(customerid) in pivot table to percentage)
 
WITH cte_online_retail AS
(
SELECT * 
  FROM online_retail
 WHERE CustomerID IS NOT NULL AND Quantity > 0 AND UnitPrice > 0 
)
,cte_online_retail_2 AS
(
SELECT * , ROW_NUMBER () OVER (PARTITION BY invoiceno,stockcode,quantity ORDER BY invoicedate ) row_number
  FROM cte_online_retail
)
,f_online_retail_1 AS
(
SELECT * 
  FROM cte_online_retail_2
 WHERE row_number = 1
)
,f_online_retail_2 AS
(
SELECT customerid , MIN(invoicedate) first_purchase_date , 
	   DATEFROMPARTS(YEAR(MIN(invoicedate)),MONTH(MIN(invoicedate)),1) cohort_date
  FROM f_online_retail_1  
 GROUP BY CustomerID
)
,f_online_retail_3 AS
(
SELECT mm.* , (year_diff * 12 + month_diff + 1) cohort_index  
  FROM (
SELECT * , invoice_year  - cohort_year year_diff ,invoice_month - cohort_month month_diff 
  FROM (
SELECT a.invoiceno,a.stockcode,a.description,a.quantity,a.invoicedate,a.unitprice,a.customerid,a.country, b.cohort_date ,
	   YEAR(a.invoicedate) invoice_year,
	   MONTH(a.invoicedate) invoice_month,
	   YEAR(b.cohort_date) cohort_year ,
	   MONTH(b.cohort_date) cohort_month
  FROM f_online_retail_1 a
  JOIN f_online_retail_2 b
    ON a.customerid = b.customerid
	   ) m
	   ) mm
)
,f_online_retail_4 AS
(
SELECT DISTINCT customerid , cohort_date, cohort_index 
  FROM f_online_retail_3
),
f_online_retail_5 AS
(
SELECT * 
  FROM f_online_retail_4 
 PIVOT(COUNT(customerid) FOR cohort_index IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10],[11],[12],[13])) AS pivot_table
)

SELECT cohort_date,(1.0*[1]/[1])*100 AS [1],(1.0*[2]/[1])*100 AS [2] ,(1.0*[3]/[1])*100 AS [3],(1.0*[4]/[1])*100 AS [4],
	   (1.0*[5]/[1])*100 AS [5] , (1.0*[6]/[1])*100 AS [6],(1.0*[7]/[1])*100 AS [7],(1.0*[8]/[1])*100 AS [8],
	   (1.0*[9]/[1])*100 AS [9],(1.0*[10]/[1])*100 AS [10],(1.0*[11]/[1])*100 AS [11],(1.0*[12]/[1])*100 AS [12],
	   (1.0*[13]/[1])*100 AS [13]
  FROM f_online_retail_5 
 ORDER BY cohort_date