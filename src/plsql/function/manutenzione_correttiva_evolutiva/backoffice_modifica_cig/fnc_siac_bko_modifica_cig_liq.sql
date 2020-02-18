/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_liq(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_liq(INTEGER, CHARACTER VARYING, CHARACTER VARYING);
CREATE OR REPLACE FUNCTION fnc_siac_bko_modifica_cig_liq(
    p_liq_id integer, 
    p_cig character varying,
    p_numeroRemedy CHARACTER VARYING
)
RETURNS integer AS 
$body$
DECLARE
	v_messaggiorisultato varchar;
	v_codResult integer := null;
	v_result integer := null;
	v_login_op_precedente varchar:= null;
 	v_login_operazione varchar:='BackofficeModificaCig';
BEGIN
	
	v_messaggiorisultato := '[fnc_siac_bko_modifica_cig_liq] INIZIO PROCEDURA MODIFICA CIG';
	
	if p_numeroRemedy != '' then
		v_login_operazione := p_numeroRemedy;
		v_messaggiorisultato := v_messaggiorisultato || ' - REMEDY: ' || v_login_operazione;
	end if;

	--CONTROLLARE
	select login_operazione 
	from (
		select rattr.liq_attr_id
		from
			siac_t_liquidazione liq,
			siac_t_attr attr,
			siac_r_liquidazione_attr rattr
		where liq.liq_id = p_liq_id
		and rattr.liq_id = liq.liq_id
		and attr.attr_id = rattr.attr_id
		and attr.attr_code = 'cig'
		and rattr.data_cancellazione is null
		and rattr.validita_fine is null
	) query
	where rliqATTR.liq_attr_id = query.liq_attr_id and rliqATTR.liq_id=p_liq_id into v_login_op_precedente;

	
	v_codResult := null;

	update siac_r_liquidazione_attr rliqATTR
	set
		data_cancellazione = now(),
		validita_fine = now(),
		login_operazione = v_login_op_precedente || ' - ' || v_login_operazione
	from (
		select rattr.liq_attr_id
		from
			siac_t_liquidazione liq,
			siac_t_attr attr,
			siac_r_liquidazione_attr rattr
		where liq.liq_id = p_liq_id
		and rattr.liq_id = liq.liq_id
		and attr.attr_id = rattr.attr_id
		and attr.attr_code = 'cig'
		and rattr.data_cancellazione is null
		and rattr.validita_fine is null
	) query
	where rliqATTR.liq_attr_id = query.liq_attr_id
	returning rliqATTR.liq_attr_id into v_codResult;

	if v_codResult is null then
		v_messaggiorisultato := v_messaggiorisultato || '[fnc_siac_bko_modifica_cig_liq] Valore del CIG non presente o non aggiornato.';

		raise notice '[fnc_siac_bko_modifica_cig_liq] v_messaggiorisultato=%', v_messaggiorisultato;
	else
		v_codResult := null;
	end if;

	insert into siac_r_liquidazione_attr ( liq_id, attr_id, ente_proprietario_id, testo, validita_inizio, login_operazione )
	select
		query.liq_id,
		attr.attr_id,
		attr.ente_proprietario_id,
		p_cig,
		now(),
		v_login_operazione
	from (
		select liq.liq_id
		from siac_t_liquidazione liq
		where liq.liq_id = p_liq_id
		and not exists (
			select 1
			from
				siac_r_liquidazione_attr rattr,
				siac_t_attr attr
			where rattr.liq_id = liq.liq_id
			and attr.attr_id = rattr.attr_id
			and attr.attr_code = 'cig'
			and rattr.data_cancellazione is null
			and rattr.validita_fine is null
		)
	) query,
	siac_t_attr attr,
	siac_t_liquidazione tl
	where attr.attr_code = 'cig'
	and tl.liq_id = p_liq_id
	and attr.ente_proprietario_id = tl.ente_proprietario_id
	returning liq_attr_id into v_codResult;
	
	if v_codResult is not null then
		v_messaggiorisultato := '[fnc_siac_bko_modifica_cig_liq] Nuovo valore del CIG inserito.';
	else
		v_messaggiorisultato := '[fnc_siac_bko_modifica_cig_liq] Valore del CIG NON inserito.';
	end if;

	raise notice '[fnc_siac_bko_modifica_cig_liq] v_messaggiorisultato=%', v_messaggiorisultato;

	v_result := 0;
	return v_result;

	exception
		when RAISE_EXCEPTION then
			v_messaggiorisultato := v_messaggiorisultato || ' - ' || substring(upper(sqlerrm) from 1 for 2500);
			raise notice '[fnc_siac_bko_modifica_cig_liq] ERROR %', v_messaggiorisultato;
			v_result := 1;
			return v_result;
		when others then
			v_messaggiorisultato := v_messaggiorisultato || ' others - ' || substring(upper(sqlerrm) from 1 for 2500);
			raise notice '[fnc_siac_bko_modifica_cig_liq] ERROR %', v_messaggiorisultato;
			v_result := 2;
			return v_result;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
