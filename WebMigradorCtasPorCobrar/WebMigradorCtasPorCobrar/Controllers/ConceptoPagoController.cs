using System.Collections.Generic;
using System.Web.Mvc;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using CtasPorCobrar = WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using TemporalPagos = WebMigradorCtasPorCobrar.Models.Services.TemporalPagos;

namespace WebMigradorCtasPorCobrar.Controllers
{
    [Authorize]
    public class ConceptoPagoController : Controller
    {
        private readonly TemporalPagos.ConceptoPagoService _conceptoPagoServiceTemporalPagos;
        private readonly ConceptoPagoService _conceptoPagoServiceMigracion;
        private readonly CtasPorCobrar.ConceptoPagoServices _conceptoPagoServiceCtasPorCobrar;
        private readonly EquivalenciasServices _equivalenciasServices;
        private readonly ObservacionService _observacionService;

        public ConceptoPagoController()
        {
            _conceptoPagoServiceTemporalPagos = new TemporalPagos.ConceptoPagoService();
            _conceptoPagoServiceMigracion = new ConceptoPagoService();
            _conceptoPagoServiceCtasPorCobrar = new CtasPorCobrar.ConceptoPagoServices();
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


        public ActionResult Tasas(string partial)
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


        public ActionResult CtasPorCobrar(Procedencia procedencia)
        {
            var model = _conceptoPagoServiceCtasPorCobrar.Obtener(procedencia);
            return PartialView("_CtasPorCobrarConceptos", model);
        }


        public ActionResult DatosMigracion(TipoData tipo, Procedencia procedencia, int? tipo_obs)
        {
            var model = _conceptoPagoServiceMigracion.Obtener(procedencia, tipo_obs);

            ViewBag.Observaciones = new SelectList(_observacionService.Obtener_TipoObservacionesTabla(tipo, Tablas.TR_Cp_Pri, procedencia),
                                                "I_ObservID", "T_ObservDesc", tipo_obs);

            ViewBag.IdObservacion = tipo_obs;
            ViewBag.Procedencia = procedencia;

            if (Procedencia.Tasas == procedencia)
            {
                return PartialView("_DatosMigracionTasas", model);
            }

            return PartialView("_DatosMigracion", model);
        }


        public ActionResult ProcesoMigracion(Procedencia procedencia)
        {
            ViewBag.Procedencia = procedencia;
            ViewBag.Boundary = procedencia == Procedencia.Tasas ? "Tasas" : "Obligaciones";

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
            ViewBag.Procedencia = procedencia.ToString();
            IEnumerable<Response> result = _conceptoPagoServiceMigracion.EjecutarValidaciones(procedencia, null);

            return PartialView("_ResultadoValidarRegistros", result);
        }


        [HttpPost]
        public ActionResult EjecutarValidacion(Procedencia procedencia, int ObservacionId)
        {

            Response result = _conceptoPagoServiceMigracion.EjecutarValidacionPorObsId((int)procedencia, ObservacionId);
            ViewBag.Procedencia = procedencia.ToString();

            return PartialView("_ResultadoValidacion", result);
        }


        [HttpPost]
        public ActionResult MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            IEnumerable<Response> result = _conceptoPagoServiceMigracion.MigrarDatosTemporalPagos(procedencia);

            return PartialView("_ResultadoMigrarRegistros", result);
        }


        public ActionResult Observaciones(int id)
        {
            var model = _observacionService.Obtener_ObservacionesConceptoPago(id);
            ViewBag.Controller = this.ControllerContext.RouteData.Values["controller"].ToString();

            ViewBag.RowID = id;

            var fila = _conceptoPagoServiceMigracion.Obtener(id);
            ViewBag.ErrorTitle = $"Concepto de pago {fila.Id_cp} - {fila.Descripcio}";

            return PartialView("_Observaciones", model);
        }

        public ActionResult AgregarObservacion(int id)
        {
            ViewBag.LstObservaciones = new SelectList(_observacionService.ObtenerCatalogo(), "I_ObservID", "T_ObservDesc");

            return PartialView("_ObservacionRegistro");
        }


        public ActionResult VerDatos(int id)
        {
            var model = new ConceptoPagoViewModel()
            {
                ConceptoPagoMigracion = _conceptoPagoServiceMigracion.Obtener(id),
            };

            var conceptoPagoCtasCobrar = _conceptoPagoServiceCtasPorCobrar.Obtener(model.ConceptoPagoMigracion.I_EquivDestinoID ?? 0);

            model.ConceptoPagoCtasCobrar = conceptoPagoCtasCobrar ?? new Models.Entities.CtasPorCobrar.TI_ConceptoPago();

            return PartialView("_DatosConceptoPago", model);
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
                var observacion = _observacionService.ObtenerCatalogo(obsID);
                ViewBag.TipoObserv = obsID.ToString();
                ViewBag.Observacion = observacion == null ? "" : observacion.T_ObservDesc;
                ViewBag.Periodos = new SelectList(_equivalenciasServices.ObtenerPeriodosAcademicos(),
                                                  "I_OpcionID", "T_OpcionDesc", model.I_TipPerID);

                ViewBag.TipoAlumno = new SelectList(_equivalenciasServices.ObtenerTipoAlumno(),
                                                  "I_OpcionID", "T_OpcionDesc", model.I_TipAluID);

                ViewBag.Grados = new SelectList(_equivalenciasServices.ObtenerTipoGrado(),
                                                  "I_OpcionID", "T_OpcionDesc", model.I_TipGradoID);

                ViewBag.Procedencia = new SelectList(ListEnums.Procedencias(), "Value", "Descripcion",
                                                     model.I_ProcedenciaID);

                return PartialView(viewResult.CurrentID, model);
            }
        }

        [HttpPost]
        public ActionResult Save(ConceptoPago model, int tipoObserv)
        {
            var result = _conceptoPagoServiceMigracion.Save(model, tipoObserv);

            ViewBag.Reload = true;

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
                case ConceptoPagoObs.ErrorConPeriodoCuota:
                    viewName = "_EditarPeriodo";
                    break;
                case ConceptoPagoObs.NoObligacion:
                    viewName = "_EditarEsObligacion";
                    break;
                default:
                    viewName = "_EditarConceptoPago";
                    break;
            }

            model.CurrentID = viewName;

            return model;
        }

    }
}