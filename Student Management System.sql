-- MySQL Database Schema for Student Management System
-- Database: student_management

-- Create the database if it doesn't exist
CREATE DATABASE IF NOT EXISTS student_management;

-- Use the newly created database
USE student_management;

-- Table for Students
CREATE TABLE IF NOT EXISTS students (
    id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    date_of_birth DATE,
    gender ENUM('Male', 'Female', 'Other'),
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(20),
    address TEXT,
    enrollment_date DATE NOT NULL
);

-- Table for Courses (optional, but good for a full system)
CREATE TABLE IF NOT EXISTS courses (
    id INT AUTO_INCREMENT PRIMARY KEY,
    course_name VARCHAR(100) NOT NULL UNIQUE,
    course_code VARCHAR(10) NOT NULL UNIQUE,
    credits INT NOT NULL
);

-- Table for Enrollments (linking students to courses)
CREATE TABLE IF NOT EXISTS enrollments (
    id INT AUTO_INCREMENT PRIMARY KEY,
    student_id INT NOT NULL,
    course_id INT NOT NULL,
    enrollment_date DATE NOT NULL,
    grade VARCHAR(5),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
    FOREIGN KEY (course_id) REFERENCES courses(id) ON DELETE CASCADE,
    UNIQUE(student_id, course_id) -- A student can enroll in a course only once
);

-- Insert some sample data (optional)
INSERT INTO students (first_name, last_name, date_of_birth, gender, email, phone_number, address, enrollment_date) VALUES
('Alice', 'Smith', '2003-05-15', 'Female', 'alice.smith@example.com', '123-456-7890', '123 Main St, Anytown', '2022-09-01'),
('Bob', 'Johnson', '2002-11-20', 'Male', 'bob.j@example.com', '098-765-4321', '456 Oak Ave, Otherville', '2022-09-01'),
('Charlie', 'Brown', '2004-01-10', 'Male', 'charlie.b@example.com', '555-123-4567', '789 Pine Ln, Somewhere', '2023-01-15');

INSERT INTO courses (course_name, course_code, credits) VALUES
('Introduction to Programming', 'CS101', 3),
('Calculus I', 'MA101', 4),
('English Literature', 'ENGL201', 3);

INSERT INTO enrollments (student_id, course_id, enrollment_date, grade) VALUES
(1, 1, '2022-09-01', 'A'),
(1, 2, '2022-09-01', 'B+'),
(2, 1, '2022-09-01', 'B'),
(3, 3, '2023-01-15', NULL);

```python
import mysql.connector
from mysql.connector import Error
import datetime

class StudentManagementSystem:
    def __init__(self, host, database, user, password):
        """
        Initializes the database connection.
        Args:
            host (str): The database host.
            database (str): The database name.
            user (str): The database username.
            password (str): The database password.
        """
        self.host = host
        self.database = database
        self.user = user
        self.password = password
        self.connection = None
        self.cursor = None
        self._connect()

    def _connect(self):
        """Establishes a connection to the MySQL database."""
        try:
            self.connection = mysql.connector.connect(
                host=self.host,
                database=self.database,
                user=self.user,
                password=self.password
            )
            if self.connection.is_connected():
                self.cursor = self.connection.cursor(buffered=True)
                print(f"Connected to MySQL database: {self.database}")
            else:
                print("Failed to connect to MySQL database.")
        except Error as e:
            print(f"Error connecting to MySQL database: {e}")

    def _disconnect(self):
        """Closes the database connection."""
        if self.connection and self.connection.is_connected():
            self.cursor.close()
            self.connection.close()
            print("MySQL connection closed.")

    def add_student(self, first_name, last_name, date_of_birth, gender, email, phone_number, address, enrollment_date):
        """
        Adds a new student to the database.
        Args:
            first_name (str): Student's first name.
            last_name (str): Student's last name.
            date_of_birth (str): Student's date of birth (YYYY-MM-DD).
            gender (str): Student's gender ('Male', 'Female', 'Other').
            email (str): Student's email (must be unique).
            phone_number (str): Student's phone number.
            address (str): Student's address.
            enrollment_date (str): Student's enrollment date (YYYY-MM-DD).
        Returns:
            int: The ID of the newly added student, or None if failed.
        """
        try:
            sql = """INSERT INTO students (first_name, last_name, date_of_birth, gender, email, phone_number, address, enrollment_date)
                     VALUES (%s, %s, %s, %s, %s, %s, %s, %s)"""
            val = (first_name, last_name, date_of_birth, gender, email, phone_number, address, enrollment_date)
            self.cursor.execute(sql, val)
            self.connection.commit()
            print(f"Student '{first_name} {last_name}' added successfully. ID: {self.cursor.lastrowid}")
            return self.cursor.lastrowid
        except Error as e:
            print(f"Error adding student: {e}")
            self.connection.rollback()
            return None

    def get_student(self, student_id):
        """
        Retrieves a student by their ID.
        Args:
            student_id (int): The ID of the student to retrieve.
        Returns:
            tuple: A tuple containing student data, or None if not found.
        """
        try:
            sql = "SELECT * FROM students WHERE id = %s"
            self.cursor.execute(sql, (student_id,))
            student = self.cursor.fetchone()
            if student:
                print(f"Found student: {student}")
            else:
                print(f"Student with ID {student_id} not found.")
            return student
        except Error as e:
            print(f"Error retrieving student: {e}")
            return None

    def get_all_students(self):
        """
        Retrieves all students from the database.
        Returns:
            list: A list of tuples, each representing a student.
        """
        try:
            sql = "SELECT * FROM students"
            self.cursor.execute(sql)
            students = self.cursor.fetchall()
            if students:
                print("All students:")
                for student in students:
                    print(student)
            else:
                print("No students found in the database.")
            return students
        except Error as e:
            print(f"Error retrieving all students: {e}")
            return []

    def update_student(self, student_id, **kwargs):
        """
        Updates student information.
        Args:
            student_id (int): The ID of the student to update.
            **kwargs: Keyword arguments for fields to update (e.g., first_name='NewName').
        Returns:
            bool: True if updated successfully, False otherwise.
        """
        if not kwargs:
            print("No fields to update provided.")
            return False

        set_clauses = []
        values = []
        for key, value in kwargs.items():
            set_clauses.append(f"{key} = %s")
            values.append(value)

        values.append(student_id) # Add student_id to the end for the WHERE clause

        sql = f"UPDATE students SET {', '.join(set_clauses)} WHERE id = %s"
        try:
            self.cursor.execute(sql, tuple(values))
            self.connection.commit()
            if self.cursor.rowcount > 0:
                print(f"Student with ID {student_id} updated successfully.")
                return True
            else:
                print(f"No student found with ID {student_id} or no changes made.")
                return False
        except Error as e:
            print(f"Error updating student: {e}")
            self.connection.rollback()
            return False

    def delete_student(self, student_id):
        """
        Deletes a student from the database by ID.
        Args:
            student_id (int): The ID of the student to delete.
        Returns:
            bool: True if deleted successfully, False otherwise.
        """
        try:
            sql = "DELETE FROM students WHERE id = %s"
            self.cursor.execute(sql, (student_id,))
            self.connection.commit()
            if self.cursor.rowcount > 0:
                print(f"Student with ID {student_id} deleted successfully.")
                return True
            else:
                print(f"No student found with ID {student_id}.")
                return False
        except Error as e:
            print(f"Error deleting student: {e}")
            self.connection.rollback()
            return False

    def add_course(self, course_name, course_code, credits):
        """
        Adds a new course to the database.
        """
        try:
            sql = "INSERT INTO courses (course_name, course_code, credits) VALUES (%s, %s, %s)"
            val = (course_name, course_code, credits)
            self.cursor.execute(sql, val)
            self.connection.commit()
            print(f"Course '{course_name}' added successfully. ID: {self.cursor.lastrowid}")
            return self.cursor.lastrowid
        except Error as e:
            print(f"Error adding course: {e}")
            self.connection.rollback()
            return None

    def get_all_courses(self):
        """
        Retrieves all courses from the database.
        """
        try:
            sql = "SELECT * FROM courses"
            self.cursor.execute(sql)
            courses = self.cursor.fetchall()
            if courses:
                print("All courses:")
                for course in courses:
                    print(course)
            else:
                print("No courses found.")
            return courses
        except Error as e:
            print(f"Error retrieving all courses: {e}")
            return []

    def enroll_student_in_course(self, student_id, course_id, enrollment_date):
        """
        Enrolls a student in a course.
        """
        try:
            sql = "INSERT INTO enrollments (student_id, course_id, enrollment_date) VALUES (%s, %s, %s)"
            val = (student_id, course_id, enrollment_date)
            self.cursor.execute(sql, val)
            self.connection.commit()
            print(f"Student ID {student_id} enrolled in Course ID {course_id} successfully.")
            return self.cursor.lastrowid
        except Error as e:
            print(f"Error enrolling student: {e}")
            self.connection.rollback()
            return None

    def get_student_enrollments(self, student_id):
        """
        Retrieves all courses a student is enrolled in.
        """
        try:
            sql = """
                SELECT c.course_name, c.course_code, e.enrollment_date, e.grade
                FROM enrollments e
                JOIN courses c ON e.course_id = c.id
                WHERE e.student_id = %s
            """
            self.cursor.execute(sql, (student_id,))
            enrollments = self.cursor.fetchall()
            if enrollments:
                print(f"Enrollments for Student ID {student_id}:")
                for enrollment in enrollments:
                    print(enrollment)
            else:
                print(f"Student ID {student_id} has no enrollments.")
            return enrollments
        except Error as e:
            print(f"Error retrieving enrollments for student {student_id}: {e}")
            return []

# --- Example Usage ---
if __name__ == "__main__":
    # IMPORTANT: Replace with your MySQL database credentials
    DB_CONFIG = {
        'host': 'localhost',
        'database': 'student_management',
        'user': 'your_mysql_user',     # e.g., 'root'
        'password': 'your_mysql_password' # e.g., 'password'
    }

    # 1. Initialize the system
    sms = StudentManagementSystem(**DB_CONFIG)

    if sms.connection and sms.connection.is_connected():
        # 2. Add a new student
        print("\n--- Adding a new student ---")
        new_student_id = sms.add_student(
            first_name='David',
            last_name='Lee',
            date_of_birth='2005-03-22',
            gender='Male',
            email='david.lee@example.com',
            phone_number='111-222-3333',
            address='101 River Rd, Riverton',
            enrollment_date='2024-01-01'
        )

        # 3. Get all students
        print("\n--- Getting all students ---")
        sms.get_all_students()

        # 4. Get a specific student
        if new_student_id:
            print(f"\n--- Getting student with ID {new_student_id} ---")
            sms.get_student(new_student_id)

            # 5. Update a student
            print(f"\n--- Updating student with ID {new_student_id} ---")
            sms.update_student(
                student_id=new_student_id,
                email='david.m.lee@example.com',
                phone_number='999-888-7777'
            )
            sms.get_student(new_student_id) # Verify update

            # 6. Add a new course
            print("\n--- Adding a new course ---")
            new_course_id = sms.add_course(
                course_name='Data Structures',
                course_code='CS201',
                credits=3
            )

            # 7. Get all courses
            print("\n--- Getting all courses ---")
            sms.get_all_courses()

            # 8. Enroll student in a course
            if new_course_id:
                print(f"\n--- Enrolling student {new_student_id} in course {new_course_id} ---")
                sms.enroll_student_in_course(new_student_id, new_course_id, '2024-01-15')

                # 9. Get student's enrollments
                print(f"\n--- Getting enrollments for student {new_student_id} ---")
                sms.get_student_enrollments(new_student_id)

            # 10. Delete a student
            print(f"\n--- Deleting student with ID {new_student_id} ---")
            sms.delete_student(new_student_id)
            sms.get_all_students() # Verify deletion

    # 11. Disconnect from the database
    sms._disconnect()
