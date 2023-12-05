/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR061_fpv_spese_per_capitolo" (
  p_ente_prop_id integer,
  p_set_id varchar,
  p_anno_bilancio varchar,
  p_gestione varchar
)
RETURNS TABLE (
  anno varchar,
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
  tipo varchar,
  capitolo varchar,
  descrizione_capitolo varchar,
  articolo varchar,
  descrizione_articolo varchar,
  ueb varchar
) AS
$body$
DECLARE
setRec record;
setRecPro record;

DEF_NULL	constant 			varchar:='';
def_spazio	constant 			varchar:=' ';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
flag_gestione	VARCHAR;
--codice_programma	VARCHAR;
--codice_cronop VARCHAR;
r_set_cronop_id INTEGER;
user_table	varchar;
id_capitolo integer;


BEGIN
anno='';
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
tipo='';
capitolo='';
descrizione_capitolo='';
articolo='';
descrizione_articolo='';
ueb='';

 RTN_MESSAGGIO:='acquisizione user_table ';
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
                COALESCE(t_programma.programma_code,'')	programma_codice,
                t_programma.programma_desc		programma_descrizione,
                t_cronop.cronop_code			cronop_codice,
                t_cronop.cronop_desc			cronop_descrizione,
                p_ente_prop_id					ente,
                user_table 						user_utente
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
        -- 17/10/2016: aggiunte le date cancellazione
        and 		gruppo.data_cancellazione	IS NULL
        and 		r_gruppo_crono.data_cancellazione	IS NULL
        and 		bil.data_cancellazione	IS NULL
        and 		periodo.data_cancellazione	IS NULL
        and 		t_programma.data_cancellazione	IS NULL
        and 		t_cronop.data_cancellazione	IS NULL;
        --and         b.cronop_id = 30
      --  order by gestione_flag,programma_id,id_cronop;	
     
 RTN_MESSAGGIO:='inserimento tabella di comodo dove usa gestione = true '||p_set_id||'.';    

 insert into siac_rep_set_cronop_fpv
 select 		gruppo.set_cronop_code			set_code,
                gruppo.set_cronop_desc			descr_set,
                gruppo.set_cronop_id			set_id,
                r_gruppo_crono.cronop_id		cronop_id,
                r_gruppo_crono.programma_id		programma_id,
                r_gruppo_crono.set_cronop_id	id_r_set_cronop,
                r_gruppo_crono.usa_gestione		gestione_flag,
                COALESCE(t_programma.programma_code,'')	programma_codice,
                COALESCE(t_programma.programma_desc,'')	programma_descrizione,
                ' ',
                ' ',
                p_ente_prop_id					ente,
                user_table 						user_utente
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
        -- 17/10/2016: aggiunte le date cancellazione
        and 		gruppo.data_cancellazione	IS NULL
        and 		r_gruppo_crono.data_cancellazione	IS NULL
        and 		bil.data_cancellazione	IS NULL
        and 		periodo.data_cancellazione	IS NULL
        and 		t_programma.data_cancellazione	IS NULL    ;   
       -- and 		a.programma_id = 3    
   --  order by gestione_flag,programma_id;--,id_cronop;	
 
------------------------------------------------------------------------------------------------------------------------------------

if p_gestione = 'NO' THEN
	 raise notice '<<<  gestione uguale a no >>>' ;
	BEGIN
     		RTN_MESSAGGIO:='select 1 tabella di comodo set programmi ';
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
        raise notice 'setRec.id_cronop = %', setRec.id_cronop;
            if setRec.flag_gestione = false then
                                        RTN_MESSAGGIO:='acquisizione dati da function ----------------------------- ';
                BEGIN
                 for setRecPro in
                 SELECT 		elem_id_out 		id_capitolo,
  								elem_code_out 		capitolo,
  								elem_desc_out 		descrizione_capitolo,
  								missione_out 		missione,
  								programma_out 		programma,
                                titolo_out 			titolo,
                                anno_out 			anno,
                                spesa_prevista_out 	spesa_prevista,
                                fpv_spesa_out 		fpv_spesa,
                                elem_code2_out		articolo,
                                elem_desc2_out 		descrizione_articolo,
                                elem_code3_out 		ueb
                  from fnc_siac_fpv_spesa_capitolo_previsione(setRec.id_cronop,p_anno_bilancio)
                  ---from fnc_siac_fpv_spesa_capitolo(setRec.id_programma,p_anno_bilancio)
                   loop
                        id_set:=setRec.id_set;
                        codice_set:=setRec.codice_set;
                        descrizione_set:=setRec.descrizione_set;
                        id_programma:=setRec.id_programma;
                        id_cronop:=setRec.id_cronop;
                        descrizione_programma:=COALESCE(setRec.descrizione_programma,'');
                        descrizione_cronop:=COALESCE(setRec.descrizione_cronop,'');
                        anno:=setRecPro.anno;
                        missione:=COALESCE(setRecPro.missione,'');
                        programma:=COALESCE(setRecPro.programma,'');
                        titolo:=COALESCE(setRecPro.titolo,'');
                        spesa_prevista:=setRecPro.spesa_prevista;
                        fpv_spesa:=setRecPro.fpv_spesa; 
                        capitolo:=COALESCE(setRecPro.capitolo,'');
                        descrizione_capitolo:=COALESCE(setRecPro.descrizione_capitolo,'');
                        codice_programma:=COALESCE(setRec.codice_programma,'');
                        codice_cronop:=COALESCE(setRec.codice_cronop,'');
                        if setRec.flag_gestione = false then
                            tipo='PREVISIONE';
                        ELSE
                            tipo='GESTIONE';
                        end if;
                        -----tipo:=setRec.tipo;
                        
                        articolo:= COALESCE(setRecPro.articolo,'');
  						descrizione_articolo:= COALESCE(setRecPro.descrizione_articolo,'');
  						ueb := COALESCE(setRecPro.ueb,'');
                        return next;
                        spesa_prevista=0;
                        fpv_spesa=0;
                        capitolo='';
                        descrizione_capitolo='';  
                   end loop;
                end;
            ELSE
                --BEGIN
                    /*
                    loop 
            			RTN_MESSAGGIO:='acquisizione 2 dati da function  fnc_siac_fpv_spesa_capitolo  ---- ';
                     id_set:=setRec.id_set;
                     codice_set:=setRec.codice_set;
                     descrizione_set:=setRec.descrizione_set;
                     id_programma:=setRec.id_programma;
                     id_cronop:=setRec.id_cronop;
                     descrizione_programma:=setRec.descrizione_programma;
                     descrizione_cronop:=setRec.descrizione_cronop;*/
                	BEGIN
                    
                		for setRecPro in
                        SELECT 	elem_id_out id_capitolo,
                                elem_code_out capitolo,
                                elem_desc_out descrizione_capitolo,
                                missione_out missione,
                                programma_out programma,
                                titolo_out titolo,
                                anno_out	anno,
                                spesa_prevista_out spesa_prevista,
                                fpv_spesa_out fpv_spesa,
                                elem_code2_out		articolo,
                                elem_desc2_out 		descrizione_articolo,
                                elem_code3_out 		ueb                                
                              from fnc_siac_fpv_spesa_capitolo(setRec.id_programma,p_anno_bilancio)
                      		loop
                            
                            id_set:=setRec.id_set;
                     		codice_set:=setRec.codice_set;
                     		descrizione_set:=setRec.descrizione_set;
                     		id_programma:=setRec.id_programma;
                     		id_cronop:=setRec.id_cronop;
                     		descrizione_programma:=COALESCE(setRec.descrizione_programma,'');
                     		descrizione_cronop:=COALESCE(setRec.descrizione_cronop,'');
                            --anno:=setRecPro.anno;
                             codice_programma:=COALESCE(setRec.codice_programma,'');
                              codice_cronop:=COALESCE(setRec.codice_cronop,'');
                              missione:=COALESCE(setRecPro.missione,'');
                              programma:=COALESCE(setRecPro.programma,'');
                              titolo:=COALESCE(setRecPro.titolo,'');
                              anno:=setRecPro.anno;
                              spesa_prevista:=setRecPro.spesa_prevista;
                              fpv_spesa:=setRecPro.fpv_spesa; 
                              capitolo:=COALESCE(setRecPro.capitolo,'');
                              descrizione_capitolo:=COALESCE(setRecPro.descrizione_capitolo,'');
                              tipo='GESTIONE';
                              articolo:= COALESCE(setRecPro.articolo,'');
  							  descrizione_articolo:= COALESCE(setRecPro.descrizione_articolo,'');
  							  ueb := COALESCE(setRecPro.ueb,'');
                              
                              ------tipo:=setRecPro.tipo;
                              return next;
                              
                              missione='';
                              programma='';
                              titolo='';
                              spesa_prevista=0;
                              fpv_spesa=0;
                              capitolo='';
                              descrizione_capitolo=''; 
                              anno=''; 
                              tipo='';
                              
                      		end loop;
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
                              anno=''; 
                              tipo='';
                              
                	--end;
                    
                    
                    
                    --END LOOP;
                    /*id_set=0;
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
                    tipo='';*/
                END;
  		 	end if;
      end loop;
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
                    anno=''; 
                    tipo='';
    end;
ELSE
  		 raise notice '<<<  gestione uguale a si >>>' ;
         RTN_MESSAGGIO:='select 2 tabella di comodo set programmi ';
  	BEGIN
  	for setRec in
  		select  set_code				codice_set,
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
  	from     siac_rep_set_cronop_fpv a
  	where a.gestione_flag = TRUE
    loop 
    	RTN_MESSAGGIO:='acquisizione 2 dati da function  fnc_siac_fpv_spesa_capitolo  ---- ';
        
       id_set:=setRec.id_set;
       codice_set:=setRec.codice_set;
       descrizione_set:=setRec.descrizione_set;
       id_programma:=setRec.id_programma;
       id_cronop:=setRec.id_cronop;
       raise notice 'id_cronop = %', id_cronop;
       descrizione_programma:=setRec.descrizione_programma;
       descrizione_cronop:=setRec.descrizione_cronop;
      BEGIN
      raise notice 'ZZZ setRec.id_programma = %', setRec.id_programma;
            for setRecPro in
            SELECT 	elem_id_out id_capitolo,
  					elem_code_out capitolo,
  					elem_desc_out descrizione_capitolo,
  					missione_out missione,
  					programma_out programma,
  					titolo_out titolo,
  					anno_out	anno,
  					spesa_prevista_out spesa_prevista,
  					fpv_spesa_out fpv_spesa,
                    elem_code2_out,
                    elem_desc2_out,
                    elem_code3_out
                  from fnc_siac_fpv_spesa_capitolo(setRec.id_programma,p_anno_bilancio)
                  loop
                          missione:=setRecPro.missione;
        				  programma:=setRecPro.programma;
        				  titolo:=setRecPro.titolo;
                          anno:=setRecPro.anno;
                          spesa_prevista:=setRecPro.spesa_prevista;
                          fpv_spesa:=setRecPro.fpv_spesa; 
                          capitolo:=setRecPro.capitolo;
                          descrizione_capitolo:=setRecPro.descrizione_capitolo;
                          tipo='GESTIONE';
                          ------tipo:=setRecPro.tipo;
                          
                          articolo=setRecPro.elem_code2_out; 
                          return next;
                          
                          missione='';
						  programma='';
						  titolo='';
                          spesa_prevista=0;
                          fpv_spesa=0;
                          capitolo='';
                          descrizione_capitolo=''; 
                          anno=''; 
                          tipo='';
                  end loop;
                   missione='';
				  programma='';
				  titolo='';
                  spesa_prevista=0;
                  fpv_spesa=0;
                  capitolo='';
                  descrizione_capitolo='';  
                  anno='';
                  tipo='';
       end;
      end loop;

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
        anno=''; 
		tipo='';
    end;
  end if;
delete from siac_rep_set_cronop_fpv where  utente = user_table;
-----------------|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||
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