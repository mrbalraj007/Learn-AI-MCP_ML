# **Terraform MCP Server on Windows 11 (No Docker) — Step-by-Step Guide**

Since Docker isn't available, you'll run the Terraform MCP server as a native Go binary. The HashiCorp `terraform-mcp-server` is written in Go and can be built or downloaded as a standalone executable.

**Step 1 — Identify Your MCP Client**
First, clarify which client will consume the MCP server on this Windows VM:

# ClientConfig file locations

| Surface | File location |
|---|---|
| Claude Desktop (Windows) | `%APPDATA%\Claude\claude_desktop_config.json` |
| Claude Code CLI | `~/.claude.json` or per-project `.claude/settings.json` |
| VS Code + Claude Code extension | Workspace `.vscode/mcp.json` or user settings |

## Notes

- Claude Code settings are shared between the VS Code extension and the CLI in `~/.claude/settings.json`. [page:2]
- For MCP server configuration in the VS Code extension, the docs say to use the CLI or manage existing servers with `/mcp`; the extension only has partial MCP support. [page:2]


**Step 2 — Prerequisites**

Open PowerShell as Administrator and verify/install these:

a) Check if Go is installed (needed only if building from source)
```powershell
go version
```
If missing → download from https://go.dev/dl/ (Windows .msi installer). Install and reopen PowerShell.

**b) Check Git**
powershellgit --version
If missing → https://git-scm.com/download/win

**c) Check Terraform CLI is in PATH (you likely have this already)**
```powershell
terraform version
```

**Step 3 — Get the terraform-mcp-server Binary**

<!-- Option A: Download pre-built binary (fastest)
Go to the GitHub releases page:
https://github.com/hashicorp/terraform-mcp-server/releases
Look for a file like terraform-mcp-server_windows_amd64.zip or terraform-mcp-server_windows_amd64.exe. Download and extract it to a permanent location, for example:
C:\tools\terraform-mcp-server\terraform-mcp-server.exe -->

**Option B: Build from source (if no binary release exists for Windows)**
```powershell
# Clone the repo
git clone https://github.com/hashicorp/terraform-mcp-server.git
cd terraform-mcp-server

# Build the Windows binary
go build -o terraform-mcp-server.exe ./cmd/terraform-mcp-server

# Move to a permanent location
mkdir C:\tools\terraform-mcp-server
Move-Item terraform-mcp-server.exe C:\tools\terraform-mcp-server\
```

**Verify the binary runs:**
```powershell
C:\tools\terraform-mcp-server\terraform-mcp-server.exe --version
# or
C:\tools\terraform-mcp-server\terraform-mcp-server.exe --help
```

**Step 4 — Configure the MCP Client**

*For Claude Desktop (most common on Windows)*

Open or create %APPDATA%\Claude\claude_desktop_config.
```json:
{
  "mcpServers": {
    "terraform": {
      "command": "C:\\tools\\terraform-mcp-server\\terraform-mcp-server.exe",
      "args": ["stdio"],
      "env": {}
    }
  }
}
```
*Note: Use double backslashes \\ in JSON on Windows.*

**For Claude Code CLI**
Edit `~/.claude.json` (or run ``claude mcp add`):

```json
{
  "mcpServers": {
    "terraform": {
      "command": "C:\\tools\\terraform-mcp-server\\terraform-mcp-server.exe",
      "args": ["stdio"]
    }
  }
}
```
**Or via CLI:**
```powershell
claude mcp add terraform -- C:\tools\terraform-mcp-server\terraform-mcp-server.exe stdio
```

---

> [!NOTE]
The /mcp command runs in the current project context (test_C\Lab-02). The Terraform MCP server you showed earlier was configured as a local (project-scoped) config in a
  different directory — ~\test_D\terraform-mcp-server.
<br>



> [!IMPORTANT] 
> Local MCP configs are per-project, so each project needs its own setup. You can add it to this project too:
  *claude mcp add terraform -s local -- stdio C:\tools\terraform-mcp-server\terraform-mcp-server.exe stdio*

<br>

> [!CAUTION] 
> If you want it available in every project, add it at the global scope instead:
> *claude mcp add terraform -s user -- stdio C:\tools\terraform-mcp-server\terraform-mcp-server.exe stdio*

---

**Step 5 — Restart the MCP Client**

- Claude Desktop: Quit and reopen the app (not just minimise — fully quit from the system tray).
- Claude Code CLI: No restart needed; config is read fresh each session.


**Step 6 — Verify the MCP Server is Loaded**

**In Claude Desktop**
Open a new chat and type:
`What MCP tools do you have available?`

You should see Terraform-related tools listed (e.g., `terraform_validate, terraform_plan, terraform_providers`, etc.).

**In Claude Code CLI**
```powershell
claude mcp list
```
Should show terraform in the connected servers list.

**Step 7 — Test Against Your Terraform Code**

Navigate to a folder with your Terraform files, then in Claude (Desktop or Code), try prompts like:
```sh
- Validate the Terraform code in the current directory
- Run a terraform plan against my current workspace and summarise what will change
- List all providers used in this Terraform configuration
- Check for any drift in the resources defined here
```
The MCP server proxies these requests by executing Terraform commands in the context of your working directory.

**Troubleshooting Tips**

| Issue | Check |
|---|---|
| `command not found` or path error | Verify the `.exe` path in config uses `\\`, not `/`. |
| MCP server not appearing in Claude | Fully quit Claude Desktop from the system tray, not just close the window. |
| `terraform` not found by the MCP server | Ensure `terraform.exe` is in your system `PATH` and test with `terraform version` in the same PowerShell session. |
| `stdio` mode hanging | Some builds use `--transport stdio` as the argument; check the server’s `--help` output. |
| Antivirus blocking the binary | Add `C:\tools\terraform-mcp-server\` to Windows Defender exclusions. |

**Quick Reference — Key Paths**
```sh
Binary:     C:\tools\terraform-mcp-server\terraform-mcp-server.exe
Config:     %APPDATA%\Claude\claude_desktop_config.json  (Claude Desktop)
            ~\.claude.json                               (Claude Code CLI)
Test dir:   Your Terraform working directory (e.g., .\src\terraform\)
```

Once you confirm the binary runs and tools show up in the MCP list, you're ready to use it against your Azure Terraform code. Let me know which client you're using (Desktop vs Code CLI) and I can tailor the config further.