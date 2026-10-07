from __future__ import annotations

from pathlib import Path

OPT_OUT_CONTENT = """# Disables all telemetry for Shopify AI Toolkit
# Reference: https://github.com/Shopify/Shopify-AI-Toolkit#opting-out
"""


def register(api) -> None:
    # Ensure user-level opt-out file exists
    opt_out_file = Path("~/.config/shopify-ai-toolkit/opt-out").expanduser()
    if not opt_out_file.exists():
        opt_out_file.parent.mkdir(parents=True, exist_ok=True)
        opt_out_file.write_text(OPT_OUT_CONTENT, encoding="utf-8")

    # Shopify consolidated its API skills into skills/shopify. Keep the old
    # catalog name so existing workspace specifications continue to resolve.
    api.register_skill(
        "remote:shopify-storefront-graphql",
        "https://github.com/Shopify/Shopify-AI-Toolkit/tree/main/skills/shopify",
    )
