/****** Exception Report ******/
SELECT VH.Date as [VoucherDate], VH.PartyLedgerName as [LedgerName], VH.VoucherTypeName as [VoucherTypeName],  VH.VoucherNo as [VoucherNo], 
CASE WHEN AL.Amount< 0 THEN AL.Amount ELSE 0 END AS [DebitAmount],
CASE WHEN AL.Amount> 0 THEN AL.Amount ELSE 0 END AS [CreditAmount],
vh.CostCentreName as [CostCenter], VH.Narration, VH.EnteredBy, VH.AlterId
FROM TD_Txn_VchHdr as VH
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID  AND VH.Id = AL.VoucherID
WHERE VH.CompanyID = '10B5D794-DCFA-41F4-89E6-45D3B15FC160' AND  VoucherTypeName = 'Receipts' AND Date = '2020-11-23 00:00:00.000'
AND VH.PartyLedgerName = AL.LedgerName AND IsOptional = 1

--select * from TD_Mst_Company