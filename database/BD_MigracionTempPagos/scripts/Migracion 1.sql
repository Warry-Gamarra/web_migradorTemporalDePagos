USE BD_OCEF_CtasPorCobrar
GO


/* -------------------------------- TC_CuentaDeposito ------------------------------------ */

/*	SI DURANTE LA MIGRACION EXISTEN MAS NUMEROS DE CUENTA QUE LOS REGISTRADOS INICIALMENTE SE
	INSERTAN EN LA TABLA TC_CuentaDeposito
*/


IF EXISTS (SELECT DISTINCT N_CTA_CTE FROM temporal_pagos..cp_des 
			WHERE ELIMINADO = 0 AND NOT EXISTS (
			SELECT * FROM TC_CuentaDeposito CD 
			WHERE N_CTA_CTE COLLATE DATABASE_DEFAULT = C_NumeroCuenta COLLATE DATABASE_DEFAULT))
BEGIN
	INSERT TC_CuentaDeposito(I_EntidadFinanID, C_NumeroCuenta, B_Habilitado, B_Eliminado)
	SELECT DISTINCT 1, N_CTA_CTE, 1, 0 FROM temporal_pagos..cp_des 
			WHERE ELIMINADO = 0 AND NOT EXISTS (
			SELECT * FROM TC_CuentaDeposito CD 
			WHERE N_CTA_CTE COLLATE DATABASE_DEFAULT = C_NumeroCuenta COLLATE DATABASE_DEFAULT)
END
GO


/* -------------------------------- TC_CuentaDeposito_CategoriaPago ------------------------------------ */

INSERT TC_CuentaDeposito_CategoriaPago(I_CtaDepositoID, I_CatPagoID, B_Habilitado, B_Eliminado)
SELECT BNC.I_CtaDepositoID, CP.I_CatPagoID, 1 AS B_Habilitado, 0 as B_Eliminado--, C_NumeroCuenta, CODIGO_BNC    
FROM TC_CategoriaPago CP 
	 INNER JOIN (SELECT DISTINCT I_CtaDepositoID, C_NumeroCuenta, TP_CP.CODIGO_BNC COLLATE DATABASE_DEFAULT AS CODIGO_BNC
				 FROM TC_CuentaDeposito CD  
				 	 INNER JOIN temporal_pagos..cp_des TP_CP ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CP.N_CTA_CTE COLLATE DATABASE_DEFAULT
				 WHERE ELIMINADO = 0
) BNC ON CP.N_CodBanco = BNC.CODIGO_BNC
UNION
SELECT BNC.I_CtaDepositoID, CP.I_CatPagoID, 1 AS B_Habilitado, 0 as B_Eliminado--, C_NumeroCuenta, CODIGO_BNC    
FROM TC_CategoriaPago CP 
	 INNER JOIN (SELECT DISTINCT I_CtaDepositoID, C_NumeroCuenta, TP_CP.CODIGO_BNC COLLATE DATABASE_DEFAULT AS CODIGO_BNC
				 FROM TC_CuentaDeposito CD  
 				 		INNER JOIN temporal_pagos..cp_des TP_CP ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CP.N_CTA_CTE COLLATE DATABASE_DEFAULT
				 WHERE CODIGO_BNC IS NULL AND ELIMINADO = 0
) BNC ON CP.N_CodBanco IS NULL
GO


/* -------------------------------- TC_Proceso - TI_CtaDepo_Proceso ------------------------------------ */

SET IDENTITY_INSERT TC_Proceso ON
GO

WITH TEMP_PROC (I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, B_Migrado, B_Habilitado, B_Eliminado)
AS
(
	SELECT CAST(TP_CD.CUOTA_PAGO AS INT) CUOTA_PAGO, I_CatPagoID, TP_CD.DESCRIPCIO, 
	   CASE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4))) WHEN 1 THEN SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4) ELSE NULL END AS I_Anio, 
	    CODIGO_BNC, FCH_VENC, PRIORIDAD, CASE C_MORA WHEN 'VERDADERO' THEN 1 WHEN 'FALSO' THEN 0 ELSE NULL END AS C_MORA,
		1 AS B_Migrado, 1 AS B_Habilitado, TP_CD.ELIMINADO
	FROM TC_CategoriaPago CP  
		  INNER JOIN temporal_pagos..cp_des TP_CD ON CP.N_CodBanco COLLATE DATABASE_DEFAULT = TP_CD.CODIGO_BNC COLLATE DATABASE_DEFAULT
	WHERE TP_CD.ELIMINADO = 0 AND CODIGO_BNC IN (
			'0635','0636','0638','0670','0671','0674',
			'0675','0678','0679','0680','0681','0682',
			'0683','0689','0690','0691','0692','0695',
			'0696','0697','0698'
			)
)

INSERT INTO TC_Proceso (I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, I_Periodo, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, B_Migrado, B_Habilitado, B_Eliminado)
SELECT	I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, co_periodo.I_OpcionID AS I_Periodo, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, B_Migrado, TEMP.B_Habilitado, TEMP.B_Eliminado
FROM	TEMP_PROC TEMP
		LEFT JOIN (SELECT DISTINCT cuota_pago, ano, p FROM temporal_pagos..cp_pri WHERE eliminado = 0) TP_CP ON TP_CP.cuota_pago = TEMP.I_ProcesoID
		LEFT JOIN TC_CatalogoOpcion co_periodo ON co_periodo.T_OpcionCod COLLATE DATABASE_DEFAULT = TP_CP.p COLLATE DATABASE_DEFAULT AND co_periodo.I_ParametroID = 5
WHERE	NOT EXISTS (
			SELECT TP_CD2.I_ProcesoID , COUNT(TP_CD2.I_ProcesoID)
			  FROM TEMP_PROC TP_CD2
				   LEFT JOIN (SELECT DISTINCT cuota_pago, ano, p FROM temporal_pagos..cp_pri WHERE eliminado = 0) TP_CP ON TP_CP.cuota_pago = TP_CD2.I_ProcesoID
			 WHERE TP_CD2.I_ProcesoID = TEMP.I_ProcesoID
			GROUP BY TP_CD2.I_ProcesoID
			HAVING COUNT(TP_CD2.I_ProcesoID) > 1
		)
UNION
SELECT	I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, NULL AS I_Periodo, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, 
		B_Migrado, TEMP.B_Habilitado, TEMP.B_Eliminado
FROM	TEMP_PROC TEMP
WHERE	EXISTS (
			SELECT TP_CD2.I_ProcesoID , COUNT(TP_CD2.I_ProcesoID)
			  FROM TEMP_PROC TP_CD2
				   LEFT JOIN (SELECT DISTINCT cuota_pago, ano, p FROM temporal_pagos..cp_pri WHERE eliminado = 0) TP_CP ON TP_CP.cuota_pago = TP_CD2.I_ProcesoID
			 WHERE TP_CD2.I_ProcesoID = TEMP.I_ProcesoID
			GROUP BY TP_CD2.I_ProcesoID
			HAVING COUNT(TP_CD2.I_ProcesoID) > 1
		)
UNION
SELECT CAST(TP_CD.CUOTA_PAGO AS INT) CUOTA_PAGO, I_CatPagoID, TP_CD.DESCRIPCIO, 
	   CASE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4))) WHEN 1 THEN SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4) ELSE NULL END AS I_Anio, 
	    NULL AS I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, CASE C_MORA WHEN 'VERDADERO' THEN 1 WHEN 'FALSO' THEN 0 ELSE NULL END AS C_MORA,
		1 AS B_Migrado, 1 AS B_Habilitado, TP_CD.ELIMINADO
FROM TC_CategoriaPago CP  
	  INNER JOIN temporal_pagos..cp_des TP_CD ON TP_CD.CODIGO_BNC IS NULL AND CP.B_Obligacion = 0 
WHERE TP_CD.ELIMINADO = 0

SET IDENTITY_INSERT TC_Proceso OFF
GO

INSERT INTO TI_CtaDepo_Proceso (I_CtaDepositoID, I_ProcesoID, B_Habilitado, B_Eliminado)
SELECT CD.I_CtaDepositoID, P.I_ProcesoID, 1 AS B_Habilitado, 0 AS B_Eliminado
FROM TC_Proceso P
	INNER JOIN temporal_pagos..cp_des TP_CD ON TP_CD.CUOTA_PAGO = P.I_ProcesoID AND TP_CD.ELIMINADO = 0
	INNER JOIN TC_CuentaDeposito CD ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CD.N_CTA_CTE COLLATE DATABASE_DEFAULT
GO


/* -------------------------------- TC_Concepto - TI_ConceptoPago (OBLIGACIONES) ------------------------------------ */

SET IDENTITY_INSERT TC_Concepto ON
GO

-- INSERTAR CONCEPTOS agrupa = 1
INSERT INTO TC_Concepto (I_ConceptoID, T_ConceptoDesc, T_Clasificador, I_Monto, I_MontoMinimo, B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado)
				SELECT id_cp, descripcio, clasificad, monto, monto_min, 1, 0, 1, 0, NULL, 1,eliminado
				FROM temporal_pagos..cp_pri 
				WHERE agrupa = 1 and tipo_oblig = 1

SET IDENTITY_INSERT TC_Concepto OFF
GO

-- INSERTAR CONCEPTOS agrupa = 0

 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230010100',	0, NULL, 1, 0, 40, 40,'BIBLIOTECA')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230010300',	0, NULL, 1, 0, 16, 11,'CARNET UNIVERSITARIO EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230010301',	0, NULL, 1, 0, 16, 16,'CARNET UNIVERSITARIO')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230020315',	0, NULL, 0, 0, 40, 0,'LABORATORIO EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '123003200',	0, NULL, 0, 0, 6, 6,'RECORD ACADÉMICO')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230032000',	0, NULL, 1, 0, 6, 6,'RECORD ACADÉMICO')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230033701',	0, NULL, 1, 0, 150, 150,'CONSTANCIA DE INGRESO MAESTRÍA')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230033702',	0, NULL, 1, 0, 150, 150,'CONSTANCIA DE INGRESO DOCTORADO')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230040311',	0, NULL, 1, 0, 49, 49,'LABORATORIO GABINETE - GRUPO 1')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230040312',	0, NULL, 1, 0, 42, 42,'LABORATORIO GABINETE - GRUPO 2')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230040313',	0, NULL, 1, 0, 35, 35,'LABORATORIO GABINETE - GRUPO 3')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230040314',	0, NULL, 1, 0, 28, 28,'LABORATORIO GABINETE - GRUPO 4')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230070200',	0, NULL, 1, 0, 25, 25,'SERVICIOS UNIVERSITARIOS')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080100',	0, NULL, 1, 0, 1920, 480,'PENSIÓN MAESTRIA INGRESANTE EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080110',	0, NULL, 1, 0, 1920, 480,'PENSIÓN MAESTRIA REGULAR EUPG')
 --INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080200',	0, NULL, 1, 0, 2400, 600,'PENSIÓN DOCTORADO INGRESANTE EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080200',	0, NULL, 1, 0, 2400, 600,'PENSIÓN DOCTORADO REGULAR EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080610',	1, 3, 1, 0,	2232, 248,'PENSIÓN ENSEÑANZA SEGUNDA PROFESIÓN')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080605',	1, 3, 1, 0,	186, 186,'PENSIÓN CONVENIO - 2DA PROF. PNP')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080606',	1, 3, 1, 0,	186, 186,'PENSIÓN CONVENIO - 2DA PROF. EP')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080611',	1, 3, 1, 0,	200, 200,'PENSIÓN ENSEÑANZA - TRASLADO EXT.PARTICUL')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080612',	1, 3, 1, 0,	50,	50,'PENSIÓN ENSEÑANZA - TRASLADO EXT.NACIONAL')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230080618',	0, NULL, 1, 0, 100,	100,'DERECHO ACADÉMICO MENSUAL')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230081600',	0, NULL, 1, 0, 390,	130,'PENSIÓN - PROCUNED')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230081601',	0, NULL, 1, 0, 225,	225,'PENSIÓN - PROLICED')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090200',	0, NULL, 1, 0, 35, 0,'MATRÍCULA')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090300',	0, NULL, 1, 0, 100,	100,'MATRÍCULA CONVENIO POLI')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090301',	0, NULL, 1, 0, 170,	170,'MATRÍCULA (X CONVENIO) 2DA.PROF.FAP')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090302',	0, NULL, 1, 0, 170,	170,'MATRÍCULA (X CONVENIO) 2DA.PROF.PNP')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090303',	0, NULL, 1, 0, 170,	170,'MATRÍCULA (X CONVENIO) 2DA.PROF.EJE')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090304',	0, NULL, 1, 0, 178,	178,'MATRÍCULA (ALUMNO.CONV)')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090308',	0, NULL, 1, 0, 196,	196,'MATRÍCULA BACHILL.CONV.FAP')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 1, 0, '1230090400',	0, NULL, 1, 0, 50, 50,'MATRÍCULA EXTEMPORÁNEA (RECARGO)')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090502',	0, NULL, 1, 0, 80, 80,'MATRÍCULA / LIMA - PROCUNED')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090503',	0, NULL, 1, 0, 80, 80,'MATRÍCULA / PROV. - PROCUNED')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090504',	0, NULL, 1, 0, 100,	100,'MATRÍCULA / LIMA - PROLICED')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230090505',	0, NULL, 1, 0, 130,	130,'MATRÍCULA / PROV. - PROLICED')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230091500',	0, NULL, 1, 0, 500,	500,'MATRÍCULA MAESTRÍA - EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230091600',	0, NULL, 1, 0, 500,	500,'MATRÍCULA DOCTORADO - EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230092500',	0, NULL, 1, 0, 100,	100,'MATRÍCULA SUSPENSIÓN')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230092501',	0, NULL, 1, 0, 100,	100,'MATRÍCULA CANCELADA')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230990210',	1, 4, 1 , 0, 21,21,'MULTA POR NO VOTAR')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '123099100',	0, NULL, 1 , 0,	0, 0,'FRACCIONAMIENTO DEUDA ANTERIOR EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1230991000',	0, NULL, 1 , 0,	0, 0,'MORA X PENSIONES - PERIODO ACTUAL')
 --INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '123991000', 0, NULL, 1 , 0, 0, 0,'MORA X PENSIONES')
 --INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1323199121', 0, NULL, 1 , 0, 0, 0,'DEUDAS ANTERIORES EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1440012800',	0, NULL, 1, 0, 3, 3,'CARPETA DE MATRÍCULA')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1540020315',	0, NULL, 1, 0, 0, 0,'LABORATORIO INFORMÁTICA - EUPG')
 INSERT INTO TC_Concepto (B_EsPagoMatricula, B_EsPagoExtmp, B_ConceptoAgrupa, T_Clasificador, B_Calculado, I_Calculado, B_Habilitado, B_Eliminado, I_Monto, I_MontoMinimo, T_ConceptoDesc ) VALUES (1, 0, 0, '1540100100',	0, NULL, 1, 0, 5, 5,'DEPORTES')

 GO


SET IDENTITY_INSERT TI_ConceptoPago ON
GO

INSERT INTO TI_ConceptoPago (I_ConcPagID, I_ProcesoID, I_ConceptoID, T_ConceptoPagoDesc, B_Fraccionable, B_ConceptoGeneral, B_AgrupaConcepto, I_AlumnosDestino, I_GradoDestino, I_TipoObligacion, T_Clasificador, C_CodTasa, B_Calculado, I_Calculado, 
							B_AnioPeriodo, I_Anio, I_Periodo, B_Especialidad, C_CodRc, B_Dependencia, C_DepCod, B_GrupoCodRc, I_GrupoCodRc, B_ModalidadIngreso, I_ModalidadIngresoID, B_ConceptoAgrupa, I_ConceptoAgrupaID, B_ConceptoAfecta, 
							I_ConceptoAfectaID, N_NroPagos, B_Porcentaje, C_Moneda, M_Monto, M_MontoMinimo, T_DescripcionLarga, T_Documento, B_Migrado, B_Habilitado, B_Eliminado, I_TipoDescuentoID)

			SELECT  cp.id_cp, cp.cuota_pago, c.I_ConceptoID, cp.descripcio, cp.fraccionab, cp.concepto_g, cp.agrupa, co_tipoAlumno.I_OpcionID as tip_alumno, co_grado.I_OpcionID as grado, co_tipOblg.I_OpcionID as tip_oblig, cp.clasificad, cp.clasific_5, 
					CASE WHEN co_calc.I_OpcionID IS NULL THEN 0 ELSE 1 END as calculado, co_calc.I_OpcionID as tip_calculo, CASE CAST(cp.ano AS int) WHEN 0 THEN 0 ELSE 1 END as b_anio, CASE CAST(cp.ano AS int) WHEN 0 THEN NULL ELSE CAST(cp.ano AS int) END as anio, 
					co_periodo.I_OpcionID as periodo, CASE LEN(LTRIM(RTRIM(cp.cod_rc))) WHEN 0 THEN 0 ELSE 1 END as b_cod_rc, CASE LEN(LTRIM(RTRIM(cp.cod_rc))) WHEN 0 THEN NULL ELSE cp.cod_rc END as cod_rc, 
					CASE LEN(LTRIM(RTRIM(cp.cod_dep_pl))) WHEN 0 THEN 0 ELSE 1 END as b_cod_dep_pl, unfv_dep.I_DependenciaID, CASE WHEN co_grpRc.I_OpcionID IS NULL THEN 0 ELSE 1 END as b_co_grpRc, co_grpRc.I_OpcionID as grupo_rc,
					CASE WHEN co_codIng.I_OpcionID IS NULL THEN 0 ELSE 1 END as b_codIng, co_codIng.I_OpcionID as codIng, CASE cp.id_cp_agrp WHEN 0 THEN 0 ELSE 1 END as b_id_cp_agrp, CASE cp.id_cp_agrp WHEN 0 THEN NULL ELSE cp.id_cp_agrp END as id_cp_agrp, 
					CASE cp.id_cp_afec WHEN 0 THEN 0 ELSE 1 END as b_id_cp_afec, CASE cp.id_cp_afec WHEN 0 THEN NULL ELSE cp.id_cp_afec END as id_cp_afec, cp.nro_pagos, cp.porcentaje, 'PEN' as moneda, cp.monto, cp.monto_min, cp.descrip_l,
					cp.documento, 1 as migrado, 1 as habilitado, cp.eliminado as eliminado, NULL as tipo_descuento

			FROM	temporal_pagos.dbo.cp_pri cp
					INNER JOIN TC_Concepto c ON c.T_Clasificador COLLATE DATABASE_DEFAULT = cp.clasificad COLLATE DATABASE_DEFAULT AND c.B_ConceptoAgrupa = 0
					INNER JOIN TC_Proceso p ON cp.cuota_pago = p.I_ProcesoID
					LEFT JOIN TC_CatalogoOpcion co_tipoAlumno ON CAST(co_tipoAlumno.T_OpcionCod AS float) = cp.tip_alumno AND co_tipoAlumno.I_ParametroID = 1
					LEFT JOIN TC_CatalogoOpcion co_grado ON CAST(co_grado.T_OpcionCod AS float) = cp.grado AND co_grado.I_ParametroID = 2
					LEFT JOIN TC_CatalogoOpcion co_tipOblg ON CAST(co_tipOblg.T_OpcionCod AS bit) = cp.tipo_oblig AND co_tipOblg.I_ParametroID = 3
					LEFT JOIN TC_CatalogoOpcion co_calc ON co_calc.T_OpcionCod COLLATE DATABASE_DEFAULT = cp.calcular COLLATE DATABASE_DEFAULT AND co_calc.I_ParametroID = 4
					LEFT JOIN TC_CatalogoOpcion co_periodo ON co_periodo.T_OpcionCod COLLATE DATABASE_DEFAULT = cp.p COLLATE DATABASE_DEFAULT AND co_periodo.I_ParametroID = 5
					LEFT JOIN TC_CatalogoOpcion co_grpRc ON co_grpRc.T_OpcionCod COLLATE DATABASE_DEFAULT = cp.grupo_rc COLLATE DATABASE_DEFAULT AND co_grpRc.I_ParametroID = 6
					LEFT JOIN TC_CatalogoOpcion co_codIng ON co_codIng.T_OpcionCod COLLATE DATABASE_DEFAULT = cp.cod_ing COLLATE DATABASE_DEFAULT AND co_codIng.I_ParametroID = 7
					LEFT JOIN TC_DependenciaUNFV unfv_dep on unfv_dep.C_DepCodPl COLLATE DATABASE_DEFAULT = cp.cod_dep_pl COLLATE DATABASE_DEFAULT AND LEN(unfv_dep.C_DepCodPl) > 0 
			WHERE	
			 		p.I_CatPagoID <> 36 
					AND cp.agrupa = 0
			ORDER BY cuota_pago, id_cp

SET IDENTITY_INSERT TI_ConceptoPago OFF
GO



SELECT * FROM ec_obl 
WHERE ANO = '2007' AND P =	'2' AND COD_ALU = '2006328587' AND COD_RC = 'M37' AND CUOTA_PAGO = '61'

SELECT * FROM ec_det 
WHERE ANO = '2007' AND P =	'2' AND COD_ALU = '2006328587' AND COD_RC = 'M37' AND CUOTA_PAGO = '61'


SELECT * FROM ec_obl 
WHERE ANO = '2019' AND P =	'2' AND COD_ALU = '2012337825' AND COD_RC = 'P49' AND CUOTA_PAGO = '478'

SELECT * FROM ec_det SRC
WHERE ANO = '2011' AND P =	'1' AND COD_ALU = '2011313049' AND COD_RC = 'D03' AND CUOTA_PAGO = '209'


SELECT TRG.*, SRC.* FROM ec_obl TRG 
LEFT JOIN ec_det SRC ON TRG.ANO = SRC.ANO AND TRG.P = SRC.P
	AND TRG.COD_ALU	= SRC.COD_ALU AND TRG.COD_RC = SRC.COD_RC
	AND TRG.CUOTA_PAGO = SRC.CUOTA_PAGO AND ISNULL(CONVERT(VARCHAR, TRG.FCH_VENC, 112), '/ /') = CONCAT(SUBSTRING(SRC.FCH_VENC,7,4),SUBSTRING(SRC.FCH_VENC,1,2),SUBSTRING(SRC.FCH_VENC,4,2))
	AND TRG.TIPO_OBLIG = CASE SRC.TIPO_OBLIG WHEN 'T' THEN 1 ELSE 0 END AND SRC.CONCEPTO <> 0 AND SRC.ELIMINADO = 'F'
WHERE SRC.ANO IS NULL
ORDER BY 1,2,3,4,5

