// ui/algorithms/RunningAlgorithmsView.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5

Item {
    id: runningAlgorithmsViewRoot

    // --- Свойства ---
    property string categoryFilter: "" // Фильтр по категории алгоритмов
    // --- ---

    // --- Сигналы ---
    signal startNewAlgorithmRequested(string category)
    signal finishAlgorithmRequested(int executionId)
    signal expandAlgorithmRequested(int executionId)
    // --- ---

    ListModel {
        id: executionsModel
    }

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
            
            Button {
                text: "Календарь"
                onClicked: {
                    console.log("QML RunningAlgorithmsView: Нажата кнопка Календарь для категории:", categoryFilter);
                    // TODO: Открыть CalendarView
                }
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
                    height: contentColumn.implicitHeight + 2 * padding // Высота зависит от содержимого
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
                        id: contentColumn
                        anchors.fill: parent
                        anchors.margins: padding // Отступы внутри элемента
                        spacing: 6

                        // Название алгоритма (жирный шрифт)
                        Text {
                            Layout.fillWidth: true
                            text: model.algorithm_name || "Без названия"
                            font.bold: true
                            font.pixelSize: rootItem.scaleFactor * 12 // Используем scaleFactor
                            elide: Text.ElideRight
                            color: "black"
                        }

                        // Ответственный
                        Text {
                            Layout.fillWidth: true
                            text: "Ответственный: " + (model.created_by_user_display_name || "Не назначен")
                            color: "gray"
                            font.pixelSize: rootItem.scaleFactor * 10
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
                                    font.pixelSize: rootItem.scaleFactor * 9
                                    font.bold: true
                                }
                            }

                            Item { Layout.fillWidth: true } // Заполнитель

                            // Время начала
                            Text {
                                text: "Начат: " + (model.started_at || "—")
                                color: "gray"
                                font.pixelSize: rootItem.scaleFactor * 10
                                elide: Text.ElideRight
                            }
                        }

                        // Кнопки управления (размещаем в отдельной строке, прижатой к правому краю)
                        RowLayout {
                            Layout.alignment: Qt.AlignRight // Выравнивание кнопок по правому краю
                            spacing: 8 // Немного больше отступа между кнопками

                            Button {
                                text: "Завершить"
                                font.pixelSize: rootItem.scaleFactor * 10
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
                                font.pixelSize: rootItem.scaleFactor * 10
                                onClicked: {
                                    console.log("QML RunningAlgorithmsView: Запрошено развертывание execution ID:", model.id);
                                    runningAlgorithmsViewRoot.expandAlgorithmRequested(model.id);
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
                        font.pixelSize: rootItem.scaleFactor * 12
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
     * Загружает список запущенных алгоритмов для заданной категории
     */
    function loadExecutions() {
        if (!categoryFilter || categoryFilter === "") {
            console.warn("QML RunningAlgorithmsView: categoryFilter не задан, пропускаем загрузку.");
            executionsModel.clear();
            return;
        }

        console.log("QML RunningAlgorithmsView: Запрос списка активных executions для категории:", categoryFilter);
        var executionsList = appData.getActiveExecutionsByCategory(categoryFilter);

        // Преобразование QJSValue/QVariant в массив JS
        if (executionsList && typeof executionsList === 'object' && typeof executionsList.hasOwnProperty === 'function' && executionsList.hasOwnProperty('toVariant')) {
            console.log("QML RunningAlgorithmsView: Обнаружен QJSValue, преобразование в JS-объект...");
            executionsList = executionsList.toVariant();
            console.log("QML RunningAlgorithmsView: QJSValue преобразован.");
        } else {
            console.log("QML RunningAlgorithmsView: Преобразование QJSValue не требуется.");
        }

        // Очистка модели
        console.log("QML RunningAlgorithmsView: Очистка модели ListView executions...");
        executionsModel.clear();

        // Заполнение модели
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
                            "started_at": execution["started_at"] || "",
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
    }
}