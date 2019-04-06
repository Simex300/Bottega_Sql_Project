-- Create Schema --

CREATE DATABASE bottega_course;

USE bottega_course;

-- Create Tables and Primary Keys --

CREATE TABLE students (
    `id` INT NOT NULL AUTO_INCREMENT,
    `first_name` VARCHAR(45) NOT NULL,
    `last_name` VARCHAR(45) NOT NULL,
    PRIMARY KEY(`id`)
);

CREATE TABLE courses (
    `id` INT NOT NULL AUTO_INCREMENT,
    `name` VARCHAR(45),
    `professor_id` INT NOT NULL,
    PRIMARY KEY(`id`)
);

CREATE TABLE course_student (
    `id` INT NOT NULL AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `course_id` INT NOT NULL,
    PRIMARY KEY(`id`)
);

CREATE TABLE professors (
    `id` INT NOT NULL AUTO_INCREMENT,
    `first_name` VARCHAR(45),
    `last_name` VARCHAR(45),
    PRIMARY KEY(`id`)
);

CREATE TABLE grades (
    `id` INT NOT NULL AUTO_INCREMENT,
    `student_id` INT NOT NULL,
    `course_id` INT NOT NULL,
    `grade` DECIMAL(3, 0),
    PRIMARY KEY(`id`)
);

-- Adding Foreign Keys --

ALTER TABLE course_student
ADD CONSTRAINT FK_CourseStudent_Student
FOREIGN KEY (`student_id`) REFERENCES students(`id`);

ALTER TABLE course_student
ADD CONSTRAINT FK_CourseStudent_Course
FOREIGN KEY (`course_id`) REFERENCES courses(`id`);

ALTER TABLE courses
ADD CONSTRAINT FK_Course_Professor
FOREIGN KEY (`professor_id`) REFERENCES professors(`id`);

ALTER TABLE grades
ADD CONSTRAINT FK_Grades_Student
FOREIGN KEY (`student_id`) REFERENCES students(`id`);

ALTER TABLE grades
ADD CONSTRAINT FK_Grades_Courses
FOREIGN KEY (`course_id`) REFERENCES courses(`id`);

-- Populating Dump Data --

INSERT INTO students (`first_name`, `last_name`) VALUES ('John', 'McClain');
INSERT INTO students (`first_name`, `last_name`) VALUES ('Andrea', 'Clark');
INSERT INTO students (`first_name`, `last_name`) VALUES ('Thomas', 'Connor');
INSERT INTO students (`first_name`, `last_name`) VALUES ('Ben', 'Anderson');
INSERT INTO students (`first_name`, `last_name`) VALUES ('Ivan', 'Mark');


INSERT INTO professors (`first_name`, `last_name`) VALUES ('Carlos', 'Romeo');
INSERT INTO professors (`first_name`, `last_name`) VALUES ('Marth', 'Blue');
INSERT INTO professors (`first_name`, `last_name`) VALUES ('Sandra', 'Chief');

INSERT INTO courses (`name`, `professor_id`) VALUES ('Calculus I', RAND() * 3);
INSERT INTO courses (`name`, `professor_id`) VALUES ('Calculus II', RAND() * 3);
INSERT INTO courses (`name`, `professor_id`) VALUES ('Intro to programming', RAND() * 3);
INSERT INTO courses (`name`, `professor_id`) VALUES ('Intro to IT', RAND() * 3);
INSERT INTO courses (`name`, `professor_id`) VALUES ('English I', RAND() * 3);
INSERT INTO courses (`name`, `professor_id`) VALUES ('English II', RAND() * 3);

DELIMITER //
CREATE PROCEDURE populateCoursesStudents(student_value INT, loop_count INT)
BEGIN
    DECLARE EXIT HANDLER FOR 1452
    SELECT CONCAT('Foreign key error student_id:', CONCAT(student_value, CONCAT(' and course_id: ', @random_number))) as msg;
    
    SET @counter = 0;
    label: LOOP
        SET @selected_student = 0;
        SET @selected_course = 0;
    
        SET @counter = @counter + 1;
        SET @random_number = CAST((RAND() * 5) + 1 AS DECIMAL(1, 0));
        SET @condition_value = (SELECT COUNT(*) FROM course_student WHERE (`student_id` = student_value AND `course_id` = CAST(@random_number AS DECIMAL(1,0))));
        
        IF @condition_value = 0 THEN
            INSERT INTO course_student (`student_id`, `course_id`) VALUES (student_value, @random_number);
            SET loop_count = loop_count + 1;
        END IF;
        
        IF @counter > 100 THEN 
            SELECT 'Nothing happened!' as 'Message', @condition_value as 'Last Condition Value', @random_number as 'Last Course ID', student_value as 'Last Student ID';
            SELECT * FROM course_student WHERE (`student_id` = student_value AND `course_id` =  CAST(@random_number AS DECIMAL(1,0)));
            LEAVE label;
        END IF;
        
        IF loop_count >= 3 THEN 
            LEAVE label;
        ELSE 
            ITERATE label;
        END IF;
    END LOOP label;
END//
DELIMITER ;

CALL populateCoursesStudents(1, 0);
CALL populateCoursesStudents(2, 0);
CALL populateCoursesStudents(3, 0);
CALL populateCoursesStudents(4, 0);
CALL populateCoursesStudents(5, 0);

DELIMITER //
CREATE PROCEDURE populateStudentGrade(student INT)
BEGIN
    SET @counter = 0;
    SET @course_id = 0;
    label: LOOP
        IF @course_id = 0 THEN
            SET @course_id = (SELECT `id` FROM course_student WHERE `student_id` = student LIMIT 0, 1);
        ELSE
            SET @course_id = @course_id + 1;
        END IF;
        
        SET @course = (SELECT `course_id` FROM course_student WHERE `id` = @course_id);
        SET @rand_grade = CAST((RAND() * 99) + 1 AS DECIMAL(3, 0));
        
        IF @counter < 3 THEN
            INSERT INTO grades (`student_id`, `course_id`, `grade`) VALUES (student, @course, @rand_grade);
            SET @counter = @counter + 1;
            ITERATE label;
        ELSE
            LEAVE label;
        END IF;
    END LOOP label;
END //
DELIMITER ;

CALL populateStudentGrade(1);
CALL populateStudentGrade(2);
CALL populateStudentGrade(3);
CALL populateStudentGrade(4);
CALL populateStudentGrade(5);

-- Queries --

SELECT p.first_name, CAST(AVG(g.grade) AS DECIMAL(5,2)) as 'Average Grade'
FROM professors p
INNER JOIN courses c ON p.id = c.professor_id
INNER JOIN grades g ON c.id = g.course_id
GROUP BY p.first_name;

SELECT s.first_name, CAST(MAX(g.grade) AS DECIMAL(5,2)) as 'Maximun Grade'
FROM students s
INNER JOIN grades g ON s.id = g.student_id
GROUP BY s.first_name;

SELECT c.name, s.first_name
FROM courses c
INNER JOIN course_student cs ON c.id = cs.course_id
INNER JOIN students s ON s.id = cs.student_id
ORDER BY c.name DESC;

SELECT c.name as 'Course Name', CAST(AVG(g.grade) AS DECIMAL(5,2)) as 'Average Grade'
FROM courses c
INNER JOIN grades g ON c.id = g.course_id
GROUP BY c.name
ORDER BY AVG(g.grade) ASC;

SELECT s.first_name as 'Student Name', p.first_name as 'Professor Name', COUNT(c.id) as 'Number of courses'
FROM courses c
INNER JOIN professors p ON p.id = c.professor_id
INNER JOIN course_student cs ON cs.course_id = c.id
INNER JOIN students s ON s.id = cs.student_id
GROUP BY s.first_name, p.first_name
ORDER BY COUNT(c.id) DESC;