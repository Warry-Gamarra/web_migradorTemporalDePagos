using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class PosgradoController : Controller
    {
        // GET: Posgrado
        public ActionResult Index()
        {
            ViewBag.Title = "Posgrado";
            return View();
        }
    }
}