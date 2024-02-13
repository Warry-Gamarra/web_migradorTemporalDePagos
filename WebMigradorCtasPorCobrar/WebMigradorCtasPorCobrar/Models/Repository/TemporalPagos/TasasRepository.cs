using Dapper;
using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;


namespace WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos
{
    public class TasasRepository
    {
        public static IEnumerable<Tasa_EcObl> Obtener_EcObl()
        {
            IEnumerable<Tasa_EcObl> result;

            using (var connection = new SqlConnection(Databases.TemporalTasasConnectionString))
            {
                result = connection.Query<Tasa_EcObl>($"SELECT * FROM dbo.ec_obl ORDER BY Ano, P, Cuota_pago",
                                                        commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<Obligacion> Obtener_EcObl(string anio)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalTasasConnectionString))
            {
                result = connection.Query<Obligacion>($"SELECT * FROM dbo.ec_obl " +
                                                       "WHERE Ano = @T_Anio ORDER BY P, Cuota_pago",
                                                       new { T_Anio = anio },
                                                       commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<Obligacion> Obtener_EcObl_PorCuotaPago(string cuotaPago)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalTasasConnectionString))
            {
                string str_query = $"SELECT ec_obl.*, cp_des.descripcio FROM dbo.ec_obl " +
                                   $"       LEFT JOIN dbo.cp_des ON ec_obl.cuota_pago = cp_des.cuota_pago " +
                                   $"WHERE ec_obl.cuota_pago = @cuota_pago;";

                result = connection.Query<Obligacion>(str_query, new { cuota_pago = cuotaPago }, commandType: CommandType.Text);
            }

            return result;
        }

    }
}