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
    public class ObligacionesRepository
    {
        public static List<TR_ObligacionAluCab> Obtener(int procedencia)
        {
            List<TR_ObligacionAluCab> result;

            try
            {
                string s_command = @"SELECT OC.*, MO.I_RowID AS I_MigracionRowID
                                       FROM TR_ObligacionAluCab OC
		                                    INNER JOIN TC_MatriculaAlumno MA ON OC.I_MatAluID = MA.I_MatAluID
		                                    INNER JOIN BD_OCEF_MigracionTP.dbo.TR_Ec_Obl MO ON OC.I_ProcesoID = MO.Cuota_pago 
					                                   AND CAST(MA.I_Anio AS varchar)= MO.Ano AND MA.I_Periodo = MO.I_Periodo
					                                   AND MA.C_CodAlu = MO.Cod_alu AND MA.C_CodRc = MO.Cod_rc AND OC.I_MontoOblig = MO.Monto
					                                   AND OC.D_FecVencto = MO.Fch_venc
                                      WHERE OC.B_Eliminado = 0
                                            AND MO.I_ProcedenciaID = @I_ProcedenciaID;";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TR_ObligacionAluCab>(s_command, new { I_ProcedenciaID = procedencia }, commandType: CommandType.Text).ToList();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static TR_ObligacionAluCab ObtenerObligacion(int obligacionAluID)
        {
            TR_ObligacionAluCab result;

            try
            {
                string s_command = @"SELECT t.* FROM dbo.TR_ObligacionAluCab t WHERE I_ObligacionAluID = @I_ObligacionAluID;";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.QuerySingleOrDefault<TR_ObligacionAluCab>(s_command,
                                                                                  new { I_ObligacionAluID = obligacionAluID },
                                                                                  commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static List<TR_ObligacionAluDet> ObtenerDetalle(int obligacionAluID)
        {
            List<TR_ObligacionAluDet> result;

            try
            {
                string s_command = @"SELECT t.* FROM dbo.TR_ObligacionAluDet t WHERE I_ObligacionAluID = @I_ObligacionAluID;";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.Query<TR_ObligacionAluDet>(s_command,
                                                                      new { I_ObligacionAluID = obligacionAluID }, 
                                                                      commandType: CommandType.Text).ToList();
                }
            }
            catch (Exception ex)
            {
                throw ex;
            }

            return result;
        }

        public static TR_ObligacionAluDet ObtenerDatosDetalle(int detalleAluID)
        {
            TR_ObligacionAluDet result;

            try
            {
                string s_command = @"SELECT t.* FROM dbo.TR_ObligacionAluDet t WHERE I_ObligacionAluDetID = @I_ObligacionAluDetID;";

                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    result = _dbConnection.QuerySingleOrDefault<TR_ObligacionAluDet>(s_command,
                                                                                  new { I_ObligacionAluDetID = detalleAluID },
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