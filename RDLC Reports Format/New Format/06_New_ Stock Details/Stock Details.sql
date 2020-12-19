--------- Stock Details----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockCategoryName_List as Varchar(500)='', @StockItemName_List as Varchar(500)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='01/01/2020'
--SET @DateTo = '10/30/2020'

--SET @StockCategoryName_List = ''
--SET @StockItemName_List = ''


IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpStockCategoryName') IS NOT NULL DROP TABLE #tmpStockCategoryName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName

IF OBJECT_ID('tempdb..#StockDetails') IS NOT NULL DROP TABLE #StockDetails

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'StockCategoryName' INTO #tmpStockCategoryName from dbo.GetTableFromString(isnull(@StockCategoryName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))


BEGIN
CREATE TABLE #StockDetails(
	[TransDate] datetime NOT NULL,
	[StockCategory] [varchar](300) NULL,
	[StockItemName] [varchar](300)  NULL,     
	[VoucherName] [varchar](300) NULL, 
	[QTY_Opening] [decimal](18, 4) NULL,
	[QTY_InWard] [decimal](18, 4) NULL,
	[QTY_OutWard] [decimal](18, 4) NULL,
	[QTY_Closing] [decimal](18, 4) NULL,
) 


Select * From #StockDetails
END