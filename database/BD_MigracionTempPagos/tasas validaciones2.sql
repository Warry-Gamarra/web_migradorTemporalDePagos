use BD_OCEF_TemporalTasas
go

-- Las tasas no deberían tener registros en ec_obl
-- Existen 2 registros en ec_obl con tipo_obl 0 pero no tienen detalle No se pueden migrar
select * from ec_obl where tipo_oblig = 0

select * from ec_det where ano = '2005' and p = 'A' and tipo_oblig = 0 and cod_alu = '' and cod_rc = ''
select * from ec_det where ano = '2008' and p = '1' and cod_alu = '2001332202' and cod_rc = 'M47' -- la cuota de pago es de obligacion - Debe estar dentro de los registros de obligacion

-- cuota de pago 155 es cuota de pago de obligacion debe sus registros en la bd de tasas deben pasar como obligacion 

-- Cantidad total de registros en ec_obl => 680802
select count(*) from ec_obl

-- cantidad de registros obl con tipo_oblig = 1 => 680800
select count(*) from ec_obl where tipo_oblig = 1

-- cantidad de registros ec_obl con tipo_oblig = 0 => 2
select count(*) from ec_obl where tipo_oblig = 0

-- cantidad de registros en ec_obl con tipo_oblig = 1 con cuota_pago de Tasas => 1 (corregir tipo)
select * from ec_obl 
where cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)
	  and tipo_oblig = 1

select count(*) from ec_obl 
where cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)
	  and tipo_oblig = 1


-- Los pagos de tasa solo tienen un registro por el pago con el codigo de concepto de pago y el monto
-- En el campo cod_alu va el codigo del depositante, asi que puede ir tanto un dni como el codigo de alumno
-- cantidad de registros en ec_det con tipo_oblig = 1 con cuota_pago de Tasas = 1 => 8384 corregir tipo
select * from ec_det 
where cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)
	  and tipo_oblig = 1

select distinct cuota_pago, COUNT(cuota_pago) from ec_det 
where cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)
	  and tipo_oblig = 1
group by cuota_pago 

select count(*) from ec_det 
where cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)
	  and tipo_oblig = 1

-- Registros en ec_det con cuota_pago = 0 => 2342182
select count(*) from ec_det 
where cuota_pago = 0

-- Registros en ec_det con cuota_pago = vacio => 0
select count(*) from ec_det 
where cast(cuota_pago as varchar) = ''

-- Registros en ec_det con cuota_pago IS null => 0
select count(*) from ec_det 
where cuota_pago is null

-- Registro en ec_det con cuota_pago <> 0 => 8384 (Todos los pagos de tasas están con tipo_oblig = 1)
select count(*) from ec_det 
where cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155)





select  * from ec_det where cod_alu = '2010002487'
select  * from ec_det where cod_alu = ''
select * from ec_det 
where cuota_pago in (select cuota_pago from cp_des where codigo_bnc = '' and cuota_pago <> 155) order by cod_alu, cuota_pago, monto








select * from ec_obl where cod_alu = '46000113'


