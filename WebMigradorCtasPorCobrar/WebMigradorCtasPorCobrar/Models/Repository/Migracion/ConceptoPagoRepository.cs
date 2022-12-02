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
    public class ConceptoPagoRepository
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
                                                        "WHERE obs.I_ProcedenciaID = @I_ProcedenciaID AND obs.I_ObservID = @I_ObservID"
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

                    connection.Execute("USP_IU_CopiarTablaConceptoDePago", parameters, commandType: CommandType.StoredProcedure);

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


        public Response InicializarEstadoValidacionCuotaPago(int procedenciaID)
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

                    connection.Execute("USP_U_InicializarEstadoValidacionConceptoPago", parameters, commandType: CommandType.StoredProcedure);

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


        public Response ValidarDuplicadoConceptosPago(int procedenciaID)
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

                    connection.Execute("USP_U_MarcarConceptosPagoRepetidos", parameters, commandType: CommandType.StoredProcedure);

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


        public Response ValidarConceptosPagoObligSinAnioAsignado(int procedenciaID)
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

                    connection.Execute("USP_U_MarcarConceptosPagoObligSinAnioAsignado", parameters, commandType: CommandType.StoredProcedure);

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


        public Response ValidarConceptosPagoObligSinPeriodoAsignado(int procedenciaID)
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

                    connection.Execute("USP_U_MarcarConceptosPagoObligSinPeriodoAsignado", parameters, commandType: CommandType.StoredProcedure);

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


        public Response ValidarConceptosPagoObligSinCuotaPago(int procedenciaID)
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

                    connection.Execute("USP_U_MarcarConceptosPagoObligSinCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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


        public Response AsignarIdEquivalenciasConceptoPago(int procedenciaID)
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

                    connection.Execute("USP_U_AsignarIdEquivalenciasConceptoPago", parameters, commandType: CommandType.StoredProcedure);

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


        public Response AsignarEquivalenciasCtasxCobrar(int procedenciaID)
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

                    connection.Execute("USP_U_ActualizarEquivalenciaCtasPorCobrar", parameters, commandType: CommandType.StoredProcedure);

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


        public Response GrabarTablaCatalogoConceptos(int procedenciaID)
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

                    connection.Execute("USP_IU_GrabarTablaCatalogoConceptos", parameters, commandType: CommandType.StoredProcedure);

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


        public Response MigrarDataConceptoPagoCtasPorCobrar(int procedenciaID, int? procesoID, int? anioIni, int? anioFin)
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

                    connection.Execute("USP_IU_MigrarDataConceptoPagoObligacionesCtasPorCobrar", parameters, commandType: CommandType.StoredProcedure);

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


        public Response SavePeriodo(ConceptoPago conceptoPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri SET I_Anio = @I_Anio WHERE I_RowID = @I_RowID;",
                                                  new { I_Anio = conceptoPago.P, I_RowID = conceptoPago.I_RowID },
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


        public Response SaveAnio(ConceptoPago conceptoPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri " +
                                                  "SET I_Anio = @I_Anio " +
                                                      "B_Actualizado = 1, " +
                                                      "B_MantenerPeriodo = 1, " +
                                                      "D_FecActualiza = GETDATE() " +
                                                  "WHERE I_RowID = @I_RowID;",
                                                  new { I_Anio = conceptoPago.P, I_RowID = conceptoPago.I_RowID },
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


        public Response SaveCuotaPago(ConceptoPago conceptoPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri " +
                                                  "SET cuota_pago = @I_Anio " +
                                                      "B_Actualizado = 1, " +
                                                      "B_MantenerPeriodo = 1, " +
                                                      "D_FecActualiza = GETDATE() " +
                                                  "WHERE I_RowID = @I_RowID;",
                                                  new { I_Anio = conceptoPago.P, I_RowID = conceptoPago.I_RowID },
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


        public Response SaveRepetido(ConceptoPago conceptoPago)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri SET I_Anio = @I_Anio WHERE I_RowID = @I_RowID;",
                                                  new { I_Anio = conceptoPago.P, I_RowID = conceptoPago.I_RowID },
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
    }
}