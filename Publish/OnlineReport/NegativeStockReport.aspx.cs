﻿using System;
using System.Collections.Generic;
using System.Data;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using iTextSharp.text.xml;
using Microsoft.Reporting.WebForms;
using static ReportModel;

public partial class OnlineReport_NegativeStockReport : System.Web.UI.Page
{
    protected void Page_Init(object sender, EventArgs e)
    {
    }
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            PopulateSearchDropdowns(null);
            DateTime d = DateTime.Now;

            d = d.AddMonths(-2);

            Session["StartDate"] = d.ToString("dd/MM/yyyy");
            Session["EndDate"] = DateTime.Now.ToString("dd/MM/yyyy");
            dtFromDate.Text = Session["StartDate"].ToString();
            dtToDate.Text = Session["EndDate"].ToString();
            //generate report
            Report_Search repParamSearch = new Report_Search();
            ReportViewer1.Visible = false;
        }
        else
        {
            var ControlObject = Request.Params[Page.postEventSourceID];
            var ControlFeature = Request.Params[Page.postEventArgumentID];
        }
    }

    protected void lbCompany_SelectedIndexChanged(object sender, EventArgs e)
    {
        PopulateSearchDropdowns(lbCompany.SelectedValue);
    }

    private void PopulateSearchDropdowns(string CompanyName)
    {
        string ComboName = "StockItem";
        Search_DropdownList objData = (new Report_DL()).Common_BindDropdownData(CompanyName, ComboName);
        lbCompany.DataSource = objData.lst_Company;
        lbCompany.DataBind();

        lbStockItemName.DataSource = objData.lst_Item;
        lbStockItemName.DataBind();
    }

    private void GenerateRDLCReport(Report_Search repParamSearch)
    {
        ReportViewer1.Visible = true;
        ReportViewer1.ProcessingMode = ProcessingMode.Local;
        ReportViewer1.LocalReport.ReportPath = Server.MapPath("~/rdlcs/Stock/Report_NegativeStockReport.rdlc");

        DataSet dt = (new Report_DL()).BuildReportData_NegativeStockReport(repParamSearch);
        if (dt.Tables.Count >= 1)
        {
            ReportViewer1.LocalReport.DataSources.Clear();
            ReportViewer1.LocalReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource()
            {
                Name = "dsNegativeStockReport",
                Value = dt.Tables[0]
            });
        }
        ReportViewer1.LocalReport.Refresh();
    }

    protected void btnSearch_Click(object sender, EventArgs e)
    {
        if (lbCompany.SelectedIndex == -1)
        {
            string message = "Please Select Company Name from List !!";
            System.Text.StringBuilder sb = new System.Text.StringBuilder();
            sb.Append("<script type = 'text/javascript'>");
            sb.Append("window.onload=function(){");
            sb.Append("alert('");
            sb.Append(message);
            sb.Append("')};");
            sb.Append("</script>");
            ClientScript.RegisterClientScriptBlock(this.GetType(), "alert", sb.ToString());
        }
        else
        {
            Report_Search repParamSearch = new Report_Search();

            Thread.CurrentThread.CurrentCulture = new CultureInfo("en-GB");
            DateTime startDate = Convert.ToDateTime(dtFromDate.Text);
            DateTime enddate = Convert.ToDateTime(dtToDate.Text);

            repParamSearch.StartDate = startDate.ToString("MM/dd/yyyy");
            repParamSearch.EndDate = enddate.ToString("MM/dd/yyyy");

            Session["StartDate"] = repParamSearch.StartDate;
            Session["EndDate"] = repParamSearch.EndDate;

            //--- Company:: Multi Select List Box Values --
            string strCompany = string.Empty;
            foreach (ListItem item in lbCompany.Items)
            {
                if (item.Selected)
                {
                    strCompany += "'" + item.Text + "'";
                    strCompany += ",";
                }
            }
            if (lbCompany.SelectedIndex != -1)
            {
                repParamSearch.CompanyName = strCompany.Remove(strCompany.Length - 1, 1);// Remove last ,lbCompany.SelectedItem.Text;
            }           

            //--- StockItemName::  Multi Select List Box Values  Item--
            string strStockItemName = string.Empty;
            foreach (ListItem item in lbStockItemName.Items)
            {
                if (item.Selected)
                {
                    strStockItemName += "'" + item.Text + "'";
                    strStockItemName += ",";
                }
            }
            if (lbStockItemName.SelectedIndex != -1)
            {
                repParamSearch.ItemName = strStockItemName.Remove(strStockItemName.Length - 1, 1);// Remove last;
            }


            bool blncontinue = true;

            if (blncontinue)
            {
                GenerateRDLCReport(repParamSearch);
            }
        }
    }

    protected void btnReset_Click(object sender, EventArgs e)
    {
        Report_Search repParamSearch = new Report_Search();

        //GenerateRDLCReport(repParamSearch);
        string FromDate = Request.Form["_dtFromDate"];
        string ToDate = Request.Form["_dtToDate"];

        lbCompany.SelectedIndex = -1;
        lbStockItemName.SelectedIndex = -1;
        //--- Set Current Date in Date Fileds Input Box
        ReportViewer1.LocalReport.DataSources.Clear();
    }

    protected void btnExporttoCSV_Click(object sender, EventArgs e)
    {
        ExportCSVReport();
    }

    protected void ExportCSVReport()
    {
        Warning[] warnings;
        string[] streamIds;
        string contentType;
        string encoding;
        string extension;

        //Export the RDLC Report to Byte Array.
        byte[] bytes = ReportViewer1.LocalReport.Render("EXCEL", null, out contentType, out encoding, out extension, out streamIds, out warnings);

        //Download the RDLC Report in Word, Excel, PDF and Image formats.
        Response.Clear();
        Response.Buffer = true;
        Response.Charset = "";
        Response.Cache.SetCacheability(HttpCacheability.NoCache);
        Response.ContentType = contentType;
        Response.AppendHeader("Content-Disposition", "attachment; filename=Negative Stock Register" + extension);
        Response.BinaryWrite(bytes);
        Response.Flush();
        Response.End();
    }   
}