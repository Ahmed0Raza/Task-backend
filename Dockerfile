FROM python:3.12.3-slim

WORKDIR /fastapi

COPY requirements.txt .

RUN pip install --upgrade pip && \
    pip install -r requirements.txt

COPY . .
