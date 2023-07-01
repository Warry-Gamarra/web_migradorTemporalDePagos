using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using Migracion = WebMigradorCtasPorCobrar.Models.Services.Migracion;
using UnfvRepositorio = WebMigradorCtasPorCobrar.Models.Services.UnfvRepositorio;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class EstudianteController : Controller
    {
        private readonly TemporalPagos.AlumnoService _alumnoServiceTemporalPagos;
        private readonly Migracion.AlumnoService _alumnoServiceMigracion;
        private readonly UnfvRepositorio.AlumnoService _alumnoServiceUnfvRepositorio;
        private readonly Migracion.ObservacionService _observacionService;
        private readonly EquivalenciasServices _equivalenciaService;
        
        public EstudianteController()
        {
            _alumnoServiceTemporalPagos = new TemporalPagos.AlumnoService();
            _alumnoServiceMigracion = new Migracion.AlumnoService();
            _alumnoServiceUnfvRepositorio = new UnfvRepositorio.AlumnoService();
            _observacionService = new Migracion.ObservacionService();
            _equivalenciaService = new EquivalenciasServices();
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

            ViewBag.IdObservacion = tipo_obs;
            ViewBag.Procedencia = procedencia;

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
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia, string codAlu, Int16? anioIngreso)
        {
            Response result = _alumnoServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }

        public ActionResult VerDatos(int id)
        {
            var migracionAlumno = _alumnoServiceMigracion.Obtener(id);
            var model = new DatosEstudianteViewModel()
            {
                MigracionAlumno = migracionAlumno,
                RepositorioAlumno = _alumnoServiceUnfvRepositorio.ObtenerAlumno(migracionAlumno.C_RcCod, migracionAlumno.C_CodAlu)
            };

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

            ViewBag.Procedencia = (Procedencia)model.I_ProcedenciaID;
            ViewBag.ModalidadIngreso = new SelectList(_equivalenciaService.ObtenerModalidadIngreso(), "T_OpcionCod", "T_OpcionDesc", model.C_CodModIng);

            return PartialView("_Editar", model);
        }


        [HttpPost]
        [ValidateAntiForgeryToken]
        public ActionResult Save(Alumno model, string FecNac, Procedencia procedencia)
        {
            Response result = new Response();
            DateTime D_FecNac;

            if (ModelState.IsValid)
            {
                model.D_FecNac = DateTime.TryParse(FecNac, out D_FecNac) ? D_FecNac : model.D_FecNac;

                result = _alumnoServiceMigracion.Save(model, procedencia);
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



        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _alumnoServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Observaciones-Alumnos " + procedencia + ".xlsx");
        }

    }
}