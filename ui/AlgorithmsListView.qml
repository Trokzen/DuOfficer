// ui/AlgorithmsListView.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5

Item {
    id: algorithmsListViewRoot

    // Сигналы для уведомления родителя о действиях
    signal algorithmSelected(var algorithmData)
    signal addAlgorithmRequested()
    signal editAlgorithmRequested(var algorithmData)
    signal deleteAlgorithmRequested(var algorithmId)
    signal duplicateAlgorithmRequested(var algorithmId)
    // --- НОВЫЙ СИГНАЛ для редактирования действий ---
    signal editActionsRequested(var algorithmData)
    // --- ---

    RowLayout {
        anchors.fill: parent
        spacing: 10

        // --- Основная область: Заголовок и список алгоритмов (70% ширины) ---
        ColumnLayout {
            Layout.preferredWidth: parent.width * 0.7 // 70% ширины
            Layout.fillHeight: true
            spacing: 10

            Label {
                text: "Список алгоритмов"
                font.pointSize: 14
                font.bold: true
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ListView {
                    id: listView
                    model: ListModel {
                        id: algorithmsModel
                    }
                    delegate: Rectangle {
                        width: ListView.view.width
                        // Увеличиваем высоту, чтобы вместить дополнительную информацию
                        height: 80 
                        // --- Цвет фона и рамки с выделением ---
                        color: {
                            if (listView.currentIndex === index) {
                                return "#3498db"; // Цвет выделенного
                            } else {
                                return index % 2 ? "#f9f9f9" : "#ffffff"; // Чередующийся
                            }
                        }
                        border.color: listView.currentIndex === index ? "#2980b9" : "#ddd"
                        // Плавные переходы цветов
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Behavior on border.color { ColorAnimation { duration: 100 } }

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 5
                            spacing: 2

                            Text {
                                Layout.fillWidth: true
                                // --- Цвет текста ---
                                color: listView.currentIndex === index ? "white" : "black"
                                // --- ---
                                text: model.name
                                font.bold: true
                                font.pointSize: 11 // Немного увеличим шрифт названия
                                elide: Text.ElideRight
                            }
                            // --- Обновленное отображение категории и времени ---
                            Text {
                                Layout.fillWidth: true
                                // --- Цвет текста ---
                                color: listView.currentIndex === index ? "#e0e0e0" : "gray"
                                // --- ---
                                // Формат: "Категория: <категория>"
                                text: "Категория: " + (model.category || "")
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                // --- Цвет текста ---
                                color: listView.currentIndex === index ? "#e0e0e0" : "gray"
                                // --- ---
                                // Формат: "Время: (<тип времени>)"
                                text: "Время: " + (model.time_type || "")
                                font.pixelSize: 10
                                elide: Text.ElideRight
                            }
                            // --- ---
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                listView.currentIndex = index;
                                // Передаем копию данных алгоритма
                                algorithmsListViewRoot.algorithmSelected({
                                    "id": model.id,
                                    "name": model.name,
                                    "category": model.category,
                                    "time_type": model.time_type,
                                    "description": model.description
                                });
                            }
                            // --- ДОБАВЛЕНО: Обработка двойного клика для редактирования ---
                            onDoubleClicked: {
                                listView.currentIndex = index;
                                var algData = algorithmsModel.get(index);
                                // Открываем диалог редактирования алгоритма
                                algorithmsListViewRoot.editAlgorithmRequested(algData);
                            }
                            // --- ---
                        }
                    }
                }
            }
        }
        // --- ---

        // --- Панель кнопок справа (30% ширины) ---
        ColumnLayout {
            Layout.preferredWidth: parent.width * 0.3 // 30% ширины
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignTop
            spacing: 10

            // Надпись "Управление алгоритмами" УДАЛЕНА

            Button {
                text: "Добавить"
                Layout.fillWidth: true
                onClicked: algorithmsListViewRoot.addAlgorithmRequested()
            }

            Button {
                text: "Редактировать"
                Layout.fillWidth: true
                enabled: listView.currentIndex !== -1
                onClicked: {
                    var index = listView.currentIndex
                    if (index !== -1) {
                        var algData = algorithmsModel.get(index)
                        algorithmsListViewRoot.editAlgorithmRequested(algData)
                    }
                }
            }

            Button {
                text: "Удалить"
                Layout.fillWidth: true
                enabled: listView.currentIndex !== -1
                onClicked: {
                    var index = listView.currentIndex
                    if (index !== -1) {
                        var algId = algorithmsModel.get(index).id
                        algorithmsListViewRoot.deleteAlgorithmRequested(algId)
                    }
                }
            }

            Button {
                text: "Дублировать"
                Layout.fillWidth: true
                enabled: listView.currentIndex !== -1
                onClicked: {
                    var index = listView.currentIndex
                    if (index !== -1) {
                        var algId = algorithmsModel.get(index).id
                        algorithmsListViewRoot.duplicateAlgorithmRequested(algId)
                    }
                }
            }
            
            // --- Кнопка для редактирования действий ---
            Button {
                text: "Редактировать действия"
                Layout.fillWidth: true
                enabled: listView.currentIndex !== -1
                onClicked: {
                    var index = listView.currentIndex
                    if (index !== -1) {
                        var algData = algorithmsModel.get(index)
                        // Передаем полные данные алгоритма
                        algorithmsListViewRoot.editActionsRequested(algData)
                    }
                }
            }
            // --- ---
            
            // --- НОВОЕ: Кнопки ранжирования ---
            Button {
                text: "▲ Вверх"
                // --- ИЗМЕНЕНО: Заполняем ширину, как другие кнопки ---
                Layout.fillWidth: true // <-- НОВОЕ
                // --- ---
                // Включена, если выбран не первый элемент
                enabled: listView.currentIndex !== -1 && listView.currentIndex > 0 
                onClicked: {
                    var index = listView.currentIndex;
                    if (index > 0) { // Дополнительная проверка
                        var algId = algorithmsModel.get(index).id;
                        console.log("QML AlgorithmsListView: Запрошено перемещение алгоритма ID", algId, "вверх.");
                        var result = appData.moveAlgorithmUp(algId);
                        if (result === true) {
                            console.log("QML AlgorithmsListView: Алгоритм ID", algId, "перемещен вверх успешно.");
                            // --- ИЗМЕНЕНО: Перезагружаем список и сохраняем/восстанавливаем выделение ---
                            // Сохраняем ID перемещенного алгоритма
                            var movedAlgorithmId = algId;
                            // Перезагружаем список
                            algorithmsListViewRoot.loadAlgorithms();
                            // После перезагрузки пытаемся восстановить выделение
                            // Ищем новый индекс алгоритма по его ID
                            for (var i = 0; i < algorithmsModel.count; i++) {
                                if (algorithmsModel.get(i).id === movedAlgorithmId) {
                                    listView.currentIndex = i;
                                    console.log("QML AlgorithmsListView: Выделение восстановлено на алгоритме ID", movedAlgorithmId, "на новой позиции", i);
                                    break;
                                }
                            }
                            // --- ---
                        } else {
                            console.warn("QML AlgorithmsListView: Ошибка перемещения алгоритма ID", algId, "вверх. Результат:", result);
                            // TODO: Отобразить ошибку пользователю
                        }
                    } else {
                        console.log("QML AlgorithmsListView: Перемещение вверх невозможно: выбран первый элемент или элемент не выбран.");
                    }
                }
            }
            Button {
                text: "▼ Вниз"
                // --- ИЗМЕНЕНО: Заполняем ширину, как другие кнопки ---
                Layout.fillWidth: true // <-- НОВОЕ
                // --- ---
                // Включена, если выбран не последний элемент
                enabled: listView.currentIndex !== -1 && listView.currentIndex < (algorithmsModel.count - 1) 
                onClicked: {
                    var index = listView.currentIndex;
                    if (index !== -1 && index < (algorithmsModel.count - 1)) { // Дополнительная проверка
                        var algId = algorithmsModel.get(index).id;
                        console.log("QML AlgorithmsListView: Запрошено перемещение алгоритма ID", algId, "вниз.");
                        var result = appData.moveAlgorithmDown(algId);
                        if (result === true) {
                            console.log("QML AlgorithmsListView: Алгоритм ID", algId, "перемещен вниз успешно.");
                            // --- ИЗМЕНЕНО: Перезагружаем список и сохраняем/восстанавливаем выделение ---
                            // Сохраняем ID перемещенного алгоритма
                            var movedAlgorithmId = algId;
                            // Перезагружаем список
                            algorithmsListViewRoot.loadAlgorithms();
                            // После перезагрузки пытаемся восстановить выделение
                            // Ищем новый индекс алгоритма по его ID
                            for (var i = 0; i < algorithmsModel.count; i++) {
                                if (algorithmsModel.get(i).id === movedAlgorithmId) {
                                    listView.currentIndex = i;
                                    console.log("QML AlgorithmsListView: Выделение восстановлено на алгоритме ID", movedAlgorithmId, "на новой позиции", i);
                                    break;
                                }
                            }
                            // --- ---
                        } else {
                            console.warn("QML AlgorithmsListView: Ошибка перемещения алгоритма ID", algId, "вниз. Результат:", result);
                            // TODO: Отобразить ошибку пользователю
                        }
                    } else {
                        console.log("QML AlgorithmsListView: Перемещение вниз невозможно: выбран последний элемент, элемент не выбран или список пуст.");
                    }
                }
            }
            // --- ---

            Item {
                Layout.fillHeight: true // Заполнитель для выравнивания кнопок сверху
            }
        }
        // --- ---
    }

    // ... (остальные функции loadAlgorithms, updateOrAddAlgorithm, removeAlgorithm, Component.onCompleted остаются без изменений) ...
    // Или копируются из вашего текущего файла если они были изменены.

    /**
     * Загружает список алгоритмов из Python
     */
    function loadAlgorithms() {
        console.log("QML AlgorithmsListView: === НАЧАЛО ЗАГРУЗКИ СПИСКА АЛГОРИТМОВ ===")
        
        console.log("QML AlgorithmsListView: 1. Вызов appData.getAllAlgorithmsList()...")
        var algorithmsList = appData.getAllAlgorithmsList()
        console.log("QML AlgorithmsListView: 2. Получен ответ из Python. Тип:", typeof algorithmsList, "Значение (первые 500 символов):", JSON.stringify(algorithmsList).substring(0, 500))

        // Проверка и преобразование QJSValue/QVariant
        console.log("QML AlgorithmsListView: 3. Проверка необходимости преобразования QJSValue...")
        if (algorithmsList && typeof algorithmsList === 'object' && typeof algorithmsList.hasOwnProperty === 'function' && algorithmsList.hasOwnProperty('toVariant')) {
            console.log("QML AlgorithmsListView: 3a. Обнаружен QJSValue, преобразование в QVariant/JS...")
            algorithmsList = algorithmsList.toVariant()
            console.log("QML AlgorithmsListView: 3b. Преобразование завершено. Новый тип:", typeof algorithmsList, "Новое значение (первые 500 символов):", JSON.stringify(algorithmsList).substring(0, 500))
        } else {
            console.log("QML AlgorithmsListView: 3a. Преобразование не требуется или невозможно.")
        }

        // Очистка модели
        console.log("QML AlgorithmsListView: 4. Очистка модели ListView...")
        var oldCount = algorithmsModel.count
        algorithmsModel.clear()
        console.log("QML AlgorithmsListView: 4a. Модель очищена. Было элементов:", oldCount, "Стало:", algorithmsModel.count)

        // Заполнение модели
        console.log("QML AlgorithmsListView: 5. Попытка заполнения модели...")
        
        // Более надежная проверка на массив
        var isArrayLike = algorithmsList && typeof algorithmsList === 'object' && (
            Array.isArray(algorithmsList) || 
            (typeof algorithmsList.length === 'number' && algorithmsList.length >= 0)
        );
        
        console.log("QML AlgorithmsListView: 5a. Проверка, является ли algorithmsList массивоподобным:", isArrayLike)
        
        if (isArrayLike) {
            console.log("QML AlgorithmsListView: 5b. algorithmsList распознан как массив/список. Количество элементов:", algorithmsList.length)
            
            if (algorithmsList.length === 0) {
                 console.log("QML AlgorithmsListView: 5c. Список алгоритмов пуст.")
            }
            
            for (var i = 0; i < algorithmsList.length; i++) {
                var alg = algorithmsList[i]
                console.log("QML AlgorithmsListView: 5d. Обрабатываем элемент", i, ". Тип:", typeof alg, "Значение (первые 200 символов):", JSON.stringify(alg).substring(0, 200))
                
                if (alg && typeof alg === 'object') { // Проверяем, что alg не null и является объектом
                    try {
                        // Проверяем наличие обязательных полей
                        var id = alg["id"];
                        var name = alg["name"] || "";
                        var category = alg["category"] || "";
                        var time_type = alg["time_type"] || "";
                        var description = alg["description"] || "";
                        
                        console.log("QML AlgorithmsListView: 5e. Подготовленные данные элемента", i, ":", id, name, category, time_type)
                        
                        if (id === undefined || id === null) {
                             console.warn("QML AlgorithmsListView: 5f. Элемент", i, "не содержит поле 'id'. Пропущен.")
                             continue;
                        }
                        
                        algorithmsModel.append({
                            "id": id,
                            "name": name,
                            "category": category,
                            "time_type": time_type,
                            "description": description
                        })
                        console.log("QML AlgorithmsListView: 5g. Элемент", i, "добавлен в модель.")
                    } catch (e_append) {
                        console.error("QML AlgorithmsListView: 5h. ОШИБКА при добавлении элемента", i, "в модель:", e_append.toString(), "Данные элемента:", JSON.stringify(alg))
                    }
                } else {
                    console.warn("QML AlgorithmsListView: 5i. Элемент", i, "не является корректным объектом. Тип:", typeof alg, "Значение:", alg)
                }
            }
        } else {
            console.error("QML AlgorithmsListView: 5b. ОШИБКА: Python не вернул корректный массив/список. Получен тип:", typeof algorithmsList, "Значение:", algorithmsList)
            // Попробуем вывести больше информации об объекте
            if (algorithmsList && typeof algorithmsList === 'object') {
                console.log("QML AlgorithmsListView: 5c. Свойства полученного объекта:", Object.keys ? Object.keys(algorithmsList) : "Object.keys недоступен")
            }
        }
        
        console.log("QML AlgorithmsListView: 6. Финальное состояние модели. Элементов:", algorithmsModel.count)
        if (algorithmsModel.count > 0) {
            try {
                console.log("QML AlgorithmsListView: 6a. Первый элемент в модели (для проверки):", JSON.stringify(algorithmsModel.get(0)))
            } catch (e_log) {
                console.warn("QML AlgorithmsListView: 6b. Не удалось залогировать первый элемент:", e_log.toString())
            }
        }
        
        console.log("QML AlgorithmsListView: === КОНЕЦ ЗАГРУЗКИ СПИСКА АЛГОРИТМОВ ===")
    }

    /**
     * Обновляет или добавляет алгоритм в модель
     */
    function updateOrAddAlgorithm(algorithmData) {
        // Проверяем, существует ли уже алгоритм с таким ID
        for (var i = 0; i < algorithmsModel.count; i++) {
            if (algorithmsModel.get(i).id === algorithmData.id) {
                // Обновляем существующий
                algorithmsModel.set(i, algorithmData)
                console.log("QML AlgorithmsListView: Алгоритм ID", algorithmData.id, "обновлен в модели.")
                return
            }
        }
        // Добавляем новый
        algorithmsModel.append(algorithmData)
        console.log("QML AlgorithmsListView: Новый алгоритм ID", algorithmData.id, "добавлен в модель.")
    }

    /**
     * Удаляет алгоритм из модели
     */
    function removeAlgorithm(algorithmId) {
        for (var i = 0; i < algorithmsModel.count; i++) {
            if (algorithmsModel.get(i).id === algorithmId) {
                algorithmsModel.remove(i)
                console.log("QML AlgorithmsListView: Алгоритм ID", algorithmId, "удален из модели.")
                // Сбрасываем выбор, если удалили выбранный элемент
                if (listView.currentIndex === i) {
                    listView.currentIndex = -1
                }
                return
            }
        }
    }

    Component.onCompleted: {
        console.log("QML AlgorithmsListView: Загружен. Инициализация...")
        loadAlgorithms()
    }
}