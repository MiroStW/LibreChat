#!/bin/bash

# LibreChat Deployment Management Script
# Usage: ./scripts/deploy.sh <command> [options]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
COMPOSE_FILE="docker-compose.yml"
ENV_FILE=".env"

show_help() {
    echo -e "${BLUE}LibreChat Deployment Management${NC}"
    echo "================================="
    echo ""
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  start       Start all services"
    echo "  stop        Stop all services"
    echo "  restart     Restart all services"
    echo "  build       Build and start services"
    echo "  logs        Show service logs"
    echo "  status      Show service status"
    echo "  update      Update all submodules"
    echo "  backup      Backup current deployment"
    echo "  restore     Restore from backup"
    echo "  health      Run health checks"
    echo "  clean       Clean up unused resources"
    echo ""
    echo "Options:"
    echo "  -f, --file     Docker compose file (default: docker-compose.yml)"
    echo "  -e, --env      Environment file (default: .env)"
    echo "  -s, --service  Specific service name"
    echo "  -h, --help     Show this help"
    echo ""
    echo "Examples:"
    echo "  $0 start                    # Start all services"
    echo "  $0 logs -s api             # Show API logs"
    echo "  $0 build --service api     # Build only API service"
    echo "  $0 update                  # Update all submodules"
}

check_requirements() {
    # Check if required files exist
    if [[ ! -f "$COMPOSE_FILE" ]]; then
        echo -e "${RED}❌ Error: $COMPOSE_FILE not found${NC}"
        exit 1
    fi

    if [[ ! -f "$ENV_FILE" ]]; then
        echo -e "${YELLOW}⚠️  Warning: $ENV_FILE not found${NC}"
        echo "Creating from template..."
        if [[ -f ".env.example" ]]; then
            cp .env.example .env
            echo -e "${GREEN}✅ Created .env from template${NC}"
        else
            echo -e "${RED}❌ Error: No .env.example template found${NC}"
            exit 1
        fi
    fi

    # Check if Docker is running
    if ! docker info > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: Docker is not running${NC}"
        exit 1
    fi

    # Check if docker-compose is available
    if ! command -v docker-compose > /dev/null 2>&1; then
        echo -e "${RED}❌ Error: docker-compose is not installed${NC}"
        exit 1
    fi
}

start_services() {
    echo -e "${BLUE}🚀 Starting LibreChat services...${NC}"

    if [[ -n "$SERVICE" ]]; then
        docker-compose -f "$COMPOSE_FILE" up -d "$SERVICE"
        echo -e "${GREEN}✅ Service $SERVICE started${NC}"
    else
        docker-compose -f "$COMPOSE_FILE" up -d
        echo -e "${GREEN}✅ All services started${NC}"
    fi
}

stop_services() {
    echo -e "${BLUE}🛑 Stopping LibreChat services...${NC}"

    if [[ -n "$SERVICE" ]]; then
        docker-compose -f "$COMPOSE_FILE" stop "$SERVICE"
        echo -e "${GREEN}✅ Service $SERVICE stopped${NC}"
    else
        docker-compose -f "$COMPOSE_FILE" down
        echo -e "${GREEN}✅ All services stopped${NC}"
    fi
}

restart_services() {
    echo -e "${BLUE}🔄 Restarting LibreChat services...${NC}"

    if [[ -n "$SERVICE" ]]; then
        docker-compose -f "$COMPOSE_FILE" restart "$SERVICE"
        echo -e "${GREEN}✅ Service $SERVICE restarted${NC}"
    else
        docker-compose -f "$COMPOSE_FILE" restart
        echo -e "${GREEN}✅ All services restarted${NC}"
    fi
}

build_services() {
    echo -e "${BLUE}🔨 Building and starting LibreChat services...${NC}"

    if [[ -n "$SERVICE" ]]; then
        docker-compose -f "$COMPOSE_FILE" up --build -d "$SERVICE"
        echo -e "${GREEN}✅ Service $SERVICE built and started${NC}"
    else
        docker-compose -f "$COMPOSE_FILE" up --build -d
        echo -e "${GREEN}✅ All services built and started${NC}"
    fi
}

show_logs() {
    echo -e "${BLUE}📋 Showing service logs...${NC}"

    if [[ -n "$SERVICE" ]]; then
        docker-compose -f "$COMPOSE_FILE" logs -f --tail=100 "$SERVICE"
    else
        docker-compose -f "$COMPOSE_FILE" logs -f --tail=100
    fi
}

show_status() {
    echo -e "${BLUE}📊 Service Status:${NC}"
    docker-compose -f "$COMPOSE_FILE" ps

    echo -e "\n${BLUE}💾 Disk Usage:${NC}"
    docker system df

    echo -e "\n${BLUE}🔗 Network Status:${NC}"
    docker network ls | grep librechat || echo "No LibreChat networks found"
}

update_submodules() {
    echo -e "${BLUE}⬆️  Updating submodules...${NC}"

    # Update LibreChat
    if [[ -d "LibreChat" ]]; then
        echo "Updating LibreChat..."
        ./scripts/update-librechat.sh --force
    fi

    # Update PKM service
    if [[ -d "pkm-ai-bridge" ]]; then
        echo "Updating PKM service..."
        ./scripts/update-pkm-service.sh --force
    fi

    echo -e "${GREEN}✅ All submodules updated${NC}"
}

backup_deployment() {
    BACKUP_DIR="backups/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$BACKUP_DIR"

    echo -e "${BLUE}💾 Creating backup in $BACKUP_DIR...${NC}"

    # Backup configuration files
    cp docker-compose.yml "$BACKUP_DIR/"
    cp .env "$BACKUP_DIR/" 2>/dev/null || true

    # Backup data volumes
    docker run --rm -v "$(pwd)/data-node:/source" -v "$(pwd)/$BACKUP_DIR:/backup" alpine tar czf /backup/mongodb-data.tar.gz -C /source .

    # Create submodule info
    echo "LibreChat commit: $(cd LibreChat && git rev-parse HEAD)" > "$BACKUP_DIR/submodule-info.txt"
    echo "PKM service commit: $(cd pkm-ai-bridge && git rev-parse HEAD)" >> "$BACKUP_DIR/submodule-info.txt"

    echo -e "${GREEN}✅ Backup created in $BACKUP_DIR${NC}"
}

health_check() {
    echo -e "${BLUE}🏥 Running health checks...${NC}"

    # Check if services are running
    echo "Checking service status..."
    docker-compose -f "$COMPOSE_FILE" ps

    # Check LibreChat API
    if curl -f http://localhost:${PORT:-3080}/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ LibreChat API: Healthy${NC}"
    else
        echo -e "${RED}❌ LibreChat API: Unhealthy${NC}"
    fi

    # Check PKM service
    if curl -f http://localhost:3001/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PKM Service: Healthy${NC}"
    else
        echo -e "${YELLOW}⚠️  PKM Service: Not responding${NC}"
    fi

    # Check MongoDB
    if docker-compose -f "$COMPOSE_FILE" exec -T mongodb mongosh --eval "db.runCommand('ping')" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ MongoDB: Healthy${NC}"
    else
        echo -e "${RED}❌ MongoDB: Unhealthy${NC}"
    fi
}

clean_resources() {
    echo -e "${BLUE}🧹 Cleaning up unused resources...${NC}"

    # Remove stopped containers
    docker container prune -f

    # Remove unused images
    docker image prune -f

    # Remove unused networks
    docker network prune -f

    # Remove unused volumes (be careful!)
    read -p "Remove unused volumes? This may delete data! (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker volume prune -f
    fi

    echo -e "${GREEN}✅ Cleanup complete${NC}"
}

# Parse arguments
COMMAND=""
SERVICE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        start|stop|restart|build|logs|status|update|backup|restore|health|clean)
            COMMAND="$1"
            shift
            ;;
        -f|--file)
            COMPOSE_FILE="$2"
            shift 2
            ;;
        -e|--env)
            ENV_FILE="$2"
            shift 2
            ;;
        -s|--service)
            SERVICE="$2"
            shift 2
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check if command was provided
if [[ -z "$COMMAND" ]]; then
    echo -e "${RED}❌ Error: No command provided${NC}"
    show_help
    exit 1
fi

# Run pre-checks
check_requirements

# Execute command
case $COMMAND in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    build)
        build_services
        ;;
    logs)
        show_logs
        ;;
    status)
        show_status
        ;;
    update)
        update_submodules
        ;;
    backup)
        backup_deployment
        ;;
    health)
        health_check
        ;;
    clean)
        clean_resources
        ;;
    restore)
        echo -e "${YELLOW}Restore functionality not implemented yet${NC}"
        exit 1
        ;;
    *)
        echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
        show_help
        exit 1
        ;;
esac