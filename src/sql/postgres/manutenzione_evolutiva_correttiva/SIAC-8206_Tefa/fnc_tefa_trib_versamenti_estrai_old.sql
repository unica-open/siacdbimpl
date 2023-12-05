/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop FUNCTION if exists siac.fnc_tefa_trib_versamenti_estrai(p_ente_proprietario_id integer,p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer);

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_versamenti_estrai(p_ente_proprietario_id integer,p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
RETURNS TABLE
(
  data_ripartizione varchar,
  data_bonifico     varchar,
  raggruppamento_codice_tributo varchar,
  importo_a_debito_versato      numeric,
  importo_a_credito_compensato  numeric,
  anno_di_riferimento_str       varchar,
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
  'select query.data_ripartizione::varchar,
          query.data_bonifico::varchar,
          upd.tefa_trib_gruppo_upload::varchar raggruppamento_codice_tributo,
          query.importo_a_debito_versato::numeric,
          query.importo_a_credito_compensato::numeric,
          query.anno_di_riferimento_str::varchar,
          query.importo_tefa_lordo::numeric,
          query.importo_credito::numeric,
          query.importo_comm::numeric,
          query.importo_tefa_netto::numeric
  from
  (


  select
   tefa.tefa_trib_file_id,
   (case when tefa.tefa_trib_data_ripart like '''||chr(37)||'-'||chr(37)||''' then
              tefa.tefa_trib_data_ripart
          else
             substring(tefa.tefa_trib_data_ripart,7,4)||''/''||substring(tefa.tefa_trib_data_ripart,4,2)||''/''||substring(tefa.tefa_trib_data_ripart,1,2)
    end)::timestamp  data_ripartizione_dt,
   (case when tefa.tefa_trib_data_bonifico like '''||chr(37)||'-'||chr(37)||''' then
              tefa.tefa_trib_data_bonifico
          else
             substring(tefa.tefa_trib_data_bonifico,7,4)||''/''||substring(tefa.tefa_trib_data_bonifico,4,2)||''/''||substring(tefa.tefa_trib_data_bonifico,1,2)
    end)::timestamp  data_bonifico_dt,
   (case when tefa.tefa_trib_data_ripart like '''||chr(37)||'-'||chr(37)||''' then
         substring(tefa.tefa_trib_data_ripart,9,2)||''/''||substring(tefa.tefa_trib_data_ripart,6,2)||''/''||substring(tefa.tefa_trib_data_ripart,1,4)
         else      tefa.tefa_trib_data_ripart end)  data_ripartizione,
   (case when tefa.tefa_trib_data_bonifico like '''||chr(37)||'-'||chr(37)||''' then
         substring(tefa.tefa_trib_data_bonifico,9,2)||''/''||substring(tefa.tefa_trib_data_bonifico,6,2)||''/''||substring(tefa.tefa_trib_data_bonifico,1,4)
         else      tefa.tefa_trib_data_bonifico end)  data_bonifico,
   gruppo.tefa_trib_gruppo_tipo_id,
  ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::varchar||''''||
         ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
         ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''' end ) anno_di_riferimento_str,
   sum(tefa.tefa_trib_importo_versato_deb) importo_a_debito_versato ,
   sum(tefa.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo ,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                 ) importo_credito,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f3_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 )
                                 ) importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) -
  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                 ) -
 (
 fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f3_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(tipo.tefa_trib_gruppo_tipo_f1_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f1_id
                                   when coalesce(tipo.tefa_trib_gruppo_tipo_f2_id,0)!=0 then tipo.tefa_trib_gruppo_tipo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 )
                                 )
 ) importo_tefa_netto
from siac_t_tefa_trib_importi tefa,
     siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_gruppo_tipo tipo
where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar||
' and   trib.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code
  and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and   gruppo.tefa_trib_gruppo_anno=
      ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::varchar||''''||
      '    when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar|| ' then ''='||annoPrec::varchar||''''||
      '    when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''' end )
  and   tipo.tefa_trib_gruppo_tipo_id=gruppo.tefa_trib_gruppo_tipo_id
  and   tefa.tefa_trib_tipo_record=''D''
  and   tefa.data_cancellazione is null
  and   tefa.validita_fine  is null
  and   trib.data_cancellazione is null
  and   trib.validita_fine is null
  and   gruppo.data_cancellazione is null
  and   gruppo.validita_fine is null
  and   tipo.data_cancellazione is null
  and   tipo.validita_fine is null
  and   r_gruppo.data_cancellazione is null
  and   r_gruppo.validita_fine  is null
group by tefa.tefa_trib_file_id,
	     tefa.tefa_trib_data_ripart,
         tefa.tefa_trib_data_bonifico,
         gruppo.tefa_trib_gruppo_tipo_id,
         tipo.tefa_trib_gruppo_tipo_f1_id,tipo.tefa_trib_gruppo_tipo_f2_id,tipo.tefa_trib_gruppo_tipo_f3_id,
	     ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::varchar||' then ''<='||annoPrecPrec::VARCHAR||''''||
         ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
         ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''' end )
order by 2,3,gruppo.tefa_trib_gruppo_tipo_id
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_tipo_id=query.tefa_trib_gruppo_tipo_id
order by query.data_ripartizione_dt,query.data_bonifico_dt,
         query.tefa_trib_gruppo_tipo_id;'::text;

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