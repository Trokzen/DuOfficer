# main.py
import sys
import traceback
from pathlib import Path
from PySide6.QtCore import Qt, QUrl, QDateTime, QTimer, Slot, QSettings
from PySide6.QtGui import QGuiApplication, QIcon, QAction
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtCore import QObject, Signal, Property
# --- Импорты для трея и сообщений ---
from PySide6.QtWidgets import QSystemTrayIcon, QMenu, QApplication, QMessageBox
# --- ИМПОРТЫ для работы с БД ---
from db.sqlite_config import SQLiteConfigManager
from db.postgresql_manager import PostgreSQLDatabaseManager
# --- ---


class ApplicationData(QObject):
    """Класс для передачи данных и управления логикой в QML."""
    # Сигналы для обновления свойств в QML
    currentTimeChanged = Signal()
    currentDateChanged = Signal()
    dutyOfficerChanged = Signal()
    workplaceNameChanged = Signal()
    # --- Новые сигналы ---
    loginScreenRequested = Signal()  # Сигнал для перехода на экран входа
    mainScreenRequested = Signal()   # Сигнал для перехода на основной экран
    settingsChanged = Signal() # Новый сигнал для уведомления об изменении настроек
    postNumberChanged = Signal()
    postNameChanged = Signal()
    localTimeChanged = Signal()
    moscowTimeChanged = Signal()
    localDateChanged = Signal()   # Сигнал для изменения местной даты
    moscowDateChanged = Signal()  # Сигнал для изменения московской даты    
    timeSettingsChanged = Signal() # Сигнал для обновления настроек времени
    backgroundImagePathChanged = Signal()
    algorithmsListChanged = Signal()
    printFontFamilyChanged = Signal()
    printFontSizeChanged = Signal()
    printFontStyleChanged = Signal()


    def load_initial_settings(self):
        """Загружает начальные настройки при запуске приложения"""
        try:
            if self.sqlite_config_manager:
                settings = self.sqlite_config_manager.get_app_settings()
                if settings:
                    # Обновляем свойства приложения
                    if 'workplace_name' in settings and settings['workplace_name']:
                        self._workplace_name = settings['workplace_name']
                        self.workplaceNameChanged.emit()
                    
                    if 'post_number' in settings and settings['post_number']:
                        self._post_number = str(settings['post_number'])
                        self.postNumberChanged.emit()
                    
                    if 'post_name' in settings and settings['post_name']:
                        self._post_name = settings['post_name']
                        self.postNameChanged.emit()
                    
                    updated_time_props = False
                    
                    if 'custom_time_label' in settings and settings['custom_time_label']:
                        self._custom_time_label = settings['custom_time_label']
                        updated_time_props = True
                        print(f"Python: Загружено custom_time_label: '{self._custom_time_label}'")

                    # Загружаем смещение как число секунд
                    if 'custom_time_offset_seconds' in settings and isinstance(settings['custom_time_offset_seconds'], int):
                        self._custom_time_offset_seconds = settings['custom_time_offset_seconds']
                        updated_time_props = True
                        print(f"Python: Загружено custom_time_offset_seconds: {self._custom_time_offset_seconds}")

                    if 'show_moscow_time' in settings:
                        # Преобразуем 1/0 из SQLite в True/False
                        self._show_moscow_time = bool(settings['show_moscow_time'])
                        updated_time_props = True
                        print(f"Python: Загружено show_moscow_time: {self._show_moscow_time}")

                    # Загружаем смещение Москвы как число секунд
                    if 'moscow_time_offset_seconds' in settings and isinstance(settings['moscow_time_offset_seconds'], int):
                        self._moscow_time_offset_seconds = settings['moscow_time_offset_seconds']
                        updated_time_props = True
                        print(f"Python: Загружено moscow_time_offset_seconds: {self._moscow_time_offset_seconds}")

                    if updated_time_props:
                        print("Python: Некоторые настройки времени обновлены из БД.")
                        # Принудительно обновляем рассчитываемые времена
                        self.update_time()
                        # Уведомляем QML об изменении настроек времени
                        self.timeSettingsChanged.emit()
                    # --- ---
                    
                    # --- НОВОЕ: Загрузка настроек внешнего вида ---
                    updated_appearance_props = False
                    
                    # Путь к фоновому изображению/эмблеме
                    if 'background_image_path' in settings:
                        bg_image_path = settings['background_image_path']
                        # Устанавливаем путь, если он не None и не пустая строка
                        if bg_image_path is not None and str(bg_image_path).strip() != "":
                            self._background_image_path = str(bg_image_path).strip()
                        else:
                            # Если путь None или пустая строка, оставляем как есть (None или дефолтный путь)
                            # self._background_image_path = None # <-- Опционально: явно установить None
                            pass 
                        self.backgroundImagePathChanged.emit() # <-- ВАЖНО: Уведомляем QML
                        updated_appearance_props = True
                        print(f"Python: Загружен background_image_path: '{self._background_image_path}'")

                    # ... (здесь можно добавить загрузку других настроек внешнего вида: font_family, font_size и т.д.) ...
                    
                    # --- НОВОЕ: Загрузка настроек шрифта печати ---
                    updated_print_props = False
                    if 'print_font_family' in settings and settings['print_font_family']:
                        self._print_font_family = settings['print_font_family']
                        self.printFontFamilyChanged.emit()
                        updated_print_props = True
                        print(f"Python: Загружен print_font_family: {self._print_font_family}")

                    if 'print_font_size' in settings and isinstance(settings['print_font_size'], int):
                        self._print_font_size = settings['print_font_size']
                        self.printFontSizeChanged.emit()
                        updated_print_props = True
                        print(f"Python: Загружен print_font_size: {self._print_font_size}")
                    
                    # --- ДОБАВЛЕНО: Загрузка начертания шрифта печати ---
                    if 'print_font_style' in settings and settings['print_font_style']:
                        self._print_font_style = settings['print_font_style']
                        self.printFontStyleChanged.emit() # <-- Добавлено
                        updated_print_props = True
                        print(f"Python: Загружен print_font_style: {self._print_font_style}")

                    if updated_appearance_props:
                        print("Python: Некоторые настройки внешнего вида обновлены из БД.")
                        # Уведомляем QML об общем изменении настроек (если нужно)
                        # self.settingsChanged.emit() # <-- Опционально: если используется глобальный сигнал
                    # --- ---
                    
                    print(f"Python: Начальные настройки (включая время и внешний вид) загружены.")
        except Exception as e:
            print(f"Python: Ошибка при загрузке начальных настроек (включая время и внешний вид): {e}")
            import traceback
            traceback.print_exc()

    def __init__(self, app, engine, sqlite_config_manager):
        """
        Инициализирует контекст данных приложения.
        :param app: Экземпляр QApplication.
        :param engine: Экземпляр QQmlApplicationEngine.
        :param sqlite_config_manager: Экземпляр SQLiteConfigManager.
        """
        super().__init__()
        self.app = app
        self.engine = engine
        # --- Менеджеры БД ---
        self.sqlite_config_manager = sqlite_config_manager
        self.pg_database_manager = None  # Будет создан после успешного входа
        # --- ---
        self.window = None # Ссылка на ApplicationWindow из QML
        self._current_user = None # Данные вошедшего пользователя

        # --- Инициализация свойств (временно из заглушек, позже из БД) ---
        self._workplace_name = "Рабочее место дежурного"
        self._duty_officer = "Не выбран"
        self._current_time = QDateTime.currentDateTime().toString("hh:mm:ss")
        self._current_date = QDateTime.currentDateTime().toString("dd.MM.yyyy")
        self._post_number = "1"  # Значение по умолчанию
        self._post_name = "Дежурство по части"  # Значение по умолчанию
                # --- НОВЫЕ свойства для времени ---
        self._local_time = self._current_time # Инициализируем как текущее
        self._moscow_time = self._current_time # Инициализируем как текущее
        self._custom_time_label = "Местное время" # Значение по умолчанию
        self._custom_time_offset_seconds = 0 # Смещение в секундах (удобнее для расчетов)
        self._show_moscow_time = True
        self._moscow_time_offset_seconds = 0 # Смещение Москвы в секундах
        # --- ИНИЦИАЛИЗАЦИЯ НОВЫХ СВОЙСТВ ДЛЯ ДАТ ---
        self._local_date = self._current_date # <-- Новое внутреннее свойство
        self._moscow_date = self._current_date # <-- Новое внутреннее свойство
        self._print_font_family = "Arial" # Значение по умолчанию
        self._print_font_size = 12        # Значение по умолчанию
        # --- НОВОЕ СВОЙСТВО ДЛЯ НАЧЕРТАНИЯ ШРИФТА ПЕЧАТИ ---
        self._print_font_style = "normal" # Значение по умолчанию # <-- Добавлено
        # --- ---
        # Инициализируем путь к эмблеме значением по умолчанию или None
        self._background_image_path = None # <-- ИЛИ путь к дефолтной эмблеме, если нужно

    # Загружаем начальные настройки
        self.load_initial_settings()
        
        self.tray_icon = None
        self.close_confirmation_shown = False

        # Таймер для обновления времени
        self.timer = QTimer()
        self.timer.timeout.connect(self.update_time)
        # self.timer.start(1000) # Запускаем таймер позже, когда основной экран активен

        # Подключаемся к сигналу, когда объекты QML созданы
        self.engine.objectCreated.connect(self.on_qml_objects_created)

    def on_qml_objects_created(self, obj, url):
        """Вызывается, когда QML объекты загружены."""
        if obj is not None and url.fileName() == "main.qml":
            self.window = obj
            self.setup_tray()
            print("Python: QML объекты загружены. Ссылка на window установлена.")

    def setup_tray(self):
        """Настройка иконки в системном трее."""
        if not QSystemTrayIcon.isSystemTrayAvailable():
            print("Системный трей недоступен.")
            return

        # --- Создание иконки трея ---
        icon_path = Path(__file__).parent / "resources" / "images" / "placeholder_emblem.png"
        self.tray_icon = QSystemTrayIcon(QIcon(str(icon_path)), self.app)
        self.tray_icon.setToolTip("ВПО «Алгоритм-ДЧ»")

        # --- Создание контекстного меню для трея ---
        tray_menu = QMenu()
        restore_action = QAction("Восстановить", tray_menu)
        minimize_action = QAction("Свернуть", tray_menu)
        maximize_action = QAction("Развернуть", tray_menu)
        quit_action = QAction("Выход", tray_menu)

        restore_action.triggered.connect(self.restore_window)
        minimize_action.triggered.connect(self.minimize_window)
        maximize_action.triggered.connect(self.maximize_window)
        quit_action.triggered.connect(self.quit_app)

        tray_menu.addAction(restore_action)
        tray_menu.addAction(minimize_action)
        tray_menu.addAction(maximize_action)
        tray_menu.addSeparator()
        tray_menu.addAction(quit_action)

        self.tray_icon.setContextMenu(tray_menu)
        self.tray_icon.activated.connect(self.on_tray_icon_activated)
        self.tray_icon.show()
        print("Иконка в трее создана и показана.")

    def update_time(self):
        """Обновляет текущее время, местное время и московское время."""
        now_system = QDateTime.currentDateTime() # Время системы QDateTime
        
        # --- Обновляем основное (системное) время и ДАТУ ---
        self._current_time = now_system.toString("hh:mm:ss")
        # --- ОБНОВЛЕНО: Обновляем и системную дату ---
        self._current_date = now_system.toString("dd.MM.yyyy") 
        # --- ---
        self.currentTimeChanged.emit()
        # --- ОБНОВЛЕНО: Эмитируем сигнал о смене системной даты ---
        self.currentDateChanged.emit() 
        # --- ---

        # --- Рассчитываем и обновляем местное время и ДАТУ ---
        # Создаем QDateTime для местного времени на основе системного
        local_dt = now_system.addSecs(self._custom_time_offset_seconds)
        self._local_time = local_dt.toString("hh:mm:ss")
        # --- НОВОЕ: Рассчитываем и обновляем местную дату ---
        self._local_date = local_dt.toString("dd.MM.yyyy") 
        # --- ---
        self.localTimeChanged.emit()
        # --- НОВОЕ: Эмитируем сигнал о смене местной даты ---
        self.localDateChanged.emit() 
        # --- ---

        # --- Рассчитываем и обновляем московское время и ДАТУ ---
        # Создаем QDateTime для московского времени на основе системного
        moscow_dt = now_system.addSecs(self._moscow_time_offset_seconds)
        self._moscow_time = moscow_dt.toString("hh:mm:ss")
        # --- НОВОЕ: Рассчитываем и обновляем московскую дату ---
        self._moscow_date = moscow_dt.toString("dd.MM.yyyy") 
        # --- ---
        self.moscowTimeChanged.emit()
        # --- НОВОЕ: Эмитируем сигнал о смене московской даты ---
        self.moscowDateChanged.emit() 
        # --- ---

    # --- Свойства для QML ---
    @Property(str, notify=workplaceNameChanged)
    def workplaceName(self):
        return self._workplace_name

    @Property(str, notify=dutyOfficerChanged)
    def dutyOfficer(self):
        return self._duty_officer

    @Property(str, notify=currentTimeChanged)
    def currentTime(self):
        return self._current_time

    @Property(str, notify=currentDateChanged)
    def currentDate(self):
        return self._current_date
    
    @Property(str, notify=postNumberChanged)
    def postNumber(self):
        return self._post_number

    @Property(str, notify=postNameChanged)
    def postName(self):
        return self._post_name

    @Property(str, notify=localTimeChanged)
    def localTime(self):
        return self._local_time

    @Property(str, notify=moscowTimeChanged)
    def moscowTime(self):
        return self._moscow_time

    # --- СВОЙСТВА ДЛЯ ДАТ ---
    @Property(str, notify=localDateChanged) # <-- Новый сигнал
    def localDate(self):
        """Настраиваемая местная дата."""
        return self._local_date # <-- Новое внутреннее свойство

    @Property(str, notify=moscowDateChanged) # <-- Новый сигнал
    def moscowDate(self):
        """Московская дата."""
        return self._moscow_date # <-- Новое внутреннее свойство
    # --- ---

    @Property(str, notify=timeSettingsChanged)
    def customTimeLabel(self):
        return self._custom_time_label

    @Property(bool, notify=timeSettingsChanged)
    def showMoscowTime(self):
        return self._show_moscow_time

    @Property(str, notify=backgroundImagePathChanged)
    def backgroundImagePath(self):
        return self._background_image_path

    @Property(str, notify=printFontFamilyChanged)
    def printFontFamily(self):
        return self._print_font_family

    @Property(int, notify=printFontSizeChanged)
    def printFontSize(self):
        return self._print_font_size

    # --- НОВОЕ СВОЙСТВО ДЛЯ НАЧЕРТАНИЯ ШРИФТА ПЕЧАТИ ---
    @Property(str, notify=printFontStyleChanged) # <-- Добавлено
    def printFontStyle(self):                   # <-- Добавлено
        return self._print_font_style           # <-- Добавлено

    @Slot(str)
    def setDutyOfficer(self, name):
        """Слот для установки дежурного из QML."""
        self._duty_officer = name
        self.dutyOfficerChanged.emit()

    @Slot(str)
    def setWorkplaceName(self, name):
        """Слот для установки названия рабочего места из QML."""
        self._workplace_name = name
        self.workplaceNameChanged.emit()

    # --- НОВЫЕ СЛОТЫ ДЛЯ УПРАВЛЕНИЯ СОСТОЯНИЕМ ПРИЛОЖЕНИЯ ---

    @Slot()
    def requestLoginScreen(self):
        """Слот для запроса перехода на экран входа."""
        print("Python: Запрошен переход на экран входа.")
        self.loginScreenRequested.emit()

    @Slot()
    def requestMainScreen(self):
        """Слот для запроса перехода на основной экран."""
        print("Python: Запрошен переход на основной экран.")
        # Здесь можно добавить дополнительную логику инициализации
        self.mainScreenRequested.emit()
        # Запускаем таймер только когда основной экран активен
        if not self.timer.isActive():
            self.timer.start(1000)

    # --- СЛОТЫ ДЛЯ АУТЕНТИФИКАЦИИ ---

    @Slot(str, str, result='QVariant') # Возвращаем bool (успех) или str (ошибка)
    def authenticateAndLogin(self, login, password):
        """
        Слот для аутентификации пользователя и входа в систему.
        :param login: Логин пользователя.
        :param password: Пароль пользователя.
        :return: True если успех, иначе строка с сообщением об ошибке.
        """
        print(f"Python: Попытка аутентификации для логина '{login}'...")
        
        if not login or not password:
            return "Логин и пароль не могут быть пустыми."

        # 1. Проверяем, есть ли конфигурация подключения к PG
        pg_config = self.sqlite_config_manager.get_connection_config()
        if not pg_config:
             return "Конфигурация подключения к БД не найдена. Перейдите в 'Настройки'."

        # Проверяем, не пустой ли пароль в конфиге
        if not pg_config.get('password'):
             return "Пароль подключения к БД не задан. Перейдите в 'Настройки'."

        # 2. Если pg_database_manager еще не создан или конфиг изменился, создаем новый
        # (Для простоты будем создавать всегда, если конфиг есть)
        try:
            self.pg_database_manager = PostgreSQLDatabaseManager(pg_config)
            if not self.pg_database_manager.test_connection():
                 return "Не удалось подключиться к базе данных PostgreSQL. Проверьте настройки."
        except Exception as e:
             print(f"Python: Ошибка создания/тестирования подключения к PG: {e}")
             return f"Ошибка подключения к БД: {e}"

        # 3. Пытаемся аутентифицировать пользователя
        try:
            user_data = self.pg_database_manager.authenticate_user(login, password)
            if user_data:
                print(f"Python: Пользователь {user_data['login']} аутентифицирован успешно.")
                # TODO: Сохранить user_data в self для дальнейшего использования
                self._current_user = user_data
                
                # 4. Переключаемся на основной экран
                self.requestMainScreen()
                return True # Успех
            else:
                print(f"Python: Аутентификация для '{login}' не удалась.")
                return "Неверный логин или пароль."
        except Exception as e:
             print(f"Python: Неизвестная ошибка при аутентификации: {e}")
             return "Ошибка аутентификации."

    @Slot()
    def openConnectionSettings(self):
        """
        Слот для открытия диалога настроек подключения к БД.
        Пока просто выводим сообщение.
        """
        print("Python: Запрошено открытие настроек подключения к БД.")
        # TODO: Реализовать открытие диалога настроек (QML Dialog или отдельное окно)
        # Например, можно использовать QML Dialog внутри LoginView.qml
        # или создать отдельный QML компонент и управлять им отсюда.
        # Пока выведем в консоль.
        print("Python: Диалог настроек подключения (TODO).")
        return "Открытие настроек подключения (функция в разработке)."

    # --- СЛОТЫ ДЛЯ РАБОТЫ С НАСТРОЙКАМИ ПОДКЛЮЧЕНИЯ К БД ---

    @Slot(result='QVariant') # QVariantMap в Python это dict
    def getPgConnectionConfig(self):
        """
        Возвращает текущую конфигурацию подключения к PostgreSQL из SQLite.
        Вызывается QML при открытии диалога настроек подключения.
        """
        print("Python: QML запросил конфигурацию подключения к PG.")
        if self.sqlite_config_manager:
            try:
                config = self.sqlite_config_manager.get_connection_config()
                if config:
                    print(f"Python: Конфигурация PG загружена из SQLite.")
                    # Отправляем конфиг в QML (без пароля)
                    safe_config = {k: v for k, v in config.items() if k != 'password'}
                    return safe_config
                else:
                    print("Python: Конфигурация PG в SQLite не найдена.")
                    return {}
            except Exception as e:
                print(f"Python: Ошибка при получении конфигурации PG из SQLite: {e}")
        else:
            print("Python: SQLiteConfigManager не инициализирован.")
        return {}

    @Slot('QVariant', result='QVariant')
    def savePgConnectionConfig(self, new_config):
        """
        Сохраняет новую конфигурацию подключения к PostgreSQL в SQLite.
        Вызывается QML при нажатии "Сохранить" в диалоге настроек подключения.
        :param new_config: Словарь с новыми настройками подключения.
        :return: True если успешно, иначе строка с сообщением об ошибке.
        """
        print(f"Python: QML отправил обновление конфигурации подключения к PG. Исходный тип new_config: {type(new_config)}, Значение: {new_config}")
        
        # Преобразование QJSValue/QVariant в словарь Python
        if hasattr(new_config, 'toVariant'):
            new_config = new_config.toVariant()
            print(f"Python: QJSValue (new_config) преобразован в: {new_config}")

        # Проверка типа и содержимого
        if not isinstance(new_config, dict):
            error_msg = f"Некорректный тип данных конфигурации. Ожидался dict, получен {type(new_config)}."
            print(f"Python: {error_msg}")
            return error_msg

        if not new_config:
            error_msg = "Получен пустой словарь конфигурации."
            print(f"Python: {error_msg}")
            return error_msg

        # Проверяем наличие обязательных ключей
        required_keys = ["host", "port", "dbname", "user"]
        missing_keys = [key for key in required_keys if key not in new_config]
        if missing_keys:
            error_msg = f"В конфигурации отсутствуют обязательные поля: {missing_keys}"
            print(f"Python: {error_msg}")
            return error_msg

        if self.sqlite_config_manager:
            try:
                # 1. Получаем текущую конфигурацию
                current_config = self.sqlite_config_manager.get_connection_config()
                current_password = current_config.get('password') if current_config else ""

                # 2. Проверяем, передан ли новый пароль
                new_password = new_config.get('new_password')  # Из QML приходит как 'new_password'
                
                # 3. Определяем, какой пароль использовать
                if new_password and new_password.strip():  # Если передан новый пароль и он не пустой
                    final_password = new_password.strip()
                    print(f"Python: Используется новый пароль из QML")
                else:
                    final_password = current_password  # Используем старый пароль
                    print(f"Python: Используется существующий пароль из БД")

                # 4. Подготавливаем полную конфигурацию для сохранения
                try:
                    full_new_config = {
                        "host": str(new_config.get("host", "")),
                        "port": int(new_config.get("port")), # Преобразуем в int
                        "dbname": str(new_config.get("dbname", "")),
                        "user": str(new_config.get("user", "")),
                        "password": final_password  # Используем правильный пароль
                    }
                except (ValueError, TypeError) as e:
                    error_msg = f"Ошибка преобразования данных конфигурации: {e}. Проверьте правильность введенных значений (особенно порт)."
                    print(f"Python: {error_msg}")
                    return error_msg

                # 5. Проверка обязательных полей
                if not all([full_new_config['host'], full_new_config['dbname'], full_new_config['user']]):
                    error_msg = "Хост, имя БД и пользователь не могут быть пустыми строками."
                    print(f"Python: {error_msg}")
                    return error_msg

                # 6. Сохраняем в SQLite
                self.sqlite_config_manager.save_connection_config(**full_new_config)
                print("Python: Конфигурация подключения к PG успешно сохранена в SQLite.")
                return True # Успех
            except Exception as e:
                error_msg = f"Ошибка сохранения конфигурации PG в SQLite: {e}"
                print(f"Python: {error_msg}")
                import traceback
                traceback.print_exc()
                return error_msg
        else:
            error_msg = "SQLiteConfigManager не инициализирован."
            print(f"Python: {error_msg}")
            return error_msg

    # --- СЛОТЫ ДЛЯ РАБОТЫ С НАСТРОЙКАМИ ПРИЛОЖЕНИЯ ---

    @Slot(result='QVariant')
    def getFullSettings(self):
        """
        Возвращает полный словарь настроек приложения из SQLite.
        Вызывается QML при открытии экрана настроек.
        """
        print("Python: QML запросил полные настройки приложения из SQLite.")
        if self.sqlite_config_manager:
            try:
                settings = self.sqlite_config_manager.get_app_settings()
                if settings:
                    print(f"Python: Настройки приложения загружены из SQLite")
                    return settings
                else:
                    print("Python: Настройки приложения не найдены в SQLite.")
                    return {}
            except Exception as e:
                print(f"Python: Ошибка при получении настроек: {e}")
                import traceback
                traceback.print_exc()
                return {}
        else:
            print("Python: SQLiteConfigManager не инициализирован.")
            return {}

    @Slot('QVariant', result='QVariant')
    def updateSettings(self, new_settings):
        """
        Обновляет настройки приложения в SQLite из QML.
        :param new_settings: Словарь новых настроек.
        :return: True если успешно, иначе строка с сообщением об ошибке.
        """
        print("Python: QML отправил обновление настроек приложения в SQLite:", new_settings)
        
        # Преобразование QJSValue/QVariant в словарь Python
        if hasattr(new_settings, 'toVariant'):
            new_settings = new_settings.toVariant()
            print(f"Python: QJSValue (new_settings) преобразован в: {new_settings}")

        # Проверка типа и содержимого
        if not isinstance(new_settings, dict):
            error_msg = f"Некорректный тип данных настроек. Ожидался dict, получен {type(new_settings)}."
            print(f"Python: {error_msg}")
            return error_msg

        if not new_settings:
            error_msg = "Получен пустой словарь настроек."
            print(f"Python: {error_msg}")
            return error_msg

        if self.sqlite_config_manager:
            try:
                success = self.sqlite_config_manager.update_app_settings(new_settings)
                if success:
                    print("Python: Настройки приложения успешно обновлены в SQLite.")
                    # --- Обновляем локальные свойства ApplicationData в реальном времени ---
                    updated_props = False
                    updated_time_props = False # Флаг для отслеживания изменений времени
                    # Обновляем локальные свойства ApplicationData в реальном времени
                    updated_properties = False
                    if 'workplace_name' in new_settings and new_settings['workplace_name'] is not None:
                        self._workplace_name = str(new_settings['workplace_name'])
                        self.workplaceNameChanged.emit()
                        updated_properties = True
                        print(f"Python: Обновлено workplace_name: {self._workplace_name}")
                    
                    if 'post_number' in new_settings and new_settings['post_number'] is not None:
                        self._post_number = str(new_settings['post_number'])
                        self.postNumberChanged.emit()
                        updated_properties = True
                        print(f"Python: Обновлен post_number: {self._post_number}")

                    if 'post_name' in new_settings and new_settings['post_name'] is not None:
                        self._post_name = str(new_settings['post_name'])
                        self.postNameChanged.emit()
                        updated_properties = True
                        print(f"Python: Обновлен post_name: {self._post_name}")
                    
                    if 'custom_time_label' in new_settings:
                        self._custom_time_label = str(new_settings['custom_time_label'])
                        self.timeSettingsChanged.emit() # Уведомляем об изменении метки
                        updated_props = True
                        updated_time_props = True
                        print(f"Python: Обновлен custom_time_label: {self._custom_time_label}")

                    if 'custom_time_offset_seconds' in new_settings:
                         # Убедимся, что это целое число
                         try:
                             offset_secs = int(new_settings['custom_time_offset_seconds'])
                             self._custom_time_offset_seconds = offset_secs
                             updated_props = True
                             updated_time_props = True
                             print(f"Python: Обновлен custom_time_offset_seconds: {self._custom_time_offset_seconds}")
                         except (ValueError, TypeError):
                             print(f"Python: Ошибка преобразования custom_time_offset_seconds: {new_settings['custom_time_offset_seconds']}")

                    if 'show_moscow_time' in new_settings:
                        # Преобразуем в булево
                        self._show_moscow_time = bool(new_settings['show_moscow_time'])
                        self.timeSettingsChanged.emit() # Уведомляем об изменении флага показа
                        updated_props = True
                        updated_time_props = True
                        print(f"Python: Обновлен show_moscow_time: {self._show_moscow_time}")
                        
                    if 'moscow_time_offset_seconds' in new_settings:
                         # Убедимся, что это целое число
                         try:
                             moscow_offset_secs = int(new_settings['moscow_time_offset_seconds'])
                             self._moscow_time_offset_seconds = moscow_offset_secs
                             updated_props = True
                             updated_time_props = True
                             print(f"Python: Обновлен moscow_time_offset_seconds: {self._moscow_time_offset_seconds}")
                         except (ValueError, TypeError):
                             print(f"Python: Ошибка преобразования moscow_time_offset_seconds: {new_settings['moscow_time_offset_seconds']}")

                    # --- Обновляем свойства, связанные с внешним видом ---
                    if 'background_image_path' in new_settings and new_settings['background_image_path'] is not None:
                        self._background_image_path = str(new_settings['background_image_path']) if new_settings['background_image_path'] else None
                        self.backgroundImagePathChanged.emit() # <-- Сигнал для backgroundImagePath
                        updated_properties = True
                        print(f"Python: Обновлен background_image_path: {self._background_image_path}")

                    if updated_properties:
                        print("Python: Локальные свойства обновлены.")
                        self.settingsChanged.emit()
                        # --- Если изменялись настройки времени, обновляем рассчитываемые времена ---
                        if updated_time_props:
                            print("Python: Обнаружены изменения настроек времени. Пересчет localTime/moscowTime...")
                            self.update_time() # Пересчитываем localTime и moscowTime
                        # --- ---
                        # Уведомляем QML об общем изменении настроек (если нужно)
                        # self.settingsChanged.emit() # (если такой сигнал используется глобально)

                    # --- НОВОЕ: Обновление локальных свойств ApplicationData для шрифта печати ---
                    updated_print_props = False
                    if 'print_font_family' in new_settings:
                        self._print_font_family = new_settings['print_font_family']
                        self.printFontFamilyChanged.emit()
                        updated_print_props = True
                        print(f"Python: Обновлен print_font_family: {self._print_font_family}")

                    if 'print_font_size' in new_settings:
                        self._print_font_size = new_settings['print_font_size']
                        self.printFontSizeChanged.emit()
                        updated_print_props = True
                        print(f"Python: Обновлен print_font_size: {self._print_font_size}")
                    
                    # --- ДОБАВЛЕНО: Обновление начертания шрифта печати ---
                    if 'print_font_style' in new_settings:
                        self._print_font_style = new_settings['print_font_style']
                        self.printFontStyleChanged.emit() # <-- Добавлено
                        updated_print_props = True
                        print(f"Python: Обновлен print_font_style: {self._print_font_style}")
                    
                    return True
                else:
                    error_msg = "Не удалось обновить настройки приложения в SQLite."
                    print(f"Python: {error_msg}")
                    return error_msg
                    
            except Exception as e:
                error_msg = f"Ошибка БД SQLite при обновлении настроек: {e}"
                print(f"Python: {error_msg}")
                import traceback
                traceback.print_exc()
                return error_msg
        else:
            error_msg = "SQLiteConfigManager не инициализирован."
            print(f"Python: {error_msg}")
            return error_msg

    # --- СЛОТЫ ДЛЯ РАБОТЫ С ДОЛЖНОСТНЫМИ ЛИЦАМИ (ПОЛЬЗОВАТЕЛЯМИ) ---

    @Slot(result=list) # Возвращаем список словарей
    def getDutyOfficersList(self):
        """Возвращает список всех активных должностных лиц для QML."""
        try:
            if self.pg_database_manager:
                officers = self.pg_database_manager.get_all_users()
            else:
                # Заглушка, если нет подключения
                officers = [
                    {'id': 1, 'rank': 'ст. лейтенант', 'last_name': 'Иванов', 'first_name': 'Иван', 'middle_name': 'Иванович', 'phone': '123-456-789', 'is_active': 1, 'is_admin': 0},
                    {'id': 2, 'rank': 'лейтенант', 'last_name': 'Петров', 'first_name': 'Пётр', 'middle_name': 'Петрович', 'phone': '987-654-321', 'is_active': 1, 'is_admin': 0},
                ]
            print(f"Python: QML запросил список должностных лиц. Найдено: {len(officers)}")
            # ВАЖНО: PySide/Qt может требовать простые типы данных.
            # Если объекты row_factory sqlite3.Row не сериализуются корректно,
            # преобразуем их в словари явно.
            result = []
            for officer in officers:
                # officer уже должен быть dict благодаря row_factory, но на всякий случай
                if isinstance(officer, dict):
                    result.append(officer)
                else:
                    # Если это sqlite3.Row, преобразуем
                    result.append(dict(officer))
            return result
        except Exception as e:
            print(f"Python: Ошибка при получении списка должностных лиц: {e}")
            import traceback
            traceback.print_exc() # Для более детального лога ошибок
            return []

    @Slot('QVariant', result=int) # Принимает QVariantMap (dict), возвращает int (ID нового пользователя или -1 в случае ошибки)
    def addDutyOfficer(self, officer_data):
        """
        Добавляет нового должностного лица в PostgreSQL.
        :param officer_data: Словарь с данными нового пользователя.
        :return: ID нового пользователя, если успешно, иначе -1.
        """
        print("Python: QML отправил запрос на добавление нового пользователя (должностного лица).")
        print(f"Python: Исходные данные officer_data (тип: {type(officer_data)}): {officer_data}")

        # --- НОВОЕ: Преобразование QJSValue/QVariant в словарь Python ---
        # Это решает проблему "QJSValue object at ..."
        if hasattr(officer_data, 'toVariant'): # Проверка для QJSValue
            officer_data = officer_data.toVariant()
            print(f"Python: QJSValue (officer_data) преобразован в: {officer_data}")
        # --- ---

        # --- УЛУЧШЕННАЯ проверка типа и содержимого ---
        if not isinstance(officer_data, dict):
             print(f"Python: Ошибка - officer_data не является словарем. Получен тип: {type(officer_data)}")
             return -1 # Возвращаем -1 в случае ошибки типа

        if not officer_data:
             print("Python: Ошибка - officer_data пуст.")
             return -1 # Возвращаем -1 в случае пустых данных
        # --- ---

        if self.pg_database_manager:
            try:
                # --- Подготовка данных для передачи в менеджер БД ---
                # Убедимся, что все ключи присутствуют и имеют правильный тип/значение по умолчанию
                prepared_data = {
                    'rank': str(officer_data.get('rank', '')).strip(),
                    'last_name': str(officer_data.get('last_name', '')).strip(),
                    'first_name': str(officer_data.get('first_name', '')).strip(),
                    'middle_name': str(officer_data.get('middle_name', '')).strip() or None, # '' или None -> None
                    'phone': str(officer_data.get('phone', '')).strip() or None, # '' или None -> None
                    'is_active': 1 if officer_data.get('is_active') else 0, # Преобразуем в 1/0
                    'is_admin': 1 if officer_data.get('is_admin') else 0,   # Преобразуем в 1/0
                    'login': str(officer_data.get('login', '')).strip(), # <-- Новое поле
                    'new_password': str(officer_data.get('new_password', '')) if officer_data.get('new_password') else '', # <-- Новое поле
                }

                # --- Базовая валидация обязательных полей ---
                if not all([prepared_data['rank'], prepared_data['last_name'], prepared_data['first_name'], prepared_data['login']]): # <-- Обновить проверку
                    print("Python: Ошибка - Звание, Фамилия, Имя и Логин обязательны для заполнения.")
                    return -1
                # --- ---

                print(f"Python: Подготовленные данные для добавления: {prepared_data}")

                # --- Вызов метода менеджера БД ---
                # Убедитесь, что метод в вашем PostgreSQLDatabaseManager называется create_user
                new_id = self.pg_database_manager.create_user(prepared_data) # Используем create_user
                # --- ---

                if isinstance(new_id, int) and new_id > 0:
                    print(f"Python: Новый пользователь успешно добавлен с ID: {new_id}")
                    return new_id # Возвращаем ID нового пользователя
                else:
                    print(f"Python: Менеджер БД вернул некорректный ID: {new_id}")
                    return -1 # Возвращаем -1, если ID некорректный

            except Exception as e:
                # --- Улучшенная обработка исключений ---
                print(f"Python: Исключение при добавлении пользователя: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc() # Печатаем трассировку для отладки
                return -1 # Возвращаем -1 в случае любого исключения
                # --- ---
        else:
             print("Python: Ошибка - Нет подключения к БД PostgreSQL (pg_database_manager не инициализирован).")
             return -1 # Возвращаем -1, если нет подключения к БД

    @Slot(int, 'QVariant', result=bool) # Принимает int (ID) и QVariantMap (dict), возвращает bool
    def updateDutyOfficer(self, officer_id: int, officer_data: 'QVariant') -> bool:
        """
        Обновляет данные существующего должностного лица в PostgreSQL.
        :param officer_id: ID пользователя для обновления.
        :param officer_ Словарь с новыми данными пользователя.
        :return: True если успешно, иначе False.
        """
        print(f"Python: QML отправил запрос на обновление пользователя (должностного лица) с ID {officer_id}.")
        print(f"Python: Исходные данные officer_data (тип: {type(officer_data)}): {officer_data}")

        # --- Преобразование QJSValue/QVariant в словарь Python ---
        if hasattr(officer_data, 'toVariant'):
            officer_data = officer_data.toVariant()
            print(f"Python: QJSValue (officer_data) преобразован в: {officer_data}")
        # --- ---

        # --- УЛУЧШЕННАЯ проверка типа и содержимого ---
        if not isinstance(officer_data, dict):
             print(f"Python: Ошибка - officer_data не является словарем. Получен тип: {type(officer_data)}")
             return False

        if not officer_data:
             print("Python: Ошибка - officer_data пуст.")
             return False
        # --- ---

        if self.pg_database_manager:
            try:
                # --- Подготовка данных для передачи в менеджер БД ---
                # Фильтруем и готовим только разрешенные поля
                prepared_data = {}
                allowed_fields = ['rank', 'last_name', 'first_name', 'middle_name', 'phone', 'is_active', 'is_admin', 'login', 'new_password']
                for key, value in officer_data.items():
                    if key in allowed_fields:
                        if key in ['is_active', 'is_admin']:
                            prepared_data[key] = 1 if value else 0 # Преобразуем в 1/0
                        else: # rank, last_name, first_name, middle_name, phone
                            prepared_data[key] = str(value).strip() if value is not None else None
                            # Для необязательных текстовых полей: пустая строка -> None
                            if key in ['middle_name', 'phone'] and prepared_data[key] == "":
                                prepared_data[key] = None

                print(f"Python: Подготовленные данные для обновления: {prepared_data}")

                # --- Базовая валидация обязательных полей ---
                if not all([prepared_data.get('rank'), prepared_data.get('last_name'), prepared_data.get('first_name')]):
                     print("Python: Ошибка - Звание, Фамилия и Имя обязательны для заполнения.")
                     return False
                # --- ---

                # --- Вызов метода менеджера БД ---
                # Убедитесь, что метод в вашем PostgreSQLDatabaseManager называется update_user
                success = self.pg_database_manager.update_user(officer_id, prepared_data) # Используем update_user
                # --- ---

                if success:
                    print(f"Python: Пользователь с ID {officer_id} успешно обновлен.")
                    return True
                else:
                    print(f"Python: Не удалось обновить пользователя с ID {officer_id}.")
                    return False

            except Exception as e:
                print(f"Python: Исключение при обновлении пользователя {officer_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
             print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
             return False

    @Slot(int, result=bool) # Принимает int (ID), возвращает bool
    def deleteDutyOfficer(self, officer_id: int) -> bool:
        """
        Полностью удаляет должностное лицо из PostgreSQL.
        :param officer_id: ID пользователя для удаления.
        :return: True если успешно, иначе False.
        """
        print(f"Python: QML отправил запрос на полное удаление пользователя с ID {officer_id}.")

        if not isinstance(officer_id, int) or officer_id <= 0:
             print(f"Python: Ошибка - Некорректный ID пользователя: {officer_id}")
             return False

        if self.pg_database_manager:
            try:
                # --- Вызов обновленного метода менеджера БД ---
                # Ранее: success = self.pg_database_manager.deactivate_user(officer_id)
                success = self.pg_database_manager.delete_user(officer_id) # <-- Используем delete_user
                # --- ---

                if success:
                    print(f"Python: Пользователь с ID {officer_id} успешно удален из БД.")
                    return True
                else:
                    print(f"Python: Не удалось удалить пользователя с ID {officer_id}.")
                    return False

            except Exception as e:
                print(f"Python: Исключение при удалении пользователя {officer_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
             print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
             return False
    
    
    # --- НОВЫЙ СЛОТ: Получение списка ВСЕХ пользователей ---
    @Slot(result=list)
    def getAllDutyOfficersList(self):
        """
        Возвращает список ВСЕХ должностных лиц (активных и неактивных) для QML.
        Используется, например, для выбора дежурного из полного списка.
        """
        try:
            if self.pg_database_manager:
                # Вызываем метод, который теперь возвращает всех пользователей
                officers = self.pg_database_manager.get_all_users()  # <-- Изменено на get_all_users
            else:
                # Заглушка, если нет подключения
                officers = [
                    {'id': 1, 'rank': 'ст. лейтенант (заглушка)', 'last_name': 'Иванов', 'first_name': 'Иван', 'middle_name': 'Иванович', 'phone': '123-456-789', 'is_active': 1, 'is_admin': 0, 'login': 'ivanov_ii'},
                    {'id': 2, 'rank': 'лейтенант (заглушка)', 'last_name': 'Петров', 'first_name': 'Пётр', 'middle_name': 'Петрович', 'phone': '987-654-321', 'is_active': 0, 'is_admin': 0, 'login': 'petrov_pp'}, # <-- Неактивный
                ]
            print(f"Python: QML запросил список ВСЕХ должностных лиц. Найдено: {len(officers)}")
            
            # Преобразуем в нужный формат
            result = []
            for officer in officers:
                if isinstance(officer, dict):
                    result.append(officer)
                else:
                    result.append(dict(officer))
            print(f"Python: Отправка списка ВСЕХ в QML: {result}")
            return result
        except Exception as e:
            print(f"Python: Ошибка при получении списка ВСЕХ должностных лиц: {e}")
            import traceback
            traceback.print_exc()
            return []
    # --- ---

    @Slot(int) # Принимает int (ID дежурного)
    # --- ---
    @Slot(int)
    def setCurrentDutyOfficer(self, officer_id: int):
        """
        Устанавливает выбранного дежурного.
        :param officer_id: ID нового дежурного.
        """
        print(f"Python: QML установил текущего дежурного: ID {officer_id}")
        try:
            # --- Отладка: Проверка pg_database_manager ---
            if not hasattr(self, 'pg_database_manager') or self.pg_database_manager is None:
                 print("Python: Ошибка - Менеджер БД PostgreSQL (pg_database_manager) не инициализирован.")
                 return
            print("Python: Менеджер БД PostgreSQL (pg_database_manager) инициализирован.")
            # --- ---

            # --- Отладка: Вызов метода менеджера БД ---
            print(f"Python: Вызов self.pg_database_manager.set_current_duty_officer({officer_id})...")
            self.pg_database_manager.set_current_duty_officer(officer_id) # <-- Вызываем метод менеджера БД
            print("Python: Метод set_current_duty_officer успешно выполнен.")
            # --- ---
            
            # --- Отладка: Получение данных о новом дежурном ---
            print(f"Python: Вызов self.pg_database_manager.get_duty_officer_by_id({officer_id})...")
            officer = self.pg_database_manager.get_duty_officer_by_id(officer_id) # <-- Вызываем метод менеджера БД
            print(f"Python: Получены данные дежурного: {officer}")
            # --- ---
            
            # --- Отладка: Обновление свойства _duty_officer ---
            if officer:
                # Формируем строку "Звание Фамилия И.О."
                name = f"{officer['rank']} {officer['last_name']} {officer['first_name'][0]}."
                if officer['middle_name']:
                    name += f"{officer['middle_name'][0]}."
                old_duty_officer = self._duty_officer
                self._duty_officer = name
                print(f"Python: Свойство _duty_officer обновлено с '{old_duty_officer}' на '{self._duty_officer}'")
            else:
                old_duty_officer = self._duty_officer
                self._duty_officer = "Не выбран"
                print(f"Python: Дежурный не найден. Свойство _duty_officer обновлено с '{old_duty_officer}' на '{self._duty_officer}'")
            # --- ---
            
            # --- Отладка: Эмитирование сигнала ---
            print("Python: Эмитирование сигнала dutyOfficerChanged...")
            self.dutyOfficerChanged.emit() # Уведомляем QML об изменении
            print("Python: Сигнал dutyOfficerChanged эмитирован.")
            # --- ---
            
            print(f"Python: Текущий дежурный установлен: {self._duty_officer}")
        except Exception as e:
            print(f"Python: Ошибка установки текущего дежурного: {e}")
            import traceback
            traceback.print_exc()

    # --- Новые слоты для управления окном из QML ---
    @Slot()
    def minimizeToTray(self):
        """Слот для сворачивания окна в трей по запросу из QML."""
        print("Вызов minimizeToTray из QML") # Для отладки
        if self.tray_icon and self.tray_icon.isVisible():
            if not self.close_confirmation_shown:
                # Создаем QMessageBox БЕЗ родителя QWidget
                msg_box = QMessageBox()
                msg_box.setIcon(QMessageBox.Information)
                msg_box.setWindowTitle("Программа свернута")
                msg_box.setText("Программа продолжит выполнение в системном трее.\nДля завершения программы выберите 'Выход' в контекстном меню на значке программы.")
                msg_box.setStandardButtons(QMessageBox.Ok)
                msg_box.exec() # Показываем окно
                self.close_confirmation_shown = True

            self.window.hide() # Скрываем QML окно
            print("Окно скрыто") # Для отладки
        else:
             print("Трей не доступен или не показан") # Для отладки

    @Slot()
    def restore_window(self):
        if self.window:
            self.window.showNormal()
            self.window.raise_()
            self.window.requestActivate()
            self.close_confirmation_shown = False # Сброс флага
            print("Окно восстановлено") # Для отладки


    # --- СЛОТЫ ДЛЯ РАБОТЫ С ALGORITHMS ---

    @Slot(result=list)
    def getAllAlgorithmsList(self) -> list:
        """Возвращает список всех алгоритмов для QML."""
        try:
            if self.pg_database_manager:
                algorithms = self.pg_database_manager.get_all_algorithms()
            else:
                # Заглушка, если нет подключения
                algorithms = [
                    {'id': 1, 'name': 'Алгоритм 1 (заглушка)', 'category': 'повседневная деятельность', 'time_type': 'оперативное', 'description': 'Описание алгоритма 1'},
                    {'id': 2, 'name': 'Алгоритм 2 (заглушка)', 'category': 'кризисные ситуации', 'time_type': 'астрономическое', 'description': 'Описание алгоритма 2'},
                ]
            print(f"Python: QML запросил список алгоритмов. Найдено: {len(algorithms)}")
            result = []
            for alg in algorithms:
                if isinstance(alg, dict):
                    result.append(alg)
                else:
                    result.append(dict(alg))
            return result
        except Exception as e:
            print(f"Python: Ошибка при получении списка алгоритмов: {e}")
            import traceback
            traceback.print_exc()
            return []

    @Slot(int, result='QVariant')
    def getAlgorithmById(self, algorithm_id: int) -> 'QVariant':
        """Возвращает данные алгоритма по ID для QML."""
        try:
            if not isinstance(algorithm_id, int) or algorithm_id <= 0:
                print(f"Python: Ошибка - Некорректный ID алгоритма: {algorithm_id}")
                return None

            if self.pg_database_manager:
                algorithm = self.pg_database_manager.get_algorithm_by_id(algorithm_id)
                if algorithm:
                    print(f"Python: QML запросил алгоритм ID {algorithm_id}. Найден: {algorithm['name']}")
                    return algorithm
                else:
                    print(f"Python: Алгоритм ID {algorithm_id} не найден.")
                    return None
            else:
                print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
                return None
        except Exception as e:
            print(f"Python: Ошибка при получении алгоритма ID {algorithm_id}: {e}")
            import traceback
            traceback.print_exc()
            return None

    @Slot('QVariant', result=int)
    def addAlgorithm(self, algorithm_data: 'QVariant') -> int:
        """Добавляет новый алгоритм."""
        print("Python: QML отправил запрос на добавление нового алгоритма.")
        
        if hasattr(algorithm_data, 'toVariant'):
            algorithm_data = algorithm_data.toVariant()
            print(f"Python: QJSValue (algorithm_data) преобразован в: {algorithm_data}")

        if not isinstance(algorithm_data, dict):
            print(f"Python: Ошибка - algorithm_data не является словарем. Получен тип: {type(algorithm_data)}")
            return -1
        if not algorithm_data:
            print("Python: Ошибка - algorithm_data пуст.")
            return -1

        if self.pg_database_manager:
            try:
                # Подготовка данных
                required_fields = ['name', 'category', 'time_type']
                missing_fields = [field for field in required_fields if field not in algorithm_data or not algorithm_data[field]]
                if missing_fields:
                    print(f"Python: Ошибка - Отсутствуют обязательные поля: {missing_fields}")
                    return -1

                prepared_data = {
                    'name': str(algorithm_data.get('name', '')).strip(),
                    'category': str(algorithm_data.get('category', '')).strip(),
                    'time_type': str(algorithm_data.get('time_type', '')).strip(),
                    'description': str(algorithm_data.get('description', '')).strip() if algorithm_data.get('description') is not None else ""
                }

                if not all([prepared_data['name'], prepared_data['category'], prepared_data['time_type']]):
                    print("Python: Ошибка - Название, категория и тип времени не могут быть пустыми.")
                    return -1

                new_id = self.pg_database_manager.create_algorithm(prepared_data)
                if isinstance(new_id, int) and new_id > 0:
                    print(f"Python: Новый алгоритм успешно добавлен с ID: {new_id}")
                    return new_id
                else:
                    print(f"Python: Менеджер БД вернул некорректный ID: {new_id}")
                    return -1
            except Exception as e:
                print(f"Python: Исключение при добавлении алгоритма: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return -1
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return -1

    @Slot(int, 'QVariant', result=bool)
    def updateAlgorithm(self, algorithm_id: int, algorithm_data: 'QVariant') -> bool:
        """Обновляет существующий алгоритм."""
        print(f"Python: QML отправил запрос на обновление алгоритма ID {algorithm_id}.")
        
        if hasattr(algorithm_data, 'toVariant'):
            algorithm_data = algorithm_data.toVariant()
            print(f"Python: QJSValue (algorithm_data) преобразован в: {algorithm_data}")

        if not isinstance(algorithm_data, dict):
            print(f"Python: Ошибка - algorithm_data не является словарем. Получен тип: {type(algorithm_data)}")
            return False
        if not algorithm_data:
            print("Python: Ошибка - algorithm_data пуст.")
            return False
        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            print(f"Python: Ошибка - Некорректный ID алгоритма: {algorithm_id}")
            return False

        if self.pg_database_manager:
            try:
                # Подготовка данных (фильтрация разрешенных полей)
                allowed_fields = ['name', 'category', 'time_type', 'description']
                prepared_data = {}
                for key, value in algorithm_data.items():
                    if key in allowed_fields:
                        if key in ['name', 'category', 'time_type']:
                            prepared_data[key] = str(value).strip() if value is not None else ""
                        else: # description
                            prepared_data[key] = str(value).strip() if value is not None else ""

                if not prepared_data:
                    print("Python: Ошибка - Нет данных для обновления.")
                    return False

                success = self.pg_database_manager.update_algorithm(algorithm_id, prepared_data)
                if success:
                    print(f"Python: Алгоритм ID {algorithm_id} успешно обновлен.")
                    return True
                else:
                    print(f"Python: Не удалось обновить алгоритм ID {algorithm_id}.")
                    return False
            except Exception as e:
                print(f"Python: Исключение при обновлении алгоритма {algorithm_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return False

    @Slot(int, result=bool)
    def deleteAlgorithm(self, algorithm_id: int) -> bool:
        """Удаляет алгоритм."""
        print(f"Python: QML отправил запрос на удаление алгоритма ID {algorithm_id}.")
        
        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            print(f"Python: Ошибка - Некорректный ID алгоритма: {algorithm_id}")
            return False

        if self.pg_database_manager:
            try:
                success = self.pg_database_manager.delete_algorithm(algorithm_id)
                if success:
                    print(f"Python: Алгоритм ID {algorithm_id} успешно удален.")
                    return True
                else:
                    print(f"Python: Не удалось удалить алгоритм ID {algorithm_id}. Возможно, есть выполнения или другие ограничения.")
                    return False # QML может показать сообщение пользователю
            except Exception as e:
                print(f"Python: Исключение при удалении алгоритма {algorithm_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return False

    @Slot(int, result=int)
    def duplicateAlgorithm(self, original_algorithm_id: int) -> int:
        """Создает копию алгоритма."""
        print(f"Python: QML отправил запрос на дублирование алгоритма ID {original_algorithm_id}.")
        
        if not isinstance(original_algorithm_id, int) or original_algorithm_id <= 0:
            print(f"Python: Ошибка - Некорректный ID оригинального алгоритма: {original_algorithm_id}")
            return -1

        if self.pg_database_manager:
            try:
                new_algorithm_id = self.pg_database_manager.duplicate_algorithm(original_algorithm_id)
                if new_algorithm_id != -1:
                    print(f"Python: Алгоритм ID {original_algorithm_id} успешно дублирован. Новый ID: {new_algorithm_id}")
                    return new_algorithm_id
                else:
                    print(f"Python: Не удалось дублировать алгоритм ID {original_algorithm_id}.")
                    return -1
            except Exception as e:
                print(f"Python: Исключение при дублировании алгоритма {original_algorithm_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return -1
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return -1

    # --- СЛОТЫ ДЛЯ РАБОТЫ С ACTIONS ---

    @Slot(int, result=list)
    def getActionsByAlgorithmId(self, algorithm_id: int) -> list:
        """Возвращает список действий для заданного алгоритма."""
        try:
            if not isinstance(algorithm_id, int) or algorithm_id <= 0:
                print(f"Python: Ошибка - Некорректный ID алгоритма: {algorithm_id}")
                return []

            if self.pg_database_manager:
                actions = self.pg_database_manager.get_actions_by_algorithm_id(algorithm_id)
                print(f"Python: QML запросил действия для алгоритма ID {algorithm_id}. Найдено: {len(actions)}")
                result = []
                for action in actions:
                    if isinstance(action, dict):
                        result.append(action)
                    else:
                        result.append(dict(action))
                return result
            else:
                print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
                return []
        except Exception as e:
            print(f"Python: Ошибка при получении действий для алгоритма ID {algorithm_id}: {e}")
            import traceback
            traceback.print_exc()
            return []

    @Slot(int, result='QVariant')
    def getActionById(self, action_id: int) -> 'QVariant':
        """Возвращает данные действия по ID."""
        try:
            if not isinstance(action_id, int) or action_id <= 0:
                print(f"Python: Ошибка - Некорректный ID действия: {action_id}")
                return None

            if self.pg_database_manager:
                action = self.pg_database_manager.get_action_by_id(action_id)
                if action:
                    print(f"Python: QML запросил действие ID {action_id}.")
                    return action
                else:
                    print(f"Python: Действие ID {action_id} не найдено.")
                    return None
            else:
                print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
                return None
        except Exception as e:
            print(f"Python: Ошибка при получении действия ID {action_id}: {e}")
            import traceback
            traceback.print_exc()
            return None

    @Slot('QVariant', result=int)
    def addAction(self, action_data: 'QVariant') -> int:
        """Добавляет новое действие."""
        print("Python: QML отправил запрос на добавление нового действия.")
        
        if hasattr(action_data, 'toVariant'):
            action_data = action_data.toVariant()
            print(f"Python: QJSValue (action_data) преобразован в: {action_data}")

        if not isinstance(action_data, dict):
            print(f"Python: Ошибка - action_data не является словарем. Получен тип: {type(action_data)}")
            return -1
        if not action_data:
            print("Python: Ошибка - action_data пуст.")
            return -1

        if self.pg_database_manager:
            try:
                required_fields = ['algorithm_id', 'description']
                missing_fields = [field for field in required_fields if field not in action_data or not action_data[field]]
                if missing_fields:
                    print(f"Python: Ошибка - Отсутствуют обязательные поля: {missing_fields}")
                    return -1

                # Подготовка данных, включая преобразование INTERVAL из строки QML
                prepared_data = {}
                for key, value in action_data.items():
                    if key in ['algorithm_id', 'description', 'contact_phones', 'report_materials']:
                        prepared_data[key] = str(value).strip() if value is not None else (None if key in ['contact_phones', 'report_materials'] else "")
                    elif key in ['start_offset', 'end_offset']:
                        # Ожидаем, что QML передаст строку вроде '2 days 3 hours' или '03:30:00'
                        # psycopg2 может автоматически преобразовать строку в INTERVAL, если поле в БД типа INTERVAL
                        # Но для надежности можно оставить как строку, БД сама преобразует
                        prepared_data[key] = value if value is not None else None
                
                # Особая обработка algorithm_id
                try:
                    prepared_data['algorithm_id'] = int(prepared_data['algorithm_id'])
                except (ValueError, TypeError):
                    print("Python: Ошибка - algorithm_id должен быть целым числом.")
                    return -1

                new_id = self.pg_database_manager.create_action(prepared_data)
                if isinstance(new_id, int) and new_id > 0:
                    print(f"Python: Новое действие успешно добавлено с ID: {new_id}")
                    return new_id
                else:
                    print(f"Python: Менеджер БД вернул некорректный ID: {new_id}")
                    return -1
            except Exception as e:
                print(f"Python: Исключение при добавлении действия: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return -1
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return -1

    @Slot(int, 'QVariant', result=bool)
    def updateAction(self, action_id: int, action_data: 'QVariant') -> bool:
        """Обновляет существующее действие."""
        print(f"Python: QML отправил запрос на обновление действия ID {action_id}.")
        
        if hasattr(action_data, 'toVariant'):
            action_data = action_data.toVariant()
            print(f"Python: QJSValue (action_data) преобразован в: {action_data}")

        if not isinstance(action_data, dict):
            print(f"Python: Ошибка - action_data не является словарем. Получен тип: {type(action_data)}")
            return False
        if not action_data:
            print("Python: Ошибка - action_data пуст.")
            return False
        if not isinstance(action_id, int) or action_id <= 0:
            print(f"Python: Ошибка - Некорректный ID действия: {action_id}")
            return False

        if self.pg_database_manager:
            try:
                # Подготовка данных (фильтрация разрешенных полей)
                allowed_fields = ['description', 'start_offset', 'end_offset', 'contact_phones', 'report_materials']
                prepared_data = {}
                for key, value in action_data.items():
                    if key in allowed_fields:
                        if key in ['description', 'contact_phones', 'report_materials']:
                            prepared_data[key] = str(value).strip() if value is not None else (None if key in ['contact_phones', 'report_materials'] else "")
                        elif key in ['start_offset', 'end_offset']:
                            # Аналогично добавлению
                            prepared_data[key] = value if value is not None else None

                if not prepared_data:
                    print("Python: Ошибка - Нет данных для обновления.")
                    return False

                success = self.pg_database_manager.update_action(action_id, prepared_data)
                if success:
                    print(f"Python: Действие ID {action_id} успешно обновлено.")
                    return True
                else:
                    print(f"Python: Не удалось обновить действие ID {action_id}.")
                    return False
            except Exception as e:
                print(f"Python: Исключение при обновлении действия {action_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return False

    @Slot(int, result=bool)
    def deleteAction(self, action_id: int) -> bool:
        """Удаляет действие."""
        print(f"Python: QML отправил запрос на удаление действия ID {action_id}.")
        
        if not isinstance(action_id, int) or action_id <= 0:
            print(f"Python: Ошибка - Некорректный ID действия: {action_id}")
            return False

        if self.pg_database_manager:
            try:
                success = self.pg_database_manager.delete_action(action_id)
                if success:
                    print(f"Python: Действие ID {action_id} успешно удалено.")
                    return True
                else:
                    print(f"Python: Не удалось удалить действие ID {action_id}. Возможно, есть выполнения или другие ограничения.")
                    return False
            except Exception as e:
                print(f"Python: Исключение при удалении действия {action_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return False

    @Slot(int, result=int) # Для дублирования в том же алгоритме
    @Slot(int, int, result=int) # Для дублирования в другом алгоритме
    def duplicateAction(self, original_action_id: int, new_algorithm_id: int = None) -> int:
        """Создает копию действия."""
        print(f"Python: QML отправил запрос на дублирование действия ID {original_action_id} (новый алгоритм ID: {new_algorithm_id}).")
        
        if not isinstance(original_action_id, int) or original_action_id <= 0:
            print(f"Python: Ошибка - Некорректный ID оригинального действия: {original_action_id}")
            return -1

        if self.pg_database_manager:
            try:
                # Передаем None как есть, если new_algorithm_id не передан или равен 0
                final_new_alg_id = new_algorithm_id if new_algorithm_id is not None and new_algorithm_id > 0 else None
                new_action_id = self.pg_database_manager.duplicate_action(original_action_id, final_new_alg_id)
                if new_action_id != -1:
                    print(f"Python: Действие ID {original_action_id} успешно дублировано. Новый ID: {new_action_id}")
                    return new_action_id
                else:
                    print(f"Python: Не удалось дублировать действие ID {original_action_id}.")
                    return -1
            except Exception as e:
                print(f"Python: Исключение при дублировании действия {original_action_id}: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return -1
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return -1


    @Slot(int, result=bool)
    def moveAlgorithmUp(self, algorithm_id: int) -> bool:
        """
        Перемещает алгоритм вверх в списке.
        :param algorithm_id: ID алгоритма для перемещения.
        :return: True, если успешно, иначе False.
        """
        print(f"Python: QML отправил запрос на перемещение алгоритма ID {algorithm_id} вверх.")
        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            print(f"Python: Ошибка - Некорректный ID алгоритма: {algorithm_id}")
            return False

        if self.pg_database_manager:
            try:
                success = self.pg_database_manager.move_algorithm_up(algorithm_id)
                if success:
                    print(f"Python: Алгоритм ID {algorithm_id} успешно перемещен вверх.")
                    # Перезагружаем список алгоритмов в QML
                    self.algorithmsListChanged.emit()
                    return True
                else:
                    print(f"Python: Не удалось переместить алгоритм ID {algorithm_id} вверх.")
                    return False
            except Exception as e:
                print(f"Python: Исключение при перемещении алгоритма {algorithm_id} вверх: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return False

    @Slot(int, result=bool)
    def moveAlgorithmDown(self, algorithm_id: int) -> bool:
        """
        Перемещает алгоритм вниз в списке.
        :param algorithm_id: ID алгоритма для перемещения.
        :return: True, если успешно, иначе False.
        """
        print(f"Python: QML отправил запрос на перемещение алгоритма ID {algorithm_id} вниз.")
        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            print(f"Python: Ошибка - Некорректный ID алгоритма: {algorithm_id}")
            return False

        if self.pg_database_manager:
            try:
                success = self.pg_database_manager.move_algorithm_down(algorithm_id)
                if success:
                    print(f"Python: Алгоритм ID {algorithm_id} успешно перемещен вниз.")
                    # Перезагружаем список алгоритмов в QML
                    self.algorithmsListChanged.emit()
                    return True
                else:
                    print(f"Python: Не удалось переместить алгоритм ID {algorithm_id} вниз.")
                    return False
            except Exception as e:
                print(f"Python: Исключение при перемещении алгоритма {algorithm_id} вниз: {type(e).__name__}: {e}")
                import traceback
                traceback.print_exc()
                return False
        else:
            print("Python: Ошибка - Нет подключения к БД PostgreSQL.")
            return False

    def minimize_window(self):
        if self.window:
            self.window.showMinimized()
            print("Окно минимизировано") # Для отладки

    def maximize_window(self):
        if self.window:
            self.window.showMaximized()
            print("Окно развернуто") # Для отладки

    def on_tray_icon_activated(self, reason):
        """Обработчик клика по иконке в трее."""
        if reason == QSystemTrayIcon.Trigger or reason == QSystemTrayIcon.DoubleClick: # Левый клик или двойной клик
            self.restore_window()
        # elif reason == QSystemTrayIcon.Context: # Правый клик - меню показывается автоматически
            # pass

    def quit_app(self):
        print("Выход из приложения") # Для отладки
        # Скрываем иконку трея перед выходом
        if self.tray_icon:
            self.tray_icon.hide()
        self.app.quit()


def on_qml_loaded(obj, url):
    if obj and url.fileName() == "main.qml":
        print("QML main.qml загружен. Устанавливаем соединения сигналов...")
        # obj - это корневой объект ApplicationWindow из main.qml
        # Подключаем сигнал mainScreenRequested к функции QML switchToMainScreen
        # и loginScreenRequested к функции QML switchToLoginScreen
        data_context.mainScreenRequested.connect(obj.switchToMainScreen)
        data_context.loginScreenRequested.connect(obj.switchToLoginScreen)
        print("Соединения сигналов установлены.")



# --- ТОЧКА ВХОДА В ПРИЛОЖЕНИЕ ---
if __name__ == "__main__":
    # --- Используем QApplication для поддержки QSystemTrayIcon ---
    app = QApplication(sys.argv)
    # ВАЖНО: Не завершать приложение при закрытии последнего окна
    app.setQuitOnLastWindowClosed(False)

    # --- СОЗДАЕМ экземпляр менеджера ЛОКАЛЬНОЙ КОНФИГУРАЦИИ (SQLite) ---
    sqlite_config_manager = SQLiteConfigManager()
    print("Python: SQLiteConfigManager инициализирован.")
    # --- ---

    # --- Сначала создаем engine ---
    engine = QQmlApplicationEngine()

    # --- Затем создаем ApplicationData, ПЕРЕДАВАЯ app, engine и db_manager ---
    # Обратите внимание на добавленный аргумент db_manager
    data_context = ApplicationData(app, engine, sqlite_config_manager) # <-- Добавлен sqlite_config_manager
    
    # --- Регистрация контекста для QML ---
    engine.rootContext().setContextProperty("appData", data_context)

    engine.objectCreated.connect(on_qml_loaded)

    # --- Загрузка QML файла ---
    qml_file = Path(__file__).parent / "ui" / "main.qml"
    engine.load(QUrl.fromLocalFile(str(qml_file)))

    if not engine.rootObjects():
        sys.exit(-1)

    sys.exit(app.exec())
