/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR152_elenco_progetti" (
  p_ente_prop_id integer,
  p_numero_provv integer,
  p_anno_provv varchar,
  p_tipo_provv varchar
)
RETURNS TABLE (
  code_progetto varchar,
  desc_progetto varchar,
  importo_progetto numeric
) AS
$body$
DECLARE

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;


BEGIN

code_progetto:='';
desc_progetto:='';

importo_progetto:=0;


RTN_MESSAGGIO:='Estrazione dei dati dei progetti ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
return query 
select query_totale.* from  (
  with elenco_programmi as (
      SELECT t_programma.programma_code code_progetto, 
          t_programma.programma_desc desc_progetto,
          t_programma.programma_id
      FROM siac_t_programma t_programma,
          siac_r_programma_atto_amm r_progr_atto_amm,
          siac_t_atto_amm t_atto_amm ,
          siac_d_atto_amm_tipo	tipo_atto,   
          siac_r_programma_stato r_progr_stato,
          siac_d_programma_stato d_progr_stato             
      WHERE t_programma.programma_id=r_progr_atto_amm.programma_id    
         AND t_atto_amm.attoamm_id=r_progr_atto_amm.attoamm_id
         AND tipo_atto.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id  
         AND r_progr_stato.programma_id=t_programma.programma_id 
         AND d_progr_stato.programma_stato_id=r_progr_stato.programma_stato_id           
         AND r_progr_atto_amm.ente_proprietario_id=p_ente_prop_id
         AND t_atto_amm.attoamm_numero=p_numero_provv
         AND t_atto_amm.attoamm_anno=p_anno_provv
         AND tipo_atto.attoamm_tipo_code=p_tipo_provv    
         AND d_progr_stato.programma_stato_code <> 'AN' --Annullato            
         AND t_programma.data_cancellazione IS NULL
         AND r_progr_atto_amm.data_cancellazione IS NULL                  
         AND t_atto_amm.data_cancellazione IS NULL
         AND tipo_atto.data_cancellazione IS NULL
         AND r_progr_stato.data_cancellazione IS NULL
         AND d_progr_stato.data_cancellazione IS NULL),
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
       COALESCE(elenco_attr.numerico,0)::numeric importo_progetto
FROM elenco_programmi
	left join elenco_attr on elenco_attr.programma_id=elenco_programmi.programma_id
ORDER BY code_progetto) query_totale ;

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