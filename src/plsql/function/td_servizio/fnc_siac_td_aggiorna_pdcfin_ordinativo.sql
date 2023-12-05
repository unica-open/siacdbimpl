/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_aggiorna_pdcfin_ordinativo (
  anno_bil varchar,
  p_ente_proprietario_id integer,
  anno_mov varchar,
  codice_mov varchar,
  tipo_mov varchar,
  pdc_fin varchar,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
	v_messaggiorisultato varchar;
    mov_id_new siac_t_ordinativo.ord_id%type;
    login_operazione_new siac_t_ordinativo.login_operazione%type;
    data_modifica_new siac_t_ordinativo.data_modifica%type;
    classif_id_new siac_t_class.classif_id%type;
BEGIN
    v_messaggiorisultato :='Errore';
    
   
  
    select a.ord_id into mov_id_new 
    from siac_t_ordinativo a, 
    siac_t_bil d, siac_t_periodo e,
    siac_d_ordinativo_tipo f
    where 
    a.data_cancellazione is null
    and a.validita_fine is null
    and d.bil_id=a.bil_id
    and d.periodo_id=e.periodo_id
    and f.ord_tipo_id =a.ord_tipo_id
    and a.ente_proprietario_id=p_ente_proprietario_id
    and e.anno=anno_bil
    and a.ord_anno=anno_mov::integer
    and a.ord_numero =codice_mov::integer
    and f.ord_tipo_code =tipo_mov;
    
    
    select a.classif_id into classif_id_new from 
    siac_t_class a, siac_d_class_tipo b
    where 
     a.classif_tipo_id=b.classif_tipo_id
    and b.classif_tipo_code='PDC_V'
    and a.classif_code = pdc_fin
    and a.data_cancellazione is null
    and a.ente_proprietario_id=p_ente_proprietario_id;
    
    
    
    
    
    if classif_id_new is not null and 
    	mov_id_new is not null then 
    
          UPDATE 
            siac.siac_r_ordinativo_class 
          SET 
            validita_fine = now(),
            data_cancellazione = now(),
            login_operazione = login_operazione || ' - ' || numero_incident
          WHERE 
            ord_classif_id in (
               select x.ord_classif_id from siac_r_ordinativo_class x,
               siac_t_class y, siac_d_class_tipo z
               where x.ord_id =mov_id_new
               and x.classif_id=y.classif_id
               and y.classif_tipo_id=z.classif_tipo_id
               and z.classif_tipo_code='PDC_V'
               and x.data_cancellazione is null
               and x.validita_fine is null
            )
          ;
              
          INSERT INTO 
              siac.siac_r_ordinativo_class
            (
              ord_id,
              classif_id,
              validita_inizio,
              ente_proprietario_id,
              login_operazione
            )
            VALUES (
              mov_id_new,
              classif_id_new,
              now(),
              p_ente_proprietario_id,
              numero_incident
            ); 
       
   end if;


    
    if mov_id_new is null  then 
	    v_messaggiorisultato:='nessun dato aggiornato';
    elseif classif_id_new is null then 
        v_messaggiorisultato:='pdc fin nuovo non trovato';
    else 
        v_messaggiorisultato:= 'Eseguito aggiornamento dell''id '||mov_id_new::varchar ||
        ' pdc new = ' || pdc_fin ||
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
