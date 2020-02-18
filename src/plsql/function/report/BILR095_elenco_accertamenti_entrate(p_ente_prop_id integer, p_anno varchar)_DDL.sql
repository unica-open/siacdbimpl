/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR095_elenco_accertamenti_entrate" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  nome_ente varchar,
  bil_anno varchar,
  anno_capitolo integer,
  num_capitolo varchar,
  cod_articolo varchar,
  ueb varchar,
  descr_capitolo varchar,
  descr_articolo varchar,
  anno_provv varchar,
  num_provv integer,
  cod_tipo_provv varchar,
  desc_tipo_provv varchar,
  descr_strutt_amm varchar,
  cod_soggetto varchar,
  classe_soggetto varchar,
  descr_soggetto varchar,
  anno_accertamento integer,
  num_accertamento varchar,
  tipo_accertamento varchar,
  stato_accertamento varchar,
  descr_accertamento varchar,
  importo_accertamento numeric,
  scadenza_accertamento date,
  da_riaccertamento varchar,
  anno_riaccert integer,
  num_riaccert varchar,
  anno_accertamento_origine integer,
  num_accertamento_origine varchar,
  movgest_id integer,
  movgest_ts_id integer,
  prevista_fattura varchar
) AS
$body$
DECLARE
 elencoImpegniRec record;
 elencoAttrib record;
 elencoClass	record;
 annoCompetenza_int integer;
 sett_code varchar;
 sett_descr varchar;
 direz_code varchar;
 direz_descr varchar;
 classif_id_padre integer;
 conta_vincoli integer;
 
BEGIN
 
nome_ente='';
bil_anno='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
descr_capitolo='';
descr_articolo='';
anno_provv='';
num_provv=0;
cod_tipo_provv='';
desc_tipo_provv='';
descr_strutt_amm='';
cod_soggetto='';
classe_soggetto='';
descr_soggetto='';
anno_accertamento=0;
num_accertamento='';
tipo_accertamento='';
stato_accertamento='';
descr_accertamento='';
importo_accertamento=0;
scadenza_accertamento=NULL;
da_riaccertamento='';
anno_riaccert=0;
num_riaccert='';
anno_accertamento_origine=0;
num_accertamento_origine='';
movgest_id=0;
movgest_ts_id=0;
prevista_fattura='N';

annoCompetenza_int =p_anno ::INTEGER;

raise notice 'ora: % ',clock_timestamp()::varchar;
raise notice 'Estrazione dei dati degli accertamenti ';

for elencoImpegniRec IN
	select capitolo.elem_id,capitolo.elem_code,capitolo.elem_desc,
    	capitolo.elem_code2, capitolo.elem_desc2,capitolo.elem_code3,         
        t_mov_gest.movgest_id,anno_eserc.anno anno_bil,
        t_mov_gest.movgest_numero NUM_accertamento,t_mov_gest.movgest_anno ANNO_COMP_accertamento,  
        t_movgest_ts_det.movgest_ts_det_importo importo_accertamento, 
        t_movgest_ts.movgest_ts_scadenza_data scadenza_data,
        t_mov_gest.movgest_desc, anno_eserc.anno BIL_ANNO,
        t_ente_prop.ente_denominazione, d_movgest_stato.movgest_stato_code,
        d_movgest_stato.movgest_stato_desc, t_soggetto.soggetto_code,
        COALESCE(t_soggetto.soggetto_desc, '')  soggetto,
        d_soggetto_classe.soggetto_classe_code, d_soggetto_classe.soggetto_classe_desc,
        t_mov_gest.movgest_id, t_movgest_ts.movgest_ts_id,
        t_atto_amm.attoamm_numero, t_atto_amm.attoamm_anno, t_atto_amm.attoamm_id,
        t_atto_amm.attoamm_oggetto, t_movgest_ts.movgest_ts_id_padre,
        d_atto_amm_tipo.attoamm_tipo_code, d_atto_amm_tipo.attoamm_tipo_desc        
        from siac_t_movgest t_mov_gest,
            siac_d_movgest_tipo d_mov_gest_tipo,
            siac_t_movgest_ts_det t_movgest_ts_det,
            siac_d_movgest_ts_tipo   ts_mov_tipo, 
            siac_d_movgest_ts_det_tipo d_movgest_ts_det_tipo,           
            siac_r_movgest_bil_elem r_movgest_bil_elem, 
            siac_d_movgest_stato 	d_movgest_stato,
            siac_r_movgest_ts_stato r_movgest_ts_stato,
            siac_t_bil			bilancio,
            siac_t_periodo      anno_eserc,
            siac_t_ente_proprietario	t_ente_prop,
            siac_t_bil_elem		capitolo,
            siac_t_movgest_ts t_movgest_ts       
        left  join siac_r_movgest_ts_sog r_movgest_ts_sog 
        			on (r_movgest_ts_sog.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        AND  r_movgest_ts_sog.data_cancellazione is NULL)
        left join  siac_t_soggetto		t_soggetto 
        		on (t_soggetto.soggetto_id=r_movgest_ts_sog.soggetto_id                  		 
                        AND  t_soggetto.data_cancellazione is NULL)   
        left join siac_r_movgest_ts_sogclasse r_movgest_ts_sogclasse
        		on (r_movgest_ts_sogclasse.movgest_ts_id=t_movgest_ts.movgest_ts_id
                		AND r_movgest_ts_sogclasse.data_cancellazione IS NULL)
        left join siac_d_soggetto_classe  d_soggetto_classe
        		on (d_soggetto_classe.soggetto_classe_id=r_movgest_ts_sogclasse.soggetto_classe_id
                		AND d_soggetto_classe.data_cancellazione  IS NULL)
        left join siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm
        		on (r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                		AND r_movgest_ts_atto_amm.data_cancellazione IS NULL)
        left join siac_t_atto_amm		t_atto_amm
        		on (t_atto_amm.attoamm_id=r_movgest_ts_atto_amm.attoamm_id 
                		AND t_atto_amm.data_cancellazione IS NULL) 
        left join  siac_d_atto_amm_tipo  d_atto_amm_tipo
        		on (d_atto_amm_tipo.attoamm_tipo_id=t_atto_amm.attoamm_tipo_id
                		AND d_atto_amm_tipo.data_cancellazione IS NULL)                                   
        where d_mov_gest_tipo.movgest_tipo_id=t_mov_gest.movgest_tipo_id
                AND t_movgest_ts.movgest_id=t_mov_gest.movgest_id
                and t_movgest_ts.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
                AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                and d_movgest_ts_det_tipo.movgest_ts_det_tipo_id=t_movgest_ts_det.movgest_ts_det_tipo_id              
                AND r_movgest_bil_elem.elem_id=capitolo.elem_id
                AND r_movgest_bil_elem.movgest_id=t_mov_gest.movgest_id                                            
                AND bilancio.bil_id=capitolo.bil_id
                AND anno_eserc.periodo_id=bilancio.periodo_id
                and t_ente_prop.ente_proprietario_id=capitolo.ente_proprietario_id
                and r_movgest_ts_stato.movgest_stato_id=d_movgest_stato.movgest_stato_id
                and r_movgest_ts_stato.movgest_ts_id=t_movgest_ts.movgest_ts_id
                	/* A= Accertamento - I = Impegno */
                AND d_mov_gest_tipo.movgest_tipo_code = 'A'
                and anno_eserc.anno=p_anno
                	/* Testata */
                and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
                	/* Importo attuale */
                and d_movgest_ts_det_tipo.movgest_ts_det_tipo_code='A'
               -- and t_mov_gest.movgest_anno =annoCompetenza_int
                AND t_mov_gest.ente_proprietario_id=p_ente_prop_id             
                and t_mov_gest.data_cancellazione is NULL
                and d_mov_gest_tipo.data_cancellazione is NULL
                and t_movgest_ts.data_cancellazione is NULL
                and t_movgest_ts_det.data_cancellazione is NULL
                and r_movgest_bil_elem.data_cancellazione is NULL
                and bilancio.data_cancellazione is NULL
                and anno_eserc.data_cancellazione is NULL
                and ts_mov_tipo.data_cancellazione is NULL  
                and capitolo.data_cancellazione IS NULL
                and t_ente_prop.data_cancellazione is NULL 
                and d_movgest_ts_det_tipo.data_cancellazione IS NULL
                and r_movgest_ts_stato.data_cancellazione IS NULL
                and r_movgest_ts_stato.validita_fine is  null
                and d_movgest_stato.data_cancellazione IS NULL               
                ORDER BY  capitolo.elem_code, capitolo.elem_code2
loop
	nome_ente=elencoImpegniRec.ente_denominazione;
    bil_anno=elencoImpegniRec.BIL_ANNO;
    anno_capitolo=elencoImpegniRec.BIL_ANNO;
    num_capitolo=elencoImpegniRec.elem_code;
    cod_articolo=elencoImpegniRec.elem_code2;
    ueb=elencoImpegniRec.elem_code3;
    descr_capitolo=elencoImpegniRec.elem_desc;
    descr_articolo=elencoImpegniRec.elem_desc2;
    anno_provv=COALESCE(elencoImpegniRec.attoamm_anno,'');
    num_provv=COALESCE(elencoImpegniRec.attoamm_numero,0);
    if elencoImpegniRec.attoamm_tipo_code IS NOT NULL THEN
    	cod_tipo_provv=elencoImpegniRec.attoamm_tipo_code;
        desc_tipo_provv=COALESCE(elencoImpegniRec.attoamm_tipo_desc,'');
	end if;
    
    cod_soggetto=elencoImpegniRec.soggetto_code;
    if elencoImpegniRec.soggetto_classe_code IS NOT NULL THEN
    	classe_soggetto=elencoImpegniRec.soggetto_classe_code || ' - '|| elencoImpegniRec.soggetto_classe_desc;
    end if;
    descr_soggetto=elencoImpegniRec.soggetto;
    anno_accertamento=elencoImpegniRec.ANNO_COMP_accertamento;
    num_accertamento=elencoImpegniRec.NUM_accertamento;
    
    stato_accertamento=elencoImpegniRec.movgest_stato_code||' - '||elencoImpegniRec.movgest_stato_desc;
    descr_accertamento=elencoImpegniRec.movgest_desc;
    importo_accertamento=elencoImpegniRec.importo_accertamento;
    scadenza_accertamento=elencoImpegniRec.scadenza_data;    	
    
    movgest_id=elencoImpegniRec.movgest_id;
    movgest_ts_id=elencoImpegniRec.movgest_ts_id;
    
/* cerco gli attributi.

 */
    BEGIN
    	for elencoAttrib IN
      		SELECT b.attr_code, a.boolean, a.testo
    			from siac_r_movgest_ts_attr a,
    			siac_t_attr b
   			 where a.attr_id=b.attr_id
              and a.movgest_ts_id=elencoImpegniRec.movgest_ts_id            
              and a.data_cancellazione IS NULL
              and b.data_cancellazione IS NULL  
        loop
        
            IF elencoAttrib.attr_code='flagDaRiaccertamento' THEN
    			da_riaccertamento=elencoAttrib.boolean;
            ELSIF elencoAttrib.attr_code='numeroRiaccertato' THEN   
            	num_riaccert=COALESCE(elencoAttrib.testo,''); 
            ELSIF elencoAttrib.attr_code='annoRiaccertato' THEN   
                anno_riaccert=elencoAttrib.testo ::INTEGER;
            ELSIF elencoAttrib.attr_code='FlagCollegamentoAccertamentoFattura' THEN
            	prevista_fattura=elencoAttrib.boolean;
            end if;
        end loop;
    END;    
    	/* cerco l'eventuale accertamento origine */
    IF elencoImpegniRec.movgest_ts_id_padre IS NOT NULL THEN
    	BEGIN
        	SELECT a.movgest_anno, a.movgest_numero
            INTO anno_accertamento_origine, num_accertamento_origine
            FROM SIAC_T_MOVGEST a
            WHERE a.movgest_id = elencoImpegniRec.movgest_ts_id_padre;
            IF NOT FOUND THEN
            	anno_accertamento_origine=0;
                num_accertamento_origine='';
            END IF;
        END;
    END IF;
    
    
    
    /* cerco la struttura amministrativa */
	BEGIN    
          SELECT   t_class.classif_code, t_class.classif_desc, r_class_fam_tree.classif_id_padre 
          INTO sett_code, sett_descr, classif_id_padre      
              from siac_r_atto_amm_class r_atto_amm_class,
                  siac_r_class_fam_tree r_class_fam_tree,
                  siac_t_class			t_class,
                  siac_d_class_tipo		d_class_tipo ,
                  siac_t_atto_amm    		t_atto_amm               
          where 
              r_atto_amm_class.attoamm_id			= 	t_atto_amm.attoamm_id
              and t_class.classif_id 					= 	r_atto_amm_class.classif_id
              and t_class.classif_id 					= 	r_class_fam_tree.classif_id
              and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id
             AND d_class_tipo.classif_tipo_desc='Cdc(Settore)'
              and t_atto_amm.attoamm_id=elencoImpegniRec.attoamm_id
               AND r_atto_amm_class.data_cancellazione is NULL
               AND t_class.data_cancellazione is NULL
               AND d_class_tipo.data_cancellazione is NULL
               AND t_atto_amm.data_cancellazione is NULL
               and r_class_fam_tree.data_cancellazione is NULL;    
                                
              IF NOT FOUND THEN
                  /* se il settore non esiste restituisco un codice fittizio
                      e cerco se esiste la direzione */
                  sett_code='';
                  sett_descr='';
              
                BEGIN
                SELECT  t_class.classif_code, t_class.classif_desc
                    INTO direz_code, direz_descr
                    from siac_r_atto_amm_class r_atto_amm_class,
                        siac_t_class			t_class,
                        siac_d_class_tipo		d_class_tipo ,
                        siac_t_atto_amm    		t_atto_amm                 
                where 
                    r_atto_amm_class.attoamm_id 			= 	t_atto_amm.attoamm_id
                    and t_class.classif_id 					= 	r_atto_amm_class.classif_id
                    and d_class_tipo.classif_tipo_id		=	t_class.classif_tipo_id          
                   and d_class_tipo.classif_tipo_code='CDR'
                    and t_atto_amm.attoamm_id=elencoImpegniRec.attoamm_id
                     AND r_atto_amm_class.data_cancellazione is NULL
                     AND t_class.data_cancellazione is NULL
                     AND d_class_tipo.data_cancellazione is NULL
                     AND t_atto_amm.data_cancellazione is NULL;	
               IF NOT FOUND THEN
                  /* se non esiste la direzione restituisco un codice fittizio */
                direz_code='';
                direz_descr='';         
                END IF;
            END;
              
         ELSE
              /* cerco la direzione con l'ID padre del settore */
           BEGIN
            SELECT  t_class.classif_code, t_class.classif_desc
                INTO direz_code, direz_descr
            from siac_t_class t_class
            where t_class.classif_id= classif_id_padre;
            IF NOT FOUND THEN
              direz_code='';
              direz_descr='';  
            END IF;
            END;
              
          END IF;
       if direz_code <> '' THEN
          descr_strutt_amm = direz_code||' - ' ||direz_descr;
        else 
          descr_strutt_amm='';
        end if;
        
        if sett_code <> '' THEN
          descr_strutt_amm = descr_strutt_amm || ' - ' || sett_code ||' - ' ||sett_descr;
        end if;

      END;   
    
    
        
return next;

nome_ente='';
bil_anno='';
anno_capitolo=0;
num_capitolo='';
cod_articolo='';
ueb='';
descr_capitolo='';
descr_articolo='';
anno_provv='';
num_provv=0;
cod_tipo_provv='';
desc_tipo_provv='';
descr_strutt_amm='';
cod_soggetto='';
classe_soggetto='';
descr_soggetto='';
anno_accertamento=0;
num_accertamento='';
tipo_accertamento='';
stato_accertamento='';
descr_accertamento='';
importo_accertamento=0;
scadenza_accertamento=NULL;
da_riaccertamento='';
anno_riaccert=0;
num_riaccert='';
anno_accertamento_origine=0;
num_accertamento_origine='';

movgest_id=0;
movgest_ts_id=0;
prevista_fattura='N';

end loop;

exception
	when no_data_found THEN
		raise notice 'Dati degli accertamenti non trovati.' ;
		--return next;
	when others  THEN		
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'ACCERTAMENTI',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
RETURNS NULL ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;