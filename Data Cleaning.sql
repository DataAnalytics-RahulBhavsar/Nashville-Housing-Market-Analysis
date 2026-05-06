-- 1] Cleaning Part

SELECT * FROM [dirty Nashville Housing]

-- Copy of Table
SELECT * INTO Nashville_Housing 
FROM [dirty Nashville Housing]

SELECT * FROM Nashville_Housing

-- Cheaking Duplicate Values 
WITH UniqueIDNumber
AS (
SELECT UniqueID,
        ROW_NUMBER() OVER(PARTITION BY UniqueID ORDER BY UniqueID) AS RowNumber
FROM Nashville_Housing )
SELECT * FROM UniqueIDNumber
WHERE RowNumber > 1

-- Removing Duplicates (PropertyAddress)
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
FROM Nashville_Housing a
JOIN Nashville_Housing b
    ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
WHERE a.PropertyAddress IS NULL;

-- Split Property Address 
ALTER TABLE Nashville_Housing
ADD PropertySplitAddress NVARCHAR(255),
    PropertySplitCity NVARCHAR(255);

UPDATE Nashville_Housing
SET 
    PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1),
    PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress));

-- Split Owner Address 
ALTER TABLE Nashville_Housing
ADD OwnerSplitAddress NVARCHAR(255),
    OwnerSplitCity NVARCHAR(255),
    OwnerSplitState NVARCHAR(255);

UPDATE Nashville_Housing
SET 
    OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
    OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
    OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1);

-- Handling OwnerName Nulls 
SELECT OwnerAddress, COUNT(DISTINCT OwnerName) AS OwnerCount
FROM Nashville_Housing
GROUP BY OwnerAddress
HAVING COUNT(DISTINCT OwnerName) > 1;

-- Cheaking Owner Name Based on Owner Address
SELECT OwnerAddress, OwnerName
FROM Nashville_Housing
WHERE OwnerAddress = '0  BATAVIA ST, NASHVILLE, TN'

-- Updating OwnerName
UPDATE Nashville_Housing SET OwnerName = 'Unknown'
WHERE OwnerName IS NULL;

SELECT  * FROM Nashville_Housing

-- Handling Null of Owner Address


-- Droping Full Address Column
ALTER TABLE Nashville_Housing
DROP COLUMN PropertyAddress, OwnerAddress;

-- Renaming Address Column Names
EXEC sp_rename 'Nashville_Housing.PropertySplitAddress', 'PropertyAddress', 'COLUMN';

EXEC sp_rename 'Nashville_Housing.PropertySplitCity', 'PropertyCity', 'COLUMN';

EXEC sp_rename 'Nashville_Housing.OwnerSplitAddress', 'OwnerAddress', 'COLUMN';

EXEC sp_rename 'Nashville_Housing.OwnerSplitCity', 'OwnerCity', 'COLUMN';

EXEC sp_rename 'Nashville_Housing.OwnerSplitState', 'OwnerState', 'COLUMN';

-- Handling OwnerAddress Nulls
SELECT *
FROM Nashville_Housing
WHERE OwnerAddress = PropertyAddress OR
OwnerAddress IS NULL

-- Found That PropertyAddress is No Nulls
SELECT COUNT(*) FROM Nashville_Housing
WHERE PropertyAddress IS NULL

-- Checcking owneraddress and PropertyAddress 
SELECT OwnerAddress,
      PropertyAddress,
       LEN(OwnerAddress) AS OwnerAddressNumber,
       LEN(PropertyAddress) AS PropertyAddressNumber
FROM Nashville_Housing
WHERE OwnerAddress <> PropertyAddress;

-- Updating OwnerAddress Based on PropertyAddress

UPDATE Nashville_Housing
SET OwnerAddress = PropertyAddress
WHERE OwnerAddress IS NULL
AND PropertyAddress IS NOT NULL;

-- Checking OwnerAddress 
SELECT * FROM Nashville_Housing
WHERE OwnerAddress IS NULL

-- Updating OwnerCity Nulls
UPDATE Nashville_Housing
SET OwnerCity = PropertyCity
WHERE OwnerCity IS NULL

-- Cheaking OwnerCity
SELECT * FROM Nashville_Housing
WHERE OwnerAddress IS NULL

--  Handling Owner State Null
SELECT DISTINCT OwnerState
FROM Nashville_Housing

SELECT OwnerState,
    COUNT(*) AS Number
FROM Nashville_Housing
GROUP BY OwnerState

-- Not Null State
SELECT *
FROM Nashville_Housing
WHERE OwnerState IS NOT NULL;

-- NULL State
SELECT *
FROM Nashville_Housing
WHERE OwnerState IS NULL

-- Updating OwnerState 
ALTER TABLE Nashville_Housing
ADD DataCompleteness VARCHAR(20);

UPDATE Nashville_Housing
SET DataCompleteness = 
    CASE 
        WHEN OwnerState IS NULL THEN 'Incomplete'
        ELSE 'Complete'
    END;

-- Not Nulls Values 
SELECT *
FROM Nashville_Housing
WHERE Acreage IS NOT NULL
AND LandValue IS NOT NULL
AND BuildingValue IS NOT NULL;


-- 2] Analysis 

-- 1] Basic Analysis 
--  Total number of Records in Dataset
SELECT * FROM Nashville_Housing

-- Total number of sales transactions
SELECT SUM(SalePrice) AS Total_Sales
FROM Nashville_Housing

-- Count of Unique Properties 
SELECT COUNT(DISTINCT ParcelID) AS NumberOfProperty
FROM Nashville_Housing

-- Number Of Properties Sold Per Year
SELECT YEAR(SaleDate) AS [Year],
       COUNT(UniqueID) AS Number_Of_Property
FROM Nashville_Housing
GROUP BY YEAR(SaleDate)
ORDER BY YEAR(SaleDate) DESC

-- Number of properties sold per city
SELECT PropertyCity,
       COUNT(UniqueID) AS Number_Of_Property
FROM Nashville_Housing
GROUP BY PropertyCity
ORDER BY COUNT(UniqueID) DESC

-- 2] Sales & Price Analysis 

-- What is the average sale price?
SELECT AVG(SalePrice) AS Average_Sale_Price
FROM Nashville_Housing

-- What is the maximum and minimum sale price?
SELECT MIN(SalePrice) AS Minimum_Sale,
       MAX(SalePrice) AS Maximum_Sale
FROM Nashville_Housing

-- Average sale price per year
SELECT YEAR(SaleDate) AS [Year],
        AVG(SalePrice) AS Average_Sale_Price
FROM Nashville_Housing
GROUP BY YEAR(SaleDate)
ORDER BY YEAR(SaleDate) DESC

SELECT * FROM Nashville_Housing

-- Top 5 most expensive property sales
SELECT TOP 5 PropertyAddress,
        SUM(SalePrice) AS Total_Sales
FROM Nashville_Housing
GROUP BY PropertyAddress
ORDER BY SUM(SalePrice) DESC

-- Total sales value per year (trend analysis)
SELECT YEAR(SaleDate) AS [Year],
        SUM(SalePrice) AS Total_Sales
FROM Nashville_Housing
GROUP BY YEAR(SaleDate) 
ORDER BY YEAR(SaleDate) DESC

-- 3] Property Insight

-- Average number of bedrooms per property
SELECT LandUse,
        AVG (Bedrooms) AS Average_Badrooms
FROM Nashville_Housing
GROUP BY LandUse
ORDER BY AVG(Bedrooms) DESC

-- Average number of bathrooms (FullBath + HalfBath logic)
SELECT LandUse,
        AVG(FullBath + HalfBath) AS Average_Numberof_Bathroom
FROM Nashville_Housing
GROUP BY LandUse
ORDER BY AVG(FullBath + HalfBath) DESC

-- Average property value (TotalValue)
SELECT LandUse,
        AVG(CAST(TotalValue AS BIGINT)) AS Total_Value
FROM Nashville_Housing
GROUP BY LandUse
ORDER BY Total_Value DESC

-- Compare LandValue vs BuildingValue
SELECT LandUse,
       SUM(CAST(LandValue AS BIGINT)) AS Total_Land_Value,
       SUM(CAST(TotalValue AS BIGINT)) AS Total_Value
FROM Nashville_Housing
WHERE LandValue IS NOT NULL
AND TotalValue IS NOT NULL
GROUP BY LandUse
ORDER BY Total_Land_Value DESC

-- Which properties have higher building value than land value?
SELECT LandUse,
       SUM(CAST(BuildingValue AS BIGINT)) AS TotalBuildingValue,
       SUM(CAST(LandValue AS BIGINT)) AS TotalLandValue
FROM Nashville_Housing
WHERE BuildingValue > LandValue 
AND BuildingValue IS NOT NULL 
AND LandValue IS NOT NULL
GROUP BY LandUse
ORDER BY TotalBuildingValue DESC

-- 4] Location - Based Analysis 
SELECT *
FROM Nashville_Housing

-- Which city has highest number of sales
SELECT PropertyCity,
       SUM(CAST(TotalValue AS BIGINT)) AS Total_Sales
FROM Nashville_Housing
GROUP BY PropertyCity 
ORDER BY Total_Sales DESC

-- Which city has highest average sale priceWhich city has highest average sale price
SELECT PropertyCity,
       AVG(CAST(Totalvalue AS BIGINT)) AS Average_Sales
FROM Nashville_Housing
GROUP BY PropertyCity
ORDER BY Average_Sales DESC

-- Top 5 cities by total revenue
SELECT TOP 5
       PropertyCity,
       SUM(CAST(TotalValue AS BIGINT)) AS Total_Sales
FROM Nashville_Housing
GROUP BY PropertyCity
ORDER BY Total_Sales DESC

-- Distribution of properties across cities
SELECT 
    PropertyCity,
    COUNT(*) AS TotalProperties
FROM Nashville_Housing
WHERE PropertyCity IS NOT NULL
GROUP BY PropertyCity
ORDER BY TotalProperties DESC;

-- 5] Time - Based Insights
SELECT 
    YEAR(SaleDate) AS [Year],
    SUM(CAST(SalePrice AS BIGINT)) AS TotalRevenue
FROM Nashville_Housing
GROUP BY YEAR(SaleDate)
ORDER BY [Year] DESC;

-- Previus Year Sales
SELECT 
    YEAR(SaleDate) AS [Year],
    SUM(CAST(SalePrice AS BIGINT)) AS TotalRevenue,
    LAG(SUM(CAST(SalePrice AS BIGINT))) OVER (ORDER BY YEAR(SaleDate)) AS PrevYearRevenue
FROM Nashville_Housing
GROUP BY YEAR(SaleDate)
ORDER BY [Year] DESC;

-- Average Price Trend
SELECT 
    YEAR(SaleDate) AS [YEAR],
    AVG(CAST(SalePrice AS BIGINT)) AS AvgPrice,
    LAG(AVG(CAST(SalePrice AS BIGINT))) OVER(ORDER BY YEAR(SaleDate)) AS PrevAverageSales
FROM Nashville_Housing
GROUP BY YEAR(SaleDate)
ORDER BY [YEAR] DESC

-- Growth (%) From Previous Year 
SELECT 
    YEAR(SaleDate) AS SaleYear,
    SUM(CAST(SalePrice AS BIGINT)) AS TotalRevenue, 
    LAG(SUM(CAST(SalePrice AS BIGINT))) OVER (ORDER BY YEAR(SaleDate)) AS PrevYearRevenue,
    CAST(ROUND(
        (SUM(SalePrice) - LAG(SUM(SalePrice)) OVER (ORDER BY YEAR(SaleDate))) 
        * 100.0 
        / LAG(SUM(SalePrice)) OVER (ORDER BY YEAR(SaleDate))
    , 0) AS INT) AS GrowthPercentage
FROM Nashville_Housing
GROUP BY YEAR(SaleDate)
ORDER BY SaleYear DESC

-- 6] Advance Analytics 

-- Does more bedrooms → higher price?
SELECT 
    CASE 
        WHEN Bedrooms <= 2 THEN 'Small'
        WHEN Bedrooms BETWEEN 3 AND 4 THEN 'Medium'
        ELSE 'Large'
    END AS PropertySize,
    COUNT(*) AS TotalProperties,
    AVG(SalePrice) AS AvgPrice
FROM Nashville_Housing
WHERE Bedrooms IS NOT NULL
GROUP BY 
    CASE 
        WHEN Bedrooms <= 2 THEN 'Small'
        WHEN Bedrooms BETWEEN 3 AND 4 THEN 'Medium'
        ELSE 'Large'
    END
ORDER BY AvgPrice;

-- Properties with price above average
SELECT *
FROM Nashville_Housing
WHERE SalePrice > (
    SELECT AVG(SalePrice)
    FROM Nashville_Housing
)

-- Categorize properties: Low / Medium / High price
SELECT 
    UniqueID,
    PropertyCity,
    SalePrice,
    CASE 
        WHEN SalePrice < 150000 THEN 'Low'
        WHEN SalePrice BETWEEN 150000 AND 300000 THEN 'Medium'
        ELSE 'High'
    END AS PriceCategory
FROM Nashville_Housing
WHERE SalePrice IS NOT NULL;

SELECT * FROM Nashville_Housing



