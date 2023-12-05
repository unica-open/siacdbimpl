/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop table if exists siac.bck_fase_bil_t_prev_apertura_bil_elem_det_comp;
CREATE TABLE siac.bck_fase_bil_t_prev_apertura_bil_elem_det_comp
(
  bck_fase_bil_prev_ape_comp_id serial,
  elem_bck_det_comp_id integer not null,
  elem_bck_det_id      INTEGER NOT NULL,
  elem_bck_det_comp_tipo_id INTEGER NOT NULL,
  elem_bck_det_importo NUMERIC,
  elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  elem_bck_login_operazione VARCHAR(200) NOT NULL,
  elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  elem_bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  fase_bil_elab_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_bck_fase_bil_t_prev_ape_bil_elem_det_comp PRIMARY KEY(bck_fase_bil_prev_ape_comp_id),
  CONSTRAINT fk_bck_fase_bil_t_prev_ape_bil_elem_det_comp_1 FOREIGN KEY (elem_bck_det_id)
    REFERENCES siac_t_bil_elem_det(elem_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT fk_bck_fase_bil_t_prev_ape_bil_elem_det_comp_2 FOREIGN KEY (elem_bck_det_comp_id)
    REFERENCES siac_t_bil_elem_det_comp(elem_det_comp_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT fk_bck_fase_bil_t_prev_ape_bil_elem_det_comp_3 FOREIGN KEY (elem_bck_det_comp_tipo_id)
    REFERENCES siac_d_bil_elem_det_comp_tipo(elem_det_comp_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fk_bck_fase_bil_t_prev_ape_bil_elem_det_comp_4 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fk_bck_fase_bil_t_prev_ape_bil_elem_det_comp_5 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE siac.bck_fase_bil_t_prev_apertura_bil_elem_det_comp
IS 'Apertura bilancio previsione - bck dettagli componenti importo previsione equivalente sovrascritta da gestione anno precedente';

alter table siac.bck_fase_bil_t_prev_apertura_bil_elem_det_comp owner to siac;


drop table if exists siac.bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp;

CREATE TABLE bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
(
  bck_fase_bil_gest_prov_ape_comp_id serial,
  elem_bck_det_comp_id integer not null,
  elem_bck_det_id      INTEGER NOT NULL,
  elem_bck_det_comp_tipo_id INTEGER NOT NULL,
  elem_bck_det_importo NUMERIC,
  elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  elem_bck_login_operazione VARCHAR(200) NOT NULL,
  elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  elem_bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  fase_bil_elab_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_bck_fase_bil_t_prov_ape_bil_elem_det_comp PRIMARY KEY(bck_fase_bil_gest_prov_ape_comp_id),
  CONSTRAINT fk_bck_fase_bil_t_prov_ape_bil_elem_det_comp_1 FOREIGN KEY (elem_bck_det_id)
    REFERENCES siac_t_bil_elem_det(elem_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT fk_bck_fase_bil_t_prov_ape_bil_elem_det_comp_2 FOREIGN KEY (elem_bck_det_comp_id)
    REFERENCES siac_t_bil_elem_det_comp(elem_det_comp_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT fk_bck_fase_bil_t_prov_ape_bil_elem_det_comp_3 FOREIGN KEY (elem_bck_det_comp_tipo_id)
    REFERENCES siac_d_bil_elem_det_comp_tipo(elem_det_comp_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fk_bck_fase_bil_t_prov_ape_bil_elem_det_comp_4 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fk_bck_fase_bil_t_prov_ape_bil_elem_det_comp_5 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
IS 'Apertura bilancio gestione provvisorio - bck struttura gestione corrente [siac_t_bil_elem_det_comp] sovrascritta da gestione anno precedente';

alter table siac.bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp owner to siac;

drop table if exists siac.bck_fase_bil_t_prev_approva_bil_elem_det_comp;


CREATE TABLE siac.bck_fase_bil_t_prev_approva_bil_elem_det_comp (
  bck_fase_bil_prev_app_comp_id serial,
  elem_bck_det_comp_id integer not null,
  elem_bck_det_id      INTEGER NOT NULL,
  elem_bck_det_comp_tipo_id INTEGER NOT NULL,
  elem_bck_det_importo NUMERIC,
  elem_bck_data_creazione TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  elem_bck_data_modifica TIMESTAMP WITHOUT TIME ZONE,
  elem_bck_login_operazione VARCHAR(200) NOT NULL,
  elem_bck_validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  elem_bck_validita_fine TIMESTAMP WITHOUT TIME ZONE,
  fase_bil_elab_id INTEGER NOT NULL,
  validita_inizio TIMESTAMP WITHOUT TIME ZONE NOT NULL,
  validita_fine TIMESTAMP WITHOUT TIME ZONE,
  data_creazione TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_modifica TIMESTAMP WITHOUT TIME ZONE DEFAULT now() NOT NULL,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  ente_proprietario_id INTEGER NOT NULL,
  login_operazione VARCHAR(200) NOT NULL,
  CONSTRAINT pk_bck_fase_bil_t_prev_app_bil_elem_det_comp PRIMARY KEY(bck_fase_bil_prev_app_comp_id),
  CONSTRAINT fk_bck_fase_bil_t_prev_app_bil_elem_det_comp_1 FOREIGN KEY (elem_bck_det_id)
    REFERENCES siac_t_bil_elem_det(elem_det_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT fk_bck_fase_bil_t_prev_app_bil_elem_det_comp_2 FOREIGN KEY (elem_bck_det_comp_id)
    REFERENCES siac_t_bil_elem_det_comp(elem_det_comp_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
   CONSTRAINT fk_bck_fase_bil_t_prev_app_bil_elem_det_comp_3 FOREIGN KEY (elem_bck_det_comp_tipo_id)
    REFERENCES siac_d_bil_elem_det_comp_tipo(elem_det_comp_tipo_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fk_bck_fase_bil_t_prev_app_bil_elem_det_comp_4 FOREIGN KEY (fase_bil_elab_id)
    REFERENCES fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT fk_bck_fase_bil_t_prev_app_bil_elem_det_comp_5 FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

COMMENT ON TABLE bck_fase_bil_t_prev_approva_bil_elem_det_comp
IS 'Approvazione bilancio previsione - bck dettagli importo gestione equivalente sovrascritta da previsione - per siac_t_bil_elem_det';

alter table siac.bck_fase_bil_t_prev_approva_bil_elem_det_comp owner to siac;


drop table if exists siac.fase_bil_t_variazione_gest;
CREATE TABLE siac.fase_bil_t_variazione_gest
 (
  fase_bil_var_gest_id SERIAL,
  fase_bil_elab_id INTEGER NOT NULL,
  variazione_id    integer not null,
  bil_id INTEGER NOT NULL,
  variazione_stato_id integer not null,
  variazione_stato_tipo_id integer not null,
  variazione_stato_new_id integer,
  variazione_stato_tipo_new_id integer,
  fl_cambia_stato boolean,
  fl_applica_var boolean,
  fl_elab VARCHAR DEFAULT 'N'::character varying NOT NULL,
  scarto_code VARCHAR,
  scarto_desc VARCHAR,
  data_creazione TIMESTAMP WITHOUT TIME ZONE default now(),
  data_modifica TIMESTAMP WITHOUT TIME ZONE,
  data_cancellazione TIMESTAMP WITHOUT TIME ZONE,
  login_operazione VARCHAR,
  ente_proprietario_id INTEGER,
  CONSTRAINT pk_fase_bil_t_var_gest PRIMARY KEY(fase_bil_var_gest_id),
  CONSTRAINT fase_bil_t_elaborazione_fase_bil_t_var_gest FOREIGN KEY (fase_bil_elab_id)
    REFERENCES siac.fase_bil_t_elaborazione(fase_bil_elab_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_bil_fase_bil_t_var_gest FOREIGN KEY (bil_id)
    REFERENCES siac.siac_t_bil(bil_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_var_fase_bil_t_var_gest FOREIGN KEY (variazione_id)
    REFERENCES siac.siac_t_variazione(variazione_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE,
  CONSTRAINT siac_t_ente_proprietario_fase_bil_t_var_gest FOREIGN KEY (ente_proprietario_id)
    REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION
    NOT DEFERRABLE
)
WITH (oids = false);

alter table siac.fase_bil_t_variazione_gest owner to siac;


insert into fase_bil_d_elaborazione_tipo
(
  fase_bil_elab_tipo_code,
  fase_bil_elab_tipo_desc,
  validita_inizio,
  login_operazione,
  ente_proprietario_id
)
select
'APE_VAR_GEST',
'Variazioni di bilancio - gestione',
now(),
'SIAC-7495',
ente.ente_proprietario_id
from siac_t_ente_proprietario ente
where ente.ente_proprietario_id  in (2,3,4,5,10,14,16)
and   not exists
(
select 1
from fase_bil_d_elaborazione_tipo tipo
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.fase_bil_elab_tipo_code='APE_VAR_GEST'
);

drop FUNCTION if exists siac.fnc_fasi_bil_prev_apertura_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemPrevTipo varchar,
  bilElemGestTipo varchar,
  elemPrevEq      boolean, 
  importiGest     boolean, 
  faseBilElabId   integer, 
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop FUNCTION if exists siac.fnc_fasi_bil_provv_apertura_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemGestTipo varchar,
  elemGestEq      boolean,
  importiGest     boolean,
  faseBilElabId   integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop FUNCTION if exists siac.fnc_fasi_bil_prev_approva_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemPrevTipo varchar,
  bilElemGestTipo varchar,
  elemGestEq      boolean, 
  importiPrev     boolean, 
  faseBilElabId   integer, 
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp, 
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop FUNCTION if exists siac.fnc_siac_bko_gestisci_variazione
(
  enteProprietarioId     integer,
  annoBilancio           integer,
  variazioneNum          integer,
  cambiaStatoVar         boolean,
  statoVar               varchar,
  applicaVar             boolean,
  loginOperazione         varchar,
  dataElaborazione       timestamp
);

drop FUNCTION if exists siac.fnc_fasi_bil_variazione_gest
(
annobilancio       varchar,
elencoVariazioni   text,
nomeTabella        varchar,
flagCambiaStato    varchar, 
flagApplicaVar     varchar, 
statoVar           varchar,
enteProprietarioId varchar,
loginoperazione    VARCHAR,
dataelaborazione   TIMESTAMP,
OUT faseBilElabIdRet   varchar,
OUT codiceRisultato    varchar,
OUT messaggioRisultato VARCHAR
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_prev_apertura_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemPrevTipo varchar,
  bilElemGestTipo varchar,
  elemPrevEq      boolean, -- trattamento capitoli di gestione equivalenti esistenti
  importiGest     boolean, -- impostazione importi di previsione da gestione anno precedente
  faseBilElabId   integer, -- identificativo elaborazione
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp, -- deve essere passato con now() o clock_timepstamp()
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	APE_PREV_DA_GEST CONSTANT varchar:='APE_PREV';
    SY_PER_TIPO      CONSTANT varchar:='SY';
    STI_DET_TIPO     CONSTANT varchar:='STI';
    SRI_DET_TIPO     CONSTANT varchar:='SRI';
    SCI_DET_TIPO     CONSTANT varchar:='SCI';

    STA_DET_TIPO     CONSTANT varchar:='STA';
    STR_DET_TIPO     CONSTANT varchar:='STR';
    SCA_DET_TIPO     CONSTANT varchar:='SCA';
    STASS_DET_TIPO   CONSTANT varchar:='STASS';
    STCASS_DET_TIPO  CONSTANT varchar:='STCASS';
    STRASS_DET_TIPO  CONSTANT varchar:='STRASS';

    -- SIAC-5788
    MI_DET_TIPO      CONSTANT varchar:='MI';

    -- SIAC-7495 Sofia 09.09.2020
    CAP_UG_ST CONSTANT varchar:='CAP-UG';
    CAP_UP_ST CONSTANT varchar:='CAP-UP';

	prevEqEsiste      integer:=null;
    prevEqApri     integer:=null;
    prevEqEsisteNoGest  integer:=null;
    codResult         integer:=null;
	dataInizioVal     timestamp:=null;

    bilancioId        integer:=null;

    periodoId        integer:=null;
    periodoAnno1Id   integer:=null;
    periodoAnno2Id   integer:=null;

    detTipoStaId     integer:=null;
    detTipoScaId     integer:=null;
    detTipoStrId     integer:=null;

    detTipoStiId     integer:=null;
    detTipoSciId     integer:=null;
    detTipoSriId     integer:=null;

    detTipoStassId     integer:=null;
    detTipoStcassId     integer:=null;
    detTipoStrassId     integer:=null;

    detTipoMiId       integer:=null;


BEGIN

	messaggioRisultato:='';
    codiceRisultato:=0;


    dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Apertura bilancio di previsione.Aggiornamento importi Previsione '||bilElemPrevTipo||' da Gestione anno precedente'||bilElemGEstTipo||
    					'.Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STI_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStiId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

	strMessaggio:='Lettura validita'' identificativo tipo importo '||STA_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSciId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCA_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoScaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    strMessaggio:='Lettura validita'' identificativo tipo importo '||SRI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSriId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SRI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STR_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStrId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STR_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    --- stanziamenti assestamento di gestione 'STASS','STCASS','STRASS'
    strMessaggio:='Lettura validita'' identificativo tipo importo '||STASS_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStassId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STASS_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

	strMessaggio:='Lettura validita'' identificativo tipo importo '||STCASS_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStcassId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STCASS_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STRASS_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStrassId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STRASS_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||MI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoMiId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=MI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    strMessaggio:='Lettura validita'' identificativo elaborazione faseBilElabId='||faseBilElabId||'.';
    codResult:=null;
	select  1 into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.ente_proprietario_id=enteProprietarioId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fase_bil_elab_esito!='IN2';

    if codResult is not null then
    	raise exception ' Identificatvo elab. non valido.';
    end if;


  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id,per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   per.data_cancellazione is null;

  	strMessaggio:='Lettura periodoAnno1Id  per annoBilancio+1='||(annoBilancio+1)::varchar||'.';
    select per.periodo_id into strict periodoAnno1Id
    from siac_t_periodo per, siac_d_periodo_tipo tipo
    where per.ente_proprietario_id=enteProprietarioId
    and   per.anno::INTEGER=annoBilancio+1
    and   tipo.periodo_tipo_id=per.periodo_tipo_id
    and   tipo.periodo_tipo_code=SY_PER_TIPO
    and   per.data_cancellazione is null;


  	strMessaggio:='Lettura periodoAnno2Id  per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    select per.periodo_id into strict periodoAnno2Id
    from siac_t_periodo per, siac_d_periodo_tipo tipo
    where per.ente_proprietario_id=enteProprietarioId
    and   per.anno::INTEGER=annoBilancio+2
    and   tipo.periodo_tipo_id=per.periodo_tipo_id
    and   tipo.periodo_tipo_code=SY_PER_TIPO
    and   per.data_cancellazione is null;


	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    -- cancellazione logica importi di previsione equivalente esistente
    if elemPrevEq=true then
        strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti da aggiornare da gestione anno precedente.';

    	select distinct 1 into prevEqEsiste
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_gest_id is not null
        limit 1;

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

        if prevEqEsiste is not null then
	    /* 07.07.2016 Sostituito con backup di seguito
         strMessaggio:='Cancellazione logica importi capitoli di previsione equivalenti esistenti.';
    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_inizio=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_gest_id is not null
         and    det.elem_id=fase.elem_prev_id
         and    det.data_cancellazione is null
         and    det.validita_fine is null; */

	     -- 07.07.2016 Sofia inserimento backup
		 strMessaggio:='Inserimento backup importi capitoli di previsione equivalenti esistenti.';
         insert into bck_fase_bil_t_prev_apertura_bil_elem_det
         (elem_bck_id,
		  elem_bck_det_id,
		  elem_bck_det_importo,
		  elem_bck_det_flag,
		  elem_bck_det_tipo_id,
		  elem_bck_periodo_id,
		  elem_bck_data_creazione,
		  elem_bck_data_modifica,
		  elem_bck_login_operazione,
	      elem_bck_validita_inizio,
		  elem_bck_validita_fine,
	      fase_bil_elab_id,
		  validita_inizio,
          login_operazione,
          ente_proprietario_id
          )
          (select det.elem_id, det.elem_det_id, det.elem_det_importo,det.elem_det_flag,det.elem_det_tipo_id,
                  det.periodo_id,det.data_creazione,det.data_modifica,det.login_operazione,det.validita_inizio,
                  det.validita_fine, fase.fase_bil_elab_id,now(),loginOperazione,fase.ente_proprietario_id
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is not null
           and   det.elem_id=fase.elem_prev_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
          );

          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is not null
           and   det.elem_id=fase.elem_prev_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det bck
                             where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=det.elem_id
                             and   bck.data_cancellazione is null
                             and   bck.validita_fine is null);
           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

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

         -- SIAC-7495 Sofia 08.09.2020 - inizio
 		 if bilElemPrevTipo=CAP_UP_ST then
           -- Sofia inserimento backup componenti
           -- per capitoli di previsione esistenti relativi a capitoli di gestione esistenti in anno prec
           strMessaggio:='Inserimento backup importi capitoli di previsione equivalenti esistenti.Componenti.';
           insert into bck_fase_bil_t_prev_apertura_bil_elem_det_comp
           (
            elem_bck_det_comp_id,
            elem_bck_det_id,
            elem_bck_det_comp_tipo_id,
            elem_bck_det_importo,
            elem_bck_data_creazione,
            elem_bck_data_modifica,
            elem_bck_login_operazione,
            elem_bck_validita_inizio,
            elem_bck_validita_fine,
            fase_bil_elab_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
            )
            (select comp.elem_det_comp_id,
                    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.data_creazione,comp.data_modifica,comp.login_operazione,comp.validita_inizio,
                    comp.validita_fine, fase.fase_bil_elab_id,clock_timestamp(),loginOperazione,fase.ente_proprietario_id
             from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det,
                  siac_t_bil_elem_det_comp comp
             where fase.ente_proprietario_id=enteProprietarioId
             and   fase.bil_id=bilancioId
             and   fase.fase_bil_elab_id=faseBilElabId
             and   fase.data_cancellazione is null
             and   fase.validita_fine is null
             and   fase.elem_gest_id is not null
             and   det.elem_id=fase.elem_prev_id
             and   comp.elem_det_id=det.elem_det_id
             and   det.data_cancellazione is null
             and   det.validita_fine is null
             and   comp.data_cancellazione is null
             and   comp.validita_fine is null
            );

            codResult:=null;
            strmessaggio:=strMessaggio||' Verifica inserimento.';
            select 1  into codResult
            from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp
            where fase.ente_proprietario_id=enteProprietarioId
             and   fase.bil_id=bilancioId
             and   fase.fase_bil_elab_id=faseBilElabId
             and   fase.data_cancellazione is null
             and   fase.validita_fine is null
             and   fase.elem_gest_id is not null
             and   det.elem_id=fase.elem_prev_id
             and   comp.elem_det_id=det.elem_det_id
             and   det.data_cancellazione is null
             and   det.validita_fine is null
             and   comp.data_cancellazione is null
             and   comp.validita_fine is null
             and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det_comp bck
                               where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                               and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
                               and   bck.data_cancellazione is null
                               and   bck.validita_fine is null);
           if codResult is not null then raise exception ' Elementi senza backup importi componenti.'; end if;

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
          -- SIAC-7495 Sofia 08.09.2020 - fine
       end if;
    end if;

    strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti da aprire.';

	select distinct 1 into prevEqApri
    from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    limit 1;

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

    if prevEqApri is not null then
     strMessaggio:='Inserimento  importi capitoli di previsione da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prev_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
      and   det.elem_det_tipo_id not in (detTipoStassId,detTipoStcassId,detTipoStrassId) -- esclusione importi assestamento di gestione
      and   det.elem_det_tipo_id not in (detTipoMiId) -- esclusione importi massimo impegnabile SIAC-5788
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi iniziali capitoli di previsione da gestione attuali equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prev_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            (case when det.elem_det_tipo_id=detTipoScaId then detTipoSciId
                  when det.elem_det_tipo_id=detTipoStaId then detTipoStiId
                  when det.elem_det_tipo_id=detTipoStrId then detTipoSriId end),
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id in (detTipoScaId,detTipoStrId,detTipoStaId)
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi capitoli di previsione per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prev_id,
             0,
             det.elem_det_tipo_id,
             periodoAnno2Id,
             dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_prev_id
      and   det.periodo_id=periodoId
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

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

     --- controllo inserimento importi prec
     codResult:=null;
     strMessaggio:='Inserimento  importi capitoli di previsione da gestione equivalenti anno precedente.Verifica inserimento.';
     select 1  into codResult
     from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_nuovo fase
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   det.elem_id=fase.elem_prev_id
     and   det.data_cancellazione is null
     and   det.validita_fine is null
     limit 1;

     if codResult is null then
    	raise exception ' Non effettuato.';
     end if;

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


     -- SIAC-7495 Sofia 08.09.2020 - inizio
     if bilElemPrevTipo=CAP_UP_ST then
       -- inserimento componenti per nuovi capitolid i bilancio di previsione
       strMessaggio:='Inserimento  importi capitoli componenti di previsione annoBilancio='
                    ||annoBilancio::varchar
                    ||' e annoBilancio+1='
                    ||(annoBilancio+1)::varchar
                    ||'.';
       --- inserimento nuovi importi componenti
       insert into siac_t_bil_elem_det_comp
       (elem_det_id,
        elem_det_comp_tipo_id,
        elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select det.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               compgest.elem_det_importo,
               dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
             siac_t_bil_elem_det det,
             siac_t_bil_elem_det detGest,
             siac_t_bil_elem_det_comp compGest,siac_d_bil_elem_det_comp_tipo tipo_comp
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_prev_id
        and   det.periodo_id in ( periodoId, periodoAnno1Id)
        and   detGest.elem_id=fase.elem_id
        and   detGest.periodo_id=det.periodo_id
        and   detGest.elem_det_tipo_id=det.elem_det_tipo_id
        and   compGest.elem_det_id=detGest.elem_det_id
        and   tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   detGest.data_cancellazione is null
        and   detGest.validita_fine is null
        and   compGest.data_cancellazione is null
        and   compGest.validita_fine is null
        and   tipo_comp.data_cancellazione is null
       );

       strMessaggio:='Inserimento  importi capitoli componenti di previsione annoBilancio+2='
                    ||(annoBilancio+2)::varchar
                    ||'.';

       insert into siac_t_bil_elem_det_comp
       (elem_det_id,
        elem_det_comp_tipo_id,
        elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select det.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               0,
               dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
             siac_t_bil_elem_det det,
             siac_t_bil_elem_det detGest,
             siac_t_bil_elem_det_comp compGest,siac_d_bil_elem_det_comp_tipo tipo_comp
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_prev_id
        and   det.periodo_id = periodoAnno2Id
        and   detGest.elem_id=fase.elem_id
        and   detGest.periodo_id=periodoId
        and   detGest.elem_det_tipo_id=det.elem_det_tipo_id
        and   compGest.elem_det_id=detGest.elem_det_id
        and   tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   detGest.data_cancellazione is null
        and   detGest.validita_fine is null
        and   compGest.data_cancellazione is null
        and   compGest.validita_fine is null
        and   tipo_comp.data_cancellazione is null
       );

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

       --- controllo inserimento importi prec
       codResult:=null;
       strMessaggio:='Inserimento  importi componenti capitoli di previsione da gestione equivalenti anno precedente.Verifica inserimento.';
       select 1  into codResult
       from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
            siac_t_bil_elem_det_comp comp,siac_d_bil_elem_det_comp_tipo tipo
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   det.elem_id=fase.elem_prev_id
       and   comp.elem_det_id=det.elem_det_id
       and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   comp.data_cancellazione is null
       and   comp.validita_fine is null
       and   tipo.data_cancellazione is null
       limit 1;

       if codResult is null then
          raise exception ' Non effettuato.';
       end if;

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
     -- SIAC-7495 Sofia 08.09.2020 - fine
    end if;

--	raise notice 'elemPrevEq=% prevEqEsiste=%', elemPrevEq,prevEqEsiste;
	if elemPrevEq=true and prevEqEsiste is not null then
        -- sostituire con update

	    /* 07.07.2016 Sofia - sostituito con update di seguito
        strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prev_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    );*/

        strMessaggio:='Aggiornamento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
         and   det.elem_det_tipo_id not in (detTipoMiId)-- esclusione importi massimo impegnabile SIAC-5788
         and   detCor.elem_det_tipo_id=det.elem_det_tipo_id
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;

        strMessaggio:='Aggiornamento importi cassa iniziale capitoli di previsione esistenti da gestione cassa attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id=detTipoScaId
         and   detCor.elem_det_tipo_id=detTipoSciId
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;


		strMessaggio:='Aggiornamento importi competenza  iniziale capitoli di previsione esistenti da gestione competenza attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id=detTipoStaId
         and   detCor.elem_det_tipo_id=detTipoStiId
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi residui  iniziale capitoli di previsione esistenti da gestione residua attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
   	     and   fase.elem_prev_id is not null
         and   detCor.elem_id=fase.elem_prev_id
         and   detCor.periodo_id in (periodoId, periodoAnno1Id)
    	 and   det.elem_id=fase.elem_gest_id
         and   det.periodo_id in (periodoId, periodoAnno1Id)
         and   det.elem_det_tipo_id=detTipoStrId
         and   detCor.elem_det_tipo_id=detTipoSriId
         and   detCor.periodo_id=det.periodo_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
   	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;


        -- sostituire con update
        /* 07.07.2016 Sofia - sostituito con update sotto
        strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prev_id,
                0,
                det.elem_det_tipo_id,
                periodoAnno2Id,
                dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is not null
    	 and   det.elem_id=fase.elem_prev_id
         and   det.periodo_id =periodoId
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); */

        /* 07.07.2016 Sofia - aggiornamento a 0 degli importi del terzo anno  */
        strMessaggio:='Aggiornamento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
        update siac_t_bil_elem_det detCor
        set  elem_det_importo=0,
             data_modifica=now(),
             login_operazione=loginOperazione
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
         and  fase.bil_id=bilancioId
         and  fase.fase_bil_elab_id=faseBilElabId
	     and  fase.data_cancellazione is null
    	 and  fase.validita_fine is null
	     and  fase.elem_gest_id is not null
    	 and  detCor.elem_id=fase.elem_prev_id
         and  detCor.periodo_id =periodoAnno2Id
	     and  detCor.data_cancellazione is null
    	 and  detCor.validita_fine is null;

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

    	--- controllo inserimento importi prec
	    /* 07.07.2016 Sofia - non serve controllare inserimento perche sopra solo update
        codResult:=null;
    	strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente.Verifica inserimento.';
	    select 1  into codResult
    	from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_esiste fase
	    where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
    	and   fase.elem_gest_id is not null
	    and   det.elem_id=fase.elem_prev_id
    	and   det.data_cancellazione is null
	    and   det.validita_fine is null
        limit 1;

    	if codResult is null then
    		raise exception ' Non effettuato.';
	    end if;

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
        end if; */

	    -- 08.09.2020 Sofia - SIAC-7495 - inizio
       if bilElemPrevTipo=CAP_UP_ST then
          -- aggiornamento delle componenti per i capitoli di previsione presenti
          -- relativi a capitoli di gestione presenti in anno prec
          strMessaggio:='Aggiornamento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar
                       ||' e annoBilancio+2='||(annoBilancio+2)::varchar
                       ||'. Aggiornamento componenti esistenti in previsione.';
          update siac_t_bil_elem_det_comp detCompCor
          set  elem_det_importo=compGest.elem_det_importo,
               data_modifica=now(),
               login_operazione=loginOperazione
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_t_bil_elem_det detGest, siac_t_bil_elem_det_comp compGest,
               siac_d_bil_elem_det_comp_tipo tipo_comp
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id in ( periodoId,periodoAnno1Id)
           and  detGest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=detPrev.periodo_id
           and  detGest.elem_det_tipo_id=detprev.elem_det_tipo_id
           and  compGest.elem_det_id=detGest.elem_det_id
           and  detcompcor.elem_det_id=detPrev.elem_det_id
           and  compGest.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  tipo_comp.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  detCompCor.data_cancellazione is null
           and  detCompCor.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

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


          strMessaggio:='Aggiornamento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='
          			  ||(annoBilancio+2)::varchar
                      ||'. Aggiornamento componenti esistenti in previsione.';
          update siac_t_bil_elem_det_comp detCompCor
          set  elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_t_bil_elem_det detGest, siac_t_bil_elem_det_comp compGest,
               siac_d_bil_elem_det_comp_tipo tipo_comp
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id =periodoAnno2Id
           and  detGest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=periodoId
           and  compGest.elem_det_id=detGest.elem_det_id
           and  detcompcor.elem_det_id=detPrev.elem_det_id
           and  compGest.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  tipo_comp.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  detCompCor.data_cancellazione is null
           and  detCompCor.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

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

          -- azzeramento comp in prev non esistenti in gest
          strMessaggio:='Aggiornamento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='
                        ||(annoBilancio)::varchar
                        ||'. Azzeramento componenti previsione non esistenti in gestione.';
          update siac_t_bil_elem_det_comp detCompCor
          set  elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_d_bil_elem_det_comp_tipo tipo_comp
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detcompcor.elem_det_id=detPrev.elem_det_id
           and  tipo_comp.elem_det_comp_tipo_id=detcompCor.elem_det_comp_tipo_id
           and  not exists
           (
           select 1
           from siac_t_bil_elem_det detGest, siac_t_bil_elem_det_comp compGest
           where detGest.elem_id=fase.elem_gest_id
           and   detGest.elem_det_tipo_id=detprev.elem_det_tipo_id
           and   compGest.elem_det_id=detGest.elem_det_id
           and   compGest.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
           and   detGest.data_cancellazione is null
           and   detGest.validita_fine is null
           and   compGest.data_cancellazione is null
           and   compGest.validita_fine is null
           )
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detCompCor.data_cancellazione is null
           and  detCompCor.validita_fine is null;
           --and  tipo_comp.data_cancellazione is null;

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

          -- inserimento comp da gest  in prev non esistenti in prev
          strMessaggio:='Inserimento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio='
                       ||(annoBilancio)::varchar
                       ||' e annoBilancio+1='||(annoBilancio+1)::varchar
                       ||'.';
          insert into siac_t_bil_elem_det_comp
          (
              elem_det_id,
              elem_det_comp_tipo_id,
              elem_det_importo,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select
               detPrev.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               compGest.elem_det_importo,
               dataInizioVal,
               loginOperazione,
               fase.ente_proprietario_id
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_d_bil_elem_det_comp_tipo tipo_comp,
               siac_t_bil_elem_det detGest,
               siac_t_bil_elem_det_comp compGest
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id in (periodoId,periodoAnno1Id)
           and  detgest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=detPrev.periodo_id
           and  detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
           and  compGest.elem_det_id=detGest.elem_det_id
           and  tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
           and  not exists
           (
           select 1
           from  siac_t_bil_elem_det_comp compPrev
           where compPrev.elem_det_id=detPrev.elem_det_id
           and   compPrev.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
           and   compPrev.data_cancellazione is null
           and   compPrev.validita_fine is null
           )
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

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

          strMessaggio:='Inserimento importi componenti capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='
                       ||(annoBilancio+2)::varchar||'.';
          insert into siac_t_bil_elem_det_comp
          (
              elem_det_id,
              elem_det_comp_tipo_id,
              elem_det_importo,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
          )
          select
               detPrev.elem_det_id,
               tipo_comp.elem_det_comp_tipo_id,
               0,
               dataInizioVal,
               loginOperazione,
               fase.ente_proprietario_id
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
               siac_t_bil_elem_det detPrev,
               siac_d_bil_elem_det_comp_tipo tipo_comp,
               siac_t_bil_elem_det detGest,
               siac_t_bil_elem_det_comp compGest
          where fase.ente_proprietario_id=enteProprietarioId
           and  fase.bil_id=bilancioId
           and  fase.fase_bil_elab_id=faseBilElabId
           and  fase.data_cancellazione is null
           and  fase.validita_fine is null
           and  fase.elem_gest_id is not null
           and  detPrev.elem_id=fase.elem_prev_id
           and  detPrev.periodo_id=periodoAnno2Id
           and  detgest.elem_id=fase.elem_gest_id
           and  detGest.periodo_id=periodoId
           and  detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
           and  compGest.elem_det_id=detGest.elem_det_id
           and  tipo_comp.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
           and  not exists
           (
           select 1
           from  siac_t_bil_elem_det_comp compPrev
           where compPrev.elem_det_id=detPrev.elem_det_id
           and   compPrev.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
           and   compPrev.data_cancellazione is null
           and   compPrev.validita_fine is null
           )
           and  detPrev.data_cancellazione is null
           and  detPrev.validita_fine is null
           and  detGest.data_cancellazione is null
           and  detGest.validita_fine is null
           and  compGest.data_cancellazione is null
           and  compGest.validita_fine is null
           and  tipo_comp.data_cancellazione is null;

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
        enD if;
        -- 08.09.2020 Sofia - SIAC-7495 - fine

	end if;

    if elemPrevEq=true then

        strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti non presenti in gestione anno precedente.';

    	select  1 into prevEqEsisteNoGest
        from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_gest_id is null
        limit 1;
--raise notice 'prevEqEsisteNoGest=%', prevEqEsisteNoGest;

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

		if prevEqEsisteNoGest is not null then
        -- inserire backup
        strMessaggio:='Inserimento  backup importi  capitoli di previsione esistenti senza gestione equivalente anno precedente.';
        insert into bck_fase_bil_t_prev_apertura_bil_elem_det
         (elem_bck_id,
		  elem_bck_det_id,
		  elem_bck_det_importo,
		  elem_bck_det_flag,
		  elem_bck_det_tipo_id,
		  elem_bck_periodo_id,
		  elem_bck_data_creazione,
		  elem_bck_data_modifica,
		  elem_bck_login_operazione,
	      elem_bck_validita_inizio,
		  elem_bck_validita_fine,
	      fase_bil_elab_id,
		  validita_inizio,
          login_operazione,
          ente_proprietario_id
          )
          (select det.elem_id, det.elem_det_id, det.elem_det_importo,det.elem_det_flag,det.elem_det_tipo_id,
                  det.periodo_id,det.data_creazione,det.data_modifica,det.login_operazione,det.validita_inizio,
                  det.validita_fine, fase.fase_bil_elab_id,now(),loginOperazione,fase.ente_proprietario_id
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is null
           and   det.elem_id=fase.elem_prev_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
          );

          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	      and   fase.bil_id=bilancioId
    	  and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
	      and   fase.validita_fine is null
		  and   fase.elem_gest_id is null
          and   det.elem_id=fase.elem_prev_id
	      and   det.data_cancellazione is null
     	  and   det.validita_fine is null
          and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det bck
                             where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=det.elem_id
                             and   bck.data_cancellazione is null
                             and   bck.validita_fine is null);

           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

           strMessaggio:='Aggiornamento importi a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.';
           update siac_t_bil_elem_det detCor
           set elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
           where fase.ente_proprietario_id=enteProprietarioId
 	       and   fase.bil_id=bilancioId
     	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_gest_id is null
           and   detCor.elem_id=fase.elem_prev_id
	       and   detCor.data_cancellazione is null
     	   and   detCor.validita_fine is null;

         -- sostituire con update
   	     /* 07.07.2016 Sofia - sostituito con bck e update sopra
         strMessaggio:='Inserimento importi a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.';
  	     insert into siac_t_bil_elem_det
	     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
    	  validita_inizio, ente_proprietario_id, login_operazione)
	     (select fase.elem_prev_id, 0,
   		         det.elem_det_tipo_id,
	             det.periodo_id,
    	         dataInizioVal,det.ente_proprietario_id,loginOperazione
	      from fase_bil_t_prev_apertura_str_elem_prev_esiste fase, siac_t_bil_elem_det det
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_gest_id is null
    	  and   det.elem_id=fase.elem_prev_id
	      and   det.data_cancellazione is null
    	  and   det.validita_fine is null
	     ); */

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

		-- commentare tutte queste update
	    /*  07.07.2016 Sofia sostituito con back e update sopra
         strMessaggio:='Cancellazione logica importi capitoli di previsione esistenti senza gestione equivalente anno precedente.';

    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_apertura_str_elem_prev_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_gest_id is null
         and    det.elem_id=fase.elem_prev_id
         and    det.data_cancellazione is null
         and    dataElaborazione>det.validita_inizio -- date_trunc('DAY',det.validita_inizio) -- solo > per escludere quelli appena inseriti
         and    det.validita_fine is null;

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
         end if; */

         --- controllo inserimento importi prec
         /* 07.07.2016 Sofia non serve non sono inseriti ma aggiornati
         codResult:=null;
	     strMessaggio:='Inserimento importi a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.Verifica inserimento.';


    	 select  1  into codResult
	     from siac_t_bil_elem_det det , fase_bil_t_prev_apertura_str_elem_prev_esiste fase
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_gest_id is null
    	 and   det.elem_id=fase.elem_prev_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
         limit 1;

	     if codResult is null then
    		raise exception ' Non effettuato.';
	     end if;

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
         end if; */

        -- 09.09.2020 Sofia SIAC-7495 - inizio
        if bilElemPrevTipo=CAP_UP_ST then
          -- inserire backup
          strMessaggio:='Inserimento  backup importi componenti capitoli di previsione esistenti senza gestione equivalente anno precedente.';
          insert into bck_fase_bil_t_prev_apertura_bil_elem_det_comp
          (
            elem_bck_det_comp_id,
            elem_bck_det_id,
            elem_bck_det_comp_tipo_id,
            elem_bck_det_importo,
            elem_bck_data_creazione,
            elem_bck_data_modifica,
            elem_bck_login_operazione,
            elem_bck_validita_inizio,
            elem_bck_validita_fine,
            fase_bil_elab_id,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
           )
           (select  comp.elem_det_comp_id,
                    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.data_creazione,comp.data_modifica,comp.login_operazione,comp.validita_inizio,
                    comp.validita_fine, fase.fase_bil_elab_id,clock_timestamp(),loginOperazione,fase.ente_proprietario_id
            from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
                 siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp
            where fase.ente_proprietario_id=enteProprietarioId
            and   fase.bil_id=bilancioId
            and   fase.fase_bil_elab_id=faseBilElabId
            and   fase.data_cancellazione is null
            and   fase.validita_fine is null
            and   fase.elem_gest_id is null
            and   det.elem_id=fase.elem_prev_id
            and   comp.elem_det_id=det.elem_det_id
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   comp.data_cancellazione is null
            and   comp.validita_fine is null
           );

           codResult:=null;
           strmessaggio:=strMessaggio||' Verifica inserimento.';
           select 1  into codResult
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
                siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp
           where fase.ente_proprietario_id=enteProprietarioId
           and   fase.bil_id=bilancioId
           and   fase.fase_bil_elab_id=faseBilElabId
           and   fase.data_cancellazione is null
           and   fase.validita_fine is null
           and   fase.elem_gest_id is null
           and   det.elem_id=fase.elem_prev_id
           and   comp.elem_det_id=det.elem_det_id
           and   det.data_cancellazione is null
           and   det.validita_fine is null
           and   comp.data_cancellazione is null
           and   comp.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_apertura_bil_elem_det_comp bck
                              where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                              and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
                              and   bck.data_cancellazione is null
                              and   bck.validita_fine is null);

           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;


           strMessaggio:='Aggiornamento importi componenti a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.';
           update siac_t_bil_elem_det_comp detCompCor
           set elem_det_importo=0,
               data_modifica=now(),
               login_operazione=loginOperazione
           from fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
                siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
           and   fase.bil_id=bilancioId
           and   fase.fase_bil_elab_id=faseBilElabId
           and   fase.data_cancellazione is null
           and   fase.validita_fine is null
           and   fase.elem_gest_id is null
           and   det.elem_id=fase.elem_prev_id
           and   detCompCor.elem_det_id=det.elem_det_id
           and   detCompCor.data_cancellazione is null
           and   detCompCor.validita_fine is null;


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
         -- 09.09.2020 Sofia SIAC-7495 - fine
       end if;
    end if;


   -- SIAC-7495 Sofia 05.10.2020 - inizio
   if bilElemPrevTipo=CAP_UP_ST then

       strMessaggio:='Aggiornamento importi componenti a zero per capitoli di previsione nuovi : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_prev_apertura_str_elem_prev_nuovo fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UP_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
          /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_prev_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


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

    strMessaggio:='Aggiornamento importi componenti a zero per capitoli di previsione esistenti : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_prev_apertura_str_elem_prev_esiste fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UP_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
          /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_prev_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


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


   strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PREV_DA_GEST||' TERMINATA : AGGIORNAMENTO IMPORTI COMPLETATO.'
    where fase_bil_elab_id=faseBilElabId;

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

    messaggioRisultato:=strMessaggioFinale||'OK .';
    return;


exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_fasi_bil_prev_apertura_importi
(
   integer,
   varchar,
   varchar,
   varchar,
   boolean, 
   boolean, 
   integer, 
   integer,
   varchar,
   timestamp, 
   out  integer,
   out  varchar
) owner to siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_provv_apertura_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemGestTipo varchar,
  elemGestEq      boolean, -- trattamento capitoli di gestione equivalenti esistenti
  importiGest     boolean, -- impostazione importi di previsione da gestione anno precedente
  faseBilElabId   integer, -- identificativo elaborazione
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp, -- deve essere passato con now() o clock_timepstamp()
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	APE_PROV_DA_GEST CONSTANT varchar:='APE_PROV';
    SY_PER_TIPO      CONSTANT varchar:='SY';
    STI_DET_TIPO     CONSTANT varchar:='STI';
    SRI_DET_TIPO     CONSTANT varchar:='SRI';
    SCI_DET_TIPO     CONSTANT varchar:='SCI';

    STA_DET_TIPO     CONSTANT varchar:='STA';
    STR_DET_TIPO     CONSTANT varchar:='STR';
    SCA_DET_TIPO     CONSTANT varchar:='SCA';

    -- SIAC-7495 Sofia 14.09.2020
    CAP_UG_ST CONSTANT varchar:='CAP-UG';

	gestEqEsiste      integer:=null;
    gestEqApri     integer:=null;
    gestEqEsisteNoGest  integer:=null;
    codResult         integer:=null;
	dataInizioVal     timestamp:=null;

    bilancioId        integer:=null;

    periodoId        integer:=null;
    periodoAnno1Id   integer:=null;
    periodoAnno2Id   integer:=null;



    detTipoStaId     integer:=null;
    detTipoScaId     integer:=null;
    detTipoStrId     integer:=null;

    detTipoStiId     integer:=null;
    detTipoSciId     integer:=null;
    detTipoSriId     integer:=null;

BEGIN

	messaggioRisultato:='';
    codiceRisultato:=0;

    dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Apertura bilancio provvisorio di gestione.Aggiornamento importi Gestione '||bilElemGestTipo||' da Gestione anno precedente'||bilElemGEstTipo||
    					'.Anno bilancio='||annoBilancio::varchar||'.';


    strMessaggio:='Lettura validita'' identificativo elaborazione faseBilElabId='||faseBilElabId||'.';
    codResult:=null;
	select  1 into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.ente_proprietario_id=enteProprietarioId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fase_bil_elab_esito!='IN2';

    if codResult is not null then
    	raise exception ' Identificatvo elab. non valido.';
    end if;


  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id,per.periodo_id into strict bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   per.data_cancellazione is null;

  	strMessaggio:='Lettura periodoAnno1Id  per annoBilancio+1='||(annoBilancio+1)::varchar||'.';
    select per.periodo_id into strict periodoAnno1Id
    from siac_t_periodo per, siac_d_periodo_tipo tipo
    where per.ente_proprietario_id=enteProprietarioId
    and   per.anno::INTEGER=annoBilancio+1
    and   tipo.periodo_tipo_id=per.periodo_tipo_id
    and   tipo.periodo_tipo_code=SY_PER_TIPO
    and   per.data_cancellazione is null;


  	strMessaggio:='Lettura periodoAnno2Id  per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    select per.periodo_id into strict periodoAnno2Id
    from siac_t_periodo per, siac_d_periodo_tipo tipo
    where per.ente_proprietario_id=enteProprietarioId
    and   per.anno::INTEGER=annoBilancio+2
    and   tipo.periodo_tipo_id=per.periodo_tipo_id
    and   tipo.periodo_tipo_code=SY_PER_TIPO
    and   per.data_cancellazione is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STI_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStiId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

	strMessaggio:='Lettura validita'' identificativo tipo importo '||STA_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSciId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCA_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoScaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    strMessaggio:='Lettura validita'' identificativo tipo importo '||SRI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSriId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SRI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STR_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStrId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STR_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

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



    -- backup -- aggiornamento importi di gestione equivalente esistente
    if elemGestEq=true then
        strMessaggio:='Verifica esistenza elementi di bilancio provvisorio di gestione equivalenti da aggiornare da gestione anno precedente.';

    	select distinct 1 into gestEqEsiste
        from fase_bil_t_gest_apertura_provv fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_id is not null       -- esistenti in gestione precedente
        and   fase.elem_prov_id is not null
        and   fase.elem_prov_new_id is null
        limit 1;

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

        if gestEqEsiste is not null then
         -- inserire backup importi gestione esistente che devono poi essere sovrascritti
         -- al posto di update qui
        /* strMessaggio:='Cancellazione logica importi capitoli di gestione provvisoria equivalenti esistenti.';
    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_inizio=now(), login_operazione=loginOperazione
    	 from fase_bil_t_gest_apertura_provv fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
         and    fase.elem_id is not null
         and    fase.elem_prov_new_id is null
	     and    fase.elem_prov_id is not null
         and    det.elem_id=fase.elem_prov_id
         and    det.data_cancellazione is null
         and    det.validita_fine is null;*/
         strMessaggio:='Inserimento backup importi capitoli di gestione provvisoria equivalenti esistenti.';
         insert into bck_fase_bil_t_gest_apertura_provv_bil_elem_det
         (elem_bck_id,elem_bck_det_id,elem_bck_det_importo,elem_bck_det_flag,elem_bck_det_tipo_id,elem_bck_periodo_id,
          elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
          elem_bck_validita_inizio,elem_bck_validita_fine,
		  fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
         (select  det.elem_id, det.elem_det_id, det.elem_det_importo, det.elem_det_flag, det.elem_det_tipo_id, det.periodo_id,
          	      det.data_creazione, det.data_modifica, det.login_operazione, det.validita_inizio,det.validita_fine,
                  fase.fase_bil_elab_id, loginoperazione, now(),enteProprietarioId
          from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is not null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
          and   det.data_cancellazione is null
          and   det.validita_fine is null);

         -- verifica inserimento backup
		 codResult:=null;
         strMessaggio:=strMessaggio||' Verifica inserimento.';
         select 1 into codResult
         from  fase_bil_t_gest_apertura_provv fase
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
    	 and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.elem_id is not null      -- esistente in gestione precedente
         and   fase.elem_prov_new_id is null -- non nuovo
	     and   fase.elem_prov_id is not null -- esistente in gestione correge
         and   not exists ( select 1 from bck_fase_bil_t_gest_apertura_provv_bil_elem_det bck
							where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                            and   bck.elem_bck_id=fase.elem_prov_id
					        and   bck.data_cancellazione is null
					        and   bck.validita_fine is null )
         limit 1;
         if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;

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

        -- SIAC-7495 Sofia 14.09.2020 - inizio
        if bilElemGestTipo=CAP_UG_ST then
		-- bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
        strMessaggio:='Inserimento backup componenti importi capitoli di gestione provvisoria equivalenti esistenti.';
        insert into bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
        (elem_bck_det_comp_id,
		 elem_bck_det_id,
		 elem_bck_det_comp_tipo_id,
		 elem_bck_det_importo,
         elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
         elem_bck_validita_inizio,elem_bck_validita_fine,
		 fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
        (select  comp.elem_det_comp_id, comp.elem_det_id, comp.elem_det_comp_tipo_id, comp.elem_det_importo,
          	     comp.data_creazione, comp.data_modifica, comp.login_operazione, comp.validita_inizio,comp.validita_fine,
                 fase.fase_bil_elab_id, loginoperazione, clock_timestamp(),enteProprietarioId
          from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det,
               siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is not null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
          and   comp.elem_det_id=det.elem_det_id
--          and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null);
--          and   tipo.data_cancellazione is null);

         -- verifica inserimento backup
		 codResult:=null;
         strMessaggio:=strMessaggio||' Verifica inserimento.';
         select 1 into codResult
         from  fase_bil_t_gest_apertura_provv fase,
               siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
         where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   det.elem_id=fase.elem_prov_id
         and   comp.elem_det_id=det.elem_det_id
         --and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
    	 and   fase.data_cancellazione is null
         and   fase.validita_fine is null
         and   fase.elem_id is not null      -- esistente in gestione precedente
         and   fase.elem_prov_new_id is null -- non nuovo
	     and   fase.elem_prov_id is not null -- esistente in gestione correge
         and   det.data_cancellazione is null
         and   det.validita_fine is null
         and   comp.data_cancellazione is null
         and   comp.validita_fine is null
  --       and   tipo.data_cancellazione is null
         and   not exists ( select 1 from bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp bck
							where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                            and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
					        and   bck.data_cancellazione is null
					        and   bck.validita_fine is null )
         limit 1;
         if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;

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

        -- SIAC-7495 Sofia 14.09.2020 - fine
       end if;
    end if;

    strMessaggio:='Verifica esistenza elementi di bilancio provvisorio equivalenti da aprire.';

	select distinct 1 into gestEqApri
    from fase_bil_t_gest_apertura_provv fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.elem_id is not null
    and   fase.elem_prov_id is null
    and   fase.elem_prov_new_id is not null
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    limit 1;

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

    if gestEqApri is not null then
     strMessaggio:='Inserimento  importi capitoli di gestione provvisori da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prov_new_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
			det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_id is not null
      and   fase.elem_prov_id is null
      and   fase.elem_prov_new_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi iniziali capitoli di gestione provvisori da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prov_new_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
			(case when det.elem_det_tipo_id=detTipoScaId then detTipoSciId
                  when det.elem_det_tipo_id=detTipoStaId then detTipoStiId
                  when det.elem_det_tipo_id=detTipoStrId then detTipoSriId end),
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_id is not null
      and   fase.elem_prov_id is null
      and   fase.elem_prov_new_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
      and   det.elem_det_tipo_id in (detTipoScaId,detTipoStrId,detTipoStaId)
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi capitoli di gestione provvisori per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_prov_new_id,
             0,
             det.elem_det_tipo_id,
             periodoAnno2Id,
             dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_gest_apertura_provv fase,
           siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.elem_id is not null
      and   fase.elem_prov_id is null
      and   fase.elem_prov_new_id is not null
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.periodo_id=periodoId
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

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

     --- controllo inserimento importi prec
     codResult:=null;
     strMessaggio:='Inserimento  importi capitoli di previsione da gestione equivalenti anno precedente.Verifica inserimento.';
     select 1  into codResult
     from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.elem_id is not null
     and   fase.elem_prov_id is null
     and   fase.elem_prov_new_id is not null
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   det.elem_id=fase.elem_prov_new_id
     and   det.data_cancellazione is null
     and   det.validita_fine is null
     limit 1;

     if codResult is null then
    	raise exception ' Non effettuato.';
     end if;

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

     -- SIAC-7495 Sofia 14.09.2020 - inizio
     if bilElemGestTipo=CAP_UG_ST then

       strMessaggio:='Inserimento  componenti importi capitoli di gestione provvisori da gestione equivalenti anno precedente per annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
       --- inserimento nuovi importi
       insert into siac_t_bil_elem_det_comp
       (elem_det_id,elem_det_comp_tipo_id, elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select detGestNew.elem_det_id,
               tipo.elem_det_comp_tipo_id,
              (case when importiGest=true then comp.elem_det_importo
                    else 0 END),
              dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det,
             siac_t_bil_elem_det_comp comp,siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGestNew
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null
        and   fase.elem_prov_id is null
        and   fase.elem_prov_new_id is not null
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_id
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- impostazione degli importi dalla gestione anno prec per anno e anno+1
        and   comp.elem_det_id=det.elem_det_id
        and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
        and   detGestNew.elem_id=fase.elem_prov_new_id
        and   detGestNew.elem_det_tipo_id=det.elem_det_tipo_id
        and   detGestNew.periodo_id=det.periodo_id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   comp.data_cancellazione is null
        and   comp.validita_fine is null
        and   detGestNew.data_cancellazione is null
        and   detGestNew.validita_fine is null
        and   tipo.data_cancellazione is null
       );

       strMessaggio:='Inserimento componenti importi capitoli di gestione provvisori per annoBilancio+2='||(annoBilancio+2)::varchar||'.';
       --- inserimento nuovi importi
       insert into siac_t_bil_elem_det_comp
       (elem_det_id,elem_det_comp_tipo_id, elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select detGestNew.elem_det_id,
       		   tipo.elem_det_comp_tipo_id,
               0,
               dataInizioVal,det.ente_proprietario_id,loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det det,
             siac_t_bil_elem_det_comp comp,siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGestNew
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null
        and   fase.elem_prov_id is null
        and   fase.elem_prov_new_id is not null
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   det.elem_id=fase.elem_id
        and   det.periodo_id=periodoId
        and   comp.elem_det_id=det.elem_det_id
        and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
        and   detGestNew.elem_id=fase.elem_prov_new_id
        and   detGestNew.elem_det_tipo_id=det.elem_det_tipo_id
        and   detGestNew.periodo_id=periodoAnno2Id
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   comp.data_cancellazione is null
        and   comp.validita_fine is null
        and   detGestNew.data_cancellazione is null
        and   detGestNew.validita_fine is null
        and   tipo.data_cancellazione is null
       );

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

       --- controllo inserimento importi prec
       codResult:=null;
       strMessaggio:='Inserimento  importi capitoli di previsione da gestione equivalenti anno precedente.Verifica inserimento.';
       select 1  into codResult
       from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase,
            siac_t_bil_elem_det_comp comp, siac_d_bil_elem_det_comp_tipo tipo
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   fase.elem_id is not null
       and   fase.elem_prov_id is null
       and   fase.elem_prov_new_id is not null
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   det.elem_id=fase.elem_prov_new_id
       and   comp.elem_det_id=det.elem_det_id
       and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   comp.data_cancellazione is null
       and   comp.validita_fine is null
       and   tipo.data_cancellazione is null
       limit 1;

       if codResult is null then
          raise exception ' Non effettuato.';
       end if;

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
     -- SIAC-7495 Sofia 14.09.2020 - fine
    end if;

--	raise notice 'elemGestEq=% gestEqEsiste=%', elemPrevEq,prevEqEsiste;
	if elemGestEq=true and gestEqEsiste is not null then
        -- sostituire insert di nuovi dettagli con update su quelli esistenti di cui fatto backup ad inizio
	    /*strMessaggio:='Inserimento importi capitoli di gestione provvisorio esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prov_id,
            (case when importiGest=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null
         and   fase.elem_prov_id is not null
         and   fase.elem_prov_new_id is null
       	 and   det.elem_id=fase.elem_id
         and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
         and   det.periodo_id in (periodoId, periodoAnno1Id)
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); sostituito con update sotto */

        strMessaggio:='Aggiornamento importi capitoli di gestione provvisorio esistenti da gestione equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id not in (detTipoSciId,detTipoSriId,detTipoStiId)
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=det.elem_det_tipo_id -- stesso tipo importo
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

        strMessaggio:='Aggiornamento importi cassa inziale capitoli di gestione provvisorio esistenti da gestione cassa attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id=detTipoScaId
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detTipoSciId
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

		strMessaggio:='Aggiornamento importi residui inziale capitoli di gestione provvisorio esistenti da gestione residui attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id=detTipoStrId
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detTipoSriId
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

		strMessaggio:='Aggiornamento importi competenza inziale capitoli di gestione provvisorio esistenti da gestione competenza attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det detCor
        set elem_det_flag=det.elem_det_flag,
            elem_det_importo=det.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   det.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   det.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
        and   det.elem_det_tipo_id=detTipoStaId
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detTipoStiId
        and   detCor.periodo_id=det.periodo_id             -- su stesso periodo
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

        /*strMessaggio:='Inserimento importi capitoli di previsione esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_prov_id,
                0,
                det.elem_det_tipo_id,
                periodoAnno2Id,
                dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null
         and   fase.elem_prov_id is not null
         and   fase.elem_prov_new_id is null
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   det.elem_id=fase.elem_id
         and   det.periodo_id =periodoId
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); sostituito con update sotto */

        strMessaggio:='Aggiornamento importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
        update siac_t_bil_elem_det detCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   det.elem_id=fase.elem_id       -- gestione eq prec
         and   det.periodo_id =periodoId
         and   detCor.elem_id=fase.elem_prov_id -- gestione eq cor
         and   detCor.elem_det_tipo_id=det.elem_det_tipo_id -- tipo uguale
         and   detCor.periodo_id=periodoAnno2Id  --annoBilancio+2
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null;


        -- fine-sostituire insert di nuovi dettagli con update su quelli esistenti di cui fatto backup ad inizio
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

    	--- controllo inserimento importi prec
	    /* non si puo fare andiamo in aggiornamento
        codResult:=null;
    	strMessaggio:='Inserimento importi capitoli di gestione provvisorio esistenti da gestione equivalenti anno precedente.Verifica inserimento.';
	    select 1  into codResult
    	from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase
	    where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null
        and   fase.elem_prov_id is not null
        and   fase.elem_prov_new_id is null
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
	    and   det.elem_id=fase.elem_prov_id
    	and   det.data_cancellazione is null
	    and   det.validita_fine is null
        limit 1;

    	if codResult is null then
    		raise exception ' Non effettuato.';
	    end if;

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
        end if;*/

	 -- SIAC-7495 Sofia 14.09.2020 - inizio
     if bilElemGestTipo=CAP_UG_ST then

        strMessaggio:='Aggiornamento componenti importi competenza capitoli di gestione provvisorio esistenti da gestione competenza attuale equivalenti anno precedente annoBilancio='||annoBilancio::varchar||' e annoBilancio+1.';
		update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=compPrec.elem_det_importo,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compPrec,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detCor
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is not null          -- esistente in gestione equivalente prec
        and   fase.elem_prov_id is not null     -- esistente in gestione equivalente corr
        and   fase.elem_prov_new_id is null     -- non un nuovo inserimento
   	    and   detGestPrec.elem_id=fase.elem_id          -- dato gestione equivalente prec
        and   detGestPrec.periodo_id in (periodoId, periodoAnno1Id) -- annoBilancio, AnnoBilancio+1
		and   compPrec.elem_det_id=detGestPrec.elem_det_id
        and   tipo.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_id
        and   detCor.elem_id=fase.elem_prov_id  -- dato gestione equivalente corrente
        and   detCor.elem_det_tipo_id=detGestPrec.elem_det_tipo_id
        and   detCor.periodo_id=detGestPrec.periodo_id             -- su stesso periodo
        and   compCor.elem_det_id=detCor.elem_det_id
        and   compCor.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_id
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null
	    and   compCor.data_cancellazione is null
    	and   compCor.validita_fine is null
	    and   detGestPrec.data_cancellazione is null
    	and   detGestPrec.validita_fine is null
	    and   compPrec.data_cancellazione is null
    	and   compPrec.validita_fine is null
        and   tipo.data_cancellazione is null
        and   fase.data_cancellazione is null
    	and   fase.validita_fine is null;

        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='||(annoBilancio+2)::varchar||'.';
        update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
        	 siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compPrec,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detCor
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detGestPrec.elem_id=fase.elem_id       -- gestione eq prec
         and   detGestPrec.periodo_id =periodoId
         and   compPrec.elem_det_id=detGestPrec.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_id
         and   detCor.elem_id=fase.elem_prov_id -- gestione eq cor
         and   detCor.elem_det_tipo_id=detGestPrec.elem_det_tipo_id -- tipo uguale
         and   detCor.periodo_id=periodoAnno2Id  --annoBilancio+2
         and   compCor.elem_det_id=detCor.elem_det_id
         and   compCor.elem_det_comp_tipo_id=compPrec.elem_det_comp_tipo_Id
	     and   detGestPrec.data_cancellazione is null
    	 and   detGestPrec.validita_fine is null
	     and   compPrec.data_cancellazione is null
    	 and   compPrec.validita_fine is null
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null
	     and   compCor.data_cancellazione is null
    	 and   compCor.validita_fine is null
	     and   tipo.data_cancellazione is null;


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


        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio='
           ||(annoBilancio)::varchar
           || ' annoBilancio+1='||(annoBilancio+1)::varchar
           ||'. Azzeramento componenti non esistenti in anno prec.';
        update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id in (periodoId,periodoAnno1Id)
         and   compCor.elem_det_id=detCor.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compGestPrec
         where detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=detCor.periodo_id
         and   compGestPrec.elem_Det_id=detGestPrec.elem_det_id
         and   compGestPrec.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   detGestPrec.data_cancellazione is null
         and   detGestPrec.validita_fine is null
         and   compGestPrec.data_cancellazione is null
         and   compGestPrec.validita_fine is null
         )
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null
	     and   compCor.data_cancellazione is null
    	 and   compCor.validita_fine is null;
	     --and   tipo.data_cancellazione is null;

        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='
           ||(annoBilancio+2)::varchar
           ||'. Azzeramento componenti non esistenti in anno prec.';
        update siac_t_bil_elem_det_comp compCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id =periodoAnno2Id
         and   compCor.elem_det_id=detCor.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det detGestPrec, siac_t_bil_elem_det_comp compGestPrec
         where detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=periodoId
         and   compGestPrec.elem_Det_id=detGestPrec.elem_det_id
         and   compGestPrec.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   detGestPrec.data_cancellazione is null
         and   detGestPrec.validita_fine is null
         and   compGestPrec.data_cancellazione is null
         and   compGestPrec.validita_fine is null
         )
	     and   detCor.data_cancellazione is null
    	 and   detCor.validita_fine is null
	     and   compCor.data_cancellazione is null
    	 and   compCor.validita_fine is null;
--	     and   tipo.data_cancellazione is null;

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


        strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio='
           ||(annoBilancio)::varchar
           || ' annoBilancio+1='||(annoBilancio+1)::varchar
           ||'. Inserimento componenti non esistenti in anno corrente.';
        insert into siac_t_bil_elem_det_comp
        (
        	elem_det_id,
            elem_det_comp_tipo_id,
            elem_det_importo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select
            detCor.elem_det_id,
            tipo.elem_det_comp_tipo_id,
            compGestPrec.elem_det_importo,
            dataInizioVal,
            loginOperazione,
            tipo.ente_proprietario_id
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_t_bil_elem_det detGestPrec,
             siac_t_bil_elem_det_comp compGestPrec,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id in (periodoId,periodoAnno1Id)
         and   detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=detCor.periodo_id
         and   compGestPrec.elem_det_id=detGestPrec.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compGestPrec.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det_comp compCor
         where compCor.elem_det_id=detCor.elem_det_id
         and   compCor.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   compCor.data_cancellazione is null
         and   compCor.validita_fine is null
         )
	     and   detGestPrec.data_cancellazione is null
    	 and   detGestPrec.validita_fine is null
	     and   compGestPrec.data_cancellazione is null
    	 and   compGestPrec.validita_fine is null
	     and   tipo.data_cancellazione is null;

         strMessaggio:='Aggiornamento componenti importi capitoli di gestione provvisoria esistenti da gestione equivalenti anno precedente annoBilancio+2='
           ||(annoBilancio+2)::varchar
           ||'. Inserimento componenti non esistenti in anno corrente.';
        insert into siac_t_bil_elem_det_comp
        (
        	elem_det_id,
            elem_det_comp_tipo_id,
            elem_det_importo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select
            detCor.elem_det_id,
            tipo.elem_det_comp_tipo_id,
            0,
            dataInizioVal,
            loginOperazione,
            tipo.ente_proprietario_id
        from fase_bil_t_gest_apertura_provv fase,
             siac_t_bil_elem_det detCor,
             siac_t_bil_elem_det detGestPrec,
             siac_t_bil_elem_det_comp compGestPrec,
             siac_d_bil_elem_det_comp_tipo tipo
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and   fase.elem_id is not null       -- esistente in gestione eq prec
         and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
         and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   detCor.elem_id=fase.elem_prov_id   -- cap corr
         and   detCor.periodo_id=periodoAnno2Id
         and   detGestPrec.elem_id=fase.elem_id
         and   detGestPrec.elem_det_tipo_id=detCor.elem_det_tipo_id
         and   detGestPrec.periodo_id=periodoId
         and   compGestPrec.elem_det_id=detGestPrec.elem_det_id
         and   tipo.elem_det_comp_tipo_id=compGestPrec.elem_det_comp_tipo_id
         and   not exists
         (
         select 1
         from siac_t_bil_elem_det_comp compCor
         where compCor.elem_det_id=detCor.elem_det_id
         and   compCor.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
         and   compCor.data_cancellazione is null
         and   compCor.validita_fine is null
         )
	     and   detGestPrec.data_cancellazione is null
    	 and   detGestPrec.validita_fine is null
	     and   compGestPrec.data_cancellazione is null
    	 and   compGestPrec.validita_fine is null
	     and   tipo.data_cancellazione is null;


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
     -- SIAC-7495 Sofia 14.09.2020 - fine


	end if;

    if elemGestEq=true then

        strMessaggio:='Verifica esistenza elementi di bilancio provvisorio equivalenti non presenti in gestione anno precedente.';

    	select  1 into gestEqEsisteNoGest
        from fase_bil_t_gest_apertura_provv fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is null
        and   fase.elem_prov_id is not null
        and   fase.elem_prov_new_id is null
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        limit 1;
--raise notice 'gestEqEsisteNoGest=%', gestEqEsisteNoGest;

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

		if gestEqEsisteNoGest is not null then
         -- sostituire insert e successiva update con
         -- backup di importi precedenti per capitoli gestione corrente che non esistono in gestione eq prec
         strMessaggio:='Inserimento backup importi per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
         insert into bck_fase_bil_t_gest_apertura_provv_bil_elem_det
         (elem_bck_id,elem_bck_det_id,elem_bck_det_importo,elem_bck_det_flag,elem_bck_det_tipo_id,elem_bck_periodo_id,
          elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
          elem_bck_validita_inizio,elem_bck_validita_fine,
		  fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
         (select  det.elem_id, det.elem_det_id, det.elem_det_importo, det.elem_det_flag, det.elem_det_tipo_id, det.periodo_id,
          	      det.data_creazione, det.data_modifica, det.login_operazione, det.validita_inizio,det.validita_fine,
                  fase.fase_bil_elab_id, loginoperazione, now(),enteProprietarioId
          from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is null          -- non esiste in gestione precedente
          and   fase.elem_prov_id is not null -- esiste in gestione corrente
          and   fase.elem_prov_new_id is null -- non nuovo
          and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
          and   det.data_cancellazione is null
          and   det.validita_fine is null);

          -- inserire controllo inserimento backup
		  codResult:=null;
          strMessaggio:=strMessaggio||' Verifica inserimento.';
          select 1 into codResult
          from  fase_bil_t_gest_apertura_provv fase
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   not exists ( select 1 from bck_fase_bil_t_gest_apertura_provv_bil_elem_det bck
		 					 where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=fase.elem_prov_id
					         and   bck.data_cancellazione is null
					         and   bck.validita_fine is null )
          limit 1;
          if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;


         -- update di importi a zero
   	     /*strMessaggio:='Inserimento importi a zero per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
  	     insert into siac_t_bil_elem_det
	     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
    	  validita_inizio, ente_proprietario_id, login_operazione)
	     (select fase.elem_prov_id, 0,
   		         det.elem_det_tipo_id,
	             det.periodo_id,
    	         dataInizioVal,det.ente_proprietario_id,loginOperazione
	      from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_id is null
          and   fase.elem_prov_id is not null
          and   fase.elem_prov_new_id is null
    	  and   det.elem_id=fase.elem_prov_id
	      and   det.data_cancellazione is null
    	  and   det.validita_fine is null
	     ); vedi update sotto */

        strMessaggio:='Aggiornamento importi a zero per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
        from fase_bil_t_gest_apertura_provv fase
    	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.elem_id is null           -- non esiste in gestione eq prec
        and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
        and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
    	and   detCor.elem_id=fase.elem_prov_id -- gestione corrente
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;

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

	    /* strMessaggio:='Cancellazione logica importi capitoli di gestione provvisoria esistenti senza gestione equivalente anno precedente.';

    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
    	 from fase_bil_t_gest_apertura_provv fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
         and    fase.elem_id is null
         and    fase.elem_prov_id is not null
         and    fase.elem_prov_new_id is null
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
         and    det.elem_id=fase.elem_prov_id
         and    det.data_cancellazione is null
         and    dataElaborazione>det.validita_inizio -- date_trunc('DAY',det.validita_inizio) -- solo > per escludere quelli appena inseriti
         and    det.validita_fine is null;

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
         --- controllo inserimento importi prec
         codResult:=null;
	     strMessaggio:='Inserimento importi a zero per capitoli di previsione esistenti senza gestione equivalente anno precedente.Verifica inserimento.';


    	 select  1  into codResult
	     from siac_t_bil_elem_det det , fase_bil_t_gest_apertura_provv fase
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
         and    fase.elem_id is null
         and    fase.elem_prov_id is not null
         and    fase.elem_prov_new_id is null
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
    	 and   det.elem_id=fase.elem_prov_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
         limit 1;

	     if codResult is null then
    		raise exception ' Non effettuato.';
	     end if;

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
         end if;*/


         -- SIAC-7495 Sofia 14.09.2020 - inizio
	     if bilElemGestTipo=CAP_UG_ST then
           strMessaggio:='Inserimento backup componenti importi per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
           insert into bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp
           (elem_bck_det_comp_id,
		    elem_bck_det_id,
		    elem_bck_det_comp_tipo_id,
		    elem_bck_det_importo,
            elem_bck_data_creazione,elem_bck_data_modifica,elem_bck_login_operazione,
            elem_bck_validita_inizio,elem_bck_validita_fine,
            fase_bil_elab_id, login_operazione, validita_inizio, ente_proprietario_id)
           (select  comp.elem_det_comp_id,
           		    comp.elem_det_id,
                    comp.elem_det_comp_tipo_id,
                    comp.elem_det_importo,
                    comp.data_creazione, comp.data_modifica, comp.login_operazione, comp.validita_inizio,comp.validita_fine,
                    fase.fase_bil_elab_id, loginoperazione, clock_timestamp(),enteProprietarioId
            from fase_bil_t_gest_apertura_provv fase, siac_t_bil_elem_det det,
                 siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
            where fase.ente_proprietario_id=enteProprietarioId
            and   fase.bil_id=bilancioId
            and   fase.fase_bil_elab_id=faseBilElabId
            and   fase.data_cancellazione is null
            and   fase.validita_fine is null
            and   fase.elem_id is null          -- non esiste in gestione precedente
            and   fase.elem_prov_id is not null -- esiste in gestione corrente
            and   fase.elem_prov_new_id is null -- non nuovo
            and   det.elem_id=fase.elem_prov_id -- bck del dato in gestione corrente
            and   comp.elem_det_id=det.elem_det_id
--            and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   comp.data_cancellazione is null
            and   comp.validita_fine is null);
          --  and   tipo.data_cancellazione is null);

          -- inserire controllo inserimento backup
		  codResult:=null;
          strMessaggio:=strMessaggio||' Verifica inserimento.';
          select 1 into codResult
          from  fase_bil_t_gest_apertura_provv fase,siac_t_bil_elem_det det,
                siac_t_bil_elem_det_comp comp--,siac_d_bil_elem_det_comp_tipo tipo
          where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   fase.elem_id is null      -- esistente in gestione precedente
          and   fase.elem_prov_new_id is null -- non nuovo
	      and   fase.elem_prov_id is not null -- esistente in gestione correge
          and   det.elem_id=fase.elem_prov_id
          and   comp.elem_det_id=det.elem_det_id
          --and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
         -- and   tipo.data_cancellazione is null
          and   not exists ( select 1 from bck_fase_bil_t_gest_ape_provv_bil_elem_det_comp bck
		 					 where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
					         and   bck.data_cancellazione is null
					         and   bck.validita_fine is null )
          limit 1;
          if codResult is not null then raise exception ' Elementi senza backup effettuato.'; end if;


          strMessaggio:='Aggiornamento importi a zero per capitoli di gestione provvisorio esistenti senza gestione equivalente anno precedente.';
		  update siac_t_bil_elem_det_comp compCor
	      set elem_det_importo=0,
            data_modifica=dataInizioVal,
            login_operazione=loginOperazione
    	  from fase_bil_t_gest_apertura_provv fase,siac_t_bil_elem_det detCor--,
--               siac_d_bil_elem_det_comp_tipo tipo
	      where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
          and   fase.elem_id is null           -- non esiste in gestione eq prec
          and   fase.elem_prov_id is not null  -- esistente in gestione eq corr
          and   fase.elem_prov_new_id is null  -- non un nuovo inserimento
          and   fase.data_cancellazione is null
          and   fase.validita_fine is null
          and   detCor.elem_id=fase.elem_prov_id -- gestione corrente
          and   compCor.elem_det_id=detCor.elem_det_id
       --  and   tipo.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
          and   detCor.data_cancellazione is null
          and   detCor.validita_fine is null
          and   compCor.data_cancellazione is null
          and   compCor.validita_fine is null;
--          and   tipo.data_cancellazione is null;

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

       end if;
    end if;


   -- SIAC-7495 Sofia 14.09.2020 - inizio
   if bilElemGestTipo=CAP_UG_ST then
   	strMessaggio:='Aggiornamento importi componenti a zero per capitoli di gestione nuovi : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_gest_apertura_provv fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UG_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
          /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_prov_new_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


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


    strMessaggio:='Aggiornamento importi componenti a zero per capitoli di gestione esistenti : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_gest_apertura_provv fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UG_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
          /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_prov_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


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

   strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_PROV_DA_GEST||' TERMINATA : AGGIORNAMENTO IMPORTI COMPLETATO.'
    where fase_bil_elab_id=faseBilElabId;

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

    messaggioRisultato:=strMessaggioFinale||'OK .';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_fasi_bil_provv_apertura_importi
(
   integer,
   varchar,
   varchar,
   boolean,
   boolean,
   integer,
   integer,
   varchar,
   timestamp, 
   out  integer,
   out  varchar
) owner to siac;

CREATE OR REPLACE FUNCTION fnc_fasi_bil_prev_approva_importi
(
  annobilancio    integer,
  euElemTipo      varchar,
  bilElemPrevTipo varchar,
  bilElemGestTipo varchar,
  elemGestEq      boolean, -- trattamento capitoli di gestione equivalenti esistenti
  importiPrev     boolean, -- impostazione importi di previsione su gestione
  faseBilElabId   integer, -- identificativo elaborazione
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp, -- deve essere passato con now() o clock_timepstamp()
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	APPROVA_PREV_SU_GEST CONSTANT varchar:='APROVA_PREV';

    STI_DET_TIPO     CONSTANT varchar:='STI';
    SRI_DET_TIPO     CONSTANT varchar:='SRI';
    SCI_DET_TIPO     CONSTANT varchar:='SCI';

    STA_DET_TIPO     CONSTANT varchar:='STA';
    STR_DET_TIPO     CONSTANT varchar:='STR';
    SCA_DET_TIPO     CONSTANT varchar:='SCA';

	-- SIAC-7495 Sofia 14.09.2020
    CAP_UP_ST CONSTANT varchar:='CAP-UP';
    CAP_UG_ST CONSTANT varchar:='CAP-UG';

	gestEqEsiste      integer:=null;
    prevEqApprova     integer:=null;
    gestEqEsisteNoPrev  integer:=null;
    codResult         integer:=null;
	dataInizioVal     timestamp:=null;
    bilancioId        integer:=null;

    detTipoStaId     integer:=null;
    detTipoScaId     integer:=null;
    detTipoStrId     integer:=null;

    detTipoStiId     integer:=null;
    detTipoSciId     integer:=null;
    detTipoSriId     integer:=null;

BEGIN

	messaggioRisultato:='';
    codiceRisultato:=0;

   -- dataInizioVal:=date_trunc('DAY', now());
    dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;

	strMessaggioFinale:='Approvazione bilancio di previsione.Aggiornamento importi Gestione '||bilElemGestTipo||' da Previsione '||bilElemPrevTipo||
    					'.Anno bilancio='||annoBilancio::varchar||'.';


    strMessaggio:='Lettura validita'' identificativo elaborazione faseBilElabId='||faseBilElabId||'.';
    codResult:=null;
	select  1 into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.ente_proprietario_id=enteProprietarioId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fase_bil_elab_esito!='IN2';

    if codResult is not null then
    	raise exception ' Identificatvo elab. non valido.';
    end if;


  	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id into strict bilancioId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    order by bil.bil_id limit 1;
    strMessaggio:='Lettura validita'' identificativo tipo importo '||STI_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStiId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

	strMessaggio:='Lettura validita'' identificativo tipo importo '||STA_DET_TIPO||'.';
	select tipo.elem_det_tipo_id into strict detTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSciId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||SCA_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoScaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


    strMessaggio:='Lettura validita'' identificativo tipo importo '||SRI_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoSriId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SRI_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura validita'' identificativo tipo importo '||STR_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStrId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STR_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;


	codResult:=null;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    -- cancellazione logica importi di gestione equivalente esistente
    if elemGestEq=true then
        strMessaggio:='Verifica esistenza elementi di bilancio di gestione equivalenti da aggiornare da previsione.';

    	select distinct 1 into gestEqEsiste
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_prev_id is not null
--        order by fase.fase_bil_prev_str_esiste_id
        limit 1;

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

        if gestEqEsiste is not null then
         -- al posto di update inserire backup

	  /*   strMessaggio:='Cancellazione logica importi capitoli di gestione equivalenti esistenti.';
    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_inizio=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and    fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_prev_id is not null
         and    det.elem_id=fase.elem_gest_id
         and    det.data_cancellazione is null
         and    det.validita_fine is null; */

         strMessaggio:='Inserimento backup importi capitoli di gestione equivalenti esistenti.';
         insert into bck_fase_bil_t_prev_approva_bil_elem_det
         (elem_bck_id,
		  elem_bck_det_id,
		  elem_bck_det_importo,
		  elem_bck_det_flag,
		  elem_bck_det_tipo_id,
		  elem_bck_periodo_id,
		  elem_bck_data_creazione,
		  elem_bck_data_modifica,
		  elem_bck_login_operazione,
	      elem_bck_validita_inizio,
		  elem_bck_validita_fine,
	      fase_bil_elab_id,
		  validita_inizio,
          login_operazione,
          ente_proprietario_id
          )
          (select det.elem_id, det.elem_det_id, det.elem_det_importo,det.elem_det_flag,det.elem_det_tipo_id,
                  det.periodo_id,det.data_creazione,det.data_modifica,det.login_operazione,det.validita_inizio,
                  det.validita_fine, fase.fase_bil_elab_id,now(),loginOperazione,fase.ente_proprietario_id
           from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_prev_id is not null
           and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
          );

          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_prev_id is not null
           and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_det bck
                             where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=det.elem_id
                             and   bck.data_cancellazione is null
                             and   bck.validita_fine is null);
           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

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

		   -- SIAC-7495 Sofia 14.09.2020 - inizio
	       if bilElemPrevTipo=CAP_UP_ST then
           	 strMessaggio:='Inserimento backup componenti importi capitoli di gestione equivalenti esistenti.';
             insert into bck_fase_bil_t_prev_approva_bil_elem_det_comp
             (
              elem_bck_det_comp_id,
 			  elem_bck_det_id,
			  elem_bck_det_comp_tipo_id,
			  elem_bck_det_importo,
              elem_bck_data_creazione,
              elem_bck_data_modifica,
              elem_bck_login_operazione,
              elem_bck_validita_inizio,
              elem_bck_validita_fine,
              fase_bil_elab_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
              )
              (select comp.elem_det_comp_id,
              		  comp.elem_det_id,
              		  comp.elem_det_comp_tipo_id,
                      comp.elem_det_importo,
                      comp.data_creazione,comp.data_modifica,comp.login_operazione,comp.validita_inizio,
                      comp.validita_fine, fase.fase_bil_elab_id,clock_timestamp(),loginOperazione,fase.ente_proprietario_id
               from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det,
		            siac_t_bil_elem_det_comp comp
               where fase.ente_proprietario_id=enteProprietarioId
               and   fase.bil_id=bilancioId
               and   fase.fase_bil_elab_id=faseBilElabId
               and   fase.data_cancellazione is null
               and   fase.validita_fine is null
               and   fase.elem_prev_id is not null
               and   det.elem_id=fase.elem_gest_id
               and   comp.elem_det_id=det.elem_det_id
               and   det.data_cancellazione is null
               and   det.validita_fine is null
               and   comp.data_cancellazione is null
               and   comp.validita_fine is null
               );

              codResult:=null;
              strmessaggio:=strMessaggio||' Verifica inserimento.';
              select 1  into codResult
              from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det,
                   siac_t_bil_elem_det_comp comp
              where fase.ente_proprietario_id=enteProprietarioId
               and   fase.bil_id=bilancioId
               and   fase.fase_bil_elab_id=faseBilElabId
               and   fase.data_cancellazione is null
               and   fase.validita_fine is null
               and   fase.elem_prev_id is not null
               and   det.elem_id=fase.elem_gest_id
               and   comp.elem_det_id=det.elem_det_id
               and   det.data_cancellazione is null
               and   det.validita_fine is null
               and   comp.data_cancellazione is null
               and   comp.validita_fine is null
               and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_det_comp bck
                                 where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                                 and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
                                 and   bck.data_cancellazione is null
                                 and   bck.validita_fine is null);
               if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

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
		  -- SIAC-7495 Sofia 14.09.2020 - inizio
       end if;
    end if;

    strMessaggio:='Verifica esistenza elementi di bilancio di previsione equivalenti da approvare.';

	select distinct 1 into prevEqApprova
    from fase_bil_t_prev_approva_str_elem_gest_nuovo fase
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
--    order by fase.fase_bil_prev_str_nuovo_id
    limit 1;

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

    if prevEqApprova is not null then
     strMessaggio:='Inserimento  importi capitoli di previsione su gestione equivalenti non esistenti.';
     --- inserimento nuovi importi
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_gest_id,
            (case when importiPrev=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_approva_str_elem_gest_nuovo fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id not in (detTipoStiId,detTipoSriId,detTipoSciId) -- escluso iniziali gestiti di seguito
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

     strMessaggio:='Inserimento  importi attuali capitoli di previsione su gestione iniziale  equivalenti non esistenti.';
     insert into siac_t_bil_elem_det
     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
      validita_inizio, ente_proprietario_id, login_operazione)
     (select fase.elem_gest_id,
            (case when importiPrev=true then det.elem_det_importo
    			  else 0 END),
            (case when det.elem_det_tipo_id=detTipoStaId then detTipoStiId
                  when det.elem_det_tipo_id=detTipoScaId then detTipoSciId
                  when det.elem_det_tipo_id=detTipoStrId then detTipoSriId end), -- attuali in iniziali
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
      from fase_bil_t_prev_approva_str_elem_gest_nuovo fase, siac_t_bil_elem_det det
      where fase.ente_proprietario_id=enteProprietarioId
      and   fase.bil_id=bilancioId
      and   fase.fase_bil_elab_id=faseBilElabId
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      and   det.elem_id=fase.elem_id
      and   det.elem_det_tipo_id in (detTipoStaId,detTipoStrId,detTipoScaId) -- attuali
      and   det.data_cancellazione is null
      and   det.validita_fine is null
     );

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

     --- controllo inserimento importi prec
     codResult:=null;
     strMessaggio:='Inserimento  importi capitoli di previsione su gestione equivalenti non esistenti.Verifica inserimento.';
     select 1  into codResult
     from siac_t_bil_elem_det det , fase_bil_t_prev_approva_str_elem_gest_nuovo fase
     where fase.ente_proprietario_id=enteProprietarioId
     and   fase.bil_id=bilancioId
     and   fase.fase_bil_elab_id=faseBilElabId
     and   fase.data_cancellazione is null
     and   fase.validita_fine is null
     and   det.elem_id=fase.elem_gest_id
     and   det.data_cancellazione is null
     and   det.validita_fine is null
--     order by fase.fase_bil_prev_str_nuovo_id
     limit 1;

     if codResult is null then
    	raise exception ' Non effettuato.';
     end if;

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

     -- SIAC-7495 Sofia 15.09.2020 - inizio
	 if bilElemPrevTipo=CAP_UP_ST then

       strMessaggio:='Inserimento  componenti importi attuali capitoli di previsione su gestione  equivalenti non esistenti.';
       insert into siac_t_bil_elem_det_comp
       (elem_det_id,elem_det_comp_tipo_id, elem_det_importo,
        validita_inizio, ente_proprietario_id, login_operazione)
       (select detGest.elem_det_id,
               tipo.elem_det_comp_tipo_id,
               (case when importiPrev=true then compPrev.elem_det_importo
                    else 0 END),
               dataInizioVal,tipo.ente_proprietario_id,loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_nuovo fase,
             siac_t_bil_elem_det detPrev,siac_t_bil_elem_det_comp compPrev,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGest
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   detPrev.elem_id=fase.elem_id
        and   compPrev.elem_det_id=detPrev.elem_det_id
        and   tipo.elem_det_comp_tipo_id=compPrev.elem_det_comp_tipo_id
        and   detGest.elem_id=fase.elem_gest_id
        and   detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
        and   detGest.periodo_id=detPrev.periodo_id
        and   detPrev.data_cancellazione is null
        and   detPrev.validita_fine is null
        and   compPrev.data_cancellazione is null
        and   compPrev.validita_fine is null
        and   detGest.data_cancellazione is null
        and   detGest.validita_fine is null
        and   tipo.data_cancellazione is null
       );

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

       --- controllo inserimento importi prec
       codResult:=null;
       strMessaggio:='Inserimento componenti  importi capitoli di previsione su gestione equivalenti non esistenti.Verifica inserimento.';
       select 1  into codResult
       from siac_t_bil_elem_det det ,
       	    siac_t_bil_elem_det_comp comp,
            siac_d_bil_elem_det_comp_tipo tipo,
            fase_bil_t_prev_approva_str_elem_gest_nuovo fase
       where fase.ente_proprietario_id=enteProprietarioId
       and   fase.bil_id=bilancioId
       and   fase.fase_bil_elab_id=faseBilElabId
       and   fase.data_cancellazione is null
       and   fase.validita_fine is null
       and   det.elem_id=fase.elem_gest_id
       and   comp.elem_det_id=det.elem_det_id
       and   tipo.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
       and   det.data_cancellazione is null
       and   det.validita_fine is null
       and   comp.data_cancellazione is null
       and   comp.validita_fine is null
       and   tipo.data_cancellazione is null
  --     order by fase.fase_bil_prev_str_nuovo_id
       limit 1;

       if codResult is null then
          raise exception ' Non effettuato.';
       end if;

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
     -- SIAC-7495 Sofia 15.09.2020 - fine
    end if;

--	raise notice 'elemGestEq=% gestEqEsiste=%', elemGestEq,gestEqEsiste;
	if elemGestEq=true and gestEqEsiste is not null then
        -- sostituire insert con update
/*	    strMessaggio:='Inserimento importi capitoli di previsione su gestione equivalenti esistenti.';
    	--- inserimento nuovi importi
	    insert into siac_t_bil_elem_det
    	(elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
	     validita_inizio, ente_proprietario_id, login_operazione)
    	(select fase.elem_gest_id,
            (case when importiPrev=true then det.elem_det_importo
    			  else 0 END),
            det.elem_det_tipo_id,
            det.periodo_id,
            dataInizioVal,det.ente_proprietario_id,loginOperazione
	     from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_prev_id is not null
    	 and   det.elem_id=fase.elem_prev_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
	    ); */

        strMessaggio:='Aggiornamento importi capitoli di previsione su gestione equivalenti esistenti.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id not in (detTipoStiId,detTipoSriId,detTipoSciId) -- escluso iniziali gestiti di seguito
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=det.elem_det_tipo_id
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi competenza attuale capitoli di previsione  su gestione equivalenti esistenti competenza iniziale.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id=detTipoStaId -- attuale
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=detTipoStiId -- iniziale
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi cassa attuale capitoli di previsione  su gestione equivalenti esistenti cassa iniziale.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id=detTipoScaId -- attuale
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=detTipoSciId -- iniziale
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;

		strMessaggio:='Aggiornamento importi residui attuale capitoli di previsione  su gestione equivalenti esistenti residui iniziale.';
		update siac_t_bil_elem_det detCor
        set elem_det_importo=det.elem_det_importo,
            elem_det_flag=det.elem_det_flag,
            data_modifica=now(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   det.elem_id=fase.elem_prev_id
        and   det.elem_det_tipo_id=detTipoStrId -- attuale
        and   detCor.elem_id=fase.elem_gest_id
        and   detCor.elem_det_tipo_id=detTipoSriId -- iniziale
        and   detCor.periodo_id=det.periodo_id
	    and   det.data_cancellazione is null
    	and   det.validita_fine is null
	    and   detCor.data_cancellazione is null
    	and   detCor.validita_fine is null;


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

    	--- controllo inserimento importi prec
/*	    commentato perche si fa update e non insert
        codResult:=null;
    	strMessaggio:='Inserimento importi capitoli di previsione su gestione equivalenti esistenti.Verifica inserimento.';
	    select 1  into codResult
    	from siac_t_bil_elem_det det , fase_bil_t_prev_approva_str_elem_gest_esiste fase
	    where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
    	and   fase.elem_prev_id is not null
	    and   det.elem_id=fase.elem_gest_id
    	and   det.data_cancellazione is null
	    and   det.validita_fine is null
--        order by fase.fase_bil_prev_str_esiste_id
        limit 1;

    	if codResult is null then
    		raise exception ' Non effettuato.';
	    end if;

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
        end if; */

     -- SIAC-7495 Sofia 15.09.2020 - inizio
	 if bilElemPrevTipo=CAP_UP_ST then
	    strMessaggio:='Aggiornamento componenti importi capitoli di previsione  su gestione equivalenti esistenti.'
        			 ||' Aggiornamento componenti esistenti.';
		update siac_t_bil_elem_det_comp compGest
        set elem_det_importo=compPrev.elem_det_importo,
            data_modifica=clock_timestamp(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
             siac_t_bil_elem_det detPrev,siac_t_bil_elem_det_comp compPrev,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGest
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   detPrev.elem_id=fase.elem_prev_id
        and   compPrev.elem_det_id=detPrev.elem_det_id
        and   tipo.elem_det_comp_tipo_id=compPrev.elem_det_comp_tipo_id
        and   detGest.elem_id=fase.elem_gest_id
        and   detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
        and   detGest.periodo_id=detPrev.periodo_id
        and   compGest.elem_det_id=detGest.elem_det_id
        and   compGest.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
	    and   detGest.data_cancellazione is null
    	and   detGest.validita_fine is null
        and   compGest.data_cancellazione is null
    	and   compGest.validita_fine is null
	    and   detPrev.data_cancellazione is null
    	and   detPrev.validita_fine is null
        and   compPrev.data_cancellazione is null
    	and   compPrev.validita_fine is null
        and   tipo.data_cancellazione is null;


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

		strMessaggio:='Aggiornamento componenti importi capitoli di previsione  su gestione equivalenti esistenti.'
        			 ||' Azzeramento componenti non esistenti in previsione utilizzate in gestione.';
        update siac_t_bil_elem_det_comp compGest
        set elem_det_importo=0,
            data_modifica=clock_timestamp(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
             siac_t_bil_elem_det detPrev,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGest
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   detPrev.elem_id=fase.elem_prev_id
        and   detGest.elem_id=fase.elem_gest_id
        and   detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
        and   detGest.periodo_id=detPrev.periodo_id
        and   compGest.elem_det_id=detGest.elem_det_id
        and   tipo.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
        and   not exists
        (
        select 1
        from siac_t_bil_elem_det_comp compPrev
        where compPrev.elem_det_id=detPrev.elem_det_id
        and   compPrev.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
        and   compPrev.data_cancellazione is null
    	and   compPrev.validita_fine is null
        )
        and
        (
          exists
          (
          select 1
          from siac_t_bil_elem_det_var_comp var
          where var.elem_det_comp_id=compGest.elem_det_comp_id
          and   var.data_cancellazione is null
          )
        or
          exists
          (
          select 1
          from siac_r_movgest_bil_elem r
          where r.elem_id=fase.elem_gest_id
          and   r.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
          and   r.data_cancellazione is null
          )
        )
	    and   detGest.data_cancellazione is null
    	and   detGest.validita_fine is null
        and   compGest.data_cancellazione is null
    	and   compGest.validita_fine is null
	    and   detPrev.data_cancellazione is null
    	and   detPrev.validita_fine is null
        and   tipo.data_cancellazione is null;


		strMessaggio:='Aggiornamento componenti importi capitoli di previsione  su gestione equivalenti esistenti.'
        			 ||' Azzeramento e invalidamento componenti non esistenti in previsione non utilizzate in gestione.';
        update siac_t_bil_elem_det_comp compGest
        set elem_det_importo=0,
            data_cancellazione=clock_timestamp(),
            login_operazione=loginOperazione
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
             siac_t_bil_elem_det detPrev,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGest
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   detPrev.elem_id=fase.elem_prev_id
        and   detGest.elem_id=fase.elem_gest_id
        and   detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
        and   detGest.periodo_id=detPrev.periodo_id
        and   compGest.elem_det_id=detGest.elem_det_id
        and   tipo.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
        and   not exists
        (
        select 1
        from siac_t_bil_elem_det_comp compPrev
        where compPrev.elem_det_id=detPrev.elem_det_id
        and   compPrev.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
        and   compPrev.data_cancellazione is null
    	and   compPrev.validita_fine is null
        )
        and not exists
        (
          select 1
          from siac_t_bil_elem_det_var_comp var
          where var.elem_det_comp_id=compGest.elem_det_comp_id
          and   var.data_cancellazione is null
        )
        and not exists
        (
          select 1
          from siac_r_movgest_bil_elem r
          where r.elem_id=fase.elem_gest_id
          and   r.elem_det_comp_tipo_id=compGest.elem_det_comp_tipo_id
          and   r.data_cancellazione is null
        )
	    and   detGest.data_cancellazione is null
    	and   detGest.validita_fine is null
        and   compGest.data_cancellazione is null
    	and   compGest.validita_fine is null
	    and   detPrev.data_cancellazione is null
    	and   detPrev.validita_fine is null
        and   tipo.data_cancellazione is null;


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


        strMessaggio:='Aggiornamento componenti importi capitoli di previsione  su gestione equivalenti esistenti.'
        			 ||' Inserimento componenti non esistenti in gestione.';
        insert into siac_t_bil_elem_det_comp
        (
        	elem_det_id,
            elem_det_comp_tipo_id,
            elem_det_importo,
            validita_inizio,
            login_operazione,
            ente_proprietario_id
        )
        select
        	 detGest.elem_det_id,
             tipo.elem_det_comp_tipo_id,
             compPrev.elem_det_importo,
             dataInizioVal,
             loginOperazione,
             tipo.ente_proprietario_id
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
             siac_t_bil_elem_det detPrev,
             siac_t_bil_elem_det_comp compPrev,
             siac_d_bil_elem_det_comp_tipo tipo,
             siac_t_bil_elem_det detGest
     	where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
	    and   fase.data_cancellazione is null
    	and   fase.validita_fine is null
	    and   fase.elem_prev_id is not null
    	and   detPrev.elem_id=fase.elem_prev_id
        and   compPrev.elem_det_id=detPrev.elem_det_id
        and   tipo.elem_det_comp_tipo_id=compPrev.elem_det_comp_tipo_id
        and   detGest.elem_id=fase.elem_gest_id
        and   detGest.elem_det_tipo_id=detPrev.elem_det_tipo_id
        and   detGest.periodo_id=detPrev.periodo_id
        and   not exists
        (
        select 1
        from siac_t_bil_elem_det_comp compGest
        where compGest.elem_det_id=detGest.elem_det_id
        and   compGest.elem_det_comp_tipo_id=tipo.elem_det_comp_tipo_id
        and   compGest.data_cancellazione is null
    	and   compGest.validita_fine is null
        )
	    and   detGest.data_cancellazione is null
    	and   detGest.validita_fine is null
        and   compPrev.data_cancellazione is null
    	and   compPrev.validita_fine is null
	    and   detPrev.data_cancellazione is null
    	and   detPrev.validita_fine is null
        and   tipo.data_cancellazione is null;


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
     -- SIAC-7495 Sofia 15.09.2020 - fine


	end if;

    if elemGestEq=true then

        strMessaggio:='Verifica esistenza elementi di bilancio di gestione equivalenti non presenti in previsione da aggiornare.';

    	select  1 into gestEqEsisteNoPrev
        from fase_bil_t_prev_approva_str_elem_gest_esiste fase
        where fase.ente_proprietario_id=enteProprietarioId
        and   fase.bil_id=bilancioId
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null
        and   fase.elem_prev_id is null
--        order by fase.fase_bil_prev_str_esiste_id
        limit 1;
--raise notice 'gestEqEsisteNoPrev=%', gestEqEsisteNoPrev;

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

		if gestEqEsisteNoPrev is not null then
         --sostituire insert con backup e update
/*   	     strMessaggio:='Inserimento importi a zero per capitoli di gestione esistenti senza previsione equivalente.';
  	     insert into siac_t_bil_elem_det
	     (elem_id, elem_det_importo, elem_det_tipo_id,periodo_id,
    	  validita_inizio, ente_proprietario_id, login_operazione)
	     (select fase.elem_gest_id, 0,
   		        det.elem_det_tipo_id,
	            det.periodo_id,
    	        dataInizioVal,det.ente_proprietario_id,loginOperazione
	      from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_prev_id is null
    	  and   det.elem_id=fase.elem_gest_id
	      and   det.data_cancellazione is null
    	  and   det.validita_fine is null
	     );*/

         strMessaggio:='Inserimento backup importi per capitoli di gestione esistenti senza previsione equivalente.';
		 insert into bck_fase_bil_t_prev_approva_bil_elem_det
         (elem_bck_id,
		  elem_bck_det_id,
		  elem_bck_det_importo,
		  elem_bck_det_flag,
		  elem_bck_det_tipo_id,
		  elem_bck_periodo_id,
		  elem_bck_data_creazione,
		  elem_bck_data_modifica,
		  elem_bck_login_operazione,
	      elem_bck_validita_inizio,
		  elem_bck_validita_fine,
	      fase_bil_elab_id,
		  validita_inizio,
          login_operazione,
          ente_proprietario_id
          )
          (select det.elem_id, det.elem_det_id, det.elem_det_importo,det.elem_det_flag,det.elem_det_tipo_id,
                  det.periodo_id,det.data_creazione,det.data_modifica,det.login_operazione,det.validita_inizio,
                  det.validita_fine, fase.fase_bil_elab_id,now(),loginOperazione,fase.ente_proprietario_id
           from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
           where fase.ente_proprietario_id=enteProprietarioId
           and   fase.bil_id=bilancioId
           and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
           and   fase.validita_fine is null
	       and   fase.elem_prev_id is null
    	   and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
    	   and   det.validita_fine is null
          );

          strMessaggio:='Aggiornamento importi a zero per capitoli di gestione esistenti senza previsione equivalente.';
          update siac_t_bil_elem_det detCor
          set   elem_det_importo=0,
                data_modifica=now(),
                login_operazione=loginOperazione
          from fase_bil_t_prev_approva_str_elem_gest_esiste fase
    	  where fase.ente_proprietario_id=enteProprietarioId
          and   fase.bil_id=bilancioId
          and   fase.fase_bil_elab_id=faseBilElabId
    	  and   fase.data_cancellazione is null
          and   fase.validita_fine is null
	      and   fase.elem_prev_id is null
    	  and   detCor.elem_id=fase.elem_gest_id
	      and   detCor.data_cancellazione is null
    	  and   detCor.validita_fine is null;


          codResult:=null;
          strmessaggio:=strMessaggio||' Verifica inserimento.';
          select 1  into codResult
          from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det
          where fase.ente_proprietario_id=enteProprietarioId
	       and   fase.bil_id=bilancioId
    	   and   fase.fase_bil_elab_id=faseBilElabId
    	   and   fase.data_cancellazione is null
	       and   fase.validita_fine is null
		   and   fase.elem_prev_id is null
           and   det.elem_id=fase.elem_gest_id
	       and   det.data_cancellazione is null
     	   and   det.validita_fine is null
           and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_det bck
                             where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                             and   bck.elem_bck_id=det.elem_id
                             and   bck.data_cancellazione is null
                             and   bck.validita_fine is null);
           if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

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

         -- commentare update --
	     /*strMessaggio:='Cancellazione logica importi capitoli di gestione esistenti senza previsione equivalente.';

    	 update siac_t_bil_elem_det det
	      set data_cancellazione=now(), validita_fine=now(), login_operazione=loginOperazione
    	 from fase_bil_t_prev_approva_str_elem_gest_esiste fase
	     where  fase.ente_proprietario_id=enteProprietarioId
         and    fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
    	 and    fase.data_cancellazione is null
         and    fase.validita_fine is null
	     and    fase.elem_prev_id is null
         and    det.elem_id=fase.elem_gest_id
         and    det.data_cancellazione is null
         and    dataElaborazione>det.validita_inizio -- date_trunc('DAY',det.validita_inizio) -- solo > per escludere quelli appena inseriti
         and    det.validita_fine is null;

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
         --- controllo inserimento importi prec
         codResult:=null;
	     strMessaggio:='Inserimento importi a zero per capitoli di gestione esistenti senza previsione equivalente.Verifica inserimento.';


    	 select  1  into codResult
	     from siac_t_bil_elem_det det , fase_bil_t_prev_approva_str_elem_gest_esiste fase
    	 where fase.ente_proprietario_id=enteProprietarioId
         and   fase.bil_id=bilancioId
         and   fase.fase_bil_elab_id=faseBilElabId
	     and   fase.data_cancellazione is null
    	 and   fase.validita_fine is null
	     and   fase.elem_prev_id is null
    	 and   det.elem_id=fase.elem_gest_id
	     and   det.data_cancellazione is null
    	 and   det.validita_fine is null
--         order by fase.fase_bil_prev_str_esiste_id
         limit 1;

	     if codResult is null then
    		raise exception ' Non effettuato.';
	     end if;

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
         end if; */

         -- SIAC-7495 Sofia 15.09.2020 - inizio
	 	 if bilElemPrevTipo=CAP_UP_ST then
         	 strMessaggio:='Inserimento backup componenti importi per capitoli di gestione esistenti senza previsione equivalente.';
             insert into bck_fase_bil_t_prev_approva_bil_elem_det_comp
             (
              elem_bck_det_comp_id,
 			  elem_bck_det_id,
			  elem_bck_det_comp_tipo_id,
			  elem_bck_det_importo,
              elem_bck_data_creazione,
              elem_bck_data_modifica,
              elem_bck_login_operazione,
              elem_bck_validita_inizio,
              elem_bck_validita_fine,
              fase_bil_elab_id,
              validita_inizio,
              login_operazione,
              ente_proprietario_id
              )
              (select comp.elem_det_comp_id,comp.elem_det_id,comp.elem_det_comp_tipo_id, comp.elem_det_importo,
                      comp.data_creazione,comp.data_modifica,comp.login_operazione,comp.validita_inizio,
                      comp.validita_fine, fase.fase_bil_elab_id,clock_timestamp(),loginOperazione,fase.ente_proprietario_id
               from fase_bil_t_prev_approva_str_elem_gest_esiste fase, siac_t_bil_elem_det det,
               	    siac_t_bil_elem_det_comp comp
               where fase.ente_proprietario_id=enteProprietarioId
               and   fase.bil_id=bilancioId
               and   fase.fase_bil_elab_id=faseBilElabId
               and   fase.data_cancellazione is null
               and   fase.validita_fine is null
               and   fase.elem_prev_id is null
               and   det.elem_id=fase.elem_gest_id
               and   comp.elem_det_id=det.elem_det_id
               and   det.data_cancellazione is null
               and   det.validita_fine is null
               and   comp.data_cancellazione is null
               and   comp.validita_fine is null
              );

              codResult:=null;
              strmessaggio:=strMessaggio||' Verifica inserimento.';
              select 1  into codResult
              from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
                   siac_t_bil_elem_det det,siac_t_bil_elem_det_comp comp
              where fase.ente_proprietario_id=enteProprietarioId
               and   fase.bil_id=bilancioId
               and   fase.fase_bil_elab_id=faseBilElabId
               and   fase.data_cancellazione is null
               and   fase.validita_fine is null
               and   fase.elem_prev_id is null
               and   det.elem_id=fase.elem_gest_id
               and   comp.elem_det_id=det.elem_det_id
               and   det.data_cancellazione is null
               and   det.validita_fine is null
               and   comp.data_cancellazione is null
               and   comp.validita_fine is null
               and   not exists (select 1 from bck_fase_bil_t_prev_approva_bil_elem_det_comp bck
                                 where bck.fase_bil_elab_id=fase.fase_bil_elab_id
                                 and   bck.elem_bck_det_comp_id=comp.elem_det_comp_id
                                 and   bck.data_cancellazione is null
                                 and   bck.validita_fine is null);
              if codResult is not null then raise exception ' Elementi senza backup importi.'; end if;

              strMessaggio:='Aggiornamento componenti importi a zero per capitoli di gestione esistenti senza previsione equivalente.'
                            ||' Azzeramento importi per componenti utilizzati in gestione.';
              update siac_t_bil_elem_det_comp compCor
              set   elem_det_importo=0,
                    data_modifica=now(),
                    login_operazione=loginOperazione
              from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
                   siac_t_bil_elem_det det
              where fase.ente_proprietario_id=enteProprietarioId
              and   fase.bil_id=bilancioId
              and   fase.fase_bil_elab_id=faseBilElabId
              and   fase.data_cancellazione is null
              and   fase.validita_fine is null
              and   fase.elem_prev_id is null
              and   det.elem_id=fase.elem_gest_id
              and   compCor.elem_det_id=det.elem_det_id
              and
              (
                exists
                (
                select 1
                from siac_t_bil_elem_det_var_comp var
                where var.elem_det_comp_id=compCor.elem_det_comp_id
                and   var.data_cancellazione is null
                )
                /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
				or
                exists
                (
                select 1
                from siac_r_movgest_bil_elem re
                where re.elem_id=fase.elem_gest_id
                and   re.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
                and   re.data_cancellazione is null
                )*/
              )
              and   compCor.data_cancellazione is null
              and   compCor.validita_fine is null
              and   det.data_cancellazione is null
              and   det.validita_fine is null;


              strMessaggio:='Aggiornamento componenti importi a zero per capitoli di gestione esistenti senza previsione equivalente.'
                            ||' Azzeramento importi per componenti non utilizzati in gestione.';
              update siac_t_bil_elem_det_comp compCor
              set   elem_det_importo=0,
                    data_cancellazione=now(),
                    login_operazione=loginOperazione
              from fase_bil_t_prev_approva_str_elem_gest_esiste fase,
                   siac_t_bil_elem_det det
              where fase.ente_proprietario_id=enteProprietarioId
              and   fase.bil_id=bilancioId
              and   fase.fase_bil_elab_id=faseBilElabId
              and   fase.data_cancellazione is null
              and   fase.validita_fine is null
              and   fase.elem_prev_id is null
              and   det.elem_id=fase.elem_gest_id
              and   compCor.elem_det_id=det.elem_det_id
              and   not exists
              (
                select 1
                from siac_t_bil_elem_det_var_comp var
                where var.elem_det_comp_id=compCor.elem_det_comp_id
                and   var.data_cancellazione is null
              )
              /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
			  and not exists
              (
                select 1
                from siac_r_movgest_bil_elem re
                where re.elem_id=fase.elem_gest_id
                and   re.elem_det_comp_tipo_id=compCor.elem_det_comp_tipo_id
                and   re.data_cancellazione is null
              )*/
              and   compCor.data_cancellazione is null
              and   compCor.validita_fine is null
              and   det.data_cancellazione is null
              and   det.validita_fine is null;

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
         -- SIAC-7495 Sofia 15.09.2020 - fine
       end if;

    end if;

   -- SIAC-7495 Sofia 05.10.2020 - inizio
   if bilElemPrevTipo=CAP_UP_ST then

    strMessaggio:='Aggiornamento importi componenti a zero per capitoli di gestione nuovi : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_prev_approva_str_elem_gest_nuovo fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UG_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
         /*  09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_gest_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


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


    strMessaggio:='Aggiornamento importi componenti a zero per capitoli di gestione esistenti : '
                  ||' cancellazione logica componenti a zero non utilizzate.';
    update siac_t_bil_elem_det_comp detCompCor
    set --elem_det_importo=0,
        data_cancellazione=clock_timestamp(),
        login_operazione=loginOperazione||'-CANC-COMP-ZERO'
    from  fase_bil_t_prev_approva_str_elem_gest_esiste fase,
          siac_t_bil_elem_det det ,siac_t_periodo per,
          siac_d_bil_elem_det_comp_tipo tipo,
          (
          select tipo.elem_tipo_code,e.elem_code::integer,
                 e.elem_id,
                 tipo_comp.elem_det_comp_tipo_id,
                 tipo_comp.elem_det_comp_tipo_desc,
                 sum(comp.elem_det_importo)
          from siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
               siac_t_bil_elem_Det det,siac_t_bil_elem_Det_comp comp,
               siac_d_bil_elem_det_comp_tipo tipo_comp,siac_t_periodo per
          where tipo.ente_proprietario_id=enteProprietarioId
          and   tipo.elem_tipo_code=CAP_UG_ST
          and   e.elem_tipo_id=tipo.elem_tipo_id
          and   e.bil_id=bilancioId
          and   det.elem_id=e.elem_id
          and   comp.elem_det_id=det.elem_det_id
          and   tipo_comp.elem_det_comp_tipo_id=comp.elem_det_comp_tipo_id
          and   per.periodo_id=det.periodo_id
          and not exists
          (
          select 1
          from siac_t_bil_elem_det_comp comp_comp,
               siac_t_bil_elem_det_var_comp dvar_comp,siac_t_bil_elem_det_var dvar
          where comp_comp.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and   dvar_comp.elem_det_comp_id=comp_comp.elem_det_comp_id
          and   dvar.elem_det_var_id=dvar_comp.elem_det_var_id
          and   dvar.elem_id=e.elem_id
          and   comp_comp.data_cancellazione is null
          and   dvar_comp.data_cancellazione is null
          and   dvar.data_cancellazione is null
          )
          /* 09.10.2020 Sofia da scommentare con rilascio della SIAC-7349
		  and not exists
          (
          select 1
          from siac_r_movgest_bil_elem re
          where  re.elem_id=e.elem_id
          and    re.elem_det_comp_tipo_id=tipo_comp.elem_det_comp_tipo_id
          and    re.data_cancellazione is null
          )*/
          and   e.data_cancellazione is null
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   comp.data_cancellazione is null
          and   comp.validita_fine is null
          and   tipo_comp.data_cancellazione is null
          group by tipo.elem_tipo_code,e.elem_code::integer,
                   e.elem_id,
                   tipo_comp.elem_det_comp_tipo_id,
                   tipo_comp.elem_det_comp_tipo_desc
          having sum(comp.elem_det_importo)=0
          order by 1,2,3
          ) query
    where fase.ente_proprietario_id=enteProprietarioId
    and   fase.bil_id=bilancioId
    and   fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   det.elem_id=fase.elem_gest_id
    and   detCompCor.elem_Det_id=det.elem_det_id
    and   tipo.elem_Det_comp_tipo_id=detCompCor.elem_det_comp_tipo_id
    and   per.periodo_id=det.periodo_id
    and   query.elem_id=det.elem_id
    and   query.elem_det_comp_tipo_id=tipo.elem_Det_comp_tipo_id
    and   det.data_cancellazione is null
    and   detCompCor.data_cancellazione is null;


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

   strMessaggio:='Aggiornamento elaborazione faseBilElabId='||faseBilElabId||' per conclusione OK.';
    update fase_bil_t_elaborazione set
       fase_bil_elab_esito='OK',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APPROVA_PREV_SU_GEST||' TERMINATA : AGGIORNAMENTO IMPORTI COMPLETATO.'
    where fase_bil_elab_id=faseBilElabId;

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

    messaggioRisultato:=strMessaggioFinale||'OK .';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 50);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function siac.fnc_fasi_bil_prev_approva_importi
(
   integer,
   varchar,
   varchar,
   varchar,
   boolean,
   boolean,
   integer,
   integer,
   varchar,
   timestamp, 
   out  integer,
   out  varchar
) owner to siac;

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_gestisci_variazione
(
  enteProprietarioId     integer,
  annoBilancio           integer,
  variazioneNum          integer,
  cambiaStatoVar         boolean,
  statoVar               varchar,
  applicaVar             boolean,
  loginOperazione         varchar,
  dataElaborazione       timestamp
)
RETURNS  TABLE
(
codiceRisultato integer,
messaggioRisultato varchar
)

AS
$body$
DECLARE
	v_messaggiorisultato varchar;

  	v_messaggiorisultato_agg varchar;

    variazioneStatoid INTEGER:=null;
    variazioneStatoNewId integer:=null;
    variazioneStatoCode varchar(1):=null;
    variazioneId      integer:=null;

	-- 20.10.2020 Sofia SIAC-7495
    attoAmmId         integer:=null;
    attAmmVarBilId    integer:=null;

    codResult      integer:=null;
    codResult1      integer:=null;

    VAR_BOZZA_ST constant varchar(1):='B';
    VAR_DEF_ST constant varchar(1):='D';
    VAR_PRE_DEF_ST constant varchar(1):='P';
BEGIN

  codiceRisultato:=null;
  messaggioRisultato:=null;

  v_messaggiorisultato :='Gestione variazione '||variazioneNum::varchar||
                        '/'||annoBilancio::varchar||'.';

  v_messaggiorisultato_agg:=  v_messaggiorisultato;
  raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;

  v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Lettura dati variazione.';
  raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
  -- variazione_stato_id
  select r.variazione_stato_id,stato.variazione_Stato_tipo_code, var.variazione_id,
         r.attoamm_id,r.attoamm_id_varbil
         into variazioneStatoId, variazioneStatoCode,variazioneId,
              attoAmmId,attAmmVarBilId -- 20.10.2020 Sofia SIAC-7495
  from siac_t_variazione var, siac_v_bko_anno_bilancio anno,
   	   siac_r_variazione_stato r, siac_d_variazione_stato stato
  where anno.ente_proprietario_id=enteProprietarioId
  and   anno.anno_bilancio=annoBilancio
  and   var.bil_id=anno.bil_id
  and   var.variazione_num::integer=variazioneNum
  and   r.variazione_id=var.variazione_id
  and   stato.variazione_stato_tipo_id=r.variazione_stato_tipo_id
  and   stato.variazione_stato_tipo_code!='A'
  and   r.data_cancellazione is null
  and   r.validita_fine is null;

  if variazioneStatoId is null or variazioneStatoCode is null or variazioneId is null
  then
  	  v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Dato non reperito.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;

  -- se applico senza cambiamento di stato su stato non definitivo devo bloccare
  if applicaVar=true and  cambiaStatoVar = false and variazioneStatoCode!=VAR_DEF_ST
  then
      v_messaggiorisultato_agg:=  v_messaggiorisultato;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Applicazione non effettuabile senza cambiamento di stato '||
                            ' su stato '||variazioneStatoCode||' .';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;
  -- se applico senza cambiamento di stato, lo stato deve essere definitivo
  -- quindi anche quello che uso per applicare
  if applicaVar=true and  cambiaStatoVar = false and variazioneStatoCode=VAR_DEF_ST  and statoVar!=VAR_DEF_ST
  then
  	statoVar:=VAR_DEF_ST;
  end if;

  -- se applico con cambiamento di stato senza passare a stato definitivo devo bloccare
  if applicaVar=true and  cambiaStatoVar = true and statoVar!=VAR_DEF_ST
  then
      v_messaggiorisultato_agg:=  v_messaggiorisultato;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Applicazione non effettuabile senza cambiamento di stato a '||
                            VAR_DEF_ST||' .';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;

  -- se tento di passare allo stato D senza applicare devo bloccare
  if applicaVar=false and  cambiaStatoVar = true and statoVar=VAR_DEF_ST
  then
  	  v_messaggiorisultato_agg:=  v_messaggiorisultato;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Passaggio allo stato DEFINITIVO non ammesso senza applicazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
  end if;


  -- check cambiamento di stato variazione
  if cambiaStatoVar = false then
       variazioneStatoNewId:=variazioneStatoId;
  else -- inserimento nuovi stati e dettagli
     v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
     v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovo stato variazione  '||
                            statoVar||'.';
     raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

  	insert into siac_r_variazione_stato
    (
    	variazione_id,
        variazione_Stato_tipo_id,
        attoamm_id,  -- 20.10.2020 Sofia SIAC-7495
        attoamm_id_varbil, -- 20.10.2020 Sofia SIAC-7495
        validita_Inizio,
        login_Operazione,
        ente_Proprietario_Id
    )
    select
         variazioneId,
         stato.variazione_Stato_tipo_Id,
         attoAmmId, -- 20.10.2020 Sofia SIAC-7495
         attAmmVarBilId, -- 20.10.2020 Sofia SIAC-7495
         clock_timestamp(),
         loginOperazione,
         stato.ente_proprietario_id
    from siac_d_variazione_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.variazione_stato_tipo_code=statoVar
    returning variazione_stato_id into variazioneStatoNewId;
    if variazioneStatoNewId is null then
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
    end if;

    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovo stato variazione  '||
                               statoVar||'. Chiusura prec. stato.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    codResult:=null;
    update siac_r_variazione_stato rs
    set    data_cancellazione=clock_timestamp(),
           validita_fine=clock_timestamp(),
           login_operazione=rs.login_operazione||'-'||loginOperazione
    where rs.variazione_stato_id=variazioneStatoId
    returning rs.variazione_id into codResult;

    if codResult is null then
       v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
       raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

       codiceRisultato:=-1;
       messaggioRisultato:=v_messaggiorisultato_agg;
  	   return next;
       return;
    end if;
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione riuscita.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    if variazioneStatoCode=VAR_BOZZA_ST and statoVar=VAR_DEF_ST then
        v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
        v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovo stato variazione  '||
                                  statoVar||' e '||VAR_PRE_DEF_ST||'.';
        raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
        codResult:=null;
    	insert into siac_r_variazione_stato
        (
            variazione_id,
            variazione_Stato_tipo_id,
            attoamm_id,  -- 20.10.2020 Sofia SIAC-7495
            attoamm_id_varbil, -- 20.10.2020 Sofia SIAC-7495
            validita_Inizio,
            validita_fine,
            data_cancellazione,
            login_Operazione,
            ente_Proprietario_Id
        )
        select
             variazioneId,
             stato.variazione_Stato_tipo_Id,
             attoAmmId, -- 20.10.2020 Sofia SIAC-7495
             attAmmVarBilId, -- 20.10.2020 Sofia SIAC-7495
             clock_timestamp(),
             clock_timestamp(),
             clock_timestamp(),
             loginOperazione,
             stato.ente_proprietario_id
        from siac_d_variazione_stato stato
        where stato.ente_proprietario_id=enteProprietarioId
        and   stato.variazione_stato_tipo_code=VAR_PRE_DEF_ST
        returning variazione_stato_id into codResult;
        if codResult is null then
            v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
            raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

       		codiceRisultato:=-1;
      		messaggioRisultato:=v_messaggiorisultato_agg;
  	  		return next;
     		return;
        end if;

    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovi dettagli di variazione.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    insert into siac_t_bil_elem_det_var
    (
    	 variazione_stato_id,
 		 elem_id,
 		 elem_det_importo,
 		 elem_det_tipo_id,
		 periodo_id,
         elem_det_flag,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         variazioneStatoNewId,
         dvar.elem_id,
 		 dvar.elem_det_importo,
 		 dvar.elem_det_tipo_id,
		 dvar.periodo_id,
         dvar.elem_det_flag,
         clock_timestamp(),
         loginOperazione||'@'||dvar.elem_Det_Var_id::varchar,
         dvar.ente_proprietario_id
    from siac_t_bil_elem_det_var dvar
    where dvar.variazione_Stato_id=variazioneStatoId
    and   dvar.data_cancellazione is null;

    v_messaggiorisultato_agg:=  v_messaggiorisultato;
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Verifica inserimento nuovi dettagli di variazione.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    -- verifica inserimento
    codResult:=null;
    select 1 into codResult
    from siac_t_bil_elem_det_var dvar
    where dvar.variazione_Stato_id=variazioneStatoNewId
    and   dvar.data_cancellazione is null;
    if codResult is null then
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
      codiceRisultato:=-1;
      messaggioRisultato:=v_messaggiorisultato_agg;
  	  return next;
      return;
    end if;
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione riuscita.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato.';
    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Verifica esistenza dettagli di variazione componenti da inserire.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    -- verifica esistenza var componenti da inserire
    codResult:=null;
    select 1 into codResult
    from siac_t_bil_elem_det_var dvar,siac_t_bil_elem_det_var_comp var_comp,
         siac_t_bil_elem_Det_Var dvar_new
    where dvar.variazione_Stato_id=variazioneStatoId
    and   var_comp.elem_det_var_id=dvar.elem_det_var_id
    and   dvar_new.variazione_stato_id=variazioneStatoNewId
    and   dvar_new.login_operazione like loginOperazione||'@%'
    and   split_part(dvar_new.login_Operazione,'@',2)::integer=dvar.elem_Det_Var_id
    and   dvar.data_cancellazione is null
    and   dvar_new.data_cancellazione is null
    and   var_comp.data_cancellazione is null;

    if codResult is not null then
      codResult:=null;
      v_messaggiorisultato_agg:=  v_messaggiorisultato;
   	  v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Inserimento nuovi dettagli di variazione componenti.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
       -- verifica esistenza var componenti da inserire
      insert into siac_t_bil_elem_det_var_comp
      (
           elem_det_var_id,
           elem_det_comp_id ,
           elem_Det_importo,
           elem_det_flag,
           validita_inizio,
           login_operazione,
           ente_proprietario_id
      )
      select
           dvar_new.elem_det_var_id,
           var_comp.elem_Det_comp_id,
           var_comp.elem_det_importo,
           var_comp.elem_det_flag,
           clock_timestamp(),
           loginOperazione,
           var_comp.ente_proprietario_id
      from siac_t_bil_elem_det_var dvar,siac_t_bil_elem_det_var_comp var_comp,
           siac_t_bil_elem_Det_Var dvar_new
      where dvar.variazione_Stato_id=variazioneStatoId
      and   var_comp.elem_det_var_id=dvar.elem_det_var_id
      and   dvar_new.variazione_stato_id=variazioneStatoNewId
      and   dvar_new.login_operazione like loginOperazione||'@%'
      and   split_part(dvar_new.login_Operazione,'@',2)::integer=dvar.elem_Det_Var_id
      and   dvar.data_cancellazione is null
      and   dvar_new.data_cancellazione is null
      and   var_comp.data_cancellazione is null;
      -- verifica inserimento

      codResult:=null;
      select 1 into codResult
      from siac_t_bil_elem_det_var dvar,siac_t_bil_elem_det_var_comp var_comp
      where dvar.variazione_Stato_id=variazioneStatoNewId
      and   var_comp.elem_det_var_id=dvar.elem_det_var_id
      and   dvar.data_cancellazione is null
      and   var_comp.data_cancellazione is null;
      if codResult is null then
        v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione non riuscita.';
        raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
        codiceRisultato:=-1;
        messaggioRisultato:=v_messaggiorisultato_agg;
  	    return next;
        return;
      end if;

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Operazione riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Passaggio di stato variazione effettuato.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
  end if;


  -- aggiornamento stanziamenti e componenti se statoVar=DEFINITIVO e applicaVar=true
  if statoVar=VAR_DEF_ST and applicaVar=true then

    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';

    v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Verifica esistenza dettagli di variazione per aggiornamento stanziamenti.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    raise notice 'variazioneStatoNewId=%',variazioneStatoNewId;
    -- check se esistono det di stanziamento
    codResult:=null;
    select 1 into codResult
    from   siac_t_bil_elem_det_var dvar,siac_t_bil_elem_Det det
    where  dvar.variazione_stato_id=variazioneStatoNewId
    and    det.elem_id=dvar.elem_id
    and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
    and    det.periodo_id=dvar.periodo_id
    and    dvar.elem_det_importo!=0
    and    dvar.data_cancellazione is null
    and    det.data_cancellazione is null;
    raise notice 'codResult=%',codResult;
    if codResult is not null then
      v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Aggiornamento stanziamenti da dettagli di variazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
      codResult:=null;
      update siac_t_bil_elem_Det det
      set    elem_det_importo=det.elem_det_importo+dvar.elem_det_importo,
             data_modifica=clock_timestamp(),
             login_operazione=det.login_operazione||'-'||loginOperazione
      from   siac_t_bil_elem_det_var dvar
      where  dvar.variazione_stato_id=variazioneStatoNewId
      and    det.elem_id=dvar.elem_id
      and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
      and    det.periodo_id=dvar.periodo_id
      and    dvar.elem_det_importo!=0
      and    dvar.data_cancellazione is null
      and    det.data_cancellazione is null;
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if codResult is null then
          v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Stanziamenti non aggiornati.';
          raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

          codiceRisultato:=-1;
          messaggioRisultato:=v_messaggiorisultato_agg;
          return next;
          return;
      end if;
      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Stanziamenti  aggiornati.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';

    v_messaggiorisultato_agg:=v_messaggiorisultato_agg
                             ||' Verifica esistenza dettagli di variazione per aggiornamento componenti stanziamenti.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    -- check se esistono det di componente di stanziamento
    codResult:=null;
    select 1 into codResult
    from   siac_t_bil_elem_det_var dvar,siac_t_bil_elem_Det det,
           siac_t_bil_elem_Det_var_comp var_comp, siac_t_bil_elem_det_comp comp
    where  dvar.variazione_stato_id=variazioneStatoNewId
    and    det.elem_id=dvar.elem_id
    and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
    and    det.periodo_id=dvar.periodo_id
    and    dvar.elem_det_importo!=0
    and    var_comp.elem_Det_var_id=dvar.elem_det_var_id
    and    comp.elem_det_comp_id=var_comp.elem_det_comp_id
    and    comp.elem_det_id=det.elem_det_id
    and    var_comp.elem_det_importo!=0
    and    dvar.data_cancellazione is null
    and    det.data_cancellazione is null
    and    var_comp.data_cancellazione is null
    and    comp.data_cancellazione is null;
raise notice 'codResult=%',codResult;
    if codResult is not null then
      v_messaggiorisultato_agg:=  v_messaggiorisultato;

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Aggiornamento componenti stanziamenti da dettagli di variazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

      codResult:=null;
      update siac_t_bil_elem_det_comp comp
      set    elem_det_importo=comp.elem_det_importo+var_comp.elem_det_importo,
             data_modifica=clock_timestamp(),
             login_operazione=comp.login_operazione||'-'||loginOperazione
      from   siac_t_bil_elem_det_var dvar,siac_t_bil_elem_Det det,
             siac_t_bil_elem_Det_var_comp var_comp
      where  dvar.variazione_stato_id=variazioneStatoNewId
      and    det.elem_id=dvar.elem_id
      and    det.elem_Det_tipo_id=dvar.elem_det_tipo_id
      and    det.periodo_id=dvar.periodo_id
      and    dvar.elem_det_importo!=0
      and    var_comp.elem_Det_var_id=dvar.elem_det_var_id
      and    comp.elem_det_comp_id=var_comp.elem_det_comp_id
      and    comp.elem_det_id=det.elem_det_id
      and    var_comp.elem_det_importo!=0
      and    dvar.data_cancellazione is null
      and    det.data_cancellazione is null
      and    var_comp.data_cancellazione is null
      and    comp.data_cancellazione is null;
      GET DIAGNOSTICS codResult = ROW_COUNT;

      if codResult is null then
          v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Componenti stanziamenti non aggiornati.';
          raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

          codiceRisultato:=-1;
          messaggioRisultato:=v_messaggiorisultato_agg;
          return next;
          return;
      end if;

      v_messaggiorisultato_agg:=v_messaggiorisultato_agg||' Componenti stanziamenti aggiornati.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    end if;



    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';
    v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Verifica esistenza capitoli provvisori in variazione.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    codResult:=null;
    select coalesce(count(distinct e.elem_id),0) into codResult
    from siac_t_bil_elem_det_var dvar,siac_t_bil_elem e,
         siac_r_bil_elem_Stato rs,siac_d_bil_elem_stato stato
    where dvar.variazione_stato_id=variazioneStatoNewId
    and   e.elem_id=dvar.elem_id
    and   rs.elem_id=e.elem_id
    and   stato.elem_stato_id=rs.elem_stato_id
    and   stato.elem_stato_code='PR'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null;
    raise notice 'codResult=%',codResult;

    if coalesce(codResult,0)!=0 then

      v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione.';
      v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Aggiornamento stato capitoli provvisori in variazione.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
      update siac_r_bil_elem_Stato rs
      set    elem_stato_id=statoVA.elem_Stato_id,
             data_modifica=clock_timestamp(),
             login_operazione=rs.login_operazione||'-'||loginOperazione
      from siac_t_bil_elem_det_var dvar,siac_t_bil_elem e,
           siac_d_bil_elem_stato stato,siac_d_bil_elem_stato statoVA
      where dvar.variazione_stato_id=variazioneStatoNewId
      and   e.elem_id=dvar.elem_id
      and   rs.elem_id=e.elem_id
      and   stato.elem_stato_id=rs.elem_stato_id
      and   stato.elem_stato_code='PR'
      and   statoVA.ente_proprietario_id=stato.ente_proprietario_id
      and   statoVA.elem_stato_code='VA'
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null;
      GET DIAGNOSTICS codResult1 = ROW_COUNT;
      raise notice 'codResult1=%',codResult1;

      if coalesce(codResult,0)!=coalesce(codResult1,0) then
        v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Operazione non riuscita.';
        raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
        codiceRisultato:=-1;
        messaggioRisultato:=v_messaggiorisultato_agg;
        return next;
        return;
      end if;

      v_messaggiorisultato_agg:=  v_messaggiorisultato_agg||' Operazione riuscita.';
      raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;
    end if;


    v_messaggiorisultato_agg:=  v_messaggiorisultato||' Definizione variazione effettuata.';
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato_agg;

 end if;


 codiceRisultato:=0;
 messaggioRisultato:=  v_messaggiorisultato||' Operazione terminata.';
 raise notice 'messaggioRisultato=%',messaggioRisultato;
 return next;
 return;

exception
    when RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;
    messaggioRisultato:=  v_messaggiorisultato;
    codiceRisultato:=-1;
    return next;
    return;
	when others  THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' others - ' ||substring(upper(SQLERRM) from 1 for 2500);
    raise notice 'v_messaggiorisultato=%',v_messaggiorisultato;
    messaggioRisultato:=  v_messaggiorisultato;
    codiceRisultato:=-1;
    return next;
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

alter function siac.fnc_siac_bko_gestisci_variazione
(
   integer,
   integer,
   integer,
   boolean,
   varchar,
   boolean,
   varchar,
   timestamp
) owner to siac;

CREATE OR replace FUNCTION siac.fnc_fasi_bil_variazione_gest
(
annobilancio       varchar,
elencoVariazioni   text,
nomeTabella        varchar,
flagCambiaStato    varchar, -- [1,0],[true,false]
flagApplicaVar     varchar, -- [1,0],[true,false]
statoVar           varchar,
enteProprietarioId varchar,
loginoperazione    VARCHAR,
dataelaborazione   TIMESTAMP,
OUT faseBilElabIdRet   varchar,
OUT codiceRisultato    varchar,
OUT messaggioRisultato VARCHAR
)
returns RECORD
AS
$body$
  DECLARE
   strmessaggio       VARCHAR(1500):='';
   strmessaggiofinale VARCHAR(1500):='';
   codresult          INTEGER:=NULL;
   faseBilElabId         integer:=null;
   faseBilVarGestId      integer:=null;
   varCursor refcursor;
   recVarCursor record;
   strVarCursor varchar:=null;
   recResult record;

   scartoCode varchar(10):=null;
   scartoDesc varchar:=null;
   flagElab   varchar(10):=null;
   variazioneStatoNewId integer:=null;
   variazioneStatoTipoNewId integer:=null;

   elencoVariazioneCur text:='';

   APE_VAR_GEST CONSTANT VARCHAR :='APE_VAR_GEST';
  begin
    messaggiorisultato:='';
    codicerisultato:='0';
    fasebilelabidret:=null;


    strMessaggioFinale:='Variazione bilancio - gestione.';
    raise notice 'strMessaggioFinale=%',strMessaggioFinale;

    raise notice 'nomeTabella=%',      quote_nullable(nomeTabella);
    raise notice 'elencoVariazioni=%', quote_nullable(elencoVariazioni);

    if coalesce(nomeTabella,'')=''  and coalesce(elencoVariazioni,'')='' then
    	strmessaggio:=' Nome tabella e elenco variazione non valorizzati. Impossibile determinare variazioni da trattare.';
        raise exception ' ';
    end if;

    strMessaggio='Inserimento tabella fase_bil_t_elaborazione.';
    raise notice 'strMessaggio=%',strMessaggio;
    insert into  fase_bil_t_elaborazione
    (
    	fase_bil_elab_esito,
        fase_bil_elab_esito_msg,
        fase_bil_elab_tipo_id,
        ente_proprietario_id,
        validita_inizio,
        login_operazione
    )
    select  'IN',
            'ELABORAZIONE FASE BILANCIO '||APE_VAR_GEST||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,
            tipo.ente_proprietario_id,
            clock_timestamp(),
            loginoperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId::integer
    and   tipo.fase_bil_elab_tipo_code=APE_VAR_GEST
    returning fase_bil_elab_id into codResult;
    if codResult is null then
     strMessaggio:=strMessaggio||' Errore in inserimento - ';
     raise notice 'strMessaggio=%',strMessaggio;
     raise exception ' record non inserito.';
    end if;
    faseBilElabId:=codResult;
    raise notice 'faseBilElabId=%',faseBilElabId;

    if coalesce(elencoVariazioni,'')!='' then
     -- impostazione stringa per ricerca
     raise notice 'elencoVariazioni=%',elencoVariazioni;
     elencoVariazioneCur:=elencoVariazioni;
    else
     -- lettura da tabella
     if coalesce(nomeTabella,'')!='' then
	     raise notice 'Lettura tabella %',nomeTabella;
         strvarcursor:='select * from '||nomeTabella;
         open varCursor for execute strVarCursor;
		    loop
		    fetch varCursor into recVarCursor;
            exit when NOT FOUND;
            if coalesce(elencoVariazioneCur,'')!='' then
             elencoVariazioneCur:=elencoVariazioneCur||',';
            end if;
            elencoVariazioneCur:=elencoVariazioneCur||recVarCursor.variazione_num::varchar;

         end loop;
         close  varCursor;
      end if;
    end if;

    raise notice 'elencoVariazioneCur=%',quote_nullable(elencoVariazioneCur);
	if coalesce(elencoVariazioneCur,'')='' then
      strMessaggio:='Aggiornamento tabella fase_bil_t_elaborazione per errore.Impossibile determinare elenco variazioni da trattare.';
      codResult:=null;
      update fase_bil_t_elaborazione fase
      set    fase_bil_elab_esito='KO',
             fase_bil_elab_esito_msg=
              'ELABORAZIONE FASE BILANCIO '||APE_VAR_GEST||' TERMINATA CON ERRORE.IMPOSSIBILE DETERMINARE VARIAZIONI DA TRATTARE.',
             validita_fine=clock_timestamp(),
             data_modifica=clock_timestamp()
      where fase.fase_bil_elab_id=faseBilElabId
      returning fase.fase_bil_elab_id into codResult;
      if codResult is null then
          raise exception ' Tabella non aggiornata.';
      end if;
    end if;

    strMessaggio:='Preparazione cursore lettura variazioni.';
    raise notice 'strMessaggio=%',strMessaggio;

    strVarCursor:=null;
    varCursor:=null;
    recVarCursor:=null;

    strVarCursor:='select var.variazione_num::integer variazione_num, var.variazione_id, rs.variazione_stato_id, '
                  ||' bil.bil_id,per.anno::integer anno,'
                  ||' stato.variazione_stato_tipo_code, stato.variazione_stato_tipo_id '
                  ||' from siac_t_variazione var,siac_r_variazione_stato rs,siac_d_variazione_stato stato , '
                  ||' siac_t_bil bil,siac_t_periodo per '
                  ||' where stato.ente_proprietario_id='||enteProprietarioId
                  ||' and   stato.variazione_stato_tipo_code!=''A'' '
                  ||' and   rs.variazione_stato_tipo_id=stato.variazione_stato_tipo_id'
                  ||' and   var.variazione_id=rs.variazione_id '
                  ||' and   bil.bil_id=var.bil_id and per.periodo_id=bil.periodo_Id'
                  ||' and   per.anno::integer='||annoBilancio
                  ||' and   var.variazione_num in ('||elencoVariazioneCur||')'
                  ||' and   rs.data_cancellazione is null and rs.validita_fine is null '
                  ||' order by rs.validita_inizio, var.variazione_num::integer';


    raise notice 'strVarCursor=%',strVarCursor;
    strMessaggio:='Apertura cursore lettura variazioni.';
    raise notice 'strMessaggio=%',strMessaggio;
    open varCursor for execute strVarCursor;
    loop
      fetch varCursor into recVarCursor;
      exit when NOT FOUND;

      raise notice 'Variazione num=%',recVarCursor.variazione_num::varchar;

      strMessaggio:='Inserimento tabella fase_bil_t_variazione_gest variazione_numo='||recVarCursor.variazione_num::varchar||'.';
      raise notice 'strMessaggio=%',strMessaggio;

      scartoCode:=null;
      scartoDesc:=null;
      flagElab:='S';
	  variazioneStatoNewId:=null;
      variazioneStatoTipoNewId:=null;
      faseBilVarGestId:=null;
      -- insert into fase_bil_t_variazione_gest
	  insert into fase_bil_t_variazione_gest
      (
      	fase_bil_elab_id,
		variazione_id,
	    bil_id,
	    variazione_stato_id,
	    variazione_stato_tipo_id,
	    fl_cambia_stato,
	    fl_applica_var,
        login_operazione,
        ente_proprietario_id
      )
      values
      (
       faseBilElabId,
       recVarCursor.variazione_id,
       recVarCursor.bil_id,
       recVarCursor.variazione_stato_id,
       recVarCursor.variazione_stato_tipo_id,
       flagCambiaStato::boolean,
       flagApplicaVar::boolean,
       loginOperazione,
       enteProprietarioId::integer
      )
      returning fase_bil_var_gest_id into faseBilVarGestId;
      if faseBilVarGestId is null then
      	strMessaggio:=strMessaggio||' Errore in inserimento - ';
        raise notice 'strMessaggio=%',strMessaggio;
        raise exception ' record non inserito.';
      end if;
      raise notice 'faseBilVarGestId=%', faseBilVarGestId;

	  strMessaggio:='Esecuzione fnc_siac_bko_gestisci_variazione variazione_num='||recVarCursor.variazione_num::varchar||'.';
      raise notice 'strMessaggio=%',strMessaggio;

      select * into recResult
      from fnc_siac_bko_gestisci_variazione
           (
            enteProprietarioId::integer,
            recVarCursor.anno,
            recVarCursor.variazione_num,
            flagCambiaStato::boolean,
            statoVar,
            flagApplicaVar::boolean,
            loginOperazione,
            dataElaborazione
           );

      if recResult.codiceRisultato::integer=0 then
        strMessaggio:='Lettura nuovi identificativi per variazione_num='||recVarCursor.variazione_num::varchar||'.';
        raise notice 'strMessaggio=%',strMessaggio;
      	select rs.variazione_stato_id, stato.variazione_stato_tipo_id
        into   variazioneStatoNewId, variazioneStatoTipoNewId
        from siac_r_variazione_Stato rs,siac_d_variazione_stato stato
        where rs.variazione_id=recVarCursor.variazione_id
        and   stato.variazione_stato_tipo_id=rs.variazione_Stato_tipo_id
        and   rs.data_cancellazione is null
        and   rs.validita_fine is null;
        if variazioneStatoNewId is null or  variazioneStatoTipoNewId is null then
        	variazioneStatoNewId:=null;
            variazioneStatoTipoNewId:=null;
            scartoCode:='02';
       	    scartoDesc:=strMessaggio||strMessaggio||' Errore in lettura.';
            flagElab:='X';
        end if;
      else
        scartoCode:='01';
        scartoDesc:=recResult.messaggioRisultato;
        flagElab:='X';
      end if;

      strMessaggio:='Aggiornamento fase_bil_t_variazione_gest variazione_num='
                   ||recVarCursor.variazione_num::varchar||'flagElab='||flagElab||'.';
      raise notice 'strMessaggio=%',strMessaggio;
      codResult:=null;
   	  update fase_bil_t_variazione_gest fase
      set    scarto_code=scartoCode,
		     scarto_desc=scartoDesc,
             fl_elab=flagElab,
             variazione_stato_new_id=variazioneStatoNewId,
             variazione_stato_tipo_new_id=variazioneStatoTipoNewId
      where  fase.fase_bil_var_gest_id=faseBilVarGestId
      returning fase.fase_bil_var_gest_id into codResult;
      if codResult is null then
      	strMessaggio:=strMessaggio||' Errore in aggiornamento - ';
        raise exception ' record non aggiornato.';
      end if;

    end loop;
    close  varCursor;

    strMessaggio:='Chiusura ciclo-cursore.';
    raise notice 'strMessaggio=%',strMessaggio;

    strMessaggio:='Aggiornamento fase_bil_t_elaborazione termine con successo.';
    raise notice 'strMessaggio=%',strMessaggio;

    codResult:=null;
    update fase_bil_t_elaborazione fase
    set    fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_VAR_GEST||' TERMINATA CON SUCCESSO.',
           --validita_fine=clock_timestamp(),
           data_modifica=clock_timestamp()
    where fase.fase_bil_elab_id=faseBilElabId
    returning fase.fase_bil_elab_id into codResult;
    if codResult is null then
    	raise exception ' Tabella non aggiornata.';
    end if;


    if faseBilElabId is not null then
	    faseBilElabIdRet:=faseBilElabId::varchar;
    end if;

    messaggiorisultato:=strMessaggioFinale||strMessaggio;
    codiceRisultato:='0';
    raise notice 'messaggiorisultato=%',messaggiorisultato;
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'faseBilElabIdRet=%',coalesce(faseBilElabIdRet,' ');


    RETURN;
  EXCEPTION
  WHEN raise_exception THEN

    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'ERRORE :'
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;


    codicerisultato:='-1';
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'messaggiorisultato=%',messaggiorisultato;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice ' % % Nessun elemento trovato.' ,strmessaggiofinale,strmessaggio;
    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'Nessun elemento trovato.' ;
    codicerisultato:='-1';
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale
    ||strmessaggio
    ||'Errore DB '
    ||SQLSTATE
    ||' '
    ||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:='-1';
    raise notice 'codiceRisultato=%',codiceRisultato;
    raise notice 'messaggiorisultato=%',messaggiorisultato;

    RETURN;
  END;
  $body$ LANGUAGE 'plpgsql' volatile called ON NULL input security invoker cost 100;

alter function siac.fnc_fasi_bil_variazione_gest
(
  varchar,
  text,
  varchar,
  varchar,
  varchar,
  varchar,
  VARCHAR,
  varchar,
  TIMESTAMP,
  OUT varchar,
  OUT varchar,
  OUT  VARCHAR
) owner to siac;