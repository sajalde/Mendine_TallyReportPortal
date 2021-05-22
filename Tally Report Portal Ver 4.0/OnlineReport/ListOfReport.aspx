<%@ Page Title="List Of Report" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
    CodeFile="ListOfReport.aspx.cs" Inherits="OnlineReport_ListOfReport" %>

<asp:Content ID="HeaderContent" runat="server" ContentPlaceHolderID="HeadContent">

    <link href="../Styles/Customstyle1.css" rel="stylesheet" type="text/css" />
    <style type="text/css">
        #image {
            line-height: .5em;
            list-style-position: inside;
            list-style-image: url(../Image/reporticon2.png);
        }
    </style>

</asp:Content>

<asp:Content ID="Content2" ContentPlaceHolderID="MainContent" runat="Server">
    <div class="container1">
        <div class="row">
            <div class="col-xs-12">
                <div class="box box-info">
                    <div class="box-header with-border" style="color: #fff">
                        <h3 class="box-title">Tally Report</h3>
                    </div>
                    <%--<div class="box-body">
                        <ul>
                            <li>
                                <asp:HyperLink ID="HyperLink1" runat="server" NavigateUrl="~/OnlineReport/FinalProductStock.aspx">Final Product Stock Statement</asp:HyperLink>
                            </li>
                        </ul>
                    </div>--%>
                </div>
            </div>
        </div>

        <div class="row">
            <div class=" col-md-3 ">
                <div class="panel panel-default">
                    <div class="panel-body">
                        <div class="col-md-12">
                            <label for="info">Stock Module</label>
                        </div>
                        <ul>
                            <li>
                                <asp:HyperLink ID="tallFinalstock" runat="server" NavigateUrl="~/OnlineReport/FinalProductStock.aspx">Final Product Stock Statement</asp:HyperLink>
                            </li>

                            <li>
                                <asp:HyperLink ID="tallyGodownStockTransfer" runat="server" NavigateUrl="~/OnlineReport/GodownStockTransfer.aspx">Godown Stock Transfer</asp:HyperLink>
                            </li>

                            <li>
                                <asp:HyperLink ID="tallyGodownStockSummary" runat="server" NavigateUrl="~/OnlineReport/GodownStockSummary.aspx">Godown Stock Summary</asp:HyperLink>
                            </li>

                            <li>
                                <asp:HyperLink ID="tallyStockDetails" runat="server" NavigateUrl="~/OnlineReport/StockDetails.aspx">Stock Details</asp:HyperLink>
                            </li>

                            <li>
                                <asp:HyperLink ID="Tallylead" runat="server" NavigateUrl="~/OnlineReport/LeadTimeReport.aspx">Lead Time Report</asp:HyperLink>
                            </li>

                             <li>
                                <asp:HyperLink ID="TallyNegativeBatch" runat="server" NavigateUrl="~/OnlineReport/Stock_NegativeBatch.aspx">Negative Batch Report</asp:HyperLink>
                            </li>
                        </ul>

                    </div>
                </div>
            </div>

            <div class=" col-md-3">
                <div class="panel panel-default">
                    <div class=" panel-body">
                        <div class="col-md-12">
                            <label for="info">Purchase Module</label>
                        </div>

                        <div class="row">
                            <div class="col-md-12">
                                <ul>
                                    <li>
                                        <asp:HyperLink ID="tallyPendingpo" runat="server" NavigateUrl="~/OnlineReport/PendingPurchaseOrder.aspx">Pending Purchase Order</asp:HyperLink>
                                    </li>
                                    <li>
                                        <asp:HyperLink ID="tallyPendingPurchaseBill" runat="server" NavigateUrl="~/OnlineReport/PendingPurchaseBill.aspx">Pending Purchase Bill</asp:HyperLink>
                                    </li>
                                    <li>
                                        <asp:HyperLink ID="tallyVendorOutstanding" runat="server" NavigateUrl="~/OnlineReport/VendorOutstanding.aspx">Vendor Outstanding</asp:HyperLink>
                                    </li>
                                    <li>
                                        <asp:HyperLink ID="tallyNegativeStockReport" runat="server" NavigateUrl="~/OnlineReport/NegativeStockReport.aspx">Negative Stock Report</asp:HyperLink>
                                    </li>
                                </ul>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class=" col-md-3">
                <div class="panel panel-default">
                    <div class=" panel-body">
                        <div class="col-md-12">
                            <label for="info">Sales Module</label>
                            <div class="row">
                                <div class="col-md-12">
                                    <ul>
                                        <li>
                                            <asp:HyperLink ID="tallyPendingSalesBill" runat="server" NavigateUrl="~/OnlineReport/PendingSalesBill.aspx">Pending Sales Bill</asp:HyperLink>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>

            <div class=" col-md-3">
                <div class="panel panel-default">
                    <div class=" panel-body">
                        <div class="col-md-12">
                            <label for="info">Accounts Module</label>
                            <div class="row">
                                <div class="col-md-12">
                                    <ul>
                                        <li>
                                            <asp:HyperLink ID="tallyDebitCreditNoteRegister" runat="server" NavigateUrl="~/OnlineReport/DebitCreditNoteRegister.aspx">Debit Credit Note Register</asp:HyperLink>
                                        </li>
                                        <li>
                                            <asp:HyperLink ID="tallyJournalRegister" runat="server" NavigateUrl="~/OnlineReport/JournalRegister.aspx">Journal Register</asp:HyperLink>
                                        </li>

                                        <li>
                                            <asp:HyperLink ID="tallyCashBook" runat="server" NavigateUrl="~/OnlineReport/Acc_CashBook.aspx">Cash Book</asp:HyperLink>
                                        </li>

                                        <li>
                                            <asp:HyperLink ID="tallyLedgerBook" runat="server" NavigateUrl="~/OnlineReport/Acc_LedgerReport.aspx">Ledger Report</asp:HyperLink>
                                        </li>

                                        <li>
                                            <asp:HyperLink ID="TallyCostCenter" runat="server" NavigateUrl="~/OnlineReport/Acc_CostcenterReport.aspx">Cost Center Report</asp:HyperLink>
                                        </li>

                                        <li>
                                            <asp:HyperLink ID="TallyNegativeLedger" runat="server" NavigateUrl="~/OnlineReport/Acc_NegativeLedger.aspx">Negative Ledger Report</asp:HyperLink>
                                        </li>

                                        <li>
                                            <asp:HyperLink ID="TallyExceptionReport" runat="server" NavigateUrl="~/OnlineReport/Acc_ExceptionReport.aspx">Exception Report</asp:HyperLink>
                                        </li>
                                    </ul>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</asp:Content>
