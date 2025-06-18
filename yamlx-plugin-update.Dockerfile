FROM python:3.10-slim

LABEL maintainer="you@example.com"
LABEL description="YAML Executor CLI Tool - Plugin Ready"

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

RUN pip install --no-cache-dir pyyaml

RUN mkdir -p /app/yamlx/actions

RUN touch /app/yamlx/__init__.py && touch /app/yamlx/actions/__init__.py

# registry.py
RUN cat <<EOF > /app/yamlx/registry.py
ACTION_REGISTRY = {}

def register(name):
    def wrapper(func):
        ACTION_REGISTRY[name] = func
        return func
    return wrapper

def get_action(name):
    return ACTION_REGISTRY.get(name)
EOF

# core.py
RUN cat <<EOF > /app/yamlx/core.py
import yaml
from yamlx.registry import get_action
import importlib
import os

def load_actions():
    actions_dir = os.path.join(os.path.dirname(__file__), "actions")
    for f in os.listdir(actions_dir):
        if f.endswith(".py") and not f.startswith("_"):
            importlib.import_module(f"yamlx.actions.{f[:-3]}")

def execute_yaml(yaml_file):
    load_actions()
    try:
        with open(yaml_file, "r") as file:
            yaml_script = yaml.safe_load(file)
    except Exception as e:
        print(f"❌ Không thể đọc YAML: {e}")
        return

    print(f"\\n📄 Thực thi: {yaml_script.get('metadata', {}).get('title', 'YAML Script')}")
    print("="*50)

    for task in yaml_script.get("tasks", []):
        action_name = task.get("action")
        action_func = get_action(action_name)
        if action_func:
            try:
                action_func(task)
            except Exception as e:
                print(f"❌ Lỗi khi xử lý action '{action_name}': {e}")
        else:
            print(f"⚠️ Action không được hỗ trợ: {action_name}")
EOF

# cli.py
RUN cat <<EOF > /app/yamlx/cli.py
import argparse
import os
import sys
from yamlx.core import execute_yaml

def main():
    parser = argparse.ArgumentParser(description="🧩 YAML Executor CLI Tool (Pluggable)")
    parser.add_argument("yaml_file", help="Đường dẫn tới YAML script")
    args = parser.parse_args()

    if not os.path.exists(args.yaml_file):
        print(f"❌ File '{args.yaml_file}' không tồn tại.")
        sys.exit(1)

    execute_yaml(args.yaml_file)
EOF

# setup.py
RUN cat <<EOF > /app/setup.py
from setuptools import setup, find_packages

setup(
    name="yamlx",
    version="2.0.0",
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

# --- ACTION plug-ins ---
# print_message
RUN cat <<EOF > /app/yamlx/actions/print_message.py
from yamlx.registry import register

@register("print_message")
def handle(task):
    print(f"[PRINT] {task.get('message')}")
EOF

# calculate
RUN cat <<EOF > /app/yamlx/actions/calculate.py
from yamlx.registry import register

@register("calculate")
def handle(task):
    op = task.get("operation")
    nums = task.get("numbers", [])
    if op == "add":
        print(f"[CALC] Kết quả cộng: {sum(nums)}")
    elif op == "multiply":
        result = 1
        for n in nums:
            result *= n
        print(f"[CALC] Kết quả nhân: {result}")
    else:
        print(f"[CALC] Phép toán không hỗ trợ: {op}")
EOF

# run_command
RUN cat <<EOF > /app/yamlx/actions/run_command.py
import subprocess
from yamlx.registry import register

@register("run_command")
def handle(task):
    cmd = task.get("command")
    print(f"[CMD] Chạy lệnh: {cmd}")
    try:
        subprocess.run(cmd, shell=True)
    except Exception as e:
        print(f"❌ Lỗi khi chạy lệnh: {e}")
EOF

# file_write
RUN cat <<EOF > /app/yamlx/actions/file_write.py
from yamlx.registry import register

@register("file_write")
def handle(task):
    try:
        with open(task["filename"], "w") as f:
            f.write(task["content"])
        print(f"[WRITE] Đã ghi file: {task['filename']}")
    except Exception as e:
        print(f"❌ Ghi file thất bại: {e}")
EOF

# python_execute
RUN cat <<EOF > /app/yamlx/actions/python_execute.py
from yamlx.registry import register

@register("python_execute")
def handle(task):
    print("[PYTHON] Thực thi mã Python:")
    try:
        exec(task.get("code", ""))
    except Exception as e:
        print(f"❌ Lỗi khi thực thi Python: {e}")
EOF

# binary_execute
RUN cat <<EOF > /app/yamlx/actions/binary_execute.py
import base64, tempfile, subprocess, os
from yamlx.registry import register

@register("binary_execute")
def handle(task):
    binary_data = task.get("binary_code")
    if not binary_data:
        print("⚠️ Không có binary_code.")
        return
    try:
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
        print(f"[BINARY] Thực thi binary:")
        subprocess.run([tmp_path])
        os.remove(tmp_path)
    except Exception as e:
        print(f"❌ Thực thi binary thất bại: {e}")
EOF

# example.yaml
RUN cat <<EOF > /app/demo.yaml
metadata:
  title: "🎯 YAML Executor - Plugin Demo"
tasks:
  - action: "print_message"
    message: "👋 Xin chào!"
  - action: "calculate"
    operation: "add"
    numbers: [5, 10, 15]
  - action: "file_write"
    filename: "output.txt"
    content: "Ghi dữ liệu thành công!"
  - action: "run_command"
    command: "echo '🎉 Lệnh shell OK!'"
  - action: "python_execute"
    code: |
      print("🔥 Python được thực thi:")
      for i in range(2):
          print("  Dong", i)
  - action: "binary_execute"
    binary_code: !!binary |
      IyEvYmluL3NoCmVjaG8gIlxu4peEIEJpbmFyeSBleGVjdXRlZCIK
EOF

# Cài đặt CLI tool
RUN pip install --no-cache-dir -e .

# Tự động chạy thử
ENTRYPOINT ["yamlx", "demo.yaml"]
