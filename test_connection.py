from db_connection import get_connection

connection = get_connection()

if connection:
    print("Connected to ComplaintManagement database successfully!")

    cursor = connection.cursor()
    cursor.execute("SHOW TABLES")

    print("\nAvailable tables:")
    for table in cursor.fetchall():
        print(table[0])

    cursor.close()
    connection.close()
else:
    print("Database connection failed.")