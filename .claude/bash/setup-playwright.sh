#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
LOCAL_SETTINGS="${ROOT_DIR}/.claude/settings.local.json"

if [[ ! -f "${LOCAL_SETTINGS}" ]] || [[ ! -s "${LOCAL_SETTINGS}" ]]; then
  printf '%s\n' '{}' >"${LOCAL_SETTINGS}"
fi

tmp="$(mktemp)"
trap 'rm -f "${tmp}"' EXIT

JQ_FILTER='.
  | .mcpServers = (.mcpServers // {} | . + {
      "playwright": {
        "command": "npx",
        "args": ["@anthropic-ai/mcp-server-playwright", "--headless"]
      }
    })
'

if command -v jq >/dev/null 2>&1; then
  jq "${JQ_FILTER}" "${LOCAL_SETTINGS}" >"${tmp}"
elif command -v node >/dev/null 2>&1; then
  node - "${LOCAL_SETTINGS}" "${tmp}" <<'NODE'
const fs = require('fs');
const [,, inPath, outPath] = process.argv;
let raw = '';
try { raw = fs.readFileSync(inPath, 'utf8'); } catch {}
let obj = {};
try { obj = raw.trim() ? JSON.parse(raw) : {}; } catch (e) {
  console.error(`Invalid JSON in ${inPath}: ${e.message}`);
  process.exit(1);
}
obj = (obj && typeof obj === 'object' && !Array.isArray(obj)) ? obj : {};
obj.mcpServers = (obj.mcpServers && typeof obj.mcpServers === 'object' && !Array.isArray(obj.mcpServers)) ? obj.mcpServers : {};
obj.mcpServers.playwright = {
  command: 'npx',
  args: ['@anthropic-ai/mcp-server-playwright', '--headless']
};
fs.writeFileSync(outPath, JSON.stringify(obj, null, 2) + '\n');
NODE
else
  echo "Error: need 'jq' or 'node' to edit ${LOCAL_SETTINGS}" >&2
  exit 1
fi

mv "${tmp}" "${LOCAL_SETTINGS}"
trap - EXIT

echo "Configured Playwright MCP in ${LOCAL_SETTINGS}"
