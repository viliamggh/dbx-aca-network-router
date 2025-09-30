-- 1) Make a schema
CREATE SCHEMA IF NOT EXISTS demo;

-- 2) Create a tiny table (no citext, no triggers)
CREATE TABLE IF NOT EXISTS demo.employees (
  id         BIGSERIAL PRIMARY KEY,
  first_name TEXT NOT NULL,
  last_name  TEXT NOT NULL,
  email      TEXT NOT NULL UNIQUE,  -- simple unique text
  dept       TEXT NOT NULL,
  salary     NUMERIC(10,2) DEFAULT 0
);

-- 3) Insert a few rows (safe to re-run)
INSERT INTO demo.employees (first_name, last_name, email, dept, salary) VALUES
  ('Anna','Novak','anna.novak@example.com','HR',52000),
  ('Petr','Svoboda','petr.svoboda@example.com','Engineering',89000),
  ('Jana','Dvorak','jana.dvorak@example.com','Finance',74000)
ON CONFLICT (email) DO NOTHING;

-- 4) Quick check
-- SELECT * FROM demo.employees ORDER BY id;