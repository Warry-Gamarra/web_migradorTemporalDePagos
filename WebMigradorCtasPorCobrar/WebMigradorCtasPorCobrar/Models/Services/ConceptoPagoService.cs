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
    public class ConceptoPagoService
    {
        public IEnumerable<ConceptoPagoTP> ObtenerPosgradoTP()
        {
            IEnumerable<ConceptoPagoTP> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<ConceptoPagoTP>("SELECT * FROM EUPG.cp_pri", commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<ConceptoPagoMG> ObtenerPosgradoMG()
        {
            IEnumerable<ConceptoPagoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<ConceptoPagoMG>("SELECT * FROM TR_MG_CpPri", commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<ConceptoPagoTP> ObtenerEudedTP()
        {
            IEnumerable<ConceptoPagoTP> result;

            using (var connection = new SqlConnection(Databases.TemporalPagoConnectionString))
            {
                result = connection.Query<ConceptoPagoTP>("SELECT * FROM EUPG.cp_pri", commandType: CommandType.Text);
            }

            return result;
        }

        public IEnumerable<ConceptoPagoMG> ObtenerEudedMG()
        {
            IEnumerable<ConceptoPagoMG> result;

            using (var connection = new SqlConnection(Databases.MigracionTPConnectionString))
            {
                result = connection.Query<ConceptoPagoMG>("SELECT * FROM TR_MG_CpPri", commandType: CommandType.Text);
            }

            return result;
        }


    }
}