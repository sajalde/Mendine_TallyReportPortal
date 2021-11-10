--- Pending Purchase Order Register Report 4.0 ------
Declare @CompanyIDs as Varchar(2000)='', @PO_DateFrom as Date=null, @PO_DateTo as Date=null, @PONo_List as Varchar(250)='',	@PartyName_List as Varchar(250)='',@ItemName_List as Varchar(250)=''

---- Init the Value for Validate ----
Set @PO_DateFrom='01/01/2021'
Set @PO_DateTo='01/30/2021'
Set @CompanyIDs='Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)'
Set @PONo_List=''
Set @PartyName_List='ADDAPT LIFE CARE'
Set @ItemName_List=''

IF(@PO_DateFrom is null) BEGIN  SET @PO_DateFrom ='1900-01-01' END    
IF(@PO_DateTo is null) BEGIN SET @PO_DateTo ='2100-01-01' END

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpPendingPurchaseOrder') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpPOList') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID('tempdb..#tmpItemName') IS NOT NULL DROP TABLE #tmpItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyIDs


--SELECT NAME AS 'CompanyID' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''))
SELECT NAME AS 'PartyLedgerName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'PONumber' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''))
SELECT NAME AS 'ItemName' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''))

------------- GET PO DETAILS ----------------------------
Select  VH.ID, vh.Date as [PODate], vh.Reference as [PONumber], VH.Reference, Upper(vh.PartyLedgerName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    COALESCE(LTrim(RTrim(LEFT(BT.PreClosedQty, PATINDEX('%[0-9][^0-9]%', BT.PreClosedQty )))),0) as [PreClosedQty],
		CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = '01-Jan-1900' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Mst_VoucherType as VT 

Inner Join TD_Txn_VchHdr as VH ON VH.VoucherTypeName=VT.VoucherTypeName And VT.CompanyID=@CompanyID
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.ID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  GVH.CompanyId=vh.CompanyID And VH.Reference = GVH.OrderNo  And GVH.VoucherTypeName Like '%GRN%'
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.ID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.ID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.InvLineId = IL.Id 

Where VT.VoucherType ='Purchase Order' And  VT.CompanyID=@CompanyID
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo --And vh.CompanyId=@CompanyID
And (@PartyName_List  <> '' AND vh.PartyLedgerName IN (SELECT PartyLedgerName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (@PONo_List  <> '' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,PPO.PreClosedQty, -- PPO.Discount , PPO.PORate, PPO.Discount , 
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - (Sum(PPO.GRNPOQTY) + PPO.PreClosedQty)) As [BalanceQTY], ((PPO.POQTY - (Sum(PPO.GRNPOQTY)+ PPO.PreClosedQty)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate, PPO.PreClosedQty
Having (PPO.POQTY - (Sum(PPO.GRNPOQTY) + PPO.PreClosedQty) )>0  Order By PODate Desc