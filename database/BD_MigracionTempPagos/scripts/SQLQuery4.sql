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
