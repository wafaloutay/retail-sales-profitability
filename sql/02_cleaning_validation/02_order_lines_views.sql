/* RetailTraining | 02 / 02
   Purpose: standardize raw IDs, quantities, prices, and discount rates.
   Requires: dbo.fn_TryRetailAmount (01_amount_parser.sql).
   No update/delete of dbo.OrderLines_staging.
*/
USE RetailTraining;
GO

CREATE OR ALTER VIEW dbo.vw_OrderLines_Clean
AS
WITH SourceText AS (
    SELECT
        UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), OrderLineID)))) AS OrderLineID,
        UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), OrderID)))) AS OrderID,
        UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), ProductID)))) AS ProductID,
        Quantity, UnitPrice, DiscountPct,
        LOWER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), Quantity)))) AS QuantityText
    FROM dbo.OrderLines_staging
)
SELECT
    OrderLineID, OrderID, ProductID, Quantity, UnitPrice, DiscountPct,
    CASE QuantityText
        WHEN N'one' THEN 1
        WHEN N'two' THEN 2
        WHEN N'three' THEN 3
        ELSE TRY_CONVERT(INT, NULLIF(QuantityText, N''))
    END AS QuantityClean,
    dbo.fn_TryRetailAmount(CONVERT(NVARCHAR(200), UnitPrice)) AS UnitPriceClean
FROM SourceText;
GO

CREATE OR ALTER VIEW dbo.vw_OrderLines_Ready
AS
SELECT
    OrderLineID, OrderID, ProductID,
    Quantity, UnitPrice, DiscountPct,
    QuantityClean, UnitPriceClean,
    CASE
        WHEN DiscountPct IS NULL
           OR LTRIM(RTRIM(CONVERT(NVARCHAR(100), DiscountPct))) = N''
            THEN CAST(NULL AS DECIMAL(18, 6))
        WHEN CHARINDEX(N'%', CONVERT(NVARCHAR(100), DiscountPct)) > 0
            THEN CAST(
                dbo.fn_TryRetailAmount(
                    REPLACE(CONVERT(NVARCHAR(100), DiscountPct), N'%', N'')
                ) / 100.0 AS DECIMAL(18, 6)
            )
        ELSE CAST(
            dbo.fn_TryRetailAmount(CONVERT(NVARCHAR(100), DiscountPct))
            AS DECIMAL(18, 6)
        )
    END AS DiscountRateClean
FROM dbo.vw_OrderLines_Clean;
GO
