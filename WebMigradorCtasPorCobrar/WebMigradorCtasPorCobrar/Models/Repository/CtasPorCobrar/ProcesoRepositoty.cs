﻿using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar
{
    public class ProcesoRepositoty
    {
        public static IEnumerable<VW_Proceso> Obtener(int procedenciaID)
        {
            IEnumerable<VW_Proceso> result;
            string command;
            try
            {
                using (var _dbConnection = new SqlConnection(Databases.CtasPorCobrarConnectionString))
                {
                    command = @"SELECT DISTINCT p.I_ProcesoID, cp.I_CatPagoID, cp.T_CatPagoDesc, per.T_OpcionDesc AS T_PeriodoDesc, p.I_Periodo, per.T_OpcionCod AS C_PeriodoCod,  
                                       p.I_Anio, p.D_FecVencto, p.I_Prioridad, p.N_CodBanco, p.T_ProcesoDesc, cp.B_Obligacion, cp.I_Nivel, niv.T_OpcionCod AS C_Nivel, 
		                               cp.I_TipoAlumno, tipAlu.T_OpcionDesc AS T_TipoAlumno, tipAlu.T_OpcionCod as C_TipoAlumno, 
                                       p.I_MigracionRowID, p.I_MigracionTablaID, cp_des.cuota_pago,  cta.C_NumeroCuenta, p.B_Mora,
                                       IIF(p.I_MigracionTablaID IS NULL, 'S/MIGRAR', ct.T_TablaNom) AS T_TablaNom, 
                                       IIF(I_MigracionRowID IS NULL, 0, 1) AS B_Migrado, p.B_Eliminado 
                                 FROM  dbo.TC_Proceso p
                                       INNER JOIN BD_OCEF_MigracionTP.dbo.TR_Cp_Des cp_des ON p.I_ProcesoID = cp_des.cuota_pago AND cp_des.I_ProcedenciaID = @I_ProcedenciaID
                                       LEFT JOIN BD_OCEF_MigracionTP.dbo.TC_CatalogoTabla ct ON p.I_MigracionTablaID = ct.I_TablaID
                                       INNER JOIN dbo.TC_CategoriaPago cp ON p.I_CatPagoID = cp.I_CatPagoID 
                                       LEFT JOIN dbo.TC_CatalogoOpcion per ON per.I_OpcionID = p.I_Periodo 
                                       LEFT JOIN dbo.TC_CatalogoOpcion niv ON niv.I_OpcionID = cp.I_Nivel 
                                       LEFT JOIN dbo.TC_CatalogoOpcion tipAlu ON tipAlu.I_OpcionID = cp.I_TipoAlumno
                                       LEFT JOIN dbo.VW_CtaDepositoProceso cta ON cta.I_ProcesoID = p.I_ProcesoID
                                 WHERE p.B_Eliminado = 0";

                    result = _dbConnection.Query<VW_Proceso>(command, new { I_ProcedenciaID = procedenciaID }, commandType: CommandType.Text);
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