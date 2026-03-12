#!/bin/bash
chcp 65001

sqlite3 movies_rating.db < db_init.sql

echo ""
echo "1. Для каждого фильма вывести название, год и средний рейтинг с ранжированием (топ 10):"
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
WITH movie_avg AS (
    SELECT 
        m.id, 
        m.title, 
        m.year, 
        AVG(r.rating) AS avg_rating,
        COUNT(r.rating) AS rating_count
    FROM movies m
    LEFT JOIN ratings r ON m.id = r.movie_id
    GROUP BY m.id
    HAVING COUNT(r.rating) >= 5  -- Фильмы с минимум 5 оценками
), 
ranked AS (
    SELECT 
        title, 
        year, 
        ROUND(avg_rating, 2) AS avg_rating,
        RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating
    FROM movie_avg
)
SELECT 
    title, 
    year, 
    avg_rating, 
    rank_by_avg_rating
FROM ranked
WHERE rank_by_avg_rating <= 10
ORDER BY rank_by_avg_rating;"

echo ""
echo "2. Выделить все жанры рекурсивно и рассчитать средний рейтинг с ранжированием:"
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
WITH RECURSIVE genre_split(id, genre, rest) AS (
    SELECT 
        id,
        CASE 
            WHEN instr(genres, '|') = 0 THEN genres 
            ELSE substr(genres, 1, instr(genres, '|') - 1) 
        END,
        CASE 
            WHEN instr(genres, '|') = 0 THEN '' 
            ELSE substr(genres, instr(genres, '|') + 1) 
        END
    FROM movies
    UNION ALL
    SELECT 
        id,
        CASE 
            WHEN instr(rest, '|') = 0 THEN rest 
            ELSE substr(rest, 1, instr(rest, '|') - 1) 
        END,
        CASE 
            WHEN instr(rest, '|') = 0 THEN '' 
            ELSE substr(rest, instr(rest, '|') + 1) 
        END
    FROM genre_split
    WHERE rest <> ''
), 
genre_avg AS (
    SELECT 
        gs.genre, 
        AVG(r.rating) AS avg_rating,
        COUNT(r.rating) AS rating_count
    FROM genre_split gs
    LEFT JOIN ratings r ON gs.id = r.movie_id
    GROUP BY gs.genre
    HAVING COUNT(r.rating) >= 10  -- Жанры с минимум 10 оценками
)
SELECT 
    genre, 
    ROUND(avg_rating, 2) AS avg_rating,
    RANK() OVER (ORDER BY avg_rating DESC) AS rank_by_avg_rating
FROM genre_avg
ORDER BY rank_by_avg_rating;"

echo ""
echo "3. Подсчитать количество фильмов в каждом жанре:"
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
WITH RECURSIVE genre_split(id, genre, rest) AS (
    SELECT 
        id,
        CASE 
            WHEN instr(genres, '|') = 0 THEN genres 
            ELSE substr(genres, 1, instr(genres, '|') - 1) 
        END,
        CASE 
            WHEN instr(genres, '|') = 0 THEN '' 
            ELSE substr(genres, instr(genres, '|') + 1) 
        END
    FROM movies
    UNION ALL
    SELECT 
        id,
        CASE 
            WHEN instr(rest, '|') = 0 THEN rest 
            ELSE substr(rest, 1, instr(rest, '|') - 1) 
        END,
        CASE 
            WHEN instr(rest, '|') = 0 THEN '' 
            ELSE substr(rest, instr(rest, '|') + 1) 
        END
    FROM genre_split
    WHERE rest <> ''
)
SELECT 
    genre, 
    COUNT(DISTINCT id) AS movie_count
FROM genre_split
GROUP BY genre
ORDER BY movie_count DESC;"

echo ""
echo "4. Найти жанры, в которых чаще всего оставляют теги (вывести genre, tag_count и долю в процентах):"
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
WITH RECURSIVE genre_split(id, genre, rest) AS (
    SELECT 
        id,
        CASE 
            WHEN instr(genres, '|') = 0 THEN genres 
            ELSE substr(genres, 1, instr(genres, '|') - 1) 
        END,
        CASE 
            WHEN instr(genres, '|') = 0 THEN '' 
            ELSE substr(genres, instr(genres, '|') + 1) 
        END
    FROM movies
    UNION ALL
    SELECT 
        id,
        CASE 
            WHEN instr(rest, '|') = 0 THEN rest 
            ELSE substr(rest, 1, instr(rest, '|') - 1) 
        END,
        CASE 
            WHEN instr(rest, '|') = 0 THEN '' 
            ELSE substr(rest, instr(rest, '|') + 1) 
        END
    FROM genre_split
    WHERE rest <> ''
), 
genre_tags AS (
    SELECT 
        gs.genre, 
        COUNT(t.tag) AS tag_count
    FROM genre_split gs
    LEFT JOIN tags t ON gs.id = t.movie_id
    GROUP BY gs.genre
), 
total AS (
    SELECT SUM(tag_count) AS total_tags FROM genre_tags
)
SELECT 
    gt.genre, 
    gt.tag_count,
    CASE 
        WHEN total.total_tags = 0 THEN 0 
        ELSE ROUND(100.0 * gt.tag_count / total.total_tags, 2) 
    END AS tag_share
FROM genre_tags gt, total
ORDER BY gt.tag_count DESC;"

echo ""
echo "5. Для каждого пользователя: количество оценок, средний рейтинг, даты первой и последней оценки (топ 10 по количеству):"
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
SELECT 
    u.id AS user_id,
    COUNT(r.rating) AS rating_count,
    ROUND(AVG(r.rating), 2) AS avg_rating,
    datetime(MIN(r.timestamp), 'unixepoch') AS first_rating_date,
    datetime(MAX(r.timestamp), 'unixepoch') AS last_rating_date
FROM users u
LEFT JOIN ratings r ON u.id = r.user_id
GROUP BY u.id
HAVING COUNT(r.rating) > 0
ORDER BY rating_count DESC
LIMIT 10;"

echo ""
echo "6. Сегментация пользователей по поведению (оценщики, комментаторы, активные, пассивные):"
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
WITH user_ratings AS (
    SELECT 
        user_id, 
        COUNT(*) AS cnt_ratings 
    FROM ratings 
    GROUP BY user_id
), 
user_tags AS (
    SELECT 
        user_id, 
        COUNT(*) AS cnt_tags 
    FROM tags 
    GROUP BY user_id
)
SELECT 
    u.id AS user_id,
    COALESCE(ur.cnt_ratings, 0) AS rating_count,
    COALESCE(ut.cnt_tags, 0) AS tag_count,
    CASE
        WHEN COALESCE(ut.cnt_tags, 0) > COALESCE(ur.cnt_ratings, 0) THEN 'Комментаторы'
        WHEN COALESCE(ur.cnt_ratings, 0) > COALESCE(ut.cnt_tags, 0) THEN 'Оценщики'
        WHEN COALESCE(ur.cnt_ratings, 0) >= 10 AND COALESCE(ut.cnt_tags, 0) >= 10 THEN 'Активные'
        WHEN COALESCE(ur.cnt_ratings, 0) < 5 AND COALESCE(ut.cnt_tags, 0) < 5 THEN 'Пассивные'
        ELSE 'Другие'
    END AS behavior
FROM users u
LEFT JOIN user_ratings ur ON u.id = ur.user_id
LEFT JOIN user_tags ut ON u.id = ut.user_id
ORDER BY rating_count DESC, tag_count DESC;"

echo ""
echo "7. Для каждого пользователя вывести имя и последний фильм, который он оценил:"
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "
WITH last_rating AS (
    SELECT 
        user_id, 
        movie_id, 
        MAX(timestamp) AS last_ts 
    FROM ratings 
    GROUP BY user_id
)
SELECT 
    u.id AS user_id, 
    u.name,
    m.title AS last_rated_movie_title,
    datetime(lr.last_ts, 'unixepoch') AS last_rating_timestamp
FROM users u
LEFT JOIN last_rating lr ON u.id = lr.user_id
LEFT JOIN movies m ON lr.movie_id = m.id
ORDER BY u.id;"