# 🏠 Zabbix - Monitoramento de Rede Doméstica

Este projeto configura um sistema completo de monitoramento Zabbix usando **Podman** no **Linux Mint** para monitorar sua rede doméstica. O Zabbix é uma solução open-source robusta para monitoramento de infraestrutura de TI.

> 🐧 **Ambiente Testado**: Este projeto foi desenvolvido e testado especificamente em **Linux Mint** usando **Podman** como runtime de containers, oferecendo uma alternativa segura e rootless ao Docker.

## 📋 Visão Geral

O sistema é composto por:
- **Zabbix Server**: Núcleo do sistema de monitoramento (alpine-trunk)
- **Zabbix Web Nginx**: Interface web com servidor Nginx para visualização e configuração
- **PostgreSQL 15.6**: Banco de dados para armazenar dados de monitoramento
- **Zabbix Agent2**: Agente avançado para monitorar o host local com suporte a containers

## 🏗️ Arquitetura

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ Zabbix Web Nginx│    │  Zabbix Server  │    │  PostgreSQL 15  │
│ (Ports 8080/8443│◄──►│   (Port 10051)  │◄──►│   (Port 5432)   │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │
                       ┌─────────────────┐
                       │ Zabbix Agent2   │
                       │ (Ports 10050/   │
                       │      31999)     │
                       └─────────────────┘
                                │
                       ┌─────────────────┐
                       │ Podman Socket   │
                       │ (Monitoring)    │
                       └─────────────────┘
```

**Rede**: `zabbix7` (bridge)
**Volume**: `zbx_db15` (PostgreSQL data)

## 📁 Estrutura dos Arquivos

O projeto inclui dois arquivos de configuração:

### `podman-compose.yml` (Arquivo Principal)
- ✅ **Configuração básica** para início rápido
- ✅ **IPs fixos** definidos diretamente no arquivo
- ✅ **Ideal para testes** e primeira configuração
- ⚠️ **Requer edição manual** para alterar IPs

### `podman-compose.env.yml` (Recomendado)
- ✅ **Usa variáveis de ambiente** (.env)
- ✅ **Configuração flexível** sem editar o arquivo
- ✅ **Melhor para produção** e reutilização
- ✅ **Facilita atualizações** e backups
- 🔧 **Inclui arquivo `.env`** pré-configurado (baseado em `.env.example`)

**💡 Recomendação**: Use `podman-compose.env.yml` + arquivo `.env` para maior flexibilidade.

### 🔧 Nomes de Imagens Totalmente Qualificados

Este projeto foi configurado com **nomes de imagens totalmente qualificados** para garantir máxima compatibilidade e segurança com Podman:

```yaml
# ✅ Configuração atual (totalmente qualificada)
image: docker.io/zabbix/zabbix-server-pgsql:alpine-trunk
image: docker.io/zabbix/zabbix-web-nginx-pgsql:alpine-trunk
image: docker.io/zabbix/zabbix-agent2:alpine-trunk
image: docker.io/library/postgres:15.6-bullseye

# ❌ Configuração anterior (não qualificada)
image: zabbix/zabbix-server-pgsql:alpine-trunk
image: postgres:15.6-bullseye
```

**🎯 Vantagens dos Nomes Totalmente Qualificados:**
- ✅ **Compatibilidade garantida** com Podman
- ✅ **Não depende** de configurações locais de registry
- ✅ **Explicitamente define** a origem das imagens
- ✅ **Evita ambiguidades** entre diferentes registries
- ✅ **Funciona imediatamente** após clone do projeto

### Compatibilidade com Docker
- ✅ **Link simbólico** `docker-compose.yml` → `podman-compose.yml`
- ✅ **Funciona com docker-compose** sem alterações
- 🔄 **Migração fácil** entre Podman e Docker

## 🚀 Instalação e Configuração

### Pré-requisitos

#### 🐧 Para Linux Mint (Ambiente Testado):
- **Podman** e **Podman Compose** instalados
- **Linux Mint 20.3+** (testado em versões recentes)
- 4GB+ de RAM disponível (configurado para alta performance)
- 20GB+ de espaço em disco
- Acesso à rede onde deseja monitorar dispositivos

#### 📦 Instalação do Podman no Linux Mint:
```bash
# Atualizar repositórios
sudo apt update

# Instalar Podman
sudo apt install podman podman-compose

# Verificar instalação
podman --version
podman-compose --version

# Configurar Podman para usuário atual (rootless)
echo 'unqualified-search-registries = ["docker.io"]' | sudo tee /etc/containers/registries.conf
```

#### 🔄 Compatibilidade com Docker:
Se preferir usar Docker ao invés de Podman, funciona perfeitamente:
- Docker Engine 20.10+
- Docker Compose v2+

### 1. Clone o Projeto

```bash
git clone <url-do-repositorio>
cd zabbix
```

> ✅ **Pronto para Uso**: O projeto já inclui um arquivo `.env` pré-configurado com valores padrão. Você só precisa ajustar o IP do servidor!

### 2. Configurar Variáveis de Ambiente (Recomendado)

#### 📋 Estrutura dos Arquivos de Configuração:
- **`.env`**: Arquivo ATIVO com valores reais já configurados ✅
- **`.env.example`**: Arquivo TEMPLATE com placeholders de exemplo ⚠️

**✅ MÉTODO FÁCIL**: O projeto já inclui um arquivo `.env` funcional! Apenas ajuste-o:

```bash
# Edite o arquivo .env (que já tem valores funcionais)
nano .env

# Principais configurações a verificar/ajustar:
# ZABBIX_SERVER_IP=192.168.1.120  (confirme se é seu IP real)
# POSTGRES_PASSWORD=G7p!xQ2v#Lm9sT  (troque por senha própria)
# ZBX_HOSTNAME=zabbix-server-home  (nome único do seu servidor)
# TZ=America/Recife  (ajuste seu fuso horário)
```

**🔄 Método Alternativo**: Recrie o `.env` a partir do template:

```bash
# Se quiser começar do zero
cp .env.example .env
nano .env  # Substitua TODOS os valores marcados com ⚠️
```

**Alternativa Manual**: Edite diretamente o `podman-compose.yml`:

```bash
# Edite o podman-compose.yml
nano podman-compose.yml

# Substitua todas as ocorrências de "SEUIP" pelo IP do seu servidor
# Exemplo: se seu servidor tem IP 192.168.1.100
# DB_SERVER_HOST: "192.168.1.100"
# ZBX_PASSIVESERVERS: "192.168.1.100"
```

### 3. Criar Diretório para Certificados (Opcional)

```bash
mkdir -p cert
# Coloque seus certificados SSL aqui se desejar HTTPS
```

### 4. Iniciar os Serviços

#### 🐧 Com Podman (Recomendado para Linux Mint):
```bash
# RECOMENDADO: Usando arquivo com variáveis de ambiente (.env)
podman-compose -f podman-compose.env.yml up -d

# Alternativa: Usando arquivo com configuração fixa
podman-compose up -d

# Ou usando podman diretamente
podman run --rm -it -v "$(pwd)":/compose:Z docker.io/docker/compose -f podman-compose.env.yml up -d
```

#### 🐳 Com Docker (Alternativo):
```bash
# RECOMENDADO: Com variáveis de ambiente
docker-compose -f podman-compose.env.yml up -d

# Arquivo padrão (mantém compatibilidade)
docker-compose up -d
```

### 5. Verificar Status dos Serviços

#### 🐧 Com Podman:
```bash
# Verificar containers
podman ps

# Verificar com compose
podman-compose ps

# Ver logs
podman-compose logs
```

#### 🐳 Com Docker:
```bash
docker-compose -f podman-compose.yml ps
```

## 🌐 Acesso ao Sistema

### Interface Web
- **URL HTTP**: http://localhost:8080
- **URL HTTPS**: https://localhost:8443
- **Usuário padrão**: Admin
- **Senha padrão**: zabbix

⚠️ **Importante**: Altere a senha padrão imediatamente após o primeiro login!

### Portas Utilizadas
- **8080**: Interface web HTTP do Zabbix
- **8443**: Interface web HTTPS do Zabbix
- **5432**: PostgreSQL
- **10050**: Zabbix Agent2
- **10051**: Zabbix Server
- **31999**: Zabbix Agent2 (porta adicional)

## 🔧 Configurações Avançadas do Podman

### Socket do Podman para Monitoramento
O Zabbix Agent2 está configurado para monitorar containers através do socket do Podman:

```yaml
# Configuração automática do socket (já incluída no projeto)
volumes:
  - /run/user/${UID:-1000}/podman/podman.sock:/var/run/docker.sock:ro
```

**🎯 Recursos de Monitoramento de Containers:**
- ✅ **Status dos containers**: Running, stopped, paused
- ✅ **Uso de recursos**: CPU, memória, rede por container
- ✅ **Estatísticas em tempo real**: I/O de disco, tráfego de rede
- ✅ **Inventário de imagens**: Tamanho, tags, data de criação
- ✅ **Compatibilidade total** com API Docker (via Podman)

### Variável UID para Multi-usuário
O projeto inclui suporte automático para diferentes usuários:

```bash
# No arquivo .env
UID=1000  # ID do usuário atual

# Para descobrir seu UID
id -u

# O socket será montado automaticamente de:
# /run/user/[SEU_UID]/podman/podman.sock
```

### Configuração Rootless
O Podman funciona sem privilégios de root, oferecendo maior segurança:

```bash
# Verificar se Podman está rodando rootless
podman info | grep -i rootless

# Verificar localização do socket
ls -la /run/user/$(id -u)/podman/podman.sock

# Status dos containers sem sudo
podman ps
```

## ⚙️ Configurações Especiais

### Cache e Performance
O Zabbix Server está configurado com caches otimizados:
- **CACHESIZE**: 4096M
- **HISTORYCACHESIZE**: 1024M
- **HISTORYINDEXCACHESIZE**: 1024M
- **TRENDCACHESIZE**: 1024M
- **VALUECACHESIZE**: 1024M

### Zabbix Agent2 Features
- **Monitoramento de Containers**: Acesso ao socket Podman/Docker para monitorar containers
- **Comandos Remotos**: Habilitados para execução remota
- **Modo Privilegiado**: Para acesso completo ao sistema host Linux Mint
- **Debug Level**: 3 (logs detalhados)
- **Rootless Support**: Funciona perfeitamente com Podman rootless

## 📊 Configuração Inicial

### 1. Primeiro Acesso
1. Acesse http://localhost:8080 ou https://localhost:8443
2. Aguarde alguns minutos para inicialização completa
3. Faça login com Admin/zabbix
4. Vá em Administration → Users → Admin
5. Altere a senha padrão

### 2. Configurar Host Local
O Zabbix Agent2 já está configurado com hostname "zabbix7". Para verificar:

1. Vá em Configuration → Hosts
2. Verifique se o host "zabbix7" aparece
3. Status deve estar "Available" (verde)

### 3. Configurar Novos Hosts
Para adicionar outros dispositivos da rede:

1. Configuration → Hosts → Create host
2. Configure:
   - **Host name**: Nome do dispositivo
   - **Visible name**: Nome amigável
   - **Groups**: Selecione grupo apropriado
   - **Interfaces**:
     - Agent: IP do dispositivo + porta 10050
     - SNMP: IP do dispositivo + porta 161
     - IPMI: Para servidores com IPMI

### 4. Templates Recomendados para Rede Doméstica
- **Linux by Zabbix agent 2**: Para servidores/PCs Linux
- **Windows by Zabbix agent 2**: Para PCs Windows
- **Docker by Zabbix agent 2**: Para monitoramento de containers
- **Generic SNMP**: Para roteadores, switches, impressoras
- **ICMP Ping**: Para verificar conectividade básica
- **Zabbix server health**: Para monitorar o próprio Zabbix

## 🔧 Monitoramento da Rede Doméstica

### Dispositivos Comuns para Monitorar

#### � Containers Docker
Com o Agent2 configurado, você pode monitorar:
- **Status dos containers**: Running, stopped, paused
- **Uso de recursos**: CPU, RAM, rede por container
- **Logs de containers**: Erros e alertas
- **Images**: Espaço usado, versões

#### �🖥️ Computadores/Servidores
- CPU, RAM, disco, swap
- Processos e serviços críticos
- Temperatura e sensores (se disponível)
- Conectividade de rede
- Performance de disco I/O

#### 📡 Equipamentos de Rede
- **Roteador**: Status WAN/LAN, throughput, VPN
- **Switch**: Status das portas, tráfego, VLAN
- **Access Points**: Clientes conectados, sinal WiFi, interferência
- **Modem**: Sinal, SNR, linha

#### 🌐 Serviços e Aplicações
- **Conectividade com Internet**: Latência, perda de pacotes
- **Serviços web locais**: Plex, NAS, Nextcloud, etc.
- **Velocidade de internet**: Download/upload
- **DNS**: Resolução, tempo de resposta
- **DHCP**: Pool de IPs, leases

### Configuração SNMP para Equipamentos
```bash
# Exemplo para roteadores/switches (varia por modelo)
# Via interface web ou CLI:

# Para equipamentos Cisco:
snmp-server community public RO
snmp-server community private RW

# Para equipamentos TP-Link/D-Link:
# Vá em Advanced → SNMP → Enable SNMP
# Community: public (read-only)

# Para equipamentos Ubiquiti:
# System → Advanced → SNMP → Enable
```

### Instalação do Zabbix Agent em Outros Hosts

#### Linux (Ubuntu/Debian):
```bash
# Baixar e instalar
wget https://repo.zabbix.com/zabbix/7.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_latest+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_latest+ubuntu22.04_all.deb
sudo apt update
sudo apt install zabbix-agent2

# Configurar
sudo sed -i 's/Server=127.0.0.1/Server=SEU_IP_ZABBIX/' /etc/zabbix/zabbix_agent2.conf
sudo sed -i 's/ServerActive=127.0.0.1/ServerActive=SEU_IP_ZABBIX/' /etc/zabbix/zabbix_agent2.conf
sudo sed -i 's/Hostname=Zabbix server/Hostname=nome-do-host/' /etc/zabbix/zabbix_agent2.conf

# Iniciar serviço
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2
```

#### Windows:
1. Baixe o Zabbix Agent2 para Windows
2. Instale e configure no arquivo `zabbix_agent2.conf`
3. Configure como serviço do Windows

## 📈 Dashboards Sugeridos

### Dashboard Principal - Rede Doméstica
- Status geral dos dispositivos
- Mapa da rede com status visual
- Uso de banda da internet (real-time)
- Alertas ativos e problemas
- Top 5 dispositivos por tráfego
- Status dos containers Docker

### Dashboard de Infraestrutura
- CPU, RAM, disco de todos os hosts
- Status de serviços críticos
- Uptime dos sistemas
- Performance de rede por interface
- Temperatura dos equipamentos

### Dashboard de Aplicações
- Status dos serviços web (Plex, NAS, etc.)
- Tempo de resposta de aplicações
- Logs de erro recentes
- Backup status
- Certificados SSL próximos ao vencimento

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

#### 🐧 Com Podman:
```bash
# Backup do banco PostgreSQL
podman exec zabbix_db pg_dump -U zabbix zabbix_db > backup_$(date +%Y%m%d).sql

# Backup do volume de dados
podman run --rm -v zbx_db15:/data -v $(pwd):/backup alpine tar czf /backup/zabbix_db_backup_$(date +%Y%m%d).tar.gz -C /data .

# Backup da configuração
cp podman-compose.yml podman-compose.yml.backup
cp podman-compose.env.yml podman-compose.env.yml.backup 2>/dev/null || true
```

#### 🐳 Com Docker:
```bash
# Backup do banco PostgreSQL
docker exec zabbix_db pg_dump -U zabbix zabbix_db > backup_$(date +%Y%m%d).sql

# Backup do volume de dados
docker run --rm -v zbx_db15:/data -v $(pwd):/backup alpine tar czf /backup/zabbix_db_backup_$(date +%Y%m%d).tar.gz -C /data .

# Backup da configuração
cp podman-compose.yml podman-compose.yml.backup
cp podman-compose.env.yml podman-compose.env.yml.backup 2>/dev/null || true
```

### Restaurar Backup

#### 🐧 Com Podman:
```bash
# Parar os serviços
podman-compose down

# Restaurar banco
podman run --rm -v zbx_db15:/data -v $(pwd):/backup alpine tar xzf /backup/zabbix_db_backup_YYYYMMDD.tar.gz -C /data

# Reiniciar
podman-compose up -d
```

#### 🐳 Com Docker:
```bash
# Parar os serviços
docker-compose -f podman-compose.yml down
# ou
docker-compose -f podman-compose.env.yml down

# Restaurar banco
docker run --rm -v zbx_db15:/data -v $(pwd):/backup alpine tar xzf /backup/zabbix_db_backup_YYYYMMDD.tar.gz -C /data

# Reiniciar
docker-compose -f podman-compose.yml up -d
# ou
docker-compose -f podman-compose.env.yml up -d
```

### Logs dos Serviços

#### 🐧 Com Podman:
```bash
# Ver logs do Zabbix Server
podman logs zabbix-server

# Ver logs do banco
podman logs zabbix_db

# Ver logs da interface web
podman logs zabbix-web

# Ver logs do Agent2
podman logs zabbix-agent2

# Seguir logs em tempo real
podman logs -f zabbix-server
```

#### 🐳 Com Docker:
```bash
# Ver logs do Zabbix Server
docker logs zabbix-server

# Ver logs do banco
docker logs zabbix_db

# Ver logs da interface web
docker logs zabbix-web

# Ver logs do Agent2
docker logs zabbix-agent2

# Seguir logs em tempo real
docker logs -f zabbix-server
```

# Seguir logs em tempo real
docker logs -f zabbix-server
```

### Monitoramento de Performance

#### 🐧 Com Podman:
```bash
# Verificar uso de recursos dos containers
podman stats

# Verificar espaço do volume do banco
podman system df -v

# Verificar conectividade do Agent2
podman exec zabbix-agent2 zabbix_get -s 127.0.0.1 -k agent.ping
```

#### 🐳 Com Docker:
```bash
# Verificar uso de recursos dos containers
docker stats

# Verificar espaço do volume do banco
docker system df -v

# Verificar conectividade do Agent2
docker exec zabbix-agent2 zabbix_get -s 127.0.0.1 -k agent.ping
```

### Atualização

#### 🐧 Com Podman:
```bash
# Parar serviços
podman-compose down

# Fazer backup dos dados
tar -czf backup_antes_update.tar.gz postgres_data/

# Atualizar imagens
podman-compose pull

# Reiniciar
podman-compose up -d
```

#### 🐳 Com Docker:
```bash
# Parar serviços
docker-compose -f podman-compose.yml down
# ou
docker-compose -f podman-compose.env.yml down

# Fazer backup dos dados
tar -czf backup_antes_update.tar.gz postgres_data/

# Atualizar imagens
docker-compose -f podman-compose.yml pull
# ou
docker-compose -f podman-compose.env.yml pull

# Reiniciar
docker-compose -f podman-compose.yml up -d
# ou
docker-compose -f podman-compose.env.yml up -d
```

## 🛠️ Solução de Problemas

### Problemas Comuns

#### Serviço não inicia

#### 🐧 Com Podman:
```bash
# Verificar logs
podman-compose logs nome-do-servico
# ou
podman-compose -f podman-compose.env.yml logs nome-do-servico

# Verificar recursos do sistema
free -h
df -h
```

#### 🐳 Com Docker:
```bash
# Verificar logs
docker-compose -f podman-compose.yml logs nome-do-servico
# ou
docker-compose -f podman-compose.env.yml logs nome-do-servico

# Verificar recursos do sistema
free -h
df -h
```

#### Interface web não carrega
- Verificar se as portas 8080/8443 estão livres
- Aguardar alguns minutos para inicialização completa
- Verificar logs do zabbix-web
- Testar: `curl http://localhost:8080/ping`

#### Agent2 não se conecta
```bash
# Verificar se o Agent2 está rodando
docker ps | grep zabbix-agent2

# Testar conectividade
docker exec zabbix-agent2 zabbix_get -s 127.0.0.1 -k agent.ping

# Verificar configuração de rede
docker network inspect zabbix7
```

#### Performance lenta
- Verificar se o host tem pelo menos 4GB de RAM
- Monitorar uso de CPU dos containers
- Considerar ajustar os valores de cache se necessário
- Verificar espaço em disco disponível

#### Problemas com monitoramento Docker
```bash
# Verificar permissões do socket Docker
ls -la /var/run/docker.sock

# Verificar se o Agent2 tem acesso
docker exec zabbix-agent2 ls -la /var/run/docker.sock
```

#### Banco de dados com problemas
```bash
# Verificar status do PostgreSQL
docker exec zabbix_db pg_isready -U zabbix

# Verificar conectividade
docker exec zabbix_db psql -U zabbix -d zabbix_db -c "SELECT version();"

# Verificar espaço do volume
docker exec zabbix_db df -h /var/lib/postgresql/data
```

## 🚀 Funcionalidades Avançadas

### Monitoramento de Containers Docker
O Agent2 já está configurado para monitorar containers. Métricas disponíveis:
- `docker.container_info[*]` - Informações dos containers
- `docker.container.stats[*]` - Estatísticas de uso
- `docker.images[*]` - Lista de imagens Docker

### Auto-discovery de Dispositivos
Configure auto-discovery para encontrar novos dispositivos automaticamente:
1. Configuration → Discovery → Create discovery rule
2. Configure IP range da sua rede (ex: 192.168.1.1-254)
3. Defina checks: Zabbix agent, SNMP, ICMP ping

### Mapas de Rede
Crie mapas visuais da sua rede:
1. Monitoring → Maps → Create map
2. Adicione hosts e defina conexões
3. Configure ícones baseados no status

### Notification via Telegram/WhatsApp
1. Administration → Media types
2. Configure Webhook para Telegram/Discord
3. Teste as notificações

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

**🐧 Ambiente Testado**: Este projeto foi desenvolvido e testado especificamente em **Linux Mint 21.3** usando **Podman 3.4.4** e **Podman Compose 1.0.0**.

**💡 Dica**: Para uma rede doméstica típica, comece monitorando conectividade (ping) e depois vá adicionando métricas mais detalhadas conforme necessário.

---

## 🐧 Por que Podman no Linux Mint?

### Vantagens do Podman:
- **🔒 Rootless**: Executa containers sem privilégios de root, aumentando a segurança
- **🛡️ Sem Daemon**: Não requer um daemon em execução constante como o Docker
- **🔐 Melhor Segurança**: Isolamento de containers mais seguro por padrão
- **📋 Compatibilidade**: API compatível com Docker, facilitando migração
- **🎯 Ideal para Desktop**: Perfeito para ambientes de desenvolvimento e uso doméstico

### Específico para Linux Mint:
- **✅ Pacote Nativo**: Disponível nos repositórios oficiais do Linux Mint
- **🏠 Ambiente Doméstico**: Ideal para monitoramento residencial sem comprometer segurança
- **⚡ Performance**: Excelente performance em sistemas baseados em Ubuntu/Debian
- **🔧 Facilidade**: Configuração simples, sem necessidade de adicionar usuário a grupos especiais

### Comparação Podman vs Docker:
| Aspecto | Podman | Docker |
|---------|--------|--------|
| Segurança | ✅ Rootless por padrão | ⚠️ Requer configuração |
| Daemon | ✅ Sem daemon | ❌ Requer daemon |
| Compatibilidade | ✅ API Docker | ✅ Nativo |
| Facilidade Setup | ✅ Simples | ⚠️ Requer configuração |
| Uso Doméstico | ✅ Ideal | ✅ Funciona |
