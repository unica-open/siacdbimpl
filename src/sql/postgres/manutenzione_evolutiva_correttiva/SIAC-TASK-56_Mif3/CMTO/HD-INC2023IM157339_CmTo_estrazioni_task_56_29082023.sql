/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- 29.08.2023 Sofia HD-INC2023IM157339_CmTo
-- HD-INC2023IM157339_CmTo_estrazioni_task_56_29082023.sql
-- 2023-IM157339

/*BACKOFFICE APPLICATIVO [Citta' Metropolitana di Torino (Torino) - TO - cmto]
Descrizione breve
CMTO : OI-52345 Fwd: siac-tasks | Valorizzazione del conto di accredito per girofondi a enti in regime di Tesoreria Unica e per i pagamenti F24EP (SIOPE PLUS) (#56)
Descrizione estesa
Buon pomeriggio a tutti,
martedì 5 settembre alle 10 abbiamo un incontro con Cmto su questo tema.
Puoi fornirci gli elenchi che citi così ne diamo evidenza all'ente?
In particolare  elenco delle MDP e delle associazioni tra soggetti e MDP (cessioni dell'incasso) così iniziano a fare le nuove associazioni

Grazie mille!!!

Nino Cicala
Project Manager Suite Unica Bilancio, Fatturazione Elettronica, Valutazione Performance
SERVIZI DIGITALI PER LA P.A.
CSI- Piemonte www.csipiemonte.it
e- mail nino.cicala@csi.it
cell. 3454700586

Da: "Sofia Sterchele" <sofia.sterchele@consulenti.csi.it>
A: "Antonino Cicala" <nino.cicala@csi.it>
Cc: "Marco Maspes" <marco.maspes@consulenti.csi.it>, "Anna Valenzano" <anna.valenzano@csi.it>, "Massimo Molino" <massimo.molino@csi.it>
Inviato: Venerdì, 5 maggio 2023 15:06:25
Oggetto: Re: OI-52345 Fwd: siac-tasks | Valorizzazione del conto di accredito per girofondi a enti in regime di Tesoreria Unica e per i pagamenti F24EP (SIOPE PLUS) (#56)
Ciao,
abbiamo predisposto gli script per l'argomento in oggetto.

Le operazioni che dovremo eseguire saranno le seguenti :

1. predisposizione estrazioni relativamente alle tipologie di pagamento che dovranno essere chiuse nel 2024
     "ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B" e "ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A"
	 "REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB A" e "REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB B"
   - elenco liquidazioni non pagate
   - elenco documenti non liquidati
   - elenco delle MDP e delle associazioni tra soggetti e MDP (cessioni dell'incasso)
   - elenco dei mandati (se necessario)
2. trattamento delle MDP di cui al punto 1 che verranno BLOCCATE al pagamento; le MDP in MODIFICA dovranno essere validate prima che si proceda con tali operazioni
3. trattamento delle tipologie di pagamento di cui al punto 1 che verranno chiuse e rese non utilizzabili per creare nuove MDP    
4. inserimento della nuova tipologia di pagamento ATP - ACCREDITO TESORERIA PROVINCIALE STATO di tipo CB - coordinate bancarie, con la quale potranno essere inserite nuove MDP indicando il codice IBAN e facoltativamente il BIC; 
   adeguamento della configurazione per la procedura di generazione dei tracciati XML dei mandati per la gestione della nuova tipologia ATP, con valorizzazione della sezione sepa_credit_trasfer per l'esposizione delle coordinate bancarie
   
6. chiusura della tipologia di incasso "REGOLARIZZAZIONE ACCREDITO BANCA D'ITALIA", che non verrà più accettata a partire dal 2024,quindi chiusura dei relativi classificatori di tipo CLASSIFICATORE_28, descrizione %ACCREDITO BANCA D''ITALIA,
    al fine di non consentirne più utlizzo in sede di registrazione reversali di incasso
   
Per quanto riguarda le estrazioni relativamente agli elenchi citati al punto 1, potranno essere forniti agli enti. 
In particolare gli elenchi relativi a liquidazioni non pagate e documenti non liquidati, dovranno essere visionati dagli enti, in quanto in seguito al trattamento dati ( punto 2 ), risulteranno essere associati a MDP bloccate, quindi non potranno più essere pagati/liquidati.
Gli enti dovranno ricondurre tali movimenti/documenti a diverse MDP o chiudere tutto quanto il pagabile nel 2023 con le vecchie modalità ammesse.

Abbiamo generato in ambiente consip 3 mandati di pagamento con la nuova MDP ATP e creato i relativi file XML.
- n. 22/2023 con IBAN IT   esposto in sepa_credit_tranfer
- n. 23/2023 con IBAN diverso da IT, SEPA esposto in sepa_credit_transfer
- n. 24/2023 con IBAN trattato come extrasepa, tipologia per la quale la sezione sepa_credit_tranfer non è gestita
Nelle specifiche tecniche OPI fornite si parla di un’anagrafica degli IBAN resa disponibile agli Enti e alle Banche Tesoriere,tuttavia noi abbiamo effettuato dei test per le tre casistiche gestite per i pagamento di tipo CB-coordinate bancarie, 
quindi anche iban non IT, che comunque l'ente potrà liberamente indicare sulla ATP senza nessun diverso controllo rispetto a quelli già esistenti per la tipologia CB di appartenenza.
In allegato i tre XML citati.

Questo è quanto ci sembra sia necessario realizzare per l'argomento in oggetto, anche sulla base di  altri adeguamenti simili già effettuati in passato.
Suggeriamo di allertare gli enti relativamente ai trattamenti dati che dovremo fare e agli elenchi che forniremo, sempre se vi sembra che sia tutto corretto e necessario, diversamente attendiamo vostre diverse indicazioni.*/


-- Q1-MODALITA DI PAGAMENTO
-- query di verifica delle MDP 
-- tutte quelle che saranno esistenti dovranno essere chiuse o bloccate o annullate
-- non dovranno essercene in modifica e tutte le altre saranno bloccate - fornire estrazioni 
select  sog.ente_proprietario_id , sog.soggetto_code, sog.soggetto_desc, stato.soggetto_stato_code ,stato_mdp.modpag_stato_code ,
             oil.accredito_tipo_oil_desc , tipo.accredito_tipo_code , tipo.accredito_tipo_desc ,gruppo.accredito_gruppo_desc 
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_r_modpag_stato  rs_mdp,siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo
where sog.ente_proprietario_id in (3)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null 
order by 1,3




select  sog_da.ente_proprietario_id , sog_da.soggetto_code , sog_da.soggetto_desc , stato_da.soggetto_stato_code ,
            sog.soggetto_code, sog.soggetto_desc, stato.soggetto_stato_code ,stato_mdp.modpag_stato_code ,stato_rel.relaz_stato_code ,
             oil.accredito_tipo_oil_desc , tipo.accredito_tipo_code , tipo.accredito_tipo_desc ,gruppo.accredito_gruppo_desc 
from siac_t_soggetto sog,siac_t_modpag mdp ,siac_d_accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil oil,
           siac_r_soggetto_stato rs,siac_d_soggetto_stato stato, siac_r_modpag_stato  rs_mdp,siac_d_modpag_stato stato_mdp,siac_d_accredito_gruppo gruppo,
           siac_r_soggetto_relaz  rel , siac_r_soggetto_relaz_stato  rs_rel,siac_d_relaz_stato  stato_rel,
           siac_t_soggetto sog_da , siac_r_soggetto_stato rs_da ,siac_d_soggetto_stato stato_da 
where sog.ente_proprietario_id in (3)
and     mdp.soggetto_id=sog.soggetto_id
and     tipo.accredito_tipo_id =mdp.accredito_tipo_id 
and     r.accredito_tipo_id =tipo.accredito_tipo_id 
and     oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and    gruppo.accredito_gruppo_id =tipo.accredito_gruppo_id               
and     rs.soggetto_id=sog.soggetto_id 
and     stato.soggetto_stato_id =rs.soggetto_stato_id 
and     stato.soggetto_stato_code not in ('BLOCCATO','ANNULLATO')
and     rs_mdp.modpag_id =mdp.modpag_id 
and     stato_mdp.modpag_stato_id=rs_mdp.modpag_stato_id 
and     stato_mdp.modpag_stato_code not in ('BLOCCATO','ANNULLATO')
and     rel.soggetto_id_a =sog.soggetto_id 
and     rs_rel.soggetto_relaz_id =rel.soggetto_relaz_id 
and     stato_rel.relaz_stato_id =rs_rel.relaz_stato_id 
and     stato_rel.relaz_stato_code  not in ('BLOCCATO','ANNULLATO')
and     sog_da.soggetto_id=rel.soggetto_id_da 
and     rs_da.soggetto_id=sog_da.soggetto_id 
and     stato_da.soggetto_stato_id =rs_da.soggetto_stato_id 
and     tipo.data_cancellazione  is null 
and     tipo.validita_fine  is null 
and     oil.data_cancellazione  is null 
and     oil.validita_fine  is null 
and     r.data_cancellazione  is null 
and     r.validita_fine  is null 
and     sog.data_cancellazione  is null 
and     sog.validita_fine  is null 
and     mdp.data_cancellazione  is null 
and     mdp.validita_fine  is null 
and     rs_mdp.data_cancellazione  is null 
and     rs_mdp.validita_fine  is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine  is null 
and     rel.data_cancellazione  is null 
and     rel.validita_fine  is null 
and     rs_rel.data_cancellazione  is null 
and     rs_rel.validita_fine  is null 
and     rs_da.data_cancellazione  is null 
and     rs_da.validita_fine  is null 
and     sog_da.data_cancellazione  is null 
and     sog_da.validita_fine  is null 
order by 1,3


-- mandati
select op.ente_proprietario_id ,op.anno_bilancio ,op.ord_numero , op.ord_stato_code , stato.modpag_stato_code,tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , sog.soggetto_code, sog.soggetto_desc 
from siac_v_bko_ordinativo_op_valido op ,siac_r_ordinativo_modpag  rmdp,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
           siac_r_modpag_stato rs,siac_d_modpag_stato stato ,siac_t_soggetto sog 
where op.ente_proprietario_id in (3)
and      op.anno_bilancio >=2023
and      rmdp.ord_id=op.ord_id 
and      mdp.modpag_id =rmdp.modpag_id 
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      rs.modpag_id =mdp.modpag_id 
and      stato.modpag_stato_id =rs.modpag_stato_id 
and      stato.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      sog.soggetto_id=mdp.soggetto_id
and      rmdp.data_cancellazione  is null 
and      rmdp.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
order by 1,2,3

select op.ente_proprietario_id ,op.anno_bilancio, op.ord_numero , op.ord_stato_code , tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , stato.modpag_stato_code ,stato_rel.relaz_stato_code ,
            rel_tipo.relaz_tipo_code , sog_da.soggetto_code, sog_da.soggetto_desc, 
            sog_a.soggetto_code, sog_a.soggetto_desc 
from siac_v_bko_ordinativo_op_valido op ,
           siac_r_ordinativo_soggetto  rsog,
           siac_r_soggetto_relaz  relaz,siac_d_relaz_tipo rel_tipo, siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
           siac_r_modpag_stato rs,siac_d_modpag_stato stato ,siac_r_soggetto_relaz_stato  rs_rel,siac_d_relaz_stato  stato_rel,
           siac_t_soggetto sog_da, siac_t_soggetto sog_a 
where op.ente_proprietario_id in (3)
and      op.anno_bilancio >=2023
and      rsog.ord_id=op.ord_id 
and      relaz.soggetto_id_da =rsog.soggetto_id 
and      rel_tipo.relaz_tipo_id=relaz.relaz_tipo_id 
and      rel_tipo.relaz_tipo_code ='CSI'
and      mdp.modpag_id =relaz.soggetto_id_a  
and      rs.modpag_id=mdp.modpag_id 
and      stato.modpag_stato_id =rs.modpag_stato_id 
and      stato.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      rs_rel.soggetto_relaz_id =relaz.soggetto_relaz_id 
and      stato_rel.relaz_stato_id =rs_rel.relaz_stato_id 
and      stato_rel.relaz_stato_code  not in ('BLOCCATO','ANNULLATO')
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%'
                           or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and     sog_da.soggetto_id =relaz.soggetto_id_da 
and     sog_a.soggetto_id=relaz.soggetto_id_a 
and      rsog.data_cancellazione  is null 
and      rsog.validita_fine  is null 
and      relaz.data_cancellazione  is null 
and      relaz.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
and      rs_rel.data_cancellazione  is null 
and      rs_rel.validita_fine  is null 
order by 1,2,3


-- Q3 - LIQUIDAZIONI- verifica esistenza liquidazioni - non pagate 
select liq.ente_proprietario_id , liq.anno_bilancio ,liq.liq_anno,liq.liq_numero , liq.liq_stato_code  ,tipo.accredito_tipo_code, tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc ,stato.modpag_stato_code ,sog.soggetto_code, sog.soggetto_desc 
from siac_v_bko_liquidazione_valida liq, siac_t_liquidazione liq_mdp ,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
          siac_r_modpag_stato rs,siac_d_modpag_stato stato ,siac_t_soggetto sog 
where liq.ente_proprietario_id in (3)
and      liq.anno_bilancio >=2023
and      liq_mdp.liq_id=liq.liq_id 
and      mdp.modpag_id =liq_mdp.modpag_id 
and     sog.soggetto_id =mdp.soggetto_id
and      rs.modpag_id =mdp.modpag_id 
and      stato.modpag_stato_id =rs.modpag_stato_id 
and      stato.modpag_stato_code   not in ('BLOCCATO','ANNULLATO')
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      not exists 
(
select 1 
from siac_r_liquidazione_ord rord,siac_t_ordinativo_ts ts,siac_t_ordinativo op ,siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato
where rord.liq_id=liq.liq_id 
and     ts.ord_ts_id=rord.sord_id 
and     op.ord_id=ts.ord_id 
and     op.bil_id=liq.bil_id 
and     rs.ord_id=op.ord_id 
and     stato.ord_Stato_id=rs.ord_stato_id 
and     stato.ord_stato_code!='A'
and     rord.data_cancellazione  is null 
and     rord.validita_fine   is null 
and     rs.data_cancellazione  is null 
and     rs.validita_fine   is null 
and     ts.data_cancellazione  is null 
and     ts.validita_fine   is null 
and     op.data_cancellazione  is null 
and     op.validita_fine   is null 
)
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
order by 1,2,3,4



-- Q4 - verifica esistenza documenti non liquidati

select tipo_doc.ente_proprietario_id , tipo_doc.doc_tipo_code, doc.doc_anno, doc.doc_numero,sub.subdoc_numero, stato.doc_stato_code , tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , sub.subdoc_id,
            stato_mdp.modpag_stato_code , sog.soggetto_code, sog.soggetto_desc 
from siac_t_doc doc,siac_d_doc_tipo tipo_doc, siac_t_subdoc sub,siac_r_doc_Stato rs,siac_d_doc_stato stato, 
          siac_r_subdoc_modpag  rmdp,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
          siac_r_modpag_stato rs_mdp,siac_d_modpag_stato stato_mdp,siac_t_soggetto sog 
where tipo_doc.ente_proprietario_id in (3)
and      doc.doc_tipo_id=tipo_doc.doc_tipo_id 
and      sub.doc_id=doc.doc_id 
and      rs.doc_id=doc.doc_id 
and      stato.doc_stato_id=rs.doc_stato_id 
and      stato.doc_stato_code not in ('A','ST','L','EM')
and      rmdp.subdoc_id=sub.subdoc_id 
and     sog.soggetto_id=mdp.soggetto_id
and      mdp.modpag_id =rmdp.modpag_id 
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
                or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      not exists 
(
select 1 
from siac_r_subdoc_liquidazione rliq,siac_t_liquidazione liq,siac_r_liquidazione_Stato rs_liq,siac_d_liquidazione_stato stato_liq, 
          siac_v_bko_anno_bilancio_only  anno
where rliq.subdoc_id=sub.subdoc_id 
and     rs_liq.liq_id=rliq.liq_id 
and     stato_liq.liq_Stato_id=rs_liq.liq_stato_id 
and     stato_liq.liq_Stato_code!='A'
and     liq.liq_id=rs_liq.liq_id
and     anno.bil_id=liq.bil_id 
and     anno.anno_bilancio >=2023
and     rs_liq.data_cancellazione  is null 
and     rs_liq.validita_fine  is null 
and     rliq.data_cancellazione  is null 
and     rliq.validita_fine  is null 
and     liq.data_cancellazione  is null 
and     liq.validita_fine  is null 
)
and      rs_mdp.modpag_id=mdp.modpag_id 
and      stato_mdp.modpag_stato_id =rs_mdp.modpag_stato_id 
and      stato_mdp.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      rmdp.data_cancellazione  is null 
and      rmdp.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
and      rs_mdp.data_cancellazione  is null 
and      rs_mdp.validita_fine  is null 
order by 1, doc.doc_id


select tipo_doc.ente_proprietario_id ,tipo_doc.doc_tipo_code, doc.doc_anno, doc.doc_numero,sub.subdoc_numero, stato.doc_stato_code , tipo.accredito_tipo_desc , oil.accredito_tipo_oil_desc , sub.subdoc_id,
            stato_mdp.modpag_stato_code ,stato_relaz.relaz_stato_code 
from siac_t_doc doc,siac_d_doc_tipo tipo_doc, siac_t_subdoc sub,siac_r_doc_Stato rs,siac_d_doc_stato stato, 
          siac_r_subdoc_modpag  rmdp,siac_t_modpag mdp ,siac_d_Accredito_tipo tipo ,siac_r_accredito_tipo_oil  r, siac_d_accredito_tipo_oil  oil ,
          siac_r_soggrel_modpag  rel_mdp,siac_r_modpag_stato rs_mdp,siac_d_modpag_stato stato_mdp,
          siac_r_soggetto_relaz_stato  rs_rel,siac_d_relaz_stato  stato_relaz
where tipo_doc.ente_proprietario_id in (3)
and      doc.doc_tipo_id=tipo_doc.doc_tipo_id 
and      sub.doc_id=doc.doc_id 
and      rs.doc_id=doc.doc_id 
and      stato.doc_stato_id=rs.doc_stato_id 
and      stato.doc_stato_code not in ('A','ST','L','EM')
and      rmdp.subdoc_id =sub.subdoc_id
and      rel_mdp.soggrelmpag_id =rmdp.soggrelmpag_id 
and      mdp.modpag_id =rel_mdp.modpag_id 
and      tipo.accredito_tipo_id=mdp.accredito_tipo_id 
and      r.accredito_tipo_id =tipo.accredito_tipo_id 
and      oil.accredito_tipo_oil_id =r.accredito_tipo_oil_id 
and      ( oil.accredito_tipo_oil_desc  like 'ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' 
               or oil.accredito_tipo_oil_desc  like 'REGOLARIZZAZIONE ACCREDITO TESORERIA PROVINCIALE STATO PER TAB%' )
and      not exists 
(
select 1 
from siac_r_subdoc_liquidazione rliq,siac_t_liquidazione liq,siac_r_liquidazione_Stato rs_liq,siac_d_liquidazione_stato stato_liq, 
          siac_v_bko_anno_bilancio_only  anno
where rliq.subdoc_id=sub.subdoc_id 
and     rs_liq.liq_id=rliq.liq_id 
and     stato_liq.liq_Stato_id=rs_liq.liq_stato_id 
and     stato_liq.liq_Stato_code!='A'
and     liq.liq_id=rs_liq.liq_id
and     anno.bil_id=liq.bil_id 
and     anno.anno_bilancio >=2023
and     rs_liq.data_cancellazione  is null 
and     rs_liq.validita_fine  is null 
and     rliq.data_cancellazione  is null 
and     rliq.validita_fine  is null 
and     liq.data_cancellazione  is null 
and     liq.validita_fine  is null 
)
and      rs_mdp.modpag_id=mdp.modpag_id 
and      stato_mdp.modpag_stato_id =rs_mdp.modpag_stato_id 
and      stato_mdp.modpag_stato_code  not in ('BLOCCATO','ANNULLATO')
and      rs_rel.soggetto_relaz_id =rel_mdp.soggetto_relaz_id 
and      stato_relaz.relaz_stato_id =rs_rel.relaz_stato_id 
and      stato_relaz.relaz_stato_code    not in ('BLOCCATO','ANNULLATO')
and      rel_mdp.data_cancellazione  is null 
and      rel_mdp.validita_fine  is null 
and      rmdp.data_cancellazione  is null 
and      rmdp.validita_fine  is null 
and      r.data_cancellazione  is null 
and      r.validita_fine  is null 
and      tipo.data_cancellazione  is null 
and      tipo.validita_fine  is null 
and      oil.data_cancellazione  is null 
and      oil.validita_fine  is null 
and      rs.data_cancellazione  is null 
and      rs.validita_fine  is null 
and      rs_mdp.data_cancellazione  is null 
and      rs_mdp.validita_fine  is null 
and      rs_rel.data_cancellazione  is null 
and      rs_rel.validita_fine  is null 
order by 1,doc.doc_id
