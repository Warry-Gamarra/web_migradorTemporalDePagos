/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- Inserta todos los valores de la tabla cp_pri a la tabla TC_ConceptoPago excepto los ID_CP 3899,3898,3897,3896 con estado Eliminado = 1 por estar repetidos 
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/

DELETE TC_ConceptoPago
DBCC CHECKIDENT(TC_ConceptoPago, RESEED, 0)

DECLARE @max_id int

SET IDENTITY_INSERT TC_ConceptoPago ON

INSERT INTO TC_ConceptoPago (I_ConceptoID, T_ConceptoDesc, B_Habilitado, B_Eliminado)
				SELECT ID_CP, DESCRIPCIO, 0, ISNULL(ELIMINADO, 0) FROM cp_pri A
				WHERE NOT EXISTS (SELECT ID_CP, DESCRIPCIO, 0, ISNULL(ELIMINADO, 0) FROM CP_PRI B WHERE A.ID_CP IN (3899,3898,3897,3896) AND A.ELIMINADO = 1)  
				ORDER BY A.ID_CP ASC

SET IDENTITY_INSERT TC_ConceptoPago OFF

SET @max_id = (SELECT ISNULL(MAX(I_ConceptoID),0) FROM TC_ConceptoPago)

DBCC CHECKIDENT(TC_ConceptoPago, RESEED, @max_id)

GO


/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- Inserta todos los valores de la tabla cp_des a la tabla TC_TipoPeriodo  
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/

DELETE TC_CuentaDeposito_TipoPeriodo
DBCC CHECKIDENT(TC_CuentaDeposito_TipoPeriodo, RESEED, 0)

DELETE TC_TipoPeriodo
DBCC CHECKIDENT(TC_TipoPeriodo, RESEED, 0)

INSERT INTO TC_TipoPeriodo (T_TipoPerDesc, I_Prioridad, B_Habilitado, B_Eliminado)
SELECT DESCRIP AS T_TipoPerDesc, NULL AS I_Prioridad, 1 AS B_Habilitado, 0 AS B_Eliminado FROM (
SELECT DISTINCT LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),5,LEN(DESCRIPCIO))) AS DESCRIP
FROM cp_des
WHERE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),1,4))) = 1 
	AND SUBSTRING(LTRIM(DESCRIPCIO),5,1) = ' '
UNION
SELECT DISTINCT LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),5,LEN(DESCRIPCIO))) AS DESCRIP
FROM cp_des
WHERE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),1,4))) = 1 
	AND SUBSTRING(LTRIM(DESCRIPCIO),5,1) <> ''
UNION
SELECT DISTINCT LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),5,LEN(DESCRIPCIO))) AS DESCRIP
FROM cp_des
WHERE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),1,4))) = 0 
	AND SUBSTRING(LTRIM(DESCRIPCIO),5,1) <> ''
) TIPO_PERIODO
ORDER BY DESCRIP ASC


/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- Insertar cp_des en tabla TC_Periodo
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/

INSERT INTO TC_Periodo (I_TipoPeriodoID, I_Anio, D_FecVencto, I_Prioridad, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod)
SELECT I_TipoPeriodoID, TP.T_TipoPerDesc, SUBSTRING(LTRIM(CD1.DESCRIPCIO),1,4),
FROM TC_TipoPeriodo TP 
INNER JOIN cp_des CD1 ON TP.T_TipoPerDesc = LTRIM(SUBSTRING(LTRIM(CD1.DESCRIPCIO),5,LEN(CD1.DESCRIPCIO))) 
			AND ISNUMERIC(LTRIM(SUBSTRING(LTRIM(CD1.DESCRIPCIO),1,4))) = 1 
			AND SUBSTRING(LTRIM(CD1.DESCRIPCIO),5,1) <> ''
UNION
SELECT I_TipoPeriodoID, TP.T_TipoPerDesc,  
FROM TC_TipoPeriodo TP 
INNER JOIN cp_des CD2 ON TP.T_TipoPerDesc = LTRIM(SUBSTRING(LTRIM(CD2.DESCRIPCIO),5,LEN(CD2.DESCRIPCIO))) 
			AND ISNUMERIC(LTRIM(SUBSTRING(LTRIM(CD2.DESCRIPCIO),1,4))) = 1 
			AND SUBSTRING(LTRIM(CD2.DESCRIPCIO),5,1) <> ''
UNION
SELECT I_TipoPeriodoID, TP.T_TipoPerDesc 
FROM TC_TipoPeriodo TP 
INNER JOIN cp_des CD3 ON TP.T_TipoPerDesc = LTRIM(SUBSTRING(LTRIM(CD3.DESCRIPCIO),5,LEN(CD3.DESCRIPCIO))) 
			AND ISNUMERIC(LTRIM(SUBSTRING(LTRIM(CD3.DESCRIPCIO),1,4))) = 0 
			AND SUBSTRING(LTRIM(CD3.DESCRIPCIO),5,1) <> ''




(SELECT DESCRIP AS T_TipoPerDesc FROM (
SELECT LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),5,LEN(DESCRIPCIO))) AS DESCRIP
FROM cp_des
WHERE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),1,4))) = 1 
	AND SUBSTRING(LTRIM(DESCRIPCIO),5,1) = ' '
UNION ALL
SELECT LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),5,LEN(DESCRIPCIO))) AS DESCRIP
FROM cp_des
WHERE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),1,4))) = 1 
	AND SUBSTRING(LTRIM(DESCRIPCIO),5,1) <> ''
UNION ALL
SELECT LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),5,LEN(DESCRIPCIO))) AS DESCRIP
FROM cp_des
WHERE ISNUMERIC(LTRIM(SUBSTRING(LTRIM(DESCRIPCIO),1,4))) = 0 
	AND SUBSTRING(LTRIM(DESCRIPCIO),5,1) <> ''
) CP_DES_DESC) CP_DES_DESC ON CP_DES_DESC.T_TipoPerDesc = TP.T_TipoPerDesc


/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/
-- Insertar cuenta depósito para tipos de periodo del temporal de pagos
/*-----------------------------------------------------------------------------------------------------------------------------------------------------------------*/

INSERT INTO TC_CuentaDeposito_TipoPeriodo (I_CtaDepositoID, I_TipoPeriodoID, B_Habilitado, B_Eliminado, I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod) 
									SELECT 1, I_TipoPeriodoID, 1, 0, NULL, NULL, NULL, NULL
									FROM	TC_TipoPeriodo


