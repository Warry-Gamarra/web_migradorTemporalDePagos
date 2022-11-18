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
        public static TI_ConceptoPago FindByID(int I_ConcPagID)
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

        public static List<TC_Concepto> Find()
        {
            List<TC_Concepto> result;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    var s_command = @"SELECT c.* FROM TC_Concepto c WHERE c.B_Eliminado = 0";

                    result = _dbConnection.Query<TC_Concepto>(s_command, commandType: CommandType.Text).ToList();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static List<TC_Concepto> Find(bool esObligacion)
        {
            List<TC_Concepto> result;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    var s_command = @"SELECT c.* FROM TC_Concepto c WHERE c.B_Eliminado = 0 AND c.B_EsObligacion = @B_EsObligacion";

                    result = _dbConnection.Query<TC_Concepto>(s_command, new { B_EsObligacion = esObligacion ? 1 : 0 }, commandType: CommandType.Text).ToList();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static TC_Concepto Find(int conceptoID)
        {
            TC_Concepto result;

            try
            {
                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    var s_command = @"SELECT c.* FROM TC_Concepto c WHERE I_ConceptoID = @I_ConceptoID AND c.B_Eliminado = 0";

                    result = _dbConnection.QuerySingleOrDefault<TC_Concepto>(s_command, new { I_ConceptoID = conceptoID }, commandType: CommandType.Text);
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