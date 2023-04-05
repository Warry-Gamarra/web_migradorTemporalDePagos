using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Services.Migracion;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class DetalleObligacionController : Controller
    {
        private readonly ObservacionService _observacionServiceMigracion;
        private readonly ObligacionService _obligacionServiceMigracion;
        private readonly ObligacionDetalleService _detObligacionServiceMigracion;

        public DetalleObligacionController()
        {
            _observacionServiceMigracion = new ObservacionService();
            _obligacionServiceMigracion = new ObligacionService();
            _detObligacionServiceMigracion = new ObligacionDetalleService();
        }

        public ActionResult Observaciones(int OblID)
        {
            var model = _observacionServiceMigracion.Obtener_ObservacionesDetalleObligacion(OblID);
            ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();

            var fila = _obligacionServiceMigracion.ObtenerObligacion(OblID, false);

            ViewBag.ErrorTitle = $"Cuota de pago {fila.Cuota_pago} - {fila.Cuota_pago_desc}";

            return PartialView("_Observaciones", model);
        }

        public ActionResult CargarDetalle(int id, Procedencia procedencia)
        {
            var model = _obligacionServiceMigracion.ObtenerObligacion(id, true);

            return PartialView("_DetalleObligacion", model);
        }


        public ActionResult EditarDetalleObligacion(int? id)
        {

            return PartialView("_EditarDetalleObligacion");
        }
    }
}