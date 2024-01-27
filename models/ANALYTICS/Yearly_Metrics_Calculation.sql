-- Yearly Metrics Calculation: This query is for calculating the yearly CUSTOMER_COUNT, PRODUCTS_SOLD, TOTAL_SALES, and TOTAL_PROFITS.

WITH 

    DIM_DATE AS (
        SELECT * FROM {{ ref('DIM_DATE') }}
    ),

    FACT_SALES AS (
        SELECT * FROM {{ ref('FACT_SALES') }}
    ),

    YEARLY_METRICS AS (
        SELECT
            DIM_DATE.YEAR ,
            COUNT(DISTINCT FACT_SALES.CUSTOMER_KEY) AS CUSTOMERS_COUNT,
            COUNT(DISTINCT FACT_SALES.PRODUCT_KEY) AS PRODUCTS_SOLD,
            ROUND(SUM(FACT_SALES.SALES),3) AS TOTAL_SALES,
            ROUND(SUM(FACT_SALES.PROFIT),3) AS TOTAL_PROFITS

        FROM FACT_SALES 
        LEFT JOIN DIM_DATE 
            ON FACT_SALES.ORDER_DATE_KEY = DIM_DATE.DATE_KEY

        GROUP BY DIM_DATE.YEAR 
    )


SELECT *
FROM YEARLY_METRICS
ORDER BY YEAR