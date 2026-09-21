from flask import Flask, request, jsonify, render_template_string
import pika
import os
import uuid
from datetime import datetime

app = Flask(__name__)

RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "rabbitmq")
QUEUE = os.getenv("QUEUE", "fila_teste")

HTML = """
<!DOCTYPE html>
<html lang="pt-BR">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <title>Sistema de Mensageria</title>

    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 600px;
            margin: 40px auto;
            padding: 20px;
        }

        h1 {
            text-align: center;
        }

        textarea {
            width: 100%;
            height: 150px;
            padding: 10px;
            box-sizing: border-box;
            resize: vertical;
        }

        button {
            width: 100%;
            padding: 15px;
            margin-top: 15px;
            font-size: 18px;
            cursor: pointer;
        }

        #resultado {
            margin-top: 20px;
            padding: 15px;
        }
    </style>
</head>

<body>

    <h1>Sistema de Mensageria</h1>

    <p>
        Digite uma mensagem para enviá-la ao sistema distribuído:
    </p>

    <textarea id="mensagem"
              placeholder="Digite sua mensagem..."></textarea>

    <button onclick="enviarMensagem()">
        ENVIAR MENSAGEM
    </button>

    <div id="resultado"></div>

    <script>
        async function enviarMensagem() {

            const campo = document.getElementById("mensagem");
            const resultado = document.getElementById("resultado");

            const mensagem = campo.value.trim();

            if (!mensagem) {
                resultado.innerText = "Digite uma mensagem.";
                return;
            }

            resultado.innerText = "Enviando...";

            try {

                const resposta = await fetch("/mensagem", {
                    method: "POST",

                    headers: {
                        "Content-Type": "application/json"
                    },

                    body: JSON.stringify({
                        mensagem: mensagem
                    })
                });

                const dados = await resposta.json();

                if (resposta.ok) {

                    resultado.innerText =
                        "Mensagem enviada com sucesso!";

                    campo.value = "";

                } else {

                    resultado.innerText =
                        "Erro: " + dados.erro;
                }

            } catch (erro) {

                resultado.innerText =
                    "Não foi possível conectar ao servidor.";
            }
        }
    </script>

</body>
</html>
"""


def publicar_mensagem(mensagem):

    connection = pika.BlockingConnection(
        pika.ConnectionParameters(
            host=RABBITMQ_HOST
        )
    )

    channel = connection.channel()

    channel.queue_declare(
        queue=QUEUE,
        durable=True
    )

    id_mensagem = str(uuid.uuid4())

    conteudo = (
        f"id={id_mensagem};"
        f"timestamp={datetime.now().isoformat()};"
        f"mensagem={mensagem}"
    )

    channel.basic_publish(
        exchange="",
        routing_key=QUEUE,
        body=conteudo,
        properties=pika.BasicProperties(
            delivery_mode=2
        )
    )

    connection.close()


@app.route("/", methods=["GET"])
def pagina():

    return render_template_string(HTML)


@app.route("/mensagem", methods=["POST"])
def receber_mensagem():

    dados = request.get_json()

    if not dados or "mensagem" not in dados:
        return jsonify({
            "erro": "Mensagem não informada."
        }), 400

    mensagem = dados["mensagem"].strip()

    if not mensagem:
        return jsonify({
            "erro": "Mensagem vazia."
        }), 400

    try:

        publicar_mensagem(mensagem)

        return jsonify({
            "status": "ok"
        })

    except Exception as erro:

        print(f"Erro ao publicar mensagem: {erro}")

        return jsonify({
            "erro": "Não foi possível enviar a mensagem."
        }), 500


if __name__ == "__main__":

    app.run(
        host="0.0.0.0",
        port=5000
    )
