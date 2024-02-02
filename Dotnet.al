/* dotnet
{
    //DotNet "'System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'.System.Net.HttpWebRequest"
    assembly(System)
    {
        type(System.Net.HttpWebRequest; HttpWebRequestDV)
        { }
    }
    //"'System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'.System.Net.HttpWebResponse"
    assembly(System)
    {
        type(System.Net.HttpWebResponse; HttpWebResponseDV)
        { }

    }
    //"'GSTEInvoiceAccessToken, Version=1.0.0.0, Culture=neutral, PublicKeyToken=null'.GSTEInvoiceAccessToken.GenerateAccessToken";
    assembly(GSTEInvoiceAccessToken)
    {
        type(GSTEInvoiceAccessToken.GenerateAccessToken; AccessCodeDllDV)
        { }
    }

    //"'mscorlib'.System.IO.FileStream"
    assembly(mscorlib)
    {
        type(System.IO.FileStream; FileStreamDV)
        { }
        type("System.IO.StringReader"; "StringReader")
        {
        }

        type("System.Text.StringBuilder"; "StringBuilder")
        {
        }

        type("System.IO.StringWriter"; "StringWriter")
        {
        }
        type("System.IO.TextWriter"; "TextWriter")
        {

        }
        type("System.Collections.Generic.Dictionary`2"; GenDictionary)
        { }
        type("System.Convert"; SystemConvert)
        { }

    }
    //"'mscorlib'.System.IO.FileMode"
    assembly(mscorlib)
    {
        type(System.IO.FileMode; FileModeDV)
        { }
        type(System.IO.MemoryStream; MemoryStream)
        { }
    }
    //"'Microsoft.Dynamics.Nav.MX, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35'.Microsoft.Dynamics.Nav.MX.BarcodeProviders.IBarcodeProvider"
    assembly(Microsoft.Dynamics.Nav.MX)
    {
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.IBarcodeProvider; IBarCodeProviderDV)
        { }
    }
    //"'Microsoft.Dynamics.Nav.MX, Version=9.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35'.Microsoft.Dynamics.Nav.MX.BarcodeProviders.QRCodeProvider"
    assembly(Microsoft.Dynamics.Nav.MX)
    {
        type(Microsoft.Dynamics.Nav.MX.BarcodeProviders.QRCodeProvider; QRCodeProviderDV)
        { }
    }
    assembly("Newtonsoft.Json")
    {
        type("Newtonsoft.Json.JsonTextReader"; "JsonTextReader")
        {
        }

        type("Newtonsoft.Json.JsonTextWriter"; "JsonTextWriter")
        {
        }

        type("Newtonsoft.Json.Formatting"; "Formatting")
        {
        }
    }
    assembly(System.Web.Extensions)
    {
        type("System.Web.Script.Serialization.JavaScriptSerializer"; Serialization) { }
    }
    assembly(GSTEInvAccessTokenMI)
    {
        type(GSTEInvAccessTokenMI.GenerateAccesToken; GSTEInvAccessTokenMI)
        { }
    }
    assembly(Microsoft.VisualBasic)
    {
        type(Microsoft.VisualBasic.Interaction; Interaction)
        { }
    }
    assembly(System.Windows.Forms)
    {
        type(System.Windows.Forms.Form; FormDV) { }
        type(System.Windows.Forms.FormBorderStyle; FormBorderStyleDV) { }
        type(System.Windows.Forms.FormStartPosition; FormStartPositionDV) { }
        type(System.Windows.Forms.Label; LabelDV) { }
        type(System.Windows.Forms.TextBox; TextBoxDV) { }
        type(System.Windows.Forms.Button; ButtonDV) { }
        type(System.Windows.Forms.DialogResult; DialogResultDV) { }
    }
} */
dotnet
{
    //DotNet "'System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'.System.Net.HttpWebRequest"
    assembly(System)
    {
        type(System.Net.HttpWebRequest; HttpWebRequestDV)
        { }
    }
    //"'System, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'.System.Net.HttpWebResponse"
    assembly(System)
    {
        type(System.Net.HttpWebResponse; HttpWebResponseDV)
        { }

    }
}