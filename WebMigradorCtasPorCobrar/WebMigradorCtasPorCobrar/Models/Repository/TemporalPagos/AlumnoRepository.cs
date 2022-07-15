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
                result = connection.Query<Alumno>($"SELECT * FROM {schemaDb}.alumnos", commandType: CommandType.Text);
            }

            return result;
        }
    }
}