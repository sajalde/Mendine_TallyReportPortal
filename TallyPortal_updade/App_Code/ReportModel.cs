using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;


    public class ReportModel
    {
    #region --Commoon Report Search --
    public class Search_DropdownList
    {
        public List<String> lst_Company { get; set; }
        public List<String> lst_Godown { get; set; }
        public List<String> lst_SourceGodown { get; set; }
        public List<String> lst_DestinationGodown { get; set; }

        public List<String> lst_Party { get; set; }
        public List<String> lst_Item { get; set; }
        public List<String> lst_StockCategory { get; set; }
        public List<String> lst_StockGroup { get; set; }
        public List<String> lst_PONumber { get; set; }
        public List<String> lst_CostCenter { get; set; }
        public List<String> lst_HQ { get; set; }
        public List<String> lst_VoucherType { get; set; }
        public List<String> lst_LedgerName { get; set; }
        public List<String> lst_TransactionType { get; set; }

    }
    public class Report_Search
    {
        public string CompanyName { get; set; }
        public string StartDate { get; set; }
        public string EndDate { get; set; }
        public string GodownName_Source { get; set; }
        public string PartyName { get; set; }
        public string ItemName { get; set; }
        public string PONumber { get; set; }
        public string StockGroup { get; set; }
        public string CostCenter { get; set; }
        public string StockCategory { get; set; }
        public string GodownName_Destination { get; set; }
        public string StartDate_GRN { get; set; }
        public string EndDate_GRN { get; set; }
        public string StartDate_Invoice { get; set; }
        public string EndDate_Invoice { get; set; }
        public string VoucherType { get; set; }
        public string HQ { get; set; }
        public string LedgerName { get; set; }
        public string TransactionType { get; set; }
    }

        #endregion

        #region -- Pending Purchase Order ----
        public class PendingPurchaseOrder_Report
        {
            public string CompanyID { get; set; }
            public string PODate { get; set; }
            public string PONumber { get; set; }
            public string Reference { get; set; }
            public string PartyName { get; set; }
            public string ItemName { get; set; }
            public string POQTY { get; set; }
            public string UOM { get; set; }
            public string PORate { get; set; }
            public string TotalGRNQTY { get; set; }
            public string BalanceQTY { get; set; }
            public string DueDate { get; set; }
            public string OverdueDays { get; set; }
        }

        public class Report_List : List<PendingPurchaseOrder_Report>
        {

        }

        #endregion

        #region -- Lead Time Report --
        public class LeadTime_Dropdown
        {
            public List<String> lst_PartyName { get; set; }
            public List<String> lst_StockItemName { get; set; }
        }

        public class LeadTime_Search
        {
            public string StartDate_PO { get; set; }
            public string EndtDate_PO { get; set; }
            public string PartyName { get; set; }
            public string ItemName { get; set; }
            public string StartDate_GRN { get; set; }
            public string EndtDate_GRN { get; set; }
            public string StartDate_Invoice { get; set; }
            public string EndtDate_Invoice { get; set; }
        }

        public class LeadTime_Report
        {
            public string PODate { get; set; }
            public string PartyName { get; set; }
            public string StoreItemName { get; set; }
            public string POQTY { get; set; }
            public string PORate { get; set; }
            public string POUOM { get; set; }
            public string POAmount { get; set; }
            public string GRNDate { get; set; }
            public string GRNReference { get; set; }
            public string GRNQuantity { get; set; }
            public string GRNRate { get; set; }
            public string GRNUOM { get; set; }
            public string GRNAmount { get; set; }
            public string InvoiceDate { get; set; }
            public string InvoiceReference { get; set; }
            public string InvoiceActualQuantity { get; set; }
            public string InvoiceRate { get; set; }
            public string InvoiceRateUOM { get; set; }
            public string InvoiceAmount { get; set; }
        }

        public class LeadTime_Report_List : List<LeadTime_Report>
        {

        }
        #endregion

        #region -- Final Product Stock Report --
        public class FinalProductStock_Dropdown
        {
            public List<String> lst_Company { get; set; }
            public List<String> lst_StockItemName { get; set; }
            public List<String> lst_GodownName { get; set; }
            public List<String> lst_StockGroup { get; set; }
        }
        public class FinalProductStock_Search
        {
            public string Company { get; set; }
            public string ItemName { get; set; }
            public string GodownName { get; set; }
            public string StockGroup { get; set; }
            public string StartDate_StockDate { get; set; }
            public string EndDate_StockDate { get; set; }
        }

        public class FinalProductStock_Report
        {
            public string CompanyID { get; set; }
            public string StockDate { get; set; }
            public string StockItemName { get; set; }
            public string GodownName { get; set; }
            public string BatchName { get; set; }
            public string Quantity { get; set; }
            public string UOM { get; set; }
            public string Rate { get; set; }
            public string Amount { get; set; }
            public string StockGroup { get; set; }
        }

        public class FinalProductStock_Report_List : List<FinalProductStock_Report>
        {

        }

        #endregion       
    }
