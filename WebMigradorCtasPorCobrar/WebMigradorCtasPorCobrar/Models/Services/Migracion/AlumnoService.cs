using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using System.IO;
using ClosedXML.Excel;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class AlumnoService
    {
        private readonly EquivalenciasServices _equivalenciasServices;

        public AlumnoService()
        {
            _equivalenciasServices = new EquivalenciasServices();
        }


        public IEnumerable<Alumno> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return AlumnoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Alumnos);
            }

            return AlumnoRepository.Obtener((int)procedencia);
        }

        public Alumno Obtener(int alumnoId)
        {
            var result = AlumnoRepository.ObtenerPorId(alumnoId);

            result.T_Carrera = _equivalenciasServices.ObtenerCarreraProfesional(result.C_RcCod).T_CarProfDesc;
            result.T_ModalidadIng = _equivalenciasServices.ObtenerModalidadIngreso(result.C_CodModIng).T_OpcionDesc;
            return result;
        }

        public byte[] ObtenerDatosObservaciones(Procedencia procedencia, int? tipo_obsID)
        {
            XLWorkbook excel_book = new XLWorkbook();
            MemoryStream result = new MemoryStream();

            tipo_obsID = tipo_obsID.HasValue ? tipo_obsID : 0;
            var data = AlumnoRepository.ObtenerReporteObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Alumnos);

            var sheet = excel_book.Worksheets.Add( data,"Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }


        public Response Save(Alumno alumno, Procedencia procedencia)
        {
            Response result = new Response();
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            alumnoRepository.InicializarEstadoValidacionAlumno((int)procedencia);

            alumno.I_ProcedenciaID = (byte)procedencia;
            result = AlumnoRepository.Save(alumno);

            alumnoRepository.ValidarCaracteresEspeciales((int)procedencia);
            alumnoRepository.ValidarCodigoCarreraAlumno((int)procedencia);
            alumnoRepository.ValidarCodigosAlumnoRepetidos((int)procedencia);
            alumnoRepository.ValidarAnioIngresoAlumno((int)procedencia);

            alumnoRepository.ValidarCorrespondenciaNumDocumentoPersona((int)procedencia);
            alumnoRepository.ValidarSexoDiferenteMismoDocumentoPersona((int)procedencia);
            alumnoRepository.ValidarCodigosAlumnoRemovidos((int)procedencia);
            alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaRepo((int)procedencia);
            alumnoRepository.ValidarSexoDiferenteMismoAlumnoRepo((int)procedencia);
            alumnoRepository.ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepo((int)procedencia);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            result = alumnoRepository.CopiarRegistros((int)procedencia, schemaDb);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }

        public Response EjecutarValidaciones(Procedencia procedencia)
        {
            Response result = new Response();

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            Response result_InicializarEstados = alumnoRepository.InicializarEstadoValidacionAlumno((int)procedencia);
            Response result_CaracteresEspeciales = alumnoRepository.ValidarCaracteresEspeciales((int)procedencia);
            Response result_CodigoCarreraAlumno = alumnoRepository.ValidarCodigoCarreraAlumno((int)procedencia);
            Response result_CodigosAlumnoRepetidos = alumnoRepository.ValidarCodigosAlumnoRepetidos((int)procedencia);
            Response result_AnioIngresoAlumno = alumnoRepository.ValidarAnioIngresoAlumno((int)procedencia);

            Response result_CorrespondenciaNumDoc = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersona((int)procedencia);
            Response result_SexoDiferenteMismoDoc = alumnoRepository.ValidarSexoDiferenteMismoDocumentoPersona((int)procedencia);
            Response result_DniDiferenteMismoCodAlu = alumnoRepository.ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepo((int)procedencia);
            Response result_CodigosAlumnoRemovidos = alumnoRepository.ValidarCodigosAlumnoRemovidos((int)procedencia);

            Response result_CorrespondenciaNumDocRepo = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaRepo((int)procedencia);
            Response result_SexoDiferenteMismoDocRepo = alumnoRepository.ValidarSexoDiferenteMismoAlumnoRepo((int)procedencia);

            result.IsDone = result_CaracteresEspeciales.IsDone &&
                            result_CodigoCarreraAlumno.IsDone &&
                            result_CodigosAlumnoRepetidos.IsDone &&
                            result_AnioIngresoAlumno.IsDone &&
                            result_CorrespondenciaNumDoc.IsDone &&
                            result_SexoDiferenteMismoDoc.IsDone &&
                            result_DniDiferenteMismoCodAlu.IsDone &&
                            result_SexoDiferenteMismoDocRepo.IsDone;

            result.Message = $"    <dl class=\"row text-justify\">" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por caracteres especiales</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CaracteresEspeciales.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por codigos de carrera</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CodigoCarreraAlumno.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por codigos de alumno repetidos</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CodigosAlumnoRepetidos.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Años de ingreso</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_AnioIngresoAlumno.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Número de documento</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CorrespondenciaNumDoc.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Número de documento</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_DniDiferenteMismoCodAlu.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Número de documento Repositorio</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CorrespondenciaNumDocRepo.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Sexo difernte</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_SexoDiferenteMismoDoc.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Sexo difernte con el repositorio</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_SexoDiferenteMismoDocRepo.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public  Response MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            result = alumnoRepository.MigrarDataAlumnosUnfvRepositorio((int)procedencia);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }
    }
}