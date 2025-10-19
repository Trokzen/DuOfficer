# notifications/notification_item_widget.py
import sys
from PySide6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QLabel, QPushButton
from PySide6.QtCore import QTimer, Qt
from PySide6.QtGui import QPalette, QFont

class NotificationItemWidget(QWidget):
    def __init__(self, title, message, icon_type, duration_ms, container_widget, parent=None): # <-- Добавлен container_widget
        super().__init__(parent)
        self.setFixedHeight(80)
        self.setAutoFillBackground(True)

        # --- Сохраняем ссылку на контейнер ---
        self.container_widget = container_widget # <-- Сохраняем
        # --- ---

        # --- Настройка фона в зависимости от типа ---
        palette = self.palette()
        if icon_type == "Warning":
            palette.setColor(QPalette.Window, Qt.red)
        elif icon_type == "Information":
            palette.setColor(QPalette.Window, Qt.lightGray)
        else:
            palette.setColor(QPalette.Window, Qt.white)
        self.setPalette(palette)
        # --- ---

        # --- Макет для содержимого ---
        main_layout = QHBoxLayout(self)
        main_layout.setContentsMargins(5, 5, 5, 5)
        main_layout.setSpacing(5)

        # --- Содержимое уведомления ---
        content_layout = QVBoxLayout()
        content_layout.setSpacing(2)

        self.title_label = QLabel(title)
        self.title_label.setWordWrap(True)
        self.title_label.setStyleSheet("font-weight: bold;")

        self.message_label = QLabel(message)
        self.message_label.setWordWrap(True)

        content_layout.addWidget(self.title_label)
        content_layout.addWidget(self.message_label)
        content_layout.addStretch()

        # --- Кнопка закрытия ---
        close_button = QPushButton("×")
        close_button.setFixedSize(20, 20)
        close_button.setStyleSheet(
            "QPushButton {"
            "   border: 1px solid gray;"
            "   border-radius: 10px;"
            "   font-weight: bold;"
            "   background-color: lightgray;"
            "}"
            "QPushButton:hover {"
            "   background-color: #ffcccc;"
            "}"
        )
        close_button.clicked.connect(self._on_close_clicked)

        # --- Добавляем элементы в основной макет ---
        main_layout.addLayout(content_layout)
        main_layout.addWidget(close_button)

        # --- Таймер для автоскрытия ---
        self.auto_hide_timer = QTimer(self)
        self.auto_hide_timer.timeout.connect(self._on_timer_timeout)
        self.auto_hide_timer.setSingleShot(True)
        self.auto_hide_timer.start(duration_ms)

    def _on_close_clicked(self):
        print(f"Python: Уведомление закрыто вручную: {self.title_label.text()}")
        self._cleanup()

    def _on_timer_timeout(self):
        print(f"Python: Время уведомления истекло: {self.title_label.text()}")
        self._cleanup()

    def _cleanup(self):
        # Останавливаем таймер
        self.auto_hide_timer.stop()

        # Удаляем себя из родительского макета
        parent_layout = self.parent().layout() # <-- parent() это self.content_widget
        if parent_layout:
            parent_layout.removeWidget(self)

        # Скрываем и удаляем виджет
        self.hide()
        self.deleteLater()

        # --- УВЕДОМЛЯЕМ РОДИТЕЛЬСКИЙ КОНТЕЙНЕР ОБ УДАЛЕНИИ ---
        # Вызываем метод у сохраненного контейнера
        if hasattr(self.container_widget, 'on_item_removed'):
            self.container_widget.on_item_removed()
        # --- ---

