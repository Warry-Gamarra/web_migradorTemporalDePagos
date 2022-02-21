using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class RepositorioController : Controller
    {
        // GET: Repositorio
        public ActionResult Index()
        {
            return RedirectToAction("Estudiantes");
        }

        public ActionResult Estudiantes()
        {
            ViewBag.Title = "Estudiantes";
            return View();
        }
    }
}