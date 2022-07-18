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
        public static IEnumerable<CuotaPago> Obtener(string schemaDb, string codigos_bnc)
        {
            IEnumerable<CuotaPago> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<CuotaPago>($"SELECT * FROM {schemaDb}.cp_des WHERE codigo_bnc IN ({codigos_bnc})", commandType: CommandType.Text);
            }

            return result;
        }
    }
}