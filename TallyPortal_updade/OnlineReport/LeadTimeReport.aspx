<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeFile="LeadTimeReport.aspx.cs" Inherits="OnlineReport_LeadTimeReport" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" Runat="Server">


   
   <script src="../lib/jquery-3.3.1.min.js"></script>
    <link href="../lib/bootstrap.min.css" rel="stylesheet" />
        <script src="../lib/bootstrap.min.js"></script>
    <link href="../lib/bootstrap-multiselect.css" rel="stylesheet" />
      <script src="../lib/bootstrap-multiselect.min.js"></script>


    <asp:UpdatePanel runat="server" ID="pnl_report">
        <ContentTemplate>

        <div style="height: 50px; text-align: center;">
            <h2>Lead Time Report</h2>
        </div>
        <%--<div style="text-align: right; padding-right: 50px; height: 50px;">
            <asp:LinkButton ID="lnklogout" runat="server" Text="Logout" OnClick="lnklogout_Click"></asp:LinkButton>
        </div>--%>
<div class="panel panel-default">
                            <div class="panel-body">
                                 <div id="wp" style="display : none; min-height : 200px; text-align : center; font-size : 22px; font-weight : bold;"> Please wait</div>
                                <div id="searchp" style="display : none;">

        <div style="padding-top: 10px; padding-bottom: 40px;">
            <asp:Label ID="lblmsg" runat="server" ForeColor="Red"></asp:Label>
        </div>

        <div id="adminsearch" style="visibility: visible">
            <table style="width: 100%">
                <tr>
                    <td colspan="2" style="text-align: center; font-weight: bold;">PO Date</td>
                    <td style="width: 15%; font-weight: bold;">Party Name</td>
                    <td style="width: 15% ; font-weight: bold;">Item Name</td>
                    <td colspan="2" style="text-align: center; font-weight: bold;">GRN Date</td>
                    <td colspan="2" style="text-align: center; font-weight: bold;">Invoice Date</td>
                </tr>
                <tr>
                    <td style="width: 12%">From &nbsp;
                       <%--  <input type="text" id="dtFromDate_PO" name="_dtFromDate_PO" />--%>
                         <asp:TextBox ID="dtFromDate_PO" runat="server"></asp:TextBox>
                          <asp:CalendarExtender ID="CalendarExtender4" runat="server" Format="dd/MM/yyyy"
                    TargetControlID="dtFromDate_PO" />
                    </td>
                    <td style="width: 12%">To &nbsp;
                        <%-- <input type="text" id="dtToDate_PO" name="_dtToDate_PO" />--%>

                         <asp:TextBox ID="dtToDate_PO" runat="server"></asp:TextBox>
                          <asp:CalendarExtender ID="CalendarExtender5" runat="server" Format="dd/MM/yyyy"
                    TargetControlID="dtToDate_PO" />
                    </td>

                    <td style="width: 15%">
                        <asp:ListBox ID="lbPartyName" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                    </td>
                    <td style="width: 15%">
                        <asp:ListBox ID="lbItemName" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                    </td>

                    <td style="width: 12%">From &nbsp;
                        <%-- <input type="text" id="dtFromDate_GRN" name="_dtFromDate_GRN" />--%>

                         <asp:TextBox ID="dtFromDate_GRN" runat="server"></asp:TextBox>
                          <asp:CalendarExtender ID="txttodate_CalendarExtender" runat="server" Format="dd/MM/yyyy"
                    TargetControlID="dtFromDate_GRN" />
                    </td>
                    <td style="width: 12%">To &nbsp;

                        <%-- <input type="text" id="dtToDate_GRN" name="_dtToDate_GRN" />--%>

                        <asp:TextBox ID="dtToDate_GRN" runat="server"></asp:TextBox>
                          <asp:CalendarExtender ID="CalendarExtender1" runat="server" Format="dd/MM/yyyy"
                    TargetControlID="dtToDate_GRN" />
                    </td>

                    <td style="width: 12%">From &nbsp;
                         <%--<input type="text" id="dtFromDate_Invoice" name="_dtFromDate_Invoice" />--%>
                           <asp:TextBox ID="dtFromDate_Invoice" runat="server"></asp:TextBox>
                          <asp:CalendarExtender ID="CalendarExtender2" runat="server" Format="dd/MM/yyyy"
                    TargetControlID="dtFromDate_Invoice" />
                    </td>
                    <td style="width: 12%">To &nbsp;
                       <%--  <input type="text" id="dtToDate_Invoice" name="_dtToDate_Invoice" />--%>

                           <asp:TextBox ID="dtToDate_Invoice" runat="server"></asp:TextBox>
                          <asp:CalendarExtender ID="CalendarExtender3" runat="server" Format="dd/MM/yyyy"
                    TargetControlID="dtToDate_Invoice" />
                    </td>
                </tr>
                <tr>
                    <td style="padding-top: 40px;" colspan="2"></td>
                    <td style="text-align: center">
                        <asp:Button ID="btnSearch" runat="server" Text="Search" Width="90%" Height="35px" BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnSearch_Click" />
                    </td>
                    <td style="text-align: center">
                        <asp:Button ID="btnReset" runat="server" Text="Reset" Width="90%" Height="35px" BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnReset_Click" />
                    </td>
                    <td>
                        <asp:Button ID="btnExporttoCSV" runat="server" Text="Export to CSV" Width="90%" Height="35px" BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnExporttoCSV_Click" />
                    </td>
                    <td></td>
                </tr>
            </table>
        </div>
        <div style="height: 30px;">
        </div>
</div>
                                </div>
    </div>
     <rsweb:ReportViewer ID="ReportViewer1" runat="server" BackColor="" ClientIDMode="AutoID" HighlightBackgroundColor="" InternalBorderColor="204, 204, 204" InternalBorderStyle="Solid" InternalBorderWidth="1px" LinkActiveColor="" LinkActiveHoverColor="" LinkDisabledColor="" PrimaryButtonBackgroundColor="" PrimaryButtonForegroundColor="" PrimaryButtonHoverBackgroundColor="" PrimaryButtonHoverForegroundColor="" SecondaryButtonBackgroundColor="" SecondaryButtonForegroundColor="" SecondaryButtonHoverBackgroundColor="" SecondaryButtonHoverForegroundColor="" SplitterBackColor="" ToolbarDividerColor="" ToolbarForegroundColor="" ToolbarForegroundDisabledColor="" ToolbarHoverBackgroundColor="" ToolbarHoverForegroundColor="" ToolBarItemBorderColor="" ToolBarItemBorderStyle="Solid" ToolBarItemBorderWidth="1px" ToolBarItemHoverBackColor="" ToolBarItemPressedBorderColor="51, 102, 153" ToolBarItemPressedBorderStyle="Solid" ToolBarItemPressedBorderWidth="1px" ToolBarItemPressedHoverBackColor="153, 187, 226" Width="100%" Height="723px" AsyncRendering="False" InteractivityPostBackMode="AlwaysSynchronous" PageCountMode="Actual" ShowBackButton="False" ShowDocumentMapButton="False" ShowExportControls="False" ShowFindControls="False" ShowParameterPrompts="False" ShowPrintButton="False" ShowRefreshButton="False" ShowZoomControl="False">
         <LocalReport ReportPath="rdlcs\Report_FinalProductStock.rdlc">
            </LocalReport>
    </rsweb:ReportViewer>

       <%-- <rsweb:ReportViewer ID="ReportViewer1" runat="server" BackColor="" ClientIDMode="AutoID" HighlightBackgroundColor="" InternalBorderColor="204, 204, 204" InternalBorderStyle="Solid" InternalBorderWidth="1px" LinkActiveColor="" LinkActiveHoverColor="" LinkDisabledColor="" PrimaryButtonBackgroundColor="" PrimaryButtonForegroundColor="" PrimaryButtonHoverBackgroundColor="" PrimaryButtonHoverForegroundColor="" SecondaryButtonBackgroundColor="" SecondaryButtonForegroundColor="" SecondaryButtonHoverBackgroundColor="" SecondaryButtonHoverForegroundColor="" SplitterBackColor="" ToolbarDividerColor="" ToolbarForegroundColor="" ToolbarForegroundDisabledColor="" ToolbarHoverBackgroundColor="" ToolbarHoverForegroundColor="" ToolBarItemBorderColor="" ToolBarItemBorderStyle="Solid" ToolBarItemBorderWidth="1px" ToolBarItemHoverBackColor="" ToolBarItemPressedBorderColor="51, 102, 153" ToolBarItemPressedBorderStyle="Solid" ToolBarItemPressedBorderWidth="1px" ToolBarItemPressedHoverBackColor="153, 187, 226" Width="100%" Height="723px" AsyncRendering="False" InteractivityPostBackMode="AlwaysSynchronous" PageCountMode="Actual" ShowBackButton="False" ShowDocumentMapButton="False" ShowExportControls="False" ShowFindControls="False" ShowParameterPrompts="False" ShowPrintButton="False" ShowRefreshButton="False" ShowZoomControl="False">
            <LocalReport ReportPath="rdlcs\Report_FinalProductStock.rdlc">
            </LocalReport>
        </rsweb:ReportViewer>--%>
    </form>
</body>
<%--<script src="https://code.jquery.com/jquery-1.12.4.js"></script>
<script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>--%>

<%--<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>--%>
<%--<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.3/js/bootstrap.min.js"></script>
<script src="//cdn.rawgit.com/davidstutz/bootstrap-multiselect/master/dist/js/bootstrap-multiselect.js"
    type="text/javascript"></script>--%>

<script type="text/javascript">  
    $(function () {
        $("#dtFromDate_PO").datepicker();
        $("#dtToDate_PO").datepicker();
        $("#dtFromDate_GRN").datepicker();
        $("#dtToDate_GRN").datepicker();
        $("#dtFromDate_Invoice").datepicker();
        $("#dtToDate_Invoice").datepicker();
    });
</script>

<script type="text/javascript">  
    function pageLoad(sender, args) {
        $(document).ready(function () {
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
            setTimeout(function () {
                window.document.getElementById('wp').style.display = 'none';
                window.document.getElementById('searchp').style.display = '';
            }, 100);
        });
    }
</script>


 </ContentTemplate>
 
  <Triggers>
            <asp:PostBackTrigger ControlID="btnSearch" />
			 <asp:PostBackTrigger ControlID="btnReset" />
			  <asp:PostBackTrigger ControlID="btnExporttoCSV" />
        </Triggers>
    </asp:UpdatePanel>

</asp:Content>

