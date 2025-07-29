#!/bin/bash

# Update LibreChat submodule to latest main
# Usage: ./scripts/update-librechat.sh [--force]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FORCE_UPDATE=false
BACKUP_BRANCH="backup-$(date +%Y%m%d-%H%M%S)"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --force)
      FORCE_UPDATE=true
      shift
      ;;
    -h|--help)
      echo "Usage: $0 [--force]"
      echo "  --force  Skip confirmation prompts"
      exit 0
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

echo -e "${BLUE}🔄 LibreChat Update Script${NC}"
echo "=============================="

# Check if we're in the right directory
if [[ ! -f ".gitmodules" ]] || [[ ! -d "LibreChat" ]]; then
    echo -e "${RED}❌ Error: Must be run from the deployment repo root${NC}"
    echo "Expected to find .gitmodules and LibreChat/ directory"
    exit 1
fi

# Check current status
echo -e "${BLUE}📊 Current Status:${NC}"
echo "Current LibreChat commit: $(cd LibreChat && git log -1 --format='%h - %s')"

# Fetch latest changes
echo -e "\n${BLUE}📥 Fetching latest changes...${NC}"
cd LibreChat
git fetch origin

# Get commit info
CURRENT_COMMIT=$(git rev-parse HEAD)
LATEST_COMMIT=$(git rev-parse origin/main)

if [[ "$CURRENT_COMMIT" == "$LATEST_COMMIT" ]]; then
    echo -e "${GREEN}✅ LibreChat is already up to date!${NC}"
    exit 0
fi

echo "Latest available commit: $(git log -1 --format='%h - %s' origin/main)"

# Show changes summary
echo -e "\n${YELLOW}📋 Changes Summary:${NC}"
git log --oneline --graph ${CURRENT_COMMIT}..${LATEST_COMMIT} | head -10
CHANGE_COUNT=$(git rev-list --count ${CURRENT_COMMIT}..${LATEST_COMMIT})
echo "Total commits: $CHANGE_COUNT"

# Confirmation prompt
if [[ "$FORCE_UPDATE" != "true" ]]; then
    echo -e "\n${YELLOW}⚠️  This will update LibreChat to the latest version.${NC}"
    echo "It's recommended to backup your current setup first."
    read -p "Continue with update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Update cancelled.${NC}"
        exit 0
    fi
fi

# Create backup branch in parent repo
cd ..
echo -e "\n${BLUE}💾 Creating backup branch: $BACKUP_BRANCH${NC}"
git checkout -b "$BACKUP_BRANCH"
git checkout main

# Update LibreChat submodule
echo -e "\n${BLUE}⬆️  Updating LibreChat submodule...${NC}"
cd LibreChat
git checkout origin/main

# Return to parent repo and commit update
cd ..
echo -e "\n${BLUE}💾 Committing submodule update...${NC}"
git add LibreChat
git commit -m "Update LibreChat to $(cd LibreChat && git log -1 --format='%h - %s')"

echo -e "\n${GREEN}✅ LibreChat updated successfully!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "  1. Test the deployment: docker-compose up --build"
echo "  2. If everything works: git push"
echo "  3. If issues occur: git checkout $BACKUP_BRANCH"

# Optional: Run quick health check
if command -v docker-compose > /dev/null 2>&1; then
    if [[ "$FORCE_UPDATE" != "true" ]]; then
        read -p "Run quick deployment test? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "\n${BLUE}🧪 Running deployment test...${NC}"
            docker-compose up --build -d
            sleep 30

            # Basic health check
            if curl -f http://localhost:${PORT:-3080}/health > /dev/null 2>&1; then
                echo -e "${GREEN}✅ Health check passed!${NC}"
            else
                echo -e "${YELLOW}⚠️  Health check failed - please verify manually${NC}"
            fi

            docker-compose down
        fi
    fi
fi

echo -e "\n${GREEN}🎉 Update complete!${NC}"