/* RetailTraining | 03 / 01
   Creates analytical fields from cleaned sales lines, canonical products,
   and summarized orders. No duplicate orders or products in the joins.

   IMPORTANT DATE ASSUMPTION:
   dd/mm/yyyy and dd-mm-yyyy are interpreted as day-first in this exercise.
   Ambiguous dates require source confirmation for real business reporting.
*/
USE RetailTraining;
GO

CREATE OR ALTER VIEW dbo.vw_Sales_Analysis
AS
WITH OrderSource AS (
    SELECT
        UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), OrderID)))) AS OrderID,
        LTRIM(RTRIM(CONVERT(NVARCHAR(100), OrderDate))) AS RawOrderDate,
        UPPER(LTRIM(RTRIM(CONVERT(NVARCHAR(100), OrderStatus)))) AS RawOrderStatus
    FROM dbo.Orders
),
OrderPrepared AS (
    SELECT OrderID,
        CASE
            WHEN RawOrderDate LIKE '[12][0-9][0-9][0-9]-[01][0-9]-[0-3][0-9]'
                THEN TRY_CONVERT(DATE, RawOrderDate, 23)
            WHEN RawOrderDate LIKE '[12][0-9][0-9][0-9]/[01][0-9]/[0-3][0-9]'
                THEN TRY_CONVERT(DATE, REPLACE(RawOrderDate, '/', '-'), 23)
            WHEN RawOrderDate LIKE '[0-3][0-9]/[01][0-9]/[12][0-9][0-9][0-9]'
                THEN TRY_CONVERT(DATE, RawOrderDate, 103)
            WHEN RawOrderDate LIKE '[0-3][0-9]-[01][0-9]-[12][0-9][0-9][0-9]'
                THEN TRY_CONVERT(DATE, RawOrderDate, 105)
            WHEN RawOrderDate LIKE '[A-Za-z]%'
                THEN COALESCE(
                    TRY_CONVERT(DATE, RawOrderDate, 107),
                    TRY_CONVERT(DATE, STUFF(RawOrderDate, LEN(RawOrderDate) - 4, 0, ','), 107),
                    TRY_CONVERT(DATE, RawOrderDate, 0)
                )
            ELSE TRY_CONVERT(DATE, RawOrderDate, 106)
        END AS ParsedOrderDate,
        CASE RawOrderStatus
            WHEN 'DELIVRED' THEN 'Delivered'
            WHEN 'DELIVERED' THEN 'Delivered'
            WHEN 'SHIPPED' THEN 'Shipped'
            WHEN 'CANCELLED' THEN 'Cancelled'
            WHEN 'RETURNED' THEN 'Returned'
            WHEN 'PENDING' THEN 'Pending'
            WHEN 'PROCESSING' THEN 'Processing'
            WHEN 'IN TRANSIT' THEN 'In Transit'
            WHEN 'UNKNOWN' THEN 'Unknown'
            ELSE COALESCE(NULLIF(RawOrderStatus, ''), 'Unknown')
        END AS OrderStatusClean
    FROM OrderSource
),
OrderSummary AS (
    SELECT OrderID,
           COUNT(*) AS NumberOfOrderRecords,
           CASE WHEN COUNT(ParsedOrderDate) = COUNT(*)
                      AND MIN(ParsedOrderDate) = MAX(ParsedOrderDate)
                THEN MIN(ParsedOrderDate) ELSE CAST(NULL AS DATE)
           END AS OrderDate,
           CASE WHEN COUNT(DISTINCT OrderStatusClean) = 1
                THEN MIN(OrderStatusClean) ELSE 'Ambiguous'
           END AS OrderStatus
    FROM OrderPrepared
    GROUP BY OrderID
),
JoinedSales AS (
    SELECT ol.OrderLineID, ol.OrderID, ol.ProductID,
           ol.QuantityClean, ol.UnitPriceClean, ol.DiscountRateClean,
           p.ProductName, p.Category, p.UnitCostClean,
           o.OrderDate, o.OrderStatus, o.NumberOfOrderRecords,
           CASE
               WHEN ol.QuantityClean IS NULL THEN 'InvalidQuantity'
               WHEN ol.QuantityClean <= 0 THEN 'NonPositiveQuantity'
               WHEN ol.UnitPriceClean IS NULL THEN 'InvalidPrice'
               WHEN ol.UnitPriceClean < 0 THEN 'NegativePrice'
               WHEN ol.DiscountRateClean IS NULL THEN 'MissingOrInvalidDiscount'
               WHEN ol.DiscountRateClean < 0 OR ol.DiscountRateClean > 1
                   THEN 'OutOfRangeDiscount'
               WHEN ol.DiscountRateClean = 1 THEN 'Review100Pct'
               WHEN p.ProductID IS NULL THEN 'MissingProduct'
               ELSE 'OK'
           END AS RevenueQualityStatus
    FROM dbo.vw_OrderLines_Ready AS ol
    LEFT JOIN dbo.vw_Products_Unique AS p ON ol.ProductID = p.ProductID
    LEFT JOIN OrderSummary AS o ON ol.OrderID = o.OrderID
),
Financials AS (
    SELECT *,
        CASE WHEN RevenueQualityStatus = 'OK'
             THEN CAST(QuantityClean * UnitPriceClean AS DECIMAL(22, 2))
             ELSE CAST(NULL AS DECIMAL(22, 2)) END AS GrossRevenue,
        CASE WHEN RevenueQualityStatus = 'OK'
             THEN CAST(QuantityClean * UnitPriceClean * (1 - DiscountRateClean)
                       AS DECIMAL(26, 6))
             ELSE CAST(NULL AS DECIMAL(26, 6)) END AS NetRevenue,
        CASE WHEN RevenueQualityStatus = 'OK' AND UnitCostClean IS NOT NULL
             THEN CAST(QuantityClean * UnitCostClean AS DECIMAL(22, 2))
             ELSE CAST(NULL AS DECIMAL(22, 2)) END AS TotalCost
    FROM JoinedSales
)
SELECT
    OrderLineID, OrderID, ProductID,
    QuantityClean, UnitPriceClean, DiscountRateClean,
    ProductName, Category, UnitCostClean,
    OrderDate, OrderStatus, NumberOfOrderRecords,
    RevenueQualityStatus,
    GrossRevenue, NetRevenue, TotalCost,
    CASE WHEN NetRevenue IS NOT NULL AND TotalCost IS NOT NULL
         THEN CAST(NetRevenue - TotalCost AS DECIMAL(26, 6))
         ELSE CAST(NULL AS DECIMAL(26, 6)) END AS GrossMargin
FROM Financials;
GO
