# ==========================
# 📦 YAML Executor Dockerfile
# ==========================

# 1. Base image
FROM python:3.10-slim

# 2. Metadata
LABEL maintainer="you@example.com"
LABEL description="YAML Executor CLI Tool - Run YAML-defined tasks from command line"

# 3. Create working directory
WORKDIR /app

# 4. Copy all files into container
COPY . /app

# 5. Install dependencies
RUN pip install --no-cache-dir pyyaml

# 6. Create project structure
RUN mkdir -p yamlx

# 7. Write core.py
RUN echo '\
import yaml\n\
import base64\n\
import subprocess\n\
import tempfile\n\
import os\n\
\ndef execute_yaml(yaml_file):\n\
    try:\n\
        with open(yaml_file, \"r\") as file:\n\
            yaml_script = yaml.safe_load(file)\n\
    except Exception as e:\n\
        print(f\"❌ Không thể đọc YAML: {e}\")\n\
        return\n\
    print(f\"\\n📄 Thực thi: {yaml_script.get('metadata', {}).get('title', 'YAML Script')}\")\n\
    print(\"=\"*50)\n\
    for task in yaml_script.get(\"tasks\", []):\n\
        action = task.get(\"action\")\n\
        if action == \"print_message\":\n\
            print(f\"[PRINT] {task.get('message')}\")\n\
        elif action == \"calculate\":\n\
            op = task.get(\"operation\")\n\
            nums = task.get(\"numbers\", [])\n\
            if op == \"add\":\n\
                print(f\"[CALC] Kết quả phép cộng: {sum(nums)}\")\n\
            elif op == \"multiply\":\n\
                result = 1\n\
                for n in nums:\n\
                    result *= n\n\
                print(f\"[CALC] Kết quả nhân: {result}\")\n\
            else:\n\
                print(f\"[CALC] Phép toán không hỗ trợ: {op}\")\n\
        elif action == \"file_write\":\n\
            try:\n\
                with open(task[\"filename\"], \"w\") as f:\n\
                    f.write(task[\"content\"])\n\
                print(f\"[WRITE] Đã ghi vào file: {task['filename']}\")\n\
            except Exception as e:\n\
                print(f\"❌ Ghi file thất bại: {e}\")\n\
        elif action == \"binary_execute\":\n\
            binary_data = task.get(\"binary_code\")\n\
            if not binary_data:\n\
                print(\"⚠️ Không có binary_code để thực thi.\")\n\
                continue\n\
            try:\n\
                binary_decoded = base64.b64decode(binary_data)\n\
                with tempfile.NamedTemporaryFile(delete=False) as tmp_bin:\n\
                    tmp_bin.write(binary_decoded)\n\
                    tmp_path = tmp_bin.name\n\
                os.chmod(tmp_path, 0o755)\n\
                print(f\"[BINARY] Thực thi mã nhị phân:\")\n\
                subprocess.run([tmp_path])\n\
                os.remove(tmp_path)\n\
            except Exception as e:\n\
                print(f\"❌ Thực thi binary thất bại: {e}\")\n\
        elif action == \"run_command\":\n\
            cmd = task.get(\"command\")\n\
            print(f\"[CMD] Chạy lệnh: {cmd}\")\n\
            try:\n\
                subprocess.run(cmd, shell=True)\n\
            except Exception as e:\n\
                print(f\"❌ Lỗi khi chạy lệnh: {e}\")\n\
        elif action == \"python_execute\":\n\
            code = task.get(\"code\", \"\")\n\
            print(\"[PYTHON] Thực thi mã Python:\")\n\
            try:\n\
                exec(code)\n\
            except Exception as e:\n\
                print(f\"❌ Lỗi khi thực thi Python: {e}\")\n\
        else:\n\
            print(f\"⚠️ Action không được hỗ trợ: {action}\")\n\
' > yamlx/core.py

# 8. Write cli.py
RUN echo '\
import argparse\n\
import os\n\
import sys\n\
from yamlx.core import execute_yaml\n\
\ndef main():\n\
    parser = argparse.ArgumentParser(description=\"🧩 YAML Executor CLI Tool\")\n\
    parser.add_argument(\"yaml_file\", help=\"Đường dẫn tới YAML script\")\n\
    args = parser.parse_args()\n\
    if not os.path.exists(args.yaml_file):\n\
        print(f\"❌ File '{args.yaml_file}' không tồn tại.\")\n\
        sys.exit(1)\n\
    execute_yaml(args.yaml_file)\n\
' > yamlx/cli.py

# 9. Create __init__.py
RUN touch yamlx/__init__.py

# 10. Write example.yaml
RUN echo '\
metadata:\n\
  title: \"Demo YAML Executor\"\n\
  description: \"Chạy lệnh, tính toán, ghi file, và chạy binary\"\n\
tasks:\n\
  - action: \"print_message\"\n\
    message: \"🚀 Bắt đầu thực thi YAML...\"\n\
  - action: \"calculate\"\n\
    operation: \"add\"\n\
    numbers: [5, 15, 30]\n\
  - action: \"file_write\"\n\
    filename: \"result.txt\"\n\
    content: \"✅ File được ghi từ YAML Executor!\"\n\
  - action: \"run_command\"\n\
    command: \"echo '📦 Lệnh shell đã chạy thành công!'\"\n\
  - action: \"python_execute\"\n\
    code: |\n\
      print(\"🐍 Python inline đang chạy!\")\n\
      for i in range(3):\n\
          print(f\"  Dòng {i+1}\")\n\
  - action: \"binary_execute\"\n\
    binary_code: !!binary |\n\
      # Dán mã base64 thực thi bạn muốn vào đây\n\
' > example.yaml

# 11. Install as CLI tool
RUN echo '\
from setuptools import setup, find_packages\n\
setup(\n\
    name=\"yamlx\",\n\
    version=\"1.0.0\",\n\
    packages=find_packages(),\n\
    install_requires=[\"pyyaml\"],\n\
    entry_points={\n\
        \"console_scripts\": [\n\
            \"yamlx = yamlx.cli:main\"\n\
        ]\n\
    },\n\
    python_requires=\">=3.6\"\n\
)\n\
' > setup.py

# 12. Install the tool
RUN pip install .

# 13. Set default command to run example.yaml
CMD ["yamlx", "example.yaml"]
