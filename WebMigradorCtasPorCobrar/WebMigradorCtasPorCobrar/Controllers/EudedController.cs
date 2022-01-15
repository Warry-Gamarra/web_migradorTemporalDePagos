using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class EudedController : Controller
    {
        // GET: Euded
        public ActionResult Index()
        {
            ViewBag.OrigenPago = "Euded";
            ViewBag.Title = "Euded";
            return View();
        }
    }
}