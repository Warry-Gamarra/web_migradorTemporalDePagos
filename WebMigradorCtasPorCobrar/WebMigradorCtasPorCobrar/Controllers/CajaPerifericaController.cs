using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class CajaPerifericaController : Controller
    {
        // GET: CajaPerifedica
        public ActionResult Index()
        {
            ViewBag.Title = "Caja Periferica";

            return View();
        }
    }
}