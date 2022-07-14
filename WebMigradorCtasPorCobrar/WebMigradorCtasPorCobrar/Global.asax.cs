using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using System.Web.Optimization;
using System.Web.Routing;
using WebMatrix.WebData;

namespace WebMigradorCtasPorCobrar
{
    public class MvcApplication : System.Web.HttpApplication
    {
        protected void Application_Start()
        {
            AreaRegistration.RegisterAllAreas();

            FilterConfig.RegisterGlobalFilters(GlobalFilters.Filters);
            RouteConfig.RegisterRoutes(RouteTable.Routes);
            BundleConfig.RegisterBundles(BundleTable.Bundles);

            if (!WebSecurity.Initialized)
            {
                WebSecurity.InitializeDatabaseConnection("BD_MigracionTPConnection", "TC_Usuarios", "UserId", "UserName", autoCreateTables: true);

            }
        }
    }
}
