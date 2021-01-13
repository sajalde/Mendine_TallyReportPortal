------- Debit and Credit Note Register ----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null, @VoucherType_List as Varchar(500)='',  @PartyName_List as Varchar(250)='', @StockItemName_List as Varchar(250)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='01/01/2020'
--SET @DateTo = '12/30/2020'
--SET @VoucherType_List = ''
--SET @PartyName_List = ''
--SET @StockItemName_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpVoucherType') IS NOT NULL DROP TABLE #tmpVoucherType
IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'VoucherType' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''))
SELECT NAME AS 'PartyName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))


SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName, IL.StockItemName, IL.ActualQuantity,   IL.Rate, IL.RateUOM, IL.Amount,
GSTClass as [GST], 0 as [GSTAmount], IL.Amount + 0 as [TotalAmount] , VH.Narration 
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
FULL OUTER JOIN TD_Txn_AccLine ON IL.AccLineNo = TD_Txn_AccLine.AccLineNo AND VH.CompanyID = TD_Txn_AccLine.CompanyID AND IL.VoucherID = TD_Txn_AccLine.VoucherID
where VoucherTypeName like '%Debit Note%' or VoucherTypeName like '%credit%'
	And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And (@PartyName_List  <> '' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
	And   (@StockItemName_List  <> '' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND IL.StockItemName = IL.StockItemName))
Order by VH.Date, VH.PartyLedgerName, IL.StockItemName Desc