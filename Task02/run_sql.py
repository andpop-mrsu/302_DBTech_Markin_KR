#!/usr/bin/env python3
import sqlite3
import sys

# Читаем SQL-скрипт
with open('db_init.sql', 'r', encoding='utf-8') as f:
    sql_script = f.read()

# Подключаемся к базе и выполняем
conn = sqlite3.connect('movies_rating.db')
cursor = conn.cursor()
cursor.executescript(sql_script)
conn.commit()
conn.close()

print("База данных movies_rating.db успешно создана и заполнена")