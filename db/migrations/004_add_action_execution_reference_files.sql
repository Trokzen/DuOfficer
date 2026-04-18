-- Migration 004: Add table for individual reference file selection per action execution
-- Эта миграция добавляет возможность индивидуального выбора справочных файлов для каждого действия

-- Таблица для связи действий с конкретными справочными файлами организаций
CREATE TABLE IF NOT EXISTS action_execution_reference_files (
    id INTEGER PRIMARY KEY AUTOINCREMENT,              -- Уникальный идентификатор связи
    action_execution_id INTEGER NOT NULL,              -- Ссылка на выполнение действия
    organization_id INTEGER NOT NULL,                  -- Ссылка на организацию (для контекста)
    reference_file_id INTEGER NOT NULL,                -- Ссылка на справочный файл организации
    created_at TEXT DEFAULT (datetime('now', 'localtime')), -- Дата и время создания связи
    FOREIGN KEY (action_execution_id) REFERENCES action_executions(id) ON DELETE CASCADE,
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
    FOREIGN KEY (reference_file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
    UNIQUE(action_execution_id, reference_file_id)     -- Уникальность связи действие-файл
);

-- Индексы для оптимизации запросов
CREATE INDEX IF NOT EXISTS idx_ae_ref_files_action_execution_id ON action_execution_reference_files(action_execution_id);
CREATE INDEX IF NOT EXISTS idx_ae_ref_files_organization_id ON action_execution_reference_files(organization_id);
CREATE INDEX IF NOT EXISTS idx_ae_ref_files_reference_file_id ON action_execution_reference_files(reference_file_id);
