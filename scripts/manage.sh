#!/bin/bash
set -e

COMMIT=$(git rev-parse --short HEAD 2>/dev/null || echo "latest")
TEMP_DIR="/tmp/sandbox"

case "$1" in
  setup)
    echo "🔍 Checking tools..."
    command -v docker >/dev/null || { echo "❌ Docker not found"; exit 1; }
    command -v git    >/dev/null || { echo "❌ Git not found";    exit 1; }
    mkdir -p "$TEMP_DIR"
    echo "📦 Pulling base images..."
    docker pull python:3.11-slim
    docker pull node:20-slim
    echo "✅ Setup complete!"
    ;;

  build)
    echo "🔨 Building images (commit: $COMMIT)..."
    docker build -t sandbox-python:$COMMIT -t sandbox-python containers/python/
    docker build -t sandbox-nodejs:$COMMIT -t sandbox-nodejs containers/nodejs/
    docker-compose build
    echo "✅ Build complete!"
    ;;

  test)
    echo "🚀 Starting services..."
    cd "$(dirname "$0")/.." && docker-compose up -d
    sleep 3

    echo "🧪 Testing Python..."
    curl -s -X POST http://localhost:3000/execute \
      -H "Content-Type: application/json" \
      -d '{"language":"python","code":"print(\"Hello from Python!\")"}' | grep -q "Hello" \
      && echo "✅ Python: PASSED" || echo "❌ Python: FAILED"

    echo "🧪 Testing Node.js..."
    curl -s -X POST http://localhost:3000/execute \
      -H "Content-Type: application/json" \
      -d '{"language":"nodejs","code":"console.log(\"Hello from Node.js!\")"}' | grep -q "Hello" \
      && echo "✅ Node.js: PASSED" || echo "❌ Node.js: FAILED"
    ;;

  clean)
    echo "🧹 Cleaning up..."
    docker-compose down -v 2>/dev/null || true
    docker rmi sandbox-python sandbox-nodejs 2>/dev/null || true
    rm -rf "$TEMP_DIR"
    echo "✅ Clean complete!"
    ;;

  logs)
    echo "📋 Tailing logs (ERROR/CRITICAL highlighted)..."
    docker-compose logs -f | sed 's/.*ERROR.*/\x1b[31m&\x1b[0m/;s/.*CRITICAL.*/\x1b[31m&\x1b[0m/'
    ;;

  *)
    echo "Usage: $0 {setup|build|test|clean|logs}"
    exit 1
    ;;
esac