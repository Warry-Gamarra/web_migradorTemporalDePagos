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
    public class ObligacionRepository
    {
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

        public Response CopiarRegistrosCabecera(int procedenciaID, string schemaDB, string anioIni, string anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_SchemaDB", dbType: DbType.String, size: 20, value: schemaDB);
                    parameters.Add(name: "T_AnioIni", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "T_AnioFin", dbType: DbType.String, size: 4, value: anioFin);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_IU_CopiarTablaObligacionesPago", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response InicializarEstadoValidacionObligacionPago(int procedenciaID, int? rowID, string anioIni, string anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "T_AnioIni", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "T_AnioFin", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_InicializarEstadoValidacionObligacionPago", parameters, commandType: CommandType.StoredProcedure);

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

        public Response ValidarAlumnoCabeceraObligacion(int procedenciaID, int? rowID, string anioIni, string anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "I_AnioIni", dbType: DbType.Int16, value: anioIni);
                    parameters.Add(name: "I_AnioFin", dbType: DbType.Int16, value: anioFin);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_ValidarExisteAlumnoCabeceraObligacion", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarAnioEnCabeceraObligacion(int procedenciaID, int? rowID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_ValidarAnioEnCabeceraObligacion", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarPeriodoEnCabeceraObligacion(int procedenciaID, int? rowID, string anioIni, string anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_AnioIni", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "T_AnioFin", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_ValidarPeriodoEnCabeceraObligacion", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarFechaVencimientoCuotaObligacion(int procedenciaID, int? rowID, string anioIni, string anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "T_AnioIni", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "T_AnioFin", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_ValidarFechaVencimientoCuotaObligacion", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarObligacionCuotaPagoMigrada(int procedenciaID, int? rowID, string anioIni, string anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "T_AnioIni", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "T_AnioFin", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_ValidarObligacionCuotaPagoMigrada", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarProcedenciaObligacionCuotaPago(int procedenciaID, int? rowID, string anioIni, string anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
                    parameters.Add(name: "T_AnioIni", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "T_AnioFin", dbType: DbType.String, size: 4, value: anioIni);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_ValidarProcedenciaObligacionCuotaPago", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response MigrarDataObligacionesCtasPorCobrar(int procedenciaID, int? procesoID, int? anioIni, int? anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Int32, value: procedenciaID);
                    parameters.Add(name: "I_ProcesoID", dbType: DbType.Int32, value: procesoID);
                    parameters.Add(name: "I_AnioIni", dbType: DbType.Int16, value: anioIni);
                    parameters.Add(name: "I_AnioFin", dbType: DbType.Int16, value: anioFin);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_IU_MigrarObligacionesCtasPorCobrar", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response MigrarDataPagoObligacionesCtasPorCobrar(int procedenciaID, int? procesoID, int? anioIni, int? anioFin)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Int32, value: procedenciaID);
                    parameters.Add(name: "I_ProcesoID", dbType: DbType.Int32, value: procesoID);
                    parameters.Add(name: "I_AnioIni", dbType: DbType.Int16, value: anioIni);
                    parameters.Add(name: "I_AnioFin", dbType: DbType.Int16, value: anioFin);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_IU_MigrarPagoObligacionesCtasPorCobrar", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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


        public Response SaveCuotaPagoObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET Cuota_pago = @Cuota_Pago, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Cuota_pago = obligacion.Cuota_pago,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response SavePeriodoObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET P = @P, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        P = obligacion.P,
                        I_Periodo = obligacion.I_Periodo,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response SaveAnioObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET Ano = @Ano, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Ano = obligacion.Ano,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response SaveMontoObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET Monto = @Monto, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Monto = obligacion.Monto,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response SaveEstadoObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET Pagado = @Pagado, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Pagado = obligacion.Pagado,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response SaveEstudianteObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET Cod_alu = @Cod_alu, Cod_RC = @Cod_RC, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Cod_RC = obligacion.Cod_RC,
                        Cod_alu = obligacion.Cod_alu,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response SaveTipoObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET Tipo_oblig = @Tipo_oblig, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Tipo_oblig = obligacion.Tipo_oblig,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }

        public Response SaveFecVencObligacion(Obligacion obligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Obl SET Fch_venc = @Fch_venc, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Fch_venc = obligacion.Fch_venc,
                        I_RowID = obligacion.I_RowID,
                        B_Actualizado = obligacion.B_Actualizado,
                        D_FecActualiza = obligacion.D_FecActualiza
                    },
                    commandTimeout: 3600,
                    commandType: CommandType.Text);
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
