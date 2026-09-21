#!/bin/bash

PROJETO="$HOME/projeto-mensageria"

NAMESPACE="mensageria"

PID_FILE="$PROJETO/scripts/.port-forward.pid"

echo
echo "=========================================="
echo "       PARANDO DEMONSTRAÇÃO"
echo "=========================================="
echo

# ============================================================
# 1. PARAR PORT-FORWARD
# ============================================================

echo "[1/2] Encerrando acesso da API..."

if [ -f "$PID_FILE" ]; then

    PID=$(cat "$PID_FILE")

    if kill -0 "$PID" 2>/dev/null; then

        kill "$PID"

        echo "Port-forward encerrado."

    else

        echo "Port-forward já estava parado."

    fi

    rm -f "$PID_FILE"

else

    echo "Nenhum port-forward registrado."

fi

# ============================================================
# 2. PARAR WORKER
# ============================================================

echo
echo "[2/2] Parando Worker..."

kubectl scale deployment worker \
    -n "$NAMESPACE" \
    --replicas=0

echo "Worker parado."

echo
echo "=========================================="
echo "       DEMONSTRAÇÃO ENCERRADA"
echo "=========================================="
echo

echo "RabbitMQ continua funcionando."
echo "API continua funcionando."
echo "Producer continua parado."
echo "Worker foi parado."

echo
