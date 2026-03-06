# Help Guide

---
name: help-guide
description: Provides contextual help about Claude Code features and capabilities. Activate when users ask for help, are stuck, or want to learn about specific features.
user-invocable: true
allowed-tools: Read, Glob
---

## Purpose

Provide helpful guidance when users need assistance. This skill acts as a friendly support system.

## When to Activate

Trigger when the user:
- Types `/help-guide` or asks for help
- Is stuck on something
- Wants to know about specific features
- Asks "can you do X?"

## Help Categories

### 1. Code Assistance

**What Claude Code can do:**
- Write new code from descriptions
- Explain existing code
- Debug errors and suggest fixes
- Refactor and improve code
- Add comments and documentation
- Convert between programming languages

**Example prompts:**
- "Write a function that validates email addresses"
- "Why is this loop not working?"
- "Make this code more readable"
- "Add error handling to this function"

### 2. File Operations

**What Claude Code can do:**
- Create new files
- Edit existing files
- Search for files by name or content
- Read and analyze files
- Rename or reorganize files

**Example prompts:**
- "Create a new component called Button.tsx"
- "Find all files that import lodash"
- "Update the config to use port 8080"
- "Show me what's in the src folder"

### 3. Terminal Commands

**What Claude Code can do:**
- Run shell commands
- Execute scripts
- Install packages
- Start development servers
- Run tests

**Example prompts:**
- "Install the axios package"
- "Run the test suite"
- "Start the dev server"
- "Check what's using port 3000"

### 4. Project Understanding

**What Claude Code can do:**
- Explain project structure
- Find where things are defined
- Trace how code flows
- Identify patterns and conventions

**Example prompts:**
- "How is authentication handled in this project?"
- "Where is the User model defined?"
- "What does the build process do?"
- "Explain the folder structure"

## Common Questions

### "What's the best way to ask for help?"

Be specific! Include:
1. What you're trying to do
2. What's happening instead
3. Any error messages you see
4. Relevant file names or code

### "Can you access external services?"

Claude Code can use MCP (Model Context Protocol) servers to connect to external services. Type `/mcp` to see what's available.

### "Will you remember our conversation?"

Within a session, yes! Claude Code maintains context throughout your conversation. Between sessions, key learnings may be saved to memory if relevant.

### "What if I make a mistake?"

Claude Code runs in a controlled environment. Most operations can be undone (git, file edits). For destructive operations, Claude Code will ask for confirmation first.

## Getting More Help

- Type `/` to see all available commands
- Ask "what else can you help with?"
- Describe your goal and ask for guidance
- If stuck, share what you've tried so far
