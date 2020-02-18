/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR045_report_progetto_dati_cronop" (
  p_ente_prop_id integer,
  p_codice_progetto varchar,
  p_anno_bilancio varchar
)
RETURNS TABLE (
  tipo_liv1 varchar,
  codice_liv1 varchar,
  descr_liv1 varchar,
  tipo_liv2 varchar,
  codice_liv2 varchar,
  descr_liv2 varchar,
  tipo_liv3 varchar,
  codice_liv3 varchar,
  descr_liv3 varchar,
  tipo_liv4 varchar,
  codice_liv4 varchar,
  descr_liv4 varchar,
  id_progetto integer,
  capitolo varchar,
  articolo varchar,
  ueb varchar,
  anno_competenza_stanziamento varchar,
  anno_entrata_rif_spesa varchar,
  stanziato numeric,
  descrizione1_attivita varchar,
  descrizione2_attivita varchar,
  anno_bilancio varchar,
  cronoprogramma_id integer,
  cronoprogramma_codice varchar,
  cronoprogramma_descrizione varchar,
  stato varchar,
  note_cronoprogramma varchar,
  cronop_id_elem integer,
  tipologia_capitolo varchar,
  codice_classificatore varchar,
  descrizione_classificatore varchar,
  descrizione_tipo_classificatore varchar
) AS
$body$
DECLARE
datistrutturaRec record;
progettoRec record;
datiCronoprogrammaRec record;


tipo_capitolo_P varchar;
tipo_capitolo_G varchar;
descrizione_classificatore varchar;
codice_classificatore	varchar;
descrizione_tipo_classificatore	varchar;
-----tipologia_capitolo	varchar;
DEF_NULL	constant varchar:='';
def_spazio	constant varchar:=' ';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
id_capitolo integer;


BEGIN

	tipo_capitolo_G='';
	tipo_capitolo_P='';
	tipo_liv1='';
    codice_liv1='';
  	descr_liv1='';
  	tipo_liv2='';
    codice_liv2='';
  	descr_liv2='';
  	tipo_liv3='';
    codice_liv3='';
  	descr_liv3='';
  	tipo_liv4='';
    codice_liv4='';
  	descr_liv4='';
  	id_progetto=0;
    capitolo='';
  	articolo='';
  	ueb='';
  	anno_competenza_stanziamento='';
  	anno_entrata_rif_spesa='';
  	stanziato=0;
    descrizione1_attivita='';
    descrizione2_attivita='';



select fnc_siac_random_user()
into	user_table;


--------------------------------------------------------------------------------------------------------------------------------------------------
if	(coalesce(p_anno_bilancio,DEF_NULL)=DEF_NULL or coalesce(p_anno_bilancio,def_spazio)=def_spazio)
    THEN 
    insert into siac_rep_prog_cronop
          select 	a.programma_id,
          			b.cronop_id,
                    periodo.anno,
                    user_table
    from      	siac_t_programma a,
    			siac_t_cronop b,
                siac_t_bil	bil,
                siac_t_periodo periodo  			
    where 	a.programma_code		=	p_codice_progetto
    and		b.programma_id			=	a.programma_id
    and		b.bil_id					=	bil.bil_id
    and		bil.periodo_id				=	periodo.periodo_id	
    and 	a.ente_proprietario_id 	= 	p_ente_prop_id
    group by a.programma_id,b.cronop_id, periodo.anno;
        
else
    insert into  siac_rep_prog_cronop
            select 	a.programma_id	id_progetto,
          			b.cronop_id,
                    periodo.anno,
                    user_table
                  from 		siac_t_programma a, 
                          	siac_t_cronop b, 
                          	siac_t_bil	bil,
                          	siac_t_periodo periodo
                  where 	a.programma_code			=	p_codice_progetto
                  and		b.programma_id				=	a.programma_id
                  and		b.bil_id					=	bil.bil_id
                  and		bil.periodo_id				=	periodo.periodo_id
                  and		periodo.anno				=	p_anno_bilancio
                  and 		a.ente_proprietario_id 		= 	p_ente_prop_id
                  and 		b.ente_proprietario_id 		= 	a.ente_proprietario_id
                  and 		bil.ente_proprietario_id	=	a.ente_proprietario_id
                  and 		periodo.ente_proprietario_id	=	a.ente_proprietario_id
                  and		a.data_cancellazione	is NULL
                  and		b.data_cancellazione	is null
                  and		bil.data_cancellazione	is null
                  and		periodo.data_cancellazione	is null
                   group by a.programma_id,b.cronop_id, periodo.anno;                   
end if;  





---------------------------------------------------------------------------------------------------------------------------------------------------
for progettoRec in
    select 	id_programma		id_progetto,
    		id_cronoprogramma	cronoprogramma_id,
            anno_del_bilancio	anno_bilancio
    from 	siac_rep_prog_cronop a 
    where 	a.utente	=	user_table
loop
	id_progetto:=progettoRec.id_progetto; 
    cronoprogramma_id:=progettoRec.cronoprogramma_id; 
    anno_bilancio:=progettoRec.anno_bilancio;
    BEGIN
    for datiCronoprogrammaRec in
        select 		a.programma_id, 
                  	a.cronop_id					cronoprogramma_id, 
                  	a.cronop_code				cronoprogramma_codice, 
                  	a.cronop_desc				cronoprogramma_descrizione, 
                    COALESCE (c.anno_entrata,' ')	anno_entrata_rif_spesa, 
                  	c.periodo_id, 
                    COALESCE (d.anno,' ')		anno_competenza_stanziamento, 
                  	----c.cronop_elem_det_id		cronop_id_elem,
                    b.cronop_elem_id			cronop_id_elem,
                    k.elem_tipo_code			tipologia_capitolo,
                    b.elem_tipo_id,
                  	c.cronop_elem_det_importo	stanziato, 
                  	b.cronop_elem_desc			descrizione1_attivita, 
                  	b.cronop_elem_desc2			descrizione2_attivita,
                    COALESCE (b.cronop_elem_code,' ')	capitolo, 	
                    COALESCE (b.cronop_elem_code2,' ')	articolo, 	
                    COALESCE (b.cronop_elem_code3,' ')	ueb, 	
                  	f.cronop_stato_code, 
                  	f.cronop_stato_desc			stato,
                     (select 	r.testo
                  from  	siac_t_cronop a1,
                            siac_r_cronop_attr r,
                            siac_t_attr ta, 
                            siac_d_attr_tipo i    
                  where		a1.cronop_id	=	a.cronop_id
                  and		a1.cronop_id	=	r.cronop_id
                  and		ta.attr_id			=	r.attr_id
                  and		ta.attr_tipo_id		=	i.attr_tipo_id
                  and 		i.attr_tipo_code	=	'X'
                  --SIAC-6821 16/05/2019.
                  --Mancava il filtro sul nome dell'attributo da estrarre.
                  and 		upper(ta.attr_code)='NOTE'
                  and		r.data_cancellazione	is null
                  and		ta.data_cancellazione	is null
                  and		a.ente_proprietario_id	= p_ente_prop_id)  note_cronoprogramma
          from  	siac_r_cronop_stato e,
                  	siac_d_cronop_stato f,
                  	siac_t_cronop a,
                  	siac_t_cronop_elem b,
                    siac_d_bil_elem_tipo	k, 
                  	siac_t_cronop_elem_det c
                  FULL join  siac_t_periodo d
                  on (c.periodo_id		=	d.periodo_id)       
          where		a.programma_id			=	progettoRec.id_progetto
          and		a.cronop_id				=	progettoRec.cronoprogramma_id 	
          and		c.cronop_elem_id		=	b.cronop_elem_id
          and		b.cronop_id				=	a.cronop_id	
          and		a.ente_proprietario_id 	= 	p_ente_prop_id
          and 		b.ente_proprietario_id	=	a.ente_proprietario_id
          and		c.ente_proprietario_id	=	a.ente_proprietario_id
          and		e.cronop_id				=	a.cronop_id
          and		e.cronop_stato_id		=	f.cronop_stato_id
          and 		b.elem_tipo_id 			= 	k.elem_tipo_id
          and		d.ente_proprietario_id	=	a.ente_proprietario_id
          and		e.ente_proprietario_id	=	a.ente_proprietario_id
          and		f.ente_proprietario_id	=	a.ente_proprietario_id
          and		a.data_cancellazione is null
          and		b.data_cancellazione is null 
          and		c.data_cancellazione is null 
          and		d.data_cancellazione is null 
          and		e.data_cancellazione is null 
          and		f.data_cancellazione is null 
          order by a.programma_id,a.cronop_id,c.anno_entrata,d.anno 
		loop
        	cronoprogramma_codice:=datiCronoprogrammaRec.cronoprogramma_codice;
            cronoprogramma_id:=datiCronoprogrammaRec.cronoprogramma_id;  
            cronoprogramma_descrizione:=datiCronoprogrammaRec.cronoprogramma_descrizione;
            note_cronoprogramma:=datiCronoprogrammaRec.note_cronoprogramma; 
            anno_entrata_rif_spesa:=datiCronoprogrammaRec.anno_entrata_rif_spesa; 
            
            --SIAC-6931 19/06/2019.
            -- Aggiunto questo test perche' a volte l'assegnazione alla variabile
            -- anno_entrata_rif_spesa se datiCronoprogrammaRec.anno_entrata_rif_spesa 
            -- e' uguale a ' ' non funziona e assegna ''.
            -- In questo caso la procedura DEVE restituire ' ' perche' questo e' il  che e'
            -- valore testato nel report. 
            if anno_entrata_rif_spesa = '' then
            	anno_entrata_rif_spesa:= ' ';
            end if;

                    
            anno_competenza_stanziamento:=datiCronoprogrammaRec.anno_competenza_stanziamento; 
            stanziato:=datiCronoprogrammaRec.stanziato; 
            descrizione1_attivita:=datiCronoprogrammaRec.descrizione1_attivita;
            descrizione2_attivita:=datiCronoprogrammaRec.descrizione2_attivita;
            capitolo:=datiCronoprogrammaRec.capitolo; 
            articolo:=datiCronoprogrammaRec.articolo;
            ueb:=datiCronoprogrammaRec.ueb; 
            stato:=datiCronoprogrammaRec.stato;
            cronop_id_elem:=datiCronoprogrammaRec.cronop_id_elem;
            tipologia_capitolo:=datiCronoprogrammaRec.tipologia_capitolo;
-- raise notice 'cronop_id_elem = % - cronoprogramma_codice % - capitolo % - tipologia_capitolo %',
 --	datiCronoprogrammaRec.cronop_id_elem,cronoprogramma_codice, capitolo, 
   -- datiCronoprogrammaRec.tipologia_capitolo;  
    
    --SIAC-6855 verifico se il cronop_id_elem esiste su siac_r_cronop_elem_bil_elem.
    -- Se NON esiste devo prendere la struttura di bilancio da siac_r_cronop_elem_class
    -- e non da capitolo.
    	id_capitolo:=NULL;
		select a.elem_id
        into id_capitolo
		from siac_r_cronop_elem_bil_elem a
        where a.ente_proprietario_id = p_ente_prop_id
        	and a.cronop_elem_id = datiCronoprogrammaRec.cronop_id_elem;
            
        if  datiCronoprogrammaRec.tipologia_capitolo = 'CAP-EP' or datiCronoprogrammaRec.tipologia_capitolo = 'CAP-EG' THEN
    			if	(coalesce(datiCronoprogrammaRec.articolo ,DEF_spazio)=DEF_spazio 
                and coalesce(datiCronoprogrammaRec.ueb,DEF_spazio)=DEF_spazio) OR
                	id_capitolo IS NULL	THEN 
    	 			--raise notice 'capitolo % entro',capitolo;
                    BEGIN
    				for datistrutturaRec in                 
                    select distinct titolo_tipo.classif_tipo_desc  		tipo_liv1,
                               titolo.classif_code            				codice_liv1,
                               titolo.classif_desc            				descr_liv1,
                               tipologia_tipo.classif_tipo_desc				tipo_liv2,
                               tipologia.classif_code           			codice_liv2,
                               tipologia.classif_desc           			descr_liv2
                        from siac_t_class_fam_tree 			titolo_tree,
                             siac_d_class_fam 				titolo_fam,
                             siac_r_class_fam_tree 			titolo_r_cft,
                             siac_t_class 					titolo,
                             siac_d_class_tipo 				titolo_tipo,
                             siac_d_class_tipo 				tipologia_tipo,
                             siac_t_class 					tipologia,
                             siac_r_cronop_elem_class		r_cronp_class,
                             siac_t_cronop_elem_det			cronop_elem
                        where 		titolo_fam.classif_fam_desc					=	'Entrata - TitoliTipologieCategorie'
                              and 	titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
                              and 	titolo_r_cft.classif_fam_tree_id			=	titolo_tree.classif_fam_tree_id
                              and 	titolo.classif_id							=	titolo_r_cft.classif_id_padre
                              and 	titolo_tipo.classif_tipo_code				=	'TITOLO_ENTRATA'
                              and 	titolo.classif_tipo_id						=	titolo_tipo.classif_tipo_id
                              and 	tipologia_tipo.classif_tipo_code			=	'TIPOLOGIA'
                              and 	tipologia.classif_tipo_id					=	tipologia_tipo.classif_tipo_id
                              and 	titolo_r_cft.classif_id						=	tipologia.classif_id
                               and 	r_cronp_class.classif_id					=	tipologia.classif_id
                              and	r_cronp_class.cronop_elem_id				=	datiCronoprogrammaRec.cronop_id_elem
                              and 	titolo.ente_proprietario_id					=	p_ente_prop_id
                              and 	tipologia.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	titolo_tree.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	titolo_fam.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	titolo_r_cft.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	titolo_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	tipologia_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	cronop_elem.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	r_cronp_class.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	titolo.data_cancellazione					is null
                              and 	tipologia.data_cancellazione				is null
                              and	r_cronp_class.data_cancellazione			is null
                              and 	titolo_tree.data_cancellazione				is null
                              and 	titolo_fam.data_cancellazione				is null
                              and 	titolo_r_cft.data_cancellazione				is null
                              and 	titolo_tipo.data_cancellazione				is null
                              and 	tipologia_tipo.data_cancellazione			is null
                              and 	cronop_elem.data_cancellazione				is null
    
                     
                      	loop
                     --   raise notice 'Capitolo %',capitolo;   
                        	tipo_liv1:=datistrutturaRec.tipo_liv1;
                                descr_liv1:=datistrutturaRec.descr_liv1;
                                codice_liv1:=datistrutturaRec.codice_liv1;
                                tipo_liv2:=datistrutturaRec.tipo_liv2;
                                descr_liv2:=datistrutturaRec.descr_liv2;
                                codice_liv2:=datistrutturaRec.codice_liv2;
                        end loop;
                        exception
                          when no_data_found THEN
                          	raise notice 'nessuna struttura collegata' ;
                          return;
                          when others  THEN
                          RTN_MESSAGGIO:='ricerca struttura nuovo capitolo entrata oppure senza capitolo entrata';
                          RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                          return;
                    end;
    			else
                --raise notice 'capitolo % entro2',capitolo;
    ------------------------------------------------------------------------------------------------------------------------
                    BEGIN
                    for datistrutturaRec in
                        select distinct titolo_tipo.classif_tipo_desc  		tipo_liv1,
                               titolo.classif_code            				codice_liv1,
                               titolo.classif_desc            				descr_liv1,
                               tipologia_tipo.classif_tipo_desc				tipo_liv2,
                               tipologia.classif_code           			codice_liv2,
                               tipologia.classif_desc           			descr_liv2,
                               categoria_tipo.classif_tipo_desc  			tipo_liv3,
                               categoria.classif_code              			codice_liv3,
                               categoria.classif_desc               		descr_liv3
                        from siac_t_class_fam_tree 			titolo_tree,
                             siac_d_class_fam 				titolo_fam,
                             siac_r_class_fam_tree 			titolo_r_cft,
                             siac_r_class_fam_tree 			tipologia_r_cft,
                             siac_t_class 					titolo,
                             siac_d_class_tipo 				titolo_tipo,
                             siac_d_class_tipo 				tipologia_tipo,
                             siac_t_class 					tipologia,
                             siac_d_class_tipo 				categoria_tipo,
                             siac_t_class 					categoria,
                             siac_r_bil_elem_class 			r_capitolo_categoria,
                             siac_r_cronop_elem_bil_elem	r_cronop_elem,
                             siac_t_cronop_elem_det			cronop_elem
                        where 		titolo_fam.classif_fam_desc					=	'Entrata - TitoliTipologieCategorie'
                              and 	titolo_tree.classif_fam_id					=	titolo_fam.classif_fam_id
                              and 	titolo_r_cft.classif_fam_tree_id			=	titolo_tree.classif_fam_tree_id
                              and 	titolo.classif_id							=	titolo_r_cft.classif_id_padre
                              and 	titolo_tipo.classif_tipo_code				=	'TITOLO_ENTRATA'
                              and 	titolo.classif_tipo_id						=	titolo_tipo.classif_tipo_id
                              and 	tipologia_tipo.classif_tipo_code			=	'TIPOLOGIA'
                              and 	tipologia.classif_tipo_id					=	tipologia_tipo.classif_tipo_id
                              and 	titolo_r_cft.classif_id						=	tipologia.classif_id
                              and 	tipologia.classif_id						=	tipologia_r_cft.classif_id_padre
                              and 	categoria_tipo.classif_tipo_code			=	'CATEGORIA'
                              and 	categoria.classif_tipo_id					=	categoria_tipo.classif_tipo_id
                              and 	tipologia_r_cft.classif_id					=	categoria.classif_id
                              and	tipologia_r_cft.classif_id					=	r_capitolo_categoria.classif_id
                              and	r_capitolo_categoria.elem_id				=	r_cronop_elem.elem_id
                              and	r_cronop_elem.cronop_elem_id				=	datiCronoprogrammaRec.cronop_id_elem
                              and 	titolo.ente_proprietario_id					=	p_ente_prop_id
                              and 	tipologia.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	categoria.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	titolo_tree.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	titolo_fam.ente_proprietario_id				=	titolo.ente_proprietario_id
                              and 	titolo_r_cft.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	tipologia_r_cft.ente_proprietario_id		=	titolo.ente_proprietario_id
                              and 	titolo_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	tipologia_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	categoria_tipo.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	r_capitolo_categoria.ente_proprietario_id	=	titolo.ente_proprietario_id
                              and 	r_cronop_elem.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	cronop_elem.ente_proprietario_id			=	titolo.ente_proprietario_id
                              and 	titolo.data_cancellazione					is null
                              and 	tipologia.data_cancellazione				is null
                              and 	categoria.data_cancellazione				is null
                              and 	titolo_tree.data_cancellazione				is null
                              and 	titolo_fam.data_cancellazione				is null
                              and 	titolo_r_cft.data_cancellazione				is null
                              and 	tipologia_r_cft.data_cancellazione			is null
                              and 	titolo_tipo.data_cancellazione				is null
                              and 	tipologia_tipo.data_cancellazione			is null
                              and 	categoria_tipo.data_cancellazione			is null
                              and 	r_capitolo_categoria.data_cancellazione		is null
                              and 	r_cronop_elem.data_cancellazione			is null
                              and 	cronop_elem.data_cancellazione				is null
                            loop
                                tipo_liv1:=datistrutturaRec.tipo_liv1;
                                descr_liv1:=datistrutturaRec.descr_liv1;
                                codice_liv1:=datistrutturaRec.codice_liv1;
                                tipo_liv2:=datistrutturaRec.tipo_liv2;
                                descr_liv2:=datistrutturaRec.descr_liv2;
                                codice_liv2:=datistrutturaRec.codice_liv2;
                                tipo_liv3:=datistrutturaRec.tipo_liv3;
                                descr_liv3:=datistrutturaRec.descr_liv3;
                                codice_liv3:=datistrutturaRec.codice_liv3;
                            end loop;
                                exception
                                  when no_data_found THEN
                                  raise notice 'nessuna struttura collegata' ;
                                  return;
                                  when others  THEN
                                  RTN_MESSAGGIO:='ricerca struttura capitolo entrata esistente';
                                  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                                  return;
                    end;      
    			end if; 
		else -- CAPITOLI DI SPESA
    --SIAC-6855 verifico se il cronop_id_elem esiste su siac_r_cronop_elem_bil_elem.
    -- Se NON esiste devo prendere la struttura di bilancio da siac_r_cronop_elem_class
    -- e non da capitolo.
        	id_capitolo:=NULL;
            select a.elem_id
            into id_capitolo
            from siac_r_cronop_elem_bil_elem a
            where a.ente_proprietario_id = p_ente_prop_id
                and a.cronop_elem_id = datiCronoprogrammaRec.cronop_id_elem;
                
    		if	(coalesce(datiCronoprogrammaRec.articolo ,DEF_spazio)=DEF_spazio and 
            	coalesce(datiCronoprogrammaRec.ueb,DEF_spazio)=DEF_spazio) OR
                	id_capitolo IS NULL	THEN 
                BEGIN
               --  raise notice 'Capitolo2 %',capitolo;  
    				for datistrutturaRec in
                     select  distinct 	missione_tipo.classif_tipo_desc 		tipo_liv1,
                                    missione.classif_code 					codice_liv1,
                                    missione.classif_desc 					descr_liv1,
                                    programma_tipo.classif_tipo_desc 		tipo_liv2,
                                    programma.classif_code 					codice_liv2,
                                    programma.classif_desc 					descr_liv2,
                                    titusc_tipo.classif_tipo_desc 			tipo_liv3,
                                    titusc.classif_code 					codice_liv3,
                                    titusc.classif_desc 					descr_liv3
                from siac_t_class_fam_tree 			missione_tree,
                     siac_d_class_fam 				missione_fam,
                     siac_r_class_fam_tree 			missione_r_cft,
                     siac_t_class 					missione,
                     siac_d_class_tipo 				missione_tipo ,
                     siac_d_class_tipo 				programma_tipo,
                     siac_t_class 					programma,
                     siac_t_class_fam_tree 			titusc_tree,
                     siac_d_class_fam 				titusc_fam,
                     siac_r_class_fam_tree 			titusc_r_cft,
                     siac_t_class 					titusc,
                     siac_d_class_tipo 				titusc_tipo,
                     siac_r_cronop_elem_class		r_cronp_class_programma,
                     siac_r_cronop_elem_class		r_cronp_class_titolo,
                     siac_t_cronop_elem_det			cronop_elem
                where missione_fam.classif_fam_desc						=	'Spesa - MissioniProgrammi'      
                      and	missione_tree.classif_fam_id				=	missione_fam.classif_fam_id 
                        and	missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id 
                      and	missione.classif_id							=	missione_r_cft.classif_id_padre 
                      and	missione_tipo.classif_tipo_code				=	'MISSIONE' 
                      and	missione.classif_tipo_id					=	missione_tipo.classif_tipo_id 
                      and	programma_tipo.classif_tipo_code			=	'PROGRAMMA'  
                      and	programma.classif_tipo_id					=	programma_tipo.classif_tipo_id  
                      and	missione_r_cft.classif_id					=	programma.classif_id  
                      and	programma.classif_id						=	r_cronp_class_programma.classif_id
                      and	r_cronp_class_programma.cronop_elem_id		=	datiCronoprogrammaRec.cronop_id_elem		
                      and	titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'      
                      and	titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id 
                      and	titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id 
                      and	titusc.classif_id							=	titusc_r_cft.classif_id_padre 
                      and	titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA' 
                      and	titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id
                      and	titusc.classif_id							=	r_cronp_class_titolo.classif_id
                      and	r_cronp_class_titolo.cronop_elem_id			=	datiCronoprogrammaRec.cronop_id_elem		 
                      and 	missione_tree.ente_proprietario_id			=	p_ente_prop_id
                      and 	missione_fam.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	missione_r_cft.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	missione.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      AND 	missione_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	programma_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	programma.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	titusc_tree.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	titusc_fam.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	titusc_r_cft.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	titusc.ente_proprietario_id					=	missione_tree.ente_proprietario_id
                      AND 	titusc_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and	r_cronp_class_titolo.ente_proprietario_id	=	missione_tree.ente_proprietario_id
                      and	cronop_elem.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	missione_tree.data_cancellazione			is null
                      and 	missione_fam.data_cancellazione				is null
                      AND 	missione_r_cft.data_cancellazione			is null
                      and 	missione.data_cancellazione					is null
                      AND 	missione_tipo.data_cancellazione			is null
                      AND 	programma_tipo.data_cancellazione			is null
                      AND 	programma.data_cancellazione				is null
                      and 	titusc_tree.data_cancellazione				is null
                      AND 	titusc_fam.data_cancellazione				is null
                      and 	titusc_r_cft.data_cancellazione				is null
                      and 	titusc.data_cancellazione					is null
                      AND 	titusc_tipo.data_cancellazione				is null
                      and	r_cronp_class_titolo.data_cancellazione		is null
                      and	cronop_elem.data_cancellazione				is null
                      	loop
                        	 tipo_liv1:=datistrutturaRec.tipo_liv1;
                                descr_liv1:=datistrutturaRec.descr_liv1;
                                codice_liv1:=datistrutturaRec.codice_liv1;
                                tipo_liv2:=datistrutturaRec.tipo_liv2;
                                descr_liv2:=datistrutturaRec.descr_liv2;
                                codice_liv2:=datistrutturaRec.codice_liv2;
                                tipo_liv3:=datistrutturaRec.tipo_liv3;
                                descr_liv3:=datistrutturaRec.descr_liv3;
                                codice_liv3:=datistrutturaRec.codice_liv3;    
                        end loop;
                        exception
                          when no_data_found THEN
                          raise notice 'nessuna struttura collegata' ;
                          return;
                          when others  THEN
                          RTN_MESSAGGIO:='ricerca struttura nuovo capitolo spesa o senza capitolo di spesa';
                          RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                          return;
                    end;
            else
            BEGIN
    				for datistrutturaRec in
            
            	select  distinct 	missione_tipo.classif_tipo_desc 		tipo_liv1,
                                    missione.classif_code 					codice_liv1,
                                    missione.classif_desc 					descr_liv1,
                                    programma_tipo.classif_tipo_desc 		tipo_liv2,
                                    programma.classif_code 					codice_liv2,
                                    programma.classif_desc 					descr_liv2,
                                    titusc_tipo.classif_tipo_desc 			tipo_liv3,
                                    titusc.classif_code 					codice_liv3,
                                    titusc.classif_desc 					descr_liv3,
                                    macroaggr_tipo.classif_tipo_desc 		tipo_liv4,
                                    macroaggr.classif_code 					codice_liv4,
                                    macroaggr.classif_desc 					descr_liv4
                from siac_t_class_fam_tree 			missione_tree,
                     siac_d_class_fam 				missione_fam,
                     siac_r_class_fam_tree 			missione_r_cft,
                     siac_t_class 					missione,
                     siac_d_class_tipo 				missione_tipo ,
                     siac_d_class_tipo 				programma_tipo,
                     siac_t_class 					programma,
                     siac_t_class_fam_tree 			titusc_tree,
                     siac_d_class_fam 				titusc_fam,
                     siac_r_class_fam_tree 			titusc_r_cft,
                     siac_t_class 					titusc,
                     siac_d_class_tipo 				titusc_tipo ,
                     siac_d_class_tipo 				macroaggr_tipo,
                     siac_t_class 					macroaggr,
                     siac_r_bil_elem_class 			r_capitolo_programma,
                     siac_r_cronop_elem_bil_elem	r_cronop_elem,
                     siac_r_bil_elem_class 			r_capitolo_macroaggr
                where missione_fam.classif_fam_desc						=	'Spesa - MissioniProgrammi'      
                      and	missione_tree.classif_fam_id				=	missione_fam.classif_fam_id 
                        and	missione_r_cft.classif_fam_tree_id			=	missione_tree.classif_fam_tree_id 
                      and	missione.classif_id							=	missione_r_cft.classif_id_padre 
                      and	missione_tipo.classif_tipo_code				=	'MISSIONE' 
                      and	missione.classif_tipo_id					=	missione_tipo.classif_tipo_id 
                      and	programma_tipo.classif_tipo_code			=	'PROGRAMMA'  
                      and	programma.classif_tipo_id					=	programma_tipo.classif_tipo_id  
                      and	missione_r_cft.classif_id					=	programma.classif_id  
                      and	missione_r_cft.classif_id					=	r_capitolo_programma.classif_id		
                      and	r_capitolo_programma.elem_id				=	r_cronop_elem.elem_id		
                      and	r_cronop_elem.cronop_elem_id				=	datiCronoprogrammaRec.cronop_id_elem	
                      and	titusc_fam.classif_fam_desc					=	'Spesa - TitoliMacroaggregati'      
                      and	titusc_tree.classif_fam_id					=	titusc_fam.classif_fam_id 
                      and	titusc_r_cft.classif_fam_tree_id			=	titusc_tree.classif_fam_tree_id 
                      and	titusc.classif_id							=	titusc_r_cft.classif_id_padre 
                      and	titusc_tipo.classif_tipo_code				=	'TITOLO_SPESA' 
                      and	titusc.classif_tipo_id						=	titusc_tipo.classif_tipo_id 
                      and	macroaggr_tipo.classif_tipo_code			=	'MACROAGGREGATO' 
                      and	macroaggr.classif_tipo_id					=	macroaggr_tipo.classif_tipo_id 
                      and	titusc_r_cft.classif_id						=	macroaggr.classif_id 
                      and	titusc_r_cft.classif_id						=	r_capitolo_macroaggr.classif_id 
                      and	r_capitolo_macroaggr.elem_id				=	r_cronop_elem.elem_id		 
                      and	r_cronop_elem.cronop_elem_id				=	datiCronoprogrammaRec.cronop_id_elem
                      and 	missione_tree.ente_proprietario_id			=	p_ente_prop_id
                      and 	missione_fam.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	missione_r_cft.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	missione.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      AND 	missione_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	programma_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	programma.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	titusc_tree.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	titusc_fam.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	titusc_r_cft.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	titusc.ente_proprietario_id					=	missione_tree.ente_proprietario_id
                      AND 	titusc_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	macroaggr_tipo.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      AND 	macroaggr.ente_proprietario_id				=	missione_tree.ente_proprietario_id
                      and 	r_capitolo_programma.ente_proprietario_id	=	missione_tree.ente_proprietario_id
                      AND	r_cronop_elem.ente_proprietario_id			=	missione_tree.ente_proprietario_id
                      and 	r_capitolo_macroaggr.ente_proprietario_id	=	missione_tree.ente_proprietario_id     
                      and 	missione_tree.data_cancellazione			is null
                      and 	missione_fam.data_cancellazione				is null
                      AND 	missione_r_cft.data_cancellazione			is null
                      and 	missione.data_cancellazione					is null
                      AND 	missione_tipo.data_cancellazione			is null
                      AND 	programma_tipo.data_cancellazione			is null
                      AND 	programma.data_cancellazione				is null
                      and 	titusc_tree.data_cancellazione				is null
                      AND 	titusc_fam.data_cancellazione				is null
                      and 	titusc_r_cft.data_cancellazione				is null
                      and 	titusc.data_cancellazione					is null
                      AND 	titusc_tipo.data_cancellazione				is null
                      AND 	macroaggr_tipo.data_cancellazione			is null
                      AND 	macroaggr.data_cancellazione				is null
                      and 	r_capitolo_programma.data_cancellazione		is null
                      AND	r_cronop_elem.data_cancellazione			is null
                      and 	r_capitolo_macroaggr.data_cancellazione		is null
                      
            		loop
                    -- raise notice 'Capitolo3 %',capitolo;  
                                tipo_liv1:=datistrutturaRec.tipo_liv1;
                                descr_liv1:=datistrutturaRec.descr_liv1;
                                codice_liv1:=datistrutturaRec.codice_liv1;
                                tipo_liv2:=datistrutturaRec.tipo_liv2;
                                descr_liv2:=datistrutturaRec.descr_liv2;
                                codice_liv2:=datistrutturaRec.codice_liv2;
                                tipo_liv3:=datistrutturaRec.tipo_liv3;
                                descr_liv3:=datistrutturaRec.descr_liv3;
                                codice_liv3:=datistrutturaRec.codice_liv3;
                                tipo_liv4:=datistrutturaRec.tipo_liv4;
                                descr_liv4:=datistrutturaRec.descr_liv4;
                                codice_liv4:=datistrutturaRec.codice_liv4;
            		 end loop;
                                exception
                                  when no_data_found THEN
                                  raise notice 'nessuna struttura collegata' ;
                                  return;
                                  when others  THEN
                                  RTN_MESSAGGIO:='ricerca struttura capitolo spesa esistente';
                                  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                                  return;
                end;      
            end if; 
        end if;
       
    
      --raise notice 'anno_entrata_rif_spesa2 =X%X',anno_entrata_rif_spesa;  
             
            return next;
            tipo_liv1='';
            descr_liv1='';
            codice_liv1='';
            tipo_liv2='';
            descr_liv2='';
            codice_liv2='';
            tipo_liv3='';
            descr_liv3='';
            codice_liv3='';
            tipo_liv4='';
            descr_liv4='';
            codice_liv4='';
            capitolo='';
            articolo='';
            ueb='';
            anno_competenza_stanziamento='';
            anno_entrata_rif_spesa='';
            stanziato=0;
            cronoprogramma_id=0;
            descrizione1_attivita='';
            descrizione2_attivita='';
            cronoprogramma_codice='';
            cronoprogramma_descrizione='';
            note_cronoprogramma='';
            cronop_id_elem=0;
        end loop;
        exception
          when no_data_found THEN
          raise notice 'nessun cronoprogramma trovato' ;
          return;
          when others  THEN
          RTN_MESSAGGIO:='ricerca cronoprogrammi';
          RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
          return;
    end;
    id_progetto=0;
end loop;

delete from siac_rep_prog_cronop where utente=user_table;

exception
	when no_data_found THEN
		raise notice 'nessun programma/progetto trovato' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='ricerca programmi/progetti';
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