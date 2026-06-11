def register(api):
    # Register public default skills (previously in 50-dotfiles)

    api.register_skill(
        "gog", {"repo": "openclaw/openclaw", "ref": "main", "subpath": "skills/gog"}
    )

    api.register_skill(
        "home-assistant-best-practices",
        {
            "repo": "homeassistant-ai/skills",
            "ref": "main",
            "subpath": "skills/home-assistant-best-practices",
        },
    )

    api.register_skill(
        "compose-preview",
        {"repo": "yschimke/skills", "ref": "main", "subpath": "skills/compose-preview"},
    )

    api.register_skill(
        "compose-preview-review",
        {
            "repo": "yschimke/skills",
            "ref": "main",
            "subpath": "skills/compose-preview-review",
        },
    )

    api.register_skill(
        "chrome-devtools-cli",
        {
            "repo": "ChromeDevTools/chrome-devtools-mcp",
            "ref": "main",
            "subpath": "skills/chrome-devtools-cli",
        },
    )
