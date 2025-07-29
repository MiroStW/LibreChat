# 🚀 LibreChat Deployment Scripts

This directory contains automation scripts for managing your LibreChat deployment with submodules.

## 📋 Available Scripts

### `deploy.sh` - Main Deployment Manager

The primary script for managing your LibreChat deployment.

```bash
# Start all services
./scripts/deploy.sh start

# Build and start services
./scripts/deploy.sh build

# Show service status
./scripts/deploy.sh status

# Show logs (all services)
./scripts/deploy.sh logs

# Show logs for specific service
./scripts/deploy.sh logs -s api

# Update all submodules
./scripts/deploy.sh update

# Run health checks
./scripts/deploy.sh health

# Backup current deployment
./scripts/deploy.sh backup

# Clean unused resources
./scripts/deploy.sh clean
```

**Available Commands:**

- `start` - Start all services
- `stop` - Stop all services
- `restart` - Restart all services
- `build` - Build and start services
- `logs` - Show service logs
- `status` - Show service status
- `update` - Update all submodules
- `backup` - Backup current deployment
- `health` - Run health checks
- `clean` - Clean up unused resources

**Options:**

- `-s, --service` - Target specific service
- `-f, --file` - Custom docker-compose file
- `-h, --help` - Show help

### `update-librechat.sh` - LibreChat Updates

Updates the LibreChat submodule to the latest version.

```bash
# Interactive update (recommended)
./scripts/update-librechat.sh

# Force update without prompts
./scripts/update-librechat.sh --force
```

**Features:**

- Shows change summary before updating
- Creates automatic backup branch
- Optional deployment testing
- Safety confirmations

### `update-pkm-service.sh` - PKM Service Updates

Updates the PKM AI Bridge submodule to the latest version.

```bash
# Interactive update
./scripts/update-pkm-service.sh

# Force update without prompts
./scripts/update-pkm-service.sh --force
```

## 🔧 Initial Setup

### 1. Create Environment File

```bash
# Copy template and customize
cp .env.example .env
# Edit .env with your settings (API keys, etc.)
```

### 2. First-Time Deployment

```bash
# Build and start all services
./scripts/deploy.sh build

# Check status
./scripts/deploy.sh status

# Run health checks
./scripts/deploy.sh health
```

### 3. Verify Setup

```bash
# Check LibreChat
curl http://localhost:3080/health

# Check PKM service
curl http://localhost:3001/health

# View logs
./scripts/deploy.sh logs
```

## 📅 Maintenance Workflows

### Weekly Updates

```bash
# Update all submodules
./scripts/deploy.sh update

# Test deployment
./scripts/deploy.sh build

# Run health checks
./scripts/deploy.sh health
```

### Backup Before Major Changes

```bash
# Create backup
./scripts/deploy.sh backup

# The backup includes:
# - Configuration files
# - MongoDB data
# - Submodule commit info
```

### Troubleshooting

```bash
# Check service status
./scripts/deploy.sh status

# View real-time logs
./scripts/deploy.sh logs -s api

# Restart specific service
./scripts/deploy.sh restart -s api

# Clean up resources
./scripts/deploy.sh clean
```

## 🔄 Submodule Management

### Understanding the Structure

```
LibreChat/                    # Your deployment repo
├── LibreChat/               # Official LibreChat (submodule)
├── pkm-ai-bridge/          # Your PKM service (submodule)
├── docker-compose.yml      # Orchestration config
└── scripts/                # Automation scripts
```

### Manual Submodule Operations

```bash
# Update LibreChat manually
cd LibreChat
git fetch origin
git checkout origin/main
cd ..
git add LibreChat
git commit -m "Update LibreChat"

# Update PKM service manually
cd pkm-ai-bridge
git fetch origin
git checkout origin/main
cd ..
git add pkm-ai-bridge
git commit -m "Update PKM service"
```

### Working on Submodules

```bash
# Make changes to PKM service
cd pkm-ai-bridge
# edit files, git add, git commit, git push
cd ..
# Update parent repo to track new commit
git add pkm-ai-bridge
git commit -m "Update PKM service to latest"
```

## 🚨 Emergency Procedures

### Rollback to Previous Version

```bash
# If you have backup branches
git branch -a  # List branches
git checkout backup-YYYYMMDD-HHMMSS

# Or rollback submodule
cd LibreChat
git checkout previous-commit-hash
cd ..
git add LibreChat
git commit -m "Rollback LibreChat"
```

### Reset Deployment

```bash
# Stop all services
./scripts/deploy.sh stop

# Clean resources
./scripts/deploy.sh clean

# Rebuild from scratch
./scripts/deploy.sh build
```

### Check Docker Resources

```bash
# View resource usage
docker system df

# View running containers
docker ps

# View all containers
docker ps -a

# Clean everything (DANGEROUS!)
docker system prune -a --volumes
```

## 📊 Monitoring & Health

### Regular Health Checks

```bash
# Automated health check
./scripts/deploy.sh health

# Manual checks
curl http://localhost:3080/health     # LibreChat
curl http://localhost:3001/health     # PKM service
curl http://localhost:8000/health     # RAG API
```

### Log Analysis

```bash
# All services
./scripts/deploy.sh logs

# Specific service
./scripts/deploy.sh logs -s api
./scripts/deploy.sh logs -s pkm-service
./scripts/deploy.sh logs -s mongodb

# Follow logs in real-time
docker-compose logs -f --tail=100
```

## 🔐 Security Considerations

### Environment Variables

- Always use strong, unique passwords
- Rotate API keys regularly
- Never commit `.env` files to git

### Backup Security

- Backups contain sensitive data
- Store backups securely
- Encrypt backups for long-term storage

### Network Security

- Use HTTPS in production
- Configure firewalls appropriately
- Monitor access logs

## 🛠️ Customization

### Adding New Scripts

1. Create script in `scripts/` directory
2. Make it executable: `chmod +x scripts/your-script.sh`
3. Follow the existing pattern for error handling and output

### Extending Deploy Script

The `deploy.sh` script can be extended with new commands by:

1. Adding the command to the help text
2. Adding a case in the argument parsing
3. Implementing the function

### Custom Docker Compose Files

```bash
# Use custom compose file
./scripts/deploy.sh start -f docker-compose.prod.yml
```

## 📚 Additional Resources

- [LibreChat Documentation](https://docs.librechat.ai/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Git Submodules Documentation](https://git-scm.com/book/en/v2/Git-Tools-Submodules)

## 🆘 Support

If you encounter issues:

1. Check the logs: `./scripts/deploy.sh logs`
2. Verify configuration: `./scripts/deploy.sh status`
3. Run health checks: `./scripts/deploy.sh health`
4. Check the troubleshooting section above
