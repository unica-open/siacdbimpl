/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_modifiche_entrata_spesa" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar,
  p_cdr varchar,
  p_cdc varchar
)
RETURNS TABLE (
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  bil_ele_code3 varchar,
  num_movimento numeric,
  anno_movimento integer,
  num_submovimento varchar,
  tipo_movimento varchar,
  num_modifica integer,
  motivazione_modifica varchar,
  importo_modifica numeric,
  tipo_modifica varchar,
  display_error varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_eser_int integer;
 
tipo_sac varchar;
var_sac varchar;
estremi_provv varchar;
atto_id integer;

BEGIN

bil_ele_code:='';
bil_ele_desc:='';
bil_ele_code2:='';
bil_ele_desc2:='';
bil_ele_code3:='';
num_movimento:=0;
anno_movimento:=0;
num_submovimento:='';
tipo_movimento:='';
num_modifica:=0;
motivazione_modifica:='';
importo_modifica:=0;
tipo_modifica:='';

anno_eser_int=p_anno ::INTEGER;

--15/04/2020 SIAC-7498.
-- Introdotte le modifiche per la gestione della SAC (Direzione/Settore) collegata all'atto.
-- La SAC puo' non essere specificata; viene verificata l'esistenza dell'atto indicato in
-- input e nel caso non esista o ne esista piu' di 1 e' restituito un errore.

display_error:='';
estremi_provv:= ' Numero: '|| p_numero_provv|| ' Anno: '||p_anno_provv||' Tipo: '||p_tipo_provv;

if p_cdr IS not null and trim(p_cdr) <> '' and p_cdr <> '999' then
	if p_cdc IS not null and trim(p_cdc) <> '' and p_cdc <> '999' then
    	tipo_sac:= 'CDC';
        var_sac:=p_cdc;
        estremi_provv:=estremi_provv|| ' SAC: '||p_cdc;
    else
    	tipo_sac:= 'CDR';
        var_sac:=p_cdr;
        estremi_provv:=estremi_provv|| ' SAC: '||p_cdr;
    end if;
else
	tipo_sac:= '';
    var_sac:='';
end if;

--specificata la SAC
if tipo_sac <> '' then
  begin
      select t_atto_amm.attoamm_id
          into STRICT  atto_id
      from siac_t_atto_amm t_atto_amm,
          siac_r_atto_amm_class r_atto_amm_class,
          siac_t_class t_class,
          siac_d_class_tipo d_class_tipo,
          siac_d_atto_amm_tipo	tipo_atto
      where t_atto_amm.attoamm_id=r_atto_amm_class.attoamm_id
        and r_atto_amm_class.classif_id=t_class.classif_id
        and t_class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
        and t_atto_amm.ente_proprietario_id =p_ente_prop_id
        and t_atto_amm.attoamm_anno=p_anno_provv
        and t_atto_amm.attoamm_numero=p_numero_provv
        and tipo_atto.attoamm_tipo_code=p_tipo_provv
        and t_class.classif_code=var_sac
        and t_atto_amm.data_cancellazione IS NULL
        and r_atto_amm_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL
        and tipo_atto.data_cancellazione IS NULL;  
  EXCEPTION        
  WHEN NO_DATA_FOUND THEN
        raise notice 'atto_id = %', atto_id;
            display_error := 'Non esiste un provvedimento '||estremi_provv;
            return next;
            return;         
     WHEN TOO_MANY_ROWS THEN
        raise notice 'atto_id = %', atto_id;
              display_error := 'Esistono  piu'' provvedimenti '||estremi_provv;
              return next;
              return;     
  end;
ELSE
	begin
        select t_atto_amm.attoamm_id
            into STRICT atto_id
        from siac_t_atto_amm t_atto_amm,        
            siac_d_atto_amm_tipo	tipo_atto
        where t_atto_amm.attoamm_tipo_id=tipo_atto.attoamm_tipo_id
          and t_atto_amm.ente_proprietario_id =p_ente_prop_id
          and t_atto_amm.attoamm_anno=p_anno_provv
          and t_atto_amm.attoamm_numero=p_numero_provv
          and tipo_atto.attoamm_tipo_code=p_tipo_provv
          and t_atto_amm.data_cancellazione IS NULL
          and tipo_atto.data_cancellazione IS NULL
        group by t_atto_amm.attoamm_id;
      EXCEPTION        
        WHEN NO_DATA_FOUND THEN
              raise notice 'atto_id = %', atto_id;
                  display_error := 'Non esiste un provvedimento '||estremi_provv;
                  return next;
                  return;         
           WHEN TOO_MANY_ROWS THEN
              raise notice 'atto_id = %', atto_id;
                    display_error := 'Esistono piu'' provvedimenti '||estremi_provv;
                    return next;
                    return;             
    end;
end if;

raise notice 'attoamm_id = %',atto_id;

RTN_MESSAGGIO:='Estrazione dei dati delle modifiche  ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
with modifiche as (      
      select t_modifica.mod_id,
      		t_modifica.mod_num,
            t_modifica.mod_desc,	
            r_modifica_stato.mod_stato_r_id ,
            d_modifica_tipo.mod_tipo_code,
            d_modifica_tipo.mod_tipo_desc               
          from siac_t_modifica t_modifica,   
          		siac_d_modifica_tipo d_modifica_tipo,    
                siac_r_modifica_stato r_modifica_stato,     
                siac_d_modifica_stato d_modifica_stato,     
                siac_t_atto_amm t_atto_amm ,
                siac_d_atto_amm_tipo	tipo_atto
          where t_modifica.attoamm_id=t_atto_amm.attoamm_id  
          		and tipo_atto.attoamm_tipo_id= t_atto_amm.attoamm_tipo_id 
          		and t_modifica.mod_tipo_id= d_modifica_tipo.mod_tipo_id     
                and r_modifica_stato.mod_id=  t_modifica.mod_id   
                and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id
              and t_modifica.ente_proprietario_id=p_ente_prop_id
              and t_atto_amm.attoamm_id= atto_id
              --AND t_atto_amm.attoamm_numero=p_numero_provv
              --AND t_atto_amm.attoamm_anno=p_anno_provv
              --AND tipo_atto.attoamm_tipo_code=p_tipo_provv
              AND d_modifica_stato.mod_stato_code <>'A' --Annullato           
              AND t_modifica.data_cancellazione IS NULL
              AND t_atto_amm.data_cancellazione IS NULL
              AND tipo_atto.data_cancellazione IS NULL
              AND d_modifica_tipo.data_cancellazione IS NULL
              AND r_modifica_stato.data_cancellazione IS NULL
              AND d_modifica_stato.data_cancellazione IS NULL   ),
 movimenti as (
		SELECT t_movgest.movgest_id, t_movgest_ts.movgest_ts_id,
        		t_movgest_ts_det_mod.mod_stato_r_id,
        		t_movgest.movgest_anno, 
      			t_movgest.movgest_numero,
            	t_movgest_ts.movgest_ts_code,
                d_movgest_ts_tipo.movgest_ts_tipo_code,     
                d_movgest_tipo.movgest_tipo_code,       
                t_movgest_ts_det_mod.movgest_ts_det_importo
            FROM siac_t_movgest t_movgest,
            	siac_t_bil t_bil,
                siac_t_periodo t_periodo,
            	siac_t_movgest_ts t_movgest_ts,    
                siac_d_movgest_tipo d_movgest_tipo,            
                siac_t_movgest_ts_det t_movgest_ts_det,
                siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,
                siac_d_movgest_ts_tipo d_movgest_ts_tipo,
                siac_r_movgest_ts_stato r_movgest_ts_stato,
                siac_d_movgest_stato d_movgest_stato ,
                siac_t_movgest_ts_det_mod t_movgest_ts_det_mod
          	WHERE t_movgest.movgest_id=t_movgest_ts.movgest_id    
            	AND t_bil.bil_id= t_movgest.bil_id   
                AND t_periodo.periodo_id=t_bil.periodo_id    
            	AND d_movgest_tipo.movgest_tipo_id=t_movgest.movgest_tipo_id 
                 AND r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id     
               AND r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id   	
               AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
               AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id
                AND d_movgest_ts_tipo.movgest_ts_tipo_id=t_movgest_ts.movgest_ts_tipo_id
                and t_movgest_ts_det_mod.movgest_ts_det_id=t_movgest_ts_det.movgest_ts_det_id
                AND t_movgest.ente_proprietario_id=p_ente_prop_id
                AND t_periodo.anno =p_anno               
                AND d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A' -- importo attuale 
                AND d_movgest_stato.movgest_stato_code<>'A' -- non gli annullati
                AND  t_movgest_ts.data_cancellazione IS NULL
                AND  t_movgest.data_cancellazione IS NULL   
                AND t_bil.data_cancellazione IS NULL 
                AND t_periodo.data_cancellazione IS NULL
                AND  d_movgest_tipo.data_cancellazione IS NULL            
                AND t_movgest_ts_det.data_cancellazione IS NULL
                AND d_movgest_ts_det_tipo.data_cancellazione IS NULL
                AND d_movgest_ts_tipo.data_cancellazione IS NULL
                AND r_movgest_ts_stato.data_cancellazione IS NULL
                AND d_movgest_stato.data_cancellazione IS NULL
                AND t_movgest_ts_det_mod.data_cancellazione IS NULL),
capitoli as(
        	select r_movgest_bil_elem.movgest_id,
            	t_bil_elem.elem_id,
            	t_bil_elem.elem_code,
                t_bil_elem.elem_code2,
                t_bil_elem.elem_code3,
                t_bil_elem.elem_desc,
                t_bil_elem.elem_desc2
            from 	siac_r_movgest_bil_elem r_movgest_bil_elem,
            	siac_t_bil_elem t_bil_elem
            where r_movgest_bil_elem.elem_id=t_bil_elem.elem_id            
            	AND r_movgest_bil_elem.ente_proprietario_id=p_ente_prop_id
            	AND t_bil_elem.data_cancellazione IS NULL
                AND r_movgest_bil_elem.data_cancellazione IS NULL)                                                   
SELECT COALESCE(capitoli.elem_code,'')::varchar bil_ele_code,
	COALESCE(capitoli.elem_desc,'')::varchar bil_ele_desc,
    COALESCE(capitoli.elem_code2,'')::varchar bil_ele_code2,
   	COALESCE(capitoli.elem_desc2,'')::varchar bil_ele_desc2,
    COALESCE(capitoli.elem_code3,'')::varchar bil_ele_code3,
    movimenti.movgest_numero::numeric num_movimento,
    movimenti.movgest_anno::integer anno_movimento,
    movimenti.movgest_ts_code::varchar num_submovimento,
    CASE WHEN movimenti.movgest_tipo_code = 'A' --Impegno = entrata
      THEN CASE WHEN movimenti.movgest_ts_tipo_code = 'T'
            THEN 'MAC'::varchar 
            ELSE 'MSA'::varchar 
            END
      ELSE CASE WHEN movimenti.movgest_ts_tipo_code = 'T'
            THEN 'MIM'::varchar 
            ELSE 'MSI'::varchar 
            END 
      END tipo_movimento,
    modifiche.mod_num::integer num_modifica,
	modifiche.mod_tipo_desc::varchar motivazione_modifica,
	movimenti.movgest_ts_det_importo::numeric importo_modifica,
    CASE WHEN movimenti.movgest_tipo_code = 'I' --Impegno = spesa
    	THEN 'S'::varchar
        ELSE 'E'::varchar END tipo_modifica,
    ''::varchar display_error
FROM modifiche 
	INNER JOIN movimenti on movimenti.mod_stato_r_id=modifiche.mod_stato_r_id  
    LEFT JOIN capitoli on capitoli.movgest_id = movimenti.movgest_id
ORDER BY anno_movimento, num_movimento, num_submovimento) query_totale;

RTN_MESSAGGIO:='Fine Estrazione dei dati delle modifiche  ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessuna modifica trovata' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;