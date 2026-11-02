/* RetailTraining | 02 / 03
   Purpose: prepare products without multiplying sales during JOINs.
   P010 has two source records (USB-C Hub / USB C Hub).
   A descriptive label is selected by a documented training-set rule;
   a conflicting unit cost becomes NULL instead of being guessed.
*/
USE RetailTraining;
GO

CREATE OR ALTER VIEW dbo.vw_Products_Clean
AS
SELECT
    UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), ProductID)))) AS ProductID,
    LTRIM(RTRIM(CONVERT(NVARCHAR(200), ProductName))) AS ProductName,
    CASE
        WHEN LOWER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), Category)))) = 'stationery'
            THEN 'Stationery'
        ELSE LTRIM(RTRIM(CONVERT(NVARCHAR(100), Category)))
    END AS Category,
    UnitCost, ListPrice, Active,
    dbo.fn_TryRetailAmount(CONVERT(NVARCHAR(200), UnitCost)) AS UnitCostClean,
    dbo.fn_TryRetailAmount(CONVERT(NVARCHAR(200), ListPrice)) AS ListPriceClean
FROM dbo.Products_staging;
GO

CREATE OR ALTER VIEW dbo.vw_Products_Unique
AS
SELECT
    ProductID,
    -- Training-specific label preference; review any differing product labels.
    COALESCE(MAX(CASE WHEN CHARINDEX('-', ProductName) > 0 THEN ProductName END),
             MIN(ProductName)) AS ProductName,
    CASE WHEN COUNT(DISTINCT Category) = 1 THEN MIN(Category) ELSE NULL END AS Category,
    CASE WHEN COUNT(DISTINCT UnitCostClean) <= 1
              THEN MAX(UnitCostClean)
         ELSE NULL END AS UnitCostClean,
    MAX(ListPriceClean) AS ListPriceClean,
    COUNT(*) AS NumberOfProductRecords,
    COUNT(DISTINCT ProductName) AS ProductNameVariantCount,
    COUNT(DISTINCT UnitCostClean) AS UnitCostVariantCount,
    COUNT(DISTINCT Category) AS CategoryVariantCount
FROM dbo.vw_Products_Clean
GROUP BY ProductID;
GO

-- Verify known product issue. This should return one P010 record.
SELECT * FROM dbo.vw_Products_Unique WHERE ProductID = 'P010';
