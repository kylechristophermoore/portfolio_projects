/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

SELECT *
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--SELECT *
--FROM portfolio_project..covid_vaccinations
--ORDER BY 3,4

-- Select the data that we are going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
ORDER BY 1, 2

-- Looking at the total cases vs total deaths
-- Shows likelihood of dying given contracting covid

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_percentage
FROM portfolio_project..covid_deaths
WHERE location = 'United States' 
	AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at the total cases vs population
-- Shows % of population that contracted covid

SELECT location, date, population, total_cases, (total_cases / population) * 100 AS percent_population_infected
FROM portfolio_project..covid_deaths
WHERE location = 'United States'
	AND continent IS NOT NULL
ORDER BY 1, 2

-- Looking at countries with highest infeciton rate compared to poplulation

SELECT location, population, MAX(total_cases) AS highest_infeciton_count, 
	MAX(total_cases / population) * 100 AS percent_population_infected
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_population_infected DESC

-- Shows the countries with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) as total_death_count
FROM portfolio_project..covid_deaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY total_death_count DESC

-- Breaking down by continent

-- Showing contintents with the highest death count per population

SELECT location, MAX(CAST(total_deaths AS int)) as total_death_count
FROM portfolio_project..covid_deaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
GROUP BY location
ORDER BY total_death_count DESC

-- Global numbers

-- By date

SELECT date, SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, 
	SUM(CAST(new_deaths as int)) / SUM(new_cases) * 100 AS death_percentage
FROM portfolio_project..covid_deaths
--Where location like '%states%'
WHERE continent IS NOT null
GROUP BY date
ORDER BY 1, 2

-- Totals

SELECT SUM(new_cases) as total_cases, SUM(CAST(new_deaths as int)) AS total_deaths, 
	SUM(CAST(new_deaths as int)) / SUM(new_cases) * 100 AS death_percentage
FROM portfolio_project..covid_deaths
--Where location like '%states%'
WHERE continent IS NOT null
ORDER BY 1, 2


-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) rolling_vaccinations
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
ORDER BY 2, 3

-- Using CTE to perform Calculation on Partition By in previous query

WITH pop_vs_vac (continent, location, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) rolling_vaccinations
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null
)
SELECT *
	, (rolling_vaccinations / population) * 100 rolling_vaccination_percent
FROM pop_vs_vac

-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table IF exists #percent_population_vaccinated
CREATE Table #percent_population_vaccinated
(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccinations numeric,
rolling_vaccinations numeric
)

Insert into #percent_population_vaccinated
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) rolling_vaccinations
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null

SELECT *
	, (rolling_vaccinations / population) * 100 rolling_vaccination_percent
FROM #percent_population_vaccinated


-- Creating View to store data for later visualizations

-- Total death counts per continent

CREATE VIEW continent_total_deaths AS
SELECT location, MAX(CAST(total_deaths AS int)) as total_death_count
FROM portfolio_project..covid_deaths
WHERE continent IS NULL
	AND location NOT LIKE '%income%'
GROUP BY location
--ORDER BY total_death_count DESC

-- Percentage of population vaccinated

CREATE VIEW percent_population_vaccinated AS
SELECT dea.continent
	, dea.location
	, dea.date
	, dea.population
	, vac.new_vaccinations
	, SUM(CONVERT(bigint, vac.new_vaccinations)) 
		OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) rolling_vaccinations
FROM portfolio_project..covid_deaths dea
JOIN portfolio_project..covid_vaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT null