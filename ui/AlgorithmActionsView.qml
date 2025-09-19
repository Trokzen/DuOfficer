// ui/AlgorithmActionsView.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5

Item {
    id: algorithmActionsViewRoot

    // Свойство для получения ID текущего алгоритма
    property int currentAlgorithmId: -1
    property alias currentAlgorithmName: algorithmNameLabel.text

    // Сигналы для уведомления родителя о действиях
    signal addActionRequested()
    signal editActionRequested(var actionData)
    signal deleteActionRequested(var actionId)
    signal duplicateActionRequested(var actionId)

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        // Заголовок с названием алгоритма
        RowLayout {
            Layout.fillWidth: true
            Label {
                id: algorithmNameLabel
                text: "Алгоритм: ..."
                font.pointSize: 14
                font.bold: true
                elide: Text.ElideRight
            }
            Item {
                Layout.fillWidth: true
            }
            Button {
                text: "Добавить действие"
                onClicked: algorithmActionsViewRoot.addActionRequested()
            }
        }

        // Список действий
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: actionsListView
                model: ListModel {
                    id: actionsModel
                }
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 60
                    // --- Выделение выбранного элемента (скопировано из AlgorithmsListView) ---
                    color: {
                        if (actionsListView.currentIndex === index) {
                            return "#3498db"; 
                        } else {
                            return index % 2 ? "#f9f9f9" : "#ffffff"; 
                        }
                    }
                    border.color: actionsListView.currentIndex === index ? "#2980b9" : "#ddd"
                    Behavior on color { ColorAnimation { duration: 100 } }
                    Behavior on border.color { ColorAnimation { duration: 100 } }
                    // --- ---
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            // --- Цвет текста для выделенного элемента ---
                            color: actionsListView.currentIndex === index ? "white" : "black"
                            // --- ---
                            text: "Шаг " + (index+1) + ": " + model.description
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        RowLayout {
                            Text {
                                // --- Цвет текста для выделенного элемента ---
                                color: actionsListView.currentIndex === index ? "#e0e0e0" : "gray"
                                // --- ---
                                // Отображение времени начала и окончания
                                // Предполагается, что start_offset и end_offset приходят как строки INTERVAL
                                text: "Начало: " + (model.start_offset || "0") + " | Окончание: " + (model.end_offset || "0")
                                font.pixelSize: 10
                            }
                            Item {
                                Layout.fillWidth: true
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            actionsListView.currentIndex = index;
                        }
                        onDoubleClicked: {
                            actionsListView.currentIndex = index;
                            var actionData = actionsModel.get(index);
                            // Передаем копию данных действия
                            algorithmActionsViewRoot.editActionRequested({
                                "id": actionData.id,
                                "algorithm_id": actionData.algorithm_id,
                                "description": actionData.description,
                                "start_offset": actionData.start_offset,
                                "end_offset": actionData.end_offset,
                                "contact_phones": actionData.contact_phones,
                                "report_materials": actionData.report_materials
                            });
                        }
                    }
                }
            }
        }

        // Панель кнопок действий (видна, если выбрано действие)
        RowLayout {
            Layout.fillWidth: true
            spacing: 10
            enabled: actionsListView.currentIndex !== -1 && currentAlgorithmId > 0

            Button {
                text: "Редактировать"
                onClicked: {
                    var index = actionsListView.currentIndex;
                    if (index !== -1) {
                        var actionData = actionsModel.get(index);
                        algorithmActionsViewRoot.editActionRequested({
                            "id": actionData.id,
                            "algorithm_id": actionData.algorithm_id,
                            "description": actionData.description,
                            "start_offset": actionData.start_offset,
                            "end_offset": actionData.end_offset,
                            "contact_phones": actionData.contact_phones,
                            "report_materials": actionData.report_materials
                        });
                    }
                }
            }
            Button {
                text: "Удалить"
                onClicked: {
                    var index = actionsListView.currentIndex;
                    if (index !== -1) {
                        // TODO: Добавить подтверждение
                        var actionId = actionsModel.get(index).id;
                        algorithmActionsViewRoot.deleteActionRequested(actionId);
                    }
                }
            }
            Button {
                text: "Дублировать"
                onClicked: {
                    var index = actionsListView.currentIndex;
                    if (index !== -1) {
                        var actionId = actionsModel.get(index).id;
                        algorithmActionsViewRoot.duplicateActionRequested(actionId);
                    }
                }
            }
        }
    }

    /**
     * Загружает список действий для текущего алгоритма из Python
     */
    function loadActions() {
        if (currentAlgorithmId <= 0) {
            console.warn("QML AlgorithmActionsView: Невозможно загрузить действия, ID алгоритма не задан или некорректен:", currentAlgorithmId);
            return;
        }
        
        console.log("QML AlgorithmActionsView: Запрос списка действий для алгоритма ID", currentAlgorithmId, "у Python...");
        var actionsList = appData.getActionsByAlgorithmId(currentAlgorithmId);
        console.log("QML AlgorithmActionsView: Получен список действий из Python (сырой):", JSON.stringify(actionsList).substring(0, 500));

        // Преобразование QJSValue/QVariant в массив JS
        if (actionsList && typeof actionsList === 'object' && actionsList.hasOwnProperty('toVariant')) {
            actionsList = actionsList.toVariant();
            console.log("QML AlgorithmActionsView: QJSValue (actionsList) преобразован в:", JSON.stringify(actionsList).substring(0, 500));
        }

        // Очищаем текущую модель
        actionsModel.clear();
        console.log("QML AlgorithmActionsView: Модель ListView действий очищена.");

        // --- Более гибкая проверка на "массивоподобность" ---
        if (actionsList && typeof actionsList === 'object' && actionsList.length !== undefined) {
        // --- ---
            var count = actionsList.length;
            console.log("QML AlgorithmActionsView: Полученный список действий является массивоподобным. Количество элементов:", count);
            
            for (var i = 0; i < count; i++) {
                var action = actionsList[i];
                console.log("QML AlgorithmActionsView: Обрабатываем действие", i, ":", JSON.stringify(action).substring(0, 200));
                
                if (typeof action === 'object' && action !== null) {
                    try {
                        actionsModel.append({
                            "id": action["id"],
                            "algorithm_id": action["algorithm_id"],
                            "description": action["description"] || "",
                            "start_offset": action["start_offset"] || "", // Может прийти как строка INTERVAL
                            "end_offset": action["end_offset"] || "",     // Может прийти как строка INTERVAL
                            "contact_phones": action["contact_phones"] || "",
                            "report_materials": action["report_materials"] || ""
                        });
                        console.log("QML AlgorithmActionsView: Действие", i, "добавлено в модель.");
                    } catch (e) {
                        console.error("QML AlgorithmActionsView: Ошибка при добавлении действия", i, "в модель:", e.toString(), "Данные:", JSON.stringify(action));
                    }
                } else {
                    console.warn("QML AlgorithmActionsView: Действие", i, "не является корректным объектом:", typeof action, action);
                }
            }
        } else {
            console.error("QML AlgorithmActionsView: Python не вернул корректный массивоподобный объект для действий. Получен тип:", typeof actionsList, "Значение:", actionsList);
        }
        console.log("QML AlgorithmActionsView: Модель ListView действий обновлена. Элементов:", actionsModel.count);
    }

    /**
     * Обновляет или добавляет действие в модель
     */
    function updateOrAddAction(actionData) {
        if (!actionData || !actionData.id) {
            console.warn("QML AlgorithmActionsView: updateOrAddAction - некорректные данные действия:", JSON.stringify(actionData));
            return;
        }
        
        // Проверяем, существует ли уже действие с таким ID
        for (var i = 0; i < actionsModel.count; i++) {
            if (actionsModel.get(i).id === actionData.id) {
                // Обновляем существующий
                actionsModel.set(i, actionData);
                console.log("QML AlgorithmActionsView: Действие ID", actionData.id, "обновлено в модели.");
                return;
            }
        }
        // Добавляем новый (если он принадлежит текущему алгоритму)
        if (actionData.algorithm_id === currentAlgorithmId) {
            actionsModel.append(actionData);
            console.log("QML AlgorithmActionsView: Новое действие ID", actionData.id, "добавлено в модель.");
        } else {
             console.log("QML AlgorithmActionsView: Новое действие ID", actionData.id, "не добавлено в модель, так как принадлежит другому алгоритму (", actionData.algorithm_id, ").");
        }
    }

    /**
     * Удаляет действие из модели
     */
    function removeAction(actionId) {
        for (var i = 0; i < actionsModel.count; i++) {
            if (actionsModel.get(i).id === actionId) {
                actionsModel.remove(i);
                console.log("QML AlgorithmActionsView: Действие ID", actionId, "удалено из модели.");
                // Сбрасываем выбор, если удалили выбранный элемент
                if (actionsListView.currentIndex === i) {
                    actionsListView.currentIndex = -1;
                }
                return;
            }
        }
    }
}