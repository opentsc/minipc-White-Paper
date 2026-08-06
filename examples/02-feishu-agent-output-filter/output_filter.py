#!/usr/bin/env python3
import collections
import hashlib
import json
import threading
import time


SAFE_FORMAT_ERROR = "任务已经完成，但模型返回格式异常。内部运行记录已拦截，请重试。"
SAFE_RUNTIME_ERROR = "智能体运行失败，请查看服务器日志。"

INTERNAL_KEYS = frozenset({
    "thought",
    "usage",
    "sessionId",
    "session_id",
    "requestId",
    "request_id",
    "stopReason",
    "stop_reason",
    "modelUsage",
    "model_usage",
    "num_turns",
    "total_cost_usd",
    "total_cost_usd_ticks",
    "reasoning_tokens",
    "input_tokens",
    "output_tokens",
    "cache_read_input_tokens",
    "cache_creation_input_tokens",
})

PUBLIC_KEYS = ("result", "response", "text", "content", "message")


def _documents(raw: str) -> list:
    text = (raw or "").strip()
    if not text:
        return []
    try:
        return [json.loads(text)]
    except ValueError:
        documents = []
        for line in text.splitlines():
            line = line.strip()
            if not line:
                continue
            try:
                documents.append(json.loads(line))
            except ValueError:
                continue
        return documents


def _extract(value) -> str:
    if isinstance(value, str):
        return value.strip()
    if isinstance(value, list):
        parts = [_extract(item) for item in value]
        return "".join(part for part in parts if part).strip()
    if isinstance(value, dict):
        for key in PUBLIC_KEYS:
            if key in value:
                text = _extract(value[key])
                if text:
                    return text
    return ""


def _contains_internal(value) -> bool:
    if isinstance(value, dict):
        if any(key in INTERNAL_KEYS for key in value):
            return True
        return any(_contains_internal(item) for item in value.values())
    if isinstance(value, list):
        return any(_contains_internal(item) for item in value)
    return False


def extract_agent_text(raw: str) -> str:
    """在智能体运行层读取 JSON 或 JSONL，只返回面向用户的正文。"""
    documents = _documents(raw)
    for document in reversed(documents):
        if not isinstance(document, dict):
            continue
        if document.get("type") == "error" or document.get("error"):
            return SAFE_RUNTIME_ERROR
        text = _extract(document)
        if text:
            return text
    return SAFE_FORMAT_ERROR


def guard_outbound(raw: str) -> str:
    """飞书发送前的第二道检查，不改写普通文字和用户要求的普通 JSON。"""
    text = str(raw or "").strip()
    if not text:
        return ""
    try:
        payload = json.loads(text)
    except ValueError:
        markers = tuple(f'"{key}"' for key in INTERNAL_KEYS)
        return SAFE_FORMAT_ERROR if any(marker in text for marker in markers) else text
    if not _contains_internal(payload):
        return text
    public_text = _extract(payload)
    return public_text or SAFE_FORMAT_ERROR


class DuplicateGuard:
    """拦截同一聊天在短时间内重复提交的相同文字。"""

    def __init__(self, window_seconds: int = 30, max_entries: int = 1000):
        self.window_seconds = window_seconds
        self.max_entries = max_entries
        self._entries = collections.OrderedDict()
        self._lock = threading.Lock()

    def seen_recently(self, chat_id: str, user_text: str) -> bool:
        now = time.monotonic()
        digest = hashlib.sha256(user_text.strip().encode("utf-8")).hexdigest()
        key = (chat_id, digest)
        with self._lock:
            while self._entries:
                _, timestamp = next(iter(self._entries.items()))
                if now - timestamp <= self.window_seconds:
                    break
                self._entries.popitem(last=False)
            previous = self._entries.get(key)
            if previous is not None and now - previous <= self.window_seconds:
                return True
            self._entries[key] = now
            self._entries.move_to_end(key)
            while len(self._entries) > self.max_entries:
                self._entries.popitem(last=False)
        return False
