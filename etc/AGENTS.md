# AGENTS.md

This document provides general rules and requirements for agents when making changes to codebases.

## Markdown Formatting

All Markdown files, whether new or updated, _must_ be formatted by `prettier`. There is a `.prettierrc` file in the root directory that applies the formatting rules.

To format Markdown files, use the command `prettier --write <file(s)>`. This command will edit files in place.

If `prettier` is not installed globally, you can run it via `npx -y prettier @latest --write <file(s)>`. If `npx` is not available, you can skip the prettier step.

## Shell Script Linting

All shell scripts, whether new or updated, should be passed through `shellcheck` for linting. Any errors or warnings should be eliminated, or explicitly ignored if absolutely necessary.

## Jetpack Library Source Code

When analyzing or modifying code that uses Android Jetpack libraries (libraries with package names starting with `androidx.*`), it is highly recommended to consult the library's source code. This is important because you will often be interacting with the latest version of the library, and understanding its implementation is key.

The `context-jetpack` tool can be used to download the source code for Jetpack libraries.

### Using `context-jetpack`

You can use the tool to download the source for a specific library version:

```bash
context-jetpack androidx.wear.tiles:tiles STABLE
```

This will download the source code to a temporary directory and print the path.

### If `context-jetpack` is not installed

If the `context-jetpack` command is not available, you can download the script and use it locally:

```bash
curl -sSL https://raw.githubusercontent.com/ithinkihaveacat/dotfiles/refs/heads/master/bin/context-jetpack -o context-jetpack
chmod +x context-jetpack
./context-jetpack androidx.wear.tiles:tiles STABLE
```

Alternatively, you can inspect the script's contents to understand how to download the source code manually.

## Git Commit Messages

When generating git commit messages, use the following structure (hard-wrap all body text at 80 characters):

- Subject line (imperative mood) of <=50 characters. Do add "feat" or "bug" to the subject line.
- Blank line.
- One of more paragraphs explaining what changed and why. Point form is acceptable.
