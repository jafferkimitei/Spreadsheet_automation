#!/usr/bin/env bash
set -u

RUN_DIR="$(pwd -P)"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
SCRIPT_PARENT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

TASK_ROOT=""
APP_ROOT=""
REWARD_FILE=""
REPORT_SCRIPT=""

# Determine task root from multiple stable candidates.
candidates=("/workspace" "/app" "$RUN_DIR" "$SCRIPT_PARENT")
for candidate in "${candidates[@]}"; do
  [ -n "$candidate" ] || continue
  if [ -f "$candidate/environment/workspace/reporting/build_report.py" ] || \
     [ -f "$candidate/workspace/reporting/build_report.py" ] || \
     [ -f "$candidate/reporting/build_report.py" ]; then
    TASK_ROOT="$candidate"
    break
  fi
done

if [ -z "$TASK_ROOT" ]; then
  if [ "$SCRIPT_PARENT" != "/" ]; then
    TASK_ROOT="$SCRIPT_PARENT"
  elif [ "$RUN_DIR" != "/" ]; then
    TASK_ROOT="$RUN_DIR"
  else
    TASK_ROOT="/workspace"
  fi
fi

if [ -f "$TASK_ROOT/environment/workspace/reporting/build_report.py" ]; then
  APP_ROOT="$TASK_ROOT/environment/workspace"
  REPORT_SCRIPT="$APP_ROOT/reporting/build_report.py"
elif [ -f "$TASK_ROOT/workspace/reporting/build_report.py" ]; then
  APP_ROOT="$TASK_ROOT/workspace"
  REPORT_SCRIPT="$APP_ROOT/reporting/build_report.py"
elif [ -f "$TASK_ROOT/reporting/build_report.py" ]; then
  APP_ROOT="$TASK_ROOT"
  REPORT_SCRIPT="$APP_ROOT/reporting/build_report.py"
else
  APP_ROOT="$TASK_ROOT/environment/workspace"
  REPORT_SCRIPT="$APP_ROOT/reporting/build_report.py"
  echo "Could not locate build_report.py at expected paths."
  echo "Probed task-root candidates: ${candidates[*]}"
  echo "Checked: $TASK_ROOT/environment/workspace/reporting/build_report.py"
  echo "Checked: $TASK_ROOT/workspace/reporting/build_report.py"
  echo "Checked: $TASK_ROOT/reporting/build_report.py"
fi

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
rm -rf "$TASK_ROOT/output" "$APP_ROOT/output"

export TASK_ROOT_FOR_TESTS="$TASK_ROOT"

echo "TASK_ROOT=$TASK_ROOT"
echo "APP_ROOT=$APP_ROOT"
echo "TEST_ROOT=$TEST_ROOT"

if [ -f "$REPORT_SCRIPT" ]; then
  python "$REPORT_SCRIPT" > /tmp/finance_report_stdout.txt 2> /tmp/finance_report_stderr.txt
  build_status=$?
else
  build_status=1
  echo "Report generation failed before workbook verification."
  echo "python: can't open file '$REPORT_SCRIPT': [Errno 2] No such file or directory" > /tmp/finance_report_stderr.txt
fi

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

exit "$test_status"
