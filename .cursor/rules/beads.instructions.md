# Using Beads MCP Server

## Principle: Interact with Beads Functionality via MCP

When managing tasks and dependencies within an Elixir umbrella project, leverage the `fire-server` (identified as `beads-mcp`) MCP server and its associated tools to interact with the Beads issue tracking system. This provides programmatic access to task management functionalities.

## MCP Server Details

- **Server Name:** `fire-server`
- **MCP Provider:** `beads-mcp`

## Core MCP Tools for Beads Interaction

### 1. `set_context` Tool

This is the **first tool to call** when interacting with the `fire-server`. It sets the workspace root for all subsequent `bd` operations.

**Usage:**

```xml
<use_mcp_tool>
  <server_name>fire-server</server_name>
  <tool_name>set_context</tool_name>
  <arguments>
    {
      "workspace_root": "/path/to/your/project"
    }
  </arguments>
</use_mcp_tool>
```

**Example:**

```xml
<use_mcp_tool>
  <server_name>fire-server</server_name>
  <tool_name>set_context</tool_name>
  <arguments>
    {
      "workspace_root": "/Users/ernest.lee/Developer/fire-tasks"
    }
  </arguments>
</use_mcp_tool>
```

### 2. Listing and Querying Issues

Use the `list` and `show` tools to view existing issues.

- **`list` Tool:** Retrieves a list of issues with optional filters.
- **`show` Tool:** Displays detailed information about a specific issue.

**Usage:**

```xml
<!-- List all open issues -->
<use_mcp_tool>
  <server_name>fire-server</server_name>
  <tool_name>list</tool_name>
  <arguments>
    {
      "status": "open"
    }
  </arguments>
</use_mcp_tool>

<!-- Show details for issue 'bd-1' -->
<use_mcp_tool>
  <server_name>fire-server</server_name>
  <tool_name>show</tool_name>
  <arguments>
    {
      "issue_id": "bd-1"
    }
  </arguments>
</use_mcp_tool>
```

### 3. Creating and Updating Issues

Use `create` to make new issues and `update` to modify existing ones.

**Usage:**

```xml
<!-- Create a new feature -->
<use_mcp_tool>
  <server_name>fire-server</server_name>
  <tool_name>create</tool_name>
  <arguments>
    {
      "title": "Implement new feature X",
      "issue_type": "feature",
      "priority": 1,
      "assignee": "current"
    }
  </arguments>
</use_mcp_tool>

<!-- Update an issue's status -->
<use_mcp_tool>
  <server_name>fire-server</server_name>
  <tool_name>update</tool_name>
  <arguments>
    {
      "issue_id": "bd-1",
      "status": "in_progress"
    }
  </arguments>
</use_mcp_tool>
```

### 4. Accessing Resources

Use `access_mcp_resource` to retrieve resources like documentation.

**Usage:**

```xml
<access_mcp_resource>
  <server_name>fire-server</server_name>
  <uri>beads://quickstart</uri>
</access_mcp_resource>
```

## Best Practices

- **Initialize Context First:** Always call `set_context` before other tools.
- **Use Specificity:** Provide necessary arguments for tools like `list` and `show`.
- **Refer to Tool Schemas:** Consult the available tool schemas for precise parameter usage.
- **Monitor Server Status:** Be aware of potential connection or tool availability issues.
