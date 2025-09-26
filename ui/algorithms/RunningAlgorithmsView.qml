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
    // Сигнал, который будет эмитироваться при нажатии кнопки "Запустить новый алгоритм"
    signal startNewAlgorithmRequested(string category)
    // Сигнал, который будет эмитироваться при нажатии кнопки "Завершить"
    signal finishAlgorithmRequested(int executionId)
    // Сигнал, который будет эмитироваться при нажатии кнопки "Развернуть"
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
                onClicked: {
                    console.log("QML RunningAlgorithmsView: Запрошено открытие диалога запуска для категории:", categoryFilter);
                    // Эмитируем сигнал, который будет пойман в MainWindowContent.qml
                    runningAlgorithmsViewRoot.startNewAlgorithmRequested(categoryFilter);
                }
            }

            Item {
                Layout.fillWidth: true // Заполнитель
            }

            // --- Календарь (пока заглушка) ---
            Button {
                text: "Календарь"
                onClicked: {
                    console.log("QML RunningAlgorithmsView: Нажата кнопка Календарь для категории:", categoryFilter);
                    // TODO: Открыть CalendarView
                    // Можно передать categoryFilter в CalendarView
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
                spacing: 5 // Небольшой отступ между элементами

                delegate: Rectangle {
                    width: ListView.view.width
                    height: implicitHeight // Позволяем высоте определяться содержимым
                    color: index % 2 ? "#f9f9f9" : "#ffffff"
                    border.color: executionsListView.currentIndex === index ? "#3498db" : "#ddd"
                    border.width: 1
                    radius: 3

                    // Используем ColumnLayout для вертикального размещения элементов
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 8 // Отступы внутри элемента
                        spacing: 4

                        // Название алгоритма
                        Text {
                            Layout.fillWidth: true
                            text: model.algorithm_name || "Без названия"
                            font.bold: true
                            elide: Text.ElideRight
                            color: "black"
                        }

                        // Ответственный
                        Text {
                            Layout.fillWidth: true
                            text: "Ответственный: " + (model.created_by_user_display_name || "Не назначен")
                            color: "gray"
                            font.pixelSize: 11
                            elide: Text.ElideRight
                        }

                        // Статус и время
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Text {
                                text: "Статус: " + (model.status || "неизвестен")
                                color: model.status === "completed" ? "green" : (model.status === "cancelled" ? "red" : "gray")
                                font.pixelSize: 10
                            }

                            Item {
                                Layout.fillWidth: true
                            }

                            Text {
                                text: "Начало: " + (model.started_at || "—")
                                color: "gray"
                                font.pixelSize: 10
                            }
                        }

                        // Кнопки управления (размещаем в RowLayout)
                        RowLayout {
                            Layout.alignment: Qt.AlignRight // Выравнивание кнопок по правому краю
                            spacing: 5

                            Button {
                                text: "Завершить"
                                font.pixelSize: 10
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
                                font.pixelSize: 10
                                onClicked: {
                                    console.log("QML RunningAlgorithmsView: Запрошено развертывание execution ID:", model.id);
                                    // Вызываем сигнал, который может обрабатываться родителем
                                    runningAlgorithmsViewRoot.expandAlgorithmRequested(model.id);
                                    // Или открываем диалог деталей напрямую (если будет реализован)
                                    // algorithmExecutionDetailsDialog.executionId = model.id;
                                    // algorithmExecutionDetailsDialog.open();
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: executionsListView.currentIndex = index
                    }
                }

                // Индикатор загрузки или пустого списка (опционально)
                header: Item {
                    width: ListView.view.width
                    height: 30 // Высота индикатора
                    visible: executionsModel.count === 0 // Показываем, только если список пуст после загрузки

                    Text {
                        anchors.centerIn: parent
                        text: categoryFilter ? "Нет запущенных алгоритмов" : "Выберите категорию"
                        color: "gray"
                        font.italic: true
                    }
                }
            }
        }
        // --- ---
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
        console.log("QML RunningAlgorithmsView: Получен список executions из Python (сырой):", JSON.stringify(executionsList).substring(0, 500));

        // --- Преобразование QJSValue/QVariant в массив JS ---
        if (executionsList && typeof executionsList === 'object' && typeof executionsList.hasOwnProperty === 'function' && executionsList.hasOwnProperty('toVariant')) {
            console.log("QML RunningAlgorithmsView: Обнаружен QJSValue, преобразование в JS-объект...");
            executionsList = executionsList.toVariant();
            console.log("QML RunningAlgorithmsView: QJSValue преобразован. Первые 500 символов:", JSON.stringify(executionsList).substring(0, 500));
        } else {
            console.log("QML RunningAlgorithmsView: Преобразование QJSValue не требуется.");
        }
        // --- ---

        // --- Очистка модели ---
        console.log("QML RunningAlgorithmsView: Очистка модели ListView executions...");
        var oldCount = executionsModel.count;
        executionsModel.clear();
        console.log("QML RunningAlgorithmsView: Модель очищена. Было элементов:", oldCount, "Стало:", executionsModel.count);
        // --- ---

        // --- Заполнение модели ---
        // --- ИЗМЕНЕНО: Более гибкая проверка на "массивоподобность" ---
        if (executionsList && typeof executionsList === 'object' && executionsList.length !== undefined) {
        // --- ---
            var count = executionsList.length;
            console.log("QML RunningAlgorithmsView: Полученный список является массивоподобным. Количество элементов:", count);

            if (count === 0) {
                console.log("QML RunningAlgorithmsView: Список executions пуст для категории:", categoryFilter);
            }

            for (var i = 0; i < count; i++) {
                var execution = executionsList[i];
                console.log("QML RunningAlgorithmsView: Обрабатываем execution", i, ":", JSON.stringify(execution).substring(0, 200));

                if (typeof execution === 'object' && execution !== null) {
                    try {
                        // --- Явное копирование свойств ---
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
                        // --- ---

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
        // --- ---
    }

    // --- Загрузка при изменении categoryFilter ---
    onCategoryFilterChanged: {
        console.log("QML RunningAlgorithmsView: categoryFilter изменился на:", categoryFilter);
        runningAlgorithmsViewRoot.loadExecutions();
    }

    Component.onCompleted: {
        console.log("QML RunningAlgorithmsView: Загружен. Категория:", categoryFilter);
        // Загружаем сразу, если categoryFilter уже задан
        if (categoryFilter && categoryFilter !== "") {
            runningAlgorithmsViewRoot.loadExecutions();
        }
    }
}