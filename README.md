# 📚 Library Management System — SQL Database Engineering Project
### 6 Tables | 20 SQL Tasks | Stored Procedures | CTAS | Advanced Analytics

> **Designed and queried a 6-table relational database tracking 35 books, 12 members, and 11 employees across 5 branches — uncovering a 57.1% outstanding return rate and $220 rental revenue gap, with 2 automated stored procedures reducing manual book-status updates to zero.**

---

## 📌 Project Summary

This project implements a full Library Management System in MySQL from schema design through to business intelligence reporting. It covers database architecture, referential integrity enforcement, CRUD operations, CTAS workflows, and advanced SQL including window functions, stored procedures, and fine-calculation automation.

**Core business questions answered:**
- Which book categories generate the most rental revenue?
- Which branches are underperforming on returns?
- Which employees process the most transactions?
- Which members have overdue books — and how much do they owe?

---

## 🗂️ Database Schema

```
branch ──< employees >──< issued_status >──< books
                              │
                         return_status
                              │
                         members <──┘
```

| Table | Rows | Purpose |
|---|---|---|
| `branch` | 5 | Library locations + manager assignments |
| `employees` | 11 | Staff: Clerks, Assistants, Librarians, Managers |
| `members` | 12 | Registered library members |
| `books` | 35 | Catalog with rental price + availability status |
| `issued_status` | 35 | Book issue transactions |
| `return_status` | 18 | Return records + book quality tracking |

**ERD:** See `library_erd.png`

---

## 📊 Key Findings (All Data-Validated)

### Revenue Analysis

| Category | Issues | Total Income |
|---|---|---|
| Classic | 10 | **$59.00** ← highest |
| History | 7 | $49.50 |
| Fantasy | 4 | $28.50 |
| Dystopian | 4 | $25.50 |
| Fiction | 3 | $14.50 |
| **Total** | **35** | **$220.00** |

### Branch Performance

| Branch | Issues | Returned | Return Rate | Revenue |
|---|---|---|---|---|
| B001 (Main St) | 17 | 9 | 52.9% | **$111.50** |
| B005 (Maple St) | 9 | 3 | 33.3% | $50.00 |
| B004 (Pine St) | 4 | 3 | **75.0%** | $26.50 |
| B003 (Oak St) | 3 | 0 | 0.0% ⚠️ | $20.00 |
| B002 (Elm St) | 2 | 0 | 0.0% ⚠️ | $12.00 |

### Return & Overdue Status

- **Return rate: 42.9%** (15 of 35 books returned)
- **Outstanding: 20 books (57.1%)** not yet returned
- **Estimated fine revenue: $115.00** from overdue penalties ($0.50/day beyond 30 days)

### Top Employees by Transactions Processed

| Rank | Employee | Position | Branch | Books Processed |
|---|---|---|---|---|
| 1 | Laura Martinez | Manager | B005 | 6 |
| 1 | Michelle Ramirez | Assistant | B001 | 6 |
| 3 | Emily Davis | Assistant | B001 | 4 |

### Heavy Borrowers (Most Active Members)

| Member | Books Issued |
|---|---|
| Ivy Martinez (C109) | **7** |
| Grace Taylor (C107) | 6 |
| Jack Wilson (C110) | 6 |
| Eve Brown (C105) | 5 |

---

## 🛠️ SQL Skills Demonstrated

| Skill | Tasks |
|---|---|
| DDL — schema design with FK constraints | Setup |
| DML — INSERT, UPDATE, DELETE | Tasks 1–3 |
| SELECT with JOIN, GROUP BY, HAVING | Tasks 4–5, 7–10 |
| CTAS (Create Table As Select) | Tasks 6, 11, 15, 16, 20 |
| Multi-table JOINs (4–5 tables) | Tasks 13, 15, 17 |
| LEFT JOIN for NULL detection | Tasks 12, 13, 20 |
| Stored Procedures with IF/ELSE logic | Tasks 14, 19 |
| DATEDIFF + conditional fine calculation | Tasks 13, 20 |
| Window functions (SUM OVER) | BI-5 |
| Self-join (manager lookup) | Task 10 |
| Subqueries + IN clause | Task 16 |
| INDEX creation for performance | insert_queries2.sql |

---

## 📁 Repository Structure

```
├── app_library.sql              # Schema DDL — all 6 tables
├── insert_queries.sql           # Seed data inserts
├── insert_queries2.sql          # Additional inserts + ALTER TABLE
├── solutions_1.sql              # Tasks 1–12 (CRUD + Data Analysis)
├── lms_project_advanced_solution_2.sql  # Tasks 13–20 (Advanced SQL)
├── lms_complete_analysis.sql    # FULL consolidated script (all tasks + BI queries)
├── books.csv                    # 35 book records
├── branch.csv                   # 5 branch records
├── employees.csv                # 11 employee records
├── members.csv                  # 12 member records
├── issued_status.csv            # 35 issue transactions
├── return_status.csv            # 18 return records
├── library_erd.png              # Entity Relationship Diagram
└── README.md
```

---

## 🚀 How to Run

```sql
-- Step 1: Create & populate database
SOURCE app_library.sql;
SOURCE insert_queries.sql;
SOURCE insert_queries2.sql;

-- Step 2: Run all tasks in order
SOURCE lms_complete_analysis.sql;  -- All tasks + 5 BI queries
```

**Requirements:** MySQL 8.0+ (uses window functions, DELIMITER syntax)

---

## 🔑 Stored Procedures

### `issue_book(issued_id, member_id, isbn, emp_id)`
Checks availability → if 'yes': issues book + updates status to 'no'. If 'no': returns informational message. Prevents double-issuing.

```sql
CALL issue_book('IS155', 'C108', '978-0-553-29698-2', 'E104');
-- Output: "Book issued successfully: The Catcher in the Rye"
```

### `add_return_records(return_id, issued_id, book_quality)`
Logs return → updates book status back to 'yes' → records condition (Good/Damaged).

```sql
CALL add_return_records('RS138', 'IS135', 'Good');
-- Output: "Book returned successfully: Sapiens | Quality logged: Good"
```

---

## 📥 Key SQL Highlights

### Overdue Detection with Fine Calculation
```sql
SELECT
    m.member_name,
    bk.book_title,
    ist.issued_date,
    DATEDIFF(CURDATE(), ist.issued_date) - 30      AS days_overdue,
    (DATEDIFF(CURDATE(), ist.issued_date) - 30)
    * 0.50                                          AS fine_usd
FROM issued_status ist
JOIN members m       ON m.member_id  = ist.issued_member_id
JOIN books bk        ON bk.isbn      = ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
WHERE rs.return_date IS NULL
  AND DATEDIFF(CURDATE(), ist.issued_date) > 30;
```

### Branch Performance (Multi-table JOIN + Aggregation)
```sql
SELECT b.branch_id, COUNT(ist.issued_id) AS issued,
       COUNT(rs.return_id) AS returned,
       SUM(bk.rental_price) AS revenue
FROM issued_status ist
JOIN employees e ON e.emp_id = ist.issued_emp_id
JOIN branch b    ON b.branch_id = e.branch_id
LEFT JOIN return_status rs ON rs.issued_id = ist.issued_id
JOIN books bk    ON bk.isbn = ist.issued_book_isbn
GROUP BY b.branch_id;
```

---

## 👤 Author

**Neela Vinay** — Data Analyst | SQL Developer  
📧 [neelavinni9@gmail.com] | 🔗 [(https://www.linkedin.com/in/vinay-neela/)] | 💼 [Portfolio]

---
*Database: MySQL 8.0 | Intermediate–Advanced SQL | MIT License*
