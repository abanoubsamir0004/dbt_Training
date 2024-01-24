WITH 

    SOURCE AS (
        SELECT 
        
            *
        
        FROM {{ ref('ABANOUB_SUPERSTORE') }}
    ),

    DIM_ORDER AS (
        SELECT DISTINCT

           ORDER_ID AS ORDER_KEY,
           SHIP_MODE

        FROM SOURCE
    ) 

SELECT * FROM DIM_ORDER
