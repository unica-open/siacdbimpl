/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 15.01.2018 Sofia - INIZIO

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_vincoli_elabora(
  enteProprietarioId     integer,
  annoBilancio           integer,
  faseBilElabId          integer,
  loginOperazione        varchar,
  dataElaborazione       timestamp,
  out codiceRisultato    integer,
  out messaggioRisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio       VARCHAR(1500):='';
    strMessaggioTemp   VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';
	dataInizioVal      timestamp:=null;
	codResult          integer:=null;

    IMP_MOVGEST_TIPO  CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO  CONSTANT varchar:='A';
    IMP_MOVGEST       CONSTANT varchar:='IMP';
    ACC_MOVGEST       CONSTANT varchar:='ACC';

    APE_GEST_VINCOLI    CONSTANT varchar:='APE_GEST_VINCOLI';

    bilancioPrecId    integer:=null;

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    dataInizioVal:= clock_timestamp();

    strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento vincoli da Gestione precedente. Anno bilancio='
                        ||annoBilancio::varchar||'. ELABORA.';


    codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_vincoli.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_vincoli fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessun  vincolo da creare.';
    end if;


	strMessaggio:='Inserimento LOG.';
    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id into strict bilancioPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;



    strMessaggio:='Verifica scarti per accertamento non esistente';
    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

	update  fase_bil_t_gest_apertura_vincoli fase
    set    fl_elab='X',
           scarto_code='ACC',
           scarto_desc='ACCERTAMENTO NON ESISTENTE O NON VALIDO'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   fase.movgest_ts_a_id is not null -- 06.12.2017 Sofia jira siac-5276
    and   not exists (select 1 from siac_t_movgest_ts ts, siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
                      where ts.movgest_ts_id=fase.movgest_ts_a_id
                      and   r.movgest_ts_id=ts.movgest_ts_id
                      and   stato.movgest_stato_id=r.movgest_stato_id
                      and   stato.movgest_stato_code!='A'
                      and   r.data_cancellazione is null
                      and   r.validita_fine is null
                      and   ts.data_cancellazione is null
                      and   ts.validita_fine is null
                     )
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    strMessaggio:='Verifica scarti per impegno non esistente';
    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


	update  fase_bil_t_gest_apertura_vincoli fase
    set    fl_elab='X',
           scarto_code='IMP',
           scarto_desc='IMPEGNO NON ESISTENTE O NON VALIDO'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   not exists (select 1 from siac_t_movgest_ts ts, siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
                      where ts.movgest_ts_id=fase.movgest_ts_b_id
                      and   r.movgest_ts_id=ts.movgest_ts_id
                      and   stato.movgest_stato_id=r.movgest_stato_id
                      and   stato.movgest_stato_code!='A'
                      and   r.data_cancellazione is null
                      and   r.validita_fine is null
                      and   ts.data_cancellazione is null
                      and   ts.validita_fine is null
                     )
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    strMessaggio:='Inserimento siac_r_movgest_ts. INIZIO.';
    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

	insert into siac_r_movgest_ts
    (
     movgest_ts_a_id,
     movgest_ts_b_id,
     movgest_ts_importo,
     avav_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (select fase.movgest_ts_a_id,
            fase.movgest_ts_b_id,
            fase.importo_vinc,
            fase.avav_id, -- 06.12.2017 Sofia jira siac-5276
            --dataInizioVal,
            clock_timestamp(), -- 12.01.2018 Sofia
            loginOperazione||'_APE_VINC@'||fase.fase_bil_gest_ape_vinc_id::varchar, -- 06.12.2017 Sofia jira siac-5276
            enteProprietarioId
     from fase_bil_t_gest_apertura_vincoli fase
     where fase.fase_bil_elab_id=faseBilElabId
     and   fase.fl_elab='N'
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
    );




    strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_vincoli.';
    update  fase_bil_t_gest_apertura_vincoli fase
    set    movgest_ts_r_id=r.movgest_ts_r_id,
           fl_elab='S'
    from  siac_r_movgest_ts r
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fl_elab='N'
    and   r.ente_proprietario_id=fase.ente_proprietario_id
    -- 06.12.2017 Sofia jira siac-5276
    and   r.login_operazione like '%_APE_VINC@%'
    and   substring(r.login_operazione , position('@' in r.login_operazione)+1)::integer=fase.fase_bil_gest_ape_vinc_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;


    strMessaggio:='Inserimento siac_r_movgest_ts. INIZIO.';
    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_VINCOLI||' IN CORSO IN-2.'
    where fase_bil_elab_id=faseBilElabId;

    codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


CREATE OR REPLACE FUNCTION fnc_mif_tipo_pagamento_splus( ordinativoId integer,
												   codicePaese varchar,
                                                   codiceItalia varchar,
                                                   codiceAreaSepa varchar,
                                                   codiceAreaExtraSepa varchar,
                                                   accreditoCodeCB varchar,
                                                   accreditoCodeREG varchar,
                                                   tipoPagamCompensa varchar,
 												   accreditoTipoId INTEGER,
                                                   accreditoGruppoCode varchar,
                                                   importoOrd       numeric,
                                                   pagamentoGFB     boolean,
                                                   dataElaborazione timestamp,
                                                   dataFineVal timestamp,
                                                   enteProprietarioId integer,
												   out codeTipoPagamento varchar,
                                                   out descTipoPagamento varchar,
                                                   out defRifDocEsterno boolean)
RETURNS record AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

isSepa boolean:=false;
isProvvisori boolean :=false;
isAllegatoCartaceo boolean :=false;
isCompensa boolean:=false;
codAreaSepa VARCHAR(50):=null;
accreditoTipoCode varchar(50):=null;
checkDati integer:=null;
accreditoCodeTes varchar(50):=null;
accreditoTipoOilId integer :=null;
accreditoCodePag varchar(50):=null;
accreditoDescPag varchar(200):=null;

ALLEG_CART_ATTR CONSTANT VARCHAR:='flagAllegatoCartaceo';

BEGIN

 codeTipoPagamento:=null;
 descTipoPagamento:=null;
 defRifDocEsterno:=false;



 -- codiceItalia valore presente in param
 -- codicePaese valorizzato se presente Iban
 -- codiceAreaSepa letto in param
 -- codiceAreaExtraSepa letto in param

-- raise notice 'ordinativoId=% ',ordinativoId;
-- raise notice 'codicePaese=% ',codicePaese;
-- raise notice 'codiceItalia=% ',codiceItalia;
-- raise notice 'codiceAreaSepa=% ',codiceAreaSepa;
-- raise notice 'codiceAreaExtraSepa=% ',codiceAreaExtraSepa;

 checkDati:=null;
 strMessaggio:='Lettura tipo pagamento ordinativo [siac_r_ordinativo_prov_cassa].';
 select distinct 1 into checkDati
 from siac_r_ordinativo_prov_cassa prov
 where prov.ord_id=ordinativoId
 and   prov.data_cancellazione is null
 and   prov.validita_fine is null;

 if checkDati is not null then
    	isProvvisori  :=true;
 end if;

 if isProvvisori = false then
  checkDati:=null;
  strMessaggio:='Verifica ordinativo compensazione.';
  select 1 into checkDati
  from siac_r_ordinativo rOrd, siac_t_ordinativo ord,siac_d_ordinativo_tipo tipo,
       siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato,
       siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod,
       siac_d_relaz_tipo tiporel
  where rord.ord_id_da=ordinativoId
  and   ord.ord_id=rord.ord_id_a
  and   tipo.ord_tipo_id=ord.ord_tipo_id
  and   tipo.ord_tipo_code='I'
  and   rstato.ord_id=ord.ord_id
  and   stato.ord_stato_id=rstato.ord_stato_id
  and   stato.ord_stato_code!='A'
  and   ts.ord_id=ord.ord_id
  and   det.ord_ts_id=ts.ord_ts_id
  and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
  and   tipod.ord_ts_det_tipo_code='A'
  and   tiporel.relaz_tipo_id=rOrd.relaz_tipo_id
  and   rord.data_cancellazione is null
  and   rord.validita_fine is null
  and   ord.data_cancellazione is null
  and   ord.validita_fine is null
  and   rstato.data_cancellazione is null
  and   rstato.validita_fine is null
  and   ts.data_cancellazione is null
  and   ts.validita_fine is null
  and   det.data_cancellazione is null
  and   det.validita_fine is null
--  group by ord.ord_id
  group by rord.ord_id_da -- 20.12.2017 Sofia jira siac-5665
  having coalesce(sum(det.ord_ts_det_importo),0)=importoOrd
  limit 1;

  if checkDati is not null then
    strMessaggio:='Lettura tipo pamento compensazione.';
  	select oil.accredito_tipo_oil_code ,oil.accredito_tipo_oil_desc
           into accreditoCodePag,accreditoDescPag
    from siac_d_accredito_tipo_oil oil
    where oil.ente_proprietario_id=enteProprietarioId
    and   oil.accredito_tipo_oil_desc=tipoPagamCompensa
    and   oil.data_cancellazione is null
    and   oil.validita_fine is null;
    if accreditoCodePag is not null  then
    	isCompensa:=true;
    end if;
  end if;
 end if;

 if isProvvisori = false and isCompensa=false then
 	if codicePaese='' or codicePaese is null then

 	 -- se il codice paese='' or codicepaese is null
 	 -- cerco il gruppo da accredito_tipo_id
	 -- se e' CB allora forzo paese=' '
     if accreditoGruppoCode=accreditoCodeCB then
     	codicePaese=' '; -- forzato per cercare CB extrasepa
     end if;

    end if;
 end if;


 if isProvvisori=false and  isCompensa=false and
    codicePaese is not null and codicePaese!=codiceItalia then
    strMessaggio:='Lettura tipo pagamento ordinativo [siac_t_sepa].';
 	select distinct 1 into checkDati
    from siac_t_sepa sepa
    where sepa.sepa_iso_code=codicePaese
    and   sepa.ente_proprietario_id=enteProprietarioId
    and   sepa.data_cancellazione is null
 	and   date_trunc('day',dataElaborazione)>=date_trunc('day',sepa.validita_inizio)
 	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(sepa.validita_fine,dataElaborazione));

    if checkDati is not null then
    	isSepa:=true;
    end if;
 end if;

 if isProvvisori=true THEN
 	-- lettura tabella di decodifica REG ( valore presente in param )
    accreditoCodeTes:=accreditoCodeREG;
 end if;


 checkDati:=null;
 strMessaggio:='Lettura tipo pagamento ordinativo [siac_r_ordinativo_attr].';
 select 1 into checkDati
 from siac_r_ordinativo_attr rattr, siac_t_attr attr
 where rattr.ord_id=ordinativoId
 and   rattr.boolean='S'
 and   rattr.data_cancellazione is null
 and   rattr.validita_fine is null
 and   attr.attr_id=rattr.attr_id
 and   attr.attr_code=ALLEG_CART_ATTR
 and   attr.data_cancellazione is null
 and   attr.validita_fine is null;

 if checkDati is not null then
  	isAllegatoCartaceo  :=true;
 end if;

 strMessaggio:='Lettura tipo pagamento ordinativo.';
 -- raise notice 'isProvvisori=% ',isProvvisori;
 -- raise notice 'isSepa=% ',isSepa;


 if isProvvisori=false and isCompensa=false  and
    codicePaese is not  null and  codicePaese!=codiceItalia  then
    accreditoCodeTes:=accreditoCodeCB;
 	if isSepa=true then
	 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=SEPA
    	codAreaSepa:=codiceAreaSepa;
    else
	 	-- lettura tabella di decodifica con CB ( valore presente in param), oil_area=EXTRASEPA
	    codAreaSepa:=codiceAreaExtraSepa;
        isAllegatoCartaceo  :=true; -- bonifico estero extra-sepa forzato a true
    end if;

 end if;

 if  isCompensa=false  then

  if isProvvisori=false and -- 13.12.2017 Sofia siac-5654
     (accreditoCodeTes is null or  pagamentoGFB = true ) then
     accreditoTipoOilId:=accreditoTipoId;
     if pagamentoGFB=true then
    	codAreaSepa:=null;
     end if;
  else
    -- lettura di accredito_tipo_id per lettura in accredito_tipo
	strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo] accredito_tipo_code='||accreditoCodeTes||'.';

	select tipo.accredito_tipo_id into accreditoTipoOilId
	from siac_d_accredito_tipo tipo
	where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.accredito_tipo_code=accreditoCodeTes
	and   tipo.data_cancellazione is null
	and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
	and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(tipo.validita_fine,dataElaborazione));

	 if accreditoTipoOilId is null then
 		RAISE EXCEPTION ' Accredito tipo non trovato.';
	 end if;
  end if;

 end if;

 if  isCompensa=false  then

  -- lettura di accredito_tipo_id per lettura in accredito_tipo_oil
  strMessaggio:='Lettura tipo pagamento ordinativo [siac_d_accredito_tipo_oil].';
  select oil.accredito_tipo_oil_code,oil.accredito_tipo_oil_desc into accreditoCodePag,accreditoDescPag
  from siac_d_accredito_tipo_oil oil, siac_r_accredito_tipo_oil raccre
  where raccre.accredito_tipo_id=accreditoTipoOilId
  and   raccre.data_cancellazione is null
  and   raccre.validita_fine is null
  and   oil.accredito_tipo_oil_id=raccre.accredito_tipo_oil_id
  and   coalesce(oil.accredito_tipo_oil_area,'IT')=coalesce(codAreaSepa,'IT')
  and   oil.data_cancellazione is null
  and   date_trunc('day',dataElaborazione)>=date_trunc('day',oil.validita_inizio)
  and   date_trunc('day',dataElaborazione)<=date_trunc('day',coalesce(oil.validita_fine,dataElaborazione));
 end if;



 codeTipoPagamento:=accreditoCodePag;
 descTipoPagamento:=accreditoDescPag;
 defRifDocEsterno:= isAllegatoCartaceo;
--  raise notice 'accreditoCodePag=% ',accreditoCodePag;
--  raise notice 'descTipoPagamento=% ',accreditoDescPag;


 return;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- 15.01.2018 Sofia - FINE

--INIZIO SIAC-5557
CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_impegno_from_capitolospesa (
  _uid_capitolospesa integer,
  _anno varchar,
  _limit integer,
  _page integer
)
RETURNS TABLE (
  uid integer,
  impegno_anno integer,
  impegno_numero numeric,
  impegno_desc varchar,
  impegno_stato varchar,
  impegno_importo numeric,
  soggetto_code varchar,
  soggetto_desc varchar,
  attoamm_numero integer,
  attoamm_anno varchar,
  attoamm_tipo_code varchar,
  attoamm_tipo_desc varchar,
  attoamm_stato_desc varchar,
  attoamm_sac_code varchar,
  attoamm_sac_desc varchar,
  pdc_code varchar,
  pdc_desc varchar
) AS
$body$
DECLARE
	_offset INTEGER := (_page) * _limit;
BEGIN

	RETURN QUERY
		with imp_sogg_attoamm as (
			with imp_sogg as (
				select distinct
					soggall.uid,
					soggall.movgest_anno,
					soggall.movgest_numero,
					soggall.movgest_desc,
					soggall.movgest_stato_desc,
					soggall.movgest_ts_id,
					soggall.movgest_ts_det_importo,
					case when soggall.zzz_soggetto_code is null then soggall.zzzz_soggetto_code else soggall.zzz_soggetto_code end soggetto_code,
					case when soggall.zzz_soggetto_desc is null then soggall.zzzz_soggetto_desc else soggall.zzz_soggetto_desc end soggetto_desc,
					soggall.pdc_code,
					soggall.pdc_desc
				from (
					with za as (
						select
							zzz.uid,
							zzz.movgest_anno,
							zzz.movgest_numero,
							zzz.movgest_desc,
							zzz.movgest_stato_desc,
							zzz.movgest_ts_id,
							zzz.movgest_ts_det_importo,
							zzz.soggetto_code zzz_soggetto_code,
							zzz.soggetto_desc zzz_soggetto_desc,
							zzz.pdc_code,
							zzz.pdc_desc
						from (
							with impegno as (
								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo,
									q.classif_code pdc_code,
									q.classif_desc pdc_desc
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_r_movgest_class p,
									siac_t_class q,
									siac_d_class_tipo r,
									siac_t_bil s,
									siac_t_periodo t
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and p.movgest_ts_id = c.movgest_ts_id
								and q.classif_id = p.classif_id
								and r.classif_tipo_id = q.classif_tipo_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and s.bil_id = a.bil_id
								and t.periodo_id = s.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and now() BETWEEN p.validita_inizio and COALESCE(p.validita_fine,now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and p.data_cancellazione is null
								and q.data_cancellazione is null
								and r.data_cancellazione is null
								and s.data_cancellazione is null
								and t.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and r.classif_tipo_code in ('PDC_I','PCD_II', 'PDC_III', 'PDC_IV', 'PDC_V')
								and b.elem_id=_uid_capitolospesa
								and t.anno = _anno
							),
							soggetto as (
								select
									g.soggetto_code,
									g.soggetto_desc,
									h.movgest_ts_id
								from
									siac_t_soggetto g,
									siac_r_movgest_ts_sog h
								where h.soggetto_id=g.soggetto_id
								and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and g.data_cancellazione is null
								and h.data_cancellazione is null
							)
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc,
								impegno.pdc_code,
								impegno.pdc_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzz
					),
					zb as (
						select
							zzzz.uid,
							zzzz.movgest_anno,
							zzzz.movgest_numero,
							zzzz.movgest_desc,
							zzzz.movgest_stato_desc,
							zzzz.movgest_ts_id,
							zzzz.movgest_ts_det_importo,
							zzzz.soggetto_code zzzz_soggetto_code,
							zzzz.soggetto_desc zzzz_soggetto_desc
						from (
							with impegno as (
								select
									a.movgest_id as uid,
									a.movgest_anno,
									a.movgest_numero,
									a.movgest_desc,
									e.movgest_stato_desc,
									c.movgest_ts_id,
									f.movgest_ts_det_importo
								from
									siac_t_movgest a,
									siac_r_movgest_bil_elem b,
									siac_t_movgest_ts c,
									siac_r_movgest_ts_stato d,
									siac_d_movgest_stato e,
									siac_t_movgest_ts_det f,
									siac_d_movgest_ts_tipo j,
									siac_d_movgest_ts_det_tipo k,
									siac_t_bil l,
									siac_t_periodo m
								where a.movgest_id=b.movgest_id
								and c.movgest_id=a.movgest_id
								and d.movgest_ts_id=c.movgest_ts_id
								and e.movgest_stato_id=d.movgest_stato_id
								and j.movgest_ts_tipo_id=c.movgest_ts_tipo_id
								and k.movgest_ts_det_tipo_id=f.movgest_ts_det_tipo_id
								and l.bil_id = a.bil_id
								and m.periodo_id = l.periodo_id
								and now() between d.validita_inizio and coalesce(d.validita_fine, now())
								and now() between b.validita_inizio and coalesce(b.validita_fine, now())
								and f.movgest_ts_id=c.movgest_ts_id
								and a.data_cancellazione is null
								and b.data_cancellazione is null
								and c.data_cancellazione is null
								and d.data_cancellazione is null
								and e.data_cancellazione is null
								and f.data_cancellazione is null
								and e.movgest_stato_code<>'A'
								and j.movgest_ts_tipo_code='T'
								and k.movgest_ts_det_tipo_code='A'
								and b.elem_id=_uid_capitolospesa
								and m.anno = _anno
							),
							soggetto as (
                                select
									l.soggetto_classe_code soggetto_code,
									l.soggetto_classe_desc soggetto_desc,
									h.movgest_ts_id
								from
									siac_r_movgest_ts_sogclasse h,
									siac_d_soggetto_classe l
								where 
								    h.soggetto_classe_id=l.soggetto_classe_id								
                                and now() between h.validita_inizio and coalesce(h.validita_fine, now())
								and h.data_cancellazione is null								
							)
							select
								impegno.uid,
								impegno.movgest_anno,
								impegno.movgest_numero,
								impegno.movgest_desc,
								impegno.movgest_stato_desc,
								impegno.movgest_ts_id,
								impegno.movgest_ts_det_importo,
								soggetto.soggetto_code,
								soggetto.soggetto_desc
							from impegno
							left outer join soggetto on impegno.movgest_ts_id=soggetto.movgest_ts_id
						) as zzzz
					)
					select
						za.*,
						zb.zzzz_soggetto_code,
						zb.zzzz_soggetto_desc
					from za
					left join zb on za.movgest_ts_id=zb.movgest_ts_id
				) soggall
			),
			attoamm as (
				select
					movgest_ts_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_movgest_ts_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN m.validita_inizio and coalesce (m.validita_fine,now())
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			)
			select
				imp_sogg.uid,
				imp_sogg.movgest_anno,
				imp_sogg.movgest_numero,
				imp_sogg.movgest_desc,
				imp_sogg.movgest_stato_desc,
				imp_sogg.movgest_ts_det_importo,
				imp_sogg.soggetto_code,
				imp_sogg.soggetto_desc,
				attoamm.attoamm_id,
				attoamm.attoamm_numero,
				attoamm.attoamm_anno,
				attoamm.attoamm_tipo_code,
				attoamm.attoamm_tipo_desc,
				attoamm.attoamm_stato_desc,
				imp_sogg.pdc_code,
				imp_sogg.pdc_desc
			from imp_sogg
			left outer join attoamm ON imp_sogg.movgest_ts_id=attoamm.movgest_ts_id
		),
		sac_attoamm as (
			select
				y.classif_code,
				y.classif_desc,
				z.attoamm_id
			from
				siac_r_atto_amm_class z,
				siac_t_class y,
				siac_d_class_tipo x
			where z.classif_id=y.classif_id
			and x.classif_tipo_id=y.classif_tipo_id
			and now() BETWEEN z.validita_inizio and coalesce (z.validita_fine,now())
			and x.classif_tipo_code  IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select
			imp_sogg_attoamm.uid,
			imp_sogg_attoamm.movgest_anno as impegno_anno,
			imp_sogg_attoamm.movgest_numero as impegno_numero,
			imp_sogg_attoamm.movgest_desc as impegno_desc,
			imp_sogg_attoamm.movgest_stato_desc as impegno_stato,
			imp_sogg_attoamm.movgest_ts_det_importo as impegno_importo,
			imp_sogg_attoamm.soggetto_code,
			imp_sogg_attoamm.soggetto_desc,
			imp_sogg_attoamm.attoamm_numero,
			imp_sogg_attoamm.attoamm_anno,
			imp_sogg_attoamm.attoamm_tipo_code,
			imp_sogg_attoamm.attoamm_tipo_desc,
			imp_sogg_attoamm.attoamm_stato_desc,
			sac_attoamm.classif_code as attoamm_sac_code,
			sac_attoamm.classif_desc as attoamm_sac_desc,
			imp_sogg_attoamm.pdc_code,
			imp_sogg_attoamm.pdc_desc
		from imp_sogg_attoamm
		left outer join sac_attoamm on imp_sogg_attoamm.attoamm_id=sac_attoamm.attoamm_id
		order by
			imp_sogg_attoamm.movgest_anno,
			imp_sogg_attoamm.movgest_numero
		LIMIT _limit
		OFFSET _offset;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


--FINE SIAC-5557

-- SIAC-5685 Daniela 16.01.2018
alter table siac.siac_dwh_contabilita_generale 
	add doc_id INTEGER;
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_contabilita_generale (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
/*
pdc        record;

impegni record;
documenti record;
liquidazioni_doc record;
liquidazioni_imp record;
ordinativi record;
ordinativi_imp record;

prima_nota record;
movimenti  record;
causale    record;
class      record;*/

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   --IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      --p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   --ELSE
      p_data := now();
   --END IF;
END IF;

esito:= 'Inizio funzione carico dati contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_contabilita_generale
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

insert into
siac_dwh_contabilita_generale
select
tb.ente_proprietario_id,
tb.ente_denominazione,
tb.bil_anno,
tb.desc_prima_nota,
tb.num_provvisorio_prima_nota,
tb.num_definitivo_prima_nota,
tb.data_registrazione_prima_nota,
tb.cod_stato_prima_nota,
tb.desc_stato_prima_nota,
tb.cod_mov_ep,
tb.desc_mov_ep,
tb.cod_mov_ep_dettaglio,
tb.desc_mov_ep_dettaglio,
tb.importo_mov_ep,
tb.segno_mov_ep,
tb.cod_piano_dei_conti,
tb.desc_piano_dei_conti,
tb.livello_piano_dei_conti,
tb.ordine_piano_dei_conti,
tb.cod_pdce_fam,
tb.desc_pdce_fam,
tb.cod_ambito,
tb.desc_ambito,
tb.cod_causale,
tb.desc_causale,
tb.cod_tipo_causale,
tb.desc_tipo_causale,
tb.cod_stato_causale,
tb.desc_stato_causale,
tb.cod_evento,
tb.desc_evento,
tb.cod_tipo_mov_finanziario,
tb.desc_tipo_mov_finanziario,
tb.cod_piano_finanziario,
tb.desc_piano_finanziario,
tb.anno_movimento,
tb.numero_movimento,
tb.cod_submovimento,
anno_ordinativo,
num_ordinativo,
num_subordinativo,
anno_liquidazione,
num_liquidazione,
anno_doc,
num_doc,
cod_tipo_doc,
data_emissione_doc,
cod_sogg_doc,
num_subdoc,
modifica_impegno,
entrate_uscite,
tb.cod_bilancio,
p_data data_elaborazione,
numero_ricecon,
tipo_evento -- SIAC-5641
,doc_id -- SIAC-5573
from (
select tbdoc.* from
(
with movep as (
  select    distinct
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL
          and d.collegamento_tipo_code in ('SE','SS')
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id= p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
  then 'CE'
  when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
  when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
  when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
  when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
  when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
  else ''::varchar end as tipo_codifica,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id= p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null
        )
  select aa.*,
bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
   from aa left join
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
  doc as (with aa as (
select a.doc_id,
b.subdoc_id, b.subdoc_numero  num_subdoc,
a.doc_anno anno_doc,
a.doc_numero num_doc,
a.doc_data_emissione data_emissione_doc ,
c.doc_tipo_code cod_tipo_doc
 from siac_t_doc a,siac_t_subdoc b,siac_d_doc_tipo c
where b.doc_id=a.doc_id and a.ente_proprietario_id=p_ente_proprietario_id
and c.doc_tipo_id=a.doc_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is NULL)
, bb as (SELECT
  a.doc_id,
  b.soggetto_code v_soggetto_code
      FROM   siac_r_doc_sog a, siac_t_soggetto b
      WHERE a.soggetto_id = b.soggetto_id
      and a.ente_proprietario_id=p_ente_proprietario_id
      and a.data_cancellazione is null
and b.data_cancellazione is null
and a.validita_fine is null)
select
-- SIAC-5573
-- *
aa.*,bb.v_soggetto_code
From
aa left join bb ON
aa.doc_id=bb.doc_id),
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
   null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
-- SIAC-5573
doc.doc_id,
doc.anno_doc,
doc.num_doc,
doc.cod_tipo_doc,
doc.data_emissione_doc,
doc.v_soggetto_code cod_sogg_doc,
doc.num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case
         when movep.cod_tipo_mov_finanziario = 'SE' then
          'E'
         else
          'U'
       end
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
    from movep left join
  movepdet on movep.movep_id=movepdet.movep_id
     left join doc
  on movep.campo_pk_id=doc.subdoc_id
  left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id) as tbdoc
UNION
select tbimp.* from (
-- imp
with movep as (
  select    distinct
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
     i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND  p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL
          and d.collegamento_tipo_code in ('A','I')
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE'
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
  when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
  when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
  when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  )
  ,imp as (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento from siac_t_movgest a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  , pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.*,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
   imp.anno_movimento,imp.numero_movimento,
   null::varchar cod_submovimento
   ,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
-- SIAC-5573
null::integer doc_id,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case
         when movep.cod_tipo_mov_finanziario = 'A' then
          'E'
         else
          'U'
         end
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
   from
   movep left join
  	movepdet on movep.movep_id=movepdet.movep_id
left join imp
  on movep.campo_pk_id=imp.movgest_id  left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id) as tbimp
UNION
--subimp acc
select tbimp.* from (
-- imp
with movep as (
  select    distinct
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL
          and d.collegamento_tipo_code in ('SA','SI')
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE'
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  )
  ,subimp as (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento,
  b.movgest_ts_id,b.movgest_ts_code cod_submovimento
  from siac_t_movgest a,siac_T_movgest_ts b where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.movgest_id=a.movgest_id
  )
  , pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario, subimp.anno_movimento,
   subimp.numero_movimento,
   subimp.cod_submovimento
   ,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
-- SIAC-5573
null::integer doc_id,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case
         when movep.cod_tipo_mov_finanziario = 'SA' then
          'E'
         else
          'U'
         end
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
   from movep left join
  movepdet on movep.movep_id=movepdet.movep_id
left join subimp
  on movep.campo_pk_id=subimp.movgest_ts_id    left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id ) as tbimp
union
select tbord.* from (
-- ord
with movep as (
  select    distinct
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL
          and d.collegamento_tipo_code in ('OI', 'OP')
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as (/* SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE'
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
        )
  select aa.*,bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
   ord as (select a.ord_id,a.ord_anno anno_ordinativo,a.ord_numero num_ordinativo
   from siac_t_ordinativo a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
/*  ,liq as (select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione from siac_t_liquidazione a where a.ente_proprietario_id=3
and a.data_cancellazione is null)  */
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
   null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,ord.anno_ordinativo,
ord.num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
-- SIAC-5573
null::integer doc_id,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case
         when movep.cod_tipo_mov_finanziario = 'OI' then
          'E'
         else
          'U'
         end
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
   from movep left join
  movepdet on movep.movep_id=movepdet.movep_id
   left join ord
  on movep.campo_pk_id=ord.ord_id
      left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id
  ) as tbord
UNION
-- liq
select tbliq.* from (
with movep as (
  select    distinct
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL
          and d.collegamento_tipo_code ='L'
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE'
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,liq as (select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione from siac_t_liquidazione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario
   , null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
liq.anno_liquidazione,
liq.num_liquidazione,
-- SIAC-5573
null::integer doc_id,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case
         when movep.cod_tipo_mov_finanziario = 'L' then
          'U'
         else
          'E'
         end
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
   from movep left join
  movepdet on movep.movep_id=movepdet.movep_id
  left join liq
  on movep.campo_pk_id=liq.liq_id
      left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id
) as tbliq
union
--richiesta econ
select tbricecon.* from (
with movep as (
  select    distinct
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL
          and d.collegamento_tipo_code ='RE'
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as ( /*SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE'
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
  ricecon as (select a.ricecon_id, a.ricecon_numero numero_ricecon from siac_t_richiesta_econ a where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
)       ,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.* ,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario
   , null::integer anno_movimento,null::numeric numero_movimento,null::varchar cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
-- SIAC-5573
null::integer doc_id,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case
         when movep.cod_tipo_mov_finanziario = 'RE' then
          'U'
         else
          'E'
         end
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
ricecon.numero_ricecon
   from movep left join
  movepdet on movep.movep_id=movepdet.movep_id
  left join ricecon
  on movep.campo_pk_id=ricecon.ricecon_id   left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id) as tbricecon
   union
-- mod
select tbmod.* from (
with movep as (
  select    distinct
  a.ente_proprietario_id,p.ente_denominazione,i.anno AS bil_anno,
      m.pnota_desc desc_prima_nota,  m.pnota_numero num_provvisorio_prima_nota,
      m.pnota_progressivogiornale num_definitivo_prima_nota,
  m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
  o.pnota_stato_code cod_stato_prima_nota,
  o.pnota_stato_desc desc_stato_prima_nota,
  l.movep_id, --da non visualizzare
  l.movep_code cod_mov_ep,
  l.movep_desc desc_mov_ep,
  q.causale_ep_code cod_causale,
  q.causale_ep_desc desc_causale,
  r.causale_ep_tipo_code cod_tipo_causale,
  r.causale_ep_tipo_desc desc_tipo_causale,
  t.causale_ep_stato_code cod_stato_causale,
  t.causale_ep_stato_desc desc_stato_causale,
           c.evento_code cod_evento,
           c.evento_desc desc_evento,
           d.collegamento_tipo_code cod_tipo_mov_finanziario,
           d.collegamento_tipo_desc desc_tipo_mov_finanziario,
           b.campo_pk_id ,
           q.causale_ep_id,
           g.evento_tipo_code as tipo_evento -- SIAC-5641
    FROM siac_t_reg_movfin a,
         siac_r_evento_reg_movfin b,
         siac_d_evento c,
         siac_d_collegamento_tipo d,
         siac_r_reg_movfin_stato e,
         siac_d_reg_movfin_stato f,
         siac_d_evento_tipo g,
         siac_t_bil h,
         siac_t_periodo i,
         siac_t_mov_ep l,
         siac_t_prima_nota m,
         siac_r_prima_nota_stato n,
         siac_d_prima_nota_stato o,
         siac_t_ente_proprietario p,
         siac_t_causale_ep q,
         siac_d_causale_ep_tipo r,
         siac_r_causale_ep_stato s,
         siac_d_causale_ep_stato t
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    i.anno=p_anno_bilancio and
    a.regmovfin_id = b.regmovfin_id and
          c.evento_id = b.evento_id AND
          d.collegamento_tipo_id = c.collegamento_tipo_id AND
          g.evento_tipo_id = c.evento_tipo_id AND
          e.regmovfin_id = a.regmovfin_id AND
          f.regmovfin_stato_id = e.regmovfin_stato_id AND
          p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data) and
          p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data) and
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
          h.bil_id = a.bil_id AND
          i.periodo_id = h.periodo_id AND
          l.regmovfin_id = a.regmovfin_id AND
          l.regep_id = m.pnota_id AND
          m.pnota_id = n.pnota_id AND
          o.pnota_stato_id = n.pnota_stato_id AND
          p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
          --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
          p.ente_proprietario_id=a.ente_proprietario_id and
          q.causale_ep_id=l.causale_ep_id AND
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
          s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
          o.pnota_stato_code <> 'A' and
          a.data_cancellazione IS NULL AND
          b.data_cancellazione IS NULL AND
          c.data_cancellazione IS NULL AND
          d.data_cancellazione IS NULL AND
          e.data_cancellazione IS NULL AND
          f.data_cancellazione IS NULL AND
          g.data_cancellazione IS NULL AND
          h.data_cancellazione IS NULL AND
          i.data_cancellazione IS NULL AND
          l.data_cancellazione IS NULL AND
          m.data_cancellazione IS NULL AND
          n.data_cancellazione IS NULL AND
          o.data_cancellazione IS NULL AND
          p.data_cancellazione IS NULL AND
          q.data_cancellazione IS NULL AND
          r.data_cancellazione IS NULL AND
          s.data_cancellazione IS NULL AND
          t.data_cancellazione IS NULL
          and d.collegamento_tipo_code in ('MMGE','MMGS')
          )
  , movepdet as (
with aa as (
  select a.movep_id, b.pdce_conto_id,
     a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
  b.pdce_conto_code cod_piano_dei_conti,
  b.pdce_conto_desc desc_piano_dei_conti,
  b.livello livello_piano_dei_conti,
  b.ordine ordine_piano_dei_conti,
  d.pdce_fam_code cod_pdce_fam,
  d.pdce_fam_desc desc_pdce_fam,
  e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
      ,siac_d_pdce_fam d,siac_d_ambito e
       where a.ente_proprietario_id=p_ente_proprietario_id
      and b.pdce_conto_id=a.pdce_conto_id
      and c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and d.pdce_fam_id=c.pdce_fam_id
      and c.validita_fine is null
      and e.ambito_id=a.ambito_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null)
  , bb as (
/*
SELECT c.pdce_conto_id,
         a.codice_codifica_albero
  FROM siac_v_dwh_codifiche_econpatr a,
       siac_r_pdce_conto_class b,
       siac_t_pdce_conto c
  WHERE b.classif_id = a.classif_id AND
        c.pdce_conto_id = b.pdce_conto_id
        and c.ente_proprietario_id=p_ente_proprietario_id
        and c.data_cancellazione is null
        and b.data_cancellazione is NULL
        and b.validita_fine is null*/
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE'
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
        )
  select aa.*, bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio from aa left join
  bb on aa.pdce_conto_id=bb.pdce_conto_id
  ) ,
  mod as (
select d.mod_id,
c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
b.movgest_ts_code cod_submovimento
,tsTipo.movgest_ts_tipo_code
          FROM   siac_t_movgest_ts_det_mod a,siac_T_movgest_ts b, siac_t_movgest c,
           siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f
           ,siac_d_movgest_ts_tipo tsTipo
          WHERE  a.ente_proprietario_id = p_ente_proprietario_id
and a.mod_stato_r_id=e.mod_stato_r_id
and e.mod_id=d.mod_id
and f.mod_stato_id=e.mod_stato_id
and a.movgest_ts_id=b.movgest_ts_id
and b.movgest_id=c.movgest_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
          AND    a.data_cancellazione IS NULL
          AND    b.data_cancellazione IS NULL
          AND    c.data_cancellazione IS NULL
          AND    d.data_cancellazione IS NULL
          AND    e.data_cancellazione IS NULL
          AND    f.data_cancellazione IS NULL
AND tsTipo.movgest_ts_tipo_id = b.movgest_ts_tipo_id
UNION
select d.mod_id,
c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
b.movgest_ts_code cod_submovimento
,tsTipo.movgest_ts_tipo_code
          FROM   siac_r_movgest_ts_sog_mod a,siac_T_movgest_ts b, siac_t_movgest c,
           siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f
           ,siac_d_movgest_ts_tipo tsTipo
          WHERE  a.ente_proprietario_id = p_ente_proprietario_id
and a.mod_stato_r_id=e.mod_stato_r_id
and e.mod_id=d.mod_id
and f.mod_stato_id=e.mod_stato_id
and a.movgest_ts_id=b.movgest_ts_id
and b.movgest_id=c.movgest_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
          AND    a.data_cancellazione IS NULL
          AND    b.data_cancellazione IS NULL
          AND    c.data_cancellazione IS NULL
          AND    d.data_cancellazione IS NULL
          AND    e.data_cancellazione IS NULL
          AND    f.data_cancellazione IS NULL
AND tsTipo.movgest_ts_tipo_id = b.movgest_ts_tipo_id  )
,
pdc as (select a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b where a.ente_proprietario_id=p_ente_proprietario_id
  and b.classif_id=a.classif_id and
  b.validita_fine is null
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
   select movep.*,movepdet.*--, case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno
,pdc.cod_piano_finanziario,pdc.desc_piano_finanziario
   , mod.v_movgest_anno anno_movimento,mod.v_movgest_numero numero_movimento,
   -- SIAC-5685
   -- mod.cod_submovimento
   case when mod.movgest_ts_tipo_code='T' then null::varchar else mod.cod_submovimento end cod_submovimento
,null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
-- SIAC-5573
null::integer doc_id,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno,
case -- SIAC-5601
  when movepdet.cod_ambito = 'AMBITO_GSA' then
       case
         when movep.cod_tipo_mov_finanziario = 'MMGE' then
          'E'
         else
          'U'
         end
  else
  pdc.entrate_uscite
end entrate_uscite,
-- pdc.entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
     from movep left join
  movepdet on movep.movep_id=movepdet.movep_id
  left join mod on
  movep.campo_pk_id=  mod.mod_id
      left join pdc
  on movep.causale_ep_id=pdc.causale_ep_id
) as tbmod
--lib
union
select lib.* from (
with movep as (
select distinct
m.ente_proprietario_id,
p.ente_denominazione,
i.anno AS bil_anno,
m.pnota_desc desc_prima_nota,
m.pnota_numero num_provvisorio_prima_nota,
m.pnota_progressivogiornale num_definitivo_prima_nota,
m.pnota_dataregistrazionegiornale data_registrazione_prima_nota,
o.pnota_stato_code cod_stato_prima_nota,
o.pnota_stato_desc desc_stato_prima_nota,
l.movep_id,
l.movep_code cod_mov_ep,
l.movep_desc desc_mov_ep,
q.causale_ep_code cod_causale,
q.causale_ep_desc desc_causale,
r.causale_ep_tipo_code cod_tipo_causale,
r.causale_ep_tipo_desc desc_tipo_causale,
t.causale_ep_stato_code cod_stato_causale,
t.causale_ep_stato_desc desc_stato_causale,
NULL::varchar cod_evento,
NULL::varchar desc_evento,
NULL::varchar cod_tipo_mov_finanziario,
NULL::varchar desc_tipo_mov_finanziario,
NULL::integer campo_pk_id ,
q.causale_ep_id,
NULL::varchar evento_tipo_code
FROM
siac_t_prima_nota m,siac_d_causale_ep_tipo r,
siac_t_bil h,
siac_t_periodo i,
siac_t_mov_ep l,
siac_r_prima_nota_stato n,
siac_d_prima_nota_stato o,
siac_t_ente_proprietario p,
siac_t_causale_ep q,
siac_r_causale_ep_stato s,
siac_d_causale_ep_stato t
WHERE
m.ente_proprietario_id=p_ente_proprietario_id
and r.causale_ep_tipo_code='LIB' and
i.anno=p_anno_bilancio
and
h.bil_id = m.bil_id AND
i.periodo_id = h.periodo_id AND
l.regep_id = m.pnota_id AND
m.pnota_id = n.pnota_id AND
o.pnota_stato_id = n.pnota_stato_id AND
--p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data) and
p.ente_proprietario_id=m.ente_proprietario_id and
q.causale_ep_id=l.causale_ep_id AND
r.causale_ep_tipo_id=q.causale_ep_tipo_id and s.causale_ep_id=q.causale_ep_id AND
s.causale_ep_stato_id=t.causale_ep_stato_id and s.validita_fine is NULL and
o.pnota_stato_code <> 'A' and
h.data_cancellazione IS NULL AND
i.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL AND
r.data_cancellazione IS NULL AND
s.data_cancellazione IS NULL AND
t.data_cancellazione IS NULL
)
,
movepdet as (
with aa as
(
select a.movep_id, b.pdce_conto_id,
a.movep_det_code cod_mov_ep_dettaglio,
a.movep_det_desc desc_mov_ep_dettaglio,
a.movep_det_importo importo_mov_ep,
a.movep_det_segno segno_mov_ep,
b.pdce_conto_code cod_piano_dei_conti,
b.pdce_conto_desc desc_piano_dei_conti,
b.livello livello_piano_dei_conti,
b.ordine ordine_piano_dei_conti,
d.pdce_fam_code cod_pdce_fam,
d.pdce_fam_desc desc_pdce_fam,
e.ambito_code cod_ambito,
e.ambito_desc desc_ambito
From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c
,siac_d_pdce_fam d,siac_d_ambito e
where a.ente_proprietario_id= p_ente_proprietario_id
and b.pdce_conto_id=a.pdce_conto_id
and c.pdce_fam_tree_id=b.pdce_fam_tree_id
and d.pdce_fam_id=c.pdce_fam_id
and c.validita_fine is null
and e.ambito_id=a.ambito_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
)
,
bb as
(
SELECT c.pdce_conto_id,case when a.tipo_codifica = 'conto economico (codice di bilancio)'
then 'CE'
when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
else ''::varchar end as tipo_codifica,
a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,
siac_r_pdce_conto_class b,
siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id AND
c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
and c.data_cancellazione is null
and b.data_cancellazione is NULL
and b.validita_fine is null
)
select aa.*,
bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
from aa left join
bb on aa.pdce_conto_id=bb.pdce_conto_id
)
select movep.*,movepdet.*,
null::varchar cod_piano_finanziario,
null::varchar desc_piano_finanziario,
null::integer anno_movimento,
null::numeric numero_movimento,
null::varchar cod_submovimento,
null::integer anno_ordinativo,
null::numeric num_ordinativo,
null::varchar num_subordinativo,
null::integer anno_liquidazione,
null::numeric num_liquidazione,
-- SIAC-5573
null::integer doc_id,
null::integer anno_doc,
null::varchar num_doc,
null::varchar cod_tipo_doc,
null::timestamp data_emissione_doc,
null::varchar cod_sogg_doc,
null::integer num_subdoc,
null::varchar modifica_impegno,
null::varchar entrate_uscite,
p_data data_elaborazione,
null::integer numero_ricecon
from movep left join
movepdet on movep.movep_id=movepdet.movep_id
) as lib
) as tb;

esito:= 'Fine funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- FINE SIAC-5685
-- SIAC-5764
CREATE OR REPLACE VIEW siac.siac_v_dwh_subdoc_sospensione (
	doc_id,
    anno_doc ,
    num_doc,
    cod_tipo_doc,
    data_emissione_doc,
    cod_sogg_doc,
	num_subdoc,
    causale_sospensione,
    data_sospensione,
    data_riattivazione,
 	ente_proprietario_id)
AS
with doc as
	(select
    doc.doc_id
    , doc.doc_anno
    , doc.doc_numero
    , tipoDoc.doc_tipo_code
    , doc.doc_data_emissione
    , doc.ente_proprietario_id
    from siac_t_doc doc,
    siac_d_doc_tipo tipoDoc
    where
    doc.doc_tipo_id = tipoDoc.doc_tipo_id)
    , subDoc as
    (select
      sub.doc_id
    , sub.subdoc_numero
    , sosp.subdoc_sosp_causale
    , sosp.subdoc_sosp_data
    , sosp.subdoc_sosp_data_riattivazione
    , sub.ente_proprietario_id
    from siac_t_subdoc sub,
    	 siac_t_subdoc_sospensione sosp
        where sosp.subdoc_id = sub.subdoc_id
        and   sosp.data_cancellazione is null
        and   sosp.validita_fine is null
    )
    , sogg as
    (select
      r.doc_id
    , s.soggetto_code
    , r.ente_proprietario_id
    from
    siac_t_soggetto s,
    siac_r_doc_sog r
    where r.data_cancellazione is null
    and   r.validita_fine is null
    and   r.soggetto_id = s.soggetto_id)
select
    doc.doc_id
    , doc.doc_anno as anno_doc
    , doc.doc_numero as num_doc
    , doc.doc_tipo_code as cod_tipo_doc
    , doc.doc_data_emissione as data_emissione_doc
    , sogg.soggetto_code as cod_sogg_doc
    , subdoc.subdoc_numero as num_subdoc
    , subdoc.subdoc_sosp_causale as causale_sospensione
    , to_char(subdoc.subdoc_sosp_data,'dd/mm/yyyy') as data_sospensione
    , to_char(subdoc.subdoc_sosp_data_riattivazione,'dd/mm/yyyy') as data_riattivazione
    , doc.ente_proprietario_id
from doc, subdoc, sogg
where doc.doc_id = subdoc.doc_id
and   doc.doc_id = sogg.doc_id;

ALTER TABLE siac_dwh_documento_spesa ADD COLUMN doc_id integer;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_spesa (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

DELETE FROM siac.siac_dwh_documento_spesa
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

INSERT INTO
  siac.siac_dwh_documento_spesa
(
  ente_proprietario_id,
  ente_denominazione,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  note_atto_amministrativo,
  cod_stato_atto_amministrativo,
  desc_stato_atto_amministrativo,
  causale_atto_allegato,
  altri_allegati_atto_allegato,
  dati_sensibili_atto_allegato,
  data_scadenza_atto_allegato,
  note_atto_allegato,
  annotazioni_atto_allegato,
  pratica_atto_allegato,
  resp_amm_atto_allegato,
  resp_contabile_atto_allegato,
  anno_titolario_atto_allegato,
  num_titolario_atto_allegato,
  vers_invio_firma_atto_allegato,
  cod_stato_atto_allegato,
  desc_stato_atto_allegato,
  sogg_id_atto_allegato,
  cod_sogg_atto_allegato,
  tipo_sogg_atto_allegato,
  stato_sogg_atto_allegato,
  rag_sociale_sogg_atto_allegato,
  p_iva_sogg_atto_allegato,
  cf_sogg_atto_allegato,
  cf_estero_sogg_atto_allegato,
  nome_sogg_atto_allegato,
  cognome_sogg_atto_allegato,
  anno_doc,
  num_doc,
  desc_doc,
  importo_doc,
  beneficiario_multiplo_doc,
  data_emissione_doc,
  data_scadenza_doc,
  codice_bollo_doc,
  desc_codice_bollo_doc,
  collegato_cec_doc,
  cod_pcc_doc,
  desc_pcc_doc,
  cod_ufficio_doc,
  desc_ufficio_doc,
  cod_stato_doc,
  desc_stato_doc,
  anno_elenco_doc,
  num_elenco_doc,
  data_trasmissione_elenco_doc,
  tot_quote_entrate_elenco_doc,
  tot_quote_spese_elenco_doc,
  tot_da_pagare_elenco_doc,
  tot_da_incassare_elenco_doc,
  cod_stato_elenco_doc,
  desc_stato_elenco_doc,
  cod_gruppo_doc,
  desc_famiglia_doc,
  cod_famiglia_doc,
  desc_gruppo_doc,
  cod_tipo_doc,
  desc_tipo_doc,
  sogg_id_doc,
  cod_sogg_doc,
  tipo_sogg_doc,
  stato_sogg_doc,
  rag_sociale_sogg_doc,
  p_iva_sogg_doc,
  cf_sogg_doc,
  cf_estero_sogg_doc,
  nome_sogg_doc,
  cognome_sogg_doc,
  num_subdoc,
  desc_subdoc,
  importo_subdoc,
  num_reg_iva_subdoc,
  data_scadenza_subdoc,
  convalida_manuale_subdoc,
  importo_da_dedurre_subdoc,
  splitreverse_importo_subdoc,
  pagato_cec_subdoc,
  data_pagamento_cec_subdoc,
  note_tesoriere_subdoc,
  cod_distinta_subdoc,
  desc_distinta_subdoc,
  tipo_commissione_subdoc,
  conto_tesoreria_subdoc,
  rilevante_iva,
  ordinativo_singolo,
  ordinativo_manuale,
  esproprio,
  note,
  cig,
  cup,
  causale_sospensione,
  data_sospensione,
  data_riattivazione,
  causale_ordinativo,
  num_mutuo,
  annotazione,
  certificazione,
  data_certificazione,
  note_certificazione,
  num_certificazione,
  data_scadenza_dopo_sospensione,
  data_esecuzione_pagamento,
  avviso,
  cod_tipo_avviso,
  desc_tipo_avviso,
  sogg_id_subdoc,
  cod_sogg_subdoc,
  tipo_sogg_subdoc,
  stato_sogg_subdoc,
  rag_sociale_sogg_subdoc,
  p_iva_sogg_subdoc,
  cf_sogg_subdoc,
  cf_estero_sogg_subdoc,
  nome_sogg_subdoc,
  cognome_sogg_subdoc,
  sede_secondaria_subdoc,
  bil_anno,
  anno_impegno,
  num_impegno,
  cod_impegno,
  desc_impegno,
  cod_subimpegno,
  desc_subimpegno,
  num_liquidazione,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  sogg_id_mod_pag,
  cod_sogg_mod_pag,
  tipo_sogg_mod_pag,
  stato_sogg_mod_pag,
  rag_sociale_sogg_mod_pag,
  p_iva_sogg_mod_pag,
  cf_sogg_mod_pag,
  cf_estero_sogg_mod_pag,
  nome_sogg_mod_pag,
  cognome_sogg_mod_pag,
  anno_liquidazione,
  bil_anno_ord,
  anno_ord,
  num_ord,
  num_subord,
  registro_repertorio,
  anno_repertorio,
  num_repertorio,
  data_repertorio,
  data_ricezione_portale,
  doc_contabilizza_genpcc,
  rudoc_registrazione_anno,
  rudoc_registrazione_numero,
  rudoc_registrazione_data,
  cod_cdc_doc,
  desc_cdc_doc,
  cod_cdr_doc,
  desc_cdr_doc,
  data_operazione_pagamentoincasso,
  pagataincassata,
  note_pagamentoincasso,
  -- 	SIAC-5229
  arrotondamento,
  cod_tipo_splitrev,
  desc_tipo_splitrev,
  stato_liquidazione,
  sdi_lotto_siope_doc,
  cod_siope_tipo_doc,
  desc_siope_tipo_doc,
  desc_siope_tipo_bnkit_doc,
  cod_siope_tipo_analogico_doc,
  desc_siope_tipo_analogico_doc,
  desc_siope_tipo_ana_bnkit_doc,
  cod_siope_tipo_debito_subdoc,
  desc_siope_tipo_debito_subdoc,
  desc_siope_tipo_deb_bnkit_sub,
  cod_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_subdoc,
  desc_siope_ass_motiv_bnkit_sub,
  cod_siope_scad_motiv_subdoc,
  desc_siope_scad_motiv_subdoc,
  desc_siope_scad_moti_bnkit_sub,
  doc_id -- SIAC-5573
  )
select
tb.v_ente_proprietario_id::INTEGER,
trim(tb.v_ente_denominazione::VARCHAR)::VARCHAR,
trim(tb.v_anno_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_num_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_oggetto_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdr_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_cdc_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_note_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_amministrativo::VARCHAR)::VARCHAR,
trim(tb.v_causale_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_altri_allegati_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_dati_sensibili_atto_allegato::VARCHAR)::VARCHAR,
tb.v_data_scadenza_atto_allegato::timestamp,
trim(tb.v_note_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_annotazioni_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_pratica_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_amm_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_resp_contabile_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_titolario_atto_allegato::INTEGER,
trim(tb.v_num_titolario_atto_allegato::VARCHAR)::VARCHAR,
tb.v_vers_invio_firma_atto_allegato::INTEGER,
trim(tb.v_cod_stato_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_atto_allegato::VARCHAR)::VARCHAR,
tb.v_sogg_id_atto_allegato::INTEGER,
trim(tb.v_cod_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_atto_allegato::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_atto_allegato::VARCHAR)::VARCHAR,
tb.v_anno_doc::INTEGER,
trim(tb.v_num_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_doc::VARCHAR)::VARCHAR,
tb.v_importo_doc::NUMERIC,
trim(tb.v_beneficiario_multiplo_doc::VARCHAR)::VARCHAR,
tb.v_data_emissione_doc::TIMESTAMP,
tb.v_data_scadenza_doc::TIMESTAMP,
trim(tb.v_codice_bollo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_codice_bollo_doc::VARCHAR)::VARCHAR,
tb.v_collegato_cec_doc,
trim(tb.v_cod_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_pcc_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_ufficio_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_stato_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_doc::VARCHAR)::VARCHAR,
tb.v_anno_elenco_doc::INTEGER,
tb.v_num_elenco_doc::INTEGER,
tb.v_data_trasmissione_elenco_doc::TIMESTAMP,
tb.v_tot_quote_entrate_elenco_doc::NUMERIC,
tb.v_tot_quote_spese_elenco_doc::NUMERIC,
tb.v_tot_da_pagare_elenco_doc::NUMERIC,
tb.v_tot_da_incassare_elenco_doc::NUMERIC,
trim(tb.v_cod_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_stato_elenco_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_famiglia_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_gruppo_doc::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_doc::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_doc::VARCHAR)::VARCHAR,
tb.v_sogg_id_doc::INTEGER,
trim(tb.v_cod_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_doc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_doc::VARCHAR)::VARCHAR,
tb.v_num_subdoc::INTEGER,
trim(tb.v_desc_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_subdoc::NUMERIC,
trim(tb.v_num_reg_iva_subdoc::VARCHAR)::VARCHAR,
tb.v_data_scadenza_subdoc::TIMESTAMP,
trim(tb.v_convalida_manuale_subdoc::VARCHAR)::VARCHAR,
tb.v_importo_da_dedurre_subdoc::NUMERIC,
tb.v_splitreverse_importo_subdoc::NUMERIC,
tb.v_pagato_cec_subdoc,
tb.v_data_pagamento_cec_subdoc::TIMESTAMP,
trim(tb.v_note_tesoriere_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cod_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_desc_distinta_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_commissione_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_conto_tesoreria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rilevante_iva::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_singolo::VARCHAR)::VARCHAR,
trim(tb.v_ordinativo_manuale::VARCHAR)::VARCHAR,
trim(tb.v_esproprio::VARCHAR)::VARCHAR,
trim(tb.v_note::VARCHAR)::VARCHAR,
trim(tb.v_cig::VARCHAR)::VARCHAR,
trim(tb.v_cup::VARCHAR)::VARCHAR,
trim(tb.v_causale_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_riattivazione::VARCHAR)::VARCHAR,
trim(tb.v_causale_ordinativo::VARCHAR)::VARCHAR,
tb.v_num_mutuo::INTEGER,
trim(tb.v_annotazione::VARCHAR)::VARCHAR,
trim(tb.v_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_note_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_num_certificazione::VARCHAR)::VARCHAR,
trim(tb.v_data_scadenza_dopo_sospensione::VARCHAR)::VARCHAR,
trim(tb.v_data_esecuzione_pagamento::VARCHAR)::VARCHAR,
trim(tb.v_avviso::VARCHAR)::VARCHAR,
trim(tb.v_cod_tipo_avviso::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_avviso::VARCHAR)::VARCHAR,
tb.v_soggetto_id::INTEGER,
trim(tb.v_cod_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_sede_secondaria_subdoc::VARCHAR)::VARCHAR,
trim(tb.v_bil_anno::VARCHAR)::VARCHAR,
tb.v_anno_impegno::INTEGER,
tb.v_num_impegno::NUMERIC,
trim(tb.v_cod_impegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_impegno::VARCHAR)::VARCHAR,
trim(tb.v_cod_subimpegno::VARCHAR)::VARCHAR,
trim(tb.v_desc_subimpegno::VARCHAR)::VARCHAR,
tb.v_num_liquidazione::NUMERIC,
trim(tb.v_cod_tipo_accredito::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_accredito::VARCHAR)::VARCHAR,
tb.v_mod_pag_id::INTEGER,
trim(tb.v_quietanziante::VARCHAR)::VARCHAR,
tb.v_data_nasciata_quietanziante::TIMESTAMP,
trim(tb.v_luogo_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_stato_nascita_quietanziante::VARCHAR)::VARCHAR,
trim(tb.v_bic::VARCHAR)::VARCHAR,
trim(tb.v_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_intestazione_contocorrente::VARCHAR)::VARCHAR,
trim(tb.v_iban::VARCHAR)::VARCHAR,
trim(tb.v_note_mod_pag::VARCHAR)::VARCHAR,
tb.v_data_scadenza_mod_pag::TIMESTAMP,
tb.v_soggetto_id_modpag::INTEGER,
trim(tb.v_cod_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_tipo_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_stato_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_rag_sociale_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_p_iva_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cf_estero_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_nome_sogg_mod_pag::VARCHAR)::VARCHAR,
trim(tb.v_cognome_sogg_mod_pag::VARCHAR)::VARCHAR,
tb.v_anno_liquidazione::INTEGER,
trim(tb.v_bil_anno_ord::VARCHAR)::VARCHAR,
tb.v_anno_ord::INTEGER,
tb.v_num_ord::NUMERIC,
trim(tb.v_num_subord::VARCHAR)::VARCHAR,
--nuova sezione coge 26-09-2016
trim(tb.v_registro_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_anno_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_num_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_repertorio::VARCHAR)::VARCHAR,
trim(tb.v_data_ricezione_portale::VARCHAR)::VARCHAR,
trim(tb.v_doc_contabilizza_genpcc::VARCHAR)::VARCHAR,
-- CR 854
tb.rudoc_registrazione_anno::INTEGER,
tb.rudoc_registrazione_numero::INTEGER,
tb.rudoc_registrazione_data::TIMESTAMP,
trim(tb.cdc_code::VARCHAR)::VARCHAR,
trim(tb.cdc_desc::VARCHAR)::VARCHAR,
trim(tb.cdr_code::VARCHAR)::VARCHAR,
trim(tb.cdr_desc::VARCHAR)::VARCHAR,
trim(tb.v_dataOperazionePagamentoIncasso::VARCHAR)::VARCHAR,
trim(tb.v_flagPagataIncassata::VARCHAR)::VARCHAR,
trim(tb.v_notePagamentoIncasso::VARCHAR)::VARCHAR,
---- SIAC-5229
tb.v_arrotondamento,
-------------
trim(tb.v_cod_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_desc_tipo_splitrev::VARCHAR)::VARCHAR,
trim(tb.v_liq_stato_desc::VARCHAR)::VARCHAR,
tb.doc_sdi_lotto_siope,
tb.siope_documento_tipo_code,
tb.siope_documento_tipo_desc,
tb.siope_documento_tipo_desc_bnkit,
tb.siope_documento_tipo_analogico_code,
tb.siope_documento_tipo_analogico_desc,
tb.siope_documento_tipo_analogico_desc_bnkit,
tb.siope_tipo_debito_code,
tb.siope_tipo_debito_desc,
tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code,
tb.siope_assenza_motivazione_desc,
tb.siope_assenza_motivazione_desc_bnkit,
tb.siope_scadenza_motivo_code,
tb.siope_scadenza_motivo_desc,
tb.siope_scadenza_motivo_desc_bnkit ,
tb.doc_id -- SIAC-5573
from (
with doc as (
  with doc1 as (
select distinct
  --h.subdoc_id,a.doc_id,b.doc_tipo_id,c.doc_fam_tipo_id,d.doc_gruppo_tipo_id,e.doc_stato_r_id,f.doc_stato_id,
  b.doc_gruppo_tipo_id,
  g.ente_proprietario_id, g.ente_denominazione,
  a.doc_anno, a.doc_numero, a.doc_desc, a.doc_importo,
  case when a.doc_beneficiariomult= false then 'F' else 'T' end doc_beneficiariomult,
  a.doc_data_emissione, a.doc_data_scadenza,
  case when a.doc_collegato_cec = false then 'F' else 'T' end doc_collegato_cec,
  f.doc_stato_code, f.doc_stato_desc,
  c.doc_fam_tipo_code, c.doc_fam_tipo_desc, b.doc_tipo_code, b.doc_tipo_desc,
  a.doc_id, a.pcccod_id, a.pccuff_id,
  case when a.doc_contabilizza_genpcc= false then 'F' else 'T' end doc_contabilizza_genpcc,
  h.subdoc_numero, h.subdoc_desc, h.subdoc_importo, h.subdoc_nreg_iva, h.subdoc_data_scadenza,
  h.subdoc_convalida_manuale, h.subdoc_importo_da_dedurre, h.subdoc_splitreverse_importo,
  case when h.subdoc_pagato_cec = false then 'F' else 'T' end subdoc_pagato_cec,
  h.subdoc_data_pagamento_cec,
  a.codbollo_id, h.subdoc_id,h.comm_tipo_id,
  h.notetes_id,h.dist_id,h.contotes_id,
  a.doc_sdi_lotto_siope,
  n.siope_documento_tipo_code, n.siope_documento_tipo_desc, n.siope_documento_tipo_desc_bnkit,
  o.siope_documento_tipo_analogico_code, o.siope_documento_tipo_analogico_desc, o.siope_documento_tipo_analogico_desc_bnkit,
  i.siope_tipo_debito_code, i.siope_tipo_debito_desc, i.siope_tipo_debito_desc_bnkit,
  l.siope_assenza_motivazione_code, l.siope_assenza_motivazione_desc, l.siope_assenza_motivazione_desc_bnkit,
  m.siope_scadenza_motivo_code, m.siope_scadenza_motivo_desc, m.siope_scadenza_motivo_desc_bnkit
  from siac_t_doc a
  left join siac_d_siope_documento_tipo n on n.siope_documento_tipo_id = a.siope_documento_tipo_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
  left join siac_d_siope_documento_tipo_analogico o on o.siope_documento_tipo_analogico_id = a.siope_documento_tipo_analogico_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
  ,siac_d_doc_tipo b,siac_d_doc_fam_tipo c,
  --siac_d_doc_gruppo d,
  siac_r_doc_stato e,
  siac_d_doc_stato f,
  siac_t_ente_proprietario g,
  siac_t_subdoc h
  left join siac_d_siope_tipo_debito i on i.siope_tipo_debito_id = h.siope_tipo_debito_id
                                     and i.data_cancellazione is null
                                     and i.validita_fine is null
  left join siac_d_siope_assenza_motivazione l on l.siope_assenza_motivazione_id = h.siope_assenza_motivazione_id
                                             and l.data_cancellazione is null
                                             and l.validita_fine is null
  left join siac_d_siope_scadenza_motivo m on m.siope_scadenza_motivo_id = h.siope_scadenza_motivo_id
                                             and m.data_cancellazione is null
                                             and m.validita_fine is null
  where b.doc_tipo_id=a.doc_tipo_id
  and c.doc_fam_tipo_id=b.doc_fam_tipo_id
  --and b.doc_gruppo_tipo_id=d.doc_gruppo_tipo_id
  and e.doc_id=a.doc_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and f.doc_stato_id=e.doc_stato_id
  and g.ente_proprietario_id=a.ente_proprietario_id
  and g.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
  AND c.doc_fam_tipo_code in ('S','IS')
  and h.doc_id=a.doc_id
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  AND g.data_cancellazione IS NULL
  AND h.data_cancellazione IS NULL
)
, docgru as  (
select a.doc_gruppo_tipo_id, a.doc_gruppo_tipo_code, a.doc_gruppo_tipo_desc
 from siac_d_doc_gruppo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select doc1.*, docgru.* from doc1 left join docgru on
docgru.doc_gruppo_tipo_id = doc1.doc_gruppo_tipo_id
  )
  ,bollo as (
  select a.codbollo_id,a.codbollo_code, a.codbollo_desc from siac_d_codicebollo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null)
  ,sogg as (
  with sogg1 as (
  select distinct a.doc_id,b.soggetto_code,
  --d.soggetto_tipo_desc,
  f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_r_doc_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
 /* and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome, sogg5.soggetto_tipo_desc
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id=sogg5.soggetto_id
  )
  , reguni as (select a.doc_id,a.rudoc_registrazione_anno,
  a.rudoc_registrazione_numero,a.rudoc_registrazione_data
  from siac_t_registrounico_doc a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , cdr as (
  select a.doc_id, b.classif_code doc_cdr_cdr_code, b.classif_desc doc_cdr_cdr_desc ,
  null   doc_cdr_cdc_code, null  doc_cdr_cdc_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.doc_id, b.classif_code doc_cdc_cdc_code, b.classif_desc doc_cdc_cdc_desc,
  d.classif_code doc_cdc_cdr_code, d.classif_desc doc_cdc_cdr_desc
  from siac_r_doc_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL)
  ,pcccod as (select a.pcccod_id,a.pcccod_code,a.pcccod_desc from
  siac_d_pcc_codice  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , pccuff as (
  select a.pccuff_id,a.pccuff_code,a.pccuff_desc from
  siac_d_pcc_ufficio  a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , attoamm as (
  with attoamm1 as (
  select
  b.attoamm_id,
  a.subdoc_id,  b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
  d.attoamm_stato_code, d.attoamm_stato_desc,
  e.attoamm_tipo_code, e.attoamm_tipo_desc
  from
  siac_r_subdoc_atto_amm a ,siac_t_atto_amm b ,siac_r_atto_amm_stato c ,siac_d_atto_amm_stato d,
  siac_d_atto_amm_tipo e
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoamm_id=b.attoamm_id and c.attoamm_id=b.attoamm_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.attoamm_stato_id=c.attoamm_stato_id
  and e.attoamm_tipo_id=b.attoamm_tipo_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  and e.data_cancellazione is null
  ),
cdr as (
  select a.attoamm_id, b.classif_code attoamm_cdr_cdr_code, b.classif_desc attoamm_cdr_cdr_desc ,
  null::varchar  attoamm_cdr_cdc_code, null::varchar attoamm_cdr_cdc_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDR'
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  ),
  cdc as (
  select a.attoamm_id, b.classif_code attoamm_cdc_cdc_code, b.classif_desc attoamm_cdc_cdc_desc,
  d.classif_code attoamm_cdc_cdr_code, d.classif_desc attoamm_cdc_cdr_desc
  from siac_r_atto_amm_class a, siac_t_class b, siac_d_class_tipo c, siac_t_class d,siac_r_class_fam_tree e
  where a.classif_id=b.classif_id
  and b.classif_tipo_id=c.classif_tipo_id
  and c.classif_tipo_code='CDC'
  and b.classif_id=e.classif_id
  and d.classif_id=e.classif_id_padre
  -- and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data) -- SIAC-5494
  -- and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) -- SIAC-5494
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  )
  select   attoamm1.*,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_code::varchar else null::varchar end attoamm_cdc_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdc_desc::varchar else null::varchar end attoamm_cdc_desc,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_code::varchar else cdr.attoamm_cdr_cdr_code::varchar end attoamm_cdr_code,
  case when cdr.attoamm_cdr_cdr_code is null then cdc.attoamm_cdc_cdr_desc::varchar else cdr.attoamm_cdr_cdr_desc::varchar end attoamm_cdr_desc
  from attoamm1
  left join cdc on attoamm1.attoamm_id=cdc.attoamm_id
  left join cdr on attoamm1.attoamm_id=cdr.attoamm_id
  ),
  commt as (select a.comm_tipo_id,a.comm_tipo_code,a.comm_tipo_desc
   from siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  ,
  eldocattall as (
  with eldoc as (
  select a.subdoc_id,a.eldoc_id,
  b.eldoc_anno, b.eldoc_numero, b.eldoc_data_trasmissione, b.eldoc_tot_quoteentrate,
  b.eldoc_tot_quotespese, b.eldoc_tot_dapagare, b.eldoc_tot_daincassare,
  d.eldoc_stato_code, d.eldoc_stato_desc
   from
  siac_r_elenco_doc_subdoc a,siac_t_elenco_doc b, siac_r_elenco_doc_stato c,
  siac_d_elenco_doc_stato d
  where
  a.ente_proprietario_id=p_ente_proprietario_id and
  b.eldoc_id=a.eldoc_id
  and c.eldoc_id=b.eldoc_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and d.eldoc_stato_id=c.eldoc_stato_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  attoal as (with attoall as (
select distinct
  a.eldoc_id,b.attoal_id,
  b.attoal_causale, b.attoal_altriallegati, b.attoal_dati_sensibili,
         b.attoal_data_scadenza, b.attoal_note, b.attoal_annotazioni, b.attoal_pratica,
         b.attoal_responsabile_amm, b.attoal_responsabile_con, b.attoal_titolario_anno,
         b.attoal_titolario_numero, b.attoal_versione_invio_firma,
         d.attoal_stato_code, d.attoal_stato_desc
   from
  siac_r_atto_allegato_elenco_doc a, siac_t_atto_allegato b,
  siac_r_atto_allegato_stato c ,siac_d_atto_allegato_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id and
  a.attoal_id=b.attoal_id
  and c.attoal_id=b.attoal_id
  and d.attoal_stato_id=c.attoal_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and c.data_cancellazione is null
  and d.data_cancellazione is null
  ),
  soggattoall as (
  with sogg1 as (
  select distinct a.attoal_id,b.soggetto_code soggetto_code_atto_allegato,
  /*d.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato, */
  f.soggetto_stato_desc soggetto_stato_desc_atto_allegato,
  b.partita_iva partita_iva_atto_allegato, b.codice_fiscale codice_fiscale_atto_allegato,
  b.codice_fiscale_estero codice_fiscale_estero_atto_allegato,
   b.soggetto_id soggetto_id_atto_allegato
   from
  siac_r_atto_allegato_sog a, siac_t_soggetto b ,/*siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,*/siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  /*and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id*/
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  /*and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)*/
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
/*  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL*/
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg5 as (select
	c.soggetto_id,d.soggetto_tipo_desc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale ragione_sociale_atto_allegato,sogg3.nome nome_atto_allegato,
  sogg3.cognome cognome_atto_allegato, sogg5.soggetto_tipo_desc soggetto_tipo_desc_atto_allegato
  from sogg1 left join sogg2 on sogg1.soggetto_id_atto_allegato=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_atto_allegato=sogg3.soggetto_id
  left join sogg5 on sogg1.soggetto_id_atto_allegato=sogg5.soggetto_id
  )
  select attoall.*,soggattoall.ragione_sociale_atto_allegato,soggattoall.nome_atto_allegato,
  soggattoall.cognome_atto_allegato,   soggattoall.soggetto_code_atto_allegato,
  soggattoall.soggetto_tipo_desc_atto_allegato,
  soggattoall.soggetto_stato_desc_atto_allegato,
  soggattoall.partita_iva_atto_allegato, soggattoall.codice_fiscale_atto_allegato,
  soggattoall.codice_fiscale_estero_atto_allegato,
  soggattoall.soggetto_id_atto_allegato from attoall left join soggattoall
  on attoall.attoal_id=soggattoall.attoal_id
  )
  select distinct eldoc.*,
  attoal.attoal_id,
  attoal.attoal_causale, attoal.attoal_altriallegati, attoal.attoal_dati_sensibili,
         attoal.attoal_data_scadenza, attoal.attoal_note, attoal.attoal_annotazioni, attoal.attoal_pratica,
         attoal.attoal_responsabile_amm, attoal.attoal_responsabile_con, attoal.attoal_titolario_anno,
         attoal.attoal_titolario_numero, attoal.attoal_versione_invio_firma,
         attoal.attoal_stato_code, attoal.attoal_stato_desc,
   attoal.ragione_sociale_atto_allegato,attoal.nome_atto_allegato,attoal.cognome_atto_allegato,
   attoal.soggetto_code_atto_allegato,
  attoal.soggetto_tipo_desc_atto_allegato,
  attoal.soggetto_stato_desc_atto_allegato,
  attoal.partita_iva_atto_allegato, attoal.codice_fiscale_atto_allegato,
  attoal.codice_fiscale_estero_atto_allegato,
  attoal.soggetto_id_atto_allegato
   from eldoc left join attoal
  on eldoc.eldoc_id=attoal.eldoc_id
  ),
  notes as (
  select a.notetes_id,a.notetes_desc from
  siac.siac_d_note_tesoriere a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , dist as (
  select a.dist_id,a.dist_code, a.dist_desc from siac_d_distinta a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null)
  , contes as (
  select a.contotes_id,a.contotes_desc from siac_d_contotesoreria  a
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null),
  split as (select
  a.subdoc_id,b.sriva_tipo_code , b.sriva_tipo_desc from  siac_r_subdoc_splitreverse_iva_tipo a,
  siac_d_splitreverse_iva_tipo b
  where a.ente_proprietario_id=p_ente_proprietario_id and a.data_cancellazione is null
  and b.sriva_tipo_id=a.sriva_tipo_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  )
  , liq as (  select  a.subdoc_id,b.liq_anno,b.liq_numero ,d.liq_stato_desc
  from siac.siac_r_subdoc_liquidazione a ,siac_t_liquidazione b,siac_r_liquidazione_stato c ,
  siac_d_liquidazione_stato d
  where a.ente_proprietario_id=p_ente_proprietario_id
  and a.data_cancellazione is null
  and b.data_cancellazione is null
  and b.liq_id=a.liq_id
  and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  and c.liq_id=b.liq_id
  and d.liq_stato_id=c.liq_stato_id
  --and d.liq_stato_code<>'A'
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
),
subcltipoavviso as (select a.subdoc_id,b.classif_code cod_tipo_avviso,b.classif_desc desc_tipo_avviso
 from siac_r_subdoc_class a, siac_t_class b,siac_d_class_tipo c
where a.ente_proprietario_id=p_ente_proprietario_id and b.classif_id=a.classif_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.classif_tipo_id=b.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
docattr1 as (
SELECT distinct a.doc_id,
a.testo v_registro_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'registro_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr2 as (
SELECT distinct a.doc_id,
a.numerico v_anno_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'anno_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr3 as (
SELECT distinct a.doc_id,
a.testo v_num_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'num_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr4 as (
SELECT distinct a.doc_id,
a.testo v_data_repertorio
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_repertorio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr5 as (
SELECT distinct a.doc_id,
a.testo v_data_ricezione_portale
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataRicezionePortale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr6 as (
SELECT distinct a.doc_id,
a.testo v_dataOperazionePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataOperazionePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr7 as (
SELECT distinct a.doc_id,
a."boolean" v_flagPagataIncassata
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagPagataIncassata' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr8 as (
SELECT distinct a.doc_id,
a.testo v_notePagamentoIncasso
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'notePagamentoIncasso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
docattr9 as (
SELECT distinct a.doc_id,
a.numerico v_arrotondamento
 FROM   siac.siac_r_doc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'arrotondamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr1 as (
SELECT distinct a.subdoc_id,
a."boolean" v_rilevante_iva
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagRilevanteIVA' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr2 as (
SELECT a.subdoc_id, a.subdoc_attr_id,
a."boolean" v_ordinativo_singolo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoSingolo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)

,subdocattr3 as (
SELECT distinct a.subdoc_id,
a."boolean" v_esproprio
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagEsproprio' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr4 as (
SELECT distinct a.subdoc_id,
a."boolean" v_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr5 as (
SELECT distinct a.subdoc_id,
a."boolean" v_ordinativo_manuale
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagOrdinativoManuale' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr6 as (
SELECT distinct a.subdoc_id,
a."boolean" v_avviso
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'flagAvviso' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr7 as (
SELECT distinct a.subdoc_id,
a.numerico v_num_mutuo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroMutuo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr8 as (
SELECT distinct a.subdoc_id,
a.testo v_cup
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cup' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr9 as (
SELECT distinct a.subdoc_id,
a.testo v_cig
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'cig' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
,subdocattr10 as (
SELECT distinct a.subdoc_id,
a.testo v_note_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'noteCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr11 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,subdocattr12 as (
SELECT distinct a.subdoc_id,
a.testo v_data_esecuzione_pagamento
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataEsecuzionePagamento' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr13 as (
SELECT distinct a.subdoc_id,
a.testo v_annotazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'annotazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr14 as (
SELECT distinct a.subdoc_id,
a.testo v_num_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'numeroCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr15 as (
SELECT distinct a.subdoc_id,
a.testo v_data_scadenza_dopo_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataScadenzaDopoSospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr16 as (
*/
/*SELECT distinct a.subdoc_id,
a.testo v_data_riattivazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'data_riattivazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select a.subdoc_id,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
*/
,subdocattr17 as (
SELECT distinct a.subdoc_id,
a.testo v_causale_ordinativo
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causaleOrdinativo' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr18 as (
SELECT distinct a.subdoc_id,
a.testo v_note
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'Note' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),subdocattr19 as (
SELECT distinct a.subdoc_id,
a.testo v_data_certificazione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'dataCertificazione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
/* JIRA 5764
,subdocattr20 as (*/
/*SELECT distinct a.subdoc_id,
a.testo v_causale_sospensione
 FROM   siac.siac_r_subdoc_attr a, siac.siac_t_attr b, siac.siac_d_attr_tipo c
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and b.attr_code = 'causale_sospensione' and
    a.attr_id = b.attr_id
    AND    b.attr_tipo_id = c.attr_tipo_id
    AND    a.data_cancellazione IS NULL
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL
    AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)*/
/* JIRA 5764
select
	    a.subdoc_id
		,to_char(a.subdoc_sosp_data,'dd/mm/yyyy') v_data_sospensione
		,to_char(a.subdoc_sosp_data_riattivazione,'dd/mm/yyyy')  v_data_riattivazione
        ,a.subdoc_sosp_causale v_causale_sospensione from
siac_t_subdoc_sospensione a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)*/
,soggsub as (
  with sogg1 as (
  select distinct a.subdoc_id,b.soggetto_code soggetto_code_subdoc,
  f.soggetto_stato_desc soggetto_stato_desc_subdoc,
  b.partita_iva partita_iva_subdoc, b.codice_fiscale codice_fiscale_subdoc,
  b.codice_fiscale_estero codice_fiscale_estero_subdoc,
   b.soggetto_id soggetto_id_subdoc
   from
  siac_r_subdoc_sog a, siac_t_soggetto b ,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  a.ente_proprietario_id=p_ente_proprietario_id
  and a.soggetto_id=b.soggetto_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL
    AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale ragione_sociale_subdoc  from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome nome_subdoc, h.cognome cognome_subdoc from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  ),
  sogg4 as (
  SELECT a.soggetto_id_da, a.soggetto_id_a
    FROM siac.siac_r_soggetto_relaz a, siac.siac_d_relaz_tipo b
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id and
    a.relaz_tipo_id = b.relaz_tipo_id
    AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL)
    ,
sogg5 as (select
c.soggetto_id,d.soggetto_tipo_desc soggetto_tipo_desc_subdoc
 from siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d where c.ente_proprietario_id=p_ente_proprietario_id and
  d.soggetto_tipo_id=c.soggetto_tipo_id
  and c.data_cancellazione is null
  and d.data_cancellazione is NULL
  AND p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  )
  select sogg1.*, sogg2.ragione_sociale_subdoc,sogg3.nome_subdoc, sogg3.cognome_subdoc,
  case when sogg4.soggetto_id_da is not null then 'S' else NULL::varchar end v_sede_secondaria_subdoc
  , sogg5.soggetto_tipo_desc_subdoc
  from sogg1 left join sogg2 on sogg1.soggetto_id_subdoc=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id_subdoc=sogg3.soggetto_id
  left join sogg4 on sogg1.soggetto_id_subdoc=sogg4.soggetto_id_a
  left join sogg5 on sogg1.soggetto_id_subdoc=sogg5.soggetto_id
  ),
  imp as (select distinct
  c.movgest_id,b.movgest_ts_id,
a.subdoc_id,
case when g.movgest_ts_tipo_code ='T' then b.movgest_ts_code else NULL::varchar end v_cod_impegno,
case when g.movgest_ts_tipo_code ='T' then c.movgest_desc else NULL::varchar end v_desc_impegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_code else NULL::varchar end v_cod_subimpegno,
case when g.movgest_ts_tipo_code ='S' then b.movgest_ts_desc else NULL::varchar end v_desc_subimpegno,
e.anno v_bil_anno,
c.movgest_anno v_anno_impegno,
c.movgest_numero v_num_impegno,
g.movgest_ts_tipo_code
from
siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_t_movgest c, siac_t_bil d,
siac_t_periodo e, siac_d_movgest_tipo f, siac_d_movgest_ts_tipo g
where b.movgest_ts_id=A.movgest_ts_id
and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.movgest_id=b.movgest_id
and d.bil_id=c.bil_id
and e.periodo_id=d.periodo_id
and f.movgest_tipo_id=c.movgest_tipo_id
and g.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and f.movgest_tipo_code = 'I'
and a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
modpag as (
with modpag0 as (
with modpag1 as (
SELECT
a.subdoc_id,b.quietanziante, b.quietanzante_nascita_data, b.quietanziante_nascita_luogo, b.quietanziante_nascita_stato,
b.bic, b.contocorrente ,b.contocorrente_intestazione,b.iban , b.note , b.data_scadenza,b.accredito_tipo_id,
 b.soggetto_id,a.soggrelmpag_id, b.modpag_id
FROM siac.siac_r_subdoc_modpag a, siac.siac_t_modpag b where
a.ente_proprietario_id=p_ente_proprietario_id and
b.modpag_id = a.modpag_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL
)
,actipo as (
select a.accredito_tipo_id,
a.accredito_tipo_code ,
a.accredito_tipo_desc
 from siac.siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is NULL),
relmodpag as ( SELECT
 a.soggrelmpag_id,
b.soggetto_id_a v_soggetto_id_modpag_cess
 FROM  siac.siac_r_soggrel_modpag a, siac.siac_r_soggetto_relaz b
 WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_relaz_id = b.soggetto_relaz_id
 AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND   a.data_cancellazione IS NULL
 AND   p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
 AND   b.data_cancellazione IS NULL
 )
 select
modpag1.subdoc_id,
modpag1.quietanziante v_quietanziante,
modpag1.quietanzante_nascita_data v_data_nasciata_quietanziante,
modpag1.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
modpag1.quietanziante_nascita_stato v_stato_nascita_quietanziante,
modpag1.bic v_bic, modpag1.contocorrente v_contocorrente,
modpag1.contocorrente_intestazione v_intestazione_contocorrente,
modpag1.iban v_iban, modpag1.note v_note_mod_pag, modpag1.data_scadenza v_data_scadenza_mod_pag,
modpag1.accredito_tipo_id,
 modpag1.soggetto_id v_soggetto_id_modpag_nocess,
modpag1.soggrelmpag_id v_soggrelmpag_id, modpag1.modpag_id v_mod_pag_id,
actipo.accredito_tipo_code v_cod_tipo_accredito,
actipo.accredito_tipo_desc v_desc_tipo_accredito,
case when modpag1.soggrelmpag_id IS NULL THEN modpag1.soggetto_id else relmodpag.v_soggetto_id_modpag_cess
 end v_soggetto_id_modpag
 from modpag1 left join actipo
on modpag1.accredito_tipo_id=actipo.accredito_tipo_id
left join relmodpag on relmodpag.soggrelmpag_id=modpag1.soggrelmpag_id
)
,
 soggmodpag as (
  with sogg1 as (
  select distinct b.soggetto_code, d.soggetto_tipo_desc, f.soggetto_stato_desc,
  b.partita_iva, b.codice_fiscale, b.codice_fiscale_estero,
   b.soggetto_id
   from
  siac_t_soggetto b ,siac_r_soggetto_tipo c,
  siac_d_soggetto_tipo d,siac_r_soggetto_stato e ,siac_d_soggetto_stato f
  where
  b.ente_proprietario_id=p_ente_proprietario_id
  and c.soggetto_id=b.soggetto_id
  and d.soggetto_tipo_id=c.soggetto_tipo_id
  and e.soggetto_id=b.soggetto_id
  and f.soggetto_stato_id=e.soggetto_stato_id
  and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
  and p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
  AND b.data_cancellazione IS NULL
  AND c.data_cancellazione IS NULL
  AND d.data_cancellazione IS NULL
  AND e.data_cancellazione IS NULL
  AND f.data_cancellazione IS NULL
  --and b.soggetto_id=1862
  ),
  sogg2 as (
  select g.soggetto_id, g.ragione_sociale from  siac_t_persona_giuridica g
  where g.ente_proprietario_id=p_ente_proprietario_id and g.data_cancellazione is null)
  ,sogg3 as (
  select h.soggetto_id,h.nome, h.cognome from siac_t_persona_fisica h
  where h.ente_proprietario_id=p_ente_proprietario_id and h.data_cancellazione is null
  )
  select sogg1.*, sogg2.ragione_sociale,sogg3.nome, sogg3.cognome
  from sogg1 left join sogg2 on sogg1.soggetto_id=sogg2.soggetto_id
  left join sogg3 on sogg1.soggetto_id=sogg3.soggetto_id
  )
select modpag0.*,soggmodpag.soggetto_code v_cod_sogg_mod_pag, soggmodpag.soggetto_tipo_desc v_tipo_sogg_mod_pag,
soggmodpag.soggetto_stato_desc v_stato_sogg_mod_pag, soggmodpag.ragione_sociale v_rag_sociale_sogg_mod_pag,
soggmodpag.partita_iva v_p_iva_sogg_mod_pag, soggmodpag.codice_fiscale v_cf_sogg_mod_pag,
soggmodpag.codice_fiscale_estero v_cf_estero_sogg_mod_pag,
soggmodpag.nome v_nome_sogg_mod_pag, soggmodpag.cognome v_cognome_sogg_mod_pag
 from modpag0
left join soggmodpag on soggmodpag.soggetto_id=modpag0.v_soggetto_id_modpag
),
ord as (
SELECT
a.subdoc_id,
c.ord_anno, c.ord_numero, b.ord_ts_code, g.anno
    FROM  siac_r_subdoc_ordinativo_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo c,
          siac_r_ordinativo_stato d, siac_d_ordinativo_stato e,
          siac.siac_t_bil f, siac.siac_t_periodo g
    WHERE b.ord_ts_id = a.ord_ts_id
    AND   c.ord_id = b.ord_id
    AND   d.ord_id = c.ord_id
    AND   d.ord_stato_id = e.ord_stato_id
    AND   c.bil_id = f.bil_id
    AND   g.periodo_id = f.periodo_id
    AND   e.ord_stato_code <> 'A'
    AND   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   p_data between a.validita_inizio and COALESCE(a.validita_fine,p_data)
    AND   p_data between d.validita_inizio and COALESCE(d.validita_fine,p_data)
    )
  select doc.ente_proprietario_id v_ente_proprietario_id,
  doc.ente_denominazione v_ente_denominazione,
  doc.subdoc_id,
  doc.doc_anno v_anno_doc, doc.doc_numero v_num_doc,
  doc.doc_desc v_desc_doc,
  doc.doc_importo v_importo_doc,
  doc.doc_beneficiariomult v_beneficiario_multiplo_doc,
  doc.doc_data_emissione v_data_emissione_doc,
  doc.doc_data_scadenza v_data_scadenza_doc,
  bollo.codbollo_code v_codice_bollo_doc, bollo.codbollo_desc v_desc_codice_bollo_doc,
 doc.doc_collegato_cec v_collegato_cec_doc,
  pcccod.pcccod_code v_cod_pcc_doc,pcccod.pcccod_desc v_desc_pcc_doc
  ,pccuff.pccuff_code v_cod_ufficio_doc,pccuff.pccuff_desc v_desc_ufficio_doc,
  doc.doc_stato_code v_cod_stato_doc, doc.doc_stato_desc v_desc_stato_doc,
   doc.doc_fam_tipo_code v_cod_famiglia_doc, doc.doc_fam_tipo_desc v_desc_famiglia_doc,
doc.doc_tipo_code v_cod_tipo_doc, doc.doc_tipo_desc v_desc_tipo_doc,
doc.subdoc_numero v_num_subdoc, doc.subdoc_desc v_desc_subdoc,doc.subdoc_importo v_importo_subdoc,
doc.subdoc_nreg_iva v_num_reg_iva_subdoc, doc.subdoc_data_scadenza v_data_scadenza_subdoc,
doc.subdoc_convalida_manuale v_convalida_manuale_subdoc, doc.subdoc_importo_da_dedurre v_importo_da_dedurre_subdoc,
doc.subdoc_splitreverse_importo v_splitreverse_importo_subdoc,
doc.subdoc_pagato_cec v_pagato_cec_subdoc,
doc.subdoc_data_pagamento_cec v_data_pagamento_cec_subdoc,
doc.doc_contabilizza_genpcc v_doc_contabilizza_genpcc,
sogg.soggetto_id v_sogg_id_doc,sogg.soggetto_code v_cod_sogg_doc, sogg.soggetto_tipo_desc v_tipo_sogg_doc,
sogg.soggetto_stato_desc v_stato_sogg_doc,sogg.ragione_sociale v_rag_sociale_sogg_doc,
sogg.partita_iva v_p_iva_sogg_doc,
sogg.codice_fiscale v_cf_sogg_doc,
sogg.codice_fiscale_estero v_cf_estero_sogg_doc,
sogg.nome v_nome_sogg_doc, sogg.cognome v_cognome_sogg_doc,
reguni.rudoc_registrazione_anno,reguni.rudoc_registrazione_numero,reguni.rudoc_registrazione_data,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_code::varchar end cdc_code,
case when cdr.doc_cdr_cdr_code is not null then null::varchar else cdc.doc_cdc_cdc_desc::varchar end cdc_desc,
case when cdr.doc_cdr_cdr_code is not null then cdr.doc_cdr_cdr_code::varchar else cdc.doc_cdc_cdr_code::varchar end cdr_code,
case when cdr.doc_cdr_cdr_code is not null then cdc.doc_cdc_cdr_code::varchar else cdc.doc_cdc_cdr_desc::varchar end cdr_desc,
attoamm.attoamm_anno v_anno_atto_amministrativo, attoamm.attoamm_numero v_num_atto_amministrativo,
attoamm.attoamm_oggetto v_oggetto_atto_amministrativo, attoamm.attoamm_note v_note_atto_amministrativo,
attoamm.attoamm_stato_code v_cod_stato_atto_amministrativo, attoamm.attoamm_stato_desc v_desc_stato_atto_amministrativo,
attoamm.attoamm_tipo_code v_cod_tipo_atto_amministrativo, attoamm.attoamm_tipo_desc v_desc_tipo_atto_amministrativo,
attoamm.attoamm_cdc_code v_cod_cdc_atto_amministrativo,attoamm.attoamm_cdc_desc v_desc_cdc_atto_amministrativo,
attoamm.attoamm_cdr_code v_cod_cdr_atto_amministrativo,attoamm.attoamm_cdr_desc v_desc_cdr_atto_amministrativo,
commt.comm_tipo_code,commt.comm_tipo_desc v_tipo_commissione_subdoc,
eldocattall.subdoc_id,eldocattall.eldoc_id,
eldocattall.eldoc_anno v_anno_elenco_doc,
eldocattall.eldoc_numero v_num_elenco_doc,
eldocattall.eldoc_data_trasmissione v_data_trasmissione_elenco_doc,
eldocattall.eldoc_tot_quoteentrate v_tot_quote_entrate_elenco_doc,
eldocattall.eldoc_tot_quotespese v_tot_quote_spese_elenco_doc,
eldocattall.eldoc_tot_dapagare v_tot_da_pagare_elenco_doc,
eldocattall.eldoc_tot_daincassare v_tot_da_incassare_elenco_doc,
eldocattall.eldoc_stato_code v_cod_stato_elenco_doc,
eldocattall.eldoc_stato_desc v_desc_stato_elenco_doc,
eldocattall.attoal_id,
eldocattall.attoal_causale v_causale_atto_allegato,
eldocattall.attoal_altriallegati v_altri_allegati_atto_allegato, eldocattall.attoal_dati_sensibili v_dati_sensibili_atto_allegato,
eldocattall.attoal_data_scadenza v_data_scadenza_atto_allegato, eldocattall.attoal_note v_note_atto_allegato,
eldocattall.attoal_annotazioni v_annotazioni_atto_allegato, eldocattall.attoal_pratica v_pratica_atto_allegato,
eldocattall.attoal_responsabile_amm v_resp_amm_atto_allegato, eldocattall.attoal_responsabile_con v_resp_contabile_atto_allegato,
eldocattall.attoal_titolario_anno v_anno_titolario_atto_allegato,
eldocattall.attoal_titolario_numero v_num_titolario_atto_allegato, eldocattall.attoal_versione_invio_firma v_vers_invio_firma_atto_allegato,
eldocattall.attoal_stato_code v_cod_stato_atto_allegato, eldocattall.attoal_stato_desc v_desc_stato_atto_allegato,
eldocattall.ragione_sociale_atto_allegato v_rag_sociale_sogg_atto_allegato,
eldocattall.nome_atto_allegato v_nome_sogg_atto_allegato,
eldocattall.cognome_atto_allegato v_cognome_sogg_atto_allegato,
eldocattall.soggetto_code_atto_allegato v_cod_sogg_atto_allegato,
eldocattall.soggetto_tipo_desc_atto_allegato v_tipo_sogg_atto_allegato,
eldocattall.soggetto_stato_desc_atto_allegato v_stato_sogg_atto_allegato,
eldocattall.partita_iva_atto_allegato v_p_iva_sogg_atto_allegato,
eldocattall.codice_fiscale_atto_allegato v_cf_sogg_atto_allegato,
eldocattall.codice_fiscale_estero_atto_allegato v_cf_estero_sogg_atto_allegato,
eldocattall.soggetto_id_atto_allegato v_sogg_id_atto_allegato,
doc.doc_gruppo_tipo_code v_cod_gruppo_doc, doc.doc_gruppo_tipo_desc v_desc_gruppo_doc,
notes.notetes_desc v_note_tesoriere_subdoc,
dist.dist_code v_cod_distinta_subdoc, dist.dist_desc v_desc_distinta_subdoc,
contes.contotes_desc v_conto_tesoreria_subdoc,
split.sriva_tipo_code v_cod_tipo_splitrev , split.sriva_tipo_desc v_desc_tipo_splitrev,
liq.liq_anno v_anno_liquidazione,liq.liq_numero v_num_liquidazione,liq.liq_stato_desc v_liq_stato_desc,
subcltipoavviso.cod_tipo_avviso v_cod_tipo_avviso,subcltipoavviso.desc_tipo_avviso v_desc_tipo_avviso,
docattr1.v_registro_repertorio,
docattr2.v_anno_repertorio,
docattr3.v_num_repertorio,
docattr4.v_data_repertorio,
docattr5.v_data_ricezione_portale,
docattr6.v_dataOperazionePagamentoIncasso,
docattr7.v_flagPagataIncassata,
docattr8.v_notePagamentoIncasso,
-- 	SIAC-5229
docattr9.v_arrotondamento,
--
subdocattr1.v_rilevante_iva,
subdocattr2.v_ordinativo_singolo,
subdocattr3.v_esproprio,
subdocattr4.v_certificazione,
subdocattr5.v_ordinativo_manuale,
subdocattr6.v_avviso,
subdocattr7.v_num_mutuo,
subdocattr8.v_cup,
subdocattr9.v_cig,
subdocattr10.v_note_certificazione,
null::varchar v_data_sospensione, --subdocattr20.v_data_sospensione,--subdocattr11.v_data_sospensione, JIRA 5764
subdocattr12.v_data_esecuzione_pagamento,
subdocattr13.v_annotazione,
subdocattr14.v_num_certificazione,
subdocattr15.v_data_scadenza_dopo_sospensione,
null::varchar v_data_riattivazione,--subdocattr20.v_data_riattivazione,--subdocattr16.v_data_riattivazione, JIRA 5764
subdocattr17.v_causale_ordinativo,
subdocattr18.v_note,
subdocattr19.v_data_certificazione,
null::varchar v_causale_sospensione, --subdocattr20.v_causale_sospensione,JIRA 5764
soggsub.soggetto_code_subdoc v_cod_sogg_subdoc,
soggsub.soggetto_tipo_desc_subdoc v_tipo_sogg_subdoc,
soggsub.soggetto_stato_desc_subdoc v_stato_sogg_subdoc,
soggsub.partita_iva_subdoc v_p_iva_sogg_subdoc,
soggsub.codice_fiscale_subdoc v_cf_sogg_subdoc,
soggsub.codice_fiscale_estero_subdoc v_cf_estero_sogg_subdoc,
soggsub.soggetto_id_subdoc v_soggetto_id,
soggsub.nome_subdoc v_nome_sogg_subdoc,
soggsub.cognome_subdoc v_cognome_sogg_subdoc, soggsub.ragione_sociale_subdoc v_rag_sociale_sogg_subdoc,
soggsub.v_sede_secondaria_subdoc v_sede_secondaria_subdoc,
imp.v_cod_impegno v_cod_impegno,
imp.v_desc_impegno v_desc_impegno,
imp.v_cod_subimpegno v_cod_subimpegno,
imp.v_desc_subimpegno v_desc_subimpegno,
imp.v_bil_anno v_bil_anno,
imp.v_anno_impegno v_anno_impegno,
imp.v_num_impegno v_num_impegno,
imp.movgest_ts_tipo_code,
modpag.v_quietanziante v_quietanziante,
modpag.v_data_nasciata_quietanziante,
modpag.v_luogo_nascita_quietanziante,
modpag.v_stato_nascita_quietanziante,
modpag.v_bic, modpag.v_contocorrente,
modpag.v_intestazione_contocorrente,
modpag.v_iban, modpag.v_note_mod_pag, modpag.v_data_scadenza_mod_pag,
modpag.accredito_tipo_id,
modpag.v_soggetto_id_modpag_nocess,
modpag.v_soggrelmpag_id, modpag.v_mod_pag_id,
modpag.v_cod_tipo_accredito v_cod_tipo_accredito,
modpag.v_desc_tipo_accredito v_desc_tipo_accredito,
modpag.v_soggetto_id_modpag,
modpag.v_cod_sogg_mod_pag, modpag.v_tipo_sogg_mod_pag,
modpag.v_stato_sogg_mod_pag, modpag.v_rag_sociale_sogg_mod_pag,
modpag.v_p_iva_sogg_mod_pag, modpag.v_cf_sogg_mod_pag,
modpag.v_cf_estero_sogg_mod_pag,
modpag.v_nome_sogg_mod_pag, modpag.v_cognome_sogg_mod_pag,
ord.subdoc_id,
ord.ord_anno v_anno_ord, ord.ord_numero v_num_ord, ord.ord_ts_code v_num_subord, ord.anno v_bil_anno_ord,
doc.doc_sdi_lotto_siope,
doc.siope_documento_tipo_code, doc.siope_documento_tipo_desc, doc.siope_documento_tipo_desc_bnkit,
doc.siope_documento_tipo_analogico_code, doc.siope_documento_tipo_analogico_desc, doc.siope_documento_tipo_analogico_desc_bnkit,
doc.siope_tipo_debito_code, doc.siope_tipo_debito_desc, doc.siope_tipo_debito_desc_bnkit,
doc.siope_assenza_motivazione_code, doc.siope_assenza_motivazione_desc, doc.siope_assenza_motivazione_desc_bnkit,
doc.siope_scadenza_motivo_code, doc.siope_scadenza_motivo_desc, doc.siope_scadenza_motivo_desc_bnkit,
doc.doc_id -- SIAC-5573
from doc
left join bollo on doc.codbollo_id=bollo.codbollo_id
left join sogg on doc.doc_id=sogg.doc_id
left join reguni on doc.doc_id=reguni.doc_id
left join cdc on doc.doc_id=cdc.doc_id
left join cdr on doc.doc_id=cdr.doc_id
left join pcccod on doc.pcccod_id=pcccod.pcccod_id
left join pccuff on doc.pccuff_id=pccuff.pccuff_id
left join attoamm on doc.subdoc_id=attoamm.subdoc_id
left join commt on doc.comm_tipo_id=commt.comm_tipo_id
left join eldocattall on doc.subdoc_id=eldocattall.subdoc_id
left join notes on doc.notetes_id=notes.notetes_id
left join dist  on doc.dist_id=dist.dist_id
left join contes on doc.contotes_id=contes.contotes_id
left join split on doc.subdoc_id=split.subdoc_id
left join liq on doc.subdoc_id=liq.subdoc_id --origina multipli
left join  subcltipoavviso on doc.subdoc_id=subcltipoavviso.subdoc_id
left join docattr1 on doc.doc_id=docattr1.doc_id
left join docattr2 on doc.doc_id=docattr2.doc_id
left join docattr3 on doc.doc_id=docattr3.doc_id
left join docattr4 on doc.doc_id=docattr4.doc_id
left join docattr5 on doc.doc_id=docattr5.doc_id
left join docattr6 on doc.doc_id=docattr6.doc_id
left join docattr7 on doc.doc_id=docattr7.doc_id
left join docattr8 on doc.doc_id=docattr8.doc_id
left join docattr9 on doc.doc_id=docattr9.doc_id
left join subdocattr1 on doc.subdoc_id=subdocattr1.subdoc_id
left join subdocattr2 on doc.subdoc_id=subdocattr2.subdoc_id
left join subdocattr3 on doc.subdoc_id=subdocattr3.subdoc_id
left join subdocattr4 on doc.subdoc_id=subdocattr4.subdoc_id
left join subdocattr5 on doc.subdoc_id=subdocattr5.subdoc_id
left join subdocattr6 on doc.subdoc_id=subdocattr6.subdoc_id
left join subdocattr7 on doc.subdoc_id=subdocattr7.subdoc_id
left join subdocattr8 on doc.subdoc_id=subdocattr8.subdoc_id
left join subdocattr9 on doc.subdoc_id=subdocattr9.subdoc_id
left join subdocattr10 on doc.subdoc_id=subdocattr10.subdoc_id
--left join subdocattr11 on doc.subdoc_id=subdocattr11.subdoc_id
left join subdocattr12 on doc.subdoc_id=subdocattr12.subdoc_id
left join subdocattr13 on doc.subdoc_id=subdocattr13.subdoc_id
left join subdocattr14 on doc.subdoc_id=subdocattr14.subdoc_id
left join subdocattr15 on doc.subdoc_id=subdocattr15.subdoc_id
--left join subdocattr16 on doc.subdoc_id=subdocattr16.subdoc_id
left join subdocattr17 on doc.subdoc_id=subdocattr17.subdoc_id
left join subdocattr18 on doc.subdoc_id=subdocattr18.subdoc_id
left join subdocattr19 on doc.subdoc_id=subdocattr19.subdoc_id
--left join subdocattr20 on doc.subdoc_id=subdocattr20.subdoc_id jira 5764
left join soggsub on soggsub.subdoc_id = doc.subdoc_id
left join imp on imp.subdoc_id=doc.subdoc_id
left join modpag on modpag.subdoc_id=doc.subdoc_id
left join ord on ord.subdoc_id = doc.subdoc_id
) as tb;


esito:= 'Fine funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti spesa (FNC_SIAC_DWH_DOCUMENTO_SPESA) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

-- FINE SIAC-5764
-- FINE DANIELA

-- SIAC-5571 INIZIO
CREATE OR REPLACE VIEW siac.siac_v_dwh_fattura_sirfel (
    ente_proprietario_id,
    fornitore_cod,
    fornitore_desc,
    data_emissione,
    data_ricezione,
    numero_documento,
    documento_fel_tipo_cod,
    documento_fel_tipo_desc,
    data_acquisizione,
    stato_acquisizione,
    importo_lordo,
    arrotondamento_fel,
    importo_netto,
    codice_destinatario,
    tipo_ritenuta,
    aliquota_ritenuta,
    importo_ritenuta,
    anno_protocollo,
    numero_protocollo,
    registro_protocollo,
    data_reg_protocollo,
    modpag_cod,
    modpag_desc,
    aliquota_iva,
    imponibile,
    imposta,
    arrotondamento_onere,
    spese_accessorie,
    doc_id,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc)
AS
SELECT tab.ente_proprietario_id, tab.fornitore_cod, tab.fornitore_desc,
    tab.data_emissione, tab.data_ricezione, tab.numero_documento,
    tab.documento_fel_tipo_cod, tab.documento_fel_tipo_desc,
    tab.data_acquisizione, tab.stato_acquisizione, tab.importo_lordo,
    tab.arrotondamento_fel, tab.importo_netto, tab.codice_destinatario,
    tab.tipo_ritenuta, tab.aliquota_ritenuta, tab.importo_ritenuta,
    tab.anno_protocollo, tab.numero_protocollo, tab.registro_protocollo,
    tab.data_reg_protocollo, tab.modpag_cod, tab.modpag_desc, tab.aliquota_iva,
    tab.imponibile, tab.imposta, tab.arrotondamento_onere, tab.spese_accessorie,
    tab.doc_id, tab.anno_doc, tab.num_doc, tab.data_emissione_doc,
    tab.cod_tipo_doc, tab.cod_sogg_doc
FROM ( WITH dati_sirfel AS (
    SELECT tf.ente_proprietario_id,
                    tp.codice_prestatore AS fornitore_cod,
                        CASE
                            WHEN tp.denominazione_prestatore IS NULL THEN
                                ((tp.nome_prestatore::text || ' '::text) || tp.cognome_prestatore::text)::character varying
                            ELSE tp.denominazione_prestatore
                        END AS fornitore_desc,
                    tf.data AS data_emissione, tpf.data_ricezione,
                    tf.numero AS numero_documento,
                    dtd.codice AS documento_fel_tipo_cod,
                    dtd.descrizione AS documento_fel_tipo_desc,
                    tf.data_caricamento AS data_acquisizione,
                        CASE
                            WHEN tf.stato_fattura = 'S'::bpchar THEN 'IMPORTATA'::text
                            ELSE
                            CASE
                                WHEN tf.stato_fattura = 'N'::bpchar THEN
                                    'DA ACQUISIRE'::text
                                ELSE 'SOSPESA'::text
                            END
                        END AS stato_acquisizione,
                    tf.importo_totale_documento AS importo_lordo,
                    tf.arrotondamento AS arrotondamento_fel,
                    tf.importo_totale_netto AS importo_netto,
                    tf.codice_destinatario, tf.tipo_ritenuta,
                    tf.aliquota_ritenuta, tf.importo_ritenuta,
                    tpro.anno_protocollo, tpro.numero_protocollo,
                    tpro.registro_protocollo, tpro.data_reg_protocollo,
                    tpagdett.modalita_pagamento AS modpag_cod,
                    dmodpag.descrizione AS modpag_desc, trb.aliquota_iva,
                    trb.imponibile_importo AS imponibile, trb.imposta,
                    trb.arrotondamento AS arrotondamento_onere,
                    trb.spese_accessorie, tf.id_fattura
    FROM sirfel_t_fattura tf
              JOIN sirfel_t_prestatore tp ON tf.id_prestatore =
                  tp.id_prestatore AND tf.ente_proprietario_id = tp.ente_proprietario_id
         LEFT JOIN sirfel_t_portale_fatture tpf ON tf.id_fattura =
             tpf.id_fattura AND tf.ente_proprietario_id = tpf.ente_proprietario_id
    LEFT JOIN sirfel_d_tipo_documento dtd ON tf.tipo_documento::text =
        dtd.codice::text AND tf.ente_proprietario_id = dtd.ente_proprietario_id
   LEFT JOIN sirfel_t_riepilogo_beni trb ON tf.id_fattura = trb.id_fattura AND
       tf.ente_proprietario_id = trb.ente_proprietario_id
   LEFT JOIN sirfel_t_protocollo tpro ON tf.id_fattura = tpro.id_fattura AND
       tf.ente_proprietario_id = tpro.ente_proprietario_id
   LEFT JOIN sirfel_t_pagamento tpag ON tf.id_fattura = tpag.id_fattura AND
       tf.ente_proprietario_id = tpag.ente_proprietario_id
   LEFT JOIN sirfel_t_dettaglio_pagamento tpagdett ON tpag.id_fattura =
       tpagdett.id_fattura AND tpag.progressivo = tpagdett.progressivo_pagamento AND tpag.ente_proprietario_id = tpagdett.ente_proprietario_id
   LEFT JOIN sirfel_d_modalita_pagamento dmodpag ON
       tpagdett.modalita_pagamento::text = dmodpag.codice::text AND tpagdett.ente_proprietario_id = dmodpag.ente_proprietario_id
    ), dati_fattura AS (
    SELECT rdoc.ente_proprietario_id, rdoc.id_fattura, tdoc.doc_id,
                    tdoc.doc_anno AS anno_doc, tdoc.doc_numero AS num_doc,
                    tdoc.doc_data_emissione AS data_emissione_doc,
                    ddoctipo.doc_tipo_code AS cod_tipo_doc,
                    tsogg.soggetto_code AS cod_sogg_doc
    FROM siac_r_doc_sirfel rdoc
              JOIN siac_t_doc tdoc ON tdoc.doc_id = rdoc.doc_id
         JOIN siac_d_doc_tipo ddoctipo ON tdoc.doc_tipo_id = ddoctipo.doc_tipo_id
    LEFT JOIN siac_r_doc_sog rdocsog ON tdoc.doc_id = rdocsog.doc_id AND
        rdocsog.data_cancellazione IS NULL AND now() >= rdocsog.validita_inizio AND now() <= COALESCE(rdocsog.validita_fine::timestamp with time zone, now())
   LEFT JOIN siac_t_soggetto tsogg ON rdocsog.soggetto_id = tsogg.soggetto_id
       AND tsogg.data_cancellazione IS NULL
    WHERE rdoc.data_cancellazione IS NULL AND tdoc.data_cancellazione IS NULL
        AND now() >= rdoc.validita_inizio AND now() <= COALESCE(rdoc.validita_fine::timestamp with time zone, now())
    )
    SELECT dati_sirfel.ente_proprietario_id, dati_sirfel.fornitore_cod,
            dati_sirfel.fornitore_desc, dati_sirfel.data_emissione,
            dati_sirfel.data_ricezione, dati_sirfel.numero_documento,
            dati_sirfel.documento_fel_tipo_cod,
            dati_sirfel.documento_fel_tipo_desc, dati_sirfel.data_acquisizione,
            dati_sirfel.stato_acquisizione, dati_sirfel.importo_lordo,
            dati_sirfel.arrotondamento_fel, dati_sirfel.importo_netto,
            dati_sirfel.codice_destinatario, dati_sirfel.tipo_ritenuta,
            dati_sirfel.aliquota_ritenuta, dati_sirfel.importo_ritenuta,
            dati_sirfel.anno_protocollo, dati_sirfel.numero_protocollo,
            dati_sirfel.registro_protocollo, dati_sirfel.data_reg_protocollo,
            dati_sirfel.modpag_cod, dati_sirfel.modpag_desc,
            dati_sirfel.aliquota_iva, dati_sirfel.imponibile,
            dati_sirfel.imposta, dati_sirfel.arrotondamento_onere,
            dati_sirfel.spese_accessorie, dati_sirfel.id_fattura,
            dati_fattura.doc_id, dati_fattura.anno_doc, dati_fattura.num_doc,
            dati_fattura.data_emissione_doc, dati_fattura.cod_tipo_doc,
            dati_fattura.cod_sogg_doc
    FROM dati_sirfel
      LEFT JOIN dati_fattura ON dati_sirfel.id_fattura =
          dati_fattura.id_fattura AND dati_sirfel.ente_proprietario_id = dati_fattura.ente_proprietario_id
    ) tab;
-- SIAC-5571 FINE

-- SIAC-5570 INIZIO
CREATE OR REPLACE VIEW siac.siac_v_dwh_oneri_doc (
    ente_proprietario_id,
    doc_tipo_code,
    doc_anno,
    doc_numero,
    data_emissione,
    soggetto_id,
    soggetto_code,
    onere_tipo_code,
    onere_tipo_desc,
    onere_code,
    onere_desc,
    importo_imponibile,
    importo_carico_ente,
    importo_carico_soggetto,
    somma_non_soggetta,
    perc_carico_ente,
    perc_carico_sogg,
    doc_stato_code,
    doc_stato_desc,
    doc_id,
    attivita_code,
    attivita_desc,
    attivita_inizio,
    attivita_fine,
    quadro_770,
    causale_code,
    causale_desc,
    somma_non_soggetta_tipo_code,
    somma_non_soggetta_tipo_desc)
AS
SELECT DISTINCT tb.ente_proprietario_id, tb.doc_tipo_code, tb.doc_anno,
    tb.doc_numero, tb.doc_data_emissione AS data_emissione, tb.soggetto_id,
    tb.soggetto_code, tb.onere_code AS onere_tipo_code,
    tb.onere_desc AS onere_tipo_desc, tb.onere_tipo_code AS onere_code,
    tb.onere_tipo_desc AS onere_desc, tb.importo_imponibile,
    tb.importo_carico_ente, tb.importo_carico_soggetto, tb.somma_non_soggetta,
    tb.perc_carico_ente, tb.perc_carico_sogg, tb.doc_stato_code,
    tb.doc_stato_desc, tb.doc_id, tb.onere_att_code AS attivita_code,
    tb.onere_att_desc AS attivita_desc, tb.attivita_inizio, tb.attivita_fine,
    tb.quadro_770, tb.caus_code AS causale_code, tb.caus_desc AS causale_desc,
    tb.somma_non_soggetta_tipo_code, tb.somma_non_soggetta_tipo_desc
FROM ( WITH aa AS (
    SELECT a.ente_proprietario_id, dt.doc_tipo_code, d.doc_anno,
                    d.doc_numero, d.doc_data_emissione, e.soggetto_id,
                    e.soggetto_code, a.onere_code, a.onere_desc,
                    b.onere_tipo_code, b.onere_tipo_desc, c.importo_imponibile,
                    c.importo_carico_ente, c.importo_carico_soggetto,
                    COALESCE(c.somma_non_soggetta, 0::numeric) AS somma_non_soggetta,
                    a.onere_id, g.doc_stato_code, g.doc_stato_desc, d.doc_id,
                    c.onere_att_id, c.caus_id, c.somma_non_soggetta_tipo_id,
                    c.attivita_inizio, c.attivita_fine
    FROM siac_d_onere a, siac_d_onere_tipo b, siac_r_doc_onere c,
                    siac_t_doc d, siac_d_doc_tipo dt, siac_r_doc_sog er,
                    siac_t_soggetto e, siac_r_doc_stato f, siac_d_doc_stato g
    WHERE a.onere_tipo_id = b.onere_tipo_id AND a.onere_id = c.onere_id AND
        c.doc_id = d.doc_id AND dt.doc_tipo_id = d.doc_tipo_id AND er.doc_id = d.doc_id AND er.soggetto_id = e.soggetto_id AND f.doc_id = d.doc_id AND f.doc_stato_id = g.doc_stato_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND dt.data_cancellazione IS NULL AND er.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL AND g.data_cancellazione IS NULL AND now() >= c.validita_inizio AND now() <= COALESCE(c.validita_fine::timestamp with time zone, now()) AND now() >= er.validita_inizio AND now() <= COALESCE(er.validita_fine::timestamp with time zone, now()) AND now() >= f.validita_inizio AND now() <= COALESCE(f.validita_fine::timestamp with time zone, now())
    ), bb AS (
    SELECT rattr1.onere_id,
                    COALESCE(rattr1.percentuale, 0::numeric) AS perc_carico_ente
    FROM siac_r_onere_attr rattr1, siac_t_attr attr1
    WHERE rattr1.attr_id = attr1.attr_id AND attr1.attr_code::text =
        'ALIQUOTA_ENTE'::text AND rattr1.data_cancellazione IS NULL AND attr1.data_cancellazione IS NULL AND now() >= rattr1.validita_inizio AND now() <= COALESCE(rattr1.validita_fine::timestamp with time zone, now())
    ), cc AS (
    SELECT rattr2.onere_id,
                    COALESCE(rattr2.percentuale, 0::numeric) AS perc_carico_sogg
    FROM siac_r_onere_attr rattr2, siac_t_attr attr2
    WHERE rattr2.attr_id = attr2.attr_id AND attr2.attr_code::text =
        'ALIQUOTA_SOGG'::text AND rattr2.data_cancellazione IS NULL AND attr2.data_cancellazione IS NULL AND now() >= rattr2.validita_inizio AND now() <= COALESCE(rattr2.validita_fine::timestamp with time zone, now())
    ), dd AS (
    SELECT roa.onere_id, doa.onere_att_code, doa.onere_att_desc,
                    roa.onere_att_id
    FROM siac_r_onere_attivita roa, siac_d_onere_attivita doa
    WHERE roa.onere_att_id = doa.onere_att_id AND roa.data_cancellazione IS
        NULL AND doa.data_cancellazione IS NULL AND now() >= roa.validita_inizio AND now() <= COALESCE(roa.validita_fine::timestamp with time zone, now())
    ), ee AS (
    SELECT rattr3.onere_id, rattr3.testo AS quadro_770
    FROM siac_r_onere_attr rattr3, siac_t_attr attr3
    WHERE rattr3.attr_id = attr3.attr_id AND attr3.attr_code::text =
        'QUADRO_770'::text AND rattr3.data_cancellazione IS NULL AND attr3.data_cancellazione IS NULL AND now() >= rattr3.validita_inizio AND now() <= COALESCE(rattr3.validita_fine::timestamp with time zone, now())
    ), ff AS (
    SELECT dc.caus_id, dc.caus_code, dc.caus_desc
    FROM siac_d_causale dc
    WHERE dc.data_cancellazione IS NULL
    ), gg AS (
    SELECT dsnst.somma_non_soggetta_tipo_id,
                    dsnst.somma_non_soggetta_tipo_code,
                    dsnst.somma_non_soggetta_tipo_desc
    FROM siac_d_somma_non_soggetta_tipo dsnst
    WHERE dsnst.data_cancellazione IS NULL
    )
    SELECT aa.ente_proprietario_id, aa.doc_tipo_code, aa.doc_anno,
            aa.doc_numero, aa.doc_data_emissione, aa.soggetto_id,
            aa.soggetto_code, aa.onere_code, aa.onere_desc, aa.onere_tipo_code,
            aa.onere_tipo_desc, aa.importo_imponibile, aa.importo_carico_ente,
            aa.importo_carico_soggetto, aa.somma_non_soggetta,
            bb.perc_carico_ente, cc.perc_carico_sogg, aa.doc_stato_code,
            aa.doc_stato_desc, aa.doc_id, dd.onere_att_code, dd.onere_att_desc,
            aa.attivita_inizio, aa.attivita_fine, ee.quadro_770, ff.caus_code,
            ff.caus_desc, gg.somma_non_soggetta_tipo_code,
            gg.somma_non_soggetta_tipo_desc
    FROM aa
      LEFT JOIN bb ON aa.onere_id = bb.onere_id
   LEFT JOIN cc ON aa.onere_id = cc.onere_id
   LEFT JOIN dd ON aa.onere_id = dd.onere_id AND aa.onere_att_id = dd.onere_att_id
   LEFT JOIN ee ON aa.onere_id = ee.onere_id
   LEFT JOIN ff ON aa.caus_id = ff.caus_id
   LEFT JOIN gg ON aa.somma_non_soggetta_tipo_id = gg.somma_non_soggetta_tipo_id
    ) tb;
-- SIAC-5570 FINE 

-- SIAC-5573 INIZIO
CREATE OR REPLACE VIEW siac.siac_v_dwh_carta_contabile (
    ente_proprietario_id,
    anno_bilancio,
    cartac_stato_code,
    cartac_stato_desc,
    crt_det_sogg_id,
    soggetto_code,
    soggetto_desc,
    attoamm_anno,
    attoamm_numero,
    attoamm_tipo_code,
    attoamm_tipo_desc,
    cod_sac,
    desc_sac,
    cartac_numero,
    cartac_importo,
    cartac_oggetto,
    causale_carta,
    cartac_data_scadenza,
    cartac_data_pagamento,
    note_carta,
    urgenza,
    flagisestera,
    est_causale,
    est_valuta,
    est_data_valuta,
    est_titolare_diverso,
    est_istruzioni,
    crt_det_numero,
    crt_det_desc,
    crt_det_importo,
    crt_det_valuta,
    crt_det_contotesoriere,
    crt_det_mdp_id,
    movgest_anno,
    movgest_numero,
    subimpegno,
    doc_anno,
    doc_numero,
    doc_tipo_code,
    doc_fam_tipo_code,
    doc_data_emissione,
    soggetto_doc,
    subdoc_numero,
    anno_elenco_doc,
    num_elenco_doc,
    doc_id)
AS
SELECT tbb.ente_proprietario_id, tbb.anno_bilancio, tbb.cartac_stato_code,
    tbb.cartac_stato_desc, tbb.crt_det_sogg_id, tbb.soggetto_code,
    tbb.soggetto_desc, tbb.attoamm_anno, tbb.attoamm_numero,
    tbb.attoamm_tipo_code, tbb.attoamm_tipo_desc, tbb.cod_sac, tbb.desc_sac,
    tbb.cartac_numero, tbb.cartac_importo, tbb.cartac_oggetto,
    tbb.causale_carta, tbb.cartac_data_scadenza, tbb.cartac_data_pagamento,
    tbb.note_carta, tbb.urgenza, tbb.flagisestera, tbb.est_causale,
    tbb.est_valuta, tbb.est_data_valuta, tbb.est_titolare_diverso,
    tbb.est_istruzioni, tbb.crt_det_numero, tbb.crt_det_desc,
    tbb.crt_det_importo, tbb.crt_det_valuta, tbb.crt_det_contotesoriere,
    tbb.crt_det_mdp_id, tbb.movgest_anno, tbb.movgest_numero, tbb.subimpegno,
    tbb.doc_anno, tbb.doc_numero, tbb.doc_tipo_code, tbb.doc_fam_tipo_code,
    tbb.doc_data_emissione, tbb.soggetto_doc, tbb.subdoc_numero,
    tbb.anno_elenco_doc, tbb.num_elenco_doc,
    tbb.doc_id
FROM ( WITH aa AS (
    SELECT DISTINCT a.ente_proprietario_id, d.anno,
                    f.cartac_stato_id, f.cartac_stato_code, f.cartac_stato_desc,
                    a.cartac_numero, a.cartac_importo, a.cartac_oggetto,
                    a.cartac_causale, a.cartac_data_scadenza,
                    a.cartac_data_pagamento, a.cartac_importo_valuta,
                    a.cartac_id, b.cartac_det_numero, b.cartac_det_desc,
                    b.cartac_det_importo, b.cartac_det_importo_valuta,
                    b.contotes_id, b.cartac_det_id, a.attoamm_id
    FROM siac_t_cartacont a, siac_t_cartacont_det b,
                    siac_t_bil c, siac_t_periodo d, siac_r_cartacont_stato e,
                    siac_d_cartacont_stato f
    WHERE a.cartac_id = b.cartac_id AND a.bil_id = c.bil_id AND d.periodo_id =
        c.periodo_id AND e.cartac_id = a.cartac_id AND e.cartac_stato_id = f.cartac_stato_id AND a.data_cancellazione IS NULL AND b.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND now() >= e.validita_inizio AND now() <= COALESCE(e.validita_fine::timestamp with time zone, now())
    ), bb AS (
    SELECT notes.contotes_code, notes.contotes_id
    FROM siac_d_contotesoreria notes
    WHERE notes.data_cancellazione IS NULL
    ), cc AS (
    SELECT i.cartacest_id, i.cartacest_causalepagamento,
                    i.cartacest_data_valuta, i.cartacest_diversotitolare,
                    i.cartacest_istruzioni, i.cartac_id
    FROM siac_t_cartacont_estera i
    WHERE i.data_cancellazione IS NULL
    ), dd AS (
    SELECT rmdp.modpag_id, rmdp.cartac_det_id
    FROM siac_r_cartacont_det_modpag rmdp
    WHERE rmdp.data_cancellazione IS NULL AND now() >= rmdp.validita_inizio AND
        now() <= COALESCE(rmdp.validita_fine::timestamp with time zone, now())
    ), ee AS (
    SELECT rmvgest.cartac_det_id, mvgts.movgest_ts_id_padre,
                    movgest.movgest_anno, movgest.movgest_numero,
                    mvgts.movgest_ts_code
    FROM siac_r_cartacont_det_movgest_ts rmvgest,
                    siac_t_movgest_ts mvgts, siac_t_movgest movgest
    WHERE rmvgest.movgest_ts_id = mvgts.movgest_ts_id AND mvgts.movgest_id =
        movgest.movgest_id AND rmvgest.data_cancellazione IS NULL AND mvgts.data_cancellazione IS NULL AND movgest.data_cancellazione IS NULL AND now() >= rmvgest.validita_inizio AND now() <= COALESCE(rmvgest.validita_fine::timestamp with time zone, now())
    ), ff AS (
    SELECT rsog.soggetto_id, rsog.cartac_det_id, b.soggetto_code,
                    b.soggetto_desc
    FROM siac_r_cartacont_det_soggetto rsog, siac_t_soggetto b
    WHERE rsog.data_cancellazione IS NULL AND b.soggetto_id = rsog.soggetto_id
        AND rsog.validita_fine IS NULL
    ), gg AS (
    SELECT tb.doc_id, tb.cartac_det_id, tb.doc_anno, tb.doc_numero,
                    tb.doc_tipo_code, tb.doc_fam_tipo_code,
                    tb.doc_data_emissione, tb.soggetto_id, tb.subdoc_numero,
                    tb.anno_elenco_doc, tb.num_elenco_doc
    FROM ( WITH gg1 AS (
        SELECT doc.doc_id, rsubdoc.cartac_det_id,
                                    doc.doc_anno, doc.doc_numero,
                                    e.doc_tipo_code, d.doc_fam_tipo_code,
                                    doc.doc_data_emissione,
                                    subdoc.subdoc_numero, subdoc.subdoc_id
        FROM siac_r_cartacont_det_subdoc rsubdoc,
                                    siac_t_subdoc subdoc, siac_t_doc doc,
                                    siac_d_doc_fam_tipo d, siac_d_doc_tipo e
        WHERE subdoc.subdoc_id = rsubdoc.subdoc_id AND doc.doc_id =
            subdoc.doc_id AND rsubdoc.data_cancellazione IS NULL AND subdoc.data_cancellazione IS NULL AND doc.data_cancellazione IS NULL AND e.doc_tipo_id = doc.doc_tipo_id AND d.doc_fam_tipo_id = e.doc_fam_tipo_id AND e.data_cancellazione IS NULL AND d.data_cancellazione IS NULL
        ), gg2 AS (
        SELECT rsogd.soggetto_id, rsogd.doc_id
        FROM siac_r_doc_sog rsogd
        WHERE rsogd.data_cancellazione IS NULL
        ), gg3 AS (
        SELECT a.subdoc_id,
                                    b.eldoc_anno AS anno_elenco_doc,
                                    b.eldoc_numero AS num_elenco_doc
        FROM siac_r_elenco_doc_subdoc a,
                                    siac_t_elenco_doc b
        WHERE b.eldoc_id = a.eldoc_id AND a.data_cancellazione IS NULL AND
            b.data_cancellazione IS NULL AND a.validita_fine IS NULL
        )
        SELECT gg1.doc_id, gg1.cartac_det_id, gg1.doc_anno,
                            gg1.doc_numero, gg1.doc_tipo_code,
                            gg1.doc_fam_tipo_code, gg1.doc_data_emissione,
                            gg2.soggetto_id, gg1.subdoc_numero,
                            gg3.anno_elenco_doc, gg3.num_elenco_doc
        FROM gg1
                      LEFT JOIN gg2 ON gg1.doc_id = gg2.doc_id
                 LEFT JOIN gg3 ON gg1.subdoc_id = gg3.subdoc_id
        ) tb
    ), hh AS (
    SELECT rurg.testo, rurg.cartac_id
    FROM siac_r_cartacont_attr rurg, siac_t_attr atturg
    WHERE atturg.attr_id = rurg.attr_id AND atturg.attr_code::text =
        'motivo_urgenza'::text AND rurg.data_cancellazione IS NULL AND atturg.data_cancellazione IS NULL
    ), ii AS (
    SELECT rnote.testo, rnote.cartac_id
    FROM siac_r_cartacont_attr rnote, siac_t_attr attrnote
    WHERE attrnote.attr_id = rnote.attr_id AND attrnote.attr_code::text =
        'note'::text AND rnote.data_cancellazione IS NULL AND attrnote.data_cancellazione IS NULL
    ), ll AS (
    SELECT h.attoamm_id, h.attoamm_anno, h.attoamm_numero,
                    daat.attoamm_tipo_code, daat.attoamm_tipo_desc
    FROM siac_t_atto_amm h, siac_d_atto_amm_tipo daat
    WHERE daat.attoamm_tipo_id = h.attoamm_tipo_id AND h.data_cancellazione IS
        NULL AND daat.data_cancellazione IS NULL
    ), mm AS (
    SELECT i.attoamm_id, l.classif_id, l.classif_code,
                    l.classif_desc, m.classif_tipo_code
    FROM siac_r_atto_amm_class i, siac_t_class l,
                    siac_d_class_tipo m, siac_r_class_fam_tree n,
                    siac_t_class_fam_tree o, siac_d_class_fam p
    WHERE i.classif_id = l.classif_id AND m.classif_tipo_id = l.classif_tipo_id
        AND n.classif_id = l.classif_id AND n.classif_fam_tree_id = o.classif_fam_tree_id AND o.classif_fam_id = p.classif_fam_id AND p.classif_fam_code::text = '00005'::text AND i.data_cancellazione IS NULL AND l.data_cancellazione IS NULL AND m.data_cancellazione IS NULL AND n.data_cancellazione IS NULL AND o.data_cancellazione IS NULL AND p.data_cancellazione IS NULL
    )
    SELECT aa.ente_proprietario_id, aa.anno AS anno_bilancio,
            aa.cartac_stato_code, aa.cartac_stato_desc,
            ff.soggetto_id AS crt_det_sogg_id, ff.soggetto_code,
            ff.soggetto_desc, ll.attoamm_anno, ll.attoamm_numero,
            ll.attoamm_tipo_code, ll.attoamm_tipo_desc,
            mm.classif_code AS cod_sac, mm.classif_desc AS desc_sac,
            aa.cartac_numero, aa.cartac_importo, aa.cartac_oggetto,
            aa.cartac_causale AS causale_carta, aa.cartac_data_scadenza,
            aa.cartac_data_pagamento, ii.testo AS note_carta,
            hh.testo AS urgenza,
                CASE
                    WHEN cc.cartacest_id IS NOT NULL THEN true
                    ELSE false
                END AS flagisestera,
            cc.cartacest_causalepagamento AS est_causale,
            aa.cartac_importo_valuta AS est_valuta,
            cc.cartacest_data_valuta AS est_data_valuta,
            cc.cartacest_diversotitolare AS est_titolare_diverso,
            cc.cartacest_istruzioni AS est_istruzioni,
            aa.cartac_det_numero AS crt_det_numero,
            aa.cartac_det_desc AS crt_det_desc,
            aa.cartac_det_importo AS crt_det_importo,
            aa.cartac_det_importo_valuta AS crt_det_valuta,
            bb.contotes_code AS crt_det_contotesoriere,
            dd.modpag_id AS crt_det_mdp_id, ee.movgest_anno, ee.movgest_numero,
                CASE
                    WHEN ee.movgest_ts_id_padre::character varying IS NOT NULL
                        THEN ee.movgest_ts_code
                    ELSE ee.movgest_ts_id_padre::character varying
                END AS subimpegno,
            gg.doc_anno, gg.doc_numero, gg.doc_tipo_code, gg.doc_fam_tipo_code,
            gg.doc_data_emissione, gg.soggetto_id AS soggetto_doc,
            gg.subdoc_numero, gg.anno_elenco_doc, gg.num_elenco_doc,
            gg.doc_id
    FROM aa
      LEFT JOIN bb ON aa.contotes_id = bb.contotes_id
   LEFT JOIN cc ON aa.cartac_id = cc.cartac_id
   LEFT JOIN dd ON aa.cartac_det_id = dd.cartac_det_id
   LEFT JOIN ee ON aa.cartac_det_id = ee.cartac_det_id
   LEFT JOIN ff ON aa.cartac_det_id = ff.cartac_det_id
   LEFT JOIN gg ON aa.cartac_det_id = gg.cartac_det_id
   LEFT JOIN hh ON aa.cartac_id = hh.cartac_id
   LEFT JOIN ii ON aa.cartac_id = ii.cartac_id
   LEFT JOIN ll ON aa.attoamm_id = ll.attoamm_id
   LEFT JOIN mm ON aa.attoamm_id = mm.attoamm_id
    ) tbb
ORDER BY tbb.ente_proprietario_id, tbb.anno_bilancio, tbb.cartac_numero;

CREATE OR REPLACE VIEW siac.siac_v_dwh_pcc (
    ente_proprietario_id,
    importo_quietanza,
    numero_ordinativo,
    data_emissione_ordinativo,
    data_scadenza,
    data_registrazione,
    cod_esito,
    desc_esito,
    data_esito,
    cod_tipo_operazione,
    desc_tipo_operazione,
    cod_ufficio,
    desc_ufficio,
    cod_debito,
    desc_debito,
    cod_causale_pcc,
    desc_causale_pcc,
    validita_inizio,
    validita_fine,
    anno_doc,
    num_doc,
    data_emissione_doc,
    cod_tipo_doc,
    cod_sogg_doc,
    num_subdoc,
    doc_id)
AS
SELECT t_registro_pcc.ente_proprietario_id,
    t_registro_pcc.rpcc_quietanza_importo AS importo_quietanza,
    t_registro_pcc.ordinativo_numero AS numero_ordinativo,
    t_registro_pcc.ordinativo_data_emissione AS data_emissione_ordinativo,
    t_registro_pcc.data_scadenza,
    t_registro_pcc.rpcc_registrazione_data AS data_registrazione,
    t_registro_pcc.rpcc_esito_code AS cod_esito,
    t_registro_pcc.rpcc_esito_desc AS desc_esito,
    t_registro_pcc.rpcc_esito_data AS data_esito,
    d_pcc_oper_tipo.pccop_tipo_code AS cod_tipo_operazione,
    d_pcc_oper_tipo.pccop_tipo_desc AS desc_tipo_operazione,
    d_pcc_codice.pcccod_code AS cod_ufficio,
    d_pcc_codice.pcccod_desc AS desc_ufficio,
    d_pcc_debito_stato.pccdeb_stato_code AS cod_debito,
    d_pcc_debito_stato.pccdeb_stato_desc AS desc_debito,
    d_pcc_causale.pcccau_code AS cod_causale_pcc,
    d_pcc_causale.pcccau_desc AS desc_causale_pcc,
    t_registro_pcc.validita_inizio, t_registro_pcc.validita_fine,
    t_doc.doc_anno AS anno_doc, t_doc.doc_numero AS num_doc,
    t_doc.doc_data_emissione AS data_emissione_doc,
    d_doc_tipo.doc_tipo_code AS cod_tipo_doc,
    t_soggetto.soggetto_code AS cod_sogg_doc,
    t_subdoc.subdoc_numero AS num_subdoc,
    t_doc.doc_id
FROM siac_t_registro_pcc t_registro_pcc
INNER JOIN siac_d_pcc_operazione_tipo d_pcc_oper_tipo ON d_pcc_oper_tipo.pccop_tipo_id = t_registro_pcc.pccop_tipo_id
INNER JOIN siac_t_doc t_doc ON t_doc.doc_id = t_registro_pcc.doc_id
INNER JOIN siac_d_pcc_codice d_pcc_codice ON d_pcc_codice.pcccod_id = t_doc.pcccod_id
INNER JOIN siac_t_subdoc t_subdoc ON t_subdoc.subdoc_id = t_registro_pcc.subdoc_id
INNER JOIN siac_d_doc_tipo d_doc_tipo ON d_doc_tipo.doc_tipo_id = t_doc.doc_tipo_id
LEFT JOIN siac_d_pcc_debito_stato d_pcc_debito_stato ON d_pcc_debito_stato.pccdeb_stato_id = t_registro_pcc.pccdeb_stato_id AND d_pcc_debito_stato.data_cancellazione IS NULL
LEFT JOIN siac_d_pcc_causale d_pcc_causale ON d_pcc_causale.pcccau_id = t_registro_pcc.pcccau_id AND d_pcc_causale.data_cancellazione IS NULL
LEFT JOIN siac_r_doc_sog r_doc_sog ON r_doc_sog.doc_id = t_doc.doc_id AND r_doc_sog.data_cancellazione IS NULL
LEFT JOIN siac_t_soggetto t_soggetto ON t_soggetto.soggetto_id = r_doc_sog.soggetto_id AND t_soggetto.data_cancellazione IS NULL
WHERE d_pcc_oper_tipo.pccop_tipo_code::text = 'CP'::text 
AND t_registro_pcc.data_cancellazione IS NULL 
AND d_pcc_codice.data_cancellazione IS NULL 
AND d_pcc_oper_tipo.data_cancellazione IS NULL 
AND t_doc.data_cancellazione IS NULL 
AND t_subdoc.data_cancellazione IS NULL 
AND d_doc_tipo.data_cancellazione IS NULL;

CREATE OR REPLACE VIEW siac.siac_v_dwh_provvisori_cassa_doc (
    ente_proprietario_id,
    provc_tipo_code,
    provc_tipo_desc,
    provc_anno,
    provc_numero,
    fam_doc,
    tipo_doc,
    anno_doc,
    numero_doc,
    sogg_doc,
    subdoc_numero,
    importo_reg,
    data_emissione_doc,
    doc_id)
AS
SELECT a.ente_proprietario_id, b.provc_tipo_code, b.provc_tipo_desc,
    a.provc_anno, a.provc_numero, i.doc_fam_tipo_code AS fam_doc,
    h.doc_tipo_code AS tipo_doc, e.doc_anno AS anno_doc,
    e.doc_numero AS numero_doc, g.soggetto_code AS sogg_doc, d.subdoc_numero,
    d.subdoc_importo AS importo_reg, e.doc_data_emissione AS data_emissione_doc,
    e.doc_id
FROM siac_t_prov_cassa a, siac_d_prov_cassa_tipo b,
    siac_r_subdoc_prov_cassa c, siac_t_subdoc d, siac_t_doc e, siac_r_doc_sog f,
    siac_t_soggetto g, siac_d_doc_tipo h, siac_d_doc_fam_tipo i
WHERE a.provc_tipo_id = b.provc_tipo_id AND c.provc_id = a.provc_id AND
    d.subdoc_id = c.subdoc_id AND d.doc_id = e.doc_id AND e.doc_id = f.doc_id AND f.soggetto_id = g.soggetto_id AND e.doc_tipo_id = h.doc_tipo_id AND i.doc_fam_tipo_id = h.doc_fam_tipo_id AND a.data_cancellazione IS NULL AND c.data_cancellazione IS NULL AND d.data_cancellazione IS NULL AND e.data_cancellazione IS NULL AND f.data_cancellazione IS NULL
ORDER BY a.ente_proprietario_id;

CREATE OR REPLACE VIEW siac.siac_v_dwh_relazione_doc (
    ente_proprietario_id,
    cod_tipo_relazione,
    desc_tipo_relazione,
    anno_doc_a,
    doc_numero_a,
    desc_doc_a,
    importo_doc_a,
    beneficiario_multiplo_doc_a,
    data_emissione_doc_a,
    data_scadenza_doc_a,
    cod_tipo_doc_a,
    desc_tipo_doc_a,
    cod_famiglia_doc_a,
    desc_famiglia_doc_a,
    cod_stato_doc_a,
    desc_stato_cod_a,
    cod_soggetto_a,
    desc_soggetto_a,
    anno_doc_b,
    doc_numero_b,
    desc_doc_b,
    importo_doc_b,
    beneficiario_multiplo_doc_b,
    data_emissione_doc_b,
    data_scadenza_doc_b,
    cod_tipo_doc_b,
    desc_tipo_doc_b,
    cod_famiglia_doc_b,
    desc_famiglia_doc_b,
    cod_stato_doc_b,
    desc_stato_cod_b,
    cod_soggetto_b,
    desc_soggett_b,
    importo_relazione_doc,
    doc_id_a,
    doc_id_b)
AS
SELECT rd.ente_proprietario_id, drt.relaz_tipo_code AS cod_tipo_relazione,
    drt.relaz_tipo_desc AS desc_tipo_relazione, td1.doc_anno AS anno_doc_a,
    td1.doc_numero AS doc_numero_a, td1.doc_desc AS desc_doc_a,
    td1.doc_importo AS importo_doc_a,
    td1.doc_beneficiariomult AS beneficiario_multiplo_doc_a,
    td1.doc_data_emissione AS data_emissione_doc_a,
    td1.doc_data_scadenza AS data_scadenza_doc_a,
    ddt1.doc_tipo_code AS cod_tipo_doc_a, ddt1.doc_tipo_desc AS desc_tipo_doc_a,
    dft1.doc_fam_tipo_code AS cod_famiglia_doc_a,
    dft1.doc_fam_tipo_desc AS desc_famiglia_doc_a,
    dds1.doc_stato_code AS cod_stato_doc_a,
    dds1.doc_stato_desc AS desc_stato_cod_a,
    ts1.soggetto_code AS cod_soggetto_a, ts1.soggetto_desc AS desc_soggetto_a,
    td2.doc_anno AS anno_doc_b, td2.doc_numero AS doc_numero_b,
    td2.doc_desc AS desc_doc_b, td2.doc_importo AS importo_doc_b,
    td2.doc_beneficiariomult AS beneficiario_multiplo_doc_b,
    td2.doc_data_emissione AS data_emissione_doc_b,
    td2.doc_data_scadenza AS data_scadenza_doc_b,
    ddt2.doc_tipo_code AS cod_tipo_doc_b, ddt2.doc_tipo_desc AS desc_tipo_doc_b,
    dft2.doc_fam_tipo_code AS cod_famiglia_doc_b,
    dft2.doc_fam_tipo_desc AS desc_famiglia_doc_b,
    dds2.doc_stato_code AS cod_stato_doc_b,
    dds2.doc_stato_desc AS desc_stato_cod_b,
    ts2.soggetto_code AS cod_soggetto_b, ts2.soggetto_desc AS desc_soggett_b,
    rd.doc_importo_da_dedurre AS importo_relazione_doc,
    td1.doc_id AS doc_id_a, td2.doc_id AS doc_id_b
FROM siac_r_doc rd
   JOIN siac_t_doc td1 ON td1.doc_id = rd.doc_id_da
   JOIN siac_t_doc td2 ON td2.doc_id = rd.doc_id_a
   JOIN siac_d_relaz_tipo drt ON drt.relaz_tipo_id = rd.relaz_tipo_id
   LEFT JOIN siac_d_doc_tipo ddt1 ON ddt1.doc_tipo_id = td1.doc_tipo_id AND
       ddt1.data_cancellazione IS NULL
   LEFT JOIN siac_d_doc_tipo ddt2 ON ddt2.doc_tipo_id = td2.doc_tipo_id AND
       ddt2.data_cancellazione IS NULL
   LEFT JOIN siac_d_doc_fam_tipo dft1 ON dft1.doc_fam_tipo_id =
       ddt1.doc_fam_tipo_id AND dft1.data_cancellazione IS NULL
   LEFT JOIN siac_d_doc_fam_tipo dft2 ON dft2.doc_fam_tipo_id =
       ddt2.doc_fam_tipo_id AND dft2.data_cancellazione IS NULL
   JOIN siac_r_doc_stato rds1 ON rds1.doc_id = rd.doc_id_da
   JOIN siac_r_doc_stato rds2 ON rds2.doc_id = rd.doc_id_a
   JOIN siac_d_doc_stato dds1 ON dds1.doc_stato_id = rds1.doc_stato_id
   JOIN siac_d_doc_stato dds2 ON dds2.doc_stato_id = rds2.doc_stato_id
   JOIN siac_r_doc_sog srds1 ON srds1.doc_id = rd.doc_id_da
   JOIN siac_r_doc_sog srds2 ON srds2.doc_id = rd.doc_id_a
   JOIN siac_t_soggetto ts1 ON ts1.soggetto_id = srds1.soggetto_id
   JOIN siac_t_soggetto ts2 ON ts2.soggetto_id = srds2.soggetto_id
WHERE rd.data_cancellazione IS NULL AND td1.data_cancellazione IS NULL AND
    td2.data_cancellazione IS NULL AND drt.data_cancellazione IS NULL AND rds1.data_cancellazione IS NULL AND rds2.data_cancellazione IS NULL AND dds1.data_cancellazione IS NULL AND dds2.data_cancellazione IS NULL AND srds1.data_cancellazione IS NULL AND srds2.data_cancellazione IS NULL AND ts1.data_cancellazione IS NULL AND ts2.data_cancellazione IS NULL;

ALTER TABLE siac_dwh_documento_entrata ADD COLUMN doc_id integer;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_documento_entrata (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_doc_id record;
rec_subdoc_id record;
rec_attr record;
rec_classif_id record;
rec_classif_id_attr record;
-- Variabili per campi estratti dal cursore rec_doc_id
v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_anno_doc INTEGER := null;
v_num_doc VARCHAR := null;
v_desc_doc VARCHAR := null;
v_importo_doc NUMERIC := null;
v_beneficiario_multiplo_doc VARCHAR := null;
v_data_emissione_doc TIMESTAMP := null;
v_data_scadenza_doc TIMESTAMP := null;
v_codice_bollo_doc VARCHAR := null;
v_desc_codice_bollo_doc VARCHAR := null;
v_collegato_cec_doc VARCHAR := null;
v_cod_pcc_doc VARCHAR := null;
v_desc_pcc_doc VARCHAR := null;
v_cod_ufficio_doc VARCHAR := null;
v_desc_ufficio_doc VARCHAR := null;
v_cod_stato_doc VARCHAR := null;
v_desc_stato_doc VARCHAR := null;
v_cod_gruppo_doc VARCHAR := null;
v_desc_gruppo_doc VARCHAR := null;
v_cod_famiglia_doc VARCHAR := null;
v_desc_famiglia_doc VARCHAR := null;
v_cod_tipo_doc VARCHAR := null;
v_desc_tipo_doc VARCHAR := null;
v_sogg_id_doc INTEGER := null;
v_cod_sogg_doc VARCHAR := null;
v_tipo_sogg_doc VARCHAR := null;
v_stato_sogg_doc VARCHAR := null;
v_rag_sociale_sogg_doc VARCHAR := null;
v_p_iva_sogg_doc VARCHAR := null;
v_cf_sogg_doc VARCHAR := null;
v_cf_estero_sogg_doc VARCHAR := null;
v_nome_sogg_doc VARCHAR := null;
v_cognome_sogg_doc VARCHAR := null;
--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc VARCHAR := null;
-- Variabili per campi estratti dal cursore rec_subdoc_id
v_num_subdoc INTEGER := null;
v_desc_subdoc VARCHAR := null;
v_importo_subdoc NUMERIC := null;
v_num_reg_iva_subdoc VARCHAR := null;
v_data_scadenza_subdoc TIMESTAMP := null;
v_convalida_manuale_subdoc VARCHAR := null;
v_importo_da_dedurre_subdoc NUMERIC := null;
v_splitreverse_importo_subdoc NUMERIC := null;
v_pagato_cec_subdoc VARCHAR := null;
v_data_pagamento_cec_subdoc TIMESTAMP := null;
v_anno_atto_amministrativo VARCHAR := null;
v_num_atto_amministrativo VARCHAR := null;
v_oggetto_atto_amministrativo VARCHAR := null;
v_note_atto_amministrativo VARCHAR := null;
v_cod_tipo_atto_amministrativo VARCHAR := null;
v_desc_tipo_atto_amministrativo VARCHAR := null;
v_cod_stato_atto_amministrativo VARCHAR := null;
v_desc_stato_atto_amministrativo VARCHAR := null;
v_causale_atto_allegato VARCHAR := null;
v_altri_allegati_atto_allegato VARCHAR := null;
v_dati_sensibili_atto_allegato VARCHAR := null;
v_data_scadenza_atto_allegato TIMESTAMP := null;
v_note_atto_allegato VARCHAR := null;
v_annotazioni_atto_allegato VARCHAR := null;
v_pratica_atto_allegato VARCHAR := null;
v_resp_amm_atto_allegato VARCHAR := null;
v_resp_contabile_atto_allegato VARCHAR := null;
v_anno_titolario_atto_allegato INTEGER := null;
v_num_titolario_atto_allegato VARCHAR := null;
v_vers_invio_firma_atto_allegato INTEGER := null;
v_cod_stato_atto_allegato VARCHAR := null;
v_desc_stato_atto_allegato VARCHAR := null;
v_anno_elenco_doc INTEGER := null;
v_num_elenco_doc INTEGER := null;
v_data_trasmissione_elenco_doc TIMESTAMP := null;
v_tot_quote_entrate_elenco_doc NUMERIC := null;
v_tot_quote_spese_elenco_doc NUMERIC := null;
v_tot_da_pagare_elenco_doc NUMERIC := null;
v_tot_da_incassare_elenco_doc NUMERIC := null;
v_cod_stato_elenco_doc VARCHAR := null;
v_desc_stato_elenco_doc VARCHAR := null;
v_note_tesoriere_subdoc VARCHAR := null;
v_cod_distinta_subdoc VARCHAR := null;
v_desc_distinta_subdoc VARCHAR := null;
v_tipo_commissione_subdoc VARCHAR := null;
v_conto_tesoreria_subdoc VARCHAR := null;
-- Variabili per i soggetti legati all'atto allegato
v_sogg_id_atto_allegato INTEGER := null;
v_cod_sogg_atto_allegato VARCHAR := null;
v_tipo_sogg_atto_allegato VARCHAR := null;
v_stato_sogg_atto_allegato VARCHAR := null;
v_rag_sociale_sogg_atto_allegato VARCHAR := null;
v_p_iva_sogg_atto_allegato VARCHAR := null;
v_cf_sogg_atto_allegato VARCHAR := null;
v_cf_estero_sogg_atto_allegato VARCHAR := null;
v_nome_sogg_atto_allegato VARCHAR := null;
v_cognome_sogg_atto_allegato VARCHAR := null;
-- Variabili per i classificatori
v_cod_cdr_atto_amministrativo VARCHAR := null;
v_desc_cdr_atto_amministrativo VARCHAR := null;
v_cod_cdc_atto_amministrativo VARCHAR := null;
v_desc_cdc_atto_amministrativo VARCHAR := null;
v_cod_tipo_avviso VARCHAR := null;
v_desc_tipo_avviso VARCHAR := null;
-- Variabili per gli attributi
v_rilevante_iva VARCHAR := null;
v_ordinativo_singolo VARCHAR := null;
v_ordinativo_manuale VARCHAR := null;
v_esproprio VARCHAR := null;
v_note VARCHAR := null;
v_avviso VARCHAR := null;
-- Variabili per i soggetti legati al subdoc
v_cod_sogg_subdoc VARCHAR := null;
v_tipo_sogg_subdoc VARCHAR := null;
v_stato_sogg_subdoc VARCHAR := null;
v_rag_sociale_sogg_subdoc VARCHAR := null;
v_p_iva_sogg_subdoc VARCHAR := null;
v_cf_sogg_subdoc VARCHAR := null;
v_cf_estero_sogg_subdoc VARCHAR := null;
v_nome_sogg_subdoc VARCHAR := null;
v_cognome_sogg_subdoc VARCHAR := null;
-- Variabili per gli ordinamenti legati ai documenti
v_bil_anno_ord VARCHAR := null; 
v_anno_ord INTEGER := null;
v_num_ord NUMERIC := null; 
v_num_subord VARCHAR := null; 
-- Variabile per la sede secondaria
v_sede_secondaria_subdoc VARCHAR := null;
-- Variabili per gli accertamenti
v_bil_anno VARCHAR := null;
v_anno_accertamento INTEGER := null;
v_num_accertamento NUMERIC := null;
v_cod_accertamento VARCHAR := null;
v_desc_accertamento VARCHAR := null;
v_cod_subaccertamento VARCHAR := null;
v_desc_subaccertamento VARCHAR := null;
-- Variabili per la modalita' di pagamento
v_quietanziante VARCHAR := null;
v_data_nascita_quietanziante TIMESTAMP := null;
v_luogo_nascita_quietanziante VARCHAR := null;
v_stato_nascita_quietanziante VARCHAR := null;
v_bic VARCHAR := null;
v_contocorrente VARCHAR := null;
v_intestazione_contocorrente VARCHAR := null;
v_iban VARCHAR := null;
v_mod_pag_id INTEGER := null;
v_note_mod_pag VARCHAR := null;
v_data_scadenza_mod_pag TIMESTAMP := null;
v_cod_tipo_accredito VARCHAR := null;
v_desc_tipo_accredito VARCHAR := null;
-- Variabili per i soggetti legati alla modalita' pagamento
v_cod_sogg_mod_pag VARCHAR := null;
v_tipo_sogg_mod_pag VARCHAR := null;
v_stato_sogg_mod_pag VARCHAR := null;
v_rag_sociale_sogg_mod_pag VARCHAR := null;
v_p_iva_sogg_mod_pag VARCHAR := null;
v_cf_sogg_mod_pag VARCHAR := null;
v_cf_estero_sogg_mod_pag VARCHAR := null;
v_nome_sogg_mod_pag VARCHAR := null;
v_cognome_sogg_mod_pag VARCHAR := null;
-- Variabili utili per il caricamento
v_doc_id INTEGER := null;
v_subdoc_id INTEGER := null;
v_attoal_id INTEGER := null;
v_attoamm_id INTEGER := null;
v_soggetto_id INTEGER := null;
v_classif_code VARCHAR := null;
v_classif_desc VARCHAR := null;
v_classif_tipo_code VARCHAR := null;
v_classif_id_part INTEGER := null;
v_classif_id_padre INTEGER := null;
v_classif_tipo_id INTEGER := null;
v_conta_ciclo_classif INTEGER := null;
v_flag_attributo VARCHAR := null;
v_soggetto_id_principale INTEGER := null;
v_movgest_ts_tipo_code VARCHAR := null;
v_movgest_ts_code VARCHAR := null;
v_soggetto_id_modpag_nocess INTEGER := null;
v_soggetto_id_modpag_cess INTEGER := null;
v_soggetto_id_modpag INTEGER := null;
v_soggrelmpag_id INTEGER := null;
v_pcccod_id INTEGER := null;
v_pccuff_id INTEGER := null;
v_attoamm_tipo_id INTEGER := null;
v_comm_tipo_id INTEGER := null;
--nuova sezione coge 26-09-2016
v_registro_repertorio VARCHAR := null;
v_anno_repertorio VARCHAR := null;
v_num_repertorio VARCHAR := null;
v_data_repertorio VARCHAR := null;
v_arrotondamento VARCHAR := null;
v_data_ricezione_portale VARCHAR := null;
rec_doc_attr record;
BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_documento_entrata
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

-- Ciclo per estrarre doc_id (documenti)
FOR rec_doc_id IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       td.doc_anno, td.doc_numero, td.doc_desc, td.doc_importo, td.doc_beneficiariomult,
       td.doc_data_emissione, td.doc_data_scadenza, dc.codbollo_code, dc.codbollo_desc,
       td.doc_collegato_cec,
       dds.doc_stato_code, dds.doc_stato_desc, ddg.doc_gruppo_tipo_code, ddg.doc_gruppo_tipo_desc,
       ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc, ddt.doc_tipo_code, ddt.doc_tipo_desc,
       ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
       ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero, tpf.nome, tpf.cognome,
       td.doc_id, td.pcccod_id, td.pccuff_id, ts.soggetto_id,
       td.doc_contabilizza_genpcc
FROM siac.siac_t_doc td
INNER JOIN siac.siac_t_ente_proprietario tep ON tep.ente_proprietario_id = td.ente_proprietario_id
                                             AND p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
                                             AND tep.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_tipo ddt ON ddt.doc_tipo_id = td.doc_tipo_id
                                    AND p_data BETWEEN ddt.validita_inizio AND COALESCE(ddt.validita_fine, p_data)
                                    AND ddt.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_fam_tipo ddft ON ddft.doc_fam_tipo_id = ddt.doc_fam_tipo_id
                                         AND p_data BETWEEN ddft.validita_inizio AND COALESCE(ddft.validita_fine, p_data)
                                         AND ddft.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_gruppo ddg ON ddg.doc_gruppo_tipo_id = ddt.doc_gruppo_tipo_id
                                     AND p_data BETWEEN ddg.validita_inizio AND COALESCE(ddg.validita_fine, p_data)
                                     AND ddg.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_codicebollo dc ON dc.codbollo_id = td.codbollo_id
LEFT JOIN siac.siac_r_doc_stato rds ON rds.doc_id = td.doc_id
                                    AND p_data BETWEEN rds.validita_inizio AND COALESCE(rds.validita_fine, p_data)
                                    AND rds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_doc_stato dds ON dds.doc_stato_id = rds.doc_stato_id
                                    AND p_data BETWEEN dds.validita_inizio AND COALESCE(dds.validita_fine, p_data)
                                    AND dds.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_doc_sog srds ON srds.doc_id = td.doc_id
                                   AND p_data BETWEEN srds.validita_inizio AND COALESCE(srds.validita_fine, p_data)
                                   AND srds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = srds.soggetto_id
                                  AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
                                  AND ts.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                        AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                        AND rst.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                        AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                        AND dst.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                         AND rss.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                         AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                         AND dss.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                            AND tpg.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                         AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                         AND tpf.data_cancellazione IS NULL
WHERE tep.ente_proprietario_id = p_ente_proprietario_id
AND ddft.doc_fam_tipo_code in ('E','IE')
AND p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
AND td.data_cancellazione IS NULL

LOOP

v_ente_proprietario_id  := null;
v_ente_denominazione  := null;
v_anno_doc  := null;
v_num_doc  := null;
v_desc_doc  := null;
v_importo_doc  := null;
v_beneficiario_multiplo_doc  := null;
v_data_emissione_doc  := null;
v_data_scadenza_doc  := null;
v_codice_bollo_doc  := null;
v_desc_codice_bollo_doc  := null;
v_collegato_cec_doc  := null;
v_cod_pcc_doc  := null;
v_desc_pcc_doc  := null;
v_cod_ufficio_doc  := null;
v_desc_ufficio_doc  := null;
v_cod_stato_doc  := null;
v_desc_stato_doc  := null;
v_cod_gruppo_doc  := null;
v_desc_gruppo_doc  := null;
v_cod_famiglia_doc  := null;
v_desc_famiglia_doc  := null;
v_cod_tipo_doc  := null;
v_desc_tipo_doc  := null;
v_sogg_id_doc  := null;
v_cod_sogg_doc  := null;
v_tipo_sogg_doc  := null;
v_stato_sogg_doc  := null;
v_rag_sociale_sogg_doc  := null;
v_p_iva_sogg_doc  := null;
v_cf_sogg_doc  := null;
v_cf_estero_sogg_doc  := null;
v_nome_sogg_doc  := null;
v_cognome_sogg_doc  := null;
v_bil_anno_ord := null; 
v_anno_ord := null;
v_num_ord := null; 
v_num_subord  := null;


v_doc_id  := null;
v_pcccod_id  := null;
v_pccuff_id  := null;

--nuova sezione coge 26-09-2016
v_doc_contabilizza_genpcc := null;

v_ente_proprietario_id := rec_doc_id.ente_proprietario_id;
v_ente_denominazione := rec_doc_id.ente_denominazione;
v_anno_doc := rec_doc_id.doc_anno;
v_num_doc := rec_doc_id.doc_numero;
v_desc_doc := rec_doc_id.doc_desc;
v_importo_doc := rec_doc_id.doc_importo;
IF rec_doc_id.doc_beneficiariomult = 'FALSE' THEN
   v_beneficiario_multiplo_doc := 'F';
ELSE
   v_beneficiario_multiplo_doc := 'T';
END IF;
v_data_emissione_doc := rec_doc_id.doc_data_emissione;
v_data_scadenza_doc := rec_doc_id.doc_data_scadenza;
v_codice_bollo_doc := rec_doc_id.codbollo_code;
v_desc_codice_bollo_doc := rec_doc_id.codbollo_desc;
v_collegato_cec_doc := rec_doc_id.doc_collegato_cec;
v_cod_stato_doc := rec_doc_id.doc_stato_code;
v_desc_stato_doc := rec_doc_id.doc_stato_desc;
v_cod_gruppo_doc := rec_doc_id.doc_gruppo_tipo_code;
v_desc_gruppo_doc := rec_doc_id.doc_gruppo_tipo_desc;
v_cod_famiglia_doc := rec_doc_id.doc_fam_tipo_code;
v_desc_famiglia_doc := rec_doc_id.doc_fam_tipo_desc;
v_cod_tipo_doc := rec_doc_id.doc_tipo_code;
v_desc_tipo_doc := rec_doc_id.doc_tipo_desc;
v_sogg_id_doc := rec_doc_id.soggetto_id;
v_cod_sogg_doc := rec_doc_id.soggetto_code;
v_tipo_sogg_doc := rec_doc_id.soggetto_tipo_desc;
v_stato_sogg_doc := rec_doc_id.soggetto_stato_desc;
v_rag_sociale_sogg_doc := rec_doc_id.ragione_sociale;
v_p_iva_sogg_doc := rec_doc_id.partita_iva;
v_cf_sogg_doc := rec_doc_id.codice_fiscale;
v_cf_estero_sogg_doc := rec_doc_id.codice_fiscale_estero;
v_nome_sogg_doc := rec_doc_id.nome;
v_cognome_sogg_doc := rec_doc_id.cognome;

v_doc_id  := rec_doc_id.doc_id;
v_pcccod_id := rec_doc_id.pcccod_id;
v_pccuff_id := rec_doc_id.pccuff_id;

--nuova sezione coge 26-09-2016
IF rec_doc_id.doc_contabilizza_genpcc = 'FALSE' THEN
   v_doc_contabilizza_genpcc := 'F';
ELSE
   v_doc_contabilizza_genpcc := 'T';
END IF;

SELECT dpc.pcccod_code, dpc.pcccod_desc
INTO   v_cod_pcc_doc, v_desc_pcc_doc
FROM   siac.siac_d_pcc_codice dpc
WHERE  dpc.pcccod_id = v_pcccod_id
AND p_data BETWEEN dpc.validita_inizio AND COALESCE(dpc.validita_fine, p_data)
AND dpc.data_cancellazione IS NULL;

SELECT dpu.pccuff_code, dpu.pccuff_desc
INTO   v_cod_ufficio_doc, v_desc_ufficio_doc
FROM   siac.siac_d_pcc_ufficio dpu
WHERE  dpu.pccuff_id = v_pccuff_id
AND p_data BETWEEN dpu.validita_inizio AND COALESCE(dpu.validita_fine, p_data)
AND dpu.data_cancellazione IS NULL;

-- Ciclo per estrarre subdoc_id (subdocumenti)
FOR rec_subdoc_id IN
SELECT ts.subdoc_numero, ts.subdoc_desc, ts.subdoc_importo, ts.subdoc_nreg_iva, ts.subdoc_data_scadenza,
       ts.subdoc_convalida_manuale, ts.subdoc_importo_da_dedurre, ts.subdoc_splitreverse_importo,
       ts.subdoc_pagato_cec, ts.subdoc_data_pagamento_cec,
       taa.attoamm_anno, taa.attoamm_numero, taa.attoamm_oggetto, taa.attoamm_note,
       daas.attoamm_stato_code, daas.attoamm_stato_desc,
       staa.attoal_causale, staa.attoal_altriallegati, staa.attoal_dati_sensibili,
       staa.attoal_data_scadenza, staa.attoal_note, staa.attoal_annotazioni, staa.attoal_pratica,
       staa.attoal_responsabile_amm, staa.attoal_responsabile_con, staa.attoal_titolario_anno,
       staa.attoal_titolario_numero, staa.attoal_versione_invio_firma,
       sdaas.attoal_stato_code, sdaas.attoal_stato_desc,
       ted.eldoc_anno, ted.eldoc_numero, ted.eldoc_data_trasmissione, ted.eldoc_tot_quoteentrate,
       ted.eldoc_tot_quotespese, ted.eldoc_tot_dapagare, ted.eldoc_tot_daincassare,
       deds.eldoc_stato_code, deds.eldoc_stato_desc, dnt.notetes_desc, dd.dist_code, dd.dist_desc, dc.contotes_desc,
       ts.subdoc_id, staa.attoal_id, taa.attoamm_id, taa.attoamm_tipo_id, ts.comm_tipo_id
FROM siac.siac_t_subdoc ts
LEFT JOIN siac.siac_r_subdoc_atto_amm rsaa ON rsaa.subdoc_id = ts.subdoc_id
                                           AND p_data BETWEEN rsaa.validita_inizio AND COALESCE(rsaa.validita_fine, p_data)
                                           AND rsaa.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_amm taa ON taa.attoamm_id = rsaa.attoamm_id
                                   AND p_data BETWEEN taa.validita_inizio AND COALESCE(taa.validita_fine, p_data)
                                   AND taa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_amm_stato raas ON raas.attoamm_id = taa.attoamm_id
                                          AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
                                          AND raas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_amm_stato daas ON daas.attoamm_stato_id = raas.attoamm_stato_id
                                          AND p_data BETWEEN daas.validita_inizio AND COALESCE(daas.validita_fine, p_data)
                                          AND daas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_subdoc reds ON reds.subdoc_id = ts.subdoc_id
                                             AND p_data BETWEEN reds.validita_inizio AND COALESCE(reds.validita_fine, p_data)
                                             AND reds.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_elenco_doc ted ON ted.eldoc_id = reds.eldoc_id
                                     AND p_data BETWEEN ted.validita_inizio AND COALESCE(ted.validita_fine, p_data)
                                     AND ted.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_elenco_doc raaed ON raaed.eldoc_id = ted.eldoc_id
                                                     AND p_data BETWEEN raaed.validita_inizio AND COALESCE(raaed.validita_fine, p_data)
                                                     AND raaed.data_cancellazione IS NULL
LEFT JOIN siac.siac_t_atto_allegato staa ON staa.attoal_id = raaed.attoal_id
                                         AND p_data BETWEEN staa.validita_inizio AND COALESCE(staa.validita_fine, p_data)
                                         AND staa.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_atto_allegato_stato sraas ON sraas.attoal_id = staa.attoal_id
                                                AND p_data BETWEEN sraas.validita_inizio AND COALESCE(sraas.validita_fine, p_data)
                                                AND sraas.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_atto_allegato_stato sdaas ON sdaas.attoal_stato_id = sraas.attoal_stato_id
                                                AND p_data BETWEEN sdaas.validita_inizio AND COALESCE(sdaas.validita_fine, p_data)
                                                AND sdaas.data_cancellazione IS NULL
LEFT JOIN siac.siac_r_elenco_doc_stato  sreds ON sreds.eldoc_id = ted.eldoc_id
                                              AND p_data BETWEEN sreds.validita_inizio AND COALESCE(sreds.validita_fine, p_data)
                                              AND sreds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_elenco_doc_stato  deds ON deds.eldoc_stato_id = sreds.eldoc_stato_id
                                             AND p_data BETWEEN deds.validita_inizio AND COALESCE(deds.validita_fine, p_data)
                                             AND deds.data_cancellazione IS NULL
LEFT JOIN siac.siac_d_note_tesoriere  dnt ON dnt.notetes_id = ts.notetes_id
LEFT JOIN siac.siac_d_distinta  dd ON dd.dist_id = ts.dist_id
LEFT JOIN siac.siac_d_contotesoreria dc ON dc.contotes_id = ts.contotes_id
WHERE ts.doc_id = v_doc_id
AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
AND ts.data_cancellazione IS NULL

	LOOP

    v_num_subdoc  := null;
    v_desc_subdoc  := null;
    v_importo_subdoc  := null;
    v_num_reg_iva_subdoc  := null;
    v_data_scadenza_subdoc  := null;
    v_convalida_manuale_subdoc  := null;
    v_importo_da_dedurre_subdoc  := null;
    v_splitreverse_importo_subdoc  := null;
    v_pagato_cec_subdoc  := null;
    v_data_pagamento_cec_subdoc  := null;
    v_anno_atto_amministrativo  := null;
    v_num_atto_amministrativo  := null;
    v_oggetto_atto_amministrativo  := null;
    v_note_atto_amministrativo  := null;
    v_cod_tipo_atto_amministrativo  := null;
    v_desc_tipo_atto_amministrativo  := null;
    v_cod_stato_atto_amministrativo  := null;
    v_desc_stato_atto_amministrativo  := null;
    v_causale_atto_allegato  := null;
    v_altri_allegati_atto_allegato  := null;
    v_dati_sensibili_atto_allegato  := null;
    v_data_scadenza_atto_allegato  := null;
    v_note_atto_allegato  := null;
    v_annotazioni_atto_allegato  := null;
    v_pratica_atto_allegato  := null;
    v_resp_amm_atto_allegato  := null;
    v_resp_contabile_atto_allegato  := null;
    v_anno_titolario_atto_allegato  := null;
    v_num_titolario_atto_allegato  := null;
    v_vers_invio_firma_atto_allegato  := null;
    v_cod_stato_atto_allegato  := null;
    v_desc_stato_atto_allegato  := null;
    v_anno_elenco_doc  := null;
    v_num_elenco_doc  := null;
    v_data_trasmissione_elenco_doc  := null;
    v_tot_quote_entrate_elenco_doc  := null;
    v_tot_quote_spese_elenco_doc  := null;
    v_tot_da_pagare_elenco_doc  := null;
    v_tot_da_incassare_elenco_doc  := null;
    v_cod_stato_elenco_doc  := null;
    v_desc_stato_elenco_doc  := null;
    v_note_tesoriere_subdoc  := null;
    v_cod_distinta_subdoc  := null;
    v_desc_distinta_subdoc  := null;
    v_tipo_commissione_subdoc  := null;
    v_conto_tesoreria_subdoc  := null;

    v_sogg_id_atto_allegato  := null;
    v_cod_sogg_atto_allegato  := null;
    v_tipo_sogg_atto_allegato  := null;
    v_stato_sogg_atto_allegato  := null;
    v_rag_sociale_sogg_atto_allegato  := null;
    v_p_iva_sogg_atto_allegato  := null;
    v_cf_sogg_atto_allegato  := null;
    v_cf_estero_sogg_atto_allegato  := null;
    v_nome_sogg_atto_allegato  := null;
    v_cognome_sogg_atto_allegato  := null;

    v_cod_cdr_atto_amministrativo  := null;
    v_desc_cdr_atto_amministrativo  := null;
    v_cod_cdc_atto_amministrativo  := null;
    v_desc_cdc_atto_amministrativo  := null;
    v_cod_tipo_avviso  := null;
    v_desc_tipo_avviso  := null;

    v_cod_sogg_subdoc  := null;
    v_tipo_sogg_subdoc  := null;
    v_stato_sogg_subdoc  := null;
    v_rag_sociale_sogg_subdoc  := null;
    v_p_iva_sogg_subdoc  := null;
    v_cf_sogg_subdoc  := null;
    v_cf_estero_sogg_subdoc  := null;
    v_nome_sogg_subdoc  := null;
    v_cognome_sogg_subdoc  := null;

    v_sede_secondaria_subdoc := null;

    v_bil_anno := null;
    v_anno_accertamento := null;
    v_num_accertamento := null;
    v_cod_accertamento  := null;
    v_desc_accertamento  := null;
    v_cod_subaccertamento  := null;
    v_desc_subaccertamento  := null;

    v_quietanziante := null;
    v_data_nascita_quietanziante := null;
    v_luogo_nascita_quietanziante := null;
    v_stato_nascita_quietanziante := null;
    v_bic := null;
    v_contocorrente := null;
    v_intestazione_contocorrente := null;
    v_iban := null;
    v_mod_pag_id := null;
    v_note_mod_pag := null;
    v_data_scadenza_mod_pag := null;
    v_cod_tipo_accredito := null;
    v_desc_tipo_accredito := null;

    v_cod_sogg_mod_pag := null;
    v_tipo_sogg_mod_pag := null;
    v_stato_sogg_mod_pag := null;
    v_rag_sociale_sogg_mod_pag := null;
    v_p_iva_sogg_mod_pag := null;
    v_cf_sogg_mod_pag := null;
    v_cf_estero_sogg_mod_pag := null;
    v_nome_sogg_mod_pag := null;
    v_cognome_sogg_mod_pag := null;

    v_attoal_id  := null;
    v_subdoc_id  := null;
    v_attoamm_id  := null;
    v_classif_tipo_id := null;
    v_soggetto_id := null;
    v_soggetto_id_principale := null;
    v_movgest_ts_tipo_code := null;
    v_movgest_ts_code := null;
    v_soggetto_id_modpag_nocess := null;
    v_soggetto_id_modpag_cess := null;
    v_soggetto_id_modpag := null;
    v_soggrelmpag_id := null;
    v_attoamm_tipo_id := null;
    v_comm_tipo_id := null;

    v_num_subdoc  := rec_subdoc_id.subdoc_numero;
    v_desc_subdoc  := rec_subdoc_id.subdoc_desc;
    v_importo_subdoc  := rec_subdoc_id.subdoc_importo;
    v_num_reg_iva_subdoc  := rec_subdoc_id.subdoc_nreg_iva;
    v_data_scadenza_subdoc  := rec_subdoc_id.subdoc_data_scadenza;
    v_convalida_manuale_subdoc  := rec_subdoc_id.subdoc_convalida_manuale;
    v_importo_da_dedurre_subdoc  := rec_subdoc_id.subdoc_importo_da_dedurre;
    v_splitreverse_importo_subdoc  := rec_subdoc_id.subdoc_splitreverse_importo;
    v_pagato_cec_subdoc  := rec_subdoc_id.subdoc_pagato_cec;
    v_data_pagamento_cec_subdoc  := rec_subdoc_id.subdoc_data_pagamento_cec;
    v_anno_atto_amministrativo  := rec_subdoc_id.attoamm_anno;
    v_num_atto_amministrativo  := rec_subdoc_id.attoamm_numero;
    v_oggetto_atto_amministrativo  := rec_subdoc_id.attoamm_oggetto;
    v_note_atto_amministrativo  := rec_subdoc_id.attoamm_note;
    v_cod_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_code;
    v_desc_stato_atto_amministrativo  := rec_subdoc_id.attoamm_stato_desc;
    v_causale_atto_allegato  := rec_subdoc_id.attoal_causale;
    v_altri_allegati_atto_allegato  := rec_subdoc_id.attoal_altriallegati;
    v_dati_sensibili_atto_allegato  := rec_subdoc_id.attoal_dati_sensibili;
    v_data_scadenza_atto_allegato  := rec_subdoc_id.attoal_data_scadenza;
    v_note_atto_allegato  := rec_subdoc_id.attoal_note;
    v_annotazioni_atto_allegato  := rec_subdoc_id.attoal_annotazioni;
    v_pratica_atto_allegato  := rec_subdoc_id.attoal_pratica;
    v_resp_amm_atto_allegato  := rec_subdoc_id.attoal_responsabile_amm;
    v_resp_contabile_atto_allegato  := rec_subdoc_id.attoal_responsabile_con;
    v_anno_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_anno;
    v_num_titolario_atto_allegato  := rec_subdoc_id.attoal_titolario_numero;
    v_vers_invio_firma_atto_allegato  := rec_subdoc_id.attoal_versione_invio_firma;
    v_cod_stato_atto_allegato  := rec_subdoc_id.attoal_stato_code;
    v_desc_stato_atto_allegato  := rec_subdoc_id.attoal_stato_desc;
    v_anno_elenco_doc  := rec_subdoc_id.eldoc_anno;
    v_num_elenco_doc  := rec_subdoc_id.eldoc_numero;
    v_data_trasmissione_elenco_doc  := rec_subdoc_id.eldoc_data_trasmissione;
    v_tot_quote_entrate_elenco_doc  := rec_subdoc_id.eldoc_tot_quoteentrate;
    v_tot_quote_spese_elenco_doc  := rec_subdoc_id.eldoc_tot_quotespese;
    v_tot_da_pagare_elenco_doc  := rec_subdoc_id.eldoc_tot_dapagare;
    v_tot_da_incassare_elenco_doc  := rec_subdoc_id.eldoc_tot_daincassare;
    v_cod_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_code;
    v_desc_stato_elenco_doc  := rec_subdoc_id.eldoc_stato_desc;
    v_note_tesoriere_subdoc  := rec_subdoc_id.notetes_desc;
    v_cod_distinta_subdoc  := rec_subdoc_id.dist_code;
    v_desc_distinta_subdoc  := rec_subdoc_id.dist_desc;
    v_conto_tesoreria_subdoc  := rec_subdoc_id.contotes_desc;

    v_attoal_id  := rec_subdoc_id.attoal_id;
    v_subdoc_id  := rec_subdoc_id.subdoc_id;
    v_attoamm_id  := rec_subdoc_id.attoamm_id;
    v_attoamm_tipo_id  := rec_subdoc_id.attoamm_tipo_id;
    v_comm_tipo_id  := rec_subdoc_id.comm_tipo_id;
    -- Sezione per estrarre il tipo di atto amministrativo
    SELECT daat.attoamm_tipo_code, daat.attoamm_tipo_desc
    INTO   v_cod_tipo_atto_amministrativo, v_desc_tipo_atto_amministrativo
    FROM  siac.siac_d_atto_amm_tipo daat
    WHERE daat.attoamm_tipo_id = v_attoamm_tipo_id
    AND p_data BETWEEN daat.validita_inizio AND COALESCE(daat.validita_fine, p_data)
    AND daat.data_cancellazione IS NULL;
    -- Sezione per estrarre il tipo commissione
    SELECT dct.comm_tipo_desc
    INTO  v_tipo_commissione_subdoc
    FROM siac.siac_d_commissione_tipo dct
    WHERE dct.comm_tipo_id = v_comm_tipo_id
    AND p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data)
    AND dct.data_cancellazione IS NULL;

    --  Sezione per i soggetti legati all'atto allegato
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, ts.soggetto_id
    INTO   v_cod_sogg_atto_allegato, v_tipo_sogg_atto_allegato, v_stato_sogg_atto_allegato, v_rag_sociale_sogg_atto_allegato,
           v_p_iva_sogg_atto_allegato, v_cf_sogg_atto_allegato, v_cf_estero_sogg_atto_allegato,
           v_nome_sogg_atto_allegato, v_cognome_sogg_atto_allegato, v_sogg_id_atto_allegato
    FROM siac.siac_r_atto_allegato_sog raas
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = raas.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato rss ON rss.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
                                             AND rss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = rss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE raas.attoal_id = v_attoal_id
    AND p_data BETWEEN raas.validita_inizio AND COALESCE(raas.validita_fine, p_data)
    AND raas.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    -- Sezione per i classificatori legati ai subdocumenti
    esito:= '    Inizio step classificatori per subdocumenti - '||clock_timestamp();
    return next;
    FOR rec_classif_id IN
    SELECT tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_subdoc_class rsc, siac.siac_t_class tc
    WHERE tc.classif_id = rsc.classif_id
    AND   rsc.subdoc_id = v_subdoc_id
    AND   rsc.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN rsc.validita_inizio AND COALESCE(rsc.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_classif_tipo_id :=  rec_classif_id.classif_tipo_id;
      v_classif_code := rec_classif_id.classif_code;
      v_classif_desc := rec_classif_id.classif_desc;

      v_classif_tipo_code := null;

      SELECT dct.classif_tipo_code
      INTO   v_classif_tipo_code
      FROM   siac.siac_d_class_tipo dct
      WHERE  dct.classif_tipo_id = v_classif_tipo_id
      AND    dct.data_cancellazione IS NULL
      AND    p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

      IF v_classif_tipo_code = 'TIPO_AVVISO' THEN
         v_cod_tipo_avviso  := v_classif_code;
         v_desc_tipo_avviso :=  v_classif_desc;
      END IF;

    END LOOP;
    esito:= '    Fine step classificatori per subdocumenti - '||clock_timestamp();
    return next;

    -- Sezione per i classificatori legati agli atti amministrativi
    esito:= '    Inizio step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;
    FOR rec_classif_id_attr IN
    SELECT tc.classif_id, tc.classif_tipo_id, tc.classif_code, tc.classif_desc
    FROM siac.siac_r_atto_amm_class raac, siac.siac_t_class tc
    WHERE tc.classif_id = raac.classif_id
    AND   raac.attoamm_id = v_attoamm_id
    AND   raac.data_cancellazione IS NULL
    AND   tc.data_cancellazione IS NULL
    AND   p_data BETWEEN raac.validita_inizio AND COALESCE(raac.validita_fine, p_data)
    AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)

    LOOP

      v_conta_ciclo_classif :=0;
      v_classif_id_padre := null;

      -- Loop per RISALIRE la gerarchia di un dato classificatore
      LOOP

          v_classif_code := null;
          v_classif_desc := null;
          v_classif_id_part := null;
          v_classif_tipo_code := null;

          IF v_conta_ciclo_classif = 0 THEN
             v_classif_id_part := rec_classif_id_attr.classif_id;
          ELSE
             v_classif_id_part := v_classif_id_padre;
          END IF;

          SELECT tc.classif_code, tc.classif_desc, rcft.classif_id_padre, dct.classif_tipo_code
          INTO   v_classif_code, v_classif_desc, v_classif_id_padre, v_classif_tipo_code
          FROM  siac.siac_r_class_fam_tree rcft, siac.siac_t_class tc, siac.siac_d_class_tipo dct
          WHERE rcft.classif_id = tc.classif_id
          AND   dct.classif_tipo_id = tc.classif_tipo_id
          AND   tc.classif_id = v_classif_id_part
          AND   rcft.data_cancellazione IS NULL
          AND   tc.data_cancellazione IS NULL
          AND   dct.data_cancellazione IS NULL
          AND   p_data BETWEEN rcft.validita_inizio AND COALESCE(rcft.validita_fine, p_data)
          AND   p_data BETWEEN tc.validita_inizio AND COALESCE(tc.validita_fine, p_data)
          AND   p_data BETWEEN dct.validita_inizio AND COALESCE(dct.validita_fine, p_data);

          IF v_classif_tipo_code = 'CDR' THEN
             v_cod_cdr_atto_amministrativo := v_classif_code;
             v_desc_cdr_atto_amministrativo := v_classif_desc;
          ELSIF v_classif_tipo_code = 'CDC' THEN
             v_cod_cdc_atto_amministrativo := v_classif_code;
             v_desc_cdc_atto_amministrativo := v_classif_desc;
          END IF;

          v_conta_ciclo_classif := v_conta_ciclo_classif +1;
          EXIT WHEN v_classif_id_padre IS NULL;

      END LOOP;
    END LOOP;
    esito:= '    Fine step classificatori in gerarchia per atti amministrativi - '||clock_timestamp();
    return next;

    -- Sezione pe gli attributi
    v_rilevante_iva := null;
    v_ordinativo_singolo := null;
    v_ordinativo_manuale := null;
    v_esproprio := null;
    v_note := null;
    v_avviso := null;

    v_flag_attributo := null;
    
--nuova sezione coge 26-09-2016
    v_registro_repertorio := null;
    v_anno_repertorio := null;
    v_num_repertorio := null;
    v_data_repertorio := null;

FOR rec_doc_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_doc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat, siac_t_subdoc z
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    dat.data_cancellazione IS NULL
    and z.doc_id=rsa.doc_id
    and z.subdoc_id = v_subdoc_id
    AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
    AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
    AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
    and ta.attr_code in ( 'registro_repertorio','anno_repertorio','num_repertorio',
    'data_repertorio' ,'dataRicezionePortale','arrotondamento')

LOOP

      IF rec_doc_attr.attr_tipo_code = 'X' THEN
         v_flag_attributo := rec_doc_attr.testo::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'N' THEN
         v_flag_attributo := rec_doc_attr.numerico::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'P' THEN
         v_flag_attributo := rec_doc_attr.percentuale::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'B' THEN
         v_flag_attributo := rec_doc_attr.true_false::varchar;
      ELSIF rec_doc_attr.attr_tipo_code = 'T' THEN
         v_flag_attributo := rec_doc_attr.tabella_id::varchar;
      END IF;

      --nuova sezione coge 26-09-2016  
      IF rec_doc_attr.attr_code = 'registro_repertorio' THEN
         v_registro_repertorio := v_flag_attributo;
      ELSIF rec_doc_attr.attr_code = 'anno_repertorio' THEN
         v_anno_repertorio := v_flag_attributo;
	  ELSIF rec_doc_attr.attr_code = 'num_repertorio' THEN
         v_num_repertorio := v_flag_attributo;         
	  ELSIF rec_doc_attr.attr_code = 'data_repertorio' THEN
         v_data_repertorio := v_flag_attributo;         
      ELSIF rec_doc_attr.attr_code = 'dataRicezionePortale' THEN
         v_data_ricezione_portale := v_flag_attributo;   
      ELSIF rec_doc_attr.attr_code = 'arrotondamento' THEN
         v_arrotondamento := v_flag_attributo;   
      END IF;

    END LOOP;
    

    FOR rec_attr IN
    SELECT ta.attr_code, dat.attr_tipo_code,
           rsa.tabella_id, rsa.percentuale, rsa."boolean" true_false, rsa.numerico, rsa.testo
    FROM   siac.siac_r_subdoc_attr rsa, siac.siac_t_attr ta, siac.siac_d_attr_tipo dat
    WHERE  rsa.attr_id = ta.attr_id
    AND    ta.attr_tipo_id = dat.attr_tipo_id
    AND    rsa.subdoc_id = v_subdoc_id
    AND    rsa.data_cancellazione IS NULL
    AND    ta.data_cancellazione IS NULL
    AND    dat.data_cancellazione IS NULL
    AND    p_data BETWEEN rsa.validita_inizio AND COALESCE(rsa.validita_fine, p_data)
    AND    p_data BETWEEN ta.validita_inizio AND COALESCE(ta.validita_fine, p_data)
    AND    p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)

    LOOP

      IF rec_attr.attr_tipo_code = 'X' THEN
         v_flag_attributo := rec_attr.testo::varchar;
      ELSIF rec_attr.attr_tipo_code = 'N' THEN
         v_flag_attributo := rec_attr.numerico::varchar;
      ELSIF rec_attr.attr_tipo_code = 'P' THEN
         v_flag_attributo := rec_attr.percentuale::varchar;
      ELSIF rec_attr.attr_tipo_code = 'B' THEN
         v_flag_attributo := rec_attr.true_false::varchar;
      ELSIF rec_attr.attr_tipo_code = 'T' THEN
         v_flag_attributo := rec_attr.tabella_id::varchar;
      END IF;

      IF rec_attr.attr_code = 'flagRilevanteIVA' THEN
         v_rilevante_iva := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoManuale' THEN
         v_ordinativo_manuale := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagOrdinativoSingolo' THEN
         v_ordinativo_singolo := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagEsproprio' THEN
         v_esproprio := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'Note' THEN
         v_note := v_flag_attributo;
      ELSIF rec_attr.attr_code = 'flagAvviso' THEN
         v_avviso := v_flag_attributo;
      END IF;

    END LOOP;

    --  Sezione per i soggetti legati al subdoc
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome, rss.soggetto_id
    INTO v_cod_sogg_subdoc, v_tipo_sogg_subdoc, v_stato_sogg_subdoc, v_rag_sociale_sogg_subdoc,
         v_p_iva_sogg_subdoc, v_cf_sogg_subdoc, v_cf_estero_sogg_subdoc,
         v_nome_sogg_subdoc, v_cognome_sogg_subdoc, v_soggetto_id
    FROM siac.siac_r_subdoc_sog rss
    INNER JOIN siac.siac_t_soggetto ts ON ts.soggetto_id = rss.soggetto_id
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE rss.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rss.validita_inizio AND COALESCE(rss.validita_fine, p_data)
    AND rss.data_cancellazione IS NULL
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    -- Sezione per valorizzare la sede secondaria
    SELECT rsr.soggetto_id_da
    INTO v_soggetto_id_principale
    FROM siac.siac_r_soggetto_relaz rsr, siac.siac_d_relaz_tipo drt
    WHERE rsr.relaz_tipo_id = drt.relaz_tipo_id
    AND   drt.relaz_tipo_code  = 'SEDE_SECONDARIA'
    AND   rsr.soggetto_id_a = v_soggetto_id
    AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
    AND   p_data BETWEEN drt.validita_inizio AND COALESCE(drt.validita_fine, p_data)
    AND   rsr.data_cancellazione IS NULL
    AND   drt.data_cancellazione IS NULL;

    IF  v_soggetto_id_principale IS NOT NULL THEN
        v_sede_secondaria_subdoc := 'S';
    END IF;

    -- Sezione per gli accertamenti
    SELECT tp.anno, tm.movgest_anno, tm.movgest_numero, dmtt.movgest_ts_tipo_code,
           tmt.movgest_ts_code, tmt.movgest_ts_desc, tm.movgest_desc
    INTO v_bil_anno, v_anno_accertamento, v_num_accertamento, v_movgest_ts_tipo_code,
         v_movgest_ts_code, v_desc_subaccertamento, v_desc_accertamento
    FROM siac.siac_r_subdoc_movgest_ts rsmt
    INNER JOIN siac.siac_t_movgest_ts tmt ON tmt.movgest_ts_id = rsmt.movgest_ts_id
    INNER JOIN siac.siac_t_movgest tm ON tm.movgest_id = tmt.movgest_id
    LEFT JOIN siac.siac_t_bil tb ON tb.bil_id = tm.bil_id
                                 AND p_data BETWEEN tb.validita_inizio AND COALESCE(tb.validita_fine, p_data)
                                 AND tb.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_periodo tp ON  tp.periodo_id = tb.periodo_id
                                     AND p_data BETWEEN tp.validita_inizio AND COALESCE(tp.validita_fine, p_data)
                                     AND tp.data_cancellazione IS NULL
    INNER JOIN siac.siac_d_movgest_tipo dmt ON dmt.movgest_tipo_id = tm.movgest_tipo_id
    INNER JOIN siac.siac_d_movgest_ts_tipo dmtt ON dmtt.movgest_ts_tipo_id = tmt.movgest_ts_tipo_id
    WHERE rsmt.subdoc_id = v_subdoc_id
    AND dmt.movgest_tipo_code = 'A'
    AND p_data BETWEEN rsmt.validita_inizio AND COALESCE(rsmt.validita_fine, p_data)
    AND rsmt.data_cancellazione IS NULL
    AND p_data BETWEEN tmt.validita_inizio AND COALESCE(tmt.validita_fine, p_data)
    AND tmt.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL
    AND p_data BETWEEN dmt.validita_inizio AND COALESCE(dmt.validita_fine, p_data)
    AND dmt.data_cancellazione IS NULL
    AND p_data BETWEEN dmtt.validita_inizio AND COALESCE(dmtt.validita_fine, p_data)
    AND dmtt.data_cancellazione IS NULL;

    IF v_movgest_ts_tipo_code = 'T' THEN
       v_cod_accertamento := v_movgest_ts_code;
       v_desc_subaccertamento := NULL;
    ELSIF v_movgest_ts_tipo_code = 'S' THEN
          v_cod_subaccertamento := v_movgest_ts_code;
          v_desc_accertamento := NULL;
    END IF;

    -- Sezione per la modalita' di pagamento
    SELECT tm.quietanziante, tm.quietanzante_nascita_data, tm.quietanziante_nascita_luogo, tm.quietanziante_nascita_stato,
           tm.bic, tm.contocorrente, tm.contocorrente_intestazione, tm.iban, tm.note, tm.data_scadenza,
           dat.accredito_tipo_code, dat.accredito_tipo_desc, tm.soggetto_id, rsm.soggrelmpag_id, tm.modpag_id
    INTO   v_quietanziante, v_data_nascita_quietanziante, v_luogo_nascita_quietanziante, v_stato_nascita_quietanziante,
           v_bic, v_contocorrente, v_intestazione_contocorrente, v_iban, v_note_mod_pag, v_data_scadenza_mod_pag,
           v_cod_tipo_accredito, v_desc_tipo_accredito, v_soggetto_id_modpag_nocess, v_soggrelmpag_id, v_mod_pag_id
    FROM siac.siac_r_subdoc_modpag rsm
    INNER JOIN siac.siac_t_modpag tm ON tm.modpag_id = rsm.modpag_id
    LEFT JOIN siac.siac_d_accredito_tipo dat ON dat.accredito_tipo_id = tm.accredito_tipo_id
                                             AND p_data BETWEEN dat.validita_inizio AND COALESCE(dat.validita_fine, p_data)
                                             AND dat.data_cancellazione IS NULL
    WHERE rsm.subdoc_id = v_subdoc_id
    AND p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
    AND rsm.data_cancellazione IS NULL
    AND p_data BETWEEN tm.validita_inizio AND COALESCE(tm.validita_fine, p_data)
    AND tm.data_cancellazione IS NULL;

    IF v_soggrelmpag_id IS NULL THEN
       v_soggetto_id_modpag := v_soggetto_id_modpag_nocess;
    ELSE
       SELECT rsr.soggetto_id_a
       INTO  v_soggetto_id_modpag_cess
       FROM  siac.siac_r_soggrel_modpag rsm, siac.siac_r_soggetto_relaz rsr
       WHERE rsm.soggrelmpag_id = v_soggrelmpag_id
       AND   rsm.soggetto_relaz_id = rsr.soggetto_relaz_id
       AND   p_data BETWEEN rsm.validita_inizio AND COALESCE(rsm.validita_fine, p_data)
       AND   rsm.data_cancellazione IS NULL
       AND   p_data BETWEEN rsr.validita_inizio AND COALESCE(rsr.validita_fine, p_data)
       AND   rsr.data_cancellazione IS NULL;

       v_soggetto_id_modpag := v_soggetto_id_modpag_cess;
    END IF;

    --  Sezione per i soggetti legati alla modalita' pagamento
    SELECT ts.soggetto_code, dst.soggetto_tipo_desc, dss.soggetto_stato_desc, tpg.ragione_sociale,
           ts.partita_iva, ts.codice_fiscale, ts.codice_fiscale_estero,
           tpf.nome, tpf.cognome
    INTO   v_cod_sogg_mod_pag, v_tipo_sogg_mod_pag, v_stato_sogg_mod_pag, v_rag_sociale_sogg_mod_pag,
           v_p_iva_sogg_mod_pag, v_cf_sogg_mod_pag, v_cf_estero_sogg_mod_pag,
           v_nome_sogg_mod_pag, v_cognome_sogg_mod_pag
    FROM siac.siac_t_soggetto ts
    LEFT JOIN siac.siac_r_soggetto_tipo rst ON rst.soggetto_id = ts.soggetto_id
                                            AND p_data BETWEEN rst.validita_inizio AND COALESCE(rst.validita_fine, p_data)
                                            AND rst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_tipo dst ON dst.soggetto_tipo_id = rst.soggetto_tipo_id
                                            AND p_data BETWEEN dst.validita_inizio AND COALESCE(dst.validita_fine, p_data)
                                            AND dst.data_cancellazione IS NULL
    LEFT JOIN siac.siac_r_soggetto_stato srss ON srss.soggetto_id = ts.soggetto_id
                                              AND p_data BETWEEN srss.validita_inizio AND COALESCE(srss.validita_fine, p_data)
                                              AND srss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_d_soggetto_stato dss ON dss.soggetto_stato_id = srss.soggetto_stato_id
                                             AND p_data BETWEEN dss.validita_inizio AND COALESCE(dss.validita_fine, p_data)
                                             AND dss.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_giuridica tpg ON tpg.soggetto_id = ts.soggetto_id
                                                AND p_data BETWEEN tpg.validita_inizio AND COALESCE(tpg.validita_fine, p_data)
                                                AND tpg.data_cancellazione IS NULL
    LEFT JOIN siac.siac_t_persona_fisica tpf ON tpf.soggetto_id = ts.soggetto_id
                                             AND p_data BETWEEN tpf.validita_inizio AND COALESCE(tpf.validita_fine, p_data)
                                             AND tpf.data_cancellazione IS NULL
    WHERE ts.soggetto_id = v_soggetto_id_modpag
    AND p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
    AND ts.data_cancellazione IS NULL;

    SELECT sto.ord_anno, sto.ord_numero, tt.ord_ts_code, tp.anno
    INTO  v_anno_ord, v_num_ord, v_num_subord, v_bil_anno_ord
    FROM  siac_r_subdoc_ordinativo_ts rsot, siac_t_ordinativo_ts tt, siac_t_ordinativo sto,
          siac_r_ordinativo_stato ros, siac_d_ordinativo_stato dos,
          siac.siac_t_bil tb, siac.siac_t_periodo tp 
    WHERE tt.ord_ts_id = rsot.ord_ts_id
    AND   sto.ord_id = tt.ord_id
    AND   ros.ord_id = sto.ord_id
    AND   ros.ord_stato_id = dos.ord_stato_id
    AND   sto.bil_id = tb.bil_id 
    AND   tp.periodo_id = tb.periodo_id 
    AND   rsot.subdoc_id = v_subdoc_id
    AND   dos.ord_stato_code <> 'A'
    AND   rsot.data_cancellazione IS NULL
    AND   tt.data_cancellazione IS NULL
    AND   sto.data_cancellazione IS NULL
    AND   ros.data_cancellazione IS NULL
    AND   dos.data_cancellazione IS NULL
    AND   tb.data_cancellazione IS NULL
    AND   tp.data_cancellazione IS NULL
    AND   p_data between rsot.validita_inizio and COALESCE(rsot.validita_fine,p_data)
    AND   p_data between tt.validita_inizio and COALESCE(tt.validita_fine,p_data)
    AND   p_data between sto.validita_inizio and COALESCE(sto.validita_fine,p_data)
    AND   p_data between ros.validita_inizio and COALESCE(ros.validita_fine,p_data)
    AND   p_data between dos.validita_inizio and COALESCE(dos.validita_fine,p_data)
    AND   p_data between tb.validita_inizio and COALESCE(tb.validita_fine,p_data)
    AND   p_data between tp.validita_inizio and COALESCE(tp.validita_fine,p_data);

      INSERT INTO siac.siac_dwh_documento_entrata
      ( ente_proprietario_id,
        ente_denominazione,
        anno_atto_amministrativo,
        num_atto_amministrativo,
        oggetto_atto_amministrativo,
        cod_tipo_atto_amministrativo,
        desc_tipo_atto_amministrativo,
        cod_cdr_atto_amministrativo,
        desc_cdr_atto_amministrativo,
        cod_cdc_atto_amministrativo,
        desc_cdc_atto_amministrativo,
        note_atto_amministrativo,
        cod_stato_atto_amministrativo,
        desc_stato_atto_amministrativo,
        causale_atto_allegato,
        altri_allegati_atto_allegato,
        dati_sensibili_atto_allegato,
        data_scadenza_atto_allegato,
        note_atto_allegato,
        annotazioni_atto_allegato,
        pratica_atto_allegato,
        resp_amm_atto_allegato,
        resp_contabile_atto_allegato,
        anno_titolario_atto_allegato,
        num_titolario_atto_allegato,
        vers_invio_firma_atto_allegato,
        cod_stato_atto_allegato,
        desc_stato_atto_allegato,
        sogg_id_atto_allegato,
        cod_sogg_atto_allegato,
        tipo_sogg_atto_allegato,
        stato_sogg_atto_allegato,
        rag_sociale_sogg_atto_allegato,
        p_iva_sogg_atto_allegato,
        cf_sogg_atto_allegato,
        cf_estero_sogg_atto_allegato,
        nome_sogg_atto_allegato,
        cognome_sogg_atto_allegato,
        anno_doc,
        num_doc,
        desc_doc,
        importo_doc,
        beneficiario_multiplo_doc,
        data_emissione_doc,
        data_scadenza_doc,
        codice_bollo_doc,
        desc_codice_bollo_doc,
        collegato_cec_doc,
        cod_pcc_doc,
        desc_pcc_doc,
        cod_ufficio_doc,
        desc_ufficio_doc,
        cod_stato_doc,
        desc_stato_doc,
        anno_elenco_doc,
        num_elenco_doc,
        data_trasmissione_elenco_doc,
        tot_quote_entrate_elenco_doc,
        tot_quote_spese_elenco_doc,
        tot_da_pagare_elenco_doc,
        tot_da_incassare_elenco_doc,
        cod_stato_elenco_doc,
        desc_stato_elenco_doc,
        cod_gruppo_doc,
        desc_gruppo_doc,
        cod_famiglia_doc,
        desc_famiglia_doc,
        cod_tipo_doc,
        desc_tipo_doc,
        sogg_id_doc,
        cod_sogg_doc,
        tipo_sogg_doc,
        stato_sogg_doc,
        rag_sociale_sogg_doc,
        p_iva_sogg_doc,
        cf_sogg_doc,
        cf_estero_sogg_doc,
        nome_sogg_doc,
        cognome_sogg_doc,
        num_subdoc,
        desc_subdoc,
        importo_subdoc,
        num_reg_iva_subdoc,
        data_scadenza_subdoc,
        convalida_manuale_subdoc,
        importo_da_dedurre_subdoc,
        splitreverse_importo_subdoc,
        pagato_cec_subdoc,
        data_pagamento_cec_subdoc,
        note_tesoriere_subdoc,
        cod_distinta_subdoc,
        desc_distinta_subdoc,
        tipo_commissione_subdoc,
        conto_tesoreria_subdoc,
        rilevante_iva,
        ordinativo_singolo,
        ordinativo_manuale,
        esproprio,
        note,
        avviso,
        cod_tipo_avviso,
        desc_tipo_avviso,
        sogg_id_subdoc,
        cod_sogg_subdoc,
        tipo_sogg_subdoc,
        stato_sogg_subdoc,
        rag_sociale_sogg_subdoc,
        p_iva_sogg_subdoc,
        cf_sogg_subdoc,
        cf_estero_sogg_subdoc,
        nome_sogg_subdoc,
        cognome_sogg_subdoc,
        sede_secondaria_subdoc,
        bil_anno,
        anno_accertamento,
        num_accertamento,
        cod_accertamento,
        desc_accertamento,
        cod_subaccertamento,
        desc_subaccertamento,
        cod_tipo_accredito,
        desc_tipo_accredito,
        mod_pag_id,
        quietanziante,
        data_nascita_quietanziante,
        luogo_nascita_quietanziante,
        stato_nascita_quietanziante,
        bic,
        contocorrente,
        intestazione_contocorrente,
        iban,
        note_mod_pag,
        data_scadenza_mod_pag,
        sogg_id_mod_pag,
        cod_sogg_mod_pag,
        tipo_sogg_mod_pag,
        stato_sogg_mod_pag,
        rag_sociale_sogg_mod_pag,
        p_iva_sogg_mod_pag,
        cf_sogg_mod_pag,
        cf_estero_sogg_mod_pag,
        nome_sogg_mod_pag,
        cognome_sogg_mod_pag,
        bil_anno_ord,
        anno_ord, 
        num_ord, 
        num_subord,
        --nuova sezione coge 26-09-2016
        registro_repertorio,
		anno_repertorio,
		num_repertorio,
		data_repertorio,
        data_ricezione_portale,
        arrotondamento,
		doc_contabilizza_genpcc,
        doc_id -- SIAC-5573 
      )
      VALUES (v_ente_proprietario_id,
              v_ente_denominazione,
              v_anno_atto_amministrativo,
              v_num_atto_amministrativo,
              v_oggetto_atto_amministrativo,
              v_cod_tipo_atto_amministrativo,
              v_desc_tipo_atto_amministrativo,
              v_cod_cdr_atto_amministrativo,
              v_desc_cdr_atto_amministrativo,
              v_cod_cdc_atto_amministrativo,
              v_desc_cdc_atto_amministrativo,
              v_note_atto_amministrativo,
              v_cod_stato_atto_amministrativo,
              v_desc_stato_atto_amministrativo,
              v_causale_atto_allegato,
              v_altri_allegati_atto_allegato,
              v_dati_sensibili_atto_allegato,
              v_data_scadenza_atto_allegato,
              v_note_atto_allegato,
              v_annotazioni_atto_allegato,
              v_pratica_atto_allegato,
              v_resp_amm_atto_allegato,
              v_resp_contabile_atto_allegato,
              v_anno_titolario_atto_allegato,
              v_num_titolario_atto_allegato,
              v_vers_invio_firma_atto_allegato,
              v_cod_stato_atto_allegato,
              v_desc_stato_atto_allegato,
              v_sogg_id_atto_allegato,
              v_cod_sogg_atto_allegato,
              v_tipo_sogg_atto_allegato,
              v_stato_sogg_atto_allegato,
              v_rag_sociale_sogg_atto_allegato,
              v_p_iva_sogg_atto_allegato,
              v_cf_sogg_atto_allegato,
              v_cf_estero_sogg_atto_allegato,
              v_nome_sogg_atto_allegato,
              v_cognome_sogg_atto_allegato,
              v_anno_doc,
              v_num_doc,
              v_desc_doc,
              v_importo_doc,
              v_beneficiario_multiplo_doc,
              v_data_emissione_doc,
              v_data_scadenza_doc,
              v_codice_bollo_doc,
              v_desc_codice_bollo_doc,
              v_collegato_cec_doc,
              v_cod_pcc_doc,
              v_desc_pcc_doc,
              v_cod_ufficio_doc,
              v_desc_ufficio_doc,
              v_cod_stato_doc,
              v_desc_stato_doc,
              v_anno_elenco_doc,
              v_num_elenco_doc,
              v_data_trasmissione_elenco_doc,
              v_tot_quote_entrate_elenco_doc,
              v_tot_quote_spese_elenco_doc,
              v_tot_da_pagare_elenco_doc,
              v_tot_da_incassare_elenco_doc,
              v_cod_stato_elenco_doc,
              v_desc_stato_elenco_doc,
              v_cod_gruppo_doc,
              v_desc_gruppo_doc,
              v_cod_famiglia_doc,
              v_desc_famiglia_doc,
              v_cod_tipo_doc,
              v_desc_tipo_doc,
              v_sogg_id_doc,
              v_cod_sogg_doc,
              v_tipo_sogg_doc,
              v_stato_sogg_doc,
              v_rag_sociale_sogg_doc,
              v_p_iva_sogg_doc,
              v_cf_sogg_doc,
              v_cf_estero_sogg_doc,
              v_nome_sogg_doc,
              v_cognome_sogg_doc,
              v_num_subdoc,
              v_desc_subdoc,
              v_importo_subdoc,
              v_num_reg_iva_subdoc,
              v_data_scadenza_subdoc,
              v_convalida_manuale_subdoc,
              v_importo_da_dedurre_subdoc,
              v_splitreverse_importo_subdoc,
              v_pagato_cec_subdoc,
              v_data_pagamento_cec_subdoc,
              v_note_tesoriere_subdoc,
              v_cod_distinta_subdoc,
              v_desc_distinta_subdoc,
              v_tipo_commissione_subdoc,
              v_conto_tesoreria_subdoc,
              v_rilevante_iva,
              v_ordinativo_singolo,
              v_ordinativo_manuale,
              v_esproprio,
              v_note,
              v_avviso,
              v_cod_tipo_avviso,
              v_desc_tipo_avviso,
              v_soggetto_id,
              v_cod_sogg_subdoc,
              v_tipo_sogg_subdoc,
              v_stato_sogg_subdoc,
              v_rag_sociale_sogg_subdoc,
              v_p_iva_sogg_subdoc,
              v_cf_sogg_subdoc,
              v_cf_estero_sogg_subdoc,
              v_nome_sogg_subdoc,
              v_cognome_sogg_subdoc,
              v_sede_secondaria_subdoc,
              v_bil_anno,
              v_anno_accertamento,
              v_num_accertamento,
              v_cod_accertamento,
              v_desc_accertamento,
              v_cod_subaccertamento,
              v_desc_subaccertamento,
              v_cod_tipo_accredito,
              v_desc_tipo_accredito,
              v_mod_pag_id,
              v_quietanziante,
              v_data_nascita_quietanziante,
              v_luogo_nascita_quietanziante,
              v_stato_nascita_quietanziante,
              v_bic,
              v_contocorrente,
              v_intestazione_contocorrente,
              v_iban,
              v_note_mod_pag,
              v_data_scadenza_mod_pag,
              v_soggetto_id_modpag,
              v_cod_sogg_mod_pag,
              v_tipo_sogg_mod_pag,
              v_stato_sogg_mod_pag,
              v_rag_sociale_sogg_mod_pag,
              v_p_iva_sogg_mod_pag,
              v_cf_sogg_mod_pag,
              v_cf_estero_sogg_mod_pag,
              v_nome_sogg_mod_pag,
              v_cognome_sogg_mod_pag,
              v_bil_anno_ord,
              v_anno_ord, 
              v_num_ord, 
              v_num_subord,
              --nuova sezione coge 26-09-2016
              v_registro_repertorio,
			  v_anno_repertorio,
			  v_num_repertorio,
			  v_data_repertorio,
              v_data_ricezione_portale,
              v_arrotondamento::numeric,
			  v_doc_contabilizza_genpcc,
              v_doc_id -- SIAC-5573             
             );

	END LOOP;

END LOOP;
esito:= 'Fine funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico documenti entrata (FNC_SIAC_DWH_DOCUMENTO_ENTRATA) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

ALTER TABLE siac_dwh_subordinativo_incasso ADD COLUMN doc_id integer;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_ordinativo_incasso (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico ordinativi in incasso (FNC_SIAC_DWH_ORDINATIVO_INCASSO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_ordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

esito:= '  Inizio eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_subordinativo_incasso
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;


INSERT INTO siac.siac_dwh_ordinativo_incasso
  (
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_fase_operativa,
  desc_fase_operativa,
  anno_ord_inc,
  num_ord_inc,
  desc_ord_inc,
  cod_stato_ord_inc,
  desc_stato_ord_inc,
  castelletto_cassa_ord_inc,
  castelletto_competenza_ord_inc,
  castelletto_emessi_ord_inc,
  data_emissione,
  data_riduzione,
  data_spostamento,
  data_variazione,
  beneficiario_multiplo,
  cod_bollo,
  desc_cod_bollo,
  cod_tipo_commissione,
  desc_tipo_commissione,
  cod_conto_tesoreria,
  decrizione_conto_tesoreria,
  cod_distinta,
  desc_distinta,
  soggetto_id,
  cod_soggetto,
  desc_soggetto,
  cf_soggetto,
  cf_estero_soggetto,
  p_iva_soggetto,
  soggetto_id_mod_pag,
  cod_soggetto_mod_pag,
  desc_soggetto_mod_pag,
  cf_soggetto_mod_pag,
  cf_estero_soggetto_mod_pag,
  p_iva_soggetto_mod_pag,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_avviso,
  desc_tipo_avviso,
  cod_pdc_finanziario_i,
  desc_pdc_finanziario_i,
  cod_pdc_finanziario_ii,
  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,
  desc_pdc_finanziario_iii,
  cod_pdc_finanziario_iv,
  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,
  desc_pdc_finanziario_v,
  cod_pdc_economico_i,
  desc_pdc_economico_i,
  cod_pdc_economico_ii,
  desc_pdc_economico_ii,
  cod_pdc_economico_iii,
  desc_pdc_economico_iii,
  cod_pdc_economico_iv,
  desc_pdc_economico_iv,
  cod_pdc_economico_v,
  desc_pdc_economico_v,
  cod_cofog_divisione,
  desc_cofog_divisione,
  cod_cofog_gruppo,
  desc_cofog_gruppo,
  classificatore_1,
  classificatore_1_valore,
  classificatore_1_desc_valore,
  classificatore_2,
  classificatore_2_valore,
  classificatore_2_desc_valore,
  classificatore_3,
  classificatore_3_valore,
  classificatore_3_desc_valore,
  classificatore_4,
  classificatore_4_valore,
  classificatore_4_desc_valore,
  classificatore_5,
  classificatore_5_valore,
  classificatore_5_desc_valore,
  allegato_cartaceo,
  cup,
  note,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  importo_iniziale,
  importo_attuale,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  data_firma,
  firma,
  data_inizio_val_stato_ordin,
  data_inizio_val_ordin,
  data_creazione_ordin,
  data_modifica_ordin,
  data_trasmissione,
  cod_siope,
  desc_siope,
  caus_id -- SIAC-5522
  )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end, 
tb.codbollo_code, tb.codbollo_desc,
tb.comm_tipo_code, tb.comm_tipo_desc,
tb.contotes_code, tb.contotes_desc,
tb.dist_code, tb.dist_desc,
tb.soggetto_id,tb.soggetto_code, tb.soggetto_desc, tb.codice_fiscale, tb.codice_fiscale_estero, tb.partita_iva,
tb.v_soggetto_id_modpag,  tb.v_codice_soggetto_modpag, tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,tb. v_codice_fiscale_estero_soggetto_modpag,tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito, tb.v_descrizione_tipo_accredito, tb.modpag_id,
tb.v_quietanziante, tb.v_data_nascita_quietanziante,tb.v_luogo_nascita_quietanziante,tb.v_stato_nascita_quietanziante, 
tb.v_bic, tb.v_contocorrente, tb.v_intestazione_contocorrente, tb.v_iban, 
tb.v_note_modalita_pagamento, tb.v_data_scadenza_modalita_pagamento,
tb.attoamm_tipo_code, tb.attoamm_tipo_desc,tb.attoamm_stato_desc,
tb.attoamm_anno, tb.attoamm_numero, tb.attoamm_oggetto, tb.attoamm_note,
tb.v_codice_tipo_avviso, tb.v_descrizione_tipo_avviso,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
tb.codice_cofog_divisione, tb.descrizione_cofog_divisione,tb.codice_cofog_gruppo,tb.descrizione_cofog_gruppo,
tb.cla26_classif_tipo_desc,tb.cla26_classif_code,tb.cla26_classif_desc,
tb.cla27_classif_tipo_desc,tb.cla27_classif_code,tb.cla27_classif_desc,
tb.cla28_classif_tipo_desc,tb.cla28_classif_code,tb.cla28_classif_desc,
tb.cla29_classif_tipo_desc,tb.cla29_classif_code,tb.cla29_classif_desc, 
tb.cla30_classif_tipo_desc,tb.cla30_classif_code,tb.cla30_classif_desc, 
tb.v_flagAllegatoCartaceo,
tb.v_cup,
tb.v_note_ordinativo,
tb.v_codice_capitolo, tb.v_codice_articolo, tb.v_codice_ueb, tb.v_descrizione_capitolo , 
tb.v_descrizione_articolo,tb.importo_iniziale,tb.importo_attuale,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end cdr_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end cdr_desc,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end cdc_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end cdc_desc,
tb.v_data_firma,tb.v_firma,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_ordpg,
tb.data_creazione_ordpg,
tb.data_modifica_ordpg,
tb.ord_trasm_oil_data,
tb.mif_ord_class_codice_cge,
tb.descr_siope,
tb.caus_id -- SIAC-5522
from (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza, 
a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data, 
a.ord_beneficiariomult
,a.ord_id, --q.elem_id,
b.bil_id, a.comm_tipo_id,
f.validita_inizio as data_inizio_val_stato_ordpg,
a.validita_inizio as data_inizio_val_ordpg,
a.data_creazione as data_creazione_ordpg,
a.data_modifica as data_modifica_ordpg,
a.codbollo_id,a.contotes_id,a.dist_id,
a.ord_trasm_oil_data,
a.caus_id -- SIAC-5522
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i 
where  d.ente_proprietario_id = p_ente_proprietario_id
and 
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'I' and 
a.bil_id = b.bil_id and 
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id 
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select 
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select 
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from 
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo, 
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo , 
a.elem_desc2 v_descrizione_articolo 
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id        
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL                                
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, --b.accredito_tipo_id v_accredito_tipo_id, 
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante, 
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante, 
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente, 
       b.iban v_iban, 
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag, 
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select 
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT 
c.ord_id,d.soggetto_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data) 
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,a.soggetto_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT 
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT 
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT 
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla26_classif_tipo_desc,      
b.classif_code cla26_classif_code, b.classif_desc cla26_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_26'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla27_classif_tipo_desc,
b.classif_code cla27_classif_code, b.classif_desc cla27_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_27'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla28_classif_tipo_desc,
b.classif_code cla28_classif_code, b.classif_desc cla28_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_28'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla29_classif_tipo_desc,
b.classif_code cla29_classif_code, b.classif_desc cla29_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_29'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc cla30_classif_tipo_desc,
b.classif_code cla30_classif_code, b.classif_desc cla30_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_30'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),
cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct 
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_ordinativo_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND  
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null and 
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siac_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select 
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT 
a.ord_id
, a."boolean" v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagAllegatoCartaceo' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_cup as (
SELECT 
a.ord_id
, a.testo v_cup
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='cup' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT 
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_ORDINATIVO' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
,
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, 
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY 
a.ord_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale, 
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY 
a.ord_id),
firma as (select 
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
, mif as (        
  select tb.mif_ord_ord_id, tb.mif_ord_class_codice_cge, tb.descr_siope from (
  with mif1 as (        
      select a.mif_ord_anno, a.mif_ord_numero, a.mif_ord_ord_id,
             a.mif_ord_class_codice_cge,
             b.flusso_elab_mif_id, b.flusso_elab_mif_data
      from mif_t_ordinativo_entrata a,  mif_t_flusso_elaborato b 
      where a.ente_proprietario_id=p_ente_proprietario_id  
      and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
     ) ,
      mifmax as (
      select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
      a.mif_ord_anno,a.mif_ord_numero::integer  
      from mif_t_ordinativo_entrata a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id   
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id 
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero::integer
    ),
      descsiope as (
      select replace(substring(a.classif_code from 2),'.', '') codice_siope,
         a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'PDC_V'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   substring(a.classif_code from 1 for 1) = 'E'
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      union
      select a.classif_code codice_siope,
             a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'SIOPE_ENTRATA_I'
      and   a.classif_code not in ('XXXX','YYYY')
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      )
    select mif1.*, descsiope.descr_siope
    from mif1 
    left join descsiope on descsiope.codice_siope = mif1.mif_ord_class_codice_cge
    join mifmax on mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id 
    and  mif1.mif_ord_anno=mifmax.mif_ord_anno 
    and  mif1.mif_ord_numero::integer=mifmax.mif_ord_numero) as tb
    ) 
select ord_pag.*, 
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo, t_cup.v_cup,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,bollo.*,commis.*,contotes.*,dist.*,modpag.*,sogg.*,
tipoavviso.*,ricspesa.*,transue.*,
class26.*,class27.*,class28.*,class29.*,class30.*,
bilelem.*,
mif.mif_ord_class_codice_cge, mif.descr_siope
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id  
left join pdc5
on ord_pag.ord_id=pdc5.ord_id  
left join pdc4
on ord_pag.ord_id=pdc4.ord_id  
left join pce5
on ord_pag.ord_id=pce5.ord_id  
left join pce4
on ord_pag.ord_id=pce4.ord_id  
left join attoamm
on ord_pag.ord_id=attoamm.ord_id  
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id  
left join t_cup
on ord_pag.ord_id=t_cup.ord_id  
left join t_noteordinativo
on 
ord_pag.ord_id=t_noteordinativo.ord_id  
left join impiniziale
on ord_pag.ord_id=impiniziale.ord_id  
left join impattuale
on ord_pag.ord_id=impattuale.ord_id  
left join firma
on ord_pag.ord_id=firma.ord_id
left join mif on ord_pag.ord_id = mif.mif_ord_ord_id
) as tb; 

 
    
     INSERT INTO siac.siac_dwh_subordinativo_incasso
    (
    ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_fase_operativa,
    desc_fase_operativa,
    anno_ord_inc,
    num_ord_inc,
    desc_ord_inc,
    cod_stato_ord_inc,
    desc_stato_ord_inc,
    castelletto_cassa_ord_inc,
    castelletto_competenza_ord_inc,
    castelletto_emessi_ord_inc,
    data_emissione,
    data_riduzione,
    data_spostamento,
    data_variazione,
    beneficiario_multiplo,
    num_subord_inc,
    desc_subord_inc,
    data_scadenza,
    importo_iniziale,
    importo_attuale,
    cod_onere,
    desc_onere,
    cod_tipo_onere,
    desc_tipo_onere,
    importo_carico_ente,
    importo_carico_soggetto,
    importo_imponibile,
    inizio_attivita,
    fine_attivita,
    cod_causale,
    desc_causale,
    cod_attivita_onere,
    desc_attivita_onere,
    anno_accertamento,
    num_accertamento,
    desc_accertamento,
    cod_subaccertamento,
    importo_quietanziato,
    data_inizio_val_stato_ordin,
    data_inizio_val_subordin,
    data_creazione_subordin,
    data_modifica_subordin,
      --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
    cod_gruppo_doc,
  	desc_gruppo_doc ,
    cod_famiglia_doc ,
    desc_famiglia_doc ,
    cod_tipo_doc ,
    desc_tipo_doc ,
    anno_doc ,
    num_doc ,
    num_subdoc ,
    cod_sogg_doc,
    caus_id, -- SIAC-5522
    doc_id -- SIAC-5573   
    )
    select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end, 
tb.ord_ts_code, tb.ord_ts_desc, tb.ord_ts_data_scadenza, tb.importo_iniziale, tb.importo_attuale,
tb.onere_code, tb.onere_desc,tb.onere_tipo_code, tb.onere_tipo_desc   ,
tb.importo_carico_ente, tb.importo_carico_soggetto, tb.importo_imponibile,
tb.attivita_inizio, tb.attivita_fine,tb.v_caus_code, tb.v_caus_desc,
tb.v_onere_att_code, tb.v_onere_att_desc,
tb.movgest_anno,tb.movgest_numero,tb.movgest_desc,tb.movgest_ts_code,
case when tb.ord_stato_code='Q' then tb.importo_attuale else null end importo_quietanziato,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_subordpg,
tb.data_creazione_subordpg,
tb.data_modifica_subordpg,
  --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
tb.doc_gruppo_tipo_code,
tb.doc_gruppo_tipo_desc,
tb.doc_fam_tipo_code,
tb.doc_fam_tipo_desc,
tb.doc_tipo_code,
tb.doc_tipo_desc,
tb.doc_anno,
tb.doc_numero,
tb.subdoc_numero,
tb.soggetto_code,
tb.caus_id_ord, -- SIAC-5522
tb.doc_id -- SIAC-5573
from (
--subord
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza, 
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data, 
       a.ord_beneficiariomult
           ,  a.ord_id, --q.elem_id,
       b.bil_id, a.comm_tipo_id,
       f.validita_inizio as data_inizio_val_stato_ordpg,
       a.validita_inizio as data_inizio_val_ordpg,
       a.data_creazione as data_creazione_ordpg,
       a.data_modifica as data_modifica_ordpg,
       a.codbollo_id,a.contotes_id,a.dist_id, l.ord_ts_id,
       l.ord_ts_code, l.ord_ts_desc, l.ord_ts_data_scadenza,
       l.validita_inizio as data_inizio_val_subordpg,
       l.data_creazione as data_creazione_subordpg,
       l.data_modifica as data_modifica_subordpg,
       a.caus_id as caus_id_ord-- SIAC-5522    
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i ,siac_t_ordinativo_ts l
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id 
and 
c.anno = p_anno_bilancio--p_anno_bilancio
AND e.ord_tipo_code = 'I' and 
a.bil_id = b.bil_id and 
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id 
and l.ord_id=a.ord_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select 
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select 
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from 
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo, 
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo , 
a.elem_desc2 v_descrizione_articolo 
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id        
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL                                
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, b.accredito_tipo_id v_accredito_tipo_id, 
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante, 
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante, 
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente, 
       b.iban v_iban, 
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag, 
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select 
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT 
c.ord_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data) 
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT 
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT 
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT 
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class26 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class27 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_2,
b.classif_code v_classificatore_generico_2_valore, b.classif_desc v_classificatore_generico_2_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class28 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_3,
b.classif_code v_classificatore_generico_3_valore, b.classif_desc v_classificatore_generico_3_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class29 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_4,
b.classif_code v_classificatore_generico_4_valore, b.classif_desc v_classificatore_generico_4_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class30 as (
SELECT 
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_5,
b.classif_code v_classificatore_generico_5_valore, b.classif_desc v_classificatore_generico_5_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from 
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct 
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b, 
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III 
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id 
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT 
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM 
siac.siac_r_ordinativo_atto_amm a, 
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c, 
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE 
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id 
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND  
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.data_cancellazione is null and 
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select 
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on 
atmc.classif_id=cdc.classif_id
left join cdr on 
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT 
a.ord_id
, a.testo v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='flagAllegatoCartaceo' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT 
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE 
b.attr_code='NOTE_ORDINATIVO' and 
a.ente_proprietario_id=p_ente_proprietario_id and 
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL),
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale, 
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY 
b.ord_ts_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale, 
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE  
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY 
b.ord_ts_id),
firma as (select 
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)),
ons as (
with  onere as (
select a.ord_ts_id,
c.onere_code, c.onere_desc, d.onere_tipo_code, d.onere_tipo_desc,
b.importo_carico_ente, b.importo_carico_soggetto, b.importo_imponibile,
b.attivita_inizio, b.attivita_fine, b.caus_id, b.onere_att_id 
from  siac_r_doc_onere_ordinativo_ts  a,siac_r_doc_onere b,siac_d_onere c,siac_d_onere_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
 b.doc_onere_id=a.doc_onere_id
and c.onere_id=b.onere_id
and d.onere_tipo_id=c.onere_tipo_id
and a.data_cancellazione is null 
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
 AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data) 
 AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data) 
),
 causale as (SELECT 
 dc.caus_id,
 dc.caus_code v_caus_code, dc.caus_desc v_caus_desc
  FROM siac.siac_d_causale dc
  WHERE  dc.ente_proprietario_id=p_ente_proprietario_id and  dc.data_cancellazione IS NULL)
 ,
 onatt as (
 -- Sezione per l'onere
  SELECT 
  doa.onere_att_id,
  doa.onere_att_code v_onere_att_code, doa.onere_att_desc v_onere_att_desc
  FROM siac_d_onere_attivita doa
  WHERE --doa.onere_att_id = v_onere_att_id
  doa.ente_proprietario_id=p_ente_proprietario_id 
    AND doa.data_cancellazione IS NULL)  
select * from onere left join causale
on onere.caus_id= causale.caus_id
left join onatt 
on onere.onere_att_id=onatt.onere_att_id)
,
movgest as (
select a.ord_ts_id, c.movgest_anno,c.movgest_numero,c.movgest_desc,
case when d.movgest_ts_tipo_code = 'T' then
     	null
     else
     	b.movgest_ts_code
end movgest_ts_code 
from  
siac_r_ordinativo_ts_movgest_ts a,siac_t_movgest_ts b,siac_t_movgest c,siac_d_movgest_ts_tipo d
where 
a.ente_proprietario_id=p_ente_proprietario_id and 
a.movgest_ts_id=b.movgest_ts_id
and c.movgest_id=b.movgest_id
and d.movgest_ts_tipo_id=b.movgest_ts_tipo_id
and p_data BETWEEN a.validita_inizio and COALESCE (a.validita_fine,p_data)
)  ,
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc as (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,    	        
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id,
        t_doc.doc_id -- SIAC-5573   
    from siac_t_doc t_doc
    		LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND p_data BETWEEN r_doc_sog.validita_inizio AND 
                    	COALESCE(r_doc_sog.validita_fine, p_data))
            LEFT JOIN siac_t_soggetto t_soggetto
            	ON (t_soggetto.soggetto_id=r_doc_sog.soggetto_id
                	AND t_soggetto.data_cancellazione IS NULL),
		siac_t_subdoc t_subdoc, 
    	siac_d_doc_tipo d_doc_tipo
        	LEFT JOIN siac_d_doc_gruppo d_doc_gruppo
            	ON (d_doc_gruppo.doc_gruppo_tipo_id=d_doc_tipo.doc_gruppo_tipo_id
                	AND d_doc_gruppo.data_cancellazione IS NULL),
    	siac_d_doc_fam_tipo d_doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts
    where t_doc.doc_id=t_subdoc.doc_id
    	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id    
        and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id           
        and r_subdoc_ord_ts.subdoc_id=t_subdoc.subdoc_id
    	and t_doc.ente_proprietario_id=p_ente_proprietario_id
    	and t_doc.data_cancellazione IS NULL
   		and t_subdoc.data_cancellazione IS NULL
        AND d_doc_fam_tipo.data_cancellazione IS NULL
        and d_doc_tipo.data_cancellazione IS NULL        
        and r_subdoc_ord_ts.data_cancellazione IS NULL
        and r_subdoc_ord_ts.validita_fine IS NULL
        AND p_data BETWEEN r_subdoc_ord_ts.validita_inizio AND 
                    	COALESCE(r_subdoc_ord_ts.validita_fine, p_data)) 
select ord_pag.*, 
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,
movgest.ord_ts_id, movgest.movgest_anno,movgest.movgest_numero,movgest.movgest_desc,movgest.movgest_ts_code,
elenco_doc.*
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class26
on ord_pag.ord_id=class26.ord_id
left join class27
on ord_pag.ord_id=class27.ord_id
left join class28
on ord_pag.ord_id=class28.ord_id
left join class29
on ord_pag.ord_id=class29.ord_id
left join class30
on ord_pag.ord_id=class30.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id  
left join pdc5
on ord_pag.ord_id=pdc5.ord_id  
left join pdc4
on ord_pag.ord_id=pdc4.ord_id  
left join pce5
on ord_pag.ord_id=pce5.ord_id  
left join pce4
on ord_pag.ord_id=pce4.ord_id  
left join attoamm
on ord_pag.ord_id=attoamm.ord_id  
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id  
left join t_noteordinativo
on 
ord_pag.ord_id=t_noteordinativo.ord_id  
left join impiniziale
on ord_pag.ord_ts_id=impiniziale.ord_ts_id  
left join impattuale
on ord_pag.ord_ts_id=impattuale.ord_ts_id  
left join firma
on ord_pag.ord_id=firma.ord_id 
left join ons
on ord_pag.ord_ts_id=ons.ord_ts_id     
left join movgest
on ord_pag.ord_ts_id=movgest.ord_ts_id 
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
left join elenco_doc
on elenco_doc.ord_ts_id=ord_pag.ord_ts_id  
) as tb;
  

esito:= 'Fine funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

ALTER TABLE siac_dwh_subordinativo_pagamento ADD COLUMN doc_id integer;

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_ordinativo_pagamento (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;
IF p_anno_bilancio IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Anno di bilancio nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_ordinativo_pagamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
return next;

esito:= '  Inizio eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;
DELETE FROM siac.siac_dwh_subordinativo_pagamento
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati subordinativi pregressi - '||clock_timestamp();
return next;

INSERT INTO siac.siac_dwh_ordinativo_pagamento
  (
  ente_proprietario_id,
  ente_denominazione,
  bil_anno,
  cod_fase_operativa,
  desc_fase_operativa,
  anno_ord_pag,
  num_ord_pag,
  desc_ord_pag,
  cod_stato_ord_pag,
  desc_stato_ord_pag,
  castelletto_cassa_ord_pag,
  castelletto_competenza_ord_pag,
  castelletto_emessi_ord_pag,
  data_emissione,
  data_riduzione,
  data_spostamento,
  data_variazione,
  beneficiario_multiplo,
  cod_bollo,
  desc_cod_bollo,
  cod_tipo_commissione,
  desc_tipo_commissione,
  cod_conto_tesoreria,
  decrizione_conto_tesoreria,
  cod_distinta,
  desc_distinta,
  soggetto_id,
  cod_soggetto,
  desc_soggetto,
  cf_soggetto,
  cf_estero_soggetto,
  p_iva_soggetto,
  soggetto_id_mod_pag,
  cod_soggetto_mod_pag,
  desc_soggetto_mod_pag,
  cf_soggetto_mod_pag,
  cf_estero_soggetto_mod_pag,
  p_iva_soggetto_mod_pag,
  cod_tipo_accredito,
  desc_tipo_accredito,
  mod_pag_id,
  quietanziante,
  data_nascita_quietanziante,
  luogo_nascita_quietanziante,
  stato_nascita_quietanziante,
  bic,
  contocorrente,
  intestazione_contocorrente,
  iban,
  note_mod_pag,
  data_scadenza_mod_pag,
  tipo_cessione, -- 04.07.2017 Sofia SIAC-5036
  cod_cessione,  -- 04.07.2017 Sofia SIAC-5036
  desc_cessione, -- 04.07.2017 Sofia SIAC-5036
  cod_tipo_atto_amministrativo,
  desc_tipo_atto_amministrativo,
  desc_stato_atto_amministrativo,
  anno_atto_amministrativo,
  num_atto_amministrativo,
  oggetto_atto_amministrativo,
  note_atto_amministrativo,
  cod_tipo_avviso,
  desc_tipo_avviso,
  cod_spesa_ricorrente,
  desc_spesa_ricorrente,
  cod_transazione_spesa_ue,
  desc_transazione_spesa_ue,
  cod_pdc_finanziario_i,
  desc_pdc_finanziario_i,
  cod_pdc_finanziario_ii,
  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,
  desc_pdc_finanziario_iii,
  cod_pdc_finanziario_iv,
  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,
  desc_pdc_finanziario_v,
  cod_pdc_economico_i,
  desc_pdc_economico_i,
  cod_pdc_economico_ii,
  desc_pdc_economico_ii,
  cod_pdc_economico_iii,
  desc_pdc_economico_iii,
  cod_pdc_economico_iv,
  desc_pdc_economico_iv,
  cod_pdc_economico_v,
  desc_pdc_economico_v,
  cod_cofog_divisione,
  desc_cofog_divisione,
  cod_cofog_gruppo,
  desc_cofog_gruppo,
  classificatore_1,
  classificatore_1_valore,
  classificatore_1_desc_valore,
  classificatore_2,
  classificatore_2_valore,
  classificatore_2_desc_valore,
  classificatore_3,
  classificatore_3_valore,
  classificatore_3_desc_valore,
  classificatore_4,
  classificatore_4_valore,
  classificatore_4_desc_valore,
  classificatore_5,
  classificatore_5_valore,
  classificatore_5_desc_valore,
  allegato_cartaceo,
  --cup,
  note,
  cod_capitolo,
  cod_articolo,
  cod_ueb,
  desc_capitolo,
  desc_articolo,
  importo_iniziale,
  importo_attuale,
  cod_cdr_atto_amministrativo,
  desc_cdr_atto_amministrativo,
  cod_cdc_atto_amministrativo,
  desc_cdc_atto_amministrativo,
  data_firma,
  firma,
  data_inizio_val_stato_ordpg,
  data_inizio_val_ordpg,
  data_creazione_ordpg,
  data_modifica_ordpg,
  data_trasmissione,
  cod_siope,
  desc_siope,
  soggetto_csc_id, -- SIAC-5228
  cod_siope_tipo_debito, 
  desc_siope_tipo_debito, 
  desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, 
  desc_siope_assenza_motivazione, 
  desc_siope_assenza_motiv_bnkit
  )
select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end,
tb.codbollo_code, tb.codbollo_desc,
tb.comm_tipo_code, tb.comm_tipo_desc,
tb.contotes_code, tb.contotes_desc,
tb.dist_code, tb.dist_desc,
tb.soggetto_id,tb.soggetto_code, tb.soggetto_desc, tb.codice_fiscale, tb.codice_fiscale_estero, tb.partita_iva,
tb.v_soggetto_id_modpag,  tb.v_codice_soggetto_modpag, tb.v_descrizione_soggetto_modpag,
tb.v_codice_fiscale_soggetto_modpag,tb. v_codice_fiscale_estero_soggetto_modpag,tb.v_partita_iva_soggetto_modpag,
tb.v_codice_tipo_accredito, tb.v_descrizione_tipo_accredito, tb.modpag_id,
tb.v_quietanziante, tb.v_data_nascita_quietanziante,tb.v_luogo_nascita_quietanziante,tb.v_stato_nascita_quietanziante,
tb.v_bic, tb.v_contocorrente, tb.v_intestazione_contocorrente, tb.v_iban,
tb.v_note_modalita_pagamento, tb.v_data_scadenza_modalita_pagamento,
--tb.tipo_cessione, tb.cod_cessione, tb.desc_cessione, -- 04.07.2017 Sofia SIAC-5036
COALESCE(tb.tipo_cessione, tb.oil_relaz_tipo_code) tipo_cessione, -- SIAC-5228
COALESCE(tb.cod_cessione, tb.relaz_tipo_code) cod_cessione, -- SIAC-5228
COALESCE(tb.desc_cessione, tb.relaz_tipo_desc) desc_cessione, -- SIAC-5228
tb.attoamm_tipo_code, tb.attoamm_tipo_desc,tb.attoamm_stato_desc,
tb.attoamm_anno, tb.attoamm_numero, tb.attoamm_oggetto, tb.attoamm_note,
tb.v_codice_tipo_avviso, tb.v_descrizione_tipo_avviso,
tb.v_codice_spesa_ricorrente, tb.v_descrizione_spesa_ricorrente,
tb.v_codice_transazione_spesa_ue, tb.v_descrizione_transazione_spesa_ue,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_I else tb.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_I else tb.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_II else tb.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_II else tb.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_III else tb.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_III else tb.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_IV else tb.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_IV else tb.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   tb.pdc5_codice_pdc_finanziario_V is not null then    tb.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_I else tb.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_I else tb.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_II else tb.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_II else tb.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_III else tb.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_III else tb.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_IV else tb.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_IV else tb.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   tb.pce5_codice_pdc_economico_V is not null then    tb.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
tb.codice_cofog_divisione, tb.descrizione_cofog_divisione,tb.codice_cofog_gruppo,tb.descrizione_cofog_gruppo,
tb.cla21_classif_tipo_desc,tb.cla21_classif_code,tb.cla21_classif_desc,
tb.cla22_classif_tipo_desc,tb.cla22_classif_code,tb.cla22_classif_desc,
tb.cla23_classif_tipo_desc,tb.cla23_classif_code,tb.cla23_classif_desc,
tb.cla24_classif_tipo_desc,tb.cla24_classif_code,tb.cla24_classif_desc,
tb.cla25_classif_tipo_desc,tb.cla25_classif_code,tb.cla25_classif_desc,
tb.v_flagAllegatoCartaceo,tb.v_note_ordinativo,
tb.v_codice_capitolo, tb.v_codice_articolo, tb.v_codice_ueb, tb.v_descrizione_capitolo ,
tb.v_descrizione_articolo,tb.importo_iniziale,tb.importo_attuale,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_code::varchar else tb.cdr_cdr_code::varchar end cdr_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdr_desc::varchar else tb.cdr_cdr_desc::varchar end cdr_desc,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_code::varchar else tb.cdr_cdc_code::varchar end cdc_code,
case when tb.cdc_cdc_code::varchar is not null then  tb.cdc_cdc_desc::varchar else tb.cdr_cdc_desc::varchar end cdc_desc,
tb.v_data_firma,tb.v_firma,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_ordpg,
tb.data_creazione_ordpg,
tb.data_modifica_ordpg,
tb.ord_trasm_oil_data,
tb.mif_ord_class_codice_cge,
tb.descr_siope,
tb.soggetto_id_da soggetto_csc_id, -- SIAC-5228
tb.siope_tipo_debito_code, tb.siope_tipo_debito_desc, tb.siope_tipo_debito_desc_bnkit,
tb.siope_assenza_motivazione_code, tb.siope_assenza_motivazione_desc, tb.siope_assenza_motivazione_desc_bnkit 
from (
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
a.ord_beneficiariomult
,a.ord_id, --q.elem_id,
b.bil_id, a.comm_tipo_id,
f.validita_inizio as data_inizio_val_stato_ordpg,
a.validita_inizio as data_inizio_val_ordpg,
a.data_creazione as data_creazione_ordpg,
a.data_modifica as data_modifica_ordpg,
a.codbollo_id,a.contotes_id,a.dist_id,
a.ord_trasm_oil_data,
l.siope_tipo_debito_code, l.siope_tipo_debito_desc, l.siope_tipo_debito_desc_bnkit,
m.siope_assenza_motivazione_code, m.siope_assenza_motivazione_desc, m.siope_assenza_motivazione_desc_bnkit
FROM siac_t_ordinativo a
left join siac_d_siope_tipo_debito l on l.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and l.data_cancellazione is null
                                     and l.validita_fine is null
left join siac_d_siope_assenza_motivazione m on m.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and m.data_cancellazione is null
                                             and m.validita_fine is null
,siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id
and
c.anno = p_anno_bilancio
AND e.ord_tipo_code = 'P' and
a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
	   b.soggetto_id v_soggetto_id_modpag, --b.accredito_tipo_id v_accredito_tipo_id,
	   b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
	   b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
	   c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
	   c.codice_fiscale v_codice_fiscale_soggetto_modpag,
	   c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag,
	   b.accredito_tipo_id,
       null tipo_cessione , -- 04.07.2017 Sofia SIAC-5036
       null cod_cessione  , -- 04.07.2017 Sofia SIAC-5036
       null desc_cessione   -- 04.07.2017 Sofia SIAC-5036
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null
UNION -- 04.07.2017 Sofia SIAC-5036
select a.ord_id, b.modpag_id ,
	   b.soggetto_id v_soggetto_id_modpag,
	   b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
	   b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
	   c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
	   c.codice_fiscale v_codice_fiscale_soggetto_modpag,
	   c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag,
	   b.accredito_tipo_id,
       oil.oil_relaz_tipo_code tipo_cessione,
       tipo.relaz_tipo_code cod_cessione,
       tipo.relaz_tipo_desc desc_cessione
from siac_r_ordinativo_modpag a,siac_r_soggetto_relaz rel, siac_r_soggrel_modpag rmdp,
	 siac_r_oil_relaz_tipo roil,siac_d_oil_relaz_tipo oil,siac_d_relaz_tipo tipo,
	 siac_t_modpag b,siac_t_soggetto c
where a.ente_proprietario_id=p_ente_proprietario_id
and   a.modpag_id is NULL
and   rel.soggetto_relaz_id=a.soggetto_relaz_id
and   rmdp.soggetto_relaz_id=rel.soggetto_relaz_id
and   b.modpag_id=rmdp.modpag_id
and   c.soggetto_id=b.soggetto_id
and   roil.relaz_tipo_id=rel.relaz_tipo_id
and   tipo.relaz_tipo_id=roil.relaz_tipo_id
and   oil.oil_relaz_tipo_id=roil.oil_relaz_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
AND   p_data BETWEEN rmdp.validita_inizio AND COALESCE(rmdp.validita_fine, p_data)
AND   p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
and   a.data_cancellazione is null
and   b.data_cancellazione is null
and   c.data_cancellazione is null
and   rel.data_cancellazione is null
and   rmdp.data_cancellazione is null
and   roil.data_cancellazione is null
),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT
c.ord_id,d.soggetto_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,a.soggetto_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class21 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla21_classif_tipo_desc,
b.classif_code cla21_classif_code, b.classif_desc cla21_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class22 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla22_classif_tipo_desc,
b.classif_code cla22_classif_code, b.classif_desc cla22_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class23 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla23_classif_tipo_desc,
b.classif_code cla23_classif_code, b.classif_desc cla23_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class24 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla24_classif_tipo_desc,
b.classif_code cla24_classif_code, b.classif_desc cla24_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class25 as (
SELECT
a.ord_id ,
c.classif_tipo_desc cla25_classif_tipo_desc,
b.classif_code cla25_classif_code, b.classif_desc cla25_classif_desc
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siac_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a."boolean" v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
,
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale,
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY
a.ord_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
a.ord_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
a.ord_id),
firma as (select
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data))
, mif as (
  select tb.mif_ord_ord_id, tb.mif_ord_class_codice_cge, tb.descr_siope from (
  with mif1 as (
      select a.mif_ord_anno, a.mif_ord_numero, a.mif_ord_ord_id,
             a.mif_ord_class_codice_cge,
             b.flusso_elab_mif_id, b.flusso_elab_mif_data
      from mif_t_ordinativo_spesa a,  mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and  a.mif_ord_flusso_elab_mif_id=b.flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
     ) ,
      mifmax as (
      select max(b.flusso_elab_mif_id) flusso_elab_mif_id,
      a.mif_ord_anno,a.mif_ord_numero::integer
      from mif_t_ordinativo_spesa a, mif_t_flusso_elaborato b
      where a.ente_proprietario_id=p_ente_proprietario_id
      and b.flusso_elab_mif_id=a.mif_ord_flusso_elab_mif_id
      and b.flusso_elab_mif_esito='OK'
      and a.data_cancellazione is null
      and b.data_cancellazione is null
      group by a.mif_ord_anno,a.mif_ord_numero::integer
    ),
      descsiope as (
      select replace(substring(a.classif_code from 2),'.', '') codice_siope,
         a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'PDC_V'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   substring(a.classif_code from 1 for 1) = 'U'
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      union
      select a.classif_code codice_siope,
             a.classif_desc descr_siope
      from  siac_t_class a, siac_d_class_tipo b
      where a.classif_tipo_id = b.classif_tipo_id
      and   b.classif_tipo_code = 'SIOPE_SPESA_I'
      and   a.ente_proprietario_id = p_ente_proprietario_id
      and   a.data_cancellazione is null
      and   b.data_cancellazione is null
      )
    select mif1.*, descsiope.descr_siope
    from mif1
    left join descsiope on descsiope.codice_siope = mif1.mif_ord_class_codice_cge
    join mifmax on mif1.flusso_elab_mif_id=mifmax.flusso_elab_mif_id
    and  mif1.mif_ord_anno=mifmax.mif_ord_anno
    and  mif1.mif_ord_numero::integer=mifmax.mif_ord_numero) as tb
    ),
modpagcsc as ( -- SIAC-5228
SELECT  ordts.ord_id, rel.soggetto_id_da, oil.oil_relaz_tipo_code, tipo.relaz_tipo_code, tipo.relaz_tipo_desc
FROM  siac_t_ordinativo_ts ordts, siac_r_subdoc_ordinativo_ts subdocordts, siac_r_subdoc_modpag subdocmodpag, siac_r_soggrel_modpag sogrel,
      siac_r_soggetto_relaz rel, siac_r_oil_relaz_tipo roil, siac_d_relaz_tipo tipo , siac_d_oil_relaz_tipo oil
WHERE  ordts.ente_proprietario_id = p_ente_proprietario_id
AND    oil.oil_relaz_tipo_code = 'CSC'
AND    ordts.ord_ts_id = subdocordts.ord_ts_id
AND    subdocordts.subdoc_id = subdocmodpag.subdoc_id
AND    sogrel.modpag_id = subdocmodpag.modpag_id
AND    sogrel.soggetto_relaz_id = rel.soggetto_relaz_id
AND    rel.relaz_tipo_id = roil.relaz_tipo_id
AND    tipo.relaz_tipo_id = roil.relaz_tipo_id
AND    oil.oil_relaz_tipo_id = roil.oil_relaz_tipo_id
AND    p_data BETWEEN subdocordts.validita_inizio AND COALESCE(subdocordts.validita_fine, p_data)
AND    p_data BETWEEN subdocmodpag.validita_inizio AND COALESCE(subdocmodpag.validita_fine, p_data)
AND    p_data BETWEEN sogrel.validita_inizio AND COALESCE(sogrel.validita_fine, p_data)
AND    p_data BETWEEN rel.validita_inizio AND COALESCE(rel.validita_fine, p_data)
AND    p_data BETWEEN roil.validita_inizio AND COALESCE(roil.validita_fine, p_data)
AND    ordts.data_cancellazione is null
AND    subdocordts.data_cancellazione is null
AND    subdocmodpag.data_cancellazione is null
AND    sogrel.data_cancellazione is null
AND    rel.data_cancellazione is null
AND    roil.data_cancellazione is null
AND    tipo.data_cancellazione is null
AND    oil.data_cancellazione is null
)
select ord_pag.*,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,bollo.*,commis.*,contotes.*,dist.*,modpag.*,sogg.*,
tipoavviso.*,ricspesa.*,transue.*,
class21.*,class22.*,class23.*,class24.*,class25.*,
bilelem.*,
mif.mif_ord_class_codice_cge, mif.descr_siope,
modpagcsc.soggetto_id_da,      -- SIAC-5228
modpagcsc.oil_relaz_tipo_code, -- SIAC-5228
modpagcsc.relaz_tipo_code,     -- SIAC-5228
modpagcsc.relaz_tipo_desc      -- SIAC-5228
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class21
on ord_pag.ord_id=class21.ord_id
left join class22
on ord_pag.ord_id=class22.ord_id
left join class23
on ord_pag.ord_id=class23.ord_id
left join class24
on ord_pag.ord_id=class24.ord_id
left join class25
on ord_pag.ord_id=class25.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id
left join pdc5
on ord_pag.ord_id=pdc5.ord_id
left join pdc4
on ord_pag.ord_id=pdc4.ord_id
left join pce5
on ord_pag.ord_id=pce5.ord_id
left join pce4
on ord_pag.ord_id=pce4.ord_id
left join attoamm
on ord_pag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on
ord_pag.ord_id=t_noteordinativo.ord_id
left join impiniziale
on ord_pag.ord_id=impiniziale.ord_id
left join impattuale
on ord_pag.ord_id=impattuale.ord_id
left join firma
on ord_pag.ord_id=firma.ord_id
left join mif on ord_pag.ord_id = mif.mif_ord_ord_id
left join modpagcsc on ord_pag.ord_id = modpagcsc.ord_id
) as tb;



    INSERT INTO siac.siac_dwh_subordinativo_pagamento
    (ente_proprietario_id,
    ente_denominazione,
    bil_anno,
    cod_fase_operativa,
    desc_fase_operativa,
    anno_ord_pag,
    num_ord_pag,
    desc_ord_pag,
    cod_stato_ord_pag,
    desc_stato_ord_pag,
    castelletto_cassa_ord_pag,
    castelletto_competenza_ord_pag,
    castelletto_emessi_ord_pag,
    data_emissione,
    data_riduzione,
    data_spostamento,
    data_variazione,
    beneficiario_multiplo,
    num_subord_pag,
    desc_subord_pag,
    data_esecuzione_pagamento,
    importo_iniziale,
    importo_attuale,
    cod_onere,
    desc_onere,
    cod_tipo_onere,
    desc_tipo_onere,
    importo_carico_ente,
    importo_carico_soggetto,
    importo_imponibile,
    inizio_attivita,
    fine_attivita,
    cod_causale,
    desc_causale,
    cod_attivita_onere,
    desc_attivita_onere,
    anno_liquidazione,
    num_liquidazione,
    desc_liquidazione,
    data_emissione_liquidazione,
    importo_liquidazione,
    liquidazione_automatica,
    liquidazione_convalida_manuale,
    cup,
    cig,
    data_inizio_val_stato_ordpg,
    data_inizio_val_subordpg,
    data_creazione_subordpg,
    data_modifica_subordpg,
      --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
    cod_gruppo_doc,
  	desc_gruppo_doc ,
    cod_famiglia_doc ,
    desc_famiglia_doc ,
    cod_tipo_doc ,
    desc_tipo_doc ,
    anno_doc ,
    num_doc ,
    num_subdoc ,
    cod_sogg_doc,
    doc_id -- SIAC-5573
    )
    select tb.ente_proprietario_id, tb.ente_denominazione, tb.anno, tb.fase_operativa_code,tb.fase_operativa_desc,
tb.ord_anno, tb.ord_numero,tb.ord_desc, tb.ord_stato_code,tb.ord_stato_desc,
tb.ord_cast_cassa, tb.ord_cast_competenza, tb.ord_cast_emessi,
tb.ord_emissione_data, tb.ord_riduzione_data, tb.ord_spostamento_data, tb.ord_variazione_data,
case when tb.ord_beneficiariomult=true then 'T' else 'F' end,
tb.ord_ts_code, tb.ord_ts_desc, tb.ord_ts_data_scadenza, tb.importo_iniziale, tb.importo_attuale,
tb.onere_code, tb.onere_desc,tb.onere_tipo_code, tb.onere_tipo_desc   ,
tb.importo_carico_ente, tb.importo_carico_soggetto, tb.importo_imponibile,
tb.attivita_inizio, tb.attivita_fine,tb.v_caus_code, tb.v_caus_desc,
tb.v_onere_att_code, tb.v_onere_att_desc,
tb.v_liq_anno,tb.v_liq_numero, tb.v_liq_desc, tb.v_liq_emissione_data,
tb.v_liq_importo, tb.v_liq_automatica, tb.liq_convalida_manuale,
tb.cup,tb.cig,
tb.data_inizio_val_stato_ordpg,
tb.data_inizio_val_subordpg,
tb.data_creazione_subordpg,
tb.data_modifica_subordpg,
  --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
tb.doc_gruppo_tipo_code,
tb.doc_gruppo_tipo_desc,
tb.doc_fam_tipo_code,
tb.doc_fam_tipo_desc,
tb.doc_tipo_code,
tb.doc_tipo_desc,
tb.doc_anno,
tb.doc_numero,
tb.subdoc_numero,
tb.soggetto_code, 
tb.doc_id -- SIAC-5573
from (
--subord
with ord_pag as (
SELECT d.ente_proprietario_id, d.ente_denominazione, c.anno, i.fase_operativa_code, i.fase_operativa_desc,
       a.ord_anno, a.ord_numero, a.ord_desc, g.ord_stato_code, g.ord_stato_desc, a.ord_cast_cassa, a.ord_cast_competenza,
       a.ord_cast_emessi, a.ord_emissione_data, a.ord_riduzione_data, a.ord_spostamento_data, a.ord_variazione_data,
       a.ord_beneficiariomult
           ,  a.ord_id, --q.elem_id,
       b.bil_id, a.comm_tipo_id,
       f.validita_inizio as data_inizio_val_stato_ordpg,
       a.validita_inizio as data_inizio_val_ordpg,
       a.data_creazione as data_creazione_ordpg,
       a.data_modifica as data_modifica_ordpg,
       a.codbollo_id,a.contotes_id,a.dist_id, l.ord_ts_id,
       l.ord_ts_code, l.ord_ts_desc, l.ord_ts_data_scadenza,
        l.validita_inizio as data_inizio_val_subordpg,
         l.data_creazione as data_creazione_subordpg,
         l.data_modifica as data_modifica_subordpg
FROM siac_t_ordinativo a, siac_t_bil b, siac_t_periodo c, siac_t_ente_proprietario d,
siac_d_ordinativo_tipo e, siac_r_ordinativo_stato f, siac_d_ordinativo_stato g ,
 siac_r_bil_fase_operativa h, siac_d_fase_operativa i ,siac_t_ordinativo_ts l
where  d.ente_proprietario_id = p_ente_proprietario_id--p_ente_proprietario_id
and
c.anno = p_anno_bilancio--p_anno_bilancio
AND e.ord_tipo_code = 'P' and
a.bil_id = b.bil_id and
c.periodo_id = b.periodo_id and
d.ente_proprietario_id = a.ente_proprietario_id and
a.ord_tipo_id = e.ord_tipo_id AND
f.ord_id = a.ord_id  and
f.ord_stato_id = g.ord_stato_id
and l.ord_id=a.ord_id
AND p_data BETWEEN f.validita_inizio AND COALESCE(f.validita_fine, p_data)
and h.fase_operativa_id = i.fase_operativa_id
AND   h.bil_id = b.bil_id
AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and g.data_cancellazione is null),
bollo as (select
a.codbollo_code, a.codbollo_desc,
a.codbollo_id from siac_d_codicebollo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
contotes as  (select
a.contotes_code, a.contotes_desc,a.contotes_id from siac_d_contotesoreria a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
)
,
dist as  (select a.dist_code, a.dist_desc,a.dist_id from siac_d_distinta a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
commis as  (select a.comm_tipo_code, a.comm_tipo_desc, a.comm_tipo_id from
siac_d_commissione_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null
),
bilelem as (SELECT b.ord_id,
a.elem_code v_codice_capitolo, a.elem_code2 v_codice_articolo,
a.elem_code3 v_codice_ueb, a.elem_desc v_descrizione_capitolo ,
a.elem_desc2 v_descrizione_articolo
FROM siac.siac_t_bil_elem a, siac_r_ordinativo_bil_elem b
WHERE a.elem_id = b.elem_id
and b.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is NULL
and b.data_cancellazione is NULL),
modpag as (
with mod as (
select a.ord_id, b.modpag_id ,
b.soggetto_id v_soggetto_id_modpag, b.accredito_tipo_id v_accredito_tipo_id,
b.quietanziante v_quietanziante, b.quietanzante_nascita_data v_data_nascita_quietanziante,
b.quietanziante_nascita_luogo v_luogo_nascita_quietanziante,
       b.quietanziante_nascita_stato v_stato_nascita_quietanziante,
       b.bic v_bic, b.contocorrente v_contocorrente, b.contocorrente_intestazione v_intestazione_contocorrente,
       b.iban v_iban,
       b.note v_note_modalita_pagamento, b.data_scadenza v_data_scadenza_modalita_pagamento,
 c.soggetto_code v_codice_soggetto_modpag, c.soggetto_desc v_descrizione_soggetto_modpag,
  c.codice_fiscale v_codice_fiscale_soggetto_modpag,
  c.codice_fiscale_estero v_codice_fiscale_estero_soggetto_modpag, c.partita_iva v_partita_iva_soggetto_modpag
  , b.accredito_tipo_id
from siac_r_ordinativo_modpag a,
siac_t_modpag b,siac_t_soggetto c
where a.modpag_id=b.modpag_id and a.ente_proprietario_id=p_ente_proprietario_id
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and c.soggetto_id=b.soggetto_id
and a.data_cancellazione is null and b.data_cancellazione is null
and c.data_cancellazione is null),
acc as (select
a.accredito_tipo_id,
a.accredito_tipo_code v_codice_tipo_accredito, a.accredito_tipo_desc v_descrizione_tipo_accredito
from siac_d_accredito_tipo a where a.ente_proprietario_id=p_ente_proprietario_id
and a.data_cancellazione is null)
select * from mod left join acc
on mod.accredito_tipo_id=acc.accredito_tipo_id
)
,
sogg as (
SELECT
c.ord_id,
d.soggetto_code, d.soggetto_desc, d.codice_fiscale, d.codice_fiscale_estero, d.partita_iva
FROM siac_r_soggetto_relaz a, siac_d_relaz_tipo b,siac_r_ordinativo_soggetto c,siac_t_soggetto d
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.relaz_tipo_id = b.relaz_tipo_id
AND   b.relaz_tipo_code  = 'SEDE_SECONDARIA'
and c.soggetto_id=a.soggetto_id_da
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and d.soggetto_id=c.soggetto_id
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
union
select b.ord_id,
a.soggetto_code, a.soggetto_desc, a.codice_fiscale, a.codice_fiscale_estero, a.partita_iva
 from siac_t_soggetto a, siac_r_ordinativo_soggetto b
where a.ente_proprietario_id=p_ente_proprietario_id
and a.soggetto_id=b.soggetto_id
and p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
),
--classificatori non gerarchici
tipoavviso as (
SELECT
a.ord_id ,b.classif_code v_codice_tipo_avviso, b.classif_desc v_descrizione_tipo_avviso
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_AVVISO'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
),
ricspesa as (
SELECT
a.ord_id ,b.classif_code v_codice_spesa_ricorrente, b.classif_desc v_descrizione_spesa_ricorrente
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
transue as (
SELECT
a.ord_id ,b.classif_code v_codice_transazione_spesa_ue, b.classif_desc v_descrizione_transazione_spesa_ue
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class21 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_1,
b.classif_code v_classificatore_generico_1_valore, b.classif_desc v_classificatore_generico_1_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_21'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class22 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_2,
b.classif_code v_classificatore_generico_2_valore, b.classif_desc v_classificatore_generico_2_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_22'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class23 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_3,
b.classif_code v_classificatore_generico_3_valore, b.classif_desc v_classificatore_generico_3_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_23'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class24 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_4,
b.classif_code v_classificatore_generico_4_valore, b.classif_desc v_classificatore_generico_4_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_24'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
)
,
class25 as (
SELECT
a.ord_id ,
c.classif_tipo_desc v_classificatore_generico_5,
b.classif_code v_classificatore_generico_5_valore, b.classif_desc v_classificatore_generico_5_descrizione_valore
 from siac_r_ordinativo_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id--p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_25'
AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
),

cofog as (
select distinct r.ord_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--DIVISIONE_COFOG
siac_r_class_fam_tree d2,
siac_t_class a2
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='GRUPPO_COFOG'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null)
, pdc5 as (
select distinct
r.ord_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pdc4 as (
select distinct r.ord_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PDC_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
)
, pce5 as (
select distinct r.ord_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4,
--PDC_I
siac_r_class_fam_tree d5,
siac_t_class a5
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_V'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and d5.classif_id=a4.classif_id
and a5.classif_id=d5.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
and d5.data_cancellazione is null
and a5.data_cancellazione is null
)
, pce4 as (
select distinct r.ord_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_ordinativo_class r,
siac_t_class a,siac_d_class_tipo b,
--PDC_IV
siac_r_class_fam_tree d2,
siac_t_class a2,
--PDC_III
siac_r_class_fam_tree d3,
siac_t_class a3,
--PDC_II
siac_r_class_fam_tree d4,
siac_t_class a4
where
r.ente_proprietario_id=p_ente_proprietario_id
and  a.classif_id=r.classif_id
and a.classif_tipo_id=b.classif_tipo_id
and b.classif_tipo_code='PCE_IV'
and d2.classif_id=a.classif_id
and a2.classif_id=d2.classif_id_padre
and d3.classif_id=a2.classif_id
and a3.classif_id=d3.classif_id_padre
and d4.classif_id=a3.classif_id
and a4.classif_id=d4.classif_id_padre
and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d3.validita_fine,p_data)
and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
and r.data_cancellazione is null
and a.data_cancellazione is null
and b.data_cancellazione is null
and d2.data_cancellazione is null
and a2.data_cancellazione is null
and d3.data_cancellazione is null
and a3.data_cancellazione is null
and d4.data_cancellazione is null
and a4.data_cancellazione is null
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.ord_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_ordinativo_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
--AND
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null and
 p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
)
select atm.*,atmrclass.classif_id from atm left join atmrclass
on atmrclass.attoamm_id=atm.attoamm_id
)
,
cdc as (
select a.classif_id,a.classif_code cdc_cdc_code,a.classif_desc cdc_cdc_desc
,a2.classif_code cdc_cdr_code,a2.classif_desc cdc_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b, siac_r_class_fam_tree c,siaC_t_class a2
where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDC'
and c.classif_id=a.classif_id
and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null)
select
atmc.ord_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id)
--sezione attributi
, t_flagAllegatoCartaceo as (
SELECT
a.ord_id
, a.testo v_flagAllegatoCartaceo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagAllegatoCartaceo' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_noteordinativo as (
SELECT
a.ord_id
, a.testo v_note_ordinativo
FROM   siac.siac_r_ordinativo_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_ORDINATIVO' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL)
, t_cig as (
SELECT
a.sord_id
, c.testo cig
FROM   siac_r_liquidazione_ord a, siac_t_attr b,siac_r_liquidazione_attr c
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 c.attr_id = b.attr_id
 and c.liq_id=a.liq_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL)
, t_cup as (
SELECT
a.sord_id
, c.testo cup
FROM   siac_r_liquidazione_ord a, siac_t_attr b,siac_r_liquidazione_attr c
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 c.attr_id = b.attr_id
 and c.liq_id=a.liq_id
AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    c.data_cancellazione IS NULL),
impiniziale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_iniziale,
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='I'
GROUP BY
b.ord_ts_id),
impattuale as (
SELECT COALESCE(SUM(b.ord_ts_det_importo),0) importo_attuale,
b.ord_ts_id
FROM   siac.siac_t_ordinativo_ts a, siac.siac_t_ordinativo_ts_det b, siac.siac_d_ordinativo_ts_det_tipo c
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.ord_ts_id = b.ord_ts_id
AND    c.ord_ts_det_tipo_id = b.ord_ts_det_tipo_id
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.data_cancellazione IS NULL
and c.ord_ts_det_tipo_code='A'
GROUP BY
b.ord_ts_id),
firma as (select
a.ord_id,
a.ord_firma_data v_data_firma, a.ord_firma v_firma
 from siac_r_ordinativo_firma a where a.ente_proprietario_id=p_ente_proprietario_id
AND   a.data_cancellazione IS NULL
AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)),
ons as (
with  onere as (
select a.ord_ts_id,
c.onere_code, c.onere_desc, d.onere_tipo_code, d.onere_tipo_desc,
b.importo_carico_ente, b.importo_carico_soggetto, b.importo_imponibile,
b.attivita_inizio, b.attivita_fine, b.caus_id, b.onere_att_id
from  siac_r_doc_onere_ordinativo_ts  a,siac_r_doc_onere b,siac_d_onere c,siac_d_onere_tipo d
where
a.ente_proprietario_id=p_ente_proprietario_id and
 b.doc_onere_id=a.doc_onere_id
and c.onere_id=b.onere_id
and d.onere_tipo_id=c.onere_tipo_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
 AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
 AND p_data BETWEEN b.validita_inizio AND COALESCE(b.validita_fine, p_data)
),
 causale as (SELECT
 dc.caus_id,
 dc.caus_code v_caus_code, dc.caus_desc v_caus_desc
  FROM siac.siac_d_causale dc
  WHERE  dc.ente_proprietario_id=p_ente_proprietario_id and  dc.data_cancellazione IS NULL)
 ,
 onatt as (
 -- Sezione per l'onere
  SELECT
  doa.onere_att_id,
  doa.onere_att_code v_onere_att_code, doa.onere_att_desc v_onere_att_desc
  FROM siac_d_onere_attivita doa
  WHERE --doa.onere_att_id = v_onere_att_id
  doa.ente_proprietario_id=p_ente_proprietario_id
    AND doa.data_cancellazione IS NULL)
select * from onere left join causale
on onere.caus_id= causale.caus_id
left join onatt
on onere.onere_att_id=onatt.onere_att_id),
liq as (select a.sord_id,
b.liq_anno v_liq_anno, b.liq_numero v_liq_numero, b.liq_desc v_liq_desc, b.liq_emissione_data v_liq_emissione_data,
         b.liq_importo v_liq_importo, b.liq_automatica v_liq_automatica, b.liq_convalida_manuale
 FROM siac_r_liquidazione_ord a, siac_t_liquidazione b
  WHERE a.liq_id = b.liq_id
  AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
  AND a.data_cancellazione IS NULL
  AND b.data_cancellazione IS NULL ),
 --04/07/2017: SIAC-5037 aggiunta gestione dei documenti
 elenco_doc as (
		select distinct d_doc_gruppo.doc_gruppo_tipo_code, d_doc_gruppo.doc_gruppo_tipo_desc,
    	d_doc_fam_tipo.doc_fam_tipo_code, d_doc_fam_tipo.doc_fam_tipo_desc,
        d_doc_tipo.doc_tipo_code, d_doc_tipo.doc_tipo_desc,
        t_doc.doc_numero, t_doc.doc_anno, t_subdoc.subdoc_numero,
        t_soggetto.soggetto_code,
        r_subdoc_ord_ts.ord_ts_id,
        t_doc.doc_id -- SIAC-5573
    from siac_t_doc t_doc
    		LEFT JOIN siac_r_doc_sog r_doc_sog
            	ON (r_doc_sog.doc_id=t_doc.doc_id
                	AND r_doc_sog.data_cancellazione IS NULL
                    AND p_data BETWEEN r_doc_sog.validita_inizio AND
                    	COALESCE(r_doc_sog.validita_fine, p_data))
            LEFT JOIN siac_t_soggetto t_soggetto
            	ON (t_soggetto.soggetto_id=r_doc_sog.soggetto_id
                	AND t_soggetto.data_cancellazione IS NULL),
		siac_t_subdoc t_subdoc,
    	siac_d_doc_tipo d_doc_tipo
        	LEFT JOIN siac_d_doc_gruppo d_doc_gruppo
            	ON (d_doc_gruppo.doc_gruppo_tipo_id=d_doc_tipo.doc_gruppo_tipo_id
                	AND d_doc_gruppo.data_cancellazione IS NULL),
    	siac_d_doc_fam_tipo d_doc_fam_tipo,
        siac_r_subdoc_ordinativo_ts r_subdoc_ord_ts
    where t_doc.doc_id=t_subdoc.doc_id
    	and d_doc_tipo.doc_tipo_id=t_doc.doc_tipo_id
        and d_doc_fam_tipo.doc_fam_tipo_id=d_doc_tipo.doc_fam_tipo_id
        and r_subdoc_ord_ts.subdoc_id=t_subdoc.subdoc_id
    	and t_doc.ente_proprietario_id=p_ente_proprietario_id
    	and t_doc.data_cancellazione IS NULL
   		and t_subdoc.data_cancellazione IS NULL
        AND d_doc_fam_tipo.data_cancellazione IS NULL
        and d_doc_tipo.data_cancellazione IS NULL
        and r_subdoc_ord_ts.data_cancellazione IS NULL
        and r_subdoc_ord_ts.validita_fine IS NULL
        AND p_data BETWEEN r_subdoc_ord_ts.validita_inizio AND
                    	COALESCE(r_subdoc_ord_ts.validita_fine, p_data))
select ord_pag.*,
cofog.codice_cofog_gruppo,
cofog.descrizione_cofog_gruppo,
cofog.codice_cofog_divisione,
cofog.descrizione_cofog_divisione,
pdc5.pdc5_codice_pdc_finanziario_V,pdc5.pdc5_descrizione_pdc_finanziario_V,
pdc5.pdc5_codice_pdc_finanziario_IV,pdc5.pdc5_descrizione_pdc_finanziario_IV,
pdc5.pdc5_codice_pdc_finanziario_III,pdc5.pdc5_descrizione_pdc_finanziario_III,
pdc5.pdc5_codice_pdc_finanziario_II,pdc5.pdc5_descrizione_pdc_finanziario_II,
pdc5.pdc5_codice_pdc_finanziario_I,pdc5.pdc5_descrizione_pdc_finanziario_I,
pdc4.pdc4_codice_pdc_finanziario_IV,pdc4.pdc4_descrizione_pdc_finanziario_IV,
pdc4.pdc4_codice_pdc_finanziario_III,pdc4.pdc4_descrizione_pdc_finanziario_III,
pdc4.pdc4_codice_pdc_finanziario_II,pdc4.pdc4_descrizione_pdc_finanziario_II,
pdc4.pdc4_codice_pdc_finanziario_I,pdc4.pdc4_descrizione_pdc_finanziario_I,
pce5.pce5_codice_pdc_economico_V,pce5.pce5_descrizione_pdc_economico_V,
pce5.pce5_codice_pdc_economico_IV,pce5.pce5_descrizione_pdc_economico_IV,
pce5.pce5_codice_pdc_economico_III,pce5.pce5_descrizione_pdc_economico_III,
pce5.pce5_codice_pdc_economico_II,pce5.pce5_descrizione_pdc_economico_II,
pce5.pce5_codice_pdc_economico_I,pce5.pce5_descrizione_pdc_economico_I,
pce4.pce4_codice_pdc_economico_IV,pce4.pce4_descrizione_pdc_economico_IV,
pce4.pce4_codice_pdc_economico_III,pce4.pce4_descrizione_pdc_economico_III,
pce4.pce4_codice_pdc_economico_II,pce4.pce4_descrizione_pdc_economico_II,
pce4.pce4_codice_pdc_economico_I,pce4.pce4_descrizione_pdc_economico_I,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagAllegatoCartaceo.v_flagAllegatoCartaceo,
t_noteordinativo.v_note_ordinativo,
t_cig.cig,
t_cup.cup,
impiniziale.importo_iniziale,
impattuale.importo_attuale,
firma.v_data_firma, firma.v_firma,
ons.*,liq.*, elenco_doc.*
from ord_pag
left join bollo
on ord_pag.codbollo_id=bollo.codbollo_id
left join contotes
on ord_pag.contotes_id=contotes.contotes_id
left join dist
on ord_pag.dist_id=dist.dist_id
left join commis
on ord_pag.comm_tipo_id=commis.comm_tipo_id
left join bilelem
on ord_pag.ord_id=bilelem.ord_id
left join modpag
on ord_pag.ord_id=modpag.ord_id
left join sogg
on ord_pag.ord_id=sogg.ord_id
left join tipoavviso
on ord_pag.ord_id=tipoavviso.ord_id
left join ricspesa
on ord_pag.ord_id=ricspesa.ord_id
left join transue
on ord_pag.ord_id=transue.ord_id
left join class21
on ord_pag.ord_id=class21.ord_id
left join class22
on ord_pag.ord_id=class22.ord_id
left join class23
on ord_pag.ord_id=class23.ord_id
left join class24
on ord_pag.ord_id=class24.ord_id
left join class25
on ord_pag.ord_id=class25.ord_id
left join cofog
on ord_pag.ord_id=cofog.ord_id
left join pdc5
on ord_pag.ord_id=pdc5.ord_id
left join pdc4
on ord_pag.ord_id=pdc4.ord_id
left join pce5
on ord_pag.ord_id=pce5.ord_id
left join pce4
on ord_pag.ord_id=pce4.ord_id
left join attoamm
on ord_pag.ord_id=attoamm.ord_id
left join t_flagAllegatoCartaceo
on ord_pag.ord_id=t_flagAllegatoCartaceo.ord_id
left join t_noteordinativo
on
ord_pag.ord_id=t_noteordinativo.ord_id
left join t_cig
on
ord_pag.ord_ts_id=t_cig.sord_id
left join t_cup
on
ord_pag.ord_ts_id=t_cup.sord_id
left join impiniziale
on ord_pag.ord_ts_id=impiniziale.ord_ts_id
left join impattuale
on ord_pag.ord_ts_id=impattuale.ord_ts_id
left join firma
on ord_pag.ord_id=firma.ord_id
left join ons
on ord_pag.ord_ts_id=ons.ord_ts_id
left join liq
on ord_pag.ord_ts_id=liq.sord_id
--04/07/2017: SIAC-5037 aggiunta gestione dei documenti
left join elenco_doc
on elenco_doc.ord_ts_id=ord_pag.ord_ts_id
) as tb;


esito:= 'Fine funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi in pagamento (FNC_SIAC_DWH_ORDINATIVO_PAGAMENTO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
	
ALTER TABLE siac_dwh_iva ADD COLUMN doc_id integer;	

CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_iva (
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE

rec_iva record;
rec_iva_mov record;
rec_subdoc record;

v_ente_proprietario_id INTEGER := null;
v_ente_denominazione VARCHAR := null;
v_subdociva_anno VARCHAR := null;
v_subdociva_numero INTEGER := null;
v_subdociva_data_registrazione TIMESTAMP := null;
v_subdociva_prot_prov VARCHAR := null;
v_subdociva_data_prot_prov TIMESTAMP := null;
v_subdociva_prot_def VARCHAR := null;
v_subdociva_data_prot_def TIMESTAMP := null;
v_doc_anno INTEGER := null;
v_doc_numero VARCHAR := null;
v_doc_tipo_code VARCHAR := null;
v_doc_data_emissione TIMESTAMP := null;
v_soggetto_code VARCHAR := null;
v_subdoc_numero INTEGER := null;
v_doc_fam_tipo_code VARCHAR := null;
v_doc_fam_tipo_desc VARCHAR := null;
v_reg_tipo_code VARCHAR := null;
v_reg_tipo_desc VARCHAR := null; 
v_ivareg_code VARCHAR := null; 
v_ivareg_desc VARCHAR := null; 
v_ivareg_tipo_code VARCHAR := null; 
v_ivareg_tipo_desc VARCHAR := null; 
v_ivaatt_code VARCHAR := null;
v_ivaatt_desc VARCHAR := null;
v_ivamov_imponibile NUMERIC := null;
v_ivamov_imposta NUMERIC := null;
v_ivamov_imp_detraibile NUMERIC(15,2) := null;
v_ivamov_imp_indetraibile NUMERIC(15,2) := null;
v_ivaaliquota_code VARCHAR := null; 
v_ivaaliquota_desc VARCHAR := null; 
v_ivaaliquota_perc NUMERIC := null; 
v_ivaaliquota_perc_indetr NUMERIC := null; 
v_ivaop_tipo_code VARCHAR := null; 
v_ivaop_tipo_desc VARCHAR := null; 
v_ivaaliquota_tipo_code VARCHAR := null;  
v_ivaaliquota_tipo_desc VARCHAR := null;              

v_doc_tipo_id INTEGER := null;
v_doc_id INTEGER := null;
v_subdociva_id INTEGER := null; 
v_ivaatt_id INTEGER := null; 
v_ivareg_id INTEGER := null; 
v_reg_tipo_id INTEGER := null;
v_ivaaliquota_id INTEGER := null;
v_ivaop_tipo_id INTEGER := null; 
v_ivaaliquota_tipo_id INTEGER := null;
v_dociva_r_id INTEGER := null; 

BEGIN

IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;

IF p_data IS NULL THEN
   p_data := now();
END IF;

esito:= 'Inizio funzione carico dati iva (FNC_SIAC_DWH_IVA) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_iva
WHERE ente_proprietario_id = p_ente_proprietario_id;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

FOR rec_iva IN
SELECT tep.ente_proprietario_id, tep.ente_denominazione,
       tsi.subdociva_anno, tsi.subdociva_numero, tsi.subdociva_data_registrazione,
       tsi.subdociva_prot_prov, tsi.subdociva_data_prot_prov,
       tsi.subdociva_prot_def, tsi.subdociva_data_prot_def,
       tsi.subdociva_id,
       tsi.ivaatt_id,
       tsi.ivareg_id,
       tsi.reg_tipo_id,
       tsi.dociva_r_id
FROM   siac_t_subdoc_iva tsi, siac_t_ente_proprietario tep
WHERE  tep.ente_proprietario_id = p_ente_proprietario_id
AND    tep.ente_proprietario_id = tsi.ente_proprietario_id
AND    p_data BETWEEN tep.validita_inizio AND COALESCE(tep.validita_fine, p_data)
AND    tep.data_cancellazione IS NULL
AND    p_data BETWEEN tsi.validita_inizio AND COALESCE(tsi.validita_fine, p_data)
AND    tsi.data_cancellazione IS NULL

LOOP

  v_ente_proprietario_id := null;
  v_ente_denominazione := null;
  v_subdociva_anno := null;
  v_subdociva_numero := null;
  v_subdociva_data_registrazione := null;
  v_subdociva_prot_prov := null;
  v_subdociva_data_prot_prov := null;
  v_subdociva_prot_def := null;
  v_subdociva_data_prot_def := null;
  v_subdociva_id := null;
  v_ivaatt_id := null;
  v_ivareg_id := null;
  v_reg_tipo_id := null;
  v_dociva_r_id := null;

  v_ente_proprietario_id := rec_iva.ente_proprietario_id;
  v_ente_denominazione := rec_iva.ente_denominazione;
  v_subdociva_anno := rec_iva.subdociva_anno;
  v_subdociva_numero := rec_iva.subdociva_numero;
  v_subdociva_data_registrazione := rec_iva.subdociva_data_registrazione;
  v_subdociva_prot_prov := rec_iva.subdociva_prot_prov;
  v_subdociva_data_prot_prov := rec_iva.subdociva_data_prot_prov;
  v_subdociva_prot_def := rec_iva.subdociva_prot_def;
  v_subdociva_data_prot_def := rec_iva.subdociva_data_prot_def;
  v_subdociva_id := rec_iva.subdociva_id;
  v_ivaatt_id := rec_iva.ivaatt_id;
  v_ivareg_id := rec_iva.ivareg_id;
  v_reg_tipo_id := rec_iva.reg_tipo_id;
  v_dociva_r_id := rec_iva.dociva_r_id;

  v_reg_tipo_code := null; 
  v_reg_tipo_desc := null;

  SELECT dirt.reg_tipo_code, dirt.reg_tipo_desc
  INTO   v_reg_tipo_code, v_reg_tipo_desc
  FROM   siac_d_iva_registrazione_tipo dirt
  WHERE  dirt.reg_tipo_id = v_reg_tipo_id
  AND    dirt.data_cancellazione IS NULL
  AND    p_data BETWEEN dirt.validita_inizio AND COALESCE(dirt.validita_fine, p_data);

  v_ivareg_code := null;
  v_ivareg_desc := null;
  v_ivareg_tipo_code := null;
  v_ivareg_tipo_desc := null;

  SELECT tir.ivareg_code, tir.ivareg_desc, sdirt.ivareg_tipo_code, sdirt.ivareg_tipo_desc
  INTO  v_ivareg_code, v_ivareg_desc, v_ivareg_tipo_code, v_ivareg_tipo_desc
  FROM  siac_t_iva_registro tir, siac_d_iva_registro_tipo sdirt
  WHERE tir.ivareg_id = v_ivareg_id
  AND   tir.ivareg_tipo_id = sdirt.ivareg_tipo_id
  AND   tir.data_cancellazione IS NULL
  AND   sdirt.data_cancellazione IS NULL
  AND   p_data BETWEEN tir.validita_inizio AND COALESCE(tir.validita_fine, p_data)
  AND   p_data BETWEEN sdirt.validita_inizio AND COALESCE(sdirt.validita_fine, p_data);

  v_ivaatt_code := null;
  v_ivaatt_desc := null;

  SELECT tia.ivaatt_code, tia.ivaatt_desc
  INTO  v_ivaatt_code, v_ivaatt_desc
  FROM  siac_t_iva_attivita tia
  WHERE tia.ivaatt_id = v_ivaatt_id
  AND   tia.data_cancellazione IS NULL
  AND   p_data BETWEEN tia.validita_inizio AND COALESCE(tia.validita_fine, p_data);

  FOR rec_subdoc IN
  SELECT td.doc_anno, td.doc_numero, td.doc_data_emissione, 
         ts.subdoc_numero,
         td.doc_tipo_id, td.doc_id
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_subdoc_subdoc_iva rssi, siac_t_doc td, siac_t_subdoc ts
  WHERE  rssi.subdociva_id = v_subdociva_id
  AND    td.ente_proprietario_id = p_ente_proprietario_id
  AND    rssi.subdoc_id = ts.subdoc_id
  AND    ts.doc_id = td.doc_id
  AND    rssi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  AND    p_data BETWEEN rssi.validita_inizio AND COALESCE(rssi.validita_fine, p_data)
  AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    v_dociva_r_id IS NULL
  UNION 
  SELECT td.doc_anno, td.doc_numero, td.doc_data_emissione, 
         ts.subdoc_numero,
         td.doc_tipo_id, td.doc_id
  /*INTO   v_doc_anno, v_doc_numero, v_doc_data_emissione,
         v_subdoc_numero,
         v_doc_tipo_id, v_doc_id*/
  FROM   siac_r_doc_iva rdi, siac_t_doc td, siac_t_subdoc ts
  WHERE  rdi.dociva_r_id = v_dociva_r_id
  AND    td.ente_proprietario_id = p_ente_proprietario_id
  AND    rdi.doc_id = td.doc_id
  AND    ts.doc_id = td.doc_id
  AND    rdi.data_cancellazione IS NULL
  AND    ts.data_cancellazione IS NULL
  AND    td.data_cancellazione IS NULL
  AND    p_data BETWEEN rdi.validita_inizio AND COALESCE(rdi.validita_fine, p_data)
  AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data)
  AND    p_data BETWEEN td.validita_inizio AND COALESCE(td.validita_fine, p_data)
  AND    v_dociva_r_id IS NOT NULL
		
    LOOP
    	
      v_doc_anno := null;
      v_doc_numero := null;
      v_doc_data_emissione := null;
      v_subdoc_numero := null;
      v_doc_tipo_id := null;
      v_doc_id := null;
      
      v_doc_anno := rec_subdoc.doc_anno;
      v_doc_numero := rec_subdoc.doc_numero;
      v_doc_data_emissione := rec_subdoc.doc_data_emissione;
      v_subdoc_numero := rec_subdoc.subdoc_numero;
      v_doc_tipo_id := rec_subdoc.doc_tipo_id;
      v_doc_id := rec_subdoc.doc_id;

      v_doc_tipo_code := null;
      v_doc_fam_tipo_code := null;
      v_doc_fam_tipo_desc := null;

      SELECT ddt.doc_tipo_code, ddft.doc_fam_tipo_code, ddft.doc_fam_tipo_desc
      INTO   v_doc_tipo_code, v_doc_fam_tipo_code, v_doc_fam_tipo_desc
      FROM   siac_d_doc_tipo ddt, siac_d_doc_fam_tipo ddft
      WHERE  ddt.doc_tipo_id = v_doc_tipo_id
      AND    ddt.doc_fam_tipo_id = ddft.doc_fam_tipo_id
      AND    ddt.data_cancellazione IS NULL
      AND    ddft.data_cancellazione IS NULL
      AND    p_data BETWEEN ddt.validita_inizio AND COALESCE(ddt.validita_fine, p_data)
      AND    p_data BETWEEN ddft.validita_inizio AND COALESCE(ddft.validita_fine, p_data);

      v_soggetto_code := null;

      SELECT ts.soggetto_code
      INTO   v_soggetto_code
      FROM   siac_r_doc_sog srds, siac_t_soggetto ts
      WHERE  srds.doc_id = v_doc_id
      AND    srds.soggetto_id = ts.soggetto_id
      AND    srds.data_cancellazione IS NULL
      AND    ts.data_cancellazione IS NULL
      AND    p_data BETWEEN srds.validita_inizio AND COALESCE(srds.validita_fine, p_data)
      AND    p_data BETWEEN ts.validita_inizio AND COALESCE(ts.validita_fine, p_data);

      
      FOR    rec_iva_mov IN
      SELECT ti.ivamov_imponibile, ti.ivamov_imposta,
             ti.ivaaliquota_id
      FROM   siac_r_ivamov ri, siac_t_ivamov ti
      WHERE  ri.subdociva_id = v_subdociva_id
      AND    ri.ivamov_id = ti.ivamov_id
      AND    ri.data_cancellazione IS NULL
      AND    ti.data_cancellazione IS NULL
      AND    p_data BETWEEN ri.validita_inizio AND COALESCE(ri.validita_fine, p_data)
      AND    p_data BETWEEN ti.validita_inizio AND COALESCE(ti.validita_fine, p_data)
		
        LOOP
          
          v_ivaaliquota_id := null;
          v_ivamov_imponibile := null;
          v_ivamov_imposta := null;
          v_ivamov_imp_detraibile := null;
          v_ivamov_imp_indetraibile := null;

          v_ivamov_imponibile := rec_iva_mov.ivamov_imponibile;
          v_ivamov_imposta := rec_iva_mov.ivamov_imposta;
          v_ivaaliquota_id := rec_iva_mov.ivaaliquota_id;
          
          v_ivaaliquota_code := null; 
          v_ivaaliquota_desc := null; 
          v_ivaaliquota_perc := null; 
          v_ivaaliquota_perc_indetr := null;
          v_ivaop_tipo_id := null; 
          v_ivaaliquota_tipo_id := null;

          SELECT  tia.ivaaliquota_code, tia.ivaaliquota_desc, tia.ivaaliquota_perc, tia.ivaaliquota_perc_indetr,
                  tia.ivaop_tipo_id, tia.ivaaliquota_tipo_id
          INTO    v_ivaaliquota_code, v_ivaaliquota_desc, v_ivaaliquota_perc, v_ivaaliquota_perc_indetr, 
                  v_ivaop_tipo_id, v_ivaaliquota_tipo_id
          FROM    siac_t_iva_aliquota tia
          WHERE   tia.ivaaliquota_id = v_ivaaliquota_id
          AND     tia.data_cancellazione IS NULL;
          --AND     p_data BETWEEN tia.validita_inizio AND COALESCE(tia.validita_fine, p_data);
          
          v_ivamov_imp_indetraibile := (coalesce(v_ivamov_imposta,0)/100)*coalesce(v_ivaaliquota_perc_indetr,0);
          v_ivamov_imp_detraibile := coalesce(v_ivamov_imposta,0) - v_ivamov_imp_indetraibile;
          
          v_ivaop_tipo_code := null;
          v_ivaop_tipo_desc := null;
          
          SELECT   diot.ivaop_tipo_code, diot.ivaop_tipo_desc
          INTO     v_ivaop_tipo_code, v_ivaop_tipo_desc
          FROM     siac_d_iva_operazione_tipo diot       
          WHERE    diot.ivaop_tipo_id = v_ivaop_tipo_id
          AND      diot.data_cancellazione IS NULL;
          --AND      p_data BETWEEN diot.validita_inizio AND COALESCE(diot.validita_fine, p_data);
          
          v_ivaaliquota_tipo_code := null; 
          v_ivaaliquota_tipo_desc := null;
          
          SELECT   diat.ivaaliquota_tipo_code, diat.ivaaliquota_tipo_desc
          INTO     v_ivaaliquota_tipo_code, v_ivaaliquota_tipo_desc
          FROM     siac_d_iva_aliquota_tipo diat
          WHERE    diat.ivaaliquota_tipo_id = v_ivaaliquota_tipo_id
          AND      diat.data_cancellazione IS NULL;
          --AND      p_data BETWEEN diat.validita_inizio AND COALESCE(diat.validita_fine, p_data);  
          
          INSERT INTO siac.siac_dwh_iva
          ( ente_proprietario_id,
            ente_denominazione,
            cod_doc_fam_tipo,
            desc_doc_fam_tipo,
            anno_doc,
            num_doc,
            cod_tipo_doc,
            data_emissione_doc,
            cod_sogg_doc, 
            num_subdoc, 
            anno_subbdoc_iva, 
            num_subdoc_iva,
            data_registrazione_subdoc_iva,
            cod_tipo_registrazione,
            desc_tipo_registrazione,
            cod_tipo_registro_iva,
            desc_tipo_registro_iva,
            cod_registro_iva,
            desc_registro_iva,
            cod_attivita,
            desc_attivita, 
            prot_prov_subdoc_iva,
            data_prot_prov_subdoc_iva,
            prot_def_subdoc_iva,
            data_prot_def_subdoc_iva,
            cod_aliquota_iva,
            desc_aliquota_iva,
            perc_aliquota_iva,
            perc_indetr_aliquota_iva,
            imponibile,
            imposta,
            importo_detraibile,
            importo_indetraibile,
            cod_tipo_oprazione,
            desc_tipo_oprazione,
            cod_tipo_aliquota,
            desc_tipo_aliquota,
            doc_id -- SIAC-5573
          )
          VALUES (v_ente_proprietario_id,
                  v_ente_denominazione,
                  v_doc_fam_tipo_code, 
                  v_doc_fam_tipo_desc,
                  v_doc_anno, 
                  v_doc_numero, 
                  v_doc_tipo_code,
                  v_doc_data_emissione,
                  v_soggetto_code,
                  v_subdoc_numero,
                  v_subdociva_anno,
                  v_subdociva_numero,
                  v_subdociva_data_registrazione,
                  v_reg_tipo_code,
                  v_reg_tipo_desc,
                  v_ivareg_tipo_code,
                  v_ivareg_tipo_desc,
                  v_ivareg_code, 
                  v_ivareg_desc,
                  v_ivaatt_code, 
                  v_ivaatt_desc, 
                  v_subdociva_prot_prov,
                  v_subdociva_data_prot_prov,
                  v_subdociva_prot_def,
                  v_subdociva_data_prot_def,
                  v_ivaaliquota_code, 
                  v_ivaaliquota_desc, 
                  v_ivaaliquota_perc, 
                  v_ivaaliquota_perc_indetr,
                  v_ivamov_imponibile,
                  v_ivamov_imposta,
                  v_ivamov_imp_detraibile,
                  v_ivamov_imp_indetraibile,
                  v_ivaop_tipo_code,
                  v_ivaop_tipo_desc,
                  v_ivaaliquota_tipo_code, 
                  v_ivaaliquota_tipo_desc,
                  v_doc_id -- SIAC-5573
                 );
          END LOOP;
	END LOOP;	    
END LOOP;
esito:= 'Fine funzione carico iva (FNC_SIAC_DWH_IVA) - '||clock_timestamp();
RETURN NEXT;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico iva (FNC_SIAC_DWH_IVA) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;	
-- SIAC-5573 FINE
-- SIAC-5765 pto 18 D)
CREATE OR REPLACE FUNCTION fnc_mif_flusso_elaborato_giornalecassa
( enteProprietarioId integer,
  annoBilancio integer,
  nomeEnte VARCHAR,
  tipoFlussoMif varchar,
  flussoElabMifId integer,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out codiceRisultato integer,
  out messaggioRisultato varchar,
  out countOrdAggRisultato numeric )
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    ELAB_MIF_ESITO_IN       CONSTANT  varchar :='IN';

	-- costante tipo flusso presenti nella mif_d_flusso_elaborato_tipo
    -- valori di parametro tipoFlussoMif devono essere presenti in mif_d_flusso_elaborato_tipo
    GIOCASSA_ELAB_FLUSSO_TIPO    CONSTANT  varchar :='GIOCASSA';    -- giornale di cassa

    -- costante tipo flusso presenti nei flussi e in siac_d_ricevuta_tipo
    QUIET_MIF_FLUSSO_TIPO   CONSTANT  varchar :='R';    -- quietanze e storni
    FIRME_MIF_FLUSSO_TIPO   CONSTANT  varchar :='S';    -- firme
    PROVC_MIF_FLUSSO_TIPO   CONSTANT  varchar :='P';    -- provvisori

    -- costante tipo ricevuta presente in siac_d_ricevuta_tipo
    QUIET_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='Q';    -- quietanze
    STORNI_MIF_FLUSSO_TIPO_CODE  CONSTANT  varchar :='S';    -- storni
    PROVC_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='P';    -- provvisori
    PROVC_ST_MIF_FLUSSO_TIPO_CODE   CONSTANT  varchar :='PS';    -- storno provvisori



    MIF_FLUSSO_QU_COD_ERR       CONSTANT varchar:='5'; -- tipo flusso quietanza
    MIF_FLUSSO_FI_COD_ERR       CONSTANT varchar:='6'; -- tipo flusso firme
    MIF_FLUSSO_PC_COD_ERR       CONSTANT varchar:='7'; -- tipo flusso provvisori cassa
    MIF_FLUSSO_QU_C_COD_ERR       CONSTANT varchar:='8'; -- tipo flusso quietanza
    MIF_FLUSSO_FI_C_COD_ERR       CONSTANT varchar:='9'; -- tipo flusso firme
    MIF_FLUSSO_PC_C_COD_ERR       CONSTANT varchar:='10'; -- tipo flusso provvisori cassa

    MIF_DT_ORA_TESTA_COD_ERR    CONSTANT varchar:='11';  -- data ora flusso non presente in testata
    MIF_RICEVUTE_TESTA_COD_ERR  CONSTANT varchar:='12'; -- numero ricevute non prensente in testata
    MIF_DATI_ENTE_TESTA_COD_ERR CONSTANT varchar:='13'; -- dati enteOil non prensente in testata o non validi
    MIF_DT_ORA_CODA_COD_ERR    CONSTANT varchar:='14';  -- data ora flusso non presente in coda
    MIF_RICEVUTE_CODA_COD_ERR  CONSTANT varchar:='15'; -- numero ricevute non prensente in coda
    MIF_DATI_ENTE_CODA_COD_ERR CONSTANT varchar:='16'; -- dati enteOil non prensente in coda o non validi

    MIF_RR_NO_DR_COD_ERR CONSTANT varchar:='17'; -- record RR senza DR
    MIF_DR_NO_RR_COD_ERR CONSTANT varchar:='18'; -- record DR senza RR

	MIF_RR_NO_TIPO_REC_COD_ERR CONSTANT varchar:='19'; -- tipo record non valorizzato
    MIF_DR_NO_TIPO_REC_COD_ERR CONSTANT varchar:='20'; -- tipo record non valorizzato

    -- scarti record rr
	MIF_RR_PROGR_RIC_COD_ERR CONSTANT varchar:='21'; -- progressivo ricevuta non valorizzato
	MIF_RR_DATA_MSG_COD_ERR  CONSTANT varchar:='22'; -- data ora messaggio ricevuta non valorizzato
    MIF_RR_ESITO_DER_COD_ERR CONSTANT varchar:='23'; -- esito derivato non valorizzato o non ammesso per ricevuta
	MIF_RR_DATI_ENTE_COD_ERR CONSTANT varchar:='24'; -- dati ente non valorizzati o errati
    MIF_RR_ESITO_NEG_COD_ERR CONSTANT varchar:='25'; -- codice_esito non valorizzato o non positivo
    MIF_RR_COD_FUNZIONE_COD_ERR CONSTANT varchar:='26'; -- codice_funzione non valorizzato o non ammesso
    MIF_RR_QUALIFICATORE_COD_ERR CONSTANT varchar:='27'; -- qualificatore non valorizzato o non ammesso
    MIF_RR_DATI_ORD_COD_ERR CONSTANT varchar:='28';  -- dati ordinativo non indicati ( anno_esercizio, numero_ordinativo, data_pagamento)
    MIF_RR_ANNO_ORD_COD_ERR CONSTANT varchar:='29';  -- anno ordinativo non corretto ( anno_esercizio>annoBilancio)
    MIF_RR_ORD_COD_ERR CONSTANT varchar:='30'; -- ordinativo non esistente
	MIF_RR_ORD_ANNULL_COD_ERR CONSTANT varchar:='31'; -- ordinativo annullato
	MIF_RR_ORD_DT_EMIS_COD_ERR CONSTANT varchar:='32'; -- ordinativo data_emissione successiva alla data di quietanza/firma
    MIF_RR_ORD_DT_TRASM_COD_ERR CONSTANT varchar:='33'; -- ordinativo data_trasmisisione non valorizzata o successiva alla data di quietanza
	MIF_RR_ORD_DT_FIRMA_COD_ERR CONSTANT varchar:='34'; -- ordinativo data_firma non valorizzata o successiva alla data di quietanza

	-- scarto di dettaglio
    MIF_DR_ORD_PROGR_RIC_COD_ERR CONSTANT varchar:='35'; -- esistenza di ricevute con record DR con progressivo_ricevuta non valorizzato
    MIF_DR_ORD_NUM_RIC_COD_ERR CONSTANT   varchar:='36'; -- esistenza di ricevute con record DR con numero_ricevuta non valorizzato
	MIF_DR_ORD_IMPORTO_RIC_COD_ERR CONSTANT   varchar:='37'; -- esistenza di ricevute con record DR con importo_ricevuta non valorizzato o non valido

    MIF_DR_ORD_IMP_NEG_RIC_COD_ERR CONSTANT   varchar:='38'; -- totale ricevuta in DR negativo
	MIF_DR_ORD_NUM_ERR_RIC_COD_ERR CONSTANT   varchar:='39'; -- lettura numero ricevuta ultimo in DR non riuscita
    MIF_DR_ORD_IMP_ORD_Z_COD_ERR   CONSTANT    varchar:='40';  -- lettura importo ordinativo in ciclo di elaborazione non riuscita
    MIF_DR_ORD_NON_QUIET_COD_ERR   CONSTANT    varchar:='41';  -- verifica esistenza quietanza in ciclo di elaborazione per ord in fase di storno non riuscita
    MIF_DR_ORD_IMP_QUIET_ERR_COD_ERR CONSTANT  varchar:='42';  -- importo quietanzato totale > importo ordinativo
    MIF_DR_ORD_IMP_QUIET_NEG_COD_ERR CONSTANT  varchar:='43';  -- importo quietanzato totale < 0
 	MIF_DR_ORD_STATO_ORD_ERR_COD_ERR CONSTANT  varchar:='44';  -- stato attuale ordinativo non congruente con operazione ricevuta

	MIF_RR_DATI_FIRMA_COD_ERR CONSTANT  varchar:='45';   -- dati firma non indicati
    MIF_RR_ORD_FIRMATO_COD_ERR CONSTANT  varchar:='46';  -- ordinativo firmato
    MIF_RR_ORD_QUIET_COD_ERR CONSTANT  varchar:='47';    -- ordinativo quietanzato in data antecedente alla data di firma
    MIF_RR_ORD_NO_FIRMA_COD_ERR CONSTANT  varchar:='48'; -- ordinativo non firmato
    MIF_RR_ORD_FIRMA_QU_COD_ERR CONSTANT  varchar:='49'; -- ordinativo quietanzato


	MIF_RR_PC_CASSA_COD_ERR CONSTANT varchar:='50';       -- dati provvisorio di cassa non indicati ( anno_esercizio, numero_ordinativo, data_ordinativo, importo_ordinativo)
    MIF_RR_PC_CASSA_ANNO_COD_ERR CONSTANT varchar:='51';  -- anno provvisorio non corretto ( anno_esercizio>annoBilancio)
    MIF_RR_PC_CASSA_DT_COD_ERR  CONSTANT varchar:='52';   --  data provvisorio non corretto ( data_ordinativo>dataElaborazione)
	MIF_RR_PC_CASSA_IMP_COD_ERR  CONSTANT varchar:='53';  --  importo provvisorio non corretto ( importo_ordinativo<=0)
	MIF_RR_PROVC_S_COD_ERR CONSTANT varchar:='54';        --  provvisorio di cassa non esistente per ricevuta di storno
	MIF_RR_PROVC_S_REG_COD_ERR CONSTANT varchar:='55';    --  provvisorio di cassa esistente per ricevuta di storno , collegato a ordinativo
	MIF_RR_PROVC_S_IMP_COD_ERR CONSTANT varchar:='56';    --  provvisorio di cassa esistente per ricevuta di storno , importo storno != importo provvisorio
    MIF_RR_PROVC_S_SOG_COD_ERR  CONSTANT varchar:='57';    --  provvisorio di cassa esistente per ricevuta di storno , soggetto storno != soggetto provvisorio
    MIF_RR_PROVC_S_STO_COD_ERR  CONSTANT varchar:='58';    --  provvisorio di cassa esistente per ricevuta di storno , provvisorio stornato data_annullamento valorizzata
	MIF_RR_PROVC_ESISTE_COD_ERR  CONSTANT varchar:='59';   --  provvisorio di cassa esistente per ricevuta di inserimento , provvisorio esistente


	flussoMifTipoId integer:=null;
    tipoFlusso VARCHAR(200):=null;
    dataOraFlusso VARCHAR(200):=null;
    codiceAbiBt VARCHAR(200):=null;
    codiceEnteBt VARCHAR(200):=null;

    oilRicevutaTipoId integer:=null;

    enteOilRec record;
    ricevutaRec record;
	recQuiet record;
  	recProv record;

    codResult integer :=null;
    codErrore varchar(10) :=null;


	countOrdAgg numeric:=0;
  	countProvAgg numeric:=0;
BEGIN

	strMessaggioFinale:='Elaborazione flusso giornale di cassa tipo flusso='||tipoFlussoMif||'.Identificativo flusso='||flussoElabMifId||'.';

    codiceRisultato:=0;
    countOrdAggRisultato:=0;
    messaggioRisultato:='';

	strMessaggio:='Lettura identificativo tipo flusso.';
    select tipo.flusso_elab_mif_tipo_id into  flussoMifTipoId
    from mif_d_flusso_elaborato_tipo tipo
    where tipo.flusso_elab_mif_tipo_code=tipoFlussoMif
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    and   tipoFlussoMif=GIOCASSA_ELAB_FLUSSO_TIPO;

    if flussoMifTipoId is null then
    	raise exception ' Dato non reperito.';
    end if;


    strMessaggio:='Verifica esistenza identificativo flusso passato [mif_t_flusso_elaborato].';
    select distinct 1 into codResult
    from mif_t_flusso_elaborato mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   mif.data_cancellazione is null
    and   mif.validita_fine is null
    and   mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN;

    if codResult is null then
    	raise exception ' Dato non reperito.';
    end if;


    -- verifica  elaborazioni diverse da quella passata non completata
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_flusso_elaborato].';
    select distinct 1 into codResult
    from mif_t_flusso_elaborato mif
    where mif.flusso_elab_mif_id!=flussoElabMifId
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   mif.data_cancellazione is null
    and   mif.validita_fine is null
    and   mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN;

    if codResult is not null then
    	raise exception ' Elaborazioni presenti-verificare.';
    end if;

    -- verifca esistenza mif_t_oil_ricevuta ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_oil_ricevuta].';
    select distinct 1  into codResult
    from mif_t_oil_ricevuta m, mif_t_flusso_elaborato mif
    where m.ente_proprietario_id=enteProprietarioId
    and   mif.flusso_elab_mif_id=m.flusso_elab_mif_id
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   m.data_cancellazione is null
    and   m.validita_fine is null
    and   mif.data_cancellazione is null
    and   mif.validita_fine is NULL;

    if codResult is not null then
    	raise exception ' Elaborazioni presenti-verificare.';
    end if;


	-- verifca esistenza mif_t_elab_giornalecassa ( deve essere sempre vuota )
    strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_elab_giornalecassa].';
    select distinct 1  into codResult
    from  mif_t_elab_giornalecassa m, mif_t_flusso_elaborato mif
    where m.ente_proprietario_id=enteProprietarioId
    and   mif.flusso_elab_mif_id=m.flusso_elab_mif_id
    and   mif.flusso_elab_mif_tipo_id=flussoMifTipoId
    and   m.data_cancellazione is null
    and   m.validita_fine is null
    and   mif.data_cancellazione is null
    and   mif.validita_fine is NULL;

    if codResult is not null then
    	raise exception ' Elaborazioni presenti-verificare.';
    end if;



	-- verifca esistenza mif_t_giornalecassa
    strMessaggio:='Verifica esistenza record da elaborare [mif_t_giornalecassa].';
    select distinct 1  into codResult
    from  mif_t_giornalecassa m
    where m.flusso_elab_mif_id=flussoElabMifId
    and   m.ente_proprietario_id=enteProprietarioId;

    if codResult is null then
        -- SIAC-5765 pto 18.D)
        -- chiudere elaborazione
        -- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
        strMessaggio:='Elaborazione flusso giornale di cassa.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId
                      ||'.Nessun record da elaborare.';
        update  mif_t_flusso_elaborato
        set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,flusso_elab_mif_num_ord_elab,validita_fine)=
            ('OK',
             'ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '
             ||GIOCASSA_ELAB_FLUSSO_TIPO
             ||'. NESSUN RECORD DA ELABORARE.',
             countOrdAgg+countProvAgg,clock_timestamp())
        where flusso_elab_mif_id=flussoElabMifId;

    --    messaggioRisultato:=strMessaggioFinale||' Elaborazione conclusa OK.';
        messaggioRisultato:=strMessaggio;
        messaggioRisultato:=upper(messaggioRisultato);
        countOrdAggRisultato:=countOrdAgg+countProvAgg;

        return;
--    	raise exception ' Nessun record da elaborare.';
    end if;

    -- inserimento mif_t_elab_giornalecassa
    strMessaggio:='Inserimento record da elaborare [mif_t_elab_giornalecassa da mif_t_giornalecassa].';
    insert into mif_t_elab_giornalecassa
    (
     mif_t_giornalecassa_id,
	 flusso_elab_mif_id,
	 codice_abi_bt,
	 identificativo_flusso,
	 data_ora_creazione_flusso,
	 data_inizio_periodo_riferimento,
	 data_fine_periodo_riferimento,
	 codice_ente,
	 descrizione_ente,
	 codice_ente_bt,
	 esercizio,
	 conto_evidenza,
	 descrizione_conto_evidenza,
	 tipo_movimento,
	 tipo_documento,
	 tipo_operazione,
	 numero_documento,
	 progressivo_documento,
	 importo,
	 numero_bolletta_quietanza,
	 numero_bolletta_quietanza_storno,
	 data_movimento,
	 data_valuta_ente,
	 tipo_esecuzione,
	 coordinate,
	 codice_riferimento_operazione,
	 codice_riferimento_interno,
	 tipo_contabilita,
	 destinazione,
	 assoggettamento_bollo,
	 importo_bollo,
	 assoggettamento_spese,
	 importo_spese,
	 anagrafica_cliente,
	 indirizzo_cliente,
	 cap_cliente,
	 localita_cliente,
	 codice_fiscale_cliente,
	 provincia_cliente,
	 partita_iva_cliente,
	 anagrafica_delegato,
	 indirizzo_delegato,
	 cap_delegato,
	 localita_delegato,
	 provincia_delegato,
	 codice_fiscale_delegato,
	 causale,
	 numero_sospeso,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    (select
     mif.mif_t_giornalecassa_id,
	 mif.flusso_elab_mif_id,
	 mif.codice_abi_bt,
	 mif.identificativo_flusso,
	 mif.data_ora_creazione_flusso,
	 mif.data_inizio_periodo_riferimento,
	 mif.data_fine_periodo_riferimento,
	 mif.codice_ente,
	 mif.descrizione_ente,
	 mif.codice_ente_bt,
	 mif.esercizio,
	 mif.conto_evidenza,
	 mif.descrizione_conto_evidenza,
	 mif.tipo_movimento,
	 mif.tipo_documento,
	 mif.tipo_operazione,
	 mif.numero_documento,
	 mif.progressivo_documento,
	 abs(mif.importo::numeric),
	 mif.numero_bolletta_quietanza,
	 mif.numero_bolletta_quietanza_storno,
	 mif.data_movimento,
	 mif.data_valuta_ente,
	 mif.tipo_esecuzione,
	 mif.coordinate,
	 mif.codice_riferimento_operazione,
	 mif.codice_riferimento_interno,
	 mif.tipo_contabilita,
	 mif.destinazione,
	 mif.assoggettamento_bollo,
	 abs(mif.importo_bollo::numeric),
	 mif.assoggettamento_spese,
	 abs(mif.importo_spese::numeric),
	 mif.anagrafica_cliente,
	 mif.indirizzo_cliente,
	 mif.cap_cliente,
	 mif.localita_cliente,
	 mif.codice_fiscale_cliente,
	 mif.provincia_cliente,
	 mif.partita_iva_cliente,
	 mif.anagrafica_delegato,
	 mif.indirizzo_delegato,
	 mif.cap_delegato,
	 mif.localita_delegato,
	 mif.provincia_delegato,
	 mif.codice_fiscale_delegato,
	 mif.causale,
	 mif.numero_sospeso,
     clock_timestamp(),
     loginOperazione,
     enteProprietarioId
     from mif_t_giornalecassa mif
     where mif.flusso_elab_mif_id=flussoElabMifId
     and   mif.ente_proprietario_id=enteProprietarioId
    );


	-- letture enteOIL
    strMessaggio:='Lettura dati ente OIL.';
    select * into strict enteOilRec
    from siac_t_ente_oil
    where ente_proprietario_id=enteProprietarioId;
    codiceAbiBt:=enteOilRec.ente_oil_abi;
    codiceEnteBt:=enteOilRec.ente_oil_codice;

	-- lettura tipoRicevuta
    strMessaggio:='Lettura tipo ricevuta '||QUIET_MIF_FLUSSO_TIPO_CODE||'.';
	select tipo.oil_ricevuta_tipo_id
           into strict oilRicevutaTipoId
    from siac_d_oil_ricevuta_tipo tipo
    where tipo.oil_ricevuta_tipo_code=QUIET_MIF_FLUSSO_TIPO_CODE
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;




	-- controlli di integrita flusso

	strMessaggio:='Verifica integrita'' flusso. Codifiche ente.';
    codResult:=null;
    select mif.mif_t_giornalecassa_id into codResult
    from mif_t_elab_giornalecassa  mif
    where mif.flusso_elab_mif_id=flussoElabMifId
    and   mif.codice_abi_bt=codiceAbiBt
    and   mif.codice_ente_bt=codiceEnteBt
    limit 1;

    if codResult is null then
		codErrore:=MIF_DATI_ENTE_TESTA_COD_ERR;
    end if;

	if codErrore is not null then
	    raise exception ' COD.ERRORE=%',codErrore;
    end if;




    -- inserimento in mif_t_ricevuta_oil scarti

    -- MIF_RR_DATI_ENTE_COD_ERR dati ente  non valorizzati o errati
    strMessaggio:='Verifica esistenza record ricevuta  dati ente non valorizzati o errati.';
    insert into mif_t_oil_ricevuta
    ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
      oil_ricevuta_anno,oil_ricevuta_numero,
      oil_ricevuta_data,oil_ricevuta_tipo,
      oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
      validita_inizio,
      login_operazione,
      ente_proprietario_id
    )
    (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.mif_t_giornalecassa_id,
            rr.esercizio,rr.numero_bolletta_quietanza,
            rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
            rr.importo,rr.esercizio,rr.numero_documento,
            clock_timestamp(),loginOperazione,enteProprietarioId
     from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore
     where rr.flusso_elab_mif_id=flussoElabMifId
     and   ( rr.codice_abi_bt is null or rr.codice_abi_bt='' or rr.codice_abi_bt!=codiceAbiBt or
             rr.codice_ente_bt is null or rr.codice_ente_bt='' or rr.codice_ente_bt!=codiceEnteBt)
     and errore.oil_ricevuta_errore_code=MIF_RR_DATI_ENTE_COD_ERR::varchar
     and errore.ente_proprietario_id=enteProprietarioId
     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));


     -- tipo_movimento +
     -- tipo_documento+tipo_operazione => QUALIFICATORE
     --- da qualificatore trovo esito derivato
     -- quindi tipo_movimento, tipo_documento, tipo_operazione devono essere valorizzati

     -- MIF_RR_QUALIFICATORE_COD_ERR qualificatore non valorizzato
     strMessaggio:='Verifica esistenza record ricevuta dati qualificatore non valorizzati.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,rr.numero_bolletta_quietanza,
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             rr.importo,rr.esercizio,rr.numero_documento,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.tipo_movimento is null or rr.tipo_movimento=''    -- tipo_movimento ENTRATA-USCITA
          or rr.tipo_documento is null or rr.tipo_documento=''    -- tipo_documento MANDATO-REVERSALE-SOSPESO USCITA-SOSPESO ENTRATA
          or rr.tipo_operazione is null or rr.tipo_operazione='') -- tipo_operazione ESEGUITO-STORNATO-REGOLARIZZATO-RIPRISTINATO
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

     -- MIF_RR_QUALIFICATORE_COD_ERR qualificatore non ammesso
     strMessaggio:='Verifica esistenza record ricevuta dati qualificatore non ammesso.';
     insert into mif_t_oil_ricevuta
     ( oil_ricevuta_errore_id,oil_ricevuta_tipo_id,flusso_elab_mif_id, oil_progr_ricevuta_id,
       oil_ricevuta_anno,oil_ricevuta_numero,
       oil_ricevuta_data,oil_ricevuta_tipo,
       oil_ricevuta_importo,oil_ord_anno_bil,oil_ord_numero,
       validita_inizio,
       login_operazione,
       ente_proprietario_id
     )
     (select errore.oil_ricevuta_errore_id, oilRicevutaTipoId,flussoElabMifId,rr.mif_t_giornalecassa_id,
             rr.esercizio,rr.numero_bolletta_quietanza,
             rr.data_movimento::timestamp,substring(rr.tipo_movimento,1,1),
             abs(rr.importo),rr.esercizio,rr.numero_documento::integer,
             clock_timestamp(),loginOperazione,enteProprietarioId
      from  mif_t_elab_giornalecassa rr, siac_d_oil_ricevuta_errore errore
      where rr.flusso_elab_mif_id=flussoElabMifId
      and   (rr.tipo_movimento is not null and rr.tipo_movimento!=''    -- tipo_movimento ENTRATA-USCITA
         and rr.tipo_documento is not null and rr.tipo_documento!=''    -- tipo_documento MANDATO-REVERSALE-SOSPESO USCITA-SOSPESO ENTRATA
         and rr.tipo_operazione is not null and rr.tipo_operazione!='' )-- tipo_operazione ESEGUITO-STORNATO-REGOLARIZZATO-RIPRISTINATO
      and   not exists ( select distinct 1
                         from siac_d_oil_qualificatore q, siac_d_oil_esito_derivato e,siac_d_oil_ricevuta_tipo tipo
                         where q.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
                         and   q.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
                         and   q.ente_proprietario_id=enteProprietarioId
                         and   e.oil_esito_derivato_id=q.oil_esito_derivato_id
                         and   tipo.oil_ricevuta_tipo_id=e.oil_ricevuta_tipo_id
	                     and   tipo.oil_ricevuta_tipo_code in
                               (QUIET_MIF_FLUSSO_TIPO_CODE, STORNI_MIF_FLUSSO_TIPO_CODE,
                                PROVC_MIF_FLUSSO_TIPO_CODE,PROVC_ST_MIF_FLUSSO_TIPO_CODE)
      				   )
      and errore.oil_ricevuta_errore_code=MIF_RR_QUALIFICATORE_COD_ERR::varchar
      and errore.ente_proprietario_id=enteProprietarioId
      and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                     where rr1.flusso_elab_mif_id=flussoElabMifId
                     and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id));

    -- chiamate fnc per tipo_ricevuta :  gestione scarti e cicli elaborazione
    strMessaggio:='Gestione elaborazione quietanze-storni.';
    -- esecuzione
    -- fnc_mif_flusso_elaborato_giornalecassa_quiet
    select * into recQuiet
    from  fnc_mif_flusso_elaborato_giornalecassa_quiet
		  ( enteProprietarioId,
		    annoBilancio,
	        nomeEnte,
	        tipoFlussoMif,
		    flussoElabMifId,
			enteOilRec.ente_oil_firme_ord,
			loginOperazione,
			dataElaborazione
          );
    if recQuiet.codiceRisultato!= 0 then
    	codErrore:=-1;
        raise exception ' % ', recQuiet.messaggioRisultato;
    else
     countOrdAgg:=coalesce(recQuiet.countOrdAggRisultato,0);
    end if;

    strMessaggio:='Gestione elaborazione provviosori di cassa-storni.';
    -- esecuzione
    -- fnc_mif_flusso_elaborato_giornalecassa_prov
	select * into recProv
    from  fnc_mif_flusso_elaborato_giornalecassa_prov
		  ( enteProprietarioId,
		    annoBilancio,
	        nomeEnte,
	        tipoFlussoMif,
		    flussoElabMifId,
			loginOperazione,
			dataElaborazione
          );
    if recProv.codiceRisultato!= 0 then
       	codErrore:=-1;
        raise exception ' % ', recProv.messaggioRisultato;
    else
     countProvAgg:=coalesce(recProv.countOrdAggRisultato,0);
    end if;

    -- inserimento scarti in siac_t_oil_ricevuta
	strMessaggio:='Inserimento scarti ricevute [siac_oil_ricevute] dopo ciclo di elaborazione.';
    -- inserire in siac_t_oil_ricevuta i dati scartati presenti in mif_t_oil_ricevuta
    insert into siac_t_oil_ricevuta
    ( oil_ricevuta_anno,
      oil_ricevuta_numero,
      oil_ricevuta_data,
      oil_ricevuta_tipo,
      oil_ricevuta_importo,
      oil_ricevuta_cro1,
      oil_ricevuta_cro2,
--    oil_ricevuta_note_tes,
--    oil_ricevuta_denominazione,
      oil_ricevuta_errore_id,
      oil_ricevuta_tipo_id,
      oil_ricevuta_note,
      oil_ord_bil_id,
      oil_ord_id,
      flusso_elab_mif_id,
      oil_progr_ricevuta_id,
      oil_progr_dett_ricevuta_id,
      oil_ord_anno_bil,
      oil_ord_numero,
      oil_ord_importo,
      oil_ord_data_emissione,
      oil_ord_data_annullamento,
      oil_ord_trasm_oil_data,
      oil_ord_data_firma,
      oil_ord_importo_quiet,
      oil_ord_importo_storno,
      oil_ord_importo_quiet_tot,
      validita_inizio,
      ente_proprietario_id,
      login_operazione)
    ( select
       annoBilancio,
       m.oil_ricevuta_numero,
       m.oil_ricevuta_data,
       m.oil_ricevuta_tipo,
       m.oil_ricevuta_importo,
       m.oil_ricevuta_cro1,
       m.oil_ricevuta_cro2,
--     oil_ricevuta_note_tes,
--     oil_ricevuta_denominazione,
       m.oil_ricevuta_errore_id,
       m.oil_ricevuta_tipo_id,
       m.oil_ricevuta_note,
       m.oil_ord_bil_id,
       m.oil_ord_id,
       flussoElabMifId,
       m.oil_progr_ricevuta_id,
       m.oil_progr_dett_ricevuta_id,
       m.oil_ord_anno_bil,
       m.oil_ord_numero,
       m.oil_ord_importo,
       m.oil_ord_data_emissione,
       m.oil_ord_data_annullamento,
       m.oil_ord_trasm_oil_data,
       m.oil_ord_data_firma,
       m.oil_ord_importo_quiet,
       m.oil_ord_importo_storno,
       m.oil_ord_importo_quiet_tot,
       clock_timestamp(),
	   enteProprietarioId,
       loginOperazione
     from  mif_t_oil_ricevuta m
     where m.flusso_elab_mif_id=flussoElabMifId
     and   m.oil_ricevuta_errore_id is not null
     order by m.oil_ricevuta_id);

	-- verificare se altre tab temporanee da cancellare
    -- cancellazione tabelle temporanee
    -- cancellare mif_t_oil_ricevuta
    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;


    -- chiudere elaborazione
	-- aggiornamento mif_t_flusso_elaborato per flusso_elab_mif_id=flussoElabMifId
    strMessaggio:='Elaborazione flusso giornale di cassa.Chiusura elaborazione [stato OK] mif_t_flusso_elaborato flussoElabMifId='||flussoElabMifId
                  ||'.Aggiornati ordinativi num='||countOrdAgg
                  ||'.Aggiornati provvisori di cassa num='||countProvAgg
                  ||'.';
    update  mif_t_flusso_elaborato
    set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,flusso_elab_mif_num_ord_elab,validita_fine)=
   	    ('OK',
         'ELABORAZIONE CONCLUSA [STATO OK] PER TIPO FLUSSO '
         ||GIOCASSA_ELAB_FLUSSO_TIPO
         ||'. AGGIORNATI NUM='||countOrdAgg||' ORDINATIVI'
         ||'. AGGIORNATI NUM='||countProvAgg||' PROVVISORI.',
         countOrdAgg+countProvAgg,clock_timestamp())
    where flusso_elab_mif_id=flussoElabMifId;

--    messaggioRisultato:=strMessaggioFinale||' Elaborazione conclusa OK.';
    messaggioRisultato:=strMessaggio;
    messaggioRisultato:=upper(messaggioRisultato);
    countOrdAggRisultato:=countOrdAgg+countProvAgg;

    return;

exception
    when RAISE_EXCEPTION THEN
		if codErrore is null then
         messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'') ;
        else
        	messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'') ;
        end if;
     	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);

  		-- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	   	delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;

   --     if codErrore is not null then
        	update  mif_t_flusso_elaborato
    		set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  		('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
		    where flusso_elab_mif_id=flussoElabMifId;

  --      end if;

        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        -- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
    	strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;

		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
		where flusso_elab_mif_id=flussoElabMifId;

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        -- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;


		update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
		where flusso_elab_mif_id=flussoElabMifId;

        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        -- verificare se altre tab temporanee da cancellare
	    -- cancellazione tabelle temporanee
    	-- cancellare mif_t_oil_ricevuta
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_oil_ricevuta flussoElabMifId='||flussoElabMifId||'.';
    	delete from mif_t_oil_ricevuta where flusso_elab_mif_id=flussoElabMifId;
	    strMessaggio:='Cancellazione archivio temporaneo mif_t_elab_giornalecassa flussoElabMifId='||flussoElabMifId||'.';
	    delete from mif_t_elab_giornalecassa where flusso_elab_mif_id=flussoElabMifId;

        update  mif_t_flusso_elaborato
    	set (flusso_elab_mif_esito,flusso_elab_mif_esito_msg,validita_fine)=
   	  	('KO','ELABORAZIONE CONCLUSA [STATO KO].'||messaggioRisultato,clock_timestamp())
		where flusso_elab_mif_id=flussoElabMifId;

        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;
-- SIAC-5765 pto 18 D) FINE