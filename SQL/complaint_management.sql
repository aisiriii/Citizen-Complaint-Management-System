-- ============================================================
-- CITIZEN COMPLAINT MANAGEMENT SYSTEM
-- DBMS Mini Project | MySQL 8.x
-- SAFE SQL ENHANCEMENT SCRIPT FOR THE EXISTING DATABASE
--
-- IMPORTANT:
-- 1. Selects the existing complaintmanagement database.
-- 2. Does NOT create, drop, alter, or recreate any existing table.
-- 3. Does NOT delete or reinsert existing project records.
-- 4. Preserves the existing table structures:
--    * Complaint_Worker PK: (Complaint_ID, Worker_ID)
--    * Complaint_Status_Audit.Complaint_ID remains nullable; no FK added
--    * Complaint.Category remains nullable
--    * Complaint.Status continues to support Closed
--    * Resolution.Resolution_date remains nullable
-- 5. Uses only the reserved demo IDs 9901 and 9902.
-- 6. Recreates only the view, procedure, function, and trigger.
-- ============================================================

USE complaintmanagement;

-- ==================== 1. DEMO SUPPORTING DATA ====================
-- These INSERT IGNORE statements add only reserved demo rows.
-- They do not replace existing project records.

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

-- ==================== 2. VIEW ====================

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

-- ==================== 3. STORED PROCEDURE ====================

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

-- ==================== 4. USER-DEFINED FUNCTION ====================

DROP FUNCTION IF EXISTS GetCitizenComplaintCount;
DELIMITER //
CREATE FUNCTION GetCitizenComplaintCount(p_citizen_id INT)
RETURNS INT
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

-- ==================== 5. TRIGGER ====================
-- Uses the existing audit table as-is. No table or FK changes.

DROP TRIGGER IF EXISTS After_Complaint_Status_Update;
DELIMITER //
CREATE TRIGGER After_Complaint_Status_Update
AFTER UPDATE ON Complaint
FOR EACH ROW
BEGIN
    IF NOT (OLD.Status <=> NEW.Status) THEN
        INSERT INTO Complaint_Status_Audit
            (Complaint_ID, Old_Status, New_Status, Changed_At)
        VALUES
            (NEW.Complaint_ID, OLD.Status, NEW.Status, CURRENT_TIMESTAMP);
    END IF;
END //
DELIMITER ;

-- ==================== 6. SAFE DML DEMONSTRATION ====================
-- Transaction is rolled back; existing project records are not touched.

START TRANSACTION;

UPDATE Complaint
SET Priority = 'Critical'
WHERE Complaint_ID = 9901;

DELETE FROM Complaint_Asset
WHERE Complaint_ID = 9902 AND Asset_ID = 9902;

SELECT Complaint_ID, Priority, Status
FROM Complaint
WHERE Complaint_ID IN (9901, 9902);

ROLLBACK;

-- ==================== 7. TRIGGER DEMONSTRATION ====================
-- Changes only demo complaint 9901. The audit rows are intentionally kept.
-- Re-running is safe: status changes only when the current status matches.

UPDATE Complaint
SET Status = 'In Progress'
WHERE Complaint_ID = 9901 AND Status = 'Open';

UPDATE Complaint
SET Status = 'Resolved'
WHERE Complaint_ID = 9901 AND Status = 'In Progress';

-- ==================== 8. REQUIRED QUERIES ====================

-- 8.1 Simple SELECT with filtering and sorting
SELECT Complaint_ID, Description, Priority, Status
FROM Complaint
WHERE Priority IN ('High', 'Critical')
ORDER BY Date_filed DESC;

-- 8.2 INNER JOIN: complaints with citizen and department details
SELECT c.Complaint_ID, ci.Name AS Citizen_Name, d.Dname AS Department_Name,
       c.Description, c.Status
FROM Complaint c
INNER JOIN Citizen ci ON c.Citizen_ID = ci.Citizen_ID
INNER JOIN Department d ON c.Dept_ID = d.Dept_ID;

-- 8.3 LEFT JOIN: all complaints and any assigned workers
SELECT c.Complaint_ID, c.Description,
       CONCAT(w.Fname, ' ', w.Lname) AS Worker_Name
FROM Complaint c
LEFT JOIN Complaint_Worker cw ON c.Complaint_ID = cw.Complaint_ID
LEFT JOIN Worker w ON cw.Worker_ID = w.Worker_ID;

-- 8.4 Aggregate query with GROUP BY
SELECT Status, COUNT(*) AS Complaint_Count
FROM Complaint
GROUP BY Status;

-- 8.5 Aggregate query with HAVING
SELECT Dept_ID, COUNT(*) AS Total_Complaints
FROM Complaint
GROUP BY Dept_ID
HAVING COUNT(*) >= 1;

-- 8.6 Nested subquery
SELECT Complaint_ID, Description, Citizen_ID
FROM Complaint
WHERE Citizen_ID IN (
    SELECT Citizen_ID
    FROM Citizen
    WHERE Citizen_ID IN (SELECT DISTINCT Citizen_ID FROM Complaint)
);

-- 8.7 Correlated subquery: citizens with more than one complaint
SELECT ci.Citizen_ID, ci.Name
FROM Citizen ci
WHERE (
    SELECT COUNT(*)
    FROM Complaint c
    WHERE c.Citizen_ID = ci.Citizen_ID
) > 1;

-- 8.8 Function call
SELECT Citizen_ID, Name,
       GetCitizenComplaintCount(Citizen_ID) AS Total_Complaints
FROM Citizen;

-- 8.9 View query
SELECT * FROM Complaint_Details
ORDER BY Date_filed DESC;

-- 8.10 Resolution details
SELECT c.Complaint_ID, c.Status, r.Resolution_date, r.Notes, r.SLA_status
FROM Complaint c
LEFT JOIN Resolution r ON c.Complaint_ID = r.Complaint_ID;

-- 8.11 Audit history
SELECT Audit_ID, Complaint_ID, Old_Status, New_Status, Changed_At
FROM Complaint_Status_Audit
ORDER BY Changed_At DESC;

-- ==================== 9. PROCEDURE CALL ====================

CALL GetComplaintsByStatus('Open');

-- ==================== 10. TRANSACTION DEMONSTRATION ====================
START TRANSACTION;

UPDATE Complaint
SET Priority = 'Low'
WHERE Complaint_ID = 9902;

SELECT Complaint_ID, Priority
FROM Complaint
WHERE Complaint_ID = 9902;

ROLLBACK;

-- ==================== 11. VERIFICATION ====================

SHOW TABLES;

SELECT COUNT(*) AS Total_Complaints FROM Complaint;
SELECT COUNT(*) AS Total_Resolutions FROM Resolution;
SELECT COUNT(*) AS Total_Audit_Records FROM Complaint_Status_Audit;
SELECT * FROM Complaint_Details LIMIT 20;

-- End of safe enhancement script.

START TRANSACTION;

UPDATE Complaint
SET Priority = 'High'
WHERE Complaint_ID = 9902;

COMMIT;

SELECT Complaint_ID, Priority
FROM Complaint
WHERE Complaint_ID = 9902;