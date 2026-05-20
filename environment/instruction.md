# Finance Reporting Workbook Repair

This repository is used by the finance operations team to produce a month-end Excel report book based on raw CSV exports. This is already being done, although the process currently produces an incomplete workbook, with some business metrics calculated incorrectly.

Please fix the workflow for producing the report so that invoking the report command produces a complete Excel workbook as follows:

`/workspace/output/finance_report.xlsx`

The workbook must include these sheets:

- Raw Cleaned Data
- Regional Summary
- Product Summary
- Risk Metrics
- Validation Checks

The pipeline must perform source data cleaning, map the right regions to the respective countries, remove reversed transactions from the business total, compute revenues and margins properly, deal with missing risk factors, and format the workbook such that it can be easily read by finance reviewers.

In addition to producing correct per-sheet values, the workbook should be internally consistent across sheets. For example, transaction counts in summary sheets should reconcile back to the cleaned detail rows, and approved revenue totals should align between summaries and validation checks.

## Expected workbook schema

The generated workbook should use a consistent tabular structure for every worksheet.

### Raw Cleaned Data

This sheet should contain one row per included transaction after cleaning and filtering. Reversed transactions should not appear in this sheet.

Each `transaction_id` should appear at most once in this cleaned output.

Required columns:

- `transaction_id` — transaction identifier as text
- `date` — transaction date
- `country` — source country name
- `product` — product category
- `revenue_usd` — numeric revenue amount in USD
- `cost_usd` — numeric cost amount in USD
- `credit_risk_ratio` — numeric credit risk ratio; missing values should remain blank instead of being converted to zero
- `restructured_portfolio_ratio` — numeric restructured portfolio ratio; missing values should remain blank instead of being converted to zero
- `status` — transaction status
- `world_bank_region` — reporting region mapped from the country
- `revenue_kes` — numeric revenue converted from USD to KES
- `cost_kes` — numeric cost converted from USD to KES
- `gross_profit_usd` — revenue minus cost in USD
- `margin_pct` — gross profit divided by revenue

### Regional Summary

This sheet should contain one row per reporting region.

Required columns:

- `world_bank_region` — reporting region name
- `transaction_count` — number of included transactions in the region
- `revenue_usd` — total included revenue in USD
- `cost_usd` — total included cost in USD
- `gross_profit_usd` — total revenue minus total cost in USD
- `margin_pct` — gross profit divided by revenue
- `revenue_kes` — total included revenue converted to KES
- `cost_kes` — total included cost converted to KES

### Product Summary

This sheet should contain one row per product category.

Required columns:

- `product` — product category
- `transaction_count` — number of included transactions for the product
- `revenue_usd` — total included revenue in USD
- `cost_usd` — total included cost in USD
- `gross_profit_usd` — total revenue minus total cost in USD
- `margin_pct` — gross profit divided by revenue
- `revenue_kes` — total included revenue converted to KES
- `cost_kes` — total included cost converted to KES

### Risk Metrics

This sheet should contain one row per reporting region.

Required columns:

- `world_bank_region` — reporting region name
- `avg_credit_risk_ratio` — average credit risk ratio for included transactions, ignoring blank values
- `avg_restructured_portfolio_ratio` — average restructured portfolio ratio for included transactions, ignoring blank values

### Validation Checks

This sheet should contain name/value control checks that make the workbook auditable.

Required columns:

- `check_name` — validation metric name
- `value` — validation metric value

At least, include the validation rows for the number of source rows, the number of rows with cleaned data, the number of reversed transactions that were excluded, total revenue approved in US dollars, and total revenue approved in Kenyan Shillings.

## Formatting expectations

The first row of each worksheet must be a header row and must be well-formatted. Header cells must be visually appealing, bold, and readable. No need to use advanced formatting; readability is key.

The test runner uses system-wide Python dependencies installed in the Docker image.

You may change the report code and supporting project files if needed. Do not modify the tests or hardcode verifier results.
