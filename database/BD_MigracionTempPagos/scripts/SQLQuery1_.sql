
declare @B_Resultado  bit,
		@I_ProcedenciaID	tinyint = 3,
		@T_SchemaDB			varchar(20) = 'euded',
		@T_Codigo_bnc		varchar(250) = '''0658'', ''0685'', ''0687'', ''0688'', ''0689'', ''0690'', ''0691'', ''0692''',
		@T_Message			nvarchar(4000)
exec USP_IU_CopiarTablaCuotaDePago @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go

declare @B_Resultado  bit,
		@I_ProcedenciaID	tinyint = 2,
		@T_SchemaDB			varchar(20) = 'eupg',
		@T_Codigo_bnc		varchar(250) = '''0670'', ''0671'', ''0672'', ''0673'', ''0674'', ''0675'',
										   ''0676'', ''0677'', ''0678'', ''0679'', ''0680'', ''0681'',
										   ''0682'', ''0683'', ''0695'', ''0696'', ''0697'', ''0698''',
		@T_Message			nvarchar(4000)
exec USP_IU_CopiarTablaCuotaDePago @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO


declare @B_Resultado  bit,
		@I_ProcedenciaID	tinyint = 1,
		@T_SchemaDB			varchar(20) = 'pregrado',
		@T_Codigo_bnc		varchar(250) = '''0635'', ''0636'', ''0637'', ''0638'', ''0639''',
		@T_Message			nvarchar(4000)
exec USP_IU_CopiarTablaCuotaDePago @I_ProcedenciaID, @T_SchemaDB, @T_Codigo_bnc, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje


--truncate table tr_cp_des


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarRepetidosCuotaDePago @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 2,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarRepetidosCuotaDePago @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 3,
		@T_Message	  nvarchar(4000)
exec USP_U_MarcarRepetidosCuotaDePago @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO




declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 3,
		@T_SchemaDB		 varchar(20) = 'euded',
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarAnioPeriodoCuotaPago @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 2,
		@T_SchemaDB		 varchar(20) = 'eupg',
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarAnioPeriodoCuotaPago @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go

declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_SchemaDB		 varchar(20) = 'pregrado',
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarAnioPeriodoCuotaPago @I_ProcedenciaID, @T_SchemaDB, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO


declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 1,
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarCategoriaCuotaPago  @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 2,
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarCategoriaCuotaPago  @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare @B_Resultado  bit,
		@I_ProcedenciaID tinyint = 3,
		@T_Message	  nvarchar(4000)
exec USP_U_AsignarCategoriaCuotaPago  @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
go


declare	@B_Resultado  bit, 
			@I_ProcesoID int = NULL,
			@I_AnioIni int = NULL, 
			@I_AnioFin int = NULL,
			@I_ProcedenciaID tinyint = 1,
			@T_Message nvarchar(4000)
exec USP_IU_MigrarDataCuotaDePagoCtasPorCobrar @I_ProcesoID, @I_AnioIni, @I_AnioFin, @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare	@B_Resultado  bit, 
			@I_ProcesoID int = NULL,
			@I_AnioIni int = NULL, 
			@I_AnioFin int = NULL,
			@I_ProcedenciaID tinyint = 2,
			@T_Message nvarchar(4000)
exec USP_IU_MigrarDataCuotaDePagoCtasPorCobrar @I_ProcesoID, @I_AnioIni, @I_AnioFin, @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO

declare	@B_Resultado  bit, 
			@I_ProcesoID int = NULL,
			@I_AnioIni int = NULL, 
			@I_AnioFin int = NULL,
			@I_ProcedenciaID tinyint = 3,
			@T_Message nvarchar(4000)
exec USP_IU_MigrarDataCuotaDePagoCtasPorCobrar @I_ProcesoID, @I_AnioIni, @I_AnioFin, @I_ProcedenciaID, @B_Resultado output, @T_Message output
select @B_Resultado as resultado, @T_Message as mensaje
GO







SELECT count(*) FROM BD_OCEF_TemporalPagos.eupg.ec_det det
				LEFT JOIN TR_Ec_Obl obl ON det.cod_rc = obl.cod_rc AND det.cod_alu = obl.cod_alu 
						AND det.ano = obl.ano AND det.p = obl.p AND det.cuota_pago = obl.cuota_pago 
						AND det.fch_venc = obl.fch_venc AND det.pagado = obl.Pagado
						AND obl.I_ProcedenciaID = 2

SELECT obl.*, det.* FROM BD_OCEF_TemporalPagos.eupg.ec_det det
							   LEFT JOIN TR_Ec_Obl obl ON det.cod_rc = obl.cod_rc AND det.cod_alu = obl.cod_alu 
										AND det.ano = obl.ano AND det.p = obl.p AND det.cuota_pago = obl.cuota_pago 
										AND det.fch_venc = obl.fch_venc AND det.pagado = obl.Pagado
										AND obl.I_ProcedenciaID = 2
					WHERE det.ano BETWEEN '2014' AND '2014'


SELECT obl.I_RowID, det.* 
FROM BD_OCEF_TemporalPagos.eupg.ec_det det
	 LEFT JOIN (SELECT I_RowID, obl2.* FROM TR_Ec_Obl obl1 
									  INNER JOIN (SELECT Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado, I_ProcedenciaID
													FROM TR_Ec_Obl WHERE  I_ProcedenciaID = 2 
												  GROUP BY  I_ProcedenciaID, Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, Pagado
												  HAVING count(*) = 1
												 ) obl2 ON obl1.Ano = obl2.Ano AND obl1.P = obl2.P AND obl1.Cod_alu = obl2.Cod_alu
														   AND obl1.Cod_rc = obl2.Cod_rc AND obl1.Cuota_pago = obl2.Cuota_pago 
														   AND obl1.Fch_venc = obl2.Fch_venc AND obl1.Pagado = obl2.Pagado 
														   AND obl1.I_ProcedenciaID = obl2.I_ProcedenciaID
				) obl ON det.cod_rc = obl.cod_rc AND det.cod_alu = obl.cod_alu 
						AND det.ano = obl.ano AND det.p = obl.p AND det.cuota_pago = obl.cuota_pago 
						AND det.fch_venc = obl.fch_venc AND det.pagado = obl.Pagado
WHERE det.ano BETWEEN '2014' AND '2014'
and det.cod_alu = '2014326491'
and det.cuota_pago = '286'


select distinct(ano) from TR_Ec_Obl

select * from BD_OCEF_TemporalPagos.eupg.ec_obl where cod_alu = '2013310037' and ano = '2014' 

select count(*) from TR_Ec_Obl where I_ProcedenciaID = 2 and Ano = '2014'

TRUNCATE TABLE TR_EC_DET

SELECT obl.*, det.* FROM BD_OCEF_TemporalPagos.eupg.ec_det det
							   LEFT JOIN TR_Ec_Obl obl ON det.cod_rc = obl.cod_rc AND det.cod_alu = obl.cod_alu AND det.ano = obl.ano 
													  AND det.p = obl.p AND det.cuota_pago = obl.cuota_pago AND det.fch_venc = obl.fch_venc 
													  AND obl.I_ProcedenciaID = 2
						where det.cod_alu = '2009316686'

select * from BD_OCEF_TemporalPagos.eupg.cp_des where cuota_pago = 162
select * from BD_OCEF_TemporalPagos.eupg.ec_obl where cuota_pago = 162 and cod_alu = '2009316686'
select * from BD_OCEF_TemporalPagos.eupg.ec_obl where cod_alu = '2009316686'
select * from BD_OCEF_TemporalPagos.eupg.ec_det where cod_alu = '2009316686'

select count(*) from TR_Ec_Obl where I_ProcedenciaID = 2
select count(*) from BD_OCEF_TemporalPagos.eupg.ec_obl

select count(*) from TR_Ec_Det
select count(*) from BD_OCEF_TemporalPagos.eupg.ec_det 
WHERE ano BETWEEN '2014' AND '2014'
and cod_alu = '2014326491'
and cuota_pago = '286'

select * from BD_OCEF_TemporalPagos.eupg.ec_det 
WHERE ano BETWEEN '2014' AND '2014'
and cod_alu = '2014326491'
and cuota_pago = '286'

select * from TR_Ec_Obl where cod_alu = '2013335513' and ano = '2014' 
select * from BD_OCEF_TemporalPagos.eupg.ec_obl where cod_alu = '2013335513' and ano = '2014' 



select Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado, I_ProcedenciaID, count(*) 
from TR_Ec_Obl
WHERE
I_ProcedenciaID = 2 --and ano BETWEEN '2014' AND '2014'
group by I_ProcedenciaID, Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado
having count(*) = 1

select Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado, count(*) 
from TR_Ec_Obl
WHERE
I_ProcedenciaID = 2 --and ano BETWEEN '2014' AND '2014'
group by Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado
having count(*) > 1



--MERGE INTO BD_OCEF_TemporalPagos.dbo.alumnos AS TRG
--USING dbo.walter AS SRC
--   ON SRC.c_codalu	 = TRG.C_CODALU 
--	  AND SRC.c_rccod	 = TRG.C_RCCOD 
--	  AND SRC.c_anioingr = TRG.C_ANIOINGR
--	  AND SRC.c_codmodin = TRG.C_CODMODIN
--WHEN MATCHED THEN
--	UPDATE SET TRG.T_APEPATER	= SRC.T_APEPATER	
--			 , TRG.T_APEMATER	= SRC.T_APEMATER	
--			 , TRG.T_NOMBRE		= SRC.T_NOMBRE		
--			 , TRG.C_NUMDNI		= SRC.C_NUMDNI		
--			 , TRG.C_CODTIPDO	= SRC.C_CODTIPDO	
--			 , TRG.D_FECNAC		= SRC.D_FECNAC		
--			 , TRG.C_SEXO		= SRC.C_SEXO		
--WHEN NOT MATCHED THEN
--	INSERT (C_RCCOD, C_CODALU, T_APEPATER, T_APEMATER, T_NOMBRE, C_NUMDNI, C_CODTIPDO, C_CODMODIN, C_ANIOINGR, D_FECNAC, C_SEXO)
--	VALUES (SRC.C_RCCOD, SRC.C_CODALU, SRC.T_APEPATER, SRC.T_APEMATER, SRC.T_NOMBRE, SRC.C_NUMDNI, SRC.C_CODTIPDO, SRC.C_CODMODIN, SRC.C_ANIOINGR, SRC.D_FECNAC, SRC.C_SEXO);


select count(*) from euded.cp_des
select count(*) from euded.cp_pri
select count(*) from euded.ec_alu
select count(*) from euded.ec_det
select count(*) from euded.ec_nro
select count(*) from euded.ec_obl
select count(*) from euded.ec_pri

select count(*) from eupg.cp_des
select count(*) from eupg.cp_pri
select count(*) from eupg.ec_alu
select count(*) from eupg.ec_det
select count(*) from eupg.ec_nro
select count(*) from eupg.ec_obl
select count(*) from eupg.ec_pri

select count(*) from pregrado.cp_des
select count(*) from pregrado.cp_pri
select count(*) from pregrado.ec_alu
select count(*) from pregrado.ec_det
select count(*) from pregrado.ec_nro
select count(*) from pregrado.ec_obl
select count(*) from pregrado.ec_pri

select codigo_bnc, *
from BD_OCEF_TemporalPagos.pregrado.cp_des
where codigo_bnc IN (select distinct(codigo_bnc) from BD_OCEF_TemporalPagos.pregrado.cp_des)
order by 1 


SELECT * FROM BD_OCEF_TemporalPagos.euded.ec_obl where cuota_pago 
in (
'0689',
'0690',
'0691',
'0692')

select * from BD_OCEF_TemporalPagos.dbo.alumnos

--PREGRADO: 0635, 0636, 0637, 0638, 0639
--EUDED: 0658, 0685, 0687, 0688
--PROLICE: 0689, 0690
--PROCUNED: 0691, 0692
--EUPG: 0670, 0671, 0672, 0673, 0674, 0675, 0676, 0677, 0678, 0679, 0680, 
--		0681, 0682, 0683, 0695, 0696, 0697, 0698

select cuota_pago, I_MatAluID, 'PEN', Monto, Fch_venc, Pagado, 1, 0, getdate(), null, null, 5, I_RowID, 1
from [BD_OCEF_MigracionTP].[dbo].[TR_Ec_Obl] a
	 inner join TC_MatriculaAlumno m on a.Cod_alu = m.C_CodAlu and a.Cod_rc = m.C_CodRc
where a.Ano in ('2020', '2021', '2012') and a.I_ProcedenciaID = 2


INSERT INTO [dbo].[TR_ObligacionAluDet](I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod, B_Mora, I_MigracionTablaID, I_MigracionRowID, B_Migrado)
select c.I_ObligacionAluID,  Concepto, a.Monto, a.Pagado, a.Fch_venc, null, Documento , 1, 0, null, getdate(), null, null, 0, 4, A.I_RowID, 1
from [BD_OCEF_MigracionTP].[dbo].[TR_Ec_Det] a
	 inner join [BD_OCEF_MigracionTP].[dbo].[TR_Ec_Obl] b on a.Cod_alu = b.Cod_alu and a.Cod_rc = b.Cod_rc and a.Ano = b.Ano 
				and a.p = b.P and a.Cuota_pago = b.Cuota_pago
	 inner join [TR_ObligacionAluCab] c on b.I_RowID = c.I_MigracionRowID --and b.I_ProcedenciaID = 1 
where a.Ano in ('2020', '2021', '2012')


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



SELECT COUNT(I_PersonaID) FROM  ##TEMP_AlumnoPersona
select count(*) from (SELECT distinct I_PersonaID FROM  ##TEMP_AlumnoPersona) tbl

select I_PersonaID, COUNT(I_PersonaID) 'repetidos' FROM  ##TEMP_AlumnoPersona 
group by I_PersonaID
having COUNT(I_PersonaID) > 1

select * from  ##TEMP_AlumnoPersona 
where I_PersonaId in (
18131
,158
,2242
,525
,2463
,1313
,5931)
order by 1


SELECT A.* FROM ##TEMP_AlumnoPersona AP 
				INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1
where I_PersonaId in (
18131
,158
,2242
,525
,2463
,1313
,5931)
order by 1

SELECT DISTINCT AP.I_PersonaID, A.C_NumDNI, A.C_CodTipDoc, A.T_ApePaterno COLLATE Modern_Spanish_CI_AI
, A.T_ApeMaterno COLLATE Modern_Spanish_CI_AI
,  A.T_Nombre COLLATE Modern_Spanish_CI_AI
, A.D_FecNac, A.C_Sexo
 FROM ##TEMP_AlumnoPersona AP 
				INNER JOIN TR_Alumnos A ON AP.I_RowID = A.I_RowID AND A.B_Migrable = 1
where AP.I_PersonaID in (
18131
,158
,2242
,525
,2463
,1313
,5931)
order by 1

SELECT * FROM TR_Alumnos WHERE I_RowID IN (77324
,272405)

SELECT COUNT(C_NumDNI) FROM TR_Alumnos 
SELECT DISTINCT COUNT(C_NumDNI) FROM TR_Alumnos 
SELECT COUNT(C_NumDNI) FROM (SELECT DISTINCT C_NumDNI FROM TR_Alumnos ) TBL
SELECT COUNT(*) FROM (SELECT C_NumDNI, C_Sexo FROM TR_Alumnos WHERE C_NumDNI IS NOT NULL) TBL 
SELECT COUNT(*) FROM (SELECT DISTINCT C_NumDNI, C_Sexo FROM TR_Alumnos  WHERE C_NumDNI IS NOT NULL) TBL

select * from tr_alumnos where c_numdni = '70063617'

SELECT C_NumDNI, COUNT(*) FROM TR_Alumnos
WHERE C_NumDNI IS NOT NULL
GROUP BY C_NumDNI
HAVING COUNT(*) > 1
ORDER BY 1

SELECT C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI
	, T_Nombre COLLATE Modern_Spanish_CI_AI, COUNT(*) 
FROM TR_Alumnos
WHERE C_NumDNI IS NOT NULL
GROUP BY C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI, T_Nombre COLLATE Modern_Spanish_CI_AI
HAVING COUNT(*) > 1

SELECT * FROM TR_Alumnos WHERE C_NumDNI IN (
SELECT C_NumDNI FROM (SELECT C_NumDNI, COUNT(*) R FROM TR_Alumnos
WHERE C_NumDNI IS NOT NULL
GROUP BY C_NumDNI
HAVING COUNT(*) > 1) T1
WHERE EXISTS (
SELECT C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI
	, T_Nombre COLLATE Modern_Spanish_CI_AI, COUNT(*) R
FROM TR_Alumnos
WHERE C_NumDNI IS NOT NULL AND T1.C_NumDNI = C_NumDNI
GROUP BY C_NumDNI, T_ApePaterno COLLATE Modern_Spanish_CI_AI, T_ApeMaterno COLLATE Modern_Spanish_CI_AI, T_Nombre COLLATE Modern_Spanish_CI_AI
HAVING COUNT(*) > 1)
)
ORDER BY C_NumDNI


SELECT C_NumDNI, C_Sexo, COUNT(*) FROM TR_Alumnos
WHERE C_NumDNI IS NOT NULL
GROUP BY C_NumDNI, C_Sexo
HAVING COUNT(*) > 1

select count(*) from (select distinct cuota_pago from TR_Ec_Obl where I_ProcedenciaID = 3) as obl
select count(*) from (select distinct cuota_pago from TR_Ec_Det where I_ProcedenciaID = 3) as det 

select distinct cuota_pago from TR_Ec_Det where I_ProcedenciaID = 3 
and not exists (select * from TR_Ec_Obl where I_ProcedenciaID = 3 and Cuota_pago = TR_Ec_Det.Cuota_pago)
select top 10 * from TR_Ec_Det
select distinct I_ProcedenciaID from TR_Cp_Des
select * from TR_Cp_Des  where  Cuota_pago in (
'0'
,'195'
,'129'
,'21'
,'196'
,'254'
,'231'
,'463'
,'54'
,'237')

select * from BD_OCEF_TemporalPagos.pregrado.cp_des where cuota_pago = '54'


select count(*) from TR_Ec_Det where I_ProcedenciaID = 3

select distinct cuota_pago 
from TR_Ec_Obl obl
	inner join TR_Ec_Det det ON obl.Cuota_pago = det.Cuota_pago and obl.Cod_rc = det.Cod_rc and obl.Cod_alu = det.Cod_alu 
 where I_ProcedenciaID = 3

 select * from BD_OCEF_CtasPorCobrar..TI_ConceptoPago where I_ConcPagID = 7643




 truncate table tr_ec_obl


select * from BD_OCEF_TemporalPagos.eupg.ec_det
where concepto in
(select id_cp from  BD_OCEF_TemporalPagos.eupg.cp_pri where descripcio like '%mora%')

select top 1000 * from BD_OCEF_TemporalPagos.pregrado.ec_det where concepto = '7643'

SELECT cuota_pago, p, ano, fch_venc, cod_alu, cod_rc, monto, pagado FROM BD_OCEF_TemporalPagos.euded.ec_det


select distinct concepto, ano from BD_OCEF_TemporalPagos.eupg.ec_det
where concepto in
(select id_cp from  BD_OCEF_TemporalPagos.eupg.cp_pri where descripcio like '%mora%')
order by 2 desc


