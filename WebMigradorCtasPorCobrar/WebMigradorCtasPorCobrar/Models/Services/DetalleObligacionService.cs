using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services
{
    public class DetalleObligacionService
    {
        public IEnumerable<DetalleObligacionTP> ObtenerPosgrado(string anio, string per, string codAlu, string cuotaPago, DateTime? fecVenc)
        {
            IEnumerable<DetalleObligacionTP> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                string str_query = $"SELECT * FROM EUPG_ec_det WHERE ano = @ano AND p = @p AND cod_alu = @cod_alu AND cuota_pago = @cuota_pago";
                str_query += fecVenc.HasValue ? " AND fhc_venc = @fch_venc;" : ";";

                result = connection.Query<DetalleObligacionTP>(str_query,
                                                       new
                                                       {
                                                           ano = anio,
                                                           p = per,
                                                           cod_alu = codAlu,
                                                           cuota_pago = cuotaPago,
                                                           fch_venc = fecVenc
                                                       }, commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<DetalleObligacionMG> ObtenerPosgradoMG(int rowId)
        {
            IEnumerable<DetalleObligacionMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<DetalleObligacionMG>("SELECT * FROM EUPG_ec_det WHERE I_RowID = @I_RowID", new { I_RowID = rowId }, commandType: CommandType.Text);
            }

            return result;
        }



        public Response ObtenerResultadoValidacion(string anio)
        {
            var result = new Response();

            return result;
        }


    }
}