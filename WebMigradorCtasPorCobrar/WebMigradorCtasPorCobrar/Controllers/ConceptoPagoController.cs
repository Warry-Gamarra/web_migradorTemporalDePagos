﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using Migracion = WebMigradorCtasPorCobrar.Models.Services.Migracion;
using WebMigradorCtasPorCobrar.Models.Services.Migracion;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.ViewModels;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class ConceptoPagoController : Controller
    {
        private readonly TemporalPagos.ConceptoPagoService _conceptoPagoServiceTemporalPagos;
        private readonly Migracion.ConceptoPagoService _conceptoPagoServiceMigracion;
        private readonly EquivalenciasServices _equivalenciasServices;
        private readonly ObservacionService _observacionService;

        public ConceptoPagoController()
        {
            _conceptoPagoServiceTemporalPagos = new TemporalPagos.ConceptoPagoService();
            _conceptoPagoServiceMigracion = new Migracion.ConceptoPagoService();
            _observacionService = new ObservacionService();
            _equivalenciasServices = new EquivalenciasServices();
        }

        public ActionResult Pregrado(string partial)
        {
            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }


        public ActionResult Posgrado(string partial)
        {
            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }


        public ActionResult Cuded(string partial)
        {
            if (!string.IsNullOrEmpty(partial))
            {
                ViewBag.Action = partial;
                ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();
            }

            return View();
        }


        public ActionResult TemporalPagos(Procedencia procedencia)
        {
            var model = _conceptoPagoServiceTemporalPagos.Obtener(procedencia);
            return PartialView("_TemporalPagos", model);
        }


        public ActionResult DatosMigracion(Procedencia procedencia, int? tipo_obs)
        {
            var model = _conceptoPagoServiceMigracion.Obtener(procedencia, tipo_obs);

            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(Tablas.TR_Cp_Pri, procedencia),
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
            Response result = _conceptoPagoServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia);

            return PartialView("_ResultadoCopiarRegistros", result);
        }

        [HttpPost]
        public ActionResult ValidarRegistros(Procedencia procedencia)
        {

            Response result = _conceptoPagoServiceMigracion.EjecutarValidaciones(procedencia);

            return PartialView("_ResultadoValidarRegistros", result);
        }

        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = _conceptoPagoServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesConceptoPago(id);
            ViewBag.RowID = id;

            return PartialView("_Observaciones", model);
        }

        public ActionResult AgregarObservacion(int id)
        {
            ViewBag.LstObservaciones = new SelectList(_observacionService.ObtenerCatalogo(), "I_ObservID", "T_ObservDesc");


            return PartialView("_ObservacionRegistro");
        }


        public ActionResult Editar(int id, int obsID)
        {
            Response viewResult = ObtenerVistaEdicion(obsID);

            if (viewResult.CurrentID == "_Message")
            {
                return PartialView(viewResult.CurrentID, viewResult);
            }
            else
            {
                var model = _conceptoPagoServiceMigracion.ObtenerConRelaciones(id);

                ViewBag.TipoObserv = obsID.ToString();
                ViewBag.Observacion = _observacionService.ObtenerCatalogo(obsID).T_ObservDesc;
                ViewBag.Periodos = new SelectList(_equivalenciasServices.ObtenerPeriodosAcademicos(),
                                                  "I_OpcionID", "T_OpcionDesc", model.I_Periodo);

                ViewBag.TipoAlumno = new SelectList(_equivalenciasServices.ObtenerPeriodosAcademicos(),
                                                  "I_OpcionID", "T_OpcionDesc", model.I_Periodo);

                ViewBag.Grados = new SelectList(_equivalenciasServices.ObtenerPeriodosAcademicos(),
                                                  "I_OpcionID", "T_OpcionDesc", model.I_Periodo);

                ViewBag.Procedencia = new SelectList(ListEnums.Procedencias(), "Value", "Descripcion", 
                                                     model.I_ProcedenciaID);

                return PartialView(viewResult.CurrentID, model);
            }
        }

        [HttpPost]
        public ActionResult Save(ConceptoPago model, int tipoObserv)
        {
            var result = _conceptoPagoServiceMigracion.Save(model, tipoObserv);

            return PartialView("_Message", result);
        }


        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _conceptoPagoServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", "Observaciones-ConceptoPago.xlsx");
        }

        private Response ObtenerVistaEdicion(int obsID)
        {
            Response model = new Response();
            string viewName = "_Message";
            model.Warning(false);

            switch ((ConceptoPagoObs)obsID)
            {
                case ConceptoPagoObs.Repetido:
                    viewName = "_EditarRepetido";
                    break;
                case ConceptoPagoObs.SinCuotaPago:
                    viewName = "_EditarCuotaPago";
                    break;
                case ConceptoPagoObs.SinCuotaMigrada:
                    viewName = "_Message";
                    model.Warning(false);
                    model.Message = "Debe migrarse primero la cuota de pago para poder migrar el concepto asociado.";
                    break;
                case ConceptoPagoObs.SinAnio:
                    viewName = "_EditarAnio";
                    break;
                case ConceptoPagoObs.Externo:
                    viewName = "_Message";
                    model.Message = "Los datos no pueden ser modificados por que ya existen en la base de datos de destino"; ;
                    break;
                case ConceptoPagoObs.SinPeriodo:
                    viewName = "_EditarPeriodo";
                    break;
                case ConceptoPagoObs.ErrorConAnioCuota:
                    viewName = "_EditarAnio";
                    break;
                case ConceptoPagoObs.ErroConPeriodoCuota:
                    viewName = "_EditarPeriodo";
                    break;
            }

            model.CurrentID = viewName;

            return model;
        }

    }
}