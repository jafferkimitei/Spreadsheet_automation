#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(pwd -P)"

if [ -f "$RUN_DIR/environment/workspace/reporting/build_report.py" ]; then
  TASK_ROOT="$RUN_DIR"
  APP_ROOT="$RUN_DIR/environment/workspace"
elif [ -f "$RUN_DIR/workspace/reporting/build_report.py" ]; then
  TASK_ROOT="$RUN_DIR"
  APP_ROOT="$RUN_DIR/workspace"
elif [ -f "/workspace/environment/workspace/reporting/build_report.py" ]; then
  TASK_ROOT="/workspace"
  APP_ROOT="/workspace/environment/workspace"
elif [ -f "/workspace/workspace/reporting/build_report.py" ]; then
  TASK_ROOT="/workspace"
  APP_ROOT="/workspace/workspace"
elif [ -f "/app/workspace/reporting/build_report.py" ]; then
  TASK_ROOT="/app"
  APP_ROOT="/app/workspace"
else
  echo "Could not locate build_report.py in expected app roots"
  echo "Current directory: $RUN_DIR"
  find /workspace /app /tmp "$RUN_DIR" -maxdepth 6 -path "*/workspace/reporting/build_report.py" 2>/dev/null || true
  exit 1
fi

TARGET="$APP_ROOT/reporting/build_report.py"

cat > "$TARGET" <<'PY'

#!/usr/bin/env python3

from pathlib import Path

import pandas as pd
from openpyxl.styles import Alignment, Font, PatternFill
from openpyxl.utils import get_column_letter


APP_ROOT = Path(__file__).resolve().parents[1]
if APP_ROOT.name == "workspace" and APP_ROOT.parent.name == "environment":
    TASK_ROOT = APP_ROOT.parent.parent
else:
    TASK_ROOT = APP_ROOT.parent
DATA_DIR = APP_ROOT / "data"
OUTPUT_PATH = TASK_ROOT / "output" / "finance_report.xlsx"


def format_sheet(ws):
    header_fill = PatternFill(fill_type="solid", fgColor="D9EAF7")
    header_font = Font(bold=True)
    header_alignment = Alignment(horizontal="center")

    for cell in ws[1]:
        cell.fill = header_fill
        cell.font = header_font
        cell.alignment = header_alignment

    for column_cells in ws.columns:
        max_length = 0
        column_letter = get_column_letter(column_cells[0].column)
        for cell in column_cells:
            if cell.value is not None:
                max_length = max(max_length, len(str(cell.value)))
        ws.column_dimensions[column_letter].width = min(max_length + 2, 40)


def build_report() -> None:
    transactions = pd.read_csv(DATA_DIR / "transactions.csv")
    region_mapping = pd.read_csv(DATA_DIR / "region_mapping.csv")
    exchange_rates = pd.read_csv(DATA_DIR / "exchange_rates.csv")

    usd_rate = float(
        exchange_rates.loc[
            exchange_rates["currency"].astype(str).str.upper() == "USD",
            "rate_to_kes",
        ].iloc[0]
    )

    merged = transactions.merge(region_mapping, on="country", how="left")
    clean = merged[merged["status"].astype(str).str.lower() != "reversed"].copy()

    clean["revenue_kes"] = clean["revenue_usd"] * usd_rate
    clean["cost_kes"] = clean["cost_usd"] * usd_rate
    clean["gross_profit_usd"] = clean["revenue_usd"] - clean["cost_usd"]
    clean["margin_pct"] = clean["gross_profit_usd"] / clean["revenue_usd"]

    raw_cleaned = clean[
        [
            "transaction_id",
            "date",
            "country",
            "product",
            "revenue_usd",
            "cost_usd",
            "credit_risk_ratio",
            "restructured_portfolio_ratio",
            "status",
            "world_bank_region",
            "revenue_kes",
            "cost_kes",
            "gross_profit_usd",
            "margin_pct",
        ]
    ].copy()

    regional_summary = (
        clean.groupby("world_bank_region", as_index=False)
        .agg(
            transaction_count=("transaction_id", "count"),
            revenue_usd=("revenue_usd", "sum"),
            cost_usd=("cost_usd", "sum"),
            revenue_kes=("revenue_kes", "sum"),
            cost_kes=("cost_kes", "sum"),
        )
    )
    regional_summary["gross_profit_usd"] = (
        regional_summary["revenue_usd"] - regional_summary["cost_usd"]
    )
    regional_summary["margin_pct"] = (
        regional_summary["gross_profit_usd"] / regional_summary["revenue_usd"]
    )
    regional_summary = regional_summary[
        [
            "world_bank_region",
            "transaction_count",
            "revenue_usd",
            "cost_usd",
            "gross_profit_usd",
            "margin_pct",
            "revenue_kes",
            "cost_kes",
        ]
    ]

    product_summary = (
        clean.groupby("product", as_index=False)
        .agg(
            transaction_count=("transaction_id", "count"),
            revenue_usd=("revenue_usd", "sum"),
            cost_usd=("cost_usd", "sum"),
            revenue_kes=("revenue_kes", "sum"),
            cost_kes=("cost_kes", "sum"),
        )
    )
    product_summary["gross_profit_usd"] = (
        product_summary["revenue_usd"] - product_summary["cost_usd"]
    )
    product_summary["margin_pct"] = (
        product_summary["gross_profit_usd"] / product_summary["revenue_usd"]
    )
    product_summary = product_summary[
        [
            "product",
            "transaction_count",
            "revenue_usd",
            "cost_usd",
            "gross_profit_usd",
            "margin_pct",
            "revenue_kes",
            "cost_kes",
        ]
    ]

    risk_metrics = (
        clean.groupby("world_bank_region", as_index=False)
        .agg(
            avg_credit_risk_ratio=("credit_risk_ratio", "mean"),
            avg_restructured_portfolio_ratio=(
                "restructured_portfolio_ratio",
                "mean",
            ),
        )
    )

    validation_checks = pd.DataFrame(
        [
            {"check_name": "source_row_count", "value": len(transactions)},
            {"check_name": "clean_row_count", "value": len(clean)},
            {
                "check_name": "excluded_reversed_count",
                "value": int(
                    (transactions["status"].astype(str).str.lower() == "reversed").sum()
                ),
            },
            {
                "check_name": "approved_revenue_usd_total",
                "value": float(clean["revenue_usd"].sum()),
            },
            {
                "check_name": "approved_revenue_kes_total",
                "value": float(clean["revenue_kes"].sum()),
            },
        ]
    )

    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)

    with pd.ExcelWriter(OUTPUT_PATH, engine="openpyxl") as writer:
        raw_cleaned.to_excel(writer, sheet_name="Raw Cleaned Data", index=False)
        regional_summary.to_excel(writer, sheet_name="Regional Summary", index=False)
        product_summary.to_excel(writer, sheet_name="Product Summary", index=False)
        risk_metrics.to_excel(writer, sheet_name="Risk Metrics", index=False)
        validation_checks.to_excel(writer, sheet_name="Validation Checks", index=False)

        for worksheet in writer.book.worksheets:
            format_sheet(worksheet)


if __name__ == "__main__":
    build_report()
PY

chmod +x "$TARGET"
