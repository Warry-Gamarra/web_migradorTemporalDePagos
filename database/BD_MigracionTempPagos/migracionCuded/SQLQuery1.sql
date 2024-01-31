
select * from TR_Ec_Obl where I_ProcedenciaID = 1 order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) > 1

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 2

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 3

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 4

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 5

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 7

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from TR_Ec_Obl 
where I_ProcedenciaID = 3 
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) = 6


select * from BD_OCEF_TemporalPagos.euded.ec_obl 
where ano = '2011' and Cod_alu = '2008703916' and Cod_rc = 'E01' and
p = '0'  and Cuota_pago = 418
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto


select eliminado, * from BD_OCEF_TemporalPagos.euded.ec_det 
where ano = '2011' and Cod_alu = '2008703916' and Cod_rc = 'E01' and
p = '0'  and Cuota_pago = 418
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto

select * from BD_OCEF_TemporalPagos.euded.ec_obl  
where ano = '2018' and Cod_alu = '2014710778' and Cod_rc = 'E01' and
p = '2' and Cuota_pago = 454
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc--, Monto

select eliminado as elim, * from BD_OCEF_TemporalPagos.euded.ec_det  
where ano = '2018' and Cod_alu = '2014710778' and Cod_rc = 'E01' and
p = '2' and Cuota_pago = 454
order by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, eliminado

select * from TR_Cp_Des where Cuota_pago = 330
select * from BD_OCEF_CtasPorCobrar..TC_Proceso where I_ProcesoID = 330
select * from BD_OCEF_CtasPorCobrar..TC_Proceso where I_Anio = 2016

select * from BD_OCEF_TemporalPagos.pregrado.ec_obl where cuota_pago = 330
select * from BD_OCEF_TemporalPagos.euded.ec_obl where cuota_pago = 330

select ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc, count(*) from BD_OCEF_TemporalPagos.euded.ec_obl   
group by ano, Cod_alu, Cod_rc, p, Cuota_pago, Fch_venc
having count(*) > 1




delete TI_ObservacionRegistroTabla where I_TablaID in (4, 5)
delete TR_Ec_Det
delete TR_Ec_Obl

select * from BD_OCEF_CtasPorCobrar..TR_ObligacionAluCab where I_ProcesoID = 128
select * from BD_OCEF_CtasPorCobrar..TR_ObligacionAluDet where I_ObligacionAluID = 11102393
select * from BD_OCEF_CtasPorCobrar..TRI_PagoProcesadoUnfv where I_ObligacionAluDetID = 8204239
select * from BD_OCEF_CtasPorCobrar..TRI_PagoProcesadoUnfv where I_ObligacionAluDetID = 8204240
select * from BD_OCEF_CtasPorCobrar..TR_PagoBanco where I_MigracionRowID is not null
select * from BD_OCEF_CtasPorCobrar..TR_PagoBanco where I_MigracionRowID = 26222465

select * from TR_Ec_Det where I_RowID = 26222486
select * from TR_Ec_Det where I_RowID = 26222465


