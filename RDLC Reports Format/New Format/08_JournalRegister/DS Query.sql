SELECT  VH.Date, VH.PartyName,  AL.LedgerName,  BL.BillName,  VH.CostCentreName,  AL.Amount, VH.Narration, VH.Reference,
		VH.VoucherTypeName, VH.Reference, AL.IsPartyLedger,  VH.VoucherNo
FROM  TD_Txn_AccLine as AL 
INNER JOIN TD_Txn_VchHdr as VH ON AL.CompanyID = VH.CompanyID AND AL.VoucherID = VH.VoucherID 
INNER JOIN TD_Txn_BillLine as BL ON AL.CompanyID = BL.Companyid AND VH.CompanyID = BL.Companyid AND 
		AL.VoucherID = BL.VoucherId AND VH.VoucherID = BL.VoucherId AND AL.AccLineNo = BL.AccLineNo 						 												 
Where VoucherTypeName like '%Journal'