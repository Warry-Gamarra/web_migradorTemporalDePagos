
USE [BD_OCEF_MigracionTP]
GO


DELETE TI_ObservacionRegistroTabla WHERE I_TablaID = 5

DECLARE @I_MAX_ObsTablaID bigint 
SET @I_MAX_ObsTablaID = (SELECT max(I_ObsTablaID) + 1 FROM TI_ObservacionRegistroTabla)

DBCC CHECKIDENT('TI_ObservacionRegistroTabla', RESEED, @I_MAX_ObsTablaID)

SELECT IDENT_CURRENT('TI_ObservacionRegistroTabla')
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_TYPE = 'BASE TABLE' AND TABLE_NAME = 'TC_CarreraProfesionalProcedencia')
	DROP TABLE TC_CarreraProfesionalProcedencia
GO

CREATE TABLE TC_CarreraProfesionalProcedencia
(
	C_CodRc  varchar(3),
	I_ProcedenciaID tinyint,
	T_Descripcion  varchar(100),
	N_Grado char(1),
	CONSTRAINT PK_CarreraProfesionalProcedencia PRIMARY KEY (C_CodRc),
	CONSTRAINT PK_CarreraProfesionalProcedencia_Procedencia FOREIGN KEY (I_ProcedenciaID) REFERENCES TC_ProcedenciaData(I_ProcedenciaID)
)
GO




--cambio 20230116

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (47, 'El valor del campo <Sexo> prensenta valores distintos para misma persona en la base de destino', 'SEXO ERRADO', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (48, 'El valor del campo <DNI> prensenta valores distintos para el mismo código de alumno', 'DNI ERRADO', NULL)

DECLARE @I_ProcedenciaID tinyint = 0

--PREGRADO
SET @I_ProcedenciaID = 1
INSERT INTO TC_CarreraProfesionalProcedencia (C_CodRc, I_ProcedenciaID, T_Descripcion, N_Grado)
	 SELECT C_RcCod, @I_ProcedenciaID, T_CarProfDesc, N_Grado FROM BD_UNFV_Repositorio.dbo.VW_CarreraProfesional
	  WHERE N_Grado = 1 AND C_CodFac <> 'ET'

--POSGRADO
SET @I_ProcedenciaID = 2
INSERT INTO TC_CarreraProfesionalProcedencia (C_CodRc, I_ProcedenciaID, T_Descripcion, N_Grado)
	 SELECT C_RcCod, @I_ProcedenciaID, T_CarProfDesc, N_Grado FROM BD_UNFV_Repositorio.dbo.VW_CarreraProfesional
	  WHERE N_Grado IN (2, 3)


--CUDED
SET @I_ProcedenciaID = 3
INSERT INTO TC_CarreraProfesionalProcedencia (C_CodRc, I_ProcedenciaID, T_Descripcion, N_Grado)
	 SELECT C_RcCod, @I_ProcedenciaID, T_CarProfDesc, N_Grado FROM BD_UNFV_Repositorio.dbo.VW_CarreraProfesional
	  WHERE N_Grado = 1 AND C_CodFac = 'ET'


