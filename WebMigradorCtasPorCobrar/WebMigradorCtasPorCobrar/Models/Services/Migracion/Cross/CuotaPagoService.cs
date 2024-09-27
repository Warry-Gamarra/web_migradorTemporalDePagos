using ClosedXML.Excel;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using RepoCtas = WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;
using Temporal = WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross
{
    public class CuotaPagoService
    {
        private readonly Obligaciones.CuotaPagoService _cuotaPagoObligacionServices;
        private readonly Tasas.CuotaPagoService _cuotaPagoTasasServices;

        public CuotaPagoService()
        {
            _cuotaPagoObligacionServices = new Obligaciones.CuotaPagoService();
            _cuotaPagoTasasServices = new Tasas.CuotaPagoService();
        }

        public IEnumerable<CuotaPago> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObtenerConRepo(CuotaPagoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Des), procedencia);
            }

            return ObtenerConRepo(CuotaPagoRepository.Obtener((int)procedencia), procedencia);
        }

        private IEnumerable<CuotaPago> ObtenerConRepo(IEnumerable<CuotaPago> cuotasPago, Procedencia procedencia)
        {
            var newCuotasPago = from c in cuotasPago
                                where c.I_ProcedenciaID == (int) procedencia
                                select new CuotaPago()
                                {
                                    Cuota_pago = c.Cuota_pago,
                                    Descripcio = c.Descripcio,
                                    I_Anio = c.I_Anio,
                                    PeriodoDesc = c.PeriodoDesc,
                                    N_cta_cte = c.N_cta_cte,
                                    Codigo_bnc = c.Codigo_bnc,
                                    Fch_venc = c.Fch_venc,
                                    Eliminado = c.Eliminado,
                                    B_Migrable = c.B_Migrable,
                                    B_Migrado = c.B_Migrado,
                                    I_RowID = c.I_RowID,
                                    Prioridad = c.Prioridad,
                                    C_mora = c.C_mora,
                                    B_ExisteCtas = c.B_ExisteCtas,
                                    I_CtaDepoProID = c.I_CtaDepoProID
                                };

            return newCuotasPago;
        }

        public CuotaPago Obtener(int cuotaID)
        {
            var result = CuotaPagoRepository.ObtenerPorId(cuotaID);

            if (result.I_CatPagoID.HasValue)
            {
                result.CatPagoDesc = CategoriaPagoRepository.Obtener(result.I_CatPagoID.Value).T_CatPagoDesc;
            }

            return CuotaPagoRepository.ObtenerPorId(cuotaID);
        }

        public CuotaPagoViewModel ObtenerVistaDatos(int id, Procedencia procedencia)
        {
            ProcesoServices _cuotaPagoServiceCtasPorCobrar = new ProcesoServices();
            var result = new CuotaPagoViewModel()
            {
                CuotaMigracion = Obtener(id),
            };

            result.CuotaCtasCobrar = _cuotaPagoServiceCtasPorCobrar.Obtener(procedencia)
                                                                   .FirstOrDefault(x => x.Cuota_Pago == result.CuotaMigracion.Cuota_pago);

            return result;
        }


        public CuotaPago ObtenerConRelaciones(int cuotaID)
        {
            var cuotaPago = CuotaPagoRepository.ObtenerPorId(cuotaID);

            cuotaPago.Fch_venc_s = cuotaPago.Fch_venc.ToShortDateString();
            cuotaPago.ConceptosPago = new List<ConceptoPago>();
            cuotaPago.Obligaciones = new List<Obligacion>();
            cuotaPago.DetalleObligaciones = new List<DetalleObligacion>();

            string schema = Schema.SetSchema((Procedencia)cuotaPago.I_ProcedenciaID);

            foreach (var Temp_conceptoPago in Temporal.ConceptoPagoRepository.ObtenerPorCuotaPago(schema, cuotaPago.Cuota_pago.ToString()))
            {
                cuotaPago.ConceptosPago.Add(new ConceptoPago(Temp_conceptoPago));
            }

            foreach (var Temp_item in Temporal.ObligacionRepository.ObtenerObligacionPorCuotaPago(schema, cuotaPago.Cuota_pago.ToString())
                                                                   .Select(x => new { x.Ano, x.P, x.Cuota_pago, x.Descripcio })
                                                                   .Distinct())
            {
                var obligacion = new Entities.TemporalPagos.Obligacion()
                {
                    Ano = Temp_item.Ano,
                    P = Temp_item.P,
                    Cuota_pago = Temp_item.Cuota_pago,
                    Descripcio = Temp_item.Descripcio,
                };

                cuotaPago.Obligaciones.Add(new Obligacion(obligacion));
            }

            foreach (var Temp_item in Temporal.ObligacionRepository.ObtenerDetallePorCuotaPago(schema, cuotaPago.Cuota_pago.ToString())//.Where(x => x.Eliminado == false)
                                                                   .Select(x => new { x.Ano, x.P, x.Cuota_pago, x.Concepto, x.Descripcio, x.Eliminado })
                                                                   .Distinct().OrderBy(x => x.Ano))
            {
                var detalle = new Entities.TemporalPagos.DetalleObligacion()
                {
                    Ano = Temp_item.Ano,
                    P = Temp_item.P,
                    Cuota_pago = Temp_item.Cuota_pago,
                    Concepto = Temp_item.Concepto,
                    Descripcio = Temp_item.Descripcio,
                    Eliminado = Temp_item.Eliminado
                };

                cuotaPago.DetalleObligaciones.Add(new DetalleObligacion(detalle));
            }

            return cuotaPago;
        }

        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = CuotaPagoRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Cp_Des);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }


        public IEnumerable<Response> CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            IEnumerable<Response> result;

            if (procedencia == Procedencia.Tasas)
            {
                result = _cuotaPagoTasasServices.CopiarRegistrosDesdeTemporalPagos(procedencia);
            }
            else
            {
                result = _cuotaPagoObligacionServices.CopiarRegistrosDesdeTemporalPagos(procedencia);
            }

            return result;
        }


        public List<Response> EjecutarValidaciones(Procedencia procedencia, int? cuotaPagoRowID)
        {
            IEnumerable<Response> result;

            if (procedencia == Procedencia.Tasas)
            {
                result = _cuotaPagoTasasServices.EjecutarValidaciones(procedencia, cuotaPagoRowID);
            }
            else
            {
                result = _cuotaPagoObligacionServices.EjecutarValidaciones(procedencia, cuotaPagoRowID);
            }

            return result.ToList();
        }

        public Response EjecutarValidacionPorObsId(Procedencia procedencia, int ObservacionId)
        {
            Response result;

            if (procedencia == Procedencia.Tasas)
            {
                result = _cuotaPagoTasasServices.EjecutarValidacionPorObsId((int)procedencia, ObservacionId);
            }
            else
            {
                result = _cuotaPagoObligacionServices.EjecutarValidacionPorObsId((int)procedencia, ObservacionId);
            }

            return result;
        }


        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            IEnumerable<Response> result;

            if (procedencia == Procedencia.Tasas)
            {
                result = _cuotaPagoTasasServices.MigrarDatosTemporalPagos(procedencia);
            }
            else
            {
                result = _cuotaPagoObligacionServices.MigrarDatosTemporalPagos(procedencia);
            }

            return result.ToList();
        }

        public List<Response> ValidarMigracionCtasPorCobrar(Procedencia procedencia)
        {
            IEnumerable<Response> result;

            if (procedencia == Procedencia.Tasas)
            {
                result = _cuotaPagoTasasServices.MigrarDatosTemporalPagos(procedencia);
            }
            else
            {
                result = _cuotaPagoObligacionServices.ValidarMigracionCtasPorCobrar(procedencia);
            }

            return result.ToList();
        }

        public Response Save(CuotaPago cuotaPago, int? tipoObsID)
        {
            Response result;
            cuotaPago.Fch_venc = !string.IsNullOrEmpty(cuotaPago.Fch_venc_s) ? DateTime.Parse(cuotaPago.Fch_venc_s) : cuotaPago.Fch_venc;

            if ((Procedencia)cuotaPago.I_ProcedenciaID == Procedencia.Tasas)
            {
                result = _cuotaPagoTasasServices.Save(cuotaPago, tipoObsID);
            }
            else
            {
                result = _cuotaPagoObligacionServices.Save(cuotaPago, tipoObsID);
            }

            return result.IsDone ? result.Success(false) : result.Error(false);
        }
    }
}