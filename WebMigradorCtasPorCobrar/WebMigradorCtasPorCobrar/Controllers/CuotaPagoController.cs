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
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class CuotaPagoController : Controller
    {
        private readonly TemporalPagos.CuotaPagoService _cuotaPagoServiceTemporalPagos;
        private readonly Migracion.CuotaPagoService _cuotaPagoServiceMigracion;
        private readonly EquivalenciasServices _equivalenciasServices;
        private readonly ObservacionService _observacionService;

        public CuotaPagoController()
        {
            _cuotaPagoServiceTemporalPagos = new TemporalPagos.CuotaPagoService();
            _cuotaPagoServiceMigracion = new Migracion.CuotaPagoService();
            _observacionService = new ObservacionService();
            _equivalenciasServices = new EquivalenciasServices();
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
            var model = _cuotaPagoServiceMigracion.ObtenerConRelaciones(id);
            ViewBag.TipoObserv = obsID.ToString();
            ViewBag.Observacion = _observacionService.ObtenerCatalogo(obsID).T_ObservDesc;
            ViewBag.CategoriasBnc = new SelectList(_equivalenciasServices.ObtenerCategoriasPago(model.Codigo_bnc),
                                                    "I_CatPagoID", "T_CatPagoDesc", model.I_CatPagoID);
            ViewBag.Periodos = new SelectList(_equivalenciasServices.ObtenerPeriodosAcademicos(),
                                                    "I_OpcionID", "T_OpcionDesc", model.I_Periodo);
            ViewBag.Procedencia = new SelectList(ListEnums.Procedencias(), "Value", "Descripcion",
                                         model.I_ProcedenciaID);

            string viewName = ObtenerVistaEdicion(obsID);

            return PartialView(viewName, model);
        }

        [HttpPost]
        public ActionResult Save(CuotaPago model, int tipoObserv)
        {
            var result = _cuotaPagoServiceMigracion.Save(model, tipoObserv);

            return PartialView("_Message", result);
        }


        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _cuotaPagoServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Observaciones-CuotaPago.xlsx");
        }

        private string ObtenerVistaEdicion(int obsID)
        {
            string viewName = "_Message";

            switch ((CuotaPagoObs)obsID)
            {
                case CuotaPagoObs.Repetido:
                    viewName = "_EditarRepetido";
                    break;
                case CuotaPagoObs.Eliminado:
                    viewName = "_Message";
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