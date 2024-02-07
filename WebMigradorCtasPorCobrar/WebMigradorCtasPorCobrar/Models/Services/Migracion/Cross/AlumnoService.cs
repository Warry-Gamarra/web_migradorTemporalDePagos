using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using RepoAlu = WebMigradorCtasPorCobrar.Models.Repository.UnfvRepositorio;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using System.IO;
using ClosedXML.Excel;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;

namespace WebMigradorCtasPorCobrar.Models.Services.Migracion.Cross
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

            var sheet = excel_book.Worksheets.Add(data, "Observaciones");
            sheet.ColumnsUsed().AdjustToContents();

            excel_book.SaveAs(result);

            return result.ToArray();
        }


        public Response Save(Alumno alumno, Procedencia procedencia)
        {
            Response result;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            alumnoRepository.InicializarEstadoValidacionPorAlumno(alumno.I_RowID);

            alumno.I_ProcedenciaID = (byte)procedencia;
            result = AlumnoRepository.Save(alumno);

            alumnoRepository.ValidarCaracteresEspecialesPorAlumno(alumno.I_RowID);
            alumnoRepository.ValidarCodigoCarreraAlumno(alumno.I_RowID);
            alumnoRepository.ValidarCodigosAlumnoRepetidosPorAlumno(alumno.I_RowID);
            alumnoRepository.ValidarAnioIngresoPorAlumno(alumno.I_RowID);

            alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaPorAlumno(alumno.I_RowID);
            alumnoRepository.ValidarSexoDiferenteMismoDocumentoPersonaPorAlumno(alumno.I_RowID);
            alumnoRepository.ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepoPorAlumno(alumno.I_RowID);
            alumnoRepository.ValidarCodigosAlumnoRemovidosPorAlumno(alumno.I_RowID);
            alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaRepoPorAlumno(alumno.I_RowID);
            alumnoRepository.ValidarSexoDiferenteMismoAlumnoRepoPorAlumno(alumno.I_RowID);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public Response CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia)
        {
            Response result;
            string schemaDb = Schema.SetSchema(procedencia);

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            result = alumnoRepository.CopiarRegistros((int)procedencia, schemaDb);

            return result.IsDone ? result.Success(false) : result.Error(false);
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, int? aluRowId)
        {
            List<Response> result = new List<Response>();
            int procedenciaId = (int)procedencia;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            alumnoRepository.InicializarEstadoValidacionAlumno(procedenciaId);

            result.Add(ValidarCaracteresEspeciales(procedenciaId, aluRowId));
            result.Add(ValidarCodigoCarreraAlumno(procedenciaId, aluRowId));
            result.Add(ValidarCodigosAlumnoRepetidos(procedenciaId, aluRowId));
            result.Add(ValidarAnioIngresoAlumno(procedenciaId, aluRowId));
            result.Add(ValidarCorrespondenciaNumDocumentoPersona(procedenciaId, aluRowId));
            result.Add(ValidarSexoDiferenteMismoDocumentoPersona(procedenciaId, aluRowId));
            result.Add(ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepo(procedenciaId, aluRowId));
            result.Add(ValidarCodigosAlumnoRemovidos(procedenciaId, aluRowId));
            result.Add(ValidarCorrespondenciaNumDocumentoPersonaRepo(procedenciaId, aluRowId));
            result.Add(ValidarSexoDiferenteMismoAlumnoRepo(procedenciaId, aluRowId));

            return result;
        }


        private Response ValidarCaracteresEspeciales(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarCaracteresEspecialesPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarCaracteresEspeciales(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por caracteres especiales";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCodigoCarreraAlumno(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarCodigoCarreraPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarCodigoCarreraAlumno(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por códigos de carrera";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCodigosAlumnoRepetidos(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarCodigosAlumnoRepetidosPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarCodigosAlumnoRepetidos(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por códigos de alumno repetidos";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarAnioIngresoAlumno(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarAnioIngresoPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarAnioIngresoAlumno(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por Años de ingreso";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCorrespondenciaNumDocumentoPersona(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersona(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por Número de documento";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarSexoDiferenteMismoDocumentoPersona(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarSexoDiferenteMismoDocumentoPersonaPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarSexoDiferenteMismoDocumentoPersona(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por presentar diferente cod_sexo para el mismo num_doc";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCodigosAlumnoRemovidos(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarCodigosAlumnoRemovidosPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarCodigosAlumnoRemovidos(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por estar con estado eliminado";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarCorrespondenciaNumDocumentoPersonaRepo(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaRepoPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarCorrespondenciaNumDocumentoPersonaRepo(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por Número de documento en Repositorio";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarSexoDiferenteMismoAlumnoRepo(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarSexoDiferenteMismoAlumnoRepoPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarSexoDiferenteMismoAlumnoRepo(procedencia);
            }

            response = response.IsDone ? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por sexo diferente para el mismo codigo de alumno en repositorio";
            response.Message += " registros encontrados";

            return response;
        }

        private Response ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepo(int procedencia, int? aluRowId)
        {
            Response response;
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (aluRowId.HasValue)
            {
                response = alumnoRepository.ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepoPorAlumno(aluRowId.Value);
            }
            else
            {
                response = alumnoRepository.ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepo(procedencia);
            }

            response = response.IsDone? response.Success(false) : response.Error(false);
            int observados = int.TryParse(response.Message, out int obs) ? obs : 0;
            response = observados == 0 ? response : response.Warning(false);
            response.CurrentID = "Observados por diferente num_doc para el mismo alumno en repositorio";
            response.Message += " registros encontrados";

            return response;
        }


        public IEnumerable<Response> MigrarDatosTemporalPagos(Procedencia procedencia, int? anio)
        {
            List<Response> result = new List<Response>();
            int int_procedencia = (int)procedencia;
            string schemaDb = Schema.SetSchema(procedencia);

            if (anio.HasValue)
            {
                result.Add(MigrarDatosTemporalPagosAnio(int_procedencia, anio.Value));

                return result;
            }

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            var aniosIngreso = AlumnoRepository.Obtener(int_procedencia).Select(x => x.C_AnioIngreso).Distinct().OrderBy(x => x);

            foreach (var anioIngreso in aniosIngreso)
            {
                Response response = MigrarDatosTemporalPagosAnio((int)procedencia, anioIngreso.Value);
                response.CurrentID = anioIngreso.ToString();

                result.Add(response);

            }

            return result;
        }


        public Response MigrarDatosTemporalPagosCodAlu(int procedencia, string codAlu)
        {
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            Response result = alumnoRepository.MigrarDataAlumnosUnfvRepositorioCodAlu(procedencia, codAlu);
            result = result.IsDone ? result.Success(false) : result.Error(false);

            return result;
        }

        public Response MigrarDatosTemporalPagosAnio(int procedencia, int anioIngreso)
        {            
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            Response result = alumnoRepository.MigrarDataAlumnosUnfvRepositorioAnio(procedencia, anioIngreso);
            result = result.IsDone ? result.Success(false) : result.Error(false);

            return result;
        }

    }
}