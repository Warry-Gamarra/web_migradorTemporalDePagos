using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using System.Data;
using Dapper;

namespace WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos
{
    public class AlumnoRepository
    {
        public static IEnumerable<Alumno> Obtener(string schemaDb)
        {
            IEnumerable<Alumno> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<Alumno>($"SELECT A.* FROM dbo.alumnos A " +
                                                             $"INNER JOIN (SELECT DISTINCT Cod_alu, Cod_rc FROM {schemaDb}.ec_pri) O ON A.C_CODALU = O.cod_alu AND A.C_RCCOD = O.cod_rc " +
                                                  $"UNION " +
                                                  $"SELECT A.* FROM dbo.alumnos A " +
                                                             $"INNER JOIN (SELECT DISTINCT Cod_alu, Cod_rc FROM {schemaDb}.ec_obl) O ON A.C_CODALU = O.cod_alu AND A.C_RCCOD = O.cod_rc;"
                                                  , commandTimeout: 3600
                                                  , commandType: CommandType.Text);

            }

            return result;
        }
    }
}
