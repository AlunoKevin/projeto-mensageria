import pika
import time
import os

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
QUEUE = os.getenv("QUEUE", "fila_teste")
PROCESS_TIME = float(os.getenv("PROCESS_TIME", "0.05"))

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host=RABBITMQ_HOST)
)

channel = connection.channel()

channel.queue_declare(
    queue=QUEUE,
    durable=True
)

print("Worker iniciado")
print(f"RabbitMQ: {RABBITMQ_HOST}")
print(f"Fila: {QUEUE}")
print(f"Tempo de processamento: {PROCESS_TIME}s")


def processar_mensagem(ch, method, properties, body):

    print(f"Recebida: {body.decode()}")

    time.sleep(PROCESS_TIME)

    ch.basic_ack(
        delivery_tag=method.delivery_tag
    )


channel.basic_qos(
    prefetch_count=1
)

channel.basic_consume(
    queue=QUEUE,
    on_message_callback=processar_mensagem
)

print("Aguardando mensagens...")

try:
    channel.start_consuming()

except KeyboardInterrupt:
    print("Worker encerrado")
    connection.close()
