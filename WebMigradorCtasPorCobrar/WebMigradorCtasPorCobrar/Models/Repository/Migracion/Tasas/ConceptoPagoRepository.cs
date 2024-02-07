using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Tasas
{
    public partial class ConceptoPagoRepository
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

                    connection.Execute("USP_MigracionTP_Tasas_IU_ConceptoPago_CopiarTablaTemporalPagos", parameters, commandType: CommandType.StoredProcedure);

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

                    connection.Execute("USP_MigracionTP_Tasas_U_ConceptoPago_InicializarEstadosValidacion", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response ValidarDuplicadoConceptosPago(int? rowID, int procedenciaID)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            //parameters.Add(name: "I_RowID", dbType: DbType.Int32, value: rowID);
        //            parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_U_MarcarConceptosPagoRepetidos", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response ValidarEliminadoConceptosPago(int? rowID, int procedenciaID)
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


        //public Response ValidarConceptosPagoNoObligacion(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_MarcarConceptosPagoNoObligacion", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response ValidarConceptosPagoObligSinAnioAsignado(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_MarcarConceptosPagoObligSinAnioAsignado", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response ValidarConceptosPagoConAnioDiferenteCuotaPago(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_MarcarConceptosPagoConAnioDiferenteCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response ValidarConceptosPagoObligSinPeriodoAsignado(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_MarcarConceptosPagoObligSinPeriodoAsignado", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response ValidarConceptosPagoConPeriodoDiferenteCuotaPago(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_MarcarConceptosPagoConPeriodoDiferenteCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response ValidarConceptosPagoObligSinCuotaPago(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_MarcarConceptosPagoObligSinCuotaPago", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response AsignarIdEquivalenciasConceptoPago(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_AsignarIdEquivalenciasConceptoPago", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response AsignarEquivalenciasCtasxCobrar(int? rowID, int procedenciaID)
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

        //            connection.Execute("USP_U_ActualizarEquivalenciaCtasPorCobrar", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response GrabarTablaCatalogoConceptos(int procedenciaID)
        //{
        //    Response result = new Response();
        //    DynamicParameters parameters = new DynamicParameters();

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            //parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Byte, value: procedenciaID);
        //            parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
        //            parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

        //            connection.Execute("USP_IU_GrabarTablaCatalogoConceptos", parameters, commandType: CommandType.StoredProcedure);

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


        public Response MigrarDataConceptoPagoCtasPorCobrar(int procedenciaID, int? procesoID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_ProcesoID", dbType: DbType.Int32, value: procesoID);
                    parameters.Add(name: "I_ProcedenciaID", dbType: DbType.Int32, value: procedenciaID);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_MigracionTP_Tasas_IU_ConceptoPago_MigrarDataTemporalPagos", parameters, commandType: CommandType.StoredProcedure);

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


        //public Response Save(ConceptoPago conceptoPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri " +
        //                                          "SET I_TipPerID = @I_TipPerID, " +
        //                                              "P = @T_PerCod, " +
        //                                              "B_Actualizado = 1, " +
        //                                              "B_MantenerPeriodo = 1, " +
        //                                              "D_FecActualiza = GETDATE() " +
        //                                          "WHERE I_RowID = @I_RowID;",
        //                                          new
        //                                          {
        //                                              I_TipPerID = conceptoPago.I_TipPerID,
        //                                              I_RowID = conceptoPago.I_RowID,
        //                                              T_PerCod = conceptoPago.P
        //                                          },
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


        //public Response SavePeriodo(ConceptoPago conceptoPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri " +
        //                                          "SET I_TipPerID = @I_TipPerID, " +
        //                                              "P = @T_PerCod, " +
        //                                              "B_Actualizado = 1, " +
        //                                              "B_MantenerPeriodo = 1, " +
        //                                              "D_FecActualiza = GETDATE() " +
        //                                          "WHERE I_RowID = @I_RowID;",
        //                                          new
        //                                          {
        //                                              I_TipPerID = conceptoPago.I_TipPerID,
        //                                              I_RowID = conceptoPago.I_RowID,
        //                                              T_PerCod = conceptoPago.P
        //                                          },
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


        //public Response SaveAnio(ConceptoPago conceptoPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri " +
        //                                          "SET Ano = @I_Anio, " +
        //                                              "B_Actualizado = 1, " +
        //                                              "B_MantenerAnio = 1, " +
        //                                              "D_FecActualiza = GETDATE() " +
        //                                          "WHERE I_RowID = @I_RowID;",
        //                                          new { I_Anio = conceptoPago.Ano, I_RowID = conceptoPago.I_RowID },
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


        //public Response SaveCuotaPago(ConceptoPago conceptoPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri " +
        //                                          "SET cuota_pago = @Cuota_Pago, " +
        //                                              "B_Actualizado = 1, " +
        //                                              "D_FecActualiza = GETDATE() " +
        //                                          "WHERE I_RowID = @I_RowID;",
        //                                          new { Cuota_Pago = conceptoPago.Cuota_pago, I_RowID = conceptoPago.I_RowID },
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


        //public Response SaveRepetido(ConceptoPago conceptoPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri SET I_Anio = @I_Anio WHERE I_RowID = @I_RowID;",
        //                                          new { I_Anio = conceptoPago.P, I_RowID = conceptoPago.I_RowID },
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


        //public Response SaveEstadoObligacion(ConceptoPago conceptoPago)
        //{
        //    Response result = new Response();
        //    int rowCount = 0;

        //    try
        //    {
        //        using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
        //        {
        //            rowCount = connection.Execute("UPDATE dbo.TR_Cp_Pri SET Tipo_oblig = @TipoObligacion WHERE I_RowID = @I_RowID;",
        //                                          new { TipoObligacion = conceptoPago.Tipo_oblig, I_RowID = conceptoPago.I_RowID },
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
    }
}