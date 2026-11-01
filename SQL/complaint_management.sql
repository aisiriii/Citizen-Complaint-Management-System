-- ============================================================
-- CITIZEN COMPLAINT MANAGEMENT SYSTEM
-- DBMS Mini Project | MySQL 8.x
-- Complete reference SQL script
--
-- IMPORTANT:
-- 1. This script does NOT DROP the database or existing tables.
-- 2. CREATE TABLE IF NOT EXISTS does not modify existing table definitions.
-- 3. Seed records use IDs in the 9900 range to avoid colliding with the
--    project's existing records (for example, Complaint_ID 430).
-- 4. UPDATE/DELETE demonstrations are wrapped in a transaction and rolled
--    back. The trigger demonstration is committed so its audit entries remain.
-- 5. Run on a fresh database for a clean DDL demonstration. For an existing
--    database, compare table definitions before running.
-- ============================================================

CREATE DATABASE IF NOT EXISTS complaintmanagement;
USE complaintmanagement;

-- ==================== 1. TABLE DEFINITIONS ====================

CREATE TABLE IF NOT EXISTS Department (
    Dept_ID INT PRIMARY KEY,
    Dname VARCHAR(100) NOT NULL,
    Location VARCHAR(100),
    Phone VARCHAR(15),
    CONSTRAINT uq_department_name UNIQUE (Dname)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Citizen (
    Citizen_ID INT PRIMARY KEY,
    Name VARCHAR(100) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Address VARCHAR(255),
    Email VARCHAR(150),
    CONSTRAINT uq_citizen_phone UNIQUE (Phone),
    CONSTRAINT uq_citizen_email UNIQUE (Email)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Asset (
    Asset_ID INT PRIMARY KEY,
    Install_date DATE,
    Asset_type VARCHAR(100) NOT NULL,
    Location VARCHAR(150) NOT NULL
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Worker (
    Worker_ID INT PRIMARY KEY,
    Fname VARCHAR(60) NOT NULL,
    Lname VARCHAR(60) NOT NULL,
    Phone VARCHAR(15) NOT NULL,
    Role VARCHAR(60),
    Dept_ID INT NOT NULL,
    Skills VARCHAR(255),
    CONSTRAINT uq_worker_phone UNIQUE (Phone),
    CONSTRAINT fk_worker_department FOREIGN KEY (Dept_ID)
        REFERENCES Department(Dept_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Complaint (
    Complaint_ID INT PRIMARY KEY,
    Description TEXT NOT NULL,
    Priority VARCHAR(20) NOT NULL,
    Status VARCHAR(30) NOT NULL,
    Date_filed DATE NOT NULL,
    Category VARCHAR(100) NOT NULL,
    Citizen_ID INT NOT NULL,
    Dept_ID INT NOT NULL,
    CONSTRAINT chk_complaint_priority
        CHECK (Priority IN ('Low', 'Medium', 'High', 'Critical')),
    CONSTRAINT chk_complaint_status
        CHECK (Status IN ('Open', 'In Progress', 'Resolved')),
    CONSTRAINT fk_complaint_citizen FOREIGN KEY (Citizen_ID)
        REFERENCES Citizen(Citizen_ID),
    CONSTRAINT fk_complaint_department FOREIGN KEY (Dept_ID)
        REFERENCES Department(Dept_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Complaint_Asset (
    Complaint_ID INT NOT NULL,
    Asset_ID INT NOT NULL,
    PRIMARY KEY (Complaint_ID, Asset_ID),
    CONSTRAINT fk_complaint_asset_complaint FOREIGN KEY (Complaint_ID)
        REFERENCES Complaint(Complaint_ID),
    CONSTRAINT fk_complaint_asset_asset FOREIGN KEY (Asset_ID)
        REFERENCES Asset(Asset_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Complaint_Worker (
    Complaint_ID INT NOT NULL,
    Worker_ID INT NOT NULL,
    Assigned_date DATE NOT NULL,
    PRIMARY KEY (Complaint_ID, Worker_ID, Assigned_date),
    CONSTRAINT fk_complaint_worker_complaint FOREIGN KEY (Complaint_ID)
        REFERENCES Complaint(Complaint_ID),
    CONSTRAINT fk_complaint_worker_worker FOREIGN KEY (Worker_ID)
        REFERENCES Worker(Worker_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Resolution (
    Resolution_ID INT PRIMARY KEY,
    Resolution_date DATE NOT NULL,
    Notes TEXT,
    SLA_status VARCHAR(30),
    Complaint_ID INT NOT NULL,
    CONSTRAINT uq_resolution_complaint UNIQUE (Complaint_ID),
    CONSTRAINT fk_resolution_complaint FOREIGN KEY (Complaint_ID)
        REFERENCES Complaint(Complaint_ID)
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS Complaint_Status_Audit (
    Audit_ID INT AUTO_INCREMENT PRIMARY KEY,
    Complaint_ID INT NOT NULL,
    Old_Status VARCHAR(30),
    New_Status VARCHAR(30) NOT NULL,
    Changed_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_audit_complaint FOREIGN KEY (Complaint_ID)
        REFERENCES Complaint(Complaint_ID)
) ENGINE=InnoDB;

-- ==================== 2. SAMPLE DATA ====================
-- INSERT IGNORE preserves existing rows with the same keys/unique values.

INSERT IGNORE INTO Department (Dept_ID, Dname, Location, Phone) VALUES
(9901, 'Road Maintenance Demo', 'Central Zone', '9900009901'),
(9902, 'Water Supply Demo', 'North Zone', '9900009902');

INSERT IGNORE INTO Citizen (Citizen_ID, Name, Phone, Address, Email) VALUES
(9901, 'Demo Citizen One', '9900019901', 'Central Zone', 'demo9901@example.com'),
(9902, 'Demo Citizen Two', '9900019902', 'North Zone', 'demo9902@example.com');

INSERT IGNORE INTO Asset (Asset_ID, Install_date, Asset_type, Location) VALUES
(9901, '2024-01-15', 'Street Light', 'Central Zone'),
(9902, '2023-06-10', 'Water Pipeline', 'North Zone');

INSERT IGNORE INTO Worker (Worker_ID, Fname, Lname, Phone, Role, Dept_ID, Skills) VALUES
(9901, 'Demo', 'WorkerOne', '9900029901', 'Technician', 9901, 'Road repair'),
(9902, 'Demo', 'WorkerTwo', '9900029902', 'Technician', 9902, 'Pipeline repair');

INSERT IGNORE INTO Complaint
(Complaint_ID, Description, Priority, Status, Date_filed, Category, Citizen_ID, Dept_ID)
VALUES
(9901, 'Pothole near the central bus stop', 'High', 'Open', CURRENT_DATE, 'Roads', 9901, 9901),
(9902, 'Water leakage near the north park', 'Medium', 'In Progress', CURRENT_DATE, 'Water', 9902, 9902);

INSERT IGNORE INTO Complaint_Asset (Complaint_ID, Asset_ID) VALUES
(9901, 9901),
(9902, 9902);

INSERT IGNORE INTO Complaint_Worker (Complaint_ID, Worker_ID, Assigned_date) VALUES
(9901, 9901, CURRENT_DATE),
(9902, 9902, CURRENT_DATE);

-- ==================== 3. VIEW ====================

CREATE OR REPLACE VIEW Complaint_Details AS
SELECT
    c.Complaint_ID,
    c.Description,
    c.Priority,
    c.Status,
    c.Date_filed,
    c.Category,
    ci.Citizen_ID,
    ci.Name AS Citizen_Name,
    ci.Phone AS Citizen_Phone,
    d.Dept_ID,
    d.Dname AS Department_Name
FROM Complaint c
JOIN Citizen ci ON c.Citizen_ID = ci.Citizen_ID
JOIN Department d ON c.Dept_ID = d.Dept_ID;

-- ==================== 4. STORED PROCEDURE ====================

DROP PROCEDURE IF EXISTS GetComplaintsByStatus;
DELIMITER //
CREATE PROCEDURE GetComplaintsByStatus(IN p_status VARCHAR(30))
BEGIN
    SELECT Complaint_ID, Description, Priority, Status, Date_filed, Category
    FROM Complaint
    WHERE Status = p_status
    ORDER BY Date_filed DESC;
END //
DELIMITER ;

-- ==================== 5. USER-DEFINED FUNCTION ====================

DROP FUNCTION IF EXISTS GetCitizenComplaintCount;
DELIMITER //
CREATE FUNCTION GetCitizenComplaintCount(p_citizen_id INT)
RETURNS INT
DETERMINISTIC
READS SQL DATA
BEGIN
    DECLARE total_complaints INT DEFAULT 0;

    SELECT COUNT(*)
    INTO total_complaints
    FROM Complaint
    WHERE Citizen_ID = p_citizen_id;

    RETURN total_complaints;
END //
DELIMITER ;

-- ==================== 6. TRIGGER ====================
-- The trigger records every change to Complaint.Status.

DROP TRIGGER IF EXISTS After_Complaint_Status_Update;
DELIMITER //
CREATE TRIGGER After_Complaint_Status_Update
AFTER UPDATE ON Complaint
FOR EACH ROW
BEGIN
    IF OLD.Status <> NEW.Status THEN
        INSERT INTO Complaint_Status_Audit
            (Complaint_ID, Old_Status, New_Status, Changed_At)
        VALUES
            (NEW.Complaint_ID, OLD.Status, NEW.Status, CURRENT_TIMESTAMP);
    END IF;
END //
DELIMITER ;

-- ==================== 7. DML DEMONSTRATIONS ====================
-- Safe UPDATE and DELETE examples: changes are rolled back at the end.

START TRANSACTION;

UPDATE Complaint
SET Priority = 'Critical'
WHERE Complaint_ID = 9901;

DELETE FROM Complaint_Asset
WHERE Complaint_ID = 9902 AND Asset_ID = 9902;

-- Show the temporary effect of the UPDATE and DELETE.
SELECT Complaint_ID, Priority, Status
FROM Complaint
WHERE Complaint_ID IN (9901, 9902);

ROLLBACK;

-- ==================== 8. TRIGGER DEMONSTRATION ====================
-- This changes only the dedicated demo complaint (9901).
-- The trigger writes an audit row. This change is committed intentionally.

UPDATE Complaint
SET Status = 'In Progress'
WHERE Complaint_ID = 9901 AND Status = 'Open';

UPDATE Complaint
SET Status = 'Resolved'
WHERE Complaint_ID = 9901 AND Status = 'In Progress';

-- ==================== 9. REQUIRED QUERIES ====================

-- 9.1 Simple SELECT with filtering and sorting
SELECT Complaint_ID, Description, Priority, Status
FROM Complaint
WHERE Priority IN ('High', 'Critical')
ORDER BY Date_filed DESC;

-- 9.2 INNER JOIN: complaints with citizen and department details
SELECT c.Complaint_ID, ci.Name AS Citizen_Name, d.Dname AS Department_Name,
       c.Description, c.Status
FROM Complaint c
INNER JOIN Citizen ci ON c.Citizen_ID = ci.Citizen_ID
INNER JOIN Department d ON c.Dept_ID = d.Dept_ID;

-- 9.3 LEFT JOIN: all complaints and any assigned workers
SELECT c.Complaint_ID, c.Description,
       CONCAT(w.Fname, ' ', w.Lname) AS Worker_Name
FROM Complaint c
LEFT JOIN Complaint_Worker cw ON c.Complaint_ID = cw.Complaint_ID
LEFT JOIN Worker w ON cw.Worker_ID = w.Worker_ID;

-- 9.4 Aggregate query with GROUP BY
SELECT Status, COUNT(*) AS Complaint_Count
FROM Complaint
GROUP BY Status;

-- 9.5 Aggregate query with HAVING
SELECT Dept_ID, COUNT(*) AS Total_Complaints
FROM Complaint
GROUP BY Dept_ID
HAVING COUNT(*) >= 1;

-- 9.6 Nested subquery: complaints filed by citizens who have filed
-- at least one complaint.
SELECT Complaint_ID, Description, Citizen_ID
FROM Complaint
WHERE Citizen_ID IN (
    SELECT Citizen_ID
    FROM Citizen
    WHERE Citizen_ID IN (SELECT DISTINCT Citizen_ID FROM Complaint)
);

-- 9.7 Correlated subquery: citizens with more than one complaint.
SELECT ci.Citizen_ID, ci.Name
FROM Citizen ci
WHERE (
    SELECT COUNT(*)
    FROM Complaint c
    WHERE c.Citizen_ID = ci.Citizen_ID
) > 1;

-- 9.8 Function call
SELECT Citizen_ID, Name,
       GetCitizenComplaintCount(Citizen_ID) AS Total_Complaints
FROM Citizen;

-- 9.9 View query
SELECT * FROM Complaint_Details
ORDER BY Date_filed DESC;

-- 9.10 Resolution details
SELECT c.Complaint_ID, c.Status, r.Resolution_date, r.Notes, r.SLA_status
FROM Complaint c
LEFT JOIN Resolution r ON c.Complaint_ID = r.Complaint_ID;

-- 9.11 Audit history
SELECT Audit_ID, Complaint_ID, Old_Status, New_Status, Changed_At
FROM Complaint_Status_Audit
ORDER BY Changed_At DESC;

-- ==================== 10. PROCEDURE CALL ====================

CALL GetComplaintsByStatus('Open');

-- ==================== 11. TRANSACTION DEMONSTRATION ====================
-- Demonstrate rollback without permanently changing project records.

START TRANSACTION;

UPDATE Complaint
SET Priority = 'Low'
WHERE Complaint_ID = 9902;

SELECT Complaint_ID, Priority
FROM Complaint
WHERE Complaint_ID = 9902;

ROLLBACK;

-- ==================== 12. TABLE / DATA VERIFICATION ====================

SHOW TABLES;

SELECT COUNT(*) AS Total_Complaints FROM Complaint;
SELECT COUNT(*) AS Total_Citizens FROM Citizen;
SELECT COUNT(*) AS Total_Workers FROM Worker;
SELECT * FROM Complaint_Details LIMIT 20;

-- End of Citizen Complaint Management System SQL script.
