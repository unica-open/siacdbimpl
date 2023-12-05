/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS siac.fnc_siac_inserisci_det_variazione_assestamento (integer, varchar, varchar);

CREATE OR REPLACE FUNCTION siac.fnc_siac_inserisci_det_variazione_assestamento (
  variazione_id_in integer,
  anno_bilancio varchar,
  login_operazione_in varchar
)
RETURNS TABLE (
  _elem_id integer,
  _elem_det_var_id integer,
  _elem_det_var_tipo_code varchar,
  _anno varchar,
  _elem_det_importo numeric
) AS
$body$
DECLARE

periodo_id_piu_zero integer;
periodo_id_piu_uno integer;
periodo_id_piu_due integer;

BEGIN
	
	-- Ottengo periodo per anno, anno + 1 e anno + 2
	select siac_t_periodo_var.periodo_id, siac_t_periodo1.periodo_id, siac_t_periodo2.periodo_id
	into periodo_id_piu_zero, periodo_id_piu_uno, periodo_id_piu_due
	from siac_t_periodo siac_t_periodo1
	join siac_t_periodo siac_t_periodo2 on (siac_t_periodo2.ente_proprietario_id = siac_t_periodo1.ente_proprietario_id and siac_t_periodo2.data_cancellazione is null)
	join siac_t_variazione on (siac_t_variazione.ente_proprietario_id = siac_t_periodo1.ente_proprietario_id and siac_t_variazione.data_cancellazione is null)
	join siac_t_bil on (siac_t_bil.bil_id = siac_t_variazione.bil_id and siac_t_bil.data_cancellazione is null)
	join siac_t_periodo siac_t_periodo_var on (siac_t_periodo_var.periodo_id = siac_t_bil.periodo_id and siac_t_periodo_var.data_cancellazione is null)
	join siac_d_periodo_tipo siac_d_periodo_tipo1 on (siac_d_periodo_tipo1.periodo_tipo_id = siac_t_periodo1.periodo_tipo_id AND siac_d_periodo_tipo1.data_cancellazione is null)
	join siac_d_periodo_tipo siac_d_periodo_tipo2 on (siac_d_periodo_tipo2.periodo_tipo_id = siac_t_periodo2.periodo_tipo_id AND siac_d_periodo_tipo2.data_cancellazione is null)
	where siac_t_periodo1.data_cancellazione is null
	and siac_t_variazione.variazione_id = variazione_id_in
	and siac_t_periodo1.anno = cast(cast(siac_t_periodo_var.anno as integer) + 1 as character varying)
	and siac_t_periodo2.anno = cast(cast(siac_t_periodo_var.anno as integer) + 2 as character varying)
	and siac_d_periodo_tipo1.periodo_tipo_code = 'SY'
	and siac_d_periodo_tipo2.periodo_tipo_code = 'SY';
	
	insert into siac.siac_t_bil_elem_det_var (
		variazione_stato_id,
		elem_id,
		elem_det_importo,
		elem_det_flag,
		elem_det_tipo_id,
		periodo_id,
		validita_inizio,
		ente_proprietario_id,
		login_operazione)
	select
		temp.variazione_stato_id,
		temp.elemid,
		-sum(temp.rescap) + sum(temp.resmv) as var_st_res,
		null,
		siac_d_bil_elem_det_tipo.elem_det_tipo_id,
		siac_t_periodo.periodo_id,
		now(),
		temp.ente_proprietario_id,
		login_operazione_in
	from (
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			sum(siac_t_bil_elem_det.elem_det_importo) as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-UG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			sum(siac_t_bil_elem_det.elem_det_importo) as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem_det.elem_id = siac_t_bil_elem.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-UG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-UG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_r_movgest_bil_elem.ente_proprietario_id,
			siac_r_movgest_bil_elem.elem_id as elemid,
			0 as rescap,
			sum(siac_t_movgest_ts_det.movgest_ts_det_importo) as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_movgest_ts
		join siac_r_movgest_bil_elem on (siac_t_movgest_ts.movgest_id = siac_r_movgest_bil_elem.movgest_id and siac_r_movgest_bil_elem.data_cancellazione is null and now() between siac_r_movgest_bil_elem.validita_inizio and COALESCE(siac_r_movgest_bil_elem.validita_fine,now()))
		join siac_t_movgest_ts_det on (siac_t_movgest_ts_det.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_t_movgest_ts_det.data_cancellazione is null)
		join siac_d_movgest_ts_det_tipo on (siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_id = siac_t_movgest_ts_det.movgest_ts_det_tipo_id and siac_d_movgest_ts_det_tipo.data_cancellazione is null)
		join siac_t_movgest on (siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id and siac_t_movgest.data_cancellazione is null)
		join siac_d_movgest_tipo on (siac_d_movgest_tipo.movgest_tipo_id = siac_t_movgest.movgest_tipo_id and siac_d_movgest_tipo.data_cancellazione is null)
		join siac_d_movgest_ts_tipo on (siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id and siac_d_movgest_ts_tipo.data_cancellazione is null)
		join siac_r_movgest_ts_stato on (siac_r_movgest_ts_stato.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_r_movgest_ts_stato.data_cancellazione is null and now() between siac_r_movgest_ts_stato.validita_inizio and COALESCE(siac_r_movgest_ts_stato.validita_fine,now()))
		join siac_d_movgest_stato on (siac_r_movgest_ts_stato.movgest_stato_id = siac_d_movgest_stato.movgest_stato_id and siac_d_movgest_stato.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_movgest_ts_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() between siac_r_variazione_stato.validita_inizio and COALESCE(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.bil_id = siac_t_movgest.bil_id and siac_t_bil.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil.periodo_id and siac_t_periodo.data_cancellazione is null)
		where siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'I'
		and siac_d_movgest_tipo.movgest_tipo_code = 'I'
		and siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'
		and siac_t_movgest.movgest_anno < anno_bilancio::integer
		and siac_d_movgest_stato.movgest_stato_code in ('N', 'D')
		and siac_t_movgest_ts.data_cancellazione is null
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_periodo.anno = anno_bilancio
		group by siac_r_variazione_stato.variazione_stato_id, siac_r_movgest_bil_elem.ente_proprietario_id, siac_r_movgest_bil_elem.elem_id
	) as temp
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.ente_proprietario_id = temp.ente_proprietario_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_t_periodo on (siac_t_periodo.ente_proprietario_id = siac_d_bil_elem_det_tipo.ente_proprietario_id and siac_t_periodo.data_cancellazione is null)
	join siac_d_periodo_tipo on (siac_d_periodo_tipo.periodo_tipo_id = siac_t_periodo.periodo_tipo_id and siac_d_periodo_tipo.data_cancellazione is null)
	where siac_d_bil_elem_det_tipo.elem_det_tipo_code in ('STR', 'SCA')
	and siac_t_periodo.anno = anno_bilancio
	and siac_d_periodo_tipo.periodo_tipo_code = 'SY'
	group by temp.variazione_stato_id, temp.elemid, siac_d_bil_elem_det_tipo.elem_det_tipo_id, siac_t_periodo.periodo_id, temp.ente_proprietario_id
	having -sum(temp.rescap) + sum(temp.resmv) <> 0;
	
	insert into siac.siac_t_bil_elem_det_var (
		variazione_stato_id,
		elem_id,
		elem_det_importo,
		elem_det_flag,
		elem_det_tipo_id,
		periodo_id,
		validita_inizio,
		ente_proprietario_id,
		login_operazione)
	select
		temp.variazione_stato_id,
		temp.elemid,
		-sum(temp.rescap) + sum(temp.resmv) as var_st_res,
		null,
		siac_d_bil_elem_det_tipo.elem_det_tipo_id,
		siac_t_periodo.periodo_id,
		now(),
		temp.ente_proprietario_id,
		login_operazione_in
	from (
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			sum(siac_t_bil_elem_det.elem_det_importo) as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-EG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			sum(siac_t_bil_elem_det.elem_det_importo) as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-EG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_t_bil_elem_det.ente_proprietario_id,
			siac_t_bil_elem_det.elem_id as elemid,
			0 as rescap,
			0 as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_bil_elem
		join siac_d_bil_elem_tipo on (siac_t_bil_elem.elem_tipo_id = siac_d_bil_elem_tipo.elem_tipo_id and siac_d_bil_elem_tipo.data_cancellazione is null)
		join siac_t_bil_elem_det on (siac_t_bil_elem.elem_id = siac_t_bil_elem_det.elem_id and siac_t_bil_elem_det.data_cancellazione is null)
		join siac_d_bil_elem_det_tipo on (siac_t_bil_elem_det.elem_det_tipo_id = siac_d_bil_elem_det_tipo.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det.periodo_id and siac_t_periodo.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_bil_elem_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() BETWEEN siac_r_variazione_stato.validita_inizio and coalesce(siac_r_variazione_stato.validita_fine,now()))
		join siac_t_bil on (siac_t_bil.periodo_id = siac_t_periodo.periodo_id and siac_t_bil_elem.bil_id = siac_t_bil.bil_id and siac_t_bil.data_cancellazione is null)
		where siac_d_bil_elem_tipo.elem_tipo_code = 'CAP-EG'
		and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		and siac_t_bil_elem.data_cancellazione is null
		group by siac_r_variazione_stato.variazione_stato_id, siac_t_bil_elem_det.ente_proprietario_id, siac_t_bil_elem_det.elem_id
		
		union
		
		select
			siac_r_variazione_stato.variazione_stato_id,
			siac_r_movgest_bil_elem.ente_proprietario_id,
			siac_r_movgest_bil_elem.elem_id as elemid,
			0 as rescap,
			sum(siac_t_movgest_ts_det.movgest_ts_det_importo) as resmv,
			0 as casscap,
			0 as compcap
		from siac_t_movgest_ts
		join siac_r_movgest_bil_elem on (siac_t_movgest_ts.movgest_id = siac_r_movgest_bil_elem.movgest_id and siac_r_movgest_bil_elem.data_cancellazione is null and now() between siac_r_movgest_bil_elem.validita_inizio and COALESCE(siac_r_movgest_bil_elem.validita_fine, now()))
		join siac_t_movgest_ts_det on (siac_t_movgest_ts_det.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_t_movgest_ts_det.data_cancellazione is null)
		join siac_d_movgest_ts_det_tipo on (siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_id = siac_t_movgest_ts_det.movgest_ts_det_tipo_id and siac_d_movgest_ts_det_tipo.data_cancellazione is null)
		join siac_t_movgest on (siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id and siac_t_movgest.data_cancellazione is null)
		join siac_d_movgest_tipo on (siac_d_movgest_tipo.movgest_tipo_id = siac_t_movgest.movgest_tipo_id and siac_d_movgest_tipo.data_cancellazione is null)
		join siac_d_movgest_ts_tipo on (siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id and siac_d_movgest_ts_tipo.data_cancellazione is null)
		join siac_r_movgest_ts_stato on (siac_r_movgest_ts_stato.movgest_ts_id = siac_t_movgest_ts.movgest_ts_id and siac_r_movgest_ts_stato.data_cancellazione is null and now() between siac_r_movgest_ts_stato.validita_inizio and COALESCE(siac_r_movgest_ts_stato.validita_fine, now()))
		join siac_d_movgest_stato on (siac_r_movgest_ts_stato.movgest_stato_id = siac_d_movgest_stato.movgest_stato_id and siac_d_movgest_stato.data_cancellazione is null)
		join siac_r_variazione_stato on (siac_r_variazione_stato.ente_proprietario_id = siac_t_movgest_ts_det.ente_proprietario_id and siac_r_variazione_stato.data_cancellazione is null and now() between siac_r_variazione_stato.validita_inizio and COALESCE(siac_r_variazione_stato.validita_fine, now()))
		join siac_t_bil on (siac_t_bil.bil_id = siac_t_movgest.bil_id and siac_t_bil.data_cancellazione is null)
		join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil.periodo_id and siac_t_periodo.data_cancellazione is null)
		where siac_d_movgest_ts_det_tipo.movgest_ts_det_tipo_code = 'I'
		and siac_d_movgest_tipo.movgest_tipo_code = 'A'
		and siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'T'
		and siac_t_movgest.movgest_anno < anno_bilancio::integer
		and siac_d_movgest_stato.movgest_stato_code in ('N', 'D')
		and siac_t_movgest_ts.data_cancellazione is null
		and siac_t_periodo.anno = anno_bilancio
		and siac_r_variazione_stato.variazione_id = variazione_id_in
		group by siac_r_variazione_stato.variazione_stato_id, siac_r_movgest_bil_elem.ente_proprietario_id, siac_r_movgest_bil_elem.elem_id
	) as temp
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.ente_proprietario_id = temp.ente_proprietario_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_t_periodo on (siac_t_periodo.ente_proprietario_id = siac_d_bil_elem_det_tipo.ente_proprietario_id and siac_t_periodo.data_cancellazione is null)
	join siac_d_periodo_tipo on (siac_d_periodo_tipo.periodo_tipo_id = siac_t_periodo.periodo_tipo_id and siac_d_periodo_tipo.data_cancellazione is null)
	where siac_d_bil_elem_det_tipo.elem_det_tipo_code in ('STR', 'SCA')
	and siac_t_periodo.anno = anno_bilancio
	and siac_d_periodo_tipo.periodo_tipo_code = 'SY'
	group by temp.variazione_stato_id, temp.elemid, siac_d_bil_elem_det_tipo.elem_det_tipo_id, siac_t_periodo.periodo_id, temp.ente_proprietario_id
	having -sum(temp.rescap) + sum(temp.resmv) <> 0;
	
	insert into siac.siac_t_bil_elem_det_var (
		variazione_stato_id,
		elem_id,
		elem_det_importo,
		elem_det_flag,
		elem_det_tipo_id,
		periodo_id,
		validita_inizio,
		ente_proprietario_id,
		login_operazione
	)
	select
		siac_t_bil_elem_det_var.variazione_stato_id,
		siac_t_bil_elem_det_var.elem_id,
		0,
		null,
		siac_d_bil_elem_det_tipo.elem_det_tipo_id,
		tmp.periodo_id,
		now(),
		siac_t_bil_elem_det_var.ente_proprietario_id,
		login_operazione_in
	from siac_t_bil_elem_det_var
	join siac_d_bil_elem_det_tipo siac_d_bil_elem_det_tipo_var on (siac_d_bil_elem_det_tipo_var.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id and siac_d_bil_elem_det_tipo_var.data_cancellazione is null)
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.ente_proprietario_id = siac_t_bil_elem_det_var.ente_proprietario_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_r_variazione_stato on (siac_t_bil_elem_det_var.variazione_stato_id = siac_r_variazione_stato.variazione_stato_id and siac_r_variazione_stato.data_cancellazione is null)
	cross join (values
		(periodo_id_piu_zero),
		(periodo_id_piu_uno),
		(periodo_id_piu_due)
	) as tmp(periodo_id)
	where siac_t_bil_elem_det_var.data_cancellazione is null
	and siac_r_variazione_stato.variazione_id = variazione_id_in
	and siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA'
	and siac_d_bil_elem_det_tipo_var.elem_det_tipo_code = 'STR'
	and siac_t_bil_elem_det_var.login_operazione = login_operazione_in;
	
	RETURN QUERY
	select
		siac_t_bil_elem_det_var.elem_id,
		siac_t_bil_elem_det_var.elem_det_var_id,
		siac_d_bil_elem_det_tipo.elem_det_tipo_code,
		siac_t_periodo.anno,
		siac_t_bil_elem_det_var.elem_det_importo
	from siac_t_bil_elem_det_var
	join siac_d_bil_elem_det_tipo on (siac_d_bil_elem_det_tipo.elem_det_tipo_id = siac_t_bil_elem_det_var.elem_det_tipo_id and siac_d_bil_elem_det_tipo.data_cancellazione is null)
	join siac_t_periodo on (siac_t_periodo.periodo_id = siac_t_bil_elem_det_var.periodo_id and siac_t_periodo.data_cancellazione is null)
	join siac_r_variazione_stato on (siac_t_bil_elem_det_var.variazione_stato_id = siac_r_variazione_stato.variazione_stato_id and siac_r_variazione_stato.data_cancellazione is null)
	where siac_t_bil_elem_det_var.data_cancellazione is null
	and siac_r_variazione_stato.variazione_id = variazione_id_in
	and siac_t_bil_elem_det_var.login_operazione = login_operazione_in
	order by
		siac_t_bil_elem_det_var.elem_id,
		siac_t_periodo.anno,
		case
			when siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STA' then 1
			when siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'STR' then 2
			when siac_d_bil_elem_det_tipo.elem_det_tipo_code = 'SCA' then 3
			else 4
		end;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;