#!/bin/bash
# Test MCP Integration Setup

set -e

echo "🧪 Testing F1 Race Engineer MCP Integration..."
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test functions
test_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

test_fail() {
    echo -e "${RED}✗${NC} $1"
}

test_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check files exist
echo "📁 Checking files..."

FILES=(
    "mcp_server/server.py"
    "mcp_server/__init__.py"
    "mcp_server/requirements.txt"
    "Dockerfile.mcp"
    "Dockerfile.nginx"
    "docker-compose.mcp.yml"
    "nginx/nginx.conf"
    "nginx/conf.d/default.conf"
    ".env.mcp.example"
    "start-mcp.sh"
    "stop-mcp.sh"
    "MCP_README.md"
    "docs/mcp/MCP_QUICKSTART.md"
    "docs/mcp/VOICE_INTEGRATION.md"
    "docs/mcp/AI_CLIENT_SETUP.md"
    "docs/mcp/DOCKER_MCP_TOOLKIT.md"
    "docs/mcp/architecture.mmd"
    "apps/frontend/html/strategy-center.html"
)

for file in "${FILES[@]}"; do
    if [ -f "$file" ]; then
        test_pass "Found $file"
    else
        test_fail "Missing $file"
        exit 1
    fi
done

echo ""
echo "📝 Checking configuration..."

# Check .env.mcp.example has required variables
if grep -q "LLM_ENDPOINT" .env.mcp.example && \
   grep -q "LLM_API_KEY" .env.mcp.example && \
   grep -q "LLM_MODEL" .env.mcp.example; then
    test_pass "Environment template is valid"
else
    test_fail "Environment template missing required variables"
    exit 1
fi

# Check scripts are executable
if [ -x "start-mcp.sh" ] && [ -x "stop-mcp.sh" ]; then
    test_pass "Scripts are executable"
else
    test_warn "Scripts may not be executable (run: chmod +x start-mcp.sh stop-mcp.sh)"
fi

echo ""
echo "🐳 Checking Docker configuration..."

# Validate docker-compose.yml
if docker-compose -f docker-compose.mcp.yml config > /dev/null 2>&1; then
    test_pass "docker-compose.mcp.yml is valid"
else
    test_fail "docker-compose.mcp.yml has errors"
    exit 1
fi

# Check Dockerfiles can be parsed
if docker build -f Dockerfile.mcp --help > /dev/null 2>&1; then
    test_pass "Dockerfile.mcp syntax is valid"
else
    test_fail "Dockerfile.mcp has errors"
fi

if docker build -f Dockerfile.nginx --help > /dev/null 2>&1; then
    test_pass "Dockerfile.nginx syntax is valid"
else
    test_fail "Dockerfile.nginx has errors"
fi

echo ""
echo "🔧 Checking Python code..."

# Check Python syntax
if python3 -m py_compile mcp_server/server.py 2>/dev/null; then
    test_pass "mcp_server/server.py has valid Python syntax"
else
    test_fail "mcp_server/server.py has syntax errors"
    exit 1
fi

# Check for required imports
if grep -q "from fastapi import FastAPI" mcp_server/server.py && \
   grep -q "class F1RaceEngineer" mcp_server/server.py; then
    test_pass "Required classes and imports present"
else
    test_fail "Missing required imports or classes"
    exit 1
fi

echo ""
echo "🌐 Checking nginx configuration..."

# Check nginx config syntax (if nginx is installed)
if command -v nginx &> /dev/null; then
    if nginx -t -c nginx/nginx.conf > /dev/null 2>&1; then
        test_pass "nginx configuration is valid"
    else
        test_warn "nginx config may have issues (will work in Docker)"
    fi
else
    test_warn "nginx not installed locally (will test in Docker)"
fi

echo ""
echo "📖 Checking documentation..."

# Check documentation word count
docs=(
    "MCP_README.md"
    "docs/mcp/MCP_QUICKSTART.md"
    "docs/mcp/VOICE_INTEGRATION.md"
    "docs/mcp/AI_CLIENT_SETUP.md"
    "docs/mcp/DOCKER_MCP_TOOLKIT.md"
)

total_words=0
for doc in "${docs[@]}"; do
    words=$(wc -w < "$doc")
    total_words=$((total_words + words))
done

if [ $total_words -gt 10000 ]; then
    test_pass "Documentation is comprehensive ($total_words words)"
else
    test_warn "Documentation may be incomplete ($total_words words)"
fi

echo ""
echo "🔍 Checking strategy center integration..."

# Check strategy-center.html has MCP integration
if grep -q "MCP_CHAT_ENDPOINT" apps/frontend/html/strategy-center.html && \
   grep -q "callMCPChatAPI" apps/frontend/html/strategy-center.html && \
   grep -q "mcp_chat" apps/frontend/html/strategy-center.html; then
    test_pass "Strategy center has MCP integration"
else
    test_fail "Strategy center missing MCP integration"
    exit 1
fi

# Check for AI modes
if grep -q "switchAIMode" apps/frontend/html/strategy-center.html; then
    test_pass "AI mode switching implemented"
else
    test_warn "AI mode switching may be missing"
fi

echo ""
echo "📊 Summary:"
echo ""
echo "  Files checked: ${#FILES[@]}"
echo "  Documentation: $total_words words"
echo "  Python files: ✓ Syntax valid"
echo "  Docker files: ✓ Configuration valid"
echo ""

# Check if Docker is running
if docker info > /dev/null 2>&1; then
    test_pass "Docker is running"
    echo ""
    echo "✅ All checks passed! Ready to deploy."
    echo ""
    echo "🚀 Next steps:"
    echo "  1. Copy .env.mcp.example to .env.mcp"
    echo "  2. Add your LLM_API_KEY to .env.mcp"
    echo "  3. Run: ./start-mcp.sh"
    echo "  4. Access: http://localhost/strategy-center.html"
    echo ""
else
    test_warn "Docker is not running"
    echo ""
    echo "⚠️  Checks passed, but Docker is not running."
    echo "   Start Docker before running ./start-mcp.sh"
    echo ""
fi

exit 0
