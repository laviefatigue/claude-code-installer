# OpenClaw Reverse Engineering

Complete component breakdown of the OpenClaw system framework.

---

## Component Inventory

```
secure-openclaw/
├── gateway.js              # Main orchestrator (422 lines)
├── cli.js                  # Interactive CLI + terminal chat (1228 lines)
├── config.js               # Runtime configuration
├── package.json            # Dependencies
├── Dockerfile              # Container build
├── docker-compose.yml      # Container orchestration
│
├── adapters/               # Platform connectors
│   ├── base.js             # Abstract interface (102 lines)
│   ├── whatsapp.js         # WhatsApp via Baileys
│   ├── telegram.js         # Telegram via node-telegram-bot-api
│   ├── imessage.js         # iMessage via imsg CLI (macOS)
│   └── signal.js           # Signal via signal-cli
│
├── agent/                  # AI execution engine
│   ├── claude-agent.js     # Core agent logic (500 lines)
│   └── runner.js           # Queue management (334 lines)
│
├── providers/              # Model backends
│   ├── base-provider.js    # Abstract interface (103 lines)
│   ├── claude-provider.js  # Claude Agent SDK (135 lines)
│   ├── opencode-provider.js # Opencode alternative
│   └── index.js            # Provider factory
│
├── commands/               # Slash command handling
│   └── handler.js          # /new, /status, /memory, /model, etc. (373 lines)
│
├── sessions/               # Session persistence
│   └── manager.js          # JSONL transcript storage (121 lines)
│
├── memory/                 # Long-term memory
│   └── manager.js          # MEMORY.md + daily logs (230 lines)
│
├── tools/                  # Custom MCP servers
│   ├── cron.js             # Scheduling (375 lines)
│   ├── gateway.js          # Cross-platform messaging (179 lines)
│   └── applescript.js      # macOS automation
│
└── skills/                 # Agent skills
    ├── design-system/
    ├── design-component/
    ├── design-audit/
    ├── design-polish/
    └── ui-inspiration/
```

---

## Component Details

### 1. Gateway (`gateway.js`) - THE ORCHESTRATOR

The gateway is the central hub that:
- Initializes all adapters
- Routes messages to the agent
- Manages tool approval flow
- Handles cron job execution
- Serves HTTP for health checks + QR codes

```javascript
class Gateway {
  constructor() {
    this.sessionManager = new SessionManager()
    this.agentRunner = new AgentRunner(this.sessionManager, config)
    this.commandHandler = new CommandHandler(this)
    this.adapters = new Map()
    this.pendingApprovals = new Map()
    this.composio = new Composio()  // Optional
    this.mcpServers = {}
  }

  async start() {
    await this.initMcpServers()         // Composio
    this.agentRunner.setMcpServers(this.mcpServers)

    // Initialize each adapter
    if (config.whatsapp.enabled) { ... }
    if (config.telegram.enabled) { ... }
    if (config.imessage.enabled) { ... }
    if (config.signal.enabled) { ... }

    this.startHttpServer()
  }

  setupAdapter(adapter, platform, config) {
    adapter.onMessage(async (message) => {
      // 1. Check pending approvals
      // 2. Check command handler
      // 3. Else: agentRunner.enqueueRun()
    })
  }

  // Tool approval via messaging
  waitForApproval(chatId, adapter, message, timeoutMs = 120000) { ... }
}
```

**Superman Claude needs**: Replace adapter initialization with WebAdapter

---

### 2. Adapters (`adapters/`) - PLATFORM CONNECTORS

#### Base Interface
```javascript
class BaseAdapter {
  async start() { throw Error }
  async stop() { throw Error }
  async sendMessage(chatId, text) { throw Error }
  onMessage(callback) { this.messageCallback = callback }

  shouldRespond(message, config) {
    // Security: Check allowedDMs, allowedGroups
  }

  generateSessionKey(agentId, platform, message) {
    return `agent:${agentId}:${platform}:${type}:${chatId}`
  }
}
```

#### Telegram Example (simplest adapter)
```javascript
class TelegramAdapter extends BaseAdapter {
  async start() {
    this.bot = new TelegramBot(this.config.token, { polling: true })
    this.botInfo = await this.bot.getMe()

    this.bot.on('message', (msg) => this.handleMessage(msg))
  }

  async sendMessage(chatId, text) {
    // Handle 4096 char limit
    await this.bot.sendMessage(chatId, text)
  }

  async handleMessage(msg) {
    // Extract: chatId, text, image, isGroup, sender, mentions
    // Check shouldRespond()
    this.emitMessage(message)
  }
}
```

**Superman Claude needs**: WebAdapter with WebSocket streaming

---

### 3. Agent (`agent/`) - AI EXECUTION ENGINE

#### ClaudeAgent (`claude-agent.js`)
```javascript
class ClaudeAgent extends EventEmitter {
  constructor(config) {
    this.memoryManager = new MemoryManager()
    this.cronMcpServer = createCronMcpServer()
    this.gatewayMcpServer = createGatewayMcpServer()
    this.provider = getProvider(config.provider, config)
    this.sessions = new Map()
  }

  async *run({ message, sessionKey, platform, chatId, image, mcpServers, canUseTool }) {
    // 1. Build system prompt (memory, cron, tools)
    // 2. Call provider.query()
    // 3. Yield chunks: text, tool_use, tool_result, done
  }

  buildSystemPrompt(memoryContext, sessionInfo, cronInfo) {
    return `You are Secure OpenClaw...
      ## Current Context
      ## Memory System
      ## Scheduling / Reminders
      ## Available Tools
      ...
    `
  }
}
```

#### AgentRunner (`runner.js`)
```javascript
class AgentRunner extends EventEmitter {
  constructor(sessionManager, config) {
    this.agent = new ClaudeAgent(config)
    this.queues = new Map()  // sessionKey -> { items: [], processing: false }
  }

  async enqueueRun(sessionKey, message, adapter, chatId, image) {
    queue.items.push(run)
    this.processQueue(sessionKey)
  }

  async processQueue(sessionKey) {
    while (queue.items.length > 0) {
      const run = queue.items.shift()
      await this.executeRun(run)
    }
  }

  async executeRun(run) {
    // Stream agent response to adapter
    for await (const chunk of this.agent.run(...)) {
      if (chunk.type === 'text') { adapter.sendMessage(...) }
    }
  }

  createMessagingCanUseTool(adapter, chatId) {
    // Tool approval callback for messaging platforms
  }
}
```

**Superman Claude needs**: Same agent, different system prompt additions

---

### 4. Providers (`providers/`) - MODEL BACKENDS

#### Base Interface
```javascript
class BaseProvider {
  constructor(config) {
    this.sessions = new Map()
    this.currentModel = config.model || null
  }

  setModel(model) { ... }
  getModel() { ... }
  getAvailableModels() { return [] }

  async *query(params) { throw Error }

  getSession(chatId) { ... }
  setSession(chatId, sessionId) { ... }
  abort(chatId) { return false }
}
```

#### Claude Provider
```javascript
class ClaudeProvider extends BaseProvider {
  getAvailableModels() {
    return [
      { id: 'claude-opus-4-6', label: 'Opus 4.6' },
      { id: 'claude-sonnet-4-5-20250929', label: 'Sonnet 4.5' },
      { id: 'claude-haiku-4-5-20251001', label: 'Haiku 4.5' },
    ]
  }

  async *query({ prompt, chatId, mcpServers, allowedTools, maxTurns, systemPrompt, canUseTool }) {
    const queryOptions = {
      allowedTools, maxTurns, mcpServers,
      permissionMode: 'bypassPermissions',
      includePartialMessages: true,
      canUseTool
    }

    if (existingSessionId) queryOptions.resume = existingSessionId

    for await (const chunk of query({ prompt, options: queryOptions })) {
      yield chunk  // Pass through to agent
    }
  }
}
```

**Superman Claude needs**: Same providers, no changes

---

### 5. Commands (`commands/handler.js`) - SLASH COMMANDS

```javascript
class CommandHandler {
  async execute(text, sessionKey, adapter, chatId) {
    const { command, args } = this.parse(text)

    switch (command) {
      case 'new':
      case 'reset':    return this.handleReset(sessionKey)
      case 'status':   return this.handleStatus(sessionKey)
      case 'memory':   return this.handleMemory(args)
      case 'queue':    return this.handleQueue()
      case 'help':     return this.handleHelp()
      case 'stop':     return this.handleStop(sessionKey)
      case 'model':    return this.handleModel(args, chatId, adapter)
      case 'provider': return this.handleProvider(args, chatId, adapter)
      default:         return { handled: false }
    }
  }
}
```

**Superman Claude needs**: Add `/marketplace`, `/workspace` commands

---

### 6. Sessions (`sessions/manager.js`) - PERSISTENCE

```javascript
class SessionManager {
  constructor() {
    this.sessions = new Map()
  }

  getSession(key) {
    if (!this.sessions.has(key)) {
      this.sessions.set(key, {
        key, lastRunId: null, lastActivity: Date.now(), transcript: []
      })
    }
    return this.sessions.get(key)
  }

  appendTranscript(key, entry) {
    // In-memory + JSONL file
    const line = JSON.stringify({ ...entry, timestamp: Date.now() })
    fs.appendFileSync(this.getTranscriptFilename(key), line + '\n')
  }

  getTranscript(key, limit = 50) {
    // Load from file if needed
  }
}
```

**Superman Claude needs**: Same, but add workspace context

---

### 7. Memory (`memory/manager.js`) - LONG-TERM MEMORY

```javascript
class MemoryManager {
  // Workspace: ~/secure-openclaw/
  // Memory dir: ~/secure-openclaw/memory/

  readTodayMemory()      // memory/YYYY-MM-DD.md
  readYesterdayMemory()  // memory/YYYY-MM-DD.md (yesterday)
  readLongTermMemory()   // MEMORY.md

  appendToDailyMemory(content)    // Today's log
  appendToLongTermMemory(content) // Curated memory

  getMemoryContext() {
    // Returns all memory for system prompt
  }

  searchMemory(query) {
    // Simple text search across files
  }
}
```

**Superman Claude needs**: Same, per-workspace memory

---

### 8. MCP Servers (`tools/`) - CUSTOM TOOLS

#### Cron (`tools/cron.js`)
```javascript
class CronScheduler extends EventEmitter {
  constructor() {
    this.jobs = new Map()
    this.timers = new Map()
    this.loadJobs()  // Persist to ~/.secure-openclaw/cron-jobs.json
  }

  scheduleDelayed({ message, delaySeconds, invokeAgent }) { ... }
  scheduleRecurring({ message, intervalSeconds, invokeAgent }) { ... }
  scheduleCron({ message, cron, invokeAgent }) { ... }
  list() { ... }
  cancel(jobId) { ... }
}

export function createCronMcpServer() {
  return createSdkMcpServer({
    name: 'cron',
    tools: [
      tool('schedule_delayed', ...),
      tool('schedule_recurring', ...),
      tool('schedule_cron', ...),
      tool('list_scheduled', ...),
      tool('cancel_scheduled', ...),
    ]
  })
}
```

#### Gateway (`tools/gateway.js`)
```javascript
export function createGatewayMcpServer() {
  return createSdkMcpServer({
    name: 'gateway',
    tools: [
      tool('send_message', ...),        // Send to any platform
      tool('list_platforms', ...),      // Connected platforms
      tool('get_queue_status', ...),    // Queue stats
      tool('get_current_context', ...),  // Current session info
      tool('list_sessions', ...),       // All sessions
      tool('broadcast_message', ...),   // Multi-target send
    ]
  })
}
```

**Superman Claude needs**: Add `tools/marketplace.js`

---

### 9. CLI (`cli.js`) - INTERACTIVE INTERFACE

```javascript
// Menu-driven interface
async function mainMenu() {
  1) Terminal chat    → terminalChat()
  2) Start gateway    → import('./gateway.js')
  3) Setup adapters   → setupWizard()
  4) Show config      → showConfig()
  5) Test connection  → testConnection()
  6) Change provider  → changeProvider()
  7) Exit
}

async function terminalChat() {
  // Full-featured terminal UI
  // - Spinner animation
  // - Input bar with box drawing
  // - Tool approval prompts
  // - Model switching via /model
  // - Cron job notifications
  // - Interrupt handling (Ctrl+C)
}
```

**Superman Claude needs**: Web UI instead of CLI

---

## What's Missing for Superman Claude

### Required Components

| Component | OpenClaw | Superman Claude | Status |
|-----------|----------|-----------------|--------|
| **WebAdapter** | N/A | HTTP + WebSocket adapter | **NEW** |
| **Marketplace MCP** | N/A | Plugin install/uninstall | **NEW** |
| **Plugin Registry** | N/A | Catalog + dynamic loading | **NEW** |
| **Launcher UI** | CLI | Web-based workspace selector | **NEW** |
| **Chat UI** | Terminal | Web-based streaming chat | **NEW** |
| **OAuth Web Flow** | Manual `claude setup-token` | Browser redirect | **NEW** |
| **Workspace Manager** | Single workspace | Multiple workspaces | **NEW** |

### Existing Components (Reuse)

| Component | OpenClaw | Superman Claude |
|-----------|----------|-----------------|
| ClaudeAgent | ✓ | Same + marketplace tools in system prompt |
| AgentRunner | ✓ | Same |
| Providers | ✓ | Same |
| SessionManager | ✓ | Same + workspace context |
| MemoryManager | ✓ | Same per workspace |
| CommandHandler | ✓ | Same + /marketplace, /workspace |
| CronMcpServer | ✓ | Same |
| GatewayMcpServer | ✓ | Modified for web |

---

## New Components Spec

### 1. WebAdapter (`adapters/web.js`)

```javascript
import { WebSocketServer } from 'ws'
import http from 'http'
import BaseAdapter from './base.js'

export default class WebAdapter extends BaseAdapter {
  constructor(config) {
    super(config)
    this.sessions = new Map()  // sessionId → WebSocket
    this.httpServer = null
    this.wss = null
  }

  async start() {
    this.httpServer = http.createServer(this.handleHttp.bind(this))
    this.wss = new WebSocketServer({ server: this.httpServer })

    this.wss.on('connection', (ws, req) => {
      const sessionId = this.extractSession(req)
      this.sessions.set(sessionId, ws)

      ws.on('message', (data) => {
        const { type, text, image } = JSON.parse(data)

        if (type === 'message') {
          this.emitMessage({
            chatId: sessionId,
            text,
            image,
            isGroup: false,
            sender: sessionId,
            platform: 'web'
          })
        }
      })

      ws.on('close', () => this.sessions.delete(sessionId))
    })

    this.httpServer.listen(4096)
  }

  async sendMessage(chatId, text) {
    const ws = this.sessions.get(chatId)
    if (ws?.readyState === 1) {
      ws.send(JSON.stringify({ type: 'text', content: text }))
    }
  }

  // Stream chunks to WebSocket
  async sendChunk(chatId, chunk) {
    const ws = this.sessions.get(chatId)
    if (ws?.readyState === 1) {
      ws.send(JSON.stringify(chunk))
    }
  }

  handleHttp(req, res) {
    // Serve static files (launcher UI)
    // OAuth callback
    // Health check
  }
}
```

### 2. Marketplace MCP (`tools/marketplace.js`)

```javascript
import { createSdkMcpServer, tool } from '@anthropic-ai/claude-agent-sdk'
import { z } from 'zod'
import PluginRegistry from '../marketplace/registry.js'

const registry = new PluginRegistry()

export function createMarketplaceMcpServer() {
  return createSdkMcpServer({
    name: 'marketplace',
    tools: [
      tool('list_available', 'List available MCP plugins', {},
        async () => ({ plugins: registry.listAvailable() })
      ),

      tool('list_installed', 'List installed plugins', {},
        async () => ({ plugins: registry.listInstalled() })
      ),

      tool('install', 'Install an MCP plugin', {
        name: z.string().describe('Plugin name'),
      }, async ({ name }) => {
        const result = await registry.install(name)
        return result
      }),

      tool('uninstall', 'Remove an MCP plugin', {
        name: z.string().describe('Plugin name'),
      }, async ({ name }) => {
        const result = await registry.uninstall(name)
        return result
      }),

      tool('configure', 'Set plugin environment variables', {
        name: z.string().describe('Plugin name'),
        env: z.record(z.string()).describe('Environment variables'),
      }, async ({ name, env }) => {
        const result = await registry.configure(name, env)
        return result
      }),
    ]
  })
}
```

### 3. Plugin Registry (`marketplace/registry.js`)

```javascript
import { exec } from 'child_process'
import { promisify } from 'util'
import fs from 'fs'
import path from 'path'

const execAsync = promisify(exec)
const PLUGINS_DIR = path.join(process.env.HOME, '.superman-claude', 'plugins')
const CATALOG_PATH = path.join(__dirname, 'catalog.json')

export default class PluginRegistry {
  constructor() {
    this.installed = new Map()
    this.catalog = this.loadCatalog()
    this.loadInstalled()
  }

  loadCatalog() {
    return JSON.parse(fs.readFileSync(CATALOG_PATH, 'utf-8'))
  }

  listAvailable() {
    return this.catalog.map(p => ({
      name: p.name,
      description: p.description,
      installed: this.installed.has(p.name),
      env_required: p.env || []
    }))
  }

  listInstalled() {
    return Array.from(this.installed.entries()).map(([name, data]) => ({
      name,
      ...data
    }))
  }

  async install(name) {
    const plugin = this.catalog.find(p => p.name === name)
    if (!plugin) return { success: false, error: 'Plugin not found' }
    if (this.installed.has(name)) return { success: false, error: 'Already installed' }

    // Install package
    await execAsync(plugin.install, { cwd: PLUGINS_DIR })

    // Track installation
    this.installed.set(name, {
      installedAt: Date.now(),
      entry: plugin.entry,
      env: {}
    })
    this.saveInstalled()

    return {
      success: true,
      tools: plugin.tools || [],
      env_required: plugin.env || []
    }
  }

  async uninstall(name) {
    if (!this.installed.has(name)) return { success: false, error: 'Not installed' }

    // Stop MCP server if running
    // Remove from registry
    this.installed.delete(name)
    this.saveInstalled()

    return { success: true }
  }

  configure(name, env) {
    if (!this.installed.has(name)) return { success: false, error: 'Not installed' }

    const data = this.installed.get(name)
    data.env = { ...data.env, ...env }
    this.installed.set(name, data)
    this.saveInstalled()

    return { success: true }
  }

  // Return MCP server configs for all installed plugins
  getMcpServers() {
    const servers = {}
    for (const [name, data] of this.installed) {
      if (data.env && Object.keys(data.env).length > 0) {
        servers[name] = {
          command: data.entry.split(' ')[0],
          args: data.entry.split(' ').slice(1),
          env: data.env
        }
      }
    }
    return servers
  }
}
```

### 4. Plugin Catalog (`marketplace/catalog.json`)

```json
[
  {
    "name": "cloudflare-mcp",
    "description": "Manage Cloudflare DNS, tunnels, and security",
    "install": "pip install cloudflare-mcp",
    "entry": "python -m cloudflare_mcp.server",
    "env": ["CLOUDFLARE_API_TOKEN"],
    "tools": [
      "mcp__cloudflare__list_zones",
      "mcp__cloudflare__create_dns_record",
      "mcp__cloudflare__delete_dns_record",
      "mcp__cloudflare__create_tunnel"
    ]
  },
  {
    "name": "coolify-mcp",
    "description": "Deploy and manage applications on Coolify",
    "install": "pip install coolify-mcp",
    "entry": "python -m coolify_mcp.server",
    "env": ["COOLIFY_TOKEN", "COOLIFY_BASE_URL"],
    "tools": [
      "mcp__coolify__list_applications",
      "mcp__coolify__deploy",
      "mcp__coolify__get_logs"
    ]
  },
  {
    "name": "slack-mcp",
    "description": "Read and send Slack messages",
    "install": "npm install -g @anthropic/slack-mcp",
    "entry": "slack-mcp-server",
    "env": ["SLACK_TOKEN"],
    "tools": [
      "mcp__slack__send_message",
      "mcp__slack__read_channel"
    ]
  }
]
```

---

## Dependencies

### OpenClaw (`package.json`)
```json
{
  "dependencies": {
    "@anthropic-ai/claude-agent-sdk": "^0.1.0",
    "@composio/core": "latest",
    "@opencode-ai/sdk": "latest",
    "@whiskeysockets/baileys": "^6.7.16",  // WhatsApp
    "node-telegram-bot-api": "^0.66.0",    // Telegram
    "dotenv": "^17.2.4",
    "oh-my-logo": "^0.4.0",                // CLI art
    "pino": "^9.6.0",                      // Logging
    "qrcode": "^1.5.4",                    // QR generation
    "qrcode-terminal": "^0.12.0",
    "zod": "^3.24.0"                       // Schema validation
  }
}
```

### Superman Claude Additions
```json
{
  "dependencies": {
    // Keep from OpenClaw
    "@anthropic-ai/claude-agent-sdk": "^0.1.0",
    "dotenv": "^17.2.4",
    "pino": "^9.6.0",
    "zod": "^3.24.0",

    // Replace messaging with web
    "ws": "^8.16.0",

    // Optional: keep composio for integrations
    "@composio/core": "latest"
  }
}
```

---

## Summary: Build Path

1. **Fork OpenClaw** to `superman-claude/`

2. **Delete** messaging adapters (keep base.js)

3. **Add** new files:
   - `adapters/web.js`
   - `tools/marketplace.js`
   - `marketplace/registry.js`
   - `marketplace/catalog.json`
   - `launcher/` (static web UI)

4. **Modify** existing:
   - `gateway.js` → Use WebAdapter, add marketplace MCP
   - `agent/claude-agent.js` → Add marketplace tools to system prompt
   - `commands/handler.js` → Add `/marketplace`, `/workspace`
   - `config.js` → Web config instead of messaging platforms
   - `Dockerfile` → Add pip for Python MCP plugins
   - `package.json` → Replace messaging deps with ws

5. **Total new code**: ~400 lines
   - WebAdapter: ~100 lines
   - Marketplace MCP: ~80 lines
   - Plugin Registry: ~120 lines
   - Launcher UI: ~100 lines (HTML/JS)
