/*
**************************************
Layoffs Project Part 1 - Data Cleaning
Debra Brewer
www.linkedin.com/in/debrabrewer/
debrabrewer.github.io/
github.com/DebraBrewer
AnalystDebra@gmail.com

NOTE: Use data file layoffs_dirty.csv and mySQL
**************************************

Project part 1: Clean data **THIS PROJECT**
Project Part 2: Analyze data **See Part 2 - NEXT PROJECT**

**************************************
In this project, I will: 
	1) Create new file with data
	2) Remove duplicate rows
	3) Standardizing data 
	4) Examine nulls and blank values
    5) Remove rows and columns
**************************************
*/

-- View data
SELECT *
FROM layoffs
LIMIT 1000;

/*
************************************************** 
Step 1: 
Save copy of raw data before manipulating data set 
************************************************** 
*/


CREATE TABLE layoffs_staging
LIKE layoffs;

SELECT *
FROM layoffs_staging
LIMIt 1000;

INSERT layoffs_staging
SELECT *
FROM layoffs;

/*
******************************* 
Step 2: 
Remove Duplicate rows from data 
******************************* 
*/

-- Note: First, I used fewer columns to find duplicate rows.  I tested the company "Oda" and realized I needed to analyze all of the columns in order to find duplicate rows.

-- Search for duplicate rows
SELECT *
FROM (
	SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging
) duplicates
WHERE 
	row_num > 1;

-- Test using company "Casper"

SELECT * 
FROM layoffs_staging
WHERE company = 'Casper';

-- Delete duplicate rows by creating 2nd table

CREATE TABLE `layoffs_staging_2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` int
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

INSERT INTO layoffs_staging_2
SELECT *,
		ROW_NUMBER() OVER (
			PARTITION BY company, location, industry, total_laid_off, percentage_laid_off, `date`, stage, country, funds_raised_millions
			) AS row_num
	FROM 
		world_layoffs.layoffs_staging;
        
SELECT *
FROM layoffs_staging_2
WHERE row_num > 1;

DELETE
FROM layoffs_staging_2
WHERE row_num > 1;

SELECT *
FROM layoffs_staging_2;

/*
******************************* 
Step 3: 
Standardizing data 
******************************* 
*/

-- Clean company column
-- Remove extra space at beginning

SELECT company, TRIM(company)
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET company = TRIM(company);

SELECT DISTINCT industry
FROM layoffs_staging_2
ORDER BY 1;

-- Clean industry column to combine similar names
-- Only problem is 3 different naming conventions of "crypto"

SELECT *
FROM layoffs_staging_2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging_2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Clean country column
-- Only problem is 4 rows with "United States." rather than "United States"

SELECT DISTINCT country
From layoffs_staging_2
ORDER By 1;

SELECT country, COUNT(country)
FROM layoffs_staging_2
WHERE country LIKE 'United States%'
GROUP BY country
ORDER BY 1;

SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging_2
WHERE country LIKE 'United States%'
ORDER BY 1;

UPDATE layoffs_staging_2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%'; 

-- Date column wrong format
-- Change date column from text to date, both the data and the data type

SELECT `date`, STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging_2;

UPDATE layoffs_staging_2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

SELECT `date`
FROM layoffs_staging_2;

ALTER TABLE layoffs_staging_2
MODIFY COLUMN `date` DATE;

/*
******************************* 
Step 4: 
Nulls and blank values
******************************* 
*/

-- Some industries blank or null
-- Used Airbnb as our sample to test
-- Found same company in other rows and copied label for industry

SELECT *
FROM layoffs_staging_2
WHERE industry IS NULL
	OR industry = '';
    
SELECT *
FROM layoffs_staging_2
WHERE company = 'Airbnb';

SELECT t1.company, t1.industry, t2.industry, t1.location
FROM layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
    AND t1.location = t2.location
WHERE (t1.industry IS NULL OR t1.industry = '')
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging_2
SET industry = NULL
WHERE industry = '';

UPDATE layoffs_staging_2 t1
JOIN layoffs_staging_2 t2
	ON t1.company = t2.company
    SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;  

-- This company doesn't have any duplicate data, so it is still null

SELECT *
FROM layoffs_staging_2
WHERE company LIKE 'Bally%';  

-- Could populate data between total laid off and percentage laid off IF we had data for total employees
-- Since we don't, this null data cannot be filled

SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL 
	OR percentage_laid_off IS NULL;

/*
******************************* 
Step 5: 
Remove rows and columns
******************************* 
*/

-- Both total laid off and percentage laid off null, we don't know how many laid off
-- Goal of data set is to examine laid off, so these rows are unneeded

SELECT *
FROM layoffs_staging_2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;
    
DELETE
FROM layoffs_staging_2
WHERE total_laid_off IS NULL 
	AND percentage_laid_off IS NULL;
    
-- Remove our row_num column that we created to remove duplicate rows

ALTER TABLE layoffs_staging_2
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging_2;

/*
END of data cleaning
SEE Part 2 for in depth analysis of data
*/
