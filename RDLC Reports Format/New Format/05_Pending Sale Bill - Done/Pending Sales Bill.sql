------- Pending Sales Bill----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockGroupName_List as Varchar(500)='', @StockItemName_List as Varchar(500)='',
--		@DepotName_List as Varchar(500)='', @HQName_List as Varchar(500)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='01/01/2020'
--SET @DateTo = '10/30/2020'

--SET @StockGroupName_List = ''
--SET @StockItemName_List = ''
--SET @DepotName_List = ''
--SET @HQName_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpStockGroupName') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID('tempdb..#tmpDepotName') IS NOT NULL DROP TABLE #tmpDepotName
IF OBJECT_ID('tempdb..#tmpHQName') IS NOT NULL DROP TABLE #tmpHQName
IF OBJECT_ID('tempdb..#PendingSalesBill') IS NOT NULL DROP TABLE #PendingSalesBill

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'StockGroupName' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))
SELECT NAME AS 'DepotName' INTO #tmpDepotName from dbo.GetTableFromString(isnull(@DepotName_List,''))
SELECT NAME AS 'HQName' INTO #tmpHQName from dbo.GetTableFromString(isnull(@HQName_List,''))

BEGIN
CREATE TABLE #PendingSalesBill(
      [TransDate] datetime NOT NULL,
      [TrackingName] [varchar](300) NULL,
      [StockGroup] [varchar](300) NULL,
      [StockItemName] [varchar](300)  NULL,     
	  [DepotName] [varchar](300)  NULL,     
	  [HQName] [varchar](300)  NULL,     
      [QTY] [decimal](18, 4) NULL,
      [Rate] [decimal](18, 4) NULL,
      [Amount] [decimal](18, 4) NULL
) 


Select * From #PendingSalesBill
END