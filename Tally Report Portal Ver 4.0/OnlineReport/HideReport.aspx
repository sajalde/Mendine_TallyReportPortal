<%@ Page Title="List Of Report" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
    CodeFile="HideReport.aspx.cs" Inherits="OnlineReport_ListOfReport" %>

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


        <div class=" col-md-3">
            <div class="panel panel-default">
                <div class=" panel-body">
                    <div class="col-md-12">
                        <label for="info">Accounts Module</label>
                        <div class="row">
                            <div class="col-md-12">
                                <ul>

                                    <li>
                                        <asp:HyperLink ID="tallyJournalRegister" runat="server" NavigateUrl="~/OnlineReport/JournalRegister.aspx">Journal Register</asp:HyperLink>
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
</asp:Content>
