using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross
{
    public class UsuarioRepository
    {
        public static int ObtenerUsuarioCtasPorCobrar()
        {
            try
            {
                string s_command = @"SELECT dbo.Func_Config_CtasPorCobrar_I_ObtenerUsuarioMigracionID();";

                using (var _dbConnection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    return _dbConnection.QuerySingleOrDefault<int>(s_command, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

        }
    }
}