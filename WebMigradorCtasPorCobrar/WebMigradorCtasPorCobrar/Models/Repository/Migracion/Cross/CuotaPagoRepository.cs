using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross
{
    public class CuotaPagoRepository
    {
        public static IEnumerable<CuotaPago> Obtener(int procedenciaID)
        {
            IEnumerable<CuotaPago> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPago>("SELECT cp_des.*, eq.T_OpcionDesc AS PeriodoDesc, eq2.T_CatPagoDesc AS CatPagoDesc " +
                                                     "FROM dbo.TR_Cp_Des cp_des " +
                                                          "LEFT JOIN VW_EquivalenciasCtasPorCobrar eq ON cp_des.I_Periodo = eq.I_opcionID " +
                                                          "LEFT JOIN VW_CategoríasDePagoCtasPorCobrar eq2 ON cp_des.I_CatPagoID = eq2.I_CatPagoID " +
                                                     "WHERE I_ProcedenciaID = @I_ProcedenciaID"
                                                     , new { I_ProcedenciaID = procedenciaID }
                                                     , commandType: CommandType.Text);
            }

            return result;
        }

        public static CuotaPago ObtenerPorId(int rowID)
        {
            CuotaPago result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<CuotaPago>("SELECT cp_des.*, eq.T_OpcionDesc AS PeriodoDesc, eq2.T_CatPagoDesc AS CatPagoDesc " +
                                                                    "FROM dbo.TR_Cp_Des cp_des " +
                                                                         "LEFT JOIN VW_EquivalenciasCtasPorCobrar eq ON cp_des.I_Periodo = eq.I_opcionID " +
                                                                         "LEFT JOIN VW_CategoríasDePagoCtasPorCobrar eq2 ON cp_des.I_CatPagoID = eq2.I_CatPagoID " +
                                                                    "WHERE I_RowID = @I_RowID"
                                                                    , new { I_RowID = rowID }
                                                                    , commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<CuotaPago> ObtenerObservados(int procedenciaID, int observacionID, int tablaID)
        {
            IEnumerable<CuotaPago> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPago>("SELECT * FROM dbo.TR_Cp_Des cp_des " +
                                                     "INNER JOIN TI_ObservacionRegistroTabla obs ON cp_des.I_RowID = obs.I_FilaTablaID AND obs.I_TablaID = @I_TablaID " +
                                                     "WHERE obs.I_ProcedenciaID = @I_ProcedenciaID AND obs.I_ObservID = @I_ObservID AND B_Resuelto = 0"
                                                        , new { I_ProcedenciaID = procedenciaID, I_TablaID = tablaID, I_ObservID = observacionID }
                                                        , commandType: CommandType.Text);
            }

            return result;
        }

        public static DataTable ObtenerReporteObservados(int procedenciaID, int observacionID, int tablaID)
        {
            DataTable result = new DataTable();

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                string query = "SELECT Cuota_pago AS 'COD CUOTA', Descripcio AS 'DESCRIPCION', N_cta_cte AS 'NRO CUENTA', Codigo_bnc AS 'COD BNC', Fch_venc AS 'FEC VENC', " +
                                      "Prioridad AS 'PRIORIDAD', C_mora AS 'MORA', I_Anio AS 'AÑO', I_Periodo AS 'PERIODO', T_ObservCod AS 'OBSERVACION'  " +
                               "FROM dbo.TR_Cp_Des cp_des " +
                                   "INNER JOIN TI_ObservacionRegistroTabla obs ON cp_des.I_RowID = obs.I_FilaTablaID AND obs.I_TablaID = @I_TablaID " +
                                   "INNER JOIN TC_CatalogoObservacion co ON obs.I_ObservID = co.I_ObservID " +
                               "WHERE obs.I_ProcedenciaID = @I_ProcedenciaID AND obs.I_ObservID = IIF(@I_ObservID = 0, obs.I_ObservID, @I_ObservID)" +
                               "ORDER BY Cuota_pago;";

                SqlCommand command = new SqlCommand(query, connection);
                command.Parameters.AddWithValue("I_ProcedenciaID", procedenciaID);
                command.Parameters.AddWithValue("I_ObservID", observacionID);
                command.Parameters.AddWithValue("I_TablaID", tablaID);

                using (SqlDataAdapter dataAdapter = new SqlDataAdapter(command))
                {
                    dataAdapter.Fill(result);
                }
            }

            return result;
        }

    }
}