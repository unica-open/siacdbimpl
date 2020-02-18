/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR040_progetti_per_capitolo_dati_programma" (
  p_ente_prop_id integer,
  p_capitolo varchar,
  p_articolo varchar,
  p_ueb varchar,
  p_tipologia_capitolo varchar,
  p_anno_bilancio varchar
)
RETURNS TABLE (
  id_progetto integer,
  codice_progetto varchar,
  descrizione_progetto varchar,
  valore_progetto numeric,
  ambito varchar,
  stato varchar,
  rilev_fpv varchar,
  atto_id integer,
  atto_anno varchar,
  atto_numero varchar,
  atto_oggetto varchar,
  atto_note varchar,
  atto_tipo_id integer,
  atto_stato_id integer,
  atto_stato_code varchar,
  atto_stato_desc varchar,
  atto_tipo_code varchar,
  atto_tipo_desc varchar,
  note_progetto varchar
) AS
$body$
DECLARE
progettoRec record;
datiProgettoRec record;
datiattorec	record;

tipo_capitolo_P varchar;
tipo_capitolo_G varchar;
DEF_NULL	constant varchar:='';
def_spazio	constant varchar:=' ';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;



BEGIN

	tipo_capitolo_G='';
	tipo_capitolo_P='';
  	id_progetto=0;
  	codice_progetto='';
  	descrizione_progetto='';
  	valore_progetto=0;
  	ambito='';
  	stato='';
  	rilev_fpv='';
  	atto_id=0;
  	atto_anno='';
  	atto_oggetto='';
  	atto_note='';
  	atto_tipo_id=0;
  	atto_stato_id=0;
  	atto_stato_code='';
  	atto_stato_desc='';
  	atto_tipo_code='';
  	atto_tipo_desc='';
--  ricercare la tipologia di capitolo partendo dal parametro indicato dall'operatore 

if p_tipologia_capitolo = 'E' THEN
	tipo_capitolo_P='CAP-EP';
	tipo_capitolo_G='CAP-EG';
else
	tipo_capitolo_P='CAP-UP';
	tipo_capitolo_G='CAP-UG';
end if;



select fnc_siac_random_user()
into	user_table;


------------------------------------------------------------------------------------------------------------------------------------------

if	((coalesce(p_articolo,DEF_NULL)=DEF_NULL and coalesce(p_ueb,DEF_NULL)=DEF_NULL)
	or (coalesce(p_articolo,def_spazio)=def_spazio and coalesce(p_ueb,def_spazio)=def_spazio))
    and ((coalesce(p_anno_bilancio,DEF_NULL)=DEF_NULL or coalesce(p_anno_bilancio,def_spazio)=def_spazio))
    THEN 
      insert into siac_rep_prog_cronop
          select 	a.programma_id	id_progetto,
          			0,
                    ' ',
                    user_table
          from 	siac_t_programma a, 
          		siac_t_cronop b, 
                siac_t_cronop_elem c, 
                siac_d_bil_elem_tipo d
          where 	c.cronop_elem_code 		= 	p_capitolo
          ----and		c.cronop_elem_code2		is null
          -----and 	c.cronop_elem_code3 		is null
          and 	c.elem_tipo_id 			= d.elem_tipo_id
          and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
          and 	c.cronop_id 			= b.cronop_id
          and 	b.programma_id 			= a.programma_id
          and 	c.ente_proprietario_id 	= 	p_ente_prop_id
          and 	b.ente_proprietario_id 	= 	c.ente_proprietario_id
          and 	a.ente_proprietario_id	=	c.ente_proprietario_id
          and 	d.ente_proprietario_id	=	c.ente_proprietario_id
          group by a.programma_id;
else
      if	((coalesce(p_articolo,DEF_NULL)=DEF_NULL and coalesce(p_ueb,DEF_NULL)=DEF_NULL)
          or (coalesce(p_articolo,def_spazio)=def_spazio and coalesce(p_ueb,def_spazio)=def_spazio))
          and p_anno_bilancio > '0'
          THEN 
          insert into  siac_rep_prog_cronop
            select 	a.programma_id	id_progetto,
          			0,
                    ' ',
                    user_table
                  from 	siac_t_programma a, 
                          siac_t_cronop b, 
                          siac_t_cronop_elem c, 
                          siac_t_bil	bil,
                          siac_t_periodo periodo,
                          siac_d_bil_elem_tipo d
                  where 	b.bil_id				=	bil.bil_id
                  and		bil.periodo_id			=	periodo.periodo_id
                  and		periodo.anno			=	p_anno_bilancio
                  and		c.cronop_elem_code 		= 	p_capitolo
                  ----and		c.cronop_elem_code2		is null
                  -----and 	c.cronop_elem_code3 	is null
                  and 	c.elem_tipo_id 			= d.elem_tipo_id
                  and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
                  and 	c.cronop_id 			= b.cronop_id
                  and 	b.programma_id 			= a.programma_id
                  and 	c.ente_proprietario_id 	= 	p_ente_prop_id
                  and 	b.ente_proprietario_id 	= 	c.ente_proprietario_id
                  and 	a.ente_proprietario_id	=	c.ente_proprietario_id
                  and 	d.ente_proprietario_id	=	c.ente_proprietario_id
                  group by a.programma_id;           
         else
        	if	(coalesce(p_anno_bilancio,DEF_NULL)=DEF_NULL or coalesce(p_anno_bilancio,def_spazio)=def_spazio)
          			THEN 
                  	insert into siac_rep_prog_cronop
                       select 	a.programma_id	id_progetto,
          						0,
                                ' ',
                                user_table
                      from 	siac_t_programma a, 
                              siac_t_cronop b, 
                              siac_t_cronop_elem c, 
                              siac_d_bil_elem_tipo d
                      where 	c.cronop_elem_code 		= 	p_capitolo
                      and		c.cronop_elem_code2		= p_articolo
                      and 	c.cronop_elem_code3 	= p_ueb
                      and 	c.elem_tipo_id 			= d.elem_tipo_id
                      and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
                      and 	c.cronop_id 			= b.cronop_id
                      and 	b.programma_id 			= a.programma_id
                      and 	c.ente_proprietario_id 	= 	p_ente_prop_id
                      and 	b.ente_proprietario_id 	= 	c.ente_proprietario_id
                      and 	a.ente_proprietario_id	=	c.ente_proprietario_id
                      and 	d.ente_proprietario_id	=	c.ente_proprietario_id
                      group by a.programma_id;
			ELSE
					insert into siac_rep_prog_cronop
           			 select 	a.programma_id	id_progetto,
          						0,
                                ' ',
                                user_table
                      from 	siac_t_programma a, 
                              siac_t_cronop b, 
                              siac_t_cronop_elem c, 
                              siac_t_bil	bil,
                              siac_t_periodo periodo,
                              siac_d_bil_elem_tipo d
                      where 	b.bil_id				=	bil.bil_id
                      and		bil.periodo_id			=	periodo.periodo_id
                      and		periodo.anno			=	p_anno_bilancio
                      and		c.cronop_elem_code 		= 	p_capitolo
                      and		c.cronop_elem_code2			= p_articolo
                      and 	c.cronop_elem_code3 	= p_ueb
                      and 	c.elem_tipo_id 			= d.elem_tipo_id
                      and		d.elem_tipo_code in (tipo_capitolo_P, tipo_capitolo_G)
                      and 	c.cronop_id 			= b.cronop_id
                      and 	b.programma_id 			= a.programma_id
                      and 	c.ente_proprietario_id 	= 	p_ente_prop_id
                      and 	b.ente_proprietario_id 	= 	c.ente_proprietario_id
                      and 	a.ente_proprietario_id	=	c.ente_proprietario_id
                      and 	d.ente_proprietario_id	=	c.ente_proprietario_id
                      group by a.programma_id;
			end if; 
      end if;
end if;  



-----------------------------------------------------------------------------------------------------------------------------------------
for progettoRec in
    select 	id_programma		id_progetto
    from 	siac_rep_prog_cronop a 
    where 	a.utente	=	user_table
loop
	id_progetto:=progettoRec.id_progetto; 
    raise notice 'progettoRec.id_progetto = %', progettoRec.id_progetto;
    BEGIN
    for datiProgettoRec in
      select 	a.programma_id, 
          a.programma_code			codice_progetto, 
          a.programma_desc			descrizione_progetto,
          h.classif_id,
          h.classif_code,
          h.classif_desc			ambito,
          r.attr_id,
          ta.attr_code,
          ta.attr_desc,
          i.attr_tipo_code,
          i.attr_tipo_desc,
          dps.programma_stato_code,
          dps.programma_stato_desc	stato,
          r.numerico				valore_progetto,
          (select 	r."boolean"
                    from  	siac_t_programma a1,
                              siac_r_programma_attr r,
                              siac_t_attr ta, 
                              siac_d_attr_tipo i    
                    where		a1.programma_id	=	a.programma_id
                    and		a1.programma_id		=	r.programma_id
                    and		ta.attr_id			=	r.attr_id
                    and		ta.attr_tipo_id		=	i.attr_tipo_id
                    and 		i.attr_tipo_code	=	'B'
                    --SIAC-6821 16/05/2019.
                  	--Mancava il filtro sul nome dell'attributo da estrarre.
                    and		ta.attr_code		= 	'FlagRilevanteFPV'
                    and		r.data_cancellazione	is null
                    and		ta.data_cancellazione	is null
                    and		a.ente_proprietario_id	= p_ente_prop_id)  rilev_fpv,
           (select 	r.testo
                    from  	siac_t_programma a1,
                              siac_r_programma_attr r,
                              siac_t_attr ta, 
                              siac_d_attr_tipo i    
                    where		a1.programma_id	=	a.programma_id
                    and		a1.programma_id		=	r.programma_id
                    and		ta.attr_id			=	r.attr_id
                    and		ta.attr_tipo_id		=	i.attr_tipo_id
                    and 		i.attr_tipo_code	=	'X'
                    --SIAC-6821 16/05/2019.
                  	--Mancava il filtro sul nome dell'attributo da estrarre.
                  	and 	upper(ta.attr_code)='NOTE'
                    and		r.data_cancellazione	is null
                    and		ta.data_cancellazione	is null
                    and		a.ente_proprietario_id	= p_ente_prop_id)  note_progetto
          from  	siac_r_programma_class g,
                  siac_t_class h,
                  siac_t_programma a,
                  siac_r_programma_attr r,
                  siac_t_attr ta, 
                  siac_d_attr_tipo i,
                  siac_r_programma_stato rps,
                  siac_d_programma_stato dps     
          where	a.programma_id					=	progettoRec.id_progetto		
                  and		g.classif_id			=	h.classif_id
                  and		g.programma_id			=	a.programma_id
                  and		a.programma_id			=	r.programma_id
                  and		ta.attr_id				=	r.attr_id
                  and		ta.attr_tipo_id			=	i.attr_tipo_id
                  and 	i.attr_tipo_code		=	'N'
                  --SIAC-6821 16/05/2019.
                  --Mancava il filtro sul nome dell'attributo da estrarre.
                	and 	ta.attr_code			=	'ValoreComplessivoProgramma'
                  and		a.programma_id			=	rps.programma_id
                  and		rps.programma_stato_id	=	dps.programma_stato_id
                  and		g.data_cancellazione	is null
                  and		h.data_cancellazione	is null
                  and		r.data_cancellazione	is null
                  and		ta.data_cancellazione	is null
                  and		rps.data_cancellazione	is null
                  and		a.ente_proprietario_id	= 	p_ente_prop_id
                  and		g.ente_proprietario_id	=	a.ente_proprietario_id
                  and		h.ente_proprietario_id	=	a.ente_proprietario_id
                  and		r.ente_proprietario_id	=	a.ente_proprietario_id
                  and		ta.ente_proprietario_id	=	a.ente_proprietario_id
                  and		i.ente_proprietario_id	=	a.ente_proprietario_id
                  and		rps.ente_proprietario_id	=	a.ente_proprietario_id
                  and		dps.ente_proprietario_id	=	a.ente_proprietario_id
          loop
                codice_progetto:=datiProgettoRec.codice_progetto;
                descrizione_progetto:=datiProgettoRec.descrizione_progetto;
                valore_progetto:=datiProgettoRec.valore_progetto;
                ambito:=datiProgettoRec.ambito;
                stato:=datiProgettoRec.stato;
                rilev_fpv:=datiProgettoRec.rilev_fpv;
                note_progetto:=datiProgettoRec.note_progetto;
                BEGIN
                for datiAttoRec in
                   select 	c.attoamm_id				atto_id,
                        c.attoamm_anno				atto_anno,
                        c.attoamm_numero			atto_numero,
                        c.attoamm_oggetto			atto_oggetto,
                        c.attoamm_note				atto_note,
                        c.attoamm_tipo_id			atto_tipo_id,
                        f.attoamm_stato_id			atto_stato_id,
                        f.attoamm_stato_code		atto_stato_code,
                        f.attoamm_stato_desc		atto_stato_desc,
                        e.attoamm_tipo_code			atto_tipo_code,
                        e.attoamm_tipo_desc			atto_tipo_desc
                  from  siac_r_programma_atto_amm b 
                          LEFT join siac_t_atto_amm c
                          on	( b.attoamm_id			=	c.attoamm_id
                                and c.data_cancellazione is null	)
                          LEFT join siac_r_atto_amm_stato d
                          on (d.attoamm_id			=	c.attoamm_id
                                and d.data_cancellazione is null)
                          left join siac_d_atto_amm_stato f
                          on (d.attoamm_stato_id	=	f.attoamm_stato_id
                            and f.data_cancellazione is null)
                          LEFT join siac_d_atto_amm_tipo e
                          on (c.attoamm_tipo_id		=	e.attoamm_tipo_id
                            and e.data_cancellazione is null) 
                  where b.programma_id	=	progettoRec.id_progetto
                    and b.data_cancellazione is null
                    and b.ente_proprietario_id = p_ente_prop_id                    
                  loop   
                        atto_id:=datiAttoRec.atto_id;
                        atto_anno:=datiAttoRec.atto_anno;
                        atto_numero:=datiAttoRec.atto_numero;
                        atto_oggetto:=datiAttoRec.atto_oggetto;
                        atto_note:=datiAttoRec.atto_note;
                        atto_tipo_id:=datiAttoRec.atto_tipo_id;
                        atto_stato_id:=datiAttoRec.atto_stato_id;
                        atto_stato_code:=datiAttoRec.atto_stato_code;
                        atto_stato_desc:=datiAttoRec.atto_stato_desc;
                        atto_tipo_code:=datiAttoRec.atto_tipo_code;
                        atto_tipo_desc:=datiAttoRec.atto_tipo_desc;
                        return next;
                  end loop;
                        id_progetto=0;
                        codice_progetto='';
                        descrizione_progetto='';
                        note_progetto='';
                        valore_progetto=0;
                        ambito='';
                        stato='';
                        rilev_fpv='';
                        atto_id=0;
                        atto_anno='';
                        atto_oggetto='';
                        atto_note='';
                        atto_tipo_id=0;
                        atto_stato_id=0;
                        atto_stato_code='';
                        atto_stato_desc='';
                        atto_tipo_code='';
                        atto_tipo_desc='';
                    exception
                    when no_data_found THEN
                        raise notice 'nessun atto trovato passo 1 ' ;
                        return;
                    when others  THEN
                        RTN_MESSAGGIO:='ricerca dati atto passo 1';
                        RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                        return;
               end;
          end loop;
          exception
              when no_data_found THEN
                  raise notice 'nessun dato progetto trovato passo 2' ;
                  return;
              when others  THEN
                  RTN_MESSAGGIO:='ricerca dati programmi/progetti passo 2';
                  RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
                  return;
    end;
end loop;

delete from siac_rep_prog_cronop where utente=user_table;

exception
	when no_data_found THEN
		raise notice 'nessun programma/progetto trovato nella tabella siac_rep_prog_cronop' ;
		return;
	when others  THEN
        RTN_MESSAGGIO:='ricerca dati programmi/progetti passo 1';
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
        
delete from siac_rep_prog_cronop where utente=user_table;
raise notice 'fine OK';
return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;