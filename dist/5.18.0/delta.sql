/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


-- INIZIO 1.DDL-tabelle-2.sql



\echo 1.DDL-tabelle-2.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop view if exists siac.siac_v_dwh_mutuo_ripartizione;

--DROP TABLE if exists siac.siac_d_mutuo_ripartizione_tipo CASCADE;
CREATE TABLE if not exists siac.siac_d_mutuo_ripartizione_tipo (
	mutuo_ripartizione_tipo_id serial NOT NULL,
	mutuo_ripartizione_tipo_code varchar(200) NOT NULL,
	mutuo_ripartizione_tipo_desc varchar(500) NULL,
	--
	ente_proprietario_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_d_mutuo_ripartizione_tipo PRIMARY KEY (mutuo_ripartizione_tipo_id),
	CONSTRAINT siac_t_ente_proprietario_siac_d_mutuo_ripartizione_tipo
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

alter table siac.siac_d_mutuo_ripartizione_tipo owner to siac;


--DROP TABLE if exists siac.siac_r_mutuo_ripartizione CASCADE;
CREATE TABLE if not exists siac.siac_r_mutuo_ripartizione (
	mutuo_ripartizione_id serial NOT NULL,
	mutuo_id integer NOT NULL,
	mutuo_ripartizione_tipo_id integer NOT NULL,
	elem_id integer not null,
	mutuo_ripartizione_importo numeric NULL,
	mutuo_ripartizione_perc numeric NULL,
	--
	ente_proprietario_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	login_creazione varchar(200) NOT NULL,
	login_modifica varchar(200) NOT NULL,
	login_cancellazione varchar(200) NULL,
	CONSTRAINT pk_siac_r_mutuo_ripartizione PRIMARY KEY (mutuo_ripartizione_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_mutuo_ripartizione 
		FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_mutuo_siac_r_mutuo_ripartizione  
		FOREIGN KEY (mutuo_id) REFERENCES siac.siac_t_mutuo(mutuo_id),
	CONSTRAINT siac_t_bil_elem_siac_r_mutuo_ripartizione
		FOREIGN KEY (elem_id) REFERENCES siac.siac_t_bil_elem(elem_id)
);

alter table siac.siac_r_mutuo_ripartizione owner to siac;




-- INIZIO 2.task-132.sql



\echo 2.task-132.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/




drop view if exists siac.siac_v_dwh_mutuo_ripartizione;
create or replace view siac.siac_v_dwh_mutuo_ripartizione
(
    ente_proprietario_id,
    mutuo_numero,
	mutuo_ripartizione_tipo_code,
	mutuo_ripartizione_tipo_desc,
	anno_bilancio,
	mutuo_bil_elem_tipo,
	mutuo_bil_elem_code_capitolo,
	mutuo_bil_elem_code_articolo,
	mutuo_ripartizione_importo,
	mutuo_ripartizione_perc
 )
AS
(
SELECT 
    mutuo.ente_proprietario_id,
    mutuo.mutuo_numero,
    tipo.mutuo_ripartizione_tipo_code,
    tipo.mutuo_ripartizione_tipo_desc,
    per.anno::integer anno_bilancio,
    tipo_cap.elem_tipo_code mutuo_bil_elem_tipo,
    cap.elem_code mutuo_bil_elem_code_capitolo,
    cap.elem_code2 mutuo_bil_elem_code_articolo,
    r.mutuo_ripartizione_importo,
    r.mutuo_ripartizione_perc
FROM siac_t_mutuo mutuo ,siac_r_mutuo_ripartizione r,siac_d_mutuo_ripartizione_tipo tipo ,siac_t_bil_elem cap, siac_d_bil_elem_tipo tipo_cap, siac_t_bil bil,siac_t_periodo per
where mutuo.mutuo_id=r.mutuo_id 
AND    tipo.mutuo_ripartizione_tipo_id=r.mutuo_ripartizione_tipo_id 
AND    cap.elem_id=r.elem_id 
AND    tipo_cap.elem_tipo_id=cap.elem_tipo_id 
AND    bil.bil_id=cap.bil_id 
AND    per.periodo_id=bil.periodo_id
and     mutuo.data_cancellazione  is NULL
and     r.data_cancellazione  is NULL
and     cap.data_cancellazione  is NULL
);

alter view siac.siac_v_dwh_mutuo_ripartizione owner to siac;




-- INIZIO 3.task-45.sql



\echo 3.task-45.sql


INSERT INTO siac.siac_d_mutuo_stato(mutuo_stato_code, mutuo_stato_desc, ente_proprietario_id, validita_inizio, login_operazione)
SELECT tmp.codice, tmp.descrizione, e.ente_proprietario_id, now() as validita_inizio, 'admin' as login_operazione
FROM (VALUES
	('P', 'PREDEFINITIVO')
) AS tmp(codice, descrizione)
JOIN siac_t_ente_proprietario e on e.in_uso
WHERE NOT EXISTS (
	SELECT 1
	FROM siac.siac_d_mutuo_stato ms
	WHERE ms.mutuo_stato_code = tmp.codice
	and ms.ente_proprietario_id = e.ente_proprietario_id
);




-- INIZIO SIAC-8633.sql



\echo SIAC-8633.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-8633 Sofia 13.06.2023 inizio
alter table fase_bil_t_programmi_puntuale add column if not exists cronop_id integer null;

insert into fase_bil_d_elaborazione_tipo
(
 fase_bil_elab_tipo_code,
 fase_bil_elab_tipo_desc,
 fase_bil_elab_tipo_param,
 validita_inizio ,
 login_operazione ,
 ente_proprietario_id 
)
select 'APE_GEST_ALL_PROGRAMMI',
			'APERTURA BILANCIO : ALLINEAMENTO PROGRAMMI-CRONOP',
			'gp|GP|PG',
		    now(),
			'SIAC-8633',
			ente.ente_proprietario_id 
from siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id in (2,3,4,5,10,16)
and     not exists 
(
select 1 
from fase_bil_d_elaborazione_tipo tipo 
where tipo.ente_proprietario_id =ente.ente_proprietario_id 
and      tipo.fase_bil_elab_tipo_code ='APE_GEST_ALL_PROGRAMMI'
and      tipo.data_cancellazione is null 
and      tipo.validita_fine is null 
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_programmi_popola 
(
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);
drop FUNCTION if exists siac.fnc_fasi_bil_gest_apertura_programmi_pop_puntuale 
(
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone,
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
);

drop function if exists siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  ribalta_coll_mov boolean,    -- 17.05.2023 Sofia SIAC-8633
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);


drop FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_prev_approva_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
);

DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_acc_elabora 
(
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists 
siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp 
(
  enteproprietarioid integer,
  annobilancio integer,
  tipoelab varchar,
  fasebilelabid integer,
  minid integer,
  maxid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop function if exists siac.fnc_fasi_bil_gest_apertura_pluri_elabora
( enteproprietarioid integer, annobilancio integer, fasebilelabid integer, tipocapitologest character varying, tipomovgest character varying, tipomovgestts character varying, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying);


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_popola (
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';
    --- Sofia SIAC-8633 24.05.2023       
    GP_FASE                        CONSTANT varchar:='GP';  

	STATO_AN 			    	     CONSTANT varchar:='AN';
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=0;
    programmaTipoCode                varchar(10):=null;
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Popolamento.';

   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;




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

   --siac_t_programma
   --siac_r_programma_stato
   --siac_r_programma_class
   --siac_r_programma_attr
   --siac_r_programma_atto_amm
   --siac_r_movgest_ts_programma
   --siac_t_cronop
   --siac_r_cronop_stato
   --siac_r_cronop_attr
   --siac_t_cronop_elem
   --siac_r_cronop_elem_class
   --siac_r_cronop_elem_bil_elem
   --siac_t_cronop_elem_det

 /*  if tipoApertura=P_FASE then
 
   	bilancioElabId:=bilancioPrecId;
    programmaTipoCode=G_FASE;
   else
   	bilancioElabId:=bilancioId;
    programmaTipoCode=P_FASE;
   end if; Sofia SIAC-8633 24.05.2023         */

  -- Sofia SIAC-8633 24.05.2023         
  case  
   when tipoApertura=P_FASE then
	   	bilancioElabId:=bilancioPrecId;
    	programmaTipoCode=G_FASE;
   when tipoApertura=G_FASE then
	   bilancioElabId:=bilancioId;
       programmaTipoCode=P_FASE;
   when tipoApertura=GP_FASE then   
       bilancioElabId:=bilancioId;
       programmaTipoCode=G_FASE;
       tipoApertura=P_FASE;
  end case ;
 
   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   insert into fase_bil_t_programmi
   (
   	fase_bil_elab_id,
	fase_bil_programma_ape_tipo,
	programma_id,
	programma_tipo_id,
	bil_id,
    login_operazione,
    ente_proprietario_id
   )
   select faseBilElabId,
          tipoApertura,
          prog.programma_id,
          tipo.programma_tipo_id,
          prog.bil_id,
          loginOperazione,
          prog.ente_proprietario_id
   from siac_t_programma prog,siac_d_programma_tipo tipo,
	    siac_r_programma_stato rs,siac_d_programma_stato stato
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.programma_tipo_code=programmaTipoCode
   and   prog.programma_tipo_id=tipo.programma_tipo_id
   and   prog.bil_id=bilancioElabId
   and   rs.programma_id=prog.programma_id
   and   stato.programma_stato_id=rs.programma_stato_id
   and   stato.programma_stato_code!=STATO_AN
   and   prog.data_cancellazione is null
   and   prog.validita_fine is null
   and   rs.data_cancellazione is null
   and   rs.validita_fine is null;
   GET DIAGNOSTICS numeroProgr = ROW_COUNT;

   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi numero='||numeroProgr::varchar||'.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   if coalesce(numeroProgr)!=0 then
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' '||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    codResult:=null;
    -- modificare qui in base a indicazioni di Floriana con n-insert diverse
    -- previsione quelli con usato_per_fpv=true
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Previsione scelti come FPV.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   cronop.usato_per_fpv=true
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=p_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Previsione scelti come FPV. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- gestione   quelli con prov definitivo
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con provvedimento definitivo.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
         siac_r_cronop_atto_amm ratto,siac_r_atto_amm_stato rsatto,siac_d_atto_amm_stato statoatto
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   ratto.cronop_id=cronop.cronop_id
    and   rsatto.attoamm_id=ratto.attoamm_id
    and   statoatto.attoamm_stato_id=rsatto.attoamm_stato_id
    and   statoatto.attoamm_stato_code='DEFINITIVO'
    and   tipoApertura=g_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   rsatto.data_cancellazione is null
    and   rsatto.validita_fine is null
    and   not exists -- 17.05.2023 Sofia SIAC-8633
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    );
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con provvedimento definitivo. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    -- gestione   quelli con impegno collegato ( se non ne ho gia ribaltati con prov def )
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con impegno collegato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=g_fase
    and   exists
    (
    select 1
    from siac_t_cronop_elem celem,siac_r_movgest_ts_cronop_elem rmov
    where celem.ente_proprietario_id=enteProprietarioId
    and   celem.cronop_id=cronop.cronop_id
    and   rmov.cronop_elem_id=celem.cronop_elem_id
    and   celem.data_cancellazione is null
    and   celem.validita_fine is null
    and   rmov.data_cancellazione is null
    and   rmov.validita_fine is null
    )
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con impegno collegato. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- previsione/gestione quelli non annullati ( ultimo cronop aggiornato ) se non ne ho gia ribaltato prima
	codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Ultimo cronop aggiornato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   exists
	(
      select 1
      from siac_t_cronop c1
      where c1.ente_proprietario_id=enteProprietarioId
      and   c1.cronop_id=cronop.cronop_id
      and   c1.data_modifica=
      (
        select max(cmax.data_modifica)
        from siac_t_cronop cmax,siac_r_cronop_stato rsmax,siac_d_cronop_stato stmax
        where cmax.ente_proprietario_id=enteProprietarioId
        and   cmax.programma_id=c1.programma_id
        and   cmax.bil_id=c1.bil_id
        and   rsmax.cronop_id=cmax.cronop_id
        and   stmax.cronop_stato_id=rsmax.cronop_stato_id
        and   stmax.cronop_stato_code!=STATO_AN
        and   cmax.data_cancellazione is null
        and   cmax.validita_fine is null
        and   rsmax.data_cancellazione is null
        and   rsmax.validita_fine is null
      )
      and   c1.data_cancellazione is null
	  and   c1.validita_fine is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;


    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Ultimo cronop aggiornato. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;



    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop numero='||numeroCronop::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;
   end if;
   raise notice 'Programmmi inseriti in fase_bil_t_programmi=%',numeroProgr;
   raise notice 'CronoProgrammmi inseriti in fase_bil_t_cronop=%',numeroCronop;


   strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
   update fase_bil_t_elaborazione fase
   set fase_bil_elab_esito='IN-1',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO IN-1.POPOLA PROGRAMMI-CRONOP.'
   where fase.fase_bil_elab_id=faseBilElabId;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   if coalesce(codiceRisultato,0)=0 then
    	messaggioRisultato:=strMessaggioFinale||'- FINE.';
   else messaggioRisultato:=strMessaggioFinale||strMessaggio;
   end if;

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter FUNCTION  siac.fnc_fasi_bil_gest_apertura_programmi_popola (  integer, integer, integer,  varchar,  varchar,  timestamp, out integer, out  varchar) owner to siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_pop_puntuale 
(
  fasebilelabid integer,
  enteproprietarioid integer,
  annobilancio integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';
    --- Sofia SIAC-8633 24.05.2023       
    GP_FASE                        CONSTANT varchar:='GP';  

	STATO_AN 			    	     CONSTANT varchar:='AN';
    numeroProgr                      integer:=null;
    numeroCronop					 integer:=0;
    programmaTipoCode                varchar(10):=null;
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Popolamento.';

   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;




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

   --siac_t_programma
   --siac_r_programma_stato
   --siac_r_programma_class
   --siac_r_programma_attr
   --siac_r_programma_atto_amm
   --siac_r_movgest_ts_programma
   --siac_t_cronop
   --siac_r_cronop_stato
   --siac_r_cronop_attr
   --siac_t_cronop_elem
   --siac_r_cronop_elem_class
   --siac_r_cronop_elem_bil_elem
   --siac_t_cronop_elem_det

  -- Sofia SIAC-8633 24.05.2023
  /*
   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
    programmaTipoCode=G_FASE;
   else
   	bilancioElabId:=bilancioId;
    programmaTipoCode=P_FASE;
   end if;*/

  -- Sofia SIAC-8633 24.05.2023         
  case  
   when tipoApertura=P_FASE then
	   	bilancioElabId:=bilancioPrecId;
    	programmaTipoCode=G_FASE;
   when tipoApertura=G_FASE then
	   bilancioElabId:=bilancioId;
       programmaTipoCode=P_FASE;
   when tipoApertura=GP_FASE then   
       bilancioElabId:=bilancioId;
       programmaTipoCode=G_FASE;
       tipoApertura=P_FASE;
  end case ;
 
   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   insert into fase_bil_t_programmi
   (
   	fase_bil_elab_id,
	fase_bil_programma_ape_tipo,
	programma_id,
	programma_tipo_id,
	bil_id,
    login_operazione,
    ente_proprietario_id
   )
   select faseBilElabId,
          tipoApertura,
          prog.programma_id,
          tipo.programma_tipo_id,
          prog.bil_id,
          loginOperazione,
          prog.ente_proprietario_id
   from fase_bil_t_programmi_puntuale punt,
        siac_t_programma prog,siac_d_programma_tipo tipo,
	    siac_r_programma_stato rs,siac_d_programma_stato stato
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.programma_tipo_code=programmaTipoCode
   and   prog.programma_tipo_id=tipo.programma_tipo_id
   and   prog.bil_id=bilancioElabId
   and   rs.programma_id=prog.programma_id
   and   stato.programma_stato_id=rs.programma_stato_id
   and   stato.programma_stato_code!=STATO_AN
   and   punt.programma_id=prog.programma_id
   and   prog.data_cancellazione is null
   and   prog.validita_fine is null
   and   rs.data_cancellazione is null
   and   rs.validita_fine is null;
  -- and   punt.data_cancellazione is null
   --and   punt.validita_fine is null;
   GET DIAGNOSTICS numeroProgr = ROW_COUNT;

   strMessaggio:='Inserimento dati programmi in fase_bil_t_programmi numero='||numeroProgr::varchar||'.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   if coalesce(numeroProgr)!=0 then
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' '||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    codResult:=null;
    -- modificare qui in base a indicazioni di Floriana con n-insert diverse
    -- previsione quelli con usato_per_fpv=true
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Previsione scelti come FPV.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 19.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and      punt.programma_id =fase.programma_id  --- Sofia SIAC-8633 19.06.2023
    and      cronop.programma_id=fase.programma_id
    and      cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 19.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   cronop.usato_per_fpv=true
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=p_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Previsione scelti come FPV. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- gestione   quelli con prov definitivo
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con provvedimento definitivo.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
         siac_r_cronop_atto_amm ratto,siac_r_atto_amm_stato rsatto,siac_d_atto_amm_stato statoatto,
         fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 19.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and      punt.programma_id =fase.programma_id --- Sofia SIAC-8633 19.06.2023
    and      cronop.programma_id=fase.programma_id
    and      cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 19.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   ratto.cronop_id=cronop.cronop_id
    and   rsatto.attoamm_id=ratto.attoamm_id
    and   statoatto.attoamm_stato_id=rsatto.attoamm_stato_id
    and   statoatto.attoamm_stato_code='DEFINITIVO'
    and   tipoApertura=g_fase
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   rsatto.data_cancellazione is null
    and   rsatto.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con provvedimento definitivo. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    -- gestione   quelli con impegno collegato ( se non ne ho gia ribaltati con prov def )
    codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Gestione con impegno collegato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
              fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 21.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and     punt.programma_id=fase.programma_id --- Sofia SIAC-8633 21.06.2023
    and   cronop.programma_id=fase.programma_id
    and   cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 21.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   tipoApertura=g_fase
    and   exists
    (
    select 1
    from siac_t_cronop_elem celem,siac_r_movgest_ts_cronop_elem rmov
    where celem.ente_proprietario_id=enteProprietarioId
    and   celem.cronop_id=cronop.cronop_id
    and   rmov.cronop_elem_id=celem.cronop_elem_id
    and   celem.data_cancellazione is null
    and   celem.validita_fine is null
    and   rmov.data_cancellazione is null
    and   rmov.validita_fine is null
    )
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;

    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Gestione con impegno collegato. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- previsione/gestione quelli non annullati ( ultimo cronop aggiornato ) se non ne ho gia ribaltato prima
	codResult:=null;
    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop. Ultimo cronop aggiornato.';
    insert into fase_bil_t_cronop
    (
	    fase_bil_elab_id,
	    fase_bil_cronop_ape_tipo,
		cronop_id,
		programma_id,
	    bil_id,
        login_operazione,
   	    ente_proprietario_id
    )
    select fase.fase_bil_elab_id,
           tipoApertura,
           cronop.cronop_id,
           cronop.programma_id,
           cronop.bil_id,
           loginOperazione,
           cronop.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               fase_bil_t_programmi_puntuale  punt     --- Sofia SIAC-8633 21.06.2023
    where fase.fase_bil_elab_id=faseBilElabId
    and   cronop.programma_id=fase.programma_id
    --- Sofia SIAC-8633 21.06.2023
    and  punt.programma_id =fase.programma_id 
    and   cronop.bil_id=bilancioElabId
    --- Sofia SIAC-8633 21.06.2023    
    and   coalesce(punt.cronop_id, cronop.cronop_id) = cronop.cronop_id 
    and   rs.cronop_id=cronop.cronop_id
    and   stato.cronop_stato_id=rs.cronop_stato_id
    and   stato.cronop_stato_code!=STATO_AN
    and   not exists
    (
    select 1
    from fase_bil_t_cronop fase1
    where fase1.fase_bil_elab_id=faseBilElabId
    and   fase1.cronop_id=cronop.cronop_id
    and   fase1.data_cancellazione is null
    )
    and   exists
	(
      select 1
      from siac_t_cronop c1
      where c1.ente_proprietario_id=enteProprietarioId
      and   c1.cronop_id=cronop.cronop_id
      and   c1.data_modifica=
      (
        select max(cmax.data_modifica)
        from siac_t_cronop cmax,siac_r_cronop_stato rsmax,siac_d_cronop_stato stmax
        where cmax.ente_proprietario_id=enteProprietarioId
        and   cmax.programma_id=c1.programma_id
        and   cmax.bil_id=c1.bil_id
        and   rsmax.cronop_id=cmax.cronop_id
        and   stmax.cronop_stato_id=rsmax.cronop_stato_id
        and   stmax.cronop_stato_code!=STATO_AN
        and   cmax.data_cancellazione is null
        and   cmax.validita_fine is null
        and   rsmax.data_cancellazione is null
        and   rsmax.validita_fine is null
      )
      and   c1.data_cancellazione is null
	  and   c1.validita_fine is null
    )
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if codResult is not null then
	    numeroCronop:=numeroCronop+codResult;
    end if;


    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop.Ultimo cronop aggiornato. numero='||codResult::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;



    strMessaggio:='Inserimento dati crono-programmi in fase_bil_t_cronop numero='||numeroCronop::varchar||'.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;
   end if;
   raise notice 'Programmmi inseriti in fase_bil_t_programmi=%',numeroProgr;
   raise notice 'CronoProgrammmi inseriti in fase_bil_t_cronop=%',numeroCronop;


   strMessaggio:='Aggiornamento stato fase bilancio IN-1.';
   update fase_bil_t_elaborazione fase
   set fase_bil_elab_esito='IN-1',
       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO IN-1.POPOLA PROGRAMMI-CRONOP.'
   where fase.fase_bil_elab_id=faseBilElabId;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


   if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||'- FINE.';
   else messaggioRisultato:=strMessaggioFinale||strMessaggio;
   end if;

   return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_pop_puntuale 
(
  integer,
  integer,
  integer,
  varchar,
  varchar,
  timestamp,
  out  integer,
  out  varchar
) owner to siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
fasebilelabid integer, 
enteproprietarioid integer, 
annobilancio integer, 
tipoapertura varchar, 
loginoperazione varchar, 
dataelaborazione timestamp without time zone, 
ribalta_coll_mov boolean DEFAULT true, 
OUT codicerisultato integer, 
OUT messaggiorisultato varchar
)
RETURNS record
AS $body$
			 
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;
    periodoId         integer:=null;
    periodoPrecId     integer:=null;
	dataInizioVal     timestamp:=null;


    bilancioElabId                   integer:=null;

    APE_GEST_PROGRAMMI    	    	 CONSTANT varchar:='APE_GEST_PROGRAMMI';

    P_FASE							 CONSTANT varchar:='P';
    G_FASE					    	 CONSTANT varchar:='G';
    -- Sofia SIAC-8633 24.05.2023      
    GP_FASE					    	 CONSTANT varchar:='GP';
   
	STATO_AN 			    	     CONSTANT varchar:='AN';

	-- 21.01.2022 Sofia Jira SIAC-8536
    FL_RIL_FPV_ATTR                  CONSTANT varchar:='FlagRilevanteFPV';
    FlagRilevanteFPVAttrId           integer:=NULL;

    numeroProgr                      integer:=null;
    numeroCronop					 integer:=null;

     -- 30.07.2019 Sofia siac-6934
    flagDaRiaccAttrId                integer:=null;
    annoRiaccAttrId                  integer:=null;
    numeroRiaccAttrId                integer:=null;

   
   
BEGIN

   codiceRisultato:=null;
   messaggioRisultato:=null;

   dataInizioVal:= clock_timestamp();


   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'. Elaborazione.';


    codResult:=null;
    strMessaggio:='Verifica stato fase_bil_t_elaborazione.';
    select 1  into codResult
    from fase_bil_t_elaborazione fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_elab_esito like 'IN-%'
    and   fase.data_cancellazione is null;

    if codResult is null then
      raise exception ' Nessuna elaborazione in corso [IN-n].';
    end if;


    codResult:=null;
    strMessaggio:='Verifica esistenza programmi da creare in fase_bil_t_programmi.';
    select 1 into codResult
    from fase_bil_t_programmi fase
    where fase.fase_bil_elab_id=faseBilElabId
    and     fase.data_cancellazione is null;

    if codResult is null then
--      raise exception ' Nessun  programma da creare.';
      -- 10.09.2019 Sofia SIAC-7023
      codiceRisultato:=0;
      messaggioRisultato:=strMessaggio||' Nessun  programma da creare.';
      return;
    end if;


   strMessaggio:='Inserimento LOG.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;


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

 /*
   if tipoApertura=P_FASE THEN
   	bilancioElabId:=bilancioPrecId;
   else
   	bilancioElabId:=bilancioId;
   end if; Sofia SIAC-8633 24.05.2023      
   */
  
  --  Sofia SIAC-8633 24.05.2023      
   case 
    when tipoApertura=P_FASE THEN
	   	bilancioElabId:=bilancioPrecId;
    when tipoApertura=G_FASE THEN
	   	bilancioElabId:=bilancioId;
	when tipoApertura=GP_FASE THEN   
	   bilancioElabId:=bilancioId;
	   tipoApertura =P_FASE;
    end case;	  
  
  
   -- 30.07.2019 Sofia siac-6934
   strMessaggio:='Lettura identificativi attributi riaccertamento.';
   SELECT attr.attr_id
   INTO   flagDaRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='flagDaRiaccertamento'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   annoRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='annoRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

   SELECT attr.attr_id
   INTO   numeroRiaccAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code ='numeroRiaccertato'
   AND    attr.ente_proprietario_id = enteproprietarioid;

  
  	
   -- 21.01.2022 Sofia Jira SIAC-8536
   strMessaggio:='Lettura identificativo attributo FlagRilevanteFPV.';
   SELECT attr.attr_id
   INTO   FlagRilevanteFPVAttrId
   FROM   siac_t_attr attr
   WHERE  attr.attr_code =FL_RIL_FPV_ATTR
   AND    attr.ente_proprietario_id = enteproprietarioid;
  
   strMessaggio:='Inizio inserimento dati programmi da  fase_bil_t_programmi - inizio.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

  
  
   -- 16.05.2023 Sofia SIAC-8633 - inizio 
  --  gestione scarti per programma esistenti in bilancioId - devono essere riportati solo programmi non esistenti
  strMessaggio:='Gestione scarti programmi esistenti da creare in fase_bil_t_programmi.';
  codResult:=0;
  update  fase_bil_t_programmi fase
  set    fl_elab='X',
           scarto_code='001',
           scarto_desc ='PROGRAMMA ESISTENTE PER TIPO='||tipoApertura
  from siac_t_programma progr,
	        siac_t_programma progrNew,
            siac_d_programma_tipo tipo,
            siac_r_programma_stato rs,siac_d_programma_stato stato 
   where fase.fase_bil_elab_id=faseBilElabId
   and      fase.fl_elab='N'   
   and      progr.programma_id=fase.programma_id
   and      tipo.ente_proprietario_id=progr.ente_proprietario_id
   and      tipo.programma_tipo_code=tipoApertura
   and      progrNew.programma_tipo_id=tipo.programma_tipo_id 
   and      progrNew.programma_code =progr.programma_code 
   and      progrNew.bil_id=bilancioId 
   and      rs.programma_id=progrNew.programma_id 
   and      stato.programma_stato_id =rs.programma_stato_id 
   and      stato.programma_stato_code !='AN'
   and      progr.data_cancellazione  is null 
   and      progr.validita_fine  is null 
   and      fase.data_cancellazione is null
   and      progrNew.data_cancellazione  is null 
   and      progrNew.validita_fine  is null 
   and      rs.data_cancellazione  is null 
   and      rs.validita_fine  is null;
   GET DIAGNOSTICS codResult = ROW_COUNT;
   if codResult is null then codResult:=0; end if;
   raise notice '% Scartati=%', strMessaggio,codResult;
   
   strMessaggio:='Numero di programmi scartati per esistenza='||coalesce(codResult,0)::varchar||'.';
   raise notice '%', strMessaggio;
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if; 
  
   /*codResult:=null;
   strMessaggio:='Verifica esistenza programmi da creare in fase_bil_t_programmi.';
   select 1 into codResult
   from fase_bil_t_programmi fase
   where fase.fase_bil_elab_id=faseBilElabId
   and      fase.fl_elab ='N'
    and     fase.data_cancellazione is null;

    if codResult is null then
--      raise exception ' Nessun  programma da creare.';
      codiceRisultato:=0;
      messaggioRisultato:=strMessaggio||' Nessun  programma da creare.';
      return;
    end if;*/
    -- 16.05.2023 Sofia SIAC-8633 - fine   

   -- siac_t_programma

   strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_t_programma].';
   insert into siac_t_programma
   (
   	 programma_code,
	 programma_desc,
     programma_tipo_id,
     bil_id,
     programma_data_gara_indizione,
	 programma_data_gara_aggiudicazione,
	 investimento_in_definizione,
     programma_responsabile_unico,
	 programma_spazi_finanziari,
     programma_affidamento_id,
     login_operazione,
     validita_inizio,
     ente_proprietario_id
   )
   select  progr.programma_code,
           progr.programma_desc,
           tipo.programma_tipo_id,
           bilancioId,
           progr.programma_data_gara_indizione,
		   progr.programma_data_gara_aggiudicazione,
	   	   progr.investimento_in_definizione,
	       progr.programma_responsabile_unico,
	   	   progr.programma_spazi_finanziari,
	       progr.programma_affidamento_id,
           loginOperazione||'@'||fase.fase_bil_programma_id::varchar,
           clock_timestamp(),
           progr.ente_proprietario_id
   from fase_bil_t_programmi fase,siac_t_programma progr,
        siac_d_programma_tipo tipo
   where fase.fase_bil_elab_id=faseBilElabId
   and   progr.programma_id=fase.programma_id
   and   fase.fl_elab='N'
   and   tipo.ente_proprietario_id=progr.ente_proprietario_id
   and   tipo.programma_tipo_code=tipoApertura
   and   fase.data_cancellazione is null;

   GET DIAGNOSTICS numeroProgr = ROW_COUNT;


   strMessaggio:='Numero di programmi inseriti='||coalesce(numeroProgr,0)::varchar||'.';
   raise notice '%', strMessaggio;
   codResult:=null;

  insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;

   -- inserimento dati programmi
   if coalesce(numeroProgr,0)!=0 then
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - aggiornamento fase_bil_t_programmi.';
    codResult:=null;
    update fase_bil_t_programmi fase
    set    programma_new_id=progr.programma_id,
             fl_elab='S'
    from   siac_t_programma progr
    where  fase.fase_bil_elab_id=faseBilElabId
    and    fase.fl_elab='N'
    and    progr.ente_proprietario_id=enteProprietarioId
    and    progr.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-SIAC-8470
    and    progr.login_operazione like loginOperazione||'@%'
    and    substring(progr.login_operazione from position ('@' in progr.login_operazione)+1)::integer=fase.fase_bil_programma_id
    and    fase.data_cancellazione is null
    and    progr.data_cancellazione is null
    and    progr.validita_fine is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=coalesce(numeroProgr,0) then
     raise exception ' Il numero di aggiornamenti non corrisponde al numero di programmi inseriti.';
    end if;


    -- siac_r_programma_stato
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_stato].';
    codResult:=null;
    insert into siac_r_programma_stato
    (
   	 programma_id,
     programma_stato_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rs.programma_stato_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_stato rs
    where fase.fase_bil_elab_id=faseBilElabId
    and   rs.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   fase.data_cancellazione is null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    if coalesce(codResult,0)!=0 and coalesce(numeroProgr,0)=0 then
	   raise exception ' Il numero di stati inseriti non corrisponde al numero di programmi inseriti.';
    end if;
    raise notice '% numIns=%', strMessaggio,codResult;



    -- siac_r_programma_class
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_class].';
    codResult:=null;
    insert into siac_r_programma_class
    (
   	 programma_id,
     classif_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
           rc.classif_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_class rc,siac_t_class c
    where fase.fase_bil_elab_id=faseBilElabId
    and   rc.programma_id=fase.programma_id
    and   c.classif_id=rc.classif_id
    and   fase.programma_new_id is not null
    and   c.data_cancellazione is null
    and   rc.data_cancellazione is null
    and   rc.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

 

    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_attr].';
    -- siac_r_programma_attr
    codResult:=null;
    insert into siac_r_programma_attr
    (
   	 programma_id,
     attr_id,
     boolean,
     testo,
     percentuale,
     numerico,
     tabella_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
   	       rattr.attr_id,
---   	       rattr.boolean     -- 21.01.2022 Sofia Jira SIAC-8563
   	       ( CASE WHEN tipoapertura=P_FASE AND rattr.attr_id=FlagRilevanteFPVAttrId THEN 'N'
   	         ELSE  rattr.boolean END 
   	       )  ,     -- 21.01.2022 Sofia Jira SIAC-8563
		   rattr.testo,
		   rattr.percentuale,
	       rattr.numerico,
	       rattr.tabella_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_attr rattr
    where fase.fase_bil_elab_id=faseBilElabId
    and   rattr.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

   
   
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_programma_atto_amm].';
    -- siac_r_programma_atto_amm
    codResult:=null;
    insert into siac_r_programma_atto_amm
    (
     programma_id,
     attoamm_id,
     validita_inizio,
     login_operazione,
     ente_proprietario_id
    )
    select fase.programma_new_id,
	       ratto.attoamm_id,
           clock_timestamp(),
           loginOperazione,
           fase.ente_proprietario_id
    from fase_bil_t_programmi fase,siac_r_programma_atto_amm ratto
    where fase.fase_bil_elab_id=faseBilElabId
    and   ratto.programma_id=fase.programma_id
    and   fase.programma_new_id is not null
    and   ratto.data_cancellazione is null
    and   ratto.validita_fine is null
    and   fase.data_cancellazione is null;

    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% numIns=%', strMessaggio,codResult;

   -- 19.04.2023 Sofia SIAC-TASK-21
   if tipoApertura=G_FASE then 
    strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi [siac_r_mutuo_programma].';
    -- siac_r_mutuo_programma
    codResult:=null;
    
   insert into siac_r_mutuo_programma
    (
     programma_id,
     mutuo_id,
     mutuo_programma_importo_iniziale,
     mutuo_programma_importo_finale,
     validita_inizio,
     login_operazione,
     login_creazione,
     login_modifica,
     ente_proprietario_id
    )
    select query.programma_id,
	            query.mutuo_id,
	            query.mutuo_programma_importo_iniziale ,
	            query.programma_importo,
	            clock_timestamp(),
                loginOperazione,
                loginOperazione,
                loginOperazione,
                enteProprietarioId
  from 
  (
    with 
    progrNew as 
    (
     select p.programma_id, p.programma_code ,coalesce(rattr.numerico ,0) programma_importo
     from fase_bil_t_programmi fase,
               siac_t_programma p 
                 left join siac_r_programma_attr rattr join siac_t_attr attr on (attr.attr_id=rattr.attr_id and   attr.attr_code='ValoreComplessivoProgramma')
                  on (rattr.programma_id=p.programma_id and rattr.data_cancellazione  is null and  rattr.validita_fine is null )
     where fase.fase_bil_elab_id=faseBilElabId
     and      p.programma_id =fase.programma_new_id
     and      fase.programma_new_id is not NULL
     and      fase.data_cancellazione is null
     and      p.data_cancellazione is null
     and      p.validita_fine is null
    ),
    progrMutuo as
    (
     select p.programma_code, r.mutuo_id, r.mutuo_programma_importo_iniziale 
     from siac_t_programma p , siac_d_programma_tipo tipo,  siac_r_programma_stato rs,siac_d_programma_stato statoP ,
               siac_r_mutuo_programma r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato
    where tipo.ente_proprietario_id =enteProprietarioId 
    and      tipo.programma_tipo_code =G_FASE
    and      p.programma_tipo_id=tipo.programma_tipo_id 
    and      p.bil_id=bilancioPrecId
    and      rs.programma_id =p.programma_id 
    and      statoP.programma_stato_id =rs.programma_stato_id 
    and      statoP.programma_stato_code !='AN'
    and      r.programma_id=p.programma_id
    and      mutuo.mutuo_id=r.mutuo_id 
    and      stato.mutuo_stato_id=mutuo.mutuo_stato_id 
    and      stato.mutuo_stato_code!='A'
    and      r.data_cancellazione is null
    and      r.validita_fine is null
    and      mutuo.data_cancellazione is null
    and      mutuo.validita_fine is null
    and      p.data_cancellazione is null
    and      p.validita_fine is null
    and      rs.data_cancellazione is null
    and      rs.validita_fine is null
    )
	select progrNew.programma_id,
		        progrNew.programma_importo,
	            progrMutuo.mutuo_id,
	            progrMutuo.mutuo_programma_importo_iniziale
	from progrNew , progrMutuo 
	where progrNew.programma_code=progrMutuo.programma_code
  ) query;
  GET DIAGNOSTICS codResult = ROW_COUNT;
   raise notice '% numIns=%', strMessaggio,codResult;
  end if;   
 end if;


  strMessaggio:='Inserimento dati programmi da fase_bil_t_programmi - fine .';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
  end if;
  -- fine inserimento dati programmi
  
  -- 16.05.2023 Sofia SIAC-8633 - cronop 
 
   strMessaggio:='Inizio inserimento dati crono-programmi da  fase_bil_t_cronop - inizio.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
   end if;
  
  strMessaggio:='Gestione scarti crono-programmi esistenti da creare in fase_bil_t_cronop.';
  codResult:=0;
  update  fase_bil_t_cronop fasec
  set    fl_elab='X',
           scarto_code='001',
           scarto_desc ='CRONOP ESISTENTE PER TIPO='||tipoApertura
 from siac_t_programma p, 
            siac_t_programma pNew, siac_d_programma_tipo tipo,siac_r_programma_stato rs,siac_d_programma_stato stato,
            siac_t_cronop cronop, 
            siac_t_cronop cNew,siac_r_cronop_stato  rs_cronop,siac_d_cronop_stato  stato_cronop 
  where fasec.fase_bil_elab_id=faseBilElabId
  and     fasec.fl_elab='N'
  and     p.programma_id =fasec.programma_id 
  and     cronop.cronop_id =fasec.cronop_id 
  and     cronop.programma_id =p.programma_id
  and     tipo.ente_proprietario_id =p.ente_proprietario_id 
  and     tipo.programma_tipo_code =tipoApertura
  and     pNew.programma_tipo_id=tipo.programma_tipo_id 
  and     pNew.programma_code =p.programma_code 
  and     pNew.bil_id=bilancioId
  and     rs.programma_id =pNew.programma_id 
  and     stato.programma_stato_id =rs.programma_stato_id 
  and     stato.programma_stato_code!='AN'
  and     cNew.programma_id=pNew.programma_id 
  and     cNew.cronop_code=cronop.cronop_code
  and     cNew.bil_id=pNew.bil_id
  and     rs_cronop.cronop_id=cNew.cronop_id 
  and     stato_cronop.cronop_stato_id =rs_cronop.cronop_stato_id 
  and     stato_cronop.cronop_stato_code !='AN'
  and     fasec.data_cancellazione is null
  and     cronop.data_cancellazione is null 
  and     cronop.validita_fine is null
  and     p.data_cancellazione is null 
  and     p.validita_fine is null
  and     pNew.data_cancellazione is null 
  and     pNew.validita_fine is null
  and     cNew.data_cancellazione is null 
  and     cNew.validita_fine is null
 and      rs.data_cancellazione is null 
 and      rs.validita_fine is null
 and      rs_cronop.data_cancellazione is null 
 and      rs_cronop.validita_fine is null;
 GET DIAGNOSTICS codResult = ROW_COUNT;
 if codResult is null then codResult:=0; end if;
 raise notice '% Scartati=%', strMessaggio,codResult;

  /*codResult:=null;
  select 1 into codResult
  from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec
  where fasep.fase_bil_elab_id=faseBilElabId
  and   fasep.programma_new_id is not null
  and   fasep.fl_elab='S'
  and   fasec.fase_bil_elab_id=faseBilElabId
  and   fasec.programma_id=fasep.programma_id
  and   fasec.fl_elab='N'
  and   fasep.data_cancellazione is null
  and   fasec.data_cancellazione is null;
  16.05.2023 Sofia SIAC-8633 - cronop */

  -- 16.05.2023 Sofia SIAC-8633 - cronop
  strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - verifica dati creare [fase_bil_t_cronop].';
  codResult:=0;
  select coalesce(count(*),0) into codResult
  from fase_bil_t_cronop fasec,siac_t_programma p, 
            siac_t_programma pNew, siac_d_programma_tipo tipo,siac_r_programma_stato rs,siac_d_programma_stato stato,
            siac_t_cronop cronop
  where fasec.fase_bil_elab_id=faseBilElabId
  and     fasec.fl_elab='N'
  and     p.programma_id =fasec.programma_id 
  and     cronop.cronop_id =fasec.cronop_id 
  and     cronop.programma_id =p.programma_id
  and     tipo.ente_proprietario_id =p.ente_proprietario_id 
  and     tipo.programma_tipo_code =tipoApertura
  and     pNew.programma_tipo_id=tipo.programma_tipo_id 
  and     pNew.programma_code =p.programma_code 
  and     pNew.bil_id=bilancioId
  and     rs.programma_id =pNew.programma_id 
  and     stato.programma_stato_id =rs.programma_stato_id 
  and     stato.programma_stato_code!='AN'
  and     not exists 
  (
   select 1 
   from   siac_t_cronop cNew,siac_r_cronop_stato  rs_cronop,siac_d_cronop_stato  stato_cronop
   where cNew.programma_id=pNew.programma_id 
   and      cNew.cronop_code=cronop.cronop_code
   and      cNew.bil_id=pNew.bil_id
   and      rs_cronop.cronop_id=cNew.cronop_id 
   and      stato_cronop.cronop_stato_id =rs_cronop.cronop_stato_id 
   and      stato_cronop.cronop_stato_code !='AN'
   and      cNew.data_cancellazione is null 
   and      cNew.validita_fine is null
   and       rs_cronop.data_cancellazione is null 
   and       rs_cronop.validita_fine is null
  )
  and     fasec.data_cancellazione is null
  and     cronop.data_cancellazione is null 
  and     cronop.validita_fine is null
  and     p.data_cancellazione is null 
  and     p.validita_fine is null
  and     pNew.data_cancellazione is null 
  and     pNew.validita_fine is null
  and      rs.data_cancellazione is null 
  and      rs.validita_fine is null;
  raise notice '% numdaIns=%', strMessaggio,codResult;


  if codResult is not null then

   	strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop da inserire numero='||codResult::varchar||'- inizio.';
	codResult:=null;
	insert into fase_bil_t_elaborazione_log
	(fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
	)
    values
    (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;
    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;


    
    -- siac_t_cronop
   	/*-- 16.05.2023 Sofia SIAC-8633 - cronop
   	 * insert into siac_t_cronop
    (
    	 cronop_code,
	     cronop_desc,
	     programma_id,
	     bil_id,
	     usato_per_fpv,
         cronop_data_approvazione_fattibilita,
	     cronop_data_approvazione_programma_def,
		 cronop_data_approvazione_programma_esec,
		 cronop_data_avvio_procedura,
		 cronop_data_aggiudicazione_lavori,
		 cronop_data_inizio_lavori,
		 cronop_data_fine_lavori,
		 cronop_giorni_durata,
		 cronop_data_collaudo,
	     gestione_quadro_economico,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         cronop.cronop_code,
	     cronop.cronop_desc,
	     fasep.programma_new_id,
	     bilancioId,
--	     cronop.usato_per_fpv,      -- 04.10.2022 Sofia Jira SIAC-8816
   	       ( CASE WHEN tipoapertura=P_FASE  THEN false
   	         ELSE  cronop.usato_per_fpv END 
   	       )  ,     -- 04.10.2022 Sofia Jira SIAC-8816
         cronop.cronop_data_approvazione_fattibilita,
	     cronop.cronop_data_approvazione_programma_def,
		 cronop.cronop_data_approvazione_programma_esec,
		 cronop.cronop_data_avvio_procedura,
		 cronop.cronop_data_aggiudicazione_lavori,
		 cronop.cronop_data_inizio_lavori,
		 cronop.cronop_data_fine_lavori,
		 cronop.cronop_giorni_durata,
		 cronop.cronop_data_collaudo,
	     cronop.gestione_quadro_economico,
         clock_timestamp(),
         loginOperazione||'@'||fasec.fase_bil_cronop_id::varchar,
         cronop.ente_proprietario_id
    from fase_bil_t_programmi fasep, fase_bil_t_cronop fasec,siac_t_cronop cronop
    where fasep.fase_bil_elab_id=faseBilElabId
    and   fasep.programma_new_id is not null
    and   fasep.fl_elab='S'
    and   fasec.fase_bil_elab_id=faseBilElabId
    and   fasec.programma_id=fasep.programma_id
    and   fasec.fl_elab='N'
    and   cronop.cronop_id=fasec.cronop_id
    and   fasep.data_cancellazione is null
    and   fasec.data_cancellazione is null
    and   cronop.data_cancellazione is null
    and   cronop.validita_fine is null;*/
   
    -- 16.05.2023 Sofia SIAC-8633 - cronop
    numeroCronop:=0;
    strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop].';
    
    insert into siac_t_cronop
    (
    	 cronop_code,
	     cronop_desc,
	     programma_id,
	     bil_id,
	     usato_per_fpv,
         cronop_data_approvazione_fattibilita,
	     cronop_data_approvazione_programma_def,
		 cronop_data_approvazione_programma_esec,
		 cronop_data_avvio_procedura,
		 cronop_data_aggiudicazione_lavori,
		 cronop_data_inizio_lavori,
		 cronop_data_fine_lavori,
		 cronop_giorni_durata,
		 cronop_data_collaudo,
	     gestione_quadro_economico,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
    )
    select
         cronop.cronop_code,
	     cronop.cronop_desc,
	     pNew.programma_id,
	     bilancioId,
   	       ( CASE WHEN tipoapertura=P_FASE  THEN false
   	         ELSE  cronop.usato_per_fpv END 
   	       )  ,
         cronop.cronop_data_approvazione_fattibilita,
	     cronop.cronop_data_approvazione_programma_def,
		 cronop.cronop_data_approvazione_programma_esec,
		 cronop.cronop_data_avvio_procedura,
		 cronop.cronop_data_aggiudicazione_lavori,
		 cronop.cronop_data_inizio_lavori,
		 cronop.cronop_data_fine_lavori,
		 cronop.cronop_giorni_durata,
		 cronop.cronop_data_collaudo,
	     cronop.gestione_quadro_economico,
         clock_timestamp(),
         loginOperazione||'@'||fasec.fase_bil_cronop_id::varchar,
         cronop.ente_proprietario_id
    from fase_bil_t_cronop fasec,siac_t_programma p, 
              siac_t_programma pNew, siac_d_programma_tipo tipo,siac_r_programma_stato rs,siac_d_programma_stato stato,
              siac_t_cronop cronop 
    where fasec.fase_bil_elab_id=faseBilElabId
    and     fasec.fl_elab='N'
    and     p.programma_id =fasec.programma_id 
    and     cronop.cronop_id =fasec.cronop_id 
    and     cronop.programma_id =p.programma_id
    and     tipo.ente_proprietario_id =p.ente_proprietario_id 
    and     tipo.programma_tipo_code =tipoApertura
    and     pNew.programma_tipo_id=tipo.programma_tipo_id 
    and     pNew.programma_code =p.programma_code 
    and     pNew.bil_id=bilancioId
    and     rs.programma_id =pNew.programma_id 
    and     stato.programma_stato_id =rs.programma_stato_id 
    and     stato.programma_stato_code!='AN'
    and     not exists 
    (
    select 1 
    from   siac_t_cronop cNew,siac_r_cronop_stato  rs_cronop,siac_d_cronop_stato  stato_cronop
    where  cNew.programma_id=pNew.programma_id 
    and       cNew.cronop_code=cronop.cronop_code 
    and       cNew.bil_id=pNew.bil_id
    and       rs_cronop.cronop_id=cNew.cronop_id 
    and       stato_cronop.cronop_stato_id =rs_cronop.cronop_stato_id 
    and       stato_cronop.cronop_stato_code !='AN'
    and       cNew.data_cancellazione is null 
    and       cNew.validita_fine is null
    and       rs_cronop.data_cancellazione is null 
    and       rs_cronop.validita_fine is null
   )
   and     fasec.data_cancellazione is null
   and     cronop.data_cancellazione is null 
   and     cronop.validita_fine is null
   and     p.data_cancellazione is null 
   and     p.validita_fine is null
   and     pNew.data_cancellazione is null 
   and     pNew.validita_fine is null
   and     rs.data_cancellazione is null 
   and     rs.validita_fine is null;
   GET DIAGNOSTICS numeroCronop = ROW_COUNT;

  if coalesce(numeroCronop,0)!=0 then

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop inseriti numero='||coalesce(numeroCronop,0)::varchar||'.';
	 codResult:=null;
	 insert into fase_bil_t_elaborazione_log
	 (fase_bil_elab_id,fase_bil_elab_log_operazione,
      validita_inizio, login_operazione, ente_proprietario_id
	 )
     values
     (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
     returning fase_bil_elab_log_id into codResult;
     if codResult is null then
     	raise exception ' Errore in inserimento LOG.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  - aggiornamento fase_bil_t_cronop.';
     codResult:=null;
     update fase_bil_t_cronop fase
     set    cronop_new_id=cronop.cronop_id,
               fl_elab='S'
     from   siac_t_cronop cronop
     where  fase.fase_bil_elab_id=faseBilElabId
     and       fase.fl_elab='N'
     and    cronop.ente_proprietario_id=enteProprietarioId
     and    cronop.bil_id=bilancioId -- 03.12.2021 Sofia SIAC-8879
     and    cronop.login_operazione like loginOperazione||'@%'
     and    substring(cronop.login_operazione from position ('@' in cronop.login_operazione)+1)::integer=fase.fase_bil_cronop_id
     and    fase.data_cancellazione is null
     and    cronop.data_cancellazione is null
     and    cronop.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
	      raise exception ' Il numero di aggiornamenti non corrisponde al numero di crono-programmi inseriti.';
     end if;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_stato].';
     -- siac_r_cronop_stato
     codResult:=null;
     insert into siac_r_cronop_stato
     (
    	cronop_id,
        cronop_stato_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            rs.cronop_stato_id,
            clock_timestamp(),
            loginOperazione,
            rs.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_stato rs
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rs.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;


     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_atto_amm].';
     -- siac_r_cronop_atto_amm
     codResult:=null;
     insert into siac_r_cronop_atto_amm
     (
    	cronop_id,
        attoamm_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select fase.cronop_new_id,
            ratto.attoamm_id,
            clock_timestamp(),
            loginOperazione,
            ratto.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_atto_amm ratto
   	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    ratto.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    ratto.data_cancellazione is null
     and    ratto.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
/*     if coalesce(codResult,0)!=coalesce(numeroCronop,0) then
      raise exception ' Il numero di stati inseriti non corrisponde al numero di crono-programmi inseriti.';
     end if;*/

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_attr].';

     -- siac_r_cronop_attr
     codResult:=null;
     insert into siac_r_cronop_attr
     (
    	cronop_id,
		attr_id,
	    boolean,
	    testo,
    	percentuale,
	    numerico,
    	tabella_id,
	    validita_inizio,
    	login_operazione,
	    ente_proprietario_id
     )
     select
        fase.cronop_new_id,
        rattr.attr_id,
	    rattr.boolean,
    	rattr.testo,
	    rattr.percentuale,
	    rattr.numerico,
    	rattr.tabella_id,
	    clock_timestamp(),
    	loginOperazione,
	    rattr.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_r_cronop_attr rattr
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    rattr.cronop_id=fase.cronop_id
     and    fase.data_cancellazione is null
     and    rattr.data_cancellazione is null
     and    rattr.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem].';
	 codResult:=null;
     -- siac_t_cronop_elem
     insert into siac_t_cronop_elem
     (
	    cronop_elem_code,
	    cronop_elem_code2,
	    cronop_elem_code3,
	    cronop_elem_desc,
	    cronop_elem_desc2,
	    cronop_id,
--	    cronop_elem_id_padre,
        cronop_elem_is_ava_amm,
	    elem_tipo_id,
	    ordine,
	    livello,
   	    login_operazione,
	    validita_inizio,
	    ente_proprietario_id
     )
     select
        celem.cronop_elem_code,
	    celem.cronop_elem_code2,
	    celem.cronop_elem_code3,
	    celem.cronop_elem_desc,
	    celem.cronop_elem_desc2,
        fase.cronop_new_id,
--        cronop_elem_id_padre,
	    celem.cronop_elem_is_ava_amm,
        tiponew.elem_tipo_id,
        celem.ordine,
	    celem.livello,
        loginOperazione||'@'||celem.cronop_elem_id::varchar,
        clock_timestamp(),
        celem.ente_proprietario_id
 	 from fase_bil_t_cronop fase,siac_t_cronop_elem celem,
          siac_d_bil_elem_tipo tipo, siac_d_bil_elem_tipo tiponew
 	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_id
     and    tipo.elem_tipo_id=celem.elem_tipo_id
     and    tiponew.ente_proprietario_id=tipo.ente_proprietario_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;






     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_class].';
	 codResult:=null;
	 -- siac_r_cronop_elem_class
     insert into siac_r_cronop_elem_class
     (
  	  	cronop_elem_id,
	    classif_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            c.classif_id,
            clock_timestamp(),
            loginOperazione,
            c.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_class r,siac_t_class c
	 where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    c.classif_id=r.classif_id
     and    c.data_cancellazione is null
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_r_cronop_elem_bil_elem].';
	 codResult:=null;
     -- siac_r_cronop_elem_bil_elem
     insert into siac_r_cronop_elem_bil_elem
     (
	    cronop_elem_id,
	    elem_id,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
     )
     select celem.cronop_elem_id,
            enew.elem_id,
            clock_timestamp(),
            loginOperazione,
            enew.ente_proprietario_id
     from  fase_bil_t_cronop fase,siac_t_cronop_elem celem,siac_r_cronop_elem_bil_elem r,
           siac_t_bil_elem e,siac_d_bil_elem_tipo tipo,
           siac_t_bil_elem enew,siac_d_bil_elem_tipo tiponew,
           siac_r_bil_elem_stato rs,siac_d_bil_elem_Stato stato
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    r.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    e.elem_id=r.elem_id
     and    tipo.elem_tipo_id=e.elem_tipo_id
     and    enew.bil_id=bilancioId
     and    enew.elem_code=e.elem_code
     and    enew.elem_code2=e.elem_code2
     and    enew.elem_code3=e.elem_code3
     and    tiponew.elem_tipo_id=enew.elem_tipo_id
     and    (case
              when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-UG' then tiponew.elem_tipo_code='CAP-UP'
    		  when tipoApertura=P_FASE and tipo.elem_tipo_code='CAP-EG' then tiponew.elem_tipo_code='CAP-EP'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-UP' then tiponew.elem_tipo_code='CAP-UG'
              when tipoApertura=G_FASE and tipo.elem_tipo_code='CAP-EP' then tiponew.elem_tipo_code='CAP-EG'
            end
            )
     and    rs.elem_id=enew.elem_id
     and    stato.elem_stato_id=rs.elem_stato_id
     and    stato.elem_stato_code!='AN'
     and    r.data_cancellazione is null
     and    r.validita_fine is null
     and    rs.data_cancellazione is null
     and    rs.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null
     and    e.data_cancellazione is null
     and    enew.data_cancellazione is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
	 raise notice '% numdaIns=%', strMessaggio,codResult;

     strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop  [siac_t_cronop_elem_det].';
     codResult:=null;
     -- siac_t_cronop_elem_det
     insert into siac_t_cronop_elem_det
     (
	    cronop_elem_det_desc,
	    cronop_elem_id,
	    cronop_elem_det_importo,
	    elem_det_tipo_id,
	    periodo_id,
	    anno_entrata,
        quadro_economico_id_padre,
	    quadro_economico_id_figlio,
	    quadro_economico_det_importo,
        login_operazione,
        validita_inizio,
        ente_proprietario_id
     )
     select
         det.cronop_elem_det_desc,
	     celem.cronop_elem_id,
	     det.cronop_elem_det_importo,
	     det.elem_det_tipo_id,
	     det.periodo_id,
	     det.anno_entrata,
         det.quadro_economico_id_padre,
	     det.quadro_economico_id_figlio,
	     det.quadro_economico_det_importo,
         loginOperazione,
         clock_timestamp(),
         det.ente_proprietario_id
     from fase_bil_t_cronop fase,siac_t_cronop_elem celem, siac_t_cronop_elem_det det
     where  fase.fase_bil_elab_id=faseBilElabId
     and    fase.fl_elab='S'
     and    fase.cronop_new_id is not null
     and    celem.cronop_id=fase.cronop_new_id
     and    celem.login_operazione like loginOperazione||'@%'
     and    det.cronop_elem_id=substring(celem.login_operazione from position('@' in celem.login_operazione)+1)::integer
     and    det.data_cancellazione is null
     and    det.validita_fine is null
     and    fase.data_cancellazione is null
     and    celem.data_cancellazione is null
     and    celem.validita_fine is null;
     GET DIAGNOSTICS codResult = ROW_COUNT;
     raise notice '% numdaIns=%', strMessaggio,codResult;
   end if;
  
   strMessaggio:='Inserimento dati cronoprogrammi da fase_bil_t_cronop - fine.';
   codResult:=null;
   insert into fase_bil_t_elaborazione_log
   (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
   )
   values
   (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
   returning fase_bil_elab_log_id into codResult;
   if codResult is null then
   	raise exception ' Errore in inserimento LOG.';
   end if;

 end if;

 --- inserimento collegamenti tra programma e siac_t_movgest_Ts [siac_r_movgest_ts_programma]
 --- inserimento collegamenti tra cronop    e siac_t_movgest_ts [siac_r_movgest_ts_cronop_elem]
 --  inserimento da effettuare solo per tipoApertura='G'
 --  quindi partendo da movimenti validi e programmi - cronop nuovi, riportare le relazioni da annoBilancioPrec
 --  convertendo gli id da annoPrec a annoBilancio
 -- 06.05.2019 Sofia siac-6255
-- if tipoApertura=G_FASE then -- tutto da rivedere
-- 06.02.2020 Sofia jira SIAC-7386 aggiunto par. non aggiornare tutti i collegamenti in caso di esecuzione da puntuale
-- 16.05.2023 Sofia SIAC-8633 - aggiungere controlli su inesistenza dei legami 
 if tipoApertura=G_FASE and ribalta_coll_mov=true then

  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inizio.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;

  -- inserimento legami aperti esistenti su impegni/accertamenti residui
  -- siac_r_movgest_ts_programma
  -- residui
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma residui.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
                query.programma_new_id,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
    from
    (
    with
    mov_res_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
               (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
               mov.movgest_tipo_id,
               ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
               siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
               (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
               mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
               siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   mov.movgest_anno::integer<annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code in ('D','N')
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_res_anno.movgest_ts_id,
               progr_anno.programma_id programma_new_id
    from mov_res_anno,
              mov_res_anno_prec, 
              progr progr_anno, 
              progr progr_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and      mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and      mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and      mov_res_anno.movgest_tipo_id=mov_res_anno_prec.movgest_tipo_id
    and      progr_anno_prec.programma_id=mov_res_anno_prec.programma_id
    and      progr_anno.bil_id=bilancioId
    and      progr_anno.programma_code=progr_anno_prec.programma_code
    and      not exists  -- 17.05.2023 Sofia SIAC-8633
     (
      select 1 from siac_r_movgest_ts_programma  rp 
      where rp.movgest_ts_id =mov_res_anno.movgest_ts_id 
      and      rp.programma_id=progr_anno.programma_id 
      and      rp.data_cancellazione  is null  
      and      rp.validita_fine is null 
     )
    ) query,fase_bil_t_programmi fase -- 29.05.2023 Sofia SIAC-8633 ribaltamento dei movimenti solo per i programmi effettivamente creati
    where     -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.programma_new_id=query.programma_new_id
    and     fase.programma_new_id is not NULL
    and     fase.data_cancellazione is null
    -- 29.05.2023 Sofia SIAC-8633
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- pluriennali
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma pluriennali.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
                query.programma_new_id,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
    from
    (
    with
    mov_pluri_anno as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
               ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
               mov.movgest_tipo_id,
               ts.movgest_ts_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
               siac_d_movgest_Ts_tipo tipo
    where mov.bil_id=bilancioId
    and   mov.movgest_anno::integer>=annoBilancio
    and   ts.movgest_id=mov.movgest_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    ),
    mov_pluri_anno_prec as
    (
    select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and     mov.movgest_anno::integer>=annoBilancio
    and     ts.movgest_id=mov.movgest_id
    and     r.movgest_ts_id=ts.movgest_ts_id
    and     rs.movgest_ts_id=ts.movgest_ts_id
    and     stato.movgest_stato_id=rs.movgest_stato_id
    and     stato.movgest_stato_code!='A'
    and     tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and     mov.data_cancellazione is null
    and     mov.validita_fine is null
    and     ts.data_cancellazione is null
    and     ts.validita_fine is null
    and     rs.data_cancellazione is null
    and     rs.validita_fine is null
    and     r.data_cancellazione is null
    and     r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_pluri_anno.movgest_ts_id,
               progr_anno.programma_id programma_new_id
    from mov_pluri_anno,
               mov_pluri_anno_prec, progr progr_anno_prec,
               progr progr_anno
    where mov_pluri_anno.movgest_anno=mov_pluri_anno_prec.movgest_anno
    and     mov_pluri_anno.movgest_numero=mov_pluri_anno_prec.movgest_numero
    and     mov_pluri_anno.movgest_subnumero=mov_pluri_anno_prec.movgest_subnumero
    and     mov_pluri_anno.movgest_tipo_id=mov_pluri_anno_prec.movgest_tipo_id
    and     progr_anno_prec.programma_id=mov_pluri_anno_prec.programma_id
    and     progr_anno.bil_id=bilancioId
    and     progr_anno.programma_code=progr_anno_prec.programma_code
    and      not exists  -- 17.05.2023 Sofia SIAC-8633
    (
     select 1 from siac_r_movgest_ts_programma  rp 
     where rp.movgest_ts_id =mov_pluri_anno.movgest_ts_id 
     and     rp.programma_id=progr_anno.programma_id 
     and     rp.data_cancellazione  is null  
     and     rp.validita_fine is null 
    )
    ) query,fase_bil_t_programmi fase -- 29.05.2023 Sofia SIAC-8633 ribaltamento dei movimenti solo per i programmi effettivamente creati
    where 
     -- 29.05.2023 Sofia SIAC-8633
                 fase.fase_bil_elab_id=faseBilElabId
    and     fase.programma_new_id=query.programma_new_id
    and     fase.programma_new_id is not NULL
    and     fase.data_cancellazione is null
     -- 29.05.2023 Sofia SIAC-8633
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  -- 30.07.2019 Sofia siac-6934
  -- riaccertati
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - inserimento siac_r_movgest_ts_programma riaccertati.';
  insert into siac_r_movgest_ts_programma
  (
  	movgest_ts_id,
    programma_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
    select query.movgest_ts_id,
                query.programma_new_id,
                clock_timestamp(),
                loginOperazione,
                enteProprietarioId
    from
    (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
                 ( case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
                 mov.movgest_tipo_id,
                 ts.movgest_ts_id
      from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                siac_d_movgest_Ts_tipo tipo,
                siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and   ts.movgest_id=mov.movgest_id
      and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
      and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and   rattr.movgest_ts_id=ts.movgest_ts_id
      and   rattr.attr_id=flagDaRiaccAttrId
      and   rattr.boolean='S'
      and   mov.data_cancellazione is null
      and   mov.validita_fine is null
      and   ts.data_cancellazione is null
      and   ts.validita_fine is null
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
    ),
    annoRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=annoRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
    select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
    from siac_r_movgest_ts_attr rattr
    where rattr.attr_id=numeroRiaccAttrId
    and   rattr.testo is not null
    and   rattr.testo!='null'
    and   coalesce(rattr.testo ,'')!=''
    and   rattr.data_cancellazione is null
    and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from   mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and     mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
    select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
           (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) movgest_subnumero,
           mov.movgest_tipo_id, r.programma_id
    from siac_t_movgest mov,siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
               siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_programma r
    where mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   r.movgest_ts_id=ts.movgest_ts_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipo.movgest_ts_tipo_code='T' -- non il legame ad un sub sugli attributi quindi associo solo i programmi del padre
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    ),
    progr as
    (
      select p.programma_id, p.programma_tipo_id, p.programma_code, p.bil_id
      from siac_t_programma p, siac_r_programma_stato rs,siac_d_programma_stato stato, siac_d_programma_tipo tipo
      where stato.ente_proprietario_id=enteProprietarioId
--      and   stato.programma_stato_code='VA'
      and   stato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
      and   rs.programma_stato_id=stato.programma_stato_id
      and   p.programma_id=rs.programma_id
      and   tipo.programma_tipo_id=p.programma_tipo_id
      and   tipo.programma_tipo_code=G_FASE
      and   rs.data_cancellazione is null
      and   rs.validita_fine is null
      and   p.data_cancellazione is null
      and   p.validita_fine is null
    )
    select mov_riacc_anno.movgest_ts_id,
               progr_anno.programma_id programma_new_id
    from mov_riacc_anno,
               mov_riacc_anno_prec, progr progr_anno_prec,
               progr progr_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and      mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and      mov_riacc_anno.movgest_tipo_id=mov_riacc_anno_prec.movgest_tipo_id
    and      progr_anno_prec.programma_id=mov_riacc_anno_prec.programma_id
    and      progr_anno.bil_id=bilancioId
    and      progr_anno.programma_code=progr_anno_prec.programma_code
    and      not exists  -- 17.05.2023 Sofia SIAC-8633
    (
     select 1 from siac_r_movgest_ts_programma  rp 
     where rp.movgest_ts_id =mov_riacc_anno.movgest_ts_id 
     and     rp.programma_id=progr_anno.programma_id 
     and     rp.data_cancellazione  is null  
     and     rp.validita_fine is null 
    )
    ) query,fase_bil_t_programmi fase -- 29.05.2023 Sofia SIAC-8633 ribaltamento dei movimenti solo per i programmi effettivamente creati
        -- 29.05.2023 Sofia SIAC-8633
   where  fase.fase_bil_elab_id=faseBilElabId
    and     fase.programma_new_id=query.programma_new_id
    and     fase.programma_new_id is not NULL
    and     fase.data_cancellazione is null
     -- 29.05.2023 Sofia SIAC-8633

  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_programma res.inserimenti =%', strMessaggio,codResult;
  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
              query.cronop_new_id,
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
                 mov.movgest_tipo_id,
                 ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                  (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
                   mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                 siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                 siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
                  cronop.cronop_code,
                  prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'
     and      pstato.programma_stato_code!='AN'      -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
                mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno, cronop cronop_anno_prec
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and     mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and     mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and     cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and     cronop_anno.bil_id=bilancioId
    and     cronop_anno.programma_code=cronop_anno_prec.programma_code
    and     cronop_anno.cronop_code=cronop_anno_prec.cronop_code
    and     not exists  -- 17.05.2023 Sofia SIAC-8633
    (
    select 1 
    from siac_r_movgest_ts_cronop_elem rc
    where rc.cronop_id=cronop_anno.cronop_id 
    and      rc.movgest_ts_id=mov_res_anno.movgest_ts_id 
    and      rc.data_cancellazione is null 
    and      rc.validita_fine is null 
    )
   ) query,fase_bil_t_cronop fase -- 29.05.2023 Sofia SIAC-8633
   where    -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
             query.cronop_new_id,
             clock_timestamp(),
             loginOperazione,
             enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
                 mov.movgest_tipo_id,
                 ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                  (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
                  mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code !='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
                  cronop.cronop_code,
                  prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
                siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'   -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'   -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
               mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and     mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and     mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and     cronop_anno_prec.cronop_id=mov_res_anno_prec.cronop_id
    and     cronop_anno.bil_id=bilancioId
    and     cronop_anno.programma_code=cronop_anno_prec.programma_code
    and     cronop_anno.cronop_code=cronop_anno_prec.cronop_code
    and     not exists  -- 17.05.2023 Sofia SIAC-8633
    (
    select 1 
    from siac_r_movgest_ts_cronop_elem rc
    where rc.cronop_id=cronop_anno.cronop_id 
    and      rc.movgest_ts_id=mov_res_anno.movgest_ts_id 
    and      rc.data_cancellazione is null 
    and      rc.validita_fine is null 
    )
   ) query, fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where     -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633

  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  --- 30.07.2019 Sofia siac-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
              query.cronop_new_id,
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
    with
    mov_anno as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
                 mov.movgest_tipo_id,
                 ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                 siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                 siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      tipo.movgest_ts_tipo_code='T'
      and      rattr.movgest_ts_id=ts.movgest_ts_id
      and      rattr.attr_id=flagDaRiaccAttrId
      and      rattr.boolean='S'
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
    ),
    annoRiacc as
    (
     select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
     from siac_r_movgest_ts_attr rattr
     where rattr.attr_id=annoRiaccAttrId
     and   rattr.testo is not null
     and   rattr.testo!='null'
     and   coalesce(rattr.testo ,'')!=''
     and   rattr.data_cancellazione is null
     and   rattr.validita_fine is null
    ),
    numeroRiacc as
    (
     select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
     from siac_r_movgest_ts_attr rattr
     where rattr.attr_id=numeroRiaccAttrId
     and   rattr.testo is not null
     and   rattr.testo!='null'
     and   coalesce(rattr.testo ,'')!=''
     and   rattr.data_cancellazione is null
     and   rattr.validita_fine is null
    )
    select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
    from mov_anno, annoRiacc, numeroRiacc
    where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
    and     mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
                  (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
                  mov.movgest_tipo_id, r.cronop_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                 siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                 siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code !='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop as
    (
     select  cronop.cronop_id, cronop.bil_id,
                  cronop.cronop_code,
                  prog.programma_id, prog.programma_code
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
                siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and       tipo.programma_tipo_code=G_FASE
     and       prog.programma_tipo_id=tipo.programma_tipo_id
     and       cronop.programma_id=prog.programma_id
     and       rs.cronop_id=cronop.cronop_id
     and       stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and       stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and       rsp.programma_id=prog.programma_id
     and       pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and       pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and       rs.data_cancellazione is null
     and       rs.validita_fine is null
     and       rsp.data_cancellazione is null
     and       rsp.validita_fine is null
     and       prog.data_cancellazione is null
     and       prog.validita_fine is null
     and       cronop.data_cancellazione is null
     and       cronop.validita_fine is null
    )
    select cronop_anno.cronop_id cronop_new_id,
           mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop cronop_anno_prec, cronop cronop_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_anno_prec.cronop_id=mov_riacc_anno_prec.cronop_id
    and   cronop_anno.bil_id=bilancioId
    and   cronop_anno.programma_code=cronop_anno_prec.programma_code
    and   cronop_anno.cronop_code=cronop_anno_prec.cronop_code
   ) query,  fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where
   not exists
   (select 1
    from siac_r_movgest_ts_cronop_elem r1
    where r1.movgest_ts_id=query.movgest_ts_id
    and   r1.cronop_id=query.cronop_new_id
    and   r1.cronop_elem_id is null
    and   r1.data_cancellazione is null
    and   r1.validita_fine is null
   )
   -- 29.05.2023 Sofia SIAC-8633
    and     fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  residui.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	          query.cronop_new_id,
              query.cronop_elem_new_id,
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
                 mov.movgest_tipo_id,
                 ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
                 mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer<annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is not null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
                 cronop.cronop_code,
                 prog.programma_id, prog.programma_code,
                 celem.cronop_elem_id,
                 coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
                 coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
                 coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
                 coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
                 coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
                 coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
                 coalesce(det.periodo_id,0)           periodo_id,
                 coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
                 coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
                 coalesce(det.anno_entrata,'')        anno_entrata,
                 coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
               siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      celem.cronop_id=cronop.cronop_id
     and      det.cronop_elem_id=celem.cronop_elem_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
     and      celem.data_cancellazione is null
     and      celem.validita_fine is null
     and      det.data_cancellazione is null
     and      det.validita_fine is null
    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
                cronop_elem_anno.cronop_id cronop_new_id,
                mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and     mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and     mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and     cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and     cronop_elem_anno.bil_id=bilancioId
    and     cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and     cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and     cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and     cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and     cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and     cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and     cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and     cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and     cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and     cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and     cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and     cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and     cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists -- 17.05.2023 Sofia SIAC-8633
    (
	 select 1 
	 from siac_r_movgest_ts_cronop_elem r
  	 where r.movgest_ts_id=mov_res_anno.movgest_ts_id
  	 and     r.cronop_id=cronop_elem_anno.cronop_id
  	 and     r.cronop_elem_id=cronop_elem_anno.cronop_elem_id
  	 and     r.data_cancellazione is null 
  	 and     r.validita_fine is null
    )
   ) query,   fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where   -- 29.05.2023 Sofia SIAC-8633
               fase.fase_bil_elab_id=faseBilElabId
   and     fase.fl_elab='S'
   and     fase.cronop_new_id is not null
   and     fase.cronop_new_id=query.cronop_new_id
   and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;

  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  pluriennali.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	          query.cronop_new_id,
              query.cronop_elem_new_id,
              clock_timestamp(),
              loginOperazione,
              enteProprietarioId
  from
  (
    with
    mov_res_anno as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                  (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
                  mov.movgest_tipo_id,
                  ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                siac_d_movgest_Ts_tipo tipo
      where mov.bil_id=bilancioId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
    ),
    mov_res_anno_prec as
    (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
                 mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                 siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                 siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      mov.movgest_anno::integer>=annoBilancio
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is not null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code!='A'
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
                  cronop.cronop_code,
                  prog.programma_id, prog.programma_code,
                  celem.cronop_elem_id,
                  coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
                  coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
                  coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
                  coalesce(celem.elem_tipo_id,0)      elem_tipo_id,
                  coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
                  coalesce(celem.cronop_elem_desc2,'')  cronop_elem_desc2,
                  coalesce(det.periodo_id,0)           periodo_id,
                  coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
                  coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
                  coalesce(det.anno_entrata,'')        anno_entrata,
                  coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
               siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
               siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      celem.cronop_id=cronop.cronop_id
     and      det.cronop_elem_id=celem.cronop_elem_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
--     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
     and      celem.data_cancellazione is null
     and      celem.validita_fine is null
     and      det.data_cancellazione is null
     and      det.validita_fine is null
    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
               cronop_elem_anno.cronop_id cronop_new_id,
               mov_res_anno.movgest_ts_id
    from mov_res_anno, mov_res_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_res_anno.movgest_anno=mov_res_anno_prec.movgest_anno
    and   mov_res_anno.movgest_numero=mov_res_anno_prec.movgest_numero
    and   mov_res_anno.movgest_subnumero=mov_res_anno_prec.movgest_subnumero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_res_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=c.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists -- 17.05.2023 Sofia SIAC-8633
    (
	 select 1 
	 from siac_r_movgest_ts_cronop_elem r
  	 where r.movgest_ts_id=mov_res_anno.movgest_ts_id
  	 and     r.cronop_id=cronop_elem_anno.cronop_id
  	 and     r.cronop_elem_id=cronop_elem_anno.cronop_elem_id
  	 and     r.data_cancellazione is null 
  	 and     r.validita_fine is null
    )
   ) query,  fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where 
    -- 29.05.2023 Sofia SIAC-8633
                fase.fase_bil_elab_id=faseBilElabId
    and     fase.fl_elab='S'
    and     fase.cronop_new_id is not null
    and     fase.cronop_new_id=query.cronop_new_id
    and     fase.data_cancellazione  is null 
    -- 29.05.2023 Sofia SIAC-8633
   
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem res.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;


  --- 31.07.2019 Sofia SIAC-6934
  codResult:=null;
  strMessaggio:='Ribaltamento legame tra impegni e programmi-cronop dettaglio - inserimento siac_r_movgest_ts_cronop_elem  riaccertati.';
  -- siac_r_movgest_ts_cronop_elem
  insert into siac_r_movgest_ts_cronop_elem
  (
  	movgest_ts_id,
    cronop_id,
    cronop_elem_id,
    validita_inizio,
    login_operazione,
    ente_proprietario_id
  )
  (
  select query.movgest_ts_id,
  	         query.cronop_new_id,
             query.cronop_elem_new_id,
             clock_timestamp(),
             loginOperazione,
             enteProprietarioId
  from
  (
    with
    mov_riacc_anno as
    (
     with
     mov_anno as
     (
      select mov.movgest_anno::integer,mov.movgest_numero::INTEGER,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
                 mov.movgest_tipo_id,
                 ts.movgest_ts_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                 siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                 siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_attr rattr
      where mov.bil_id=bilancioId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      tipo.movgest_ts_tipo_code='T'
      and      rattr.movgest_ts_id=ts.movgest_ts_id
      and      rattr.attr_id=flagDaRiaccAttrId
      and      rattr.boolean='S'
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      rattr.data_cancellazione is null
      and      rattr.validita_fine is null
     ),
     annoRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer annoRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=annoRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     ),
     numeroRiacc as
     (
      select rattr.movgest_ts_id, rattr.testo::integer numeroRiacc
      from siac_r_movgest_ts_attr rattr
      where rattr.attr_id=numeroRiaccAttrId
      and   rattr.testo is not null
      and   rattr.testo!='null'
      and   coalesce(rattr.testo ,'')!=''
      and   rattr.data_cancellazione is null
      and   rattr.validita_fine is null
     )
     select  mov_anno.*, annoRiacc.annoRiacc, numeroRiacc.numeroRiacc
     from   mov_anno, annoRiacc, numeroRiacc
     where mov_anno.movgest_ts_id=annoRiacc.movgest_ts_id
     and     mov_anno.movgest_ts_id=numeroRiacc.movgest_ts_id
    ),
    mov_riacc_anno_prec as
    (
      select mov.movgest_anno::integer movgest_anno,mov.movgest_numero::INTEGER movgest_numero,
                 (case when tipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end)  movgest_subnumero,
                  mov.movgest_tipo_id, r.cronop_elem_id
      from siac_t_movgest mov,siac_d_movgest_tipo tipomov,
                 siac_t_movgest_ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
                 siac_d_movgest_Ts_tipo tipo,siac_r_movgest_ts_cronop_elem r
      where mov.bil_id=bilancioPrecId
      and      tipomov.movgest_tipo_id=mov.movgest_tipo_id
      and      tipomov.movgest_tipo_code='I'
      and      ts.movgest_id=mov.movgest_id
      and      r.movgest_ts_id=ts.movgest_ts_id
      and      r.cronop_elem_id is not null
      and      rs.movgest_ts_id=ts.movgest_ts_id
      and      stato.movgest_stato_id=rs.movgest_stato_id
      and      stato.movgest_stato_code in ('D','N')
      and      tipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
      and      mov.data_cancellazione is null
      and      mov.validita_fine is null
      and      ts.data_cancellazione is null
      and      ts.validita_fine is null
      and      rs.data_cancellazione is null
      and      rs.validita_fine is null
      and      r.data_cancellazione is null
      and      r.validita_fine is null
    ),
    cronop_elem as
    (
     select  cronop.cronop_id, cronop.bil_id,
             cronop.cronop_code,
             prog.programma_id, prog.programma_code,
             celem.cronop_elem_id,
             coalesce(celem.cronop_elem_code,'')  cronop_elem_code,
             coalesce(celem.cronop_elem_code2,'') cronop_elem_code2,
             coalesce(celem.cronop_elem_code3,'') cronop_elem_code3,
             coalesce(celem.elem_tipo_id,0)       elem_tipo_id,
             coalesce(celem.cronop_elem_desc,'')  cronop_elem_desc,
             coalesce(celem.cronop_elem_desc2,'') cronop_elem_desc2,
             coalesce(det.periodo_id,0)           periodo_id,
             coalesce(det.cronop_elem_det_importo,0) cronop_elem_det_importo,
             coalesce(det.cronop_elem_det_desc,'') cronop_elem_det_desc,
             coalesce(det.anno_entrata,'')        anno_entrata,
             coalesce(det.elem_det_tipo_id,0)     elem_det_tipo_id
     from siac_t_cronop cronop,siac_r_cronop_stato rs,siac_d_cronop_stato stato,
                siac_t_programma prog,siac_r_programma_stato rsp,siac_d_programma_stato pstato, siac_d_programma_tipo tipo,
                siac_t_cronop_elem celem,siac_t_cronop_elem_det det
   	 where  tipo.ente_proprietario_id=enteProprietarioId
     and      tipo.programma_tipo_code=G_FASE
     and      prog.programma_tipo_id=tipo.programma_tipo_id
     and      cronop.programma_id=prog.programma_id
     and      celem.cronop_id=cronop.cronop_id
     and      det.cronop_elem_id=celem.cronop_elem_id
     and      rs.cronop_id=cronop.cronop_id
     and      stato.cronop_stato_id=rs.cronop_stato_id
---     and    stato.cronop_stato_code='VA' -- 06.08.2019 Sofia siac-6934
     and      stato.cronop_stato_code!='AN' -- 06.08.2019 Sofia siac-6934
     and      rsp.programma_id=prog.programma_id
     and      pstato.programma_stato_id=rsp.programma_stato_id
--     and    pstato.programma_stato_code='VA'  -- 06.08.2019 Sofia siac-6934
     and      pstato.programma_stato_code!='AN'  -- 06.08.2019 Sofia siac-6934
     and      rs.data_cancellazione is null
     and      rs.validita_fine is null
     and      rsp.data_cancellazione is null
     and      rsp.validita_fine is null
     and      prog.data_cancellazione is null
     and      prog.validita_fine is null
     and      cronop.data_cancellazione is null
     and      cronop.validita_fine is null
     and      celem.data_cancellazione is null
     and      celem.validita_fine is null
     and      det.data_cancellazione is null
     and      det.validita_fine is null
    )
    select cronop_elem_anno.cronop_elem_id cronop_elem_new_id,
               cronop_elem_anno.cronop_id cronop_new_id,
               mov_riacc_anno.movgest_ts_id
    from mov_riacc_anno, mov_riacc_anno_prec, cronop_elem cronop_elem_anno_prec, cronop_elem cronop_elem_anno
    where mov_riacc_anno.annoRiacc=mov_riacc_anno_prec.movgest_anno
    and   mov_riacc_anno.numeroRiacc=mov_riacc_anno_prec.movgest_numero
    and   cronop_elem_anno_prec.cronop_elem_id=mov_riacc_anno_prec.cronop_elem_id
    and   cronop_elem_anno.bil_id=bilancioId
    and   cronop_elem_anno.programma_code=cronop_elem_anno_prec.programma_code
    and   cronop_elem_anno.cronop_code=cronop_elem_anno_prec.cronop_code
    and   cronop_elem_anno.cronop_elem_code=cronop_elem_anno_prec.cronop_elem_code
    and   cronop_elem_anno.cronop_elem_code2=cronop_elem_anno_prec.cronop_elem_code2
    and   cronop_elem_anno.cronop_elem_code3=cronop_elem_anno_prec.cronop_elem_code3
    and   cronop_elem_anno.elem_tipo_id=cronop_elem_anno_prec.elem_tipo_id
    and   cronop_elem_anno.cronop_elem_desc=cronop_elem_anno_prec.cronop_elem_desc
    and   cronop_elem_anno.cronop_elem_desc2=cronop_elem_anno_prec.cronop_elem_desc2
    and   cronop_elem_anno.periodo_id=cronop_elem_anno_prec.periodo_id
    and   cronop_elem_anno.cronop_elem_det_importo=cronop_elem_anno_prec.cronop_elem_det_importo
    and   cronop_elem_anno.cronop_elem_det_desc=cronop_elem_anno_prec.cronop_elem_det_desc
    and   cronop_elem_anno.anno_entrata=cronop_elem_anno_prec.anno_entrata
    and   cronop_elem_anno.elem_det_tipo_id=cronop_elem_anno_prec.elem_det_tipo_id
    and   exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
    and not exists
    (
    	select 1
        from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
        where rc.cronop_elem_id=cronop_elem_anno_prec.cronop_elem_id
        and   c.classif_id=rc.classif_id
        and   tipo.classif_tipo_id=c.classif_tipo_id
        and   not exists
        (
        	select 1
            from siac_r_cronop_elem_class rc1,siac_t_class c1
            where rc1.cronop_elem_id=cronop_elem_anno.cronop_elem_id
            and   c1.classif_id=rc1.classif_id
            and   c1.classif_tipo_id=tipo.classif_tipo_id
            and   c1.classif_code=c.classif_code
            and   rc1.data_cancellazione is null
            and   rc1.validita_fine is null
        )
        and   rc.data_cancellazione is null
        and   rc.validita_fine is null
    )
   ) query,  fase_bil_t_cronop fase  -- 29.05.2023 Sofia SIAC-8633
   where not exists
   (
   select 1
   from siac_r_movgest_ts_cronop_elem r1
   where r1.movgest_ts_id=query.movgest_ts_id
   and   r1.cronop_id=query.cronop_new_id
   and   r1.cronop_elem_id=query.cronop_elem_new_id
   and   r1.data_cancellazione is null
   and   r1.validita_fine is null
   )
   -- 29.05.2023 Sofia SIAC-8633
  and     fase.fase_bil_elab_id=faseBilElabId
  and     fase.fl_elab='S'
  and     fase.cronop_new_id is not null
  and     fase.cronop_new_id=query.cronop_elem_new_id
  and     fase.data_cancellazione  is null 
   -- 29.05.2023 Sofia SIAC-8633
  );
  GET DIAGNOSTICS codResult = ROW_COUNT;
  raise notice '% siac_r_movgest_ts_cronop_elem riacc.inserimenti =%', strMessaggio,codResult;

  strMessaggio:=strMessaggio||' Inserite num.=%'||coalesce(codResult,0)||' righe.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
   validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
     raise exception ' Errore in inserimento LOG.';
  end if;



  strMessaggio:='Ribaltamento legame tra movimenti di gestione e programmi-cronop - fine.';
  codResult:=null;
  insert into fase_bil_t_elaborazione_log
  (fase_bil_elab_id,fase_bil_elab_log_operazione,
    validita_inizio, login_operazione, ente_proprietario_id
  )
  values
  (faseBilElabId,strMessaggioFinale||'-'||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
  if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
  end if;
 end if;
 -- 06.05.2019 Sofia siac-6255



 strMessaggio:='Inserimento LOG.';
 codResult:=null;
 insert into fase_bil_t_elaborazione_log
 (fase_bil_elab_id,fase_bil_elab_log_operazione,
  validita_inizio, login_operazione, ente_proprietario_id
 )
 values
 (faseBilElabId,strMessaggioFinale||'-FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
  returning fase_bil_elab_log_id into codResult;
 if codResult is null then
  	raise exception ' Errore in inserimento LOG.';
 end if;


 if coalesce(codiceRisultato,0)=0 then
   	messaggioRisultato:=strMessaggioFinale||'- FINE.';
 else messaggioRisultato:=strMessaggioFinale||strMessaggio;
 end if;

 return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1000) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi_elabora
(
integer, 
integer, 
integer, 
varchar, 
varchar, 
timestamp without time zone, 
boolean, 
OUT integer, 
OUT  varchar
) owner to siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoapertura varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  ribalta_coll_mov boolean DEFAULT false, -- 17.05.2023 Sofia SIAC-8633
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
   strMessaggio       			VARCHAR(1500)	:='';
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;

   faseOp                       varchar(50):=null;
   strRec record;

   APE_GEST_PROGRAMMI    	    CONSTANT varchar:='APE_GEST_PROGRAMMI';
   P_FASE						CONSTANT varchar:='P';
   G_FASE					    CONSTANT varchar:='G';
   -- 25.05.2023 Sofia Jira SIAC-8633
   E_FASE					    CONSTANT varchar:='E';
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Apertura Programmi-Cronoprogrammi di tipo '||tipoApertura||' per annoBilancio='||annoBilancio::varchar||'.';

   strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PROGRAMMI||' IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
   and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
   and   fase.fase_bil_elab_esito like 'IN%'
   and   fase.data_cancellazione is null
   and   fase.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;
   if codResult is not null then
   	raise exception ' Esistenza fase in corso.';
   end if;


    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
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

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
--     if faseOp is null or faseOp not in (P_FASE,G_FASE) then 25.05.2023 Sofia Jira SIAC-8633
     -- 25.05.2023 Sofia Jira SIAC-8633
     if faseOp is null or faseOp not in (P_FASE,G_FASE,E_FASE) then
      	raise exception ' Il bilancio deve essere in fase % o % o %.',P_FASE,G_FASE,E_FASE;
     end if;

     strMessaggio:='Verifica coerenza tipo di apertura programmi-fase di bilancio di corrente.';
    --	 if tipoApertura!=faseOp then  25.05.2023 Sofia Jira SIAC-8633
    -- 25.05.2023 Sofia Jira SIAC-8633
	 if ( ( tipoApertura=P_FASE and tipoApertura!=faseOp ) or (tipoApertura=G_FASE and faseOp not in (G_FASE,E_FASE)) ) then 
     	raise exception ' Tipo di apertura % non consentita in fase di bilancio %.', tipoApertura,faseOp;
     end if;

 	 strMessaggio:='Inizio Popola programmi-cronop da elaborare.';
     select * into strRec
     from fnc_fasi_bil_gest_apertura_programmi_popola
     (
      faseBilElabId,
      enteproprietarioid,
      annobilancio,
      tipoApertura,
      loginoperazione,
	  dataelaborazione
     );
     if strRec.codiceRisultato!=0 then
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;

     if codiceRisultato=0 then
	     strMessaggio:='Inizio Elabora programmi-cronop.';
    	 select * into strRec
	     from fnc_fasi_bil_gest_apertura_programmi_elabora
    	 (
	      faseBilElabId,
    	  enteproprietarioid,
	      annobilancio,
          tipoApertura,
          loginoperazione,
          dataelaborazione,
          ribalta_coll_mov -- 17.05.2023 Sofia SIAC-8633          
         );
         if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;

     end if;


     if codiceRisultato=0 and faseBilElabId is not null then
	   strMessaggio:=' Chiusura fase_bil_t_elaborazione OK.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||'TERMINATA CON SUCCESSO.'
       where fase_bil_elab_id=faseBilElabId;

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

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
       insert into fase_bil_t_elaborazione_log
	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
        validita_inizio, login_operazione, ente_proprietario_id
	   )
	   values
       (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	   returning fase_bil_elab_log_id into codResult;

	   if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	   end if;

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||'TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      end if;

     end if;
     
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente';
	  	fasebilelabidret:=coalesce(faseBilElabId,0);
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio;
     end if;

	 RETURN;
EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_fasi_bil_gest_apertura_programmi
(
integer, 
integer, 
varchar, 
varchar, 
timestamp without time zone, 
boolean, 
OUT integer,
OUT integer, 
OUT  varchar
) owner to siac;


DROP FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi 
(
  annobilancio integer,
  enteproprietarioid integer,
  tipoAllineamento varchar, 
  loginoperazione varchar,
  dataelaborazione timestamp,
  out fasebilelabidret integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
  DECLARE
   strMessaggio       			VARCHAR(1500)	:='';
   strMessaggioErr       			VARCHAR(1500)	:='';
   strMessaggiofinale 			VARCHAR(1500)	:='';
   codResult              		INTEGER  		:=NULL;
   dataInizioVal 				timestamp		:=NULL;
   faseBilElabId 		        integer:=null;
   faseBilElabPGId          integer:=null;
   faseBilElabGPId          integer:=null;
   bilancioId                   integer:=null;
   periodoId                    integer:=null;
   tipoOperazioni varchar(50):=null;
  
   faseOp                       varchar(50):=null;
   strRec record;

   APE_GEST_PROGRAMMI    	    CONSTANT varchar:='APE_GEST_ALL_PROGRAMMI';
   P_FASE						CONSTANT varchar:='P';
   E_FASE					    CONSTANT varchar:='E';
   
  BEGIN

   messaggioRisultato:='';
   codicerisultato:=0;
   faseBilElabIdRet:=0;
   dataInizioVal:= clock_timestamp();

   strmessaggiofinale:='Allineamento '||coalesce(tipoAllineamento,' ')||' Programmi-Cronoprogrammi per annoBilancio='||annoBilancio::varchar||'.';
   raise notice '%',strmessaggiofinale;
   strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_PROGRAMMI||' IN CORSO.';
   select 1 into codResult
   from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
   and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
   and   fase.fase_bil_elab_esito like 'IN%'
   and   fase.data_cancellazione is null
   and   fase.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;
   if codResult is not null then
   	raise exception ' Esistenza fase in corso.';
   end if;

   -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
   -- da g anno     a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti 
   -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
   --     'gp|GP|PG'
   strMessaggio:='Verifica tipo allineamenti da eseguire per  '||APE_GEST_PROGRAMMI||'.';
   select tipo.fase_bil_elab_tipo_param  into tipoOperazioni
   from fase_bil_d_elaborazione_tipo  tipo 
   where tipo.ente_proprietario_id =enteProprietarioId 
   and      tipo.fase_bil_elab_tipo_code =APE_GEST_PROGRAMMI
   and      tipo.data_cancellazione  is null 
   and      tipo.validita_fine is null;
   if tipoOperazioni is null then 
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Nessun tipo di allineamento predisposto in esecuzione.';
	   return;
   end if;


    
    -- inserimento fase_bil_t_elaborazione
	strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
     fase_bil_elab_tipo_id,
     ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 P ANNO IN CORSO.',
            tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
     from fase_bil_d_elaborazione_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null)
     returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
     	raise exception ' Inserimento non effettuato.';
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

     strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
     select bil.bil_id , per.periodo_id into strict bilancioId, periodoId
     from siac_t_bil bil, siac_t_periodo per
     where bil.ente_proprietario_id=enteProprietarioId
     and   per.periodo_id=bil.periodo_id
     and   per.anno::INTEGER=annoBilancio
     and   bil.data_cancellazione is null
     and   per.data_cancellazione is null;


	 strMessaggio:='Verifica fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null or faseOp not in (P_FASE,E_FASE) then
      	raise notice ' Il bilancio deve essere in fase % o %.',P_FASE,E_FASE;
	--	strMessaggio:='Allineamento Programmi-Cronoprogrammi gp -  da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	    strMessaggio:=strMessaggio||' Il bilancio deve essere in fase '||P_FASE||' o '||E_FASE||'. Chiusura fase_bil_t_elaborazione KO.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      
       messaggioRisultato := strMessaggioFinale||strMessaggio||' Fase di bilancio non ammessa.';
	   return;
     end if;
    
    -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%gp%' then 
	 -- da g anno-1  a  p anno gp   - PREVISIONE E ES. PROVVISORIO no ribaltamento collegamenti movimenti
     strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
     if tipoOperazioni like '%gp%'  then
      raise notice '%',strmessaggio;
      strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
 	
	  select * into strRec
      from fnc_fasi_bil_gest_apertura_programmi_popola
      (
       faseBilElabId,
       enteproprietarioid,
       annobilancio,
       'P',
       loginoperazione,
	   dataelaborazione
      );
      if strRec.codiceRisultato!=0 then
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
      end if;
     
      if codiceRisultato = 0 then
          strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
          strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	 select * into strRec
	     from fnc_fasi_bil_gest_apertura_programmi_elabora
    	 (
	      faseBilElabId,
    	  enteproprietarioid,
	      annobilancio,
          'P',
          loginoperazione,
          dataelaborazione,
          false -- no colleg. movimenti
         );
         if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
         end if;
      end if;
     end if;
    
      if codiceRisultato=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='OK',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 a P ANNO TERMINATA CON SUCCESSO.'
       where fase_bil_elab_id=faseBilElabId;

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

	 else
      if codiceRisultato!=0 and faseBilElabId is not null then
       strMessaggio:='Allineamento Programmi-Cronoprogrammi gp - da gestione '||(annoBilancio-1)::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
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

       update fase_bil_t_elaborazione
       set fase_bil_elab_esito='KO',
           fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' gp - DA G ANNO-1 A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggio)
       where fase_bil_elab_id=faseBilElabId;
      end if;

     end if;
    end if;
   
     -- da g anno   a  p anno GP   - ES.PROVVISORIO no ribaltamento collegamenti con movimenti
     -- da modificare fnc interne tutto nello stesso annoBilancio
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%GP%'  and
        tipoOperazioni like '%GP%' and codiceRisultato=0 and faseOp=E_FASE  then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';

       insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabGPId;

    
        if faseBilElabGPId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabGPId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.'; 
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabGPId,
           enteproprietarioid,
           annobilancio,
           'GP',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
       
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabGPId,
    	    enteproprietarioid,
	        annobilancio,
            'GP',
            loginoperazione,
            dataelaborazione,
            false -- no colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if; 
      end if;
     end if;
    
     if faseBilElabGPId is not null then
      strMessaggio:='Allineamento Programmi-Cronoprogrammi GP - da gestione '||annoBilancio::varchar||' a previsione annoBilancio='||annoBilancio::varchar||'.';
      if codiceRisultato=0 then 
     	   strMessaggio:=strMessaggio||'  Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO a P ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabGPId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabGPId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabGPId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;
	
    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' GP - DA G ANNO A P ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabGPId;
      end if;
     end if;
    
    -- da p anno     a g anno  PG   - ES. PROVVISORIO  sempre e solo dei mancati con ribaltamento dei collegamenti con movimenti
    if coalesce(tipoAllineamento,'')='' or tipoAllineamento like '%PG%' and
        tipoOperazioni like '%PG%'  and codiceRisultato=0 and faseOp=E_FASE then 
        strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
        raise notice '%',strmessaggio;
        strMessaggio:=strMessaggio||' Inserimento fase elaborazione [fase_bil_t_elaborazione].';
       
        insert into fase_bil_t_elaborazione
        (fase_bil_elab_esito, fase_bil_elab_esito_msg,
         fase_bil_elab_tipo_id,
         ente_proprietario_id,validita_inizio, login_operazione)
        (select 'IN','ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO IN CORSO.',
                     tipo.fase_bil_elab_tipo_id,enteProprietarioId, dataInizioVal, loginOperazione
         from fase_bil_d_elaborazione_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
         and   tipo.fase_bil_elab_tipo_code=APE_GEST_PROGRAMMI
         and   tipo.data_cancellazione is null
         and   tipo.validita_fine is null)
         returning fase_bil_elab_id into faseBilElabPGId;
        
        if faseBilElabPGId is null then 
         strMessaggio:=strMessaggio||' Impossibile determinare id.Elab.';
         codiceRisultato:=-1;
        else 
         codResult:=null;
	     insert into fase_bil_t_elaborazione_log
         (fase_bil_elab_id,fase_bil_elab_log_operazione,
         validita_inizio, login_operazione, ente_proprietario_id
         )
         values
         (faseBilElabPGId,strMessaggio||' INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
         returning fase_bil_elab_log_id into codResult;
         if codResult is null then
    	   raise exception ' Errore in inserimento LOG.';
         end if;
        
         strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
         strMessaggio:=strMessaggio||' Inizio Popola programmi-cronop da elaborare.';
         select * into strRec
         from fnc_fasi_bil_gest_apertura_programmi_popola
         (
           faseBilElabPGId,
           enteproprietarioid,
           annobilancio,
           'G',
           loginoperazione,
	       dataelaborazione
          );
          if strRec.codiceRisultato!=0 then
            strMessaggio:=strRec.messaggioRisultato;
            codiceRisultato:=strRec.codiceRisultato;
         end if;  
         if codiceRisultato = 0 then
           strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
           strMessaggio:=strMessaggio||' Inizio Elabora programmi-cronop.';
    	   select * into strRec
 	       from fnc_fasi_bil_gest_apertura_programmi_elabora
    	   (
	        faseBilElabPGId,
    	    enteproprietarioid,
	        annobilancio,
            'G',
            loginoperazione,
            dataelaborazione,
            true -- si colleg movimenti
           );
           if strRec.codiceRisultato!=0 then
            strMessaggioErr:=strRec.messaggioRisultato;
            strMessaggio:=strMessaggioErr;
            codiceRisultato:=strRec.codiceRisultato;
           end if;
         end if;
       end if; 
     end if;
    
 	 
     if faseBilElabPGId is not null then
     strMessaggio:='Allineamento Programmi-Cronoprogrammi PG - da previsione '||annoBilancio::varchar||' a gestione annoBilancio='||annoBilancio::varchar||'.';
     if codiceRisultato=0 then 
           
     	   strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione OK.';
           insert into fase_bil_t_elaborazione_log
	       (fase_bil_elab_id,fase_bil_elab_log_operazione,
             validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
           (faseBilElabPGId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	   raise exception ' Errore in inserimento LOG.';
    	   end if;

           update fase_bil_t_elaborazione
           set fase_bil_elab_esito='OK',
             fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO a G ANNO TERMINATA CON SUCCESSO.'
           where fase_bil_elab_id=faseBilElabPGId;

           insert into fase_bil_t_elaborazione_log
     	   (fase_bil_elab_id,fase_bil_elab_log_operazione,
            validita_inizio, login_operazione, ente_proprietario_id
	       )
	       values
          (faseBilElabPGId,strMessaggio||' FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	       returning fase_bil_elab_log_id into codResult;

	       if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	       end if;
     else 
	   		strMessaggio:=strMessaggio||' Chiusura fase_bil_t_elaborazione KO.';
		    insert into fase_bil_t_elaborazione_log
		    (fase_bil_elab_id,fase_bil_elab_log_operazione,
		        validita_inizio, login_operazione, ente_proprietario_id
	  	   )
		   values
    	   (faseBilElabPGId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		   returning fase_bil_elab_log_id into codResult;

		   if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
		   end if;

    	   update fase_bil_t_elaborazione
	       set fase_bil_elab_esito='KO',
    	       fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_PROGRAMMI||' PG - DA P ANNO A G ANNO TERMINATA CON ERRORE.'||upper (strMessaggioErr)
       		where fase_bil_elab_id=faseBilElabPGId;
      end if;
    end if;

 
	 if  codiceRisultato=0 then
	  	 messaggioRisultato := strMessaggioFinale||' Operazione terminata correttamente';
	  	 if faseBilElabId is not null then 
 	  	 	faseBilElabIdRet:=faseBilElabId;
 	  	 else 
 	  	    if faseBilElabPGId is not null then 
   	   	     faseBilElabIdRet:=faseBilElabPGId;
   	   	    else 
   	   	     if faseBilElabGPId is not null then 
   	   	      faseBilElabIdRet:=faseBilElabGPId;
   	   	     end if;
   	   	    end if; 
   	   	 end if; 
	 else
  	  	 messaggioRisultato := strMessaggioFinale||strMessaggio||strMessaggioErr;
     end if;

	 RETURN;
EXCEPTION
  WHEN raise_exception THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'ERRORE: . '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN no_data_found THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Nessun elemento trovato. '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  WHEN OTHERS THEN
    RAISE notice '% % Errore DB % %',strmessaggiofinale,strmessaggio,SQLSTATE, substring(upper(SQLERRM) FROM 1 FOR 1500);
    messaggiorisultato:=strmessaggiofinale||strmessaggio||'Errore OTHERS DB '||SQLSTATE||' '||substring(upper(SQLERRM) FROM 1 FOR 1500) ;
    codicerisultato:=-1;
    RETURN;
  END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter FUNCTION siac.fnc_fasi_bil_gest_allinea_programmi
(
integer, 
integer, 
varchar,
varchar, 
timestamp without time zone, 
OUT integer,
OUT integer, 
OUT  varchar
) owner to siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    faseBilElabId     integer:=null;

    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';


BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Fase Bilancio di apertura='||faseBilancio||'.';

    if not (stepPartenza=99 or stepPartenza>=1) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=1 99.';
        codiceRisultato:=-1;
    end if;

    -- STEP 1 - capitoli di uscita eseguiro per stepPartenza 1, 99
    if stepPartenza=1 or stepPartenza=99 then
 	 strMessaggio:='Capitolo di uscita.';
     select * into strRec
     from fnc_fasi_bil_gest_apertura
     (annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      faseBilancio,
      checkGest,
      impostaImporti,
      enteProprietarioId,
      loginOperazione,
      dataElaborazione
     );
     if strRec.codiceRisultato=0 then
      	faseBilElabId:=strRec.faseBilElabIdRet;
     else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;
   end if;

   -- STEP 2 - capitoli di entrata eseguiro per stepPartenza >=2
   if codiceRisultato=0 and stepPartenza>=2 then
    	strMessaggio:='Capitolo di entrata.';
    	select * into strRec
	    from fnc_fasi_bil_gest_apertura
    	(annobilancio,
	     E_STR,
    	 CAP_EP_STR,
	     CAP_EG_STR,
	     faseBilancio,
	     checkGest,
     	 impostaImporti,
	     enteProprietarioId,
    	 loginOperazione,
	     dataElaborazione
    	);
        if strRec.codiceRisultato=0 then
      		faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else
    	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;


    -- STEP 3 -- popolamento dei vincoli di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
		strMessaggio:='Ribaltamento vincoli.';
    	if faseBilancio = 'E' then
	    	select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('GEST-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		else
			select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('PREV-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		end if;

	    if strRec.codiceRisultato=0 then
            faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;


    end if;

    -- STEP 4 -- popolamento dei programmi-cronop di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
--    	if faseBilancio = 'G' then -- 17.05.2023 Sofia SIAC-8633 ribaltamento dei progetti-cronop sia in esercizio provvisorio che in gestione def
                                                  -- sempre da previsione corrente riportando sempre solo progetti non esistenti in gestione con relativi cronop
                                                  -- e cronop non esistenti di progetti anche esistenti
            strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di gestione da previsione corrente.';
        	select * into strRec
        	from fnc_fasi_bil_gest_apertura_programmi
	             (
				  annoBilancio,
				  enteProprietarioId,
				  'G',
				  loginOperazione,
				  dataElaborazione
                 );
            if  strRec.codiceRisultato!=0 then
            	strMessaggio:=strRec.messaggioRisultato;
        		codiceRisultato:=strRec.codiceRisultato;
            end if;
--        end if;
    end if;

   -- 08.04.2022 Sofia SIAC-8017
    -- STEP 6 -- popolamento dei programmi-cronoprogrammi di previsione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di previsione da gestione precedente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
		(
	     enteProprietarioId,
	     annoBilancio,   -- iniziale
	     annoBilancio-1, -- finale
	     loginOperazione,
	     dataelaborazione
	    );
--       if strRec.codiceRisultato!=0 then
--       	strMessaggio:=strRec.messaggioRisultato;
  --      codiceRisultato:=strRec.codiceRisultato;
    --   end if;
    end if;
    -- 08.04.2022 Sofia SIAC-8017
   
    if codiceRisultato=0 then
	   	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
	    faseBilElabIdRet:=faseBilElabId;
	else
	  	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

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

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  integer,
  varchar,
  integer,
  boolean,
  boolean,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER TO siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_prev_approva_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;
    faseBilElabId     integer:=null;

    prevAggImpRec record;
    prevCapRec record;
    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';

    GESTIONE_FASE               CONSTANT varchar:='G';

BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;

	strMessaggioFinale:='Approvazione bilancio di previsione per Anno bilancio='||annoBilancio::varchar||'.';

    if not (stepPartenza=99 or stepPartenza>=2) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=2 99.';
        codiceRisultato:=-1;
    end if;

    if faseBilancio is null or faseBilancio!=GESTIONE_FASE then
    	raise exception 'Fase Bilancio da indicare %.',GESTIONE_FASE;
    end if;
    -- STEP 1 -- CAPITOLI USCITA
    -- ESEGUITO SOLO SE ESEGUITI TUTTI
    if codiceRisultato=0 and stepPartenza=99 then
  	 strMessaggio:='Capitoli uscita.';

     select * into prevCapRec
     from fnc_fasi_bil_prev_approva
	 (annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      faseBilancio,
      true,--checkGest
      true,--impostaImporti
	  enteProprietarioId,
	  loginoperazione,
 	  dataelaborazione
     );

     if prevCapRec.codiceRisultato=0 then
    	faseBilElabId:=prevCapRec.faseBilElabIdRet;
     else
        strMessaggio:=prevCapRec.messaggioRisultato;
        codiceRisultato:=prevCapRec.codiceRisultato;
     end if;
    end if;

    -- STEP 2 -- CAPITOLI DI ENTRATA
    -- STEP DI RIPARTENZA
    if codiceRisultato=0  and stepPartenza>=2 then
		strMessaggio:='Capitoli entrata.';
        select * into prevCapRec
        from fnc_fasi_bil_prev_approva
		(annobilancio,
		 E_STR,
		 CAP_EP_STR,
		 CAP_EG_STR,
         faseBilancio,
		 true,--checkGest
         true,--impostaImporti
		 enteproprietarioid,
		 loginoperazione,
 	     dataelaborazione);
        if prevCapRec.codiceRisultato=0 then
    		faseBilElabId:=prevCapRec.faseBilElabIdRet;
        else
	        strMessaggio:=prevCapRec.messaggioRisultato;
    	    codiceRisultato:=prevCapRec.codiceRisultato;
        end if;
    end if;


    -- STEP 3 -- popolamento dei vincoli di gestione da previsione
    if codiceRisultato=0 and stepPartenza>=2 then
	    select * into strRec
        from fnc_fasi_bil_gest_ribaltamento_vincoli
        ('PREV-GEST',
         annoBilancio,
         enteProprietarioid,
         loginOperazione,
         dataElaborazione );

         if strRec.codiceRisultato=0 then
            faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;


	-- STEP 5 -- popolamento dei programmi-cronoprogrammi di gestione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di gestione da previsione corrente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_programmi
             (
			  annoBilancio,
			  enteProprietarioId,
			  'G',
			  loginOperazione,
			  dataElaborazione,
			  true -- 17.05.2023 Sofia SIAC-8633 in approvazione deve sempre riportare i collegamenti con i movimenti 
             );
       if strRec.codiceRisultato!=0 then
       	strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
       end if;
    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

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


ALTER FUNCTION siac.fnc_fasi_bil_prev_approva_all
(
  integer,
  varchar,
  integer,
  boolean,
  boolean,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER TO siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_acc_elabora (
  enteproprietarioid integer,
  annobilancio integer,
  fasebilelabid integer,
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
	movgGestTsIdPadre integer:=null;

    movGestRec        record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	ACC_MOVGEST_TIPO CONSTANT varchar:='A';
  	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-EG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_ACC_RES    CONSTANT varchar:='APE_GEST_ACC_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';
    U_MOV_GEST_DET_TIPO  CONSTANT varchar:='U';

    -- 17.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

	strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento accertamenti  residui  da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

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
    strMessaggio:='Verifica esistenza in fase_bil_t_gest_apertura_acc di movimenti da generare.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_acc].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_acc_id) into maxId
        from fase_bil_t_gest_apertura_acc fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

	-- 12.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_acc per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_acc fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_acc_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

	codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_acc dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_acc fase
 	where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
	and   fase.validita_fine is null
    and   fase.fl_elab='N'
    and   fase.movgest_orig_id is not null
    and   fase.movgest_orig_ts_id is not null;
    if codResult is null then
    	 raise exception ' Nessun movimento presente.';
    end if;

     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
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

     -- per A
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||ACC_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
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

     -- 17.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 17.02.2017 Sofia HD-INC000001535447

	 -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
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


     strMessaggio:='Inizio ciclo per generazione accertamenti.';
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

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_acc_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_acc fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_acc_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
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
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Accertamento [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
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
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
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
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo accertamento.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subaccertamento movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';

        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subaccertamento movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

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
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di accertamento padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
          ts.siope_tipo_debito_id,
		  ts.siope_assenza_motivazione_id


          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO,U_MOV_GEST_DET_TIPO)
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
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
--          and   atto.data_cancellazione is null 17.02.2017 Sofia HD-INC000001535447
--          and   atto.validita_fine is null
         );



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

        raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

		-- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         	strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;
        -- 17.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        /*if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;*/

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

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
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;


       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */


       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia sistemazione gestione quote per escludere quelle incassate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=sub.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        -- SIAC-8551 Sofia - inizio 
        and not exists 
        (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=det1.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
        )
     	-- SIAC-8551 Sofia - fine        		    	   
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
        ;
        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       /** spostato sotto
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; **/
      
      -- 19.04.2023 SIAC-TASK-21
      -- siac_r_mutuo_movgest_ts
      if codResult is null then
       strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_mutuo_movgest_ts].';
      	insert into siac_r_mutuo_movgest_ts  
      	(
      		movgest_ts_id,
      		mutuo_id,
      		mutuo_movgest_ts_importo_iniziale,
      		mutuo_movgest_ts_importo_finale,
      		validita_inizio,
      		ente_proprietario_id ,
      		login_operazione,
      		login_creazione,
      		login_modifica
      	)
      	select  movGestTsIdRet,
      	             r.mutuo_id,
      	             det.movgest_ts_Det_importo,
      	             det.movgest_ts_Det_importo,
      	             dataInizioVal,
		             enteProprietarioId,
          		     loginOperazione,
          		     loginOperazione,
          		     loginOperazione
      	from siac_r_mutuo_movgest_ts r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato,
      	           siac_t_movgest_ts_det det,siac_d_movgest_ts_det_tipo tipo 
      	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
      	and     mutuo.mutuo_id=r.mutuo_id 
      	and     stato.mutuo_stato_id=mutuo.mutuo_stato_id 
      	and     stato.mutuo_stato_code!='A'
      	and     det.movgest_ts_id=movGestTsIdRet
      	and     tipo.movgest_ts_det_tipo_id =det.movgest_ts_det_tipo_id 
      	and     tipo.movgest_ts_det_tipo_code='I'
      	and     mutuo.data_cancellazione is null 
      	and     mutuo.validita_fine is null
      	and     r.data_cancellazione is null 
      	and     r.validita_fine is null;
        
		select 1  into codResult
        from siac_r_mutuo_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_mutuo_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
      
      end if;
     
	   -- 03.05.2019 Sofia siac-6255
       -- siac_r_movgest_ts_programma
       if codResult is null then
	   	--if faseOp=G_FASE then 17.05.2023 Sofia SIAC-8633
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
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
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                      siac_t_programma pnew,siac_d_programma_tipo tipo,
                      siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and     prog.programma_id=r.programma_id
            and     tipo.ente_proprietario_id=prog.ente_proprietario_id
            and     tipo.programma_tipo_code='G'
            and     pnew.programma_tipo_id=tipo.programma_tipo_id
            and     pnew.bil_id=bilancioId
            and     pnew.programma_code=prog.programma_code
            and     rs.programma_id=pnew.programma_id
            and     stato.programma_stato_id=rs.programma_stato_id
--            and     stato.programma_stato_code='VA'      17.05.2023 Sofia SIAC-8633
            and     stato.programma_stato_code!='AN'  -- 17.05.2023 Sofia SIAC-8633           
            and     prog.data_cancellazione is null
            and     prog.validita_fine is null
            and     r.data_cancellazione is null
            and     r.validita_fine is null
            and     pnew.data_cancellazione is null
            and     pnew.validita_fine is null
            and     rs.data_cancellazione is null
            and     rs.validita_fine is null
           );
        --end if;
       end if;

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_acc per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


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
/*
         -- siac_r_causale_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_causale_movgest_ts.';
         delete from siac_r_causale_movgest_ts where movgest_ts_id=movGestTsIdRet;*/

         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

 		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
	     
         -- 19.04.2023 Sofia SIAC-TASK-21
         -- siac_r_mutuo_movgest_ts
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_mutuo_movgest_ts.';
         delete from siac_r_mutuo_movgest_ts   where movgest_ts_id=movGestTsIdRet;
        
         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
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
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_acc per scarto.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento accertamento/subaccertamento residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;


       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
       	    -- 12.01.2017 Sofia sistemazione gestione quote per escludere quote incassate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        	-- SIAC-8551 Sofia - inizio  SIAC-8896 Sofia
--	        and not exists 
--    	    (
--        	  select 1
--	          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
--    	      where r.subdoc_id=r.subdoc_id 
--        	  and   p.provc_id=r.provc_id 
--	          and   p.provc_anno::integer=(annoBilancio-1)
--    	      and   p.data_cancellazione is null 
--        	  and   p.validita_fine  is null 
--	          and   r.data_cancellazione is null 
--    	      and   r.validita_fine is null 
--        	)
     		-- SIAC-8551 Sofia - fine      	     SIAC-8896 Sofia	   
            -- SIAC-8896 Sofia - inizio        		    	  
   	        and not exists 
    	    (
        	  select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
    	      where rp.subdoc_id=r.subdoc_id 
        	  and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
    	      and   p.data_cancellazione is null 
        	  and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
    	      and   rp.validita_fine is null 
        	)
            -- SIAC-8896 Sofia - fine
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
			and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        	-- SIAC-8551 Sofia - inizio  SIAC-8896
--    	    and not exists 
--	        (
--        	  select 1
--	          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
--    	      where r.subdoc_id=r.subdoc_id 
--		      and   p.provc_id=r.provc_id 
--        	  and   p.provc_anno::integer=(annoBilancio-1)
--	          and   p.data_cancellazione is null 
--    	      and   p.validita_fine  is null 
--	          and   r.data_cancellazione is null 
--    	      and   r.validita_fine is null 
--	        )
        	-- SIAC-8551 Sofia - fine    SIAC-8896
        	-- SIAC-8896 Sofia - inizio 
    	    and not exists 
	        (
        	  select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
    	      where rp.subdoc_id=r.subdoc_id 
		      and   p.provc_id=rp.provc_id 
        	  and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
    	      and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
    	      and   rp.validita_fine is null 
	        )
        	-- SIAC-8896 Sofia - fine            	   	    	   
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_acc per fine elaborazione.';
      	update fase_bil_t_gest_apertura_acc fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_acc_id=movGestRec.fase_bil_gest_ape_acc_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


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



     strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='IN-2',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_ACC_RES||' IN CORSO IN-2.Elabora Acc.'
     where fase_bil_elab_id=faseBilElabId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_acc_elabora 
(
  integer,
  integer,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out varchar)
OWNER TO siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp
(
 enteproprietarioid integer, 
 annobilancio integer, 
 tipoelab character varying, 
 fasebilelabid integer, 
 minid integer, 
 maxid integer, 
 loginoperazione character varying, 
 dataelaborazione timestamp without time zone, 
 OUT codicerisultato integer, 
 OUT messaggiorisultato character varying
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
	movgGestTsIdPadre integer:=null;

    movGestRec        record;
    aggProgressivi    record;

    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';

	CAP_UG_TIPO      CONSTANT varchar:='CAP-UG';

    MOVGEST_TS_T_TIPO CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO CONSTANT varchar:='S';

    A_MOV_GEST_STATO  CONSTANT varchar:='A';
    APE_GEST_LIQ_RES  CONSTANT varchar:='APE_GEST_LIQ_RES';

    APE_GEST_IMP_RES  CONSTANT varchar:='APE_GEST_IMP_RES';

    A_MOV_GEST_DET_TIPO  CONSTANT varchar:='A';
    I_MOV_GEST_DET_TIPO  CONSTANT varchar:='I';

	-- 15.02.2017 Sofia SIAC-4425
	FRAZIONABILE_ATTR CONSTANT varchar:='flagFrazionabile';
    flagFrazAttrId integer:=null;

    -- 15.02.2017 Sofia HD-INC000001535447
    ATTO_AMM_FIT_TIPO  CONSTANT varchar:='SPR';
    ATTO_AMM_FIT_OGG CONSTANT varchar:='Passaggio residuo.';
    ATTO_AMM_FIT_STATO CONSTANT VARCHAR:='DEFINITIVO';
    attoAmmFittizioId integer:=null;
	attoAmmNumeroFittizio  VARCHAR(10):='9'||annoBilancio::varchar||'99';


	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;



    dataInizioVal:= clock_timestamp();

    if tipoElab=APE_GEST_LIQ_RES then
 	 strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui per ribaltamento liquidazioni res da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    else
     strMessaggioFinale:='Apertura bilancio gestione.Ribaltamento movimenti  residui da Gestione precedente. Anno bilancio='||annoBilancio::varchar
                         ||'.Elabora  minId='||coalesce(minId::varchar,' ')||' maxId='||coalesce(maxId::varchar,' ')
                         ||'. Fase Elaborazione Id='||faseBilElabId||'.';
    end if;

     raise notice 'strMessaggioFinale %',strMessaggioFinale;

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
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;

    if coalesce(minId,0)=0 or coalesce(maxId,0)=0 then
        strMessaggio:='Calcolo min, max Id da elaborare in [fase_bil_t_gest_apertura_liq_imp].';
    	minId:=1;

        select max(fase.fase_bil_gest_ape_liq_imp_id) into maxId
        from fase_bil_t_gest_apertura_liq_imp fase
	    where fase.fase_bil_elab_id=faseBilElabId
    	and   fase.data_cancellazione is null
	    and   fase.validita_fine is null
        and   fase.fl_elab='N';
        if coalesce(maxId ,0)=0 then
        	raise exception ' Impossibile determinare il maxId';
        end if;

    end if;

    -- 08.11.2019 Sofia SIAC-7145 - inizio
    strMessaggio:='Aggiornamento movimenti da creare in fase_bil_t_gest_apertura_liq_imp per esclusione importi a zero.';
    update fase_bil_t_gest_apertura_liq_imp fase
    set  scarto_code='IMP',
         scarto_desc='Importo a residuo pari a zero',
         fl_elab='X'
    where Fase.fase_bil_elab_id=faseBilElabId
    and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
    and   fase.fl_elab='N'
    and   fase.imp_importo=0
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null;

    codResult:=null;
    strMessaggio:='Verifica esistenza movimenti da creare in fase_bil_t_gest_apertura_liq_imp dopo esclusione importi a zero.';
    select 1 into codResult
    from fase_bil_t_gest_apertura_liq_imp fase
    where fase.fase_bil_elab_id=faseBilElabId
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   fase.fl_elab='N';
    if codResult is null then
      raise exception ' Nessun impegno da creare.';
    end if;
    -- 08.11.2019 Sofia SIAC-7145 - fine


     strMessaggio:='Lettura id identificativo per tipo capitolo='||CAP_UG_TIPO||'.';
	 select tipo.elem_tipo_id into strict tipoCapitoloGestId
     from siac_d_bil_elem_tipo tipo
     where tipo.elem_tipo_code=CAP_UG_TIPO
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

     -- per I
     strMessaggio:='Lettura id identificativo per tipoMovGestImp='||IMP_MOVGEST_TIPO||'.';
     select tipo.movgest_tipo_id into strict tipoMovGestId
     from siac_d_movgest_tipo tipo
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
     and   tipo.data_cancellazione is null
     and   tipo.validita_fine is null;


     -- 15.02.2017 Sofia HD-INC000001535447
     strMessaggio:='Lettura id identificativo atto amministrativo fittizio per passaggio residui.';
	 select a.attoamm_id into attoAmmFittizioId
     from siac_d_atto_amm_tipo tipo, siac_t_atto_amm a
     where tipo.ente_proprietario_id=enteProprietarioId
     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
     and   a.attoamm_tipo_id=tipo.attoamm_tipo_id
     and   a.attoamm_anno::integer=annoBilancio
     and   a.attoamm_numero=attoAmmNumeroFittizio::integer
     and   a.data_cancellazione is null
     and   a.validita_fine is null;

     if attoAmmFittizioId is null then
        strMessaggio:='Inserimento atto amministrativo fittizio per passaggio residui.';
     	insert into siac_t_atto_amm
        ( attoamm_anno,
          attoamm_numero,
          attoamm_oggetto,
          attoamm_tipo_id,
          validita_inizio,
          login_operazione,
          ente_proprietario_id
        )
        (select
          annoBilancio::varchar,
          attoAmmNumeroFittizio::integer,
          ATTO_AMM_FIT_OGG,
		  tipo.attoamm_tipo_id,
          dataInizioVal,
          loginOperazione,
          enteProprietarioId
         from siac_d_atto_amm_tipo tipo
         where tipo.ente_proprietario_id=enteProprietarioId
	     and   tipo.attoamm_tipo_code=ATTO_AMM_FIT_TIPO
        )
        returning attoamm_id into attoAmmFittizioId;

        if attoAmmFittizioId is null then
        	raise exception 'Inserimento non effettuato.';
        end if;

        codResult:=null;
        strMessaggio:='Inserimento stato atto amministrativo fittizio per passaggio residui.';
        insert into siac_r_atto_amm_stato
        (attoamm_id,
         attoamm_stato_id,
         validita_inizio,
         login_operazione,
         ente_proprietario_id
        )
        (select  attoAmmFittizioId,
                 stato.attoamm_stato_id,
        		 dataInizioVal,
         		 loginOperazione,
		         enteProprietarioId
         from siac_d_atto_amm_stato stato
         where stato.ente_proprietario_id=enteProprietarioId
         and   stato.attoamm_stato_code=ATTO_AMM_FIT_STATO
         )
         returning att_attoamm_stato_id into codResult;
         if codResult is null then
         	raise exception 'Inserimento non effettuato.';
         end if;
     end if;
     -- 15.02.2017 Sofia HD-INC000001535447

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

	 -- 15.02.2017 Sofia SIAC-4425
     strMessaggio:='Lettura identificativo per flagFrazAttrCode='||FRAZIONABILE_ATTR||'.';
   	 select attr.attr_id into strict flagFrazAttrId
     from siac_t_attr attr
     where attr.ente_proprietario_id=enteProprietarioId
     and   attr.attr_code=FRAZIONABILE_ATTR
     and   attr.data_cancellazione is null
     and   attr.validita_fine is null;


     -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
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


     strMessaggio:='Inizio ciclo per generazione impegni.';
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

     raise notice 'Prima di inizio ciclo';
     for movGestRec in
     (select  fase.fase_bil_gest_ape_liq_imp_id,
	   		  fase.movgest_ts_tipo,
		      fase.movgest_orig_id,
	          fase.movgest_orig_ts_id,
		      fase.elem_orig_id,
              fase.elem_id,
              fase.elem_orig_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
              fase.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	          fase.imp_importo
      from  fase_bil_t_gest_apertura_liq_imp fase
      where fase.fase_bil_elab_id=faseBilElabId
      and   fase.fase_bil_gest_ape_liq_imp_id between minId and maxId
      and   fase.fl_elab='N'
      and   fase.data_cancellazione is null
      and   fase.validita_fine is null
/*      and   exists -- x test siac-6255
      (
      select 1
      from siac_r_movgest_ts_programma r
      where r.movgest_ts_id=fase.movgest_orig_ts_id
      and   r.data_cancellazione is null
      and   r.validita_fine is null
      ) */
      order by fase.movgest_ts_tipo desc,fase.movgest_orig_id,
	           fase.movgest_orig_ts_id
     )
     loop

     	movGestTsIdRet:=null;
        movGestIdRet:=null;
        movgGestTsIdPadre:=null;
        codResult:=null;




         strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.';
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
		 if movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
      	  strMessaggio:=strMessaggio||'Inserimento Impegno [siac_t_movgest].';

          raise notice 'strMessaggio %',strMessaggio;
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
	       parere_finanziario_login_operazione
		   )
          (select
           m.movgest_anno,
		   m.movgest_numero,
		   m.movgest_desc,
		   m.movgest_tipo_id,
		   bilancioId,
		   dataInizioVal,
	       enteProprietarioId,
	       loginOperazione,
	       m.parere_finanziario,
	       m.parere_finanziario_data_modifica,
	       m.parere_finanziario_login_operazione
           from siac_t_movgest m
           where m.movgest_id=movGestRec.movgest_orig_id
          )
          returning movgest_id into movGestIdRet;
          if movGestIdRet is null then
            strMessaggioTemp:=strMessaggio;
            codResult:=-1;
          end if;

		  raise notice 'dopo inserimento siac_t_movgest T movGestIdRet=%',movGestIdRet;
		  raise notice 'dopo inserimento siac_t_movgest T strMessaggioTemp=%',strMessaggioTemp;

	      if codResult is null then
          	  strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Inserimento relazione elemento di bilancio [siac_r_movgest_bil_elem].';
	          insert into siac_r_movgest_bil_elem
    	      (movgest_id,
	    	   elem_id,
               elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   movGestRec.elem_id,
               movGestRec.elem_det_comp_tipo_id, -- 14.05.2020 Sofia Jira SIAC-7593
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
      else

        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo impegno.';

          raise notice 'strMessaggio %',strMessaggio;
		select mov.movgest_id into movGestIdRet
        from siac_t_movgest mov, siac_t_movgest movprec
        where movprec.movgest_id=movGestRec.movgest_orig_id
        and   mov.bil_id=bilancioId
        and   mov.movgest_tipo_id=tipoMovGestId
        and   mov.movgest_anno=movprec.movgest_anno
        and   mov.movgest_numero=movprec.movgest_numero
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   movprec.data_cancellazione is null
        and   movprec.validita_fine is null;

        if movGestIdRet is null then
	        codResult:=-1;
            strMessaggioTemp:=strMessaggio;
        end if;

        raise notice 'dopo lettura siac_t_movgest T per inserimento subimpegno movGestIdRet=%',movGestIdRet;

        if codResult is null then

         	 strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'.Lettura identificativo siac_t_movgest_ts movgGestTsIdPadre.';
			strMessaggioTemp:=strMessaggio;
        	select ts.movgest_ts_id into movgGestTsIdPadre
	        from siac_t_movgest_ts ts
    	    where ts.movgest_id=movGestIdRet
	        and   ts.movgest_ts_tipo_id=tipoMovGestTsTId
    	    and   ts.data_cancellazione is null
        	and   ts.validita_fine is null;

			raise notice 'dopo lettura siac_t_movgest_ts T per inserimento subimpegno movgGestTsIdPadre=%',movgGestTsIdPadre;

        end if;

        raise notice 'dopo lettura siac_t_movgest movGestIdRet=%',movGestIdRet;
        raise notice 'dopo lettura siac_t_movgest strMessaggioTemp=%',strMessaggioTemp;
      end if;

      -- inserimento TS sia T che S
      if codResult is null then
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'Inserimento [siac_t_movgest_ts].';

		raise notice 'strMessaggio=% ',strMessaggio;

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
		  siope_tipo_debito_id ,
  		  siope_assenza_motivazione_id
        )
        ( select
          ts.movgest_ts_code,
          ts.movgest_ts_desc,
          movGestIdRet,    -- inserito se I, per SUB ricavato
          ts.movgest_ts_tipo_id,
          movgGestTsIdPadre, -- da ricavare dal TS T di impegno padre
          ts.movgest_ts_scadenza_data,
          ts.ordine,
          ts.livello,
--          dataEmissione,
          ts.validita_inizio, -- i residui devono mantenere la loro data di emissione originale
          enteProprietarioId,
          loginOperazione,
          loginOperazione,
		  ts.siope_tipo_debito_id ,
  		  ts.siope_assenza_motivazione_id
          from siac_t_movgest_ts ts
          where ts.movgest_ts_id=movGestRec.movgest_orig_ts_id
         )
        returning movgest_ts_id into  movGestTsIdRet;
        if movGestTsIdRet is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        end if;
       end if;

       raise notice 'dopo inserimento siac_t_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

       -- siac_r_movgest_ts_stato
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                     ' [siac_t_movgest_ts_det].';
        raise notice ' inserimento siac_t_movgest_ts_det movGestTsIdRet=% movGestRec.movgest_orig_ts_id=%', movGestTsIdRet,movGestRec.movgest_orig_ts_id;

        insert into siac_t_movgest_ts_det
        ( movgest_ts_id,
          movgest_ts_det_tipo_id,
	      movgest_ts_det_importo,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        (  select
           movGestTsIdRet,
           tipo.movgest_ts_det_tipo_id,
           movGestRec.imp_importo,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_d_movgest_ts_det_tipo tipo
          where  tipo.ente_proprietario_id=enteProprietarioId
          and    tipo.movgest_ts_det_tipo_code in (A_MOV_GEST_DET_TIPO,I_MOV_GEST_DET_TIPO)
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
   	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

        select 1 into codResult
        from siac_r_movgest_class det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_class movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
         else codResult:=null;
         end if;
       end if;

       -- siac_r_movgest_ts_attr
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

		select 1 into codResult
        from siac_r_movgest_ts_attr det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;

        raise notice 'dopo inserimento siac_r_movgest_ts_attr movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_atto_amm
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

       /* select 1 into codResult
        from siac_r_movgest_ts_atto_amm det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*/

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

       -- raise notice 'dopo inserimento siac_r_movgest_ts_atto_amm movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        -- 15.02.2017 Sofia HD-INC000001535447 inserimento relazione con atto amministrativo fittizio
        if codResult is not null then
        	codResult:=null;
            strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_movgest_ts_atto_amm]. Inserimento atto amm. fittizio.';
        	insert into siac_r_movgest_ts_atto_amm
            (
             movgest_ts_id,
		     attoamm_id,
			 validita_inizio,
			 login_operazione,
			 ente_proprietario_id
            )
            values
            (
             movGestTsIdRet,
             attoAmmFittizioId,
             dataInizioVal,
	         loginOperazione,
             enteProprietarioId
            )
            returning movgest_atto_amm_id into codResult;

            if codResult is null then
       	 		codResult:=-1;
	         strMessaggioTemp:=strMessaggio;
    	    else codResult:=null;
        	end if;
        end if;

       end if;

       -- siac_r_movgest_ts_sog
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

        raise notice 'dopo inserimento siac_r_movgest_ts_sog movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;


        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_movgest_ts_sogclasse
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
--          and   classe.data_cancellazione is null
--          and   classe.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
         );

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
        raise notice 'dopo inserimento siac_r_movgest_ts_sogclasse movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

      
       -- 19.04.2023 SIAC-TASK-21
      -- siac_r_mutuo_movgest_ts
      if codResult is null then
       strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_mutuo_movgest_ts].';
      	insert into siac_r_mutuo_movgest_ts  
      	(
      		movgest_ts_id,
      		mutuo_id,
      		mutuo_movgest_ts_importo_iniziale,
      		mutuo_movgest_ts_importo_finale,
      		validita_inizio,
      		ente_proprietario_id ,
      		login_operazione,
      		login_creazione,
      		login_modifica
      	)
      	select  movGestTsIdRet,
      	             r.mutuo_id,
      	             det.movgest_ts_det_importo,
      	             det.movgest_ts_det_importo,
      	             dataInizioVal,
		             enteProprietarioId,
          		     loginOperazione,
          		     loginOperazione,
          		     loginOperazione
      	from siac_r_mutuo_movgest_ts r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato,
      	           siac_t_movgest_ts_det det,siac_d_movgest_Ts_det_tipo tipo 
      	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
      	and      det.movgest_ts_id=movGestTsIdRet
      	and      tipo.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id 
      	and      tipo.movgest_ts_det_tipo_code='I'
      	and      mutuo.mutuo_id=r.mutuo_id 
      	and      stato.mutuo_stato_id=mutuo.mutuo_stato_id 
      	and      stato.mutuo_stato_code!='A'
      	and      mutuo.data_cancellazione is null 
      	and      mutuo.validita_fine is null
      	and      r.data_cancellazione is null 
      	and      r.validita_fine is null;
        
		select 1  into codResult
        from siac_r_mutuo_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_mutuo_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
      
      end if;
     
       -- siac_r_movgest_ts_programma
       if codResult is null then
--	   	if faseOp=G_FASE then -- 17.05.2023 Sofia SIAC-8633 
          strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
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
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
--            and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN'			-- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );

		   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
            and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );

           strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                         ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          ( movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
		         siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew,siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.bil_id=bilancioId
			and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null
           );
--        end if; ---- 17.05.2023 Sofia SIAC-8633
        end if;


       /*if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
        raise notice 'dopo inserimento siac_r_movgest_ts_programma movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

	   -- 16.03.2023 Sofia SIAC-TASK-#44
	   -- siac_r_mutuo_voce_movgest						   


       -- inserire il resto dei record legati al TS
       -- verificare quali sono da ribaltare e verificare se usare

       -- siac_r_giustificativo_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
        raise notice 'dopo inserimento siac_r_giustificativo_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/


       -- siac_r_cartacont_det_movgest_ts
       /* Non si ribalta in seguito ad indicazioni di Annalina
        if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
        raise notice 'dopo inserimento siac_r_cartacont_det_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; **/

       -- siac_r_causale_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
        raise notice 'dopo inserimento siac_r_causale_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if; */

       -- siac_r_fondo_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
        raise notice 'dopo inserimento siac_r_fondo_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_richiesta_econ_movgest
       /* cassa-economale da non ribaltare come da indicazioni di Irene
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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
        raise notice 'dopo inserimento siac_r_richiesta_econ_movgest movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;*/

       -- siac_r_subdoc_movgest_ts
       if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
                      ' [siac_r_subdoc_movgest_ts].';
        -- 12.01.2017 Sofia correzione per esclusione quote pagate
        insert into siac_r_subdoc_movgest_ts
        ( movgest_ts_id,
          subdoc_id,
	      validita_inizio,
	      ente_proprietario_id,
          login_operazione
        )
        ( select distinct
           movGestTsIdRet,
           r.subdoc_id,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_subdoc_movgest_ts r,siac_t_subdoc sub
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   sub.subdoc_id=r.subdoc_id
          and   sub.subdoc_pagato_cec =false -- 28.04.2023 Sofia SIAC-TASK-4
          and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=r.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
          -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=sub.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine                
          and   sub.data_cancellazione is null
          and   sub.validita_fine is null
          and   r.data_cancellazione is null
          and   r.validita_fine is null
          -- 10.04.2018 Daniela esclusione documenti annullati (SIAC-6015)
          and   not exists (select 1
          				    from siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A')
         );

		select 1  into codResult
        from siac_r_subdoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1
                            from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                 siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	where rord.subdoc_id=det1.subdoc_id
	        		        and   tsord.ord_ts_id=rord.ord_ts_id
			                and   ord.ord_id=tsord.ord_id
			                and   ord.bil_id=bilancioPrecId
		            	    and   rstato.ord_id=ord.ord_id
		                	and   stato.ord_stato_id=rstato.ord_stato_id
			                and   stato.ord_stato_code!='A'
			                and   rord.data_cancellazione is null
			                and   rord.validita_fine is null
		    	            and   rstato.data_cancellazione is null
		        	        and   rstato.validita_fine is null
        		    	   )
        -- 04.05.2021 Sofia SIAC-8095
          and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=det1.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
          -- 04.05.2021 Sofia SIAC-8095
          -- SIAC-8551 Sofia - inizio 
          and not exists 
          (
          select 1
          from  siac_r_subdoc_prov_cassa  r ,siac_t_prov_cassa p 
          where r.subdoc_id=det1.subdoc_id 
          and   p.provc_id=r.provc_id 
          and   p.provc_anno::integer=(annoBilancio-1)
          and   p.data_cancellazione is null 
          and   p.validita_fine  is null 
          and   r.data_cancellazione is null 
          and   r.validita_fine is null 
          )
     	  -- SIAC-8551 Sofia - fine                
/*        and   not exists (select 1 from siac_r_subdoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione) -- 28.04.2023 Sofia SIAC-TASK-4*/
        and   not exists (select 1 from siac_r_subdoc_movgest_ts det,siac_t_subdoc sub1 -- 28.04.2023 Sofia SIAC-TASK-4
				          where det.movgest_ts_id=movGestTsIdRet
				            and    sub1.subdoc_id=det.subdoc_id
				            and   sub1.subdoc_pagato_cec =false
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1
          				    from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                            where det1.subdoc_id = sub.subdoc_id
                            and   doc.doc_id = sub.doc_id
                            and   doc.doc_id = rst.doc_id
                            and   rst.data_cancellazione is null
                            and   rst.validita_fine is null
                            and   st.doc_stato_id = rst.doc_stato_id
                            and   st.doc_stato_code = 'A');

        raise notice 'dopo inserimento siac_r_subdoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       -- siac_r_predoc_movgest_ts
	   if codResult is null then
   	    strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||
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

		select 1  into codResult
        from siac_r_predoc_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   not exists (select 1 from siac_r_predoc_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione)
		and   det1.data_cancellazione is null
        and   det1.validita_fine is null;

        raise notice 'dopo inserimento siac_r_predoc_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
      /*   spostato sotto dopo pulizia in caso di codResult null
           if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;

       end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	        end if;
       end if; */

       -- siac_r_cartacont_det_movgest_ts
       /* non si gestisce in seguito ad indicazioni di Annalina
       if codResult is null then
    	 	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
	                      ' movgest_orig_id='||movGestRec.movgest_orig_id||
                          ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                          ' elem_orig_id='||movGestRec.elem_orig_id||
                          ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_cartacont_det_movgest_ts].';
	        update siac_r_cartacont_det_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_cartacont_det_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
	    	else codResult:=null;
	       end if;
       end if; */


	   -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null then
       	strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                         ' movgest_orig_id='||movGestRec.movgest_orig_id||
                         ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                         ' elem_orig_id='||movGestRec.elem_orig_id||
                         ' elem_id='||movGestRec.elem_id||
                        ' [siac_r_movgest_ts_storico_imp_acc].';

        insert into siac_r_movgest_ts_storico_imp_acc
        ( movgest_ts_id,
          movgest_anno_acc,
          movgest_numero_acc,
          movgest_subnumero_acc,
          validita_inizio,
          ente_proprietario_id,
          login_operazione
        )
        ( select
           movGestTsIdRet,
           r.movgest_anno_acc,
           r.movgest_numero_acc,
           r.movgest_subnumero_acc,
           dataInizioVal,
           enteProprietarioId,
           loginOperazione
          from siac_r_movgest_ts_storico_imp_acc r
          where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   r.data_cancellazione is null
          and   r.validita_fine is null
        );


        select 1  into codResult
        from siac_r_movgest_ts_storico_imp_acc det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);
        raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

       -- pulizia dati inseriti
       -- aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto
	   if codResult=-1 then


        if movGestTsIdRet is not null then


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

         -- siac_r_giustificativo_movgest
/*         strMessaggio:=strMessaggioTemp||
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
         delete from siac_r_richiesta_econ_movgest where movgest_ts_id=movGestTsIdRet; */
         -- siac_r_subdoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_subdoc_movgest_ts.';
         delete from siac_r_subdoc_movgest_ts where movgest_ts_id=movGestTsIdRet;
         -- siac_r_predoc_movgest_ts
         strMessaggio:=strMessaggioTemp||
                       ' Non Effettuato. Cancellazione siac_r_predoc_movgest_ts.';
         delete from siac_r_predoc_movgest_ts where movgest_ts_id=movGestTsIdRet;

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

	     -- 17.06.2019 Sofia siac-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;


         -- siac_t_movgest_ts
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_t_movgest_ts.';
         delete from siac_t_movgest_ts         where movgest_ts_id=movGestTsIdRet;
        
         -- 19.04.2023 Sofia SIAC-TASK-21
         -- siac_r_mutuo_movgest_ts
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_mutuo_movgest_ts.';
         delete from siac_r_mutuo_movgest_ts   where movgest_ts_id=movGestTsIdRet;

        end if;

		if  movGestRec.movgest_ts_tipo=MOVGEST_TS_T_TIPO then
            -- siac_r_movgest_bil_elem
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';

            delete from siac_r_movgest_bil_elem where movgest_id=movGestIdRet;
        	-- siac_t_movgest
            strMessaggio:=strMessaggioTemp||
                          ' Non Effettuato. Cancellazione siac_t_movgest.';
            delete from siac_t_movgest          where movgest_id=movGestIdRet;

        end if;




/*        strMessaggio:=strMessaggioTemp||
                     ' Non Effettuato. Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';*/
        strMessaggioTemp:=strMessaggio;
        strMessaggio:=strMessaggio||
                      'Aggiornamento fase_bil_t_gest_apertura_liq_imp per scarto.';

      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='X',
            scarto_code='RES1',
            scarto_desc='Movimento impegno/subimpegno residuo non inserito.'||strMessaggioTemp
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;

		continue;
       end if;

       --- cancellazione relazioni del movimento precedente
	   -- siac_r_subdoc_movgest_ts
       if codResult is null then
            --- 12.01.2017 Sofia - sistemazione update per escludere le quote pagate
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_subdoc_movgest_ts].';
	        update siac_r_subdoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
            from siac_t_subdoc sub  -- 28.04.2023 Sofia SIAC-TASK-4
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and     sub.subdoc_id=r.subdoc_id  -- 28.04.2023 Sofia SIAC-TASK-4
	        and     sub.subdoc_pagato_cec =false  -- 28.04.2023 Sofia SIAC-TASK-4
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
		   -- 04.05.2021 Sofia SIAC-8095
           and  not exists (
				           select 1
                           from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                           where rord.subdoc_id=r.subdoc_id
                           and   ts.ord_ts_id=rord.ord_ts_id
                           and   ord.ord_id=ts.ord_id
                           and   ord.ord_anno>annoBilancio
                           and   rord.data_cancellazione is null
                           and   rord.validita_fine is null
                          )
            -- 04.05.2021 Sofia SIAC-8095
			-- SIAC-8551 Sofia - inizio 
            and not exists 
            (
	          select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
	          where rp.subdoc_id=r.subdoc_id 
	          and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
	          and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
	          and   rp.validita_fine is null 
            )
     	    -- SIAC-8551 Sofia - fine                          
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub,siac_t_doc  doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

	        select 1 into codResult
    	    from siac_r_subdoc_movgest_ts r, 
    	               siac_t_subdoc sub -- 28.04.2023 Sofia SIAC-TASK-4
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
        	and     sub.subdoc_id=r.subdoc_id  -- 28.04.2023 Sofia SIAC-TASK-4
        	and     sub.subdoc_pagato_cec =false -- 28.04.2023 Sofia SIAC-TASK-4
            and   not exists (select 1
                              from siac_r_subdoc_ordinativo_ts rord,siac_t_ordinativo_ts tsord, siac_t_ordinativo ord,
                                   siac_r_ordinativo_stato rstato, siac_d_ordinativo_stato stato
 		                	  where rord.subdoc_id=r.subdoc_id
	        		          and   tsord.ord_ts_id=rord.ord_ts_id
			                  and   ord.ord_id=tsord.ord_id
			                  and   ord.bil_id=bilancioPrecId
		            	      and   rstato.ord_id=ord.ord_id
		                	  and   stato.ord_stato_id=rstato.ord_stato_id
			                  and   stato.ord_stato_code!='A'
			                  and   rord.data_cancellazione is null
			                  and   rord.validita_fine is null
		    	              and   rstato.data_cancellazione is null
		        	          and   rstato.validita_fine is null
        		    	     )
            -- 04.05.2021 Sofia SIAC-8095
            and  not exists (
                             select 1
                             from siac_r_subdoc_ordinativo_ts rord, siac_t_ordinativo_ts ts, siac_t_ordinativo ord
                             where rord.subdoc_id=r.subdoc_id
                             and   ts.ord_ts_id=rord.ord_ts_id
                             and   ord.ord_id=ts.ord_id
                             and   ord.ord_anno>annoBilancio
                             and   rord.data_cancellazione is null
                             and   rord.validita_fine is null
                           )
            -- 04.05.2021 Sofia SIAC-8095
            -- SIAC-8551 Sofia - inizio 
	        and not exists 
            (
	          select 1
	          from  siac_r_subdoc_prov_cassa  rp ,siac_t_prov_cassa p 
	          where rp.subdoc_id=r.subdoc_id 
	          and   p.provc_id=rp.provc_id 
	          and   p.provc_anno::integer=(annoBilancio-1)
	          and   p.data_cancellazione is null 
	          and   p.validita_fine  is null 
	          and   rp.data_cancellazione is null 
	          and   rp.validita_fine is null 
            )
     	    -- SIAC-8551 Sofia - fine               
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null
            and   not exists (select 1
                              from siac_t_subdoc sub, siac_t_doc doc, siac_r_doc_stato rst, siac_d_doc_stato st
                              where r.subdoc_id = sub.subdoc_id
                              and   doc.doc_id = sub.doc_id
                              and   doc.doc_id = rst.doc_id
                              and   rst.data_cancellazione is null
                              and   rst.validita_fine is null
                              and   st.doc_stato_id = rst.doc_stato_id
                              and   st.doc_stato_code = 'A')
            ;

        	if codResult is not null then
	    	    --strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
        end if;

       -- siac_r_predoc_movgest_ts
       if codResult is null then
	        strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Cancellazione relazioni su gestione prec. [siac_r_predoc_movgest_ts].';
	        update siac_r_predoc_movgest_ts r
    	    set    data_cancellazione=dataElaborazione,
        	       validita_fine=dataElaborazione,
            	   login_operazione=r.login_operazione||'-'||loginOperazione
	        where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
    	    and   r.data_cancellazione is null
        	and   r.validita_fine is null;

	        select 1 into codResult
    	    from siac_r_predoc_movgest_ts r
        	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
	        and   r.data_cancellazione is null
    	    and   r.validita_fine is null;

        	if codResult is not null then
--	    	    strMessaggioTemp:=strMessaggio;
    	        codResult:=-1;
                raise exception ' Errore in aggiornamento.';
	    	else codResult:=null;
	        end if;
       end if;

	   strMessaggio:='Movimento movGestTsTipo='||movGestRec.movgest_ts_tipo||
                       ' movgest_orig_id='||movGestRec.movgest_orig_id||
                       ' movgest_orig_ts_id='||movGestRec.movgest_orig_ts_id||
                       ' elem_orig_id='||movGestRec.elem_orig_id||
                       ' elem_id='||movGestRec.elem_id||'. Aggiornamento fase_bil_t_gest_apertura_liq_imp per fine elaborazione.';
      	update fase_bil_t_gest_apertura_liq_imp fase
        set fl_elab='I',
            movgest_id=movGestIdRet,
            movgest_ts_id=movGestTsIdRet
        where fase.fase_bil_gest_ape_liq_imp_id=movGestRec.fase_bil_gest_ape_liq_imp_id
        and   fase.fase_bil_elab_id=faseBilElabId
        and   fase.fl_elab='N'
        and   fase.data_cancellazione is null
        and   fase.validita_fine is null;


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


	 -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile
     -- insert N per impegni mov.movgest_anno::integer<annoBilancio or mov.movgest_anno::integer>annoBilancio
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che non hanno ancora attributo
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Inserimento valore N per impegni residui.';
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
     and   mov.movgest_anno::integer<annoBilancio
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
     -- essendo residui consideriamo solo mov.movgest_anno::integer<annoBilancio
     -- che  hanno  attributo ='S'
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni residui.';
	 update  siac_r_movgest_ts_attr r set boolean='N'
	 from siac_t_movgest mov, siac_t_movgest_ts ts
	 where  mov.bil_id=bilancioId
--		and   ( mov.movgest_anno::integer<2017 or mov.movgest_anno::integer>2017)
	 and   mov.movgest_anno::integer<annoBilancio
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
     strMessaggio:='Gestione attributo '||FRAZIONABILE_ATTR||'. Aggiornamento valore N per impegni di competenza e atti amministrativi antecedenti.';
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
     and   r.data_cancellazione is null
     and   r.validita_fine is null
     and   ra.data_cancellazione is null
     and   ra.validita_fine is null;
    -- 15.02.2017 Sofia SIAC-4425 - gestione attributo flagFrazionabile

    strMessaggio:='Aggiornamento stato fase bilancio IN-2.';
    update fase_bil_t_elaborazione
    set fase_bil_elab_esito='IN-2',
        fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||tipoElab||' IN CORSO IN-2.Elabora Imp.'
    where fase_bil_elab_id=faseBilElabId;


    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
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
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_liq_elabora_imp 
(
  integer,
  integer,
  varchar,
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out varchar)
OWNER TO siac;


CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_pluri_elabora
( enteproprietarioid integer, annobilancio integer, fasebilelabid integer, tipocapitologest character varying, tipomovgest character varying, tipomovgestts character varying, minid integer, maxid integer, loginoperazione character varying, dataelaborazione timestamp without time zone, OUT codicerisultato integer, OUT messaggiorisultato character varying)
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

	-- 03.05.2019 Sofia siac-6255
    faseOp                    VARCHAR(10):=null;
    G_FASE                    CONSTANT varchar:='G'; -- gestione approvata

    -- 14.05.2020 Sofia SIAC-7593
    elemDetCompTipoId INTEGER:=null;
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

	 -- 03.05.2019 Sofia siac-6255
     strMessaggio:='Lettura fase di bilancio di corrente.';
	 select fase.fase_operativa_code into faseOp
     from siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
     where r.bil_id=bilancioId
     and   fase.fase_operativa_id=r.fase_operativa_id
     and   r.data_cancellazione is null
     and   r.validita_fine is null;
     if faseOp is null then
		 raise exception ' Impossibile determinare Fase.';
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

		-- 14.05.2020 Sofia SIAC-7593
        elemDetCompTipoId:=null;

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
         -- 14.05.2020 Sofia SIAC-7593
         --select  new.elem_id into elemNewId
         select  new.elem_id , r.elem_det_comp_tipo_id into  elemNewId,elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
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
               elem_Det_comp_tipo_id, -- 14.05.2020 Sofia SIAC-7593
	           validita_inizio,
    	       ente_proprietario_id,
        	   login_operazione)
	          values
    	      (movGestIdRet,
        	   elemNewId,
               elemDetCompTipoId, -- 14.05.2020 Sofia SIAC-7593
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
        -- 14.05.2020 Sofia SIAC-7593
        --select  r.elem_id into elemNewId
        select  r.elem_id,r.elem_det_comp_tipo_id into elemNewId, elemDetCompTipoId -- 14.05.2020 Sofia SIAC-7593
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
/*        dataEmissione:=( (2018::varchar||'-01-01')
            ||' ' ||EXTRACT(hour FROM clock_timestamp())
            ||':'|| EXTRACT(minute FROM clock_timestamp())
            ||':'||EXTRACT(Second FROM clock_timestamp())::integer+random()
           )::timestamp;*/

        -- 21.02.2019 Sofia SIAC-6683
        dataEmissione:=( (annoBilancio::varchar||'-01-01')
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

       -- 03.05.2019 Sofia siac-6255
       if codResult is null then
         -- siac_r_movgest_ts_programma
--         if faseOp=G_FASE then -- 17.05.2023 Sofia SIAC-8633
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
             pnew.programma_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_programma r,siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   prog.programma_id=r.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.bil_id=bilancioId
            and   pnew.programma_code=prog.programma_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
	        and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
           );
          --returning movgest_ts_programma_id into  codResult;
          /*select 1 into codResult
          from siac_r_movgest_ts_programma det
          where det.movgest_ts_id=movGestTsIdRet
          and   det.data_cancellazione is null
          and   det.validita_fine is null
          and   det.login_operazione=loginOperazione;*/

		  -- 03.05.2019 Sofia siac-6255
          /*
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
          end if;*/

          -- siac_r_movgest_ts_cronop_elem
          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' solo cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
             movGestTsIdRet,
             cnew.cronop_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is null
            and   cronop.cronop_id=r.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
            and   cnew.cronop_code=cronop.cronop_code
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
		    and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null;

          strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                        ' anno='||movGestRec.movgest_anno||
                        ' numero='||movGestRec.movgest_numero||
                        ' movGestTipoTs='||tipoMovGestTs||
                        ' sub='||movGestRec.movgest_ts_code||
                        ' dettaglio cronop [siac_r_movgest_ts_cronop_elem].';

          insert into siac_r_movgest_ts_cronop_elem
          (
          	movgest_ts_id,
            cronop_id,
            cronop_elem_id,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          select
             movGestTsIdRet,
             celem_new.cronop_id,
             celem_new.cronop_elem_id,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_cronop_elem r,siac_t_cronop_elem celem,
                 siac_t_cronop_elem_det det,
                 siac_t_cronop cronop,
                 siac_t_programma prog,
                 siac_t_programma pnew, siac_d_programma_tipo tipo,
                 siac_r_programma_stato rs,siac_d_programma_stato stato,
                 siac_t_cronop cnew, siac_r_cronop_stato rsc, siac_d_cronop_stato cstato,
                 siac_t_cronop_elem celem_new,siac_t_cronop_elem_det det_new
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.cronop_elem_id is not null
            and   celem.cronop_elem_id=r.cronop_elem_id
            and   det.cronop_elem_id=celem.cronop_elem_id
            and   cronop.cronop_id=celem.cronop_id
            and   prog.programma_id=cronop.programma_id
            and   tipo.ente_proprietario_id=prog.ente_proprietario_id
            and   tipo.programma_tipo_code='G'
            and   pnew.programma_tipo_id=tipo.programma_tipo_id
            and   pnew.programma_code=prog.programma_code
            and   cnew.programma_id=pnew.programma_id
            and   cnew.bil_id=bilancioId
            and   celem_new.cronop_id=cnew.cronop_id
            and   det_new.cronop_elem_id=celem_new.cronop_elem_id
            and   cnew.cronop_code=cronop.cronop_code
            and   coalesce(celem_new.cronop_elem_code,'')=coalesce(celem.cronop_elem_code,'')
            and   coalesce(celem_new.cronop_elem_code2,'')=coalesce(celem.cronop_elem_code2,'')
            and   coalesce(celem_new.cronop_elem_code3,'')=coalesce(celem.cronop_elem_code3,'')
            and   coalesce(celem_new.elem_tipo_id,0)=coalesce(celem.elem_tipo_id,0)
            and   coalesce(celem_new.cronop_elem_desc,'')=coalesce(celem.cronop_elem_desc,'')
            and   coalesce(celem_new.cronop_elem_desc2,'')=coalesce(celem.cronop_elem_desc2,'')
            and   coalesce(det_new.periodo_id,0)=coalesce(det.periodo_id,0)
		    and   coalesce(det_new.cronop_elem_det_importo,0)=coalesce(det.cronop_elem_det_importo,0)
            and   coalesce(det_new.cronop_elem_det_desc,'')=coalesce(det.cronop_elem_det_desc,'')
	        and   coalesce(det_new.anno_entrata,'')=coalesce(det.anno_entrata,'')
	        and   coalesce(det_new.elem_det_tipo_id,0)=coalesce(det.elem_det_tipo_id,0)
            and   rs.programma_id=pnew.programma_id
            and   stato.programma_stato_id=rs.programma_stato_id
            --and   stato.programma_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   stato.programma_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   rsc.cronop_id=cnew.cronop_id
            and   cstato.cronop_stato_id=rsc.cronop_stato_id
            --and   cstato.cronop_stato_code='VA' -- 06.08.2019 Sofia SIAC-6934
			and   cstato.cronop_stato_code!='AN' -- 06.08.2019 Sofia SIAC-6934
            and   exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and  not exists
            (
              select 1
              from siac_r_cronop_elem_class rc,siac_t_class c,siac_d_class_tipo tipo
              where rc.cronop_elem_id=celem.cronop_elem_id
              and   c.classif_id=rc.classif_id
              and   tipo.classif_tipo_id=c.classif_tipo_id
              and   not exists
              (
                select 1
                from siac_r_cronop_elem_class rc1, siac_t_class c1
                where rc1.cronop_elem_id=celem_new.cronop_elem_id
                and   c1.classif_id=rc1.classif_id
                and   c1.classif_tipo_id=tipo.classif_tipo_id
                and   c1.classif_code=c.classif_code
                and   rc1.data_cancellazione is null
                and   rc1.validita_fine is null
              )
              and   rc.data_cancellazione is null
              and   rc.validita_fine is null
            )
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   prog.data_cancellazione is null
            and   prog.validita_fine is null
            and   cronop.data_cancellazione is null
            and   cronop.validita_fine is null
            and   celem.data_cancellazione is null
            and   celem.validita_fine is null
            and   det.data_cancellazione is null
            and   det.validita_fine is null
            and   pnew.data_cancellazione is null
            and   pnew.validita_fine is null
            and   cnew.data_cancellazione is null
            and   cnew.validita_fine is null
            and   celem_new.data_cancellazione is null
            and   celem_new.validita_fine is null
            and   det_new.data_cancellazione is null
            and   det_new.validita_fine is null
            and   rs.data_cancellazione is null
            and   rs.validita_fine is null
            and   rsc.data_cancellazione is null
            and   rsc.validita_fine is null;
--         end if; -- 17.05.2023 Sofia SIAC-8633
       end if; 
       -- 03.05.2019 Sofia siac-6255
     
      
            -- 19.04.2023 SIAC-TASK-21
      -- siac_r_mutuo_movgest_ts
      if codResult is null then
       strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_mutuo_voce_movgest_ts].';
      	insert into siac_r_mutuo_movgest_ts  
      	(
      		movgest_ts_id,
      		mutuo_id,
      		mutuo_movgest_ts_importo_iniziale,
      		mutuo_movgest_ts_importo_finale,
      		validita_inizio,
      		ente_proprietario_id ,
      		login_operazione,
      		login_creazione,
      		login_modifica
      	)
      	select  movGestTsIdRet,
      	             r.mutuo_id,
      	             det.movgest_ts_det_importo,
      	             det.movgest_ts_det_importo,
      	             dataInizioVal,
		             enteProprietarioId,
          		     loginOperazione,
          		     loginOperazione,
          		     loginOperazione
      	from siac_r_mutuo_movgest_ts r,siac_t_mutuo mutuo,siac_d_mutuo_stato stato, 
      	           siac_t_movgest_ts_det det ,siac_d_movgest_ts_det_tipo tipo 
      	where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
      	and     det.movgest_ts_id=movGestTsIdRet
      	and     tipo.movgest_ts_det_tipo_id = det.movgest_ts_det_tipo_id 
      	and     tipo.movgest_ts_det_tipo_code='I'
      	and     mutuo.mutuo_id=r.mutuo_id 
      	and     stato.mutuo_stato_id=mutuo.mutuo_stato_id 
      	and     stato.mutuo_stato_code!='A'
      	and     mutuo.data_cancellazione is null 
      	and     mutuo.validita_fine is null
      	and     r.data_cancellazione is null 
      	and     r.validita_fine is null;
        
		select 1  into codResult
        from siac_r_mutuo_movgest_ts det1
        where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
        and   det1.data_cancellazione is null
        and   det1.validita_fine is null
        and   not exists (select 1 from siac_r_mutuo_movgest_ts det
				          where det.movgest_ts_id=movGestTsIdRet
					        and   det.data_cancellazione is null
					        and   det.validita_fine is null
					        and   det.login_operazione=loginOperazione);

        raise notice 'dopo inserimento siac_r_mutuo_movgest_ts movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

        if codResult is not null then
       	 codResult:=-1;
         strMessaggioTemp:=strMessaggio;
        else codResult:=null;
        end if;
      
      end if;
     
	/*	16.03.2023 Sofia SIAC-TASK-#44							
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

        **select 1 into codResult
        from siac_r_mutuo_voce_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;**

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
	  */ 

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

    *    select 1 into codResult
        from siac_r_giustificativo_movgest det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*

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

        *select 1 into codResult
        from siac_r_cartacont_det_movgest_ts det
        where det.movgest_ts_id=movGestTsIdRet
        and   det.data_cancellazione is null
        and   det.validita_fine is null
        and   det.login_operazione=loginOperazione;*


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

       -- 17.06.2019 Sofia SIAC-6702 - inizio
	   if codResult is null and tipoMovGest=IMP_MOVGEST_TIPO then
		strMessaggio:='Inserimento movimento movGestTipo='||tipoMovGest||
                      ' anno='||movGestRec.movgest_anno||
                      ' numero='||movGestRec.movgest_numero||
                      ' movGestTipoTs='||tipoMovGestTs||
                      ' sub='||movGestRec.movgest_ts_code||
                      ' [siac_r_movgest_ts_storico_imp_acc].';
          insert into siac_r_movgest_ts_storico_imp_acc
          ( movgest_ts_id,
            movgest_anno_acc,
            movgest_numero_acc,
            movgest_subnumero_acc,
            validita_inizio,
            ente_proprietario_id,
            login_operazione
          )
          ( select
             movGestTsIdRet,
             r.movgest_anno_acc,
             r.movgest_numero_acc,
             r.movgest_subnumero_acc,
             dataInizioVal,
             enteProprietarioId,
             loginOperazione
            from siac_r_movgest_ts_storico_imp_acc r
            where r.movgest_ts_id=movGestRec.movgest_orig_ts_id
            and   r.data_cancellazione is null
            and   r.validita_fine is null
          );


          select 1  into codResult
          from siac_r_movgest_ts_storico_imp_acc det1
          where det1.movgest_ts_id=movGestRec.movgest_orig_ts_id
          and   det1.data_cancellazione is null
          and   det1.validita_fine is null
          and   not exists (select 1 from siac_r_movgest_ts_storico_imp_acc det
                            where det.movgest_ts_id=movGestTsIdRet
                              and   det.data_cancellazione is null
                              and   det.validita_fine is null
                              and   det.login_operazione=loginOperazione);
          raise notice 'dopo inserimento siac_r_movgest_ts_storico_imp_acc movGestTsIdRet=% codResult=%', movGestTsIdRet,codResult;

          if codResult is not null then
           codResult:=-1;
           strMessaggioTemp:=strMessaggio;
          else codResult:=null;
          end if;
       end if;
       -- 17.06.2019 Sofia SIAC-6702 - fine

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

		 -- 03.05.2019 Sofia siac-6255
		 -- siac_r_movgest_ts_programma
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_programma.';
         delete from siac_r_movgest_ts_programma   where movgest_ts_id=movGestTsIdRet;
         -- siac_r_movgest_ts_cronop_elem
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_cronop_elem.';
         delete from siac_r_movgest_ts_cronop_elem where movgest_ts_id=movGestTsIdRet;

		 -- 17.06.2019 Sofia SIAC-6702
         -- siac_r_movgest_ts_storico_imp_acc
 	     strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_movgest_ts_storico_imp_acc.';
         delete from siac_r_movgest_ts_storico_imp_acc  where movgest_ts_id=movGestTsIdRet;

		-- 19.04.2023 Sofia SIAC-TASK-21
         -- siac_r_mutuo_movgest_ts
         strMessaggio:=strMessaggioTemp||
                      ' Non Effettuato. Cancellazione siac_r_mutuo_movgest_ts.';
         delete from siac_r_mutuo_movgest_ts   where movgest_ts_id=movGestTsIdRet;
        
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
            elem_Det_comp_tipo_id=elemDetCompTipoId, -- 14.05.2020 Sofia Jira SIAC-7593
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
		and   mov.movgest_anno::INTEGER=annoBilancio
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

alter function siac.fnc_fasi_bil_gest_apertura_pluri_elabora
(  integer,  integer,  integer,  character varying,  character varying,  character varying,  integer,  integer,  character varying,  timestamp without time zone, OUT  integer, OUT  character varying) owner to siac;



-- SIAC-8633 Sofia 13.06.2023 fine 




-- INIZIO SIAC-8863.sql



\echo SIAC-8863.sql


-- SIAC-8863 Haitham 05.07.2023 inizio

select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'codice_missione', 'varchar(10)');
select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'descri_missione', 'varchar(500)');
select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'codice_programma', 'varchar(10)');
select fnc_dba_add_column_params ('siac_dwh_contabilita_generale', 'descri_programma', 'varchar(500)');



CREATE OR REPLACE FUNCTION siac.fnc_prima_nota_missione_programma(p_ente_prop_id integer, p_anno character varying)
 RETURNS TABLE(pnota_id integer, pnota_numero integer, pnota_progressivogiornale integer, code_missione character varying, desc_missione character varying, code_programma character varying, desc_programma character varying, tipo_prima_nota character varying, collegamento_tipo_code character varying, elem_id integer)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
DECLARE
 
DEF_NULL	constant varchar:='';  
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
anno_competenza_int integer;
 
sqlQuery varchar;
idBilancio integer;
anno_bil_int integer;

BEGIN
 
	

/* 01/06/2023 .
	Funzione simile alla  BILR258_rend_gest_costi_missione_all_h_cont_gen
	ma con meno dati e  serve  per fnc_siac_dwh_contabilita_generale per la SIAC-8863.
*/

code_missione:='';
desc_missione:='';
code_programma:='';
desc_programma:='';
elem_id:=0;
collegamento_tipo_code:='';

anno_competenza_int=p_anno ::INTEGER;

anno_bil_int:=p_anno::INTEGER;

RTN_MESSAGGIO:='Estrazione dei dati degli impegni ''.';
raise notice 'ora: % ',clock_timestamp()::varchar;
  
-- leggo l'ID del bilancio x velocizzare.
 select a.bil_id
 into idBilancio
 from siac_t_bil a, siac_t_periodo b
 where a.periodo_id=b.periodo_id
 and a.ente_proprietario_id =p_ente_prop_id
 and b.anno = p_anno
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;
 

return query 

select distinct
   query_totale.pnota_id,
   query_totale.pnota_numero,
   query_totale.pnota_progressivogiornale,
 case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.code_miss_lib,'')::varchar
   else 
   		COALESCE(missioni.code_missione,'')::varchar end code_missione,
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.desc_miss_lib,'')::varchar
   else
   		COALESCE(missioni.desc_missione,'')::varchar end desc_missione,
   		
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.code_progr_lib,'')::varchar
     else 
   		COALESCE(missioni.code_programma,'')::varchar end code_programma,
   
   case when query_totale.causale_ep_tipo_code = 'LIB' THEN
   		COALESCE(query_totale.desc_progr_lib,'')::varchar
     else
   		COALESCE(missioni.desc_programma,'')::varchar end desc_programma,	

   COALESCE(query_totale.causale_ep_tipo_code,'') tipo_prima_nota,
   COALESCE(query_totale.collegamento_tipo_code,'') collegamento_tipo_code,
   COALESCE(query_totale.elem_id,0) elem_id
   		
   	from (
    	--Estraggo i capitoli di spesa gestione e i relativi dati di struttura
        --per poter avere le missioni.
	with capitoli as(
  select distinct programma.classif_id programma_id,
          macroaggr.classif_id macroaggregato_id,          
          capitolo.elem_id
  from siac_d_class_tipo programma_tipo,
       siac_t_class programma,
       siac_d_class_tipo macroaggr_tipo,
       siac_t_class macroaggr,
       siac_t_bil_elem capitolo,
       siac_d_bil_elem_tipo tipo_elemento,
       siac_r_bil_elem_class r_capitolo_programma,
       siac_r_bil_elem_class r_capitolo_macroaggr, 
       siac_d_bil_elem_stato stato_capitolo, 
       siac_r_bil_elem_stato r_capitolo_stato,
       siac_d_bil_elem_categoria cat_del_capitolo,
       siac_r_bil_elem_categoria r_cat_capitolo 
  where 	
      programma.classif_tipo_id=programma_tipo.classif_tipo_id 		
      and	programma.classif_id=r_capitolo_programma.classif_id			    
      and	macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 		
      and	macroaggr.classif_id=r_capitolo_macroaggr.classif_id			    
      and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 					
      and	capitolo.elem_id=r_capitolo_programma.elem_id					
      and	capitolo.elem_id=r_capitolo_macroaggr.elem_id						
      and	capitolo.elem_id				=	r_capitolo_stato.elem_id	
      and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		
      and	capitolo.elem_id				=	r_cat_capitolo.elem_id		
      and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id	   	
      and	capitolo.ente_proprietario_id=p_ente_prop_id 	
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.				
      --and	capitolo.bil_id = idBilancio										 
      and	programma_tipo.classif_tipo_code='PROGRAMMA'							
      and	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						
      and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     	
      and	stato_capitolo.elem_stato_code	=	'VA'						     							
      and	programma_tipo.data_cancellazione 			is null
      and	programma.data_cancellazione 				is null
      and	macroaggr_tipo.data_cancellazione 			is null
      and	macroaggr.data_cancellazione 				is null
      and	capitolo.data_cancellazione 				is null
      and	tipo_elemento.data_cancellazione 			is null
      and	r_capitolo_programma.data_cancellazione 	is null
      and	r_capitolo_macroaggr.data_cancellazione 	is null 
      and	stato_capitolo.data_cancellazione 			is null 
      and	r_capitolo_stato.data_cancellazione 		is null
      and	cat_del_capitolo.data_cancellazione 		is null
      and	r_cat_capitolo.data_cancellazione 			is null),
   strut_bilancio as(
        select *
        from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')) 
  select COALESCE(strut_bilancio.missione_code,'') code_missione,
         COALESCE(strut_bilancio.missione_desc,'') desc_missione,
         COALESCE(strut_bilancio.programma_code,'') code_programma,
         COALESCE(strut_bilancio.programma_desc,'') desc_programma,    
         capitoli.elem_id
  from capitoli  
    left JOIN strut_bilancio on (strut_bilancio.programma_id =  capitoli.programma_id
        			AND strut_bilancio.macroag_id =  capitoli.macroaggregato_id)
  ) missioni 
  --devo estrarre con full join perche' nella query seguente ci sono anche le
  --prime note libere che non hanno il collegamento con i capitoli.
  full join  (     
  	--Estraggo i dati dei classificatori.
    --Questa parte della query e' la stessa del report BILR125.
        with classificatori as (
  SELECT classif_tot.classif_code AS codice_codifica, 
         classif_tot.classif_desc AS descrizione_codifica,
         classif_tot.ordine AS codice_codifica_albero, 
         case when classif_tot.ordine='E.26' then 3 
         	else classif_tot.level end livello_codifica,
         classif_tot.classif_id
  FROM (
      SELECT tb.classif_classif_fam_tree_id,
             tb.classif_fam_tree_id, t1.classif_code,
             t1.classif_desc, ti1.classif_tipo_code,
             tb.classif_id, tb.classif_id_padre,
             tb.ente_proprietario_id, 
             CASE WHEN tb.ordine = 'B.9' THEN 'B.09'
             ELSE tb.ordine
             END  ordine,
             tb.level,
             tb.arrhierarchy
      FROM ( WITH RECURSIVE rqname(classif_classif_fam_tree_id,
                                   classif_fam_tree_id, 
                                   classif_id, 
                                   classif_id_padre, 
                                   ente_proprietario_id, 
                                   ordine, 
                                   livello, 
                                   level, arrhierarchy) AS (
             SELECT rt1.classif_classif_fam_tree_id,
                    rt1.classif_fam_tree_id,
                    rt1.classif_id,
                    rt1.classif_id_padre,
                    rt1.ente_proprietario_id,
                    rt1.ordine,
                    rt1.livello, 1,
                    ARRAY[COALESCE(rt1.classif_id,0)] AS "array"
             FROM siac_r_class_fam_tree rt1, siac_t_class_fam_tree tt1, siac_d_class_fam cf, siac_t_class c
             WHERE cf.classif_fam_id = tt1.classif_fam_id 
             and c.classif_id=rt1.classif_id
             AND   tt1.classif_fam_tree_id = rt1.classif_fam_tree_id 
             AND rt1.classif_id_padre IS NULL 
             AND   (cf.classif_fam_code = '00020')-- OR cf.classif_fam_code = v_classificatori1)
             AND tt1.ente_proprietario_id = rt1.ente_proprietario_id 
             AND anno_bil_int BETWEEN date_part('year',tt1.validita_inizio) AND 
             date_part('year',COALESCE(tt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',rt1.validita_inizio) AND 
             date_part('year',COALESCE(rt1.validita_fine,now())) 
             AND anno_bil_int BETWEEN date_part('year',c.validita_inizio) AND 
             date_part('year',COALESCE(c.validita_fine,now())) 
             AND tt1.ente_proprietario_id = p_ente_prop_id
             UNION ALL
             SELECT tn.classif_classif_fam_tree_id,
                    tn.classif_fam_tree_id,
                    tn.classif_id,
                    tn.classif_id_padre,
                    tn.ente_proprietario_id,
                    tn.ordine,
                    tn.livello,
                    tp.level + 1,
                    tp.arrhierarchy || tn.classif_id
          FROM rqname tp, siac_r_class_fam_tree tn,siac_t_class c2
          WHERE tp.classif_id = tn.classif_id_padre 
          and c2.classif_id=tn.classif_id
          AND tn.ente_proprietario_id = tp.ente_proprietario_id
          AND anno_bil_int BETWEEN date_part('year',tn.validita_inizio) AND 
             date_part('year',COALESCE(tn.validita_fine,now())) 
  AND anno_bil_int BETWEEN date_part('year',c2.validita_inizio) AND 
             date_part('year',COALESCE(c2.validita_fine,now()))            
          )
          SELECT rqname.classif_classif_fam_tree_id,
                 rqname.classif_fam_tree_id,
                 rqname.classif_id,
                 rqname.classif_id_padre,
                 rqname.ente_proprietario_id,
                 rqname.ordine, rqname.livello,
                 rqname.level,
                 rqname.arrhierarchy
          FROM rqname
          ORDER BY rqname.arrhierarchy
          ) tb,
          siac_t_class t1, siac_d_class_tipo ti1
      WHERE t1.classif_id = tb.classif_id 
      AND ti1.classif_tipo_id = t1.classif_tipo_id 
      AND t1.ente_proprietario_id = tb.ente_proprietario_id 
      AND ti1.ente_proprietario_id = t1.ente_proprietario_id
      AND anno_bil_int BETWEEN date_part('year',t1.validita_inizio) 
      AND date_part('year',COALESCE(t1.validita_fine,now()))
  ) classif_tot
  ORDER BY classif_tot.classif_tipo_code desc, classif_tot.ordine),
pdce as(  
	--Estraggo le prime note collegate ai classificatori ed anche i relativi ID
    --degli eventi coinvolti per poterli poi collegare ai capitoli.
SELECT r_pdce_conto_class.classif_id,
		d_pdce_fam.pdce_fam_code, t_mov_ep_det.movep_det_segno, 
        d_coll_tipo.collegamento_tipo_code,
        r_ev_reg_movfin.campo_pk_id, r_ev_reg_movfin.campo_pk_id_2,
        COALESCE(t_mov_ep_det.movep_det_importo,0) importo,
         t_mov_ep_det.movep_det_id,d_caus_tipo.causale_ep_tipo_code,
         t_prima_nota.pnota_id,
         t_prima_nota.pnota_numero,
         t_prima_nota.pnota_progressivogiornale
    FROM  siac_r_pdce_conto_class r_pdce_conto_class
    INNER JOIN siac_t_pdce_conto pdce_conto 
    	ON r_pdce_conto_class.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_pdce_fam_tree t_pdce_fam_tree 
    	ON pdce_conto.pdce_fam_tree_id = t_pdce_fam_tree.pdce_fam_tree_id
    INNER JOIN siac_d_pdce_fam d_pdce_fam 
    	ON t_pdce_fam_tree.pdce_fam_id = d_pdce_fam.pdce_fam_id    
    INNER JOIN siac_t_mov_ep_det t_mov_ep_det 
    	ON t_mov_ep_det.pdce_conto_id = pdce_conto.pdce_conto_id
    INNER JOIN siac_t_mov_ep t_mov_ep 
    	ON t_mov_ep_det.movep_id = t_mov_ep.movep_id
    INNER JOIN siac_t_prima_nota t_prima_nota 
    	ON t_mov_ep.regep_id = t_prima_nota.pnota_id    
    INNER JOIN siac_r_prima_nota_stato r_prima_nota_stato 
    	ON t_prima_nota.pnota_id = r_prima_nota_stato.pnota_id
    INNER JOIN siac_d_prima_nota_stato d_prima_nota_stato 
    	ON r_prima_nota_stato.pnota_stato_id = d_prima_nota_stato.pnota_stato_id
    --devo estrarre con left join per prendere anche le prime note libere
    --che non hanno eventi.
    LEFT JOIN siac_r_evento_reg_movfin r_ev_reg_movfin 
    	ON r_ev_reg_movfin.regmovfin_id = t_mov_ep.regmovfin_id
    LEFT JOIN siac_d_evento d_evento 
    	ON d_evento.evento_id = r_ev_reg_movfin.evento_id
    LEFT JOIN siac_d_collegamento_tipo d_coll_tipo
    	ON d_coll_tipo.collegamento_tipo_id = d_evento.collegamento_tipo_id
    inner join siac_d_causale_ep_tipo d_caus_tipo
    	on d_caus_tipo.causale_ep_tipo_id=t_prima_nota.causale_ep_tipo_id
    WHERE r_pdce_conto_class.ente_proprietario_id = p_ente_prop_id
    AND   t_prima_nota.bil_id = idBilancio 
    AND   d_prima_nota_stato.pnota_stato_code = 'D'
    AND   r_pdce_conto_class.data_cancellazione IS NULL
    AND   pdce_conto.data_cancellazione IS NULL
    AND   t_pdce_fam_tree.data_cancellazione IS NULL
    AND   d_pdce_fam.data_cancellazione IS NULL
    AND   t_mov_ep_det.data_cancellazione IS NULL
    AND   t_mov_ep.data_cancellazione IS NULL
    AND   t_prima_nota.data_cancellazione IS NULL
    AND   r_prima_nota_stato.data_cancellazione IS NULL
    AND   d_prima_nota_stato.data_cancellazione IS NULL
    AND   r_ev_reg_movfin.data_cancellazione IS NULL
    AND   d_evento.data_cancellazione IS NULL
    AND   d_coll_tipo.data_cancellazione IS NULL
    AND   anno_bil_int BETWEEN date_part('year',pdce_conto.validita_inizio) 
    		AND date_part('year',COALESCE(pdce_conto.validita_fine,now()))  
    AND  anno_bil_int BETWEEN date_part('year',r_pdce_conto_class.validita_inizio)::integer
    		AND coalesce (date_part('year',r_pdce_conto_class.validita_fine)::integer ,anno_bil_int) 
   ),
   --Di seguito tutti gli eventi da collegarsi alle prime note come quelli estratti
   --dal report BILR159.
collegamento_MMGS_MMGE_a AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_t_movgest_ts_det_mod tmtdm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   tmtdm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = tmtdm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND	rms.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   dms.mod_stato_code = 'V'
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   tmtdm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_MMGS_MMGE_b AS (
  SELECT DISTINCT rmbe.elem_id, tm.mod_id
  FROM  siac_t_modifica tm, siac_r_modifica_stato rms, siac_d_modifica_stato dms,
        siac_r_movgest_ts_sog_mod rmtsm, siac_t_movgest_ts tmt,
        siac_r_movgest_bil_elem rmbe, siac_t_bil_elem t_bil_elem 
  WHERE tm.mod_id = rms.mod_id  
  AND   rms.mod_stato_id = dms.mod_stato_id
  AND   rmtsm.mod_stato_r_id = rms.mod_stato_r_id
  AND   tmt.movgest_ts_id = rmtsm.movgest_ts_id
  AND   rmbe.movgest_id = tmt.movgest_id
  AND	t_bil_elem.elem_id = rmbe.elem_id
  AND 	rms.ente_proprietario_id = p_ente_prop_id
  AND   dms.mod_stato_code = 'V'
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   tm.data_cancellazione IS NULL
  AND   rms.data_cancellazione IS NULL
  AND   dms.data_cancellazione IS NULL
  AND   rmtsm.data_cancellazione IS NULL
  AND   tmt.data_cancellazione IS NULL
  AND   rmbe.data_cancellazione IS NULL),
  collegamento_I_A AS ( --Impegni e Accertamenti
    SELECT DISTINCT r_mov_bil_elem.elem_id, r_mov_bil_elem.movgest_id
      FROM   siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem 
      WHERE  t_bil_elem.elem_id=r_mov_bil_elem.elem_id
      AND	 r_mov_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
     -- AND 	 t_bil_elem.bil_id = idBilancio
      AND    r_mov_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_SI_SA AS ( --Subimpegni e Subaccertamenti
  SELECT DISTINCT r_mov_bil_elem.elem_id, mov_ts.movgest_ts_id
  FROM  siac_t_movgest_ts mov_ts, siac_r_movgest_bil_elem r_mov_bil_elem,
  		siac_t_bil_elem t_bil_elem 
  WHERE mov_ts.movgest_id = r_mov_bil_elem.movgest_id
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND   mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND 	t_bil_elem.bil_id = idBilancio
  AND   mov_ts.data_cancellazione IS NULL
  AND   r_mov_bil_elem.data_cancellazione IS NULL
  AND   t_bil_elem.data_cancellazione IS NULL),
  collegamento_SS_SE AS ( --SUBDOC
  SELECT DISTINCT r_mov_bil_elem.elem_id, r_subdoc_mov_ts.subdoc_id
  FROM   siac_r_subdoc_movgest_ts r_subdoc_mov_ts, siac_t_movgest_ts mov_ts, 
  		 siac_r_movgest_bil_elem r_mov_bil_elem, siac_t_bil_elem t_bil_elem
  WHERE  r_subdoc_mov_ts.movgest_ts_id = mov_ts.movgest_ts_id
  AND    mov_ts.movgest_id = r_mov_bil_elem.movgest_id 
  AND	t_bil_elem.elem_id = r_mov_bil_elem.elem_id
  AND 	 mov_ts.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	  
  --AND	 t_bil_elem.bil_id = idBilancio
  AND    (r_subdoc_mov_ts.data_cancellazione IS NULL OR 
  				(r_subdoc_mov_ts.data_cancellazione IS NOT NULL
  				AND r_subdoc_mov_ts.validita_fine IS NOT NULL AND
                r_subdoc_mov_ts.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
  AND    mov_ts.data_cancellazione IS NULL
  AND    r_mov_bil_elem.data_cancellazione IS NULL
  AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_OP_OI AS ( --Ordinativi di pagamento e incasso.
    SELECT DISTINCT r_ord_bil_elem.elem_id, r_ord_bil_elem.ord_id
      FROM   siac_r_ordinativo_bil_elem r_ord_bil_elem, siac_t_bil_elem t_bil_elem
      WHERE  r_ord_bil_elem.elem_id=t_bil_elem.elem_id 
      AND	 r_ord_bil_elem.ente_proprietario_id = p_ente_prop_id
      --13/01/2022 SIAC-8558 non si deve filtrare per l'anno bilancio
      --perche' ci sono prome note legate a movimenti del bilancio
      --successivo che verrebbero escluse.	      
      --AND	 t_bil_elem.bil_id = idBilancio  
      AND    r_ord_bil_elem.data_cancellazione IS NULL
      AND    t_bil_elem.data_cancellazione IS NULL),
  collegamento_L AS ( --Liquidazioni
    SELECT DISTINCT c.elem_id, a.liq_id
      FROM   siac_r_liquidazione_movgest a, siac_t_movgest_ts b, 
             siac_r_movgest_bil_elem c
      WHERE  a.movgest_ts_id = b.movgest_ts_id
      AND    b.movgest_id = c.movgest_id
      AND	 b.ente_proprietario_id = p_ente_prop_id
      AND    a.data_cancellazione IS NULL
      AND    b.data_cancellazione IS NULL
      AND    c.data_cancellazione IS NULL),
  collegamento_RR AS ( --Giustificativi.
  	SELECT DISTINCT d.elem_id, a.gst_id
      FROM  siac_t_giustificativo a, siac_r_richiesta_econ_movgest b, siac_t_movgest_ts c, siac_r_movgest_bil_elem d
      WHERE a.ente_proprietario_id = p_ente_prop_id
      AND   a.ricecon_id = b.ricecon_id
      AND   b.movgest_ts_id = c.movgest_ts_id
      AND   c.movgest_id = d.movgest_id
      AND   a.data_cancellazione  IS NULL
      AND   b.data_cancellazione  IS NULL
      AND   c.data_cancellazione  IS NULL
      AND   d.data_cancellazione  IS NULL),
  collegamento_RE AS ( --Richieste economali.
  SELECT DISTINCT c.elem_id, a.ricecon_id
    FROM  siac_r_richiesta_econ_movgest a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    WHERE b.ente_proprietario_id = p_ente_prop_id
    AND   a.movgest_ts_id = b.movgest_ts_id
    AND   b.movgest_id = c.movgest_id
    AND   a.data_cancellazione  IS NULL
    AND   b.data_cancellazione  IS NULL
    AND   c.data_cancellazione  IS NULL),
  collegamento_SS_SE_NCD AS ( --Note di credito
    select c.elem_id, a.subdoc_id
    from  siac_r_subdoc_movgest_ts a, siac_t_movgest_ts b, siac_r_movgest_bil_elem c
    where a.movgest_ts_id = b.movgest_ts_id
    AND    b.movgest_id = c.movgest_id
    AND b.ente_proprietario_id = p_ente_prop_id
    AND    (a.data_cancellazione IS NULL OR (a.data_cancellazione IS NOT NULL
                  AND a.validita_fine IS NOT NULL AND
                  a.validita_fine > to_timestamp('31/12/'||p_anno||'','dd/mm/yyyy')))
    AND    b.data_cancellazione IS NULL
    AND    c.data_cancellazione IS NULL),      
--estraggo la missione collegata a siac_r_mov_ep_det_class per le 
--prime note libere.    
ele_prime_note_lib_miss as (
  	select t_class.classif_code code_miss_lib,
    t_class.classif_desc desc_miss_lib,
     r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id=p_ente_prop_id
        and d_class_tipo.classif_tipo_code='MISSIONE'
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL),
ele_prime_note_lib_programma as (
  	select t_class.classif_code code_progr_lib,
    t_class.classif_desc desc_progr_lib,
     r_mov_ep_det_class.*
    from siac_r_mov_ep_det_class r_mov_ep_det_class,
    	siac_t_class t_class ,  	
        siac_d_class_tipo d_class_tipo	
    where t_class.classif_id=r_mov_ep_det_class.classif_id
    	and d_class_tipo.classif_tipo_id = t_class.classif_tipo_id
        AND r_mov_ep_det_class.ente_proprietario_id=p_ente_prop_id
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ep_det_class.data_cancellazione IS NULL
        and t_class.data_cancellazione IS NULL
        and d_class_tipo.data_cancellazione IS NULL)                                    
        
SELECT classificatori.codice_codifica::varchar codice_codifica,
    classificatori.descrizione_codifica::varchar descrizione_codifica,
    classificatori.codice_codifica_albero::varchar codice_codifica_albero,
    classificatori.livello_codifica::integer livello_codifica,       
    case when upper(pdce.movep_det_segno)='DARE' then pdce.importo
    	else 0::numeric end importo_dare,
    case when upper(pdce.movep_det_segno)='AVERE' then pdce.importo
    	else 0::numeric end importo_avere,
    COALESCE(collegamento_MMGS_MMGE_a.elem_id, 
    	COALESCE(collegamento_MMGS_MMGE_b.elem_id,
        	COALESCE(collegamento_I_A.elem_id,
        		COALESCE(collegamento_SI_SA.elem_id,
                	COALESCE(collegamento_SS_SE.elem_id,
                    	COALESCE(collegamento_OP_OI.elem_id,
                        	COALESCE(collegamento_L.elem_id,
                            	COALESCE(collegamento_RR.elem_id,
                                	COALESCE(collegamento_RE.elem_id,
                                    	COALESCE(collegamento_SS_SE_NCD.elem_id,
                                          	0),0),0),0),0),0),0),0),0),0) elem_id,
	pdce.collegamento_tipo_code,--, pdce.campo_pk_id, pdce.campo_pk_id_2                                            
    ele_prime_note_lib_miss.code_miss_lib,
	ele_prime_note_lib_miss.desc_miss_lib,
    ele_prime_note_lib_programma.code_progr_lib,
	ele_prime_note_lib_programma.desc_progr_lib,
	pdce.movep_det_id, pdce.causale_ep_tipo_code, pdce.pnota_id, pdce.pnota_numero,  pdce.pnota_progressivogiornale,
    --SIAC-8698 21/04/2022. Aggiungo questi campi.
    pdce.campo_pk_id, pdce.campo_pk_id_2
from classificatori
	inner join pdce
    	ON pdce.classif_id = classificatori.classif_id     
  LEFT   JOIN collegamento_MMGS_MMGE_a ON collegamento_MMGS_MMGE_a.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE') 
  LEFT   JOIN collegamento_MMGS_MMGE_b ON collegamento_MMGS_MMGE_b.mod_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('MMGS','MMGE')
  LEFT   JOIN collegamento_I_A ON collegamento_I_A.movgest_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('I','A')
  LEFT   JOIN collegamento_SI_SA ON collegamento_SI_SA.movgest_ts_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SI','SA')                                     
  LEFT   JOIN collegamento_SS_SE ON collegamento_SS_SE.subdoc_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('SS','SE')
  LEFT   JOIN collegamento_OP_OI ON collegamento_OP_OI.ord_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code IN ('OP','OI')
  LEFT   JOIN collegamento_L ON collegamento_L.liq_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'L'
  LEFT   JOIN collegamento_RR ON collegamento_RR.gst_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RR'
  LEFT   JOIN collegamento_RE ON collegamento_RE.ricecon_id = pdce.campo_pk_id
                                       AND pdce.collegamento_tipo_code = 'RE'
  --collegamento per note di credito. Si usa campo_pk_id_2
  LEFT	 JOIN collegamento_SS_SE_NCD ON collegamento_SS_SE_NCD.subdoc_id = pdce.campo_pk_id_2
  										AND pdce.collegamento_tipo_code IN ('SS','SE')                
  LEFT JOIN ele_prime_note_lib_miss ON ele_prime_note_lib_miss.movep_det_id=pdce.movep_det_id
  LEFT JOIN ele_prime_note_lib_programma ON ele_prime_note_lib_programma.movep_det_id=pdce.movep_det_id
 ) query_totale
on missioni.elem_id =query_totale.elem_id  
where COALESCE(query_totale.code_miss_lib,'') <> '' OR
	COALESCE(missioni.code_missione,'')  <> ''
order by 1;

RTN_MESSAGGIO:='Fine estrazione dei dati''.';
raise notice 'ora: % ',clock_timestamp()::varchar;



exception
	when no_data_found THEN
		raise notice 'Nessun dato trovato' ;
		return;
	when others  THEN
 		RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$function$
;



CREATE OR REPLACE FUNCTION siac.fnc_siac_dwh_contabilita_generale(p_anno_bilancio character varying, p_ente_proprietario_id integer, p_data timestamp without time zone)
 RETURNS TABLE(esito character varying)
 LANGUAGE plpgsql
 SECURITY DEFINER
AS $function$
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

v_user_table varchar;
params varchar;

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

select fnc_siac_random_user()
into	v_user_table;

params := p_anno_bilancio||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;


insert into
siac_dwh_log_elaborazioni (
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values (
p_ente_proprietario_id,
'fnc_siac_dwh_contabilita_generale',
params,
clock_timestamp(),
v_user_table
);

esito:= 'Inizio funzione carico dati contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;

esito:= '  Inizio eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;
DELETE FROM siac.siac_dwh_contabilita_generale
WHERE ente_proprietario_id = p_ente_proprietario_id
AND   bil_anno = p_anno_bilancio;
esito:= '  Fine eliminazione dati pregressi - '||clock_timestamp();
RETURN NEXT;

insert into siac_dwh_contabilita_generale

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
from
(
-- documenti
select tbdoc.*
from
(
  with
  movep as
  (
   select distinct
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
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id  -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null,   -- SIAC-5696 FINE  */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
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
          r.causale_ep_tipo_id=q.causale_ep_tipo_id and
          s.causale_ep_id=q.causale_ep_id AND -- SIAC-5941 -- SIAC-5696
          s.causale_ep_stato_id=t.causale_ep_stato_id and -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
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
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL AND
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
          (q.data_cancellazione IS NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
               ) -- SIAC-5696 FINE
          and d.collegamento_tipo_code in ('SE','SS')
          and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with
    aa as
    (
	  select a.movep_id,
             b.pdce_conto_id,
	         a.movep_det_code cod_mov_ep_dettaglio,a.movep_det_desc desc_mov_ep_dettaglio,
		     a.movep_det_importo importo_mov_ep,a.movep_det_segno segno_mov_ep,
			 b.pdce_conto_code cod_piano_dei_conti,
		     b.pdce_conto_desc desc_piano_dei_conti,
	         b.livello livello_piano_dei_conti,
		     b.ordine ordine_piano_dei_conti,
		     d.pdce_fam_code cod_pdce_fam,
			 d.pdce_fam_desc desc_pdce_fam,
 		     e.ambito_code cod_ambito, e.ambito_desc desc_ambito
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id= p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
	  and   a.data_cancellazione is null
--	  and   b.data_cancellazione is null -- 27.06.2018 Sofia jira siac-6282
	  and   c.data_cancellazione is null
	  and   d.data_cancellazione is null
	  and   e.data_cancellazione is null
   ),
   bb as
   (
   SELECT c.pdce_conto_id,
         case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
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
   WHERE b.classif_id = a.classif_id
   AND   c.pdce_conto_id = b.pdce_conto_id
   and   c.ente_proprietario_id= p_ente_proprietario_id
--   and   c.data_cancellazione is null -- 27.06.2018 Sofia jira siac-6282
   and   b.data_cancellazione is NULL
   and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
  from aa
       left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  doc as
  (with
   aa as
   (
	select a.doc_id,
		   b.subdoc_id, b.subdoc_numero  num_subdoc,
		   a.doc_anno anno_doc,
		   a.doc_numero num_doc,
	       a.doc_data_emissione data_emissione_doc ,
		   c.doc_tipo_code cod_tipo_doc
	 from siac_t_doc a,siac_t_subdoc b,siac_d_doc_tipo c
	 where b.doc_id=a.doc_id
     and   a.ente_proprietario_id=p_ente_proprietario_id
     and   c.doc_tipo_id=a.doc_tipo_id
     and   a.data_cancellazione is null
     and   b.data_cancellazione is null
     and   c.data_cancellazione is NULL
   ),
   bb as
  (SELECT  a.doc_id,
           b.soggetto_code v_soggetto_code
   FROM   siac_r_doc_sog a, siac_t_soggetto b
   WHERE a.soggetto_id = b.soggetto_id
     and a.ente_proprietario_id=p_ente_proprietario_id
     and a.data_cancellazione is null
     and b.data_cancellazione is null
     and a.validita_fine is null
  )
  select -- SIAC-5573
         -- *
         aa.*,
         bb.v_soggetto_code
  From aa left join bb ON aa.doc_id=bb.doc_id
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
         b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
        null::integer anno_movimento,
        null::numeric numero_movimento,
        null::varchar cod_submovimento,
        null::integer anno_ordinativo,
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
          case when movep.cod_tipo_mov_finanziario = 'SE' then 'E' else 'U' end
		  else  pdc.entrate_uscite
		end entrate_uscite,
       -- pdc.entrate_uscite,
       p_data data_elaborazione,
       null::integer numero_ricecon
    from movep
         left join movepdet on movep.movep_id=movepdet.movep_id
         left join doc      on movep.campo_pk_id=doc.subdoc_id
         left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbdoc
-- impegni
UNION
select tbimp.*
from
(
-- imp
with
movep as
(
  select distinct
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
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE   */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE  a.ente_proprietario_id=p_ente_proprietario_id
    and    i.anno=p_anno_bilancio
    and    a.regmovfin_id = b.regmovfin_id
    and    c.evento_id = b.evento_id
    AND    d.collegamento_tipo_id = c.collegamento_tipo_id
    AND    g.evento_tipo_id = c.evento_tipo_id
    AND    e.regmovfin_id = a.regmovfin_id
    AND    f.regmovfin_stato_id = e.regmovfin_stato_id
    AND    p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and    p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
          --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
          --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
          --p_data >= n.validita_inizio AND  p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id  -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL
    AND   n.data_cancellazione IS NULL
    AND   o.data_cancellazione IS NULL
    AND   p.data_cancellazione IS NULL
    --q.data_cancellazione IS NULL AND -- SIAC-5696
    and   r.data_cancellazione IS NULL
    --s.data_cancellazione IS NULL AND -- SIAC-5696
    --t.data_cancellazione IS NULL -- SIAC-5696
    and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
         ) -- SIAC-5696 FINE
    and d.collegamento_tipo_code in ('A','I')
    and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with aa as
    (
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
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
        and b.pdce_conto_id=a.pdce_conto_id
        and c.pdce_fam_tree_id=b.pdce_fam_tree_id
        and d.pdce_fam_id=c.pdce_fam_id
        and c.validita_fine is null
        and e.ambito_id=a.ambito_id
        and a.data_cancellazione is null
--        and b.data_cancellazione is null 27.06.2018 Sofia Jira siac-6282
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and e.data_cancellazione is null
   ),
   bb as
   ( /*SELECT c.pdce_conto_id,
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
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
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
    WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
    and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
	and   b.data_cancellazione is NULL
	and   b.validita_fine is null
   )
   select aa.*,
          bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
   from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  imp as
  (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento
  from siac_t_movgest a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
  ),
  pdc as
  (select distinct a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and   a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.*,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
         imp.anno_movimento,imp.numero_movimento,
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
	     case -- SIAC-5601
		 when movepdet.cod_ambito = 'AMBITO_GSA' then
		      case when movep.cod_tipo_mov_finanziario = 'A' then 'E' else 'U' end
			  else pdc.entrate_uscite
			  end entrate_uscite,
			-- pdc.entrate_uscite,
		p_data data_elaborazione,
		null::integer numero_ricecon
 from movep
      left join movepdet on movep.movep_id=movepdet.movep_id
      left join imp on movep.campo_pk_id=imp.movgest_id
      left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbimp

UNION
--subimp subacc
select tbimp.*
from
(
-- imp
with
movep as
(
  select distinct
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
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE  */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
     --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
     --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
     -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id -- SIAC-5941 -- SIAC-5696
          --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL AND
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
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL AND
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
          (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
               )-- SIAC-5696 FINE
          and d.collegamento_tipo_code in ('SA','SI')
          and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
               )  -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with aa as
    (
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
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
	    and b.pdce_conto_id=a.pdce_conto_id
        and c.pdce_fam_tree_id=b.pdce_fam_tree_id
        and d.pdce_fam_id=c.pdce_fam_id
        and c.validita_fine is null
        and e.ambito_id=a.ambito_id
        and a.data_cancellazione is null
    --    and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
        and c.data_cancellazione is null
        and d.data_cancellazione is null
        and e.data_cancellazione is null
    ),
    bb as
    ( /*SELECT c.pdce_conto_id,
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
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
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
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
	and   b.data_cancellazione is NULL
	and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
  from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  subimp as
  (
  select a.movgest_id,a.movgest_anno anno_movimento,a.movgest_numero numero_movimento,
  		 b.movgest_ts_id,b.movgest_ts_code cod_submovimento
  from siac_t_movgest a,siac_T_movgest_ts b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
  and   b.data_cancellazione is null
  and   b.movgest_id=a.movgest_id
  ),
  pdc as
  (select distinct
          a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and a.data_cancellazione is null
  -- and b.data_cancellazione is null
   and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
       )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario, subimp.anno_movimento,
		 subimp.numero_movimento,
		 subimp.cod_submovimento,
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
		 case -- SIAC-5601
          when movepdet.cod_ambito = 'AMBITO_GSA' then
		       case when movep.cod_tipo_mov_finanziario = 'SA' then 'E' else 'U' end
		  else pdc.entrate_uscite
		  end entrate_uscite,
		  -- pdc.entrate_uscite,
		  p_data data_elaborazione,
		  null::integer numero_ricecon
   from movep
        left join movepdet on movep.movep_id=movepdet.movep_id
		left join subimp   on movep.campo_pk_id=subimp.movgest_ts_id
        left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbimp

-- ordinativi
union
select tbord.*
from
(
-- ord
with movep as
(
  select distinct
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
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE    */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
    --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
    --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
    -- SIAC-5941 -- SIAC-5696          s.causale_ep_stato_id=t.causale_ep_stato_id and -- SIAC-5941 -- SIAC-5696
     --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL
    AND   b.data_cancellazione IS NULL
    AND   c.data_cancellazione IS NULL
    AND   d.data_cancellazione IS NULL
    AND   e.data_cancellazione IS NULL
    AND   f.data_cancellazione IS NULL
    AND   g.data_cancellazione IS NULL
    AND   h.data_cancellazione IS NULL
    AND   i.data_cancellazione IS NULL
    AND   l.data_cancellazione IS NULL
    AND   m.data_cancellazione IS NULL
    AND   n.data_cancellazione IS NULL
    AND   o.data_cancellazione IS NULL
    AND   p.data_cancellazione IS NULL
    --q.data_cancellazione IS NULL AND -- SIAC-5696
    and r.data_cancellazione IS NULL
    --s.data_cancellazione IS NULL AND -- SIAC-5696
    --t.data_cancellazione IS NULL -- SIAC-5696
   and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
        )
  -- SIAC-5696 FINE
  and d.collegamento_tipo_code in ('OI', 'OP')
  and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
       )  -- SIAC-5941 Integrazione FINE
 ),
 movepdet as
 (
  with aa as
  (
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
  From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
  where a.ente_proprietario_id=p_ente_proprietario_id
    and b.pdce_conto_id=a.pdce_conto_id
    and c.pdce_fam_tree_id=b.pdce_fam_tree_id
    and d.pdce_fam_id=c.pdce_fam_id
    and c.validita_fine is null
    and e.ambito_id=a.ambito_id
    and a.data_cancellazione is null
 --   and b.data_cancellazione is null 27.06.2018 Sofia Jira siac-6282
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 bb as
 (/* SELECT c.pdce_conto_id,
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
  SELECT c.pdce_conto_id,
  	  	 case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
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
  WHERE b.classif_id = a.classif_id
  AND   c.pdce_conto_id = b.pdce_conto_id
  and   c.ente_proprietario_id=p_ente_proprietario_id
  --and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
  and   b.data_cancellazione is NULL
  and   b.validita_fine is null
 )
 select aa.*,
       bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
 from aa left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
 ),
 ord as
 (select a.ord_id,a.ord_anno anno_ordinativo,a.ord_numero num_ordinativo
  from siac_t_ordinativo a
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   a.data_cancellazione is null
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		 b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
/*  ,liq as (select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione from siac_t_liquidazione a where a.ente_proprietario_id=3
and a.data_cancellazione is null)  */
   select movep.*,
          movepdet.* ,
          pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
		  null::integer anno_movimento,null::numeric numero_movimento,
          null::varchar cod_submovimento,
          ord.anno_ordinativo,
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
                   case when movep.cod_tipo_mov_finanziario = 'OI' then 'E' else 'U' end
				   else pdc.entrate_uscite
				   end entrate_uscite,
				   -- pdc.entrate_uscite,
			 p_data data_elaborazione,
		     null::integer numero_ricecon
	   from movep
            left join movepdet on movep.movep_id=movepdet.movep_id
            left join ord on movep.campo_pk_id=ord.ord_id
            left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbord

-- liquidazioni
UNION
-- liq
select tbliq.*
from
(
with movep as
(
  select distinct
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
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE   */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
    --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
    --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
    --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id -- SIAC-5941 -- SIAC-5696
    and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
    --s.validita_fine is NULL and -- SIAC-5696
    and   o.pnota_stato_code <> 'A'
    and   a.data_cancellazione IS NULL AND
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
          --q.data_cancellazione IS NULL AND -- SIAC-5696
          r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
    and   (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
          )-- SIAC-5696 FINE
    and d.collegamento_tipo_code ='L'
    and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
         )  -- SIAC-5941 Integrazione FINE
 ),
 movepdet as
 (
	with aa as
    (
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
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
      and   a.data_cancellazione is null
--      and   b.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
	  and   c.data_cancellazione is null
	  and   d.data_cancellazione is null
	  and   e.data_cancellazione is null
     ),
     bb as
     ( /*SELECT c.pdce_conto_id,
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
	SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
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
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and   b.data_cancellazione is NULL
    and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
  from aa
       left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
 ),
 liq as
 (
   select a.liq_id,a.liq_anno anno_liquidazione,a.liq_numero num_liquidazione
   from siac_t_liquidazione a
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   a.data_cancellazione is null
 ),
 pdc as
 (select distinct
         a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
         b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
  from siac_t_class a,siac_r_causale_ep_class b
  where a.ente_proprietario_id=p_ente_proprietario_id
  and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
 )
 select movep.*,
        movepdet.* ,
        pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
        null::integer anno_movimento,
        null::numeric numero_movimento,
        null::varchar cod_submovimento,
        null::integer anno_ordinativo,
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
                 case when movep.cod_tipo_mov_finanziario = 'L' then 'U'  else  'E' end
        else pdc.entrate_uscite
        end entrate_uscite,
        -- pdc.entrate_uscite,
	    p_data data_elaborazione,
		null::integer numero_ricecon
  from movep
       left join  movepdet on movep.movep_id=movepdet.movep_id
       left join liq  on movep.campo_pk_id=liq.liq_id
       left join pdc  on movep.causale_ep_id=pdc.causale_ep_id
) as tbliq


union
--richiesta econ
select tbricecon.*
from
(
 with
 movep as
 (
  select distinct
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
/*         left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE    */
         siac_r_causale_ep_stato s, -- SIAC-5941
         siac_d_causale_ep_stato t, -- SIAC-5941
         siac_d_causale_ep_tipo r
    WHERE a.ente_proprietario_id=p_ente_proprietario_id
    and   i.anno=p_anno_bilancio
    and   a.regmovfin_id = b.regmovfin_id
    and   c.evento_id = b.evento_id
    AND   d.collegamento_tipo_id = c.collegamento_tipo_id
    AND   g.evento_tipo_id = c.evento_tipo_id
    AND   e.regmovfin_id = a.regmovfin_id
    AND   f.regmovfin_stato_id = e.regmovfin_stato_id
    AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
    and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
   --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
  --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
    and   h.bil_id = a.bil_id
    AND   i.periodo_id = h.periodo_id
    AND   l.regmovfin_id = a.regmovfin_id
    AND   l.regep_id = m.pnota_id
    AND   m.pnota_id = n.pnota_id
    AND   o.pnota_stato_id = n.pnota_stato_id
    AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
   --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
    and   p.ente_proprietario_id=a.ente_proprietario_id
    and   q.causale_ep_id=l.causale_ep_id
    AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
    and   s.causale_ep_id=q.causale_ep_id
    -- SIAC-5941 -- SIAC-5696
    and  s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
    --s.validita_fine is NULL and -- SIAC-5696
    and  o.pnota_stato_code <> 'A'
    and  a.data_cancellazione IS NULL AND
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
         --q.data_cancellazione IS NULL AND -- SIAC-5696
         r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
     and  (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
          )-- SIAC-5696 FINE
--     and d.collegamento_tipo_code ='RE'
     and d.collegamento_tipo_code IN ('RE','RR') -- SIAC-8717 Sofia 12.05.2022
     and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
          )   -- SIAC-5941 Integrazione FINE
  ),
  movepdet as
  (
	with
    aa as
    (
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
      From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
      where a.ente_proprietario_id=p_ente_proprietario_id
      and   b.pdce_conto_id=a.pdce_conto_id
      and   c.pdce_fam_tree_id=b.pdce_fam_tree_id
      and   d.pdce_fam_id=c.pdce_fam_id
      and   c.validita_fine is null
      and   e.ambito_id=a.ambito_id
      and a.data_cancellazione is null
   --   and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
      and c.data_cancellazione is null
      and d.data_cancellazione is null
      and e.data_cancellazione is null
    ),
    bb as
    ( /*SELECT c.pdce_conto_id,
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
    SELECT c.pdce_conto_id,
           case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
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
	WHERE b.classif_id = a.classif_id
    AND   c.pdce_conto_id = b.pdce_conto_id
	and   c.ente_proprietario_id=p_ente_proprietario_id
--	and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and   b.data_cancellazione is NULL
    and   b.validita_fine is null
  )
  select aa.*,
         bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
   from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
  ),
  ricecon as
  (select a.ricecon_id,
          a.ricecon_numero numero_ricecon
   from siac_t_richiesta_econ a
   where a.ente_proprietario_id=p_ente_proprietario_id
    and  a.data_cancellazione is null
  ),
  pdc as
  (
   select distinct
          a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
		  b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
   from siac_t_class a,siac_r_causale_ep_class b
   where a.ente_proprietario_id=p_ente_proprietario_id
   and   b.classif_id=a.classif_id
  -- and b.validita_fine is null
   and   a.data_cancellazione is null
  -- and b.data_cancellazione is null
   and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
  )
  select movep.*,
         movepdet.* ,
         pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
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
		 case -- SIAC-5601
		  when movepdet.cod_ambito = 'AMBITO_GSA' then
	       case when movep.cod_tipo_mov_finanziario = 'RE' then 'U' else 'E' end
		  else pdc.entrate_uscite
		  end entrate_uscite,
		  -- pdc.entrate_uscite,
		 p_data data_elaborazione,
	     ricecon.numero_ricecon
   from movep
        left join movepdet on movep.movep_id=movepdet.movep_id
        left join ricecon  on movep.campo_pk_id=ricecon.ricecon_id
        left join pdc      on movep.causale_ep_id=pdc.causale_ep_id
) as tbricecon

union
-- mod
select tbmod.*
from
(
 with
 movep as
 (
  select distinct
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
/*        left join siac_r_causale_ep_stato s on s.causale_ep_id=q.causale_ep_id -- SIAC-5696 INIZIO
                                             and s.data_cancellazione is null
                                             and s.validita_fine is null
         left join siac_d_causale_ep_stato t on s.causale_ep_stato_id=t.causale_ep_stato_id
                                             and t.data_cancellazione is null, -- SIAC-5696 FINE  */
        siac_r_causale_ep_stato s, -- SIAC-5941
        siac_d_causale_ep_stato t, -- SIAC-5941
        siac_d_causale_ep_tipo r
   WHERE a.ente_proprietario_id=p_ente_proprietario_id
   and   i.anno=p_anno_bilancio
   and   a.regmovfin_id = b.regmovfin_id
   and   c.evento_id = b.evento_id
   AND   d.collegamento_tipo_id = c.collegamento_tipo_id
   AND   g.evento_tipo_id = c.evento_tipo_id
   AND   e.regmovfin_id = a.regmovfin_id
   AND   f.regmovfin_stato_id = e.regmovfin_stato_id
   AND   p_data BETWEEN b.validita_inizio and COALESCE(b.validita_fine, p_data)
   and   p_data BETWEEN e.validita_inizio and COALESCE(e.validita_fine, p_data)
 --p_data >= b.validita_inizio AND p_data <= COALESCE(b.validita_fine::timestamp with time zone, p_data) AND
 --p_data >= e.validita_inizio AND p_data <= COALESCE(e.validita_fine::timestamp with time zone, p_data) AND
   and   h.bil_id = a.bil_id
   AND   i.periodo_id = h.periodo_id
   AND   l.regmovfin_id = a.regmovfin_id
   AND   l.regep_id = m.pnota_id
   AND   m.pnota_id = n.pnota_id
   AND   o.pnota_stato_id = n.pnota_stato_id
   AND   p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
 --p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
   and   p.ente_proprietario_id=a.ente_proprietario_id
   and   q.causale_ep_id=l.causale_ep_id
   AND   r.causale_ep_tipo_id=q.causale_ep_tipo_id
   and   s.causale_ep_id=q.causale_ep_id -- SIAC-5941 -- SIAC-5696
   and   s.causale_ep_stato_id=t.causale_ep_stato_id  -- SIAC-5941 -- SIAC-5696
 --s.validita_fine is NULL and -- SIAC-5696
   and   o.pnota_stato_code <> 'A'
   and   a.data_cancellazione IS NULL AND
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
        --q.data_cancellazione IS NULL AND -- SIAC-5696
         r.data_cancellazione IS NULL
          --s.data_cancellazione IS NULL AND -- SIAC-5696
          --t.data_cancellazione IS NULL -- SIAC-5696
  and (q.data_cancellazione is NULL -- SIAC-5696 INIZIO
               OR
               q.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
       )-- SIAC-5696 FINE
  and d.collegamento_tipo_code in ('MMGE','MMGS')
  and ((s.data_cancellazione is null and s.validita_fine is null) -- SIAC-5941 Integrazione INIZIO
                or s.causale_ep_stato_id =
               (select d_caus_stato.causale_ep_stato_id
                from   siac_d_causale_ep_stato d_caus_stato
                where  d_caus_stato.causale_ep_stato_id = s.causale_ep_stato_id
                and    d_caus_stato.causale_ep_stato_code = 'V'
                )
       )  -- SIAC-5941 Integrazione FINE
),
movepdet as
(
 with
 aa as
 (
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
  From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c,siac_d_pdce_fam d,siac_d_ambito e
  where a.ente_proprietario_id=p_ente_proprietario_id
    and b.pdce_conto_id=a.pdce_conto_id
    and c.pdce_fam_tree_id=b.pdce_fam_tree_id
    and d.pdce_fam_id=c.pdce_fam_id
    and c.validita_fine is null
    and e.ambito_id=a.ambito_id
    and a.data_cancellazione is null
 --   and b.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
    and c.data_cancellazione is null
    and d.data_cancellazione is null
    and e.data_cancellazione is null
 ),
 bb as
 (
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
 SELECT c.pdce_conto_id,
        case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
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
 WHERE b.classif_id = a.classif_id
 AND   c.pdce_conto_id = b.pdce_conto_id
 and   c.ente_proprietario_id=p_ente_proprietario_id
-- and   c.data_cancellazione is null 27.06.2018 Sofia jira siac-6282
 and   b.data_cancellazione is NULL
 and   b.validita_fine is null
)
select aa.*,
       bb.tipo_codifica||'.'||bb.codice_codifica_albero cod_bilancio
from aa left join  bb on aa.pdce_conto_id=bb.pdce_conto_id
) ,
mod as
(
 select d.mod_id,
 	    c.movgest_anno v_movgest_anno, c.movgest_numero v_movgest_numero,
		b.movgest_ts_code cod_submovimento,
        tsTipo.movgest_ts_tipo_code
 FROM   siac_t_movgest_ts_det_mod a,siac_T_movgest_ts b,
        siac_t_movgest c,siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f,siac_d_movgest_ts_tipo tsTipo
 WHERE a.ente_proprietario_id = p_ente_proprietario_id
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
		 b.movgest_ts_code cod_submovimento,
         tsTipo.movgest_ts_tipo_code
  FROM   siac_r_movgest_ts_sog_mod a,siac_T_movgest_ts b, siac_t_movgest c,
         siac_t_modifica d, siac_r_modifica_stato e, siac_d_modifica_stato f,siac_d_movgest_ts_tipo tsTipo
  WHERE  a.ente_proprietario_id = p_ente_proprietario_id
	and  a.mod_stato_r_id=e.mod_stato_r_id
	and  e.mod_id=d.mod_id
	and  f.mod_stato_id=e.mod_stato_id
	and  a.movgest_ts_id=b.movgest_ts_id
	and  b.movgest_id=c.movgest_id
	AND  p_data BETWEEN a.validita_inizio AND COALESCE(a.validita_fine, p_data)
    AND  p_data BETWEEN e.validita_inizio AND COALESCE(e.validita_fine, p_data)
    AND  a.data_cancellazione IS NULL
    AND  b.data_cancellazione IS NULL
    AND  c.data_cancellazione IS NULL
    AND  d.data_cancellazione IS NULL
    AND  e.data_cancellazione IS NULL
    AND  f.data_cancellazione IS NULL
    AND  tsTipo.movgest_ts_tipo_id = b.movgest_ts_tipo_id
),
pdc as
(
 select distinct a.classif_code cod_piano_finanziario,a.classif_desc desc_piano_finanziario,
	    b.causale_ep_id,SUBSTRING(a.classif_code from 1 for 1) entrate_uscite
 from siac_t_class a,siac_r_causale_ep_class b
 where a.ente_proprietario_id=p_ente_proprietario_id
  and  b.classif_id=a.classif_id
  -- and b.validita_fine is null
  and  a.data_cancellazione is null
  -- and b.data_cancellazione is null
  and (b.data_cancellazione IS NULL -- SIAC-5941 Integrazione
       or
       b.data_cancellazione BETWEEN to_timestamp('01/01/'||p_anno_bilancio, 'dd/mm/yyyy') AND now()
      )
)
select movep.*,
       movepdet.*,--, case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno
       pdc.cod_piano_finanziario,pdc.desc_piano_finanziario,
       mod.v_movgest_anno anno_movimento,mod.v_movgest_numero numero_movimento,
   -- SIAC-5685
   -- mod.cod_submovimento
      case when mod.movgest_ts_tipo_code='T' then null::varchar else mod.cod_submovimento end cod_submovimento,
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
	  case when mod.mod_id is not null then 'S' else 'N' end modifica_impegno,
	  case -- SIAC-5601
	   when movepdet.cod_ambito = 'AMBITO_GSA' then
        case
         when movep.cod_tipo_mov_finanziario = 'MMGE' then 'E' else 'U' end
      else  pdc.entrate_uscite
	  end entrate_uscite,
	  -- pdc.entrate_uscite,
	  p_data data_elaborazione,
	  null::integer numero_ricecon
   from movep
        left join  movepdet on movep.movep_id=movepdet.movep_id
	    left join mod on  movep.campo_pk_id=  mod.mod_id
        left join pdc on movep.causale_ep_id=pdc.causale_ep_id
) as tbmod

--lib
union
select lib.*
from
(
with
movep as
(
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
WHERE m.ente_proprietario_id=p_ente_proprietario_id
and r.causale_ep_tipo_code='LIB'
and i.anno=p_anno_bilancio
and h.bil_id = m.bil_id
AND i.periodo_id = h.periodo_id
AND l.regep_id = m.pnota_id
AND m.pnota_id = n.pnota_id
AND o.pnota_stato_id = n.pnota_stato_id
--p_data >= n.validita_inizio AND p_data <= COALESCE(n.validita_fine::timestamp with time zone, p_data) AND
and p_data BETWEEN n.validita_inizio and COALESCE(n.validita_fine, p_data)
and p.ente_proprietario_id=m.ente_proprietario_id
and q.causale_ep_id=l.causale_ep_id
AND r.causale_ep_tipo_id=q.causale_ep_tipo_id
and s.causale_ep_id=q.causale_ep_id
AND s.causale_ep_stato_id=t.causale_ep_stato_id
and s.validita_fine is NULL
and o.pnota_stato_code <> 'A'
and
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
),
movepdet as
(
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
From siac_t_mov_ep_det a,siac_t_pdce_conto b,siac_t_pdce_fam_tree c ,siac_d_pdce_fam d,siac_d_ambito e
where a.ente_proprietario_id= p_ente_proprietario_id
and b.pdce_conto_id=a.pdce_conto_id
and c.pdce_fam_tree_id=b.pdce_fam_tree_id
and d.pdce_fam_id=c.pdce_fam_id
and c.validita_fine is null
and e.ambito_id=a.ambito_id
and a.data_cancellazione is null
--and b.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
and c.data_cancellazione is null
and d.data_cancellazione is null
and e.data_cancellazione is null
),
bb as
(
SELECT c.pdce_conto_id,
	   case when a.tipo_codifica = 'conto economico (codice di bilancio)' then 'CE'
			when a.tipo_codifica = 'conti d''ordine (codice di bilancio)' then 'CO'
			when a.tipo_codifica = 'stato patrimoniale attivo (codice di bilancio)' then 'SPA'
			when a.tipo_codifica = 'stato patrimoniale passivo (codice di bilancio)' then 'SPP'
			when a.tipo_codifica = 'CE_CODBIL_GSA' then 'CE'     -- SIAC-5551-5579
			when a.tipo_codifica = 'SPA_CODBIL_GSA' then 'SPA'   -- SIAC-5551-5579
			when a.tipo_codifica = 'SPP_CODBIL_GSA' then 'SPP'   -- SIAC-5551-5579
			else ''::varchar end as tipo_codifica,
	a.codice_codifica_albero
FROM siac_v_dwh_codifiche_econpatr a,siac_r_pdce_conto_class b,siac_t_pdce_conto c
WHERE b.classif_id = a.classif_id
AND c.pdce_conto_id = b.pdce_conto_id
and c.ente_proprietario_id=p_ente_proprietario_id
--and c.data_cancellazione is null 28.06.2018 Sofia jira siac-6282
and b.data_cancellazione is NULL
and b.validita_fine is null
)
select aa.*,
	   bb.tipo_codifica||'.'||  bb.codice_codifica_albero cod_bilancio
from aa left join bb on aa.pdce_conto_id=bb.pdce_conto_id
)
select movep.*,
       movepdet.*,
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
from movep left join movepdet on movep.movep_id=movepdet.movep_id
) as lib

) as tb;

esito:= 'Fine funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) - '||clock_timestamp();
RETURN NEXT;


update siac_dwh_contabilita_generale dwh
  set codice_missione = fnc.code_missione,
      descri_missione = fnc.desc_missione,
      codice_programma = fnc.code_programma,
      descri_programma = fnc.desc_programma
from      "fnc_prima_nota_missione_programma"(p_ente_proprietario_id,p_anno_bilancio) fnc 
 where dwh.num_provvisorio_prima_nota  = fnc.pnota_numero 
 and   dwh.num_definitivo_prima_nota = fnc.pnota_progressivogiornale ;



update siac_dwh_log_elaborazioni  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()-fnc_elaborazione_inizio
where fnc_user=v_user_table;


EXCEPTION
WHEN others THEN
  esito:='Funzione carico contabilita_generale (FNC_SIAC_DWH_CONTABILITA_GENERALE) terminata con errori';
  RAISE NOTICE '%-%.',SQLSTATE,SQLERRM;
RETURN;
END;
$function$
;

-- SIAC-8863 Haitham 05.07.2023 fine






-- INIZIO SIAC-8866.sql



\echo SIAC-8866.sql


--SIAC-8866 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."BILR011_allegato_fpv_previsione_con_dati_gestione"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."fnc_lancio_BILR011_anni_precedenti_gestione"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);
DROP FUNCTION if exists siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);

CREATE OR REPLACE FUNCTION siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  spese_da_impeg_non_def_g numeric,
  fondo_plur_anno_h numeric,
  spese_da_impeg_anno1_d2 numeric
) AS
$body$
DECLARE

classifBilRec record;
impegniPrecRec record;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
user_table	varchar;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
id_bil INTEGER;
bilancio_id_prec integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
conflagfpv:=TRUE;
a_dacapfpv:=false;
h_dacapfpv:=false;
flagretrocomp:=false;

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UP'; -- tipo capitolo previsione

annoPrec:=((p_anno::INTEGER)-1)::VARCHAR;
annoProspInt=p_anno_prospetto::INTEGER;
annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

fondo_plur_anno_prec_a=0;
spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
spese_da_impeg_non_def_g=0;
fondo_plur_anno_h=0;

/* 08/03/2019: revisione per SIAC-6623 
	I campi fondo_plur_anno_prec_a, spese_impe_anni_prec_b, quota_fond_plur_anni_prec_c e
    fondo_plur_anno_h anche se valorizzati non sono utilizzati dal report perche'
    prende quelli di gestione calcolati tramite la funzione 
    BILR011_allegato_fpv_previsione_con_dati_gestione (ex BILR171).
*/

/* 25/01/2023: revisione per SIAC-8866.
 La funzione e' stata in parte semplificata perche' erano eseguite piu' volte le stesse query.
 Inoltre sono state introdotte le modifiche richieste nelle jira SIAC-8866 per le colonne D, E, F.


*/
select t_bil.bil_id
	into id_bil
from siac_t_bil t_bil,
	siac_t_periodo t_periodo
where t_bil.periodo_id=t_periodo.periodo_id
	and t_bil.ente_proprietario_id = p_ente_prop_id
    and t_periodo.anno= p_anno    
    and t_bil.data_cancellazione IS NULL
    and t_periodo.data_cancellazione IS NULL;
IF NOT FOUND THEN
	raise notice 'Codice del bilancio non trovato';
    return;
END IF;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,
	siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno::integer = (p_anno::integer - 1)
 and a.data_cancellazione IS NULL
 and b.data_cancellazione IS NULL;

raise notice 'id_bil di anno % = %', p_anno, id_bil;
raise notice 'id_bil di anno precedente % = %', (p_anno::integer - 1), bilancio_id_prec;

for classifBilRec in
	with strutt_capitoli as (select *
		from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id,p_anno,'')),
	capitoli as (select programma.classif_id programma_id,
		macroaggr.classif_id macroag_id,
       	capitolo.*
	from siac_d_class_tipo programma_tipo,
     	siac_t_class programma,
     	siac_d_class_tipo macroaggr_tipo,
     	siac_t_class macroaggr,
	 	siac_t_bil_elem capitolo,
	 	siac_d_bil_elem_tipo tipo_elemento,
     	siac_r_bil_elem_class r_capitolo_programma,
     	siac_r_bil_elem_class r_capitolo_macroaggr, 
	 	siac_d_bil_elem_stato stato_capitolo, 
     	siac_r_bil_elem_stato r_capitolo_stato,
	 	siac_d_bil_elem_categoria cat_del_capitolo,
     	siac_r_bil_elem_categoria r_cat_capitolo
	where macroaggr.classif_tipo_id=macroaggr_tipo.classif_tipo_id 				and
    	macroaggr.classif_id=r_capitolo_macroaggr.classif_id					and
    	programma.classif_tipo_id=programma_tipo.classif_tipo_id 				and
    	programma.classif_id=r_capitolo_programma.classif_id					and    		       
    	capitolo.elem_id=r_capitolo_programma.elem_id							and
    	capitolo.elem_id=r_capitolo_macroaggr.elem_id							and
   		capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 						and
    	capitolo.elem_id				=	r_capitolo_stato.elem_id			and
		r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id		and
    	capitolo.elem_id				=	r_cat_capitolo.elem_id				and
		r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id		and
        capitolo.ente_proprietario_id=p_ente_prop_id      						and
        capitolo.bil_id= id_bil													and   	
    	tipo_elemento.elem_tipo_code = elemTipoCode						     	and 
    	macroaggr_tipo.classif_tipo_code='MACROAGGREGATO'						and
    	programma_tipo.classif_tipo_code='PROGRAMMA' 							and	        
		stato_capitolo.elem_stato_code	=	'VA'								and    
			--04/08/2016: aggiunto FPVC 
		cat_del_capitolo.elem_cat_code	in	('FPV','FPVC')								
    	and	now() between programma.validita_inizio and coalesce (programma.validita_fine, now()) 
		and	now() between macroaggr.validita_inizio and coalesce (macroaggr.validita_fine, now())
      	and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
        and	now() between programma_tipo.validita_inizio and coalesce (programma_tipo.validita_fine, now())
        and	now() between macroaggr_tipo.validita_inizio and coalesce (macroaggr_tipo.validita_fine, now())
        and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
        and	now() between r_capitolo_programma.validita_inizio and coalesce (r_capitolo_programma.validita_fine, now())
        and	now() between r_capitolo_macroaggr.validita_inizio and coalesce (r_capitolo_macroaggr.validita_fine, now())
        and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
        and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
        and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
        and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())        
        and	programma_tipo.data_cancellazione 			is null
        and	programma.data_cancellazione 				is null
        and	macroaggr_tipo.data_cancellazione 			is null
        and	macroaggr.data_cancellazione 				is null
        and	capitolo.data_cancellazione 				is null
        and	tipo_elemento.data_cancellazione 			is null
        and	r_capitolo_programma.data_cancellazione 	is null
        and	r_capitolo_macroaggr.data_cancellazione 	is null 
        and	stato_capitolo.data_cancellazione 			is null 
        and	r_capitolo_stato.data_cancellazione 		is null
        and	cat_del_capitolo.data_cancellazione 		is null
        and	r_cat_capitolo.data_cancellazione 			is null),
    importi_capitoli_anno1 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno1      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp --p_anno       		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null            
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno),
	importi_capitoli_anno2 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno2      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where  	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id            
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and	capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp1 --p_anno +1      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
    		capitolo_imp_periodo.anno),
    importi_capitoli_anno3 as (select 		capitolo_importi.elem_id,
                capitolo_imp_periodo.anno 				BIL_ELE_IMP_ANNO,
                capitolo_imp_tipo.elem_det_tipo_code 	TIPO_IMP,
                sum(capitolo_importi.elem_det_importo) stanziamento_fpv_anno3      
    from 		siac_t_bil_elem_det 		capitolo_importi,
                siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
                siac_t_periodo 				capitolo_imp_periodo,
                siac_t_bil_elem 			capitolo,
                siac_d_bil_elem_tipo 		tipo_elemento,                 
                siac_d_bil_elem_stato 		stato_capitolo, 
                siac_r_bil_elem_stato 		r_capitolo_stato,
                siac_d_bil_elem_categoria 	cat_del_capitolo,
                siac_r_bil_elem_categoria 	r_cat_capitolo
        where 	capitolo.elem_id	=	capitolo_importi.elem_id 
            and	capitolo.elem_tipo_id=tipo_elemento.elem_tipo_id 
            and	capitolo_importi.elem_det_tipo_id=capitolo_imp_tipo.elem_det_tipo_id 		
            and	capitolo_imp_periodo.periodo_id=capitolo_importi.periodo_id 	
            and	capitolo.elem_id				=	r_capitolo_stato.elem_id			
            and	r_capitolo_stato.elem_stato_id	=	stato_capitolo.elem_stato_id
            and	capitolo.elem_id				=	r_cat_capitolo.elem_id				
            and	r_cat_capitolo.elem_cat_id		=	cat_del_capitolo.elem_cat_id
            and capitolo_importi.ente_proprietario_id 	=p_ente_prop_id  
            and capitolo.bil_id					= id_bil					
            and	tipo_elemento.elem_tipo_code = elemTipoCode   
            and capitolo_imp_tipo.elem_det_tipo_code = TipoImpComp    --'STA' 			  
            and	capitolo_imp_periodo.anno = annoCapImp2 --p_anno +2      		
            and	stato_capitolo.elem_stato_code	=	'VA'								        		
            	--04/08/2016: aggiunto FPVC
            and	cat_del_capitolo.elem_cat_code	in(	'FPV','FPVC')							
            and	now() between capitolo_importi.validita_inizio and coalesce (capitolo_importi.validita_fine, now())
            and	now() between capitolo_imp_periodo.validita_inizio and coalesce (capitolo_imp_periodo.validita_fine, now())
            and	now() between capitolo_imp_tipo.validita_inizio and coalesce (capitolo_imp_tipo.validita_fine, now())
            and	now() between capitolo.validita_inizio and coalesce (capitolo.validita_fine, now())
            and	now() between tipo_elemento.validita_inizio and coalesce (tipo_elemento.validita_fine, now())
            and	now() between stato_capitolo.validita_inizio and coalesce (stato_capitolo.validita_fine, now())
            and	now() between r_capitolo_stato.validita_inizio and coalesce (r_capitolo_stato.validita_fine, now())
            and	now() between cat_del_capitolo.validita_inizio and coalesce (cat_del_capitolo.validita_fine, now())
            and	now() between r_cat_capitolo.validita_inizio and coalesce (r_cat_capitolo.validita_fine, now())
            and	capitolo_importi.data_cancellazione 		is null
            and	capitolo_imp_tipo.data_cancellazione 		is null
            and	capitolo_imp_periodo.data_cancellazione 	is null
            and	capitolo.data_cancellazione 				is null
            and	tipo_elemento.data_cancellazione 			is null
            and	stato_capitolo.data_cancellazione 			is null 
            and	r_capitolo_stato.data_cancellazione 		is null
            and cat_del_capitolo.data_cancellazione 		is null
            and	r_cat_capitolo.data_cancellazione 			is null
        group by	capitolo_importi.elem_id,capitolo_imp_tipo.elem_det_tipo_code,
            capitolo_imp_periodo.anno)            
    select strutt_capitoli.missione_tipo_desc			missione_tipo_desc,
		strutt_capitoli.missione_code				missione_code,
		strutt_capitoli.missione_desc				missione_desc,
		strutt_capitoli.programma_tipo_desc			programma_tipo_desc,
		strutt_capitoli.programma_code				programma_code,
		strutt_capitoli.programma_desc				programma_desc,
        COALESCE(SUM(importi_capitoli_anno1.stanziamento_fpv_anno1),0) stanziamento_fpv_anno1,
        COALESCE(SUM(importi_capitoli_anno2.stanziamento_fpv_anno2),0) stanziamento_fpv_anno2,
        COALESCE(SUM(importi_capitoli_anno3.stanziamento_fpv_anno3),0) stanziamento_fpv_anno3,
        0 fondo_pluri_anno_prec
    from  strutt_capitoli 
        left join capitoli 
            on (capitoli.programma_id = strutt_capitoli.programma_id
                AND capitoli.macroag_id = strutt_capitoli.macroag_id)          
        left join importi_capitoli_anno1
            on importi_capitoli_anno1.elem_id = capitoli.elem_id
        left join importi_capitoli_anno2
            on importi_capitoli_anno2.elem_id = capitoli.elem_id
        left join importi_capitoli_anno3
            on importi_capitoli_anno3.elem_id = capitoli.elem_id
--27/12/2021 SIAC-8508
-- Occorre eliminare le missioni '20', '50', '60', '99'.             
    where strutt_capitoli.missione_code not in('20', '50', '60', '99')
    group by strutt_capitoli.missione_tipo_desc, strutt_capitoli.missione_code, 
    	strutt_capitoli.missione_desc, strutt_capitoli.programma_tipo_desc, 
        strutt_capitoli.programma_code, strutt_capitoli.programma_desc
loop
	missione_tipo_desc:= classifBilRec.missione_tipo_desc;
    missione_code:= classifBilRec.missione_code;
    missione_desc:= classifBilRec.missione_desc;
    programma_tipo_desc:= classifBilRec.programma_tipo_desc;
    programma_code:= classifBilRec.programma_code;
    programma_desc:= classifBilRec.programma_desc;

    bil_anno:=p_anno;
    
    if annoProspInt = annoBilInt then
		fondo_plur_anno_prec_a=classifBilRec.fondo_pluri_anno_prec;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno1;
   	elsif  annoProspInt = annoBilInt+1 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno1;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno2;
    elsif  annoProspInt = annoBilInt+2 and a_dacapfpv=true then
    	fondo_plur_anno_prec_a=classifBilRec.stanziamento_fpv_anno2;
        fondo_plur_anno_h=classifBilRec.stanziamento_fpv_anno3;
    end if;      
    

	   		--il campo spese_impe_anni_prec_b non viene piu' calcolato in questa
            --procedura.
         
          /*select COALESCE(sum(e.cronop_elem_det_importo),0) into
          spese_impe_anni_prec_b
          from siac_t_programma pr, siac_t_cronop a, 
          siac_t_bil b, siac_t_periodo c,
          siac_t_cronop_elem d, siac_d_bil_elem_tipo dt,
          siac_t_cronop_elem_det e, siac_t_periodo f,
          siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
          siac_r_cronop_stato stc , siac_d_cronop_stato stct,
          siac_r_programma_stato stpr, siac_d_programma_stato stprt
          where pr.ente_proprietario_id=p_ente_prop_id 
          and pr.programma_id=a.programma_id
          and a.bil_id = b.bil_id
          and b.periodo_id=c.periodo_id
          and c.anno = p_anno -- anno bilancio
          and a.usato_per_fpv::boolean = conflagfpv
          and d.cronop_id=a.cronop_id
          and d.cronop_elem_id=e.cronop_elem_id
          and dt.elem_tipo_id=d.elem_tipo_id
          and e.anno_entrata::integer < p_anno_prospetto::integer -- anno prospetto  
          and e.periodo_id = f.periodo_id
          and f.anno=p_anno_prospetto -- anno prospetto
          and rcl2.cronop_elem_id = d.cronop_elem_id
          and rcl2.classif_id=cl2.classif_id
          and cl2.classif_tipo_id=clt2.classif_tipo_id
          and clt2.classif_tipo_code='PROGRAMMA'
          and cl2.classif_code=classifBilRec.programma_code
          and stc.cronop_id=a.cronop_id
          and stc.cronop_stato_id=stct.cronop_stato_id
          and stct.cronop_stato_code='VA'
          and stpr.programma_id=pr.programma_id
          and stpr.programma_stato_id=stprt.programma_stato_id
          and stprt.programma_stato_code='VA'
          and stpr.data_cancellazione is null
          and stc.data_cancellazione is null
          and a.data_cancellazione is null
          and pr.data_cancellazione is null
          and b.data_cancellazione is null
          and c.data_cancellazione is null
          and d.data_cancellazione is null
          and e.data_cancellazione is null
          and rcl2.data_cancellazione is null;*/
          
         -- raise notice 'spese_impe_anni_prec_b %' , spese_impe_anni_prec_b; 
        
        /* 3.	Colonna (c) – e' data dalla differenza tra la colonna b e la colonna a genera e
        rappresenta il valore del fondo costituito che verra' utilizzato negli anni 2018 e seguenti; */
        quota_fond_plur_anni_prec_c=fondo_plur_anno_prec_a-spese_impe_anni_prec_b ;  
       -- raise notice 'quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;  
        
        /*
        Colonna D – Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata = anno Prospetto e anno di spesa uguale a anno Prospetto+1.
        25/01/2023 SIAC-8866: i progetti devono essere solo quelli di Previsione.
        */
        
         
          select COALESCE(sum(cronop_elem_det.cronop_elem_det_importo),0) 
          	into spese_da_impeg_anno1_d
          from siac_t_programma progetto, siac_t_cronop crono, 
              siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
              siac_t_cronop_elem cronop_elem, siac_d_bil_elem_tipo tipo_cap,
              siac_t_cronop_elem_det cronop_elem_det, siac_t_periodo anno_crono, 
              siac_r_cronop_elem_class r_cronop_elem_class, siac_d_class_tipo d_class_tipo, siac_t_class class,
              siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
              siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato
          where progetto.programma_id=crono.programma_id
              and crono.bil_id = bil.bil_id
              and bil.periodo_id=anno_bil.periodo_id
              and tipo_prog.programma_tipo_id = progetto.programma_tipo_id
              and cronop_elem.cronop_id=crono.cronop_id
              and cronop_elem.cronop_elem_id=cronop_elem_det.cronop_elem_id
              and tipo_cap.elem_tipo_id=cronop_elem.elem_tipo_id
              and cronop_elem_det.periodo_id = anno_crono.periodo_id
              and r_cronop_elem_class.cronop_elem_id = cronop_elem.cronop_elem_id
              and r_cronop_elem_class.classif_id=class.classif_id
              and class.classif_tipo_id=d_class_tipo.classif_tipo_id
              and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
              and r_cronop_stato.cronop_id=crono.cronop_id
              and r_progetto_stato.programma_id=progetto.programma_id
              and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id              
              and progetto.ente_proprietario_id= p_ente_prop_id
              and anno_bil.anno=p_anno -- anno bilancio
              and crono.usato_per_fpv::boolean = conflagfpv              
              and cronop_elem_det.anno_entrata = p_anno_prospetto -- anno prospetto               
              and anno_crono.anno::integer=p_anno_prospetto::integer+1  -- anno prospetto + 1              
              and d_class_tipo.classif_tipo_code='PROGRAMMA'
              and class.classif_code=classifBilRec.programma_code                            
              and cronop_stato.cronop_stato_code='VA'   
              and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.             
              and progetto_stato.programma_stato_code='VA'
              and r_progetto_stato.data_cancellazione is null
              and r_cronop_stato.data_cancellazione is null
              and crono.data_cancellazione is null
              and progetto.data_cancellazione is null
              and bil.data_cancellazione is null
              and anno_bil.data_cancellazione is null
              and cronop_elem.data_cancellazione is null
              and cronop_elem_det.data_cancellazione is null
              and r_cronop_elem_class.data_cancellazione is null;
             -- raise notice 'Query 3: Progr: % - campo D dopo = %', classifBilRec.programma_code,spese_da_impeg_anno1_d;
        
        raise notice 'Programma % - spese_da_impeg_anno1_d da progetti = %', classifBilRec.programma_code ,
        	spese_da_impeg_anno1_d;
        
        /*
        Colonna E - Occorre prendere tutte le quote di spesa previste nei cronoprogrammi 
        con FPV selezionato, con anno di entrata = anno Prospetto e anno di spesa uguale a anno Prospetto+2.
        25/01/2023 SIAC-8866: i progetti devono essere solo quelli di Previsione.
        */
          select COALESCE(sum(cronop_elem_det.cronop_elem_det_importo),0) 
          	into spese_da_impeg_anno2_e
          from siac_t_programma progetto, siac_t_cronop crono, 
              siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
              siac_t_cronop_elem cronop_elem, siac_d_bil_elem_tipo tipo_cap,
              siac_t_cronop_elem_det cronop_elem_det, siac_t_periodo anno_crono, 
              siac_r_cronop_elem_class r_cronop_elem_class, siac_d_class_tipo d_class_tipo, siac_t_class class,
              siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
              siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato
          where progetto.programma_id=crono.programma_id
              and crono.bil_id = bil.bil_id
              and bil.periodo_id=anno_bil.periodo_id
              and tipo_prog.programma_tipo_id = progetto.programma_tipo_id
              and cronop_elem.cronop_id=crono.cronop_id
              and cronop_elem.cronop_elem_id=cronop_elem_det.cronop_elem_id
              and tipo_cap.elem_tipo_id=cronop_elem.elem_tipo_id
              and cronop_elem_det.periodo_id = anno_crono.periodo_id
              and r_cronop_elem_class.cronop_elem_id = cronop_elem.cronop_elem_id
              and r_cronop_elem_class.classif_id=class.classif_id
              and class.classif_tipo_id=d_class_tipo.classif_tipo_id
              and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
              and r_cronop_stato.cronop_id=crono.cronop_id
              and r_progetto_stato.programma_id=progetto.programma_id
              and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id              
              and progetto.ente_proprietario_id= p_ente_prop_id
              and anno_bil.anno=p_anno -- anno bilancio
              and crono.usato_per_fpv::boolean = conflagfpv              
              and cronop_elem_det.anno_entrata = p_anno_prospetto -- anno prospetto               
              and anno_crono.anno::integer=p_anno_prospetto::integer+2 -- anno prospetto + 2        
              and d_class_tipo.classif_tipo_code='PROGRAMMA'
              and class.classif_code=classifBilRec.programma_code                            
              and cronop_stato.cronop_stato_code='VA'   
              and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.             
              and progetto_stato.programma_stato_code='VA'
              and r_progetto_stato.data_cancellazione is null
              and r_cronop_stato.data_cancellazione is null
              and crono.data_cancellazione is null
              and progetto.data_cancellazione is null
              and bil.data_cancellazione is null
              and anno_bil.data_cancellazione is null
              and cronop_elem.data_cancellazione is null
              and cronop_elem_det.data_cancellazione is null
              and r_cronop_elem_class.data_cancellazione is null;
              
        
        
        /* Colonna F - Occorre prendere tutte le quote di 
        spesa previste nei cronoprogrammi con FPV selezionato, 
         con FPV selezionato, con anno di entrata = anno Prospetto e anno di spesa > anno Prospetto+2.
         25/01/2023 SIAC-8866: i progetti devono essere solo quelli di Previsione.
         */
         
          select COALESCE(sum(cronop_elem_det.cronop_elem_det_importo),0) 
          	into spese_da_impeg_anni_succ_f
          from siac_t_programma progetto, siac_t_cronop crono, 
              siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
              siac_t_cronop_elem cronop_elem, siac_d_bil_elem_tipo tipo_cap,
              siac_t_cronop_elem_det cronop_elem_det, siac_t_periodo anno_crono, 
              siac_r_cronop_elem_class r_cronop_elem_class, siac_d_class_tipo d_class_tipo, siac_t_class class,
              siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
              siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato
          where progetto.programma_id=crono.programma_id
              and crono.bil_id = bil.bil_id
              and bil.periodo_id=anno_bil.periodo_id
              and tipo_prog.programma_tipo_id = progetto.programma_tipo_id
              and cronop_elem.cronop_id=crono.cronop_id
              and cronop_elem.cronop_elem_id=cronop_elem_det.cronop_elem_id
              and tipo_cap.elem_tipo_id=cronop_elem.elem_tipo_id
              and cronop_elem_det.periodo_id = anno_crono.periodo_id
              and r_cronop_elem_class.cronop_elem_id = cronop_elem.cronop_elem_id
              and r_cronop_elem_class.classif_id=class.classif_id
              and class.classif_tipo_id=d_class_tipo.classif_tipo_id
              and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
              and r_cronop_stato.cronop_id=crono.cronop_id
              and r_progetto_stato.programma_id=progetto.programma_id
              and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id              
              and progetto.ente_proprietario_id= p_ente_prop_id
              and anno_bil.anno=p_anno -- anno bilancio
              and crono.usato_per_fpv::boolean = conflagfpv              
              and cronop_elem_det.anno_entrata = p_anno_prospetto -- anno prospetto               
              and anno_crono.anno::integer > p_anno_prospetto::integer+2 -- maggiore di anno prospetto + 2       
              and d_class_tipo.classif_tipo_code='PROGRAMMA'
              and class.classif_code=classifBilRec.programma_code                            
              and cronop_stato.cronop_stato_code='VA'   
              and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.             
              and progetto_stato.programma_stato_code='VA'
              and r_progetto_stato.data_cancellazione is null
              and r_cronop_stato.data_cancellazione is null
              and crono.data_cancellazione is null
              and progetto.data_cancellazione is null
              and bil.data_cancellazione is null
              and anno_bil.data_cancellazione is null
              and cronop_elem.data_cancellazione is null
              and cronop_elem_det.data_cancellazione is null
              and r_cronop_elem_class.data_cancellazione is null;
                            
          
        
        
        /*5.	La colonna h  e' la somma dalla colonna c alla colonna g.
        		In realta' NON e' piu' calcolata in questa procedura. */
        

        fondo_plur_anno_h=quota_fond_plur_anni_prec_c+spese_da_impeg_anno1_d+
            spese_da_impeg_anno2_e+spese_da_impeg_anni_succ_f+spese_da_impeg_non_def_g;
    
/*raise notice 'programma_codeXXX = %', programma_code;
raise notice '  spese_impe_anni_prec_b = %', spese_impe_anni_prec_b;
raise notice '  quota_fond_plur_anni_prec_c = %', quota_fond_plur_anni_prec_c;
raise notice '  spese_da_impeg_anno1_d = %', spese_da_impeg_anno1_d;
raise notice '  spese_da_impeg_anno2_e = %', spese_da_impeg_anno2_e;
raise notice '  spese_da_impeg_anni_succ_f = %', spese_da_impeg_anni_succ_f;
raise notice '  spese_da_impeg_non_def_g = %', spese_da_impeg_non_def_g;*/
    
/* 25/01/2023 SIAC-8866.
	Occorre estrarre dalla gestione anno precedente l'anno del bilancio gli importi degli impegni secondo la seguente logica:
  - Colonna D
      Impegni anno = Anno di Prospetto+1 con vincolo ad Accertamento = Anno di Prospetto
  - Colonna E
      Impegni anno = Anno di Prospetto+2 con vincolo ad Accertamento = Anno di Prospetto
  - Colonna F
      Impegni anno > Anno di Prospetto+2 con vincolo ad Accertamento = Anno di Prospetto

Gli impegni estratti NON devono essere legati a progetti con cronoprogemmi con vincolo per FPV perche'
tali impegni sono giaì stati calcolati nelle query precedenti.

Gli importi estratti sono sommati a quelli delle query precedenti relativi agli impegni legati ai progetti.

*/
--raise notice 'bilancio_id_prec = %', bilancio_id_prec;
for impegniPrecRec in
    with struttura as (
    select *
    from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,(p_anno::integer - 1)::varchar, null)
    ),
    capitoli as (
    select 	programma.classif_id programma_id,
            macroaggr.classif_id macroaggregato_id,
            capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
            capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
    from siac_t_bil_elem capitolo,
         siac_d_bil_elem_tipo tipo_elemento,
         siac_r_bil_elem_stato r_capitolo_stato,
         siac_d_bil_elem_stato stato_capitolo,      
         siac_r_bil_elem_class r_capitolo_programma,
         siac_r_bil_elem_class r_capitolo_macroaggr, 	 
         siac_d_bil_elem_categoria cat_del_capitolo,
         siac_r_bil_elem_categoria r_cat_capitolo,
         siac_d_class_tipo programma_tipo,
         siac_t_class programma,
         siac_d_class_tipo macroaggr_tipo,
         siac_t_class macroaggr
    where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
    and capitolo.elem_id = r_capitolo_stato.elem_id							
    and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
    and	capitolo.elem_id = r_capitolo_programma.elem_id							
    and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
    and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
    and programma.classif_id = r_capitolo_programma.classif_id					
    and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
    and	capitolo.elem_id = r_cat_capitolo.elem_id				
    and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
    and capitolo.ente_proprietario_id = p_ente_prop_id							
    and capitolo.bil_id = bilancio_id_prec --anno precedente													
    and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
    and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
    and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
    and stato_capitolo.elem_stato_code = 'VA' 
    -- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
    and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
    and	capitolo.data_cancellazione 				is null
    and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
    and	r_capitolo_macroaggr.data_cancellazione 	is null 
    and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
    and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione           is null
    ),
    impegni as(
    select distinct accert.*, imp.*, ts_impegni_legati.movgest_ts_b_id
    from siac_r_movgest_ts ts_impegni_legati    	
         join (	--accertamenti
         		select ts_mov_acc.movgest_ts_id,
                        mov_acc.movgest_anno anno_acc, 
                        mov_acc.movgest_numero numero_acc,
                        ts_mov_det_acc.movgest_ts_det_importo importo_acc
                    from siac_t_movgest mov_acc,
                         siac_t_movgest_ts ts_mov_acc,					
                         siac_t_movgest_ts_det ts_mov_det_acc,
                         siac_r_movgest_ts_stato r_stato_acc,
                         siac_d_movgest_stato stato_acc
                    where mov_acc.movgest_id=ts_mov_acc.movgest_id
                        and ts_mov_acc.movgest_ts_id=ts_mov_det_acc.movgest_ts_id
                        and ts_mov_acc.movgest_ts_id=r_stato_acc.movgest_ts_id
                        and r_stato_acc.movgest_stato_id=stato_acc.movgest_stato_id
                        and mov_acc.ente_proprietario_id=p_ente_prop_id
                        and mov_acc.movgest_anno = annoProspInt --accertamenti sempre dell'anno prospetto
                        and stato_acc.movgest_stato_code in ('D','N')
                        and r_stato_acc.data_cancellazione IS NULL
                        and mov_acc.data_cancellazione IS NULL
                        and ts_mov_acc.data_cancellazione IS NULL) accert
            on accert.movgest_ts_id =  ts_impegni_legati.movgest_ts_a_id
          join (--impegni
          		select ts_mov_imp.movgest_ts_id,
                        mov_imp.movgest_anno anno_imp, 
                        mov_imp.movgest_numero numero_imp,
                        r_imp_bil_elem.elem_id,
                        ts_mov_det_imp.movgest_ts_det_importo importo_imp
                    from siac_t_movgest mov_imp,
                         siac_t_movgest_ts ts_mov_imp,					
                         siac_t_movgest_ts_det ts_mov_det_imp,
                         siac_r_movgest_ts_stato r_stato_imp,
                         siac_d_movgest_stato stato_imp,
                         siac_r_movgest_bil_elem r_imp_bil_elem
                    where mov_imp.movgest_id=ts_mov_imp.movgest_id
                        and ts_mov_imp.movgest_ts_id=ts_mov_det_imp.movgest_ts_id
                        and ts_mov_imp.movgest_ts_id=r_stato_imp.movgest_ts_id
                        and r_stato_imp.movgest_stato_id=stato_imp.movgest_stato_id
                        and r_imp_bil_elem.movgest_id=mov_imp.movgest_id
                        and mov_imp.ente_proprietario_id=p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id_prec --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoProspInt + 1 --impegni a partire dell'anno prospetto + 1
                        and stato_imp.movgest_stato_code in ('D','N')
                        and r_stato_imp.data_cancellazione IS NULL
                        and mov_imp.data_cancellazione IS NULL
                        and ts_mov_imp.data_cancellazione IS NULL
                        and r_imp_bil_elem.data_cancellazione IS NULL) imp              
            on imp.movgest_ts_id =  ts_impegni_legati.movgest_ts_b_id
          left join (--legame con i progetti 
          		select r_mov_progr.movgest_ts_id, progetto.programma_id
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno::integer=annoBilInt - 1 -- anno precedente quello del bilancio?
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null) progetti
             on ts_impegni_legati.movgest_ts_b_id = progetti.movgest_ts_id
    where ts_impegni_legati.ente_proprietario_id=p_ente_prop_id      
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
        and progetti.programma_id IS NULL )
    select --struttura.programma_code::varchar programma,
        anno_imp anno_impegno,
        sum(impegni.importo_imp) importo_impegni
    from impegni
        left join capitoli 
            on impegni.elem_id=capitoli.elem_id 
        left join struttura 
            on struttura.programma_id = capitoli.programma_id
                and struttura.macroag_id = capitoli.macroaggregato_id        
    where struttura.programma_code = classifBilRec.programma_code
    group by anno_impegno
loop
	--raise notice 'anno impegno = % - progetto = %', impegniPrecRec.anno_impegno, impegniPrecRec;
	case impegniPrecRec.anno_impegno
    	when annoProspInt +1 then
    		raise notice '% = Anno % - importo %',classifBilRec.programma_code,annoProspInt +1, impegniPrecRec.importo_impegni;
            spese_da_impeg_anno1_d:= spese_da_impeg_anno1_d + impegniPrecRec.importo_impegni;
            spese_da_impeg_anno1_d2:=impegniPrecRec.importo_impegni;
      	when annoProspInt +2 then
    		raise notice '% = Anno % - importo %',classifBilRec.programma_code, annoProspInt +2, impegniPrecRec.importo_impegni;
            spese_da_impeg_anno2_e:= spese_da_impeg_anno2_e + impegniPrecRec.importo_impegni;
	 	else -->  > annoProspInt +2 then
    		raise notice '% = Anno > % - importo %',classifBilRec.programma_code, annoProspInt +2, impegniPrecRec.importo_impegni;
            spese_da_impeg_anni_succ_f:= spese_da_impeg_anni_succ_f + impegniPrecRec.importo_impegni;
    end case;
end loop;

  return next;

  bil_anno='';
  missione_tipo_code='';
  missione_tipo_desc='';
  missione_code='';
  missione_desc='';
  programma_tipo_code='';
  programma_tipo_desc='';
  programma_code='';
  programma_desc='';

  fondo_plur_anno_prec_a=0;
  spese_impe_anni_prec_b=0;
  quota_fond_plur_anni_prec_c=0;
  spese_da_impeg_anno1_d=0;
  spese_da_impeg_anno2_e=0;
  spese_da_impeg_anni_succ_f=0;
  spese_da_impeg_non_def_g=0;
  fondo_plur_anno_h=0;        
  spese_da_impeg_anno1_d2:=0;
end loop;  

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR011_Allegato_B_Fondo_Pluriennale_vincolato" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;
  
CREATE OR REPLACE FUNCTION siac."BILR011_allegato_fpv_previsione_con_dati_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  importi_capitoli numeric,
  spese_impegnate numeric,
  spese_impegnate_anno1 numeric,
  spese_impegnate_anno2 numeric,
  spese_impegnate_anno_succ numeric,
  importo_avanzo numeric,
  importo_avanzo_anno1 numeric,
  importo_avanzo_anno2 numeric,
  importo_avanzo_anno_succ numeric,
  elem_id integer,
  anno_esercizio varchar,
  spese_impegnate_da_prev numeric
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int integer;

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della BILR171_allegato_fpv_previsione_con_dati_gestione che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
		Poiche' il report BILR171 viene eliminato la funzione 
        BILR171_allegato_fpv_previsione_con_dati_gestione e' superflua ma NON viene
        cancellata perche' serve per gli anni precedenti il 2018.
*/

/*Se la fase di bilancio e' Previsione allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno-1 per tutte le colonne. 

Se la fase di bilancio e' Esercizio Provvisorio allora l''anno di esercizio e il bilancio id saranno
quelli di p_anno per tutte le colonne tranne quella relativa agli importi dei capitolo (colonna a).
In questo caso l''anno di esercizio e il bilancio id saranno quelli di p_anno-1.

L'anno relativo agli importi dei capitoli e' anno_esercizio_prec
L'anno relativo agli importi degli impegni e' annoImpImpegni_int*/


-- SIAC-6063
/*Aggiunto parametro p_anno_prospetto
Variabile annoImpImpegni_int sostituita da annoprospetto_int
Azzerati importi  spese_impegnate_anno1
                  spese_impegnate_anno2
                  spese_impegnate_anno_succ
                  importo_avanzo_anno1
                  importo_avanzo_anno2
                  importo_avanzo_anno_succ*/

RTN_MESSAGGIO := 'select 1'; 

bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
/*if cod_fase_operativa = 'P' then
  
  anno_esercizio := ((p_anno::integer)-1)::varchar;   

  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer-1;
  
elsif cod_fase_operativa in ('E','G') then

  anno_esercizio := p_anno;
  annoprospetto_int := p_anno_prospetto::integer;
   
end if;*/
 
  anno_esercizio := ((p_anno::integer)-1)::varchar;   


  select a.bil_id 
  into bilancio_id 
  from siac_t_bil a,siac_t_periodo b
  where a.ente_proprietario_id = p_ente_prop_id 
  and b.periodo_id = a.periodo_id
  and b.anno = anno_esercizio;
  
  annoprospetto_int := p_anno_prospetto::integer;
  
  annoprospetto_prec_int := ((p_anno_prospetto::integer)-1);

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

-- annoImpImpegni_int := anno_esercizio::integer; 
-- annoImpImpegni_int := p_anno::integer; -- SIAC-6063
raise notice 'anno_esercizio = % - anno_esercizio_prec = %', anno_esercizio, anno_esercizio_prec;
raise notice 'bilancio_id = % - bilancio_id_prec = %', bilancio_id, bilancio_id_prec;
raise notice 'annoprospetto_int = %', annoprospetto_int;
raise notice 'annoprospetto_prec_int = %', annoprospetto_prec_int;

return query
select 
zz.*
from (
select 
tab1.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null) -- Potrebbe essere anche anno_esercizio_prec
),
capitoli_anno_prec as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 			
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
and	programma_tipo.data_cancellazione 			is null
and	programma.data_cancellazione 				is null
and	macroaggr_tipo.data_cancellazione 			is null
and	macroaggr.data_cancellazione 				is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	r_capitolo_programma.data_cancellazione 	is null
and	r_capitolo_macroaggr.data_cancellazione 	is null 
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and	cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione           is null
),
capitoli_importo as ( -- Fondo pluriennale vincolato al 31 dicembre dell''esercizio N-1
select 		capitolo_importi.elem_id,
           	sum(capitolo_importi.elem_det_importo) importi_capitoli
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo
where capitolo_importi.ente_proprietario_id = p_ente_prop_id  								 
and	capitolo.elem_id = capitolo_importi.elem_id 
and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
and	capitolo.elem_id = r_capitolo_stato.elem_id			
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
and	capitolo.bil_id = bilancio_id_prec							
and	tipo_elemento.elem_tipo_code = 'CAP-UG'
and	capitolo_imp_periodo.anno = annoprospetto_prec_int::varchar		  
--and	capitolo_imp_periodo.anno = anno_esercizio_prec	
and	stato_capitolo.elem_stato_code = 'VA'								
and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
and capitolo_imp_tipo.elem_det_tipo_code = 'STA'				
and	capitolo_importi.data_cancellazione 		is null
and	capitolo_imp_tipo.data_cancellazione 		is null
and	capitolo_imp_periodo.data_cancellazione 	is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione 			is null
group by capitolo_importi.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
COALESCE(capitoli_importo.importi_capitoli,0)::numeric,
0::numeric spese_impegnate,
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
0::numeric importo_avanzo,
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli_anno_prec.elem_id::integer,
anno_esercizio::varchar,
0::numeric spese_impegnate_da_prev
from struttura
left join capitoli_anno_prec on struttura.programma_id = capitoli_anno_prec.programma_id
                   and struttura.macroag_id = capitoli_anno_prec.macroaggregato_id
left join capitoli_importo on capitoli_anno_prec.elem_id = capitoli_importo.elem_id
) tab1
union all
select 
tab2.*
from (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
and	programma_tipo.data_cancellazione 			is null
and	programma.data_cancellazione 				is null
and	macroaggr_tipo.data_cancellazione 			is null
and	macroaggr.data_cancellazione 				is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	r_capitolo_programma.data_cancellazione 	is null
and	r_capitolo_macroaggr.data_cancellazione 	is null 
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and	cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
impegni_verif_previsione as(
    select distinct accert.*, imp.*, ts_impegni_legati.movgest_ts_b_id
    from siac_r_movgest_ts ts_impegni_legati    	
         join (	--accertamenti
         		select ts_mov_acc.movgest_ts_id,
                        mov_acc.movgest_anno anno_acc, 
                        mov_acc.movgest_numero numero_acc,
                        ts_mov_det_acc.movgest_ts_det_importo importo_acc
                    from siac_t_movgest mov_acc,
                         siac_t_movgest_ts ts_mov_acc,					
                         siac_t_movgest_ts_det ts_mov_det_acc,
                         siac_r_movgest_ts_stato r_stato_acc,
                         siac_d_movgest_stato stato_acc
                    where mov_acc.movgest_id=ts_mov_acc.movgest_id
                        and ts_mov_acc.movgest_ts_id=ts_mov_det_acc.movgest_ts_id
                        and ts_mov_acc.movgest_ts_id=r_stato_acc.movgest_ts_id
                        and r_stato_acc.movgest_stato_id=stato_acc.movgest_stato_id
                        and mov_acc.ente_proprietario_id= p_ente_prop_id
                        and mov_acc.movgest_anno = annoprospetto_prec_int--annoprospetto_int --accertamenti sempre dell'anno prospetto
                        --and mov_acc.movgest_anno = annoprospetto_int --accertamenti sempre dell'anno prospetto
                        and stato_acc.movgest_stato_code in ('D','N')
                        and r_stato_acc.data_cancellazione IS NULL
                        and mov_acc.data_cancellazione IS NULL
                        and ts_mov_acc.data_cancellazione IS NULL) accert
            on accert.movgest_ts_id =  ts_impegni_legati.movgest_ts_a_id
          join (--impegni
          		select ts_mov_imp.movgest_ts_id,
                        mov_imp.movgest_anno anno_imp, 
                        mov_imp.movgest_numero numero_imp,
                        r_imp_bil_elem.elem_id,
                        ts_mov_det_imp.movgest_ts_det_importo importo_imp
                    from siac_t_movgest mov_imp,
                         siac_t_movgest_ts ts_mov_imp,					
                         siac_t_movgest_ts_det ts_mov_det_imp,
                         siac_r_movgest_ts_stato r_stato_imp,
                         siac_d_movgest_stato stato_imp,
                         siac_r_movgest_bil_elem r_imp_bil_elem
                    where mov_imp.movgest_id=ts_mov_imp.movgest_id
                        and ts_mov_imp.movgest_ts_id=ts_mov_det_imp.movgest_ts_id
                        and ts_mov_imp.movgest_ts_id=r_stato_imp.movgest_ts_id
                        and r_stato_imp.movgest_stato_id=stato_imp.movgest_stato_id
                        and r_imp_bil_elem.movgest_id=mov_imp.movgest_id
                        and mov_imp.ente_proprietario_id= p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id  --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoprospetto_prec_int+1-- annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        --and mov_imp.movgest_anno >=  annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        and stato_imp.movgest_stato_code in ('D','N')
                        and r_stato_imp.data_cancellazione IS NULL
                        and mov_imp.data_cancellazione IS NULL
                        and ts_mov_imp.data_cancellazione IS NULL
                        and r_imp_bil_elem.data_cancellazione IS NULL) imp              
            on imp.movgest_ts_id =  ts_impegni_legati.movgest_ts_b_id
          left join (--legame con i progetti 
          		select r_mov_progr.movgest_ts_id, progetto.programma_id
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno=p_anno -- anno bilancio
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null) progetti
             on ts_impegni_legati.movgest_ts_b_id = progetti.movgest_ts_id
    where ts_impegni_legati.ente_proprietario_id=p_ente_prop_id     
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
        and progetti.programma_id IS NULL ),
/* SIAC-8866 04/07/2023.
    	Devo verificare che l'impegno non sia legato ad un progetto per non contarlo 2 volte.
*/     
elenco_progetti_imp as (select r_mov_progr.movgest_ts_id, progetto.programma_id, progetto.programma_code
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno=anno_esercizio_prec -- anno bilancio precedente
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null)         
select impegni.movgest_ts_b_id, COALESCE(elenco_progetti_imp.programma_code,'') progetto,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,  
       case 
        when impegni.anno_impegno = annoprospetto_int+1 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno1,   
       case 
        when impegni.anno_impegno = annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno2,    
       case 
        when impegni.anno_impegno > annoprospetto_int+2 and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int+2 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate_anno_succ,
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo,    
       case 
        when impegni.anno_impegno = annoprospetto_int+1 then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo_anno1,      
       case 
        when impegni.anno_impegno = annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno2,
       case 
        when impegni.anno_impegno > annoprospetto_int+2 then
             sum(imp_impegni_avanzo.movgest_ts_importo)            
       end importo_avanzo_anno_succ,
       case 
       	when impegni.anno_impegno = annoprospetto_int then --and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
       		sum(impegni_verif_previsione.importo_imp) 
        end spese_impegnate_da_prev                            
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
left   join impegni_verif_previsione on impegni.movgest_ts_b_id = impegni_verif_previsione.movgest_ts_b_id and
		annoprospetto_int > p_anno::integer 
left join elenco_progetti_imp on elenco_progetti_imp.movgest_ts_id = impegni.movgest_ts_b_id        
--left   join impegni_verif_previsione on 1000 = impegni_verif_previsione.movgest_ts_b_id
-- SIAC-8866 04/07/2023: solo se l'impegno non è collegato al progetto.
where  ((COALESCE(elenco_progetti_imp.programma_code,'') = '' ) OR
		(COALESCE(elenco_progetti_imp.programma_code,'') <> '' AND impegni_verif_previsione.movgest_ts_b_id IS NULL))
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento ,
	COALESCE(elenco_progetti_imp.programma_code,'')
),
capitoli_impegni as (
select capitolo.elem_id, ts_movimento.movgest_ts_id
from  siac_t_bil_elem                 capitolo
inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where capitolo.ente_proprietario_id = p_ente_prop_id
and   capitolo.bil_id =	bilancio_id
and   movimento.bil_id = bilancio_id
and   t_capitolo.elem_tipo_code = 'CAP-UG'
and   movimento.movgest_anno >= annoprospetto_int
-- and   movimento.movgest_anno >= annoImpImpegni_int
and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
and   capitolo.data_cancellazione is null 
and   r_mov_capitolo.data_cancellazione is null 
and   t_capitolo.data_cancellazione is null
and   movimento.data_cancellazione is null 
and   ts_movimento.data_cancellazione is null
and   ts_stato.data_cancellazione is null-- SIAC-5778
and   stato.data_cancellazione is null-- SIAC-5778 
)
select 
capitoli_impegni.elem_id,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.spese_impegnate_anno1) spese_impegnate_anno1,
sum(importo_impegni.spese_impegnate_anno2) spese_impegnate_anno2,
sum(importo_impegni.spese_impegnate_anno_succ) spese_impegnate_anno_succ,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(importo_impegni.importo_avanzo_anno1) importo_avanzo_anno1,
sum(importo_impegni.importo_avanzo_anno2) importo_avanzo_anno2,
sum(importo_impegni.importo_avanzo_anno_succ) importo_avanzo_anno_succ,
sum(importo_impegni.spese_impegnate_da_prev) spese_impegnate_da_prev
from capitoli_impegni
	left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id
)
select 
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
0::numeric importi_capitoli,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
/*COALESCE(dati_impegni.spese_impegnate_anno1,0)::numeric spese_impegnate_anno1,
COALESCE(dati_impegni.spese_impegnate_anno2,0)::numeric spese_impegnate_anno2,
COALESCE(dati_impegni.spese_impegnate_anno_succ,0)::numeric spese_impegnate_anno_succ,*/
0::numeric spese_impegnate_anno1,
0::numeric spese_impegnate_anno2,
0::numeric spese_impegnate_anno_succ,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
/*COALESCE(dati_impegni.importo_avanzo_anno1,0)::numeric importo_avanzo_anno1,
COALESCE(dati_impegni.importo_avanzo_anno2,0)::numeric importo_avanzo_anno2,
COALESCE(dati_impegni.importo_avanzo_anno_succ,0)::numeric importo_avanzo_anno_succ,*/
0::numeric importo_avanzo_anno1,
0::numeric importo_avanzo_anno2,
0::numeric importo_avanzo_anno_succ,
capitoli.elem_id::integer,
anno_esercizio::varchar,
coalesce(dati_impegni.spese_impegnate_da_prev,0) spese_impegnate_da_prev
from struttura
left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
) tab2
) as zz;

-- raise notice 'Dati % - %',anno_esercizio::varchar,anno_esercizio_prec::varchar;
-- raise notice 'Dati % - %',bilancio_id::varchar,bilancio_id_prec::varchar;

exception
when no_data_found THEN
raise notice 'nessun dato trovato per struttura bilancio';
return;
when others  THEN
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;

CREATE OR REPLACE FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  missione varchar,
  programma varchar,
  imp_colonna_h numeric,
  imp_colonna_d numeric
) AS
$body$
DECLARE

BEGIN

/*
	12/03/2019: SIAC-6623.
    	Funzione copia della fnc_lancio_BILR171_anni_precedenti che serve
        per il calcolo dei campi relativi alle prime 2 colonne del report BILR011.
        Richiama la BILR011_allegato_fpv_previsione_con_dati_gestione con parametri 
        diversi a seconda dell'anno di prospetto.
		Poiche' il report BILR171 viene eliminato per l'anno 2018 la funzione 
        fnc_lancio_BILR171_anni_precedenti rimane per gli anni precedenti.
*/

/*
	21/12/2020: SIAC-7933.
    	Questa funzione serve per calcolare i dati della colonna H dell'anno precedente
        quando l'anno di prospetto e' maggiore di quello del bilancio.
        In questo caso tale colonna diventa la colonna A del report.
    	La funzione e' stata rivista in quanto prima la colonna H dell'anno precedente 
        del report era calcolata usando solo i dati della Gestione.
        Invece ora viene calcolata sommando i dati della Gestione delle colonne
        A e B e quelli di Previsione delle colonne D, E, F e G dell'anno precedente 
        cosi' come avviene anche quando l'anno di prospetto e' uguale all'anno del Bilancio. 
        Per questo motivo le query sono state riviste e viene richiamata anche la funzione
        "BILR011_Allegato_B_Fondo_Pluriennale_vincolato" che prende i dati di Previsione.
        
        Inoltre la funzione restituisce anche l'importo della colonna D anno precedente,
        in quanto e' stato richiesto che quando l'anno prospetto e' maggiore di quello
        del bilancio tale importo sia sommato alla colonna B.        

	28/02/2023: SIAC-8866.
    	Quando l'anno prospetto e' uguale a quallo del bilancio + 2, occorre sottrare per la colonna A l'importo
        "spese_impegnate_da_prev" che contiene l'importo degli impegni utilizzati per il calcolo 
*/

	--anno prospetto = anno bilancio + 1
if p_anno_prospetto::integer = (p_anno::integer)+1 then
   
  return query
 /*
  select missione_code, programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code;*/  
  
  	--  FPV = dati di Previsione, anno_prec = dati di gestione    
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,    
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-(anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) imp_colonna_h,
    FPV.spese_da_impeg_anno1_d imp_colonna_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro;
 
	--anno prospetto = anno bilancio + 2
elsif p_anno_prospetto::integer = (p_anno::integer)+2 then
-- quando l'anno prospette e' anno bilancio + 2, devo calcolare l'importo della 
-- colonna H del report con anno -2 perche' diventa la colonna A dell'anno -1.
  return query
   select anno_meno2.missione_code, anno_meno2.programma_code,
   (anno_meno2.importo_colonna_h -
    (anno_meno1.importo_avanzo+anno_meno1.spese_impegnate+ 
    anno_meno2.spese_da_impeg_anno1_d -anno_meno1.spese_impegnate_da_prev) + --devo aggiungere anche la colonna_B.
    anno_meno1.spese_da_impeg_anno1_d + anno_meno1.spese_da_impeg_anno2_e +
   	anno_meno1.spese_da_impeg_anni_succ_f + anno_meno1.spese_da_impeg_non_def_g) imp_colonna_h,
    anno_meno1.spese_da_impeg_anno1_d imp_colonna_d
  from (
  	--  FPV = dati di Previsione, anno_prec = dati di gestione, Anno prospetto -2.
  with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,  
    missione_code||programma_code as missioneprogramma 
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-2)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g ) importo_colonna_h,
    anno_prec.importo_avanzo, anno_prec.spese_impegnate, FPV.spese_da_impeg_anno1_d
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno2,
 ( --  FPV = dati di Previsione, anno_prec = dati di gestione. Anno prospetto -1.
 	with FPV as (select programma_code progr_code, *, missione_code||programma_code mispro
	from "BILR011_Allegato_B_Fondo_Pluriennale_vincolato"(p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)),
  	anno_prec as (select 
    missione_code,
    missione_desc,
    programma_code, 
    programma_desc,
    sum(importi_capitoli) as importi_capitoli,
    sum(importo_avanzo) as importo_avanzo,
    sum(spese_impegnate) as spese_impegnate,
    sum(importo_avanzo_anno1) as importo_avanzo_anno1,
    sum(spese_impegnate_anno1) as spese_impegnate_anno1,
    sum(importo_avanzo_anno2) as importo_avanzo_anno2,
    sum(spese_impegnate_anno2) as spese_impegnate_anno2,
    sum(importo_avanzo_anno_succ) as importo_avanzo_anno_succ,
    sum(spese_impegnate_anno_succ) as spese_impegnate_anno_succ,
    sum(spese_impegnate_da_prev) as spese_impegnate_da_prev,  
    missione_code||programma_code as missioneprogramma
    from "BILR011_allegato_fpv_previsione_con_dati_gestione" (p_ente_prop_id,
    									p_anno,
                                        (p_anno_prospetto::integer-1)::varchar)                                          
    group by missione_code, missione_desc, programma_code,
    	programma_desc, missioneprogramma)                                        
  select FPV.missione_code, FPV.programma_code,
  	(anno_prec.importi_capitoli-
    (anno_prec.importo_avanzo + anno_prec.spese_impegnate) +
    FPV.spese_da_impeg_anno1_d + FPV.spese_da_impeg_anno2_e +
    FPV.spese_da_impeg_anni_succ_f + FPV.spese_da_impeg_non_def_g) importo_colonna_h,
    FPV.spese_da_impeg_anno1_d, FPV.spese_da_impeg_anno2_e,
    FPV.spese_da_impeg_anni_succ_f, FPV.spese_da_impeg_non_def_g,
    anno_prec.spese_impegnate, anno_prec.importo_avanzo, anno_prec.spese_impegnate_da_prev
 from FPV
 	join anno_prec
    	on anno_prec.missioneprogramma=FPV.mispro) anno_meno1
where anno_meno2.missione_code = anno_meno1.missione_code
  and   anno_meno2.programma_code = anno_meno1.programma_code;
  
  /*
    select a.missione_code, a.programma_code,
    (a.importo_colonna_h-b.importo_colonna_h) as imp_colonna_h
  from (
  select missione_code, 
         programma_code, 
         sum(importi_capitoli-(importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-2)::varchar
  )
  group by missione_code, programma_code
  ) a, 
  (select missione_code, programma_code, 
         sum((importo_avanzo+spese_impegnate)+(importo_avanzo_anno1+spese_impegnate_anno1)+(importo_avanzo_anno2+spese_impegnate_anno2)+(importo_avanzo_anno_succ+spese_impegnate_anno_succ)) as  importo_colonna_h
  from "BILR011_allegato_fpv_previsione_con_dati_gestione" (
    p_ente_prop_id,
    p_anno,
    (p_anno_prospetto::integer-1)::varchar
  )
  group by missione_code, programma_code
  ) b
  where a.missione_code = b.missione_code
  and   a.programma_code = b.programma_code;*/

end if;
  
EXCEPTION
  when others  THEN
  RAISE EXCEPTION 'Errore : %-%.',SQLSTATE,substring(SQLERRM from 1 for 500);
  return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."fnc_lancio_BILR011_anni_precedenti_gestione" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;  
  
  
CREATE OR REPLACE FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  anno_prospetto varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  elem_id integer,
  numero_capitolo varchar,
  anno_impegno integer,
  numero_impegno numeric,
  spese_impegnate numeric,
  importo_avanzo numeric,
  importo_colonna_d_anno_prec numeric,
  spese_impegnate_da_prev numeric,
  progetto varchar,
  cronoprogramma varchar
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int integer;

BEGIN

/*
	26/04/2022: SIAC-8634.
    	Funzione che estrae i dati di dettaglio relativi al report BILR011
        per la sola colonna B utilizzata dal report BILR260.
*/
/* Aggiornamenti per SIAC-8866 30/06/2023.

*/

--I dati letti in questa procedura riguardano la gestione dell'anno precedente di quello del bilancio in input.
bilancio_id_prec := null;
 
anno_esercizio := ((p_anno::integer)-1)::varchar;   

annoprospetto_int := p_anno_prospetto::integer;
  
annoprospetto_prec_int := ((p_anno_prospetto::integer)-1);

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

--leggo l'id del bilancio precedente.
select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

raise notice 'bilancio_id_prec = %', bilancio_id_prec;
raise notice 'anno_esercizio = % - anno_esercizio_prec = % - annoprospetto_int = %- annoprospetto_prec_int = %', 
anno_esercizio, anno_esercizio_prec, annoprospetto_int, annoprospetto_prec_int;


return query
with tutto as (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id_prec													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
and	programma_tipo.data_cancellazione 			is null
and	programma.data_cancellazione 				is null
and	macroaggr_tipo.data_cancellazione 			is null
and	macroaggr.data_cancellazione 				is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	r_capitolo_programma.data_cancellazione 	is null
and	r_capitolo_macroaggr.data_cancellazione 	is null 
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and	cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id_prec
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id_prec
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id_prec
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
dettaglio_impegni as(
select impegno.movgest_anno anno_impegno,
	impegno.movgest_numero numero_impegno, impegno_ts.movgest_ts_id
from siac_t_movgest impegno,
	siac_t_movgest_ts impegno_ts,
    siac_d_movgest_tipo movgest_tipo
where impegno.movgest_id=impegno_ts.movgest_id
	and impegno.movgest_tipo_id=movgest_tipo.movgest_tipo_id
	and impegno.ente_proprietario_id= p_ente_prop_id
    and impegno.bil_id=bilancio_id_prec
    and movgest_tipo.movgest_tipo_code='I'
    and impegno.data_cancellazione IS NULL
    and impegno_ts.data_cancellazione IS NULL)    
select impegni.movgest_ts_b_id,
	   dettaglio_impegni.anno_impegno,
       dettaglio_impegni.numero_impegno,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,         
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo                           
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
left   join dettaglio_impegni on dettaglio_impegni.movgest_ts_id = impegni.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento,
	dettaglio_impegni.anno_impegno, dettaglio_impegni.numero_impegno
), --importo_impegni
    capitoli_impegni as (
    select capitolo.elem_id, ts_movimento.movgest_ts_id,
    	capitolo.elem_code numero_capitolo
    from  siac_t_bil_elem                 capitolo
    inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
    inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
    inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
    inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
    inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
    inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
    where capitolo.ente_proprietario_id = p_ente_prop_id
    and   capitolo.bil_id =	bilancio_id_prec
    and   movimento.bil_id = bilancio_id_prec
    and   t_capitolo.elem_tipo_code = 'CAP-UG'
    and   movimento.movgest_anno >= annoprospetto_int
    -- and   movimento.movgest_anno >= annoImpImpegni_int
    and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
    and   capitolo.data_cancellazione is null 
    and   r_mov_capitolo.data_cancellazione is null 
    and   t_capitolo.data_cancellazione is null
    and   movimento.data_cancellazione is null 
    and   ts_movimento.data_cancellazione is null
    and   ts_stato.data_cancellazione is null-- SIAC-5778
    and   stato.data_cancellazione is null-- SIAC-5778 
    ),
    /* SIAC-8866 26/06/2023.
    	Estraggo i dati degli impegni per verificare se un certo impegno era gia' stato utilizzato.
        Nel report il dato spese_impegnate_da_prev viene sottratto all'importo importo_colonna_d_anno_prec.
    */
    impegni_verif_previsione as(
    select distinct accert.*, imp.*,     ts_impegni_legati.movgest_ts_b_id
    from siac_r_movgest_ts ts_impegni_legati    	
         join (	--accertamenti
         		select ts_mov_acc.movgest_ts_id,
                        mov_acc.movgest_anno anno_acc, 
                        mov_acc.movgest_numero numero_acc,
                        ts_mov_det_acc.movgest_ts_det_importo importo_acc
                    from siac_t_movgest mov_acc,
                         siac_t_movgest_ts ts_mov_acc,					
                         siac_t_movgest_ts_det ts_mov_det_acc,
                         siac_r_movgest_ts_stato r_stato_acc,
                         siac_d_movgest_stato stato_acc
                    where mov_acc.movgest_id=ts_mov_acc.movgest_id
                        and ts_mov_acc.movgest_ts_id=ts_mov_det_acc.movgest_ts_id
                        and ts_mov_acc.movgest_ts_id=r_stato_acc.movgest_ts_id
                        and r_stato_acc.movgest_stato_id=stato_acc.movgest_stato_id
                        and mov_acc.ente_proprietario_id= p_ente_prop_id
                        and mov_acc.movgest_anno = annoprospetto_prec_int--annoprospetto_int --accertamenti sempre dell'anno prospetto
                        --and mov_acc.movgest_anno = annoprospetto_int --accertamenti sempre dell'anno prospetto
                        and stato_acc.movgest_stato_code in ('D','N')
                        and r_stato_acc.data_cancellazione IS NULL
                        and mov_acc.data_cancellazione IS NULL
                        and ts_mov_acc.data_cancellazione IS NULL) accert
            on accert.movgest_ts_id =  ts_impegni_legati.movgest_ts_a_id
          join (--impegni
          		select ts_mov_imp.movgest_ts_id,
                        mov_imp.movgest_anno anno_imp, 
                        mov_imp.movgest_numero numero_imp,
                        r_imp_bil_elem.elem_id,
                        ts_mov_det_imp.movgest_ts_det_importo importo_imp
                    from siac_t_movgest mov_imp,
                         siac_t_movgest_ts ts_mov_imp,					
                         siac_t_movgest_ts_det ts_mov_det_imp,
                         siac_r_movgest_ts_stato r_stato_imp,
                         siac_d_movgest_stato stato_imp,
                         siac_r_movgest_bil_elem r_imp_bil_elem
                    where mov_imp.movgest_id=ts_mov_imp.movgest_id
                        and ts_mov_imp.movgest_ts_id=ts_mov_det_imp.movgest_ts_id
                        and ts_mov_imp.movgest_ts_id=r_stato_imp.movgest_ts_id
                        and r_stato_imp.movgest_stato_id=stato_imp.movgest_stato_id
                        and r_imp_bil_elem.movgest_id=mov_imp.movgest_id
                        and mov_imp.ente_proprietario_id= p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id_prec  --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoprospetto_prec_int+1-- annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        --and mov_imp.movgest_anno >=  annoprospetto_int + 1 --impegni a partire dell'anno prospetto + 1
                        and stato_imp.movgest_stato_code in ('D','N')
                        and r_stato_imp.data_cancellazione IS NULL
                        and mov_imp.data_cancellazione IS NULL
                        and ts_mov_imp.data_cancellazione IS NULL
                        and r_imp_bil_elem.data_cancellazione IS NULL) imp              
            on imp.movgest_ts_id =  ts_impegni_legati.movgest_ts_b_id
          left join (--legame con i progetti 
          		select r_mov_progr.movgest_ts_id, progetto.programma_id
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno=p_anno--annoprospetto_prec_int::varchar -- anno bilancio precedente
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null) progetti
             on ts_impegni_legati.movgest_ts_b_id = progetti.movgest_ts_id
    where ts_impegni_legati.ente_proprietario_id=p_ente_prop_id   
    	and imp.anno_imp = annoprospetto_int --+1  
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
      and progetti.programma_id IS NULL  ),
/* SIAC-8866 04/07/2023.
    	Devo verificare che l'impegno non sia legato ad un progetto per non contarlo 2 volte.
*/     
elenco_progetti_imp as (select r_mov_progr.movgest_ts_id, progetto.programma_id, progetto.programma_code
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno=anno_esercizio_prec -- anno bilancio precedente
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null)      
select 
capitoli_impegni.elem_id,
capitoli_impegni.numero_capitolo,
COALESCE(importo_impegni.anno_impegno,0) anno_impegno, 
COALESCE(importo_impegni.numero_impegno,0) numero_impegno,
COALESCE(elenco_progetti_imp.programma_code,'') progetto,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.importo_avanzo) importo_avanzo,
sum(impegni_verif_previsione.importo_imp) spese_impegnate_da_prev
--0::numeric spese_impegnate_da_prev
from capitoli_impegni
	left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
	left join impegni_verif_previsione on capitoli_impegni.movgest_ts_id = impegni_verif_previsione.movgest_ts_b_id and
		annoprospetto_int > p_anno::integer 
    left join elenco_progetti_imp on elenco_progetti_imp.movgest_ts_id = capitoli_impegni.movgest_ts_id-- importo_impegni.movgest_ts_b_id
-- SIAC-8866 04/07/2023: solo se l'impegno non è collegato al progetto.
where  ((COALESCE(elenco_progetti_imp.programma_code,'') = '' ) OR
		(COALESCE(elenco_progetti_imp.programma_code,'') <> '' AND impegni_verif_previsione.movgest_ts_b_id IS NULL))    
group by capitoli_impegni.elem_id,capitoli_impegni.numero_capitolo,
importo_impegni.anno_impegno, importo_impegni.numero_impegno, COALESCE(elenco_progetti_imp.programma_code,'')
) --dati_impegni
select 
p_anno_prospetto::varchar anno_prosp,
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
dati_impegni.elem_id::integer,
dati_impegni.numero_capitolo,
COALESCE(dati_impegni.anno_impegno,0) anno_impegno, 
COALESCE(dati_impegni.numero_impegno,0) numero_impegno,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
0::numeric importo_colonna_d_Anno_prec,
COALESCE(dati_impegni.spese_impegnate_da_prev,0) spese_impegnate_da_prev,
''::varchar programma,
''::varchar cronoprogramma 
from struttura
	left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
	left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
where dati_impegni.elem_id is not null
--estraggo i dati della colonna D dello stesso anno bilancio ma con
--anno prospetto precedente.
--Vale solo quando il prospetto e' > dell'anno bilancio.
union 
--SIAC-8866 21/06/2023
--il calcolo degll'importo dei progetti deve prendere solo quelli di Previsione
select p_anno_prospetto::varchar anno_prosp,
''::varchar missione_code,
''::varchar missione_desc, 
cl2.classif_code programma_code,
''::varchar programma_desc, 
0::integer elem_id,
crono_elem.cronop_elem_code numero_capitolo,
0::integer anno_impegno,
0::integer numero_impegno,
0::numeric spese_impegnate,
0::numeric importo_avanzo,
case when p_anno = p_anno_prospetto 
    	then 0
		else COALESCE(sum(crono_elem_det.cronop_elem_det_importo),0) end importo_colonna_d_Anno_prec,
0::numeric spese_impegnate_da_prev,
pr.programma_code progetto,
crono.cronop_code cronoprogramma
from siac_t_programma pr, siac_t_cronop crono, 
     siac_t_bil bil, siac_t_periodo anno_bil, siac_d_programma_tipo tipo_prog,
     siac_t_cronop_elem crono_elem, siac_d_bil_elem_tipo crono_elem_tipo,
     siac_t_cronop_elem_det crono_elem_det, siac_t_periodo anno_crono_elem_det,
     siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
     siac_r_cronop_stato stc , siac_d_cronop_stato stct,
     siac_r_programma_stato stpr, siac_d_programma_stato stprt
where pr.programma_id=crono.programma_id
      and crono.bil_id = bil.bil_id
      and bil.periodo_id=anno_bil.periodo_id
      and tipo_prog.programma_tipo_id = pr.programma_tipo_id
      and crono_elem.cronop_id=crono.cronop_id
      and crono_elem.cronop_elem_id=crono_elem_det.cronop_elem_id
      and crono_elem_tipo.elem_tipo_id=crono_elem.elem_tipo_id
      and rcl2.cronop_elem_id = crono_elem.cronop_elem_id
      and rcl2.classif_id=cl2.classif_id
      and cl2.classif_tipo_id=clt2.classif_tipo_id
      and crono_elem_det.periodo_id = anno_crono_elem_det.periodo_id
      and stc.cronop_id=crono.cronop_id
      and stc.cronop_stato_id=stct.cronop_stato_id
      and stpr.programma_id=pr.programma_id
      and stpr.programma_stato_id=stprt.programma_stato_id                          
      and pr.ente_proprietario_id= p_ente_prop_id
      and anno_bil.anno=p_anno -- anno bilancio
      and crono.usato_per_fpv::boolean = true
      and crono_elem_det.anno_entrata = annoprospetto_prec_int::varchar -- anno prospetto           
      and anno_crono_elem_det.anno::integer=annoprospetto_prec_int +1 -- anno prospetto
      and clt2.classif_tipo_code='PROGRAMMA'
      and stct.cronop_stato_code='VA'
--SIAC-8866 21/06/2023
--il calcolo degll'importo dei progetti deve prendere solo quelli di Previsione      
      and tipo_prog.programma_tipo_code ='P'  --Solo progetti della previsione.
      and stprt.programma_stato_code='VA'
      and stpr.data_cancellazione is null
      and stc.data_cancellazione is null
      and crono.data_cancellazione is null
      and pr.data_cancellazione is null
      and bil.data_cancellazione is null
      and anno_bil.data_cancellazione is null
      and crono_elem.data_cancellazione is null
      and crono_elem_det.data_cancellazione is null
      and rcl2.data_cancellazione is null
group by cl2.classif_code ,crono_elem.cronop_elem_code, pr.programma_code, crono.cronop_code
/* SIAC-8866 26/06/2023.
    Nel report BILR011 l'importo della colonna D anno precedente e' dato non solo dai progetti ma anche dagli impegni.
    Aggiungo la query.
*/
union
select *
from(
with struttura as (
    select *
    from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,(p_anno::integer - 1)::varchar, null)
    ),
    capitoli as (
    select 	programma.classif_id programma_id,
            macroaggr.classif_id macroaggregato_id,
            capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
            capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
    from siac_t_bil_elem capitolo,
         siac_d_bil_elem_tipo tipo_elemento,
         siac_r_bil_elem_stato r_capitolo_stato,
         siac_d_bil_elem_stato stato_capitolo,      
         siac_r_bil_elem_class r_capitolo_programma,
         siac_r_bil_elem_class r_capitolo_macroaggr, 	 
         siac_d_bil_elem_categoria cat_del_capitolo,
         siac_r_bil_elem_categoria r_cat_capitolo,
         siac_d_class_tipo programma_tipo,
         siac_t_class programma,
         siac_d_class_tipo macroaggr_tipo,
         siac_t_class macroaggr
    where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
    and capitolo.elem_id = r_capitolo_stato.elem_id							
    and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
    and	capitolo.elem_id = r_capitolo_programma.elem_id							
    and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
    and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
    and programma.classif_id = r_capitolo_programma.classif_id					
    and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
    and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
    and	capitolo.elem_id = r_cat_capitolo.elem_id				
    and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
    and capitolo.ente_proprietario_id = p_ente_prop_id							
    and capitolo.bil_id = bilancio_id_prec --anno precedente													
    and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
    and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
    and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
    and stato_capitolo.elem_stato_code = 'VA' 
    -- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
    and	programma_tipo.data_cancellazione 			is null
    and	programma.data_cancellazione 				is null
    and	macroaggr_tipo.data_cancellazione 			is null
    and	macroaggr.data_cancellazione 				is null
    and	capitolo.data_cancellazione 				is null
    and	tipo_elemento.data_cancellazione 			is null
    and	r_capitolo_programma.data_cancellazione 	is null
    and	r_capitolo_macroaggr.data_cancellazione 	is null 
    and	stato_capitolo.data_cancellazione 			is null 
    and	r_capitolo_stato.data_cancellazione 		is null
    and	cat_del_capitolo.data_cancellazione 		is null
    and	r_cat_capitolo.data_cancellazione           is null
    ),
    impegni as(
    select distinct accert.*, imp.*, ts_impegni_legati.movgest_ts_b_id
    from siac_r_movgest_ts ts_impegni_legati    	
         join (	--accertamenti
         		select ts_mov_acc.movgest_ts_id,
                        mov_acc.movgest_anno anno_acc, 
                        mov_acc.movgest_numero numero_acc,
                        ts_mov_det_acc.movgest_ts_det_importo importo_acc
                    from siac_t_movgest mov_acc,
                         siac_t_movgest_ts ts_mov_acc,					
                         siac_t_movgest_ts_det ts_mov_det_acc,
                         siac_r_movgest_ts_stato r_stato_acc,
                         siac_d_movgest_stato stato_acc
                    where mov_acc.movgest_id=ts_mov_acc.movgest_id
                        and ts_mov_acc.movgest_ts_id=ts_mov_det_acc.movgest_ts_id
                        and ts_mov_acc.movgest_ts_id=r_stato_acc.movgest_ts_id
                        and r_stato_acc.movgest_stato_id=stato_acc.movgest_stato_id
                        and mov_acc.ente_proprietario_id=p_ente_prop_id
                        and mov_acc.movgest_anno = annoprospetto_prec_int --accertamenti sempre dell'anno prospetto
                        and stato_acc.movgest_stato_code in ('D','N')
                        and r_stato_acc.data_cancellazione IS NULL
                        and mov_acc.data_cancellazione IS NULL
                        and ts_mov_acc.data_cancellazione IS NULL) accert
            on accert.movgest_ts_id =  ts_impegni_legati.movgest_ts_a_id
          join (--impegni
          		select ts_mov_imp.movgest_ts_id,
                        mov_imp.movgest_anno anno_imp, 
                        mov_imp.movgest_numero numero_imp,
                        r_imp_bil_elem.elem_id,
                        ts_mov_det_imp.movgest_ts_det_importo importo_imp
                    from siac_t_movgest mov_imp,
                         siac_t_movgest_ts ts_mov_imp,					
                         siac_t_movgest_ts_det ts_mov_det_imp,
                         siac_r_movgest_ts_stato r_stato_imp,
                         siac_d_movgest_stato stato_imp,
                         siac_r_movgest_bil_elem r_imp_bil_elem
                    where mov_imp.movgest_id=ts_mov_imp.movgest_id
                        and ts_mov_imp.movgest_ts_id=ts_mov_det_imp.movgest_ts_id
                        and ts_mov_imp.movgest_ts_id=r_stato_imp.movgest_ts_id
                        and r_stato_imp.movgest_stato_id=stato_imp.movgest_stato_id
                        and r_imp_bil_elem.movgest_id=mov_imp.movgest_id
                        and mov_imp.ente_proprietario_id=p_ente_prop_id
                        and mov_imp.bil_id = bilancio_id_prec --anno precedente di gestione
                        and mov_imp.movgest_anno >= annoprospetto_prec_int + 1 --impegni a partire dell'anno prospetto + 1
                        and stato_imp.movgest_stato_code in ('D','N')
                        and r_stato_imp.data_cancellazione IS NULL
                        and mov_imp.data_cancellazione IS NULL
                        and ts_mov_imp.data_cancellazione IS NULL
                        and r_imp_bil_elem.data_cancellazione IS NULL) imp              
            on imp.movgest_ts_id =  ts_impegni_legati.movgest_ts_b_id
          left join (--legame con i progetti 
          		select r_mov_progr.movgest_ts_id, progetto.programma_id
                  from siac_t_programma progetto, siac_t_cronop crono, 
                      siac_t_bil bil, siac_t_periodo anno_bil,
                      siac_r_cronop_stato r_cronop_stato , siac_d_cronop_stato cronop_stato,
                      siac_r_programma_stato r_progetto_stato, siac_d_programma_stato progetto_stato,
                     siac_r_movgest_ts_programma r_mov_progr             
                  where progetto.programma_id=crono.programma_id
                      and crono.bil_id = bil.bil_id
                      and bil.periodo_id=anno_bil.periodo_id
                      and r_cronop_stato.cronop_stato_id=cronop_stato.cronop_stato_id
                      and r_cronop_stato.cronop_id=crono.cronop_id
                      and r_progetto_stato.programma_id=progetto.programma_id
                      and r_progetto_stato.programma_stato_id=progetto_stato.programma_stato_id     
                      and r_mov_progr.programma_id=progetto.programma_id                      
                      and progetto.ente_proprietario_id= p_ente_prop_id
                      and anno_bil.anno::integer=p_anno::integer-1--annoprospetto_prec_int - 1 -- anno precedente quello del bilancio?
                      and crono.usato_per_fpv::boolean = true--conflagfpv                                                  
                      and cronop_stato.cronop_stato_code='VA'              
                      and progetto_stato.programma_stato_code='VA'
                      and r_progetto_stato.data_cancellazione is null
                      and r_cronop_stato.data_cancellazione is null
                      and crono.data_cancellazione is null
                      and progetto.data_cancellazione is null
                      and bil.data_cancellazione is null
                      and r_mov_progr.data_cancellazione is null) progetti
             on ts_impegni_legati.movgest_ts_b_id = progetti.movgest_ts_id
    where ts_impegni_legati.ente_proprietario_id=p_ente_prop_id      
        and ts_impegni_legati.avav_id is null
        and ts_impegni_legati.data_cancellazione is null  
        	--progetti.programma_id IS NULL cioe' non sono compresi negli impegni legati ai progetti estratti
            --nelle query precedenti. In pratica non devo contarli 2 volte.
        and progetti.programma_id IS NULL )
    select --struttura.programma_code::varchar programma,    
    p_anno_prospetto::varchar anno_prosp,
	struttura.missione_code::varchar missione_code,
	struttura.missione_desc::varchar missione_desc, 
	struttura.programma_code programma_code,
	struttura.programma_desc::varchar programma_desc, 
	capitoli.elem_id::integer elem_id,
	capitoli.elem_code::varchar numero_capitolo,
	impegni.anno_imp::integer anno_impegno,
	impegni.numero_imp::integer numero_impegno,
	0::numeric spese_impegnate,
	0::numeric importo_avanzo,
	case when p_anno = p_anno_prospetto 
    	then 0
        else COALESCE(sum(impegni.importo_imp),0) end importo_colonna_d_Anno_prec,
	0::numeric spese_impegnate_da_prev,
    ''::varchar programma,
    ''::varchar cronoprogramma 
    from impegni
        left join capitoli 
            on impegni.elem_id=capitoli.elem_id 
        left join struttura 
            on struttura.programma_id = capitoli.programma_id
                and struttura.macroag_id = capitoli.macroaggregato_id        
    where impegni.anno_imp = annoprospetto_int
    group by anno_prosp, struttura.missione_code,struttura. missione_desc, struttura.programma_code, struttura.programma_desc, 
    	capitoli.elem_id, capitoli.elem_code, impegni.anno_imp, impegni.numero_imp) aaa     ) 
select * from tutto 
union 
--aggiungo la riga dei totali
select tutto.anno_prosp anno_prospetto,
 '' missione_code,
 '' missione_desc,
 'Totale' programma_code ,
 '' programma_desc,  
 0 elem_id,
 '' numero_capitolo,
 0 anno_impegno,
 0 numero_impegno,
 sum(tutto.spese_impegnate) spese_impegnate,
 sum(tutto.importo_avanzo) importo_avanzo,
 sum(tutto.importo_colonna_d_Anno_prec) importo_colonna_d_Anno_prec,
 sum(tutto.spese_impegnate_da_prev) spese_impegnate_da_prev,
 ''::varchar programma,
 ''::varchar cronoprogramma 
from tutto
group by anno_prospetto;

exception
when no_data_found THEN
raise notice 'Nessun dato trovato';
return;
when others  THEN
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;  
  
--SIAC-8866 - Maurizio - FINE
  




-- INIZIO SIAC-8900.sql



\echo SIAC-8900.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-8900 - Paolo - INIZIO
/*per il parametro PROGETTO_ABILITA_GESTIONE_ESERCIZIO_PROVVISORIO*/
insert into siac_t_parametro_config_ente (
	ente_proprietario_id,
	parametro_nome,
	parametro_valore,
	parametro_note,
	validita_inizio,
	login_operazione 
) select 
	e.ente_proprietario_id ,
	x.nome,
	true,
	x.note,
	now(),
	'admin'
 from siac_t_ente_proprietario e, 
(values 
	('progetto.abilita.gestione.esercizioProvvisorio', 'Abilita gestione esercizio provvisorio') 
) as x (nome, note) 
where not exists ( select 1 from siac_t_parametro_config_ente p where parametro_nome = x.nome and e.ente_proprietario_id = p.ente_proprietario_id)
and e.ente_code in ('REGP', 'CMTO', 'AIPO', 'CRP')
and e.in_uso
; 

--SIAC-8900 - Paolo - FINE




-- INIZIO task-134.sql



\echo task-134.sql


/*
 * task-134
 * Paolo Simone
 */

select fnc_siac_bko_inserisci_azione('OP-BKOF020-aggiornaAccertamentoConBloccoRagioneria',
									 'Accertamenti - Backoffice aggiorna accertamento con blocco ragioneria', 
									 '/../siacboapp/azioneRichiesta.do', 'ATTIVITA_SINGOLA', 'FUN_ACCESSORIE'
);




-- INIZIO task-135.sql



\echo task-135.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_siac_gsa_ordinativo
(
  p_anno_bilancio varchar,
  p_tipo_ord           varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_gsa_ordinativo
(p_anno_bilancio varchar, 
 p_tipo_ord           varchar,
 p_ente_proprietario_id integer, 
 p_data timestamp without time zone)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
v_user_table varchar;
params varchar;
p_bilancio_id integer:=null;


annoBilancio integer;
annoBilancio_ini integer;
codResult integer:=null;
annoRec record;

ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

BEGIN


select fnc_siac_random_user()
into	v_user_table;


IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;


if p_tipo_ord is not null and   p_tipo_ord not in ('I','P','E') then 
	RAISE EXCEPTION 'Errore: Parametro Tipo Ordinativo non valido [I,P]';
    RETURN;
 else 
     if p_tipo_ord is null then p_tipo_ord:='E';  
     end if;
 end if;

IF p_data IS NULL THEN
   p_data := now();
END IF;

if p_anno_bilancio is null then 
    annoBilancio:=extract('YEAR' from now())::integer;
else 
    annoBilancio:=p_anno_bilancio::integer;
end if;
annoBilancio_ini:=annoBilancio;


 params := annoBilancio::varchar||' - '||p_tipo_ord||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;

 esito:= 'Inizio funzione carico ordinativi  GSA (fnc_siac_gsa_ordinativo) - '||clock_timestamp(); 
 RETURN NEXT;
 insert into
 siac_gsa_ordinativi_log_elab 
 (
 ente_proprietario_id,
 fnc_name ,
 fnc_parameters ,
 fnc_elaborazione_inizio ,
 fnc_user
 )
 values 
 (
 p_ente_proprietario_id,
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 ); 

 esito:='Parametri='||params; 
 RETURN next;
 insert into
 siac_gsa_ordinativi_log_elab 
 (  
 ente_proprietario_id,
 fnc_name ,
 fnc_parameters ,
 fnc_elaborazione_inizio ,
 fnc_user
 )
 values 
 (
 p_ente_proprietario_id,
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 );

esito:= '  Inizio eliminazione dati pregressi into siac_gsa_ordinativo - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

DELETE FROM siac.siac_gsa_ordinativo
WHERE ente_proprietario_id = p_ente_proprietario_id;

esito:= '  Fine eliminazione dati pregressi into siac_gsa_ordinativo - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

 esito:='  Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
 -- Aggiungere parametro per non estrarre anno-1
 select 1 into codResult
 from siac_t_bil bil,siac_t_periodo per,
	       siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
 where per.ente_proprietario_id=p_ente_proprietario_id  
 and     per.anno::integer=annoBilancio-1
 and     bil.periodo_id=per.periodo_id
 and     r.bil_id=bil.bil_id 
 and     fase.fase_operativa_id=r.fase_operativa_id
 and     fase.fase_operativa_code in (ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
 if codResult is not null then
        codResult:=null;
        select 1 into codResult
        from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
        where tipo.ente_proprietario_id=p_ente_proprietario_id
        and      tipo.gestione_tipo_code='SCARICO_GSA_ORD_ANNO_PREC'  
        and      liv.gestione_tipo_id=tipo.gestione_tipo_id
        and      liv.gestione_livello_code=(annoBilancio-1)::varchar
        and      tipo.data_cancellazione is null 
        and      tipo.validita_fine is null 
        and      liv.data_cancellazione is null 
        and      liv.validita_fine is null;
		if codResult is not null then
			    	annoBilancio_ini:=annoBilancio-1;
	    end if;  
 end if;	   
 if   codResult is not null then
	           esito:=esito||'  Carico ordinativi GSA annoBilancio='||annoBilancio_ini::varchar||' e annoBilancio='||annoBilancio::varchar||'.';
 else       esito:=esito||'  Carico ordinativi GSA annoBilancio='||annoBilancio::varchar||'.';
 end if;
 RETURN next;

 insert into
 siac_gsa_ordinativi_log_elab 
 (  
 ente_proprietario_id,
 fnc_name ,
 fnc_parameters ,
 fnc_elaborazione_inizio ,
 fnc_user
 )
 values 
 (
 p_ente_proprietario_id,
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 );  


 esito:='  Carico ordinativi GSA annoBilancio='||annoBilancio_ini::varchar||' e annoBilancio='||annoBilancio::varchar||'. Prima di inizio ciclo.';
 RETURN next;
 for annoRec in
 (
    select *
    from
   	(select annoBilancio_ini anno_elab
     union
     select annoBilancio anno_elab
    ) query
    order by 1
)
loop
    esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo.';
    RETURN next;
   
    if p_tipo_ord in ('I','E') then 
   	 -- scarico ordinativi di incasso
     esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo per incassi.';
     RETURN next;
     return query  select fnc_siac_gsa_ordinativo_incasso (annoRec.anno_elab::varchar,p_ente_proprietario_id, p_data);
     
     esito:= '  Inizio caricamento incassi into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;	
     insert into siac_gsa_ordinativo 
     (
	     ente_proprietario_id,
   	     anno_bilancio,
   	     ord_tipo,
	     ord_anno,
		 ord_numero,
		 ord_desc,
		 ord_stato_code,
	 	 ord_data_emissione,
		 ord_data_firma,
		 ord_data_quietanza,
		 ord_data_annullo,
   	 	 numero_capitolo,
    	 numero_articolo,
      	 capitolo_desc,
    	 soggetto_code,
    	 soggetto_desc,
		 pdc_fin_liv_1,
		 pdc_fin_liv_2,
		 pdc_fin_liv_3,
		 pdc_fin_liv_4,
		 pdc_fin_liv_5,
	 	 ord_sub_numero, 
	 	 ord_sub_importo,
	  	 ord_sub_desc,
	     movgest_anno,
	     movgest_numero,
	     movgest_sub_numero,
	     movgest_gsa,
	     movgest_attoamm_tipo_code,
	     movgest_attoamm_anno,
	     movgest_attoamm_numero,
	     movgest_attoamm_sac,
	     liq_attoamm_tipo_code,
	     liq_attoamm_anno,
	     liq_attoamm_numero,
	     liq_attoamm_sac
     )
     select 
         inc.ente_proprietario_id,
   	     inc.anno_bilancio,
   	     'E',
	     inc.ord_anno,
		 inc.ord_numero,
		 inc.ord_desc,
		 inc.ord_stato_code,
	 	 to_char(inc.ord_data_emissione,'YYYYMMDD'),
		 to_char(inc.ord_data_firma,'YYYYMMDD'),
		 to_char(inc.ord_data_quietanza,'YYYYMMDD'),
		 to_char(inc.ord_data_annullo,'YYYYMMDD'),
   	 	 inc.numero_capitolo,
    	 inc.numero_articolo,
      	 inc.capitolo_desc,
    	 inc.soggetto_code,
    	 inc.soggetto_desc,
		 inc.pdc_fin_liv_1,
 		 inc.pdc_fin_liv_2,
		 inc.pdc_fin_liv_3,
 		 inc.pdc_fin_liv_4,
 		 inc.pdc_fin_liv_5,
	 	 inc.ord_sub_numero, 
	 	 inc.ord_sub_importo,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	  	 --inc.ord_sub_desc,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	 	 --replace(replace(substring( inc.ord_desc,1,255),chr(10),''),chr(13),''),
translate
( 
substring( inc.ord_desc,1,255),
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar),
	     inc.movgest_anno,
	     inc.movgest_numero,
	     inc.movgest_sub_numero,
	     inc.movgest_gsa,
	     inc.movgest_attoamm_tipo_code,
	     inc.movgest_attoamm_anno,
	     inc.movgest_attoamm_numero,
	     inc.movgest_attoamm_sac,
	     inc.ord_attoamm_tipo_code,
	     inc.ord_attoamm_anno,
	     inc.ord_attoamm_numero,
	     inc.ord_attoamm_sac
     from siac_gsa_ordinativo_incasso inc 
     where inc.anno_bilancio =annoRec.anno_elab
     and     inc.ente_proprietario_id =p_ente_proprietario_id ;
     
     esito:= '  Fine caricamento incassi into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;	
    end if;
    if p_tipo_ord in ('P','E') then 
      	-- scarico ordinativi di pagamento
     esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo per pagamenti.';
     RETURN next;
     return query select fnc_siac_gsa_ordinativo_pagamento (annoRec.anno_elab::varchar,p_ente_proprietario_id, p_data);
     
    esito:= '  Inizio caricamento pagamenti into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
 	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;
     insert into siac_gsa_ordinativo 
     (
	     ente_proprietario_id,
   	     anno_bilancio,
   	     ord_tipo,
	     ord_anno,
		 ord_numero,
		 ord_desc,
		 ord_stato_code,
	 	 ord_data_emissione,
		 ord_data_firma,
		 ord_data_quietanza,
		 ord_data_annullo,
   	 	 numero_capitolo,
    	 numero_articolo,
      	 capitolo_desc,
    	 soggetto_code,
    	 soggetto_desc,
		 pdc_fin_liv_1,
		 pdc_fin_liv_2,
		 pdc_fin_liv_3,
		 pdc_fin_liv_4,
		 pdc_fin_liv_5,
	 	 ord_sub_numero, 
	 	 ord_sub_importo,
	  	 ord_sub_desc,
	     movgest_anno,
	     movgest_numero,
	     movgest_sub_numero,
	     movgest_gsa,
	     movgest_attoamm_tipo_code,
	     movgest_attoamm_anno,
	     movgest_attoamm_numero,
	     movgest_attoamm_sac,
	     liq_anno,
	     liq_numero,
	     liq_attoamm_tipo_code,
	     liq_attoamm_anno,
	     liq_attoamm_numero,
	     liq_attoamm_sac
     )
     select 
         pag.ente_proprietario_id,
   	     pag.anno_bilancio,
   	     'U',
	     pag.ord_anno,
		 pag.ord_numero,
		 pag.ord_desc,
		 pag.ord_stato_code,
	 	 to_char(pag.ord_data_emissione,'YYYYMMDD'),
		 to_char(pag.ord_data_firma,'YYYYMMDD'),
		 to_char(pag.ord_data_quietanza,'YYYYMMDD'),
		 to_char(pag.ord_data_annullo,'YYYYMMDD'),
   	 	 pag.numero_capitolo,
    	 pag.numero_articolo,
      	 pag.capitolo_desc,
    	 pag.soggetto_code,
    	 pag.soggetto_desc,
		 pag.pdc_fin_liv_1,
		 pag.pdc_fin_liv_2,
		 pag.pdc_fin_liv_3,
		 pag.pdc_fin_liv_4,
		 pag.pdc_fin_liv_5,
	 	 pag.ord_sub_numero, 
	 	 pag.ord_sub_importo,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	  	 -- pag.ord_sub_desc,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
--	 	 replace(replace(substring( pag.ord_desc,1,255),chr(10),''),chr(13),''),
translate
( 
substring( pag.ord_desc,1,255),
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar),	 	 
	     pag.movgest_anno,
	     pag.movgest_numero,
	     pag.movgest_sub_numero,
	     pag.movgest_gsa,
	     pag.movgest_attoamm_tipo_code,
	     pag.movgest_attoamm_anno,
	     pag.movgest_attoamm_numero,
	     pag.movgest_attoamm_sac,
	     pag.liq_anno,
	     pag.liq_numero,
	     pag.liq_attoamm_tipo_code,
	     pag.liq_attoamm_anno,
	     pag.liq_attoamm_numero,
	     pag.liq_attoamm_sac
     from siac_gsa_ordinativo_pagamento pag 
     where pag.anno_bilancio =annoRec.anno_elab
     and     pag.ente_proprietario_id =p_ente_proprietario_id;
     
     esito:= '  Fine caricamento pagamenti into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
 	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;
    
    end if;
end loop;
   

esito:= 'Fine funzione carico ordinativi  GSA (fnc_siac_gsa_ordinativo) - '||clock_timestamp();
RETURN NEXT;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

 
update siac_gsa_ordinativi_log_elab  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()- fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi GSA (fnc_siac_gsa_ordinativi terminata con errori '||sqlstate||'-'||SQLERRM;
  raise notice 'esito=%',esito;
--  RAISE NOTICE '% %-%.',esito, SQLSTATE,SQLERRM;
  return next;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter function  siac.fnc_siac_gsa_ordinativo (  varchar, varchar,integer, timestamp) owner to siac;




-- INIZIO task-136.sql



\echo task-136.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
DROP FUNCTION IF EXISTS  siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita(
	p_loginoperazione character varying, 
	p_enteproprietarioid integer, 
	p_ordtipocode character varying, 
	p_annobilancio character varying, 
	p_ord_anno integer, 
	p_ordnumero integer, 
	p_ambito character varying, 
	p_eventocode character varying, 
	p_eventotipocode character varying, 
	p_pdcordinativo integer
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita(
	p_loginoperazione character varying, 
	p_enteproprietarioid integer, 
	p_ordtipocode character varying, 
	p_annobilancio character varying, 
	p_ord_anno integer, 
	p_ordnumero integer, 
	p_ambito character varying, 
	p_eventocode character varying, 
	p_eventotipocode character varying, 
	p_pdcordinativo integer
)
RETURNS VARCHAR
AS $body$
DECLARE
	v_messaggiorisultato VARCHAR:= NULL;
	v_id INTEGER:=NULL;
	v_id_stato INTEGER:=NULL;
	v_id_evento INTEGER:=NULL;
	v_result INTEGER:=NULL;
    v_login_operazione VARCHAR:='BackofficeModificaPianoDeiContiOrdinativo';
   	v_ambito VARCHAR:=NULL;
BEGIN
	
	v_messaggiorisultato:= ' INSERIMENTO REGISTRO ';
	--   raise notice '@@@QUI QUI QUI QUI  p_pdcOrdinativo %****', p_pdcOrdinativo::varchar;
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
--   raise notice '@@@QUI QUI QUI QUI  p_pdcOrdinativo %****', p_pdcOrdinativo::varchar;
 --  raise notice '@@@QUI QUI QUI QUI  p_enteproprietarioid %****', p_enteproprietarioid::varchar;
  -- raise notice '@@@QUI QUI QUI QUI  p_ordtipocode %****', p_ordtipocode::varchar;
--   raise notice '@@@QUI QUI QUI QUI  p_annobilancio %****', p_annobilancio::varchar;
--   raise notice '@@@QUI QUI QUI QUI  p_ord_anno %****', p_ord_anno::varchar;
 --  raise notice '@@@QUI QUI QUI QUI  p_ordnumero %****', p_ordnumero::varchar;
 --   raise notice '@@@QUI QUI QUI QUI  p_ambito %****', p_ambito::varchar;
  	INSERT INTO siac_t_reg_movfin 
	(
	    classif_id_iniziale,
	    classif_id_aggiornato,
	    bil_id,
	    ambito_id,
	    validita_inizio,
	    login_operazione,
	    ente_proprietario_id
	)
	SELECT DISTINCT
	(
		SELECT DISTINCT stc.classif_id 
		FROM siac_t_class stc
		JOIN siac_t_ente_proprietario step ON stc.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
		JOIN siac_r_ordinativo_class sroc ON sroc.classif_id = stc.classif_id
		JOIN siac.siac_r_class_fam_tree srcft ON ( srcft.classif_id = stc.classif_id ) 
		JOIN siac.siac_t_class_fam_tree stcft ON ( stcft.classif_fam_tree_id = srcft.classif_fam_tree_id AND stcft.class_fam_code = 'Piano dei Conti' ) 
		JOIN siac_t_ordinativo sto ON sto.ord_id = sroc.ord_id 
		JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
		JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
		JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id
		WHERE stp.anno = p_annoBilancio
		AND sto.ord_numero = p_ordNumero
		AND sto.ord_anno = p_ord_anno
		AND sdot.ord_tipo_code = p_ordTipoCode
		AND sto.data_cancellazione is NULL
		AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
		AND sdot.data_cancellazione is NULL
		AND ( sdot.validita_fine is NULL OR sdot.validita_fine < CURRENT_TIMESTAMP )
		AND sroc.data_cancellazione is NULL
		AND ( sroc.validita_fine is NULL OR sroc.validita_fine < CURRENT_TIMESTAMP )
		AND stc.data_cancellazione is NULL
		AND ( stc.validita_fine is NULL OR stc.validita_fine < CURRENT_TIMESTAMP )
		AND srcft.data_cancellazione is NULL
		AND ( srcft.validita_fine is NULL OR srcft.validita_fine < CURRENT_TIMESTAMP )
	),
	p_pdcOrdinativo,
	(
		SELECT DISTINCT stb.bil_id   -- 30.06.2023 Sofia SIAC-TASK-136
		FROM siac_t_ordinativo sto, siac_d_ordinativo_tipo sdot ,siac_t_bil stb,siac_t_periodo stp
		WHERE   stp.ente_proprietario_id =p_enteProprietarioId
		and            stp.anno = p_annoBilancio
		and            stb.periodo_id = stp.periodo_id 
		and            sto.bil_id = stb.bil_id
		and            sto.ord_tipo_id = sdot.ord_tipo_id
		AND          sdot.ord_tipo_code = p_ordTipoCode		
		AND          sto.ord_numero = p_ordNumero
		AND          sto.ord_anno = p_ord_anno
		AND sto.data_cancellazione is NULL
		AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
		AND sdot.data_cancellazione is NULL
		AND ( sdot.validita_fine is NULL OR sdot.validita_fine < CURRENT_TIMESTAMP )
		AND stp.data_cancellazione is NULL
		AND ( stp.validita_fine is NULL OR stp.validita_fine < CURRENT_TIMESTAMP )
		AND stb.data_cancellazione is NULL
		AND ( stb.validita_fine is NULL OR stp.validita_fine < CURRENT_TIMESTAMP )
	),
	(
		SELECT DISTINCT sda.ambito_id
		FROM siac_d_ambito sda 
		JOIN siac_t_ente_proprietario step ON step.ente_proprietario_id = sda.ente_proprietario_id and step.ente_proprietario_id = p_enteProprietarioId
		WHERE sda.ambito_code = p_ambito
		AND sda.data_cancellazione is NULL
		AND ( sda.validita_fine is NULL OR sda.validita_fine < CURRENT_TIMESTAMP ) 
	),
	now(),
	p_loginOperazione,
	p_enteProprietarioId
	RETURNING regmovfin_id INTO v_id;
	 --raise notice '2 @@@ QUI QUI QUI QUI ****';
	  
	  
	IF v_id IS NOT NULL THEN
		v_messaggiorisultato:=' INSERITO REGISTRO con id: '||v_id||'.';
	ELSE
		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
	END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
	
  	v_messaggiorisultato:= ' ASSOCIAZIONE REGISTRO con id: '||v_id||' A STATO: [NOTIFICATO] ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
    
  	INSERT INTO siac_r_reg_movfin_stato
	(
	    regmovfin_id,
	    regmovfin_stato_id,
	    validita_inizio,
	    login_operazione,
	    ente_proprietario_id
	)
	SELECT v_id,
		sdrms.regmovfin_stato_id,
		now(),
		p_loginOperazione,
		p_enteProprietarioId
	FROM siac_t_ordinativo sto
	JOIN siac_t_ente_proprietario step on sto.ente_proprietario_id = step.ente_proprietario_id and step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_d_ordinativo_tipo sdot on sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_bil stb on sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp on stp.periodo_id = stb.periodo_id 
	JOIN siac_d_reg_movfin_stato sdrms on sdrms.ente_proprietario_id = step.ente_proprietario_id
	WHERE stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND sdrms.regmovfin_stato_code = 'N'
	RETURNING regmovfin_stato_r_id INTO v_id_stato;

	IF v_id_stato IS NOT NULL THEN
		v_messaggiorisultato:=' ASSOCIATO REGISTRO con id: '||v_id||' A STATO: [NOTIFICATO] ';
	ELSE
		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
	END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
  
  	v_messaggiorisultato:= ' ASSOCIAZIONE REGISTRO con id: '||v_id||' AD EVENTO: ['||p_eventoCode||']';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;
    
  	INSERT INTO siac_r_evento_reg_movfin 
	(
		regmovfin_id,
		evento_id,
		campo_pk_id,
		validita_inizio,
		login_operazione,
		ente_proprietario_id
	)
	SELECT DISTINCT
	    v_id,
	    sde.evento_id,
	    sto.ord_id,
	    now(),
	    p_loginOperazione,
	    sto.ente_proprietario_id
	FROM siac_t_ordinativo sto 
	JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
	JOIN siac_r_evento_reg_movfin srerm ON sto.ord_id = srerm.campo_pk_id
	JOIN siac_d_evento sde ON step.ente_proprietario_id = sde.ente_proprietario_id 
	JOIN siac_d_evento_tipo sdet ON sde.evento_tipo_id = sdet.evento_tipo_id 
	JOIN siac_t_reg_movfin strm ON srerm.regmovfin_id = strm.regmovfin_id 
	WHERE stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND sde.evento_code = p_eventoCode
	AND sdet.evento_tipo_code = p_eventoTipoCode
	-- controllare lo stesso anno di bilancio sulla r
	AND strm.bil_id = stb.bil_id 
	AND sto.data_cancellazione is NULL
	AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
	AND srerm.data_cancellazione is NULL
	AND ( srerm.validita_fine is NULL OR srerm.validita_fine < CURRENT_TIMESTAMP )
	RETURNING evmovfin_id INTO v_id_evento;
  
	IF v_id_evento IS NOT NULL THEN
		v_messaggiorisultato:=' ASSOCIATO REGISTRO con id: '||v_id||' AD EVENTO: ['||p_eventoCode||']';
	ELSE
		RAISE EXCEPTION 'NESSUN RECORD INSERITO PER: % ', v_messaggiorisultato;		
	END IF;

  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
--  
  	v_messaggiorisultato:= ' INVALIDAMENTO RECORD PRECEDENTE ';
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;

	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% INIZIO',v_messaggiorisultato;

	UPDATE siac_r_evento_reg_movfin srerm
	SET data_cancellazione = now(),
		validita_fine = now(),
		login_operazione = srerm.login_operazione||' - '||p_loginOperazione
	FROM siac_t_reg_movfin strm , siac_d_ambito sda , siac_t_ordinativo sto 
	JOIN siac_t_ente_proprietario step ON sto.ente_proprietario_id = step.ente_proprietario_id AND step.ente_proprietario_id = p_enteProprietarioId
	JOIN siac_d_ordinativo_tipo sdot ON sto.ord_tipo_id = sdot.ord_tipo_id 
	JOIN siac_t_bil stb ON sto.bil_id = stb.bil_id 
	JOIN siac_t_periodo stp ON stb.periodo_id = stp.periodo_id 
	WHERE srerm.regmovfin_id = strm.regmovfin_id
	AND sda.ambito_id = strm.ambito_id
	AND sto.ord_id = srerm.campo_pk_id
	-- controllare lo stesso anno di bilancio sulla r
	AND strm.bil_id = stb.bil_id 
	AND stp.anno = p_annoBilancio
	AND sto.ord_numero = p_ordNumero
	AND sto.ord_anno = p_ord_anno
	AND sdot.ord_tipo_code = p_ordTipoCode
	AND srerm.evmovfin_id != v_id_evento
	AND sda.ambito_code = p_ambito
	AND sto.data_cancellazione is NULL
	AND ( sto.validita_fine is NULL OR sto.validita_fine < CURRENT_TIMESTAMP )
	AND srerm.data_cancellazione is NULL
	AND ( srerm.validita_fine is NULL OR srerm.validita_fine < CURRENT_TIMESTAMP );
	
	IF p_loginOperazione != '' THEN
		v_login_operazione:= p_loginOperazione;
		v_messaggiorisultato:= v_messaggiorisultato || ' - LOGIN OPERAZIONE: ' || v_login_operazione;
	END IF;
	
	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_aggiorna_contabilita] v_messaggiorisultato=% FINE',v_messaggiorisultato;
  
  	v_result:= 0;
  	v_ambito:= p_ambito;
  
  	RAISE NOTICE '[fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita] INSERIMENTO CONTABILITA % COMPLETATO.', v_ambito;
  	
  	RETURN v_result;
  
EXCEPTION
    WHEN RAISE_EXCEPTION THEN
    v_messaggiorisultato:=v_messaggiorisultato|| ' - ' ||SUBSTRING(UPPER(SQLERRM) from 1 for 2500);
    RAISE NOTICE '%',v_messaggiorisultato;
        v_result = v_messaggiorisultato;
   		RETURN v_result;
	WHEN OTHERS THEN
	v_messaggiorisultato:=v_messaggiorisultato|| ' OTHERS - ' ||SUBSTRING(UPPER(SQLERRM) from 1 for 2500);
    RAISE NOTICE '%',v_messaggiorisultato;
		v_result = v_messaggiorisultato;
   		RETURN v_result;
  
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100;

alter function  siac.fnc_siac_bko_modifica_pdc_ordinativo_inserisci_contabilita  ( character varying,  integer,  character varying,  character varying,  integer,  integer,  character varying,  character varying, character varying,  integer )  owner to siac;




-- INIZIO task-7.sql



\echo task-7.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


drop function if exists siac.fnc_siac_disponibilitavariare_cassa(id_in integer);
CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitavariare_cassa(id_in integer)
  RETURNS numeric as
  $body$
DECLARE


CAP_UG_TIPO constant varchar:='CAP-UG';
CAP_UP_TIPO constant varchar:='CAP-UP';

CAP_EG_TIPO constant varchar:='CAP-EG';
CAP_EP_TIPO constant varchar:='CAP-EP';

FASE_OP_BIL_PREV constant VARCHAR:='P';
FASE_OP_BIL_PROV constant VARCHAR:='E';

annoBilancio  varchar:=null;
tipoCapitolo  varchar:=null;
tipoCapitoloEq  varchar:=null;
faseOpCode varchar:=null;
dispVariareCassa   numeric:=0;
totOrdinativi   numeric:=0;
stanzEffettivoRec record;
elemId INTEGER:=0;
bilancioId integer:=0;

elemEqId integer:=0; -- siac-task-7 15.06.2023 Sofia

strMessaggio varchar(1500):=null;
BEGIN


	strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||'.';

	strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
    			  '.Lettura anno di bilancio e tipo elemento bilancio.';
	select per.anno, tipo.elem_tipo_code,bil.bil_id into strict annoBilancio, tipoCapitolo, bilancioId
	from siac_t_bil_elem bilElem,siac_d_bil_elem_tipo tipo,
         siac_t_bil bil, siac_t_periodo per
	where bilElem.elem_id=id_in
    and   bilElem.data_cancellazione is null and bilElem.validita_fine is null
    and   tipo.elem_tipo_id=bilElem.elem_tipo_id
    and   bil.bil_id=bilElem.bil_id
    and   per.periodo_id=bil.periodo_id;

    if NOT FOUND THEN
      RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
    end if;

    strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
      	          'Tipo elemento di bilancio='||tipoCapitolo||
    			  '.Lettura fase bilancio anno='||annoBilancio||'.';

    select  faseOp.fase_operativa_code into  faseOpCode
    from siac_r_bil_fase_operativa bilFase, siac_d_fase_operativa faseOp
    where bilFase.bil_id =bilancioId
     and bilfase.data_cancellazione is null
     and bilFase.validita_fine is null
     and faseOp.fase_operativa_id=bilFase.fase_operativa_id
     and faseOp.data_cancellazione is null
    order by bilFase.bil_fase_operativa_id desc;

    if NOT FOUND THEN
      RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
    end if;

  -- 29.06.015 Calcolabile anche in previsione su capitolo di previsione, restituisce lo stanziamento effettivo di cassa del capitolo di previsione

  --  if faseOpCode=FASE_OP_BIL_PREV then
  --  	RAISE EXCEPTION '% Fase non ammessa per il calcolo richiesto.',strMessaggio;
  --  end if;

    elemId:=id_in;

    if faseOpCode != FASE_OP_BIL_PREV then
    	if tipoCapitolo=CAP_UP_TIPO then
           tipoCapitoloEq=CAP_UG_TIPO;
        elsif tipoCapitolo=CAP_EP_TIPO then
           tipoCapitoloEq=CAP_EG_TIPO;
        end if;
        if tipoCapitoloEq is not null then
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
                          'Fase di bilancio='||faseOpCode||
    					  '.Lettura capitolo equivalente tipo='||tipoCapitoloEq||
                          ' anno='||annoBilancio||'.';
			--select bilElemGest.elem_id into  elemId siac-task-7 15.06.2023 Sofia
            --siac-task-7 15.06.2023 Sofia                        
            select bilElemGest.elem_id into  elemEqId			
   			from siac_t_bil_elem bilElemPrev, siac_d_bil_elem_tipo tipoGest,
       			 siac_t_bil_elem bilElemGest
		    where bilElemPrev.elem_id=id_in and
    	          bilElemGest.elem_code=bilElemPrev.elem_code and
        	      bilElemGest.elem_code2=bilElemPrev.elem_code2 and
            	  bilElemGest.elem_code3=bilElemPrev.elem_code3 and
	              bilElemGest.ente_proprietario_id=bilElemPrev.ente_proprietario_id and
    	          bilElemGest.bil_id=bilElemPrev.bil_id and
        	      bilElemGest.data_cancellazione is null and bilElemGest.validita_fine is null and
            	  tipoGest.elem_tipo_id=bilElemGest.elem_tipo_id and
              	  tipoGest.elem_tipo_code=tipoCapitoloEq;
             if NOT FOUND THEN
		     	elemId:=0;
		     end if;
       end if;
    end if;

    if elemId!=0 then
     case
--    	when faseOpCode = FASE_OP_BIL_PREV and tipoCapitolo in (CAP_UP_TIPO)  then -- siac-task-7 15.06.2023 Sofia
        -- siac-task-7 15.06.2023 Sofia
--    	when faseOpCode in (FASE_OP_BIL_PREV) or tipoCapitolo in (CAP_UP_TIPO)  then    	
    	when  tipoCapitolo=CAP_UP_TIPO  then  
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
			              'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';

            select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_up_anno (elemId,annoBilancio);

			if stanzEffettivoRec.stanzEffettivoCassa is not null then
	            dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa;
			end if;

           -- siac-task-7 15.06.2023 Sofia - inizio 
           if  faseOpCode !=FASE_OP_BIL_PREV and elemEqId!=0 and elemEqId is not null then 
             strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    	    	          'elemEqId='||elemEqId||
    					  '.Calcolo totale ordinativi per anno='||annoBilancio||'.';

             select * into totOrdinativi
             from fnc_siac_totalepagatoug(elemEqId);

            if totOrdinativi is null then
              totOrdinativi:=0;
            end if;

            dispVariareCassa:= dispVariareCassa-totOrdinativi;
           end if;
          -- siac-task-7 15.06.2023 Sofia - fine
          
--    	when faseOpCode = FASE_OP_BIL_PREV and tipoCapitolo in (CAP_EP_TIPO)  then -- siac-task-7 15.06.2023 Sofia
  	    -- siac-task-7 15.06.2023 Sofia
--    	when faseOpCode in (FASE_OP_BIL_PREV) or tipoCapitolo in (CAP_EP_TIPO)  then    	
    	when tipoCapitolo=CAP_EP_TIPO  then
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
                           'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';

            select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_ep_anno (elemId,annoBilancio);


            if stanzEffettivoRec.stanzEffettivoCassa is not null then
	            dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa;
			end if;
            -- siac-task-7 15.06.2023 Sofia - inizio 
            if  faseOpCode !=FASE_OP_BIL_PREV and elemEqId!=0 and elemEqId is not null then 
             strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    	    	          'elemEqId='||elemEqId||
    					  '.Calcolo totale ordinativi per anno='||annoBilancio||'.';

             select * into totOrdinativi
             from fnc_siac_totaleincassatoeg(elemEqId);

             if totOrdinativi is null then
              totOrdinativi:=0;
             end if;

            dispVariareCassa:= dispVariareCassa-totOrdinativi;
           end if;
           -- siac-task-7 15.06.2023 Sofia - fine


    	-- when faseOpCode != FASE_OP_BIL_PREV and tipoCapitolo in (CAP_UP_TIPO, CAP_UG_TIPO)  then siac-task-7 15.06.2023 Sofia
        -- siac-task-7 15.06.2023 Sofia
    	when faseOpCode != FASE_OP_BIL_PREV and tipoCapitolo in (CAP_UG_TIPO)  then    	
			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
                           'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';

            select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_ug_anno (elemId,annoBilancio);

			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo totale ordinativi per anno='||annoBilancio||'.';

            select * into totOrdinativi
            from fnc_siac_totalepagatoug(elemId);

            if totOrdinativi is null then
              totOrdinativi:=0;
            end if;

            if stanzEffettivoRec.stanzEffettivoCassa is not null then
	             dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa - totOrdinativi;
            else dispVariareCassa:= -totOrdinativi;
            end if;
	--    when faseOpCode != FASE_OP_BIL_PREV and tipoCapitolo in (CAP_EP_TIPO, CAP_EG_TIPO)  then siac-task-7 15.06.2023 Sofia
       -- siac-task-7 15.06.2023 Sofia
    	when faseOpCode != FASE_OP_BIL_PREV  and tipoCapitolo in (CAP_EG_TIPO)  then    	

			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo stanziamento effettivo cassa per anno='||annoBilancio||'.';
		    select * into stanzEffettivoRec
			from fnc_siac_stanz_effettivo_eg_anno (elemId,annoBilancio);

			strMessaggio:='Calcolo disponibile variare cassa elem_id='||id_in||
						  'Fase di bilancio='||faseOpCode||
    	    	          'Tipo elemento di bilancio='||tipoCapitolo||
    					  '.Calcolo totale ordinativi per anno='||annoBilancio||'.';
            select * into totOrdinativi
            from fnc_siac_totaleincassatoeg(elemId);
			if totOrdinativi is null then
              totOrdinativi:=0;
            end if;

            if stanzEffettivoRec.stanzEffettivoCassa is not null then
	             dispVariareCassa:= stanzEffettivoRec.stanzEffettivoCassa - totOrdinativi;
            else dispVariareCassa:= -totOrdinativi;
            end if;
     else 
            dispVariareCassa:=0;
     end case;
    end if;

return dispVariareCassa;

exception
   when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        return 0;
    when too_many_rows then
    	RAISE EXCEPTION '% Diversi records presenti in archivio.',strMessaggio;
        return 0;
    when no_data_found then
		RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        return 0;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 1000);
        return 0;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

alter function  siac.fnc_siac_disponibilitavariare_cassa(integer)  owner to siac;




-- INIZIO task-86.sql



\echo task-86.sql


/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-TASK #86 - Paolo - INIZIO
/*per il parametro NUMERAZIONE_AUTOMATICA_CAPITOLO*/
insert into siac_t_parametro_config_ente (
	ente_proprietario_id,
	parametro_nome,
	parametro_valore,
	parametro_note,
	validita_inizio,
	login_operazione 
) select 
	e.ente_proprietario_id ,
	x.nome,
	null,
	x.note,
	now(),
	'admin'
 from siac_t_ente_proprietario e, 
(values 
	('capitolo.inserisci.abilitaNumerazioneAutomatica', 'Abilitazione numerazione automatica capitoli CMTO'),
	('capitolo.inserisci.limiteNumerazioneAutomatica', 'Limite numerazione automatica capitoli CMTO') 
) as x (nome, note) 
where not exists ( select 1 from siac_t_parametro_config_ente p where parametro_nome = x.nome and e.ente_proprietario_id = p.ente_proprietario_id)
and e.ente_code = 'CMTO'
and e.in_uso
;
  
--SIAC-TASK #86 - Paolo - FINE




