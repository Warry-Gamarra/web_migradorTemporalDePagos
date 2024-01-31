using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Helpers;

namespace WebMigradorCtasPorCobrar.Models.Services.TemporalPagos
{
    public class ConceptoPagoService
    {
        public IEnumerable<ConceptoPago> Obtener(Procedencia procedencia)
        {
            string schemaDb = Schema.SetSchema(procedencia);
            string codigos_bnc = "";

            switch (procedencia)
            {
                case Procedencia.Pregrado:
                    codigos_bnc = Constant.PREGRADO_TEMPORAL_CODIGOS_BNC;
                    break;
                case Procedencia.Posgrado:
                    codigos_bnc = Constant.POSGRADO_TEMPORAL_CODIGOS_BNC;
                    break;
                case Procedencia.Cuded:
                    codigos_bnc = Constant.EUDED_TEMPORAL_CODIGOS_BNC + ", "
                                + Constant.PROLICE_TEMPORAL_CODIGOS_BNC + ", "
                                + Constant.PROCUNED_TEMPORAL_CODIGOS_BNC;
                    break;
                case Procedencia.Tasas:
                    codigos_bnc = "''";
                    return ConceptoPagoRepository.ObtenerTasas(schemaDb, codigos_bnc);
                default:
                    codigos_bnc = "''";
                    break;
            }

            return ConceptoPagoRepository.Obtener(schemaDb, codigos_bnc);
        }
    }
}