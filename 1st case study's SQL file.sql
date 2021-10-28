--Data Preparation and Understanding.

--1. What is the total number of rows in each of the 3 tables in the database?

--Answser:
select COUNT(*)
from CUSTOMER
select COUNT(*)
from TRANSACTIONS
select COUNT(*)
from PROD_CAT_INFO

--2. What is the total number of transactions that have a return?

--Answer:
select COUNT(*) 
from (select TRANSACTION_ID from TRANSACTIONS
group by TRANSACTION_ID
having  COUNT(TRANSACTION_ID)>1) as Duplicate_Values;

--3.  Convert the date variables into valid date data formats before proceeding ahead.

--Answer:
UPDATE TRANSACTIONS
SET TRAN_DATE=CONVERT(DATE,TRAN_DATE,103)

--4. What is the time range of the transaction data available for analysis? Show the output in number of days , months, and years simutaneously in differenet columns.

--Answer:

 SELECT TRANSACTION_FROM,TRANSACTION_TO,
  DATEDIFF(YEAR,TRANSACTION_FROM,TRANSACTION_TO) AS YEAR_,
  DATEDIFF(MM,TRANSACTION_FROM,TRANSACTION_TO) AS MONTH_,
  DATEDIFF(DD,TRANSACTION_FROM,TRANSACTION_TO) AS DAY_ FROM 
  (SELECT MIN(tran_date) AS TRANSACTION_FROM,MAX(tran_date) AS TRANSACTION_TO 
  FROM TRANSACTIONS) AS DUMMY


--5. Which product category does the sub-category "DIY" belong to?

select PROD_CAT from PROD_CAT_INFO
where PROD_SUBCAT='DIY'

--******DATA ANALYSIS******

--1. Which channel is most frequently used for transactions?

--Answer:
select top 1 STORE_TYPE, COUNT(STORE_TYPE) as Frequency from TRANSACTIONS
group by STORE_TYPE
order by Frequency desc

--2. What is the count of Male and Female customers in the database?

--Answer:
select distinct GENDER, COUNT(GENDER) as Gender_Count from CUSTOMER
where (GENDER ='M') or (GENDER ='F')
group by GENDER

--3. From which city do we have the maximum quantity of products ever ordered?

--Answer:
select CITY_CODE,COUNT(CUST_ID)
from TRANSACTIONS
inner join CUSTOMER on TRANSACTIONS.CUST_ID=CUSTOMER.CUSTOMER_ID
where (CITY_CODE is not null)
group by CITY_CODE

--4. How many sub-categories are there under the Books category?

--Answer:
select PROD_CAT,count(PROD_SUBCAT) as No_of_Categories_Under_Books from PROD_CAT_INFO
where PROD_CAT='Books'
group by PROD_CAT

--5. What is the maximum quantity of products ever orderted?

--Answer:
select  PROD_SUBCAT_CODE, MAX(QTY) from TRANSACTIONS
group by PROD_SUBCAT_CODE 

--6. What is the net total revenue generated in categories Electronics and Books?

--Answer:

select PROD_CAT, SUM(TOTAL_AMT) as 'Total_Revenue'
from TRANSACTIONS
inner join PROD_CAT_INFO on TRANSACTIONS.PROD_CAT_CODE=PROD_CAT_INFO.PROD_CAT_CODE
where (PROD_CAT='Electronics' ) or (PROD_CAT='Books')
group by PROD_CAT

--7. How many customers have >10 transactions with us, exculuding returns?

--Answer:

SELECT cust_id,COUNT(transaction_id) AS NO_OF_TRANSACTION
FROM TRANSACTIONS
WHERE Qty>0
GROUP BY cust_id
HAVING COUNT(transaction_id)>10
ORDER BY NO_OF_TRANSACTION DESC

--8. What is the combined revenue earned from the "Electronics" & "Clothing" categories, from "Flagship stores"?

--Answer:

select STORE_TYPE, PROD_CAT,SUM(TOTAL_AMT) as 'Total_Revenue' ,COUNT(STORE_TYPE) as 'Number_of_Stores'
from TRANSACTIONS
inner join PROD_CAT_INFO on TRANSACTIONS.PROD_CAT_CODE=PROD_CAT_INFO.PROD_CAT_CODE
where (PROD_CAT='Electronics' ) or (PROD_CAT='Clothing')
group by PROD_CAT,STORE_TYPE
having  (STORE_TYPE='Flagship store')


--9.  What is the total revenue genetated from "Male" customers in "Electronics" category? Output should display total revenue by prod sub-cat.

--Answer:

select PROD_SUBCAT,SUM(TOTAL_AMT) from TRANSACTIONS
inner join CUSTOMER on
CUSTOMER.CUSTOMER_ID=TRANSACTIONS.CUST_ID
inner join PROD_CAT_INFO on
PROD_CAT_INFO.PROD_CAT_CODE=TRANSACTIONS.PROD_CAT_CODE
where (GENDER='M') and (PROD_CAT='Electronics')
group by PROD_SUBCAT

--10. What is percentage of sales and returns by product sub category? display only top 5 sub categories in term of sales.

--Answer:

CREATE VIEW [PRODUCT_SALE_RETURN] AS

SELECT PROD_SUB_CATEGORY,CAST(ROUND((SUM_SALE/SALE_TOTAL)*100,2) AS DECIMAL(10,2))  AS SALE_PERCENTAGE,
      CAST(ROUND((SUM_RETURN/RETURN_TOTAL)*100,2) AS decimal(10,2)) AS RETURN_PERCENTAGE FROM
 (SELECT * FROM
  (SELECT PROD_SUB_CATEGORY,SUM(PRODUCT_SALE) AS SUM_SALE,SUM(PRODUCT_RETURN) AS SUM_RETURN
   FROM 
 (SELECT B.prod_subcat AS PROD_SUB_CATEGORY ,
 CASE WHEN A.total_amt>0 THEN  A.total_amt ELSE 0 END AS PRODUCT_SALE,
 CASE WHEN A.total_amt<0 THEN  A.total_amt ELSE 0 END AS PRODUCT_RETURN
  FROM TRANSACTIONS AS A INNER JOIN
   products AS B ON A.prod_cat_code=B.prod_catcode
  AND A.prod_sub_cat_code=B.prod_subcat_code ) AS JUST
  GROUP BY PROD_SUB_CATEGORY ) AS DETAIL,
 (SELECT SUM(SUM_SALE) AS SALE_TOTAL,SUM(SUM_RETURN)AS RETURN_TOTAL 
 FROM 
  (SELECT PROD_SUB_CATEGORY,SUM(PRODUCT_SALE) AS SUM_SALE,SUM(PRODUCT_RETURN) AS SUM_RETURN
   FROM 
 (SELECT B.prod_subcat AS PROD_SUB_CATEGORY ,
 CASE WHEN A.total_amt>0 THEN  A.total_amt ELSE 0 END AS PRODUCT_SALE,
 CASE WHEN A.total_amt<0 THEN  A.total_amt ELSE 0 END AS PRODUCT_RETURN
  FROM TRANSACTIONS AS A INNER JOIN
   products AS B ON A.prod_cat_code=B.prod_catcode
  AND A.prod_sub_cat_code=B.prod_subcat_code ) AS JUST
  GROUP BY PROD_SUB_CATEGORY) JUST1) AS SUM_ALL) AS END_SUM
  
--The answer is divided into 2 components

-- 1. 

  SELECT * FROM [PRODUCT_SALE_RETURN] 

-- 2. 

  SELECT TOP 5 PROD_SUB_CATEGORY, SALE_PERCENTAGE FROM [PRODUCT_SALE_RETURN] 
  ORDER BY SALE_PERCENTAGE DESC

--11. For all customers aged between 25 to 35 find what is the net total revenue generated by these consumers in last 30 days of transactions from max transaction date available in the date?

--Answer:

select sum(total_amt)as REVENUE from
(select customer_Id,DATEDIFF(year,CONVERT(datetime,dob,103),GETDATE())as age, total_amt,tran_date,
DATEDIFF(day,tran_date,(select MAX(tran_date)from transactions)) as Lasst_Trans_Date
from transactions
left join CUSTOMER on
customer.CUSTOMER_ID=transactions.CUST_ID
where(DATEDIFF(year,CONVERT(datetime,dob,103),GETDATE()) between 25 and 35)
and DATEDIFF(day,tran_date,(select MAX(tran_date) FROM transactions))<=30) as  Last_date

--12. Which product category has seen the max value of returns in the last 3 months of transactions?

--Answer:

SELECT TOP 1 PROD_CAT AS PRODUCT_CATEGORY,MIN(TOTAL_AMT) AS MAX_RETURN 
FROM transactions left join PROD_CAT_INFO  
ON TRANSACTIONS.prod_cat_code=PROD_CAT_INFO.PROD_CAT_CODE 
AND TRANSACTIONS.PROD_SUBCAT_CODE=PROD_CAT_INFO.PROD_SUB_CAT_CODE
WHERE DATEDIFF(DAY,TRANSACTIONS.TRAN_DATE,(SELECT MAX(TRAN_DATE) AS MAX_TRANSACTION from transactions)) <=30 
AND TRANSACTIONS.total_amt<0
GROUP BY PROD_CAT
ORDER BY MAX_RETURN

--13. Which store-type category has seen the max value of returns in the last 3 months of transaction?

--Answer:

SELECT Store_type AS TYPE_OF_STORE,Qty AS Max_Products_Sold,total_amt AS Max_Sales
FROM transactions 
WHERE total_amt=(SELECT MAX(TOTAL_AMT) FROM transactions) 
AND QTY=(SELECT MAX(QTY) FROM transactions) 

--14. What are the categories for which average revenue is above overall average?

--Answer:

select PROD_CAT as Product_Category, AVG(TOTAL_AMT) as Average_Revenue from TRANSACTIONS
left join PROD_CAT_INFO on
PROD_CAT_INFO.PROD_CAT_CODE=TRANSACTIONS.PROD_CAT_CODE
and TRANSACTIONS.PROD_SUBCAT_CODE=PROD_CAT_INFO.PROD_SUB_CAT_CODE
group by PROD_CAT
having avg(TOTAL_AMT)>=(SELECT AVG(TOTAL_AMT) AS Total_Average FROM transactions)

--15. Find the average and total revenue by each subcategory for the categories which are amont the top 5 categories in terms of quantity sold.

--Answer:

SELECT prod_subcat AS SUB_CATEGORY,SUM(total_amt) AS TOTAL_REVENUE, AVG(TOTAL_AMT) AS AVERAGE_REVENUE
FROM transactions LEFT JOIN PROD_CAT_INFO 
ON transactions.prod_cat_code=PROD_CAT_INFO.PROD_CAT_CODE AND transactions.PROD_SUBCAT_CODE=PROD_CAT_INFO.PROD_CAT_CODE
WHERE PROD_CAT_INFO.prod_cat IN (SELECT PROD_CAT FROM (SELECT TOP 5 D.prod_cat,SUM(C.Qty) AS QUANTITY FROM transactions AS C 
LEFT JOIN PROD_CAT_INFO AS D 
ON C.prod_cat_code=D.PROD_CAT_CODE AND C.PROD_SUBCAT_CODE=D.PROD_SUB_CAT_CODE
GROUP BY D.prod_cat ORDER BY QUANTITY DESC)AS JUST) 
GROUP BY PROD_CAT_INFO.PROD_SUBCAT