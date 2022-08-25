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
    public class ObligacionRepository
    {
        public static IEnumerable<Obligacion> Obtener(string schemaDb)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<Obligacion>($"SELECT * FROM {schemaDb}.ec_obl ORDER BY Ano, P, Cuota_pago", 
                                                        commandType: CommandType.Text);
            }

            return result;
        }
    }
}