# Source data dictionary

The following fields come from the original **fictional RetailTraining workbook** used for the project.

| Staging table | Key fields used | Additional columns |
| --- | --- | --- |
| `dbo.OrderLines_staging` | `OrderLineID`, `OrderID`, `ProductID` | `Quantity`, `UnitPrice`, `DiscountPct` |
| `dbo.Products_staging` | `ProductID` | `ProductName`, `Category`, `UnitCost`, `ListPrice`, `Active` |
| `dbo.Orders` | `OrderID` | `OrderDate`, `CustomerID`, `OrderStatus`, `PaymentMethod`, `ShippingCountry` |

Expected grain: **one sales line** per `(OrderID, OrderLineID)` in the final fact view. Neither `OrderLineID` nor `OrderID` alone is guaranteed unique in the raw tables.

### Output view chain

1. `dbo.vw_OrderLines_Clean`: standardized IDs, parsed quantity and unit price; source columns kept.
2. `dbo.vw_OrderLines_Ready`: adds normalized discount fraction.
3. `dbo.vw_Products_Clean`: standardized IDs, category and direct unit cost.
4. `dbo.vw_Products_Unique`: one selected product record per `ProductID`; flags naming and unit-cost conflicts.
5. `dbo.vw_Sales_Analysis`: matches sales lines with summarized orders and unique products; flags revenue quality and derives revenue/cost/margin.
6. `dbo.vw_Sales_PowerBI`: final 18-column analytical view with `SalesLineKey`.

### Terms

- **GrossRevenue:** `QuantityClean * UnitPriceClean` before discounts, for eligible lines.
- **NetRevenue:** `GrossRevenue * (1 - DiscountRateClean)`, for eligible lines.
- **TotalCost:** `QuantityClean * UnitCostClean`; NULL where a valid cost is unavailable.
- **GrossMargin:** `NetRevenue - TotalCost` where both sides are usable.
- **MarginRatePct:** `100 * SUM(GrossMargin) / NULLIF(SUM(NetRevenue), 0)` — an aggregate gross margin *on sales*, not gross profit as a percentage of cost.
- **RevenueQualityStatus:** `OK`, `InvalidQuantity`, `NonPositiveQuantity`, `InvalidPrice`, `NegativePrice`, `MissingOrInvalidDiscount`, `OutOfRangeDiscount`, `Review100Pct`, or `MissingProduct`.
- **OrderDate:** may be NULL when invalid, missing or conflicting; ambiguous `dd/mm/yyyy` interpretation needs source confirmation.
