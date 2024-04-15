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
    public class PagoObligacionRepository
    {
        public Response MigrarDataPagoObligacionesCtasPorCobrar(int obligacionID)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_OblRowID", dbType: DbType.Int32, value: obligacionID);
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

        public Response MigrarDataPagoObligacionesCtasPorCobrarPorObligacionID(int obligacionId)
        {
            Response result = new Response();
            DynamicParameters parameters = new DynamicParameters();

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    parameters.Add(name: "I_OblRowID", dbType: DbType.Int32, value: obligacionId);
                    parameters.Add(name: "B_Resultado", dbType: DbType.Boolean, direction: ParameterDirection.Output);
                    parameters.Add(name: "T_Message", dbType: DbType.String, size: 4000, direction: ParameterDirection.Output);

                    connection.Execute("USP_IU_MigrarPagoObligacionesCtasPorCobrarPorObligacionID", parameters, commandTimeout: 3600, commandType: CommandType.StoredProcedure);

                    result.CurrentID = parameters.Get<int>("I_OblAluID").ToString();
                    result.IsDone = parameters.Get<bool>("B_Resultado");
                    result.Message = parameters.Get<string>("T_Message");
                }
            }
            catch (Exception ex)
            {
                result.CurrentID = "0";
                result.IsDone = false;
                result.Message = ex.Message;
            }

            return result;
        }




    }
}