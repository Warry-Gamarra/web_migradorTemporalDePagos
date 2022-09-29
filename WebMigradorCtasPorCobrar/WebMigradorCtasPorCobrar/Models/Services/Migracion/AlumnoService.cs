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

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion
{
    public class AlumnoService
    {
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
            return AlumnoRepository.ObtenerPorId(alumnoId);
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

            alumno.I_ProcedenciaID = (byte)procedencia;

            result = AlumnoRepository.Save(alumno);

            if (result.IsDone)
            {
                result.Success(false);
            }
            else
            {
                result.Error(false);
            }

            return result;
        }

        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            result = alumnoRepository.CopiarRegistros((int)procedencia, schemaDb);

            if (result.IsDone)
            {
                result.Success(false);
            }
            else
            {
                result.Error(false);
            }

            return result;
        }

        public Response EjecutarValidaciones(Procedencia procedencia)
        {
            Response result = new Response();

            Response result_InicializarEstados = new Response();
            Response result_CaracteresEspeciales = new Response();
            Response result_CodigoCarreraAlumno = new Response();
            Response result_CodigosAlumnoRepetidos = new Response();
            Response result_AnioIngresoAlumno = new Response();
            Response result_ModIngresoAlumno = new Response();
            Response result_CorrespondenciaNumDoc = new Response();
            Response result_CorrespondenciaNumDocRepo = new Response();
            Response result_SexoDiferenteMismoDoc = new Response();

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            result_InicializarEstados = alumnoRepository.InicializarEstadoValidacionAlumno((int)procedencia);
            result_CaracteresEspeciales = alumnoRepository.ValidarCaracteresEspeciales((int)procedencia);
            result_CodigoCarreraAlumno = alumnoRepository.ValidarCodigoCarreraAlumno((int)procedencia);
            result_CodigosAlumnoRepetidos = alumnoRepository.ValidarCodigosAlumnoRepetidos((int)procedencia);
            result_AnioIngresoAlumno = alumnoRepository.ValidarAnioIngresoAlumno((int)procedencia);
            //result_ModIngresoAlumno = alumnoRepository.ValidarModalidadIngresoAlumno((int)procedencia);
            result_CorrespondenciaNumDoc = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersona((int)procedencia);
            result_CorrespondenciaNumDocRepo = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaRepo((int)procedencia);
            result_SexoDiferenteMismoDoc = alumnoRepository.ValidarSexoDiferenteMismoDocumento((int)procedencia);

            result.IsDone = result_CaracteresEspeciales.IsDone &&
                            result_CodigoCarreraAlumno.IsDone &&
                            result_CodigosAlumnoRepetidos.IsDone &&
                            result_AnioIngresoAlumno.IsDone &&
                            //result_ModIngresoAlumno.IsDone &&
                            result_CorrespondenciaNumDoc.IsDone &&
                            result_SexoDiferenteMismoDoc.IsDone;

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
                             //$"        <dt class=\"col-md-4 col-sm-6\">Observados por Modalidades de ingreso</dt>" +
                             //$"        <dd class=\"col-md-8 col-sm-6\">" +
                             //$"            <p>{result_ModIngresoAlumno.Message}</p>" +
                             //$"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Número de documento</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CorrespondenciaNumDoc.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Número de documento Repositorio</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_CorrespondenciaNumDocRepo.Message}</p>" +
                             $"        </dd>" +
                             $"        <dt class=\"col-md-4 col-sm-6\">Observados por Sexo duplicado</dt>" +
                             $"        <dd class=\"col-md-8 col-sm-6\">" +
                             $"            <p>{result_SexoDiferenteMismoDoc.Message}</p>" +
                             $"        </dd>" +
                             $"    </dl>";

            if (result.IsDone)
            {
                result.Success(false);
            }
            else
            {
                result.Warning(false);
            }

            return result;
        }


        public  Response MigrarDatosTemporalPagos(Procedencia procedencia)
        {
            Response result = new Response();
            string schemaDb = Schema.SetSchema(procedencia);

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            result = alumnoRepository.MigrarDataAlumnosUnfvRepositorio((int)procedencia);

            if (result.IsDone)
            {
                result.Success(false);
            }
            else
            {
                result.Error(false);
            }

            return result;
        }
    }
}