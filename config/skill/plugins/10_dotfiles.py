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
        "remote:compose-ui-builder",
        "https://github.com/yschimke/skills/tree/main/skills/compose-ui-builder",
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
        "remote:claude-skill-creator",
        "https://github.com/anthropics/skills/tree/main/skills/skill-creator",
    )

    api.register_skill(
        "remote:codex-skill-creator",
        "https://github.com/openai/codex/tree/main/codex-rs/skills/src/assets/samples/skill-creator",
    )

    api.register_skill(
        "remote:playwright-cli",
        "https://github.com/microsoft/playwright-cli/tree/main/skills/playwright-cli",
    )

    api.register_skill(
        "remote:skill-cleaner",
        "https://github.com/steipete/agent-scripts/tree/main/skills/skill-cleaner",
    )

    api.register_skill(
        "remote:typesafe-ai",
        "https://github.com/typesafe-ai/skills/tree/main/skills/typesafe-ai",
    )

    # Cloudflare: register the skills individually; do not install Cloudflare's
    # agent plugin (cloudflare/skills). As reviewed at plugin version 1.0.2, it
    # holds only standard skills/ directories, which these registrations load
    # per session, and one remote MCP server (mcp.cloudflare.com), which the cf
    # CLI covers (install.sh --with cloudflare installs cf). It has no hooks,
    # commands, agents or binaries, so no skill needs generating as for
    # build-brief. Revisit if the plugin's manifests (.claude-plugin/,
    # .codex-plugin/) add a component that cf and these skills cannot replace:
    #   gh api repos/cloudflare/skills/contents/.claude-plugin/plugin.json \
    #     --jq .content | base64 -d
    # Register other skills from the repository (wrangler, durable-objects,
    # ...) the same way when needed.
    api.register_skill(
        "remote:cloudflare",
        "https://github.com/cloudflare/skills/tree/main/skills/cloudflare",
    )

    # Cloudflare's cf CLI (npm package "cf", Node.js >= 22). On a Raspberry Pi 4
    # (39-bit virtual address space), `cf dev` and `--local` abort at startup
    # because workerd assumes 48 bits (cloudflare/workerd#5020); API commands
    # work.
    api.register_skill(
        "remote:cf-cli",
        "https://github.com/cloudflare/skills/tree/main/skills/cf-cli",
    )
