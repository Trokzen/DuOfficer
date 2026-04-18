"""
Миграция 006: Добавление связи Выполнение действия - Организация - Файл

Цель: Реализовать логику, где у каждого выполнения действия (action_execution) 
есть свои выбранные организации, и для каждой организации - свои файлы.

Текущая проблема: Организации и справочные материалы общие для всех действий.
Новая логика: У каждого действия должны быть выбранные для него организации 
и выбранные для каждой организации свои файлы.
"""
import sqlite3
import os

DB_PATH = 'duty_app.db'

def apply_migration():
    if not os.path.exists(DB_PATH):
        print(f"База данных {DB_PATH} не найдена.")
        return False

    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()

    # Проверка существования таблицы
    cursor.execute("""
        SELECT name FROM sqlite_master 
        WHERE type='table' AND name='action_execution_organization_files';
    """)
    if cursor.fetchone():
        print("Таблица 'action_execution_organization_files' уже существует. Миграция пропущена.")
        conn.close()
        return True

    # Создание таблицы связи
    # Эта таблица позволяет для каждого выполнения действия выбрать:
    # 1. Конкретные организации
    # 2. Для каждой организации - конкретные файлы
    create_table_sql = """
    CREATE TABLE IF NOT EXISTS action_execution_organization_files (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        action_execution_id INTEGER NOT NULL,
        organization_id INTEGER NOT NULL,
        file_id INTEGER NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (action_execution_id) REFERENCES action_executions(id) ON DELETE CASCADE,
        FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE,
        FOREIGN KEY (file_id) REFERENCES organization_reference_files(id) ON DELETE CASCADE,
        UNIQUE(action_execution_id, organization_id, file_id)
    );
    """
    
    cursor.execute(create_table_sql)
    
    # Создаем индексы для быстрого поиска
    # Индекс для поиска всех организаций и файлов для конкретного выполнения действия
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_aeof_action_execution 
        ON action_execution_organization_files(action_execution_id);
    """)
    
    # Индекс для поиска по организации
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_aeof_organization 
        ON action_execution_organization_files(organization_id);
    """)
    
    # Индекс для поиска по файлу
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_aeof_file 
        ON action_execution_organization_files(file_id);
    """)
    
    # Составной индекс для уникальности и быстрого поиска
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_aeof_composite 
        ON action_execution_organization_files(action_execution_id, organization_id);
    """)

    conn.commit()
    conn.close()
    print("Миграция 006 успешно применена: таблица 'action_execution_organization_files' создана.")
    print("Теперь у каждого выполнения действия могут быть свои организации и файлы.")
    return True

if __name__ == '__main__':
    success = apply_migration()
    if success:
        print("\nСледующие шаги:")
        print("1. Добавить методы в database_manager для работы с новой таблицей:")
        print("   - get_organization_files_for_action_execution(action_execution_id)")
        print("   - add_organization_file_to_action_execution(action_execution_id, org_id, file_id)")
        print("   - remove_organization_file_from_action_execution(link_id)")
        print("   - clear_organization_files_for_action_execution(action_execution_id)")
        print("2. Обновить ActionExecutionDetailsDialog.qml для отображения и выбора организаций/файлов")
        print("3. Обновить main.py для экспорта новых методов в QML")
    else:
        print("Миграция не была применена.")
