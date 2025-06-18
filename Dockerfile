FROM python:3.10-slim

LABEL maintainer="you@example.com"
LABEL description="yamlx workflow CLI tool - full-featured"

WORKDIR /app

# Cài hệ thống
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential curl \
 && rm -rf /var/lib/apt/lists/*

# Cài Python packages
RUN pip install --no-cache-dir pyyaml requests jinja2

# Tạo thư mục module
RUN mkdir -p /app/yamlx/actions
WORKDIR /app/yamlx

# __init__.py
RUN touch __init__.py && touch actions/__init__.py

# registry.py
RUN cat <<EOF > registry.py
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
RUN cat <<EOF > core.py
import yaml, importlib, os
from jinja2 import Template
from yamlx.registry import get_action

def render(value):
    return Template(value).render(env=os.environ)

def load_actions():
    path = os.path.join(os.path.dirname(__file__), "actions")
    for f in os.listdir(path):
        if f.endswith(".py") and not f.startswith("_"):
            importlib.import_module(f"yamlx.actions." + f[:-3])

def execute_yaml(file_path):
    load_actions()
    with open(file_path, "r") as f:
        data = yaml.safe_load(f)
    print("\\n📄", data.get("metadata", {}).get("title", "yamlx script"))
    print("="*40)
    for task in data.get("tasks", []):
        action = task.get("action")
        fn = get_action(action)
        if fn:
            try:
                fn(task)
            except Exception as e:
                print(f"❌ Lỗi với action '{action}': {e}")
        else:
            print(f"⚠️ Action không hỗ trợ: {action}")
EOF

# cli.py
RUN cat <<EOF > cli.py
import argparse, os, sys
from yamlx.core import execute_yaml

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("yaml_file", help="Path to YAML script")
    args = parser.parse_args()
    if not os.path.exists(args.yaml_file):
        print(f"❌ File không tồn tại: {args.yaml_file}")
        sys.exit(1)
    execute_yaml(args.yaml_file)
EOF

# setup.py
RUN cat <<EOF > /app/setup.py
from setuptools import setup, find_packages
setup(
    name="yamlx",
    version="3.0.0",
    packages=find_packages(),
    install_requires=["pyyaml", "requests", "jinja2"],
    entry_points={"console_scripts": ["yamlx = yamlx.cli:main"]},
)
EOF

# Actions: print
RUN cat <<EOF > actions/print_message.py
from yamlx.registry import register
@register("print_message")
def _(task):
    print("[PRINT]", task.get("message"))
EOF

# Actions: calculate
RUN cat <<EOF > actions/calculate.py
from yamlx.registry import register
@register("calculate")
def _(task):
    op = task.get("operation")
    nums = task.get("numbers", [])
    if op == "add":
        print("[CALC] Tổng:", sum(nums))
    elif op == "multiply":
        r = 1
        for n in nums: r *= n
        print("[CALC] Nhân:", r)
    else:
        print("[CALC] Không hỗ trợ:", op)
EOF

# Actions: shell
RUN cat <<EOF > actions/run_command.py
import subprocess
from yamlx.registry import register
from yamlx.core import render
@register("run_command")
def _(task):
    cmd = render(task.get("command"))
    print("[SHELL] ⇨", cmd)
    subprocess.run(cmd, shell=True)
EOF

# Actions: file_write
RUN cat <<EOF > actions/file_write.py
from yamlx.registry import register
@register("file_write")
def _(task):
    with open(task["filename"], "w") as f:
        f.write(task["content"])
    print("[WRITE] →", task["filename"])
EOF

# Actions: python_execute
RUN cat <<EOF > actions/python_execute.py
from yamlx.registry import register
@register("python_execute")
def _(task):
    print("[PYTHON]")
    try:
        exec(task.get("code", ""))
    except Exception as e:
        print("⚠️ Python error:", e)
EOF

# Actions: binary_execute
RUN cat <<EOF > actions/binary_execute.py
import base64, tempfile, subprocess, os
from yamlx.registry import register
@register("binary_execute")
def _(task):
    code = task.get("binary_code", "")
    if isinstance(code, str):
        code += "=" * ((4 - len(code) % 4) % 4)
        code = base64.b64decode(code)
    with tempfile.NamedTemporaryFile(delete=False) as f:
        f.write(code)
        path = f.name
    os.chmod(path, 0o755)
    print("[BIN] ⇨", path)
    subprocess.run([path])
    os.remove(path)
EOF

# Actions: http_request
RUN cat <<EOF > actions/http_request.py
import requests
from yamlx.registry import register
@register("http_request")
def _(task):
    method = task.get("method", "GET").upper()
    url = task.get("url")
    print("[HTTP]", method, url)
    res = requests.request(method, url)
    print("[RESP]", res.status_code)
    print(res.text[:200])
EOF

# Sample YAML
RUN cat <<EOF > /app/example.yaml
metadata:
  title: "🌟 YAMLX All-in-One Demo"
tasks:
  - action: print_message
    message: "🚀 Bắt đầu quy trình"
  - action: calculate
    operation: multiply
    numbers: [2, 3, 4]
  - action: file_write
    filename: hello.txt
    content: "✅ File đã được ghi"
  - action: run_command
    command: "echo 'Hello from {{ env.USER }}'"
  - action: python_execute
    code: |
      print("→ Python đang chạy:")
      for i in range(2):
          print("  Dòng", i)
  - action: http_request
    method: GET
    url: https://httpbin.org/get
  - action: binary_execute
    binary_code: !!binary |
      IyEvYmluL3NoCmVjaG8gIlxu4peEIEJpbmFyeSBydW4gdGltZSEiCg==
EOF

# Install tool
RUN pip install --no-cache-dir -e /app

#ENTRYPOINT ["yamlx", "example.yaml"]
