#!/usr/bin/env bash
set -e

echo "=== 04. Обновляем nav_graph.xml, чтобы добавить qrGeneratorFragment ==="

NAVGRAPH_FILE="./app/src/main/res/navigation/nav_graph.xml"

if [ ! -f "$NAVGRAPH_FILE" ]; then
  echo "Файл nav_graph.xml не найден по пути $NAVGRAPH_FILE!"
  exit 1
fi

# Добавляем тег <fragment> для qrGeneratorFragment
# Внимание: простой 'sed' может быть хрупким, если в файле уже есть подобные строки.
# Ниже - упрощённый вариант. При необходимости отредактируйте вручную.

# Проверим, есть ли уже строка com.example.yandexdiskqr.presentation.qr.QRGeneratorFragment
if grep -q "QRGeneratorFragment" "$NAVGRAPH_FILE"; then
  echo "nav_graph.xml: Похоже, qrGeneratorFragment уже добавлен. Пропускаем."
  exit 0
fi

# Вставляем непосредственно перед закрывающим </navigation> блок с описанием qrGeneratorFragment
sed -i '' '/<\/navigation>/i \
    <fragment\
        android:id="@+id/qrGeneratorFragment"\
        android:name="com.example.yandexdiskqr.presentation.qr.QRGeneratorFragment"\
        android:label="@string/generate_qr" \/>\
' "$NAVGRAPH_FILE"

echo "Done. qrGeneratorFragment добавлен в nav_graph.xml"
