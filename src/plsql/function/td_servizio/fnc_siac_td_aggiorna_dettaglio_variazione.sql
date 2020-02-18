/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_aggiorna_dettaglio_variazione (
  anno_bil varchar,
  p_ente_proprietario_id integer,
  codice_cap varchar,
  codice_art varchar,
  tipo_capitolo varchar,
  numero_variazione varchar,
  delta_stanziamento numeric,
  delta_residuo numeric,
  delta_cassa numeric,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
	v_messaggiorisultato varchar;
    cap_id_new siac_t_bil_elem.elem_id%type;
    login_operazione_new siac_t_bil_elem.login_operazione%type;
    data_modifica_new siac_t_bil_elem.data_modifica%type;
BEGIN
    v_messaggiorisultato :='Errore';

    UPDATE 
      siac.siac_t_bil_elem_det_var 
    SET 
      elem_det_importo = delta_cassa,
      data_modifica = now(),
      login_operazione = login_operazione || ' - ' || numero_incident
    WHERE 
    elem_det_var_id in (
      select e.elem_det_var_id from siac_t_bil a, siac_t_periodo b,
      siac_t_bil_elem c, siac_d_bil_elem_tipo d,
      siac_t_bil_elem_det_var e, siac_r_variazione_stato f,
      siac_t_variazione g, siac_d_bil_elem_det_tipo h
      where 
      a.ente_proprietario_id=p_ente_proprietario_id
      and a.periodo_id=b.periodo_id
      and a.bil_id=c.bil_id
      and d.elem_tipo_id=c.elem_tipo_id
      and b.anno=anno_bil
      and d.elem_tipo_code=tipo_capitolo
      and c.elem_code=codice_cap
      and c.elem_code2=codice_art
      and e.elem_id=c.elem_id
      and e.data_cancellazione is null
      and e.validita_fine is null
      and e.variazione_stato_id=f.variazione_stato_id
      and f.data_cancellazione is null
      and f.validita_fine is null
      and f.variazione_id=g.variazione_id
      and g.variazione_num = numero_variazione::integer
      and h.elem_det_tipo_id=e.elem_det_tipo_id
      and h.elem_det_tipo_code ='SCA'
      );
      
      
    UPDATE 
      siac.siac_t_bil_elem_det_var 
    SET 
      elem_det_importo = delta_residuo,
      data_modifica = now(),
      login_operazione = login_operazione || ' - ' || numero_incident
    WHERE 
    elem_det_var_id in (
      select e.elem_det_var_id from siac_t_bil a, siac_t_periodo b,
      siac_t_bil_elem c, siac_d_bil_elem_tipo d,
      siac_t_bil_elem_det_var e, siac_r_variazione_stato f,
      siac_t_variazione g, siac_d_bil_elem_det_tipo h
      where 
      a.ente_proprietario_id=p_ente_proprietario_id
      and a.periodo_id=b.periodo_id
      and a.bil_id=c.bil_id
      and d.elem_tipo_id=c.elem_tipo_id
      and b.anno=anno_bil
      and d.elem_tipo_code=tipo_capitolo
      and c.elem_code=codice_cap
      and c.elem_code2=codice_art
      and e.elem_id=c.elem_id
      and e.data_cancellazione is null
      and e.validita_fine is null
      and e.variazione_stato_id=f.variazione_stato_id
      and f.data_cancellazione is null
      and f.validita_fine is null
      and f.variazione_id=g.variazione_id
      and g.variazione_num = numero_variazione::integer
      and h.elem_det_tipo_id=e.elem_det_tipo_id
      and h.elem_det_tipo_code ='STR'
      );
 
    UPDATE 
      siac.siac_t_bil_elem_det_var 
    SET 
      elem_det_importo = delta_stanziamento,
      data_modifica = now(),
      login_operazione = login_operazione || ' - ' || numero_incident
    WHERE 
    elem_det_var_id in (
      select e.elem_det_var_id from siac_t_bil a, siac_t_periodo b,
      siac_t_bil_elem c, siac_d_bil_elem_tipo d,
      siac_t_bil_elem_det_var e, siac_r_variazione_stato f,
      siac_t_variazione g, siac_d_bil_elem_det_tipo h
      where 
      a.ente_proprietario_id=p_ente_proprietario_id
      and a.periodo_id=b.periodo_id
      and a.bil_id=c.bil_id
      and d.elem_tipo_id=c.elem_tipo_id
      and b.anno=anno_bil
      and d.elem_tipo_code=tipo_capitolo
      and c.elem_code=codice_cap
      and c.elem_code2=codice_art
      and e.elem_id=c.elem_id
      and e.data_cancellazione is null
      and e.validita_fine is null
      and e.variazione_stato_id=f.variazione_stato_id
      and f.data_cancellazione is null
      and f.validita_fine is null
      and f.variazione_id=g.variazione_id
      and g.variazione_num = numero_variazione::integer
      and h.elem_det_tipo_id=e.elem_det_tipo_id
      and h.elem_det_tipo_code ='STA'
      )
      returning  
      elem_id, numero_incident ,now()  
      into cap_id_new, login_operazione_new, data_modifica_new;
    

    
    if cap_id_new is null then 
	    v_messaggiorisultato:='nessun dato aggiornato';
    else 
        v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||cap_id_new::varchar ||
        ''' , eseguito da '''||login_operazione_new || ''' in data : ' ||data_modifica_new::varchar;        
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
