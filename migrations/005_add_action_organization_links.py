"""
Миграция: Добавление связи Действие-Организация-Файл
Создает таблицу action_organization_links для точечной привязки 
справочных материалов организаций к конкретным действиям.
"""
import sqlite3
import os

DB_PATH = 'duty_app.db'

def apply_migration():
    if not os.path.exists(DB_PATH):
        print(f"База данных {DB_PATH} не найдена.")
        return

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Проверка существования таблицы
    cursor.execute("""
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name='action_organization_links';
    """)
    if cursor.fetchone():
        print("Таблица 'action_organization_links' уже существует. Миграция пропущена.")
        conn.close()
        return

    # Создание таблицы связи
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS action_organization_links (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_id INTEGER NOT NULL,
        organization_id INTEGER NOT NULL,
        file_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (action_id) REFERENCES actions(id) ON DELETE CASCADE,
        FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
        FOREIGN KEY (file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE
    );
    """
    
    cursor.execute(create_table_sql)
    
    # Создаем индекс для быстрого поиска по действию
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_action_org_links_action 
        ON action_organization_links(action_id);
    """)

    conn.commit()
    conn.close()
    print("Миграция успешно применена: таблица 'action_organization_links' создана.")

if __name__ == '__main__':
    apply_migration()
