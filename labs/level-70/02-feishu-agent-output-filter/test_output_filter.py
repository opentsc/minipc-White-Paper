#!/usr/bin/env python3
import pathlib
import unittest

from output_filter import (
    DuplicateGuard,
    SAFE_FORMAT_ERROR,
    extract_agent_text,
    guard_outbound,
)


ROOT = pathlib.Path(__file__).resolve().parent


class OutputFilterTests(unittest.TestCase):
    def test_extracts_only_public_text_from_pretty_json(self):
        raw = (ROOT / "fixtures" / "agent-result.json").read_text(encoding="utf-8")
        result = extract_agent_text(raw)
        self.assertEqual(result, "资料已经整理完成，共找到 4 条有效记录。")
        self.assertNotIn("内部过程", result)
        self.assertNotIn("synthetic-session-id", result)

    def test_reads_jsonl_events(self):
        raw = '{"type":"progress"}\n{"text":"最终答案","usage":{"input_tokens":8}}'
        self.assertEqual(extract_agent_text(raw), "最终答案")

    def test_blocks_truncated_internal_object(self):
        raw = '{"text":"答案","thought":"不能发送"'
        self.assertEqual(guard_outbound(raw), SAFE_FORMAT_ERROR)

    def test_preserves_normal_text_and_user_json(self):
        self.assertEqual(guard_outbound("普通文字"), "普通文字")
        user_json = '{"name":"用户要求的 JSON"}'
        self.assertEqual(guard_outbound(user_json), user_json)

    def test_duplicate_guard(self):
        guard = DuplicateGuard(window_seconds=30)
        self.assertFalse(guard.seen_recently("chat-1", "同一任务"))
        self.assertTrue(guard.seen_recently("chat-1", "同一任务"))
        self.assertFalse(guard.seen_recently("chat-1", "另一个任务"))


if __name__ == "__main__":
    unittest.main()
