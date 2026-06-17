def register(api):
    # Register public default skills (previously in 50-dotfiles)

    api.register_skill(
        "gog", "https://github.com/openclaw/openclaw/tree/main/skills/gog"
    )

    api.register_skill(
        "home-assistant-best-practices",
        "https://github.com/homeassistant-ai/skills/tree/main/skills/home-assistant-best-practices",
    )

    api.register_skill(
        "compose-preview",
        "https://github.com/yschimke/skills/tree/main/skills/compose-preview",
    )

    api.register_skill(
        "compose-preview-review",
        "https://github.com/yschimke/skills/tree/main/skills/compose-preview-review",
    )

    api.register_skill(
        "chrome-devtools-cli",
        "https://github.com/ChromeDevTools/chrome-devtools-mcp/tree/main/skills/chrome-devtools-cli",
    )

    api.register_skill(
        "claude-frontend-design",
        "https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design/skills/frontend-design",
    )
