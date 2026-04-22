# Void MCP Tool Calling Fixes

3 bugs preventing MCP tool calling in Void Editor with OpenAI-compatible providers.

## Bug 1: Random tool name prefixes break LLM comprehension

**File:** `out/main.js` — `_addUniquePrefix()`  
**Problem:** `Math.random().toString(36).slice(2,8)` produces meaningless 6-char prefixes (e.g. `votxub_mesh_query`). LLMs cannot associate these with real actions and fall back to bash commands.  
**Fix:** Use MCP server name as deterministic prefix: `binary-mesh_mesh_query`. The existing `y9()` strip function (`t.split("_").slice(1).join("_")`) already handles this correctly.

## Bug 2: Unrecognized models get no tool format

**File:** `out/main.js` — `o5` default model options  
**Problem:** `o5` (defaults for unrecognized models) lacks `specialToolFormat`. OpenAI-compatible providers with custom model names get `specialToolFormat=undefined`, so tools are never sent via function-calling API.  
**Fix:** Add `specialToolFormat:"openai-style"` to `o5`. Known models (Claude, GPT, Gemini) have their own format in `modelOptions` and are unaffected.

## Bug 3: XML tool definitions disabled by systemMessage

**File:** `out/vs/workbench/workbench.desktop.main.js`  
**Problem:** `includeXMLToolDefinitions = !systemMessage`. When any system message is set, MCP tool XML descriptions are excluded from the prompt. LLM never sees available MCP tools.  
**Fix:** `includeXMLToolDefinitions = !systemMessage || mcpTools.length > 0`. Include XML tool definitions when MCP tools exist, regardless of systemMessage.
