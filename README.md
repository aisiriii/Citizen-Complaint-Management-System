# Citizen Complaint Management System

A DBMS Mini Project built using **Python, Streamlit, and MySQL** to manage citizen complaints efficiently. The system allows users to register complaints, track their status, assign workers, record resolutions, and monitor complaint statistics through a simple web-based interface.

## Problem Statement

Traditional complaint management systems often rely on manual processes, making it difficult to register complaints, track their progress, assign responsible workers, and maintain resolution records.

The **Citizen Complaint Management System** aims to simplify this process by providing a centralized database-driven application where complaints can be registered, managed, assigned, and resolved systematically.

## Objectives

- Provide a centralized platform for registering citizen complaints.
- Maintain citizen, department, worker, and complaint information.
- Track complaint status and priority.
- Assign workers to complaints.
- Record complaint resolutions.
- Generate useful statistics and reports.

## Technologies Used

| Technology | Purpose |
|---|---|
| Python | Application logic and backend processing |
| Streamlit | Web-based user interface |
| MySQL | Relational database management |
| MySQL Connector | Connecting Python with MySQL |
| Pandas | Displaying and handling tabular data |
| Git & GitHub | Version control and collaboration |

## Application Features

The application contains six main modules:

### 1. Dashboard
- Displays the total number of complaints.
- Shows Open, In Progress, and Resolved complaint counts.
- Displays department-wise complaint statistics.
- Shows the ten most recent complaints.

### 2. Register Complaint
- Select an existing citizen and department.
- Enter complaint category, description, and priority.
- Automatically generate a complaint ID.
- Save the complaint with an initial status of Open.

### 3. View Complaints
- View registered complaints.
- Search complaints using their complaint ID.
- View citizen and department details.
- Check worker assignments and resolution information.

### 4. Manage Complaints
- Update complaint status.
- Change complaint priority.
- Maintain complaint progress.

### 5. Assign Workers
- Assign one or more workers to a complaint.
- Store worker assignment details.
- Prevent duplicate assignments.

### 6. Record Resolution
- Record resolution dates and notes.
- Maintain SLA status.
- Update the complaint status to Resolved when appropriate.

## Database Design

The project uses a relational database named `complaintmanagement` with the following nine tables:

| Table | Purpose |
|---|---|
| Department | Stores department information |
| Citizen | Stores citizen details |
| Asset | Stores asset information |
| Worker | Stores worker details |
| Complaint | Stores complaint records |
| Complaint_Asset | Maps complaints to assets |
| Complaint_Worker | Maps complaints to assigned workers |
| Resolution | Stores complaint resolution details |
| Complaint_Status_Audit | Maintains complaint status change history |

### Relationships

- A department can handle multiple complaints.
- A citizen can register multiple complaints.
- Complaints can be associated with assets.
- Workers can be assigned to multiple complaints.
- A complaint can have resolution information.
- Complaint status changes can be maintained in an audit table.

## DBMS Concepts Implemented

The project demonstrates the following database concepts:

- **Primary Keys and Foreign Keys:** Maintain unique records and relationships between tables.
- **Constraints:** Maintain data integrity.
- **Joins:** Retrieve related information from multiple tables.
- **Aggregate Functions:** Use functions such as `COUNT()` to calculate complaint statistics.
- **GROUP BY and HAVING:** Generate department-wise and grouped reports.
- **Nested Subqueries:** Retrieve data based on the results of another query.
- **Correlated Subqueries:** Execute subqueries that refer to the outer query.
- **Views:** Simplify access to frequently required complaint details.
- **Stored Procedures:** Implement reusable database operations.
- **User-Defined Functions:** Calculate citizen complaint counts.
- **Triggers:** Automatically record complaint status changes in the audit table.
- **Transactions:** Demonstrate transaction control using `COMMIT` and `ROLLBACK`.

## Project Structure

```text
Citizen-Complaint-Management-System/
│
├── app.py
├── db_connection.py
├── .env
├── .gitignore
│
└── SQL/
    └── complaint_management.sql
```

*The structure above represents the main project files; adjust it if your repository contains additional folders or files.*

## Installation and Setup

### Prerequisites
- Python 3.x
- MySQL Server
- Git

### Step 1: Clone the repository

```bash
git clone https://github.com/aisiriii/Citizen-Complaint-Management-System.git
```

```bash
cd Citizen-Complaint-Management-System
```

### Step 2: Create a virtual environment

```bash
python -m venv venv
```

Activate it on Windows:

```bash
venv\Scripts\activate
```

### Step 3: Install dependencies

```bash
pip install streamlit pandas mysql-connector-python python-dotenv
```

### Step 4: Configure the database

Create the MySQL database and ensure the required project tables are available.

Create a `.env` file in the project root:

```env
DB_HOST=localhost
DB_USER=root
DB_PASSWORD=your_mysql_password
DB_NAME=complaintmanagement
```

Update the values according to your MySQL configuration.

### Step 5: Run the application

```bash
streamlit run app.py
```

The application will open in your browser.

## SQL Script

The SQL folder contains the project's SQL enhancement script, including database queries and objects such as views, stored procedures, functions, and triggers.

**Note:** The current script is designed to work with the existing project database and tables. Ensure the database schema is set up before executing it. It does not recreate or replace existing tables.

## Future Enhancements

- User authentication and role-based access.
- Email or SMS notifications for complaint updates.
- Advanced search and filtering.
- Improved reporting and analytics.
- Automatic complaint ID generation using database auto-increment.
- SLA deadline reminders.

## Conclusion

The Citizen Complaint Management System demonstrates how database management concepts can be applied to a practical real-world problem. By combining Python, Streamlit, and MySQL, the project provides a centralized solution for complaint registration, assignment, tracking, and resolution.

---

**Project Type:** DBMS Mini Project  
**Repository:** [Citizen Complaint Management System](https://github.com/aisiriii/Citizen-Complaint-Management-System)
