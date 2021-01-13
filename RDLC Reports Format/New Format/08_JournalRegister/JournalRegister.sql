------- Journal Register ----
--DECLARE @CompanyNames as Varchar(2000)='',   @DateFrom datetime= Null,  @DateTo datetime=Null,  @PartyName_List as Varchar(500)='', @CostCenter_List as Varchar(500)='', @LedgerName_List as Varchar(500)=''

--Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
--SET @DateFrom ='01/01/2020'
--SET @DateTo = '12/30/2020'
--SET @PartyName_List = ''
--SET @CostCenter_List = ''
--SET @LedgerName_List = ''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID
IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpCostCenter') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID('tempdb..#tmpLedger') IS NOT NULL DROP TABLE #tmpLedger

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'PartyName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'CostCentreName' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''))
SELECT NAME AS 'LedgerName' INTO #tmpLedger from	 dbo.GetTableFromString(isnull(@LedgerName_List,''))


SELECT  VH.Date, VH.PartyName,  AL.LedgerName,  BL.BillName,  VH.CostCentreName,  AL.Amount, VH.Narration, VH.Reference, VH.VoucherTypeName, VH.Reference, AL.IsPartyLedger,  VH.VoucherNo
FROM  TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND VH.CompanyID = BL.Companyid AND 
		AL.VoucherID = BL.VoucherId AND VH.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo 						 												 
Where VoucherTypeName like '%Journal'
	And (@CompanyNames  <> '' AND VH.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND VH.CompanyID = VH.CompanyID))
	And VH.Date >= @DateFrom AND VH.Date <= @DateTo
	And (@PartyName_List  <> '' AND vh.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND vh.PartyLedgerName = vh.PartyLedgerName ))
	And (@CostCenter_List  <> '' AND VH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''  AND VH.CostCentreName = VH.CostCentreName))
	And (@LedgerName_List  <> '' AND AL.LedgerName IN (SELECT LedgerName FROM #tmpLedger)  OR (@LedgerName_List = ''  AND AL.LedgerName = AL.LedgerName))
Order by VH.Date, VH.PartyLedgerName, VH.CostCentreName Desc