/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿-- 19.04.2016 Sofia - compilato in prodbilmult
-- 01.04.2016 Sofia - sblocca ordinativi da ritrasmettere
-- inserisce record in mif_t_elaborazione_flusso per tipo=SBLOCCA_MIF per tracciare elaborazione_id in tabelle di sblocco dati
-- inserisce ordinativi in mif_ordinativo_sblocca in base a elenco passato in ordArray e ordCodeTipo
--   in questa fase quindi controlla solo che gli id passati corrispondano al tipo passato
-- inserisce dati di backup in mif_t_ordinativo_sbloccato_log per gli ordinativi da sbloccare inseriti in mif_ordinativo_sblocca
--  nelle successive fasi tratta gli ordinativi inseriti in mif_ordinativo_sblocca con data di trasmissione valorizzata
--  quindi se resistuisce un numero di ordinativi inferiore al numero di id passati
--    o non esistevano per ente
--    o non esistevano per ente e tipo passato
--    o non erano stati trasmessi , ovvero non avevano la data di trasmissione valorizzata
-- sistema gli stati operativi degli ordinativi da sbloccare
-- aggiorna la data_trasm_oil sugli ordinativi
-- aggiorna il flag migr_orb_sbloccato=true per gli ordinativi per cui effettivamente aggiorna la data di trasmissione
-- chiude mif_t_elaborazione_flusso
-- elaborazione OK per ordAgg>=0
-- restituisce
-- ordAgg = 0 se non ha aggiornato migr_orb_sbloccato=true per nessuno ordinativo da sbloccare
-- ordAgg>=   con il numero di ordinativi sbloccati per ha aggiornato  migr_orb_sbloccato=true
-- elaborazione KO per ordAgg=-1
-- restituisce ordAgg=-1  in caso di errore
-- 05.04.2016 Sofia
-- per semplicita restituisce
-- null in caso di elaborazione OK
-- messaggio di errore

/*drop FUNCTION fnc_mif_ordinativo_sblocca
(
  enteProprietarioId integer,
  loginOperazione varchar,
  ordCodeTipo varchar,
  ordArray integer[]
);
RETURNS integer */

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_sblocca
(
  enteProprietarioId integer,
  loginOperazione varchar,
  ordCodeTipo varchar,
  ordArray text
)
RETURNS varchar AS
$body$
DECLARE

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF';
 REVMIF_TIPO  CONSTANT  varchar :='REVMIF';
 SBLOCCA_MIF_TIPO  CONSTANT  varchar :='SBLOCCA_MIF';
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 codResult   integer :=null;
 mifOrdSbloccaElabId integer :=null;

 tipoMif varchar(20):=null;

 ordAgg integer:=0;
 messaggioRisultato varchar:=null;

BEGIN

 messaggioRisultato:=null;


 strMessaggioFinale :='Sblocco per ritrasmissione Ordinativi tipo='||ordCodeTipo||'.';


 strMessaggio:='Verifica parametri ordCodeTipo ordArray.';
 if coalesce(ordCodeTipo,'')='' or
    coalesce(ordArray,'')='' then
    raise exception ' Parametri non valorizzati.';
 end if;

 if ordCodeTipo='P' then
 	tipoMif:=MANDMIF_TIPO;
 else
    tipoMif:=REVMIF_TIPO;
 end if;

 -- inserimento record in tabella mif_t_flusso_elaborato
 strMessaggio:='Inserimento mif_t_flusso_elaborato per sblocco dati tipo flusso='||tipoMif||'. Tipo sblocco '||SBLOCCA_MIF_TIPO||'.';

 insert into mif_t_flusso_elaborato
 (flusso_elab_mif_data ,
  flusso_elab_mif_esito,
  flusso_elab_mif_file_nome,
  flusso_elab_mif_esito_msg,
  flusso_elab_mif_tipo_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione)
 (select now(),
         ELAB_MIF_ESITO_IN,
         tipo.flusso_elab_mif_nome_file,
         'Elaborazione in corso per sblocco dati tipo flusso '||tipoMif,
    	 tipo.flusso_elab_mif_tipo_id,
   		 now(),
       	 enteProprietarioId,
         loginOperazione
  from mif_d_flusso_elaborato_tipo tipo
  where tipo.ente_proprietario_id=enteProprietarioId
  and   tipo.flusso_elab_mif_tipo_code=SBLOCCA_MIF_TIPO
  and   tipo.data_cancellazione is null
  and   tipo.validita_fine is null
 )
 returning flusso_elab_mif_id into mifOrdSbloccaElabId;-- valore da restituire

 raise notice 'mifOrdSbloccaElabId %',mifOrdSbloccaElabId;

 if mifOrdSbloccaElabId is null then
  RAISE EXCEPTION ' Errore generico in inserimento %.',SBLOCCA_MIF_TIPO;
 end if;


 strMessaggio:='Verifica esistenza elaborazioni in corso per sblocco dati  tipo flusso '||tipoMif||'.Tipo sblocco '||SBLOCCA_MIF_TIPO||'.';
 codResult:=null;
 select distinct 1 into codResult
 from mif_t_flusso_elaborato elab,  mif_d_flusso_elaborato_tipo tipo
 where  elab.flusso_elab_mif_id!=mifOrdSbloccaElabId
 and    elab.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN
 and    elab.data_cancellazione is null
 and    elab.validita_fine is null
 and    tipo.flusso_elab_mif_tipo_id=elab.flusso_elab_mif_tipo_id
 and    tipo.flusso_elab_mif_tipo_code=SBLOCCA_MIF_TIPO
 and    tipo.ente_proprietario_id=enteProprietarioId
 and    tipo.data_cancellazione is null
 and    tipo.validita_fine is null;

 if codResult is not null then
  	RAISE EXCEPTION ' Verificare situazioni esistenti.';
 end if;


 strMessaggioFinale :=strMessaggioFinale||' mifOrdSbloccaElabId='||mifOrdSbloccaElabId||'.';

 /*insert into mif_t_ordinativo_sbloccato
 ( mif_ord_id,
   mif_ord_tipo_id,
   mif_ord_trasm_oil_data,
   mif_ord_sblocca_elab_id,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 (select fnc.ord_id, fnc.ord_tipo_id,fnc.ord_trasm_oil_data, mifOrdSbloccaElabId, now(),enteProprietarioId,loginOperazione
  from fnc_mif_ordinativo_get_cursor(enteProprietarioId,ordCodeTipo,ordArray) fnc);*/

 -- 10.04.2018 Sofia SIAC-5934 - escludi sblocco di SOS_ORD annullati
 insert into mif_t_ordinativo_sbloccato
 ( mif_ord_id,
   mif_ord_tipo_id,
   mif_ord_emissione_data,  -- 16.04.2018 Sofia SIAC-5934
   mif_ord_trasm_oil_data,
   mif_ord_spostamento_data, -- 16.04.2018 Sofia SIAC-5934
   mif_ord_sblocca_elab_id,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 (
 with
 elenco as
 (
  select fnc.ord_id, fnc.ord_tipo_id,
         fnc.ord_emissione_data, -- 16.04.2018 Sofia SIAC-5934
         fnc.ord_trasm_oil_data,
         fnc.ord_spostamento_data, -- 16.04.2018 Sofia SIAC-5934
         mifOrdSbloccaElabId, now(),enteProprietarioId,loginOperazione
  from fnc_mif_ordinativo_get_cursor(enteProprietarioId,ordCodeTipo,ordArray) fnc
 ),
 sosOrd as
 (
 select rord.ord_id_da, rord.ord_id_a
 from  siac_r_ordinativo rord, siac_d_relaz_tipo  rel
 where rel.ente_proprietario_id=enteProprietarioId
 and   rel.relaz_tipo_code='SOS_ORD'
 and   rord.relaz_tipo_id=rel.relaz_tipo_id
 and   rord.data_cancellazione is null
 and   rord.validita_fine is null
 ),
 ordAnn as
 (
 select rs.ord_id
 from siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato
 where stato.ente_proprietario_id=enteProprietarioId
 and   stato.ord_stato_code='A'
 and   rs.ord_stato_id=stato.ord_stato_id
 and   rs.data_cancellazione is null
 and   rs.validita_fine is null
 )
 select elenco.*
 from elenco
 where
 not exists ( select 1 from sosOrd, ordAnn where sosOrd.ord_id_da=elenco.ord_id and ordAnn.ord_id=elenco.ord_id )
 and
 not exists ( select 1 from sosOrd, ordAnn where sosOrd.ord_id_a=elenco.ord_id and ordAnn.ord_id=elenco.ord_id )
 );


 -- controllo di presenza di ordinativi in mif_t_ordinativo_sblocca per ordCodeTipo e mifOrdSbloccaElabId validi
 strMessaggio:='Controllo presenza ordinativi in  tabella mif_t_ordinativo_sbloccato validi.';
 select 1 into codResult
 from mif_t_ordinativo_sbloccato m,  siac_d_ordinativo_tipo tipo
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId
 and   m.ente_proprietario_id=enteProprietarioId
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   tipo.ord_tipo_id=m.mif_ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   tipo.data_cancellazione is null
 and   tipo.validita_fine is null;

 if codResult is null then
	-- se non inserisce record in mif_t_ordinativo_sbloccato e quindi non ne trova
    -- chiude elaborazione OK e restituisce 0
    update mif_t_flusso_elaborato
    set flusso_elab_mif_esito='OK',
        flusso_elab_mif_esito_msg=
          upper('Elaborazione conclusa OK per sblocco dati tipo flusso '||tipoMif||'.Ordinativi sbloccati= '||ordAgg||'.'||strMessaggio||' Nessun Ordinativo presente.'),
        validita_fine=now(),
        flusso_elab_mif_num_ord_elab=0
    where flusso_elab_mif_id = mifOrdSbloccaElabId;

    -- restituisco ordAgg=0
    --return ordAgg;
    return messaggioRisultato;
 end if;

 -- 11.04.2018 Sofia SIAC-5934
 strMessaggio:='Aggiornamento tabella  mif_t_ordinativo_sbloccato per data firma.';
 update mif_t_ordinativo_sbloccato m
 set    mif_ord_data_firma=FIRMA.ord_firma_data
 from
 (
  select r.ord_id,max(r.ord_firma_data) ord_firma_data
  from siac_r_ordinativo_firma r,mif_t_ordinativo_sbloccato m1
  where m1.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId
  and   m1.ente_proprietario_id=enteProprietarioId
  and   r.ord_id=m1.mif_ord_id
  and   m1.data_cancellazione is null
  and   m1.validita_fine is null
  and   r.data_cancellazione is null
  and   r.validita_fine is  null
  group by r.ord_id
 ) FIRMA
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId
 and   m.ente_proprietario_id=enteProprietarioId
 and   FIRMA.ord_id=m.mif_ord_id
 and   m.data_cancellazione is null
 and   m.validita_fine is null;


 strMessaggio:='Inserimento tabella mif_t_ordinativo_sbloccato_log.';
 insert into mif_t_ordinativo_sbloccato_log
 (mif_ord_sblocca_elab_id, mif_ord_id,mif_ord_anno,mif_ord_numero, mif_ord_tipo_id,
  mif_ord_trasm_oil_data,mif_ord_emissione_data,
  mif_ord_spostamento_data, -- 10.04.2018 Sofia SIAC-5934
  mif_ord_inizio_st_ins,mif_ord_fine_st_ins,
  ente_proprietario_id,login_operazione,validita_inizio )
 (select  mifOrdSbloccaElabId,m.mif_ord_id,ord.ord_anno, ord.ord_numero,ord.ord_tipo_id,
          ord.ord_trasm_oil_data, ord.ord_emissione_data,
          ord.ord_spostamento_data, -- 10.04.2018 Sofia SIAC-5934
          ri.validita_inizio,ri.validita_fine,
          ord.ente_proprietario_id, loginOperazione,now()
  from mif_t_ordinativo_sbloccato m,   siac_t_ordinativo ord,
       siac_r_ordinativo_stato ri , siac_d_ordinativo_stato si
  where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
  and   m.ente_proprietario_id=enteProprietarioId
  and   m.data_cancellazione is null
  and   m.validita_fine is null
  and   ord.ord_id=m.mif_ord_id
  and   ri.ord_id=ord.ord_id
  and   si.ord_stato_id=ri.ord_stato_id
  and   si.ord_stato_code='I'
  and   ri.data_cancellazione is null
  and   si.data_cancellazione is null
  and   si.validita_fine is null
 );

 strMessaggio:='Aggiornamento tabella mif_t_ordinativo_ritrasmetti_log [stato T].';
 update mif_t_ordinativo_sbloccato_log m
 set mif_ord_inizio_st_tr=r.validita_inizio,mif_ord_fine_st_tr=r.validita_fine
 from siac_d_ordinativo_stato stato, siac_r_ordinativo_stato r
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioId
 and   r.ord_id=m.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='T'
 and   r.data_cancellazione is null
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null;

 strMessaggio:='Aggiornamento tabella mif_t_ordinativo_ritrasmetti_log [stato A].';
 update mif_t_ordinativo_sbloccato_log m
 set mif_ord_inizio_st_ann=r.validita_inizio,mif_ord_fine_st_ann=r.validita_fine
 from siac_d_ordinativo_stato stato, siac_r_ordinativo_stato r
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioId
 and   r.ord_id=m.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='A'
 and   r.data_cancellazione is null
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null;

 -- 11.04.2018 Sofia SIAC-5934
 strMessaggio:='Aggiornamento tabella mif_t_ordinativo_ritrasmetti_log [stato F].';
 update mif_t_ordinativo_sbloccato_log m
 set mif_ord_inizio_st_firma=r.validita_inizio,mif_ord_fine_st_firma=r.validita_fine
 from siac_d_ordinativo_stato stato, siac_r_ordinativo_stato r
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioId
 and   r.ord_id=m.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='F'
 and   r.data_cancellazione is null
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null;

 -- 11.04.2018 Sofia SIAC-5934 - chiusura stati F,T per ritrasmette anche ordinativi con FIRMA
 strMessaggio:='Chiusura stati F-T [siac_r_ordinativo_stato].';
 update siac_r_ordinativo_stato r
 set validita_fine=now(), login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_stato stato,  mif_t_ordinativo_sbloccato sb
 where sb.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   sb.ente_proprietario_id= enteProprietarioId
 and   sb.mif_ord_trasm_oil_data is not null
 --and   sb.mif_ord_spostamento_data is null -- 10.04.2018 Sofia SIAC-5934 - se sblocco di uno spostamento non deve perdere T
 and   r.ord_id=sb.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code in ('F','T')
 and   sb.data_cancellazione is null
 and   sb.validita_fine is null
 and   r.data_cancellazione is null
 and   r.validita_fine is  null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null
 and not exists (select 1 from siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                 where r1.ord_id=r.ord_id
                 and   r1.data_cancellazione is null
                 and   s1.ord_stato_id=r1.ord_stato_id
                 and   s1.ord_stato_code!='F'
                 and   r1.validita_inizio>=r.validita_inizio
                 and   r1.validita_fine is null)
 and exists (select 1 from siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                 where r1.ord_id=r.ord_id
                 and   s1.ord_stato_id=r1.ord_stato_id
                 and   s1.ord_stato_code='F'
                 and   r1.data_cancellazione is null
                 and   r1.validita_fine is null);

 -- 10.04.2018 Sofia SIAC-5934 - commentato delete , meglio update per non perdere traccia
 -- cancellazione stato T - se non esistono stati successivi aperti diversi da T
 /*strMessaggio:='Cancellazione stati T [siac_r_ordinativo_stato].';
 delete from siac_r_ordinativo_stato r
  using siac_d_ordinativo_stato stato,  mif_t_ordinativo_sbloccato sb
 where sb.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   sb.ente_proprietario_id= enteProprietarioId
 and   sb.mif_ord_trasm_oil_data is not null
 and   sb.mif_ord_spostamento_data is null
 and   r.ord_id=sb.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='T'
 and   sb.data_cancellazione is null
 and   sb.validita_fine is null
 and   r.data_cancellazione is null
 and   r.validita_fine is  null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null
 and not exists (select 1 from siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                 where r1.ord_id=r.ord_id
                 and   r1.data_cancellazione is null
                 and   s1.ord_stato_id=r1.ord_stato_id
                 and   s1.ord_stato_code!='T'
                 and   r1.validita_inizio>=r.validita_inizio
                 and   r1.validita_fine is null);*/

 -- 11.04.2018 Sofia SIAC-5934 - sostituito delete con update
 strMessaggio:='Chiusura stati T [siac_r_ordinativo_stato].';
 update siac_r_ordinativo_stato r
 set validita_fine=now(), login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_stato stato,  mif_t_ordinativo_sbloccato sb
 where sb.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   sb.ente_proprietario_id= enteProprietarioId
 and   sb.mif_ord_trasm_oil_data is not null -- da verificare
 and   sb.mif_ord_spostamento_data is null -- 10.04.2018 Sofia SIAC-5934 - se sblocco di uno spostamento non deve perdere T
 and   r.ord_id=sb.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='T'
 and   sb.data_cancellazione is null
 and   sb.validita_fine is null
 and   r.data_cancellazione is null
 and   r.validita_fine is  null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null
 and   not exists (select 1 from siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                 where r1.ord_id=r.ord_id
                 and   r1.data_cancellazione is null
                 and   s1.ord_stato_id=r1.ord_stato_id
                 and   s1.ord_stato_code!='T'
                 and   r1.validita_inizio>=r.validita_inizio
                 and   r1.validita_fine is null);

 -- aggiornamento stato I - riapertura se non esistono stati successivi aperti diversi da I
 strMessaggio:='Aggiornamento stati I per riapertura.';
 update siac_r_ordinativo_stato r
 set validita_fine=null, login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_stato stato, mif_t_ordinativo_sbloccato sb
 where sb.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   sb.ente_proprietario_id= enteProprietarioId
 and   sb.mif_ord_trasm_oil_data is not null
 and   r.ord_id=sb.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='I'
 and   r.data_cancellazione is null
 and   r.validita_fine is not null
 and   sb.data_cancellazione is null
 and   sb.validita_fine is null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null
 and not exists (select 1 from siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                 where r1.ord_id=r.ord_id
                 and   r1.data_cancellazione is null
                 and   s1.ord_stato_id=r1.ord_stato_id
                 and   s1.ord_stato_code!='I'
                 and   r1.validita_inizio>=r.validita_inizio
                 and   r1.validita_fine is null);

 -- (1) ord_trasm_oil_data=null
 -- aggiornamento mif_ord_sbloccato=true
 strMessaggio:='Aggiornamento mif_ord_sbloccato per ord_trasm_oil_data [null] per trasmissione da I.';
 update mif_t_ordinativo_sbloccato m
 set mif_ord_sbloccato=true
 from siac_t_ordinativo ord
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   exists (select 1 from siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
               where r.ord_id=ord.ord_id
               and   r.data_cancellazione is null
               and   s.ord_stato_id=r.ord_stato_id
               and   s.ord_stato_code='I'
               and   r.validita_fine is null);

 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = null, se esiste stato I aperto
 strMessaggio:='Aggiornamento ord_trasm_oil_data [null] per trasmissione da I.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=null,login_operazione=loginOperazione, data_modifica=now()
 from mif_t_ordinativo_sbloccato m
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   exists (select 1 from siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
               where r.ord_id=ord.ord_id
               and   r.data_cancellazione is null
               and   s.ord_stato_id=r.ord_stato_id
               and   s.ord_stato_code='I'
               and   r.validita_fine is null);



 -- (2) ord_trasm_oil_data=null
  -- aggiornamento mif_ord_sbloccato=true
 strMessaggio:='Aggiornamento mif_ord_sbloccato per ord_trasm_oil_data [null] per trasmissione da stato A.';
 update mif_t_ordinativo_sbloccato m
 set mif_ord_sbloccato=true
 from  siac_t_ordinativo ord
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   not exists (select 1 from siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
				   where r.ord_id=ord.ord_id
				   and   r.data_cancellazione is null
				   and   s.ord_stato_id=r.ord_stato_id
				   and   s.ord_stato_code='T');

 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = null
 -- se non esiste stato T (es. annullamento prima di trasmissione )
 -- I --> A
 strMessaggio:='Aggiornamento ord_trasm_oil_data [null] per trasmissione da stato A.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=null,login_operazione=loginOperazione, data_modifica=now()
 from  mif_t_ordinativo_sbloccato m
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   not exists (select 1 from siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
				   where r.ord_id=ord.ord_id
				   -- and   r.data_cancellazione is null -- 18.04.2018 Sofia commentato in quanto adesso ANNULLAMENTO cancellare le rel.
				   and   s.ord_stato_id=r.ord_stato_id
				   and   s.ord_stato_code='T');


 -- (3) ord_trasm_oil_data=validita_inizio dello stato T
 -- aggiornamento mif_ord_sbloccato=true
 strMessaggio:='Aggiornamento mif_ord_sbloccato per ord_trasm_oil_data [validita_inizio(statoT)] per nuova trasmissione.';
 update mif_t_ordinativo_sbloccato m
 set mif_ord_sbloccato=true
 from siac_t_ordinativo ord,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   r.ord_id=ord.ord_id
 and   r.data_cancellazione is null
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null;

 -- 18.04.2018 Sofia - queste due update dovrebbero servire per sblocca degli annullati dopo trasmissione
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = validita_inizio(statoT)
 -- se esiste stato  T e non esiste data_spostamento
 strMessaggio:='Aggiornamento ord_trasm_oil_data [validita_inizio(statoT)] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=r.validita_inizio,login_operazione=loginOperazione, data_modifica=now()
 from mif_t_ordinativo_sbloccato m,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   m.mif_ord_spostamento_data is null -- 16.04.2018 Sofia SIAC-5934
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   r.ord_id=ord.ord_id
 --and   r.data_cancellazione is null -- 18.04.2018 Sofia commentato in quanto adesso ANNULLAMENTO cancellare le rel.
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null;

 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = data_emissione
 -- se esiste stato  T e esiste data_spostamento
 strMessaggio:='Aggiornamento ord_trasm_oil_data [data_emissione] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=ord.ord_emissione_data,login_operazione=loginOperazione, data_modifica=now()
 from mif_t_ordinativo_sbloccato m,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   m.mif_ord_spostamento_data is not null -- 16.04.2018 Sofia SIAC-5934
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   r.ord_id=ord.ord_id
-- and   r.data_cancellazione is null -- 18.04.2018 Sofia commentato in quanto adesso ANNULLAMENTO cancellare le rel.
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null;


 -- (4) ord_trasm_oil_data=validita_inizio dello stato T
 -- aggiornamento mif_ord_sbloccato=true
 strMessaggio:='Aggiornamento mif_ord_sbloccato per ord_trasm_oil_data [validita_inizio(statoT)] per nuova trasmissione.';
 update mif_t_ordinativo_sbloccato m
 set mif_ord_sbloccato=true
 from siac_t_ordinativo ord,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   r.ord_id=ord.ord_id
 and   r.data_cancellazione is null
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   not exists (select 1 from  siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                   where  r1.ord_id=ord.ord_id
				   and   s1.ord_stato_id=r1.ord_stato_id
				   and   s1.ord_stato_code='A'
				   and   r1.validita_inizio>=r.validita_inizio
				   and   r1.data_cancellazione is null
				   and   s1.data_cancellazione is null
				   and   s1.validita_fine is null);

 -- 18.04.2018 Sofia - queste due update dovrebbero servire per sblocca di quietanzati
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = validita_inizio(statoT)
 -- se esiste stato T e non esiste stato A successivo
 strMessaggio:='Aggiornamento ord_trasm_oil_data [validita_inizio(statoT)] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=r.validita_inizio,login_operazione=loginOperazione, data_modifica=now()
 from mif_t_ordinativo_sbloccato m,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   ord.ord_spostamento_data is null -- 16.04.2018 Sofia SIAC-5934
 and   r.ord_id=ord.ord_id
 and   r.data_cancellazione is null
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   not exists (select 1 from  siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                   where  r1.ord_id=ord.ord_id
				   and   s1.ord_stato_id=r1.ord_stato_id
				   and   s1.ord_stato_code='A'
				   and   r1.validita_inizio>=r.validita_inizio
				   and   r1.data_cancellazione is null
				   and   s1.data_cancellazione is null
				   and   s1.validita_fine is null);

 -- 16.04.2018 Sofia SIAC-5934
 strMessaggio:='Aggiornamento ord_trasm_oil_data [data_emissione] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=ord.ord_emissione_data,login_operazione=loginOperazione, data_modifica=now()
 from mif_t_ordinativo_sbloccato m,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioid
 and   m.mif_ord_trasm_oil_data is not null
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   ord.ord_spostamento_data is not null -- 16.04.2018 Sofia SIAC-5934
 and   r.ord_id=ord.ord_id
 and   r.data_cancellazione is null
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   m.validita_fine is null
 and   ord.data_cancellazione is null
 and   ord.validita_fine is null
 and   not exists (select 1 from  siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                   where  r1.ord_id=ord.ord_id
				   and   s1.ord_stato_id=r1.ord_stato_id
				   and   s1.ord_stato_code='A'
				   and   r1.validita_inizio>=r.validita_inizio
				   and   r1.data_cancellazione is null
				   and   s1.data_cancellazione is null
				   and   s1.validita_fine is null);


 strMessaggio:='Calcolo numero ordinativi sbloccati.';
 select count(*) into ordAgg
 from mif_t_ordinativo_sbloccato m
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioId
 and   m.mif_ord_sbloccato=true
 and   m.data_cancellazione is null
 and   m.validita_fine is null;

 if ordAgg is null then
  ordAgg:=0;
 end if;


 strMessaggio:='Cancellazione logica mif_t_ordinativo_ritrasmetti ord_tipo_code='||ordCodeTipo||'.';
 update mif_t_ordinativo_sbloccato m
 set validita_fine=now()
 where m.mif_ord_sblocca_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioId
 and   m.data_cancellazione is null
 and   m.validita_fine is null;

 strMessaggio:='Aggiornamento mif_t_flusso_elaborato per sblocco dati tipo flusso='||tipoMif||'. Tipo sblocco '||SBLOCCA_MIF_TIPO||'.';
 update mif_t_flusso_elaborato
 set flusso_elab_mif_esito='OK',
     flusso_elab_mif_esito_msg=upper('Elaborazione conclusa stato  OK per sblocco dati tipo flusso '||tipoMif||'. Ordinativi sbloccati= '||ordAgg||'.'),
     validita_fine=now(),
     flusso_elab_mif_num_ord_elab=ordAgg
 where flusso_elab_mif_id = mifOrdSbloccaElabId;


-- return ordAgg;
 return messaggioRisultato;

exception
    when RAISE_EXCEPTION THEN
	   messaggioRisultato:=
       strMessaggioFinale||' '||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||'.' ;
	   messaggioRisultato:=upper(messaggioRisultato);
       raise notice 'messaggioRisultato=%',messaggioRisultato;
       ordAgg:=-1;
--       return ordAgg;
       return messaggioRisultato;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||' '||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||'.';
        messaggioRisultato:=upper(messaggioRisultato);
        raise notice 'messaggioRisultato=%',messaggioRisultato;
        ordAgg:=-1;
--        return ordAgg;
	    return messaggioRisultato;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||' '||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||'.';
        messaggioRisultato:=upper(messaggioRisultato);
		raise notice 'messaggioRisultato=%',messaggioRisultato;
        ordAgg:=-1;
--        return ordAgg;
        return messaggioRisultato;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||'.' ;
        messaggioRisultato:=upper(messaggioRisultato);
        raise notice 'messaggioRisultato=%',messaggioRisultato;
        ordAgg:=-1;
--        return ordAgg;
		return messaggioRisultato;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;