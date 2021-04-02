<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeFile="DebitCreditNoteRegister.aspx.cs" Inherits="OnlineReport_DebitCreditNoteRegister" %>

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
                            <h2 style="text-align: center">Debit Credit Note Register</h2>
                        </div>
                    </div>
                </div>

                <div class="panel panel-info">
                    <div class="panel-body">
                        <div class="row">
                            <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>From Date</label>
                                    <asp:TextBox ID="dtFromDate" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="txttodate_CalendarExtender" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtFromDate" />
                                </div>
                            </div>

                            <div class="form-group col-md-2">
                                <div class="form-group">
                                    <label>To Date</label>
                                    <asp:TextBox ID="dtToDate" runat="server"></asp:TextBox>
                                    <asp:CalendarExtender ID="dtToDate_CalendarExtender1" runat="server" Format="dd/MM/yyyy"
                                        TargetControlID="dtToDate" />
                                </div>
                            </div>

                            <div class="form-group col-md-8">
                                <div class="form-group">
                                    <label>Company</label>
                                    <asp:ListBox ID="lbCompany" runat="server" AutoPostBack="true" Width="75%" OnSelectedIndexChanged="lbCompany_SelectedIndexChanged"></asp:ListBox>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="form-group col-md-3">
                                <div class="form-group">
                                    <label>Voucher Type</label>
                                    <asp:ListBox ID="lbVoucherType" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                                </div>
                            </div>

                            <div class="form-group col-md-3">
                                <div class="form-group">
                                    <label>Party Name</label>
                                    <asp:ListBox ID="lbVendorName" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
                                </div>
                            </div>

                            <div class="form-group col-md-3">
                                <div class="form-group">
                                    <label>Stock Item Name</label>
                                    <asp:ListBox ID="lbStockItemName" runat="server" SelectionMode="Multiple" Width="75%"></asp:ListBox>
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
                            <LocalReport ReportPath="rdlcs\Accounts\Report_DebitCreditNoteRegister.rdlc">
                            </LocalReport>
                        </rsweb:ReportViewer>
                    </div>
                </div>

            </div>

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

                        $('[id*=lbVoucherType]').multiselect({
                            includeSelectAllOption: true,
                            maxHeight: 400,
                            enableFiltering: true,
                            enableCaseInsensitiveFiltering: true
                        });

                        $('[id*=lbVendorName]').multiselect({
                            includeSelectAllOption: true,
                            maxHeight: 400,
                            enableFiltering: true,
                            enableCaseInsensitiveFiltering: true
                        });

                        $('[id*=lbStockItemName]').multiselect({
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

