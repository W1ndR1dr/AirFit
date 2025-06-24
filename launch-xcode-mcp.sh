#!/bin/bash
# Launch script for Xcode MCP Server

export PROJECTS_BASE_DIR="/Users/Brian/Coding Projects"
export DEBUG=false
export ALLOWED_PATHS="/Users/Brian/Coding Projects"
export PORT=8080

node "/Users/Brian/Library/Application Support/Claude/mcp-servers/xcode-mcp-server/dist/index.js"