# 🚀 Migration Guide: Implementing the Microservices Strategy

## 📋 **Implementation Roadmap**

### **Phase 1: Extract PKM Service (This Week)**

#### **Step 1: Create PKM Service Repository**

```bash
# Create new GitLab repository: pkm-embedder-service
cd ~/projects
mkdir pkm-embedder-service && cd pkm-embedder-service
git init
git remote add origin https://gitlab.com/your-username/pkm-embedder-service.git

# Copy existing PKM embedder code
cp -r /path/to/LibreChat/pkm-embedder/* .

# Create service structure
mkdir -p api src docker k8s
mv mcp-pkm-server.ts src/
mv rag-action-server.js src/
mv chunker.js embedder.js uploader.js src/
```

#### **Step 2: Add REST API Endpoints**

```typescript
// api/embed-api.ts
import express from "express";
import { PKMEmbedder } from "../src/embedder.js";

const app = express();
app.use(express.json());

// Delta embedding endpoint (triggered by GitLab CI)
app.post("/api/embed/delta", async (req, res) => {
  const { files, user_id } = req.body;
  const embedder = new PKMEmbedder(user_id);

  try {
    const result = await embedder.embedFiles(files.split(","));
    res.json({ success: true, embedded: result.length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Full re-embedding endpoint
app.post("/api/embed/full", async (req, res) => {
  const { user_id } = req.body;
  const embedder = new PKMEmbedder(user_id);

  try {
    const result = await embedder.embedAll();
    res.json({ success: true, embedded: result.length });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

app.listen(3003, () => {
  console.log("PKM Embedding API running on port 3003");
});
```

#### **Step 3: Containerize PKM Service**

```dockerfile
# Dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm install

# Copy source code
COPY src/ ./src/
COPY api/ ./api/

# Expose ports
EXPOSE 3001 3002 3003

# Start services
CMD ["npm", "run", "start:all"]
```

### **Phase 2: Setup Deployment Repository**

#### **Step 1: Create Deployment Repository**

```bash
# Create deployment repository
mkdir librechat-deployment && cd librechat-deployment
git init
git remote add origin https://gitlab.com/your-username/librechat-deployment.git

# Add LibreChat as submodule
git submodule add https://github.com/danny-avila/LibreChat.git LibreChat

# Add your notes as submodule (read-only for deployment)
git submodule add https://gitlab.com/your-username/my-notes.git notes

# Add PKM service as submodule
git submodule add https://gitlab.com/your-username/pkm-embedder-service.git pkm-service
```

#### **Step 2: Create Orchestration Files**

```yaml
# docker-compose.yml
version: "3.8"

services:
  # LibreChat API (from submodule)
  api:
    build:
      context: ./LibreChat
      dockerfile: Dockerfile
    environment:
      - JWT_SECRET=${JWT_SECRET}
      - OPENAI_API_KEY=${OPENAI_API_KEY}
      # ... other LibreChat env vars
    volumes:
      - ./librechat.yaml:/app/librechat.yaml:ro
    depends_on:
      - mongodb
      - pkm-service

  # Your PKM service
  pkm-service:
    build:
      context: ./pkm-service
      dockerfile: Dockerfile
    environment:
      - RAG_API_URL=http://rag_api:8000
      - JWT_SECRET=${JWT_SECRET}
      - PKM_USER_ID=${PKM_USER_ID}
    volumes:
      - ./notes:/notes:ro
      - pkm_temp:/app/temp
    depends_on:
      - rag_api
      - vector_db

  # RAG API and Vector DB (existing)
  rag_api:
    # ... existing configuration

  vector_db:
    # ... existing configuration

  mongodb:
    # ... existing configuration

volumes:
  pkm_temp:
  # ... other volumes
```

#### **Step 3: Configure LibreChat for PKM**

```yaml
# librechat.yaml
mcpServers:
  pkm-knowledge:
    command: node
    args: ["./pkm-service/src/mcp-pkm-server.js"]
    env:
      JWT_SECRET: "${JWT_SECRET}"
      PKM_USER_ID: "${PKM_USER_ID}"
      RAG_API_URL: "http://pkm-service:3001"
    timeout: 60000
    description: "Access to your personal knowledge base"

# Optional: Also configure Actions as backup
actions:
  allowedDomains: ["pkm-service"]

endpoints:
  openAI:
    actions:
      - name: "PKM Search"
        url: "http://pkm-service:3001/search"
```

### **Phase 3: Automate Notes Embedding**

#### **Step 1: Add CI/CD to Notes Repository**

```yaml
# .gitlab-ci.yml (in your notes repository)
stages:
  - detect-changes
  - embed
  - notify

variables:
  PKM_SERVICE_URL: "https://your-pkm-service.com"
  PKM_USER_ID: "your-user-id"

detect-changes:
  stage: detect-changes
  script:
    - echo "Detecting changed files..."
    - git diff --name-only $CI_COMMIT_BEFORE_SHA $CI_COMMIT_SHA > changed_files.txt
    - echo "Changed files:" && cat changed_files.txt
  artifacts:
    paths:
      - changed_files.txt
    expire_in: 1 hour
  only:
    - main

embed-changes:
  stage: embed
  script:
    - |
      if [ -s changed_files.txt ]; then
        echo "Embedding changed files..."
        CHANGED_FILES=$(cat changed_files.txt | tr '\n' ',' | sed 's/,$//')

        curl -X POST "${PKM_SERVICE_URL}/api/embed/delta" \
          -H "Authorization: Bearer $PKM_API_TOKEN" \
          -H "Content-Type: application/json" \
          -d "{\"files\": \"$CHANGED_FILES\", \"user_id\": \"$PKM_USER_ID\"}" \
          --fail

        echo "✅ Successfully embedded changed files"
      else
        echo "No files changed, skipping embedding"
      fi
  dependencies:
    - detect-changes
  only:
    - main

# Manual full re-embedding job
embed-full:
  stage: embed
  script:
    - |
      echo "Starting full re-embedding..."
      curl -X POST "${PKM_SERVICE_URL}/api/embed/full" \
        -H "Authorization: Bearer $PKM_API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"user_id\": \"$PKM_USER_ID\"}" \
        --fail
      echo "✅ Full re-embedding completed"
  when: manual
  only:
    - main
```

#### **Step 2: Setup Update Automation**

```bash
#!/bin/bash
# scripts/update-librechat.sh

set -e

echo "🔄 Updating LibreChat to latest main..."

# Update LibreChat submodule
cd LibreChat
git fetch origin
LATEST_COMMIT=$(git rev-parse origin/main)
CURRENT_COMMIT=$(git rev-parse HEAD)

if [ "$LATEST_COMMIT" != "$CURRENT_COMMIT" ]; then
    echo "📥 New LibreChat version available"
    git checkout origin/main

    cd ..
    git add LibreChat
    git commit -m "Update LibreChat to $(cd LibreChat && git log -1 --format='%h - %s')"

    echo "✅ LibreChat updated successfully"
    echo "🧪 Please test the deployment before pushing to production"
else
    echo "✅ LibreChat is already up to date"
fi

# Test deployment
echo "🧪 Running deployment test..."
docker-compose -f docker-compose.test.yml up --build -d
sleep 30
docker-compose -f docker-compose.test.yml down

echo "✅ Update complete!"
```

### **Phase 4: Production Deployment**

#### **GitLab CI/CD for Deployment**

```yaml
# .gitlab-ci.yml (in deployment repository)
stages:
  - test
  - build
  - deploy

variables:
  DOCKER_REGISTRY: "registry.gitlab.com/your-username"
  IMAGE_TAG: $CI_COMMIT_SHORT_SHA

test-deployment:
  stage: test
  script:
    - docker-compose -f docker-compose.test.yml up --build -d
    - sleep 30
    - curl -f http://localhost:3080/health
    - docker-compose -f docker-compose.test.yml down
  only:
    - main

build-images:
  stage: build
  script:
    - docker build -t $DOCKER_REGISTRY/pkm-service:$IMAGE_TAG ./pkm-service
    - docker push $DOCKER_REGISTRY/pkm-service:$IMAGE_TAG
  only:
    - main

deploy-production:
  stage: deploy
  script:
    - echo "Deploying to production..."
    - envsubst < docker-compose.production.yml > docker-compose.deploy.yml
    - docker-compose -f docker-compose.deploy.yml up -d
  environment:
    name: production
    url: https://your-librechat.com
  only:
    - main
  when: manual
```

## 🔧 **Maintenance Scripts**

### **LibreChat Update Automation**

```bash
#!/bin/bash
# scripts/weekly-update.sh

# Schedule this with cron: 0 2 * * 1 (every Monday at 2 AM)

echo "🔄 Weekly LibreChat update check..."

cd /path/to/librechat-deployment

# Update LibreChat
./scripts/update-librechat.sh

# Check for PKM service updates
cd pkm-service
git fetch origin
if [ $(git rev-list HEAD...origin/main --count) != 0 ]; then
    echo "📥 PKM service updates available"
    git pull origin main
    # Trigger rebuild and deployment
fi

cd ..

# Test the updated stack
echo "🧪 Testing updated stack..."
docker-compose -f docker-compose.test.yml up --build -d
sleep 60

# Health checks
if curl -f http://localhost:3080/health > /dev/null 2>&1; then
    echo "✅ LibreChat health check passed"
else
    echo "❌ LibreChat health check failed"
    exit 1
fi

if curl -f http://localhost:3001/health > /dev/null 2>&1; then
    echo "✅ PKM service health check passed"
else
    echo "❌ PKM service health check failed"
    exit 1
fi

docker-compose -f docker-compose.test.yml down

echo "✅ Weekly update complete!"
```

## 🚀 **Getting Started Today**

### **Quick Start (30 minutes)**

1. **Extract PKM service:**

   ```bash
   git clone https://gitlab.com/your-username/pkm-embedder-service.git
   # Copy code from LibreChat/pkm-embedder
   ```

2. **Create deployment repo:**

   ```bash
   git clone https://gitlab.com/your-username/librechat-deployment.git
   git submodule add https://github.com/danny-avila/LibreChat.git
   ```

3. **Test locally:**

   ```bash
   docker-compose up --build
   ```

4. **Setup CI/CD:**
   ```bash
   # Add .gitlab-ci.yml to notes repo
   # Configure GitLab variables: PKM_API_TOKEN, PKM_USER_ID
   ```

This strategy gives you maximum flexibility while maintaining clean separation of concerns. You can easily update LibreChat, migrate to other platforms, and automate your entire workflow! 🎉
