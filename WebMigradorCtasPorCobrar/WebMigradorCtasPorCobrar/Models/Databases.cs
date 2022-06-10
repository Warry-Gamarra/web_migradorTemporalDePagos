using System;
using System.Collections.Generic;
using System.Configuration;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models
{
    public class Databases
    {
        public static string CtasPorCobrarConnectionString
        {
            get {
                return ConfigurationManager.ConnectionStrings["BD_CtasPorCobrarConnection"].ConnectionString;
            }
        }

        public static string MigracionTPConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["BD_MigracionTPConnection"].ConnectionString;
            }
        }

        public static string TemporalPagoConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["BD_TemporalPagoConnection"].ConnectionString;
            }
        }

        public static string RepositorioUnfvConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["BD_RepositorioConnection"].ConnectionString;
            }
        }


    }
}