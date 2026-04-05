#!/bin/bash
# Test MCP Integration - Comprehensive verification script

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
CHECK="✓"
CROSS="✗"

echo ""
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║     Pits N Giggles MCP Integration Test Suite                ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

FAILED_TESTS=0
PASSED_TESTS=0

# Test function
test_endpoint() {
    local name="$1"
    local url="$2"
    local expected="$3"
    
    echo -n "Testing ${name}... "
    
    response=$(curl -s -w "\n%{http_code}" "$url" 2>/dev/null || echo "000")
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" = "200" ] || [ "$http_code" = "201" ]; then
        if [ -n "$expected" ]; then
            if echo "$body" | grep -q "$expected"; then
                echo -e "${GREEN}${CHECK} PASS${NC}"
                ((PASSED_TESTS++))
            else
                echo -e "${RED}${CROSS} FAIL${NC} (unexpected response)"
                ((FAILED_TESTS++))
            fi
        else
            echo -e "${GREEN}${CHECK} PASS${NC}"
            ((PASSED_TESTS++))
        fi
    else
        echo -e "${RED}${CROSS} FAIL${NC} (HTTP $http_code)"
        ((FAILED_TESTS++))
    fi
}

echo -e "${BLUE}[1/4] Testing Pits N Giggles Backend${NC}"
test_endpoint "Backend Health" "http://localhost:4768/health" ""
test_endpoint "Telemetry Info" "http://localhost:4768/telemetry-info" ""
test_endpoint "Race Info" "http://localhost:4768/race-info" ""
echo ""

echo -e "${BLUE}[2/4] Testing MCP Server${NC}"
test_endpoint "MCP Health" "http://localhost:80/health" "healthy"
test_endpoint "MCP Root" "http://localhost:80/" "status"
echo ""

echo -e "${BLUE}[3/4] Testing Web UIs${NC}"
test_endpoint "Driver View" "http://localhost:4768/" "<!DOCTYPE html>"
test_endpoint "Engineer View" "http://localhost:4768/eng-view" "<!DOCTYPE html>"
test_endpoint "Strategy Center" "http://localhost:4768/strategy-center" "<!DOCTYPE html>"
test_endpoint "Voice Strategy" "http://localhost:4768/voice-strategy-center" "<!DOCTYPE html>"
echo ""

echo -e "${BLUE}[4/4] Testing Docker Services${NC}"
if command -v docker &> /dev/null; then
    if docker ps | grep -q "f1-race-engineer-mcp"; then
        echo -e "${GREEN}${CHECK} MCP Container Running${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${YELLOW}⚠ MCP Container Not Running (may be native mode)${NC}"
    fi
    
    if docker ps | grep -q "f1-nginx-proxy"; then
        echo -e "${GREEN}${CHECK} Nginx Container Running${NC}"
        ((PASSED_TESTS++))
    else
        echo -e "${YELLOW}⚠ Nginx Container Not Running (may be native mode)${NC}"
    fi
else
    echo -e "${YELLOW}⚠ Docker not available${NC}"
fi
echo ""

# Summary
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                     Test Summary                              ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""
echo -e "${GREEN}Passed: ${PASSED_TESTS}${NC}"
echo -e "${RED}Failed: ${FAILED_TESTS}${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}${CHECK} All tests passed! System is ready.${NC}"
    echo ""
    echo "Access Points:"
    echo "  - Strategy Center: http://localhost:4768/strategy-center"
    echo "  - Voice Strategy: http://localhost:4768/voice-strategy-center"
    echo "  - MCP API: http://localhost:80/api/chat"
    echo ""
    exit 0
else
    echo -e "${RED}${CROSS} Some tests failed. Check configuration.${NC}"
    echo ""
    echo "Troubleshooting:"
    echo "  1. Ensure all services are running: ./start.sh"
    echo "  2. Check logs: docker-compose -f docker-compose.mcp.yml logs"
    echo "  3. Verify .env.mcp configuration"
    echo ""
    exit 1
fi
