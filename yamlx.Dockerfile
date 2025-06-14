FROM python:3.10-slim

LABEL maintainer="you@example.com"
LABEL description="YAML Executor CLI Tool - Final Stable Version"

WORKDIR /app

# Cài dependencies hệ thống
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# Cài PyYAML
RUN pip install --no-cache-dir pyyaml

# Tạo thư mục module
RUN mkdir -p /app/yamlx

# Viết core.py (đã fix padding)
RUN cat <<EOF > /app/yamlx/core.py
import yaml
import base64
import subprocess
import tempfile
import os

def execute_yaml(yaml_file):
    try:
        with open(yaml_file, "r") as file:
            yaml_script = yaml.safe_load(file)
    except Exception as e:
        print(f"❌ Không thể đọc YAML: {e}")
        return

    print(f"\\n📄 Thực thi: {yaml_script.get('metadata', {}).get('title', 'YAML Script')}")
    print("="*50)

    for task in yaml_script.get("tasks", []):
        action = task.get("action")
        if action == "print_message":
            print(f"[PRINT] {task.get('message')}")
        elif action == "calculate":
            op = task.get("operation")
            nums = task.get("numbers", [])
            if op == "add":
                print(f"[CALC] Kết quả phép cộng: {sum(nums)}")
            elif op == "multiply":
                result = 1
                for n in nums:
                    result *= n
                print(f"[CALC] Kết quả nhân: {result}")
            else:
                print(f"[CALC] Phép toán không hỗ trợ: {op}")
        elif action == "file_write":
            try:
                with open(task["filename"], "w") as f:
                    f.write(task["content"])
                print(f"[WRITE] Đã ghi vào file: {task['filename']}")
            except Exception as e:
                print(f"❌ Ghi file thất bại: {e}")
        elif action == "binary_execute":
            binary_data = task.get("binary_code")
            if not binary_data:
                print("⚠️ Không có binary_code để thực thi.")
                continue
            try:
                # Fix base64 padding
                if isinstance(binary_data, str):
                    missing_padding = len(binary_data) % 4
                    if missing_padding:
                        binary_data += '=' * (4 - missing_padding)
                    binary_decoded = base64.b64decode(binary_data)
                else:
                    binary_decoded = binary_data

                with tempfile.NamedTemporaryFile(delete=False) as tmp_bin:
                    tmp_bin.write(binary_decoded)
                    tmp_path = tmp_bin.name
                os.chmod(tmp_path, 0o755)
                print(f"[BINARY] Thực thi mã nhị phân:")
                subprocess.run([tmp_path])
                os.remove(tmp_path)
            except Exception as e:
                print(f"❌ Thực thi binary thất bại: {e}")
        elif action == "run_command":
            cmd = task.get("command")
            print(f"[CMD] Chạy lệnh: {cmd}")
            try:
                subprocess.run(cmd, shell=True)
            except Exception as e:
                print(f"❌ Lỗi khi chạy lệnh: {e}")
        elif action == "python_execute":
            code = task.get("code", "")
            print("[PYTHON] Thực thi mã Python:")
            try:
                exec(code)
            except Exception as e:
                print(f"❌ Lỗi khi thực thi Python: {e}")
        else:
            print(f"⚠️ Action không được hỗ trợ: {action}")
EOF

# Viết cli.py
RUN cat <<EOF > /app/yamlx/cli.py
import argparse
import os
import sys
from yamlx.core import execute_yaml

def main():
    parser = argparse.ArgumentParser(description="🧩 YAML Executor CLI Tool")
    parser.add_argument("yaml_file", help="Đường dẫn tới YAML script")
    args = parser.parse_args()

    if not os.path.exists(args.yaml_file):
        print(f"❌ File '{args.yaml_file}' không tồn tại.")
        sys.exit(1)

    execute_yaml(args.yaml_file)
EOF

# __init__.py
RUN touch /app/yamlx/__init__.py

# setup.py
RUN cat <<EOF > /app/setup.py
from setuptools import setup, find_packages

setup(
    name="yamlx",
    version="1.0.0",
    packages=find_packages(),
    install_requires=["pyyaml"],
    entry_points={
        "console_scripts": [
            "yamlx = yamlx.cli:main"
        ]
    },
    python_requires=">=3.6"
)
EOF

# example.yaml (base64 đã đúng, dùng /bin/sh)
RUN cat <<EOF > /app/example.yaml
metadata:
  title: "Demo YAML Executor (with binary fix)"
  description: "Chạy tất cả các tác vụ hỗ trợ"
tasks:
  - action: "print_message"
    message: "🚀 Bắt đầu thực thi YAML..."
  - action: "calculate"
    operation: "add"
    numbers: [10, 20, 30]
  - action: "file_write"
    filename: "output.txt"
    content: "✅ Đã ghi file thành công!"
  - action: "run_command"
    command: "echo '📦 Shell command OK!'"
  - action: "python_execute"
    code: |
      print("🐍 Chạy Python embedded:")
      for i in range(3):
          print(f"  Dòng {i+1}")
  - action: "binary_execute"
    binary_code: !!binary |
      IyEvYmluL3NoCmVjaG8gIlx1MjU2RiBCaW5hcnkgY2jhuq9uIHThuqNpIgo=
EOF

# Cài đặt CLI tool
RUN pip install --no-cache-dir -e .

# Cho phép chạy yamlx từ dòng lệnh
##ENTRYPOINT ["bash"]
ENTRYPOINT ["yamlx", "example.yaml"]
