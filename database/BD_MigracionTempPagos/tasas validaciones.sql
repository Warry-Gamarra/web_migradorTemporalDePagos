use BD_OCEF_TemporalTasas
go

--- conceptos de pago no eliminados con cod_tasa (clasif_5) repetido
select clasific_5, COUNT(id_cp) from cp_pri
where eliminado = 0
     and cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)
group by clasific_5 
having COUNT(id_cp) > 1


--- conceptos de pago no eliminados con cod_tasa (clasif_5) en blanco 
select * from cp_pri
where eliminado = 0
     and cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)
	 and clasific_5 = ''


-- conceptos de pago con cod_tasa (clasif_5) repetido detalle
select * from cp_pri where clasific_5 in (
'80525','80729','80749','81036','81258','81323','81325','81375''81410','81460',
'81515','81516','81540','81542','81558','81578','81583','81596','81601','81640',
'81643','81744','81805','81843','81850','81866','81929','82037','82121','82122','82171')
order by clasific_5

-- conceptos de pago con cod_tasa (clasif_5) ecistente en ctas por cobrar
l
select cp_pri.* from cp_pri 
inner join BD_OCEF_CtasPorCobrar..TI_TasaUnfv ctas on cp_pri.clasific_5 = ctas.C_CodTasa and cp_pri.monto = ctas.M_Monto
where eliminado = 0
order by clasific_5
