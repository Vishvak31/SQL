--01. List all the states in which we have customer who have bought cellphones from 2005 till today

--Answer:

SELECT DISTINCT T4.STATE AS State_In_which_Customer_have_bought_after_2005
FROM (SELECT T1.*,T2.[YEAR] FROM FACT_TRANSACTIONS AS T1 
LEFT JOIN 
DIM_DATE AS T2 ON T1.[DATE]=T2.[DATE]) AS T3 
LEFT JOIN 
DIM_LOCATION AS T4 ON T3.IDLOCATION=T4.IDLOCATION
WHERE [YEAR]>2004

--02. What state in the US is buying more 'Samsung' cell phones?

--Answer:

select top 1 T2.state,COUNT(T2.state) as Count_of_CellPhones
 from  FACT_TRANSACTIONS as T1
inner join DIM_LOCATION as T2 on
T1.IDLocation=T2.IDLocation
inner join DIM_MODEL as T3 on 
T1.IDModel=T3.IDModel
inner join DIM_MANUFACTURER as T4 on
T3.IDManufacturer=T4.IDManufacturer
where (T2.Country='US') and (T4.Manufacturer_Name='Samsung')
group by T2.state
order by Count_of_CellPhones desc
/*
------ ANSWER --------

state	Count_of_CellPhones
Arizona	18

------ ANSWER --------
*/


--03. Show the number of transactions for each model per zip code per state.

--Answer:

select distinct T1.state, T1.ZipCode, T3.Model_Name, COUNT(T2.IDModel) as Number_of_Transactions from DIM_LOCATION as T1
inner join FACT_TRANSACTIONS as T2 on
T1.IDLocation=T2.IDLocation
inner join DIM_MODEL as T3 on
T2.IDModel=T3.IDModel
group by state, ZipCode,T3.Model_Name

--04. Show the cheapest cellphone.

--Answer:

Select top 1 Model_Name, Unit_price from DIM_MODEL
order by Unit_price asc

--05. Show the number of transactions for each model in the top 5 manufacturers in term of sales quantity and order by average price.

--Answer:

SELECT Model_Name,AVG(TotalPrice) AVERAGE_PRICE FROM FACT_TRANSACTIONS AS T1
INNER JOIN DIM_MODEL AS T2 ON T1.IDModel = T2.IDModel
INNER JOIN DIM_MANUFACTURER AS T3 ON T2.IDManufacturer = T3.IDManufacturer
WHERE Manufacturer_Name IN (
SELECT TOP 5 Manufacturer_Name FROM FACT_TRANSACTIONS AS T1
INNER JOIN DIM_MODEL AS T2 ON T1.IDModel = T2.IDModel
INNER JOIN DIM_MANUFACTURER AS T3 ON T2.IDManufacturer = T3.IDManufacturer
GROUP BY Manufacturer_Name
ORDER BY SUM(Quantity) DESC
)
GROUP BY Model_Name
ORDER BY AVERAGE_PRICE

--06. List the names of the customers and the average amount spent in 2009,  Where the average is higher than 500 

--Answer:

select distinct T2.Customer_Name,AVG(T1.TotalPrice) as Average_Amount_Spent_in_2009 from FACT_TRANSACTIONS as T1
inner join DIM_CUSTOMER as T2 on
T1.IDCustomer=T2.IDCustomer
inner join DIM_DATE as T3 on
T1.DATE=T3.DATE
where (T3.year='2009') 
group by T2.Customer_Name
having (AVG(T1.TotalPrice)>500)

--07. List if there is any model that was in the top 5 in terms of quantity,  simultaneously in 2008, 2009 and 2010 

--Answer:

SELECT * FROM(
SELECT TOP 5 IDModel FROM FACT_TRANSACTIONS AS T1
WHERE YEAR(Date) = 2008
GROUP BY IDModel
ORDER BY SUM(Quantity) DESC
) T1

INTERSECT

SELECT * FROM(
SELECT TOP 5 IDModel FROM FACT_TRANSACTIONS
WHERE YEAR(Date) = 2009
GROUP BY IDModel
ORDER BY SUM(Quantity) DESC
) T1

INTERSECT

SELECT * FROM(
SELECT TOP 5 IDModel FROM FACT_TRANSACTIONS 
WHERE YEAR(Date) = 2010
GROUP BY IDModel
ORDER BY SUM(Quantity) DESC
) T1

--08. Show the manufacturer with the 2nd top sales in the year of 2009 and the  manufacturer with the 2nd top sales in the year of 2010. 

--Answer:

select years,Manufacturer_Name,Total_sale as [Top_2nd_Sales] 
from(
select YEAR(T1.date) as years,T3.Manufacturer_Name,sum(T1.TotalPrice) as Total_sale,
dense_rank() over (partition by YEAR(T1.date) order by sum(T1.TotalPrice) desc) as rank_year_sale
from FACT_TRANSACTIONS as T1 
left join 
DIM_MODEL as T2 on T1.IDModel=T2.IDModel
left join 
DIM_MANUFACTURER as T3 on T2.IDManufacturer=T3.IDManufacturer 
where YEAR(T1.date) in (2009,2010) 
group by YEAR(T1.date),T3.Manufacturer_Name
) just
where rank_year_sale=2

--09. Show the manufacturers that sold cellphone in 2010 but didn't in 2009. 

--Answer:

SELECT Manufacturer_Name
FROM FACT_TRANSACTIONS AS T1
LEFT JOIN DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
LEFT JOIN DIM_MANUFACTURER AS T3 ON T2.IDManufacturer=T3.IDManufacturer
WHERE YEAR(Date) IN (2010)
GROUP BY YEAR(Date),Manufacturer_Name

EXCEPT

SELECT Manufacturer_Name
FROM FACT_TRANSACTIONS AS T1
LEFT JOIN DIM_MODEL AS T2 ON T1.IDModel=T2.IDModel
LEFT JOIN DIM_MANUFACTURER AS T3 ON T2.IDManufacturer=T3.IDManufacturer
WHERE YEAR(Date) IN (2009)
GROUP BY YEAR(Date),Manufacturer_Name

--10. Find top 100 customers and their average spend, average quantity by each  year. Also find the percentage of change in their spend. 

--Answer:

--1st part(quatitu by each year)

SELECT TOP 100 Customer_Name,YEAR,AVERAGE_QUANTITY,AVERAGE_REVENUE,
((AVERAGE_REVENUE-DIFF)/DIFF)*100 AS CHANGE FROM(
SELECT  Customer_Name,YEAR(Date) AS YEAR,AVG(Quantity) AS AVERAGE_QUANTITY,AVG(TotalPrice) AS AVERAGE_REVENUE,
LAG(AVG(TotalPrice),1) OVER (PARTITION BY Customer_Name ORDER BY YEAR(Date) ASC) AS DIFF
FROM DIM_Customer AS T1
INNER JOIN FACT_TRANSACTIONS AS T2 ON T1.IDCustomer = T2.IDCustomer
GROUP BY YEAR(Date),Customer_Name
)T1
