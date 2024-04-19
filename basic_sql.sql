--- Данные таблицы company по компаниям, которые закрылись
SELECT *
FROM company
WHERE status = 'closed';

--- Кол-во привлеченных средств для новостных компаний США
SELECT SUM(funding_total) AS funding_total
FROM company
WHERE category_code = 'news'
  AND country_code = 'USA'
GROUP BY name
ORDER BY funding_total DESC;

--- Общая сумма сделок, совершенных только за наличные с 2011 по 2013, по покупке одних компаний другими
SELECT SUM(price_amount)
FROM acquisition
WHERE term_code = 'cash'
  AND (EXTRACT(YEAR FROM CAST(acquired_at AS date)) BETWEEN '2011' AND '2013');

--- Выводим данные пользователей, названия аккаунтов которых начинаются на silver
SELECT first_name,
       last_name,
       network_username
FROM people
WHERE network_username LIKE 'Silver%';

---Выводим всю информацию о людях, в названиях аккаунтов которых есть подстрока money 
---и фамилия начинается на K
SELECT *
FROM people
WHERE network_username LIKE '%money%'
  AND last_name LIKE 'K%';

---Общая сумма привлеченных инвестиций, которые получили компании, по разным странам
SELECT SUM(funding_total),
       country_code
FROM company
GROUP BY country_code
ORDER BY SUM(funding_total) DESC;

---Дата проведения раунда, макс и мин суммы инвестиций, 
---Оставляем записи, в которых мин сумма инвестиций !=0 и !=макс
SELECT funded_at,
       MAX(raised_amount),
       MIN(raised_amount)
FROM funding_round
GROUP BY funded_at
HAVING MIN(raised_amount) != '0'
  AND MIN(raised_amount) != MAX(raised_amount);

---Создаем поле с категориями и отображаем все поля
SELECT f.*,
   (CASE 
        WHEN invested_companies >= 100 THEN 'high_activity'
        WHEN invested_companies >=20 AND invested_companies < 100 THEN 'middle_activity'
        WHEN invested_companies < 20 THEN 'low_activity'
    END)
FROM fund AS f;

---Считаем округленное до целого среднее кол-во инвестиционных раундов
SELECT CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds)) AS avg_investment_rounds
FROM fund
GROUP BY activity
ORDER BY avg_investment_rounds;

---Находим, в каких странах находятся фонды чаще всего инвестирующие в стартапы
SELECT country_code,
       MIN(invested_companies),
       MAX(invested_companies),
       AVG(invested_companies)
FROM fund
WHERE EXTRACT(YEAR FROM CAST (founded_at AS date)) BETWEEN '2010' AND '2012'
GROUP BY country_code
HAVING MIN(invested_companies) > 0
ORDER BY AVG(invested_companies) DESC, country_code
LIMIT 10;

---Выводим данные сотрудников стартапов
SELECT p.first_name,
       p.last_name,
       e.instituition
FROM people AS p
LEFT JOIN education AS e ON p.id = e.person_id;

---Находим кол-во учебных заведений, которые окончили сотрудники компании
SELECT c.name,
       COUNT(DISTINCT instituition) AS institute
FROM company AS c
INNER JOIN people AS p ON c.id = p.company_id
INNER JOIN education AS e ON p.id = e.person_id
GROUP BY c.name
ORDER BY institute DESC
LIMIT 5;

---Компании, для которых первый раунд финансирования является последним
SELECT DISTINCT c.name
FROM company AS c
INNER JOIN funding_round AS fr ON c.id = fr.company_id
WHERE status = 'closed'
  AND fr.is_first_round = 1 AND fr.is_last_round = 1;

---Уникальные номера сотрудников компаний, найденых выше
SELECT DISTINCT p.id
FROM company AS c
INNER JOIN funding_round AS fr ON c.id = fr.company_id
INNER JOIN people AS p ON c.id = p.company_id
WHERE status = 'closed'
  AND fr.is_first_round = 1 AND fr.is_last_round = 1;

---Уникальные пары из номеров сотрудников и учебных заведений
SELECT DISTINCT p.id,
       e.instituition
FROM company AS c
INNER JOIN funding_round AS fr ON c.id = fr.company_id
INNER JOIN people AS p ON c.id = p.company_id
INNER JOIN education AS e ON p.id = e.person_id
WHERE status = 'closed'
  AND fr.is_first_round = 1 AND fr.is_last_round = 1;

---Кол-во учебных заведений для каждого сотрудника
SELECT p.id, 
       COUNT(e.instituition) AS total_instituition
FROM people AS p JOIN education AS e ON p.id = e.person_id
WHERE company_id IN (SELECT id
                     FROM company 
                     WHERE id IN (SELECT company_id
                                  FROM funding_round
                                  WHERE is_first_round = 1 AND is_last_round = 1)
                     AND STATUS = 'closed')
GROUP BY p.id;

---Среднее число учебных заведений, которые окончили сотрудники
SELECT avg(ti.total_instituition)
FROM (SELECT p.id,
             COUNT(e.instituition) AS total_instituition
      FROM people AS p JOIN education AS e ON p.id = e.person_id
      WHERE company_id IN (SELECT id
                           FROM company 
                           WHERE id IN (SELECT company_id
                                        FROM funding_round
                                        WHERE is_first_round = 1 AND is_last_round = 1)
                           AND STATUS = 'closed')
      GROUP BY p.id
     ) AS ti;

---Среднее число учебных заведений, которые окончили сотрудники Socialnet
SELECT avg(ti.total_instituition)
FROM (SELECT p.id,
             COUNT(e.instituition) AS total_instituition
      FROM people AS p JOIN education AS e ON p.id = e.person_id
      WHERE p.company_id IN (SELECT id
                           FROM company 
                           WHERE name = 'Socialnet')
      GROUP BY p.id
     ) AS ti;

---Таблица с полями о компаниях, которые имели больше 6 этапов и раунды финансирования 
--- проходили с 2012 по 2013
SELECT f.name AS name_of_fund,
       c.name AS name_of_company,
       fr.raised_amount AS amount
FROM investment AS i
INNER JOIN company AS c ON i.company_id = c.id
INNER JOIN fund AS f ON i.fund_id = f.id
INNER JOIN funding_round AS fr ON i.funding_round_id = fr.id
WHERE c.milestones > 6 
  AND EXTRACT(YEAR FROM fr.funded_at) between 2012 AND 2013;

---Таблица с полями о компаниях, чьи суммы инвестиций не равны 0
SELECT c.name AS acquiring_company,
       ac.price_amount,
       cc.name AS acquired_company,
       cc.funding_total AS investition_price,
       ROUND(ac.price_amount/cc.funding_total) AS part_buying
FROM acquisition AS ac
LEFT JOIN company AS c ON ac.acquiring_company_id = c.id 
LEFT JOIN company AS cc ON ac.acquired_company_id = cc.id
WHERE ac.price_amount > 0
  AND cc.funding_total > 0
ORDER BY ac.price_amount DESC, cc.name
LIMIT 10;

---Названия компаний категории social, получившие финансирование с 2010 по 2013
SELECT c.name,
       EXTRACT(MONTH FROM CAST(fr.funded_at AS date))
FROM company AS c 
INNER JOIN (SELECT company_id,
                   funded_at,
                   raised_amount
            FROM funding_round
            WHERE EXTRACT(YEAR FROM CAST(funded_at AS date)) BETWEEN '2010' AND '2013'
) AS fr ON c.id = fr.company_id
WHERE c.category_code = 'social'
  AND fr.raised_amount <> 0;

---Таблица с полями о компаниях, инвестиционные раунды которых проходили с 2010 по 2013
WITH 
funds_month AS (SELECT EXTRACT(MONTH FROM fr.funded_at) AS month,
                       COUNT(DISTINCT f.name) AS count_name
                FROM funding_round AS fr 
                INNER JOIN investment AS i ON fr.id = i.funding_round_id
                INNER JOIN fund AS f ON i.fund_id = f.id
                WHERE EXTRACT(YEAR FROM fr.funded_at) BETWEEN 2010 AND 2013 
                  AND f.country_code = 'USA'
                GROUP BY month
                ),
acq_table AS (SELECT EXTRACT(MONTH FROM ac.acquired_at) AS month,
                     COUNT(ac.acquired_company_id) AS count_ac_company,
                     SUM(ac.price_amount) AS sum_amount
              FROM acquisition AS ac
              WHERE EXTRACT(YEAR FROM ac.acquired_at) BETWEEN 2010 AND 2013
              GROUP BY month
             )

SELECT funds_month.month,
       funds_month.count_name,
       acq_table.count_ac_company,
       acq_table.sum_amount
FROM funds_month JOIN acq_table ON funds_month.month = acq_table.month;

---Сводная таблица со средней суммой инвестиций для стран, в котрых есть стартапы
---Стартапы зарегестрированны с 2011 по 2013 год
WITH
     inv_2011 AS (SELECT country_code,
                         AVG(funding_total) AS y_2011
                  FROM company 
                  WHERE EXTRACT(YEAR FROM founded_at) = 2011
                  GROUP BY country_code
     ),
     inv_2012 AS (SELECT country_code,
                         AVG(funding_total) AS y_2012
                  FROM company 
                  WHERE EXTRACT(YEAR FROM founded_at) = 2012
                  GROUP BY country_code
     ),
     inv_2013 AS (SELECT country_code,
                         AVG(funding_total) AS y_2013
                  FROM company 
                  WHERE EXTRACT(YEAR FROM founded_at) = 2013
                  GROUP BY country_code
     )
SELECT inv_2011.country_code,
       inv_2011.y_2011,
       inv_2012.y_2012,
       inv_2013.y_2013
FROM inv_2011 
INNER JOIN inv_2012 ON inv_2011.country_code = inv_2012.country_code 
INNER JOIN inv_2013 ON inv_2012.country_code = inv_2013.country_code
ORDER BY inv_2011.y_2011 DESC;