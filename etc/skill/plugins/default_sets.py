def register(api):
    # Default skill sets for dotfiles
    api.add_set(
        "technical",
        ["coding-standards", "technical-writing-style", "agent-tools"],
    )
    api.add_set(
        "android",
        [
            "coding-standards",
            "technical-writing-style",
            "agent-tools",
            "adb",
            "emumanager",
            "jetpack",
        ],
    )
