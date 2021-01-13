/****** Script for SelectTopNRows command from SSMS  ******/
SELECT TOP 100 
	   [StockDate]
      ,[StockItemName]
      ,[GodownName]
      ,[BatchName]
      ,[Quantity]
      ,[UOM]
      ,[Rate]
      ,[Amount]
      ,[EntryDate]
  FROM [EasyReports3.6].[dbo].[TD_Txn_StockDetails]
  where Quantity like '-%' and StockDate='2021-01-03 00:00:00.000' and StockItemName like 'gly%'

