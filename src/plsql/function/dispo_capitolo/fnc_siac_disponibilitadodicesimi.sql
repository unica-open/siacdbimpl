/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION siac.fnc_siac_disponibilitadodicesimi 
(
  id_in integer,
  tipodisp_in varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_disponibilitadodicesimi (
  id_in integer,
  tipodisp_in varchar
)
RETURNS TABLE (
  codicerisultato integer,
  messaggiorisultato varchar,
  elemid integer,
  annocompetenza varchar,
  importodim numeric,
  importodpm numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG   constant varchar:='CAP-UG';
CL_PROGRAMMA  constant varchar:='PROGRAMMA';

TIPO_DISP_DIM constant varchar:='DIM';
TIPO_DISP_DPM constant varchar:='DPM';
TIPO_DISP_ALL constant varchar:='ENTRAMBI';

-- stati impegni
MOVGEST_TS_STATO_A  constant varchar:='A'; --- ANNULLATO

-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO

-- importoAttuale ordinativi
ORD_TS_DET_TIPO_A  constant varchar:='A';

-- stato capitolo annullato
AN_STATO_CAP   constant varchar:='AN';

-- stato capitolo annullato
STA_TIPOIMP_CAP   constant varchar:='STA';

-- stato variazioni per delta-meno
VAR_STATO_G    constant varchar:='G'; -- GIUNTA
VAR_STATO_C    constant varchar:='C'; -- CONSIGLIO
VAR_STATO_B    constant varchar:='B'; -- BOZZA
VAR_STATO_P    constant varchar:='P'; -- PRE-DEFINITIVA


MOVGEST_TS_T_TIPO     constant varchar:='T';
MOVGEST_TS_DET_A_TIPO constant varchar:='A';


bilancioId           integer:=0;
tipoCapitolo         varchar:=null;
strMessaggio         varchar(1500):=null;
strMessaggioFinale         varchar(1500):=null;
annoBilancio         varchar(10):=null;

enteProprietarioId   integer:=null;
idTipoCapitolo       integer:=null;
classifProgrammaCode VARCHAR(200):=null;
programmaClassId     integer:=null;
programmaClassTipoId integer:=null;

nMese                integer :=null;
dataelaborazione     timestamp;
dataFineValClass     timestamp;
periodoId            integer:=null;
elemStatoANId        integer:=null;
elemDetTipoStaId     integer:=null;
elemVarDetTipoStaId  integer:=null;
movGestTsTipoTId     integer:=null;
movGestTsStatoAId    integer:=null;
movGestTsDetATipoId  integer:=null;
ordStatoAId          integer:=null;
ordTsDetTipoAId      integer:=null;

stanziamentoTot      numeric:=null;
deltaMenoVarTot      numeric:=null;
importoIAP           numeric:=null;
importoImpCompetenza numeric:=null;
importoPagatoTot     numeric:=null;
LIC                  numeric:=0;
IAP                  numeric:=0;
LIM                  numeric:=0;

-- 10.08.2020 Sofia Jira SIAC-6865
importo_agg_IAP      numeric:=0;

begin
    codicerisultato     :=0;
    messaggiorisultato  :=null;
    elemId              :=null;
    annocompetenza      :=null;
    importodim          :=null;
    importodpm          :=null;

    dataelaborazione    := now()::timestamp;


    strMessaggioFinale:='Calcolo disponibilita'' dodicesimi.';

	strMessaggio:='Controllo parametri tipo elaborazione='||tipoDisp_in||'.';
    if tipoDisp_in is null then
      raise exception ' Valore non ammesso.';
    end if;
    if tipoDisp_in not in (TIPO_DISP_DIM,TIPO_DISP_DPM,TIPO_DISP_ALL) then
   	  raise exception ' Valore non ammesso.';
    end if;

    strMessaggio:='Controllo parametri ricavati da elem_id.';
    if id_in  is null or id_in=0 then
    	raise exception ' Valore non ammesso.';
    end if;

    -- Leggo annoBilancio, bil_id e tipo capitolo
    select cap.bil_id, per.anno, tipcap.elem_tipo_code,
           cap.elem_tipo_id, cap.ente_proprietario_id,per.periodo_id
      into bilancioId, annoBilancio, tipoCapitolo, idTipoCapitolo, enteProprietarioId, periodoId
      from siac_t_bil_elem cap, siac_t_bil bila, siac_d_bil_elem_tipo tipcap, siac_t_periodo per
    where cap.elem_id=id_in
    and   bila.bil_id=cap.bil_id
    and   tipcap.elem_tipo_id=cap.elem_tipo_id
    and   per.periodo_id=bila.periodo_id
    and   cap.data_cancellazione is null
    and   cap.validita_fine is null;

    if tipoCapitolo is null then
	    RAISE  EXCEPTION ' Errore in lettura dati capitolo.';
    end if;

    -- controllo che id_in sia un capitolo di tipo CAP-UG
    if tipoCapitolo <> TIPO_CAP_UG then
        RAISE  EXCEPTION ' Capitolo non del tipo CAP-UG.';
    end if;

    strMessaggio:='Lettura identificativo capitolo stato='||AN_STATO_CAP||'.';
	select stato.elem_stato_id into elemStatoANId
    from siac_d_bil_elem_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.elem_stato_code=AN_STATO_CAP;
    if elemStatoANId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;

    strMessaggio:='Lettura identificativo capitolo tipo importo='||STA_TIPOIMP_CAP||'.';
	select tipo.elem_det_tipo_id into elemDetTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_TIPOIMP_CAP;
    if elemDetTipoStaId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;

   strMessaggio:='Lettura identificativo dettaglio var capitolo tipo importo='||STA_TIPOIMP_CAP||'.';
   select bilElemDetVarTipo.elem_det_tipo_id into  elemVarDetTipoStaId
   from siac_d_bil_elem_det_tipo bilElemDetVarTipo
   where bilElemDetVarTipo.ente_proprietario_id=enteProprietarioId
   and   bilElemDetVarTipo.elem_det_tipo_code=STA_TIPOIMP_CAP;
   if elemVarDetTipoStaId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo movgest_ts_tipo='||MOVGEST_TS_T_TIPO||'.';
   select tstipo.movgest_ts_tipo_id into movGestTsTipoTId
   from siac_d_movgest_ts_tipo tstipo
   where tstipo.ente_proprietario_id=enteProprietarioId
   and   tstipo.movgest_ts_tipo_code=MOVGEST_TS_T_TIPO;
   if movGestTsTipoTId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo movgest_ts_stato='||MOVGEST_TS_STATO_A||'.';
   select movstato.movgest_stato_id into movGestTsStatoAId
   from siac_d_movgest_stato movstato
   where movstato.ente_proprietario_id=enteProprietarioId
   and   movstato.movgest_stato_code=MOVGEST_TS_STATO_A;
   if movGestTsStatoAId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo movgest_ts_det_tipo='||MOVGEST_TS_DET_A_TIPO||'.';
   select dettipo.movgest_ts_det_tipo_id into movGestTsDetATipoId
   from siac_d_movgest_ts_det_tipo dettipo
   where dettipo.ente_proprietario_id=enteProprietarioId
   and   dettipo.movgest_ts_det_tipo_code=MOVGEST_TS_DET_A_TIPO;
   if movGestTsDetATipoId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura identificativo ord_stato_code='||STATO_ORD_A||'.';
   select ordstato.ord_stato_id into ordStatoAId
   from siac_d_ordinativo_stato ordstato
   where ordstato.ente_proprietario_id=enteProprietarioId
   and   ordstato.ord_stato_code=STATO_ORD_A;

   select tipo.ord_ts_det_tipo_id into ordTsDetTipoAId
   from siac_d_ordinativo_ts_det_tipo tipo
   where tipo.ente_proprietario_id=enteProprietarioId
   and   tipo.ord_ts_det_tipo_code=ORD_TS_DET_TIPO_A;


   dataFineValClass    := (annoBilancio||'-12-31')::timestamp;

   strMessaggio:='Lettura dati classificatore='||CL_PROGRAMMA||'.';
   -- ricavare il programma collegato al id_in ( siac_t_class [PROGRAMMA])
   select k.classif_code, k.classif_id, k.classif_tipo_id
      into classifProgrammaCode, programmaClassId, programmaClassTipoId
   from siac_t_class k, siac_r_bil_elem_class l, siac_d_class_tipo r
   where l.elem_id = id_in
   and   k.classif_id = l.classif_id
   and   r.classif_tipo_id=k.classif_tipo_id
   and   r.classif_tipo_code=CL_PROGRAMMA
   and   r.ente_proprietario_id=l.ente_proprietario_id
   and   l.data_cancellazione is null
   and   l.validita_fine is null
   and   k.data_cancellazione is null
   and   date_trunc('DAY',dataElaborazione)>=date_trunc('DAY',k.validita_inizio)
   and   date_trunc('DAY',dataFineValClass)<=date_trunc('DAY',coalesce(k.validita_fine,dataFineValClass));

   if programmaClassId is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura stanziamento totale competenza.';
   -- calcolo stanziamento competenza per programma
   /*
   select sum(det.elem_det_importo) into stanziamentoTot
   from siac_t_bil_elem e,siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
	    siac_t_bil_elem_det det
   where e.bil_id=bilancioId
    and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rstato.elem_id=e.elem_id
	and   rstato.elem_stato_id!=elemStatoANId
	and   det.elem_id=e.elem_id
	and   det.elem_det_tipo_id=elemDetTipoStaId
	and   det.periodo_id=periodoId
	and   rstato.data_cancellazione is null
	and   rstato.validita_fine is null
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   det.data_cancellazione is null
	and   det.validita_fine is null;
 */

/* 11/01/2018 A.V. introdotta condizione su flagImpegnabile per escludere i non
impegnabili dal calcolo */

   select sum(det.elem_det_importo) into stanziamentoTot
   from siac_t_bil_elem e,siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
	    siac_t_bil_elem_det det
        , siac_t_attr att, siac_r_bil_elem_attr attr
   where e.bil_id=bilancioId
    and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rstato.elem_id=e.elem_id
	and   rstato.elem_stato_id!=elemStatoANId
	and   det.elem_id=e.elem_id
	and   det.elem_det_tipo_id=elemDetTipoStaId
	and   det.periodo_id=periodoId
	and   rstato.data_cancellazione is null
	and   rstato.validita_fine is null
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   det.data_cancellazione is null
	and   det.validita_fine is null
    and   attr.elem_id=e.elem_id
    and   attr.attr_id=att.attr_id
    and   att.attr_code='FlagImpegnabile'
    and   attr."boolean"<>'N'
    and   attr.data_cancellazione is null
    and   attr.validita_fine is null;

   if stanziamentoTot is null then
     RAISE  EXCEPTION ' Errore in lettura.';
   end if;

   strMessaggio:='Lettura delta-meno totale competenza.';
   select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0) into deltaMenoVarTot
   from  siac_t_bil_elem e,siac_r_bil_elem_stato rstato,  siac_r_bil_elem_class rc,
         siac_t_variazione var, siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
         siac_t_bil_elem_det_var bilElemDetVar
   where e.bil_id=bilancioId
	and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rstato.elem_id=e.elem_id
	and   rstato.elem_stato_id!=elemStatoANId
	and   rstato.data_cancellazione is null
	and   rstato.validita_fine is null
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   bilElemDetVar.elem_id=e.elem_id
	and   bilElemDetVar.periodo_id=periodoId
	and   bilElemDetVar.elem_det_importo<0
	and   bilElemDetVar.elem_det_tipo_id=elemVarDetTipoStaId
	and   bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
	and   tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
	and   tipoStatoVar.variazione_stato_tipo_code in (VAR_STATO_G,VAR_STATO_C,VAR_STATO_P,VAR_STATO_B)
	and   var.variazione_id=statoVar.variazione_id
	and   var.bil_id=bilancioId
  	and   bilElemDetVar.data_cancellazione is null
	and   bilElemDetVar.validita_fine is null
    and   statoVar.data_cancellazione is null
    and   statoVar.validita_fine is null
    and   var.data_cancellazione is null
    and  var.validita_fine is null;

   if deltaMenoVarTot is null then
     RAISE  EXCEPTION ' Errore in lettura delta-meno.';
   end if;

   strMessaggio:='Lettura importo IAP.';
   select coalesce(sum(tsdet.movgest_ts_det_importo),0) into importoIAP
   from siac_t_bil_elem e, siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
        siac_r_movgest_bil_elem rmov, siac_t_movgest mov, siac_t_movgest_ts ts,
    	siac_r_movgest_ts_stato rmovstato,
	    siac_r_movgest_ts_atto_amm rmovatto, siac_t_atto_amm attoamm,
	    siac_t_movgest_ts_det tsdet
   where e.bil_id=bilancioId
	and  e.elem_tipo_id=idTipoCapitolo
	and  rc.elem_id=e.elem_id
	and  rc.classif_id=programmaClassId
	and  rstato.elem_id=e.elem_id
	and  rstato.elem_stato_id!=elemStatoANId
	and  rmov.elem_id=e.elem_id
	and  mov.movgest_id=rmov.movgest_id
	and  mov.movgest_anno::integer=annoBilancio::integer
	and  ts.movgest_id=mov.movgest_id
	and  ts.movgest_ts_tipo_id=movGestTsTipoTId
	and  rmovstato.movgest_ts_id=ts.movgest_ts_id
	and  rmovstato.movgest_stato_id!=movGestTsStatoAId
	and  rmovatto.movgest_ts_id=ts.movgest_ts_id
	and  attoamm.attoamm_id=rmovatto.attoamm_id
	and  attoamm.attoamm_anno::integer<annoBilancio::integer
	and  tsdet.movgest_ts_id=ts.movgest_ts_id
	and  tsdet.movgest_ts_det_tipo_id=movGestTsDetATipoId
	and  rstato.data_cancellazione is null
	and  rstato.validita_fine is null
	and  e.data_cancellazione is null
	and  e.validita_fine is null
	and  rc.data_cancellazione is null
	and  rc.validita_fine is null
	and  mov.data_cancellazione is null
	and  mov.validita_fine is null
	and  ts.data_cancellazione is null
	and  ts.validita_fine is null
	and  rmov.data_cancellazione is null
	and  rmov.validita_fine is null
	and  rmovstato.data_cancellazione is null
	and  rmovstato.validita_fine is null
	and  rmovatto.data_cancellazione is null
	and  rmovatto.validita_fine is null
	and  attoamm.data_cancellazione is null
	and  attoamm.validita_fine is null
	and  tsdet.data_cancellazione is null
	and  tsdet.validita_fine is null;

    if importoIAP is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;
    raise notice 'imporoIAP =%',importoIAP;

  -- 07.08.2020 Sofia SIAC-6865 - inizio
  -- calcolo di impegni validi in annoBilancio
  -- collegati per aggiudicazione ad impegni validi in annoBilancio
  -- di competenza con annoProvvidemento<annoBilancio
  -- questa cifra da sommare a importoIAP

  strMessaggio:='Lettura importo IAP - quota di aggiudicazioni anno prec.';
  select coalesce(sum(tsdet_agg.movgest_ts_det_importo),0) into importo_agg_IAP
  from siac_t_bil_elem e, siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
       siac_r_movgest_bil_elem rmov, siac_t_movgest mov, siac_t_movgest_ts ts,
       siac_r_movgest_ts_stato rmovstato,
	   siac_r_movgest_ts_atto_amm rmovatto, siac_t_atto_amm attoamm,
       siac_r_movgest_aggiudicazione ragg, siac_t_movgest mov_agg,
       siac_t_movgest_ts ts_agg,siac_r_movgest_ts_stato rs_agg,
	   siac_t_movgest_ts_det tsdet_agg
  where e.bil_id=bilancioId
  and  e.elem_tipo_id=idTipoCapitolo
  and  rc.elem_id=e.elem_id
  and  rc.classif_id=programmaClassId
  and  rstato.elem_id=e.elem_id
  and  rstato.elem_stato_id!=elemStatoANId
  and  rmov.elem_id=e.elem_id
  and  mov.movgest_id=rmov.movgest_id
  and  mov.movgest_anno::integer=annoBilancio::integer
  and  ts.movgest_id=mov.movgest_id
  and  ts.movgest_ts_tipo_id=movGestTsTipoTId
  and  rmovstato.movgest_ts_id=ts.movgest_ts_id
  and  rmovstato.movgest_stato_id!=movGestTsStatoAId
  and  rmovatto.movgest_ts_id=ts.movgest_ts_id
  and  attoamm.attoamm_id=rmovatto.attoamm_id
  and  attoamm.attoamm_anno::integer<annoBilancio::integer
  and  ragg.movgest_id_da=mov.movgest_id
  and  mov_agg.movgest_id=ragg.movgest_id_a
  and  mov_agg.bil_id=mov.bil_id
  and  ts_agg.movgest_id=mov_agg.movgest_id
  and  ts_agg.movgest_ts_tipo_id=movGestTsTipoTId
  and  rs_agg.movgest_ts_id=ts_agg.movgest_ts_id
  and  rs_agg.movgest_stato_id!=movGestTsStatoAId
  and  tsdet_agg.movgest_ts_id=ts_agg.movgest_ts_id
  and  tsdet_agg.movgest_ts_det_tipo_id=movGestTsDetATipoId
  and  rstato.data_cancellazione is null
  and  rstato.validita_fine is null
  and  e.data_cancellazione is null
  and  e.validita_fine is null
  and  rc.data_cancellazione is null
  and  rc.validita_fine is null
  and  mov.data_cancellazione is null
  and  mov.validita_fine is null
  and  ts.data_cancellazione is null
  and  ts.validita_fine is null
  and  rmov.data_cancellazione is null
  and  rmov.validita_fine is null
  and  rmovstato.data_cancellazione is null
  and  rmovstato.validita_fine is null
  and  rmovatto.data_cancellazione is null
  and  rmovatto.validita_fine is null
  and  attoamm.data_cancellazione is null
  and  attoamm.validita_fine is null
  and  ragg.data_cancellazione is null
  and  ragg.validita_fine is null
  and  mov_agg.data_cancellazione is null
  and  mov_agg.validita_fine is null
  and  ts_agg.data_cancellazione is null
  and  ts_agg.validita_fine is null
  and  rs_agg.data_cancellazione is null
  and  rs_agg.validita_fine is null
  and  tsdet_agg.data_cancellazione is null
  and  tsdet_agg.validita_fine is null;
   raise notice 'importo_agg_IAP =%',importo_agg_IAP;
  if COALESCE(importo_agg_IAP,0)!=0 then importoIAP:=importoIAP+importo_agg_IAP; end if;
   raise notice 'imporoIAP =%',importoIAP;
  -- 07.08.2020 Sofia SIAC-6865 - fine

  -- per calcolo DIM o ENTRAMBI allora calcolo impegnato competenza
  if tipoDisp_in in ( TIPO_DISP_ALL,TIPO_DISP_DIM) then
   strMessaggio:='Lettura importo impegnato competenza.';
   select coalesce(sum(tsdet.movgest_ts_det_importo),0) into importoImpCompetenza
   from siac_t_bil_elem e, siac_r_bil_elem_stato rstato, siac_r_bil_elem_class rc,
        siac_r_movgest_bil_elem rmov, siac_t_movgest mov, siac_t_movgest_ts ts,
    	siac_r_movgest_ts_stato rmovstato,
	    siac_r_movgest_ts_atto_amm rmovatto, siac_t_atto_amm attoamm,
	    siac_t_movgest_ts_det tsdet
   where e.bil_id=bilancioId
	and  e.elem_tipo_id=idTipoCapitolo
	and  rc.elem_id=e.elem_id
	and  rc.classif_id=programmaClassId
	and  rstato.elem_id=e.elem_id
	and  rstato.elem_stato_id!=elemStatoANId
	and  rmov.elem_id=e.elem_id
	and  mov.movgest_id=rmov.movgest_id
	and  mov.movgest_anno::integer=annoBilancio::integer
	and  ts.movgest_id=mov.movgest_id
	and  ts.movgest_ts_tipo_id=movGestTsTipoTId
	and  rmovstato.movgest_ts_id=ts.movgest_ts_id
	and  rmovstato.movgest_stato_id!=movGestTsStatoAId
	and  rmovatto.movgest_ts_id=ts.movgest_ts_id
	and  attoamm.attoamm_id=rmovatto.attoamm_id
	and  attoamm.attoamm_anno::integer=annoBilancio::integer
	and  tsdet.movgest_ts_id=ts.movgest_ts_id
	and  tsdet.movgest_ts_det_tipo_id=movGestTsDetATipoId
	and  rstato.data_cancellazione is null
	and  rstato.validita_fine is null
	and  e.data_cancellazione is null
	and  e.validita_fine is null
	and  rc.data_cancellazione is null
	and  rc.validita_fine is null
	and  mov.data_cancellazione is null
	and  mov.validita_fine is null
	and  ts.data_cancellazione is null
	and  ts.validita_fine is null
	and  rmov.data_cancellazione is null
	and  rmov.validita_fine is null
	and  rmovstato.data_cancellazione is null
	and  rmovstato.validita_fine is null
	and  rmovatto.data_cancellazione is null
	and  rmovatto.validita_fine is null
	and  attoamm.data_cancellazione is null
	and  attoamm.validita_fine is null
	and  tsdet.data_cancellazione is null
	and  tsdet.validita_fine is null;

    if importoImpCompetenza is null then
	    RAISE  EXCEPTION ' Errore in lettura.';
    end if;

   end if;

   -- per calcolo DPM o ENTRAMBI allora calcolo pagato competenza
   if  tipoDisp_in in ( TIPO_DISP_ALL,TIPO_DISP_DPM) then
    strMessaggio:='Lettura importo pagato competenza.';
	select coalesce(sum(tsdet.ord_ts_det_importo),0) into importoPagatoTot
	from siac_t_bil_elem e,  siac_r_bil_elem_class rc,siac_r_movgest_bil_elem rmov,
         siac_t_movgest mov, siac_t_movgest_ts ts,
    	 siac_r_movgest_ts_atto_amm rmovatto, siac_t_atto_amm attoamm,
	     siac_r_liquidazione_movgest rliq,
    	 siac_r_liquidazione_ord rord, siac_t_ordinativo_ts ordts, siac_t_ordinativo ord,
	     siac_r_ordinativo_stato rordstato,
    	 siac_t_ordinativo_ts_det tsdet
	where e.bil_id=bilancioId
	and   e.elem_tipo_id=idTipoCapitolo
	and   rc.elem_id=e.elem_id
	and   rc.classif_id=programmaClassId
	and   rmov.elem_id=e.elem_id
	and   mov.movgest_id=rmov.movgest_id
	and   ts.movgest_id=mov.movgest_id
	and   mov.movgest_anno::integer=annoBilancio::integer
	and   rmovatto.movgest_ts_id=ts.movgest_ts_id
	and   attoamm.attoamm_id=rmovatto.attoamm_id
	and   attoamm.attoamm_anno::integer=annoBilancio::integer
	and   rliq.movgest_ts_id=ts.movgest_ts_id
	and   rord.liq_id=rliq.liq_id
	and   ordts.ord_ts_id=rord.sord_id
	and   ord.ord_id=ordts.ord_id
	and   rordstato.ord_id=ord.ord_id
	and   rordstato.ord_stato_id!=ordStatoAId
	and   tsdet.ord_ts_id=ordts.ord_ts_id
	and   tsdet.ord_ts_det_tipo_id=ordTsDetTipoAId
	and   e.data_cancellazione is null
	and   e.validita_fine is null
	and   rc.data_cancellazione is null
	and   rc.validita_fine is null
	and   mov.data_cancellazione is null
	and   mov.validita_fine is null
	and   ts.data_cancellazione is null
	and   ts.validita_fine is null
	and   rmov.data_cancellazione is null
	and   rmov.validita_fine is null
	and   rord.data_cancellazione is null
	and   rord.validita_fine is null
	and   rliq.data_cancellazione is null
	and   rliq.validita_fine is null
	and   ordts.data_cancellazione is null
	and   ordts.validita_fine is null
	and   ord.data_cancellazione is null
	and   ord.validita_fine is null
	and   rordstato.data_cancellazione is null
	and   rordstato.validita_fine is null
	and   tsdet.data_cancellazione is null
	and   tsdet.validita_fine is null
	and   rmovatto.data_cancellazione is null
	and   rmovatto.validita_fine is null
	and   attoamm.data_cancellazione is null
	and   attoamm.validita_fine is null;

    if importoPagatoTot is null then
    	RAISE  EXCEPTION ' Errore in lettura.';
    end if;
   end if;


   LIC:=stanziamentoTot-deltaMenoVarTot;
   IAP:=importoIAP;
   -- ricava il mese dal timestamp attuale
   nMese:=date_part('month',dataelaborazione);
   LIM:=round((LIC-IAP)/12,2);

   raise notice 'LIC=%',LIC;
   raise notice 'IAP=%',IAP;
   raise notice 'nMese=%',nMese;
   raise notice 'LIM=%',LIM;


   if tipoDisp_in = TIPO_DISP_ALL then
       -- calcolo DIM + calcolo DPM
       importodim := (LIM*nMEse) - importoImpCompetenza;
       importodpm := (LIM*nMEse) - importoPagatoTot;
   elsif tipoDisp_in = TIPO_DISP_DIM then
        -- calcolo DIM
        importodim := (LIM*nMEse) - importoImpCompetenza;
   else
           -- calcolo DPM
       importodpm := (LIM*nMEse) - importoPagatoTot;
   end if;

   raise notice 'importodim=%',importodim;
   raise notice 'importodpm=%',importodpm;

   -- setta gli altri campi di ritorno
   codicerisultato    := 0;
   messaggiorisultato := strMessaggioFinale||'Risultato OK.';
   elemid             := id_in;
   annocompetenza     := annoBilancio;

   return next;

exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        RAISE notice '%',messaggioRisultato;
        codiceRisultato:=-1;
        return;
    when no_data_found then
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Nessun elemento trovato.' ;
        RAISE notice '%',messaggioRisultato;
        codiceRisultato:=-1;
        return;
    when others  THEN
        messaggioRisultato:=strMessaggioFinale||strMessaggio||' Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1050) ;
        RAISE notice '%',messaggioRisultato;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;

ALTER FUNCTION siac.fnc_siac_disponibilitadodicesimi (integer,varchar) OWNER TO siac;