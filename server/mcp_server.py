#!/usr/bin/env python3
"""AirFit MCP Server - Model Context Protocol server for Claude CLI.

This exposes AirFit's fitness tools to Claude CLI via MCP,
enabling the coach to query detailed data on demand.

Usage:
    # Add to Claude CLI config (~/.claude/settings.json):
    {
        "mcpServers": {
            "airfit": {
                "command": "python",
                "args": ["/path/to/airfit/server/mcp_server.py"]
            }
        }
    }

    # Or run standalone for testing:
    python mcp_server.py
"""

import asyncio
import json
import sys
from pathlib import Path

# Add server directory to path for imports
sys.path.insert(0, str(Path(__file__).parent))

import tools


async def handle_tool_call(name: str, arguments: dict) -> dict:
    """Handle a tool call and return result."""
    result = await tools.execute_tool(name, arguments)
    return {
        "success": result.success,
        "content": result.to_context_string(),
        "error": result.error
    }


def get_tool_definitions() -> list[dict]:
    """Get tool definitions in MCP format."""
    return [
        {
            "name": schema["name"],
            "description": schema["description"],
            "inputSchema": {
                "type": "object",
                "properties": schema["parameters"]["properties"],
                "required": []
            }
        }
        for schema in tools.TOOL_SCHEMAS
    ]


async def main():
    """Run MCP server using stdio transport."""
    # For now, implement a simple JSON-RPC style protocol
    # Full MCP implementation would use the mcp package

    print(json.dumps({
        "type": "server_info",
        "name": "airfit",
        "version": "1.0.0",
        "tools": get_tool_definitions()
    }), file=sys.stderr)

    # Read requests from stdin, write responses to stdout
    for line in sys.stdin:
        try:
            request = json.loads(line.strip())

            if request.get("method") == "tools/list":
                response = {
                    "id": request.get("id"),
                    "result": {"tools": get_tool_definitions()}
                }

            elif request.get("method") == "tools/call":
                params = request.get("params", {})
                tool_name = params.get("name")
                arguments = params.get("arguments", {})

                result = await handle_tool_call(tool_name, arguments)

                response = {
                    "id": request.get("id"),
                    "result": {
                        "content": [{"type": "text", "text": result["content"]}],
                        "isError": not result["success"]
                    }
                }

            else:
                response = {
                    "id": request.get("id"),
                    "error": {"code": -32601, "message": "Method not found"}
                }

            print(json.dumps(response), flush=True)

        except json.JSONDecodeError:
            print(json.dumps({
                "error": {"code": -32700, "message": "Parse error"}
            }), flush=True)
        except Exception as e:
            print(json.dumps({
                "error": {"code": -32603, "message": str(e)}
            }), flush=True)


if __name__ == "__main__":
    asyncio.run(main())
