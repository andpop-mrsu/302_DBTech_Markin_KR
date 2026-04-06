PRAGMA foreign_keys = ON;

-- Таблица мастеров

CREATE TABLE employees (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    hire_date DATE NOT NULL,
    fire_date DATE,
    salary_percent REAL NOT NULL DEFAULT 0.3 CHECK (salary_percent >= 0 AND salary_percent <= 1),
    is_active INTEGER NOT NULL DEFAULT 1 CHECK (is_active IN (0,1))
);

-- Категории автомобилей

CREATE TABLE car_categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL UNIQUE
);

-- Услуги

CREATE TABLE services (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    price REAL NOT NULL CHECK (price >= 0),
    category_id INTEGER NOT NULL,
    FOREIGN KEY (category_id) REFERENCES car_categories(id)
);

-- Специализация мастеров

CREATE TABLE employee_services (
    employee_id INTEGER,
    service_id INTEGER,
    PRIMARY KEY (employee_id, service_id),
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    FOREIGN KEY (service_id) REFERENCES services(id)
);

-- Предварительная запись

CREATE TABLE appointments (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    employee_id INTEGER NOT NULL,
    service_id INTEGER NOT NULL,
    appointment_datetime DATETIME NOT NULL,
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'completed', 'canceled')),
    FOREIGN KEY (employee_id) REFERENCES employees(id),
    FOREIGN KEY (service_id) REFERENCES services(id)
);

-- Выполненные работы

CREATE TABLE jobs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    appointment_id INTEGER UNIQUE,
    actual_start DATETIME,
    actual_end DATETIME,
    final_price REAL CHECK (final_price >= 0),
    FOREIGN KEY (appointment_id) REFERENCES appointments(id)
);

-- Тестовые данные

-- Категории авто
INSERT INTO car_categories (name) VALUES
('Легковые'),
('Грузовые');

-- Мастера
INSERT INTO employees (full_name, hire_date, salary_percent) VALUES
('Иванов Иван', '2022-01-10', 0.3),
('Петров Петр', '2023-03-15', 0.35);

-- Услуги
INSERT INTO services (name, duration_minutes, price, category_id) VALUES
('Замена масла', 60, 50, 1),
('Диагностика двигателя', 90, 80, 1),
('Ремонт подвески', 120, 120, 2);

-- Специализации
INSERT INTO employee_services VALUES
(1, 1),
(1, 2),
(2, 2),
(2, 3);

-- Записи
INSERT INTO appointments (employee_id, service_id, appointment_datetime) VALUES
(1, 1, '2026-04-10 10:00'),
(2, 3, '2026-04-11 12:00');

-- Выполненные работы
INSERT INTO jobs (appointment_id, actual_start, actual_end, final_price) VALUES
(1, '2026-04-10 10:00', '2026-04-10 11:00', 50);