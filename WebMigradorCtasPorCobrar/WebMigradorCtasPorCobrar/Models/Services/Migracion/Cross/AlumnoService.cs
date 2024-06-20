using ClosedXML.Excel;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using WebMigradorCtasPorCobrar.Models.Services.CtasPorCobrar;
using WebMigradorCtasPorCobrar.Models.ViewModels;
using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using RepoAlu = WebMigradorCtasPorCobrar.Models.Repository.UnfvRepositorio;

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

        public IEnumerable<Alumno> Obtener(TipoData tipo, Procedencia procedencia, int? tipo_obsID)
        {
            bool alumnoOblig = Convert.ToBoolean(tipo);

            if (tipo_obsID.HasValue)
            {
                return ObtenerAlumnos(AlumnoRepository.ObtenerObservados((int)procedencia,
                                                                         tipo_obsID.Value,
                                                                         (int)Tablas.TR_Alumnos,
                                                                         alumnoOblig),
                                      procedencia);
            }

            return ObtenerAlumnos(AlumnoRepository.Obtener((int)procedencia, alumnoOblig),
                                  procedencia);
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



        public IEnumerable<Response> CopiarRegistrosDesdeTemporalPagos(Procedencia procedencia, TipoData tipoData)
        {
            List<Response> result = new List<Response>();
            
            Response resultItem;

            string schemaDb = Schema.SetSchema(procedencia);

            AlumnoRepository alumnoRepository = new AlumnoRepository();

            if (tipoData == TipoData.ConObligaciones)
            {
                resultItem = alumnoRepository.CopiarRegistrosConObligacion((int)procedencia, schemaDb);
            }
            else
            {
                resultItem = alumnoRepository.CopiarRegistrosSinObligacion((int)procedencia, schemaDb);
            }

            result.Add(resultItem.IsDone ? resultItem.Success(false) : resultItem.Error(false));

            return result;
        }


        public IEnumerable<Response> EjecutarValidaciones(Procedencia procedencia, TipoData tipoData, int? aluRowId)
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

            return response.ReturnViewValidationsMessage("Observados por caracteres especiales", (int)AlumnoObs.Caracteres, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por códigos de carrera", (int)AlumnoObs.SinCarrera, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por códigos de alumno repetidos", (int)AlumnoObs.Repetido, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por Años de ingreso", (int)AlumnoObs.SinAnioIngreso, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por Número de documento", (int)AlumnoObs.DniRepetido, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por presentar diferente cod_sexo para el mismo num_doc", (int)AlumnoObs.SexoErrado, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por estar con estado eliminado", (int)AlumnoObs.Removido, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por Número de documento en Repositorio", (int)AlumnoObs.DniExiste, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por sexo diferente para el mismo codigo de alumno en repositorio", (int)AlumnoObs.SexoDifente, "Estudiante", "EjecutarValidacion");
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

            return response.ReturnViewValidationsMessage("Observados por diferente num_doc para el mismo alumno en repositorio", (int)AlumnoObs.DniDiferente, "Estudiante", "EjecutarValidacion");
        }


        public IEnumerable<Response> MigrarDatosTemporalPagos(TipoData tipo, Procedencia procedencia, int? anio)
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

            var aniosIngreso = AlumnoRepository.Obtener(int_procedencia, Convert.ToBoolean(tipo)).Select(x => x.C_AnioIngreso).Distinct().OrderBy(x => x);

            foreach (var anioIngreso in aniosIngreso)
            {
                Response response = MigrarDatosTemporalPagosAnio((int)procedencia, anioIngreso.Value);

                result.Add(response);

            }

            return result;
        }


        public Response MigrarDatosTemporalPagosCodAlu(int procedencia, string codAlu)
        {
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            Response result = alumnoRepository.MigrarDataAlumnosUnfvRepositorioCodAlu(procedencia, codAlu);

            return result.ReturnViewMigrationMessage(codAlu + ":"); ;
        }

        public Response MigrarDatosTemporalPagosAnio(int procedencia, int anioIngreso)
        {
            AlumnoRepository alumnoRepository = new AlumnoRepository();

            Response result = alumnoRepository.MigrarDataAlumnosUnfvRepositorioAnio(procedencia, anioIngreso);

            return result.ReturnViewMigrationMessage(anioIngreso.ToString() + ":");
        }


        public Response EjecutarValidacionPorId(int procedencia, int ObservacionId)
        {
            Response result;

            switch ((AlumnoObs)ObservacionId)
            {
                case AlumnoObs.Caracteres:
                    result = ValidarCaracteresEspeciales(procedencia, null);
                    break;
                case AlumnoObs.Repetido:
                    result = ValidarCodigosAlumnoRepetidos(procedencia, null);
                    break;
                case AlumnoObs.SinAnioIngreso:
                    result = ValidarAnioIngresoAlumno(procedencia, null);
                    break;
                case AlumnoObs.SinCarrera:
                    result = ValidarCodigoCarreraAlumno(procedencia, null);
                    break;
                case AlumnoObs.DniRepetido:
                    result = ValidarCorrespondenciaNumDocumentoPersona(procedencia, null);
                    break;
                case AlumnoObs.SexoErrado:
                    result = ValidarSexoDiferenteMismoDocumentoPersona(procedencia, null);
                    break;
                case AlumnoObs.DniExiste:
                    result = ValidarCorrespondenciaNumDocumentoPersonaRepo(procedencia, null);
                    break;
                case AlumnoObs.Removido:
                    result = ValidarCodigosAlumnoRemovidos(procedencia, null);
                    break;
                case AlumnoObs.SexoDifente:
                    result = ValidarSexoDiferenteMismoAlumnoRepo(procedencia, null);
                    break;
                case AlumnoObs.DniDiferente:
                    result = ValidarNumDocumentoDiferenteMismoCodigoAlumnoRepo(procedencia, null);
                    break;
                default:
                    result = new Response();
                    break;
            }

            return result;
        }
    }
}