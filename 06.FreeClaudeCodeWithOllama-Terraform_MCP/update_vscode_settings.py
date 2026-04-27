#!/usr/bin/env python3
import json
import shutil
from pathlib import Path

# VS Code settings path on Linux
settings_path = Path.home() / '.config' / 'Code' / 'User' / 'settings.json'

# Backup first
shutil.copy(settings_path, str(settings_path) + '.backup')
print(f"Backed up to: {settings_path}.backup")

# Read existing settings
try:
    with open(settings_path, 'r') as f:
        settings = json.load(f)
except json.JSONDecodeError:
    print("Warning: Existing settings.json is corrupted, starting fresh")
    settings = {}

# Add MCP configuration
settings['claude-dev.mcpServers'] = {
    'terraform': {
        'command': 'docker',
        'args': [
            'run',
            '--rm',
            '-e', 'TF_TOKEN_app_terraform_io=YOUR_TOKEN_HERE',
            '-e', 'TF_API_ADDRESS=https://app.terraform.io',
            'hashicorp/terraform-mcp-server'
        ]
    }
}

# Write back with proper formatting
with open(settings_path, 'w') as f:
    json.dump(settings, f, indent=2)

print(f"Settings updated at: {settings_path}")
