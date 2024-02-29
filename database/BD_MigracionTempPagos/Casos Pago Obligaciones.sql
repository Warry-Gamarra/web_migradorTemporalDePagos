use BD_OCEF_TemporalPagos

select * from pregrado.ec_obl where ano = cast(2010 AS varchar)
select * from eupg.ec_obl where ano = cast(2010 AS varchar)
select * from euded.ec_obl where ano = cast(2010 AS varchar)


SELECT * FROM pregrado.ec_det WHERE  cod_alu = '2010002487'

-- QUE REGISTROS SE CONSIDERAN PAGOS DE OBLIGACIONES
-- pagado = 1 and concepto_f = 1 and cuota_pago <> 0 and concepto <> 0

--EUPG

select * from eupg.cp_pri where id_cp = 4817
select * from eupg.cp_pri where id_cp = 4818
select * from eupg.cp_pri where id_cp = 4788

DECLARE @recibo_pago int = 0
DECLARE @mora_pensiones int = 4788
DECLARE @mat_ext_ma_reg_2008 int = 4817
DECLARE @mat_ext_do_reg_2008 int = 4818

SELECT * FROM eupg.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 and concepto IN (@recibo_pago, @mora_pensiones, @mat_ext_ma_reg_2008, @mat_ext_do_reg_2008) 
SELECT distinct concepto FROM eupg.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 --and concepto <> 4788 and concepto <> 0
GO

--PREGRADO

select * from pregrado.cp_pri where id_cp = 6924

DECLARE @recibo_pago int = 0
DECLARE @deudas_anteriores_2017 int = 6924

SELECT * FROM pregrado.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 and concepto IN (@recibo_pago, @deudas_anteriores_2017) 
SELECT distinct concepto FROM pregrado.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 --and concepto <> 4788 and concepto <> 0
go

--EUDED
select * from euded.cp_pri where id_cp = 4788
select * from euded.cp_pri where id_cp = 304
select * from euded.cp_pri where id_cp = 301
select * from euded.cp_pri where id_cp = 300
select * from euded.cp_pri where id_cp = 54
select * from euded.cp_pri where id_cp = 6645
select * from euded.cp_pri where id_cp = 305

DECLARE @recibo_pago int = 0
DECLARE @mora_pensiones int = 4788
DECLARE @mat_2007_1 int = 304
DECLARE @pen_2007_1 int = 305
DECLARE @pen_2006_2 int = 301
DECLARE @mat_2006_2 int = 300
DECLARE @pen_2005_2 int = 54
DECLARE @pen_ing_2014_2 int = 6645


SELECT * FROM euded.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 and concepto IN (@recibo_pago, @mora_pensiones, @mat_2007_1, @mat_2006_2, @pen_2007_1, @pen_2006_2, @pen_2005_2, @pen_ing_2014_2) 
SELECT distinct concepto FROM euded.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 --and concepto <> 4788 and concepto <> 0






SELECT * FROM eupg.ec_det WHERE tipo_pago = 1 --352510
SELECT * FROM eupg.ec_det WHERE pagado = 1 and concepto_f = 1 and concepto = 0 --594820
SELECT * FROM eupg.ec_det WHERE pagado = 1 and concepto = 4788

select * from eupg.cp_pri where id_cp = 4817
select * from eupg.cp_pri where id_cp = 4818
select * from eupg.cp_pri where id_cp = 4788

SELECT distinct ano FROM eupg.ec_det WHERE pagado = 1 and concepto = 4788
SELECT distinct ano FROM eupg.ec_det WHERE pagado = 1 and concepto = 4818
SELECT distinct ano FROM eupg.ec_det WHERE pagado = 1 and concepto = 4817

SELECT distinct concepto FROM pregrado.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 --and concepto <> 4788 and concepto <> 0
SELECT distinct concepto FROM euded.ec_det WHERE pagado = 1 and concepto_f = 1 and cuota_pago <> 0 --and concepto <> 4788 and concepto <> 0

select * from pregrado.ec_det
where cod_alu = '2007019605' and cod_rc = '112' and cuota_pago = 355
and ano = '2017' and p = 'A' 

select * from euded.ec_det
where cod_alu = '2003701382' and cod_rc = 'E01' and cuota_pago = 34
and ano = '2006' and p = '2' 