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
            ViewBag.Procedencia = procedencia;

            return PartialView("_TemporalPagos", model);
        }

        public ActionResult TemporalPagosDetalle(Procedencia procedencia, string cuota_pago, string anio, string p, string cod_alu, string cod_rc, DateTime fch_venc)
        {
            var model = _obligacionServiceTemporalPagos.ObtenerDetalleObligacion(procedencia, cuota_pago, anio, p, cod_alu, cod_rc, fch_venc);

            return PartialView("_TemporalPagosDetalle", model);
        }



        public ActionResult DatosMigracion(Procedencia procedencia, int? tipo_obs)
        {
            var model = _obligacionServiceMigracion.ObtenerObligaciones(procedencia, tipo_obs);

            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(Tablas.TR_Ec_Obl, procedencia),
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


        public ActionResult CargarDetalle(int id, Procedencia procedencia)
        {
            var model = _obligacionServiceMigracion.ObtenerObligacion(id, procedencia);

            return PartialView("_DetalleObligacion", model);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesObligacion(id);

            ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();

            ViewBag.RowID = id;

            var fila = _obligacionServiceMigracion.ObtenerObligacion(id, null);
            ViewBag.ErrorTitle = $"Obligación de pago {fila.Ano}-{fila.P} {fila.Cod_alu}";

            return PartialView("_Observaciones", model);
        }

        public ActionResult Editar(int id)
        {

            return PartialView("_EditarObligacion");
        }


        [HttpPost]
        public ActionResult Save(int id)
        {

            return PartialView("_ProcesoMigracion");
        }


        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _obligacionServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"Observaciones-Obligaciones_{DateTime.Now.ToString("yyyyMMdd_hhmmss")}.xlsx");
        }


    }
}