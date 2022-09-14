/*
№1 Посчитать результаты тестирования. Результат попытки вычислить как количество правильных ответов,
деленное на 3 (количество вопросов в каждой попытке) и умноженное на 100. Результат округлить до двух знаков после запятой.
Вывести фамилию студента, название предмета, дату и результат. Последний столбец назвать Результат.
Информацию отсортировать сначала по фамилии студента, потом по убыванию даты попытки.
*/

SELECT  name_student, name_subject, date_attempt, ROUND((SUM(is_correct)/3)*100, 2) AS Результат
FROM attempt
    INNER JOIN testing ON attempt.attempt_id=testing.attempt_id
    INNER JOIN answer USING(answer_id)
    INNER JOIN student USING(student_id)
    INNER JOIN subject USING(subject_id)
GROUP BY attempt.attempt_id
ORDER BY student_id


/*
-- №2 Студенты могут тестироваться по одной или нескольким дисциплинам (не обязательно по всем).
-- Вывести дисциплину и количество уникальных студентов (столбец назвать Количество), которые по ней проходили тестирование.
-- Информацию отсортировать сначала по убыванию количества, а потом по названию дисциплины.
-- В результат включить и дисциплины, тестирование по которым студенты не проходили, в этом случае указать количество студентов 0.
*/

SELECT  name_subject, COUNT(DISTINCT student_id) AS Количество
FROM subject
    LEFT JOIN attempt USING(subject_id)
GROUP BY name_subject
ORDER BY Количество DESC, name_subject ASC


/*
-- №3 Вывести, сколько попыток сделали студенты по каждой дисциплине, а также средний результат попыток,
-- который округлить до 2 знаков после запятой. Под результатом попытки понимается процент правильных ответов
на вопросы теста, который занесен в столбец result.  В результат включить название дисциплины,
а также вычисляемые столбцы Количество и Среднее. Информацию вывести по убыванию средних результатов.
*/

SELECT subject.name_subject, COUNT(attempt.attempt_id) AS Количество, ROUND(AVG(attempt.result),2) AS Среднее
FROM attempt RIGHT JOIN subject ON subject.subject_id = attempt.subject_id
GROUP BY subject.subject_id
ORDER BY Среднее DESC


/*
-- №4 Вывести студентов (различных студентов), имеющих максимальные результаты попыток.
Информацию отсортировать в алфавитном порядке по фамилии студента.
*/
SELECT name_student, result
FROM student
    INNER JOIN attempt USING(student_id)
WHERE result = (
    SELECT MAX(result)
    FROM attempt
)
ORDER BY name_student ASC


/*
-- №5 Если студент совершал несколько попыток по одной и той же дисциплине, то вывести разницу в днях между первой
и последней попыткой. В результат включить фамилию и имя студента, название дисциплины и вычисляемый столбец Интервал.
Информацию вывести по возрастанию разницы. Студентов, сделавших одну попытку по дисциплине, не учитывать. 
*/

SELECT name_student, name_subject,  DATEDIFF(MAX(date_attempt),MIN(date_attempt)) AS Интервал
FROM attempt
    INNER JOIN student USING(student_id)
    INNER JOIN subject USING(subject_id)
GROUP BY name_student, name_subject
HAVING Интервал<>0
ORDER BY Интервал ASC


/*
-- №6 Выведите сколько человек подало заявление на каждую образовательную программу и конкурс
на нее (число поданных заявлений деленное на количество мест по плану), округленный до 2-х знаков после запятой.
В запросе вывести название факультета, к которому относится образовательная программа, название образовательной программы,
план набора абитуриентов на образовательную программу (plan), количество поданных заявлений (Количество) и Конкурс.
Информацию отсортировать в порядке убывания конкурса.
*/

SELECT name_department, name_program, plan, Количество, ROUND(Количество/plan, 2) AS Конкурс
FROM department
    INNER JOIN program USING(department_id)
    INNER JOIN 
            (SELECT program_id, COUNT(enrollee_id) AS Количество
            FROM  program_enrollee
            GROUP BY program_id) AS temp USING(program_id)
ORDER BY Конкурс DESC;


/*
-- №7 Сравнить ежемесячную выручку от продажи книг за текущий и предыдущий годы.
Для этого вывести год, месяц, сумму выручки в отсортированном сначала по возрастанию месяцев,
затем по возрастанию лет виде. Название столбцов: Год, Месяц, Сумма.
*/

SELECT YEAR(date_step_end) AS Год,
       MONTHNAME(date_step_end) AS Месяц,
       SUM(buy_book.amount*book.price) AS Сумма
FROM buy_step
     INNER JOIN buy_book USING(buy_id)
     INNER JOIN book USING(book_id)
     WHERE step_id=1 AND date_step_end IS NOT NULL       
GROUP BY Год, Месяц
UNION
SELECT YEAR(date_payment) AS Год,
       MONTHNAME(date_payment) AS Месяц,
       SUM(buy_archive.amount*buy_archive.price) AS Сумма
FROM buy_archive
WHERE  date_payment IS NOT NULL       
GROUP BY Год, Месяц
ORDER BY Месяц, Год


/*
-- №8 Для каждой отдельной книги необходимо вывести информацию о количестве проданных экземпляров и их стоимости
за текущий и предыдущий год . Вычисляемые столбцы назвать Количество и Сумма. Информацию отсортировать по убыванию стоимости.
*/

SELECT title, SUM(quantity) AS Количество, SUM(summa) AS Сумма
FROM
    (
    SELECT book.title, 
           SUM(buy_archive.amount) AS quantity, 
           SUM(buy_archive.amount * buy_archive.price) AS summa
    FROM buy_archive
         INNER JOIN book USING (book_id)
    GROUP BY book.title

    UNION ALL
    SELECT book.title,
           SUM(buy_book.amount) AS quantity,
           SUM(buy_book.amount * book.price) AS summa
    FROM 
        step
        INNER JOIN buy_step USING (step_id)
        INNER JOIN buy_book USING (buy_id)
        INNER JOIN book USING (book_id)
    WHERE step.name_step = 'Оплата' AND date_step_end IS NOT NULL
    GROUP BY book.title
    ORDER BY summa DESC
    ) query_in

GROUP BY title
ORDER BY Сумма DESC; 


/*
-- №9 Для книг, которые уже есть на складе (в таблице book), но по другой цене, чем в поставке (supply),
необходимо в таблице book увеличить количество на значение, указанное в поставке,  и пересчитать цену.
А в таблице  supply обнулить количество этих книг.
*/

UPDATE book 
     INNER JOIN author ON author.author_id = book.author_id
     INNER JOIN supply ON book.title = supply.title 
                         and supply.author = author.name_author
SET book.amount = book.amount + supply.amount,
    supply.amount = 0,
    book.price = (book.price * book.amount + supply.price * supply.amount)/(book.amount + supply.amount)
WHERE book.price <> supply.price;


/*
-- №10 Удалить все жанры, к которым относится меньше 4-х книг.
В таблице book для этих жанров установить значение Null.
*/

DELETE FROM genre
WHERE genre_id IN (SELECT genre_id
FROM book
GROUP BY genre_id
HAVING COUNT(amount) < 4);

SELECT * FROM genre;


/*
№11 Есть список городов, хранящийся в таблице city. Необходимо в каждом городе провести выставку книг каждого автора в течение 2020 года.
Дату проведения выставки выбрать случайным образом. Создать запрос, который выведет город, автора и дату проведения выставки.
Последний столбец назвать Дата. Информацию вывести, отсортировав сначала в алфавитном порядке по названиям городов, а потом по убыванию дат проведения выставок.
*/

SELECT name_city, name_author, (DATE_ADD('2020-01-01', INTERVAL FLOOR(RAND() * 365) DAY)) as Дата
FROM city CROSS JOIN author
ORDER BY name_city ASC, Дата DESC


/*
№12 Если в таблицах supply  и book есть одинаковые книги, которые имеют равную цену,  вывести их название и автора,
а также посчитать общее количество экземпляров книг в таблицах supply и book,  столбцы назвать Название, Автор  и Количество.
*/

SELECT book.title AS Название, name_author AS Автор, book.amount + supply.amount AS Количество
FROM 
    author 
    INNER JOIN book USING (author_id)   
    INNER JOIN supply ON book.title = supply.title 
                         and book.title  = supply.title 
                         and book.price  = supply.price ;

/*
№13 Создать таблицу book той же структуры, что и на предыдущем шаге.
Будем считать, что при удалении автора из таблицы author, должны удаляться все записи о книгах из таблицы book,
написанные этим автором. А при удалении жанра из таблицы genre для соответствующей записи book установить значение Null в столбце genre_id. 
*/

CREATE TABLE book (
    book_id INT PRIMARY KEY AUTO_INCREMENT, 
    title VARCHAR(50),
    author_id INT NOT NULL,
    genre_id INT,
    price DECIMAL(8,2), 
    amount INT,
    FOREIGN KEY (author_id)  REFERENCES author (author_id) ON DELETE CASCADE,
    FOREIGN KEY (genre_id)  REFERENCES genre (genre_id) ON DELETE SET NULL 
)


/*
№14 В таблицу fine занести дату оплаты соответствующего штрафа из таблицы payment.
Уменьшить начисленный штраф в таблице fine в два раза  (только для тех штрафов, информация о которых занесена в таблицу payment),
если оплата произведена не позднее 20 дней со дня нарушения.
*/

UPDATE fine, payment
SET
  fine.date_payment = payment.date_payment,
  fine.sum_fine = IF(DATEDIFF(payment.date_payment, fine.date_violation) <= 20,
      fine.sum_fine/2,
      fine.sum_fine
  )
WHERE fine.name = payment.name AND
      fine.number_plate = payment.number_plate AND
      fine.violation = payment.violation AND
      fine.date_payment IS NULL;


/*
№15 В таблицу fine занести дату оплаты соответствующего штрафа из таблицы payment.
Уменьшить начисленный штраф в таблице fine в два раза  (только для тех штрафов, информация о которых занесена в таблицу payment),
если оплата произведена не позднее 20 дней со дня нарушения.
*/

SELECT name_program

    FROM program
        INNER JOIN program_subject USING(program_id)
        INNER JOIN subject USING(subject_id)

        WHERE name_subject IN ("Информатика", "Математика")
        
GROUP BY name_program
HAVING COUNT(name_program) = 2
ORDER BY name_program ASC;