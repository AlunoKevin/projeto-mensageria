FROM python:3.12-slim

WORKDIR /app

RUN pip install pika

COPY producer.py .

CMD ["python", "producer.py"]
