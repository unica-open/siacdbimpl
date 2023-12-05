/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_aggiorna_cig_ordinativo (
  anno_bil varchar,
  p_ente_proprietario_id integer,
  anno_ord varchar,
  num_ord varchar,
  codice_cig varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
v_messaggiorisultato varchar;
ord_id_new siac_t_ordinativo.ord_id%type ;
login_operazione_new siac_t_ordinativo.login_operazione%type;
data_modifica_new siac_t_ordinativo.data_modifica%type; 
BEGIN
v_messaggiorisultato :='Errore';

      -- se presente si chiude il record precedente
        UPDATE 
          siac.siac_r_ordinativo_attr 
        SET 
          validita_fine = now(),
          data_cancellazione = now(),
          login_operazione = login_operazione || ' - ' || numero_incident
        WHERE 
          ord_attr_id in (
              select e.ord_attr_id
              from siac_t_ordinativo a,
              siac_t_bil b,
              siac_t_periodo c, siac_t_attr d, siac_r_ordinativo_attr e,
              siac_d_ordinativo_tipo f
              where 
              a.ente_proprietario_id= p_ente_proprietario_id 
              and c.periodo_id=b.periodo_id
              and c.anno= anno_bil
              and a.ord_anno = anno_ord::integer
              and a.ord_numero = num_ord::integer
              and b.bil_id=a.bil_id
              and a.ord_tipo_id=f.ord_tipo_id
              and f.ord_tipo_code='P'
              and a.ord_id=e.ord_id
              and e.attr_id=d.attr_id	
              and d.attr_code = 'cig'
              and e.data_cancellazione is null
              and now() between e.validita_inizio and coalesce (e.validita_fine, now())
         ); 


        -- si inserisce il nuovo valore cig
        INSERT INTO 
            siac.siac_r_ordinativo_attr
          (
            ord_id,
            attr_id,
            testo,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select a.ord_id, d.attr_id, codice_cig, now(),
              p_ente_proprietario_id, numero_incident
              from siac_t_ordinativo a,
              siac_t_bil b,
              siac_t_periodo c, siac_t_attr d,
              siac_d_ordinativo_tipo f
              where 
              a.ente_proprietario_id= p_ente_proprietario_id 
              and c.periodo_id=b.periodo_id
              and c.anno= anno_bil
              and a.ord_anno = anno_ord::integer
              and a.ord_numero = num_ord::integer
              and b.bil_id=a.bil_id
              and a.ord_tipo_id=f.ord_tipo_id
              and f.ord_tipo_code='P'
              and a.ente_proprietario_id=d.ente_proprietario_id 
              and d.attr_code = 'cig'          
            returning  
     		ord_id, numero_incident ,now()  
      		into ord_id_new, login_operazione_new, data_modifica_new;
 
        

if ord_id_new is null then 
  v_messaggiorisultato:='nessun dato aggiornato';
else 
v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||ord_id_new::varchar
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
