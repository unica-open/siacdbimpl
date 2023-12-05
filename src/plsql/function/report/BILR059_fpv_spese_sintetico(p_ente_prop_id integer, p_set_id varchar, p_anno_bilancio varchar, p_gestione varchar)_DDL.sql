/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR059_fpv_spese_sintetico" (
  p_ente_prop_id integer,
  p_set_id varchar,
  p_anno_bilancio varchar,
  p_gestione varchar
)
RETURNS TABLE (
  anno_out varchar,
  id_set varchar,
  codice_set varchar,
  descrizione_set varchar,
  id_programma integer,
  codice_programma varchar,
  descrizione_programma varchar,
  id_cronop integer,
  codice_cronop varchar,
  descrizione_cronop varchar,
  missione varchar,
  programma varchar,
  titolo varchar,
  spesa_prevista numeric,
  fpv_spesa numeric,
  tipo varchar
) AS
$body$
DECLARE
setRec record;
setrecpro record;

DEF_NULL	constant 			varchar:='';
def_spazio	constant 			varchar:=' ';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
flag_gestione	VARCHAR;
r_set_cronop_id INTEGER;
user_table	varchar;
contaChiamate integer;

BEGIN
anno_out='';
id_set=0;
codice_set='';
descrizione_set='';
id_programma=0;
id_cronop=0;
missione='';
programma='';
titolo='';
spesa_prevista=0;
fpv_spesa=0;
descrizione_programma='';
descrizione_cronop='';
codice_programma='';
codice_cronop='';
tipo='';



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
                user_table	 					utente
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
        and			bil.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			periodo.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			t_programma.ente_proprietario_id =	gruppo.ente_proprietario_id
        and			t_cronop.ente_proprietario_id	=	gruppo.ente_proprietario_id
        and			gruppo.data_cancellazione		is null
        and			r_gruppo_crono.data_cancellazione	is null 
        and			bil.data_cancellazione			is null
        and			periodo.data_cancellazione		is null
        and			t_programma.data_cancellazione			is null
        and			t_cronop.data_cancellazione			is null
        order by gestione_flag,programma_id,cronop_id;	       
 
 RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = true '||p_set_id||'.';    
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
                ' ',
                ' ',
                p_ente_prop_id					ente,
                user_table	 					utente
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
	BEGIN
    RTN_MESSAGGIO:='lettura tabella di comodo ''.';  
   -- contaChiamate:=0;
	for setRec in
		select 	set_code				codice_set,
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
    	from siac_rep_set_cronop_fpv
    	loop
        	if setRec.flag_gestione = false then
        		BEGIN
        --contaChiamate:=contaChiamate+1;
        --raise notice 'Chiamata %',contaChiamate;
                RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_spesa_previsione - param =  '||setRec.id_cronop||'.'||p_anno_bilancio||'.';
            	for setRecPro in
                -- 17/10/2017: procedura cambiata, tolto parametro anno bilancio
                    --SELECT * from fnc_siac_fpv_spesa_previsione(setRec.id_cronop,p_anno_bilancio)
                    SELECT * from fnc_siac_fpv_spesa_previsione(setRec.id_cronop) a
                    WHERE a.anno_out::INTEGER >= p_anno_bilancio::INTEGER
                    loop 
                    raise notice '<<<  ------->>>>   1    codice programma % >>>', setRec.codice_programma ;
        			raise notice '<<<  ------->>>>>  1     codice cronoprogramma % >>>', setRec.codice_cronop ;
                        id_set:=setRec.id_set;
        				codice_set:=setRec.codice_set;
        				descrizione_set:=setRec.descrizione_set;
        				id_programma:=setRec.id_programma;
        				id_cronop:=setRec.id_cronop;
       					descrizione_programma:=setRec.descrizione_programma;
						descrizione_cronop:=setRec.descrizione_cronop;
                        anno_out:=setRecPro.anno_out;
      			 		missione:=setRecPro.missione;
  				      	programma:=setRecPro.programma;
 				       	titolo:=setRecPro.titolo;
 			    		spesa_prevista:=setRecPro.spesa_prevista;
			        	fpv_spesa:=setRecPro.fpv_spesa;
                        codice_programma:=setRec.codice_programma;
                        codice_cronop:=setRec.codice_cronop;
                        if setRec.flag_gestione = false then
         					tipo='PREVISIONE';
        				ELSE
    						tipo='GESTIONE';
  						end if;
                        return next;
                        missione='';
  						programma='';
       					titolo='';
        				spesa_prevista=0;
        				fpv_spesa=0; 
        			end loop;
            	end;
            ELSE
            	BEGIN
                	RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_spesa - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
      				for setRecPro in
                    SELECT * from fnc_siac_fpv_spesa(setRec.id_programma,p_anno_bilancio)
    					loop 
                        id_set:=setRec.id_set;
        				codice_set:=setRec.codice_set;
        				descrizione_set:=setRec.descrizione_set;
        				id_programma:=setRec.id_programma;
        				id_cronop:=setRec.id_cronop;
       					descrizione_programma:=setRec.descrizione_programma;
						descrizione_cronop:=setRec.descrizione_cronop;
                        anno_out:=setRecPro.anno_out;
      			 		missione:=setRecPro.missione;
  				      	programma:=setRecPro.programma;
 				       	titolo:=setRecPro.titolo;
 			    		spesa_prevista:=setRecPro.spesa_prevista;
			        	fpv_spesa:=setRecPro.fpv_spesa;
                        codice_programma:=setRec.codice_programma;
                        codice_cronop:=setRec.codice_cronop; 
				   		tipo='GESTIONE';
                        return next;
                        missione='';
  						programma='';
       					titolo='';
        				spesa_prevista=0;
        				fpv_spesa=0; 
        			end loop;
                end;    
            end if;
        end loop;
    end;

--------------------------------------------------------------------------------------------------------------------------------
ELSE
		 raise notice '<<<  gestione uguale a si >>>' ;
  BEGIN
  		RTN_MESSAGGIO:='Lettura tabella siac_rep_set_cronop_fpv flag = true';
  		for setRec in
        select  set_code				codice_set,
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
  		from     siac_rep_set_cronop_fpv a   	where a.gestione_flag = TRUE
    		loop 
            
            	BEGIN
                	RTN_MESSAGGIO:='Lettura store procedure fnc_siac_fpv_spesa - param =  '||setRec.id_programma||'.'||p_anno_bilancio||'.';
      				for setRecPro in 
                    SELECT * from fnc_siac_fpv_spesa(setRec.id_programma,p_anno_bilancio)
    					loop 
                        raise notice '<<<  ------->>>>   2    codice programma % >>>', setRec.codice_programma ;
        				raise notice '<<<  ------->>>>>  2     codice cronoprogramma % >>>', setRec.codice_cronop ;
                        id_set:=setRec.id_set;
        				codice_set:=setRec.codice_set;
        				descrizione_set:=setRec.descrizione_set;
        				id_programma:=setRec.id_programma;
        				id_cronop:=setRec.id_cronop;
       					descrizione_programma:=setRec.descrizione_programma;
						descrizione_cronop:=setRec.descrizione_cronop;
                        anno_out:=setRecPro.anno_out;
      			 		missione:=setRecPro.missione;
  				      	programma:=setRecPro.programma;
 				       	titolo:=setRecPro.titolo;
 			    		spesa_prevista:=setRecPro.spesa_prevista;
			        	fpv_spesa:=setRecPro.fpv_spesa;
                        codice_programma:=setRec.codice_programma;
                        codice_cronop:=setRec.codice_cronop; 
				   		tipo='GESTIONE';
                        return next;
                        missione='';
  						programma='';
       					titolo='';
        				spesa_prevista=0;
        				fpv_spesa=0; 
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