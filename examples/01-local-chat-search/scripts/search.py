#!/usr/bin/env python3
import argparse

from common import api, settings


def main():
    parser = argparse.ArgumentParser(description="搜索本地聊天记录")
    parser.add_argument("query", help="要搜索的文字")
    parser.add_argument("--limit", type=int, default=10, help="最多返回多少条")
    parser.add_argument("--source", help="只搜索指定 txt 文件")
    args = parser.parse_args()

    config = settings()
    body = {
        "q": args.query,
        "limit": max(1, min(args.limit, 100)),
        "attributesToHighlight": ["content"],
    }
    if args.source:
        escaped = args.source.replace("\\", "\\\\").replace('"', '\\"')
        body["filter"] = f'source = "{escaped}"'
    _, result = api(config, "POST", f"/indexes/{config['index']}/search", body)
    hits = result.get("hits", [])
    if not hits:
        print("没有找到结果")
        return
    for position, hit in enumerate(hits, 1):
        print(f"{position}. {hit.get('source')} 第 {hit.get('line')} 行")
        print("   " + hit.get("content", ""))


if __name__ == "__main__":
    main()
