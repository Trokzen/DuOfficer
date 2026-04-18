// ui/algorithms/ReferenceMaterialsSelectorDialog.qml
// Диалог для выбора справочных материалов (организации + файлы)
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5

Popup {
    id: referenceMaterialsSelectorDialog
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width * 0.85, 900)
    height: Math.min(parent.height * 0.85, 650)
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    // Свойства
    property var allOrganizations: [] // Все организации с файлами из БД
    property var selectedMaterials: [] // Уже выбранные материалы

    background: Rectangle {
        color: "white"
        border.color: "lightgray"
        radius: 8
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 15
        spacing: 15

        // Заголовок
        Label {
            text: "Выберите справочные материалы"
            font.pointSize: 14
            font.bold: true
            Layout.fillWidth: true
        }

        // Две колонки: слева организации, справа файлы выбранной организации
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 15

            // ЛЕВАЯ КОЛОНКА: Список организаций
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.4
                Layout.fillHeight: true
                spacing: 8

                Label {
                    text: "Организации:"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#2c3e50"
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        id: organizationsList
                        width: parent.width
                        spacing: 5

                        Repeater {
                            model: allOrganizations

                            delegate: Rectangle {
                                width: organizationsList.width
                                height: orgLabel.contentHeight + 16
                                radius: 5
                                color: orgMouseArea.containsMouse ? "#e8f4f8" : "white"
                                border.color: "#3498db"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    Label {
                                        id: orgLabel
                                        text: modelData.name + (modelData.reference_files.length > 0 ? ` (${modelData.reference_files.length})` : "")
                                        font.pixelSize: 11
                                        elide: Text.ElideRight
                                        Layout.fillWidth: true
                                    }

                                    Button {
                                        text: "📂"
                                        font.pixelSize: 12
                                        Layout.preferredWidth: 30
                                        Layout.preferredHeight: 26
                                        onClicked: {
                                            showOrganizationFiles(modelData);
                                        }
                                        ToolTip.text: "Показать файлы организации"
                                        ToolTip.visible: containsMouse
                                    }
                                }

                                MouseArea {
                                    id: orgMouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        showOrganizationFiles(modelData);
                                    }
                                }
                            }
                        }

                        Label {
                            visible: allOrganizations.length === 0
                            text: "Нет организаций со справочными материалами"
                            font.pixelSize: 11
                            color: "#999"
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            padding: 20
                        }
                    }
                }
            }

            // ПРАВАЯ КОЛОНКА: Файлы выбранной организации
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.6
                Layout.fillHeight: true
                spacing: 8

                Label {
                    id: filesSectionTitle
                    text: "Файлы организации: —"
                    font.pixelSize: 12
                    font.bold: true
                    color: "#2c3e50"
                }

                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        id: filesList
                        width: parent.width
                        spacing: 5

                        Label {
                            id: noFilesLabel
                            visible: filesList.children.length <= 1
                            text: "Выберите организацию для просмотра файлов"
                            font.pixelSize: 11
                            color: "#999"
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignHCenter
                            padding: 20
                        }
                    }
                }
            }
        }

        // Кнопки
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: "Закрыть"
                onClicked: referenceMaterialsSelectorDialog.close()
            }
        }
    }

    // Функции
    function showOrganizationFiles(orgData) {
        if (!orgData) return;

        filesSectionTitle.text = "Файлы организации: " + orgData.name;

        // Очищаем список файлов
        while (filesList.children.length > 1) {
            filesList.children[1].destroy();
        }

        var files = orgData.reference_files || [];
        if (files.length === 0) {
            return;
        }

        // Создаем элементы для каждого файла
        for (var i = 0; i < files.length; i++) {
            var file = files[i];
            var isAlreadySelected = false;

            // Проверяем, выбран ли уже этот файл
            for (var j = 0; j < selectedMaterials.length; j++) {
                if (selectedMaterials[j].reference_file_id === file.id) {
                    isAlreadySelected = true;
                    break;
                }
            }

            var fileTypeIcon = "";
            if (file.file_type === "word") fileTypeIcon = "📄";
            else if (file.file_type === "excel") fileTypeIcon = "📊";
            else if (file.file_type === "image") fileTypeIcon = "🖼️";
            else fileTypeIcon = "📎";

            var fileName = file.file_path.split('/').pop() || file.file_path;

            var fileRow = Qt.createQmlObject(`
                import QtQuick 6.5
                import QtQuick.Controls 6.5
                import QtQuick.Layouts 6.5

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8
                    padding: 5
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: fileLabel.contentHeight + 10
                        radius: 4
                        color: "${isAlreadySelected ? "#d5f5e3" : "white"}"
                        border.color: "${isAlreadySelected ? "#27ae60" : "#ddd"}"
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: "${fileTypeIcon}"
                                font.pixelSize: 14
                            }

                            Label {
                                id: fileLabel
                                text: "${fileName}"
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                                Layout.fillWidth: true
                                color: "${isAlreadySelected ? "#27ae60" : "#333"}"
                            }

                            Label {
                                text: "${file.file_type.toUpperCase()}"
                                font.pixelSize: 9
                                font.bold: true
                                color: "#666"
                                padding: 2
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#f0f0f0"
                                    radius: 3
                                    z: -1
                                }
                            }

                            Button {
                                text: "${isAlreadySelected ? "✓ Добавлен" : "+ Добавить"}"
                                font.pixelSize: 10
                                enabled: ${!isAlreadySelected}
                                Layout.preferredWidth: 80
                                Layout.preferredHeight: 26
                                onClicked: {
                                    addFile(${orgData.id}, ${file.id});
                                }
                            }
                        }
                    }
                }
            `, filesList, "fileRow_" + i);
        }
    }

    function addFile(orgId, fileId) {
        // Находим информацию о файле
        var orgName = "";
        var filePath = "";
        var fileType = "";

        for (var i = 0; i < allOrganizations.length; i++) {
            var org = allOrganizations[i];
            if (org.id === orgId) {
                orgName = org.name;
                for (var j = 0; j < org.reference_files.length; j++) {
                    if (org.reference_files[j].id === fileId) {
                        filePath = org.reference_files[j].file_path;
                        fileType = org.reference_files[j].file_type;
                        break;
                    }
                }
                break;
            }
        }

        if (orgName && filePath) {
            // Добавляем в выбранные материалы
            selectedMaterials.push({
                organization_id: orgId,
                organization_name: orgName,
                reference_file_id: fileId,
                file_path: filePath,
                file_type: fileType
            });

            console.log("ReferenceMaterialsSelectorDialog: Добавлен файл:", filePath);

            // Обновляем отображение текущего списка файлов
            var currentOrg = allOrganizations.find(function(o) { return o.id === orgId; });
            if (currentOrg) {
                showOrganizationFiles(currentOrg);
            }

            // Уведомляем родительский диалог
            referenceMaterialsSelectorDialog.parent.addReferenceFile(orgId, fileId);
        }
    }
}
