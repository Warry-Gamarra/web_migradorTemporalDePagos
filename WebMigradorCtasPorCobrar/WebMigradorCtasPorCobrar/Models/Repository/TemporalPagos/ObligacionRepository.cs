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
    public class ObligacionRepository
    {
        public static IEnumerable<Obligacion> Obtener(string schemaDb)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<Obligacion>($"SELECT * FROM {schemaDb}.ec_obl ORDER BY Ano, P, Cuota_pago",
                                                        commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<Obligacion> Obtener(string schemaDb, string anio)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<Obligacion>($"SELECT * FROM {schemaDb}.ec_obl " +
                                                       "WHERE Ano = @T_Anio ORDER BY P, Cuota_pago",
                                                       new { T_Anio = anio },
                                                       commandType: CommandType.Text);
            }

            return result;
        }


        public IEnumerable<DetalleObligacion> ObtenerPosgrado(string anio, string per, string codAlu, string cuotaPago, DateTime? fecVenc)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT * FROM EUPG.ec_det WHERE ano = @ano AND p = @p AND cod_alu = @cod_alu AND cuota_pago = @cuota_pago";
                str_query += fecVenc.HasValue ? " AND fhc_venc = @fch_venc;" : ";";

                result = connection.Query<DetalleObligacion>(str_query,
                                                       new
                                                       {
                                                           ano = anio,
                                                           p = per,
                                                           cod_alu = codAlu,
                                                           cuota_pago = cuotaPago,
                                                           fch_venc = fecVenc
                                                       }, commandType: CommandType.Text);
            }

            return result;
        }


        public int ObtenerCantidadFilas(string schemaDB, string tableName)
        {
            int result = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
                {
                    result = connection.Execute($"SELECT COUNT(*) FROM {schemaDB}.{ tableName };", commandType: CommandType.Text);
                }
            }
            catch (Exception ex)
            {
                result = 0;
            }

            return result;
        }



        public int ObtenerCantidadFilasEliminadas(string schemaDB, string tableName)
        {
            int result = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string command = $"IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = '{schemaDB}' AND TABLE_NAME = '{tableName}' AND COLUMN_NAME = 'Eliminado') " +
                                      "    SELECT 1 " +
                                      "ELSE " +
                                      "    SELECT 0 ";

                    result = connection.ExecuteScalar<int>(command, commandType: CommandType.Text);


                    string command2 = $"    SELECT COUNT(*) FROM {schemaDB}.{tableName} WHERE Eliminado = 1";

//result = connection.Execute(command, commandType: CommandType.Text);
                }
            }
            catch (Exception)
            {
                result = 0;
            }

            return result;
        }
    }
}