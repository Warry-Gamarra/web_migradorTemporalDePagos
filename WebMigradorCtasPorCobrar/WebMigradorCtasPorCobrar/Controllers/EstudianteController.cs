using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using Migracion = WebMigradorCtasPorCobrar.Models.Services.Migracion;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class EstudianteController : Controller
    {
        private readonly TemporalPagos.AlumnoService _alumnoServiceTemporalPagos;
        private readonly Migracion.AlumnoService _alumnoServiceMigracion;

        public EstudianteController()
        {
            _alumnoServiceTemporalPagos = new TemporalPagos.AlumnoService();
            _alumnoServiceMigracion = new Migracion.AlumnoService();
        }


        // GET: Estudiante
        public ActionResult Index(Procedencia? procedencia, string partial)
        {
            ViewBag.Procedencia = procedencia;

            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }

        public ActionResult TemporalPagos(Procedencia procedencia)
        {
            var model = _alumnoServiceTemporalPagos.Obtener(procedencia).OrderBy(x => x.T_NomCompleto);
            return PartialView("_TemporalPagos", model);
        }


        public ActionResult DatosMigracion(Procedencia procedencia)
        {
            var model = _alumnoServiceMigracion.Obtener(procedencia);
            return PartialView("_DatosMigracion", model);
        }


        public ActionResult ProcesoMigracion(Procedencia procedencia)
        {
            ViewBag.Procedencia = procedencia;

            return PartialView("_ProcesoMigracion");
        }

    }
}