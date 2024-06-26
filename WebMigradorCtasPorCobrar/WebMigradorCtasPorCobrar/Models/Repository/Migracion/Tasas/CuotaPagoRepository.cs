using Dapper;
using System;
using System.Data;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Tasas
{
    public class CuotaPagoRepository
    {
        public Response CopiarRegistros(int procedenciaID, string codigos_bnc)
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

                    connection.Execute("USP_Tasas_CuotaPago_TemporalTasas_MigracionTP_IU_CopiarTabla", parameters, commandType: CommandType.StoredProcedure);

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

                    connection.Execute("[USP_Tasas_ConceptoPago_MigracionTP_U_InicializarEstadosValidacion]", parameters, commandType: CommandType.StoredProcedure);

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

    }
}