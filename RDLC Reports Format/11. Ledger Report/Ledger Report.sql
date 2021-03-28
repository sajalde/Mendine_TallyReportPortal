SELECT DISTINCT VH.Date as [Date], VH.PartyLedgerName as [LedgerName], '' as [Particular], VH.VoucherTypeName as [VoucherType], VH.VoucherNo as [VoucherNo],
BL.BillName as [ReferenceNo], al.LineNarration as [Narration] , AL.Amount as [AmountWithoutGST], 0 as [GST], 0 as [OtherExpenses], 0 as [Roundoff],
AL.Amount as [Amount]
FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.VoucherID = AL.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo AND 
VH.VoucherID = BL.VoucherId                         
WHERE 						 
((PartyLedgerName like 'Addapt %' and VoucherTypeName like 'Purchase for%' And LedgerName like 'Addapt %') OR
(PartyLedgerName like 'Addapt %' and VoucherTypeName like 'Paymen%' ))
AND VH.CompanyID = '4' AND VH.Date BETWEEN '2020-04-12 00:00:00.000' AND '2020-04-14 00:00:00.000'