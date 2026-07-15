def register(api):
    # Register public default skills (previously in 50-dotfiles)

    api.register_skill(
        "remote:gog", "https://github.com/openclaw/openclaw/tree/main/skills/gog"
    )

    api.register_skill(
        "remote:home-assistant-best-practices",
        "https://github.com/homeassistant-ai/skills/tree/main/skills/home-assistant-best-practices",
    )

    api.register_skill(
        "remote:compose-preview",
        "https://github.com/yschimke/skills/tree/main/skills/compose-preview",
    )

    api.register_skill(
        "remote:compose-preview-review",
        "https://github.com/yschimke/skills/tree/main/skills/compose-preview-review",
    )

    api.register_skill(
        "remote:chrome-devtools-cli",
        "https://github.com/ChromeDevTools/chrome-devtools-mcp/tree/main/skills/chrome-devtools-cli",
    )

    api.register_skill(
        "remote:claude-frontend-design",
        "https://github.com/anthropics/claude-code/tree/main/plugins/frontend-design/skills/frontend-design",
    )

    api.register_skill(
        "remote:skill-creator",
        "https://github.com/anthropics/skills/tree/main/skills/skill-creator",
    )

    api.register_skill(
        "remote:playwright-cli",
        "https://github.com/microsoft/playwright-cli/tree/main/skills/playwright-cli",
    )

    api.register_skill(
        "remote:skill-cleaner",
        "https://github.com/steipete/agent-scripts/tree/main/skills/skill-cleaner",
    )

