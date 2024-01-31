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

        public static IEnumerable<CuotaPago> ObtenerTasas(string schemaDb, string codigos_bnc)
        {
            IEnumerable<CuotaPago> result;

            using (var connection = new SqlConnection(Databases.TemporalTasasConnectionString))
            {
                result = connection.Query<CuotaPago>($"SELECT * FROM {schemaDb}.cp_des WHERE codigo_bnc IN ({codigos_bnc})", commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<CuotaPago> ObtenerPorConceptoPago(string schemaDb, int conceptoPagoID)
        {
            IEnumerable<CuotaPago> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<CuotaPago>($"SELECT cp_des.* FROM {schemaDb}.cp_pri " +
                                                     $"    INNER JOIN {schemaDb}.cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago" +
                                                     $"WHERE cp_pri.id_cp = @id_cp"
                                                     , new { id_cp = conceptoPagoID }
                                                     , commandType: CommandType.Text);
            }

            return result;
        }

    }
}