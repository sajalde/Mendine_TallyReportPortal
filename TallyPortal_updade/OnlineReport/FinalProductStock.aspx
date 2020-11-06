<%@ Page Title="Final Product Stock Report" Language="C#" AutoEventWireup="true" MasterPageFile="~/Site.master" CodeFile="FinalProductStock.aspx.cs" Inherits="OnlineReport_FinalProductStock" %>
<%@ Register assembly="Microsoft.ReportViewer.WebForms" namespace="Microsoft.Reporting.WebForms" tagprefix="rsweb" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>


<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" Runat="Server">



    <asp:UpdatePanel runat="server" ID="pnl_report">
        <ContentTemplate>
   
    <script src="../lib/jquery-3.3.1.min.js"></script>
    <link href="../lib/bootstrap.min.css" rel="stylesheet" />
        <script src="../lib/bootstrap.min.js"></script>
    <link href="../lib/bootstrap-multiselect.css" rel="stylesheet" />
      <script src="../lib/bootstrap-multiselect.min.js"></script>


 
        <div style="height:50px; text-align:center;">
            <h2>Final Product Stock Report</h2>
        </div>
      <%--  <div style="text-align:right; padding-right:50px;height:50px;">
            <asp:LinkButton ID="lnklogout" runat="server" Text="Logout"></asp:LinkButton>
        </div>--%>
 <%--<div class="panel panel-default">
                            <div class="panel-body">
                                 <div id="wp" style="display : none; min-height : 200px; text-align : center; font-size : 22px; font-weight : bold;"> Please wait</div>
                                <div id="searchp" style="display : none;">--%>
            <div id="wp" style="display : none; min-height : 200px; text-align : center; font-size : 22px; font-weight : bold;"> Please wait</div>
                                <div id="searchp" style="display : none;">

        <div style="padding-top:10px; padding-bottom:40px;">
            <asp:Label ID="lblmsg" runat="server" ForeColor="Red"></asp:Label>
        </div>

        <div id="adminsearch" style="visibility:visible">
            <table style="width:100%">
			<tr>
			<td colspan="17" style="text-align: center" class="style5">
                
                <asp:UpdateProgress ID="UpdateProgress1" AssociatedUpdatePanelID="pnl_report" runat="server">
                 <ProgressTemplate>
                <div style="margin:auto;     font-family:Trebuchet MS;filter:alpha(opacity=100);    opacity:1;     font-size:small;     vertical-align: middle; top: auto; position: absolute; right: auto; color: #FFFFFF;">
 <img alt="ajax-progress" src="../Image/ajax-progress.gif"></img>
 </div>
 </ProgressTemplate>
                </asp:UpdateProgress>
            </td>
			</tr>
                <tr>
    
                     <td colspan="2" style="text-align:left; width:20%; font-weight: bold; ">Stock Date</td>
                    <td style="width:20%; font-weight: bold;">Company</td>
                    <td style="width:20%; font-weight: bold;">Item Name</td>
                    <td style="width:20%; font-weight: bold;">Godown Name</td>
                    <td style="width:20%; font-weight: bold;">Stock Group</td>
                </tr>
                <tr>
                     <td style="width:10%">
                          <%--<input type="text" id="dtFromDate_StockDate" name="_dtFromDate_StockDate" /> --%>
                         <asp:TextBox ID="dtFromDate_StockDate" runat="server"></asp:TextBox>
                          <asp:CalendarExtender ID="txttodate_CalendarExtender" runat="server" Format="dd/MM/yyyy"
                    TargetControlID="dtFromDate_StockDate" />

                      
                    </td>
                                     <td style="width:10%">
                                        <%--  From &nbsp;--%>
                        
                        <%--  To &nbsp;
                         <input type="text" id="dtToDate_StockDate"  name="_dtToDate_StockDate" />--%>
                    </td>
                    <td style="width:20%">
                         <asp:ListBox ID="lbCompany" runat="server" SelectionMode="Multiple"  Width="75%"></asp:ListBox>
                    </td>
                    <td style="width:20%">
                        <asp:ListBox ID="lbItemName" runat="server" SelectionMode="Multiple"  Width="75%"></asp:ListBox>
                    </td>
                    <td style="width:20%">
                         <asp:ListBox ID="lbGodownName" runat="server" SelectionMode="Multiple"  Width="75%"></asp:ListBox>
                    </td>
                    <td style="width:20%">
                        <asp:ListBox ID="lbStockGroup" runat="server" SelectionMode="Multiple"  Width="75%"></asp:ListBox>
                    </td>
                </tr>

                <tr>
                    <td style="padding-top: 40px;" colspan="2"></td>
                    <td style="text-align:center">
                        <asp:Button ID="btnSearch" runat="server" Text="Search" Width="90%" Height="35px"  BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnSearch_Click"  />
                    </td>
                    <td style="text-align:center">
                        <asp:Button ID="btnReset" runat="server" Text="Reset" Width="90%" Height="35px"  BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnReset_Click" />
                    </td>
                    <td >
                        <asp:Button ID="btnExporttoCSV" runat="server" Text="Export to CSV" Width="90%" Height="35px" BackColor="#0066CC" Font-Bold="True" ForeColor="#CCFFFF" OnClick="btnExporttoCSV_Click"/>
                    </td>
                    <td></td>
                </tr>
            </table>
        </div>
       


                                      <rsweb:ReportViewer ID="ReportViewer1" runat="server" BackColor="" ClientIDMode="AutoID" HighlightBackgroundColor="" InternalBorderColor="204, 204, 204" InternalBorderStyle="Solid" InternalBorderWidth="1px" LinkActiveColor="" LinkActiveHoverColor="" LinkDisabledColor="" PrimaryButtonBackgroundColor="" PrimaryButtonForegroundColor="" PrimaryButtonHoverBackgroundColor="" PrimaryButtonHoverForegroundColor="" SecondaryButtonBackgroundColor="" SecondaryButtonForegroundColor="" SecondaryButtonHoverBackgroundColor="" SecondaryButtonHoverForegroundColor="" SplitterBackColor="" ToolbarDividerColor="" ToolbarForegroundColor="" ToolbarForegroundDisabledColor="" ToolbarHoverBackgroundColor="" ToolbarHoverForegroundColor="" ToolBarItemBorderColor="" ToolBarItemBorderStyle="Solid" ToolBarItemBorderWidth="1px" ToolBarItemHoverBackColor="" ToolBarItemPressedBorderColor="51, 102, 153" ToolBarItemPressedBorderStyle="Solid" ToolBarItemPressedBorderWidth="1px" ToolBarItemPressedHoverBackColor="153, 187, 226" Width="100%" Height="723px" AsyncRendering="False" InteractivityPostBackMode="AlwaysSynchronous" PageCountMode="Actual" ShowBackButton="False" ShowDocumentMapButton="False" ShowExportControls="False" ShowFindControls="False" ShowParameterPrompts="False" ShowPrintButton="False" ShowRefreshButton="False" ShowZoomControl="False">
            <LocalReport ReportPath="rdlcs\FinalProduct.rdlc">
            </LocalReport>
        </rsweb:ReportViewer>

      </div>
                               
            
      
   
 <%--</div>
     </div>--%>

<%--<script src="https://code.jquery.com/jquery-1.12.4.js"></script>
<script src="https://code.jquery.com/ui/1.12.1/jquery-ui.js"></script>--%>

<%--<script type="text/javascript" src="//ajax.googleapis.com/ajax/libs/jquery/1.8.3/jquery.min.js"></script>--%>
<%--<script type="text/javascript" src="//cdnjs.cloudflare.com/ajax/libs/twitter-bootstrap/3.0.3/js/bootstrap.min.js"></script>--%>
    <%--https://github.com/davidstutz/bootstrap-multiselect--%>
<%--<script src="//cdn.rawgit.com/davidstutz/bootstrap-multiselect/master/dist/js/bootstrap-multiselect.js"
    type="text/javascript"></script>--%>
            <%--<script src="../Content/libs/bootstrap-multiselect/bootstrap-multiselect.min.js"></script>--%>

<script type="text/javascript">  
    $(function () {
        $("#dtFromDate_StockDate").datepicker();
        $("#dtToDate_StockDate").datepicker();
    });
</script>

    <script type="text/javascript">  
        function pageLoad(sender, args) {
            $(document).ready(function () {
                $('[id*=lbCompany]').multiselect({
                    includeSelectAllOption: true,
                    maxHeight: 400,
                    enableFiltering: true,
                    enableCaseInsensitiveFiltering: true
                });
                $('[id*=lbItemName]').multiselect({
                    includeSelectAllOption: true,
                    maxHeight: 400,
                    enableFiltering: true,
                    enableCaseInsensitiveFiltering: true
                });
                $('[id*=lbGodownName]').multiselect({
                    includeSelectAllOption: true,
                    maxHeight: 400,
                    enableFiltering: true,
                    enableCaseInsensitiveFiltering: true
                });
                $('[id*=lbStockGroup]').multiselect({
                    includeSelectAllOption: true,
                    maxHeight: 400,
                    enableFiltering: true,
                    enableCaseInsensitiveFiltering: true
                });
              
            });
            setTimeout(function () {
                window.document.getElementById('wp').style.display = 'none';
                window.document.getElementById('searchp').style.display = '';
            }, 100);
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
