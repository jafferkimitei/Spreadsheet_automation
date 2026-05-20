#!/usr/bin/env python3

"""Starter implementation (intentionally incomplete)."""

from pathlib import Path

import pandas as pd


def build_report() -> None:
    app_root = Path(__file__).resolve().parents[1]
    task_root = app_root.parent
    data_path = app_root / "data" / "transactions.csv"
    output_path = task_root / "output" / "finance_report.xlsx"

    df = pd.read_csv(data_path)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Intentionally incorrect baseline: only one raw sheet.
    with pd.ExcelWriter(output_path, engine="openpyxl") as writer:
        df.to_excel(writer, sheet_name="Raw Data", index=False)


if __name__ == "__main__":
    build_report()