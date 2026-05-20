#!/usr/bin/env bash
set -u

# Resolve task root across Harbor and local.
if [ -f "/workspace/instruction.md" ]; then
  TASK_ROOT="/workspace"
else
  TASK_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fi

# Application root is always task-root/workspace in this task.
APP_ROOT="$TASK_ROOT/workspace"
REPORT_SCRIPT="$APP_ROOT/reporting/build_report.py"

# Harbor may mount tests at /tests. Use them if present, else local tests dir.
if [ -f "/tests/test_workbook_outputs.py" ]; then
  TEST_ROOT="/tests"
else
  TEST_ROOT="$TASK_ROOT/tests"
fi

if mkdir -p /logs/verifier >/dev/null 2>&1 && [ -w /logs/verifier ]; then
  REWARD_FILE="/logs/verifier/reward.txt"
else
  mkdir -p "$TASK_ROOT/.logs/verifier"
  REWARD_FILE="$TASK_ROOT/.logs/verifier/reward.txt"
fi

rm -f "$REWARD_FILE"
rm -rf "$TASK_ROOT/output"

python "$REPORT_SCRIPT" > /tmp/finance_report_stdout.txt 2> /tmp/finance_report_stderr.txt
build_status=$?

if [ "$build_status" -ne 0 ]; then
  echo "Report generation failed before workbook verification."
  cat /tmp/finance_report_stderr.txt
fi

cd "$TEST_ROOT"
python -m pytest -q test_workbook_outputs.py
test_status=$?

if [ "$test_status" -eq 0 ]; then
  echo 1 > "$REWARD_FILE"
else
  echo 0 > "$REWARD_FILE"
fi

# Must always print pytest output to stdout: satisfied by direct pytest invocation above.
exit "$test_status"
