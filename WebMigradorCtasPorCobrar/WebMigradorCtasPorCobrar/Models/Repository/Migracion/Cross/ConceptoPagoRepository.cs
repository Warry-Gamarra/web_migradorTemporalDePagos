using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;


namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross
{
    public partial class ConceptoPagoRepository
    {
        public static IEnumerable<ConceptoPago> Obtener(int procedenciaID)
        {
            IEnumerable<ConceptoPago> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<ConceptoPago>("SELECT cp_pri.*, (CAST(cp_des.cuota_pago as varchar) + ' - ' + cp_des.descripcio) AS cuota_pago_desc FROM dbo.TR_Cp_Pri cp_pri " +
                                                        "INNER JOIN TR_Cp_Des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago AND cp_des.Eliminado = 0 " +
                                                        "WHERE cp_pri.I_ProcedenciaID = @I_ProcedenciaID"
                                                         , new { I_ProcedenciaID = procedenciaID }
                                                         , commandType: CommandType.Text);
            }

            return result;
        }


        public static ConceptoPago ObtenerPorId(int rowID)
        {
            ConceptoPago result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<ConceptoPago>("SELECT * FROM dbo.TR_Cp_Pri WHERE I_RowID = @I_RowID"
                                                        , new { I_RowID = rowID }
                                                        , commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<ConceptoPago> ObtenerPorCuotaPago(int cuotaPagoID)
        {
            IEnumerable<ConceptoPago> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<ConceptoPago>("SELECT * FROM dbo.TR_Cp_Pri WHERE cuota_pago = @cuota_pago"
                                                        , new { cuota_pago = cuotaPagoID }
                                                        , commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<ConceptoPago> ObtenerObservados(int procedenciaID, int observacionID, int tablaID)
        {
            IEnumerable<ConceptoPago> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<ConceptoPago>("SELECT cp_pri.*, (CAST(cp_des.cuota_pago as varchar) + ' - ' + cp_des.descripcio) AS cuota_pago_desc FROM dbo.TR_Cp_Pri cp_pri " +
                                                        "INNER JOIN TI_ObservacionRegistroTabla obs ON cp_pri.I_RowID = obs.I_FilaTablaID AND obs.I_TablaID = @I_TablaID " +
                                                        "INNER JOIN TR_Cp_Des cp_des ON cp_pri.cuota_pago = cp_des.cuota_pago AND cp_des.Eliminado = 0 " +
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
                string query = "SELECT CONCAT(cp_des.Cuota_pago, ' - ', cp_des.Descripcio) AS 'CUOTA PAGO', Id_cp AS 'COD CONCEPTO', cp_pri.Descripcio AS 'DESCRIPCION', Cod_rc AS 'COD RC', Cod_ing AS 'COD INGR', Fch_venc AS 'FEC VENC', " +
                                      "I_Anio AS 'AÑO', I_Periodo AS 'PERIODO', Nro_pagos AS 'NRO PAGOS', Monto AS 'MONTO', T_ObservCod AS 'OBSERVACION'  " +
                               "FROM dbo.TR_Cp_Pri cp_pri " +
                                   "INNER JOIN TR_Cp_Des cp_des ON cp_des.Cuota_pago = cp_pri.Cuota_pago " +
                                   "INNER JOIN TI_ObservacionRegistroTabla obs ON cp_pri.I_RowID = obs.I_FilaTablaID AND obs.I_TablaID = @I_TablaID " +
                                   "INNER JOIN TC_CatalogoObservacion co ON obs.I_ObservID = co.I_ObservID " +
                               "WHERE obs.I_ProcedenciaID = @I_ProcedenciaID AND obs.I_ObservID = IIF(@I_ObservID = 0, obs.I_ObservID, @I_ObservID)" +
                               "ORDER BY cp_pri.Cuota_pago, cp_pri.Id_cp;";

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