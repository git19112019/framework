# 🌟 Interactive Programming Learning Framework with Layered Visualization

> **Phiên bản:** 1.1  
> **Tác giả:** *[Tên của bạn]*  
> **Mục tiêu:** Định nghĩa lại cách học lập trình bằng cách phân tách các bước theo hướng trực quan và logic. Framework này được thiết kế để đơn giản hóa và trực quan hóa việc học lập trình. Bằng cách sử dụng cách tiếp cận phân lớp: Flowchart → Pseudocode → Code, người học sẽ từng bước hiểu được dòng chảy logic, xây dựng cú pháp, và triển khai chương trình thực tế một cách hiệu quả hơn.

## 🚀 Tính năng chính
- Học tập phân lớp: Từng bước dẫn dắt từ khái niệm logic cơ bản (Flowchart) đến thực thi mã nguồn (Code).
- Hỗ trợ nhiều ngôn ngữ lập trình: Hiện tại hỗ trợ C và Python, có khả năng mở rộng thêm.
- Khả năng tương tác cao: Bao gồm các ví dụ mẫu để thực hành từng bước.
- Định dạng dễ sử dụng: Sử dụng YAML và Markdown để tổ chức nội dung, giúp minh bạch và dễ hiểu.

## 📑 Cấu trúc framework  
Flowchart:
graph TD  
  A[Start] --> B[Display Menu]  
  B --> C[User Input]  
  C --> D[Perform Action]  
  D --> E[End]

Pseudocode:  
- Bắt đầu.  
- Hiển thị menu cho người dùng.  
- Thực hiện hành động dựa trên lựa chọn:  
    - Thêm nhiệm vụ.  
    - Xem danh sách nhiệm vụ.  
    - Xóa nhiệm vụ.  
    - Thoát.

Code:  
def todo_list_app():  
    tasks = []  
    while True:  
        print("\nMenu:")  
        print("1. Add Task\n2. View Tasks\n3. Exit")  
        choice = input("Choose: ")  
        if choice == "1":  
            task = input("Enter task: ")  
            tasks.append(task)  
            print("Task added!")  
        elif choice == "2":  
            print("\nTasks:")  
            for idx, task in enumerate(tasks, start=1):  
                print(f"{idx}. {task}")  
        elif choice == "3":  
            break  
        else:  
            print("Invalid choice, try again.")

## 🌟 Ví dụ mẫu  
Hello World:  
Flowchart:
graph TD  
  A[Start] --> B[Print Hello, World] --> C[End]

Pseudocode:  
- Bắt đầu.  
- Hiển thị "Hello, World!".  
- Kết thúc.

Code (C):  
#include<stdio.h>  
int main() {  
    printf("Hello, World!");  
    return 0;  
}  

Ứng dụng To-Do List:  
Flowchart:
graph TD  
  A[Start] --> B[Display Menu] --> C[User Input]  
  C --> D[Add Task] --> E[Update List]  
  C --> F[View Tasks] --> G[Display Tasks]  
  C --> H[Exit] --> I[End]

Pseudocode:  
- Bắt đầu.  
- Hiển thị menu với các tùy chọn:  
    - Thêm nhiệm vụ.  
    - Xem nhiệm vụ.  
    - Xóa nhiệm vụ.  
    - Thoát.  
- Thực hiện dựa trên lựa chọn của người dùng.

Code (Python):  
def todo_list_app():  
    tasks = []  
    while True:  
        print("\nMenu:")  
        print("1. Add Task\n2. View Tasks\n3. Exit")  
        choice = input("Choose: ")  
        if choice == "1":  
            task = input("Enter task: ")  
            tasks.append(task)  
            print("Task added!")  
        elif choice == "2":  
            print("\nTasks:")  
            for idx, task in enumerate(tasks, start=1):  
                print(f"{idx}. {task}")  
        elif choice == "3":  
            break  
        else:  
            print("Invalid choice, try again.")

## 📂 Cấu trúc thư mục dự án interactive-framework/
interactive-framework/  
├── README.md           # Tài liệu mô tả  
├── framework.yaml      # Định nghĩa logic của framework  
├── example_code/       # Chứa mã nguồn mẫu  
│   ├── hello_world.c   # Ví dụ Hello World với C  
│   ├── todo_list.py    # Ứng dụng To-Do List với Python  
├── assets/             # Hình ảnh hoặc sơ đồ (tuỳ chọn)

## 🔧 Hướng dẫn sử dụng Clone repository:
git clone https://github.com/<your-username>/<repository-name>.git  
cd interactive-framework  

## 📢 Đóng góp  
Nếu bạn muốn đóng góp hoặc có ý kiến phản hồi, hãy tạo Issue hoặc gửi Pull Request trên GitHub.

## 📜 License  
Framework này được phát hành dưới MIT License. Bạn có thể sử dụng tự do nhưng hãy để lại credit cho tác giả.
