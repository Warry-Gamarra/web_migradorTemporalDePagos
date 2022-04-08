using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Areas.temporal_pagos
{
    public class temporal_pagosAreaRegistration : AreaRegistration 
    {
        public override string AreaName 
        {
            get 
            {
                return "temporal_pagos";
            }
        }

        public override void RegisterArea(AreaRegistrationContext context) 
        {
            context.MapRoute(
                "temporal_pagos_default",
                "temporal_pagos/{controller}/{action}/{id}",
                new { action = "Index", id = UrlParameter.Optional }
            );
        }
    }
}