/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 26.06.2018 Sofia siac-6193
/*
indirizzo principale del soggetto (es. nella forma ‘compatta’ in un'unica colonna: comune – via). Qualora non fosse possibile inserirlo come colonna può essere valutata l’ipotesi del tool-tip sul codice soggetto che visualizza l’indirizzo
stato del soggetto
motivazione della sospensione del soggetto (tool-tip sullo stato soggetto)
*/
--DROP FUNCTION siac.fnc_siac_cons_entita_soggetto (integer,varchar,varchar,varchar,varchar, integer, integer);

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_soggetto (
  _ente_proprietario_id integer,
  _codice_soggetto varchar,
  _denominazione_soggetto varchar,
  _codice_fiscale_soggetto varchar,
  _partita_iva_soggetto varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  soggetto_code varchar,
  soggetto_desc varchar,
  soggetto_codice_fiscale varchar,
  soggetto_partita_iva varchar,
  soggetto_via_tipo_desc varchar,
  soggetto_toponimo varchar,
  soggetto_comune_desc varchar,
  soggetto_stato_desc varchar,
  soggetto_nota_operazione varchar,
  soggetto_extcarta varchar,
  soggetto_matricola varchar,
  soggetto_mod_pag_code varchar,
  soggetto_mod_pag_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
	stringaTest character varying := 'Test';
BEGIN

RETURN QUERY
with sg as(
	with sogg as (
      select
        sog.soggetto_id
        ,sog.soggetto_code
        ,sog.soggetto_desc
        ,sog.codice_fiscale::varchar
        ,sog.partita_iva
        ,tipo.via_tipo_desc -- 26.06.2018 Sofia siac-6193
        ,ind.toponimo -- 26.06.2018 Sofia siac-6193
        ,com.comune_desc -- 26.06.2018 Sofia siac-6193
        ,stato.soggetto_stato_desc -- 26.06.2018 Sofia siac-6193
        ,COALESCE (rs.nota_operazione,' ') nota_operazione -- 26.06.2018 Sofia siac-6193
       from siac_d_ambito  a,siac_T_soggetto  sog,siac_t_indirizzo_soggetto ind,
            siac_t_comune  com,siac_d_via_tipo tipo,siac_r_soggetto_stato rs,siac_d_soggetto_stato stato
       where a.ente_proprietario_id=_ente_proprietario_id
        and  a.ambito_code='AMBITO_FIN'
        and  sog.ambito_id=a.ambito_id
		and  ind.soggetto_id = sog.soggetto_id
        and  com.comune_id = ind.comune_id
        and  tipo.via_tipo_id = ind.via_tipo_id
   	    and  rs.soggetto_id = sog.soggetto_id
		and  stato.soggetto_stato_id = rs.soggetto_stato_id
        and  coalesce(ind.principale,'N')='S' --- indirizzo principale
        and (_codice_soggetto is null or upper(sog.soggetto_code) = upper(_codice_soggetto))
        and (_denominazione_soggetto is null or upper(sog.soggetto_desc) like  '%'||upper(_denominazione_soggetto)||'%')
        and (_codice_fiscale_soggetto is null or _codice_fiscale_soggetto=sog.codice_fiscale)
        and (_partita_iva_soggetto is null or _partita_iva_soggetto=sog.partita_iva)
		and rs.data_cancellazione is null
        and now() between rs.validita_inizio and COALESCE(rs.validita_fine,now())
        and sog.data_cancellazione is null
        and now() between sog.validita_inizio and COALESCE(sog.validita_fine,now())
        and ind.data_cancellazione is null
        and now() between ind.validita_inizio and COALESCE(ind.validita_fine,now())
      ),
      soggattr as (
        select b.*
        from  siac_r_soggetto_attr b,siac_t_attr c
        where c.ente_proprietario_id=_ente_proprietario_id
        and   c.attr_code='Matricola'
        and   b.attr_id=c.attr_id
        and   coalesce(b.testo,'')!=''
        and   b.data_cancellazione is null
        and  now() between b.validita_inizio and COALESCE(b.validita_fine,now())
      ),
      cartaContabile  as -- 26.06.2018 Sofia siac-6193
      (
      	select distinct r.soggetto_id
        from siac_r_cartacont_det_soggetto r
        where r.ente_proprietario_id=_ente_proprietario_id
        and   r.data_cancellazione is null
        and now() between r.validita_inizio and COALESCE(r.validita_fine,now())
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
        ,sogg.soggetto_stato_desc
        ,sogg.nota_operazione
        ,(CASE when cartaContabile.soggetto_id is null then 'N'::varchar ELSE 'S'::varchar END) extcarta
        ,coalesce(soggattr.testo,' ') matricola
    from sogg
    	left outer join  soggattr on sogg.soggetto_id=soggattr.soggetto_id
		left outer join  cartaContabile on sogg.soggetto_id=cartaContabile.soggetto_id
)

select
	sg.*
    ,' '::varchar soggetto_mod_pag_code
    ,' '::varchar soggetto_mod_pag_desc
   	from sg


LIMIT _limit
OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;