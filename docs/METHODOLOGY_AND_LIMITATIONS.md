# Methodology, decisions and limitations

## 1. Preserve raw data

No cleaning script mutates the staging tables. Transformations are represented as SQL views, so questionable source values remain traceable.

## 2. Normalize with safeguards

- Numbers such as `€19,99`, `49,90`, `€720.00` and `1,299.00` are converted to decimal values.
- A **single separator followed by three digits** (`1.000`, `1,000`) is left NULL for review rather than automatically interpreted as either 1 or 1000. This is a deliberate conservative rule, not a universal locale parser.
- Known text quantities such as `one` and `two` are mapped to integers; unrecognized values become NULL.
- Discount percentages such as `5%` are divided by 100; decimal fractions such as `0.05` remain unchanged.
- Discounts outside the range [0, 1] are flagged. A 100% discount is flagged as `Review100Pct` for business confirmation, not assumed fraudulent.

## 3. Protect join grain

- `P010` exists twice in source product records, with different text representations for the name and unit cost. The unique products view selects a canonical name **for this training example** and checks whether costs conflict. It preserves exactly one row per product key.
- `L064` occurs in two different orders. Both rows are kept; composite `(OrderID, OrderLineID)` identifies sales-line grain.
- `Orders` includes duplicated order IDs. One summary row per order prevents multiplication of sales lines. Conflicting dates are left NULL; conflicting statuses are marked `Ambiguous`.

## 4. Explain how revenue eligibility is defined

`RevenueQualityStatus = 'OK'` requires a positive quantity, a non-negative valid unit price, a discount fraction in [0,1), and a matching product. Missing direct costs affect margin computation, not the eligibility of revenue itself. Order status is **not** used to exclude returned or cancelled orders because their financial treatment requires business decisions.

### Verified reference figures from the original workbook and earlier dashboard

- 68 total sales lines; 63 `OK`; five flagged (2 non-positive quantity, 2 out-of-range discount, 1 invalid quantity).
- Gross revenue of eligible lines: **10,851.15**.
- Net revenue of eligible lines: **10,712.9215**; displayed as **10,712.92**.
- Direct costs: **5,181.85**; gross margin: **5,531.0715**; margin rate about **51.63%**.
- Revenue without a valid reporting date: **1,299.00**.

These values were cross-checked independently against the original source workbook. **A match in your actual SQL Server still needs to be confirmed by executing the scripts.**

## 5. Date risks

The source mixes ISO dates, `dd/mm/yyyy`, `dd-mm-yyyy` and English month names. These scripts attempt explicitly documented formats. They do **not** try an automatic US `mm/dd/yyyy` fallback. Ambiguous values (for example `01/08/2025`) are interpreted provisionally as `dd/mm/yyyy`, consistent with the training exercise, but this assumption must be validated before using a monthly trend for decisions. Invalid dates such as `31/02/2025` become NULL.

## 6. Business risks

- The source includes returned/cancelled orders. Real recognized net revenue may differ after refunds, returns and status treatment.
- Currency is not independently verified. A currency symbol in some source cells is insufficient to certify every transaction as EUR.
- Gross margin here subtracts direct product cost only; shipping, marketing, payroll, overhead and tax are not included.
- The sample is small and time-limited, and cannot establish long-term demand or campaign ROI.

## 7. Verification after running

Inspect: row count (68), distinct composite sales-line keys (68), status counts, financial totals, products represented, null dates, duplicates and unmatched joins. If results differ, investigate the imported source and transformation rules rather than modifying the expected values to force a match.
