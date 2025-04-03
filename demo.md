# 🎬 Demo: Multi-layer Execution System

## 📜 1. YAML Script
```yaml
metadata:
  title: "Demo Execution"
  description: "Thực thi mã Python và C++ từ YAML script"
tasks:
  - action: "print_message"
    message: "Hello from YAML!"
  - action: "binary_execute"
    binary_code: !!binary |
      VyBI5pdrYW5zaABUIGJpbmFyeSBleGFtcGxl
  - action: "calculate"
    operation: "add"
    numbers:
      - 10
      - 20

## 📜 2. Python Script

import yaml

# Đọc YAML file
with open('example.yaml', 'r') as file:
    yaml_script = yaml.safe_load(file)

# Thực thi các hành động trong YAML
for task in yaml_script['tasks']:
    action = task['action']
    
    if action == "print":
        print(task['message'])
    
    elif action == "calculate":
        if task['operation'] == "add":
            result = sum(task['numbers'])
            print(f"Kết quả phép tính: {result}")
    
    elif action == "file_write":
        with open(task['filename'], 'w') as f:
            f.write(task['content'])
        print(f"File '{task['filename']}' đã được tạo!")

## 📜 3. C Code

#include <stdio.h>
int main() {
    printf("Hello from Binary Code!\n");
    return 0;
}

gcc -o binary_example binary_code.c
base64 binary_example > encoded_binary.txt

## 📜 4. Python Script execute 
python3 demo.py
