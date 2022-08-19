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
    public class CuotaPagoController : Controller
    {
        public readonly TemporalPagos.CuotaPagoService _cuotaPagoServiceTemporalPagos;
        public readonly Migracion.CuotaPagoService _cuotaPagoServiceMigracion;
        private readonly ObservacionService _observacionService;

        public CuotaPagoController()
        {
            _cuotaPagoServiceTemporalPagos = new TemporalPagos.CuotaPagoService();
            _cuotaPagoServiceMigracion = new Migracion.CuotaPagoService();
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
            var model = _cuotaPagoServiceTemporalPagos.Obtener(procedencia);
            return PartialView("_TemporalPagos", model);
        }


        public ActionResult DatosMigracion(Procedencia procedencia)
        {
            var model = _cuotaPagoServiceMigracion.Obtener(procedencia);
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
            Response result = _cuotaPagoServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia);

            return PartialView("_CopiarRegistrosResultado", result);
        }

        [HttpPost]
        public ActionResult ValidarRegistros(Procedencia procedencia)
        {

            Response result = _cuotaPagoServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia);

            return PartialView("_CopiarRegistrosResultado", result);
        }

        [HttpPost]
        public ActionResult MigrarRegistrosValidos(Procedencia procedencia)
        {

            Response result = _cuotaPagoServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia);

            return PartialView("_CopiarRegistrosResultado", result);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesCuotaPago(id);

            return PartialView("_Observaciones", model);
        }

        public ActionResult Editar(int id)
        {
            var model = _cuotaPagoServiceMigracion.Obtener(id);

            return PartialView("_Editar", model);
        }

        [HttpPost]
        public ActionResult Save(int id)
        {

            return PartialView("_ProcesoMigracion");
        }

    }
}