using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion
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


        public Response CopiarRegistros(int procedenciaID, string schemaDB, string codigos_bnc)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_SchemaDB", dbType: DbType.String, size: 20, value: schemaDB);
                    parameters.Add(name: "T_Codigo_bnc", dbType: DbType.String, size: 250, value: codigos_bnc);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_IU_CopiarTablaCuotaDePago", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response InicializarEstadoValidacionCuotaPago(int? rowID, int procedenciaID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_InicializarEstadoValidacionCuotaPago", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response MarcarDuplicadosCuotaPago(int procedenciaID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_MarcarRepetidosCuotaDePago", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response MarcarEliminadosCuotaPago(int? rowID, int procedenciaID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_MarcarConceptosPagoEliminados", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response AsignarCategoriaCuotaPago(int? rowID, int procedenciaID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_AsignarCategoriaCuotaPago", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response AsignarAnioCuotaPago(int? rowID, int procedenciaID, string schemaBD)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_SchemaDB", dbType: DbType.String, size: 20, value: schemaBD);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_AsignarAnioCuotaPago", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response AsignarPeriodoCuotaPago(int? rowID, int procedenciaID, string schemaBD)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_SchemaDB", dbType: DbType.String, size: 20, value: schemaBD);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_AsignarPeriodoCuotaPago", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response MigrarDataCuotaPagoCtasPorCobrar(int procedenciaID, int? procesoID, int? anioIni, int? anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcesoID", dbType: DbType.Int32, value: procesoID);
                    parameters.Add(name: "I_AnioIni", dbType: DbType.Int16, value: anioIni);
                    parameters.Add(name: "I_AnioFin", dbType: DbType.Int16, value: anioFin);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Int32, value: procedenciaID);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_IU_MigrarDataCuotaDePagoCtasPorCobrar", parameters, commandType: CommandType.StoredProcedure);

                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response SaveCategoria(CuotaPago cuotaPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des " +
                                                  "SET Codigo_bnc = @Codigo_bnc, " +
                                                      "I_CatPagoID = @I_CatPagoID, " +
                                                      "B_Actualizado = 1, " +
                                                      "D_FecActualiza = GETDATE() " +
                                                  "WHERE I_RowID = @I_RowID;", 
                                                  new { Codigo_bnc = cuotaPago.Codigo_bnc, I_CatPagoID = cuotaPago.I_CatPagoID, I_RowID = cuotaPago.I_RowID}, 
                                                  commandType: CommandType.Text);

                    if (rowCount > 0)
                    {
                        result.IsDone = true;
                        result.Message = "Categoría actualizado correctamente";
                    }
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response SavePeriodo(CuotaPago cuotaPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des " +
                                                  "SET I_Periodo = @I_Periodo, " +
                                                      "B_Actualizado = 1, " +
                                                      "B_MantenerPeriodo = 1, " +
                                                      "D_FecActualiza = GETDATE() " +
                                                  "WHERE I_RowID = @I_RowID;",
                                                  new { I_Periodo = cuotaPago.I_Periodo, I_RowID = cuotaPago.I_RowID },
                                                  commandType: CommandType.Text);

                    if (rowCount > 0)
                    {
                        result.IsDone = true;
                        result.Message = "Periodo actualizado correctamente";
                    }
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response SaveAnio(CuotaPago cuotaPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des " +
                                                  "SET I_Anio = @I_Anio, " +
                                                      "B_Actualizado = 1, " +
                                                      "B_MantenerAnio = 1, " +
                                                      "D_FecActualiza = GETDATE() " +
                                                  "WHERE I_RowID = @I_RowID;",
                                                  new { I_Anio = cuotaPago.I_Anio, I_RowID = cuotaPago.I_RowID },
                                                  commandType: CommandType.Text);

                    if (rowCount > 0)
                    {
                        result.IsDone = true;
                        result.Message = "Año actualizado correctamente";
                    }
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        public Response SaveRepetido(CuotaPago cuotaPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des SET Eliminado = 1 WHERE I_RowID = @I_RowID;",
                                                  new { I_RowID = cuotaPago.I_RowID },
                                                  commandType: CommandType.Text);

                    if (rowCount > 0)
                    {
                        result.IsDone = true;
                        result.Message = "La cuota de pago se desactivó actualizado correctamente";
                    }
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }


        //public Response SaveCuotaPago(CuotaPago cuotaPago)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: cuotaPago.I_RowID);
        //            parameters.Add(name: "Cuota_pago", dbType: DbType.Byte, value: cuotaPago.Cuota_pago);

        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_CambiarCodigoCuotaPago", parameters, commandType: CommandType.StoredProcedure);

        //            result.IsDone = parameters.Get<bool>("B_Resultado");
        //            result.Message = parameters.Get<string>("T_Message");
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        result.IsDone = false;
        //        result.Message = ex.Message;
        //    }

        //    return result;
        //}

    }
}