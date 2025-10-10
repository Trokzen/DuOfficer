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
    property var cachedActionsList: []

    property real availableTableWidth: width - 20

    // ЗАМЕНА: "№" → "Номер" (во избежание проблем с привязкой)
    property var columnHeaders: [
        "Статус",
        "Номер",           // ← изменено
        "Описание",
        "Начало",
        "Окончание",
        "Телефоны",
        "Отчётные материалы",
        "Кому доложено",
        "Выполнение"
    ]

    property var columnWidthPercents: [5, 5, 38, 6, 6, 8, 9, 8, 15] // немного увеличил "Номер"

    signal executionUpdated(int executionId)

    function isFontBold(style) {
        return style === "bold" || style === "bold_italic";
    }
    function isFontItalic(style) {
        return style === "italic" || style === "bold_italic";
    }

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
        console.log("=== loadExecutionData вызвана для executionId:", executionId, "===");

        if (executionId <= 0) return;

        var execData = appData.getExecutionById(executionId);
        if (execData && execData.toVariant) execData = execData.toVariant();
        if (!execData || typeof execData !== 'object') {
            executionData = null;
            title = "Детали выполнения (ошибка)";
            console.error("Не удалось загрузить executionData");
            return;
        }
        executionData = execData;
        title = "Детали выполнения: " + (executionData.snapshot_name || "Без названия");

        // --- ГАРАНТИРОВАННОЕ ПРЕОБРАЗОВАНИЕ В JS-МАССИВ ---
        var rawActions = appData.getActionExecutionsByExecutionId(executionId);
        var actionsList = [];
        if (rawActions && typeof rawActions === 'object' && rawActions.length !== undefined) {
            for (var i = 0; i < rawActions.length; i++) {
                actionsList.push(rawActions[i]);
            }
        }
        console.log("Загружено action executions:", actionsList.length);
        executionDetailsWindow.cachedActionsList = actionsList;

        var jsRows = [];
        for (var i = 0; i < actionsList.length; i++) {
            var a = actionsList[i];
            var status = String(a.status || "unknown");
            var desc = String(a.snapshot_description || "");
            var phones = String(a.snapshot_contact_phones || "");
            var materials = a.snapshot_report_materials;
            if (typeof materials !== 'string') materials = "";
            var start = String(a.calculated_start_time || "");
            var actualEnd = String(a.actual_end_time || "");
            var reported = String(a.reported_to || "");
            var notes = String(a.notes || "");

            var htmlMaterials = "";
            if (materials) {
                materials.split('\n').forEach(rawPath => {
                    var trimmedPath = String(rawPath).trim();
                    if (!trimmedPath) return;
                    var cleanPath = trimmedPath;
                    if (cleanPath.startsWith("file:///")) {
                        cleanPath = cleanPath.substring(8);
                    }
                    var fileName = cleanPath.split(/[\\/]/).pop() || cleanPath;
                    htmlMaterials += `<a href="${cleanPath}">${escapeHtml(fileName)}</a><br/>`;
                });
            }

            jsRows.push({
                "Статус": status,
                "Номер": i + 1,               // ← изменено
                "Описание": desc,
                "Начало": formatDateTime(start),
                "Окончание": formatDateTime(String(a.calculated_end_time || "")),
                "Телефоны": phones,
                "Отчётные материалы": htmlMaterials,
                "Кому доложено": reported,
                "Примечания": notes
            });
        }

        console.log("Подготовлено строк для таблицы:", jsRows.length);
        if (jsRows.length > 0) {
            console.log("Пример строки:", JSON.stringify(jsRows[0]));
        }

        if (actionsTableModel) {
            actionsTableModel.clear();
            for (var i = 0; i < jsRows.length; i++) {
                actionsTableModel.appendRow(jsRows[i]);
            }
        } else {
            console.error("actionsTableModel не доступен!");
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 5

        // --- Заголовок ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 60
            color: "#2c3e50"
            border.color: "#34495e"
            Text {
                anchors.centerIn: parent
                text: {
                    if (!executionData) return "Загрузка...";
                    var name = executionData.snapshot_name || "Без названия";
                    var startedAt = executionData.started_at;
                    var formattedDate = "Не задано";
                    if (startedAt) {
                        var dt = new Date(startedAt);
                        if (!isNaN(dt.getTime())) {
                            var timeStr = Qt.formatDateTime(dt, "HH:mm:ss");
                            var dateStr = Qt.formatDateTime(dt, "dd.MM.yyyy");
                            formattedDate = timeStr + " " + dateStr;
                        }
                    }
                    return name + "\n" + formattedDate;
                }
                color: "white"
                font.family: appData.fontFamily
                font.pixelSize: appData.fontSize + 2
                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
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

            Button {
                text: "График"
                font.family: appData.fontFamily
                font.pixelSize: appData.fontSize
                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                onClicked: {
                    if (executionId <= 0) {
                        showInfoMessage("Неверный ID выполнения");
                        return;
                    }
                    var stats = appData.getActionExecutionStatsForPieChart(executionId);
                    var component = Qt.createComponent("ExecutionStatsChartDialog.qml");
                    if (component.status === Component.Ready) {
                        var dialog = component.createObject(executionDetailsWindow, { "stats": stats });
                        if (dialog) dialog.open();
                        else showInfoMessage("Ошибка создания окна графика");
                    } else {
                        showInfoMessage("Ошибка загрузки ExecutionStatsChartDialog.qml: " + component.errorString());
                    }
                }
            }

            Item { Layout.fillWidth: true }

            Button {
                text: "Добавить действие"
                font.family: appData.fontFamily
                font.pixelSize: appData.fontSize
                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                onClicked: {
                    var component = Qt.createComponent("ActionExecutionEditorDialog.qml");
                    if (component.status === Component.Ready) {
                        var dialog = component.createObject(executionDetailsWindow, {
                            "executionId": executionId,
                            "isEditMode": false
                        });
                        if (dialog) {
                            dialog.onActionExecutionSaved.connect(function() {
                                executionDetailsWindow.loadExecutionData();
                                executionUpdated(executionId);
                            });
                            dialog.open();
                        } else {
                            showInfoMessage("Ошибка: Не удалось открыть диалог добавления действия.");
                        }
                    } else {
                        showInfoMessage("Ошибка загрузки диалога добавления действия: " + component.errorString());
                    }
                }
            }

            Button {
                text: "Авто"
                font.family: appData.fontFamily
                font.pixelSize: appData.fontSize
                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                onClicked: {
                    if (executionId <= 0) {
                        showInfoMessage("Неверный ID выполнения");
                        return;
                    }
                    var success = appData.completeAllPendingActionsAutomatically(executionId);
                    if (success) {
                        showInfoMessage("Все действия автоматически завершены");
                        loadExecutionData();
                        executionUpdated(executionId);
                    } else {
                        showInfoMessage("Не удалось завершить действия");
                    }
                }
            }

            Button {
                text: "🖨 Печать"
                font.family: appData.fontFamily
                font.pixelSize: appData.fontSize
                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                onClicked: showInfoMessage("В разработке");
            }
            Button {
                text: "Закрыть"
                font.family: appData.fontFamily
                font.pixelSize: appData.fontSize
                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                onClicked: close()
            }
        }

        // --- ТАБЛИЦА ---
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

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
                            font.family: appData.fontFamily
                            font.pixelSize: appData.fontSize
                            font.bold: true
                            font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                            elide: Text.ElideRight
                        }
                    }
                }
            }

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
                        implicitHeight: 110
                        color: row % 2 ? "#f9f9f9" : "#ffffff"
                        border.color: "#eee"

                        // Статус
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
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize + 2
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Номер
                        Text {
                            visible: column === 1
                            anchors.fill: parent
                            anchors.margins: 5
                            text: model.display || "N/A"
                            font.family: appData.fontFamily
                            font.pixelSize: appData.fontSize
                            font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                            font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Описание
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
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                                elide: Text.ElideRight
                            }
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    fullDescriptionDialog.descriptionText = model.display || "";
                                    fullDescriptionDialog.open();
                                }
                                onEntered: descTip.open()
                                onExited: descTip.close()
                            }
                            ToolTip {
                                id: descTip
                                text: model.display || ""
                                visible: descText.truncated && hovered
                                delay: 500
                            }
                        }

                        // Начало, Окончание, Телефоны, Кому доложено
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
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
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

                        // Отчётные материалы — ИСПРАВЛЕНО: убрано reportText.hovered
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
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                                onLinkActivated: executionDetailsWindow.openFile(link)

                                ToolTip {
                                    id: reportTip
                                    text: {
                                        var raw = model.display;
                                        if (typeof raw !== 'string') return "";
                                        return raw.replace(/<[^>]*>/g, '');
                                    }
                                    // visible: reportText.hovered && ... ← УДАЛЕНО (ошибка!)
                                    delay: 500
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.NoButton
                                    onEntered: {
                                        if (reportText.text.length > 50) reportTip.open();
                                    }
                                    onExited: reportTip.close()
                                }
                            }
                        }

                        // Выполнение
                        Column {
                            visible: column === 8
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 5

                            Button {
                                id: actionButton
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    if (row < 0 || row >= executionDetailsWindow.cachedActionsList.length) return "▶️ Выполнить";
                                    var isCompleted = executionDetailsWindow.cachedActionsList[row].status === "completed";
                                    return isCompleted ? "✏️ Изменить" : "▶️ Выполнить";
                                }
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                                padding: 4
                                horizontalPadding: 8

                                onClicked: {
                                    if (row < 0 || row >= executionDetailsWindow.cachedActionsList.length) {
                                        showInfoMessage("Не удалось получить ID действия.");
                                        return;
                                    }
                                    var actionExecId = executionDetailsWindow.cachedActionsList[row].id;
                                    if (!actionExecId || actionExecId <= 0) {
                                        showInfoMessage("Некорректный ID действия.");
                                        return;
                                    }

                                    var component = Qt.createComponent("ActionExecutionCompletionDialog.qml");
                                    if (component.status === Component.Ready) {
                                        var dialog = component.createObject(executionDetailsWindow, {
                                            "executionId": executionId,
                                            "currentActionExecutionId": actionExecId,
                                            "isEditMode": true
                                        });
                                        if (dialog) {
                                            dialog.actionExecutionSaved.connect(function() {
                                                executionDetailsWindow.loadExecutionData();
                                                executionUpdated(executionId);
                                            });
                                            dialog.open();
                                        } else {
                                            showInfoMessage("Ошибка: Не удалось открыть диалог ввода данных.");
                                        }
                                    } else {
                                        showInfoMessage("Ошибка загрузки диалога: " + component.errorString());
                                    }
                                }

                                ToolTip {
                                    text: {
                                        if (row < 0 || row >= executionDetailsWindow.cachedActionsList.length) return "";
                                        return executionDetailsWindow.cachedActionsList[row].status === "completed"
                                            ? "Редактировать результаты выполнения"
                                            : "Ввести данные о выполнении";
                                    }
                                    visible: actionButton.hovered
                                    delay: 500
                                }
                            }

                            // --- Фактическое время выполнения — ИСПРАВЛЕНО: безопасная проверка ---
                            Text {
                                visible: {
                                    if (row < 0 || row >= executionDetailsWindow.cachedActionsList.length) return false;
                                    var action = executionDetailsWindow.cachedActionsList[row];
                                    var actualEnd = action.actual_end_time;
                                    var hasActualEnd = actualEnd !== null && actualEnd !== undefined && actualEnd !== "";
                                    return action.status === "completed" && hasActualEnd;
                                }
                                text: {
                                    if (row < 0 || row >= executionDetailsWindow.cachedActionsList.length) return "";
                                    var action = executionDetailsWindow.cachedActionsList[row];
                                    return action.status === "completed" && action.actual_end_time
                                        ? formatDateTime(action.actual_end_time)
                                        : "";
                                }
                                color: "black"
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize - 1
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                                elide: Text.ElideRight
                                width: parent.width
                            }

                            Item {
                                width: parent.width
                                height: 24
                                Button {
                                    anchors.centerIn: parent
                                    width: 24
                                    height: 24
                                    padding: 0
                                    font.family: appData.fontFamily
                                    font.pixelSize: appData.fontSize
                                    font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                    font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                                    text: "📄"
                                    onClicked: {
                                        if (row < 0 || row >= executionDetailsWindow.cachedActionsList.length) {
                                            showInfoMessage("Не удалось получить ID действия.");
                                            return;
                                        }
                                        var actionExecId = executionDetailsWindow.cachedActionsList[row].id;
                                        if (!actionExecId || actionExecId <= 0) {
                                            showInfoMessage("Некорректный ID действия.");
                                            return;
                                        }
                                        var notes = executionDetailsWindow.cachedActionsList[row].notes || "";

                                        var component = Qt.createComponent("ActionExecutionNotesDialog.qml");
                                        if (component.status === Component.Ready) {
                                            var dialog = component.createObject(executionDetailsWindow, {
                                                "actionExecutionId": actionExecId,
                                                "initialNotes": notes
                                            });
                                            if (dialog) {
                                                dialog.notesSaved.connect(function() {
                                                    executionDetailsWindow.loadExecutionData();
                                                    executionUpdated(executionId);
                                                });
                                                dialog.open();
                                            } else {
                                                showInfoMessage("Ошибка создания диалога примечаний.");
                                            }
                                        } else {
                                            showInfoMessage("Ошибка загрузки ActionExecutionNotesDialog.qml: " + component.errorString());
                                        }
                                    }
                                    ToolTip.text: "Примечания"
                                    ToolTip.visible: hovered
                                    ToolTip.delay: 500
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
                font.family: appData.fontFamily
                font.pixelSize: appData.fontSize
                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
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
            font.family: appData.fontFamily
            font.pixelSize: appData.fontSize
            font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
            font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
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

    Dialog {
        id: fullDescriptionDialog
        title: "Полное описание"
        standardButtons: Dialog.Close
        modal: true
        width: 600
        height: 400
        TextArea {
            id: fullDescTextArea
            text: fullDescriptionDialog.descriptionText
            readOnly: true
            wrapMode: TextEdit.Wrap
            selectByMouse: true
            anchors.fill: parent
            anchors.margins: 10
            font.family: appData.fontFamily
            font.pixelSize: appData.fontSize
            font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
            font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
        }
        property string descriptionText: ""
    }

    function showInfoMessage(msg) { infoPopup.show(msg); }

    onExecutionIdChanged: { if (executionId > 0) loadExecutionData(); }
    Component.onCompleted: { if (executionId > 0) loadExecutionData(); }

    // --- Модель ---
    TableModel {
        id: actionsTableModel
        TableModelColumn { display: "Статус" }
        TableModelColumn { display: "Номер" }          // ← изменено
        TableModelColumn { display: "Описание" }
        TableModelColumn { display: "Начало" }
        TableModelColumn { display: "Окончание" }
        TableModelColumn { display: "Телефоны" }
        TableModelColumn { display: "Отчётные материалы" }
        TableModelColumn { display: "Кому доложено" }
        TableModelColumn { display: "Примечания" }
    }
}