using Dapper;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones
{
    public class DetalleObligacionRepository
    {
        public Response CopiarRegistrosDetalle(int procedenciaID, string schemaDB, string anio)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_SchemaDB", dbType: DbType.String, size: 20, value: schemaDB);
                    parameters.Add(name: "T_Anio", dbType: DbType.String, size: 4, value: anio);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_Obligaciones_ObligacionDet_TemporalPagos_MigracionTP_IU_CopiarTabla", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response AsignarObligacionCabIdPorAnio(int procedenciaID, string anio)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_Anio", dbType: DbType.String, size: 4, value: anio);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_Obligaciones_ObligacionDet_MigracionTP_U_AsignarObligacionCabID", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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


        public Response InicializarEstadoValidacionDetalleObligacionPago(int procedenciaID, int ObligacionID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "I_OblRowID", dbType: DbType.Int32, value: ObligacionID);
                    parameters.Add(name: "T_AnioIni", dbType: DbType.String, value: null);
                    parameters.Add(name: "T_AnioFin", dbType: DbType.String, value: null);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_U_InicializarEstadoValidacionDetalleObligacionPago", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarDetalleObligacion(int procedenciaID)
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

                    connection.Execute("USP_U_ValidarDetalleObligacion", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarDetalleObligacionConceptoPago(int procedenciaID)
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

                    connection.Execute("USP_U_ValidarDetalleObligacionConceptoPago", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response ValidarDetalleObligacionConceptoPagoMigrado(int procedenciaID)
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

                    connection.Execute("USP_U_ValidarDetalleObligacionConceptoPagoMigrado", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

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

        public Response SaveCuotaPagoObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET Cuota_pago = @Cuota_Pago, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Cuota_pago = detalleObligacion.Cuota_pago,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SavePeriodoObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET P = @P, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        P = detalleObligacion.P,
                        I_Periodo = detalleObligacion.I_Periodo,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveAnioObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET Ano = @Ano, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Ano = detalleObligacion.Ano,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveConceptoPagoObligacion(DetalleObligacion detalleObligacion)
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
                        Cuota_pago = detalleObligacion.Cuota_pago,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveMontoObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET Monto = @Monto, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Monto = detalleObligacion.Monto,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveEstadoObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET Pagado = @Pagado, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Pagado = detalleObligacion.Pagado,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveEstudianteObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET Cod_alu = @Cod_alu, Cod_rc = @Cod_rc, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Cod_rc = detalleObligacion.Cod_rc,
                        Cod_alu = detalleObligacion.Cod_alu,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveTipoObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET Tipo_oblig = @Tipo_oblig, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Tipo_oblig = detalleObligacion.Tipo_oblig,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveProcedenciaObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET I_ProcedenciaID = @I_ProcedenciaID, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        I_ProcedenciaID = detalleObligacion.I_ProcedenciaID,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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

        public Response SaveFecVencObligacion(DetalleObligacion detalleObligacion)
        {
            Response result = new Response();
            int rowCount = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string sqlCommand = "UPDATE TR_Ec_Det SET Fch_venc = @Fch_venc, B_Actualizado = @B_Actualizado, D_FecActualiza = @D_FecActualiza " +
                                        "WHERE I_RowID = @I_RowID;";

                    rowCount = connection.Execute(sqlCommand, new
                    {
                        Fch_venc = detalleObligacion.Fch_venc,
                        I_RowID = detalleObligacion.I_RowID,
                        B_Actualizado = detalleObligacion.B_Actualizado,
                        D_FecActualiza = detalleObligacion.D_FecActualiza
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