using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services
{
    public class ObligacionService
    {
        public IEnumerable<Obligacion> ObtenerPosgrado(string anio)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<Obligacion>("SELECT * FROM EUPG_ec_det WHERE ano = @ano "
                                                        , new { ano = anio}, commandType: CommandType.Text);
            }

            return result;
        }





        public Response ObtenerResultadoValidacion(string anio)
        {
            var result = new Response();

            

            return result;
        }


    }
}