/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR073_variazione_su_impegni_completa_spese" (
  p_ente_prop_id integer,
  p_anno varchar,
  anno_competenza varchar
)
RETURNS TABLE (
  nome_ente varchar,
  anno_bilancio varchar,
  sett_code varchar,
  sett_desc varchar,
  motivo_var_code varchar,
  motivo_var_desc varchar,
  numero_imp integer,
  anno_imp integer,
  bil_ele_code varchar,
  bil_ele_desc varchar,
  bil_ele_code2 varchar,
  bil_ele_desc2 varchar,
  num_delibera varchar,
  anno_delibera varchar,
  oggetto_delibera varchar,
  importo_var numeric,
  note_var varchar,
  soggetto varchar
) AS
$body$
DECLARE
elencoVariazioni record;

annoCapImp_int integer;
annoCompetenza_int integer;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;

BEGIN

elemTipoCode:='CAP-UG'; -- tipo capitolo spesa gestione      
annoCapImp_int:= p_anno::integer;
    
nome_ente='';
sett_code='';
sett_desc='';
motivo_var_code='';
motivo_var_desc='';
anno_imp=0;
numero_imp=0;
importo_var=0;
bil_ele_code='';
bil_ele_desc='';
num_delibera='';
anno_delibera='';
oggetto_delibera='';
note_var='';
soggetto='';
anno_bilancio='';


raise notice 'ora: % ',clock_timestamp()::varchar;

RTN_MESSAGGIO:='inizio estrazione delle variazioni ''.';
raise notice 'inizio estrazione delle variazioni ''.';


if anno_competenza IS NOT NULL AND  anno_competenza != '' then	
BEGIN
		/* se l'anno di competenza è specificato inserisco le condizioni per estrarre solo i dati
        che riguardano quell'anno di competenza */
    annoCompetenza_int = anno_competenza;

	for elencoVariazioni in
        select capitolo.elem_id,capitolo.elem_code,capitolo.elem_desc, capitolo.elem_code2, capitolo.elem_desc2,
        t_mov_gest.movgest_id,t_modifica.mod_num,t_modifica.mod_desc NOTE_VAR,anno_eserc.anno anno_bil,
        t_mov_gest.movgest_numero NUM_IMPEGNO,t_mov_gest.movgest_anno ANNO_COMP_IMPEGNO, 
        t_movgest_ts_det_mod.movgest_ts_det_importo IMPORTO, d_modifica_tipo.mod_tipo_code COD_MOTIVO, 
        d_modifica_tipo.mod_tipo_desc DESC_MOTIVO, t_ente_prop.ente_denominazione,
        t_atto_amm.attoamm_numero, t_atto_amm.attoamm_anno, t_atto_amm.attoamm_oggetto,
        COALESCE(t_soggetto.soggetto_desc, '')  soggetto,
        t_class.classif_code sett_code, t_class.classif_desc sett_desc
        from siac_t_movgest t_mov_gest,
            siac_d_movgest_tipo d_mov_gest_tipo,
            siac_t_movgest_ts_det t_movgest_ts_det,
            siac_d_movgest_ts_tipo   ts_mov_tipo, 
            siac_t_movgest_ts_det_mod t_movgest_ts_det_mod, 
            siac_r_modifica_stato r_modifica_stato,
            siac_t_modifica 	t_modifica,
            siac_d_modifica_tipo 	d_modifica_tipo,
            siac_d_modifica_stato 	d_modifica_stato,
            siac_d_bil_elem_tipo    t_capitolo,
            siac_d_bil_elem_stato stato_capitolo,
            siac_r_bil_elem_stato r_capitolo_stato,
            siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
            siac_t_atto_amm		t_atto_amm,
            siac_t_bil			bilancio,
            siac_t_periodo      anno_eserc,
            siac_t_ente_proprietario	t_ente_prop,
            siac_t_movgest_ts t_movgest_ts
        left  join siac_r_movgest_ts_sog r_movgest_ts_sog on (r_movgest_ts_sog.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        AND  r_movgest_ts_sog.data_cancellazione is NULL  )
        left join  siac_t_soggetto		t_soggetto on (t_soggetto.soggetto_id=r_movgest_ts_sog.soggetto_id    
                        AND  t_soggetto.data_cancellazione is NULL),
         siac_t_bil_elem		capitolo
        left join  siac_r_bil_elem_class r_bil_elem_class on (r_bil_elem_class.elem_id=capitolo.elem_id
                        AND r_bil_elem_class.data_cancellazione is NULL) ,
                        siac_t_class	t_class ,
                        siac_d_class_tipo	d_class_tipo                                             
        where d_mov_gest_tipo.movgest_tipo_id=t_mov_gest.movgest_tipo_id
                AND t_movgest_ts.movgest_id=t_mov_gest.movgest_id
                and t_movgest_ts.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
                AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_movgest_ts_det_mod.movgest_ts_det_id=t_movgest_ts_det.movgest_ts_det_id
                AND r_modifica_stato.mod_stato_r_id=t_movgest_ts_det_mod.mod_stato_r_id
                and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id        
                and t_modifica.mod_id  = r_modifica_stato.mod_id
                AND d_modifica_tipo.mod_tipo_id =t_modifica.mod_tipo_id
                AND t_capitolo.elem_tipo_id=capitolo.elem_tipo_id
                AND r_capitolo_stato.elem_id=capitolo.elem_id
                AND r_capitolo_stato.elem_stato_id=stato_capitolo.elem_stato_id
                AND r_movgest_bil_elem.elem_id=capitolo.elem_id
                AND r_movgest_bil_elem.movgest_id=t_mov_gest.movgest_id
                AND r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_atto_amm.attoamm_id=r_movgest_ts_atto_amm.attoamm_id
                AND bilancio.bil_id=capitolo.bil_id
                AND anno_eserc.periodo_id=bilancio.periodo_id
                and t_ente_prop.ente_proprietario_id=capitolo.ente_proprietario_id
                and  t_class.classif_id=r_bil_elem_class.classif_id
                and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                AND d_mov_gest_tipo.movgest_tipo_code = 'I'
                AND t_capitolo.elem_tipo_code =elemTipoCode
                and anno_eserc.anno=p_anno
                and d_modifica_stato.mod_stato_code='V'
                and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
                and stato_capitolo.elem_stato_code='VA'
                and t_mov_gest.movgest_anno =annoCompetenza_int
                AND t_mov_gest.ente_proprietario_id=p_ente_prop_id
                and d_class_tipo.classif_tipo_desc='Cdc(Settore)'
                and t_mov_gest.data_cancellazione is NULL
                and d_mov_gest_tipo.data_cancellazione is NULL
                and t_movgest_ts.data_cancellazione is NULL
                and t_movgest_ts_det.data_cancellazione is NULL
                and t_movgest_ts_det_mod.data_cancellazione is NULL
                and r_modifica_stato.data_cancellazione is NULL
                and t_modifica.data_cancellazione is NULL
                and d_modifica_tipo.data_cancellazione is NULL
                and capitolo.data_cancellazione is NULL
                and t_capitolo.data_cancellazione is NULL
                and r_movgest_bil_elem.data_cancellazione is NULL
                and bilancio.data_cancellazione is NULL
                and anno_eserc.data_cancellazione is NULL
                and d_modifica_stato.data_cancellazione is NULL
                and ts_mov_tipo.data_cancellazione is NULL  
                and stato_capitolo.data_cancellazione is NULL
                and r_capitolo_stato.data_cancellazione is NULL 
                and r_movgest_ts_atto_amm.data_cancellazione is NULL
                and t_atto_amm.data_cancellazione is NULL
                and t_ente_prop.data_cancellazione is NULL 
                ORDER BY d_modifica_tipo.mod_tipo_code, capitolo.elem_code, capitolo.elem_code2
        loop         
            nome_ente=elencoVariazioni.ente_denominazione;
            motivo_var_code=elencoVariazioni.COD_MOTIVO;
            motivo_var_desc=elencoVariazioni.DESC_MOTIVO;
            anno_imp=elencoVariazioni.ANNO_COMP_IMPEGNO;
            numero_imp=elencoVariazioni.NUM_IMPEGNO;
            importo_var=elencoVariazioni.IMPORTO;
            num_delibera=elencoVariazioni.attoamm_numero;
            anno_delibera=elencoVariazioni.attoamm_anno;
            oggetto_delibera=elencoVariazioni.attoamm_oggetto;    
            bil_ele_code=elencoVariazioni.elem_code;
            bil_ele_desc=elencoVariazioni.elem_desc;
            bil_ele_code2=elencoVariazioni.elem_code2;
            bil_ele_desc2=elencoVariazioni.elem_desc2;
            sett_code=elencoVariazioni.sett_code;
            sett_desc=elencoVariazioni.sett_desc;
            note_var=elencoVariazioni.NOTE_VAR;
            soggetto=elencoVariazioni.soggetto;
            anno_bilancio=elencoVariazioni.anno_bil;                    

          return next;

        nome_ente='';
        sett_code='';
        sett_desc='';
        motivo_var_code='';
        motivo_var_desc='';
        anno_imp=0;
        numero_imp=0;
        importo_var=0;
        bil_ele_code='';
        bil_ele_desc='';
        bil_ele_code2='';
        bil_ele_desc2='';
        num_delibera='';
        anno_delibera='';
        oggetto_delibera='';
        note_var='';
        soggetto='';
        anno_bilancio='';

    end loop;
    END;
ELSE
	BEGIN /* anno non specificato: estraggo tutto senza condizione seull'anno di bilancio */
    annoCompetenza_int= annoCapImp_int;
	for elencoVariazioni in
        select capitolo.elem_id,capitolo.elem_code,capitolo.elem_desc, capitolo.elem_code2, capitolo.elem_desc2,
        t_mov_gest.movgest_id,t_modifica.mod_num,t_modifica.mod_desc NOTE_VAR,anno_eserc.anno anno_bil,
        t_mov_gest.movgest_numero NUM_IMPEGNO,t_mov_gest.movgest_anno ANNO_COMP_IMPEGNO, 
        t_movgest_ts_det_mod.movgest_ts_det_importo IMPORTO, d_modifica_tipo.mod_tipo_code COD_MOTIVO, 
        d_modifica_tipo.mod_tipo_desc DESC_MOTIVO, t_ente_prop.ente_denominazione,
        t_atto_amm.attoamm_numero, t_atto_amm.attoamm_anno, t_atto_amm.attoamm_oggetto,
        COALESCE(t_soggetto.soggetto_desc, '')  soggetto,
        t_class.classif_code sett_code, t_class.classif_desc sett_desc
        from siac_t_movgest t_mov_gest,
            siac_d_movgest_tipo d_mov_gest_tipo,
            siac_t_movgest_ts_det t_movgest_ts_det,
            siac_d_movgest_ts_tipo   ts_mov_tipo, 
            siac_t_movgest_ts_det_mod t_movgest_ts_det_mod, 
            siac_r_modifica_stato r_modifica_stato,
            siac_t_modifica 	t_modifica,
            siac_d_modifica_tipo 	d_modifica_tipo,
            siac_d_modifica_stato 	d_modifica_stato,
            siac_d_bil_elem_tipo    t_capitolo,
            siac_d_bil_elem_stato stato_capitolo,
            siac_r_bil_elem_stato r_capitolo_stato,
            siac_r_movgest_bil_elem r_movgest_bil_elem,
            siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
            siac_t_atto_amm		t_atto_amm,
            siac_t_bil			bilancio,
            siac_t_periodo      anno_eserc,
            siac_t_ente_proprietario	t_ente_prop,
            siac_t_movgest_ts t_movgest_ts
        left  join siac_r_movgest_ts_sog r_movgest_ts_sog on (r_movgest_ts_sog.movgest_ts_id=t_movgest_ts.movgest_ts_id
                        AND  r_movgest_ts_sog.data_cancellazione is NULL  )
        left join  siac_t_soggetto		t_soggetto on (t_soggetto.soggetto_id=r_movgest_ts_sog.soggetto_id    
                        AND  t_soggetto.data_cancellazione is NULL),
         siac_t_bil_elem		capitolo
        left join  siac_r_bil_elem_class r_bil_elem_class on (r_bil_elem_class.elem_id=capitolo.elem_id
                        AND r_bil_elem_class.data_cancellazione is NULL) ,
                        siac_t_class	t_class ,
                        siac_d_class_tipo	d_class_tipo                                             
        where d_mov_gest_tipo.movgest_tipo_id=t_mov_gest.movgest_tipo_id
                AND t_movgest_ts.movgest_id=t_mov_gest.movgest_id
                and t_movgest_ts.movgest_ts_tipo_id  = ts_mov_tipo.movgest_ts_tipo_id       
                AND t_movgest_ts_det.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_movgest_ts_det_mod.movgest_ts_det_id=t_movgest_ts_det.movgest_ts_det_id
                AND r_modifica_stato.mod_stato_r_id=t_movgest_ts_det_mod.mod_stato_r_id
                and d_modifica_stato.mod_stato_id=r_modifica_stato.mod_stato_id        
                and t_modifica.mod_id  = r_modifica_stato.mod_id
                AND d_modifica_tipo.mod_tipo_id =t_modifica.mod_tipo_id
                AND t_capitolo.elem_tipo_id=capitolo.elem_tipo_id
                AND r_capitolo_stato.elem_id=capitolo.elem_id
                AND r_capitolo_stato.elem_stato_id=stato_capitolo.elem_stato_id
                AND r_movgest_bil_elem.elem_id=capitolo.elem_id
                AND r_movgest_bil_elem.movgest_id=t_mov_gest.movgest_id
                AND r_movgest_ts_atto_amm.movgest_ts_id=t_movgest_ts.movgest_ts_id
                AND t_atto_amm.attoamm_id=r_movgest_ts_atto_amm.attoamm_id
                AND bilancio.bil_id=capitolo.bil_id
                AND anno_eserc.periodo_id=bilancio.periodo_id
                and t_ente_prop.ente_proprietario_id=capitolo.ente_proprietario_id
                and  t_class.classif_id=r_bil_elem_class.classif_id
                and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
                AND d_mov_gest_tipo.movgest_tipo_code = 'I'
                AND t_capitolo.elem_tipo_code =elemTipoCode
                and anno_eserc.anno=p_anno
                and d_modifica_stato.mod_stato_code='V'
                and ts_mov_tipo.movgest_ts_tipo_code  = 'T' 
                and stato_capitolo.elem_stato_code='VA'
                and t_mov_gest.movgest_anno <=annoCompetenza_int
                AND t_mov_gest.ente_proprietario_id=p_ente_prop_id
                and d_class_tipo.classif_tipo_desc='Cdc(Settore)'
                and t_mov_gest.data_cancellazione is NULL
                and d_mov_gest_tipo.data_cancellazione is NULL
                and t_movgest_ts.data_cancellazione is NULL
                and t_movgest_ts_det.data_cancellazione is NULL
                and t_movgest_ts_det_mod.data_cancellazione is NULL
                and r_modifica_stato.data_cancellazione is NULL
                and t_modifica.data_cancellazione is NULL
                and d_modifica_tipo.data_cancellazione is NULL
                and capitolo.data_cancellazione is NULL
                and t_capitolo.data_cancellazione is NULL
                and r_movgest_bil_elem.data_cancellazione is NULL
                and bilancio.data_cancellazione is NULL
                and anno_eserc.data_cancellazione is NULL
                and d_modifica_stato.data_cancellazione is NULL
                and ts_mov_tipo.data_cancellazione is NULL  
                and stato_capitolo.data_cancellazione is NULL
                and r_capitolo_stato.data_cancellazione is NULL 
                and r_movgest_ts_atto_amm.data_cancellazione is NULL
                and t_atto_amm.data_cancellazione is NULL
                and t_ente_prop.data_cancellazione is NULL 
                ORDER BY d_modifica_tipo.mod_tipo_code, capitolo.elem_code, capitolo.elem_code2
        loop         
            nome_ente=elencoVariazioni.ente_denominazione;            
            motivo_var_code=elencoVariazioni.COD_MOTIVO;
            motivo_var_desc=elencoVariazioni.DESC_MOTIVO;
            anno_imp=elencoVariazioni.ANNO_COMP_IMPEGNO;
            numero_imp=elencoVariazioni.NUM_IMPEGNO;
            importo_var=elencoVariazioni.IMPORTO;
            num_delibera=elencoVariazioni.attoamm_numero;
            anno_delibera=elencoVariazioni.attoamm_anno;
            oggetto_delibera=elencoVariazioni.attoamm_oggetto;    
            bil_ele_code=elencoVariazioni.elem_code;
            bil_ele_desc=elencoVariazioni.elem_desc;
            bil_ele_code2=elencoVariazioni.elem_code2;
            bil_ele_desc2=elencoVariazioni.elem_desc2;
            sett_code=elencoVariazioni.sett_code;
            sett_desc=elencoVariazioni.sett_desc;
            note_var=elencoVariazioni.NOTE_VAR;
            soggetto=elencoVariazioni.soggetto;
            anno_bilancio=elencoVariazioni.anno_bil;                    

          return next;

        nome_ente='';
        sett_code='';
        sett_desc='';
        motivo_var_code='';
        motivo_var_desc='';
        anno_imp=0;
        numero_imp=0;
        importo_var=0;
        bil_ele_code='';
        bil_ele_desc='';
        bil_ele_code2='';
        bil_ele_desc2='';
        num_delibera='';
        anno_delibera='';
        oggetto_delibera='';
        note_var='';
        soggetto='';
        anno_bilancio='';

    end loop;    
END;
END IF;


raise notice 'ora: % ',clock_timestamp()::varchar;

raise notice 'fine estrazione delle variazioni';

--delete from siac_rep_mis_pro_tit_mac_riga_anni where utente=user_table;
--delete from siac_rep_cap_up where utente=user_table;


exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RTN_MESSAGGIO:='struttura bilancio altro errore';
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;