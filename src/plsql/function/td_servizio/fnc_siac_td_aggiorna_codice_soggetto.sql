/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_aggiorna_codice_soggetto (
  p_ente_proprietario_id integer,
  codice_sog_old varchar,
  codice_sog_new varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
	v_messaggiorisultato varchar;
    soggetto_id_new siac_t_soggetto.soggetto_id%type ;
    soggetto_code_new siac_t_soggetto.soggetto_code%type;
    login_operazione_new siac_t_soggetto.login_operazione%type;
    data_modifica_new siac_t_soggetto.data_modifica%type;
BEGIN
    v_messaggiorisultato :='Errore';
 
	UPDATE 
      siac.siac_t_soggetto x
    SET 
      soggetto_code = codice_sog_new,
      login_operazione = login_operazione || ' - ' || numero_incident,
      data_modifica=now()
    from 
    (
      select a.soggetto_id from siac_t_soggetto a, siac_d_ambito b
      where a.ambito_id=b.ambito_id
      and a.soggetto_code = codice_sog_old
      and a.ente_proprietario_id = p_ente_proprietario_id
      and b.ambito_code='AMBITO_FIN'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
    ) as sub 
    where sub.soggetto_id=x.soggetto_id
    returning x.soggetto_id, x.soggetto_code, x.login_operazione , x.data_modifica
    into soggetto_id_new, soggetto_code_new, login_operazione_new, data_modifica_new
    ;
    
    if soggetto_id_new is null then 
	    v_messaggiorisultato:='nessun dato aggiornato';
    else 
        v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||soggetto_id_new::varchar ||' nuovo codice soggetto: '''||
        soggetto_code_new||''' , eseguito da '''||login_operazione_new || ''' in data : ' ||data_modifica_new::varchar;        
    end if;
    
    return v_messaggiorisultato;
    
exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
    	--raise notice '%',v_messaggiorisultato;
        return v_messaggiorisultato;
	when others  THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
    	--raise notice '%',v_messaggiorisultato;
        return v_messaggiorisultato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;
