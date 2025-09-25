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
    signal startNewAlgorithmRequested(string category) // Запрос на запуск нового алгоритма
    signal finishAlgorithmRequested(int executionId) // Запрос на завершение алгоритма
    signal expandAlgorithmRequested(int executionId) // Запрос на развертывание деталей алгоритма
    // --- ---

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
            
            // --- Календарь (пока заглушка) ---
            Button {
                text: "Календарь"
                onClicked: {
                    console.log("QML RunningAlgorithmsView: Нажата кнопка Календарь для категории:", categoryFilter);
                    // TODO: Открыть CalendarView
                }
            }
            // --- ---
        }
        // --- ---

        // --- Список запущенных алгоритмов ---
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            
            ListView {
                id: executionsListView
                model: ListModel {
                    id: executionsModel
                }
                delegate: Rectangle {
                    width: ListView.view.width
                    height: 80 // Увеличенная высота для деталей
                    color: index % 2 ? "#f9f9f9" : "#ffffff"
                    border.color: executionsListView.currentIndex === index ? "#3498db" : "#ddd"
                    
                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 2
                        
                        // Название алгоритма
                        Text {
                            Layout.fillWidth: true
                            text: model.algorithm_name || "Без названия"
                            font.bold: true
                            elide: Text.ElideRight
                        }
                        
                        // Ответственный
                        Text {
                            Layout.fillWidth: true
                            text: "Ответственный: " + (model.created_by_user_display_name || "Не назначен")
                            color: "gray"
                            font.pixelSize: 10
                            elide: Text.ElideRight
                        }
                        
                        // Статус и время
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10
                            
                            Text {
                                text: "Статус: " + (model.status || "неизвестен")
                                color: "gray"
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
                    }
                    
                    // Кнопки управления
                    RowLayout {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.margins: 5
                        spacing: 5
                        
                        Button {
                            text: "Завершить"
                            font.pixelSize: 10
                            onClicked: runningAlgorithmsViewRoot.finishAlgorithmRequested(model.id)
                        }
                        
                        Button {
                            text: "Развернуть"
                            font.pixelSize: 10
                            onClicked: runningAlgorithmsViewRoot.expandAlgorithmRequested(model.id)
                        }
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        onClicked: executionsListView.currentIndex = index
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
        console.log("QML RunningAlgorithmsView: Запрос списка запущенных алгоритмов для категории:", categoryFilter);
        // TODO: Вызвать метод Python для получения списка
        // var executionsList = appData.getRunningAlgorithmsByCategory(categoryFilter);
        // Заполнить executionsModel
    }
    
    Component.onCompleted: {
        console.log("QML RunningAlgorithmsView: Загружен. Категория:", categoryFilter);
        loadExecutions();
    }
}