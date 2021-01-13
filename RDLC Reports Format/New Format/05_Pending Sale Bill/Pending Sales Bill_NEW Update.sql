----- Pending Sales Bill----
DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockGroupName_List as Varchar(500)='', @StockItemName_List as Varchar(500)='',
		@DepotName_List as Varchar(500)='', @HQName_List as Varchar(500)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
SET @DateFrom ='01/01/2020'
SET @DateTo = '10/30/2020'

SET @StockGroupName_List = ''
SET @StockItemName_List = ''
SET @DepotName_List = ''
SET @HQName_List = ''

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


SELECT SALESORDER.Date AS [TransDate], SALESORDER.Reference AS [ChallanBillNo], SALESORDER.PartyName AS [VendorName],  SALESORDER.StockItemName AS [StockItemName], SALESORDER.StockGroup  as [StockGroup],
		SALESORDER.GodownName  as [GodownName],  SALESORDER.ActualQuantity AS [SalesOrderQTY], SALESORDER.Rate AS [SalesOrderRate], IsNull(SALES.ActualQuantity, 0) as [BillQTY], IsNull(SALES.Rate, 0) as [BillRate]
INTO #PendingSalesBill
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM, BL.GodownName,
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyId AND VH.VoucherID = BL.VoucherID 
		WHERE  (VH.VoucherTypeName LIKE '%Sales Order%')
		And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))
		And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS SALESORDER  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE '%SALES')
		And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))

	) AS SALES 
   ON SALESORDER.OrderNo = SALES.OrderNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], '' as [HQ],
(B.SalesOrderQTY - B.BillQTY) as [QTY], B.SalesOrderRate as [Rate], (B.SalesOrderQTY - B.BillQTY) * B.SalesOrderRate As [Amount]

from #PendingSalesBill as B
Where B.SalesOrderQTY > B.BillQTY  And
(@StockGroupName_List  <> '' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND B.StockItemName = B.StockItemName))
Order by B.TransDate Desc, B.ChallanBillNo, B.StockGroup, B.StockItemName