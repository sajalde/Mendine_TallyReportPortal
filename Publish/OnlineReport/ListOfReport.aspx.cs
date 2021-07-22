using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Web.Security;
using System.Data.SqlClient;
using ReportRDLC.models;

public partial class OnlineReport_ListOfReport : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (Session["username"] == null)
        {
            Session.Abandon();
            FormsAuthentication.SignOut();
            //or use Response.Redirect to go to a different page
            FormsAuthentication.RedirectToLoginPage();
            Response.Redirect("~/Account/Login.aspx");

        }
        else
        {
            string ReportModule = string.Empty;
            string ReportName = string.Empty;
            string ReportDisplayName = string.Empty;
            string ReportURL = string.Empty;

            string SelectedModule = Request.QueryString["id"];

            string sql = string.Empty;
            SqlCommand cmd = null;
            SqlDataReader rdr = null;
            Common.OpenConnection();
            if (SelectedModule != null)
            {
                sql = "select ReportModule, ReportName, ReportDisplayName,ReportURL, Status from RDLCReportQuery where IsActive=1 And ReportModule='"+ SelectedModule +"' order by ReportModule, ViewOrder";
            }
            else
            {
                sql = "select ReportModule, ReportName, ReportDisplayName,ReportURL, Status from RDLCReportQuery where IsActive=1 order by ReportModule, ViewOrder";
            }
            cmd = new SqlCommand(sql, Common.conn);
            rdr = cmd.ExecuteReader();
            while (rdr.Read())
            {
                ReportModule = Common.GetString(rdr["ReportModule"]);
                ReportName = Common.GetString(rdr["ReportName"]);
                ReportDisplayName = Common.GetString(rdr["ReportDisplayName"]);
                ReportURL = Common.GetString(rdr["ReportURL"]);


                //string LinkLI="<asp:HyperLink ID='tall"+ Common.GetString(rdr["CompanyName"]) + "' runat='server' NavigateUrl='~/OnlineReport/FinalProductStock.aspx'>Final Product Stock Statement</asp:HyperLink>";
                // ddlData.lst_Company.Add(Common.GetString(rdr["CompanyName"]));
            }
            rdr.Close();
        }

    }
}