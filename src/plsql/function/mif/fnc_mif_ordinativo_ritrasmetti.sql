/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_mif_ordinativo_ritrasmetti
(
  enteProprietarioId integer,
  loginOperazione varchar,
  ordCodeTipo varchar,
  ordTrasmOilData timestamp,
  out ordAgg integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE

 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 codResult   integer :=null;
BEGIN

 codiceRisultato:=0;
 messaggioRisultato:='';
 ordAgg:=0;


 strMessaggioFinale :='Ritrasmissione Ordinativi tipo='||ordCodeTipo||'.';
 if ordTrasmOilData is not null then
 	strMessaggioFinale:=strMessaggioFinale||' Trasmessi il '||ordTrasmOilData||'.';
 end if;
 strMessaggioFinale:=strMessaggioFinale||' Sblocco dati.';

 if ordTrasmOilData is not null then
 /*   strMessaggio:='Pulizia tabella mif_t_ordinativo_ritrasmetti.';
    delete from mif_t_ordinativo_ritrasmetti m
    where m.ente_proprietario_id=enteProprietarioId
    and   m.data_cancellazione is null
    and exists (select 1 from siac_d_ordinativo_tipo tipo
          	   where tipo.ord_tipo_id=m.mif_ord_id
		       and   tipo.ord_tipo_code=ordCodeTipo
               and   tipo.data_cancellazione is null
               and   tipo.validita_fine is null
               );*/
	strMessaggio:='Cancellazione logica mif_t_ordinativo_ritrasmetti ord_tipo_code='||ordCodeTipo||'.';
	update mif_t_ordinativo_ritrasmetti m
	set data_cancellazione=now()
	from siac_d_ordinativo_tipo tipo
	where m.ente_proprietario_id=enteProprietarioId
	and   m.data_cancellazione is null
	and   tipo.ord_tipo_id=m.mif_ord_tipo_id
	and   tipo.ord_tipo_code=ordCodeTipo
	and   tipo.data_cancellazione is null
	and   tipo.validita_fine is NULL;

    strMessaggio:='Inserimento tabella mif_t_ordinativo_ritrasmetti.';
 	insert into mif_t_ordinativo_ritrasmetti
    (mif_ord_id, mif_ord_tipo_id,ente_proprietario_id, login_operazione)
    select ord.ord_id,ord.ord_tipo_id, ord.ente_proprietario_id,loginOperazione
    from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo
    where ord.ente_proprietario_id=enteProprietarioId
    and   tipo.ord_tipo_id=ord.ord_tipo_id
    and   tipo.ord_tipo_code=ordCodeTipo
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
    and   date_trunc('DAY',ord.ord_trasm_oil_data)=ordTrasmOilData;
 end if;

 -- controllo di presenza di ordinativi in mif_t_ordinativo_ritrasmetti per ordCodeTipo
 strMessaggio:='Controllo presenza ordinativi in  tabella mif_t_ordinativo_ritrasmetti.';
 select 1 into codResult
 from mif_t_ordinativo_ritrasmetti m,  siac_d_ordinativo_tipo tipo
 where tipo.ord_tipo_id=m.mif_ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   tipo.data_cancellazione is null
 and   tipo.validita_fine is null
 and   m.data_cancellazione is null;
 if codResult is null then
 	raise exception ' Dati non presenti.';
 end if;


 strMessaggio:='Inserimento tabella mif_t_ordinativo_ritrasmetti_log.';
 insert into mif_t_ordinativo_ritrasmetti_log
 (mif_ord_id,mif_ord_anno,mif_ord_numero, mif_ord_tipo_id,
  mif_ord_trasm_oil_data,mif_ord_emissione_data,
  mif_ord_inizio_st_ins,mif_ord_fine_st_ins,
  ente_proprietario_id,login_operazione,validita_inizio )
 (select  m.mif_ord_id,ord.ord_anno, ord.ord_numero,ord.ord_tipo_id,
          ord.ord_trasm_oil_data, ord.ord_emissione_data,
          ri.validita_inizio,ri.validita_fine,
          ord.ente_proprietario_id, loginOperazione,now()
  from mif_t_ordinativo_ritrasmetti m, siac_d_ordinativo_tipo tipo,siac_t_ordinativo ord,
       siac_r_ordinativo_stato ri , siac_d_ordinativo_stato si
  where m.ente_proprietario_id=enteProprietarioId
  and   m.data_cancellazione is null
  and   ord.ord_id=m.mif_ord_id
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   ri.ord_id=ord.ord_id
  and   si.ord_stato_id=ri.ord_stato_id
  and   si.ord_stato_code='I'
  and   tipo.data_cancellazione is null
  and   tipo.validita_fine is null
  and   ri.data_cancellazione is null
  and   si.data_cancellazione is null
  and   si.validita_fine is null
 );

 strMessaggio:='Aggiornamento tabella mif_t_ordinativo_ritrasmetti_log [stato T].';
 update mif_t_ordinativo_ritrasmetti_log m
 set mif_ord_inizio_st_tr=r.validita_inizio,mif_ord_fine_st_tr=r.validita_fine
 from siac_d_ordinativo_stato stato, siac_r_ordinativo_stato r
 where r.ord_id=m.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='T'
 and   r.data_cancellazione is null
 and   m.data_cancellazione is null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null;

 strMessaggio:='Aggiornamento tabella mif_t_ordinativo_ritrasmetti_log [stato A].';
 update mif_t_ordinativo_ritrasmetti_log m
 set mif_ord_inizio_st_ann=r.validita_inizio,mif_ord_fine_st_ann=r.validita_fine
 from siac_d_ordinativo_stato stato, siac_r_ordinativo_stato r
 where r.ord_id=m.mif_ord_id
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='A'
 and   r.data_cancellazione is null
 and   m.data_cancellazione is null
 and   stato.data_cancellazione is null
 and   stato.validita_fine is null;


 -- cancellazione stato T - se non esistono stati successivi aperti diversi da T
 strMessaggio:='Cancellazione stati T.';
 delete from siac_r_ordinativo_stato r
 where r.ente_proprietario_id=enteProprietarioId
 and   r.data_cancellazione is null
 and   r.validita_fine is  null
 and exists (select 1 from siac_d_ordinativo_stato stato
		 	 where stato.ord_stato_id=r.ord_stato_id
			 and   stato.ord_stato_code='T')
 and exists (select 1 from mif_t_ordinativo_ritrasmetti_log log, siac_d_ordinativo_tipo tipo, mif_t_ordinativo_ritrasmetti m
             where log.mif_ord_id=r.ord_id
             and   log.mif_ord_trasm_oil_data is not null
	         and   tipo.ord_tipo_id=m.mif_ord_tipo_id
             and   tipo.ord_tipo_code=ordCodeTipo
             and   m.mif_ord_id=r.ord_id
             and   m.data_cancellazione is null
             and   log.data_cancellazione is null
             and   tipo.data_cancellazione is null
             and   tipo.validita_fine is null)
 and not exists (select 1 from siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
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
 from siac_d_ordinativo_stato stato, mif_t_ordinativo_ritrasmetti_log log, siac_d_ordinativo_tipo tipo,
      mif_t_ordinativo_ritrasmetti m
 where r.ente_proprietario_id=enteProprietarioId
 and   r.data_cancellazione is null
 and   r.validita_fine is not null
 and   stato.ord_stato_id=r.ord_stato_id
 and   stato.ord_stato_code='I'
 and   log.mif_ord_id=r.ord_id
 and   log.mif_ord_trasm_oil_data is not null
 and   m.mif_ord_id=log.mif_ord_id
 and   tipo.ord_tipo_id=m.mif_ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   m.data_cancellazione is null
 and   log.data_cancellazione is null
 and   tipo.data_cancellazione is null
 and   tipo.validita_fine is null
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
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = null, se esiste stato I aperto
 strMessaggio:='Aggiornamento ord_trasm_oil_data [null] per trasmissione da I.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=null,login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_tipo tipo, mif_t_ordinativo_ritrasmetti m
 where m.ente_proprietario_id=enteProprietarioid
 and   ord.ord_id=m.mif_ord_id
 and   ord.ord_trasm_oil_data is not null
 and   tipo.ord_tipo_id=ord.ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   m.data_cancellazione is null
 and   ord.data_cancellazione is null
 and   exists (select 1 from siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
               where r.ord_id=ord.ord_id
               and   r.data_cancellazione is null
               and   s.ord_stato_id=r.ord_stato_id
               and   s.ord_stato_code='I'
               and   r.validita_fine is null);

 -- 10.03.2016 Sofia - anche questo mi sembra che non serva, anzi mi sembra sbagliato se non esiste il T vuole dire
 -- che I, A annullato, emesso annullato e trasmesso, quindi la data di trasmissione deve essere ripulita
 -- come fatto di seguito
 -- (2) ord_trasm_oil_data=ord_emissione_data
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = siac_t_ordinativo.ord_emissione_data
 -- se non esiste stato T (es. annullamento prima di trasmissione )
 /*strMessaggio:='Aggiornamento ord_trasm_oil_data [ord_emissione_data] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=ord.ord_emissione_data,login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_tipo tipo, mif_t_ordinativo_ritrasmetti m
 where ord.ente_proprietario_id=enteProprietarioid
 and   ord.ord_trasm_oil_data is not null
 and   tipo.ord_tipo_id=ord.ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   m.mif_ord_id=ord.ord_id
 and   m.data_cancellazione is null
 and   ord.data_cancellazione is null
 and   not exists (select 1 from siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
				   where r.ord_id=ord.ord_id
				   and   r.data_cancellazione is null
				   and   s.ord_stato_id=r.ord_stato_id
				   and   s.ord_stato_code='T');*/

 -- 10.03.2016 Sofia - sostituisce il precedente
 -- (2) ord_trasm_oil_data=null
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = null
 -- se non esiste stato T (es. annullamento prima di trasmissione )
 -- I --> A
 strMessaggio:='Aggiornamento ord_trasm_oil_data [null] per trasmissione da stato A.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=null,login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_tipo tipo, mif_t_ordinativo_ritrasmetti m
 where ord.ente_proprietario_id=enteProprietarioid
 and   ord.ord_trasm_oil_data is not null
 and   tipo.ord_tipo_id=ord.ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   m.mif_ord_id=ord.ord_id
 and   m.data_cancellazione is null
 and   ord.data_cancellazione is null
 and   not exists (select 1 from siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
				   where r.ord_id=ord.ord_id
				   and   r.data_cancellazione is null
				   and   s.ord_stato_id=r.ord_stato_id
				   and   s.ord_stato_code='T');


 -- (3) ord_trasm_oil_data=validita_inizio dello stato T
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = validita_inizio(statoT)
 -- se esiste stato  T
 strMessaggio:='Aggiornamento ord_trasm_oil_data [validita_inizio(statoT)] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=r.validita_inizio,login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_tipo tipo, mif_t_ordinativo_ritrasmetti m,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where ord.ente_proprietario_id=enteProprietarioId
 and   ord.ord_trasm_oil_data is not null
 and   tipo.ord_tipo_id=ord.ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   m.mif_ord_id=ord.ord_id
 and   r.ord_id=ord.ord_id
 and   r.data_cancellazione is null
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   ord.data_cancellazione is null;

 -- 10.03.2016 Sofia i successivi non mi sembrano corretti sostituiti con il 3 precedente
 -- per soddisfare i casi della ritrasmissione entrate CRP del flusso del 08.03.2016
 -- (3) ord_trasm_oil_data=validita_inizio dello stato A
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = validita_inizio(statoA)
 -- se esiste stato A successivo allo stato T
 /*strMessaggio:='Aggiornamento ord_trasm_oil_data [validita_inizio(statoA)] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=r1.validita_inizio,login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_tipo tipo, mif_t_ordinativo_ritrasmetti m,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s,
      siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
 where ord.ente_proprietario_id=enteProprietarioId
 and   ord.ord_trasm_oil_data is not null
 and   tipo.ord_tipo_id=ord.ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   m.mif_ord_id=ord.ord_id
 and   r.ord_id=ord.ord_id
 and   r.data_cancellazione is null
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   ord.data_cancellazione is null
 and   r1.ord_id=ord.ord_id
 and   s1.ord_stato_id=r1.ord_stato_id
 and   s1.ord_stato_code='A'
 and   r1.validita_inizio>=r.validita_inizio
 and   r1.data_cancellazione is null
 and   s1.data_cancellazione is null
 and   s1.validita_fine is null;


 -- (4) ord_trasm_oil_data=validita_inizio dello stato T
 -- aggiornamento siac_t_ordinativo.ord_trasm_oil_data = validita_inizio(statoT)
 -- se esiste stato T e non esiste stato A successivo
 strMessaggio:='Aggiornamento ord_trasm_oil_data [validita_inizio(statoT)] per nuova trasmissione.';
 update siac_t_ordinativo ord
 set ord_trasm_oil_data=r.validita_inizio,login_operazione=loginOperazione, data_modifica=now()
 from siac_d_ordinativo_tipo tipo, mif_t_ordinativo_ritrasmetti m,
      siac_r_ordinativo_stato r, siac_d_ordinativo_stato s
 where ord.ente_proprietario_id=enteProprietarioId
 and   ord.ord_trasm_oil_data is not null
 and   tipo.ord_tipo_id=ord.ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   m.mif_ord_id=ord.ord_id
 and   r.ord_id=ord.ord_id
 and   r.data_cancellazione is null
 and   s.ord_stato_id=r.ord_stato_id
 and   s.ord_stato_code='T'
 and   m.data_cancellazione is null
 and   ord.data_cancellazione is null
 and   not exists (select 1 from  siac_r_ordinativo_stato r1, siac_d_ordinativo_stato s1
                   where  r1.ord_id=ord.ord_id
				   and   s1.ord_stato_id=r1.ord_stato_id
				   and   s1.ord_stato_code='A'
				   and   r1.validita_inizio>=r.validita_inizio
				   and   r1.data_cancellazione is null
				   and   s1.data_cancellazione is null
				   and   s1.validita_fine is null);*/




 strMessaggio:='Calcolo numero ordinativi modificati.';
 select count(*) into ordAgg
 from mif_t_ordinativo_ritrasmetti m, siac_d_ordinativo_tipo tipo
 where m.ente_proprietario_id=enteProprietarioId
 and   m.data_cancellazione is null
 and   tipo.ord_tipo_id=m.mif_ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   tipo.data_cancellazione is null
 and   tipo.validita_fine is NULL;

 if ordAgg is null then
  ordAgg:=0;
 end if;

 strMessaggio:='Cancellazione logica mif_t_ordinativo_ritrasmetti ord_tipo_code='||ordCodeTipo||'.';
 update mif_t_ordinativo_ritrasmetti m
 set data_cancellazione=now()
 from siac_d_ordinativo_tipo tipo
 where m.ente_proprietario_id=enteProprietarioId
 and   m.data_cancellazione is null
 and   tipo.ord_tipo_id=m.mif_ord_tipo_id
 and   tipo.ord_tipo_code=ordCodeTipo
 and   tipo.data_cancellazione is null
 and   tipo.validita_fine is NULL;

 return;


exception
    when RAISE_EXCEPTION THEN
       messaggioRisultato:=
       	strMessaggioFinale||' '||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'')||'.' ;
       codiceRisultato:=-1;
	   messaggioRisultato:=upper(messaggioRisultato);

       return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||' '||coalesce(strMessaggio,'')||' Nessun dato presente in archivio '||'.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||' '||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio '||'.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500)||'.' ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
