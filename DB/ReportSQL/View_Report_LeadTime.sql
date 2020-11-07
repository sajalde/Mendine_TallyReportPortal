USE [EasyReports3.6]
GO

/****** Object:  View [dbo].[View_Report_LeadTime]    Script Date: 10/15/2020 7:43:40 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[View_Report_LeadTime]
AS
SELECT PO.Date AS podate, UPPER(PO.PartyName) AS popartyname, PO.Reference AS PORefNo, PO.StockItemName AS POStockItemName, PO.ActualQuantity AS POQTY, PO.Rate AS PORate, PO.RateUOM AS POUOM, 
                  PO.Amount * - 1 AS POAmount, DATEDIFF(day, PO.Date, GRN.Date) AS LeadTime, GRN.Date AS grndate, UPPER(GRN.PartyName) AS GRNPartyName, GRN.Reference AS GRNReference, UPPER(GRN.StockItemName) 
                  AS GRNStockItemName, GRN.ActualQuantity AS GRNQTY, GRN.Rate AS GRNRate, GRN.RateUOM AS GRNUOM, GRN.Amount * - 1 AS GRNAmount, PURCHASE.Date AS InvoiceDate, UPPER(PURCHASE.PartyName) AS InvoicePartyName, 
                  UPPER(PURCHASE.Reference) AS InvoiceReference, UPPER(PURCHASE.StockItemName) AS PURCHASEStockItemName, PURCHASE.ActualQuantity AS InvoiceQTY, PURCHASE.Rate AS InvoiceRate, 
                  PURCHASE.RateUOM AS InvoiceUOM, PURCHASE.Amount * - 1 AS InvoiceAmount, PO.CompanyID
FROM     (SELECT dbo.TD_Txn_VchHdr.CompanyID, dbo.TD_Txn_VchHdr.Date, dbo.TD_Txn_VchHdr.VoucherTypeName, dbo.TD_Txn_VchHdr.VoucherNo, dbo.TD_Txn_VchHdr.Reference, dbo.TD_Txn_VchHdr.PartyName, dbo.TD_Txn_InvLine.Rate, 
                                    dbo.TD_Txn_InvLine.StockItemName, dbo.TD_Txn_InvLine.RateUOM, dbo.TD_Txn_InvLine.Amount, dbo.TD_Txn_InvLine.ActualQuantity, dbo.TD_Txn_InvLine.ActualUOM
                  FROM      dbo.TD_Txn_VchHdr INNER JOIN
                                    dbo.TD_Txn_InvLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_InvLine.CompanyId AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_InvLine.VoucherID INNER JOIN
                                    dbo.TD_Txn_AccLine ON dbo.TD_Txn_VchHdr.CompanyID = dbo.TD_Txn_AccLine.CompanyID AND dbo.TD_Txn_InvLine.AccLineNo = dbo.TD_Txn_AccLine.AccLineNo AND 
                                    dbo.TD_Txn_InvLine.VoucherID = dbo.TD_Txn_AccLine.VoucherID AND dbo.TD_Txn_VchHdr.VoucherID = dbo.TD_Txn_AccLine.VoucherID
                  WHERE   (dbo.TD_Txn_VchHdr.CompanyID = 2) AND (dbo.TD_Txn_VchHdr.VoucherTypeName LIKE 'Purchase Order for Factory') OR
                                    (dbo.TD_Txn_VchHdr.CompanyID = 2) AND (dbo.TD_Txn_VchHdr.VoucherTypeName LIKE 'Purchase Order for Central Hub')) AS PO LEFT OUTER JOIN
                      (SELECT TD_Txn_VchHdr_2.CompanyID, TD_Txn_VchHdr_2.Date, TD_Txn_VchHdr_2.VoucherTypeName, TD_Txn_VchHdr_2.VoucherNo, TD_Txn_VchHdr_2.Reference, TD_Txn_VchHdr_2.PartyName, TD_Txn_InvLine_2.Rate, 
                                         TD_Txn_InvLine_2.StockItemName, TD_Txn_InvLine_2.RateUOM, TD_Txn_InvLine_2.Amount, TD_Txn_InvLine_2.ActualQuantity, TD_Txn_InvLine_2.ActualUOM, TD_Txn_VchHdr_2.OrderNo, TD_Txn_VchHdr_2.OrderDate
                       FROM      dbo.TD_Txn_VchHdr AS TD_Txn_VchHdr_2 INNER JOIN
                                         dbo.TD_Txn_InvLine AS TD_Txn_InvLine_2 ON TD_Txn_VchHdr_2.CompanyID = TD_Txn_InvLine_2.CompanyId AND TD_Txn_VchHdr_2.VoucherID = TD_Txn_InvLine_2.VoucherID INNER JOIN
                                         dbo.TD_Txn_AccLine AS TD_Txn_AccLine_2 ON TD_Txn_VchHdr_2.CompanyID = TD_Txn_AccLine_2.CompanyID AND TD_Txn_InvLine_2.AccLineNo = TD_Txn_AccLine_2.AccLineNo AND 
                                         TD_Txn_InvLine_2.VoucherID = TD_Txn_AccLine_2.VoucherID AND TD_Txn_VchHdr_2.VoucherID = TD_Txn_AccLine_2.VoucherID
                       WHERE   (TD_Txn_VchHdr_2.CompanyID = 2) AND (TD_Txn_VchHdr_2.VoucherTypeName LIKE 'GRN%')) AS GRN ON PO.Reference = GRN.OrderNo AND PO.StockItemName = GRN.StockItemName LEFT OUTER JOIN
                      (SELECT TD_Txn_VchHdr_1.CompanyID, TD_Txn_VchHdr_1.Date, TD_Txn_VchHdr_1.VoucherTypeName, TD_Txn_VchHdr_1.VoucherNo, TD_Txn_VchHdr_1.Reference, TD_Txn_VchHdr_1.PartyName, TD_Txn_InvLine_1.Rate, 
                                         TD_Txn_InvLine_1.StockItemName, TD_Txn_InvLine_1.RateUOM, TD_Txn_InvLine_1.Amount, TD_Txn_InvLine_1.ActualQuantity, TD_Txn_InvLine_1.ActualUOM, TD_Txn_VchHdr_1.OrderNo
                       FROM      dbo.TD_Txn_VchHdr AS TD_Txn_VchHdr_1 INNER JOIN
                                         dbo.TD_Txn_InvLine AS TD_Txn_InvLine_1 ON TD_Txn_VchHdr_1.CompanyID = TD_Txn_InvLine_1.CompanyId AND TD_Txn_VchHdr_1.VoucherID = TD_Txn_InvLine_1.VoucherID INNER JOIN
                                         dbo.TD_Txn_AccLine AS TD_Txn_AccLine_1 ON TD_Txn_VchHdr_1.CompanyID = TD_Txn_AccLine_1.CompanyID AND TD_Txn_InvLine_1.AccLineNo = TD_Txn_AccLine_1.AccLineNo AND 
                                         TD_Txn_InvLine_1.VoucherID = TD_Txn_AccLine_1.VoucherID AND TD_Txn_VchHdr_1.VoucherID = TD_Txn_AccLine_1.VoucherID
                       WHERE   (TD_Txn_VchHdr_1.CompanyID = 2) AND (TD_Txn_VchHdr_1.VoucherTypeName LIKE 'PURCHASE FOR%')) AS PURCHASE ON GRN.OrderNo = PURCHASE.OrderNo AND GRN.StockItemName = PURCHASE.StockItemName AND 
                  GRN.ActualQuantity = PURCHASE.ActualQuantity
GO
