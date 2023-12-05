/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_liquidazione(INTEGER, INTEGER, CHARACTER VARYING, INTEGER);
DROP FUNCTION IF EXISTS fnc_siac_bko_modifica_cig_liquidazione(INTEGER, INTEGER, CHARACTER VARYING, INTEGER, CHARACTER VARYING);
CREATE OR REPLACE FUNCTION fnc_siac_bko_modifica_cig_liquidazione(
    p_liq_id INTEGER,
    p_siope_tipo_debito_id INTEGER,
    p_cig CHARACTER VARYING,
	p_siope_assenza_motivazione_id INTEGER,
	p_numeroRemedy CHARACTER VARYING
) RETURNS INTEGER 
AS $body$
DECLARE
	v_messaggiorisultato varchar;
    v_tipoDebito varchar:= null;
    v_motivoAssenzaCIG varchar:= null;
	v_codResult  integer:=null;
    v_result integer:=null;
    v_login_op_precedente varchar:= null;
    v_login_operazione varchar:='BackofficeModificaCig';
BEGIN

	v_messaggiorisultato := 'INIZIO PROCEDURA MODIFICA CIG SU LIQUIDAZIONE';
 	raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=% ',v_messaggiorisultato;
	
	if p_numeroRemedy != '' then
		v_login_operazione := p_numeroRemedy;
		v_messaggiorisultato := v_messaggiorisultato || ' - REMEDY: ' || v_login_operazione;
	end if;
	
	raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=% ',v_messaggiorisultato;
	
	select deb.siope_tipo_debito_desc_bnkit into v_tipoDebito
	from siac_d_siope_tipo_debito deb
	where deb.siope_tipo_debito_id = p_siope_tipo_debito_id;
	
	select dsam.siope_assenza_motivazione_desc into v_motivoAssenzaCIG
	from siac_d_siope_assenza_motivazione dsam
	where dsam.siope_assenza_motivazione_id = p_siope_assenza_motivazione_id;


	if v_tipoDebito='NON_COMMERCIALE' then
	   v_messaggiorisultato :='Aggiornamento tipo debito a '||v_tipoDebito||'. 
							  Cancellazione Motivo Assenza CIG. Liquidazione con UID'||p_liq_id||'.';
	   raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=%',v_messaggiorisultato;
	   
	   select login_operazione from siac_t_liquidazione liqUPD where liqUPD.liq_id=p_liq_id into v_login_op_precedente;
	   
	   v_codResult:=null;
	   update siac_t_liquidazione liqUPD
	   set siope_assenza_motivazione_id=null,
	       siope_tipo_debito_id=p_siope_tipo_debito_id,
	       data_modifica=now(),
	       login_operazione = v_login_op_precedente || ' - ' || v_login_operazione
	   where liqUPD.liq_id=p_liq_id
	   returning liqUPD.liq_id into v_codResult;
	
	   if v_codResult is null then
		  	v_messaggiorisultato:=v_messaggiorisultato||' Aggiornamento NON EFFETTUATO.';
	   else
		  	v_messaggiorisultato:=v_messaggiorisultato||' Aggiornamento EFFETTUATO.';
	   end if;
	   raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=%',v_messaggiorisultato;
	end if;

  if v_tipoDebito='COMMERCIALE' then
  	
  		if v_motivoAssenzaCIG is not null then

    		v_messaggiorisultato :='Aggiornamento tipo debito a '||v_tipoDebito||'. 
									Aggiornamento Motivo Assenza CIG='||v_motivoAssenzaCIG||' della liquidazione con UID'||p_liq_id||'.';
			raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=%',v_messaggiorisultato;
	    
			select login_operazione from siac_t_liquidazione liqUPD where liqUPD.liq_id=p_liq_id into v_login_op_precedente;
			
			v_codResult:=null;
	    	update siac_t_liquidazione liqUPD
	    	set siope_assenza_motivazione_id=p_siope_assenza_motivazione_id,
	            siope_tipo_debito_id=p_siope_tipo_debito_id,
	            data_modifica=now(),
	            login_operazione = v_login_op_precedente || ' - ' || v_login_operazione
	    	where liqUPD.liq_id=p_liq_id
	    	returning liqUPD.liq_id into v_codResult;

    	else
    		v_messaggiorisultato :='Aggiornamento tipo debito a '||v_tipoDebito||' della liquidazione con UID'||p_liq_id||'.';
			raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=%',v_messaggiorisultato;
			
			select login_operazione from siac_t_liquidazione liqUPD where liqUPD.liq_id=p_liq_id into v_login_op_precedente;
	    	
			v_codResult:=null;
	    	update siac_t_liquidazione liqUPD
	    	set siope_tipo_debito_id=p_siope_tipo_debito_id,
				siope_assenza_motivazione_id=null,
	            data_modifica=now(),
				login_operazione = v_login_op_precedente || ' - ' || v_login_operazione
	    	where liqUPD.liq_id=p_liq_id
	    	returning liqUPD.liq_id into v_codResult;
    	end if;

	    if v_codResult is null then
		    v_messaggiorisultato:='Aggiornamento NON EFFETTUATO.';
		else
		    v_messaggiorisultato:='Aggiornamento EFFETTUATO.';
		end if;
		
	    raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=%',v_messaggiorisultato;
  end if;

  select fnc_siac_bko_modifica_cig_liq( p_liq_id, p_cig, p_numeroRemedy) into v_messaggiorisultato;

  raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=%',v_messaggiorisultato;
  raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] v_messaggiorisultato=% FINE',v_messaggiorisultato;

  v_result = 0;
  return v_result;


  exception 
  when RAISE_EXCEPTION THEN
      v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
      raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] ERROR %',v_messaggiorisultato;
      v_result := 1;
      return v_result;
  when others  THEN
  	  v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
      raise notice '[fnc_siac_bko_modifica_CIG_liquidazione] ERROR %',v_messaggiorisultato;
  	  v_result := 2;
      return v_result;
     
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;