/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr105_tab_oneri_reversali (
  p_ente_prop_id integer,
  p_id_bil integer
)
RETURNS TABLE (
  ord_id integer,
  tipo_split_comm varchar,
  tipo_split_istituz varchar,
  tipo_split_reverse varchar,
  cartacont_pk integer,
  cartacont varchar,
  aliquota varchar,
  num_riscoss varchar,
  importo_iva_comm numeric,
  importo_iva_istituz numeric,
  importo_iva_reverse numeric
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoOneri record;
elencoReversali record;
ciclo integer;
sql_query VARCHAR;
ord_id_corr INTEGER;
var_attr_id integer;
flgOneriExist boolean;

/*
	SIAC-7014 18/09/2019.
Funzione utilizzata dal report BILR105 per estrarre gli oneri e le reversali
per ogni ordinativo.
*/

BEGIN

ord_id:=null;
tipo_split_comm:='';
tipo_split_istituz:='';
tipo_split_reverse:='';
cartacont_pk:=null;
cartacont:='';
aliquota:='';
num_riscoss:='';
importo_iva_comm :=0;
importo_iva_istituz :=0;
importo_iva_reverse :=0;

flgOneriExist:=false;
  
select attr_id into var_attr_id 
from siac_t_attr t_attr 
where  t_attr.attr_code = 'ALIQUOTA_SOGG' 
	and t_attr.ente_proprietario_id=p_ente_prop_id
   	and t_attr.data_cancellazione IS NULL
   	and t_attr.validita_fine IS NULL;
    
ord_id_corr:=0;
for elencoOneri in 
	SELECT d_onere_tipo.onere_tipo_code, d_onere.onere_code,
          d_onere.onere_desc, d_split_iva_tipo.sriva_tipo_code,
          t_cartacont.cartac_id, t_cartacont.cartac_numero,
          t_cartacont.cartac_data_scadenza,
          r_onere_attr.percentuale, t_ordinativo_ts.ord_id, t_ord.ord_numero
        from siac_t_ordinativo t_ord,
        	siac_t_ordinativo_ts t_ordinativo_ts,
            siac_r_subdoc_ordinativo_ts r_subdoc_ordinativo_ts,          
            siac_t_doc t_doc, 
            siac_t_subdoc t_subdoc
               left join siac_r_cartacont_det_subdoc r_cartacont_det_subdoc on (t_subdoc.subdoc_id=r_cartacont_det_subdoc.subdoc_id)
               left join siac_t_cartacont_det t_cartacont_det on (r_cartacont_det_subdoc.cartac_det_id=t_cartacont_det.cartac_det_id)
               left join siac_t_cartacont t_cartacont on (t_cartacont_det.cartac_id=t_cartacont.cartac_id),     
            siac_r_doc_onere r_doc_onere,
            siac_d_onere d_onere
            	left join siac_r_onere_attr r_onere_attr on 
                	(d_onere.onere_id = r_onere_attr.onere_id and r_onere_attr.data_cancellazione is null and r_onere_attr.attr_id=var_attr_id)
            ,siac_d_onere_tipo d_onere_tipo,
            siac_r_subdoc_splitreverse_iva_tipo r_subdoc_split_iva,
            siac_d_splitreverse_iva_tipo d_split_iva_tipo
        WHERE t_ord.ord_id= t_ordinativo_ts.ord_id
        	and r_subdoc_ordinativo_ts.ord_ts_id=t_ordinativo_ts.ord_ts_id
            AND t_doc.doc_id=t_subdoc.doc_id
            and t_subdoc.subdoc_id= r_subdoc_ordinativo_ts.subdoc_id
            AND r_doc_onere.doc_id=t_doc.doc_id
            AND d_onere.onere_id=r_doc_onere.onere_id
            AND d_onere_tipo.onere_tipo_id=d_onere.onere_tipo_id 
            AND r_subdoc_split_iva.subdoc_id=t_subdoc.subdoc_id     
            AND d_split_iva_tipo.sriva_tipo_id=r_subdoc_split_iva.sriva_tipo_id  
            and t_ordinativo_ts.ente_proprietario_id= p_ente_prop_id
            and t_ord.bil_id = p_id_bil
            AND d_onere_tipo.onere_tipo_code='SP' --SPLIT
            AND t_doc.data_cancellazione IS NULL
            AND t_subdoc.data_cancellazione IS NULL
            AND r_doc_onere.data_cancellazione IS NULL
            AND d_onere.data_cancellazione IS NULL
            AND d_onere_tipo.data_cancellazione IS NULL
            AND t_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_ordinativo_ts.data_cancellazione IS NULL
            AND r_subdoc_split_iva.data_cancellazione IS NULL
            AND d_split_iva_tipo.data_cancellazione IS NULL
       ORDER BY t_ordinativo_ts.ord_id, r_onere_attr.percentuale--t_cartacont.cartac_id
loop
flgOneriExist:=true; --esiste almeno un record di oneri
	if ord_id_corr <> 0 and ord_id_corr <> elencoOneri.ord_id then
    	--elaboro e restituisco i dati del record precedente 
      for elencoReversali in     
            select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                    t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                    t_ord_ts_det.ord_ts_det_importo importo_ord
            from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
                  siac_d_ordinativo_tipo d_ordinativo_tipo,
                  siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
                  siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo
                  where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                      AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                      AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                      AND t_ord_ts.ord_id=t_ordinativo.ord_id
                      AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                      AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                     AND d_ordinativo_tipo.ord_tipo_code ='I'
                     AND ts_det_tipo.ord_ts_det_tipo_code='A'
                        /* 09/03/2016:  estraggo solo le reversali di tipo SPR
                            DOVREBBE ESSERE SOLO 1 */
                AND d_relaz_tipo.relaz_tipo_code='SPR' 
                  /* ord_id_da contiene l'ID del mandato
                     ord_id_a contiene l'ID della reversale */
                AND r_ordinativo.ord_id_da = ord_id_corr--elencoMandati.ord_id
                and t_ordinativo.ente_proprietario_id=p_ente_prop_id
                AND d_relaz_tipo.data_cancellazione IS NULL
                AND t_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND r_ordinativo.data_cancellazione IS NULL
                AND t_ord_ts.data_cancellazione IS NULL
                AND t_ord_ts_det.data_cancellazione IS NULL
                AND ts_det_tipo.data_cancellazione IS NULL
          loop
        --raise notice 'numero mandato %, importo rev % ',elencoMandati.ord_numero, elencoReversali.importo_ord;             
              if num_riscoss = '' THEN
                  num_riscoss = elencoReversali.ord_numero ::VARCHAR;
              else
                  num_riscoss = num_riscoss||', '||elencoReversali.ord_numero ::VARCHAR;
              end if;    
          end loop;   
              /* 09/03/2016: l'importo dell'iva e' quello della reversale.
                        Il tipo di iva e' impostato in base al tipo onere del mandato
            estratto in precedenza */
          if tipo_split_comm <> '' THEN
            importo_iva_comm=elencoReversali.importo_ord;
          elsif tipo_split_istituz <> '' THEN
            importo_iva_istituz=elencoReversali.importo_ord;
          elsif tipo_split_reverse <> '' THEN
            importo_iva_reverse=elencoReversali.importo_ord;
          END IF;                 
                        
    	return next;
        
        ord_id:=null;
		tipo_split_comm:='';
        tipo_split_istituz:='';
        tipo_split_reverse:='';
        cartacont_pk:=null;
        cartacont:='';
        aliquota:='';
        num_riscoss:='';
        importo_iva_comm :=0;
        importo_iva_istituz :=0;
        importo_iva_reverse :=0;
    end if;
    
    ord_id:=elencoOneri.ord_id;
    ord_id_corr:=elencoOneri.ord_id;
    
            --SPLIT COMMERCIALE
    IF elencoOneri.sriva_tipo_code =  'SC' THEN
        tipo_split_comm=elencoOneri.sriva_tipo_code; 
        --SPLIT ISTITUZIONALE
    ELSIF elencoOneri.sriva_tipo_code = 'SI' THEN
        tipo_split_istituz=elencoOneri.sriva_tipo_code;
        --REVERSE CHANGE
    ELSIF elencoOneri.sriva_tipo_code = 'RC' THEN
        tipo_split_reverse=elencoOneri.sriva_tipo_code;
    END IF;
    if elencoOneri.cartac_id is not null and cartacont_pk != elencoOneri.cartac_id then
        cartacont_pk := elencoOneri.cartac_id;
        if cartacont = '' then
            cartacont=elencoOneri.cartac_numero||' - '||to_char(elencoOneri.cartac_data_scadenza,'dd/MM/yyyy');
        else
            cartacont=cartacont||', '||elencoOneri.cartac_numero||' - '||to_char(elencoOneri.cartac_data_scadenza,'dd/MM/yyyy');
        end if;
    end if;
    IF elencoOneri.percentuale is not null and aliquota not like '%'||elencoOneri.percentuale||'%' then
        if aliquota = '' then
            aliquota=aliquota||elencoOneri.percentuale ;
        else
            aliquota=aliquota||', '||elencoOneri.percentuale;
        end if;
    end if;
	
      
end loop;


--29/10/2019 SIAC-7149
-- l'ultimo record non veniva resituito nel resultset, devo elaborarlo.
if flgOneriExist = true then
  --devo gestire anche l'ultimo record
  for elencoReversali in     
        select t_ordinativo.ord_numero, t_ordinativo.ord_emissione_data,
                t_ordinativo.ord_id,d_relaz_tipo.relaz_tipo_code,
                t_ord_ts_det.ord_ts_det_importo importo_ord
        from  siac_r_ordinativo r_ordinativo, siac_t_ordinativo t_ordinativo,
              siac_d_ordinativo_tipo d_ordinativo_tipo,
              siac_d_relaz_tipo d_relaz_tipo, siac_t_ordinativo_ts t_ord_ts,
              siac_t_ordinativo_ts_det t_ord_ts_det, siac_d_ordinativo_ts_det_tipo ts_det_tipo
              where t_ordinativo.ord_id=r_ordinativo.ord_id_a
                  AND d_ordinativo_tipo.ord_tipo_id=t_ordinativo.ord_tipo_id
                  AND d_relaz_tipo.relaz_tipo_id=r_ordinativo.relaz_tipo_id
                  AND t_ord_ts.ord_id=t_ordinativo.ord_id
                  AND t_ord_ts_det.ord_ts_id=t_ord_ts.ord_ts_id
                  AND ts_det_tipo.ord_ts_det_tipo_id=t_ord_ts_det.ord_ts_det_tipo_id
                 AND d_ordinativo_tipo.ord_tipo_code ='I'
                 AND ts_det_tipo.ord_ts_det_tipo_code='A'
                    /* 09/03/2016:  estraggo solo le reversali di tipo SPR
                        DOVREBBE ESSERE SOLO 1 */
            AND d_relaz_tipo.relaz_tipo_code='SPR' 
              /* ord_id_da contiene l'ID del mandato
                 ord_id_a contiene l'ID della reversale */
            AND r_ordinativo.ord_id_da = ord_id_corr--elencoMandati.ord_id
            and t_ordinativo.ente_proprietario_id=p_ente_prop_id
            AND d_relaz_tipo.data_cancellazione IS NULL
            AND t_ordinativo.data_cancellazione IS NULL
            AND r_ordinativo.data_cancellazione IS NULL
            AND r_ordinativo.data_cancellazione IS NULL
            AND t_ord_ts.data_cancellazione IS NULL
            AND t_ord_ts_det.data_cancellazione IS NULL
            AND ts_det_tipo.data_cancellazione IS NULL
      loop
    --raise notice 'numero mandato %, importo rev % ',elencoMandati.ord_numero, elencoReversali.importo_ord;             
          if num_riscoss = '' THEN
              num_riscoss = elencoReversali.ord_numero ::VARCHAR;
          else
              num_riscoss = num_riscoss||', '||elencoReversali.ord_numero ::VARCHAR;
          end if;    
      end loop;   
          /* 09/03/2016: l'importo dell'iva e' quello della reversale.
                    Il tipo di iva e' impostato in base al tipo onere del mandato
        estratto in precedenza */
      if tipo_split_comm <> '' THEN
        importo_iva_comm=elencoReversali.importo_ord;
      elsif tipo_split_istituz <> '' THEN
        importo_iva_istituz=elencoReversali.importo_ord;
      elsif tipo_split_reverse <> '' THEN
        importo_iva_reverse=elencoReversali.importo_ord;
      END IF;                 
                          
    return next;
end if;
  
exception
    when no_data_found THEN
        raise notice 'nessun mandato trovato' ;
        return;
    when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;