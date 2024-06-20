using Dapper;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;

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

        public static IEnumerable<Alumno> ObtenerSinOblig(string schemaDb, string rcCodFilter)
        {
            IEnumerable<Alumno> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string query = string.Empty;
                if (string.IsNullOrEmpty(schemaDb))
                {
                    query = $"SELECT A.* FROM (SELECT * " +
                                               $"FROM dbo.alumnos WHERE C_RCCOD IN ({rcCodFilter})) A;";
                }
                else
                {
                    query = $"SELECT A.* FROM (SELECT * " +
                                               $"FROM dbo.alumnos WHERE C_RCCOD IN ({rcCodFilter})) A " +
                                                    $"LEFT JOIN (SELECT DISTINCT Cod_alu, Cod_rc FROM {schemaDb}.ec_pri " +
                                                                $"UNION " +
                                                                $"SELECT DISTINCT Cod_alu, Cod_rc FROM {schemaDb}.ec_obl" +
                                                               $") O ON A.C_CODALU = O.cod_alu AND A.C_RCCOD = O.cod_rc " +
                                              $"WHERE O.cod_alu IS NULL AND O.cod_rc IS NULL;";
                }

                result = connection.Query<Alumno>(query, commandTimeout: 3600, commandType: CommandType.Text);

            }

            return result;
        }
    }
}
