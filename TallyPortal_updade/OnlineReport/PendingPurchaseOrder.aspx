﻿<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeFile="PendingPurchaseOrder.aspx.cs" Inherits="OnlineReport_PendingPurchaseOrder" %>
<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>
<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" Runat="Server">
    



    <title>Pending Purchase Order Report</title>
     <asp:UpdatePanel runat="server" ID="pnl_report">
        <ContentTemplate>
   
    <script src="../lib/jquery-3.3.1.min.js"></script>
    <link href="../lib/bootstrap.min.css" rel="stylesheet" />
        <script src="../lib/bootstrap.min.js"></script>
    <link href="../lib/bootstrap-multiselect.css" rel="stylesheet" />
      <script src="../lib/bootstrap-multiselect.min.js"></script>


<body>
   
    <div id="wp" style="display : none; min-height : 200px; text-align : center; font-size : 22px; font-weight : bold;"> Please wait</div>
                                <div id="searchp" style="display : none;">
        <div style="height: 50px; text-align: center;">
            <h2>Pending Purchase Order Report</h2>
        </div>
        <%--<div style="text-align: right; padding-right: 50px; height: 50px;">
            <asp:LinkButton ID="lnklogout" runat="server" Text="Logout"></asp:LinkButton>
        </div>--%>


        <div style="padding-top: 10px; padding-bottom: 40px;">
            <asp:Label ID="lblmsg" runat="server" ForeColor="Red"></asp:Label>
        </div>

        <div id="adminsearch" style="visibility: visible">
            <table style="width: 100%">
                <tr>
                    <td style="width: 20%">Company</td>
                    <td colspan="2" style="text-align: center;">PO Date</td>
                    <td style="width: 20%">Party Name</td>
                    <td style="width: 20%">Stock Item</td>
                    <td style="width: 20%">Order No</td>
                </tr>
                <tr>
                    <td style="width: 20%">
                        <asp:ListBox ID="lbCompany" runat="server" AutoPostBack="true" Width="75%" SelectionMode="Multiple" OnSelectedIndexChanged="lbCompany_SelectedIndexChanged"></asp:ListBox>
                    </td>

                    <td style="width: 12%">From &nbsp;
                         <input type="text" id="dtFromDate" name="_dtFromDate" />
                    </td>

                    <td style="width: 12%">To &nbsp;
                         <input type="text" id="dtToDate" name="_dtToDate" />
                    </td>
                    <td style="width: 20%">
                        <asp:ListBox ID="lbPartyName" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                    </td>
                    <td style="width: 20%">
                        <asp:ListBox ID="lbItemName" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                    </td>
                    <td style="width: 20%">
                        <asp:ListBox ID="lbPONumber" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                    </td>
                </tr>

                <tr>
                    <td style="text-align: center">
                        <asp:Button ID="btnSearch" runat="server" Text="Search" Width="90%" Height="35px" BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnSearch_Click" />
                    </td>
                    <td style="text-align: center">
                        <asp:Button ID="btnReset" runat="server" Text="Reset" Width="90%" Height="35px" BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnReset_Click" />
                    </td>
                    <td>
                        <asp:Button ID="btnExporttoCSV" runat="server" Text="Export to Excel" Width="90%" Height="35px" BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnExporttoCSV_Click" />
                    </td>
                    <td></td>
                </tr>
            </table>
        </div>
       

       
        <rsweb:ReportViewer ID="ReportViewer1" runat="server" BackColor="" ClientIDMode="AutoID" HighlightBackgroundColor="" InternalBorderColor="204, 204, 204" InternalBorderStyle="Solid" InternalBorderWidth="1px" LinkActiveColor="" LinkActiveHoverColor="" LinkDisabledColor="" PrimaryButtonBackgroundColor="" PrimaryButtonForegroundColor="" PrimaryButtonHoverBackgroundColor="" PrimaryButtonHoverForegroundColor="" SecondaryButtonBackgroundColor="" SecondaryButtonForegroundColor="" SecondaryButtonHoverBackgroundColor="" SecondaryButtonHoverForegroundColor="" SplitterBackColor="" ToolbarDividerColor="" ToolbarForegroundColor="" ToolbarForegroundDisabledColor="" ToolbarHoverBackgroundColor="" ToolbarHoverForegroundColor="" ToolBarItemBorderColor="" ToolBarItemBorderStyle="Solid" ToolBarItemBorderWidth="1px" ToolBarItemHoverBackColor="" ToolBarItemPressedBorderColor="51, 102, 153" ToolBarItemPressedBorderStyle="Solid" ToolBarItemPressedBorderWidth="1px" ToolBarItemPressedHoverBackColor="153, 187, 226" Width="100%" Height="723px" AsyncRendering="False" InteractivityPostBackMode="AlwaysSynchronous" PageCountMode="Actual" ShowBackButton="False" ShowDocumentMapButton="False" ShowExportControls="False" ShowFindControls="False" ShowParameterPrompts="False" ShowPrintButton="False" ShowRefreshButton="False" ShowZoomControl="False">
            <LocalReport ReportPath="rdlcs\Report_PendingPurchaseOrder.rdlc">
            </LocalReport>
        </rsweb:ReportViewer>
    </div>
</body>


<script type="text/javascript">  
    $(function () {
        $("#dtFromDate").datepicker();
        $("#dtToDate").datepicker();
    });
</script>


<script type="text/javascript">  
    function pageLoad(sender, args) {
        $(document).ready(function () {
            var StartDate = '<%=Session["StartDate"]%>';
            $("#dtFromDate").val(StartDate);

            var EndDate = '<%=Session["EndDate"]%>';
            $("#dtToDate").val(EndDate);

            $('[id*=lbCompany]').multiselect({
                includeSelectAllOption: true,
                maxHeight: 400,
                enableFiltering: false,
                enableCaseInsensitiveFiltering: true
            });
            $('[id*=lbItemName]').multiselect({
                includeSelectAllOption: true,
                maxHeight: 400,
                enableFiltering: true,
                enableCaseInsensitiveFiltering: true
            });
            $('[id*=lbPartyName]').multiselect({
                includeSelectAllOption: true,
                maxHeight: 400,
                enableFiltering: true,
                enableCaseInsensitiveFiltering: true
            });
            $('[id*=lbPONumber]').multiselect({
                includeSelectAllOption: true,
                maxHeight: 400,
                enableFiltering: true,
                enableCaseInsensitiveFiltering: true
            });
            setTimeout(function () {
                 window.document.getElementById('wp').style.display = 'none';
                  window.document.getElementById('searchp').style.display = '';
            }, 100);
        });
    }
    function ShowProgress() {
        setTimeout(function () {
            var modal = $('<div />');
            modal.addClass("modal");
            $('body').append(modal);
            var loading = $(".loading");
            loading.show();
            var top = Math.max($(window).height() / 2 - loading[0].offsetHeight / 2, 0);
            var left = Math.max($(window).width() / 2 - loading[0].offsetWidth / 2, 0);
            loading.css({ top: top, left: left });
        }, 100);
    }
    $('form').live("submit", function () {
        //ShowProgress();
    });
</script>

            

</ContentTemplate>
 
  <Triggers>
            <asp:PostBackTrigger ControlID="btnSearch" />
			 <asp:PostBackTrigger ControlID="btnReset" />
			  <asp:PostBackTrigger ControlID="btnExporttoCSV" />
        </Triggers>
    </asp:UpdatePanel>


</asp:Content>

