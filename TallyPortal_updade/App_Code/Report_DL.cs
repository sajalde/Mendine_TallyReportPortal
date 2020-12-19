using ReportRDLC.models;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using static ReportModel;
//using static ReportRDLC.models.ReportModel;


public class Report_DL
{
    #region ----- Common  ----
    #region Bind Drop Down
    public Search_DropdownList Common_BindDropdownData(string CompanyName)
    {
        Int32? CompanyID = 0;
        Search_DropdownList ddlData = new Search_DropdownList();
        string sql = string.Empty;
        SqlCommand cmd = null;
        SqlDataReader rdr = null;
        Common.OpenConnection();
        try
        {
            if (String.IsNullOrEmpty(CompanyName))
            {
                //--- Company Drop Down ----
                ddlData.lst_Company = new List<string>();
                ddlData.lst_Company.Add("select");

                //String sql = "Select Distinct CompanyID from TD_Txn_StockDetails order by CompanyID";
                sql = "Select CompanyID, Upper(CompanyName) as [CompanyName] from TD_Mst_Company order by CompanyName";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    //ddlData.lst_Company.Add(Common.GetString(rdr["CompanyID"]));
                    ddlData.lst_Company.Add(Common.GetString(rdr["CompanyName"]));
                }
                rdr.Close();
            }
            else
            {
                //---------- Get Company Id by Name
                sql = "Select CompanyID from TD_Mst_Company where CompanyName='" + CompanyName + "'";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    CompanyID = Convert.ToInt32(Common.GetString(rdr["CompanyID"]));
                }

                rdr.Close();

                //--- GodownName Drop Down ----
                ddlData.lst_Godown = new List<string>();
                ddlData.lst_Godown.Add("select");
                sql = "Select Distinct Upper(GodownName) as [GodownName] from TD_Mst_Godown where CompanyID=" + CompanyID + " order by GodownName";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_Godown.Add(Common.GetString(rdr["GodownName"]));
                }
                rdr.Close();

                //--- Party Name ----
                ddlData.lst_Party = new List<string>();
                ddlData.lst_Party.Add("select");
                sql = "Select Distinct Upper(LedgerName) as [PartyName]  from TD_Mst_Ledger  where ParentLedgerGroup Like 'Sundry Creditors%' And CompanyID=" + CompanyID + " order by  Upper(LedgerName)";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_Party.Add(Common.GetString(rdr["PartyName"]));
                }
                rdr.Close();

                //--- Stock CATEGORY Drop Down ----
                ddlData.lst_StockCategory = new List<string>();
                ddlData.lst_StockCategory.Add("select");
                sql = "Select Distinct Upper(StockCategoryName) as [CategoryName] from TD_Mst_StockCategory where CompanyID=" + CompanyID + " order by CategoryName";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_StockCategory.Add(Common.GetString(rdr["CategoryName"]));
                }
                rdr.Close();

                //--- Stock Group Drop Down ----
                ddlData.lst_StockGroup = new List<string>();
                ddlData.lst_StockGroup.Add("select");
                sql = "Select Distinct Upper(StockGroupName) as [StockGroupName] from TD_Mst_StockGroup where CompanyID=" + CompanyID + " order by Upper(StockGroupName)";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_StockGroup.Add(Common.GetString(rdr["StockGroupName"]));
                }
                rdr.Close();

                //--- Stock Item Drop Down ----
                ddlData.lst_Item = new List<string>();
                ddlData.lst_Item.Add("select");
                sql = "Select Distinct Upper(StockItemName) as [ItemName]  from TD_Mst_StockItem Where CompanyID=" + CompanyID + " order by ItemName";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_Item.Add(Common.GetString(rdr["ItemName"]));
                }
                rdr.Close();

                //--- Purchase Order Number ----
                ddlData.lst_PONumber = new List<string>();
                ddlData.lst_PONumber.Add("select");
                sql = "Select VoucherNo  from TD_Txn_VchHdr where CompanyID = " + CompanyID + " And IsDeleted = 0  and VoucherTypeName Like 'Purchase Order%'  Order by Date desc";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_PONumber.Add(Common.GetString(rdr["VoucherNo"]));
                }
                rdr.Close();

                //--- Cost Center ----
                ddlData.lst_CostCenter = new List<string>();
                ddlData.lst_CostCenter.Add("select");
                sql = "Select Upper(CostCentreName) as [CostCentreName] FROM  TD_Mst_CostCentre where CompanyID=" + CompanyID + " Order by CostCentreName";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_CostCenter.Add(Common.GetString(rdr["CostCentreName"]));
                }
                rdr.Close();

                //--- HQ ----
                ddlData.lst_HQ = new List<string>();
                ddlData.lst_HQ.Add("select");
                sql = "Select Distinct Upper(LedgerName) as [HQ] FROM  TD_Txn_AccLine where CompanyID=" + CompanyID + " Order by HQ";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_HQ.Add(Common.GetString(rdr["HQ"]));
                }
                rdr.Close();

                //--- Voucher Type ----
                ddlData.lst_VoucherType = new List<string>();
                ddlData.lst_VoucherType.Add("select");
                sql = "Select Distinct Upper(VoucherType) as [VoucherType] FROM  TD_Mst_VoucherType where CompanyID=" + CompanyID + " Order by VoucherType";
                cmd = new SqlCommand(sql, Common.conn);
                rdr = cmd.ExecuteReader();
                while (rdr.Read())
                {
                    ddlData.lst_VoucherType.Add(Common.GetString(rdr["VoucherType"]));
                }
                rdr.Close();

            }


        }
        catch (Exception ex)
        {
        }
        finally
        {
            Common.CloseConnection();
        }

        return ddlData;
    }

    public List<String> Common_BindStockItemByCategory(string CompanyName, string Categories)
    {
        Int32? CompanyID = 0;
        Search_DropdownList ddlData = new Search_DropdownList();
        string sql = string.Empty;
        SqlCommand cmd = null;
        SqlDataReader rdr = null;
        Common.OpenConnection();
        try
        {
            //---------- Get Company Id by Name
            sql = "Select CompanyID from TD_Mst_Company where CompanyName='" + CompanyName + "'";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                CompanyID = Convert.ToInt32(Common.GetString(rdr["CompanyID"]));
            }

            rdr.Close();

            //--- Stock Item Drop Down ----
            ddlData.lst_Item = new List<string>();
            ddlData.lst_Item.Add("select");
            sql = "Select Distinct Upper(StockItemName) as [ItemName]  from TD_Mst_StockItem Where CompanyID=" + CompanyID + " And StockCategory In ("+ Categories  + ") order by ItemName";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_Item.Add(Common.GetString(rdr["ItemName"]));
            }
            rdr.Close();
        }

        catch (Exception ex)
        {
        }
        finally
        {
            Common.CloseConnection();
        }

        return ddlData.lst_Item;
    }

    public List<String> Common_BindStockItemByStockGroup(string CompanyName, string Groups)
    {
        Int32? CompanyID = 0;
        Search_DropdownList ddlData = new Search_DropdownList();
        string sql = string.Empty;
        SqlCommand cmd = null;
        SqlDataReader rdr = null;
        Common.OpenConnection();
        try
        {
            //---------- Get Company Id by Name
            sql = "Select CompanyID from TD_Mst_Company where CompanyName='" + CompanyName + "'";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                CompanyID = Convert.ToInt32(Common.GetString(rdr["CompanyID"]));
            }

            rdr.Close();

            //--- Stock Item Drop Down ----
            ddlData.lst_Item = new List<string>();
            ddlData.lst_Item.Add("select");
            sql = "Select Distinct Upper(StockItemName) as [ItemName]  from TD_Mst_StockItem Where CompanyID=" + CompanyID + " And StockGroup In (" + Groups + ") order by ItemName";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_Item.Add(Common.GetString(rdr["ItemName"]));
            }
            rdr.Close();
        }

        catch (Exception ex)
        {
        }
        finally
        {
            Common.CloseConnection();
        }

        return ddlData.lst_Item;
    }

    public List<String> Common_BindStockGroupByGodown(string CompanyName, string Godowns)
    {
        Int32? CompanyID = 0;
        Search_DropdownList ddlData = new Search_DropdownList();
        string sql = string.Empty;
        SqlCommand cmd = null;
        SqlDataReader rdr = null;
        Common.OpenConnection();
        try
        {
            //---------- Get Company Id by Name
            sql = "Select CompanyID from TD_Mst_Company where CompanyName='" + CompanyName + "'";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                CompanyID = Convert.ToInt32(Common.GetString(rdr["CompanyID"]));
            }

            rdr.Close();

            //--- Stock group Drop Down ----
            ddlData.lst_StockGroup = new List<string>();
            ddlData.lst_StockGroup.Add("select");
            sql = "Select Distinct Upper(StockGroupName) as [StockGroupName]  from TD_Mst_Godown_Stockgroup Where CompanyID=" + CompanyID + " And GodownName In (" + Godowns + ") order by StockGroupName";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_StockGroup.Add(Common.GetString(rdr["StockGroupName"]));
            }
            rdr.Close();
        }

        catch (Exception ex)
        {
        }
        finally
        {
            Common.CloseConnection();
        }

        return ddlData.lst_StockGroup;
    }

    #endregion

    #region -- Common SQL Fetch Function --
    public string GetRDLCReportSQL(string ReportName)
    {
        string SQLQuery = string.Empty;
        string RDLCReportSQL = string.Empty;
        try
        {
            //---------- Get Company Id by Name
            SQLQuery = "SELECT ReportSQLQuery FROM  RDLCReportQuery where IsActive=1 And  ReportName ='" + ReportName + "'";
            Common.OpenConnection();
            SqlCommand cmd = new SqlCommand(SQLQuery, Common.conn);
            SqlDataReader rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                RDLCReportSQL = Common.GetString(rdr["ReportSQLQuery"]);
            }
        }
        catch (Exception ex)
        {
        }
        finally
        {
            Common.CloseConnection();
        }
        return RDLCReportSQL;
    }

    #endregion

    #endregion

    #region -- Lead Time Report --

    #region Bind Drop Down
    public LeadTime_Dropdown GetDropdownData()
    {
        LeadTime_Dropdown ddlData = new LeadTime_Dropdown();
        Common.OpenConnection();
        try
        {
            //--- Party Drop Down ----
            ddlData.lst_PartyName = new List<string>();
            ddlData.lst_PartyName.Add("select");

            String sql = "Select distinct PartyName from TD_Txn_VchHdr where Len(PartyName)>2 order by PartyName ";
            SqlCommand cmd = new SqlCommand(sql, Common.conn);
            SqlDataReader rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_PartyName.Add(Common.GetString(rdr["PartyName"]));
            }
            rdr.Close();


            //--- lst_StockItemName Drop Down ----
            ddlData.lst_StockItemName = new List<string>();
            ddlData.lst_StockItemName.Add("select");
            sql = "select distinct StockItemName from TD_Txn_InvLine where Len(StockItemName)>2 order by StockItemName";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_StockItemName.Add(Common.GetString(rdr["StockItemName"]));
            }
            rdr.Close();
        }
        catch (Exception ex)
        {
        }
        finally
        {
            Common.CloseConnection();
        }

        return ddlData;
    }
    #endregion

    #region Get Report Search Data ---
    public DataSet GetLeadTimeReportData(LeadTime_Search repParamSearch)
    {
        try
        {
            LeadTime_Report_List lstLeadTimeReport = new LeadTime_Report_List();
            Common.OpenConnection();
            String strSQL = "select * from View_Report_LeadTime";
            string WhSQL = "";
            string strconcat = "";

            if (repParamSearch.PartyName != null && repParamSearch.PartyName != "" && repParamSearch.PartyName != "select")
            {
                WhSQL = WhSQL + strconcat + "popartyname In (" + repParamSearch.PartyName + ")";
                strconcat = " and ";
            }

            if (repParamSearch.ItemName != null && repParamSearch.ItemName != "" && repParamSearch.ItemName != "select")
            {
                WhSQL = WhSQL + strconcat + "POStockItemName In (" + repParamSearch.ItemName + ")";
                strconcat = " and ";
            }
            //--------------- PO Date -------------------
            if (repParamSearch.StartDate_PO != null && repParamSearch.StartDate_PO != "")
            {
                WhSQL = WhSQL + strconcat + " PODate>='" + repParamSearch.StartDate_PO + "'";
                strconcat = " and ";
            }
            if (repParamSearch.EndtDate_PO != null && repParamSearch.EndtDate_PO != "")
            {
                WhSQL = WhSQL + strconcat + " PODate<='" + repParamSearch.EndtDate_PO + "'";
                strconcat = " and ";
            }
            //--------------- GRN Date -------------------
            if (repParamSearch.StartDate_GRN != null && repParamSearch.StartDate_GRN != "")
            {
                WhSQL = WhSQL + strconcat + " GRNDate>='" + repParamSearch.StartDate_GRN + "'";
                strconcat = " and ";
            }
            if (repParamSearch.EndtDate_GRN != null && repParamSearch.EndtDate_GRN != "")
            {
                WhSQL = WhSQL + strconcat + " GRNDate<='" + repParamSearch.EndtDate_GRN + "'";
                strconcat = " and ";
            }
            //--------------- Invoice Date -------------------
            if (repParamSearch.StartDate_Invoice != null && repParamSearch.StartDate_Invoice != "")
            {
                WhSQL = WhSQL + strconcat + " InvoiceDate>='" + repParamSearch.StartDate_Invoice + "'";
                strconcat = " and ";
            }
            if (repParamSearch.EndtDate_Invoice != null && repParamSearch.EndtDate_Invoice != "")
            {
                WhSQL = WhSQL + strconcat + " InvoiceDate<='" + repParamSearch.EndtDate_Invoice + "'";
                strconcat = " and ";
            }

            if (WhSQL != null && WhSQL != "")
                strSQL = strSQL + " where " + WhSQL;

            strSQL += " Order by podate, popartyname, POStockItemName";

            SqlCommand cmd = new SqlCommand(strSQL, Common.conn);
            DataSet dsLeadTime = new DataSet();
            using (SqlDataAdapter sda = new SqlDataAdapter())
            {
                sda.SelectCommand = cmd;
                sda.Fill(dsLeadTime, "rpt_LeadTime");
            }
            return dsLeadTime;
        }
        catch (Exception ex)
        {
            return null;
        }

    }
    #endregion

    #endregion

    #region --- Final Product Stock --
    public DataSet BuildReportData_FinalProductStock(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("FinalProductStock");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@DateTo", "'" + repParamSearch.EndDate + "'");

        strSQL = "";
        if (repParamSearch.GodownName_Source is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.GodownName_Source.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@GodownName_List", strSQL);

        strSQL = "";
        if (repParamSearch.StockGroup is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.StockGroup.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockGroup_List", strSQL);


        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockItemName_List", strSQL);


        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsFinalProductStock = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsFinalProductStock, "rpt_FinalProductStock");
        }
        return dsFinalProductStock;
    }

    #endregion

    #region --- Final Lead Time --
    public DataSet BuildReportData_LeadTimeReport(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("LeadTimeReport");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);

        RDLCReportSQL = RDLCReportSQL.Replace("@PO_DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@PO_DateTo", "'" + repParamSearch.EndDate + "'");

        RDLCReportSQL = RDLCReportSQL.Replace("@GRN_DateFrom", "'" + repParamSearch.StartDate_GRN + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@GRN_DateTo", "'" + repParamSearch.EndDate_GRN + "'");

        RDLCReportSQL = RDLCReportSQL.Replace("@Invoice_DateFrom", "'" + repParamSearch.StartDate_Invoice + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@Invoice_DateTo", "'" + repParamSearch.EndDate_Invoice + "'");

        strSQL = "";
        if (repParamSearch.PartyName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.PartyName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@PartyName_List", strSQL);


        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockItemName_List", strSQL);


        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsLeadTime = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsLeadTime, "rpt_dsLeadTime");
        }
        return dsLeadTime;
    }

    #endregion

    #region --- Pending Purchase Order Report --
    public DataSet BuildReportData_PendingPO(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("PendingPurchaseOrder");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyIDs", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@PO_DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@PO_DateTo", "'" + repParamSearch.EndDate + "'");

        if (repParamSearch.PartyName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.PartyName.Replace("'", "") + "'";
        }

        RDLCReportSQL = RDLCReportSQL.Replace("@PartyName_List", strSQL);
        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@ItemName_List", strSQL);

        strSQL = "";
        if (repParamSearch.PONumber is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.PONumber.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@PONo_List", strSQL);


        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsPendingPO = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsPendingPO, "rpt_PendingPO");
        }
        return dsPendingPO;
    }

    #endregion

    #region --- VendorOutstanding --
    public DataSet BuildReportData_VendorOutstanding(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("VendorOutstandingReport");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@DateTo", "'" + repParamSearch.EndDate + "'");

        if (repParamSearch.PartyName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.PartyName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@PartyName_List", strSQL);


        strSQL = "";
        if (repParamSearch.CostCenter is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.CostCenter.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@CostCenter_List", strSQL);
      

        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsVendorOutstanding = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsVendorOutstanding, "rpt_VendorOutstanding");
        }
        return dsVendorOutstanding;
    }

    #endregion

    #region --- Godown Stock Transfer Report --
    public DataSet BuildReportData_GodownStockTransfer(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("GodownStockTransfer");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@DateTo", "'" + repParamSearch.EndDate + "'");

        if (repParamSearch.StockCategory is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.StockCategory.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockCategory_List", strSQL);


        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockItemName_List", strSQL);


        strSQL = "";
        if (repParamSearch.GodownName_Source is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.GodownName_Source.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@GodownName_Source_List", strSQL);

        strSQL = "";
        if (repParamSearch.GodownName_Destination is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.GodownName_Destination.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@GodownName_Destination_List", strSQL);


        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsGodownStockTransfer = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsGodownStockTransfer, "rpt_GodownStockTransfer");
        }
        return dsGodownStockTransfer;
    }

    #endregion

    #region --- Godown Stock Summary Report --
    public DataSet BuildReportData_GodownStockSummary(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("GodownStockSummary");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@DateTo", "'" + repParamSearch.EndDate + "'");

        if (repParamSearch.GodownName_Source is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.GodownName_Source.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@GodwnName_List", strSQL);


        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockItemName_List", strSQL);


        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsGodownStockSummary = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsGodownStockSummary, "rpt_GodownStockSummary");
        }
        return dsGodownStockSummary;
    }

    #endregion

    #region --- Pending Purchase Bill --
    public DataSet BuildReportData_PendingPurchaseBill(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("PendingPurchaseBill");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@DateTo", "'" + repParamSearch.EndDate + "'");

        strSQL = "";
        if (repParamSearch.PartyName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.PartyName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@PartyName_List", strSQL);

        strSQL = "";
        if (repParamSearch.StockGroup is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.StockGroup.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockGroupName_List", strSQL);


        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockItemName_List", strSQL);


        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsPendingPurchaseBill = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsPendingPurchaseBill, "Report_PendingPurchaseBill");
        }
        return dsPendingPurchaseBill;
    }

    #endregion

    #region --- Pending Sales Bill --
    public DataSet BuildReportData_PendingSalesBill(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("PendingSalesBill");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@DateTo", "'" + repParamSearch.EndDate + "'");

        strSQL = "";
        if (repParamSearch.GodownName_Source is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.GodownName_Source.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@DepotName_List", strSQL);

        strSQL = "";
        if (repParamSearch.HQ is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.HQ.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@HQName_List", strSQL);


        strSQL = "";
        if (repParamSearch.StockGroup is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.StockGroup.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockGroupName_List", strSQL);


        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockItemName_List", strSQL);


        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsPendingSalesBill = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsPendingSalesBill, "Report_PendingSalesBill");
        }
        return dsPendingSalesBill;
    }

    #endregion

    #region --- Godown Stock Transfer Report --
    public DataSet BuildReportData_StockDetails(Report_Search repParamSearch)
    {
        string RDLCReportSQL = string.Empty;
        string strSQL = string.Empty;
        RDLCReportSQL = GetRDLCReportSQL("StockDetails");


        //--------- Replace Query with Paaramenter Value -----
        RDLCReportSQL = RDLCReportSQL.Replace("@CompanyNames", repParamSearch.CompanyName);
        RDLCReportSQL = RDLCReportSQL.Replace("@DateFrom", "'" + repParamSearch.StartDate + "'");
        RDLCReportSQL = RDLCReportSQL.Replace("@DateTo", "'" + repParamSearch.EndDate + "'");

        if (repParamSearch.StockCategory is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.StockCategory.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockCategoryName_List", strSQL);


        strSQL = "";
        if (repParamSearch.ItemName is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.ItemName.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@StockItemName_List", strSQL);


        strSQL = "";
        if (repParamSearch.VoucherType is null)
        {
            strSQL += "''" + "";
        }
        else
        {
            strSQL += "'" + repParamSearch.VoucherType.Replace("'", "") + "'";
        }
        RDLCReportSQL = RDLCReportSQL.Replace("@VoucherType_List", strSQL);



        SqlCommand cmd = new SqlCommand(RDLCReportSQL, Common.conn);
        DataSet dsStockDetails = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsStockDetails, "Report_StockDetails");
        }
        return dsStockDetails;
    }

    #endregion

}