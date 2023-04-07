--Looking for products that did not sell on the internet and resellers
--Useful for cutting down the number of products sold or inventory held
SELECT 
  dp.[ProductKey], 
  dp.[EnglishProductName], 
  dp.[StandardCost], 
  dp.[ListPrice] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimProduct] dp 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] fis ON fis.ProductKey = dp.ProductKey
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.ProductKey = dp.ProductKey
WHERE 
  fis.ProductKey IS NULL
  AND
  frs.ProductKey IS NULL
ORDER BY 
  dp.ProductKey;

---------------------------------------------

--Identifying top 10 products sold through the internet by Units Sold
SELECT 
  TOP 10 fis.ProductKey, 
  dp.EnglishProductName, 
  COUNT(fis.ProductKey) AS UnitsSold 
FROM 
  [AdventureWorksDW2019].[dbo].[FactInternetSales] fis 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[DimProduct] dp ON dp.ProductKey = fis.ProductKey 
GROUP BY 
  fis.ProductKey, 
  dp.EnglishProductName 
ORDER BY 
  UnitsSold DESC;

---------------------------------------------

--Identifying top 10 products sold through the internet by Total Sales
SELECT 
  TOP 10 fis.ProductKey, 
  dp.EnglishProductName, 
  SUM(fis.SalesAmount) AS TotalSales 
FROM 
  [AdventureWorksDW2019].[dbo].[FactInternetSales] fis 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[DimProduct] dp ON dp.ProductKey = fis.ProductKey 
GROUP BY 
  fis.ProductKey, 
  dp.EnglishProductName 
ORDER BY 
  TotalSales DESC;

---------------------------------------------

--Identifying top 10 Employees based on Sales
SELECT 
  TOP 10 de.EmployeeKey, 
  CONCAT(de.FirstName, ' ', de.MiddleName, ' ', de.LastName) AS Employee, 
  SUM(frs.SalesAmount) AS TotalSales 
FROM 
  [AdventureWorksDW2019].[dbo].[DimEmployee] de 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.EmployeeKey = de.EmployeeKey 
GROUP BY 
  de.EmployeeKey, 
  de.FirstName, 
  de.MiddleName, 
  de.LastName 
ORDER BY
  TotalSales DESC;

---------------------------------------------

--Identifying sales quota per employee for the last quarter
SELECT 
  fsq.EmployeeKey, 
  CONCAT(de.FirstName, ' ', de.MiddleName, ' ', de.LastName) AS Employee, 
  fsq.SalesAmountQuota 
FROM 
  [AdventureWorksDW2019].[dbo].[FactSalesQuota] fsq 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[DimEmployee] de ON de.EmployeeKey = fsq.EmployeeKey 
WHERE 
--Filters for the last entry by date key where entries are done per quarter
  DateKey = (
    SELECT 
      MAX(DateKey) 
    FROM 
      [AdventureWorksDW2019].[dbo].[FactSalesQuota]
  )

--------------------------------------------

--Sales Quota per Employee for the previous year
SELECT 
  fsq.EmployeeKey, 
  CONCAT(de.FirstName, ' ', de.MiddleName, ' ', de.LastName) AS Employee, 
  SUM(fsq.SalesAmountQuota) AS PrevYrAnnualSalesQuota 
FROM 
  [AdventureWorksDW2019].[dbo].[FactSalesQuota] fsq 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[DimEmployee] de ON de.EmployeeKey = fsq.EmployeeKey 
WHERE 
--Filters for the previous calendar year
  CalendarYear = (
    SELECT 
      MAX(CalendarYear) -1 
    FROM 
      [AdventureWorksDW2019].[dbo].[FactSalesQuota]
  ) 
GROUP BY 
  fsq.EmployeeKey, 
  de.FirstName, 
  de.MiddleName, 
  de.LastName

---------------------------------------------

--Total Sales per Employee for the previous year
--Can be used as a comparison between actual sales and sales quota per employee
SELECT 
  de.EmployeeKey, 
  CONCAT(de.FirstName, ' ', de.MiddleName, ' ', de.LastName) AS Employee, 
  SUM(frs.SalesAmount) AS PrevYrTotalSales 
FROM 
  [AdventureWorksDW2019].[dbo].[DimEmployee] de 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.EmployeeKey = de.EmployeeKey 
WHERE 
  LEFT(OrderDateKey, 4) = YEAR(GETDATE()) -1 --First 4 digits of OrderDateKey represents the year
GROUP BY 
  de.EmployeeKey, 
  de.FirstName, 
  de.MiddleName, 
  de.LastName

---------------------------------------------

--Identifying top sales territories based on sales amount
--Can be used to identify markets for Market Penetration or Market Development strategies
SELECT 
  dst.SalesTerritoryKey, 
  dst.SalesTerritoryRegion, 
  dst.SalesTerritoryCountry, 
  dst.SalesTerritoryGroup, 
  SUM(fis.SalesAmount) AS TotalSales 
FROM 
  [AdventureWorksDW2019].[dbo].[DimSalesTerritory] dst 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] fis ON fis.SalesTerritoryKey = dst.SalesTerritoryKey 
GROUP BY 
  dst.SalesTerritoryKey, 
  dst.SalesTerritoryRegion, 
  dst.SalesTerritoryCountry, 
  dst.SalesTerritoryGroup 
HAVING 
  SUM(fis.SalesAmount) IS NOT NULL -- Removes NULL values on SalesTerritoryKey 11
ORDER BY 
  SalesTerritoryKey

---------------------------------------------

--Identifying top reseller customers based on sales volume
--Useful for segmenting top customers for special sales relationships
SELECT 
  TOP (100) dr.ResellerKey, 
  dr.ResellerName, 
  SUM(frs.SalesAmount) AS TotalPurchase 
FROM 
  [AdventureWorksDW2019].[dbo].[DimReseller] dr 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.ResellerKey = dr.ResellerKey 
GROUP BY 
  dr.ResellerKey, 
  dr.ResellerName 
HAVING 
  SUM(frs.SalesAmount) IS NOT NULL -- Removes NULL values
ORDER BY 
  TotalPurchase DESC

---------------------------------------------

--Identifying top Reseller Business Types based on TotalSalesVolume and OrderCount
--Gives insight on what type of business clients we typically deal with
SELECT 
  dr.BusinessType, 
  SUM(frs.SalesAmount) AS TotalSalesVolume, 
  COUNT(frs.SalesOrderNumber) AS OrderCount 
FROM 
  [AdventureWorksDW2019].[dbo].[DimReseller] dr 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.ResellerKey = dr.ResellerKey 
GROUP BY 
  dr.BusinessType 
ORDER BY 
  TotalSalesVolume DESC


---------------------------------------------

--Comparing Adventure Works's sales to resellers vs the reseller's estimated annual sales
--Useful for determining how much of the reseller's sold inventory is sourced from our company
SELECT 
  dr.ResellerKey, 
  dr.ResellerName, 
  SUM(frs.SalesAmount) AS SalesToReseller, 
  dr.AnnualSales AS EstResellerAnnualSales, 
  ((SUM(frs.SalesAmount) / dr.AnnualSales) * 100) AS SalesToResellerVsResellerAnnualSalesPct 
FROM 
  [AdventureWorksDW2019].[dbo].[DimReseller] dr 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.ResellerKey = dr.ResellerKey 
WHERE 
  LEFT(OrderDateKey, 4) = 2022 --Database is outdated and does not have 2023 data, YEAR(GETDATE()) not usable because of this
GROUP BY 
  dr.ResellerKey, 
  dr.ResellerName, 
  dr.AnnualSales 
ORDER BY 
  SalesToResellerVsResellerAnnualSalesPct DESC

---------------------------------------------

--Compare various SalesReason per OrderDate year for InternetSales
SELECT 
  dsr.SalesReasonName, 
  dsr.SalesReasonReasonType AS SalesReasonType, 
  COUNT(fisr.SalesOrderNumber) AS SalesOrderCount -- DISTINCT not included since there may be multiple SalesReasons per SalesOrderNumber
FROM 
  [AdventureWorksDW2019].[dbo].[DimSalesReason] dsr 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSalesReason] fisr ON fisr.SalesReasonKey = dsr.SalesReasonKey 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] fis ON fis.SalesOrderNumber = fisr.SalesOrderNumber -- FactInternetSales joined to include OrderDateKey to be able to query per year
--WHERE 
  --LEFT(OrderDateKey, 4) = 2022 --Modify depending on the year you want to query if needed
GROUP BY 
  SalesReasonName, 
  SalesReasonReasonType 
ORDER BY 
  SalesOrderCount

---------------------------------------------

--Compare the effectiveness of 4 Marketing sales reason for InternetSales
SELECT
  dsr.SalesReasonName,  
  COUNT(fisr.SalesOrderNumber) AS SalesOrderCount -- DISTINCT not included since there may be multiple SalesReasons per SalesOrderNumber
FROM 
  [AdventureWorksDW2019].[dbo].[DimSalesReason] dsr 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSalesReason] fisr ON fisr.SalesReasonKey = dsr.SalesReasonKey 
  --LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] fis ON fis.SalesOrderNumber = fisr.SalesOrderNumber -- FactInternetSales joined to include OrderDateKey to be able to query per year
--WHERE 
  --LEFT(OrderDateKey, 4) = 2022 --Modify depending on the year you want to query if needed
GROUP BY 
  SalesReasonName, 
  SalesReasonReasonType
HAVING
  dsr.SalesReasonReasonType = 'Marketing' -- Compares Marketing SalesReasons only
ORDER BY 
  SalesOrderCount

---------------------------------------------

--Compare various PromotionType
SELECT 
  dp.EnglishPromotionType AS PromotionType, 
  COUNT(fis.SalesOrderNumber) AS InternetSalesOrders 
  --COUNT(frs.SalesOrderNumber) AS ResellerSalesOrders
  --COUNT(fis.SalesOrderNumber) + COUNT(frs.SalesOrderNumber) AS TotalSalesOrders
FROM 
  [AdventureWorksDW2019].[dbo].[DimPromotion] dp 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] fis ON fis.PromotionKey = dp.PromotionKey
  --LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.PromotionKey = dp.PromotionKey
WHERE
  LEFT(fis.OrderDateKey, 4) = 2022 --Modify year based on what you want to query
  --OR
  --LEFT(frs.OrderDateKey, 4) = 2022 --Modify year based on what you want to query
GROUP BY 
  dp.EnglishPromotionType 
ORDER BY 
  InternetSalesOrders DESC

---------------------------------------------

--Compare number of items sold for the year vs Inventory UnitsBalance, SafetyStockLevel, and ReorderPoint
SELECT
  dp.ProductKey,
  dp.EnglishProductName AS ProductName,
  SUM(fis.OrderQuantity) AS InternetOrderQuantity,
  SUM(frs.OrderQuantity) AS ResellerOrderQuantity,
  --SUM(fpi.UnitsIn) - SUM(fpi.UnitsOut) AS InventoryBalance,
  COALESCE(SUM(fis.OrderQuantity), 0) + COALESCE(SUM(frs.OrderQuantity), 0) AS TotalOrderQuantity,
  dp.SafetyStockLevel,
  dp.ReorderPoint
FROM
  [AdventureWorksDW2019].[dbo].[DimProduct] dp
  --LEFT JOIN [AdventureWorksDW2019].[dbo].[FactProductInventory] fpi ON fpi.ProductKey = dp.ProductKey
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] fis ON fis.ProductKey = dp.ProductKey
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.ProductKey = dp.ProductKey
WHERE
  LEFT(fis.OrderDateKey, 4) = 2022
  OR
  LEFT(frs.OrderDateKey, 4) = 2022
GROUP BY
  dp.ProductKey,
  dp.EnglishProductName,
  dp.SafetyStockLevel,
  dp.ReorderPoint
ORDER BY
  ProductKey

---------------------------------------------

--Compare Sales Margin between top selling product on the internet vs Sales Margin when sold to resellers
--CTE for Reseller Product & Sales Margin
WITH ResellerSalesMarginTable AS (
  SELECT 
    dp.ProductKey, 
    dp.EnglishProductName AS ProductName, 
    AVG(
      frs.UnitPrice - frs.ProductStandardCost
    ) AS AvgResellerSalesMargin 
  FROM 
    [AdventureWorksDW2019].[dbo].[DimProduct] dp 
    LEFT JOIN [AdventureWorksDW2019].[dbo].[FactResellerSales] frs ON frs.ProductKey = dp.ProductKey 
  GROUP BY 
    dp.ProductKey, 
    dp.EnglishProductName 
	--ORDER BY 
    --ResellerSalesMargin DESC
    ) 
SELECT 
  dp.ProductKey, 
  dp.EnglishProductName AS ProductName, 
  AVG(
    fis.UnitPrice - fis.ProductStandardCost
  ) AS AvgInternetSalesMargin, 
  AvgResellerSalesMargin 
FROM 
  [AdventureWorksDW2019].[dbo].[DimProduct] dp 
  LEFT JOIN [AdventureWorksDW2019].[dbo].[FactInternetSales] fis ON fis.ProductKey = dp.ProductKey 
  LEFT JOIN ResellerSalesMarginTable rsm ON rsm.ProductKey = dp.ProductKey 
GROUP BY 
  dp.ProductKey, 
  dp.EnglishProductName, 
  AvgResellerSalesMargin 
ORDER BY 
  AvgInternetSalesMargin DESC

---------------------------------------------

/****** Cleaning DimCustomer  ******/
SELECT 
  [CustomerKey], 
  [GeographyKey], 
  --[CustomerAlternateKey], 
  --[Title], 
  [FirstName], 
  --[MiddleName], 
  [LastName], 
  --[NameStyle], 
  --[BirthDate], 
  --[MaritalStatus], 
  [Suffix] 
  --[Gender], 
  --[EmailAddress], 
  --[YearlyIncome] 
  --[TotalChildren], 
  --[NumberChildrenAtHome], 
  --[EnglishEducation], 
  --[SpanishEducation], 
  --[FrenchEducation], 
  --[EnglishOccupation], 
  --[SpanishOccupation], 
  --[FrenchOccupation], 
  --[HouseOwnerFlag], 
  --[NumberCarsOwned], 
  --[AddressLine1], 
  --[AddressLine2], 
  --[Phone], 
  --[DateFirstPurchase], 
  --[CommuteDistance] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimCustomer]

---------------------------------------------------------------

/******  Cleaning DimDate  ******/
SELECT 
  --[DateKey], 
  FORMAT([FullDateAlternateKey], 'dd MMM yy') AS Date, 
  [DayNumberOfWeek], 
  [EnglishDayNameOfWeek] AS Day, 
  --[SpanishDayNameOfWeek], 
  --[FrenchDayNameOfWeek], 
  --[DayNumberOfMonth], 
  --[DayNumberOfYear], 
  [WeekNumberOfYear], 
  [EnglishMonthName] AS Month, 
  --[SpanishMonthName], 
  --[FrenchMonthName], 
  [MonthNumberOfYear], 
  [CalendarQuarter], 
  [CalendarYear] 
  --[CalendarSemester] 
  --[FiscalQuarter], 
  --[FiscalYear], 
  --[FiscalSemester] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimDate]

---------------------------------------------------------------

/****** Cleaning DimEmployee  ******/
SELECT 
  [EmployeeKey], 
  [ParentEmployeeKey], 
  --[EmployeeNationalIDAlternateKey], 
  --[ParentEmployeeNationalIDAlternateKey], 
  [SalesTerritoryKey], 
  CONCAT(FirstName, ' ', LastName) AS EmployeeName
  --[FirstName], 
  --[LastName], 
  --[MiddleName] 
  --[NameStyle], 
  --[Title], 
  --[HireDate], 
  --[BirthDate], 
  --[LoginID], 
  --[EmailAddress], 
  --[Phone], 
  --[MaritalStatus], 
  --[EmergencyContactName], 
  --[EmergencyContactPhone], 
  --[SalariedFlag], 
  --[Gender], 
  --[PayFrequency], 
  --[BaseRate], 
  --[VacationHours], 
  --[SickLeaveHours], 
  --[CurrentFlag], 
  --[SalesPersonFlag], 
  --[DepartmentName] 
  --[StartDate], 
  --[EndDate], 
  --[Status], 
  --[EmployeePhoto] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimEmployee]

---------------------------------------------------------------

/****** Cleaning DimGeography  ******/
SELECT 
  [GeographyKey], 
  [City], 
  ---[StateProvinceCode], 
  [StateProvinceName] AS StateProvince, 
  [EnglishCountryRegionName] AS CountryRegion,
  [CountryRegionCode],
  --[SpanishCountryRegionName], 
  --[FrenchCountryRegionName], 
  [PostalCode], 
  [SalesTerritoryKey] 
  --[IpAddressLocator] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimGeography]

---------------------------------------------------------------

/****** Cleaning DimProduct  ******/
SELECT 
  [ProductKey], 
  --[ProductAlternateKey], 
  [ProductSubcategoryKey], 
  --[WeightUnitMeasureCode], 
  --[SizeUnitMeasureCode], 
  [EnglishProductName] AS ProductName, 
  --[SpanishProductName], 
  --[FrenchProductName], 
  [StandardCost], 
  --[FinishedGoodsFlag], 
  --[Color], 
  --[SafetyStockLevel], 
  --[ReorderPoint], 
  [ListPrice], 
  --[Size], 
  --[SizeRange], 
  --[Weight], 
  --[DaysToManufacture], 
  --[ProductLine], 
  [DealerPrice] 
  --[Class], 
  --[Style], 
  --[ModelName], 
  --[LargePhoto], 
  --[EnglishDescription], 
  --[FrenchDescription], 
  --[ChineseDescription], 
  --[ArabicDescription], 
  --[HebrewDescription], 
  --[ThaiDescription], 
  --[GermanDescription], 
  --[JapaneseDescription], 
  --[TurkishDescription], 
  --[StartDate], 
  --[EndDate], 
  --[Status] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimProduct]

---------------------------------------------------------------

/****** Cleaning DimProductCategory ******/
SELECT 
  [ProductCategoryKey], 
  --[ProductCategoryAlternateKey], 
  [EnglishProductCategoryName] 
  --[SpanishProductCategoryName], 
  --[FrenchProductCategoryName] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimProductCategory]

---------------------------------------------------------------

/****** Cleaning DimProductSubcategory  ******/
SELECT 
  [ProductSubcategoryKey], 
  --[ProductSubcategoryAlternateKey], 
  [EnglishProductSubcategoryName] AS ProductSubcategory, 
  --[SpanishProductSubcategoryName], 
  --[FrenchProductSubcategoryName], 
  [ProductCategoryKey] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimProductSubcategory]

---------------------------------------------------------------

/****** Cleaning DimPromotion  ******/
SELECT 
  [PromotionKey], 
  --[PromotionAlternateKey], 
  [EnglishPromotionName] AS PromotionName, 
  --[SpanishPromotionName], 
  --[FrenchPromotionName], 
  [DiscountPct], 
  [EnglishPromotionType] AS PromotionType, 
  --[SpanishPromotionType], 
  --[FrenchPromotionType], 
  [EnglishPromotionCategory] AS PromotionCategory
  --[SpanishPromotionCategory], 
  --[FrenchPromotionCategory], 
  --[StartDate], 
  --[EndDate], 
  --[MinQty], 
  --[MaxQty] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimPromotion]

---------------------------------------------------------------

/****** Cleaning DimReseller  ******/
SELECT 
  [ResellerKey], 
  [GeographyKey], 
  --[ResellerAlternateKey], 
  --[Phone], 
  [BusinessType], 
  [ResellerName], 
  --[NumberEmployees], 
  --[OrderFrequency], 
  --[OrderMonth], 
  --[FirstOrderYear], 
  --[LastOrderYear], 
  [ProductLine] 
  --[AddressLine1], 
  --[AddressLine2], 
  --[AnnualSales] 
  --[BankName], 
  --[MinPaymentType], 
  --[MinPaymentAmount], 
  --[AnnualRevenue], 
  --[YearOpened] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimReseller]

---------------------------------------------------------------

/****** Cleaning DimSalesReason  ******/
SELECT 
  [SalesReasonKey], 
  --[SalesReasonAlternateKey], 
  [SalesReasonName] AS SalesReason, 
  [SalesReasonReasonType] AS SalesReasonType 
FROM 
  [AdventureWorksDW2019].[dbo].[DimSalesReason]

---------------------------------------------------------------

/****** Cleaning DimSalesTerritory  ******/
SELECT 
  [SalesTerritoryKey], 
  --[SalesTerritoryAlternateKey], 
  [SalesTerritoryRegion], 
  [SalesTerritoryCountry], 
  [SalesTerritoryGroup] 
  --[SalesTerritoryImage] 
FROM 
  [AdventureWorksDW2019].[dbo].[DimSalesTerritory]

---------------------------------------------------------------

/****** Cleaning FactInternetSales  ******/
SELECT 
  [ProductKey], 
  FORMAT([OrderDate], 'dd-MM-yyyy') AS OrderDate, 
  FORMAT([DueDate], 'dd-MM-yyyy') AS DueDate,
  FORMAT([ShipDate], 'dd-MM-yyyy') AS ShipDate,
  --[OrderDateKey], 
  --[DueDateKey], 
  --[ShipDateKey], 
  [CustomerKey], 
  [PromotionKey], 
  --[CurrencyKey], 
  [SalesTerritoryKey], 
  [SalesOrderNumber], 
  [SalesOrderLineNumber], 
  --[RevisionNumber], 
  [OrderQuantity], 
  [UnitPrice], 
  --[ExtendedAmount], 
  --[UnitPriceDiscountPct], 
  --[DiscountAmount], 
  --[ProductStandardCost], 
  [TotalProductCost], 
  [SalesAmount] 
  --[TaxAmt], 
  --[Freight] 
  --[CarrierTrackingNumber], 
  --[CustomerPONumber], 
FROM 
  [AdventureWorksDW2019].[dbo].[FactInternetSales]

---------------------------------------------------------------

/****** Cleaning FactInternetSalesReason  ******/
SELECT 
  [SalesOrderNumber], 
  --[SalesOrderLineNumber], 
  [SalesReasonKey] 
FROM 
  [AdventureWorksDW2019].[dbo].[FactInternetSalesReason]

---------------------------------------------------------------

/****** Cleaning FactResellerSales  ******/
SELECT 
  [ProductKey], 
  FORMAT([OrderDate], 'dd-MM-yyyy') AS OrderDate, 
  FORMAT([DueDate], 'dd-MM-yyyy') AS DueDate,
  FORMAT([ShipDate],'dd-MM-yyyy') AS ShipDate,
  --[OrderDateKey], 
  --[DueDateKey], 
  --[ShipDateKey], 
  [ResellerKey], 
  [EmployeeKey], 
  [PromotionKey], 
  --[CurrencyKey], 
  [SalesTerritoryKey], 
  [SalesOrderNumber], 
  [SalesOrderLineNumber], 
  --[RevisionNumber], 
  [OrderQuantity], 
  [UnitPrice], 
  [ExtendedAmount], 
  [UnitPriceDiscountPct], 
  [DiscountAmount], 
  [ProductStandardCost], 
  [TotalProductCost], 
  [SalesAmount] 
  --[TaxAmt], 
  --[Freight] 
  --[CarrierTrackingNumber], 
  --[CustomerPONumber], 
  --[OrderDate], 
  --[DueDate], 
  --[ShipDate] 
FROM 
  [AdventureWorksDW2019].[dbo].[FactResellerSales]