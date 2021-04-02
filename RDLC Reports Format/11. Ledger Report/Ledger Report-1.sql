Select Top(100) vh.VoucherID ,vh.EntryDate, vh.VoucherTypeName, vh.Narration as [Particular], vh.VoucherNo, vh.PartyLedgerName, vh.Reference,
AL1.Amount as [Amount], ALO.Amount as [OtherExpenses], ALR.Amount as [RounfOff]
Into #LedgerReport
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL1 ON vh.VoucherID= AL1.VoucherID And VH.CompanyID=Al1.CompanyID And Al1.IsDeemedPositive=0
Inner Join TD_Txn_AccLine as ALO ON vh.VoucherID= ALO.VoucherID And VH.CompanyID=ALO.CompanyID And ALO.IsDeemedPositive=1
Inner Join TD_Txn_AccLine as ALR ON vh.VoucherID= ALR.VoucherID And VH.CompanyID=ALR.CompanyID And ALR.IsDeemedPositive=1
where VH.CompanyID=4 And IsCancelled=0  
And (ALO.ledgername like '%Other Expenses%') 
And (ALR.ledgername like '%Round Off%') 
And VH.PartyLedgerName='UDI Sales Pvt Ltd'
order by VH.VoucherID Desc


Select Top(100) vh.VoucherID , Sum(AL.Amount) as [GSTAmount]
Into #LedgerGSTReport
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL ON vh.VoucherID= AL.VoucherID And VH.CompanyID=Al.CompanyID
where VH.CompanyID=4 And IsCancelled=0  
And (AL.ledgername like '%IGST%' OR AL.ledgername like '%SGST%' OR AL.ledgername like '%CGST%') 
And VH.PartyLedgerName='UDI Sales Pvt Ltd'
Group By vh.VoucherID
order by VH.VoucherID Desc

Select L.EntryDate as [Date], L.PartyLedgerName as [LedgerName], L.Particular as [Particular], L.VoucherTypeName as [VoucherType], L.VoucherNo as [VoucherNo],
L.Reference as [ReferenceNo], L.Particular as [Narration] , L.Amount as [AmountWithoutGST], Abs(GL.GSTAmount) as [GST], Abs(L.OtherExpenses) as [OtherExpenses], Abs(L.RounfOff) as [Roundoff],
IsNull(L.Amount,0)+ Abs(IsNull(GL.GSTAmount,0)) + Abs(IsNull(L.OtherExpenses,0))  as [Amount]
From #LedgerReport as L
Inner Join #LedgerGSTReport as GL ON GL.VoucherID=L.VoucherID

Drop Table #LedgerReport
Drop Table #LedgerGSTReport