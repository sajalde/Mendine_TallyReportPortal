<%@ Page Title="List Of Report" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
    CodeFile="ListOfReport.aspx.cs" Inherits="OnlineReport_ListOfReport" %>

<asp:Content ID="HeaderContent" runat="server" ContentPlaceHolderID="HeadContent">

     <link href="../Styles/Customstyle1.css" rel="stylesheet" type="text/css" />
    <style type="text/css">
        #image
        {
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
