USE BD_OCEF_MigracionTP
GO


INSERT INTO TC_CatalogoTabla(I_TablaID, T_TablaNom) VALUES (7, 'TR_Ec_Det_Pagos')
GO


UPDATE TC_CatalogoObservacion SET I_TablaID = 1  WHERE I_ObservID IN (1, 2, 21, 22, 23, 30, 31, 41, 47, 48)
UPDATE TC_CatalogoObservacion SET I_TablaID = 2  WHERE I_ObservID IN (3, 4, 5, 6, 7, 8, 9, 10, 11)
UPDATE TC_CatalogoObservacion SET I_TablaID = 3  WHERE I_ObservID IN (12, 13, 14, 16, 18, 19, 20, 46)
UPDATE TC_CatalogoObservacion SET I_TablaID = 4  WHERE I_ObservID IN (15, 17, 25, 33, 35, 42, 43, 44)
UPDATE TC_CatalogoObservacion SET I_TablaID = 5  WHERE I_ObservID IN (24, 26, 27, 28, 29, 32, 34, 36, 37, 38, 39, 40, 49)
GO

/*
	Actualización de descripción de observaciones
*/


UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'Año del concepto en el detalle no coincide con año del concepto en cp_pri'
 WHERE I_ObservID = 43
GO

UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'Periodo del concepto en el detalle no coincide con periodo del concepto en cp_pri'
 WHERE I_ObservID = 44
GO

UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'El año del concepto en el detalle de la obligación no coincide con el año del concepto en cp_pri'
 WHERE I_ObservID = 15
GO

UPDATE TC_CatalogoObservacion
   SET T_ObservDesc = 'El periodo del concepto en el detalle de la obligación. no coincide con el periodo del concepto en cp_pri.'
 WHERE I_ObservID = 17
GO

/*
	Observaciones para tabla de cp_des, ec_obl y ec_det
*/

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (49, 'El monto acumulado de los conceptos en el detalle no corresponde con el monto indicado en la obligación', 'ERROR MONTO', NULL, 4)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (50, 'La cuota de pago existe repetida en otra procedenca', 'REPETIDO', NULL, 2)


/*
	Observaciones para tabla de pagos detalle
*/

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (53, 'El monto pagado no corresponde con los conceptos relacionados en el detalle', 'ERROR MONTO', NULL, 7)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (52, 'No se pudo asociar una obligaciòn con el pago registrado', 'SIN OBLIGACION', NULL, 7)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (55, 'Se encontró un pago para la misma obligación con una entidad diferente en la BD destino.', 'OTRO BANCO', NULL, 7)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (54, 'Se encontró un pago para una obligación con estado Pagado = NO', 'ERROR ESTADO', NULL, 5)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (56, 'El pago tiene observaciones de conceptos en el detalle.', 'OBSERVACIÓN DETALLE', NULL, 7)


GO

--ACTUALIZACION 2024-05-25

/*
	Observaciones para tabla de pagos detalle
*/

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad, I_TablaID) VALUES (57, 'El pago tiene observaciones en la cabecera de la obligacion.', 'OBSERVACIÓN OBLIG.', NULL, 7)


/*
	Nueva procedemcia para datos de alumnos sin obligaciones
*/

INSERT INTO TC_ProcedenciaData (I_ProcedenciaID, T_ProcedenciaDesc) VALUES (5, 'INDEFINIDO')
GO

/*
	Agregar datos a nueva tabla de carreras
*/

INSERT INTO TC_CarreraProcedencia (C_RcCod, T_CarreraNom, I_ProcedenciaID)
							SELECT C_RcCod, T_CarProfDesc,
								   CASE N_Grado
								   WHEN 1 THEN IIF(C_CodFac = 'ET', 3, 1)
								   WHEN 2 THEN IIF(C_CodFac = 'EP', 2, NULL)
								   WHEN 3 THEN IIF(C_CodFac = 'EP', 2, NULL)
								   ELSE 5 END
							  FROM BD_UNFV_Repositorio.dbo.TI_CarreraProfesional
GO
 
/*
	Actualizar estado de alumno con o sin obligacion
*/

UPDATE TR_Alumnos SET B_ObligProc = 1
GO

/*
	Actualizar estado de procedencia con obligacion o sin obligacion para la observacion
*/

UPDATE TR_Alumnos SET B_ObligProc = 1
GO



SELECT * INTO ##TEMP_ECOBL FROM TR_Ec_Obl WHERE B_Actualizado = 1
SELECT * INTO ##TEMP_ECDET FROM TR_Ec_Det WHERE B_Actualizado = 1

TRUNCATE TABLE TR_Ec_Det_Pagos
TRUNCATE TABLE TR_Ec_Det

DELETE dbo.TI_ObservacionRegistroTabla where I_TablaID in (4,5,7)
DECLARE @I_ObsTablaID INT = (SELECT MAX(I_ObsTablaID) FROM TI_ObservacionRegistroTabla)
DBCC CHECKIDENT('TI_ObservacionRegistroTabla', 'RESEED', @I_ObsTablaID)


DELETE TR_Ec_Obl
DBCC CHECKIDENT('TR_Ec_Obl', 'Reseed', 0)

