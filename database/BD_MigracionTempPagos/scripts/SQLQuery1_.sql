SELECT DISTINCT cuota_pago, concepto FROM EUDED_ec_det WHERE eliminado = 1
ORDER BY concepto


select DISTINCT EUDED_cp_pri.cuota_pago, EUDED_ec_det.cuota_pago, ID_CP, concepto, descripcio  
from EUDED_ec_det 
INNER JOIN EUDED_cp_pri ON id_cp = concepto
WHERE EUDED_ec_det.eliminado = 1
ORDER BY id_cp

select DISTINCT EUDED_cp_pri.cuota_pago, EUDED_ec_det.cuota_pago, ID_CP, descripcio  
from EUDED_ec_det 
INNER JOIN EUDED_cp_pri ON id_cp = concepto AND EUDED_cp_pri.cuota_pago = EUDED_ec_det.cuota_pago
WHERE EUDED_ec_det.eliminado = 1
ORDER BY id_cp


select DISTINCT tipo_oblig
from EUDED_ec_det 

select  *from EUDED_cp_des where n_cta_cte = '110-01-0414438'
select * from EUDED_ec_det where tipo_oblig = 0
select * from EUDED_cp_des where cuota_pago = 88
select * from ec_det where TIPO_OBLIG <> 'T'

--[dbo].[TR_PagoBanco]
--I_PagoBancoID, I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, 
--T_LugarPago, B_Anulado, I_UsuarioCre, D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, 
--I_CtaDepositoID, I_InteresMora, T_MotivoCoreccion, I_UsuarioMod, D_FecMod

SELECT 1 AS I_EntidadFinanID, nro_recibo AS C_CodOperacion, cod_alu AS C_CodDepositante, '' AS T_NomDepositante, 
		nro_recibo AS C_Referencia, fch_pago AS D_FecPago, IIF(cantidad = 0, 1, CAST(cantidad as int)) AS I_Cantidad, 
		'PEN' AS C_Moneda, monto AS I_MontoPago, id_lug_pag AS T_LugarPago, 0 AS B_Anulado, NULL AS I_UsuarioCre, 
		GETDATE() AS D_FecCre, documento AS T_Observacion, NULL AS T_InformacionAdicional, 131 AS I_CondicionPagoID, 
		IIF (tipo_oblig = 1, 133, 134) AS I_TipoPagoID, I_CtaDepositoID
FROM dbo.EUDED_ec_det EDET
	 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso CC_CDP ON CC_CDP.I_ProcesoID = EDET.cuota_pago
WHERE eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  AND tipo_oblig = 1


--[dbo].[TRI_PagoProcesadoUnfv]
--I_PagoProcesID, I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado, D_FecCre, I_UsuarioCre, D_FecMod, I_UsuarioMod, I_ObligacionAluDetID


select distinct cantidad from EUDED_ec_det --where nro_ec = 6226
select distinct cantidad from EUPG_ec_det --where nro_ec = 6226
select * from EUPG_ec_det where cantidad = 7500
select * from EUDED_ec_det where cantidad = 0
select distinct cantidad from PRE_ec_det --where nro_ec = 6226

SELECT * FROM EUPG_ec_det
WHERE eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  AND tipo_oblig = 1
	  AND concepto = 4788

select * from EUDED_cp_des where cuota_pago = 1
select * from EUDED_cp_pri where id_cp = 4788
select * from EUPG_cp_pri where id_cp = 5134

select distinct CAST(cantidad as int) from EUPG_ec_det

select * From cp_des where CUOTA_PAGO = 439

select cp.descripcio, det.*
FROM dbo.EUDED_ec_det det
inner join EUDED_cp_des cp on cp.cuota_pago = det.cuota_pago and cp.eliminado = 0
WHERE det.eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  and concepto <> 0

select COUNT(*)
FROM dbo.EUDED_ec_det det
inner join EUDED_cp_des cp on cp.cuota_pago = det.cuota_pago and cp.eliminado = 0
WHERE det.eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  --and concepto = 0

	  select COUNT(*)
FROM dbo.EUDED_ec_det det
inner join EUDED_cp_des cp on cp.cuota_pago = det.cuota_pago and cp.eliminado = 0
WHERE det.eliminado = 0
	  AND pagado = 1
	  AND concepto_f = 1
	  and concepto = 0

select * from EUDED_cp_pri where id_cp in (4788, 4, 0)


select *
from EUDED_ec_obl 
where --pagado = 1
tipo_oblig = 1

select * from cp_pri where ID_CP = 4981
select * from alumnos where C_CODALU = '0009317166'

--select distinct cuota_pago from EUDED_ec_obl