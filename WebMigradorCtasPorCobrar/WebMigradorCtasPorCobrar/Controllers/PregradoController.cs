using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class PregradoController : Controller
    {
        // GET: Pregrado
        public ActionResult Index()
        {
            ViewBag.Title = "Pregrado";

            return View();
        }

        public ActionResult CuotaPago()
        {
            ViewBag.Title = "Cuotas de pago";

            return View();
        }


        public ActionResult ConceptoPago()
        {
            ViewBag.Title = "Conceptos de pago";

            return View();
        }


        public ActionResult Obligaciones()
        {
            ViewBag.Title = "Obligaciones";

            return View();
        }

        public ActionResult Pagos()
        {
            ViewBag.Title = "Pagos de Obligaciones";

            return View();
        }

    }
}