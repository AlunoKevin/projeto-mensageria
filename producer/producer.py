import pika
import time
import os

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
QUEUE = os.getenv("QUEUE", "fila_teste")
RATE = float(os.getenv("RATE", "10"))

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host=RABBITMQ_HOST)
)

channel = connection.channel()

channel.queue_declare(
    queue=QUEUE,
    durable=True
)

print(f"Producer iniciado")
print(f"RabbitMQ: {RABBITMQ_HOST}")
print(f"Fila: {QUEUE}")
print(f"Taxa: {RATE} mensagens/s")

contador = 0

try:
    while True:
        mensagem = f"mensagem-{contador}"

        channel.basic_publish(
            exchange="",
            routing_key=QUEUE,
            body=mensagem
        )

        contador += 1

        if contador % 100 == 0:
            print(f"Enviadas: {contador}")

        time.sleep(1 / RATE)

except KeyboardInterrupt:
    print("Producer encerrado")

finally:
    connection.close()
