// ui/algorithms/RunningAlgorithmsView.qml
// --- ДОБАВИТЬ ЭТИ ИМПОРТЫ В НАЧАЛО ФАЙЛА ---
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import QtQuick.Window 6.5 // <-- ДОБАВИТЬ ЭТОТ ИМПОРТ (для Window.window.scaleFactor)
import "." // <-- НОВОЕ: Для импорта ExecutionDetailsWindow.qml
// --- ---

Item {
    id: runningAlgorithmsViewRoot

    // --- Свойства ---
    property string categoryFilter: "" // Фильтр по категории алгоритмов
    property string selectedHistoryDate: appData.localDate // <-- НОВОЕ: Выбранная дата для истории (по умолчанию местная дата)
    property bool isHistoryExpanded: false // <-- НОВОЕ: Состояние свёрнутости/развёрнутости истории
    // --- ---

    // --- Сигналы ---
    signal startNewAlgorithmRequested(string category)
    signal finishAlgorithmRequested(int executionId)
    signal expandAlgorithmRequested(int executionId)
    // --- ---

    // --- Модели данных ---
    ListModel {
        id: executionsModel // Для активных (запущенных) алгоритмов
    }
    ListModel {
        id: completedExecutionsModel // <-- НОВАЯ МОДЕЛЬ: Для завершённых алгоритмов
    }
    // --- ---

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // --- Панель инструментов ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Button {
                text: "Запустить новый алгоритм"
                onClicked: runningAlgorithmsViewRoot.startNewAlgorithmRequested(categoryFilter)
            }

            Item {
                Layout.fillWidth: true // Заполнитель
            }
        }
        // --- ---

        // --- Список запущенных алгоритмов ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: executionsListView
                model: executionsModel
                spacing: 8 // Небольшой отступ между элементами

                delegate: Rectangle {
                    width: ListView.view.width
                    height: activeContentColumn.implicitHeight + 2 * padding // Высота зависит от содержимого
                    property int padding: 10

                    // --- Визуальные стили в зависимости от статуса ---
                    color: {
                        switch(model.status) {
                            case "active": return "#e8f4fd"; // Светло-голубой для активных
                            case "completed": return "#e8f5e9"; // Светло-зелёный для завершённых
                            case "cancelled": return "#ffebee"; // Светло-красный для отменённых
                            default: return index % 2 ? "#f9f9f9" : "#ffffff"; // Стандартный чередующийся
                        }
                    }
                    border.color: executionsListView.currentIndex === index ? "#3498db" : "#ddd"
                    border.width: 1
                    radius: 5
                    // --- ---

                    // Используем ColumnLayout для вертикального размещения элементов
                    ColumnLayout {
                        id: activeContentColumn
                        anchors.fill: parent
                        anchors.margins: padding // Отступы внутри элемента
                        spacing: 6

                        // Название алгоритма (жирный шрифт)
                        Text {
                            Layout.fillWidth: true
                            text: model.algorithm_name || "Без названия"
                            font.bold: true
                            // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                            font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 12
                            // --- ---
                            elide: Text.ElideRight
                            color: "black"
                        }

                        // Ответственный
                        Text {
                            Layout.fillWidth: true
                            text: "Ответственный: " + (model.created_by_user_display_name || "Не назначен")
                            color: "gray"
                            // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                            font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                            // --- ---
                            elide: Text.ElideRight
                        }

                        // Статус и время (в одной строке)
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Статус
                            Rectangle {
                                Layout.preferredWidth: 100 // Фиксированная ширина для статуса
                                Layout.preferredHeight: 20
                                radius: 3
                                color: {
                                    switch(model.status) {
                                        case "active": return "#3498db";
                                        case "completed": return "#2ecc71";
                                        case "cancelled": return "#e74c3c";
                                        default: return "#95a5a6";
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: model.status || "неизвестен"
                                    color: "white"
                                    // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                    font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 9
                                    // --- ---
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true } // Заполнитель

                            // Время начала
                            Text {
                                text: "Начат: " + (model.started_at || "—")
                                color: "gray"
                                // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                                // --- ---
                                elide: Text.ElideRight
                            }
                        }

                        // Кнопки управления (размещаем в RowLayout, прижатом к правому краю)
                        RowLayout {
                            Layout.alignment: Qt.AlignRight // Выравнивание кнопок по правому краю
                            spacing: 8 // Немного больше отступа между кнопками

                            Button {
                                text: "Завершить"
                                // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                                // --- ---
                                // Включаем только если статус 'active'
                                enabled: model.status === "active"
                                onClicked: {
                                    console.log("QML RunningAlgorithmsView: Запрошено завершение execution ID:", model.id);
                                    var success = appData.stopAlgorithm(model.id);
                                    if (success) {
                                        console.log("QML RunningAlgorithmsView: Execution ID", model.id, "успешно отмечен как завершённый.");
                                        runningAlgorithmsViewRoot.loadExecutions(); // Перезагрузим список для обновления статуса
                                    } else {
                                        console.warn("QML RunningAlgorithmsView: Не удалось завершить execution ID", model.id);
                                        // TODO: Показать сообщение об ошибке пользователю
                                    }
                                }
                            }

                            Button {
                                text: "Развернуть"
                                // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                                // --- ---
                                onClicked: {
                                    console.log("QML RunningAlgorithmsView: Запрошено развертывание execution ID:", model.id);
                                    // --- НОВОЕ: Открытие ExecutionDetailsWindow ---
                                    // Проверяем, что ExecutionDetailsWindow.qml существует
                                    var component = Qt.createComponent("ExecutionDetailsWindow.qml");
                                    if (component.status === Component.Ready) {
                                        // Создаём новое окно
                                        var detailsWindow = component.createObject(runningAlgorithmsViewRoot, {
                                            "executionId": model.id // Передаём ID execution'а
                                        });
                                        if (detailsWindow) {
                                            detailsWindow.show(); // Открываем окно
                                            console.log("QML RunningAlgorithmsView: ExecutionDetailsWindow открыто для execution ID", model.id);
                                        } else {
                                            console.error("QML RunningAlgorithmsView: Не удалось создать объект ExecutionDetailsWindow.qml.");
                                            // TODO: Показать сообщение пользователю
                                        }
                                    } else {
                                        console.error("QML RunningAlgorithmsView: Ошибка загрузки ExecutionDetailsWindow.qml:", component.errorString());
                                        // TODO: Показать сообщение пользователю
                                    }
                                    // --- ---
                                }
                            }
                        }
                    }
                }

                // Индикатор загрузки или пустого списка
                header: Item {
                    width: ListView.view.width
                    height: 40 // Высота заголовка/индикатора
                    visible: executionsModel.count === 0

                    Text {
                        anchors.centerIn: parent
                        text: categoryFilter ? "Нет запущенных алгоритмов" : "Выберите категорию"
                        color: "gray"
                        font.italic: true
                        // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                        font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 12
                        // --- ---
                    }
                }
            }
        }
        // --- ---

        // --- НОВОЕ: Разделитель перед историей ---
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: "#bdc3c7"
            visible: completedExecutionsModel.count > 0 || isHistoryExpanded // Показываем, если есть данные или раздел развёрнут
        }
        // --- ---

        // --- НОВОЕ: Заголовок и элементы управления для истории ---
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            // Заголовок
            Label {
                text: "Завершённые алгоритмы"
                // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                font.pointSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 12
                // --- ---
                font.bold: true
            }

            // Кнопка свернуть/развернуть
            Button {
                text: runningAlgorithmsViewRoot.isHistoryExpanded ? "▼" : "▲"
                // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                // --- ---
                onClicked: {
                    console.log("QML RunningAlgorithmsView: Переключение состояния истории (свёрнута/развёрнута).");
                    runningAlgorithmsViewRoot.isHistoryExpanded = !runningAlgorithmsViewRoot.isHistoryExpanded;
                    // При разворачивании можно перезагрузить данные, если нужно
                    if (runningAlgorithmsViewRoot.isHistoryExpanded) {
                         console.log("QML RunningAlgorithmsView: История развернута. Загрузка данных...");
                         runningAlgorithmsViewRoot.loadCompletedExecutions(); // Перезагружаем, на случай если дата изменилась
                    } else {
                         console.log("QML RunningAlgorithmsView: История свёрнута.");
                    }
                }
            }

            Item { Layout.fillWidth: true } // Заполнитель

            // Выбор даты
            Label {
                text: "Дата:"
            }
            TextField {
                id: historyDateField // <-- НОВОЕ: Поле для ввода/отображения даты истории
                Layout.preferredWidth: 100
                text: runningAlgorithmsViewRoot.selectedHistoryDate // <-- Привязка к свойству
                placeholderText: "ДД.ММ.ГГГГ"
                // validator: RegExpValidator { regExp: /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d$/ }
                onEditingFinished: {
                    // Проверяем валидность введённой даты
                    if (acceptableInput) {
                        console.log("QML RunningAlgorithmsView: Ввод даты истории завершён. Новая дата:", text);
                        if (text !== runningAlgorithmsViewRoot.selectedHistoryDate) {
                             runningAlgorithmsViewRoot.selectedHistoryDate = text;
                             console.log("QML RunningAlgorithmsView: Дата истории изменена. Перезагрузка завершённых алгоритмов...");
                             runningAlgorithmsViewRoot.loadCompletedExecutions();
                        }
                    } else {
                        console.warn("QML RunningAlgorithmsView: Введена некорректная дата для истории:", text);
                        // Можно показать сообщение об ошибке или сбросить значение
                        // historyDateField.text = runningAlgorithmsViewRoot.selectedHistoryDate; // Это может вызвать зацикливание
                    }
                }
            }

            // Кнопка календаря
            Button {
                text: "📅"
                font.pixelSize: 16
                Layout.preferredWidth: 40
                onClicked: {
                    console.log("QML RunningAlgorithmsView: Нажата кнопка календаря для выбора даты истории.");
                    // --- НОВОЕ: Открываем собственный календарь для выбора даты истории ---
                    // Пытаемся установить начальную дату в календаре
                    var currentDateText = runningAlgorithmsViewRoot.selectedHistoryDate.trim();
                    var dateRegex = /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d$/;
                    if (dateRegex.test(currentDateText)) {
                        // Пытаемся распарсить дату из поля ввода
                        var parts = currentDateText.split('.');
                        var day = parseInt(parts[0], 10);
                        var month = parseInt(parts[1], 10) - 1; // Месяцы в JS Date от 0 до 11
                        var year = parseInt(parts[2], 10);
                        // Проверяем, является ли распарсенная дата валидной
                        var testDate = new Date(year, month, day);
                        if (testDate.getDate() === day && testDate.getMonth() === month && testDate.getFullYear() === year) {
                            historyCalendarPicker.selectedDate = testDate;
                            console.log("QML RunningAlgorithmsView: History CalendarPicker инициализирован датой из поля:", testDate);
                        } else {
                            // Если дата некорректна, используем текущую
                            historyCalendarPicker.selectedDate = new Date();
                            console.log("QML RunningAlgorithmsView: History CalendarPicker инициализирован текущей датой (некорректная дата в поле).");
                        }
                    } else {
                        // Если формат не совпадает, используем текущую дату
                        historyCalendarPicker.selectedDate = new Date();
                        console.log("QML RunningAlgorithmsView: History CalendarPicker инициализирован текущей датой (некорректный формат в поле).");
                    }
                    
                    // --- Подключаем обработчик onDateSelected ---
                    // Используем Connections, чтобы избежать дублирования обработчиков
                    var calendarConnection = Qt.createQmlObject('
                        import QtQuick 6.5;
                        Connections {
                            target: historyCalendarPicker;
                            function onDateSelected(date) {
                                console.log("QML RunningAlgorithmsView: History CalendarPicker: Дата выбрана:", date);
                                // Форматируем выбранную дату в строку DD.MM.YYYY
                                var year = date.getFullYear();
                                var month = String(date.getMonth() + 1).padStart(2, "0"); // Месяцы с 0
                                var day = String(date.getDate()).padStart(2, "0");
                                var formattedDate = day + "." + month + "." + year;
                                console.log("QML RunningAlgorithmsView: History CalendarPicker: Отформатированная дата:", formattedDate);
                                // Устанавливаем выбранную дату в свойство
                                runningAlgorithmsViewRoot.selectedHistoryDate = formattedDate;
                                // Перезагружаем список завершённых алгоритмов
                                runningAlgorithmsViewRoot.loadCompletedExecutions();
                                // Отключаем этот обработчик, чтобы избежать утечек
                                calendarConnection.destroy();
                            }
                        }
                    ', runningAlgorithmsViewRoot, "calendarConnection");
                    // --- ---
                    
                    historyCalendarPicker.open();
                    // --- ---
                }
            }
        }
        // --- ---

        // --- НОВОЕ: Список завершённых алгоритмов (виден только если isHistoryExpanded) ---
        ScrollView {
            Layout.fillWidth: true
            // --- ИСПРАВЛЕНО: Логика высоты для плавного сворачивания/разворачивания ---
            Layout.preferredHeight: runningAlgorithmsViewRoot.isHistoryExpanded ? implicitHeight : 0
            Layout.maximumHeight: runningAlgorithmsViewRoot.isHistoryExpanded ? 300 : 0
            // --- ---
            clip: true
            // --- ИСПРАВЛЕНО: Видимость также зависит от isHistoryExpanded ---
            visible: runningAlgorithmsViewRoot.isHistoryExpanded
            // --- ---

            ListView {
                id: completedExecutionsListView
                model: completedExecutionsModel
                spacing: 8 // Небольшой отступ между элементами
                delegate: Rectangle {
                    width: ListView.view.width
                    height: completedContentColumn.implicitHeight + 2 * padding // Высота зависит от содержимого
                    property int padding: 10

                    // --- Визуальные стили для завершённых ---
                    color: {
                        switch(model.status) {
                            case "completed": return "#e8f5e9"; // Светло-зелёный для завершённых
                            case "cancelled": return "#ffebee"; // Светло-красный для отменённых
                            default: return index % 2 ? "#f9f9f9" : "#ffffff"; // Стандартный чередующийся
                        }
                    }
                    border.color: completedExecutionsListView.currentIndex === index ? "#3498db" : "#ddd"
                    border.width: 1
                    radius: 5
                    // --- ---

                    ColumnLayout {
                        id: completedContentColumn
                        anchors.fill: parent
                        anchors.margins: padding
                        spacing: 6

                        // Название алгоритма
                        Text {
                            Layout.fillWidth: true
                            text: model.algorithm_name || "Без названия"
                            font.bold: true
                            // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                            font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 12
                            // --- ---
                            elide: Text.ElideRight
                            color: "black"
                        }

                        // Ответственный
                        Text {
                            Layout.fillWidth: true
                            text: "Ответственный: " + (model.created_by_user_display_name || "Не назначен")
                            color: "gray"
                            // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                            font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                            // --- ---
                            elide: Text.ElideRight
                        }

                        // Статус и время
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            // Статус
                            Rectangle {
                                Layout.preferredWidth: 100
                                Layout.preferredHeight: 20
                                radius: 3
                                color: {
                                    switch(model.status) {
                                        case "completed": return "#2ecc71";
                                        case "cancelled": return "#e74c3c";
                                        default: return "#95a5a6";
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    text: model.status || "неизвестен"
                                    color: "white"
                                    // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                    font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 9
                                    // --- ---
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true }

                            // Время начала и окончания
                            ColumnLayout {
                                spacing: 2
                                Text {
                                    text: "Начат: " + (model.started_at_display || "—")
                                    color: "gray"
                                    // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                    font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                                    // --- ---
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: "Завершён: " + (model.completed_at_display || "—")
                                    color: "gray"
                                    // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                    font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                                    // --- ---
                                    elide: Text.ElideRight
                                }
                            }
                        }

                        // Кнопки управления (например, "Развернуть")
                        RowLayout {
                            Layout.alignment: Qt.AlignRight
                            spacing: 8

                            Button {
                                text: "Развернуть"
                                // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                                font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 10
                                // --- ---
                                onClicked: {
                                    console.log("QML RunningAlgorithmsView: Запрошено развертывание завершённого execution ID:", model.id);
                                    var component = Qt.createComponent("ExecutionDetailsWindow.qml");
                                    if (component.status === Component.Ready) {
                                        var detailsWindow = component.createObject(runningAlgorithmsViewRoot, {
                                            "executionId": model.id
                                        });
                                        if (detailsWindow) {
                                            detailsWindow.show();
                                            console.log("QML RunningAlgorithmsView: ExecutionDetailsWindow открыто для завершённого execution ID", model.id);
                                        } else {
                                            console.error("QML RunningAlgorithmsView: Не удалось создать объект ExecutionDetailsWindow.qml.");
                                        }
                                    } else {
                                        console.error("QML RunningAlgorithmsView: Ошибка загрузки ExecutionDetailsWindow.qml:", component.errorString());
                                    }
                                }
                            }
                            // Можно добавить другие кнопки, например, "Печать отчёта"
                        }
                    }
                }

                // Индикатор загрузки или пустого списка
                header: Item {
                    width: ListView.view.width
                    height: 40
                    visible: completedExecutionsModel.count === 0 && runningAlgorithmsViewRoot.isHistoryExpanded

                    Text {
                        anchors.centerIn: parent
                        text: "Нет завершённых алгоритмов за " + runningAlgorithmsViewRoot.selectedHistoryDate
                        color: "gray"
                        font.italic: true
                        // --- ИСПРАВЛЕНО: Используем scaleFactor из Window ---
                        font.pixelSize: (Window.window && Window.window.scaleFactor ? Window.window.scaleFactor : 1) * 12
                        // --- ---
                    }
                }
            }
        }
        // --- ---
    }

    // --- Загрузка при изменении categoryFilter ---
    onCategoryFilterChanged: {
        console.log("QML RunningAlgorithmsView: categoryFilter изменился на:", categoryFilter);
        runningAlgorithmsViewRoot.loadExecutions();
    }

    Component.onCompleted: {
        console.log("QML RunningAlgorithmsView: Загружен. Категория:", categoryFilter);
        if (categoryFilter && categoryFilter !== "") {
            runningAlgorithmsViewRoot.loadExecutions();
        }
    }

    /**
     * Загружает список завершённых алгоритмов для заданной категории и даты
     */
    function loadCompletedExecutions() {
        if (!categoryFilter || categoryFilter === "") {
            console.warn("QML RunningAlgorithmsView: categoryFilter не задан для загрузки завершённых, пропускаем.");
            completedExecutionsModel.clear();
            return;
        }
        if (!selectedHistoryDate || selectedHistoryDate === "") {
             console.warn("QML RunningAlgorithmsView: selectedHistoryDate не задана для загрузки завершённых, пропускаем.");
             completedExecutionsModel.clear();
             return;
        }

        console.log("QML RunningAlgorithmsView: Запрос списка завершённых executions для категории:", categoryFilter, "и даты:", selectedHistoryDate);
        // Предполагаем, что в ApplicationData есть метод getCompletedExecutionsByCategoryAndDate
        // который возвращает список завершённых execution'ов за конкретную дату.
        var completedList = appData.getCompletedExecutionsByCategoryAndDate(categoryFilter, selectedHistoryDate);
        console.log("QML RunningAlgorithmsView: Получен список завершённых executions из Python (сырой):", JSON.stringify(completedList).substring(0, 500));

        // Преобразование QJSValue/QVariant в массив JS
        if (completedList && typeof completedList === 'object' && typeof completedList.hasOwnProperty === 'function' && completedList.hasOwnProperty('toVariant')) {
            console.log("QML RunningAlgorithmsView: Обнаружен QJSValue, преобразование в JS-объект...");
            completedList = completedList.toVariant();
            console.log("QML RunningAlgorithmsView: QJSValue (completedList) преобразован в:", JSON.stringify(completedList).substring(0, 500));
        } else {
            console.log("QML RunningAlgorithmsView: Преобразование QJSValue не требуется.");
        }

        // Очистка модели
        console.log("QML RunningAlgorithmsView: Очистка модели ListView завершённых executions...");
        completedExecutionsModel.clear();

        // Заполнение модели
        if (completedList && typeof completedList === 'object' && completedList.length !== undefined) {
            var count = completedList.length;
            console.log("QML RunningAlgorithmsView: Полученный список завершённых является массивоподобным. Количество элементов:", count);

            for (var i = 0; i < count; i++) {
                var execution = completedList[i];
                console.log("QML RunningAlgorithmsView: Обрабатываем завершённый execution", i, ":", JSON.stringify(execution).substring(0, 200));

                if (typeof execution === 'object' && execution !== null) {
                    try {
                        // --- Явное копирование свойств ---
                        var executionCopy = {
                            "id": execution["id"],
                            "algorithm_id": execution["algorithm_id"],
                            "algorithm_name": execution["algorithm_name"] || "",
                            "category": execution["category"] || "",
                            "started_at": execution["started_at"] || "",
                            "started_at_display": execution["started_at_display"] || "", // <-- НОВОЕ: Отформатированное время начала
                            "completed_at": execution["completed_at"] || "",
                            "completed_at_display": execution["completed_at_display"] || "", // <-- НОВОЕ: Отформатированное время окончания
                            "status": execution["status"] || "unknown",
                            "created_by_user_id": execution["created_by_user_id"] || null,
                            "created_by_user_display_name": execution["created_by_user_display_name"] || "Неизвестен"
                        };
                        // --- ---
                        completedExecutionsModel.append(executionCopy);
                        console.log("QML RunningAlgorithmsView: Завершённый execution", i, "добавлен в модель.");
                    } catch (e_append) {
                        console.error("QML RunningAlgorithmsView: Ошибка при добавлении завершённого execution", i, "в модель:", e_append.toString(), "Данные:", JSON.stringify(execution));
                    }
                } else {
                    console.warn("QML RunningAlgorithmsView: Завершённый execution", i, "не является корректным объектом:", typeof execution, execution);
                }
            }
        } else {
            console.error("QML RunningAlgorithmsView: Python не вернул корректный массивоподобный объект для завершённых executions. Получен тип:", typeof completedList, "Значение:", completedList);
        }
        console.log("QML RunningAlgorithmsView: Модель ListView завершённых executions обновлена. Элементов:", completedExecutionsModel.count);
    }

    /**
     * Загружает список запущенных алгоритмов для заданной категории
     * И также загружает завершённые алгоритмы за выбранную дату
     */
    function loadExecutions() {
        if (!categoryFilter || categoryFilter === "") {
            console.warn("QML RunningAlgorithmsView: categoryFilter не задан, пропускаем загрузку.");
            executionsModel.clear();
            // --- НОВОЕ: Также очищаем завершённые ---
            completedExecutionsModel.clear();
            // --- ---
            return;
        }

        console.log("QML RunningAlgorithmsView: Запрос списка активных executions для категории:", categoryFilter);
        var executionsList = appData.getActiveExecutionsByCategory(categoryFilter);
        console.log("QML RunningAlgorithmsView: Получен список активных executions из Python (сырой):", JSON.stringify(executionsList).substring(0, 500));

        // Преобразование QJSValue/QVariant в массив JS
        if (executionsList && typeof executionsList === 'object' && typeof executionsList.hasOwnProperty === 'function' && executionsList.hasOwnProperty('toVariant')) {
            console.log("QML RunningAlgorithmsView: Обнаружен QJSValue, преобразование в JS-объект...");
            executionsList = executionsList.toVariant();
            console.log("QML RunningAlgorithmsView: QJSValue (executionsList) преобразован в:", JSON.stringify(executionsList).substring(0, 500));
        } else {
            console.log("QML RunningAlgorithmsView: Преобразование QJSValue не требуется.");
        }

        // Очистка модели активных
        console.log("QML RunningAlgorithmsView: Очистка модели ListView executions...");
        executionsModel.clear();

        // Заполнение модели активных
        if (executionsList && typeof executionsList === 'object' && executionsList.length !== undefined) {
            var count = executionsList.length;
            console.log("QML RunningAlgorithmsView: Полученный список является массивоподобным. Количество элементов:", count);

            for (var i = 0; i < count; i++) {
                var execution = executionsList[i];
                console.log("QML RunningAlgorithmsView: Обрабатываем execution", i, ":", JSON.stringify(execution).substring(0, 200));

                if (typeof execution === 'object' && execution !== null) {
                    try {
                        var executionCopy = {
                            "id": execution["id"],
                            "algorithm_id": execution["algorithm_id"],
                            "algorithm_name": execution["algorithm_name"] || "",
                            "category": execution["category"] || "",
                            // --- ИЗМЕНЕНО: Используем started_at_display ---
                            // "started_at": execution["started_at"] || "", // <-- СТАРОЕ
                            "started_at": execution["started_at_display"] || execution["started_at"] || "", // <-- НОВОЕ: Приоритет у отформатированного
                            // --- ---
                            "completed_at": execution["completed_at"] || "",
                            "status": execution["status"] || "unknown",
                            "created_by_user_id": execution["created_by_user_id"] || null,
                            "created_by_user_display_name": execution["created_by_user_display_name"] || "Неизвестен"
                        };
                        executionsModel.append(executionCopy);
                        console.log("QML RunningAlgorithmsView: Execution", i, "добавлен в модель.");
                    } catch (e_append) {
                        console.error("QML RunningAlgorithmsView: Ошибка при добавлении execution", i, "в модель:", e_append.toString(), "Данные:", JSON.stringify(execution));
                    }
                } else {
                    console.warn("QML RunningAlgorithmsView: Execution", i, "не является корректным объектом:", typeof execution, execution);
                }
            }
        } else {
            console.error("QML RunningAlgorithmsView: Python не вернул корректный массивоподобный объект для executions. Получен тип:", typeof executionsList, "Значение:", executionsList);
        }
        console.log("QML RunningAlgorithmsView: Модель ListView executions обновлена. Элементов:", executionsModel.count);

        // --- НОВОЕ: Загружаем завершённые алгоритмы ---
        runningAlgorithmsViewRoot.loadCompletedExecutions();
        // --- ---
    }

    CustomCalendarPicker {
        id: historyCalendarPicker
        // onDateSelected: { ... } обработчик будет подключен динамически в onClicked кнопки
    }
}