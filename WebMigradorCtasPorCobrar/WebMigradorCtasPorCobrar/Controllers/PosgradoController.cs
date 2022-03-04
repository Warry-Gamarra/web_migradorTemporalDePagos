using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Services;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class PosgradoController : Controller
    {
        private readonly CuotaPagoService cuotaPagoService;

        public PosgradoController()
        {
            cuotaPagoService = new CuotaPagoService();
        }

        // GET: Posgrado
        public ActionResult Index()
        {
            ViewBag.Group = "Posgrado";
            ViewBag.Title = "Posgrado";
            return View();
        }

        public ActionResult CuotaPago()
        {
            ViewBag.Group = "Posgrado";
            ViewBag.Title = "Cuotas de Pago";

            var model = cuotaPagoService.ObtenerCuotasPagoTP();

            return View(model);
        }
    }
}