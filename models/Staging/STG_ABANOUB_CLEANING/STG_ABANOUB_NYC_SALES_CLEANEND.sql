{# Here an explanation for each CTE: 

1.	NYC_SALES_WITH_PK_NUMBER:
        •	Assigns a unique primary key (PK_NUMBER) to each row in the source data from STG_ABANOUB_NYC_SALES_CLEANEND.
2.	SPLIT_CLEAN_TAX_CLASS:
    •	Splits and cleans the TAX_CLASS_AT_PRESENT column into TAX_CLASS_AT_PRESENT and TAX_SUBCLASS_AT_PRESENT.
3.	BUILDING_CLASS_AT_PRESENT_CLEANED:
    •	Cleans the BUILDING_CLASS_AT_PRESENT column, replacing null or empty values with 'UNKNOWN'.
4.	APARTMENT_NUMBER_CLEANED:
    •	Extracts apartment numbers from the address, handling cases where the address contains a comma.
5.	RESIDENTIAL_UNITS_CAST:
    •	Casts and cleans the RESIDENTIAL_UNITS column, converting values with '-' to NULL and removing commas.
6.	COMMERCIAL_UNITS_CAST:
    •	Casts and cleans the COMMERCIAL_UNITS column, converting values with '-' to NULL and removing commas.
7.	TOTAL_UNITS_CAST:
    •	Casts and cleans the TOTAL_UNITS column, converting values with '-' to NULL and removing commas.
8.	RESIDENTIAL_UNITS_CLEANED:
    •	Adjusts RESIDENTIAL_UNITS column by calculating the difference when it is 0, using TOTAL_UNITS and COMMERCIAL_UNITS.
9.	COMMERCIAL_UNITS_CLEANED:
    •	Adjusts COMMERCIAL_UNITS column by calculating the difference when it is 0, using TOTAL_UNITS and RESIDENTIAL_UNITS.
10.	TOTAL_UNITS_CLEANED:
    •	Adjusts TOTAL_UNITS column by summing RESIDENTIAL_UNITS_CLEANED and COMMERCIAL_UNITS_CLEANED.
11.	LAND_SQUARE_FEET_CLEANED:
    •	Cleans the LAND_SQUARE_FEET column, converting values with '-' to NULL and removing commas.
12.	GROSS_SQUARE_FEET_CLEANED:
    •	Cleans the GROSS_SQUARE_FEET column, converting values with '-' to NULL and removing commas.
13.	YEAR_BUILT_CLEANED:
    •	Cleans the YEAR_BUILT column, converting 0 values to NULL.
14.	SALE_PRICE_CLEANED:
    •	Cleans the SALE_PRICE column, converting values with '-' or '$0' to NULL and removing commas.
15.	SALE_DATE_CLEANED:
    •	Updates the year format for dates in 2017 and 2018 and creates a SALE_DATE column.
16.	FINAL:
    •	Joins all cleaned and processed columns from previous CTEs and generates the final dataset for analysis.#}


with 

    NYC_SALES_WITH_PK_NUMBER AS (
        SELECT
        
            -- Generate an incremented PK_number unique for each row
            ROW_NUMBER() OVER (ORDER BY SALE_DATE ASC) AS PK_NUMBER,
            *
        FROM {{ source('SALES', 'NYC_SALES') }}
    ),
        
    SPLIT_CLEAN_TAX_CLASS AS (
        SELECT
            PK_NUMBER,
            CASE
                WHEN TAX_CLASS_AT_PRESENT IS NULL OR TRIM(TAX_CLASS_AT_PRESENT) = '' 
                    THEN 'UNKNOWN'
                WHEN LENGTH(COALESCE(NULLIF(TRIM(TAX_CLASS_AT_PRESENT), ''), 'UNKNOWN')) > 1 
                    THEN LEFT(TAX_CLASS_AT_PRESENT, 1)
                ELSE 'UNKNOWN'
            END AS TAX_CLASS_AT_PRESENT,
            CASE
                WHEN TAX_CLASS_AT_PRESENT IS NULL OR TRIM(TAX_CLASS_AT_PRESENT) = '' 
                    THEN 'UNKNOWN'
                WHEN LENGTH(COALESCE(NULLIF(TRIM(TAX_CLASS_AT_PRESENT), ''), 'UNKNOWN')) > 1 
                    THEN RIGHT(TAX_CLASS_AT_PRESENT, 1)
                ELSE 'UNKNOWN'
            END AS TAX_SUBCLASS_AT_PRESENT
        FROM NYC_SALES_WITH_PK_NUMBER
    ),


    BUILDING_CLASS_AT_PRESENT_CLEANED AS (
        SELECT 

            -- Check if their is null in the BUILDING_CLASS_AT_PRESENT col then make it 'UNKOWN'
            PK_NUMBER,
            CASE 
                WHEN BUILDING_CLASS_AT_PRESENT IS NULL OR TRIM(BUILDING_CLASS_AT_PRESENT) = '' THEN 'UNKNOWN'
                ELSE BUILDING_CLASS_AT_PRESENT
            END AS BUILDING_CLASS_AT_PRESENT
        FROM NYC_SALES_WITH_PK_NUMBER
    ),

    APARTMENT_NUMBER_CLEANED AS (
        SELECT
            -- get apartment number from the address when the address has a comma then the value of the apartment number
            -- else make it 'UNKOWN'
        PK_NUMBER,
        CASE
            WHEN TRIM(APARTMENT_NUMBER) = '' OR APARTMENT_NUMBER IS NULL
            THEN
                CASE
                    WHEN POSITION(',' IN ADDRESS) > 0
                    THEN TRIM(SUBSTRING(ADDRESS, POSITION(',' IN ADDRESS) + 1))
                    ELSE 'UNKNOWN'
                END
            ELSE APARTMENT_NUMBER
        END AS APARTMENT_NUMBER
        FROM NYC_SALES_WITH_PK_NUMBER
    ),

    RESIDENTIAL_UNITS_CAST AS (
        SELECT 
            
            PK_NUMBER,
            CASE
                WHEN TRIM(RESIDENTIAL_UNITS) LIKE '-'
                    THEN NULL
                ELSE CAST(REPLACE(RESIDENTIAL_UNITS, ',', '') AS INT)
            END AS RESIDENTIAL_UNITS

        FROM NYC_SALES_WITH_PK_NUMBER
    ),

    COMMERCIAL_UNITS_CAST AS (
        SELECT 
            
            PK_NUMBER,

            -- Remove all values '-' to NULL  "COMMERCIAL_UNITS" column and cast all COMMERCIAL_UNITS to INT datatype
            CASE
                WHEN TRIM(COMMERCIAL_UNITS) LIKE '-'
                    THEN NULL
                ELSE CAST(REPLACE(COMMERCIAL_UNITS, ',', '') AS INT)
            END AS COMMERCIAL_UNITS

        FROM NYC_SALES_WITH_PK_NUMBER
    ),
    
    TOTAL_UNITS_CAST AS (
        SELECT 
            
            PK_NUMBER,
            -- Remove all values '-' to 0  "TOTAL_UNITS" column and cast all TOTAL_UNITS to INT datatype
            CASE
                WHEN TRIM(TOTAL_UNITS) LIKE '-'
                    THEN NULL
                ELSE CAST(REPLACE(TOTAL_UNITS, ',', '') AS INT)
            END AS TOTAL_UNITS

        FROM NYC_SALES_WITH_PK_NUMBER        
    ),


    RESIDENTIAL_UNITS_CLEANED AS (
        SELECT 
            -- CHECK IF RESIDENTIAL_UNITS IS 0 so make it the difference between TOTAL_UNITS and COMMERCIAL_UNITS to be with right value

            NYC_SALES_WITH_PK_NUMBER.PK_NUMBER,
            CASE
                WHEN RESIDENTIAL_UNITS_CAST.RESIDENTIAL_UNITS = 0
                    THEN TOTAL_UNITS_CAST.TOTAL_UNITS - COMMERCIAL_UNITS_CAST.COMMERCIAL_UNITS

                ELSE RESIDENTIAL_UNITS_CAST.RESIDENTIAL_UNITS
            END AS RESIDENTIAL_UNITS

        FROM NYC_SALES_WITH_PK_NUMBER
        LEFT JOIN RESIDENTIAL_UNITS_CAST 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = RESIDENTIAL_UNITS_CAST.PK_NUMBER
            
        LEFT JOIN COMMERCIAL_UNITS_CAST 
                ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = COMMERCIAL_UNITS_CAST.PK_NUMBER

        LEFT JOIN TOTAL_UNITS_CAST 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = TOTAL_UNITS_CAST.PK_NUMBER
            
    ),

    COMMERCIAL_UNITS_CLEANED AS (
        SELECT 
            -- CHECK IF COMMERCIAL_UNITS IS 0 so make it the difference between TOTAL_UNITS and COMMERCIAL_UNITS to be with right value

            NYC_SALES_WITH_PK_NUMBER.PK_NUMBER,
            CASE
                WHEN COMMERCIAL_UNITS_CAST.COMMERCIAL_UNITS = 0
                    THEN TOTAL_UNITS_CAST.TOTAL_UNITS -RESIDENTIAL_UNITS_CAST.RESIDENTIAL_UNITS

                ELSE COMMERCIAL_UNITS_CAST.COMMERCIAL_UNITS
            END AS COMMERCIAL_UNITS

        FROM NYC_SALES_WITH_PK_NUMBER
        LEFT JOIN COMMERCIAL_UNITS_CAST 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = COMMERCIAL_UNITS_CAST.PK_NUMBER
            
        LEFT JOIN RESIDENTIAL_UNITS_CAST 
                ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = RESIDENTIAL_UNITS_CAST.PK_NUMBER

        LEFT JOIN TOTAL_UNITS_CAST 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = TOTAL_UNITS_CAST.PK_NUMBER
              
    ),

    TOTAL_UNITS_CLEANED AS (
        SELECT 
            -- CHECK IF TOTAL_UNITS IS 0 so make it the sum between TOTAL_UNITS and COMMERCIAL_UNITS to be with right value

            NYC_SALES_WITH_PK_NUMBER.PK_NUMBER,
            (RESIDENTIAL_UNITS_CLEANED.RESIDENTIAL_UNITS + COMMERCIAL_UNITS_CLEANED.COMMERCIAL_UNITS) AS TOTAL_UNITS

        FROM NYC_SALES_WITH_PK_NUMBER
        LEFT JOIN TOTAL_UNITS_CAST 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = TOTAL_UNITS_CAST.PK_NUMBER

        LEFT JOIN COMMERCIAL_UNITS_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = COMMERCIAL_UNITS_CLEANED.PK_NUMBER
            
        LEFT JOIN RESIDENTIAL_UNITS_CLEANED 
                ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = RESIDENTIAL_UNITS_CLEANED.PK_NUMBER
            
    ),

    LAND_SQUARE_FEET_CLEANED AS (
         SELECT 
            
            PK_NUMBER,
            -- Remove all values '-' to NULL "LAND_SQUARE_FEET" column and cast all LAND_SQUARE_FEET to INT datatype
            -- NOTE: There are 29033 rows with a value of zero.

            CASE
                WHEN TRIM(LAND_SQUARE_FEET) LIKE '-' 
                    THEN NULL
                ELSE CAST(REPLACE(LAND_SQUARE_FEET, ',', '') AS INT)
            END AS LAND_SQUARE_FEET

        FROM NYC_SALES_WITH_PK_NUMBER       
    ),

    GROSS_SQUARE_FEET_CLEANED AS (
        SELECT 
            
            PK_NUMBER,
            -- Remove all values '-' to 0  "GROSS_SQUARE_FEET" column and cast all GROSS_SQUARE_FEET to INT datatype
            -- NOTE: There are 21542 rows with a value of zero.

            CASE
                WHEN TRIM(GROSS_SQUARE_FEET) LIKE '-' 
                    THEN NULL
                ELSE CAST(REPLACE(GROSS_SQUARE_FEET, ',', '') AS INT)
            END AS GROSS_SQUARE_FEET

        FROM NYC_SALES_WITH_PK_NUMBER        
    ),

    YEAR_BUILT_CLEANED AS (
        SELECT 

            PK_NUMBER,
            -- Remove all values 0 to NULL "YEAR_BUILT"
            CASE
                WHEN YEAR_BUILT = 0 
                    THEN NULL
                ELSE YEAR_BUILT
            END AS YEAR_BUILT

        FROM NYC_SALES_WITH_PK_NUMBER        
    ),

    SALE_PRICE_CLEANED AS (
        SELECT 
          
            PK_NUMBER,
            -- Remove all values '-' to NULL and remove all '$' symbol in 2018 data in "SALE_PRICE" column and cast all SALE_PRICE to INT datatype
            CASE
                WHEN TRIM(SALE_PRICE) LIKE '-' OR SALE_PRICE = '0' OR SALE_PRICE LIKE '%$0%' 
                    THEN NULL
                WHEN SALE_PRICE LIKE '%$%' 
                    THEN CAST(REPLACE(REPLACE(SALE_PRICE, '$', ''), ',', '') AS INT)
                ELSE 
                    CAST(REPLACE(SALE_PRICE, ',', '') AS INT)
            END AS SALE_PRICE

        FROM NYC_SALES_WITH_PK_NUMBER       
    ),

    SALE_DATE_CLEANED AS (
        SELECT 
            
            PK_NUMBER,
            --Update the year format for the data in 2017 and 2018 where the date is in the form (0017-02-27) and (0018-02-27) to be (2017-02-27) and (2018-02-27)
            CASE
                WHEN YEAR(SALE_DATE) = 17 OR YEAR(SALE_DATE) = 18
                    THEN CAST(CONCAT('20', EXTRACT(YEAR FROM SALE_DATE), '-', EXTRACT(MONTH FROM SALE_DATE), '-', EXTRACT(DAY FROM SALE_DATE)) AS DATE)
                ELSE SALE_DATE -- keep the original date if not in the specified years
            END AS SALE_DATE

        FROM NYC_SALES_WITH_PK_NUMBER    
    ),

    FINAL AS (

        -- NOTE THAT I Ignored "EASEMENT" column since all of its values are either NULL or empty.

        SELECT 

            NYC_SALES_WITH_PK_NUMBER.PK_NUMBER,

            BOROUGH,

            BOROUGH_NAME,

            NEIGHBORHOOD,

            BUILDING_CLASS_CATEGORY,

            SPLIT_CLEAN_TAX_CLASS.TAX_CLASS_AT_PRESENT,

            SPLIT_CLEAN_TAX_CLASS.TAX_SUBCLASS_AT_PRESENT,

            BLOCK AS TAX_BLOCK,

            LOT AS TAX_LOT,

            BUILDING_CLASS_AT_PRESENT_CLEANED.BUILDING_CLASS_AT_PRESENT,       

            ADDRESS,

            APARTMENT_NUMBER_CLEANED.APARTMENT_NUMBER,

            ZIP_CODE,

            RESIDENTIAL_UNITS_CLEANED.RESIDENTIAL_UNITS,

            COMMERCIAL_UNITS_CLEANED.COMMERCIAL_UNITS,

            TOTAL_UNITS_CLEANED.TOTAL_UNITS,

            LAND_SQUARE_FEET_CLEANED.LAND_SQUARE_FEET,

            GROSS_SQUARE_FEET_CLEANED.GROSS_SQUARE_FEET,

            YEAR_BUILT_CLEANED.YEAR_BUILT,

            TAX_CLASS_AT_TIME_OF_SALE,

            BUILDING_CLASS_AT_TIME_OF_SALE,

            SALE_PRICE_CLEANED.SALE_PRICE,

            SALE_DATE_CLEANED.SALE_DATE

        FROM NYC_SALES_WITH_PK_NUMBER  

        LEFT JOIN SPLIT_CLEAN_TAX_CLASS 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = SPLIT_CLEAN_TAX_CLASS.PK_NUMBER
        
        LEFT JOIN BUILDING_CLASS_AT_PRESENT_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = BUILDING_CLASS_AT_PRESENT_CLEANED.PK_NUMBER
       
        LEFT JOIN APARTMENT_NUMBER_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = APARTMENT_NUMBER_CLEANED.PK_NUMBER

        LEFT JOIN RESIDENTIAL_UNITS_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = RESIDENTIAL_UNITS_CLEANED.PK_NUMBER
        
        LEFT JOIN COMMERCIAL_UNITS_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = COMMERCIAL_UNITS_CLEANED.PK_NUMBER
       
        LEFT JOIN TOTAL_UNITS_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = TOTAL_UNITS_CLEANED.PK_NUMBER
        
        LEFT JOIN LAND_SQUARE_FEET_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = LAND_SQUARE_FEET_CLEANED.PK_NUMBER
        
        LEFT JOIN GROSS_SQUARE_FEET_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = GROSS_SQUARE_FEET_CLEANED.PK_NUMBER

        LEFT JOIN YEAR_BUILT_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = YEAR_BUILT_CLEANED.PK_NUMBER

        LEFT JOIN SALE_PRICE_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = SALE_PRICE_CLEANED.PK_NUMBER
        
        LEFT JOIN SALE_DATE_CLEANED 
            ON NYC_SALES_WITH_PK_NUMBER.PK_NUMBER = SALE_DATE_CLEANED.PK_NUMBER

    )

SELECT *
FROM FINAL
