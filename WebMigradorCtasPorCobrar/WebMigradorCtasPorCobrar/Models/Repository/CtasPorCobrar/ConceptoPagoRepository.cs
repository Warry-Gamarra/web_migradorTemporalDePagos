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
        public static IEnumerable<TI_ConceptoPago> Obtener(int procedenciaID)
        {
            IEnumerable<TI_ConceptoPago> result;

            try
            {
                string s_command = @"SELECT c.I_ConcPagID, cp.I_ConceptoID, catg.T_CatPagoDesc, p.T_ProcesoDesc, ISNULL(c.T_ConceptoPagoDesc, cp.T_ConceptoDesc) as T_ConceptoPagoDesc,
	                                        c.I_Anio, c.I_Periodo, c.M_Monto, c.M_MontoMinimo, c.B_Habilitado, c.I_MigracionTablaID, c.I_MigracionRowID, 
	                                        IIF(c.I_MigracionTablaID IS NULL, 'S/MIGRAR', ct.T_TablaNom) AS T_TablaNom, per.T_OpcionDesc AS T_PeriodoDesc, 
	                                        IIF(c.I_MigracionRowID IS NULL, 0, 1) AS B_Migrado, per.T_OpcionCod AS T_PeriodoCod
                                       FROM dbo.TI_ConceptoPago c
	                                        INNER JOIN dbo.TC_Concepto cp ON cp.I_ConceptoID = c.I_ConceptoID
	                                        INNER JOIN dbo.TC_Proceso p ON p.I_ProcesoID = c.I_ProcesoID
	                                        INNER JOIN dbo.TC_CategoriaPago catg ON catg.I_CatPagoID = p.I_CatPagoID
                                            LEFT JOIN dbo.TC_CatalogoOpcion per ON per.I_OpcionID = p.I_Periodo 
	                                        LEFT JOIN BD_OCEF_MigracionTP.dbo.TC_CatalogoTabla ct ON ct.I_TablaID = c.I_MigracionTablaID 
	                                        LEFT JOIN BD_OCEF_MigracionTP.dbo.TR_Cp_Pri cp_pri ON cp_pri.Id_cp = c.I_ConcPagID AND cp_pri.I_ProcedenciaID = @I_ProcedenciaID  
                                      WHERE c.B_Eliminado = 0";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TI_ConceptoPago>(s_command, new { I_ProcedenciaID = procedenciaID }, commandType: CommandType.Text);
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
                string s_command = "SELECT c.*, per.T_OpcionCod as T_PeriodoCod, tOblig.T_OpcionDesc as T_Obligigacion, c.T_Clasificador as T_Clasificador2 FROM TI_ConceptoPago c " +
                                                    "LEFT JOIN dbo.TC_CatalogoOpcion per ON per.I_OpcionID = c.I_Periodo " +
                                                    "LEFT JOIN dbo.TC_CatalogoOpcion tOblig ON tOblig.I_OpcionID = c.I_TipoObligacion " +
                                    "WHERE c.I_ConcPagID = @I_ConcPagID";

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