#!/usr/bin/env bash
# 单据 OCR 体检：逐项检查这台机器上那条流水线是不是真的能跑给客户看。
#
# 全部是只读检查，不改任何配置，不写任何结果文件，随时可以跑。
# 唯一会“动”的地方是第 2 项要向视觉模型服务发一张脚本自己生成的 1×1 小图，
# 那会让模型被加载进内存。那是这套东西本来就要做的事。
#
# 它不读任何单据、不读跑出来的台账与 JSON、不打印任何环境变量的值。
#
# 用法：
#   ./check-ocr.sh
#
# 可以用环境变量改默认值：
#   CHECK_OCR_HOST       服务地址，默认 127.0.0.1
#   CHECK_OCR_PORT       服务端口，默认 8090
#   CHECK_OCR_MODEL      模型名，默认问服务要
#   CHECK_SCHEMA         schema 文件，默认 $HOME/ai/scripts/invoice_schema.json
#   CHECK_SCRIPTS_DIR    脚本目录，默认 $HOME/ai/scripts
#   CHECK_PROJECT_DIR    结果目录，默认 $HOME/ai/projects/invoice-ocr
#   CHECK_DATA_DIR       原件目录，默认 $HOME/ai/data
#   CHECK_TIMEOUT        等接口返回的秒数，默认 180
#
# 退出码：全部通过是 0，有任何一项不通过是 1。查不到的项报“跳过”，不算不通过。

set -uo pipefail

OCR_ADDR="${CHECK_OCR_HOST:-127.0.0.1}"
OCR_PORT="${CHECK_OCR_PORT:-8090}"
OCR_MODEL="${CHECK_OCR_MODEL:-}"
SCHEMA_FILE="${CHECK_SCHEMA:-$HOME/ai/scripts/invoice_schema.json}"
SCRIPTS_DIR="${CHECK_SCRIPTS_DIR:-$HOME/ai/scripts}"
PROJECT_DIR="${CHECK_PROJECT_DIR:-$HOME/ai/projects/invoice-ocr}"
DATA_DIR="${CHECK_DATA_DIR:-$HOME/ai/data}"
API_TIMEOUT="${CHECK_TIMEOUT:-180}"

API_BASE="http://${OCR_ADDR}:${OCR_PORT}/v1"

PASS=0
FAIL=0
SKIP=0

ok()   { printf '  通过　%s\n' "$1"; PASS=$((PASS + 1)); }
bad()  { printf '  不通过　%s\n' "$1"; FAIL=$((FAIL + 1)); }
skip() { printf '  跳过　%s\n' "$1"; SKIP=$((SKIP + 1)); }
note() { printf '  说明　%s\n' "$1"; }

have() { command -v "$1" >/dev/null 2>&1; }

# 问服务现在加载的是哪个模型。拿不到就没有输出。
detect_model() {
  have curl || return 1
  have python3 || return 1
  curl -s -m 20 "$API_BASE/models" 2>/dev/null | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
items = data.get("data") or []
if not items:
    sys.exit(1)
name = items[0].get("id")
if not name:
    sys.exit(1)
print(name)
' 2>/dev/null
}

# 造一张 1×1 的白色 PNG，转成 data URI。这是发得出去的最小一张图。
tiny_image() {
  python3 -c '
import base64
import struct
import zlib


def chunk(tag, data):
    body = tag + data
    return (struct.pack(">I", len(data)) + body
            + struct.pack(">I", zlib.crc32(body) & 0xffffffff))


raw = b"\x00\xff\xff\xff"
png = (b"\x89PNG\r\n\x1a\n"
       + chunk(b"IHDR", struct.pack(">IIBBBBB", 1, 1, 8, 2, 0, 0, 0))
       + chunk(b"IDAT", zlib.compress(raw))
       + chunk(b"IEND", b""))
print("data:image/png;base64," + base64.b64encode(png).decode("ascii"))
' 2>/dev/null
}

# 发一次最小请求：一张小图加一句话。返回里有内容就打印出长度。
minimal_request() {
  MODEL_NAME="$1"
  IMAGE_URI="$(tiny_image)"
  [ -n "$IMAGE_URI" ] || return 1
  BODY="$(MODEL_NAME="$MODEL_NAME" IMAGE_URI="$IMAGE_URI" python3 -c '
import json
import os

payload = {
    "model": os.environ["MODEL_NAME"],
    "messages": [{
        "role": "user",
        "content": [
            {"type": "image_url",
             "image_url": {"url": os.environ["IMAGE_URI"]}},
            {"type": "text", "text": "用一个词说这张图是什么颜色。"},
        ],
    }],
    "temperature": 0,
    "max_tokens": 16,
}
print(json.dumps(payload))
' 2>/dev/null)"
  [ -n "$BODY" ] || return 1
  printf '%s' "$BODY" | curl -s -m "$API_TIMEOUT" "$API_BASE/chat/completions" \
    -H "Content-Type: application/json" \
    --data-binary @- 2>/dev/null | python3 -c '
import json
import sys

try:
    data = json.load(sys.stdin)
except Exception:
    sys.exit(1)
choices = data.get("choices") or []
if not choices:
    sys.exit(1)
text = (choices[0].get("message") or {}).get("content")
if not text:
    sys.exit(1)
print(len(text))
' 2>/dev/null
}

printf '单据 OCR 体检\n'
printf '  时间          %s\n' "$(date '+%F %T')"
printf '  查的接口      %s\n' "$API_BASE"
printf '  schema        %s\n' "$SCHEMA_FILE"
printf '  脚本目录      %s\n' "$SCRIPTS_DIR"
printf '\n'

# ---------------------------------------------------------------- 1
printf '第 1 项　视觉模型服务在不在\n'
if ! have curl; then
  skip "这台机器上没有 curl，发不了请求"
elif ! have python3; then
  skip "这台机器上没有 python3，解不了返回的 JSON"
elif ! curl -s -m 10 -o /dev/null "$API_BASE/models" 2>/dev/null; then
  bad "$API_BASE 连不上（教材第 8 卷第 2 章：systemctl status ocr-vlm --no-pager）"
  note "服务没起来，或者端口不是 $OCR_PORT。端口不一样用 CHECK_OCR_PORT 指定。"
else
  FOUND_MODEL="$(detect_model)"
  if [ -n "$FOUND_MODEL" ]; then
    ok "服务在跑，它说自己加载的是 $FOUND_MODEL"
    [ -z "$OCR_MODEL" ] && OCR_MODEL="$FOUND_MODEL"
  else
    bad "服务连得上，但 /v1/models 没有返回模型名（教材第 8 卷第 2 章）"
    note "多半是模型还在加载，或者这个服务不是视觉模型那一个。"
  fi
fi

# ---------------------------------------------------------------- 2
printf '\n第 2 项　跑得通一次最小请求\n'
if ! have curl || ! have python3; then
  skip "缺 curl 或者 python3，这一项查不了"
elif [ -z "$OCR_MODEL" ]; then
  skip "不知道模型名，第 1 项没过。知道的话用 CHECK_OCR_MODEL 指定"
else
  REPLY_LEN="$(minimal_request "$OCR_MODEL")"
  if [ -n "$REPLY_LEN" ]; then
    ok "发了一张 1×1 的小图加一句话，模型回了 $REPLY_LEN 个字符"
    note "这一项只证明图文一起发这条路是通的，不证明它读单据读得准。"
    note "带 json_schema 约束的那条路要跑一次 ocr_one.py 才算数（教材第 8 卷第 4 章）。"
  else
    bad "最小请求没有拿到回答（教材第 8 卷第 2 章、第 4 章）"
    note "常见三种：模型加载超过了 $API_TIMEOUT 秒、起服务时没挂 --mmproj、模型名不对。"
    note "没挂 --mmproj 的话模型看不见图，这是最常见的一种。"
  fi
fi

# ---------------------------------------------------------------- 3
printf '\n第 3 项　schema 文件在不在，是不是合法 JSON\n'
if [ ! -f "$SCHEMA_FILE" ]; then
  bad "找不到 $SCHEMA_FILE（教材第 8 卷第 3 章）"
  note "本案例目录里有 invoice_schema.example.json，照它改一份放过去。"
elif ! have python3; then
  skip "没有 python3，认不了这个文件是不是合法 JSON"
else
  SCHEMA_INFO="$(python3 -c '
import json
import sys

try:
    with open(sys.argv[1], encoding="utf-8") as handle:
        schema = json.load(handle)
except Exception as error:
    print("坏|" + str(error))
    sys.exit(0)
if not isinstance(schema, dict):
    print("坏|最外面那一层不是一个对象")
    sys.exit(0)
props = schema.get("properties")
if not isinstance(props, dict) or not props:
    print("坏|没有 properties，或者里面一个字段都没有")
    sys.exit(0)
required = schema.get("required") or []
missing = [name for name in props if name not in required]
extra = schema.get("additionalProperties")
print("好|%d|%d|%s|%s" % (
    len(props), len(required),
    ",".join(missing[:5]) or "无",
    "关着" if extra is False else "没关",
))
' "$SCHEMA_FILE" 2>/dev/null)"
  case "$SCHEMA_INFO" in
    好\|*)
      IFS='|' read -r _ N_PROPS N_REQ MISSING EXTRA <<EOF
$SCHEMA_INFO
EOF
      ok "$SCHEMA_FILE 是合法 JSON，$N_PROPS 个字段，required 写了 $N_REQ 个"
      if [ "$MISSING" != "无" ]; then
        note "这几个字段没写进 required：$MISSING （教材第 8 卷第 3 章那三条规矩）"
      fi
      if [ "$EXTRA" = "没关" ]; then
        note "additionalProperties 没设成 false，模型可能多吐字段（教材第 8 卷第 3 章）。"
      fi
      ;;
    坏\|*)
      bad "$SCHEMA_FILE 有问题：${SCHEMA_INFO#坏|}（教材第 8 卷第 3 章）"
      ;;
    *)
      skip "读不出这个文件的情况，跳过"
      ;;
  esac
fi

# ---------------------------------------------------------------- 4
printf '\n第 4 项　依赖齐不齐\n'
DEP_MISSING=""
if have pdftoppm; then
  ok "pdftoppm 在（PDF 转图片靠它）"
else
  bad "没有 pdftoppm（教材第 8 卷第 4 章：sudo apt install -y poppler-utils）"
  DEP_MISSING="yes"
fi

if have python3; then
  ok "python3 在，版本 $(python3 -V 2>&1 | awk '{print $2}')"
else
  bad "没有 python3，这一卷三个脚本一个都跑不了"
  DEP_MISSING="yes"
fi

if have curl; then
  ok "curl 在"
else
  skip "没有 curl。脚本本身不用它，但排查接口的时候要用"
fi

if have python3 && python3 -c "import openpyxl" >/dev/null 2>&1; then
  ok "openpyxl 在（台账写成 xlsx 用得上，教材第 8 卷第 11 章）"
else
  skip "没有 openpyxl。只出 CSV 的话用不着；要写 xlsx 见教材第 8 卷第 11 章"
fi

[ -n "$DEP_MISSING" ] && note "这一卷的三个脚本只用 Python 自带的东西，除了上面标出来的那几样。"

# ---------------------------------------------------------------- 5
printf '\n第 5 项　目录和脚本在不在\n'
for one in ocr_one.py ocr_batch.py validate.py; do
  if [ -f "$SCRIPTS_DIR/$one" ]; then
    ok "$SCRIPTS_DIR/$one 在"
  else
    bad "找不到 $SCRIPTS_DIR/$one（教材第 8 卷第 4、5、7 章）"
  fi
done

if [ -d "$DATA_DIR" ]; then
  ok "原件目录 $DATA_DIR 在"
else
  skip "找不到 $DATA_DIR。用 CHECK_DATA_DIR 指定，或者按教材第 8 卷第 4 章建出来"
fi

if [ -d "$PROJECT_DIR" ]; then
  ok "结果目录 $PROJECT_DIR 在"
  for sub in out failed; do
    if [ -d "$PROJECT_DIR/$sub" ]; then
      SUB_N="$(find "$PROJECT_DIR/$sub" -mindepth 1 2>/dev/null | wc -l | tr -d ' ')"
      note "$sub/ 里有 $SUB_N 项"
    else
      note "$sub/ 还没有。跑一次 ocr_batch.py 它自己会建（教材第 8 卷第 5 章）。"
    fi
  done
  for one in ledger.csv review.csv; do
    [ -f "$PROJECT_DIR/$one" ] && note "$one 在"
  done
  note "这一项只看目录和文件在不在，不打开它们，也不判断内容对不对。"
else
  skip "找不到 $PROJECT_DIR，还没跑过。用 CHECK_PROJECT_DIR 指定"
fi

# ---------------------------------------------------------------- 结果
printf '\n结果　通过 %d 项，不通过 %d 项，跳过 %d 项\n' "$PASS" "$FAIL" "$SKIP"

if [ "$FAIL" -gt 0 ]; then
  printf '体检没过。上面每一条“不通过”后面都写了回哪一章。\n'
  exit 1
fi

printf '体检通过。真正的验收是跑完一批之后台账对得上、复核队列里那几行你看得懂。\n'
exit 0
