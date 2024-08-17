using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using Oblig = WebMigradorCtasPorCobrar.Models.Services.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class ObligacionesController : Controller
    {
        private readonly TemporalPagos.ObligacionService _obligacionServiceTemporalPagos;
        private readonly ObligacionService _obligacionCrossServiceMigracion;
        private readonly Oblig.PagoObligacionService _pagoObligacionCrossServiceMigracion;
        private readonly Oblig.ObligacionService _obligacionServiceMigracion;
        private readonly EquivalenciasServices _equivalenciasServices;
        private readonly ObservacionService _observacionService;

        public ObligacionesController()
        {
            _obligacionServiceTemporalPagos = new TemporalPagos.ObligacionService();
            _obligacionCrossServiceMigracion = new ObligacionService();
            _obligacionServiceMigracion = new Oblig.ObligacionService();
            _pagoObligacionCrossServiceMigracion = new Oblig.PagoObligacionService();
            _observacionService = new ObservacionService();
            _equivalenciasServices = new EquivalenciasServices();
        }


        // GET: Obligaciones
        public ActionResult Pregrado(string partial)
        {
            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }

        public ActionResult Posgrado(string partial)
        {
            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }

        public ActionResult Cuded(string partial)
        {
            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }

        public ActionResult TemporalPagos(Procedencia procedencia)
        {
            var model = _obligacionServiceTemporalPagos.ObtenerObligaciones(procedencia);
            ViewBag.Procedencia = procedencia;

            return PartialView("_TemporalPagos", model);
        }

        public ActionResult TemporalPagosDetalle(Procedencia procedencia, string cuota_pago, string anio, string p, string cod_alu, string cod_rc, DateTime fch_venc)
        {
            var model = _obligacionServiceTemporalPagos.ObtenerDetalleObligacion(procedencia, cuota_pago, anio, p, cod_alu, cod_rc, fch_venc);

            return PartialView("_TemporalPagosDetalle", model);
        }


        public ActionResult CtasPorCobrar(Procedencia procedencia)
        {
            var model = _obligacionServiceTemporalPagos.ObtenerObligaciones(procedencia);
            ViewBag.Procedencia = procedencia;

            return PartialView("_CtasPorCobrarObligaciones", model);
        }


        public ActionResult DatosMigracion(Procedencia procedencia, int? tipo_obs)
        {
            var model = _obligacionCrossServiceMigracion.ObtenerObligaciones(procedencia, tipo_obs);

            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(TipoData.ConObligaciones, Tablas.TR_Ec_Obl, procedencia),
                                                "I_ObservID", "T_ObservDesc", tipo_obs);

            ViewBag.IdObservacion = tipo_obs;
            ViewBag.Procedencia = procedencia;

            return PartialView("_DatosMigracion", model);
        }


        public ActionResult ProcesoMigracion(Procedencia procedencia)
        {
            ViewBag.Procedencia = procedencia;
            ViewBag.FaseMigracionCopiar = FaseMigracion.Copiar.ToString();
            ViewBag.FaseMigracionValidar = FaseMigracion.Validar.ToString();
            ViewBag.FaseMigracionMigrar = FaseMigracion.Migrar.ToString();

            return PartialView("_ProcesoMigracion");
        }


        [HttpPost]
        public ActionResult CopiarRegistros(Procedencia procedencia, string periodo)
        {
            var result = _obligacionServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia, periodo);

            return PartialView("_ResultadoCopiarRegistros", result);
        }

        [HttpGet]
        public ActionResult ObtenerPeriodos(Procedencia procedencia, FaseMigracion faseMigracion)
        {
            ViewBag.Procedencia = procedencia.ToString();
            ViewBag.FaseMigracion = faseMigracion.ToString();
            ViewBag.BtnId = $"btn-{faseMigracion.ToString().ToLower()}-per";


            if (FaseMigracion.Copiar != faseMigracion)
            {
                ViewBag.Anios = new SelectList(_obligacionCrossServiceMigracion.ObtenerAnios(procedencia), "Anio", "AnioText");
            }
            else
            {
                ViewBag.Anios = new SelectList(_obligacionServiceTemporalPagos.ObtenerAnios(procedencia), "Anio", "AnioText"); ;
            }

            return PartialView("_SeleccionPeriodoFase");
        }


        [HttpPost]
        public ActionResult ValidarRegistros(Procedencia procedencia, string periodo)
        {
            IEnumerable<Response> result = _obligacionServiceMigracion.EjecutarValidaciones(procedencia, periodo);
            ViewBag.Procedencia = procedencia.ToString();

            return PartialView("_ResultadoValidarRegistros", result);
        }


        [HttpPost]
        public ActionResult EjecutarValidacion(Procedencia procedencia, int ObservacionId)
        {

            Response result = _obligacionServiceMigracion.EjecutarValidacionPorObsId((int)procedencia, ObservacionId);
            ViewBag.Procedencia = procedencia.ToString();

            return PartialView("_ResultadoValidacion", result);
        }


        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia, string periodo)
        {
            IEnumerable<ResponseObligacion> result = _pagoObligacionCrossServiceMigracion.MigrarDatosPagoTemporalPagos(procedencia, periodo);

            return PartialView("_ResultadoMigrarRegistrosObligacion", result);
        }


        public ActionResult MigrarObligacion(int id)
        {
            IEnumerable<Response> result = _pagoObligacionCrossServiceMigracion.MigrarDatosTemporalPagosObligacionID(id);

            return PartialView("_ResultadoListMigrarRegistrosModal", result);
        }

        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesObligacion(id);
            ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();

            ViewBag.RowID = id;

            var fila = _obligacionCrossServiceMigracion.ObtenerObligacion(id, false);
            ViewBag.ErrorTitle = $"Obligación de pago {fila.Ano}-{fila.P} {fila.Cod_alu}";

            return PartialView("_Observaciones", model);
        }

        public ActionResult Editar(int id, int obsID)
        {
            var model = _obligacionCrossServiceMigracion.ObtenerObligacion(id, false);
            ViewBag.TipoObserv = obsID.ToString();
            ViewBag.Observacion = _observacionService.ObtenerCatalogo(obsID).T_ObservDesc;
            ViewBag.Periodos = new SelectList(_equivalenciasServices.ObtenerPeriodosAcademicos(),
                                                    "I_OpcionID", "T_OpcionCodDesc", model.I_Periodo);

            ViewBag.ComponentId = _obligacionServiceMigracion.ObtenerComponenteId(obsID);

            return PartialView("_EditarObligacion", model);
        }


        [HttpPost]
        public ActionResult Save(Obligacion model, int tipoObserv)
        {
            model.D_FecActualiza = DateTime.Now;
            model.B_Actualizado = true;
            Response result = new Response();

            if (ModelState.IsValid)
            {

                result = _obligacionServiceMigracion.Save(model, tipoObserv);
            }
            else
            {
                string details = "";

                foreach (ModelState modelState in ViewData.ModelState.Values)
                {
                    foreach (ModelError error in modelState.Errors)
                    {
                        details += error.ErrorMessage + " / ";
                    }
                }

                result.Error("Ha ocurrido un error con el envio de datos. " + details, false);
            }

            ViewBag.Reload = true;

            return PartialView("_Message", result);
        }


        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _obligacionCrossServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"Observaciones-Obligaciones_{DateTime.Now:yyyyMMdd_hhmmss}.xlsx");
        }


    }
}