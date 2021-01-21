--- Godown Stock Transfer Report ----
DECLARE @CompanyNames as Varchar(2000)='', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodwnName_List as Varchar(250)='', @StockItemName_List as Varchar(250)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
SET @DateFrom ='01/01/2021'
SET @DateTo = '10/30/2021'
SET @GodwnName_List = ''
SET @StockItemName_List=''

IF OBJECT_ID('tempdb..#Purchase') IS NOT NULL DROP TABLE #Purchase

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpGodwnName') IS NOT NULL DROP TABLE #tmpGodwnName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID('tempdb..#tmpOPBalance') IS NOT NULL DROP TABLE #tmpOPBalance

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'GodwnName' INTO #tmpGodwnName from	 dbo.GetTableFromString(isnull(@GodwnName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))

BEGIN
CREATE TABLE #Purchase(
      [GodownName] VARCHAR(300) NOT NULL,    
      [StockItemName] [varchar](300) NULL,
      [OpeningStock_QTY] [decimal](18, 4) NULL,
	  [OpeningStock_Value] [decimal](18, 2) NULL,
	  [InWard_QTY] [decimal](18, 4) NULL,
	  [Inward_Value] [decimal](18, 2) NULL,
      [OutWard_QTY] [decimal](18, 4) NULL,
	  [Outward_Value] [decimal](18, 2) NULL,
	  [Closing_QTY] [decimal](18, 4) NULL,
	  [Closing_Value] [decimal](18, 2) NULL,
) 
END
	--INSERT INTO #Purchase
	--SELECT TOP (200) GodownName, StockItemName, 0 as [OpeningQTY], 0 as [OpeningValue], Quantity as [InWard_QTY], (Rate * Amount) as [Inward_Value], Quantity as [OutWardQTY], (Rate * Amount) as [OutwardValue],
	--0 as [ClosingQTY], 0 as [ClosingValue]
	--FROM     TD_Txn_StockDetails Where CompanyID=2

	--Select * from #Purchase

	Declare @ShowStockDate as Datetime

	Select  distinct top(1) @ShowStockDate=stockdate 	From TD_Txn_StockDetails  
	Where (@CompanyNames  <> '' AND CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND CompanyID = CompanyID)) And StockDate>=@DateFrom 	order by stockdate Desc
	Print @ShowStockDate

	---- Fertch the Opening Balance from Stock Details and Save to Temp Table ----
	Select  StockItemName,  Sum(Quantity) as [OpeningQTY], Sum(Amount) as [OpeningValue] 
	Into #tmpOPBalance
	From TD_Txn_StockDetails 
	Where (@CompanyNames  <> '' AND CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND CompanyID = CompanyID)) And StockDate= @ShowStockDate Group by StockItemName

	Select * from  #tmpOPBalance

	---- Fetch In ward Stock -----
	Select top(100) * from TD_Txn_VchHdr where CompanyID=2
	Select top(100) * from TD_Txn_InvLine where CompanyID=2
	Select top(100) * from TD_Txn_AccLine where CompanyID=2
	Select top(100) * from TD_Txn_BatchLine where CompanyID=2
	Select top(100) * from TD_Txn_BillLine where CompanyID=2