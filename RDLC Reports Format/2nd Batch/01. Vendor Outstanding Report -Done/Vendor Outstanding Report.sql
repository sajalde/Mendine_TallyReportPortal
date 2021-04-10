--- Vendor Outstanding Report ----
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


SELECT  MC.CompanyID, AL.LedgerName, BL.BillName, SUM(BL.Amount*-1) as PaymentAmount,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END As PaymentDate
INTO #Payments
FROM TD_Mst_VoucherType as VT 
INNER JOIN TD_Mst_Company as MC ON VT.CompanyID = MC.CompanyID 
INNER JOIN TD_Txn_AccLine as AL
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND AL.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo ON VT.CompanyID = VH.CompanyID AND  VT.VoucherTypeName = VH.VoucherTypeName
WHERE VT.VoucherType = 'Payment' OR VT.VoucherType = 'Debit Note' OR VT.VoucherType = 'Journal'
	--AND TD_Mst_Company.CompanyID = @CompanyIDs
GROUP BY MC.CompanyID, AL.LedgerName,  BL.BillName,
	CASE 
		WHEN BL.Date IS NULL THEN VH.Date
		ELSE BL.Date
	END

Select  B.*,P.PaymentDate, P.PaymentAmount, (b.BillAmount - p.PaymentAmount) as [PendingAmount],  DATEDIFF(D,BillDate,PaymentDate) As PaymentDays,
L.StateName, L.ParentLedgerGroup as PartyGroup
FROM #Bills B 
   LEFT OUTER JOIN #Payments P ON b.CompanyID = P.CompanyID AND B.PartyName = P.LedgerName AND B.BillNo = P.BillName 
   LEFT OUTER JOIN TD_Mst_Ledger L ON B.CompanyID = L.CompanyID And B.PartyName = L.LedgerName
where  (b.BillAmount - p.PaymentAmount)>0 
