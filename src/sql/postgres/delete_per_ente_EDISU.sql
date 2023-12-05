/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- elenco doc
delete from siac_r_atto_allegato_elenco_doc r where r.ente_proprietario_id=13;
delete from siac_r_elenco_doc_stato r where r.ente_proprietario_id=13;
delete from siac_r_elenco_doc_subdoc r where r.ente_proprietario_id=13;
delete from siac_t_elenco_doc t where t.ente_proprietario_id=13;
-- atto atto allegato
delete from siac_r_atto_allegato_elenco_doc r where r.ente_proprietario_id=13;
delete from siac_r_atto_allegato_stato r where r.ente_proprietario_id=13;
delete from siac_r_atto_allegato_sog r where r.ente_proprietario_id=13;
delete from siac_t_atto_allegato t where t.ente_proprietario_id=13;
-- subdoc
delete from siac_r_subdoc_atto_amm r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_movgest_ts r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_liquidazione r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_ordinativo_ts r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_sog r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_modpag r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_attr r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_class r where r.ente_proprietario_id=13;
delete from siac_r_cartacont_det_subdoc where ente_proprietario_id = 13;
delete from siac_r_mutuo_voce_subdoc where ente_proprietario_id = 13;
delete from siac_r_predoc_subdoc where ente_proprietario_id = 13;
delete from siac_r_subdoc_prov_cassa where ente_proprietario_id = 13;
delete from siac_r_subdoc_splitreverse_iva_tipo where ente_proprietario_id = 13;
delete from siac_r_subdoc_subdoc_iva where ente_proprietario_id = 13;
delete from siac_t_registro_pcc where ente_proprietario_id = 13;
delete from siac_t_subdoc t where t.ente_proprietario_id=13;
-- doc
delete from siac_t_registrounico_doc r where r.ente_proprietario_id=13;
--delete from siac_r_doc r using siac_t_doc t where t.ente_proprietario_id=13 and r.ente_proprietario_id=13;
delete from siac_r_doc r where r.ente_proprietario_id=13;
delete from siac_r_doc_stato r where r.ente_proprietario_id=13;
delete from siac_r_doc_attr r where r.ente_proprietario_id=13;
delete from siac_r_doc_class r where r.ente_proprietario_id=13;
delete from siac_r_doc_sog r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_iva_attr where ente_proprietario_id=13;
delete from siac_r_subdoc_iva_stato where ente_proprietario_id=13;
delete from siac_r_ivamov where ente_proprietario_id=13;

--delete from siac_t_subdoc_iva where ente_proprietario_id = 13;
--delete from siac_r_doc_iva where ente_proprietario_id=13;
delete from siac_r_doc_onere where ente_proprietario_id=13;
delete from siac_r_doc_ordine where ente_proprietario_id=13;
delete from siac_r_doc_sirfel where ente_proprietario_id=13;
--delete from siac_r_richiesta_econ_doc where ente_proprietario_id=13;
delete from siac_t_registro_pcc where ente_proprietario_id=13;
delete from siac_t_subdoc_num where ente_proprietario_id=13;
--delete from siac_t_doc t where t.ente_proprietario_id=13;
-------------liquidazioni (giuliano) -----------------
delete from siac_r_liquidazione_atto_amm r where r.ente_proprietario_id=13;
delete from siac_r_liquidazione_attr r where r.ente_proprietario_id=13;
delete from siac_r_liquidazione_class r where r.ente_proprietario_id=13;
delete from siac_r_liquidazione_movgest r where r.ente_proprietario_id=13;
delete from siac_r_liquidazione_ord r where r.ente_proprietario_id=13;
delete from siac_r_liquidazione_soggetto r where r.ente_proprietario_id=13;
delete from siac_r_liquidazione_stato r where r.ente_proprietario_id=13;
delete from siac_r_mutuo_voce_liquidazione r where r.ente_proprietario_id=13;
delete from siac_r_subdoc_liquidazione r where r.ente_proprietario_id=13;
delete from siac_t_liquidazione where ente_proprietario_id=13;
--------------subdoc (giuliano)----------------
/*
delete from siac_r_cartacont_det_subdoc where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_elenco_doc_subdoc where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
delete from siac_r_mutuo_voce_subdoc where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
delete from siac_r_predoc_subdoc where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_atto_amm where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_attr where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_class where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_liquidazione where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_modpag where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_movgest_ts where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_ordinativo_ts where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
delete from siac_r_subdoc_prov_cassa where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_r_subdoc_sog where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
delete from siac_r_subdoc_splitreverse_iva_tipo where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
delete from siac_r_subdoc_subdoc_iva where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
delete from siac_t_registro_pcc where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
--delete from siac_t_subdoc where subdoc_id in (select subdoc_id from siac_t_subdoc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13));
*/
-------------doc (giuliano)----------------
/*
--delete from siac_r_doc_attr where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
--delete from siac_r_doc_class where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
delete from siac_r_subdoc_iva_attr where ente_proprietario_id=13;
delete from siac_r_subdoc_iva_stato where ente_proprietario_id=13;
delete from siac_r_ivamov where ente_proprietario_id=13;
delete from siac_t_subdoc_iva where ente_proprietario_id = 13;
delete from siac_r_doc_iva where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
delete from siac_r_doc_onere where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
delete from siac_r_doc_ordine where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
delete from siac_r_doc_sirfel where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
--delete from siac_r_doc_sog where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
--delete from siac_r_doc_stato where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
delete from siac_r_richiesta_econ_doc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
delete from siac_t_registro_pcc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
--delete from siac_t_registrounico_doc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
delete from siac_t_subdoc_num where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
--delete from siac_t_doc where doc_id in (select doc_id from siac_t_doc a where a.ente_proprietario_id=13);
*/
-------------- movgest---------------
-- capire quando cancellare la siac_r_modifica_stato
-- siac_r_variazione_stato

delete from siac_r_movgest_ts_sogclasse_mod where ente_proprietario_id=13; --(controllare tabelle che referenzia)
delete from siac_r_movgest_ts_sogclasse r where r.ente_proprietario_id=13;
delete from siac_r_movgest_ts_sog_mod r where r.ente_proprietario_id=13;
delete from siac_r_movgest_ts_sog r where r.ente_proprietario_id=13;
delete from siac_r_movgest_ts_programma r where r.ente_proprietario_id=13;
    --delete from siac_t_programma where ente_proprietario_id=13;--new ?? DA CANCELLARE ??? NO, VIVE ANCHE SENZA MOVGEST ASSOCIATO
delete from siac_r_movgest_ts_attr where ente_proprietario_id=13;
delete from siac_r_movgest_ts_stato where ente_proprietario_id=13;
delete from siac_t_movgest_ts_det_mod where ente_proprietario_id=13;
delete from siac_t_movgest_ts_det r where r.ente_proprietario_id=13;
delete from siac_r_movgest_ts_atto_amm r where r.ente_proprietario_id=13;
delete from siac_r_atto_amm_class where ente_proprietario_id=13;
delete from siac_r_atto_amm_stato r where r.ente_proprietario_id=13;
delete from SIAC_R_PROGRAMMA_ATTO_AMM where ente_proprietario_id=13;
--delete from SIAC_R_MODIFICA_STATO where ente_proprietario_id=13;
--delete from siac_t_modifica t where t.ente_proprietario_id=13;
delete from SIAC_R_LIQUIDAZIONE_ATTO_AMM where ente_proprietario_id=13;
delete from siac_r_ordinativo_atto_amm r where r.ente_proprietario_id=13;
--delete from SIAC_R_SUBDOC_ATTO_AMM r where r.ente_proprietario_id=13; cancellato prima
--delete from SIAC_R_ATTO_ALLEGATO_ELENCO_DOC where r.ente_proprietario_id=13; cancellato prima
--delete from SIAC_R_ATTO_ALLEGATO_STATO where ente_proprietario_id=13;cancellato prima
--delete from siac_t_atto_allegato t where t.ente_proprietario_id=13;cancellato prima
delete from SIAC_R_MUTUO_ATTO_AMM r where r.ente_proprietario_id=13;
    delete from siac_r_cartacont_estera_attr where ente_proprietario_id=13;--new
delete from siac_t_cartacont_estera where ente_proprietario_id=13;
delete from siac_r_cartacont_stato where ente_proprietario_id=13;
delete from siac_r_cartacont_det_attr where ente_proprietario_id=13;
delete from siac_r_cartacont_det_modpag where ente_proprietario_id=13;
--delete from siac_r_cartacont_det_movgest where ente_proprietario_id=13; tabella cancellata
delete from siac_r_cartacont_det_soggetto where ente_proprietario_id=13;
delete from siac_r_cartacont_det_subdoc where ente_proprietario_id=13;
    delete from siac_r_mutuo_voce_cartacont_det where ente_proprietario_id=13;--new
delete from SIAC_R_CARTACONT_DET_MOVGEST_TS r where r.ente_proprietario_id=13;
delete from siac_t_cartacont_det where ente_proprietario_id=13;
delete from siac_r_cartacont_attr where ente_proprietario_id=13;
delete from siac_t_cartacont where ente_proprietario_id=13;
delete from SIAC_R_CAUSALE_MOVGEST_TS r where r.ente_proprietario_id=13;
delete from SIAC_R_SUBDOC_MOVGEST_TS r where r.ente_proprietario_id=13;
delete from SIAC_R_MOVGEST_TS where ente_proprietario_id=13;
-- predoc
    delete from siac_r_mutuo_voce_predoc where ente_proprietario_id=13;--new
delete from siac_r_predoc_atto_amm where ente_proprietario_id=13;
    delete from siac_r_predoc_bil_elem where ente_proprietario_id=13;--new
    delete from siac_r_predoc_causale where ente_proprietario_id=13;--new
    delete from siac_r_predoc_class where ente_proprietario_id=13;--new
    delete from siac_r_predoc_modpag where ente_proprietario_id=13;--new
delete from siac_r_predoc_movgest_ts where ente_proprietario_id=13;
    delete from siac_r_predoc_prov_cassa where ente_proprietario_id=13;--new
    delete from siac_r_predoc_sog where ente_proprietario_id=13;--new
    delete from siac_r_predoc_stato where ente_proprietario_id=13;--new
    delete from siac_r_predoc_subdoc where ente_proprietario_id=13;--new
    delete from siac_t_predoc_anagr where ente_proprietario_id=13;--new
    delete from siac_t_predoc_num where ente_proprietario_id=13;--new
    delete from siac_t_predoc where ente_proprietario_id=13;--new
--delete from SIAC_R_LIQUIDAZIONE_MOVGEST r where r.ente_proprietario_id=13; cancellato prima
delete from SIAC_R_ORDINATIVO_TS_MOVGEST_TS r where r.ente_proprietario_id=13;
    delete from siac_r_doc_onere_ordinativo_ts where ente_proprietario_id=13;--new
    delete from siac_r_liquidazione_ord where ente_proprietario_id=13;--new, cancellato anche sopra
    delete from siac_r_subdoc_ordinativo_ts where ente_proprietario_id=13;--new, cancellato anche sopra
    delete from siac_t_ordinativo_ts_det where ente_proprietario_id=13;--new
    delete from siac_t_ordinativo_ts where ente_proprietario_id=13;--new
    delete from siac_r_ordinativo where ente_proprietario_id=13;--new
--    delete from siac_r_ordinativo_atto_amm where ente_proprietario_id=13;cancellato prima
    delete from siac_r_ordinativo_attr where ente_proprietario_id=13;--new
    delete from siac_r_ordinativo_bil_elem where ente_proprietario_id=13;--new
    delete from siac_r_ordinativo_class where ente_proprietario_id=13;--new
    delete from siac_r_ordinativo_modpag where ente_proprietario_id=13;--new
    delete from siac_r_ordinativo_prov_cassa where ente_proprietario_id=13;--new
    delete from siac_r_ordinativo_soggetto where ente_proprietario_id=13;--new
    delete from siac_r_ordinativo_stato where ente_proprietario_id=13;--new
    delete from siac_t_ordinativo where ente_proprietario_id=13;--new

delete from SIAC_R_RICHIESTA_ECON_MOVGEST r where r.ente_proprietario_id=13;
    -- siac_t_richiesta_econ
    delete from siac_r_richiesta_econ_class where ente_proprietario_id=13;--new
--    delete from siac_r_richiesta_econ_doc where a.ente_proprietario_id=13;--new TABELLA CANCELLATA
    delete from siac_r_richiesta_econ_movgest where ente_proprietario_id=13;--new
    delete from siac_r_richiesta_econ_sog where ente_proprietario_id=13;--new
    delete from siac_r_richiesta_econ_stato where ente_proprietario_id=13;--new
    delete from siac_t_giustificativo_det where ente_proprietario_id=13;--new
    delete from siac_r_giustificativo_movgest where ente_proprietario_id = 13;--new
    delete from siac_r_giustificativo_stato where ente_proprietario_id = 13;--new
    delete from siac_t_giustificativo_det where ente_proprietario_id = 13;--new
    delete from siac_r_movimento_modpag where ente_proprietario_id = 13;--new
    delete from siac_r_movimento_stampa where ente_proprietario_id = 13;--new
    delete from siac_t_movimento where ente_proprietario_id=13;--new
    delete from siac_t_giustificativo where ente_proprietario_id=13;--new
    delete from siac_t_richiesta_econ_sospesa where ente_proprietario_id=13;--new
    delete from siac_t_richiesta_econ where ente_proprietario_id=13;--new
    delete from siac_r_trasf_miss_trasporto where ente_proprietario_id=13;--new
    delete from siac_t_trasf_miss where ente_proprietario_id=13;--new
    delete from siac_t_richiesta_econ where ente_proprietario_id=13;--new
delete from siac_r_mutuo_voce_movgest r where r.ente_proprietario_id=13;
delete from siac_r_mutuo_voce_liquidazione r where r.ente_proprietario_id=13;
    --delete from siac_r_mutuo_voce_predoc where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_mutuo_voce_subdoc where ente_proprietario_id = 13;--cancellato prima
    delete from siac_t_mutuo_voce_var where ente_proprietario_id = 13;--new
delete from siac_t_mutuo_voce t where t.ente_proprietario_id=13;
delete from siac_r_mutuo_atto_amm r where r.ente_proprietario_id=13;
delete from siac_r_mutuo_soggetto r where r.ente_proprietario_id=13;
delete from siac_r_mutuo_stato r where r.ente_proprietario_id=13;
delete from siac_t_mutuo t where t.ente_proprietario_id=13;
    -- atti amm
    --delete from siac_r_atto_amm_class where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_atto_amm_stato where ente_proprietario_id = 13;--cancellato prima
    delete from siac_r_bil_stato_op_atto_amm where ente_proprietario_id = 13;--new
    delete from siac_r_causale_atto_amm where ente_proprietario_id = 13;--new
    --delete from siac_r_liquidazione_atto_amm where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_movgest_ts_atto_amm where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_mutuo_atto_amm where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_ordinativo_atto_amm where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_predoc_atto_amm where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_programma_atto_amm where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_r_subdoc_atto_amm where ente_proprietario_id = 13;--cancellato prima
    delete from siac_t_bil_elem_det_var where ente_proprietario_id = 13;
    delete from siac_r_variazione_stato where ente_proprietario_id = 13;--new
    delete from siac_t_atto_allegato_bkp where ente_proprietario_id = 13;--new
    --delete from siac_t_atto_allegato where ente_proprietario_id = 13;--cancellato prima
    --delete from siac_t_cartacont where ente_proprietario_id = 13;--cancellato prima
    delete from siac_t_cassa_econ_operaz where ente_proprietario_id = 13;--new
    delete from siac_r_modifica_stato where ente_proprietario_id = 13;
    delete from siac_t_modifica where ente_proprietario_id = 13;--new
delete from siac_t_atto_amm t where t.ente_proprietario_id=13;
delete from siac_r_movgest_class where ente_proprietario_id=13;
    delete from siac_r_fondo_econ_movgest where ente_proprietario_id = 13;--new
delete from siac_t_movgest_ts t where t.ente_proprietario_id=13;
delete from siac_r_movgest_bil_elem r where r.ente_proprietario_id=13;
delete from siac_t_movgest t where t.ente_proprietario_id=13;
-- SOGGETTI
DELETE FROM siac_r_soggetto_onere r where r.ente_proprietario_id=13;
DELETE FROM siac_r_subdoc_sog r where r.ente_proprietario_id=13;
DELETE FROM siac_r_doc_sog r where r.ente_proprietario_id=13;
DELETE FROM siac_r_subdoc_modpag r  where r.ente_proprietario_id=13;
DELETE FROM siac_r_modpag_ordine r  where r.ente_proprietario_id=13;
DELETE FROM siac_r_soggrel_modpag_mod r where r.ente_proprietario_id=13;
DELETE FROM siac_r_soggrel_modpag t where t.ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_relaz_stato r where r.ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_relaz_mod r where r.ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_relaz  r where r.ente_proprietario_id=13;
DELETE FROM siac_r_modpag_stato r where r.ente_proprietario_id=13;
    delete from siac_r_causale_modpag where ente_proprietario_id=13;--new
DELETE FROM siac_t_modpag_mod t where t.ente_proprietario_id=13;
DELETE FROM siac_t_modpag t where t.ente_proprietario_id=13;
DELETE FROM siac_r_indirizzo_soggetto_tipo_mod r where r.ente_proprietario_id=13;
DELETE FROM siac_t_indirizzo_soggetto_mod where ente_proprietario_id=13;
DELETE FROM siac_r_indirizzo_soggetto_tipo where ente_proprietario_id=13;
DELETE FROM siac_t_indirizzo_soggetto where ente_proprietario_id=13;
DELETE FROM siac_t_recapito_soggetto_mod where ente_proprietario_id=13;
DELETE FROM siac_t_recapito_soggetto where ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_stato where ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_attr_mod  where ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_attr where ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_classe_mod  where ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_classe where ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_tipo_mod  where ente_proprietario_id=13;
DELETE FROM siac_r_soggetto_tipo  where ente_proprietario_id=13;
DELETE FROM SIAC_R_MOVGEST_TS_SOG_MOD  where ente_proprietario_id=13;
DELETE FROM SIAC_R_MOVGEST_TS_SOG  where ente_proprietario_id=13;
DELETE FROM siac_r_mutuo_soggetto where ente_proprietario_id=13;
DELETE FROM siac_r_liquidazione_soggetto where ente_proprietario_id=13;
DELETE FROM siac_r_forma_giuridica_mod where ente_proprietario_id=13;
DELETE FROM siac_r_forma_giuridica  where ente_proprietario_id=13;
DELETE FROM siac_t_persona_giuridica_mod  where ente_proprietario_id=13;
DELETE FROM siac_t_persona_giuridica where ente_proprietario_id=13;
DELETE FROM siac_t_persona_fisica_mod  where ente_proprietario_id=13;
DELETE FROM siac_t_persona_fisica  where ente_proprietario_id=13;
DELETE from siac_r_causale_soggetto where ente_proprietario_id = 13
and soggetto_id not in (select t.soggetto_id from siac_t_soggetto t, siac_r_soggetto_ruolo r
						where t.ente_proprietario_id = 13
                        and r.ente_proprietario_id = 13
						and t.soggetto_id = r.soggetto_id);
DELETE from siac_t_soggetto_mod where ente_proprietario_id = 13
and soggetto_id not in (select t.soggetto_id from siac_t_soggetto t, siac_r_soggetto_ruolo r
						where t.ente_proprietario_id =13
                        and r.ente_proprietario_id =13
						and t.soggetto_id = r.soggetto_id);
DELETE from siac_r_causale_ep_soggetto where ente_proprietario_id = 13
and soggetto_id not in (select t.soggetto_id from siac_t_soggetto t, siac_r_soggetto_ruolo r
						where t.ente_proprietario_id = 13
                        and r.ente_proprietario_id = 13
						and t.soggetto_id = r.soggetto_id);

DELETE FROM siac_t_soggetto t  where t.ente_proprietario_id=13
	and t.soggetto_id not in (select r.soggetto_id from siac_r_soggetto_ruolo r where r.ente_proprietario_id=13);

-- CAPITOLI

-- ATTI LEGGE
delete from siac_r_bil_elem_atto_legge where ente_proprietario_id=13;
delete from siac_r_atto_legge_stato  where ente_proprietario_id=13;
delete from siac_t_atto_legge where ente_proprietario_id=13;
-- VINCOLI
delete from siac_r_vincolo_bil_elem where ente_proprietario_id=13;
delete from siac_r_vincolo_stato where ente_proprietario_id=13;
delete from siac_r_vincolo_attr where ente_proprietario_id=13;
delete from siac_r_vincolo_genere where ente_proprietario_id=13;
delete from siac_t_vincolo where ente_proprietario_id=13;
-- VARIAZIONI
delete from siac_t_bil_elem_var where ente_proprietario_id=13;
delete from siac_t_bil_elem_det_var  where ente_proprietario_id=13;
delete from siac_r_bil_elem_class_var where ente_proprietario_id=13;
delete from siac_r_variazione_stato  where ente_proprietario_id=13;
delete from siac_r_variazione_attr where ente_proprietario_id=13;
delete from siac_t_variazione where ente_proprietario_id=13;
-- CLASSIFICATORI
delete  from siac_r_bil_elem_class  where ente_proprietario_id=13;
-- REL IMP/ACC
delete from SIAC_R_MOVGEST_BIL_ELEM where ente_proprietario_id=13;
-- ELEMENTI
delete from  siac_r_bil_elem_attr where ente_proprietario_id=13;
delete from  siac_r_bil_elem_stato where ente_proprietario_id=13;
delete from  siac_r_bil_elem_categoria where ente_proprietario_id=13;
delete from  SIAC_R_CRONOP_ELEM_BIL_ELEM  where ente_proprietario_id=13;
    delete from siac_r_cronop_elem_class  where ente_proprietario_id=13;--new
    delete from siac_t_cronop_elem_det where ente_proprietario_id=13;--new
    delete from siac_t_cronop_elem where ente_proprietario_id=13;--new
delete from SIAC_R_BIL_ELEM_REL_TEMPO where ente_proprietario_id=13;
delete from  siac_r_predoc_bil_elem  where ente_proprietario_id=13;
delete from  siac_r_ordinativo_bil_elem  where ente_proprietario_id=13;
delete from  siac_r_fondo_econ_bil_elem  where ente_proprietario_id=13;
    delete from  siac_r_fondo_econ_movgest where ente_proprietario_id=13;--new, cancellato anche per movgest
    delete from  siac_t_fondo_econ where ente_proprietario_id=13;--new
-- 26.13.2015 ATTENZIONE NON CANCELLATE, SONO TABELLE DI CONFIGURAZIONE?
--    delete from siac_r_cassa_econ_attr where ente_proprietario_id = 13;--new
--    delete from siac_t_cassa_econ_operaz_num where ente_proprietario_id = 13;--new
--    delete from siac_t_cassa_econ_stampa where ente_proprietario_id = 13;--new
--    delete from siac_t_cassa_econ_stanz where ente_proprietario_id = 13;--new
--    delete from siac_t_richiesta_econ_num where ente_proprietario_id = 13;--new
--    delete from siac_t_richiesta_econ where ente_proprietario_id = 13;--new
--    delete from siac_t_cassa_econ where ente_proprietario_id = 13;--new
delete from  siac_r_causale_bil_elem  where ente_proprietario_id=13;
delete from  siac_r_bil_elem_iva_attivita  where ente_proprietario_id=13;
-- 26.13.2015 ATTENZIONE NON CACELLATE, SONO TABELLE DI CONFIGURAZIONE?
--    delete from siac_r_iva_att_attr where ente_proprietario_id = 13;--new
--    delete from siac_r_iva_gruppo_attivita where ente_proprietario_id = 13;--new
--    delete from siac_t_iva_registro_totale where ente_proprietario_id = 13;--new
--    delete from siac_t_iva_attivita where ente_proprietario_id = 13;--new
--    delete from siac_t_ivaaliquota where ente_proprietario_id = 13;--new
--    delete from siac_r_iva_registro_gruppo where ente_proprietario_id = 13;--new
--    delete from siac_t_iva_registro where ente_proprietario_id = 13;--new

	delete from siac_r_ivamov where ente_proprietario_id = 13;
	delete from siac_t_ivamov where ente_proprietario_id = 13;
	delete from siac_r_subdoc_iva where ente_proprietario_id = 13;
	delete from siac_r_subdoc_iva_stato where ente_proprietario_id = 13;
	delete from siac_r_subdoc_iva_attr where ente_proprietario_id = 13;
	delete from siac_t_subdoc_iva where ente_proprietario_id = 13;
	delete from siac_r_doc_iva where ente_proprietario_id = 13;
  	delete from siac_t_doc where ente_proprietario_id = 13;

-- TABELLA DI CONFIGURAZIONE?
--    delete from siac_r_iva_stampa_registro where ente_proprietario_id = 13;--new
    delete from siac_t_subdoc_iva_prot_def_num where ente_proprietario_id = 13;--new
    delete from siac_t_subdoc_iva_prot_prov_num where ente_proprietario_id = 13;--new

delete from  SIAC_R_BIL_ELEM_STIPENDIO_CODICE  where ente_proprietario_id=13;
delete from  siac_t_dicuiimpegnato_bilprev where ente_proprietario_id = 13;
delete from  siac_t_bil_elem_det where ente_proprietario_id=13;
delete from  siac_t_bil_elem where ente_proprietario_id=13;


-- tabelle di decodifica siac
delete from siac_t_class where ente_proprietario_id=13 and login_operazione like ('migr_%');
DELETE FROM siac_t_forma_giuridica t where ente_proprietario_id=13 and login_operazione like ('migr_%');
DELETE FROM siac_r_comune_provincia where ente_proprietario_id=13 and login_operazione like ('migr_%');
DELETE FROM siac_t_provincia where ente_proprietario_id=13 and login_operazione like ('migr_%');
DELETE FROM siac_t_comune where ente_proprietario_id=13 and login_operazione like ('migr_%');
DELETE FROM siac_t_nazione where ente_proprietario_id=13 and login_operazione like ('migr_%');
DELETE FROM siac_d_soggetto_classe where ente_proprietario_id =13 and login_operazione like ('migr_%');
delete from siac_r_accredito_tipo_oil where ente_proprietario_id=13;
DELETE FROM siac_d_accredito_tipo where ente_proprietario_id =13 and login_operazione like ('migr_%');


-- tabelle di appoggio
delete from siac_r_migr_elenco_doc_all_t_elenco_doc where ente_proprietario_id = 13;
delete from siac_r_migr_atto_all_t_atto_allegato where ente_proprietario_id = 13;
delete from siac_r_migr_docquo_entrata_t_subdoc where ente_proprietario_id = 13;
delete from siac_r_migr_doc_entrata_t_doc m where ente_proprietario_id = 13;
delete from siac_r_migr_docquo_spesa_t_subdoc where ente_proprietario_id = 13;
delete from siac_r_migr_doc_spesa_t_doc where ente_proprietario_id = 13;
delete from siac_r_migr_liquidazione_t_liquidazione r where ente_proprietario_id = 13;
delete from siac_r_migr_impegno_movgest_ts where ente_proprietario_id = 13;
delete from siac_r_migr_accertamento_movgest_ts where ente_proprietario_id = 13;
delete from siac_r_migr_mutuo_t_mutuo where ente_proprietario_id = 13;
delete from siac_r_migr_voce_mutuo_t_mutuo_voce where ente_proprietario_id = 13;
DELETE FROM siac_r_migr_indirizzo_secondario_indirizzo where ente_proprietario_id = 13;
delete from siac_r_migr_recapito_soggetto_recapito where ente_proprietario_id = 13;
delete from siac_r_migr_soggetto_classe_rel_classe where ente_proprietario_id = 13;
DELETE FROM siac_r_migr_sede_secondaria_rel_sede where ente_proprietario_id = 13;
DELETE FROM siac_r_migr_soggetto_soggetto where ente_proprietario_id = 13;
DELETE FROM siac_r_migr_relaz_soggetto_relaz where ente_proprietario_id = 13;
DELETE FROM siac_r_migr_modpag_modpag where ente_proprietario_id = 13;
DELETE FROM siac_r_migr_classe_soggclasse where ente_proprietario_id=13;
DELETE FROM siac_r_migr_mod_accredito_accredito where ente_proprietario_id=13;
delete from siac_r_migr_attilegge_ent where ente_proprietario_id = 13;
delete from siac_r_migr_attilegge_usc where ente_proprietario_id = 13;
delete from siac_r_migr_vincolo_capitolo where ente_proprietario_id = 13;
delete from siac_r_migr_capitolo_uscita_bil_elem  where ente_proprietario_id = 13;
delete from siac_r_migr_capitolo_entrata_bil_elem   where ente_proprietario_id = 13;
delete from siac_r_migr_docquospesaivaaliq_t_ivamov where ente_proprietario_id = 13;
delete from siac_r_migr_relazdocquospesaiva_subdoc where ente_proprietario_id = 13;
delete from siac_r_migr_docquospesaiva_t_subdoc_iva where ente_proprietario_id = 13;



-- tabelle da cencellare ? usate ? sono legate ai soggetti
--siac_r_doc_iva_sog
--SIAC_R_pdce_conto_soggetto
--SIAC_R_soggetto_ente_proprietario
--SIAC_R_soggetto_onere_mod