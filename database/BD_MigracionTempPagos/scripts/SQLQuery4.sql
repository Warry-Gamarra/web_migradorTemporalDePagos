select *
from
(select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from EUPG_ec_obl obl
	 inner join EUPG_cp_des cp on cp.cuota_pago = obl.cuota_pago
) eupg
inner join (select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from EUDED_ec_obl obl
	 inner join EUDED_cp_des cp on cp.cuota_pago = obl.cuota_pago
) euded on eupg.cuota_pago = euded.cuota_pago
inner join (select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from PRE_ec_obl obl
	 inner join PRE_cp_des cp on cp.cuota_pago = obl.cuota_pago
) pregrado on pregrado.cuota_pago = eupg.cuota_pago



select *
from
(select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from EUPG_ec_obl obl
	 inner join EUPG_cp_des cp on cp.cuota_pago = obl.cuota_pago
) eupg
inner join (select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from EUDED_ec_obl obl
	 inner join EUDED_cp_des cp on cp.cuota_pago = obl.cuota_pago
) euded on eupg.cuota_pago = euded.cuota_pago





select *
from
(select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from EUPG_ec_obl obl
	 inner join EUPG_cp_des cp on cp.cuota_pago = obl.cuota_pago
) eupg
inner join (select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from EUDED_ec_obl obl
	 inner join EUDED_cp_des cp on cp.cuota_pago = obl.cuota_pago
) euded on eupg.cuota_pago = euded.cuota_pago
inner join (select distinct cp.cuota_pago, cp.descripcio --, obl.* 
	from PRE_ec_obl obl
	 inner join PRE_cp_des cp on cp.cuota_pago = obl.cuota_pago
) pregrado on pregrado.cuota_pago = euded.cuota_pago


select eupg.cuota_pago as cuota_pago_eupg, eupg.descripcio, eupg.cod_alu, eupg.ano, eupg.p, eupg.cod_rc,
	   eupg.pagado, euded.cuota_pago as cuota_pago_euded, euded.descripcio, euded.pagado  
from
(select obl.*, cp.descripcio
	from EUPG_ec_obl obl
	 inner join EUPG_cp_des cp on cp.cuota_pago = obl.cuota_pago
) eupg
inner join (select obl.*, cp.descripcio
	from EUDED_ec_obl obl
	 inner join EUDED_cp_des cp on cp.cuota_pago = obl.cuota_pago
) euded on eupg.cuota_pago = euded.cuota_pago
				AND eupg.cod_alu = euded.cod_alu
				AND eupg.ano	 = euded.ano
				AND eupg.p		 = euded.p
				AND eupg.cod_rc	 = euded.cod_rc



select eupg.cuota_pago as cuota_pago_eupg, eupg.descripcio, eupg.cod_alu, eupg.ano, eupg.p, eupg.cod_rc,
		eupg.pagado, pregrado.cuota_pago as cuota_pago_pregrado, pregrado.descripcio, pregrado.pagado  
from
(select obl.*, cp.descripcio
	from EUPG_ec_obl obl
	 inner join EUPG_cp_des cp on cp.cuota_pago = obl.cuota_pago
) eupg
inner join (select obl.*, cp.descripcio
	from PRE_ec_obl obl
	 inner join PRE_cp_des cp on cp.cuota_pago = obl.cuota_pago
) pregrado on pregrado.cuota_pago = eupg.cuota_pago
				AND eupg.cod_alu = pregrado.cod_alu
				AND eupg.ano	 = pregrado.ano
				AND eupg.p		 = pregrado.p
				AND eupg.cod_rc	 = pregrado.cod_rc


select euded.cuota_pago as cuota_pago_euded, euded.descripcio, euded.cod_alu, euded.ano, euded.p, euded.cod_rc,
		euded.pagado, pregrado.cuota_pago as cuota_pago_pregrado, pregrado.descripcio, pregrado.pagado  
from
(select obl.*, cp.descripcio
	from EUDED_ec_obl obl
	 inner join EUDED_cp_des cp on cp.cuota_pago = obl.cuota_pago
) euded
inner join (select obl.*, cp.descripcio
	from PRE_ec_obl obl
	 inner join PRE_cp_des cp on cp.cuota_pago = obl.cuota_pago
) pregrado on pregrado.cuota_pago = euded.cuota_pago
				AND euded.cod_alu = pregrado.cod_alu
				AND euded.ano	 = pregrado.ano
				AND euded.p		 = pregrado.p
				AND euded.cod_rc = pregrado.cod_rc








elect * from eupg.ec_det where ano = 2021

--validar cuota de pago por año
select distinct cuota_pago from eupg.ec_det where ano = 2021

--validar conceptos de pago por año
select distinct concepto from eupg.ec_det where concepto_f = 1 and ano = 2021


select * from  eupg.ec_det where concepto = 0 and concepto_f = 0
select * from eupg.cp_pri where id_cp =4788


select * from eupg.cp_des where cuota_pago in (458, 457)


select * from  eupg.ec_det where 
cod_alu = '2015332742' and cod_rc = 'M19' and cuota_pago in (338, 339) and ano = 2016


-- validar que monto de la obligacion coincida con el monto de los items en el detalle

--2378 filas
select * from eupg.ec_obl obl 
where monto <> (select	sum(monto) 
				  from	eupg.ec_det det 
				 where	obl.cuota_pago = det.cuota_pago 
						and obl.cod_alu = det.cod_alu 
						and obl.cod_rc = det.cod_rc 
						and obl.p = det.p 
						and obl.ano = det.ano
						and obl.tipo_oblig = det.tipo_oblig 
						and obl.fch_venc = det.fch_venc
						and concepto_f = 0
						and concepto <> 0
						and det.eliminado = 0)

select COUNT(*) from eupg.ec_obl


select * from eupg.ec_det where 
cod_alu = '2017066365' and cod_rc = 'D13' and cuota_pago in (467) and ano = 2019 and p = 1
and eliminado = 0

select * from eupg.cp_des where cuota_pago = 467
select * from eupg.cp_pri where id_cp in (7411, 7412, 7413, 7414, 7417)


select * from eupg.ec_det where 
cod_alu = '2021001013' and cod_rc = 'P51' and cuota_pago in (515) and ano = 2021 and p = 2
and eliminado = 0

select * from eupg.cp_des where cuota_pago = 515
select * from eupg.cp_pri where id_cp in (7651, 7652, 7653)


select * from eupg.ec_det where 
cod_alu = '2019319019' and cod_rc = 'P99' and cuota_pago in (515) and ano = 2021 and p = 2
and eliminado = 0

select * from eupg.cp_des where cuota_pago = 515
select * from eupg.cp_pri where id_cp in (7651, 7652, 7653)
