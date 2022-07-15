using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;

namespace WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos
{
    public class CuotaPagoRepository
    {
        public static IEnumerable<CuotaPago> Obtener(string schemaDb)
        {
            IEnumerable<CuotaPago> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<CuotaPago>($"SELECT * FROM {schemaDb}.cp_des", commandType: CommandType.Text);
            }

            return result;
        }
    }
}