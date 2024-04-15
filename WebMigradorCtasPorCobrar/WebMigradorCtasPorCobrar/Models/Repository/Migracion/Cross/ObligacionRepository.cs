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
    public class ObligacionRepository
    {
        public static IEnumerable<string> ObtenerAnios(int procedenciaID)
        {
            IEnumerable<string> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<string>("SELECT Ano_obl FROM (SELECT DISTINCT IIF(ISNUMERIC(Ano) = 1, Ano, 'NO NUMERICO') AS Ano_obl " +
                                                                       "FROM TR_Ec_obl WHERE I_ProcedenciaID = @I_ProcedenciaID) TBL ORDER BY Ano_obl",
                                                        new { I_ProcedenciaID = procedenciaID },
                                                        commandType: CommandType.Text, commandTimeout: 1200);
            }

            return result;
        }

        public static IEnumerable<Obligacion> Obtener(int procedenciaID)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Obligacion>("SELECT ec_obl.*, '(' + CAST(cp_des.cuota_pago as varchar) + ') ' + cp_des.Descripcio AS Cuota_pago_desc " +
                                                        "FROM TR_Ec_obl ec_obl " +
                                                             "LEFT JOIN TR_Cp_Des cp_des ON ec_obl.cuota_pago = cp_des.cuota_pago AND cp_des.eliminado = 0" +
                                                      "WHERE ec_obl.I_ProcedenciaID = @I_ProcedenciaID ORDER BY Ano, P, Cuota_pago",
                                                        new { I_ProcedenciaID = procedenciaID },
                                                        commandType: CommandType.Text, commandTimeout: 1200);
            }

            return result;
        }


        public static Obligacion ObtenerPorID(int obligacionID)
        {
            Obligacion result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<Obligacion>("SELECT ec_obl.*, '(' + CAST(cp_des.cuota_pago as varchar) + ') ' + cp_des.Descripcio AS Cuota_pago_desc " +
                                                                       "FROM TR_Ec_obl ec_obl " +
                                                                            "LEFT JOIN TR_Cp_Des cp_des ON ec_obl.cuota_pago = cp_des.cuota_pago AND cp_des.eliminado = 0" +
                                                                     "WHERE ec_obl.I_RowID = @I_RowID",
                                                        new { I_RowID = obligacionID },
                                                        commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<Obligacion> ObtenerObservados(int procedenciaID, int observacionID, int tablaID)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Obligacion>("SELECT ec_obl.*, '(' + CAST(cp_des.cuota_pago as varchar) + ') ' + cp_des.Descripcio AS Cuota_pago_desc " +
                                                      "  FROM TR_Ec_Obl ec_obl " +
                                                             "LEFT JOIN TR_Cp_Des cp_des ON ec_obl.cuota_pago = cp_des.cuota_pago AND cp_des.eliminado = 0 " +
                                                             "INNER JOIN TI_ObservacionRegistroTabla ort ON ort.I_FilaTablaID = ec_obl.I_RowID " +
                                                                    "AND ort.I_ProcedenciaID = ec_obl.I_ProcedenciaID  " +
                                                      "WHERE ec_obl.I_ProcedenciaID = @I_ProcedenciaID " +
                                                      "      AND ort.I_TablaID = @I_TablaID " +
                                                      "      AND ort.I_ObservID = @I_ObservID;"
                                                        , new { I_ProcedenciaID = procedenciaID, I_TablaID = tablaID, I_ObservID = observacionID }
                                                        , commandType: CommandType.Text, commandTimeout: 1200);
            }

            return result;
        }

        public static IEnumerable<Obligacion> ObtenerPorAlumno(string CodAlu, string CodRc)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Obligacion>("SELECT * FROM TR_Ec_obl WHERE Cod_alu = @Cod_alu AND Cod_RC = @Cod_RC ORDER BY Ano, P, Cuota_pago",
                                                        new { Cod_alu = CodAlu, Cod_Rc = CodRc },
                                                        commandType: CommandType.Text, commandTimeout: 1200);
            }

            return result;
        }

        public static DataTable ObtenerReporteObservados(int procedenciaID, int observacionID, int tablaID)
        {
            DataTable result = new DataTable();

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                string query = "SELECT Ano AS 'AÑO', P AS 'PERIODO', CONCAT(cp_des.Cuota_pago, ' - ', cp_des.Descripcio) AS 'CUOTA PAGO', Cod_rc AS 'COD RC', Cod_alu AS 'COD ALUMNO', " +
                                      "ec_obl.Fch_venc AS 'FEC VENC', Monto AS 'MONTO', T_ObservCod AS 'OBSERVACION'  " +
                               "FROM dbo.TR_Ec_Obl ec_obl " +
                                   "INNER JOIN TR_Cp_Des cp_des ON cp_des.Cuota_pago = ec_obl.Cuota_pago " +
                                   "INNER JOIN TI_ObservacionRegistroTabla obs ON ec_obl.I_RowID = obs.I_FilaTablaID AND obs.I_TablaID = @I_TablaID " +
                                   "INNER JOIN TC_CatalogoObservacion co ON obs.I_ObservID = co.I_ObservID " +
                               "WHERE obs.I_ProcedenciaID = @I_ProcedenciaID AND obs.I_ObservID = IIF(@I_ObservID = 0, obs.I_ObservID, @I_ObservID)" +
                               "ORDER BY ec_obl.Ano, ec_obl.P, ec_obl.Cuota_pago, ec_obl.cod_alu;";

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


        public static IEnumerable<DetalleObligacion> ObtenerDetalle(int obligacionID)
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
