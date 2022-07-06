USE BD_OCEF_MigracionTP
GO

CREATE PROCEDURE USP_IU_MigrarObligacionesAlumno
(
    @C_CodAlu   varchar(20),
    @C_Anio     varchar(4),
    @B_Resultado  bit output,
	@T_Message	  nvarchar(4000) OUTPUT	
)
AS
--declare @B_Resultado  bit,
--		@T_Message	  nvarchar(4000)
--exec USP_IU_MigrarObligacionesAlumno '2010002487', '2012', @B_Resultado output, @T_Message output
--select @B_Resultado as resultado, @T_Message as mensaje
BEGIN
    IF EXISTS (SELECT * FROM TR_Ec_Obl WHERE Cod_Alu = @C_CodAlu AND Ano = @C_Anio)
    BEGIN
		
        
    END
    ELSE
    BEGIN
        DECLARE @T_Sql          nvarchar(max)
        DECLARE @T_Procedencia  varchar(20)

        SET @T_Procedencia = (SELECT dbo.Func_T_ObtenerProcedenciaAlumno (@C_CodAlu, @C_Ano));

        SET @T_Sql = '';

        EXEC sp_executesql @T_Sql;
    END
    
END
GO


IF EXISTS (SELECT * FROM INFORMATION_SCHEMA.ROUTINES WHERE ROUTINE_TYPE = 'FUNCTION' AND ROUTINE_NAME = 'Func_T_ObtenerProcedenciaAlumno')
	DROP FUNCTION [dbo].[Func_T_ObtenerProcedenciaAlumno]
GO


CREATE FUNCTION Func_T_ObtenerProcedenciaAlumno
(
    @C_CodAlu   varchar(20),
    @C_Anio     varchar(4)
)
RETURNS VARCHAR(20)
AS
-- select dbo.Func_T_ObtenerProcedenciaAlumno ('2010002487', '2012')
BEGIN
    DECLARE @T_Procedencia  varchar(20);

    IF EXISTS (SELECT * FROM BD_OCEF_TemporalPagos.pregrado.ec_obl WHERE cod_alu = @C_CodAlu AND ano = @C_Anio)
    BEGIN
        SET @T_Procedencia = 'pregrado';
    END
    ELSE IF EXISTS (SELECT * FROM BD_OCEF_TemporalPagos.eupg.ec_obl WHERE cod_alu = @C_CodAlu AND ano = @C_Anio)
    BEGIN
        SET @T_Procedencia = 'eupg';
    END
    ELSE IF EXISTS (SELECT * FROM BD_OCEF_TemporalPagos.euded.ec_obl WHERE cod_alu = @C_CodAlu AND ano = @C_Anio)
    BEGIN
        SET @T_Procedencia = 'euded';
    END
    ELSE
    BEGIN
        SET @T_Procedencia = '';
    END

    RETURN @T_Procedencia;
END
GO


