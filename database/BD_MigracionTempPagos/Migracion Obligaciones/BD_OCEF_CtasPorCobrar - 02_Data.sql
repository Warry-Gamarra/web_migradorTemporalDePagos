USE [BD_OCEF_CtasPorCobrar]
GO


IF OBJECT_ID('tempdb..##TEMP_DEL_ConstanciaPago') IS NULL
BEGIN

	CREATE TABLE ##TEMP_DEL_ConstanciaPago
	(	
		I_ConstanciaPagoID  int NOT NULL,
		I_PagoBancoID		int NOT NULL,
		I_AnioConstancia	int NOT NULL,
		I_NroConstancia		int NOT NULL,
		I_UsuarioCre		int NOT NULL,
		D_FecCre			datetime  NOT NULL,
	)
		
END
GO

IF OBJECT_ID('tempdb..##TEMP_DEL_PagoBanco') IS NULL
BEGIN

	CREATE TABLE ##TEMP_DEL_PagoBanco
	(	
		I_PagoBancoID		int NOT NULL,
		I_EntidadFinanID	int NOT NULL,
		C_CodOperacion		varchar(50)  NULL,
		C_CodDepositante	varchar(20)  NULL,
		T_NomDepositante	varchar(200)  NULL,
		C_Referencia		varchar(50)  NULL,
		D_FecPago			datetime  NULL,
		I_Cantidad			int  NULL,
		C_Moneda			varchar(3)  NULL,
		I_MontoPago			decimal(15, 2)  NULL,
		T_LugarPago			varchar(250)  NULL,
		B_Anulado			bit  NOT NULL,
		I_Usuariocre		int  NULL,
		D_FecCre			datetime  NULL,
		T_Observacion		varchar(250)  NULL,
		T_InformacionAdicional varchar(max)  NULL,
		I_CondicionPagoID	int  NOT NULL,
		I_TipoPagoID		int  NOT NULL,
		I_CtaDepositoID		int  NOT NULL,
		I_InteresMora		decimal(15, 2)  NOT NULL,
		T_MotivoCoreccion	varchar(250)  NULL,
		I_UsuarioMod		int  NULL,
		D_FecMod			datetime  NULL,
		C_CodigoInterno		varchar(250) NULL,
		I_ProcesoIDArchivo	int NULL,
		T_ProcesoDescArchivo varchar(250) NULL,
		D_FecVenctoArchivo	date NULL,
		B_Migrado			bit NULL,
		I_MigracionTablaID	int NULL,
		I_MigracionRowID	int NULL
	)

END
GO

IF OBJECT_ID('tempdb..##TEMP_DEL_PagoProcesadoUnfv') IS NULL
BEGIN
	CREATE TABLE ##TEMP_DEL_PagoProcesadoUnfv(
		I_PagoProcesID			int NOT NULL,
		I_PagoBancoID			int NOT NULL,
		I_CtaDepositoID			int NULL,
		I_TasaUnfvID			int NULL,
		I_MontoPagado			decimal(15, 2) NULL,
		I_SaldoAPagar			decimal(15, 2) NULL,
		I_PagoDemas				decimal(15, 2) NULL,
		B_PagoDemas				bit NULL,
		N_NroSIAF				int NULL,
		B_Anulado				bit NOT NULL,
		D_FecCre				datetime NULL,
		I_UsuarioCre			int NULL,
		D_FecMod				datetime NULL,
		I_UsuarioMod			int NULL,
		I_ObligacionAluDetID	int NULL,
		B_Migrado				bit NULL,
		I_MigracionTablaID		int NULL,
		I_MigracionRowID		int NULL
	)
END
GO

IF OBJECT_ID('tempdb..##TEMP_DEL_ObligacionAluDet') IS NULL
BEGIN
	CREATE TABLE ##TEMP_DEL_ObligacionAluDet(
		I_ObligacionAluDetID	int NOT NULL,
		I_ObligacionAluID		int NOT NULL,
		I_ConcPagID				int NOT NULL,
		I_Monto					decimal(15, 2) NULL,
		B_Pagado				bit NOT NULL,
		D_FecVencto				date NOT NULL,
		I_TipoDocumento			int NULL,
		T_DescDocumento			varchar(max) NULL,
		B_Habilitado			bit NOT NULL,
		B_Eliminado				bit NOT NULL,
		I_UsuarioCre			int NULL,
		D_FecCre				datetime NULL,
		I_UsuarioMod			int NULL,
		D_FecMod				datetime NULL,
		B_Mora					bit NOT NULL,
		B_Migrado				bit NULL,
		I_MigracionTablaID		int NULL,
		I_MigracionRowID		int NULL,
	)
END
GO

IF OBJECT_ID('tempdb..##TEMP_DEL_ObligacionAluCab') IS NULL
BEGIN
	CREATE TABLE ##TEMP_DEL_ObligacionAluCab (
		I_ObligacionAluID	int NOT NULL,
		I_ProcesoID			int NULL,
		I_MatAluID			int NULL,
		C_Moneda			varchar(3) NULL,
		I_MontoOblig		decimal(15, 2) NULL,
		D_FecVencto			date NULL,
		B_Pagado			bit NULL,
		B_Habilitado		bit NOT NULL,
		B_Eliminado			bit NOT NULL,
		I_UsuarioCre		int NULL,
		D_FecCre			datetime NULL,
		I_UsuarioMod		int NULL,
		D_FecMod			datetime NULL,
		B_Migrado			bit NULL,
		I_MigracionTablaID	int NULL,
		I_MigracionRowID	int NULL
	)
END
GO

INSERT INTO ##TEMP_DEL_ConstanciaPago (I_ConstanciaPagoID, I_PagoBancoID, I_AnioConstancia, I_NroConstancia, I_UsuarioCre, D_FecCre)
							 SELECT CP.I_ConstanciaPagoID, CP.I_PagoBancoID, CP.I_AnioConstancia, CP.I_NroConstancia, CP.I_UsuarioCre, CP.D_FecCre
							   FROM TR_ConstanciaPago CP
									INNER JOIN TR_PagoBanco PB ON CP.I_PagoBancoID = PB.I_PagoBancoID
							  WHERE ISNULL(PB.I_MigracionRowID, 0) > 0 
GO

INSERT INTO ##TEMP_DEL_PagoBanco (I_PagoBancoID, I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago,  
								  B_Anulado, I_UsuarioCre, D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora, T_MotivoCoreccion, 
								  I_UsuarioMod, D_FecMod, C_CodigoInterno, I_ProcesoIDArchivo, T_ProcesoDescArchivo, D_FecVenctoArchivo, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
						  SELECT PB.I_PagoBancoID, I_EntidadFinanID, C_CodOperacion, C_CodDepositante, T_NomDepositante, C_Referencia, D_FecPago, I_Cantidad, C_Moneda, I_MontoPago, T_LugarPago, 
								 B_Anulado, PB.I_UsuarioCre, PB.D_FecCre, T_Observacion, T_InformacionAdicional, I_CondicionPagoID, I_TipoPagoID, I_CtaDepositoID, I_InteresMora, T_MotivoCoreccion, 
								 I_UsuarioMod, D_FecMod, C_CodigoInterno, I_ProcesoIDArchivo, T_ProcesoDescArchivo, D_FecVenctoArchivo, B_Migrado, I_MigracionTablaID, I_MigracionRowID
							FROM TR_PagoBanco PB
								 INNER JOIN ##TEMP_DEL_ConstanciaPago TMP ON PB.I_PagoBancoID = TMP.I_PagoBancoID
								
GO
--219801
INSERT INTO ##TEMP_DEL_PagoProcesadoUnfv (I_PagoProcesID, I_PagoBancoID, I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, B_Anulado, D_FecCre, 
										  I_UsuarioCre, D_FecMod, I_UsuarioMod, I_ObligacionAluDetID, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
								SELECT I_PagoProcesID, PP.I_PagoBancoID, PP.I_CtaDepositoID, I_TasaUnfvID, I_MontoPagado, I_SaldoAPagar, I_PagoDemas, B_PagoDemas, N_NroSIAF, PP.B_Anulado, PP.D_FecCre, 
										PP.I_UsuarioCre, PP.D_FecMod, PP.I_UsuarioMod, I_ObligacionAluDetID, PP.B_Migrado, PP.I_MigracionTablaID, PP.I_MigracionRowID
								  FROM TRI_PagoProcesadoUnfv PP 
								       INNER JOIN ##TEMP_DEL_PagoBanco TMP ON PP.I_PagoBancoID = TMP.I_PagoBancoID
GO

INSERT INTO ##TEMP_DEL_ObligacionAluDet (I_ObligacionAluDetID, I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, 
										 I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod, B_Mora, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
								 SELECT D.I_ObligacionAluDetID, I_ObligacionAluID, I_ConcPagID, I_Monto, B_Pagado, D_FecVencto, I_TipoDocumento, T_DescDocumento, B_Habilitado, B_Eliminado, 
										D.I_UsuarioCre, D.D_FecCre, D.I_UsuarioMod, D.D_FecMod, B_Mora, D.B_Migrado, D.I_MigracionTablaID, D.I_MigracionRowID
								   FROM TR_ObligacionAluDet D 
										INNER JOIN ##TEMP_DEL_PagoProcesadoUnfv PP ON D.I_ObligacionAluDetID = PP.I_ObligacionAluDetID
GO

INSERT INTO ##TEMP_DEL_ObligacionAluCab (I_ObligacionAluID, I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, D_FecVencto, B_Pagado, B_Habilitado, B_Eliminado, 
										 I_UsuarioCre, D_FecCre, I_UsuarioMod, D_FecMod, B_Migrado, I_MigracionTablaID, I_MigracionRowID)
								 SELECT  C.I_ObligacionAluID, I_ProcesoID, I_MatAluID, C_Moneda, I_MontoOblig, C.D_FecVencto, C.B_Pagado, C.B_Habilitado, C.B_Eliminado, 
										 C.I_UsuarioCre, C.D_FecCre, C.I_UsuarioMod, C.D_FecMod, C.B_Migrado, C.I_MigracionTablaID, C.I_MigracionRowID
								   FROM  TR_ObligacionAluCab C
										 INNER JOIN ##TEMP_DEL_ObligacionAluDet TD ON C.I_ObligacionAluID = TD.I_ObligacionAluID
GO


DELETE FROM TR_ConstanciaPago 
	  WHERE I_ConstanciaPagoID IN (SELECT I_ConstanciaPagoID FROM ##TEMP_DEL_ConstanciaPago)


DELETE FROM TR_PagoBanco WHERE ISNULL(I_MigracionRowID, 0) > 0 
DELETE FROM TR_PagoBanco 
	  WHERE I_PagoBancoID IN (SELECT I_PagoBancoID FROM ##TEMP_DEL_PagoBanco)


DELETE FROM TRI_PagoProcesadoUnfv WHERE ISNULL(I_MigracionRowID, 0) > 0 
DELETE FROM TRI_PagoProcesadoUnfv 
	  WHERE I_ObligacionAluDetID IN (SELECT I_ObligacionAluDetID 
									   FROM TR_ObligacionAluDet 
									  WHERE I_ObligacionAluID IN (SELECT DISTINCT I_ObligacionAluID 
																	FROM TR_ObligacionAluCab 
																   WHERE ISNULL(I_MigracionRowID, 0) > 0 
																 )
									)



DELETE FROM TR_ObligacionAluDet WHERE ISNULL(I_MigracionRowID, 0) > 0 
DELETE FROM TR_ObligacionAluDet 
WHERE I_ObligacionAluID IN (SELECT DISTINCT I_ObligacionAluID FROM TR_ObligacionAluCab 
							WHERE ISNULL(I_MigracionRowID, 0) > 0 )


DELETE FROM TR_ObligacionAluCab WHERE ISNULL(I_MigracionRowID, 0) > 0 

