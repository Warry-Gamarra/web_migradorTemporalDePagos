using ClosedXML.Excel;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using Temporal = WebMigradorCtasPorCobrar.Models.Repository.TemporalPagos.ObligacionRepository;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Obligaciones;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using RepoCtas = WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;

using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross
{
    public class ObligacionService
    {
        public IEnumerable<AnioObligacion> ObtenerAnios(Procedencia procedencia)
        {
            List<AnioObligacion> result = new List<AnioObligacion>();

            foreach (var item in CrossRepo.ObligacionRepository.ObtenerAnios((int)procedencia))
            {
                result.Add(new AnioObligacion(item));
            }
            return result;
        }


        public IEnumerable<Obligacion> ObtenerObligaciones(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObtenerConRepo(CrossRepo.ObligacionRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Ec_Obl), procedencia);
            }

            return ObtenerConRepo(CrossRepo.ObligacionRepository.Obtener((int)procedencia), procedencia);
        }


        private IEnumerable<Obligacion> ObtenerConRepo(IEnumerable<Obligacion> obligaciones, Procedencia procedencia)
        {
            var obligacionesCtas = RepoCtas.ObligacionesRepository.Obtener((int)procedencia);

            var newObligacion = from o in obligaciones
                                select o;
                                //join oc in obligacionesCtas on o.I_RowID equals oc.I_MigracionRowID
                                //into obligacionesPagoGroup
                                //from og in obligacionesPagoGroup.DefaultIfEmpty()
                                //select new Obligacion()
                                //{
                                //    I_RowID = o.I_RowID,
                                //    Ano = o.Ano,
                                //    P = o.P,
                                //    I_Periodo = o.I_Periodo,
                                //    Cod_alu = o.Cod_alu,
                                //    Cod_RC = o.Cod_RC,
                                //    NomAlumno = o.NomAlumno,
                                //    T_Carrera = o.T_Carrera,
                                //    Cuota_pago = o.Cuota_pago,
                                //    Cuota_pago_desc = o.Cuota_pago_desc,
                                //    Tipo_oblig = o.Tipo_oblig,
                                //    Fch_venc = o.Fch_venc,
                                //    Monto = o.Monto,
                                //    Pagado = o.Pagado,
                                //    D_FecCarga = o.D_FecCarga,
                                //    B_Actualizado = o.B_Actualizado,
                                //    D_FecActualiza = o.D_FecActualiza,
                                //    B_Migrable = o.B_Migrable,
                                //    D_FecEvalua = o.D_FecEvalua,
                                //    B_Migrado = o.B_Migrado,
                                //    D_FecMigrado = o.D_FecMigrado,
                                //    B_Removido = o.B_Removido,
                                //    D_FecRemovido = o.D_FecRemovido,
                                //    DetalleObligaciones = o.DetalleObligaciones,
                                //    I_ProcedenciaID = o.I_ProcedenciaID,
                                //    B_ExisteCtas = og == null ? false : true
                                //};

            return newObligacion;
        }


        public Obligacion ObtenerObligacion(int obligacionID, bool getDetalle)
        {
            var obligacion = CrossRepo.ObligacionRepository.ObtenerPorID(obligacionID);

            if (getDetalle)
            {
                obligacion.DetalleObligaciones = CrossRepo.DetalleObligacionRepository.Obtener(obligacionID).ToList();
            }

            return obligacion;
        }

        public IEnumerable<Obligacion> ObtenerPorAlumno(string codAlu, string codRc)
        {
            IEnumerable<Obligacion> obligaciones;

            obligaciones = CrossRepo.ObligacionRepository.ObtenerPorAlumno(codAlu, codRc);

            foreach (var item in obligaciones)
            {
                item.DetalleObligaciones = CrossRepo.DetalleObligacionRepository.ObtenerDetallePorAlumno(codAlu, codRc, item.I_RowID).ToList();
            }

            return obligaciones;
        }


        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = CrossRepo.ObligacionRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Ec_Obl);

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }


        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia, string anio)
        {
            Response result = new Response();
            Response result_Cabecera = new Response();
            Response result_Detalle = new Response();
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            DetalleObligacionRepository detalleObligacionRepository = new DetalleObligacionRepository();

            string schemaDb = Schema.SetSchema(procedencia);

            if (!string.IsNullOrEmpty(anio))
            {
                result_Cabecera = obligacionRepository.CopiarRegistrosCabecera((int)procedencia, schemaDb, anio);
                result_Detalle = detalleObligacionRepository.CopiarRegistrosDetalle((int)procedencia, schemaDb, anio);
                
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
            }
            else
            {
                foreach (var itemAnio in Temporal.ObtenerAnios(schemaDb))
                {
                    result_Cabecera = obligacionRepository.CopiarRegistrosCabecera((int)procedencia, schemaDb, itemAnio);
                    result_Detalle = detalleObligacionRepository.CopiarRegistrosDetalle((int)procedencia, schemaDb, itemAnio);


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
                }
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


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, PeriodosValidacion periodosValidacion)
        {
            short anioInicio = 0;
            short anioFin = 0;
            int procedencia_id = (int)procedencia;

            List<Response> result = new List<Response>();
            ObligacionRepository obligacionRepository = new ObligacionRepository();

            switch (periodosValidacion)
            {
                case PeriodosValidacion.Anterior_hasta_2009:
                    anioInicio = 2000;
                    anioFin = 2009;
                    break;
                case PeriodosValidacion.Del_2010_al_2015:
                    anioInicio = 2010;
                    anioFin = 2015;
                    break;
                case PeriodosValidacion.Del_2016_al_2020:
                    anioInicio = 2016;
                    anioFin = 2020;
                    break;
            }

           result.Add(ValidarAnioEnCabeceraObligacion(procedencia_id));

           for (short anio = anioInicio; anio <= anioFin; anio++)
            {
                _ = obligacionRepository.InicializarEstadoValidacionObligacionPago((int)procedencia, anio);

                result.Add(ValidarAlumnoCabeceraObligacion(procedencia_id, anio));
                result.Add(ValidarPeriodoEnCabeceraObligacion(procedencia_id, anio));
                result.Add(ValidarFechaVencimientoCuotaObligacion(procedencia_id, anio));
                result.Add(ValidarObligacionCuotaPagoMigrada(procedencia_id, anio));
                result.Add(ValidarProcedenciaObligacionCuotaPago(procedencia_id, anio));
            }

            return result;
        }


        private Response ValidarProcedenciaObligacionCuotaPago(int procedencia, short anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Procedencia = obligacionRepository.ValidarProcedenciaObligacionCuotaPago(procedencia, anio);

            int obsProcedencia = int.TryParse(result_Procedencia.Message, out int obs_proc) ? obs_proc : 0;
            result_Procedencia = result_Procedencia.IsDone ? (obsProcedencia > 0 ? result_Procedencia.Warning($"{obsProcedencia} registros encontrados", false) 
                                                                                 : result_Procedencia.Success(false))
                                                     : result_Procedencia.Error(false);

            result_Procedencia.CurrentID = $"Año {anio} - Observado por procedencia de la cuota de pago";

            return result_Procedencia;
        }


        private Response ValidarObligacionCuotaPagoMigrada (int procedencia, short anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_CuotaPagoMigrada = obligacionRepository.ValidarObligacionCuotaPagoMigrada(procedencia, anio);

            int obsCuotaPago = int.TryParse(result_CuotaPagoMigrada.Message, out int obs_cp) ? obs_cp : 0;
            result_CuotaPagoMigrada = result_CuotaPagoMigrada.IsDone ? (obsCuotaPago > 0 ? result_CuotaPagoMigrada.Warning($"{obs_cp} registros encontrados", false) 
                                                                     : result_CuotaPagoMigrada.Success(false))
                                                          : result_CuotaPagoMigrada.Error(false);

            result_CuotaPagoMigrada.CurrentID = $"Año {anio} - Observado por cuota de pago sin migrar";

            return result_CuotaPagoMigrada;
        }

        private Response ValidarFechaVencimientoCuotaObligacion(int procedencia, short anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_FecVencimiento = obligacionRepository.ValidarFechaVencimientoCuotaObligacion(procedencia, anio);
            int obsFecVenc = int.TryParse(result_FecVencimiento.Message, out int obs_fecVenc) ? obs_fecVenc : 0;

            result_FecVencimiento = result_FecVencimiento.IsDone ? (obsFecVenc > 0 ? result_FecVencimiento.Warning($"{obsFecVenc} registros encontrados", false)
                                                                                   : result_FecVencimiento.Success(false))
                                                                 : result_FecVencimiento.Error(false);

            result_FecVencimiento.CurrentID = $"Año {anio} - Observado por fecha de vencimiento repetido para diferentes cuotas de pago";

            return result_FecVencimiento;
        }

        private Response ValidarAlumnoCabeceraObligacion (int procedencia, short anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Alumnos = obligacionRepository.ValidarAlumnoCabeceraObligacion(procedencia, anio);
            int obsAlumno = int.TryParse(result_Alumnos.Message, out int obs_Alu) ? obs_Alu : 0;

            result_Alumnos = result_Alumnos.IsDone ? (obsAlumno > 0 ? result_Alumnos.Warning($"{obs_Alu} registros encontrados", false)
                                                                    : result_Alumnos.Success(false))
                                                   : result_Alumnos.Error(false);

            result_Alumnos.CurrentID = $"Año {anio} - Observados por código de alumno inexistente en la relación de alumnos.";

            return result_Alumnos;
        }
         
        private Response ValidarAnioEnCabeceraObligacion(int procedencia)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Anio = obligacionRepository.ValidarAnioEnCabeceraObligacion(procedencia);

            int obsAnio = int.TryParse(result_Anio.Message, out int obs_Anio) ? obs_Anio : 0;

            result_Anio = result_Anio.IsDone ? (obsAnio > 0 ? result_Anio.Warning($"{obsAnio} registros encontrados", false) 
                                                            : result_Anio.Success(false))
                                             : result_Anio.Error(false);

            result_Anio.CurrentID = $"Observados por año errado en la obligación";
            return result_Anio;
        }

        private Response ValidarPeriodoEnCabeceraObligacion(int procedencia, short anio)
        {
            ObligacionRepository obligacionRepository = new ObligacionRepository();
            Response result_Periodo = obligacionRepository.ValidarPeriodoEnCabeceraObligacion(procedencia, anio);
            int obsPeriodo = int.TryParse(result_Periodo.Message, out int obs_per) ? obs_per : 0;

            result_Periodo = result_Periodo.IsDone ? (obsPeriodo > 0 ? result_Periodo.Warning($"{obsPeriodo} registros encontrados", false) 
                                                                     : result_Periodo.Success(false))
                                                   : result_Periodo.Error(false);

            result_Periodo.CurrentID = $"Año {anio} - Observados por periodo errado en la obligación";

            return result_Periodo;
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

            obligacionRepository.ValidarAlumnoCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarAnioEnCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarPeriodoEnCabeceraObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarFechaVencimientoCuotaObligacionPorID(obligacion.I_RowID);
            obligacionRepository.ValidarObligacionCuotaPagoMigradaPorObligacionID(obligacion.I_RowID);
            obligacionRepository.ValidarProcedenciaObligacionCuotaPagoPorOblID(obligacion.I_RowID);

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

        public IEnumerable<Response> MigrarDatosTemporalPagosObligacionID(int obl_rowId)
        {
            List<Response> result = new List<Response>();
            ObligacionRepository obligacionRepository = new ObligacionRepository();

            Response responseObl = obligacionRepository.MigrarDataObligacionesCtasPorCobrarPorObligacionID(obl_rowId);
            Response responsePago;
            if (responseObl.IsDone)
            {
                responsePago = obligacionRepository.MigrarDataPagoObligacionesCtasPorCobrarPorObligacionID(obl_rowId);
            }
            else
            {
                responsePago = new Response() { IsDone = false, Message = "No se encontraron obligación migrada para la migración del pago" };
            }

            responseObl = responseObl.IsDone ? responseObl.Success(false) : responseObl.Error(false);
            responseObl.Action = "Migración de la obligación...";
            
            responsePago = responsePago.IsDone ? responsePago.Success(false) : responsePago.Error(false);
            responsePago.Action = "Migración del pago de la obligación...";

            result.Add(responseObl);
            result.Add(responsePago);

            return result;
        }

        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            List<Response> resultObligaciones = new List<Response>();
            List<Response> resultPagos = new List<Response>();

            string schemaDb = Schema.SetSchema(procedencia);

            ObligacionRepository obligacionRepository = new ObligacionRepository();

            for (int anio = 2005; anio < 2023; anio++)
            {
                Response responseObl;
                Response responsePago;

                responseObl = obligacionRepository.MigrarDataObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);
                responsePago = obligacionRepository.MigrarDataPagoObligacionesCtasPorCobrar((int)procedencia, null, anio, anio);

                resultObligaciones.Add(responseObl);
                resultPagos.Add(responsePago);
            }

            return resultObligaciones;
        }

    }
}