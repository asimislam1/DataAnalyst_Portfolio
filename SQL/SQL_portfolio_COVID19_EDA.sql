-- select database
USE PortfolioProject;

------------------------------------------------
-- create tables - Import from Excel
------------------------------------------------
--  CREATE DATABASE
--- open SSMS and connect to server
--- right-click Databases, new database and enter "PortfolioProject"

--  IMPORT FROM EXCEL
--- right-click on "PortfolioProject", Tasks, Import data
--- data source is an Microsoft Excel
--- select PATH and ".xlsx" file
--- destination is "Microsoft OLE DB Provider for SQL Server"
--- database:  "PortfolioProject" or whichever database is being used
--- make sure server name and database are correct
--- press the nexts till Finish, Perform Operations
--- refresh Tables in Database

-- rename tables (take out $ at end of name)
-- may need to restart SSMS
------------------------------------------------
--================================================


-----------------------------------------------
-- add total_cases column to CovidDeaths
-- SSMS displays the column but cannot calculate off of it
-- manually add in Excel and re-import table
-- DROP TABLE IF EXISTS CovidDeaths;
------------------------------------------------
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'CovidDeaths' AND COLUMN_NAME LIKE '%total%'

--ALTER TABLE CovidDeaths 
--DROP COLUMN IF EXISTS total_cases;
--ALTER TABLE CovidDeaths ADD total_cases int
--UPDATE CovidDeaths SET total_cases = total_cases_per_million * population/1000000

--SELECT TOP(10) location, total_cases_per_million, population, 
--	total_cases, total_deaths, 
--	(total_deaths/total_cases)*100 AS DeathPercentage
--FROM CovidDeaths
--WHERE location LIKE '%states%'
--ORDER BY location
-- refresh table:  Cntl+Shift+R
------------------------------------------------



-- check tables
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'CovidDeaths'
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'CovidVaccinations'

SELECT * FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'CovidDeaths' AND ORDINAL_POSITION IN ('3', '4')


select top(10) location, date, total_cases, total_deaths, population 
	from CovidDeaths       
	order by 3,4
select top(10) location, date, continent, total_tests, tests_per_case
	from CovidVaccinations 
	order by 3,4

	
-- total cases per population
-- shows what population got covid
select top(200) location, date, population, total_cases, 
	(total_cases/population)*100 as DeathPercentage 
from CovidDeaths 
where location like '%states%'  -- united states
order by 1,2 desc


-- Total Cases vs Total Deaths:  percentage of deaths
-- shows likelyhood of dying if you contract covid
select location, date, total_cases, total_deaths, population,
(total_deaths/total_cases)*100 as DeathPercentage
from CovidDeaths 
where continent is not null and 
	  location like '%states%'  -- united states
order by 1,2 


-- show country with highest infection rate per population
-- overall, not date specific
select location, population,  
max((total_cases)) as HighestInfectionCount,
max((total_cases/population)*100) as PercentagePopulationInfected
from CovidDeaths 
where continent is not null
group by location, population
order by PercentagePopulationInfected desc


-- show country with highest death count per population
-- overall, not date specific
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths 
where continent is not null
group by location, population
order by TotalDeathCount desc

-- look at continents only
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths 
where continent is not null
group by continent
order by TotalDeathCount desc

-- look at continents only (more accurate)
select location, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths 
where continent is null
group by location
order by TotalDeathCount desc

-- look at countries in North America 
select location, continent, max(cast(total_deaths as int)) as TotalDeathCount
from CovidDeaths 
where continent like '%north%'
group by location, continent
order by TotalDeathCount desc




-- GLOBAL NUMBERS
-- use NULLIF for "Divide by zero error encountered" error
-- SUM(new_cases) = total_cases
select  date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
(SUM(cast(new_deaths as int)*100)/SUM(NULLIF(new_cases, 0))) as DeathPercentage
from CovidDeaths 
where continent is not null 
group by date
order by 1,2

-- worldwide - total death percentage
select  SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, 
(SUM(cast(new_deaths as int)*100)/SUM(NULLIF(new_cases, 0))) as DeathPercentage
from CovidDeaths 
where continent is not null 
order by 1,2


-- JOIN the two tables
-- vac.new_vaccinations rolling total:
--     o  use BigInt and 
--     o  "order by dea.location, dea.date" in PARTITION
-- using CAST or CONVERT
select dea.continent, dea.location, dea.date, dea.population,
   vac.new_vaccinations, 
   --SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location 
   SUM(convert(bigint, vac.new_vaccinations)) over (partition by dea.location
       order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null 
   --and vac.new_vaccinations is not null
   and dea.location like '%albania%'
order by 2,3


--  CTE
-- can be used only one time per final select statement
-- columns in CTE must match columns in select statement
-- may need a GO before WITH statement
go
WITH PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as 
(
select dea.continent, dea.location, dea.date, dea.population,
   vac.new_vaccinations, 
   SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location 
       order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null 
)
select *, (RollingPeopleVaccinated/population)*100 from PopvsVac
where new_vaccinations is not null


-- TEMP TABLE  #PercentPopulationVaccinated
drop table if exists #PercentPopulationVaccinated
create table #PercentPopulationVaccinated
(
continent varchar(255),
location  varchar(255),
date      datetime,
population numeric,
new_vaccinations  numeric,
RollingPeopleVaccinated  numeric
)

insert into #PercentPopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population,
   vac.new_vaccinations, 
   SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location 
       order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null 
order by 2,3

select *, (RollingPeopleVaccinated/population)*100 from #PercentPopulationVaccinated
where new_vaccinations is not null;



-- VIEWS
-- may need a GO before CREATE VIEW statement
-- may need a GO after CREATE VIEW statement
drop view if exists PercentPopulationVaccinated
go

create view PercentPopulationVaccinated 
as
(
select dea.continent, dea.location, dea.date, dea.population,
   vac.new_vaccinations, 
   SUM(cast(vac.new_vaccinations as bigint)) over (partition by dea.location 
       order by dea.location, dea.date) as RollingPeopleVaccinated
from CovidDeaths as dea
join CovidVaccinations as vac
   on dea.location = vac.location
   and dea.date = vac.date
where dea.continent is not null 
)
go


select top(20) * from PercentPopulationVaccinated
where new_vaccinations is not null
--================================================


