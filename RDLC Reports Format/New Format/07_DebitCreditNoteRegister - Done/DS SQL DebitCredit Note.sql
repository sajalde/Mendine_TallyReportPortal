SELECT VH.VoucherTypeName, VH.Date , vh.PartyLedgerName as [PartyName], VH.Reference, VH.CostCentreName,
IL.StockItemName, IL.ActualQuantity,   IL.Rate, IL.RateUOM, IL.Amount, GSTClass as [GST], 0 as [GSTAmount], IL.Amount + 0 as [TotalAmount] , VH.Narration 
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId AND VH.VoucherID = IL.VoucherID 
FULL OUTER JOIN TD_Txn_AccLine ON IL.AccLineNo = TD_Txn_AccLine.AccLineNo AND VH.CompanyID = TD_Txn_AccLine.CompanyID AND IL.VoucherID = TD_Txn_AccLine.VoucherID
where VoucherTypeName like '%Debit Note%' or VoucherTypeName like '%credit%'