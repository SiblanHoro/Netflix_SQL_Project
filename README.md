# Netflix Movies and TV Shows Data Analysis using SQL

![](https://github.com/najirh/netflix_sql_project/blob/main/logo.png)

## Overview
This project involves a comprehensive analysis of Netflix's movies and TV shows data using SQL. The goal is to extract valuable insights and answer various business questions based on the dataset. The following README provides a detailed account of the project's objectives, business problems, solutions, findings, and conclusions.

## Objectives

- Analyze the distribution of content types (movies vs TV shows).
- Identify the most common ratings for movies and TV shows.
- List and analyze content based on release years, countries, and durations.
- Explore and categorize content based on specific criteria and keywords.

## Dataset

The data for this project is sourced from the Kaggle dataset:

- **Dataset Link:** [Movies Dataset](https://www.kaggle.com/datasets/shivamb/netflix-shows?resource=download)

## Schema

```sql
DROP TABLE IF EXISTS Netflix_N;
CREATE TABLE Netflix_N
(
    show_id      VARCHAR(5),
    type         VARCHAR(10),
    title        VARCHAR(250),
    director     VARCHAR(550),
    casts        VARCHAR(1050),
    country      VARCHAR(550),
    date_added   VARCHAR(55),
    release_year INT,
    rating       VARCHAR(15),
    duration     VARCHAR(15),
    listed_in    VARCHAR(250),
    description  VARCHAR(550)
);
```

## Business Problems and Solutions

### 1. Count the Number of Movies vs TV Shows

```sql
SELECT
     type,
     COUNT(*) AS Num_Of_content
FROM Netflix_N
GROUP BY type;
```
**Objective:** Determine the distribution of content types on Netflix.

### 2. Find the Most Common Rating for Movies and TV Shows

```sql
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
```

**Objective:** Identify the most frequently occurring rating for each type of content.

### 3. List All Movies Released in a Specific Year (e.g., 2020)

```sql
SELECT * 
FROM netflix
WHERE release_year = 2020;
```
**Objective:** Retrieve all movies released in a specific year.

### 4. Find the Top 5 Countries with the Most Content on Netflix

```sql
WITH countryList AS (
                    SELECT LTRIM(RTRIM(m.n.value('.', 'VARCHAR(30)'))) AS countryName
					          FROM
                       (
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
```

**Objective:** Identify the top 5 countries with the highest number of content items.

### 5. Identify the Longest Movie

```sql
SELECT *
FROM Netflix_N
WHERE 
    type = 'Movie' 
	AND 
	duration = (SELECT MAX(duration) FROM Netflix_N);
```
**Objective:** Find the movie with the longest duration.

### 6. Find Content Added in the Last 5 Years

```sql
SELECT *
FROM Netflix_N
WHERE YEAR(date_added) >= DATEDIFF(yy, date_added, GETDATE()) - 5
```
**Objective:** Retrieve content added to Netflix in the last 5 years.

### 7. Find All Movies/TV Shows by Director 'Rajiv Chilaka'

```sql
SELECT * 
FROM Netflix_N
WHERE 
    director LIKE '%Rajiv Chilaka%'
```

**Objective:** List all content directed by 'Rajiv Chilaka'.

### 8. List All TV Shows with More Than 5 Seasons

```sql
SELECT * 
FROM Netflix_N
WHERE 
     type = 'TV Show' 
	 AND 
	 CAST(LEFT(duration, CHARINDEX(' ', duration) - 1) AS INT) > 5
```

**Objective:** Identify TV shows with more than 5 seasons.

### 9. Count the Number of Content Items in Each Genre

```sql
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
```
**Objective:** Count the number of content items in each genre.

### 10.Find each year and the average numbers of content release in India on netflix, return top 5 year with highest avg content release!

```sql
SELECT TOP 5 YEAR(CONVERT(DATE, date_added)) AS Year,
     COUNT(*) AS yearly_content,
     CAST(COUNT(*) *100 /(SELECT COUNT(*) FROM Netflix_N WHERE country = 'India') AS FLOAT) 
AS Avg_content_percentage
from Netflix_N 
WHERE 
     country = 'India'
GROUP BY YEAR(CONVERT(DATE, date_added))
ORDER BY Avg_content_percentage DESC;
```
**Objective:** Calculate and rank years by the average number of content releases by India.

### 11. List All Movies that are Documentaries

```sql
SELECT * 
FROM Netflix_N
WHERE 
     type = 'Movie' 
     AND 
	   listed_in LIKE '%Documentaries%'
```
**Objective:** Retrieve all movies classified as documentaries.

### 12. Find All Content Without a Director

```sql
SELECT * 
FROM netflix
WHERE director IS NULL;
```
**Objective:** List content that does not have a director.

### 13. Find How Many Movies Actor 'Salman Khan' Appeared in the Last 10 Years

```sql
SELECT * 
FROM Netflix_N
WHERE
     cast LIKE '%Salman Khan%'
	   AND
	   type = 'Movie'
	   AND 
     release_year > DATEDIFF(yy, date_added, GETDATE()) - 10;
```
**Objective:** Count the number of movies featuring 'Salman Khan' in the last 10 years.

### 14. Find the Top 10 Actors Who Have Appeared in the Highest Number of Movies Produced in India

```sql
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
```
**Objective:** Identify the top 10 actors with the most appearances in Indian-produced movies.

### 15. Categorize Content Based on the Presence of 'Kill' and 'Violence' Keywords

```sql
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
```

**Objective:** Categorize content as 'Bad' if it contains 'kill' or 'violence' and 'Good' otherwise. Count the number of items in each category.

## Findings and Conclusion

- **Content Distribution:** The dataset contains a diverse range of movies and TV shows with varying ratings and genres.
- **Common Ratings:** Insights into the most common ratings provide an understanding of the content's target audience.
- **Geographical Insights:** The top countries and the average content releases by India highlight regional content distribution.
- **Content Categorization:** Categorizing content based on specific keywords helps in understanding the nature of content available on Netflix.

This analysis provides a comprehensive view of Netflix's content and can help inform content strategy and decision-making.

