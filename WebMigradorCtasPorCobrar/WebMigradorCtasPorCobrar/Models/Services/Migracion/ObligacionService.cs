using ClosedXML.Excel;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Web;
using System.Reflection;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class ObligacionService
    {
        public IEnumerable<Obligacion> ObtenerObligaciones(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObligacionRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Ec_Obl);
            }

            return ObligacionRepository.Obtener((int)procedencia);
        }


        public Obligacion ObtenerObligacion(int obligacionID, bool getDetalle)
        {
            var obligacion = ObligacionRepository.ObtenerPorID(obligacionID);

            if (getDetalle)
            {
                obligacion.DetalleObligaciones = DetalleObligacionRepository.Obtener(obligacionID).ToList();
            }

            return obligacion;
        }

        public IEnumerable<Obligacion> ObtenerPorAlumno(string codAlu, string codRc)
        {
            IEnumerable<Obligacion> obligaciones;

            obligaciones = ObligacionRepository.ObtenerPorAlumno(codAlu, codRc);

            foreach (var item in obligaciones)
            {
                item.DetalleObligaciones = DetalleObligacionRepository.ObtenerDetallePorAlumno(codAlu, codRc, item.I_RowID).ToList();
            }

            return obligaciones;
        }


        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = ObligacionRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Ec_Obl);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }


        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia, int? anioIni, int? anioFin)
        {
            Response result = new Response();
            Response result_Cabecera = new Response();
            Response result_Detalle = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            DetalleObligacionRepository detalleObligacionRepository = new DetalleObligacionRepository();

            string schemaDb = Schema.SetSchema(procedencia);
            string s_anioIni = anioIni.HasValue ? null : anioIni.ToString();
            string s_anioFin = anioFin.HasValue ? null : anioIni.ToString();

            result_Cabecera = obligacionRepository.CopiarRegistrosCabecera((int)procedencia, schemaDb, s_anioIni, s_anioFin);
            result_Detalle = detalleObligacionRepository.CopiarRegistrosDetalle((int)procedencia, schemaDb, s_anioIni, s_anioFin);

            if (result_Cabecera.IsDone && result_Detalle.IsDone)
            {
                result.IsDone = true;
                result.Success(false);
            }
            else
            {
                result.IsDone = false;
                result.Error(false);
            }

            result.Message = $"    <dl class=\"row text-justify\">" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Cabecera de Obligaciones</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Cabecera.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Detalle de Obligaciones </dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_Detalle.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";


            return result;
        }


        public Response EjecutarValidaciones(Procedencia procedencia, int? oblId, PeriodosValidacion periodosValidacion)
        {
            string anioInicio = null;
            string anioFin = null;

            Response result = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();

            switch (periodosValidacion)
            {
                case PeriodosValidacion.Anterior_hasta_2009:
                    anioInicio = null;
                    anioFin = "2009";
                    break;
                case PeriodosValidacion.Del_2010_al_2015:
                    anioInicio = "2010";
                    anioFin = "2015";
                    break;
                case PeriodosValidacion.Del_2016_al_2020:
                    anioInicio = "2016";
                    anioFin = "2020";
                    break;
            }

            _ = Schema.SetSchema(procedencia);
            _ = obligacionRepository.InicializarEstadoValidacionObligacionPago((int)procedencia, oblId, anioInicio, anioFin);

            Response result_Alumnos = obligacionRepository.ValidarAlumnoCabeceraObligacion((int)procedencia, oblId, anioInicio, anioFin);
            Response result_Anio = obligacionRepository.ValidarAnioEnCabeceraObligacion((int)procedencia, oblId);
            Response result_Periodo = obligacionRepository.ValidarPeriodoEnCabeceraObligacion((int)procedencia, oblId, anioInicio, anioFin);
            Response result_FecVencimiento = obligacionRepository.ValidarFechaVencimientoCuotaObligacion((int)procedencia, oblId, anioInicio, anioFin);
            Response result_CuotaPagoMigrada = obligacionRepository.ValidarObligacionCuotaPagoMigrada((int)procedencia, oblId, anioInicio, anioFin);
            Response result_Procedencia = obligacionRepository.ValidarProcedenciaObligacionCuotaPago((int)procedencia, oblId, anioInicio, anioFin);

            result.IsDone = result_Alumnos.IsDone &&
                            result_Anio.IsDone &&
                            result_Periodo.IsDone &&
                            result_FecVencimiento.IsDone &&
                            result_CuotaPagoMigrada.IsDone &&
                            result_Procedencia.IsDone;

            result.Message = result_Alumnos.Message + " | " +
                            result_Anio.Message + " | " +
                            result_Periodo.Message + " | " +
                            result_FecVencimiento.Message + " | " +
                            result_CuotaPagoMigrada.Message + " | " +
                            result_Procedencia.Message;

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public Response Save(Obligacion obligacion, int tipoObserv)
        {
            Response result = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();

            switch ((ObligacionesPagoObs)tipoObserv)
            {
                case ObligacionesPagoObs.SinAlumno:
                    result = obligacionRepository.SaveEstudianteObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.AnioNoValido:
                    result = obligacionRepository.SaveAnioObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.SinPeriodo:
                    result = obligacionRepository.SavePeriodoObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.FchVencRepetido:
                    result = obligacionRepository.SaveFecVencObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.ExisteConOtroMonto:
                    result = obligacionRepository.SaveMontoObligacion(obligacion);
                    break;
                case ObligacionesPagoObs.SinCuotaPagoMigrable:
                    result = obligacionRepository.SaveCuotaPagoObligacion(obligacion);
                    break;
            }

            obligacionRepository.ValidarAlumnoCabeceraObligacion(obligacion.I_ProcedenciaID, obligacion.I_RowID, null, null);
            obligacionRepository.ValidarAnioEnCabeceraObligacion(obligacion.I_ProcedenciaID, obligacion.I_RowID);
            obligacionRepository.ValidarPeriodoEnCabeceraObligacion(obligacion.I_ProcedenciaID, obligacion.I_RowID, null, null);
            obligacionRepository.ValidarFechaVencimientoCuotaObligacion(obligacion.I_ProcedenciaID, obligacion.I_RowID, null, null);
            obligacionRepository.ValidarObligacionCuotaPagoMigrada(obligacion.I_ProcedenciaID, obligacion.I_RowID, null, null);
            obligacionRepository.ValidarProcedenciaObligacionCuotaPago(obligacion.I_ProcedenciaID, obligacion.I_RowID, null, null);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public string ObtenerComponenteId(int obsID)
        {
            string componentID;
            ObligacionesPagoObs obligacionesPagoObs = (ObligacionesPagoObs)obsID;

            switch (obligacionesPagoObs)
            {
                case ObligacionesPagoObs.SinAlumno:
                    componentID = "#Cod_alu";
                    break;
                case ObligacionesPagoObs.AnioNoValido:
                    componentID = "#Ano";
                    break;
                case ObligacionesPagoObs.SinPeriodo:
                    componentID = "#I_Periodo";
                    break;
                case ObligacionesPagoObs.FchVencRepetido:
                    componentID = "#Fch_venc";
                    break;
                case ObligacionesPagoObs.ExisteConOtroMonto:
                    componentID = "#Monto";
                    break;
                case ObligacionesPagoObs.SinCuotaPagoMigrable:
                    componentID = "#Cuota_pago";
                    break;
                default:
                    componentID = string.Empty;
                    break;
            }

            return componentID;
        }

        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            List<Response> resultObligaciones = new List<Response>();
            List<Response> resultPagos = new List<Response>();

            string schemaDb = Schema.SetSchema(procedencia);

            ObligacionRepository obligacionRepository = new ObligacionRepository();

            for (int anio = 2005; anio < 2023; anio++)
            {
                Response responseObl = new Response();
                Response responsePago = new Response();

                responseObl = obligacionRepository.MigrarDataObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);
                responsePago = obligacionRepository.MigrarDataPagoObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);

                resultObligaciones.Add(responseObl);
                resultPagos.Add(responsePago);
            }

            return resultObligaciones;
        }

    }
}