USE [EasyReports3.6]
GO
/****** Object:  Table [dbo].[RDLCReportQuery]    Script Date: 12/11/2020 6:19:45 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[RDLCReportQuery](
	[PK_ReportID] [int] IDENTITY(1,1) NOT NULL,
	[IsActive] [bit] NULL,
	[ReportName] [varchar](50) NULL,
	[Version] [int] NULL,
	[ParameterList] [varchar](500) NULL,
	[ReportSQLQuery] [nvarchar](max) NULL,
 CONSTRAINT [PK_RDLCReportQuery] PRIMARY KEY CLUSTERED 
(
	[PK_ReportID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET IDENTITY_INSERT [dbo].[RDLCReportQuery] ON 

INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsActive], [ReportName], [Version], [ParameterList], [ReportSQLQuery]) VALUES (1, 1, N'PendingPurchaseOrder', 1, NULL, N'----- Pending Purchase Order Report ------
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

')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsActive], [ReportName], [Version], [ParameterList], [ReportSQLQuery]) VALUES (2, 1, N'VendorOutstandingReport', 1, NULL, N'--- Vendor Outstanding Report ----
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
')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsActive], [ReportName], [Version], [ParameterList], [ReportSQLQuery]) VALUES (3, 1, N'GodownStockTransfer', 1, NULL, N'--- Godown Stock Transfer Report ----
--DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='''', @StockCategory_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

--Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
--SET @DateFrom =''01/01/2020''
--SET @DateTo = ''10/30/2020''
--SET @PartyName_List = ''''
--SET @StockCategory_List=''''
--SET @StockItemName_List=''''

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpStockCategory'') IS NOT NULL DROP TABLE #tmpStockCategory
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName


SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS ''StockCategory'' INTO #tmpStockCategory from	 dbo.GetTableFromString(isnull(@StockCategory_List,''''))
SELECT NAME AS ''StockItemName'' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''''))

Select Top(100) bl.EntryDate, IL.StockItemName, il.BilledQuantity, il.ActualUOM, si.StockCategory, il.Rate,  bl.Amount, vt.VoucherType
,bl.GodownName, BL.DestinationGodownName
From TD_Txn_BatchLine as BL 
INNER JOIN TD_Txn_InvLine as IL ON BL.CompanyID = IL.CompanyId AND BL.VoucherId = IL.VoucherID AND BL.AccLineNo = IL.AccLineNo AND BL.InvLineNo = IL.InvLineNo
INNER JOIN TD_Mst_StockItem as SI ON IL.CompanyId = SI.CompanyID AND IL.StockItemName = SI.StockItemName 
INNER JOIN TD_Mst_Company as MC ON MC.CompanyID=BL.CompanyID
INNER JOIN TD_Mst_VoucherType as VT ON MC.CompanyID = VT.CompanyID 
INNER JOIN TD_Txn_VchHdr as VH ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.VoucherID = AL.VoucherID and IL.CompanyId = AL.CompanyID AND IL.VoucherID = AL.VoucherID AND IL.AccLineNo = AL.AccLineNo
where (VT.VoucherType =''Stock Journal'' OR VT.VoucherType= ''#Internal Stock Journal#'')
	AND (VH.IsOptional <> 1 AND VH.IsCancelled <> 1 AND VH.IsDeleted <> 1) AND AL.IsPartyLedger = 0  And MC.CompanyID IN (2) 
	and bl.EntryDate >= @DateFrom  and bl.EntryDate <= @DateTo
	And (@CompanyNames  <> '''' AND MC.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''''  AND MC.CompanyID = MC.CompanyID))
	And (@StockCategory_List  <> '''' AND SI.StockCategory IN (SELECT StockCategory FROM #tmpStockCategory)  OR (@StockCategory_List = ''''  AND SI.StockCategory  = SI.StockCategory))
	And (@StockItemName_List  <> '''' AND IL.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''''  AND IL.StockItemName = IL.StockItemName ))

Order by bl.EntryDate Desc





	--Select top(100) * from TD_Txn_BatchLine where VoucherId=202955
	--Select top(100) * from TD_Txn_AccLine where VoucherId=202955
	--Select top(100) * from TD_Txn_VchHdr where VoucherId=202955
	--Select top(100) * from TD_Txn_AccLine where VoucherId=202955
	--Select distinct VoucherType from TD_Mst_VoucherType')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsActive], [ReportName], [Version], [ParameterList], [ReportSQLQuery]) VALUES (4, 1, N'GodownStockSummary', 1, NULL, N'----- Godown Stock Transfer Report ----
--DECLARE @CompanyNames as Varchar(2000)='''', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodwnName_List as Varchar(250)='''', @StockItemName_List as Varchar(250)=''''

--Set @CompanyNames=''Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server''
--SET @DateFrom =''01/01/2020''
--SET @DateTo = ''10/30/2020''
--SET @GodwnName_List = ''''
--SET @StockItemName_List=''''

IF OBJECT_ID(''tempdb..#Purchase'') IS NOT NULL DROP TABLE #Purchase

IF OBJECT_ID(''tempdb..#tmpCompanyName'') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID(''tempdb..#tmpCompanyID'') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID(''tempdb..#tmpGodwnName'') IS NOT NULL DROP TABLE #tmpGodwnName
IF OBJECT_ID(''tempdb..#tmpStockItemName'') IS NOT NULL DROP TABLE #tmpStockItemName


SELECT NAME AS ''CompanyName'' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
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

	INSERT INTO #Purchase
	SELECT TOP (200) GodownName, StockItemName, 0 as [OpeningQTY], 0 as [OpeningValue], Quantity as [InWard_QTY], (Rate * Amount) as [Inward_Value], Quantity as [OutWardQTY], (Rate * Amount) as [OutwardValue],
	0 as [ClosingQTY], 0 as [ClosingValue]
	FROM     TD_Txn_StockDetails Where CompanyID=2


	Select * from #Purchase')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsActive], [ReportName], [Version], [ParameterList], [ReportSQLQuery]) VALUES (5, 1, N'FinalProductStock', 1, NULL, N'----- FinalProductStock----
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

')
INSERT [dbo].[RDLCReportQuery] ([PK_ReportID], [IsActive], [ReportName], [Version], [ParameterList], [ReportSQLQuery]) VALUES (6, 1, N'LeadTimeReport', 1, NULL, N'------- Lead Time Report----
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
')
SET IDENTITY_INSERT [dbo].[RDLCReportQuery] OFF
ALTER TABLE [dbo].[RDLCReportQuery] ADD  CONSTRAINT [DF_RDLCReportQuery_IsActive]  DEFAULT ((1)) FOR [IsActive]
GO
