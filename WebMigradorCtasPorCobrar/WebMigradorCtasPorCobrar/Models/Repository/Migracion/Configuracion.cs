using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion
{
    public class Configuracion
    {
        public Response ReiniciarTablasMigracion(string tableName)
        {
            Response response = new Response();

            try
            {
                using (var connection = new  SqlConnection(Databases.MigracionTPConnectionString))
                {
                    connection.Execute($"TRUNCATE TABLE { tableName };");
                }
            }
            catch (Exception ex)
            {
                response.IsDone = false;
                response.Message = ex.Message;
            }

            return response;
        }



    }
}