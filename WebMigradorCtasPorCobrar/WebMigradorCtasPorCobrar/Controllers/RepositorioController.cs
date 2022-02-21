using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Services;

namespace WebMigradorCtasPorCobrar.Controllers
{
    public class RepositorioController : Controller
    {
        public readonly AlumnoService _alumnoService;

        public RepositorioController()
        {
            _alumnoService = new AlumnoService();
        }
        // GET: Repositorio
        public ActionResult Index()
        {
            return RedirectToAction("Estudiantes");
        }

        public ActionResult Estudiantes()
        {
            ViewBag.Title = "Estudiantes";
            var model = _alumnoService.ObtenerAlumnosTP();

            return View(model);
        }
    }
}