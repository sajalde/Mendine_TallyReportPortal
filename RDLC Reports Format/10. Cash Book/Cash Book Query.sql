----- Cash Book ----
DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,
@TransactionType_List as Varchar(500)='',  @LedgerName_List as Varchar(2500)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2020-21)'
SET @DateFrom ='03/01/2021'
SET @DateTo = '03/19/2021'
SET @TransactionType_List = ''
SET @LedgerName_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpTransactionType') IS NOT NULL DROP TABLE #tmpTransactionType
IF OBJECT_ID('tempdb..#tmpLedgerName') IS NOT NULL DROP TABLE #tmpLedgerName

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'TransactionType ' INTO #tmpTransactionType from dbo.GetTableFromString(isnull(@TransactionType_List,''))
SELECT NAME AS 'LedgerName' INTO #tmpLedgerName from dbo.GetTableFromString(isnull(@LedgerName_List,''))


if object_id('tempdb..#CashTransactions') is not null
	    drop table #CashTransactions

-- Select all the transactions which have a cash
SELECT DISTINCT BA.CompanyId, ba.TransactionType, VH.VoucherTypeName, BA.VoucherID 
INTO #CashTransactions
FROM  TD_Txn_BankAllocations as BA 
INNER JOIN  TD_Txn_VchHdr as VH ON VH.CompanyID = BA.CompanyID AND VH.VoucherID = BA.VoucherID 
WHERE BA.CompanyID IN (4) AND BA.VoucherDate BETWEEN @DateFrom AND @DateTo  aND
(VH.IsOptional <> 1) AND (VH.IsCancelled <> 1) AND (VH.IsDeleted <> 1)  AND TransactionType LIKE '%cash%'	


Select vh.Date as [VoucherDate] , l.TypeOfLedger as [LedgerName], l.LedgerName as [SubLedgerName], ct.TransactionType as [TransactionType], l.LedgerAlias as [Particular],
al.Amount as [Amount], vh.Narration as [Narration], bl.BillType as [BillType]
From TD_Mst_Company as c
Inner Join TD_Mst_VoucherType as vt ON c.CompanyID = vt.CompanyID 
Inner Join TD_Txn_AccLine as al 
INNER JOIN TD_Txn_VchHdr as vh ON al.CompanyID = vh.CompanyID AND al.VoucherID = vh.VoucherID ON vt.CompanyID = vh.CompanyID AND vt.VoucherTypeName = vh.VoucherTypeName
LEFT OUTER JOIN TD_Mst_Ledger as l ON al.CompanyID = l.CompanyID AND al.LedgerName = l.LedgerName
Inner Join #CashTransactions ct	ON ct.CompanyID = vh.CompanyID AND ct.VoucherID = vh.VoucherID
Inner Join TD_Txn_BillLine bl	ON ct.CompanyID = bl.CompanyID AND ct.VoucherID = bl.VoucherID
WHERE c.CompanyID IN (4) And al.Amount>0
