FROM python:3.10-slim

LABEL maintainer="you@example.com"
LABEL description="YAML Executor CLI Tool - Modular Plug-in Version"

WORKDIR /app

# Cài dependencies hệ thống
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
 && rm -rf /var/lib/apt/lists/*

# Cài PyYAML
RUN pip install --no-cache-dir pyyaml

# Tạo thư mục gốc và module
RUN mkdir -p /app/yamlx/actions

# __init__.py cho package
RUN touch /app/yamlx/__init__.py && touch /app/yamlx/actions/__init__.py

# registry.py (quản lý action plug-in)
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

# core.py (main executor)
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

# print_message.py (ví dụ plug-in)
RUN cat <<EOF > /app/yamlx/actions/print_message.py
from yamlx.registry import register

@register("print_message")
def handle(task):
    print(f"[PRINT] {task.get('message')}")
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

# demo.yaml
RUN cat <<EOF > /app/demo.yaml
metadata:
  title: "Modular YAMLX Demo"
tasks:
  - action: "print_message"
    message: "🎉 Đây là YAML với kiến trúc plug-in!"
EOF

# Cài công cụ
RUN pip install --no-cache-dir -e .

ENTRYPOINT ["yamlx", "demo.yaml"]
