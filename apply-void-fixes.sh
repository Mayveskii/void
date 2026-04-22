#!/bin/bash
# Void Editor MCP Tool Calling Fixes
# Version: 1.99.30044
# Applies 3 patches to fix MCP tool calling with OpenAI-compatible providers

set -e
VOID_APP="/usr/share/void/resources/app"
MAIN_JS="$VOID_APP/out/main.js"
WB_JS="$VOID_APP/out/vs/workbench/workbench.desktop.main.js"
PRODUCT_JSON="$VOID_APP/product.json"

cp "$MAIN_JS" "$MAIN_JS.bak"
cp "$WB_JS" "$WB_JS.bak"
cp "$PRODUCT_JSON" "$PRODUCT_JSON.bak"

# Patch 1: _addUniquePrefix — deterministic server name prefix instead of Math.random()
# Problem: Math.random().toString(36).slice(2,8) produces meaningless 6-char prefixes
#          (e.g. "votxub_mesh_query") that LLMs cannot associate with real actions
# Fix: Use MCP server name as prefix (e.g. "binary-mesh_mesh_query")
sed -i 's/_addUniquePrefix(t){return`${Math.random().toString(36).slice(2,8)}_${t}`}/_addUniquePrefix(e,t){return e+"_"+t}/' "$MAIN_JS"
sed -i 's/this\._addUniquePrefix(l)/this._addUniquePrefix(e,l)/g' "$MAIN_JS"
sed -i 's/this\._addUniquePrefix(u)/this._addUniquePrefix(e,u)/g' "$MAIN_JS"

# Patch 2: o5 default model options — add specialToolFormat for unrecognized models
# Problem: OpenAI-compatible provider with custom model name gets specialToolFormat=undefined
#          Tools are never sent to the model via function-calling API
# Fix: Default to "openai-style" so tools use standard OpenAI function calling
sed -i 's/o5={contextWindow:4096,reservedOutputTokenSpace:4096,cost:{input:0,output:0},downloadable:!1,supportsSystemMessage:!1,supportsFIM:!1,reasoningCapabilities:!1}/o5={contextWindow:4096,reservedOutputTokenSpace:4096,cost:{input:0,output:0},downloadable:!1,supportsSystemMessage:!1,supportsFIM:!1,specialToolFormat:"openai-style",reasoningCapabilities:!1}/' "$MAIN_JS"

# Patch 3: includeXMLToolDefinitions — enable when MCP tools exist
# Problem: XML tool definitions are disabled when systemMessage is set (!f)
#          LLM never sees MCP tool descriptions in system prompt
# Fix: Enable when MCP tools are available, regardless of systemMessage
sed -i 's/_=!f,C=this.mcpService.getMCPTools()/C=this.mcpService.getMCPTools(),_=!f||C.length>0/' "$WB_JS"

# Patch 4: Update product.json checksum (Void verifies file integrity)
python3 -c "
import json, hashlib, base64
with open('$PRODUCT_JSON') as f: d = json.load(f)
with open('$WB_JS', 'rb') as f:
    sha = base64.b64encode(hashlib.sha256(f.read()).digest()).decode().rstrip('=')
d['checksums']['vs/workbench/workbench.desktop.main.js'] = sha
with open('$PRODUCT_JSON', 'w') as f: json.dump(d, f, indent=2)
print(f'Updated checksum: {sha}')
"

echo "All patches applied. Restart Void."
