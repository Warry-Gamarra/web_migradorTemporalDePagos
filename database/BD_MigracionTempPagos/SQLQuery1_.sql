select * from BD_UNFV_Repositorio.dbo.TC_Alumno where C_CodAlu = '2016017156'
SELECT * FROM BD_UNFV_Repositorio.dbo.TC_Persona where I_PersonaID = 14267
select * from BD_OCEF_MigracionTP.dbo.TR_Alumnos where C_CodAlu = '2005022777'
truncate table  BD_OCEF_MigracionTP.dbo.TR_Ec_Pri
select * from BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv where I_ObligacionAluDetID = 382 
select * from BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet where I_ObligacionAluDetID = 149424
SELECT * FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco where I_ProcesoIDArchivo is null

select * from BD_OCEF_MigracionTP.dbo.TR_Ec_Det WHERE Concepto = 4788 and Ano  = 2011
SELECT * FROM BD_OCEF_CtasPorCobrar.dbo.TC_EntidadFinanciera
SELECT * FROM BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco
SELECT * FROM BD_OCEF_CtasPorCobrar.dbo.TC_CatalogoOpcion WHERE I_ParametroID = 10

select * from  BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet  where B_Pagado = 0 and B_Eliminado = 0

--2015321838	
			SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(ISNULL(P.C_NumDNI, TA.C_NumDNI),'�', ' '))) AS C_NumDNI, 
					ISNULL(P.C_CodTipDoc, TA.C_CodTipDoc) as C_CodTipDoc, ISNULL(P.T_ApePaterno, TA.T_ApePaterno) as T_ApePaterno, 
					ISNULL(P.T_ApeMaterno, TA.T_ApeMaterno) as T_ApeMaterno, ISNULL(P.T_Nombre, TA.T_Nombre) as T_Nombre, 
					IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo) AS C_Sexo, TA.C_CodAlu, TA.C_RcCod, TA.C_CodModIng, TA.I_RowID, 
					ISNULL(A.C_AnioIngreso, TA.C_AnioIngreso) as C_AnioIngreso, ISNULL(P.D_FecNac, TA.D_FecNac) AS D_FecNac
			FROM	BD_UNFV_Repositorio.dbo.TC_Persona P
					INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON A.I_PersonaID = P.I_PersonaID 
					RIGHT JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod 
			WHERE   TA.B_Migrable = 1
					AND TA.I_ProcedenciaID = 3
					AND P.B_Eliminado = 0
					AND A.B_Eliminado = 0

select C_AnioIngreso, cofrom BD_OCEF_MigracionTP.dbo.TR_Alumnos where I_ProcedenciaID = 1 order by 1

SELECT *  FROM BD_UNFV_Repositorio.dbo.TC_Alumno
select COUNT(*) from BD_OCEF_TemporalPagos.euded.ec_pri WHERE ano = 2011
SELECT * FROM BD_OCEF_MigracionTP.dbo.TR_Ec_Pri where Ano <> 2011
select COUNT(*) from BD_OCEF_MigracionTP.dbo.TR_Ec_Pri where Ano  = 2011
select distinct COUNT(nro_ec) from BD_OCEF_MigracionTP.dbo.TR_Ec_Pri where Ano  = 2011
select * from BD_OCEF_TemporalPagos.euded.ec_pri order by cod_alu, nro_ec
select * from BD_OCEF_CtasPorCobrar.dbo.TRI_PagoProcesadoUnfv

select * from BD_OCEF_TemporalPagos.euded.ec_obl where cod_alu = '1999700465' and cod_rc =  'E01' and p = 2 and ano = 2005
select * from BD_OCEF_TemporalPagos.euded.ec_det WHERE nro_ec = 49 AND eliminado = 0

select * from BD_OCEF_TemporalPagos.dbo.alumnos where C_CodAlu = '2019232117'
select * from BD_OCEF_MigracionTP.dbo.TR_Alumnos where C_CodAlu = '2019232117'

select distinct COUNT(nro_ec) from BD_OCEF_TemporalPagos.euded.ec_pri WHERE  ano = 2011

SELECT COUNT(*) FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno

SELECT COUNT(*) FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno WHERE B_Migrado = 1
SELECT COUNT(*) FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno WHERE B_Migrado = 0

SELECT  COUNT(*) FROM BD_OCEF_MigracionTP.dbo.TR_Alumnos
SELECT  COUNT(*) FROM BD_OCEF_MigracionTP.dbo.TR_Alumnos WHERE B_Migrable = 1

select Id_cp  from BD_OCEF_MigracionTP..TR_Cp_Pri where Descripcio like '%Mora_%'

select * from BD_OCEF_TemporalPagos.euded.ec_det WHERE ano = 2011

select * from BD_OCEF_CtasPorCobrar.dbo.VW_DetalleObligaciones where B_Mora = 1 

SELECT M.C_CodAlu, M.C_CodRc, I_Anio, I_Periodo, COUNT(C.I_ObligacionAluID) FROM TR_ObligacionAluCab C
		INNER JOIN TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID

WHERE M.B_Migrado = 1
GROUP BY M.C_CodAlu, M.C_CodRc, I_Anio, I_Periodo

SELECT * FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno WHERE B_Migrado = 1


SELECT COUNT(*) FROM TR_ObligacionAluCab C
INNER JOIN TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID
WHERE M.B_Migrado = 1 --  M.B_Migrado = 1 AND C.B_Migrado = 1


select * from BD_OCEF_TemporalPagos.eupg.ec_det where  nro_ec = 23161 order by cuota_pago
SELECT * FROM BD_OCEF_TemporalPagos.eupg.ec_pri WHERE nro_ec = 23161 
select * from BD_OCEF_TemporalPagos.eupg.ec_det where cod_alu = '2008311297' and cod_rc = 'M21' and ano = '2009' and p = 1 and eliminado = 0 order by cuota_pago
select * from BD_OCEF_TemporalPagos.eupg.ec_det where concepto = 4788 and cod_alu = '2008311297' and cod_rc = 'M21' and ano = '2009' and p = 1 and eliminado = 0 order by cuota_pago
select * from BD_OCEF_TemporalPagos.eupg.ec_obl where cod_alu = '2008311297' and cod_rc = 'M21' and ano = '2009' and p = 1 order by cuota_pago



SELECT COUNT(*) FROM TR_ObligacionAluCab C
INNER JOIN TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID
WHERE C.B_Migrado = 1 and  M.B_Migrado = 1 --AND C.B_Migrado = 1


SELECT COUNT(*) FROM TR_ObligacionAluCab C
INNER JOIN TR_ObligacionAluDet D ON C.I_ObligacionAluID = D.I_ObligacionAluID
WHERE C.B_Migrado = 1

select COUNT(*) 
FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab cabecera_obligaciones
		 LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet detalle_obligaciones 
				   ON cabecera_obligaciones.I_ObligacionAluID = detalle_obligaciones.I_ObligacionAluID
		 WHERE cabecera_obligaciones.B_Migrado = 1 AND detalle_obligaciones.I_ObligacionAluID IS NULL


SELECT m.* FROM TR_ObligacionAluCab C
INNER JOIN TC_MatriculaAlumno M ON C.I_MatAluID = M.I_MatAluID
WHERE C.B_Migrado = 1 and  M.B_Migrado = 0



select * from BD_OCEF_MigracionTP.dbo.TR_Alumnos a
inner join BD_OCEF_CtasPorCobrar..TC_MatriculaAlumno M on a.C_RcCod = M.C_CodRc and a.C_CodAlu = M.C_CodAlu
INNER JOIN TR_ObligacionAluCab C ON C.I_MatAluID = M.I_MatAluID
where M.B_Migrado = 0 and C.B_Migrado = 1 

SELECT * FROM TR_ObligacionAluDet C





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




select *  from TR_Cp_Pri

select *  from TR_Cp_Pri
WHERE B_Migrable = 0

select * from TR_Ec_Obl where I_ProcedenciaID = 2


select count(*) from BD_OCEF_TemporalPagos.euded.ec_obl 
select count(*) from TR_Ec_obl where I_ProcedenciaID = 3

select count(*) from BD_OCEF_TemporalPagos.euded.ec_det --where concepto_f = 0
select count(*) from TR_Ec_Det where I_ProcedenciaID = 3 AND B_Removido = 1


update TR_Ec_Det set B_Removido = 0, D_FecRemovido = NULL

select top 100 * from TR_Alumnos
select * from TI_ObservacionRegistroTabla
select top 100 * from TR_Ec_Obl where B_Migrable = 0

SELECT * FROM TR_Ec_Obl WHERE ISNUMERIC(ANO) = 0 AND I_ProcedenciaID = 3
select count(*) from TR_Ec_Det where i_procedenciaid = 3 and I_OblRowID is null

SELECT * FROM TR_Ec_Obl WHERE I_ProcedenciaID = 3  and Cuota_pago = 0
select count(*) from TR_Ec_Det where i_procedenciaid = 3 and I_OblRowID is null
select count(*) from TR_Ec_Det where i_procedenciaid = 3 and Cuota_pago = 0
select count(*) from BD_OCEF_TemporalPagos.euded.ec_det where Cuota_pago = 0
select count(*) from BD_OCEF_TemporalPagos.euded.ec_obl where Cuota_pago = 0
select count(*) from BD_OCEF_TemporalPagos.euded.cp_des where Cuota_pago = 0

select count(*) from TR_Ec_Det where i_procedenciaid = 3 and Eliminado = 1 and  I_OblRowID is null


select * from TR_Ec_Obl where Cuota_pago = 462 AND Ano = 2019 AND P = 1 AND Cod_alu = '2006701141'
select * from TR_Ec_Det where Cuota_pago = 462 AND Ano = 2019 AND P = 1 AND Cod_alu = '2006701141'

select count(*) from TR_Ec_Obl where i_procedenciaid = 3 

SELECT obl.I_RowID AS I_OblRowID , det.* 
FROM BD_OCEF_TemporalPagos.euded.ec_det det
	LEFT JOIN (SELECT I_RowID, obl2.* FROM TR_Ec_Obl obl1 
				INNER JOIN (SELECT Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado, I_ProcedenciaID
							FROM TR_Ec_Obl WHERE  I_ProcedenciaID = 3 
							GROUP BY  I_ProcedenciaID, Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, Pagado
							HAVING count(*) = 1
						) obl2 ON obl1.Ano = obl2.Ano AND obl1.P = obl2.P AND obl1.Cod_alu = obl2.Cod_alu
									AND obl1.Cod_rc = obl2.Cod_rc AND obl1.Cuota_pago = obl2.Cuota_pago 
									AND obl1.Fch_venc = obl2.Fch_venc AND obl1.Pagado = obl2.Pagado 
									AND obl1.I_ProcedenciaID = obl2.I_ProcedenciaID
			) obl ON det.cod_rc = obl.cod_rc AND det.cod_alu = obl.cod_alu 
						AND det.ano = obl.ano AND det.p = obl.p AND det.cuota_pago = obl.cuota_pago 
						AND det.fch_venc = obl.fch_venc AND det.pagado = obl.Pagado


select distinct TR_Ec_Det.Cuota_pago from TR_Ec_Det 
left join TR_Ec_Obl on TR_Ec_Det.Cuota_pago = TR_Ec_Obl.Cuota_pago and TR_Ec_Det.I_ProcedenciaID = TR_Ec_Obl.I_ProcedenciaID
where TR_Ec_Det.I_ProcedenciaID = 3 and TR_Ec_Obl.I_RowID is null
	
select * from TR_Cp_Des where I_ProcedenciaID = 1 and Cuota_pago
in (
0
,195
,129
,21
,196
,254
,231
,463
,54
,237)

SELECT I_RowID, obl2.* FROM TR_Ec_Obl obl1 
INNER JOIN (SELECT Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, pagado, I_ProcedenciaID
			FROM TR_Ec_Obl WHERE  I_ProcedenciaID = 3 
			GROUP BY  I_ProcedenciaID, Ano, P, Cod_alu, Cod_rc, Cuota_pago, Fch_venc, Pagado
			HAVING count(*) = 1
) obl2 ON obl1.Ano = obl2.Ano AND obl1.P = obl2.P AND obl1.Cod_alu = obl2.Cod_alu
						AND obl1.Cod_rc = obl2.Cod_rc AND obl1.Cuota_pago = obl2.Cuota_pago 
						AND obl1.Fch_venc = obl2.Fch_venc AND obl1.Pagado = obl2.Pagado 
						AND obl1.I_ProcedenciaID = obl2.I_ProcedenciaID

select distinct i_Anio from BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno
select distinct Ano from TR_Ec_Obl where I_ProcedenciaID = 3

		SELECT * 
		INTO #Numeric_Year_Ec_Obl
		FROM TR_Ec_Obl
		WHERE ISNUMERIC(ANO) = 1
			  AND I_ProcedenciaID = 3

		SELECT ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as TempRowID, obl.I_RowID, 
			   obl.Ano, mat.I_Anio, obl.P, obl.I_Periodo, obl.Cod_alu, obl.Cod_rc, obl.Cuota_pago, obl.Tipo_oblig, obl.Fch_venc, obl.Monto, obl.Pagado, mat.I_MatAluID
		FROM #Numeric_Year_Ec_Obl obl
			 INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON 
						obl.cod_alu = mat.C_CodAlu AND obl.cod_rc = mat.C_CodRc 
						AND CAST(obl.ano AS int) = mat.I_Anio
						AND obl.I_Periodo = mat.I_Periodo
		WHERE obl.I_ProcedenciaID = 3
			  AND (CAST(obl.Ano AS int) BETWEEN 0 AND 3000)
			  AND B_Migrable = 1;


SELECT DISTINCT Cuota_pago FROM TR_Ec_Obl WHERE Cuota_pago NOT IN (SELECT I_ProcesoID FROM BD_OCEF_CtasPorCobrar..TC_Proceso) AND I_ProcedenciaID =  3 and B_Migrable = 1

select * from TR_Ec_Obl where B_Migrable = 1


SELECT * FROM TR_ec_obl WHERE Cuota_pago IN (229
,26
,133
,142
,128
,134) 


SELECT * FROM TR_Cp_Des WHERE Cuota_pago IN (229
,26
,133
,142
,128
,134) 


SELECT * FROM TC_CatalogoTabla


declare @I_ProcedenciaID tinyint = 3,
		@I_ProcesoID int = null, 
		@I_AnioIni	 int = null, 
		@I_AnioFin	 int = null 

DECLARE @I_RowID  int

SET @I_AnioIni = (SELECT ISNULL(@I_AnioIni, 0))
SET @I_AnioFin = (SELECT ISNULL(@I_AnioFin, 3000))

SET @I_RowID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet')

SELECT det.B_Migrable, @I_RowID + ROW_NUMBER() OVER (ORDER BY det.I_OblRowID ASC) as OblDetAluID, ROW_NUMBER() OVER (ORDER BY det.I_OblRowID ASC) as TempRowID, I_OblRowID, Concepto, det.Monto, det.Pagado, 
		det.Fch_venc, CASE WHEN CAST(Documento as varchar(max)) IS NULL THEN NULL ELSE 138 END AS I_TipoDocumento, CAST(Documento as varchar(max)) AS T_DescDocumento, 
		1 AS Habilitado, Eliminado, 1 as I_UsuarioCre, getdate() as D_FecCre, 0 AS Mora, det.I_RowID
--INTO #tmp_det_migra
FROM  TR_Ec_Det det
		INNER JOIN TR_Ec_Obl obl ON det.I_OblRowID = obl.I_RowID
WHERE det.I_ProcedenciaID = @I_ProcedenciaID
		AND (det.Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
		AND (CAST(det.Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin)
		AND det.Concepto_f = 1
		AND det.B_Migrable = 1


		select count(*) from TR_Cp_Des  where B_Migrable = 1 and I_ProcedenciaID = 3
select count(*) from TR_Cp_Des  where B_Migrado = 1 and I_ProcedenciaID = 3

select * from TR_Ec_Obl
		WHERE	Cuota_pago NOT IN (SELECT Cuota_pago FROM TR_Cp_Des WHERE I_ProcedenciaID = 3)
				AND I_ProcedenciaID = 3


select DISTINCT Concepto from TR_Ec_Det where B_Migrable = 1 and I_ProcedenciaID = 3
and Concepto not in (select distinct id_cp from TR_Cp_Pri where B_Migrado = 1 and I_ProcedenciaID = 3
)

select DISTINCT Concepto from TR_Ec_Det where B_Migrable = 1 and I_ProcedenciaID = 3
and Concepto not in (select distinct id_cp from TR_Cp_Pri where B_Migrable = 1 and I_ProcedenciaID = 3
)


select DISTINCT Concepto from TR_Ec_Det where I_ProcedenciaID = 3
and Concepto not in (select distinct id_cp from TR_Cp_Pri WHERE I_ProcedenciaID = 3
)


select * from TR_Cp_Pri where Id_cp = 4788

select count(*) from TR_Ec_Det where I_ProcedenciaID = 3 and B_Migrable = 1
select count(*) from TR_Ec_Det where I_ProcedenciaID = 3 and B_Migrable = 0
select count(*) from TR_Ec_Det where I_ProcedenciaID = 3 and B_Migrable = 1
select count(*) from TR_Ec_Det where I_ProcedenciaID = 3 



SELECT * FROM TR_Ec_Det		WHERE	TIPO_OBLIG = 1 AND
				NOT EXISTS (SELECT * FROM TR_Ec_Obl b 
							WHERE	TR_Ec_Det.ANO = b.ANO 
									AND TR_Ec_Det.P = b.P
									AND TR_Ec_Det.CUOTA_PAGO = b.CUOTA_PAGO
									AND TR_Ec_Det.COD_ALU = b.COD_ALU
									AND TR_Ec_Det.COD_RC = b.COD_RC
									AND CONVERT(DATE, FCH_VENC, 102) = b.FCH_VENC
							)
				AND TR_Ec_Det.I_ProcedenciaID = 3


	SET @I_RowID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab')

	SELECT @I_RowID + ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as OblCabAluID, ROW_NUMBER() OVER (ORDER BY obl.I_RowID ASC) as TempRowID, obl.I_RowID, 
			obl.Ano, obl.P, obl.I_Periodo, obl.Cod_alu, obl.Cod_rc, obl.Cuota_pago, obl.Tipo_oblig, obl.Fch_venc, obl.Monto, obl.Pagado, mat.I_MatAluID
	--INTO #tmp_obl_migra
	FROM #Numeric_Year_Ec_Obl obl
			INNER JOIN BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno mat ON 
					obl.cod_alu = mat.C_CodAlu AND obl.cod_rc = mat.C_CodRc 
					AND CAST(obl.ano AS int) = mat.I_Anio 
					AND obl.I_Periodo = mat.I_Periodo
	WHERE obl.I_ProcedenciaID = @I_ProcedenciaID
			AND (obl.Cuota_pago = @I_ProcesoID OR @I_ProcesoID IS NULL)
			AND (CAST(obl.Ano AS int) BETWEEN @I_AnioIni AND @I_AnioFin)
			AND B_Migrable = 1;

	select * from #tmp_obl_migra


	SELECT COUNT(*) FROM TR_Ec_Obl WHERE B_Migrable = 1 AND I_ProcedenciaID = 3
		SELECT COUNT(*) FROM TR_Ec_Obl WHERE B_Migrable = 0 AND I_ProcedenciaID = 3

	SELECT * FROM TR_CP_DES WHERE B_MIGRADO = 1 AND I_ProcedenciaID = 3

	UPDATE TR_Ec_Obl SET B_Migrable = 1 WHERE I_ProcedenciaID = 3


SELECT * INTO #temp_obl_migrados FROM TR_Ec_Obl WHERE I_ProcedenciaID = 3 AND B_Migrable = 1;
SELECT * INTO #temp_det_migrados FROM TR_Ec_Det WHERE I_ProcedenciaID = 3 AND B_Migrable = 1;
	
SELECT * INTO #temp_pagos_interes_mora FROM	TR_Ec_Det WHERE Concepto = 4788		
SELECT * INTO #temp_pagos_banco FROM TR_Ec_Det WHERE Concepto = 0 AND Concepto_f = 1 AND Pagado = 1		
SELECT * INTO #temp_pagos_conceptos FROM TR_Ec_Det WHERE Pagado = 1 AND Concepto_f = 0 AND Concepto NOT IN (0, 4788)			

SELECT COUNT(*) FROM #temp_obl_migrados
SELECT COUNT(*) FROM #temp_det_migrados
SELECT COUNT(*) FROM #temp_pagos_interes_mora 
SELECT COUNT(*) FROM #temp_pagos_banco 
SELECT COUNT(*) FROM #temp_pagos_conceptos

SELECT top 100 * FROM #temp_pagos_banco order by Cod_alu 
SELECT top 100 * FROM #temp_pagos_conceptos order by Cod_alu
 
SELECT * FROM TR_Ec_Det WHERE I_OblRowID = 1044123


SELECT  distinct CASE det.Cod_cajero WHEN 'BCP' THEN 2 ELSE 1 END AS I_EntidadFinanID, det.Nro_recibo, det.Cod_alu, null AS T_NomDepositante, det.Fch_pago, 
		det.Cantidad, det.Monto, det.Id_lug_pag, det.Eliminado, null AS T_Observacion, cast(det.Documento as varchar(max)) AS Documento, cdp.I_CtaDepositoID,
		det.Fch_ec, 131 AS I_CondicionPagoID, 133 AS I_TipoPagoID, ISNULL(mora.Monto, 0) AS Interes_moratorio, det.I_RowID
FROM	#temp_pagos_banco det
		LEFT JOIN  #temp_pagos_interes_mora mora ON det.Ano = mora.Ano AND det.P = mora.P AND det.Cuota_pago = mora.Cuota_pago 
													AND det.Cod_Alu = mora.Cod_Alu AND det.Cod_rc = mora.Cod_rc
		LEFT JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID


-- I_PagoProcesID, I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado,
-- D_FecCre, I_UsuarioCre, D_FecMod, I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID
DECLARE @I_MigracionTablaDetID tinyint = 4

SELECT  distinct pagos.I_PagoBancoID, cdp.I_CtaDepositoID, NULL AS I_TasaUnfvID, det.Monto, 0 AS I_SaldoAPagar, 0 AS I_PagoDemas, 0 AS B_PagoDemas, NULL AS N_NroSIAF, det.Eliminado,
		NULL AS D_FecCre, NULL AS I_UsuarioCre, NULL AS D_FecMod, NULL AS I_UsuarioMod, alu_det.I_ObligacionAluDetID AS I_ObligacionAluDetID, NULL AS B_Migrado, @I_MigracionTablaDetID, 
		det.I_RowID AS I_MigracionRowID, det.cuota_pago, cdp.I_ProcesoID, DET.B_Migrable
FROM	#temp_pagos_conceptos det
		INNER JOIN #temp_pagos_banco pagos_det ON det.I_OblRowID = pagos_det.I_OblRowID
		LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet alu_det ON det.I_RowID = alu_det.I_MigracionRowID
		LEFT JOIN  BD_OCEF_CtasPorCobrar.dbo.TR_PagoBanco pagos ON pagos_det.I_RowID = pagos.I_MigracionRowID -- AND pagos.I_MigracionTablaID = 5
		LEFT JOIN  BD_OCEF_CtasPorCobrar.dbo.TI_CtaDepo_Proceso cdp ON det.cuota_pago = cdp.I_ProcesoID
WHERE det.B_Migrable = 1 
	  AND DET.I_OblRowID = 239174 



select * from VW_ObservacionesTabla

SELECT C_RcCod AS 'COD RC', C_CodAlu AS 'COD ALU', T_ApePaterno AS 'AP. PATERNO', T_ApeMaterno AS 'AP MATERNO', T_Nombre AS 'NOMBRE', 
	   C_NumDNI AS 'NUM DOC', C_Sexo AS 'SEXO', C_CodModIng AS 'MOD INGR', C_AnioIngreso AS 'A�O INGR', T_ObservCod AS 'OBSERVACION' 
	   FROM dbo.TR_Alumnos alu 
INNER JOIN TI_ObservacionRegistroTabla obs ON alu.I_RowID = obs.I_FilaTablaID AND obs.I_TablaID = 1
INNER JOIN TC_CatalogoObservacion co ON obs.I_ObservID = co.I_ObservID
WHERE alu.I_ProcedenciaID = 1 AND obs.I_ObservID = 30




SELECT * FROM BD_UNFV_Repositorio.dbo.VW_Alumnos where C_NumDNI = '48486091'
SELECT * FROM BD_OCEF_MigracionTP.dbo.TR_Alumnos where C_NumDNI = '48486091'

SELECT * FROM BD_UNFV_Repositorio.dbo.VW_Alumnos where C_NumDNI = '42049718'
SELECT * FROM BD_OCEF_MigracionTP.dbo.TR_Alumnos where C_NumDNI = '42049718'

SELECT * FROM BD_UNFV_Repositorio.dbo.VW_Alumnos where C_NumDNI = '72168949'
SELECT * FROM BD_OCEF_MigracionTP.dbo.TR_Alumnos where C_NumDNI = '72168949'

SELECT * FROM BD_UNFV_Repositorio.dbo.VW_Alumnos where C_NumDNI = '75667604'
SELECT * FROM BD_OCEF_MigracionTP.dbo.TR_Alumnos where C_NumDNI = '75667604'



exec sp_change_users_login 'report'
exec sp_change_users_login 'auto_fix', 'UserOCEF'
exec sp_change_users_login 'auto_fix', 'UserUNFV'


SELECT * FROM TC_Usuarios
SELECT * FROM webpages_Membership WHERE UserId = 1

UPDATE webpages_Membership SET Password = 'AP4rEZG+/M6zCwEgQfjF5lDadZ3Sr7MCnroZzIXlwDEXCY/Q1esZcx1gPlGIV3ERjA=='


select count(*) from ##TEMP_Persona
select distinct C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, D_FecNac from ##TEMP_Persona
select C_NumDNI, count(*) from ##TEMP_Persona where C_NumDNI is not null group by C_NumDNI having COUNT(*) > 1
select  C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, COUNT(*) FROM ##TEMP_Persona 
group by C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
having COUNT(*) > 1


select  C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, COUNT(*) FROM TR_Alumnos 
where C_NumDNI is not null
group by C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
having COUNT(*) > 1
order by C_NumDNI


select  C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo, COUNT(*) FROM ##TEMP_Persona 
where C_NumDNI is not null
group by C_NumDNI, C_CodTipDoc, T_ApePaterno, T_ApeMaterno, T_Nombre, C_Sexo
having COUNT(*) > 1
order by C_NumDNI

select  I_PersonaID, COUNT(*) FROM ##TEMP_Persona 
group by I_PersonaID
having COUNT(*) > 1



select p.* from ##TEMP_Persona p 
inner join (select C_NumDNI, count(*) cantidad from ##TEMP_Persona 
			where C_NumDNI is not null group by C_NumDNI having COUNT(*) > 1) as a on p.C_NumDNI = a.C_NumDNI 
			
order by p.C_NumDNI

SELECT * FROM ##TEMP_Persona where C_NUMDNI = '73240463'
select * from BD_OCEF_TemporalPagos.dbo.alumnos where C_NUMDNI = '73240463'
select * from TR_Alumnos WHERE C_NumDNI = '2008230617'

SELECT * FROM BD_UNFV_Repositorio..TC_Persona WHERE C_NumDNI = '77328587'
SELECT * FROM BD_UNFV_Repositorio..TC_Persona WHERE I_PersonaID = 24256
SELECT * FROM BD_UNFV_Repositorio..TC_Persona WHERE I_PersonaID = 18970
select * from BD_UNFV_Repositorio..TC_Alumno where I_PersonaID = 24256
select * from BD_UNFV_Repositorio..TC_Alumno where I_PersonaID = 18970
select * from TR_Alumnos where C_NumDNI = '70092156'
select * from ##TEMP_Persona where C_NumDNI = '77010403'

select * from TR_Alumnos where C_RcCod = '001'and C_CodAlu = '0008100789'
select * from BD_UNFV_Repositorio..TC_Alumno where C_CodAlu = '2013020021'

select * from ##TEMP_AlumnoPersona where C_RcCod = '001'and C_CodAlu = '0008100789'
SELECT * FROM BD_UNFV_Repositorio..TC_Persona WHERE T_ApePaterno = 'ANGULO' and T_ApeMaterno = 'ESCALANTE'
SELECT * FROM BD_UNFV_Repositorio..TC_Persona WHERE T_ApePaterno = 'MELCHOR' and T_ApeMaterno = 'QUISPE'
SELECT * FROM BD_UNFV_Repositorio..TC_Persona WHERE T_ApePaterno = 'VALLEJOS' and T_ApeMaterno = 'VASQUEZ'
SELECT * FROM BD_UNFV_Repositorio..TC_Persona WHERE T_ApePaterno = 'VENTO' and T_ApeMaterno = 'ROJAS'


select * from ##TEMP_Persona WHERE T_ApePaterno = 'ANGULO' and T_ApeMaterno = 'ESCALANTE'


SELECT COUNT(*) FROM ##TEMP_Persona 
SELECT IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 

SELECT PER.* FROM  BD_UNFV_Repositorio..TC_Persona PER INNER JOIN (
SELECT C_NumDNI, count(*) cantidad FROM BD_UNFV_Repositorio..TC_Persona where C_NumDNI is not null AND B_Eliminado = 0
 group by C_NumDNI having COUNT(*) > 1
) REP ON PER.C_NumDNI = REP.C_NumDNI 
ORDER BY PER.C_NumDNI



SELECT PER.* FROM  BD_UNFV_Repositorio..TC_Alumno PER INNER JOIN (
SELECT C_CodAlu, count(*) cantidad FROM BD_UNFV_Repositorio..TC_Alumno where C_CodAlu is not null AND B_Eliminado = 0
 group by C_CodAlu having COUNT(*) > 1
) REP ON PER.C_CodAlu = REP.C_CodAlu 
ORDER BY PER.C_CodAlu






SELECT * FROM ##TEMP_Persona TP
WHERE EXISTS (SELECT TP1.T_ApePaterno COLLATE Latin1_general_CI_AI,
					 TP1.T_ApeMaterno COLLATE Latin1_general_CI_AI,
					 TP1.T_Nombre COLLATE Latin1_general_CI_AI,
					 COUNT(*) FROM ##TEMP_Persona TP1				
				GROUP BY TP1.T_ApePaterno COLLATE Latin1_general_CI_AI,
						 TP1.T_ApeMaterno COLLATE Latin1_general_CI_AI,
						 TP1.T_Nombre COLLATE Latin1_general_CI_AI
				HAVING COUNT(*) > 1
						AND TP.T_ApePaterno = TP1.T_ApePaterno COLLATE Latin1_general_CI_AI
						AND TP.T_ApeMaterno = TP1.T_ApeMaterno COLLATE Latin1_general_CI_AI
						AND TP.T_Nombre =  TP1.T_Nombre COLLATE Latin1_general_CI_AI
				)
order by T_ApePaterno, T_ApeMaterno, T_Nombre



SELECT * FROM ##TEMP_AlumnoPersona TP
WHERE EXISTS (SELECT TP1.C_CodAlu, TP1.C_RcCod, COUNT(*) FROM ##TEMP_AlumnoPersona TP1				
				GROUP BY TP1.C_RcCod, TP1.C_CodAlu
				HAVING COUNT(*) > 1
						AND TP.C_CodAlu =  TP1.C_CodAlu
						AND TP.C_RcCod =  TP1.C_RcCod
				)
order by TP.C_RcCod, TP.C_CodAlu






select * from TR_Alumnos A
right join ##TEMP_AlumnoPersona TA on a.C_RcCod = ta.C_RcCod	AND a.C_CodAlu =  ta.C_CodAlu
	where A.C_CodAlu is null
	 and a.I_ProcedenciaID = 2 and B_Migrable = 1
order by a.T_ApePaterno, a.T_ApeMaterno, a.T_Nombre


SELECT min(i_PersonaID) over (partition by C_CodAlu) as max_i_persona, * FROM ##TEMP_AlumnoPersona TP
WHERE EXISTS (SELECT TP1.C_CodAlu, TP1.C_RcCod, COUNT(*) FROM ##TEMP_AlumnoPersona TP1				
				GROUP BY TP1.C_RcCod, TP1.C_CodAlu
				HAVING COUNT(*) > 1
						AND TP.C_CodAlu =  TP1.C_CodAlu
						AND TP.C_RcCod =  TP1.C_RcCod
				)
order by TP.C_RcCod, TP.C_CodAlu


select * from TR_Alumnos A
left join ##TEMP_AlumnoPersona TA on a.C_RcCod = ta.C_RcCod	AND a.C_CodAlu =  ta.C_CodAlu
	where ta.C_CodAlu is null
	 and a.I_ProcedenciaID = 2 and B_Migrable = 1
order by a.T_ApePaterno, a.T_ApeMaterno, a.T_Nombre

select * from ##temp_persona where c_numdni = '70559900'
select * from TR_Alumnos WHERE C_NumDNI = '70559900'

select * from TR_Alumnos WHERE C_NumDNI = '45771176'

select * from TR_Alumnos WHERE T_ApePaterno = 'AMES' and T_ApeMaterno = 'GANVINI'

select * from TR_Alumnos WHERE T_ApePaterno = 'VENTO' and T_ApeMaterno = 'ROJAS'
select * from ##TEMP_Persona where I_PersonaID IN (49942,
49941)
ORDER BY 4,5,6

select * from TR_Alumnos WHERE C_CodAlu = '2009331309'
select * from BD_UNFV_Repositorio.dbo.VW_Alumnos where C_CodAlu = '48877036'

select * from TR_Ec_Obl WHERE B_Migrado = 1

SELECT * FROM VW_ObservacionesTabla WHERE T_TablaNom = 'TR_Ec_obl'
SELECT * FROM VW_ObservacionesTabla WHERE T_TablaNom = 'TR_Ec_det'

SELECT	DISTINCT A.I_PersonaID, LTRIM(RTRIM(REPLACE(P.C_NumDNI,'�', ' '))) AS C_NumDNI, P.C_CodTipDoc,  
		P.T_ApePaterno, P.T_ApeMaterno, P.T_Nombre, IIF(P.C_Sexo IS NULL, TA.C_Sexo, P.C_Sexo) AS C_Sexo
FROM	BD_UNFV_Repositorio.dbo.TC_Persona P
		INNER JOIN BD_UNFV_Repositorio.dbo.TC_Alumno A ON A.I_PersonaID = P.I_PersonaID
		INNER JOIN TR_Alumnos TA ON TA.C_CodAlu = A.C_CodAlu AND TA.C_RcCod = A.C_RcCod
WHERE	P.B_Eliminado = 0 
		AND A.B_Eliminado = 0
order by 1

select count(*) from TI_ObservacionRegistroTabla
select max(I_ObsTablaID) from TI_ObservacionRegistroTabla

select * from TC_CatalogoTabla 

select * from TC_CatalogoObservacion 


SELECT IDENT_CURRENT('TI_ObservacionRegistroTabla')

DELETE TI_ObservacionRegistroTabla WHERE I_TablaID = 5

DECLARE @I_MAX_ObsTablaID bigint 
SET @I_MAX_ObsTablaID = (SELECT max(I_ObsTablaID) + 1 FROM TI_ObservacionRegistroTabla)

DBCC CHECKIDENT('TI_ObservacionRegistroTabla', RESEED, @I_MAX_ObsTablaID)

SELECT IDENT_CURRENT('TI_ObservacionRegistroTabla')

SELECT * FROM TC_CatalogoObservacion


select * from BD_UNFV_Repositorio.dbo.VW_CarreraProfesional where C_CodFac = 'ET'
select * from BD_UNFV_Repositorio.dbo.TC_GradoAcademico


select distinct cod_rc from BD_OCEF_TemporalPagos.eupg.ec_obl where isnumeric(cod_rc) = 1

select * from BD_UNFV_Repositorio.dbo.TI_CarreraProfesional where C_RcCod in (
'010',
'070',
'103',
'064',
'020')

select distinct cod_rc, ano from BD_OCEF_TemporalPagos.eupg.ec_obl where cod_rc in (
'010',
'070',
'103',
'064',
'020')

truncate table TC_CarreraProfesionalProcedencia


SELECT * FROM TC_CarreraProfesionalProcedencia
SELECT * FROM TC_CatalogoObservacion

declare @con_tilde varchar(10)  = 'Jos�'
declare @sin_tilde varchar(10)  = ' jose'

select IIF(@sin_tilde COLLATE Latin1_General_CI_AI = @con_tilde COLLATE Latin1_General_CI_AI , 'IGUALES', 'DIFERENTES')


select * from ##TEMP_AlumnoPersona
select * from ##TEMP_Persona order by I_PersonaID



select * from ##TEMP_AlumnoPersona WHERE C_RcCod = '010' AND C_CodAlu = '2008180647'
select * from ##TEMP_Persona WHERE I_PersonaID IN (31767
,31769)
select * from ##TEMP_Persona WHERE C_NumDNI = '48486091'

select * from TR_Alumnos where C_NumDNI = '43231400'
select * from BD_UNFV_Repositorio..TC_Persona where C_NumDNI = '10087163'
select * from ##TEMP_Persona WHERE C_NumDNI = '43231400'


		SELECT IDENT_CURRENT('BD_UNFV_Repositorio.dbo.TC_Persona') 


SELECT distinct PER.* FROM ##TEMP_Persona per INNER JOIN (
SELECT C_NumDNI, count(*) cantidad FROM ##TEMP_Persona where C_NumDNI is not null group by C_NumDNI having COUNT(*) > 1
) REP ON PER.C_NumDNI = REP.C_NumDNI 
ORDER BY PER.C_NumDNI



UPDATE BD_UNFV_Repositorio..TC_Persona
SET C_NumDNI = A.C_NumDNI
	,T_ApePaterno = A.T_ApePaterno
	,T_ApeMaterno = A.T_ApeMaterno
	,T_Nombre = A.T_Nombre
FROM BD_UNFV_Repositorio..VW_Alumnos VA
	 INNER JOIN TR_Alumnos A ON VA.C_CodAlu = A.C_CodAlu AND VA.C_RcCod = A.C_RcCod
WHERE BD_UNFV_Repositorio..TC_Persona.I_PersonaID = VA.I_PersonaID
	  AND BD_UNFV_Repositorio..TC_Persona.C_NumDNI IS NULL


UPDATE BD_UNFV_Repositorio..TC_Persona
SET C_Sexo = AR.C_Sexo
FROM BD_UNFV_Repositorio..VW_Alumnos VA
	 INNER JOIN TR_Alumnos A ON VA.C_CodAlu = A.C_CodAlu AND VA.C_RcCod = A.C_RcCod
	 INNER JOIN ##Alumno_Repetidos_sexo_diferente AR ON AR.I_RowID = A.I_RowID
WHERE BD_UNFV_Repositorio..TC_Persona.I_PersonaID = VA.I_PersonaID


		select * from ##Alumno_Repetidos_sexo_diferente ORDER BY T_ApePaterno, T_ApeMaterno, T_Nombre



select * from TR_Ec_Obl where B_Actualizado = 1

select * from TR_Ec_Obl where I_RowID = 5961352

select * from TR_Ec_Obl where Ano = '2007' AND P = 'A' AND Cod_alu = '2006701702'
select * from VW_ObservacionesEcObl where I_ObservID = 34 --and I_FilaTablaID = 5807925