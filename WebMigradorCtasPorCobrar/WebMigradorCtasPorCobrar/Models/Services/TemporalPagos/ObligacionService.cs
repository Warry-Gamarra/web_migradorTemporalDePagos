using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Entities.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;

namespace WebMigradorCtasPorCobrar.Models.Services.TemporalPagos
{
    public class ObligacionService
    {
        public IEnumerable<AnioObligacion> ObtenerAnios(Procedencia procedencia)
        {
            List<AnioObligacion> result = new List<AnioObligacion>();
            string schemaDb = Schema.SetSchema(procedencia);

            foreach (var item in ObligacionRepository.ObtenerAnios(schemaDb))
            {
                result.Add(new AnioObligacion(item));
            }
            return result;
        }


        public IEnumerable<Obligacion> ObtenerObligaciones(Procedencia procedencia)
        {
            string schemaDb = Schema.SetSchema(procedencia);

            return ObligacionRepository.Obtener(schemaDb);
        }

        public IEnumerable<DetalleObligacion> ObtenerDetalleObligacion(Procedencia procedencia, string cuota_pago, 
                                                                        string anio, string p, string cod_alu, 
                                                                        string cod_rc, DateTime fch_venc)
        {
            string schemaDb = Schema.SetSchema(procedencia);

            return ObligacionRepository.ObtenerDetalle(schemaDb, cuota_pago, anio, p, cod_alu, cod_rc, fch_venc);
        }
    }
}