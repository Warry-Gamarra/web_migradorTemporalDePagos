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
                string s_command = @"SELECT c.I_ConcPagID, cp.I_ConceptoID, catg.T_CatPagoDesc, p.T_ProcesoDesc, ISNULL(c.T_ConceptoPagoDesc, cp.T_ConceptoDesc) as T_ConceptoDesc,
	   c.I_Anio, c.I_Periodo, c.M_Monto, c.M_MontoMinimo, c.B_Habilitado, 

FROM dbo.TI_ConceptoPago c
	INNER JOIN dbo.TC_Concepto cp ON cp.I_ConceptoID = c.I_ConceptoID
	INNER JOIN dbo.TC_Proceso p ON p.I_ProcesoID = c.I_ProcesoID
	INNER JOIN dbo.TC_CategoriaPago catg ON catg.I_CatPagoID = p.I_CatPagoID
	LEFT JOIN BD_OCEF_MigracionTP.dbo.TC_CatalogoTabla ct ON ct.I_TablaID = c.I_MigracionTablaID 
	LEFT JOIN BD_OCEF_MigracionTP.dbo.TR_Cp_Pri cp_pri ON cp_pri.Id_cp = c.I_MigracionRowID
WHERE  c.B_Eliminado = 0 ";

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