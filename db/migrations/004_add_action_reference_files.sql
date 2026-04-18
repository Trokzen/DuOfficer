-- Миграция 004: Добавление таблицы справочных материалов для действий
-- Дата: 2026-04-15
-- Описание: Создание таблицы action_reference_files для индивидуальной привязки 
-- справочных материалов к каждому действию

-- Таблица для хранения связей действий со справочными файлами
CREATE TABLE IF NOT EXISTS action_reference_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,              -- Уникальный идентификатор записи связи
    action_id INTEGER NOT NULL,                        -- Ссылка на действие (из таблицы actions)
    organization_id INTEGER NOT NULL,                  -- Ссылка на организацию (владелец файла)
    file_id INTEGER NOT NULL,                          -- Ссылка на файл в organization_reference_files
    created_at TEXT DEFAULT (datetime('now', 'localtime')), -- Дата и время привязки файла
    FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
    UNIQUE(action_id, file_id)                         -- Уникальность связи (одно действие - один файл)
);

-- Индексы для ускорения поиска
CREATE INDEX IF NOT EXISTS idx_action_ref_files_action_id ON action_reference_files(action_id);
CREATE INDEX IF NOT EXISTS idx_action_ref_files_organization_id ON action_reference_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_action_ref_files_file_id ON action_reference_files(file_id);
