/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists  siac.fnc_tefa_trib_comune_anno_rif_estrai(p_ente_proprietario_id integer,p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_comune_anno_rif_estrai(p_ente_proprietario_id integer,p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
RETURNS TABLE
(
  codice_comune varchar,
  raggruppamento_codice_tributo varchar,
  importo_a_debito_versato      numeric,
  importo_a_credito_compensato  numeric,
  anno_di_riferimento_str       varchar,
  ente                          varchar,
  anno_di_riferimento           varchar,
  tipologia                     VARCHAR,
  importo_tefa_lordo            numeric,
  importo_credito               numeric,
  importo_comm                  numeric,
  importo_tefa_netto            numeric
) AS
$body$
DECLARE

annoPrec integer;
annoPrecPrec integer;

sql_query text;

BEGIN

 raise notice 'p_ente_proprietario_id=%',p_ente_proprietario_id::varchar;
 raise notice 'p_tefa_trib_upload_id=%',p_tefa_trib_upload_id::varchar;
 raise notice 'p_tefa_trib_comune_anno=%',p_tefa_trib_comune_anno::varchar;

 annoPrecPrec:=p_tefa_trib_comune_anno-2;
 annoPrec:=p_tefa_trib_comune_anno-1;

 raise notice 'annoPrecPrec=%',annoPrecPrec::varchar;
 raise notice 'annoPrec=%',annoPrec::varchar;

 sql_query:=
 'select query.codice_comune::varchar,
       upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
       query.importo_a_debito_versato::numeric,
       query.importo_a_credito_compensato::numeric,
       query.anno_di_riferimento_str::varchar,
       query.ente::varchar,
       query.anno_di_riferimento::varchar,
       query.tipologia::varchar,
       query.importo_tefa_lordo::numeric,
       query.importo_credito::numeric,
       query.importo_comm::numeric,
       query.importo_tefa_netto::numeric
 from
 (

 with 
 raggruppa_sel as
 (
 select tipo.tefa_trib_tipologia_code,
        tipo.tefa_trib_tipologia_desc,
        gruppo.tefa_trib_gruppo_code,
        gruppo.tefa_trib_gruppo_desc,
        gruppo.tefa_trib_gruppo_anno,
        gruppo.tefa_trib_gruppo_f1_id,
        gruppo.tefa_trib_gruppo_f2_id,
        gruppo.tefa_trib_gruppo_f3_id,
        trib.tefa_trib_code,
        trib.tefa_trib_desc,
        trib.tefa_trib_id,
        gruppo.tefa_trib_gruppo_id,        
        tipo.tefa_trib_tipologia_id
 from  siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
       siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
  where trib.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and  r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and  gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and  tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
  and  trib.data_cancellazione is null
  and  trib.validita_fine is null
  and  gruppo.data_cancellazione is null
  and  gruppo.validita_fine is null
  and  tipo.data_cancellazione is null
  and  tipo.validita_fine is null
  and  r_gruppo.data_cancellazione is null
  and  r_gruppo.validita_fine is null
 ),
 tefa_sel as 
 (
 select tefa.tefa_trib_file_id,
        tefa.tefa_trib_tributo_code,
        tefa.tefa_trib_comune_code,
        tefa.tefa_trib_importo_versato_deb,
        tefa.tefa_trib_importo_compensato_cred,
        tefa.tefa_trib_anno_rif_str,
		tefa.tefa_trib_anno_rif,
        com.tefa_trib_comune_cat_desc
 from siac_t_tefa_trib_importi tefa 
      left join siac_d_tefa_trib_comune com on (com.ente_proprietario_id=tefa.ente_proprietario_id and com.tefa_trib_comune_code=tefa.tefa_trib_comune_code and com.data_cancellazione is null )
 where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar||      
' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar||
' and   tefa.tefa_trib_tipo_record=''D''
 and   tefa.data_cancellazione is null
 and   tefa.validita_fine is null
 )
 select
   tefa_sel.tefa_trib_file_id,
   tefa_sel.tefa_trib_comune_code codice_comune,
   raggruppa_sel.tefa_trib_gruppo_id ,
   raggruppa_sel.tefa_trib_gruppo_code,
   sum(tefa_sel.tefa_trib_importo_versato_deb) importo_a_debito_versato,
   sum(tefa_sel.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   ( case when tefa_sel.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ) anno_di_riferimento_str,
   tefa_sel.tefa_trib_comune_cat_desc ente,
  (case when tefa_sel.tefa_trib_anno_rif::integer<='||annoPrecPrec::VARCHAR||' then '||annoPrecPrec::VARCHAR||
   	     ' when tefa_sel.tefa_trib_anno_rif::integer='||annoPrec::varchar||' then tefa_sel.tefa_trib_anno_rif::integer
           when tefa_sel.tefa_trib_anno_rif::integer>='||p_tefa_trib_comune_anno::varchar||' then tefa_sel.tefa_trib_anno_rif::integer else null end ) anno_di_riferimento,   
   raggruppa_sel.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa_sel.tefa_trib_importo_compensato_cred)
                                  ) importo_credito,
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa_sel.tefa_trib_importo_versato_deb))
                                )  importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb)) -
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_compensato_cred)) -
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f3_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(raggruppa_sel.tefa_trib_gruppo_f1_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f1_id
                                   when coalesce(raggruppa_sel.tefa_trib_gruppo_f2_id,0)!=0 then raggruppa_sel.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa_sel.tefa_trib_importo_versato_deb) )
                                  ) importo_tefa_netto
from  raggruppa_sel , tefa_sel
where raggruppa_sel.tefa_trib_code=tefa_sel.tefa_trib_tributo_code
  and raggruppa_sel.tefa_trib_gruppo_anno=tefa_sel.tefa_trib_anno_rif_str
group by tefa_sel.tefa_trib_file_id,
	     tefa_sel.tefa_trib_comune_code,
         raggruppa_sel.tefa_trib_gruppo_id,
		 raggruppa_sel.tefa_trib_gruppo_code,
         raggruppa_sel.tefa_trib_gruppo_f1_id,raggruppa_sel.tefa_trib_gruppo_f2_id,raggruppa_sel.tefa_trib_gruppo_f3_id,
		 ( case when tefa_sel.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa_sel.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ),
         tefa_sel.tefa_trib_comune_cat_desc,
         (case when tefa_sel.tefa_trib_anno_rif::integer<='||annoPrecPrec::VARCHAR||' then '||annoPrecPrec::VARCHAR||
   	     ' when tefa_sel.tefa_trib_anno_rif::integer='||annoPrec::varchar||' then tefa_sel.tefa_trib_anno_rif::integer
           when tefa_sel.tefa_trib_anno_rif::integer>='||p_tefa_trib_comune_anno::varchar||' then tefa_sel.tefa_trib_anno_rif::integer else null end ),
         raggruppa_sel.tefa_trib_tipologia_desc
order by 2,4
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
and   upd.data_cancellazione is null 
and   upd.validita_fine is null
order by 1,query.tefa_trib_gruppo_code::integer;'::text;

raise notice 'sql_query=%',sql_query::varchar;
return query execute sql_query;

exception
	when no_data_found THEN
    raise notice 'Nessun dato trovato.';
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;