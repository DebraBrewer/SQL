/*
**************************************
COVID 19 Analysis using Deaths and Vaccination by Country/region
Debra Brewer
www.linkedin.com/in/debrabrewer/
debrabrewer.github.io/
github.com/DebraBrewer
AnalystDebra@gmail.com

NOTE: Use data file deaths.xlsx and vaccinations.xlsx with SQL Server
**************************************
In this project, I will: 
	1) Find highest percentage and number of cases or deaths
	2) Explore global numbers
	3) Explore percentage vaccinated using 3 techniques (Subquery, CTE, temptable)
	4) Create view to access data for later visualizations
**************************************
*/

-- View data
SELECT TOP 50*
FROM deaths;

SELECT TOP 50*
FROM vaccinations;

/*
************************************************** 
Step 1: 
Find highest percentage and number of cases or deaths
(Focus on continent and regions/countries)
************************************************** 
*/

-- Which countries had the highest percent of their population with COVID?
SELECT location, population, MAX(total_cases) AS 'Max Total Cases', ROUND(MAX((total_cases/population))*100,2) AS 'Percent of Cases'
FROM deaths
GROUP BY location, population
ORDER BY MAX((total_cases/population))*100 DESC;

-- Which countries had the highest number of deaths?
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathCount DESC;

-- Which continents had the highest number of deaths?
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent IS NULL AND location NOT IN ('World', 'European Union', 'International')
GROUP BY location
ORDER BY DeathCount DESC;

--  DRILL DOWN 
-- Which region/country had the highest number of deaths by continent?
-- 1) Europe
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent ='Europe'
GROUP BY location
ORDER BY DeathCount DESC;

-- 2) North America
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent ='North America'
GROUP BY location
ORDER BY DeathCount DESC;

-- 3) South America
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent ='South America'
GROUP BY location
ORDER BY DeathCount DESC;

-- 4) Asia
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent ='Asia'
GROUP BY location
ORDER BY DeathCount DESC;

-- 5) Africa
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent ='Africa'
GROUP BY location
ORDER BY DeathCount DESC;

-- 6) Oceania
SELECT location, MAX(cast(total_deaths as int)) AS DeathCount
FROM deaths
WHERE continent ='Oceania'
GROUP BY location
ORDER BY DeathCount DESC;

/*
************************************************** 
Step 2: 
Explore global numbers
************************************************** 
*/

-- Total numbers for all of covid
SELECT SUM(new_cases) AS total_cases, SUM(cast(new_deaths as int)) AS total_deaths
	, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM deaths
WHERE continent is not null 
ORDER BY 1, 2;

--  Global cases, vaccinations, and deaths from COVID by date (year, month)
SELECT YEAR(d.date) AS year, MONTH(d.date) AS month, SUM(d.new_cases) AS 'Number Cases COVID'
	, SUM(CAST(d.new_deaths AS int)) AS 'Number Deaths COVID', SUM(CASt(v.new_vaccinations as int)) AS 'Number vaccinated'
FROM deaths d
	LEFT JOIN vaccinations v
		ON d.date = v.date
		AND d.continent = v.continent
		AND d.location = v.location
WHERE d.continent IS NOT null
GROUP BY YEAR(d.date), MONTH(d.date)
ORDER BY YEAR(d.date), MONTH(d.date);


/*
************************************************** 
Step 3: 
Explore percentage vaccinated using 3 techniques 
(subquery, CTE, temptable)
************************************************** 
*/

-- How many people are vaccinated in each country? (by date)

-- using subquery
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
	, SUM(CONVERT(int, v.new_vaccinations)) OVER (Partition by d.location ORDER BY
		d.location, d.date) AS RollingPeopleVaccinated
FROM deaths	d
	INNER JOIN vaccinations v
		ON d.location = v.location
			AND d.date=v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3;

-- USING CTE
WITH PopvsVac (continent, Location, Date, Population, new_Vaccinations, RollingPeopleVaccinated)
AS (
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
	, SUM(CONVERT(int, v.new_vaccinations)) OVER (Partition by d.location ORDER BY
		d.location, d.date) AS RollingPeopleVaccinated
	FROM deaths	d
	INNER JOIN vaccinations v
		ON d.location = v.location
			AND d.date=v.date
	WHERE d.continent IS NOT NULL
)
SELECT *, ROUND((RollingPeopleVaccinated/Population)*100,2) AS PercentageVaccinated
FROM PopvsVac;

-- USING Temp table
DROP TABLE IF EXISTS #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(Continent nvarchar(255),
location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric)
Insert into #PercentPopulationVaccinated
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
	, SUM(CONVERT(int, v.new_vaccinations)) OVER (Partition by d.location ORDER BY
		d.location, d.date) AS RollingPeopleVaccinated
	FROM deaths	d
	INNER JOIN vaccinations v
		ON d.location = v.location
			AND d.date=v.date
SELECT *, ROUND((RollingPeopleVaccinated/Population)*100,2) AS PercentageVaccianted
FROM #PercentPopulationVaccinated
	WHERE continent IS NOT NULL;


/*
************************************************** 
Step 4: 
Create view to access data for later visualizations
************************************************** 
*/

-- CREATING VIEW to store data for later visualizations
DROP VIEW IF EXISTS PercentPopulationVaccinated;

CREATE VIEW PercentPopulationVaccinated AS
SELECT d.continent, d.location, d.date, d.population, v.new_vaccinations
	, SUM(CONVERT(int, v.new_vaccinations)) OVER (Partition by d.location ORDER BY
		d.location, d.date) AS RollingPeopleVaccinated
	FROM deaths	d
	INNER JOIN vaccinations v
		ON d.location = v.location
			AND d.date=v.date
	WHERE d.continent IS NOT NULL;

SELECT *
FROM PercentPopulationVaccinated;