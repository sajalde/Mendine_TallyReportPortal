<%@ Page Language="C#" AutoEventWireup="true"  MasterPageFile="~/Register/Site.master" CodeFile="Powerbi.aspx.cs" Inherits="Register_Powerbi" %>
<%@ Register assembly="Microsoft.ReportViewer.WebForms" namespace="Microsoft.Reporting.WebForms" tagprefix="rsweb" %>


<asp:Content ID="HeaderContent" runat="server" ContentPlaceHolderID="HeadContent">

    <title></title>


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

     <div class="container">  
           
               <div class="col-lg-5 col-md-6 col-sm-8 col-xl-12 " style="margin: auto; float: initial; padding-top: 12%; top: 0px; left: 0px; height: 615px;">  
                   <div class="row userInfo">  
  
                       <div class="panel panel-default ">  
                          
                           <div id="collapse1" class="panel-collapse collapse in">  
                               <div class="panel-body">  
                                 
                                       <div class="form-group">  
                                           <div class="col-md-">

                                                <iframe runat="server" width="700" height="500" src="https://app.powerbi.com/view?r=eyJrIjoiMDdjYTAyOTYtNzMzYS00MGY0LWFiODYtOWNiY2NkOWIyZjQwIiwidCI6IjQ2YzViYjUyLTVlNmMtNGU4YS05YWUwLTRiMjA3ZTg1NDQzMyIsImMiOjEwfQ%3D%3D" frameborder="0" allowFullScreen="true" 
          ></iframe>

                                           </div>  
                                            
    </div>
                                       
                 </div>

                                

               </div>
             </div></div></div>

             

           </div>
















</asp:Content>
 
