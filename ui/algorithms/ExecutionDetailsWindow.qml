// ui/algorithms/ExecutionDetailsWindow.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import QtQuick.Dialogs 6.5
import Qt.labs.qmlmodels 1.0

Window {
    id: executionDetailsWindow
    width: 1400
    height: 900
    minimumWidth: 1200
    minimumHeight: 700
    title: "Детали выполнения алгоритма"

    // --- Свойства ---
    property int executionId: -1
    property var executionData: null
    property var columnHeaders: [
        "Статус", "№", "Описание", "Начало", "Окончание",
        "Телефоны", "Отчёт", "Факт", "Статус (текст)",
        "Доложено", "Примечания", "Действие"
    ]

    // --- Сигналы ---
    signal executionUpdated(int executionId)

    // --- Вспомогательные функции ---
    function openFile(filePath) {
        if (Qt.openUrlExternally("file:///" + filePath)) {
            console.log("Файл открыт:", filePath);
        } else {
            console.warn("Не удалось открыть файл:", filePath);
        }
    }

    function mapStatusToText(status) {
        if (status === "completed") return "Выполнено";
        else if (status === "pending") return "Ожидает";
        else if (status === "in_progress") return "В процессе";
        else if (status === "skipped") return "Пропущено";
        else return status;
    }

    function escapeHtml(unsafe) {
        if (typeof unsafe !== 'string') return '';
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "<")
            .replace(/>/g, ">")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }

    // --- Загрузка данных ---
    function loadExecutionData() {
        if (executionId <= 0) return;

        var execData = appData.getExecutionById(executionId);
        if (execData && execData.toVariant) execData = execData.toVariant();
        if (!execData || typeof execData !== 'object') {
            executionData = null;
            title = "Детали выполнения (ошибка)";
            return;
        }
        executionData = execData;
        title = "Детали выполнения: " + (execData.snapshot_name || "Без названия");

        var actionsList = appData.getActionExecutionsByExecutionId(executionId);
        if (!Array.isArray(actionsList) && !(actionsList && actionsList.length !== undefined)) {
            actionsList = [];
        } else if (!Array.isArray(actionsList)) {
            var tmp = [];
            for (var i = 0; i < actionsList.length; i++) tmp.push(actionsList[i]);
            actionsList = tmp;
        }

        var jsRows = [];
        for (var i = 0; i < actionsList.length; i++) {
            var a = actionsList[i];
            var id = a.id || -1;
            var status = String(a.status || "unknown");
            var desc = String(a.snapshot_description || "");
            var phones = String(a.snapshot_contact_phones || "");
            var materials = String(a.snapshot_report_materials || "");
            var start = String(a.calculated_start_time || "");
            var end = String(a.calculated_end_time || "");
            var actual = String(a.actual_end_time || "");
            var reported = String(a.reported_to || "");
            var notes = String(a.notes || "");

            function fmt(dtStr) {
                if (!dtStr) return "";
                var d = new Date(dtStr);
                return isNaN(d) ? dtStr : d.toLocaleTimeString(Qt.locale(), "HH:mm") + "\n" + d.toLocaleDateString(Qt.locale(), "dd.MM");
            }

            var htmlMaterials = "";
            if (materials) {
                materials.split('\n').forEach(path => {
                    if (path = path.trim()) {
                        if (path.startsWith("file:///")) path = path.substring(8);
                        htmlMaterials += `<a href="${path}">${escapeHtml(path)}</a><br/>`;
                    }
                });
            }

            jsRows.push({
                "Статус": status,
                "№": id,
                "Описание": desc,
                "Начало": fmt(start),
                "Окончание": fmt(end),
                "Телефоны": phones,
                "Отчёт": htmlMaterials,
                "Факт": fmt(actual),
                "Статус (текст)": mapStatusToText(status),
                "Доложено": reported,
                "Примечания": notes,
                "Действие": ""
            });
        }

        actionsTableModel.rows = jsRows;
    }

    // --- Основной контент ---
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5

        // --- Заголовок окна ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#2c3e50"
            border.color: "#34495e"
            Text {
                anchors.centerIn: parent
                text: executionData ? (executionData.snapshot_name || "Без названия") + "\n" + (executionData.started_at || "Не задано") : "Загрузка..."
                color: "white"
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }

        // --- Кнопки ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 10
            Button { text: "График"; onClicked: showInfoMessage("В разработке"); }
            Item { Layout.fillWidth: true }
            Button { text: "Добавить действие"; onClicked: { /* ... */ } }
            Button { text: "Авто"; onClicked: { /* ... */ } }
            Button { text: "Печать"; onClicked: showInfoMessage("В разработке"); }
            Button { text: "Закрыть"; onClicked: close() }
        }

        // --- ТАБЛИЦА С ЗАГОЛОВКАМИ ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // --- РУЧНЫЕ ЗАГОЛОВКИ ---
            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                Repeater {
                    model: columnHeaders
                    Rectangle {
                        Layout.fillWidth: true
                        color: "#e0e0e0"
                        border.color: "#ccc"
                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            // --- ТАБЛИЦА ---
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                TableView {
                    id: actionsTableView
                    anchors.fill: parent
                    model: actionsTableModel

                    rowHeightProvider: function(row) { return 100; }

                    columnWidthProvider: function(col) {
                        return width / columnHeaders.length;
                    }

                    delegate: Rectangle {
                        implicitWidth: actionsTableView.columnWidthProvider(column)
                        implicitHeight: 100
                        color: row % 2 ? "#f9f9f9" : "#ffffff"
                        border.color: "#eee"

                        // Столбец 0: Статус (иконка)
                        Text {
                            visible: column === 0
                            anchors.fill: parent
                            anchors.margins: 5
                            text: {
                                var s = model.display;
                                return s === "completed" ? "✅" :
                                       s === "skipped" ? "❌" :
                                       s === "pending" ? "⏸" :
                                       s === "in_progress" ? "🔄" : "?";
                            }
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Столбец 1: №
                        Text {
                            visible: column === 1
                            anchors.fill: parent
                            anchors.margins: 5
                            text: model.display || "N/A"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Столбец 2: Описание
                        Text {
                            visible: column === 2
                            anchors.fill: parent
                            anchors.margins: 5
                            text: model.display || ""
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignLeft
                            verticalAlignment: Text.AlignTop
                        }

                        // Столбцы 3–5, 7–10: текст
                        Text {
                            visible: [3,4,5,7,8,9,10].indexOf(column) >= 0
                            anchors.fill: parent
                            anchors.margins: 5
                            text: model.display || (column === 3 || column === 4 ? "Не задано" : "")
                            wrapMode: Text.Wrap
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Столбец 6: Отчёт (HTML)
                        ScrollView {
                            visible: column === 6
                            anchors.fill: parent
                            anchors.margins: 2
                            clip: true
                            TextEdit {
                                textFormat: TextEdit.RichText
                                text: model.display || ""
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                onLinkActivated: executionDetailsWindow.openFile(link)
                            }
                        }

                        // Столбец 11: Кнопка
                        Button {
                            visible: column === 11
                            anchors.centerIn: parent
                            text: {
                                var status = actionsTableModel.rows[row]["Статус"];
                                return status === "completed" ? "Изменить" : "Выполнить";
                            }
                            onClicked: {
                                var id = actionsTableModel.rows[row]["№"];
                                var comp = Qt.createComponent("ActionExecutionEditorDialog.qml");
                                if (comp.status === Component.Ready) {
                                    var dlg = comp.createObject(executionDetailsWindow, {
                                        executionId: executionId,
                                        currentActionExecutionId: id,
                                        isEditMode: true
                                    });
                                    if (dlg) {
                                        dlg.onActionExecutionSaved.connect(() => {
                                            loadExecutionData();
                                            executionUpdated(executionId);
                                        });
                                        dlg.open();
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // --- Подвал ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#ecf0f1"
            border.color: "#bdc3c7"
            Text {
                anchors.centerIn: parent
                text: (appData.postName || "Пост") + ": " + (executionData ? executionData.created_by_user_display_name : "—")
                elide: Text.ElideRight
            }
        }
    }

    // --- Вспомогательные компоненты ---
    Popup {
        id: infoPopup
        x: (width - parent.width) / 2
        y: 50
        width: 300
        height: 100
        modal: false
        closePolicy: Popup.NoAutoClose
        parent: contentItem
        background: Rectangle { color: "lightyellow"; border.color: "orange"; radius: 5 }
        Text {
            anchors.centerIn: parent
            anchors.margins: 10
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }
        Timer {
            id: infoTimer
            interval: 3000
            onTriggered: infoPopup.close()
        }
        function show(msg) {
            infoText.text = msg;
            open();
            infoTimer.start();
        }
    }
    function showInfoMessage(msg) { infoPopup.show(msg); }

    // --- Обработчики ---
    onExecutionIdChanged: { if (executionId > 0) loadExecutionData(); }
    Component.onCompleted: { if (executionId > 0) loadExecutionData(); }

    // --- Модель ---
    TableModel {
        id: actionsTableModel
        TableModelColumn { display: "Статус" }
        TableModelColumn { display: "№" }
        TableModelColumn { display: "Описание" }
        TableModelColumn { display: "Начало" }
        TableModelColumn { display: "Окончание" }
        TableModelColumn { display: "Телефоны" }
        TableModelColumn { display: "Отчёт" }
        TableModelColumn { display: "Факт" }
        TableModelColumn { display: "Статус (текст)" }
        TableModelColumn { display: "Доложено" }
        TableModelColumn { display: "Примечания" }
        TableModelColumn { display: "Действие" }
    }
}