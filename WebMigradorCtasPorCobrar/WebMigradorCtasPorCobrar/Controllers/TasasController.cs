using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class TasasController : Controller
    {
        // GET: Tasas
        public ActionResult Index()
        {
            ViewBag.Title = "Tasas";

            return View();
        }
    }
}