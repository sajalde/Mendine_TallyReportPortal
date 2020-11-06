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
using Microsoft.Reporting.WebForms;
using static ReportModel;

public partial class OnlineReport_PendingPurchaseOrder : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        if (!Page.IsPostBack)
        {
            PopulateSearchDropdowns(null);
            DateTime d = DateTime.Now;
            d = d.AddMonths(-2);

            Session["StartDate"] = d.ToString("MM/dd/yyyy");
            Session["EndDate"] = DateTime.Now.ToString("MM/dd/yyyy");
            //_dtFromDate
            //generate report
            Report_Search repParamSearch = new Report_Search();
            ReportViewer1.Visible = false;
        }
        else
        {
            // Set From and To Date From Session Variable

        }
    }

    protected void lbCompany_SelectedIndexChanged(object sender, EventArgs e)
    {

        PopulateSearchDropdowns(lbCompany.SelectedValue);
    }

    private void PopulateSearchDropdowns(string CompanyName)
    {
        Search_DropdownList objData = (new Report_DL()).Common_BindDropdownData(CompanyName);
        lbCompany.DataSource = objData.lst_Company;
        lbCompany.DataBind();

        lbPartyName.DataSource = objData.lst_Party;
        lbPartyName.DataBind();

        lbItemName.DataSource = objData.lst_Item;
        lbItemName.DataBind();

        lbPONumber.DataSource = objData.lst_PONumber;
        lbPONumber.DataBind();
    }

    private void GenerateRDLCReport(Report_Search repParamSearch)
    {
        ReportViewer1.Visible = true;
        ReportViewer1.ProcessingMode = ProcessingMode.Local;
        ReportViewer1.LocalReport.ReportPath = Server.MapPath("~/rdlcs/Report_PendingPurchaseOrder.rdlc");

        //DataSet dt = (new Report_DL()).GetReportData_PendingPO(repParamSearch);
        DataSet dt = (new Report_DL()).BuildReportData_PendingPO(repParamSearch);

        ReportViewer1.LocalReport.DataSources.Clear();
        ReportViewer1.LocalReport.DataSources.Add(new Microsoft.Reporting.WebForms.ReportDataSource()
        {
            Name = "dsPendingPO",
            Value = dt.Tables[0]
        });

        ReportViewer1.LocalReport.Refresh();
    }

    protected void btnSearch_Click(object sender, EventArgs e)
    {

        Report_Search repParamSearch = new Report_Search();
        repParamSearch.StartDate = Page.Request.Form["_dtFromDate"].ToString();
        repParamSearch.EndDate = Page.Request.Form["_dtToDate"].ToString();

        Session["StartDate"] = Page.Request.Form["_dtFromDate"].ToString();
        Session["EndDate"] = Page.Request.Form["_dtToDate"].ToString();

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

        //--- Party Name::  Multi Select List Box Values  Party Name--
        string strPartyName = string.Empty;
        foreach (ListItem item in lbPartyName.Items)
        {
            if (item.Selected)
            {
                strPartyName += "'" + item.Text + "'";
                strPartyName += ",";
            }
        }
        if (lbPartyName.SelectedIndex != -1)
        {
            repParamSearch.PartyName = strPartyName.Remove(strPartyName.Length - 1, 1);// Remove last , lbItemName.SelectedItem.Text;
        }

        //--- ItemName::  Multi Select List Box Values  ItemName--
        string strItemName = string.Empty;
        foreach (ListItem item in lbItemName.Items)
        {
            if (item.Selected)
            {
                strItemName += "'" + item.Text + "'";
                strItemName += ",";
            }
        }
        if (lbItemName.SelectedIndex != -1)
        {
            repParamSearch.ItemName = strItemName.Remove(strItemName.Length - 1, 1);// Remove last , lbItemName.SelectedItem.Text;
        }

        //--- Purchase Order No::  Multi Select List Box Values  PO Number--
        string strPONumber = string.Empty;
        foreach (ListItem item in lbPONumber.Items)
        {
            if (item.Selected)
            {
                strPONumber += "'" + item.Text + "'";
                strPONumber += ",";
            }
        }
        if (lbPONumber.SelectedIndex != -1)
        {
            repParamSearch.ItemName = strPONumber.Remove(strPONumber.Length - 1, 1);// Remove last , lbItemName.SelectedItem.Text;
        }


        bool blncontinue = true;

        if (blncontinue)
        {
            GenerateRDLCReport(repParamSearch);
        }
    }

    protected void btnReset_Click(object sender, EventArgs e)
    {
        Report_Search repParamSearch = new Report_Search();

        GenerateRDLCReport(repParamSearch);
        string FromDate = Request.Form["_dtFromDate"];


        lbCompany.SelectedIndex = -1;
        lbPartyName.SelectedIndex = -1;
        lbItemName.SelectedIndex = -1;
        lbPartyName.SelectedIndex = -1;
        lbPONumber.SelectedIndex = -1;
        //--- Set Current Date in Date Fileds Input Box

        lblmsg.Text = "";
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
        Response.AppendHeader("Content-Disposition", "attachment; filename=PendingPurchaseOrderReport." + extension);
        Response.BinaryWrite(bytes);
        Response.Flush();
        Response.End();
    }
}