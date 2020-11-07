

/****** Object:  View [dbo].[View_Report_LeadTime]    Script Date: 7/25/2020 12:56:07 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE VIEW [dbo].[View_Report_LeadTime]
AS
SELECT PO.Date AS podate, PO.PartyName AS popartyname, PO.Reference AS poref, PO.StockItemName AS POStockItemName, PO.ActualQuantity AS POActualQuantity, PO.Rate AS PORate, PO.RateUOM AS PORateUOM, 
                  PO.Amount * - 1 AS POamount, GRN.Date AS grndate, GRN.PartyName AS GRNPartyName, GRN.Reference AS GRNReference, GRN.StockItemName AS GRNStockItemName, GRN.ActualQuantity AS GRNActualQuantity, 
                  GRN.Rate AS GRNRate, GRN.RateUOM AS GRNRateUOM, GRN.Amount * - 1 AS GRNAmount, PURCHASE.Date AS PURCHASEDate, PURCHASE.PartyName AS PURCHASEPartyName, PURCHASE.Reference AS PURCHASEReference, 
                  PURCHASE.StockItemName AS PURCHASEStockItemName, PURCHASE.ActualQuantity AS PURCHASEActualQuantity, PURCHASE.Rate AS PURCHASERate, PURCHASE.RateUOM AS PURCHASERateUOM, 
                  PURCHASE.Amount * - 1 AS PURCHASEAmount
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

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPane1', @value=N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "PO"
            Begin Extent = 
               Top = 7
               Left = 48
               Bottom = 170
               Right = 269
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "GRN"
            Begin Extent = 
               Top = 7
               Left = 317
               Bottom = 170
               Right = 538
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PURCHASE"
            Begin Extent = 
               Top = 7
               Left = 586
               Bottom = 170
               Right = 807
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
' , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Report_LeadTime'
GO

EXEC sys.sp_addextendedproperty @name=N'MS_DiagramPaneCount', @value=1 , @level0type=N'SCHEMA',@level0name=N'dbo', @level1type=N'VIEW',@level1name=N'View_Report_LeadTime'
GO


