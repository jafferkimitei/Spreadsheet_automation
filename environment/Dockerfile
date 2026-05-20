FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

RUN pip install --no-cache-dir pandas==2.2.3 openpyxl==3.1.5 pytest==8.3.4

# Anchor file — lets test.sh detect TASK_ROOT=/workspace correctly
COPY instruction.md /workspace/instruction.md

# Seed the broken starter and data files
COPY workspace/ /workspace/workspace/

WORKDIR /workspace

CMD ["/bin/bash"]