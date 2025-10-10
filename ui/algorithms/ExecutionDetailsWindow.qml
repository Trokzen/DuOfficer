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

    // --- Вспомогательные функции для стиля шрифта ---
    function isFontBold(style) {
        return style === "bold" || style === "bold_italic";
    }
    function isFontItalic(style) {
        return style === "italic" || style === "bold_italic";
    }

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

        // --- КЭШИРУЕМ СПИСОК action_executions ---
        var actionsList = appData.getActionExecutionsByExecutionId(executionId);
        executionDetailsWindow.cachedActionsList = actionsList;

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
            var materials = a.snapshot_report_materials;
            if (typeof materials !== 'string') materials = "";
            var start = String(a.calculated_start_time || "");
            var actualEnd = String(a.actual_end_time || ""); // ← ФАКТИЧЕСКОЕ ВРЕМЯ ОКОНЧАНИЯ
            var reported = String(a.reported_to || "");
            var notes = String(a.notes || ""); // ← ДОБАВЛЕНО: примечания

            // === Формируем HTML для отчётных материалов (с защитой) ===
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
                "№": i + 1,
                "Описание": desc,
                "Начало": formatDateTime(start),
                "Окончание": formatDateTime(String(a.calculated_end_time || "")), // плановое окончание
                "Телефоны": phones,
                "Отчётные материалы": htmlMaterials,
                "Кому доложено": reported,
                "Примечания": notes, // ← ДОБАВЛЕНО
                "isCompleted": (status === "completed"),
                "actualEndTimeDisplay": (status === "completed" && actualEnd) ? formatDateTime(actualEnd) : ""
            });
        }
        actionsTableModel.clear();
        for (var i = 0; i < jsRows.length; i++) {
            actionsTableModel.appendRow(jsRows[i]);
        }
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
                            formattedDate = timeStr + " " + dateStr; // ← hh:mm:ss dd.mm.yyyy
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
                    console.log("Статистика:", 
                        "своевр.:", stats.on_time,
                        "несвоевр.:", stats.late,
                        "не вып.:", stats.not_done,
                        "всего:", stats.total
                    );

                    var component = Qt.createComponent("ExecutionStatsChartDialog.qml");
                    if (component.status === Component.Ready) {
                        var dialog = component.createObject(executionDetailsWindow, {
                            "stats": stats
                        });
                        if (dialog) {
                            dialog.open();
                        } else {
                            showInfoMessage("Ошибка создания окна графика");
                        }
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
                    console.log("QML ExecutionDetailsWindow: Нажата кнопка 'Добавить действие' для execution ID:", executionId);

                    var component = Qt.createComponent("ActionExecutionEditorDialog.qml");
                    if (component.status === Component.Ready) {
                        var dialog = component.createObject(executionDetailsWindow, {
                            "executionId": executionId,
                            "isEditMode": false
                        });

                        if (dialog) {
                            dialog.onActionExecutionSaved.connect(function() {
                                console.log("QML ExecutionDetailsWindow: Получен сигнал о сохранении нового action_execution. Перезагружаем данные таблицы.");
                                executionDetailsWindow.loadExecutionData();
                                executionUpdated(executionId);
                            });
                            console.log("QML ExecutionDetailsWindow: Диалог добавления action_execution создан успешно. Открываем.");
                            dialog.open();
                        } else {
                            console.error("QML ExecutionDetailsWindow: Не удалось создать объект ActionExecutionEditorDialog (режим добавления).");
                            showInfoMessage("Ошибка: Не удалось открыть диалог добавления действия.");
                        }
                    } else {
                        console.error("QML ExecutionDetailsWindow: Ошибка загрузки компонента ActionExecutionEditorDialog.qml:", component.errorString());
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
                        loadExecutionData(); // Обновляем таблицу
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
                            font.family: appData.fontFamily
                            font.pixelSize: appData.fontSize
                            font.bold: true
                            font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
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
                        implicitHeight: 110
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
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize + 2
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
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
                            font.family: appData.fontFamily
                            font.pixelSize: appData.fontSize
                            font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                            font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        // Столбец 2: Описание — без скролла, только клик и тултип
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
                        Column {
                            visible: column === 8
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 5

                            // --- Основная кнопка "Выполнить/Изменить" ---
                            Button {
                                id: actionButton
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: {
                                    if (row >= actionsTableModel.rows.length) return "▶️ Выполнить";
                                    return actionsTableModel.rows[row].isCompleted ? "✏️ Изменить" : "▶️ Выполнить";
                                }
                                font.family: appData.fontFamily
                                font.pixelSize: appData.fontSize
                                font.bold: executionDetailsWindow.isFontBold(appData.fontStyle)
                                font.italic: executionDetailsWindow.isFontItalic(appData.fontStyle)
                                padding: 4
                                horizontalPadding: 8

                                onClicked: {
                                    if (!executionDetailsWindow.cachedActionsList || row < 0 || row >= executionDetailsWindow.cachedActionsList.length) {
                                        console.error("QML ExecutionDetailsWindow: Невозможно получить ID action_execution. Индекс за пределами диапазона или список не кэширован.");
                                        showInfoMessage("Не удалось получить ID действия для завершения.");
                                        return;
                                    }
                                    var actionExecId = executionDetailsWindow.cachedActionsList[row].id;
                                    if (!actionExecId || actionExecId <= 0) {
                                        console.error("QML ExecutionDetailsWindow: Невозможно открыть диалог завершения - некорректный ID action_execution из кэша:", actionExecId);
                                        showInfoMessage("Не удалось получить ID действия для завершения.");
                                        return;
                                    }

                                    console.log("QML ExecutionDetailsWindow: Нажата кнопка 'Выполнить'/'Изменить' для action_execution ID:", actionExecId);

                                    var component = Qt.createComponent("ActionExecutionCompletionDialog.qml");
                                    if (component.status === Component.Ready) {
                                        var dialog = component.createObject(executionDetailsWindow, {
                                            "executionId": executionId,
                                            "currentActionExecutionId": actionExecId,
                                            "isEditMode": true
                                        });

                                        if (dialog) {
                                            dialog.actionExecutionSaved.connect(function() {
                                                console.log("QML ExecutionDetailsWindow: Получен сигнал о сохранении данных action_execution. Перезагружаем данные таблицы.");
                                                executionDetailsWindow.loadExecutionData();
                                                executionUpdated(executionId);
                                            });
                                            console.log("QML ExecutionDetailsWindow: Диалог ActionExecutionCompletionDialog создан и открыт для ID:", actionExecId);
                                            dialog.open();
                                        } else {
                                            console.error("QML ExecutionDetailsWindow: Не удалось создать объект ActionExecutionCompletionDialog.");
                                            showInfoMessage("Ошибка: Не удалось открыть диалог ввода данных.");
                                        }
                                    } else {
                                        console.error("QML ExecutionDetailsWindow: Ошибка загрузки компонента ActionExecutionCompletionDialog.qml:", component.errorString());
                                        showInfoMessage("Ошибка загрузки диалога: " + component.errorString());
                                    }
                                }

                                ToolTip {
                                    text: actionsTableModel.rows[row].isCompleted
                                        ? "Редактировать результаты выполнения"
                                        : "Ввести данные о выполнении";
                                    visible: actionButton.hovered
                                    delay: 500
                                }
                            }

                            // --- Фактическое время выполнения (если есть) ---
                            Text {
                                visible: {
                                    if (row >= actionsTableModel.rows.length) return false;
                                    var rowObj = actionsTableModel.rows[row];
                                    return rowObj.isCompleted && rowObj.actualEndTimeDisplay && rowObj.actualEndTimeDisplay !== "";
                                }
                                text: actionsTableModel.rows[row].actualEndTimeDisplay
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

                            // --- Кнопка "Примечания" ---
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
                                    // Иконки: 📝, 📄 если нет
                                    text: {
                                        if (row >= actionsTableModel.rows.length) return "📄";
                                        var notes = actionsTableModel.rows[row]["Примечания"];
                                        return (notes && notes.trim() !== "") ? "📄" : "📄";
                                    }

                                    onClicked: {
                                        if (!executionDetailsWindow.cachedActionsList || row < 0 || row >= executionDetailsWindow.cachedActionsList.length) {
                                            showInfoMessage("Не удалось получить ID действия.");
                                            return;
                                        }
                                        var actionExecId = executionDetailsWindow.cachedActionsList[row].id;
                                        if (!actionExecId || actionExecId <= 0) {
                                            showInfoMessage("Некорректный ID действия.");
                                            return;
                                        }

                                        var component = Qt.createComponent("ActionExecutionNotesDialog.qml");
                                        if (component.status === Component.Ready) {
                                            var dialog = component.createObject(executionDetailsWindow, {
                                                "actionExecutionId": actionExecId,
                                                "initialNotes": actionsTableModel.rows[row]["Примечания"] || ""
                                            });
                                            if (dialog) {
                                                dialog.notesSaved.connect(function() {
                                                    executionDetailsWindow.loadExecutionData(); // ← перезагружаем ВСЁ
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

    // --- Модальное окно для полного описания ---
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
        TableModelColumn { display: "Примечания" } 
        TableModelColumn { display: "isCompleted" }
        TableModelColumn { display: "actualEndTimeDisplay" }
    }
}