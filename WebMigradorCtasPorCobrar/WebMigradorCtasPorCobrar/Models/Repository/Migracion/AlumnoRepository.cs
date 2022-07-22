using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using System.Data;
using Dapper;

namespace WebMigradorCtasPorCobrar.Models.Repository.Migracion
{
    public class AlumnoRepository
    {
        public static IEnumerable<Alumno> Obtener(string schemaDb)
        {
            IEnumerable<Alumno> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Alumno>($"SELECT top 100 * FROM dbo.TR_Alumnos", commandType: CommandType.Text);
            }

            return result;
        }

        public static Alumno Obtener(string schemaDb, int id)
        {
            Alumno result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<Alumno>($"SELECT * FROM {schemaDb}.TR_Alumnos WHERE I_RowID = @I_RowID",
                                                                    new { I_RowID = id }, commandType: CommandType.Text);
            }

            return result;
        }

    }
}