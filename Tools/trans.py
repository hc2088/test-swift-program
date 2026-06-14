import os
import re
import json
import argparse
import shutil
from collections import defaultdict


# 操作实例
# python ./trans.py --base /Users/mi/Documents/miwear/MiJiaWear/Resource --target /Users/mi/Documents/fitness-rn/app/assets/sport/res/localizedString --a



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

if os.path.exists(log_output_path):
    print(f"检测到之前的日志文件 {log_output_path}，开始删除整个 {output_dir} 文件夹...")
    shutil.rmtree(output_dir)
    print(f"已删除 {output_dir} 文件夹，准备重新生成内容")



# ===== 映射表规则说明 =====
# - 若 "xx-YY:xx" 表示将地区变种（如 ne-IN）映射到通用语言（如 ne）
# - 若 "xx" 没有冒号，表示原样输出为 xx.json
# - 未在此列出的语言将会被跳过，不会生成 JSON
# 多对一说明：
# zh-Hant-HK:zh-HK
#   zh-Hant:zh-HK 只会有第一个出现的目录被处理写入 zh-HK.json



# ===== 支持注释的映射表 =====
mapping_raw_lines = [
    "ar",
    "as",
    "az",
    "be",
    "bg-BG:bg",   # 保加利亚语
    "bn-IN:bn",   # 孟加拉语（印度）
    "bn",
    #"bo",  #藏语，IOS没有藏语，不处理
    "bs",
    "ca",
    "cs",
    "da",
    "de",         # 德语
    "el",
    "en-AU",      # 英语（澳洲）
    "en-GB",      # 英语（英国）
    "en-IN",      # 英语（印度）
    "en:en-US",   # 默认英语映射到美国英语
    "es",
    "et",
    "eu",
    "fa",
    "fi",
    "fr",
    "gl",
    "gu-IN:gu",
    "ha",
    "he",
    "hi",
    "hr",
    "hu",
    "hy-AM:hy",
    "id",
    "is",
    "it",
    "ja",
    "ka",
    "kk",
    "km",
    "kn",
    "ko",
    "lo",
    "lt",
    "lv",
    "mk",
    "ml-IN:ml",
    "mr",
    "ms",
    "mt",
    "my",
    "nb",
    "ne-IN:ne",     # 尼泊尔语（印度）
    "ne-NP:ne",     # 尼泊尔语（尼泊尔）
    "nl",
    "or",
    "pa-IN:pa",
    "pl",
    "pt-BR",
    "pt-PT",
    "ro",
    "ru",
    "sk",
    "sl",
    "sq",
    "sr",
    "sv",
    "sw",
    "ta",
    "te",
    "th",
    "tr",
    #"ug", #维吾尔语，IOS没有维吾尔语 不处理
    "uk",
    "ur-IN",
    "ur-PK",
    "uz",
    "vi",
    "zh-Hans:zh-CN",     # 简体中文
    "zh-Hant-HK:zh-HK",  # 繁体中文（香港）
    "zh-Hant:zh-HK",     # 也指向香港
    "zh-Hant:zh-TW",     # 可切换为台湾（注释其中一个即可）
]

# ===== Key 映射 =====
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

# ===== 解析映射表（带注释）=====
mapping = {}
for line in mapping_raw_lines:
    line = line.strip()
    if not line or line.startswith("#"):
        continue
    if "#" in line:
        line = line.split("#", 1)[0].strip()
    if ":" in line:
        k, v = line.split(":", 1)
        mapping[k.strip()] = v.strip()
    else:
        mapping[line] = line

# ===== 初始化 =====
ensure_dir(output_dir)
log_lines = []

def log(msg):
    print(msg)
    log_lines.append(msg)

# ===== Step 1: 获取 zh-Hans.lproj 的原始键值表 =====
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

# ===== Step 2: 遍历多语言包并输出 JSON =====
translations_all = defaultdict(dict)
missing_keys_log = defaultdict(list)
processed_json_targets = set()
lproj_folders = [d for d in os.listdir(base_dir) if d.endswith('.lproj') and d != source_locale]

for folder in sorted(lproj_folders):
    locale_code = folder[:-6]
    if locale_code not in mapping:
        continue  # ❌ 不在 mapping 表中的语言，不处理

    json_target = mapping[locale_code]
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

# ===== Step 3: 可选追加到已有 JSON 文件 =====
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

                to_add = {k: v for k, v in new_data.items() if k not in existing_data}
                existing_keys = [k for k in new_data.keys() if k in existing_data]

                if not to_add:
                    msg = f"ℹ️ {tgt_path} 中已包含全部词条，无需追加"
                    print(msg)
                    log_lines.append(msg)
                    continue

                first_brace_index = next((i for i, l in enumerate(old_lines) if l.strip() == '{'), None)
                last_kv_index = next((i for i in reversed(range(len(old_lines))) if old_lines[i].strip() and not old_lines[i].strip().startswith("//") and old_lines[i].strip() not in ("{", "}")), None)

                insertion = [f'  "{k}": "{v}"{"," if idx < len(to_add) - 1 else ""}\n' for idx, (k, v) in enumerate(to_add.items())]

                if last_kv_index is not None and first_brace_index is not None and last_kv_index > first_brace_index:
                    if not old_lines[last_kv_index].rstrip().endswith(","):
                        old_lines[last_kv_index] = old_lines[last_kv_index].rstrip() + ",\n"
                    new_lines = old_lines[:last_kv_index + 1] + insertion + old_lines[last_kv_index + 1:]
                else:
                    new_lines = old_lines[:first_brace_index + 1] + insertion + old_lines[first_brace_index + 1:]

                with open(tgt_path, 'w', encoding='utf-8') as f:
                    f.writelines(new_lines)

                msg = f"✅ 已追加 {len(to_add)} 项到 {tgt_path}"
                if existing_keys:
                    msg += f"，已有 {len(existing_keys)} 项词条未追加: {existing_keys}"
                print(msg)
                log_lines.append(msg)
            else:
                with open(tgt_path, 'w', encoding='utf-8') as f:
                    json.dump(new_data, f, ensure_ascii=False, indent=2)
                msg = f"🆕 创建并写入新文件 {tgt_path}"
                print(msg)
                log_lines.append(msg)

    append_to_existing_json(target_append_dir, output_dir)

# ===== Step 4: 写入日志 =====
ensure_dir(output_dir)
with open(log_output_path, 'w', encoding='utf-8') as logf:
    logf.write("\n".join(log_lines))

print(f"\n日志写入完成: {log_output_path}")
