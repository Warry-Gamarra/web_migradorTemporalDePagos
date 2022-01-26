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
    }
}