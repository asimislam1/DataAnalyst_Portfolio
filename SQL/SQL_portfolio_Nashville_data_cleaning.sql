--================================================
-- DATA ANALYST PORTFOLIO PROJECT
-- data cleaning
-- https://www.kaggle.com/datasets/tmthyjames/nashville-housing-data
--================================================


--================================================
--  IMPORT DATA
--================================================
-- create tables - Import data from Excel
-- "Nashville_housing_data_2013_2016.csv"
--  CREATE DATABASE
--- open SSMS and connect to server
--- right-click Databases, new database and enter "PortfolioProject"

--  IMPORT FROM EXCEL
--- right-click on "PortfolioProject", Tasks, Import data
--- data source is an Microsoft Excel
--- select PATH and ".xlsx" file
--- destination is "Microsoft OLE DB Provider for SQL Server"
--- make sure server name (and database) are correct
--- database:  "PortfolioProject" or whichever database is being used
--- press the nexts till Finish, Perform Operations
--- refresh Tables in Database

-- rename tables (take out $ at end of name)
-- may need to restart SSMS
--================================================



--================================================
--  DATA CLEANING 
--================================================
-- select database
USE PortfolioProject;


------------------------------------------------
--  check table
------------------------------------------------
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'NashvilleHousing'

SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'NashvilleHousing'
	AND COLUMN_NAME LIKE '%sale%'
	 OR COLUMN_NAME LIKE '%BATH%'


select top(10) ParcelID, LandUse, SalePrice, SoldAsVacant, YearBuilt, Bedrooms
	from NashvilleHousing       
	order by 3,4
------------------------------------------------



------------------------------------------------
-- standardize the date format
------------------------------------------------
select top(10) SaleDate, convert(Date, SaleDate) from NashvilleHousing

-- update did not do anything even tough it says (56477 rows affected)
update NashvilleHousing set SaleDate = convert(date, SaleDate);

-- add columns and update values
alter table NashvilleHousing drop column if exists SaleDateConverted;
alter table NashvilleHousing add SaleDateConverted Date;

update NashvilleHousing set SaleDateConverted = convert(date, SaleDate);

select top(10) SaleDate, SaleDateConverted from NashvilleHousing;

SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'NashvilleHousing' 
	AND COLUMN_NAME LIKE '%Sale%' ;
------------------------------------------------


------------------------------------------------
-- populate property address data
------------------------------------------------
select top(10) PropertyAddress from NashvilleHousing
select top(10) * from NashvilleHousing where PropertyAddress is null

-- explore how to fill out PropertyAddress = NULL fields
select * from NashvilleHousing order by ParcelID 
-- 025 07 0 031.00 has two entries, one NULL and one with ADDRESS
select * from NashvilleHousing where ParcelID = '025 07 0 031.00'


-- find the PropertyAddress = NULL values using a self join
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
    ISNULL(a.PropertyAddress, b.PropertyAddress)  -- return "b" is "a" is NULL
from NashvilleHousing a
join NashvilleHousing b
	on  a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is NULL


-- update a.PropertyAddress with b.PropertyAddress
update a    -- use alias
-- ISNULL returns "b" is "a" is NULL
-- ISNULL(a.PropertyAddress, "no address")
set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
from NashvilleHousing a
join NashvilleHousing b
	on  a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is NULL


-- check for NULL values
select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress,
    ISNULL(a.PropertyAddress, b.PropertyAddress)  -- return "b" is "a" is NULL
from NashvilleHousing a
join NashvilleHousing b
	on  a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ]
where a.PropertyAddress is NULL
------------------------------------------------


------------------------------------------------
-- breakout address into individual columns (address, city, state)
------------------------------------------------
select top(500) PropertyAddress from NashvilleHousing

select 
	substring(PropertyAddress, 1, charindex(',', PropertyAddress)  -1) as Address,
	substring(PropertyAddress, charindex(',', PropertyAddress) + 1, LEN(PropertyAddress)) as Address
from NashvilleHousing


-- add columns and update values
alter table NashvilleHousing 
	drop column if exists PropertySplitAddress, 
		 column if exists PropertySplitCity;

alter table NashvilleHousing add 
	PropertySplitAddress nvarchar(255),
	PropertySplitCity    nvarchar(255);

-- set values for  PropertySplitAddress and PropertySplitCity
update NashvilleHousing set
	PropertySplitAddress = substring(PropertyAddress, 1, charindex(',', PropertyAddress)  -1),
	PropertySplitCity    = substring(PropertyAddress, charindex(',', PropertyAddress) + 1, LEN(PropertyAddress));

select top(50) PropertyAddress, PropertySplitAddress, PropertySplitCity from NashvilleHousing


-- use OwnerAddress using PARSENAME 
-- works only with period, need REPLACE statement
-- works backwards
select OwnerAddress from NashvilleHousing

select PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) as ParseState,  -- state
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) as ParseCity,   -- city
	   PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) as ParseAddr    -- address
from NashvilleHousing

-- add columns and update values
alter table NashvilleHousing 
	drop column if exists OwnerSplitAddress, 
		 column if exists OwnerSplitCity,
		 column if exists OwnerSplitState;

alter table NashvilleHousing add 
	OwnerSplitAddress nvarchar(255),
	OwnerSplitCity    nvarchar(255),
	OwnerSplitState   nvarchar(255);

-- set values for  PropertySplitAddress and PropertySplitCity
update NashvilleHousing set
	 OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
	 OwnerSplitCity    = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
	 OwnerSplitState   = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

select OwnerAddress, OwnerSplitAddress, OwnerSplitCity, OwnerSplitState 
from NashvilleHousing

SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'NashvilleHousing' 
	AND COLUMN_NAME LIKE '%Address%' 
	OR  COLUMN_NAME LIKE '%Split%' 
------------------------------------------------


------------------------------------------------
-- sold as vacant field, change Y/N to Yes/No
------------------------------------------------
select distinct(SoldAsVacant), count(SoldAsVacant) 
from NashvilleHousing
group by SoldAsVacant
order by 2 desc

-- check case statement
select SoldAsVacant, 
case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end
from NashvilleHousing

-- update with case statements
update NashvilleHousing set SoldAsVacant = 
case
	when SoldAsVacant = 'Y' then 'Yes'
	when SoldAsVacant = 'N' then 'No'
	else SoldAsVacant
end

-- check after updates
select distinct(SoldAsVacant), count(SoldAsVacant) 
from NashvilleHousing
group by SoldAsVacant
order by 2 desc
------------------------------------------------


------------------------------------------------
-- remove duplicates
-- not common to do
------------------------------------------------
select *,
	ROW_NUMBER() OVER (
	partition by ParcelID,
				 PropertyAddress,
				 SaleDate,
				 LegalReference
				 order by UniqueID
				 ) row_num
from NashvilleHousing
order by ParcelID


-- use with CTE (use one time only)
go
with RowNumCTE AS (
select *,
	ROW_NUMBER() OVER (
	partition by ParcelID,
				 PropertyAddress,
				 SaleDate,
				 LegalReference
				 order by UniqueID
				 ) row_num
from NashvilleHousing
--order by ParcelID
)
delete from RowNumCTE 
where row_num > 1
--order by PropertyAddress
------------------------------------------------


------------------------------------------------
-- delete unused columns
-- not common to do
------------------------------------------------
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'NashvilleHousing' 
	AND COLUMN_NAME LIKE '%Address%' 
	OR  COLUMN_NAME LIKE '%Tax%'
	OR  COLUMN_NAME LIKE '%Buil%'


-- drop columns
-- alter table NashvilleHousing
-- drop column TaxDistrict, BuildingValue


SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'NashvilleHousing' 
	AND COLUMN_NAME LIKE '%Address%' 
	OR  COLUMN_NAME LIKE '%Tax%'
	OR  COLUMN_NAME LIKE '%Buil%'
------------------------------------------------



------------------------------------------------
--  final check
------------------------------------------------
SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS
	WHERE TABLE_NAME = 'NashvilleHousing' 
	
SELECT top(20) * FROM NashvilleHousing
------------------------------------------------
--================================================

select SaleDateConverted from NashvilleHousing
--================================================
--  EXPORT TABLE
--================================================
--  EXPORT TO EXCEL
--- right-click on "PortfolioProject", Tasks, Export data
--- data source is "Microsoft OLE DB Provider for SQL Server"
--- make sure server name (and database) are correct
--- database:  "PortfolioProject" or whichever database is being used
--- destination is "Microsoft Excel"
--- enter PATH and ".xlsx" file, click next
--- select "copy data from one or more tables or views", click next
--- select the table(s)
--  enter new destination table name(s), click next, next
--- click Finish (run immediately)
--- manually check the exported excel file
--================================================