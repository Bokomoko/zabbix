#!/bin/bash

# 🌐 Script de Configuração para GitHub Codespaces
# Automatiza port forwarding e configuração inicial do Zabbix

echo "🏠 Zabbix - Configuração para GitHub Codespaces"
echo "==============================================="

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para verificar se comando existe
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Verificar se estamos em um Codespace
if [[ -n "$CODESPACES" ]]; then
    echo -e "${GREEN}✅ GitHub Codespace detectado!${NC}"
    echo -e "${BLUE}ℹ️  Codespace: $CODESPACE_NAME${NC}"
else
    echo -e "${YELLOW}⚠️  Este script é otimizado para GitHub Codespaces${NC}"
    echo -e "${YELLOW}   Mas você pode executá-lo em qualquer ambiente Linux${NC}"
fi

echo ""

# 1. Verificar pré-requisitos
echo "🔍 Verificando pré-requisitos..."

if command_exists podman; then
    echo -e "${GREEN}✅ Podman encontrado: $(podman --version)${NC}"
else
    echo -e "${RED}❌ Podman não encontrado!${NC}"
    echo "   Instalando Podman..."
    sudo apt update && sudo apt install -y podman podman-compose
fi

if command_exists podman-compose; then
    echo -e "${GREEN}✅ Podman Compose encontrado: $(podman-compose --version)${NC}"
else
    echo -e "${RED}❌ Podman Compose não encontrado!${NC}"
    exit 1
fi

echo ""

# 2. Configurar arquivo .env se necessário
echo "📝 Verificando arquivo .env..."

if [[ ! -f ".env" ]]; then
    echo -e "${YELLOW}⚠️  Arquivo .env não encontrado!${NC}"
    if [[ -f ".env.example" ]]; then
        echo "   Criando .env a partir do .env.example..."
        cp .env.example .env
        echo -e "${GREEN}✅ Arquivo .env criado!${NC}"
        echo -e "${YELLOW}⚠️  IMPORTANTE: Edite o arquivo .env com suas configurações!${NC}"
    else
        echo -e "${RED}❌ Arquivo .env.example também não encontrado!${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}✅ Arquivo .env encontrado${NC}"
fi

echo ""

# 3. Verificar/criar diretório de certificados
echo "🔐 Configurando certificados..."

if [[ ! -d "cert" ]]; then
    mkdir -p cert
    echo -e "${GREEN}✅ Diretório cert/ criado${NC}"
fi

# Verificar se já existem certificados
if [[ ! -f "cert/zabbix.crt" ]] || [[ ! -f "cert/zabbix.key" ]]; then
    echo "   Gerando certificados SSL auto-assinados..."
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout cert/zabbix.key \
        -out cert/zabbix.crt \
        -subj "/C=BR/ST=Estado/L=Cidade/O=Zabbix-Home/CN=zabbix-codespace" \
        > /dev/null 2>&1
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✅ Certificados SSL gerados${NC}"
    else
        echo -e "${YELLOW}⚠️  Erro ao gerar certificados SSL (não crítico)${NC}"
    fi
else
    echo -e "${GREEN}✅ Certificados SSL já existem${NC}"
fi

echo ""

# 4. Iniciar serviços
echo "🚀 Iniciando serviços Zabbix..."

# Parar serviços se estiverem rodando
podman-compose -f podman-compose.env.yml down > /dev/null 2>&1

# Iniciar serviços
podman-compose -f podman-compose.env.yml up -d

if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Serviços iniciados com sucesso!${NC}"
else
    echo -e "${RED}❌ Erro ao iniciar serviços${NC}"
    exit 1
fi

echo ""

# 5. Aguardar inicialização
echo "⏳ Aguardando inicialização dos serviços..."

sleep 10

# Verificar status dos containers
echo "🔍 Verificando status dos containers..."
podman-compose -f podman-compose.env.yml ps

echo ""

# 6. Configurar port forwarding (se estiver no Codespace)
if [[ -n "$CODESPACES" ]] && command_exists gh; then
    echo "🌐 Configurando port forwarding..."
    
    # Verificar se as portas já estão sendo forwarded
    PORTS_STATUS=$(gh codespace ports 2>/dev/null)
    
    if echo "$PORTS_STATUS" | grep -q "8080"; then
        echo -e "${GREEN}✅ Porta 8080 já está sendo forwarded${NC}"
    else
        echo "   Configurando port forwarding para porta 8080..."
        gh codespace ports forward 8080 > /dev/null 2>&1
    fi
    
    if echo "$PORTS_STATUS" | grep -q "10051"; then
        echo -e "${GREEN}✅ Porta 10051 já está sendo forwarded${NC}"
    else
        echo "   Configurando port forwarding para porta 10051..."
        gh codespace ports forward 10051 > /dev/null 2>&1
    fi
    
    echo ""
    
    # Mostrar URLs de acesso
    echo "🔗 URLs de acesso:"
    echo "=================="
    
    CODESPACE_URL=$(gh codespace ports | grep "8080" | awk '{print $3}' | head -1)
    ZABBIX_SERVER_URL=$(gh codespace ports | grep "10051" | awk '{print $3}' | head -1)
    
    if [[ -n "$CODESPACE_URL" ]]; then
        echo -e "${GREEN}🌐 Interface Web:  $CODESPACE_URL${NC}"
    else
        echo -e "${YELLOW}⚠️  URL da interface web não detectada automaticamente${NC}"
        echo "   Verifique a aba PORTS no VS Code"
    fi
    
    if [[ -n "$ZABBIX_SERVER_URL" ]]; then
        echo -e "${GREEN}📡 Zabbix Server: $ZABBIX_SERVER_URL${NC}"
        echo -e "${BLUE}ℹ️  Use esta URL para configurar agentes externos${NC}"
    else
        echo -e "${YELLOW}⚠️  URL do Zabbix Server não detectada automaticamente${NC}"
        echo "   Verifique a aba PORTS no VS Code"
    fi
    
else
    echo -e "${YELLOW}⚠️  GitHub CLI não encontrado ou não está em Codespace${NC}"
    echo "   Configure port forwarding manualmente na aba PORTS do VS Code"
fi

echo ""

# 7. Informações de acesso
echo "🔑 Informações de Acesso:"
echo "========================="
echo -e "${GREEN}Usuário: Admin${NC}"
echo -e "${GREEN}Senha:   zabbix${NC}"
echo ""
echo -e "${RED}⚠️  IMPORTANTE: Altere a senha padrão após o primeiro login!${NC}"

echo ""

# 8. Próximos passos
echo "📋 Próximos Passos:"
echo "==================="
echo "1. 🌐 Acesse a interface web (URL acima)"
echo "2. 🔐 Faça login com Admin/zabbix"
echo "3. 🔑 Altere a senha padrão"
echo "4. 📊 Explore os dashboards padrão"
echo "5. ➕ Adicione novos hosts para monitorar"

echo ""

# 9. Comandos úteis
echo "🛠️  Comandos Úteis:"
echo "==================="
echo "Ver logs:           podman-compose -f podman-compose.env.yml logs"
echo "Parar serviços:     podman-compose -f podman-compose.env.yml down"
echo "Reiniciar:          podman-compose -f podman-compose.env.yml restart"
echo "Status:             podman-compose -f podman-compose.env.yml ps"

if [[ -n "$CODESPACES" ]]; then
    echo "Ver port forwards:  gh codespace ports"
    echo "Parar Codespace:    gh codespace stop"
fi

echo ""
echo -e "${GREEN}🎉 Configuração concluída!${NC}"
echo -e "${BLUE}ℹ️  Consulte README.md para mais informações${NC}"

# Aguardar um pouco para ver se a interface web está respondendo
echo ""
echo "🔍 Testando conectividade da interface web..."
sleep 5

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080 2>/dev/null)

if [[ "$HTTP_STATUS" == "200" ]]; then
    echo -e "${GREEN}✅ Interface web está respondendo!${NC}"
elif [[ "$HTTP_STATUS" == "302" ]]; then
    echo -e "${GREEN}✅ Interface web está redirecionando (normal)${NC}"
else
    echo -e "${YELLOW}⚠️  Interface web ainda não está respondendo${NC}"
    echo "   Aguarde mais alguns minutos para inicialização completa"
fi
