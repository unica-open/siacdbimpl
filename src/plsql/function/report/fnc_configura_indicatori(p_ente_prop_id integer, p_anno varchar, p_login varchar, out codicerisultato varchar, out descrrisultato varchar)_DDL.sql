/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_configura_indicatori (
  p_ente_prop_id integer,
  p_anno varchar,
  p_login varchar,
  out codicerisultato varchar,
  out descrrisultato varchar
)
RETURNS record AS
$body$
DECLARE
  	DEF_NULL	constant varchar:=''; 
	RTN_MESSAGGIO varchar(1000):=DEF_NULL;   
    anno1 varchar;
    anno2 varchar;
    anno3 varchar;
    entePropIdCorr integer;
    elencoEnti record;
    annoDaInserire integer;
    proseguiGestione boolean;
	var_anno_bil_prev varchar;
    esisteNumAnniBilPrev integer;
    cod_esito varchar;
    desc_esito varchar;
    conta integer;
  
  
BEGIN
 
/*
 Procedura per configurare i dati degli indicatori.
 La procedura esegue le seguenti operazioni:
 - crea il parametro GESTIONE_NUM_ANNI_BIL_PREV_INDIC_anno se non  esiste ancora;
 - gli indicatori sintetici per l'anno di bilancio in input
 - configura  i dati del Rendiconto di Entrata e Spesa per i 3 anni precedenti quello
 	del bilancio, lanciando le rispettive procedure.
 La procedura presuppone che per l'ente in questione esistano gia' gli indicatori sintetici 
 sulla tabella "siac_t_voce_conf_indicatori_sint" che saranno configurati sulla tabella
  "siac_t_conf_indicatori_sint" per l'anno di bilancio in input.
 
 Parametri:
 	- p_ente_prop_id; ente da configurare; indicare 0 per configurarli tutti.  
  	- p_anno; anno di bilancio da configurare.
    - p_login; stringa da inserire nel campo login_operazione per i nuovi record.
  
 La procedura segnala l'esito delle operazioni:
 - codicerisultato = 0 se OK, -1 se errore;
 - descrrisultato = descrizione dell'errore o elenco degli enti configurati e la stringa
 	che indica che le operazioni sii sono concluse correttamente ad esempio:
      Ente 2 - Operazioni concluse correttamente
      Ente 15 - Operazioni concluse correttamente
     
 Se per qualche motivo si verificano errori per uno degli enti la procedura si interrompe.
  
*/

anno1:=(p_anno::integer -1)::varchar;  
anno2:=(p_anno::integer -2)::varchar;    
anno3:=(p_anno::integer -3)::varchar; 
var_anno_bil_prev:='CONF_NUM_ANNI_BIL_PREV_INDIC_'||p_anno;
descrrisultato:='';

-- ciclo sugli enti.	
-- se p_ente_prop_id = 0, voglio configurare tutti gli enti.
FOR elencoEnti IN
	SELECT *
    FROM siac_t_ente_proprietario a
    WHERE a.data_cancellazione IS NULL
    	AND (a.ente_proprietario_id = p_ente_prop_id AND p_ente_prop_id <> 0) OR
        	p_ente_prop_id=0
    ORDER BY a.ente_proprietario_id
loop

	entePropIdCorr :=elencoEnti.ente_proprietario_id;
    raise notice 'Ente = %', entePropIdCorr;
    esisteNumAnniBilPrev:=0;
    if descrrisultato = '' then	 
    	descrrisultato:='Ente '|| entePropIdCorr;
    else 
    	descrrisultato:=descrrisultato||chr(13)||'Ente '|| entePropIdCorr;
    end if;
    
	--Inserisco la variabile che dice quanti sono gli anni di rendiconto.
  INSERT INTO siac_d_gestione_livello (
    gestione_livello_code, gestione_livello_desc, gestione_tipo_id,
    validita_inizio, ente_proprietario_id, data_creazione,
    data_modifica, login_operazione)
  SELECT
   var_anno_bil_prev, '3', a.gestione_tipo_id, now(),  a.ente_proprietario_id, 
      now(), now(),  p_login
   FROM siac_d_gestione_tipo a
   WHERE  a.ente_proprietario_id=entePropIdCorr
      and a.gestione_tipo_code ='GESTIONE_NUM_ANNI_BIL_PREV_INDIC'
      and a.data_cancellazione IS NULL
      and not exists (select 1
        from siac_d_gestione_livello z
        where z.ente_proprietario_id=a.ente_proprietario_id
        and z.gestione_livello_code=var_anno_bil_prev);

      --verifico inserimento della variabile.
      conta:=0;
      select count(*)
          into conta
      from siac_d_gestione_livello z
      where z.ente_proprietario_id=entePropIdCorr
      and z.gestione_livello_code=var_anno_bil_prev;
  
      if conta = 0 then
          codicerisultato=-1;
          descrrisultato:=descrrisultato||' - Errore: variabile '|| var_anno_bil_prev|| ' non inserita. - Operazioni interrotte';
          RETURN;
      end if;

    		-- inserisco il record nella tabella di relazione.
	INSERT INTO siac_r_gestione_ente (
      gestione_livello_id,  validita_inizio, ente_proprietario_id,
      data_creazione,  data_modifica, login_operazione)
     SELECT
        gestione_livello_id, now(),  ente_proprietario_id, now(), now(), p_login
     from siac_d_gestione_livello a
        where  a.ente_proprietario_id=entePropIdCorr
            and a.gestione_livello_code =var_anno_bil_prev
            and a.data_cancellazione IS NULL
        and not exists (select 1
          from siac_r_gestione_ente z
          where z.ente_proprietario_id=a.ente_proprietario_id
          and z.gestione_livello_id=a.gestione_livello_id);

    --verifico inserimento nella tabella di relazione.
    conta:=0;          
    select count(*)
        into conta
    from siac_r_gestione_ente a, siac_d_gestione_livello b
    where b.gestione_livello_id=a.gestione_livello_id
    and a.ente_proprietario_id=entePropIdCorr
    and b.gestione_livello_code=var_anno_bil_prev;

    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: relazione su siac_r_gestione_ente per la variabile '|| var_anno_bil_prev|| ' Non inserita. - Operazioni interrotte';
        RETURN;
    end if;          
      
         -- inserisco gli indicatori sintetici sulla tabella siac_t_conf_indicatori_sint
         -- per l'anno di bilancio in input.
         -- sono prese le voci presenti su siac_t_voce_conf_indicatori_sint che quindi
         -- DEVONO esistere per l'ente gestito.
         -- Se non esistono occorre prima crearle magari copiandolo da un altro ente.
    INSERT INTO  siac_t_conf_indicatori_sint (
    voce_conf_ind_id,
      bil_id,
      conf_ind_valore_anno,
      conf_ind_valore_anno_1,
      conf_ind_valore_anno_2,
      conf_ind_valore_tot_miss_13_anno,
      conf_ind_valore_tot_miss_13_anno_1 ,
      conf_ind_valore_tot_miss_13_anno_2 ,
      conf_ind_valore_tutte_spese_anno ,
      conf_ind_valore_tutte_spese_anno_1 ,
      conf_ind_valore_tutte_spese_anno_2 ,
      validita_inizio,
      validita_fine,
      ente_proprietario_id,
      data_creazione,
      data_modifica,
      data_cancellazione,
      login_operazione)
    SELECT t_voce_ind.voce_conf_ind_id, t_bil.bil_id, NULL, NULL, NULL,
        NULL, NULL, NULL, NULL, NULL, NULL,
        now(), NULL, t_ente.ente_proprietario_id,  now(), now(), NULL, p_login
    FROM siac_t_ente_proprietario t_ente,
        siac_t_bil t_bil,
        siac_t_periodo t_periodo,
        siac_t_voce_conf_indicatori_sint t_voce_ind
    where t_ente.ente_proprietario_id =t_bil.ente_proprietario_id
        and t_bil.periodo_id=t_periodo.periodo_id
        and t_voce_ind.ente_proprietario_id=t_bil.ente_proprietario_id
        and t_ente.ente_proprietario_id = entePropIdCorr
        and t_periodo.anno=p_anno    	
        and t_ente.data_cancellazione IS NULL
        and	t_bil.data_cancellazione IS NULL
        and	t_periodo.data_cancellazione IS NULL
        and t_voce_ind.data_cancellazione IS NULL
        and not exists (select 1
          from siac_t_conf_indicatori_sint z
          where z.bil_id=t_bil.bil_id
          and z.ente_proprietario_id=t_ente.ente_proprietario_id
          and z.voce_conf_ind_id=t_voce_ind.voce_conf_ind_id);
          
    --verifico inserimento degli indicatori sintetici.
    conta:=0;          
    select count(*)
        into conta
    from siac_t_conf_indicatori_sint ind,
    	siac_t_bil t_bil,
        siac_t_periodo t_periodo
    where ind.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
    	and ind.ente_proprietario_id=entePropIdCorr
    	and t_periodo.anno=p_anno
        and ind.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL;

    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: indicatori sintetici non inseriti. - Operazioni interrotte';
        RETURN;
    end if;           
         
     
 	--CONFIGURAZIONE dati del rendiconto per gli INDICATORI ANALITICI. 
    	--Spesa anno-1     
    select *
    	into cod_esito, desc_esito 
    from  "fnc_configura_indicatori_spesa"(entePropIdCorr,p_anno,anno1,false, false)a;--a.codicerisultato, a.descrrisultato
	        
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di spesa - anno '||
                anno1||': '||desc_esito;	
        return;
    end if;
     
    	--Spesa anno-2
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_spesa"(entePropIdCorr,p_anno,anno2,false, false);
   
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di spesa - anno '||
                anno2||': '||desc_esito;	
        return;
    end if;
        
    	--Spesa anno-3 
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_spesa"(entePropIdCorr,p_anno,anno3,false, false);
		
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di spesa - anno '||
                anno3||': '||desc_esito;	
        return;
    end if;

--verifico inserimento di dati di rendiconto di spesa per gli indicatori analitici
    conta:=0;          
    select count(*)
        into conta
    from siac_t_conf_indicatori_spesa ind,
    	siac_t_bil t_bil,
        siac_t_periodo t_periodo
    where ind.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
    	and ind.ente_proprietario_id=entePropIdCorr
    	and t_periodo.anno=p_anno
        and ind.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL;
        
    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: dati del rendiconto di spesa non inseriti. - Operazioni interrotte';
        RETURN;
    end if;
   
		--Entrata anno-1   
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_entrata"(entePropIdCorr,p_anno,anno1,false, false);
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di entrata - anno '||
                anno1||': '||desc_esito;	
        return;
    end if;
    
    	--Entrata anno-2
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_entrata"(entePropIdCorr,p_anno,anno2,false, false);
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di entrata - anno '||
                anno2||': '||desc_esito;	
        return;
    end if;
    
    	--Entrata anno-3
    select *
    	into cod_esito, desc_esito 
	FROM "fnc_configura_indicatori_entrata"(entePropIdCorr,p_anno,anno3,false, false);  
    if cod_esito <> '0' then
        codiceRisultato:=cod_esito;
        descrRisultato:=descrRisultato|| ' - Errore configurazione dati rendiconto di entrata - anno '||
                anno3||': '||desc_esito;	
        return;
    end if;     
       
--verifico inserimento di dati di rendiconto di entrata per gli indicatori analitici
    conta:=0;          
    select count(*)
        into conta
    from siac_t_conf_indicatori_entrata ind,
    	siac_t_bil t_bil,
        siac_t_periodo t_periodo
    where ind.bil_id=t_bil.bil_id
    	and t_bil.periodo_id=t_periodo.periodo_id
    	and ind.ente_proprietario_id=entePropIdCorr
    	and t_periodo.anno=p_anno
        and ind.data_cancellazione IS NULL
        and t_bil.data_cancellazione IS NULL
        and t_periodo.data_cancellazione IS NULL;
        
    if conta = 0 then
        codicerisultato=-1;
        descrrisultato:=descrrisultato||' - Errore: dati del rendiconto di entrata non inseriti. - Operazioni interrotte';
        RETURN;
    end if;
    
    descrrisultato:=descrrisultato|| ' - Operazioni concluse correttamente';
end loop;
      
codicerisultato:=0;

EXCEPTION
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
        codicerisultato:=-1;
        descrrisultato:='Nessun dato trovato';
		return;
	when others  THEN
    	codicerisultato:=-1;
    	descrrisultato:= SQLSTATE;
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);        
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;