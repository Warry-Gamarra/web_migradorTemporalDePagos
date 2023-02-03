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
    public class ConceptoPagoRepository
    {
        public static IEnumerable<TI_ConceptoPago> Obtener()
        {
            IEnumerable<TI_ConceptoPago> result;

            try
            {
                string s_command = @"SELECT c.* FROM TI_ConceptoPago c where c.B_Eliminado = 0";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TI_ConceptoPago>(s_command, commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static TI_ConceptoPago ObtenerPorID(int I_ConcPagID)
        {
            TI_ConceptoPago result;

            try
            {
                string s_command = @"SELECT c.* FROM TI_ConceptoPago c where c.I_ConcPagID = @I_ConcPagID AND c.B_Eliminado = 0";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TI_ConceptoPago>(s_command, new { I_ConcPagID = I_ConcPagID }, commandType: CommandType.Text).FirstOrDefault();
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