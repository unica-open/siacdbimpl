/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- non serve questo scritpt
--drop type flussoElabMifRecType;

create type flussoElabMifRecType as
(
	 flussoElabMifId          integer,
	 flussoElabMifAttivo      boolean,
	 flussoElabMifDef         VARCHAR(200),
	 flussoElabMifElab        boolean,
	 flussoElabMifParam 	  VARCHAR(200),
	 flusso_elab_mif_campo    VARCHAR(50),
     flusso_elab_mif_tipo_id  integer,
	 flusso_elab_mif_ordine_elab integer,
	 flusso_elab_mif_code        VARCHAR(500)
);



/*select  (case when m.flusso_elab_mif_campo like '%siope%'
              then  'sipoe_'||replace(m.flusso_elab_mif_code,' ','_')
              else replace(m.flusso_elab_mif_code,' ','_') end)
        || ' varchar(500) default '''||m.flusso_elab_mif_campo||''' not null,'
from mif_d_flusso_elaborato m
where m.ente_proprietario_id=15
and ( m.flusso_elab_mif_calcolato=true or m.flusso_elab_mif_default is not null)
and m.flusso_elab_mif_campo is not null
and m.flusso_elab_mif_tabella is not null
order by m.flusso_elab_mif_ordine*/

select  (case when m.flusso_elab_mif_campo like '%siope%'
              then  'siope_'||replace(m.flusso_elab_mif_code,' ','_')
              when m.flusso_elab_mif_campo like '%class_codice_cge%'
              then 'class_'||replace(m.flusso_elab_mif_code,' ','_')
              when m.flusso_elab_mif_campo like '%dispe_voce_ecoe%'
              then 'dispe_'||replace(m.flusso_elab_mif_code,' ','_')
              else replace(m.flusso_elab_mif_code,' ','_') end)
        || ' varchar(500) default '''||m.flusso_elab_mif_campo||''' not null,'
from mif_d_flusso_elaborato m
where m.ente_proprietario_id=15
--and ( m.flusso_elab_mif_calcolato=true or m.flusso_elab_mif_default is not null)
--and m.flusso_elab_mif_campo is not null
--and m.flusso_elab_mif_tabella is not null
and m.flusso_elab_mif_elab=true
order by m.flusso_elab_mif_ordine

-- eseguire la select sopra riportata per ottenere i campi per creare la tabella
-- portare il risultato aggiungere nella create dopo i seguenti campi
-- ente_proprietario_id integer not null,
-- flusso_elab_mif_tipo integer not null,
-- lancia la create composta di seguito , risultato della select sopra eseguita
-- dopo avere creato lanciare la insert

drop table mif_d_flusso_elaborato_type;

create table mif_d_flusso_elaborato_type
(
flusso_elab_mif_tipo integer not null,
data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
ente_proprietario_id INTEGER NOT NULL,
login_operazione VARCHAR(200) NOT NULL,
codice_funzione varchar(500) default 'mif_ord_codice_funzione' not null,
numero_mandato varchar(500) default 'mif_ord_numero' not null,
data_mandato varchar(500) default 'mif_ord_data' not null,
importo_mandato varchar(500) default 'mif_ord_importo' not null,
flg_finanza_locale varchar(500) default 'mif_ord_flag_fin_loc' not null,
numero_documento varchar(500) default 'mif_ord_documento' not null,
tipo_contabilita_ente_pagante varchar(500) default 'mif_ord_bci_tipo_ente_pag' not null,
destinazione_ente_pagante varchar(500) default 'mif_ord_bci_dest_ente_pag' not null,
conto_tesoreria varchar(500) default 'mif_ord_bci_conto_tes' not null,
estremi_provvedimento_autorizzativo varchar(500) default 'mif_ord_estremi_attoamm' not null,
codice_ufficio_responsabile varchar(500) default 'mif_ord_codice_uff_resp' not null,
data_provvedimento_autorizzativo varchar(500) default 'mif_ord_data_attoamm' not null,
responsabile_provvedimento varchar(500) default 'mif_ord_resp_attoamm' not null,
ufficio_responsabile varchar(500) default 'mif_ord_uff_resp_attomm' not null,
codice_ABI_BT varchar(500) default 'mif_ord_codice_abi_bt' not null,
codice_ente varchar(500) default 'mif_ord_codice_ente' not null,
descrizione_ente varchar(500) default 'mif_ord_desc_ente' not null,
codice_ente_BT varchar(500) default 'mif_ord_codice_ente_bt' not null,
esercizio varchar(500) default 'mif_ord_anno_esercizio' not null,
identificativo_flusso varchar(500) default 'mif_ord_id_flusso_oil' not null,
data_ora_creazione_flusso varchar(500) default 'mif_ord_data_creazione_flusso' not null,
anno_flusso varchar(500) default 'mif_ord_anno_flusso' not null,
codice_struttura varchar(500) default 'mif_ord_codice_struttura' not null,
progressivo_mandato_struttura varchar(500) default 'mif_ord_progr_ord_struttura' not null,
ente_localita varchar(500) default 'mif_ord_ente_localita' not null,
ente_indirizzo varchar(500) default 'mif_ord_ente_indirizzo' not null,
codice_cge varchar(500) default 'mif_ord_codice_cge' not null,
descr_cge varchar(500) default 'mif_ord_descr_cge' not null,
Tipo_Contabilita varchar(500) default 'mif_ord_tipo_contabilita' not null,
codice_raggruppamento varchar(500) default 'mif_ord_codice_raggrup' not null,
progressivo_beneficiario varchar(500) default 'mif_ord_progr_benef' not null,
Impignorabili varchar(500) default 'mif_ord_progr_impignor' not null,
Destinazione varchar(500) default 'mif_ord_progr_dest' not null,
numero_conto_banca_italia_ente_ricevente varchar(500) default 'mif_ord_bci_conto' not null,
tipo_contabilita_ente_ricevente varchar(500) default 'mif_ord_bci_tipo_contabil' not null,
class_codice_cge varchar(500) default 'mif_ord_class_codice_cge' not null,
importo varchar(500) default 'mif_ord_class_importo' not null,
Codice_cup varchar(500) default 'mif_ord_class_codice_cup' not null,
Codice_cpv varchar(500) default 'mif_ord_class_codice_cpv' not null,
gestione_provvisoria varchar(500) default 'mif_ord_class_codice_gest_prov' not null,
frazionabile varchar(500) default 'mif_ord_class_codice_gest_fraz' not null,
codifica_bilancio varchar(500) default 'mif_ord_codifica_bilancio' not null,
numero_articolo varchar(500) default 'mif_ord_articolo' not null,
voce_economica varchar(500) default 'mif_ord_voce_eco' not null,
descrizione_codifica varchar(500) default 'mif_ord_desc_codifica' not null,
gestione varchar(500) default 'mif_ord_gestione' not null,
anno_residuo varchar(500) default 'mif_ord_anno_res' not null,
importo_bilancio varchar(500) default 'mif_ord_importo_bil' not null,
stanziamento varchar(500) default 'mif_ord_stanz' not null,
mandati_stanziamento varchar(500) default 'mif_ord_mandati_stanz' not null,
disponibilita_capitolo varchar(500) default 'mif_ord_disponibilita' not null,
previsione varchar(500) default 'mif_ord_prev' not null,
mandati_previsione varchar(500) default 'mif_ord_mandati_prev' not null,
disponibilita_cassa varchar(500) default 'mif_ord_disp_cassa' not null,
anagrafica_beneficiario varchar(500) default 'mif_ord_anag_benef' not null,
indirizzo_beneficiario varchar(500) default 'mif_ord_indir_benef' not null,
cap_beneficiario varchar(500) default 'mif_ord_cap_benef' not null,
localita_beneficiario varchar(500) default 'mif_ord_localita_benef' not null,
provincia_beneficiario varchar(500) default 'mif_ord_prov_benef' not null,
partita_iva_beneficiario varchar(500) default 'mif_ord_partiva_benef' not null,
codice_fiscale_beneficiario varchar(500) default 'mif_ord_codfisc_benef' not null,
beneficiario_quietanzante varchar(500) default 'mif_ord_benef_quiet' not null,
anagrafica_ben_quiet varchar(500) default 'mif_ord_anag_quiet' not null,
indirizzo_ben_quiet varchar(500) default 'mif_ord_indir_quiet' not null,
cap_ben_quiet varchar(500) default 'mif_ord_cap_quiet' not null,
localita_ben_quiet varchar(500) default 'mif_ord_localita_quiet' not null,
provincia_ben_quiet varchar(500) default 'mif_ord_prov_quiet' not null,
partita_iva_ben_quiet varchar(500) default 'mif_ord_partiva_quiet' not null,
codice_fiscale_ben_quiet varchar(500) default 'mif_ord_codfisc_quiet' not null,
delegato varchar(500) default 'mif_ord_delegato' not null,
anagrafica_delegato varchar(500) default 'mif_ord_anag_del' not null,
codice_fiscale_delegato varchar(500) default 'mif_ord_codfisc_del' not null,
cap_delegato varchar(500) default 'mif_ord_cap_del' not null,
localita_delegato varchar(500) default 'mif_ord_localita_del' not null,
provincia_delegato varchar(500) default 'mif_ord_prov_del' not null,
avviso varchar(500) default 'mif_ord_avviso' not null,
invio_avviso varchar(500) default 'mif_ord_invio_avviso' not null,
codice_fiscale_avviso varchar(500) default 'mif_ord_codfisc_avviso' not null,
piazzatura varchar(500) default 'mif_ord_piazzatura' not null,
abi_beneficiario varchar(500) default 'mif_ord_abi_benef' not null,
cab_beneficiario varchar(500) default 'mif_ord_cab_benef' not null,
numero_conto_corrente_beneficiario varchar(500) default 'mif_ord_cc_benef' not null,
caratteri_controllo varchar(500) default 'mif_ord_ctrl_benef' not null,
codice_cin varchar(500) default 'mif_ord_cin_benef' not null,
codice_paese varchar(500) default 'mif_ord_cod_paese_benef' not null,
denominazione_banca_destinataria varchar(500) default 'mif_ord_denom_banca_benef' not null,
conto_corrente_postale varchar(500) default 'mif_ord_cc_postale_benef' not null,
conto_corrente_estero varchar(500) default 'mif_ord_cc_benef_estero' not null,
codice_swift varchar(500) default 'mif_ord_swift_benef' not null,
coordinate_iban varchar(500) default 'mif_ord_iban_benef' not null,
codice_ente_beneficiario varchar(500) default 'mif_ord_cod_ente_benef' not null,
flag_pagamento_condizionato varchar(500) default 'mif_ord_fl_pagam_cond_benef' not null,
tipo_ritenuta varchar(500) default 'mif_ord_rit_tipo' not null,
importo_ritenuta varchar(500) default 'mif_ord_rit_importo' not null,
numero_reversale varchar(500) default 'mif_ord_rit_numero' not null,
progressivo_reversale varchar(500) default 'mif_ord_rit_progr_rev' not null,
progressivo_ritenuta varchar(500) default 'mif_ord_rit_progr_rit' not null,
esenzione varchar(500) default 'mif_ord_bollo_esenzione' not null,
carico_bollo varchar(500) default 'mif_ord_bollo_carico' not null,
causale_esenzione_bollo varchar(500) default 'mif_ordin_bollo_caus_esenzione' not null,
Importo_bollo varchar(500) default 'mif_ord_bollo_importo' not null,
carico_spese varchar(500) default 'mif_ord_bollo_carico_spe' not null,
importo_spese varchar(500) default 'mif_ord_bollo_importo_spe' not null,
carico_commissioni varchar(500) default 'mif_ord_commissioni_carico' not null,
importo_commissioni varchar(500) default 'mif_ord_commissioni_importo' not null,
tipo_pagamento varchar(500) default 'mif_ord_pagam_tipo' not null,
codice_pagamento varchar(500) default 'mif_ord_pagam_code' not null,
importo_beneficiario varchar(500) default 'mif_ord_pagam_importo' not null,
causale varchar(500) default 'mif_ord_pagam_causale' not null,
data_esecuzione_pagamento varchar(500) default 'mif_ord_pagam_data_esec' not null,
data_scadenza_pagamento varchar(500) default 'mif_ord_pagam_data_scad' not null,
flag_valuta_antergata varchar(500) default 'mif_ord_pagam_flag_val_ant' not null,
divisa_estera_conversione varchar(500) default 'mif_ord_pagam_divisa_estera' not null,
flag_assegno_circolare varchar(500) default 'mif_ord_pagam_flag_ass_circ' not null,
flag_vaglia_postale varchar(500) default 'mif_ord_pagam_flag_vaglia' not null,
lingua varchar(500) default 'mif_ord_lingua' not null,
riferimento_documento_esterno varchar(500) default 'mif_ord_rif_doc_esterno' not null,
informazioni_tesoriere varchar(500) default 'mif_ord_info_tesoriere' not null,
tipo_utenza varchar(500) default 'mif_ord_tipo_utenza' not null,
codifica_utenza varchar(500) default 'mif_ord_codice_ute' not null,
codice_generico varchar(500) default 'mif_ord_cod_generico' not null,
flag_copertura varchar(500) default 'mif_ord_flag_copertura' not null,
numero_ricevuta varchar(500) default 'mif_ord_ric_numero' not null,
importo_ricevuta varchar(500) default 'mif_ord_ric_importo' not null,
sostituzione_mandato varchar(500) default 'mif_ord_sost_mand' not null,
numero_mandato_collegato varchar(500) default 'mif_ord_num_ord_colleg' not null,
progressivo_mandato_collegato varchar(500) default 'mif_ord_progr_ord_colleg' not null,
esercizio_mandato_collegato varchar(500) default 'mif_ord_anno_ord_colleg' not null,
Capitolo_origine varchar(500) default 'mif_ord_dispe_cap_orig' not null,
Numero_articolo_capitolo varchar(500) default 'mif_ord_dispe_articolo' not null,
Descrizione_articolo_capitolo varchar(500) default 'mif_ord_dispe_descri_articolo' not null,
Somme_non_soggette varchar(500) default 'mif_ord_dispe_somme_non_sogg' not null,
Codice_tributo varchar(500) default 'mif_ord_dispe_cod_trib' not null,
Causale_770 varchar(500) default 'mif_ord_dispe_causale_770' not null,
Data_nascita_beneficiario varchar(500) default 'mif_ord_dispe_dtns_benef' not null,
Luogo_nascita_beneficiario varchar(500) default 'mif_ord_dispe_cmns_benef' not null,
Prov_nascita_beneficiario varchar(500) default 'mif_ordinativo_dispe_prns_benef' not null,
Note varchar(500) default 'mif_ord_dispe_note' not null,
Descrizione_tipo_pagamento varchar(500) default 'mif_ord_dispe_descri_pag' not null,
Descrizione_atto_autorizzativo varchar(500) default 'mif_ord_dispe_descri_attoamm' not null,
Capitolo_Peg varchar(500) default 'mif_ord_dispe_capitolo_peg' not null,
Vincoli_di_destinazione varchar(500) default 'mif_ord_dispe_vincoli_dest' not null,
Vincolato varchar(500) default 'mif_ord_dispe_vincolato' not null,
dispe_Voce_Economica varchar(500) default 'mif_ord_dispe_voce_eco' not null,
Numero_distinta_bilancio varchar(500) default 'mif_ord_dispe_distinta' not null,
Data_scadenza_interna varchar(500) default 'mif_ord_dispe_data_scad_interna' not null,
Numero_reversale_vincolata varchar(500) default 'mif_ord_dispe_rev_vinc' not null,
Allegato_Atto varchar(500) default 'mif_ord_dispe_atto_all' not null,
Liquidazione varchar(500) default 'mif_ord_dispe_liquidaz' not null,
Codice_Missione varchar(500) default 'mif_ord_missione' not null,
Codice_Programma varchar(500) default 'mif_ord_programma' not null,
Codice_Economico varchar(500) default 'mif_ord_conto_econ' not null,
Importo_Codice_Economico varchar(500) default 'mif_ord_importo_econ' not null,
Codice_Ue varchar(500) default 'mif_ord_cod_ue' not null,
Codice_Cofog varchar(500) default 'mif_ord_cofog_codice' not null,
Importo_Cofog varchar(500) default 'mif_ord_cofog_importo' not null,
InfSerMan_NumeroImpegno varchar(500) default 'mif_ord_numero_imp' not null,
InfSerMan_SubImpegno varchar(500) default 'mif_ord_numero_subimp' not null,
InfSerMan_CodiceOperatore varchar(500) default 'mif_ord_code_operatore' not null,
InfSerMan_NomeOperatore varchar(500) default 'mif_ord_nome_operatore' not null,
InfSerMan_Fattura_Descr varchar(500) default 'mif_ord_fatture' not null,
InfSerMan_DescrizioniEstesaCapitolo varchar(500) default 'mif_ord_descri_estesa_cap' not null,
InfSerMan_DescrCapitolo varchar(500) default 'mif_ord_descri_cap' not null,
InfSerMan_ProgSpesa varchar(500) default 'mif_ord_prog_cap' not null,
InfSerMan_TipoSpesa varchar(500) default 'mif_ord_tipo_cap' not null,
siope_codice_cge varchar(500) default 'mif_ord_siope_codice_cge' not null,
siope_descr_cge varchar(500) default 'mif_ord_siope_descri_cge' not null
);

 insert into mif_d_flusso_elaborato_type
 (ente_proprietario_id,flusso_elab_mif_tipo,login_operazione)
 (select tipo.ente_proprietario_id,tipo.flusso_elab_mif_tipo_id,'mif'
  from mif_d_flusso_elaborato_tipo tipo
  where tipo.ente_proprietario_id=15
  and   tipo.flusso_elab_mif_tipo_code='MANDMIF');

 select * from mif_d_flusso_elaborato_type