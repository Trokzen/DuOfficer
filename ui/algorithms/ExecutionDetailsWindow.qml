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

    // Доступная ширина для таблицы (с учётом отступов)
    property real availableTableWidth: width - 20 // 10px слева + 10px справа

    // Заголовки (9 столбцов)
    property var columnHeaders: [
        "Статус",              // ← обновлено
        "№",
        "Описание",
        "Начало",
        "Окончание",
        "Телефоны",
        "Отчётные материалы",
        "Кому доложено",
        "Выполнение"           // ← обновлено
    ]

    // Проценты ширины (в сумме 100%)
    property var columnWidthPercents: [5, 3, 40, 6, 6, 8, 9, 8, 15]

    // --- Сигналы ---
    signal executionUpdated(int executionId)

    // --- Вспомогательные функции ---
    function openFile(filePath) {
        print("try to open file:", filePath);
        if (filePath.startsWith("file://")) {
            if (Qt.openUrlExternally(filePath)) {
                console.log("Файл открыт (URL):", filePath);
                return;
            }
            console.warn("Не удалось открыть URL:", filePath);
            return;
        }

        var normalizedPath = filePath.replace(/\\/g, "/");
        var url = "file:///" + normalizedPath;

        if (Qt.openUrlExternally(url)) {
            console.log("Файл открыт:", filePath);
        } else {
            console.warn("Не удалось открыть файл через URL:", url);
        }
    }

    function executeAction(actionNumber) {
        var actionsList = appData.getActionExecutionsByExecutionId(executionId);
        if (!Array.isArray(actionsList) || actionNumber < 1 || actionNumber > actionsList.length) {
            showInfoMessage("Неверный номер действия");
            return;
        }

        var action = actionsList[actionNumber - 1];
        if (!action || !action.id) {
            showInfoMessage("Действие не содержит ID");
            return;
        }

        if (typeof appData.executeActionExecution !== 'function') {
            showInfoMessage("Метод выполнения не доступен");
            return;
        }

        try {
            appData.executeActionExecution(action.id);
            showInfoMessage("Действие отмечено как выполненное");
            loadExecutionData();
            executionUpdated(executionId);
        } catch (e) {
            console.error("Ошибка выполнения действия:", e);
            showInfoMessage("Не удалось выполнить действие");
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

    function formatDateTime(dateTimeStr) {
        if (!dateTimeStr) return "";
        var dt = new Date(dateTimeStr);
        if (isNaN(dt.getTime())) return dateTimeStr;
        var timeStr = Qt.formatDateTime(dt, "HH:mm");
        var dateStr = Qt.formatDateTime(dt, "dd.MM.yyyy");
        return timeStr + "\n" + dateStr;
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
        title = "Детали выполнения: " + (executionData.snapshot_name || "Без названия");

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
            var status = String(a.status || "unknown");
            var desc = String(a.snapshot_description || "");
            var phones = String(a.snapshot_contact_phones || "");
            var materials = String(a.snapshot_report_materials || "");
            var start = String(a.calculated_start_time || "");
            var end = String(a.calculated_end_time || "");
            var reported = String(a.reported_to || "");
            // Примечания больше не используются напрямую

            // === Формируем HTML для столбца "Выполнение" ===
            var executionHtml = "";
            if (status === "completed" && end) {
                executionHtml = "✅ Выполнено<br/>" + formatDateTime(end);
            } else {
                executionHtml = '<a href="execute:' + (i + 1) + '">Выполнить</a>';
            }

            // === Формируем HTML для отчётных материалов ===
            var htmlMaterials = "";
            if (materials) {
                materials.split('\n').forEach(rawPath => {
                    var trimmedPath = rawPath.trim();
                    if (!trimmedPath) return;
                    var cleanPath = trimmedPath;
                    if (cleanPath.startsWith("file:///")) {
                        cleanPath = cleanPath.substring(8);
                    }
                    var fileName = cleanPath.split(/[\\/]/).pop();
                    htmlMaterials += `<a href="${cleanPath}">${escapeHtml(fileName)}</a><br/>`;
                });
            }

            jsRows.push({
                "Статус": status,
                "№": i + 1,
                "Описание": desc,
                "Начало": formatDateTime(start),
                "Окончание": formatDateTime(end),
                "Телефоны": phones,
                "Отчётные материалы": htmlMaterials,
                "Кому доложено": reported,
                "Выполнение": executionHtml  // ← обновлено
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
            Button { text: "🖨 Печать"; onClicked: showInfoMessage("В разработке"); }
            Button { text: "Закрыть"; onClicked: close() }
        }

        // --- ТАБЛИЦА С ЗАГОЛОВКАМИ ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // --- РУЧНЫЕ ЗАГОЛОВКИ ---
            Row {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                width: availableTableWidth
                x: 10

                Repeater {
                    model: columnHeaders
                    Rectangle {
                        width: Math.max(20, availableTableWidth * columnWidthPercents[index] / 100)
                        height: 40
                        color: "#e0e0e0"
                        border.color: "#ccc"
                        border.width: 1
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
                        return Math.max(20, availableTableWidth * columnWidthPercents[col] / 100);
                    }

                    delegate: Rectangle {
                        implicitWidth: actionsTableView.columnWidthProvider(column)
                        implicitHeight: 100
                        color: row % 2 ? "#f9f9f9" : "#ffffff"
                        border.color: "#eee"

                        // Столбец 0: Статус + Иконка действия
                        Item {
                            visible: column === 0
                            anchors.fill: parent
                            anchors.margins: 5

                            Text {
                                anchors.centerIn: parent
                                text: {
                                    var s = model.display;
                                    return s === "completed" ? "✅" :
                                        s === "skipped" ? "❌" :
                                        s === "pending" ? "⏸" :
                                        s === "in_progress" ? "🔄" : "?";
                                }
                                font.pixelSize: 16
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
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

                        // Столбец 2: Описание — с ToolTip
                        Item {
                            visible: column === 2
                            anchors.fill: parent
                            anchors.margins: 5

                            Text {
                                id: descText
                                anchors.fill: parent
                                text: model.display || ""
                                wrapMode: Text.WordWrap
                                horizontalAlignment: Text.AlignLeft
                                verticalAlignment: Text.AlignTop
                                elide: Text.ElideRight
                            }

                            ToolTip {
                                id: descTip
                                text: model.display || ""
                                visible: descText.truncated && hovered
                                delay: 500
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: descTip.open()
                                onExited: descTip.close()
                            }
                        }

                        // Столбцы 3–5, 7: текст с ToolTip
                        Item {
                            visible: [3,4,5,7].indexOf(column) >= 0
                            anchors.fill: parent
                            anchors.margins: 5

                            Text {
                                id: textEl
                                anchors.fill: parent
                                text: model.display || (column === 3 || column === 4 ? "Не задано" : "")
                                wrapMode: Text.Wrap
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                            }

                            ToolTip {
                                id: textTip
                                text: model.display || ""
                                visible: textEl.truncated && hovered
                                delay: 500
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: textTip.open()
                                onExited: textTip.close()
                            }
                        }

                        // Столбец 6: Отчётные материалы (HTML)
                        ScrollView {
                            visible: column === 6
                            anchors.fill: parent
                            anchors.margins: 2
                            clip: true
                            TextEdit {
                                id: reportText
                                textFormat: TextEdit.RichText
                                text: model.display || ""
                                readOnly: true
                                wrapMode: TextEdit.Wrap
                                onLinkActivated: executionDetailsWindow.openFile(link)

                                ToolTip {
                                    id: reportTip
                                    text: model.display.replace(/<[^>]*>/g, '') || ""
                                    visible: reportText.hovered && reportText.text.length > 50
                                    delay: 500
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                    onEntered: reportTip.open()
                                    onExited: reportTip.close()
                                }
                            }
                        }

                        // Столбец 8: Выполнение — интерактивный
                        Item {
                            visible: column === 8
                            anchors.fill: parent
                            anchors.margins: 5

                            Button {
                                id: actionButton
                                anchors.centerIn: parent
                                text: model["Статус"] === "completed" ? "✏️ Изменить" : "▶️ Выполнить"
                                //icon.visible: false

                                font.pixelSize: 12
                                padding: 4
                                horizontalPadding: 8

                                onClicked: {
                                    if (model["Статус"] === "completed") {
                                        var comp = Qt.createComponent("ActionExecutionEditorDialog.qml");
                                        if (comp.status === Component.Ready) {
                                            var dlg = comp.createObject(executionDetailsWindow, {
                                                executionId: executionId,
                                                currentActionExecutionId: model["№"], // ← из model
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
                                    } else {
                                        executeAction(model["№"]); // ← из model
                                    }
                                }
                            }

                            ToolTip {
                                text: model["Статус"] === "completed" ? "Редактировать результаты" : "Отметить как выполненное"
                                visible: actionButton.hovered
                                delay: 500
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
            id: infoText
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
        TableModelColumn { display: "Отчётные материалы" }
        TableModelColumn { display: "Кому доложено" }
        TableModelColumn { display: "Выполнение" }
    }
}