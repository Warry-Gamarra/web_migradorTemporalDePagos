USE BD_OCEF_MigracionTP
GO

INSERT INTO TC_ProcedenciaData (I_ProcedenciaID, T_ProcedenciaDesc) VALUES (1, 'PREGRADO')
INSERT INTO TC_ProcedenciaData (I_ProcedenciaID, T_ProcedenciaDesc) VALUES (2, 'POSGRADO')
INSERT INTO TC_ProcedenciaData (I_ProcedenciaID, T_ProcedenciaDesc) VALUES (3, 'CUDED')
INSERT INTO TC_ProcedenciaData (I_ProcedenciaID, T_ProcedenciaDesc) VALUES (4, 'GLOBAL')


INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (1, 'El nombre de alumno tiene caracteres extraños', 'CARACTERES', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (2, 'La combinación código de carrera + código de alumno se encuentran repetidos', 'REPETIDO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (22, 'El codigo de alumno no cuenta con año de ingreso.', 'SIN AÑO INGRESO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (21, 'No se encontró código de carrera asociado en la base de datos de repositorio.', 'SIN CARRERA', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (23, 'No se encontró código de modalidad de ingreso asociado en la base de datos de repositorio.', 'SIN MOD. INGRESO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (30, 'El valor del campo <Número Documento> prensenta valores diferentes para apellidos y/o nombres', 'DNI REPETIDO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (31, 'El valor del campo <Sexo> prensenta valores diferentes para misma persona en filas diferentes', 'SEXO ERRADO', NULL)

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (3, 'La cuota de pago se encuentra repetida con estado ACTIVO', 'REPETIDO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (4, 'La cuota de pago se encuentra repetida con estado ELIMINADO', 'REPETIDO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (5, 'La cuota de pago presenta más de un año asociado en las tablas cp_pri o ec_det.', '1+ AÑOS', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (6, 'La cuota de pago no presenta año asociado en las tablas cp_pri o ec_det', '0 AÑOS', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (7, 'La cuota de pago presenta más de un periodo asociado en la tabla cp_pri', '1+ PERIODOS', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (8, 'La cuota de pago no presenta un periodo asociado en la tabla cp_pri.', '0 PERIODOS', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (9, 'La cuota de pago presenta más de una categoría según codBanco', '1+ CATEGORIAS', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (10, 'La cuota de pago no presenta una categoria asociada según codigo_bnc.', '0 CATEGORIAS', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (11, 'La cuota de pago ha sido ingresada o modificada desde una fuente externa.', 'EXTERNO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (12, 'El concepto de pago se encuentra repetido con estado ACTIVO', 'REPETIDO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (13, 'El concepto de pago se encuentra repetido con estado ELIMINADO', 'REPETIDO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (14, 'Concepto de pago de obligacion sin año asignado', '0 AÑOS', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (15, 'Año del concepto de pago de obligacion no coincide con el año de la cuota de pagos.', 'NO COINCIDE AÑO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (16, 'Concepto de pago de obligacion sin periodo.', '0 PERIODO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (17, 'Periodo deñ Concepto de pago de obligacion no coincide con el periodo de la cuota de pagos.', 'NO COINCIDE PERIODO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (18, 'Concepto de pago de obligacion sin cuota de pago.', 'SIN CUOTA', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (19, 'La cuota de pago asociada no fue migrada.', 'SIN CUOTA MIGRADA', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (20, 'El concepto de pago ha sido ingresado o modificado desde una fuente externa.', 'EXTERNO', NULL)


INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (24, 'No se encontró un alumno para el codigo de alumno y carrera de la obligación.', 'SIN ALUMNO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (25, 'La obligación correspondiente no ha sido migrada por errores en validación.', 'SIN OBLIGACION', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (26, 'El AÑO de la obligacion no es un valor válido.', 'AÑO NO VALIDO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (27, 'El PERIODO de la obligacion no tiene equivalencia en base de datos de Ctas por cobrar.', 'SIN PERIODO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (28, 'La fecha de vencimiento se encuentra repetida para la misma cuota de pago y codigo de alumno.', 'SIN PERIODO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (29, 'La obligación ya existe en la base de datos de destino con otro monto.', 'EXISTE', NULL)


INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (32, 'La obligación tiene una cuota de pago sin migrar.', 'SIN CUOTA DE PAGO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (33, 'El detalle de pago tiene un concepto de pago sin migrar.', 'SIN CONCEPTO DE PAGO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (34, 'La procedencia de la obligación no coincide con la procedencia de la cuota de pago.', 'SIN CUOTA DE PAGO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (35, 'El concepto en el detalle de la obligación no existe en el catálogo de conceptos.', 'SIN CONCEPTO DE PAGO', NULL)



INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (1, 'TR_Alumnos')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (2, 'TR_Cp_Des')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (3, 'TR_Cp_Pri')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (4, 'TR_Ec_Det')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (5, 'TR_Ec_Obl')
INSERT INTO TC_CatalogoTabla (I_TablaID, T_TablaNom) VALUES (6, 'TR_Ec_Pri')


