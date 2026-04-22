# Void MCP Fix Notes — Mayveskii/void

## Version Mapping

| Artifact | Version | Notes |
|---|---|---|
| deb package | 1.99.30044 | distro hash `21c8d8ea1e46d97c5639a7cabda6c0e063cc8dd5` |
| GitHub repo `voideditor/void` | main branch | **newer** than deb — code diverges |

## Source → Bundle Mapping

| Patch | TypeScript source (GitHub) | Compiled bundle (local) |
|---|---|---|
| `_addUniquePrefix` | `src/vs/workbench/contrib/void/electron-main/mcpChannel.ts:234` | `out/main.js` → module `vs/workbench/contrib/void/electron-main/mcpChannel.js` |
| `defaultModelOptions` (o5) | `src/vs/workbench/contrib/void/common/modelCapabilities.ts:244` | `out/main.js` → module `vs/workbench/contrib/void/common/modelCapabilities.js` |
| `includeXMLToolDefinitions` | `src/vs/workbench/contrib/void/browser/convertToLLMMessageService.ts:591` | `out/vs/workbench/workbench.desktop.main.js` |

## Divergence Between GitHub and deb Bundle

**Bug 3 is different between GitHub source and installed bundle:**

| | GitHub (newer) | Installed deb (older) |
|---|---|---|
| `includeXMLToolDefinitions` | `= !specialToolFormat` | `= !systemMessage` (i.e. `_=!f`) |

GitHub version is **logically correct**: XML tool defs are needed when no API tool format is set (fallback). The deb version was wrong: it disabled XML tool defs based on systemMessage presence.

Our patch on the deb bundle: `_=!f||C.length>0` (= `!systemMessage || mcpTools.length > 0`).

**For PR to GitHub:** the fix should be different — just ensure `specialToolFormat` is set correctly (via o5 fix), and the existing `!specialToolFormat` logic handles the rest. The `includeXMLToolDefinitions` code on GitHub is already correct.

## Proper PR Strategy

1. Fork `voideditor/void`
2. Only 2 TS patches needed (not 3):
   - **mcpChannel.ts**: `_addUniquePrefix(serverName, base)` instead of `_addUniquePrefix(base)` + `Math.random()`
   - **modelCapabilities.ts**: add `specialToolFormat: 'openai-style'` to `defaultModelOptions`
3. `includeXMLToolDefinitions` — **no change needed** in GitHub source (already correct)
4. `removeMCPToolNamePrefix` in `mcpServiceTypes.ts` — already works with server-name prefix

## Checksum Patch

After modifying `workbench.desktop.main.js`, must update checksum in `product.json`:
```python
import json, hashlib, base64
with open('product.json') as f: d = json.load(f)
with open('out/vs/workbench/workbench.desktop.main.js', 'rb') as f:
    sha = base64.b64encode(hashlib.sha256(f.read()).digest()).decode().rstrip('=')
d['checksums']['vs/workbench/workbench.desktop.main.js'] = sha
with open('product.json', 'w') as f: json.dump(d, f, indent=2)
```
