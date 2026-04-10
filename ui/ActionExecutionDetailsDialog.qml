// ui/ActionExecutionDetailsDialog.qml
import QtQuick 6.5
import QtQuick.Controls 6.5
import QtQuick.Layouts 6.5
import QtQuick.Dialogs 6.5

Popup {
    id: actionDetailsDialog
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2
    width: Math.min(parent.width * 0.95, 1400)
    height: Math.min(parent.height * 0.9, 900)
    modal: true
    focus: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

    // --- Свойства ---
    property int executionId: -1
    property int currentActionIndex: -1
    property int totalActions: 0
    property bool autoSwitch: true
    property bool isOverdue: false

    // --- Таймеры ---
    Timer {
        id: countdownTimer
        interval: 1000
        repeat: true
        running: true
        onTriggered: {
            updateCountdown()
            checkOverdue()
        }
    }

    Timer {
        id: overduePulseTimer
        interval: 800
        repeat: true
        running: actionDetailsDialog.isOverdue
    }

    // --- Функции ---
    function updateCountdown() {
        var now = new Date()
        var endTimeText = calculatedEndTimeLabel.text
        if (!endTimeText || endTimeText === "Не задано") {
            remainingTimeLabel.text = "—"
            return
        }

        // Парсим дату окончания
        var endParts = endTimeText.match(/(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/)
        if (!endParts) {
            remainingTimeLabel.text = "—"
            return
        }

        var endDate = new Date(parseInt(endParts[3]), parseInt(endParts[2]) - 1, parseInt(endParts[1]),
                               parseInt(endParts[4]), parseInt(endParts[5]), parseInt(endParts[6]))
        var diff = endDate - now

        if (diff <= 0) {
            remainingTimeLabel.text = "00:00:00"
            remainingTimeLabel.color = "#e74c3c"
        } else {
            var hours = Math.floor(diff / 3600000)
            var minutes = Math.floor((diff % 3600000) / 60000)
            var seconds = Math.floor((diff % 60000) / 1000)
            remainingTimeLabel.text = String(hours).padStart(2, '0') + ":" +
                                      String(minutes).padStart(2, '0') + ":" +
                                      String(seconds).padStart(2, '0')
            remainingTimeLabel.color = diff <= 300000 ? "#f39c12" : "#27ae60"
        }
    }

    function checkOverdue() {
        var now = new Date()
        var endTimeText = calculatedEndTimeLabel.text
        if (!endTimeText || endTimeText === "Не задано") return

        var endParts = endTimeText.match(/(\d{2})\.(\d{2})\.(\d{4})\s+(\d{2}):(\d{2}):(\d{2})/)
        if (!endParts) return

        var endDate = new Date(parseInt(endParts[3]), parseInt(endParts[2]) - 1, parseInt(endParts[1]),
                               parseInt(endParts[4]), parseInt(endParts[5]), parseInt(endParts[6]))
        actionDetailsDialog.isOverdue = now > endDate

        // Автопереключение
        if (actionDetailsDialog.isOverdue && actionDetailsDialog.autoSwitch) {
            switchToNext()
        }
    }

    function switchToNext() {
        if (actionDetailsDialog.currentActionIndex < actionDetailsDialog.totalActions - 1) {
            actionDetailsDialog.currentActionIndex++
            loadActionData()
        }
    }

    function switchToPrevious() {
        if (actionDetailsDialog.currentActionIndex > 0) {
            actionDetailsDialog.currentActionIndex--
            loadActionData()
        }
    }

    function loadActionData() {
        if (actionDetailsDialog.executionId <= 0 || actionDetailsDialog.currentActionIndex < 0) return

        var actions = appData.getActionExecutionsByExecutionId(actionDetailsDialog.executionId)
        if (!actions || actionDetailsDialog.currentActionIndex >= actions.length) return

        var action = actions[actionDetailsDialog.currentActionIndex]
        actionDetailsDialog.totalActions = actions.length

        // Название
        actionNameLabel.text = "Мероприятие №" + action.number + ": " + (action.snapshot_description || "Без названия")

        // Время начала
        calculatedStartTimeLabel.text = action.calculated_start_time ? formatDateTime(action.calculated_start_time) : "Не задано"

        // Время окончания
        calculatedEndTimeLabel.text = action.calculated_end_time ? formatDateTime(action.calculated_end_time) : "Не задано"

        // Описание
        actionDescriptionText.text = action.snapshot_description || ""

        // Статус
        var statusText = ""
        var statusColor = "#95a5a6"
        if (action.status === "completed") {
            statusText = "✅ Выполнено"
            statusColor = "#27ae60"
        } else if (action.status === "in_progress") {
            statusText = "🔄 В процессе"
            statusColor = "#f39c12"
        } else if (action.status === "pending") {
            statusText = "⏸ Ожидает"
            statusColor = "#3498db"
        } else if (action.status === "skipped") {
            statusText = "❌ Пропущено"
            statusColor = "#e74c3c"
        }
        statusLabel.text = statusText
        statusRectangle.color = statusColor

        // Отчётные материалы
        reportMaterialsList.clear()
        if (action.snapshot_report_materials) {
            var materials = action.snapshot_report_materials.split('\n')
            for (var i = 0; i < materials.length; i++) {
                if (materials[i].trim()) {
                    reportMaterialsList.append({ "path": materials[i].trim() })
                }
            }
        }

        // Кому доложено
        reportedToLabel.text = action.reported_to || "—"

        // Справочные материалы организаций
        loadOrganizationsForAction(action.id)

        // Обновляем таймер
        updateCountdown()
        checkOverdue()
    }

    function loadOrganizationsForAction(actionExecutionId) {
        orgsList.clear()
        var orgs = appData.getOrganizationsForActionExecution(actionExecutionId)
        if (orgs && orgs.length > 0) {
            for (var i = 0; i < orgs.length; i++) {
                orgsList.append(orgs[i])
            }
        }
    }

    function formatDateTime(dtStr) {
        if (!dtStr) return ""
        var dt = new Date(dtStr)
        if (isNaN(dt.getTime())) return dtStr
        var h = String(dt.getHours()).padStart(2, '0')
        var m = String(dt.getMinutes()).padStart(2, '0')
        var s = String(dt.getSeconds()).padStart(2, '0')
        var day = String(dt.getDate()).padStart(2, '0')
        var month = String(dt.getMonth() + 1).padStart(2, '0')
        var year = dt.getFullYear()
        return day + "." + month + "." + year + " " + h + ":" + m + ":" + s
    }

    // Фон
    background: Rectangle {
        id: dialogBackground
        radius: 12
        color: actionDetailsDialog.isOverdue ? (overduePulseTimer.running ? "#f5b7b1" : "#ffffff") : "#ffffff"
        border.color: actionDetailsDialog.isOverdue ? "#e74c3c" : "#e0e0e0"
        border.width: actionDetailsDialog.isOverdue ? 2 : 1
        Behavior on color { ColorAnimation { duration: 400 } }
    }

    // --- Основной макет ---
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        // --- Заголовок ---
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 70
            color: "#2c3e50"
            radius: 12
            clip: true

            Label {
                id: actionNameLabel
                anchors.centerIn: parent
                text: "Загрузка..."
                color: "#ffffff"
                font.pointSize: 18
                font.bold: true
                horizontalAlignment: Text.AlignHCenter
            }

            Button {
                anchors.right: parent.right
                anchors.rightMargin: 15
                anchors.verticalCenter: parent.verticalCenter
                text: "✕"
                font.pointSize: 14
                onClicked: actionDetailsDialog.close()
                background: Rectangle { color: "transparent" }
            }
        }

        // --- Разделитель ---
        Rectangle {
            Layout.fillWidth: true
            height: 2
            color: "#34495e"
        }

        // --- Основной контент (2 колонки) ---
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // === ЛЕВАЯ ЧАСТЬ ===
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.55
                Layout.fillHeight: true
                spacing: 0
                anchors.top: parent.top
                anchors.topMargin: 15
                anchors.left: parent.left
                anchors.leftMargin: 15

                // --- Времена ---
                GridLayout {
                    Layout.fillWidth: true
                    columns: 3
                    columnSpacing: 15
                    rowSpacing: 8

                    Label { text: "Начало:"; font.pixelSize: 13; color: "#666" }
                    Label {
                        id: calculatedStartTimeLabel
                        text: "—"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Label { text: ""; }

                    Label { text: "Окончание:"; font.pixelSize: 13; color: "#666" }
                    Label {
                        id: calculatedEndTimeLabel
                        text: "—"
                        font.pixelSize: 14
                        font.bold: true
                    }
                    Label { text: ""; }

                    Label { text: "Осталось:"; font.pixelSize: 13; color: "#666" }
                    Label {
                        id: remainingTimeLabel
                        text: "—"
                        font.pixelSize: 16
                        font.bold: true
                        color: "#27ae60"
                    }
                    Label { text: ""; }
                }

                // --- Описание ---
                Label {
                    text: "Технический текст:"
                    font.pixelSize: 13
                    color: "#666"
                    Layout.topMargin: 10
                }
                ScrollView {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 80
                    clip: true
                    TextArea {
                        id: actionDescriptionText
                        readOnly: true
                        wrapMode: TextArea.Wrap
                        font.pixelSize: 13
                        background: Rectangle { color: "#f8f9fa"; radius: 6; border.color: "#dee2e6"; border.width: 1 }
                    }
                }

                // --- Статус ---
                Rectangle {
                    id: statusRectangle
                    Layout.fillWidth: true
                    Layout.preferredHeight: 45
                    radius: 8
                    color: "#95a5a6"
                    Behavior on color { ColorAnimation { duration: 300 } }

                    Label {
                        id: statusLabel
                        anchors.centerIn: parent
                        text: "Загрузка..."
                        color: "#ffffff"
                        font.pixelSize: 16
                        font.bold: true
                    }
                }

                // --- Отчётные материалы и Кому доложено ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 120
                    spacing: 15
                    Layout.topMargin: 10

                    // Отчётные материалы
                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        spacing: 5

                        Label { text: "Отчётные материалы:"; font.pixelSize: 13; color: "#666" }
                        ScrollView {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            clip: true
                            ListView {
                                id: reportMaterialsList
                                model: ListModel { id: reportMaterialsModel }
                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 28
                                    color: index % 2 ? "#f9f9f9" : "#ffffff"
                                    Text {
                                        anchors.fill: parent
                                        anchors.margins: 5
                                        text: {
                                            var p = model.path || ""
                                            var parts = p.replace(/\\/g, "/").split("/")
                                            return parts.length > 0 ? parts[parts.length - 1] : p
                                        }
                                        font.pixelSize: 12
                                        elide: Text.ElideMiddle
                                        verticalAlignment: Text.AlignVCenter
                                        color: "#2980b9"
                                    }
                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.openUrlExternally("file:///" + model.path.replace(/\\/g, "/"))
                                    }
                                }
                                Label {
                                    anchors.centerIn: parent
                                    text: "Нет материалов"
                                    color: "#95a5a6"
                                    font.pixelSize: 12
                                    font.italic: true
                                    visible: reportMaterialsModel.count === 0
                                }
                            }
                        }
                    }

                    // Кому доложено
                    ColumnLayout {
                        Layout.preferredWidth: 200
                        Layout.fillHeight: true
                        spacing: 5

                        Label { text: "Кому доложено:"; font.pixelSize: 13; color: "#666" }
                        Label {
                            id: reportedToLabel
                            text: "—"
                            font.pixelSize: 14
                            wrapMode: Text.Wrap
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                        }
                    }
                }

                // --- Кнопки навигации ---
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 15
                    Layout.topMargin: 10

                    // Назад
                    Rectangle {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 36
                        radius: 8
                        color: {
                            if (prevBtn.pressed) return "#5d6d7e"
                            if (prevBtn.hovered) return "#85929e"
                            return "#95a5a6"
                        }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        enabled: actionDetailsDialog.currentActionIndex > 0
                        opacity: enabled ? 1.0 : 0.5
                        MouseArea {
                            id: prevBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: parent.enabled
                            onClicked: actionDetailsDialog.switchToPrevious()
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "← Предыдущее"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    // Номер действия
                    Label {
                        text: (actionDetailsDialog.currentActionIndex + 1) + " / " + actionDetailsDialog.totalActions
                        font.pixelSize: 14
                        color: "#2c3e50"
                    }

                    Item { Layout.fillWidth: true }

                    // Вперёд
                    Rectangle {
                        Layout.preferredWidth: 120
                        Layout.preferredHeight: 36
                        radius: 8
                        color: {
                            if (nextBtn.pressed) return "#1a6e8e"
                            if (nextBtn.hovered) return "#2980b9"
                            return "#3498db"
                        }
                        Behavior on color { ColorAnimation { duration: 150 } }
                        enabled: actionDetailsDialog.currentActionIndex < actionDetailsDialog.totalActions - 1
                        opacity: enabled ? 1.0 : 0.5
                        MouseArea {
                            id: nextBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: parent.enabled
                            onClicked: actionDetailsDialog.switchToNext()
                        }
                        Text {
                            anchors.centerIn: parent
                            text: "Следующее →"
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                // --- Автопереключение ---
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 8
                    spacing: 10

                    // Современный переключатель (toggle switch)
                    Rectangle {
                        width: 44
                        height: 24
                        radius: 12
                        color: actionDetailsDialog.autoSwitch ? "#27ae60" : "#bdc3c7"
                        Behavior on color { ColorAnimation { duration: 200 } }

                        Rectangle {
                            width: 20
                            height: 20
                            radius: 10
                            color: "#ffffff"
                            anchors.verticalCenter: parent.verticalCenter
                            x: actionDetailsDialog.autoSwitch ? parent.width - 22 : 2
                            Behavior on x { NumberAnimation { duration: 200 } }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: actionDetailsDialog.autoSwitch = !actionDetailsDialog.autoSwitch
                        }
                    }

                    Label {
                        text: "Автопереключение при истечении времени"
                        font.pixelSize: 12
                        color: "#666"
                    }
                }
            }

            // === РАЗДЕЛИТЕЛЬ ===
            Rectangle {
                Layout.preferredWidth: 2
                Layout.fillHeight: true
                color: "#dee2e6"
            }

            // === ПРАВАЯ ЧАСТЬ ===
            ColumnLayout {
                Layout.preferredWidth: parent.width * 0.45
                Layout.fillHeight: true
                spacing: 0
                anchors.top: parent.top
                anchors.topMargin: 15
                anchors.right: parent.right
                anchors.rightMargin: 15

                Label {
                    text: "📚 Справочный материал"
                    font.pointSize: 16
                    font.bold: true
                    Layout.bottomMargin: 10
                }

                // Список организаций
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: orgsList
                        model: ListModel { id: orgsModel }
                        delegate: Rectangle {
                            width: ListView.view.width
                            height: 45
                            color: index % 2 ? "#f9f9f9" : "#ffffff"
                            border.color: "#eee"
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 6
                                spacing: 8

                                // Иконки файлов
                                RowLayout {
                                    spacing: 3
                                    Repeater {
                                        model: {
                                            var files = []
                                            if (modelData && modelData.reference_files) {
                                                files = modelData.reference_files
                                            }
                                            return files
                                        }
                                        delegate: Rectangle {
                                            width: 26
                                            height: 26
                                            radius: 4
                                            color: {
                                                var ft = modelData.file_type || "other"
                                                if (ft === "word") return "#4a90e2"
                                                else if (ft === "excel") return "#27ae60"
                                                else if (ft === "pdf") return "#e74c3c"
                                                else return "#95a5a6"
                                            }
                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                ToolTip.text: modelData.file_path || ""
                                                ToolTip.visible: hovered
                                                ToolTip.delay: 500
                                                onClicked: {
                                                    var fp = modelData.file_path || ""
                                                    if (fp) Qt.openUrlExternally("file:///" + fp.replace(/\\/g, "/"))
                                                }
                                            }
                                            Text {
                                                anchors.centerIn: parent
                                                text: {
                                                    var ft = modelData.file_type || "other"
                                                    if (ft === "word") return "📝"
                                                    else if (ft === "excel") return "📊"
                                                    else if (ft === "pdf") return "📄"
                                                    else return "📎"
                                                }
                                                font.pixelSize: 13
                                            }
                                        }
                                    }
                                }

                                // Название организации
                                Text {
                                    Layout.fillWidth: true
                                    text: modelData.name || "Без названия"
                                    font.pixelSize: 13
                                    font.bold: true
                                    elide: Text.ElideRight
                                }

                                // Телефон
                                Text {
                                    Layout.preferredWidth: 100
                                    text: modelData.phone || "—"
                                    font.pixelSize: 13
                                    color: "#666"
                                    horizontalAlignment: Text.AlignRight
                                    elide: Text.ElideRight
                                }
                            }
                        }
                        Label {
                            anchors.centerIn: parent
                            text: "Нет организаций"
                            color: "#95a5a6"
                            font.pixelSize: 13
                            font.italic: true
                            visible: orgsModel.count === 0
                        }
                    }
                }
            }
        }
    }

    onOpened: {
        loadActionData()
    }
}
