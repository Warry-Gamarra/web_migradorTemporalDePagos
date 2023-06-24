USE BD_OCEF_MigracionTP
GO

INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (42, 'La cuota de pago del detalle no es la misma que la cuota de pago del concepto.', 'CUOTA PAGO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (43, 'El año del detalle no coincide con el año del concepto en cp_pri.', 'DIF. AÑO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (44, 'El periodo del detalle no coincide con el año del concepto en cp_pri.', 'DIF. PERIODO CP_PRI', NULL)
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (45, 'El registro se encuentra con estado Eliminado y no será parte de la migración.', 'REMOVIDO', NULL)


--cambio 20221212 
INSERT INTO TC_CatalogoObservacion (I_ObservID, T_ObservDesc, T_ObservCod, I_Severidad) VALUES (46, 'El concepto de pago contiene falso en el campo obligación.', 'NO OBLIGACION', NULL)


GO


UPDATE tb_obs
   SET tb_obs.I_ProcedenciaID = cp_des.I_ProcedenciaID
  FROM TI_ObservacionRegistroTabla tb_obs 
	   INNER JOIN TR_Cp_Des cp_des on cp_des.I_RowID = tb_obs.I_FilaTablaID AND tb_obs.I_TablaID = 2
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





--CAMBIOS 20230514
--Eliminar migracion de obligaciones en ctas por cobrar
BEGIN TRANSACTION DEL_OBL_MIGRATION;
BEGIN TRY
	DELETE cabecera_obligaciones  
	FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab cabecera_obligaciones
		 LEFT JOIN BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluDet detalle_obligaciones 
				   ON cabecera_obligaciones.I_ObligacionAluID = detalle_obligaciones.I_ObligacionAluID
		 WHERE cabecera_obligaciones.B_Migrado = 1 AND detalle_obligaciones.I_ObligacionAluID IS NULL
	
	DELETE matricula_alumno
	FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno matricula_alumno
		 
		 WHERE matricula_alumno.B_Migrado = 1
	
	DECLARE @I_ObligacionAluID int,
			@I_MatAluID int

	SET @I_MatAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno');
	SET @I_ObligacionAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab');
	SELECT @I_MatAluID AS 'TC_MatriculaAlumno', @I_ObligacionAluID AS 'TR_ObligacionAluCab'


	SET @I_MatAluID = (SELECT MAX(I_MatAluID) FROM BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno);
	SET @I_ObligacionAluID = (SELECT MAX(I_ObligacionAluID) FROM BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab);

	DBCC CHECKIDENT('BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno', 'RESEED', @I_MatAluID)
	DBCC CHECKIDENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab', 'RESEED', @I_ObligacionAluID)


	SET @I_MatAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TC_MatriculaAlumno');
	SET @I_ObligacionAluID = IDENT_CURRENT('BD_OCEF_CtasPorCobrar.dbo.TR_ObligacionAluCab');
	SELECT @I_MatAluID AS 'TC_MatriculaAlumno', @I_ObligacionAluID AS 'TR_ObligacionAluCab'

	COMMIT TRANSACTION DEL_OBL_MIGRATION;
END TRY
BEGIN CATCH
	ROLLBACK TRANSACTION DEL_OBL_MIGRATION;
END CATCH
GO
