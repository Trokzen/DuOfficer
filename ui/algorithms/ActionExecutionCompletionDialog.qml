// ui/algorithms/ActionExecutionCompletionDialog.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import QtQuick.Dialogs 6.5

Popup {
    id: actionExecutionCompletionDialog

    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width * 0.8, 650)
    height: Math.min(parent.height * 0.85, 650) // Увеличили высоту
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    property bool isEditMode: false
    property int executionId: -1
    property int currentActionExecutionId: -1
    signal actionExecutionSaved()

    background: Rectangle {
        color: "white"
        border.color: "#3498db"
        radius: 8
        border.width: 2
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 20

        Label {
            id: dialogTitleLabel
            text: actionExecutionCompletionDialog.isEditMode ? "Изменить выполнение действия" : "Ввод данных о выполнении"
            font.pointSize: 16
            font.bold: true
            color: "#2c3e50"
            Layout.alignment: Qt.AlignHCenter
        }

        // --- Описание действия ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5
            Label {
                text: "Описание действия:"
                font.bold: true
                color: "#495057"
            }
            TextArea {
                id: descriptionArea
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                readOnly: true
                wrapMode: TextArea.Wrap
                background: Rectangle {
                    border.color: "#ced4da"
                    border.width: 1
                    radius: 3
                    color: "#e9ecef"
                }
                selectByMouse: true
            }
        }
        // --- ---

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 15

                // --- Секция: Время выполнения (без GroupBox) ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    // Заголовок секции (опционально, можно убрать)
                    // Label {
                    //     text: "Время выполнения"
                    //     font.pointSize: 12
                    //     font.bold: true
                    //     color: "#2c3e50"
                    // }

                    // Фактическое время окончания
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        Label {
                            text: "Фактическое время выполнения:*"
                            font.bold: true
                            color: "#495057"
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            TextField {
                                id: actualEndDateField
                                Layout.fillWidth: true
                                placeholderText: "ДД.ММ.ГГГГ"
                                background: Rectangle {
                                    border.color: actualEndDateField.activeFocus ? "#3498db" : "#ced4da"
                                    border.width: 1
                                    radius: 3
                                    color: "white"
                                }
                            }
                            Button {
                                text: "📅"
                                font.pixelSize: 14
                                Layout.preferredWidth: 45
                                Layout.preferredHeight: 35
                                background: Rectangle {
                                    color: "#3498db"
                                    radius: 3
                                    border.color: "#2980b9"
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: parent.font.pixelSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    console.log("QML ActionExecutionCompletionDialog: Нажата кнопка календаря для фактической даты окончания.");
                                    var currentDateText = actualEndDateField.text.trim();
                                    var dateRegex = /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.\d{4}$/;
                                    if (dateRegex.test(currentDateText)) {
                                        var parts = currentDateText.split('.');
                                        var day = parseInt(parts[0], 10);
                                        var month = parseInt(parts[1], 10) - 1;
                                        var year = parseInt(parts[2], 10);
                                        var testDate = new Date(year, month, day);
                                        if (testDate.getDate() === day && testDate.getMonth() === month && testDate.getFullYear() === year) {
                                            customCalendarPicker.selectedDate = testDate;
                                            console.log("QML ActionExecutionCompletionDialog: CustomCalendarPicker инициализирован датой из поля:", testDate);
                                        } else {
                                            customCalendarPicker.selectedDate = new Date();
                                            console.log("QML ActionExecutionCompletionDialog: CustomCalendarPicker инициализирован текущей датой (некорректная дата в поле).");
                                        }
                                    } else {
                                        customCalendarPicker.selectedDate = new Date();
                                        console.log("QML ActionExecutionCompletionDialog: CustomCalendarPicker инициализирован текущей датой (некорректный формат в поле).");
                                    }
                                    customCalendarPicker.open();
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            ColumnLayout {
                                spacing: 3
                                TextField {
                                    id: actualEndTimeHoursField
                                    Layout.preferredWidth: 60
                                    placeholderText: "ЧЧ"
                                    text: "00"
                                    validator: IntValidator { bottom: 0; top: 23 }
                                    horizontalAlignment: TextInput.AlignHCenter
                                    background: Rectangle {
                                        border.color: actualEndTimeHoursField.activeFocus ? "#3498db" : "#ced4da"
                                        border.width: 1
                                        radius: 3
                                        color: "white"
                                    }
                                }
                                RowLayout {
                                    spacing: 2
                                    Button {
                                        text: "▲"
                                        font.pixelSize: 8
                                        Layout.preferredWidth: 25
                                        Layout.preferredHeight: 18
                                        onClicked: {
                                            var currentValue = parseInt(actualEndTimeHoursField.text) || 0;
                                            var newValue = (currentValue + 1) % 24;
                                            actualEndTimeHoursField.text = newValue.toString().padStart(2, '0');
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        font.pixelSize: 8
                                        Layout.preferredWidth: 25
                                        Layout.preferredHeight: 18
                                        onClicked: {
                                            var currentValue = parseInt(actualEndTimeHoursField.text) || 0;
                                            var newValue = (currentValue - 1 + 24) % 24;
                                            actualEndTimeHoursField.text = newValue.toString().padStart(2, '0');
                                        }
                                    }
                                }
                            }
                            Text { text: ":"; font.pixelSize: 12; Layout.preferredHeight: 35; verticalAlignment: Text.AlignVCenter }

                            ColumnLayout {
                                spacing: 3
                                TextField {
                                    id: actualEndTimeMinutesField
                                    Layout.preferredWidth: 60
                                    placeholderText: "ММ"
                                    text: "00"
                                    validator: IntValidator { bottom: 0; top: 59 }
                                    horizontalAlignment: TextInput.AlignHCenter
                                    background: Rectangle {
                                        border.color: actualEndTimeMinutesField.activeFocus ? "#3498db" : "#ced4da"
                                        border.width: 1
                                        radius: 3
                                        color: "white"
                                    }
                                }
                                RowLayout {
                                    spacing: 2
                                    Button {
                                        text: "▲"
                                        font.pixelSize: 8
                                        Layout.preferredWidth: 25
                                        Layout.preferredHeight: 18
                                        onClicked: {
                                            var currentValue = parseInt(actualEndTimeMinutesField.text) || 0;
                                            var newValue = (currentValue + 1) % 60;
                                            actualEndTimeMinutesField.text = newValue.toString().padStart(2, '0');
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        font.pixelSize: 8
                                        Layout.preferredWidth: 25
                                        Layout.preferredHeight: 18
                                        onClicked: {
                                            var currentValue = parseInt(actualEndTimeMinutesField.text) || 0;
                                            var newValue = (currentValue - 1 + 60) % 60;
                                            actualEndTimeMinutesField.text = newValue.toString().padStart(2, '0');
                                        }
                                    }
                                }
                            }
                            Text { text: ":"; font.pixelSize: 12; Layout.preferredHeight: 35; verticalAlignment: Text.AlignVCenter }

                            ColumnLayout {
                                spacing: 3
                                TextField {
                                    id: actualEndTimeSecondsField
                                    Layout.preferredWidth: 60
                                    placeholderText: "СС"
                                    text: "00"
                                    validator: IntValidator { bottom: 0; top: 59 }
                                    horizontalAlignment: TextInput.AlignHCenter
                                    background: Rectangle {
                                        border.color: actualEndTimeSecondsField.activeFocus ? "#3498db" : "#ced4da"
                                        border.width: 1
                                        radius: 3
                                        color: "white"
                                    }
                                }
                                RowLayout {
                                    spacing: 2
                                    Button {
                                        text: "▲"
                                        font.pixelSize: 8
                                        Layout.preferredWidth: 25
                                        Layout.preferredHeight: 18
                                        onClicked: {
                                            var currentValue = parseInt(actualEndTimeSecondsField.text) || 0;
                                            var newValue = (currentValue + 1) % 60;
                                            actualEndTimeSecondsField.text = newValue.toString().padStart(2, '0');
                                        }
                                    }
                                    Button {
                                        text: "▼"
                                        font.pixelSize: 8
                                        Layout.preferredWidth: 25
                                        Layout.preferredHeight: 18
                                        onClicked: {
                                            var currentValue = parseInt(actualEndTimeSecondsField.text) || 0;
                                            var newValue = (currentValue - 1 + 60) % 60;
                                            actualEndTimeSecondsField.text = newValue.toString().padStart(2, '0');
                                        }
                                    }
                                }
                            }

                            // --- Кнопка "Предельное" (рядом с секундами) ---
                            Button {
                                id: setExtremeTimeButton
                                text: "Предельное"
                                Layout.preferredWidth: 100
                                Layout.alignment: Qt.AlignBottom // Прижимаем к низу строки
                                background: Rectangle {
                                    color: "#e67e22"
                                    radius: 3
                                    border.color: "#d35400"
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: parent.font.pixelSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    console.log("QML ActionExecutionCompletionDialog: Нажата кнопка 'Предельное'.");
                                    if (actionExecutionCompletionDialog.currentActionExecutionId > 0) {
                                        var actionExecData = appData.getActionExecutionById(actionExecutionCompletionDialog.currentActionExecutionId);
                                        console.log("QML ActionExecutionCompletionDialog: Получены данные action_execution (сырой):", JSON.stringify(actionExecData).substring(0, 500));

                                        if (actionExecData && typeof actionExecData === 'object' && actionExecData.hasOwnProperty('toVariant')) {
                                            actionExecData = actionExecData.toVariant();
                                        }

                                        if (actionExecData && actionExecData.calculated_end_time) {
                                            var calcEndTimeStr = actionExecData.calculated_end_time;
                                            console.log("QML ActionExecutionCompletionDialog: calculated_end_time из БД:", calcEndTimeStr);

                                            var match1 = calcEndTimeStr.match(/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})$/);
                                            var match2 = calcEndTimeStr.match(/^(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})$/);

                                            if (match1) {
                                                actualEndDateField.text = match1[3] + "." + match1[2] + "." + match1[1];
                                                actualEndTimeHoursField.text = match1[4];
                                                actualEndTimeMinutesField.text = match1[5];
                                                actualEndTimeSecondsField.text = match1[6];
                                            } else if (match2) {
                                                actualEndDateField.text = calcEndTimeStr.substring(0, 10);
                                                actualEndTimeHoursField.text = calcEndTimeStr.substring(11, 13);
                                                actualEndTimeMinutesField.text = calcEndTimeStr.substring(14, 16);
                                                actualEndTimeSecondsField.text = calcEndTimeStr.substring(17, 19);
                                            } else {
                                                console.warn("QML ActionExecutionCompletionDialog: Неизвестный формат calculated_end_time:", calcEndTimeStr);
                                                errorMessageLabel.text = "Неизвестный формат времени 'предельного' выполнения.";
                                                return;
                                            }
                                            console.log("QML ActionExecutionCompletionDialog: Время 'предельное' подставлено в поля.");
                                            errorMessageLabel.text = "";
                                        } else {
                                            console.warn("QML ActionExecutionCompletionDialog: Не удалось получить calculated_end_time для action_execution ID", actionExecutionCompletionDialog.currentActionExecutionId);
                                            errorMessageLabel.text = "Не удалось получить 'предельное' время из данных действия.";
                                        }
                                    } else {
                                        console.warn("QML ActionExecutionCompletionDialog: currentActionExecutionId не задан.");
                                        errorMessageLabel.text = "Невозможно получить 'предельное' время: ID действия неизвестен.";
                                    }
                                }
                            }
                        }
                    }
                }
                // --- ---

                // --- Разделитель ---
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: "#ced4da"
                }
                // --- ---

                // --- Секция: Дополнительная информация (без GroupBox) ---
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Заголовок секции (опционально, можно убрать)
                    // Label {
                    //     text: "Дополнительная информация"
                    //     font.pointSize: 12
                    //     font.bold: true
                    //     color: "#2c3e50"
                    // }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Label {
                            text: "Кому доложено:"
                            font.bold: true
                            color: "#495057"
                        }
                        TextField {
                            id: reportedToField
                            Layout.fillWidth: true
                            placeholderText: "Введите, кому было доложено о выполнении..."
                            background: Rectangle {
                                border.color: reportedToField.activeFocus ? "#3498db" : "#ced4da"
                                border.width: 1
                                radius: 3
                                color: "white"
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Label {
                            text: "Отчётные материалы:"
                            font.bold: true
                            color: "#495057"
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            TextArea {
                                id: reportMaterialsArea
                                Layout.fillWidth: true
                                Layout.preferredHeight: 80 // Фиксированная высота
                                placeholderText: "Пути к файлам отчётных материалов (по одному на строку)..."
                                wrapMode: TextArea.Wrap
                                background: Rectangle {
                                    border.color: reportMaterialsArea.activeFocus ? "#3498db" : "#ced4da"
                                    border.width: 1
                                    radius: 3
                                    color: "white"
                                }
                            }

                            Button {
                                text: "Добавить файлы отчёта..."
                                Layout.alignment: Qt.AlignLeft
                                background: Rectangle {
                                    color: "#2ecc71"
                                    radius: 3
                                    border.color: "#27ae60"
                                }
                                contentItem: Text {
                                    text: parent.text
                                    color: "white"
                                    font.pixelSize: parent.font.pixelSize
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                                onClicked: {
                                    console.log("QML ActionExecutionCompletionDialog: Нажата кнопка 'Добавить файлы отчёта...'");
                                    reportMaterialsFileDialog.open();
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 5
                        Label {
                            text: "Примечания:"
                            font.bold: true
                            color: "#495057"
                        }
                        TextArea {
                            id: notesArea
                            Layout.fillWidth: true
                            Layout.preferredHeight: 120 // Увеличена высота, чтобы не обрезалось
                            placeholderText: "Введите дополнительные примечания..."
                            wrapMode: TextArea.Wrap
                            background: Rectangle {
                                border.color: notesArea.activeFocus ? "#3498db" : "#ced4da"
                                border.width: 1
                                radius: 3
                                color: "white"
                            }
                        }
                    }
                }
                // --- ---
            }
        }

        Label {
            id: errorMessageLabel
            Layout.fillWidth: true
            color: "red"
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 15
            Item { Layout.fillWidth: true }
            Button {
                text: "Отмена"
                Layout.preferredWidth: 100
                background: Rectangle {
                    color: "#95a5a6"
                    radius: 3
                    border.color: "#7f8c8d"
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    console.log("QML ActionExecutionCompletionDialog: Нажата кнопка Отмена");
                    actionExecutionCompletionDialog.close();
                }
            }
            Button {
                id: saveButton
                text: "Сохранить"
                Layout.preferredWidth: 100
                background: Rectangle {
                    color: "#3498db"
                    radius: 3
                    border.color: "#2980b9"
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    font.pixelSize: parent.font.pixelSize
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                onClicked: {
                    console.log("QML ActionExecutionCompletionDialog: Нажата кнопка Сохранить");
                    errorMessageLabel.text = "";

                    if (!actualEndDateField.text.trim()) {
                        errorMessageLabel.text = "Пожалуйста, заполните дату фактического выполнения.";
                        return;
                    }
                    var dateRegex = /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.\d{4}$/;
                    if (!dateRegex.test(actualEndDateField.text.trim())) {
                        errorMessageLabel.text = "Некорректный формат даты. Используйте ДД.ММ.ГГГГ.";
                        return;
                    }

                    var hours = parseInt(actualEndTimeHoursField.text, 10);
                    var minutes = parseInt(actualEndTimeMinutesField.text, 10);
                    var seconds = parseInt(actualEndTimeSecondsField.text, 10);

                    if (isNaN(hours) || hours < 0 || hours > 23 ||
                        isNaN(minutes) || minutes < 0 || minutes > 59 ||
                        isNaN(seconds) || seconds < 0 || seconds > 59) {
                        errorMessageLabel.text = "Некорректное время выполнения. Проверьте часы, минуты и секунды.";
                        return;
                    }

                    var actualEndTimeStr = actualEndDateField.text.trim() + " " +
                                           String(hours).padStart(2, '0') + ":" +
                                           String(minutes).padStart(2, '0') + ":" +
                                           String(seconds).padStart(2, '0');

                    var actionExecutionData = {
                        "actual_end_time": actualEndTimeStr,
                        "reported_to": reportedToField.text.trim() || null,
                        "snapshot_report_materials": reportMaterialsArea.text.trim() || null,
                        "notes": notesArea.text.trim() || null
                    };

                    console.log("QML ActionExecutionCompletionDialog: Отправляем данные о выполнении action_execution ID", currentActionExecutionId, "в Python:", JSON.stringify(actionExecutionData));

                    var result = appData.updateActionExecution(currentActionExecutionId, actionExecutionData);

                    if (result === true) {
                        console.log("QML ActionExecutionCompletionDialog: Данные о выполнении action_execution ID", currentActionExecutionId, "успешно обновлены.");
                        actionExecutionCompletionDialog.actionExecutionSaved();
                        actionExecutionCompletionDialog.close();
                    } else if (typeof result === 'string') {
                        errorMessageLabel.text = result;
                        console.warn("QML ActionExecutionCompletionDialog: Ошибка обновления action_execution:", result);
                    } else {
                        errorMessageLabel.text = "Неизвестная ошибка при сохранении данных.";
                        console.error("QML ActionExecutionCompletionDialog: Неизвестная ошибка обновления action_execution. Результат:", result);
                    }
                }
            }
        }
    }

    FileDialog {
        id: reportMaterialsFileDialog
        title: "Выберите файлы отчётных материалов"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["Все файлы (*)", "Документы (*.doc *.docx *.pdf)", "Изображения (*.png *.jpg *.jpeg *.gif)"]
        onAccepted: {
            console.log("QML ActionExecutionCompletionDialog: FileDialog accepted. Selected files:", JSON.stringify(reportMaterialsFileDialog.selectedFiles));
            var currentText = reportMaterialsArea.text;
            var newText = "";
            for (var i = 0; i < reportMaterialsFileDialog.selectedFiles.length; i++) {
                var filePath = reportMaterialsFileDialog.selectedFiles[i].toString();
                if (filePath.startsWith("file:///")) {
                    filePath = filePath.substring(8);
                }
                newText += filePath;
                if (i < reportMaterialsFileDialog.selectedFiles.length - 1) {
                    newText += "\n";
                }
            }
            if (currentText.length > 0 && !currentText.endsWith("\n")) {
                currentText += "\n";
            }
            reportMaterialsArea.text = currentText + newText;
        }
        onRejected: {
            console.log("QML ActionExecutionCompletionDialog: FileDialog rejected")
        }
    }

    CustomCalendarPicker {
        id: customCalendarPicker
        onDateSelected: {
            console.log("QML ActionExecutionCompletionDialog: CustomCalendarPicker: Дата выбрана:", Qt.formatDate(customCalendarPicker.selectedDate, "yyyy-MM-dd"));
            var year = customCalendarPicker.selectedDate.getFullYear();
            var month = String(customCalendarPicker.selectedDate.getMonth() + 1).padStart(2, '0');
            var day = String(customCalendarPicker.selectedDate.getDate()).padStart(2, '0');
            var formattedDate = day + "." + month + "." + year;
            console.log("QML ActionExecutionCompletionDialog: CustomCalendarPicker: Отформатированная дата:", formattedDate);
            actualEndDateField.text = formattedDate;
        }
    }

    function loadActionExecutionData() {
        if (currentActionExecutionId <= 0) {
            console.warn("QML ActionExecutionCompletionDialog: currentActionExecutionId не задан, невозможно загрузить данные для редактирования.");
            return;
        }

        console.log("QML ActionExecutionCompletionDialog: Запрос данных action_execution ID", currentActionExecutionId, "у Python...");
        var actionExecData = appData.getActionExecutionById(currentActionExecutionId);
        console.log("QML ActionExecutionCompletionDialog: Получены данные action_execution (сырой):", JSON.stringify(actionExecData).substring(0, 500));

        if (actionExecData && typeof actionExecData === 'object' && actionExecData.hasOwnProperty('toVariant')) {
            console.log("QML ActionExecutionCompletionDialog: Обнаружен QJSValue, преобразование в JS-объект...");
            actionExecData = actionExecData.toVariant();
            console.log("QML ActionExecutionCompletionDialog: QJSValue (actionExecData) преобразован в:", JSON.stringify(actionExecData).substring(0, 500));
        } else {
            console.log("QML ActionExecutionCompletionDialog: Преобразование QJSValue не требуется.");
        }

        if (actionExecData && typeof actionExecData === 'object') {
            descriptionArea.text = actionExecData.snapshot_description || "";
            console.log("QML ActionExecutionCompletionDialog: Загружено описание:", descriptionArea.text);

            var actualEndTime = actionExecData.actual_end_time;
            if (actualEndTime) {
                console.log("QML ActionExecutionCompletionDialog: Загружено actual_end_time из БД:", actualEndTime);
                var match1 = actualEndTime.match(/^(\d{4})-(\d{2})-(\d{2})\s+(\d{2}):(\d{2}):(\d{2})$/);
                var match2 = actualEndTime.match(/^(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})$/);

                if (match1) {
                    actualEndDateField.text = match1[3] + "." + match1[2] + "." + match1[1];
                    actualEndTimeHoursField.text = match1[4];
                    actualEndTimeMinutesField.text = match1[5];
                    actualEndTimeSecondsField.text = match1[6];
                } else if (match2) {
                    actualEndDateField.text = actualEndTime.substring(0, 10);
                    actualEndTimeHoursField.text = actualEndTime.substring(11, 13);
                    actualEndTimeMinutesField.text = actualEndTime.substring(14, 16);
                    actualEndTimeSecondsField.text = actualEndTime.substring(17, 19);
                } else {
                    console.warn("QML ActionExecutionCompletionDialog: Неизвестный формат actual_end_time:", actualEndTime);
                }
            } else {
                 console.log("QML ActionExecutionCompletionDialog: actual_end_time в БД отсутствует, поля времени остаются пустыми.");
            }

            reportedToField.text = actionExecData.reported_to || "";
            console.log("QML ActionExecutionCompletionDialog: Загружено reported_to:", reportedToField.text);

            reportMaterialsArea.text = actionExecData.report_materials || "";
            console.log("QML ActionExecutionCompletionDialog: Загружено report_materials (первых 200 символов):", reportMaterialsArea.text.substring(0, 200));

            notesArea.text = actionExecData.notes || "";
            console.log("QML ActionExecutionCompletionDialog: Загружено notes (первых 200 символов):", notesArea.text.substring(0, 200));

        } else {
             console.warn("QML ActionExecutionCompletionDialog: Не удалось получить корректные данные action_execution ID", currentActionExecutionId, "из Python.");
             descriptionArea.text = "";
             actualEndDateField.text = "";
             actualEndTimeHoursField.text = "00";
             actualEndTimeMinutesField.text = "00";
             actualEndTimeSecondsField.text = "00";
             reportedToField.text = "";
             reportMaterialsArea.text = "";
             notesArea.text = "";
        }
    }

    function loadCurrentLocalTime() {
        console.log("QML ActionExecutionCompletionDialog: Загрузка текущего местного времени из appData.");
        var localDate = appData.localDate;
        var localTime = appData.localTime;

        console.log("QML ActionExecutionCompletionDialog: Получено местное время: дата =", localDate, ", время =", localTime);

        actualEndDateField.text = localDate;

        var timeParts = localTime.split(':');
        if (timeParts.length === 3) {
            actualEndTimeHoursField.text = timeParts[0];
            actualEndTimeMinutesField.text = timeParts[1];
            actualEndTimeSecondsField.text = timeParts[2];
        } else {
            console.warn("QML ActionExecutionCompletionDialog: Невозможно разобрать местное время:", localTime);
        }
    }

    onOpened: {
        console.log("QML ActionExecutionCompletionDialog: Диалог открыт. Режим:", isEditMode ? "Редактирование" : "Ввод новых данных", ". ID action_execution:", currentActionExecutionId);
        errorMessageLabel.text = "";

        if (isEditMode) {
            actionExecutionCompletionDialog.loadActionExecutionData();
        } else {
            descriptionArea.text = "";
            actualEndDateField.text = "";
            actualEndTimeHoursField.text = "00";
            actualEndTimeMinutesField.text = "00";
            actualEndTimeSecondsField.text = "00";
            reportedToField.text = "";
            reportMaterialsArea.text = "";
            notesArea.text = "";

            actionExecutionCompletionDialog.loadCurrentLocalTime();
        }
    }
}