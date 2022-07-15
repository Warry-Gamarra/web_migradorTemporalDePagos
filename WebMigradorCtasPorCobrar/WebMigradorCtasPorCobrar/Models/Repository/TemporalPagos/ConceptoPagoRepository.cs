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
    public class ConceptoPagoRepository
    {
        public static IEnumerable<ConceptoPago> Obtener(string schemaDb)
        {
            IEnumerable<ConceptoPago> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<ConceptoPago>($"SELECT * FROM {schemaDb}.cp_pri", commandType: CommandType.Text);
            }

            return result;
        }
    }
}