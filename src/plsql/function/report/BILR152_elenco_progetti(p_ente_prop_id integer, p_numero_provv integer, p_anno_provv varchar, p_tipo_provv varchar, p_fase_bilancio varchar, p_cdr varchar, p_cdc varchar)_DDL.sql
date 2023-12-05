/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_progetti" (
  p_ente_prop_id integer,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar,
  p_fase_bilancio varchar,
  p_cdr varchar,
  p_cdc varchar
)
RETURNS TABLE (
  code_progetto varchar,
  desc_progetto varchar,
  importo_progetto numeric,
  cronop_code varchar,
  cronop_desc varchar,
  progetto_id integer,
  display_error varchar
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

tipo_sac varchar;
var_sac varchar;
estremi_provv varchar;
atto_id integer;

BEGIN

code_progetto:='';
desc_progetto:='';

importo_progetto:=0;

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

RTN_MESSAGGIO:='Estrazione dei dati dei progetti ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- 10/04/2020 SIAC-7465 
-- 	Aggiunta la gestione della fase Bilancio (nuovo paramtro in input).

return query 
select query_totale.* from  (
  with elenco_programmi as (
      SELECT t_programma.programma_code code_progetto, 
          t_programma.programma_desc desc_progetto,
          t_programma.programma_id, cronop.cronop_code, cronop.cronop_desc
      FROM siac_t_programma t_programma
      			LEFT JOIN (select t_cronop.programma_id, t_cronop.cronop_code,
                			t_cronop.cronop_desc
                			from siac_t_cronop t_cronop,
                            	siac_r_cronop_stato r_cronop_stato,
                                siac_d_cronop_stato d_cronop_stato
                            where t_cronop.cronop_id=r_cronop_stato.cronop_id
                            	and r_cronop_stato.cronop_stato_id=d_cronop_stato.cronop_stato_id
                                and d_cronop_stato.cronop_stato_code <> 'AN' 
                                and t_cronop.data_cancellazione IS NULL 
                                and r_cronop_stato.data_cancellazione IS NULL
                                and d_cronop_stato.data_cancellazione IS NULL) cronop
                	ON cronop.programma_id=t_programma.programma_id,                    	
          siac_r_programma_atto_amm r_progr_atto_amm,
          siac_t_atto_amm t_atto_amm ,
          siac_d_atto_amm_tipo	tipo_atto,   
          siac_r_programma_stato r_progr_stato,
          siac_d_programma_stato d_progr_stato,
          siac_d_programma_tipo d_progr_tipo           
      WHERE t_programma.programma_id=r_progr_atto_amm.programma_id    
         AND t_atto_amm.attoamm_id=r_progr_atto_amm.attoamm_id
         AND tipo_atto.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id  
         AND r_progr_stato.programma_id=t_programma.programma_id 
         AND d_progr_stato.programma_stato_id=r_progr_stato.programma_stato_id
         AND d_progr_tipo.programma_tipo_id=t_programma.programma_tipo_id           
         AND r_progr_atto_amm.ente_proprietario_id=p_ente_prop_id
         and t_atto_amm.attoamm_id = atto_id
         --AND t_atto_amm.attoamm_numero=p_numero_provv
         --AND t_atto_amm.attoamm_anno=p_anno_provv
         --AND tipo_atto.attoamm_tipo_code=p_tipo_provv    
         and d_progr_tipo.programma_tipo_code=p_fase_bilancio
         AND d_progr_stato.programma_stato_code <> 'AN' --Annullato            
         AND t_programma.data_cancellazione IS NULL
         AND r_progr_atto_amm.data_cancellazione IS NULL                  
         AND t_atto_amm.data_cancellazione IS NULL
         AND tipo_atto.data_cancellazione IS NULL
         AND r_progr_stato.data_cancellazione IS NULL
         AND d_progr_stato.data_cancellazione IS NULL
         AND d_progr_tipo.data_cancellazione IS NULL),
      elenco_attr as (
      	SELECT r_progr_attr.programma_id,
        	t_attr.attr_code,
            r_progr_attr.testo, 
            r_progr_attr.numerico  ,
            r_progr_attr."boolean"
        FROM	siac_r_programma_attr r_progr_attr, 
            	siac_t_attr t_attr, 
            	siac_d_attr_tipo d_attr_tipo
        WHERE r_progr_attr.attr_id = t_attr.attr_id
        	AND t_attr.attr_tipo_id=d_attr_tipo.attr_tipo_id
            AND r_progr_attr.ente_proprietario_id = p_ente_prop_id
            AND t_attr.attr_code ='ValoreComplessivoProgramma'
            AND r_progr_attr.data_cancellazione IS NULL
         	AND t_attr.data_cancellazione IS NULL
         	AND d_attr_tipo.data_cancellazione IS NULL)
SELECT elenco_programmi.code_progetto::varchar code_progetto,
       elenco_programmi.desc_progetto::varchar desc_progetto,
       COALESCE(elenco_attr.numerico,0)::numeric importo_progetto,
       COALESCE(elenco_programmi.cronop_code,'')::varchar cronop_code,
       COALESCE(elenco_programmi.cronop_desc,'')::varchar cronop_desc,
       elenco_programmi.programma_id::integer progetto_id,
       ''::varchar display_error
FROM elenco_programmi
	left join elenco_attr on elenco_attr.programma_id=elenco_programmi.programma_id
ORDER BY code_progetto) query_totale ;
--UNION select '345677', ' DESC PROG 345677',1000, 'crono1', 'desc crono1', 333
--UNION select '345677', ' DESC PROG 345677',1000, 'crono2', 'desc crono2', 333;

RTN_MESSAGGIO:='Fine estrazione dei dati dei progetti ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun programma trovato' ;
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