#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Утилита для генерации SQL-скрипта db_init.sql
Создаёт таблицы и INSERT-запросы из исходных файлов dataset
"""

import csv
import os
import re
from pathlib import Path

# Конфигурация
DATASET_DIR = Path('../dataset')  # Путь к данным (родительская директория)
OUTPUT_SQL = 'db_init.sql'
DB_NAME = 'movies_rating.db'

def escape_sql_string(s):
    """Экранирование строк для SQL"""
    if s is None:
        return 'NULL'
    # Заменяем одинарные кавычки на двойные
    s = str(s).replace("'", "''")
    return f"'{s}'"

def read_csv_file(filename, delimiter=','):
    """Чтение CSV файла"""
    filepath = DATASET_DIR / filename
    if not filepath.exists():
        print(f"Предупреждение: файл {filename} не найден в {filepath}")
        return []
    
    with open(filepath, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f, delimiter=delimiter)
        return list(reader)

def read_txt_file(filename, delimiter='|'):
    """Чтение текстового файла с разделителем"""
    filepath = DATASET_DIR / filename
    if not filepath.exists():
        print(f"Предупреждение: файл {filename} не найден в {filepath}")
        return []
    
    data = []
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        if not lines:
            return []
        
        for line in lines:
            line = line.strip()
            if not line:
                continue
            fields = line.split(delimiter)
            data.append(fields)
    return data

def parse_movie_title(title):
    """Извлечение года и чистого названия фильма"""
    # Ищем год в скобках в конце строки: "Title (1995)"
    year_match = re.search(r'\((\d{4})\)\s*$', title)
    if year_match:
        year = year_match.group(1)
        # Убираем год из названия
        clean_title = re.sub(r'\s*\(\d{4}\)\s*$', '', title)
        return clean_title, year
    return title, None

def generate_sql():
    """Генерация SQL-скрипта"""
    sql_lines = []
    
    # Удаление существующих таблиц
    sql_lines.append("-- Удаление существующих таблиц")
    sql_lines.append("DROP TABLE IF EXISTS ratings;")
    sql_lines.append("DROP TABLE IF EXISTS tags;")
    sql_lines.append("DROP TABLE IF EXISTS users;")
    sql_lines.append("DROP TABLE IF EXISTS movies;")
    sql_lines.append("")
    
    # Создание таблицы movies
    sql_lines.append("-- Создание таблицы movies")
    sql_lines.append("""CREATE TABLE movies (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    year INTEGER,
    genres TEXT
);""")
    sql_lines.append("")
    
    # Создание таблицы users
    sql_lines.append("-- Создание таблицы users")
    sql_lines.append("""CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL,
    email TEXT,
    gender TEXT,
    register_date TEXT,
    occupation TEXT
);""")
    sql_lines.append("")
    
    # Создание таблицы ratings
    sql_lines.append("-- Создание таблицы ratings")
    sql_lines.append("""CREATE TABLE ratings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    rating REAL NOT NULL,
    timestamp INTEGER NOT NULL
);""")
    sql_lines.append("")
    
    # Создание таблицы tags
    sql_lines.append("-- Создание таблицы tags")
    sql_lines.append("""CREATE TABLE tags (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    movie_id INTEGER NOT NULL,
    tag TEXT NOT NULL,
    timestamp INTEGER NOT NULL
);""")
    sql_lines.append("")
    
    # Загрузка данных в movies
    sql_lines.append("-- Загрузка данных в movies")
    movies_data = read_csv_file('movies.csv')
    if movies_data:
        for row in movies_data:
            movie_id = row.get('movieId', row.get('id', 'NULL'))
            title_full = row.get('title', '')
            genres = escape_sql_string(row.get('genres', ''))
            
            # Парсим название и год
            clean_title, year = parse_movie_title(title_full)
            title = escape_sql_string(clean_title)
            year_val = year if year else 'NULL'
            
            sql_lines.append(f"INSERT INTO movies (id, title, year, genres) VALUES ({movie_id}, {title}, {year_val}, {genres});")
        print(f"Загружено фильмов: {len(movies_data)}")
    sql_lines.append("")
    
    # Загрузка данных в users
    sql_lines.append("-- Загрузка данных в users")
    users_data = read_txt_file('users.txt', delimiter='|')
    if users_data:
        for fields in users_data:
            if len(fields) >= 6:
                user_id = fields[0]
                name = escape_sql_string(fields[1])
                email = escape_sql_string(fields[2])
                gender = escape_sql_string(fields[3])
                register_date = escape_sql_string(fields[4])
                occupation = escape_sql_string(fields[5])
                sql_lines.append(f"INSERT INTO users (id, name, email, gender, register_date, occupation) VALUES ({user_id}, {name}, {email}, {gender}, {register_date}, {occupation});")
        print(f"Загружено пользователей: {len(users_data)}")
    sql_lines.append("")
    
    # Загрузка данных в ratings
    sql_lines.append("-- Загрузка данных в ratings")
    ratings_data = read_csv_file('ratings.csv')
    if ratings_data:
        for row in ratings_data:
            user_id = row.get('userId', row.get('user_id', 'NULL'))
            movie_id = row.get('movieId', row.get('movie_id', 'NULL'))
            rating = row.get('rating', 'NULL')
            timestamp = row.get('timestamp', 'NULL')
            sql_lines.append(f"INSERT INTO ratings (user_id, movie_id, rating, timestamp) VALUES ({user_id}, {movie_id}, {rating}, {timestamp});")
        print(f"Загружено рейтингов: {len(ratings_data)}")
    sql_lines.append("")
    
    # Загрузка данных в tags
    sql_lines.append("-- Загрузка данных в tags")
    tags_data = read_csv_file('tags.csv')
    if tags_data:
        for row in tags_data:
            user_id = row.get('userId', row.get('user_id', 'NULL'))
            movie_id = row.get('movieId', row.get('movie_id', 'NULL'))
            tag = escape_sql_string(row.get('tag', ''))
            timestamp = row.get('timestamp', 'NULL')
            sql_lines.append(f"INSERT INTO tags (user_id, movie_id, tag, timestamp) VALUES ({user_id}, {movie_id}, {tag}, {timestamp});")
        print(f"Загружено тегов: {len(tags_data)}")
    sql_lines.append("")
    
    # Запись SQL-скрипта
    with open(OUTPUT_SQL, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sql_lines))
    
    print(f"\nSQL-скрипт сгенерирован: {OUTPUT_SQL}")
    print(f"Всего строк SQL: {len(sql_lines)}")

if __name__ == '__main__':
    generate_sql()