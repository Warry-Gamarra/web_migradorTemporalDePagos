using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using Migracion = WebMigradorCtasPorCobrar.Models.Services.Migracion;
using WebMigradorCtasPorCobrar.Models.Services.Migracion;

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


        public ActionResult DatosMigracion(Procedencia procedencia)
        {
            var model = _conceptoPagoServiceMigracion.Obtener(procedencia);
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
        public ActionResult Save(int id)
        {

            return PartialView("_ProcesoMigracion");
        }

    }
}