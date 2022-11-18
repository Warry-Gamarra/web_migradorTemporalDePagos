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
    public class CategoriaPagoRepository
    {
        public static List<TC_CategoriaPago> Obtener()
        {
            List<TC_CategoriaPago> result;

            try
            {
                string s_command = @"SELECT t.* FROM dbo.TC_CategoriaPago t WHERE B_Eliminado = 0;";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TC_CategoriaPago>(s_command, commandType: CommandType.Text).ToList();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static TC_CategoriaPago Obtener(int CatePagoID)
        {
            TC_CategoriaPago result;

            try
            {
                string s_command = @"SELECT t.* FROM dbo.TC_CategoriaPago t WHERE I_CatPagoID = @I_CatPagoID;";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.QuerySingleOrDefault<TC_CategoriaPago>(s_command,
                                                                                  new { I_CatPagoID = CatePagoID },
                                                                                  commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }


        public List<TI_ConceptoCategoriaPago> FindByCategoriaID(int categoriaPagoID)
        {
            List<TI_ConceptoCategoriaPago> result;

            try
            {
                string s_command = @"SELECT CCP.*, CP.T_CatPagoDesc, C.T_ConceptoDesc, C.I_Monto, C.I_MontoMinimo, C.T_Clasificador 
                                     FROM dbo.TC_CategoriaPago CP
 	                                     INNER JOIN dbo.TI_ConceptoCategoriaPago CCP ON CP.I_CatPagoID = CCP.I_CatPagoID
 	                                     INNER JOIN dbo.TC_Concepto C ON C.I_ConceptoID = CCP.I_ConceptoID
                                     WHERE CCP.I_CatPagoID = @I_CatPagoID";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TI_ConceptoCategoriaPago>(s_command, new { I_CatPagoID = categoriaPagoID }, commandType: CommandType.Text).ToList();
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
