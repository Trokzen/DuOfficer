-- db/init_postgres_schema.sql

-- 1. Создание схемы (если она еще не существует)
CREATE SCHEMA IF NOT EXISTS app_schema;

-- 2. Создание таблицы пользователей (должностных лиц) в новой схеме
CREATE TABLE IF NOT EXISTS app_schema.users (
    id SERIAL PRIMARY KEY,                             -- Уникальный идентификатор пользователя
    login VARCHAR(50) UNIQUE NOT NULL,                 -- Уникальное имя для входа в систему
    password_hash TEXT NOT NULL,                       -- Хэш пароля пользователя для безопасной аутентификации
    rank VARCHAR(100),                                 -- Звание пользователя (например, "лейтенант")
    last_name VARCHAR(100),                            -- Фамилия пользователя
    first_name VARCHAR(100),                           -- Имя пользователя
    middle_name VARCHAR(100),                          -- Отчество пользователя
    phone VARCHAR(20),                                 -- Контактный телефон пользователя
    is_active BOOLEAN DEFAULT TRUE,                    -- Флаг активности пользователя (может ли входить в систему)
    is_admin BOOLEAN DEFAULT FALSE,                    -- Флаг администратора (имеет ли права администратора)
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- Дата и время создания записи пользователя
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP     -- Дата и время последнего обновления записи пользователя
);

-- 3. Создание таблицы настроек поста в новой схеме (переименована из settings)
CREATE TABLE IF NOT EXISTS app_schema.post_settings (
    id INTEGER PRIMARY KEY CHECK (id = 1),             -- Уникальный идентификатор записи настроек (ограничен одной записью)
    workplace_name TEXT,                               -- Название рабочего места (например, "Рабочее место дежурного")
    post_number TEXT,                                 -- Номер поста (например, "1")
    post_name TEXT,                                   -- Название поста (например, "Дежурство по части")
    use_persistent_reminders BOOLEAN DEFAULT TRUE,     -- Флаг использования настойчивых напоминаний
    sound_enabled BOOLEAN DEFAULT TRUE,               -- Флаг включения звуковых сигналов
    custom_datetime TIMESTAMP,                        -- Пользовательская дата и время (для коррекции времени системы)
    background_image_path TEXT,                       -- Путь к фоновому изображению/эмблеме
    font_family TEXT DEFAULT 'Arial',                 -- Название шрифта интерфейса
    font_size INTEGER DEFAULT 12,                     -- Размер шрифта интерфейса
    background_color TEXT DEFAULT '#ecf0f1',          -- Цвет фонового оформления
    -- current_officer_id INTEGER REFERENCES app_schema.users(id), -- ССЫЛКА УДАЛЕНА
    print_font_family TEXT DEFAULT 'Arial',           -- Название шрифта для печати
    print_font_size INTEGER DEFAULT 12                -- Размер шрифта для печати
);

-- === НОВЫЕ ТАБЛИЦЫ ДЛЯ АЛГОРИТМОВ ===

-- Таблица для хранения алгоритмов
CREATE TABLE IF NOT EXISTS app_schema.algorithms (
    id SERIAL PRIMARY KEY,                             -- Уникальный идентификатор алгоритма
    name VARCHAR(255) NOT NULL,                        -- Наименование алгоритма (например, "Алгоритм реагирования на пожар")
    category VARCHAR(100) NOT NULL CHECK (category IN ('повседневная деятельность', 'боевая готовность', 'противодействие терроризму', 'кризисные ситуации')), -- Категория алгоритма
    time_type VARCHAR(50) NOT NULL CHECK (time_type IN ('оперативное', 'астрономическое')), -- Тип времени выполнения алгоритма
    description TEXT,                                  -- Описание алгоритма
    -- --- НОВОЕ: Поле для ранжирования ---
    sort_order INTEGER DEFAULT 0,                     -- Порядковый номер для сортировки алгоритмов в списке
    -- --- ---
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- Дата и время создания записи алгоритма
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP     -- Дата и время последнего обновления записи алгоритма
);

-- Таблица для хранения действий внутри алгоритмов
CREATE TABLE IF NOT EXISTS app_schema.actions (
    id SERIAL PRIMARY KEY,                             -- Уникальный идентификатор действия
    algorithm_id INTEGER NOT NULL REFERENCES app_schema.algorithms(id) ON DELETE CASCADE, -- Ссылка на родительский алгоритм
    description TEXT NOT NULL,                         -- Описание действия
    start_offset INTERVAL,                             -- Относительное время начала действия (смещение от начала алгоритма)
    end_offset INTERVAL,                               -- Относительное время окончания действия (смещение от начала алгоритма)
    contact_phones TEXT,                               -- Телефоны для связи, связанные с этим действием
    report_materials TEXT,                             -- Пути или ссылки на отчетные материалы
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- Дата и время создания записи действия
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- Дата и время последнего обновления записи действия
    -- --- НОВОЕ: Ограничение на порядок времени ---
    CONSTRAINT check_action_time_order CHECK (
        start_offset IS NULL OR
        end_offset IS NULL OR
        start_offset <= end_offset
    )
    -- --- ---
);

-- Таблица для хранения запущенных/выполняемых экземпляров алгоритмов
-- Изменена в соответствии с Snapshot-подходом.
CREATE TABLE IF NOT EXISTS app_schema.algorithm_executions (
    id SERIAL PRIMARY KEY,                             -- Уникальный идентификатор экземпляра выполнения алгоритма
    -- --- ССЫЛКА на исходный алгоритм сохраняется для трассировки ---
    algorithm_id INTEGER NOT NULL REFERENCES app_schema.algorithms(id), -- Ссылка на выполняемый алгоритм (для трассировки)
    -- --- ПОЛЯ ДЛЯ SNAPSHOT'А ДАННЫХ АЛГОРИТМА НА МОМЕНТ ЗАПУСКА ---
    -- Эти поля хранят копию данных алгоритма на момент создания execution'а
    snapshot_name VARCHAR(255) NOT NULL,              -- Копия name алгоритма на момент запуска
    snapshot_category VARCHAR(100) NOT NULL,           -- Копия category алгоритма на момент запуска
    snapshot_time_type VARCHAR(50) NOT NULL,          -- Копия time_type алгоритма на момент запуска
    snapshot_description TEXT,                         -- Копия description алгоритма на момент запуска
    -- --- ---
    started_at TIMESTAMP,                              -- Фактическое время начала выполнения экземпляра
    completed_at TIMESTAMP,                            -- Фактическое время завершения выполнения экземпляра
    status VARCHAR(50) DEFAULT 'active' CHECK (status IN ('active', 'completed', 'cancelled')), -- Статус выполнения экземпляра
    -- --- ОБНОВЛЕНО: Информация о пользователе на момент запуска ---
    created_by_user_id INTEGER,                        -- ID пользователя на момент запуска (для трассировки, может быть NULL если пользователь удален)
    created_by_user_display_name TEXT,                -- Отображаемое имя пользователя на момент запуска (Фамилия И.О.)
    -- --- ---
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- Дата и время создания записи выполнения
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP     -- Дата и время последнего обновления записи выполнения
);

-- Таблица для хранения выполнения действий в рамках запущенного алгоритма
-- Изменена кардинально в соответствии с Snapshot-подходом и уточнениями.
CREATE TABLE IF NOT EXISTS app_schema.action_executions (
    id SERIAL PRIMARY KEY,                             -- Уникальный идентификатор выполнения действия
    -- --- ССЫЛКА на execution, а не на action ---
    execution_id INTEGER NOT NULL REFERENCES app_schema.algorithm_executions(id) ON DELETE CASCADE, -- Ссылка на экземпляр выполнения алгоритма
    -- --- ---
    
    -- --- ПОЛЯ ДЛЯ SNAPSHOT'А СТАТИЧЕСКИХ ДАННЫХ ДЕЙСТВИЯ НА МОМЕНТ ПЛАНИРОВАНИЯ ---
    -- Эти поля хранят копию данных действия на момент планирования его выполнения
    -- Они позволяют action_execution существовать независимо от оригинального шаблона действия
    snapshot_description TEXT NOT NULL,              -- Копия description действия на момент планирования
    snapshot_contact_phones TEXT,                     -- Копия contact_phones действия на момент планирования
    snapshot_report_materials TEXT,                   -- Копия report_materials действия на момент планирования
    -- --- ---
    
    -- --- РАССЧИТАННЫЕ АБСОЛЮТНЫЕ ВРЕМЕНА (вместо snapshot смещений) ---
    -- Рассчитываются один раз на основе snapshot_*_offset шаблона действия и времени запуска алгоритма
    calculated_start_time TIMESTAMP,                   -- Рассчитанное (планируемое) АБСОЛЮТНОЕ время начала действия
    calculated_end_time TIMESTAMP,                     -- Рассчитанное (планируемое) АБСОЛЮТНОЕ время окончания действия
    -- --- ---
    
    -- --- ФАКТИЧЕСКИЕ ВРЕМЕНА ВЫПОЛНЕНИЯ ---
    -- actual_start_time TIMESTAMP,                    -- Фактическое время начала выполнения действия (УБРАНО по требованию)
    actual_end_time TIMESTAMP,                         -- Фактическое время окончания выполнения действия (ОБЯЗАТЕЛЬНО)
    -- --- ---
    
    status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'in_progress', 'completed', 'skipped')), -- Статус выполнения действия
    reported_to TEXT,                                  -- Информация о том, кому было доложено о выполнении действия
    notes TEXT,                                        -- Дополнительные заметки по выполнению действия
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,    -- Дата и время создания записи выполнения действия
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP     -- Дата и время последнего обновления записи выполнения действия
);

-- === ИНДЕКСЫ ===

-- Индекс для ускорения поиска действий по алгоритму
CREATE INDEX IF NOT EXISTS idx_actions_algorithm_id ON app_schema.actions(algorithm_id);

-- Индексы для оптимизации запросов логов
CREATE INDEX IF NOT EXISTS idx_algorithm_executions_algorithm_id ON app_schema.algorithm_executions(algorithm_id);
CREATE INDEX IF NOT EXISTS idx_algorithm_executions_status ON app_schema.algorithm_executions(status);
CREATE INDEX IF NOT EXISTS idx_action_executions_execution_id ON app_schema.action_executions(execution_id);
-- CREATE INDEX IF NOT EXISTS idx_action_executions_action_id ON app_schema.action_executions(action_id); -- ИНДЕКС УДАЛЕН
CREATE INDEX IF NOT EXISTS idx_action_executions_status ON app_schema.action_executions(status);

-- --- НОВЫЙ ИНДЕКС: Для сортировки алгоритмов ---
CREATE INDEX IF NOT EXISTS idx_algorithms_sort_order ON app_schema.algorithms(sort_order);
-- --- ---

-- === ФУНКЦИИ И ТРИГГЕРЫ ===

-- Создание или замена функции для обновления поля updated_at
CREATE OR REPLACE FUNCTION app_schema.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
   NEW.updated_at = CURRENT_TIMESTAMP;
   RETURN NEW;
END;
$$ language 'plpgsql';

-- Триггеры для обновления updated_at для всех таблиц

-- Для users
DROP TRIGGER IF EXISTS update_users_updated_at ON app_schema.users;
CREATE TRIGGER update_users_updated_at
BEFORE UPDATE ON app_schema.users
FOR EACH ROW
EXECUTE FUNCTION app_schema.update_updated_at_column();

-- Для post_settings (новое имя)
DROP TRIGGER IF EXISTS update_post_settings_updated_at ON app_schema.post_settings;
CREATE TRIGGER update_post_settings_updated_at
BEFORE UPDATE ON app_schema.post_settings
FOR EACH ROW
EXECUTE FUNCTION app_schema.update_updated_at_column();

-- Для algorithms
DROP TRIGGER IF EXISTS update_algorithms_updated_at ON app_schema.algorithms;
CREATE TRIGGER update_algorithms_updated_at
BEFORE UPDATE ON app_schema.algorithms
FOR EACH ROW
EXECUTE FUNCTION app_schema.update_updated_at_column();

-- Для actions
DROP TRIGGER IF EXISTS update_actions_updated_at ON app_schema.actions;
CREATE TRIGGER update_actions_updated_at
BEFORE UPDATE ON app_schema.actions
FOR EACH ROW
EXECUTE FUNCTION app_schema.update_updated_at_column();

-- Для algorithm_executions
DROP TRIGGER IF EXISTS update_algorithm_executions_updated_at ON app_schema.algorithm_executions;
CREATE TRIGGER update_algorithm_executions_updated_at
BEFORE UPDATE ON app_schema.algorithm_executions
FOR EACH ROW
EXECUTE FUNCTION app_schema.update_updated_at_column();

-- Для action_executions
DROP TRIGGER IF EXISTS update_action_executions_updated_at ON app_schema.action_executions;
CREATE TRIGGER update_action_executions_updated_at
BEFORE UPDATE ON app_schema.action_executions
FOR EACH ROW
EXECUTE FUNCTION app_schema.update_updated_at_column();

-- === НАЧАЛЬНЫЕ ДАННЫЕ ===

-- Вставка начальных настроек поста
INSERT INTO app_schema.post_settings (
    id, 
    workplace_name, 
    post_number, 
    post_name, 
    print_font_family, 
    print_font_size,
    use_persistent_reminders,
    sound_enabled
)
VALUES (
    1, 
    'Рабочее место дежурного', 
    '1', 
    'Дежурство по части', 
    'Arial', 
    12,
    TRUE,
    TRUE
)
ON CONFLICT (id) DO NOTHING;

-- Вставка начального администратора
-- !!! ВАЖНО: Замените 'PLACEHOLDER_WERKZEUG_HASH_HERE' на реальный хэш пароля 'admin' !!!
INSERT INTO app_schema.users (
    login, 
    password_hash, 
    rank, 
    last_name, 
    first_name, 
    middle_name, 
    is_admin
)
VALUES (
    'admin', 
    'scrypt:32768:8:1$Atn4MrMt5x0I1XQr$a9f9efc8c59fdf784156004ace3717466af3e871cc9f4ee6a07ec72dc7319196fd741dde5d3458b21731c92e57fcc833eec0141a746d46237816dc016ef76475', 
    'Администратор', 
    'Админов', 
    'Админ', 
    'Админович', 
    TRUE
)
ON CONFLICT (login) DO NOTHING;

-- Сообщение
DO $$ BEGIN
    RAISE NOTICE 'Схема ''app_schema'' создана (если не существовала).';
    RAISE NOTICE 'Таблицы (users, post_settings, algorithms, actions, algorithm_executions, action_executions) и начальные данные созданы в схеме ''app_schema''.';
    RAISE NOTICE 'Пожалуйста, замените плейсхолдер хэша пароля для пользователя ''admin'' на реальный хэш.';
    RAISE NOTICE 'Таблица algorithms обновлена: добавлено поле sort_order и индекс idx_algorithms_sort_order.';
    RAISE NOTICE 'Таблицы algorithm_executions и action_executions обновлены в соответствии с Snapshot-подходом и уточнениями.';
    RAISE NOTICE 'В таблицу actions добавлено ограничение check_action_time_order.';
END $$;
