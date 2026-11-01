
import streamlit as st
import pandas as pd
from datetime import date
from db_connection import get_connection


# --------------------------------------------------
# PAGE CONFIGURATION
# --------------------------------------------------

st.set_page_config(
    page_title="Citizen Complaint Management",
    page_icon="🏛️",
    layout="wide"
)

st.title("🏛️ Citizen Complaint Management System")
st.caption(
    "A centralized platform to register, monitor and resolve citizen complaints."
)


# --------------------------------------------------
# DATABASE CONNECTION
# --------------------------------------------------

connection = get_connection()

if connection is None:
    st.error(
        "Unable to connect to the database. "
        "Please check your MySQL connection."
    )
    st.stop()


def read_data(query, params=None):
    """Execute SELECT queries and return results as a DataFrame."""
    cursor = connection.cursor(dictionary=True)

    try:
        cursor.execute(query, params or ())
        rows = cursor.fetchall()
        return pd.DataFrame(rows)

    finally:
        cursor.close()


# --------------------------------------------------
# SIDEBAR NAVIGATION
# --------------------------------------------------

st.sidebar.title("Navigation")

page = st.sidebar.radio(
    "Select a section",
    [
        "Dashboard",
        "Register Complaint",
        "View Complaints",
        "Manage Complaints",
        "Assign Workers",
        "Record Resolution"
    ]
)


# ==================================================
# 1. DASHBOARD
# ==================================================

if page == "Dashboard":

    st.header("Dashboard Overview")

    total = read_data(
        "SELECT COUNT(*) AS total FROM Complaint"
    ).iloc[0]["total"]

    open_count = read_data(
        "SELECT COUNT(*) AS total FROM Complaint WHERE Status = 'Open'"
    ).iloc[0]["total"]

    progress_count = read_data(
        "SELECT COUNT(*) AS total FROM Complaint WHERE Status = 'In Progress'"
    ).iloc[0]["total"]

    resolved_count = read_data(
        "SELECT COUNT(*) AS total FROM Complaint WHERE Status = 'Resolved'"
    ).iloc[0]["total"]

    col1, col2, col3, col4 = st.columns(4)

    col1.metric("Total Complaints", total)
    col2.metric("Open", open_count)
    col3.metric("In Progress", progress_count)
    col4.metric("Resolved", resolved_count)

    st.divider()

    st.subheader("Complaints by Department")

    department_data = read_data("""
        SELECT
            d.Dname AS Department,
            COUNT(c.Complaint_ID) AS Total_Complaints
        FROM Department d
        LEFT JOIN Complaint c
            ON d.Dept_ID = c.Dept_ID
        GROUP BY d.Dept_ID, d.Dname
        ORDER BY Total_Complaints DESC
    """)

    st.bar_chart(
        department_data.set_index("Department")
    )

    st.subheader("Recent Complaints")

    recent = read_data("""
        SELECT
            Complaint_ID,
            Category,
            Priority,
            Status,
            Date_filed
        FROM Complaint
        ORDER BY Date_filed DESC, Complaint_ID DESC
        LIMIT 10
    """)

    st.dataframe(recent, use_container_width=True)


# ==================================================
# 2. REGISTER COMPLAINT
# ==================================================

elif page == "Register Complaint":

    st.header("Register a New Complaint")

    citizens = read_data("""
        SELECT Citizen_ID, Name
        FROM Citizen
        ORDER BY Name
    """)

    departments = read_data("""
        SELECT Dept_ID, Dname
        FROM Department
        ORDER BY Dname
    """)

    if citizens.empty or departments.empty:
        st.warning("Citizens or departments are not available.")

    else:

        citizen_options = {
            f"{row['Name']} (ID: {row['Citizen_ID']})":
            row["Citizen_ID"]
            for _, row in citizens.iterrows()
        }

        department_options = {
            row["Dname"]: row["Dept_ID"]
            for _, row in departments.iterrows()
        }

        with st.form("complaint_form"):

            citizen_name = st.selectbox(
                "Select Citizen",
                list(citizen_options.keys())
            )

            department_name = st.selectbox(
                "Select Department",
                list(department_options.keys())
            )

            category = st.selectbox(
                "Complaint Category",
                [
                    "Roads",
                    "Electrical",
                    "Water",
                    "Sanitation",
                    "Traffic",
                    "Drainage",
                    "Parks",
                    "Waste Management",
                    "Other"
                ]
            )

            description = st.text_area(
                "Complaint Description"
            )

            priority = st.selectbox(
                "Priority",
                ["Low", "Medium", "High", "Critical"]
            )

            submitted = st.form_submit_button(
                "Submit Complaint"
            )

            if submitted:

                if not description.strip():
                    st.error("Please enter a complaint description.")

                else:

                    cursor = connection.cursor()

                    try:
                        cursor.execute("""
                            SELECT COALESCE(MAX(Complaint_ID), 400) + 1
                            FROM Complaint
                        """)

                        new_id = cursor.fetchone()[0]

                        cursor.execute("""
                            INSERT INTO Complaint
                            (
                                Complaint_ID,
                                Description,
                                Priority,
                                Status,
                                Date_filed,
                                Category,
                                Citizen_ID,
                                Dept_ID
                            )
                            VALUES (%s, %s, %s, %s, CURDATE(), %s, %s, %s)
                        """, (
                            new_id,
                            description.strip(),
                            priority,
                            "Open",
                            category,
                            citizen_options[citizen_name],
                            department_options[department_name]
                        ))

                        connection.commit()

                        st.success(
                            f"Complaint registered successfully! "
                            f"Complaint ID: {new_id}"
                        )

                    except Exception as error:
                        connection.rollback()
                        st.error(f"Registration failed: {error}")

                    finally:
                        cursor.close()


# ==================================================
# 3. VIEW COMPLAINTS
# ==================================================

elif page == "View Complaints":

    st.header("View and Track Complaints")

    complaints = read_data("""
        SELECT
            c.Complaint_ID,
            ci.Name AS Citizen,
            c.Category,
            d.Dname AS Department,
            c.Priority,
            c.Status,
            c.Date_filed
        FROM Complaint c
        JOIN Citizen ci
            ON c.Citizen_ID = ci.Citizen_ID
        JOIN Department d
            ON c.Dept_ID = d.Dept_ID
        ORDER BY c.Complaint_ID DESC
    """)

    st.dataframe(
        complaints,
        use_container_width=True
    )

    st.subheader("Search for a Complaint")

    complaint_id = st.number_input(
        "Enter Complaint ID",
        min_value=1,
        step=1
    )

    if st.button("Search Complaint"):

        details = read_data("""
            SELECT
                c.*,
                ci.Name AS Citizen_Name,
                d.Dname AS Department
            FROM Complaint c
            JOIN Citizen ci
                ON c.Citizen_ID = ci.Citizen_ID
            JOIN Department d
                ON c.Dept_ID = d.Dept_ID
            WHERE c.Complaint_ID = %s
        """, (int(complaint_id),))

        if details.empty:
            st.warning("Complaint not found.")

        else:
            st.success("Complaint found!")
            st.dataframe(
                details,
                use_container_width=True
            )

            assignments = read_data("""
                SELECT
                    w.Worker_ID,
                    CONCAT(w.Fname, ' ', w.Lname) AS Worker_Name,
                    w.Role,
                    cw.Assigned_date
                FROM Complaint_Worker cw
                JOIN Worker w
                    ON cw.Worker_ID = w.Worker_ID
                WHERE cw.Complaint_ID = %s
            """, (int(complaint_id),))

            st.subheader("Assigned Workers")

            if assignments.empty:
                st.info("No workers assigned yet.")
            else:
                st.dataframe(
                    assignments,
                    use_container_width=True
                )

            resolution = read_data("""
                SELECT
                    Resolution_ID,
                    Resolution_date,
                    Notes,
                    SLA_status
                FROM Resolution
                WHERE Complaint_ID = %s
            """, (int(complaint_id),))

            st.subheader("Resolution Details")

            if resolution.empty:
                st.info("No resolution has been recorded.")
            else:
                st.dataframe(
                    resolution,
                    use_container_width=True
                )


# ==================================================
# 4. MANAGE COMPLAINTS
# ==================================================

elif page == "Manage Complaints":

    st.header("Manage Complaint Status and Priority")

    complaints = read_data("""
        SELECT
            Complaint_ID,
            Status,
            Priority
        FROM Complaint
        ORDER BY Complaint_ID DESC
    """)

    if complaints.empty:

        st.info("No complaints available.")

    else:

        selected_id = st.selectbox(
            "Select Complaint ID",
            complaints["Complaint_ID"].tolist()
        )

        current = complaints[
            complaints["Complaint_ID"] == selected_id
        ].iloc[0]

        st.write("Current Status:", current["Status"])
        st.write("Current Priority:", current["Priority"])

        with st.form("update_form"):

            statuses = [
                "Open",
                "In Progress",
                "Resolved"
            ]

            priorities = [
                "Low",
                "Medium",
                "High",
                "Critical"
            ]

            new_status = st.selectbox(
                "New Status",
                statuses,
                index=statuses.index(current["Status"])
            )

            new_priority = st.selectbox(
                "New Priority",
                priorities,
                index=priorities.index(current["Priority"])
            )

            update = st.form_submit_button(
                "Update Complaint"
            )

            if update:

                cursor = connection.cursor()

                try:
                    cursor.execute("""
                        UPDATE Complaint
                        SET Status = %s,
                            Priority = %s
                        WHERE Complaint_ID = %s
                    """, (
                        new_status,
                        new_priority,
                        int(selected_id)
                    ))

                    connection.commit()

                    st.success(
                        "Complaint updated successfully!"
                    )

                except Exception as error:
                    connection.rollback()
                    st.error(f"Update failed: {error}")

                finally:
                    cursor.close()


# ==================================================
# 5. ASSIGN WORKERS
# ==================================================

elif page == "Assign Workers":

    st.header("Assign Workers to Complaints")

    complaints = read_data("""
        SELECT
            Complaint_ID,
            Category,
            Status,
            Dept_ID
        FROM Complaint
        ORDER BY Complaint_ID DESC
    """)

    workers = read_data("""
        SELECT
            Worker_ID,
            Fname,
            Lname,
            Role,
            Dept_ID
        FROM Worker
        ORDER BY Fname
    """)

    if complaints.empty or workers.empty:

        st.warning(
            "Complaints or workers are not available."
        )

    else:

        complaint_id = st.selectbox(
            "Select Complaint",
            complaints["Complaint_ID"].tolist()
        )

        selected_complaint = complaints[
            complaints["Complaint_ID"] == complaint_id
        ].iloc[0]

        st.write(
            "Complaint Category:",
            selected_complaint["Category"]
        )

        st.write(
            "Complaint Status:",
            selected_complaint["Status"]
        )

        worker_options = {
            (
                f"{row['Fname']} {row['Lname']} "
                f"(Worker ID: {row['Worker_ID']}) - {row['Role']}"
            ): row["Worker_ID"]
            for _, row in workers.iterrows()
        }

        selected_workers = st.multiselect(
            "Select Workers",
            list(worker_options.keys())
        )

        if st.button("Assign Workers"):

            if not selected_workers:

                st.error("Please select at least one worker.")

            else:

                cursor = connection.cursor()

                try:

                    assigned = 0

                    for worker in selected_workers:

                        worker_id = worker_options[worker]

                        cursor.execute("""
                            INSERT IGNORE INTO Complaint_Worker
                            (
                                Complaint_ID,
                                Worker_ID,
                                Assigned_date
                            )
                            VALUES (%s, %s, CURDATE())
                        """, (
                            int(complaint_id),
                            int(worker_id)
                        ))

                        assigned += cursor.rowcount

                    connection.commit()

                    if assigned > 0:
                        st.success(
                            f"{assigned} worker(s) assigned successfully!"
                        )
                    else:
                        st.info(
                            "The selected workers were already assigned."
                        )

                except Exception as error:

                    connection.rollback()
                    st.error(f"Assignment failed: {error}")

                finally:
                    cursor.close()

    st.divider()

    st.subheader("Existing Worker Assignments")

    assignments = read_data("""
        SELECT
            cw.Complaint_ID,
            w.Worker_ID,
            CONCAT(w.Fname, ' ', w.Lname) AS Worker_Name,
            w.Role,
            cw.Assigned_date
        FROM Complaint_Worker cw
        JOIN Worker w
            ON cw.Worker_ID = w.Worker_ID
        ORDER BY cw.Complaint_ID DESC
    """)

    st.dataframe(
        assignments,
        use_container_width=True
    )


# ==================================================
# 6. RECORD RESOLUTION
# ==================================================

elif page == "Record Resolution":

    st.header("Record Complaint Resolution")

    complaints = read_data("""
        SELECT
            c.Complaint_ID,
            c.Description,
            c.Status,
            ci.Name AS Citizen
        FROM Complaint c
        JOIN Citizen ci
            ON c.Citizen_ID = ci.Citizen_ID
        ORDER BY c.Complaint_ID DESC
    """)

    if complaints.empty:

        st.info("No complaints available.")

    else:

        complaint_id = st.selectbox(
            "Select Complaint ID",
            complaints["Complaint_ID"].tolist()
        )

        selected_complaint = complaints[
            complaints["Complaint_ID"] == complaint_id
        ].iloc[0]

        st.write(
            "Citizen:",
            selected_complaint["Citizen"]
        )

        st.write(
            "Complaint Description:",
            selected_complaint["Description"]
        )

        st.write(
            "Current Status:",
            selected_complaint["Status"]
        )

        existing_resolution = read_data("""
            SELECT Resolution_ID
            FROM Resolution
            WHERE Complaint_ID = %s
        """, (int(complaint_id),))

        if not existing_resolution.empty:

            st.warning(
                "A resolution is already recorded for this complaint. "
                "The Resolution table permits only one resolution per complaint."
            )

        else:

            with st.form("resolution_form"):

                resolution_date = st.date_input(
                    "Resolution Date",
                    value=date.today()
                )

                notes = st.text_area(
                    "Resolution Notes",
                    placeholder="Describe the action taken to resolve the complaint."
                )

                sla_status = st.selectbox(
                    "SLA Status",
                    [
                        "Within SLA",
                        "Breached",
                        "Pending"
                    ]
                )

                mark_resolved = st.checkbox(
                    "Mark complaint status as Resolved",
                    value=True
                )

                submitted = st.form_submit_button(
                    "Save Resolution"
                )

                if submitted:

                    if not notes.strip():

                        st.error(
                            "Please enter resolution notes."
                        )

                    else:

                        cursor = connection.cursor()

                        try:

                            cursor.execute("""
                                SELECT COALESCE(MAX(Resolution_ID), 0) + 1
                                FROM Resolution
                            """)

                            resolution_id = cursor.fetchone()[0]

                            cursor.execute("""
                                INSERT INTO Resolution
                                (
                                    Resolution_ID,
                                    Resolution_date,
                                    Notes,
                                    SLA_status,
                                    Complaint_ID
                                )
                                VALUES (%s, %s, %s, %s, %s)
                            """, (
                                resolution_id,
                                resolution_date,
                                notes.strip(),
                                sla_status,
                                int(complaint_id)
                            ))

                            if mark_resolved:

                                cursor.execute("""
                                    UPDATE Complaint
                                    SET Status = 'Resolved'
                                    WHERE Complaint_ID = %s
                                """, (int(complaint_id),))

                            connection.commit()

                            st.success(
                                f"Resolution recorded successfully! "
                                f"Resolution ID: {resolution_id}"
                            )

                        except Exception as error:

                            connection.rollback()
                            st.error(
                                f"Could not record resolution: {error}"
                            )

                        finally:
                            cursor.close()

    st.divider()

    st.subheader("Resolution History")

    resolution_history = read_data("""
        SELECT
            r.Resolution_ID,
            r.Complaint_ID,
            ci.Name AS Citizen,
            r.Resolution_date,
            r.Notes,
            r.SLA_status
        FROM Resolution r
        JOIN Complaint c
            ON r.Complaint_ID = c.Complaint_ID
        JOIN Citizen ci
            ON c.Citizen_ID = ci.Citizen_ID
        ORDER BY r.Resolution_date DESC
    """)

    if resolution_history.empty:
        st.info("No resolutions have been recorded yet.")
    else:
        st.dataframe(
            resolution_history,
            use_container_width=True
        )


# --------------------------------------------------
# CLOSE DATABASE CONNECTION
# --------------------------------------------------

connection.close()
