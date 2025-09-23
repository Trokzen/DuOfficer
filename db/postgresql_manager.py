# db/postgresql_manager.py
import psycopg2
from psycopg2 import sql
import re
# from psycopg2.extras import RealDictCursor # Для получения результатов как dict
from werkzeug.security import check_password_hash, generate_password_hash
from typing import Optional, Dict, Any, List
import logging
import datetime

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
    
        # --- МЕТОДЫ ДЛЯ РАБОТЫ С ALGORITHMS ---

    def get_all_algorithms(self) -> List[Dict[str, Any]]:
        """
        Получает список всех алгоритмов, отсортированных по названию.
        :return: Список словарей с данными алгоритмов.
        """
        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute(
                f"SELECT id, name, category, time_type, description, created_at, updated_at FROM {self.SCHEMA_NAME}.algorithms ORDER BY name ASC;"
            )
            rows = cursor.fetchall()
            colnames = [desc[0] for desc in cursor.description]
            cursor.close()
            algorithms_list = [dict(zip(colnames, row)) for row in rows]
            logger.debug(f"Получен список {len(algorithms_list)} алгоритмов из БД.")
            return algorithms_list
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при получении списка алгоритмов: {e}")
            return []
        except Exception as e:
            logger.error(f"Неизвестная ошибка при получении списка алгоритмов: {e}")
            return []

    def get_algorithm_by_id(self, algorithm_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает данные алгоритма по его ID.
        :param algorithm_id: ID алгоритма.
        :return: Словарь с данными алгоритма или None.
        """
        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            logger.warning("Некорректный ID алгоритма для получения.")
            return None

        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute(
                f"SELECT id, name, category, time_type, description FROM {self.SCHEMA_NAME}.algorithms WHERE id = %s;",
                (algorithm_id,)
            )
            row = cursor.fetchone()
            colnames = [desc[0] for desc in cursor.description]
            cursor.close()
            
            if row:
                algorithm_dict = dict(zip(colnames, row))
                logger.debug(f"Получены данные алгоритма по ID {algorithm_id}: {algorithm_dict}")
                return algorithm_dict
            else:
                logger.warning(f"Алгоритм с ID {algorithm_id} не найден.")
                return None
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при получении данных алгоритма по ID {algorithm_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Неизвестная ошибка при получении данных алгоритма по ID {algorithm_id}: {e}")
            return None

    def create_algorithm(self, algorithm_data: Dict[str, Any]) -> int:
        """
        Создает новый алгоритм в БД.
        :param algorithm_data: Словарь с данными нового алгоритма.
                               Должен содержать ключи: name, category, time_type.
                               Может содержать: description.
        :return: ID нового алгоритма, если успешно, иначе -1.
        """
        if not algorithm_data:
            logger.warning("Попытка создания алгоритма с пустыми данными.")
            return -1

        required_fields = ['name', 'category', 'time_type']
        missing_fields = [field for field in required_fields if not algorithm_data.get(field)]
        if missing_fields:
            logger.error(f"Отсутствуют обязательные поля для создания алгоритма: {missing_fields}")
            return -1

        # Проверка допустимых значений для category и time_type
        allowed_categories = ['повседневная деятельность', 'боевая готовность', 'противодействие терроризму', 'кризисные ситуации']
        allowed_time_types = ['оперативное', 'астрономическое']
        
        if algorithm_data['category'] not in allowed_categories:
            logger.error(f"Недопустимая категория: {algorithm_data['category']}")
            return -1
        if algorithm_data['time_type'] not in allowed_time_types:
            logger.error(f"Недопустимый тип времени: {algorithm_data['time_type']}")
            return -1

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            allowed_fields = ['name', 'category', 'time_type', 'description']
            fields = [field for field in allowed_fields if field in algorithm_data]
            placeholders = ['%s'] * len(fields)
            values = [algorithm_data.get(field) for field in fields]

            columns_str = ', '.join(fields)
            placeholders_str = ', '.join(placeholders)
            sql_query = f"INSERT INTO {self.SCHEMA_NAME}.algorithms ({columns_str}) VALUES ({placeholders_str}) RETURNING id;"
            
            logger.debug(f"Выполнение SQL создания алгоритма: {cursor.mogrify(sql_query, values)}")
            cursor.execute(sql_query, values)
            new_id_row = cursor.fetchone()
            new_id = new_id_row[0] if new_id_row else None
            conn.commit()
            cursor.close()
            
            if new_id:
                logger.info(f"Новый алгоритм успешно создан с ID: {new_id}")
                return new_id
            else:
                logger.error("Не удалось получить ID нового алгоритма после вставки.")
                return -1

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при создании алгоритма: {e}")
            if conn:
                conn.rollback()
            return -1
        except Exception as e:
            logger.error(f"Неизвестная ошибка при создании алгоритма: {e}")
            if conn:
                conn.rollback()
            return -1

    def update_algorithm(self, algorithm_id: int, algorithm_data: Dict[str, Any]) -> bool:
        """
        Обновляет данные существующего алгоритма в БД.
        :param algorithm_id: ID алгоритма для обновления.
        :param algorithm_data: Словарь с новыми данными алгоритма.
                               Может содержать: name, category, time_type, description.
        :return: True, если успешно, иначе False.
        """
        if not algorithm_data:
            logger.warning("Попытка обновления алгоритма с пустыми данными.")
            return False

        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            logger.error("Некорректный ID алгоритма для обновления.")
            return False

        # Проверка допустимых значений, если они переданы
        if 'category' in algorithm_data and algorithm_data['category'] not in ['повседневная деятельность', 'боевая готовность', 'противодействие терроризму', 'кризисные ситуации']:
             logger.error(f"Недопустимая категория: {algorithm_data['category']}")
             return False
        if 'time_type' in algorithm_data and algorithm_data['time_type'] not in ['оперативное', 'астрономическое']:
             logger.error(f"Недопустимый тип времени: {algorithm_data['time_type']}")
             return False

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            allowed_fields = ['name', 'category', 'time_type', 'description']
            fields_to_update = [field for field in allowed_fields if field in algorithm_data]
            
            if not fields_to_update:
                logger.warning("Нет полей для обновления алгоритма.")
                return False

            set_clauses = [f"{field} = %s" for field in fields_to_update]
            values = [algorithm_data[field] for field in fields_to_update]
            values.append(algorithm_id)
            
            set_clause_str = ', '.join(set_clauses)
            sql_query = f"UPDATE {self.SCHEMA_NAME}.algorithms SET {set_clause_str} WHERE id = %s;"
            
            logger.debug(f"Выполнение SQL обновления алгоритма {algorithm_id}: {cursor.mogrify(sql_query, values)}")
            cursor.execute(sql_query, values)
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Алгоритм с ID {algorithm_id} успешно обновлен. Затронуто строк: {rows_affected}.")
                return True
            else:
                logger.warning(f"Не удалось обновить алгоритм с ID {algorithm_id} (запись не найдена или данные не изменились).")
                return False

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при обновлении алгоритма {algorithm_id}: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при обновлении алгоритма {algorithm_id}: {e}")
            if conn:
                conn.rollback()
            return False

    def delete_algorithm(self, algorithm_id: int) -> bool:
        """
        Удаляет алгоритм из БД. Из-за ON DELETE CASCADE связанные actions также будут удалены.
        Однако algorithm_executions останутся (из-за отсутствия CASCADE в схеме).
        :param algorithm_id: ID алгоритма для удаления.
        :return: True, если успешно, иначе False.
        """
        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            logger.error("Некорректный ID алгоритма для удаления.")
            return False

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            # Проверяем, существуют ли выполнения этого алгоритма
            cursor.execute(
                f"SELECT COUNT(*) FROM {self.SCHEMA_NAME}.algorithm_executions WHERE algorithm_id = %s;",
                (algorithm_id,)
            )
            execution_count = cursor.fetchone()[0]
            
            if execution_count > 0:
                logger.warning(f"Невозможно удалить алгоритм ID {algorithm_id}, так как существуют ({execution_count}) записей о его выполнении. Рассмотрите архивирование.")
                cursor.close()
                return False # Или выбросить исключение, в зависимости от логики UI

            sql_query = f"DELETE FROM {self.SCHEMA_NAME}.algorithms WHERE id = %s;"
            
            logger.debug(f"Выполнение SQL удаления алгоритма {algorithm_id}: {cursor.mogrify(sql_query, (algorithm_id,))}")
            cursor.execute(sql_query, (algorithm_id,))
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Алгоритм с ID {algorithm_id} успешно удален из БД. Затронуто строк: {rows_affected}.")
                return True
            else:
                logger.warning(f"Не удалось удалить алгоритм с ID {algorithm_id} (запись не найдена).")
                return False

        except psycopg2.IntegrityError as e:
            # Это может произойти, если есть algorithm_executions
            logger.error(f"Ошибка целостности БД при удалении алгоритма {algorithm_id} (возможно, есть выполнения): {e}")
            if conn:
                conn.rollback()
            return False
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при удалении алгоритма {algorithm_id}: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при удалении алгоритма {algorithm_id}: {e}")
            if conn:
                conn.rollback()
            return False

# db/postgresql_manager.py

# ... (другие методы класса PostgreSQLDatabaseManager) ...

    def duplicate_algorithm(self, original_algorithm_id: int) -> int:
        """
        Создает копию существующего алгоритма и всех его действий.
        :param original_algorithm_id: ID оригинального алгоритма.
        :return: ID нового алгоритма, если успешно, иначе -1.
        """
        # 1. Получаем данные оригинального алгоритма
        original_algorithm = self.get_algorithm_by_id(original_algorithm_id)
        if not original_algorithm:
            logger.error(f"Не удалось найти оригинальный алгоритм с ID {original_algorithm_id} для дублирования.")
            return -1

        # 2. Формируем данные для нового алгоритма (с пометкой "копия")
        original_name = original_algorithm.get('name', 'Алгоритм')
        new_name = f"{original_name} (копия)"

        new_algorithm_data = {
            'name': new_name,
            'category': original_algorithm['category'],
            'time_type': original_algorithm['time_type'],
            'description': original_algorithm.get('description', '')
        }

        # 3. Создаем новый алгоритм в БД
        new_algorithm_id = self.create_algorithm(new_algorithm_data)
        
        # 4. Проверяем, успешно ли создан новый алгоритм
        if isinstance(new_algorithm_id, int) and new_algorithm_id > 0:
            logger.info(f"Алгоритм ID {original_algorithm_id} успешно дублирован. Новый ID: {new_algorithm_id}")

            # --- НОВАЯ ЛОГИКА: Дублирование всех действий оригинального алгоритма ---
            try:
                # a. Получаем список всех действий оригинального алгоритма
                original_actions = self.get_actions_by_algorithm_id(original_algorithm_id)
                logger.debug(f"Найдено {len(original_actions)} действий для дублирования из алгоритма {original_algorithm_id}.")
                
                # b. Проходимся по каждому действию и создаем его копию
                actions_duplicated_count = 0
                for original_action in original_actions:
                    # Подготавливаем данные для нового действия
                    # ВАЖНО: algorithm_id заменяется на ID нового алгоритма
                    new_action_data = {
                        'algorithm_id': new_algorithm_id,  # Привязываем к НОВОМУ алгоритму
                        'description': original_action.get('description', ''),
                        'start_offset': original_action.get('start_offset'),
                        'end_offset': original_action.get('end_offset'),
                        'contact_phones': original_action.get('contact_phones'),
                        'report_materials': original_action.get('report_materials')
                    }
                    # Создаем копию действия в БД
                    new_action_id = self.create_action(new_action_data)
                    if isinstance(new_action_id, int) and new_action_id > 0:
                        logger.debug(f"Действие ID {original_action['id']} дублировано как ID {new_action_id} для нового алгоритма {new_algorithm_id}.")
                        actions_duplicated_count += 1
                    else:
                        logger.warning(f"Не удалось дублировать действие ID {original_action['id']} для алгоритма {new_algorithm_id}.")
                
                logger.info(f"Для нового алгоритма {new_algorithm_id} дублировано {actions_duplicated_count} из {len(original_actions)} действий.")
                        
            except Exception as e_actions:
                logger.error(f"Ошибка при дублировании действий для нового алгоритма {new_algorithm_id}: {e_actions}")
                import traceback
                traceback.print_exc()
                # Примечание: Сам алгоритм уже создан, просто действия не дублированы.
                # Можно решить, считать ли это критической ошибкой или нет.
                # В данном случае, мы возвращаем ID алгоритма, но логируем ошибку.
            # --- КОНЕЦ НОВОЙ ЛОГИКИ ---
            
            # 5. Возвращаем ID нового алгоритма (с дублированными действиями или без)
            return new_algorithm_id
        else:
            logger.error(f"Ошибка при дублировании алгоритма ID {original_algorithm_id}. Метод create_algorithm вернул: {new_algorithm_id}")
            return -1

# ... (другие методы класса PostgreSQLDatabaseManager) ...


    # --- МЕТОДЫ ДЛЯ РАБОТЫ С ACTIONS ---

    def get_actions_by_algorithm_id(self, algorithm_id: int) -> List[Dict[str, Any]]:
        """
        Получает список всех действий для заданного алгоритма, отсортированных по start_offset.
        :param algorithm_id: ID алгоритма.
        :return: Список словарей с данными действий.
        """
        if not isinstance(algorithm_id, int) or algorithm_id <= 0:
            logger.warning("Некорректный ID алгоритма для получения действий.")
            return []

        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            # Используем полное имя таблицы с указанием схемы
            cursor.execute(
                f"SELECT id, algorithm_id, description, start_offset, end_offset, contact_phones, report_materials, created_at, updated_at FROM {self.SCHEMA_NAME}.actions WHERE algorithm_id = %s ORDER BY start_offset ASC;",
                (algorithm_id,)
            )
            rows = cursor.fetchall()
            # Получаем названия колонок
            colnames = [desc[0] for desc in cursor.description]
            cursor.close()
            
            # --- ИЗМЕНЕНО: Преобразование timedelta в строки ---
            actions_list = []
            for row in rows:
                # Создаем словарь из строки результата
                action_dict = dict(zip(colnames, row))
                
                # Преобразуем start_offset и end_offset, если они являются timedelta
                for time_field in ['start_offset', 'end_offset']:
                    if isinstance(action_dict[time_field], datetime.timedelta):
                        # timedelta можно преобразовать в строку в формате, понятном QML
                        # Например, "1 day, 2:30:45" -> "1 day 02:30:45"
                        # Или можно использовать strftime, если нужно определенное форматирование
                        # Для простоты используем стандартное строковое представление
                        # action_dict[time_field] = str(action_dict[time_field]) 
                        # Или более контролируемый формат:
                        td = action_dict[time_field]
                        # Форматируем как "DD:HH:MM:SS"
                        days = td.days
                        hours, remainder = divmod(td.seconds, 3600)
                        minutes, seconds = divmod(remainder, 60)
                        action_dict[time_field] = f"{days}:{hours:02d}:{minutes:02d}:{seconds:02d}"
                        logger.debug(f"Преобразован {time_field} из timedelta в строку: {action_dict[time_field]}")
                    elif action_dict[time_field] is None:
                         # Если значение NULL в БД, преобразуем в пустую строку или оставляем None
                         # В зависимости от вашей логики в QML
                         action_dict[time_field] = "" # или None
                         logger.debug(f"{time_field} был None, преобразован в пустую строку")
                    else:
                        # Если это уже строка (например, из интервала типа '1 hour 30 minutes'),
                        # оставляем как есть или преобразуем в строку принудительно
                        action_dict[time_field] = str(action_dict[time_field])
                        
                actions_list.append(action_dict)
            # --- ---
            
            logger.debug(f"Получен список {len(actions_list)} действий для алгоритма ID {algorithm_id}.")
            return actions_list
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при получении списка действий для алгоритма {algorithm_id}: {e}")
            return []
        except Exception as e:
            logger.error(f"Неизвестная ошибка при получении списка действий для алгоритма {algorithm_id}: {e}")
            import traceback
            traceback.print_exc() # Для более детального лога ошибок
            return []

    def get_action_by_id(self, action_id: int) -> Optional[Dict[str, Any]]:
        """
        Получает данные действия по его ID.
        :param action_id: ID действия.
        :return: Словарь с данными действия или None.
        """
        if not isinstance(action_id, int) or action_id <= 0:
            logger.warning("Некорректный ID действия для получения.")
            return None

        try:
            conn = self._get_connection()
            cursor = conn.cursor()
            cursor.execute(
                f"SELECT id, algorithm_id, description, start_offset, end_offset, contact_phones, report_materials FROM {self.SCHEMA_NAME}.actions WHERE id = %s;",
                (action_id,)
            )
            row = cursor.fetchone()
            colnames = [desc[0] for desc in cursor.description]
            cursor.close()
            
            if row:
                action_dict = dict(zip(colnames, row))
                logger.debug(f"Получены данные действия по ID {action_id}: {action_dict}")
                return action_dict
            else:
                logger.warning(f"Действие с ID {action_id} не найдено.")
                return None
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при получении данных действия по ID {action_id}: {e}")
            return None
        except Exception as e:
            logger.error(f"Неизвестная ошибка при получении данных действия по ID {action_id}: {e}")
            return None

    def _convert_time_string_to_interval(self, time_str: str) -> str:
        """
        Преобразует строку времени формата 'dd:hh:mm:ss' или 'hh:mm:ss' 
        в формат INTERVAL PostgreSQL, например '1 day 02:30:45' или '02:30:45'.
        Также поддерживает 'dd:h:m:s' (без ведущих нулей).
        :param time_str: Строка времени.
        :return: Форматированная строка INTERVAL для PostgreSQL или исходная строка, если формат не распознан.
        """
        if not time_str:
            return '0 seconds' 

        # 1. Попробуем сначала формат dd:hh:mm:ss (с ведущими нулями или без)
        # Регулярное выражение для dd:hh:mm:ss или dd:h:m:s
        # \d+ - один или более цифр для дней
        # \d{1,2} - одна или две цифры для часов/минут/секунд
        match_dd_hh_mm_ss = re.fullmatch(r'(\d+):(\d{1,2}):(\d{1,2}):(\d{1,2})', time_str)
        if match_dd_hh_mm_ss:
            days, hours, minutes, seconds = match_dd_hh_mm_ss.groups()
            days_int = int(days)
            hours_int = int(hours)
            minutes_int = int(minutes)
            seconds_int = int(seconds)
            
            # Формируем строку для PostgreSQL
            interval_parts = []
            if days_int > 0:
                interval_parts.append(f"{days_int} day{'s' if days_int != 1 else ''}")
            
            # Форматируем время как HH:MM:SS с ведущими нулями
            time_part = f"{hours_int:02d}:{minutes_int:02d}:{seconds_int:02d}"
            interval_parts.append(time_part)
            
            return " ".join(interval_parts) # Например: "1 day 02:30:45"

        # 2. Попробуем формат hh:mm:ss (с ведущими нулями или без)
        # \d{1,2} - одна или две цифры
        match_hh_mm_ss = re.fullmatch(r'(\d{1,2}):(\d{1,2}):(\d{1,2})', time_str)
        if match_hh_mm_ss:
            hours, minutes, seconds = match_hh_mm_ss.groups()
            # Форматируем как HH:MM:SS с ведущими нулями, это должно быть понятно PostgreSQL
            return f"{int(hours):02d}:{int(minutes):02d}:{int(seconds):02d}" 
            
        # Если формат не распознан, возвращаем исходную строку
        logger.warning(f"Нераспознанный формат времени '{time_str}'. Передаю как есть.")
        return time_str

    def create_action(self, action_data: Dict[str, Any]) -> int:
        """
        Создает новое действие в БД.
        :param action_data: Словарь с данными нового действия.
                             Должен содержать ключи: algorithm_id, description.
                             Может содержать: start_offset, end_offset, contact_phones, report_materials.
        :return: ID нового действия, если успешно, иначе -1.
        """
        # ... (проверки на существование action_data и обязательных полей) ...
        if not action_data:
            logger.warning("Попытка создания действия с пустыми данными.")
            return -1

        required_fields = ['algorithm_id', 'description']
        missing_fields = [field for field in required_fields if not action_data.get(field)]
        if missing_fields:
            logger.error(f"Отсутствуют обязательные поля для создания действия: {missing_fields}")
            return -1
        # ... (остальные проверки) ...

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            # --- ИЗМЕНЕНО: Подготовка полей и значений с преобразованием времени ---
            # Определяем поля, которые будут вставлены
            allowed_fields = ['algorithm_id', 'description', 'start_offset', 'end_offset', 'contact_phones', 'report_materials']
            fields = [field for field in allowed_fields if field in action_data]
            
            # Создаем список %s плейсхолдеров
            placeholders = ['%s'] * len(fields)
            
            # Формируем значения для вставки, обрабатывая типы данных
            values = []
            for field in fields:
                val = action_data.get(field)
                # --- ДОБАВЛЕНО: Преобразование времени ---
                if field in ['start_offset', 'end_offset']:
                    # Преобразуем строку времени в формат INTERVAL PostgreSQL
                    formatted_interval = self._convert_time_string_to_interval(str(val) if val is not None else "")
                    values.append(formatted_interval) # Передаем преобразованную строку
                    logger.debug(f"Преобразовано {field} из '{val}' в INTERVAL '{formatted_interval}'")
                # --- ---
                else: # algorithm_id, description, contact_phones, report_materials
                    # Для текстовых полей None -> NULL, пустые строки -> NULL
                    processed_val = val if val is not None else None
                    if isinstance(processed_val, str) and processed_val == "":
                         processed_val = None
                    values.append(processed_val)

            if not fields:
                logger.error("Нет корректных полей для вставки.")
                return -1
            # --- ---

            # ... (формирование и выполнение SQL-запроса) ...

            columns_str = ', '.join(fields)
            placeholders_str = ', '.join(placeholders)
            # Используем RETURNING id для получения ID нового пользователя
            sql_query = f"INSERT INTO {self.SCHEMA_NAME}.actions ({columns_str}) VALUES ({placeholders_str}) RETURNING id;"
            
            logger.debug(f"Выполнение SQL создания действия: {cursor.mogrify(sql_query, values)}")
            cursor.execute(sql_query, values)
            new_id_row = cursor.fetchone()
            new_id = new_id_row[0] if new_id_row else None
            conn.commit()
            cursor.close()
            
            if new_id:
                logger.info(f"Новое действие успешно создано с ID: {new_id}")
                return new_id
            else:
                logger.error("Не удалось получить ID нового действия после вставки.")
                return -1

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при создании действия: {e}")
            if conn:
                conn.rollback()
            return -1
        except Exception as e:
            logger.error(f"Неизвестная ошибка при создании действия: {e}")
            if conn:
                conn.rollback()
            return -1

    def update_action(self, action_id: int, action_data: Dict[str, Any]) -> bool:
        """
        Обновляет данные существующего действия в БД.
        :param action_id: ID действия для обновления.
        :param action_data: Словарь с новыми данными действия.
                            Может содержать: algorithm_id, description, start_offset, end_offset,
                                           contact_phones, report_materials.
        :return: True, если успешно, иначе False.
        """
        # ... (проверки на существование action_data и action_id) ...
        if not action_data:
            logger.warning("Попытка обновления действия с пустыми данными.")
            return False

        if not isinstance(action_id, int) or action_id <= 0:
            logger.error("Некорректный ID действия для обновления.")
            return False
        # ... (остальные проверки) ...

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            # --- ИЗМЕНЕНО: Подготовка данных с преобразованием времени ---
            # Фильтруем и готовим только разрешенные поля
            allowed_fields = ['algorithm_id', 'description', 'start_offset', 'end_offset', 'contact_phones', 'report_materials']
            fields_to_update = [field for field in allowed_fields if field in action_data]
            
            if not fields_to_update:
                logger.warning("Нет полей для обновления действия.")
                return False

            set_clauses = []
            values = []
            for field in fields_to_update:
                val = action_data.get(field)
                # --- ДОБАВЛЕНО: Преобразование времени ---
                if field in ['start_offset', 'end_offset']:
                    # Преобразуем строку времени в формат INTERVAL PostgreSQL
                    formatted_interval = self._convert_time_string_to_interval(str(val) if val is not None else "")
                    values.append(formatted_interval) # Передаем преобразованную строку
                    logger.debug(f"Преобразовано {field} из '{val}' в INTERVAL '{formatted_interval}'")
                # --- ---
                else: # algorithm_id, description, contact_phones, report_materials
                    # Обработка текстовых полей: пустая строка -> None -> NULL
                    processed_val = val if val is not None else None
                    if isinstance(processed_val, str) and processed_val == "":
                         processed_val = None
                    values.append(processed_val)
                
                set_clauses.append(f"{field} = %s")

            # Добавляем action_id в конец списка значений для WHERE
            values.append(action_id)
            # --- ---

            # ... (формирование и выполнение SQL-запроса) ...
            
            set_clause_str = ', '.join(set_clauses)
            sql_query = f"UPDATE {self.SCHEMA_NAME}.actions SET {set_clause_str} WHERE id = %s;"
            
            logger.debug(f"Выполнение SQL обновления действия {action_id}: {cursor.mogrify(sql_query, values)}")
            cursor.execute(sql_query, values)
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Действие с ID {action_id} успешно обновлено. Затронуто строк: {rows_affected}.")
                return True
            else:
                logger.warning(f"Не удалось обновить действие с ID {action_id} (запись не найдена или данные не изменились).")
                return False

        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при обновлении действия {action_id}: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при обновлении действия {action_id}: {e}")
            if conn:
                conn.rollback()
            return False

    def delete_action(self, action_id: int) -> bool:
        """
        Удаляет действие из БД.
        :param action_id: ID действия для удаления.
        :return: True, если успешно, иначе False.
        """
        if not isinstance(action_id, int) or action_id <= 0:
            logger.error("Некорректный ID действия для удаления.")
            return False

        try:
            conn = self._get_connection()
            cursor = conn.cursor()

            # Проверяем, существуют ли выполнения этого действия
            cursor.execute(
                f"SELECT COUNT(*) FROM {self.SCHEMA_NAME}.action_executions WHERE action_id = %s;",
                (action_id,)
            )
            execution_count = cursor.fetchone()[0]
            
            if execution_count > 0:
                logger.warning(f"Невозможно удалить действие ID {action_id}, так как существуют ({execution_count}) записей о его выполнении.")
                cursor.close()
                # Можно вернуть False или выбросить исключение
                # return False 

            sql_query = f"DELETE FROM {self.SCHEMA_NAME}.actions WHERE id = %s;"
            
            logger.debug(f"Выполнение SQL удаления действия {action_id}: {cursor.mogrify(sql_query, (action_id,))}")
            cursor.execute(sql_query, (action_id,))
            conn.commit()
            
            rows_affected = cursor.rowcount
            cursor.close()
            
            if rows_affected > 0:
                logger.info(f"Действие с ID {action_id} успешно удалено из БД. Затронуто строк: {rows_affected}.")
                return True
            else:
                logger.warning(f"Не удалось удалить действие с ID {action_id} (запись не найдена).")
                return False

        except psycopg2.IntegrityError as e:
            # Это может произойти, если есть action_executions
            logger.error(f"Ошибка целостности БД при удалении действия {action_id} (возможно, есть выполнения): {e}")
            if conn:
                conn.rollback()
            return False
        except psycopg2.Error as e:
            logger.error(f"Ошибка БД при удалении действия {action_id}: {e}")
            if conn:
                conn.rollback()
            return False
        except Exception as e:
            logger.error(f"Неизвестная ошибка при удалении действия {action_id}: {e}")
            if conn:
                conn.rollback()
            return False

    def duplicate_action(self, original_action_id: int, new_algorithm_id: int = None) -> int:
        """
        Создает копию существующего действия.
        :param original_action_id: ID оригинального действия.
        :param new_algorithm_id: ID алгоритма для новой копии (если None, используется ID оригинального алгоритма).
        :return: ID нового действия, если успешно, иначе -1.
        """
        original_action = self.get_action_by_id(original_action_id)
        if not original_action:
            logger.error(f"Не удалось найти оригинальное действие с ID {original_action_id} для дублирования.")
            return -1

        new_action_data = {
            'algorithm_id': new_algorithm_id if new_algorithm_id is not None else original_action['algorithm_id'],
            'description': original_action['description'],
            'start_offset': original_action.get('start_offset'),
            'end_offset': original_action.get('end_offset'),
            'contact_phones': original_action.get('contact_phones'),
            'report_materials': original_action.get('report_materials')
        }

        new_action_id = self.create_action(new_action_data)
        
        if new_action_id != -1:
            logger.info(f"Действие ID {original_action_id} успешно дублировано. Новый ID: {new_action_id}")
        else:
            logger.error(f"Ошибка при дублировании действия ID {original_action_id}.")
            
        return new_action_id
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
