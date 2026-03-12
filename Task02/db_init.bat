#!/bin/bash
# Скрипт инициализации базы данных movies_rating.db
# Запускает Python-утилиту и загружает SQL в SQLite

# Генерация SQL-скрипта
python3 make_db_init.py

# Выполнение SQL-скрипта в базе данных
sqlite3 movies_rating.db < db_init.sql

echo "База данных movies_rating.db успешно создана и заполнена"