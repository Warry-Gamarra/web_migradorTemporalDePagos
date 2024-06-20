using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.Services.Migracion.Tasas;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class TasasController : Controller
    {
        private readonly TemporalPagos.TasasService _tasasServiceTemporalPagos;
        private readonly PagoTasasService _pagoTasasServiceMigracion;
        private readonly ObservacionService _observacionService;

        public TasasController()
        {
            _tasasServiceTemporalPagos = new TemporalPagos.TasasService();
            _pagoTasasServiceMigracion = new PagoTasasService();
            _observacionService = new ObservacionService();

        }

        // GET: Tasas
        public ActionResult Index(string partial)
        {
            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }

        public ActionResult TemporalPagos()
        {
            var model = _tasasServiceTemporalPagos.ObtenerEcObl();

            return PartialView("_TemporalPagos", model);
        }


        public ActionResult DatosMigracion(int? tipo_obs, TipoData tipoData = TipoData.ConObligaciones)
        {
            var model = _pagoTasasServiceMigracion.Obtener(tipo_obs);
            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(tipoData, Tablas.TR_Ec_Obl, Procedencia.Tasas),
                                                    "I_ObservID", "T_ObservDesc", tipo_obs);

            ViewBag.IdObservacion = tipo_obs;
            ViewBag.Procedencia = Procedencia.Tasas;

            return PartialView("_DatosMigracion", model);
        }


        public ActionResult ProcesoMigracion(Procedencia procedencia)
        {
            ViewBag.Procedencia = procedencia;

            return PartialView("_ProcesoMigracion");
        }


    }
}