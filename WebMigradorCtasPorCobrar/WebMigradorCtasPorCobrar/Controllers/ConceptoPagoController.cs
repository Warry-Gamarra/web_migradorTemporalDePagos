using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using Migracion = WebMigradorCtasPorCobrar.Models.Services.Migracion;
using WebMigradorCtasPorCobrar.Models.Services.Migracion;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class ConceptoPagoController : Controller
    {
        private readonly TemporalPagos.ConceptoPagoService  _conceptoPagoServiceTemporalPagos;
        private readonly Migracion.ConceptoPagoService _conceptoPagoServiceMigracion;
        private readonly ObservacionService _observacionService;

        public ConceptoPagoController()
        {
            _conceptoPagoServiceTemporalPagos = new TemporalPagos.ConceptoPagoService();
            _conceptoPagoServiceMigracion = new Migracion.ConceptoPagoService();
            _observacionService = new ObservacionService();
        }

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
            var model = _conceptoPagoServiceTemporalPagos.Obtener(procedencia);
            return PartialView("_TemporalPagos", model);
        }


        public ActionResult DatosMigracion(Procedencia procedencia, int? tipo_obs)
        {
            var model = _conceptoPagoServiceMigracion.Obtener(procedencia, tipo_obs);

            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(Tablas.TR_Cp_Pri, procedencia),
                                                "I_ObservID", "T_ObservDesc", tipo_obs);

            ViewBag.IdObservacion = tipo_obs;
            ViewBag.Procedencia = procedencia;

            return PartialView("_DatosMigracion", model);
        }


        public ActionResult ProcesoMigracion(Procedencia procedencia)
        {
            ViewBag.Procedencia = procedencia;

            return PartialView("_ProcesoMigracion");
        }

        [HttpPost]
        public ActionResult CopiarRegistros(Procedencia procedencia)
        {
            Response result = _conceptoPagoServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia);

            return PartialView("_ResultadoCopiarRegistros", result);
        }

        [HttpPost]
        public ActionResult ValidarRegistros(Procedencia procedencia)
        {

            Response result = _conceptoPagoServiceMigracion.EjecutarValidaciones(procedencia);

            return PartialView("_ResultadoValidarRegistros", result);
        }

        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia)
        {

            Response result = _conceptoPagoServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesConceptoPago(id);

            return PartialView("_Observaciones", model);
        }

        public ActionResult Editar(int id)
        {

            return PartialView("_ProcesoMigracion");
        }

        [HttpPost]
        public ActionResult Save(ConceptoPago model, int tipoObserv)
        {
            var result = _conceptoPagoServiceMigracion.Save(model, tipoObserv);

            return PartialView("_Message", result);
        }


        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _conceptoPagoServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Observaciones-ConceptoPago.xlsx");
        }

        private string ObtenerVistaEdicion(int obsID)
        {
            string viewName = "_Message";

            switch ((ConceptoPagoObs)obsID)
            {
                case ConceptoPagoObs.Repetido:
                    viewName = "_EditarRepetido";
                    break;
                case ConceptoPagoObs.SinCuotaPago:
                    viewName = "_EditarCuotaPago";
                    break;
                case ConceptoPagoObs.SinCuotaMigrada:
                    viewName = "_Message";
                    break;
                case ConceptoPagoObs.SinAnio:
                    viewName = "_EditarAnio";
                    break;
                case ConceptoPagoObs.Externo:
                    viewName = "_Message";
                    break;
                case ConceptoPagoObs.SinPeriodo:
                    viewName = "_EditarPeriodo";
                    break;
                case ConceptoPagoObs.ErrorConAnioCuota:
                    viewName = "_EditarAnio";
                    break;
                case ConceptoPagoObs.ErroConPeriodoCuota:
                    viewName = "_EditarPeriodo";
                    break;
            }

            return viewName;
        }

    }
}