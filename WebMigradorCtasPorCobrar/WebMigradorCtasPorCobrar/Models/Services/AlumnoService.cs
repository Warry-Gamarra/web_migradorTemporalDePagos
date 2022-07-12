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

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
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
                result = connection.Query<AlumnoMG>("SELECT * FROM TR_Alumnos", commandType: CommandType.Text);
            }

            return result;
        }


        public AlumnoMG ObtenerAlumnosMG(int id)
        {
            AlumnoMG result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.QuerySingleOrDefault<AlumnoMG>("SELECT * FROM TR_Alumnos WHERE I_RowID = @I_RowID", 
                                                                    new { I_RowID = id }, commandType: CommandType.Text);
            }

            return result;
        }

    }
}