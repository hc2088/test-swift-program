import os
import re
import json
import argparse
import shutil
from collections import defaultdict

# ========== 参数解析 ==========
parser = argparse.ArgumentParser()
parser.add_argument("--base", required=True, help="原始 .lproj 资源目录")
parser.add_argument("--target", required=False, help="追加 JSON 的目标目录")
parser.add_argument("--a", action="store_true", help="是否将结果追加到目标 JSON")
args = parser.parse_args()

base_dir = args.base
target_append_dir = args.target
should_append = args.a

source_locale = "zh-Hans.lproj"
output_dir = os.path.join(os.getcwd(), "lproj-json")
log_output_path = os.path.join(output_dir, "translation_log.txt")

# ==== 启动时清理 lproj-json 文件夹，如果 translation_log.txt 存在 ====
if os.path.exists(log_output_path):
    print(f"检测到之前的日志文件 {log_output_path}，开始删除整个 {output_dir} 文件夹...")
    shutil.rmtree(output_dir)
    print(f"已删除 {output_dir} 文件夹，准备重新生成内容")

# ===== 映射表 =====
mapping_raw = """
ar
as
az
be
bg-BG:bg
bn-IN:bn
bn
bo
bs
ca
cs
da
de
el
en-AU
en-GB
en-IN
en:en-US
es-419:es
es-MX:es
es
et
eu
fa
fi
fr
gl
gu-IN:gu
ha
he-IL:he
he
hi
hr
hu
hy-AM:hy
id
is
it
ja
ka
kk
km
kn
ko
lo
lt
lv
mk
ml-IN:ml
mr
ms
mt
my
nb
ne-IN:ne
ne-NP:ne
nl
or
pa-IN:pa
pl
pt-BR
pt-PT
ro
ru
sk
sl
sq
sr
sv
sw
ta
te
th
tr
ug
uk
ur-IN
ur-PK
uz
vi
zh-Hans:zh-CN
zh-Hant-HK:zh-HK
zh-Hant:zh-HK
"""

key_override_map = {
    "运动": "sport.tabName",
    "户外跑步": "sport.entry.outdoorRunning",
    "健走": "sport.entry.outsideWalking",
    "户外骑行": "sport.entry.outsideRiding",
    "室内跑步": "sport.entry.indoorRunning",
    "跳绳": "sport.entry.ropeSkipping",
    "运动记录": "sport.plan.sportRecord",
    "全部": "all.title",
    "暂无运动记录": "sport.plan.noRecord",
    "训练指标": "sport.plan.trainingIndicator",
    "扫一扫": "sport.plan.scanQRCode",
    "添加设备": "sport.plan.addDevice",
    "动感单车": "sport.entry.indoorBicycle"
}
target_values = list(key_override_map.keys())

def ensure_dir(path):
    if not os.path.exists(path):
        os.makedirs(path)

def parse_strings_file(filepath):
    translations = {}
    if not os.path.exists(filepath):
        return translations
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        matches = re.findall(r'"(.*?)"\s*=\s*"(.+?)";', content)
        for key, value in matches:
            translations[key] = value
    return translations

mapping = {}
for line in mapping_raw.strip().splitlines():
    line = line.strip()
    if not line:
        continue
    if ':' in line:
        k, v = line.split(':', 1)
        mapping[k] = v
    else:
        mapping[line] = line

# ===== 初始化 =====
ensure_dir(output_dir)
log_lines = []

def log(msg):
    print(msg)
    log_lines.append(msg)

# ===== Step 1: 解析源语言 zh-Hans.lproj =====
source_file = os.path.join(base_dir, source_locale, "Localizable.strings")
source_map = parse_strings_file(source_file)
reverse_source_map = defaultdict(list)
for k, v in source_map.items():
    reverse_source_map[v].append(k)

value_to_key_map = {}
initial_key_list = []
log("\n🔍 Step 1: 从 zh-Hans.lproj 反向查找目标value对应的key和备选key")
for val in target_values:
    keys = reverse_source_map.get(val)
    if keys:
        main_key = keys[0]
        fallback_keys = keys[1:]
        initial_key_list.append(main_key)
        value_to_key_map[main_key] = {"value": val, "fallback_keys": fallback_keys}
        log(f"  ✅ \"{val}\" => 主key: {main_key}，备选key: {fallback_keys}")
    else:
        log(f"  ❌ \"{val}\" 未找到对应key")

# ===== Step 2: 多语言包翻译查找 =====
translations_all = defaultdict(dict)
missing_keys_log = defaultdict(list)
processed_json_targets = set()
lproj_folders = [d for d in os.listdir(base_dir) if d.endswith('.lproj') and d != source_locale]

for folder in sorted(lproj_folders):
    locale_code = folder[:-6]
    json_target = mapping.get(locale_code, locale_code)
    if json_target in processed_json_targets:
        continue

    lproj_path = os.path.join(base_dir, folder, "Localizable.strings")
    if not os.path.exists(lproj_path):
        continue

    locale_map = parse_strings_file(lproj_path)
    output_json_dict = {}

    for orig_key in initial_key_list:
        val = value_to_key_map[orig_key]["value"]
        fallback_keys = value_to_key_map[orig_key]["fallback_keys"]
        out_key = key_override_map.get(val, orig_key)
        search_keys = [orig_key] + fallback_keys
        trans_val = None
        for k in search_keys:
            if k in locale_map:
                trans_val = locale_map[k]
                break
        if trans_val:
            output_json_dict[out_key] = trans_val
        else:
            missing_keys_log[folder].append(orig_key)

    out_path = os.path.join(output_dir, f"{json_target}.json")
    with open(out_path, 'w', encoding='utf-8') as f:
        json.dump(output_json_dict, f, ensure_ascii=False, indent=2)
    processed_json_targets.add(json_target)

# ===== Step 3: 可选追加到外部 JSON 文件，并打印新增和已存在词条 =====
if should_append and target_append_dir:

    def append_to_existing_json(target_append_dir, output_dir):
        for filename in os.listdir(output_dir):
            if not filename.endswith(".json"):
                continue
            src_path = os.path.join(output_dir, filename)
            tgt_path = os.path.join(target_append_dir, filename)

            with open(src_path, 'r', encoding='utf-8') as f:
                new_data = json.load(f)

            if os.path.exists(tgt_path):
                with open(tgt_path, 'r', encoding='utf-8') as f:
                    old_lines = f.readlines()

                try:
                    existing_data = json.loads("".join(old_lines))
                except json.JSONDecodeError:
                    msg = f"❌ 无法解析 {tgt_path}，跳过"
                    print(msg)
                    log_lines.append(msg)
                    continue

                # 区分新增和已存在的 key
                to_add = {k: v for k, v in new_data.items() if k not in existing_data}
                existing_keys = [k for k in new_data.keys() if k in existing_data]

                if not to_add:
                    msg = f"ℹ️ {tgt_path} 中已包含全部词条，无需追加"
                    print(msg)
                    log_lines.append(msg)
                    continue

                # 找到 { 所在的行号
                first_brace_index = None
                for i, line in enumerate(old_lines):
                    if line.strip() == '{':
                        first_brace_index = i
                        break
                if first_brace_index is None:
                    msg = f"❌ {tgt_path} 找不到左花括号 '{{'，跳过"
                    print(msg)
                    log_lines.append(msg)
                    continue

                # 向上寻找最后一个有效键值对行（非空、非注释、非花括号）
                last_kv_index = None
                for i in range(len(old_lines) - 1, -1, -1):
                    line_strip = old_lines[i].strip()
                    if (
                        line_strip and
                        not line_strip.startswith("//") and
                        not line_strip.startswith("/*") and
                        not line_strip.startswith("*") and
                        line_strip != "}" and
                        line_strip != "{"
                    ):
                        last_kv_index = i
                        break

                insertion = []
                items = list(to_add.items())
                if last_kv_index is None or last_kv_index <= first_brace_index:
                    # 文件为空 JSON 或无有效键值对，直接在 { 后插入，无需逗号
                    for idx, (k, v) in enumerate(items):
                        line = f'  "{k}": "{v}"'
                        if idx < len(items) - 1:
                            line += ","
                        insertion.append(line + "\n")
                    # 插入在 { 后面一行
                    new_lines = old_lines[:first_brace_index + 1] + insertion + old_lines[first_brace_index + 1:]
                else:
                    # 文件已有键值，确保最后一有效行有逗号
                    if not old_lines[last_kv_index].rstrip().endswith(","):
                        old_lines[last_kv_index] = old_lines[last_kv_index].rstrip() + ",\n"

                    for idx, (k, v) in enumerate(items):
                        line = f'  "{k}": "{v}"'
                        if idx < len(items) - 1:
                            line += ","
                        insertion.append(line + "\n")
                    # 插入在最后有效键值对行之后
                    new_lines = old_lines[:last_kv_index + 1] + insertion + old_lines[last_kv_index + 1:]

                # 写回文件
                with open(tgt_path, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)

                msg = f"✅ 已追加 {len(to_add)} 项到 {tgt_path}"
                if existing_keys:
                    msg += f"，已有 {len(existing_keys)} 项词条未追加: {existing_keys}"
                print(msg)
                log_lines.append(msg)

            else:
                # 文件不存在，直接写新文件
                with open(tgt_path, 'w', encoding='utf-8') as f:
                    json.dump(new_data, f, ensure_ascii=False, indent=2)
                msg = f"🆕 创建并写入新文件 {tgt_path}"
                print(msg)
                log_lines.append(msg)

    append_to_existing_json(target_append_dir, output_dir)

# ===== Step 4: 写入日志文件 =====
ensure_dir(output_dir)
with open(log_output_path, 'w', encoding='utf-8') as logf:
    logf.write("\n".join(log_lines))

print(f"\n日志写入完成: {log_output_path}")
