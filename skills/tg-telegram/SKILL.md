---
name: tg-telegram
description: Use when the user asks to send Telegram messages, notify via Telegram, message through Telegram, use the tg command, or get Telegram replies. Covers tg init, tg send, tg recv, and tg status.
---

# tg — Telegram Bot CLI

The `tg` command sends and receives messages through a Telegram bot. It lives at `tg` (in PATH) and stores configuration in `~/.tg.conf`.

## Subcommands

### `tg status`
Check whether the bot is configured and authenticated. Use this first to verify setup before sending messages.

### `tg init`
First-time setup. Prompts for the Telegram Bot Token interactively, then waits for the user to send any message in Telegram to capture the chat ID. The AI cannot run this interactively — ask the user to run it themselves.

### `tg send <message>`
Send a message via the Telegram bot. Message is a single argument (wrap in quotes if it contains spaces). Returns nothing on success, prints an error on failure.

### `tg recv <message>`
Send a message and then block (busy-wait) until a human reply arrives. Prints the reply text to stdout and exits. Useful for request-response workflows where you need an answer from the user via Telegram.

## Usage notes

- Requires `curl` and `jq` in PATH.
- Config file is `~/.tg.conf` (override with `TG_CONF` env var).
- All subcommands read the bot token and chat ID from the config automatically after `tg init` has been run.
- `tg recv` blocks indefinitely until a reply is received. The AI should warn the user that it will wait for a Telegram reply before proceeding.
