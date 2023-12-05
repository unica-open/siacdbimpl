/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_bko_impegno_cig_su_collegati(INTEGER, INTEGER, CHARACTER VARYING, INTEGER);
DROP FUNCTION IF EXISTS fnc_siac_bko_impegno_cig_su_collegati(INTEGER, INTEGER, CHARACTER VARYING, INTEGER, CHARACTER VARYING);
CREATE OR REPLACE FUNCTION fnc_siac_bko_impegno_cig_su_collegati
(
    p_movgest_ts_id INTEGER,
    p_siope_tipo_debito_id INTEGER,
    p_cig CHARACTER VARYING,
	p_siope_assenza_motivazione_id INTEGER,
	p_numeroRemedy CHARACTER VARYING
)
RETURNS INTEGER AS
$body$
DECLARE
	v_messaggiorisultato varchar;
    v_tipoDebito varchar:= null;
    v_motivoAssenzaCIG varchar:= null;
    v_liq_id integer:= null;
    v_subdoc_id integer:=null;
	v_codResult  integer:=null;
    v_result integer:=null;
BEGIN
 	v_messaggiorisultato :='Aggiornamento tipo debito dei documenti/quote e liquidazioni associati all''impegno con UID'||p_movgest_ts_id||'.';

 	raise notice '[fnc_siac_bko_impegno_cig_su_collegati] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
 
    select fnc_siac_bko_impegno_cig_su_movgest( p_movgest_ts_id, p_siope_tipo_debito_id, p_cig, p_siope_assenza_motivazione_id, p_numeroRemedy) into v_result;
    raise notice '[fnc_siac_bko_impegno_cig_su_collegati] v_messaggiorisultato=% FINE',v_result;
    if v_result !=0 then
    	--v_result ritorna 3 se l'esecuzione di fnc_siac_bko_impegno_cig_su_movgest fallisce 
    	v_result:=3;
    	return v_result;
    end if;
   
   -- QUOTE
    FOR v_subdoc_id IN SELECT ts.subdoc_id
	from siac_t_subdoc ts
	join siac_r_subdoc_movgest_ts rsm on (ts.subdoc_id=rsm.subdoc_id and rsm.data_cancellazione is null and rsm.validita_fine is null)
	join siac_t_doc td on (td.doc_id=ts.doc_id and td.data_cancellazione is null and td.validita_fine is null)
    join siac_r_doc_stato rds on (rds.doc_id = td.doc_id and rds.data_cancellazione is null and rds.validita_fine is null)
    join siac_d_doc_stato dds on (dds.doc_stato_id = rds.doc_stato_id and dds.data_cancellazione is null and dds.validita_fine is null)
	where rsm.movgest_ts_id = p_movgest_ts_id
	and ts.data_cancellazione is null
	and ts.validita_fine is null
	and dds.doc_stato_code <> 'A'
	and not exists (
	    select 1
		from siac_r_subdoc_liquidazione rsl
	    join siac_t_liquidazione tl on (tl.liq_id=rsl.liq_id and tl.data_cancellazione is null and tl.validita_fine is null)
		join siac_r_liquidazione_ord rlo on (rlo.liq_id=rsl.liq_id and rlo.data_cancellazione is null and rlo.validita_fine is null)
		join siac_t_ordinativo_ts torts on (torts.ord_ts_id=rlo.sord_id and torts.data_cancellazione is null and torts.validita_fine is null)
		join siac_t_ordinativo tor on (tor.ord_id=torts.ord_id and tor.data_cancellazione is null and tor.validita_fine is null)
		join siac_r_ordinativo_stato ros on (ros.ord_id=tor.ord_id and ros.data_cancellazione is null and ros.validita_fine is null)
		join siac_d_ordinativo_stato dos on (dos.ord_stato_id=ros.ord_stato_id and dos.data_cancellazione is null and dos.validita_fine is null)
	    where rsl.subdoc_id=ts.subdoc_id 
	    and rsl.data_cancellazione is null 
	    and rsl.validita_fine is null
		and dos.ord_stato_code <> 'A'
		)
	LOOP
		select fnc_siac_bko_modifica_cig_quote(v_subdoc_id,p_siope_tipo_debito_id,p_cig,p_siope_assenza_motivazione_id,p_numeroRemedy) into v_result;
		if v_result !=0 then
    	--v_result torna 4 se l'esecuzione di fnc_siac_bko_impegno_cig_quote fallisce 
    	v_result:=4;
    	return v_result;
    end if;
	END LOOP;

	-- LIQUIDAZIONI
	FOR v_liq_id in
	
	SELECT tl.liq_id
	from siac_t_liquidazione tl
	join siac_r_liquidazione_movgest srlm on (tl.liq_id = srlm.liq_id and srlm.data_cancellazione is null and srlm.validita_fine is null)
	join siac_r_liquidazione_stato rls on (rls.liq_id = tl.liq_id and rls.data_cancellazione is null and rls.validita_fine is null)
    join siac_d_liquidazione_stato dls on (dls.liq_stato_id = rls.liq_stato_id and dls.data_cancellazione is null and dls.validita_fine is null)
	where srlm.movgest_ts_id = p_movgest_ts_id
	and tl.data_cancellazione is null
	and tl.validita_fine is null
	and dls.liq_stato_code <> 'A'
	and not exists (
		select 1
		from siac_r_liquidazione_ord rlo
		join siac_t_ordinativo_ts torts on (rlo.sord_id = torts.ord_ts_id and torts.data_cancellazione is null and torts.validita_fine is null)
		join siac_t_ordinativo tor on (tor.ord_id=torts.ord_id and tor.data_cancellazione is null and tor.validita_fine is null)
		join siac_r_ordinativo_stato ros on (ros.ord_id = tor.ord_id and ros.data_cancellazione is null and ros.validita_fine is null)
		join siac_d_ordinativo_stato dos on (dos.ord_stato_id = ros.ord_stato_id and dos.data_cancellazione is null and dos.validita_fine is null)
		where tl.liq_id = rlo.liq_id
		and rlo.data_cancellazione is null
		and rlo.validita_fine is null
		and dos.ord_stato_code <> 'A'
	)
	UNION
	SELECT tl.liq_id
	from siac_r_subdoc_liquidazione rsl, siac_t_liquidazione tl, siac_r_subdoc_movgest_ts rsdm
	where rsdm.movgest_ts_id = p_movgest_ts_id
	and rsdm.subdoc_id=rsl.subdoc_id
	and tl.liq_id = rsl.liq_id
	and rsl.data_cancellazione is null
	and rsl.validita_fine is null
	and rsdm.data_cancellazione is null
	and rsdm.validita_fine is null
	and tl.data_cancellazione is null
	and tl.validita_fine is null
	and not exists (
		select 1
		from siac_r_liquidazione_ord rlo
		join siac_t_ordinativo_ts torts on (rlo.sord_id = torts.ord_ts_id and torts.data_cancellazione is null and torts.validita_fine is null)
		join siac_t_ordinativo tor on (tor.ord_id=torts.ord_id and tor.data_cancellazione is null and tor.validita_fine is null)
		join siac_r_ordinativo_stato ros on (ros.ord_id = tor.ord_id and ros.data_cancellazione is null and ros.validita_fine is null)
		join siac_d_ordinativo_stato dos on (dos.ord_stato_id = ros.ord_stato_id and dos.data_cancellazione is null and dos.validita_fine is null)
		where tl.liq_id = rlo.liq_id
		and rlo.data_cancellazione is null
		and rlo.validita_fine is null
		and dos.ord_stato_code <> 'A'
	)
	
	LOOP
		select fnc_siac_bko_modifica_cig_liquidazione(v_liq_id, p_siope_tipo_debito_id, p_cig, p_siope_assenza_motivazione_id, p_numeroRemedy) into v_result;
		if v_result !=0 then
    	--v_result torna 5 se l'esecuzione di fnc_siac_bko_impegno_cig_liquidazione fallisce 
    	v_result:=5;
    	return v_result;
    end if;
	END LOOP;

    raise notice '[fnc_siac_bko_impegno_cig_su_collegati] v_messaggiorisultato=% FINE',v_messaggiorisultato;

	return v_result;

	exception
	    when RAISE_EXCEPTION THEN
	    	v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
	   	    raise notice '[fnc_siac_bko_impegno_cig_su_collegati] ERROR %',v_messaggiorisultato;
	        v_result := 1;
	   		return v_result;
		when others  THEN
			v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
	    	raise notice '[fnc_siac_bko_impegno_cig_su_collegati] ERROR %',v_messaggiorisultato;
			v_result := 2;
	   		return v_result;
	   	
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;