#!/bin/bash

set -e

PROJETO="$HOME/projeto-mensageria"

echo
echo "=========================================="
echo "       BUILD DAS IMAGENS"
echo "=========================================="
echo

cd "$PROJETO"

echo "[1/3] Construindo imagem da API..."
docker build \
    -t speedowagon/mensageria-api:1.0 \
    ./api

echo
echo "[2/3] Construindo imagem do Worker..."
docker build \
    -t speedowagon/mensageria-worker:1.0 \
    ./worker

echo
echo "[3/3] Construindo imagem do Producer..."
docker build \
    -t speedowagon/mensageria-producer:1.0 \
    ./producer

echo
echo "=========================================="
echo "       BUILD CONCLUÍDO"
echo "=========================================="
echo

docker images | grep "speedowagon/mensageria"

echo
