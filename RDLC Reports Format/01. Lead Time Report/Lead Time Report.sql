------- Lead Time Report----
--DECLARE @CompanyNames as Varchar(2000)='', @PO_DateFrom datetime= Null,  @PO_DateTo datetime=Null,   @GRN_DateFrom datetime= Null,  @GRN_DateTo datetime=Null, 
--		@Invoice_DateFrom datetime= Null,  @Invoice_DateTo datetime=Null, @PartyName_List as Varchar(250)='',  @StockItemName_List as Varchar(250)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @PO_DateFrom ='01/01/2020'
--SET @PO_DateTo = '10/30/2020'
--SET @GRN_DateFrom ='01/01/2020'
--SET @GRN_DateTo = '10/30/2020'
--SET @Invoice_DateFrom ='01/01/2020'
--SET @Invoice_DateTo = '10/30/2020'
--SET @PartyName_List = ''
--SET @StockItemName_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'PartyName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))

select * from View_Report_LeadTime as LT
where  (@CompanyNames  <> '' AND LT.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND LT.CompanyID = LT.CompanyID))
	And (@PartyName_List  <> '' AND LT.popartyname IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND LT.popartyname =LT.popartyname))
	And (@StockItemName_List  <> '' AND LT.POStockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND LT.POStockItemName =LT.POStockItemName ))
	And LT.PODate >= @PO_DateFrom AND LT.PODate <= @PO_DateTo
	And LT.GRNDate >= @GRN_DateFrom AND LT.GRNDate <= @GRN_DateTo
	And LT.InvoiceDate >= @Invoice_DateFrom AND LT.InvoiceDate <= @GRN_DateTo
Order by podate, popartyname, POStockItemName
