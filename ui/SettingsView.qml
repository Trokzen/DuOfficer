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
                text: "Мероприятия"
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
                                    CheckBox {
                                        id: useCustomTimeCheckBox
                                        text: "Использовать пользовательское время"
                                    }
                                    // TODO: Реализовать условное отображение
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

            // --- Вкладка 3: Мероприятия ---
            Item {
                id: eventsTab
                Text {
                    anchors.centerIn: parent
                    text: "Настройка мероприятий (будет реализована позже)"
                    color: "gray"
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
        console.log("QML: Сохранение настроек...");
        
        // Собираем настройки с вкладки "Пост"
        var postSettings = {
            'workplace_name': workplaceNameField.text,  // <- Закомментируй это
            'post_number': postNumberField.text,
            'post_name': postNameField.text,
            'use_persistent_reminders': persistentRemindersCheckBox.checked ? 1 : 0, // SQLite хранит BOOLEAN как 1/0
            'sound_enabled': soundEnabledCheckBox.checked ? 1 : 0
        };
        
        console.log("QML: Отправляемые настройки:", JSON.stringify(postSettings));
        
        // Вызываем метод Python для сохранения
        var result = appData.updateSettings(postSettings);
        
        console.log("QML: Результат сохранения:", result);
        
        if (result === true) {
            console.log("QML: Настройки успешно сохранены");
            showSuccessMessage("Настройки сохранены успешно");
        } else {
            console.log("QML: Ошибка сохранения настроек:", result);
            showErrorMessage("Ошибка сохранения настроек: " + result);
        }
    }

    function loadSettings() {
        console.log("QML: Загрузка настроек...");
        
        // Получаем все настройки из Python
        var settings = appData.getFullSettings();
        
        console.log("QML: Полученные настройки:", JSON.stringify(settings));
        
        if (settings && typeof settings === 'object') {
            // Заполняем поля вкладки "Пост"
            if (settings.workplace_name !== undefined) {
                workplaceNameField.text = settings.workplace_name;
            }
            if (settings.post_number !== undefined) {
                postNumberField.text = settings.post_number;
            }
            if (settings.post_name !== undefined) {
                postNameField.text = settings.post_name;
            }
            // Проверяем, существуют ли ключи, и устанавливаем значения CheckBox
            if (settings.use_persistent_reminders !== undefined) {
                // Преобразуем 1/0 из SQLite в true/false для QML
                persistentRemindersCheckBox.checked = (settings.use_persistent_reminders === 1 || settings.use_persistent_reminders === true);
            }
            if (settings.sound_enabled !== undefined) {
                soundEnabledCheckBox.checked = (settings.sound_enabled === 1 || settings.sound_enabled === true);
            }
            console.log("QML: Настройки загружены");
        } else {
            console.log("QML: Не удалось загрузить настройки или они пусты");
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
        }
    }
    // --- ---

    // --- Автоматическая загрузка при открытии SettingsView ---
    Component.onCompleted: {
        // Этот код выполнится, когда компонент SettingsView будет полностью создан
        console.log("QML SettingsView: Загружен. Инициализация...");
        loadSettings();
        // loadDutyOfficers(); // Загружаем список сразу при открытии окна настроек (можно, но лучше при активации вкладки)
    }
    // --- ---
}