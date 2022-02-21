using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Dapper;
using System.Data.SqlClient;
using WebMigradorCtasPorCobrar.Models.Entities;

namespace WebMigradorCtasPorCobrar.Models.Services
{
    public class AlumnoService
    {
        public IEnumerable<Alumno> ObtenerAlumnos()
        {
            IEnumerable<Alumno> result;

            using (var connection = new SqlConnection())
            {

            }

            return result;
        }

    }
}