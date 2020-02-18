/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_imp(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_imp(INTEGER, CHARACTER VARYING, CHARACTER VARYING);

CREATE OR REPLACE FUNCTION fnc_siac_bko_modifica_cig_imp
(
	p_movgest_ts_id INTEGER,
	p_cig CHARACTER VARYING,
	p_numeroRemedy CHARACTER VARYING
)
RETURNS VARCHAR AS
$body$
DECLARE
	v_messaggiorisultato varchar;

    v_tipoDebito     varchar:= null;
    v_bilElemAttrId  integer:= null;
    v_codResult      integer:= null;
    v_login_op_precedente varchar:= null;
    v_login_operazione varchar:='BackofficeModificaCig';
BEGIN
	
	v_messaggiorisultato := 'INIZIO PROCEDURA MODIFICA CIG DELL''IMPEGNO';
	
	if p_numeroRemedy != '' then
		v_login_operazione := p_numeroRemedy;
		v_messaggiorisultato := v_messaggiorisultato || ' - REMEDY: ' || v_login_operazione;
	end if;

	raise notice '[fnc_siac_bko_modifica_cig_imp] v_messaggiorisultato=%', v_messaggiorisultato;
	
	 select login_operazione from siac_r_movgest_ts_Attr rattrUPD where impUPD.movgest_ts_id=p_movgest_ts_id into v_login_op_precedente;
	
     update siac_r_movgest_ts_Attr rattrUPD
     set    data_cancellazione=now(),
            validita_fine=now(),
  			login_operazione = v_login_op_precedente || ' - ' || v_login_operazione
     from
     (
     	select rattr.bil_elem_attr_id
     	from siac_t_attr attr,siac_r_movgest_ts_Attr rattr
     	where rattr.movgest_ts_id=p_movgest_ts_id
     	and   attr.attr_id=rattr.attr_id
     	and   attr.attr_code='cig'
     	and   rattr.data_cancellazione is null
     	and   rattr.validita_fine is null
    ) rattrQuery
    where rattrUPD.bil_elem_attr_id=rattrQuery.bil_elem_attr_id
    returning  rattrUPD.bil_elem_attr_id into v_bilElemAttrId;
    
    if v_bilElemAttrId is null then
    	v_messaggiorisultato:=v_messaggiorisultato||'Valore non presente o non aggiornato.';
       raise notice '[fnc_siac_bko_modifica_cig_imp] v_messaggiorisultato=%',v_messaggiorisultato;

	else 
		v_bilElemAttrId:=null;
	end if;

	insert into siac_r_movgest_ts_attr
	(
		movgest_ts_id,
		attr_id,
		ente_proprietario_id,
		testo,
		validita_inizio,
		login_operazione
	)
	select ts.movgest_ts_id,
			attr.attr_id,
			ts.ente_proprietario_id,
			p_cig,
			now(),
			v_login_operazione
	from siac_t_movgest_ts ts, siac_t_attr attr
	where ts.movgest_ts_id=p_movgest_ts_id
	and   attr.attr_code='cig'
	and   ts.data_cancellazione is null
	and   ts.validita_fine is null
	and   attr.ente_proprietario_id = ts.ente_proprietario_id
	returning bil_elem_attr_id into v_bilElemAttrId;
	
	if v_bilElemAttrId is not null then
			v_messaggiorisultato:='[fnc_siac_bko_modifica_cig_imp] Valore inserito.';
	else 
			v_messaggiorisultato:='[fnc_siac_bko_modifica_cig_imp] Valore NON inserito.';
	end if;


 return v_messaggiorisultato;

exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return v_messaggiorisultato;
	when others  THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
        return v_messaggiorisultato;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;