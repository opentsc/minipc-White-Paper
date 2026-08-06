#!/usr/bin/env python3
import argparse
import hashlib
import os
from pathlib import Path

from common import ROOT, api, load_env, settings, wait_task


def data_directory():
    load_env()
    configured = Path(os.environ.get("CHAT_DATA_DIR", "./sample-data"))
    return configured if configured.is_absolute() else ROOT / configured


def collect_documents(directory):
    documents = []
    for path in sorted(directory.rglob("*.txt")):
        source = path.relative_to(directory).as_posix()
        modified_at = int(path.stat().st_mtime)
        for line_number, raw_line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            content = raw_line.strip()
            if not content:
                continue
            raw_id = f"{source}|{line_number}|{content}".encode("utf-8")
            documents.append({
                "id": hashlib.sha256(raw_id).hexdigest()[:32],
                "source": source,
                "line": line_number,
                "content": content,
                "modified_at": modified_at,
            })
    return documents


def ensure_index(config):
    status, _ = api(config, "GET", f"/indexes/{config['index']}", allowed=(200, 404))
    if status == 404:
        _, task = api(config, "POST", "/indexes", {
            "uid": config["index"],
            "primaryKey": "id",
        })
        wait_task(config, task.get("taskUid"))
    _, task = api(config, "PATCH", f"/indexes/{config['index']}/settings", {
        "searchableAttributes": ["content", "source"],
        "filterableAttributes": ["source"],
        "sortableAttributes": ["modified_at"],
        "displayedAttributes": ["id", "source", "line", "content", "modified_at"],
    })
    wait_task(config, task.get("taskUid"))


def main():
    parser = argparse.ArgumentParser(description="把 txt 文件导入本地 Meilisearch")
    parser.add_argument("--reset", action="store_true", help="导入前清空旧索引")
    parser.add_argument("--dry-run", action="store_true", help="只检查文件，不连接 Meilisearch")
    args = parser.parse_args()

    directory = data_directory()
    if not directory.exists():
        raise SystemExit(f"数据目录不存在：{directory}")
    documents = collect_documents(directory)
    if not documents:
        raise SystemExit(f"没有找到可导入的文字：{directory}")
    print(f"找到 {len(documents)} 行文字，来源目录 {directory}")
    if args.dry_run:
        print("检查完成，没有写入索引")
        return

    config = settings()
    ensure_index(config)
    if args.reset:
        _, task = api(config, "DELETE", f"/indexes/{config['index']}/documents")
        wait_task(config, task.get("taskUid"))

    total = 0
    for start in range(0, len(documents), 500):
        batch = documents[start:start + 500]
        _, task = api(config, "POST", f"/indexes/{config['index']}/documents", batch)
        wait_task(config, task.get("taskUid"))
        total += len(batch)
    print(f"导入完成，共写入 {total} 行文字")


if __name__ == "__main__":
    main()
