#!/usr/bin/env python3
from output_filter import DuplicateGuard, extract_agent_text, guard_outbound


duplicate_guard = DuplicateGuard(window_seconds=30)


def handle_message(chat_id, user_text, run_agent, send_to_feishu):
    if duplicate_guard.seen_recently(chat_id, user_text):
        return "duplicate_ignored"

    raw_result = run_agent(user_text)
    answer = guard_outbound(extract_agent_text(raw_result))
    outbound = "✅ 完成\n" + answer
    send_to_feishu(chat_id, outbound)
    return "sent"
