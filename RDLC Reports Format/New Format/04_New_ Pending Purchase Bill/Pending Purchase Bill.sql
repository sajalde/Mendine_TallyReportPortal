------- Pending Purchase Bill----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @PartyName_List as Varchar(250)='', @StockGroupName_List as Varchar(250)='', 
--		@StockItemName_List as Varchar(250)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='01/01/2020'
--SET @DateTo = '10/30/2020'
--SET @PartyName_List = ''
--SET @StockGroupName_List = ''
--SET @StockItemName_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpStockGroupName') IS NOT NULL DROP TABLE #tmpStockGroupName
IF OBJECT_ID('tempdb..#tmpStockItemName') IS NOT NULL DROP TABLE #tmpStockItemName

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'PartyName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'StockGroupName' INTO #tmpStockGroupName from dbo.GetTableFromString(isnull(@StockGroupName_List,''))
SELECT NAME AS 'StockItemName' INTO #tmpStockItemName from dbo.GetTableFromString(isnull(@StockItemName_List,''))

--select * from View_Report_LeadTime as LT
--where  (@CompanyNames  <> '' AND LT.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND LT.CompanyID = LT.CompanyID))
--	And (@PartyName_List  <> '' AND LT.popartyname IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND LT.popartyname =LT.popartyname))
--	And (@StockItemName_List  <> '' AND LT.POStockItemName IN (SELECT StockItemName FROM #tmpStockItemName)  OR (@StockItemName_List = ''  AND LT.POStockItemName =LT.POStockItemName ))
--Order by podate, popartyname, POStockItemName

SELECT GRN.Date AS [TransDate], GRN.Reference AS [ChallanBillNo], GRN.PartyName AS [VendorName],  GRN.StockItemName AS [StockItemName], '' as [StockGroup], GRN.ActualQuantity AS [QTY], 
                  GRN.Rate AS [Rate],  GRN.Amount AS [Amount] 
FROM     (SELECT dbo.TD_Txn_VchHdr.CompanyID, dbo.TD_Txn_VchHdr.Date, dbo.TD_Txn_VchHdr.VoucherTypeName, dbo.TD_Txn_VchHdr.VoucherNo, dbo.TD_Txn_VchHdr.Reference, dbo.TD_Txn_VchHdr.PartyName, dbo.TD_Txn_InvLine.Rate, 
                                    dbo.TD_Txn_InvLine.StockItemName, dbo.TD_Txn_InvLine.RateUOM, dbo.TD_Txn_InvLine.Amount, dbo.TD_Txn_InvLine.ActualQuantity, dbo.TD_Txn_InvLine.ActualUOM
                  FROM      dbo.TD_Txn_VchHdr INNER JOIN
                                    dbo.TD_Txn_InvLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_InvLine.CompanyId AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_InvLine.VoucherID INNER JOIN
                                    dbo.TD_Txn_AccLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_InvLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo AND 
                                    dbo.TD_Txn_InvLine.VoucherID = dbo.TD_Txn_AccLine.VoucherID AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_AccLine.VoucherID
                  WHERE   (dbo.TD_Txn_VchHdr.CompanyID = 2) AND (dbo.TD_Txn_VchHdr.VoucherTypeName LIKE 'Purchase Order for Factory') OR
                                    (dbo.TD_Txn_VchHdr.CompanyID = 2) AND (dbo.TD_Txn_VchHdr.VoucherTypeName LIKE 'Purchase Order for Central Hub')) AS PO LEFT OUTER JOIN
                      (SELECT dbo.TD_Txn_VchHdr.CompanyID, dbo.TD_Txn_VchHdr.Date, dbo.TD_Txn_VchHdr.VoucherTypeName, dbo.TD_Txn_VchHdr.VoucherNo, dbo.TD_Txn_VchHdr.Reference, dbo.TD_Txn_VchHdr.PartyName, 
                                         dbo.TD_Txn_InvLine.Rate, dbo.TD_Txn_InvLine.StockItemName, dbo.TD_Txn_InvLine.RateUOM, dbo.TD_Txn_InvLine.Amount, dbo.TD_Txn_InvLine.ActualQuantity, dbo.TD_Txn_InvLine.ActualUOM, dbo.TD_Txn_VchHdr.OrderNo, 
                                         dbo.TD_Txn_VchHdr.OrderDate
                       FROM      dbo.TD_Txn_VchHdr INNER JOIN
                                         dbo.TD_Txn_InvLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_InvLine.CompanyId AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_InvLine.VoucherID INNER JOIN
                                         dbo.TD_Txn_AccLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_InvLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo AND 
                                         dbo.TD_Txn_InvLine.VoucherID = dbo.TD_Txn_AccLine.VoucherID AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_AccLine.VoucherID
                       WHERE   (dbo.TD_Txn_VchHdr.CompanyID = 2) AND (dbo.TD_Txn_VchHdr.VoucherTypeName LIKE 'GRN%')) AS GRN ON PO.Reference = GRN.OrderNo AND PO.StockItemName = GRN.StockItemName LEFT OUTER JOIN
                      (SELECT dbo.TD_Txn_VchHdr.CompanyID, dbo.TD_Txn_VchHdr.Date, dbo.TD_Txn_VchHdr.VoucherTypeName, dbo.TD_Txn_VchHdr.VoucherNo, dbo.TD_Txn_VchHdr.Reference, dbo.TD_Txn_VchHdr.PartyName, 
                                         dbo.TD_Txn_InvLine.Rate, dbo.TD_Txn_InvLine.StockItemName, dbo.TD_Txn_InvLine.RateUOM, dbo.TD_Txn_InvLine.Amount, dbo.TD_Txn_InvLine.ActualQuantity, dbo.TD_Txn_InvLine.ActualUOM, 
                                         dbo.TD_Txn_VchHdr.OrderNo
                       FROM      dbo.TD_Txn_VchHdr INNER JOIN
                                         dbo.TD_Txn_InvLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_InvLine.CompanyId AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_InvLine.VoucherID INNER JOIN
                                         dbo.TD_Txn_AccLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_InvLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo AND 
                                         dbo.TD_Txn_InvLine.VoucherID = dbo.TD_Txn_AccLine.VoucherID AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_AccLine.VoucherID
                       WHERE   (dbo.TD_Txn_VchHdr.CompanyID = 2) AND (dbo.TD_Txn_VchHdr.VoucherTypeName LIKE 'PURCHASE FOR%')) AS PURCHASE ON GRN.OrderNo = PURCHASE.OrderNo AND 
                  GRN.StockItemName = PURCHASE.StockItemName AND GRN.ActualQuantity = PURCHASE.ActualQuantity LEFT OUTER JOIN
                      (SELECT dbo.TD_Txn_AccLine.LedgerName, dbo.TD_Txn_AccLine.Amount, dbo.TD_Txn_BillLine.BillType, dbo.TD_Txn_BillLine.BillName, dbo.TD_Txn_BillLine.Amount AS Expr1, dbo.TD_Txn_BillLine.Date, 
                                         dbo.TD_Txn_AccLine.CompanyID
                       FROM      dbo.TD_Txn_BillLine INNER JOIN
                                         dbo.TD_Txn_AccLine ON dbo.TD_Txn_BillLine.Companyid = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_BillLine.VoucherId = dbo.TD_Txn_AccLine.VoucherID AND 
                                         dbo.TD_Txn_BillLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo
                       WHERE   (dbo.TD_Txn_BillLine.BillType LIKE 'Agst Ref') AND (dbo.TD_Txn_AccLine.CompanyID = 2)) AS payment ON PURCHASE.Reference = payment.BillName