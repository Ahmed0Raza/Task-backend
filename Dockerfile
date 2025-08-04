FROM python:3.12.3-slim

WORKDIR /fastapi

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install -r requirements.txt

COPY . .

RUN alembic upgrade head || true

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
