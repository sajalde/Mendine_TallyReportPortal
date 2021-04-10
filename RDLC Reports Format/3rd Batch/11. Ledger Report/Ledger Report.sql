SELECT DISTINCT VH.Date as [Date], VH.PartyLedgerName as [LedgerName], '' as [Particular], VH.VoucherTypeName as [VoucherType], VH.VoucherNo as [VoucherNo],
BL.BillName as [ReferenceNo], al.LineNarration as [Narration] , AL.Amount as [AmountWithoutGST], 0 as [GST], 0 as [OtherExpenses], 0 as [Roundoff],
AL.Amount as [Amount] FROM  TD_Txn_VchHdr as VH 
INNER JOIN TD_Txn_InvLine as IL ON VH.CompanyID = IL.CompanyId 
INNER JOIN TD_Txn_AccLine as AL ON VH.CompanyID = AL.CompanyID AND VH.VoucherID = AL.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo AND 
VH.VoucherID = BL.VoucherId                         
WHERE 						 
((PartyLedgerName like 'Addapt %' and VoucherTypeName like 'Purchase for%' And LedgerName like 'Addapt %') OR
(PartyLedgerName like 'Addapt %' and VoucherTypeName like 'Paymen%' ))
AND VH.CompanyID = '4' AND VH.Date BETWEEN '2020-04-12 00:00:00.000' AND '2020-04-14 00:00:00.000'
------================================================================================================================================================================

Select Top(100) vh.VoucherID ,vh.EntryDate, vh.VoucherTypeName, vh.Narration as [Particular], vh.VoucherNo, vh.PartyLedgerName, vh.Reference,
AL.LedgerName ,AL.Amount as [GSTAmount], AL1.Amount as [Amount], ALO.Amount as [OtherExpenses], ALR.Amount as [RounfOff]
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL ON vh.VoucherID= AL.VoucherID And VH.CompanyID=Al.CompanyID
Inner Join TD_Txn_AccLine as AL1 ON vh.VoucherID= AL1.VoucherID And VH.CompanyID=Al1.CompanyID And Al1.IsDeemedPositive=0
Inner Join TD_Txn_AccLine as ALO ON vh.VoucherID= ALO.VoucherID And VH.CompanyID=ALO.CompanyID And ALO.IsDeemedPositive=1
Inner Join TD_Txn_AccLine as ALR ON vh.VoucherID= ALR.VoucherID And VH.CompanyID=ALR.CompanyID And ALR.IsDeemedPositive=1
where VH.CompanyID=4 And IsCancelled=0  
And (AL.ledgername like '%IGST%' OR AL.ledgername like '%SGST%' OR AL.ledgername like '%CGST%') 
And (ALO.ledgername like '%Other Expenses%') 
And (ALR.ledgername like '%Round Off%') 
And VH.PartyLedgerName='UDI Sales Pvt Ltd'
order by VH.VoucherID Desc





/*  vh.VoucherID In (54812,50675, 56118) */



-- VoucherID ,Date, VoucherType, Narration/Particular, VoucherNo, PartyLedgerName, Reference
Select Top(100) * from TD_Txn_InvLine where CompanyID=4 and VoucherID In (54812,50675, 56118)
-- VoucherID, 
Select Top(100) * from TD_Txn_AccLine where CompanyID=4 and VoucherID In (54812,50675, 56118) order by VoucherID Desc
-- VoucherID, 
Select Top(100) * from TD_Txn_BillLine where CompanyID=4 and VoucherID In (54812,50675)
-- VoucherID, 

Select Top(100) * from tmpPurchase where companyid=4