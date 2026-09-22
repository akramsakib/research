# Strix setup in this workspace

## What can work in Arena

Arena's in-chat assistant cannot be exposed as an LLM API endpoint that the normal Strix multi-agent scanner can call. I cannot add an API credential or make the chat itself reachable from a background process.

To make the repository usable **with this conversation as the reasoning layer**, I added `strix arena-review`: a local-only handoff mode. It inventories a source directory in the shared workspace and creates a review pack that I can inspect here. It does not execute a scan, use Docker, contact a network target, or require an LLM API key.

Use it only on software that you own or are explicitly authorized to assess.

## 1. Bootstrap the Python environment

```sh
./bootstrap-strix.sh
```

The workspace's Python environment (`.venv`) is transient, so repeat this step whenever it is absent.

## 2. Create an Arena handoff pack

```sh
./run-strix-arena-review.sh --target ./your-app --output ./your-app-review
```

It produces:

- `REVIEW_REQUEST.md` — the scope and file inventory
- `arena-review.json` — bounded metadata (paths, sizes, SHA-256 hashes)

Then tell me in this chat: **“Review `./your-app` using `./your-app-review/REVIEW_REQUEST.md`.”** I can read the shared files, reason through the code, and help prioritize fixes. The handoff is deliberately manual because this assistant is not a network service that Strix can invoke automatically.

## Normal Strix scanner: optional ChatGPT subscription configuration

The repository is also configured for the upstream Strix ChatGPT-subscription route, which has no metered API key but requires your own ChatGPT Plus or Pro subscription and Docker:

```sh
./setup-chatgpt-auth.sh
./run-strix-chatgpt.sh --target ./your-app --scan-mode quick
```

The wrapper reads `strix-chatgpt-config.json`, which sets:

- `STRIX_LLM=chatgpt/gpt-5.4`
- `STRIX_TELEMETRY=0`

## Environment constraint

Docker is not available in this Arena workspace, so the normal sandboxed Strix scans cannot run here. The local `arena-review` handoff command works without Docker.

## Optional Kali SSH execution host

I also prepared a Tailscale + SSH environment so this workspace can run commands on your own Kali machine without local Docker. See `ARENA_KALI_SSH.md`.

This is direct SSH execution on Kali, not Docker isolation and not an automatic Arena-LLM API backend. Use a dedicated Kali account and only test systems you own or are explicitly authorized to assess.

No LLM API key or OAuth token has been written to the repository.
