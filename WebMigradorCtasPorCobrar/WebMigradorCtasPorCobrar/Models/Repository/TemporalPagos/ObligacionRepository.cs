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

        public static IEnumerable<string> ObtenerAnios(string schemaDb)
        {
            IEnumerable<string> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<string>($"SELECT Ano_obl FROM (SELECT DISTINCT IIF(ISNUMERIC(Ano) = 1, Ano, 'NO NUMERICO') AS Ano_obl " +
                                                                       $"FROM {schemaDb}.ec_obl) TBL ORDER BY Ano_obl",
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
                                   $"                                      AND fch_venc = @fch_venc" +
                                   $"                                      AND Concepto_f = 0;";

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

        public static IEnumerable<Obligacion> ObtenerObligacionPorCuotaPago(string schemaDb, string cuotaPago)
        {
            IEnumerable<Obligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT ec_obl.*, cp_des.descripcio FROM {schemaDb}.ec_obl " +
                                   $"       LEFT JOIN {schemaDb}.cp_des ON ec_obl.cuota_pago = cp_des.cuota_pago " +
                                   $"WHERE ec_obl.cuota_pago = @cuota_pago;";

                result = connection.Query<Obligacion>(str_query, new { cuota_pago = cuotaPago }, commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<DetalleObligacion> ObtenerObligacionPorConceptoPago(string schemaDb, string conceptoPago)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT ec_obl.*, cp_pri.descripcio FROM {schemaDb}.ec_obl " +
                                   $"       INNER JOIN {schemaDb}.ec_det ON ec_obl.cuota_pago = ec_det.cuota_pago " +
                                   $"                                   AND ec_obl.ano = ec_det.ano " +
                                   $"                                   AND ec_obl.P = ec_det.P " +
                                   $"                                   AND ec_obl.cod_alu = ec_det.cod_alu " +
                                   $"                                   AND ec_obl.cod_rc = ec_det.cod_rc " +
                                   $"                                   AND ec_obl.fch_venc = ec_det.fch_venc " +
                                   $"       INNER JOIN {schemaDb}.cp_pri ON ec_det.concepto = cp_pri.id_cp " +
                                   $"WHERE cp_pri.id_cp = @id_cp;";

                result = connection.Query<DetalleObligacion>(str_query, new { id_cp = conceptoPago }, commandType: CommandType.Text);
            }

            return result;
        }


        public static IEnumerable<DetalleObligacion> ObtenerDetallePorCuotaPago(string schemaDb, string cuotaPago)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT ec_det.*, cp_pri.descripcio FROM {schemaDb}.ec_det " +
                                   $"       LEFT JOIN {schemaDb}.cp_des ON ec_det.cuota_pago = cp_des.cuota_pago " +
                                   $"       LEFT JOIN {schemaDb}.cp_pri ON ec_det.concepto = cp_pri.id_cp " +
                                   $"WHERE ec_det.cuota_pago = @cuota_pago AND Concepto_f = 0;";

                result = connection.Query<DetalleObligacion>(str_query, new { cuota_pago = cuotaPago }, commandType: CommandType.Text);
            }

            return result;
        }

        public static IEnumerable<DetalleObligacion> ObtenerDetallePorConceptoPago(string schemaDb, string conceptoPago)
        {
            IEnumerable<DetalleObligacion> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                string str_query = $"SELECT ec_det.*, cp_pri.descripcio FROM {schemaDb}.ec_det " +
                                   $"       LEFT JOIN {schemaDb}.cp_pri ON  ec_det.concepto = cp_pri.id_cp " +
                                   $"WHERE ec_det.concepto = @concepto AND Concepto_f = 0;";

                result = connection.Query<DetalleObligacion>(str_query, new { concepto = conceptoPago }, commandType: CommandType.Text);
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