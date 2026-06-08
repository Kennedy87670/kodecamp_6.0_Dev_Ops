#!/bin/bash

TODO_FILE="$HOME/todo.txt"

touch "$TODO_FILE"

while true
do
    echo "======================"
    echo "   TO-DO LIST MANAGER"
    echo "======================"
    echo "1. View all tasks"
    echo "2. Add a new task"
    echo "3. Delete a task"
    echo "4. Exit"
    echo "======================"

    read -p "Choose an option: " choice

    case $choice in
        1)
            echo "Your Tasks:"
            if [ ! -s "$TODO_FILE" ]; then
                echo "No tasks found."
            else
                nl "$TODO_FILE"
            fi
            ;;
        2)
            read -p "Enter new task: " task
            echo "$task" >> "$TODO_FILE"
            echo "Task added successfully."
            ;;
        3)
            if [ ! -s "$TODO_FILE" ]; then
                echo "No tasks found."
                continue
            fi

            echo "Your Tasks:"
            nl "$TODO_FILE"
            read -p "Enter task number to delete: " number

            if ! [[ $number =~ ^[0-9]+$ ]]; then
                echo "Invalid task number."
                continue
            fi

            total_tasks=$(wc -l < "$TODO_FILE")
            if [ "$number" -lt 1 ] || [ "$number" -gt "$total_tasks" ]; then
                echo "Task number does not exist."
                continue
            fi

            temp_file=$(mktemp)
            awk -v line_to_delete="$number" 'NR != line_to_delete' "$TODO_FILE" > "$temp_file"
            mv "$temp_file" "$TODO_FILE"
            echo "Task deleted successfully."
            ;;
        4)
            echo "Exiting To-Do List Manager. Goodbye!"
            break
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac

    echo ""
done
