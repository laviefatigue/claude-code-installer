# Superman Claude - Containerized AI Workspace

## Vision

Skip the build step. Go straight to customizing.

| Layer | Tool | Target User |
|-------|------|-------------|
| **Normie** | Claude Desktop | Casual users |
| **Builder** | Claude Code in VS Code | "Woodworkers" who want to learn |
| **Superman** | Containerized Claude | Skip setup, just customize |

The Superman version is Claude Code running in Docker with:
- Pre-configured environment (no npm, no git, no terminal knowledge needed)
- One-time browser OAuth (not setup-token dance)
- Web launcher for workspace selection
- Self-improvement through conversation ("pull the Cloudflare tools")

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────┐
│                        LAUNCHER (Web UI)                                │
│  http://localhost:4096                                                 │
│                                                                        │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │
│  │  Project A  │  │  Project B  │  │  Personal   │  │   + New     │  │
│  │  client-web │  │  email-sys  │  │  Notes      │  │  Workspace  │  │
│  └─────────────┘  └─────────────┘  └─────────────┘  └─────────────┘  │
│                                                                        │
│  [ Start Chat ]           [ Manage Tools ]         [ Settings ]        │
└────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                        DOCKER CONTAINER                                 │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │  Claude Agent (claude-agent.js)                                   │ │
│  │    ↓                                                              │ │
│  │  Claude Agent SDK + OAuth Token                                   │ │
│  │    ↓                                                              │ │
│  │  MCP Server Registry (dynamic)                                    │ │
│  │    - Built-in: Read, Write, Edit, Bash, Glob, Grep               │ │
│  │    - Persistent: Cron, Memory, Gateway                           │ │
│  │    - User-added: Cloudflare, Coolify, Custom...                  │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐ │
│  │  Tool Registry (self-improving)                                   │ │
│  │    GET /marketplace/list                                         │ │
│  │    POST /marketplace/install?name=cloudflare-mcp                 │ │
│  │    DELETE /marketplace/uninstall?name=...                        │ │
│  └──────────────────────────────────────────────────────────────────┘ │
│                                                                        │
│  Volumes:                                                              │
│    - claude-credentials:/home/claw/.claude/    (OAuth token)          │
│    - workspaces:/home/claw/workspaces/         (Project files)        │
│    - mcp-plugins:/home/claw/.mcp/              (Installed tools)      │
│    - memory:/home/claw/memory/                 (Persistent memory)    │
└────────────────────────────────────────────────────────────────────────┘
```

---

## First-Run Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  STEP 1: LAUNCH                                                  │
│                                                                  │
│  docker run -d -p 4096:4096 --name superman-claude \            │
│    -v claude-credentials:/home/claw/.claude \                   │
│    -v workspaces:/home/claw/workspaces \                        │
│    ghcr.io/laviefatigue/superman-claude:latest                  │
│                                                                  │
│  Then visit: http://localhost:4096                               │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 2: AUTHENTICATE                                            │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐│
│  │         🔐 Connect Your Claude Account                     ││
│  │                                                            ││
│  │  Superman Claude needs to connect to your Anthropic       ││
│  │  account (Claude Pro, Max, or Teams).                     ││
│  │                                                            ││
│  │         [ Connect with Anthropic → ]                       ││
│  │                                                            ││
│  │  This uses OAuth - no API key needed.                     ││
│  │  Your credentials are stored locally.                     ││
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 3: CREATE WORKSPACE                                        │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐│
│  │  What would you like to work on?                           ││
│  │                                                            ││
│  │  [ ] Personal Assistant                                    ││
│  │      Memory, reminders, research                           ││
│  │                                                            ││
│  │  [ ] Web Development                                       ││
│  │      Node.js, React, APIs                                  ││
│  │                                                            ││
│  │  [ ] DevOps / Infrastructure                               ││
│  │      Cloudflare, Docker, servers                           ││
│  │                                                            ││
│  │  [ ] Custom                                                ││
│  │      Start blank, add tools as needed                      ││
│  │                                                            ││
│  │  Workspace name: [_____________________]                   ││
│  │                                                            ││
│  │         [ Create Workspace → ]                             ││
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  STEP 4: CHAT                                                    │
│                                                                  │
│  ┌────────────────────────────────────────────────────────────┐│
│  │  [web-dev] ~/workspaces/client-website                     ││
│  │                                                            ││
│  │  Hi! I'm your Superman Claude assistant. I have access to:││
│  │                                                            ││
│  │  🛠️  Built-in: Read, Write, Edit, Bash, Glob, Grep        ││
│  │  📦  Installed: Cloudflare DNS, Coolify Deploy            ││
│  │                                                            ││
│  │  Want me to add more tools? Just say "pull the X tools"   ││
│  │  or ask me anything to get started.                        ││
│  │                                                            ││
│  │  ─────────────────────────────────────────────────────────││
│  │                                                            ││
│  │  You: [_______________________________________________]    ││
│  └────────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────────┘
```

---

## Self-Improvement (Key Feature)

Claude can modify its own capabilities through conversation:

### Pull Tools
```
User: "I need to manage my Cloudflare DNS"

Claude: I can pull the Cloudflare MCP tools. This will let me:
        - Manage DNS records
        - Configure tunnels
        - View analytics

        Should I install them? [yes/no]

User: "yes"

Claude: *installs cloudflare-mcp to ~/.mcp/plugins/*
        Done! I now have access to:
        - mcp__cloudflare__list_dns_records
        - mcp__cloudflare__create_dns_record
        - mcp__cloudflare__create_tunnel
        ... (15 more tools)

        You'll need to set CLOUDFLARE_API_TOKEN in settings.
        Want me to guide you through that?
```

### Tool Discovery
```
User: "What tools can you install?"

Claude: Here are available MCP plugins:

        📦 INFRASTRUCTURE
        - cloudflare-mcp: DNS, tunnels, security
        - coolify-mcp: Deploy apps, manage servers
        - docker-mcp: Container management

        💬 COMMUNICATION
        - slack-mcp: Read/send Slack messages
        - gmail-mcp: Email management
        - telegram-mcp: Telegram bot control

        📊 PRODUCTIVITY
        - notion-mcp: Notes and databases
        - linear-mcp: Issue tracking
        - calendar-mcp: Google Calendar

        Want me to install any of these?
```

### Create Custom Skills
```
User: "Whenever I say 'deploy prod', run my deployment script"

Claude: I'll create a skill for that.

        Skill: /deploy-prod
        Action: cd ~/workspaces/client-website && ./deploy.sh production

        Created at ~/.claude/skills/deploy-prod/SKILL.md
        Now you can say "deploy prod" or /deploy-prod
```

---

## Tool Registry API

```yaml
# GET /marketplace/list
response:
  - name: cloudflare-mcp
    description: Manage Cloudflare DNS, tunnels, and security
    installed: true
    version: 1.2.0
    env_required: [CLOUDFLARE_API_TOKEN]

  - name: coolify-mcp
    description: Deploy and manage applications on Coolify
    installed: false
    version: 0.8.0
    env_required: [COOLIFY_TOKEN, COOLIFY_BASE_URL]

# POST /marketplace/install
request:
  name: cloudflare-mcp

response:
  success: true
  tools_added:
    - mcp__cloudflare__list_zones
    - mcp__cloudflare__create_dns_record
    # ...

# POST /marketplace/configure
request:
  name: cloudflare-mcp
  env:
    CLOUDFLARE_API_TOKEN: "xxxx"

# DELETE /marketplace/uninstall
request:
  name: cloudflare-mcp
```

---

## Workspace Presets

When creating a workspace, presets install relevant tools automatically:

### Personal Assistant
```yaml
tools:
  - memory-mcp (built-in)
  - cron-mcp (reminders)
skills:
  - /remember - Save to memory
  - /remind - Schedule reminder
  - /summarize - Summarize conversation
```

### Web Development
```yaml
tools:
  - Read, Write, Edit, Bash
  - cloudflare-mcp (optional)
  - coolify-mcp (optional)
skills:
  - /deploy - Run deployment
  - /test - Run test suite
  - /lint - Check code quality
```

### DevOps / Infrastructure
```yaml
tools:
  - cloudflare-mcp
  - coolify-mcp
  - docker-mcp
skills:
  - /status - Check all services
  - /deploy - Deploy to production
  - /logs - View application logs
```

---

## File Structure

```
D:\Work\superman-claude/
├── docker-compose.yml
├── Dockerfile
├── .env.example
│
├── launcher/                    # Web UI (served at :4096)
│   ├── index.html              # SPA entry
│   ├── auth.html               # OAuth callback
│   ├── static/
│   │   ├── app.js
│   │   └── styles.css
│   └── api/                    # Backend routes
│       ├── workspaces.js
│       ├── marketplace.js
│       └── chat.js
│
├── agent/                       # Claude Agent (from OpenClaw)
│   ├── claude-agent.js
│   ├── runner.js
│   └── providers/
│
├── marketplace/                 # Tool registry
│   ├── registry.js             # In-memory registry
│   ├── installer.js            # pip/npm install logic
│   └── catalog.json            # Available plugins
│
├── mcp/                         # Built-in MCP servers
│   ├── cron.js
│   ├── memory.js
│   └── gateway.js
│
└── skills/                      # Default skills
    ├── help/SKILL.md
    └── getting-started/SKILL.md
```

---

## Implementation Phases

### Phase 1: Core Container (Week 1)
- Fork OpenClaw structure
- Remove messaging adapters (WhatsApp, Telegram, etc.)
- Add web-based chat interface
- OAuth flow via `claude setup-token` redirect

### Phase 2: Launcher UI (Week 2)
- Workspace selector
- Auth status indicator
- Basic chat interface (streaming responses)
- Settings panel (env vars)

### Phase 3: Tool Marketplace (Week 3)
- Catalog of available MCP plugins
- Install/uninstall via API
- Env configuration per tool
- Dynamic MCP server loading

### Phase 4: Self-Improvement (Week 4)
- Agent can call marketplace API
- "Pull the X tools" workflow
- Custom skill creation
- Workspace persistence

---

## Key Differences from OpenClaw

| Aspect | OpenClaw | Superman Claude |
|--------|----------|-----------------|
| **Interface** | Messaging (WhatsApp, Telegram) | Web UI |
| **Auth** | Manual `claude setup-token` in container | Browser OAuth flow |
| **Tools** | Fixed config.js | Dynamic marketplace |
| **Workspaces** | Single workspace | Multiple, switchable |
| **Self-improvement** | No | Yes - pull tools, create skills |
| **Target user** | Developer | Power user, less technical |

---

---

## Mapping OpenClaw Patterns

Superman Claude uses the **exact same architecture** as OpenClaw, just with different adapters.

See [OPENCLAW_FLOW_MAP.md](OPENCLAW_FLOW_MAP.md) for detailed flow diagrams.

### Layer Mapping

| Layer | OpenClaw | Superman Claude |
|-------|----------|-----------------|
| **Adapters** | WhatsApp, Telegram, iMessage, Signal | Web UI (HTTP/WebSocket) |
| **Gateway** | Routes messages from messaging apps | Routes requests from browser |
| **AgentRunner** | Queue per session, FIFO processing | Same |
| **ClaudeAgent** | System prompt + streaming | Same + marketplace tools |
| **Providers** | Claude SDK with OAuth | Same |
| **MCP Servers** | cron, gateway, applescript | cron, gateway, **marketplace** |

### Same Deterministic Loops

**Message Queue** (unchanged):
```javascript
// queues: Map<sessionKey, { items: Run[], processing: boolean }>

async enqueueRun(sessionKey, message, adapter, chatId) {
  queue.items.push(run)
  processQueue(sessionKey)
}

async processQueue(sessionKey) {
  while (queue.items.length > 0) {
    const run = queue.items.shift()
    await executeRun(run)
  }
}
```

**Session Isolation** (unchanged):
```
workspace:superman:web:session:abc123
workspace:superman:web:session:def456
```

**Streaming Response** (unchanged):
```javascript
for await (const chunk of agent.run(...)) {
  if (chunk.type === 'text') { ws.send(chunk) }
  if (chunk.type === 'tool_use') { ws.send(chunk) }
  if (chunk.type === 'done') { break }
}
```

### New: Marketplace MCP Server

The key addition that enables self-improvement:

```javascript
// mcp/marketplace.js

export function createMarketplaceMcpServer(registry) {
  return {
    name: 'marketplace',
    tools: {
      'mcp__marketplace__list': async () => {
        return registry.listAvailable()
      },
      'mcp__marketplace__install': async ({ name }) => {
        await registry.install(name)
        return { success: true, tools: registry.getTools(name) }
      },
      'mcp__marketplace__uninstall': async ({ name }) => {
        await registry.uninstall(name)
        return { success: true }
      },
      'mcp__marketplace__configure': async ({ name, env }) => {
        await registry.configure(name, env)
        return { success: true }
      }
    }
  }
}
```

### Web Adapter (replaces messaging adapters)

```javascript
// adapters/web.js

export default class WebAdapter extends BaseAdapter {
  constructor(config) {
    super(config)
    this.sessions = new Map()
  }

  async start() {
    this.httpServer = http.createServer(this.handleHttp.bind(this))
    this.wss = new WebSocketServer({ server: this.httpServer })
    this.wss.on('connection', this.handleWs.bind(this))
    this.httpServer.listen(4096)
  }

  async handleWs(ws, req) {
    const sessionId = this.extractSessionId(req)
    this.sessions.set(sessionId, ws)

    ws.on('message', async (data) => {
      const { text, image } = JSON.parse(data)
      // Same event pattern as WhatsApp adapter
      this.emit('message', {
        platform: 'web',
        chatId: sessionId,
        text,
        image,
        isGroup: false
      })
    })
  }

  async sendMessage(chatId, text) {
    const ws = this.sessions.get(chatId)
    if (ws?.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type: 'text', content: text }))
    }
  }

  generateSessionKey(agentId, platform, message) {
    return `workspace:${agentId}:web:session:${message.chatId}`
  }
}
```

---

## Implementation: Minimal Diff from OpenClaw

1. **Fork OpenClaw** (`secure-openclaw/`)

2. **Remove messaging adapters**:
   - Delete: `adapters/whatsapp.js`, `telegram.js`, `imessage.js`, `signal.js`
   - Keep: `adapters/base.js`

3. **Add web adapter**:
   - Create: `adapters/web.js` (HTTP + WebSocket)

4. **Add marketplace**:
   - Create: `marketplace/registry.js`
   - Create: `marketplace/catalog.json`
   - Create: `mcp/marketplace.js`

5. **Update gateway.js**:
   - Replace adapter initialization with web adapter
   - Add registry to MCP servers
   - Inject marketplace tools to allowed list

6. **Add launcher UI**:
   - Create: `launcher/index.html`
   - Create: `launcher/chat.html`
   - Create: `launcher/static/app.js`

7. **Update Dockerfile**:
   - Same base (node:20-slim + Claude Code CLI)
   - Add pip for Python MCP plugins

---

## Open Questions

1. **OAuth flow**: Can we redirect `claude setup-token` browser auth back to our web UI?
2. **MCP hot-reload**: Can we add MCP servers without restarting the agent?
3. **Plugin format**: Standardize on .claude-plugin or simpler JSON manifest?
4. **Persistence**: SQLite vs flat files for workspace/tool state?
