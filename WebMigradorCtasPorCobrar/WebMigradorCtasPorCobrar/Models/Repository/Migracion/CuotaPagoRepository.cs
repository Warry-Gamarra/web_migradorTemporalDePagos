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
    public class CuotaPagoRepository
    {
        public static IEnumerable<CuotaPago> Obtener(int procedenciaID)
        {
            IEnumerable<CuotaPago> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPago>("SELECT * FROM dbo.TR_Cp_Des WHERE I_ProcedenciaID = @I_ProcedenciaID"
                                                        , new { I_ProcedenciaID = procedenciaID }
                                                        , commandType: CommandType.Text);
            }

            return result;
        }
    }
}