#!/usr/bin/env python3
import json
import os
import time
import urllib.error
import urllib.request
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]


def load_env():
    env_file = ROOT / ".env"
    if env_file.exists():
        for raw_line in env_file.read_text(encoding="utf-8").splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            os.environ.setdefault(key.strip(), value.strip())


def settings():
    load_env()
    key = os.environ.get("MEILI_MASTER_KEY", "")
    if not key or key == "replace-with-a-random-key":
        raise SystemExit("请先复制 .env.example 为 .env，并生成 MEILI_MASTER_KEY")
    return {
        "url": os.environ.get("MEILI_URL", "http://127.0.0.1:7700").rstrip("/"),
        "index": os.environ.get("MEILI_INDEX", "local_chat"),
        "key": key,
    }


def api(config, method, path, body=None, allowed=(200, 201, 202)):
    data = json.dumps(body, ensure_ascii=False).encode("utf-8") if body is not None else None
    request = urllib.request.Request(config["url"] + path, data=data, method=method)
    request.add_header("Authorization", "Bearer " + config["key"])
    request.add_header("Content-Type", "application/json")
    try:
        with urllib.request.urlopen(request, timeout=60) as response:
            payload = response.read().decode("utf-8")
            return response.status, json.loads(payload) if payload else {}
    except urllib.error.HTTPError as error:
        payload = error.read().decode("utf-8", errors="replace")
        if error.code in allowed:
            return error.code, json.loads(payload) if payload else {}
        raise SystemExit(f"Meilisearch 返回 HTTP {error.code}：{payload[:300]}") from error
    except urllib.error.URLError as error:
        raise SystemExit(f"无法连接 Meilisearch：{error.reason}") from error


def wait_task(config, task_uid):
    if task_uid is None:
        return
    for _ in range(120):
        _, task = api(config, "GET", f"/tasks/{task_uid}")
        status = task.get("status")
        if status == "succeeded":
            return
        if status == "failed":
            raise SystemExit(f"Meilisearch 任务失败：{task.get('error')}")
        time.sleep(0.25)
    raise SystemExit("等待 Meilisearch 任务超时")
