FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

WORKDIR /workspace

RUN pip install --no-cache-dir pandas==2.2.3 openpyxl==3.1.5 pytest==8.3.4

CMD ["/bin/bash"]
