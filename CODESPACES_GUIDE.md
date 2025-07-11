# 🌐 Guia Prático: Zabbix no GitHub Codespaces

Este guia mostra como acessar e usar o Zabbix Server rodando em um GitHub Codespace de forma remota.

## 🚀 Início Rápido

### 1. Iniciar o Zabbix no Codespace

```bash
# Clone o projeto (se não fez ainda)
git clone https://github.com/seu-usuario/zabbix-home-monitoring.git
cd zabbix-home-monitoring

# Inicie os serviços
podman-compose -f podman-compose.env.yml up -d

# Verifique se estão rodando
podman-compose -f podman-compose.env.yml ps
```

### 2. Configurar Port Forwarding

#### Método 1: Automático (VS Code)
1. Abra a aba **"PORTS"** no VS Code
2. As portas aparecerão automaticamente quando os containers subirem
3. Clique no ícone 🌐 para abrir no navegador

#### Método 2: Manual
1. Aba **"PORTS"** → **"Forward a Port"**
2. Digite: `8080` → Enter
3. Digite: `10051` → Enter (para agentes externos)

### 3. Acessar a Interface Web

Após o port forwarding, você receberá uma URL similar a:
```
https://psychic-funicular-1234567890.github.dev
```

**Credenciais padrão:**
- Usuario: `Admin`
- Senha: `zabbix`

⚠️ **IMPORTANTE**: Altere a senha imediatamente!

## 📱 Configuração de Agentes Externos

### Cenário: Monitorar PC/Servidor da sua casa

#### 1. Obter URL do Zabbix Server
```bash
# No terminal do Codespace:
gh codespace ports | grep 10051

# Exemplo de saída:
# 10051 (zabbix-server) | https://psychic-funicular-1234567890-10051.app.github.dev
```

#### 2. Configurar Agent no PC de Casa (Linux)
```bash
# Instalar Zabbix Agent2
sudo apt update
sudo apt install zabbix-agent2

# Editar configuração
sudo nano /etc/zabbix/zabbix_agent2.conf
```

**Configuração para Codespace:**
```ini
# Substituir pela URL real do seu Codespace
Server=psychic-funicular-1234567890-10051.app.github.dev
ServerActive=psychic-funicular-1234567890-10051.app.github.dev:10051
Hostname=pc-casa-sala
ListenPort=10050
EnableRemoteCommands=1
```

```bash
# Reiniciar serviço
sudo systemctl restart zabbix-agent2
sudo systemctl enable zabbix-agent2

# Verificar status
sudo systemctl status zabbix-agent2
```

#### 3. Adicionar Host no Zabbix Web

1. **Configuration** → **Hosts** → **Create host**
2. Configurar:
   - **Host name**: `pc-casa-sala`
   - **Visible name**: `PC da Sala (Casa)`
   - **Groups**: `Linux servers`
   - **Interfaces** → **Agent**:
     - **IP address**: IP público do seu PC ou DDNS
     - **Port**: `10050`

## 🛡️ Configurações de Segurança

### 1. Alterar Senha Padrão
```
Administration → Users → Admin → Change password
```
**Nova senha forte:** mínimo 12 caracteres, misturar maiúsculas, minúsculas, números e símbolos.

### 2. Configurar HTTPS (Opcional)
```bash
# No Codespace, gerar certificado self-signed
mkdir -p cert
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout cert/zabbix.key \
    -out cert/zabbix.crt \
    -subj "/CN=zabbix-codespace"

# Reiniciar web interface
podman-compose -f podman-compose.env.yml restart zabbix-web
```

### 3. Restringir Acesso por IP (Para Produção)
```yaml
# No podman-compose.env.yml:
environment:
  ZBX_DENY_GUI_ACCESS: "0.0.0.0/0"
  ZBX_ALLOW_GUI_ACCESS: "SEU_IP_PUBLICO/32"
```

## 📊 Monitoramento Básico

### Templates Recomendados para Casa

#### 1. **Linux by Zabbix agent 2**
- CPU, RAM, Disco, Rede
- Processos e serviços
- Performance geral

#### 2. **Docker by Zabbix agent 2**
- Status dos containers
- Uso de recursos por container
- Imagens e volumes

#### 3. **Generic SNMP**
- Roteadores
- Switches
- Impressoras de rede

### Métricas Importantes para Casa

```
🖥️ PCs/Servidores:
- CPU usage > 90%
- Memory usage > 85% 
- Disk free < 10%
- System uptime

📡 Rede:
- Internet connectivity (ping 8.8.8.8)
- Router uptime
- WiFi clients count
- Bandwidth usage

🐳 Containers:
- Container status (running/stopped)
- Memory per container
- CPU per container
```

## 🚨 Alertas Recomendados

### 1. Configurar Email
```
Administration → Media types → Email
- SMTP server: smtp.gmail.com
- Port: 587
- Security: STARTTLS
- Username: seu.email@gmail.com
- Password: app-password (não a senha normal!)
```

### 2. Configurar Triggers Básicos
```
📧 Email quando:
- Dispositivo fica offline (> 5 min)
- CPU > 90% (> 10 min)
- Memória > 90% (> 5 min)
- Disco < 10% livre
- Internet fora do ar (> 2 min)
```

## 📱 Acesso Mobile

### URLs Otimizadas
```
Desktop: https://seu-codespace.github.dev
Mobile:  https://seu-codespace.github.dev/mobile
```

### Apps de Terceiros
- **Zabbix Mobile** (oficial)
- **ZBX Viewer** (Android)
- **iZabbix** (iOS)

**Configuração do App:**
- URL: `https://seu-codespace.github.dev`
- User: `Admin`
- Password: `sua-nova-senha`

## 💰 Otimização de Custos

### GitHub Codespaces - Dicas de Economia

```bash
# Parar Codespace quando não usar
gh codespace stop

# Verificar uso de horas
gh billing view

# Configurar auto-stop (VS Code)
# Settings → Codespaces → Idle Timeout
```

### Alternativas Gratuitas
1. **GitHub Actions** (apenas para CI/CD)
2. **Oracle Cloud Free Tier** (VM sempre gratuita)
3. **VPS barato** ($3-5/mês)

## 🔧 Troubleshooting

### Problema: Port não aparece na aba PORTS
```bash
# Verificar se containers estão rodando
podman ps

# Forçar port forwarding
gh codespace ports forward 8080
```

### Problema: Agent não conecta
```bash
# No PC de casa, testar conectividade
telnet seu-codespace-10051.app.github.dev 10051

# Verificar firewall
sudo ufw allow 10050

# Ver logs do agent
sudo tail -f /var/log/zabbix/zabbix_agent2.log
```

### Problema: Interface lenta
- Codespace pode estar em região distante
- Considere usar em horários de menor tráfego
- Para produção, use VPS local

## 🎯 Casos de Uso Ideais

### ✅ Perfeito para:
- **Desenvolvimento** e testes
- **Demonstrações** para clientes
- **Aprender** Zabbix
- **Configurar** templates e dashboards
- **Acesso remoto** temporário

### ⚠️ Limitado para:
- **Produção 24/7** (custos altos)
- **Monitoramento crítico** (dependência internet)
- **Baixa latência** (pode ter atrasos)

## 📚 Próximos Passos

1. **Explore dashboards** padrão
2. **Configure alertas** para sua rede
3. **Adicione dispositivos** da casa
4. **Crie templates** customizados
5. **Para produção**: migre para VPS/servidor dedicado

---

**💡 Dica Final**: Use o Codespace para aprender e configurar. Quando estiver satisfeito, faça o deploy em um servidor real para uso em produção!
