using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities;

namespace WebMigradorCtasPorCobrar.Models.Services
{
    public class CuotaPagoService
    {
        public IEnumerable<CuotaPagoTP> ObtenerCuotasPagoTP()
        {
            IEnumerable<CuotaPagoTP> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPagoTP>("SELECT * FROM EUPG_cp_des", commandType: CommandType.Text);
            }

            return result;
        }
    }
}