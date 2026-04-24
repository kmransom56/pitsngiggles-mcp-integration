# MIT License
#
# Canonical HTTP paths for the Model Context Protocol (MCP) integration that
# exposes Pits n' Giggles live telemetry to AI clients.

# Primary path — matches app identity (F1, LAN, race engineering).
MCP_HTTP_PATH = "/f1-race-engineer-lan"

# Backward compatibility for configs and clients that still use the short name.
MCP_HTTP_PATH_LEGACY = "/mcp"

# Display name for Cursor/Claude/ChatGPT MCP server lists and examples.
MCP_SERVER_NAME = "f1-race-engineer-lan"
