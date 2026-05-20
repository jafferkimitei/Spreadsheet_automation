# Finance Reporting Workbook Repair

Terminal-Bench task scaffold for a spreadsheet automation / finance operations workflow.

The starter CLI generates an incomplete and inaccurate Excel workbook from messy CSV exports. The oracle repairs the reporting pipeline so the verifier passes.

Required files included:
- instruction.md
- task.toml
- environment/Dockerfile
- solution/solve.sh
- tests/test.sh
- tests/test_workbook_outputs.py

Expected validation behavior:
- NOP/pre-apply: tests fail and /logs/verifier/reward.txt is 0
- Oracle/post-apply: tests pass and /logs/verifier/reward.txt is 1
# Spreadsheet_automation
