# Getting Started with Claude Code

Welcome! This guide will help you start using Claude Code.

## What is Claude Code?

Claude Code is an AI assistant that lives in your terminal. It can help you:

- Write and edit code
- Understand existing codebases
- Run terminal commands
- Debug errors
- And much more

## Installation

### Automatic (Recommended)

Run the installer:

```powershell
.\install.ps1
```

The installer will:
1. Check for VS Code and Git
2. Install Claude Code CLI
3. Open your browser for authentication
4. Set up helpful commands and skills

### Manual

If you prefer manual setup:

1. Install [VS Code](https://code.visualstudio.com/)
2. Install [Git for Windows](https://git-scm.com/)
3. Install Claude Code:
   ```powershell
   irm https://claude.ai/install.ps1 | iex
   ```
4. Run `claude` and authenticate

## Your First Session

### Start Claude Code

Open VS Code, press `Ctrl+`` to open the terminal, then type:

```
claude
```

### Try These Commands

**Get help:**
```
/help
```

**Start the guided tour:**
```
/getting-started
```

**Ask a question:**
```
How do I create a Python function?
```

## Tips for Success

### Be Specific

Instead of: "Make a function"

Try: "Create a Python function called `calculate_total` that takes a list of prices and returns the sum with 10% tax"

### Share Context

If you have an error, paste it:
```
I'm getting this error when I run my code:
TypeError: cannot unpack non-iterable NoneType object
```

### Ask Follow-ups

If Claude's response isn't quite right, tell it:
```
That's close, but I also need it to handle empty lists
```

## Common Tasks

### Create a New File

```
Create a new file called app.py with a basic Flask server
```

### Edit an Existing File

```
In app.py, add a new route for /health that returns OK
```

### Run a Command

```
Install the requests library
```

### Understand Code

```
Explain what the authenticate function does
```

## Getting More Help

- Type `/help` for command reference
- Type `/getting-started` for the interactive guide
- Just ask "how do I..." for any task

Remember: Claude Code is here to help. If something isn't working, describe what you expected and what happened instead.
