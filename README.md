# 🏠 Zabbix - Monitoramento de Rede Doméstica

Este projeto configura um sistema completo de monitoramento Zabbix usando Docker/Podman para monitorar sua rede doméstica. O Zabbix é uma solução open-source robusta para monitoramento de infraestrutura de TI.

## 📋 Visão Geral

O sistema é composto por:
- **Zabbix Server**: Núcleo do sistema de monitoramento
- **Zabbix Web Interface**: Interface web para visualização e configuração
- **PostgreSQL**: Banco de dados para armazenar dados de monitoramento
- **Zabbix Agent**: Agente para monitorar o host local

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Zabbix Web    │    │  Zabbix Server  │    │   PostgreSQL    │
│   (Port 80)     │◄──►│   (Port 10051)  │◄──►│   (Port 5432)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │  Zabbix Agent   │
                       │   (Port 10050)  │
                       └─────────────────┘
```

## 🚀 Instalação e Configuração

### Pré-requisitos

- Docker ou Podman instalado
- Docker Compose ou Podman Compose
- 2GB+ de RAM disponível
- 10GB+ de espaço em disco

### 1. Clone o Projeto

```bash
git clone <url-do-repositorio>
cd zabbix
```

### 2. Configurar Variáveis de Ambiente

Crie um arquivo `.env` com as seguintes variáveis:

```bash
# Configurações do PostgreSQL
POSTGRES_DB=zabbix
POSTGRES_USER=zabbix
POSTGRES_PASSWORD=sua_senha_forte_aqui

# Configurações do PHP/Timezone
PHP_TZ=America/Sao_Paulo
```

### 3. Criar a Rede Docker (Opcional)

Se estiver usando Docker (não necessário para a configuração atual com network_mode: host):

```bash
./create_zabbix.sh
```

### 4. Iniciar os Serviços

```bash
docker-compose up -d
```

ou com Podman:

```bash
podman-compose up -d
```

### 5. Verificar Status dos Serviços

```bash
docker-compose ps
```

## 🌐 Acesso ao Sistema

### Interface Web
- **URL**: http://localhost
- **Usuário padrão**: Admin
- **Senha padrão**: zabbix

⚠️ **Importante**: Altere a senha padrão imediatamente após o primeiro login!

### Portas Utilizadas
- **80**: Interface web do Zabbix
- **5432**: PostgreSQL
- **10050**: Zabbix Agent
- **10051**: Zabbix Server

## 📊 Configuração Inicial

### 1. Primeiro Acesso
1. Acesse http://localhost
2. Faça login com Admin/zabbix
3. Vá em Administration → Users → Admin
4. Altere a senha padrão

### 2. Configurar Host Local
O Zabbix Agent já está configurado para monitorar o host local. Para adicionar outros dispositivos:

1. Vá em Configuration → Hosts
2. Clique em "Create host"
3. Configure:
   - **Host name**: Nome do dispositivo
   - **Groups**: Linux servers, Windows servers, etc.
   - **Interfaces**: IP do dispositivo

### 3. Templates Recomendados
- **Linux by Zabbix agent**: Para servidores/PCs Linux
- **Windows by Zabbix agent**: Para PCs Windows
- **Generic SNMP**: Para roteadores, switches
- **ICMP Ping**: Para verificar conectividade básica

## 🔧 Monitoramento da Rede Doméstica

### Dispositivos Comuns para Monitorar

#### 🖥️ Computadores/Servidores
- CPU, RAM, disco
- Processos e serviços
- Temperatura (se disponível)
- Conectividade de rede

#### 📡 Equipamentos de Rede
- **Roteador**: Status WAN/LAN, throughput
- **Switch**: Status das portas, tráfego
- **Access Points**: Clientes conectados, sinal WiFi

#### 🌐 Serviços
- **Conectividade com Internet**
- **Serviços web locais** (Plex, NAS, etc.)
- **Velocidade de internet**

### Configuração SNMP para Roteadores
```bash
# Exemplo de configuração SNMP (varia por modelo)
# Adicione no seu roteador:
snmp-server community public RO
```

## 📈 Dashboards Sugeridos

### Dashboard Principal - Rede Doméstica
- Status geral dos dispositivos
- Uso de banda da internet
- Alertas ativos
- Top 5 dispositivos por tráfego

### Dashboard de Servidores
- CPU, RAM, disco de servidores
- Status de serviços críticos
- Uptime dos sistemas

## 🚨 Configuração de Alertas

### Alertas Básicos Recomendados
1. **Dispositivo offline** (não responde ping)
2. **Alto uso de CPU** (>90% por 5 min)
3. **Pouco espaço em disco** (<10% livre)
4. **Internet fora do ar**
5. **Alto uso de RAM** (>90%)

### Configurar Notificações
1. Administration → Media types
2. Configure Email/Telegram/Slack
3. Administration → Users → Admin → Media
4. Actions → Trigger actions → Create action

## 🔧 Manutenção

### Backup dos Dados
```bash
# Backup do banco PostgreSQL
docker exec postgres-server pg_dump -U zabbix zabbix > backup_$(date +%Y%m%d).sql

# Backup dos dados persistentes
tar -czf zabbix_backup_$(date +%Y%m%d).tar.gz postgres_data/
```

### Logs dos Serviços
```bash
# Ver logs do Zabbix Server
docker logs zabbix-server

# Ver logs do banco
docker logs postgres-server

# Ver logs da interface web
docker logs zabbix-web
```

### Atualização
```bash
# Parar serviços
docker-compose down

# Fazer backup dos dados
tar -czf backup_antes_update.tar.gz postgres_data/

# Atualizar imagens
docker-compose pull

# Reiniciar
docker-compose up -d
```

## 🛠️ Solução de Problemas

### Problemas Comuns

#### Serviço não inicia
```bash
# Verificar logs
docker-compose logs nome-do-servico

# Verificar recursos do sistema
free -h
df -h
```

#### Interface web não carrega
- Verificar se a porta 80 está livre
- Aguardar alguns minutos para inicialização completa
- Verificar logs do zabbix-web

#### Banco de dados com problemas
```bash
# Verificar status do PostgreSQL
docker exec postgres-server pg_isready -U zabbix
```

## 📚 Recursos Úteis

### Documentação Oficial
- [Zabbix Documentation](https://www.zabbix.com/documentation)
- [Zabbix Templates](https://www.zabbix.com/integrations)

### Comunidade
- [Zabbix Forum](https://www.zabbix.com/forum/)
- [Reddit r/zabbix](https://reddit.com/r/zabbix)

## 🤝 Contribuição

Sinta-se à vontade para melhorar este projeto:
1. Faça um fork
2. Crie uma branch para sua feature
3. Commit suas mudanças
4. Abra um Pull Request

## 📄 Licença

Este projeto é open-source. O Zabbix é licenciado sob GPL v2.

---

**Dica**: Para uma rede doméstica típica, comece monitorando conectividade (ping) e depois vá adicionando métricas mais detalhadas conforme necessário.
