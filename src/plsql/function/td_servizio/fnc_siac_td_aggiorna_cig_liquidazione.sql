/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_aggiorna_cig_liquidazione (
  anno_bil varchar,
  p_ente_proprietario_id integer,
  anno_liq varchar,
  num_liq varchar,
  codice_cig varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
v_messaggiorisultato varchar;
liq_id_new siac_t_liquidazione.liq_id%type ;
login_operazione_new siac_t_liquidazione.login_operazione%type;
data_modifica_new siac_t_liquidazione.data_modifica%type; 
BEGIN
v_messaggiorisultato :='Errore';

      -- se presente si chiude il record precedente

      UPDATE 
        siac.siac_r_liquidazione_attr x
      SET 
        validita_fine = now(),
        data_cancellazione = now(),
        login_operazione = login_operazione || ' - ' || numero_incident
      from ( 
            select m.liq_attr_id, m.liq_id
            from siac_t_movgest a, siac_t_movgest_ts b,
            siac_t_bil c, 
            siac_d_movgest_tipo f, siac_t_liquidazione g, siac_r_liquidazione_movgest h,
            siac_t_periodo i, siac_t_attr l, siac_r_liquidazione_attr m
            where 
            a.ente_proprietario_id= p_ente_proprietario_id 
            and i.periodo_id=c.periodo_id
            and i.anno= anno_bil
            and g.liq_anno = anno_liq::integer
            and g.liq_numero = num_liq::integer
            and c.bil_id=a.bil_id
            and a.movgest_tipo_id=f.movgest_tipo_id
            and f.movgest_tipo_code='I'
            and a.movgest_id=b.movgest_id
            and h.movgest_ts_id=b.movgest_ts_id
            and h.liq_id= g.liq_id
            and m.liq_id=g.liq_id
            and m.attr_id=l.attr_id
            and l.attr_code = 'cig'
            and m.data_cancellazione is null
            and a.data_cancellazione is null
            and b.data_cancellazione is null
            and c.data_cancellazione is null
            and f.data_cancellazione is null
            and g.data_cancellazione is null
            and h.data_cancellazione is null
            and i.data_cancellazione is null
            and now() between a.validita_inizio and coalesce (a.validita_fine, now())
            and now() between h.validita_inizio and coalesce (h.validita_fine, now())
            and now() between m.validita_inizio and coalesce (m.validita_fine, now())
        ) as sub
        where sub.liq_attr_id = x.liq_attr_id;
        


        -- si inserisce il nuovo valore cig
        
        INSERT INTO 
          siac.siac_r_liquidazione_attr 
        (
          liq_id,
          attr_id,
          testo,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )   select g.liq_id , l.attr_id, codice_cig, now() as data_modifica_new, 
        	p_ente_proprietario_id , numero_incident as login_operazione_new
            from siac_t_movgest a, siac_t_movgest_ts b,
            siac_t_bil c, 
            siac_d_movgest_tipo f, siac_t_liquidazione g, siac_r_liquidazione_movgest h,
            siac_t_periodo i, siac_t_attr l
            where 
            a.ente_proprietario_id= p_ente_proprietario_id 
            and i.periodo_id=c.periodo_id
            and i.anno = anno_bil
            and g.liq_anno = anno_liq::integer
            and g.liq_numero = num_liq::integer
            and c.bil_id=a.bil_id
            and a.movgest_tipo_id=f.movgest_tipo_id
            and f.movgest_tipo_code='I'
            and a.movgest_id=b.movgest_id
            and h.movgest_ts_id=b.movgest_ts_id
            and h.liq_id= g.liq_id
			and l.ente_proprietario_id=a.ente_proprietario_id
            and l.attr_code = 'cig'
            and a.data_cancellazione is null
            and b.data_cancellazione is null
            and c.data_cancellazione is null
            and f.data_cancellazione is null
            and g.data_cancellazione is null
            and h.data_cancellazione is null
            and i.data_cancellazione is null
            and now() between a.validita_inizio and coalesce (a.validita_fine, now())
            and now() between h.validita_inizio and coalesce (h.validita_fine, now())
            returning  
     		liq_id, numero_incident ,now()  
      		into liq_id_new, login_operazione_new, data_modifica_new;
 
        

if liq_id_new is null then 
  v_messaggiorisultato:='nessun dato aggiornato';
else 
v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||liq_id_new::varchar
||' , eseguito da '''||login_operazione_new || ''' in data : ' ||data_modifica_new::varchar;        
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
