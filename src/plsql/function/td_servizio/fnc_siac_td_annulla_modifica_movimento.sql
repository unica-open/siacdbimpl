/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_annulla_modifica_movimento (
  anno_bil varchar,
  p_ente_proprietario_id integer,
  anno_mov varchar,
  codice_mov varchar,
  tipo_mov varchar,
  numero_modifica varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
	v_messaggiorisultato varchar;
    mod_id_new siac_t_modifica.mod_id%type;
    login_operazione_new siac_t_bil_elem.login_operazione%type;
    data_modifica_new siac_t_bil_elem.data_modifica%type;
    delta_modifica numeric;
    id_modifica numeric;
    id_stato_a numeric;
BEGIN
    v_messaggiorisultato :='Errore';
    
    delta_modifica :=0; 
  
    select c.movgest_ts_det_importo into delta_modifica 
    from siac_t_movgest a, 
    siac_t_movgest_ts b, siac_t_movgest_ts_det_mod c,
    siac_t_bil d, siac_t_periodo e,
    siac_d_movgest_tipo f,
    siac_r_modifica_stato g, siac_t_modifica h, siac_d_modifica_stato i
    where 
    a.movgest_id=b.movgest_id
    and a.data_cancellazione is null
    and a.validita_fine is null
    and c.movgest_ts_id=b.movgest_ts_id
    and d.bil_id=a.bil_id
    and d.periodo_id=e.periodo_id
    and f.movgest_tipo_id=a.movgest_tipo_id
    and c.mod_stato_r_id = g.mod_stato_r_id
    and g.data_cancellazione is null
    and g.validita_fine is null
    and h.mod_id=g.mod_id
    and i.mod_stato_id=g.mod_stato_id
    and i.mod_stato_code <> 'A'
    and a.ente_proprietario_id=p_ente_proprietario_id
    and e.anno=anno_bil
    and a.movgest_anno=anno_mov::integer
    and a.movgest_numero=codice_mov::integer
    and f.movgest_tipo_code=tipo_mov
    and h.mod_num =numero_modifica::integer;

    select h.mod_id into id_modifica 
    from siac_t_movgest a, 
    siac_t_movgest_ts b, siac_t_movgest_ts_det_mod c,
    siac_t_bil d, siac_t_periodo e,
    siac_d_movgest_tipo f,
    siac_r_modifica_stato g, siac_t_modifica h, siac_d_modifica_stato i
    where 
    a.movgest_id=b.movgest_id
    and a.data_cancellazione is null
    and a.validita_fine is null
    and c.movgest_ts_id=b.movgest_ts_id
    and d.bil_id=a.bil_id
    and d.periodo_id=e.periodo_id
    and f.movgest_tipo_id=a.movgest_tipo_id
    and c.mod_stato_r_id = g.mod_stato_r_id
    and g.data_cancellazione is null
    and g.validita_fine is null
    and h.mod_id=g.mod_id
    and i.mod_stato_id=g.mod_stato_id
    and i.mod_stato_code <> 'A'
    and a.ente_proprietario_id=p_ente_proprietario_id
    and e.anno=anno_bil
    and a.movgest_anno=anno_mov::integer
    and a.movgest_numero=codice_mov::integer
    and f.movgest_tipo_code=tipo_mov
    and h.mod_num =numero_modifica::integer;

    
    if delta_modifica <> 0 then
    
        select x.mod_stato_id into id_stato_a from siac_d_modifica_stato x
        where x.ente_proprietario_id=p_ente_proprietario_id
        and x.mod_stato_code='A'; 
    
      
    UPDATE 
        siac.siac_r_modifica_stato x
      SET 
        mod_stato_id = id_stato_a,
        data_modifica = now(),
        login_operazione = login_operazione || ' - ' || numero_incident
      WHERE 
        mod_stato_r_id in 
      (
            select g.mod_stato_r_id
            from siac_t_movgest a, 
            siac_t_movgest_ts b, siac_t_movgest_ts_det_mod c,
            siac_t_bil d, siac_t_periodo e,
            siac_d_movgest_tipo f,
            siac_r_modifica_stato g, siac_t_modifica h, siac_d_modifica_stato i
            where 
            a.movgest_id=b.movgest_id
            and a.data_cancellazione is null
            and a.validita_fine is null
            and c.movgest_ts_id=b.movgest_ts_id
            and d.bil_id=a.bil_id
            and d.periodo_id=e.periodo_id
            and f.movgest_tipo_id=a.movgest_tipo_id
            and c.mod_stato_r_id = g.mod_stato_r_id
            and g.data_cancellazione is null
            and g.validita_fine is null
            and h.mod_id=g.mod_id
            and i.mod_stato_id=g.mod_stato_id
            and i.mod_stato_code <> 'A'
            and a.ente_proprietario_id=p_ente_proprietario_id
            and e.anno=anno_bil
            and a.movgest_anno=anno_mov::integer
            and a.movgest_numero=codice_mov::integer
            and f.movgest_tipo_code=tipo_mov
            and h.mod_num =numero_modifica::integer
       );
    
          
   
    
        UPDATE 
            siac.siac_t_movgest_ts_det x
          SET 
            movgest_ts_det_importo = sub.movgest_ts_det_importo - delta_modifica,
            data_modifica = now(),
            login_operazione = login_operazione || ' - ' || numero_incident
         from (  
            select l.movgest_ts_det_importo, l.movgest_ts_det_id
                from siac_t_movgest a, 
                siac_t_movgest_ts b, siac_t_movgest_ts_det_mod c,
                siac_t_bil d, siac_t_periodo e,
                siac_d_movgest_tipo f,
                siac_r_modifica_stato g, siac_t_modifica h, siac_d_modifica_stato i,
                siac_t_movgest_ts_det l, siac_d_movgest_ts_det_tipo m
                where 
                a.movgest_id=b.movgest_id
                and a.data_cancellazione is null
                and a.validita_fine is null
                and c.movgest_ts_id=b.movgest_ts_id
                and d.bil_id=a.bil_id
                and d.periodo_id=e.periodo_id
                and f.movgest_tipo_id=a.movgest_tipo_id
                and c.mod_stato_r_id = g.mod_stato_r_id
                and g.data_cancellazione is null
                and g.validita_fine is null
                and h.mod_id=g.mod_id
                and i.mod_stato_id=g.mod_stato_id
                and i.mod_stato_code = 'A'
                and l.movgest_ts_id=b.movgest_ts_id
                and l.movgest_ts_det_tipo_id =m.movgest_ts_det_tipo_id
                and m.movgest_ts_det_tipo_code='A'
                and a.ente_proprietario_id=p_ente_proprietario_id
                and e.anno=anno_bil
                and a.movgest_anno=anno_mov::integer
                and a.movgest_numero=codice_mov::integer
                and f.movgest_tipo_code=tipo_mov
                and h.mod_num =numero_modifica::integer
      ) as sub
      WHERE sub.movgest_ts_det_id = x.movgest_ts_det_id;
    
    end if;
    
    
    
    mod_id_new = id_modifica;
    
    if mod_id_new is null or delta_modifica = 0 then 
	    v_messaggiorisultato:='nessun dato aggiornato';
    else 
        v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||mod_id_new::varchar ||
        ' delta modifica = ' || delta_modifica ||
        ''' , eseguito da '''||numero_incident || ''' in data : ' ||now()::varchar;        
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
