-- ============================================================
-- CITIZEN COMPLAINT MANAGEMENT SYSTEM | DBMS PROJECT
-- MySQL 8.x script
-- Re-runnable setup: CREATE TABLE IF NOT EXISTS + INSERT IGNORE.
-- Existing rows with matching unique/primary keys are preserved; duplicate
-- seed rows are skipped. UPDATE/DELETE and trigger demo statements below
-- intentionally demonstrate the requested DML and audit behaviour.
-- NOTE: CREATE TABLE IF NOT EXISTS does not alter a pre-existing
-- table definition. Use a fresh database for the full DDL setup.
-- ============================================================

CREATE DATABASE IF NOT EXISTS complaintmanagement;
USE complaintmanagement;

-- ==================== TABLE DEFINITIONS ====================

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