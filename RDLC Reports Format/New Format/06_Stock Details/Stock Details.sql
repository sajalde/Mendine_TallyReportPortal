--------- Stock Details----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @StockCategoryName_List as Varchar(500)='', @StockItemName_List as Varchar(500)='',
--		@VoucherType_List as Varchar(500)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='11/01/2020'
--SET @DateTo = '11/30/2020'

--SET @StockCategoryName_List = ''
--SET @StockItemName_List = ''
--SET @VoucherType_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpStockCategoryName') IS NOT NULL DROP TABLE #tmpStockCategoryName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName
IF OBJECT_ID('tempdb..#tmpVoucherType') IS NOT NULL DROP TABLE #tmpVoucherType

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




--Select Top(10)* from TD_Txn_InvLine order by EntryDate Desc
--Select Top(10)* from TD_Txn_BatchLine where VoucherId=297666 
--Select Top(10)* from TD_Txn_VchHdr where VoucherId=297666 
--Select distinct VoucherType from TD_Mst_VoucherType where CompanyID=2
--Select * from TD_Mst_StockItem where CompanyID=2

------------------- Satocl In  Data ------------------
	Select CONVERT(date, il.EntryDate) as [Date], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [In]
	/*il.EntryDate, il.VoucherID, il.AccLineNo, il.StockItemName, il.BilledQuantity, il.BilledQuantity,
	bl.BatchName, bl.TrackingNumber, bl.ExpiryPeriod, BL.GodownName, vh.CostCentreName,
	VT.VoucherType*/
	Into #TempInwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineNo=BL.AccLineNo and IL.InvLineNo=BL.InvLineNo 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.VoucherID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where il.EntryDate>='12/01/2020' And IL.CompanyId=2  And (VT.VoucherType IN('Purchase','Debit Note','Material In'))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType

------------------- Satocl Outward Data ------------------
	Select CONVERT(date, il.EntryDate) as [Date], si.StockCategory, il.StockItemName,  vt.VoucherType, Sum(IL.BilledQuantity) as [OutWard]
	Into #TempOutwardStock
	From TD_Txn_InvLine as IL
	Left Outer Join TD_Txn_BatchLine as BL ON  il.CompanyId=bl.CompanyID And BL.VoucherId=IL.VoucherID And IL.AccLineNo=BL.AccLineNo and IL.InvLineNo=BL.InvLineNo 
	Left Outer Join TD_Txn_VchHdr as VH ON  il.CompanyId=VH.CompanyID and IL.VoucherID=vh.VoucherID
	Left Outer Join TD_Mst_VoucherType as VT ON VT.VoucherTypeName=VH.VoucherTypeName
	Left Outer Join TD_Mst_StockItem as SI ON SI.CompanyID=il.CompanyId And IL.StockItemName=SI.StockItemName
	Where il.EntryDate>='12/01/2020' And IL.CompanyId=2  And (VT.VoucherType IN('#Internal Stock Journal#'))
	Group by il.EntryDate,  il.StockItemName, si.StockCategory, vt.VoucherType
	order by CONVERT(date, il.EntryDate) , si.StockCategory, il.StockItemName,  vt.VoucherType



--Select * From  #TempInwardStock
--Select * From  #TempOutwardStock

Select Date as [TransDate], StockCategory, StockItemName, VoucherType as [VoucherName], 0 as [QTY_Opening], 0 as [QTY_InWard],  OutWard as [QTY_OutWard], 0 as [QTY_Closing]

From #TempOutwardStock