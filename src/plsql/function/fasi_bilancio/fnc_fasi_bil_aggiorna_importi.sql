/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 13.09.2016 Davide - aggiornamento delle tavole siac_t_cap_u_importi_anno_prec / siac_t_cap_e_importi_anno_prec
-- 13.09.2016 Davide - chiamata da fnc_fasi_bil_aggiorna_importi_bilprev.

CREATE OR REPLACE FUNCTION fnc_fasi_bil_aggiorna_importi (
  annobilancio integer,
  prevelemid integer,
  prevtipoid integer,
  prevelemcode varchar,
  prevelemcode2 varchar,
  prevelemcode3 varchar,
  gestelemid integer,
  gestbilid integer,
  enteproprietarioid integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

    strMessaggio         VARCHAR(1500):='';
    strMessaggioFinale   VARCHAR(1500):='';

    SY_PER_TIPO          CONSTANT varchar:='SY';

    BILANCIO_CODE        CONSTANT varchar:='BIL_'||annobilancio::varchar;
    BILANCIO_CODEP       CONSTANT varchar:='BIL_'||(annobilancio-1)::varchar;

    CAPITOLO_EP          CONSTANT varchar:='CAP-EP';
    CAPITOLO_UP          CONSTANT varchar:='CAP-UP';
    CAPITOLO_EG          CONSTANT varchar:='CAP-EG';
    CAPITOLO_UG          CONSTANT varchar:='CAP-UG';

    STA_DET_TIPO         CONSTANT varchar:='STA';
    SCA_DET_TIPO         CONSTANT varchar:='SCA';

    -- codifiche Capitoli Uscita
    CL_MISSIONE             CONSTANT varchar :='MISSIONE';
    CL_PROGRAMMA            CONSTANT varchar :='PROGRAMMA';
    CL_COFOG                CONSTANT varchar :='GRUPPO_COFOG';
    CL_MACROAGGREGATO       CONSTANT varchar :='MACROAGGREGATO';
    CL_TITOLO_SPESA         CONSTANT varchar :='TITOLO_SPESA';
	CL_TRANSAZIONE_UE_SPESA CONSTANT varchar:='TRANSAZIONE_UE_SPESA';
    AT_FUNZIONI_DEL         CONSTANT varchar:='FlagFunzioniDelegate';

    -- codifiche Capitoli Entrata
    CL_TIPOLOGIA         CONSTANT varchar :='TIPOLOGIA';
    CL_CATEGORIA         CONSTANT varchar :='CATEGORIA';
    CL_TITOLO_ENTRATA    CONSTANT varchar :='TITOLO_ENTRATA';

    esistecap            integer := 0;
    codResult            integer:=null;
    --dataInizioVal      timestamp:=null;
    IdPrevEntrate        numeric:= null;
    IdPrevSpese          numeric:= null;

    detTipoStaId         integer:=null;
    detTipoScaId         integer:=null;

    -- Id tipi capitolo
    IdCapitoloEP         integer :=0;
    IdCapitoloUP         integer :=0;
    IdCapitoloEG         integer :=0;
    IdCapitoloUG         integer :=0;

    -- Id classificatori
	macroAggrClassId     integer:=null;
	macroAggrTipoId      integer:=null;
    missioneTipoId       integer:=null;
    programmaClassId     integer:=null;
    programmaTipoId      integer:=null;
    categoriaClassId     integer:=null;
    categoriaTipoId      integer:=null;
	titoloSpesaId        integer:=null;
	titoloEntrataId      integer:=null;
    transazioneUeSpesaId INTEGER:=null;
    funzdelegateId       INTEGER:=null;
    cofogTipoId          integer:=null;
    tipologiaClassId     integer:=null;
    tipologiaId          integer:=null;

    -- Codifiche Capitoli Uscita
    classifMissioneCode  VARCHAR(200):='';
    classifProgrammaCode VARCHAR(200):='';
    classifCofogCode     VARCHAR(200):='';
    classifTitSpesaCode  VARCHAR(200):='';
    classifMacroAggrCode VARCHAR(200):='';
    AttrFunzDelCode      VARCHAR(1):='';
    classifTrasfUECode   VARCHAR(1):='';

    -- Codifiche Capitoli Entrata
    classifTitEntCode    VARCHAR(200):='';
    classifTipologiaCode VARCHAR(200):='';
    classifCategoriaCode VARCHAR(200):='';

    capCategoriaCode     VARCHAR(200):=null;

	-- Importi
	capImpCompetenza     numeric := 0;
    capImpCassa          numeric := 0;

BEGIN

    messaggioRisultato:='';
    codiceRisultato:=0;

    --dataInizioVal:=clock_timestamp();-- usato al posto di now() per essere certi di riconoscere i record inseriti dopo la chiamata della funzione;
    strMessaggioFinale:='Aggiornamento importi Cassa, Competenza da capitoli equivalenti Gestione anno precedente.Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_EP||'.';
    select tipo.elem_tipo_id into strict IdCapitoloEP
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_EP
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_UP||'.';
    select tipo.elem_tipo_id into strict IdCapitoloUP
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_UP
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_EG||'.';
    select tipo.elem_tipo_id into strict IdCapitoloEG
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_EG
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo Capitolo '||CAPITOLO_UG||'.';
    select tipo.elem_tipo_id into strict IdCapitoloUG
    from siac_d_bil_elem_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_tipo_code=CAPITOLO_UG
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_TIPOLOGIA||'.';
    select classif.classif_tipo_id into strict tipologiaId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_TIPOLOGIA
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_CATEGORIA||'.';
    select classif.classif_tipo_id into strict categoriaTipoId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_CATEGORIA
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_MISSIONE||'.';
    select classif.classif_tipo_id into strict missioneTipoId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_MISSIONE
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_PROGRAMMA||'.';
    select classif.classif_tipo_id into strict programmaTipoId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_PROGRAMMA
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_COFOG||'.';
    select classif.classif_tipo_id into strict cofogTipoId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_COFOG
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_MACROAGGREGATO||'.';
    select classif.classif_tipo_id into strict macroAggrTipoId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_MACROAGGREGATO
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_TITOLO_ENTRATA||'.';
    select classif.classif_tipo_id into strict titoloEntrataId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_TITOLO_ENTRATA
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_TITOLO_SPESA||'.';
    select classif.classif_tipo_id into strict titoloSpesaId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_TITOLO_SPESA
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo attributo '||AT_FUNZIONI_DEL||'.';
    select attr.attr_id into strict funzdelegateId
    from siac_t_attr attr
    where attr.ente_proprietario_id=enteProprietarioId
    and   attr.attr_code=AT_FUNZIONI_DEL
	and   attr.data_cancellazione is null
    and   attr.validita_fine is null;

    strMessaggio:='Lettura identificativo classificatore '||CL_TRANSAZIONE_UE_SPESA||'.';
    select classif.classif_tipo_id into strict transazioneUeSpesaId
    from siac_d_class_tipo classif
    where classif.ente_proprietario_id=enteProprietarioId
    and   classif.classif_tipo_code=CL_TRANSAZIONE_UE_SPESA
	and   classif.data_cancellazione is null
    and   classif.validita_fine is null;

    strMessaggio:='Lettura identificativo tipo importo '||STA_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoStaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=STA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    strMessaggio:='Lettura identificativo tipo importo '||SCA_DET_TIPO||'.';
    select tipo.elem_det_tipo_id into strict detTipoScaId
    from siac_d_bil_elem_det_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.elem_det_tipo_code=SCA_DET_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

    -- Leggi le codifiche
    strMessaggio:='Lettura categoria capitolo.'||gestelemid;
	select s.elem_cat_code into strict capCategoriaCode
      from siac_d_bil_elem_categoria s
     where s.ente_proprietario_id=enteProprietarioId and
           s.elem_cat_id in (select k.elem_cat_id
                               from siac_r_bil_elem_categoria k
                              where k.elem_id=gestelemid
                                and k.validita_fine is null
                                and k.ente_proprietario_id=enteProprietarioId)
       and s.validita_fine is null;

    If prevtipoid in (IdCapitoloEP, IdCapitoloEG) then
        strMessaggio:='Lettura codice classificatore '||CL_CATEGORIA||'.';
        BEGIN
            select k.classif_id, k.classif_code into strict categoriaClassId,classifCategoriaCode
              from siac_t_class k
             where k.classif_id in (select l.classif_id
		                              from siac_r_bil_elem_class l
                                     where l.elem_id = gestelemid)
               and k.classif_tipo_id = categoriaTipoId;
        EXCEPTION
             WHEN OTHERS THEN null;
        END;

        if categoriaClassId is not null then
            strMessaggio:='Lettura codice classificatore '||CL_TIPOLOGIA||'.';
            BEGIN
                select k.classif_id, k.classif_code into strict tipologiaClassId, classifTipologiaCode
                  from siac_t_class k
                 where k.classif_id in (select j.classif_id_padre
				                          from siac_r_class_fam_tree j
                                         where j.ente_proprietario_id=enteProprietarioId
                                           and j.classif_id=categoriaClassId)
                   and k.classif_tipo_id = tipologiaId;
            EXCEPTION
                WHEN OTHERS THEN null;
            END;

            if tipologiaClassId is not null then
                strMessaggio:='Lettura codice classificatore '||CL_TITOLO_ENTRATA||'.';
                BEGIN
                    select k.classif_code into strict classifTitEntCode
                      from siac_t_class k
                     where k.classif_id in (select j.classif_id_padre
				                              from siac_r_class_fam_tree j
                                             where j.ente_proprietario_id=enteProprietarioId
                                               and j.classif_id=tipologiaClassId)
                       and k.classif_tipo_id = titoloEntrataId;
                EXCEPTION
                    WHEN OTHERS THEN null;
                END;
            end if;
        end if;

    else
        -- Capitolo Uscita
        strMessaggio:='Lettura codice classificatore '||CL_PROGRAMMA||'.';
        BEGIN
            select k.classif_id, k.classif_code into strict programmaClassId, classifProgrammaCode
              from siac_t_class k
             where k.classif_id in (select l.classif_id
		                              from siac_r_bil_elem_class l
                                     where l.elem_id = gestelemid)
               and k.classif_tipo_id = programmaTipoId;
        EXCEPTION
             WHEN OTHERS THEN null;
        END;

        strMessaggio:='Lettura codice classificatore '||CL_COFOG||'.';
        BEGIN
            select k.classif_code into strict classifCofogCode
              from siac_t_class k
             where k.classif_id in (select l.classif_id
		                              from siac_r_bil_elem_class l
                                     where l.elem_id = gestelemid)
               and k.classif_tipo_id = cofogTipoId;
        EXCEPTION
             WHEN OTHERS THEN null;
        END;

        strMessaggio:='Lettura codice classificatore '||CL_MACROAGGREGATO||'.';
        BEGIN
            select k.classif_id, k.classif_code into strict macroAggrClassId, classifMacroAggrCode
              from siac_t_class k
             where k.classif_id in (select l.classif_id
		                              from siac_r_bil_elem_class l
                                     where l.elem_id = gestelemid)
               and k.classif_tipo_id = macroAggrTipoId;
        EXCEPTION
            WHEN OTHERS THEN null;
        END;

        strMessaggio:='Lettura codice attributo '||AT_FUNZIONI_DEL||'.';
        BEGIN
            select k."boolean" into strict AttrFunzDelCode
              from siac_r_bil_elem_attr k
             where k.elem_id = gestelemid
		       and k.attr_id = funzdelegateId;
        EXCEPTION
            WHEN OTHERS THEN null;
        END;

        strMessaggio:='Lettura codice classificatore '||CL_TRANSAZIONE_UE_SPESA||'.';
        
        
        
        BEGIN
        select k.classif_code into strict classifTrasfUECode
          from siac_t_class k
         where k.classif_id in (select l.classif_id
		                          from siac_r_bil_elem_class l
                                 where l.elem_id = gestelemid)
           and k.classif_tipo_id = transazioneUeSpesaId;
        EXCEPTION
            WHEN OTHERS THEN null;
        END;



        if programmaClassId is not null then
            strMessaggio:='Lettura codice classificatore '||CL_MISSIONE||'.';
            BEGIN
                select k.classif_code into strict classifMissioneCode
                  from siac_t_class k
                 where k.classif_id in (select j.classif_id_padre
				                          from siac_r_class_fam_tree j
                                         where j.ente_proprietario_id=enteProprietarioId
                                           and j.classif_id=programmaClassId)
                   and k.classif_tipo_id = missioneTipoId;
            EXCEPTION
                WHEN OTHERS THEN null;
            END;
        end if;

        if macroAggrClassId is not null then
            strMessaggio:='Lettura codice classificatore '||CL_TITOLO_SPESA||'.';
            BEGIN
                select k.classif_code into strict classifTitSpesaCode
                  from siac_t_class k
                 where k.classif_id in (select j.classif_id_padre
				                          from siac_r_class_fam_tree j
                                         where j.ente_proprietario_id=enteProprietarioId
                                           and j.classif_id=macroAggrClassId)
                   and k.classif_tipo_id = titoloSpesaId;
            EXCEPTION
                WHEN OTHERS THEN null;
            END;
        end if;

    end if;

    -- Leggi gli importi cassa e competenza
    strMessaggio:='Lettura Importo Cassa.';
    select j.elem_det_importo into strict capImpCassa
	  from siac_t_bil_elem_det j, siac_d_bil_elem_det_tipo k
     where j.elem_id=gestelemid and
	       k.elem_det_tipo_id=detTipoScaId and
		   k.elem_det_tipo_id=j.elem_det_tipo_id and
		   j.periodo_id in (select per.periodo_id
                              from siac_t_bil bil, siac_t_periodo per
                             where bil.ente_proprietario_id=enteProprietarioId and
                                   bil.ente_proprietario_id=per.ente_proprietario_id and
                                   bil.bil_id=gestbilid and
								   per.periodo_id=bil.periodo_id);

    strMessaggio:='Lettura Importo Competenza.';
    select j.elem_det_importo into strict capImpCompetenza
	  from siac_t_bil_elem_det j, siac_d_bil_elem_det_tipo k
     where j.elem_id=gestelemid and
	       k.elem_det_tipo_id=detTipoStaId and
		   k.elem_det_tipo_id=j.elem_det_tipo_id and
		   j.periodo_id in (select per.periodo_id
                              from siac_t_bil bil, siac_t_periodo per
                             where bil.ente_proprietario_id=enteProprietarioId and
                                   bil.ente_proprietario_id=per.ente_proprietario_id and
                                   bil.bil_id=gestbilid and
								   per.periodo_id=bil.periodo_id);

    If prevtipoid in (IdCapitoloEP, IdCapitoloEG) then
        -- Gestione Capitoli Entrata
        BEGIN

            -- Inserisci il capitolo sulla tavola
            IdPrevEntrate := 0;
            strMessaggio:='Inserimento siac_t_cap_e_importi_anno_prec.';

            insert into siac_t_cap_e_importi_anno_prec
                (anno, titolo_code, tipologia_code, categoria_code,
                 elem_id, elem_code, elem_code2, elem_code3, elem_cat_code,
                 importo_competenza, importo_cassa, ente_proprietario_id,
                 data_creazione,login_operazione)
            values
                ((annobilancio-1)::varchar, classifTitEntCode, classifTipologiaCode, classifCategoriaCode,
                 prevelemid, prevelemcode, prevelemcode2, prevelemcode3, capCategoriaCode,
				 capImpCompetenza, capImpCassa, enteProprietarioId,
                 clock_timestamp(),loginOperazione)
            returning imp_prev_entrate_id into IdPrevEntrate;

        EXCEPTION
             WHEN OTHERS THEN null;
        END;

        -- Controlla inserimento ok
        if IdPrevEntrate = 0 then
            RAISE EXCEPTION 'Errore nell''inserimento siac_t_cap_e_importi_anno_prec.';
        end if;

    else
        -- Gestione Capitoli Uscita
        BEGIN

            -- Inserisci il capitolo sulla tavola
            IdPrevSpese := 0;
            strMessaggio:='Inserimento siac_t_cap_u_importi_anno_prec.';

            insert into siac_t_cap_u_importi_anno_prec
                (anno, missione_code, programma_code, cofog_code, titolo_code,
                 macroagg_code, elem_id, elem_code, elem_code2, elem_code3, elem_cat_code,
				 importo_competenza, importo_cassa, ente_proprietario_id,
                 data_creazione, login_operazione,fl_funzionidelegate,fl_trasferimentiue)
            values
                ((annobilancio-1)::varchar, classifMissioneCode, classifProgrammaCode, classifCofogCode,
                 classifTitSpesaCode, classifMacroAggrCode, prevelemid, prevelemcode, prevelemcode2,
				 prevelemcode3, capCategoriaCode, capImpCompetenza, capImpCassa,
				 enteProprietarioId, clock_timestamp(),loginOperazione,AttrFunzDelCode,classifTrasfUECode)
            returning imp_prev_spese_id into IdPrevSpese;

        EXCEPTION
            WHEN OTHERS THEN null;
        END;

        -- Controlla inserimento ok
        if IdPrevSpese = 0 then
            RAISE EXCEPTION 'Errore nell''inserimento siac_t_cap_u_importi_anno_prec.';
        end if;

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