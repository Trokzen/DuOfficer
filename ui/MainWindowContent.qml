// ui/MainWindowContent.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import "." // Импорт из той же директории (ui/)
import "./algorithms"

Item {
    id: rootItem
    // width и height будут заданы из main.qml

    // --- Свойства для динамического масштабирования ---
    readonly property real scaleFactor: Math.min(width, height) / 600
    // --- ---

    // --- Свойство для управления текущей вкладкой в правой панели ---
    property int currentRightPanelIndex: 0 // 0-4: категории, 5: Настройки

    // --- Основной макет, разделяющий окно на 3 части по вертикали ---
    ColumnLayout {
        anchors.fill: parent
        spacing: Math.max(2, Math.floor(5 * scaleFactor)) // Динамический отступ

        // --- 1) Верхняя панель (15% высоты) ---
        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.15 // Примерно 15%
            color: "#2c3e50" // Темно-синий фон, как в военных приложениях
            border.color: "#34495e"

            // --- Используем Item вместо RowLayout для более точного контроля ---
            Item {
                anchors.fill: parent
                anchors.margins: Math.max(5, Math.floor(10 * scaleFactor)) // Динамические внешние отступы

                // --- Левая часть заголовка: НАСТРАИВАЕМОЕ Местное время и ДАТА ---
                Column {
                    id: leftHeaderContent
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: parent.width * 0.05 // 5% отступ слева
                    spacing: Math.max(2, Math.floor(5 * scaleFactor)) // Динамический внутренний отступ

                    Text {
                        // text: "Московское время" // <-- СТАРОЕ
                        text: appData.customTimeLabel // <-- НОВОЕ: Настраиваемая метка
                        // --- ЕДИНОЕ ФОРМАТИРОВАНИЕ ---
                        font.pixelSize: rootItem.scaleFactor * 14
                        color: "white" // Белый шрифт
                        // --- ---
                    }
                    Text {
                        // text: appData.currentTime + " " + appData.currentDate // <-- СТАРОЕ
                        text: appData.localTime // <-- НОВОЕ: Настраиваемое местное время
                        // --- ЕДИНОЕ ФОРМАТИРОВАНИЕ ---
                        font.pixelSize: rootItem.scaleFactor * 16
                        color: "#2ecc71" // Светло-зеленый
                        font.bold: true
                        // --- ---
                    }
                    // --- НОВОЕ: Добавляем дату отдельно ---
                    Text {
                        text: appData.localDate // Настраиваемая местная дата
                        // --- ЕДИНОЕ ФОРМАТИРОВАНИЕ ---
                        font.pixelSize: rootItem.scaleFactor * 10
                        color: "#2ecc71"
                        // --- ---
                    }
                    // --- ---
                }
                // --- ---

                // --- НОВАЯ Центральная Левая часть: Московское время и ДАТА (условно) ---
                // Размещаем её между левой частью и эмблемой
                Column {
                    id: moscowTimeHeaderContent
                    // Привязываемся к правому краю левой части + небольшой отступ
                    anchors.left: leftHeaderContent.right
                    anchors.leftMargin: parent.width * 0.03 // 3% отступ от левой части
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: Math.max(2, Math.floor(5 * scaleFactor))
                    // --- УСЛОВНОЕ ОТОБРАЖЕНИЕ ---
                    visible: appData.showMoscowTime // Отображаем ТОЛЬКО если флаг установлен
                    // --- ---

                    Text {
                        text: "Московское время" // Фиксированная подпись для Москвы
                        // --- ЕДИНОЕ ФОРМАТИРОВАНИЕ ---
                        font.pixelSize: rootItem.scaleFactor * 14
                        color: "white" // Белый шрифт
                        // --- ---
                    }
                    Text {
                        text: appData.moscowTime // НовоеМосковское время
                        // --- ЕДИНОЕ ФОРМАТИРОВАНИЕ ---
                        font.pixelSize: rootItem.scaleFactor * 16
                        color: "#2ecc71" // Светло-зеленый
                        font.bold: true
                        // --- ---
                    }
                    // --- НОВОЕ: Добавляем дату отдельно для Москвы (если нужно) ---
                    // Предполагая, что у нас есть отдельное свойство moscowDate или мы рассчитываем его
                    // Пока используем ту же дату, что и для местного времени, так как дата обычно одна
                    Text {
                        text: appData.moscowDate // Московская дата
                        font.pixelSize: rootItem.scaleFactor * 10
                        color: "#2ecc71"
                        // --- ---
                    }
                    // --- ---
                }
                // --- ---

                // --- Центральная часть - Эмблема (строго по центру) ---
                Image {
                    id: emblem
                    anchors.centerIn: parent
                    // --- ИЗМЕНЕНО: Привязка к appData.backgroundImagePath ---
                    // source: "../resources/images/placeholder_emblem.png" // <-- СТАРОЕ
                    source: {
                        var imagePath = appData.backgroundImagePath; // Получаем путь из Python
                        console.log("QML MainWindowContent: emblem.source запрашивает путь к эмблеме из appData:", imagePath);
                        if (imagePath && imagePath !== "") {
                            // Если путь задан, используем его
                            // Добавляем префикс "file:///" для локальных файлов
                            var fullPath = "file:///" + imagePath;
                            console.log("QML MainWindowContent: emblem.source использует путь к эмблеме:", fullPath);
                            return fullPath;
                        } else {
                            // Если путь не задан или пуст, используем заглушку
                            console.log("QML MainWindowContent: emblem.source использует заглушку для эмблемы.");
                            return "../resources/images/placeholder_emblem.png";
                        }
                    }
                    // --- ---
                    fillMode: Image.PreserveAspectFit
                    // --- Увеличение эмблемы на ~20% ---
                    height: parent.height * 0.96 // 0.8 * 1.2 = 0.96
                    width: height // Сохраняем пропорции
                }
                // --- ---

                // --- Правая часть заголовка (информация о посте и дежурный) ---
                Column {
                    id: rightHeaderContent
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.rightMargin: parent.width * 0.05 // 5% отступ справа
                    spacing: Math.max(3, Math.floor(8 * scaleFactor))

                    Text {
                        text: appData.workplaceName // Это будет связано с настройками
                        font.pixelSize: rootItem.scaleFactor * 18
                        font.bold: true
                        color: "white"
                        elide: Text.ElideRight // Обрезаем, если длинное
                    }
                    Text {
                        text: appData.postName // Это будет связано с настройками
                        font.pixelSize: rootItem.scaleFactor * 14
                        color: "white"
                        elide: Text.ElideRight
                    }
                    // --- Изменение ширины кнопки дежурного ---
                         // --- Изменение ширины кнопки дежурного ---
                    Button {
                        id: dutyOfficerButton // <-- Убедимся, что ID установлен
                        // --- ЯВНАЯ привязка текста ---
                        property string dutyOfficerText: "Дежурный: " + appData.dutyOfficer // <-- Привязка к свойству Python
                        text: dutyOfficerButton.dutyOfficerText // <-- Явное использование свойства
                        // --- ---
                        font.pixelSize: rootItem.baseFontSize
                        // --- Отступ снизу ~5% от высоты заголовка ---
                        anchors.bottomMargin: parent.height * 0.05
                        // --- Уменьшение ширины на ~33% ---
                        implicitHeight: Math.max(25, Math.floor(20 * scaleFactor))
                        implicitWidth: Math.min(parent.width * 1.5, Math.max(150, Math.floor(200 * scaleFactor))) // ~134 = 200 * 0.67
                        // --- ---
                        background: Rectangle {
                            color: "transparent"
                            border.color: "#3498db"
                            radius: Math.max(2, Math.floor(4 * scaleFactor))
                        }
                        contentItem: Text {
                            text: parent.text
                            color: "#3498db"
                            font.pixelSize: parent.font.pixelSize
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        // --- Добавим отладку на изменение текста ---
                        onTextChanged: {
                            console.log("QML MainWindowContent: Текст кнопки дежурного изменился на:", text);
                        }
                        // --- ---
                        onClicked: {
                            console.log("QML MainWindowContent: Кнопка выбора дежурного нажата.");
                            // --- ИЗМЕНЕНО: Запрашиваем список ВСЕХ пользователей ---
                            // var officersList = appData.getDutyOfficersList(); // <-- Старый вызов
                            var officersList = appData.getAllDutyOfficersList(); // <-- Новый вызов
                            // --- ---
                            console.log("QML MainWindowContent: Получен список всех пользователей для выбора дежурного:", JSON.stringify(officersList));

                            // --- НОВОЕ: Открываем Popup для выбора ---
                            // Передаем список в Popup
                            dutyOfficerSelectionPopup.loadOfficersList(officersList);
                            dutyOfficerSelectionPopup.open();
                            // --- ---
                        }
                    }
                    // --- ---
                    // --- ЯВНОЕ обновление текста кнопки при изменении свойства в Python ---
                    Connections {
                        target: appData
                        function onDutyOfficerChanged() {
                            console.log("QML MainWindowContent: Получен сигнал dutyOfficerChanged от Python.");
                            console.log("QML MainWindowContent: appData.dutyOfficer =", appData.dutyOfficer);
                            // Явно обновляем текст кнопки
                            if (dutyOfficerButton) { // Проверяем, существует ли кнопка
                                var newText = "Дежурный: " + appData.dutyOfficer;
                                console.log("QML MainWindowContent: Установка текста кнопки дежурного на:", newText);
                                dutyOfficerButton.dutyOfficerText = newText; // <-- Обновляем свойство
                                console.log("QML MainWindowContent: Текст кнопки дежурного обновлен.");
                            } else {
                                console.warn("QML MainWindowContent: Кнопка дежурного (dutyOfficerButton) не найдена!");
                            }
                        }
                    }
                    // --- ---
                }
                // --- ---
            }
        }
        // --- ---

        // --- 2) Средняя панель (80% высоты теперь) ---
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true // Занимает оставшееся пространство (~80%)
            color: "#ecf0f1" // Светло-серый фон

            RowLayout {
                anchors.fill: parent
                anchors.margins: Math.max(3, Math.floor(5 * scaleFactor))
                spacing: Math.max(5, Math.floor(10 * scaleFactor))

                // --- Левая часть (25% ширины) - Кнопки категорий ---
                ColumnLayout {
                    Layout.preferredWidth: parent.width * 0.25
                    Layout.fillHeight: true
                    spacing: Math.max(5, Math.floor(10 * scaleFactor))

                    Repeater {
                        model: ListModel {
                            // --- Перемещаем "Мероприятия" в начало ---
                            ListElement { text: "Мероприятия" }
                            // --- ---
                            ListElement { text: "Повседневная деятельность" }
                            ListElement { text: "Боевая готовность" }
                            ListElement { text: "Противодействие терроризму" }
                            ListElement { text: "Кризисные ситуации" }
                        }
                        // --- Кнопки категорий ---
                        Button {
                            text: model.text
                            Layout.fillWidth: true
                            // --- Корректируем высоту для первой кнопки ("Мероприятия") ---
                            Layout.preferredHeight: index === 0 ? parent.height * 0.18 : parent.height * 0.15 // Первая кнопка чуть выше
                            // --- ---
                            font.pixelSize: rootItem.scaleFactor * 12
                            // --- Выделяем активную кнопку КАТЕГОРИИ ---
                            // Активна, если currentRightPanelIndex совпадает с индексом категории (0-4)
                            background: Rectangle {
                                color: (index === rootItem.currentRightPanelIndex && rootItem.currentRightPanelIndex < 5) ? "#2980b9" : "#3498db"
                                radius: Math.max(4, Math.floor(8 * scaleFactor))
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
                                // При клике на категорию устанавливаем соответствующий индекс (0-4)
                                rootItem.currentRightPanelIndex = index;
                            }
                        }
                    }
                    // Заполнитель
                    Item {
                        Layout.fillHeight: true
                    }
                }

                // --- Правая часть (75% ширины) - Содержимое мероприятий и настроек ---
                Rectangle {
                     Layout.preferredWidth: parent.width * 0.75
                     Layout.fillHeight: true
                     color: "white"
                     border.color: "#bdc3c7"
                     radius: Math.max(3, Math.floor(5 * scaleFactor))

                     // --- StackLayout для переключения между категориями и настройками ---
                     StackLayout {
                         id: rightPanelStackLayout
                         anchors.fill: parent
                         anchors.margins: Math.max(10, Math.floor(15 * scaleFactor))
                         // --- Связываем currentIndex с нашим свойством ---
                         currentIndex: rootItem.currentRightPanelIndex

                         // --- Вкладка 0: Мероприятия (ПЕРЕМЕЩЕНА ВВЕРХ) ---
                         Item {
                             ColumnLayout {
                                 anchors.fill: parent
                                 Text {
                                     text: "Содержимое вкладки: Мероприятия"
                                     font.pixelSize: rootItem.scaleFactor * 12
                                 }
                                 Text {
                                     text: "Здесь будет отображаться список всех мероприятий из всех алгоритмов."
                                     color: "gray"
                                 }
                                 // Заполнитель
                                 Item {
                                     Layout.fillHeight: true
                                 }
                             }
                         }
                         // --- ---

                         // --- Вкладка 1: Повседневная деятельность ---
                         Item { // Заглушка
                             ColumnLayout {
                                 anchors.fill: parent
                                 Text {
                                     text: "Содержимое вкладки: Повседневная деятельность"
                                     font.pixelSize: rootItem.scaleFactor * 12
                                 }
                                 // --- НОВОЕ: Вставка RunningAlgorithmsView ---
                                 RunningAlgorithmsView {
                                     id: runningAlgorithmsView1
                                     Layout.fillWidth: true
                                     Layout.fillHeight: true
                                     categoryFilter: "повседневная деятельность" // <-- Передаем фильтр категории
                                 }
                                 // --- ---
                                 // Заполнитель (можно удалить, если RunningAlgorithmsView заполняет всё)
                                 // Item {
                                 //     Layout.fillHeight: true
                                 // }
                             }
                         }
                         // --- ---

                         // --- Вкладка 2: Боевая готовность ---
                         Item { // Заглушка
                             ColumnLayout {
                                 anchors.fill: parent
                                 Text {
                                     text: "Содержимое вкладки: Боевая готовность"
                                     font.pixelSize: rootItem.scaleFactor * 12
                                 }
                                 // --- НОВОЕ: Вставка RunningAlgorithmsView ---
                                 RunningAlgorithmsView {
                                     id: runningAlgorithmsView2
                                     Layout.fillWidth: true
                                     Layout.fillHeight: true
                                     categoryFilter: "боевая готовность" // <-- Передаем фильтр категории
                                 }
                                 // --- ---
                                 // Заполнитель (можно удалить, если RunningAlgorithmsView заполняет всё)
                                 // Item {
                                 //     Layout.fillHeight: true
                                 // }
                             }
                         }
                         // --- ---

                         // --- Вкладка 3: Противодействие терроризму ---
                         Item { // Заглушка
                             ColumnLayout {
                                 anchors.fill: parent
                                 Text {
                                     text: "Содержимое вкладки: Противодействие терроризму"
                                     font.pixelSize: rootItem.scaleFactor * 12
                                 }
                                 // --- НОВОЕ: Вставка RunningAlgorithmsView ---
                                 RunningAlgorithmsView {
                                     id: runningAlgorithmsView3
                                     Layout.fillWidth: true
                                     Layout.fillHeight: true
                                     categoryFilter: "противодействие терроризму" // <-- Передаем фильтр категории
                                 }
                                 // --- ---
                                 // Заполнитель (можно удалить, если RunningAlgorithmsView заполняет всё)
                                 // Item {
                                 //     Layout.fillHeight: true
                                 // }
                             }
                         }
                         // --- ---

                         // --- Вкладка 4: Кризисные ситуации ---
                         Item { // Заглушка
                             ColumnLayout {
                                 anchors.fill: parent
                                 Text {
                                     text: "Содержимое вкладки: Кризисные ситуации"
                                     font.pixelSize: rootItem.scaleFactor * 12
                                 }
                                 // --- НОВОЕ: Вставка RunningAlgorithmsView ---
                                 RunningAlgorithmsView {
                                     id: runningAlgorithmsView4
                                     Layout.fillWidth: true
                                     Layout.fillHeight: true
                                     categoryFilter: "кризисные ситуации" // <-- Передаем фильтр категории
                                 }
                                 // --- ---
                                 // Заполнитель (можно удалить, если RunningAlgorithmsView заполняет всё)
                                 // Item {
                                 //     Layout.fillHeight: true
                                 // }
                             }
                         }
                         // --- ---

                         // --- Вкладка 5: Настройки (возвращаем старую логику) ---
                         SettingsView {
                             id: settingsView
                             anchors.fill: parent
                         }
                         // --- ---
                     }

                    StartNewAlgorithmDialog {
                        id: startNewAlgorithmDialog1
                        // Подключаем сигнал к соответствующему RunningAlgorithmsView
                        Connections {
                            target: startNewAlgorithmDialog1
                            function onAlgorithmStarted(executionData) {
                                console.log("MainWindowContent: Диалог 1 сообщил о запуске. Обновляем View 1.");
                                runningAlgorithmsView1.loadExecutions(); // Перезагружаем список для соответствующей вкладки
                            }
                        }
                    }
                    StartNewAlgorithmDialog {
                        id: startNewAlgorithmDialog2
                        // Подключаем сигнал к соответствующему RunningAlgorithmsView
                        Connections {
                            target: startNewAlgorithmDialog2
                            function onAlgorithmStarted(executionData) {
                                console.log("MainWindowContent: Диалог 2 сообщил о запуске. Обновляем View 2.");
                                runningAlgorithmsView1.loadExecutions(); // Перезагружаем список для соответствующей вкладки
                            }
                        }
                    }

                    StartNewAlgorithmDialog {
                        id: startNewAlgorithmDialog3
                        // Подключаем сигнал к соответствующему RunningAlgorithmsView
                        Connections {
                            target: startNewAlgorithmDialog3
                            function onAlgorithmStarted(executionData) {
                                console.log("MainWindowContent: Диалог 3 сообщил о запуске. Обновляем View 3.");
                                runningAlgorithmsView1.loadExecutions(); // Перезагружаем список для соответствующей вкладки
                            }
                        }
                    }

                    StartNewAlgorithmDialog {
                        id: startNewAlgorithmDialog4
                        // Подключаем сигнал к соответствующему RunningAlgorithmsView
                        Connections {
                            target: startNewAlgorithmDialog4
                            function onAlgorithmStarted(executionData) {
                                console.log("MainWindowContent: Диалог 4 сообщил о запуске. Обновляем View 4.");
                                runningAlgorithmsView1.loadExecutions(); // Перезагружаем список для соответствующей вкладки
                            }
                        }
                    }
                }
            }
        }
        // --- ---

        // --- 3) Нижняя панель (5% высоты теперь) ---
        Rectangle {
            id: footer
            Layout.fillWidth: true
            Layout.preferredHeight: parent.height * 0.05 // (~5%)
            color: "#34495e" // Темно-серый фон

            Row {
                id: footerRow
                anchors.fill: parent
                anchors.margins: Math.max(3, Math.floor(5 * scaleFactor))
                spacing: (width - 4 * (width * 0.20)) / 3

                Repeater {
                     model: ListModel {
                         ListElement { text: "О программе" }
                         ListElement { text: "Учет личного состава" }
                         ListElement { text: "Настройки" } // <-- Эта кнопка переключает StackLayout на вкладку 5
                         ListElement { text: "(По согласованию)" }
                     }
                     Button {
                         width: parent.width * 0.20
                         anchors.verticalCenter: parent.verticalCenter
                         height: parent.height * 0.8
                         text: model.text
                         font.pixelSize: rootItem.scaleFactor * 10
                         // --- Выделяем активную кнопку НАСТРОЕК ---
                         // Активна, если currentRightPanelIndex равен 5 (индекс Настроек)
                         background: Rectangle {
                             // Проверяем, является ли эта кнопка "Настройки" (index==2) и активна ли она
                             color: (index === 2 && rootItem.currentRightPanelIndex === 5) ? "#2980b9" : "#7f8c8d"
                             radius: Math.max(2, Math.floor(4 * scaleFactor))
                         }
                         contentItem: Text {
                             text: parent.text
                             color: "white"
                             font.pixelSize: parent.font.pixelSize
                             horizontalAlignment: Text.AlignHCenter
                             verticalAlignment: Text.AlignVCenter
                         }
                         onClicked: {
                             // Если нажата кнопка "Настройки" (index 2 в модели нижней панели)
                             if (index === 2) {
                                 // Устанавливаем индекс на "Настройки" (5)
                                 rootItem.currentRightPanelIndex = 5;
                                 // Вызываем метод onOpened у SettingsView для загрузки настроек
                                 if (settingsView.onOpened) {
                                     settingsView.onOpened();
                                 }
                             } else {
                                 // Для других кнопок нижней панели (О программе, Учет, По согласованию)
                                 console.log("Нажата кнопка нижней панели: " + model.text);
                                 // Можно реализовать другую логику или оставить пустой
                             }
                         }
                     }
                 }
            }
        }
    }
    // --- Конец ColumnLayout ---

    // --- НОВОЕ: Popup для выбора дежурного ---
    Popup {
        id: dutyOfficerSelectionPopup
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2
        width: Math.min(parent.width * 0.5, 400) // 50% ширины или максимум 400
        height: Math.min(parent.height * 0.6, 400) // 60% высоты или максимум 400
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            color: "white"
            border.color: "lightgray"
            radius: 5
        }

        // --- Свойства для хранения списка ---
        // --- ИЗМЕНЕНО: Используем ListModel вместо обычного массива JS ---
        // property var officersListModel: [] // <-- СТАРОЕ
        property alias officersListModel: officersListInternalModel // <-- НОВОЕ: Проксируем внутреннюю модель
        // --- ---

        // --- Основной столбец для элементов диалога ---
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15
            spacing: 15

            Label {
                text: "Выберите дежурного"
                font.pointSize: 14
                font.bold: true
            }

            // Список должностных лиц
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: officersListView
                    // --- ИЗМЕНЕНО: Используем внутреннюю ListModel ---
                    // model: dutyOfficerSelectionPopup.officersListModel // <-- СТАРОЕ
                    model: ListModel { id: officersListInternalModel } // <-- НОВОЕ
                    // --- ---
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
                                // При клике на элемент списка
                                // --- ИЗМЕНЕНО: Не сериализуем весь model ---
                                // console.log("QML DutyOfficerSelectionPopup: Выбран дежурный:", JSON.stringify(model)); // <-- СТАРОЕ (вызывает ошибку)
                                console.log("QML DutyOfficerSelectionPopup: Выбран дежурный с ID:", model.id); // <-- НОВОЕ
                                // --- ---
                                // --- Отправляем ID выбранного дежурного в Python ---
                                // Вызываем слот Python для установки текущего дежурного
                                appData.setCurrentDutyOfficer(model.id); // <-- Используем ID из модели
                                // --- ---
                                // Закрываем Popup
                                dutyOfficerSelectionPopup.close();
                            }
                        }
                    }
                    // --- ---
                }
            }

            // Кнопка отмены
            RowLayout {
                Layout.fillWidth: true
                spacing: 10
                Item { Layout.fillWidth: true } // Заполнитель слева
                Button {
                    text: "Отмена"
                    onClicked: {
                        console.log("QML DutyOfficerSelectionPopup: Нажата кнопка Отмена");
                        dutyOfficerSelectionPopup.close(); // Просто закрываем
                    }
                }
            }
        }

        // --- Функция для загрузки списка из Python ---
        function loadOfficersList(list) {
            console.log("QML DutyOfficerSelectionPopup: Загрузка списка должностных лиц из Python...");
            console.log("QML DutyOfficerSelectionPopup: Получен список (сырой):", JSON.stringify(list));
            
            // --- НОВОЕ: Преобразование QJSValue/QVariant в массив JS ---
            // Если list - это QJSValue (из Python), преобразуем его
            if (list && typeof list === 'object' && list.hasOwnProperty('toVariant')) {
                list = list.toVariant();
                console.log("QML DutyOfficerSelectionPopup: QJSValue (list) преобразован в:", JSON.stringify(list));
            }
            // --- ---

            // --- ИЗМЕНЕНО: Очищаем внутреннюю ListModel ---
            // dutyOfficerSelectionPopup.officersListModel = []; // <-- СТАРОЕ
            officersListInternalModel.clear(); // <-- НОВОЕ: Очищаем внутреннюю модель
            // --- ---
            console.log("QML DutyOfficerSelectionPopup: Модель ListView очищена.");

            // --- ИЗМЕНЕНО: Более гибкая проверка на "массивоподобность" ---
            // Вместо Array.isArray, проверяем, есть ли у объекта свойство length (не undefined)
            if (list && typeof list === 'object' && list.length !== undefined) {
            // --- ---
                var count = list.length;
                console.log("QML DutyOfficerSelectionPopup: Полученный список является массивоподобным. Количество элементов:", count);
                // Заполняем модель данными по одному
                for (var i = 0; i < count; i++) {
                    var officer = list[i];
                    console.log("QML DutyOfficerSelectionPopup: Обрабатываем элемент", i, ":", JSON.stringify(officer)); // Лог каждого элемента
                    // Убедимся, что элемент - это объект
                    if (typeof officer === 'object' && officer !== null) {
                        // --- ИЗМЕНЕНО: Добавляем в ListModel, а не в массив JS ---
                        // try {
                        //     dutyOfficerSelectionPopup.officersListModel.push(officer); // <-- СТАРОЕ
                        //     console.log("QML DutyOfficerSelectionPopup: Элемент", i, "добавлен в модель.");
                        // } catch (e) {
                        //     console.error("QML DutyOfficerSelectionPopup: Ошибка при добавлении элемента", i, "в модель:", e.toString(), "Данные:", JSON.stringify(officer));
                        // }
                        
                        // --- НОВОЕ: Явное копирование свойств и добавление в ListModel ---
                        try {
                            // Создаем копию объекта, чтобы избежать проблем с QJSValue
                            var officerCopy = ({
                                "id": officer["id"],
                                "rank": officer["rank"],
                                "last_name": officer["last_name"],
                                "first_name": officer["first_name"],
                                "middle_name": officer["middle_name"],
                                "phone": officer["phone"],
                                "is_active": officer["is_active"],
                                "is_admin": officer["is_admin"],
                                "login": officer["login"]
                                // Добавьте другие поля, если они нужны для отображения в списке
                            });
                            officersListInternalModel.append(officerCopy); // <-- НОВОЕ: Добавляем КОПИЮ в ListModel
                            console.log("QML DutyOfficerSelectionPopup: Элемент", i, "добавлен в модель ListModel.");
                        } catch (e_append) {
                            console.error("QML DutyOfficerSelectionPopup: Ошибка при добавлении элемента", i, "в ListModel:", e_append.toString(), "Данные:", JSON.stringify(officer));
                        }
                        // --- ---
                    } else {
                        console.warn("QML DutyOfficerSelectionPopup: Элемент", i, "не является корректным объектом:", typeof officer, officer);
                    }
                }
            } else {
                // --- ИЗМЕНЕНО: Сообщение об ошибке ---
                console.error("QML DutyOfficerSelectionPopup: Python не вернул корректный массивоподобный объект. Получен тип:", typeof list, "Значение:", list);
                // --- ---
            }
            // --- ИЗМЕНЕНО: Выводим количество элементов в ListModel ---
            // console.log("QML DutyOfficerSelectionPopup: Модель ListView обновлена. Элементов:", dutyOfficerSelectionPopup.officersListModel.length);
            console.log("QML DutyOfficerSelectionPopup: Модель ListView (ListModel) обновлена. Элементов:", officersListInternalModel.count); // <-- НОВОЕ
            // --- ---
            // --- ДОБАВЛЕНО: Отладка содержимого модели ---
            if (officersListInternalModel.count > 0) {
                 try {
                     console.log("QML DutyOfficerSelectionPopup: Первый элемент в модели (ListModel):", JSON.stringify(officersListInternalModel.get(0)));
                 } catch (e_get) {
                     console.warn("QML DutyOfficerSelectionPopup: Не удалось сериализовать первый элемент модели (ListModel) для лога:", e_get.toString());
                     // Попробуем получить отдельные свойства
                     var firstItem = officersListInternalModel.get(0);
                     if (firstItem) {
                         console.log("QML DutyOfficerSelectionPopup: Первый элемент в модели (ListModel) (свойства): id=", firstItem.id, "rank=", firstItem.rank, "last_name=", firstItem.last_name);
                     }
                 }
            }
            // --- ---
        }
        // --- ---
    }
    // --- ---

    // --- Connections для обработки ЗАПРОСА НА ОТКРЫТИЕ ДИАЛОГА от КАЖДОГО VIEW ---
    // Эти Connections находятся на уровне rootItem, чтобы они могли ссылаться на
    // и диалоги (startNewAlgorithmDialog1-4), и на view (runningAlgorithmsView1-4).
    Connections {
        target: runningAlgorithmsView1
        function onStartNewAlgorithmRequested(category) {
            console.log("MainWindowContent: Получен запрос на запуск от View1 для категории:", category);
            // Открываем соответствующий диалог
            startNewAlgorithmDialog1.categoryFilter = category; // Передаём категорию
            startNewAlgorithmDialog1.resetForAdd(); // Сбрасываем диалог
            startNewAlgorithmDialog1.open(); // Открываем
        }
    }

    Connections {
        target: runningAlgorithmsView2
        function onStartNewAlgorithmRequested(category) {
             console.log("MainWindowContent: Получен запрос на запуск от View2 для категории:", category);
             startNewAlgorithmDialog2.categoryFilter = category;
             startNewAlgorithmDialog2.resetForAdd();
             startNewAlgorithmDialog2.open();
        }
    }

    Connections {
        target: runningAlgorithmsView3
        function onStartNewAlgorithmRequested(category) {
             console.log("MainWindowContent: Получен запрос на запуск от View3 для категории:", category);
             startNewAlgorithmDialog3.categoryFilter = category;
             startNewAlgorithmDialog3.resetForAdd();
             startNewAlgorithmDialog3.open();
        }
    }

    Connections {
        target: runningAlgorithmsView4
        function onStartNewAlgorithmRequested(category) {
             console.log("MainWindowContent: Получен запрос на запуск от View4 для категории:", category);
             startNewAlgorithmDialog4.categoryFilter = category;
             startNewAlgorithmDialog4.resetForAdd();
             startNewAlgorithmDialog4.open();
        }
    }

}
