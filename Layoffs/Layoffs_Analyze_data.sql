/*
Layoffs Project Part 2 - Data Analyzing
Debra Brewer
www.linkedin.com/in/debrabrewer/
debrabrewer.github.io/
github.com/DebraBrewer
AnalystDebra@gmail.com

NOTE: Use file layoffs_clean.csv and mySQL
*******************************************

Project part 1: Clean data **See Part 1 - PREVIOUS PROJECT**
Project Part 2: Analyze data **THIS PROJECT**

*******************************************
In this project, I will: 
	1) Initial analysis of data
	2) Examine 100% layoff (company failed)
	3) Examine by category (industry, country, year, stage)
	4) Calculated rolling total of layoffs by month
    5) Used CTE to find top 5 companies for layoffs in each year
*******************************************
*/

/*
******************************************* 
Step 1: 
Initial analysis of data
******************************************* 
*/

-- View data
SELECT *
FROM layoffs_staging_2;

-- Initial look at companies with a lot of people laid & percentage of people laid off
SELECT MAX(total_laid_off), MAX(percentage_laid_off)
FROM layoffs_staging_2;

/*
******************************************* 
Step 2: 
Examine 100% layoff (company failed)
******************************************* 
*/

-- List all companies that completely failed (100% job loss)
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY total_laid_off DESC;

-- Of companies that failed, which had a lot of funding
SELECT *
FROM layoffs_staging_2
WHERE percentage_laid_off = 1
ORDER BY funds_raised_millions DESC;

SELECT company, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY company
ORDER BY SUM(total_laid_off) DESC;

-- See the dates in this data: 3 years starting with COVID
SELECT MIN(`date`), MAX(`date`)
FROM layoffs_staging_2;

/*
******************************************* 
Step 3: 
Examine by category (industry, country, year, stage)
******************************************* 
*/

-- Look across multiple columns to see what had the most layoffs during COVID (industries, countries, etc)
-- For industry, showed most layoffs in consumer, then retail, other, transportation
SELECT industry, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY industry
ORDER BY SUM(total_laid_off) DESC;

--  For countries, showed most layoffs in United States, then India, Netherlands, Sweden
SELECT country, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY country
ORDER BY SUM(total_laid_off) DESC;

-- Showed 2022 had most laid off, but only 3 months for 2023, which was close to 2022 level
SELECT YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY YEAR(`date`)
ORDER BY SUM(total_laid_off) DESC;

-- For stage, showed Post-IPO had most layoffs
SELECT stage, SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY stage
ORDER BY SUM(total_laid_off) DESC;

/*
******************************************* 
Step 4: 
Calculated rolling total of layoffs by month
******************************************* 
*/

-- Progression of layoffs - rolling total by month
-- Shows total of 383K laid off
WITH Rolling_Total AS
(
SELECT SUBSTRING(`date`,1,7) AS `MONTH`, SUM(total_laid_off)AS total_off
FROM layoffs_staging_2
WHERE SUBSTRING(`date`,1,7)  IS NOT NULL
GROUP BY `MONTH`
ORDER BY 1 ASC
)
SELECT `MONTH`, total_off, SUM(total_off) OVER(ORDER BY `MONTH`) AS rolling_total
FROM Rolling_Total;

SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
ORDER BY 3 DESC;

/*
******************************************* 
Step 5: 
Used CTE to find top 5 companies for layoffs in each year
******************************************* 
*/

-- Multiple CTE to find the top 5 companies from each year that laid people off
-- 2020 showed Uber, Booking.com, Groupon, Swiffy, & AirBNB as the top 5
WITH Company_Year (company, years, total_laid_off) AS
(
SELECT company, YEAR(`date`), SUM(total_laid_off)
FROM layoffs_staging_2
GROUP BY company, YEAR(`date`)
), Company_Year_Rank AS
(
SELECT *, DENSE_RANK() OVER (PARTITION BY years ORDER BY total_laid_off DESC) AS Ranking
FROM Company_Year
WHERE years IS NOT NULL
)
SELECT *
FROM Company_Year_Rank
WHERE Ranking <=5;