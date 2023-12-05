/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_td_associa_provv_a_ordinativo (
  anno_bil varchar,
  p_ente_proprietario_id integer,
  tipo_ordinativo varchar,
  anno_ord varchar,
  numero_ord varchar,
  anno_provv varchar,
  numero_provv varchar,
  importo_reg numeric,
  numero_incident varchar
)
RETURNS varchar AS
$body$
DECLARE
	v_messaggiorisultato varchar;
    ord_id_new siac_t_ordinativo.ord_id%type ;
    prov_id_new siac_t_prov_cassa.provc_id%type;
    login_operazione_new siac_t_ordinativo.login_operazione%type;
    data_modifica_new siac_t_ordinativo.data_modifica%type;
    ord_provc_id_new  siac_r_ordinativo_prov_cassa.ord_provc_id%type;
    tipo_provv varchar;
BEGIN
    v_messaggiorisultato :='Errore';
 
      login_operazione_new = numero_incident;
      data_modifica_new = now();

	  if tipo_ordinativo = 'P' then
      	tipo_provv = 'S';
      else 
      	tipo_provv = 'E';  
	  end if;
      
      select a.ord_id into ord_id_new from siac_t_ordinativo a,
      siac_t_bil b, siac_t_periodo c, siac_d_ordinativo_tipo d
      where a.ord_anno = anno_ord::integer
      and a.ord_numero = numero_ord::integer
      and c.anno = anno_bil
      and d.ord_tipo_code=tipo_ordinativo
      and a.ente_proprietario_id=p_ente_proprietario_id
      and a.bil_id=b.bil_id
      and b.periodo_id=c.periodo_id
      and d.ord_tipo_id=a.ord_tipo_id
      and a.data_cancellazione is null
      and a.validita_fine is null;


      select a.provc_id into prov_id_new from siac_t_prov_cassa a, siac_d_prov_cassa_tipo b
      where a.provc_anno =anno_provv::integer
      and a.provc_numero=numero_provv::integer
      and a.ente_proprietario_id=p_ente_proprietario_id
      and b.provc_tipo_code= tipo_provv
      and a.provc_tipo_id = b.provc_tipo_id;
      
      
      select a.ord_provc_id into ord_provc_id_new from siac_r_ordinativo_prov_cassa a
      where a.ord_id=ord_id_new 
      and a.provc_id=prov_id_new
      and a.data_cancellazione is null
      and a.validita_fine is null;

      if ord_id_new is not null and prov_id_new is not null 
         and ord_provc_id_new is null then 
           
            INSERT INTO 
              siac.siac_r_ordinativo_prov_cassa
            (
              ord_id,
              provc_id,
              ord_provc_importo,
              validita_inizio,
              ente_proprietario_id,
              login_operazione
            )
            VALUES (
              ord_id_new,
              prov_id_new,
              importo_reg,
              data_modifica_new,
              p_ente_proprietario_id,
              login_operazione_new
            );
    end if;
     

    if ord_id_new is null or prov_id_new is null or ord_provc_id_new is not null then 
	    v_messaggiorisultato:='nessun dato aggiornato';
    else 
        v_messaggiorisultato:= 'Eseguito aggiornamento dell''id ord '||ord_id_new::varchar ||' e provvisorio: '''||
        prov_id_new||''' , eseguito da '''||login_operazione_new || ''' in data : ' ||data_modifica_new::varchar;        
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
