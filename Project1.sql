/*
COVID-19 Data Analysis

Skills demonstrated: Joins, Common Table Expressions (CTEs), Temporary Tables, Window Functions, Aggregate Functions, Creating Views, and Data Type Conversions.

*/

-- Retrieve all records from the CovidDeaths dataset, excluding any entries without a specified continent
SELECT *
FROM Portfolio_Project.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 3,4;

-- Preview key COVID-19 statistics, including case counts, death counts, and population data
SELECT Location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_Project.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

-- Calculate the death rate among confirmed cases in the United States and other relevant locations
SELECT Location, date, total_cases, total_deaths, 
       (total_deaths / total_cases) * 100 AS DeathPercentage
FROM Portfolio_Project.CovidDeaths
WHERE location LIKE '%states%'
AND continent IS NOT NULL 
ORDER BY 1,2;

-- Determine the percentage of a country’s population that has contracted COVID-19
SELECT Location, date, Population, total_cases,  
       (total_cases / population) * 100 AS PercentPopulationInfected
FROM Portfolio_Project.CovidDeaths
ORDER BY 1,2;

-- Identify the countries with the highest COVID-19 infection rates relative to their population size
SELECT Location, Population, 
       MAX(total_cases) AS HighestInfectionCount,  
       MAX((total_cases / population) * 100) AS PercentPopulationInfected
FROM Portfolio_Project.CovidDeaths
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC;

-- Find the countries with the highest total COVID-19 death counts
SELECT Location, MAX(CAST(Total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM Portfolio_Project.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Compare total COVID-19 deaths across continents to identify the most impacted regions
SELECT continent, MAX(CAST(Total_deaths AS UNSIGNED)) AS TotalDeathCount
FROM Portfolio_Project.CovidDeaths
WHERE continent IS NOT NULL 
GROUP BY continent
ORDER BY TotalDeathCount DESC;

-- Compute global COVID-19 case and death totals, along with the overall fatality rate
-- 1 
SELECT SUM(new_cases) AS total_cases, 
       SUM(CAST(new_deaths AS UNSIGNED)) AS total_deaths, 
       SUM(new_deaths) / SUM(new_cases) * 100 AS DeathPercentage
FROM Portfolio_Project.CovidDeaths
WHERE continent IS NOT NULL 
ORDER BY 1,2;

-- 2 
SELECT Location, SUM(new_deaths) AS TotalDeathCount
FROM Portfolio_Project.CovidDeaths
WHERE continent IS NULL 
AND location NOT IN('World', 'European Union', 'International')
GROUP BY Location
ORDER BY TotalDeathCount DESC;

-- Track the number of people vaccinated in each country over time
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(IFNULL(vac.new_vaccinations, 0) AS UNSIGNED)) 
       OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Portfolio_Project.CovidDeaths dea
JOIN Portfolio_Project.CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL 
ORDER BY 2,3;

-- Use a Common Table Expression (CTE) to store cumulative vaccination data for later calculations
WITH PopvsVac AS (
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
           SUM(CAST(IFNULL(vac.new_vaccinations, 0) AS UNSIGNED)) 
           OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
    FROM Portfolio_Project.CovidDeaths dea
    JOIN Portfolio_Project.CovidVaccinations vac
        ON dea.location = vac.location AND dea.date = vac.date
    WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PopvsVac;

-- Create a temporary table to store vaccination data and perform calculations on it
DROP TEMPORARY TABLE IF EXISTS PercentPopulationVaccinated;
CREATE TEMPORARY TABLE PercentPopulationVaccinated (
    Continent VARCHAR(255),
    Location VARCHAR(255),
    Date DATE,
    Population DECIMAL(15,2),
    New_vaccinations DECIMAL(15,2),
    RollingPeopleVaccinated DECIMAL(15,2)
);

-- Insert cumulative vaccination data into the temporary table
INSERT INTO PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(IFNULL(vac.new_vaccinations, 0) AS DECIMAL(15,2))) 
       OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Portfolio_Project.CovidDeaths dea
JOIN Portfolio_Project.CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date;


-- Retrieve and display the percentage of each country’s population that has been vaccinated
SELECT *, (RollingPeopleVaccinated / Population) * 100 AS PercentPopulationVaccinated
FROM PercentPopulationVaccinated;

-- Create a view to store vaccination data for easier visualization and future queries
CREATE OR REPLACE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
       SUM(CAST(IFNULL(vac.new_vaccinations, 0) AS UNSIGNED)) 
       OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM Portfolio_Project.CovidDeaths dea
JOIN Portfolio_Project.CovidVaccinations vac
    ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL;
