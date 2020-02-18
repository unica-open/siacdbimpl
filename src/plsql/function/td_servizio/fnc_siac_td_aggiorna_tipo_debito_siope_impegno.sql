/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_aggiorna_tipo_debito_siope_impegno (
  anno_bil varchar,
  p_ente_proprietario_id integer,
  anno_impegno varchar,
  num_impegno varchar,
  tipo_debito_siope varchar,
  motivo_assenza_cig varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
v_messaggiorisultato varchar;
movgest_ts_id_new siac_t_movgest_ts.movgest_ts_id%type ;
siope_tipo_debito_id_new siac_t_movgest_ts.siope_tipo_debito_id%type;  
siope_assenza_motivazione_id_new siac_t_movgest_ts.siope_assenza_motivazione_id%type;
login_operazione_new siac_t_movgest_ts.login_operazione%type;
data_modifica_new siac_t_movgest_ts.data_modifica%type;
BEGIN
v_messaggiorisultato :='Errore';

if tipo_debito_siope = 'CO' and motivo_assenza_cig <> 'CIG' then

        UPDATE 
          siac.siac_t_movgest_ts x
        SET 
          siope_tipo_debito_id = sub.siope_tipo_debito_id,
          siope_assenza_motivazione_id = sub.siope_assenza_motivazione_id,
          login_operazione = login_operazione || ' - ' || numero_incident,
          data_modifica=now() 
        from (
        select b.movgest_ts_id, d.siope_tipo_debito_id, e.siope_assenza_motivazione_id 
        from siac_t_movgest a, siac_t_movgest_ts b,
        siac_t_bil c, siac_d_siope_tipo_debito d,
        siac_d_siope_assenza_motivazione e,
        siac_d_movgest_tipo f, 
        siac_t_periodo g
        where 
        a.ente_proprietario_id= p_ente_proprietario_id -- id ente proprietario
        and a.movgest_anno=anno_impegno::integer    -- anno impegno
        and a.movgest_numero=num_impegno::numeric  -- numero impegno 
        and a.movgest_id=b.movgest_id
        --and c.bil_code = 'BIL_' || anno_bil -- anno bilancio
        and c.bil_id=a.bil_id
        and f.movgest_tipo_code='I'
        and g.periodo_id=c.periodo_id
        and g.anno=anno_bil -- anno bilancio
        and d.siope_tipo_debito_code = tipo_debito_siope             -- CO = Commerciale - NC = Non Commerciale 
        and e.siope_assenza_motivazione_code = motivo_assenza_cig     -- Codici che si vedono a video
        and d.ente_proprietario_id=a.ente_proprietario_id
        and e.ente_proprietario_id=a.ente_proprietario_id
        and a.movgest_tipo_id=f.movgest_tipo_id
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and e.data_cancellazione is null
        and g.data_cancellazione is null
        and now() between a.validita_inizio and coalesce (a.validita_fine, now())
        ) as sub
        where sub.movgest_ts_id = x.movgest_ts_id
        --and coalesce(x.siope_tipo_debito_id, 0)<>sub.siope_tipo_debito_id
        --and coalesce(x.siope_assenza_motivazione_id,0)<>sub.siope_assenza_motivazione_id
   returning  
        x.movgest_ts_id,x.siope_tipo_debito_id, x.siope_assenza_motivazione_id,x.login_operazione,data_modifica  
        into movgest_ts_id_new,siope_tipo_debito_id_new,siope_assenza_motivazione_id_new, login_operazione_new, data_modifica_new;
     
   
elsif tipo_debito_siope = 'CO' and motivo_assenza_cig = 'CIG' then  

UPDATE 
        siac.siac_t_movgest_ts x
        SET 
          siope_tipo_debito_id = sub.siope_tipo_debito_id,
          siope_assenza_motivazione_id = null,
          login_operazione = login_operazione ||  ' - ' || numero_incident,
          data_modifica=now() 
        from (
        select b.movgest_ts_id, d.siope_tipo_debito_id
        from siac_t_movgest a, siac_t_movgest_ts b,
        siac_t_bil c, siac_d_siope_tipo_debito d,
        siac_d_movgest_tipo f, siac_t_periodo g
        where 
        a.ente_proprietario_id= p_ente_proprietario_id -- id ente proprietario
        and a.movgest_anno=anno_impegno::integer    -- anno impegno
        and a.movgest_numero=num_impegno::numeric  -- numero impegno 
        and a.movgest_id=b.movgest_id     
        and d.siope_tipo_debito_code = tipo_debito_siope             -- CO = Commerciale - NC = Non Commerciale 
        and c.bil_id=a.bil_id
        and d.ente_proprietario_id=a.ente_proprietario_id
        and a.movgest_tipo_id=f.movgest_tipo_id
        and f.movgest_tipo_code='I'
        and g.periodo_id=c.periodo_id
        and g.anno=anno_bil -- anno bilancio
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and f.data_cancellazione is null
        and g.data_cancellazione is null
        and now() between a.validita_inizio and coalesce (a.validita_fine, now())
        ) as sub
        where sub.movgest_ts_id = x.movgest_ts_id
        --and coalesce(x.siope_tipo_debito_id,0)<>sub.siope_tipo_debito_id
        returning   
        x.movgest_ts_id,x.siope_tipo_debito_id, x.login_operazione,data_modifica  
        into movgest_ts_id_new,siope_tipo_debito_id_new,login_operazione_new, data_modifica_new
        ;   
        
elsif tipo_debito_siope = 'NC' then

 UPDATE 
          siac.siac_t_movgest_ts x
        SET 
          siope_tipo_debito_id = sub.siope_tipo_debito_id,
          siope_assenza_motivazione_id = null,
          login_operazione = login_operazione ||  ' - ' || numero_incident,
          data_modifica=now() 
        from (
        select b.movgest_ts_id, d.siope_tipo_debito_id
        from siac_t_movgest a, siac_t_movgest_ts b,
        siac_t_bil c, siac_d_siope_tipo_debito d,
        siac_d_movgest_tipo f , siac_t_periodo g
        where 
        a.ente_proprietario_id= p_ente_proprietario_id -- id ente proprietario
        and a.movgest_anno=anno_impegno::integer    -- anno impegno
        and a.movgest_numero=num_impegno::numeric  -- numero impegno 
         and d.siope_tipo_debito_code = tipo_debito_siope             -- CO = Commerciale - NC = Non Commerciale 
        and c.bil_id=a.bil_id
        and d.ente_proprietario_id=a.ente_proprietario_id
        and a.movgest_tipo_id=f.movgest_tipo_id
        and f.movgest_tipo_code='I'
        and g.periodo_id=c.periodo_id
        and g.anno=anno_bil -- anno bilancio
        and a.movgest_id=b.movgest_id
        and a.data_cancellazione is null
        and b.data_cancellazione is null
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and f.data_cancellazione is null
        and g.data_cancellazione is null        
        and now() between a.validita_inizio and coalesce (a.validita_fine, now())
        ) as sub
        where sub.movgest_ts_id = x.movgest_ts_id
        --and coalesce(x.siope_tipo_debito_id,0)<>sub.siope_tipo_debito_id
        returning 
        x.movgest_ts_id,x.siope_tipo_debito_id,x.login_operazione,data_modifica  
        into movgest_ts_id_new,siope_tipo_debito_id_new, login_operazione_new, data_modifica_new;            
        

end if;


if movgest_ts_id_new is null then 
  v_messaggiorisultato:='nessun dato aggiornato';
else 
v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||movgest_ts_id_new::varchar
||' nuovo id tipo debito: '|| siope_tipo_debito_id_new::varchar
||' nuovo id assenza motivazione: '|| COALESCE ( siope_assenza_motivazione_id_new, 0)::varchar
||' , eseguito da '''||login_operazione_new || ''' in data : ' ||data_modifica_new::varchar;        
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
