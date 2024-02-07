using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using Temporal = WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;
using RepoCtas = WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using ClosedXML.Excel;
using System.IO;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross
{
    public class ConceptoPagoService
    {
        private readonly Obligaciones.ConceptoPagoService _conceptoPagoObligacionesService;
        private readonly Tasas.ConceptoPagoService _conceptoPagoTasasService;

        public ConceptoPagoService()
        {
            _conceptoPagoObligacionesService = new Obligaciones.ConceptoPagoService();
            _conceptoPagoTasasService = new Tasas.ConceptoPagoService();
        }

        public IEnumerable<ConceptoPago> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObtenerConRepo(ConceptoPagoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Pri), procedencia);
            }

            return ObtenerConRepo(ConceptoPagoRepository.Obtener((int)procedencia), procedencia);
        }

        private IEnumerable<ConceptoPago> ObtenerConRepo(IEnumerable<ConceptoPago> conceptosPago, Procedencia procedencia)
        {
            var conceptosPagoCtas = RepoCtas.ConceptoPagoRepository.Obtener((int)procedencia);

            var newCuotasPago = from c in conceptosPago
                                join cr in conceptosPagoCtas on c.Id_cp equals cr.I_ConcPagID
                                into conceptosPagoConceptosPagoCtasGroup
                                from cpg in conceptosPagoConceptosPagoCtasGroup.DefaultIfEmpty()
                                select new ConceptoPago()
                                {
                                    Id_cp = c.Id_cp,
                                    Cuota_pago = c.Cuota_pago,
                                    Descripcio = c.Descripcio,
                                    Ano = c.Ano,
                                    P = c.P,
                                    Cuota_pago_desc = c.Cuota_pago_desc,
                                    Tipo_oblig = c.Tipo_oblig,
                                    Eliminado = c.Eliminado,
                                    Monto = c.Monto,
                                    B_Migrable = c.B_Migrable,
                                    B_Migrado = c.B_Migrado,
                                    I_RowID = c.I_RowID,
                                    B_ExisteCtas = cpg == null ? false : true
                                };

            return newCuotasPago;
        }

        public ConceptoPago Obtener(int cuotaID)
        {
            return ConceptoPagoRepository.ObtenerPorId(cuotaID);
        }


        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = ConceptoPagoRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Pri);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }

        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();

            if (procedencia == Procedencia.Tasas)
            {
                result = _conceptoPagoTasasService.CopiarRegistrosDesdeTemporalPagos(procedencia);
            }
            else
            {
                result = _conceptoPagoObligacionesService.CopiarRegistrosDesdeTemporalPagos(procedencia);
            }

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public List<Response> EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            IEnumerable<Response> result = new List<Response>();

            if (procedencia == Procedencia.Tasas)
            {
                result = _conceptoPagoTasasService.EjecutarValidaciones(procedencia, cuotaPagoRowID);
            }
            else
            {
                result = _conceptoPagoObligacionesService.EjecutarValidaciones(procedencia, cuotaPagoRowID);
            }

            return result.ToList();
        }


        public ConceptoPago ObtenerConRelaciones(int conceptoPagoID)
        {
            ConceptoPago conceptoPago = ConceptoPagoRepository.ObtenerPorId(conceptoPagoID);

            conceptoPago.CuotasPago = new List<CuotaPago>();
            conceptoPago.DetalleObligaciones = new List<DetalleObligacion>();

            string schema = Schema.SetSchema((Procedencia)conceptoPago.I_ProcedenciaID);
            string str_conceptoPago = conceptoPago.Id_cp.ToString();

            foreach (var concepto in ConceptoPagoRepository.Obtener(conceptoPago.I_ProcedenciaID).Where(x => x.Id_cp == conceptoPago.Id_cp))
            {
                foreach (var cuotaPago in CuotaPagoRepository.Obtener(concepto.I_ProcedenciaID).Where(x => x.Cuota_pago == concepto.Cuota_pago))
                {
                    conceptoPago.CuotasPago.Add(cuotaPago);
                }
            }

            foreach (var obligacion in Temporal.ObligacionRepository.ObtenerObligacionPorConceptoPago(schema, str_conceptoPago))
            {

            }

            foreach (var detalleObligacion in Temporal.ObligacionRepository.ObtenerDetallePorConceptoPago(schema, str_conceptoPago)//.Where (x => x.Eliminado == false)
                                                                           .Select(x => new
                                                                           {
                                                                               x.Cuota_pago,
                                                                               x.Ano,
                                                                               x.P,
                                                                               x.Concepto,
                                                                               x.Descripcio,
                                                                               x.Eliminado
                                                                           }).Distinct())
            {
                conceptoPago.DetalleObligaciones.Add(new DetalleObligacion()
                {
                    Cuota_pago = detalleObligacion.Cuota_pago,
                    Ano = detalleObligacion.Ano,
                    P = detalleObligacion.P,
                    Concepto = detalleObligacion.Concepto,
                    Descripcio = detalleObligacion.Descripcio,
                    Eliminado = detalleObligacion.Eliminado
                });
            }

            return conceptoPago;
        }


        public Response Save(ConceptoPago conceptoPago, int tipoObserv)
        {
            Response result;

            if (conceptoPago.I_ProcedenciaID == (int)Procedencia.Tasas)
            {
                result = _conceptoPagoTasasService.Save(conceptoPago, tipoObserv);
            }
            else
            {
                result = _conceptoPagoObligacionesService.Save(conceptoPago, tipoObserv);
            }

            return result.IsDone ? result.Success(false) : result.Error(false);
        }
        

        public List<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            IEnumerable<Response> result;

            if (procedencia == Procedencia.Tasas)
            {
                result = _conceptoPagoTasasService.MigrarDatosTemporalPagos(procedencia); 
            }
            else
            {
                result = _conceptoPagoObligacionesService.MigrarDatosTemporalPagos(procedencia);
            }

            return result.ToList();
        }
    }

}