#!/bin/bash

set -e

# ============================================================
# CONFIGURAÇÃO
# ============================================================

PROJETO="$HOME/projeto-mensageria"

NAMESPACE="mensageria"

LOCAL_PORT=5000

SERVICE="svc/api"

PID_FILE="$PROJETO/scripts/.port-forward.pid"

QR_FILE="$PROJETO/scripts/qr-code.png"

VENV="$PROJETO/scripts/.venv"

# ============================================================
# CORES
# ============================================================

GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BLUE="\033[0;34m"
NC="\033[0m"

# ============================================================
# FUNÇÕES
# ============================================================

erro() {
    echo
    echo -e "${RED}ERRO: $1${NC}"
    echo
    exit 1
}

# ============================================================
# INÍCIO
# ============================================================

echo
echo "=========================================="
echo "       SISTEMA DE MENSAGERIA"
echo "       MODO APRESENTAÇÃO"
echo "=========================================="
echo

# ============================================================
# 1. VERIFICAR KUBERNETES
# ============================================================

echo -e "${BLUE}[1/7] Verificando Kubernetes...${NC}"

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
    erro "Namespace '$NAMESPACE' não existe."
fi

echo -e "${GREEN}Kubernetes OK.${NC}"

# ============================================================
# 2. RABBITMQ
# ============================================================

echo
echo -e "${BLUE}[2/7] Verificando RabbitMQ...${NC}"

RABBITMQ_REPLICAS=$(kubectl get deployment rabbitmq \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.replicas}')

if [ "$RABBITMQ_REPLICAS" != "1" ]; then

    echo "RabbitMQ está parado. Iniciando..."

    kubectl scale deployment rabbitmq \
        -n "$NAMESPACE" \
        --replicas=1
fi

kubectl rollout status deployment/rabbitmq \
    -n "$NAMESPACE" \
    --timeout=60s

echo -e "${GREEN}RabbitMQ OK.${NC}"

# ============================================================
# 3. API
# ============================================================

echo
echo -e "${BLUE}[3/7] Verificando API...${NC}"

API_REPLICAS=$(kubectl get deployment api \
    -n "$NAMESPACE" \
    -o jsonpath='{.spec.replicas}')

if [ "$API_REPLICAS" != "1" ]; then

    echo "API está parada. Iniciando..."

    kubectl scale deployment api \
        -n "$NAMESPACE" \
        --replicas=1
fi

kubectl rollout status deployment/api \
    -n "$NAMESPACE" \
    --timeout=60s

echo -e "${GREEN}API OK.${NC}"

# ============================================================
# 4. WORKER
# ============================================================

echo
echo -e "${BLUE}[4/7] Iniciando Worker...${NC}"

kubectl scale deployment worker \
    -n "$NAMESPACE" \
    --replicas=1

kubectl rollout status deployment/worker \
    -n "$NAMESPACE" \
    --timeout=60s

echo -e "${GREEN}Worker iniciado.${NC}"

# ============================================================
# 5. DESCOBRIR IP DA REDE
# ============================================================

echo
echo -e "${BLUE}[5/7] Descobrindo IP da rede local...${NC}"

IP_LOCAL=$(ip route get 1.1.1.1 2>/dev/null | \
    awk '{for(i=1;i<=NF;i++) if($i=="src") print $(i+1); exit}')

if [ -z "$IP_LOCAL" ]; then
    erro "Não foi possível descobrir o IP da máquina."
fi

URL="http://$IP_LOCAL:$LOCAL_PORT"

echo -e "${GREEN}IP encontrado: $IP_LOCAL${NC}"

# ============================================================
# 6. PORT-FORWARD
# ============================================================

echo
echo -e "${BLUE}[6/7] Iniciando acesso à API...${NC}"

# Encerrar port-forward anterior

if [ -f "$PID_FILE" ]; then

    PID=$(cat "$PID_FILE")

    if kill -0 "$PID" 2>/dev/null; then
        echo "Encerrando port-forward anterior..."
        kill "$PID" 2>/dev/null || true
        sleep 1
    fi

    rm -f "$PID_FILE"

fi

kubectl port-forward \
    --address 0.0.0.0 \
    -n "$NAMESPACE" \
    "$SERVICE" \
    "$LOCAL_PORT:$LOCAL_PORT" \
    > "$PROJETO/scripts/port-forward.log" 2>&1 &

PORT_FORWARD_PID=$!

echo "$PORT_FORWARD_PID" > "$PID_FILE"

echo "Port-forward iniciado."

# Esperar API

API_OK=false

for i in {1..15}; do

    if curl -s --max-time 1 "$URL" >/dev/null 2>&1; then
        API_OK=true
        break
    fi

    sleep 1

done

if [ "$API_OK" != "true" ]; then

    echo -e "${RED}A API não ficou acessível.${NC}"

    echo
    echo "Log do port-forward:"
    cat "$PROJETO/scripts/port-forward.log"

    exit 1
fi

echo -e "${GREEN}API acessível.${NC}"

# ============================================================
# 7. QR CODE
# ============================================================

echo
echo -e "${BLUE}[7/7] Gerando QR Code...${NC}"

if [ ! -d "$VENV" ]; then

    echo "Criando ambiente Python para QR Code..."

    python3 -m venv "$VENV"

    "$VENV/bin/pip" install --quiet qrcode[pil]

fi

"$VENV/bin/python" - "$URL" "$QR_FILE" <<'PYTHON'
import sys
import qrcode

url = sys.argv[1]
arquivo = sys.argv[2]

img = qrcode.make(url)

img.save(arquivo)

print(f"QR Code gerado: {arquivo}")
PYTHON

# ============================================================
# STATUS FINAL
# ============================================================

echo
echo "=========================================="
echo -e "${GREEN}       DEMONSTRAÇÃO PRONTA${NC}"
echo "=========================================="
echo

echo "Componentes:"
echo
echo "  RabbitMQ : ONLINE"
echo "  API      : ONLINE"
echo "  Worker   : ONLINE"
echo "  Producer : DESLIGADO"
echo

echo "URL para os celulares:"
echo
echo -e "${GREEN}  $URL${NC}"
echo

echo "QR Code:"
echo
echo "  $QR_FILE"
echo

echo "Port-forward PID: $PORT_FORWARD_PID"
echo
echo -e "${YELLOW}Mantenha este terminal aberto durante a apresentação.${NC}"
echo

echo "Para encerrar:"
echo
echo "  ./scripts/parar-demo.sh"
echo

echo "=========================================="
echo
