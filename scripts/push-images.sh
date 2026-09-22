#!/bin/bash

set -e

echo
echo "=========================================="
echo "       PUSH PARA DOCKER HUB"
echo "=========================================="
echo

echo "[1/3] Enviando API..."

docker push speedowagon/mensageria-api:1.0

echo
echo "[2/3] Enviando Worker..."

docker push speedowagon/mensageria-worker:1.0

echo
echo "[3/3] Enviando Producer..."

docker push speedowagon/mensageria-producer:1.0

echo
echo "=========================================="
echo "       PUSH CONCLUÍDO"
echo "=========================================="
echo
