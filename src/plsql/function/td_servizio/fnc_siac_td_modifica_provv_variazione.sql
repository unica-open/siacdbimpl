/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_modifica_provv_variazione (
  p_ente_proprietario_id integer,
  numero_variazione integer,
  anno_provv varchar,
  numero_provv varchar,
  tipo_provv varchar,
  anno_bil varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
	v_messaggiorisultato varchar;
    variazione_stato_id_new siac_r_variazione_stato.variazione_stato_id%type;
    attoamm_id_new siac_r_variazione_stato.attoamm_id%type;
    login_operazione_new siac_r_variazione_stato.login_operazione%type;
    data_modifica_new siac_r_variazione_stato.data_modifica%type;
BEGIN
    v_messaggiorisultato :='Errore';

update siac_r_variazione_stato x set 
attoamm_id=subquery.attoamm_idnew,
login_operazione = login_operazione || ' - ' || numero_incident  || ' - ' || 'attoamm_id_old='||subquery.attoamm_idold::varchar,
data_modifica=now()
  from (
   select
     b.variazione_stato_id, b.attoamm_id attoamm_idold,e.attoamm_id attoamm_idnew
  from siac_t_variazione a,siac_r_variazione_stato b, siac_d_variazione_stato c,siac_t_atto_amm d,
  siac_t_atto_amm e ,siac_d_atto_amm_tipo f,siac_t_bil g,siac_t_periodo h
   where a.ente_proprietario_id=p_ente_proprietario_id
  and b.variazione_id=a.variazione_id
  and a.variazione_num = numero_variazione
  and c.variazione_stato_tipo_id=b.variazione_stato_tipo_id
 and b.data_cancellazione is null
 and d.attoamm_id=b.attoamm_id
 and e.ente_proprietario_id=a.ente_proprietario_id
 and e.attoamm_anno=anno_provv
 and e.attoamm_numero=numero_provv::integer
 and f.attoamm_tipo_id=e.attoamm_tipo_id
 and f.attoamm_tipo_code=tipo_provv
 and g.bil_id=a.bil_id
 and g.periodo_id=h.periodo_id
 and h.anno=anno_bil) as  subquery
 where subquery.variazione_stato_id=x.variazione_stato_id
 and x.attoamm_id<>subquery.attoamm_idnew
returning 
x.variazione_stato_id, x.attoamm_id,  x.login_operazione , x.data_modifica
into 
variazione_stato_id_new, attoamm_id_new,  login_operazione_new, data_modifica_new
;
   
    
    if variazione_stato_id_new is null then 
	    v_messaggiorisultato:='nessun dato aggiornato';
    else 
        v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||variazione_stato_id_new::varchar ||' nuovo id provvedimento: '''||
        attoamm_id_new::varchar||''' , eseguito da '''||login_operazione_new || ''' in data : ' ||data_modifica_new::varchar;        
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
