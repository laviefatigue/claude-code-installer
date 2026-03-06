# Getting Started with Claude Code

---
name: getting-started
description: Guides new users through Claude Code basics. Activate when users ask how to get started, what Claude Code can do, or seem new to the tool.
user-invocable: true
allowed-tools: Read, Glob, Grep
---

## Purpose

Help new users understand what Claude Code can do and how to use it effectively. This skill provides a friendly, non-technical introduction.

## When to Activate

Trigger this skill when the user:
- Says "I'm new" or "just getting started"
- Asks "what can you do?" or "how does this work?"
- Seems confused about basic operations
- Types `/getting-started`

## Response Guidelines

### For Non-Technical Users

Keep explanations simple. Focus on outcomes, not technical details.

**Explain what Claude Code can help with:**

1. **Writing Code**
   - "Help me write a Python script that..."
   - "Create a function to calculate..."
   - Just describe what you want in plain English

2. **Understanding Code**
   - "Explain what this code does"
   - "Why isn't this working?"
   - Paste code and ask questions about it

3. **Working with Files**
   - "Create a new file called..."
   - "Edit the config file to..."
   - "Find all files that contain..."

4. **Running Commands**
   - "Run the tests"
   - "Start the development server"
   - "Install the dependencies"

### Quick Tips to Share

1. **Be specific** - The more detail you provide, the better the help
2. **Share context** - Paste error messages, code snippets, or file names
3. **Ask follow-ups** - If something isn't clear, just ask
4. **Use slash commands** - Type `/` to see available commands

### Example Interactions

Show these as conversation examples:

**Simple request:**
> "Create a Python script that reads a CSV file and prints the first 5 rows"

**Getting help with errors:**
> "I'm seeing this error: [paste error]. What's wrong?"

**Understanding code:**
> "Can you explain what this function does? [paste code]"

## What NOT to Do

- Don't overwhelm with technical jargon
- Don't assume knowledge of git, npm, terminals
- Don't list every feature - keep it digestible
- Don't use acronyms without explanation

## Closing

End with an encouraging prompt:
> "What would you like to work on? Just describe it in your own words, and I'll help you get started!"
