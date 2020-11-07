DECLARE @CompanyID int
DECLARE @DateTo datetime
SET @CompanyID = 2
SET @DateTo = '2020-10-30'

IF OBJECT_ID('tempdb..#OrderDetails') IS NOT NULL
DROP TABLE #OrderDetails;
IF OBJECT_ID('tempdb..#Purchase') IS NOT NULL
DROP TABLE #Purchase;
IF OBJECT_ID('tempdb..#PurchaseSummary') IS NOT NULL
DROP TABLE #PurchaseSummary;
IF OBJECT_ID('tempdb..#GSTDetails') IS NOT NULL
   DROP TABLE #GSTDetails;
IF OBJECT_ID('tempdb..#POOutstanding') IS NOT NULL
   DROP TABLE #POOutstanding;
   
IF OBJECT_ID('tempdb..#ItemMaster') IS NOT NULL
	DROP TABLE #ItemMaster;
	
IF OBJECT_ID('tempdb..#PartyMaster') IS NOT NULL
	DROP TABLE #PartyMaster;
IF OBJECT_ID('tempdb..#Final') IS NOT NULL
	DROP TABLE #Final;

SELECT    
	TD_Mst_Company.CompanyID, 	TD_Mst_Company.CompanyName,	TD_Mst_Ledger.StateName,	TD_Txn_InvLine.StockItemName,	TD_Mst_VoucherType.VoucherType,	TD_Txn_VchHdr.VoucherTypeName,	TD_Txn_VchHdr.VoucherNo AS PurchaseOrderNo,
	TD_Txn_VchHdr.OrderNo,	TD_Txn_VchHdr.Reference,	TD_Txn_VchHdr.PartyLedgerName,	TD_Txn_BatchLine.GodownName,	TD_Txn_VchHdr.Date, 	TD_Txn_VchHdr.Narration,	TD_Txn_VchHdr.PartyName,	TD_Txn_BatchLine.BatchName,
	TD_Txn_BatchLine.ActualUOM,	TD_Txn_AccLine.LedgerName, 	TD_Mst_StockItem.StockGroup,	TD_Mst_StockItem.PartNo,	TD_Mst_StockItem.ItemDescription,	TD_Mst_StockItem.ItemRemarks,	TD_Mst_StockItem.StockCategory,
	OrderValue = Sum(CASE
		  WHEN TD_Txn_BatchLine.Amount IS NULL THEN TD_Txn_AccLine.Amount*-1
		  ELSE TD_Txn_BatchLine.Amount*-1
	END),

	CASE
		 WHEN ((dbo.ReturnDueDate(OrderDueDate,Date))) = '01-Jan-1900' THEN NULL
		 ELSE ((dbo.ReturnDueDate(OrderDueDate,Date)))
	END As OrderDueDate,

	SUM(TD_Txn_BatchLine.ActualQty) As OrderQty, SUM(ISNULL(CONVERT(FLOAT,SUBSTRING(LTRIM(TD_Txn_BatchLine.PreClosedQty),0,CHARINDEX(' ',LTRIM(TD_Txn_BatchLine.PreClosedQty)))),0))  AS PreClosedQty,
	TD_Txn_BatchLine.PreCloseDate, TD_Txn_BatchLine.PreCloseReason
INTO #OrderDetails
FROM   TD_Txn_BatchLine 
INNER JOIN TD_Txn_InvLine ON TD_Txn_BatchLine.CompanyID = TD_Txn_InvLine.CompanyId AND TD_Txn_BatchLine.VoucherId = TD_Txn_InvLine.VoucherID AND
		TD_Txn_BatchLine.AccLineNo = TD_Txn_InvLine.AccLineNo AND TD_Txn_BatchLine.InvLineNo = TD_Txn_InvLine.InvLineNo 
LEFT OUTER JOIN TD_Mst_StockItem ON TD_Txn_InvLine.CompanyId = TD_Mst_StockItem.CompanyID AND TD_Txn_InvLine.StockItemName = TD_Mst_StockItem.StockItemName 
RIGHT OUTER JOIN TD_Mst_Ledger 
INNER JOIN TD_Mst_Company 
INNER JOIN TD_Mst_VoucherType ON TD_Mst_Company.CompanyID = TD_Mst_VoucherType.CompanyID 
INNER JOIN TD_Txn_VchHdr ON TD_Mst_VoucherType.CompanyID = TD_Txn_VchHdr.CompanyID AND TD_Mst_VoucherType.VoucherTypeName = TD_Txn_VchHdr.VoucherTypeName 
INNER JOIN TD_Txn_AccLine ON TD_Txn_VchHdr.CompanyID = TD_Txn_AccLine.CompanyID AND TD_Txn_VchHdr.VoucherID = TD_Txn_AccLine.VoucherID ON TD_Mst_Ledger.LedgerName = TD_Txn_VchHdr.PartyLedgerName 
		AND TD_Mst_Ledger.CompanyID = TD_Txn_VchHdr.CompanyID ON TD_Txn_InvLine.CompanyId = TD_Txn_AccLine.CompanyID AND TD_Txn_InvLine.VoucherID = TD_Txn_AccLine.VoucherID AND
		TD_Txn_InvLine.AccLineNo = TD_Txn_AccLine.AccLineNo
WHERE    
	(TD_Mst_VoucherType.VoucherType ='Purchase Order') AND (TD_Txn_VchHdr.IsOptional <> 1 AND TD_Txn_VchHdr.IsCancelled <> 1 AND TD_Txn_VchHdr.IsDeleted <> 1)
	AND TD_Txn_AccLine.IsPartyLedger = 0 AND TD_Mst_VoucherType.CompanyID IN (@CompanyID) AND ISNULL(dbo.ReturnDueDate(OrderDueDate,Date),'01-Jan-1900') <= @DateTo
	AND TD_Txn_VchHdr.Date >'2018-03-31' AND TD_Txn_BatchLine.ActualQty IS NOT NULL
GROUP BY
	TD_Mst_Company.CompanyID, TD_Mst_Company.CompanyName,TD_Mst_Ledger.StateName,TD_Txn_InvLine.StockItemName,TD_Mst_VoucherType.VoucherType,TD_Txn_VchHdr.VoucherTypeName,TD_Txn_VchHdr.VoucherNo,
	TD_Txn_VchHdr.Reference, TD_Txn_VchHdr.PartyLedgerName,TD_Txn_BatchLine.GodownName,TD_Txn_VchHdr.Date,TD_Txn_VchHdr.Narration,TD_Txn_VchHdr.PartyName,TD_Txn_VchHdr.VoucherClassName,TD_Mst_VoucherType.VoucherTypeAlias,
	TD_Txn_BatchLine.BatchName,TD_Txn_BatchLine.ActualUOM,TD_Txn_AccLine.LineNarration,TD_Txn_AccLine.LedgerName,  TD_Mst_StockItem.StockGroup,TD_Mst_StockItem.StockItemAlias,TD_Mst_StockItem.PartNo,TD_Mst_StockItem.ItemDescription,
	TD_Mst_StockItem.ItemRemarks, TD_Mst_StockItem.StockCategory,OrderDueDate,TD_Txn_VchHdr.OrderNo,TD_Txn_BatchLine.PreCloseDate,TD_Txn_BatchLine.PreCloseReason

--Select * from #OrderDetails



SELECT TD_Txn_InvLine.CompanyId,TD_Txn_InvLine.StockItemName,TD_Txn_BatchLine.OrderNo,ISNULL(dbo.ReturnDueDate(OrderDueDate,Date),'01-Jan-1900') As OrderDueDate,
SUM(TD_Txn_BatchLine.ActualQty) As InvoiceQty, SUM(TD_Txn_BatchLine.Amount*-1) AS InvoiceAmount 
INTO #Purchase 
FROM  TD_Mst_VoucherType
INNER JOIN TD_Txn_VchHdr ON TD_Mst_VoucherType.CompanyID = TD_Txn_VchHdr.CompanyID AND TD_Mst_VoucherType.VoucherTypeName = TD_Txn_VchHdr.VoucherTypeName
INNER JOIN TD_Txn_InvLine ON TD_Txn_InvLine.CompanyId = TD_Txn_VchHdr.CompanyID AND TD_Txn_InvLine.VoucherID = TD_Txn_VchHdr.VoucherID
INNER JOIN TD_Txn_BatchLine ON TD_Txn_BatchLine.CompanyID = TD_Txn_InvLine.CompanyId AND TD_Txn_BatchLine.VoucherId = TD_Txn_InvLine.VoucherID 
		AND TD_Txn_BatchLine.AccLineNo = TD_Txn_InvLine.AccLineNo AND TD_Txn_BatchLine.InvLineNo = TD_Txn_InvLine.InvLineNo 
WHERE    
(TD_Mst_VoucherType.VoucherType ='Purchase') AND (TD_Txn_VchHdr.IsOptional <> 1 AND TD_Txn_VchHdr.IsCancelled <> 1 AND TD_Txn_VchHdr.IsDeleted <> 1)
AND TD_Mst_VoucherType.CompanyID IN (@CompanyID) AND TD_Txn_VchHdr.Date<=@DateTo AND TD_Txn_VchHdr.Date>'2018-03-31' 
GROUP BY TD_Txn_InvLine.CompanyId, TD_Txn_InvLine.StockItemName, TD_Txn_BatchLine.OrderNo, TD_Txn_BatchLine.OrderDueDate, TD_Txn_VchHdr.Date
 
 
 SELECT CompanyID,StockItemName,OrderNo,SUM(InvoiceQty) AS InvoiceQty,SUM(InvoiceAmount) AS InvoiceAmount
 INTO #PurchaseSummary
  FROM #Purchase
  GROUP BY 
CompanyID,StockItemName,OrderNo

SELECT CompanyID,StockItemName,MAX(ApplicableFromDate) AS ApplicableFrom,CalculationType,HSNCode,Taxability,CGST,SGST,IGST
INTO #GSTDetails
FROM TD_Mst_StockItem_GST
WHERE CompanyID IN(@CompanyID)
GROUP BY
CompanyID,StockItemName,CalculationType,HSNCOde,Taxability,CGST,SGST,IGST

SELECT 
#OrderDetails.*,
ISNULL(#PurchaseSummary.InvoiceQty,0) AS ClearedQty,
ISNULL(#PurchaseSummary.InvoiceAmount,0) AS ClearedValue,
cast(#OrderDetails.OrderQty-PreClosedQty-ISNULL(#PurchaseSummary.InvoiceQty,0) AS Decimal(18,2)) AS PendingQty,
CAST(#OrderDetails.OrderValue*((#OrderDetails.OrderQty-PreClosedQty-ISNULL(#PurchaseSummary.InvoiceQty,0))/#OrderDetails.OrderQty) AS Decimal(18,2)) AS PendingValue,
DATEDIFF(Day,#OrderDetails.OrderDueDate,@DateTo) AS OverDueDays,
TD_Mst_Ledger.LD_UDF1 [Zone],
TD_Mst_Ledger.LD_UDF2 [Salesperson],
TD_Mst_Ledger.LD_UDF3 [Team],
TD_Mst_Ledger.LD_UDF4 [Location], 
CASE WHEN TD_Mst_Ledger.LD_UDF5 IN ('Yes','YES') THEN TD_Mst_Ledger.LD_UDF5
     ELSE 'No' END AS [Active],
#PurchaseSummary.OrderNo AS PurchaseVoucherOrderNo,
TD_Mst_StockItem.SI_UDF1 AS StockLevel,
TD_Mst_StockItem.SI_UDF2 AS Supplier,
CASE WHEN TD_Mst_StockItem.SI_UDF3 IN ('Yes','YES') THEN TD_Mst_StockItem.SI_UDF3 
     ELSE 'No' END AS Inactive,
TD_Mst_StockItem.SI_UDF4 AS SupplierLeadTime,
CAST(NULL AS DateTime) AS ApplicableFrom,
CAST('' AS Nvarchar(50)) AS CalculationType,
CAST(0 AS nvarchar(15)) AS HSNCode,
CAST('' AS Nvarchar(20)) AS Taxability,
CAST(0.0 AS Decimal(18,2)) AS CGST,
CAST(0.0 AS Decimal(18,2)) AS SGST,
CAST(0.0 AS Decimal(18,2)) AS IGST
INTO #POOutstanding
FROM #OrderDetails 
      LEFT JOIN #PurchaseSummary 
           ON #OrderDetails.CompanyID=#PurchaseSummary.CompanyID
               AND #OrderDetails.StockItemName=#PurchaseSummary.StockItemName
               AND #OrderDetails.Reference=#PurchaseSummary.OrderNo
               --AND #OrderDetails.OrderDueDate=#PurchaseSummary.OrderDueDate
      LEFT JOIN TD_Mst_Ledger 
           ON #OrderDetails.CompanyID=TD_Mst_Ledger.CompanyID
              AND #OrderDetails.PartyLedgerName=TD_Mst_Ledger.LedgerName 
      LEFT JOIN TD_Mst_StockItem 
	      ON #OrderDetails.CompanyID=TD_Mst_StockItem.CompanyID
		     AND #OrderDetails.StockItemName=TD_Mst_StockItem.StockItemName
WHERE #OrderDetails.OrderQty-PreClosedQty-ISNULL(#PurchaseSummary.InvoiceQty,0)>0

UPDATE #POOutstanding
SET ApplicableFrom=(SELECT TOP 1 ApplicableFrom FROM #GSTDetails
                     WHERE #GSTDetails.CompanyId=#POOutstanding.CompanyID AND #GSTDetails.StockItemName=#POOutstanding.StockItemName AND #GSTDetails.ApplicableFrom<=#POOutstanding.Date
					  ORDER BY ApplicableFrom DESC)

UPDATE #POOutstanding
SET CalculationType=(SELECT TOP 1 CalculationType FROM  #GSTDetails
                     WHERE #GSTDetails.CompanyId=#POOutstanding.CompanyID AND #GSTDetails.StockItemName=#POOutstanding.StockItemName AND #GSTDetails.ApplicableFrom<=#POOutstanding.Date
					  ORDER BY ApplicableFrom DESC)

UPDATE #POOutstanding
SET HSNCode=(SELECT TOP 1 HSNCode FROM  #GSTDetails
                     WHERE #GSTDetails.CompanyId=#POOutstanding.CompanyID AND #GSTDetails.StockItemName=#POOutstanding.StockItemName AND #GSTDetails.ApplicableFrom<=#POOutstanding.Date
					  ORDER BY ApplicableFrom DESC)
UPDATE #POOutstanding
SET Taxability=(SELECT TOP 1 Taxability FROM  #GSTDetails
                     WHERE #GSTDetails.CompanyId=#POOutstanding.CompanyID AND #GSTDetails.StockItemName=#POOutstanding.StockItemName AND #GSTDetails.ApplicableFrom<=#POOutstanding.Date
					  ORDER BY ApplicableFrom DESC)

UPDATE #POOutstanding
SET CGST=(SELECT TOP 1 CGST FROM  #GSTDetails
                     WHERE #GSTDetails.CompanyId=#POOutstanding.CompanyID AND #GSTDetails.StockItemName=#POOutstanding.StockItemName AND #GSTDetails.ApplicableFrom<=#POOutstanding.Date
					  ORDER BY ApplicableFrom DESC)

UPDATE #POOutstanding
SET SGST=(SELECT TOP 1 SGST FROM  #GSTDetails
                     WHERE #GSTDetails.CompanyId=#POOutstanding.CompanyID AND #GSTDetails.StockItemName=#POOutstanding.StockItemName AND #GSTDetails.ApplicableFrom<=#POOutstanding.Date
					  ORDER BY ApplicableFrom DESC)
UPDATE #POOutstanding
SET IGST=(SELECT TOP 1 IGST FROM  #GSTDetails
                     WHERE #GSTDetails.CompanyId=#POOutstanding.CompanyID AND #GSTDetails.StockItemName=#POOutstanding.StockItemName AND #GSTDetails.ApplicableFrom<=#POOutstanding.Date

					  ORDER BY ApplicableFrom DESC)







SELECT * FROM #POOutstanding 
