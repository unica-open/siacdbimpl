/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
 19.04.2016 Sofia - creato tabelle e tipi flusso, compilare plSql
-- 01.04.2016 Sofia - sblocca ordinativi da ritrasmettere
-- inserisce record in mif_t_elaborazione_flusso per tipo=RITRASM_MIF per tracciare elaborazione_id in tabelle di ritrasmissione dati
-- inserisce ordinativi in mif_ordinativo_ritrasmesso in base a elenco passato in ordArray e ordCodeTipo
-- chiude mif_t_elaborazione_flusso
-- elaborazione OK per ordAgg>=0
-- restituisce
-- -mifOrdSbloccaElabId  se non ha inserito nessun record in mif_t_elaborazione_flusso,
-- ovvero non ci sono dati da trasmettere per gli id e tipo passati
-- mifOrdSbloccaElabId>0   con id_elaborazione per tipo=RITRASM_MIF se ha inserito record e elaborazione ok
-- mifOrdSbloccaElabId deve essere restituito per poi essere passato
-- alla fnc_mif_ordinativo_spesa, fnc_mif_ordinativo_entrata per ritrasmettere solo gli id interessati
-- elaborazione KO per 0
-- restituisce  0  in caso di errore

/*drop FUNCTION fnc_mif_ordinativo_ritrasm
(
  enteProprietarioId integer,
  loginOperazione varchar,
  ordCodeTipo varchar,
  ordArray integer[]
);*/

/*drop function fnc_mif_ordinativo_ritrasm
(
  enteProprietarioId integer,
  loginOperazione varchar,
  ordCodeTipo varchar,
  ordArray text
);*/

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_ritrasm
(
  enteProprietarioId integer,
  loginOperazione varchar,
  ordCodeTipo varchar,
  ordArray text,
  out mifOrdRitrasmElabId integer,
  out mifOrdRitrasm integer,
  out codiceRisultato integer,
  out messaggioRisultato  varchar
)
RETURNS record AS
$body$
DECLARE

 ELAB_MIF_ESITO_IN CONSTANT  varchar :='IN';
 MANDMIF_TIPO  CONSTANT  varchar :='MANDMIF';
 REVMIF_TIPO  CONSTANT  varchar :='REVMIF';
 SBLOCCA_MIF_TIPO  CONSTANT  varchar :='RITRASM_MIF';
 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 codResult   integer :=null;
 mifOrdSbloccaElabId integer :=null;

 tipoMif varchar(20):=null;

 ordAgg integer:=0;


BEGIN

 messaggioRisultato:='';
 codiceRisultato:=0;
 mifOrdRitrasmElabId:=0;
 mifOrdRitrasm:=0;

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
         'Elaborazione in corso per ritramissione dati tipo flusso '||tipoMif,
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

 insert into mif_t_ordinativo_ritrasmesso
 ( mif_ord_id,
   mif_ord_tipo_id,
   mif_ord_trasm_oil_data,
   mif_ord_ritrasm_elab_id,
   validita_inizio,
   ente_proprietario_id,
   login_operazione
 )
 (select fnc.ord_id, fnc.ord_tipo_id,fnc.ord_trasm_oil_data, mifOrdSbloccaElabId, now(),enteProprietarioId,loginOperazione
  from fnc_mif_ordinativo_get_cursor(enteProprietarioId,ordCodeTipo,ordArray) fnc);

 -- controllo di presenza di ordinativi in mif_t_ordinativo_ritrasmesso per ordCodeTipo e mifOrdSbloccaElabId validi
 strMessaggio:='Controllo presenza ordinativi in  tabella mif_t_ordinativo_ritrasmesso validi.';
 select 1 into codResult
 from mif_t_ordinativo_ritrasmesso m,  siac_d_ordinativo_tipo tipo
 where m.mif_ord_ritrasm_elab_id=mifOrdSbloccaElabId
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
    strMessaggio:='Chiusura elaborazione ritrasmissione dati tipo flusso '||tipomif||'.Nessun ordinativo da ritrasmettere.';
    update mif_t_flusso_elaborato
    set flusso_elab_mif_esito='OK',
        flusso_elab_mif_esito_msg=
          upper('Elaborazione conclusa OK per ritramissione dati tipo flusso '||tipoMif||'.Ordinativi da ritrasmettere= '||ordAgg||'.'||strMessaggio||' Nessun Ordinativo presente.'),
        validita_fine=now(),
        flusso_elab_mif_num_ord_elab=0
    where flusso_elab_mif_id = mifOrdSbloccaElabId;

    messaggioRisultato:=upper(strMessaggioFinale||' '||coalesce(strMessaggio,''));
    mifOrdRitrasmElabId:=mifOrdSbloccaElabId;

    return;
 end if;





 strMessaggio:='Calcolo numero ordinativi da ritrasmettere.';
 select count(*) into ordAgg
 from mif_t_ordinativo_ritrasmesso m
 where m.mif_ord_ritrasm_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioId
 and   m.data_cancellazione is null
 and   m.validita_fine is null;

 if ordAgg is null then
  ordAgg:=0;
 end if;


 /* non serve
 strMessaggio:='Cancellazione logica mif_t_ordinativo_ritrasmetti ord_tipo_code='||ordCodeTipo||'.';
 update mif_t_ordinativo_ritrasmesso m
 set validita_fine=now()
 where m.mif_ord_ritrasm_elab_id=mifOrdSbloccaElabId -- sbloccato per idSblocco
 and   m.ente_proprietario_id=enteProprietarioId
 and   m.data_cancellazione is null
 and   m.validita_fine is null;*/

 strMessaggio:='Aggiornamento mif_t_flusso_elaborato per sblocco dati tipo flusso='||tipoMif||'. Tipo sblocco '||SBLOCCA_MIF_TIPO||'.';
 update mif_t_flusso_elaborato
 set flusso_elab_mif_esito='OK',
     flusso_elab_mif_esito_msg=upper('Elaborazione conclusa stato  OK per ritrasmissione dati tipo flusso '||tipoMif||'. Ordinativi da ritrasmettere= '||ordAgg||'.'),
     validita_fine=now(),
     flusso_elab_mif_num_ord_elab=ordAgg
 where flusso_elab_mif_id = mifOrdSbloccaElabId;

 mifOrdRitrasmElabId:=mifOrdSbloccaElabId;
 mifOrdRitrasm:=ordAgg;
 messaggioRisultato:=upper(strMessaggioFinale||' '||upper('Elaborazione conclusa stato  OK per ritrasmissione dati tipo flusso '||tipoMif||'. Ordinativi da ritrasmettere= '||ordAgg||'.'));

 return;


exception
    when RAISE_EXCEPTION THEN
	   messaggioRisultato:=
       strMessaggioFinale||' '||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||'.' ;
	   messaggioRisultato:=upper(messaggioRisultato);
       raise notice 'messaggioRisultato=%',messaggioRisultato;
       --ordAgg:=0;
       --return ordAgg;
       codiceRisultato:=-1;
       mifOrdRitrasmElabId:=0;
       return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||' '||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||'.';
        messaggioRisultato:=upper(messaggioRisultato);
        raise notice 'messaggioRisultato=%',messaggioRisultato;
--        ordAgg:=0;
--        return ordAgg;
       codiceRisultato:=-1;
       mifOrdRitrasmElabId:=0;
       return;

     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||' '||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||'.';
        messaggioRisultato:=upper(messaggioRisultato);
		raise notice 'messaggioRisultato=%',messaggioRisultato;
--        ordAgg:=0;
--        return ordAgg;
       codiceRisultato:=-1;
       mifOrdRitrasmElabId:=0;
       return;

	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||'.' ;
        messaggioRisultato:=upper(messaggioRisultato);
        raise notice 'messaggioRisultato=%',messaggioRisultato;
--        ordAgg:=0;
--        return ordAgg;
       codiceRisultato:=-1;
       mifOrdRitrasmElabId:=0;
       return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;