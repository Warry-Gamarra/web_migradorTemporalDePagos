insert into TC_MatriculaAlumno (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
select distinct a.c_rccod, c_codalu, 2020, I_OpcionID, 'R', null, 0, 0,1,0, 1
from BD_OCEF_MigracionTP..tr_alumnos a
	 inner join BD_OCEF_TemporalPagos.eupg.ec_obl b on a.C_CodAlu = b.cod_alu and a.C_RcCod = b.cod_rc
	 inner join TC_CatalogoOpcion C ON b.p = c.T_OpcionCod and c.I_ParametroID = 5
where b.ano = '2020'


insert into [dbo].[TR_ObligacionAluCab] (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado)
select  cuota_pago, c.I_MatAluID, 'PEN', monto, fch_venc, pagado, 1, 0
from BD_OCEF_TemporalPagos.eupg.ec_obl a
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TC_Proceso] b on a.cuota_pago = b.I_ProcesoID and cast(a.fch_venc as date) = cast(b.D_FecVencto as date)
										and a.ano = cast(b.I_Anio as varchar(4))
where b.I_Anio = 2020 --and pagado = 0
order by 2

insert into [dbo].[TR_ObligacionAluDet] (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, B_Mora)
select distinct d.I_ObligacionAluID, e.I_ConcPagID, a.monto, a.pagado, D_FecVencto, null, null, 1, 0, 0
from BD_OCEF_TemporalPagos.eupg.ec_det a
	inner join BD_OCEF_TemporalPagos.eupg.ec_obl b on a.cod_alu = b.cod_alu and a.cod_rc = b.cod_rc and a.ano = b.ano and a.fch_venc = b.fch_venc
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TR_ObligacionAluCab] d on b.cuota_pago = d.I_ProcesoID and a.fch_venc = d.D_FecVencto and d.I_MatAluID = c.I_MatAluID
	inner join [dbo].[TI_ConceptoPago] e on a.concepto = e.I_ConcPagID
where a.concepto_f <> 1 
		and a.ano = '2020'
		and eliminado = 0


insert into TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora)
select distinct 1, a.nro_recibo, cod_alu, null, a.nro_recibo, a.fch_pago, a.cantidad, 'PEN', A.monto, id_lug_pag, a.eliminado, null, cast(documento as varchar(max)),131, 133, b.I_CtaDepositoID, 0 
from BD_OCEF_TemporalPagos.eupg.ec_det a
	 inner join [dbo].[TI_CtaDepo_Proceso] b on a.cuota_pago = b.I_ProcesoID
where a.concepto_f = 1
		and fch_pago > '19001001'
		and a.ano = '2020'
		and eliminado = 0
	

insert into TRI_PagoProcesadoUnfv (I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado, I_ObligacionAluDetID)
select distinct d.I_PagoBancoID, d.I_CtaDepositoID, null, d.I_MontoPago, 0, 0, 0, null, 0, e.I_ObligacionAluDetID
from BD_OCEF_TemporalPagos.eupg.ec_det a
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TR_ObligacionAluCab] b on a.cuota_pago = b.I_ProcesoID and a.fch_venc = b.D_FecVencto and b.I_MatAluID = c.I_MatAluID
	inner join TR_PagoBanco d on a.cod_alu = d.C_CodDepositante and a.fch_pago = CAST(d.D_FecPago as date) and a.monto = d.I_MontoPago and a.ano = '2020'
	inner join [TR_ObligacionAluDet] e on e.I_ObligacionAluID = b.I_ObligacionAluID and a.concepto = e.I_ConcPagID





insert into TC_MatriculaAlumno (C_CodRc, C_CodAlu, I_Anio, I_Periodo, C_EstMat, C_Ciclo, B_Ingresante, I_CredDesaprob, B_Habilitado, B_Eliminado, B_Migrado)
select distinct a.c_rccod, c_codalu, 2012, I_OpcionID, 'R', null, 0, 0,1,0, 1
from BD_OCEF_MigracionTP..tr_alumnos a
	 inner join BD_OCEF_TemporalPagos.pregrado.ec_obl b on a.C_CodAlu = b.cod_alu and a.C_RcCod = b.cod_rc
	 inner join TC_CatalogoOpcion C ON b.p = c.T_OpcionCod and c.I_ParametroID = 5
where b.ano = '2012'
	and a.c_codalu = '2010002487'


insert into [dbo].[TR_ObligacionAluCab] (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado)
select cuota_pago, c.I_MatAluID, 'PEN', monto, fch_venc, pagado, 1, 0
from BD_OCEF_TemporalPagos.pregrado.ec_obl a
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TC_Proceso] b on a.cuota_pago = b.I_ProcesoID and cast(a.fch_venc as date) = cast(b.D_FecVencto as date)
										and a.ano = cast(b.I_Anio as varchar(4))
where b.I_Anio = 2012 --and pagado = 0
order by 2

insert into [dbo].[TR_ObligacionAluDet] (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, B_Mora)
select distinct d.I_ObligacionAluID, e.I_ConcPagID, a.monto, a.pagado, D_FecVencto, null, null, 1, 0, 0
from BD_OCEF_TemporalPagos.pregrado.ec_det a
	inner join BD_OCEF_TemporalPagos.pregrado.ec_obl b on a.cod_alu = b.cod_alu and a.cod_rc = b.cod_rc and a.ano = b.ano and a.fch_venc = b.fch_venc
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TR_ObligacionAluCab] d on b.cuota_pago = d.I_ProcesoID and a.fch_venc = d.D_FecVencto and d.I_MatAluID = c.I_MatAluID
	inner join [dbo].[TI_ConceptoPago] e on a.concepto = e.I_ConcPagID
where a.concepto_f <> 1 
		and a.ano = '2012'
		and eliminado = 0


insert into TR_PagoBanco (I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, B_Anulado, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora)
select distinct 1, a.nro_recibo, cod_alu, null, a.nro_recibo, a.fch_pago, a.cantidad, 'PEN', A.monto, id_lug_pag, a.eliminado, null, cast(documento as varchar(max)),131, 133, b.I_CtaDepositoID, 0 
from BD_OCEF_TemporalPagos.pregrado.ec_det a
	 inner join [dbo].[TI_CtaDepo_Proceso] b on a.cuota_pago = b.I_ProcesoID
where a.concepto_f = 1
		and fch_pago > '19001001'
		and a.ano = '2012'
		and eliminado = 0
	

insert into TRI_PagoProcesadoUnfv (I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado, I_ObligacionAluDetID)
select distinct d.I_PagoBancoID, d.I_CtaDepositoID, null, d.I_MontoPago, 0, 0, 0, null, 0, e.I_ObligacionAluDetID
from BD_OCEF_TemporalPagos.pregrado.ec_det a
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TR_ObligacionAluCab] b on a.cuota_pago = b.I_ProcesoID and a.fch_venc = b.D_FecVencto and b.I_MatAluID = c.I_MatAluID
	inner join TR_PagoBanco d on a.cod_alu = d.C_CodDepositante and a.fch_pago = CAST(d.D_FecPago as date) and a.monto = d.I_MontoPago and a.ano = '2012'
	inner join [TR_ObligacionAluDet] e on e.I_ObligacionAluID = b.I_ObligacionAluID and a.concepto = e.I_ConcPagID









select * from TC_MatriculaAlumno where c_codalu = '2010002487'


insert into [dbo].[TR_ObligacionAluCab] (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado)
select cuota_pago, c.I_MatAluID, 'PEN', monto, fch_venc, pagado, 1, 0
from BD_OCEF_TemporalPagos.euded.ec_obl a
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TC_Proceso] b on a.cuota_pago = b.I_ProcesoID and cast(a.fch_venc as date) = cast(b.D_FecVencto as date)
										and a.ano = cast(b.I_Anio as varchar(4))

insert into [dbo].[TR_ObligacionAluCab] (I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado)
select cuota_pago, c.I_MatAluID, 'PEN', monto, fch_venc, pagado, 1, 0
from BD_OCEF_TemporalPagos.pregrado.ec_obl a
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TC_Proceso] b on a.cuota_pago = b.I_ProcesoID and cast(a.fch_venc as date) = cast(b.D_FecVencto as date)
										and a.ano = cast(b.I_Anio as varchar(4))










insert into [dbo].[TR_ObligacionAluDet] (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, B_Mora)
select d.I_ObligacionAluID, e.I_ConcPagID, a.monto, a.pagado, D_FecVencto, null, null, 1, 0, 0
from BD_OCEF_TemporalPagos.pregrado.ec_det a
	inner join BD_OCEF_TemporalPagos.pregrado.ec_obl b on a.cod_alu = b.cod_alu and a.cod_rc = b.cod_rc and a.ano = b.ano and a.fch_venc = b.fch_venc
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TR_ObligacionAluCab] d on b.cuota_pago = d.I_ObligacionAluID --and a.fch_venc = d.D_FecVencto and d.I_MatAluID = c.I_MatAluID
	inner join [dbo].[TI_ConceptoPago] e on a.concepto = e.I_ConcPagID



insert into [dbo].[TR_ObligacionAluDet] (I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, B_Mora)
select d.I_ObligacionAluID, e.I_ConcPagID, a.monto, a.pagado, D_FecVencto, null, null, 1, 0, 0
from BD_OCEF_TemporalPagos.euded.ec_det a
	inner join BD_OCEF_TemporalPagos.euded.ec_obl b on a.cod_alu = b.cod_alu and a.cod_rc = b.cod_rc and a.ano = b.ano and a.fch_venc = b.fch_venc
	inner join TC_MatriculaAlumno c on a.cod_alu = c.C_CodAlu and a.cod_rc = c.C_CodRc and a.ano = c.I_Anio
	inner join [dbo].[TR_ObligacionAluCab] d on b.cuota_pago = d.I_ObligacionAluID --and a.fch_venc = d.D_FecVencto and d.I_MatAluID = c.I_MatAluID
	inner join [dbo].[TI_ConceptoPago] e on a.concepto = e.I_ConcPagID







select * from TR_PagoBanco


select distinct len(cast(documento as varchar(max))) from BD_OCEF_TemporalPagos.eupg.ec_det

select * from BD_OCEF_TemporalPagos.eupg.ec_det where len(cast(documento as varchar(max)))  = 1025

select * from TC_CatalogoOpcion
select * from TC_CuentaDeposito
select * from TC_CuentaDeposito_CategoriaPago

select * from TC_CategoriaPago
select *  from TC_Parametro 

select * from TC_CatalogoOpcion where I_ParametroID = 8
select * from TR_ObligacionAluCab where I_ProcesoID < 498


select * from TC_Proceso where I_Anio = 2020



select * from [TR_ObligacionAluDet]

alter table [dbo].[TR_ObligacionAluDet] 
alter column [T_DescDocumento] varchar(max)


select * from TR_ObligacionAluDet where I_ObligacionAluID = 96328