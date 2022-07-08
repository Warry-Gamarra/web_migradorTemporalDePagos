USE BD_OCEF_CtasPorCobrar
GO


SELECT BNC.I_CtaDepositoID, CP.I_CatPagoID, 1 AS B_Habilitado, 0 as B_Eliminado--, C_NumeroCuenta, CODIGO_BNC    
FROM TC_CategoriaPago CP 
	 INNER JOIN (SELECT DISTINCT I_CtaDepositoID, C_NumeroCuenta, TP_CP.CODIGO_BNC COLLATE DATABASE_DEFAULT AS CODIGO_BNC
					FROM TC_CuentaDeposito CD  
						 INNER JOIN temporal_pagos..cp_des TP_CP ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CP.N_CTA_CTE COLLATE DATABASE_DEFAULT
					WHERE ELIMINADO = 0 AND CODIGO_BNC IN (
							'0635','0636','0638','0670','0671','0674',
							'0675','0676','0677','0678','0679','0680',
							'0681','0682','0683','0687','0688','0689',
							'0690','0691','0692','0695','0696','0697',
							'0698')
) BNC ON CP.N_CodBanco = BNC.CODIGO_BNC
UNION
SELECT BNC.I_CtaDepositoID, CP.I_CatPagoID, 1 AS B_Habilitado, 0 as B_Eliminado--, C_NumeroCuenta, CODIGO_BNC    
FROM TC_CategoriaPago CP 
	 INNER JOIN (SELECT DISTINCT I_CtaDepositoID, C_NumeroCuenta, TP_CP.CODIGO_BNC COLLATE DATABASE_DEFAULT AS CODIGO_BNC
				 FROM TC_CuentaDeposito CD  
 				 		INNER JOIN temporal_pagos..cp_des TP_CP ON CD.C_NumeroCuenta COLLATE DATABASE_DEFAULT = TP_CP.N_CTA_CTE COLLATE DATABASE_DEFAULT
				 WHERE CODIGO_BNC IS NULL
) BNC ON CP.N_CodBanco IS NULL


SELECT CAST(TP_CD.CUOTA_PAGO AS INT) CUOTA_PAGO, I_CatPagoID, TP_CD.DESCRIPCIO, 
	   CASE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4))) WHEN 1 THEN SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4) ELSE NULL END AS I_Anio, 
	   TP_CP.ano, TP_CP.p,
	   NULL AS I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, CASE C_MORA WHEN 'VERDADERO' THEN 1 WHEN 'FALSO' THEN 0 ELSE NULL END
FROM TC_CategoriaPago CP  
	  INNER JOIN temporal_pagos..cp_des TP_CD ON CP.N_CodBanco COLLATE DATABASE_DEFAULT = TP_CD.CODIGO_BNC COLLATE DATABASE_DEFAULT
	  LEFT JOIN (SELECT DISTINCT cuota_pago, ano, p FROM temporal_pagos..cp_pri WHERE eliminado = 0) TP_CP ON TP_CP.cuota_pago = TP_CD.CUOTA_PAGO
WHERE TP_CD.ELIMINADO = 0 AND CODIGO_BNC IN (
		'0635','0636','0638','0670','0671','0674',
		'0675','0678','0679','0680','0681','0682',
		'0683','0689','0690','0691','0692','0695',
		'0696','0697','0698'
		)
ORDER BY 1,2


SELECT CAST(CUOTA_PAGO AS INT) CUOTA_PAGO, I_CatPagoID, TP_CP.DESCRIPCIO, 
	   CASE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),1,4))) WHEN 1 THEN SUBSTRING(LTRIM(DESCRIPCIO),1,4) ELSE NULL END AS I_Anio, 
	   NULL AS I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, CASE C_MORA WHEN 'VERDADERO' THEN 1 WHEN 'FALSO' THEN 0 ELSE NULL END
FROM TC_CategoriaPago CP  
		INNER JOIN temporal_pagos..cp_des TP_CP ON CP.N_CodBanco COLLATE DATABASE_DEFAULT = TP_CP.CODIGO_BNC COLLATE DATABASE_DEFAULT
WHERE ELIMINADO = 0 AND CODIGO_BNC IN (
			'0637','0639','0658','0672','0673','0685'

			,'0676','0677','0687','0688'
		)
ORDER BY N_CodBanco, 1


SELECT DISTINCT N_CTA_CTE, CODIGO_BNC 
FROM temporal_pagos..cp_des
WHERE ELIMINADO = 0 AND CODIGO_BNC IN (
'0635','0636','0638','0670','0671','0674',
'0675','0676','0677','0678','0679','0680',
'0681','0682','0683','0687','0688','0689',
'0690','0691','0692','0695','0696','0697',
'0698'
)


SELECT * FROM temporal_pagos..cp_des 
WHERE ELIMINADO = 0 AND CODIGO_BNC IN (
'0637',
'0639',
'0658',
'0672',
'0673',
'0685'

,'0676','0677','0687','0688'
)
ORDER BY CODIGO_BNC



SELECT TP_CD.CUOTA_PAGO , COUNT(TP_CD.CUOTA_PAGO), ano
FROM TC_CategoriaPago CP  
	  INNER JOIN temporal_pagos..cp_des TP_CD ON CP.N_CodBanco COLLATE DATABASE_DEFAULT = TP_CD.CODIGO_BNC COLLATE DATABASE_DEFAULT
	  LEFT JOIN (SELECT DISTINCT cuota_pago, ano, p FROM temporal_pagos..cp_pri WHERE eliminado = 0) TP_CP ON TP_CP.cuota_pago = TP_CD.CUOTA_PAGO
WHERE TP_CD.ELIMINADO = 0 AND CODIGO_BNC IN (
		'0635','0636','0638','0670','0671','0674',
		'0675','0678','0679','0680','0681','0682',
		'0683','0689','0690','0691','0692','0695',
		'0696','0697','0698'
		)
		AND CAST(ano AS int) > 2015
GROUP BY TP_CD.CUOTA_PAGO, ano
HAVING COUNT(TP_CD.CUOTA_PAGO) > 1
ORDER BY 1,2


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

SELECT	I_ProcesoID, I_CatPagoID, T_ProcesoDesc, I_Anio, co_periodo.I_OpcionID AS I_Periodo, N_CodBanco, D_FecVencto, I_Prioridad, B_Mora, 
		B_Migrado, TEMP.B_Habilitado, TEMP.B_Eliminado
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





SELECT CAST(TP_CD.CUOTA_PAGO AS INT) CUOTA_PAGO, I_CatPagoID, TP_CD.DESCRIPCIO, 
	   CASE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4))) WHEN 1 THEN SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4) ELSE NULL END AS I_Anio, 
	    NULL AS I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, CASE C_MORA WHEN 'VERDADERO' THEN 1 WHEN 'FALSO' THEN 0 ELSE NULL END AS C_MORA,
		1 AS B_Migrado, 1 AS B_Habilitado, TP_CD.ELIMINADO
FROM TC_CategoriaPago CP  
	  INNER JOIN temporal_pagos..cp_des TP_CD ON TP_CD.CODIGO_BNC IS NULL AND CP.B_Obligacion = 0 
WHERE TP_CD.ELIMINADO = 0
	  AND NOT EXISTS (
			  SELECT TP_CD2.CUOTA_PAGO , COUNT(TP_CD2.CUOTA_PAGO)
				FROM TC_CategoriaPago CP  
					  INNER JOIN temporal_pagos..cp_des TP_CD2 ON CP.N_CodBanco COLLATE DATABASE_DEFAULT = TP_CD2.CODIGO_BNC COLLATE DATABASE_DEFAULT
					  LEFT JOIN (SELECT DISTINCT cuota_pago, ano, p FROM temporal_pagos..cp_pri WHERE eliminado = 0) TP_CP ON TP_CP.cuota_pago = TP_CD2.CUOTA_PAGO
				WHERE TP_CD2.CUOTA_PAGO = TP_CD.CUOTA_PAGO AND TP_CD2.ELIMINADO = 0 AND CODIGO_BNC IN (
						'0635','0636','0638','0670','0671','0674',
						'0675','0678','0679','0680','0681','0682',
						'0683','0689','0690','0691','0692','0695',
						'0696','0697','0698'
						)
				GROUP BY TP_CD2.CUOTA_PAGO
				HAVING COUNT(TP_CD2.CUOTA_PAGO) > 1
	  )
UNION
SELECT CAST(TP_CD.CUOTA_PAGO AS INT) CUOTA_PAGO, I_CatPagoID, TP_CD.DESCRIPCIO, 
	   CASE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4))) WHEN 1 THEN SUBSTRING(LTRIM(TP_CD.DESCRIPCIO),1,4) ELSE NULL END AS I_Anio, 
	   NULL AS I_Periodo, CODIGO_BNC, FCH_VENC, PRIORIDAD, CASE C_MORA WHEN 'VERDADERO' THEN 1 WHEN 'FALSO' THEN 0 ELSE NULL END  AS C_MORA,
	   1 AS B_Migrado, 1 AS B_Habilitado, TP_CD.ELIMINADO
FROM TC_CategoriaPago CP  
	  INNER JOIN temporal_pagos..cp_des TP_CD ON CP.N_CodBanco COLLATE DATABASE_DEFAULT = TP_CD.CODIGO_BNC COLLATE DATABASE_DEFAULT
WHERE TP_CD.ELIMINADO = 0 AND CODIGO_BNC IN (
		'0635','0636','0638','0670','0671','0674',
		'0675','0678','0679','0680','0681','0682',
		'0683','0689','0690','0691','0692','0695',
		'0696','0697','0698'
		)
	  AND EXISTS (
			SELECT TP_CD2.CUOTA_PAGO , COUNT(TP_CD2.CUOTA_PAGO)
			FROM TC_CategoriaPago CP  
					INNER JOIN temporal_pagos..cp_des TP_CD2 ON CP.N_CodBanco COLLATE DATABASE_DEFAULT = TP_CD2.CODIGO_BNC COLLATE DATABASE_DEFAULT
					LEFT JOIN (SELECT DISTINCT cuota_pago, ano, p FROM temporal_pagos..cp_pri WHERE eliminado = 0) TP_CP ON TP_CP.cuota_pago = TP_CD2.CUOTA_PAGO
			WHERE TP_CD2.CUOTA_PAGO = TP_CD.CUOTA_PAGO AND TP_CD2.ELIMINADO = 0 AND CODIGO_BNC IN (
					'0635','0636','0638','0670','0671','0674',
					'0675','0678','0679','0680','0681','0682',
					'0683','0689','0690','0691','0692','0695',
					'0696','0697','0698'
					)
			GROUP BY TP_CD2.CUOTA_PAGO
			HAVING COUNT(TP_CD2.CUOTA_PAGO) > 1
	  )



SELECT * FROM TC_CategoriaPago WHERE I_CatPagoID = 36

/* CONSULTAS DE TASAS QUE COINCIDEN CON LOS DATOS IMPORTADOS DE CUOTA Y CATEGORIA DE PAGO*/

SELECT * FROM temporal_pagos..cp_pri cp_pri
INNER JOIN TC_Proceso P ON cp_pri.cuota_pago = P.I_ProcesoID
WHERE I_CatPagoID = 36 AND cp_pri.clasific_5 <> ''
ORDER BY descripcio
--UNION 
SELECT * FROM temporal_pagos..cp_pri cp_pri
INNER JOIN TC_Proceso P ON cp_pri.cuota_pago = P.I_ProcesoID
WHERE I_CatPagoID = 36 AND cp_pri.clasific_5 = ''
ORDER BY descripcio

/* CONSULTAS DE TASAS QUE COINCIDEN CON LOS DATOS IMPORTADOS DE CUOTA Y CATEGORIA DE PAGO CON DESCRIPCIONES REPETIDAS Y CLASIF 5 DIGITOS */
SELECT cp_pri.clasificad, cp_pri.descripcio, COUNT(cp_pri.id_cp) FROM temporal_pagos..cp_pri cp_pri
INNER JOIN TC_Proceso P ON cp_pri.cuota_pago = P.I_ProcesoID
WHERE I_CatPagoID = 36 AND cp_pri.clasific_5 <> ''
GROUP BY cp_pri.clasificad, cp_pri.descripcio
HAVING COUNT(cp_pri.id_cp) > 1
ORDER BY 1

SELECT cp_pri.descripcio, COUNT(cp_pri.id_cp) FROM temporal_pagos..cp_pri cp_pri
INNER JOIN TC_Proceso P ON cp_pri.cuota_pago = P.I_ProcesoID
WHERE I_CatPagoID = 36 AND cp_pri.clasific_5 <> ''
GROUP BY cp_pri.descripcio
HAVING COUNT(cp_pri.id_cp) > 1
ORDER BY 1


SELECT *
FROM temporal_pagos..cp_pri 
WHERE cuota_pago = 484

SELECT cp_pri.clasificad, cp_pri.grado
		,(SELECT top 1 a.descripcio from temporal_pagos..cp_pri a 
			where a.clasificad = cp_pri.clasificad and a.grado = cp_pri.grado order by ano desc)
		,(SELECT top 1 a.monto_min from temporal_pagos..cp_pri a 
			where a.clasificad = cp_pri.clasificad and a.grado = cp_pri.grado order by ano desc)
		,(SELECT top 1 a.monto from temporal_pagos..cp_pri a 
			where a.clasificad = cp_pri.clasificad and a.grado = cp_pri.grado order by ano desc)
		,COUNT(cp_pri.id_cp)
FROM temporal_pagos..cp_pri cp_pri
left join temporal_pagos..cp_pri cp_pri_agrupa on cp_pri.id_cp_agrp = cp_pri_agrupa.id_cp
INNER JOIN TC_Proceso P ON cp_pri.cuota_pago = P.I_ProcesoID
WHERE I_CatPagoID <> 36
GROUP BY cp_pri.clasificad, cp_pri.grado
ORDER BY 1,2

SELECT cp_pri.clasificad
		,(SELECT top 1 a.descripcio from temporal_pagos..cp_pri a 
			where a.clasificad = cp_pri.clasificad order by ano desc) as descripcio
		,(SELECT top 1 a.monto_min from temporal_pagos..cp_pri a  
			where a.clasificad = cp_pri.clasificad order by ano desc) as monto_min
		,(SELECT top 1 a.monto from temporal_pagos..cp_pri a 
			where a.clasificad = cp_pri.clasificad order by ano desc) as monto
		,COUNT(cp_pri.id_cp) as registros
FROM temporal_pagos..cp_pri cp_pri
left join temporal_pagos..cp_pri cp_pri_agrupa on cp_pri.id_cp_agrp = cp_pri_agrupa.id_cp
INNER JOIN TC_Proceso P ON cp_pri.cuota_pago = P.I_ProcesoID
WHERE I_CatPagoID <> 36 and cp_pri.eliminado = 0 and cp_pri.clasificad <> ''-- AND cp_pri.ano in ('2020', '2019', '2018')
GROUP BY cp_pri.clasificad
ORDER BY 1


SELECT ' VALUES ('		
		, '1, 0, 0,' 
		, '''' + cp_pri.clasificad + '''', ','
		,IIF((SELECT top 1 a.calcular from temporal_pagos..cp_pri a  
			where a.clasificad = cp_pri.clasificad order by ano desc) <> '', 1, 0) as b_calcular
		, ','
		, (SELECT top 1 IIF(a.calcular <> '', a.calcular, null) from temporal_pagos..cp_pri a  
			where a.clasificad = cp_pri.clasificad order by ano desc) as calcular
		, ', 1 , 0,'
		,(SELECT top 1 a.monto from temporal_pagos..cp_pri a 
			where a.clasificad = cp_pri.clasificad order by ano desc) as monto
		, ','
		,(SELECT top 1 a.monto_min from temporal_pagos..cp_pri a  
			where a.clasificad = cp_pri.clasificad order by ano desc) as monto_min
		, ','
		,(SELECT top 1 '''' + a.descripcio + '''' from temporal_pagos..cp_pri a 
			where a.clasificad = cp_pri.clasificad order by ano desc) as descripcio
		, ')'
FROM temporal_pagos..cp_pri cp_pri
left join temporal_pagos..cp_pri cp_pri_agrupa on cp_pri.id_cp_agrp = cp_pri_agrupa.id_cp
INNER JOIN TC_Proceso P ON cp_pri.cuota_pago = P.I_ProcesoID
WHERE I_CatPagoID <> 36 and cp_pri.eliminado = 0 and cp_pri.clasificad <> ''-- AND cp_pri.ano in ('2020', '2019', '2018')
GROUP BY cp_pri.clasificad
ORDER BY 1

select * from TI_ConceptoPago
select * from TC_Concepto

select * from TC_CatalogoOpcion


select * from TC_Proceso where I_ProcesoID = 63