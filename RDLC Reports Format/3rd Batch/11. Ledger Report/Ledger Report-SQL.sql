----- Ledger Report ----
DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @LedgerName_List as Varchar(2500)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)'
SET @DateFrom ='03/01/2021'
SET @DateTo = '03/31/2021'
SET @LedgerName_List = 'UDI Sales Pvt Ltd'

IF OBJECT_ID('tempdb..#tmpLedgerName') IS NOT NULL DROP TABLE #tmpLedgerName
Declare @CompanyID as Int
Select @CompanyID= c.CompanyID  From TD_Mst_Company as c Where c.CompanyName=@CompanyNames
Print @CompanyID
SELECT NAME AS 'LedgerName' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''))

if object_id('tempdb..#LedgerReport') is not null drop table #LedgerReport
if object_id('tempdb..#LedgerGSTReport') is not null drop table #LedgerGSTReport

Select vh.VoucherID ,vh.EntryDate, vh.VoucherTypeName, vh.Narration as [Particular], vh.VoucherNo, vh.PartyLedgerName, vh.Reference, AL1.Amount as [Amount],
ALO.Amount as [OtherExpenses], ALR.Amount as [RounfOff]
--Into #LedgerReport
from TD_Txn_VchHdr as vh
Inner Join TD_Txn_AccLine as AL1 ON vh.VoucherID= AL1.VoucherID And VH.CompanyID=Al1.CompanyID And Al1.IsDeemedPositive=0
Inner Join TD_Txn_AccLine as ALO ON vh.VoucherID= ALO.VoucherID And VH.CompanyID=ALO.CompanyID And ALO.IsDeemedPositive=1
Inner Join TD_Txn_AccLine as ALR ON vh.VoucherID= ALR.VoucherID And VH.CompanyID=ALR.CompanyID And ALR.IsDeemedPositive=1
where IsCancelled=0  
--And VH.Date >= @DateFrom AND VH.Date <= @DateTo 
And VH.CompanyID=@CompanyID
And (@LedgerName_List  <> '' AND vh.PartyLedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
And (ALO.ledgername like '%Other Expenses%') And (ALR.ledgername like '%Round Off%') 
order by VH.VoucherID Desc



--Select vh.VoucherID , Sum(AL.Amount) as [GSTAmount]
--Into #LedgerGSTReport
--From #LedgerReport as L
--Inner Join TD_Txn_VchHdr as vh ON VH.VoucherID= L.VoucherID
--Inner Join TD_Txn_AccLine as AL ON vh.VoucherID= AL.VoucherID And VH.CompanyID=Al.CompanyID
--And (AL.ledgername like '%IGST%' OR AL.ledgername like '%SGST%' OR AL.ledgername like '%CGST%') 
--Group By vh.VoucherID
--order by VH.VoucherID Desc

----Select vh.VoucherID , Sum(AL.Amount) as [GSTAmount]
----Into #LedgerGSTReport
----from TD_Txn_VchHdr as vh
----Inner Join TD_Txn_AccLine as AL ON vh.VoucherID= AL.VoucherID And VH.CompanyID=Al.CompanyID
----where IsCancelled=0  And VH.Date >= @DateFrom AND VH.Date <= @DateTo
----And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID)
----And (@LedgerName_List  <> '' AND vh.PartyLedgerName IN (SELECT LedgerName FROM #tmpLedgerName)  OR (@LedgerName_List = ''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
----And (AL.ledgername like '%IGST%' OR AL.ledgername like '%SGST%' OR AL.ledgername like '%CGST%') 
----Group By vh.VoucherID
----order by VH.VoucherID Desc

--Select L.EntryDate as [Date], L.PartyLedgerName as [LedgerName], L.Particular as [Particular], L.VoucherTypeName as [VoucherType], L.VoucherNo as [VoucherNo],
--L.Reference as [ReferenceNo], L.Particular as [Narration] , L.Amount as [AmountWithoutGST], Abs(GL.GSTAmount) as [GST], Abs(L.OtherExpenses) as [OtherExpenses], Abs(L.RounfOff) as [Roundoff],
--IsNull(L.Amount,0)+ Abs(IsNull(GL.GSTAmount,0)) + Abs(IsNull(L.OtherExpenses,0))  as [Amount]
--From #LedgerReport as L
--Inner Join #LedgerGSTReport as GL ON GL.VoucherID=L.VoucherID
