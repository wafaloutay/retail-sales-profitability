/* RetailTraining | 02 / 04
   Read-only checks on normalized fields. Fix upstream rules, not the raw rows.
*/
USE RetailTraining;
GO

SELECT OrderLineID, OrderID, Quantity, QuantityClean,
       UnitPrice, UnitPriceClean, DiscountPct, DiscountRateClean
FROM dbo.vw_OrderLines_Ready
WHERE QuantityClean IS NULL OR QuantityClean <= 0
   OR UnitPriceClean IS NULL OR UnitPriceClean < 0
   OR DiscountRateClean IS NULL OR DiscountRateClean < 0 OR DiscountRateClean > 1
   OR DiscountRateClean = 1
ORDER BY OrderLineID;

-- Product master variants; don't silently overwrite conflicts.
SELECT ProductID, ProductName, Category, UnitCostClean,
       NumberOfProductRecords, ProductNameVariantCount,
       UnitCostVariantCount, CategoryVariantCount
FROM dbo.vw_Products_Unique
WHERE NumberOfProductRecords > 1
   OR ProductNameVariantCount > 1
   OR UnitCostVariantCount > 1
   OR CategoryVariantCount > 1
   OR UnitCostClean IS NULL;

-- Check for unrecognized products before the analytical joins.
SELECT ol.OrderID, ol.OrderLineID, ol.ProductID
FROM dbo.vw_OrderLines_Ready AS ol
LEFT JOIN dbo.vw_Products_Unique AS p ON ol.ProductID = p.ProductID
WHERE p.ProductID IS NULL;

-- Check composite key uniqueness: expected zero rows.
SELECT OrderID, OrderLineID, COUNT(*) AS NumberOfRecords
FROM dbo.vw_OrderLines_Ready
GROUP BY OrderID, OrderLineID
HAVING COUNT(*) > 1;
