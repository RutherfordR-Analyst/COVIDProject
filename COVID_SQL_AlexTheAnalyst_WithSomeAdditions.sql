---CHECK Total Cases vs	Total Deaths

SELECT
Location,
date,
total_cases,
total_deaths
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 1,2

---Global Numbers (Deaths) per day

SELECT 
date,
SUM(new_cases) AS total_cases,
SUM(cast(new_deaths as int)) AS total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1,2;

---Global Numbers over all as of Sept. 10, 2021

SELECT 
SUM(new_cases) AS total_cases,
SUM(cast(new_deaths as int)) AS total_deaths,
SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE continent is not NULL;

----Check Total Cases vs Total Deaths AND Death Percentage in the Philippines

SELECT 
Location,
date,
total_cases,
total_deaths,
(total_deaths/total_cases)*100 AS DeathPercentage
FROM CovidDeaths
WHERE location = 'Philippines'
ORDER BY date;

----Percent of Population who got COVID in the Philippines

SELECT 
Location,
date,
total_cases,
total_deaths,
(total_cases/population)*100 AS PopulationPercent
FROM CovidDeaths
WHERE location = 'Philippines'
ORDER BY date;

----HighestInfectionRate by Country

SELECT 
Location,
MAX(total_cases) AS HighestInfectionCount,
MAX((total_cases/population))*100 AS PopulationPercentage
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY Location
ORDER BY HighestInfectionCount DESC;

----Countries with Highest Death Count

SELECT
location,
MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC;

----Current Infection per Population by Country as of September 20, 2021

SELECT 
Location,
date,
total_cases,
(total_cases/population)*100 AS InfectionRate
FROM CovidDeaths
WHERE continent is not NULL AND date = '2021/9/10'
GROUP BY Location, date, total_cases, InfectionRate
ORDER BY InfectionRate DESC;

----Looking at Total Populaiton vs Vaccinations 

SELECT
dea.continent,
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingCountVaccinations, --- ADDS all new vaccinations in a country, and starts all over again once it reaches a new country in the column.
---(RollingCountVaccinations/population)*100 [this won't work since you can't access RollingCountVaccinations yet so we need to use CTE OR TEMP TABLE to access it]
FROM CovidDeaths dea
JOIN CovidVac vac ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not NULL
order by 2,3;

---Use CTE

With PopvsVac(Continent, Location, Date, Population, new_vaccinations, RollingCountVaccinations) ---Make sure the columns listed matches the columns listed in SELECT
AS (
SELECT
dea.continent,
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingCountVaccinations --- ADDS all new vaccinations in a country, and starts all over again once it reaches a new country in the column.
FROM CovidDeaths dea
JOIN CovidVac vac ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not NULL
) ---Needed to remove ORDER BY since query won't work with it.
SELECT  *, (RollingCountVaccinations/Population)*100
FROM PopvsVac


---TEMP TABLE Approach. In this case, one needs to specify the DATA TYPE of the columns. Use Columns Folder in the Explorer Pane to make it easier to assign data types.
--- I like the CTE better, since it's shorter and easier to understand. :P 

DROP TABLE IF EXISTS #PercentPopulationVaccinated --Drops the table first before creating it so in case you change something in the QUERY, it will still work.
CREATE TABLE #PercentPopulationVaccinated
(Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
population float, ---can use numeric as well
new_vaccinations numeric, ---changed it from nvarchar to numeric since it's the correct data type for the query) 
RollingCountVaccinations numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT
dea.continent,
dea.location, 
dea.date, 
dea.population, 
vac.new_vaccinations,
SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition by dea.Location ORDER BY dea.location, dea.date) AS RollingCountVaccinations --- ADDS all new vaccinations in a country, and starts all over again once it reaches a new country in the column.
FROM CovidDeaths dea
JOIN CovidVac vac ON dea.location = vac.location 
	AND dea.date = vac.date
WHERE dea.continent is not NULL

SELECT  *, (RollingCountVaccinations/Population)*100 AS PercentVaccinated
FROM #PercentPopulationVaccinated