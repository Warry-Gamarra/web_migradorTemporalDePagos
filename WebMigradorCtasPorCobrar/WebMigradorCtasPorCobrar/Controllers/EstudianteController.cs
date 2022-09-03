﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using Migracion = WebMigradorCtasPorCobrar.Models.Services.Migracion;
using WebMigradorCtasPorCobrar.Models.Services.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.ViewModels;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class EstudianteController : Controller
    {
        private readonly TemporalPagos.AlumnoService _alumnoServiceTemporalPagos;
        private readonly Migracion.AlumnoService _alumnoServiceMigracion;
        private readonly ObservacionService _observacionService;

        public EstudianteController()
        {
            _alumnoServiceTemporalPagos = new TemporalPagos.AlumnoService();
            _alumnoServiceMigracion = new Migracion.AlumnoService();
            _observacionService = new ObservacionService();
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


        public ActionResult DatosMigracion(Procedencia procedencia, int? tipo_obs)
        {
            var model = _alumnoServiceMigracion.Obtener(procedencia, tipo_obs);

            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(Tablas.TR_Alumnos, procedencia),
                                                    "I_ObservID", "T_ObservDesc", tipo_obs);

            return PartialView("_DatosMigracion", model);
        }


        public ActionResult ProcesoMigracion(Procedencia procedencia)
        {
            ViewBag.Procedencia = procedencia;

            return PartialView("_ProcesoMigracion");
        }


        [HttpPost]
        public ActionResult CopiarRegistros(Procedencia procedencia)
        {
            Response result = _alumnoServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia);

            return PartialView("_ResultadoCopiarRegistros", result);
        }


        [HttpPost]
        public ActionResult ValidarRegistros(Procedencia procedencia)
        {
            Response result = _alumnoServiceMigracion.EjecutarValidaciones(procedencia);

            return PartialView("_ResultadoValidarRegistros", result);
        }

        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = _alumnoServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }

        public ActionResult VerDatos(int id)
        {
            var model = _alumnoServiceMigracion.Obtener(id);

            return PartialView("_DatosEstudiante", model);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesAlumno(id);

            return PartialView("_Observaciones", model);
        }


        public ActionResult Editar(int id)
        {
            var model = _alumnoServiceMigracion.Obtener(id);

            return PartialView("_Editar", model);
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Save(Alumno model)
        {
            Response result = new Response();

            if (ModelState.IsValid)
            {
                result = _alumnoServiceMigracion.Save(model);
            }
            else
            {
                string details = "";

                foreach (ModelState modelState in ViewData.ModelState.Values)
                {
                    foreach (ModelError error in modelState.Errors)
                    {
                        details += error.ErrorMessage + " / ";
                    }
                }

                result.Error("Ha ocurrido un error con el envio de datos. " + details, false);
            }

            return PartialView("_MsgPartialWR", result);
        }

    }
}