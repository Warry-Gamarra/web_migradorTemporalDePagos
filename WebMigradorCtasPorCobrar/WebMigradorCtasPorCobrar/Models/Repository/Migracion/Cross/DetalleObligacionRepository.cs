using Dapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross
{
    public class DetalleObligacionRepository
    {
        public static DetalleObligacion ObtenerDatosDetalle(int detalleObligID)
        {
            DetalleObligacion result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<DetalleObligacion>("SELECT ec_det.*, '(' + CAST(cp_pri.id_cp as varchar) + ') ' + cp_pri.Descripcio AS Concepto_desc " +
                                                                              "FROM TR_Ec_det ec_det " +
                                                                                   "LEFT JOIN TR_Cp_Pri cp_pri ON ec_det.concepto = cp_pri.id_cp AND cp_pri.eliminado = 0 " +
                                                                             "WHERE I_RowID = @I_RowID " +
                                                                                   "AND ec_det.concepto_f = 0 " +
                                                                            "ORDER BY ec_det.Eliminado ASC",
                                                                             new { I_RowID = detalleObligID },
                                                                              commandType: CommandType.Text, commandTimeout: 1200);
            }

            return result;
        }


        public static IEnumerable<DetalleObligacion> Obtener(int obligacionID)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<DetalleObligacion>("SELECT ec_det.*, '(' + CAST(cp_pri.id_cp as varchar) + ') ' + cp_pri.Descripcio AS Concepto_desc " +
                                                               "FROM TR_Ec_det ec_det " +
                                                                    "LEFT JOIN TR_Cp_Pri cp_pri ON ec_det.concepto = cp_pri.id_cp AND cp_pri.eliminado = 0 " +
                                                              "WHERE I_OblRowID = @I_OblRowID " +
                                                                    "AND ec_det.concepto_f = 0 " +
                                                             "ORDER BY ec_det.Eliminado ASC",
                                                              new { I_OblRowID = obligacionID },
                                                              commandType: CommandType.Text, commandTimeout: 1200);
            }

            return result;
        }


        public static IEnumerable<DetalleObligacion> ObtenerDetallePorAlumno(string CodAlu, string CodRc, double ObligacionID)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<DetalleObligacion>("SELECT * FROM TR_Ec_det WHERE I_OblRowID = @I_OblRowID AND Cod_alu = @Cod_alu AND Cod_RC = @Cod_RC",
                                                              new { I_OblRowID = ObligacionID, Cod_alu = CodAlu, Cod_Rc = CodRc },
                                                              commandType: CommandType.Text, commandTimeout: 1200);
            }

            return result;
        }

    }
}