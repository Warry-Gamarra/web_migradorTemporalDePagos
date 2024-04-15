using ClosedXML.Excel;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using WebMigradorCtasPorCobrar.Models.Entities.Migracion;
using WebMigradorCtasPorCobrar.Models.Helpers;
using CrossRepo = WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;
using RepoCtas = WebMigradorCtasPorCobrar.Models.Repository.CtasPorCobrar;

using static WebMigradorCtasPorCobrar.Models.Helpers.Observaciones;
using WebMigradorCtasPorCobrar.Models.Repository.Migracion.Cross;

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
                obligacion.DetalleObligaciones = CrossRepo.ObligacionRepository.ObtenerDetalle(obligacionID).ToList();
            }

            return obligacion;
        }


        public IEnumerable<Obligacion> ObtenerPorAlumno(string codAlu, string codRc)
        {
            IEnumerable<Obligacion> obligaciones;

            obligaciones = CrossRepo.ObligacionRepository.ObtenerPorAlumno(codAlu, codRc);

            foreach (var item in obligaciones)
            {
                item.DetalleObligaciones = CrossRepo.ObligacionRepository.ObtenerDetallePorAlumno(codAlu, codRc, item.I_RowID).ToList();
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


        public DetalleObligacion ObtenerDatosDetalle(int detOblID)
        {
            return ObligacionRepository.ObtenerDatosDetalle(detOblID);
        }

        public IEnumerable<DetalleObligacion> ObtenerDetalleObligacion(int obligID)
        {
            return ObligacionRepository.ObtenerDetalle(obligID);
        }

    }
}