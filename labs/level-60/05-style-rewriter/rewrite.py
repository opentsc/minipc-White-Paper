#!/usr/bin/env python3
"""Run a local style-library rewrite workflow through an OpenAI-compatible API."""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path


FACT_RULES = """事实规则：
1. 不新增原文没有的事实、数据、案例、人物、结论或承诺；
2. 不删除关键事实、数字、时间、链接和限定条件；
3. 不确定的内容保持原样，不自行补全；
4. 保留核心立场和逻辑顺序；
5. 输出前做事实检查，列出可能被改动的事实点；
6. 如果风格要求和事实规则冲突，事实规则优先。"""

STYLE_RULES = """风格规则：
1. 只使用风格库中能观察到的习惯；
2. 不强行加入口头禅、私人细节或错误；
3. 不使用风格库没有证据支持的表达；
4. 保留原文的标题、链接和必要结构。"""


class ApiError(RuntimeError):
    pass


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def call_api(endpoint: str, model: str, system: str, user: str, token: str) -> str:
    url = endpoint.rstrip("/") + "/chat/completions"
    payload = {
        "model": model,
        "messages": [
            {"role": "system", "content": system},
            {"role": "user", "content": user},
        ],
        "temperature": 0.7,
    }
    request = urllib.request.Request(
        url,
        data=json.dumps(payload, ensure_ascii=False).encode("utf-8"),
        headers={
            "Content-Type": "application/json",
            "Authorization": "Bearer " + token,
        },
        method="POST",
    )
    try:
        with urllib.request.urlopen(request, timeout=900) as response:
            data = json.loads(response.read().decode("utf-8"))
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as exc:
        raise ApiError(str(exc)) from exc
    try:
        return data["choices"][0]["message"]["content"]
    except (KeyError, IndexError, TypeError) as exc:
        raise ApiError("API 返回中没有 choices[0].message.content") from exc


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--endpoint", default=os.environ.get("MODEL_ENDPOINT"))
    parser.add_argument("--model", default=os.environ.get("MODEL_NAME"))
    parser.add_argument("--token", default=os.environ.get("MODEL_TOKEN", "local"))
    parser.add_argument("--style-dir", type=Path, required=True)
    parser.add_argument("--input", type=Path, required=True)
    parser.add_argument("--output-dir", type=Path, required=True)
    args = parser.parse_args()

    if not args.endpoint or not args.model:
        parser.error("请设置 MODEL_ENDPOINT 和 MODEL_NAME，或通过参数传入")

    style_files = sorted(args.style_dir.glob("*.md"))
    if not style_files:
        parser.error("风格库为空，请先放入代表作和风格说明")
    if not args.input.exists():
        parser.error("原文文件不存在：%s" % args.input)

    args.output_dir.mkdir(parents=True, exist_ok=True)
    style_text = "\n\n".join(
        "【风格文件：%s】\n%s" % (path.name, read_text(path))
        for path in style_files
    )
    source_text = read_text(args.input)
    run_path = args.output_dir / "run.jsonl"

    system = "你是一个本地风格分析和事实保真编辑。不要输出分析过程。"
    fingerprint_prompt = (
        "请只分析下面的代表作，不要改写，不要新增内容。\n"
        "输出常见开头、收尾、句子长度、段落长度、常用表达、标点习惯和不确定处。"
        "没有证据的地方写‘未观察到’。\n\n" + style_text
    )

    def record(kind: str, output: str) -> None:
        with run_path.open("a", encoding="utf-8") as handle:
            handle.write(
                json.dumps(
                    {
                        "time": time.strftime("%Y-%m-%dT%H:%M:%S%z"),
                        "kind": kind,
                        "endpoint": args.endpoint,
                        "model": args.model,
                        "output_file": str(args.output_dir / (kind + ".md")),
                    },
                    ensure_ascii=False,
                )
                + "\n"
            )

    try:
        fingerprint = call_api(
            args.endpoint,
            args.model,
            system,
            fingerprint_prompt,
            args.token,
        )
        (args.output_dir / "style-fingerprint.md").write_text(
            fingerprint, encoding="utf-8"
        )
        record("style-fingerprint", fingerprint)

        for kind, definition in (
            ("light", "轻改：只调整句长、停顿和少量词语。"),
            ("standard", "标准：调整句式、段落衔接和词语，但保留事实骨架。"),
            ("strong", "猛改：重新组织表达，只保留事实骨架和必要结构。"),
        ):
            prompt = (
                "你是文章风格迁移编辑，不是内容创作者。\n"
                + FACT_RULES
                + "\n"
                + STYLE_RULES
                + "\n改写档位："
                + definition
                + "\n文末单独输出‘## 事实检查’，逐条列出事实差异，没有差异写‘无’。"
                + "\n\n【风格指纹】\n"
                + fingerprint
                + "\n\n【原文】\n"
                + source_text
            )
            output = call_api(args.endpoint, args.model, system, prompt, args.token)
            (args.output_dir / (kind + ".md")).write_text(output, encoding="utf-8")
            record(kind, output)
    except ApiError as exc:
        print("接口请求失败：%s" % exc, file=sys.stderr)
        return 1

    print("已生成：%s" % args.output_dir)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
