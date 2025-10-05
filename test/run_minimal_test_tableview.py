# run_minimal_test_tableview.py
import sys
from pathlib import Path
from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QUrl

if __name__ == "__main__":
    app = QGuiApplication(sys.argv)
    engine = QQmlApplicationEngine()

    qml_file = Path(__file__).parent / "MinimalTestTableView.qml"
    print(f"Попытка загрузки QML-файла: {qml_file}")

    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        print("Ошибка: Не удалось загрузить QML-файл или в QML есть ошибки.")
        if engine.hasError():
            for error in engine.errors():
                print(f"QML Ошибка: {error.toString()}")
        sys.exit(-1)

    print("QML-файл успешно загружен. Приложение запущено.")
    sys.exit(app.exec())