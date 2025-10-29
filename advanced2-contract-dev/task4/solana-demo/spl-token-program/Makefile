# SPL Token Program Makefile

.PHONY: help install build deploy test clean dev stop lint format

# default target
help:
	@echo "SPL Token Program - Usage:"
	@echo ""
	@echo "  setup     - install all dependencies & tools"
	@echo "  install   - install Node.js dependencies"
	@echo "  build     - build Anchor program"
	@echo "  deploy    - deploy program to current net"
	@echo "  test      - run test"
	@echo "  dev       - launch development environment"
	@echo "  clean     - clean built files"
	@echo "  lint      - check code format"
	@echo "  format    - format code"
	@echo "  validator - launch local validator"
	@echo "  stop      - stop local validator"
	@echo ""
	@echo "  Docker command:"
	@echo "  docker-build  - build Docker image"
	@echo "  docker-run    - run Docker container"
	@echo "  docker-up     - start Docker Compose"
	@echo "  docker-down   - stop Docker Compose"
	@echo ""
	@echo "  Token management:"
	@echo "  token-create  - create new token"
	@echo "  token-info    - get token info"

# environment set up
setup:
	@echo "🔧 Set develoment environment..."
	@echo "Check Rust installed or not..."
	@which rustc || (echo "Please install Rust firstly: https://rustup.rs/" && exit 1)
	@echo "Check Solana CLI installed or not..."
	@which solana || (echo "Please install Solana CLI" && exit 1)
	@echo "Check Anchor installed or not..."
	@which anchor || (echo "Please install Anchor" && exit 1)
	@echo "Check Node.js dependencies..."
	@yarn install
	@echo "Configure Solana as localnet..."
	@solana config set --url localhost
	@echo "✅ Set development environment complete!"

# install dependencies
install:
	@echo "📦 Install dependencies..."
	@yarn install

# build program
build:
	@echo "🔨 Build program..."
	@anchor build

# Deploy program
deploy: build
	@echo "🚀 Deploy program..."
	@anchor deploy

# Run test
test:
	@echo "🧪 Run test..."
	@anchor test

# Clean built files
clean:
	@echo "🧹 Clean built files..."
	@anchor clean
	@rm -rf node_modules/.cache
	@rm -rf target/

# Launch development environment
dev:
	@echo "🚀 Launch development environment..."
	@echo "Please make sure run this cmd in another terminal: make validator"
	@yarn dev

# Launch local validator
validator:
	@echo "🔗 Launch Solana test validator..."
	@solana-test-validator --reset

# Stop local validator
stop:
	@echo "🛑 Stop validator..."
	@pkill -f solana-test-validator || true

# Code Lint
lint:
	@echo "🔍 Check code format..."
	@yarn lint

# Format code
format:
	@echo "✨ Format code..."
	@yarn lint:fix

# Docker command
docker-build:
	@echo "🐳 Build Docker image..."
	@docker build -t spl-token-program .

docker-run: docker-build
	@echo "🐳 Run Docker container..."
	@docker run -p 3000:3000 -p 8899:8899 spl-token-program

docker-up:
	@echo "🐳 Start Docker Compose..."
	@docker-compose up -d

docker-down:
	@echo "🐳 Stop Docker Compose..."
	@docker-compose down

# token management cmd
token-create:
	@echo "🪙 Create new token..."
	@yarn token:create

token-info:
	@echo "📊 Get token info..."
	@yarn token:info

# Launch all development environment quickly
quick-start: stop
	@echo "⚡ Launch all development environment quickly..."
	@echo "1. Launch validator..."
	@solana-test-validator --reset &
	@sleep 5
	@echo "2. Build & Deploy program..."
	@make deploy
	@echo "3. Launch frontend server..."
	@yarn dev

# reset environment
reset: stop clean
	@echo "🔄 Reset develoment environment..."
	@rm -f keypair.json mint-address.txt
	@make setup

# Check environment
check:
	@echo "🔍 Check environment..."
	@echo "Rust version:"
	@rustc --version
	@echo "Solana version:""
	@solana --version
	@echo "Anchor version:"
	@anchor --version
	@echo "Node.js version:"
	@node --version
	@echo "Yarn version:"
	@yarn --version
	@echo "Current Solana config:"
	@solana config get

# Delopy to devnet
deploy-devnet:
	@echo "🌐 Deploy to Devnet..."
	@solana config set --url devnet
	@solana airdrop 2
	@anchor deploy --provider.cluster devnet
	@echo "✅ Deploy to Devnet complete!"

# Deploy to mainnet
deploy-mainnet:
	@echo "⚠️  Deploy to Mainnet..."
	@read -p "Are you sure to deploy to Mainnet? (y/N): " confirm && [ "$$confirm" = "y" ]
	@solana config set --url mainnet-beta
	@anchor deploy --provider.cluster mainnet-beta
	@echo "✅ Delopy to Mainnet complete!"