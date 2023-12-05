/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_subdoc(INTEGER, CHARACTER VARYING);
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_subdoc(INTEGER, CHARACTER VARYING, CHARACTER VARYING);
CREATE OR REPLACE FUNCTION fnc_siac_bko_modifica_cig_subdoc(
    p_subdoc_id INTEGER,
    p_cig CHARACTER VARYING,
    p_numeroRemedy CHARACTER VARYING
) RETURNS INTEGER 
AS $body$
DECLARE
	v_messaggiorisultato varchar;
    v_result integer:=null;
    v_codResult      integer:=null;
    v_login_operazione varchar:='BackofficeModificaCig';
BEGIN

	v_messaggiorisultato := 'INIZIO PROCEDURA MODIFICA CIG SUBDOC';
	
	if p_numeroRemedy != '' then
		v_login_operazione := p_numeroRemedy;
		v_messaggiorisultato := v_messaggiorisultato || ' - REMEDY: ' || v_login_operazione;
	end if;
	
     raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;
	
     v_codResult:=null;
     update siac_r_subdoc_attr rsa
     set    data_cancellazione=now(),
            validita_fine=now(),
	        login_operazione = login_operazione || ' - ' || v_login_operazione
     from
     (
     select rsuba.subdoc_attr_id
     from siac_t_subdoc ts, siac_t_attr attr,siac_r_subdoc_attr rsuba
     where ts.subdoc_id=p_subdoc_id
     and   rsuba.subdoc_id=ts.subdoc_id
     and   attr.attr_id=rsuba.attr_id
     and   attr.attr_code='cig'
     and   rsuba.data_cancellazione is null
     and   rsuba.validita_fine is null
    ) query
    where  rsa.subdoc_attr_id=query.subdoc_attr_id
    returning rsa.subdoc_attr_id into v_codResult;
    
    if  v_codResult is null then
    	v_messaggiorisultato:=v_messaggiorisultato||' Valore non presente o non aggiornato.';
       raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;
    end if;

    v_codResult:=null;
    insert into siac_r_subdoc_attr
    (
        subdoc_id,
        attr_id,
        ente_proprietario_id,
        testo,
        validita_inizio,
        login_operazione
    )
    select query.subdoc_id,
            attr.attr_id,
            attr.ente_proprietario_id,
            p_cig,
            now(),
            v_login_operazione
    from
    (
    	select rsa.subdoc_id
	    from siac_t_subdoc rsa
	    where rsa.subdoc_id=p_subdoc_id
        and not exists
        (
        select 1
        from siac_r_subdoc_attr rsuba, siac_t_attr attr
        where rsuba.subdoc_id=rsa.subdoc_id
        and   attr.attr_id=rsuba.attr_id
        and   attr.attr_code='cig'
        and   rsuba.data_cancellazione is null
	    and   rsuba.validita_fine is null
        )

    ) query, siac_t_attr attr, siac_t_subdoc tsd
	    where attr.attr_code='cig'
        and tsd.subdoc_id=p_subdoc_id
	    and   attr.ente_proprietario_id = tsd.ente_proprietario_id
	    returning subdoc_attr_id into v_codResult;
		
    if v_codResult is not null then
            v_messaggiorisultato:=v_messaggiorisultato||' Valore inserito.';
    else 
            v_messaggiorisultato:=v_messaggiorisultato||' Valore NON inserito.';
    end if;

    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;

    v_result = 0;
    return v_result;


  exception 
  when RAISE_EXCEPTION THEN
      v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
      raise notice '[fnc_siac_bko_modifica_CIG_quote] ERROR %',v_messaggiorisultato;
      v_result := 1;
      return v_result;
  when others  THEN
  	  v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
      raise notice '[fnc_siac_bko_modifica_CIG_quote] ERROR %',v_messaggiorisultato;
  	  v_result := 2;
      return v_result;
     

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;