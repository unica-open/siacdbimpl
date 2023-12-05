/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr144_tab_modpag (
  p_ente_prop_id integer
)
RETURNS TABLE (
  ord_id integer,
  banca_iban varchar,
  desc_mod_pagamento varchar,
  banca_cc_posta varchar,
  banca_cin varchar,
  banca_abi varchar,
  banca_cab varchar,
  banca_cc varchar,
  banca_cc_estero varchar,
  banca_bic varchar,
  banca_cc_bitalia varchar,
  quietanziante varchar,
  quietanziante_codice_fiscale varchar,
  contocorrente_intestazione varchar,
  banca_denominazione varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoModPag record;

BEGIN

ord_id:=null;

banca_iban:='';
desc_mod_pagamento:='';
banca_cc_posta:='';
banca_cin:='';
banca_abi:='';
banca_cab:='';
banca_cc:='';
banca_cc_estero:='';
banca_bic:='';
banca_cc_bitalia:='';
quietanziante:='';
quietanziante_codice_fiscale:='';
contocorrente_intestazione:='';
banca_denominazione:='';

RTN_MESSAGGIO:='Funzione di lettura dei mandati di pagamento';

for elencoModPag in                             
	select r_ord_modpag.ord_id,
    	        -- se la modalita' di pagamento collegata all'ordinativo e' nulla (cessione di incasso)
        -- prendo quella collegata al soggetto a cui e' stata ceduta
        case when t_modpag.modpag_id is not null then COALESCE(t_modpag.iban,'')
        	else COALESCE(t_modpag1.iban,'') end iban_banca,
        case when t_modpag.modpag_id is not null then COALESCE(d_accredito_tipo.accredito_tipo_code,'')
        	else  COALESCE(d_accredito_tipo1.accredito_tipo_code,'') end code_pagamento,
        case when t_modpag.modpag_id is not null then COALESCE(d_accredito_tipo.accredito_tipo_desc,'')
        	else  COALESCE(d_accredito_tipo1.accredito_tipo_desc,'') end desc_pagamento,
        case when t_modpag.modpag_id is not null then COALESCE(t_modpag.quietanziante,'')
        	else  COALESCE(t_modpag1.quietanziante,'') end quietanziante,
        case when t_modpag.modpag_id is not null then COALESCE(t_modpag.quietanziante_codice_fiscale,'')
        	else  COALESCE(t_modpag1.quietanziante_codice_fiscale,'') end quietanziante_codice_fiscale,
        case when t_modpag.modpag_id is not null then COALESCE(t_modpag.contocorrente,'')
        	else  COALESCE(t_modpag1.contocorrente,'') end contocorrente,
        case when t_modpag.modpag_id is not null then COALESCE(t_modpag.contocorrente_intestazione,'')
        	else  COALESCE(t_modpag1.contocorrente_intestazione,'') end contocorrente_intestazione,            
		case when t_modpag.modpag_id is not null then COALESCE(t_modpag.banca_denominazione,'')
        	else  COALESCE(t_modpag1.banca_denominazione,'') end banca_denominazione,      
        case when t_modpag.modpag_id is not null then COALESCE(t_modpag.bic,'')
        	else  COALESCE(t_modpag1.bic,'') end bic,
        t_modpag.modpag_id, t_modpag1.modpag_id modpag_id1
          from siac_r_ordinativo_modpag r_ord_modpag
                  LEFT JOIN siac_t_modpag t_modpag 
                      ON (t_modpag.modpag_id=r_ord_modpag.modpag_id
                          AND t_modpag.data_cancellazione IS NULL)
                  LEFT JOIN siac_d_accredito_tipo d_accredito_tipo 
                      ON (d_accredito_tipo.accredito_tipo_id=t_modpag.accredito_tipo_id
                          AND d_accredito_tipo.data_cancellazione IS NULL) 
                  /* in caso di cessione di incasso su siac_r_ordinativo_modpag
                  non e' valorizzata la modalita' di pagamento.
                  Devo cercare quella del soggetto a cui e' stato ceduto l'incasso. */
                  LEFT JOIN  siac_r_soggrel_modpag r_sogg_modpag
                      ON (r_ord_modpag.soggetto_relaz_id=r_sogg_modpag.soggetto_relaz_id
                          AND r_sogg_modpag.data_cancellazione IS NULL)
                  LEFT JOIN siac_t_modpag t_modpag1 
                      ON (t_modpag1.modpag_id=r_sogg_modpag.modpag_id
                          AND t_modpag1.data_cancellazione IS NULL)
                  LEFT JOIN siac_d_accredito_tipo d_accredito_tipo1 
                      ON (d_accredito_tipo1.accredito_tipo_id=t_modpag1.accredito_tipo_id
                          AND d_accredito_tipo1.data_cancellazione IS NULL)
          where r_ord_modpag.ente_proprietario_id=p_ente_prop_id 
          and r_ord_modpag.data_cancellazione IS NULL
          order by ord_id             
    loop
     if ord_id is not null and 
            ord_id <> elencoModPag.ord_id THEN
                                           
            return next;
            
            banca_iban:='';
            desc_mod_pagamento:='';
            banca_cc_posta:='';
            banca_cin:='';
            banca_abi:='';
            banca_cab:='';
            banca_cc:='';
            banca_cc_estero:='';
            banca_bic:='';
            banca_cc_bitalia:='';
            quietanziante:='';
            quietanziante_codice_fiscale:='';
            contocorrente_intestazione:='';
            banca_denominazione:='';
      end if;
      
	  ord_id=elencoModPag.ord_id;
      
      banca_iban:= elencoModPag.iban_banca;
      desc_mod_pagamento:= elencoModPag.desc_pagamento;
      quietanziante:=elencoModPag.quietanziante;
	  quietanziante_codice_fiscale:=elencoModPag.quietanziante_codice_fiscale;
  	  contocorrente_intestazione:=elencoModPag.contocorrente_intestazione;
	  banca_denominazione:=elencoModPag.banca_denominazione;
      
		IF elencoModPag.code_pagamento = 'CCP' THEN --Conto Corrente Postale
        		/* SIAC-6017: corretto il nome del dataset */
        	banca_cc_posta = elencoModPag.contocorrente;
        elsif elencoModPag.code_pagamento in ('CB','CD') THEN -- BONIFICO o CC BANCARIO DEDICATO
        	IF upper(substr(banca_iban,1,2)) ='IT' THEN --IBAN ITALIA
            	banca_cin=substr(banca_iban,5,1);
                banca_abi=substr(banca_iban,6,5);
                banca_cab=substr(banca_iban,11,5);
                banca_cc=substr(banca_iban,16,12);
            else
            	banca_cc_estero=elencoModPag.contocorrente;
                banca_bic=elencoModPag.bic;
            END IF;
        elsif elencoModPag.code_pagamento = 'CBI' THEN -- BONIFICO Banca d'Italia
        	banca_cc_bitalia=elencoModPag.contocorrente;
        END IF;
                    
    end loop;
        
        --raise notice 'cod_v_livello1 = %', replace(substr(cod_v_livello,2, char_length(cod_v_livello)-1),'.','');       
        
    return next;


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