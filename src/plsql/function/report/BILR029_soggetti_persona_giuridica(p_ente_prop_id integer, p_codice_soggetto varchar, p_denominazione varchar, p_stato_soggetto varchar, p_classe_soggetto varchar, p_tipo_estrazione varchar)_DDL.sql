/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac."BILR029_soggetti_persona_giuridica" (
  p_ente_prop_id integer,
  p_codice_soggetto varchar = NULL::character varying,
  p_denominazione varchar = NULL::character varying,
  p_stato_soggetto varchar = NULL::character varying,
  p_classe_soggetto varchar = NULL::character varying,
  p_tipo_estrazione varchar = NULL::character varying
)
RETURNS TABLE (
  ambito_id integer,
  soggetto_code varchar,
  codice_fiscale varchar,
  codice_fiscale_estero varchar,
  partita_iva varchar,
  soggetto_desc varchar,
  soggetto_tipo_code varchar,
  soggetto_tipo_desc varchar,
  forma_giuridica_cat_id varchar,
  forma_giuridica_desc varchar,
  forma_giuridica_istat_codice varchar,
  soggetto_id integer,
  stato varchar,
  classe_soggetto varchar,
  desc_tipo_indirizzo varchar,
  tipo_indirizzo varchar,
  via_indirizzo varchar,
  toponimo_indirizzo varchar,
  numero_civico_indirizzo varchar,
  interno_indirizzo varchar,
  frazione_indirizzo varchar,
  comune_indirizzo varchar,
  provincia_indirizzo varchar,
  provincia_sigla_indirizzo varchar,
  stato_indirizzo varchar,
  indirizzo_id integer,
  avviso varchar,
  sede_indirizzo_id integer,
  sede_via_indirizzo varchar,
  sede_toponimo_indirizzo varchar,
  sede_numero_civico_indirizzo varchar,
  sede_interno_indirizzo varchar,
  sede_frazione_indirizzo varchar,
  sede_comune_indirizzo varchar,
  sede_provincia_indirizzo varchar,
  sede_provincia_sigla_indirizzo varchar,
  sede_stato_indirizzo varchar,
  mp_soggetto_id integer,
  mp_soggetto_desc varchar,
  mp_accredito_tipo_code varchar,
  mp_accredito_tipo_desc varchar,
  mp_modpag_stato_desc varchar,
  ricevente varchar,
  accredito_tipo_code varchar,
  accredito_tipo_desc varchar,
  note varchar,
  ricevente_cod_fis varchar,
  ricevente_piva varchar,
  quietanzante varchar,
  quietanzante_cod_fis varchar,
  bic varchar,
  conto_corrente varchar,
  iban varchar,
  mp_data_scadenza date,
  data_scadenza_cessione date
) AS
$body$
DECLARE
	dati_soggetto record;
    DEF_NULL	constant varchar:=''; 
    DEF_SPACES	constant varchar:=' '; 
    RTN_MESSAGGIO varchar(1000):=DEF_NULL;
    user_table	varchar;
  
  BEGIN
  
select fnc_siac_random_user()
into	user_table;


if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
      raise notice '1';
    insert into siac_rep_persona_giuridica
	select 	a.ambito_id,
            a.soggetto_code,
            a.codice_fiscale,
            a.codice_fiscale_estero,
            a.partita_iva,
            b.ragione_sociale,
            d.soggetto_tipo_code,
            d.soggetto_tipo_desc,
            m.forma_giuridica_cat_id,
            m.forma_giuridica_desc,
            m.forma_giuridica_istat_codice,
            a.soggetto_id,
            f.soggetto_stato_desc,
            h.soggetto_classe_desc,
            b.ente_proprietario_id,
            user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
ELSE
	if coalesce(p_stato_soggetto ,DEF_NULL)!=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)=DEF_NULL then
              raise notice '2';
        insert into siac_rep_persona_giuridica
        select 	a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                 
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            siac_t_persona_giuridica 	b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            FULL  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)      
                WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                and		b.ente_proprietario_id	=	a.ente_proprietario_id
                and		c.ente_proprietario_id	=	a.ente_proprietario_id
                and		d.ente_proprietario_id	=	a.ente_proprietario_id
                and		e.ente_proprietario_id	=	a.ente_proprietario_id
                and		f.ente_proprietario_id	=	a.ente_proprietario_id
                and		a.soggetto_id			=	b.soggetto_id
                and		c.soggetto_id			=	b.soggetto_id
                and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                and		e.soggetto_id			=	b.soggetto_id
                and		e.soggetto_stato_id		=	f.soggetto_stato_id
               	and		f.soggetto_stato_desc	=	p_stato_soggetto
                and		a.validita_fine			is null
                and		b.validita_fine			is null
                and		e.validita_fine			is null
                and		c.validita_fine			is null
                and		d.validita_fine			is null
                and		e.validita_fine			is null
                and		f.validita_fine			is null;		
     ELSE
     	if coalesce(p_stato_soggetto ,DEF_NULL)=DEF_NULL and	coalesce(p_classe_soggetto ,DEF_NULL)!=DEF_NULL then
             raise notice 'classe diversa da null';
            insert into siac_rep_persona_giuridica
	select 		a.ambito_id,
                a.soggetto_code,
                a.codice_fiscale,
                a.codice_fiscale_estero,
                a.partita_iva,
                b.ragione_sociale,
                d.soggetto_tipo_code,
                d.soggetto_tipo_desc,
                m.forma_giuridica_cat_id,
                m.forma_giuridica_desc,
                m.forma_giuridica_istat_codice,
                a.soggetto_id,
                f.soggetto_stato_desc,
                h.soggetto_classe_desc,
                b.ente_proprietario_id,
                user_table utente                
    from 	
            siac_r_soggetto_tipo 	c, 
            siac_d_soggetto_tipo 	d,
            siac_r_soggetto_stato	e,
            siac_d_soggetto_stato	f,
            siac_t_soggetto 		a,
            --19/05/2023. siac-tassk-issues #108.
            --bisogna prendere la tabella siac_t_persona_giuridica e non siac_t_persona_fisica
            --siac_t_persona_fisica 	b
            siac_t_persona_giuridica b
            FULL  join siac_r_soggetto_classe	g
            on    	(b.soggetto_id		=	g.soggetto_id
                        and	g.ente_proprietario_id	=	b.ente_proprietario_id
                        and	g.validita_fine	is null)
            RIGHT  join  siac_d_soggetto_classe	h	
            on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
            			AND	H.soggetto_classe_desc	=	p_classe_soggetto
                        and	h.ente_proprietario_id	=	g.ente_proprietario_id
                        and	h.validita_fine	is null)
            FULL  join  siac_r_forma_giuridica	p	
            on    	(b.soggetto_id			=	p.soggetto_id
                        and	p.ente_proprietario_id	=	b.ente_proprietario_id)
            FULL  join  siac_t_forma_giuridica	m	
            on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                        and	p.ente_proprietario_id	=	m.ente_proprietario_id
                        and	p.validita_fine	is null)          
            WHERE	a.ente_proprietario_id	=	p_ente_prop_id
            and		b.ente_proprietario_id	=	a.ente_proprietario_id
            and		c.ente_proprietario_id	=	a.ente_proprietario_id
            and		d.ente_proprietario_id	=	a.ente_proprietario_id
            and		e.ente_proprietario_id	=	a.ente_proprietario_id
            and		f.ente_proprietario_id	=	a.ente_proprietario_id
            and		a.soggetto_id			=	b.soggetto_id
            and		c.soggetto_id			=	b.soggetto_id
            and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
            and		e.soggetto_id			=	b.soggetto_id
            and		e.soggetto_stato_id		=	f.soggetto_stato_id
            and		a.validita_fine			is null
            and		b.validita_fine			is null
            and		e.validita_fine			is null
            and		c.validita_fine			is null
            and		d.validita_fine			is null
            and		e.validita_fine			is null
            and		f.validita_fine			is null;		
            		
      else  
      		      raise notice '3';
            insert into siac_rep_persona_giuridica
            select 	a.ambito_id,
                    a.soggetto_code,
                    a.codice_fiscale,
                    a.codice_fiscale_estero,
                    a.partita_iva,
                    b.ragione_sociale,
                    d.soggetto_tipo_code,
                    d.soggetto_tipo_desc,
                    m.forma_giuridica_cat_id,
                    m.forma_giuridica_desc,
                    m.forma_giuridica_istat_codice,
                    a.soggetto_id,
                    f.soggetto_stato_desc,
                    h.soggetto_classe_desc,
                    b.ente_proprietario_id,
                    user_table utente           
            from 	
                    siac_r_soggetto_tipo 	c, 
                    siac_d_soggetto_tipo 	d,
                    siac_r_soggetto_stato	e,
                    siac_d_soggetto_stato	f,
                    siac_t_soggetto 		a,
                    siac_t_persona_fisica 	b
                    FULL  join siac_r_soggetto_classe	g
                    on    	(b.soggetto_id		=	g.soggetto_id
                                and	g.ente_proprietario_id	=	b.ente_proprietario_id
                                and	g.validita_fine	is null)
                    RIGHT  join  siac_d_soggetto_classe	h	
                    on    	(h.soggetto_classe_id	=	g.soggetto_classe_id
                    			and	h.soggetto_classe_desc	=	p_classe_soggetto
                                and	h.ente_proprietario_id	=	g.ente_proprietario_id
                                and	h.validita_fine	is null)
                    FULL  join  siac_r_forma_giuridica	p	
                    on    	(b.soggetto_id			=	p.soggetto_id
                                and	p.ente_proprietario_id	=	b.ente_proprietario_id)
                    FULL  join  siac_t_forma_giuridica	m	
                    on    	(p.forma_giuridica_id	=	m.forma_giuridica_id
                                and	p.ente_proprietario_id	=	m.ente_proprietario_id
                                and	p.validita_fine	is null)
                    WHERE	a.ente_proprietario_id	=	p_ente_prop_id
                    and		b.ente_proprietario_id	=	a.ente_proprietario_id
                    and		c.ente_proprietario_id	=	a.ente_proprietario_id
                    and		d.ente_proprietario_id	=	a.ente_proprietario_id
                    and		e.ente_proprietario_id	=	a.ente_proprietario_id
                    and		f.ente_proprietario_id	=	a.ente_proprietario_id
                    and		a.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_id			=	b.soggetto_id
                    and		c.soggetto_tipo_id		=	d.soggetto_tipo_id
                    and		e.soggetto_id			=	b.soggetto_id
                    and		e.soggetto_stato_id		=	f.soggetto_stato_id
                    and		f.soggetto_stato_desc	=	p_stato_soggetto
                    and		a.validita_fine			is null
                    and		b.validita_fine			is null
                    and		e.validita_fine			is null
                    and		c.validita_fine			is null
                    and		d.validita_fine			is null
                    and		e.validita_fine			is null
                    and		f.validita_fine			is null;	      
      end if;    
	end if;
end if;



if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '4';
      insert into siac_rep_persona_giuridica_recapiti
     select	d.soggetto_id,				
   				c.principale,			
                b1.via_tipo_desc,			
                c.toponimo,					
                c.numero_civico,			
                c.interno,				
                c.frazione,				
                n.comune_desc,				
                q.provincia_desc,			
                q.sigla_automobilistica,		
                r.nazione_desc,		
                c.avviso,			
                d.ente_proprietario_id,
                user_table utente,
                e.indirizzo_tipo_desc,
                c.indirizzo_id	
 from	  siac_t_persona_giuridica d
              full join	siac_t_indirizzo_soggetto c   
                  on (d.soggetto_id	=	c.soggetto_id
                      and	d.validita_fine	is null) 
              full join siac_r_indirizzo_soggetto_tipo	a
              		on (c.indirizzo_id	=	a.indirizzo_id
                    	and	c.ente_proprietario_id	=	a.ente_proprietario_id
                        and	a.validita_fine	is NULL)
              full join siac_d_indirizzo_tipo	e
              		on (e.indirizzo_tipo_id	=	a.indirizzo_tipo_id
                    	and	e.ente_proprietario_id	=	a.ente_proprietario_id
                        and	e.validita_fine	is null)              
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id
                          and	b1.validita_fine is null)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	n.validita_fine	is null)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id
                              and	o.validita_fine	is null)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id
                              and	q.validita_fine	is null)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id
                              and	r.validita_fine	is null)  
              where 
                      d.ente_proprietario_id 	= p_ente_prop_id
              and		c.ente_proprietario_id 	= 	d.ente_proprietario_id;
end if;  


if  p_tipo_estrazione = '1' or p_tipo_estrazione = '3'	THEN
      		      raise notice '5';
      insert into siac_rep_persona_giuridica_sedi
      select		d.soggetto_id,	
                  ----c.								denominazione,	
                  b1.via_tipo_desc,
                  c.toponimo,
                  c.numero_civico,
                  c.interno,
                  c.frazione,
                  n.comune_desc,
                  q.provincia_desc,
                  q.sigla_automobilistica,
                  r.nazione_desc,
                  '',
                  c.indirizzo_id,
                  d.ente_proprietario_id,
                  user_table utente             
      from 	siac_d_relaz_tipo b, 
              siac_r_soggetto_relaz a  
              RIGHT join	siac_t_persona_fisica d
                  on (		d.soggetto_id	=	a.soggetto_id_da
                      and	d.validita_fine	is null)
              full join siac_t_indirizzo_soggetto c
                  on (a.soggetto_id_a	=	c.soggetto_id	
                      and	c.validita_fine is null) 
              FULL  join siac_d_via_tipo b1
                      on (b1.via_tipo_id	=	c.via_tipo_id
                          and	b1.ente_proprietario_id	=	c.ente_proprietario_id)  
              FULL  join  siac_t_comune	n	
                  on    	(n.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_r_comune_provincia	o	
                  on    	(o.comune_id	=	c.comune_id
                              and	n.ente_proprietario_id	=	c.ente_proprietario_id)
              FULL  join  siac_t_provincia	q	
                  on    	(q.provincia_id	=	o.provincia_id
                              and	q.ente_proprietario_id	=	o.ente_proprietario_id)
              FULL  join  siac_t_nazione	r	
                  on    	(n.nazione_id	=	r.nazione_id
                              and	r.ente_proprietario_id	=	n.ente_proprietario_id)  
              where a.relaz_tipo_id = b.relaz_tipo_id
              and 	b.relaz_tipo_code ='SEDE_SECONDARIA'
              and 	a.ente_proprietario_id 	= p_ente_prop_id
              and 	b.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	c.ente_proprietario_id 	= 	a.ente_proprietario_id
              and	d.ente_proprietario_id	=	a.ente_proprietario_id;



end if;  
if  p_tipo_estrazione = '1' or p_tipo_estrazione = '4'	THEN
	insert into siac_rep_persona_giuridica_modpag
       select
        	a.soggetto_id,	
    		a.soggetto_desc,
            0,
            ' ',
            ' ',
            ' ',   
            b.modpag_id, 
            b.accredito_tipo_id, 
			c.accredito_tipo_code, 
            c.accredito_tipo_desc, 
            d.modpag_stato_code, 
            d.modpag_stato_desc,
            ' ',
            ' ',
            ' ',
            a.ente_proprietario_id,
            user_table utente,
            a.soggetto_code,
            b.quietanziante,
            b.quietanziante_codice_fiscale,
            b.iban,
            b.bic,
            b.contocorrente,
            b.data_scadenza,
            NULL  
        from 	siac_t_soggetto a,
    			siac_t_modpag b ,
            	siac_d_accredito_tipo c, 
            	siac_d_modpag_stato d, 
				siac_r_modpag_stato e
        where a.ente_proprietario_id = p_ente_prop_id
        and	a.ente_proprietario_id=b.ente_proprietario_id
        and	c.ente_proprietario_id=a.ente_proprietario_id
        and	d.ente_proprietario_id=a.ente_proprietario_id
        and	e.ente_proprietario_id=a.ente_proprietario_id
        and a.soggetto_id = b.soggetto_id
        and b.accredito_tipo_id = c.accredito_tipo_id
        and e.modpag_id = b.modpag_id
        and	e.modpag_stato_id	=	d.modpag_stato_id      
   union  
    select 
           	a.soggetto_id_da,
            d.soggetto_desc,
            a.soggetto_id_a,
            x.soggetto_desc,
            x.codice_fiscale,
            x.partita_iva,
            0,
            a.relaz_tipo_id,
 			c.relaz_tipo_code,
        	c.relaz_tipo_desc,
 			g.relaz_stato_code,
        	g.relaz_stato_desc,
        	b.note,
        	f.accredito_tipo_code,
        	f.accredito_tipo_desc,
        	a.ente_proprietario_id,
            user_table utente,
        	d.soggetto_code,
            ' ',
            ' ',
            ' ',
            ' ',
            ' ',
            NULL,
            e.data_scadenza
    from 		siac_r_soggetto_relaz a, 
    			siac_r_soggrel_modpag b, 
                siac_d_relaz_tipo c,
  				siac_t_soggetto d, 
                siac_t_modpag e, 
                siac_d_accredito_tipo f,
 				siac_d_relaz_stato g, 
				siac_r_soggetto_relaz_stato h, 
                siac_t_soggetto x
	where 	b.soggetto_relaz_id		= 	a.soggetto_relaz_id
		and a.relaz_tipo_id			= 	c.relaz_tipo_id
		and a.soggetto_id_da 		=	d.soggetto_id
        and	b.modpag_id				=	e.modpag_id
        and	e.accredito_tipo_id		=	f.accredito_tipo_id
        and h.soggetto_relaz_id		=	b.soggetto_relaz_id
        and	h.relaz_stato_id		=	g.relaz_stato_id
        and a.soggetto_id_a			=	x.soggetto_id
        and d.ente_proprietario_id	=	p_ente_prop_id
        and	a.ente_proprietario_id	=	d.ente_proprietario_id
        and b.ente_proprietario_id	=	d.ente_proprietario_id
        and c.ente_proprietario_id	=	d.ente_proprietario_id
        and e.ente_proprietario_id	=	d.ente_proprietario_id
        and f.ente_proprietario_id	=	d.ente_proprietario_id
        and g.ente_proprietario_id	=	d.ente_proprietario_id
        and h.ente_proprietario_id	=	d.ente_proprietario_id;
end if;
if coalesce(p_codice_soggetto ,DEF_NULL)=DEF_NULL	then
for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione				      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and 	a.utente	=	user_table
       				and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    and 	a.utente	=	user_table
       and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    and 	a.utente	=	user_table
       and	d.utente	=	user_table)
       --SIAC-6215: 12/06/2018: nel caso la denominazione sia NULL
    --	viene trasformata in ''.
        --where a.soggetto_desc	like '%'|| p_denominazione ||'%'
     where a.soggetto_desc	like '%'|| COALESCE(p_denominazione, DEF_NULL) ||'%'        
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
     end loop;


  raise notice 'fine OK';
else
for dati_soggetto in 
	select 	a.ambito_id					ambito_id,
    		a.soggetto_code				soggetto_code,
            a.codice_fiscale			codice_fiscale,
            a.codice_fiscale_estero		codice_fiscale_estero, 
            a.partita_iva				partita_iva, 
            a.soggetto_desc				soggetto_desc, 
            a.soggetto_tipo_code		soggetto_tipo_code, 
            a.soggetto_tipo_desc		soggetto_tipo_desc,
            a.forma_giuridica_cat_id	forma_giuridica_cat_id,
            a.forma_giuridica_desc		forma_giuridica_desc,
            a.forma_giuridica_istat_codice	forma_giuridica_istat_codice,
            a.soggetto_id				soggetto_id,
            a.stato						stato,
            a.classe_soggetto			classe_soggetto,
            b.tipo_indirizzo			tipo_indirizzo,		
            coalesce (b.via,DEF_SPACES)						via_indirizzo,
            coalesce (b.toponimo,DEF_SPACES)					toponimo_indirizzo, 
            coalesce (b.numero_civico,DEF_SPACES)				numero_civico_indirizzo,
            coalesce (b.interno,DEF_SPACES)						interno_indirizzo,
            coalesce (b.frazione,DEF_SPACES)					frazione_indirizzo,
            coalesce (b.comune,DEF_SPACES)						comune_indirizzo,
            coalesce (b.provincia_desc_sede,DEF_SPACES)			provincia_indirizzo,
            coalesce (b.provincia_sigla,DEF_SPACES)				provincia_sigla_indirizzo,
            coalesce (b.stato_sede,DEF_SPACES)					stato_indirizzo,
            b.avviso					avviso,
            b.desc_tipo_indirizzo		desc_tipo_indirizzo,
            b.indirizzo_id				indirizzo_id,
            c.indirizzo_id_sede			sede_indirizzo_id,
            coalesce (c.via_sede,DEF_SPACES)					sede_via_indirizzo,
        	coalesce (c.toponimo_sede,DEF_SPACES)				sede_toponimo_indirizzo,					
            coalesce (c.numero_civico_sede,DEF_SPACES)			sede_numero_civico_indirizzo,
            coalesce (c.interno_sede,DEF_SPACES)				sede_interno_indirizzo,
            coalesce (c.frazione_sede,DEF_SPACES)				sede_frazione_indirizzo,
            coalesce (c.comune_sede,DEF_SPACES)					sede_comune_indirizzo,
            coalesce (c.provincia_desc_sede,DEF_SPACES)			sede_provincia_indirizzo,
            coalesce (c.provincia_sigla_sede,DEF_SPACES)		sede_provincia_sigla_indirizzo,
            coalesce (c.stato_sede,DEF_SPACES)					sede_stato_indirizzo,
           	d.soggetto_id				mp_soggetto_id,
            d.soggetto_desc				mp_soggetto_desc,
            d.accredito_tipo_code		mp_accredito_tipo_code,
            d.accredito_tipo_desc		mp_accredito_tipo_desc,
            d.modpag_stato_desc			mp_modpag_stato_desc,
            coalesce (d.soggetto_ricevente_desc,DEF_SPACES)			ricevente,
            coalesce (d.soggetto_ricevente_cod_fis,DEF_SPACES)		ricevente_cod_fis,
            coalesce (d.soggetto_ricevente_piva ,DEF_SPACES)		ricevente_piva,		
            coalesce (d.accredito_ricevente_tipo_code,DEF_SPACES)	accredito_tipo_code,
            coalesce (d.accredito_ricevente_tipo_desc,DEF_SPACES)	accredito_tipo_desc,
          	coalesce (d.note,DEF_SPACES)							note,
            coalesce (d.quietanzante,DEF_SPACES)					quietanzante,
            coalesce (d.quietanzante_codice_fiscale,DEF_SPACES)		quietanzante_cod_fis,
            coalesce (d.bic,DEF_SPACES)								bic,
            coalesce (d.conto_corrente,DEF_SPACES)					conto_corrente,
            coalesce (d.iban,DEF_SPACES)							iban,
            d.mp_data_scadenza										mp_data_scadenza,
            d.data_scadenza_cessione								data_scadenza_cessione				      
    from siac_rep_persona_giuridica	a
    LEFT join	siac_rep_persona_giuridica_recapiti b   
                  on (a.soggetto_id	=	b.soggetto_id
                  and 	a.utente	=	user_table
       				and	b.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_sedi c   
    on (a.soggetto_id	=	c.soggetto_id
    and 	a.utente	=	user_table
       and	c.utente	=	user_table)
    LEFT join	siac_rep_persona_giuridica_modpag d   
    on (a.soggetto_code	=	d.soggetto_code
    and 	a.utente	=	user_table
       and	d.utente	=	user_table)
        where a.soggetto_code	=	p_codice_soggetto
    loop
        ambito_id:=dati_soggetto.ambito_id;
        soggetto_code:=dati_soggetto.soggetto_code;
        codice_fiscale:=dati_soggetto.codice_fiscale;
        codice_fiscale_estero:=dati_soggetto.codice_fiscale_estero;
        partita_iva:=dati_soggetto.partita_iva;
        soggetto_desc:=dati_soggetto.soggetto_desc;
        soggetto_tipo_code:=dati_soggetto.soggetto_tipo_code;
        soggetto_tipo_desc:=dati_soggetto.soggetto_tipo_desc;
        soggetto_id:=dati_soggetto.soggetto_id;
        stato:=dati_soggetto.stato;
        forma_giuridica_cat_id:=dati_soggetto.forma_giuridica_cat_id;
        forma_giuridica_desc:=dati_soggetto.forma_giuridica_desc;
        forma_giuridica_istat_codice:=dati_soggetto.forma_giuridica_istat_codice;
        classe_soggetto:=dati_soggetto.classe_soggetto;   
        tipo_indirizzo:=dati_soggetto.tipo_indirizzo;
  		via_indirizzo:=dati_soggetto.via_indirizzo;
  		toponimo_indirizzo:=dati_soggetto.toponimo_indirizzo;
  		numero_civico_indirizzo:=dati_soggetto.numero_civico_indirizzo;
  		interno_indirizzo:=dati_soggetto.interno_indirizzo;
  		frazione_indirizzo:=dati_soggetto.frazione_indirizzo;
  		comune_indirizzo:=dati_soggetto.comune_indirizzo;
  		provincia_indirizzo:=dati_soggetto.provincia_indirizzo;
  		provincia_sigla_indirizzo:=dati_soggetto.provincia_sigla_indirizzo;
  		stato_indirizzo:=dati_soggetto.stato_indirizzo;
        avviso:=dati_soggetto.avviso;
        indirizzo_id:=dati_soggetto.indirizzo_id;
        desc_tipo_indirizzo:=dati_soggetto.desc_tipo_indirizzo;
        sede_indirizzo_id:=dati_soggetto.sede_indirizzo_id;
        sede_via_indirizzo:=dati_soggetto.sede_via_indirizzo;
       	sede_toponimo_indirizzo:=dati_soggetto.sede_toponimo_indirizzo;					
        sede_numero_civico_indirizzo:=dati_soggetto.sede_numero_civico_indirizzo;
        sede_interno_indirizzo:=dati_soggetto.sede_interno_indirizzo;
        sede_frazione_indirizzo:=dati_soggetto.sede_frazione_indirizzo;
       	sede_comune_indirizzo:=dati_soggetto.sede_comune_indirizzo;
       	sede_provincia_indirizzo:=dati_soggetto.sede_provincia_indirizzo;
        sede_provincia_sigla_indirizzo:=dati_soggetto.sede_provincia_sigla_indirizzo;
        sede_stato_indirizzo:=dati_soggetto.sede_stato_indirizzo;
         mp_soggetto_id:=dati_soggetto.mp_soggetto_id;
        mp_soggetto_desc:=dati_soggetto.mp_soggetto_desc;
        mp_accredito_tipo_code:=dati_soggetto.mp_accredito_tipo_code;
        mp_accredito_tipo_desc:=dati_soggetto.mp_accredito_tipo_desc;
        mp_modpag_stato_desc:=dati_soggetto.mp_modpag_stato_desc;
        ricevente:=dati_soggetto.ricevente;		
        accredito_tipo_code:=dati_soggetto.accredito_tipo_code;
        accredito_tipo_desc:=dati_soggetto.accredito_tipo_desc;
        note:=dati_soggetto.note;
        ricevente_cod_fis:=dati_soggetto.ricevente_cod_fis;
        ricevente_piva:=dati_soggetto.ricevente_piva;
        quietanzante:=dati_soggetto.quietanzante;
        quietanzante_cod_fis:=dati_soggetto.quietanzante_cod_fis;
        bic:=dati_soggetto.bic;
        conto_corrente:=dati_soggetto.conto_corrente;
        iban:=dati_soggetto.iban;
        mp_data_scadenza:=dati_soggetto.mp_data_scadenza;
        data_scadenza_cessione:=dati_soggetto.data_scadenza_cessione;
        return next;
        ambito_id=0;
        soggetto_code='';
        codice_fiscale='';
     	codice_fiscale_estero='';
        partita_iva='';
        soggetto_desc='';
        soggetto_tipo_code='';
        soggetto_tipo_desc='';
        soggetto_id=0;
        stato='';
        forma_giuridica_cat_id=0;
        forma_giuridica_desc='';
        forma_giuridica_istat_codice='';
        classe_soggetto='';
        tipo_indirizzo='';
  		via_indirizzo='';
  		toponimo_indirizzo='';
  		numero_civico_indirizzo='';
  		interno_indirizzo='';
  		frazione_indirizzo='';
  		comune_indirizzo='';
  		provincia_indirizzo='';
  		provincia_sigla_indirizzo='';
  		stato_indirizzo='';
        avviso='';
       indirizzo_id=0;
        desc_tipo_indirizzo='';
        sede_indirizzo_id=0;
        sede_via_indirizzo='';
       	sede_toponimo_indirizzo='';
        sede_numero_civico_indirizzo='';
        sede_interno_indirizzo='';
        sede_frazione_indirizzo='';
       	sede_comune_indirizzo='';
       	sede_provincia_indirizzo='';
        sede_provincia_sigla_indirizzo='';
        sede_stato_indirizzo='';
        mp_soggetto_id=0;
        mp_soggetto_desc='';
        mp_accredito_tipo_code='';
        mp_accredito_tipo_desc='';
        mp_modpag_stato_desc='';
        ricevente='';
        accredito_tipo_code='';
        accredito_tipo_desc='';
       	note='';
        ricevente_cod_fis='';
        ricevente_piva='';
        quietanzante='';
        quietanzante_cod_fis='';
        bic='';
        conto_corrente='';
        iban='';
        mp_data_scadenza=NULL;
        data_scadenza_cessione=NULL;
     end loop;


  raise notice 'fine OK';
end if;    
delete from siac_rep_persona_giuridica where utente=user_table;
delete from siac_rep_persona_giuridica_recapiti where utente=user_table;
delete from siac_rep_persona_giuridica_sedi where utente=user_table;	
delete from siac_rep_persona_giuridica_modpag where utente=user_table;	

EXCEPTION
when no_data_found THEN
	raise notice 'nessun soggetto  trovato';
	return;
when others  THEN
 RTN_MESSAGGIO:='Ricerca dati soggetto';
 RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR029_soggetti_persona_giuridica" (p_ente_prop_id integer, p_codice_soggetto varchar, p_denominazione varchar, p_stato_soggetto varchar, p_classe_soggetto varchar, p_tipo_estrazione varchar)
  OWNER TO siac;