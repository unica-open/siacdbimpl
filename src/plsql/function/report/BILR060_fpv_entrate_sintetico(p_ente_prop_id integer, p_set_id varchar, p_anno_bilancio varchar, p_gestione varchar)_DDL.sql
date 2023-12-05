/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR060_fpv_entrate_sintetico" (
  p_ente_prop_id integer,
  p_set_id varchar,
  p_anno_bilancio varchar,
  p_gestione varchar
)
RETURNS TABLE (
  anno_out varchar,
  id_set integer,
  codice_set varchar,
  descrizione_set varchar,
  id_programma integer,
  codice_programma varchar,
  descrizione_programma varchar,
  id_cronop integer,
  codice_cronop varchar,
  descrizione_cronop varchar,
  entrata_prevista numeric,
  fpv_entrata_spesa_corrente numeric,
  fpv_entrata_spesa_conto_capitale numeric,
  totale numeric,
  fpv_entrata_complessivo numeric,
  tipo varchar
) AS
$body$
DECLARE
setRec record;
setrecpro record;


DEF_NULL	constant 	varchar:='';
def_spazio	constant 	varchar:=' ';  
RTN_MESSAGGIO 			varchar(1000):=DEF_NULL;
flag_gestione			VARCHAR;
--codice_programma		VARCHAR;
--codice_cronop			VARCHAR;
r_set_cronop_id 		INTEGER;
ente_proprietario_id 	INTEGER;
user_table 				VARCHAR;

BEGIN
anno_out='';
id_set=0;
codice_set='';
descrizione_set='';
id_programma=0;
id_cronop=0;
entrata_prevista=0;
fpv_entrata_spesa_corrente=0;
fpv_entrata_spesa_conto_capitale=0;
totale=0;
fpv_entrata_complessivo=0;
descrizione_programma='';
descrizione_cronop='';
codice_programma='';   

select fnc_siac_random_user()
into	user_table;
RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = false '||p_set_id||'.';
insert into siac_rep_set_cronop_fpv
 select 		gruppo.set_cronop_code			set_code,
                gruppo.set_cronop_desc			descr_set,
                gruppo.set_cronop_id			set_id,
                r_gruppo_crono.cronop_id		cronop_id,
                r_gruppo_crono.programma_id		programma_id,
                r_gruppo_crono.set_cronop_id	id_r_set_cronop,
                r_gruppo_crono.usa_gestione		gestione_flag,
                t_programma.programma_code		programma_codice,
                t_programma.programma_desc		programma_descrizione,
                t_cronop.cronop_code			cronop_codice,
                t_cronop.cronop_desc			cronop_descrizione,
                p_ente_prop_id					ente,
                user_table 						utente
    from   		siac_t_fpv_set_cronop 	gruppo,  	
                siac_r_fpv_set_cronop	r_gruppo_crono,
                siac_t_bil				bil,
                siac_t_periodo 			periodo, 
                siac_t_programma 		t_programma,
                siac_t_cronop 			t_cronop
        where		gruppo.set_cronop_code		=	p_set_id
        and			gruppo.set_cronop_id		=	r_gruppo_crono.set_cronop_id
        and			r_gruppo_crono.cronop_id	=	t_cronop.cronop_id
        and			r_gruppo_crono.usa_gestione	= FALSE
        and			r_gruppo_crono.programma_id	=	t_programma.programma_id
        and			gruppo.bil_id				=	bil.bil_id
        and			bil.periodo_id				=	periodo.periodo_id
        and			periodo.anno				=	p_anno_bilancio
        and			gruppo.ente_proprietario_id	=	p_ente_prop_id
        and			bil.ente_proprietario_id		=	gruppo.ente_proprietario_id
        and			periodo.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_programma.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_cronop.ente_proprietario_id		=	gruppo.ente_proprietario_id
        and			gruppo.data_cancellazione		is null
        and 		r_gruppo_crono.data_cancellazione is null 
        and			bil.data_cancellazione			is null
        and			periodo.data_cancellazione		is null
        and			t_programma.data_cancellazione			is null
        and			t_cronop.data_cancellazione			is null
        order by gestione_flag,id_programma,id_cronop;	
        
 RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = true '||p_set_id||'.';        
 insert into siac_rep_set_cronop_fpv
 select 		gruppo.set_cronop_code			set_code,
                gruppo.set_cronop_desc			descr_set,
                gruppo.set_cronop_id			set_id,
                r_gruppo_crono.cronop_id		cronop_id,
                r_gruppo_crono.programma_id		programma_id,
                r_gruppo_crono.set_cronop_id	id_r_set_cronop,
                r_gruppo_crono.usa_gestione		gestione_flag,
                COALESCE(t_programma.programma_code,'')		programma_codice,
                COALESCE(t_programma.programma_desc,'')		programma_descrizione,
                ' ',
                ' ',
                p_ente_prop_id					ente,
                user_table 						utente
    from   		siac_t_fpv_set_cronop 	gruppo,  	
                siac_r_fpv_set_cronop	r_gruppo_crono,
                siac_t_bil				bil,
                siac_t_periodo 			periodo, 
                siac_t_programma 		t_programma
        where		gruppo.set_cronop_code		=	p_set_id
        and			gruppo.set_cronop_id		=	r_gruppo_crono.set_cronop_id
        and			r_gruppo_crono.usa_gestione	= TRUE
        and			r_gruppo_crono.programma_id	=	t_programma.programma_id
        and			gruppo.bil_id				=	bil.bil_id
        and			bil.periodo_id				=	periodo.periodo_id
        and			periodo.anno				=	p_anno_bilancio
        and			gruppo.ente_proprietario_id	=	p_ente_prop_id
        and			bil.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			periodo.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_programma.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			gruppo.data_cancellazione		is null
        and			r_gruppo_crono.data_cancellazione is null
        and			bil.data_cancellazione			is null
        and			periodo.data_cancellazione		is null
        and			t_programma.data_cancellazione	is null
        order by gestione_flag,programma_id,cronop_id;	

if p_gestione = 'NO' THEN
	 raise notice '<<<  gestione uguale a no >>>' ;
     RTN_MESSAGGIO:='lettura tabella di comodo ''.';  
	BEGIN
	for setRec in
	select 		set_code				codice_set,
  				descr_set				descrizione_set,
  				set_id					id_set,
 				cronop_id				id_cronop,
   				programma_id			id_programma,
   				id_r_set_cronop			r_set_cronop_id,
   				gestione_flag			flag_gestione,
   				COALESCE(programma_codice,'')		codice_programma,
  				COALESCE(programma_descrizione,'')	descrizione_programma,
   				COALESCE(cronop_codice,'')			codice_cronop,
  				COALESCE(cronop_descrizione,'')		descrizione_cronop,
 				ente,
  				utente
    from siac_rep_set_cronop_fpv
    loop 
    	if setRec.flag_gestione = false then
        	BEGIN
            	RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_entrata_previsione - param =  '||setRec.id_cronop||'.'||p_anno_bilancio||'.';
         	for setRecPro in 
            -- 17/10/2017: procedura cambiata, tolto parametro anno bilancio
             --SELECT * from  fnc_siac_fpv_entrata_previsione(setrec.id_cronop,p_anno_bilancio)
             SELECT * from  fnc_siac_fpv_entrata_previsione(setrec.id_cronop) a
             WHERE a.anno_out::INTEGER >= p_anno_bilancio::INTEGER
             loop
             
              raise notice '<<<  descrizione programma--- punto 1 >>> %',setRec.descrizione_programma;
              raise notice '<<<  ------->>>>>  1     codice cronoprogramma % >>>', setRec.codice_cronop ;
             	id_set:=setRec.id_set;
        		codice_set:=setRec.codice_set;
        		descrizione_set:=setRec.descrizione_set;
        		id_programma:=setRec.id_programma;
        		id_cronop:=setRec.id_cronop;
        		descrizione_programma:=setRec.descrizione_programma;
				descrizione_cronop:=setRec.descrizione_cronop;
        		anno_out:=setRecPro.anno_out;
        		entrata_prevista:=setRecPro.entrata_prevista;
        		--fpv_entrata_spesa_corrente:=setRecPro.fpv_entrata_spesa_corrente;
                fpv_entrata_spesa_corrente:=setRecPro.spesa_corrente;
        		--fpv_entrata_spesa_conto_capitale:=setRecPro.fpv_entrata_spesa_conto_capitale;
                fpv_entrata_spesa_conto_capitale:=setRecPro.spesa_conto_capitale;
        		--totale:=setRecPro.totale;
                totale:=setRecPro.totale_spese;
        		--fpv_entrata_complessivo:=setRecPro.fpv_entrata_complessivo;
                fpv_entrata_complessivo:=setRecPro.fpv_entrata;
                codice_programma:=setRec.codice_programma;
                codice_cronop:=setRec.codice_cronop;
        		if setRec.flag_gestione = false then
         			tipo='PREVISIONE';
         		ELSE
    				tipo='GESTIONE';
  				end if;
        		return next;
        		anno_out='';
        		id_set=0;
        		codice_set='';
        		descrizione_set='';
        		id_programma=0;
        		id_cronop=0;
        		entrata_prevista=0;
        		fpv_entrata_spesa_corrente=0;
        		fpv_entrata_spesa_conto_capitale=0;
        		totale=0;
        		fpv_entrata_complessivo=0;
        		descrizione_programma='';
        		descrizione_cronop=''; 
        		tipo='';
             end loop;
            end;
         ELSE
         	BEGIN
            RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_entrata - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
            for setRecPro in 
    		SELECT 	* from fnc_siac_fpv_entrata(setrec.id_programma,p_anno_bilancio)
            loop
            	              raise notice '<<<  descrizione programma punto 2 >>> %',setRec.descrizione_programma;
            	id_set:=setRec.id_set;
        		codice_set:=setRec.codice_set;
        		descrizione_set:=setRec.descrizione_set;
        		id_programma:=setRec.id_programma;
        		id_cronop:=setRec.id_cronop;
        		descrizione_programma:=setRec.descrizione_programma;
				descrizione_cronop:=setRec.descrizione_cronop;
        		anno_out:=setRecPro.anno_out;
        		entrata_prevista:=setRecPro.entrata_prevista;
        		fpv_entrata_spesa_corrente:=setRecPro.fpv_entrata_spesa_corrente;
        		fpv_entrata_spesa_conto_capitale:=setRecPro.fpv_entrata_spesa_conto_capitale;
        		totale:=setRecPro.totale;
        		fpv_entrata_complessivo:=setRecPro.fpv_entrata_complessivo;
                codice_programma:=setRec.codice_programma;
                codice_cronop:=setRec.codice_cronop;
                tipo='GESTIONE';
                
        		return next;
                
        		anno_out='';
        		id_set=0;
        		codice_set='';
        		descrizione_set='';
        		id_programma=0;
        		id_cronop=0;
        		entrata_prevista=0;
        		fpv_entrata_spesa_corrente=0;
        		fpv_entrata_spesa_conto_capitale=0;
        		totale=0;
        		fpv_entrata_complessivo=0;
        		descrizione_programma='';
        		descrizione_cronop=''; 
        		tipo='';
            end loop;
            end;
  		end if;
 	end loop;
    end;
  ELSE
  		 raise notice '<<<  gestione uguale a si >>>' ;
  BEGIN
  RTN_MESSAGGIO:='Lettura tabella siac_rep_set_cronop_fpv flag = true';
  for setRec in
  select  		set_code				codice_set,
  				descr_set				descrizione_set,
  				set_id					id_set,
 				cronop_id				id_cronop,
   				programma_id			id_programma,
   				id_r_set_cronop			r_set_cronop_id,
   				gestione_flag			flag_gestione,
   				programma_codice		codice_programma,
  				programma_descrizione	descrizione_programma,
   				cronop_codice			codice_cronop,
  				cronop_descrizione		descrizione_cronop,
                ente,
  				utente
  	from 
    siac_rep_set_cronop_fpv a   	where a.gestione_flag = TRUE
    loop
    BEGIN
    RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_entrata - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
		for setRecPro in 
      	SELECT *  from fnc_siac_fpv_entrata(setRec.id_programma,p_anno_bilancio)
		loop
                      raise notice '<<<  descrizione programma punto 3>>> %',setRec.descrizione_programma;
        id_set:=setRec.id_set;
        codice_set:=setRec.codice_set;
        descrizione_set:=setRec.descrizione_set;
        id_programma:=setRec.id_programma;
        id_cronop:=setRec.id_cronop;
        descrizione_programma:=setRec.descrizione_programma;
		descrizione_cronop:=setRec.descrizione_cronop;
        anno_out:=setRecPro.anno_out;
        entrata_prevista:=setRecPro.entrata_prevista;
        fpv_entrata_spesa_corrente:=setRecPro.fpv_entrata_spesa_corrente;
        fpv_entrata_spesa_conto_capitale:=setRecPro.fpv_entrata_spesa_conto_capitale;
        totale:=setRecPro.totale;
        fpv_entrata_complessivo:=setRecPro.fpv_entrata_complessivo;
        codice_programma:=setRec.codice_programma;
        codice_cronop:=setRec.codice_cronop; 
    	tipo='GESTIONE';
        		return next;
        anno_out='';
        id_set=0;
        codice_set='';
        descrizione_set='';
        id_programma=0;
        id_cronop=0;
        entrata_prevista=0;
        fpv_entrata_spesa_corrente=0;
        fpv_entrata_spesa_conto_capitale=0;
        totale=0;
        fpv_entrata_complessivo=0;
        descrizione_programma='';
        descrizione_cronop=''; 
        tipo='';
        end loop;
    end;
 	end loop;
    end;  
  end if;
  
  delete from siac_rep_set_cronop_fpv where  utente = user_table;
    
exception
	when no_data_found THEN
		raise notice '<<<  set fpv non trovato >>>' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='ricerca set fpv ===> ';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
raise notice 'fine OK';
return; 
    	
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;