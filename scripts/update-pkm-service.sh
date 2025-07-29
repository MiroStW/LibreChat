#!/bin/bash

# Update PKM AI Bridge submodule to latest main
# Usage: ./scripts/update-pkm-service.sh [--force]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
FORCE_UPDATE=false

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

echo -e "${BLUE}🔄 PKM Service Update Script${NC}"
echo "=============================="

# Check if we're in the right directory
if [[ ! -f ".gitmodules" ]] || [[ ! -d "pkm-ai-bridge" ]]; then
    echo -e "${RED}❌ Error: Must be run from the deployment repo root${NC}"
    echo "Expected to find .gitmodules and pkm-ai-bridge/ directory"
    exit 1
fi

# Check current status
echo -e "${BLUE}📊 Current Status:${NC}"
echo "Current PKM service commit: $(cd pkm-ai-bridge && git log -1 --format='%h - %s')"

# Fetch latest changes
echo -e "\n${BLUE}📥 Fetching latest changes...${NC}"
cd pkm-ai-bridge
git fetch origin

# Get commit info
CURRENT_COMMIT=$(git rev-parse HEAD)
LATEST_COMMIT=$(git rev-parse origin/main)

if [[ "$CURRENT_COMMIT" == "$LATEST_COMMIT" ]]; then
    echo -e "${GREEN}✅ PKM service is already up to date!${NC}"
    exit 0
fi

echo "Latest available commit: $(git log -1 --format='%h - %s' origin/main)"

# Show changes summary
echo -e "\n${YELLOW}📋 Changes Summary:${NC}"
git log --oneline --graph ${CURRENT_COMMIT}..${LATEST_COMMIT}
CHANGE_COUNT=$(git rev-list --count ${CURRENT_COMMIT}..${LATEST_COMMIT})
echo "Total commits: $CHANGE_COUNT"

# Confirmation prompt
if [[ "$FORCE_UPDATE" != "true" ]]; then
    echo -e "\n${YELLOW}⚠️  This will update PKM service to the latest version.${NC}"
    read -p "Continue with update? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Update cancelled.${NC}"
        exit 0
    fi
fi

# Update PKM service submodule
echo -e "\n${BLUE}⬆️  Updating PKM service submodule...${NC}"
git checkout origin/main

# Return to parent repo and commit update
cd ..
echo -e "\n${BLUE}💾 Committing submodule update...${NC}"
git add pkm-ai-bridge
git commit -m "Update PKM service to $(cd pkm-ai-bridge && git log -1 --format='%h - %s')"

echo -e "\n${GREEN}✅ PKM service updated successfully!${NC}"
echo -e "${BLUE}📝 Next steps:${NC}"
echo "  1. Test the deployment: docker-compose up --build pkm-service"
echo "  2. If everything works: git push"

echo -e "\n${GREEN}🎉 Update complete!${NC}"