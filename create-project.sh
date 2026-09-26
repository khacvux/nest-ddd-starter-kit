#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# NestJS DDD Starter Kit - Project Generator
# GitHub: https://github.com/khacvux/nest-ddd-starter-kit
# -----------------------------------------------------------------------------

set -e

# Terminal colors
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

REPO_URL="https://github.com/khacvux/nest-ddd-starter-kit.git"
DEFAULT_PROJECT_NAME="my-nest-app"

# Helper for reading interactive inputs even when piped through curl | bash
prompt_input() {
  local prompt_text="$1"
  local default_val="$2"
  local user_val=""

  if [ -t 0 ]; then
    read -r -p "$(echo -e "${CYAN}?${NC} ${BOLD}${prompt_text}${NC} ${DIM}[${default_val}]${NC}: ")" user_val
  elif [ -r /dev/tty ]; then
    read -r -p "$(echo -e "${CYAN}?${NC} ${BOLD}${prompt_text}${NC} ${DIM}[${default_val}]${NC}: ")" user_val </dev/tty
  else
    user_val="$default_val"
  fi

  echo "${user_val:-$default_val}"
}

prompt_confirm() {
  local prompt_text="$1"
  local default_choice="$2" # "y" or "n"
  local choice_display="[y/N]"
  [ "$default_choice" = "y" ] && choice_display="[Y/n]"
  local user_choice=""

  if [ -t 0 ]; then
    read -r -p "$(echo -e "${CYAN}?${NC} ${BOLD}${prompt_text}${NC} ${DIM}${choice_display}${NC}: ")" user_choice
  elif [ -r /dev/tty ]; then
    read -r -p "$(echo -e "${CYAN}?${NC} ${BOLD}${prompt_text}${NC} ${DIM}${choice_display}${NC}: ")" user_choice </dev/tty
  else
    user_choice="$default_choice"
  fi

  user_choice=$(echo "${user_choice:-$default_choice}" | tr '[:upper:]' '[:lower:]')
  if [[ "$user_choice" =~ ^(y|yes)$ ]]; then
    return 0
  else
    return 1
  fi
}

print_banner() {
  echo -e "${CYAN}"
  echo "  ███╗   ██╗███████╗███████╗████████╗    ██████╗ ██████╗ ██████╗ "
  echo "  ████╗  ██║██╔════╝██╔════╝╚══██╔══╝    ██╔══██╗██╔══██╗██╔══██╗"
  echo "  ██╔██╗ ██║█████╗  ███████╗   ██║       ██║  ██║██║  ██║██║  ██║"
  echo "  ██║╚██╗██║██╔══╝  ╚════██║   ██║       ██║  ██║██║  ██║██║  ██║"
  echo "  ██║ ╚████║███████╗███████║   ██║       ██████╔╝██████╔╝██████╔╝"
  echo "  ╚═╝  ╚═══╝╚══════╝╚══════╝   ╚═╝       ╚═════╝ ╚═════╝ ╚═════╝ "
  echo -e "${BOLD}         Domain-Driven Design (DDD) & Hexagonal Starter Kit${NC}"
  echo -e "${DIM}         GitHub: https://github.com/khacvux/nest-ddd-starter-kit${NC}"
  echo ""
}

show_help() {
  print_banner
  echo -e "${BOLD}Usage:${NC}"
  echo "  bash create-project.sh [project-name] [options]"
  echo "  curl -fsSL https://raw.githubusercontent.com/khacvux/nest-ddd-starter-kit/main/create-project.sh | bash -s [project-name]"
  echo ""
  echo -e "${BOLD}Options:${NC}"
  echo "  -h, --help                 Show this help message and exit"
  echo "  -y, --yes                  Accept all defaults (non-interactive)"
  echo "  --npm                      Use npm as package manager"
  echo "  --pnpm                     Use pnpm as package manager"
  echo "  --yarn                     Use yarn as package manager"
  echo "  --skip-install             Skip installing dependencies"
  echo "  --skip-git                 Skip initializing a new git repository"
  echo "  --docker                   Automatically start PostgreSQL with Docker Compose"
  echo "  --skip-docker              Do not prompt or start Docker Compose"
  echo ""
  exit 0
}

# Parse CLI flags
PROJECT_NAME=""
PKG_MANAGER=""
AUTO_YES=false
SKIP_INSTALL=false
SKIP_GIT=false
START_DOCKER=false
SKIP_DOCKER=false

while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
      show_help
      ;;
    -y|--yes)
      AUTO_YES=true
      shift
      ;;
    --npm)
      PKG_MANAGER="npm"
      shift
      ;;
    --pnpm)
      PKG_MANAGER="pnpm"
      shift
      ;;
    --yarn)
      PKG_MANAGER="yarn"
      shift
      ;;
    --skip-install)
      SKIP_INSTALL=true
      shift
      ;;
    --skip-git)
      SKIP_GIT=true
      shift
      ;;
    --docker)
      START_DOCKER=true
      shift
      ;;
    --skip-docker)
      SKIP_DOCKER=true
      shift
      ;;
    -*)
      echo -e "${RED}Error:${NC} Unknown option $1"
      exit 1
      ;;
    *)
      if [ -z "$PROJECT_NAME" ]; then
        PROJECT_NAME="$1"
      else
        echo -e "${RED}Error:${NC} Unexpected argument: $1"
        exit 1
      fi
      shift
      ;;
  esac
done

print_banner

# Step 0: Pre-flight checks
if ! command -v git &> /dev/null; then
  echo -e "${RED}Error:${NC} git is required but not installed."
  exit 1
fi

if ! command -v node &> /dev/null; then
  echo -e "${RED}Error:${NC} Node.js is required but not installed."
  exit 1
fi

NODE_MAJOR_VER=$(node -v | cut -d'.' -f1 | sed 's/v//')
if [ "$NODE_MAJOR_VER" -lt 20 ]; then
  echo -e "${YELLOW}Warning:${NC} Recommended Node.js version is >= 20. Current version is $(node -v)."
fi

# Step 1: Prompt for project name if not supplied
if [ -z "$PROJECT_NAME" ]; then
  if [ "$AUTO_YES" = true ]; then
    PROJECT_NAME="$DEFAULT_PROJECT_NAME"
  else
    PROJECT_NAME=$(prompt_input "Enter project name" "$DEFAULT_PROJECT_NAME")
  fi
fi

# Resolve target directory and project name
if [[ "$PROJECT_NAME" = /* ]]; then
  TARGET_DIR="$PROJECT_NAME"
  PROJECT_NAME=$(basename "$PROJECT_NAME")
elif [[ "$PROJECT_NAME" == */* ]]; then
  TARGET_DIR="$(cd "$(dirname "$PROJECT_NAME")" 2>/dev/null && pwd)/$(basename "$PROJECT_NAME")"
  PROJECT_NAME=$(basename "$PROJECT_NAME")
else
  TARGET_DIR="$(pwd)/$PROJECT_NAME"
fi

# Sanitize project name for package.json and Docker
PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-_')
if [ -z "$PROJECT_NAME" ]; then
  echo -e "${RED}Error:${NC} Project name cannot be empty or contain invalid characters."
  exit 1
fi

if [ -d "$TARGET_DIR" ] && [ "$(ls -A "$TARGET_DIR" 2>/dev/null)" ]; then
  echo -e "${RED}Error:${NC} Directory '${TARGET_DIR}' already exists and is not empty."
  exit 1
fi

echo ""
echo -e "${GREEN}Creating a new NestJS DDD project in:${NC} ${BOLD}${TARGET_DIR}${NC}"
echo ""

# Step 2: Clone repository
echo -e "${CYAN}→${NC} Downloading starter kit from GitHub..."
git clone --depth=1 "$REPO_URL" "$TARGET_DIR" --quiet

cd "$TARGET_DIR"

# Step 3: Clean up starter kit metadata & reset git
echo -e "${CYAN}→${NC} Setting up project workspace..."
rm -rf .git
rm -f create-project.sh # Remove generator script from new project

# Step 4: Configure package.json
DB_SAFE_NAME=$(echo "$PROJECT_NAME" | tr '-' '_')

node -e "
  const fs = require('fs');
  const pkg = JSON.parse(fs.readFileSync('package.json', 'utf8'));
  pkg.name = '$PROJECT_NAME';
  pkg.version = '0.1.0';
  pkg.description = 'Enterprise NestJS project built with Domain-Driven Design';
  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2) + '\n');
"

# Step 5: Configure environment (.env)
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
  echo -e "${CYAN}→${NC} Initializing .env configuration..."
  cp .env.example .env
  
  # Customize database name in .env
  node -e "
    const fs = require('fs');
    let env = fs.readFileSync('.env', 'utf8');
    env = env.replace(/DB_NAME=nest_ddd_db/g, 'DB_NAME=${DB_SAFE_NAME}_db');
    fs.writeFileSync('.env', env);
  "
fi

# Customize docker-compose.yml container & database names
if [ -f "docker-compose.yml" ]; then
  node -e "
    const fs = require('fs');
    let dc = fs.readFileSync('docker-compose.yml', 'utf8');
    dc = dc.replace(/container_name: nest_ddd_postgres/g, 'container_name: ${DB_SAFE_NAME}_postgres');
    dc = dc.replace(/POSTGRES_DB: \$\{DB_NAME:-nest_ddd_db\}/g, 'POSTGRES_DB: \${DB_NAME:-${DB_SAFE_NAME}_db}');
    dc = dc.replace(/pg_isready -U \$\{DB_USER:-postgres\} -d \$\{DB_NAME:-nest_ddd_db\}/g, 'pg_isready -U \${DB_USER:-postgres} -d \${DB_NAME:-${DB_SAFE_NAME}_db}');
    fs.writeFileSync('docker-compose.yml', dc);
  "
fi

# Step 6: Select package manager
if [ -z "$PKG_MANAGER" ]; then
  if command -v pnpm &> /dev/null; then
    PKG_MANAGER="pnpm"
  elif command -v yarn &> /dev/null; then
    PKG_MANAGER="yarn"
  else
    PKG_MANAGER="npm"
  fi
fi

# Step 7: Install dependencies
if [ "$SKIP_INSTALL" = false ]; then
  DO_INSTALL=true
  if [ "$AUTO_YES" = false ]; then
    echo ""
    if ! prompt_confirm "Install project dependencies using ${PKG_MANAGER}?" "y"; then
      DO_INSTALL=false
    fi
  fi

  if [ "$DO_INSTALL" = true ]; then
    echo -e "${CYAN}→${NC} Installing dependencies with ${PKG_MANAGER}... (this may take a minute)"
    if [ "$PKG_MANAGER" = "pnpm" ]; then
      pnpm install
    elif [ "$PKG_MANAGER" = "yarn" ]; then
      yarn install
    else
      npm install
    fi
    echo -e "${GREEN}✓${NC} Dependencies installed successfully."
  else
    echo -e "${DIM}Skipped dependency installation.${NC}"
  fi
fi

# Step 8: Initialize fresh git repository
if [ "$SKIP_GIT" = false ]; then
  echo -e "${CYAN}→${NC} Initializing fresh Git repository..."
  git init -b main --quiet 2>/dev/null || git init --quiet
  git add .
  git commit -m "chore: initial commit from nest-ddd-starter-kit" --quiet
  echo -e "${GREEN}✓${NC} Git repository initialized."
fi

# Step 9: Optionally start PostgreSQL container
if [ "$SKIP_DOCKER" = false ] && command -v docker &> /dev/null; then
  if [ "$START_DOCKER" = true ]; then
    echo -e "${CYAN}→${NC} Starting PostgreSQL container..."
    docker compose up -d 2>/dev/null || docker-compose up -d
    echo -e "${GREEN}✓${NC} PostgreSQL container is running."
  elif [ "$AUTO_YES" = false ]; then
    echo ""
    if prompt_confirm "Start PostgreSQL database container with Docker now?" "n"; then
      echo -e "${CYAN}→${NC} Starting PostgreSQL container..."
      docker compose up -d 2>/dev/null || docker-compose up -d
      echo -e "${GREEN}✓${NC} PostgreSQL container is running."
    fi
  fi
fi

# Step 10: Finished message & next steps
RUN_CMD="npm run start:dev"
[ "$PKG_MANAGER" = "pnpm" ] && RUN_CMD="pnpm run start:dev"
[ "$PKG_MANAGER" = "yarn" ] && RUN_CMD="yarn start:dev"

echo ""
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}${BOLD} 🎉 Project '${PROJECT_NAME}' created successfully!${NC}"
echo -e "${GREEN}================================================================${NC}"
echo ""
echo -e "${BOLD}Next steps:${NC}"
echo -e "  1. ${CYAN}cd ${PROJECT_NAME}${NC}"
if [ "$SKIP_INSTALL" = true ]; then
  echo -e "  2. ${CYAN}${PKG_MANAGER} install${NC}"
  echo -e "  3. ${CYAN}${RUN_CMD}${NC}"
else
  echo -e "  2. ${CYAN}${RUN_CMD}${NC}"
fi
echo ""
echo -e "${BOLD}Available URLs:${NC}"
echo -e "  - Swagger API Docs:  ${CYAN}http://localhost:3000/api/docs${NC}"
echo -e "  - Health Check:      ${CYAN}http://localhost:3000/health${NC}"
echo ""
echo -e "${BOLD}AI Agents & Architecture:${NC}"
echo -e "  - Rules & Guidelines:  ${DIM}.agents/rules/architecture.md${NC}"
echo -e "  - DDD Feature Skill:   ${DIM}.agents/skills/ddd-nestjs/SKILL.md${NC}"
echo -e "  - Agent Instructions:  ${DIM}AGENTS.md & CLAUDE.md${NC}"
echo ""
echo -e "${BOLD}Happy Coding! 🚀${NC}"
echo ""
