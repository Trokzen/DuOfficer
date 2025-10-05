// MinimalTestTableView.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import Qt.labs.qmlmodels 1.0

Window {
    width: 800
    height: 400
    visible: true
    title: "Тест: ручные заголовки (финальная версия)"

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // --- ЗАГОЛОВКИ: фиксированная высота, НЕ в Item ---
        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            Layout.preferredHeight: 40  // ← Используем Layout.preferredHeight

            Repeater {
                model: ["Имя", "Возраст", "Город"]
                Rectangle {
                    Layout.preferredWidth: 150
                    color: "#e0e0e0"
                    border.color: "#aaa"

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        font.bold: true
                    }
                }
            }
        }

        // --- ТАБЛИЦА: в Item, чтобы Layout.fillHeight работал корректно ---
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true  // ← Занимает всё оставшееся пространство

            TableView {
                anchors.fill: parent  // ← Заполняет контейнер Item
                model: tableModel

                columnWidthProvider: function(column) {
                    return 150;
                }

                delegate: Rectangle {
                    implicitWidth: 150
                    implicitHeight: 40
                    color: row % 2 ? "#f8f8f8" : "white"
                    border.color: "#eee"

                    Text {
                        anchors.centerIn: parent
                        text: model.display
                    }
                }
            }
        }
    }

    TableModel {
        id: tableModel
        TableModelColumn { display: "Имя" }
        TableModelColumn { display: "Возраст" }
        TableModelColumn { display: "Город" }
    }

    Component.onCompleted: {
        tableModel.rows = [
            { "Имя": "Анна", "Возраст": 28, "Город": "Москва" },
            { "Имя": "Борис", "Возраст": 34, "Город": "СПб" },
            { "Имя": "Вера", "Возраст": 22, "Город": "Новосибирск" }
        ];
    }
}