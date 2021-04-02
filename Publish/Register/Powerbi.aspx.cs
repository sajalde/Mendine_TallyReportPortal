using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;

public partial class Register_Powerbi : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        Menu men = (Menu)Master.FindControl("NavigationMenu");
        men.Visible = false;
        LoginView lv = (LoginView)Master.FindControl("HeadLoginView");
        lv.Visible = false;

    }
}