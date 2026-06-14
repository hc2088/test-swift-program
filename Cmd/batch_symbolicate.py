import os
import sys
import subprocess

def main():
    if len(sys.argv) < 2:
        print("用法: python3 batch_symbolicate.py <input_folder> [dsym_path]")
        sys.exit(1)

    input_folder = sys.argv[1]

    # 如果传入了 dsym_path 参数，就使用，否则使用默认路径
    if len(sys.argv) >= 3:
        dsym_path = sys.argv[2]
    else:
        dsym_path = os.path.join(input_folder, "MiJiaWear.app.dSYM")

    # CrashSymbolicator 工具路径
    symbolicator_path = "/Applications/Xcode.app/Contents/SharedFrameworks/CoreSymbolicationDT.framework/Versions/A/Resources/CrashSymbolicator.py"

    if not os.path.isdir(input_folder):
        print(f"❌ 输入文件夹不存在: {input_folder}")
        sys.exit(1)

    if not os.path.isdir(dsym_path):
        print(f"❌ 找不到 dSYM 文件夹: {dsym_path}")
        sys.exit(1)

    # 遍历 .ips 文件
    for filename in os.listdir(input_folder):
        if filename.endswith(".ips") and not filename.endswith("-decoded.ips"):
            input_path = os.path.join(input_folder, filename)
            base_name = os.path.splitext(filename)[0]
            output_name = f"{base_name}-decoded.ips"
            output_path = os.path.join(input_folder, output_name)

            if os.path.exists(output_path):
                print(f"⚠️ 已存在，跳过: {output_name}")
                continue

            print(f"📦 正在符号化: {filename} → {output_name}")

            cmd = [
                "python3",
                symbolicator_path,
                "-d", dsym_path,
                "-o", output_path,
                "-p", input_path
            ]

            try:
                subprocess.run(cmd, check=True)
                print(f"✅ 完成: {output_name}")
            except subprocess.CalledProcessError as e:
                print(f"❌ 错误: {filename} 符号化失败，原因: {e}")

    print("\n🎉 所有 .ips 文件符号化任务完成")

if __name__ == "__main__":
    main()
