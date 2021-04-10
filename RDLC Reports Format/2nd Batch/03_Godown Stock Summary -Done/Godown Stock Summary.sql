--- Godown Stock Transfer Report ----
DECLARE @CompanyNames as Varchar(2000)='', @DateFrom datetime= Null,  @DateTo datetime=Null,   @GodwnName_List as Varchar(250)='', @StockItemName_List as Varchar(250)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
SET @DateFrom ='01/01/2021'
SET @DateTo = '10/30/2021'
SET @GodwnName_List = ''
SET @StockItemName_List=''

IF OBJECT_ID('tempdb..#Purchase') IS NOT NULL DROP TABLE #Purchase

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpGodwnName') IS NOT NULL DROP TABLE #tmpGodwnName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName

IF OBJECT_ID('tempdb..#tmpOPBalance') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID('tempdb..#tmpInward') IS NOT NULL DROP TABLE #tmpInward
IF OBJECT_ID('tempdb..#tmpOutward') IS NOT NULL DROP TABLE #tmpOutward


SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'GodwnName' INTO #tmpGodwnName from	 dbo.GetTableFromString(isnull(@GodwnName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))

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
	--INSERT INTO #Purchase
	--SELECT TOP (200) GodownName, StockItemName, 0 as [OpeningQTY], 0 as [OpeningValue], Quantity as [InWard_QTY], (Rate * Amount) as [Inward_Value], Quantity as [OutWardQTY], (Rate * Amount) as [OutwardValue],
	--0 as [ClosingQTY], 0 as [ClosingValue]
	--FROM     TD_Txn_StockDetails Where CompanyID=2

	--Select * from #Purchase

	Declare @ShowStockDate as Datetime

	Select  distinct top(1) @ShowStockDate=stockdate 	From TD_Txn_StockDetails  
	Where (@CompanyNames  <> '' AND CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND CompanyID = CompanyID)) And StockDate>=@DateFrom 	order by stockdate Desc
	Print @ShowStockDate

	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select GodownName, StockItemName,  Sum(Quantity) as [OpeningStock_QTY], Sum(Amount) as [OpeningStock_Value] 
	Into #tmpOPBalance
	From TD_Txn_StockDetails 
	Where StockDate= @ShowStockDate 
	And (@CompanyNames  <> '' AND CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND CompanyID = CompanyID))
	And (@GodwnName_List  <> '' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''  AND GodownName = GodownName))
	Group by StockItemName, GodownName

	--Select * from  #tmpOPBalance

	---- Fetch In ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [InWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Inward_Value]	
	Into #tmpInward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
	INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyId AND VH.VoucherID = BL.VoucherID 
	Where (VH.VoucherTypeName LIKE 'Purchase for%') And  VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))
	And (@GodwnName_List  <> '' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''  AND GodownName = GodownName))
	Group by BL.DestinationGodownName, IL.StockItemName, IL.ActualUOM	
	
	--Select * from  #tmpInward

	---- Fetch Out ward Stock -----
	SELECT BL.DestinationGodownName as [GodownName], IL.StockItemName, IL.ActualUOM	, Sum(IL.ActualQuantity) as [OutWard_QTY],  Sum(IL.ActualQuantity *  IL.Rate) as [Outward_Value]	
	Into #tmpOutward
	FROM  TD_Txn_VchHdr as VH
	INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
	INNER JOIN TD_Txn_BatchLine as BL ON VH.CompanyID = BL.CompanyId AND VH.VoucherID = BL.VoucherID 
	Where (VH.VoucherTypeName LIKE 'Sales')
	And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))
	And (@GodwnName_List  <> '' AND GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''  AND GodownName = GodownName))
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
	Where   (@CompanyNames  <> '' AND S.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND S.CompanyID = S.CompanyID))
	And (@GodwnName_List  <> '' AND OP.GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''  AND OP.GodownName = OP.GodownName))
	Group by S.StockItemName
	Order by S.StockItemName