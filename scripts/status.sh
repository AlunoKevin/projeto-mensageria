#!/bin/bash

PROJETO="$HOME/projeto-mensageria"
NAMESPACE="mensageria"

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

echo
echo "=========================================="
echo "       STATUS DO SISTEMA"
echo "=========================================="
echo

# ============================================================
# KUBERNETES
# ============================================================

echo -e "${BLUE}KUBERNETES${NC}"
echo

if kubectl cluster-info >/dev/null 2>&1; then
    echo -e "${GREEN}Cluster: ONLINE${NC}"
else
    echo -e "${RED}Cluster: OFFLINE${NC}"
    echo
    exit 1
fi

echo

# ============================================================
# NODES
# ============================================================

echo -e "${BLUE}NODES${NC}"
echo

kubectl get nodes

echo

# ============================================================
# DEPLOYMENTS
# ============================================================

echo -e "${BLUE}DEPLOYMENTS${NC}"
echo

kubectl get deployments \
    -n "$NAMESPACE"

echo

# ============================================================
# PODS
# ============================================================

echo -e "${BLUE}PODS${NC}"
echo

kubectl get pods \
    -n "$NAMESPACE" \
    -o wide

echo

# ============================================================
# SERVICES
# ============================================================

echo -e "${BLUE}SERVICES${NC}"
echo

kubectl get services \
    -n "$NAMESPACE"

echo

# ============================================================
# RABBITMQ
# ============================================================

echo -e "${BLUE}RABBITMQ${NC}"
echo

RABBITMQ_POD=$(kubectl get pods \
    -n "$NAMESPACE" \
    -l app=rabbitmq \
    -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [ -n "$RABBITMQ_POD" ]; then

    echo -e "${GREEN}RabbitMQ: POD ENCONTRADO${NC}"
    echo "Pod: $RABBITMQ_POD"

else

    echo -e "${RED}RabbitMQ: NÃO ENCONTRADO${NC}"

fi

echo

# ============================================================
# API
# ============================================================

echo -e "${BLUE}API${NC}"
echo

API_PODS=$(kubectl get pods \
    -n "$NAMESPACE" \
    -l app=api \
    --no-headers 2>/dev/null | wc -l)

echo "Pods da API: $API_PODS"

echo

# ============================================================
# WORKER
# ============================================================

echo -e "${BLUE}WORKER${NC}"
echo

WORKER_PODS=$(kubectl get pods \
    -n "$NAMESPACE" \
    -l app=worker \
    --no-headers 2>/dev/null | wc -l)

echo "Pods do Worker: $WORKER_PODS"

echo

# ============================================================
# PRODUCER
# ============================================================

echo -e "${BLUE}PRODUCER${NC}"
echo

PRODUCER_REPLICAS=$(kubectl get deployment producer \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "0")

echo "Réplicas: $PRODUCER_REPLICAS"

echo

# ============================================================
# FILA
# ============================================================

echo -e "${BLUE}FILA${NC}"
echo

echo "Para consultar diretamente as métricas da fila,"
echo "utilize o Prometheus/Grafana."

echo

echo "=========================================="
echo "       FIM DO STATUS"
echo "=========================================="
echo
