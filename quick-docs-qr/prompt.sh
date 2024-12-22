#!/bin/bash

# Массив игнорируемых паттернов
declare -a IGNORE_PATTERNS=(
    # Системные файлы и папки
    ".git"
    ".gitignore"
    "__pycache__"
    "*.pyc"
    ".DS_Store"

    "trees"
    "prompt.py"
    ".prompt"
    "widget-top-bar"
    "deploy-header"
    "dev-tools"
    "widget-deploy-packages"

    # IDE и редакторы
    ".idea"
    ".vscode"
    "*.swp"

    # Виртуальные окружения
    "venv"
    "env"
    ".env"

    # Зависимости
    "node_modules"

    # Временные файлы
    "*.log"
    "*.tmp"

    # Документация
    "docs/*"
    "*.md"
)

# Счетчики для статистики
processed=0
skipped=0

# Функция для проверки, нужно ли игнорировать файл
should_ignore() {
    local file_path="$1"

    # Проверяем каждый паттерн
    for pattern in "${IGNORE_PATTERNS[@]}"; do
        # Для точных совпадений
        if [[ "$(basename "$file_path")" == "$pattern" ]]; then
            return 0
        fi

        # Для паттернов с wildcards
        if [[ "$file_path" == $pattern ]]; then
            return 0
        fi

        # Для паттернов типа docs/*
        if [[ $pattern == *"/*" && "$file_path" == "${pattern%/*}"* ]]; then
            return 0
        fi
    done

    return 1
}

# Создаем директорию .prompt
mkdir -p .prompt
echo "Директория '.prompt' готова"

# Генерируем имя выходного файла с текущей датой и временем
timestamp=$(date '+%Y%m%d_%H%M%S')
output_file=".prompt/prompt_${timestamp}.log"

echo -e "\nНачинаем обработку файлов..."

# Обрабатываем все файлы рекурсивно
while IFS= read -r -d '' file; do
    # Пропускаем сам выходной файл
    if [[ "$file" == "$output_file" ]]; then
        continue
    fi

    # Проверяем, нужно ли игнорировать файл
    if should_ignore "$file"; then
        echo "Пропускаем: $file"
        ((skipped++))
        continue
    fi

    # Обрабатываем файл
    echo "Обрабатываем: $file"
    {
        echo -e "\n=================================================="
        echo "Файл: $file"
        echo "=================================================="
        cat "$file" 2>/dev/null || {
            echo "Ошибка при чтении файла"
            ((skipped++))
            continue
        }
        echo
    } >> "$output_file"

    ((processed++))
done < <(find . -type f -print0)

# Выводим статистику
echo -e "\nГотово!"
echo "Обработано файлов: $processed"
echo "Пропущено файлов: $skipped"
echo "Результат сохранён в: $output_file"