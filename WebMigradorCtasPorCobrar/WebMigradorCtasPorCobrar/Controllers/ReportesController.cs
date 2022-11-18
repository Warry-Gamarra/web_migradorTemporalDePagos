using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class ReportesController : Controller
    {
        // GET: Reporte
        public ActionResult Index()
        {
            return View();
        }


        public ActionResult ObligacionesAlumno()
        {
            return View();
        }

        public ActionResult ObligacionesAlumno(string codAlu)
        {

            return View();
        }

        public ActionResult Pregrado()
        {
            return View();
        }

        public ActionResult Posgrado()
        {
            return View();
        }

        public ActionResult Cuded()
        {
            return View();
        }
    }
}