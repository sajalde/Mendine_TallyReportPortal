using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using loginservice;

public partial class Register_Loginuser : System.Web.UI.Page
{
    protected void Page_Load(object sender, EventArgs e)
    {
        try

        {
            Menu men = (Menu)Master.FindControl("NavigationMenu");
            men.Visible = false;
            Control txtblnk = (Control)Master.FindControl("txtblnk");
            txtblnk.Visible = false;
            Control txtblnk1 = (Control)Master.FindControl("txtblnk1");
            txtblnk1.Visible = false;


            if (!IsPostBack)
            {
                //Check if the browser support cookies.
                if (Request.Browser.Cookies)
                {
                    //Check if the cookie with name "C_LOGIN" exists on web browser of the user's machine.
                    if (Request.Cookies["C_LOGIN"] != null)
                    {
                        //Note: You have two options: Either you can display the login page filled with credentials in it.
                        //or you can simply navigate to the page next to the login page, if the cookie exists.
                        //Option 1:
                        //Display the credentials (Username & Password) on the login page.
                        //Pass the Username and Password to the respective TextBox.

                        uname.Text = Request.Cookies["C_LOGIN"]["Username"].ToString();
                        pwd.Attributes["value"] = Request.Cookies["C_LOGIN"]["Password"].ToString();
                        CheckBox1.Checked = true;

                        //OR
                        //Option 2:
                        //Navigate to home page without displaying login page.
                        //Response.Redirect("home.aspx");
                    }
                }
            }
        }
        catch (Exception ex) { }
        finally { }

    }

    protected void submit_Click(object sender, EventArgs e)
    {

        try
        {
            //Save login credentials in cookies.
            //Note: "C_LOGIN" is a user defined name.
            //Check if "Remember Me" checkbox is checked on login.

            if (CheckBox1.Checked)
            {
                if (Request.Browser.Cookies)
                {
                    //Create a cookie with expiry of 60 days.
                    Response.Cookies["C_LOGIN"].Expires = DateTime.Now.AddDays(60);

                    //Write Username to the cookie.
                    Response.Cookies["C_LOGIN"]["Username"] = uname.Text.Trim();

                    //Write Password to the cookie.
                    Response.Cookies["C_LOGIN"]["Password"] = pwd.Text.Trim();
                }

                //If the cookie already exists then write the Username and Password to the cookie.
                else
                {
                    Response.Cookies["C_LOGIN"]["Username"] = uname.Text.Trim();
                    Response.Cookies["C_LOGIN"]["Password"] = pwd.Text.Trim();
                }
            }
            else
            {
                //If the checkbox is unchecked then clean the cookie "C_LOGIN"
                Response.Cookies["C_LOGIN"].Expires = DateTime.Now.AddDays(-1);
            }
        }
        catch (Exception ex) { }
        finally { }


        loginservice.logincontrolSoapClient ls = new loginservice.logincontrolSoapClient();
       string t= ls.UserNamePwdcheck(uname.Text, pwd.Text);
        if ( t=="true")
        {
            Response.Redirect("~/Register/Register.aspx");

        }
        else
        {
            Response.Redirect("~/Register/Webinar.aspx");
        }

        
    }
}