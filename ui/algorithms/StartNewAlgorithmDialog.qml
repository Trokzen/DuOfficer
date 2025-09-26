// ui/algorithms/StartNewAlgorithmDialog.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
// import QtQuick.Dialogs 6.5 // Если понадобится MessageDialog

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
    property string categoryFilter: "" // Фильтр по категории (передаётся из родителя)
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
                    textRole: "name"
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
                // --- НОВОЕ: Улучшенный ввод времени (часы, минуты, секунды) ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    // Поле и кнопки для часов
                    ColumnLayout {
                        spacing: 2
                        TextField {
                            id: startHoursField
                            Layout.fillWidth: true
                            placeholderText: "Часы (00-23)"
                            text: "00"
                            validator: IntValidator { bottom: 0; top: 23 }
                        }
                        RowLayout {
                            spacing: 1
                            Button {
                                text: "▲"
                                font.pixelSize: 8
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 12
                                onClicked: incrementTimeComponent(startHoursField, "hours", 1);
                            }
                            Button {
                                text: "▼"
                                font.pixelSize: 8
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 12
                                onClicked: incrementTimeComponent(startHoursField, "hours", -1);
                            }
                        }
                    }
                    
                    Text { text: ":" } // Разделитель

                    // Поле и кнопки для минут
                    ColumnLayout {
                        spacing: 2
                        TextField {
                            id: startMinutesField
                            Layout.fillWidth: true
                            placeholderText: "Минуты (00-59)"
                            text: "00"
                            validator: IntValidator { bottom: 0; top: 59 }
                        }
                        RowLayout {
                            spacing: 1
                            Button {
                                text: "▲"
                                font.pixelSize: 8
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 12
                                onClicked: incrementTimeComponent(startMinutesField, "minutes", 1);
                            }
                            Button {
                                text: "▼"
                                font.pixelSize: 8
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 12
                                onClicked: incrementTimeComponent(startMinutesField, "minutes", -1);
                            }
                        }
                    }
                    
                    Text { text: ":" } // Разделитель

                    // Поле и кнопки для секунд
                    ColumnLayout {
                        spacing: 2
                        TextField {
                            id: startSecondsField
                            Layout.fillWidth: true
                            placeholderText: "Секунды (00-59)"
                            text: "00"
                            validator: IntValidator { bottom: 0; top: 59 }
                        }
                        RowLayout {
                            spacing: 1
                            Button {
                                text: "▲"
                                font.pixelSize: 8
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 12
                                onClicked: incrementTimeComponent(startSecondsField, "seconds", 1);
                            }
                            Button {
                                text: "▼"
                                font.pixelSize: 8
                                Layout.preferredWidth: 15
                                Layout.preferredHeight: 12
                                onClicked: incrementTimeComponent(startSecondsField, "seconds", -1);
                            }
                        }
                    }
                }
                // --- ---

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
                        // Закомментирован validator
                        // validator: RegExpValidator { regExp: /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d$/ } // Формат DD.MM.YYYY
                    }
                    
                    // Кнопка для открытия календаря
                    Button {
                        text: "📅"
                        font.pixelSize: 16
                        Layout.preferredWidth: 40
                        onClicked: {
                            // TODO: Открыть календарь для выбора даты
                            console.log("QML StartNewAlgorithmDialog: Нажата кнопка календаря для выбора даты начала");
                            // showInfoMessage("Выбор даты (TODO): " + startDateField.text); // УДАЛЁН
                            console.log("QML StartNewAlgorithmDialog: Выбор даты (TODO): " + startDateField.text);
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

                // --- НОВОЕ: Поле для примечаний с улучшенным оформлением ---
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
                    // --- УЛУЧШЕННОЕ ОФОРМЛЕНИЕ ---
                    background: Rectangle {
                        border.color: notesArea.activeFocus ? "#3498db" : "#ccc" // Цвет границы при фокусе (синий) и без (серый)
                        border.width: 1 // Толщина границы в пикселях
                        radius: 2 // Небольшое скругление углов (опционально)
                        color: "white" // Цвет фона поля ввода
                    }
                    // --- ---
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
                    // --- ВАЛИДАЦИЯ ВРЕМЕНИ ---
                    var hours = parseInt(startHoursField.text, 10);
                    var minutes = parseInt(startMinutesField.text, 10);
                    var seconds = parseInt(startSecondsField.text, 10);
                    
                    if (isNaN(hours) || hours < 0 || hours > 23 ||
                        isNaN(minutes) || minutes < 0 || minutes > 59 ||
                        isNaN(seconds) || seconds < 0 || seconds > 59) {
                        errorMessageLabel.text = "Некорректное время начала. Проверьте часы, минуты и секунды.";
                        return;
                    }
                    // --- ---
                    if (!startDateField.text.trim()) {
                        errorMessageLabel.text = "Пожалуйста, заполните дату начала.";
                        return;
                    }
                    // Проверка формата даты (упрощённая, так как validator закомментирован)
                    var dateRegex = /^(0[1-9]|[12][0-9]|3[01])\.(0[1-9]|1[012])\.(19|20)\d\d$/;
                    if (!dateRegex.test(startDateField.text.trim())) {
                        errorMessageLabel.text = "Некорректный формат даты начала. Используйте ДД.ММ.ГГГГ.";
                        return;
                    }
                    if (officerComboBox.currentIndex === -1 || !officerComboBox.model.get(officerComboBox.currentIndex)) {
                        errorMessageLabel.text = "Пожалуйста, выберите ответственного.";
                        return;
                    }

                    // --- СОБИРАЕМ ВРЕМЯ ---
                    var timeString = String(hours).padStart(2, '0') + ":" +
                                     String(minutes).padStart(2, '0') + ":" +
                                     String(seconds).padStart(2, '0');
                    // --- ---
                    
                    // Подготавливаем данные
                    var officerData = officerComboBox.model.get(officerComboBox.currentIndex);
                    var algorithmExecutionData = {
                        "algorithm_id": startNewAlgorithmDialog.selectedAlgorithmId,
                        "started_at": startDateField.text.trim() + " " + timeString, // Формат 'DD.MM.YYYY HH:MM:SS'
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
        // Сбрасываем поля времени
        startHoursField.text = hours;
        startMinutesField.text = minutes;
        startSecondsField.text = seconds;
        
        console.log("QML StartNewAlgorithmDialog: Установлены значения по умолчанию: дата =", startDateField.text, ", время = ", hours, ":", minutes, ":", seconds);
        
        // Загружаем список алгоритмов по фильтру
        loadAlgorithmsByCategory();
        // Загружаем список должностных лиц
        loadOfficers();
        // Пытаемся выбрать текущего дежурного
        selectCurrentDutyOfficer();
    }

    /**
     * Загружает список алгоритмов из Python, отфильтрованных по categoryFilter
     */
    function loadAlgorithmsByCategory() {
        console.log("QML StartNewAlgorithmDialog: Запрос списка алгоритмов для категории:", categoryFilter, "у Python...");
        // Используем метод, который возвращает ВСЕ алгоритмы
        var allAlgorithmsList = appData.getAllAlgorithmsList(); 
        console.log("QML StartNewAlgorithmDialog: Получен список ВСЕХ алгоритмов из Python (сырой):", JSON.stringify(allAlgorithmsList).substring(0, 500));

        // Преобразование QJSValue/QVariant в массив JS
        if (allAlgorithmsList && typeof allAlgorithmsList === 'object' && allAlgorithmsList.hasOwnProperty('toVariant')) {
            allAlgorithmsList = allAlgorithmsList.toVariant();
            console.log("QML StartNewAlgorithmDialog: QJSValue (allAlgorithmsList) преобразован в:", JSON.stringify(allAlgorithmsList).substring(0, 500));
        }

        // Очищаем текущую модель
        algorithmsModel.clear();
        console.log("QML StartNewAlgorithmDialog: Модель ComboBox алгоритмов очищена.");

        // --- Более гибкая проверка на "массивоподобность" ---
        if (allAlgorithmsList && typeof allAlgorithmsList === 'object' && allAlgorithmsList.length !== undefined) {
        // --- ---
            var count = allAlgorithmsList.length;
            console.log("QML StartNewAlgorithmDialog: Полученный список ВСЕХ алгоритмов является массивоподобным. Количество элементов:", count);
            
            for (var i = 0; i < count; i++) {
                var alg = allAlgorithmsList[i];
                console.log("QML StartNewAlgorithmDialog: Обрабатываем алгоритм", i, ":", JSON.stringify(alg).substring(0, 200));
                
                // --- ФИЛЬТРАЦИЯ ПО КАТЕГОРИИ ---
                if (typeof alg === 'object' && alg !== null && alg.category === categoryFilter) {
                // --- ---
                    try {
                        algorithmsModel.append({
                            "id": alg["id"],
                            "name": alg["name"] || "",
                            "category": alg["category"] || "",
                            "time_type": alg["time_type"] || "",
                            "description": alg["description"] || ""
                        });
                        console.log("QML StartNewAlgorithmDialog: Алгоритм", i, "(ID:", alg.id, ") добавлен в модель (категория совпадает).");
                    } catch (e) {
                        console.error("QML StartNewAlgorithmDialog: Ошибка при добавлении алгоритма", i, "в модель:", e.toString(), "Данные:", JSON.stringify(alg));
                    }
                } else {
                     // Если алгоритм не подходит по категории или не объект, пропускаем
                     if (typeof alg === 'object' && alg !== null) {
                         console.log("QML StartNewAlgorithmDialog: Алгоритм", i, "(ID:", alg.id, ") пропущен (категория не совпадает).");
                     } else {
                         console.log("QML StartNewAlgorithmDialog: Алгоритм", i, "пропущен (не является объектом).");
                     }
                }
            }
        } else {
            console.error("QML StartNewAlgorithmDialog: Python не вернул корректный массивоподобный объект для алгоритмов. Получен тип:", typeof allAlgorithmsList, "Значение:", allAlgorithmsList);
        }
        console.log("QML StartNewAlgorithmDialog: Модель ComboBox алгоритмов (после фильтрации) обновлена. Элементов:", algorithmsModel.count);
    }

    /**
     * Загружает список доступных должностных лиц из Python
     */
    function loadOfficers() {
        console.log("QML StartNewAlgorithmDialog: Запрос списка всех должностных лиц у Python...");
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
     * Пытается выбрать в ComboBox текущего дежурного, чьё имя отображается в appData.dutyOfficer
     */
    function selectCurrentDutyOfficer() {
        console.log("QML StartNewAlgorithmDialog: Попытка выбрать текущего дежурного:", appData.dutyOfficer);
        
        var currentDutyOfficerDisplay = appData.dutyOfficer; // Это "Фамилия И.О." из ApplicationData
        
        if (!currentDutyOfficerDisplay) {
            console.log("QML StartNewAlgorithmDialog: appData.dutyOfficer пуст, нечего выбирать.");
            return;
        }

        // Проходим по модели officersModel и ищем совпадение по display_name
        for (var i = 0; i < officersModel.count; i++) {
            var officerItem = officersModel.get(i);
            if (officerItem && officerItem.display_name === currentDutyOfficerDisplay) {
                officerComboBox.currentIndex = i;
                console.log("QML StartNewAlgorithmDialog: Текущий дежурный", currentDutyOfficerDisplay, "выбран в ComboBox (индекс", i, ").");
                return; // Нашли, выходим
            }
        }
        
        console.log("QML StartNewAlgorithmDialog: Текущий дежурный", currentDutyOfficerDisplay, "не найден в списке должностных лиц для выбора. Оставляем без выбора.");
    }


    /**
     * Вспомогательная функция для инкремента/декремента компонентов времени
     * @param {TextField} textField - Поле ввода времени (часы, минуты, секунды)
     * @param {string} component - Компонент: "hours", "minutes", "seconds"
     * @param {number} delta - Шаг изменения (+1 или -1)
     */
    function incrementTimeComponent(textField, component, delta) {
        console.log("QML StartNewAlgorithmDialog: incrementTimeComponent called with", textField, component, delta);
        var text = textField.text || "00";
        console.log("QML StartNewAlgorithmDialog: Current text:", text);
        
        var value = parseInt(text, 10) || 0;
        console.log("QML StartNewAlgorithmDialog: Parsed value:", value);
        
        switch(component) {
            case "hours":
                value += delta;
                // Ограничиваем диапазон 0-23
                value = (value + 24) % 24; // Обеспечивает корректное переполнение
                break;
            case "minutes":
                value += delta;
                // Обработка переполнения минут
                while (value >= 60) {
                    value -= 60;
                    // Увеличиваем часы при переполнении минут
                    incrementTimeComponent(startHoursField, "hours", 1);
                }
                while (value < 0) {
                    value += 60;
                    // Уменьшаем часы при переполнении минут
                    incrementTimeComponent(startHoursField, "hours", -1);
                }
                value = Math.max(0, Math.min(59, value)); // Ограничиваем 0-59
                break;
            case "seconds":
                value += delta;
                // Обработка переполнения секунд
                while (value >= 60) {
                    value -= 60;
                    // Увеличиваем минуты при переполнении секунд
                    incrementTimeComponent(startMinutesField, "minutes", 1);
                }
                while (value < 0) {
                    value += 60;
                    // Уменьшаем минуты при переполнении секунд
                    incrementTimeComponent(startMinutesField, "minutes", -1);
                }
                value = Math.max(0, Math.min(59, value)); // Ограничиваем 0-59
                break;
        }
        
        // Форматируем обратно в строку HH, MM, SS
        var newText = value.toString().padStart(2, '0');
        
        console.log("QML StartNewAlgorithmDialog: New text:", newText);
        textField.text = newText;
    }

    onOpened: {
        console.log("QML StartNewAlgorithmDialog: Диалог открыт.");
        resetForAdd(); // Сбрасываем поля ввода, загружаем данные, выбираем дежурного
        errorMessageLabel.text = ""; // Очищаем сообщения об ошибках
    }
}