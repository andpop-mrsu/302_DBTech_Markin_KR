@echo off
chcp 65001 >nul

echo "Инициализация базы данных..."
sqlite3 movies_rating.db < db_init.sql

echo "1. Список фильмов с хотя бы одной оценкой..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT DISTINCT m.title, m.year FROM movies m JOIN ratings r ON m.id = r.movie_id ORDER BY m.year, m.title LIMIT 10;"
echo.

echo "2. Пользователи, фамилии которых начинаются на 'A'..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT id, name, email, register_date FROM users WHERE SUBSTR(name, INSTR(name, ' ') + 1) LIKE 'A%%' ORDER BY register_date LIMIT 5;"
echo.

echo "3. Рейтинги в читаемом формате..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT u.name AS expert_name, m.title AS movie_title, m.year, r.rating, strftime('%%Y-%%m-%%d', datetime(r.timestamp, 'unixepoch')) AS rating_date FROM ratings r JOIN users u ON r.user_id = u.id JOIN movies m ON r.movie_id = m.id ORDER BY u.name, m.title, r.rating LIMIT 50;"
echo.

echo "4. Фильмы с тегами..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT m.title, m.year, t.tag FROM movies m JOIN tags t ON m.id = t.movie_id ORDER BY m.year, m.title, t.tag LIMIT 40;"
echo.

echo "5. Самые свежие фильмы..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT title, year FROM movies WHERE year = (SELECT MAX(year) FROM movies) ORDER BY year, title;"
echo.

echo "6. Комедии после 2000 года, понравившиеся мужчинам..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT m.title, m.year, COUNT(r.rating) AS likes_count FROM movies m JOIN ratings r ON m.id = r.movie_id JOIN users u ON u.id = r.user_id WHERE LOWER(m.genres) LIKE '%%comedy%%' AND CAST(m.year AS INTEGER) > 2000 AND u.gender = 'male' AND r.rating >= 4.5 GROUP BY m.title, m.year ORDER BY CAST(m.year AS INTEGER) DESC, m.title LIMIT 20;"
echo.

echo "7. Анализ профессий пользователей..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT occupation, COUNT(*) AS user_count FROM users GROUP BY occupation ORDER BY user_count DESC;"
echo.

echo "7a. Самая распространённая профессия..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT occupation, COUNT(*) AS user_count FROM users GROUP BY occupation ORDER BY user_count DESC LIMIT 1;"
echo.

echo "7b. Самая редкая профессия..."
echo "--------------------------------------------------"
sqlite3 movies_rating.db -box "SELECT occupation, COUNT(*) AS user_count FROM users GROUP BY occupation ORDER BY user_count ASC LIMIT 1;"
echo.

echo "Завершено. База данных создана и проанализирована."