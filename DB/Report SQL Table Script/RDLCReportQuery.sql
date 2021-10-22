USE [EasyReports4.0_Tally]
GO
/****** Object:  Table [dbo].[RDLCReportQuery]    Script Date: 8/12/2021 8:42:29 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RDLCReportQuery](
	[PK_ReportID] [int] IDENTITY(1,1) NOT NULL,
	[IsReleasedInLive] [bit] NULL,
	[IsActive] [bit] NULL,
	[ReportModule] [varchar](150) NULL,
	[ViewOrder] [int] NULL,
	[ReportName] [varchar](50) NULL,
	[ReportDisplayName] [varchar](150) NULL,
	[ReportURL] [varchar](150) NULL,
	[ReportSQLQuery] [nvarchar](max) NULL,
	[ReportSQLQuery_Full] [nvarchar](max) NULL,
	[ReportSQLQuery_Ver4] [nvarchar](max) NULL,
	[ReportSQLQuery_Ver4_Full] [nvarchar](max) NULL,
	[ParameterList] [varchar](500) NULL,
	[Version] [int] NULL,
	[Status] [varchar](25) NULL,
 CONSTRAINT [PK_RDLCReportQuery] PRIMARY KEY CLUSTERED 
(
	[PK_ReportID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[RDLCReportQuery] ON 

INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (1, 1, 1, N'Purchase', 1, N'PendingPurchaseOrder', N'Pending Purchase Order', N'~/OnlineReport/PendingPurchaseOrder.aspx', N'IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPendingPurchaseOrder'') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpPOList'') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID(''tempdb..#tmpItemName'') IS NOT NULL DROP TABLE #tmpItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyIDs


--SELECT NAME AS ''CompanyID'' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
SELECT NAME AS ''PartyLedgerName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''''))

------------- GET PO DETAILS ----------------------------
Select  VH.ID, vh.Date as [PODate], vh.Reference as [PONumber], VH.Reference, Upper(vh.PartyLedgerName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Mst_VoucherType as VT 

Inner Join TD_Txn_VchHdr as VH ON VH.VoucherTypeName=VT.VoucherTypeName And VT.CompanyID=@CompanyID
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.ID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  VH.Reference = GVH.OrderNo 
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.ID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.ID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.AccLineId = IL.AccLineId AND BT.InvLineId = IL.Id 

Where VT.VoucherType =''Purchase Order'' And  VT.CompanyID=@CompanyID
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo --And vh.CompanyId=@CompanyID
And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyLedgerName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (@PONo_List  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,-- PPO.Discount , PPO.PORate, PPO.Discount ,
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - Sum(PPO.GRNPOQTY)) As [BalanceQTY], ((PPO.POQTY - Sum(PPO.GRNPOQTY)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate
Having (PPO.POQTY - Sum(PPO.GRNPOQTY))>0  Order By PODate Desc', N'--- Pending Purchase Order Report 4.0 ------
Declare @CompanyIDs as Varchar(2000)='''', @PO_DateFrom as Date=null, @PO_DateTo as Date=null, @PONo_List as Varchar(250)='''',	@PartyName_List as Varchar(250)='''',@ItemName_List as Varchar(250)=''''

---- Init the Value for Validate ----
Set @PO_DateFrom=''05/01/2021''
Set @PO_DateTo=''06/30/2021''
Set @CompanyIDs=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
Set @PONo_List=''''
Set @PartyName_List=''''
Set @ItemName_List=''''

IF(@PO_DateFrom is null) BEGIN  SET @PO_DateFrom =''1900-01-01'' END    
IF(@PO_DateTo is null) BEGIN SET @PO_DateTo =''2100-01-01'' END

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPendingPurchaseOrder'') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpPOList'') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID(''tempdb..#tmpItemName'') IS NOT NULL DROP TABLE #tmpItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyIDs


--SELECT NAME AS ''CompanyID'' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
SELECT NAME AS ''PartyLedgerName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''''))

------------- GET PO DETAILS ----------------------------
Select  VH.ID, vh.Date as [PODate], vh.Reference as [PONumber], VH.Reference, Upper(vh.PartyLedgerName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Mst_VoucherType as VT 

Inner Join TD_Txn_VchHdr as VH ON VH.VoucherTypeName=VT.VoucherTypeName And VT.CompanyID=@CompanyID
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.ID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  VH.Reference = GVH.OrderNo 
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.ID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.ID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.AccLineId = IL.AccLineId AND BT.InvLineId = IL.Id 

Where VT.VoucherType =''Purchase Order'' And  VT.CompanyID=@CompanyID
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo --And vh.CompanyId=@CompanyID
And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyLedgerName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (@PONo_List  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,-- PPO.Discount , PPO.PORate, PPO.Discount ,
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - Sum(PPO.GRNPOQTY)) As [BalanceQTY], ((PPO.POQTY - Sum(PPO.GRNPOQTY)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate
Having (PPO.POQTY - Sum(PPO.GRNPOQTY))>0  Order By PODate Desc', N'IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPendingPurchaseOrder'') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpPOList'') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID(''tempdb..#tmpItemName'') IS NOT NULL DROP TABLE #tmpItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyIDs


--SELECT NAME AS ''CompanyID'' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
SELECT NAME AS ''PartyLedgerName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''''))

------------- GET PO DETAILS ----------------------------
Select  VH.ID, vh.Date as [PODate], vh.Reference as [PONumber], VH.Reference, Upper(vh.PartyLedgerName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    COALESCE(LTrim(RTrim(LEFT(BT.PreClosedQty, PATINDEX(''%[0-9][^0-9]%'', BT.PreClosedQty )))),0) as [PreClosedQty],
		CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Mst_VoucherType as VT 

Inner Join TD_Txn_VchHdr as VH ON VH.VoucherTypeName=VT.VoucherTypeName And VT.CompanyID=@CompanyID
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.ID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  GVH.CompanyId=vh.CompanyID And VH.Reference = GVH.OrderNo  And GVH.VoucherTypeName Like ''%GRN%''
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.ID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.ID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.InvLineId = IL.Id 

Where VT.VoucherType =''Purchase Order'' And  VT.CompanyID=@CompanyID
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo --And vh.CompanyId=@CompanyID
And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyLedgerName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (@PONo_List  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,PPO.PreClosedQty, -- PPO.Discount , PPO.PORate, PPO.Discount , 
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - (Sum(PPO.GRNPOQTY) + PPO.PreClosedQty)) As [BalanceQTY], ((PPO.POQTY - (Sum(PPO.GRNPOQTY)+ PPO.PreClosedQty)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate, PPO.PreClosedQty
Having (PPO.POQTY - (Sum(PPO.GRNPOQTY) + PPO.PreClosedQty) )>0  Order By PODate Desc', N'--- Pending Purchase Order Report 4.0 ------
Declare @CompanyIDs as Varchar(2000)='''', @PO_DateFrom as Date=null, @PO_DateTo as Date=null, @PONo_List as Varchar(250)='''',	@PartyName_List as Varchar(250)='''',@ItemName_List as Varchar(250)=''''

---- Init the Value for Validate ----
Set @PO_DateFrom=''01/01/2021''
Set @PO_DateTo=''01/30/2021''
Set @CompanyIDs=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
Set @PONo_List=''''
Set @PartyName_List=''ADDAPT LIFE CARE''
Set @ItemName_List=''''

IF(@PO_DateFrom is null) BEGIN  SET @PO_DateFrom =''1900-01-01'' END    
IF(@PO_DateTo is null) BEGIN SET @PO_DateTo =''2100-01-01'' END

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPendingPurchaseOrder'') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpPOList'') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID(''tempdb..#tmpItemName'') IS NOT NULL DROP TABLE #tmpItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyIDs


--SELECT NAME AS ''CompanyID'' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
SELECT NAME AS ''PartyLedgerName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''''))

------------- GET PO DETAILS ----------------------------
Select  VH.ID, vh.Date as [PODate], vh.Reference as [PONumber], VH.Reference, Upper(vh.PartyLedgerName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    COALESCE(LTrim(RTrim(LEFT(BT.PreClosedQty, PATINDEX(''%[0-9][^0-9]%'', BT.PreClosedQty )))),0) as [PreClosedQty],
		CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Mst_VoucherType as VT 

Inner Join TD_Txn_VchHdr as VH ON VH.VoucherTypeName=VT.VoucherTypeName And VT.CompanyID=@CompanyID
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.ID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  GVH.CompanyId=vh.CompanyID And VH.Reference = GVH.OrderNo  And GVH.VoucherTypeName Like ''%GRN%''
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.ID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.ID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.InvLineId = IL.Id 

Where VT.VoucherType =''Purchase Order'' And  VT.CompanyID=@CompanyID
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo --And vh.CompanyId=@CompanyID
And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyLedgerName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (@PONo_List  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,PPO.PreClosedQty, -- PPO.Discount , PPO.PORate, PPO.Discount , 
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - (Sum(PPO.GRNPOQTY) + PPO.PreClosedQty)) As [BalanceQTY], ((PPO.POQTY - (Sum(PPO.GRNPOQTY)+ PPO.PreClosedQty)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate, PPO.PreClosedQty
Having (PPO.POQTY - (Sum(PPO.GRNPOQTY) + PPO.PreClosedQty) )>0  Order By PODate Desc', NULL, 1, N'LIVE')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (2, 1, 1, N'Purchase', 3, N'VendorOutstandingReport', N'Vendor Outstanding', N'~/OnlineReport/VendorOutstanding.aspx', N'IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from  dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.ID as [CompanyID], Upper(AH.PartyLedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName], AH.Date As BillDate, BL.BillName as [BillNo],
BL.Amount As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_VchHdr as AH ON  AH.CompanyID = MC.ID 
INNER JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  MC.ID And BL.VoucherId= AH.Id And BL.BillType=''New Ref''  --And AH.Reference=bl.BillName
WHERE (VT.VoucherType = ''Purchase'' OR VT.VoucherType = ''Journal'') And
 (@PartyName_List  <> '''' AND AH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND AH.PartyLedgerName = AH.PartyLedgerName ))
And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
And BL.Amount > 0 --And  AH.PartyLedgerName=''Kamala Pal''
GROUP BY MC.ID, AH.Date, AH.PartyLedgerName, 	BL.BillName,	AH.CostCentreName, BL.Amount

Select b.CompanyID as ID,  B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount, @DateFrom as [PaymentDate],  IsNull(SUM(BL.Amount*-1),0) as PaymentAmount, 
	 (b.BillAmount - IsNull(SUM(BL.Amount*-1),0)) as [PendingAmount], DATEDIFF(D,BillDate,@DateFrom) As PaymentDays
INTO #Payments
From #Bills as B
Left Outer JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  B.CompanyID  AND  B.BillNo=bl.BillName And b.PartyName=BL.LedgerName And BL.BillType=''Agst Ref''
Group by b.CompanyID, B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount

Select P.*, L.StateName, L.ParentLedgerGroup as PartyGroup
From #Payments as P
LEFT OUTER JOIN TD_Mst_Ledger L ON P.ID = L.CompanyID And P.PartyName = L.LedgerName
Where P.PendingAmount>1 And P.PaymentDays>0 Order By p.BillDate, p.PartyName', N'-- Vendor Outstanding Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='''', @CostCenter_List as Varchar(250)=''''
Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/07/2021''
SET @DateTo = ''01/01/2021''
SET @PartyName_List = ''''

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from  dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.ID as [CompanyID], Upper(AH.PartyLedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName], AH.Date As BillDate, BL.BillName as [BillNo],
BL.Amount As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_VchHdr as AH ON  AH.CompanyID = MC.ID 
INNER JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  MC.ID And BL.VoucherId= AH.Id And BL.BillType=''New Ref''  --And AH.Reference=bl.BillName
WHERE (VT.VoucherType = ''Purchase'' OR VT.VoucherType = ''Journal'') And
 (@PartyName_List  <> '''' AND AH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND AH.PartyLedgerName = AH.PartyLedgerName ))
And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
And BL.Amount > 0 --And  AH.PartyLedgerName=''Kamala Pal''
GROUP BY MC.ID, AH.Date, AH.PartyLedgerName, 	BL.BillName,	AH.CostCentreName, BL.Amount

Select b.CompanyID as ID,  B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount, @DateFrom as [PaymentDate],  IsNull(SUM(BL.Amount*-1),0) as PaymentAmount, 
	 (b.BillAmount - IsNull(SUM(BL.Amount*-1),0)) as [PendingAmount], DATEDIFF(D,BillDate,@DateFrom) As PaymentDays
INTO #Payments
From #Bills as B
Left Outer JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  B.CompanyID  AND  B.BillNo=bl.BillName And b.PartyName=BL.LedgerName And BL.BillType=''Agst Ref''
Group by b.CompanyID, B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount

Select P.*, L.StateName, L.ParentLedgerGroup as PartyGroup
From #Payments as P
LEFT OUTER JOIN TD_Mst_Ledger L ON P.ID = L.CompanyID And P.PartyName = L.LedgerName
Where P.PendingAmount>1 And P.PaymentDays>0 Order By p.BillDate, p.PartyName', N'IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from  dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.ID as [CompanyID], Upper(BL.LedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName], Bl.Date As BillDate, BL.BillName as [BillNo],
BL.Amount As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_VchHdr as AH ON  AH.CompanyID = MC.ID 
INNER JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  MC.ID And BL.VoucherId= AH.Id And BL.BillType=''New Ref''  --And AH.Reference=bl.BillName
WHERE (VT.VoucherType = ''Purchase'' OR VT.VoucherType = ''Journal'') And
 (@PartyName_List  <> '''' AND Bl.LedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND Bl.LedgerName = Bl.LedgerName ))
And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
And AH.IsOptional=0 And AH.IsDeleted=0 And AH.IsCancelled=0  
And BL.Amount > 0 
GROUP BY MC.ID, Bl.Date, BL.LedgerName, 	BL.BillName,	AH.CostCentreName, BL.Amount


Select b.CompanyID as ID,  B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount, @DateFrom as [PaymentDate],  IsNull(SUM(BL.Amount*-1),0) as PaymentAmount, 
	 (b.BillAmount - IsNull(SUM(BL.Amount*-1),0)) as [PendingAmount], DATEDIFF(D,BillDate,@DateFrom) As PaymentDays
INTO #Payments
From #Bills as B
Left Outer JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  B.CompanyID  AND  B.BillNo=bl.BillName And b.PartyName=BL.LedgerName And BL.BillType=''Agst Ref''
Group by b.CompanyID, B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount

Select P.*, L.StateName, L.ParentLedgerGroup as PartyGroup
From #Payments as P
LEFT OUTER JOIN TD_Mst_Ledger L ON P.ID = L.CompanyID And P.PartyName = L.LedgerName
Where P.PendingAmount>0 And P.PaymentDays>=0 
 Order By p.BillDate, p.PartyName', N'-- Vendor Outstanding Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='''', @CostCenter_List as Varchar(250)=''''
Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''07/31/2021''
SET @PartyName_List = ''GOPAL MONDAL''

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from  dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.ID as [CompanyID], Upper(BL.LedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName], Bl.Date As BillDate, BL.BillName as [BillNo],
BL.Amount As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_VchHdr as AH ON  AH.CompanyID = MC.ID 
INNER JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  MC.ID And BL.VoucherId= AH.Id And BL.BillType=''New Ref''  --And AH.Reference=bl.BillName
WHERE (VT.VoucherType = ''Purchase'' OR VT.VoucherType = ''Journal'') And
 (@PartyName_List  <> '''' AND Bl.LedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND Bl.LedgerName = Bl.LedgerName ))
And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
And AH.IsOptional=0 And AH.IsDeleted=0 And AH.IsCancelled=0  
And BL.Amount > 0 
GROUP BY MC.ID, Bl.Date, BL.LedgerName, 	BL.BillName,	AH.CostCentreName, BL.Amount


Select b.CompanyID as ID,  B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount, @DateFrom as [PaymentDate],  IsNull(SUM(BL.Amount*-1),0) as PaymentAmount, 
	 (b.BillAmount - IsNull(SUM(BL.Amount*-1),0)) as [PendingAmount], DATEDIFF(D,BillDate,@DateFrom) As PaymentDays
INTO #Payments
From #Bills as B
Left Outer JOIN TD_Txn_BillLine as BL ON BL.CompanyID =  B.CompanyID  AND  B.BillNo=bl.BillName And b.PartyName=BL.LedgerName And BL.BillType=''Agst Ref''
Group by b.CompanyID, B.PartyName, b.CostCentreName, b.BillDate, b.BillNo, b.BillAmount

Select P.*, L.StateName, L.ParentLedgerGroup as PartyGroup
From #Payments as P
LEFT OUTER JOIN TD_Mst_Ledger L ON P.ID = L.CompanyID And P.PartyName = L.LedgerName
Where P.PendingAmount>0 And P.PaymentDays>=0 
 Order By p.BillDate, p.PartyName', NULL, 1, N'LIVE')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (3, 1, 1, N'Stock', 3, N'GodownStockTransfer', N'Godown Stock Transfer', N'~/OnlineReport/GodownStockTransfer.aspx', N'IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockCategory'') IS NOT NULL DROP TABLE #tmpStockCategory
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpSourceGodownName'') IS NOT NULL DROP TABLE #tmpSourceGodownName
IF OBJECT_ID(''tempdb..#tmpDestinationGodownName'') IS NOT NULL DROP TABLE #tmpDestinationGodownName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''StockCategory'' INTO #tmpStockCategory from	 dbo.GetTableFromString(isnull(@StockCategory_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpSourceGodownName from dbo.GetTableFromString(isnull(@GodownName_Source_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpDestinationGodownName from dbo.GetTableFromString(isnull(@GodownName_Destination_List,''''))

Select  bl.EntryDate, IL.StockItemName, il.BilledQuantity, il.ActualUOM, si.StockCategory, il.Rate,  bl.Amount, vt.VoucherType
,bl.GodownName, BL.DestinationGodownName
From TD_Txn_BatchLine as BL 
INNER JOIN TD_Txn_InvLine as IL ON BL.CompanyID = IL.CompanyId AND BL.VoucherId = IL.VoucherID AND BL.AccLineNo = IL.AccLineNo AND BL.InvLineNo = IL.InvLineNo
INNER JOIN TD_Mst_StockItem as SI ON IL.CompanyId = SI.CompanyID AND IL.StockItemName = SI.StockItemName 
INNER JOIN TD_Mst_Company as MC ON MC.CompanyID=BL.CompanyID
INNER JOIN TD_Mst_VoucherType as VT ON MC.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_VchHdr as VH ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.VoucherID = AL.VoucherID and IL.CompanyId = AL.CompanyID AND IL.VoucherID = AL.VoucherID AND IL.AccLineNo = AL.AccLineNo
where (VT.VoucherType =''Stock Journal'' OR VT.VoucherType= ''#Internal Stock Journal#'')
AND (VH.IsOptional <> 1 AND VH.IsCancelled <> 1 AND VH.IsDeleted <> 1) AND AL.IsPartyLedger = 0  --And MC.CompanyID IN (2) 
and CAST(bl.EntryDate AS DATE) >= @DateFrom  and CAST(bl.EntryDate AS DATE) <= @DateTo
And (@CompanyNames  <> '''' AND MC.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND MC.CompanyID = MC.CompanyID))
And (@StockCategory_List  <> '''' AND SI.StockCategory IN (SELECT StockCategory FROM #tmpStockCategory)  OR (@StockCategory_List = ''''  AND SI.StockCategory  = SI.StockCategory))
And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName ))
And (@GodownName_Source_List  <> '''' AND bl.GodownName IN (SELECT GodownName FROM #tmpSourceGodownName)  OR (@GodownName_Source_List = ''''  AND bl.GodownName = bl.GodownName ))
And (@GodownName_Destination_List  <> '''' AND BL.DestinationGodownName IN (SELECT GodownName FROM #tmpDestinationGodownName)  OR (@GodownName_Destination_List = ''''  AND BL.DestinationGodownName = BL.DestinationGodownName ))

Order by bl.EntryDate Desc', N'--- Godown Stock Transfer Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='''',
@StockCategory_List as Varchar(2000)='''', @StockItemName_List as Varchar(2000)='''', @GodownName_Source_List as Varchar(2000)='''', @GodownName_Destination_List as Varchar(2000)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''03/15/2021''
SET @DateTo = ''03/15/2021''
SET @PartyName_List = ''''
SET @StockCategory_List=''''
SET @StockItemName_List=''''
SET @GodownName_Source_List=''''
SET @GodownName_Destination_List=''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockCategory'') IS NOT NULL DROP TABLE #tmpStockCategory
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpSourceGodownName'') IS NOT NULL DROP TABLE #tmpSourceGodownName
IF OBJECT_ID(''tempdb..#tmpDestinationGodownName'') IS NOT NULL DROP TABLE #tmpDestinationGodownName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''StockCategory'' INTO #tmpStockCategory from	 dbo.GetTableFromString(isnull(@StockCategory_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpSourceGodownName from dbo.GetTableFromString(isnull(@GodownName_Source_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpDestinationGodownName from dbo.GetTableFromString(isnull(@GodownName_Destination_List,''''))

Select  bl.EntryDate, IL.StockItemName, il.BilledQuantity, il.ActualUOM, si.StockCategory, il.Rate,  bl.Amount, vt.VoucherType
,bl.GodownName, BL.DestinationGodownName
From TD_Txn_BatchLine as BL 
INNER JOIN TD_Txn_InvLine as IL ON BL.CompanyID = IL.CompanyId AND BL.VoucherId = IL.VoucherID AND BL.AccLineNo = IL.AccLineNo AND BL.InvLineNo = IL.InvLineNo
INNER JOIN TD_Mst_StockItem as SI ON IL.CompanyId = SI.CompanyID AND IL.StockItemName = SI.StockItemName 
INNER JOIN TD_Mst_Company as MC ON MC.CompanyID=BL.CompanyID
INNER JOIN TD_Mst_VoucherType as VT ON MC.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_VchHdr as VH ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.VoucherID = AL.VoucherID and IL.CompanyId = AL.CompanyID AND IL.VoucherID = AL.VoucherID AND IL.AccLineNo = AL.AccLineNo
where (VT.VoucherType =''Stock Journal'' OR VT.VoucherType= ''#Internal Stock Journal#'')
AND (VH.IsOptional <> 1 AND VH.IsCancelled <> 1 AND VH.IsDeleted <> 1) AND AL.IsPartyLedger = 0  --And MC.CompanyID IN (2) 
and CAST(bl.EntryDate AS DATE) >= @DateFrom  and CAST(bl.EntryDate AS DATE) <= @DateTo
And (@CompanyNames  <> '''' AND MC.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND MC.CompanyID = MC.CompanyID))
And (@StockCategory_List  <> '''' AND SI.StockCategory IN (SELECT StockCategory FROM #tmpStockCategory)  OR (@StockCategory_List = ''''  AND SI.StockCategory  = SI.StockCategory))
And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName ))
And (@GodownName_Source_List  <> '''' AND bl.GodownName IN (SELECT GodownName FROM #tmpSourceGodownName)  OR (@GodownName_Source_List = ''''  AND bl.GodownName = bl.GodownName ))
And (@GodownName_Destination_List  <> '''' AND BL.DestinationGodownName IN (SELECT GodownName FROM #tmpDestinationGodownName)  OR (@GodownName_Destination_List = ''''  AND BL.DestinationGodownName = BL.DestinationGodownName ))

Order by bl.EntryDate Desc', N'IF OBJECT_ID(''tempdb..#tmpStockCategory'') IS NOT NULL DROP TABLE #tmpStockCategory
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpSourceGodownName'') IS NOT NULL DROP TABLE #tmpSourceGodownName
IF OBJECT_ID(''tempdb..#tmpDestinationGodownName'') IS NOT NULL DROP TABLE #tmpDestinationGodownName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockCategory'' INTO #tmpStockCategory from	 dbo.GetTableFromString(isnull(@StockCategory_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpSourceGodownName from dbo.GetTableFromString(isnull(@GodownName_Source_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpDestinationGodownName from dbo.GetTableFromString(isnull(@GodownName_Destination_List,''''))

Select VH.Date as [EntryDate], IL.StockItemName, il.BilledQuantity, il.ActualUOM, si.StockCategory, il.Rate,  bl.Amount, bl.GodownName,
vt.VoucherType +''-''+vh.Reference as [VoucherType] ,  vh.DestinationGodown as [DestinationGodownName]
From TD_Mst_Company as MC  
INNER JOIN TD_Mst_VoucherType as VT ON MC.Id = VT.CompanyID 
INNER JOIN TD_Txn_VchHdr as VH ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName 
INNER JOIN TD_Txn_BatchLine as BL On BL.CompanyId=mc.Id And VH.Id=bl.VoucherId
INNER JOIN TD_Txn_InvLine as IL ON BL.CompanyID = IL.CompanyId AND BL.VoucherId = IL.VoucherID AND BL.AccLineId = IL.AccLineId AND BL.InvLineId = IL.Id
INNER JOIN TD_Mst_StockItem as SI ON IL.CompanyId = SI.CompanyID AND IL.StockItemName = SI.StockItemName 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.Id = AL.VoucherID and IL.CompanyId = AL.CompanyID AND IL.VoucherID = AL.VoucherID AND IL.AccLineId = AL.Id
where MC.Id=@CompanyID And (VT.VoucherType =''Stock Journal'' OR VT.VoucherType= ''#Internal Stock Journal#'') And (VH.DestinationGodown <> bl.GodownName)
AND (VH.IsOptional <> 1 AND VH.IsCancelled <> 1 AND VH.IsDeleted <> 1) AND AL.IsPartyLedger = 0  
and CAST(VH.Date AS DATE) >= @DateFrom  and CAST(VH.Date AS DATE) <= @DateTo And bl.CompanyId=@CompanyID
And (@StockCategory_List  <> '''' AND SI.StockCategory IN (SELECT StockCategory FROM #tmpStockCategory)  OR (@StockCategory_List = ''''  AND SI.StockCategory  = SI.StockCategory))
And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName ))
And (@GodownName_Source_List  <> '''' AND bl.GodownName IN (SELECT GodownName FROM #tmpSourceGodownName)  OR (@GodownName_Source_List = ''''  AND bl.GodownName = bl.GodownName ))
And (@GodownName_Destination_List  <> '''' AND BL.DestinationGodownName IN (SELECT GodownName FROM #tmpDestinationGodownName)  OR (@GodownName_Destination_List = ''''  AND BL.DestinationGodownName = BL.DestinationGodownName ))
--Group by VH.Date, vt.VoucherType, vh.Reference,  vh.DestinationGodown
Order by bl.EntryDate Desc', N'--- Godown Stock Transfer Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='''',
@StockCategory_List as Varchar(2000)='''', @StockItemName_List as Varchar(2000)='''', @GodownName_Source_List as Varchar(2000)='''', @GodownName_Destination_List as Varchar(2000)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''06/01/2021''
SET @DateTo = ''06/04/2021''
SET @PartyName_List = ''''
SET @StockCategory_List=''''
SET @StockItemName_List=''''
SET @GodownName_Source_List=''''
SET @GodownName_Destination_List=''''

IF OBJECT_ID(''tempdb..#tmpStockCategory'') IS NOT NULL DROP TABLE #tmpStockCategory
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpSourceGodownName'') IS NOT NULL DROP TABLE #tmpSourceGodownName
IF OBJECT_ID(''tempdb..#tmpDestinationGodownName'') IS NOT NULL DROP TABLE #tmpDestinationGodownName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockCategory'' INTO #tmpStockCategory from	 dbo.GetTableFromString(isnull(@StockCategory_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpSourceGodownName from dbo.GetTableFromString(isnull(@GodownName_Source_List,''''))
SELECT NAME AS ''GodownName'' INTO #tmpDestinationGodownName from dbo.GetTableFromString(isnull(@GodownName_Destination_List,''''))

Select VH.Date as [EntryDate], IL.StockItemName, il.BilledQuantity, il.ActualUOM, si.StockCategory, il.Rate,  bl.Amount, bl.GodownName,
vt.VoucherType +''-''+vh.Reference as [VoucherType] ,  vh.DestinationGodown as [DestinationGodownName]
From TD_Mst_Company as MC  
INNER JOIN TD_Mst_VoucherType as VT ON MC.Id = VT.CompanyID 
INNER JOIN TD_Txn_VchHdr as VH ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName 
INNER JOIN TD_Txn_BatchLine as BL On BL.CompanyId=mc.Id And VH.Id=bl.VoucherId
INNER JOIN TD_Txn_InvLine as IL ON BL.CompanyID = IL.CompanyId AND BL.VoucherId = IL.VoucherID AND BL.AccLineId = IL.AccLineId AND BL.InvLineId = IL.Id
INNER JOIN TD_Mst_StockItem as SI ON IL.CompanyId = SI.CompanyID AND IL.StockItemName = SI.StockItemName 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.Id = AL.VoucherID and IL.CompanyId = AL.CompanyID AND IL.VoucherID = AL.VoucherID AND IL.AccLineId = AL.Id
where MC.Id=@CompanyID And (VT.VoucherType =''Stock Journal'' OR VT.VoucherType= ''#Internal Stock Journal#'') And (VH.DestinationGodown <> bl.GodownName)
AND (VH.IsOptional <> 1 AND VH.IsCancelled <> 1 AND VH.IsDeleted <> 1) AND AL.IsPartyLedger = 0  
and CAST(VH.Date AS DATE) >= @DateFrom  and CAST(VH.Date AS DATE) <= @DateTo And bl.CompanyId=@CompanyID
And (@StockCategory_List  <> '''' AND SI.StockCategory IN (SELECT StockCategory FROM #tmpStockCategory)  OR (@StockCategory_List = ''''  AND SI.StockCategory  = SI.StockCategory))
And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName ))
And (@GodownName_Source_List  <> '''' AND bl.GodownName IN (SELECT GodownName FROM #tmpSourceGodownName)  OR (@GodownName_Source_List = ''''  AND bl.GodownName = bl.GodownName ))
And (@GodownName_Destination_List  <> '''' AND BL.DestinationGodownName IN (SELECT GodownName FROM #tmpDestinationGodownName)  OR (@GodownName_Destination_List = ''''  AND BL.DestinationGodownName = BL.DestinationGodownName ))
--Group by VH.Date, vt.VoucherType, vh.Reference,  vh.DestinationGodown
Order by bl.EntryDate Desc', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (4, 1, 1, N'Stock', 4, N'GodownStockSummary', N'Godown Stock Summary', N'~/OnlineReport/GodownStockSummary.aspx', N'IF OBJECT_ID(''tempdb..#Purchase'') IS NOT NULL DROP TABLE #Purchase
IF OBJECT_ID(''tempdb..#tmpGodwnName'') IS NOT NULL DROP TABLE #tmpGodwnName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#tmpInward'') IS NOT NULL DROP TABLE #tmpInward
IF OBJECT_ID(''tempdb..#tmpOutward'') IS NOT NULL DROP TABLE #tmpOutward

Declare @CompanyID as Int
Select @CompanyID= CompanyID From TD_Mst_Company  Where CompanyName=@CompanyNames

SELECT NAME AS ''GodwnName'' INTO #tmpGodwnName from	 dbo.GetTableFromString(isnull(@GodwnName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

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


	Declare @ShowStockDate as Datetime

	--Select  distinct top(1) @ShowStockDate=stockdate 	From TD_Txn_StockDetails  
	--Where CompanyID=@CompanyID 	And StockDate>=@DateFrom 	order by stockdate Desc
	--Print @ShowStockDate

	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select GodownName, StockItemName,  Sum(Quantity) as [OpeningStock_QTY], Sum(Amount) as [OpeningStock_Value] 
	Into #tmpOPBalance
	From TD_Txn_StockDetails as SD
	Where CompanyID=@CompanyID And StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by StockItemName, GodownName

	--Select * from  #tmpOPBalance

	---- Fetch In ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [InWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Inward_Value]	
	Into #tmpInward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.VoucherID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.VoucherID
	Where (VH.VoucherTypeName LIKE ''Purchase for%'') And  VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And VH.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	
	
	--Select * from  #tmpInward

	---- Fetch Out ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [OutWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Outward_Value]	
	Into #tmpOutward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.VoucherID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.VoucherID
	Where (VH.VoucherTypeName LIKE ''Sales'')
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	

	--Select * from  #tmpOutward


	select  S.StockItemName as [StockItemName], Sum(IsNull(Op.OpeningStock_QTY,0)) as [OpeningStock_QTY], Sum(IsNull(op.OpeningStock_Value,0)) as [OpeningStock_Value],
	Sum(IsNull(I.InWard_QTY,0)) as [InWard_QTY],  Sum(IsNull(I.Inward_Value,0)) as [Inward_Value], Sum(IsNull(O.OutWard_QTY,0)) as [OutWard_QTY], Sum(IsNull(O.Outward_Value,0)) as [Outward_Value],
	((Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0))) - Sum(IsNull(O.OutWard_QTY,0))) as [Closing_QTY]
	, ((Sum(IsNull(Op.OpeningStock_Value,0)) + Sum(IsNull(I.Inward_Value,0))) - Sum(IsNull(O.Outward_Value,0))) as [Closing_Value]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #tmpInward as I ON I.StockItemName=S.StockItemName
	Left Outer Join #tmpOutward as O ON O.StockItemName=S.StockItemName
	Where  S.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@GodwnName_List  <> '''' AND OP.GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND OP.GodownName = OP.GodownName))
	Group by S.StockItemName
	Order by S.StockItemName', N'--- GodownStockSummary Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodwnName_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2020''
SET @DateTo = ''04/01/2020''
SET @GodwnName_List = ''''
SET @StockItemName_List=''100 ML BRUTE PET BOTTLE''

IF OBJECT_ID(''tempdb..#Purchase'') IS NOT NULL DROP TABLE #Purchase
IF OBJECT_ID(''tempdb..#tmpGodwnName'') IS NOT NULL DROP TABLE #tmpGodwnName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#tmpInward'') IS NOT NULL DROP TABLE #tmpInward
IF OBJECT_ID(''tempdb..#tmpOutward'') IS NOT NULL DROP TABLE #tmpOutward

Declare @CompanyID as Int
Select @CompanyID= CompanyID From TD_Mst_Company  Where CompanyName=@CompanyNames

SELECT NAME AS ''GodwnName'' INTO #tmpGodwnName from	 dbo.GetTableFromString(isnull(@GodwnName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

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


	Declare @ShowStockDate as Datetime

	--Select  distinct top(1) @ShowStockDate=stockdate 	From TD_Txn_StockDetails  
	--Where CompanyID=@CompanyID 	And StockDate>=@DateFrom 	order by stockdate Desc
	--Print @ShowStockDate

	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select GodownName, StockItemName,  Sum(Quantity) as [OpeningStock_QTY], Sum(Amount) as [OpeningStock_Value] 
	Into #tmpOPBalance
	From TD_Txn_StockDetails as SD
	Where CompanyID=@CompanyID And StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by StockItemName, GodownName

	--Select * from  #tmpOPBalance

	---- Fetch In ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [InWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Inward_Value]	
	Into #tmpInward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.VoucherID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.VoucherID
	Where (VH.VoucherTypeName LIKE ''Purchase for%'') And  VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And VH.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	
	
	--Select * from  #tmpInward

	---- Fetch Out ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [OutWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Outward_Value]	
	Into #tmpOutward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.VoucherID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.VoucherID
	Where (VH.VoucherTypeName LIKE ''Sales'')
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	

	--Select * from  #tmpOutward


	select  S.StockItemName as [StockItemName], Sum(IsNull(Op.OpeningStock_QTY,0)) as [OpeningStock_QTY], Sum(IsNull(op.OpeningStock_Value,0)) as [OpeningStock_Value],
	Sum(IsNull(I.InWard_QTY,0)) as [InWard_QTY],  Sum(IsNull(I.Inward_Value,0)) as [Inward_Value], Sum(IsNull(O.OutWard_QTY,0)) as [OutWard_QTY], Sum(IsNull(O.Outward_Value,0)) as [Outward_Value],
	((Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0))) - Sum(IsNull(O.OutWard_QTY,0))) as [Closing_QTY]
	, ((Sum(IsNull(Op.OpeningStock_Value,0)) + Sum(IsNull(I.Inward_Value,0))) - Sum(IsNull(O.Outward_Value,0))) as [Closing_Value]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #tmpInward as I ON I.StockItemName=S.StockItemName
	Left Outer Join #tmpOutward as O ON O.StockItemName=S.StockItemName
	Where  S.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@GodwnName_List  <> '''' AND OP.GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND OP.GodownName = OP.GodownName))
	Group by S.StockItemName
	Order by S.StockItemName', N'IF OBJECT_ID(''tempdb..#Purchase'') IS NOT NULL DROP TABLE #Purchase
IF OBJECT_ID(''tempdb..#tmpGodwnName'') IS NOT NULL DROP TABLE #tmpGodwnName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#tmpInward'') IS NOT NULL DROP TABLE #tmpInward
IF OBJECT_ID(''tempdb..#tmpOutward'') IS NOT NULL DROP TABLE #tmpOutward

Declare @CompanyID as uniqueidentifier
Select @CompanyID= ID From TD_Mst_Company  Where CompanyName=@CompanyNames

SELECT NAME AS ''GodwnName'' INTO #tmpGodwnName from	 dbo.GetTableFromString(isnull(@GodwnName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

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

	Declare @ShowStockDate as Datetime

	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select GodownName, StockItemName,  Sum(ActualQty) as [OpeningStock_QTY], Sum(Amount) as [OpeningStock_Value] 
	Into #tmpOPBalance
	From TD_Stock as s
	Where CompanyID=@CompanyID And   CAST(s.StockDate AS DATE) >= @DateFrom  And CAST(s.StockDate AS DATE) <= @DateTo
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by StockItemName, GodownName

	---- Fetch In ward Stock -----
	SELECT VH.DestinationGodown as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [InWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Inward_Value]	
	Into #tmpInward
	FROM TD_Mst_VoucherType as VT 
	INNER JOIN TD_Txn_VchHdr as VH On VT.CompanyID=VH.CompanyId And VT.VoucherTypeName=VH.VoucherTypeName
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=VH.CompanyId AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=VH.CompanyId AND IL.VoucherID =BL.VoucherId
	Left Outer Join TD_Mst_StockMultiGroup as MG ON IL.StockItemName=MG.Name
	Where VT.CompanyID=@CompanyID 
	And CAST(VH.Date AS DATE) >= @DateFrom  And CAST(VH.Date AS DATE) <= @DateTo
	And VT.VoucherTypeParent like ''stock%'' and (BL.GodownName like ''%approve%'' or  BL.GodownName like ''%approve%'') and L1 like ''packing%'' and IL.IsDeemedPositive=''1''
	And  Vh.DestinationGodown=''Approved Store'' -- In Ward		
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND VH.DestinationGodown IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND VH.DestinationGodown = VH.DestinationGodown))
	Group by VH.DestinationGodown, IL.StockItemName, IL.ActualUOM	

	---- Fetch Out ward Stock -----
	SELECT VH.DestinationGodown as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [OutWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Outward_Value]
	Into #tmpOutward
	FROM TD_Mst_VoucherType as VT 
	INNER JOIN TD_Txn_VchHdr as VH On VT.CompanyID=VH.CompanyId And VT.VoucherTypeName=VH.VoucherTypeName
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=VH.CompanyId AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=VH.CompanyId AND IL.VoucherID =BL.VoucherId
	Left Outer Join TD_Mst_StockMultiGroup as MG ON IL.StockItemName=MG.Name
	Where VT.CompanyID=@CompanyID 
	And CAST(VH.Date AS DATE) >= @DateFrom  And CAST(VH.Date AS DATE) <= @DateTo
	And VT.VoucherTypeParent like ''stock%'' and (BL.GodownName like ''%approve%'' or  BL.GodownName like ''%approve%'') and L1 like ''packing%'' and IL.IsDeemedPositive=''1''
	And BL.GodownName=''Approved Store''-- Out Ward		
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND VH.DestinationGodown IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND VH.DestinationGodown = VH.DestinationGodown))
	Group by VH.DestinationGodown, IL.StockItemName, IL.ActualUOM	

	select  S.StockItemName as [StockItemName], Sum(IsNull(Op.OpeningStock_QTY,0)) as [OpeningStock_QTY], Sum(IsNull(op.OpeningStock_Value,0)) as [OpeningStock_Value],
	Sum(IsNull(I.InWard_QTY,0)) as [InWard_QTY],  Sum(IsNull(I.Inward_Value,0)) as [Inward_Value], Sum(IsNull(O.OutWard_QTY,0)) as [OutWard_QTY], Sum(IsNull(O.Outward_Value,0)) as [Outward_Value],
	((Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0))) - Sum(IsNull(O.OutWard_QTY,0))) as [Closing_QTY]
	, ((Sum(IsNull(Op.OpeningStock_Value,0)) + Sum(IsNull(I.Inward_Value,0))) - Sum(IsNull(O.Outward_Value,0))) as [Closing_Value]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #tmpInward as I ON I.StockItemName=S.StockItemName
	Left Outer Join #tmpOutward as O ON O.StockItemName=S.StockItemName
	Where  S.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@GodwnName_List  <> '''' AND OP.GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND OP.GodownName = OP.GodownName))
	Group by S.StockItemName
	Order by S.StockItemName', N'--- Godown Stock Summary Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodwnName_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2021''
SET @DateTo = ''06/18/2021''
SET @GodwnName_List = ''''
SET @StockItemName_List=''100 ML BRUTE PET BOTTLE''

IF OBJECT_ID(''tempdb..#Purchase'') IS NOT NULL DROP TABLE #Purchase
IF OBJECT_ID(''tempdb..#tmpGodwnName'') IS NOT NULL DROP TABLE #tmpGodwnName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#tmpInward'') IS NOT NULL DROP TABLE #tmpInward
IF OBJECT_ID(''tempdb..#tmpOutward'') IS NOT NULL DROP TABLE #tmpOutward

Declare @CompanyID as uniqueidentifier
Select @CompanyID= ID From TD_Mst_Company  Where CompanyName=@CompanyNames

SELECT NAME AS ''GodwnName'' INTO #tmpGodwnName from	 dbo.GetTableFromString(isnull(@GodwnName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

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

	Declare @ShowStockDate as Datetime

	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select GodownName, StockItemName,  Sum(ActualQty) as [OpeningStock_QTY], Sum(Amount) as [OpeningStock_Value] 
	Into #tmpOPBalance
	From TD_Stock as s
	Where CompanyID=@CompanyID And   CAST(s.StockDate AS DATE) >= @DateFrom  And CAST(s.StockDate AS DATE) <= @DateTo
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by StockItemName, GodownName

	---- Fetch In ward Stock -----
	SELECT VH.DestinationGodown as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [InWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Inward_Value]	
	Into #tmpInward
	FROM TD_Mst_VoucherType as VT 
	INNER JOIN TD_Txn_VchHdr as VH On VT.CompanyID=VH.CompanyId And VT.VoucherTypeName=VH.VoucherTypeName
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=VH.CompanyId AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=VH.CompanyId AND IL.VoucherID =BL.VoucherId
	Left Outer Join TD_Mst_StockMultiGroup as MG ON IL.StockItemName=MG.Name
	Where VT.CompanyID=@CompanyID 
	And CAST(VH.Date AS DATE) >= @DateFrom  And CAST(VH.Date AS DATE) <= @DateTo
	And VT.VoucherTypeParent like ''stock%'' and (BL.GodownName like ''%approve%'' or  BL.GodownName like ''%approve%'') and L1 like ''packing%'' and IL.IsDeemedPositive=''1''
	And  Vh.DestinationGodown=''Approved Store'' -- In Ward		
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND VH.DestinationGodown IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND VH.DestinationGodown = VH.DestinationGodown))
	Group by VH.DestinationGodown, IL.StockItemName, IL.ActualUOM	

	---- Fetch Out ward Stock -----
	SELECT VH.DestinationGodown as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [OutWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Outward_Value]
	Into #tmpOutward
	FROM TD_Mst_VoucherType as VT 
	INNER JOIN TD_Txn_VchHdr as VH On VT.CompanyID=VH.CompanyId And VT.VoucherTypeName=VH.VoucherTypeName
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=VH.CompanyId AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=VH.CompanyId AND IL.VoucherID =BL.VoucherId
	Left Outer Join TD_Mst_StockMultiGroup as MG ON IL.StockItemName=MG.Name
	Where VT.CompanyID=@CompanyID 
	And CAST(VH.Date AS DATE) >= @DateFrom  And CAST(VH.Date AS DATE) <= @DateTo
	And VT.VoucherTypeParent like ''stock%'' and (BL.GodownName like ''%approve%'' or  BL.GodownName like ''%approve%'') and L1 like ''packing%'' and IL.IsDeemedPositive=''1''
	And BL.GodownName=''Approved Store''-- Out Ward		
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND VH.DestinationGodown IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND VH.DestinationGodown = VH.DestinationGodown))
	Group by VH.DestinationGodown, IL.StockItemName, IL.ActualUOM	

	select  S.StockItemName as [StockItemName], Sum(IsNull(Op.OpeningStock_QTY,0)) as [OpeningStock_QTY], Sum(IsNull(op.OpeningStock_Value,0)) as [OpeningStock_Value],
	Sum(IsNull(I.InWard_QTY,0)) as [InWard_QTY],  Sum(IsNull(I.Inward_Value,0)) as [Inward_Value], Sum(IsNull(O.OutWard_QTY,0)) as [OutWard_QTY], Sum(IsNull(O.Outward_Value,0)) as [Outward_Value],
	((Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0))) - Sum(IsNull(O.OutWard_QTY,0))) as [Closing_QTY]
	, ((Sum(IsNull(Op.OpeningStock_Value,0)) + Sum(IsNull(I.Inward_Value,0))) - Sum(IsNull(O.Outward_Value,0))) as [Closing_Value]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #tmpInward as I ON I.StockItemName=S.StockItemName
	Left Outer Join #tmpOutward as O ON O.StockItemName=S.StockItemName
	Where  S.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@GodwnName_List  <> '''' AND OP.GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND OP.GodownName = OP.GodownName))
	Group by S.StockItemName
	Order by S.StockItemName', NULL, 1, N'In/Out Ward Value Issue')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (5, 1, 1, N'Stock', 1, N'FinalProductStock', N'Final Product Stock', N'~/OnlineReport/FinalProductStock.aspx', N'

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID

IF OBJECT_ID(''tempdb..#tmpGodownName'') IS NOT NULL DROP TABLE #tmpGodownName
IF OBJECT_ID(''tempdb..#tmpStockGroup'') IS NOT NULL DROP TABLE #tmpStockGroup
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''GodownName'' INTO #tmpGodownName from dbo.GetTableFromString(isnull(@GodownName_List,''''))
SELECT NAME AS ''StockGroup'' INTO #tmpStockGroup from	 dbo.GetTableFromString(isnull(@StockGroup_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from	 dbo.GetTableFromString(isnull(@StockItemName_List,''''))



 SELECT c.CompanyName AS[CompanyID], sd.StockDate, sd.StockItemName, sd.GodownName, sd.BatchName, sd.Quantity, sd.UOM, sd.Rate, sd.Amount * -1 AS amount, SI.StockGroup 
 FROM  dbo.TD_Txn_StockDetails AS sd 
 INNER JOIN dbo.TD_Mst_StockItem AS SI ON sd.CompanyID = SI.CompanyID AND sd.StockItemName = SI.StockItemName 
 Inner Join TD_Mst_Company as C On c.CompanyID = Sd.CompanyID 
 where  sd.StockDate >= @DateFrom AND sd.StockDate <= @DateTo
	And (@CompanyNames  <> '''' AND SD.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND SD.CompanyID = SD.CompanyID))
	And (@GodownName_List  <> '''' AND SD.GodownName IN (SELECT GodownName FROM #tmpGodownName)  OR (@GodownName_List = ''''  AND SD.GodownName =SD.GodownName ))
	And (@StockGroup_List  <> '''' AND SI.StockGroup IN (SELECT StockGroup FROM #tmpStockGroup)  OR (@StockGroup_List = ''''  AND SI.StockGroup =SI.StockGroup ))
 	And (@StockItemName_List  <> '''' AND SI.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SI.StockItemName =SI.StockItemName ))
  Order by StockDate, GodownName, StockGroup,StockItemName 

', N'----- FinalProductStock----
--DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodownName_List as Varchar(250)='''', @StockGroup_List as Varchar(250)='''',
--		@StockItemName_List as Varchar(250)=''''

--Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
--SET @DateFrom =''01/01/2020''
--SET @DateTo = ''10/30/2020''
--SET @GodownName_List = ''''
--SET @StockGroup_List=''''
--SET @StockItemName_List=''''


IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID

IF OBJECT_ID(''tempdb..#tmpGodownName'') IS NOT NULL DROP TABLE #tmpGodownName
IF OBJECT_ID(''tempdb..#tmpStockGroup'') IS NOT NULL DROP TABLE #tmpStockGroup
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''GodownName'' INTO #tmpGodownName from dbo.GetTableFromString(isnull(@GodownName_List,''''))
SELECT NAME AS ''StockGroup'' INTO #tmpStockGroup from	 dbo.GetTableFromString(isnull(@StockGroup_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from	 dbo.GetTableFromString(isnull(@StockItemName_List,''''))



 SELECT c.CompanyName AS[CompanyID], sd.StockDate, sd.StockItemName, sd.GodownName, sd.BatchName, sd.Quantity, sd.UOM, sd.Rate, sd.Amount * -1 AS amount, SI.StockGroup 
 FROM  dbo.TD_Txn_StockDetails AS sd 
 INNER JOIN dbo.TD_Mst_StockItem AS SI ON sd.CompanyID = SI.CompanyID AND sd.StockItemName = SI.StockItemName 
 Inner Join TD_Mst_Company as C On c.CompanyID = Sd.CompanyID 
 where  sd.StockDate >= @DateFrom AND sd.StockDate <= @DateTo
	And (@CompanyNames  <> '''' AND SD.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND SD.CompanyID = SD.CompanyID))
	And (@GodownName_List  <> '''' AND SD.GodownName IN (SELECT GodownName FROM #tmpGodownName)  OR (@GodownName_List = ''''  AND SD.GodownName =SD.GodownName ))
	And (@StockGroup_List  <> '''' AND SI.StockGroup IN (SELECT StockGroup FROM #tmpStockGroup)  OR (@StockGroup_List = ''''  AND SI.StockGroup =SI.StockGroup ))
 	And (@StockItemName_List  <> '''' AND SI.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SI.StockItemName =SI.StockItemName ))
  Order by StockDate, GodownName, StockGroup,StockItemName 

', N'IF OBJECT_ID(''tempdb..#tmpGodownName'') IS NOT NULL DROP TABLE #tmpGodownName
IF OBJECT_ID(''tempdb..#tmpStockGroup'') IS NOT NULL DROP TABLE #tmpStockGroup
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''GodownName'' INTO #tmpGodownName from dbo.GetTableFromString(isnull(@GodownName_List,''''))
SELECT NAME AS ''StockGroup'' INTO #tmpStockGroup from	 dbo.GetTableFromString(isnull(@StockGroup_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from	 dbo.GetTableFromString(isnull(@StockItemName_List,''''))

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

	SELECT c.CompanyName AS[CompanyID], sd.StockDate as [StockDate], sd.StockItemName as [StockItemName], sd.GodownName as [GodownName], sd.BatchName as [BatchName],
	sd.ActualQty as [Quantity], sd.ActualUom as [UOM],  sd.Amount * -1 AS [Amount], SI.StockGroup as [StockGroup]
	FROM  TD_Mst_Company as C
	INNER JOIN dbo.TD_Mst_StockItem AS SI ON SI.CompanyID = C.Id  
	Inner Join TD_Stock AS sd On sd.CompanyId=c.Id And sd.StockItemName = SI.StockItemName 
	--Inner Join TD_Mst_Company as C On c.ID = Sd.CompanyID 
	where  C.id= @CompanyID And   CAST(sd.StockDate AS DATE) >= @DateFrom  And CAST(sd.StockDate AS DATE) <= @DateTo
	And (@GodownName_List  <> '''' AND SD.GodownName IN (SELECT GodownName FROM #tmpGodownName)  OR (@GodownName_List = ''''  AND SD.GodownName =SD.GodownName ))
	And (@StockGroup_List  <> '''' AND SI.StockGroup IN (SELECT StockGroup FROM #tmpStockGroup)  OR (@StockGroup_List = ''''  AND SI.StockGroup =SI.StockGroup ))
	And (@StockItemName_List  <> '''' AND SI.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SI.StockItemName =SI.StockItemName ))
	Order by StockDate, GodownName, StockGroup,StockItemName ', N'--- Final Product Stock----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodownName_List as Varchar(250)='''', @StockGroup_List as Varchar(250)='''',
		@StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/31/2021''
SET @DateTo = ''01/31/2021''
SET @GodownName_List = ''''
SET @StockGroup_List=''''
SET @StockItemName_List=''''

IF OBJECT_ID(''tempdb..#tmpGodownName'') IS NOT NULL DROP TABLE #tmpGodownName
IF OBJECT_ID(''tempdb..#tmpStockGroup'') IS NOT NULL DROP TABLE #tmpStockGroup
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''GodownName'' INTO #tmpGodownName from dbo.GetTableFromString(isnull(@GodownName_List,''''))
SELECT NAME AS ''StockGroup'' INTO #tmpStockGroup from	 dbo.GetTableFromString(isnull(@StockGroup_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from	 dbo.GetTableFromString(isnull(@StockItemName_List,''''))

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

	SELECT c.CompanyName AS[CompanyID], sd.StockDate as [StockDate], sd.StockItemName as [StockItemName], sd.GodownName as [GodownName], sd.BatchName as [BatchName],
	sd.ActualQty as [Quantity], sd.ActualUom as [UOM],  sd.Amount * -1 AS [Amount], SI.StockGroup as [StockGroup]
	FROM  TD_Mst_Company as C
	INNER JOIN dbo.TD_Mst_StockItem AS SI ON SI.CompanyID = C.Id  
	Inner Join TD_Stock AS sd On sd.CompanyId=c.Id And sd.StockItemName = SI.StockItemName 
	--Inner Join TD_Mst_Company as C On c.ID = Sd.CompanyID 
	where  C.id= @CompanyID And   CAST(sd.StockDate AS DATE) >= @DateFrom  And CAST(sd.StockDate AS DATE) <= @DateTo
	And (@GodownName_List  <> '''' AND SD.GodownName IN (SELECT GodownName FROM #tmpGodownName)  OR (@GodownName_List = ''''  AND SD.GodownName =SD.GodownName ))
	And (@StockGroup_List  <> '''' AND SI.StockGroup IN (SELECT StockGroup FROM #tmpStockGroup)  OR (@StockGroup_List = ''''  AND SI.StockGroup =SI.StockGroup ))
	And (@StockItemName_List  <> '''' AND SI.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SI.StockItemName =SI.StockItemName ))
	Order by StockDate, GodownName, StockGroup,StockItemName ', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (6, 1, 1, N'Stock', 2, N'LeadTimeReport', N'Lead Time Report', N'~/OnlineReport/LeadTimeReport.aspx', N'

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

select * from View_Report_LeadTime as LT
where  (@CompanyNames  <> '''' AND LT.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND LT.CompanyID = LT.CompanyID))
	And (@PartyName_List  <> '''' AND LT.popartyname IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND LT.popartyname =LT.popartyname))
	And (@StockItemName_List  <> '''' AND LT.POStockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND LT.POStockItemName =LT.POStockItemName ))
	And LT.PODate >= @PO_DateFrom AND LT.PODate <= @PO_DateTo
	And LT.GRNDate >= @GRN_DateFrom AND LT.GRNDate <= @GRN_DateTo
	And LT.InvoiceDate >= @Invoice_DateFrom AND LT.InvoiceDate <= @GRN_DateTo
Order by podate, popartyname, POStockItemName
', N'------- Lead Time Report----
--DECLARE @CompanyNames as Varchar(2000)='''', @PO_DateFrom datetime= Null,  @PO_DateTo datetime=Null,   @GRN_DateFrom datetime= Null,  @GRN_DateTo datetime=Null, 
--		@Invoice_DateFrom datetime= Null,  @Invoice_DateTo datetime=Null, @PartyName_List as Varchar(250)='''',  @StockItemName_List as Varchar(250)=''''

--Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
--SET @PO_DateFrom =''01/01/2020''
--SET @PO_DateTo = ''10/30/2020''
--SET @GRN_DateFrom =''01/01/2020''
--SET @GRN_DateTo = ''10/30/2020''
--SET @Invoice_DateFrom =''01/01/2020''
--SET @Invoice_DateTo = ''10/30/2020''
--SET @PartyName_List = ''''
--SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

select * from View_Report_LeadTime as LT
where  (@CompanyNames  <> '''' AND LT.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND LT.CompanyID = LT.CompanyID))
	And (@PartyName_List  <> '''' AND LT.popartyname IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND LT.popartyname =LT.popartyname))
	And (@StockItemName_List  <> '''' AND LT.POStockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND LT.POStockItemName =LT.POStockItemName ))
	And LT.PODate >= @PO_DateFrom AND LT.PODate <= @PO_DateTo
	And LT.GRNDate >= @GRN_DateFrom AND LT.GRNDate <= @GRN_DateTo
	And LT.InvoiceDate >= @Invoice_DateFrom AND LT.InvoiceDate <= @GRN_DateTo
Order by podate, popartyname, POStockItemName
', N'IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#View_Report_LeadTime'') IS NOT NULL DROP TABLE #View_Report_LeadTime


Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))


SELECT PO.Date AS podate, UPPER(PO.PartyName) AS popartyname, PO.Reference AS PORefNo, PO.StockItemName AS POStockItemName, PO.ActualQuantity AS POQTY, PO.Rate AS PORate, PO.RateUOM AS POUOM, 
	PO.Amount * - 1 AS POAmount, DATEDIFF(day, PO.Date, GRN.Date) AS LeadTime, GRN.Date AS grndate, UPPER(GRN.PartyName) AS GRNPartyName, GRN.Reference AS GRNReference, UPPER(GRN.StockItemName) 
	AS GRNStockItemName, GRN.ActualQuantity AS GRNQTY, GRN.Rate AS GRNRate, GRN.RateUOM AS GRNUOM, GRN.Amount * - 1 AS GRNAmount, PURCHASE.Date AS InvoiceDate, UPPER(PURCHASE.PartyName) AS InvoicePartyName, 
	UPPER(PURCHASE.Reference) AS InvoiceReference, UPPER(PURCHASE.StockItemName) AS PURCHASEStockItemName, PURCHASE.ActualQuantity AS InvoiceQTY, PURCHASE.Rate AS InvoiceRate, 
	PURCHASE.RateUOM AS InvoiceUOM, PURCHASE.Amount * - 1 AS InvoiceAmount, PO.CompanyID
Into #View_Report_LeadTime
FROM     
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyLedgerName as [PartyName], IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM
		FROM  TD_Txn_VchHdr as  VH 
		INNER JOIN  TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.Id = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
		WHERE   (VH.CompanyID = @CompanyID)  
		AND ((VH.VoucherTypeName LIKE ''Purchase Order for Factory'') OR (VH.VoucherTypeName LIKE ''Purchase Order for Central Hub''))									
	) AS PO LEFT OUTER JOIN
        (
		SELECT VH2.CompanyID, VH2.Date, VH2.VoucherTypeName, VH2.VoucherNo, VH2.Reference, VH2.PartyLedgerName as [PartyName], IL2.Rate, 
		IL2.StockItemName, IL2.RateUOM, IL2.Amount, IL2.ActualQuantity, IL2.ActualUOM, VH2.OrderNo, VH2.OrderDate
		FROM      dbo.TD_Txn_VchHdr AS VH2 INNER JOIN
		dbo.TD_Txn_InvLine AS IL2 ON VH2.CompanyID = IL2.CompanyId AND VH2.Id = IL2.VoucherID INNER JOIN
		dbo.TD_Txn_AccLine AS AL2 ON VH2.CompanyID = AL2.CompanyID AND IL2.AccLineId = AL2.Id AND 
		IL2.VoucherID = AL2.VoucherID AND VH2.Id = AL2.VoucherID
		WHERE   (VH2.CompanyID = @CompanyID) AND (VH2.VoucherTypeName LIKE ''GRN%'')
		) AS GRN ON PO.Reference = GRN.OrderNo AND PO.StockItemName = GRN.StockItemName LEFT OUTER JOIN
			(
			SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyLedgerName as [PartyName], IL.Rate, 
			IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
			FROM   dbo.TD_Txn_VchHdr AS VH 
			INNER JOIN dbo.TD_Txn_InvLine AS IL ON VH.CompanyID = IL.CompanyId AND VH.Id = IL.VoucherID 
			INNER JOIN dbo.TD_Txn_AccLine AS AL ON VH.CompanyID = AL.CompanyID AND AL.Id=IL.AccLineId AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
			WHERE   (VH.CompanyID = @CompanyID) AND (VH.VoucherTypeName LIKE ''PURCHASE FOR%'')					   
			) AS PURCHASE ON GRN.OrderNo = PURCHASE.OrderNo AND GRN.StockItemName = PURCHASE.StockItemName AND 
		GRN.ActualQuantity = PURCHASE.ActualQuantity


select * from #View_Report_LeadTime as LT
where  (@PartyName_List  <> '''' AND LT.popartyname IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND LT.popartyname =LT.popartyname))
	And (@StockItemName_List  <> '''' AND LT.POStockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND LT.POStockItemName =LT.POStockItemName ))
	And LT.PODate >= @PO_DateFrom AND LT.PODate <= @PO_DateTo
	And LT.GRNDate >= @GRN_DateFrom AND LT.GRNDate <= @GRN_DateTo
	And LT.InvoiceDate >= @Invoice_DateFrom AND LT.InvoiceDate <= @GRN_DateTo
Order by podate, popartyname, POStockItemName
', N'----- Lead Time Report----
DECLARE @CompanyNames as Varchar(2000)='''', @PO_DateFrom datetime= Null,  @PO_DateTo datetime=Null,   @GRN_DateFrom datetime= Null,  @GRN_DateTo datetime=Null, 
		@Invoice_DateFrom datetime= Null,  @Invoice_DateTo datetime=Null, @PartyName_List as Varchar(250)='''',  @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @PO_DateFrom =''01/01/2020''
SET @PO_DateTo = ''10/30/2020''
SET @GRN_DateFrom =''01/01/2020''
SET @GRN_DateTo = ''10/30/2020''
SET @Invoice_DateFrom =''01/01/2020''
SET @Invoice_DateTo = ''10/30/2020''
SET @PartyName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#View_Report_LeadTime'') IS NOT NULL DROP TABLE #View_Report_LeadTime


Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))


SELECT PO.Date AS podate, UPPER(PO.PartyName) AS popartyname, PO.Reference AS PORefNo, PO.StockItemName AS POStockItemName, PO.ActualQuantity AS POQTY, PO.Rate AS PORate, PO.RateUOM AS POUOM, 
	PO.Amount * - 1 AS POAmount, DATEDIFF(day, PO.Date, GRN.Date) AS LeadTime, GRN.Date AS grndate, UPPER(GRN.PartyName) AS GRNPartyName, GRN.Reference AS GRNReference, UPPER(GRN.StockItemName) 
	AS GRNStockItemName, GRN.ActualQuantity AS GRNQTY, GRN.Rate AS GRNRate, GRN.RateUOM AS GRNUOM, GRN.Amount * - 1 AS GRNAmount, PURCHASE.Date AS InvoiceDate, UPPER(PURCHASE.PartyName) AS InvoicePartyName, 
	UPPER(PURCHASE.Reference) AS InvoiceReference, UPPER(PURCHASE.StockItemName) AS PURCHASEStockItemName, PURCHASE.ActualQuantity AS InvoiceQTY, PURCHASE.Rate AS InvoiceRate, 
	PURCHASE.RateUOM AS InvoiceUOM, PURCHASE.Amount * - 1 AS InvoiceAmount, PO.CompanyID
Into #View_Report_LeadTime
FROM     
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyLedgerName as [PartyName], IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM
		FROM  TD_Txn_VchHdr as  VH 
		INNER JOIN  TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.Id = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
		WHERE   (VH.CompanyID = @CompanyID)  
		AND ((VH.VoucherTypeName LIKE ''Purchase Order for Factory'') OR (VH.VoucherTypeName LIKE ''Purchase Order for Central Hub''))									
	) AS PO LEFT OUTER JOIN
        (
		SELECT VH2.CompanyID, VH2.Date, VH2.VoucherTypeName, VH2.VoucherNo, VH2.Reference, VH2.PartyLedgerName as [PartyName], IL2.Rate, 
		IL2.StockItemName, IL2.RateUOM, IL2.Amount, IL2.ActualQuantity, IL2.ActualUOM, VH2.OrderNo, VH2.OrderDate
		FROM      dbo.TD_Txn_VchHdr AS VH2 INNER JOIN
		dbo.TD_Txn_InvLine AS IL2 ON VH2.CompanyID = IL2.CompanyId AND VH2.Id = IL2.VoucherID INNER JOIN
		dbo.TD_Txn_AccLine AS AL2 ON VH2.CompanyID = AL2.CompanyID AND IL2.AccLineId = AL2.Id AND 
		IL2.VoucherID = AL2.VoucherID AND VH2.Id = AL2.VoucherID
		WHERE   (VH2.CompanyID = @CompanyID) AND (VH2.VoucherTypeName LIKE ''GRN%'')
		) AS GRN ON PO.Reference = GRN.OrderNo AND PO.StockItemName = GRN.StockItemName LEFT OUTER JOIN
			(
			SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyLedgerName as [PartyName], IL.Rate, 
			IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
			FROM   dbo.TD_Txn_VchHdr AS VH 
			INNER JOIN dbo.TD_Txn_InvLine AS IL ON VH.CompanyID = IL.CompanyId AND VH.Id = IL.VoucherID 
			INNER JOIN dbo.TD_Txn_AccLine AS AL ON VH.CompanyID = AL.CompanyID AND AL.Id=IL.AccLineId AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
			WHERE   (VH.CompanyID = @CompanyID) AND (VH.VoucherTypeName LIKE ''PURCHASE FOR%'')					   
			) AS PURCHASE ON GRN.OrderNo = PURCHASE.OrderNo AND GRN.StockItemName = PURCHASE.StockItemName AND 
		GRN.ActualQuantity = PURCHASE.ActualQuantity


select * from #View_Report_LeadTime as LT
where  (@PartyName_List  <> '''' AND LT.popartyname IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND LT.popartyname =LT.popartyname))
	And (@StockItemName_List  <> '''' AND LT.POStockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND LT.POStockItemName =LT.POStockItemName ))
	And LT.PODate >= @PO_DateFrom AND LT.PODate <= @PO_DateTo
	And LT.GRNDate >= @GRN_DateFrom AND LT.GRNDate <= @GRN_DateTo
	And LT.InvoiceDate >= @Invoice_DateFrom AND LT.InvoiceDate <= @GRN_DateTo
Order by podate, popartyname, POStockItemName
', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (7, 1, 1, N'Purchase', 2, N'PendingPurchaseBill', N'Pending Purchase Bill', N'~/OnlineReport/PendingPurchaseBill.aspx', N'IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tempPendingPurchaseBills'') IS NOT NULL DROP TABLE #tempPendingPurchaseBills

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT GRN.Date AS [TransDate], GRN.Reference AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], GRN.StockGroup  as [StockGroup],
	   GRN.ActualQuantity AS [GRNQTY], GRN.Rate AS [GRNRate], IsNull(PURCHASE.ActualQuantity, 0) as [BillQTY], IsNull(PURCHASE.Rate, 0) as [BillRate]
INTO #tempPendingPurchaseBills
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyLedgerName as [PartyName], vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM,  IL.ActualUOM	, IL.ActualQuantity,
		IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE  (VH.VoucherTypeName LIKE ''GRN%'') And VH.CompanyId=@CompanyID
		And VH.Date >= @DateFrom AND VH.Date <= @DateTo

	) AS GRN  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyLedgerName as [PartyName], IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE ''PURCHASE FOR%'') And VH.CompanyId=@CompanyID	
	) AS PURCHASE 
		ON GRN.OrderNo = PURCHASE.OrderNo AND GRN.StockItemName = PURCHASE.StockItemName AND GRN.ActualQuantity = PURCHASE.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, (B.GRNQTY - B.BillQTY) as [QTY], B.GRNRate as [Rate], (B.GRNQTY - B.BillQTY) * B.GRNRate As [Amount]
from #tempPendingPurchaseBills as B
Where (@PartyName_List  <> '''' AND B.VendorName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND B.VendorName = B.VendorName ))
And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '''' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND B.StockItemName = B.StockItemName))
And B.GRNQTY > B.BillQTY
Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc', N'----- Pending Purchase Bill----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @PartyName_List as Varchar(250)='''', @StockGroupName_List as Varchar(250)='''', 
		@StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''01/31/2021''
SET @PartyName_List = '''' 
SET @StockGroupName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tempPendingPurchaseBills'') IS NOT NULL DROP TABLE #tempPendingPurchaseBills
IF OBJECT_ID(''tempdb..#grouptempPendingPurchaseBills'') IS NOT NULL DROP TABLE #grouptempPendingPurchaseBills

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT GRN.Date AS [TransDate], GRN.TrackingNumber AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], GRN.StockGroup  as [StockGroup],
	   GRN.ActualQuantity AS [GRNQTY], GRN.Rate AS [GRNRate], IsNull(PURCHASE.ActualQuantity, 0) as [BillQTY], PURCHASE.StockItemName as PS1, IsNull(PURCHASE.Rate, 0) as [BillRate]
INTO #tempPendingPurchaseBills
FROM    
	(
		SELECT  VH.Date, VH.VoucherTypeName, BL.TrackingNumber,  VH.PartyLedgerName as [PartyName],  IL.StockItemName, SI.StockGroup,
		IL.RateUOM,  IL.ActualUOM, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount], BL.TrackingNumber as [GRNTrackingNo]					
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE (VT.VoucherType =''Receipt Note'') And VH.CompanyId=@CompanyID 	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
		And (@PartyName_List  <> '''' AND VH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND VH.PartyLedgerName = VH.PartyLedgerName ))
		And   (@StockGroupName_List  <> '''' AND SI.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND SI.StockGroup = SI.StockGroup))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))

	) AS GRN  
	LEFT OUTER JOIN	
	(
		SELECT  VH.Date, VH.VoucherTypeName, BL.TrackingNumber, VH.PartyLedgerName as [PartyName], IL.Rate, IL.StockItemName, IL.RateUOM,
		 IL.ActualUOM, BL.TrackingNumber as [BillTrackingNo], IsNull(IL.ActualQuantity, 0) as [ActualQuantity], Isnull(IL.Amount,0) as Amount		
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		WHERE  (VT.VoucherType =''PURCHASE'') And IL.ActualQuantity>0
		And (@PartyName_List  <> '''' AND VH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND VH.PartyLedgerName = VH.PartyLedgerName ))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS PURCHASE 
	ON GRN.GRNTrackingNo = PURCHASE.BillTrackingNo AND GRN.StockItemName = PURCHASE.StockItemName AND GRN.ActualQuantity = PURCHASE.ActualQuantity 

	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.GRNQTY as [GRNQTYTotal], Sum(B.BillQTY) as [BillQTYTotal],
	B.GRNRate as [Rate]
	INTO #grouptempPendingPurchaseBills
	from #tempPendingPurchaseBills as B
	Where  B.GRNQTY > B.BillQTY
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Group by B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.GRNRate, B.GRNQTY
	Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc

	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, (B.GRNQTYTotal - B.BillQTYTotal) as [QTY], B.Rate as [Rate],
	(B.GRNQTYTotal - B.BillQTYTotal) * B.Rate As [Amount]	
	from #grouptempPendingPurchaseBills as B
	Where  B.GRNQTYTotal > B.BillQTYTotal And (B.GRNQTYTotal - B.BillQTYTotal)>0
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc', N'IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tempPendingPurchaseBills'') IS NOT NULL DROP TABLE #tempPendingPurchaseBills
IF OBJECT_ID(''tempdb..#grouptempPendingPurchaseBills'') IS NOT NULL DROP TABLE #grouptempPendingPurchaseBills

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT GRN.Date AS [TransDate], GRN.TrackingNumber AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], GRN.StockGroup  as [StockGroup],
	   GRN.ActualQuantity AS [GRNQTY], GRN.Rate AS [GRNRate], IsNull(PURCHASE.ActualQuantity, 0) as [BillQTY], PURCHASE.StockItemName as PS1, IsNull(PURCHASE.Rate, 0) as [BillRate]
INTO #tempPendingPurchaseBills
FROM    
	(
		SELECT  VH.Date, VH.VoucherTypeName, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(BL.TrackingNumber, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), ''''))) as [TrackingNumber],
		VH.PartyLedgerName as [PartyName],  IL.StockItemName, SI.StockGroup,
		IL.RateUOM,  IL.ActualUOM, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount], BL.TrackingNumber as [GRNTrackingNo]					
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE (VT.VoucherType =''Receipt Note'') And VH.CompanyId=@CompanyID 	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And (@PartyName_List  <> '''' AND VH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND VH.PartyLedgerName = VH.PartyLedgerName ))
		And   (@StockGroupName_List  <> '''' AND SI.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND SI.StockGroup = SI.StockGroup))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))

	) AS GRN  
	LEFT OUTER JOIN	
	(
		SELECT  VH.Date, VH.VoucherTypeName, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(BL.TrackingNumber, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), ''''))) as [TrackingNumber],
		 VH.PartyLedgerName as [PartyName], IL.Rate, IL.StockItemName, IL.RateUOM, 
		 IL.ActualUOM, BL.TrackingNumber as [BillTrackingNo], IsNull(IL.ActualQuantity, 0) as [ActualQuantity], Isnull(IL.Amount,0) as Amount		
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		WHERE  (VT.VoucherType =''PURCHASE'') And IL.ActualQuantity>0 
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And (@PartyName_List  <> '''' AND VH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND VH.PartyLedgerName = VH.PartyLedgerName ))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS PURCHASE 
	ON LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(GRN.GRNTrackingNo, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), '''')))=
	   LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(PURCHASE.BillTrackingNo, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), '''')))	
	 AND GRN.StockItemName = PURCHASE.StockItemName  

	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.GRNQTY as [GRNQTYTotal], Sum(B.BillQTY) as [BillQTYTotal],
	B.GRNRate as [Rate]
	INTO #grouptempPendingPurchaseBills
	from #tempPendingPurchaseBills as B
	Where  B.GRNQTY > B.BillQTY
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Group by B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.GRNRate, B.GRNQTY
	Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc

	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, (B.GRNQTYTotal - B.BillQTYTotal) as [QTY], B.Rate as [Rate],
	(B.GRNQTYTotal - B.BillQTYTotal) * B.Rate As [Amount]	
	from #grouptempPendingPurchaseBills as B
	Where  B.GRNQTYTotal > B.BillQTYTotal And (B.GRNQTYTotal - B.BillQTYTotal)>0
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Order by B.TransDate, B.VendorName, B.ChallanBillNo, B.StockGroup, B.StockItemName Desc', N'----- Pending Purchase Bill----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @PartyName_List as Varchar(250)='''', @StockGroupName_List as Varchar(250)='''', 
		@StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''01/31/2021''
SET @PartyName_List = '''' 
SET @StockGroupName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tempPendingPurchaseBills'') IS NOT NULL DROP TABLE #tempPendingPurchaseBills
IF OBJECT_ID(''tempdb..#grouptempPendingPurchaseBills'') IS NOT NULL DROP TABLE #grouptempPendingPurchaseBills

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT GRN.Date AS [TransDate], GRN.TrackingNumber AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], GRN.StockGroup  as [StockGroup],
	   GRN.ActualQuantity AS [GRNQTY], GRN.Rate AS [GRNRate], IsNull(PURCHASE.ActualQuantity, 0) as [BillQTY], PURCHASE.StockItemName as PS1, IsNull(PURCHASE.Rate, 0) as [BillRate]
INTO #tempPendingPurchaseBills
FROM    
	(
		SELECT  VH.Date, VH.VoucherTypeName, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(BL.TrackingNumber, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), ''''))) as [TrackingNumber],
		VH.PartyLedgerName as [PartyName],  IL.StockItemName, SI.StockGroup,
		IL.RateUOM,  IL.ActualUOM, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount], BL.TrackingNumber as [GRNTrackingNo]					
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE (VT.VoucherType =''Receipt Note'') And VH.CompanyId=@CompanyID 	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And (@PartyName_List  <> '''' AND VH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND VH.PartyLedgerName = VH.PartyLedgerName ))
		And   (@StockGroupName_List  <> '''' AND SI.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND SI.StockGroup = SI.StockGroup))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))

	) AS GRN  
	LEFT OUTER JOIN	
	(
		SELECT  VH.Date, VH.VoucherTypeName, LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(BL.TrackingNumber, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), ''''))) as [TrackingNumber],
		 VH.PartyLedgerName as [PartyName], IL.Rate, IL.StockItemName, IL.RateUOM, 
		 IL.ActualUOM, BL.TrackingNumber as [BillTrackingNo], IsNull(IL.ActualQuantity, 0) as [ActualQuantity], Isnull(IL.Amount,0) as Amount		
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		WHERE  (VT.VoucherType =''PURCHASE'') And IL.ActualQuantity>0 
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And (@PartyName_List  <> '''' AND VH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND VH.PartyLedgerName = VH.PartyLedgerName ))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS PURCHASE 
	ON LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(GRN.GRNTrackingNo, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), '''')))=
	   LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(PURCHASE.BillTrackingNo, CHAR(10), ''''), CHAR(13), ''''), CHAR(9), ''''), CHAR(160), '''')))	
	 AND GRN.StockItemName = PURCHASE.StockItemName  

	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.GRNQTY as [GRNQTYTotal], Sum(B.BillQTY) as [BillQTYTotal],
	B.GRNRate as [Rate]
	INTO #grouptempPendingPurchaseBills
	from #tempPendingPurchaseBills as B
	Where  B.GRNQTY > B.BillQTY
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Group by B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.GRNRate, B.GRNQTY
	Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc

	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, (B.GRNQTYTotal - B.BillQTYTotal) as [QTY], B.Rate as [Rate],
	(B.GRNQTYTotal - B.BillQTYTotal) * B.Rate As [Amount]	
	from #grouptempPendingPurchaseBills as B
	Where  B.GRNQTYTotal > B.BillQTYTotal And (B.GRNQTYTotal - B.BillQTYTotal)>0
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Order by B.TransDate, B.VendorName, B.ChallanBillNo, B.StockGroup, B.StockItemName Desc', NULL, 1, N'LIVE')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (8, 1, 1, N'Sales', 1, N'PendingSalesBill', N'Pending Sales Bill', N'~/OnlineReport/PendingSalesBill.aspx', N'IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpDepotName'') IS NOT NULL DROP TABLE #tmpDepotName
IF OBJECT_ID(''tempdb..#tmpHQName'') IS NOT NULL DROP TABLE #tmpHQName
IF OBJECT_ID(''tempdb..#PendingSalesBill'') IS NOT NULL DROP TABLE #PendingSalesBill

SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''DepotName'' INTO #tmpDepotName from dbo.GetTableFromString(isnull(@DepotName_List,''''))
SELECT NAME AS ''HQName'' INTO #tmpHQName from dbo.GetTableFromString(isnull(@HQName_List,''''))

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT SALESORDER.Date AS [TransDate], SALESORDER.Reference AS [ChallanBillNo], SALESORDER.PartyName AS [VendorName],  SALESORDER.StockItemName AS [StockItemName], SALESORDER.StockGroup  as [StockGroup],
		SALESORDER.GodownName  as [GodownName],  SALESORDER.ActualQuantity AS [SalesOrderQTY], SALESORDER.Rate AS [SalesOrderRate], IsNull(SALES.ActualQuantity, 0) as [BillQTY], IsNull(SALES.Rate, 0) as [BillRate]
INTO #PendingSalesBill
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM, VH.DestinationGodown as [GodownName],
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount], BL.TrackingNumber as [TrackingNo]						
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.id AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And Si.CompanyID=VH.CompanyID
		WHERE  (VT.VoucherType =''Sales Order'') And VH.CompanyId=@CompanyID And VH.Date >= @DateFrom AND VH.Date <= @DateTo
		And (@StockGroupName_List  <> '''' AND SI.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND SI.StockGroup = SI.StockGroup))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS SALESORDER  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, 
		IL.ActualUOM, VH.OrderNo, BL.TrackingNumber as [TrackingNo]			
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		WHERE (VT.VoucherType =''Sales'')  And VH.CompanyId=@CompanyID
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS SALES 
   ON SALESORDER.TrackingNo = SALES.TrackingNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], '''' as [HQ],
(B.SalesOrderQTY - B.BillQTY) as [QTY], B.SalesOrderRate as [Rate], (B.SalesOrderQTY - B.BillQTY) * B.SalesOrderRate As [Amount]
from #PendingSalesBill as B
Where B.SalesOrderQTY > B.BillQTY  
And (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
Order by B.TransDate Desc, B.ChallanBillNo, B.StockGroup, B.StockItemName', N'----- Pending Sales Bill----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockGroupName_List as Varchar(500)='''', @StockItemName_List as Varchar(500)='''',
		@DepotName_List as Varchar(500)='''', @HQName_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''01/30/2021''

SET @StockGroupName_List = ''''
SET @StockItemName_List = ''''
SET @DepotName_List = ''''
SET @HQName_List = ''''

IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpDepotName'') IS NOT NULL DROP TABLE #tmpDepotName
IF OBJECT_ID(''tempdb..#tmpHQName'') IS NOT NULL DROP TABLE #tmpHQName
IF OBJECT_ID(''tempdb..#PendingSalesBill'') IS NOT NULL DROP TABLE #PendingSalesBill

SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''DepotName'' INTO #tmpDepotName from dbo.GetTableFromString(isnull(@DepotName_List,''''))
SELECT NAME AS ''HQName'' INTO #tmpHQName from dbo.GetTableFromString(isnull(@HQName_List,''''))

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT SALESORDER.Date AS [TransDate], SALESORDER.Reference AS [ChallanBillNo], SALESORDER.PartyName AS [VendorName],  SALESORDER.StockItemName AS [StockItemName], SALESORDER.StockGroup  as [StockGroup],
		SALESORDER.GodownName  as [GodownName],  SALESORDER.ActualQuantity AS [SalesOrderQTY], SALESORDER.Rate AS [SalesOrderRate], IsNull(SALES.ActualQuantity, 0) as [BillQTY], IsNull(SALES.Rate, 0) as [BillRate]
INTO #PendingSalesBill
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM, VH.DestinationGodown as [GodownName],
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount], BL.TrackingNumber as [TrackingNo]						
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.id AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And Si.CompanyID=VH.CompanyID
		WHERE  (VT.VoucherType =''Sales Order'') And VH.CompanyId=@CompanyID And VH.Date >= @DateFrom AND VH.Date <= @DateTo
		And (@StockGroupName_List  <> '''' AND SI.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND SI.StockGroup = SI.StockGroup))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS SALESORDER  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, 
		IL.ActualUOM, VH.OrderNo, BL.TrackingNumber as [TrackingNo]			
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		WHERE (VT.VoucherType =''Sales'')  And VH.CompanyId=@CompanyID
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS SALES 
   ON SALESORDER.TrackingNo = SALES.TrackingNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], '''' as [HQ],
(B.SalesOrderQTY - B.BillQTY) as [QTY], B.SalesOrderRate as [Rate], (B.SalesOrderQTY - B.BillQTY) * B.SalesOrderRate As [Amount]
from #PendingSalesBill as B
Where B.SalesOrderQTY > B.BillQTY  
And (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
Order by B.TransDate Desc, B.ChallanBillNo, B.StockGroup, B.StockItemName', N'IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpDepotName'') IS NOT NULL DROP TABLE #tmpDepotName
IF OBJECT_ID(''tempdb..#tmpHQName'') IS NOT NULL DROP TABLE #tmpHQName
IF OBJECT_ID(''tempdb..#PendingSalesBill'') IS NOT NULL DROP TABLE #PendingSalesBill
IF OBJECT_ID(''tempdb..#grouptempPendingBills'') IS NOT NULL DROP TABLE #grouptempPendingBills

SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''DepotName'' INTO #tmpDepotName from dbo.GetTableFromString(isnull(@DepotName_List,''''))
SELECT NAME AS ''HQName'' INTO #tmpHQName from dbo.GetTableFromString(isnull(@HQName_List,''''))

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT SALESORDER.Date AS [TransDate], SALESORDER.Reference AS [ChallanBillNo], SALESORDER.PartyName AS [VendorName],  SALESORDER.StockItemName AS [StockItemName], SALESORDER.StockGroup  as [StockGroup],
		SALESORDER.GodownName  as [GodownName], SALESORDER.LedgerName as [LedgerName], SALESORDER.ActualQuantity AS [SalesOrderQTY], SALESORDER.Rate AS [SalesOrderRate], IsNull(SALES.ActualQuantity, 0) as [BillQTY], IsNull(SALES.Rate, 0) as [BillRate]
INTO #PendingSalesBill
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM, 
		Bl.GodownName as [GodownName], VH.PartyLedgerName as [LedgerName],
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount], BL.TrackingNumber as [TrackingNo]				
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE (VT.VoucherType =''Delivery Note'') And VH.CompanyId=@CompanyID 	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And   (@StockGroupName_List  <> '''' AND SI.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND SI.StockGroup = SI.StockGroup))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))	
	) AS SALESORDER  

	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, 
		IL.ActualUOM, VH.OrderNo, BL.TrackingNumber as [TrackingNo]			
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		WHERE  (VT.VoucherType =''Sales'') And IL.ActualQuantity>0 
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS SALES 
   ON SALESORDER.TrackingNo = SALES.TrackingNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.SalesOrderQTY as [SalesOrderQTY], Sum(B.BillQTY) as [BillQTYTotal],
	B.SalesOrderRate as [Rate], B.GodownName, B.LedgerName
	INTO #grouptempPendingBills
	from #PendingSalesBill as B
	Where  B.SalesOrderQTY > B.BillQTY
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Group by B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.SalesOrderRate, B.SalesOrderQTY, B.GodownName, B.LedgerName
	Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName, B.GodownName, B.LedgerName Desc

	Select Distinct  B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], b.LedgerName as [HQName],
	(B.SalesOrderQTY - B.BillQTYTotal) as [QTY], B.Rate as [Rate], (B.SalesOrderQTY - B.BillQTYTotal) * B.Rate As [Amount]
	from #grouptempPendingBills as B
	Where  B.SalesOrderQTY > B.BillQTYTotal And (B.SalesOrderQTY - B.BillQTYTotal)>0
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	And   (@DepotName_List  <> '''' AND B.GodownName IN (SELECT DepotName FROM #tmpDepotName)  OR (@DepotName_List = ''''  AND B.GodownName = B.GodownName))
	And   (@HQName_List  <> '''' AND B.LedgerName IN (SELECT HQName FROM #tmpHQName)  OR (@HQName_List = ''''  AND B.LedgerName = B.LedgerName))
	Order by B.TransDate,  B.StockGroup, B.StockItemName Desc', N'----- Pending Sales Bill----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockGroupName_List as Varchar(500)='''', @StockItemName_List as Varchar(500)='''',
		@DepotName_List as Varchar(500)='''', @HQName_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''01/30/2021''

SET @StockGroupName_List = ''''
SET @StockItemName_List = ''''
SET @DepotName_List = ''''
SET @HQName_List = ''''

IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpDepotName'') IS NOT NULL DROP TABLE #tmpDepotName
IF OBJECT_ID(''tempdb..#tmpHQName'') IS NOT NULL DROP TABLE #tmpHQName
IF OBJECT_ID(''tempdb..#PendingSalesBill'') IS NOT NULL DROP TABLE #PendingSalesBill
IF OBJECT_ID(''tempdb..#grouptempPendingBills'') IS NOT NULL DROP TABLE #grouptempPendingBills

SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''DepotName'' INTO #tmpDepotName from dbo.GetTableFromString(isnull(@DepotName_List,''''))
SELECT NAME AS ''HQName'' INTO #tmpHQName from dbo.GetTableFromString(isnull(@HQName_List,''''))

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT SALESORDER.Date AS [TransDate], SALESORDER.Reference AS [ChallanBillNo], SALESORDER.PartyName AS [VendorName],  SALESORDER.StockItemName AS [StockItemName], SALESORDER.StockGroup  as [StockGroup],
		SALESORDER.GodownName  as [GodownName], SALESORDER.LedgerName as [LedgerName], SALESORDER.ActualQuantity AS [SalesOrderQTY], SALESORDER.Rate AS [SalesOrderRate], IsNull(SALES.ActualQuantity, 0) as [BillQTY], IsNull(SALES.Rate, 0) as [BillRate]
INTO #PendingSalesBill
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM, 
		Bl.GodownName as [GodownName], VH.PartyLedgerName as [LedgerName],
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount], BL.TrackingNumber as [TrackingNo]				
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE (VT.VoucherType =''Delivery Note'') And VH.CompanyId=@CompanyID 	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And   (@StockGroupName_List  <> '''' AND SI.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND SI.StockGroup = SI.StockGroup))
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))	
	) AS SALESORDER  

	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, 
		IL.ActualUOM, VH.OrderNo, BL.TrackingNumber as [TrackingNo]			
		FROM  TD_Txn_VchHdr as VH
		Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyId
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyID AND BL.VoucherId=VH.id 
		WHERE  (VT.VoucherType =''Sales'') And IL.ActualQuantity>0 
		And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
		And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	) AS SALES 
   ON SALESORDER.TrackingNo = SALES.TrackingNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


	Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.SalesOrderQTY as [SalesOrderQTY], Sum(B.BillQTY) as [BillQTYTotal],
	B.SalesOrderRate as [Rate], B.GodownName, B.LedgerName
	INTO #grouptempPendingBills
	from #PendingSalesBill as B
	Where  B.SalesOrderQTY > B.BillQTY
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	Group by B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, B.SalesOrderRate, B.SalesOrderQTY, B.GodownName, B.LedgerName
	Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName, B.GodownName, B.LedgerName Desc

	Select Distinct  B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], b.LedgerName as [HQName],
	(B.SalesOrderQTY - B.BillQTYTotal) as [QTY], B.Rate as [Rate], (B.SalesOrderQTY - B.BillQTYTotal) * B.Rate As [Amount]
	from #grouptempPendingBills as B
	Where  B.SalesOrderQTY > B.BillQTYTotal And (B.SalesOrderQTY - B.BillQTYTotal)>0
	And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
	And   (@DepotName_List  <> '''' AND B.GodownName IN (SELECT DepotName FROM #tmpDepotName)  OR (@DepotName_List = ''''  AND B.GodownName = B.GodownName))
	And   (@HQName_List  <> '''' AND B.LedgerName IN (SELECT HQName FROM #tmpHQName)  OR (@HQName_List = ''''  AND B.LedgerName = B.LedgerName))
	Order by B.TransDate,  B.StockGroup, B.StockItemName Desc', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (9, 0, 1, N'Stock', 5, N'StockDetails', N'Stock Details', N'~/OnlineReport/StockDetails.aspx', N'IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockCategoryName'') IS NOT NULL DROP TABLE #tmpStockCategoryName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#StockDetails'') IS NOT NULL DROP TABLE #StockDetails
IF OBJECT_ID(''tempdb..#TempInwardStock'') IS NOT NULL DROP TABLE #TempInwardStock
IF OBJECT_ID(''tempdb..#TempOutwardStock'') IS NOT NULL DROP TABLE #TempOutwardStock

Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockCategoryName'' INTO #tmpStockCategoryName from dbo.GetTableFromString(isnull(@StockCategoryName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))


	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select SD.StockDate, ST.StockCategory,  SD.StockItemName,  Sum(Quantity) as [OpeningStock_QTY]
	Into #tmpOPBalance
	From TD_Txn_StockDetails as SD
	Inner Join TD_Mst_StockItem as ST ON ST.StockItemName=SD.StockItemName And ST.CompanyID=SD.CompanyID
	Where SD.CompanyID=@CompanyID And  StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@StockCategoryName_List  <> '''' AND ST.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND ST.StockCategory = ST.StockCategory))
	Group by StockDate,ST.StockCategory,  SD.StockItemName


--------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [InWard_QTY]
	Into #TempInwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineNo=BL.AccLineNo and IL.InvLineNo=BL.InvLineNo 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.VoucherID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where (VT.VoucherType IN(''Purchase'',''Debit Note'',''Material In'')) And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo 
	And IL.CompanyId= @CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

	--------------------- Satocl Outward Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [OutWard_QTY]
	Into #TempOutwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineNo=BL.AccLineNo and IL.InvLineNo=BL.InvLineNo 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.VoucherID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where (VT.VoucherType IN(''Sales'',''Credit Note''))
	And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo  And IL.CompanyId= @CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))

	--And (@CompanyNames  <> '''' AND IL.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND IL.CompanyID = IL.CompanyID))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

	------------------------------------------------------------------------------

	select op.StockDate as [TransDate], S.StockCategory as [StockCategory],  S.StockItemName as [StockItemName], i.VoucherType as [VoucherName], 
	Sum(IsNull(Op.OpeningStock_QTY,0)) as [QTY_Opening], Sum(IsNull(I.InWard_QTY,0)) as [QTY_InWard],   Sum(IsNull(O.OutWard_QTY,0)) as [QTY_OutWard] ,
	Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0)) -  Sum(IsNull(O.OutWard_QTY,0)) as [QTY_Closing] 
	--,((IsNull(Op.OpeningStock_QTY,0) + IsNull(I.InWard_QTY,0)) - IsNull(O.OutWard_QTY,0)) as [QTY_Closing]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #TempInwardStock as I ON I.StockItemName=S.StockItemName
	Left Outer Join #TempOutwardStock as O ON O.StockItemName=S.StockItemName
	Where 
	 (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@StockCategoryName_List  <> '''' AND S.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND S.StockCategory = S.StockCategory))
	GROUP bY op.StockDate, S.StockCategory, S.StockItemName, i.VoucherType
	Order by S.StockItemName', N'------- Stock Details----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockCategoryName_List as Varchar(2500)='''', @StockItemName_List as Varchar(2500)='''',
		@VoucherType_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
SET @DateFrom =''04/01/2020''
SET @DateTo = ''04/04/2020''

SET @StockCategoryName_List = ''''
SET @StockItemName_List = ''100 ML BRUTE PET BOTTLE''
SET @VoucherType_List = ''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockCategoryName'') IS NOT NULL DROP TABLE #tmpStockCategoryName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#StockDetails'') IS NOT NULL DROP TABLE #StockDetails
IF OBJECT_ID(''tempdb..#TempInwardStock'') IS NOT NULL DROP TABLE #TempInwardStock
IF OBJECT_ID(''tempdb..#TempOutwardStock'') IS NOT NULL DROP TABLE #TempOutwardStock

Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockCategoryName'' INTO #tmpStockCategoryName from dbo.GetTableFromString(isnull(@StockCategoryName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))


	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select SD.StockDate, ST.StockCategory,  SD.StockItemName,  Sum(Quantity) as [OpeningStock_QTY]
	Into #tmpOPBalance
	From TD_Txn_StockDetails as SD
	Inner Join TD_Mst_StockItem as ST ON ST.StockItemName=SD.StockItemName And ST.CompanyID=SD.CompanyID
	Where SD.CompanyID=@CompanyID And  StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@StockCategoryName_List  <> '''' AND ST.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND ST.StockCategory = ST.StockCategory))
	Group by StockDate,ST.StockCategory,  SD.StockItemName


--------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [InWard_QTY]
	Into #TempInwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineNo=BL.AccLineNo and IL.InvLineNo=BL.InvLineNo 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.VoucherID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where (VT.VoucherType IN(''Purchase'',''Debit Note'',''Material In'')) And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo 
	And IL.CompanyId= @CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

	--------------------- Satocl Outward Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [OutWard_QTY]
	Into #TempOutwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineNo=BL.AccLineNo and IL.InvLineNo=BL.InvLineNo 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.VoucherID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where (VT.VoucherType IN(''Sales'',''Credit Note''))
	And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo  And IL.CompanyId= @CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))

	--And (@CompanyNames  <> '''' AND IL.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND IL.CompanyID = IL.CompanyID))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

	------------------------------------------------------------------------------

	select op.StockDate as [TransDate], S.StockCategory as [StockCategory],  S.StockItemName as [StockItemName], i.VoucherType as [VoucherName], 
	Sum(IsNull(Op.OpeningStock_QTY,0)) as [QTY_Opening], Sum(IsNull(I.InWard_QTY,0)) as [QTY_InWard],   Sum(IsNull(O.OutWard_QTY,0)) as [QTY_OutWard] ,
	Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0)) -  Sum(IsNull(O.OutWard_QTY,0)) as [QTY_Closing] 
	--,((IsNull(Op.OpeningStock_QTY,0) + IsNull(I.InWard_QTY,0)) - IsNull(O.OutWard_QTY,0)) as [QTY_Closing]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #TempInwardStock as I ON I.StockItemName=S.StockItemName
	Left Outer Join #TempOutwardStock as O ON O.StockItemName=S.StockItemName
	Where 
	 (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@StockCategoryName_List  <> '''' AND S.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND S.StockCategory = S.StockCategory))
	GROUP bY op.StockDate, S.StockCategory, S.StockItemName, i.VoucherType
	Order by S.StockItemName', N'IF OBJECT_ID(''tempdb..#tmpStockCategoryName'') IS NOT NULL DROP TABLE #tmpStockCategoryName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#StockDetails'') IS NOT NULL DROP TABLE #StockDetails
IF OBJECT_ID(''tempdb..#TempInwardStock'') IS NOT NULL DROP TABLE #TempInwardStock
IF OBJECT_ID(''tempdb..#TempOutwardStock'') IS NOT NULL DROP TABLE #TempOutwardStock

Declare @CompanyID as Uniqueidentifier
Select @CompanyID= c.ID From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockCategoryName'' INTO #tmpStockCategoryName from dbo.GetTableFromString(isnull(@StockCategoryName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))


	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select SD.StockDate, ST.StockCategory,  SD.StockItemName,  Sum(ActualQty) as [OpeningStock_QTY]
	Into #tmpOPBalance
	From  TD_Mst_StockItem as ST 
	Inner Join TD_Stock as SD ON ST.StockItemName=SD.StockItemName And ST.CompanyID=SD.CompanyID 
	Where ST.CompanyID=@CompanyID And  StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@StockCategoryName_List  <> '''' AND ST.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND ST.StockCategory = ST.StockCategory))
	Group by StockDate,ST.StockCategory,  SD.StockItemName

	--select * from #tmpOPBalance

--------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [InWard_QTY]
	Into #TempInwardStock
	From TD_Mst_VoucherType as VT --ON VT.VoucherTypeName=VH.VoucherTypeName
	Inner Join TD_Txn_VchHdr as VH ON  VT.CompanyId=VH.CompanyID 
	Inner Join TD_Mst_StockItem as SI ON SI.CompanyID=VT.CompanyID 
	Inner Join TD_Txn_InvLine as IL ON IL.CompanyId=VT.CompanyId And IL.VoucherID=vh.ID And IL.StockItemName=SI.StockItemName
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineId and IL.Id=BL.InvLineId 
		
	Where VT.CompanyId= @CompanyID And (VT.VoucherType IN(''Purchase'',''Debit Note'',''Material In'')) 
	And  CAST(il.EntryDate AS DATE) >= @DateFrom  and CAST(il.EntryDate AS DATE) <= @DateFrom 
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

	--------------------- Satocl Outward Data ------------------
	Select  CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [OutWard_QTY]
	Into #TempOutwardStock
	From TD_Mst_VoucherType as VT --ON VT.VoucherTypeName=VH.VoucherTypeName
	Inner Join TD_Txn_VchHdr as VH ON  VT.CompanyId=VH.CompanyID 
	Inner Join TD_Mst_StockItem as SI ON SI.CompanyID=VT.CompanyID 
	Inner Join TD_Txn_InvLine as IL ON IL.CompanyId=VT.CompanyId And IL.VoucherID=vh.ID And IL.StockItemName=SI.StockItemName
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineId and IL.Id=BL.InvLineId 
		
	Where VT.CompanyId= @CompanyID And (VT.VoucherType IN(''Sales'',''Credit Note'')) 
	And  CAST(il.EntryDate AS DATE) >= @DateFrom  and CAST(il.EntryDate AS DATE) <= @DateFrom 
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType
	------------------------------------------------------------------------------

	select op.StockDate as [TransDate], S.StockCategory as [StockCategory],  S.StockItemName as [StockItemName], i.VoucherType as [VoucherName], 
	Sum(IsNull(Op.OpeningStock_QTY,0)) as [QTY_Opening], Sum(IsNull(I.InWard_QTY,0)) as [QTY_InWard],   Sum(IsNull(O.OutWard_QTY,0)) as [QTY_OutWard] ,
	Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0)) -  Sum(IsNull(O.OutWard_QTY,0)) as [QTY_Closing] 
	--,((IsNull(Op.OpeningStock_QTY,0) + IsNull(I.InWard_QTY,0)) - IsNull(O.OutWard_QTY,0)) as [QTY_Closing]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #TempInwardStock as I ON I.StockItemName=S.StockItemName
	Left Outer Join #TempOutwardStock as O ON O.StockItemName=S.StockItemName
	Where 
	 (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@StockCategoryName_List  <> '''' AND S.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND S.StockCategory = S.StockCategory))
	GROUP bY op.StockDate, S.StockCategory, S.StockItemName, i.VoucherType
	Order by S.StockItemName', N'------ Stock Details----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockCategoryName_List as Varchar(2500)='''', @StockItemName_List as Varchar(2500)='''',
		@VoucherType_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''05/01/2021''
SET @DateTo = ''05/31/2021''

SET @StockCategoryName_List = ''''
SET @StockItemName_List = ''''
SET @VoucherType_List = ''''


IF OBJECT_ID(''tempdb..#tmpStockCategoryName'') IS NOT NULL DROP TABLE #tmpStockCategoryName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType

IF OBJECT_ID(''tempdb..#tmpOPBalance'') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID(''tempdb..#StockDetails'') IS NOT NULL DROP TABLE #StockDetails
IF OBJECT_ID(''tempdb..#TempInwardStock'') IS NOT NULL DROP TABLE #TempInwardStock
IF OBJECT_ID(''tempdb..#TempOutwardStock'') IS NOT NULL DROP TABLE #TempOutwardStock

Declare @CompanyID as Uniqueidentifier
Select @CompanyID= c.ID From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockCategoryName'' INTO #tmpStockCategoryName from dbo.GetTableFromString(isnull(@StockCategoryName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))


	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select SD.StockDate, ST.StockCategory,  SD.StockItemName,  Sum(ActualQty) as [OpeningStock_QTY]
	Into #tmpOPBalance
	From  TD_Mst_StockItem as ST 
	Inner Join TD_Stock as SD ON ST.StockItemName=SD.StockItemName And ST.CompanyID=SD.CompanyID 
	Where ST.CompanyID=@CompanyID And  StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@StockCategoryName_List  <> '''' AND ST.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND ST.StockCategory = ST.StockCategory))
	Group by StockDate,ST.StockCategory,  SD.StockItemName

	--select * from #tmpOPBalance

--------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [InWard_QTY]
	Into #TempInwardStock
	From TD_Mst_VoucherType as VT --ON VT.VoucherTypeName=VH.VoucherTypeName
	Inner Join TD_Txn_VchHdr as VH ON  VT.CompanyId=VH.CompanyID 
	Inner Join TD_Mst_StockItem as SI ON SI.CompanyID=VT.CompanyID 
	Inner Join TD_Txn_InvLine as IL ON IL.CompanyId=VT.CompanyId And IL.VoucherID=vh.ID And IL.StockItemName=SI.StockItemName
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineId and IL.Id=BL.InvLineId 
		
	Where VT.CompanyId= @CompanyID And (VT.VoucherType IN(''Purchase'',''Debit Note'',''Material In'')) 
	And  CAST(il.EntryDate AS DATE) >= @DateFrom  and CAST(il.EntryDate AS DATE) <= @DateFrom 
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

	--------------------- Satocl Outward Data ------------------
	Select  CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [OutWard_QTY]
	Into #TempOutwardStock
	From TD_Mst_VoucherType as VT --ON VT.VoucherTypeName=VH.VoucherTypeName
	Inner Join TD_Txn_VchHdr as VH ON  VT.CompanyId=VH.CompanyID 
	Inner Join TD_Mst_StockItem as SI ON SI.CompanyID=VT.CompanyID 
	Inner Join TD_Txn_InvLine as IL ON IL.CompanyId=VT.CompanyId And IL.VoucherID=vh.ID And IL.StockItemName=SI.StockItemName
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineId and IL.Id=BL.InvLineId 
		
	Where VT.CompanyId= @CompanyID And (VT.VoucherType IN(''Sales'',''Credit Note'')) 
	And  CAST(il.EntryDate AS DATE) >= @DateFrom  and CAST(il.EntryDate AS DATE) <= @DateFrom 
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@StockCategoryName_List  <> '''' AND SI.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND SI.StockCategory = SI.StockCategory))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType
	------------------------------------------------------------------------------

	select op.StockDate as [TransDate], S.StockCategory as [StockCategory],  S.StockItemName as [StockItemName], i.VoucherType as [VoucherName], 
	Sum(IsNull(Op.OpeningStock_QTY,0)) as [QTY_Opening], Sum(IsNull(I.InWard_QTY,0)) as [QTY_InWard],   Sum(IsNull(O.OutWard_QTY,0)) as [QTY_OutWard] ,
	Sum(IsNull(Op.OpeningStock_QTY,0)) + Sum(IsNull(I.InWard_QTY,0)) -  Sum(IsNull(O.OutWard_QTY,0)) as [QTY_Closing] 
	--,((IsNull(Op.OpeningStock_QTY,0) + IsNull(I.InWard_QTY,0)) - IsNull(O.OutWard_QTY,0)) as [QTY_Closing]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #TempInwardStock as I ON I.StockItemName=S.StockItemName
	Left Outer Join #TempOutwardStock as O ON O.StockItemName=S.StockItemName
	Where 
	 (@StockItemName_List  <> '''' AND S.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND S.StockItemName = S.StockItemName))
	And (@StockCategoryName_List  <> '''' AND S.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND S.StockCategory = S.StockCategory))
	GROUP bY op.StockDate, S.StockCategory, S.StockItemName, i.VoucherType
	Order by S.StockItemName', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (10, 0, 1, N'Accounts', 1, N'DebitCreditNoteRegister', N'Debit Credit Note Register', N'~/OnlineReport/DebitCreditNoteRegister.aspx', N'IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))


SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName, IL.StockItemName, IL.ActualQuantity,   IL.Rate, IL.RateUOM, IL.Amount,
AL.LedgerName as [GST], AL.Amount as [GSTAmount], IL.Amount + 0 as [TotalAmount] , VH.Narration , al.VoucherID
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
FULL OUTER JOIN TD_Txn_AccLine as AL ON /*IL.AccLineNo = AL.AccLineNo AND */ VH.CompanyID = AL.CompanyID AND IL.VoucherID = AL.VoucherID And  (AL.LedgerName like ''CGST%'' OR AL.LedgerName like ''SGST%'' OR AL.LedgerName like ''IGST%'')
Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyID
where (VT.VoucherTypeParent=''Credit Note'' Or VT.VoucherTypeParent=''Debit Note'')
--(VH.VoucherTypeName like ''%Debit Note%'' or VoucherTypeName like ''%credit%'')
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
	And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And   (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName = VH.VoucherTypeName))
Order by VH.Date, VH.PartyLedgerName, IL.StockItemName Desc

--TD_Txn_AccLine', N'----- Debit and Credit Note Register ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null, @VoucherType_List as Varchar(500)='''',  @PartyName_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''07/30/2021''
SET @VoucherType_List = ''''
SET @PartyName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName, IsNull(IL.StockItemName,'''') as [StockItemName], IsNull(IL.ActualQuantity,0) as [ActualQuantity],
  IsNull(IL.Rate,0) as [Rate], IsNull(IL.RateUOM,'''') as [RateUOM], Isnull(IL.Amount, 0) as [Amount], '''' as [GST],
 Sum(IsNull(AL.Amount, 0)) as [GSTAmount], (IsNull(IL.Amount,0) + Sum(IsNull(AL.Amount, 0))) as [TotalAmount] , '''' as [Narration]
FROM  TD_Txn_VchHdr as VH 
Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyID
LEFT OUTER JOIN TD_Txn_AccLine as AL ON  VH.CompanyID = AL.CompanyID AND  AL.VoucherID =VH.Id And  (AL.LedgerName like ''CGST%'' OR AL.LedgerName like ''SGST%'' OR AL.LedgerName like ''IGST%'')
LEFT OUTER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
where (VT.VoucherTypeParent=''Credit Note'' Or VT.VoucherTypeParent=''Debit Note'') And VH.IsCancelled=0
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo And VH.CompanyId=@CompanyID
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))	
	And  (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName = VH.VoucherTypeName))
	And  (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
Group By VH.VoucherTypeName, VH.Date , vh.PartyLedgerName, VH.Reference, VH.CostCentreName, IL.StockItemName, IL.ActualQuantity, 
	IL.Rate, IL.RateUOM, IL.Amount
Order by VH.Date, VH.PartyLedgerName, IL.StockItemName Desc
', N'IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName, IsNull(IL.StockItemName,'''') as [StockItemName], IsNull(IL.ActualQuantity,0) as [ActualQuantity],
  IsNull(IL.Rate,0) as [Rate], IsNull(IL.RateUOM,'''') as [RateUOM], Isnull(IL.Amount, 0) as [Amount], '''' as [GST],
 Sum(IsNull(AL.Amount, 0)) as [GSTAmount], (IsNull(IL.Amount,0) + Sum(IsNull(AL.Amount, 0))) as [TotalAmount] , VH.Narration as [Narration]
FROM  TD_Txn_VchHdr as VH 
Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyID
LEFT OUTER JOIN TD_Txn_AccLine as AL ON  VH.CompanyID = AL.CompanyID AND  AL.VoucherID =VH.Id And  (AL.LedgerName like ''CGST%'' OR AL.LedgerName like ''SGST%'' OR AL.LedgerName like ''IGST%'')
LEFT OUTER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
where (VT.VoucherTypeParent=''Credit Note'' Or VT.VoucherTypeParent=''Debit Note'') And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo And VH.CompanyId=@CompanyID
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))	
	And  (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName = VH.VoucherTypeName))
	And  (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
Group By VH.VoucherTypeName, VH.Date , vh.PartyLedgerName, VH.Reference, VH.CostCentreName, IL.StockItemName, IL.ActualQuantity, 
	IL.Rate, IL.RateUOM, IL.Amount, VH.Narration
Order by VH.Date, VH.PartyLedgerName, IL.StockItemName Desc
', N'----- Debit and Credit Note Register ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null, @VoucherType_List as Varchar(500)='''',  @PartyName_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''07/30/2021''
SET @VoucherType_List = ''''
SET @PartyName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName, IsNull(IL.StockItemName,'''') as [StockItemName], IsNull(IL.ActualQuantity,0) as [ActualQuantity],
  IsNull(IL.Rate,0) as [Rate], IsNull(IL.RateUOM,'''') as [RateUOM], Isnull(IL.Amount, 0) as [Amount], '''' as [GST],
 Sum(IsNull(AL.Amount, 0)) as [GSTAmount], (IsNull(IL.Amount,0) + Sum(IsNull(AL.Amount, 0))) as [TotalAmount] , VH.Narration as [Narration]
FROM  TD_Txn_VchHdr as VH 
Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyID
LEFT OUTER JOIN TD_Txn_AccLine as AL ON  VH.CompanyID = AL.CompanyID AND  AL.VoucherID =VH.Id And  (AL.LedgerName like ''CGST%'' OR AL.LedgerName like ''SGST%'' OR AL.LedgerName like ''IGST%'')
LEFT OUTER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
where (VT.VoucherTypeParent=''Credit Note'' Or VT.VoucherTypeParent=''Debit Note'') And VH.IsOptional=0 And VH.IsDeleted=0 And IsCancelled=0
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo And VH.CompanyId=@CompanyID
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))	
	And  (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName = VH.VoucherTypeName))
	And  (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
Group By VH.VoucherTypeName, VH.Date , vh.PartyLedgerName, VH.Reference, VH.CostCentreName, IL.StockItemName, IL.ActualQuantity, 
	IL.Rate, IL.RateUOM, IL.Amount, VH.Narration
Order by VH.Date, VH.PartyLedgerName, IL.StockItemName Desc
', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (11, 0, 1, N'Accounts', 2, N'JournalRegister', N'Journal Register', N'~/OnlineReport/JournalRegister.aspx', N'IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#tmpLedger'') IS NOT NULL DROP TABLE #tmpLedger

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedger from	 dbo.GetTableFromString(isnull(@LedgerName_List,''''))


SELECT  VH.Date, VH.PartyLedgerName as [PartyName],  AL.LedgerName,  BL.BillName,   VH.CostCentreName,  AL.Amount, VH.Narration, BL.BillName as [Reference], VH.VoucherTypeName,  AL.IsPartyLedger,  VH.VoucherNo
FROM  TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND VH.CompanyID = BL.Companyid AND 
		AL.VoucherID = BL.VoucherId AND VH.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo 						 												 
Where VH.VoucherTypeName like ''%Journal'' And bl.BillLineNo !=2
	And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
	And (@CostCenter_List  <> '''' AND VH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND VH.CostCentreName = VH.CostCentreName))
	And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedger)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName))
Order by VH.Date, VH.PartyLedgerName, VH.CostCentreName Desc', N'----- Journal Register ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @PartyName_List as Varchar(500)='''', @CostCenter_List as Varchar(500)='''', @LedgerName_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
SET @DateFrom =''01/01/2020''
SET @DateTo = ''12/30/2020''
SET @PartyName_List = ''''
SET @CostCenter_List = ''''
SET @LedgerName_List = ''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#tmpLedger'') IS NOT NULL DROP TABLE #tmpLedger

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedger from	 dbo.GetTableFromString(isnull(@LedgerName_List,''''))


SELECT  VH.Date, VH.PartyLedgerName as [PartyName],  AL.LedgerName,  BL.BillName,   VH.CostCentreName,  AL.Amount, VH.Narration, BL.BillName as [Reference], VH.VoucherTypeName,  AL.IsPartyLedger,  VH.VoucherNo
FROM  TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND VH.CompanyID = BL.Companyid AND 
		AL.VoucherID = BL.VoucherId AND VH.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo 						 												 
Where VH.VoucherTypeName like ''%Journal'' And bl.BillLineNo !=2
	And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
	And (@CostCenter_List  <> '''' AND VH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND VH.CostCentreName = VH.CostCentreName))
	And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedger)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName))
Order by VH.Date, VH.PartyLedgerName, VH.CostCentreName Desc', N'IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#tmpLedger'') IS NOT NULL DROP TABLE #tmpLedger

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedger from	 dbo.GetTableFromString(isnull(@LedgerName_List,''''))

SELECT  VH.Date, VH.PartyLedgerName as [PartyName],  AL.LedgerName,  BL.BillName,   VH.CostCentreName,  AL.Amount, VH.Narration, BL.BillName as [Reference], VH.VoucherTypeName,  AL.IsPartyLedger,  VH.VoucherNo
FROM  TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.Id 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND VH.CompanyID = BL.Companyid AND 
		AL.VoucherID = BL.VoucherId AND VH.Id = BL.VoucherId AND AL.Id = BL.AccLineId 						 												 
Where VH.CompanyID = @CompanyID  And VH.Date >= @DateFrom AND VH.Date <= @DateTo
AND VH.VoucherTypeName like ''%Journal'' --And bl.BillLineNo !=2		
And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (@CostCenter_List  <> '''' AND VH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND VH.CostCentreName = VH.CostCentreName))
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedger)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName))
Order by VH.Date, VH.PartyLedgerName, VH.CostCentreName Desc', N'----- Journal Register ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @PartyName_List as Varchar(500)='''', @CostCenter_List as Varchar(500)='''', @LedgerName_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
SET @DateFrom =''01/01/2020''
SET @DateTo = ''12/30/2020''
SET @PartyName_List = ''''
SET @CostCenter_List = ''''
SET @LedgerName_List = ''''

IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#tmpLedger'') IS NOT NULL DROP TABLE #tmpLedger

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedger from	 dbo.GetTableFromString(isnull(@LedgerName_List,''''))

SELECT  VH.Date, VH.PartyLedgerName as [PartyName],  AL.LedgerName,  BL.BillName,   VH.CostCentreName,  AL.Amount, VH.Narration, BL.BillName as [Reference], VH.VoucherTypeName,  AL.IsPartyLedger,  VH.VoucherNo
FROM  TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.Id 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND VH.CompanyID = BL.Companyid AND 
		AL.VoucherID = BL.VoucherId AND VH.Id = BL.VoucherId AND AL.Id = BL.AccLineId 						 												 
Where VH.CompanyID = @CompanyID  And VH.Date >= @DateFrom AND VH.Date <= @DateTo
AND VH.VoucherTypeName like ''%Journal'' --And bl.BillLineNo !=2		
And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (@CostCenter_List  <> '''' AND VH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND VH.CostCentreName = VH.CostCentreName))
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedger)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName))
Order by VH.Date, VH.PartyLedgerName, VH.CostCentreName Desc', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (12, 0, 1, N'Stock', 6, N'NegativeStockReport', N'Negative Stock Report', N'~/OnlineReport/NegativeStockReport.aspx', N'

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))


SELECT SD.StockDate, SD.StockItemName,  SD.BatchName, SD.Quantity, SD.UOM, SD.Rate, SD.Amount, SD.GodownName
FROM TD_Txn_StockDetails as SD
where SD.Quantity like ''-%'' --and SD.StockDate=''2021-01-03 00:00:00.000'' and SD.StockItemName like ''gly%''
	And (@CompanyNames  <> '''' AND SD.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND SD.CompanyID = SD.CompanyID))
	And SD.StockDate >= @DateFrom AND SD.StockDate <= @DateTo
	And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
Order by SD.StockDate, SD.StockItemName Desc', N'------- Negative Stock Register ----
--DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockItemName_List as Varchar(250)=''''

--Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
--SET @DateFrom =''01/03/2021''
--SET @DateTo = ''01/03/2021''
--SET @StockItemName_List = ''''


IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))


SELECT SD.StockDate, SD.StockItemName,  SD.BatchName, SD.Quantity, SD.UOM, SD.Rate, SD.Amount, SD.GodownName
FROM TD_Txn_StockDetails as SD
where SD.Quantity like ''-%'' --and SD.StockDate=''2021-01-03 00:00:00.000'' and SD.StockItemName like ''gly%''
	And (@CompanyNames  <> '''' AND SD.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND SD.CompanyID = SD.CompanyID))
	And SD.StockDate >= @DateFrom AND SD.StockDate <= @DateTo
	And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
Order by SD.StockDate, SD.StockItemName Desc', N'IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT SD.StockDate as [StockDate], SD.StockItemName as [StockItemName],  SD.BatchName as [BatchName], SD.ActualUom as [UOM], SD.ActualQty as [Quantity], 
ABS(SD.Amount / SD.ActualQty) As [Rate], SD.Amount as [Amount], SD.GodownName
FROM TD_Stock as SD
where SD.ActualQty like ''-%'' And SD.CompanyId=@CompanyID
	And SD.StockDate >= @DateFrom AND SD.StockDate <= @DateTo
	And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
Order by SD.StockDate, SD.StockItemName Desc', N'----- Negative Stock Register ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2020''
SET @DateTo = ''01/03/2021''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT SD.StockDate as [StockDate], SD.StockItemName as [StockItemName],  SD.BatchName as [BatchName], SD.ActualUom as [UOM], SD.ActualQty as [Quantity], 
ABS(SD.Amount / SD.ActualQty) As [Rate], SD.Amount as [Amount], SD.GodownName
FROM TD_Stock as SD
where SD.ActualQty like ''-%'' And SD.CompanyId=@CompanyID
	And SD.StockDate >= @DateFrom AND SD.StockDate <= @DateTo
	And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
Order by SD.StockDate, SD.StockItemName Desc', NULL, 1, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (14, 0, 1, N'Accounts', 3, N'CashBook', N'Cash Book', NULL, N'IF OBJECT_ID(''tempdb..#tmpTransactionType'') IS NOT NULL DROP TABLE #tmpTransactionType
IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''TransactionType '' INTO #tmpTransactionType from dbo.GetTableFromString(isnull(@TransactionType_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#CashTransactions'') is not null
	    drop table #CashTransactions

SELECT DISTINCT VH.CompanyId, AL.LedgerName, 	VH.VoucherID
INTO #CashTransactions
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as  AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
WHERE (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1) 
--AND (VoucherType <> ''Purchase Order'' AND VoucherType <> ''Sales Order'' AND VoucherType <> ''Receipt Note'' AND VoucherType <> ''Delivery Note''  AND VoucherType <> ''#Internal Journal Voucher#'' AND VoucherType <> ''#Internal Stock Journal#'')
AND (L.ParentLedgerGroup IN (''Cash-in-hand''))
AND	VH.CompanyID =@CompanyID
AND VH.Date BETWEEN @DateFrom AND @DateTo
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))
And (@TransactionType_List  <> '''' AND VT.VoucherTypeName IN (SELECT TransactionType FROM #tmpTransactionType)  OR (@TransactionType_List = ''''  AND VT.VoucherTypeName = VT.VoucherTypeName ))


SELECT VH.Date as [Date], L.LedgerName as [LedgerName],  CashTxns.LedgerName As [SubLedgerName], VT.VoucherTypeName as [TransactionType],
L.ParentLedgerGroup As [Particular], AL.Amount As Amount,  VH.Narration as [Narration], AL.LedgerName as [BillType]
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
Inner Join #CashTransactions CashTxns ON CashTxns.CompanyID = VH.CompanyID AND CashTxns.VoucherID = VH.VoucherID
WHERE  CashTxns.LedgerName <> AL.LedgerName
AND C.CompanyID =@CompanyID', N'----- Cash Book ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,
@TransactionType_List as Varchar(500)='''',  @LedgerName_List as Varchar(2500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2020''
SET @DateTo = ''04/15/2020''
SET @TransactionType_List = ''Payment''
SET @LedgerName_List = ''''

IF OBJECT_ID(''tempdb..#tmpTransactionType'') IS NOT NULL DROP TABLE #tmpTransactionType
IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''TransactionType '' INTO #tmpTransactionType from dbo.GetTableFromString(isnull(@TransactionType_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#CashTransactions'') is not null
	    drop table #CashTransactions

SELECT DISTINCT VH.CompanyId, AL.LedgerName, 	VH.VoucherID
INTO #CashTransactions
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as  AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
WHERE (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1) 
--AND (VoucherType <> ''Purchase Order'' AND VoucherType <> ''Sales Order'' AND VoucherType <> ''Receipt Note'' AND VoucherType <> ''Delivery Note''  AND VoucherType <> ''#Internal Journal Voucher#'' AND VoucherType <> ''#Internal Stock Journal#'')
AND (L.ParentLedgerGroup IN (''Cash-in-hand''))
AND	VH.CompanyID =@CompanyID
AND VH.Date BETWEEN @DateFrom AND @DateTo
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))
And (@TransactionType_List  <> '''' AND VT.VoucherTypeName IN (SELECT TransactionType FROM #tmpTransactionType)  OR (@TransactionType_List = ''''  AND VT.VoucherTypeName = VT.VoucherTypeName ))


SELECT VH.Date as [Date], L.LedgerName as [LedgerName],  CashTxns.LedgerName As [SubLedgerName], VT.VoucherTypeName as [TransactionType],
L.ParentLedgerGroup As [Particular], AL.Amount As Amount,  VH.Narration as [Narration], AL.LedgerName as [BillType]
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
Inner Join #CashTransactions CashTxns ON CashTxns.CompanyID = VH.CompanyID AND CashTxns.VoucherID = VH.VoucherID
WHERE  CashTxns.LedgerName <> AL.LedgerName
AND C.CompanyID =@CompanyID', N'IF OBJECT_ID(''tempdb..#tmpTransactionType'') IS NOT NULL DROP TABLE #tmpTransactionType
IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''TransactionType '' INTO #tmpTransactionType from dbo.GetTableFromString(isnull(@TransactionType_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#CashTransactions'') is not null
	    drop table #CashTransactions

SELECT DISTINCT VH.CompanyId, AL.LedgerName, 	VH.ID
INTO #CashTransactions
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.ID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as  AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
WHERE (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1) 
--AND (VoucherType <> ''Purchase Order'' AND VoucherType <> ''Sales Order'' AND VoucherType <> ''Receipt Note'' AND VoucherType <> ''Delivery Note''  AND VoucherType <> ''#Internal Journal Voucher#'' AND VoucherType <> ''#Internal Stock Journal#'')
AND (L.ParentLedgerGroup IN (''Cash-in-hand''))
AND	VH.CompanyID =@CompanyID
AND VH.Date BETWEEN @DateFrom AND @DateTo
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))
And (@TransactionType_List  <> '''' AND VT.VoucherTypeName IN (SELECT TransactionType FROM #tmpTransactionType)  OR (@TransactionType_List = ''''  AND VT.VoucherTypeName = VT.VoucherTypeName ))


SELECT VH.Date as [Date], L.LedgerName as [LedgerName],  CashTxns.LedgerName As [SubLedgerName], VT.VoucherTypeName as [TransactionType],
L.ParentLedgerGroup As [Particular], AL.Amount As Amount,  VH.Narration as [Narration], AL.LedgerName as [BillType]
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.ID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
Inner Join #CashTransactions CashTxns ON CashTxns.CompanyID = VH.CompanyID AND CashTxns.ID = VH.ID
WHERE  CashTxns.LedgerName <> AL.LedgerName
AND C.ID =@CompanyID
order by VH.Date desc', N'----- Cash Book ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,
@TransactionType_List as Varchar(500)='''',  @LedgerName_List as Varchar(2500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2020''
SET @DateTo = ''06/15/2021''
SET @TransactionType_List = ''Payment''
SET @LedgerName_List = ''''

IF OBJECT_ID(''tempdb..#tmpTransactionType'') IS NOT NULL DROP TABLE #tmpTransactionType
IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''TransactionType '' INTO #tmpTransactionType from dbo.GetTableFromString(isnull(@TransactionType_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#CashTransactions'') is not null
	    drop table #CashTransactions

SELECT DISTINCT VH.CompanyId, AL.LedgerName, 	VH.ID
INTO #CashTransactions
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.ID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as  AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
WHERE (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1) 
--AND (VoucherType <> ''Purchase Order'' AND VoucherType <> ''Sales Order'' AND VoucherType <> ''Receipt Note'' AND VoucherType <> ''Delivery Note''  AND VoucherType <> ''#Internal Journal Voucher#'' AND VoucherType <> ''#Internal Stock Journal#'')
AND (L.ParentLedgerGroup IN (''Cash-in-hand''))
AND	VH.CompanyID =@CompanyID
AND VH.Date BETWEEN @DateFrom AND @DateTo
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))
And (@TransactionType_List  <> '''' AND VT.VoucherTypeName IN (SELECT TransactionType FROM #tmpTransactionType)  OR (@TransactionType_List = ''''  AND VT.VoucherTypeName = VT.VoucherTypeName ))


SELECT VH.Date as [Date], L.LedgerName as [LedgerName],  CashTxns.LedgerName As [SubLedgerName], VT.VoucherTypeName as [TransactionType],
L.ParentLedgerGroup As [Particular], AL.Amount As Amount,  VH.Narration as [Narration], AL.LedgerName as [BillType]
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.ID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
Inner Join #CashTransactions CashTxns ON CashTxns.CompanyID = VH.CompanyID AND CashTxns.ID = VH.ID
WHERE  CashTxns.LedgerName <> AL.LedgerName
AND C.ID =@CompanyID
order by VH.Date desc', NULL, 3, N'LIVE')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (15, 0, 1, N'Accounts', 3, N'LedgerReport', N'Ledger Report', NULL, N'IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName
Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
Print @CompanyID
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#LedgerReport'') is not null drop table #LedgerReport
if object_id(''tempdb..#LedgerGSTReport'') is not null drop table #LedgerGSTReport

Select vh.VoucherID ,vh.EntryDate, vh.VoucherTypeName, vh.Narration as [Particular], vh.VoucherNo, vh.PartyLedgerName, vh.Reference, AL1.Amount as [Amount],
ALO.Amount as [OtherExpenses], ALR.Amount as [RounfOff]
Into #LedgerReport
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL1 ON vh.VoucherID= AL1.VoucherID And VH.CompanyID=Al1.CompanyID And Al1.IsDeemedPositive=0
Inner Join TD_Txn_AccLine as ALO ON vh.VoucherID= ALO.VoucherID And VH.CompanyID=ALO.CompanyID And ALO.IsDeemedPositive=1
Inner Join TD_Txn_AccLine as ALR ON vh.VoucherID= ALR.VoucherID And VH.CompanyID=ALR.CompanyID And ALR.IsDeemedPositive=1
where IsCancelled=0 And VH.EntryDate >= @DateFrom AND VH.EntryDate <= @DateTo 
And VH.CompanyID=@CompanyID
And (@LedgerName_List  <> '''' AND vh.PartyLedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (ALO.ledgername like ''%Other Expenses%'') And (ALR.ledgername like ''%Round Off%'') 
order by VH.VoucherID Desc

Select vh.VoucherID , Sum(AL.Amount) as [GSTAmount]
Into #LedgerGSTReport
From #LedgerReport as L
Inner Join TD_Txn_VchHdr as vh ON VH.VoucherID= L.VoucherID
Inner Join TD_Txn_AccLine as AL ON vh.VoucherID= AL.VoucherID And VH.CompanyID=Al.CompanyID
And (AL.ledgername like ''%IGST%'' OR AL.ledgername like ''%SGST%'' OR AL.ledgername like ''%CGST%'') 
Group By vh.VoucherID
order by VH.VoucherID Desc


Select L.EntryDate as [Date], L.PartyLedgerName as [LedgerName], L.Particular as [Particular], L.VoucherTypeName as [VoucherType], L.VoucherNo as [VoucherNo],
L.Reference as [ReferenceNo], L.Particular as [Narration] , L.Amount as [AmountWithoutGST], Abs(GL.GSTAmount) as [GST], Abs(L.OtherExpenses) as [OtherExpenses], Abs(L.RounfOff) as [Roundoff],
IsNull(L.Amount,0)+ Abs(IsNull(GL.GSTAmount,0)) + Abs(IsNull(L.OtherExpenses,0))  as [Amount]
From #LedgerReport as L
Inner Join #LedgerGSTReport as GL ON GL.VoucherID=L.VoucherID
', N'----- Ledger Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @LedgerName_List as Varchar(2500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''03/01/2021''
SET @DateTo = ''03/31/2021''
SET @LedgerName_List = ''UDI Sales Pvt Ltd''

IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName
Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
Print @CompanyID
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#LedgerReport'') is not null drop table #LedgerReport
if object_id(''tempdb..#LedgerGSTReport'') is not null drop table #LedgerGSTReport

Select vh.VoucherID ,vh.EntryDate, vh.VoucherTypeName, vh.Narration as [Particular], vh.VoucherNo, vh.PartyLedgerName, vh.Reference, AL1.Amount as [Amount],
ALO.Amount as [OtherExpenses], ALR.Amount as [RounfOff]
Into #LedgerReport
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL1 ON vh.VoucherID= AL1.VoucherID And VH.CompanyID=Al1.CompanyID And Al1.IsDeemedPositive=0
Inner Join TD_Txn_AccLine as ALO ON vh.VoucherID= ALO.VoucherID And VH.CompanyID=ALO.CompanyID And ALO.IsDeemedPositive=1
Inner Join TD_Txn_AccLine as ALR ON vh.VoucherID= ALR.VoucherID And VH.CompanyID=ALR.CompanyID And ALR.IsDeemedPositive=1
where IsCancelled=0 And VH.EntryDate >= @DateFrom AND VH.EntryDate <= @DateTo 
And VH.CompanyID=@CompanyID
And (@LedgerName_List  <> '''' AND vh.PartyLedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (ALO.ledgername like ''%Other Expenses%'') And (ALR.ledgername like ''%Round Off%'') 
order by VH.VoucherID Desc

Select vh.VoucherID , Sum(AL.Amount) as [GSTAmount]
Into #LedgerGSTReport
From #LedgerReport as L
Inner Join TD_Txn_VchHdr as vh ON VH.VoucherID= L.VoucherID
Inner Join TD_Txn_AccLine as AL ON vh.VoucherID= AL.VoucherID And VH.CompanyID=Al.CompanyID
And (AL.ledgername like ''%IGST%'' OR AL.ledgername like ''%SGST%'' OR AL.ledgername like ''%CGST%'') 
Group By vh.VoucherID
order by VH.VoucherID Desc


Select L.EntryDate as [Date], L.PartyLedgerName as [LedgerName], L.Particular as [Particular], L.VoucherTypeName as [VoucherType], L.VoucherNo as [VoucherNo],
L.Reference as [ReferenceNo], L.Particular as [Narration] , L.Amount as [AmountWithoutGST], Abs(GL.GSTAmount) as [GST], Abs(L.OtherExpenses) as [OtherExpenses], Abs(L.RounfOff) as [Roundoff],
IsNull(L.Amount,0)+ Abs(IsNull(GL.GSTAmount,0)) + Abs(IsNull(L.OtherExpenses,0))  as [Amount]
From #LedgerReport as L
Inner Join #LedgerGSTReport as GL ON GL.VoucherID=L.VoucherID
', N'IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#LedgerReport'') is not null drop table #LedgerReport
if object_id(''tempdb..#LedgerGSTReport'') is not null drop table #LedgerGSTReport

Select vh.Id ,vh.Date, vh.VoucherTypeName, vh.Narration as [Particular], vh.VoucherNo, vh.PartyLedgerName, vh.Reference, AL1.Amount as [Amount],
ALO.Amount as [OtherExpenses], ALR.Amount as [RounfOff]
Into #LedgerReport
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL1 ON vh.Id= AL1.VoucherID And VH.CompanyID=Al1.CompanyID And Al1.IsDeemedPositive=0
Inner Join TD_Txn_AccLine as ALO ON vh.Id= ALO.VoucherID And VH.CompanyID=ALO.CompanyID And ALO.IsDeemedPositive=1
Inner Join TD_Txn_AccLine as ALR ON vh.Id= ALR.VoucherID And VH.CompanyID=ALR.CompanyID And ALR.IsDeemedPositive=1
where IsCancelled=0 And VH.EntryDate >= @DateFrom AND VH.EntryDate <= @DateTo 
And VH.CompanyID=@CompanyID
And (@LedgerName_List  <> '''' AND vh.PartyLedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (ALO.ledgername like ''%Other Expenses%'') And (ALR.ledgername like ''%Round Off%'') 
order by VH.Id Desc

Select vh.Id , Sum(AL.Amount) as [GSTAmount]
Into #LedgerGSTReport
From #LedgerReport as L
Inner Join TD_Txn_VchHdr as vh ON VH.Id= L.Id
Inner Join TD_Txn_AccLine as AL ON vh.Id= AL.VoucherID And VH.CompanyID=Al.CompanyID
And (AL.ledgername like ''%IGST%'' OR AL.ledgername like ''%SGST%'' OR AL.ledgername like ''%CGST%'') 
Group By vh.Id
order by VH.Id Desc


Select L.Date as [Date], L.PartyLedgerName as [LedgerName], L.Particular as [Particular], L.VoucherTypeName as [VoucherType], L.VoucherNo as [VoucherNo],
L.Reference as [ReferenceNo], L.Particular as [Narration] , L.Amount as [AmountWithoutGST], Abs(GL.GSTAmount) as [GST], Abs(L.OtherExpenses) as [OtherExpenses], Abs(L.RounfOff) as [Roundoff],
IsNull(L.Amount,0)+ Abs(IsNull(GL.GSTAmount,0)) + Abs(IsNull(L.OtherExpenses,0))  as [Amount]
From #LedgerReport as L
Inner Join #LedgerGSTReport as GL ON GL.Id=L.Id
', N'----- Ledger Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @LedgerName_List as Varchar(2500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''03/01/2021''
SET @DateTo = ''05/31/2021''
SET @LedgerName_List = ''''

IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#LedgerReport'') is not null drop table #LedgerReport
if object_id(''tempdb..#LedgerGSTReport'') is not null drop table #LedgerGSTReport

Select vh.Id ,vh.EntryDate, vh.VoucherTypeName, vh.Narration as [Particular], vh.VoucherNo, vh.PartyLedgerName, vh.Reference, AL1.Amount as [Amount],
ALO.Amount as [OtherExpenses], ALR.Amount as [RounfOff]
Into #LedgerReport
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL1 ON vh.Id= AL1.VoucherID And VH.CompanyID=Al1.CompanyID And Al1.IsDeemedPositive=0
Inner Join TD_Txn_AccLine as ALO ON vh.Id= ALO.VoucherID And VH.CompanyID=ALO.CompanyID And ALO.IsDeemedPositive=1
Inner Join TD_Txn_AccLine as ALR ON vh.Id= ALR.VoucherID And VH.CompanyID=ALR.CompanyID And ALR.IsDeemedPositive=1
where IsCancelled=0 And VH.EntryDate >= @DateFrom AND VH.EntryDate <= @DateTo 
And VH.CompanyID=@CompanyID
And (@LedgerName_List  <> '''' AND vh.PartyLedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (ALO.ledgername like ''%Other Expenses%'') And (ALR.ledgername like ''%Round Off%'') 
order by VH.Id Desc

Select vh.Id , Sum(AL.Amount) as [GSTAmount]
Into #LedgerGSTReport
From #LedgerReport as L
Inner Join TD_Txn_VchHdr as vh ON VH.Id= L.Id
Inner Join TD_Txn_AccLine as AL ON vh.Id= AL.VoucherID And VH.CompanyID=Al.CompanyID
And (AL.ledgername like ''%IGST%'' OR AL.ledgername like ''%SGST%'' OR AL.ledgername like ''%CGST%'') 
Group By vh.Id
order by VH.Id Desc


Select L.EntryDate as [Date], L.PartyLedgerName as [LedgerName], L.Particular as [Particular], L.VoucherTypeName as [VoucherType], L.VoucherNo as [VoucherNo],
L.Reference as [ReferenceNo], L.Particular as [Narration] , L.Amount as [AmountWithoutGST], Abs(GL.GSTAmount) as [GST], Abs(L.OtherExpenses) as [OtherExpenses], Abs(L.RounfOff) as [Roundoff],
IsNull(L.Amount,0)+ Abs(IsNull(GL.GSTAmount,0)) + Abs(IsNull(L.OtherExpenses,0))  as [Amount]
From #LedgerReport as L
Inner Join #LedgerGSTReport as GL ON GL.Id=L.Id
', NULL, 3, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (17, 0, 1, N'Accounts', 4, N'CostCenterReport', N'Cost Center', NULL, N'IF OBJECT_ID(''tempdb..#tmpTransactionType'') IS NOT NULL DROP TABLE #tmpTransactionType
IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''TransactionType '' INTO #tmpTransactionType from dbo.GetTableFromString(isnull(@TransactionType_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#CashTransactions'') is not null
	    drop table #CashTransactions

SELECT DISTINCT VH.CompanyId, AL.LedgerName, 	VH.VoucherID
INTO #CashTransactions
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as  AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
WHERE (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1) 
--AND (VoucherType <> ''Purchase Order'' AND VoucherType <> ''Sales Order'' AND VoucherType <> ''Receipt Note'' AND VoucherType <> ''Delivery Note''  AND VoucherType <> ''#Internal Journal Voucher#'' AND VoucherType <> ''#Internal Stock Journal#'')
AND (L.ParentLedgerGroup IN (''Cash-in-hand''))
AND	VH.CompanyID =@CompanyID
AND VH.Date BETWEEN @DateFrom AND @DateTo
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))

SELECT VH.Date as [Date], L.LedgerName as [LedgerName],  CashTxns.LedgerName As [SubLedgerName], VT.VoucherTypeName as [TransactionType],
L.ParentLedgerGroup As [Particular], AL.Amount As Amount,  VH.Narration as [Narration], AL.LedgerName as [BillType]
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
Inner Join #CashTransactions CashTxns ON CashTxns.CompanyID = VH.CompanyID AND CashTxns.VoucherID = VH.VoucherID
WHERE  CashTxns.LedgerName <> AL.LedgerName  AND C.CompanyID =@CompanyID', N'----- Cash Book ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,
@TransactionType_List as Varchar(500)='''',  @LedgerName_List as Varchar(2500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''03/01/2021''
SET @DateTo = ''03/19/2021''
SET @TransactionType_List = ''''
SET @LedgerName_List = ''''

IF OBJECT_ID(''tempdb..#tmpTransactionType'') IS NOT NULL DROP TABLE #tmpTransactionType
IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName

Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''TransactionType '' INTO #tmpTransactionType from dbo.GetTableFromString(isnull(@TransactionType_List,''''))
SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))

if object_id(''tempdb..#CashTransactions'') is not null
	    drop table #CashTransactions

SELECT DISTINCT VH.CompanyId, AL.LedgerName, 	VH.VoucherID
INTO #CashTransactions
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as  AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
WHERE (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1) 
--AND (VoucherType <> ''Purchase Order'' AND VoucherType <> ''Sales Order'' AND VoucherType <> ''Receipt Note'' AND VoucherType <> ''Delivery Note''  AND VoucherType <> ''#Internal Journal Voucher#'' AND VoucherType <> ''#Internal Stock Journal#'')
AND (L.ParentLedgerGroup IN (''Cash-in-hand''))
AND	VH.CompanyID =@CompanyID
AND VH.Date BETWEEN @DateFrom AND @DateTo
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))

SELECT VH.Date as [Date], L.LedgerName as [LedgerName],  CashTxns.LedgerName As [SubLedgerName], VT.VoucherTypeName as [TransactionType],
L.ParentLedgerGroup As [Particular], AL.Amount As Amount,  VH.Narration as [Narration], AL.LedgerName as [BillType]
FROM TD_Mst_Company as C
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as L ON AL.CompanyID = L.CompanyID AND AL.LedgerName = L.LedgerName
Inner Join #CashTransactions CashTxns ON CashTxns.CompanyID = VH.CompanyID AND CashTxns.VoucherID = VH.VoucherID
WHERE  CashTxns.LedgerName <> AL.LedgerName  AND C.CompanyID =@CompanyID', N'IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))
SELECT NAME AS ''CostCenter'' INTO #tmpCostCenter from dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT DISTINCT VH.Date as [Date], vh.CostCentreName as [CostCenter] , AL.LedgerName as [LedgerName], '''' as [Particular], VH.VoucherTypeName as [VoucherType], VH.VoucherNo as [VoucherNo],
BL.BillName as [ReferenceNo], VH.Narration as [Narration] , AL.Amount as [AmountWithoutGST], 0 as [GST], 0 as [OtherExpenses], 0 as [Roundoff],
AL.Amount as [Amount] 
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.Id = AL.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.Id = BL.AccLineId AND VH.Id = BL.VoucherId                       
WHERE VH.CompanyID = @CompanyID  AND VH.Date BETWEEN @DateFrom AND @DateTo  
And (VoucherTypeName like ''Purchase for%'' OR VoucherTypeName like ''Paymen%'')
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))
And (@CostCenter_List  <> '''' AND VH.CostCentreName IN (SELECT CostCenter FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND VH.CostCentreName=VH.CostCentreName ))
 Order By VH.Date, VH.CostCentreName, AL.LedgerName
', N'----- Cost Center Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null, @LedgerName_List as Varchar(500)='''', @CostCenter_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''05/01/2021''
SET @DateTo = ''05/31/2021''
SET @LedgerName_List = ''''
SET @CostCenter_List = ''''

IF OBJECT_ID(''tempdb..#tmpLedgerName'') IS NOT NULL DROP TABLE #tmpLedgerName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''LedgerName'' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''''))
SELECT NAME AS ''CostCenter'' INTO #tmpCostCenter from dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT DISTINCT VH.Date as [Date], vh.CostCentreName as [CostCenter] , AL.LedgerName as [LedgerName], '''' as [Particular], VH.VoucherTypeName as [VoucherType], VH.VoucherNo as [VoucherNo],
BL.BillName as [ReferenceNo], VH.Narration as [Narration] , AL.Amount as [AmountWithoutGST], 0 as [GST], 0 as [OtherExpenses], 0 as [Roundoff],
AL.Amount as [Amount] 
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.Id = AL.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.Id = BL.AccLineId AND VH.Id = BL.VoucherId                       
WHERE VH.CompanyID = @CompanyID  AND VH.Date BETWEEN @DateFrom AND @DateTo  
And (VoucherTypeName like ''Purchase for%'' OR VoucherTypeName like ''Paymen%'')
And (@LedgerName_List  <> '''' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''''  AND AL.LedgerName = AL.LedgerName ))
And (@CostCenter_List  <> '''' AND VH.CostCentreName IN (SELECT CostCenter FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND VH.CostCentreName=VH.CostCentreName ))
 Order By VH.Date, VH.CostCentreName, AL.LedgerName
', NULL, 3, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (18, 0, 1, N'Stock', 6, N'NegativeBatch', N'Negative Batch', NULL, N'IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT DISTINCT [CompanyID], [StockDate], [StockItemName] ,[BatchName] ,SUM([Quantity]) AS Quantity ,[UOM], MAX(Rate) as [Rate], SUM([Amount])AS Amount
FROM [EasyReports3.6].[dbo].[TD_Txn_StockDetails] as SD
WHERE CompanyID = @CompanyID 
And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
AND StockDate = @DateFrom
GROUP BY [CompanyID], [StockDate], [StockItemName]
,[BatchName]
,[UOM] 	  
HAVING SUM([Quantity]) LIKE ''-%''
', N'----- Negative Batch Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockItemName_List as Varchar(2500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2020''
SET @DateTo = ''03/31/2021''
SET @StockItemName_List = ''CARMOZYME (450)''

IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT DISTINCT [CompanyID], [StockDate], [StockItemName] ,[BatchName] ,SUM([Quantity]) AS Quantity ,[UOM], MAX(Rate) as [Rate], SUM([Amount])AS Amount
FROM [EasyReports3.6].[dbo].[TD_Txn_StockDetails] as SD
WHERE CompanyID = @CompanyID 
And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
AND StockDate = @DateFrom
GROUP BY [CompanyID], [StockDate], [StockItemName]
,[BatchName]
,[UOM] 	  
HAVING SUM([Quantity]) LIKE ''-%''
', N'IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT DISTINCT [CompanyID], [StockDate], [StockItemName] ,[BatchName] ,SUM([ActualQty]) AS Quantity ,[ActualUom], MAX(Amount) as [Rate], SUM([Amount])AS Amount
FROM TD_Stock as SD
WHERE SD.CompanyID = @CompanyID  And  CAST(SD.StockDate AS DATE) >= @DateFrom  and CAST(SD.StockDate AS DATE) <= @DateFrom 
And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
AND StockDate = @DateFrom
GROUP BY [CompanyID], [StockDate], [StockItemName]
,[BatchName] ,[ActualUom] 	  
HAVING SUM([ActualQty]) LIKE ''-%''', N'----- Negative Batch Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockItemName_List as Varchar(2500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''05/31/2021''
SET @DateTo = ''05/31/2021''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT DISTINCT [CompanyID], [StockDate], [StockItemName] ,[BatchName] ,SUM([ActualQty]) AS Quantity ,[ActualUom], MAX(Amount) as [Rate], SUM([Amount])AS Amount
FROM TD_Stock as SD
WHERE SD.CompanyID = @CompanyID  And  CAST(SD.StockDate AS DATE) >= @DateFrom  and CAST(SD.StockDate AS DATE) <= @DateFrom 
And   (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
AND StockDate = @DateFrom
GROUP BY [CompanyID], [StockDate], [StockItemName]
,[BatchName] ,[ActualUom] 	  
HAVING SUM([ActualQty]) LIKE ''-%''
', NULL, 3, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (19, 0, 1, N'Accounts', 5, N'NegativeLedger', N'NegativeLedger', NULL, N'Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT  AL.LedgerName, ML.ParentLedgerGroup AS GroupName, SUM(case when AL.Amount < 0 then AL.Amount  else 0 end *-1) AS DRAmount,
SUM(case when AL.Amount > 0 then AL.Amount  else 0 end) AS CRAmount, SUM(AL.Amount * - 1) AS Amount                    
FROM TD_Mst_Company as c
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH  ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as ML ON AL.CompanyID = ML.CompanyID AND AL.LedgerName = ML.LedgerName
WHERE     (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1)  And C.CompanyID=@CompanyID  And VH.Date <=@DateFrom
--AND (VT.VoucherType <> ''Purchase Order'') AND (VT.VoucherType <> ''Sales Order'') AND  (VT.VoucherType <> ''Receipt Note'') AND (VT.VoucherType <> ''Delivery Note'') 
--AND  (VT.VoucherType <> ''#Internal Stock Journal#'') AND (VT.VoucherType <> ''Reversing Journal'') AND  (VT.VoucherType <> ''Memorandum'') AND (AL.LedgerName <> ''#InventoryLine#'')
GROUP BY  AL.LedgerName, ML.ParentLedgerGroup
', N'----- Negative Ledger Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null
Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2021''

Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT  AL.LedgerName, ML.ParentLedgerGroup AS GroupName, SUM(case when AL.Amount < 0 then AL.Amount  else 0 end *-1) AS DRAmount,
SUM(case when AL.Amount > 0 then AL.Amount  else 0 end) AS CRAmount, SUM(AL.Amount * - 1) AS Amount                    
FROM TD_Mst_Company as c
INNER JOIN TD_Mst_VoucherType as VT ON C.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH  ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as ML ON AL.CompanyID = ML.CompanyID AND AL.LedgerName = ML.LedgerName
WHERE     (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1)  And C.CompanyID=@CompanyID  And VH.Date <=@DateFrom
--AND (VT.VoucherType <> ''Purchase Order'') AND (VT.VoucherType <> ''Sales Order'') AND  (VT.VoucherType <> ''Receipt Note'') AND (VT.VoucherType <> ''Delivery Note'') 
--AND  (VT.VoucherType <> ''#Internal Stock Journal#'') AND (VT.VoucherType <> ''Reversing Journal'') AND  (VT.VoucherType <> ''Memorandum'') AND (AL.LedgerName <> ''#InventoryLine#'')
GROUP BY  AL.LedgerName, ML.ParentLedgerGroup
', N'Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT  AL.LedgerName, ML.ParentLedgerGroup AS GroupName, SUM(case when AL.Amount < 0 then AL.Amount  else 0 end *-1) AS DRAmount,
SUM(case when AL.Amount > 0 then AL.Amount  else 0 end) AS CRAmount, SUM(AL.Amount * - 1) AS Amount                    
FROM TD_Mst_Company as c
INNER JOIN TD_Mst_VoucherType as VT ON C.ID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH  ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as ML ON AL.CompanyID = ML.CompanyID AND AL.LedgerName = ML.LedgerName
WHERE     (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1)  And C.ID=@CompanyID  And VH.Date <=@DateFrom
--AND (VT.VoucherType <> ''Purchase Order'') AND (VT.VoucherType <> ''Sales Order'') AND  (VT.VoucherType <> ''Receipt Note'') AND (VT.VoucherType <> ''Delivery Note'') 
--AND  (VT.VoucherType <> ''#Internal Stock Journal#'') AND (VT.VoucherType <> ''Reversing Journal'') AND  (VT.VoucherType <> ''Memorandum'') AND (AL.LedgerName <> ''#InventoryLine#'')
GROUP BY  AL.LedgerName, ML.ParentLedgerGroup
', N'----- Negative Ledger Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null
Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2021''

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT  AL.LedgerName, ML.ParentLedgerGroup AS GroupName, SUM(case when AL.Amount < 0 then AL.Amount  else 0 end *-1) AS DRAmount,
SUM(case when AL.Amount > 0 then AL.Amount  else 0 end) AS CRAmount, SUM(AL.Amount * - 1) AS Amount                    
FROM TD_Mst_Company as c
INNER JOIN TD_Mst_VoucherType as VT ON C.ID = VT.CompanyID 
INNER JOIN TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH  ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID ON VT.CompanyID = VH.CompanyID AND VT.VoucherTypeName = VH.VoucherTypeName 
LEFT OUTER JOIN TD_Mst_Ledger as ML ON AL.CompanyID = ML.CompanyID AND AL.LedgerName = ML.LedgerName
WHERE     (VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1)  And C.ID=@CompanyID  And VH.Date <=@DateFrom
--AND (VT.VoucherType <> ''Purchase Order'') AND (VT.VoucherType <> ''Sales Order'') AND  (VT.VoucherType <> ''Receipt Note'') AND (VT.VoucherType <> ''Delivery Note'') 
--AND  (VT.VoucherType <> ''#Internal Stock Journal#'') AND (VT.VoucherType <> ''Reversing Journal'') AND  (VT.VoucherType <> ''Memorandum'') AND (AL.LedgerName <> ''#InventoryLine#'')
GROUP BY  AL.LedgerName, ML.ParentLedgerGroup
', NULL, 3, N'Tested')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (20, 0, 1, N'Accounts', 5, N'ExceptionReport', N'Exception Report', NULL, N'', N'----- Exception Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null, @VoucherType_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2020''
SET @DateTo = ''05/30/2021''
SET @VoucherType_List = ''Cancelled''

IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))

	/****** Script for List Of All Optional Vouchers ******/

	If @VoucherType_List= ''Optional''
		Begin
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND   CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo
			AND VH.PartyLedgerName = AL.LedgerName AND IsOptional = 1 
			--And (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName  =VH.VoucherTypeName  ))
			AND VoucherTypeName = ''Receipts'' 
			Order by Date Desc
		End
	Else If @VoucherType_List= ''Cancelled''
		Begin
			Print ''Cancelled''
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			Left Outer Join TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND  vh.IsCancelled = 1 
			And CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo 
			 --VH.PartyLedgerName = AL.LedgerName AND		 
			Order by Date Desc
		End
	Else If @VoucherType_List= ''Post-Dated''
		Begin
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			Left Outer Join TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND  vh.IsPostDated = 1 
			And CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo 
			And VH.PartyLedgerName = AL.LedgerName 		 
			Order by Date Desc
		End
	', N'IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))

	/****** Script for List Of All Optional Vouchers ******/

	If @VoucherType_List= ''Optional''
		Begin
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND   CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo
			AND VH.PartyLedgerName = AL.LedgerName AND IsOptional = 1 
			--And (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName  =VH.VoucherTypeName  ))
			AND VoucherTypeName = ''Receipts'' 
			Order by Date Desc
		End
	Else If @VoucherType_List= ''Cancelled''
		Begin
			Print ''Cancelled''
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			Left Outer Join TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND  vh.IsCancelled = 1 
			And CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo 
			 --VH.PartyLedgerName = AL.LedgerName AND		 
			Order by Date Desc
		End
	Else If @VoucherType_List= ''Post-Dated''
		Begin
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			Left Outer Join TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND  vh.IsPostDated = 1 
			And CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo 
			And VH.PartyLedgerName = AL.LedgerName 		 
			Order by Date Desc
		End
	', N'----- Exception Report ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null, @VoucherType_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2020''
SET @DateTo = ''05/30/2021''
SET @VoucherType_List = ''''

IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))

	/****** Script for List Of All Optional Vouchers ******/

	If @VoucherType_List= ''Optional''
		Begin
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND   CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo
			AND VH.PartyLedgerName = AL.LedgerName AND IsOptional = 1 
			--And (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName  =VH.VoucherTypeName  ))
			AND VoucherTypeName = ''Receipts'' 
			Order by Date Desc
		End
	Else If @VoucherType_List= ''Cancelled''
		Begin
			Print ''Cancelled''
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			Left Outer Join TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND  vh.IsCancelled = 1 
			And CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo 
			 --VH.PartyLedgerName = AL.LedgerName AND		 
			Order by Date Desc
		End
	Else If @VoucherType_List= ''Post-Dated''
		Begin
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			Left Outer Join TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND  vh.IsPostDated = 1 
			And CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo 
			And VH.PartyLedgerName = AL.LedgerName 		 
			Order by Date Desc
		End
	Else
	Begin
		Print ''Optional''
			SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
					CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
					CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount], vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
			FROM TD_Txn_VchHdr as VH
			INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
			WHERE VH.CompanyID = @CompanyID AND   CAST(vh.Date AS DATE) >= @DateFrom  And CAST(vh.Date AS DATE) <= @DateTo
			AND VH.PartyLedgerName = AL.LedgerName AND IsOptional = 1 
			--And (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName  =VH.VoucherTypeName  ))
			AND VoucherTypeName = ''Receipts'' 
			Order by Date Desc
	End
', NULL, 3, N'Tested')
SET IDENTITY_INSERT [dbo].[RDLCReportQuery] OFF
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_IsReleasedInLive]  DEFAULT ((0)) FOR [IsReleasedInLive]
GO
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_ViewOrder]  DEFAULT ((0)) FOR [ViewOrder]
GO
