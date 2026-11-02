# Retail Sales & Profitability Analysis

**SQL Server · Power Query · Power BI · DAX**  
*A guided data analytics case study using a fictional retail dataset.*

## Project question

**Which products drive revenue and margin, and how much can we trust the underlying sales data?**

I worked through a retail dataset containing mixed numeric formats, reused identifiers, duplicate product records and invalid quantities/discounts. The goal was to prepare analysis-ready SQL views, check their quality, and create a three-page Power BI report.

### Results observed in the training project

| KPI | Observed value |
| --- | ---: |
| Source sales lines | 68 |
| Lines eligible for the selected revenue calculation | 63 |
| Lines flagged for review | 5 |
| Gross revenue on eligible lines | 10,851.15 |
| Net revenue on eligible lines | 10,712.9215 |
| Direct product costs on eligible lines | 5,181.85 |
| Gross margin on eligible lines | 5,531.0715 |
| Gross margin as % of net revenue | 51.63% |
| Net revenue not assigned to a reporting month | 1,299.00 |

**Important:** These are *reference checks* from the training dataset, not live SQL execution results from this repository. Currency is intentionally not asserted: the source uses mixed symbols but does not document a confirmed transaction currency. The reported margin is **not** company net profit. Returned/cancelled orders have not been independently reconciled.

## Repository structure

```text
retail-sales-profitability/
├── README.md
├── .gitignore
├── data/
│   └── retail_training_dirty_source.xlsx
├── sql/
│   ├── 01_exploration/
│   │   ├── 01_source_inventory.sql
│   │   ├── 02_duplicates_and_keys.sql
│   │   └── 03_raw_quality_checks.sql
│   ├── 02_cleaning_validation/
│   │   ├── 01_amount_parser.sql
│   │   ├── 02_order_lines_views.sql
│   │   ├── 03_products_views.sql
│   │   └── 04_cleaning_validation_checks.sql
│   └── 03_metrics/
│       ├── 01_sales_analysis_view.sql
│       ├── 02_powerbi_view.sql
│       ├── 03_kpi_and_profitability.sql
│       └── 04_reconciliation_checks.sql
└── docs/
    ├── DATA_DICTIONARY.md
    └── METHODOLOGY_AND_LIMITATIONS.md
```

## Source data and prerequisites

- **Database:** `RetailTraining` on Microsoft SQL Server (T-SQL).
- **Expected staging tables:** `dbo.OrderLines_staging`, `dbo.Products_staging` and `dbo.Orders`.
- **Expected source columns:** see [data dictionary](docs/DATA_DICTIONARY.md).
- The fictional training workbook is included in `data/retail_training_dirty_source.xlsx` for reproducibility. Import its `Raw_OrderLines`, `Raw_Products`, and `Raw_Orders` worksheets into the three expected staging tables in SSMS before running the SQL scripts. The workbook contains synthetic training customer records; no real customer data is intended. No import credentials or server connections are included.
- Run the SQL in **SSMS**, connected to your own `RetailTraining` database.

> These scripts are a **documented reconstruction** of the workflow practiced in the project, using the original training workbook and the validated outcomes. They were not exported verbatim from the original SSMS query tabs, and have **not been executed against your SQL Server instance**. Review and test them locally before presenting them as the final executed code.

## Run order

1. Run the files in `sql/01_exploration/` to inspect the source without modifying it.
2. Run `sql/02_cleaning_validation/01_amount_parser.sql` to create the numerical conversion helper.
3. Run `02_order_lines_views.sql` and `03_products_views.sql` to create the cleaned SQL views.
4. Run `04_cleaning_validation_checks.sql` to review parsing issues and duplicate keys.
5. Run `sql/03_metrics/01_sales_analysis_view.sql` and then `02_powerbi_view.sql`.
6. Run `03_kpi_and_profitability.sql` and **`04_reconciliation_checks.sql`**. Check the numbers and investigate any deviation.
7. In Power BI, import `dbo.vw_Sales_PowerBI` as the report fact table. A separate calendar (`DimDate`) can be used for time-based reporting.

The scripts use `CREATE OR ALTER VIEW` and do **not** delete, UPDATE or overwrite original staging records.

## Examples of issues uncovered

- **P010:** two product rows, with variants of the product name and cost formatting. Matching these rows naively in a join would double related sales records. The unique product view documents the chosen label and detects cost conflicts.
- **L064:** `OrderLineID` is reused by orders `O1001` and `O1002`; these are distinct transactions, not duplicate rows. `SalesLineKey = OrderID + '-' + OrderLineID` distinguishes them.
- **Order duplicates:** identical or conflicting `OrderID` records exist. The sales analysis aggregates the orders to *one row per OrderID before joining*, records the duplicate count, and preserves ambiguous statuses/dates as unresolved.
- **Revenue quality:** 63 eligible, 2 non-positive quantities, 2 out-of-range discounts and 1 invalid quantity. A 100% discount is marked for review rather than automatically corrected.

## Business interpretation

The **Monitor 27 inch** generated approximately 60% of eligible net revenue but only five units sold in the sample. Its contribution is notable, but that alone is not evidence that a larger marketing investment would be profitable. Returns, history, inventory, true currency and campaign costs would need checking first.

## Portfolio

Add your public Notion project link here after publication. The Power BI report contains three pages: **Sales Overview**, **Product Profitability** and **Data Quality**.

## Transparency

This is an educational project completed with step-by-step guidance. The scripts below reproduce the documented approach; they are not represented as independently validated production code. Source dates are particularly ambiguous (such as `01/08/2025`), and this repository does not attempt to resolve them through guesswork. See [Methodology and Limitations](docs/METHODOLOGY_AND_LIMITATIONS.md).
