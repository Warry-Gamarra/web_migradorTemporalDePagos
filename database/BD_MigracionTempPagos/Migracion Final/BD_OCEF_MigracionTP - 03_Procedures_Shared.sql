/*
====================================================
	BD_OCEF_MigracionTP - 03_Procedures_Shared
====================================================
*/

USE BD_OCEF_MigracionTP
GO

IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Shared_ControlTabla_MigracionTP_IU_RegistrarCopiados')
	DROP PROCEDURE [dbo].[USP_Shared_ControlTabla_MigracionTP_IU_RegistrarCopiados]
GO

CREATE PROCEDURE dbo.USP_Shared_ControlTabla_MigracionTP_IU_RegistrarCopiados
(
	@I_TablaID		  tinyint,
	@I_ProcedenciaID  tinyint,
	@I_Anio			  smallint,
	@I_ValueToDo	  int = null,
	@I_ValueDone	  int,
	@I_ValueProgress  int,
	@D_FecProceso	  datetime
)
/*
	DECLARE @I_TablaID		  tinyint = 2,
			@I_ProcedenciaID  tinyint = 1,
			@I_Anio			  smallint = 0,
			@I_ValueToDo	  int = 500,
			@I_ValueDone	  int = 450,
			@I_ValueProgress  int = 50,
			@D_FecProceso	  datetime = GETDATE()
	EXEC USP_Shared_ControlTabla_MigracionTP_IU_RegistrarCopiados @I_TablaID, @I_ProcedenciaID, @I_Anio, @I_ValueToDo, @I_ValueDone, @I_ValueProgress, @D_FecProceso
	SELECT * FROM TR_ControlTablas WHERE I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID AND I_CurrentEtapaID = 1 AND B_Habilitado = 1
*/
AS
BEGIN
	/*
		1	Copia de datos
		2	Validacion de consistencia
		3	Migracion a Recaudación de Ingresos
	*/

	DECLARE @I_CurrentEtapaID tinyint = 1
	DECLARE @I_ControlID int 
	SET @I_ControlID = (SELECT I_ControlID FROM TR_ControlTablas 
						 WHERE I_TablaID = @I_TablaID 
							   AND I_ProcedenciaID = @I_ProcedenciaID 
							   AND B_Habilitado = 1
					   )

	IF (@I_ControlID IS NOT NULL)
	BEGIN
		UPDATE TR_ControlTablas
		   SET B_Habilitado = 0
		 WHERE I_ControlID = @I_ControlID
	END

	INSERT INTO TR_ControlTablas (I_TablaID, I_ProcedenciaID, I_Anio, I_CurrentEtapaID, I_TotalCopiar, I_CountCopiados, I_CountSnCopiar, D_LastCopia)
						  VALUES (@I_TablaID, @I_ProcedenciaID, @I_Anio, @I_CurrentEtapaID, @I_ValueToDo, @I_ValueDone, @I_ValueProgress, @D_FecProceso)


END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Shared_ControlTabla_MigracionTP_IU_RegistrarValidacion')
	DROP PROCEDURE [dbo].[USP_Shared_ControlTabla_MigracionTP_IU_RegistrarValidacion]
GO

CREATE PROCEDURE dbo.USP_Shared_ControlTabla_MigracionTP_IU_RegistrarValidacion
(
	@I_TablaID		  tinyint,
	@I_ProcedenciaID  tinyint,
	@I_ValueToDo	  int,
	@I_ValueDone	  int,
	@I_ValueProgress  int,
	@D_FecProceso	  datetime
)
/*
	DECLARE @I_TablaID		  tinyint = 2,
			@I_ProcedenciaID  tinyint = 1,
			@I_ValueToDo	  int = 450,
			@I_ValueDone	  int = 420,
			@I_ValueProgress  int = 30,
			@D_FecProceso	  datetime = GETDATE()
	EXEC USP_Shared_ControlTabla_MigracionTP_IU_RegistrarValidacion @I_TablaID, @I_ProcedenciaID, @I_ValueToDo, @I_ValueDone, @I_ValueProgress, @D_FecProceso
	SELECT * FROM TR_ControlTablas WHERE I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID AND I_CurrentEtapaID = 2 AND B_Habilitado = 1
*/
AS
BEGIN
	/*
		1	Copia de datos
		2	Validacion de consistencia
		3	Migracion a Recaudación de Ingresos
	*/

	DECLARE @I_CurrentEtapaID tinyint = 2
	DECLARE @I_OldEtapaID tinyint = 1
	DECLARE @I_ControlID int 

	SET @I_ControlID = (SELECT I_ControlID FROM TR_ControlTablas 
						 WHERE I_TablaID = @I_TablaID 
							   AND I_ProcedenciaID = @I_ProcedenciaID 
							   AND I_CurrentEtapaID = @I_OldEtapaID
							   AND B_Habilitado = 1
						)

	UPDATE TR_ControlTablas
		SET I_TotalValidar = @I_ValueToDo, 
		    I_CurrentEtapaID = @I_CurrentEtapaID,
			I_CountValidados = @I_ValueDone, 
			I_CountSnValidar= @I_ValueProgress, 
			D_LastValidacion = @D_FecProceso
	  WHERE I_ControlID = @I_ControlID

END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'PROCEDURE' AND ROUTINE_NAME = 'USP_Shared_ControlTabla_MigracionTP_IU_RegistrarMigracion')
	DROP PROCEDURE [dbo].[USP_Shared_ControlTabla_MigracionTP_IU_RegistrarMigracion]
GO

CREATE PROCEDURE dbo.USP_Shared_ControlTabla_MigracionTP_IU_RegistrarMigracion
(
	@I_TablaID		  tinyint,
	@I_ProcedenciaID  tinyint,
	@I_ValueToDo	  int,
	@I_ValueDone	  int,
	@I_ValueProgress  int,
	@D_FecProceso	  datetime
)
/*
	DECLARE @I_TablaID		  tinyint = 2,
			@I_ProcedenciaID  tinyint = 1,
			@I_ValueToDo	  int = 420,
			@I_ValueDone	  int = 400,
			@I_ValueProgress  int = 20,
			@D_FecProceso	  datetime = GETDATE()
	EXEC USP_Shared_ControlTabla_MigracionTP_IU_RegistrarMigracion @I_TablaID, @I_ProcedenciaID, @I_ValueToDo, @I_ValueDone, @I_ValueProgress, @D_FecProceso
	SELECT * FROM TR_ControlTablas WHERE I_TablaID = @I_TablaID AND I_ProcedenciaID = @I_ProcedenciaID AND I_CurrentEtapaID = 3 AND B_Habilitado = 1
*/
AS
BEGIN
	/*
		1	Copia de datos
		2	Validacion de consistencia
		3	Migracion a Recaudación de Ingresos
	*/

	DECLARE @I_CurrentEtapaID tinyint = 3
	DECLARE @I_OldEtapaID tinyint = 2
	DECLARE @I_ControlID int 

	SET @I_ControlID = (SELECT I_ControlID FROM TR_ControlTablas 
						 WHERE I_TablaID = @I_TablaID 
							   AND I_ProcedenciaID = @I_ProcedenciaID 
							   AND I_CurrentEtapaID = @I_OldEtapaID
							   AND B_Habilitado = 1
						)

	UPDATE TR_ControlTablas
	   SET I_TotalMigrar = @I_ValueToDo,
		   I_CurrentEtapaID = @I_CurrentEtapaID,
		   I_CountMigrados = @I_ValueDone, 
		   I_CountSnMigrar = @I_ValueProgress, 
		   D_LastMigracion = @D_FecProceso
	 WHERE I_ControlID = @I_ControlID

END
GO



