Select *
From PortfolioProject..CovidDeaths
order by 3,4;

-- Select Data that we are going to be using
Select Location, date, total_cases, new_cases, total_deaths,population
From PortfolioProject..CovidDeaths
order by 1,2;


-- Looking at Total Cases vs Total Deaths

--Shows likelihood of dying if you catch covid in NZ
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage 
FROM PortfolioProject..CovidDeaths
Where location = 'New Zealand'
Order by 1,2;

-- Looking at Total Cases vs Population 
Select Location, date, population, total_cases,(total_deaths/population)*100 as Perecntage_Covidcases_Population 
FROM PortfolioProject..CovidDeaths
--Where location = 'New Zealand'
Order by 1,2;

-- Countires with highest infection rate
Select Location, population, MAX(total_cases) as Maxinfection, MAX((total_cases/population))*100 as Percent_Population_Infected
FROM PortfolioProject..CovidDeaths
GROUP BY Location, Population
Order by Percent_Population_Infected desc

-- Countries with the highest death count per Population
Select location, MAX(cast(total_deaths as int)) as Total_acculmulated_death, MAX(cast(population as int)) as population
FROM PortfolioProject..CovidDeaths
Where Continent is not null
GROUP BY location
Order by Total_acculmulated_death desc

-- Showing continents with the highest death count per population
Select Continent, MAX(cast(total_deaths as int)) as Total_Death_Count
From PortfolioProject..CovidDeaths
Where continent is not null
Group by Continent
Order by Total_death_count  desc

-- GLOBAL NUMBERS (Total case, death and Percentage)
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
From PortfolioProject..CovidDeaths
where continent is not null
order by 1,2

-- Looking at Total Population vs Vaccinations
With Population_vs_Vac (Continent, Location, Date, Population, New_vaccinations, Aggregate_People_Vaccinated)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location,dea.date) as Aggregate_People_Vaccinated
--(Aggregate_Of_People_Vaccinated/population)*100
From PortfolioProject.. CovidDeaths dea
Join PortfolioProject.. CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date	
WHERE dea.continent is not null
)
Select *, (Aggregate_People_vaccinated/Population)*100 as Percentage_People_Vaccinated
From Population_vs_Vac


-- Creating View for later
Create View Percentage_People_Vaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as bigint)) OVER (Partition by dea.location ORDER by dea.location,dea.date) as Aggregate_People_Vaccinated
--(Aggregate_Of_People_Vaccinated/population)*100
From PortfolioProject.. CovidDeaths dea
Join PortfolioProject.. CovidVaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date	
WHERE dea.continent is not null
