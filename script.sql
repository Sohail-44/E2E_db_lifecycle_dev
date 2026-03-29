-- drop tables in reverse FK dependency order
DROP TABLE IF EXISTS instructorCourse;
DROP TABLE IF EXISTS departmentCourse;
DROP TABLE IF EXISTS instructor;
DROP TABLE IF EXISTS department;
DROP TABLE IF EXISTS course;
DROP TABLE IF EXISTS college;

-- college entity
CREATE TABLE college (
    name  VARCHAR(100) PRIMARY KEY,
    city  VARCHAR(100),
    state CHAR(2)
) ENGINE=InnoDB;

-- department entity
CREATE TABLE department (
    code         CHAR(4)      PRIMARY KEY,
    name         VARCHAR(100),
    college_name VARCHAR(100),
    FOREIGN KEY (college_name) REFERENCES college(name)
) ENGINE=InnoDB;

-- course entity
CREATE TABLE course (
    number INT          PRIMARY KEY,
    title  VARCHAR(200)
) ENGINE=InnoDB;

-- instructor entity
CREATE TABLE instructor (
    id        INT          PRIMARY KEY AUTO_INCREMENT,
    firstName VARCHAR(100),
    lastName  VARCHAR(100)
) ENGINE=InnoDB;

-- departmentCourse associative entity (department M:M course)
-- offering_id is a surrogate key; natural key enforced via UNIQUE
CREATE TABLE departmentCourse (
    offering_id    INT      PRIMARY KEY AUTO_INCREMENT,
    departmentCode CHAR(4),
    course_number  INT,
    section        CHAR(1),
    year           SMALLINT,
    semester       VARCHAR(10),
    UNIQUE (departmentCode, course_number, section, year, semester),
    FOREIGN KEY (departmentCode) REFERENCES department(code),
    FOREIGN KEY (course_number)  REFERENCES course(number)
) ENGINE=InnoDB;

-- instructorCourse intersection (instructor M:M course / can teach)
CREATE TABLE instructorCourse (
    instructor_id INT,
    course_number INT,
    PRIMARY KEY (instructor_id, course_number),
    FOREIGN KEY (instructor_id) REFERENCES instructor(id),
    FOREIGN KEY (course_number) REFERENCES course(number)
) ENGINE=InnoDB;

-- ── LOAD DATA FROM TSV FILES ─────────────────────────────────
-- cd into the folder containing your TSV files before running,
-- or replace filenames with full absolute paths.

LOAD DATA LOCAL INFILE 'college.tsv'
    INTO TABLE college
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES
    (name, city, state);

LOAD DATA LOCAL INFILE 'department.tsv'
    INTO TABLE department
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES
    (code, name, college_name);

LOAD DATA LOCAL INFILE 'course.tsv'
    INTO TABLE course
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES
    (number, title);

LOAD DATA LOCAL INFILE ' instructor.tsv'
    INTO TABLE instructor
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES
    (id, firstName, lastName);

LOAD DATA LOCAL INFILE 'departmentCourse.tsv'
    INTO TABLE departmentCourse
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES
    (offering_id, departmentCode, course_number, section, year, semester);

LOAD DATA LOCAL INFILE ' instructorCourse.tsv'
    INTO TABLE instructorCourse
    FIELDS TERMINATED BY '\t'
    LINES TERMINATED BY '\r\n'
    IGNORE 1 LINES
    (instructor_id, course_number);


-- Queries 
-- Q1: How many departments does each college have?
SELECT   c.name AS college, COUNT(d.code) AS num_departments
FROM     college c
JOIN     department d ON d.college_name = c.name
GROUP BY c.name
ORDER BY num_departments DESC;

-- Q2: Which courses are offered by more than one department?
SELECT   c.number, c.title, COUNT(DISTINCT dc.departmentCode) AS offered_by_n_depts
FROM     course c
JOIN     departmentCourse dc ON dc.course_number = c.number
GROUP BY c.number, c.title
HAVING   offered_by_n_depts > 1;

-- Q3: Full course schedule — who teaches what, where, and when
SELECT   d.college_name                       AS college,
         dc.departmentCode                    AS dept,
         c.title                              AS course,
         dc.section,
         dc.year,
         dc.semester,
         CONCAT(i.firstName, ' ', i.lastName) AS instructor
FROM     departmentCourse dc
JOIN     department d  ON d.code        = dc.departmentCode
JOIN     course     c  ON c.number      = dc.course_number
LEFT JOIN instructorCourse ic ON ic.course_number  = dc.course_number
LEFT JOIN instructor       i  ON i.id              = ic.instructor_id
ORDER BY dc.year, dc.semester, dc.departmentCode;

-- Q4: Departments with no course offerings yet
SELECT   d.code, d.name, d.college_name
FROM     department d
LEFT JOIN departmentCourse dc ON dc.departmentCode = d.code
WHERE    dc.departmentCode IS NULL;

-- Q5: Course load per department
SELECT   d.name AS department, d.college_name AS college,
         COUNT(dc.offering_id) AS total_offerings
FROM     department d
LEFT JOIN departmentCourse dc ON dc.departmentCode = d.code
GROUP BY d.code, d.name, d.college_name
ORDER BY total_offerings DESC;