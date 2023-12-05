/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-5874 Sofia 13.02.2018  -INIZIO


ALTER TABLE mif_r_conto_tesoreria_fruttifero
  ALTER COLUMN fruttifero TYPE VARCHAR(20);

-- SIAC-5874 Sofia 13.02.2018  -FINE

-- SIAC-5849 Sofia 14.02.2018  -Inizio

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
     -- 14.02.2018 Sofia siac-5874
     checkDati:=null;
     strMessaggio:='Lettura gruppo tipo pagamento '||accreditoCodeCB||'.';
	 select 1 into checkDati
     from siac_d_accredito_gruppo gruppo, siac_d_accredito_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.accredito_tipo_code=accreditoCodeCB
     and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
     and   gruppo.accredito_gruppo_code=accreditoGruppoCode
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

 	 -- se il codice paese='' or codicepaese is null
 	 -- cerco il gruppo da accredito_tipo_id
	 -- se e' CB allora forzo paese=' '
--     if accreditoGruppoCode=accreditoCodeCB then
     -- 14.02.2018 Sofia siac-5874
     if checkDati is not null then
     	codicePaese=' '; -- forzato per cercare CB extrasepa
     end if;

    end if;
 end if;


 if isProvvisori=false and  isCompensa=false and
    codicePaese is not null and codicePaese!=codiceItalia then
    strMessaggio:='Lettura tipo pagamento ordinativo [siac_t_sepa].';
    checkDati:=null; -- 14.02.2018 Sofia siac-5874
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

-- SIAC-5849 Sofia 14.02.2018  -Inizio

-- SIAC-5882 Sofia 13.02.2018  -INIZIO

CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_reimputa_elabora(
    IN p_fasebilelabid integer,
    IN enteproprietarioid integer,
    IN annobilancio integer,
    IN loginoperazione character varying,
    IN dataelaborazione timestamp without time zone,
    IN p_movgest_tipo_code character varying,
    OUT outfasebilelabretid integer,
    OUT codicerisultato integer,
    OUT messaggiorisultato character varying)
  RETURNS record AS
$BODY$
  DECLARE
    strmessaggiotemp   				VARCHAR(1000):='';
    tipomovgestid      				INTEGER:=NULL;
    movgesttstipoid    				INTEGER:=NULL;
    tipomovgesttssid   				INTEGER:=NULL;
    tipomovgesttstid   				INTEGER:=NULL;
    tipocapitologestid 				INTEGER:=NULL;
    bilancioid         				INTEGER:=NULL;
    bilancioprecid     				INTEGER:=NULL;
    periodoid          				INTEGER:=NULL;
    periodoprecid      				INTEGER:=NULL;
    datainizioval      				timestamp:=NULL;
    movgestidret      				INTEGER:=NULL;
    movgesttsidret    				INTEGER:=NULL;
    v_elemid          				INTEGER:=NULL;
    movgesttstipotid  				INTEGER:=NULL;
    movgesttstiposid  				INTEGER:=NULL;
    movgesttstipocode 				VARCHAR(10):=NULL;
    movgeststatoaid   				INTEGER:=NULL;
    v_importomodifica 				NUMERIC;
    movgestrec 						RECORD;
    aggprogressivi 					RECORD;
    cleanrec						RECORD;
    v_movgest_numero                INTEGER;
    v_prog_id                       INTEGER;
    v_flagdariaccertamento_attr_id  INTEGER;
    v_annoriaccertato_attr_id       INTEGER;
    v_numeroriaccertato_attr_id     INTEGER;
    v_numero_el                     integer;
    -- tipo periodo annuale
    sy_per_tipo CONSTANT VARCHAR:='SY';
    -- tipo anno ordinario annuale
    bil_ord_tipo        CONSTANT VARCHAR:='BIL_ORD';
    imp_movgest_tipo    CONSTANT VARCHAR:='I';
    acc_movgest_tipo    CONSTANT VARCHAR:='A';
    sim_movgest_ts_tipo CONSTANT VARCHAR:='SIM';
    sac_movgest_ts_tipo CONSTANT VARCHAR:='SAC';
    a_mov_gest_stato    CONSTANT VARCHAR:='A';
    strmessaggio        VARCHAR(1500):='';
    strmessaggiofinale  VARCHAR(1500):='';
    codresult           INTEGER;
    v_bil_attr_id       INTEGER;
    v_attr_code         VARCHAR;
    movgest_ts_t_tipo   CONSTANT VARCHAR:='T';
    movgest_ts_s_tipo   CONSTANT VARCHAR:='S';
    cap_ug_tipo         CONSTANT VARCHAR:='CAP-UG';
    cap_eg_tipo         CONSTANT VARCHAR:='CAP-EG';
    ape_gest_reimp      CONSTANT VARCHAR:='APE_GEST_REIMP';
    faserec RECORD;
    faseelabrec RECORD;
    recmovgest RECORD;
    v_maxcodgest      INTEGER;
    v_movgest_ts_id   INTEGER;
    v_ambito_id       INTEGER;
    v_inizio          VARCHAR;
    v_fine            VARCHAR;
    v_bil_tipo_id     INTEGER;
    v_periodo_id      INTEGER;
    v_periodo_tipo_id INTEGER;
    v_tmp             VARCHAR;


    -- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;
	-- 07.03.2017 Sofia SIAC-4568
    dataEmissione     timestamp:=null;


  BEGIN
    codicerisultato:=NULL;
    messaggiorisultato:=NULL;
    strmessaggiofinale:='Inizio.';
    datainizioval:= clock_timestamp();
    -- 07.03.2017 Sofia SIAC-4568
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;

    SELECT attr.attr_id
    INTO   v_flagdariaccertamento_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='flagDaRiaccertamento'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_annoriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='annoRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    SELECT attr.attr_id
    INTO   v_numeroriaccertato_attr_id
    FROM   siac_t_attr attr
    WHERE  attr.attr_code ='numeroRiaccertato'
    AND    attr.ente_proprietario_id = enteproprietarioid;

    -- estraggo il bilancio nuovo
    SELECT bil_id
    INTO   strict bilancioid
    FROM   siac_t_bil
    WHERE  bil_code = 'BIL_'
                  ||annobilancio::VARCHAR
    AND    ente_proprietario_id = enteproprietarioid;

    -- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo then
    	strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTipoCode='||imp_movgest_tipo||'.';
        select tipo.movgest_tipo_id into strict tipoMovGestId
        from siac_d_movgest_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_tipo_code=imp_movgest_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

        strMessaggio:='Lettura identificativo per movGestTsTTipoCode='||movgest_ts_t_tipo||'.';
        select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
        from siac_d_movgest_ts_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.movgest_ts_tipo_code=movgest_ts_t_tipo
        and   tipo.data_cancellazione is null
        and   tipo.validita_fine is null;

    end if;


    FOR movgestrec IN
    (
           SELECT reimputazione_id ,
                  bil_id ,
                  elemid_old ,
                  elem_code ,
                  elem_code2 ,
                  elem_code3 ,
                  elem_tipo_code ,
                  movgest_id ,
                  movgest_anno ,
                  movgest_numero ,
                  movgest_desc ,
                  movgest_tipo_id ,
                  parere_finanziario ,
                  parere_finanziario_data_modifica ,
                  parere_finanziario_login_operazione ,
                  movgest_ts_id ,
                  movgest_ts_code ,
                  movgest_ts_desc ,
                  movgest_ts_tipo_id ,
                  movgest_ts_id_padre ,
                  ordine ,
                  livello ,
                  movgest_ts_scadenza_data ,
                  movgest_ts_det_tipo_id ,
                  impoinizimpegno ,
                  impoattimpegno ,
                  importomodifica ,
                  tipo ,
                  movgest_ts_det_tipo_code ,
                  movgest_ts_det_importo ,
                  mtdm_reimputazione_anno ,
                  mtdm_reimputazione_flag ,
                  mod_tipo_code ,
                  login_operazione ,
                  ente_proprietario_id,
                  siope_tipo_debito_id,
		          siope_assenza_motivazione_id
           FROM   fase_bil_t_reimputazione
           WHERE  ente_proprietario_id = enteproprietarioid
           AND    fasebilelabid = p_fasebilelabid
           AND    fl_elab = 'N' )
    LOOP
      movgesttsidret:=NULL;
      movgestidret:=NULL;
      codresult:=NULL;
      v_elemid:=NULL;
      v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-01-01';
      v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR ||'-12-31';

	  --caso in cui si tratta di impegno/ accertamento creo la struttua a partire da movgest
      --tipots.movgest_ts_tipo_code tipo

      IF movgestrec.tipo !='S' THEN

        v_movgest_ts_id = NULL;
        --v_maxcodgest= movgestrec.movgest_ts_code::INTEGER;

        IF p_movgest_tipo_code = 'I' THEN
          strmessaggio:='progressivo per Impegno ' ||'imp_'||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
          SELECT prog_value + 1 ,
                 prog_id
          INTO   strict v_movgest_numero ,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo.ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'imp_'  ||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN
            strmessaggio:='aggiungo progressivo per anno ' ||'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   strict v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            INSERT INTO siac_t_progressivo
            (
                        prog_value,
                        prog_key ,
                        ambito_id ,
                        validita_inizio ,
                        validita_fine ,
                        ente_proprietario_id ,
                        data_cancellazione ,
                        login_operazione
            )
            VALUES
            (
                        0,
                        'imp_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR,
                        v_ambito_id ,
                        v_inizio::timestamp,
                        v_fine::timestamp,
                        enteproprietarioid ,
                        NULL,
                        loginoperazione
            )
            returning   prog_id  INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'imp_'
                          ||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF;

        ELSE --IF p_movgest_tipo_code = 'I'

          --Accertamento
          SELECT prog_value + 1,
                 prog_id
          INTO   v_movgest_numero,
                 v_prog_id
          FROM   siac_t_progressivo ,
                 siac_d_ambito
          WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
          AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
          AND    siac_t_progressivo.prog_key = 'acc_'
                        ||movgestrec.mtdm_reimputazione_anno::VARCHAR
          AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          IF v_movgest_numero IS NULL THEN

            strmessaggio:='aggiungo progressivo per anno ' ||'acc_' ||movgestrec.mtdm_reimputazione_anno::VARCHAR ||'.';
            SELECT ambito_id
            INTO   v_ambito_id
            FROM   siac_d_ambito
            WHERE  ambito_code = 'AMBITO_FIN'
            AND    ente_proprietario_id = enteproprietarioid
            AND    data_cancellazione IS NULL;

            v_inizio := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-01-01'; v_fine := movgestrec.mtdm_reimputazione_anno::VARCHAR||'-12-31';
            INSERT INTO siac_t_progressivo
			(
				prog_value ,
				prog_key ,
				ambito_id ,
				validita_inizio ,
				validita_fine ,
				ente_proprietario_id ,
				data_cancellazione ,
				login_operazione
			)
			VALUES
			(
				0,
				'acc_'||movgestrec.mtdm_reimputazione_anno::VARCHAR,
				v_ambito_id ,
				v_inizio::timestamp,
				v_fine::timestamp,
				enteproprietarioid ,
				NULL,
				loginoperazione
			)
            returning   prog_id INTO        v_prog_id ;

            SELECT prog_value + 1 ,
                   prog_id
            INTO   strict v_movgest_numero ,
                   v_prog_id
            FROM   siac_t_progressivo ,
                   siac_d_ambito
            WHERE  siac_t_progressivo.ambito_id = siac_d_ambito.ambito_id
            AND    siac_t_progressivo .ente_proprietario_id = enteproprietarioid
            AND    siac_t_progressivo.prog_key = 'acc_'
                          ||movgestrec.mtdm_reimputazione_anno::VARCHAR
            AND    siac_d_ambito.ambito_code = 'AMBITO_FIN';

          END IF; --fine if v_movgest_numero

        END IF;

        strmessaggio:='inserisco il siac_t_movgest.';
        INSERT INTO siac_t_movgest
        (
			movgest_anno,
			movgest_numero,
			movgest_desc,
			movgest_tipo_id,
			bil_id,
			validita_inizio,
			ente_proprietario_id,
			login_operazione,
			parere_finanziario,
			parere_finanziario_data_modifica,
			parere_finanziario_login_operazione
        )
        VALUES
        (
			movgestrec.mtdm_reimputazione_anno,
            v_movgest_numero,
			movgestrec.movgest_desc,
			movgestrec.movgest_tipo_id,
			bilancioid,
			datainizioval,
			enteproprietarioid,
			loginoperazione,
			movgestrec.parere_finanziario,
			movgestrec.parere_finanziario_data_modifica,
			movgestrec.parere_finanziario_login_operazione
        )
        returning   movgest_id INTO        movgestidret;

        IF movgestidret IS NULL THEN
          strmessaggiotemp:=strmessaggio;
          codresult:=-1;
        END IF;

        RAISE notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movgestidret;

        strmessaggio:='aggiornamento progressivo v_prog_id ' ||v_prog_id::VARCHAR;
        UPDATE siac_t_progressivo
        SET    prog_value = prog_value + 1
        WHERE  prog_id = v_prog_id;

        strmessaggio:='estraggo il capitolo =elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';
        --raise notice 'strMessaggio=%',strMessaggio;
        SELECT be.elem_id
        INTO   v_elemid
        FROM   siac_t_bil_elem be,
               siac_r_bil_elem_stato rbes,
               siac_d_bil_elem_stato bbes,
               siac_d_bil_elem_tipo bet
        WHERE  be.elem_tipo_id = bet.elem_tipo_id
        AND    be.elem_code=movgestrec.elem_code
        AND    be.elem_code2=movgestrec.elem_code2
        AND    be.elem_code3=movgestrec.elem_code3
        AND    bet.elem_tipo_code = movgestrec.elem_tipo_code
        AND    be.elem_id = rbes.elem_id
        AND    rbes.elem_stato_id = bbes.elem_stato_id
        AND    bbes.elem_stato_code !='AN'
        AND    rbes.data_cancellazione IS NULL
        AND    be.bil_id = bilancioid
        AND    be.ente_proprietario_id = enteproprietarioid
        AND    be.data_cancellazione IS NULL
        AND    be.validita_fine IS NULL;

        IF v_elemid IS NULL THEN
          codresult:=-1;
          strmessaggio:= ' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.';

          update fase_bil_t_reimputazione
          set fl_elab='X'
            ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
            ,scarto_code='IMAC1'
            ,scarto_desc=' impegno/accertamento privo di capitolo nel nuovo bilancio elem_code ' || movgestrec.elem_code ||' elem_code2 ' || movgestrec.elem_code2 ||' elem_code3' || movgestrec.elem_code3 ||' elem_tipo_code =' || movgestrec.elem_tipo_code ||' bilancioId='||bilancioid::VARCHAR ||'.'
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
          continue;
        END IF;


        -- relazione tra capitolo e movimento
        strmessaggio:='Inserimento relazione movimento capitolo anno='||movgestrec.movgest_anno ||' numero=' ||movgestrec.movgest_numero || ' v_elemId='||v_elemid::varchar ||' [siac_r_movgest_bil_elem]';

        INSERT INTO siac_r_movgest_bil_elem
        (
          movgest_id,
          elem_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        VALUES
        (
          movgestidret,
          v_elemid,--movGestRec.elemId_old,
          datainizioval,
          enteproprietarioid,
          loginoperazione
        )
        returning   movgest_atto_amm_id  INTO        codresult;

        IF codresult IS NULL THEN
          codresult:=-1;
          strmessaggiotemp:=strmessaggio;
        ELSE
          codresult:=NULL;
        END IF;
        strmessaggio:='Inserimento movimento movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' sub=' ||movgestrec.movgest_ts_code || ' [siac_t_movgest_ts].';
        RAISE notice 'strMessaggio=% ',strmessaggio;

        v_maxcodgest := v_movgest_numero;



      ELSE --caso in cui si tratta di subimpegno/ subaccertamento estraggo il movgest_id padre e movgest_ts_id_padre IF movgestrec.tipo =='S'

        -- todo calcolare il papa' sel subimpegno movgest_id  del padre  ed anche movgest_ts_id_padre
        strmessaggio:='caso SUB movGestTipo=' ||movgestrec.tipo ||'.';

        SELECT count(*)
        INTO v_numero_el
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T';


        SELECT fase_bil_t_reimputazione.movgestnew_id ,
               fase_bil_t_reimputazione.movgestnew_ts_id
        INTO strict  movgestidret ,
               v_movgest_ts_id
        FROM   fase_bil_t_reimputazione
        WHERE  fase_bil_t_reimputazione.movgest_anno = movgestrec.movgest_anno
        AND    fase_bil_t_reimputazione.movgest_numero = movgestrec.movgest_numero
        AND    fase_bil_t_reimputazione.fasebilelabid = p_fasebilelabid
        AND    fase_bil_t_reimputazione.mod_tipo_code =  movgestrec.mod_tipo_code
        AND    fase_bil_t_reimputazione.tipo = 'T';



        if movgestidret is null then
          update fase_bil_t_reimputazione
          set fl_elab        ='X'
            ,scarto_code      ='IMACNP'
            ,scarto_desc      =' subimpegno/subaccertamento privo di testata modificata movGestTipo=' ||movgestrec.tipo || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero|| ' v_numero_el = ' ||v_numero_el::varchar||'.'
      	    ,movgestnew_ts_id = movgesttsidret
            ,movgestnew_id    = movgestidret
            ,data_modifica = clock_timestamp()
          from
          	siac_t_bil_elem elem
      	  where
      	  	fase_bil_t_reimputazione.reimputazione_id = movgestrec.reimputazione_id;
        	continue;
        end if;


        strmessaggio:=' estraggo movGest padre movGestRec.movgest_id='||movgestrec.movgest_id::VARCHAR ||' p_fasebilelabid'||p_fasebilelabid::VARCHAR ||'' ||'.';
        --strMessaggio:='calcolo il max siac_t_movgest_ts.movgest_ts_code  movGestIdRet='||movGestIdRet::varchar ||'.';

        SELECT max(siac_t_movgest_ts.movgest_ts_code::INTEGER)
        INTO   v_maxcodgest
        FROM   siac_t_movgest ,
               siac_t_movgest_ts ,
               siac_d_movgest_tipo,
               siac_d_movgest_ts_tipo
        WHERE  siac_t_movgest.movgest_id = siac_t_movgest_ts.movgest_id
        AND    siac_t_movgest.movgest_tipo_id = siac_d_movgest_tipo.movgest_tipo_id
        AND    siac_d_movgest_tipo.movgest_tipo_code = p_movgest_tipo_code
        AND    siac_t_movgest_ts.movgest_ts_tipo_id = siac_d_movgest_ts_tipo.movgest_ts_tipo_id
        AND    siac_d_movgest_ts_tipo.movgest_ts_tipo_code = 'S'
        AND    siac_t_movgest.bil_id = bilancioid
        AND    siac_t_movgest.ente_proprietario_id = enteproprietarioid
        AND    siac_t_movgest.movgest_id = movgestidret;

        IF v_maxcodgest IS NULL THEN
          v_maxcodgest:=0;
        END IF;
        v_maxcodgest := v_maxcodgest+1;

     END IF; -- fine cond se sub o non sub





      -- caso di sub



      INSERT INTO siac_t_movgest_ts
      (
        movgest_ts_code,
        movgest_ts_desc,
        movgest_id,
        movgest_ts_tipo_id,
        movgest_ts_id_padre,
        movgest_ts_scadenza_data,
        ordine,
        livello,
        validita_inizio,
        ente_proprietario_id,
        login_operazione,
        login_creazione,
		siope_tipo_debito_id,
		siope_assenza_motivazione_id
      )
      VALUES
      (
        v_maxcodgest::VARCHAR, --movGestRec.movgest_ts_code,
        movgestrec.movgest_ts_desc,
        movgestidret, -- inserito se I/A, per SUB ricavato
        movgestrec.movgest_ts_tipo_id,
        v_movgest_ts_id, -- ????? valorizzato se SUB come quello da cui deriva diversamente null
        movgestrec.movgest_ts_scadenza_data,
        movgestrec.ordine,
        movgestrec.livello,
--        dataelaborazione, -- 07.03.2017 Sofia SIAC-4568
		dataEmissione,      -- 07.03.2017 Sofia SIAC-4568
        enteproprietarioid,
        loginoperazione,
        loginoperazione,
        movgestrec.siope_tipo_debito_id,
		movgestrec.siope_assenza_motivazione_id
      )
      returning   movgest_ts_id
      INTO        movgesttsidret;

      IF movgesttsidret IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      END IF;
      RAISE notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movgesttsidret,codresult;

      -- siac_r_movgest_ts_stato
      strmessaggio:='Inserimento movimento ' || ' anno='  ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code || ' [siac_r_movgest_ts_stato].';
      INSERT INTO siac_r_movgest_ts_stato
	  (
          movgest_ts_id,
          movgest_stato_id,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.movgest_stato_id,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_stato r,
                siac_d_movgest_stato stato
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    stato.movgest_stato_id=r.movgest_stato_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    stato.data_cancellazione IS NULL
         AND    stato.validita_fine IS NULL )
      returning   movgest_stato_r_id INTO        codresult;

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      RAISE notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movgesttsidret,codresult;
      -- siac_t_movgest_ts_det
      strmessaggio:='Inserimento movimento ' || ' anno=' ||movgestrec.movgest_anno || ' numero=' ||movgestrec.movgest_numero || ' sub=' ||movgestrec.movgest_ts_code|| ' [siac_t_movgest_ts_det].';
      RAISE notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_ts_id=%', movgesttsidret,movgestrec.movgest_ts_id;
      v_importomodifica := movgestrec.importomodifica * -1;
      INSERT INTO siac_t_movgest_ts_det
	  (
        movgest_ts_id,
        movgest_ts_det_tipo_id,
        movgest_ts_det_importo,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
       SELECT movgesttsidret,
              r.movgest_ts_det_tipo_id,
              v_importomodifica,
              datainizioval,
              enteproprietarioid,
              loginoperazione
       FROM   siac_t_movgest_ts_det r
       WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
       AND    r.data_cancellazione IS NULL
       AND    r.validita_fine IS NULL );

      IF codresult IS NULL THEN
        codresult:=-1;
        strmessaggiotemp:=strmessaggio;
      ELSE
        codresult:=NULL;
      END IF;
      strmessaggio:='Inserimento classificatori  movgest_ts_id='||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_class].';
      -- siac_r_movgest_class
      INSERT INTO siac_r_movgest_class
	  (
				  movgest_ts_id,
				  classif_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.classif_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_class r,
					siac_t_class class
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    class.classif_id=r.classif_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
			 AND    class.data_cancellazione IS NULL
			 AND    class.validita_fine IS NULL );

      strmessaggio:='Inserimento attributi  movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_attr].';
      -- siac_r_movgest_ts_attr
      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id,
        attr_id,
        tabella_id,
        BOOLEAN,
        percentuale,
        testo,
        numerico,
        validita_inizio,
        ente_proprietario_id,
        login_operazione
	  )
	  (
         SELECT movgesttsidret,
                r.attr_id,
                r.tabella_id,
                r.BOOLEAN,
                r.percentuale,
                r.testo,
                r.numerico,
                datainizioval,
                enteproprietarioid,
                loginoperazione
         FROM   siac_r_movgest_ts_attr r,
                siac_t_attr attr
         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
         AND    attr.attr_id=r.attr_id
         AND    r.data_cancellazione IS NULL
         AND    r.validita_fine IS NULL
         AND    attr.data_cancellazione IS NULL
         AND    attr.validita_fine IS NULL
         AND    attr.attr_code NOT IN ('flagDaRiaccertamento',
                                       'annoRiaccertato',
                                       'numeroRiaccertato') );

      INSERT INTO siac_r_movgest_ts_attr
	  (
				  movgest_ts_id ,
				  attr_id ,
				  tabella_id ,
				  "boolean" ,
				  percentuale,
				  testo,
				  numerico ,
				  validita_inizio ,
				  validita_fine ,
				  ente_proprietario_id ,
				  data_cancellazione ,
				  login_operazione
	  )  VALUES (
				  movgesttsidret ,
				  v_flagdariaccertamento_attr_id ,
				  NULL,
				  'S',
				  NULL,
				  NULL ,
				  NULL,
				  now() ,
				  NULL ,
				  enteproprietarioid ,
				  NULL ,
				  loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_annoriaccertato_attr_id,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_anno ,
        NULL ,
        now() ,
        NULL,
        enteproprietarioid,
        NULL,
        loginoperazione
	  );

      INSERT INTO siac_r_movgest_ts_attr
	  (
        movgest_ts_id ,
        attr_id ,
        tabella_id ,
        "boolean" ,
        percentuale,
        testo,
        numerico ,
        validita_inizio ,
        validita_fine ,
        ente_proprietario_id ,
        data_cancellazione ,
        login_operazione
	  )
	  VALUES
	  (
        movgesttsidret ,
        v_numeroriaccertato_attr_id ,
        NULL,
        NULL,
        NULL,
        movgestrec.movgest_numero ,
        NULL,
        now() ,
        NULL ,
        enteproprietarioid ,
        NULL,
        loginoperazione
	  );

      -- siac_r_movgest_ts_atto_amm
      strmessaggio:='Inserimento   movgest_ts_id='
      ||movgestrec.movgest_ts_id::VARCHAR
      || ' [siac_r_movgest_ts_atto_amm].';
      INSERT INTO siac_r_movgest_ts_atto_amm
	  (
				  movgest_ts_id,
				  attoamm_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.attoamm_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_atto_amm r,
					siac_t_atto_amm atto
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    atto.attoamm_id=r.attoamm_id
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL
       );
--			 AND    atto.data_cancellazione IS NULL Sofia HD-INC000001535447
--			 AND    atto.validita_fine IS NULL );

      -- siac_r_movgest_ts_sog
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sog].';
      INSERT INTO siac_r_movgest_ts_sog
	  (
				  movgest_ts_id,
				  soggetto_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sog r,
					siac_t_soggetto sogg
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sogg.soggetto_id=r.soggetto_id
			 AND    sogg.data_cancellazione IS NULL
			 AND    sogg.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_sogclasse
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_sogclasse].';
      INSERT INTO siac_r_movgest_ts_sogclasse
	  (
				  movgest_ts_id,
				  soggetto_classe_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.soggetto_classe_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_sogclasse r,
					siac_d_soggetto_classe classe
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    classe.soggetto_classe_id=r.soggetto_classe_id
			 AND    classe.data_cancellazione IS NULL
			 AND    classe.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_movgest_ts_programma
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_movgest_ts_programma].';
      INSERT INTO siac_r_movgest_ts_programma
	  (
				  movgest_ts_id,
				  programma_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.programma_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_movgest_ts_programma r,
					siac_t_programma prog
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    prog.programma_id=r.programma_id
			 AND    prog.data_cancellazione IS NULL
			 AND    prog.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_mutuo_voce_movgest
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_mutuo_voce_movgest].';
      INSERT INTO siac_r_mutuo_voce_movgest
	  (
				  movgest_ts_id,
				  mut_voce_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.mut_voce_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_mutuo_voce_movgest r,
					siac_t_mutuo_voce voce
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    voce.mut_voce_id=r.mut_voce_id
			 AND    voce.data_cancellazione IS NULL
			 AND    voce.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_causale_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_causale_movgest_ts].';
      INSERT INTO siac_r_causale_movgest_ts
	  (
				  movgest_ts_id,
				  caus_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.caus_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_causale_movgest_ts r,
					siac_d_causale caus
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    caus.caus_id=r.caus_id
			 AND    caus.data_cancellazione IS NULL
			 AND    caus.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- 05.05.2017 Sofia HD-INC000001737424
      -- siac_r_subdoc_movgest_ts
      /*
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_subdoc_movgest_ts].';
      INSERT INTO siac_r_subdoc_movgest_ts
	  (
				  movgest_ts_id,
				  subdoc_id,
				  validita_inizio,
				  ente_proprietario_id,
				  login_operazione
	  )
	  (
			 SELECT movgesttsidret,
					r.subdoc_id,
					datainizioval,
					enteproprietarioid,
					loginoperazione
			 FROM   siac_r_subdoc_movgest_ts r,
					siac_t_subdoc sub
			 WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
			 AND    sub.subdoc_id=r.subdoc_id
			 AND    sub.data_cancellazione IS NULL
			 AND    sub.validita_fine IS NULL
			 AND    r.data_cancellazione IS NULL
			 AND    r.validita_fine IS NULL );

      -- siac_r_predoc_movgest_ts
      strmessaggio:='Inserimento   movgest_ts_id=' ||movgestrec.movgest_ts_id::VARCHAR || ' [siac_r_predoc_movgest_ts].';
      INSERT INTO siac_r_predoc_movgest_ts
                  (
                              movgest_ts_id,
                              predoc_id,
                              validita_inizio,
                              ente_proprietario_id,
                              login_operazione
                  )
                  (
                         SELECT movgesttsidret,
                                r.predoc_id,
                                datainizioval,
                                enteproprietarioid,
                                loginoperazione
                         FROM   siac_r_predoc_movgest_ts r,
                                siac_t_predoc sub
                         WHERE  r.movgest_ts_id=movgestrec.movgest_ts_id
                         AND    sub.predoc_id=r.predoc_id
                         AND    sub.data_cancellazione IS NULL
                         AND    sub.validita_fine IS NULL
                         AND    r.data_cancellazione IS NULL
                         AND    r.validita_fine IS NULL );
	  */
      -- 05.05.2017 Sofia HD-INC000001737424


      strmessaggio:='aggiornamento tabella di appoggio';
      UPDATE fase_bil_t_reimputazione
      SET   movgestnew_ts_id =movgesttsidret
      		,movgestnew_id =movgestidret
            ,data_modifica = clock_timestamp()
       		,fl_elab='S'
      WHERE  reimputazione_id = movgestrec.reimputazione_id;



    END LOOP;

    -- bonifica eventuali scarti
    select * into cleanrec from fnc_fasi_bil_gest_reimputa_clean(  p_fasebilelabid ,enteproprietarioid );

	-- 15.02.2017 Sofia Sofia SIAC-4425
	if p_movgest_tipo_code=imp_movgest_tipo and cleanrec.codicerisultato =0 then
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che non hanno ancora attributo
	 strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'N',
		    dataInizioVal,
		    ts.ente_proprietario_id,
		    loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
     and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null);

     -- insert S per impegni mov.movgest_anno::integer=annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
	 INSERT INTO siac_r_movgest_ts_attr
	 (
	  movgest_ts_id,
	  attr_id,
	  boolean,
	  validita_inizio,
	  ente_proprietario_id,
	  login_operazione
	 )
	 select ts.movgest_ts_id,
	        flagFrazAttrId,
            'S',
	        dataInizioVal,
	        ts.ente_proprietario_id,
	        loginOperazione
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::integer=annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   not exists (select 1 from siac_r_movgest_ts_attr r1
       		           where r1.movgest_ts_id=ts.movgest_ts_id
                       and   r1.attr_id=flagFrazAttrId
                       and   r1.data_cancellazione is null
                       and   r1.validita_fine is null)
     and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
					  where ra.movgest_ts_id=ts.movgest_ts_id
					  and   atto.attoamm_id=ra.attoamm_id
				 	  and   atto.attoamm_anno::integer < annoBilancio
		     		  and   ra.data_cancellazione is null
				      and   ra.validita_fine is null);

     -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo reimputazioni consideriamo solo mov.movgest_anno::integer>annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer>annoBilancio
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null;

     -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza con atto amministrativo antecedente.';
     update siac_r_movgest_ts_attr r set boolean='N'
  	 from siac_t_movgest mov, siac_t_movgest_ts ts,
	      siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
  	 where mov.bil_id=bilancioId
	 and   mov.movgest_anno::INTEGER=2017
	 and   mov.movgest_tipo_id=tipoMovGestId
	 and   ts.movgest_id=mov.movgest_id
     and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
	 and   r.movgest_ts_id=ts.movgest_ts_id
     and   r.attr_id=flagFrazAttrId
	 and   ra.movgest_ts_id=ts.movgest_ts_id
	 and   atto.attoamm_id=ra.attoamm_id
	 and   atto.attoamm_anno::integer < annoBilancio
	 and   r.boolean='S'
     and   r.login_operazione=loginOperazione
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    end if;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


    outfasebilelabretid:=p_fasebilelabid;
    if cleanrec.codicerisultato = -1 then
	    codicerisultato:=cleanrec.codicerisultato;
	    messaggiorisultato:=cleanrec.messaggiorisultato;
    else
	    codicerisultato:=0;
	    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    end if;



    outfasebilelabretid:=p_fasebilelabid;
    codicerisultato:=0;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||' FINE';
    RETURN;
  EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % ERRORE : %',strmessaggiofinale,strmessaggio,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'ERRORE :' ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Nessun elemento trovato.' ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE,substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale ||strmessaggio ||'Errore DB ' ||SQLSTATE ||' ' ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    outfasebilelabretid:=p_fasebilelabid;
    RETURN;
  END;
  $BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  
CREATE OR REPLACE FUNCTION fnc_fasi_bil_gest_apertura_pluri_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  tipocapitologest varchar,
  tipomovgest varchar,
  tipomovgestts varchar,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
    strMessaggioTemp VARCHAR(1000):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    movGestTsTipoId    integer:=null;
    tipoMovGestTsSId   integer:=null;
    tipoMovGestTsTId   integer:=null;
    tipoCapitoloGestId integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;
    dataEmissione     timestamp:=null;
	movGestIdRet      integer:=null;
    movGestTsIdRet    integer:=null;
    elemNewId         integer:=null;
	movGestTsTipoTId  integer:=null;
	movGestTsTipoSId  integer:=null;
	movGestTsTipoCode VARCHAR(10):=null;
    movGestStatoAId   integer:=null;

    movGestRec        record;
    aggProgressivi    record;


	movgestTsTipoDetIniz integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetAtt  integer; -- 29.01.2018 Sofia siac-5830
    movgestTsTipoDetUtil integer; -- 29.01.2018 Sofia siac-5830

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';
	SIM_MOVGEST_TS_TIPO CONSTANT varchar:='SIM';
    SAC_MOVGEST_TS_TIPO CONSTANT varchar:='SAC';


    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    APE_GEST_PLURI    CONSTANT varchar:='APE_GEST_PLURI';
    A_MOV_GEST_STATO  CONSTANT varchar:='A';

	-- 14.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    INIZ_MOVGEST_TS_DET_TIPO  constant varchar:='I'; -- 29.01.2018 Sofia siac-5830
    ATT_MOVGEST_TS_DET_TIPO   constant varchar:='A'; -- 29.01.2018 Sofia siac-5830
    UTI_MOVGEST_TS_DET_TIPO   constant varchar:='U'; -- 29.01.2018 Sofia siac-5830

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;

    raise notice 'fnc_fasi_bil_gest_apertura_pluri_elabora tipoCapitoloGest=%',tipoCapitoloGest;

	if tipoMovGest=IMP_MOVGEST_TIPO then
    	 movGestTsTipoCode=SIM_MOVGEST_TS_TIPO;
    else movGestTsTipoCode=SAC_MOVGEST_TS_TIPO;
    end if;

    dataInizioVal:= clock_timestamp();
--    dataEmissione:=((annoBilancio-1)::varchar||'-12-31')::timestamp; -- da capire che data impostare come data emissione
    -- 23.08.2016 Sofia in attesa di indicazioni diverse ho deciso di impostare il primo di gennaio del nuovo anno di bilancio
    dataEmissione:=(annoBilancio::varchar||'-01-01')::timestamp;
--    raise notice 'fasbilElabId %',faseBilElabId;
	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  pluriennali da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora tipoMovGest='||tipoMovGest||' minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
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
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_pluri.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_pluri fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;
    if codResult is null then
      raise exception ' Nessuna movimento da creare.';
    end if;


    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_pluri].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_pluri_id) into maxId
        from fase_bil_t_gest_apertura_pluri fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null;
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;


     strMessaggio:='Lettura id identificativo per tipo capitolo='||tipoCapitoloGest||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=tipoCapitoloGest
     and   tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.data_cancellazione is null
     and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
     and   ( date_trunc('day',dataElaborazione)<=date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);



	 strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioPrecId, periodoPrecId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio-1
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;

     strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
     select stato.movgest_stato_id into strict movGestStatoAId
     from siac_d_movgest_stato stato
     where stato.ente_proprietario_id=enteProprietarioId
     and   stato.movgest_stato_code=A_MOV_GEST_STATO
     and   stato.data_cancellazione is null
     and   stato.validita_fine is null;

     -- per I,A
     strMessaggio:='Lettura id identificativo per tipoMovGest='||tipoMovGest||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=tipoMovGest
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;





     strMessaggio:='Lettura identificativo per tipoMovGestTsT='||MOVGEST_TS_T_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsTId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     strMessaggio:='Lettura identificativo per tipoMovGestTsS='||MOVGEST_TS_S_TIPO||'.';
     select tipo.movgest_ts_tipo_id into strict tipoMovGestTsSId
     from siac_d_movgest_ts_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_tipo_code=MOVGEST_TS_S_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;

     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
          movGestTsTipoId:=tipoMovGestTsTId;
     else movGestTsTipoId:=tipoMovGestTsSId;
     end if;

     if movGestTsTipoId is null then
      strMessaggio:='Lettura identificativo per tipoMovGestTs='||tipoMovGestTs||'.';
      select tipo.movgest_ts_tipo_id into strict movGestTsTipoId
      from siac_d_movgest_ts_tipo tipo
      where tipo.ente_proprietario_id=enteProprietarioId
      and   tipo.movgest_ts_tipo_code=tipoMovGestTs
      and   tipo.data_cancellazione is null
      and   tipo.validita_fine is null;
     end if;


	 -- 14.02.2017 Sofia SIAC-4425
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
     	select attr.attr_id into strict flagFrazAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FRAZIONABILE_ATTR
        and   attr.data_cancellazione is null
        and   attr.validita_fine is null;
     end if;

	 -- 29.01.2018 Sofia siac-5830
     strMessaggio:='Lettura identificativo per tipo importo='||INIZ_MOVGEST_TS_DET_TIPO||'.';
     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetIniz
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=INIZ_MOVGEST_TS_DET_TIPO;

     strMessaggio:='Lettura identificativo per tipo importo='||ATT_MOVGEST_TS_DET_TIPO||'.';

     select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetAtt
     from siac_d_movgest_ts_det_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_ts_det_tipo_code=ATT_MOVGEST_TS_DET_TIPO;

--	 if tipoMovGest=ACC_MOVGEST_TIPO then
     	 strMessaggio:='Lettura identificativo per tipo importo='||UTI_MOVGEST_TS_DET_TIPO||'.';
		 select tipo.movgest_ts_det_tipo_id into strict movgestTsTipoDetUtil
    	 from siac_d_movgest_ts_det_tipo tipo
	     where tipo.ente_proprietario_id=enteProprietarioId
    	 and   tipo.movgest_ts_det_tipo_code=UTI_MOVGEST_TS_DET_TIPO;
  --   end if;
     -- 29.01.2018 Sofia siac-5830



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

     -- se impegno-accertamento verifico che i relativi capitoli siano presenti sul nuovo Bilancio
     if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. INIZIO.';
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

        update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='IMAC1',
            scarto_desc='Movimento impegno/accertamento pluriennale privo di capitolo nel nuovo bilancio'
      	from siac_t_bil_elem elem
      	where fase.fase_bil_elab_id=faseBilElabId
      	and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      	and   fase.movgest_tipo=movGestTsTipoCode
     	and   fase.fl_elab='N'
        and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
     	and   elem.ente_proprietario_id=fase.ente_proprietario_id
        and   elem.elem_id=fase.elem_orig_id
    	and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
     	and   elem.data_cancellazione is null
     	and   elem.validita_fine is null
        and   not exists (select 1 from siac_t_bil_elem elemnew
                          where elemnew.ente_proprietario_id=elem.ente_proprietario_id
                          and   elemnew.elem_tipo_id=elem.elem_tipo_id
                          and   elemnew.bil_id=bilancioId
                          and   elemnew.elem_code=elem.elem_code
                          and   elemnew.elem_code2=elem.elem_code2
                          and   elemnew.elem_code3=elem.elem_code3
                          and   elemnew.data_cancellazione is null
                          and   elemnew.validita_fine is null
                         );


        strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti movimenti privi di relativo capitolo nel nuovo bilancio. FINE.';
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

     end if;
     -- se sub, verifico prima se i relativi padri sono stati elaborati e creati
     -- se non sono stati ribaltati scarto  i relativi sub per escluderli da elaborazione

     if tipoMovGestTs=MOVGEST_TS_S_TIPO then
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. INIZIO.';
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

      update fase_bil_t_gest_apertura_pluri fase
      set fl_elab='X',
          scarto_code='SUB1',
          scarto_desc='Movimento sub impegno/accertamento pluriennale privo di impegno/accertamento pluri nel nuovo bilancio'
      from siac_t_movgest mprec
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   fase.movgest_tipo=movGestTsTipoCode
      and   fase.fl_elab='N'
      and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
      and   mprec.ente_proprietario_id=fase.ente_proprietario_id
      and   mprec.movgest_id=fase.movgest_orig_id
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   mprec.data_cancellazione is null
      and   mprec.validita_fine is null
      and   not exists (select 1 from siac_t_movgest mnew
                        where mnew.ente_proprietario_id=mprec.ente_proprietario_id
                        and   mnew.movgest_tipo_id=mprec.movgest_tipo_id
                        and   mnew.bil_id=bilancioId
                        and   mnew.movgest_anno=mprec.movgest_anno
                        and   mnew.movgest_numero=mprec.movgest_numero
                        and   mnew.data_cancellazione is null
                        and   mnew.validita_fine is null
                        );
      strMessaggio:='Aggiornamento fase_bil_t_gest_apertura_pluri per scarti sub privi di relativo padre ribaltato. FINE.';
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

     end if;

     strMessaggio:='Inizio ciclo per tipoMovGest='||tipoMovGest||' tipoMovGestTs='||tipoMovGestTs||'.';
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


     for movGestRec in
     (select tipo.movgest_tipo_code,
     		 m.*,
             tstipo.movgest_ts_tipo_code,
             ts.*,
             fase.fase_bil_gest_ape_pluri_id,
             fase.movgest_orig_id,
             fase.movgest_orig_ts_id,
             fase.elem_orig_id,
             mpadre.movgest_id movgest_id_new,
             tspadre.movgest_ts_id movgest_ts_id_padre_new
      from  fase_bil_t_gest_apertura_pluri fase
             join siac_t_movgest m
               left outer join
               ( siac_t_movgest mpadre join  siac_t_movgest_ts tspadre
                   on (tspadre.movgest_id=mpadre.movgest_id
                   and tspadre.movgest_ts_tipo_id=tipoMovGestTsTId
                   and tspadre.data_cancellazione is null
                   and tspadre.validita_fine is null)
                )
                on (mpadre.movgest_anno=m.movgest_anno
                and mpadre.movgest_numero=m.movgest_numero
                and mpadre.bil_id=bilancioId
                and mpadre.ente_proprietario_id=m.ente_proprietario_id
                and mpadre.movgest_tipo_id = tipoMovGestId
                and mpadre.data_cancellazione is null
                and mpadre.validita_fine is null)
             on   ( m.ente_proprietario_id=fase.ente_proprietario_id  and   m.movgest_id=fase.movgest_orig_id),
            siac_d_movgest_tipo tipo,
            siac_t_movgest_ts ts,
            siac_d_movgest_ts_tipo tstipo
      where fase.fase_bil_elab_id=faseBilElabId
          and   tipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tipo.movgest_tipo_code=tipoMovGest
          and   tstipo.ente_proprietario_id=fase.ente_proprietario_id
          and   tstipo.movgest_ts_tipo_code=tipoMovGestTs
          and   m.ente_proprietario_id=fase.ente_proprietario_id
          and   m.movgest_id=fase.movgest_orig_id
          and   m.movgest_tipo_id=tipo.movgest_tipo_id
          and   ts.ente_proprietario_id=fase.ente_proprietario_id
          and   ts.movgest_ts_id=fase.movgest_orig_ts_id
          and   ts.movgest_ts_tipo_id=tstipo.movgest_ts_tipo_id
          and   fase.fase_bil_gest_ape_pluri_id between minId and maxId
          and   fase.fl_elab='N'
          and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          order by fase_bil_gest_ape_pluri_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        codResult:=null;
		elemNewId:=null;

        strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
         raise notice 'strMessaggio=%  movGestRec.movgest_id_new=%', strMessaggio, movGestRec.movgest_id_new;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

    	codResult:=null;
        if movGestRec.movgest_id_new is null then
      	 strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                       ' anno='||movGestRec.movgest_anno||
                       ' numero='||movGestRec.movgest_numero||' [siac_t_movgest].';
     	 insert into siac_t_movgest
         (movgest_anno,
		  movgest_numero,
		  movgest_desc,
		  movgest_tipo_id,
		  bil_id,
		  validita_inizio,
	      ente_proprietario_id,
	      login_operazione,
	      parere_finanziario,
	      parere_finanziario_data_modifica,
	      parere_finanziario_login_operazione)
         values
         (movGestRec.movgest_anno,
		  movGestRec.movgest_numero,
		  movGestRec.movgest_desc,
		  movGestRec.movgest_tipo_id,
		  bilancioId,
		  dataInizioVal,
	      enteProprietarioId,
	      loginOperazione,
	      movGestRec.parere_finanziario,
	      movGestRec.parere_finanziario_data_modifica,
	      movGestRec.parere_finanziario_login_operazione
         )
         returning movgest_id into movGestIdRet;
         if movGestIdRet is null then
           strMessaggioTemp:=strMessaggio;
           codResult:=-1;
         end if;
			raise notice 'dopo inserimento siac_t_movgest movGestIdRet=%',movGestIdRet;
		 if codResult is null then
         strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';

         raise notice 'strMessaggio=%',strMessaggio;

         select  new.elem_id into elemNewId
         from siac_r_movgest_bil_elem r,
              siac_t_bil_elem prec, siac_t_bil_elem new
         where r.movgest_id=movGestRec.movgest_orig_id
         and   prec.elem_id=r.elem_id
         and   new.elem_code=prec.elem_code
         and   new.elem_code2=prec.elem_code2
         and   new.elem_code3=prec.elem_code3
         and   prec.elem_tipo_id=new.elem_tipo_id
         and   prec.bil_id=bilancioPrecId
         and   new.bil_id=bilancioId
         and   r.data_cancellazione is null
         and   r.validita_fine is null
         and   prec.data_cancellazione is null
         and   prec.validita_fine is null
         and   new.data_cancellazione is null
         and   new.validita_fine is null;
         if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
         end if;
		 raise notice 'elemNewId=%',elemNewId;
		 if codResult is null then
          	  strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
             	            ' anno='||movGestRec.movgest_anno||
                 	        ' numero='||movGestRec.movgest_numero||' [siac_r_movgest_bil_elem]';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   elemNewId,
	           dataInizioVal,
    	       enteProprietarioId,
        	   loginOperazione
		       )
    	       returning movgest_atto_amm_id into codResult;
        	   if codResult is null then
            	codResult:=-1;
	            strMessaggioTemp:=strMessaggio;
               else codResult:=null;
    	       end if;
         end if;
        end if;
      else
        movGestIdRet:=movGestRec.movgest_id_new;
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||'. Lettura elem_id bilancio corrente.';
        select  r.elem_id into elemNewId
        from siac_r_movgest_bil_elem r
        where r.movgest_id=movGestIdRet
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if elemNewId is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;
      end if;


      if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts].';
		raise notice 'strMessaggio=% ',strMessaggio;
        dataEmissione:=( (2018::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;
        raise notice 'dataEmissione=% ',dataEmissione;
        insert into siac_t_movgest_ts
        ( movgest_ts_code,
          movgest_ts_desc,
          movgest_id,
	      movgest_ts_tipo_id,
          movgest_ts_id_padre,
          movgest_ts_scadenza_data,
	      ordine,
		  livello,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione,
	      login_creazione,
		  siope_tipo_debito_id,
		  siope_assenza_motivazione_id

        )
        values
        ( movGestRec.movgest_ts_code,
          movGestRec.movgest_ts_desc,
          movGestIdRet,    -- inserito se I/A, per SUB ricavato
          movGestRec.movgest_ts_tipo_id,
          movGestRec.movgest_ts_id_padre_new,  -- valorizzato se SUB
          movGestRec.movgest_ts_scadenza_data,
          movGestRec.ordine,
          movGestRec.livello,
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataInizioVal else dataEmissione end), -- 25.11.2016 Sofia
--          (case when tipoMovGestTs=MOVGEST_TS_T_TIPO then dataEmissione else dataInizioVal end), -- 25.11.2016 Sofia
--          dataEmissione, -- 12.04.2017 Sofia
          dataEmissione,   -- 09.02.2018 Sofia
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          movGestRec.siope_tipo_debito_id,
		  movGestRec.siope_assenza_motivazione_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;
        raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;
       -- siac_r_liquidazione_movgest --> x pluriennali non dovrebbe esserci legame e andrebbe ricreato cmq con il ribaltamento delle liq
       -- siac_r_ordinativo_ts_movgest_ts --> x pluriennali non dovrebbe esistere legame in ogni caso non deve essere  ribaltato
       -- siac_r_movgest_ts --> legame da creare alla conclusione del ribaltamento dei pluriennali e dei residui

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_ts_stato].';

        insert into siac_r_movgest_ts_stato
        ( movgest_ts_id,
          movgest_stato_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_stato_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_stato r, siac_d_movgest_stato stato
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   stato.movgest_stato_id=r.movgest_stato_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   stato.data_cancellazione is null
          and   stato.validita_fine is null
         )
        returning movgest_stato_r_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
        raise notice 'dopo inserimento siac_r_movgest_ts_stato movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_t_movgest_ts_det
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        -- 29.01.2018 Sofia siac-5830 - insert sostituita con le tre successive


        /*insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );*/
        --returning movgest_ts_det_id into  codResult;

        -- 29.01.2018 Sofia siac-5830 - iniziale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetIniz,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - attuale = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_ts_det_tipo_id,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

        -- 29.01.2018 Sofia siac-5830 - utilizzabile = attuale
        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           movgestTsTipoDetUtil,
           r.movgest_ts_det_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_t_movgest_ts_det r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.movgest_ts_det_tipo_id=movgestTsTipoDetAtt
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

		select 1 into codResult
        from siac_t_movgest_ts_det det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_t_movgest_ts_det movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_class
       if codResult is null then
   	   strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                     ' anno='||movGestRec.movgest_anno||
                     ' numero='||movGestRec.movgest_numero||
                     ' movGestTipoTs='||tipoMovGestTs||
                     ' sub='||movGestRec.movgest_ts_code||
                     ' [siac_r_movgest_class].';

        insert into siac_r_movgest_class
        ( movgest_ts_id,
          classif_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.classif_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_class r, siac_t_class class
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   class.classif_id=r.classif_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   class.data_cancellazione is null
          and   class.validita_fine is null
         );
--        returning movgest_classif_id into  codResult;

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;


        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_attr].';

        insert into siac_r_movgest_ts_attr
        ( movgest_ts_id,
          attr_id,
          tabella_id,
		  boolean,
	      percentuale,
		  testo,
	      numerico,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
          movGestTsIdRet,
          r.attr_id,
          r.tabella_id,
		  r.boolean,
	      r.percentuale,
		  r.testo,
	      r.numerico,
          dataInizioVal,
          enteProprietarioId,
          loginOperazione
          from siac_r_movgest_ts_attr r, siac_t_attr attr
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   attr.attr_id=r.attr_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          and   attr.data_cancellazione is null
          and   attr.validita_fine is null
         );
        --returning bil_elem_attr_id into  codResult;

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_atto_amm].';

        insert into siac_r_movgest_ts_atto_amm
        ( movgest_ts_id,
          attoamm_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.attoamm_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm atto
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   atto.attoamm_id=r.attoamm_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         -- and   atto.data_cancellazione is null 15.02.2017 Sofia HD-INC000001535447
         -- and   atto.validita_fine is null
         );

        /*select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        --returning movgest_atto_amm_id into  codResult;
        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
         end if;
       end if;*/

       -- se movimento provvisorio atto_amm potrebbe non esserci
	   select 1  into codResult
       from siac_r_movgest_ts_atto_amm det1
       where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
       and   det1.data_cancellazione is null
       and   det1.validita_fine is null
       and   not exists (select 1 from siac_r_movgest_ts_atto_amm det
			             where det.movgest_ts_id=movGestTsIdRet
					       and   det.data_cancellazione is null
					       and   det.validita_fine is null
					       and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sog].';

        insert into siac_r_movgest_ts_sog
        ( movgest_ts_id,
          soggetto_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sog r,siac_t_soggetto sogg
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sogg.soggetto_id=r.soggetto_id
          and   sogg.data_cancellazione is null
          and   sogg.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning movgest_ts_sog_id into  codResult;

        /*select 1 into codResult
        from siac_r_movgest_ts_sog det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

 		select 1  into codResult
        from siac_r_movgest_ts_sog det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sog det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_sogclasse].';

        insert into siac_r_movgest_ts_sogclasse
        ( movgest_ts_id,
          soggetto_classe_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.soggetto_classe_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_sogclasse r,siac_d_soggetto_classe classe
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   classe.soggetto_classe_id=r.soggetto_classe_id
          and   classe.data_cancellazione is null
          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning soggetto_classe_id into  codResult;

        select 1  into codResult
        from siac_r_movgest_ts_sogclasse det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_sogclasse det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_programma
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_programma].';

        insert into siac_r_movgest_ts_programma
        ( movgest_ts_id,
          programma_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.programma_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_programma r,siac_t_programma prog
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   prog.programma_id=r.programma_id
          and   prog.data_cancellazione is null
          and   prog.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning movgest_ts_programma_id into  codResult;
        /*select 1 into codResult
        from siac_r_movgest_ts_programma det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_movgest_ts_programma det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_programma det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_mutuo_voce_movgest
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_mutuo_voce_movgest].';

        insert into siac_r_mutuo_voce_movgest
        ( movgest_ts_id,
          mut_voce_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.mut_voce_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_mutuo_voce_movgest r,siac_t_mutuo_voce voce
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   voce.mut_voce_id=r.mut_voce_id
          and   voce.data_cancellazione is null
          and   voce.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning mut_voce_movgest_id into  codResult;

        /*select 1 into codResult
        from siac_r_mutuo_voce_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_mutuo_voce_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_voce_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa economale - da non ricreare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_giustificativo_movgest].';

        insert into siac_r_giustificativo_movgest
        ( movgest_ts_id,
          gst_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.gst_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_giustificativo_movgest r,siac_t_giustificativo gst
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   gst.gst_id=r.gst_id
          and   gst.data_cancellazione is null
          and   gst.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning gstmovgest_id into  codResult;

    /*    select 1 into codResult
        from siac_r_giustificativo_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_giustificativo_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_giustificativo_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_cartacont_det_movgest_ts].';

        insert into siac_r_cartacont_det_movgest_ts
        ( movgest_ts_id,
          cartac_det_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.cartac_det_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_cartacont_det_movgest_ts r,siac_t_cartacont_det carta
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   carta.cartac_det_id=r.cartac_det_id
          and   carta.data_cancellazione is null
          and   carta.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_cartacont_det_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/


		select 1  into codResult
        from siac_r_cartacont_det_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_cartacont_det_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_causale_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_causale_movgest_ts
        ( movgest_ts_id,
          caus_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.caus_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_causale_movgest_ts r,siac_d_causale caus
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   caus.caus_id=r.caus_id
          and   caus.data_cancellazione is null
          and   caus.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning caus_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_causale_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_causale_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_causale_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_fondo_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_causale_movgest_ts].';

        insert into siac_r_fondo_econ_movgest
        ( movgest_ts_id,
          fondoecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.fondoecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_fondo_econ_movgest r,siac_t_fondo_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.fondoecon_id=r.fondoecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning liq_movgest_id into  codResult;

       /* select 1 into codResult
        from siac_r_fondo_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_fondo_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_fondo_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_richiesta_econ_movgest
       /* cassa economale - da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_richiesta_econ_movgest].';

        insert into siac_r_richiesta_econ_movgest
        ( movgest_ts_id,
          ricecon_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.ricecon_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_richiesta_econ_movgest r,siac_t_richiesta_econ econ
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   econ.ricecon_id=r.ricecon_id
          and   econ.data_cancellazione is null
          and   econ.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning riceconsog_id into  codResult;

       /* select 1 into codResult
        from siac_r_richiesta_econ_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_richiesta_econ_movgest det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_richiesta_econ_movgest det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_subdoc_movgest_ts].';

        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning subdoc_movgest_ts_id into  codResult;

       /* select 1 into codResult
        from siac_r_subdoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_predoc_movgest_ts].';

        insert into siac_r_predoc_movgest_ts
        ( movgest_ts_id,
          predoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.predoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_predoc_movgest_ts r,siac_t_predoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.predoc_id=r.predoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );
        --returning predoc_movgest_ts_id into  codResult;

        /*select 1 into codResult
        from siac_r_predoc_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- cancellazione logica relazioni anno precedente
       -- siac_r_cartacont_det_movgest_ts
/*  non si gestisce in seguito ad indicazioni con Annalina
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' . Cancellazione siac_r_cartacont_det_movgest_ts anno bilancio precedente.';

        update siac_r_cartacont_det_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_cartacont_det_movgest_ts r,	siac_t_cartacont_det carta
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   carta.cartac_det_id=r.cartac_det_id
        and   carta.data_cancellazione is null
        and   carta.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        if codResult is not null then
        	 strMessaggioTemp:=strMessaggio;
        	 codResult:=-1;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
             strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/


       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_pluri per scarto
	   if codResult=-1 then
       	/*if movGestRec.movgest_id_new is null then
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        end if; spostato sotto */

        if movGestTsIdRet is not null then
         -- siac_t_movgest_ts
 	    /*strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet; spostato sotto */

         -- siac_r_movgest_class
	     strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_class.';
         delete from siac_r_movgest_class    where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_attr
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_attr     where movgest_ts_id=movGestTsIdRet;
		 -- siac_r_movgest_ts_atto_amm
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_attr.';
         delete from siac_r_movgest_ts_atto_amm     where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_stato
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_stato.';
         delete from siac_r_movgest_ts_stato     where movgest_ts_id=movGestTsIdRet;
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sog.';
         delete from siac_r_movgest_ts_sog      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_sogclasse
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_sogclasse.';
         delete from siac_r_movgest_ts_sogclasse      where movgest_ts_id=movGestTsIdRet;
         -- siac_t_movgest_ts_det
		 strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_t_movgest_ts_det.';
         delete from siac_t_movgest_ts_det      where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma where movgest_ts_id=movGestTsIdRet;
         -- siac_r_mutuo_voce_movgest
/*
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_mutuo_voce_movgest.';
         delete from siac_r_mutuo_voce_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_giustificativo_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_giustificativo_movgest.';
         delete from siac_r_giustificativo_movgest where movgest_ts_id=movGestTsIdRet;
         -- siac_r_cartacont_det_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_cartacont_det_movgest_ts.';
         delete from siac_r_cartacont_det_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- siac_r_fondo_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_fondo_econ_movgest.';
         delete from siac_r_fondo_econ_movgest where movgest_ts_id=movGestTsIdRet;
	     -- siac_r_richiesta_econ_movgest
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_richiesta_econ_movgest.';
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet;*/
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if movGestRec.movgest_id_new is null then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;


        /*strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';*/
	    strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_pluri per scarto.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='X',
            scarto_code='PLUR1',
            scarto_desc='Movimento impegno/accertamento sub  pluriennale non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

		continue;
       end if;

	   -- annullamento relazioni movimenti precedenti
       -- siac_r_subdoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_subdoc_movgest_ts anno bilancio precedente.';
        update siac_r_subdoc_movgest_ts r
        set data_cancellazione=dataElaborazione,
            validita_fine=dataElaborazione,
            login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;

        select 1 into codResult
        from   siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null;
        if codResult is not null then
        	 codResult:=-1;
             --strMessaggioTemp:=strMessaggio;
             raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   -- siac_r_predoc_movgest_ts
       if codResult is null then
        strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      '. Cancellazione siac_r_predoc_movgest_ts anno bilancio precedente.';
        update siac_r_predoc_movgest_ts r
        set  data_cancellazione=dataElaborazione,
             validita_fine=dataElaborazione,
             login_operazione=r.login_operazione||'-'||loginOperazione
       	from siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        select 1 into codResult
        from siac_r_predoc_movgest_ts r,siac_t_predoc sub
        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   sub.predoc_id=r.predoc_id
        and   sub.data_cancellazione is null
        and   sub.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

		if codResult is not null then
             codResult:=-1;
--             strMessaggioTemp:=strMessaggio;
               raise exception ' Errore in aggiornamento.';
        else codResult:=null;
        end if;
       end if;

	   strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'. Aggiornamento fase_bil_t_gest_apertura_pluri per fine elaborazione.';
      	update fase_bil_t_gest_apertura_pluri fase
        set fl_elab='S',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet,
            elem_id=elemNewId,
            bil_id=bilancioId
        where fase.fase_bil_gest_ape_pluri_id=movGestRec.fase_bil_gest_ape_pluri_id;

       strMessaggio:='Movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTsTipo='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||'.';
       codResult:=null;
	   insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

     end loop;


     -- aggiornamento progressivi
	 if tipoMovGestTs=MOVGEST_TS_T_TIPO then
     	 strMessaggio:='Aggiornamento progressivi.';
		 select * into aggProgressivi
   		 from fnc_aggiorna_progressivi(enteProprietarioId, tipoMovGest, loginOperazione);
	     if aggProgressivi.codresult=-1 then
			RAISE EXCEPTION ' % ', aggProgressivi.messaggioRisultato;
     	 end if;
     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     if tipoMovGest=IMP_MOVGEST_TIPO and tipoMovGestTs=MOVGEST_TS_T_TIPO then
        -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni pluriennali.';
     	INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'N',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio)
        and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null);

        -- insert S per impegni mov.movgest_anno::integer=annoBilancio
        -- che non hanno ancora attributo
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore S per impegni di competenza senza atto amministrativo antecedente.';
		INSERT INTO siac_r_movgest_ts_attr
		(
		  movgest_ts_id,
		  attr_id,
		  boolean,
		  validita_inizio,
		  ente_proprietario_id,
		  login_operazione
		)
		select ts.movgest_ts_id,
		       flagFrazAttrId,
               'S',
		       dataInizioVal,
		       ts.ente_proprietario_id,
		       loginOperazione
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::integer=annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   not exists (select 1 from siac_r_movgest_ts_attr r1
        		          where r1.movgest_ts_id=ts.movgest_ts_id
                          and   r1.attr_id=flagFrazAttrId
                          and   r1.data_cancellazione is null
                          and   r1.validita_fine is null)
        and  not exists (select 1 from siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
						 where ra.movgest_ts_id=ts.movgest_ts_id
						 and   atto.attoamm_id=ra.attoamm_id
				 		 and   atto.attoamm_anno::integer < annoBilancio
		     			 and   ra.data_cancellazione is null
				         and   ra.validita_fine is null);

        -- aggiornamento N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
        -- -- essendo pluriennali consideriamo solo mov.movgest_anno::integer>annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni pluriennali.';
		update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts
		where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
		and   mov.movgest_anno::integer>annoBilancio
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        -- aggiornamento N per impegni mov.movgest_anno::integer=annoBilancio e atto.attoamm_anno::integer < annoBilancio
        -- che  hanno  attributo ='S'
        strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atto amministrativo antecedente.';
        update  siac_r_movgest_ts_attr r set boolean='N'
		from siac_t_movgest mov, siac_t_movgest_ts ts,
		     siac_r_movgest_ts_atto_amm ra,siac_t_atto_amm atto
		where mov.bil_id=bilancioId
		and   mov.movgest_anno::INTEGER=2017
		and   mov.movgest_tipo_id=tipoMovGestId
		and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
		and   r.movgest_ts_id=ts.movgest_ts_id
        and   r.attr_id=flagFrazAttrId
		and   ra.movgest_ts_id=ts.movgest_ts_id
		and   atto.attoamm_id=ra.attoamm_id
		and   atto.attoamm_anno::integer < annoBilancio
		and   r.boolean='S'
        and   r.data_cancellazione is null
        and   r.validita_fine is null
        and   ra.data_cancellazione is null
        and   ra.validita_fine is null;

     end if;

     -- 14.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile


     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PLURI||' IN CORSO IN-2.'
     where fase_bil_elab_id=faseBilElabId;


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



-- SIAC-5882 Sofia 13.02.2018  - FINE 

-- SIAC-5623 - INIZIO

INSERT INTO siac.siac_t_azione (azione_code, azione_desc, azione_tipo_id, gruppo_azioni_id, urlapplicazione, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.azcode, tmp.azdesc, ta.azione_tipo_id, ga.gruppo_azioni_id, '/../siacbilapp/azioneRichiesta.do', to_timestamp('01/01/2013','dd/mm/yyyy'), e.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario e
JOIN siac_d_azione_tipo ta ON (ta.ente_proprietario_id = e.ente_proprietario_id)
JOIN siac_d_gruppo_azioni ga ON (ga.ente_proprietario_id = e.ente_proprietario_id)
CROSS JOIN (VALUES
	('OP-CEC-abilitaRimborsoSpese', 'Abilitazione richiesta economale rimborso spese'),
	('OP-CEC-abilitaPagamentoFatture', 'Abilitazione richiesta economale pagamento fatture'),
	('OP-CEC-abilitaAnticipoSpese', 'Abilitazione richiesta economale anticipo spese'),
	('OP-CEC-abilitaAnticipoPerTrasfertaDipendenti', 'Abilitazione richiesta economale anticipo per trasferta dipendenti'),
	('OP-CEC-abilitaAnticipoSpesePerMissione', 'Abilitazione richiesta economale anticipo spese per missione'),
	('OP-CEC-abilitaPagamento', 'Abilitazione richiesta economale pagamento')
) AS tmp(azcode, azdesc)
WHERE ta.azione_tipo_code = 'AZIONE_SECONDARIA'
AND ga.gruppo_azioni_code = 'CASSA ECONOMALE'
AND NOT EXISTS (
	SELECT 1
	FROM siac_t_azione z
	WHERE z.azione_tipo_id = ta.azione_tipo_id
	AND z.azione_code = tmp.azcode
)
ORDER BY e.ente_proprietario_id, tmp.azcode;

-- SIAC-5623 - FINE
-- SIAC-5883 - DANIELA
CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_impegno (
  p_anno_bilancio varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
)
RETURNS TABLE (
  esito varchar
) AS
$body$
begin

IF p_data IS NULL THEN
   IF p_anno_bilancio::integer < to_char(now(),'YYYY')::integer THEN
      p_data = to_timestamp('31/12/'||p_anno_bilancio, 'dd/mm/yyyy');
   ELSE
      p_data := now();
   END IF;
END IF;

delete from siac_dwh_impegno where
ente_proprietario_id=p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
delete from siac_dwh_subimpegno where
ente_proprietario_id=p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;

INSERT INTO
  siac.siac_dwh_impegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_impegno,  cod_stato_impegno,  desc_stato_impegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,
  flagdariaccertamento,
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,
  importo_iniziale,  importo_attuale,  importo_utilizzabile,
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,
  flagcassaeconomale,  data_inizio_val_stato_imp,  data_inizio_val_imp,
  data_creazione_imp,  data_modifica_imp,
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo,
  cod_programma, desc_programma,
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit
  )
select
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc,
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data,
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario
,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc,
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_desc,xx.cla11_classif_code,xx.cla11_classif_desc,
xx.cla12_classif_tipo_desc,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_desc,xx.cla13_classif_code,xx.cla13_classif_desc,
xx.cla14_classif_tipo_desc,xx.cla14_classif_code,xx.cla14_classif_desc,
xx.cla15_classif_tipo_desc,xx.cla15_classif_code,xx.cla15_classif_desc,
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc,
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale,
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_imp,
xx.data_creazione_imp, xx.data_modifica_imp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.programma_code, xx.programma_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
 from (
with imp as (
SELECT
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc,
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id,
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp,
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp,
       b.validita_inizio as data_inizio_val_imp,
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
, siac_t_movgest b
, siac_t_bil c
, siac_t_periodo d
, siac_t_ente_proprietario e
, siac_d_movgest_tipo f
, siac_d_movgest_ts_tipo g
, siac_r_movgest_ts_stato h
, siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and
 b.bil_id = c.bil_id and
 d.periodo_id = c.periodo_id and
 e.ente_proprietario_id = b.ente_proprietario_id   and
 b.movgest_tipo_id = f.movgest_tipo_id and
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and
 h.movgest_ts_id = a.movgest_ts_id   and
 h.movgest_stato_id = i.movgest_stato_id
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I'
--AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND c.data_cancellazione IS NULL
AND d.data_cancellazione IS NULL
AND e.data_cancellazione IS NULL
AND f.data_cancellazione IS NULL
AND g.data_cancellazione IS NULL
AND h.data_cancellazione IS NULL
AND i.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
AND c.validita_fine IS NULL
AND d.validita_fine IS NULL
AND e.validita_fine IS NULL
AND f.validita_fine IS NULL
AND g.validita_fine IS NULL
AND h.validita_fine IS NULL
AND i.validita_fine IS NULL
)
, cap as (
select l.movgest_id
,m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND l.data_cancellazione IS NULL
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL
AND m.validita_fine IS NULL
),
sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale,
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto,
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
--classificatori non gerarchici
tipoimpegno as (
SELECT
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc,
c.classif_tipo_desc cla11_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
-- AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc,
c.classif_tipo_desc cla12_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc,
c.classif_tipo_desc cla13_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc,
c.classif_tipo_desc cla14_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc,
c.classif_tipo_desc cla15_classif_tipo_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroArticoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaRiaccertamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroUEBOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroUEBOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_MOVGEST' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='validato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroAccFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagCassaEconomale' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazione' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazioneLiquidabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagFrazionabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
,
atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null
and a.validita_fine is null
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b,
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id
    AND   a.liq_id = b.liq_id
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
    AND a.data_cancellazione IS NULL
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL
    AND d.validita_fine IS NULL
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id)
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato,
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id
left join quiet ON
liquid.liq_id=quiet.liq_id
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_movgest_class r,
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
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- SIAC-5883 FINE Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, progetto as (
select rmtp.movgest_ts_id, tp.programma_code, tp.programma_desc
from   siac_r_movgest_ts_programma rmtp, siac_t_programma tp
where  rmtp.programma_id = tp.programma_id
--and    p_data BETWEEN rmtp.validita_inizio and COALESCE(rmtp.validita_fine,p_data)
--and    p_data BETWEEN tp.validita_inizio and COALESCE(tp.validita_fine,p_data)
and    rmtp.data_cancellazione IS NULL
and    tp.data_cancellazione IS NULL
and    rmtp.validita_fine IS NULL
and    tp.validita_fine IS NULL
)
select
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc,
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2,
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp,
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp,
imp.data_inizio_val_imp,
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale,
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc,
cla11.cla11_classif_tipo_desc,
cla12.cla12_classif_code,
cla12.cla12_classif_desc,
cla12.cla12_classif_tipo_desc,
cla13.cla13_classif_code,
cla13.cla13_classif_desc,
cla13.cla13_classif_tipo_desc,
cla14.cla14_classif_code,
cla14.cla14_classif_desc,
cla14.cla14_classif_tipo_desc,
cla15.cla15_classif_code,
cla15.cla15_classif_desc,
cla15.cla15_classif_tipo_desc,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
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
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
progetto.programma_code, progetto.programma_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit
from
imp left join cap
on
imp.movgest_id=cap.movgest_id
left join sogg
on
imp.movgest_ts_id=sogg.movgest_ts_id
left join sogcla
on
imp.movgest_ts_id=sogcla.movgest_ts_id
left join tipoimpegno
on
imp.movgest_ts_id=tipoimpegno.movgest_ts_id
left join ricorrentespesa
on
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id
left join truespesa
on
imp.movgest_ts_id=truespesa.movgest_ts_id
left join persaspesa
on
imp.movgest_ts_id=persaspesa.movgest_ts_id
left join polregunitarie
on
imp.movgest_ts_id=polregunitarie.movgest_ts_id
left join cla11
on
imp.movgest_ts_id=cla11.movgest_ts_id
left join cla12
on
imp.movgest_ts_id=cla12.movgest_ts_id
left join cla13
on
imp.movgest_ts_id=cla13.movgest_ts_id
left join cla14
on
imp.movgest_ts_id=cla14.movgest_ts_id
left join cla15
on
imp.movgest_ts_id=cla15.movgest_ts_id
left join t_annoCapitoloOrigine
on
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id
left join t_numeroCapitoloOrigine
on
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id
left join t_annoOriginePlur
on
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id
left join t_annoRiaccertato
on
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id
left join t_numeroRiaccertato
on
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id
left join t_numeroOriginePlur
on
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id
left join t_flagDaRiaccertamento
on
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id
left join t_numeroUEBOrigine
on
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id
left join t_cig
on
imp.movgest_ts_id=t_cig.movgest_ts_id
left join t_cup
on
imp.movgest_ts_id=t_cup.movgest_ts_id
left join t_NOTE_MOVGEST
on
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id
left join t_validato
on
imp.movgest_ts_id=t_validato.movgest_ts_id
left join t_annoFinanziamento
on
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id
left join t_numeroAccFinanziamento
on
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id
left join t_flagCassaEconomale
on
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id
left join attoamm
on
imp.movgest_ts_id=attoamm.movgest_ts_id
left join impattuale
on
imp.movgest_ts_id=impattuale.movgest_ts_id
left join impiniziale
on
imp.movgest_ts_id=impiniziale.movgest_ts_id
left join imputilizzabile
on
imp.movgest_ts_id=imputilizzabile.movgest_ts_id
left join impliquidatoemessoquietanziato
on
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id
left join cofog
on
imp.movgest_ts_id=cofog.movgest_ts_id
left join pdc5
on
imp.movgest_ts_id=pdc5.movgest_ts_id
left join pdc4
on
imp.movgest_ts_id=pdc4.movgest_ts_id
left join pce5
on
imp.movgest_ts_id=pce5.movgest_ts_id
left join pce4
on
imp.movgest_ts_id=pce4.movgest_ts_id
left join progetto
on
imp.movgest_ts_id=progetto.movgest_ts_id
left join t_flagPrenotazione
on
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id
left join t_flagPrenotazioneLiquidabile
on
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id
left join t_flagFrazionabile
on
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
) xx
where xx.movgest_ts_tipo_code='T';



--------subimp

INSERT INTO
  siac.siac_dwh_subimpegno
(
  ente_proprietario_id,  ente_denominazione,  bil_anno,  cod_fase_operativa,  desc_fase_operativa,
  anno_impegno,  num_impegno,  desc_impegno,  cod_subimpegno,  cod_stato_subimpegno,  desc_stato_subimpegno,
  data_scadenza,  parere_finanziario,  cod_capitolo,  cod_articolo,  cod_ueb,  desc_capitolo,  desc_articolo,
  soggetto_id, cod_soggetto, desc_soggetto,  cf_soggetto,  cf_estero_soggetto, p_iva_soggetto,  cod_classe_soggetto,  desc_classe_soggetto,
  cod_tipo_impegno,  desc_tipo_impegno,   cod_spesa_ricorrente,  desc_spesa_ricorrente,  cod_perimetro_sanita_spesa,  desc_perimetro_sanita_spesa,
  cod_transazione_ue_spesa,  desc_transazione_ue_spesa,  cod_politiche_regionali_unit,  desc_politiche_regionali_unit,
  cod_pdc_finanziario_i,  desc_pdc_finanziario_i,  cod_pdc_finanziario_ii,  desc_pdc_finanziario_ii,
  cod_pdc_finanziario_iii,  desc_pdc_finanziario_iii,  cod_pdc_finanziario_iv,  desc_pdc_finanziario_iv,
  cod_pdc_finanziario_v,  desc_pdc_finanziario_v,  cod_pdc_economico_i,  desc_pdc_economico_i,
  cod_pdc_economico_ii,  desc_pdc_economico_ii,  cod_pdc_economico_iii,  desc_pdc_economico_iii,
  cod_pdc_economico_iv,  desc_pdc_economico_iv,  cod_pdc_economico_v,  desc_pdc_economico_v,
  cod_cofog_divisione,  desc_cofog_divisione,  cod_cofog_gruppo,  desc_cofog_gruppo,
  classificatore_1,  classificatore_1_valore,  classificatore_1_desc_valore,
  classificatore_2,  classificatore_2_valore,  classificatore_2_desc_valore,
  classificatore_3,  classificatore_3_valore,  classificatore_3_desc_valore,
  classificatore_4,  classificatore_4_valore,  classificatore_4_desc_valore,
  classificatore_5,  classificatore_5_valore,  classificatore_5_desc_valore,
  annocapitoloorigine,  numcapitoloorigine,  annoorigineplur, numarticoloorigine,  annoriaccertato,  numriaccertato,  numorigineplur,
  flagdariaccertamento,
  anno_atto_amministrativo,  num_atto_amministrativo,  oggetto_atto_amministrativo,  note_atto_amministrativo,
  cod_tipo_atto_amministrativo, desc_tipo_atto_amministrativo, desc_stato_atto_amministrativo,
   importo_iniziale,  importo_attuale,  importo_utilizzabile,
  note,  anno_finanziamento,  cig,  cup,  num_ueb_origine,  validato,
  num_accertamento_finanziamento,  importo_liquidato,  importo_quietanziato,  importo_emesso,
  --data_elaborazione,
  flagcassaeconomale,  data_inizio_val_stato_subimp,  data_inizio_val_subimp,
  data_creazione_subimp,  data_modifica_subimp,
  cod_cdc_atto_amministrativo,  desc_cdc_atto_amministrativo,
  cod_cdr_atto_amministrativo,  desc_cdr_atto_amministrativo,
  flagPrenotazione, flagPrenotazioneLiquidabile, flagFrazionabile,
  cod_siope_tipo_debito, desc_siope_tipo_debito, desc_siope_tipo_debito_bnkit,
  cod_siope_assenza_motivazione, desc_siope_assenza_motivazione, desc_siope_assenza_motiv_bnkit
  )
select
xx.ente_proprietario_id, xx.ente_denominazione, xx.anno,xx.fase_operativa_code, xx.fase_operativa_desc ,
xx.movgest_anno, xx.movgest_numero, xx.movgest_desc, xx.movgest_ts_code, --xx.movgest_ts_desc,
xx.movgest_stato_code, xx.movgest_stato_desc, xx.movgest_ts_scadenza_data,
case when xx.parere_finanziario=false then 'F' else 'S' end parere_finanziario,-- xx.movgest_id, xx.movgest_ts_id, xx.movgest_ts_tipo_code,
xx.elem_code, xx.elem_code2, xx.elem_code3, xx.elem_desc, xx.elem_desc2, --xx.bil_id,
xx.soggetto_id, xx.soggetto_code, xx.soggetto_desc, xx.codice_fiscale,xx.codice_fiscale_estero, xx.partita_iva, xx.soggetto_classe_code, xx.soggetto_classe_desc,
xx.tipoimpegno_classif_code,xx.tipoimpegno_classif_desc,xx.ricorrentespesa_classif_code,xx.ricorrentespesa_classif_desc,
xx.persaspesa_classif_code,xx.persaspesa_classif_desc, xx.truespesa_classif_code, xx.truespesa_classif_desc, xx.polregunitarie_classif_code,xx.polregunitarie_classif_desc,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_I else xx.pdc4_codice_pdc_finanziario_I end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_I else xx.pdc4_descrizione_pdc_finanziario_I end descrizione_pdc_finanziario_I,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_II else xx.pdc4_codice_pdc_finanziario_II end codice_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_II else xx.pdc4_descrizione_pdc_finanziario_II end descrizione_pdc_finanziario_II,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_III else xx.pdc4_codice_pdc_finanziario_III end codice_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_III else xx.pdc4_descrizione_pdc_finanziario_III end descrizione_pdc_finanziario_III,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_IV else xx.pdc4_codice_pdc_finanziario_IV end codice_pdc_finanziario_IV  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_IV else xx.pdc4_descrizione_pdc_finanziario_IV end descrizione_pdc_finanziario_IV,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_codice_pdc_finanziario_V end codice_pdc_finanziario_V  ,
case when   xx.pdc5_codice_pdc_finanziario_V is not null then    xx.pdc5_descrizione_pdc_finanziario_V end descrizione_pdc_finanziario_V,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_I else xx.pce4_codice_pdc_economico_I end codice_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_I else xx.pce4_descrizione_pdc_economico_I end descrizione_pdc_economico_I,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_II else xx.pce4_codice_pdc_economico_II end codice_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_II else xx.pce4_descrizione_pdc_economico_II end descrizione_pdc_economico_II,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_III else xx.pce4_codice_pdc_economico_III end codice_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_III else xx.pce4_descrizione_pdc_economico_III end descrizione_pdc_economico_III,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_IV else xx.pce4_codice_pdc_economico_IV end codice_pdc_economico_IV  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_IV else xx.pce4_descrizione_pdc_economico_IV end descrizione_pdc_economico_IV,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_codice_pdc_economico_V end codice_pdc_economico_V  ,
case when   xx.pce5_codice_pdc_economico_V is not null then    xx.pce5_descrizione_pdc_economico_V end descrizione_pdc_economico_V,
xx.codice_cofog_divisione, xx.descrizione_cofog_divisione,xx.codice_cofog_gruppo,xx.descrizione_cofog_gruppo,
xx.cla11_classif_tipo_code,xx.cla11_classif_code,xx.cla11_classif_desc,xx.cla12_classif_tipo_code,xx.cla12_classif_code,xx.cla12_classif_desc,
xx.cla13_classif_tipo_code,xx.cla13_classif_code,xx.cla13_classif_desc,xx.cla14_classif_tipo_code,xx.cla14_classif_code,xx.cla14_classif_desc,
xx.cla15_classif_tipo_code,xx.cla15_classif_code,xx.cla15_classif_desc,
xx.annoCapitoloOrigine,xx.numeroCapitoloOrigine,xx.annoOriginePlur,xx.numeroArticoloOrigine,xx.annoRiaccertato,xx.numeroRiaccertato,
xx.numeroOriginePlur, xx.flagDaRiaccertamento,
xx.attoamm_anno, xx.attoamm_numero, xx.attoamm_oggetto, xx.attoamm_note,
xx.attoamm_tipo_code, xx.attoamm_tipo_desc, xx.attoamm_stato_desc,
xx.importo_iniziale, xx.importo_attuale, xx.importo_utilizzabile,
xx.NOTE_MOVGEST,  xx.annoFinanziamento, xx.cig,xx.cup, xx.numeroUEBOrigine,  xx.validato,
--xx.attoamm_id,
xx.numeroAccFinanziamento,  xx.importo_liquidato,  xx.importo_quietanziato, xx.importo_emesso,
xx.flagCassaEconomale,
xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_code::varchar else xx.cdr_cdc_code::varchar end cdc_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdc_desc::varchar else xx.cdr_cdc_desc::varchar end cdc_desc,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_code::varchar else xx.cdr_cdr_code::varchar end cdr_code,
case when xx.cdc_cdc_code::varchar is not null then  xx.cdc_cdr_desc::varchar else xx.cdr_cdr_desc::varchar end cdr_desc,
xx.flagPrenotazione, xx.flagPrenotazioneLiquidabile, xx.flagFrazionabile,
xx.siope_tipo_debito_code, xx.siope_tipo_debito_desc, xx.siope_tipo_debito_desc_bnkit,
xx.siope_assenza_motivazione_code, xx.siope_assenza_motivazione_desc, xx.siope_assenza_motivazione_desc_bnkit
/*xx.data_inizio_val_stato_subimp, xx.data_inizio_val_subimp,
xx.data_creazione_subimp, xx.data_modifica_subimp,*/
 from (
with imp as (
SELECT
e.ente_proprietario_id, e.ente_denominazione, d.anno,
       b.movgest_anno, b.movgest_numero, b.movgest_desc, a.movgest_ts_code, a.movgest_ts_desc,
       i.movgest_stato_code, i.movgest_stato_desc,
       a.movgest_ts_scadenza_data, b.parere_finanziario, b.movgest_id, a.movgest_ts_id,
       g.movgest_ts_tipo_code,    c.bil_id,
       h.validita_inizio as data_inizio_val_stato_subimp,
       a.data_creazione as data_creazione_subimp,
       a.validita_inizio as  data_inizio_val_subimp,
       a.data_modifica as data_modifica_subimp,
       b.data_creazione as data_creazione_imp,
       b.validita_inizio as data_inizio_val_imp,
       b.data_modifica as data_modifica_imp,
       m.fase_operativa_code, m.fase_operativa_desc,
       n.siope_tipo_debito_code, n.siope_tipo_debito_desc, n.siope_tipo_debito_desc_bnkit,
       o.siope_assenza_motivazione_code, o.siope_assenza_motivazione_desc, o.siope_assenza_motivazione_desc_bnkit
FROM
siac_t_movgest_ts a
left join siac_d_siope_tipo_debito n on n.siope_tipo_debito_id = a.siope_tipo_debito_id
                                     and n.data_cancellazione is null
                                     and n.validita_fine is null
left join siac_d_siope_assenza_motivazione o on o.siope_assenza_motivazione_id = a.siope_assenza_motivazione_id
                                             and o.data_cancellazione is null
                                             and o.validita_fine is null
, siac_t_movgest b
, siac_t_bil c
,  siac_t_periodo d
, siac_t_ente_proprietario e
,  siac_d_movgest_tipo f
,  siac_d_movgest_ts_tipo g
,  siac_r_movgest_ts_stato h
,  siac_d_movgest_stato i,
siac_r_bil_fase_operativa l, siac_d_fase_operativa m
where a.movgest_id=  b.movgest_id and
 b.bil_id = c.bil_id and
 d.periodo_id = c.periodo_id and
 e.ente_proprietario_id = b.ente_proprietario_id   and
 b.movgest_tipo_id = f.movgest_tipo_id and
 a.movgest_ts_tipo_id = g.movgest_ts_tipo_id      and
 h.movgest_ts_id = a.movgest_ts_id   and
 h.movgest_stato_id = i.movgest_stato_id
and e.ente_proprietario_id = p_ente_proprietario_id
AND d.anno = p_anno_bilancio
AND f.movgest_tipo_code = 'I'
--AND p_data BETWEEN h.validita_inizio AND COALESCE(h.validita_fine, p_data)
and l.bil_id=c.bil_id
and m.fase_operativa_id=l.fase_operativa_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
AND c.data_cancellazione IS NULL
AND d.data_cancellazione IS NULL
AND e.data_cancellazione IS NULL
AND f.data_cancellazione IS NULL
AND g.data_cancellazione IS NULL
AND h.data_cancellazione IS NULL
AND i.data_cancellazione IS NULL
AND a.validita_fine IS NULL
AND b.validita_fine IS NULL
AND c.validita_fine IS NULL
AND d.validita_fine IS NULL
AND e.validita_fine IS NULL
AND f.validita_fine IS NULL
AND g.validita_fine IS NULL
AND h.validita_fine IS NULL
AND i.validita_fine IS NULL
)
, cap as (
select l.movgest_id
,m.elem_code, m.elem_code2, m.elem_code3, m.elem_desc, m.elem_desc2
From siac_r_movgest_bil_elem l, siac_t_bil_elem m
where l.elem_id=m.elem_id
and l.ente_proprietario_id=p_ente_proprietario_id
--AND p_data BETWEEN l.validita_inizio AND COALESCE(l.validita_fine, p_data)
AND l.data_cancellazione IS NULL
AND m.data_cancellazione IS NULL
AND l.validita_fine IS NULL
AND m.validita_fine IS NULL
),
sogg as (SELECT
a.movgest_ts_id,
b.soggetto_code, b.soggetto_desc, b.codice_fiscale,
b.codice_fiscale_estero, b.partita_iva, b.soggetto_id
/*INTO v_codice_soggetto, v_descrizione_soggetto, v_codice_fiscale_soggetto,
v_codice_fiscale_estero_soggetto, v_partita_iva_soggetto, v_soggetto_id*/
FROM siac_r_movgest_ts_sog a, siac_t_soggetto b
WHERE a.soggetto_id = b.soggetto_id
and a.ente_proprietario_id=p_ente_proprietario_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
),
sogcla as (SELECT
a.movgest_ts_id,b.soggetto_classe_code, b.soggetto_classe_desc
--INTO v_codice_classe_soggetto, v_descrizione_classe_soggetto
FROM siac_r_movgest_ts_sogclasse a, siac.siac_d_soggetto_classe b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.soggetto_classe_id = b.soggetto_classe_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
)
,
--classificatori non gerarchici
tipoimpegno as (
SELECT
a.movgest_ts_id,b.classif_code tipoimpegno_classif_code,b.classif_desc tipoimpegno_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TIPO_IMPEGNO'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
ricorrentespesa as (
SELECT
a.movgest_ts_id,b.classif_code ricorrentespesa_classif_code,b.classif_desc ricorrentespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='RICORRENTE_SPESA'
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
truespesa as (
SELECT
a.movgest_ts_id,b.classif_code truespesa_classif_code,b.classif_desc truespesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='TRANSAZIONE_UE_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
persaspesa as (
SELECT
a.movgest_ts_id,b.classif_code persaspesa_classif_code,b.classif_desc persaspesa_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='PERIMETRO_SANITARIO_SPESA'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
polregunitarie as (
SELECT
a.movgest_ts_id,b.classif_code polregunitarie_classif_code,b.classif_desc polregunitarie_classif_desc
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='POLITICHE_REGIONALI_UNITARIE'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
),
cla11 as (
SELECT
a.movgest_ts_id,b.classif_code cla11_classif_code,b.classif_desc cla11_classif_desc, c.classif_tipo_code cla11_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_11'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla12 as (
SELECT
a.movgest_ts_id,b.classif_code cla12_classif_code,b.classif_desc cla12_classif_desc, c.classif_tipo_code cla12_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_12'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla13 as (
SELECT
a.movgest_ts_id,b.classif_code cla13_classif_code,b.classif_desc cla13_classif_desc, c.classif_tipo_code cla13_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_13'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla14 as (
SELECT
a.movgest_ts_id,b.classif_code cla14_classif_code,b.classif_desc cla14_classif_desc, c.classif_tipo_code cla14_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_14'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
,
cla15 as (
SELECT
a.movgest_ts_id,b.classif_code cla15_classif_code,b.classif_desc cla15_classif_desc, c.classif_tipo_code cla15_classif_tipo_code
 from siac_r_movgest_class a, siac_t_class b, siac_d_class_tipo c
where
a.ente_proprietario_id =p_ente_proprietario_id
and a.classif_id=b.classif_id
and b.classif_tipo_id=c.classif_tipo_id
and c.classif_tipo_code='CLASSIFICATORE_15'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
)
--sezione attributi
, t_annoCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo annoCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroCapitoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroCapitoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroCapitoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo annoOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroArticoloOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroArticoloOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroArticoloOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo annoRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroRiaccertato as (
SELECT
a.movgest_ts_id
, a.testo numeroRiaccertato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroRiaccertato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroOriginePlur as (
SELECT
a.movgest_ts_id
, a.testo numeroOriginePlur
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroOriginePlur' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagDaRiaccertamento as (
SELECT
a.movgest_ts_id
, a."boolean" flagDaRiaccertamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagDaRiaccertamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroUEBOrigine as (
SELECT
a.movgest_ts_id
, a.testo numeroUEBOrigine
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroUEBOrigine' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cig as (
SELECT
a.movgest_ts_id
, a.testo cig
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cig' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_cup as (
SELECT
a.movgest_ts_id
, a.testo cup
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='cup' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_NOTE_MOVGEST as (
SELECT
a.movgest_ts_id
, a.testo NOTE_MOVGEST
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='NOTE_MOVGEST' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_validato as (
SELECT
a.movgest_ts_id
, a."boolean" validato
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='validato' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_annoFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo annoFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='annoFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_numeroAccFinanziamento as (
SELECT
a.movgest_ts_id
, a.testo numeroAccFinanziamento
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='numeroAccFinanziamento' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagCassaEconomale as (
SELECT
a.movgest_ts_id
, a."boolean" flagCassaEconomale
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagCassaEconomale' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazione as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazione
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazione' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
)
, t_flagPrenotazioneLiquidabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagPrenotazioneLiquidabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagPrenotazioneLiquidabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
t_flagFrazionabile as (
SELECT
a.movgest_ts_id
, a."boolean" flagFrazionabile
FROM   siac.siac_r_movgest_ts_attr a, siac.siac_t_attr b
WHERE
b.attr_code='flagFrazionabile' and
a.ente_proprietario_id=p_ente_proprietario_id and
 a.attr_id = b.attr_id
--AND    p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND    a.data_cancellazione IS NULL
AND    b.data_cancellazione IS NULL
AND    a.validita_fine IS NULL
AND    b.validita_fine IS NULL
),
--atto amm
attoamm as (
with atmc as (
with atm as (
SELECT
a.movgest_ts_id,
b.attoamm_anno, b.attoamm_numero, b.attoamm_oggetto, b.attoamm_note,
       e.attoamm_tipo_code, e.attoamm_tipo_desc, d.attoamm_stato_desc, b.attoamm_id
FROM
siac.siac_r_movgest_ts_atto_amm a,
siac.siac_t_atto_amm b, siac.siac_r_atto_amm_stato c,
siac.siac_d_atto_amm_stato d, siac.siac_d_atto_amm_tipo e
WHERE
a.ente_proprietario_id=p_ente_proprietario_id--p_ente_proprietario_id
and a.attoamm_id=b.attoamm_id
AND c.attoamm_id = b.attoamm_id
AND d.attoamm_stato_id = c.attoamm_stato_id
AND e.attoamm_tipo_id = b.attoamm_tipo_id
--AND   p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   c.data_cancellazione IS NULL
AND   d.data_cancellazione IS NULL
AND   e.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   c.validita_fine IS NULL
AND   d.validita_fine IS NULL
AND   e.validita_fine IS NULL
)
, atmrclass as (select a.attoamm_id,a.classif_id from siac_r_atto_amm_class a where
a.ente_proprietario_id=p_ente_proprietario_id and
a.data_cancellazione is null
AND   a.validita_fine IS NULL
--and p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
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
--and p_data BETWEEN c.validita_inizio AND COALESCE(c.validita_fine, p_data)
and a2.classif_id=c.classif_id_padre
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and a2.data_cancellazione is null
and a2.classif_id=c.classif_id_padre
/*and a.validita_fine is null
and b.validita_fine is null
and c.validita_fine is null
and a2.validita_fine is null*/
)
,cdr as (
select a.classif_id,null cdr_cdc_code,null cdr_cdc_desc
,a.classif_code cdr_cdr_code,a.classif_desc cdr_cdr_desc
 from siaC_t_class a,siac_d_class_tipo b
 where a.ente_proprietario_id=p_ente_proprietario_id
and b.classif_tipo_id=a.classif_tipo_id
and b.classif_tipo_code='CDR'
and a.data_cancellazione is null
and b.data_cancellazione is null
/*and a.validita_fine is null
and b.validita_fine is null*/
)
select
atmc.movgest_ts_id,
atmc.attoamm_anno, atmc.attoamm_numero, atmc.attoamm_oggetto, atmc.attoamm_note,
atmc.attoamm_tipo_code, atmc.attoamm_tipo_desc, atmc.attoamm_stato_desc, atmc.attoamm_id,
cdc.cdc_cdc_code,cdc.cdc_cdc_desc,cdc.cdc_cdr_code,cdc.cdc_cdr_desc,
cdr.cdr_cdc_code,cdr.cdr_cdc_desc,cdr.cdr_cdr_code,cdr.cdr_cdr_desc
from atmc left join cdc on
atmc.classif_id=cdc.classif_id
left join cdr on
atmc.classif_id=cdr.classif_id),
impattuale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_attuale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='A'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
impiniziale as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_iniziale, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='I'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
)
,
imputilizzabile as (
SELECT COALESCE(SUM(a.movgest_ts_det_importo),0) importo_utilizzabile, a.movgest_ts_id
FROM siac.siac_t_movgest_ts_det a, siac.siac_d_movgest_ts_det_tipo b
WHERE
a.ente_proprietario_id=p_ente_proprietario_id and
a.movgest_ts_det_tipo_id = b.movgest_ts_det_tipo_id
AND a.data_cancellazione IS NULL
AND b.data_cancellazione IS NULL
and a.validita_fine is null
and b.validita_fine is null
and b.movgest_ts_det_tipo_code='U'
--AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
GROUP BY  a.movgest_ts_id, b.movgest_ts_det_tipo_code
),
impliquidatoemessoquietanziato as (select tz.* from (
with liquid as (
 SELECT sum(COALESCE(b.liq_importo,0)) importo_liquidato, a.movgest_ts_id,
b.liq_id
    FROM siac.siac_r_liquidazione_movgest a, siac.siac_t_liquidazione b,
    siac.siac_d_liquidazione_stato c, siac.siac_r_liquidazione_stato d
    WHERE
    a.ente_proprietario_id=p_ente_proprietario_id
    AND   a.liq_id = b.liq_id
    AND   b.liq_id = d.liq_id
    AND   d.liq_stato_id = c.liq_stato_id
    AND   c.liq_stato_code <> 'A'
    --AND p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    --AND p_data BETWEEN d.validita_inizio AND COALESCE(d.validita_fine, p_data)
    AND a.data_cancellazione IS NULL
    AND b.data_cancellazione IS NULL
    AND c.data_cancellazione IS NULL
    AND d.data_cancellazione IS NULL
    AND a.validita_fine IS NULL
    AND b.validita_fine IS NULL
    AND c.validita_fine IS NULL
    AND d.validita_fine IS NULL
    group by a.movgest_ts_id, b.liq_id),
emes as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_emesso, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code <> 'A'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id),
quiet as (
  SELECT COALESCE(SUM(e.ord_ts_det_importo),0) importo_quietanziato, a.liq_id
            FROM
            siac_r_liquidazione_ord a,
            siac_t_ordinativo_ts b,
                 siac_r_ordinativo_stato c, siac_d_ordinativo_stato d,
                 siac_t_ordinativo_ts_det e, siac_d_ordinativo_ts_det_tipo f
            WHERE
            a.ente_proprietario_id=p_ente_proprietario_id and
            a.sord_id=b.ord_ts_id
            AND  c.ord_id = b.ord_id
            AND  c.ord_stato_id = d.ord_stato_id
            AND  e.ord_ts_id = b.ord_ts_id
            AND  f.ord_ts_det_tipo_id = e.ord_ts_det_tipo_id
            AND  d.ord_stato_code= 'Q'
            AND  f.ord_ts_det_tipo_code = 'A'
            --AND  p_data BETWEEN  a.validita_inizio  AND COALESCE(a.validita_fine, p_data)
            --AND  p_data BETWEEN  c.validita_inizio  AND COALESCE(c.validita_fine, p_data)
            AND  a.data_cancellazione IS NULL
            AND  b.data_cancellazione IS NULL
            AND  c.data_cancellazione IS NULL
            AND  d.data_cancellazione IS NULL
            AND  e.data_cancellazione IS NULL
            AND  f.data_cancellazione IS NULL
            AND  a.validita_fine IS NULL
            AND  b.validita_fine IS NULL
            AND  c.validita_fine IS NULL
            AND  d.validita_fine IS NULL
            AND  e.validita_fine IS NULL
            AND  f.validita_fine IS NULL
            group by a.liq_id)
select liquid.movgest_ts_id,coalesce(sum(liquid.importo_liquidato),0) importo_liquidato,
coalesce(sum(emes.importo_emesso),0) importo_emesso,
coalesce(sum(quiet.importo_quietanziato),0) importo_quietanziato
from liquid left join emes ON
liquid.liq_id=emes.liq_id
left join quiet ON
liquid.liq_id=quiet.liq_id
group by liquid.movgest_ts_id
) as tz),
cofog as (
select distinct r.movgest_ts_id,
a.classif_code codice_cofog_gruppo,a.classif_desc descrizione_cofog_gruppo,
a2.classif_code codice_cofog_divisione,a2.classif_desc descrizione_cofog_divisione
from
siac_r_movgest_class r,
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
--and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine, p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
)
, pdc5 as (
select distinct
r.movgest_ts_id,
a.classif_code pdc5_codice_pdc_finanziario_V,a.classif_desc pdc5_descrizione_pdc_finanziario_V,
a2.classif_code pdc5_codice_pdc_finanziario_IV,a2.classif_desc pdc5_descrizione_pdc_finanziario_IV,
a3.classif_code pdc5_codice_pdc_finanziario_III,a3.classif_desc pdc5_descrizione_pdc_finanziario_III,
a4.classif_code pdc5_codice_pdc_finanziario_II,a4.classif_desc pdc5_descrizione_pdc_finanziario_II,
a5.classif_code pdc5_codice_pdc_finanziario_I,a5.classif_desc pdc5_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pdc4 as (
select distinct r.movgest_ts_id,
a.classif_code pdc4_codice_pdc_finanziario_IV,a.classif_desc pdc4_descrizione_pdc_finanziario_IV,
a2.classif_code pdc4_codice_pdc_finanziario_III,a2.classif_desc pdc4_descrizione_pdc_finanziario_III,
a3.classif_code pdc4_codice_pdc_finanziario_II,a3.classif_desc pdc4_descrizione_pdc_finanziario_II,
a4.classif_code pdc4_codice_pdc_finanziario_I,a4.classif_desc pdc4_descrizione_pdc_finanziario_I
 from siac_r_movgest_class r,
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
-- SIAC-5883 Daniela 13.02.2018
-- and p_data BETWEEN r.validita_inizio and COALESCE(r.validita_fine,p_data)
-- FINE SIAC-5883 Daniela 13.02.2018
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
, pce5 as (
select distinct r.movgest_ts_id,
--r.classif_id,
a.classif_code pce5_codice_pdc_economico_V,a.classif_desc pce5_descrizione_pdc_economico_V,
a2.classif_code pce5_codice_pdc_economico_IV,a2.classif_desc pce5_descrizione_pdc_economico_IV,
a3.classif_code pce5_codice_pdc_economico_III,a3.classif_desc pce5_descrizione_pdc_economico_III,
a4.classif_code pce5_codice_pdc_economico_II,a4.classif_desc pce5_descrizione_pdc_economico_II,
a5.classif_code pce5_codice_pdc_economico_I,a5.classif_desc pce5_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
--and p_data BETWEEN d5.validita_inizio and COALESCE(d5.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
AND   d5.data_cancellazione IS NULL
AND   a5.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL
AND   d5.validita_fine IS NULL
AND   a5.validita_fine IS NULL*/
)
, pce4 as (
select distinct r.movgest_ts_id,
a.classif_code pce4_codice_pdc_economico_IV,a.classif_desc pce4_descrizione_pdc_economico_IV,
a2.classif_code pce4_codice_pdc_economico_III,a2.classif_desc pce4_descrizione_pdc_economico_III,
a3.classif_code pce4_codice_pdc_economico_II,a3.classif_desc pce4_descrizione_pdc_economico_II,
a4.classif_code pce4_codice_pdc_economico_I,a4.classif_desc pce4_descrizione_pdc_economico_I
 from siac_r_movgest_class r,
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
--and p_data BETWEEN d2.validita_inizio and COALESCE(d2.validita_fine,p_data)
--and p_data BETWEEN d3.validita_inizio and COALESCE(d3.validita_fine,p_data)
--and p_data BETWEEN d4.validita_inizio and COALESCE(d4.validita_fine,p_data)
AND   a.data_cancellazione IS NULL
AND   b.data_cancellazione IS NULL
AND   r.data_cancellazione IS NULL
AND   d2.data_cancellazione IS NULL
AND   a2.data_cancellazione IS NULL
AND   d3.data_cancellazione IS NULL
AND   a3.data_cancellazione IS NULL
AND   d4.data_cancellazione IS NULL
AND   a4.data_cancellazione IS NULL
/*AND   a.validita_fine IS NULL
AND   b.validita_fine IS NULL
AND   r.validita_fine IS NULL
AND   d2.validita_fine IS NULL
AND   a2.validita_fine IS NULL
AND   d3.validita_fine IS NULL
AND   a3.validita_fine IS NULL
AND   d4.validita_fine IS NULL
AND   a4.validita_fine IS NULL*/
)
select
imp.ente_proprietario_id, imp.ente_denominazione, imp.anno,
imp.movgest_anno, imp.movgest_numero, imp.movgest_desc, imp.movgest_ts_code, imp.movgest_ts_desc,
imp.movgest_stato_code, imp.movgest_stato_desc,
imp.movgest_ts_scadenza_data, imp.parere_finanziario, imp.movgest_id, imp.movgest_ts_id,
imp.movgest_ts_tipo_code,
cap.elem_code, cap.elem_code2, cap.elem_code3, cap.elem_desc, cap.elem_desc2,
imp.bil_id,
imp.data_inizio_val_stato_subimp,
imp.data_creazione_subimp,
imp.data_inizio_val_subimp,
imp.data_modifica_subimp,
imp.data_creazione_imp,
imp.data_inizio_val_imp,
imp.data_modifica_imp,
imp.fase_operativa_code, imp.fase_operativa_desc ,
sogg.soggetto_code, sogg.soggetto_desc, sogg.codice_fiscale,
sogg.codice_fiscale_estero, sogg.partita_iva, sogg.soggetto_id
,sogcla.soggetto_classe_code, sogcla.soggetto_classe_desc,
tipoimpegno.tipoimpegno_classif_code,
tipoimpegno.tipoimpegno_classif_desc,
ricorrentespesa.ricorrentespesa_classif_code,
ricorrentespesa.ricorrentespesa_classif_desc,
truespesa.truespesa_classif_code,
truespesa.truespesa_classif_desc,
persaspesa.persaspesa_classif_code,
persaspesa.persaspesa_classif_desc,
polregunitarie.polregunitarie_classif_code,
polregunitarie.polregunitarie_classif_desc,
cla11.cla11_classif_code,
cla11.cla11_classif_desc,
cla11.cla11_classif_tipo_code,
cla12.cla12_classif_code,
cla12.cla12_classif_desc,
cla12.cla12_classif_tipo_code,
cla13.cla13_classif_code,
cla13.cla13_classif_desc,
cla13.cla13_classif_tipo_code,
cla14.cla14_classif_code,
cla14.cla14_classif_desc,
cla14.cla14_classif_tipo_code,
cla15.cla15_classif_code,
cla15.cla15_classif_desc,
cla15.cla15_classif_tipo_code,
t_annoCapitoloOrigine.annoCapitoloOrigine,
t_numeroCapitoloOrigine.numeroCapitoloOrigine,
t_annoOriginePlur.annoOriginePlur,
t_numeroArticoloOrigine.numeroArticoloOrigine,
t_annoRiaccertato.annoRiaccertato,
t_numeroRiaccertato.numeroRiaccertato,
t_numeroOriginePlur.numeroOriginePlur,
t_flagDaRiaccertamento.flagDaRiaccertamento,
t_numeroUEBOrigine.numeroUEBOrigine,
t_cig.cig,
t_cup.cup,
t_NOTE_MOVGEST.NOTE_MOVGEST,
t_validato.validato,
t_annoFinanziamento.annoFinanziamento,
t_numeroAccFinanziamento.numeroAccFinanziamento,
t_flagCassaEconomale.flagCassaEconomale,
attoamm.attoamm_anno, attoamm.attoamm_numero, attoamm.attoamm_oggetto, attoamm.attoamm_note,
attoamm.attoamm_tipo_code, attoamm.attoamm_tipo_desc, attoamm.attoamm_stato_desc, attoamm.attoamm_id,
impattuale.importo_attuale,
impiniziale.importo_iniziale,
imputilizzabile.importo_utilizzabile,
impliquidatoemessoquietanziato.importo_liquidato,
impliquidatoemessoquietanziato.importo_emesso,
impliquidatoemessoquietanziato,importo_quietanziato,
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
attoamm.cdc_cdc_code,attoamm.cdc_cdc_desc,attoamm.cdc_cdr_code,attoamm.cdc_cdr_desc,
attoamm.cdr_cdc_code,attoamm.cdr_cdc_desc,attoamm.cdr_cdr_code,attoamm.cdr_cdr_desc,
t_flagPrenotazione.flagPrenotazione, t_flagPrenotazioneLiquidabile.flagPrenotazioneLiquidabile,
t_flagFrazionabile.flagFrazionabile,
imp.siope_tipo_debito_code, imp.siope_tipo_debito_desc, imp.siope_tipo_debito_desc_bnkit,
imp.siope_assenza_motivazione_code, imp.siope_assenza_motivazione_desc, imp.siope_assenza_motivazione_desc_bnkit
from
imp left join cap
on
imp.movgest_id=cap.movgest_id
left join sogg
on
imp.movgest_ts_id=sogg.movgest_ts_id
left join sogcla
on
imp.movgest_ts_id=sogcla.movgest_ts_id
left join tipoimpegno
on
imp.movgest_ts_id=tipoimpegno.movgest_ts_id
left join ricorrentespesa
on
imp.movgest_ts_id=ricorrentespesa.movgest_ts_id
left join truespesa
on
imp.movgest_ts_id=truespesa.movgest_ts_id
left join persaspesa
on
imp.movgest_ts_id=persaspesa.movgest_ts_id
left join polregunitarie
on
imp.movgest_ts_id=polregunitarie.movgest_ts_id
left join cla11
on
imp.movgest_ts_id=cla11.movgest_ts_id
left join cla12
on
imp.movgest_ts_id=cla12.movgest_ts_id
left join cla13
on
imp.movgest_ts_id=cla13.movgest_ts_id
left join cla14
on
imp.movgest_ts_id=cla14.movgest_ts_id
left join cla15
on
imp.movgest_ts_id=cla15.movgest_ts_id
left join t_annoCapitoloOrigine
on
imp.movgest_ts_id=t_annoCapitoloOrigine.movgest_ts_id
left join t_numeroCapitoloOrigine
on
imp.movgest_ts_id=t_numeroCapitoloOrigine.movgest_ts_id
left join t_annoOriginePlur
on
imp.movgest_ts_id=t_annoOriginePlur.movgest_ts_id
left join t_numeroArticoloOrigine
on
imp.movgest_ts_id=t_numeroArticoloOrigine.movgest_ts_id
left join t_annoRiaccertato
on
imp.movgest_ts_id=t_annoRiaccertato.movgest_ts_id
left join t_numeroRiaccertato
on
imp.movgest_ts_id=t_numeroRiaccertato.movgest_ts_id
left join t_numeroOriginePlur
on
imp.movgest_ts_id=t_numeroOriginePlur.movgest_ts_id
left join t_flagDaRiaccertamento
on
imp.movgest_ts_id=t_flagDaRiaccertamento.movgest_ts_id
left join t_numeroUEBOrigine
on
imp.movgest_ts_id=t_numeroUEBOrigine.movgest_ts_id
left join t_cig
on
imp.movgest_ts_id=t_cig.movgest_ts_id
left join t_cup
on
imp.movgest_ts_id=t_cup.movgest_ts_id
left join t_NOTE_MOVGEST
on
imp.movgest_ts_id=t_NOTE_MOVGEST.movgest_ts_id
left join t_validato
on
imp.movgest_ts_id=t_validato.movgest_ts_id
left join t_annoFinanziamento
on
imp.movgest_ts_id=t_annoFinanziamento.movgest_ts_id
left join t_numeroAccFinanziamento
on
imp.movgest_ts_id=t_numeroAccFinanziamento.movgest_ts_id
left join t_flagCassaEconomale
on
imp.movgest_ts_id=t_flagCassaEconomale.movgest_ts_id
left join attoamm
on
imp.movgest_ts_id=attoamm.movgest_ts_id
left join impattuale
on
imp.movgest_ts_id=impattuale.movgest_ts_id
left join impiniziale
on
imp.movgest_ts_id=impiniziale.movgest_ts_id
left join imputilizzabile
on
imp.movgest_ts_id=imputilizzabile.movgest_ts_id
left join impliquidatoemessoquietanziato
on
imp.movgest_ts_id=impliquidatoemessoquietanziato.movgest_ts_id
left join cofog
on
imp.movgest_ts_id=cofog.movgest_ts_id
left join pdc5
on
imp.movgest_ts_id=pdc5.movgest_ts_id
left join pdc4
on
imp.movgest_ts_id=pdc4.movgest_ts_id
left join pce5
on
imp.movgest_ts_id=pce5.movgest_ts_id
left join pce4
on
imp.movgest_ts_id=pce4.movgest_ts_id
left join t_flagPrenotazione
on
imp.movgest_ts_id=t_flagPrenotazione.movgest_ts_id
left join t_flagPrenotazioneLiquidabile
on
imp.movgest_ts_id=t_flagPrenotazioneLiquidabile.movgest_ts_id
left join t_flagFrazionabile
on
imp.movgest_ts_id=t_flagFrazionabile.movgest_ts_id
) xx
where xx.movgest_ts_tipo_code='S';


esito:='ok';

EXCEPTION
WHEN others THEN
  esito:='Funzione carico impegni (FNC_SIAC_DWH_IMPEGNO) terminata con errori';
  RAISE EXCEPTION '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;
-- SIAC-5883 - FINE

-- SIAC-5809 INIZIO
INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_ant_liq_rend',
        'Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita'' (DL 35/2013 e succesive modifiche e rifinanziamenti) - solo per le Regioni',
        0,
        'N',
        4,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-5809'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2017'
and c.periodo_tipo_code='SY'
and b2.anno = '2017'
and c2.periodo_tipo_code='SY'
and not exists (select 1
                from SIAC_T_REPORT_IMPORTI tab
                where tab.ente_proprietario_id = a.ente_proprietario_id
                and   tab.repimp_codice = 'di_cui_ant_liq_rend'
                and   tab.bil_id = a.bil_id
                and   tab.periodo_id = b2.periodo_id
                and   tab.repimp_progr_riga = 4
                and   tab.validita_inizio = to_date('01/01/2016','dd/mm/yyyy')
                and   tab.repimp_modificabile = 'N'                
                );

INSERT INTO SIAC_T_REPORT_IMPORTI (repimp_codice,
                                   repimp_desc,
                                   repimp_importo,
                                   repimp_modificabile,
                                   repimp_progr_riga,
                                   bil_id,
                                   periodo_id,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                                                   
select  'di_cui_ant_liq_rend',
        'Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita'' (DL 35/2013 e succesive modifiche e rifinanziamenti) - solo per le Regioni',
        0,
        'N',
        4,
        a.bil_id,
        b2.periodo_id,
        to_date('01/01/2016','dd/mm/yyyy'),
        null,
        a.ente_proprietario_id,
        now(),
        now(),
        null,
        'SIAC-5809'
from  siac_t_bil a, 
siac_t_periodo b, siac_d_periodo_tipo c,
siac_t_periodo b2, siac_d_periodo_tipo c2
where a.periodo_id = b.periodo_id
and c.periodo_tipo_id=b.periodo_tipo_id
and b2.ente_proprietario_id=b.ente_proprietario_id
and c2.periodo_tipo_id=b2.periodo_tipo_id
and b.anno = '2018'
and c.periodo_tipo_code='SY'
and b2.anno = '2018'
and c2.periodo_tipo_code='SY'
and not exists (select 1
                from SIAC_T_REPORT_IMPORTI tab
                where tab.ente_proprietario_id = a.ente_proprietario_id
                and   tab.repimp_codice = 'di_cui_ant_liq_rend'
                and   tab.bil_id = a.bil_id
                and   tab.periodo_id = b2.periodo_id
                and   tab.repimp_progr_riga = 4
                and   tab.validita_inizio = to_date('01/01/2016','dd/mm/yyyy')
                and   tab.repimp_modificabile = 'N'                
                );

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
d.rep_id,
a.repimp_id,
1 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-5809' login_operazione
from   siac_t_report_importi a, siac_t_report d
where  a.repimp_codice = 'di_cui_ant_liq_rend'
and    d.ente_proprietario_id = a.ente_proprietario_id
and    d.rep_codice = 'BILR048'
and not exists (select 1
                from SIAC_R_REPORT_IMPORTI tab
                where tab.ente_proprietario_id = a.ente_proprietario_id
                and   tab.rep_id = d.rep_id
                and   tab.repimp_id = a.repimp_id
                and   tab.validita_inizio = to_date('01/01/2016','dd/mm/yyyy')            
                );

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
d.rep_id,
a.repimp_id,
1 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-5809' login_operazione
from   siac_t_report_importi a, siac_t_report d
where  a.repimp_codice = 'di_cui_ant_liq_rend'
and    d.ente_proprietario_id = a.ente_proprietario_id
and    d.rep_codice = 'BILR052'
and not exists (select 1
                from SIAC_R_REPORT_IMPORTI tab
                where tab.ente_proprietario_id = a.ente_proprietario_id
                and   tab.rep_id = d.rep_id
                and   tab.repimp_id = a.repimp_id
                and   tab.validita_inizio = to_date('01/01/2016','dd/mm/yyyy')            
                );

INSERT INTO SIAC_R_REPORT_IMPORTI (rep_id,
                                   repimp_id,
                                   posizione_stampa,
                                   validita_inizio,
                                   validita_fine,
                                   ente_proprietario_id,
                                   data_creazione,
                                   data_modifica,
                                   data_cancellazione,
                                   login_operazione)                                   
select 
d.rep_id,
a.repimp_id,
1 posizione_stampa,
to_date('01/01/2016','dd/mm/yyyy') validita_inizio,
null validita_fine,
a.ente_proprietario_id ente_proprietario_id,
now() data_creazione,
now() data_modifica,
null data_cancellazione,
'SIAC-5809' login_operazione
from   siac_t_report_importi a, siac_t_report d
where  a.repimp_codice = 'di_cui_ant_liq_rend'
and    d.ente_proprietario_id = a.ente_proprietario_id
and    d.rep_codice = 'BILR062'
and not exists (select 1
                from SIAC_R_REPORT_IMPORTI tab
                where tab.ente_proprietario_id = a.ente_proprietario_id
                and   tab.rep_id = d.rep_id
                and   tab.repimp_id = a.repimp_id
                and   tab.validita_inizio = to_date('01/01/2016','dd/mm/yyyy')            
                );

INSERT INTO BKO_T_REPORT_COMPETENZE 
(rep_codice,
 rep_competenza_anni)
select 'BILR048', 1 
where not exists (select 1
                  from BKO_T_REPORT_COMPETENZE a
                  where a.rep_codice = 'BILR048');
 
 INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select   
'BILR048',
 'Allegato n.10 - Entrate: Riepilogo per Titolo - Tipologia (BILR048)',
 'di_cui_ant_liq_rend',
 'Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita'' (DL 35/2013 e succesive modifiche e rifinanziamenti) - solo per le Regioni',
 0,
 'N',
 4
where not exists (select 1
                  from BKO_T_REPORT_IMPORTI a
                  where a.rep_codice = 'BILR048'
                  and   a.repimp_codice = 'di_cui_ant_liq_rend'                                 
                  ); 

INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select
'BILR052',
 'Allegato n.10 - Quadro riassuntivo (BILR052)',
 'di_cui_ant_liq_rend',
 'Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita'' (DL 35/2013 e succesive modifiche e rifinanziamenti) - solo per le Regioni',
 0,
 'N',
 4
where not exists (select 1
                  from BKO_T_REPORT_IMPORTI a
                  where a.rep_codice = 'BILR052'
                  and   a.repimp_codice = 'di_cui_ant_liq_rend'                                 
                  ); 
 
 INSERT INTO BKO_T_REPORT_IMPORTI
(rep_codice,
  rep_desc,
  repimp_codice,
  repimp_desc,
  repimp_importo,
  repimp_modificabile,
  repimp_progr_riga)
select
'BILR062',
 'Allegato n.10 - Entrate: Riepilogo generale per Titolo (BILR062)',
 'di_cui_ant_liq_rend',
 'Avanzo di amministrazione - di cui Utilizzo Fondo anticipazioni di liquidita'' (DL 35/2013 e succesive modifiche e rifinanziamenti) - solo per le Regioni',
 0,
 'N',
 4
where not exists (select 1
                  from BKO_T_REPORT_IMPORTI a
                  where a.rep_codice = 'BILR062'
                  and   a.repimp_codice = 'di_cui_ant_liq_rend'                                 
                  ); 
-- SIAC-5809 FINE


-- SIAC-5907: aggiornamento da parte del CSI -  Maurizio  - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibileapagaremovgest (
  movgest_ts_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
disponibileapagare numeric;
disponibileapagare_sub numeric;
disponibileapagare_new numeric;
BEGIN



disponibileapagare :=0.0; 
disponibileapagare_sub :=0.0;


select sum(g.ord_ts_det_importo) into disponibileapagare 
 --s.movgest_ts_code
from siac_t_movgest a,
     siac_t_movgest_ts b, 
     siac_r_liquidazione_movgest c,
     siac_t_liquidazione d,
     siac_r_liquidazione_ord e,
     siac_t_ordinativo_ts f,
     siac_t_ordinativo_ts_det  g,
     siac_d_ordinativo_ts_det_tipo h,
     siac_r_ordinativo_stato i, siac_d_ordinativo_stato l
where 
a.movgest_id = b.movgest_id and
      c.movgest_ts_id = b.movgest_ts_id and
      d.liq_id = c.liq_id and
      e.liq_id = d.liq_id and
      f.ord_ts_id=e.sord_id and
      g.ord_ts_id = f.ord_ts_id and
      h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id and 
      h.ord_ts_det_tipo_code='A' and-- importo attuale
      now() BETWEEN d.validita_inizio and COALESCE (d.validita_fine,now()) and 
      i.ord_id=f.ord_id and
      l.ord_stato_id=i.ord_stato_id and 
      now() BETWEEN i.validita_inizio and COALESCE (i.validita_fine,now()) and 
      l.ord_stato_code<>'A' and
      a.data_cancellazione is NULL and 
      b.data_cancellazione is NULL and 
      c.data_cancellazione is NULL and 
      d.data_cancellazione is NULL and 
      e.data_cancellazione is NULL and 
      f.data_cancellazione is NULL and 
      g.data_cancellazione is NULL and 
      h.data_cancellazione is NULL and 
      i.data_cancellazione is NULL and 
      l.data_cancellazione is NULL      
      and b.movgest_ts_id = movgest_ts_id_in ; --11890 -- id movgest da parametrizzare
      -- aggiungere la ricerca e la IF su stato ordinativo
/*group by 
a.movgest_id;*/


select sum(g.ord_ts_det_importo) into disponibileapagare_sub 
 --s.movgest_ts_code
from siac_t_movgest a,
     siac_t_movgest_ts b, 
     siac_r_liquidazione_movgest c,
     siac_t_liquidazione d,
     siac_r_liquidazione_ord e,
     siac_t_ordinativo_ts f,
     siac_t_ordinativo_ts_det  g,
     siac_d_ordinativo_ts_det_tipo h,
     siac_r_ordinativo_stato i, siac_d_ordinativo_stato l
where 
a.movgest_id = b.movgest_id and
      c.movgest_ts_id = b.movgest_ts_id and
      d.liq_id = c.liq_id and
      e.liq_id = d.liq_id and
      f.ord_ts_id=e.sord_id and
      g.ord_ts_id = f.ord_ts_id and
      h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id and 
      h.ord_ts_det_tipo_code='A' and-- importo attuale
      now() BETWEEN d.validita_inizio and COALESCE (d.validita_fine,now()) and 
      i.ord_id=f.ord_id and
      l.ord_stato_id=i.ord_stato_id and 
      now() BETWEEN i.validita_inizio and COALESCE (i.validita_fine,now()) and 
      l.ord_stato_code<>'A' and
      a.data_cancellazione is NULL and 
      b.data_cancellazione is NULL and 
      c.data_cancellazione is NULL and 
      d.data_cancellazione is NULL and 
      e.data_cancellazione is NULL and 
      f.data_cancellazione is NULL and 
      g.data_cancellazione is NULL and 
      h.data_cancellazione is NULL and 
      i.data_cancellazione is NULL and 
      l.data_cancellazione is NULL      
      and b.movgest_ts_id_padre =movgest_ts_id_in;



if disponibileapagare is null then disponibileapagare:=0; end if;

if disponibileapagare_sub is null then disponibileapagare_sub:=0; end if;



select a.movgest_ts_det_importo - disponibileapagare - disponibileapagare_sub into disponibileapagare_new
from siac_t_movgest_ts_det a,siac_d_movgest_ts_det_tipo b where a.movgest_ts_id=movgest_ts_id_in
and a.data_cancellazione is NULL
and b.movgest_ts_det_tipo_id=a.movgest_ts_det_tipo_id
and b.movgest_ts_det_tipo_code='A'
and b.data_cancellazione is NULL;

disponibileapagare:=disponibileapagare_new;

return disponibileapagare;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


-- SIAC-5907: aggiornamento da parte del CSI -  Maurizio  - FINE

-- SIAC-5893 INIZIO
CREATE OR REPLACE FUNCTION siac."BILR092_stampa_mastrino" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_data_reg_da date,
  p_data_reg_a date,
  p_pdce_v_livello varchar
)
RETURNS TABLE (
  nome_ente varchar,
  id_pdce0 integer,
  codice_pdce0 varchar,
  descr_pdce0 varchar,
  id_pdce1 integer,
  codice_pdce1 varchar,
  descr_pdce1 varchar,
  id_pdce2 integer,
  codice_pdce2 varchar,
  descr_pdce2 varchar,
  id_pdce3 integer,
  codice_pdce3 varchar,
  descr_pdce3 varchar,
  id_pdce4 integer,
  codice_pdce4 varchar,
  descr_pdce4 varchar,
  id_pdce5 integer,
  codice_pdce5 varchar,
  descr_pdce5 varchar,
  id_pdce6 integer,
  codice_pdce6 varchar,
  descr_pdce6 varchar,
  id_pdce7 integer,
  codice_pdce7 varchar,
  descr_pdce7 varchar,
  id_pdce8 integer,
  codice_pdce8 varchar,
  descr_pdce8 varchar,
  data_registrazione date,
  num_prima_nota integer,
  tipo_pnota varchar,
  prov_pnota varchar,
  cod_soggetto varchar,
  descr_soggetto varchar,
  tipo_documento varchar,
  data_registrazione_mov date,
  numero_documento varchar,
  num_det_rif varchar,
  data_det_rif date,
  importo_dare numeric,
  importo_avere numeric,
  livello integer,
  tipo_movimento varchar,
  saldo_prec_dare numeric,
  saldo_prec_avere numeric,
  saldo_ini_dare numeric,
  saldo_ini_avere numeric,
  code_pdce_livello varchar,
  display_error varchar
) AS
$body$
DECLARE
elenco_prime_note record;
elencoPdce record;
dati_movimento record;
dati_eventi record;
--dati_pdce record;
pdce_conto_id_in integer;

DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO 		varchar(1000):=DEF_NULL;
user_table			varchar;
nome_ente_in varchar;
bil_id_in integer;



BEGIN

p_data_reg_a:=date_trunc('day', to_timestamp(to_char(p_data_reg_a,'dd/mm/yyyy'),'dd/mm/yyyy')) + interval '1 day';


select ente_denominazione,b.bil_id into nome_ente_in,bil_id_in
from siac_t_ente_proprietario a,siac_t_bil b,siac_t_periodo c where 
a.ente_proprietario_id=p_ente_prop_id and
a.ente_proprietario_id=b.ente_proprietario_id and b.periodo_id=c.periodo_id
and c.anno=p_anno
;
/*
raise notice 'dati input  p_ente_prop_id % - 
  p_anno % - 
  p_data_reg_da % - 
  p_data_reg_a % - 
  p_pdce_v_livello % - 
  nome_ente_in % - 
  bil_id_in %', p_ente_prop_id::varchar , p_anno::varchar ,  p_data_reg_da::varchar ,
  p_data_reg_a::varchar ,  p_pdce_v_livello::varchar ,  nome_ente_in::varchar ,
  bil_id_in::varchar ;
*/
    select fnc_siac_random_user()
	into	user_table;

raise notice '1 - % ',clock_timestamp()::varchar;
	select --a.pdce_conto_code, 
    a.pdce_conto_id --, a.livello
    into --dati_pdce
    pdce_conto_id_in
    from siac_t_pdce_conto a
    where a.ente_proprietario_id=p_ente_prop_id
    	and a.pdce_conto_code=p_pdce_v_livello;
    IF NOT FOUND THEN
    	display_error='Il codice PDCE indicato ('||p_pdce_v_livello||') e'' inesistente';
        return next;
    	return;
    END IF;
--raise notice 'PDCE livello = %, conto = %, ID = %',  dati_pdce.livello, dati_pdce.pdce_conto_code, dati_pdce.pdce_conto_id;      
    
--     carico l'intera struttura PDCE 
RTN_MESSAGGIO:='inserimento tabella di comodo STRUTTURA DEL PDCE ''.';
raise notice 'inserimento tabella di comodo STRUTTURA DEL PDCE';

raise notice '2 - % ',clock_timestamp()::varchar;
INSERT INTO 
  siac.siac_rep_struttura_pdce
(
  pdce_liv0_id,
  pdce_liv0_id_padre,
  pdce_liv0_code,
  pdce_liv0_desc,
  pdce_liv1_id,
  pdce_liv1_id_padre,
  pdce_liv1_code,
  pdce_liv1_desc,
  pdce_liv2_id,
  pdce_liv2_id_padre,
  pdce_liv2_code,
  pdce_liv2_desc,
  pdce_liv3_id,
  pdce_liv3_id_padre,
  pdce_liv3_code,
  pdce_liv3_desc,
  pdce_liv4_id,
  pdce_liv4_id_padre,
  pdce_liv4_code,
  pdce_liv4_desc,
  pdce_liv5_id,
  pdce_liv5_id_padre,
  pdce_liv5_code,
  pdce_liv5_desc,
  pdce_liv6_id,
  pdce_liv6_id_padre,
  pdce_liv6_code,
  pdce_liv6_desc,
  pdce_liv7_id,
  pdce_liv7_id_padre,
  pdce_liv7_code,
  pdce_liv7_desc,
  utente
)
select zzz.*, user_table from(
with t_pdce_conto0 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree where pdce_conto_id=pdce_conto_id_in
),
t_pdce_conto1 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
),
t_pdce_conto2 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto3 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto4 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto5 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto6 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
,
t_pdce_conto7 as (
WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_id_padre, my_tree.pdce_conto_code,my_tree.pdce_conto_desc,my_tree.livello
from my_tree 
)
select 
t_pdce_conto7.pdce_conto_id pdce_liv0_id,
t_pdce_conto7.pdce_conto_id_padre pdce_liv0_id_padre, 
t_pdce_conto7.pdce_conto_code pdce_liv0_code,
t_pdce_conto7.pdce_conto_desc pdce_liv0_desc,
t_pdce_conto6.pdce_conto_id pdce_liv1_id, 
t_pdce_conto6.pdce_conto_id_padre pdce_liv1_id_padre, 
t_pdce_conto6.pdce_conto_code pdce_liv1_code,
t_pdce_conto6.pdce_conto_desc pdce_liv1_desc,
t_pdce_conto5.pdce_conto_id pdce_liv2_id, 
t_pdce_conto5.pdce_conto_id_padre pdce_liv2_id_padre, 
t_pdce_conto5.pdce_conto_code pdce_liv2_code,
t_pdce_conto5.pdce_conto_desc pdce_liv2_desc,
t_pdce_conto4.pdce_conto_id pdce_liv3_id, 
t_pdce_conto4.pdce_conto_id_padre pdce_liv3_id_padre, 
t_pdce_conto4.pdce_conto_code pdce_liv3_code,
t_pdce_conto4.pdce_conto_desc pdce_liv3_desc,
t_pdce_conto3.pdce_conto_id pdce_liv4_id, 
t_pdce_conto3.pdce_conto_id_padre pdce_liv4_id_padre, 
t_pdce_conto3.pdce_conto_code pdce_liv4_code,
t_pdce_conto3.pdce_conto_desc pdce_liv4_desc,
t_pdce_conto2.pdce_conto_id pdce_liv5_id, 
t_pdce_conto2.pdce_conto_id_padre pdce_liv5_id_padre, 
t_pdce_conto2.pdce_conto_code pdce_liv5_code,
t_pdce_conto2.pdce_conto_desc pdce_liv5_desc,
t_pdce_conto1.pdce_conto_id pdce_liv6_id, 
t_pdce_conto1.pdce_conto_id_padre pdce_liv6_id_padre, 
t_pdce_conto1.pdce_conto_code pdce_liv6_code,
t_pdce_conto1.pdce_conto_desc pdce_liv6_desc,
t_pdce_conto0.pdce_conto_id pdce_liv7_id, 
t_pdce_conto0.pdce_conto_id_padre pdce_liv7_id_padre, 
t_pdce_conto0.pdce_conto_code pdce_liv7_code,
t_pdce_conto0.pdce_conto_desc pdce_liv7_desc
 from t_pdce_conto0 left join t_pdce_conto1
on t_pdce_conto0.livello-1=t_pdce_conto1.livello
left join t_pdce_conto2
on t_pdce_conto1.livello-1=t_pdce_conto2.livello
left join t_pdce_conto3
on t_pdce_conto2.livello-1=t_pdce_conto3.livello
left join t_pdce_conto4
on t_pdce_conto3.livello-1=t_pdce_conto4.livello
left join t_pdce_conto5
on t_pdce_conto4.livello-1=t_pdce_conto5.livello
left join t_pdce_conto6
on t_pdce_conto5.livello-1=t_pdce_conto6.livello
left join t_pdce_conto7
on t_pdce_conto6.livello-1=t_pdce_conto7.livello
) as zzz;

raise notice '3 - % ',clock_timestamp()::varchar;
RTN_MESSAGGIO:='Estrazione dei dati delle prime note''.';
raise notice 'Estrazione dei dati delle prime note';

return query  
select outp.* from (
with ord as (--ORD
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'ORD'::varchar tipo_pnota,
c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
s.soggetto_desc::varchar       descr_soggetto,
'ORD'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a  and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
     --   limit 1
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all       
select impacc.* from (          
--A,I 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'I' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.movgest_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest q                
WHERE d.collegamento_tipo_code in ('I','A') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_id=b.campo_pk_id and
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL 
),
sogcla as (
select distinct c.movgest_id,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest c,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select c.movgest_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest c,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and c.movgest_id=d.movgest_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and c.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_id=sogcla.movgest_id 
left join sog on 
movgest.movgest_id=sog.movgest_id 
) as impacc
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all         
select impsubacc.* from (          
--SA,SI 
with movgest as (
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'SI' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest_ts q,siac_t_movgest r               
WHERE d.collegamento_tipo_code in ('SI','SA') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and q.movgest_ts_id =b.campo_pk_id and
r.movgest_id=q.movgest_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL 
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubacc
--'MMGE','MMGS'
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all        
select impsubaccmod.* from (          
with movgest as (
/*SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 c.evento_code::varchar prov_pnota,
case when d.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
 FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_movgest r,
 siac_t_movgest_ts q, siac_t_modifica s,siac_r_modifica_stato t,
 siac_t_movgest_ts_det_mod u
WHERE d.collegamento_tipo_code in ('MMGE','MMGS') and
  a.ente_proprietario_id=p_ente_prop_id
  and  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and
p_data_reg_a 
and r.movgest_id=q.movgest_id 
and s.mod_id=b.campo_pk_id
and t.mod_id=s.mod_id
and q.movgest_id=r.movgest_id
and u.mod_stato_r_id=t.mod_stato_r_id
and u.movgest_ts_id=q.movgest_ts_id and 
a.data_cancellazione IS NULL AND
b.data_cancellazione IS NULL AND
c.data_cancellazione IS NULL AND
d.data_cancellazione IS NULL AND
g.data_cancellazione IS NULL AND
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
q.data_cancellazione IS NULL and
r.data_cancellazione IS NULL and 
s.data_cancellazione IS NULL and 
t.data_cancellazione IS NULL and 
u.data_cancellazione IS NULL  
union
select 
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,--uguale a tipo_pnota,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.movgest_numero||'-'||q.movgest_ts_code::varchar num_det_rif,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
, q.movgest_ts_id
  from siac_t_prima_nota a 
,siac_r_prima_nota_stato b, siac_d_prima_nota_stato c,siac_t_mov_ep d,
siac_t_mov_ep_det e, siac_t_reg_movfin f,siac_r_evento_reg_movfin g,
siac_d_evento h,siac_d_collegamento_tipo i, siac_d_evento_tipo l,
siac_t_modifica m, siac_r_modifica_stato n, siac_d_modifica_stato o,
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where a.ente_proprietario_id=p_ente_prop_id
and b.pnota_id=a.pnota_id
and a.bil_id=bil_id_in
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between     p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and m.mod_id=g.campo_pk_id
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and c.pnota_stato_code='D'
and p.mod_stato_r_id=n.mod_stato_r_id
and q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null 
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null*/
with modge as (select tbz.* from (
with modprnoteint as (
select 
g.campo_pk_id,
a.pnota_dataregistrazionegiornale,
a.pnota_progressivogiornale::integer num_prima_nota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_pnota,
 h.evento_code::varchar prov_pnota,
case when i.collegamento_tipo_code = 'MMGS' then 'IMP' else 'ACC'::varchar end tipo_documento ,
e.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
a.ente_proprietario_id,
e.pdce_conto_id,     
l.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
a.data_creazione::date  data_registrazione,
case when  e.movep_det_segno='Dare' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  e.movep_det_segno='Avere' THEN COALESCE(e.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
from 
siac_t_prima_nota a 
,siac_r_prima_nota_stato b, 
siac_d_prima_nota_stato c,
siac_t_mov_ep d,
siac_t_mov_ep_det e, 
siac_t_reg_movfin f,
siac_r_evento_reg_movfin g,
siac_d_evento h,
siac_d_collegamento_tipo i, 
siac_d_evento_tipo l
where a.ente_proprietario_id=p_ente_prop_id
and a.bil_id=bil_id_in
and b.pnota_id=a.pnota_id
and i.collegamento_tipo_code in ('MMGS','MMGE')
and c.pnota_stato_id=b.pnota_stato_id
and   a.pnota_dataregistrazionegiornale between  p_data_reg_da and
p_data_reg_a
and b.validita_fine is null
and d.regep_id=a.pnota_id
and e.movep_id=d.movep_id
and f.regmovfin_id=d.regmovfin_id
and g.regmovfin_id=f.regmovfin_id
and g.validita_fine is null
and h.evento_id=g.evento_id
and i.collegamento_tipo_id=h.collegamento_tipo_id
and l.evento_tipo_id=h.evento_tipo_id
and c.pnota_stato_code='D'
and  a.data_cancellazione is null 
and b.data_cancellazione is null 
and c.data_cancellazione is null 
and d.data_cancellazione is null 
and e.data_cancellazione is null 
and f.data_cancellazione is null 
and g.data_cancellazione is null 
and h.data_cancellazione is null 
and i.data_cancellazione is null 
and l.data_cancellazione is null 
)
,
moddd as (
select m.mod_id,n.mod_stato_r_id
 from siac_t_modifica m, 
siac_r_modifica_stato n, 
siac_d_modifica_stato o
where m.ente_proprietario_id=p_ente_prop_id 
and n.mod_id=m.mod_id
and n.validita_fine is null
and o.mod_stato_id=n.mod_stato_id
and m.data_cancellazione is null 
and n.data_cancellazione is null 
and o.data_cancellazione is null
) 
select 
moddd.mod_stato_r_id,
modprnoteint.pnota_dataregistrazionegiornale,
modprnoteint.num_prima_nota,
modprnoteint.tipo_pnota,
modprnoteint.prov_pnota,
modprnoteint.tipo_documento,
modprnoteint.data_registrazione_movimento,
modprnoteint.numero_documento,
modprnoteint.ente_proprietario_id,
modprnoteint.pdce_conto_id,     
modprnoteint.tipo_movimento,
modprnoteint.data_det_rif,
modprnoteint.data_registrazione,
modprnoteint.importo_dare,                    
modprnoteint.importo_avere           
 from modprnoteint join moddd
on  moddd.mod_id=modprnoteint.campo_pk_id)
as tbz
) ,
modsog as (
select p.mod_stato_r_id,q.movgest_ts_id,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
 from 
siac_r_movgest_ts_sog_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
,
modimp as (
select p.mod_stato_r_id,q.movgest_ts_id 
,r.movgest_numero||'-'||q.movgest_ts_code num_det_rif
from 
siac_t_movgest_ts_det_mod p,siac_t_movgest_ts q,siac_t_movgest r
where 
p.ente_proprietario_id=p_ente_prop_id and
 q.movgest_ts_id=p.movgest_ts_id
and r.movgest_id=q.movgest_id
and p.data_cancellazione is null 
and q.data_cancellazione is null
and r.data_cancellazione is null)
select 
modge.pnota_dataregistrazionegiornale,
modge.num_prima_nota,
modge.tipo_pnota,
modge.prov_pnota,
modge.tipo_documento ,--uguale a tipo_pnota,
modge.data_registrazione_movimento,
modge.numero_documento,
case when modsog.movgest_ts_id is null then modimp.num_det_rif else modsog.num_det_rif end num_det_rif,
modge.ente_proprietario_id,
modge.pdce_conto_id,     
modge.tipo_movimento,
modge.data_det_rif,
modge.data_registrazione,
modge.importo_dare,                    
modge.importo_avere           
, case when modsog.movgest_ts_id is null then modimp.movgest_ts_id else modsog.movgest_ts_id end movgest_ts_id
from modge left join
modsog on modge.mod_stato_r_id=modsog.mod_stato_r_id
left join
modimp on modge.mod_stato_r_id=modimp.mod_stato_r_id
),
sogcla as (
select distinct d.movgest_ts_id ,b.soggetto_classe_code,b.soggetto_classe_desc
From  siac_r_movgest_ts_sogclasse a,siac_d_soggetto_classe b,siac_t_movgest_ts d where a.ente_proprietario_id=p_ente_prop_id
and b.soggetto_classe_id=a.soggetto_classe_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
),
sog as (
select d.movgest_ts_id, b.soggetto_id,
b.soggetto_code,b.soggetto_desc from siac_r_movgest_ts_sog a,
siac_t_soggetto b,siac_t_movgest_ts d 
where a.ente_proprietario_id=p_ente_prop_id and b.soggetto_id=a.soggetto_id
and d.movgest_ts_id=a.movgest_ts_id
and a.data_cancellazione is null
and b.data_cancellazione is null
and d.data_cancellazione is null
)
select 
movgest.pnota_dataregistrazionegiornale,
movgest.num_prima_nota,
movgest.tipo_pnota,
movgest.prov_pnota,
case when sog.soggetto_id is null then sogcla.soggetto_classe_code else sog.soggetto_code end  cod_soggetto,
case when sog.soggetto_id is null then sogcla.soggetto_classe_desc else sog.soggetto_desc end descr_soggetto,
movgest.tipo_documento,
movgest.data_registrazione_movimento,
movgest.numero_documento,
movgest.num_det_rif,
movgest.ente_proprietario_id,
movgest.pdce_conto_id,     
movgest.tipo_movimento,
movgest.data_det_rif,
movgest.data_registrazione,
movgest.importo_dare,                    
movgest.importo_avere           
 from movgest left join sogcla on 
movgest.movgest_ts_id=sogcla.movgest_ts_id 
left join sog on 
movgest.movgest_ts_id=sog.movgest_ts_id 
) as impsubaccmod
--LIQ
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union 
union all 
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'LIQ'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'LIQ'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
q.liq_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.liq_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_liquidazione q,
       siac_r_liquidazione_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('L') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.liq_id=b.campo_pk_id and
        r.liq_id=q.liq_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--DOC
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
'FAT'::varchar tipo_pnota,
 c.evento_code::varchar prov_pnota,
t.soggetto_code::varchar cod_soggetto,
 t.soggetto_desc::varchar       descr_soggetto,
'FAT'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
r.doc_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
r.doc_data_emissione::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_subdoc q,
       siac_t_doc  r,
       siac_r_doc_sog s,
       siac_t_soggetto t                                       
WHERE d.collegamento_tipo_code in ('SS','SE') and
  a.ente_proprietario_id=p_ente_prop_id
  and
  a.regmovfin_id = b.regmovfin_id AND
        c.evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in 
        and    l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
        q.subdoc_id=b.campo_pk_id and
        r.doc_id=q.doc_id and 
        s.doc_id=r.doc_id and 
        s.soggetto_id=t.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL/*
SELECT   
m.pnota_dataregistrazionegiornale,
m.pnota_progressivogiornale::integer num_prima_nota,
'' tipo_pnota,
 c.evento_code::varchar prov_pnota,
s.soggetto_code::varchar cod_soggetto,
 s.soggetto_desc::varchar       descr_soggetto,
'' tipo_documento ,--uguale a tipo_pnota,
l.data_creazione::date data_registrazione_movimento,
'' numero_documento,
q.ord_numero::varchar num_det_rif,
a.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
q.ord_emissione_data::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_reg_movfin a,
       siac_r_evento_reg_movfin b,
       siac_d_evento c,
       siac_d_collegamento_tipo d,
       siac_d_evento_tipo g,
       siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
       siac_t_ordinativo q,
       siac_r_ordinativo_soggetto  r,
       siac_t_soggetto  s                                       
WHERE d.collegamento_tipo_code in ('OI','OP') and
  a.ente_proprietario_id=p_ente_prop_id and
  a.regmovfin_id = b.regmovfin_id AND
        c.	evento_id = b.evento_id AND
        d.collegamento_tipo_id = c.collegamento_tipo_id AND
        g.evento_tipo_id = c.evento_tipo_id AND
        b.validita_fine is null and
        a.bil_id=m.bil_id and 
        m.bil_id=bil_id_in and
        l.regmovfin_id = a.regmovfin_id AND
        l.regep_id = m.pnota_id AND
        m.pnota_id = n.pnota_id AND
        o.pnota_stato_id = n.pnota_stato_id AND
         n.validita_fine is null and
        p.movep_id=l.movep_id  and 
        o.pnota_stato_code='D' and 
        m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a and
        q.ord_id=b.campo_pk_id and
        r.ord_id=q.ord_id and 
        s.soggetto_id=r.soggetto_id AND
        r.validita_fine is null and
        a.data_cancellazione IS NULL AND
        b.data_cancellazione IS NULL AND
        c.data_cancellazione IS NULL AND
        d.data_cancellazione IS NULL AND
        g.data_cancellazione IS NULL AND
        l.data_cancellazione IS NULL AND
        m.data_cancellazione IS NULL AND
        n.data_cancellazione IS NULL AND
        o.data_cancellazione IS NULL AND
        p.data_cancellazione IS NULL AND
        q.data_cancellazione IS NULL AND
        r.data_cancellazione IS NULL AND
        s.data_cancellazione IS NULL*/
-- 07/07/2017: le union NON devono escludere i record eventualmente duplicati
--   quindi si deve usare la UNION ALL.
-- union         
union all 
--lib
SELECT   
m.pnota_dataregistrazionegiornale::date,
m.pnota_progressivogiornale::integer num_prima_nota,
case when dd.evento_code='AAP' then 'AAP'::varchar when dd.evento_code='APP' then 'APP'::varchar
else 'LIB'::varchar end tipo_pnota,
 dd.evento_code::varchar prov_pnota,
m.pnota_desc::varchar cod_soggetto,
 ''::varchar       descr_soggetto,
'LIB'::varchar tipo_documento,
l.data_creazione::date data_registrazione_movimento,
''::varchar numero_documento,
''::varchar num_det_rif,
m.ente_proprietario_id,
p.pdce_conto_id,     
g.evento_tipo_code::varchar  tipo_movimento,
null::date data_det_rif,
m.data_creazione::date  data_registrazione,
case when  p.movep_det_segno='Dare' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_dare,                    
case when  p.movep_det_segno='Avere' THEN COALESCE(p.movep_det_importo,0)::numeric  else 0::numeric  end importo_avere           
  FROM siac_t_mov_ep l,
       siac_t_prima_nota m,
       siac_r_prima_nota_stato n,
       siac_d_prima_nota_stato o,
       siac_t_mov_ep_det p,
siac_t_causale_ep	aa,
siac_d_causale_ep_tipo bb,
siac_r_evento_causale cc,
siac_d_evento dd,
siac_d_evento_tipo g
where 
l.ente_proprietario_id=p_ente_prop_id
and l.regep_id=m.pnota_id
and n.pnota_id=m.pnota_id
and o.pnota_stato_id=n.pnota_stato_id
and p.movep_id=l.movep_id
and aa.causale_ep_id=l.causale_ep_id
and bb.causale_ep_tipo_id=aa.causale_ep_tipo_id
and bb.causale_ep_tipo_code='LIB'
and cc.causale_ep_id=aa.causale_ep_id
and dd.evento_id=cc.evento_id 
and g.evento_tipo_id=dd.evento_tipo_id and
 m.pnota_dataregistrazionegiornale between 
        p_data_reg_da and p_data_reg_a  and
l.data_cancellazione IS NULL AND
m.data_cancellazione IS NULL AND
n.data_cancellazione IS NULL AND
o.data_cancellazione IS NULL AND
p.data_cancellazione IS NULL AND
aa.data_cancellazione IS NULL AND
bb.data_cancellazione IS NULL AND
cc.data_cancellazione IS NULL AND
dd.data_cancellazione IS NULL AND  
g.data_cancellazione IS NULL 
AND  n.validita_fine IS NULL
AND  cc.validita_fine IS NULL
AND  m.bil_id = bil_id_in
AND  o.pnota_stato_code = 'D' -- SIAC-5893
        )
        ,cc as 
        ( WITH RECURSIVE my_tree AS 
(-- Seed
  SELECT a.pdce_conto_id ,a.pdce_conto_id_padre,a.pdce_conto_code,a.pdce_conto_desc,a.livello,1 livellotree
  FROM siac_t_pdce_conto a WHERE  a.pdce_conto_id= pdce_conto_id_in
  UNION
  -- Recursive Term
  SELECT b.pdce_conto_id ,b.pdce_conto_id_padre ,b.pdce_conto_code,b.pdce_conto_desc,b.livello,t.livellotree+1  
  FROM my_tree as t INNER JOIN siac_t_pdce_conto b  ON t.pdce_conto_id_padre = b.pdce_conto_id  
)
SELECT my_tree.pdce_conto_id, my_tree.pdce_conto_code, my_tree.livello
from my_tree 
),
bb as (select * from siac_rep_struttura_pdce bb where bb.utente=user_table)
        /* bb as (select pdce_conto.livello, pdce_conto.pdce_conto_id,pdce_conto.pdce_conto_code codice_conto,
        pdce_conto.pdce_conto_desc descr_pdce_livello,strutt_pdce.*
    	from siac_t_pdce_conto	pdce_conto,
            siac_rep_struttura_pdce strutt_pdce
        where ((pdce_conto.livello=0 
            		AND strutt_pdce.pdce_liv0_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=1 
            		AND strutt_pdce.pdce_liv1_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=2 
            		AND strutt_pdce.pdce_liv2_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=3 
            		AND strutt_pdce.pdce_liv3_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=4 
            		AND strutt_pdce.pdce_liv4_id=pdce_conto.pdce_conto_id)
            	OR (pdce_conto.livello=5 
            		AND strutt_pdce.pdce_liv5_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=6 
            		AND strutt_pdce.pdce_liv6_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=7 
            		AND strutt_pdce.pdce_liv7_id=pdce_conto.pdce_conto_id)
                OR (pdce_conto.livello=8 
            		AND strutt_pdce.pdce_liv8_id=pdce_conto.pdce_conto_id))
         and pdce_conto.ente_proprietario_id=p_ente_prop_id 
         and pdce_conto.pdce_conto_code=p_pdce_v_livello
        and strutt_pdce.utente=user_table
         and pdce_conto.data_cancellazione is NULL)*/
         select   
nome_ente_in,
bb.pdce_liv0_id::integer  id_pdce0 ,
bb.pdce_liv0_code::varchar codice_pdce0 ,
bb.pdce_liv0_desc  descr_pdce0 ,
bb.pdce_liv1_id id_pdce1,
bb.pdce_liv1_code::varchar  codice_pdce1 ,
bb.pdce_liv1_desc::varchar  descr_pdce1 ,
bb.pdce_liv2_id  id_pdce2 ,
bb.pdce_liv2_code::varchar codice_pdce2 ,
bb.pdce_liv2_desc::varchar  descr_pdce2 ,
bb.pdce_liv3_id  id_pdce3 ,
bb.pdce_liv3_code::varchar  codice_pdce3 ,
bb.pdce_liv3_desc::varchar  descr_pdce3 ,
bb.pdce_liv4_id   id_pdce4 ,
bb.pdce_liv4_code::varchar  codice_pdce4 ,
bb.pdce_liv4_desc::varchar  descr_pdce4 ,
bb.pdce_liv5_id   id_pdce5 ,
bb.pdce_liv5_code::varchar  codice_pdce5 ,
bb.pdce_liv5_desc::varchar  descr_pdce5 ,
bb.pdce_liv6_id   id_pdce6 ,
bb.pdce_liv6_code::varchar  codice_pdce6 ,
bb.pdce_liv6_desc::varchar  descr_pdce6 ,
bb.pdce_liv7_id   id_pdce7 ,
bb.pdce_liv7_code::varchar  codice_pdce7 ,
bb.pdce_liv7_desc::varchar  descr_pdce7 ,
coalesce(bb.pdce_liv8_id,0)::integer   id_pdce8 ,
coalesce(bb.pdce_liv8_code,'')::varchar  codice_pdce8 ,
coalesce(bb.pdce_liv8_desc,'')::varchar  descr_pdce8, 
ord.data_registrazione,
ord.num_prima_nota,
ord.tipo_pnota tipo_pnota,
ord.prov_pnota,
ord.cod_soggetto, 
ord.descr_soggetto,
ord.tipo_documento tipo_documento,--uguale a tipo_pnota,
ord.data_registrazione_movimento,
''::varchar numero_documento,
ord.num_det_rif,
ord.data_det_rif,
ord.importo_dare,                    
ord.importo_avere,             
--bb.livello::integer,
cc.livello::integer,
ord.tipo_movimento,
0::numeric  saldo_prec_dare,
0::numeric  saldo_prec_avere ,
0::numeric saldo_ini_dare ,
0::numeric saldo_ini_avere ,
--bb.codice_conto::varchar   code_pdce_livello ,
cc.pdce_conto_code::varchar   code_pdce_livello ,
''::varchar  display_error 
from ord join cc on ord.pdce_conto_id=cc.pdce_conto_id
cross join bb 
) as outp
;
  
 delete from siac_rep_struttura_pdce 	where utente=user_table;
  
exception
	when no_data_found THEN
		raise notice 'Prime note non trovate' ;
		--return next;
	when others  THEN
		--raise notice 'errore nella lettura delle prime note ';
        RAISE EXCEPTION '% Errore : %-%.',SQLSTATE,'MASTRINO',substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;
-- SIAC-5893 FINE


--Inizio SIAC-5909

CREATE OR REPLACE FUNCTION siac.fnc_siac_cons_entita_mandato_from_soggetto_total (
  _uid_soggetto integer
)
RETURNS bigint AS
$body$
DECLARE
	total bigint;
BEGIN

	SELECT coalesce(count(*),0) into total
	from (
with ord_join_outer as (
		with ord_join as (
			with ordinativo as (
				select
					a.ord_id as uid,
					a.ord_numero,
					a.ord_desc,
					a.ord_emissione_data,
					e.ord_stato_desc,
					g.ord_ts_det_importo as importo,
					f.ord_ts_code
				from
					siac_t_ordinativo a,
					siac_r_ordinativo_stato d,
					siac_d_ordinativo_stato e,
					siac_t_ordinativo_ts f,
					siac_t_ordinativo_ts_det g,
					siac_d_ordinativo_ts_det_tipo h,
					siac_d_ordinativo_tipo i
				where d.ord_id=a.ord_id
				and d.ord_stato_id=e.ord_stato_id
				and now() BETWEEN d.validita_inizio and COALESCE(d.validita_fine,now())
				and f.ord_id=a.ord_id
				and g.ord_ts_id=f.ord_ts_id
				and h.ord_ts_det_tipo_id=g.ord_ts_det_tipo_id
				and h.ord_ts_det_tipo_code = 'A'
				and i.ord_tipo_id=a.ord_tipo_id
				and i.ord_tipo_code='P'
				and a.data_cancellazione is null
				and d.data_cancellazione is null
				and e.data_cancellazione is null
				and f.data_cancellazione is null
				and g.data_cancellazione is null
				and i.data_cancellazione is null
			),
			soggetto as (
				select
					b.ord_id,
					c.soggetto_code,
					c.soggetto_desc
				from
					siac_r_ordinativo_soggetto b,
					siac_t_soggetto c
				where b.soggetto_id=c.soggetto_id
				and c.soggetto_id=_uid_soggetto
				and now() BETWEEN b.validita_inizio and COALESCE(b.validita_fine,now())
				and b.data_cancellazione is null
				and c.data_cancellazione is null
			),
			attoamm as (
				select
					m.ord_id,
					n.attoamm_id,
					n.attoamm_numero,
					n.attoamm_anno,
					q.attoamm_stato_desc,
					o.attoamm_tipo_code,
					o.attoamm_tipo_desc
				from
					siac_r_ordinativo_atto_amm m,
					siac_t_atto_amm n,
					siac_d_atto_amm_tipo o,
					siac_r_atto_amm_stato p,
					siac_d_atto_amm_stato q
				where n.attoamm_id=m.attoamm_id
				and o.attoamm_tipo_id=n.attoamm_tipo_id
				and p.attoamm_id=n.attoamm_id
				and p.attoamm_stato_id=q.attoamm_stato_id
				and now() BETWEEN p.validita_inizio and coalesce (p.validita_fine,now())
				and now() BETWEEN m.validita_inizio and COALESCE(m.validita_fine,now())
				and q.attoamm_stato_code<>'ANNULLATO'
				and m.data_cancellazione is null
				and n.data_cancellazione is null
				and o.data_cancellazione is null
				and p.data_cancellazione is null
				and q.data_cancellazione is null
			),
			capitolo as (
				select
					r.ord_id,
					s.elem_id,
					s.elem_code,
					s.elem_code2,
					s.elem_code3,
					s.elem_desc
				from
					siac_r_ordinativo_bil_elem r,
					siac_t_bil_elem s
				where s.elem_id=r.elem_id
				and r.data_cancellazione is null
				and s.data_cancellazione is null
				and now() BETWEEN r.validita_inizio and coalesce (r.validita_fine,now())
			),
			modpag as (
				with modpag_noncessione as (
					select
						c2.ord_id,
						e2.accredito_tipo_code,
						e2.accredito_tipo_desc
					FROM
						siac_r_ordinativo_modpag c2,
						siac_t_modpag d2,
						siac_d_accredito_tipo e2
					where c2.modpag_id=d2.modpag_id
					and e2.accredito_tipo_id=d2.accredito_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null--??forse da commentare siac-5670
					and e2.data_cancellazione is null
				),
				modpag_cessione as (
					select
						c2.ord_id,
						e2.relaz_tipo_code accredito_tipo_code,
						e2.relaz_tipo_desc accredito_tipo_desc
					from
						siac_r_ordinativo_modpag c2,
						siac_r_soggetto_relaz d2,
						siac_d_relaz_tipo e2
					where d2.soggetto_relaz_id = c2.soggetto_relaz_id
					and e2.relaz_tipo_id = d2.relaz_tipo_id
					and now() BETWEEN c2.validita_inizio and coalesce (c2.validita_fine,now())
					and c2.data_cancellazione is null
					and d2.data_cancellazione is null
					and e2.data_cancellazione is null
				)
				select *
				from modpag_noncessione
				UNION ALL
				select *
				from modpag_cessione
			)
			select *
			from
				           ordinativo
				CROSS JOIN soggetto
				CROSS JOIN attoamm
				CROSS JOIN capitolo
				LEFT OUTER JOIN modpag on  (ordinativo.uid=modpag.ord_id)
			where ordinativo.uid=soggetto.ord_id
			and ordinativo.uid=attoamm.ord_id
			and ordinativo.uid=capitolo.ord_id
			--and ordinativo.uid=modpag.ord_id
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
			and x.classif_tipo_code IN ('CDC', 'CDR')
			and z.data_cancellazione is NULL
			and x.data_cancellazione is NULL
			and y.data_cancellazione is NULL
		)
		select *
		from ord_join
		left outer join sac_attoamm on ord_join.attoamm_id=sac_attoamm.attoamm_id
	),
	provv_cassa as (
		select
			a2.ord_id,
			b2.provc_anno,
			b2.provc_numero,
			b2.provc_data_convalida
		from
			siac_r_ordinativo_prov_cassa a2,
			siac_t_prov_cassa b2
		where b2.provc_id=a2.provc_id
		and now() BETWEEN a2.validita_inizio and coalesce (a2.validita_fine,now())
		and a2.data_cancellazione is NULL
		and b2.data_cancellazione is NULL
	)
	select
		ord_join_outer.uid,
		ord_join_outer.ord_numero,
		ord_join_outer.ord_desc,
		ord_join_outer.ord_emissione_data,
		ord_join_outer.soggetto_code,
		ord_join_outer.soggetto_desc,
		ord_join_outer.accredito_tipo_code,
		ord_join_outer.accredito_tipo_desc,
		ord_join_outer.ord_stato_desc,
		ord_join_outer.importo,
		ord_join_outer.ord_ts_code,
		ord_join_outer.attoamm_numero,
		ord_join_outer.attoamm_anno,
		ord_join_outer.attoamm_stato_desc,
		ord_join_outer.classif_code as attoamm_sac_code,
		ord_join_outer.classif_desc as attoamm_sac_desc,
		ord_join_outer.attoamm_tipo_code,
		ord_join_outer.attoamm_tipo_desc,
		ord_join_outer.elem_id as uid_capitolo,
		ord_join_outer.elem_code as num_capitolo,
		ord_join_outer.elem_code2 as num_articolo,
		ord_join_outer.elem_code3 as num_ueb,
		ord_join_outer.elem_desc as capitolo_desc,
		provv_cassa.provc_anno,
		provv_cassa.provc_numero,
		provv_cassa.provc_data_convalida
	from ord_join_outer
	left outer join provv_cassa on ord_join_outer.uid=provv_cassa.ord_id





	) as ord_id;
	
	return total;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

--Fine SIAC-5909

-- SIAC-5908: aggiornamento da parte del CSI -  Maurizio  - INIZIO

CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitaincassaremovgest (
  movgest_ts_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
number_out numeric;
tot_imp_ts numeric;
tot_imp_ord numeric;
tot_imp_subdoc numeric;
tot_imp_ord_sudoc numeric;
tot_imp_predoc numeric;
tot_mod_prov numeric;

BEGIN

--number_out:=1000.3;
number_out:=0.0;
tot_imp_ts:=0.0;
tot_imp_ord:=0.0;
tot_imp_subdoc:=0.0;
tot_imp_ord_sudoc:=0.0;
tot_imp_predoc:=0.0;

--SET TIME ZONE 'CET';


  
    select sum(e.movgest_ts_det_importo)
    into tot_imp_ts
    from siac_t_movgest_ts a,
         siac_d_movgest_ts_tipo b,
         siac_t_movgest c,
         siac_d_movgest_tipo d,
         siac_t_movgest_ts_det e,
         siac_d_movgest_ts_det_tipo f
    where a.movgest_ts_id = movgest_ts_id_in and
          a.movgest_ts_tipo_id = b.movgest_ts_tipo_id and
          a.movgest_id = c.movgest_id and
          c.movgest_tipo_id = d.movgest_tipo_id and
          e.movgest_ts_id = a.movgest_ts_id and
          f.movgest_ts_det_tipo_id = e.movgest_ts_det_tipo_id and
          f.movgest_ts_det_tipo_code = 'A' and
          a.data_cancellazione is null and
          now() between a.validita_inizio and
          coalesce(a.validita_fine, now()) and
          b.data_cancellazione is null and
          now() between b.validita_inizio and
          coalesce(b.validita_fine, now()) and
          c.data_cancellazione is null and
          now() between c.validita_inizio and
          coalesce(c.validita_fine, now()) and
          d.data_cancellazione is null and
          now() between d.validita_inizio and
          coalesce(d.validita_fine, now()) and
          e.data_cancellazione is null and
          now() between e.validita_inizio and
          coalesce(e.validita_fine, now()) and
          f.data_cancellazione is null and
          now() between f.validita_inizio and
          coalesce(f.validita_fine, now());

-- somma importoAttuale ordinativi  : in stato <> ANNULLATO

 select coalesce(sum(c.ord_ts_det_importo), 0)
 into tot_imp_ord
 from siac_r_ordinativo_ts_movgest_ts a,
      siac_t_ordinativo_ts b,
      siac_t_ordinativo_ts_det c,
      siac_d_ordinativo_ts_det_tipo d,
      siac_t_ordinativo e,
      siac_d_ordinativo_stato f,
      siac_r_ordinativo_stato g,
      siac_t_movgest_ts h
 where 
       --a.movgest_ts_id = movgest_ts_id_in  and
       (
       h.movgest_ts_id = movgest_ts_id_in 
       or h.movgest_ts_id_padre = movgest_ts_id_in
       ) 
       AND
       a.movgest_ts_id=h.movgest_ts_id and
       a.ord_ts_id = b.ord_ts_id and
       c.ord_ts_id = b.ord_ts_id and
       c.ord_ts_det_tipo_id = d.ord_ts_det_tipo_id and
       d.ord_ts_det_tipo_code = 'A' and
       e.ord_id = b.ord_id and
       e.ord_id = g.ord_id and
       g.ord_stato_id = f.ord_stato_id and
       f.ord_stato_code != 'A' and
       a.data_cancellazione is null and
       now() between a.validita_inizio and
       coalesce(a.validita_fine, now()) and
       b.data_cancellazione is null and
       now() between b.validita_inizio and
       coalesce(b.validita_fine, now()) and
       c.data_cancellazione is null and
       now() between c.validita_inizio and
       coalesce(c.validita_fine, now()) and
       d.data_cancellazione is null and
       now() between d.validita_inizio and
       coalesce(d.validita_fine, now()) and
       e.data_cancellazione is null and
       now() between e.validita_inizio and
       coalesce(e.validita_fine, now()) and
       f.data_cancellazione is null and
       now() between f.validita_inizio and
       coalesce(f.validita_fine, now()) and
       g.data_cancellazione is null and
       now() between g.validita_inizio and
       coalesce(g.validita_fine, now());


-- somma (importo - importoDaDedurre) subdocumenti di entrata collegati al movgest:  in stato <> A

 select coalesce(sum(a1.subdoc_importo - coalesce(a1.subdoc_importo_da_dedurre,0)),0) into tot_imp_subdoc
 from
    siac_r_subdoc_movgest_ts a, siac_t_subdoc a1,  siac_t_doc a2, 
    siac_d_doc_stato a3, siac_r_doc_stato a4 , siac_d_doc_tipo a5
    where
    a.movgest_ts_id =  movgest_ts_id_in--172
    and a.subdoc_id = a1.subdoc_id
    and a1.doc_id = a2.doc_id
    and a4.doc_id = a2.doc_id
    and a4.doc_stato_id = a3.doc_stato_id
    and a3.doc_stato_code != 'A' and  a3.doc_stato_code != 'ST'
    and a2.doc_tipo_id=a5.doc_tipo_id
    and a5.doc_tipo_code <> 'NCV' 
    and a5.data_cancellazione is null
    and a.data_cancellazione is null
    and now() between  a.validita_inizio 
    and coalesce(a.validita_fine, now())
   	and a1.data_cancellazione is null
    and now() between  a1.validita_inizio 
    and coalesce(a1.validita_fine, now()) 
   	and a2.data_cancellazione is null
    and now() between  a2.validita_inizio 
    and coalesce(a2.validita_fine, now()) 
   	and a3.data_cancellazione is null
    and now() between  a3.validita_inizio
     and coalesce(a3.validita_fine, now()) 
       and a4.data_cancellazione is null
    and now() between  a4.validita_inizio 
    and coalesce(a4.validita_fine, now())
    ;

-- somma (importo) degli ordinativi collegate a subdocumenti di entrata collegati al movgest iniziale

select coalesce(sum(c.ord_ts_det_importo),0)  into tot_imp_ord_sudoc
    from
    siac_r_ordinativo_ts_movgest_ts a, siac_t_ordinativo_ts b, siac_t_ordinativo_ts_det c,
    siac_r_subdoc_ordinativo_ts e,siac_d_ordinativo_ts_det_tipo f, siac_t_ordinativo g, 
    siac_d_ordinativo_stato h, 
    siac_r_ordinativo_stato i
    where
    a.movgest_ts_id =  movgest_ts_id_in--172
    and a.ord_ts_id = e.ord_ts_id
    and a.ord_ts_id = b.ord_ts_id
    and c.ord_ts_id = b.ord_ts_id
    and g.ord_id=b.ord_id
    and i.ord_id=g.ord_id
    and h.ord_stato_id=i.ord_stato_id
    and h.ord_stato_code<>'A'
    and f.ord_ts_det_tipo_id=c.ord_ts_det_tipo_id 
    and f.ord_ts_det_tipo_code='A'
    and now() between  i.validita_inizio and coalesce(i.validita_fine, now()) 
    and now() between  a.validita_inizio and coalesce(a.validita_fine, now()) 
    and now() between  b.validita_inizio and coalesce(b.validita_fine, now()) 
    and now() between  c.validita_inizio and coalesce(c.validita_fine, now()) 
    and now() between  e.validita_inizio and coalesce(e.validita_fine, now()) 
    and a.data_cancellazione is null
    and b.data_cancellazione is null
    and c.data_cancellazione is null
    and e.data_cancellazione is null
    and f.data_cancellazione is null
    and g.data_cancellazione is null
    and h.data_cancellazione is null
    and i.data_cancellazione is null
    ;


-- somma predoc collegati al movgest : in stato I o C
 select coalesce(sum (a1.predoc_importo),0)  into tot_imp_predoc
 from
    siac_r_predoc_movgest_ts a, siac_t_predoc a1, siac_d_predoc_stato a3, siac_r_predoc_stato a4
    where
    a.movgest_ts_id = movgest_ts_id_in
    and a.predoc_id = a1.predoc_id
    and a1.predoc_id = a4.predoc_id
    and a4.predoc_stato_id = a3.predoc_stato_id
    and (a3.predoc_stato_code 
    = 'I' or  a3.predoc_stato_code = 'C')
    and a.data_cancellazione is null
    and now() between  a.validita_inizio
    and coalesce(a.validita_fine, now()) 
   	and a1.data_cancellazione is null
    and now() between  a1.validita_inizio
    and coalesce(a1.validita_fine, now()) 
 	and a3.data_cancellazione is null
    and now() between  a3.validita_inizio
    and coalesce(a3.validita_fine, now()) 
    and a4.data_cancellazione is null
    and now() between  a4.validita_inizio
    and coalesce(a4.validita_fine, now()) 
    ;


--nuova sezione CR 740

select coalesce(sum(c.movgest_ts_det_importo),0) into tot_mod_prov
from siac_t_modifica a, siac_r_modifica_stato b,
siac_t_movgest_ts_det_mod c, siac_t_movgest_ts_det d,
siac_t_movgest_ts e, siac_d_modifica_stato f, siac_t_atto_amm g,
siac_r_atto_amm_stato h, siac_d_atto_amm_stato i
where
e.movgest_ts_id = movgest_ts_id_in
and f.mod_stato_code = 'V' -- la modifica deve essere valida
and i.attoamm_stato_code = 'PROVVISORIO' -- atto provvisorio
and c.movgest_ts_det_importo > 0 -- importo positivo
--
and a.mod_id = b.mod_id
and c.mod_stato_r_id = b.mod_stato_r_id
and d.movgest_ts_det_id = c.movgest_ts_det_id
and e.movgest_ts_id = d.movgest_ts_id
and f.mod_stato_id = b.mod_stato_id
and a.attoamm_id = g.attoamm_id
and g.attoamm_id = h.attoamm_id
and h.attoamm_stato_id = i.attoamm_stato_id
-- date
and a.data_cancellazione is null
and now() between a.validita_inizio and coalesce(a.validita_fine, now())
and b.data_cancellazione is null
and now() between b.validita_inizio and coalesce(b.validita_fine, now())
and c.data_cancellazione is null
and now() between c.validita_inizio and coalesce(c.validita_fine, now())
and d.data_cancellazione is null
and now() between d.validita_inizio and coalesce(d.validita_fine, now())
and e.data_cancellazione is null
and now() between e.validita_inizio and coalesce(e.validita_fine, now())
and f.data_cancellazione is null
and now() between f.validita_inizio and coalesce(f.validita_fine, now())
and g.data_cancellazione is null
and now() between g.validita_inizio and coalesce(g.validita_fine, now())
and h.data_cancellazione is null
and now() between h.validita_inizio and coalesce(h.validita_fine, now())
and i.data_cancellazione is null;

raise notice 'tot_mod_prov:%',tot_mod_prov;  


--importoattuale

number_out:=tot_imp_ts -  tot_imp_ord  - (tot_imp_subdoc - tot_imp_ord_sudoc) - tot_imp_predoc   ;

number_out:=number_out - tot_mod_prov;
return number_out;



END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- SIAC-5908: aggiornamento da parte del CSI -  Maurizio  - FINE


-- Sezione gestione azioni


--regione
INSERT INTO
  siac.siac_r_ruolo_op_azione
(
  ruolo_op_id,
  azione_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select e.ruolo_op_id, f.azione_id , now(), d.ente_proprietario_id, 'admin_3.26.0'
 from siac_t_azione d, siac_r_ruolo_op_azione c,siac_d_ruolo_op e, siac_t_azione f
 where
 d.azione_code like '%OP-GESREP2-BilCons%'
and c.azione_id=d.azione_id
and e.ruolo_op_id=c.ruolo_op_id
and f.ente_proprietario_id=d.ente_proprietario_id
and f.azione_code in ('OP-GESREP2-BilCons-2017',
'OP-GESREP2-BilCons-2016')
and d.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and not exists (select 1 from siac_r_ruolo_op_azione z where z.azione_id=f.azione_id
and z.ruolo_op_id=e.ruolo_op_id
);

--EELL
INSERT INTO
  siac.siac_r_ruolo_op_azione
(
  ruolo_op_id,
  azione_id,
  validita_inizio,
  ente_proprietario_id,
  login_operazione
)
select e.ruolo_op_id, f.azione_id , now(), d.ente_proprietario_id, 'admin_3.26.0'
 from siac_t_azione d, siac_r_ruolo_op_azione c,siac_d_ruolo_op e, siac_t_azione f
 where
 d.azione_code like '%OP-GESREP1-BilCons%'
and c.azione_id=d.azione_id
and e.ruolo_op_id=c.ruolo_op_id
and f.ente_proprietario_id=d.ente_proprietario_id
and f.azione_code in ('OP-GESREP1-BilCons-2017',
'OP-GESREP1-BilCons-2016')
and d.data_cancellazione is null
and c.data_cancellazione is null
and e.data_cancellazione is null
and f.data_cancellazione is null
and not exists (select 1 from siac_r_ruolo_op_azione z where z.azione_id=f.azione_id
and z.ruolo_op_id=e.ruolo_op_id
);


update siac_r_ruolo_op_azione
set data_cancellazione = now(),
    login_operazione = login_operazione || '3.26.0'
where azione_id in (
                     select a.azione_id
                     from siac_t_azione a
                     where a.azione_code in ('OP-GESREP1-BilCons',
                       'OP-GESREP2-BilCons')
      );
      
update siac_t_azione       
set data_cancellazione = now(),
    login_operazione = login_operazione || '3.26.0'
where azione_code in ('OP-GESREP1-BilCons',
                       'OP-GESREP2-BilCons');
					   
-- SIAC-5834 INIZIO
update siac_t_class
set    validita_fine = to_date('31/12/2016','dd/mm/yyyy'), login_operazione = login_operazione||'- SIAC5834'
where  classif_code = '2.9';
-- SIAC-5834 FINE					   