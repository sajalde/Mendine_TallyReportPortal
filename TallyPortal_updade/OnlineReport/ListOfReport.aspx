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
            <div class=" col-md-5">
                <div class="panel panel-default">
                    <div class=" panel-body">
                        <div class="col-md-12">
                            <label for="info">Tally Reports</label>
                        </div>

                        <div class="row">
                            <div class="col-md-12">
                                <ul>
                                    <li>
                                        <asp:HyperLink ID="tallFinalstock" runat="server" NavigateUrl="~/OnlineReport/FinalProductStock.aspx">Final Product Stock Statement</asp:HyperLink>
                                    </li>

                                    <li>
                                        <asp:HyperLink ID="Tallylead" runat="server" NavigateUrl="~/OnlineReport/LeadTimeReport.aspx">Lead Time Report</asp:HyperLink>
                                    </li>

                                    <li>
                                        <asp:HyperLink ID="tallyPendingpo" runat="server" NavigateUrl="~/OnlineReport/PendingPurchaseOrder.aspx">Pending PO</asp:HyperLink>
                                    </li>

                                    <li>
                                        <asp:HyperLink ID="tallyVendorOutstanding" runat="server" NavigateUrl="~/OnlineReport/VendorOutstanding.aspx">Vendor Outstanding</asp:HyperLink>
                                    </li>

                                    <li>
                                        <asp:HyperLink ID="tallyGodownStockTransfer" runat="server" NavigateUrl="~/OnlineReport/GodownStockTransfer.aspx">Godown Stock Transfer</asp:HyperLink>
                                    </li>
                                    
                                    <li>
                                        <asp:HyperLink ID="tallyGodownStockSummary" runat="server" NavigateUrl="~/OnlineReport/GodownStockSummary.aspx">Godown Stock Summary</asp:HyperLink>
                                    </li>
                                    
                                     <li>
                                        <asp:HyperLink ID="tallyPendingPurchaseBill" runat="server" NavigateUrl="~/OnlineReport/PendingPurchaseBill.aspx">Pending Purchase Bill</asp:HyperLink>
                                    </li>

                                    <li>
                                        <asp:HyperLink ID="tallyPendingSalesBill" runat="server" NavigateUrl="~/OnlineReport/PendingSalesBill.aspx">Pending Sales Bill</asp:HyperLink>
                                    </li>
                                    
                                    <li>
                                        <asp:HyperLink ID="tallyStockDetails" runat="server" NavigateUrl="~/OnlineReport/StockDetails.aspx">Stock Details</asp:HyperLink>
                                    </li>

                                    <li>
                                        <asp:HyperLink ID="tallyDebitCreditNoteRegister" runat="server" NavigateUrl="~/OnlineReport/DebitCreditNoteRegister.aspx">Debit Credit Note Register</asp:HyperLink>
                                    </li>

                                    <li>
                                        <asp:HyperLink ID="tallyJournalRegister" runat="server" NavigateUrl="~/OnlineReport/JournalRegister.aspx">Journal Register</asp:HyperLink>
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
        </div>
    </div>
</asp:Content>
