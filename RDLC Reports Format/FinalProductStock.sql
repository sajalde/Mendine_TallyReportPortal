--- FinalProductStock----
DECLARE @CompanyNames as Varchar(2000)='', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodownName_List as Varchar(250)='', @StockGroup_List as Varchar(250)='',
		@StockItemName_List as Varchar(250)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
SET @DateFrom ='01/01/2020'
SET @DateTo = '10/30/2020'
SET @GodownName_List = ''
SET @StockGroup_List=''
SET @StockItemName_List=''


IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID

IF OBJECT_ID('tempdb..#tmpGodownName') IS NOT NULL DROP TABLE #tmpGodownName
IF OBJECT_ID('tempdb..#tmpStockGroup') IS NOT NULL DROP TABLE #tmpStockGroup
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'GodownName' INTO #tmpGodownName from dbo.GetTableFromString(isnull(@GodownName_List,''))
SELECT NAME AS 'StockGroup' INTO #tmpStockGroup from	 dbo.GetTableFromString(isnull(@StockGroup_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from	 dbo.GetTableFromString(isnull(@StockItemName_List,''))



 SELECT c.CompanyName AS[CompanyID], sd.StockDate, sd.StockItemName, sd.GodownName, sd.BatchName, sd.Quantity, sd.UOM, sd.Rate, sd.Amount * -1 AS amount, SI.StockGroup 
 FROM  dbo.TD_Txn_StockDetails AS sd 
 INNER JOIN dbo.TD_Mst_StockItem AS SI ON sd.CompanyID = SI.CompanyID AND sd.StockItemName = SI.StockItemName 
 Inner Join TD_Mst_Company as C On c.CompanyID = Sd.CompanyID 
 where  sd.StockDate >= @DateFrom AND sd.StockDate <= @DateTo
	And (@CompanyNames  <> '' AND SD.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND SD.CompanyID = SD.CompanyID))
	And (@GodownName_List  <> '' AND SD.GodownName IN (SELECT GodownName FROM #tmpGodownName)  OR (@GodownName_List = ''  AND SD.GodownName =SD.GodownName ))
	And (@StockGroup_List  <> '' AND SI.StockGroup IN (SELECT StockGroup FROM #tmpStockGroup)  OR (@StockGroup_List = ''  AND SI.StockGroup =SI.StockGroup ))
 	And (@StockItemName_List  <> '' AND SI.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND SI.StockItemName =SI.StockItemName ))
  Order by StockDate, GodownName, StockGroup,StockItemName 

