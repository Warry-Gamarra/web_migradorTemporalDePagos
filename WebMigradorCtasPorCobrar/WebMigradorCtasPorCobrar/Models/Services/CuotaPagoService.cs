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
    public class CuotaPagoService
    {
        public IEnumerable<CuotaPagoTP> ObtenerPosgradoTP()
        {
            IEnumerable<CuotaPagoTP> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<CuotaPagoTP>("SELECT * FROM EUPG.cp_des", commandType: CommandType.Text);
            }


            return result;
        }

        public IEnumerable<CuotaPagoMG> ObtenerPosgradoMG()
        {
            IEnumerable<CuotaPagoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPagoMG>("SELECT * FROM TR_MG_CpDes", commandType: CommandType.Text);
            }

            return result;
        }


        public IEnumerable<CuotaPagoMG> ObtenerPregradoTP()
        {
            IEnumerable<CuotaPagoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPagoMG>("SELECT * FROM TR_MG_CpDes", commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<CuotaPagoMG> ObtenerPregradoMG()
        {
            IEnumerable<CuotaPagoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPagoMG>("SELECT * FROM TR_MG_CpDes", commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<CuotaPagoMG> ObtenerEudedTP()
        {
            IEnumerable<CuotaPagoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPagoMG>("SELECT * FROM TR_MG_CpDes", commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<CuotaPagoMG> ObtenerEudedMG()
        {
            IEnumerable<CuotaPagoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<CuotaPagoMG>("SELECT * FROM TR_MG_CpDes", commandType: CommandType.Text);
            }

            return result;
        }


    }
}