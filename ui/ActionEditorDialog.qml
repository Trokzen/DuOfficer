// ui/ActionEditorDialog.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5

Popup {
    id: actionEditorDialog
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width * 0.8, 600)
    height: Math.min(parent.height * 0.85, 500) // Увеличена высота
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    // Свойства
    property bool isEditMode: false
    property int currentActionId: -1
    property int currentAlgorithmId: -1 // Нужен для нового действия

    // Сигнал для уведомления о сохранении
    signal actionSaved()

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
            text: isEditMode ? "Редактировать действие" : "Добавить новое действие"
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
                rowSpacing: 10
                width: parent.width

                Label {
                    text: "Описание:*"
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                }
                TextArea {
                    id: descriptionArea
                    Layout.fillWidth: true
                    Layout.minimumHeight: 60
                    placeholderText: "Введите описание действия..."
                    wrapMode: TextArea.Wrap
                }

                Label {
                    text: "Время начала (смещение):*"
                    Layout.alignment: Qt.AlignRight
                    ToolTip.text: "Формат: '1 day 2 hours 30 minutes' или '01:30:00'"
                    ToolTip.visible: hovered
                }
                TextField {
                    id: startOffsetField
                    Layout.fillWidth: true
                    placeholderText: "Например: 00:00:00 или 1 hour 30 minutes"
                    text: "00:00:00" // Значение по умолчанию
                }

                Label {
                    text: "Время окончания (смещение):*"
                    Layout.alignment: Qt.AlignRight
                    ToolTip.text: "Формат: '1 day 2 hours 30 minutes' или '01:30:00'"
                    ToolTip.visible: hovered
                }
                TextField {
                    id: endOffsetField
                    Layout.fillWidth: true
                    placeholderText: "Например: 00:00:00 или 1 hour 30 minutes"
                    text: "00:00:00" // Значение по умолчанию
                }

                Label {
                    text: "Контактные телефоны:"
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                }
                TextArea {
                    id: contactPhonesArea
                    Layout.fillWidth: true
                    Layout.minimumHeight: 40
                    placeholderText: "Введите контактные телефоны (через запятую или новую строку)..."
                    wrapMode: TextArea.Wrap
                }

                Label {
                    text: "Отчетные материалы:"
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                }
                TextArea {
                    id: reportMaterialsArea
                    Layout.fillWidth: true
                    Layout.minimumHeight: 60
                    placeholderText: "Введите пути/ссылки на отчетные материалы (через запятую или новую строку)..."
                    wrapMode: TextArea.Wrap
                }
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
                    console.log("QML ActionEditorDialog: Нажата кнопка Отмена");
                    actionEditorDialog.close();
                }
            }
            Button {
                text: isEditMode ? "Сохранить" : "Добавить"
                onClicked: {
                    console.log("QML ActionEditorDialog: Нажата кнопка Сохранить/Добавить");
                    errorMessageLabel.text = "";

                    // Валидация
                    if (!descriptionArea.text.trim()) {
                        errorMessageLabel.text = "Пожалуйста, заполните описание действия.";
                        return;
                    }
                    if (!startOffsetField.text.trim()) {
                        errorMessageLabel.text = "Пожалуйста, заполните время начала.";
                        return;
                    }
                    if (!endOffsetField.text.trim()) {
                        errorMessageLabel.text = "Пожалуйста, заполните время окончания.";
                        return;
                    }

                    // Подготавливаем данные
                    var actionData = {
                        "algorithm_id": currentAlgorithmId, // Всегда передаем, даже при редактировании
                        "description": descriptionArea.text.trim(),
                        "start_offset": startOffsetField.text.trim(),
                        "end_offset": endOffsetField.text.trim(),
                        "contact_phones": contactPhonesArea.text,
                        "report_materials": reportMaterialsArea.text
                    };

                    var result;
                    if (isEditMode) {
                        console.log("QML ActionEditorDialog: Отправляем обновление действия ID", currentActionId, "в Python:", JSON.stringify(actionData));
                        result = appData.updateAction(currentActionId, actionData);
                    } else {
                        console.log("QML ActionEditorDialog: Отправляем новое действие для алгоритма ID", currentAlgorithmId, "в Python:", JSON.stringify(actionData));
                        result = appData.addAction(actionData);
                    }

                    if (result === true || (typeof result === 'number' && result > 0)) {
                        console.log("QML ActionEditorDialog: Действие успешно сохранено/добавлено. Результат:", result);
                        actionEditorDialog.actionSaved();
                        actionEditorDialog.close();
                    } else {
                        var errorMsg = "Неизвестная ошибка";
                        if (typeof result === 'string') {
                            errorMsg = result;
                        } else if (result === false) {
                            errorMsg = "Не удалось выполнить операцию. Проверьте данные.";
                        } else if (result === -1) {
                            errorMsg = "Ошибка при добавлении действия.";
                        }
                        errorMessageLabel.text = "Ошибка: " + errorMsg;
                        console.warn("QML ActionEditorDialog: Ошибка при сохранении/добавлении действия:", errorMsg);
                    }
                }
            }
        }
    }

    /**
     * Сбрасывает диалог для добавления нового действия
     */
    function resetForAdd(algorithmId) {
        console.log("QML ActionEditorDialog: Сброс для добавления нового действия для алгоритма ID:", algorithmId);
        isEditMode = false;
        currentActionId = -1;
        currentAlgorithmId = algorithmId; // Запоминаем ID алгоритма
        descriptionArea.text = "";
        startOffsetField.text = "00:00:00"; // Значение по умолчанию
        endOffsetField.text = "00:00:00";   // Значение по умолчанию
        contactPhonesArea.text = "";
        reportMaterialsArea.text = "";
        errorMessageLabel.text = "";
    }

    /**
     * Загружает данные действия для редактирования
     */
    function loadDataForEdit(actionData) {
        console.log("QML ActionEditorDialog: Загрузка данных для редактирования:", JSON.stringify(actionData));
        isEditMode = true;
        currentActionId = actionData.id;
        currentAlgorithmId = actionData.algorithm_id; // Запоминаем ID алгоритма
        descriptionArea.text = actionData.description || "";
        startOffsetField.text = actionData.start_offset || "";
        endOffsetField.text = actionData.end_offset || "";
        contactPhonesArea.text = actionData.contact_phones || "";
        reportMaterialsArea.text = actionData.report_materials || "";
        errorMessageLabel.text = "";
    }

    onOpened: {
        console.log("QML ActionEditorDialog: Диалог открыт.");
        errorMessageLabel.text = "";
    }
}