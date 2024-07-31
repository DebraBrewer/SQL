/* 
**************************************************
Housing (Nashville) - Data Cleaning
Debra Brewer
www.linkedin.com/in/debrabrewer/
debrabrewer.github.io/
github.com/DebraBrewer
AnalystDebra@gmail.com

NOTE: Use file nashville.xlsx and SQL Server
**************************************************
In this project, I will: 
	1) Standardize date format
	2) Populate property address data
	3) Breaking Address into parts (address, city, state)
	4) Change "Y" and "N" to "Yes" and "No" (for "Sold as vacant" field)
    5) Remove duplicates
    6) Delete unused columns
**************************************************
*/

-- View data
SELECT *
FROM nashville
LIMIT 1000;

/*
************************************************** 
Step 1: 
Remove unneeded time and create new date column
************************************************** 
*/

SELECT saledateconverted, CONVERT(Date,SaleDate)
From Nashville;

ALTER TABLE Nashville
ADD saledateconverted Date;

UPDATE Nashville
SET SaleDateConverted = CONVERT(date,saledate);

/*
************************************************** 
Step 2: 
Populate Property Address data
************************************************** 
*/

-- Note: 29 rows with NULL for property address
SELECT DISTINCT a.parcelID, a.propertyaddress, b.parcelID, b.PropertyAddress
FROM Nashville a
	INNER JOIN Nashville b
		ON a.parcelID = b.parcelID
		AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.Propertyaddress IS NULL AND b.propertyaddress IS NOT NULL 
	AND a.parcelID = b.ParcelID;

Update a
SET a.PropertyAddress = b.PropertyAddress
FROM Nashville a
	INNER JOIN Nashville b
		ON a.parcelID = b.parcelID
		AND a.[UniqueID ]<>b.[UniqueID ]
WHERE a.Propertyaddress IS NULL AND b.propertyaddress IS NOT NULL 
	AND a.parcelID = b.ParcelID;

/*
************************************************** 
Step 3: 
Break Address into parts (address, city, state)
************************************************** 
*/

-- Check the substrings to split Property Address into Street and City Address
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS StreetAddress
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS CityAddress
FROM Nashville

-- Create new table columns
ALTER TABLE dbo.Nashville
ADD PropertyStreetAddress NVARCHAR(255)
	, PropertyCityAddress NVARCHAR(255);

-- Store the new substrings into the correct columns
UPDATE Nashville
SET PropertyStreetAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)
	, PropertyCityAddress = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress));

-- Check split to ensure it matches
SELECT SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS StreetAddress
	, PropertyStreetAddress
	, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS CityAddress
	, PropertyCityAddress
FROM Nashville;

-- Check Parsename to split Owner Address into Street, City, and State Address
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM Nashville;

-- Create new table columns
ALTER TABLE dbo.Nashville
ADD OwnerStreetAddress NVARCHAR(255)
	, OwnerCityAddress NVARCHAR(255)
	, OwnerStateAddress NVARCHAR(255);

-- Store the new parsed address into the correct columns
UPDATE Nashville
SET OwnerStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
	, OwnerCityAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
	, OwnerStateAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Check work to ensure it matches
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)
	, OwnerStreetAddress
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)
	, OwnerCityAddress
	, PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
	, OwnerStateAddress
FROM Nashville;

/*
************************************************** 
Step 4
Change "Y" and "N" to "Yes" and "No" (for "Sold as vacant" field)
************************************************** 
*/

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM Nashville
GROUP BY SoldAsVacant
Order by 2;

SELECT SoldAsVacant,
(
	Case
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
)
FROM Nashville;

UPDATE Nashville
SET SoldAsVacant = Case
	WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

/*
**************************************************
Step 5: 
Remove duplicate rows
************************************************** 
*/

-- Find duplicate rows
WITH CTE AS(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress,SalePrice,SaleDate
		, LegalReference ORDER BY UniqueID) AS row_num
	FROM Nashville
)
SELECT *
FROM CTE
WHERE row_num > 1
ORDER BY PropertyAddress;

-- Delete duplicate rows
WITH CTE AS(
	SELECT *, ROW_NUMBER() OVER (PARTITION BY ParcelID, PropertyAddress,SalePrice,SaleDate
		, LegalReference ORDER BY UniqueID) AS row_num
	FROM Nashville
)
DELETE
FROM CTE
WHERE row_num > 1;

/*
**************************************************
Step 6: 
Delete unused columns
************************************************** 
*/

-- See table to decide which columns are unneeded.
SELECT *
FROM Nashville;

-- Remove the Owner and Proeprty address that was split, sale date that was altered, and tax district that is unneeded
ALTER TABLE Nashville
DROP COLUMN OwnerAddress,TaxDistrict, PropertyAddress, SaleDate;
