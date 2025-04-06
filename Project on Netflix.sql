CREATE DATABASE Netflix_DB

USE Netflix_DB


-- SCHEMAS of Netflix

CREATE TABLE Netflix_N
(
	show_id	    VARCHAR(5),
	type        VARCHAR(10),
	title	    VARCHAR(250),
	director    VARCHAR(550),
	casts	    VARCHAR(1050),
	country	    VARCHAR(550),
	date_added	VARCHAR(55),
	release_yea INT,
	rating	    VARCHAR(15),
	duration	VARCHAR(15),
	listed_in	VARCHAR(250),
	description VARCHAR(550)
);

SELECT * FROM Netflix_N;

-- 1. Count the number of Movies vs TV Shows

SELECT type,
     COUNT(*) AS Num_Of_content
FROM Netflix_N
GROUP BY type;

---2. Find the most common rating for movies and TV shows

SELECT
     type,
	 rating
FROM (
     SELECT type, 
           rating,
	       COUNT(*) AS CNT,
	       RANK() OVER(PARTITION BY type ORDER BY COUNT(*)DESC) AS ranking
     FROM Netflix_N
GROUP BY type, rating
) AS T1 
WHERE ranking = 1

---3. List all movies released in a specific year (e.g., 2020)

SELECT * 
FROM Netflix_N
WHERE 
    type = 'Movie' 
	AND 
	release_Year = 2020;

---4. Find the top 5 countries with the most content on Netflix

WITH countryList AS (
                    SELECT LTRIM(RTRIM(m.n.value('.', 'VARCHAR(30)'))) AS countryName
		    FROM (
                        SELECT
                             CAST('<X>' + REPLACE(country, ', ', '</X><X>') + '</X>' AS XML) AS countryXML
                        FROM Netflix_N
                       ) AS T
                    CROSS APPLY countryXML.nodes('/X') AS m(n)
                     )
SELECT DISTINCT TOP 5 country, COUNT(*) AS ContentCount
FROM countryList
GROUP BY country
ORDER BY ContentCount DESC;

---5. Identify the longest movie

SELECT *
FROM Netflix_N
WHERE 
    type = 'Movie' 
    AND 
    duration = (SELECT MAX(duration) FROM Netflix_N);

---6. Find content added in the last 5 years

SELECT *
FROM Netflix_N
WHERE YEAR(date_added) >= DATEDIFF(yy, date_added, GETDATE()) - 5

---7. Find all the movies/TV shows by director 'Rajiv Chilaka'!

SELECT * 
FROM Netflix_N
WHERE 
    director LIKE '%Rajiv Chilaka%'

---8. List all TV shows with more than 5 seasons

SELECT * 
FROM Netflix_N
WHERE 
     type = 'TV Show' 
     AND 
     CAST(LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT) > 5

---9. Count the number of content items in each genre

WITH GenreCTE AS (
      SELECT LTRIM(RTRIM(m.n.value('.','VARCHAR(100)'))) 
AS Genre
      FROM Netflix_N
      CROSS APPLY (
             SELECT CAST('<X>' + 
                    REPLACE([listed_in], '&', 'amp;') + '</X>' AS XML) AS GenreXML 
             ) AS A  
	     CROSS APPLY GenreXML.nodes('/X') AS m(n)
) 
SELECT Genre,
       COUNT(*) AS Content_count
FROM GenreCTE
GROUP BY Genre
ORDER BY Content_count DESC; 

---10.Find each year and the average numbers of content release in India on netflix return top 5 year with highest avg content release!. 

SELECT TOP 5 YEAR(CONVERT(DATE, date_added)) AS Year,
       COUNT(*) AS yearly_content,
       CAST(COUNT(*) *100 /(SELECT COUNT(*) FROM Netflix_N WHERE country = 'India') AS FLOAT) 
AS Avg_content_percentage
from Netflix_N 
WHERE 
     country = 'India'
GROUP BY YEAR(CONVERT(DATE, date_added))
ORDER BY Avg_content_percentage DESC;

---11. List all movies that are documentaries

SELECT * 
FROM Netflix_N
WHERE 
     type = 'Movie' 
     AND 
     listed_in LIKE '%Documentaries%'

--12. Find all content without a director

SELECT * FROM Netflix_N
WHERE director IS NULL

---13. Find how many movies actor 'Salman Khan' appeared in last 10 years!

SELECT * 
FROM Netflix_N
WHERE
     cast LIKE '%Salman Khan%'
	 AND
	 type = 'Movie'
	 AND 
	 release_year > DATEDIFF(yy, date_added, GETDATE()) - 10;

---14. Find the top 10 actors who have appeared in the highest number of movies produced in India.

WITH ActorCTE AS (
              SELECT LTRIM(RTRIM(m.n.value('.', 'VARCHAR(100)')))
              AS ActorName
              FROM Netflix_N
	          CROSS APPLY (
	                       SELECT CAST('<X>' + REPLACE(cast, ',', '</X><X>') + '</X>' AS XML) AS xml_Data
	                      ) AS A
	                       CROSS APPLY xml_Data.nodes('/X') AS m(n)
	                       WHERE type = 'Movie' 
				     AND 
				     country LIKE '%India%'
                  )
SELECT TOP 10 ActorName, COUNT(*) AS movie_count
FROM ActorCTE
GROUP BY ActorName
ORDER BY movie_count DESC;

---15.Categorize the content based on the presence of the keywords 'kill' and 'violence' in the description field. Label content containing these keywords as 'Bad' and all other content as 'Good'. Count how many items fall into each category.

SELECT type,
       COUNT(*) AS content_count,
	   CASE
	       WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad'
           ELSE 'Good'
       END AS category
FROM Netflix_N
GROUP BY type, (CASE
	       WHEN description LIKE '%kill%' OR description LIKE '%violence%' THEN 'Bad'
           ELSE 'Good'
               END 
)
ORDER BY type;
 

		
