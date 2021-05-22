/****** Script for List Of All Post-Dated Vouchers command from SSMS  ******/
SELECT        TD_Txn_VchHdr.CompanyID, TD_Txn_VchHdr.VoucherID, TD_Txn_VchHdr.Date, TD_Txn_VchHdr.Narration,
	      TD_Txn_VchHdr.EnteredBy, TD_Txn_VchHdr.VoucherTypeName, TD_Txn_VchHdr.VoucherNo,
              TD_Txn_VchHdr.PartyLedgerName, TD_Txn_AccLine.Amount
FROM          TD_Txn_VchHdr INNER JOIN
                         TD_Txn_AccLine ON TD_Txn_VchHdr.CompanyID = TD_Txn_AccLine.CompanyID 
						 AND TD_Txn_VchHdr.VoucherID = TD_Txn_AccLine.VoucherID
WHERE TD_Txn_VchHdr.CompanyID = 4 
AND Date ='2020-04-01 00:00:00.000' AND TD_Txn_VchHdr.PartyLedgerName = TD_Txn_AccLine.LedgerName
AND IsPostDated = 1