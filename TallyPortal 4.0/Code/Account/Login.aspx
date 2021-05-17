<%@ Page Title="Tally Portal | Log In" Language="C#" MasterPageFile="~/Site.master" AutoEventWireup="true"
    CodeFile="Login.aspx.cs" Inherits="Account_Login" %>

<asp:Content ID="HeaderContent" runat="server" ContentPlaceHolderID="HeadContent">
    <style type="text/css">
        .container1
        {
            background-color: #f2f2f2;
            padding-left: 15px;
            margin-top: -19px;
            margin-left: -8px;
            margin-right: -8px;
            height: 80vh;
            align-content:center;
        }
    </style>


    <meta charset="utf-8" />  
    <meta http-equiv="X-UA-Compatible" content="IE=edge" />  
    <meta name="viewport" content="width=device-width, initial-scale=1" />  
    <meta name="description" content="" />  
    <meta name="author" content="ananth.G" />  
    <link href="bootstrap/css/bootstrap.css" rel="stylesheet" />  
    <link href="css/skin-3.css" rel="stylesheet" />  
    <link href="css/style.css" rel="stylesheet" />  
    <link href="bootstrap/css/font-awesome.min.css" rel="stylesheet" />  
    <script src="https://oss.maxcdn.com/libs/html5shiv/3.7.0/html5shiv.js"></script>  
    <script src="https://oss.maxcdn.com/libs/respond.js/1.3.0/respond.min.js"></script>  
    <script src="bootstrap/js/jquery-1.9.1.js"></script>  
    <style>  
        body {  
            background: url(../images/06.jpg) no-repeat;  
            background-size: cover;  
            min-height: 100%;  
        }  
  
        html {  
            min-height: 100%;  
        }  
  
        .Error-control {  
            background: #ffdedd !important;  
            border-color: #ff5b57 !important;  
        }  

    </style>  
</asp:Content>
<asp:Content ID="BodyContent" runat="server" ContentPlaceHolderID="MainContent">
     
      <asp:UpdatePanel ID="UpdatePanel1" runat="server">
        <ContentTemplate>
    
    <div class="container">  
           
               <div class="col-lg-5 col-md-6 col-sm-8 col-xl-12 " style="margin: auto; float: initial; padding-top: 12%; top: 0px; left: 0px; height: 615px;">  
                   <div class="row userInfo">  
  
                       <div class="panel panel-default ">  
                           <div class="panel-heading">  
                               <h3 class="panel-title" style="text-align: center; font-weight: bold">  
                                   <a class="collapseWill">Sign In</a>  
                               </h3>  
                           </div>  
                           <div id="collapse1" class="panel-collapse collapse in">  
                               <div class="panel-body">  
                                 
                                       <div class="form-group">  
                                           <div class="col-md-"></div>  
                                             <fieldset>  

        <asp:Login ID="LoginUser" runat="server" EnableViewState="false" RenderOuterTable="false">
            <LayoutTemplate>
                <span class="failureNotification">
                    <asp:Literal ID="FailureText" runat="server"></asp:Literal>
                </span>
                <asp:ValidationSummary ID="LoginUserValidationSummary" runat="server" CssClass="failureNotification"
                    ValidationGroup="LoginUserValidationGroup" />
                <div class="accountInfo">
                    <fieldset class="form-group">
                        <p>
                            <table id="login_tbl">
                                <tr>
                                    <td>
                                         
                                             
                                        <asp:Label ID="UserNameLabel" runat ="server" AssociatedControlID="UserName">Username:</asp:Label>
                                  
                                             </td>
                                </tr>
                                <tr>
                                    <td>
                                         
                  <asp:TextBox ID="UserName" runat="server" CssClass="form-control" Width="320px" placeholder="Username"></asp:TextBox>
                                              <asp:RequiredFieldValidator ID="UserNameRequired" runat="server" ControlToValidate="UserName"
                                            CssClass="failureNotification" ErrorMessage="User Name is required." ToolTip="User Name is required."
                                            ValidationGroup="LoginUserValidationGroup">*</asp:RequiredFieldValidator>
                 
                                        
                                       
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <asp:Label ID="PasswordLabel" runat="server" AssociatedControlID="Password">Password:</asp:Label>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <asp:TextBox ID="Password" runat="server" CssClass="form-control" TextMode="Password" placeholder="Password"></asp:TextBox>
                                        <asp:RequiredFieldValidator ID="PasswordRequired" runat="server" ControlToValidate="Password"
                                            CssClass="failureNotification" ErrorMessage="Password is required." ToolTip="Password is required."
                                            ValidationGroup="LoginUserValidationGroup">*</asp:RequiredFieldValidator>
                                    </td>
                                </tr>
                                <tr>
                                    <td>
                                        <asp:CheckBox ID="RememberMe" runat="server" />
                                        <asp:Label ID="RememberMeLabel" runat="server" AssociatedControlID="RememberMe" CssClass="inline">Keep me logged in</asp:Label>
                    </fieldset>
                    </td></tr>
                    <%--<tr>
                        <td scope="row">
                            <asp:HyperLink ID="fpassword_link" runat="server" class="collapseWill" NavigateUrl="~/Register/password.aspx">Forgot Password</asp:HyperLink>
                        </td>
                    </tr>--%>
                    <tr>
                        <td>

                            <p class="submitButton">
                                <asp:Button ID="LoginButton" runat="server" CommandName="Login" Text="Log In" ValidationGroup="LoginUserValidationGroup"
                                    class="btn btn-success btn-lg" OnClick="LoginButton_Click" />
                            </p>
                        </td>
                    </tr>
                    </table> </p>
                </div>
            </LayoutTemplate>
        </asp:Login>
                                                 </fieldset>
    </div>
                                       
                 </div>

                                  <div class="panel-heading">  
                               <div class="panel-title" style="text-align: right">  

                                     <asp:HyperLink ID="fpassword_link" runat="server" class="collapseWill" NavigateUrl="../Register/password.aspx">Forgot Password</asp:HyperLink>
                                <%--   <a class="collapseWill" href="SellerForgetPassword.aspx" style="font-size: x-small">Forgot Username or Password?  --%>
                                   </a>  
                               </div>  </div>

               </div>
             </div></div></div>

             

           </div>
        </ContentTemplate>
          </asp:UpdatePanel>
</asp:Content>
