-- Migration 005: Add table for individual reference file selection per action template
-- Эта миграция добавляет возможность индивидуального выбора справочных файлов для каждого шаблона действия

-- Таблица для связи шаблонов действий с конкретными справочными файлами организаций
CREATE TABLE IF NOT EXISTS action_reference_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,              -- Уникальный идентификатор связи
    action_id INTEGER NOT NULL,                        -- Ссылка на шаблон действия
    organization_id INTEGER NOT NULL,                  -- Ссылка на организацию (для контекста)
    reference_file_id INTEGER NOT NULL,                -- Ссылка на справочный файл организации
    created_at TEXT DEFAULT (datetime('now', 'localtime')), -- Дата и время создания связи
    FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (reference_file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
    UNIQUE(action_id, reference_file_id)               -- Уникальность связи действие-файл
);

-- Индексы для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_action_ref_files_action_id ON action_reference_files(action_id);
CREATE INDEX IF NOT EXISTS idx_action_ref_files_organization_id ON action_reference_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_action_ref_files_reference_file_id ON action_reference_files(reference_file_id);
