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

        public ActionResult Estudiantes(int step = 1)
        {
            ViewBag.Group = "Repositorio";
            ViewBag.Title = "Estudiantes";

            ViewBag.Step = $"step_{step}";

            switch (step)
            {
                case 1:
                    ViewBag.Active_1 = "active";
                    ViewBag.Enabled_2 = "disabled";
                    ViewBag.Enabled_3 = "disabled";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "TemporalPagos";
                    break;
                case 2:
                    ViewBag.Active_2 = "active";
                    ViewBag.Enabled_3 = "disabled";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "Transformacion";
                    break;
                case 3:
                    ViewBag.Active_3 = "active";
                    ViewBag.Enabled_4 = "disabled";

                    ViewBag.Action = "ResultadoRevision";
                    break;
                case 4:
                    ViewBag.Active_4 = "active";

                    ViewBag.Action = "ResultadoMigracion";
                    break;
            }

            return View();
        }


        public ActionResult TemporalPagos()
        {
            var model = _alumnoService.ObtenerAlumnosTP();

            return PartialView("Estudiante_migracion_step1", model);
        }

        public ActionResult Transformacion()
        {
            var model = _alumnoService.ObtenerAlumnosMG();

            return PartialView("Estudiante_migracion_step2", model);
        }


        public ActionResult ResultadoRevision()
        {
            var model = _alumnoService.ObtenerAlumnosMG();

            return PartialView("Estudiante_migracion_step3", model);
        }

        public ActionResult ResultadoMigracion()
        {
            var model = _alumnoService.ObtenerAlumnosTP();

            return PartialView("Estudiante_migracion_step4", model);
        }

        public ActionResult EstudianteEdit(int id)
        {
            var model = _alumnoService.ObtenerAlumnosMG(id);

            return PartialView(model);
        }




    }
}