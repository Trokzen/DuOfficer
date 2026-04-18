// ui/algorithms/OrganizationFilesSelector.qml
// Компонент для выбора организаций и файлов для выполнения действия
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5

Item {
    id: organizationFilesSelector
    
    // Свойства
    property int actionExecutionId: -1
    property bool isEditMode: false
    
    // Модели данных
    property var selectedOrganizationFiles: []
    property var availableOrganizations: []
    property var currentOrganizationFiles: []
    
    // Состояния
    property string statusMessage: ""
    property bool isLoading: false
    
    // Внутренние свойства для формы добавления
    property int selectedOrganizationId: -1
    property int selectedFileId: -1
    property var currentOrganizationFilesList: []
    
    signal dataLoaded()
    signal dataSaved()
    signal errorOccurred(string message)
    
    // Загрузка данных при изменении ID выполнения действия
    function loadOrganizationFiles() {
        if (actionExecutionId <= 0) {
            console.log("OrganizationFilesSelector: Неверный actionExecutionId")
            return
        }
        
        isLoading = true
        statusMessage = "Загрузка данных..."
        
        console.log("OrganizationFilesSelector: Загрузка организаций/файлов для action_execution ID", actionExecutionId)
        
        // Получаем выбранные организации и файлы
        selectedOrganizationFiles = appData.getOrganizationFilesForActionExecution(actionExecutionId)
        console.log("OrganizationFilesSelector: Получено", selectedOrganizationFiles.length, "записей")
        
        // Получаем доступные организации (еще не привязанные)
        availableOrganizations = appData.getAvailableOrganizationsForActionExecution(actionExecutionId)
        console.log("OrganizationFilesSelector: Получено", availableOrganizations.length, "доступных организаций")
        
        // Сбрасываем выбор
        selectedOrganizationId = -1
        selectedFileId = -1
        currentOrganizationFilesList = []
        
        isLoading = false
        statusMessage = ""
        dataLoaded()
    }
    
    // Получить файлы для выбранной организации
    function getFilesForOrganization(organizationId) {
        if (organizationId <= 0) {
            currentOrganizationFilesList = []
            return []
        }
        
        console.log("OrganizationFilesSelector: Запрос файлов для организации ID", organizationId)
        var files = appData.getFilesForOrganization(organizationId)
        console.log("OrganizationFilesSelector: Получено", files.length, "файлов")
        currentOrganizationFilesList = files
        return files
    }
    
    // Добавить организацию и файл к выполнению действия
    function addOrganizationFile(organizationId, fileId) {
        if (actionExecutionId <= 0 || organizationId <= 0 || fileId <= 0) {
            errorOccurred("Некорректные параметры для добавления")
            return false
        }
        
        console.log("OrganizationFilesSelector: Добавление организации ID", organizationId, "файл ID", fileId)
        var success = appData.addOrganizationFileToActionExecution(actionExecutionId, organizationId, fileId)
        
        if (success) {
            statusMessage = "Файл успешно добавлен"
            loadOrganizationFiles() // Перезагружаем данные
            dataSaved()
            return true
        } else {
            errorOccurred("Не удалось добавить файл")
            return false
        }
    }
    
    // Удалить связь
    function removeOrganizationFile(linkId) {
        if (linkId <= 0) {
            errorOccurred("Некорректный ID связи")
            return false
        }
        
        console.log("OrganizationFilesSelector: Удаление связи ID", linkId)
        var success = appData.removeOrganizationFileFromActionExecution(linkId)
        
        if (success) {
            statusMessage = "Связь удалена"
            loadOrganizationFiles() // Перезагружаем данные
            dataSaved()
            return true
        } else {
            errorOccurred("Не удалось удалить связь")
            return false
        }
    }
    
    // Визуальный интерфейс компонента
    ColumnLayout {
        anchors.fill: parent
        spacing: 5
        
        // Таблица выбранных организаций и файлов
        Label {
            text: "Выбранные организации и файлы:"
            font.bold: true
            font.pixelSize: 11
        }
        
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            TableView {
                id: organizationFilesTable
                width: parent.width
                height: Math.max(contentHeight, 100)
                
                model: selectedOrganizationFiles
                
                delegate: Rectangle {
                    implicitWidth: Math.max(implicitColumnWidth, 100)
                    implicitHeight: 25
                    color: index % 2 === 0 ? "#f5f5f5" : "white"
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 3
                        spacing: 5
                        
                        Label {
                            text: model.organization_name || ""
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            font.pixelSize: 11
                        }
                        
                        Label {
                            text: model.file_name || ""
                            Layout.fillWidth: true
                            Layout.preferredWidth: 150
                            elide: Text.ElideRight
                            font.pixelSize: 11
                        }
                        
                        Button {
                            text: "✕"
                            Layout.preferredWidth: 25
                            Layout.preferredHeight: 20
                            font.pixelSize: 10
                            onClicked: {
                                if (model.id > 0) {
                                    removeOrganizationFile(model.id)
                                }
                            }
                        }
                    }
                }
                
                header: DelegateModel {
                    model: [
                        { title: "Организация", width: 200 },
                        { title: "Файл", width: 200 },
                        { title: "", width: 30 }
                    ]
                    
                    delegate: Rectangle {
                        implicitWidth: modelData.width
                        implicitHeight: 25
                        color: "#e0e0e0"
                        
                        Label {
                            text: modelData.title
                            anchors.centerIn: parent
                            font.bold: true
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
        
        // Форма добавления новой связи
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 80
            color: "#f9f9f9"
            border.color: "#ddd"
            border.width: 1
            radius: 3
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 5
                spacing: 5
                
                Label {
                    text: "Добавить организацию и файл:"
                    font.bold: true
                    font.pixelSize: 11
                }
                
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 5
                    
                    // Выбор организации
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: "Организация:"
                            font.pixelSize: 10
                        }
                        
                        ComboBox {
                            id: organizationComboBox
                            Layout.fillWidth: true
                            model: availableOrganizations
                            textRole: "name"
                            valueRole: "id"
                            font.pixelSize: 11
                            
                            onCurrentIndexChanged: {
                                if (currentIndex >= 0 && model.count > 0) {
                                    var orgId = model.get(currentIndex).id
                                    if (orgId > 0) {
                                        selectedOrganizationId = orgId
                                        getFilesForOrganization(orgId)
                                        fileComboBox.currentIndex = -1
                                        selectedFileId = -1
                                    }
                                }
                            }
                        }
                    }
                    
                    // Выбор файла
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2
                        
                        Label {
                            text: "Файл:"
                            font.pixelSize: 10
                        }
                        
                        ComboBox {
                            id: fileComboBox
                            Layout.fillWidth: true
                            model: currentOrganizationFilesList
                            textRole: "filename"
                            valueRole: "id"
                            font.pixelSize: 11
                            enabled: currentOrganizationFilesList.length > 0
                            
                            onCurrentIndexChanged: {
                                if (currentIndex >= 0 && model.count > 0) {
                                    var fileId = model.get(currentIndex).id
                                    if (fileId > 0) {
                                        selectedFileId = fileId
                                    }
                                }
                            }
                        }
                    }
                    
                    // Кнопка добавления
                    Button {
                        text: "Добавить"
                        Layout.preferredWidth: 80
                        Layout.alignment: Qt.AlignBottom
                        font.pixelSize: 11
                        enabled: selectedOrganizationId > 0 && selectedFileId > 0
                        
                        onClicked: {
                            if (selectedOrganizationId > 0 && selectedFileId > 0) {
                                addOrganizationFile(selectedOrganizationId, selectedFileId)
                                // Сброс выбора
                                selectedOrganizationId = -1
                                selectedFileId = -1
                                organizationComboBox.currentIndex = -1
                                fileComboBox.currentIndex = -1
                                currentOrganizationFilesList = []
                            }
                        }
                    }
                }
            }
        }
        
        // Статус
        Label {
            text: statusMessage
            visible: statusMessage !== ""
            font.pixelSize: 10
            color: statusMessage.includes("ошибка") || statusMessage.includes("Не удалось") ? "red" : "green"
        }
    }
}
