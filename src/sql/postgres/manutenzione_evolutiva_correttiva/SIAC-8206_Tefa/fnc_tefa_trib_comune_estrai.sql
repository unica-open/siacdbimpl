/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


drop FUNCTION if exists siac.fnc_tefa_trib_comune_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)

CREATE OR REPLACE FUNCTION siac.fnc_tefa_trib_comune_estrai(p_ente_proprietario_id integer, p_tefa_trib_upload_id integer, p_tefa_trib_comune_anno integer)
 RETURNS TABLE(codice_comune character varying, raggruppamento_codice_tributo character varying, importo_a_debito_versato numeric, importo_a_credito_compensato numeric, anno_di_riferimento_str character varying, ente character varying, tipologia character varying, importo_tefa_lordo numeric, importo_credito numeric, importo_comm numeric, importo_tefa_netto numeric)
 LANGUAGE plpgsql
AS $function$
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
       query.tipologia::varchar,
       query.importo_tefa_lordo::numeric,
       query.importo_credito::numeric,
       query.importo_comm::numeric,
       query.importo_tefa_netto::numeric
 from
 (

select
    tefa.tefa_trib_file_id,
    tefa.tefa_trib_comune_code codice_comune,
    gruppo.tefa_trib_gruppo_id ,
    sum(tefa.tefa_trib_importo_versato_deb) importo_a_debito_versato,
    sum(tefa.tefa_trib_importo_compensato_cred)    importo_a_credito_compensato,
   ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ) anno_di_riferimento_str,
   com.tefa_trib_comune_cat_desc ente,
   tipo.tefa_trib_tipologia_desc tipologia,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_versato_deb)
                                 ) importo_tefa_lordo,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),
                                  sum(tefa.tefa_trib_importo_compensato_cred)
                                  ) importo_credito,
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),
                                  fnc_tefa_trib_calcolo_formule
                                  (
                                  (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                   ),
                                   sum(tefa.tefa_trib_importo_versato_deb))
                                )  importo_comm,
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb)) -
   fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_compensato_cred)) -
   fnc_tefa_trib_calcolo_formule((case
                                   when coalesce(gruppo.tefa_trib_gruppo_f3_id,0)!=0 then gruppo.tefa_trib_gruppo_f3_id
                                   else null
                                   end
                                  ),fnc_tefa_trib_calcolo_formule( (case
     							   when coalesce(gruppo.tefa_trib_gruppo_f1_id,0)!=0 then gruppo.tefa_trib_gruppo_f1_id
                                   when coalesce(gruppo.tefa_trib_gruppo_f2_id,0)!=0 then gruppo.tefa_trib_gruppo_f2_id
                                   else null
                                   end
                                  ),sum(tefa.tefa_trib_importo_versato_deb) )
                                  ) importo_tefa_netto
from siac_t_tefa_trib_importi tefa,siac_d_tefa_trib_comune com,
     siac_d_tefa_tributo trib,siac_r_tefa_tributo_gruppo r_gruppo,
     siac_d_tefa_trib_gruppo gruppo,siac_d_tefa_trib_tipologia tipo
where tefa.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   tefa.tefa_trib_file_id='||p_tefa_trib_upload_id::varchar||
' and   com.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   com.tefa_trib_comune_code=tefa.tefa_trib_comune_code
  and   trib.ente_proprietario_id='||p_ente_proprietario_id::varchar||
' and   trib.tefa_trib_code=tefa.tefa_trib_tributo_code
  and   r_gruppo.tefa_trib_id=trib.tefa_trib_id
  and   gruppo.tefa_trib_gruppo_id=r_gruppo.tefa_trib_gruppo_id
  and   gruppo.tefa_trib_gruppo_anno=
       ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::varchar||' then ''<='||annoPrecPrec::varchar||''''||
       '   when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''='||annoPrec::varchar||''''||
       '   when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::VARCHAR||' then ''>='||p_tefa_trib_comune_anno::VARCHAR||''' end )
  and   tipo.tefa_trib_tipologia_id=gruppo.tefa_trib_tipologia_id
  and   tefa.tefa_trib_tipo_record=''D''
  and   tefa.data_cancellazione is null
  and   tefa.validita_fine is null
  and   r_gruppo.data_cancellazione is null
  and   r_gruppo.validita_fine is null
  group by tefa.tefa_trib_file_id,
	     tefa.tefa_trib_comune_code,
         gruppo.tefa_trib_gruppo_id,
         gruppo.tefa_trib_gruppo_f1_id,gruppo.tefa_trib_gruppo_f2_id,gruppo.tefa_trib_gruppo_f3_id,
		 ( case when tefa.tefa_trib_anno_rif::INTEGER<='||annoPrecPrec::VARCHAR||' then ''<='||annoPrecPrec::VARCHAR||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER='||annoPrec::varchar||' then ''''''='||annoPrec::varchar||''''||
          ' when tefa.tefa_trib_anno_rif::INTEGER>='||p_tefa_trib_comune_anno::varchar||' then ''>='||p_tefa_trib_comune_anno::varchar||''''||
          ' end ),
         com.tefa_trib_comune_cat_desc,
         tipo.tefa_trib_tipologia_desc
order by 2,3
) query,siac_t_tefa_trib_gruppo_upload upd
where upd.tefa_trib_file_id=query.tefa_trib_file_id
and   upd.tefa_trib_gruppo_id=query.tefa_trib_gruppo_id
order by 1,query.tefa_trib_gruppo_id;'::text;

raise notice 'sql_query=%',sql_query::varchar;
return query execute sql_query;

exception
	when no_data_found THEN
    raise notice 'Nessun dato trovato.';
	when others  THEN
 	RAISE EXCEPTION ' Errore DB % %',SQLSTATE,substring(SQLERRM from 1 for 1000);
    return;
END;
$function$
;
