#!/usr/bin/env python3
"""Ask the local Game Factory server to generate or refine a game."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request


DEFAULT_URL = os.environ.get("APP_FACTORY_URL", "http://127.0.0.1:7866").rstrip("/")
DEFAULT_MODEL = os.environ.get("APP_FACTORY_MODEL", "qwen3-coder:30b")


def request_json(base_url: str, path: str, payload: dict | None = None, timeout: int = 30) -> dict:
    data = None
    method = "GET"
    headers = {}
    if payload is not None:
        data = json.dumps(payload).encode("utf-8")
        method = "POST"
        headers["Content-Type"] = "application/json"
    req = urllib.request.Request(f"{base_url}{path}", data=data, headers=headers, method=method)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return json.loads(resp.read().decode("utf-8"))


def wait_for_result(base_url: str, timeout: int) -> dict:
    deadline = time.monotonic() + timeout
    last = {}
    while time.monotonic() < deadline:
        last = request_json(base_url, "/api/status", timeout=10)
        status = last.get("status")
        if status in {"awaiting_human", "complete", "failed"}:
            return last
        time.sleep(2)
    raise TimeoutError(f"Game Factory did not finish within {timeout}s; last status={last.get('status')!r}")


def absolute_url(base_url: str, maybe_relative: str) -> str:
    if maybe_relative.startswith("http://") or maybe_relative.startswith("https://"):
        return maybe_relative
    return f"{base_url}{maybe_relative}"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("prompt", nargs="*", help="Game or app prompt.")
    parser.add_argument("--url", default=DEFAULT_URL)
    parser.add_argument("--model", default=DEFAULT_MODEL)
    parser.add_argument("--timeout", type=int, default=int(os.environ.get("APP_FACTORY_GENERATE_TIMEOUT", "900")))
    parser.add_argument("--refine", help="Refine the existing run with this feedback instead of starting a new run.")
    parser.add_argument("--approve", action="store_true", help="Mark the current run approved.")
    args = parser.parse_args()

    base_url = args.url.rstrip("/")
    prompt = " ".join(args.prompt).strip()

    try:
        health = request_json(base_url, "/api/health", timeout=5)
        if not health.get("ok"):
            raise RuntimeError(f"health check failed: {health}")

        if args.approve:
            request_json(base_url, "/api/approve", {}, timeout=10)
            result = request_json(base_url, "/api/status", timeout=10)
        elif args.refine:
            request_json(base_url, "/api/refine", {"feedback": args.refine}, timeout=10)
            result = wait_for_result(base_url, args.timeout)
        else:
            if not prompt:
                parser.error("prompt is required unless --refine or --approve is used")
            request_json(base_url, "/api/start", {"prompt": prompt, "model": args.model}, timeout=10)
            result = wait_for_result(base_url, args.timeout)
    except urllib.error.HTTPError as exc:
        print(exc.read().decode("utf-8", errors="ignore"), file=sys.stderr)
        return 1
    except Exception as exc:
        print(f"Game Factory request failed: {exc}", file=sys.stderr)
        return 1

    generated = result.get("result") or {}
    url = generated.get("url") or ""
    if url:
        generated["absoluteUrl"] = absolute_url(base_url, url)

    output = {
        "status": result.get("status"),
        "phase": result.get("phase"),
        "model": result.get("model"),
        "modelStatus": result.get("modelStatus"),
        "title": result.get("title"),
        "summary": result.get("summary"),
        "result": generated,
        "reviewNotes": result.get("reviewNotes", []),
    }
    print(json.dumps(output, indent=2))

    if output["status"] not in {"awaiting_human", "complete"}:
        return 1
    if not generated.get("url"):
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
