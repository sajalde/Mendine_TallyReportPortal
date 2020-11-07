--- List of Cost Center ----
--Select Upper(CostCentreName) as [CostCentreName] FROM  TD_Mst_CostCentre where CompanyID=2 Order by CostCentreName
-- CostCenter in Table -- TD_Txn_VchHdr

DECLARE @CompanyNames as Varchar(2000)='', @DateFrom datetime= Null,  @DateTo datetime=Null,   @PartyName_List as Varchar(250)='', @CostCenter_List as Varchar(250)=''

Set @CompanyNames='Mendine Pharmaceuticals Pvt Ltd. (FY 2019-20)Server'
SET @DateFrom ='01/01/2020'
SET @DateTo = '10/30/2020'
SET @PartyName_List = ''
SET @CostCenter_List=''

IF OBJECT_ID('tempdb..#tmpCompanyName') IS NOT NULL DROP TABLE #tmpCompanyName
IF OBJECT_ID('tempdb..#tmpCompanyID') IS NOT NULL DROP TABLE #tmpCompanyID

IF OBJECT_ID('tempdb..#tmpPartyName') IS NOT NULL DROP TABLE #tmpPartyName
IF OBJECT_ID('tempdb..#tmpCostCenter') IS NOT NULL DROP TABLE #tmpCostCenter
IF OBJECT_ID('tempdb..#Bills') IS NOT NULL DROP TABLE #Bills;
IF OBJECT_ID('tempdb..#Payments') IS NOT NULL DROP TABLE #Payments;

SELECT NAME AS 'CompanyName' INTO #tmpCompanyName  from dbo.GetTableFromString(isnull(@CompanyNames,''))
Select c.CompanyID Into #tmpCompanyID  From #tmpCompanyName as t Inner Join TD_Mst_Company as c ON c.CompanyName=t.CompanyName
SELECT NAME AS 'PartyName' INTO #tmpPartyName from dbo.GetTableFromString(isnull(@PartyName_List,''))
SELECT NAME AS 'CostCentreName' INTO #tmpCostCenter from	 dbo.GetTableFromString(isnull(@CostCenter_List,''))

SELECT  MC.CompanyID, Upper(AH.PartyLedgerName) as [PartyName], Upper(AH.CostCentreName) as [CostCentreName],
	    CASE WHEN MIN(BL.Date) IS NULL THEN MIN(AH.Date)	ELSE MIN(BL.Date) END As BillDate, BL.BillName as [BillNo], SUM(BL.Amount*1) As [BillAmount]
INTO #Bills
FROM TD_Mst_VoucherType as VT
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as AH ON AL.CompanyID = AH.CompanyID AND AL.VoucherID = AH.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo  ON VT.CompanyID = AH.CompanyID AND  VT.VoucherTypeName = AH.VoucherTypeName
WHERE VT.VoucherType = 'Purchase' And BL.Amount > 0 AND AH.Date >= @DateFrom AND AH.Date <= @DateTo
	And (@CompanyNames  <> '' AND MC.CompanyID IN (SELECT CompanyID FROM #tmpCompanyID)  OR (@CompanyNames = ''  AND MC.CompanyID = MC.CompanyID))
	And (@PartyName_List  <> '' AND AH.PartyLedgerName IN (SELECT PartyName FROM #tmpPartyName)  OR (@PartyName_List = ''  AND AH.PartyLedgerName = AH.PartyLedgerName ))
	And (@CostCenter_List  <> '' AND AH.CostCentreName IN (SELECT CostCentreName FROM #tmpCostCenter)  OR (@CostCenter_List = ''  AND AH.CostCentreName = AH.CostCentreName ))
GROUP BY MC.CompanyID, 	AH.PartyLedgerName, 	BL.BillName,	AH.CostCentreName


SELECT     
TD_Mst_Company.CompanyID, 
	CASE 
		WHEN TD_Txn_BillLine.Date IS NULL THEN TD_Txn_VchHdr.Date
		ELSE TD_Txn_BillLine.Date
	END As PaymentDate, 
	TD_Txn_AccLine.LedgerName, 
	TD_Txn_BillLine.BillName, 
	SUM(TD_Txn_BillLine.Amount) as PaymentAmount
INTO #Payments
FROM         TD_Mst_VoucherType INNER JOIN
                      TD_Mst_Company ON TD_Mst_VoucherType.CompanyID = TD_Mst_Company.CompanyID INNER JOIN
                      TD_Txn_AccLine INNER JOIN
                      TD_Txn_VchHdr ON TD_Txn_AccLine.CompanyID = TD_Txn_VchHdr.CompanyID AND 
                      TD_Txn_AccLine.VoucherID = TD_Txn_VchHdr.VoucherID INNER JOIN
                      TD_Txn_BillLine ON TD_Txn_AccLine.CompanyID = TD_Txn_BillLine.Companyid AND TD_Txn_AccLine.VoucherID = TD_Txn_BillLine.VoucherId AND 
                      TD_Txn_AccLine.AccLineNo = TD_Txn_BillLine.AccLineNo ON TD_Mst_VoucherType.CompanyID = TD_Txn_VchHdr.CompanyID AND 
                      TD_Mst_VoucherType.VoucherTypeName = TD_Txn_VchHdr.VoucherTypeName
WHERE TD_Mst_VoucherType.VoucherType = 'Payment' OR TD_Mst_VoucherType.VoucherType = 'Debit Note' OR TD_Mst_VoucherType.VoucherType = 'Journal'
	--AND TD_Mst_Company.CompanyID = @CompanyIDs
GROUP BY
TD_Mst_Company.CompanyID, 
	CASE 
		WHEN TD_Txn_BillLine.Date IS NULL THEN TD_Txn_VchHdr.Date
		ELSE TD_Txn_BillLine.Date
	END, 
	TD_Txn_AccLine.LedgerName, 
	TD_Txn_BillLine.BillName

Select L.StateName, L.ParentLedgerGroup as PartyGroup, B.*,P.PaymentDate,P.PaymentAmount, DATEDIFF(D,BillDate,PaymentDate) As PaymentDays
FROM
#Bills B 
   LEFT OUTER JOIN #Payments P ON b.CompanyID = P.CompanyID AND B.PartyName = P.LedgerName AND B.BillNo = P.BillName 
   LEFT OUTER JOIN TD_Mst_Ledger L ON B.CompanyID = L.CompanyID And B.PartyName = L.LedgerName
   
