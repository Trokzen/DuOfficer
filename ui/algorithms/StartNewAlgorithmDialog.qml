// ui/algorithms/StartNewAlgorithmDialog.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5

Popup {
    id: startNewAlgorithmDialog
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width * 0.8, 600)
    height: Math.min(parent.height * 0.85, 500)
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    // --- Свойства ---
    property int selectedAlgorithmId: -1
    property string selectedAlgorithmName: ""
    property var availableAlgorithms: [] // Список доступных алгоритмов
    property var availableOfficers: []   // Список доступных должностных лиц
    // --- ---

    // --- Сигналы ---
    signal algorithmStarted(var algorithmExecutionData) // Сигнал при успешном запуске
    // --- ---

    background: Rectangle {
        color: "white"
        border.color: "lightgray"
        radius: 5
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        Label {
            text: "Запустить новый алгоритм"
            font.pointSize: 14
            font.bold: true
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            GridLayout {
                columns: 2
                columnSpacing: 10
                rowSpacing: 15
                width: parent.width

                Label {
                    text: "Выберите алгоритм:*"
                    Layout.alignment: Qt.AlignRight
                }
                ComboBox {
                    id: algorithmComboBox
                    Layout.fillWidth: true
                    model: ListModel {
                        id: algorithmsModel
                    }
                    textRole: "name" // Отображаем поле 'name'
                    onCurrentIndexChanged: {
                        if (currentIndex !== -1 && model.get(currentIndex)) {
                            startNewAlgorithmDialog.selectedAlgorithmId = model.get(currentIndex).id;
                            startNewAlgorithmDialog.selectedAlgorithmName = model.get(currentIndex).name;
                        } else {
                            startNewAlgorithmDialog.selectedAlgorithmId = -1;
                            startNewAlgorithmDialog.selectedAlgorithmName = "";
                        }
                    }
                }

                Label {
                    text: "Время начала:*"
                    Layout.alignment: Qt.AlignRight
                }
                // Используем RowLayout для поля ввода времени и кнопок
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    TextField {
                        id: startTimeField
                        Layout.fillWidth: true
                        placeholderText: "Введите время начала (ЧЧ:ММ:СС)..."
                        // text будет установлен в resetForAdd
                        validator: RegExpValidator { regExp: /^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/ } // Формат HH:MM:SS
                    }
                    
                    // Кнопки инкремента/декремента для часов
                    ColumnLayout {
                        spacing: 2
                        Button {
                            text: "▲"
                            font.pixelSize: 8
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 15
                            onClicked: {
                                incrementTimeComponent(startTimeField, "hours", 1);
                            }
                        }
                        Button {
                            text: "▼"
                            font.pixelSize: 8
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 15
                            onClicked: {
                                incrementTimeComponent(startTimeField, "hours", -1);
                            }
                        }
                    }
                    
                    // Кнопки инкремента/декремента для минут
                    ColumnLayout {
                        spacing: 2
                        Button {
                            text: "▲"
                            font.pixelSize: 8
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 15
                            onClicked: {
                                incrementTimeComponent(startTimeField, "minutes", 1);
                            }
                        }
                        Button {
                            text: "▼"
                            font.pixelSize: 8
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 15
                            onClicked: {
                                incrementTimeComponent(startTimeField, "minutes", -1);
                            }
                        }
                    }
                    
                    // Кнопки инкремента/декремента для секунд
                    ColumnLayout {
                        spacing: 2
                        Button {
                            text: "▲"
                            font.pixelSize: 8
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 15
                            onClicked: {
                                incrementTimeComponent(startTimeField, "seconds", 1);
                            }
                        }
                        Button {
                            text: "▼"
                            font.pixelSize: 8
                            Layout.preferredWidth: 20
                            Layout.preferredHeight: 15
                            onClicked: {
                                incrementTimeComponent(startTimeField, "seconds", -1);
                            }
                        }
                    }
                }

                Label {
                    text: "Дата начала:*"
                    Layout.alignment: Qt.AlignRight
                }
                // Используем RowLayout для поля ввода даты и кнопок
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    TextField {
                        id: startDateField
                        Layout.fillWidth: true
                        placeholderText: "Введите дату начала (ДД.ММ.ГГГГ)..."
                        // text будет установлен в resetForAdd
                        validator: RegExpValidator { regExp: /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d$/ } // Формат DD.MM.YYYY
                    }
                    
                    // Кнопка для открытия календаря
                    Button {
                        text: "📅"
                        font.pixelSize: 16
                        Layout.preferredWidth: 40
                        onClicked: {
                            // TODO: Открыть календарь для выбора даты
                            console.log("QML StartNewAlgorithmDialog: Нажата кнопка календаря для выбора даты начала");
                            showInfoMessage("Выбор даты (TODO): " + startDateField.text);
                        }
                    }
                }

                Label {
                    text: "Ответственный:*"
                    Layout.alignment: Qt.AlignRight
                }
                ComboBox {
                    id: officerComboBox
                    Layout.fillWidth: true
                    model: ListModel {
                        id: officersModel
                    }
                    textRole: "display_name" // Отображаем поле 'display_name'
                }

                // --- НОВОЕ: Поле для примечаний ---
                Label {
                    text: "Примечания:"
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                }
                TextArea {
                    id: notesArea
                    Layout.fillWidth: true
                    Layout.minimumHeight: 80
                    placeholderText: "Введите дополнительные примечания к запуску алгоритма..."
                    wrapMode: TextArea.Wrap
                }
                // --- ---
            }
        }

        // Сообщения об ошибках
        Label {
            id: errorMessageLabel
            Layout.fillWidth: true
            color: "red"
            wrapMode: Text.WordWrap
            visible: text !== ""
        }

        // Кнопки
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: "Отмена"
                onClicked: {
                    console.log("QML StartNewAlgorithmDialog: Нажата кнопка Отмена");
                    startNewAlgorithmDialog.close();
                }
            }
            Button {
                text: "Запустить"
                onClicked: {
                    console.log("QML StartNewAlgorithmDialog: Нажата кнопка Запустить");
                    errorMessageLabel.text = "";

                    // Валидация
                    if (startNewAlgorithmDialog.selectedAlgorithmId <= 0) {
                        errorMessageLabel.text = "Пожалуйста, выберите алгоритм.";
                        return;
                    }
                    if (!startTimeField.text.trim()) {
                        errorMessageLabel.text = "Пожалуйста, заполните время начала.";
                        return;
                    }
                    if (!startDateField.text.trim()) {
                        errorMessageLabel.text = "Пожалуйста, заполните дату начала.";
                        return;
                    }
                    // Проверка формата даты и времени
                    var timeRegex = /^([01]?[0-9]|2[0-3]):[0-5][0-9]:[0-5][0-9]$/;
                    var dateRegex = /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d$/;
                    if (!timeRegex.test(startTimeField.text.trim())) {
                        errorMessageLabel.text = "Некорректный формат времени начала. Используйте ЧЧ:ММ:СС.";
                        return;
                    }
                    if (!dateRegex.test(startDateField.text.trim())) {
                        errorMessageLabel.text = "Некорректный формат даты начала. Используйте ДД.ММ.ГГГГ.";
                        return;
                    }
                    if (officerComboBox.currentIndex === -1 || !officerComboBox.model.get(officerComboBox.currentIndex)) {
                        errorMessageLabel.text = "Пожалуйста, выберите ответственного.";
                        return;
                    }

                    // Подготавливаем данные для запуска
                    var officerData = officerComboBox.model.get(officerComboBox.currentIndex);
                    var algorithmExecutionData = {
                        "algorithm_id": startNewAlgorithmDialog.selectedAlgorithmId,
                        "started_at": startDateField.text.trim() + " " + startTimeField.text.trim(), // Формат 'DD.MM.YYYY HH:MM:SS'
                        "created_by_user_id": officerData.id,
                        "notes": notesArea.text.trim() || null // Примечания (может быть null)
                    };
                    
                    console.log("QML StartNewAlgorithmDialog: Отправляем данные для запуска алгоритма в Python:", JSON.stringify(algorithmExecutionData));

                    // Вызываем метод Python для запуска
                    var result = appData.startAlgorithmExecution(algorithmExecutionData);
                    
                    if (result === true || (typeof result === 'number' && result > 0)) {
                        console.log("QML StartNewAlgorithmDialog: Алгоритм успешно запущен. Результат:", result);
                        // Уведомляем родителя об успешном запуске
                        startNewAlgorithmDialog.algorithmStarted({
                            "execution_id": typeof result === 'number' ? result : -1, // ID нового execution'а, если вернулся ID
                            "algorithm_id": startNewAlgorithmDialog.selectedAlgorithmId,
                            "started_at": algorithmExecutionData.started_at,
                            "created_by_user_id": officerData.id,
                            "notes": algorithmExecutionData.notes
                        });
                        startNewAlgorithmDialog.close();
                    } else {
                        var errorMsg = "Неизвестная ошибка";
                        if (typeof result === 'string') {
                            errorMsg = result;
                        } else if (result === false) {
                            errorMsg = "Не удалось выполнить операцию. Проверьте данные.";
                        } else if (result === -1) {
                            errorMsg = "Ошибка при запуске алгоритма.";
                        }
                        errorMessageLabel.text = "Ошибка: " + errorMsg;
                        console.warn("QML StartNewAlgorithmDialog: Ошибка при запуске алгоритма:", errorMsg);
                    }
                }
            }
        }
    }

    /**
     * Сбрасывает диалог для добавления нового запуска алгоритма
     */
    function resetForAdd() {
        console.log("QML StartNewAlgorithmDialog: Сброс для запуска нового алгоритма");
        selectedAlgorithmId = -1;
        selectedAlgorithmName = "";
        algorithmComboBox.currentIndex = -1;
        officerComboBox.currentIndex = -1;
        notesArea.text = "";
        errorMessageLabel.text = "";
        
        // Устанавливаем текущую дату и время по умолчанию
        var now = new Date();
        var year = now.getFullYear();
        var month = String(now.getMonth() + 1).padStart(2, '0'); // Месяцы с 0
        var day = String(now.getDate()).padStart(2, '0');
        var hours = String(now.getHours()).padStart(2, '0');
        var minutes = String(now.getMinutes()).padStart(2, '0');
        var seconds = String(now.getSeconds()).padStart(2, '0');
        
        startDateField.text = day + "." + month + "." + year;
        startTimeField.text = hours + ":" + minutes + ":" + seconds;
        
        console.log("QML StartNewAlgorithmDialog: Установлены значения по умолчанию: дата =", startDateField.text, ", время =", startTimeField.text);
    }

    /**
     * Загружает список доступных алгоритмов из Python
     */
    function loadAlgorithms() {
        console.log("QML StartNewAlgorithmDialog: Запрос списка всех алгоритмов у Python...");
        var algorithmsList = appData.getAllAlgorithmsList(); // <-- Получаем ВСЕ алгоритмы
        console.log("QML StartNewAlgorithmDialog: Получен список алгоритмов из Python (сырой):", JSON.stringify(algorithmsList).substring(0, 500));

        // Преобразование QJSValue/QVariant в массив JS
        if (algorithmsList && typeof algorithmsList === 'object' && algorithmsList.hasOwnProperty('toVariant')) {
            algorithmsList = algorithmsList.toVariant();
            console.log("QML StartNewAlgorithmDialog: QJSValue (algorithmsList) преобразован в:", JSON.stringify(algorithmsList).substring(0, 500));
        }

        // Очищаем текущую модель
        algorithmsModel.clear();
        console.log("QML StartNewAlgorithmDialog: Модель ComboBox алгоритмов очищена.");

        // --- Более гибкая проверка на "массивоподобность" ---
        if (algorithmsList && typeof algorithmsList === 'object' && algorithmsList.length !== undefined) {
        // --- ---
            var count = algorithmsList.length;
            console.log("QML StartNewAlgorithmDialog: Полученный список алгоритмов является массивоподобным. Количество элементов:", count);
            
            for (var i = 0; i < count; i++) {
                var alg = algorithmsList[i];
                console.log("QML StartNewAlgorithmDialog: Обрабатываем алгоритм", i, ":", JSON.stringify(alg).substring(0, 200));
                
                if (typeof alg === 'object' && alg !== null) {
                    try {
                        algorithmsModel.append({
                            "id": alg["id"],
                            "name": alg["name"] || "",
                            "category": alg["category"] || "",
                            "time_type": alg["time_type"] || "",
                            "description": alg["description"] || ""
                        });
                        console.log("QML StartNewAlgorithmDialog: Алгоритм", i, "добавлен в модель.");
                    } catch (e) {
                        console.error("QML StartNewAlgorithmDialog: Ошибка при добавлении алгоритма", i, "в модель:", e.toString(), "Данные:", JSON.stringify(alg));
                    }
                } else {
                    console.warn("QML StartNewAlgorithmDialog: Алгоритм", i, "не является корректным объектом:", typeof alg, alg);
                }
            }
        } else {
            console.error("QML StartNewAlgorithmDialog: Python не вернул корректный массивоподобный объект для алгоритмов. Получен тип:", typeof algorithmsList, "Значение:", algorithmsList);
        }
        console.log("QML StartNewAlgorithmDialog: Модель ComboBox алгоритмов обновлена. Элементов:", algorithmsModel.count);
    }

    /**
     * Загружает список доступных должностных лиц из Python
     */
    function loadOfficers() {
        console.log("QML StartNewAlgorithmDialog: Запрос списка всех должностных лиц у Python...");
        // var officersList = appData.getDutyOfficersList(); // <-- СТАРОЕ: Только активные
        var officersList = appData.getAllDutyOfficersList(); // <-- НОВОЕ: Все (активные и неактивные)
        console.log("QML StartNewAlgorithmDialog: Получен список должностных лиц из Python (сырой):", JSON.stringify(officersList).substring(0, 500));

        // Преобразование QJSValue/QVariant в массив JS
        if (officersList && typeof officersList === 'object' && officersList.hasOwnProperty('toVariant')) {
            officersList = officersList.toVariant();
            console.log("QML StartNewAlgorithmDialog: QJSValue (officersList) преобразован в:", JSON.stringify(officersList).substring(0, 500));
        }

        // Очищаем текущую модель
        officersModel.clear();
        console.log("QML StartNewAlgorithmDialog: Модель ComboBox должностных лиц очищена.");

        // --- Более гибкая проверка на "массивоподобность" ---
        if (officersList && typeof officersList === 'object' && officersList.length !== undefined) {
        // --- ---
            var count = officersList.length;
            console.log("QML StartNewAlgorithmDialog: Полученный список должностных лиц является массивоподобным. Количество элементов:", count);
            
            for (var i = 0; i < count; i++) {
                var officer = officersList[i];
                console.log("QML StartNewAlgorithmDialog: Обрабатываем должностное лицо", i, ":", JSON.stringify(officer).substring(0, 200));
                
                if (typeof officer === 'object' && officer !== null) {
                    try {
                        // Формируем отображаемое имя: Звание Фамилия И.О.
                        var displayName = (officer["rank"] || "") + " " +
                                          (officer["last_name"] || "") + " " +
                                          (officer["first_name"] ? officer["first_name"].charAt(0) + "." : "") +
                                          (officer["middle_name"] ? officer["middle_name"].charAt(0) + "." : "");
                        
                        officersModel.append({
                            "id": officer["id"],
                            "rank": officer["rank"] || "",
                            "last_name": officer["last_name"] || "",
                            "first_name": officer["first_name"] || "",
                            "middle_name": officer["middle_name"] || "",
                            "phone": officer["phone"] || "",
                            "is_active": officer["is_active"] || 0,
                            "is_admin": officer["is_admin"] || 0,
                            "login": officer["login"] || "",
                            "display_name": displayName // <-- НОВОЕ: Отображаемое имя
                        });
                        console.log("QML StartNewAlgorithmDialog: Должностное лицо", i, "добавлено в модель с display_name:", displayName);
                    } catch (e) {
                        console.error("QML StartNewAlgorithmDialog: Ошибка при добавлении должностного лица", i, "в модель:", e.toString(), "Данные:", JSON.stringify(officer));
                    }
                } else {
                    console.warn("QML StartNewAlgorithmDialog: Должностное лицо", i, "не является корректным объектом:", typeof officer, officer);
                }
            }
        } else {
            console.error("QML StartNewAlgorithmDialog: Python не вернул корректный массивоподобный объект для должностных лиц. Получен тип:", typeof officersList, "Значение:", officersList);
        }
        console.log("QML StartNewAlgorithmDialog: Модель ComboBox должностных лиц обновлена. Элементов:", officersModel.count);
    }

    /**
     * Вспомогательная функция для инкремента/декремента компонентов времени
     * @param {TextField} textField - Поле ввода времени
     * @param {string} component - Компонент: "hours", "minutes", "seconds"
     * @param {number} delta - Шаг изменения (+1 или -1)
     */
    function incrementTimeComponent(textField, component, delta) {
        console.log("QML StartNewAlgorithmDialog: incrementTimeComponent called with", textField, component, delta);
        var text = textField.text || "00:00:00";
        console.log("QML StartNewAlgorithmDialog: Current text:", text);
        
        // Попробуем разобрать формат HH:MM:SS
        var parts = text.split(":");
        if (parts.length === 3) {
            var hours = parseInt(parts[0], 10) || 0;
            var minutes = parseInt(parts[1], 10) || 0;
            var seconds = parseInt(parts[2], 10) || 0;
            
            console.log("QML StartNewAlgorithmDialog: Parsed H:M:S:", hours, minutes, seconds);
            
            switch(component) {
                case "hours":
                    hours += delta;
                    // Ограничиваем диапазон 0-23
                    hours = (hours + 24) % 24; // Обеспечивает корректное переполнение
                    break;
                case "minutes":
                    minutes += delta;
                    // Обработка переполнения минут
                    while (minutes >= 60) {
                        minutes -= 60;
                        hours += 1;
                        if (hours >= 24) hours = 0; // Переполнение часов
                    }
                    while (minutes < 0) {
                        minutes += 60;
                        hours -= 1;
                        if (hours < 0) hours = 23; // Переполнение часов
                    }
                    minutes = Math.max(0, minutes);
                    break;
                case "seconds":
                    seconds += delta;
                    // Обработка переполнения секунд
                    while (seconds >= 60) {
                        seconds -= 60;
                        minutes += 1;
                        if (minutes >= 60) {
                            minutes -= 60;
                            hours += 1;
                            if (hours >= 24) hours = 0; // Переполнение часов
                        }
                    }
                    while (seconds < 0) {
                        seconds += 60;
                        minutes -= 1;
                        if (minutes < 0) {
                            minutes += 60;
                            hours -= 1;
                            if (hours < 0) hours = 23; // Переполнение часов
                        }
                    }
                    seconds = Math.max(0, seconds);
                    break;
            }
            
            // Форматируем обратно в строку HH:MM:SS
            var newHours = hours.toString().padStart(2, '0');
            var newMinutes = minutes.toString().padStart(2, '0');
            var newSeconds = seconds.toString().padStart(2, '0');
            var newText = newHours + ":" + newMinutes + ":" + newSeconds;
            
            console.log("QML StartNewAlgorithmDialog: New text:", newText);
            textField.text = newText;
        } else {
            // Если формат не HH:MM:SS, можно попробовать другие форматы
            // или просто добавить/убрать секунду/минуту/час в конец как строку
            // Пока просто выводим предупреждение
            console.warn("QML StartNewAlgorithmDialog: incrementTimeComponent: Unsupported time format:", text);
        }
    }

    onOpened: {
        console.log("QML StartNewAlgorithmDialog: Диалог открыт.");
        resetForAdd(); // Сбрасываем поля ввода
        loadAlgorithms(); // Загружаем список алгоритмов
        loadOfficers(); // Загружаем список должностных лиц
        errorMessageLabel.text = ""; // Очищаем сообщения об ошибках
    }
}