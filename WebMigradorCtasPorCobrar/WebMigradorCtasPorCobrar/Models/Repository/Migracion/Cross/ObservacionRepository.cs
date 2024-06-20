using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion
{
    public class ObservacionRepository
    {

        public static IEnumerable<Observacion> ObtenerCatalogo()
        {
            IEnumerable<Observacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Observacion>("SELECT I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad " +
                                                                       "FROM dbo.TC_CatalogoObservacion;"
                                                                       , commandType: CommandType.Text);
            }

            return result;
        }

        public static Observacion ObtenerCatalogo(int ObservacionID)
        {
            Observacion result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<Observacion>("SELECT I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad " +
                                                                       "FROM dbo.TC_CatalogoObservacion " +
                                                                       "WHERE I_ObservID = @I_ObservID"
                                                                       , new { I_ObservID = ObservacionID }
                                                                       , commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<Observacion> Obtener(int tablaID, bool procObligacion)
        {
            IEnumerable<Observacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Observacion>("SELECT DISTINCT I_ObservID, I_TablaID, T_TablaNom, T_ObservDesc, T_ObservCod, I_ProcedenciaID " +
                                                       "FROM dbo.VW_ObservacionesTabla " +
                                                       "WHERE I_TablaID = @I_TablaID " +
                                                             "AND B_ObligProc = @B_ObligProc " +
                                                             "AND B_Resuelto = 0;"
                                                       , new { I_TablaID = tablaID, B_ObligProc = procObligacion }
                                                       , commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<Observacion> Obtener(int filaID, int tablaID)
        {
            IEnumerable<Observacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Observacion>("SELECT * FROM dbo.VW_ObservacionesTabla " +
                                                       "WHERE I_FilaTablaID = @I_FilaTablaID AND I_TablaID = @I_TablaID"
                                                       , new { I_FilaTablaID = filaID, I_TablaID = tablaID }
                                                       , commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<Observacion> ObtenerDeCabecercaObligacion(int filaID)
        {
            IEnumerable<Observacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Observacion>("SELECT * FROM dbo.VW_ObservacionesEcObl " +
                                                       "WHERE I_FilaTablaID = @I_FilaTablaID"
                                                       , new { I_FilaTablaID = filaID }
                                                       , commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<Observacion> ObtenerDeDetalleObligacion(int filaID)
        {
            IEnumerable<Observacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Observacion>("SELECT * FROM dbo.VW_ObservacionesEcDet " +
                                                       "WHERE I_FilaTablaID = @I_FilaTablaID"
                                                       , new { I_FilaTablaID = filaID }
                                                       , commandType: CommandType.Text);
            }

            return result;
        }
    }
}