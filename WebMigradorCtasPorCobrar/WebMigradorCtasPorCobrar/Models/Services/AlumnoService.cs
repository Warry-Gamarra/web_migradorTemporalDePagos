using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Dapper;
using System.Data;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities;


namespace WebMigradorCtasPorCobrar.Models.Services
{
    public class AlumnoService
    {
        public IEnumerable<AlumnoTP> ObtenerAlumnosTP()
        {
            IEnumerable<AlumnoTP> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<AlumnoTP>("SELECT * FROM alumnos", commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<AlumnoMG> ObtenerAlumnosMG()
        {
            IEnumerable<AlumnoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<AlumnoMG>("SELECT * FROM TC_MG_Alumnos", commandType: CommandType.Text);
            }

            return result;
        }

    }
}