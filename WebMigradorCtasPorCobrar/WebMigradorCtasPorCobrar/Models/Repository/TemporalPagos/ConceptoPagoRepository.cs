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
        public static IEnumerable<ConceptoPago> Obtener(string schemaDb, string codigos_bnc)
        {
            IEnumerable<ConceptoPago> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<ConceptoPago>($"SELECT cp_pri.* FROM {schemaDb}.cp_pri cp_pri " +
                                                        $"       INNER JOIN {schemaDb}.cp_des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago " +
                                                        $"WHERE cp_des.codigo_bnc IN ({codigos_bnc});"
                                                        , commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<ConceptoPago> ObtenerTasas(string schemaDb, string codigos_bnc)
        {
            IEnumerable<ConceptoPago> result;

            using (var connection = new SqlConnection(Databases.TemporalTasasConnectionString))
            {
                result = connection.Query<ConceptoPago>($"SELECT cp_pri.* FROM {schemaDb}.cp_pri cp_pri " +
                                                        $"       INNER JOIN {schemaDb}.cp_des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago " +
                                                        $"WHERE cp_des.codigo_bnc IN ({codigos_bnc});"
                                                        , commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<ConceptoPago> ObtenerPorCuotaPago(string schemaDb, string cuotaPagoID)
        {
            IEnumerable<ConceptoPago> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<ConceptoPago>($"SELECT * FROM {schemaDb}.cp_pri " +
                                                        $"WHERE cuota_pago = @cuota_pago"
                                                        , new { cuota_pago = cuotaPagoID }
                                                        , commandType: CommandType.Text);
            }

            return result;
        }

    }
}