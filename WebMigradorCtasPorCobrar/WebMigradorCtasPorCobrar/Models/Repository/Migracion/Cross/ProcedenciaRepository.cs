using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross
{
    public class ProcedenciaRepository
    {
        public static IEnumerable<ProcedenciaData> Obtener()
        {
            IEnumerable<ProcedenciaData> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<ProcedenciaData>($"SELECT * FROM dbo.TC_ProcedenciaData", commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<CarreraProcedencia> ObtenerCarreraByProcID(int procedenciaID)
        {
            IEnumerable<CarreraProcedencia> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CarreraProcedencia>($"SELECT * FROM dbo.TC_CarreraProcedencia WHERE I_ProcedenciaID = @I_ProcedenciaID"
                                                               , new { I_ProcedenciaID = procedenciaID }, commandType: CommandType.Text);
            }

            return result;
        }

    }
}