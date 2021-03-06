USE [EasyReports4.0_Tally]
GO
/****** Object:  Table [dbo].[RDLCReportQuery]    Script Date: 5/22/2021 4:25:10 PM ******/
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

INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (1, 1, 1, N'Purchase', 1, N'PendingPurchaseOrder', N'Pending Purchase Order', N'~/OnlineReport/PendingPurchaseOrder.aspx', N'
IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPendingPurchaseOrder'') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpPOList'') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID(''tempdb..#tmpItemName'') IS NOT NULL DROP TABLE #tmpItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName

--SELECT NAME AS ''CompanyID'' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''''))

------------- GET PO DETAILS ----------------------------
Select  VH.VoucherID, vh.Date as [PODate], vh.VoucherNo as [PONumber], VH.Reference, Upper(vh.PartyName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Txn_VchHdr as VH
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.VoucherID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  VH.Reference = GVH.OrderNo 
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.VoucherID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.VoucherID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.AccLineNo = IL.AccLineNo AND BT.InvLineNo = IL.InvLineNo 
Where vh.VoucherTypeName Like ''Purchase Order%'' And Gvh.VoucherTypeName Like ''GRN%'' 
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo
And (@CompanyIDs  <> '''' AND vh.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyIDs = ''''  AND vh.CompanyID = vh.CompanyID ))
And (@PartyName_List  <> '''' AND vh.PartyName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyName = vh.PartyName ))
And (@PONo_List  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,-- PPO.Discount , PPO.PORate, PPO.Discount ,
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - Sum(PPO.GRNPOQTY)) As [BalanceQTY], ((PPO.POQTY - Sum(PPO.GRNPOQTY)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate
Having (PPO.POQTY - Sum(PPO.GRNPOQTY))>0  Order By PODate Desc

', N'----- Pending Purchase Order Report ------
--Declare @CompanyIDs as Varchar(2000)='''', @PO_DateFrom as Date=null, @PO_DateTo as Date=null, @PONo_List as Varchar(250)='''',	@PartyName_List as Varchar(250)='''',@ItemName_List as Varchar(250)=''''

------ Init the Value for Validate ----
--Set @PO_DateFrom=''01/01/2020''
--Set @PO_DateTo=''10/30/2020''
--Set @CompanyIDs=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
--Set @PONo_List=''''
--Set @PartyName_List=''''
--Set @ItemName_List=''''

--IF(@PO_DateFrom is null) BEGIN  SET @PO_DateFrom =''1900-01-01'' END    
--IF(@PO_DateTo is null) BEGIN SET @PO_DateTo =''2100-01-01'' END

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPendingPurchaseOrder'') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpPOList'') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID(''tempdb..#tmpItemName'') IS NOT NULL DROP TABLE #tmpItemName

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName

--SELECT NAME AS ''CompanyID'' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(@CompanyIDs,''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''''))

------------- GET PO DETAILS ----------------------------
Select  VH.VoucherID, vh.Date as [PODate], vh.VoucherNo as [PONumber], VH.Reference, Upper(vh.PartyName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Txn_VchHdr as VH
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.VoucherID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  VH.Reference = GVH.OrderNo 
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.VoucherID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.VoucherID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.AccLineNo = IL.AccLineNo AND BT.InvLineNo = IL.InvLineNo 
Where vh.VoucherTypeName Like ''Purchase Order%'' And Gvh.VoucherTypeName Like ''GRN%'' 
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo
And (@CompanyIDs  <> '''' AND vh.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyIDs = ''''  AND vh.CompanyID = vh.CompanyID ))
And (@PartyName_List  <> '''' AND vh.PartyName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyName = vh.PartyName ))
And (@PONo_List  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,-- PPO.Discount , PPO.PORate, PPO.Discount ,
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - Sum(PPO.GRNPOQTY)) As [BalanceQTY], ((PPO.POQTY - Sum(PPO.GRNPOQTY)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate
Having (PPO.POQTY - Sum(PPO.GRNPOQTY))>0  Order By PODate Desc

', N'IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPendingPurchaseOrder'') IS NOT NULL DROP TABLE #tmpPendingPurchaseOrder
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpPOList'') IS NOT NULL DROP TABLE #tmpPOList
IF OBJECT_ID(''tempdb..#tmpItemName'') IS NOT NULL DROP TABLE #tmpItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=''MENDINE PHARMACEUTICALS PVT LTD. (FY 2020-21)''


--SELECT NAME AS ''CompanyID'' INTO #tmpCompanyID from dbo.GetTableFromString(isnull(''MENDINE PHARMACEUTICALS PVT LTD. (FY 2020-21)'',''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull('''',''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull('''',''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull('''',''''))

------------- GET PO DETAILS ----------------------------
Select  VH.ID, vh.Date as [PODate], vh.VoucherNo as [PONumber], VH.Reference, Upper(vh.PartyName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Txn_VchHdr as VH
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.ID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  VH.Reference = GVH.OrderNo 
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.ID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.ID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.AccLineId = IL.AccLineId AND BT.InvLineId = IL.Id 
Where vh.VoucherTypeName Like ''Purchase Order%'' And Gvh.VoucherTypeName Like ''GRN%'' 
And vh.Date>=''02/18/2020'' And vh.Date<=''05/18/2021'' And vh.CompanyId=@CompanyID
And (''''  <> '''' AND vh.PartyName IN (SELECT PartyName FROM #tmpPartyName)  OR ('''' = ''''  AND vh.PartyName = vh.PartyName ))
And (''''  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR ('''' = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (''''  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR ('''' = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,-- PPO.Discount , PPO.PORate, PPO.Discount ,
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - Sum(PPO.GRNPOQTY)) As [BalanceQTY], ((PPO.POQTY - Sum(PPO.GRNPOQTY)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate
Having (PPO.POQTY - Sum(PPO.GRNPOQTY))>0  Order By PODate Desc', N'--- Pending Purchase Order Report 4.0 ------
Declare @CompanyIDs as Varchar(2000)='''', @PO_DateFrom as Date=null, @PO_DateTo as Date=null, @PONo_List as Varchar(250)='''',	@PartyName_List as Varchar(250)='''',@ItemName_List as Varchar(250)=''''

---- Init the Value for Validate ----
Set @PO_DateFrom=''01/01/2021''
Set @PO_DateTo=''10/30/2021''
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
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''PONumber'' INTO #tmpPOList from	 dbo.GetTableFromString(isnull(@PONo_List,''''))
SELECT NAME AS ''ItemName'' INTO #tmpItemName from dbo.GetTableFromString(isnull(@ItemName_List,''''))

------------- GET PO DETAILS ----------------------------
Select  VH.ID, vh.Date as [PODate], vh.VoucherNo as [PONumber], VH.Reference, Upper(vh.PartyName) as [PartyName], Upper(IL.StockItemName) as [ItemName], Il.ActualQuantity as [POQTY], IL.ActualUOM as [UOM],
	    Il.Rate as [PORate], Il.Discount as [Discount],	GVH.OrderNo as [GRNOrderNumber],  Upper(GVH.PartyName) as [GRNPartyName], Upper(GIL.StockItemName) as [GRNItemName], ISNULL(GIl.ActualQuantity,0) as [GRNPOQTY], 
	    CASE WHEN ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) = ''01-Jan-1900'' THEN NULL  ELSE ((dbo.ReturnDueDate(BT.OrderDueDate,vh.Date))) END As OrderDueDate
INTO #tmpPendingPurchaseOrder
From TD_Txn_VchHdr as VH
Inner Join TD_Txn_InvLine as IL ON IL.VoucherID=VH.ID And IL.CompanyId=vh.CompanyID
LEFT OUTER JOIN TD_Txn_VchHdr as GVH ON  VH.Reference = GVH.OrderNo 
LEFT OUTER JOIN TD_Txn_InvLine as GIL ON GIL.VoucherID=GVH.ID And GIL.CompanyId=Gvh.CompanyID And IL.StockItemName=GIL.StockItemName
LEFT OUTER JOIN TD_Txn_BatchLine as BT ON vh.ID=IL.VoucherId And BT.CompanyID = IL.CompanyId AND BT.VoucherId = IL.VoucherID AND BT.AccLineId = IL.AccLineId AND BT.InvLineId = IL.Id 
Where vh.VoucherTypeName Like ''Purchase Order%'' And Gvh.VoucherTypeName Like ''GRN%'' 
And vh.Date>=@PO_DateFrom And vh.Date<=@PO_DateTo And vh.CompanyId=@CompanyID
And (@PartyName_List  <> '''' AND vh.PartyName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyName = vh.PartyName ))
And (@PONo_List  <> '''' AND vh.VoucherNo IN (SELECT PONumber FROM #tmpPOList)  OR (@PONo_List = ''''  AND vh.VoucherNo = vh.VoucherNo ))
And (@ItemName_List  <> '''' AND IL.StockItemName IN (SELECT ItemName FROM #tmpItemName)  OR (@ItemName_List = ''''  AND IL.StockItemName =IL.StockItemName ))
Order By vh.Date Desc, vh.VoucherNo, vh.PartyName, IL.StockItemName


Select PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate ,-- PPO.Discount , PPO.PORate, PPO.Discount ,
Sum(PPO.GRNPOQTY) as [TotalGRNQTY], (PPO.POQTY - Sum(PPO.GRNPOQTY)) As [BalanceQTY], ((PPO.POQTY - Sum(PPO.GRNPOQTY)) * PPO.PORate) as [BalanceAmount]
,PPO.OrderDueDate as [DueDate] ,DATEDIFF(DAY,  PPO.OrderDueDate, GETDATE()) as [OverdueDays]
From #tmpPendingPurchaseOrder as PPO
Group by PPO.PODate, PPO.PONumber, PPO.Reference, PPO.PartyName, PPO.ItemName, PPO.POQTY, PPO.UOM,  PPO.PORate , PPO.Discount , PPO.PORate, PPO.OrderDueDate
Having (PPO.POQTY - Sum(PPO.GRNPOQTY))>0  Order By PODate Desc', NULL, 1, N'Dev')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (2, 1, 1, N'Purchase', 3, N'VendorOutstandingReport', N'Vendor Outstanding', N'~/OnlineReport/VendorOutstanding.aspx', N'
IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.CompanyID, Upper(AH.PartyLedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName],
	    CASE WHEN MIN(BL.Date) IS NULL THEN MIN(AH.Date)	ELSE MIN(BL.Date) END As BillDate, BL.BillName as [BillNo], SUM(BL.Amount*1) As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as AH ON AL.CompanyID = AH.CompanyID AND AL.VoucherID = AH.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo  ON VT.CompanyID = AH.CompanyID AND  VT.VoucherTypeName = AH.VoucherTypeName
WHERE VT.VoucherType = ''Purchase'' And BL.Amount > 0 AND AH.Date >= @DateFrom AND AH.Date <= @DateTo
	And (@CompanyNames  <> '''' AND MC.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND MC.CompanyID = MC.CompanyID))
	And (@PartyName_List  <> '''' AND AH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND AH.PartyLedgerName = AH.PartyLedgerName ))
	And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
GROUP BY MC.CompanyID, 	AH.PartyLedgerName, 	BL.BillName,	AH.CostCentreName


SELECT  MC.CompanyID, AL.LedgerName, BL.BillName, SUM(BL.Amount*-1) as PaymentAmount,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END As PaymentDate
INTO #Payments
FROM TD_Mst_VoucherType as VT 
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName
WHERE VT.VoucherType = ''Payment'' OR VT.VoucherType = ''Debit Note'' OR VT.VoucherType = ''Journal''
	--AND TD_Mst_Company.CompanyID = @CompanyIDs
GROUP BY MC.CompanyID, AL.LedgerName,  BL.BillName,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END

Select  B.*,P.PaymentDate, P.PaymentAmount, (b.BillAmount - p.PaymentAmount) as [PendingAmount],  DATEDIFF(D,BillDate,PaymentDate) As PaymentDays,
L.StateName, L.ParentLedgerGroup as PartyGroup
FROM #Bills B 
   LEFT OUTER JOIN #Payments P ON b.CompanyID = P.CompanyID AND B.PartyName = P.LedgerName AND B.BillNo = P.BillName 
   LEFT OUTER JOIN TD_Mst_Ledger L ON B.CompanyID = L.CompanyID And B.PartyName = L.LedgerName
where  (b.BillAmount - p.PaymentAmount)>0 
', N'--- Vendor Outstanding Report ----
--DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='''', @CostCenter_List as Varchar(250)=''''

--Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
--SET @DateFrom =''01/01/2020''
--SET @DateTo = ''10/30/2020''
--SET @PartyName_List = ''''
--SET @CostCenter_List=''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.CompanyID, Upper(AH.PartyLedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName],
	    CASE WHEN MIN(BL.Date) IS NULL THEN MIN(AH.Date)	ELSE MIN(BL.Date) END As BillDate, BL.BillName as [BillNo], SUM(BL.Amount*1) As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as AH ON AL.CompanyID = AH.CompanyID AND AL.VoucherID = AH.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo  ON VT.CompanyID = AH.CompanyID AND  VT.VoucherTypeName = AH.VoucherTypeName
WHERE VT.VoucherType = ''Purchase'' And BL.Amount > 0 AND AH.Date >= @DateFrom AND AH.Date <= @DateTo
	And (@CompanyNames  <> '''' AND MC.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND MC.CompanyID = MC.CompanyID))
	And (@PartyName_List  <> '''' AND AH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND AH.PartyLedgerName = AH.PartyLedgerName ))
	And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
GROUP BY MC.CompanyID, 	AH.PartyLedgerName, 	BL.BillName,	AH.CostCentreName


SELECT  MC.CompanyID, AL.LedgerName, BL.BillName, SUM(BL.Amount*-1) as PaymentAmount,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END As PaymentDate
INTO #Payments
FROM TD_Mst_VoucherType as VT 
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName
WHERE VT.VoucherType = ''Payment'' OR VT.VoucherType = ''Debit Note'' OR VT.VoucherType = ''Journal''
	--AND TD_Mst_Company.CompanyID = @CompanyIDs
GROUP BY MC.CompanyID, AL.LedgerName,  BL.BillName,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END

Select  B.*,P.PaymentDate, P.PaymentAmount, (b.BillAmount - p.PaymentAmount) as [PendingAmount],  DATEDIFF(D,BillDate,PaymentDate) As PaymentDays,
L.StateName, L.ParentLedgerGroup as PartyGroup
FROM #Bills B 
   LEFT OUTER JOIN #Payments P ON b.CompanyID = P.CompanyID AND B.PartyName = P.LedgerName AND B.BillNo = P.BillName 
   LEFT OUTER JOIN TD_Mst_Ledger L ON B.CompanyID = L.CompanyID And B.PartyName = L.LedgerName
where  (b.BillAmount - p.PaymentAmount)>0 
', N'IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.ID, Upper(AH.PartyLedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName],
	    CASE WHEN MIN(BL.Date) IS NULL THEN MIN(AH.Date)	ELSE MIN(BL.Date) END As BillDate, BL.BillName as [BillNo], SUM(BL.Amount*1) As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as AH ON AL.CompanyID = AH.CompanyID AND AL.VoucherID = AH.ID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.Id = BL.AccLineId  ON VT.CompanyID = AH.CompanyID AND  VT.VoucherTypeName = AH.VoucherTypeName
WHERE VT.VoucherType = ''Purchase'' And BL.Amount > 0 AND AH.Date >= @DateFrom AND AH.Date <= @DateTo
	And MC.Id=@CompanyID
	And (@PartyName_List  <> '''' AND AH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND AH.PartyLedgerName = AH.PartyLedgerName ))
	And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
GROUP BY MC.ID, 	AH.PartyLedgerName, 	BL.BillName,	AH.CostCentreName


SELECT  MC.ID, AL.LedgerName, BL.BillName, SUM(BL.Amount*-1) as PaymentAmount,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END As PaymentDate
INTO #Payments
FROM TD_Mst_VoucherType as VT 
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.Id = BL.AccLineid ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName
WHERE VT.VoucherType = ''Payment'' OR VT.VoucherType = ''Debit Note'' OR VT.VoucherType = ''Journal''
	--AND TD_Mst_Company.CompanyID = @CompanyIDs
GROUP BY MC.ID, AL.LedgerName,  BL.BillName,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END

Select  B.*,P.PaymentDate, P.PaymentAmount, (b.BillAmount - p.PaymentAmount) as [PendingAmount],  DATEDIFF(D,BillDate,PaymentDate) As PaymentDays,
L.StateName, L.ParentLedgerGroup as PartyGroup
FROM #Bills B 
   LEFT OUTER JOIN #Payments P ON b.ID = P.ID AND B.PartyName = P.LedgerName AND B.BillNo = P.BillName 
   LEFT OUTER JOIN TD_Mst_Ledger L ON B.ID = L.CompanyID And B.PartyName = L.LedgerName
where  (b.BillAmount - p.PaymentAmount)>0 
', N'-- Vendor Outstanding Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='''', @CostCenter_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2020''
SET @DateTo = ''10/30/2021''
SET @PartyName_List = ''''
SET @CostCenter_List=''''

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpCostCenter'') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID(''tempdb..#Bills'') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID(''tempdb..#Payments'') IS NOT NULL DROP TABLE #Payments;

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.Id  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''CostCentreName'' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''''))

SELECT  MC.ID, Upper(AH.PartyLedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName],
	    CASE WHEN MIN(BL.Date) IS NULL THEN MIN(AH.Date)	ELSE MIN(BL.Date) END As BillDate, BL.BillName as [BillNo], SUM(BL.Amount*1) As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as AH ON AL.CompanyID = AH.CompanyID AND AL.VoucherID = AH.ID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.Id = BL.AccLineId  ON VT.CompanyID = AH.CompanyID AND  VT.VoucherTypeName = AH.VoucherTypeName
WHERE VT.VoucherType = ''Purchase'' And BL.Amount > 0 AND AH.Date >= @DateFrom AND AH.Date <= @DateTo
	And MC.Id=@CompanyID
	And (@PartyName_List  <> '''' AND AH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND AH.PartyLedgerName = AH.PartyLedgerName ))
	And (@CostCenter_List  <> '''' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''''  AND AH.CostCentreName = AH.CostCentreName ))
GROUP BY MC.ID, 	AH.PartyLedgerName, 	BL.BillName,	AH.CostCentreName


SELECT  MC.ID, AL.LedgerName, BL.BillName, SUM(BL.Amount*-1) as PaymentAmount,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END As PaymentDate
INTO #Payments
FROM TD_Mst_VoucherType as VT 
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.ID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.ID
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.Id = BL.AccLineid ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName
WHERE VT.VoucherType = ''Payment'' OR VT.VoucherType = ''Debit Note'' OR VT.VoucherType = ''Journal''
	--AND TD_Mst_Company.CompanyID = @CompanyIDs
GROUP BY MC.ID, AL.LedgerName,  BL.BillName,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END

Select  B.*,P.PaymentDate, P.PaymentAmount, (b.BillAmount - p.PaymentAmount) as [PendingAmount],  DATEDIFF(D,BillDate,PaymentDate) As PaymentDays,
L.StateName, L.ParentLedgerGroup as PartyGroup
FROM #Bills B 
   LEFT OUTER JOIN #Payments P ON b.ID = P.ID AND B.PartyName = P.LedgerName AND B.BillNo = P.BillName 
   LEFT OUTER JOIN TD_Mst_Ledger L ON B.ID = L.CompanyID And B.PartyName = L.LedgerName
where  (b.BillAmount - p.PaymentAmount)>0 
', NULL, 1, N'Dev')
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

Order by bl.EntryDate Desc', NULL, NULL, NULL, 1, N'Pending')
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
	From TD_Stock 
	Where StockDate>= @DateFrom And StockDate<= @DateTo And CompanyID=@CompanyID
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by StockItemName, GodownName

	---- Fetch In ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [InWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Inward_Value]	
	Into #tmpInward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.ID
	Where (VH.VoucherTypeName LIKE ''Purchase for%'') And  VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And VH.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	
	
	---- Fetch Out ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [OutWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Outward_Value]	
	Into #tmpOutward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.ID
	Where (VH.VoucherTypeName LIKE ''Sales'')
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	

	
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
	Order by S.StockItemName
', N'--- Godown Stock Summary Report ----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodwnName_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''04/01/2021''
SET @DateTo = ''04/30/2021''
SET @GodwnName_List = ''''
SET @StockItemName_List=''''

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
	From TD_Stock 
	Where StockDate>= @DateFrom And StockDate<= @DateTo And CompanyID=@CompanyID
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by StockItemName, GodownName

	---- Fetch In ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [InWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Inward_Value]	
	Into #tmpInward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.ID
	Where (VH.VoucherTypeName LIKE ''Purchase for%'') And  VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And VH.CompanyID=@CompanyID
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	
	
	---- Fetch Out ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [OutWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Outward_Value]	
	Into #tmpOutward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON IL.CompanyId=@CompanyID AND  IL.VoucherID =VH.ID
	INNER JOIN TD_Txn_BatchLine as BL ON BL.CompanyId=@CompanyID AND BL.VoucherID =VH.ID
	Where (VH.VoucherTypeName LIKE ''Sales'')
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And (@GodwnName_List  <> '''' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''''  AND GodownName = GodownName))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	

	
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
	Order by S.StockItemName
', NULL, 1, N'Dev')
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
 FROM  dbo.TD_Stock AS sd 
 INNER JOIN dbo.TD_Mst_StockItem AS SI ON sd.CompanyID = SI.CompanyID AND sd.StockItemName = SI.StockItemName 
 Inner Join TD_Mst_Company as C On c.ID = Sd.CompanyID 
 where  sd.StockDate >= @DateFrom AND sd.StockDate <= @DateTo And SD.CompanyId=@CompanyID
	And (@GodownName_List  <> '''' AND SD.GodownName IN (SELECT GodownName FROM #tmpGodownName)  OR (@GodownName_List = ''''  AND SD.GodownName =SD.GodownName ))
	And (@StockGroup_List  <> '''' AND SI.StockGroup IN (SELECT StockGroup FROM #tmpStockGroup)  OR (@StockGroup_List = ''''  AND SI.StockGroup =SI.StockGroup ))
 	And (@StockItemName_List  <> '''' AND SI.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SI.StockItemName =SI.StockItemName ))
  Order by StockDate, GodownName, StockGroup,StockItemName ', N'--- Final Product Stock----
DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodownName_List as Varchar(250)='''', @StockGroup_List as Varchar(250)='''',
		@StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''10/30/2021''
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
 FROM  dbo.TD_Stock AS sd 
 INNER JOIN dbo.TD_Mst_StockItem AS SI ON sd.CompanyID = SI.CompanyID AND sd.StockItemName = SI.StockItemName 
 Inner Join TD_Mst_Company as C On c.ID = Sd.CompanyID 
 where  sd.StockDate >= @DateFrom AND sd.StockDate <= @DateTo And SD.CompanyId=@CompanyID
	And (@GodownName_List  <> '''' AND SD.GodownName IN (SELECT GodownName FROM #tmpGodownName)  OR (@GodownName_List = ''''  AND SD.GodownName =SD.GodownName ))
	And (@StockGroup_List  <> '''' AND SI.StockGroup IN (SELECT StockGroup FROM #tmpStockGroup)  OR (@StockGroup_List = ''''  AND SI.StockGroup =SI.StockGroup ))
 	And (@StockItemName_List  <> '''' AND SI.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SI.StockItemName =SI.StockItemName ))
  Order by StockDate, GodownName, StockGroup,StockItemName ', NULL, 1, N'Dev')
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
', NULL, NULL, NULL, 1, N'Pending')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (7, 1, 1, N'Purchase', 2, N'PendingPurchaseBill', N'Pending Purchase Bill', N'~/OnlineReport/PendingPurchaseBill.aspx', N'
IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tempPendingPurchaseBills'') IS NOT NULL DROP TABLE #tempPendingPurchaseBills


SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))


SELECT GRN.Date AS [TransDate], GRN.Reference AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], GRN.StockGroup  as [StockGroup],
	   GRN.ActualQuantity AS [GRNQTY], GRN.Rate AS [GRNRate], IsNull(PURCHASE.ActualQuantity, 0) as [BillQTY], IsNull(PURCHASE.Rate, 0) as [BillRate]
INTO #tempPendingPurchaseBills
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM,  IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE  (VH.VoucherTypeName LIKE ''GRN%'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))
		And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS GRN  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE ''PURCHASE FOR%'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))

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

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
SET @DateFrom =''01/01/2020''
SET @DateTo = ''10/30/2020''
SET @PartyName_List = ''''
SET @StockGroupName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tempPendingPurchaseBills'') IS NOT NULL DROP TABLE #tempPendingPurchaseBills


SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))


SELECT GRN.Date AS [TransDate], GRN.Reference AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], GRN.StockGroup  as [StockGroup],
	   GRN.ActualQuantity AS [GRNQTY], GRN.Rate AS [GRNRate], IsNull(PURCHASE.ActualQuantity, 0) as [BillQTY], IsNull(PURCHASE.Rate, 0) as [BillRate]
INTO #tempPendingPurchaseBills
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM,  IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And SI.CompanyID=vh.CompanyID
		WHERE  (VH.VoucherTypeName LIKE ''GRN%'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))
		And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS GRN  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE ''PURCHASE FOR%'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))

	) AS PURCHASE 
		ON GRN.OrderNo = PURCHASE.OrderNo AND GRN.StockItemName = PURCHASE.StockItemName AND GRN.ActualQuantity = PURCHASE.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo, B.VendorName, B.StockGroup, B.StockItemName, (B.GRNQTY - B.BillQTY) as [QTY], B.GRNRate as [Rate], (B.GRNQTY - B.BillQTY) * B.GRNRate As [Amount]

from #tempPendingPurchaseBills as B
Where (@PartyName_List  <> '''' AND B.VendorName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND B.VendorName = B.VendorName ))
And   (@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '''' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND B.StockItemName = B.StockItemName))
And B.GRNQTY > B.BillQTY
Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc', N'IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
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
SET @DateTo = ''10/30/2021''
SET @PartyName_List = ''''
SET @StockGroupName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
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
Order by B.TransDate, B.VendorName, B.StockGroup, B.StockItemName Desc', NULL, 1, N'Dev')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsReleasedInLive], [IsActive], [ReportModule], [ViewOrder], [ReportName], [ReportDisplayName], [ReportURL], [ReportSQLQuery], [ReportSQLQuery_Full], [ReportSQLQuery_Ver4], [ReportSQLQuery_Ver4_Full], [ParameterList], [Version], [Status]) VALUES (8, 1, 1, N'Sales', 1, N'PendingSalesBill', N'Pending Sales Bill', N'~/OnlineReport/PendingSalesBill.aspx', N'
IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpDepotName'') IS NOT NULL DROP TABLE #tmpDepotName
IF OBJECT_ID(''tempdb..#tmpHQName'') IS NOT NULL DROP TABLE #tmpHQName
IF OBJECT_ID(''tempdb..#PendingSalesBill'') IS NOT NULL DROP TABLE #PendingSalesBill

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''DepotName'' INTO #tmpDepotName from dbo.GetTableFromString(isnull(@DepotName_List,''''))
SELECT NAME AS ''HQName'' INTO #tmpHQName from dbo.GetTableFromString(isnull(@HQName_List,''''))


SELECT SALESORDER.Date AS [TransDate], SALESORDER.Reference AS [ChallanBillNo], SALESORDER.PartyName AS [VendorName],  SALESORDER.StockItemName AS [StockItemName], SALESORDER.StockGroup  as [StockGroup],
		SALESORDER.GodownName  as [GodownName],  SALESORDER.ActualQuantity AS [SalesOrderQTY], SALESORDER.Rate AS [SalesOrderRate], IsNull(SALES.ActualQuantity, 0) as [BillQTY], IsNull(SALES.Rate, 0) as [BillRate]
INTO #PendingSalesBill
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM, VH.DestinationGodown as [GodownName],
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And Si.CompanyID=VH.CompanyID
		--INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyId AND VH.VoucherID = BL.VoucherID 
		WHERE  (VH.VoucherTypeName LIKE ''%Sales Order%'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))
		And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS SALESORDER  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE ''%SALES'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))

	) AS SALES 
   ON SALESORDER.OrderNo = SALES.OrderNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], '''' as [HQ],
(B.SalesOrderQTY - B.BillQTY) as [QTY], B.SalesOrderRate as [Rate], (B.SalesOrderQTY - B.BillQTY) * B.SalesOrderRate As [Amount]
from #PendingSalesBill as B
Where B.SalesOrderQTY > B.BillQTY  And
(@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '''' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND B.StockItemName = B.StockItemName))
Order by B.TransDate Desc, B.ChallanBillNo, B.StockGroup, B.StockItemName', N'----- Pending Sales Bill----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockGroupName_List as Varchar(500)='''', @StockItemName_List as Varchar(500)='''',
		@DepotName_List as Varchar(500)='''', @HQName_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
SET @DateFrom =''01/01/2020''
SET @DateTo = ''10/30/2020''

SET @StockGroupName_List = ''''
SET @StockItemName_List = ''''
SET @DepotName_List = ''''
SET @HQName_List = ''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID(''tempdb..#tmpDepotName'') IS NOT NULL DROP TABLE #tmpDepotName
IF OBJECT_ID(''tempdb..#tmpHQName'') IS NOT NULL DROP TABLE #tmpHQName
IF OBJECT_ID(''tempdb..#PendingSalesBill'') IS NOT NULL DROP TABLE #PendingSalesBill

SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''StockGroupName'' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))
SELECT NAME AS ''DepotName'' INTO #tmpDepotName from dbo.GetTableFromString(isnull(@DepotName_List,''''))
SELECT NAME AS ''HQName'' INTO #tmpHQName from dbo.GetTableFromString(isnull(@HQName_List,''''))


SELECT SALESORDER.Date AS [TransDate], SALESORDER.Reference AS [ChallanBillNo], SALESORDER.PartyName AS [VendorName],  SALESORDER.StockItemName AS [StockItemName], SALESORDER.StockGroup  as [StockGroup],
		SALESORDER.GodownName  as [GodownName],  SALESORDER.ActualQuantity AS [SalesOrderQTY], SALESORDER.Rate AS [SalesOrderRate], IsNull(SALES.ActualQuantity, 0) as [BillQTY], IsNull(SALES.Rate, 0) as [BillRate]
INTO #PendingSalesBill
FROM    
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, vh.OrderNo, IL.StockItemName, SI.StockGroup, IL.RateUOM, VH.DestinationGodown as [GodownName],
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And Si.CompanyID=VH.CompanyID
		--INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyId AND VH.VoucherID = BL.VoucherID 
		WHERE  (VH.VoucherTypeName LIKE ''%Sales Order%'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))
		And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS SALESORDER  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineNo = AL.AccLineNo AND IL.VoucherID = AL.VoucherID AND VH.VoucherID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE ''%SALES'')
		And (@CompanyNames  <> '''' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND VH.CompanyID = VH.CompanyID))

	) AS SALES 
   ON SALESORDER.OrderNo = SALES.OrderNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], '''' as [HQ],
(B.SalesOrderQTY - B.BillQTY) as [QTY], B.SalesOrderRate as [Rate], (B.SalesOrderQTY - B.BillQTY) * B.SalesOrderRate As [Amount]
from #PendingSalesBill as B
Where B.SalesOrderQTY > B.BillQTY  And
(@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '''' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND B.StockItemName = B.StockItemName))
Order by B.TransDate Desc, B.ChallanBillNo, B.StockGroup, B.StockItemName', N'IF OBJECT_ID(''tempdb..#tmpStockGroupName'') IS NOT NULL DROP TABLE #tmpStockGroupName
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
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.id AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And Si.CompanyID=VH.CompanyID
		--INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyId AND VH.VoucherID = BL.VoucherID 
		WHERE  (VH.VoucherTypeName LIKE ''%Sales Order%'') And VH.CompanyId=@CompanyID And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS SALESORDER  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE ''%SALES'') And VH.CompanyId=@CompanyID

	) AS SALES 
   ON SALESORDER.OrderNo = SALES.OrderNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], '''' as [HQ],
(B.SalesOrderQTY - B.BillQTY) as [QTY], B.SalesOrderRate as [Rate], (B.SalesOrderQTY - B.BillQTY) * B.SalesOrderRate As [Amount]
from #PendingSalesBill as B
Where B.SalesOrderQTY > B.BillQTY  And
(@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '''' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND B.StockItemName = B.StockItemName))
Order by B.TransDate Desc, B.ChallanBillNo, B.StockGroup, B.StockItemName', N'----- Pending Sales Bill----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockGroupName_List as Varchar(500)='''', @StockItemName_List as Varchar(500)='''',
		@DepotName_List as Varchar(500)='''', @HQName_List as Varchar(500)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''10/30/2021''

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
		IL.ActualUOM	, IL.ActualQuantity, IL.Rate, (IL.ActualQuantity *  IL.Rate) as [Amount]					
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.id AND IL.VoucherID = AL.VoucherID AND VH.Id = AL.VoucherID
		Inner Join TD_Mst_StockItem as SI ON SI.StockItemName=IL.StockItemName And Si.CompanyID=VH.CompanyID
		--INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyId AND VH.VoucherID = BL.VoucherID 
		WHERE  (VH.VoucherTypeName LIKE ''%Sales Order%'') And VH.CompanyId=@CompanyID And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	) AS SALESORDER  
	LEFT OUTER JOIN	
	(
		SELECT VH.CompanyID, VH.Date, VH.VoucherTypeName, VH.VoucherNo, VH.Reference, VH.PartyName, IL.Rate, IL.StockItemName, IL.RateUOM, IL.Amount, IL.ActualQuantity, IL.ActualUOM, VH.OrderNo
		FROM  TD_Txn_VchHdr as VH
		INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
		INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND IL.AccLineId = AL.Id AND IL.VoucherID = AL.VoucherID AND VH.ID = AL.VoucherID
		WHERE  (VH.VoucherTypeName LIKE ''%SALES'') And VH.CompanyId=@CompanyID

	) AS SALES 
   ON SALESORDER.OrderNo = SALES.OrderNo AND SALESORDER.StockItemName = SALES.StockItemName --AND SALESORDER.ActualQuantity = SALES.ActualQuantity 


Select Distinct B.TransDate, B.ChallanBillNo as [TrackingName], B.StockGroup as [StockGroup], B.StockItemName as [StockItemName], B.GodownName as [DepotName], '''' as [HQ],
(B.SalesOrderQTY - B.BillQTY) as [QTY], B.SalesOrderRate as [Rate], (B.SalesOrderQTY - B.BillQTY) * B.SalesOrderRate As [Amount]
from #PendingSalesBill as B
Where B.SalesOrderQTY > B.BillQTY  And
(@StockGroupName_List  <> '''' AND B.StockGroup IN (SELECT StockGroupName FROM #tmpStockGroupName)  OR (@StockGroupName_List = ''''  AND B.StockGroup = B.StockGroup))
And   (@StockItemName_List  <> '''' AND B.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND B.StockItemName = B.StockItemName))
Order by B.TransDate Desc, B.ChallanBillNo, B.StockGroup, B.StockItemName', NULL, 1, N'Dev')
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
	From TD_Stock as SD
	Inner Join TD_Mst_StockItem as ST ON ST.StockItemName=SD.StockItemName And ST.CompanyID=SD.CompanyID
	Where SD.CompanyID=@CompanyID And  StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@StockCategoryName_List  <> '''' AND ST.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND ST.StockCategory = ST.StockCategory))
	Group by StockDate,ST.StockCategory,  SD.StockItemName

	--select * from #tmpOPBalance

--------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [InWard_QTY]
	Into #TempInwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineId and IL.Id=BL.InvLineId 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.ID
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
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineid and IL.Id=BL.InvLineid 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.ID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where (VT.VoucherType IN(''Sales'',''Credit Note''))
	And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo  And IL.CompanyId= @CompanyID
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
SET @DateFrom =''01-04-2020''
SET @DateTo = ''05-04-2020''

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
	From TD_Stock as SD
	Inner Join TD_Mst_StockItem as ST ON ST.StockItemName=SD.StockItemName And ST.CompanyID=SD.CompanyID
	Where SD.CompanyID=@CompanyID And  StockDate>= @DateFrom And StockDate<= @DateTo 
	And (@StockItemName_List  <> '''' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND SD.StockItemName = SD.StockItemName))
	And (@StockCategoryName_List  <> '''' AND ST.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''''  AND ST.StockCategory = ST.StockCategory))
	Group by StockDate,ST.StockCategory,  SD.StockItemName

	--select * from #tmpOPBalance

--------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [InWard_QTY]
	Into #TempInwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineId and IL.Id=BL.InvLineId 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.ID
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
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineId=BL.AccLineid and IL.Id=BL.InvLineid 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.ID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where (VT.VoucherType IN(''Sales'',''Credit Note''))
	And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo  And IL.CompanyId= @CompanyID
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
	Order by S.StockItemName', NULL, 1, N'Dev')
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

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
SET @DateFrom =''01/01/2019''
SET @DateTo = ''12/30/2021''
SET @VoucherType_List = ''''
SET @PartyName_List = ''''
SET @StockItemName_List = ''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
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

--TD_Txn_AccLine', N'IF OBJECT_ID(''tempdb..#tmpVoucherType'') IS NOT NULL DROP TABLE #tmpVoucherType
IF OBJECT_ID(''tempdb..#tmpPartyName'') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName

Declare @CompanyID as uniqueidentifier
Select @CompanyID= c.ID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames

SELECT NAME AS ''VoucherType'' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''''))
SELECT NAME AS ''PartyName'' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName, IL.StockItemName, IL.ActualQuantity,   IL.Rate, IL.RateUOM, IL.Amount,
AL.LedgerName as [GST], AL.Amount as [GSTAmount], IL.Amount + 0 as [TotalAmount] , VH.Narration , al.VoucherID
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
FULL OUTER JOIN TD_Txn_AccLine as AL ON /*IL.AccLineNo = AL.AccLineNo AND */ VH.CompanyID = AL.CompanyID AND IL.VoucherID = AL.VoucherID And  (AL.LedgerName like ''CGST%'' OR AL.LedgerName like ''SGST%'' OR AL.LedgerName like ''IGST%'')
Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyID
where (VT.VoucherTypeParent=''Credit Note'' Or VT.VoucherTypeParent=''Debit Note'')
--(VH.VoucherTypeName like ''%Debit Note%'' or VoucherTypeName like ''%credit%'')
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo And VH.CompanyId=@CompanyID
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
	And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And   (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName = VH.VoucherTypeName))
Order by VH.Date, VH.PartyLedgerName, IL.StockItemName Desc', N'----- Debit and Credit Note Register ----
DECLARE @CompanyNames as Varchar(2000)='''',   @DateFrom datetime= Null,  @DateTo datetime=Null, @VoucherType_List as Varchar(500)='''',  @PartyName_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)''
SET @DateFrom =''01/01/2021''
SET @DateTo = ''12/30/2021''
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

SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName, IL.StockItemName, IL.ActualQuantity,   IL.Rate, IL.RateUOM, IL.Amount,
AL.LedgerName as [GST], AL.Amount as [GSTAmount], IL.Amount + 0 as [TotalAmount] , VH.Narration , al.VoucherID
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.ID = IL.VoucherID 
FULL OUTER JOIN TD_Txn_AccLine as AL ON /*IL.AccLineNo = AL.AccLineNo AND */ VH.CompanyID = AL.CompanyID AND IL.VoucherID = AL.VoucherID And  (AL.LedgerName like ''CGST%'' OR AL.LedgerName like ''SGST%'' OR AL.LedgerName like ''IGST%'')
Inner Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=vh.VoucherTypeName And VT.CompanyID=vh.CompanyID
where (VT.VoucherTypeParent=''Credit Note'' Or VT.VoucherTypeParent=''Debit Note'')
--(VH.VoucherTypeName like ''%Debit Note%'' or VoucherTypeName like ''%credit%'')
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo And VH.CompanyId=@CompanyID
	And (@PartyName_List  <> '''' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
	And   (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName))
	And   (@VoucherType_List  <> '''' AND VH.VoucherTypeName IN (SELECT VoucherType FROM #tmpVoucherType)  OR (@VoucherType_List = ''''  AND VH.VoucherTypeName = VH.VoucherTypeName))
Order by VH.Date, VH.PartyLedgerName, IL.StockItemName Desc', NULL, 1, N'Dev')
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
Order by VH.Date, VH.PartyLedgerName, VH.CostCentreName Desc', NULL, NULL, NULL, 1, N'Pending')
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
Order by SD.StockDate, SD.StockItemName Desc', NULL, 1, N'Dev')
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
order by VH.Date desc', NULL, 3, N'Pending')
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
', NULL, NULL, NULL, 3, N'Pending')
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
WHERE  CashTxns.LedgerName <> AL.LedgerName  AND C.CompanyID =@CompanyID', NULL, NULL, NULL, 3, N'Pending')
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
', NULL, NULL, NULL, 3, N'Pending')
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
', NULL, 3, N'Dev')
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
', NULL, 3, N'Dev')
SET IDENTITY_INSERT [dbo].[RDLCReportQuery] OFF
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_IsReleasedInLive]  DEFAULT ((0)) FOR [IsReleasedInLive]
GO
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_ViewOrder]  DEFAULT ((0)) FOR [ViewOrder]
GO
