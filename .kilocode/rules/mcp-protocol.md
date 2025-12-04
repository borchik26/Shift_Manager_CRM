# 🔧 MCP Evaluation Protocol for Kilo Code / Roo Code

> **CRITICAL:** This protocol is MANDATORY before EVERY response!

## 🎯 Purpose

This rule forces the LLM to consciously evaluate and use MCP tools before answering any question. This ensures:
- Real data instead of assumptions
- Consistent use of available tools
- Better code understanding through actual codebase analysis

## 📦 Available MCP Servers

```yaml
codealive:
  purpose: "Deep codebase analysis and search"
  tools:
    - codebase_search: "Natural language code search"
    - codebase_consultant: "Ask questions about codebase"
    - get_data_sources: "List available repositories"
  when: |
    - Understanding existing code
    - Finding implementations
    - Searching for patterns
    - ANY question about the codebase
  priority: 1 (ALWAYS FIRST for code questions)

context7:
  purpose: "Official library documentation"
  tools:
    - get-library-docs: "Get docs for a package"
    - resolve-library-id: "Find library identifier"
  when: |
    - Need API details
    - Official guides needed
    - Package documentation
    - Verifying API signatures
  priority: 3

tavily-search:
  purpose: "Web search for current information"
  tools:
    - tavily-search: "Search the web"
    - tavily-extract: "Extract from URLs"
  when: |
    - Best practices research
    - External solutions
    - Current/recent information
    - Community solutions
  priority: 4 (only if local knowledge insufficient)

dart-mcp-server:
  purpose: "Dart/Flutter code analysis"
  tools:
    - analyze_files: "Analyze Dart code"
    - resolve_workspace_symbol: "Find symbols"
    - hover: "Get type information"
  when: |
    - Dart-specific navigation
    - Understanding Flutter widgets
    - Code structure analysis
  priority: 2

sequential-thinking:
  purpose: "Complex multi-step reasoning"
  tools:
    - sequentialthinking: "Step-by-step analysis"
  when: |
    - Architecture decisions
    - Complex problems
    - Multi-step planning
  priority: 5 (for complex tasks only)
```

## 📋 Evaluation Template

**COPY THIS at the START of EVERY response:**

```
📋 MCP Evaluation:
□ codealive: [YES/NO] - [reason in 3-5 words]
□ context7: [YES/NO] - [reason in 3-5 words]
□ tavily: [YES/NO] - [reason in 3-5 words]
□ dart-mcp: [YES/NO] - [reason in 3-5 words]
□ sequential-thinking: [YES/NO] - [reason in 3-5 words]

→ Using: [list of tools to call NOW]
```

## 🔄 Three-Step Protocol

### Step 1: EVALUATE (write in response)
Fill the template above with YES/NO and short reasons.

### Step 2: ACTIVATE (immediately after Step 1)
- ✅ If any YES → Call the corresponding MCP tool **IMMEDIATELY**
- ❌ If all NO → Write "No MCP needed" and proceed

### Step 3: IMPLEMENT
**ONLY** after Step 2 is complete, proceed with implementation.

## ✅ Correct Examples

### Example 1: Adding a Feature

```
User: "Add email validation to the registration form"

📋 MCP Evaluation:
□ codealive: YES - find existing validators
□ context7: NO - standard task
□ tavily: NO - local implementation
□ dart-mcp: YES - analyze form structure
□ sequential-thinking: NO - simple task

→ Using: codealive, dart-mcp

[Calling mcp_codealive_codebase_search to find validators...]
[Results received, found validators at lib/core/utils/...]
[Calling dart-mcp to analyze form structure...]
[Now implementing based on findings...]
```

### Example 2: Package Documentation

```
User: "How to use Syncfusion Calendar for timeline view?"

📋 MCP Evaluation:
□ codealive: YES - check existing usage
□ context7: YES - Syncfusion docs needed
□ tavily: NO - context7 has docs
□ dart-mcp: YES - check imports
□ sequential-thinking: NO - specific question

→ Using: codealive, context7, dart-mcp

[Calling context7 to get Syncfusion Calendar docs...]
[Calling codealive to find existing calendar usage...]
[Now answering with real documentation...]
```

## ❌ Anti-patterns (DON'T DO THIS)

```
❌ WRONG: Skipping evaluation
"Let me implement this..."
(Missing MCP evaluation completely)

❌ WRONG: Shallow evaluation
"📋 MCP Evaluation: all NO"
(No reasons provided)

❌ WRONG: Evaluation without activation
"codealive: YES - need to check code"
[Immediately starts implementation without calling tool]
(Evaluation without activation is USELESS!)

✅ CORRECT: Full protocol
"📋 MCP Evaluation:
□ codealive: YES - find existing implementation
..."
[Calls mcp_codealive_codebase_search]
[Receives results]
[ONLY NOW starts implementation]
```

## 🔑 Key Rules

1. **Evaluation without activation = USELESS**
2. **codealive FIRST for ANY code questions**
3. **Don't rely on "knowledge" — USE TOOLS**
4. **Better to check once more than miss something**

## 📁 Project Context

This is a **Flutter CRM** project with:
- MVVM architecture
- Repository pattern
- Mock API services
- Syncfusion components

When using `codealive` for THIS project:
- Use `include_content=false` (current repository)
- Then use Read tool to get actual file contents

## 🇷🇺 Важно

Всегда отвечай на русском языке, но MCP Evaluation можно писать на английском для краткости.

