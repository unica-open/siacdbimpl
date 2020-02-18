/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_soggetto_total (
  _ente_proprietario_id integer,
  _codice_soggetto varchar,
  _denominazione_soggetto varchar,
  _codice_fiscale_soggetto varchar,
  _partita_iva_soggetto varchar
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN
	
select	coalesce(count(*),0) into total
	from (
  
         with sg as(
            with sogg as (
              select 
                siac_T_soggetto.soggetto_id
                ,siac_T_soggetto.soggetto_code
                ,siac_T_soggetto.soggetto_desc
                ,siac_T_soggetto.codice_fiscale::varchar
                ,siac_T_soggetto.partita_iva
                ,siac_d_via_tipo.via_tipo_desc
                ,siac_t_indirizzo_soggetto.toponimo
                ,siac_t_comune.comune_desc
                
               from 
                  siac_T_soggetto 
                  ,siac_d_ambito 
                  ,siac_t_indirizzo_soggetto
                  ,siac_t_comune 
                  ,siac_d_via_tipo
               where  
                    siac_T_soggetto.ambito_id=siac_d_ambito.ambito_id
                and siac_T_soggetto.soggetto_id = siac_t_indirizzo_soggetto.soggetto_id	
                and siac_t_indirizzo_soggetto.comune_id = siac_t_comune.comune_id 
                and siac_t_indirizzo_soggetto.via_tipo_id = siac_d_via_tipo.via_tipo_id 
                and siac_d_ambito.ambito_code='AMBITO_FIN' 
                and  siac_T_soggetto.ente_proprietario_id=_ente_proprietario_id 
                and (_codice_soggetto is null or upper(siac_T_soggetto.soggetto_code) = upper(_codice_soggetto))
                and (_denominazione_soggetto is null or upper(siac_T_soggetto.soggetto_desc) like  '%'||upper(_denominazione_soggetto)||'%')
                and (_codice_fiscale_soggetto is null or _codice_fiscale_soggetto=siac_T_soggetto.codice_fiscale)
                and (_partita_iva_soggetto is null or _partita_iva_soggetto=siac_T_soggetto.partita_iva)
              ),
              soggattr as (
                select b.*-- b.soggetto_id,b.testo
                from 
                siac_r_soggetto_attr b,siac_t_attr c 
                where c.attr_id=b.attr_id
                and b.data_cancellazione is null
                and c.data_cancellazione is NULL
                and now() between b.validita_inizio and COALESCE(b.validita_fine,now())
                and c.attr_code='Matricola'
                and b.testo is not null
              ) 
            select 
                 sogg.soggetto_id
                ,sogg.soggetto_code
                ,sogg.soggetto_desc
                ,sogg.codice_fiscale
                ,sogg.partita_iva
                ,sogg.via_tipo_desc
                ,sogg.toponimo
                ,sogg.comune_desc
                ,soggattr.testo matricola
             
            from sogg left outer join  soggattr on sogg.soggetto_id=soggattr.soggetto_id 
        )

        select 
            sg.*
            ,' '::varchar soggetto_mod_pag_code
            ,' '::varchar soggetto_mod_pag_desc 
            from sg 


	) as soggtotal;

	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;