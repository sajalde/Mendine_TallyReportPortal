------- Pending Purchase Bill----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @PartyName_List as Varchar(250)='', @StockGroupName_List as Varchar(250)='', 
--		@StockItemName_List as Varchar(250)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='01/01/2020'
--SET @DateTo = '10/30/2020'
--SET @PartyName_List = ''
--SET @StockGroupName_List = ''
--SET @StockItemName_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpStockGroupName') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID('tempdb..#tempPendingPurchaseBills') IS NOT NULL DROP TABLE #tempPendingPurchaseBills


SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'PartyName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'StockGroupName' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))


SELECT GRN.Date AS [TransDate], GRN.Reference AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], GRN.StockGroup  as [StockGroup],
	   GRN.ActualQuantity AS [GRNQTY], GRN.Rate AS [GRNRate], IsNull(PURCHASE.ActualQuantity, 0) as [BillQTY], IsNull(PURCHASE.Rate, 0) as [BillRate]
INTO #tempPendingPurchaseBills
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM,  IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName
		WHERE  (VH.VoucherTypeName LIKE 'GRN%')
		And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))
		And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS GRN  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE 'PURCHASE FOR%')
		And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))

	) AS PURCHASE 
		ON GRN.OrderNo = PURCHASE.OrderNo AND GRN.StockItemName = PURCHASE.StockItemName AND GRN.ActualQuantity = PURCHASE.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, (B.GRNQTY - B.BillQTY) as [QTY], B.GRNRate as [Rate], (B.GRNQTY - B.BillQTY) * B.GRNRate As [Amount]

from #tempPendingPurchaseBills as B
Where (@PartyName_List  <> '' AND B.VendorName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND B.VendorName = B.VendorName ))
And   (@StockGroupName_List  <> '' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND B.StockItemName = B.StockItemName))
And B.GRNQTY > B.BillQTY
Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc