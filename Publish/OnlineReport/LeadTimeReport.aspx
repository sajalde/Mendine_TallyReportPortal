<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeFile="LeadTimeReport.aspx.cs" Inherits="OnlineReport_LeadTimeReport" %>
<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>
<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="Server">
    <script type="text/javascript" src="../lib/jquery-3.3.1.min.js"></script>
    <link href="../lib/bootstrap.min.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" src="../lib/bootstrap.min.js"></script>
    <link href="../lib/bootstrap-multiselect.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" src="../lib/bootstrap-multiselect.min.js"></script>

    <asp:UpdatePanel runat="server" ID="pnl_report">
        <ContentTemplate>
            <div class="card">
                <div class="card-body">
                    <div class="row">
                        <div class="col-12">
                            <h2 style="text-align: center">Lead Time Report</h2>
                        </div>
                    </div>
                </div>
                <div class="panel panel-info">
                    <div class="panel-body">
                        <div class="row">
                            <div class="form-group col-md-4">
                                <div class="form-group">
                                    <label>Company</label>
                                    <asp:ListBox ID="lbCompany" runat="server" AutoPostBack="true" Width="75%" OnSelectedIndexChanged="lbCompany_SelectedIndexChanged"></asp:ListBox>
                                </div>
                            </div>

                            <div class="form-group col-md-4">
                                <div class="form-group">
                                    <label>Party Name</label>
                                    <asp:ListBox ID="lbPartyName" runat="server" SelectionMode="Multiple" Width="75%" ></asp:ListBox>
                                </div>
                            </div>

                            <div class="form-group col-md-4">
                                <div class="form-group">
                                    <label>Stock Item Name</label>
                                    <asp:ListBox ID="lbItemName" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                                <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>PO Date From</label>
                                    <asp:TextBox ID="dtFromDate_PO" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="txttodate_CalendarExtender" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtFromDate_PO" />
                                </div>
                              </div>

                              <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>PO Date Upto</label>
                                    <asp:TextBox ID="dtToDate_PO" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="CalendarExtender1" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtToDate_PO" />
                                </div>
                              </div>
   
                                <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>GRN Date From</label>
                                    <asp:TextBox ID="dtFromDate_GRN" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="CalendarExtender2" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtFromDate_GRN" />
                                </div>
                              </div>

                              <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>GRN Date Upto</label>
                                    <asp:TextBox ID="dtToDate_GRN" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="CalendarExtender3" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtToDate_GRN" />
                                </div>
                              </div>

                                <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>Invoice Date From</label>
                                    <asp:TextBox ID="dtFromDate_Invoice" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="CalendarExtender4" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtFromDate_Invoice" />
                                </div>
                              </div>

                              <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>Invoice Date Upto</label>
                                    <asp:TextBox ID="dtToDate_Invoice" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="CalendarExtender5" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtToDate_Invoice" />
                                </div>
                              </div>

                        </div>

                    <div class="mb-4 mt-4">
                        <div class="m-4">
                            <div class="form-group mb-0 text-center">
                                <asp:Button ID="btnSearch" runat="server" Text="Show Report" class="btn btn-success waves-effect waves-light" OnClick="btnSearch_Click" />
                                <asp:Button ID="btnReset" runat="server" Text="Reset" class="btn btn-danger waves-effect waves-light" OnClick="btnReset_Click" />
                                <asp:Button ID="btnExporttoCSV" runat="server" Text="Export to Excel" class="btn btn-info waves-effect waves-light" OnClick="btnExporttoCSV_Click" />
                            </div>
                        </div>
                    </div>

                </div>
            </div>

            <div class="row">
                <div class="form-group col-md-12">
                <rsweb:ReportViewer ID="ReportViewer1" runat="server" BackColor="" ClientIDMode="AutoID" HighlightBackgroundColor="" InternalBorderColor="204, 204, 204" InternalBorderStyle="Solid" InternalBorderWidth="1px" LinkActiveColor="" LinkActiveHoverColor="" LinkDisabledColor="" PrimaryButtonBackgroundColor="" PrimaryButtonForegroundColor="" PrimaryButtonHoverBackgroundColor="" PrimaryButtonHoverForegroundColor="" SecondaryButtonBackgroundColor="" SecondaryButtonForegroundColor="" SecondaryButtonHoverBackgroundColor="" SecondaryButtonHoverForegroundColor="" SplitterBackColor="" ToolbarDividerColor="" ToolbarForegroundColor="" ToolbarForegroundDisabledColor="" ToolbarHoverBackgroundColor="" ToolbarHoverForegroundColor="" ToolBarItemBorderColor="" ToolBarItemBorderStyle="Solid" ToolBarItemBorderWidth="1px" ToolBarItemHoverBackColor="" ToolBarItemPressedBorderColor="51, 102, 153" ToolBarItemPressedBorderStyle="Solid" ToolBarItemPressedBorderWidth="1px" ToolBarItemPressedHoverBackColor="153, 187, 226" Width="100%" Height="723px" AsyncRendering="False" InteractivityPostBackMode="AlwaysSynchronous" PageCountMode="Actual" ShowBackButton="False" ShowDocumentMapButton="False" ShowExportControls="False" ShowFindControls="False" ShowParameterPrompts="False" ShowPrintButton="False" ShowRefreshButton="False" ShowZoomControl="False">
                    <LocalReport ReportPath="rdlcs\Report_LeadTime.rdlc">
                    </LocalReport>
                </rsweb:ReportViewer>
                </div>
            </div>

            </div>



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
                        var StartDate = '<%=Session["StartDate"]%>';
                        $("#dtFromDate_PO").val(StartDate);

                        var EndDate = '<%=Session["EndDate"]%>';
                        $("#dtToDate_PO").val(EndDate);

                        var StartDate_GRN = '<%=Session["StartDate_GRN"]%>';
                        $("#dtFromDate_GRN").val(StartDate_GRN);

                        var EndDate_GRN = '<%=Session["EndDate_GRN"]%>';
                        $("#dtToDate_GRN").val(EndDate_GRN);

                        var StartDate_Invoice = '<%=Session["StartDate_Invoice"]%>';
                        $("#dtFromDate_Invoice").val(StartDate_Invoice);

                        var EndDate_Invoice = '<%=Session["EndDate_Invoice"]%>';
                        $("#dtToDate_Invoice").val(EndDate_Invoice);

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

