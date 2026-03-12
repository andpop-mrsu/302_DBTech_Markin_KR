#!/bin/bash
chcp 65001

# Инициализация базы данных
sqlite3 movies_rating.db < db_init.sql

echo "1. Найти все пары пользователей, оценивших один и тот же фильм..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH pairs AS (
    SELECT u1.name AS user1, u2.name AS user2, m.title AS movie_title
    FROM ratings r1
    JOIN ratings r2 ON r1.movie_id = r2.movie_id AND r1.user_id < r2.user_id
    JOIN users u1 ON r1.user_id = u1.id
    JOIN users u2 ON r2.user_id = u2.id
    JOIN movies m ON r1.movie_id = m.id
)
SELECT user1, user2, movie_title
FROM pairs
LIMIT 100;
"
echo " "

echo "2. 10 самых свежих оценок от разных пользователей..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT m.title AS movie_title, u.name AS user_name, r.rating,
       strftime('%Y-%m-%d', datetime(r.timestamp, 'unixepoch')) AS rating_date
FROM ratings r
JOIN users u ON r.user_id = u.id
JOIN movies m ON r.movie_id = m.id
GROUP BY r.user_id
ORDER BY r.timestamp DESC
LIMIT 10;
"
echo " "

echo "3. Фильмы с максимальным и минимальным средним рейтингом..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH avg_ratings AS (
    SELECT title, year, AVG(rating) AS avg_rating
    FROM movies m
    JOIN ratings r ON m.id = r.movie_id
    GROUP BY m.id
),
max_min AS (
    SELECT MAX(avg_rating) AS max_rating, MIN(avg_rating) AS min_rating FROM avg_ratings
)
SELECT title, year, avg_rating,
       CASE WHEN avg_rating >= 4.5 THEN 'Да' ELSE 'Нет' END AS 'Рекомендуем'
FROM avg_ratings, max_min
WHERE avg_rating = max_rating OR avg_rating = min_rating
ORDER BY year, title;
"
echo " "

echo "4. Оценки от женщин за 2010-2012 годы..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT COUNT(*) AS 'Количество оценок', ROUND(AVG(rating),2) AS 'Средняя оценка'
FROM ratings r
JOIN users u ON r.user_id = u.id
JOIN movies m ON r.movie_id = m.id
WHERE u.gender='female' AND strftime('%Y', datetime(r.timestamp, 'unixepoch')) BETWEEN '2010' AND '2012';
"
echo " "

echo "5. Рейтинг фильмов по средней оценке (первые 20)..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH ranked AS (
    SELECT title, year, AVG(rating) AS avg_rating,
           RANK() OVER (ORDER BY AVG(rating) DESC) AS rank_place
    FROM movies m
    JOIN ratings r ON m.id = r.movie_id
    GROUP BY m.id
)
SELECT title, year, ROUND(avg_rating,2) AS 'Средняя оценка', rank_place AS 'Место в рейтинге'
FROM ranked
ORDER BY year, title
LIMIT 20;
"
echo " "

echo "6. 10 последних зарегистрированных пользователей..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
SELECT SUBSTR(name, INSTR(name, ' ')+1) || ' ' || SUBSTR(name, 1, INSTR(name, ' ')-1) AS 'Фамилия Имя',
       register_date AS 'Дата регистрации'
FROM users
ORDER BY register_date DESC
LIMIT 10;
"
echo " "

echo "7. Таблица умножения (1-10) с помощью рекурсивного CTE..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE mult(x, y, val) AS (
    SELECT 1, 1, 1
    UNION ALL
    SELECT x, y+1, x*(y+1) FROM mult WHERE y<10
    UNION ALL
    SELECT x+1, 1, x+1 FROM mult WHERE y=10 AND x<10
)
SELECT x || 'x' || y || '=' || val AS multiplication
FROM mult
ORDER BY x, y;
"
echo " "

echo "8. Все жанры фильмов (рекурсивно)..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box -echo "
WITH RECURSIVE genre_split(title, genre, rest) AS (
    SELECT title,
           CASE WHEN INSTR(genres,'|')>0 THEN SUBSTR(genres,1,INSTR(genres,'|')-1)
                ELSE genres END,
           CASE WHEN INSTR(genres,'|')>0 THEN SUBSTR(genres,INSTR(genres,'|')+1) ELSE '' END
    FROM movies
    UNION ALL
    SELECT title,
           CASE WHEN INSTR(rest,'|')>0 THEN SUBSTR(rest,1,INSTR(rest,'|')-1)
                ELSE rest END,
           CASE WHEN INSTR(rest,'|')>0 THEN SUBSTR(rest,INSTR(rest,'|')+1) ELSE '' END
    FROM genre_split
    WHERE rest<>'' 
)
SELECT DISTINCT genre AS 'Жанр'
FROM genre_split
WHERE genre<>''
ORDER BY genre;
"
echo " "

echo "Задание выполнено!"