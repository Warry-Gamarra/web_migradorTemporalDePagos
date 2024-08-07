using System;
using System.Collections.Generic;
using System.Configuration;
using System.Data.SqlClient;
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

        public static string TemporalTasasConnectionString
        {
            get
            {
                return ConfigurationManager.ConnectionStrings["BD_TemporalTasasConnection"].ConnectionString;
            }
        }


        public bool IsDatabaseConnected(string connectionStringName)
        {
            try
            {
                string connectionString = ConfigurationManager.ConnectionStrings[connectionStringName].ConnectionString;

                using (var connection = new SqlConnection(connectionString))
                {
                    connection.Open();
                    return true;
                }
            }
            catch (SqlException)
            {
                return false;
            }
        }
    }
}