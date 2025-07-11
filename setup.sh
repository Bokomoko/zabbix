#!/bin/bash

# Script de Configuração Automática do Zabbix
# Autor: Projeto Zabbix Rede Doméstica
# Versão: 1.0

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Função para print colorido
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERRO]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Função para detectar IP local
get_local_ip() {
    local ip=$(ip route get 8.8.8.8 | grep -oP 'src \K\S+' 2>/dev/null || echo "")
    if [[ -z "$ip" ]]; then
        ip=$(hostname -I | awk '{print $1}' 2>/dev/null || echo "127.0.0.1")
    fi
    echo "$ip"
}

# Verificar se Docker está instalado
check_docker() {
    if ! command -v docker &> /dev/null; then
        print_error "Docker não está instalado. Por favor, instale o Docker primeiro."
        echo "Instruções: https://docs.docker.com/engine/install/"
        exit 1
    fi

    if ! command -v docker-compose &> /dev/null; then
        print_error "Docker Compose não está instalado. Por favor, instale o Docker Compose primeiro."
        echo "Instruções: https://docs.docker.com/compose/install/"
        exit 1
    fi

    print_status "Docker e Docker Compose encontrados ✓"
}

# Verificar recursos do sistema
check_resources() {
    local mem_gb=$(free -g | awk '/^Mem:/{print $2}')
    local disk_gb=$(df -BG . | awk 'NR==2{print $4}' | sed 's/G//')

    if [[ $mem_gb -lt 4 ]]; then
        print_warning "Sistema tem apenas ${mem_gb}GB de RAM. Recomendado: 4GB+"
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    if [[ $disk_gb -lt 20 ]]; then
        print_warning "Pouco espaço em disco disponível: ${disk_gb}GB. Recomendado: 20GB+"
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi

    print_status "Recursos do sistema verificados ✓"
}

# Criar arquivo .env se não existir
create_env_file() {
    if [[ ! -f .env ]]; then
        print_status "Criando arquivo .env..."

        local server_ip=$(get_local_ip)

        echo "# Configuração gerada automaticamente em $(date)" > .env
        echo "# IP do servidor Zabbix" >> .env
        echo "ZABBIX_SERVER_IP=$server_ip" >> .env
        echo "" >> .env
        echo "# Configurações do banco de dados" >> .env
        echo "POSTGRES_USER=zabbix" >> .env
        echo "POSTGRES_PASSWORD=zabbix_$(openssl rand -hex 8)" >> .env
        echo "POSTGRES_DB=zabbix_db" >> .env
        echo "" >> .env
        echo "# Configurações de cache (ajuste conforme RAM)" >> .env
        echo "ZBX_CACHESIZE=2048M" >> .env
        echo "ZBX_HISTORYCACHESIZE=512M" >> .env
        echo "ZBX_HISTORYINDEXCACHESIZE=512M" >> .env
        echo "ZBX_TRENDCACHESIZE=512M" >> .env
        echo "ZBX_VALUECACHESIZE=512M" >> .env
        echo "" >> .env
        echo "# Outras configurações" >> .env
        echo "ZBX_MEMORYLIMIT=512M" >> .env
        echo "ZBX_HOSTNAME=zabbix-server-home" >> .env
        echo "ZBX_DEBUGLEVEL=3" >> .env
        echo "TZ=America/Sao_Paulo" >> .env

        print_status "Arquivo .env criado com IP do servidor: $server_ip"
        print_warning "Verifique o arquivo .env e ajuste as configurações se necessário"
    else
        print_status "Arquivo .env já existe ✓"
        print_status "Usando configurações existentes do arquivo .env"
        local current_ip=$(grep "ZABBIX_SERVER_IP" .env | cut -d'=' -f2)
        print_status "IP configurado no .env: $current_ip"
        print_warning "Verifique se o IP no arquivo .env está correto para seu ambiente"
        echo
        print_status "💡 Para reconfigurar do zero:"
        echo "   1. cp .env.example .env"
        echo "   2. nano .env (substitua valores marcados com ⚠️)"
    fi
}

# Criar diretório para certificados
create_cert_dir() {
    if [[ ! -d "cert" ]]; then
        mkdir -p cert
        print_status "Diretório cert/ criado para certificados SSL"
    fi
}

# Verificar se portas estão livres
check_ports() {
    local ports=(8080 8443 5432 10050 10051)
    local ports_in_use=()

    for port in "${ports[@]}"; do
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            ports_in_use+=($port)
        fi
    done

    if [[ ${#ports_in_use[@]} -gt 0 ]]; then
        print_warning "As seguintes portas estão em uso: ${ports_in_use[*]}"
        print_warning "Isso pode causar conflitos. Considere parar os serviços ou alterar as portas no .env"
        read -p "Continuar mesmo assim? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        print_status "Todas as portas necessárias estão livres ✓"
    fi
}

# Função principal de instalação
install_zabbix() {
    print_header "INSTALAÇÃO DO ZABBIX PARA REDE DOMÉSTICA"

    print_status "Verificando pré-requisitos..."
    check_docker
    check_resources

    print_status "Configurando ambiente..."
    create_env_file
    create_cert_dir
    check_ports

    print_status "Baixando imagens Docker/Podman..."
    if [[ -f "podman-compose.env.yml" ]]; then
        if command -v podman-compose &> /dev/null; then
            podman-compose -f podman-compose.env.yml pull
        else
            docker-compose -f podman-compose.env.yml pull
        fi
    else
        if command -v podman-compose &> /dev/null; then
            podman-compose pull
        else
            docker-compose -f podman-compose.yml pull
        fi
    fi

    print_status "Iniciando serviços Zabbix..."
    if [[ -f "podman-compose.env.yml" ]]; then
        if command -v podman-compose &> /dev/null; then
            podman-compose -f podman-compose.env.yml up -d
        else
            docker-compose -f podman-compose.env.yml up -d
        fi
    else
        if command -v podman-compose &> /dev/null; then
            podman-compose up -d
        else
            docker-compose -f podman-compose.yml up -d
        fi
    fi

    print_status "Aguardando inicialização dos serviços..."
    sleep 30

    # Verificar status dos serviços
    print_status "Verificando status dos serviços..."
    if [[ -f "podman-compose.env.yml" ]]; then
        if command -v podman-compose &> /dev/null; then
            podman-compose -f podman-compose.env.yml ps
        else
            docker-compose -f podman-compose.env.yml ps
        fi
    else
        if command -v podman-compose &> /dev/null; then
            podman-compose ps
        else
            docker-compose -f podman-compose.yml ps
        fi
    fi

    print_header "INSTALAÇÃO CONCLUÍDA!"

    local server_ip=$(get_local_ip)
    echo
    print_status "🌐 Interface Web:"
    echo "   HTTP:  http://$server_ip:8080"
    echo "   HTTPS: https://$server_ip:8443"
    echo
    print_status "🔐 Credenciais padrão:"
    echo "   Usuário: Admin"
    echo "   Senha:   zabbix"
    echo
    print_warning "⚠️  IMPORTANTE: Altere a senha padrão imediatamente após o login!"
    echo
    print_status "📝 Próximos passos:"
    echo "   1. Acesse a interface web"
    echo "   2. Faça login e altere a senha"
    echo "   3. Verifique se o host 'zabbix-server-home' está ativo"
    echo "   4. Configure outros dispositivos da sua rede"
    echo
    print_status "📖 Consulte o README.md para instruções detalhadas"
}

# Função para desinstalação
uninstall_zabbix() {
    print_header "DESINSTALAÇÃO DO ZABBIX"

    print_warning "Isso irá remover todos os containers e dados do Zabbix!"
    read -p "Tem certeza que deseja continuar? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Operação cancelada."
        exit 0
    fi

    print_status "Parando e removendo containers..."
    if [[ -f "docker-compose.env.yml" ]]; then
        docker-compose -f docker-compose.env.yml down -v
    else
        docker-compose down -v
    fi

    print_status "Removendo imagens Docker..."
    docker rmi $(docker images "zabbix/*" -q) 2>/dev/null || true
    docker rmi postgres:15.6-bullseye 2>/dev/null || true

    print_status "Limpando volumes órfãos..."
    docker volume prune -f

    print_status "Desinstalação concluída!"
}

# Função para mostrar status
show_status() {
    print_header "STATUS DO ZABBIX"

    if [[ -f "docker-compose.env.yml" ]]; then
        docker-compose -f docker-compose.env.yml ps
    else
        docker-compose ps
    fi

    echo
    print_status "Logs recentes:"
    if [[ -f "docker-compose.env.yml" ]]; then
        docker-compose -f docker-compose.env.yml logs --tail=10
    else
        docker-compose logs --tail=10
    fi
}

# Função para backup
backup_zabbix() {
    print_header "BACKUP DO ZABBIX"

    local backup_dir="backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    print_status "Criando backup do banco de dados..."
    docker exec zabbix_db pg_dump -U zabbix zabbix_db > "$backup_dir/database.sql"

    print_status "Criando backup dos volumes..."
    docker run --rm -v zbx_db15:/data -v "$(pwd)/$backup_dir":/backup alpine tar czf /backup/volume_data.tar.gz -C /data .

    print_status "Copiando arquivos de configuração..."
    cp docker-compose.yml "$backup_dir/" 2>/dev/null || true
    cp docker-compose.env.yml "$backup_dir/" 2>/dev/null || true
    cp .env "$backup_dir/" 2>/dev/null || true

    print_status "Backup criado em: $backup_dir"
}

# Menu principal
case "${1:-}" in
    install)
        install_zabbix
        ;;
    uninstall)
        uninstall_zabbix
        ;;
    status)
        show_status
        ;;
    backup)
        backup_zabbix
        ;;
    *)
        echo "Uso: $0 {install|uninstall|status|backup}"
        echo
        echo "Comandos disponíveis:"
        echo "  install   - Instalar e configurar o Zabbix"
        echo "  uninstall - Remover completamente o Zabbix"
        echo "  status    - Mostrar status dos serviços"
        echo "  backup    - Criar backup dos dados"
        echo
        exit 1
        ;;
esac
