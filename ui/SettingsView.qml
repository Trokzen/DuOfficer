// ui/SettingsView.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
// --- Импорт для OfficerEditorDialog ---
import "." // Импорт из той же директории (ui/)
// --- ---

Item {
    id: settingsViewRoot

    // --- Основной столбец для размещения вкладок и содержимого ---
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // --- Панель вкладок настроек ---
        TabBar {
            id: settingsTabBar
            Layout.fillWidth: true

            // --- Вкладка 1: Пост ---
            TabButton {
                text: "Пост"
            }
            // --- Вкладка 2: Должностные лица ---
            TabButton {
                text: "Должностные лица"
            }
            // --- Вкладка 3: Мероприятия ---
            TabButton {
                text: "Алгоритмы"
            }
            // --- Вкладка 4: Дополнительно ---
            TabButton {
                text: "Дополнительно"
            }
        }

        // --- Содержимое вкладок ---
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: settingsTabBar.currentIndex

            // --- Вкладка 1: Пост (с перенесенными настройками) ---
            Item {
                id: workplaceTab
                
                // Основной столбец для содержимого вкладки
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    Label {
                        text: "Настройки поста"
                        font.pointSize: 14
                        font.bold: true
                    }

                    // --- ScrollView для прокручиваемой части ---
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true  // Занимает всё доступное пространство кроме кнопки
                        clip: true
                        
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            spacing: 15

                            // --- Поля для "Пост" ---
                            Label {
                                text: "Номер поста:"
                            }
                            TextField {
                                id: postNumberField
                                Layout.fillWidth: true
                                placeholderText: "Введите номер поста..."
                            }

                            Label {
                                text: "Название поста:"
                            }
                            TextField {
                                id: postNameField
                                Layout.fillWidth: true
                                placeholderText: "Введите название поста..."
                            }
                            
                            Label {
                                text: "Название рабочего места:"
                            }
                            TextField {
                                id: workplaceNameField
                                Layout.fillWidth: true
                                placeholderText: "Введите название рабочего места..."
                            }
                            // --- ---

                            // --- Поле: Смена пароля ---
                            Label {
                                text: "Пароль для доступа к настройкам:"
                            }
                            TextField {
                                id: settingsPasswordField
                                Layout.fillWidth: true
                                placeholderText: "Введите новый пароль..."
                                echoMode: TextInput.Password
                            }
                            // --- ---

                            // --- Перенесенные настройки из "Дополнительно" ---

                            // Настройки напоминаний
                            CheckBox {
                                id: persistentRemindersCheckBox
                                text: "Использовать настойчивые напоминания"
                            }

                            // Настройки звука
                            CheckBox {
                                id: soundEnabledCheckBox
                                text: "Включить звуковой сигнал"
                            }

                            // Коррекция времени
                            GroupBox {
                                title: "Коррекция времени и даты"
                                Layout.fillWidth: true
                                ColumnLayout {
                                    // --- Название местного времени ---
                                    Label {
                                        text: "Название местного времени:"
                                    }
                                    TextField {
                                        id: customTimeLabelField
                                        Layout.fillWidth: true
                                        placeholderText: "Например: Местное время, Свердловское..."
                                        // text будет установлен в loadSettings
                                    }
                                    // --- ---
                                    
                                    // --- Смещение местного времени (часы) ---
                                    Label {
                                        text: "Смещение местного времени от системного (часы):"
                                        ToolTip.text: "Положительное значение - время вперёд, отрицательное - назад. Например, -2 для Калининграда, +2 для Самары относительно Москвы."
                                        ToolTip.visible: hovered
                                    }
                                    // Используем SpinBox для ввода целого числа со смещением
                                    SpinBox {
                                        id: customTimeOffsetSpinBox
                                        Layout.fillWidth: true
                                        from: -24 // Разумный диапазон
                                        to: 24
                                        stepSize: 1
                                        // value будет установлен в loadSettings
                                        // Добавим суффикс " ч" для наглядности
                                        property string suffix: " ч"
                                        textFromValue: function(value) { return value + suffix; }
                                        valueFromText: function(text) { return parseInt(text.replace(suffix, '')) || 0; }
                                    }
                                    // --- ---
                                    
                                    // --- Показывать московское время ---
                                    CheckBox {
                                        id: showMoscowTimeCheckBox
                                        text: "Показывать московское время"
                                        // checked будет установлен в loadSettings
                                    }
                                    // --- ---
                                    
                                    // --- Смещение московского времени (часы) ---
                                    // (Отображается, если включена опция показа)
                                    ColumnLayout {
                                        visible: showMoscowTimeCheckBox.checked
                                        spacing: 5
                                        
                                        Label {
                                            text: "Смещение московского времени от системного (часы):"
                                            ToolTip.text: "Обычно 0. Укажите, если нужно скорректировать показ Москвы."
                                            ToolTip.visible: hovered
                                        }
                                        SpinBox {
                                            id: moscowTimeOffsetSpinBox
                                            Layout.fillWidth: true
                                            from: -24
                                            to: 24
                                            stepSize: 1
                                            // value будет установлен в loadSettings
                                            property string suffix: " ч"
                                            textFromValue: function(value) { return value + suffix; }
                                            valueFromText: function(text) { return parseInt(text.replace(suffix, '')) || 0; }
                                        }
                                    }
                                    // --- ---
                                }
                            }

                            // Настройки внешнего вида
                            GroupBox {
                                title: "Внешний вид"
                                Layout.fillWidth: true

                                ColumnLayout {
                                    Label {
                                        text: "Фоновое изображение (эмблема):"
                                    }
                                    RowLayout {
                                        Button {
                                            text: "Выбрать файл..."
                                            // TODO: onClicked - открыть диалог выбора файла
                                        }
                                        Text {
                                            text: "..." // TODO: Путь к выбранному файлу
                                        }
                                    }

                                    Label {
                                        text: "Шрифт интерфейса:"
                                    }
                                    ComboBox {
                                        model: ["Arial", "Times New Roman", "Courier New"]
                                    }

                                    Label {
                                        text: "Размер шрифта:"
                                    }
                                    SpinBox {
                                        from: 8
                                        to: 24
                                        value: 12
                                    }

                                    Label {
                                        text: "Цвет фона:"
                                    }
                                    Rectangle {
                                        width: 50
                                        height: 25
                                        color: "#ecf0f1"
                                        border.color: "black"
                                    }
                                }
                            }
                            // --- Конец перенесенных настроек ---
                            
                            // Заполнитель для правильного скроллинга
                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }
                    // --- Конец ScrollView ---

                    // Кнопка сохранения - ВНЕ ScrollView, всегда видна!
                    Button {
                        text: "Сохранить"
                        onClicked: {
                            console.log("QML: Нажата кнопка сохранить");
                            saveSettings();
                        }
                        Layout.alignment: Qt.AlignRight
                    }
                }
            }

            // --- Вкладка 2: Должностные лица ---
            Item {
                id: officersTab
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10

                    Label {
                        text: "Список должностных лиц"
                        font.pointSize: 14
                        font.bold: true
                    }

                    // Панель с кнопками управления
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Button {
                            text: "Добавить"
                            onClicked: {
                                console.log("QML SettingsView: Нажата кнопка 'Добавить' должностное лицо.");
                                // Сбрасываем и открываем диалог добавления
                                officerEditorDialog.resetForAdd();
                                officerEditorDialog.open();
                            }
                        }
                        Button {
                            text: "Редактировать"
                            enabled: officersListView.currentIndex !== -1 // Включена, если выбран элемент
                            onClicked: {
                                var selectedIndex = officersListView.currentIndex;
                                if (selectedIndex !== -1) {
                                    var officerData = officersListView.model.get(selectedIndex);
                                    console.log("QML SettingsView: Нажата кнопка 'Редактировать' для пользователя ID:", officerData.id);
                                    // Загружаем данные и открываем диалог редактирования
                                    officerEditorDialog.loadDataForEdit(officerData);
                                    officerEditorDialog.open();
                                }
                            }
                        }
                        Button {
                            text: "Удалить"
                            enabled: officersListView.currentIndex !== -1 // Включена, если выбран элемент
                            onClicked: {
                                var selectedIndex = officersListView.currentIndex;
                                if (selectedIndex !== -1) {
                                    var officerData = officersListView.model.get(selectedIndex);
                                    console.log("QML SettingsView: Нажата кнопка 'Удалить' для пользователя ID:", officerData.id);
                                    // TODO: Добавить подтверждение удаления (например, MessageDialog)
                                    var confirmDelete = true; // Пока без подтверждения
                                    if (confirmDelete) {
                                        var result = appData.deleteDutyOfficer(officerData.id);
                                        if (result === true || (typeof result === 'number' && result > 0)) {
                                            console.log("QML SettingsView: Пользователь ID", officerData.id, "удален успешно.");
                                            // Перезагружаем список
                                            settingsViewRoot.loadDutyOfficers();
                                        } else if (typeof result === 'string') {
                                            console.warn("QML SettingsView: Ошибка удаления пользователя:", result);
                                            // TODO: Отобразить ошибку пользователю
                                        } else {
                                             console.error("QML SettingsView: Неизвестная ошибка удаления пользователя. Результат:", result);
                                        }
                                    }
                                }
                            }
                        }
                        // Заполнитель
                        Item {
                            Layout.fillWidth: true
                        }
                        // Кнопка обновления списка (на случай, если данные изменились вне этого окна)
                        Button {
                            text: "Обновить"
                            onClicked: {
                                console.log("QML SettingsView: Нажата кнопка 'Обновить' список должностных лиц.");
                                settingsViewRoot.loadDutyOfficers();
                            }
                        }
                    }

                    // Список должностных лиц
                    ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        ListView {
                            id: officersListView
                            clip: true // Обрезаем содержимое, выходящее за границы
                            model: ListModel {
                                id: officersListModel
                                // Модель будет заполнена данными из Python
                            }
                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 40
                                color: index % 2 ? "#f9f9f9" : "#ffffff" // Чередующийся цвет
                                border.color: officersListView.currentIndex === index ? "#3498db" : "#ddd" // Выделение выбранного
                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    // Формируем строку отображения: Звание Фамилия И.О.
                                    text: model.rank + " " + model.last_name + " " +
                                          model.first_name.charAt(0) + "." +
                                          (model.middle_name ? model.middle_name.charAt(0) + "." : "")
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        officersListView.currentIndex = index; // Устанавливаем выбранный элемент
                                    }
                                }
                            }
                        }
                    }
                }

                // --- OfficerEditorDialog для добавления/редактирования ---
                OfficerEditorDialog {
                    id: officerEditorDialog
                    // Подключаемся к сигналу accepted, чтобы перезагрузить список после успешной операции
                    onAccepted: {
                        console.log("QML SettingsView: Получен сигнал accepted от OfficerEditorDialog. Перезагружаем список.");
                        settingsViewRoot.loadDutyOfficers();
                    }
                }
                // --- ---
            }

            // --- Вкладка 3: Алгоритмы ---
            Item {
                id: algorithmsTab
                
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 10
                    
                    // Импортируем наш новый компонент
                    AlgorithmsListView {
                        id: algorithmsListView
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        
                        // Подключаем сигналы
                        onAddAlgorithmRequested: {
                            console.log("QML SettingsView: Запрошено добавление алгоритма")
                            algorithmEditorDialog.resetForAdd()
                            algorithmEditorDialog.open()
                        }
                        
                        onEditAlgorithmRequested: {
                            console.log("QML SettingsView: Запрошено редактирование алгоритма:", algorithmData)
                            algorithmEditorDialog.loadDataForEdit(algorithmData)
                            algorithmEditorDialog.open()
                        }
                        
                        onDeleteAlgorithmRequested: {
                            console.log("QML SettingsView: Запрошено удаление алгоритма ID:", algorithmId)
                            // TODO: Добавить подтверждение
                            var confirmDelete = true // Пока без подтверждения
                            if (confirmDelete) {
                                var result = appData.deleteAlgorithm(algorithmId)
                                if (result === true) {
                                    console.log("QML SettingsView: Алгоритм ID", algorithmId, "удален успешно.")
                                    // Обновляем список в ListView
                                    algorithmsListView.removeAlgorithm(algorithmId)
                                } else if (typeof result === 'string') {
                                    console.warn("QML SettingsView: Ошибка удаления алгоритма:", result)
                                    // TODO: Отобразить ошибку пользователю
                                } else {
                                    console.error("QML SettingsView: Неизвестная ошибка удаления алгоритма. Результат:", result)
                                }
                            }
                        }
                        
                        onDuplicateAlgorithmRequested: {
                            console.log("QML SettingsView: Запрошено дублирование алгоритма ID:", algorithmId)
                            var newAlgorithmId = appData.duplicateAlgorithm(algorithmId)
                            if (typeof newAlgorithmId === 'number' && newAlgorithmId > 0) {
                                console.log("QML SettingsView: Алгоритм ID", algorithmId, "дублирован успешно. Новый ID:", newAlgorithmId)
                                // Перезагружаем список, чтобы увидеть новую копию
                                algorithmsListView.loadAlgorithms()
                            } else {
                                console.warn("QML SettingsView: Ошибка дублирования алгоритма ID", algorithmId, ". Результат:", newAlgorithmId)
                                // TODO: Отобразить ошибку пользователю
                            }
                        }
                        onEditActionsRequested: {
                            console.log("QML SettingsView: Запрошено редактирование действий для алгоритма:", JSON.stringify(algorithmData));
                            // Предполагается, что algorithmActionsDialog уже создан и доступен в этой области видимости
                            // как это сделано в предыдущем примере кода.
                            if (typeof algorithmActionsDialog !== 'undefined' && algorithmActionsDialog) {
                                algorithmActionsDialog.loadData(algorithmData);
                                algorithmActionsDialog.open();
                            } else {
                                console.error("QML SettingsView: ОШИБКА - algorithmActionsDialog не найден!");
                                // TODO: Открыть диалог каким-то другим способом или показать сообщение об ошибке
                            }
                        }
                    }
                    
                    // Диалог редактора алгоритма
                    AlgorithmEditorDialog {
                        id: algorithmEditorDialog
                        // Подключаемся к сигналу сохранения, чтобы обновить список
                        onAlgorithmSaved: {
                            console.log("QML SettingsView: Получен сигнал algorithmSaved от AlgorithmEditorDialog. Перезагружаем список.")
                            algorithmsListView.loadAlgorithms()
                            // Или можно обновить только конкретный элемент, если известен ID
                            // algorithmsListView.updateOrAddAlgorithm(...)
                        }
                    }
                    // Диалог для редактирования действий алгоритма
                    AlgorithmActionsDialog {
                        id: algorithmActionsDialog
                    }
                }
            }

            // --- Вкладка 4: Дополнительно (перенесенные настройки) ---
            Item {
                id: generalTab
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 15
                    spacing: 15

                    Label {
                        text: "Дополнительные настройки"
                        font.pointSize: 14
                        font.bold: true
                    }
                    Text {
                        text: "Настройки перенесены на вкладку 'Пост'."
                        color: "gray"
                    }
                    // Заполнитель
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }

    function saveSettings() {
        console.log("QML SettingsView: === НАЧАЛО СОХРАНЕНИЯ НАСТРОЕК ===");
        
        console.log("QML SettingsView: 1. Сбор настроек из полей ввода...");
        // --- СБОР НАСТРОЕК "ПОСТ" ---
        console.log("QML SettingsView: 2. Сбор настроек раздела 'Пост'...");
        var postSettings = {};
        postSettings['post_number'] = postNumberField.text.trim();
        postSettings['post_name'] = postNameField.text.trim();
        postSettings['workplace_name'] = workplaceNameField.text.trim();
        console.log("QML SettingsView: 2. Собраны настройки 'Пост':", JSON.stringify(postSettings));
        // --- ---

        // --- СБОР НАСТРОЕК "НАПОМИНАНИЙ И ЗВУКА" ---
        console.log("QML SettingsView: 3. Сбор настроек раздела 'Напоминания и звук'...");
        var reminderSoundSettings = {};
        // SQLite хранит BOOLEAN как 1/0
        reminderSoundSettings['use_persistent_reminders'] = persistentRemindersCheckBox.checked ? 1 : 0;
        reminderSoundSettings['sound_enabled'] = soundEnabledCheckBox.checked ? 1 : 0;
        console.log("QML SettingsView: 3. Собраны настройки 'Напоминания и звук':", JSON.stringify(reminderSoundSettings));
        // --- ---

        // --- СБОР НОВЫХ НАСТРОЕК ВРЕМЕНИ ---
        console.log("QML SettingsView: 4. Сбор настроек раздела 'Время'...");
        var timeSettings = {};
        timeSettings['custom_time_label'] = customTimeLabelField.text.trim();
        // Преобразуем часы из SpinBox в секунды для хранения в БД
        timeSettings['custom_time_offset_seconds'] = customTimeOffsetSpinBox.value * 3600;
        // SQLite хранит BOOLEAN как 1/0
        timeSettings['show_moscow_time'] = showMoscowTimeCheckBox.checked ? 1 : 0;
        // Преобразуем часы из SpinBox в секунды для хранения в БД
        timeSettings['moscow_time_offset_seconds'] = moscowTimeOffsetSpinBox.value * 3600;
        console.log("QML SettingsView: 4. Собраны настройки 'Время':", JSON.stringify(timeSettings));
        // --- ---

        // --- СБОР НАСТРОЕК "ДОПОЛНИТЕЛЬНО" (если есть другие) ---
        // console.log("QML SettingsView: 5. Сбор настроек раздела 'Дополнительно'...");
        // var generalSettings = {};
        // ... (здесь можно добавить сбор других настроек, если они будут)
        // console.log("QML SettingsView: 5. Собраны настройки 'Дополнительно':", JSON.stringify(generalSettings));
        // --- ---

        // --- ОБЪЕДИНЕНИЕ ВСЕХ НАСТРОЕК В ОДИН СЛОВАРЬ ---
        console.log("QML SettingsView: 6. Объединение всех настроек в один словарь...");
        var allSettings = {};
        // Добавляем настройки "Пост"
        for (var key in postSettings) {
            if (postSettings.hasOwnProperty(key)) {
                allSettings[key] = postSettings[key];
            }
        }
        // Добавляем настройки "Напоминания и звук"
        for (var key_rs in reminderSoundSettings) {
            if (reminderSoundSettings.hasOwnProperty(key_rs)) {
                allSettings[key_rs] = reminderSoundSettings[key_rs];
            }
        }
        // Добавляем настройки "Время"
        for (var key_t in timeSettings) {
            if (timeSettings.hasOwnProperty(key_t)) {
                allSettings[key_t] = timeSettings[key_t];
            }
        }
        // Добавляем настройки "Дополнительно" (если есть)
        // for (var key_g in generalSettings) {
        //     if (generalSettings.hasOwnProperty(key_g)) {
        //         allSettings[key_g] = generalSettings[key_g];
        //     }
        // }
        console.log("QML SettingsView: 6. Все настройки объединены. Отправляемый словарь:", JSON.stringify(allSettings).substring(0, 500));
        // --- ---

        console.log("QML SettingsView: 7. Отправка настроек в Python для сохранения...");
        var result = appData.updateSettings(allSettings);
        console.log("QML SettingsView: 8. Получен результат сохранения из Python:", result);

        if (result === true) {
            console.log("QML SettingsView: === НАСТРОЙКИ УСПЕШНО СОХРАНЕНЫ ===");
            showSuccessMessage("Настройки сохранены успешно");
        } else {
            var errorMsgSave = "Неизвестная ошибка";
            if (typeof result === 'string') {
                errorMsgSave = result;
            } else if (result === false) {
                errorMsgSave = "Не удалось выполнить операцию. Проверьте данные.";
            } else if (result === -1) {
                errorMsgSave = "Ошибка при сохранении настроек.";
            }
            console.error("QML SettingsView: === ОШИБКА СОХРАНЕНИЯ НАСТРОЕК ===", errorMsgSave);
            showErrorMessage("Ошибка сохранения настроек: " + errorMsgSave);
        }
    }

    function loadSettings() {
        console.log("QML SettingsView: === НАЧАЛО ЗАГРУЗКИ НАСТРОЕК ===");
        console.log("QML SettingsView: 1. Запрос полных настроек у Python...");
        var settings = appData.getFullSettings();
        console.log("QML SettingsView: 2. Полученные настройки (сырой):", JSON.stringify(settings).substring(0, 500));

        // --- Преобразование QJSValue/QVariant в словарь JS ---
        console.log("QML SettingsView: 3. Проверка необходимости преобразования QJSValue...");
        if (settings && typeof settings === 'object' && typeof settings.hasOwnProperty === 'function' && settings.hasOwnProperty('toVariant')) {
            console.log("QML SettingsView: 3a. Обнаружен QJSValue, преобразование в QVariant/JS...");
            settings = settings.toVariant();
            console.log("QML SettingsView: 3b. QJSValue (settings) преобразован в:", JSON.stringify(settings).substring(0, 500));
        } else {
            console.log("QML SettingsView: 3a. Преобразование не требуется или невозможно.");
        }
        // --- ---

        if (settings && typeof settings === 'object') {
            console.log("QML SettingsView: 4. Настройки получены в виде объекта. Начало заполнения полей ввода...");
            
            // --- ЗАГРУЗКА НАСТРОЕК "ПОСТ" ---
            console.log("QML SettingsView: 5. Загрузка настроек раздела 'Пост'...");
            // Номер поста
            if (settings.post_number !== undefined) {
                postNumberField.text = String(settings.post_number);
                console.log("QML SettingsView: 5a. Загружен post_number:", postNumberField.text);
            }
            // Название поста
            if (settings.post_name !== undefined) {
                postNameField.text = String(settings.post_name);
                console.log("QML SettingsView: 5b. Загружен post_name:", postNameField.text);
            }
            // Название рабочего места
            if (settings.workplace_name !== undefined) {
                workplaceNameField.text = String(settings.workplace_name);
                console.log("QML SettingsView: 5c. Загружено workplace_name:", workplaceNameField.text);
            }
            console.log("QML SettingsView: 5. Загрузка настроек раздела 'Пост' завершена.");
            // --- ---

            // --- ЗАГРУЗКА НАСТРОЕК "НАПОМИНАНИЙ И ЗВУКА" ---
            console.log("QML SettingsView: 6. Загрузка настроек раздела 'Напоминания и звук'...");
            // Настойчивые напоминания
            if (settings.use_persistent_reminders !== undefined) {
                // Преобразуем 1/0 из SQLite в true/false для QML CheckBox
                persistentRemindersCheckBox.checked = (settings.use_persistent_reminders === 1 || settings.use_persistent_reminders === true);
                console.log("QML SettingsView: 6a. Загружено use_persistent_reminders:", persistentRemindersCheckBox.checked);
            }
            // Звук
            if (settings.sound_enabled !== undefined) {
                // Преобразуем 1/0 из SQLite в true/false для QML CheckBox
                soundEnabledCheckBox.checked = (settings.sound_enabled === 1 || settings.sound_enabled === true);
                console.log("QML SettingsView: 6b. Загружено sound_enabled:", soundEnabledCheckBox.checked);
            }
            console.log("QML SettingsView: 6. Загрузка настроек раздела 'Напоминания и звук' завершена.");
            // --- ---

            // --- ЗАГРУЗКА НОВЫХ НАСТРОЕК ВРЕМЕНИ ---
            console.log("QML SettingsView: 7. Загрузка настроек раздела 'Время'...");
            // Название местного времени
            if (settings.custom_time_label !== undefined) {
                customTimeLabelField.text = String(settings.custom_time_label);
                console.log("QML SettingsView: 7a. Загружено custom_time_label:", customTimeLabelField.text);
            }
            // Смещение местного времени (секунды -> часы для SpinBox)
            if (settings.custom_time_offset_seconds !== undefined) {
                var offsetSecs = parseInt(settings.custom_time_offset_seconds);
                if (!isNaN(offsetSecs)) {
                    var offsetHours = Math.floor(offsetSecs / 3600);
                    customTimeOffsetSpinBox.value = offsetHours;
                    console.log("QML SettingsView: 7b. Загружено custom_time_offset_seconds:", offsetSecs, "->", offsetHours, "ч");
                } else {
                    console.warn("QML SettingsView: 7b. Ошибка преобразования custom_time_offset_seconds:", settings.custom_time_offset_seconds);
                }
            }
            // Показывать московское время
            if (settings.show_moscow_time !== undefined) {
                // Преобразуем 1/0 из SQLite в true/false для QML CheckBox
                showMoscowTimeCheckBox.checked = (settings.show_moscow_time === 1 || settings.show_moscow_time === true);
                console.log("QML SettingsView: 7c. Загружено show_moscow_time:", showMoscowTimeCheckBox.checked);
            }
            // Смещение московского времени (секунды -> часы для SpinBox)
            if (settings.moscow_time_offset_seconds !== undefined) {
                var moscowOffsetSecs = parseInt(settings.moscow_time_offset_seconds);
                if (!isNaN(moscowOffsetSecs)) {
                    var moscowOffsetHours = Math.floor(moscowOffsetSecs / 3600);
                    moscowTimeOffsetSpinBox.value = moscowOffsetHours;
                    console.log("QML SettingsView: 7d. Загружено moscow_time_offset_seconds:", moscowOffsetSecs, "->", moscowOffsetHours, "ч");
                } else {
                    console.warn("QML SettingsView: 7d. Ошибка преобразования moscow_time_offset_seconds:", settings.moscow_time_offset_seconds);
                }
            }
            console.log("QML SettingsView: 7. Загрузка настроек раздела 'Время' завершена.");
            // --- ---

            // --- ЗАГРУЗКА НАСТРОЕК "ДОПОЛНИТЕЛЬНО" (если есть другие) ---
            // console.log("QML SettingsView: 8. Загрузка настроек раздела 'Дополнительно'...");
            // ... (здесь можно добавить загрузку других настроек, если они будут)
            // console.log("QML SettingsView: 8. Загрузка настроек раздела 'Дополнительно' завершена.");
            // --- ---

            console.log("QML SettingsView: === ЗАГРУЗКА НАСТРОЕК ЗАВЕРШЕНА ===");
        } else {
            var errorMsgLoad = "Не удалось загрузить настройки или они пусты.";
            console.error("QML SettingsView: === ОШИБКА ЗАГРУЗКИ НАСТРОЕК ===", errorMsgLoad);
            // TODO: Отобразить ошибку пользователю, например:
            // showErrorMessage(errorMsgLoad);
        }
    }

    // --- Функция для загрузки списка из Python ---
    function loadDutyOfficers() {
        console.log("QML SettingsView: Запрос списка должностных лиц у Python...");
        // Вызываем слот Python, который возвращает список
        var officersList = appData.getDutyOfficersList(); // <-- Получаем список
        console.log("QML SettingsView: Получен список из Python (сырой):", JSON.stringify(officersList));

        // --- НОВОЕ: Преобразование QJSValue/QVariant в массив JS ---
        // Если officersList - это QJSValue (из Python), преобразуем его
        if (officersList && typeof officersList === 'object' && officersList.hasOwnProperty('toVariant')) {
            officersList = officersList.toVariant();
            console.log("QML SettingsView: QJSValue (officersList) преобразован в:", JSON.stringify(officersList));
        }
        // --- ---

        // Очищаем текущую модель
        officersListModel.clear();
        console.log("QML SettingsView: Модель ListView очищена.");

        // --- ИЗМЕНЕНО: Более гибкая проверка на "массивоподобность" ---
        // Вместо Array.isArray, проверяем, есть ли у объекта свойство length (не undefined)
        // Это работает как для JS Array, так и для QVariantList, переданного из Python
        if (officersList && typeof officersList === 'object' && officersList.length !== undefined) {
        // --- ---
            var count = officersList.length;
            console.log("QML SettingsView: Полученный список является массивоподобным. Количество элементов:", count);
            // Заполняем модель данными по одному
            for (var i = 0; i < count; i++) {
                var officer = officersList[i];
                console.log("QML SettingsView: Обрабатываем элемент", i, ":", JSON.stringify(officer)); // Лог каждого элемента
                // Убедимся, что элемент - это объект
                if (typeof officer === 'object' && officer !== null) {
                    // --- ИЗМЕНЕНО: Явное копирование свойств ---
                    // Вместо officersListModel.append(officer), создаем новый JS объект
                    // Это помогает избежать проблем с QJSValue/QVariantMap, которые могут
                    // не сериализоваться корректно внутри ListModel.
                    var officerCopy = ({
                        "id": officer["id"],
                        "rank": officer["rank"],
                        "last_name": officer["last_name"],
                        "first_name": officer["first_name"],
                        "middle_name": officer["middle_name"],
                        "phone": officer["phone"], // Предполагаем, что phone тоже передается
                        "is_active": officer["is_active"], // Предполагаем, что is_active тоже передается
                        "is_admin": officer["is_admin"],
                        "login": officer["login"] // <-- Добавлено
                        // Добавьте другие поля, если они нужны для отображения в списке
                    });
                    // --- ---
                    try {
                        officersListModel.append(officerCopy); // <-- Добавляем КОПИЮ
                        console.log("QML SettingsView: Элемент", i, "добавлен в модель.");
                    } catch (e) {
                        console.error("QML SettingsView: Ошибка при добавлении элемента", i, "в модель:", e.toString(), "Данные:", JSON.stringify(officerCopy));
                    }
                } else {
                    console.warn("QML SettingsView: Элемент", i, "не является корректным объектом:", typeof officer, officer);
                }
            }
        } else {
            // --- ИЗМЕНЕНО: Сообщение об ошибке ---
            console.error("QML SettingsView: Python не вернул корректный массивоподобный объект. Получен тип:", typeof officersList, "Значение:", officersList);
            // --- ---
        }
        console.log("QML SettingsView: Модель ListView обновлена. Элементов:", officersListModel.count);
        // --- ДОБАВЛЕНО: Отладка содержимого модели ---
        if (officersListModel.count > 0) {
             try {
                 console.log("QML SettingsView: Первый элемент в модели (попытка):", JSON.stringify(officersListModel.get(0)));
             } catch (e_get) {
                 console.warn("QML SettingsView: Не удалось сериализовать первый элемент модели для лога:", e_get.toString());
                 // Попробуем получить отдельные свойства
                 var firstItem = officersListModel.get(0);
                 if (firstItem) {
                     console.log("QML SettingsView: Первый элемент в модели (свойства): id=", firstItem.id, "rank=", firstItem.rank, "last_name=", firstItem.last_name);
                 }
             }
        }
        // --- ---
    }
    // --- ---

    // --- Отслеживание активации вкладки "Должностные лица" ---
    Connections {
        target: settingsTabBar
        function onCurrentIndexChanged() {
            // Проверяем, является ли активной вкладка "Должностные лица"
            // Индекс вкладки "Должностные лица" - 1 (вторая вкладка, индекс с 0)
            if (settingsTabBar.currentIndex === 1) {
                console.log("QML SettingsView: Вкладка 'Должностные лица' активирована. Загрузка списка...");
                loadDutyOfficers(); // Загружаем список при активации вкладки
            }
            // Индекс вкладки "Алгоритмы" - 2 (третья вкладка, индекс с 0)
            if (settingsTabBar.currentIndex === 2) {
                console.log("QML SettingsView: Вкладка 'Алгоритмы' активирована. Загрузка списка...");
                // Проверяем, существует ли функция, и вызываем её
                // algorithmsListView - это id компонента AlgorithmsListView в algorithmsTab
                if (algorithmsListView && typeof algorithmsListView.loadAlgorithms === 'function') {
                    algorithmsListView.loadAlgorithms();
                } else {
                    console.error("QML SettingsView: ОШИБКА - algorithmsListView или algorithmsListView.loadAlgorithms не найдены!");
                }
            }
        }
    }
    // --- Автоматическая загрузка при открытии SettingsView ---
    Component.onCompleted: {
        // Этот код выполнится, когда компонент SettingsView будет полностью создан
        console.log("QML SettingsView: Загружен. Инициализация...");
        loadSettings();
    }
}