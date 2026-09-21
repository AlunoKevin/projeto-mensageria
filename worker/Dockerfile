FROM python:3.12-slim


WORKDIR /app

ENV PYTHONUNBUFFERED=1

RUN pip install pika

COPY worker.py .

CMD ["python", "worker.py"]
