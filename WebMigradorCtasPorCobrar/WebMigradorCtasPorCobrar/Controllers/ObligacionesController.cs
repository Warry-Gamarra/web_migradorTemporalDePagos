﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Helpers;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;
using WebMigradorCtasPorCobrar.Models.Services.Migracion;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class ObligacionesController : Controller
    {
        private readonly TemporalPagos.ObligacionService _obligacionServiceTemporalPagos;
        private readonly ObligacionService _obligacionServiceMigracion;
        private readonly ObligacionDetalleService _obligacionDetalleServiceMigracion;
        private readonly EquivalenciasServices _equivalenciasServices;
        private readonly ObservacionService _observacionService;

        public ObligacionesController()
        {
            _obligacionServiceTemporalPagos = new TemporalPagos.ObligacionService();
            _obligacionServiceMigracion = new ObligacionService();
            _observacionService = new ObservacionService();
            _equivalenciasServices = new EquivalenciasServices();
            _obligacionDetalleServiceMigracion = new ObligacionDetalleService();
        }


        // GET: Obligaciones
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
            var model = _obligacionServiceTemporalPagos.ObtenerObligaciones(procedencia);
            ViewBag.Procedencia = procedencia;

            return PartialView("_TemporalPagos", model);
        }

        public ActionResult TemporalPagosDetalle(Procedencia procedencia, string cuota_pago, string anio, string p, string cod_alu, string cod_rc, DateTime fch_venc)
        {
            var model = _obligacionServiceTemporalPagos.ObtenerDetalleObligacion(procedencia, cuota_pago, anio, p, cod_alu, cod_rc, fch_venc);

            return PartialView("_TemporalPagosDetalle", model);
        }


        public ActionResult CtasPorCobrar(Procedencia procedencia)
        {
            var model = _obligacionServiceTemporalPagos.ObtenerObligaciones(procedencia);
            ViewBag.Procedencia = procedencia;

            return PartialView("_CtasPorCobrarObligaciones", model);
        }


        public ActionResult DatosMigracion(Procedencia procedencia, int? tipo_obs)
        {
            var model = _obligacionServiceMigracion.ObtenerObligaciones(procedencia, tipo_obs);

            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(Tablas.TR_Ec_Obl, procedencia),
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
            Response result = _obligacionServiceMigracion.CopiarRegistrosDesdeTemporalPagos(procedencia, null, null);

            return PartialView("_ResultadoCopiarRegistros", result);
        }

        [HttpGet]
        public ActionResult ValidarRegistros(Procedencia procedencia)
        {
            ViewBag.Procedencia = procedencia.ToString();
            ViewBag.Rango_Hasta_2009 = PeriodosValidacion.Anterior_hasta_2009.ToString();
            ViewBag.Rango_2010_2015 = PeriodosValidacion.Del_2010_al_2015.ToString();
            ViewBag.Rango_2016_2020 = PeriodosValidacion.Del_2016_al_2020.ToString();

            return PartialView("_ValidarRegistrosObligacion");
        }


        [HttpPost]
        public ActionResult ValidarRegistros(int? id, Procedencia procedencia, PeriodosValidacion periodo)
        {
            Response result = _obligacionServiceMigracion.EjecutarValidaciones(procedencia, id, periodo);

            return PartialView("_ResultadoValidarRegistros", result);
        }


        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = _obligacionServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesObligacion(id);
            ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();

            ViewBag.RowID = id;

            var fila = _obligacionServiceMigracion.ObtenerObligacion(id, false);
            ViewBag.ErrorTitle = $"Obligación de pago {fila.Ano}-{fila.P} {fila.Cod_alu}";

            return PartialView("_Observaciones", model);
        }

        public ActionResult Editar(int id, int obsID)
        {
            var model = _obligacionServiceMigracion.ObtenerObligacion(id, false);
            ViewBag.TipoObserv = obsID.ToString();
            ViewBag.Observacion = _observacionService.ObtenerCatalogo(obsID).T_ObservDesc;
            ViewBag.Periodos = new SelectList(_equivalenciasServices.ObtenerPeriodosAcademicos(),
                                                    "I_OpcionID", "T_OpcionCodDesc", model.I_Periodo);

            ViewBag.ComponentId = _obligacionServiceMigracion.ObtenerComponenteId(obsID);

            return PartialView("_EditarObligacion", model);
        }


        [HttpPost]
        public ActionResult Save(Obligacion model, int tipoObserv)
        {
            model.D_FecActualiza = DateTime.Now;

            var result = _obligacionServiceMigracion.Save(model, tipoObserv);

            return PartialView("_Message", result);
        }


        public ActionResult ExportarObservaciones(int? id, Procedencia procedencia)
        {
            var model = _obligacionServiceMigracion.ObtenerDatosObservaciones(procedencia, id);

            return File(model, "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet", $"Observaciones-Obligaciones_{DateTime.Now.ToString("yyyyMMdd_hhmmss")}.xlsx");
        }


    }
}