# db/postgresql_manager.py
import psycopg2
from psycopg2 import sql
# from psycopg2.extras import RealDictCursor # Для получения результатов как dict
# Убедитесь, что установили библиотеку: pip install Werkzeug
from werkzeug.security import check_password_hash, generate_password_hash
from typing import Optional, Dict, Any, List
import logging

# Настройка логирования для отладки
logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO) # Или DEBUG для более подробного лога

class PostgreSQLDatabaseManager:
    """
    Класс для управления подключением к базе данных PostgreSQL
    и выполнения запросов, связанных с основной логикой приложения.
    Предполагается, что все объекты БД находятся в схеме 'app_schema'.
    """
    SCHEMA_NAME = 'app_schema' # Имя схемы

    def __init__(self, connection_config: Dict[str, Any]):
        """
        Инициализирует менеджер БД PostgreSQL.
        :param connection_config: Словарь с параметрами подключения
                                  (host, port, dbname, user, password).
        """
        self.connection_config = connection_config
        self.connection = None
        logger.info(f"PostgreSQLDatabaseManager инициализирован. Используется схема: {self.SCHEMA_NAME}")

    def _get_connection(self):
        """
        Создает и возвращает новое подключение к БД.
        В реальном приложении здесь должен быть пул соединений.
        """
        if self.connection is None or self.connection.closed:
            try:
                logger.debug(f"Попытка подключения к PostgreSQL с параметрами: host={self.connection_config['host']}, port={self.connection_config['port']}, dbname={self.connection_config['dbname']}, user={self.connection_config['user']}")
                
                # --- ДОБАВЛЕНО: Отладка значений параметров ---
                # Проверим типы и содержимое каждого параметра
                for key, value in self.connection_config.items():
                    logger.debug(f"  Параметр '{key}': тип={type(value)}, значение='{value}'")
                    # Проверим, нет ли скрытых символов
                    if isinstance(value, str):
                        logger.debug(f"    Длина строки: {len(value)}")
                        logger.debug(f"    Символы: {[ord(c) for c in value]}") # Коды символов
                # --- ---

                # --- ИЗМЕНЕНО: Используем тот же стиль вызова, что и в Flask ---
                # Вместо формирования DSN, передаем параметры напрямую
                # и добавляем client_encoding вручную после подключения
                self.connection = psycopg2.connect(
                    host=self.connection_config['host'],
                    port=self.connection_config['port'],
                    dbname=self.connection_config['dbname'],
                    user=self.connection_config['user'],
                    password=self.connection_config['password']
                )
                logger.debug("Соединение psycopg2 создано (параметры напрямую).")

                # --- ИЗМЕНЕНО: Устанавливаем кодировку после подключения ---
                try:
                    # Сначала проверим, что соединение активно
                    test_cursor = self.connection.cursor()
                    test_cursor.execute("SELECT 1;")
                    test_cursor.fetchone()
                    test_cursor.close()
                    logger.debug("Тестовый запрос после подключения успешен.")

                    self.connection.set_client_encoding('UTF8')
                    logger.info("Кодировка клиента установлена в UTF8 после подключения.")
                except psycopg2.Error as pe:
                    logger.error(f"Ошибка psycopg2 при установке кодировки или тестовом запросе: {pe}")
                    raise
                except Exception as e_set_enc:
                    logger.error(f"Неизвестная ошибка при установке кодировки или тестовом запросе: {e_set_enc}")
                    raise
                # --- ---
                
            except psycopg2.Error as e:
                logger.error(f"Ошибка подключения к PostgreSQL (psycopg2): {e}")
                # Логируем без использования e.diag, чтобы избежать UnicodeDecodeError
                self.connection = None
                raise
            except Exception as e: # Ловим любые другие исключения
                logger.error(f"Неизвестная ошибка при подключении к PostgreSQL: {type(e).__name__}: {e}")
                self.connection = None
                raise
        else:
            logger.debug("Используется существующее подключение к PostgreSQL.")

        return self.connection

    def close_connection(self):
        """Закрывает подключение к БД."""
        if self.connection and not self.connection.closed:
            self.connection.close()
            logger.info("Подключение к PostgreSQL закрыто.")

    def test_connection(self) -> bool:
        """
        Тестирует подключение к БД.
        :return: True, если подключение успешно, иначе False.
        """
        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            
            # --- ИЗМЕНЕНО: Простой запрос вместо SELECT version() ---
            # cursor.execute('SELECT version();')
            # db_version = cursor.fetchone()
            cursor.execute('SELECT 1;') # Очень простой запрос
            test_result = cursor.fetchone()
            # --- ---
            
            # Проверяем, существует ли схема app_schema
            cursor.execute(
                "SELECT schema_name FROM information_schema.schemata WHERE schema_name = %s;",
                (self.SCHEMA_NAME,)
            )
            schema_exists = cursor.fetchone()
            
            cursor.close()
            
            # if db_version: # Старая проверка
            if test_result: # Новая проверка
                if schema_exists:
                    # logger.info(f"Тест подключения успешен. Версия БД: {db_version[0] if db_version else 'Неизвестно'}. Схема '{self.SCHEMA_NAME}' найдена.")
                    logger.info(f"Тест подключения успешен. Простой запрос выполнен. Схема '{self.SCHEMA_NAME}' найдена.") # Обновленное сообщение
                    return True
                else:
                    logger.warning(f"Тест подключения успешен, но схема '{self.SCHEMA_NAME}' не найдена.")
                    return False
            else:
                logger.error("Тест подключения не удался: не удалось выполнить простой запрос.")
                return False
                
        except Exception as e:
            logger.error(f"Тест подключения не удался: {e}")
            return False

    def authenticate_user(self, login: str, password: str) -> Optional[Dict[str, Any]]:
        """
        Аутентифицирует пользователя по логину и паролю.
        :param login: Логин пользователя.
        :param password: Введенный пароль (в открытом виде).
        :return: Словарь с данными пользователя, если аутентификация успешна, иначе None.
        """
        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            # Используем полное имя таблицы с указанием схемы
            cursor.execute(
                f"SELECT id, login, password_hash, rank, last_name, first_name, middle_name, is_admin FROM {self.SCHEMA_NAME}.users WHERE login = %s AND is_active = TRUE;",
                (login,)
            )
            user_record = cursor.fetchone()
            cursor.close()

            if user_record:
                # user_record[2] - это password_hash из запроса
                stored_hash = user_record[2]
                # Проверяем, соответствует ли введенный пароль хэшу с помощью Werkzeug
                if check_password_hash(stored_hash, password):
                    logger.info(f"Пользователь '{login}' успешно аутентифицирован.")
                    # Возвращаем данные пользователя (без хэша пароля)
                    return {
                        'id': user_record[0],
                        'login': user_record[1],
                        'rank': user_record[3],
                        'last_name': user_record[4],
                        'first_name': user_record[5],
                        'middle_name': user_record[6],
                        'is_admin': user_record[7]
                    }
                else:
                    logger.warning(f"Неверный пароль для пользователя '{login}'.")
            else:
                logger.warning(f"Пользователь '{login}' не найден или неактивен.")
            return None
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при аутентификации пользователя '{login}': {e}")
            return None
        except Exception as e:
            logger.error(f"Неизвестная ошибка при аутентификации пользователя '{login}': {e}")
            return None

    # --- Методы для работы с данными (реализации) ---

    def get_settings(self) -> Optional[Dict[str, Any]]:
        """Получает настройки приложения из БД."""
        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            # Используем полное имя таблицы с указанием схемы
            cursor.execute(f"SELECT * FROM {self.SCHEMA_NAME}.settings WHERE id = 1;")
            row = cursor.fetchone()
            # Получаем названия колонок
            colnames = [desc[0] for desc in cursor.description]
            cursor.close()
            
            if row:
                # Создаем словарь из результата
                settings_dict = dict(zip(colnames, row))
                logger.debug(f"Настройки загружены из БД: {settings_dict}")
                return settings_dict
            else:
                logger.warning("Запись настроек (id=1) не найдена в БД.")
                return None
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при получении настроек: {e}")
            return None
        except Exception as e:
            logger.error(f"Неизвестная ошибка при получении настроек: {e}")
            return None

    def get_all_users(self) -> List[Dict[str, Any]]:
        """
        Получает список всех пользователей (активных и неактивных), отсортированных по званию, фамилии, имени, отчеству.
        """
        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            # Убираем WHERE is_active = TRUE, чтобы получить всех пользователей
            cursor.execute(
                f"SELECT id, login, rank, last_name, first_name, middle_name, phone, is_active, is_admin FROM {self.SCHEMA_NAME}.users ORDER BY rank ASC, last_name ASC, first_name ASC, middle_name ASC;"
            )
            rows = cursor.fetchall()
            # Получаем названия колонок
            colnames = [desc[0] for desc in cursor.description]
            cursor.close()
            
            # Преобразуем список кортежей в список словарей
            users_list = [dict(zip(colnames, row)) for row in rows]
            logger.debug(f"Получен список {len(users_list)} всех пользователей из БД (отсортирован по званию, фамилии, имени, отчеству).")
            return users_list
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при получении списка всех пользователей: {e}")
            return []
        except Exception as e:
            logger.error(f"Неизвестная ошибка при получении списка всех пользователей: {e}")
            return []

    # --- Добавим заглушку для будущего метода обновления настроек ---
    def update_settings(self, settings_data: Dict[str, Any]) -> bool:
        """
        Обновляет настройки приложения в БД.
        :param settings_data: Словарь с новыми значениями настроек.
        :return: True, если успешно, иначе False.
        """
        if not settings_data:
            logger.warning("Попытка обновления настроек с пустыми данными.")
            return False

        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            
            # Формируем SQL-запрос динамически, исключая 'id'
            # Это безопасно, так как ключи берутся из нашего кода, а не из пользовательского ввода
            fields_to_update = [key for key in settings_data.keys() if key != 'id']
            if not fields_to_update:
                 logger.warning("Нет полей для обновления в настройках.")
                 return False

            set_clause = ", ".join([f"{key} = %s" for key in fields_to_update])
            values = [settings_data[key] for key in fields_to_update]
            values.append(1) # id = 1
            
            sql_query = f"UPDATE {self.SCHEMA_NAME}.settings SET {set_clause} WHERE id = %s;"
            
            logger.debug(f"Выполнение SQL обновления настроек: {cursor.mogrify(sql_query, values)}")
            cursor.execute(sql_query, values)
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Настройки успешно обновлены в БД. Затронуто строк: {rows_affected}.")
                return True
            else:
                logger.warning("Не удалось обновить настройки (запись не найдена или данные не изменились).")
                return False
                
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при обновлении настроек: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при обновлении настроек: {e}")
            if conn:
                conn.rollback()
            return False
    
        # --- НОВЫЕ МЕТОДЫ ДЛЯ РАБОТЫ С ПОЛЬЗОВАТЕЛЯМИ (ДОЛЖНОСТНЫМИ ЛИЦАМИ) ---

    def create_user(self, user_data: Dict[str, Any]) -> int:
        """
        Создает нового пользователя (должностного лица) в БД.
        :param user_ Словарь с данными нового пользователя.
                         Должен содержать ключи: rank, last_name, first_name, login.
                         Может содержать: middle_name, phone, is_active, is_admin, new_password.
        :return: ID нового пользователя, если успешно, иначе -1.
        """
        if not user_data:
            logger.warning("Попытка создания пользователя с пустыми данными.")
            return -1

        required_fields = ['rank', 'last_name', 'first_name', 'login'] # <-- Обновлено: добавлен 'login'
        missing_fields = [field for field in required_fields if not user_data.get(field)]
        if missing_fields:
            logger.error(f"Отсутствуют обязательные поля для создания пользователя: {missing_fields}")
            return -1

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            # --- Подготовка полей и значений для INSERT ---
            # Определяем поля, которые будут вставлены
            # --- ОБНОВЛЕНО: Добавлены 'login' и 'password_hash' ---
            allowed_fields = ['rank', 'last_name', 'first_name', 'middle_name', 'phone', 'is_active', 'is_admin', 'login', 'password_hash']
            # --- ---
            fields = [field for field in allowed_fields if field in user_data or field == 'password_hash'] # Всегда включаем password_hash, если есть new_password
            
            # Создаем список %s плейсхолдеров
            placeholders = ['%s'] * len(fields)
            
            # Формируем значения для вставки, обрабатывая типы данных
            values = []
            for field in fields:
                val = user_data.get(field)
                # Обработка булевых полей
                if field in ['is_active', 'is_admin']:
                    # Преобразуем в Python boolean (True/False)
                    values.append(bool(val)) 
                # --- ДОБАВЛЕНО: Обработка логина и пароля ---
                elif field == 'login':
                     # Логин должен быть строкой
                     values.append(str(val).strip() if val is not None else None)
                elif field == 'password_hash':
                     # password_hash генерируется из new_password
                     new_pass = user_data.get('new_password')
                     if new_pass:
                         # Генерируем хэш с использованием Werkzeug
                         values.append(generate_password_hash(str(new_pass)))
                     else:
                         # Если пароль не задан, вставляем NULL
                         values.append(None)
                # --- ---
                else: # rank, last_name, first_name, middle_name, phone
                    # Для текстовых полей None -> NULL, пустые строки -> NULL
                    processed_val = val if val is not None else None
                    if isinstance(processed_val, str) and processed_val == "":
                         processed_val = None
                    values.append(processed_val)

            # --- Формирование и выполнение SQL-запроса ---
            columns_str = ', '.join(fields)
            placeholders_str = ', '.join(placeholders)
            # Используем RETURNING id для получения ID нового пользователя
            sql_query = f"INSERT INTO {self.SCHEMA_NAME}.users ({columns_str}) VALUES ({placeholders_str}) RETURNING id;"
            
            logger.debug(f"Выполнение SQL создания пользователя: {cursor.mogrify(sql_query, values)}")
            cursor.execute(sql_query, values)
            new_id_row = cursor.fetchone()
            new_id = new_id_row[0] if new_id_row else None
            conn.commit()
            cursor.close()
            
            if new_id:
                logger.info(f"Новый пользователь успешно создан с ID: {new_id}")
                return new_id
            else:
                logger.error("Не удалось получить ID нового пользователя после вставки.")
                return -1

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при создании пользователя: {e}")
            if conn:
                conn.rollback()
            return -1
        except Exception as e:
            logger.error(f"Неизвестная ошибка при создании пользователя: {e}")
            if conn:
                conn.rollback()
            return -1

    def update_user(self, user_id: int, user_data: Dict[str, Any]) -> bool:
        """
        Обновляет данные существующего пользователя (должностного лица) в БД.
        :param user_id: ID пользователя для обновления.
        :param user_ Словарь с новыми данными пользователя.
                         Может содержать: rank, last_name, first_name, middle_name, phone, is_active, is_admin, login, new_password.
        :return: True, если успешно, иначе False.
        """
        if not user_data:
            logger.warning("Попытка обновления пользователя с пустыми данными.")
            return False

        if not isinstance(user_id, int) or user_id <= 0:
            logger.error("Некорректный ID пользователя для обновления.")
            return False

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            # --- Подготовка полей и значений для UPDATE ---
            # Определяем поля, которые разрешено обновлять
            # --- ОБНОВЛЕНО: Добавлены 'login' и 'password_hash' ---
            allowed_fields = ['rank', 'last_name', 'first_name', 'middle_name', 'phone', 'is_active', 'is_admin', 'login', 'password_hash']
            # --- ---
            
            # Фильтруем только те поля, которые присутствуют в user_data
            fields_to_update = [field for field in allowed_fields if field in user_data]
            
            # Особая обработка для password_hash: оно обновляется только если передан new_password
            if 'new_password' in user_data and user_data['new_password']:
                 # Добавляем password_hash в список обновляемых полей, если его еще нет
                 if 'password_hash' not in fields_to_update:
                     fields_to_update.append('password_hash')
            else:
                 # Если new_password пуст или не передан, исключаем password_hash из обновления
                 if 'password_hash' in fields_to_update:
                     fields_to_update.remove('password_hash')

            if not fields_to_update:
                logger.warning("Нет полей для обновления.")
                return False

            # Формируем SET часть запроса и список значений
            set_clauses = []
            values = []
            for field in fields_to_update:
                val = user_data.get(field)
                # Обработка типов данных
                if field in ['is_active', 'is_admin']:
                    # Преобразуем в Python boolean
                    values.append(bool(val))
                # --- ДОБАВЛЕНО: Обработка логина и пароля ---
                elif field == 'login':
                     # Логин должен быть строкой
                     values.append(str(val).strip() if val is not None else None)
                elif field == 'password_hash':
                     # password_hash генерируется из new_password
                     new_pass = user_data.get('new_password')
                     if new_pass:
                         # Генерируем хэш с использованием Werkzeug
                         values.append(generate_password_hash(str(new_pass)))
                     else:
                         # Это не должно произойти, так как мы фильтровали выше, но на всякий случай
                         logger.warning("Попытка установить password_hash без new_password.")
                         values.append(None) # Или continue?
                # --- ---
                else: # rank, last_name, first_name, middle_name, phone
                    # Обработка текстовых полей: пустая строка -> None -> NULL
                    processed_val = val if val is not None else None
                    if isinstance(processed_val, str) and processed_val == "":
                         processed_val = None
                    values.append(processed_val)
                
                set_clauses.append(f"{field} = %s")

            # Добавляем user_id в конец списка значений для WHERE
            values.append(user_id)
            
            # --- Формирование и выполнение SQL-запроса ---
            set_clause_str = ', '.join(set_clauses)
            sql_query = f"UPDATE {self.SCHEMA_NAME}.users SET {set_clause_str} WHERE id = %s;"
            
            logger.debug(f"Выполнение SQL обновления пользователя {user_id}: {cursor.mogrify(sql_query, values)}")
            cursor.execute(sql_query, values)
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Пользователь с ID {user_id} успешно обновлен. Затронуто строк: {rows_affected}.")
                return True
            else:
                logger.warning(f"Не удалось обновить пользователя с ID {user_id} (запись не найдена или данные не изменились).")
                return False

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при обновлении пользователя {user_id}: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при обновлении пользователя {user_id}: {e}")
            if conn:
                conn.rollback()
            return False

    def delete_user(self, user_id: int) -> bool:
        """
        Полностью удаляет пользователя (должностное лицо) из БД.
        :param user_id: ID пользователя для удаления.
        :return: True, если успешно, иначе False.
        """
        if not isinstance(user_id, int) or user_id <= 0:
            logger.error("Некорректный ID пользователя для удаления.")
            return False

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            # --- Формирование и выполнение SQL-запроса на удаление ---
            sql_query = f"DELETE FROM {self.SCHEMA_NAME}.users WHERE id = %s;"
            
            logger.debug(f"Выполнение SQL удаления пользователя {user_id}: {cursor.mogrify(sql_query, (user_id,))}")
            cursor.execute(sql_query, (user_id,))
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Пользователь с ID {user_id} успешно удален из БД. Затронуто строк: {rows_affected}.")
                return True
            else:
                logger.warning(f"Не удалось удалить пользователя с ID {user_id} (запись не найдена).")
                return False

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при удалении пользователя {user_id}: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при удалении пользователя {user_id}: {e}")
            if conn:
                conn.rollback()
            return False

    def get_duty_officer_by_id(self, officer_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает данные должностного лица по его ID.
        :param officer_id: ID должностного лица.
        :return: Словарь с данными или None.
        """
        if not isinstance(officer_id, int) or officer_id <= 0:
            logger.warning("Некорректный ID пользователя для получения.")
            return None

        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            # --- Используем полное имя таблицы с указанием схемы ---
            cursor.execute(
                f"SELECT * FROM {self.SCHEMA_NAME}.users WHERE id = %s AND is_active = TRUE;", # Можно убрать is_active = TRUE, если хотите получать всех
                (officer_id,)
            )
            row = cursor.fetchone()
            # Получаем названия колонок
            colnames = [desc[0] for desc in cursor.description]
            cursor.close()
            
            if row:
                # Создаем словарь из результата
                officer_dict = dict(zip(colnames, row))
                logger.debug(f"Получены данные должностного лица по ID {officer_id}: {officer_dict}")
                return officer_dict
            else:
                logger.warning(f"Должностное лицо с ID {officer_id} не найдено (или неактивно).")
                return None
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при получении данных должностного лица по ID {officer_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Неизвестная ошибка при получении данных должностного лица по ID {officer_id}: {e}")
            return None

    def set_current_duty_officer(self, officer_id: int) -> bool:
        """
        Устанавливает выбранного дежурного в настройках приложения.
        :param officer_id: ID нового дежурного.
        :return: True, если успешно, иначе False.
        """
        if not isinstance(officer_id, int):
            logger.error("Некорректный тип ID дежурного. Ожидался int.")
            return False

        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            
            # --- Обновляем настройки, устанавливая current_officer_id ---
            # Предполагается, что в таблице settings есть запись с id=1
            sql_query = f"UPDATE {self.SCHEMA_NAME}.settings SET current_officer_id = %s WHERE id = 1;"
            
            logger.debug(f"Выполнение SQL установки текущего дежурного: {cursor.mogrify(sql_query, (officer_id,))}")
            cursor.execute(sql_query, (officer_id,))
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Текущий дежурный успешно установлен в настройках: ID {officer_id}")
                return True
            else:
                logger.warning(f"Не удалось установить текущего дежурного: запись settings (id=1) не найдена или ID {officer_id} не изменился.")
                return False

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при установке текущего дежурного ID {officer_id}: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при установке текущего дежурного ID {officer_id}: {e}")
            if conn:
                conn.rollback()
            return False
    
    # --- ---

# --- Пример использования (для тестирования модуля отдельно) ---
if __name__ == "__main__":
    # Для тестирования в standalone-режиме нужно получить конфиг из SQLite
    # from db.sqlite_config import SQLiteConfigManager
    # config_manager = SQLiteConfigManager()
    # connection_config = config_manager.get_connection_config()
    #
    # if connection_config:
    #     pg_manager = PostgreSQLDatabaseManager(connection_config)
    #     if pg_manager.test_connection():
    #         print("Подключение к PostgreSQL успешно!")
    #         # Попробуем аутентификацию (логин и пароль нужно знать)
    #         # user = pg_manager.authenticate_user("admin", "admin_password")
    #         # print("Результат аутентификации:", user)
    #         # settings = pg_manager.get_settings()
    #         # print("Настройки:", settings)
    #         # users = pg_manager.get_all_active_users()
    #         # print("Пользователи:", users)
    #     else:
    #         print("Не удалось подключиться к PostgreSQL или схема не найдена.")
    # else:
    #     print("Конфигурация подключения к PostgreSQL не найдена.")
    pass
