# OpenClaw Flow Map

This maps the deterministic and dynamic loops in OpenClaw's architecture. Superman Claude will follow these same patterns.

---

## System Layers

```
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 1: ADAPTERS (Entry Points)                                        │
│                                                                         │
│ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐       │
│ │  WhatsApp   │ │  Telegram   │ │   iMessage  │ │   Signal    │       │
│ │   Adapter   │ │   Adapter   │ │   Adapter   │ │   Adapter   │       │
│ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘       │
│        │               │               │               │               │
│        └───────────────┴───────────────┴───────────────┘               │
│                                │                                        │
│                    { platform, chatId, text, image }                   │
└────────────────────────────────┼────────────────────────────────────────┘
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 2: GATEWAY (Router)                                               │
│                                                                         │
│  gateway.js                                                             │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  DETERMINISTIC: Message Routing                                   │  │
│  │                                                                   │  │
│  │  1. adapter.onMessage(message) ──▶ Check security (allowedDMs)   │  │
│  │  2. Check pending approvals ──────▶ Resolve if waiting           │  │
│  │  3. Check command handler ────────▶ /help, /new, /status, /stop  │  │
│  │  4. Else: agentRunner.enqueueRun() ─────────────────────────────▶│  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  Components:                                                            │
│    - SessionManager: Track session state, transcripts                  │
│    - CommandHandler: Slash commands                                    │
│    - pendingApprovals: Map<chatId, {resolve, timeout}>                 │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 3: AGENT RUNNER (Queue + Execution)                               │
│                                                                         │
│  runner.js                                                              │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  DETERMINISTIC: Queue Processing                                  │  │
│  │                                                                   │  │
│  │  1. enqueueRun() ──▶ Create run object, add to session queue     │  │
│  │  2. processQueue() ──▶ FIFO, one at a time per session           │  │
│  │  3. executeRun() ──▶ Call agent.run(), stream chunks             │  │
│  │  4. Send response ──▶ adapter.sendMessage()                       │  │
│  │  5. Cleanup ──▶ Remove empty queues after 60s                     │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  Queue Structure:                                                       │
│    queues: Map<sessionKey, { items: Run[], processing: boolean }>      │
│                                                                         │
│    Run = {                                                              │
│      id, sessionKey, message, adapter, chatId,                         │
│      image, mcpServers, resolve, reject, queuedAt                      │
│    }                                                                    │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 4: CLAUDE AGENT (Execution Engine)                                │
│                                                                         │
│  claude-agent.js                                                        │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  DYNAMIC: Agent Loop (the "thinking")                             │  │
│  │                                                                   │  │
│  │  1. Build system prompt (memory, session, cron)                   │  │
│  │  2. provider.query() ──▶ Claude Agent SDK streaming               │  │
│  │  3. For each chunk:                                               │  │
│  │     - text_delta ──▶ yield { type: 'text', content }             │  │
│  │     - tool_use ──▶ yield { type: 'tool_use', name, input }       │  │
│  │     - tool_result ──▶ yield { type: 'tool_result', result }      │  │
│  │  4. Loop until: done, aborted, or error                           │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
│  System Prompt Includes:                                                │
│    - Date/time                                                          │
│    - Memory context (MEMORY.md, daily logs)                            │
│    - Cron jobs summary                                                  │
│    - Available tools list                                               │
│    - Communication style guidelines                                     │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 5: PROVIDERS (Model Connection)                                   │
│                                                                         │
│  providers/claude-provider.js                                           │
│  providers/opencode-provider.js                                         │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  DETERMINISTIC: SDK Interface                                     │  │
│  │                                                                   │  │
│  │  Claude Provider:                                                 │  │
│  │    - Uses @anthropic-ai/claude-agent-sdk                         │  │
│  │    - OAuth token from ~/.claude/credentials                      │  │
│  │    - Streams via runAgentLoop()                                  │  │
│  │                                                                   │  │
│  │  Opencode Provider:                                               │  │
│  │    - HTTP calls to opencode.ai server                            │  │
│  │    - Different streaming format                                   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 6: MCP SERVERS (Tools)                                            │
│                                                                         │
│  Built-in:                                                              │
│    - Read, Write, Edit, Bash, Glob, Grep, TodoWrite, Skill             │
│                                                                         │
│  Custom MCP:                                                            │
│    - mcp/cron.js ──▶ schedule_delayed, schedule_recurring, etc.        │
│    - mcp/gateway.js ──▶ send_message, list_platforms, broadcast        │
│    - mcp/applescript.js ──▶ run_script, list_apps (macOS only)         │
│    - Composio ──▶ 500+ app integrations (optional)                     │
│                                                                         │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  DYNAMIC: Tool Execution                                          │  │
│  │                                                                   │  │
│  │  Agent requests tool ──▶ SDK routes to MCP server                │  │
│  │  MCP server executes ──▶ Returns result                          │  │
│  │  SDK yields tool_result ──▶ Agent continues thinking             │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## Flow Diagrams

### 1. Message Processing Flow (Deterministic)

```
User sends "What's the weather?"
            │
            ▼
┌─────────────────────────────────┐
│  Adapter receives message        │
│  platform: "whatsapp"            │
│  chatId: "123456789"             │
│  text: "What's the weather?"     │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  Gateway.setupAdapter()          │
│                                  │
│  1. Generate sessionKey          │
│     "agent:openclaw:whatsapp:dm:123456789"
│                                  │
│  2. Check pendingApprovals       │
│     → None, continue             │
│                                  │
│  3. Check command handler        │
│     → Not a /command             │
│                                  │
│  4. Enqueue run                  │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  AgentRunner.enqueueRun()        │
│                                  │
│  Create run object:              │
│  {                               │
│    id: "run_1709812345_abc123",  │
│    sessionKey: "...",            │
│    message: "What's the weather?"│
│    adapter: WhatsAppAdapter,     │
│    chatId: "123456789",          │
│    mcpServers: { cron, gateway } │
│  }                               │
│                                  │
│  Add to queue, start processing  │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  AgentRunner.executeRun()        │
│                                  │
│  Record in transcript            │
│  Create canUseTool callback      │
│  Call agent.run()                │
│                                  │
│  Stream chunks to adapter        │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  adapter.sendMessage()           │
│                                  │
│  "I don't have real-time weather │
│   access, but you can check..."  │
└─────────────────────────────────┘
```

### 2. Agent Thinking Loop (Dynamic)

```
agent.run() called with message
            │
            ▼
┌─────────────────────────────────┐
│  Build System Prompt             │
│                                  │
│  - Load memory context           │
│    (MEMORY.md, daily logs)       │
│  - Get cron summary              │
│  - Include session info          │
│  - List available tools          │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  provider.query()                │
│                                  │
│  async generator ────────────────┼─────────────┐
└───────────────┬─────────────────┘              │
                │                                 │
                ▼                                 │
┌─────────────────────────────────┐              │
│  LOOP: For each chunk from SDK   │◄────────────┘
│                                  │
│  switch (chunk.type):            │
│                                  │
│  case 'text_delta':              │
│    yield { type: 'text' }        │
│    → Stream to user              │
│                                  │
│  case 'tool_use':                │
│    yield { type: 'tool_use' }    │
│    → SDK executes tool           │
│    → Returns result              │
│    → Agent sees result           │
│    → Continue loop ──────────────┼────┐
│                                  │    │
│  case 'done':                    │    │
│    yield { type: 'done' }        │    │
│    → Exit loop                   │    │
│                                  │    │
│  case 'error':                   │    │
│    yield { type: 'error' }       │    │
│    → Exit loop                   │    │
└──────────────────────────────────┘    │
                │                        │
                │ ◄──────────────────────┘
                ▼          (tool result triggers next iteration)
┌─────────────────────────────────┐
│  Return fullText                 │
└─────────────────────────────────┘
```

### 3. Tool Approval Flow (Dynamic)

```
Agent wants to use risky tool (e.g., Bash rm -rf)
                │
                ▼
┌─────────────────────────────────┐
│  SDK calls canUseTool()          │
│                                  │
│  toolName: "Bash"                │
│  input: { command: "rm -rf /tmp" }
│  options: { decisionReason: ... }│
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  runner.createMessagingCanUseTool()
│                                  │
│  Format prompt:                  │
│  "Claude wants to use: Bash     │
│   { command: 'rm -rf /tmp' }    │
│   Reply Y to allow, N to deny."  │
│                                  │
│  gateway.waitForApproval()       │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  Send prompt to user via adapter │
│                                  │
│  Start timeout (120s)            │
│  Store in pendingApprovals Map   │
│                                  │
│  await user reply                │
└───────────────┬─────────────────┘
                │
    ┌───────────┴───────────┐
    ▼                       ▼
┌────────────┐      ┌────────────┐
│ User: "Y"  │      │ User: "N"  │
└─────┬──────┘      └─────┬──────┘
      │                   │
      ▼                   ▼
┌────────────┐      ┌────────────┐
│ { behavior:│      │ { behavior:│
│   'allow'  │      │   'deny',  │
│ }          │      │   message  │
│            │      │ }          │
└─────┬──────┘      └─────┬──────┘
      │                   │
      └───────┬───────────┘
              │
              ▼
┌─────────────────────────────────┐
│  SDK continues or stops          │
│  based on behavior               │
└─────────────────────────────────┘
```

### 4. Cron Execution Flow (Asynchronous)

```
┌─────────────────────────────────┐
│  User: "Remind me in 10 minutes │
│         to check the server"    │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  Agent calls:                    │
│  mcp__cron__schedule_delayed({   │
│    delaySeconds: 600,            │
│    message: "Check the server",  │
│    invokeAgent: false            │
│  })                              │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  cronScheduler.scheduleDelayed() │
│                                  │
│  Store job with:                 │
│    - platform: "whatsapp"        │
│    - chatId: "123456789"         │
│    - message: "Check the server" │
│    - executeAt: now + 600s       │
└───────────────┬─────────────────┘
                │
        (10 minutes pass)
                │
                ▼
┌─────────────────────────────────┐
│  cronScheduler emits 'execute'   │
│                                  │
│  { jobId, platform, chatId,      │
│    message, invokeAgent: false } │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  Gateway.setupCronExecution()    │
│                                  │
│  if (invokeAgent):               │
│    Run agent with message        │
│    Send agent response           │
│  else:                           │
│    adapter.sendMessage(message)  │
└───────────────┬─────────────────┘
                │
                ▼
┌─────────────────────────────────┐
│  User receives:                  │
│  "Check the server"              │
└─────────────────────────────────┘
```

---

## Key Patterns

### 1. Session Isolation
Each conversation gets a unique sessionKey:
```
agent:<agentId>:<platform>:<type>:<id>
agent:openclaw:whatsapp:dm:15551234567
agent:openclaw:telegram:group:-100123456
```

Sessions are isolated:
- Separate message queue
- Separate conversation context in SDK
- Separate transcript storage

### 2. Queue Per Session
```javascript
queues: Map<sessionKey, { items: Run[], processing: boolean }>
```
- Messages queue per session
- FIFO processing
- One message processes at a time per session
- Different sessions process in parallel

### 3. Streaming Response Pattern
```javascript
for await (const chunk of agent.run(...)) {
  if (chunk.type === 'text') {
    currentText += chunk.content
  }
  if (chunk.type === 'tool_use') {
    // Send accumulated text before tool runs
    await adapter.sendMessage(chatId, currentText)
    currentText = ''
  }
  if (chunk.type === 'done') {
    await adapter.sendMessage(chatId, currentText)
  }
}
```

### 4. MCP Server Registration
```javascript
const allMcpServers = {
  cron: this.cronMcpServer,       // Built-in
  gateway: this.gatewayMcpServer, // Built-in
  applescript: this.applescriptMcpServer, // Platform-specific
  ...mcpServers                   // User-provided (e.g., Composio)
}
```

### 5. Tool Allow List
```javascript
const allAllowedTools = [
  // Built-in
  'Read', 'Write', 'Edit', 'Bash', 'Glob', 'Grep',
  'TodoWrite', 'Skill', 'AskUserQuestion',
  // MCP tools
  'mcp__cron__schedule_delayed',
  'mcp__gateway__send_message',
  // etc.
]
```

---

## For Superman Claude

Apply the same patterns:

| OpenClaw | Superman Claude |
|----------|-----------------|
| WhatsApp/Telegram Adapter | Web UI Adapter |
| Gateway routes messages | Gateway routes web requests |
| AgentRunner queue | Same queue pattern |
| ClaudeAgent | Same agent with expanded system prompt |
| MCP: cron, gateway | MCP: cron, marketplace, skills |
| Config file MCP servers | Dynamic MCP registry |

The key addition is the **Marketplace MCP Server**:
```javascript
const marketplaceMcpServer = {
  tools: {
    'list_available': () => catalog.json,
    'install_plugin': (name) => downloadAndRegister(name),
    'uninstall_plugin': (name) => removeAndUnregister(name),
    'configure_plugin': (name, env) => setEnvVars(name, env)
  }
}
```

This lets Claude pull tools through conversation, modeling the same pattern but adding self-improvement capability.
