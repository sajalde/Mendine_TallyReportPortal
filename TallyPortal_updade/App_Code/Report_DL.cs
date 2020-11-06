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

    #region -- FinalProductStock --

    #region Bind Drop Down
    public FinalProductStock_Dropdown GetDropdownData_FinalProductStock()
    {
        FinalProductStock_Dropdown ddlData = new FinalProductStock_Dropdown();
        Common.OpenConnection();
        try
        {
            //--- Company Drop Down ----
            ddlData.lst_Company = new List<string>();
            ddlData.lst_Company.Add("select");

            //String sql = "Select Distinct CompanyID from TD_Txn_StockDetails order by CompanyID";
            String sql = "Select CompanyID, Upper(CompanyName) as [CompanyName] from TD_Mst_Company order by CompanyName";
            SqlCommand cmd = new SqlCommand(sql, Common.conn);
            SqlDataReader rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                //ddlData.lst_Company.Add(Common.GetString(rdr["CompanyID"]));
                ddlData.lst_Company.Add(Common.GetString(rdr["CompanyName"]));
            }
            rdr.Close();


            //--- lst_StockItemName Drop Down ----
            ddlData.lst_StockItemName = new List<string>();
            ddlData.lst_StockItemName.Add("select");
            sql = "select distinct Upper(StockItemName) as [StockItemName] from TD_Txn_InvLine where Len(StockItemName)>2 order by StockItemName";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_StockItemName.Add(Common.GetString(rdr["StockItemName"]));
            }
            rdr.Close();

            //--- GodownName Drop Down ----
            ddlData.lst_GodownName = new List<string>();
            ddlData.lst_GodownName.Add("select");
            sql = "Select Distinct Upper(GodownName) as [GodownName] from tblGodownName order by GodownName";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_GodownName.Add(Common.GetString(rdr["GodownName"]));
            }
            rdr.Close();

            //--- StockGroup Drop Down ----
            ddlData.lst_StockGroup = new List<string>();
            ddlData.lst_StockGroup.Add("select");
            sql = "Select Distinct Upper(StockGroup) as [StockGroup] from TD_Mst_StockItem order by StockGroup";
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ddlData.lst_StockGroup.Add(Common.GetString(rdr["StockGroup"]));
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
    public DataSet GetReportData_FinalProductStock(FinalProductStock_Search repParamSearch)
    {
        LeadTime_Report_List lstLeadTimeReport = new LeadTime_Report_List();
        Common.OpenConnection();
        String strSQL = "";

        //strSQL += "SELECT  sd.CompanyID, sd.StockDate, sd.StockItemName, sd.GodownName, sd.BatchName, sd.Quantity, sd.UOM, sd.Rate, sd.Amount * -1 AS amount, SI.StockGroup ";
        //strSQL += "FROM     dbo.TD_Txn_StockDetails AS sd ";
        //strSQL += "INNER JOIN dbo.TD_Mst_StockItem AS SI ON sd.CompanyID = SI.CompanyID AND sd.StockItemName = SI.StockItemName ";

        strSQL += " SELECT c.CompanyName AS[CompanyID], sd.StockDate, sd.StockItemName, sd.GodownName, sd.BatchName, sd.Quantity, sd.UOM, sd.Rate, sd.Amount * -1 AS amount, SI.StockGroup";
        strSQL += " FROM  dbo.TD_Txn_StockDetails AS sd INNER JOIN dbo.TD_Mst_StockItem AS SI ON sd.CompanyID = SI.CompanyID AND sd.StockItemName = SI.StockItemName";
        strSQL += " Inner Join TD_Mst_Company as C On c.CompanyID = Sd.CompanyID";

        string WhSQL = "";
        string strconcat = "";

        if (repParamSearch.Company != null && repParamSearch.Company != "" && repParamSearch.Company != "select")
        {
            WhSQL = WhSQL + strconcat + " C.CompanyName In (" + repParamSearch.Company + ")";
            strconcat = " and ";
        }

        if (repParamSearch.StockGroup != null && repParamSearch.StockGroup != "" && repParamSearch.StockGroup != "select")
        {
            WhSQL = WhSQL + strconcat + " SI.StockGroup In (" + repParamSearch.StockGroup + ")";
            strconcat = " and ";
        }

        if (repParamSearch.GodownName != null && repParamSearch.GodownName != "" && repParamSearch.GodownName != "select")
        {
            WhSQL = WhSQL + strconcat + " sd.GodownName In (" + repParamSearch.GodownName + ")";
            strconcat = " and ";
        }

        if (repParamSearch.StartDate_StockDate != null && repParamSearch.StartDate_StockDate != "")
        {
            WhSQL = WhSQL + strconcat + " sd.StockDate>='" + repParamSearch.StartDate_StockDate + "'";
            strconcat = " and ";
        }
        //if (repParamSearch.StartDate_StockDate != null && repParamSearch.StartDate_StockDate != "")
        //{
        //    WhSQL = WhSQL + strconcat + " sd.StockDate<='" + repParamSearch.StartDate_StockDate + "'";
        //    strconcat = " and ";
        //}
        if (repParamSearch.EndDate_StockDate != null && repParamSearch.EndDate_StockDate != "")
        {
            WhSQL = WhSQL + strconcat + " sd.StockDate<='" + repParamSearch.EndDate_StockDate + "'";
            strconcat = " and ";
        }

        if (repParamSearch.ItemName != null && repParamSearch.ItemName != "" && repParamSearch.ItemName != "select")
        {
            WhSQL = WhSQL + strconcat + " sd.StockItemName In (" + repParamSearch.ItemName + ")";
            strconcat = " and ";
        }

        if (WhSQL != null && WhSQL != "")
            strSQL = strSQL + " where " + WhSQL;

        strSQL += " Order by CompanyID, StockDate, StockGroup, GodownName";

        SqlCommand cmd = new SqlCommand(strSQL, Common.conn);
        DataSet dsLeadTime = new DataSet();
        using (SqlDataAdapter sda = new SqlDataAdapter())
        {
            sda.SelectCommand = cmd;
            sda.Fill(dsLeadTime, "rpt_LeadTime");
        }
        return dsLeadTime;
    }
    #endregion

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



}