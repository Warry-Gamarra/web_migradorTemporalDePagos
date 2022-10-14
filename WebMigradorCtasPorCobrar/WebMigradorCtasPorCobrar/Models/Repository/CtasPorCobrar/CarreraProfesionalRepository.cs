using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar
{
    public class CarreraProfesionalRepository
    {
        public static IEnumerable<VW_CarreraProfesional> Obtener()
        {
            List<VW_CarreraProfesional> result;

            try
            {
                string s_command = @"SELECT t.* FROM dbo.VW_CarreraProfesional t WHERE B_Eliminado = 0;";

                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    result = _dbConnection.Query<VW_CarreraProfesional>(s_command, commandType: CommandType.Text).ToList();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static VW_CarreraProfesional Obtener(string cod_rc)
        {
            VW_CarreraProfesional result = new VW_CarreraProfesional();

            try
            {
                string s_command = @"SELECT t.* FROM dbo.VW_CarreraProfesional t WHERE C_RcCod = @C_RcCod;";

                using (var _dbConnection = new SqlConnection(Databases.RepositorioUnfvConnectionString))
                {
                    result = _dbConnection.QuerySingleOrDefault<VW_CarreraProfesional>(s_command, 
                                                                                  new { C_RcCod = cod_rc }, 
                                                                                  commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

    }
}