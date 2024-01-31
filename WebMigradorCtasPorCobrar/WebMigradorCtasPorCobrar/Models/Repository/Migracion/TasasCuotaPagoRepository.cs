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
    public partial class CuotaPagoRepository
    {
        public Response CopiarRegistrosTasas(int procedenciaID, string codigos_bnc)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
                    parameters.Add(name: "T_Codigo_bnc", dbType: DbType.String, size: 250, value: codigos_bnc);

                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_MigracionTP_Tasas_IU_CuotaPagoCopiarTabla", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response InicializarEstadoValidacionCuotaPago(int? rowID, int procedenciaID)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);

        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_InicializarEstadoValidacionCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response MarcarDuplicadosCuotaPago(int procedenciaID)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_MarcarRepetidosCuotaDePago", parameters, commandType: CommandType.StoredProcedure);

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

        //public Response MarcarDuplicadosDiferenteProcedenciaCuotaPago(int procedenciaID)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_ValidarCuotaPagoRepetidaDiferentesProcedencias", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response MarcarEliminadosCuotaPago(int? rowID, int procedenciaID)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_MarcarConceptosPagoEliminados", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response AsignarCategoriaCuotaPago(int? rowID, int procedenciaID)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_AsignarCategoriaCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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

        //public Response AsignarAnioCuotaPago(int? rowID, int procedenciaID, string schemaBD)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "T_SchemaDB", dbType: DbType.String, size: 20, value: schemaBD);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_AsignarAnioCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response AsignarPeriodoCuotaPago(int? rowID, int procedenciaID, string schemaBD)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "T_SchemaDB", dbType: DbType.String, size: 20, value: schemaBD);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_AsignarPeriodoCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response MigrarDataCuotaPagoCtasPorCobrar(int procedenciaID, int? procesoID, int? anioIni, int? anioFin)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            parameters.Add(name: "I_ProcesoID", dbType: DbType.Int32, value: procesoID);
        //            parameters.Add(name: "I_AnioIni", dbType: DbType.Int16, value: anioIni);
        //            parameters.Add(name: "I_AnioFin", dbType: DbType.Int16, value: anioFin);
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Int32, value: procedenciaID);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_IU_MigrarDataCuotaDePagoCtasPorCobrar", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response SaveCategoria(CuotaPago cuotaPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des " +
        //                                          "SET Codigo_bnc = @Codigo_bnc, " +
        //                                              "I_CatPagoID = @I_CatPagoID, " +
        //                                              "B_Actualizado = 1, " +
        //                                              "D_FecActualiza = GETDATE() " +
        //                                          "WHERE I_RowID = @I_RowID;", 
        //                                          new { Codigo_bnc = cuotaPago.Codigo_bnc, I_CatPagoID = cuotaPago.I_CatPagoID, I_RowID = cuotaPago.I_RowID}, 
        //                                          commandType: CommandType.Text);

        //            if (rowCount > 0)
        //            {
        //                result.IsDone = true;
        //                result.Message = "Categoría actualizado correctamente";
        //            }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        result.IsDone = false;
        //        result.Message = ex.Message;
        //    }

        //    return result;
        //}


        //public Response SavePeriodo(CuotaPago cuotaPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des " +
        //                                          "SET I_Periodo = @I_Periodo, " +
        //                                              "B_Actualizado = 1, " +
        //                                              "B_MantenerPeriodo = 1, " +
        //                                              "D_FecActualiza = GETDATE() " +
        //                                          "WHERE I_RowID = @I_RowID;",
        //                                          new { I_Periodo = cuotaPago.I_Periodo, I_RowID = cuotaPago.I_RowID },
        //                                          commandType: CommandType.Text);

        //            if (rowCount > 0)
        //            {
        //                result.IsDone = true;
        //                result.Message = "Periodo actualizado correctamente";
        //            }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        result.IsDone = false;
        //        result.Message = ex.Message;
        //    }

        //    return result;
        //}


        //public Response SaveAnio(CuotaPago cuotaPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des " +
        //                                          "SET I_Anio = @I_Anio, " +
        //                                              "B_Actualizado = 1, " +
        //                                              "B_MantenerAnio = 1, " +
        //                                              "D_FecActualiza = GETDATE() " +
        //                                          "WHERE I_RowID = @I_RowID;",
        //                                          new { I_Anio = cuotaPago.I_Anio, I_RowID = cuotaPago.I_RowID },
        //                                          commandType: CommandType.Text);

        //            if (rowCount > 0)
        //            {
        //                result.IsDone = true;
        //                result.Message = "Año actualizado correctamente";
        //            }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        result.IsDone = false;
        //        result.Message = ex.Message;
        //    }

        //    return result;
        //}


        //public Response SaveRepetido(CuotaPago cuotaPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des SET Eliminado = 1 WHERE I_RowID = @I_RowID;",
        //                                          new { I_RowID = cuotaPago.I_RowID },
        //                                          commandType: CommandType.Text);

        //            if (rowCount > 0)
        //            {
        //                result.IsDone = true;
        //                result.Message = "La cuota de pago se desactivó actualizado correctamente";
        //            }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        result.IsDone = false;
        //        result.Message = ex.Message;
        //    }

        //    return result;
        //}

        //public Response SaveCorrecto(CuotaPago cuotaPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Des SET B_Correcto = 1 WHERE I_RowID = @I_RowID;",
        //                                          new { I_RowID = cuotaPago.I_RowID },
        //                                          commandType: CommandType.Text);

        //            if (rowCount > 0)
        //            {
        //                result.IsDone = true;
        //                result.Message = "La cuota de pago se actualizado correctamente";
        //            }
        //        }
        //    }
        //    catch (Exception ex)
        //    {
        //        result.IsDone = false;
        //        result.Message = ex.Message;
        //    }

        //    return result;
        //}
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