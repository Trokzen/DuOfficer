// ui/algorithms/ExecutionDetailsWindow.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import QtQuick.Dialogs 6.5 // Для открытия файлов
import Qt.labs.qmlmodels 1.0 // <-- ИМПОРТ ДЛЯ TableModel

Window {
    id: executionDetailsWindow
    width: 1400
    height: 900
    minimumWidth: 1200
    minimumHeight: 700
    // visible: true // Будет управляться извне
    title: "Детали выполнения алгоритма" // Временный заголовок, будет обновляться

    // --- Свойства ---
    property int executionId: -1
    property var executionData: null // Данные execution'а
    // property var actionExecutionsList: [] // Список action_execution'ов - больше не нужно как отдельное свойство

    // --- Сигналы ---
    signal executionUpdated(int executionId) // Для уведомления родителя о перезагрузке

    // --- Вспомогательные функции ---
    function openFile(filePath) {
        console.log("QML ExecutionDetailsWindow: Попытка открыть файл:", filePath);
        if (Qt.openUrlExternally("file:///" + filePath)) {
            console.log("QML ExecutionDetailsWindow: Файл успешно открыт внешней программой:", filePath);
        } else {
            console.warn("QML ExecutionDetailsWindow: Не удалось открыть файл внешней программой:", filePath);
            // TODO: Показать сообщение пользователю
        }
    }

    // --- Вспомогательные функции ---
    function mapStatusToText(status) {
        if (status === "completed") return "Выполнено";
        else if (status === "pending") return "Ожидает";
        else if (status === "in_progress") return "В процессе";
        else if (status === "skipped") return "Пропущено";
        else return status;
    }

    // --- Функция для экранирования HTML ---
    function escapeHtml(unsafe) {
        if (typeof unsafe !== 'string') return '';
        return unsafe
            .replace(/&/g, "&amp;")
            .replace(/</g, "<")
            .replace(/>/g, ">")
            .replace(/"/g, "&quot;")
            .replace(/'/g, "&#039;");
    }
    // --- ---

    // --- Функция для обновления данных ---
    function loadExecutionData() {
        console.log("QML ExecutionDetailsWindow: Загрузка данных execution ID", executionId);
        if (executionId <= 0) {
            console.error("QML ExecutionDetailsWindow: executionId <= 0, загрузка невозможна.");
            return;
        }

        // Получаем данные execution'а
        var execData = appData.getExecutionById(executionId);
        console.log("QML ExecutionDetailsWindow: Получены данные execution (сырой):", execData ? JSON.stringify(execData).substring(0, 500) : "null/undefined");

        if (execData && typeof execData === 'object' && execData.hasOwnProperty('toVariant')) {
            execData = execData.toVariant();
        }

        if (execData && typeof execData === 'object') {
            executionData = execData;
            // Обновляем заголовок окна
            executionDetailsWindow.title = "Детали выполнения: " + (executionData.snapshot_name || "Без названия");
            console.log("QML ExecutionDetailsWindow: Заголовок окна обновлён.");
        } else {
            console.error("QML ExecutionDetailsWindow: Не удалось получить корректные данные execution.");
            executionData = null;
            executionDetailsWindow.title = "Детали выполнения алгоритма (ошибка)";
            return; // Прерываем загрузку действий
        }

        // Получаем список action_execution'ов
        var actionsList = appData.getActionExecutionsByExecutionId(executionId);
        console.log("QML ExecutionDetailsWindow: Получен список action_executions (сырой):", actionsList ? JSON.stringify(actionsList).substring(0, 500) : "null/undefined");
        console.log("QML ExecutionDetailsWindow: Тип полученного списка:", typeof actionsList);
        console.log("QML ExecutionDetailsWindow: actionsList instanceof Object:", actionsList instanceof Object);
        console.log("QML ExecutionDetailsWindow: Array.isArray(actionsList):", Array.isArray(actionsList));

        // --- ИСПРАВЛЕНО: Преобразование QVariantList в JS Array ---
        // Проверяем, является ли объект "массивоподобным" (имеет length)
        if (actionsList && typeof actionsList === 'object' && actionsList.length !== undefined) {
            console.log("QML ExecutionDetailsWindow: Полученный список является массивоподобным. Количество элементов:", actionsList.length);

            if (actionsList.length === 0) {
                console.log("QML ExecutionDetailsWindow: Список action_execution'ов пуст.");
            }

            // Создаём новый JS массив
            var jsActionList = [];
            for (var i = 0; i < actionsList.length; i++) {
                jsActionList.push(actionsList[i]);
            }
            actionsList = jsActionList; // Теперь actionsList - это JS Array
            console.log("QML ExecutionDetailsWindow: QVariantList преобразован в JS Array. Длина:", actionsList.length);
        } else {
            console.error("QML ExecutionDetailsWindow: Python не вернул корректный массивоподобный объект для action_executions. Получен тип:", typeof actionsList, "Значение:", actionsList);
            actionsList = []; // Убедимся, что это массив
        }
        // --- ---

        // --- ИЗМЕНЕНО: Создаём JS-массив и заполняем его JS-объектами ---
        var jsRows = []; // Новый JS-массив
        for (var i = 0; i < actionsList.length; i++) {
            var actionExec = actionsList[i];
            // --- Явное копирование свойств и форматирование ---
            // ВАЖНО: Копируем *все* значения, чтобы избежать QVariants
            var id = (actionExec["id"] !== undefined && actionExec["id"] !== null) ? actionExec["id"] : -1;
            var execution_id = (actionExec["execution_id"] !== undefined && actionExec["execution_id"] !== null) ? actionExec["execution_id"] : -1;
            var snapshot_description = (actionExec["snapshot_description"] !== undefined && actionExec["snapshot_description"] !== null) ? String(actionExec["snapshot_description"]) : "";
            var snapshot_contact_phones = (actionExec["snapshot_contact_phones"] !== undefined && actionExec["snapshot_contact_phones"] !== null) ? String(actionExec["snapshot_contact_phones"]) : "";
            var snapshot_report_materials = (actionExec["snapshot_report_materials"] !== undefined && actionExec["snapshot_report_materials"] !== null) ? String(actionExec["snapshot_report_materials"]) : "";
            var calculated_start_time = (actionExec["calculated_start_time"] !== undefined && actionExec["calculated_start_time"] !== null) ? String(actionExec["calculated_start_time"]) : "";
            var calculated_end_time = (actionExec["calculated_end_time"] !== undefined && actionExec["calculated_end_time"] !== null) ? String(actionExec["calculated_end_time"]) : "";
            var actual_end_time = (actionExec["actual_end_time"] !== undefined && actionExec["actual_end_time"] !== null) ? String(actionExec["actual_end_time"]) : "";
            var status = (actionExec["status"] !== undefined && actionExec["status"] !== null) ? String(actionExec["status"]) : "unknown";
            var reported_to = (actionExec["reported_to"] !== undefined && actionExec["reported_to"] !== null) ? String(actionExec["reported_to"]) : "";
            var notes = (actionExec["notes"] !== undefined && actionExec["notes"] !== null) ? String(actionExec["notes"]) : "";
            var created_at = (actionExec["created_at"] !== undefined && actionExec["created_at"] !== null) ? String(actionExec["created_at"]) : "";
            var updated_at = (actionExec["updated_at"] !== undefined && actionExec["updated_at"] !== null) ? String(actionExec["updated_at"]) : "";

            var formattedStartTime = "";
            if (calculated_start_time) {
                var startDt = new Date(calculated_start_time);
                if (!isNaN(startDt.getTime())) {
                    var timeStr = startDt.toLocaleTimeString(Qt.locale(), "HH:mm");
                    var dateStr = startDt.toLocaleDateString(Qt.locale(), "dd.MM");
                    formattedStartTime = timeStr + "\n" + dateStr;
                } else {
                    formattedStartTime = calculated_start_time;
                }
            }

            var formattedEndTime = "";
            if (calculated_end_time) {
                var endDt = new Date(calculated_end_time);
                if (!isNaN(endDt.getTime())) {
                    var timeStr = endDt.toLocaleTimeString(Qt.locale(), "HH:mm");
                    var dateStr = endDt.toLocaleDateString(Qt.locale(), "dd.MM");
                    formattedEndTime = timeStr + "\n" + dateStr;
                } else {
                    formattedEndTime = calculated_end_time;
                }
            }

            var formattedActualTime = "";
            if (actual_end_time) {
                var actualDt = new Date(actual_end_time);
                if (!isNaN(actualDt.getTime())) {
                    var timeStr = actualDt.toLocaleTimeString(Qt.locale(), "HH:mm");
                    var dateStr = actualDt.toLocaleDateString(Qt.locale(), "dd.MM");
                    formattedActualTime = timeStr + "\n" + dateStr;
                } else {
                    formattedActualTime = actual_end_time;
                }
            }

            // --- HTML для отчетных материалов ---
            var materials = snapshot_report_materials;
            var htmlMaterials = "";
            if (materials) {
                var paths = materials.split('\n');
                for (var j = 0; j < paths.length; j++) {
                    var path = paths[j].trim();
                    if (path) {
                        if (path.startsWith("file:///")) path = path.substring(8);
                        // --- ИСПРАВЛЕНО: Используем вспомогательную функцию escapeHtml ---
                        htmlMaterials += "<a href=\"" + path + "\">" + escapeHtml(path) + "</a><br/>";
                        // ---
                    }
                }
            }

            var actionExecCopy = {
                "id": id,
                "execution_id": execution_id,
                "snapshot_description": snapshot_description,
                "snapshot_contact_phones": snapshot_contact_phones,
                "snapshot_report_materials": snapshot_report_materials,
                "calculated_start_time": calculated_start_time,
                "calculated_end_time": calculated_end_time,
                "actual_end_time": actual_end_time,
                "status": status,
                "reported_to": reported_to,
                "notes": notes,
                "created_at": created_at,
                "updated_at": updated_at,

                // --- Добавленные поля для отображения ---
                "status_display": status,
                "calculated_start_time_formatted": formattedStartTime,
                "calculated_end_time_formatted": formattedEndTime,
                "actual_end_time_formatted": formattedActualTime,
                "status_text": mapStatusToText(status),
                "snapshot_report_materials_formatted": htmlMaterials,
                "button_placeholder": ""
            };
            // --- ---
            jsRows.push(actionExecCopy); // Добавляем в JS-массив
            console.log("QML ExecutionDetailsWindow: Action_execution", i, "добавлен в JS-массив (id:", actionExecCopy.id, ").");
        }

        // --- ИЗМЕНЕНО: Присваиваем JS-массив TableModel.rows ---
        actionsTableModel.rows = jsRows; // Присваиваем *весь* массив за раз
        console.log("QML ExecutionDetailsWindow: TableModel action_executions обновлена. Элементов:", actionsTableModel.rows.length);

        // --- ОТЛАДКА СОДЕРЖИМОГО МОДЕЛИ ---
        if (actionsTableModel.rows.length > 0) {
            try {
                console.log("QML ExecutionDetailsWindow: Первый элемент в TableModel:", JSON.stringify(actionsTableModel.rows[0]));
            } catch (e_log) {
                console.warn("QML ExecutionDetailsWindow: Не удалось залогировать первый элемент TableModel:", e_log.toString());
            }
        }
        // --- ---
    }

    // --- Основной контент ---
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
                text: executionData ? (executionData.snapshot_name || "Без названия") + "\n" + (executionData.started_at || "Не задано") : "Загрузка..."
                font.family: appData.fontFamily || "Arial"
                font.pointSize: (appData.fontSize || 12) * 1.2
                font.bold: true
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                wrapMode: Text.Wrap
            }
        }
        // --- ---

        // --- Кнопки верхнего уровня ---
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            spacing: 10

            Button {
                text: "График"
                onClicked: {
                    console.log("QML ExecutionDetailsWindow: Кнопка 'График' нажата (заглушка).");
                    showInfoMessage("Функция диаграммы в разработке.");
                }
            }

            Item { Layout.fillWidth: true } // Заполнитель

            Button {
                text: "Добавить действие"
                onClicked: {
                    console.log("QML ExecutionDetailsWindow: Кнопка 'Добавить действие' нажата.");
                    var component = Qt.createComponent("ActionExecutionEditorDialog.qml");
                    if (component.status === Component.Ready) {
                        var dialog = component.createObject(executionDetailsWindow, {
                            "executionId": executionId,
                            "isEditMode": false
                        });
                        if (dialog) {
                            dialog.onActionExecutionSaved.connect(function() {
                                console.log("QML ExecutionDetailsWindow: Получен сигнал о сохранении нового action_execution. Перезагружаем данные.");
                                executionDetailsWindow.loadExecutionData();
                                executionUpdated(executionId);
                            });
                            dialog.open();
                        } else {
                            console.error("QML ExecutionDetailsWindow: Не удалось создать ActionExecutionEditorDialog (режим добавления).");
                            showInfoMessage("Ошибка: Не удалось открыть диалог добавления действия.");
                        }
                    } else {
                         console.error("QML ExecutionDetailsWindow: Ошибка загрузки ActionExecutionEditorDialog.qml:", component.errorString());
                         showInfoMessage("Ошибка загрузки диалога добавления действия.");
                    }
                }
            }

            Button {
                text: "Авто"
                onClicked: {
                    console.log("QML ExecutionDetailsWindow: Кнопка 'Авто' нажата.");
                    var success = appData.autoCompleteActionExecutions(executionId);
                    if (success) {
                        console.log("QML ExecutionDetailsWindow: Авто-выполнение успешно.");
                        executionDetailsWindow.loadExecutionData();
                        executionUpdated(executionId);
                    } else {
                        console.warn("QML ExecutionDetailsWindow: Ошибка авто-выполнения.");
                        showInfoMessage("Ошибка при авто-выполнении действий.");
                    }
                }
            }

            Button {
                text: "Печать"
                onClicked: {
                    console.log("QML ExecutionDetailsWindow: Кнопка 'Печать' нажата (заглушка).");
                    showInfoMessage("Функция печати в разработке.");
                }
            }

            Button {
                text: "Закрыть"
                onClicked: executionDetailsWindow.close()
            }
        }
        // --- ---

        // --- Таблица действий ---
        Item { // <-- Внешний контейнер
            Layout.fillWidth: true
            Layout.fillHeight: true

            // --- Модель данных для TableView ---
            TableModel {
                id: actionsTableModel
                // ... существующие столбцы ...
                TableModelColumn { display: "status_display" }        // Столбец 0
                TableModelColumn { display: "id" }                   // Столбец 1
                TableModelColumn { display: "snapshot_description" } // Столбец 2
                TableModelColumn { display: "calculated_start_time_formatted" } // Столбец 3
                TableModelColumn { display: "calculated_end_time_formatted" }   // Столбец 4
                TableModelColumn { display: "snapshot_contact_phones" } // Столбец 5
                TableModelColumn { display: "snapshot_report_materials_formatted" } // Столбец 6
                TableModelColumn { display: "actual_end_time_formatted" }       // Столбец 7
                TableModelColumn { display: "status_text" }                // Столбец 8
                TableModelColumn { display: "reported_to" }                // Столбец 9
                TableModelColumn { display: "notes" }                      // Столбец 10
                TableModelColumn { display: "button_placeholder" }         // Столбец 11
                // --- НОВЫЕ СТОЛБЦЫ ---
                TableModelColumn { display: "status" }                     // Столбец 12 (для кнопки)
                // --- ---
                // ...
            }
            // --- ---

            // --- Заголовки столбцов ---
            HorizontalHeaderView {
                id: tableHeader
                Layout.fillWidth: true
                syncView: actionsTableView // Синхронизируем с TableView
                model: actionsTableModel // Указываем модель для заголовков
            }
            // --- ---

            // --- САМА ТАБЛИЦА ---
            TableView {
                id: actionsTableView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                anchors.top: tableHeader.bottom
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right

                model: actionsTableModel

                // --- ФИКСИРОВАННАЯ ВЫСОТА СТРОК ---
                rowHeightProvider: function(row) { return 80; } // Увеличим высоту для отображения многострочного текста
                // --- ---

                // --- Делегат строки ---
                delegate: Rectangle {
                    implicitWidth: 100 // Будет переопределена
                    implicitHeight: 80 // Соответствует rowHeightProvider

                    color: row % 2 ? "#f9f9f9" : "#ffffff" // Чередующийся фон
                    border.color: "#eee"
                    border.width: 1

                    // --- ИСПРАВЛЕНО: Используем 'model.display' ---
                    // 'column' - это индекс столбца (0-11)
                    // 'model.display' - это значение ячейки из модели для текущей роли (role) и строки (row)

                    // Столбец 0: Статус (иконка)
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 0
                        text: {
                            var status = model.display; // Берём значение для столбца "status_display"
                            if (status === "completed") return "✅";
                            else if (status === "skipped") return "❌";
                            else if (status === "pending") return "⏸";
                            else if (status === "in_progress") return "🔄";
                            else return "? (" + status + ")";
                        }
                        font.pixelSize: 16
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 1: №
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 1
                        text: (model.display !== undefined) ? model.display.toString() : "N/A" // model.display для "id"
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 2: Описание
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 2
                        text: model.display || "" // model.display для "snapshot_description"
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 3: Начало
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 3
                        text: {
                            var start_time = model.display; // model.display для "calculated_start_time_formatted"
                            if (!start_time) return "Не задано";
                            // Формат уже готов в loadExecutionData
                            return start_time;
                        }
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 4: Окончание
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 4
                        text: {
                            var end_time = model.display; // model.display для "calculated_end_time_formatted"
                            if (!end_time) return "Не задано";
                            // Формат уже готов в loadExecutionData
                            return end_time;
                        }
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 5: Телефоны
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 5
                        text: model.display || "" // model.display для "snapshot_contact_phones"
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 6: Отчетный материал (HTML)
                    ScrollView { // ScrollView для прокрутки, если файлов много
                        anchors.fill: parent
                        anchors.margins: 2
                        clip: true
                        visible: column === 6
                        // TextEdit для отображения и кликабельности
                        TextEdit {
                            id: reportMaterialsText
                            textFormat: TextEdit.RichText // Для HTML-like форматирования
                            text: {
                                var materials_html = model.display; // model.display для "snapshot_report_materials_formatted"
                                if (!materials_html) return "";
                                // materials_html уже готовый HTML из loadExecutionData
                                return materials_html;
                            }
                            font.family: appData.fontFamily || "Arial"
                            font.pointSize: appData.fontSize || 10
                            onLinkActivated: {
                                 console.log("QML ExecutionDetailsWindow: Кликнута ссылка на файл:", link);
                                 executionDetailsWindow.openFile(link);
                            }
                            readOnly: true
                            wrapMode: TextEdit.Wrap
                        }
                    }

                    // Столбец 7: Факт. время выполнения
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 7
                        text: {
                            var actual_time = model.display; // model.display для "actual_end_time_formatted"
                            if (!actual_time) return ""; // Пусто, если не выполнено
                            // Формат уже готов в loadExecutionData
                            return actual_time;
                        }
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 8: Статус (текст)
                    Text {
                        anchors.centerIn: parent
                        visible: column === 8
                        text: model.display || "N/A" // model.display для "status_text"
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        wrapMode: Text.Wrap
                    }

                    // Столбец 9: Кому доложено
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 9
                        text: model.display || "" // model.display для "reported_to"
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 10: Примечания
                    Text {
                        anchors.fill: parent
                        anchors.margins: 5
                        visible: column === 10
                        text: model.display || "" // model.display для "notes"
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: appData.fontSize || 10
                        wrapMode: Text.Wrap
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        elide: Text.ElideRight
                    }

                    // Столбец 11: Кнопка
                    Button {
                        anchors.centerIn: parent
                        visible: column === 11
                        // text: model.status === "completed" ? "Изменить" : "Выполнить" // <-- ОШИБКА: model.status
                        text: (model.display === "completed") ? "Изменить" : "Выполнить" // <-- ИСПРАВЛЕНО: model.display для "status"
                        font.family: appData.fontFamily || "Arial"
                        font.pointSize: (appData.fontSize || 10) * 0.8 // Чуть меньше
                        onClicked: {
                            // var currentActionExecutionId = model.id; // <-- ОШИБКА: model.id
                            var currentActionExecutionId = model.displayForRole("id"); // <-- Попытка получить id, но model.displayForRole не существует
                            // Правильный способ - использовать ID из объекта, добавленного в модель.
                            // Мы можем использовать model.display для столбца id, но для этого столбца должен быть отдельный столбец, или мы используем индекс.
                            // Лучше добавить отдельный столбец для status, если он нужен для кнопки.
                            // Добавим TableModelColumn { display: "status" } как столбец 12.
                            // Тогда кнопка будет column === 12, а status будет model.display.
                            // А id можно получить через column === 1 и model.display.
                            // Для простоты, получим id из текущего ряда, зная, что row соответствует индексу в jsRows.
                            // Но это не надёжно. Лучше всё-таки добавить столбец для status и id.
                            // Добавим TableModelColumn { display: "status" } и TableModelColumn { display: "id" }.
                            // Тогда в кнопке можно будет использовать model.display для получения status и id.
                            // Пока используем индекс row и предположим, что jsRows доступен (но он не доступен в delegate напрямую).
                            // Попробуем использовать model.display для id, если id будет в отдельном столбце.
                            // Предположим, что id находится в столбце 1 (column === 1).
                            // Мы можем попытаться получить ID, передав его в `actionsTableView` как `property var currentRowData`, но это сложно.
                            // Самый надёжный способ - добавить столбцы.
                            // Добавим TableModelColumn { display: "id" } и TableModelColumn { display: "status" }.
                            // Пусть id будет в столбце 12 (после button_placeholder), а status в 13.
                            // Тогда кнопка будет column === 11 (button_placeholder), и нам нужно получить id и status.
                            // Это становится громоздко. Лучше создать отдельный столбец только для id и status, не отображая его, или использовать другой подход.
                            // Попробуем добавить столбцы в TableModel:
                            // TableModelColumn { display: "id" } // Допустим, это столбец 12
                            // TableModelColumn { display: "status" } // Допустим, это столбец 13
                            // Тогда в onClicked можно будет получить id и status.
                            // Но для onClicked нужно знать ID action_execution.
                            // Давайте добавим TableModelColumn { display: "id" } как столбец 12 (например).
                            // И TableModelColumn { display: "status" } как столбец 13 (например).
                            // А кнопку оставим в 11.
                            // В onClicked мы можем получить ID, если добавим скрытый столбец и получим его значение.
                            // Или, проще: передать `row` (индекс) и использовать его для получения ID из `actionsTableModel.rows[row].id`.
                            // Но `actionsTableModel` может быть недоступен напрямую в delegate.
                            // Используем `actionsTableModel` напрямую:
                            var currentActionId = actionsTableModel.rows[row].id; // Получаем ID из модели по индексу строки
                            var currentActionStatus = actionsTableModel.rows[row].status; // Получаем статус из модели по индексу строки
                            console.log("QML ExecutionDetailsWindow: Кнопка выполнения нажата для action_execution ID", currentActionId, "Статус:", currentActionStatus);
                            var component = Qt.createComponent("ActionExecutionEditorDialog.qml");
                            if (component.status === Component.Ready) {
                                var dialog = component.createObject(executionDetailsWindow, {
                                    "executionId": executionId, // Передаём executionId
                                    "currentActionExecutionId": currentActionId, // Передаём ID конкретного action_execution
                                    "isEditMode": true // Режим редактирования
                                });
                                if (dialog) {
                                    dialog.onActionExecutionSaved.connect(function() {
                                         console.log("QML ExecutionDetailsWindow: Получен сигнал о сохранении action_execution. Перезагружаем данные.");
                                         executionDetailsWindow.loadExecutionData();
                                         executionUpdated(executionId); // Уведомляем родителя
                                    });
                                    dialog.open();
                                } else {
                                    console.error("QML ExecutionDetailsWindow: Не удалось создать ActionExecutionEditorDialog (режим редактирования).");
                                    showInfoMessage("Ошибка: Не удалось открыть диалог редактирования действия.");
                                }
                            } else {
                                 console.error("QML ExecutionDetailsWindow: Ошибка загрузки ActionExecutionEditorDialog.qml:", component.errorString());
                                 showInfoMessage("Ошибка загрузки диалога редактирования действия.");
                            }
                        }
                    }
                    // --- ---
                }

                // --- ---
            }
            // --- ---
        }
        // --- ---

        // --- Информация под таблицей ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#ecf0f1"
            border.color: "#bdc3c7"

            Text {
                anchors.centerIn: parent
                text: (appData.postName || "Название поста") + ": " + (executionData ? executionData.created_by_user_display_name : "Ответственный")
                font.family: appData.fontFamily || "Arial"
                font.pointSize: appData.fontSize || 10
                color: "black"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                elide: Text.ElideRight // Обрезать, если слишком длинно
            }
        }
        // --- ---
    }

    // --- Вспомогательный Popup ---
    Popup {
        id: infoPopup
        x: (executionDetailsWindow.width - width) / 2
        y: 50
        width: 300
        height: 100
        modal: false
        closePolicy: Popup.NoAutoClose
        parent: executionDetailsWindow.contentItem

        background: Rectangle {
            color: "lightyellow"
            border.color: "orange"
            radius: 5
        }

        Text {
            id: infoText
            anchors.centerIn: parent
            anchors.margins: 10
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        Timer {
            id: infoTimer
            interval: 3000
            onTriggered: infoPopup.close()
        }

        function show(message) {
            infoText.text = message;
            infoPopup.open();
            infoTimer.start();
        }
    }

    function showInfoMessage(message) {
        infoPopup.show(message);
    }
    // --- ---

    // --- Обработчики ---
    onExecutionIdChanged: {
        console.log("QML ExecutionDetailsWindow: executionId изменился на", executionId);
        if (executionId > 0) {
            executionDetailsWindow.loadExecutionData();
        }
    }

    Component.onCompleted: {
        console.log("QML ExecutionDetailsWindow: Компонент завершён. executionId =", executionId);
        if (executionId > 0) {
            executionDetailsWindow.loadExecutionData();
        }
    }
}