#!/usr/bin/env python3
"""
NVIDIA API Integration Test Suite
Replicates the test output shown in the screenshot:
  - TEST 1: Fetch all available models
  - TEST 2: Find DeepSeek models
  - TEST 3: DeepSeek V4 Flash details
  - TEST 4: Live inference test

Requirements:
    pip install requests

Usage:
    export NVIDIA_API_KEY="nvapi-xxxxxxxxxxxxxxxxxxxx"
    python nvidia_api_test.py
"""

import os
import sys
import json
import requests

# ─────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────
NVIDIA_API_KEY   = os.environ.get("NVIDIA_API_KEY", "")
BASE_URL         = "https://integrate.api.nvidia.com/v1"
MODELS_ENDPOINT  = f"{BASE_URL}/models"
CHAT_ENDPOINT    = f"{BASE_URL}/chat/completions"

TARGET_MODEL     = "deepseek-ai/deepseek-v4-flash"   # used for TEST 3 & 4
DEEPSEEK_FILTER  = "deepseek"                        # case-insensitive filter

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────

def make_headers() -> dict:
    if not NVIDIA_API_KEY:
        print("\n[ERROR] NVIDIA_API_KEY environment variable is not set.")
        print("        Export it with:  export NVIDIA_API_KEY='nvapi-...'")
        sys.exit(1)
    return {
        "Authorization": f"Bearer {NVIDIA_API_KEY}",
        "Content-Type": "application/json",
    }


def print_banner(title: str) -> None:
    line = "=" * 60
    print(f"\n{line}")
    print(f"  {title}")
    print(line)


def print_result(passed: bool, label: str = "") -> None:
    status = "PASSED ✓" if passed else "FAILED ✗"
    if label:
        print(f"  [{status}] {label}")
    else:
        print(f"  [{status}]")


# ─────────────────────────────────────────────
# Tests
# ─────────────────────────────────────────────

def test_1_fetch_all_models(headers: dict) -> list:
    """TEST 1 – Fetch all available models from NVIDIA NIM."""
    print("\nTEST 1: Fetching Available Models...")

    all_models = []
    url = MODELS_ENDPOINT

    try:
        while url:
            resp = requests.get(url, headers=headers, timeout=30)
            resp.raise_for_status()
            data = resp.json()

            page_models = data.get("data", [])
            all_models.extend(page_models)

            # Handle pagination if NVIDIA returns a next-page cursor
            url = data.get("next", None)   # adjust key if the API differs

        count = len(all_models)
        print(f"  Found {count} models available")
        print_result(count > 0, f"{count} models returned")
        return all_models

    except requests.exceptions.HTTPError as exc:
        print(f"  HTTP Error: {exc.response.status_code} – {exc.response.text}")
        print_result(False, "HTTP error fetching models")
        return []
    except Exception as exc:
        print(f"  Error: {exc}")
        print_result(False, "Exception fetching models")
        return []


def test_2_find_deepseek_models(all_models: list) -> list:
    """TEST 2 – Filter models whose id contains 'deepseek'."""
    print("\nTEST 2: Finding DeepSeek Models...")

    deepseek_models = [
        m for m in all_models
        if DEEPSEEK_FILTER in m.get("id", "").lower()
    ]

    count = len(deepseek_models)
    print(f"  Found {count} DeepSeek models:")
    for m in deepseek_models:
        print(f"    - {m['id']}")

    print_result(count > 0, f"{count} DeepSeek models found")
    return deepseek_models


def test_3_deepseek_v4_flash_details(all_models: list) -> dict | None:
    """TEST 3 – Look up details for deepseek-ai/deepseek-v4-flash."""
    print(f"\nTEST 3: DeepSeek V4 Flash Details...")

    model_info = next(
        (m for m in all_models if m.get("id") == TARGET_MODEL),
        None,
    )

    if model_info:
        print(f"  Model: {model_info.get('id', 'N/A')}")
        print(f"    Owner: {model_info.get('owned_by', model_info.get('owner', 'N/A'))}")
        # Print any extra fields that exist
        for key in ("created", "object", "permission"):
            if key in model_info:
                print(f"    {key.capitalize()}: {model_info[key]}")
        print_result(True, f"Model details retrieved for {TARGET_MODEL}")
    else:
        print(f"  Model '{TARGET_MODEL}' not found in model list")
        print_result(False, f"{TARGET_MODEL} not found")

    return model_info


def test_4_live_inference(headers: dict) -> bool:
    """TEST 4 – Send a simple prompt to deepseek-v4-flash and print the reply."""
    print("\nTEST 4: Live Inference Test...")

    payload = {
        "model": TARGET_MODEL,
        "messages": [
            {"role": "user", "content": "Say exactly: Hello from Nvidia!"}
        ],
        "max_tokens": 64,
        "temperature": 0.1,
        "stream": False,
    }

    try:
        resp = requests.post(CHAT_ENDPOINT, headers=headers,
                             json=payload, timeout=60)
        resp.raise_for_status()
        data = resp.json()

        reply = (
            data.get("choices", [{}])[0]
                .get("message", {})
                .get("content", "")
                .strip()
        )

        print(f'  Response: "{reply}"')
        passed = bool(reply)
        print_result(passed, "Inference returned a response")
        return passed

    except requests.exceptions.HTTPError as exc:
        print(f"  HTTP Error: {exc.response.status_code} – {exc.response.text}")
        print_result(False, "HTTP error during inference")
        return False
    except Exception as exc:
        print(f"  Error: {exc}")
        print_result(False, "Exception during inference")
        return False


# ─────────────────────────────────────────────
# Main runner
# ─────────────────────────────────────────────

def main() -> None:
    print_banner("NVIDIA API INTEGRATION TEST SUITE")

    headers = make_headers()
    results = []

    # ── Run tests ──────────────────────────────
    all_models      = test_1_fetch_all_models(headers)
    results.append(bool(all_models))

    deepseek_models = test_2_find_deepseek_models(all_models)
    results.append(bool(deepseek_models))

    model_info      = test_3_deepseek_v4_flash_details(all_models)
    results.append(model_info is not None)

    inference_ok    = test_4_live_inference(headers)
    results.append(inference_ok)

    # ── Summary ────────────────────────────────
    print("\n" + "=" * 60)
    if all(results):
        print("  ALL TESTS PASSED!")
    else:
        failed = sum(1 for r in results if not r)
        print(f"  {failed} TEST(S) FAILED – review output above.")
    print("=" * 60 + "\n")

    sys.exit(0 if all(results) else 1)


if __name__ == "__main__":
    main()