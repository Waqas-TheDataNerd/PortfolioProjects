----- Muhammad Waqas
----- COVID 19 Data Exploration
----- Source: https://ourworldindata.org/covid-deaths (Public)
------Data Extracted on March 4, 2022

----- Skills Used: Joins, CTE, Windows Function, Agreegate Functions, Creating Views, Converting Data Types


Select *
From [Portfolio Project]..CovidDeaths
Where continent is not null
Order By 3,4;

Select *
From [Portfolio Project]..CovidVaccinations
Order By 3,4;

---- COVID DEATHS TABLE

--- First, we will select the data that we would be using and order it by country name and date
Select Location, date, total_cases, new_cases, total_deaths, population
From [Portfolio Project]..CovidDeaths
Order By 1,2


---- Let's look at the total cases, total deaths and total cases vs. total deaths 
Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From [Portfolio Project]..CovidDeaths
Order By 1,2

----- Let's look at the percentage of the total population which contracted covid
Select Location, date, population, total_cases,(total_cases/population)*100 as Population_Contracted_Covid
From [Portfolio Project]..CovidDeaths
Order By 1,2

---- Let's see the countries with highest infection rate compared to the population, this time we would order by the percentpopulationaffected in descending order
Select Location, population, Max(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From [Portfolio Project]..CovidDeaths
Group By Location, population
Order By PercentPopulationInfected desc

---- Now we would see the countries with the highest death count per population, here too we will order by the total_death_count
Select Location, Max(cast(total_deaths as int)) as TotalDeathCount 
From [Portfolio Project]..CovidDeaths
Where continent is not null
Group By Location
Order By TotalDeathCount desc

---- Let's look continent wise.
----Showing continents with the highest for population
Select continent, Max(cast(total_deaths as int)) as TotalDeathCount 
From [Portfolio Project]..CovidDeaths
Where continent is not null
Group By continent
Order By TotalDeathCount desc

---- We will now look at the global numbers
----- First we will try to find out the total number of new cases reported each day. Since for each country we have total cases reported each day. So we can group by date and then simply use aggreegate functions.
Select date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_new_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From [Portfolio Project]..CovidDeaths
Where continent is not null
Group By date
Order by 1,2

---- Now let's look at the global picture. All we need to do now is to remove the group by function in previous query.
Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_new_deaths, (SUM(cast(new_deaths as int))/SUM(new_cases))*100 as DeathPercentage
From [Portfolio Project]..CovidDeaths
Where continent is not null
Order by 1,2

---- Merging the Vaccination and Deaths Table for further Insights.
--- First let's merge the tables. Since location and date are the common fields in both the tables we can use those to merge and can only select the columns which we would need. 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From [Portfolio Project]..CovidDeaths as dea
JOIN [Portfolio Project]..CovidVaccinations as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
Order by 2, 3

---- Let's see the total and rolling vaccinations for each country.
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, dea.date) as Rolling_People_Vaccinated
From [Portfolio Project]..CovidDeaths as dea
JOIN [Portfolio Project]..CovidVaccinations as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
Order by 2, 3

---- Since we can't use the Rolling_People_Vaccinated column directly therefore we need to create either a CTE or a Tempt Table. 

----- First let's use  CTE
With PopvsVac(continent, location, date, population, New_Vaccinations, Rolling_People_Vaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, dea.date) as Rolling_People_Vaccinated
From [Portfolio Project]..CovidDeaths as dea
JOIN [Portfolio Project]..CovidVaccinations as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
)
----Let's see if our CTE is working
Select *, (Rolling_People_Vaccinated/population)*100
from PopvsVac

--- CTE worked perfectly. We can try it with Tempt Table too. Let's see how to do that. 

Drop Table if exists Percent_Population_Vaccinated ---it is always a good practice to drop the table. Drop would not only delete the data but also would delete the table.
Create Table Percent_Population_Vaccinated
(
Continent nvarchar (255),
Location nvarchar (255),
Date datetime, 
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into Percent_Population_Vaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, dea.date) as Rolling_People_Vaccinated
	From [Portfolio Project]..CovidDeaths as dea
	JOIN [Portfolio Project]..CovidVaccinations as vac
		ON dea.location = vac.location 
		AND dea.date = vac.date

Select *
From Percent_Population_Vaccinated

---- Let's create a view which we can use later on.
Create view Vaccinated_Population as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.location Order BY dea.location, dea.date) as Rolling_People_Vaccinated
From [Portfolio Project]..CovidDeaths as dea
JOIN [Portfolio Project]..CovidVaccinations as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null

--- Let's see if our View was created.
Select * from Vaccinated_Population