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

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class CuotaPagoController : Controller
    {
        private readonly TemporalPagos.CuotaPagoService _cuotaPagoServiceTemporalPagos;
        private readonly Migracion.CuotaPagoService _cuotaPagoServiceMigracion;
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


        public ActionResult DatosMigracion(Procedencia procedencia, int? tipo_obs)
        {
            var model = _cuotaPagoServiceMigracion.Obtener(procedencia, tipo_obs);
            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(Tablas.TR_Cp_Des, procedencia), 
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
            Response result = _cuotaPagoServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia);

            return PartialView("_ResultadoCopiarRegistros", result);
        }

        [HttpPost]
        public ActionResult ValidarRegistros(Procedencia procedencia)
        {

            Response result = _cuotaPagoServiceMigracion.EjecutarValidaciones(procedencia);

            return PartialView("_ResultadoValidarRegistros", result);
        }

        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia)
        {

            Response result = _cuotaPagoServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesCuotaPago(id);
            ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();

            return PartialView("_Observaciones", model);
        }

        public ActionResult Editar(int id, int obsID)
        {
            var model = _cuotaPagoServiceMigracion.ObtenerConConceptos(id);
            string viewName = ObtenerVistaEdicion(obsID);

            return PartialView(viewName, model);
        }

        [HttpPost]
        public ActionResult Save(int Id, int I_PeriodoID)
        {
            _cuotaPagoServiceMigracion.Save(Id, I_PeriodoID);

            return PartialView("_ProcesoMigracion");
        }


        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _cuotaPagoServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Observaciones-CuotaPago.xlsx");
        }

        private string ObtenerVistaEdicion(int obsID)
        {
            string viewName = "_MensajeSinEditar";

            switch ((CuotaPagoObs)obsID)
            {
                case CuotaPagoObs.Repetido:
                    viewName = "_EditarRepetido";
                    break;
                case CuotaPagoObs.Eliminado:
                    viewName = "_MensajeSinEditar";
                    break;
                case CuotaPagoObs.MasDeUnAnio:
                    viewName = "_EditarAnio";
                    break;
                case CuotaPagoObs.SinAnio:
                    viewName = "_EditarAnio";
                    break;
                case CuotaPagoObs.MasDeUnPeriodo:
                    viewName = "_EditarPeriodo";
                    break;
                case CuotaPagoObs.SinPeriodo:
                    viewName = "_EditarPeriodo";
                    break;
                case CuotaPagoObs.MásDeUnaCategoría:
                    viewName = "_EditarEquivalencia";
                    break;
                case CuotaPagoObs.SinCategoria:
                    viewName = "_EditarEquivalencia";
                    break;
            }

            return viewName;
        }
    }
}