SELECT PO.Date PODate, PO.PartyName as POPartyName, PO.Reference PORefNo, PO.StockItemName POStockItemName, PO.ActualQuantity POQTY, PO.Rate PORate, PO.RateUOM POUOM, PO.Amount *-1 as POAmount,
GRN.Date GRNDate, GRN.Reference GRNReference, GRN.ActualQuantity GRNQTY, GRN.Rate GRNRate,  GRN.RateUOM GRNUOM, GRN.Amount*-1 as GRNAmount,
PURCHASE.Date InvoiceDate, PURCHASE.Reference InvoiceReference, PURCHASE.ActualQuantity InvoiceQTY, PURCHASE.Rate InvoiceRate,PURCHASE.RateUOM InvoiceUOM, PURCHASE.Amount*-1 as InvoiceAmount ,


GRN.PartyName GRNPartyName,  GRN.StockItemName GRNStockItemName, PURCHASE.PartyName PURCHASEPartyName,  PURCHASE.StockItemName PURCHASEStockItemName 
FROM
((SELECT       dbo.TD_Txn_VchHdr.CompanyID,dbo.TD_Txn_VchHdr.Date, dbo.TD_Txn_VchHdr.VoucherTypeName, dbo.TD_Txn_VchHdr.VoucherNo, dbo.TD_Txn_VchHdr.Reference, dbo.TD_Txn_VchHdr.PartyName,  
                         dbo.TD_Txn_InvLine.Rate, dbo.TD_Txn_InvLine.StockItemName, dbo.TD_Txn_InvLine.RateUOM, dbo.TD_Txn_InvLine.Amount, dbo.TD_Txn_InvLine.ActualQuantity, dbo.TD_Txn_InvLine.ActualUOM
FROM            dbo.TD_Txn_VchHdr INNER JOIN
                         dbo.TD_Txn_InvLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_InvLine.CompanyId AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_InvLine.VoucherID INNER JOIN
                         dbo.TD_Txn_AccLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_InvLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo AND 
                         dbo.TD_Txn_InvLine.VoucherID = dbo.TD_Txn_AccLine.VoucherID AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_AccLine.VoucherID
						 where dbo.TD_Txn_VchHdr.CompanyID=2 AND (VoucherTypeName like 'Purchase Order for Factory' 
						 or vouchertypename like 'Purchase Order for Central Hub')) AS PO
						 LEFT OUTER JOIN
						 
(SELECT        dbo.TD_Txn_VchHdr.CompanyID, dbo.TD_Txn_VchHdr.Date, dbo.TD_Txn_VchHdr.VoucherTypeName, dbo.TD_Txn_VchHdr.VoucherNo, dbo.TD_Txn_VchHdr.Reference, dbo.TD_Txn_VchHdr.PartyName, 
                         dbo.TD_Txn_InvLine.Rate, dbo.TD_Txn_InvLine.StockItemName, dbo.TD_Txn_InvLine.RateUOM, dbo.TD_Txn_InvLine.Amount, dbo.TD_Txn_InvLine.ActualQuantity, dbo.TD_Txn_InvLine.ActualUOM, 
                         dbo.TD_Txn_VchHdr.OrderNo, dbo.TD_Txn_VchHdr.OrderDate
FROM            dbo.TD_Txn_VchHdr INNER JOIN
                         dbo.TD_Txn_InvLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_InvLine.CompanyId AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_InvLine.VoucherID INNER JOIN
                         dbo.TD_Txn_AccLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_InvLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo AND 
                         dbo.TD_Txn_InvLine.VoucherID = dbo.TD_Txn_AccLine.VoucherID AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_AccLine.VoucherID
						 where dbo.TD_Txn_VchHdr.CompanyID=2 AND VoucherTypeName like 'GRN%' ) AS GRN 
						 ON PO.Reference=GRN.OrderNo AND PO.StockItemName=GRN.StockItemName)
						 LEFT OUTER JOIN
(SELECT       dbo.TD_Txn_VchHdr.CompanyID,dbo.TD_Txn_VchHdr.Date, dbo.TD_Txn_VchHdr.VoucherTypeName, dbo.TD_Txn_VchHdr.VoucherNo, dbo.TD_Txn_VchHdr.Reference, dbo.TD_Txn_VchHdr.PartyName,  
                         dbo.TD_Txn_InvLine.Rate, dbo.TD_Txn_InvLine.StockItemName, dbo.TD_Txn_InvLine.RateUOM, dbo.TD_Txn_InvLine.Amount, dbo.TD_Txn_InvLine.ActualQuantity, dbo.TD_Txn_InvLine.ActualUOM,
						 dbo.TD_Txn_VchHdr.OrderNo
FROM            dbo.TD_Txn_VchHdr INNER JOIN
                         dbo.TD_Txn_InvLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_InvLine.CompanyId AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_InvLine.VoucherID INNER JOIN
                         dbo.TD_Txn_AccLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_InvLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo AND 
                         dbo.TD_Txn_InvLine.VoucherID = dbo.TD_Txn_AccLine.VoucherID AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_AccLine.VoucherID
						 where dbo.TD_Txn_VchHdr.CompanyID=2 AND VoucherTypeName like 'PURCHASE FOR%') AS PURCHASE
						 ON GRN.OrderNo=PURCHASE.OrderNo AND GRN.StockItemName=PURCHASE.StockItemName AND GRN.ActualQuantity=PURCHASE.ActualQuantity