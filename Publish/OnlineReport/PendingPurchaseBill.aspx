﻿<%@ Page Title="" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true" CodeFile="PendingPurchaseBill.aspx.cs" Inherits="OnlineReport_PendingPurchaseBill" %>

<%@ Register Assembly="Microsoft.ReportViewer.WebForms" Namespace="Microsoft.Reporting.WebForms" TagPrefix="rsweb" %>

<%@ Register Assembly="AjaxControlToolkit" Namespace="AjaxControlToolkit" TagPrefix="asp" %>

<asp:Content ID="Content1" ContentPlaceHolderID="MainContent" runat="Server">

    <script type="text/javascript" src="../lib/jquery-3.3.1.min.js"></script>
    <link href="../lib/bootstrap.min.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" src="../lib/bootstrap.min.js"></script>
    <link href="../lib/bootstrap-multiselect.css" type="text/css" rel="stylesheet" />
    <script type="text/javascript" src="../lib/bootstrap-multiselect.min.js"></script>
    <link href="../css/customcontrol.css" type="text/css" rel="stylesheet" />

    <asp:UpdateProgress ID="UpdateProgress1" runat="server" AssociatedUpdatePanelID="pnl_report"
        ClientIDMode="Predictable" ViewStateMode="Inherit">
        <ProgressTemplate>
            <div class="divloader">
                <img alt="" src="loader.gif" />
            </div>
        </ProgressTemplate>
    </asp:UpdateProgress>

    <asp:UpdatePanel runat="server" ID="pnl_report">
        <ContentTemplate>
            <div class="card">
                <div class="card-body">
                    <div class="row">
                        <div class="col-12">
                            <h2 style="text-align: center">Pending Purchase Bill Report</h2>
                        </div>
                    </div>
                </div>

                <div class="panel panel-info">
                    <div class="panel-body">
                        <div class="row">
                            <div class="col-md-4">
                                <div class="form-group row">
                                    <label class="col-sm-4">Start Date</label>
                                    <div class="col-sm-8">
                                        <asp:TextBox ID="dtFromDate" runat="server" class="form-control"></asp:TextBox>
                                        <asp:CalendarExtender ID="txtfromdate_CalendarExtender" runat="server" Format="dd/MM/yyyy"
                                            TargetControlID="dtFromDate" />
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group row">
                                    <label class="col-sm-4">End Date</label>
                                    <div class="col-sm-8">
                                        <asp:TextBox ID="dtToDate" runat="server" class="form-control"></asp:TextBox>
                                        <asp:CalendarExtender ID="dtToDate_CalendarExtender" runat="server" Format="dd/MM/yyyy"
                                            TargetControlID="dtToDate" />
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group row">
                                    <label class="col-sm-4">Company</label>
                                    <div class="col-sm-8">
                                        <asp:ListBox ID="lbCompany" runat="server" AutoPostBack="true" OnSelectedIndexChanged="lbCompany_SelectedIndexChanged" class="form-control"></asp:ListBox>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="row">
                            <div class="col-md-4">
                                <div class="form-group row">
                                    <label class="col-sm-4">Vendor Name</label>
                                    <div class="col-sm-8">
                                        <asp:ListBox ID="lbVendorName" runat="server" SelectionMode="Multiple" class="form-control"></asp:ListBox>
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group row">
                                    <label class="col-sm-4">Stock Group</label>
                                    <div class="col-sm-8">
                                        <asp:ListBox ID="lbStockGroup" runat="server" SelectionMode="Multiple" class="form-control"></asp:ListBox>
                                    </div>
                                </div>
                            </div>

                            <div class="col-md-4">
                                <div class="form-group row">
                                    <label class="col-sm-4">Item Name</label>
                                    <div class="col-sm-8">
                                        <asp:ListBox ID="lbStockItemName" runat="server" SelectionMode="Multiple" class="form-control"></asp:ListBox>
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div class="mb-4 mt-4">
                            <div class="m-4">
                                <div class="form-group mb-0 text-center">
                                    <asp:Button ID="btnSearch" runat="server" Text="Show Report" class="btn btn-success waves-effect waves-light" OnClick="btnSearch_Click" />
                                    <asp:Button ID="btnReset" runat="server" Text="Reset" class="btn btn-danger waves-effect waves-light" OnClick="btnReset_Click" />
                                    <asp:Button ID="btnExporttoCSV" runat="server" Text="Export to Excel" class="btn btn-info waves-effect waves-light" OnClick="btnExporttoCSV_Click" />
                              <asp:RequiredFieldValidator ID="RequiredFieldValidatorCompany" ControlToValidate="lbCompany" InitialValue="" runat="server" ErrorMessage="Please select any Company" ForeColor="Red"></asp:RequiredFieldValidator>
                                    </div>
                            </div>
                        </div>

                    </div>
                </div>

                <div class="row">
                    <div class="form-group col-md-12">
                        <rsweb:ReportViewer ID="ReportViewer1" runat="server" BackColor="" ClientIDMode="AutoID" HighlightBackgroundColor="" InternalBorderColor="204, 204, 204" InternalBorderStyle="Solid" InternalBorderWidth="1px" LinkActiveColor="" LinkActiveHoverColor="" LinkDisabledColor="" PrimaryButtonBackgroundColor="" PrimaryButtonForegroundColor="" PrimaryButtonHoverBackgroundColor="" PrimaryButtonHoverForegroundColor="" SecondaryButtonBackgroundColor="" SecondaryButtonForegroundColor="" SecondaryButtonHoverBackgroundColor="" SecondaryButtonHoverForegroundColor="" SplitterBackColor="" ToolbarDividerColor="" ToolbarForegroundColor="" ToolbarForegroundDisabledColor="" ToolbarHoverBackgroundColor="" ToolbarHoverForegroundColor="" ToolBarItemBorderColor="" ToolBarItemBorderStyle="Solid" ToolBarItemBorderWidth="1px" ToolBarItemHoverBackColor="" ToolBarItemPressedBorderColor="51, 102, 153" ToolBarItemPressedBorderStyle="Solid" ToolBarItemPressedBorderWidth="1px" ToolBarItemPressedHoverBackColor="153, 187, 226" Width="100%" Height="723px" AsyncRendering="False" InteractivityPostBackMode="AlwaysSynchronous" PageCountMode="Actual" ShowBackButton="False" ShowDocumentMapButton="False" ShowExportControls="False" ShowFindControls="False" ShowParameterPrompts="False" ShowPrintButton="False" ShowRefreshButton="False" ShowZoomControl="False">
                            <LocalReport ReportPath="rdlcs\Purchasre\Report_PendingPurchaseBill.rdlc">
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

                        $('[id*=lbVendorName]').multiselect({
                            includeSelectAllOption: true,
                            maxHeight: 400,
                            enableFiltering: true,
                            enableCaseInsensitiveFiltering: true
                        });


                        $('[id*=lbStockGroup]').multiselect({
                            includeSelectAllOption: true,
                            maxHeight: 400,
                            enableFiltering: true,
                            enableCaseInsensitiveFiltering: true,

                            enableClickableOptGroups: true,
                            onChange: function (option, checked, select) {
                                //alert('onChange triggered ...');
                            }
                        });
                        $('#lbStockGroup-select-onChange-button').on('click', function () {
                            $('#lbStockGroup-select-onChange').multiselect('select', '1', true);
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
            <asp:AsyncPostBackTrigger ControlID="btnSearch" />
            <asp:PostBackTrigger ControlID="btnReset" />
            <asp:PostBackTrigger ControlID="btnExporttoCSV" />
        </Triggers>

    </asp:UpdatePanel>

</asp:Content>

