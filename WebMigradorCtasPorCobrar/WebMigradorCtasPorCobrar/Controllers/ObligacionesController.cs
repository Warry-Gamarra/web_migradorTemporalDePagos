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
    public class ObligacionesController : Controller
    {
        private readonly TemporalPagos.ObligacionService _obligacionServiceTemporalPagos;
        private readonly Migracion.ObligacionService _obligacionServiceMigracion;
        private readonly ObservacionService _observacionService;

        public ObligacionesController()
        {
            _obligacionServiceTemporalPagos = new TemporalPagos.ObligacionService();
            _obligacionServiceMigracion = new Migracion.ObligacionService();
            _observacionService = new ObservacionService();
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

            return PartialView("_TemporalPagos", model);
        }


        public ActionResult DatosMigracion(Procedencia procedencia)
        {
            var model = _obligacionServiceMigracion.ObtenerObligaciones(procedencia);

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
            Response result = _obligacionServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia, null, null);

            return PartialView("_ResultadoCopiarRegistros", result);
        }

        [HttpPost]
        public ActionResult ValidarRegistros(Procedencia procedencia)
        {

            Response result = _obligacionServiceMigracion.EjecutarValidaciones(procedencia);

            return PartialView("_ResultadoValidarRegistros", result);
        }

        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia)
        {

            Response result = _obligacionServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesObligacion(id);

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