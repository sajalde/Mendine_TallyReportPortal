--- Godown Stock Transfer Report ----
DECLARE @CompanyNames as Varchar(2000)='', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='', @StockCategory_List as Varchar(250)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
SET @DateFrom ='01/01/2020'
SET @DateTo = '10/30/2020'
SET @PartyName_List = ''
SET @StockCategory_List=''

Select Top(100) bl.EntryDate, IL.StockItemName, il.BilledQuantity, il.ActualUOM, si.StockCategory, il.Rate,  bl.Amount, vt.VoucherType
,bl.GodownName, BL.DestinationGodownName
From TD_Txn_BatchLine as BL 
INNER JOIN TD_Txn_InvLine as IL ON BL.CompanyID = IL.CompanyId AND BL.VoucherId = IL.VoucherID AND BL.AccLineNo = IL.AccLineNo AND BL.InvLineNo = IL.InvLineNo
INNER JOIN TD_Mst_StockItem as SI ON IL.CompanyId = SI.CompanyID AND IL.StockItemName = SI.StockItemName 
INNER JOIN TD_Mst_Company as MC ON MC.CompanyID=BL.CompanyID
INNER JOIN TD_Mst_VoucherType as VT ON MC.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_VchHdr as VH ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.VoucherID = AL.VoucherID and IL.CompanyId = AL.CompanyID AND IL.VoucherID = AL.VoucherID AND IL.AccLineNo = AL.AccLineNo
where mc.CompanyID=2 And (VT.VoucherType ='Stock Journal' OR VT.VoucherType= '#Internal Stock Journal#')
AND (VH.IsOptional <> 1 AND VH.IsCancelled <> 1 AND VH.IsDeleted <> 1) AND AL.IsPartyLedger = 0  And MC.CompanyID IN (2) 
and bl.EntryDate >= @DateFrom  and bl.EntryDate <= @DateTo
Order by bl.EntryDate Desc






	--Select top(100) * from TD_Txn_BatchLine where VoucherId=202955
	--Select top(100) * from TD_Txn_AccLine where VoucherId=202955
	--Select top(100) * from TD_Txn_VchHdr where VoucherId=202955
	--Select top(100) * from TD_Txn_AccLine where VoucherId=202955
	--Select distinct VoucherType from TD_Mst_VoucherType