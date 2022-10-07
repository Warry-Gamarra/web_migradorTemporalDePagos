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
    public class CatalogoOpcionRepository
    {

        public static List<TC_CatalogoOpcion> Obtener(int parametroID)
        {
            List<TC_CatalogoOpcion> result;

            try
            {
                string s_command = @"select p.* from TC_CatalogoOpcion p where p.I_ParametroID = @I_ParametroID and p.B_Eliminado = 0 ORDER BY p.T_OpcionDesc";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TC_CatalogoOpcion>(s_command, new { I_ParametroID = parametroID }, commandType: CommandType.Text).ToList();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static TC_CatalogoOpcion ObtenerOpcion(int opcionID)
        {
            TC_CatalogoOpcion result;

            try
            {
                string s_command = @"SELECT t.* FROM dbo.TC_CategoriaPago t WHERE I_OpcionID = @I_OpcionID;";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.QuerySingleOrDefault<TC_CatalogoOpcion>(s_command, 
                                                                                  new { I_OpcionID = opcionID }, 
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