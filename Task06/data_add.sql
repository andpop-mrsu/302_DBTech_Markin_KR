BEGIN TRANSACTION;


-- Добавление 5 пользователей


INSERT INTO users (name, email, gender_id, occupation_id, register_date)
VALUES 
('Лукьянов Роман Александрович', 'lukyanov.ra@gmail.com',
 (SELECT id FROM genders WHERE name='male'),
 (SELECT id FROM occupations WHERE name='student'),
 CURRENT_TIMESTAMP),

('Маркин Константин Романович', 'markin.kr@gmail.com',
 (SELECT id FROM genders WHERE name='male'),
 (SELECT id FROM occupations WHERE name='student'),
 CURRENT_TIMESTAMP),

('Романов Дмитрий Алексеевич', 'romanov.da@gmail.com',
 (SELECT id FROM genders WHERE name='male'),
 (SELECT id FROM occupations WHERE name='student'),
 CURRENT_TIMESTAMP),

('Соснина Ирина Васильевна', 'sosnina.iv@gmail.com',
 (SELECT id FROM genders WHERE name='female'),
 (SELECT id FROM occupations WHERE name='educator'),
 CURRENT_TIMESTAMP),

('Тиосса Максим Николаевич', 'tiossa.mn@gmail.com',
 (SELECT id FROM genders WHERE name='male'),
 (SELECT id FROM occupations WHERE name='programmer'),
 CURRENT_TIMESTAMP);




-- Добавление фильмов


INSERT INTO movies (title, year)
VALUES 
('Грань будущего', 2014),
('Одержимость', 2014),
('Паразиты', 2019);




-- Связь фильмов с жанрами


-- Грань будущего
INSERT INTO movie_genres (movie_id, genre_id)
VALUES
((SELECT id FROM movies WHERE title='Грань будущего'),
 (SELECT id FROM genres WHERE name='Action')),
((SELECT id FROM movies WHERE title='Грань будущего'),
 (SELECT id FROM genres WHERE name='Sci-Fi'));

-- Одержимость
INSERT INTO movie_genres (movie_id, genre_id)
VALUES
((SELECT id FROM movies WHERE title='Одержимость'),
 (SELECT id FROM genres WHERE name='Drama'));

-- Паразиты
INSERT INTO movie_genres (movie_id, genre_id)
VALUES
((SELECT id FROM movies WHERE title='Паразиты'),
 (SELECT id FROM genres WHERE name='Drama')),
((SELECT id FROM movies WHERE title='Паразиты'),
 (SELECT id FROM genres WHERE name='Thriller'));



INSERT INTO ratings (user_id, movie_id, rating, timestamp)
VALUES
(
 (SELECT id FROM users WHERE email='lukyanov.ra@gmail.com'),
 (SELECT id FROM movies WHERE title='Грань будущего'),
 4.5,
 strftime('%s','now')
),

(
 (SELECT id FROM users WHERE email='lukyanov.ra@gmail.com'),
 (SELECT id FROM movies WHERE title='Одержимость'),
 5.0,
 strftime('%s','now')
),

(
 (SELECT id FROM users WHERE email='lukyanov.ra@gmail.com'),
 (SELECT id FROM movies WHERE title='Паразиты'),
 4.8,
 strftime('%s','now')
);

COMMIT;