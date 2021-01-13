------- Negative Stock Register ----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockItemName_List as Varchar(250)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='01/03/2021'
--SET @DateTo = '01/03/2021'
--SET @StockItemName_List = ''


IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))


SELECT SD.StockDate, SD.StockItemName,  SD.BatchName, SD.Quantity, SD.UOM, SD.Rate, SD.Amount, SD.GodownName
FROM TD_Txn_StockDetails as SD
where SD.Quantity like '-%' --and SD.StockDate='2021-01-03 00:00:00.000' and SD.StockItemName like 'gly%'
	And (@CompanyNames  <> '' AND SD.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND SD.CompanyID = SD.CompanyID))
	And SD.StockDate >= @DateFrom AND SD.StockDate <= @DateTo
	And   (@StockItemName_List  <> '' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND SD.StockItemName = SD.StockItemName))
Order by SD.StockDate, SD.StockItemName Desc