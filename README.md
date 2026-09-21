# Sistema Distribuído de Mensageria e Monitoramento

Projeto desenvolvido para a disciplina de Sistemas Distribuídos com o objetivo de estudar o comportamento de um sistema de mensageria distribuído sob diferentes cargas e observar como esse comportamento é representado por ferramentas de monitoramento.

O sistema utiliza **RabbitMQ** como sistema de mensageria, **Kubernetes** para gerenciamento dos componentes e **Prometheus + Grafana** para monitoramento.

Além dos testes automatizados de carga, o projeto possui uma interface web que permite que usuários enviem mensagens através de celulares durante uma demonstração.

---

## 1. Arquitetura

A arquitetura atual do sistema é:

```text
                    ┌──────────────┐
                    │   Celular    │
                    │   Navegador  │
                    └──────┬───────┘
                           │ HTTP
                           ▼
                    ┌──────────────┐
                    │     API      │
                    │    Flask     │
                    └──────┬───────┘
                           │
                           │ AMQP
                           ▼
                    ┌──────────────┐
                    │   RabbitMQ   │
                    │    Fila      │
                    └──────┬───────┘
                           │
                           │
                           ▼
                    ┌──────────────┐
                    │    Worker    │
                    │ Processamento│
                    └──────────────┘


              ┌───────────────────────────┐
              │                           │
              │        Prometheus         │
              │       Monitoramento       │
              │                           │
              └─────────────┬─────────────┘
                            │
                            ▼
                    ┌──────────────┐
                    │   Grafana    │
                    │ Visualização │
                    └──────────────┘
```

O **Producer** também pode ser utilizado para gerar carga automaticamente:

```text
Producer
   │
   │ mensagens
   ▼
RabbitMQ
   │
   ▼
Worker
```

Durante a demonstração pelo celular, o Producer pode permanecer desligado para que as mensagens sejam geradas diretamente pelos participantes.

---

# 2. Tecnologias utilizadas

* Python
* Flask
* Pika
* RabbitMQ
* Kubernetes
* Minikube
* Prometheus
* Grafana
* Helm
* Docker
* Bash

---

# 3. Pré-requisitos

Para executar o projeto localmente, é necessário possuir:

* Docker
* kubectl
* Minikube
* Helm
* Python 3
* Git

Verifique as instalações:

```bash
docker --version
kubectl version --client
minikube version
helm version
python3 --version
git --version
```

---

# 4. Clonando o projeto

Clone o repositório:

```bash
git clone <URL_DO_REPOSITORIO>
cd projeto-mensageria
```

---

# 5. Iniciando o Kubernetes

Inicie o Minikube:

```bash
minikube start
```

Verifique o estado do cluster:

```bash
minikube status
```

O nó do Minikube deve estar com estado `Ready`.

Também é possível verificar:

```bash
kubectl get nodes
```

---

# 6. Criando o namespace

O projeto utiliza o namespace `mensageria`.

Crie-o através do manifesto:

```bash
kubectl apply -f kubernetes/namespace.yaml
```

Verifique:

```bash
kubectl get namespaces
```

---

# 7. Construindo as imagens

As imagens utilizadas pelo projeto são:

```text
mensageria-api
mensageria-worker
mensageria-producer
```

No ambiente local com Minikube, as imagens podem ser construídas diretamente dentro do ambiente do Minikube.

### API

```bash
cd api
minikube image build -t mensageria-api:1.0 .
cd ..
```

### Worker

```bash
cd worker
minikube image build -t mensageria-worker:1.0 .
cd ..
```

### Producer

```bash
cd producer
minikube image build -t mensageria-producer:1.0 .
cd ..
```

Verifique as imagens:

```bash
minikube image ls
```

---

# 8. Instalando RabbitMQ

Aplique o manifesto:

```bash
kubectl apply -f kubernetes/rabbitmq.yaml
```

Verifique o Pod:

```bash
kubectl get pods -n mensageria
```

Aguarde até que o RabbitMQ esteja `Running`.

Também é possível verificar o Deployment:

```bash
kubectl get deployment -n mensageria
```

---

# 9. Instalando a API

Aplique:

```bash
kubectl apply -f kubernetes/api.yaml
```

Verifique:

```bash
kubectl get pods -n mensageria
```

A API utiliza a porta `5000`.

---

# 10. Instalando o Worker

Aplique:

```bash
kubectl apply -f kubernetes/worker.yaml
```

Verifique:

```bash
kubectl get pods -n mensageria
```

Para visualizar os logs:

```bash
kubectl logs -n mensageria deployment/worker
```

O Worker deve apresentar uma mensagem semelhante a:

```text
Worker iniciado
RabbitMQ: rabbitmq
Fila: fila_teste
Tempo de processamento: 0.05s
Aguardando mensagens...
```

---

# 11. Instalando o Producer

O Producer é utilizado para gerar carga automaticamente.

```bash
kubectl apply -f kubernetes/producer.yaml
```

Verifique:

```bash
kubectl get pods -n mensageria
```

Os logs podem ser visualizados com:

```bash
kubectl logs -n mensageria deployment/producer
```

O Producer envia mensagens continuamente de acordo com a taxa configurada na variável `RATE`.

---

# 12. Verificando o sistema

Para visualizar todos os componentes:

```bash
kubectl get all -n mensageria
```

O resultado deve apresentar os componentes:

```text
rabbitmq
api
worker
producer
```

---

# 13. Acesso à API

Para acessar a API através da própria máquina:

```bash
kubectl port-forward \
    --address 0.0.0.0 \
    -n mensageria \
    svc/api \
    5000:5000
```

Depois acesse:

```text
http://localhost:5000
```

---

# 14. Demonstração pelo celular

O projeto possui um script que automatiza a preparação da demonstração.

Execute:

```bash
./scripts/iniciar-demo.sh
```

O script:

1. verifica o Kubernetes;
2. inicia o RabbitMQ caso esteja parado;
3. inicia a API;
4. inicia um Worker;
5. identifica o endereço IP da máquina;
6. cria o `port-forward`;
7. verifica se a API está acessível;
8. gera automaticamente um QR Code.

Ao final será exibido algo semelhante a:

```text
==========================================
       DEMONSTRAÇÃO PRONTA
==========================================

Componentes:

  RabbitMQ : ONLINE
  API      : ONLINE
  Worker   : ONLINE
  Producer : DESLIGADO

URL para os celulares:

  http://192.168.X.X:5000
```

O QR Code estará disponível em:

```text
scripts/qr-code.png
```

Os participantes podem escanear o QR Code utilizando seus celulares.

Cada mensagem enviada seguirá o caminho:

```text
Celular
   ↓
API
   ↓
RabbitMQ
   ↓
Worker
```

---

# 15. Encerrando a demonstração

Para encerrar o modo de demonstração:

```bash
./scripts/parar-demo.sh
```

Esse script:

* encerra o `port-forward`;
* para o Worker;
* mantém o RabbitMQ funcionando;
* mantém a API funcionando;
* mantém o Producer desligado.

Assim, a infraestrutura principal continua disponível para uma nova demonstração.

---

# 16. Iniciando novamente a demonstração

Depois de executar:

```bash
./scripts/parar-demo.sh
```

basta executar novamente:

```bash
./scripts/iniciar-demo.sh
```

O script iniciará novamente o Worker e recriará o acesso à API.

---

# 17. Prometheus

O monitoramento utiliza o `kube-prometheus-stack`.

Adicione o repositório:

```bash
helm repo add prometheus-community \
    https://prometheus-community.github.io/helm-charts
```

Atualize:

```bash
helm repo update
```

Instale:

```bash
helm install monitoring \
    prometheus-community/kube-prometheus-stack \
    -n monitoramento \
    --create-namespace
```

Verifique:

```bash
kubectl get pods -n monitoramento
```

---

# 18. Monitoramento do RabbitMQ

O RabbitMQ possui o plugin Prometheus habilitado.

O projeto utiliza um `ServiceMonitor` para permitir que o Prometheus colete as métricas do RabbitMQ.

Aplique:

```bash
kubectl apply \
    -f kubernetes/monitoring/rabbitmq-servicemonitor.yaml
```

Verifique:

```bash
kubectl get servicemonitor -n monitoramento
```

O target do RabbitMQ pode ser verificado na interface do Prometheus.

---

# 19. Acessando o Prometheus

Execute:

```bash
kubectl port-forward \
    -n monitoramento \
    svc/monitoring-kube-prometheus-prometheus \
    9090:9090
```

Acesse:

```text
http://localhost:9090
```

Uma métrica importante para observar é:

```promql
rabbitmq_queue_messages_ready
```

Ela representa a quantidade de mensagens prontas na fila.

Outras métricas úteis incluem:

```promql
rabbitmq_queue_messages
```

```promql
rabbitmq_queue_messages_unacked
```

```promql
rabbitmq_queue_consumers
```

```promql
rabbitmq_queue_messages_published_total
```

```promql
rabbitmq_queue_messages_acked_total
```

---

# 20. Acessando o Grafana

Execute:

```bash
kubectl port-forward \
    -n monitoramento \
    svc/monitoring-grafana \
    3000:80
```

Acesse:

```text
http://localhost:3000
```

O usuário padrão é:

```text
admin
```

A senha pode ser obtida através de:

```bash
kubectl get secret \
    -n monitoramento \
    monitoring-grafana \
    -o jsonpath="{.data.admin-password}" | base64 -d
```

---

# 21. Testes de carga

O objetivo do projeto é observar o comportamento do sistema e do monitoramento sob diferentes condições.

Alguns experimentos previstos são:

### Carga baixa

Executar o Producer com uma taxa pequena de mensagens.

Por exemplo:

```text
RATE=10
```

### Aumento gradual

Aumentar progressivamente a taxa:

```text
10 mensagens/s
50 mensagens/s
100 mensagens/s
500 mensagens/s
```

### Burst

Gerar uma grande quantidade de mensagens em um intervalo curto.

### Poucos consumidores

Executar apenas um Worker e aumentar a quantidade de mensagens produzidas.

Nesse cenário, a fila pode começar a acumular mensagens.

### Aumento de consumidores

Aumentar o número de Workers:

```bash
kubectl scale deployment worker \
    -n mensageria \
    --replicas=2
```

Depois:

```bash
kubectl scale deployment worker \
    -n mensageria \
    --replicas=3
```

É possível acompanhar o comportamento da fila no Prometheus e no Grafana.

---

# 22. Parando o Producer

Para interromper a geração automática de mensagens:

```bash
kubectl scale deployment producer \
    -n mensageria \
    --replicas=0
```

Para iniciar novamente:

```bash
kubectl scale deployment producer \
    -n mensageria \
    --replicas=1
```

---

# 23. Parando os Workers

Para parar todos os Workers:

```bash
kubectl scale deployment worker \
    -n mensageria \
    --replicas=0
```

Para iniciar um Worker:

```bash
kubectl scale deployment worker \
    -n mensageria \
    --replicas=1
```

Também é possível utilizar múltiplos Workers:

```bash
kubectl scale deployment worker \
    -n mensageria \
    --replicas=3
```

---

# 24. Verificando o estado do sistema

```bash
kubectl get pods -n mensageria
```

ou:

```bash
kubectl get all -n mensageria
```

Para verificar especificamente a quantidade de réplicas:

```bash
kubectl get deployment -n mensageria
```

---

# 25. Limpando a fila

Caso seja necessário remover todas as mensagens da fila:

```bash
kubectl exec -n mensageria deployment/rabbitmq -- \
    rabbitmqctl purge_queue fila_teste
```

Depois pode-se verificar novamente as métricas no Prometheus.

---

# 26. Parando o ambiente

Para parar o Minikube:

```bash
minikube stop
```

Para iniciar novamente:

```bash
minikube start
```

Os recursos do Kubernetes permanecem armazenados no cluster do Minikube.

---

# 27. Removendo os recursos do projeto

Para remover os componentes da aplicação:

```bash
kubectl delete -f kubernetes/producer.yaml
kubectl delete -f kubernetes/worker.yaml
kubectl delete -f kubernetes/api.yaml
kubectl delete -f kubernetes/rabbitmq.yaml
```

Para remover o namespace:

```bash
kubectl delete namespace mensageria
```

> A remoção do namespace também remove os recursos existentes dentro dele.

---

# 28. Estrutura do projeto

A estrutura esperada do projeto é:

```text
projeto-mensageria/
│
├── api/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
│
├── producer/
│   ├── producer.py
│   └── Dockerfile
│
├── worker/
│   ├── worker.py
│   └── Dockerfile
│
├── kubernetes/
│   ├── namespace.yaml
│   ├── api.yaml
│   ├── producer.yaml
│   ├── rabbitmq.yaml
│   ├── worker.yaml
│   │
│   └── monitoring/
│       └── rabbitmq-servicemonitor.yaml
│
├── scripts/
│   ├── iniciar-demo.sh
│   └── parar-demo.sh
│
├── .gitignore
└── README.md
```

---

# 29. Objetivo dos experimentos

O projeto busca analisar como um sistema de mensageria se comporta sob diferentes níveis de carga e como esse comportamento é representado pelo sistema de monitoramento.

Entre os aspectos observados estão:

* quantidade de mensagens na fila;
* mensagens produzidas;
* mensagens processadas;
* mensagens não confirmadas;
* quantidade de consumidores;
* utilização dos consumidores;
* crescimento e redução da fila;
* comportamento durante bursts de carga;
* influência da quantidade de Workers;
* influência do intervalo de coleta do Prometheus.

O Prometheus realiza coleta periódica das métricas. Portanto, o monitoramento representa o comportamento observado durante os intervalos de coleta, e eventos muito rápidos podem não aparecer da mesma maneira que seriam observados através de um registro de cada evento individual.

---

# 30. Implantação no Oracle Cloud

A próxima etapa do projeto consiste em executar a aplicação em um ambiente distribuído composto por máquinas virtuais no Oracle Cloud.

A arquitetura planejada será:

```text
              Oracle Cloud
        ┌───────────────────────┐
        │   Kubernetes Cluster  │
        │                       │
        │  ┌─────┐ ┌─────┐ ┌─────┐
        │  │ VM1 │ │ VM2 │ │ VM3 │
        │  │     │ │     │ │     │
        │  └─────┘ └─────┘ └─────┘
        │                       │
        └───────────────────────┘
```

Os manifests Kubernetes serão reutilizados para permitir que o projeto seja reproduzido em outro ambiente.

As imagens da API, Worker e Producer deverão estar disponíveis em um registro de containers para que os nós do cluster possam obtê-las.

Essa etapa será configurada separadamente da execução local com Minikube.

---

# 31. Fluxo rápido para demonstração

Depois que o ambiente estiver configurado, o fluxo principal da apresentação será:

### 1. Iniciar o Minikube

```bash
minikube start
```

### 2. Verificar o cluster

```bash
kubectl get nodes
```

### 3. Iniciar a demonstração

```bash
./scripts/iniciar-demo.sh
```

### 4. Mostrar o QR Code

```text
scripts/qr-code.png
```

### 5. Participantes enviam mensagens pelos celulares

As mensagens serão encaminhadas:

```text
Celular → API → RabbitMQ → Worker
```

### 6. Abrir o Grafana

```text
http://localhost:3000
```

### 7. Observar as métricas

Principalmente:

```text
Mensagens na fila
Mensagens produzidas
Mensagens processadas
Consumidores
Mensagens não confirmadas
```

### 8. Alterar a carga

Pode-se ligar o Producer ou aumentar o número de Workers para observar a mudança no comportamento do sistema.

### 9. Encerrar

```bash
./scripts/parar-demo.sh
```

---

## Autores

Projeto desenvolvido para a disciplina de Sistemas Distribuídos.
