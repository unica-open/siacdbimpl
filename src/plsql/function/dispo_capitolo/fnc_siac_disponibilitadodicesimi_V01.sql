/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- domande
-- 1. per il calcolo dello stanziamento effettivo possiamo usare il calcolo in uso che tiene conto dello stanziamento di previsione ?
-- 2. per il calcolo dello IAP dobbiamo considerare gli impegni sull'annoBilancio -1 ??
-- 3. per il calcolo di IAP e TOT_IMP dobbiamo considerare anche gli impegni provvisori ??
-- 4. il calcolo va fatto solo per lo stanziamento di competenza =annoBilancio o anche per i due anni successivi ..
-- risposte
-- 1. Lo stanziamento effettivo per programma NON deve tenere conto dei buffi
--    ragionamenti sui minimi tipici del provvisorio ma usare lo stanziamento e basta,
--    dei minimi ce ne preoccupiamo solo a livello di singolo capitolo
-- 2. Per lo IAP si lavora nell'anno quindi usate gli impegni dell'anno
-- 3. Domanda interessante a cui non avevo pensato ma io direi, per principio di
--    prudenza, di conteggiare anche i P
-- 4. solo sulla competenza

CREATE OR REPLACE FUNCTION fnc_siac_disponibilitadodicesimi (
  id_in                  integer,
  tipoDisp_in            VARCHAR -- DIM, DPM, ENTRAMBI
 /* out importodim         numeric,
  out importodpm         numeric,
  out codicerisultato    integer,
  out messaggiorisultato varchar  */
)
--RETURNS record AS
RETURNS TABLE (
  codicerisultato    integer,
  messaggiorisultato varchar,
  elemid             integer,
  annocompetenza     varchar,
  importodim         numeric,
  importodpm         numeric
) AS
$body$
DECLARE

-- constant
TIPO_CAP_UG   constant varchar:='CAP-UG';
TIPO_ORD      constant varchar:='P';     -- PAGAMENTO
TIPO_PERIODO  constant varchar:='SY';    -- ANNO SOLARE
NVL_STR       constant varchar:='';
STA_IMP       constant varchar:='STA';
CL_PROGRAMMA  constant varchar:='PROGRAMMA';
TIPO_DISP_DIM constant varchar:='DIM';
TIPO_DISP_DPM constant varchar:='DPM';
TIPO_DISP_ALL constant varchar:='ENTRAMBI';

-- stati variazioni di importo
STATO_VAR_G    constant varchar:='G'; -- GIUNTA
STATO_VAR_C    constant varchar:='C'; -- CONSIGLIO
STATO_VAR_B    constant varchar:='B'; -- BOZZA
STATO_VAR_D    constant varchar:='D'; -- DEFINITIVA
STATO_VAR_P    constant varchar:='P'; -- PRE-DEFINITIVA

-- stati impegni
STATO_IMP_D    constant varchar:='D'; -- DEFINITIVO
STATO_IMP_N    constant varchar:='N'; -- DEFINITIVO NON LIQUIDABILE
STATO_IMP_P    constant varchar:='P'; -- PROVVISORIO

-- stati ordinativi
STATO_ORD_A    constant varchar:='A'; -- ANNULLATO

bilancioId           integer:=0;
tipoCapitolo         varchar:=NVL_STR;
strMessaggio         varchar(1500):=NVL_STR;
annoBilancio         varchar(10):=NVL_STR;
stanziamento         numeric:=0;
deltaMenoGest        numeric:=0;
capIap               numeric:=0;
capImpegn            numeric:=0;
capPagam             numeric:=0;
LIC                  numeric:=0;
IAP                  numeric:=0;
LIM                  numeric:=0;
TOT_IMP              numeric:=0;
TOT_PAG              numeric:=0;
enteProprietarioId   integer:=0;
idTipoCapitolo       integer:=0;
classifProgrammaCode VARCHAR(200):=NVL_STR;
programmaClassId     integer:=null;
programmaClassTipoId integer:=null;
nMese                integer :=0;
capitoli             record;
dataelaborazione     timestamp;
periodoCompId        integer:=0;

begin
    codicerisultato     :=0;
    messaggiorisultato  :=NVL_STR;
    elemId              :=null;
    annocompetenza      :=null;
    importodim          :=null;
    importodpm          :=null;
    dataelaborazione    := now()::timestamp;

    strMessaggio:='Calcolo disponibilità dodicesimi.Controllo parametri.';

    -- Leggo annoBilancio, bil_id e tipo capitolo
    select cap.bil_id, substring( bila.bil_code from 5 for 4 ), tipcap.elem_tipo_code,
           cap.elem_tipo_id, cap.ente_proprietario_id
      into bilancioId, annoBilancio, tipoCapitolo, idTipoCapitolo, enteProprietarioId
      from siac_t_bil_elem cap, siac_t_bil bila, siac_d_bil_elem_tipo tipcap
     where bila.ente_proprietario_id=cap.ente_proprietario_id
       and bila.bil_id=cap.bil_id
       and tipcap.ente_proprietario_id=cap.ente_proprietario_id
       and tipcap.elem_tipo_id=cap.elem_tipo_id
       and cap.elem_id=id_in
       and cap.data_cancellazione is null
       and cap.validita_fine is null;

    -- controllo che id_in sia un capitolo di tipo CAP-UG
    if tipoCapitolo <> TIPO_CAP_UG then
        RAISE  EXCEPTION '% Errore: capitolo non del tipo CAP-UG',strMessaggio;
    end if;

    -- ricavare il programma collegato al id_in ( siac_t_class [PROGRAMMA])
    select k.classif_code, k.classif_id, k.classif_tipo_id
      into classifProgrammaCode, programmaClassId, programmaClassTipoId
      from siac_t_class k, siac_r_bil_elem_class l
     where k.classif_id = l.classif_id
       and l.elem_id = id_in
       and k.classif_tipo_id in (select r.classif_tipo_id from siac_d_class_tipo r
                                  where r.ente_proprietario_id=enteProprietarioId
                                    and r.classif_tipo_code=CL_PROGRAMMA)
       and k.data_cancellazione is null
       and k.validita_fine is null;

    -- ricava il mese dal timestamp attuale
    nMese=date_part('month',dataelaborazione);

    select  per.periodo_id into strict periodoCompId
    from siac_t_periodo per, siac_d_periodo_tipo perTipo
    where per.anno=annoBilancio
    and   per.ente_proprietario_id=enteProprietarioId
    and   perTipo.periodo_tipo_id=per.periodo_tipo_id
    and   perTipo.periodo_tipo_code=TIPO_PERIODO;

    -- Loop su tutti i capitoli CAP-UG del bil_id del id_in passato e dello stesso PROGRAMMA
    for capitoli IN
        (select k.*
           from siac_t_bil_elem k, siac_t_class m, siac_r_bil_elem_class h
          where k.ente_proprietario_id=enteProprietarioId
            and k.bil_id = bilancioId
            and k.elem_tipo_id = idTipoCapitolo
            and m.ente_proprietario_id=k.ente_proprietario_id
            and m.classif_id = programmaClassId
            and m.classif_tipo_id = programmaClassTipoId
            and h.ente_proprietario_id=k.ente_proprietario_id
            and h.elem_id=k.elem_id
            and h.classif_id=m.classif_id
            and date_trunc('day',dataelaborazione)>=date_trunc('day',k.validita_inizio) and
                  (date_trunc('day',dataelaborazione)<date_trunc('day',k.validita_fine)
                          or k.validita_fine is null)
         ) loop

        -- calcolo dello stanziamento effettivo  LIC di competenza
        strMessaggio:='Lettura stanziamenti di gestione per elem_id='||capitoli.elem_id||' anno_comp_in='||bilancioId||'.';

        stanziamento  := 0;
        deltaMenoGest := 0;
        capIap        := 0;
        capImpegn     := 0;
        capPagam      := 0;

        select importiGest.elem_det_importo
          into strict stanziamento
          from siac_t_bil_elem_det importiGest, siac_d_bil_elem_det_tipo tipoImp
         where importiGest.elem_id=capitoli.elem_id
           AND importiGest.data_cancellazione is null
           and importiGest.validita_fine is null
           and tipoImp.elem_det_tipo_id=importiGest.elem_det_tipo_id
           and tipoImp.elem_det_tipo_code=STA_IMP
           and importiGest.periodo_id=periodoCompId;

        --- calcolo dei 'delta-gestione', variazioni agli importi del CAP-UG in stato
         --- diverso da BOZZA,DEFINTIVO,ANNULLATO
        strMessaggio:='Lettura variazioni delta-meno-gest per elem_id='||capitoli.elem_id||' anno_comp_in='||bilancioId||'.';

        select coalesce(sum(abs(bilElemDetVar.elem_det_importo)),0)
          into strict deltaMenoGest
          from siac_t_variazione var,
               siac_r_variazione_stato statoVar, siac_d_variazione_stato tipoStatoVar,
               siac_t_bil_elem_det_var bilElemDetVar, siac_d_bil_elem_det_tipo bilElemDetVarTipo
         where bilElemDetVar.elem_id=capitoli.elem_id
           and bilElemDetVar.data_cancellazione is null
           and bilElemDetVar.validita_fine is null
           and bilElemDetVar.periodo_id=periodoCompId
           and bilElemDetVar.elem_det_importo<0
             and bilElemDetVar.elem_det_tipo_id=bilElemDetVarTipo.elem_det_tipo_id
           and bilElemDetVarTipo.elem_det_tipo_code=STA_IMP
           and bilElemDetVar.variazione_stato_id=statoVar.variazione_stato_id
           and statoVar.data_cancellazione is null
           and statoVar.validita_fine is null
           and tipoStatoVar.variazione_stato_tipo_id=statoVar.variazione_stato_tipo_id
             and tipoStatoVar.variazione_stato_tipo_code in (STATO_VAR_G,STATO_VAR_C,STATO_VAR_P)
           and var.variazione_id=statoVar.variazione_id
           and var.data_cancellazione is null
           and var.validita_fine is null
           and var.bil_id=bilancioId;

        LIC := LIC + (stanziamento-deltaMenoGest);

        -- se calcolo DIM   , allora calcolo sia IAP che TOT_IMP
        if tipoDisp_in = TIPO_DISP_DIM or tipoDisp_in = TIPO_DISP_ALL then
            -- calcolare la somma di importo attuale degli impegni di competenza (D,N,P) IAP come segue
                --  siac_t_movgest.movgest_anno=annoBilancio
                --  siac_r_movgest_atto_amm
                -- con siac_t_atto_amm.attoam_anno<annoBilancio
            strMessaggio:='Calcolo IAP per elem_id='||capitoli.elem_id||' anno_comp_in='||bilancioId||'.';

            select coalesce(sum(abs(movgest_ts_det.movgest_ts_det_importo)),0)
              into strict capIap
              from siac_t_movgest movgest, siac_r_movgest_bil_elem rmovgestcap,
                   siac_t_movgest_ts movgest_ts, siac_r_movgest_ts_stato rmovgeststato,
                   siac_d_movgest_stato statoMovGest, siac_t_movgest_ts_det movgest_ts_det,
                   siac_r_movgest_ts_atto_amm rmovgestatto, siac_t_atto_amm atto
             where rmovgestcap.elem_id=capitoli.elem_id
               and rmovgestcap.movgest_id=movgest.movgest_id
               and movgest_ts.movgest_id=movgest.movgest_id
               and rmovgeststato.movgest_ts_id=movgest_ts.movgest_ts_id
               and rmovgeststato.movgest_stato_id=statoMovGest.movgest_stato_id
               and statoMovGest.movgest_stato_code in (STATO_IMP_D, STATO_IMP_N, STATO_IMP_P)
               and movgest_ts_det.movgest_ts_id=movgest_ts.movgest_ts_id
               and rmovgestatto.movgest_ts_id=movgest_ts.movgest_ts_id
               and atto.attoamm_id=rmovgestatto.attoamm_id
               and movgest.movgest_anno::integer=annoBilancio::integer --sofia
               and atto.attoamm_anno::integer < annoBilancio::integer; -- sofia

            IAP := IAP + capIap;

        end if;

        -- calcolare la somma di importo attuale di tutti gli impegni di competenza (D,N,P) TOT_IMP come segue
        -- siac_t_movgest.movgest_anno=annoBilancio
        strMessaggio:='Calcolo TOT_IMP per elem_id='||capitoli.elem_id||' anno_comp_in='||bilancioId||'.';

        /*select coalesce(sum(abs(movgest_ts_det.movgest_ts_det_importo)),0)
          into strict capImpegn
          from siac_t_movgest movgest, siac_r_movgest_bil_elem rmovgestcap,
               siac_t_movgest_ts movgest_ts, siac_r_movgest_ts_stato rmovgeststato,
               siac_d_movgest_stato statoMovGest, siac_t_movgest_ts_det movgest_ts_det
         where rmovgestcap.elem_id=capitoli.elem_id
           and rmovgestcap.movgest_id=movgest.movgest_id
           and movgest_ts.movgest_id=movgest.movgest_id
           and rmovgeststato.movgest_ts_id=movgest_ts.movgest_ts_id
           and rmovgeststato.movgest_stato_id=statoMovGest.movgest_stato_id
           and statoMovGest.movgest_stato_code in (STATO_IMP_D, STATO_IMP_N, STATO_IMP_P)
           and movgest_ts_det.movgest_ts_id=movgest_ts.movgest_ts_id; */

         -- sofia
		  select coalesce(sum(abs(movgest_ts_det.movgest_ts_det_importo)),0)
              into strict capImpegn
              from siac_t_movgest movgest, siac_r_movgest_bil_elem rmovgestcap,
                   siac_t_movgest_ts movgest_ts, siac_r_movgest_ts_stato rmovgeststato,
                   siac_d_movgest_stato statoMovGest, siac_t_movgest_ts_det movgest_ts_det,
                   siac_r_movgest_ts_atto_amm rmovgestatto, siac_t_atto_amm atto
             where rmovgestcap.elem_id=capitoli.elem_id
               and rmovgestcap.movgest_id=movgest.movgest_id
               and movgest_ts.movgest_id=movgest.movgest_id
               and rmovgeststato.movgest_ts_id=movgest_ts.movgest_ts_id
               and rmovgeststato.movgest_stato_id=statoMovGest.movgest_stato_id
               and statoMovGest.movgest_stato_code in (STATO_IMP_D, STATO_IMP_N, STATO_IMP_P)
               and movgest_ts_det.movgest_ts_id=movgest_ts.movgest_ts_id
               and rmovgestatto.movgest_ts_id=movgest_ts.movgest_ts_id
               and atto.attoamm_id=rmovgestatto.attoamm_id
               and movgest.movgest_anno::integer=annoBilancio::integer --sofia
               and atto.attoamm_anno::integer = annoBilancio::integer; -- sofia

        TOT_IMP := TOT_IMP + capImpegn;

        -- se calcolo DPM , allora calcolo TOT_PAG
        if tipoDisp_in = TIPO_DISP_DPM or tipoDisp_in = TIPO_DISP_ALL then
            -- calcolare la somma di importo attuale di tutti gli ordinativi di pagamento  (!=A) TOT_PAG
            strMessaggio:='Calcolo TOT_PAG per elem_id='||capitoli.elem_id||' anno_comp_in='||bilancioId||'.';

            select coalesce(sum(abs(ordin_ts_det.ord_ts_det_importo)),0)
              into strict capPagam
              from siac_t_ordinativo ordin, siac_r_ordinativo_bil_elem rordincap,
                   siac_t_ordinativo_ts ordin_ts, siac_r_ordinativo_stato rordinstato,
                   siac_d_ordinativo_stato statoOrdin, siac_t_ordinativo_ts_det ordin_ts_det,
                   siac_d_ordinativo_tipo ordTipo
             where rordincap.elem_id=capitoli.elem_id
               and rordincap.ord_id=ordin.ord_id
               and ordin_ts.ord_id=ordin.ord_id
               and rordinstato.ord_id=ordin.ord_id
               and rordinstato.ord_stato_id=statoOrdin.ord_stato_id
               and statoOrdin.ord_stato_code not in (STATO_ORD_A)
               and ordin_ts_det.ord_ts_id=ordin_ts.ord_ts_id
               and ordin.ord_tipo_id=ordTipo.ord_tipo_id
               and ordTipo.ord_tipo_code=TIPO_ORD;

              TOT_PAG := TOT_PAG + capPagam;

        end if;

    end loop;

    LIM:=(LIC-IAP)/12;

    if tipoDisp_in = TIPO_DISP_ALL then
       -- calcolo DIM + calcolo DPM
       importodim := (LIM*nMEse) - TOT_IMP;
       importodpm := (LIM*nMEse) - TOT_PAG;
    elsif tipoDisp_in = TIPO_DISP_DIM then
        -- calcolo DIM
        importodim := (LIM*nMEse) - TOT_IMP;
    else
           -- calcolo DPM
       importodpm := (LIM*nMEse) - TOT_PAG;
    end if;

    -- setta gli altri campi di ritorno
    codicerisultato    := 0;
    messaggiorisultato := 'Calcolo disponibilità dodicesimi OK';
    elemid             := id_in;
    annocompetenza     := annoBilancio;

    return next;

exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',substring(SQLERRM from 1 for 1500);
        messaggioRisultato:=strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;
    when no_data_found then
        RAISE EXCEPTION '% Non presente in archivio.',strMessaggio;
        messaggioRisultato:=strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        return;
    when others  THEN
         RAISE EXCEPTION '% Errore DB % %',strMessaggio,SQLSTATE,substring(SQLERRM from 1 for 50);
        messaggioRisultato:=strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 50) ;
        codiceRisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;