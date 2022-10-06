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


        public static IEnumerable<DetalleObligacion> ObtenerDetalle(string schemaDb, string cuotaPago, string anio, string per,
                                                             string codAlu, string codRc, DateTime fecVenc)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT * FROM {schemaDb}.ec_det WHERE ano = @ano AND p = @p AND cod_alu = @cod_alu " +
                                   $"                                      AND cuota_pago = @cuota_pago AND cod_rc = @cod_rc " +
                                   $"                                      AND fch_venc = @fch_venc;";

                result = connection.Query<DetalleObligacion>(str_query,
                                                             new
                                                             {
                                                                 ano = anio,
                                                                 p = per,
                                                                 cod_alu = codAlu,
                                                                 cod_rc = codRc,
                                                                 cuota_pago = cuotaPago,
                                                                 fch_venc = fecVenc.ToString("yyyyMMdd")
                                                             }, commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<DetalleObligacion> ObtenerObligacionPorCuotaPago(string schemaDb, string cuotaPago)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT ec_obl.*, cp_des.descripcio FROM {schemaDb}.ec_obl " +
                                   $"       LEFT JOIN {schemaDb}.cp_des ON ec_obl.cuota_pago = cp_des.cuota_pago " +
                                   $"WHERE ec_obl.cuota_pago = @cuota_pago;";

                result = connection.Query<DetalleObligacion>(str_query, new { cuota_pago = cuotaPago }, commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<DetalleObligacion> ObtenerDetallePorCuotaPago(string schemaDb, string cuotaPago)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT ec_det.*, cp_pri.descripcio FROM {schemaDb}.ec_det " +
                                   $"       LEFT JOIN {schemaDb}.cp_pri ON ec_det.cuota_pago = cp_pri.cuota_pago AND ec_det.concepto = cp_pri.id_cp " +
                                   $"WHERE ec_det.cuota_pago = @cuota_pago;";

                result = connection.Query<DetalleObligacion>(str_query, new { cuota_pago = cuotaPago }, commandType: CommandType.Text);
            }

            return result;
        }


        public static int ObtenerCantidadFilas(string schemaDB, string tableName)
        {
            int result = 0;

            try
            {
                using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
                {
                    result = connection.ExecuteScalar<int>($"SELECT COUNT(*) FROM {schemaDB}.{ tableName };", commandType: CommandType.Text);
                }
            }
            catch (Exception)
            {
                result = 0;
            }

            return result;
        }


        public static int ObtenerCantidadFilasEliminadas(string schemaDB, string tableName)
        {
            int result = 0;
            bool exists_column = false;
            try
            {
                using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
                {
                    string command = $"IF EXISTS(SELECT * FROM INFORMATION_SCHEMA.COLUMNS " +
                                                $"WHERE TABLE_SCHEMA = '{schemaDB}' AND TABLE_NAME = '{tableName}' AND COLUMN_NAME = 'Eliminado') " +
                                      "    SELECT 1 " +
                                      "ELSE " +
                                      "    SELECT 0 ";

                    exists_column = connection.ExecuteScalar<bool>(command, commandType: CommandType.Text);

                    string command_cols = "SELECT 0;";

                    if (exists_column)
                    {
                        command_cols = $"SELECT COUNT(*) FROM {schemaDB}.{tableName} WHERE Eliminado = 1";
                    }

                    result = connection.ExecuteScalar<int>(command_cols, commandType: CommandType.Text);
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