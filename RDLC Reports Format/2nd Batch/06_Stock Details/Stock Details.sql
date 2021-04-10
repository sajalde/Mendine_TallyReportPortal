------- Stock Details----
DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockCategoryName_List as Varchar(500)='', @StockItemName_List as Varchar(500)='',
		@VoucherType_List as Varchar(500)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
SET @DateFrom ='01/01/2021'
SET @DateTo = '10/30/2021'

SET @StockCategoryName_List = ''
SET @StockItemName_List = ''
SET @VoucherType_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpStockCategoryName') IS NOT NULL DROP TABLE #tmpStockCategoryName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID('tempdb..#tmpVoucherType') IS NOT NULL DROP TABLE #tmpVoucherType

IF OBJECT_ID('tempdb..#tmpOPBalance') IS NOT NULL DROP TABLE #tmpOPBalance
IF OBJECT_ID('tempdb..#StockDetails') IS NOT NULL DROP TABLE #StockDetails
IF OBJECT_ID('tempdb..#TempInwardStock') IS NOT NULL DROP TABLE #TempInwardStock
IF OBJECT_ID('tempdb..#TempOutwardStock') IS NOT NULL DROP TABLE #TempOutwardStock

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'StockCategoryName' INTO #tmpStockCategoryName from dbo.GetTableFromString(isnull(@StockCategoryName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))
SELECT NAME AS 'VoucherType' INTO #tmpVoucherType from dbo.GetTableFromString(isnull(@VoucherType_List,''))

BEGIN
CREATE TABLE #StockDetails(
	[TransDate] datetime NOT NULL,
	[StockCategory] [varchar](300) NULL,
	[StockItemName] [varchar](300)  NULL,     
	[VoucherName] [varchar](300) NULL, 
	[QTY_Opening] [decimal](18, 4) NULL,
	[QTY_InWard] [decimal](18, 4) NULL,
	[QTY_OutWard] [decimal](18, 4) NULL,
	[QTY_Closing] [decimal](18, 4) NULL,
) 

--Select * From #StockDetails

END
	Declare @ShowStockDate as Datetime
	Select  distinct top(1) @ShowStockDate=stockdate 	From TD_Txn_StockDetails  
	Where (@CompanyNames  <> '' AND CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND CompanyID = CompanyID)) And StockDate>=@DateFrom 	order by stockdate Desc
	Print @ShowStockDate

	-- Fetch the Opening Balance from Stock Details and Save to Temp Table ----
	Select  SD.StockItemName,  Sum(Quantity) as [OpeningStock_QTY]
	Into #tmpOPBalance
	From TD_Txn_StockDetails as SD
	Left outer Join TD_Mst_StockItem as ST ON ST.StockItemName=SD.StockItemName And ST.CompanyID=SD.CompanyID
	Where StockDate= @ShowStockDate 
	And (@CompanyNames  <> '' AND SD.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND SD.CompanyID = SD.CompanyID))	
	And (@StockItemName_List  <> '' AND SD.StockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND SD.StockItemName = SD.StockItemName))
	Group by SD.StockItemName, ST.StockCategory

--------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [EntryDate], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [InWard_QTY]
	Into #TempInwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineNo=BL.AccLineNo and IL.InvLineNo=BL.InvLineNo 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.VoucherID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where (VT.VoucherType IN('Purchase','Debit Note','Material In')) And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo 
	And (@CompanyNames  <> '' AND IL.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND IL.CompanyID = IL.CompanyID))
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
	Where (VT.VoucherType IN('Sales','Credit Note'))
	And  il.EntryDate>= @DateFrom AND il.EntryDate <= @DateTo 
	And (@CompanyNames  <> '' AND IL.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND IL.CompanyID = IL.CompanyID))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

	------------------------------------------------------------------------------

	select I.EntryDate as [TransDate], S.StockCategory as [StockCategory],  S.StockItemName as [StockItemName], i.VoucherType as [VoucherName], 
	IsNull(Op.OpeningStock_QTY,0) as [QTY_Opening], IsNull(I.InWard_QTY,0) as [QTY_InWard],   IsNull(O.OutWard_QTY,0) as [QTY_OutWard], 
	((IsNull(Op.OpeningStock_QTY,0) + IsNull(I.InWard_QTY,0)) - IsNull(O.OutWard_QTY,0)) as [QTY_Closing]
	from TD_Mst_StockItem as S
	Left Outer Join #tmpOPBalance as Op ON Op.StockItemName=S.StockItemName
	Left Outer Join #TempInwardStock as I ON I.StockItemName=S.StockItemName
	Left Outer Join #TempOutwardStock as O ON O.StockItemName=S.StockItemName
	Where 
	 (@StockCategoryName_List  <> '' AND S.StockCategory IN (SELECT StockCategoryName FROM #tmpStockCategoryName)  OR (@StockCategoryName_List = ''  AND S.StockCategory = S.StockCategory))
	--(@CompanyNames  <> '' AND S.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND S.CompanyID = S.CompanyID))
	--And (@GodwnName_List  <> '' AND OP.GodownName IN (SELECT GodwnName FROM #tmpGodwnName)  OR (@GodwnName_List = ''  AND OP.GodownName = OP.GodownName))
	--Group by S.StockCategory, S.StockItemName
	Order by S.StockItemName


