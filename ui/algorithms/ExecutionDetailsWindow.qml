import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import QtQuick.Dialogs 6.5 // Для открытия файлов

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
    property var actionExecutionsList: [] // Список action_execution'ов

    // --- Сигналы ---
    signal executionUpdated(int executionId) // Для уведомления родителя о перезагрузке

    // --- Вспомогательные функции ---
    // Функция для открытия файла (простая реализация)
    function openFile(filePath) {
        console.log("QML ExecutionDetailsWindow: Попытка открыть файл:", filePath);
        // Для реальной реализации может потребоваться Python слот
        // или использование Qt.labs.platform.FileDialog (если доступен и для открытия внешнего файла)
        // Пока просто логируем
        if (Qt.openUrlExternally("file:///" + filePath)) {
            console.log("QML ExecutionDetailsWindow: Файл успешно открыт внешней программой:", filePath);
        } else {
            console.warn("QML ExecutionDetailsWindow: Не удалось открыть файл внешней программой:", filePath);
            // TODO: Показать сообщение пользователю
        }
    }

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
        // --- ДОБАВИМ БОЛЬШЕ ИНФОРМАЦИИ ---
        console.log("QML ExecutionDetailsWindow: Получен список action_executions (сырой):", actionsList ? JSON.stringify(actionsList).substring(0, 500) : "null/undefined");
        console.log("QML ExecutionDetailsWindow: Тип полученного списка:", typeof actionsList);
        console.log("QML ExecutionDetailsWindow: Является ли массивом (Array.isArray):", Array.isArray(actionsList));
        if (actionsList && typeof actionsList === 'object') {
            console.log("QML ExecutionDetailsWindow: Длина списка (length):", actionsList.length);
            console.log("QML ExecutionDetailsWindow: Имеет ли свойство length:", actionsList.hasOwnProperty('length'));
            console.log("QML ExecutionDetailsWindow: actionsList instanceof Array:", actionsList instanceof Array);
            console.log("QML ExecutionDetailsWindow: Object.prototype.toString.call(actionsList):", Object.prototype.toString.call(actionsList));
        }
        // --- ---

        // --- ИСПРАВЛЕНО: Проверка на "массивоподобный" объект ---
        // if (actionsList && Array.isArray(actionsList)) {
        if (actionsList && typeof actionsList === 'object' && actionsList.length !== undefined && actionsList.length >= 0) {
        // --- ---
            console.log("QML ExecutionDetailsWindow: Полученный список является массивоподобным. Количество элементов:", actionsList.length);

            if (actionsList.length === 0) {
                console.log("QML ExecutionDetailsWindow: Список action_execution'ов пуст.");
            }

            // Сортируем по calculated_start_time (если Python не отсортировал)
            // actionsList.sort(function(a, b) { ... }); // <-- Опционально, если Python уже отсортировал
            // actionExecutionsList = actionsList; // <-- Не копируем объект, а итерируемся по нему
            console.log("QML ExecutionDetailsWindow: Список action_execution'ов (из Python) загружен как массивоподобный. Количество:", actionsList.length);
        } else {
            // --- ИСПРАВЛЕНО: Сообщение об ошибке ---
            console.error("QML ExecutionDetailsWindow: Python не вернул корректный массивоподобный объект для action_executions. Получен тип:", typeof actionsList, "Значение:", actionsList);
            // --- ---
            actionExecutionsList = [];
            // Не возвращаем, пусть модель очистится и обновится пустой
        }

        // После загрузки данных, обновляем представление
        actionsModel.clear();
        // --- ИЗМЕНЕНО: Цикл для "массивоподобного" объекта ---
        // for (var i = 0; i < actionExecutionsList.length; i++) {
        //     var actionExec = actionExecutionsList[i];
        for (var i = 0; i < actionsList.length; i++) {
            var actionExec = actionsList[i]; // <-- Используем actionsList
        // --- ---
            // --- Явное копирование свойств ---
            // Это помогает избежать проблем с QJSValue/QVariantMap, которые могут
            // не сериализоваться корректно внутри ListModel.
            // Убедимся, что 'notes' включено, так как оно есть в action_executions
            var actionExecCopy = {
                "id": actionExec["id"],
                "execution_id": actionExec["execution_id"],
                "snapshot_description": actionExec["snapshot_description"] || "",
                "snapshot_contact_phones": actionExec["snapshot_contact_phones"] || "",
                "snapshot_report_materials": actionExec["snapshot_report_materials"] || "",
                "calculated_start_time": actionExec["calculated_start_time"] || "",
                "calculated_end_time": actionExec["calculated_end_time"] || "",
                "actual_end_time": actionExec["actual_end_time"] || "",
                "status": actionExec["status"] || "unknown",
                "reported_to": actionExec["reported_to"] || "",
                "notes": actionExec["notes"] || "", // <-- ДОБАВЛЕНО: Поле 'notes' для action_executions
                "created_at": actionExec["created_at"] || "",
                "updated_at": actionExec["updated_at"] || ""
            };
            // --- ---
            actionsModel.append(actionExecCopy);
            console.log("QML ExecutionDetailsWindow: Action_execution", i, "добавлен в модель (id:", actionExecCopy.id, ").");
        }
        console.log("QML ExecutionDetailsWindow: Модель ListView action_executions обновлена. Элементов:", actionsModel.count);

        // --- ДОБАВИМ ОТЛАДКУ СОДЕРЖИМОГО МОДЕЛИ ---
        if (actionsModel.count > 0) {
            try {
                console.log("QML ExecutionDetailsWindow: Первый элемент в модели (для проверки):", JSON.stringify(actionsModel.get(0)));
            } catch (e_log) {
                console.warn("QML ExecutionDetailsWindow: Не удалось залогировать первый элемент модели:", e_log.toString());
            }
        }
        // --- ---
    }

    // --- Основной контент ---
    // --- Основной контент ---
    ScrollView {
        anchors.fill: parent
        clip: true

        // Используем ColumnLayout для вертикального расположения элементов
        ColumnLayout {
            id: mainColumn
            width: executionDetailsWindow.width // Ширина соответствует окну
            // height: contentItem.implicitHeight // Высота зависит от содержимого

            // --- Заголовок ---
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: "#2c3e50"
                border.color: "#34495e"

                Text {
                    anchors.centerIn: parent
                    text: executionData ? (executionData.snapshot_name || "Без названия") + "\n" + (executionData.started_at || "Не задано") : "Загрузка..."
                    // --- Привязка шрифта ---
                    font.family: appData.fontFamily || "Arial"
                    font.pointSize: (appData.fontSize || 12) * 1.2 // Немного увеличим размер для заголовка
                    font.bold: true
                    // --- ---
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.Wrap // Перенос строк
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
                        // TODO: Открыть Popup или новое Window с диаграммой
                        showInfoMessage("Функция диаграммы в разработке.");
                    }
                }

                Item { Layout.fillWidth: true } // Заполнитель

                Button {
                    text: "Добавить действие"
                    onClicked: {
                        console.log("QML ExecutionDetailsWindow: Кнопка 'Добавить действие' нажата.");
                        // Открываем новый диалог, передав ему executionId
                        // Предполагаем, что ActionExecutionEditorDialog уже импортирован или находится в той же папке
                        // и что он принимает executionId и isEditMode
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
                                    // Уведомляем родителя
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
                            executionDetailsWindow.loadExecutionData(); // Перезагружаем
                            executionUpdated(executionId); // Уведомляем родителя
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
                        // TODO: Реализовать печать
                    }
                }

                Button {
                    text: "Закрыть"
                    onClicked: executionDetailsWindow.close()
                }
            }
            // --- ---

            // --- Таблица действий ---
            // Используем Rectangle как контейнер для ListView
            Rectangle {
                Layout.fillWidth: true
                // --- ИСПРАВЛЕНО: Не используем Layout.fillHeight: true ---
                // Layout.fillHeight: true // <-- БЫЛО: Забирает всё пространство
                Layout.preferredHeight: 400 // <-- НОВОЕ: Фиксированная высота, можно регулировать
                // Layout.maximumHeight: parent.height * 0.6 // <-- АЛЬТЕРНАТИВА: Максимум 60% от высоты родителя ScrollView
                // --- ---
                // border.color: "#bdc3c7"
                color: "white"

                // --- ДОБАВИТЬ: Видимая граница для диагностики ---
                border.width: 2
                border.color: "red" // <-- ВРЕМЕННО
                // --- ---

                // Модель для ListView
                ListModel {
                    id: actionsModel
                    // Будет заполняться в loadExecutionData
                }

                // ListView
                ListView {
                    id: actionsListView
                    anchors.fill: parent
                    anchors.margins: 5
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    // --- ДОБАВИТЬ: Видимая граница для диагностики ---
                    // background: Rectangle { border.color: "blue"; border.width: 1; color: "transparent" } // <-- УБРАНО: Нет свойства background
                    // --- ---

                    // Делегат для строки таблицы
                    delegate: Rectangle {
                        id: rowDelegate
                        width: actionsListView.width // Ширина равна ширине ListView
                        height: 60 // Высота строки
                        // Цвет фона для наглядности
                        color: index % 2 ? "#f0f0f0" : "#ffffff" // Чередующийся фон
                        border.color: "#ccc"
                        border.width: 1

                        // Просто текст с ID и описанием
                        Text {
                            anchors.centerIn: parent
                            text: "ID: " + model.id + ", Действие: " + model.snapshot_description
                            font.family: appData.fontFamily || "Arial"
                            font.pointSize: appData.fontSize || 10
                            color: "black"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    // delegate: Rectangle {
                    //     id: rowDelegate
                    //     width: actionsListView.width
                    //     height: 60 // Фиксированная высота строки, можно регулировать
                    //     color: index % 2 ? "#f9f9f9" : "#ffffff" // Чередующийся фон
                    //     border.color: "#eee"

                    //     // Горизонтальное расположение ячеек
                    //     RowLayout {
                    //         anchors.fill: parent
                    //         anchors.margins: 1 // Отступы внутри строки
                    //         spacing: 1 // Отступы между ячейками

                    //         // ... (ваш код ячеек без изменений) ...
                    //         // --- Ячейка 1: Статус ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.04 // ~4% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.centerIn: parent
                    //                 text: {
                    //                     if (model.status === "completed") return "✅";
                    //                     else if (model.status === "skipped") return "❌";
                    //                     else return "⏸"; // pending, in_progress
                    //                 }
                    //                 font.pixelSize: 16
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 2: № ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.03 // ~3% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.centerIn: parent
                    //                 text: (index + 1).toString() // Номер по порядку
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 3: Описание ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.18 // ~18% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.fill: parent
                    //                 anchors.margins: 5
                    //                 text: model.snapshot_description || ""
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 wrapMode: Text.Wrap // Перенос
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 4: Начало ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.08 // ~8% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.fill: parent
                    //                 anchors.margins: 5
                    //                 text: {
                    //                     var start_time = model.calculated_start_time;
                    //                     if (!start_time) return "Не задано";
                    //                     // Попробуем распарсить и отформатировать
                    //                     var dateObj = new Date(start_time);
                    //                     if (isNaN(dateObj.getTime())) {
                    //                         // Если парсинг не удался, выводим как есть
                    //                         return start_time;
                    //                     }
                    //                     // Формат: "HH:MM\nDD.MM"
                    //                     var timeStr = dateObj.toLocaleTimeString(Qt.locale(), "HH:mm");
                    //                     var dateStr = dateObj.toLocaleDateString(Qt.locale(), "dd.MM");
                    //                     return timeStr + "\n" + dateStr;
                    //                 }
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 wrapMode: Text.Wrap // Перенос
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 5: Окончание ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.08 // ~8% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.fill: parent
                    //                 anchors.margins: 5
                    //                 text: {
                    //                     var end_time = model.calculated_end_time;
                    //                     if (!end_time) return "Не задано";
                    //                     var dateObj = new Date(end_time);
                    //                     if (isNaN(dateObj.getTime())) {
                    //                         return end_time;
                    //                     }
                    //                     var timeStr = dateObj.toLocaleTimeString(Qt.locale(), "HH:mm");
                    //                     var dateStr = dateObj.toLocaleDateString(Qt.locale(), "dd.MM");
                    //                     return timeStr + "\n" + dateStr;
                    //                 }
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 wrapMode: Text.Wrap
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 6: Телефоны ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.08 // ~8% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.fill: parent
                    //                 anchors.margins: 5
                    //                 text: model.snapshot_contact_phones || ""
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 wrapMode: Text.Wrap
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 7: Отчетный материал ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.10 // ~10% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             ScrollView { // ScrollView для прокрутки, если файлов много
                    //                 anchors.fill: parent
                    //                 anchors.margins: 2
                    //                 clip: true
                    //                 // Text для отображения и кликабельности
                    //                 TextEdit { // Используем TextEdit для гиперссылок
                    //                     id: reportMaterialsText
                    //                     textFormat: TextEdit.RichText // Для HTML-like форматирования
                    //                     text: {
                    //                         var materials = model.snapshot_report_materials || "";
                    //                         if (!materials) return "";
                    //                         // Разбиваем по новым строкам или другим разделителям
                    //                         var paths = materials.split('\n'); // Или split(';') или split(',') в зависимости от хранения
                    //                         var html = "";
                    //                         for (var i = 0; i < paths.length; i++) {
                    //                             var path = paths[i].trim();
                    //                             if (path) {
                    //                                 // Убираем file:/// префикс, если он есть
                    //                                 if (path.startsWith("file:///")) {
                    //                                     path = path.substring(8);
                    //                                 }
                    //                                 // Создаём кликабельную ссылку
                    //                                 html += "<a href=\"" + path + "\">" + Qt.escape(path) + "</a><br/>";
                    //                             }
                    //                         }
                    //                         return html;
                    //                     }
                    //                     // --- Привязка шрифта ---
                    //                     font.family: appData.fontFamily || "Arial"
                    //                     font.pointSize: appData.fontSize || 10
                    //                     // --- ---
                    //                     onLinkActivated: {
                    //                          console.log("QML ExecutionDetailsWindow: Кликнута ссылка на файл:", link);
                    //                          executionDetailsWindow.openFile(link);
                    //                     }
                    //                     readOnly: true
                    //                     wrapMode: TextEdit.Wrap
                    //                     // horizontalAlignment: TextEdit.AlignHCenter // Не работает для RichText
                    //                     // verticalAlignment: TextEdit.AlignVCenter // Не работает для RichText
                    //                 }
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 8: Факт. время выполнения ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.08 // ~8% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.fill: parent
                    //                 anchors.margins: 5
                    //                 text: {
                    //                     var actual_time = model.actual_end_time;
                    //                     if (!actual_time) return ""; // Пусто, если не выполнено
                    //                     var dateObj = new Date(actual_time);
                    //                     if (isNaN(dateObj.getTime())) {
                    //                         return actual_time;
                    //                     }
                    //                     var timeStr = dateObj.toLocaleTimeString(Qt.locale(), "HH:mm");
                    //                     var dateStr = dateObj.toLocaleDateString(Qt.locale(), "dd.MM");
                    //                     return timeStr + "\n" + dateStr;
                    //                 }
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 wrapMode: Text.Wrap
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 9: Статус ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.07 // ~7% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.centerIn: parent
                    //                 text: {
                    //                     if (model.status === "completed") return "Выполнено";
                    //                     else if (model.status === "pending") return "Ожидает";
                    //                     else if (model.status === "in_progress") return "В процессе";
                    //                     else if (model.status === "skipped") return "Пропущено";
                    //                     else return model.status; // На всякий случай
                    //                 }
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //                 wrapMode: Text.Wrap
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 10: Кому доложено ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.08 // ~8% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Text {
                    //                 anchors.fill: parent
                    //                 anchors.margins: 5
                    //                 text: model.reported_to || ""
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: appData.fontSize || 10
                    //                 // --- ---
                    //                 wrapMode: Text.Wrap
                    //                 horizontalAlignment: Text.AlignHCenter
                    //                 verticalAlignment: Text.AlignVCenter
                    //             }
                    //         }
                    //         // --- ---

                    //         // --- Ячейка 11: Кнопка ---
                    //         Rectangle {
                    //             Layout.preferredWidth: parent.width * 0.07 // ~7% ширины
                    //             Layout.fillHeight: true
                    //             color: "transparent"
                    //             border.color: "#ccc"
                    //             Button {
                    //                 anchors.centerIn: parent
                    //                 text: model.status === "completed" ? "Изменить" : "Выполнить"
                    //                 // --- Привязка шрифта ---
                    //                 font.family: appData.fontFamily || "Arial"
                    //                 font.pointSize: (appData.fontSize || 10) * 0.8 // Чуть меньше
                    //                 // --- ---
                    //                 onClicked: {
                    //                     console.log("QML ExecutionDetailsWindow: Кнопка выполнения нажата для action_execution ID", model.id);
                    //                     // Открываем диалог редактирования action_execution
                    //                     var component = Qt.createComponent("ActionExecutionEditorDialog.qml");
                    //                     if (component.status === Component.Ready) {
                    //                         var dialog = component.createObject(executionDetailsWindow, {
                    //                             "executionId": executionId, // Передаём executionId
                    //                             "currentActionExecutionId": model.id, // Передаём ID конкретного action_execution
                    //                             "isEditMode": true // Режим редактирования
                    //                         });
                    //                         if (dialog) {
                    //                             dialog.onActionExecutionSaved.connect(function() {
                    //                                  console.log("QML ExecutionDetailsWindow: Получен сигнал о сохранении action_execution. Перезагружаем данные.");
                    //                                  executionDetailsWindow.loadExecutionData();
                    //                                  executionUpdated(executionId); // Уведомляем родителя
                    //                             });
                    //                             dialog.open();
                    //                         } else {
                    //                             console.error("QML ExecutionDetailsWindow: Не удалось создать ActionExecutionEditorDialog (режим редактирования).");
                    //                             showInfoMessage("Ошибка: Не удалось открыть диалог редактирования действия.");
                    //                         }
                    //                     } else {
                    //                          console.error("QML ExecutionDetailsWindow: Ошибка загрузки ActionExecutionEditorDialog.qml:", component.errorString());
                    //                          showInfoMessage("Ошибка загрузки диалога редактирования действия.");
                    //                     }
                    //                 }
                    //             }
                    //         }
                    //         // --- ---
                    //     }
                    // }

                    // Заголовки столбцов (реализация может быть сложнее, чем здесь)
                    header: Rectangle {
                        width: actionsListView.width
                        height: 30
                        color: "#e0e0e0"
                        border.color: "#ccc"
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 1
                            spacing: 1

                            Repeater {
                                model: [
                                    { width: 0.04, text: "Статус" },
                                    { width: 0.03, text: "№" },
                                    { width: 0.18, text: "Действие" },
                                    { width: 0.08, text: "Начало" },
                                    { width: 0.08, text: "Окончание" },
                                    { width: 0.08, text: "Телефоны" },
                                    { width: 0.10, text: "Отчет" },
                                    { width: 0.08, text: "Выполнено" },
                                    { width: 0.07, text: "Статус" },
                                    { width: 0.08, text: "Кому" },
                                    { width: 0.07, text: "Действие" }
                                ]
                                Rectangle {
                                    Layout.preferredWidth: parent.width * modelData.width
                                    Layout.fillHeight: true
                                    color: "transparent"
                                    border.color: "#ccc"
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.text
                                        font.bold: true
                                        // --- Привязка шрифта ---
                                        font.family: appData.fontFamily || "Arial"
                                        font.pointSize: (appData.fontSize || 10) * 0.9
                                        // --- ---
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }
                }
            }
            // --- ---

            // --- Информация под таблицей ---
            Rectangle { // <-- ВЕРНЁМ Layout.fillWidth: true
                Layout.fillWidth: true // <-- БЫЛО false, стало true
                Layout.preferredHeight: 40
                color: "#ecf0f1"
                border.color: "#bdc3c7"

                Text {
                    anchors.centerIn: parent
                    text: (appData.postName || "Название поста") + ": " + (executionData ? executionData.created_by_user_display_name : "Ответственный")
                    // --- Привязка шрифта ---
                    font.family: appData.fontFamily || "Arial"
                    font.pointSize: appData.fontSize || 10
                    // --- ---
                    color: "black"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight // Обрезать, если слишком длинно
                }
            }
            // --- ---
        }
    }

    // --- Вспомогательный компонент для показа сообщений ---
    // Это может быть MessageDialog, или просто Text, показываемый на короткое время
    // Пока используем простой Popup
    Popup {
        id: infoPopup
        x: (executionDetailsWindow.width - width) / 2
        y: 50
        width: 300
        height: 100
        modal: false // Не модальный, чтобы не блокировать окно
        closePolicy: Popup.NoAutoClose // Не закрывать автоматически
        parent: executionDetailsWindow.contentItem // Привязываем к содержимому окна

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
            interval: 3000 // 3 секунды
            onTriggered: infoPopup.close()
        }

        function show(message) {
            infoText.text = message;
            infoPopup.open();
            infoTimer.start(); // Запускаем таймер
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
        // Загрузка происходит при изменении executionId, но можно вызвать и здесь,
        // если executionId уже задан при создании.
        if (executionId > 0) {
            executionDetailsWindow.loadExecutionData();
        }
    }
}