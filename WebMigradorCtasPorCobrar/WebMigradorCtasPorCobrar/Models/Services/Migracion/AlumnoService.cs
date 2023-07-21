using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion;
using RepoAlu = WebMigradorCtasPorCobrar.Models.Repository.UnfvRepositorio;
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

        private IEnumerable<Alumno> ObtenerAlumnos(IEnumerable<Alumno> alumnos, Procedencia procedencia)
        {
            var alumnosRepo = RepoAlu.AlumnoRepository.Obtener((int)procedencia);

            var newAlumnos = from a in alumnos
                             join ar in alumnosRepo on new { a.C_CodAlu, a.C_RcCod } equals new { ar.C_CodAlu, ar.C_RcCod }
                             into AlumnosAlumnosRepoGroup
                             from aarg in AlumnosAlumnosRepoGroup.DefaultIfEmpty()
                             select new Alumno
                             {
                                 C_CodAlu = a.C_CodAlu,
                                 C_RcCod = a.C_RcCod,
                                 I_RowID = a.I_RowID,
                                 B_Migrado = a.B_Migrado,
                                 B_Migrable = a.B_Migrable,
                                 C_NumDNI = a.C_NumDNI,
                                 T_ApeMaterno = a.T_ApeMaterno,
                                 T_ApePaterno = a.T_ApePaterno,
                                 T_Nombre = a.T_Nombre,
                                 I_ProcedenciaID = a.I_ProcedenciaID,
                                 B_ExistsDestino = aarg == null ? false : true
                             };

            return newAlumnos;
        }

        public IEnumerable<Alumno> Obtener(Procedencia procedencia, int? tipo_obsID)
        {
            if (tipo_obsID.HasValue)
            {
                return ObtenerAlumnos(AlumnoRepository.ObtenerObservados((int)procedencia, tipo_obsID.Value, (int)Tablas.TR_Alumnos), procedencia);
            }

            return ObtenerAlumnos(AlumnoRepository.Obtener((int)procedencia), procedencia);
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

            result.Message = $"    <dl class=\"row text-justify pt-3\">" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por caracteres especiales :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_CaracteresEspeciales.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por códigos de carrera :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_CodigoCarreraAlumno.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por códigos de alumno repetidos :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_CodigosAlumnoRepetidos.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Años de ingreso :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_AnioIngresoAlumno.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Número de documento :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_CorrespondenciaNumDoc.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Número de documento :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_DniDiferenteMismoCodAlu.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Número de documento Repositorio :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_CorrespondenciaNumDocRepo.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Sexo diferente :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_SexoDiferenteMismoDoc.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-6 col-sm-8 col-10 text-right\">Observados por Sexo diferente con el repositorio :</dt>" +
                             $"        <dd class=\"col-md-6 col-sm-4 col-2\">" +
                             $"            <p>{result_SexoDiferenteMismoDocRepo.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public  Response MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response() { IsDone = true };

            string schemaDb = Schema.SetSchema(procedencia);

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            var aniosIngreso = AlumnoRepository.Obtener((int)procedencia).Select(x => x.C_AnioIngreso).Distinct().OrderBy(x => x);

            foreach (var anio in aniosIngreso)
            {
                Response response = alumnoRepository.MigrarDataAlumnosUnfvRepositorio((int)procedencia, null, anio);
                response = response.IsDone ? response.Success(false) : response.Error(false);

                result.IsDone = result.IsDone && response.IsDone;
                result.Message += $"<p>Año {anio}:<p><p class=\"alert alert-{response.Color}\">{response.Message} <i class=\"{response.Icon}\"></i></p>";
            }

            return result.IsDone ? result.Success(false) : result.Error(false);
        }
    }
}