using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class HelpController : Controller
    {
        // GET: Help
        public ActionResult Index()
        {
            return RedirectToAction("Manual");
        }

        public ActionResult Manual()
        {
            ViewBag.Title = "Manual de usuario";
            return View();
        }
    }
}