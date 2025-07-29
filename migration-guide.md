# 🚀 Actual Migration Guide: LibreChat Deployment with Submodules

## 📋 **What We Actually Accomplished**

This guide documents the **actual migration process** completed to convert a LibreChat installation into a modern deployment repository with submodules.

---

## **🏁 Starting Point**

- **LibreChat repo**: Cloned/forked LibreChat with custom configurations
- **PKM service**: Already extracted to separate repository (`pkm-ai-bridge`)
- **Notes**: Personal markdown files in `/notes` (versioned in GitLab)
- **Goal**: Clean deployment architecture following microservices pattern

---

## **📦 Phase 1: Repository Restructuring**

### **Step 1: Prepare Current LibreChat Repository**

The existing LibreChat repository was converted to a deployment repository:

```bash
cd /path/to/your/LibreChat

# Move existing LibreChat code to subdirectory
mkdir LibreChat-temp
mv * LibreChat-temp/ 2>/dev/null || true  # Move all content
mv LibreChat-temp LibreChat

# Move custom docker-compose back to root
mv LibreChat/docker-compose.yml ./
```

### **Step 2: Convert to Submodule-Based Architecture**

Replace the copied LibreChat code with official submodule:

```bash
# Remove copied LibreChat code
rm -rf LibreChat/

# Add official LibreChat as submodule
git submodule add https://github.com/danny-avila/LibreChat.git LibreChat

# Add your PKM service as submodule
git submodule add https://github.com/YourUsername/pkm-ai-bridge.git pkm-ai-bridge

# Verify submodules
git submodule status
```

### **Step 3: Update Docker Compose Configuration**

Update `docker-compose.yml` to reference submodule paths:

```yaml
services:
  api:
    container_name: LibreChat
    build:
      context: ./LibreChat # <-- Now points to submodule
      dockerfile: Dockerfile
    # ... rest of configuration

  pkm-service:
    build:
      context: ./pkm-ai-bridge # <-- PKM service submodule
      dockerfile: Dockerfile
    # ... PKM configuration
```

---

## **🧹 Phase 2: Git History Cleanup**

### **The Problem**

Large database files (`data-node/`) were previously committed, bloating the repository to 103MB.

### **The Solution**

Remove database files from entire git history:

```bash
# Method 1: Using git filter-branch (built-in)
git filter-branch --index-filter 'git rm -rf --cached --ignore-unmatch data-node/' --prune-empty --tag-name-filter cat -- --all

# Aggressive garbage collection
git gc --aggressive --prune=now

# Verify size reduction
git count-objects -vH
```

**Results:**

- **Before**: 103MB repository
- **After**: 27MB repository (75% reduction)

### **Prevent Future Issues**

Create comprehensive `.gitignore`:

```bash
# .gitignore
# MongoDB database files (should never be committed)
data-node/
mongo-data/
mongodb-data/

# Environment files (contain secrets)
.env
.env.local
.env.production

# Docker volumes and runtime data
volumes/
logs/
temp/

# Backup files
*.backup
backup-*/
```

---

## **🤖 Phase 3: Automation Scripts**

### **Created Scripts in `/scripts/` Directory**

#### **1. Main Deployment Manager (`deploy.sh`)**

```bash
# Usage examples:
./scripts/deploy.sh start      # Start all services
./scripts/deploy.sh build      # Build and start
./scripts/deploy.sh logs       # Show logs
./scripts/deploy.sh update     # Update all submodules
./scripts/deploy.sh health     # Health checks
```

#### **2. LibreChat Updater (`update-librechat.sh`)**

```bash
# Safe LibreChat updates with backup
./scripts/update-librechat.sh

# Force update (skip confirmations)
./scripts/update-librechat.sh --force
```

#### **3. PKM Service Updater (`update-pkm-service.sh`)**

```bash
# Update PKM service to latest
./scripts/update-pkm-service.sh
```

### **Script Features**

- ✅ **Safety checks** before updates
- ✅ **Automatic backups** before major changes
- ✅ **Health checks** after deployments
- ✅ **Colored output** for better UX
- ✅ **Error handling** and rollback capabilities

---

## **⚙️ Phase 4: Configuration Management**

### **Environment Template (`.env.example`)**

```bash
# Copy and customize for your environment
cp .env.example .env

# Edit with your actual values
nano .env
```

### **Key Environment Variables**

```bash
# Application
PORT=3080
DOMAIN_CLIENT=http://localhost:3080

# Security
JWT_SECRET=your-super-secret-jwt-key
JWT_EXPIRES_IN=7d

# PKM AI Bridge
PKM_API_URL=http://pkm-service:3001
PKM_USER_ID=your-user-id

# Database
MONGO_URI=mongodb://mongodb:27017/LibreChat
```

---

## **🏗️ Final Architecture**

### **Repository Structure**

```
📁 LibreChat/ (Deployment Repository)
├── .git/                    # Clean, optimized git history (27MB)
├── .gitignore              # Prevents database commits
├── .env.example            # Environment template
├── docker-compose.yml      # Orchestration (points to submodules)
├── scripts/                # Automation toolkit
│   ├── deploy.sh           # Main deployment manager
│   ├── update-librechat.sh # LibreChat updater
│   ├── update-pkm-service.sh # PKM service updater
│   └── README.md           # Documentation
├── LibreChat/              # Official LibreChat submodule
└── pkm-ai-bridge/          # PKM service submodule
```

### **Submodule Status**

```bash
git submodule status
# 32081245... LibreChat (librechat-1.8.9-31-g32081245)
# 1d1d5ad... pkm-ai-bridge (heads/main)
```

---

## **🚀 Deployment Workflow**

### **First-Time Setup**

```bash
# Clone the deployment repository
git clone https://your-repo.com/LibreChat.git
cd LibreChat

# Initialize and update submodules
git submodule init
git submodule update

# Setup environment
cp .env.example .env
# Edit .env with your values

# Build and deploy
./scripts/deploy.sh build
```

### **Regular Updates**

```bash
# Update LibreChat to latest
./scripts/update-librechat.sh

# Update PKM service
./scripts/update-pkm-service.sh

# Deploy changes
./scripts/deploy.sh restart
```

### **Maintenance**

```bash
# Check service health
./scripts/deploy.sh health

# View logs
./scripts/deploy.sh logs

# Clean unused resources
./scripts/deploy.sh clean
```

---

## **✅ Benefits Achieved**

### **🎯 Upstream Sync**

- **Easy updates**: `./scripts/update-librechat.sh`
- **No merge conflicts**: LibreChat changes don't interfere with your configs
- **Version tracking**: Always know which LibreChat version you're running

### **🏗️ Microservices Architecture**

- **Loose coupling**: PKM service runs independently
- **Platform flexibility**: Easy to swap LibreChat for OpenWebUI later
- **Service isolation**: Issues in one service don't affect others

### **🔧 Automated Operations**

- **One-command deployment**: `./scripts/deploy.sh start`
- **Safe updates**: Automated backups and health checks
- **Easy rollbacks**: Git-based version control

### **📊 Optimized Repository**

- **75% size reduction**: 103MB → 27MB
- **Fast clones**: No more database files in git
- **Team-friendly**: Clean repo for collaboration

---

## **🔄 Future: Notes Auto-Embedding**

### **Next Phase: GitLab CI/CD Integration**

Add to your notes repository (`.gitlab-ci.yml`):

```yaml
stages:
  - detect-changes
  - embed

variables:
  PKM_SERVICE_URL: "https://your-pkm-service.com"

detect-changes:
  stage: detect-changes
  script:
    - git diff --name-only $CI_COMMIT_BEFORE_SHA $CI_COMMIT_SHA > changed_files.txt
  artifacts:
    paths: [changed_files.txt]
  only: [main]

embed-changes:
  stage: embed
  script:
    - |
      if [ -s changed_files.txt ]; then
        CHANGED_FILES=$(cat changed_files.txt | tr '\n' ',' | sed 's/,$//')
        curl -X POST "${PKM_SERVICE_URL}/api/embed/delta" \
          -H "Authorization: Bearer $PKM_API_TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"files\": \"$CHANGED_FILES\", \"user_id\": \"$PKM_USER_ID\"}"
      fi
  only: [main]
```

---

## **🎉 Migration Complete!**

Your LibreChat deployment now follows modern DevOps practices:

- ✅ **Submodule-based architecture** for flexibility
- ✅ **Automated deployment** and update scripts
- ✅ **Clean git history** optimized for collaboration
- ✅ **Production-ready** configuration management
- ✅ **Easy maintenance** with comprehensive tooling

**Ready for production deployment and team collaboration!** 🚀
