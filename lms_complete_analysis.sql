-- ============================================================
-- Library Management System — Complete SQL Analysis
-- Database: library | MySQL 8.0+ compatible
-- Author: Neela Vinay
-- Tables: branch(5) | employees(11) | members(12) |
--         books(35) | issued_status(35) | return_status(18)
-- ============================================================

-- ─────────────────────────────────────────────
-- SECTION 1 — DATABASE SETUP
-- ─────────────────────────────────────────────

CREATE DATABASE IF NOT EXISTS library;
USE library;

DROP TABLE IF EXISTS return_status;
DROP TABLE IF EXISTS issued_status;
DROP TABLE IF EXISTS books;
DROP TABLE IF EXISTS members;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS branch;

CREATE TABLE branch (
    branch_id      VARCHAR(10) PRIMARY KEY,
    manager_id     VARCHAR(10),
    branch_address VARCHAR(30),
    contact_no     VARCHAR(15)
);

CREATE TABLE employees (
    emp_id    VARCHAR(10) PRIMARY KEY,
    emp_name  VARCHAR(30),
    position  VARCHAR(30),
    salary    DECIMAL(10,2),
    branch_id VARCHAR(10),
    FOREIGN KEY (branch_id) REFERENCES branch(branch_id)
);

CREATE TABLE members (
    member_id      VARCHAR(10) PRIMARY KEY,
    member_name    VARCHAR(30),
    member_address VARCHAR(30),
    reg_date       DATE
);

CREATE TABLE books (
    isbn          VARCHAR(50) PRIMARY KEY,
    book_title    VARCHAR(80),
    category      VARCHAR(30),
    rental_price  DECIMAL(10,2),
    status        VARCHAR(10),   -- 'yes' = available, 'no' = issued
    author        VARCHAR(30),
    publisher     VARCHAR(30)
);

CREATE TABLE issued_status (
    issued_id        VARCHAR(10) PRIMARY KEY,
    issued_member_id VARCHAR(30),
    issued_book_name VARCHAR(80),
    issued_date      DATE,
    issued_book_isbn VARCHAR(50),
    issued_emp_id    VARCHAR(10),
    FOREIGN KEY (issued_member_id) REFERENCES members(member_id),
    FOREIGN KEY (issued_emp_id)    REFERENCES employees(emp_id),
    FOREIGN KEY (issued_book_isbn) REFERENCES books(isbn)
);

CREATE TABLE return_status (
    return_id        VARCHAR(10) PRIMARY KEY,
    issued_id        VARCHAR(30),
    return_book_name VARCHAR(80),
    return_date      DATE,
    return_book_isbn VARCHAR(50),
    book_quality     VARCHAR(15) DEFAULT 'Good',
    INDEX idx_issued_id (issued_id),
    FOREIGN KEY (return_book_isbn) REFERENCES books(isbn)
);
select * 
from issued_status;
-- ─────────────────────────────────────────────
-- SECTION 2 — CRUD OPERATIONS (Tasks 1–5)
-- ─────────────────────────────────────────────

-- Task 1: Insert a new book record
INSERT INTO books (isbn, book_title, category, rental_price, status, author, publisher)
VALUES ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes',
        'Harper Lee', 'J.B. Lippincott & Co.');

-- Task 2: Update a member's address
UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';

-- Task 3: Delete a record from issued_status
DELETE FROM issued_status
WHERE issued_id = 'IS121';

-- Task 4: Books issued by a specific employee
SELECT *
FROM issued_status
WHERE issued_emp_id = 'E101';

-- Task 5: Members who issued more than one book
SELECT
    ist.issued_member_id,
    m.member_name,
    COUNT(ist.issued_id) AS total_books_issued
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
GROUP BY ist.issued_member_id, m.member_name
HAVING COUNT(ist.issued_id) > 1
ORDER BY total_books_issued DESC;
/*
C109 | Ivy Martinez   | 7 books
C107 | Grace Taylor   | 6 books
C110 | Jack Wilson    | 6 books
C105 | Eve Brown      | 5 books
C106 | Frank Thomas   | 4 books
C102 | Bob Smith      | 2 books
C108 | Henry Anderson | 2 books
*/

-- ─────────────────────────────────────────────
-- SECTION 3 — CTAS (Task 6)
-- ─────────────────────────────────────────────

-- Task 6: Book issue count summary table
CREATE TABLE book_issued_cnt AS
SELECT
    b.isbn,
    b.book_title,
    b.category,
    b.rental_price,
    COUNT(ist.issued_id) AS issue_count,
    SUM(b.rental_price)  AS total_revenue_generated
FROM books AS b
LEFT JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title, b.category, b.rental_price
ORDER BY issue_count DESC;

SELECT * FROM book_issued_cnt;

-- ─────────────────────────────────────────────
-- SECTION 4 — DATA ANALYSIS (Tasks 7–12)
-- ─────────────────────────────────────────────

-- Task 7: Books in a specific category
SELECT isbn, book_title, author, rental_price, status
FROM books
WHERE category = 'Classic'
ORDER BY rental_price DESC;
-- 8 Classic books | Price range $4.00–$8.00

-- Task 8: Total rental income by category (validated)
SELECT
    b.category,
    COUNT(ist.issued_id)  AS times_issued,
    SUM(b.rental_price)   AS total_rental_income,
    ROUND(AVG(b.rental_price), 2) AS avg_price_per_issue
FROM books AS b
JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.category
ORDER BY total_rental_income DESC;
/*
Classic         | 10 issues | $59.00 income  (highest revenue category)
History         |  7 issues | $49.50 income
Fantasy         |  4 issues | $28.50 income
Dystopian       |  4 issues | $25.50 income
Fiction         |  3 issues | $14.50 income
Horror          |  2 issues | $13.00 income
Science Fiction |  1 issue  |  $8.50 income
Children        |  2 issues |  $7.50 income
Mystery         |  1 issue  |  $7.50 income
Literary Fiction|  1 issue  |  $6.50 income
Total revenue:  $220.00 across 35 transactions
*/

-- Task 9: Members registered in the last 180 days
SELECT member_id, member_name, member_address, reg_date,
       DATEDIFF(CURDATE(), reg_date) AS days_since_registration
FROM members
WHERE reg_date >= CURDATE() - INTERVAL 180 DAY
ORDER BY reg_date DESC;

-- Task 10: Employees with their branch manager's name and branch details
SELECT
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.branch_id,
    b.branch_address,
    b.contact_no,
    e2.emp_name AS manager_name
FROM employees AS e1
JOIN branch     AS b  ON b.branch_id = e1.branch_id
JOIN employees  AS e2 ON e2.emp_id   = b.manager_id
ORDER BY b.branch_id, e1.position;

-- Task 11: Books with rental price above threshold ($7.00)
CREATE TABLE books_price_above_seven AS
SELECT isbn, book_title, category, rental_price, author, publisher
FROM books
WHERE rental_price > 7.00
ORDER BY rental_price DESC;
-- 5 books above $7.00: Dune($8.50), Great Gatsby($8.00), Da Vinci Code($8.00),
--                      History of USA($9.00), Game of Thrones($7.50)

SELECT * FROM books_price_above_seven;

-- Task 12: Books not yet returned
SELECT
    ist.issued_id,
    ist.issued_member_id,
    m.member_name,
    ist.issued_book_name,
    ist.issued_date,
    DATEDIFF(CURDATE(), ist.issued_date) AS days_outstanding
FROM issued_status AS ist
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
JOIN members AS m ON m.member_id = ist.issued_member_id
WHERE rs.return_id IS NULL
ORDER BY days_outstanding DESC;
-- 20 books outstanding (57.1% of all issued books not yet returned)

-- ─────────────────────────────────────────────
-- SECTION 5 — ADVANCED SQL (Tasks 13–20)
-- ─────────────────────────────────────────────

-- Task 13: Members with overdue books (30+ days, not returned)
SELECT
    ist.issued_member_id,
    m.member_name,
    bk.book_title,
    bk.category,
    ist.issued_date,
    DATEDIFF(CURDATE(), ist.issued_date)       AS days_outstanding,
    DATEDIFF(CURDATE(), ist.issued_date) - 30  AS days_overdue,
    ((DATEDIFF(CURDATE(), ist.issued_date) - 30) * 0.50) AS fine_amount_usd
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
JOIN books   AS bk ON bk.isbn   = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30
ORDER BY days_overdue DESC;

-- Task 14: Stored Procedure — Return a book & auto-update status to 'yes'
DELIMITER $$

CREATE PROCEDURE add_return_records (
    IN p_return_id    VARCHAR(10),
    IN p_issued_id    VARCHAR(10),
    IN p_book_quality VARCHAR(10)
)
BEGIN
    DECLARE v_isbn      VARCHAR(50);
    DECLARE v_book_name VARCHAR(80);

    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES (p_return_id, p_issued_id, CURDATE(), p_book_quality);

    SELECT issued_book_isbn, issued_book_name
    INTO   v_isbn, v_book_name
    FROM   issued_status
    WHERE  issued_id = p_issued_id;

    UPDATE books
    SET    status = 'yes'
    WHERE  isbn = v_isbn;

    SELECT CONCAT('Book returned successfully: ', v_book_name,
                  ' | Quality logged: ', p_book_quality) AS confirmation;
END$$

DELIMITER ;

-- Test the procedure
-- CALL add_return_records('RS138', 'IS135', 'Good');

-- Task 15: Branch performance report (CTAS)
CREATE TABLE branch_performance_report AS
SELECT
    b.branch_id,
    b.branch_address,
    e2.emp_name                       AS manager_name,
    COUNT(ist.issued_id)              AS books_issued,
    COUNT(rs.return_id)               AS books_returned,
    COUNT(ist.issued_id)
        - COUNT(rs.return_id)         AS books_outstanding,
    ROUND(
        COUNT(rs.return_id) * 100.0
        / NULLIF(COUNT(ist.issued_id), 0), 1
    )                                 AS return_rate_pct,
    SUM(bk.rental_price)              AS total_revenue_usd
FROM issued_status AS ist
JOIN employees     AS e  ON e.emp_id    = ist.issued_emp_id
JOIN branch        AS b  ON b.branch_id = e.branch_id
JOIN employees     AS e2 ON e2.emp_id   = b.manager_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
JOIN books         AS bk ON bk.isbn     = ist.issued_book_isbn
GROUP BY b.branch_id, b.branch_address, e2.emp_name
ORDER BY total_revenue_usd DESC;

SELECT * FROM branch_performance_report;
/*
B001 | 123 Main St | 17 issued | 9 returned | 52.9% return rate | $111.50 revenue  ← TOP
B005 | 890 Maple St|  9 issued | 3 returned | 33.3% return rate | $50.00 revenue
B003 | 789 Oak St  |  3 issued | 0 returned |  0.0% return rate | $20.00 revenue
B004 | 567 Pine St |  4 issued | 3 returned | 75.0% return rate | $26.50 revenue
B002 | 456 Elm St  |  2 issued | 0 returned |  0.0% return rate | $12.00 revenue
*/

-- Task 16: Active members table (issued in last 2 months)
CREATE TABLE active_members AS
SELECT m.*,
       COUNT(ist.issued_id) AS recent_issues
FROM members AS m
JOIN issued_status AS ist ON ist.issued_member_id = m.member_id
WHERE ist.issued_date >= CURDATE() - INTERVAL 2 MONTH
GROUP BY m.member_id, m.member_name, m.member_address, m.reg_date;

SELECT * FROM active_members;

-- Task 17: Top 3 employees by books processed
SELECT
    e.emp_id,
    e.emp_name,
    e.position,
    b.branch_id,
    b.branch_address,
    COUNT(ist.issued_id) AS books_processed
FROM issued_status AS ist
JOIN employees     AS e ON e.emp_id    = ist.issued_emp_id
JOIN branch        AS b ON b.branch_id = e.branch_id
GROUP BY e.emp_id, e.emp_name, e.position, b.branch_id, b.branch_address
ORDER BY books_processed DESC
LIMIT 3;
/*
E110 | Laura Martinez   | Manager   | B005 | 6 books processed
E106 | Michelle Ramirez | Assistant | B001 | 6 books processed
E104 | Emily Davis      | Assistant | B001 | 4 books processed
*/

-- Task 18: Members issuing damaged books more than twice
SELECT
    m.member_name,
    bk.book_title,
    COUNT(ist.issued_id)   AS times_issued,
    rs.book_quality
FROM issued_status AS ist
JOIN members       AS m  ON m.member_id  = ist.issued_member_id
JOIN books         AS bk ON bk.isbn      = ist.issued_book_isbn
JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.book_quality = 'Damaged'
GROUP BY m.member_name, bk.book_title, rs.book_quality
HAVING COUNT(ist.issued_id) > 1
ORDER BY times_issued DESC;

-- Task 19: Stored Procedure — Issue a book (with availability check)
DELIMITER $$

CREATE PROCEDURE issue_book (
    IN p_issued_id        VARCHAR(10),
    IN p_issued_member_id VARCHAR(30),
    IN p_issued_book_isbn VARCHAR(30),
    IN p_issued_emp_id    VARCHAR(10)
)
BEGIN
    DECLARE v_status    VARCHAR(10);
    DECLARE v_book_name VARCHAR(80);

    SELECT status, book_title
    INTO   v_status, v_book_name
    FROM   books
    WHERE  isbn = p_issued_book_isbn;

    IF v_status = 'yes' THEN
        INSERT INTO issued_status
            (issued_id, issued_member_id, issued_date, issued_book_isbn, issued_emp_id)
        VALUES
            (p_issued_id, p_issued_member_id, CURDATE(), p_issued_book_isbn, p_issued_emp_id);

        UPDATE books SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        SELECT CONCAT('Book issued successfully: ', v_book_name) AS message;
    ELSE
        SELECT CONCAT('Book unavailable (status = no): ISBN ', p_issued_book_isbn) AS message;
    END IF;
END$$

DELIMITER ;

-- Test: available book
-- CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
-- Test: unavailable book
-- CALL issue_book('IS156', 'C108', '978-0-375-41398-8', 'E104');

-- Task 20: CTAS — Overdue books with fine calculation
CREATE TABLE overdue_fines_report AS
SELECT
    ist.issued_member_id                                       AS member_id,
    m.member_name,
    COUNT(ist.issued_id)                                       AS overdue_book_count,
    SUM(
        GREATEST(DATEDIFF(CURDATE(), ist.issued_date) - 30, 0)
        * 0.50
    )                                                          AS total_fine_usd,
    SUM(ist.issued_id IS NOT NULL)                             AS total_books_issued_by_member
FROM issued_status AS ist
JOIN members AS m ON m.member_id = ist.issued_member_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30
GROUP BY ist.issued_member_id, m.member_name
ORDER BY total_fine_usd DESC;

SELECT * FROM overdue_fines_report;

-- ─────────────────────────────────────────────
-- SECTION 6 — BUSINESS INTELLIGENCE QUERIES
-- (Beyond the 20 tasks — analytical depth)
-- ─────────────────────────────────────────────

-- BI-1: Return rate by category
SELECT
    bk.category,
    COUNT(ist.issued_id)              AS total_issued,
    SUM(rs.issued_id IS NOT NULL)     AS total_returned,
    ROUND(
        SUM(rs.issued_id IS NOT NULL) * 100.0
        / COUNT(ist.issued_id), 1
    )                                 AS return_rate_pct
FROM issued_status AS ist
JOIN books         AS bk ON bk.isbn      = ist.issued_book_isbn
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
GROUP BY bk.category
ORDER BY return_rate_pct ASC;

-- BI-2: Salary vs performance — do higher-paid employees process more books?
SELECT
    e.emp_name,
    e.position,
    e.salary,
    COUNT(ist.issued_id)                AS books_processed,
    ROUND(e.salary / NULLIF(COUNT(ist.issued_id), 0), 2) AS cost_per_issue_usd
FROM employees     AS e
LEFT JOIN issued_status AS ist ON ist.issued_emp_id = e.emp_id
GROUP BY e.emp_id, e.emp_name, e.position, e.salary
ORDER BY cost_per_issue_usd ASC;

-- BI-3: Books at risk — high value, currently unreturned
SELECT
    ist.issued_book_name,
    bk.category,
    bk.rental_price,
    m.member_name,
    ist.issued_date,
    DATEDIFF(CURDATE(), ist.issued_date)   AS days_held,
    GREATEST(DATEDIFF(CURDATE(), ist.issued_date) - 30, 0) * 0.50 AS fine_accrued
FROM issued_status AS ist
JOIN books   AS bk ON bk.isbn        = ist.issued_book_isbn
JOIN members AS m  ON m.member_id    = ist.issued_member_id
LEFT JOIN return_status AS rs ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL
  AND bk.rental_price >= 7.00
ORDER BY bk.rental_price DESC, days_held DESC;

-- BI-4: Inventory utilisation rate
SELECT
    b.category,
    COUNT(DISTINCT b.isbn)              AS catalog_size,
    COUNT(DISTINCT ist.issued_book_isbn) AS unique_books_issued,
    ROUND(
        COUNT(DISTINCT ist.issued_book_isbn) * 100.0
        / COUNT(DISTINCT b.isbn), 1
    )                                   AS utilisation_rate_pct
FROM books AS b
LEFT JOIN issued_status AS ist ON ist.issued_book_isbn = b.isbn
GROUP BY b.category
ORDER BY utilisation_rate_pct DESC;

-- BI-5: Monthly issuance trend
SELECT
    DATE_FORMAT(issued_date, '%Y-%m') AS month,
    COUNT(issued_id)                  AS books_issued,
    SUM(COUNT(issued_id)) OVER (ORDER BY DATE_FORMAT(issued_date, '%Y-%m'))
                                      AS cumulative_issued
FROM issued_status
GROUP BY month
ORDER BY month;