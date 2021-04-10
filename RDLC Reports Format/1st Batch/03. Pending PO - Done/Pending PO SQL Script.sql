--- Pending Purchase Order Report ------
Declare @CompanyIDs as Varchar(2000)='', @PO_DateFrom as Date=null, @PO_DateTo as Date=null, @PONo_List as Varchar(250)='',	@PartyName_List as Varchar(250)='',@ItemName_List as Varchar(250)=''

---- Init the Value for Validate ----
Set @PO_DateFrom='01/01/2020'
Set @PO_DateTo='10/30/2020'
Set @CompanyIDs='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
Set @PONo_List=''
Set @PartyName_List=''
Set @ItemName_List=''

IF(@PO_DateFrom is null) BEGIN  SET @PO_DateFrom ='1900-01-01' END    
IF(@PO_DateTo is null) BEGIN SET @PO_DateTo ='2100-01-01' END

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpPendingPurchaseOrder') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpPOList') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID('tempdb..#tmpItemName') IS NOT NULL DROP TABLE #tmpItemName

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyIDs,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName

--SELECT NAME AS 'CompanyID' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''))
SELECT NAME AS 'PartyName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'PONumber' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''))
SELECT NAME AS 'ItemName' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''))

------------- GET PO DETAILS ----------------------------
Select  VH.VoucherID, vh.Date as [PODate], vh.VoucherNo as [PONumber], VH.Reference, Upper(vh.PartyName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = '01-Jan-1900' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Txn_VchHdr as VH
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.VoucherID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  VH.Reference = GVH.OrderNo 
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.VoucherID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.VoucherID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.AccLineNo = IL.AccLineNo AND BT.InvLineNo = IL.InvLineNo 
Where vh.VoucherTypeName Like 'Purchase Order%' And Gvh.VoucherTypeName Like 'GRN%' 
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo
And (@CompanyIDs  <> '' AND vh.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyIDs = ''  AND vh.CompanyID = vh.CompanyID ))
And (@PartyName_List  <> '' AND vh.PartyName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND vh.PartyName = vh.PartyName ))
And (@PONo_List  <> '' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,-- PPO.Discount , PPO.PORate, PPO.Discount ,
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - Sum(PPO.GRNPOQTY)) As [BalanceQTY], ((PPO.POQTY - Sum(PPO.GRNPOQTY)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate
Having (PPO.POQTY - Sum(PPO.GRNPOQTY))>0  Order By PODate Desc

