/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_valorizza_tbe_moventrata (
  enteproprietarioid integer,
  loginoperazione varchar,
  setnull_tbe varchar,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
declare
	dataElaborazione timestamp := now();

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
    strMessaggioScarto VARCHAR(1500):='';
    rec VARCHAR(1500):='';

    CL_PDC_V CONSTANT varchar:= 'PDC_V';
    CL_SIOPE CONSTANT varchar:= 'SIOPE_ENTRATA_I';
    CL_ASL CONSTANT varchar:= 'PERIMETRO_SANITARIO_ENTRATA';
    CL_TRANSAZIONE_UE CONSTANT varchar:= 'TRANSAZIONE_UE_ENTRATA';
    CL_RICORRENTE CONSTANT varchar:= 'RICORRENTE_ENTRATA';
    TIPO_MOVIMENTO varchar(1) := 'A';

    idTipoClass_pdc integer := 0;
    idTipoClass_siope integer := 0;
    idTipoClass_asl integer := 0;

    idTipoClass_transazioneUE integer := 0;
    idTipoClass_ricorrente integer := 0;
    idTipoMov integer := 0;

	ASL_DEF CONSTANT varchar:= 'XX';
    idClass_aslDef integer := NULL; -- Valore di default caricato se presente per l'ente

    mov record;
    movAnomalo record;

	-- id classificatori per movimento
    idClass_pdc_mov integer := NULL;
    idClass_siope_mov integer := NULL;
    idClass_asl_mov integer := NULL;
    idClass_transazioneUE_mov integer := NULL;
    idClass_ricorrente_mov integer := NULL;
    -- pk relazione liquidazione/classificatore
    idRClass_pdc_mov integer := NULL;
    idRClass_siope_mov integer := NULL;
    idRClass_asl_mov integer := NULL;
    idRClass_transazioneUE_mov integer := NULL;
    idRClass_ricorrente_mov integer := NULL;

    idClass_pdc_cap integer := NULL;
    idClass_siope_cap integer := NULL;
    idClass_asl_cap integer := NULL;
    idClass_transazioneUE_cap integer := NULL;
    idClass_ricorrente_cap integer := NULL;

    nAnomalie integer := 0;

begin
	strMessaggioFinale := 'Aggiornamento transazione elementare per movimento entrata.';

    --if dataElaborazione is null then
    --	dataElaborazione := now();
    --end if;

	begin

		strMessaggio:='Lettura tipo movimento '||TIPO_MOVIMENTO||'.';

		select d.movgest_tipo_id into idTipoMov
        from siac_d_movgest_tipo d
        where ente_proprietario_id = enteProprietarioId
        and d.movgest_tipo_code = TIPO_MOVIMENTO
        and d.data_cancellazione is null and
        date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
        (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                  or d.validita_fine is null);

	    strMessaggio:='Lettura classificatore tipo_code '||CL_PDC_V||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_pdc
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_PDC_V
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

	    strMessaggio:='Lettura classificatore tipo_code '||CL_SIOPE||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_siope
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_SIOPE
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

	    strMessaggio:='Lettura classificatore tipo_code '||CL_ASL||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_asl
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_ASL
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

	    strMessaggio:='Lettura classificatore tipo_code '||CL_TRANSAZIONE_UE||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_transazioneUE
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_TRANSAZIONE_UE
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

	    strMessaggio:='Lettura classificatore tipo_code '||CL_RICORRENTE||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_ricorrente
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_RICORRENTE
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

		strMessaggio:='Lettura codice di Default per classificatore '||CL_ASL||'.';
        select c.classif_id into idClass_aslDef
        from siac_t_class c
        where c.classif_tipo_id = idTipoClass_asl
        and c.classif_code = ASL_DEF
        and c.ente_proprietario_id = enteProprietarioId
        and c.data_cancellazione is null and
        date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
        (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                  or c.validita_fine is null);

	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||strMessaggio||' NO_DATA_FOUND per ente '||enteProprietarioId||'.';
		 codicerisultato:=-1;
		 return;
        when TOO_MANY_ROWS then
		 messaggioRisultato:=strMessaggioFinale||strMessaggio||' TOO_MANY_ROWS per ente '||enteProprietarioId||'.';
		 codicerisultato:=-1;
		 return;
    end;

    strMessaggio := 'Pulizia log.';
    DELETE FROM log_fnc_siac_valorizza_tbe_movEntrata WHERE ente_proprietario_id = enteproprietarioid;

    strMessaggio := 'Select movimenti anomali con classificatore valido multiplo.';
    -- movimenti da aggiornare (nessun filtro particolare, tutti quelli di spesa) che hanno per medesimo classificatore della tbe piu di un valore valido, non saprei quindi quale considerare.;
    for movAnomalo in
        (select r.movgest_ts_id,tipoClass.classif_tipo_code, count(*)
        from
          siac_r_movgest_class r, siac_t_class c , siac_d_class_tipo tipoClass, siac_t_movgest_ts ts, siac_t_movgest m
          where
		  r.ente_proprietario_id=enteproprietarioid
          and r.classif_id = c.classif_id
          and c.classif_tipo_id=tipoClass.classif_tipo_id
          and r.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                      or r.validita_fine is null)
          and c.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                      or c.validita_fine is null)
          and tipoClass.classif_tipo_code in
          (CL_PDC_V, CL_SIOPE, CL_ASL, CL_TRANSAZIONE_UE, CL_RICORRENTE)
          and tipoClass.ente_proprietario_id=enteproprietarioid
          and tipoClass.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',tipoClass.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoClass.validita_fine)
                          or tipoClass.validita_fine is null)
          and ts.movgest_ts_id=r.movgest_ts_id
          and ts.movgest_id = m.movgest_id
          and m.movgest_tipo_id = idTipoMov
          group by r.movgest_ts_id,tipoClass.classif_tipo_code
          having count(*)>1 order by 1)
          LOOP
          	strMessaggioScarto := movAnomalo.classif_tipo_code||' : piu di un valore valido.';
            insert into log_fnc_siac_valorizza_tbe_movEntrata
              (movgest_ts_id, motivo_scarto,ente_proprietario_id)
            values
              (movAnomalo.movgest_ts_id,strMessaggioScarto,enteproprietarioid);

          	nAnomalie := nAnomalie + 1;
    end loop;

    if nAnomalie > 0 then
      codicerisultato := -1;
      messaggioRisultato:=strMessaggioFinale||' Trovate  '||nAnomalie||' anomalie.';
      return;
    end if;

    FOR mov in
	    (
        Select ts.movgest_ts_id,elem.elem_id, m.movgest_id,  tsTipo.movgest_ts_tipo_code
          from siac_t_movgest m,siac_t_movgest_ts ts, siac_r_movgest_bil_elem elem
          , siac_d_movgest_ts_tipo tsTipo
          where m.ente_proprietario_id=enteproprietarioid
          and m.movgest_tipo_id = idTipoMov
          and m.movgest_id=elem.movgest_id
          and elem.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',elem.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',elem.validita_fine)
                    or elem.validita_fine is null)
          and ts.movgest_id=m.movgest_id
          and tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
--          and ts.movgest_ts_id = 11701
-- aggiornamento del movimento ts migrato oggi
--          and ts.movgest_ts_id in
--          (select movgest_ts_id from siac_r_migr_accertamento_movgest_ts r where r.ente_proprietario_id = 32
--          and date_trunc ('DAY', data_creazione) = date_trunc ('DAY', now()))
          order by m.movgest_id, tsTipo.movgest_ts_tipo_code desc
          )
    loop
    	strMessaggioScarto := null;

        idClass_pdc_mov := NULL;
        idClass_siope_mov := NULL;
        idClass_asl_mov := NULL;
        idClass_transazioneUE_mov := NULL;
        idClass_ricorrente_mov := NULL;
        -- pk relazione mov/classificatore
        idRClass_pdc_mov := NULL;
        idRClass_siope_mov := NULL;
        idRClass_asl_mov := NULL;
        idRClass_transazioneUE_mov := NULL;
        idRClass_ricorrente_mov := NULL;

        idClass_pdc_cap := NULL;
        idClass_siope_cap := NULL;
        idClass_asl_cap := NULL;
        idClass_transazioneUE_cap := NULL;
        idClass_ricorrente_cap := NULL;

    	rec := 'Movimento ts. '||mov.movgest_ts_id||'\'||mov.movgest_ts_tipo_code||', capitolo id '||mov.elem_id||'.';

		-- lettura classificatore per movimento ts da aggiornare
        strMessaggio := 'Lettura classificatore '||CL_PDC_V||' per movimento.';
        select r.movgest_classif_id, r.classif_id into idRClass_pdc_mov, idClass_pdc_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = mov.movgest_ts_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_pdc
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_SIOPE||' per movimento.';
        select r.movgest_classif_id, r.classif_id into idRClass_siope_mov, idClass_siope_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = mov.movgest_ts_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_siope
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_ASL||' per movimento.';
        select r.movgest_classif_id, r.classif_id into idRClass_asl_mov, idClass_asl_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = mov.movgest_ts_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_asl
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_TRANSAZIONE_UE||' per movimento.';
        select r.movgest_classif_id, r.classif_id into idRClass_transazioneUE_mov, idClass_transazioneUE_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = mov.movgest_ts_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_transazioneUE
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_RICORRENTE||' per movimento.';
        select r.movgest_classif_id, r.classif_id into idRClass_ricorrente_mov, idClass_ricorrente_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = mov.movgest_ts_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_ricorrente
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

		-- Lettura classificatore per capitolo da cui copiare
        strMessaggio := 'Lettura classificatore '||CL_PDC_V||' per capitolo '|| mov.elem_id;
        select r.classif_id into idClass_pdc_cap
        from siac_r_bil_elem_class r, siac_t_class c
        where r.elem_id = mov.elem_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_pdc
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_SIOPE||' per capitolo '|| mov.elem_id;
        select r.classif_id into idClass_siope_cap
        from siac_r_bil_elem_class r, siac_t_class c
        where r.elem_id = mov.elem_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_siope
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_ASL||' per capitolo '|| mov.elem_id;
        select r.classif_id into idClass_asl_cap
        from siac_r_bil_elem_class r, siac_t_class c
        where r.elem_id = mov.elem_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_asl
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_TRANSAZIONE_UE||' per capitolo '|| mov.elem_id;
        select r.classif_id into idClass_transazioneUE_cap
        from siac_r_bil_elem_class r, siac_t_class c
        where r.elem_id = mov.elem_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_transazioneUE
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_RICORRENTE||' per capitolo '|| mov.elem_id;
        select r.classif_id into idClass_ricorrente_cap
        from siac_r_bil_elem_class r, siac_t_class c
        where r.elem_id = mov.elem_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_ricorrente
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

		/* 12.01.2016 Nessuna vefifica sull'obbligatorieta dei classificatori
        strMessaggio := 'Verifica completezza transazione elementare.';

        if (idClass_pdc_mov is null or setNull_tbe='S') and idClass_pdc_cap is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_PDC_V||'.';
        elsif (idClass_siope_mov is null or setNull_tbe='S') and idClass_siope_cap is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_SIOPE||'.';
        elsif (idClass_transazioneUE_mov is null or setNull_tbe='S') and idClass_transazioneUE_cap is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_TRANSAZIONE_UE||'.';
        elsif (idClass_ricorrente_mov is null or setNull_tbe='S') and idClass_ricorrente_cap is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_RICORRENTE||'.';
        end if;

        if strMessaggioScarto is not null then
        	-- saltare al record successivo e segnalare in tabella log
            insert into log_fnc_siac_valorizza_tbe_movEntrata
              (movgest_ts_id, elem_id, motivo_scarto,ente_proprietario_id)
            values
              (mov.movgest_ts_id,mov.elem_id,strMessaggioScarto,enteproprietarioid);
        	continue;
        end if;
		*/
        if setNull_tbe is not null and setNull_tbe = 'S' then
			strMessaggio := 'Set Null della tbe presente, classificatori.';
            Update siac_r_movgest_class
              set data_cancellazione = dataElaborazione
              , validita_fine = dataElaborazione
              , login_operazione = loginoperazione
            where ente_proprietario_id = enteproprietarioid
            and movgest_classif_id in (idRClass_pdc_mov,
                                     idRClass_siope_mov,
                                     idRClass_asl_mov,
                                     idRClass_transazioneUE_mov,
                                     idRClass_ricorrente_mov);

            idClass_pdc_mov := NULL;
            idClass_siope_mov := NULL;
            idClass_asl_mov := NULL;
            idClass_transazioneUE_mov := NULL;
            idClass_ricorrente_mov := NULL;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_PDC_V||'.';
        if idClass_pdc_mov is null and idClass_pdc_cap is not null THEN
          	insert into siac_r_movgest_class
  				(movgest_ts_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(mov.movgest_ts_id, idClass_pdc_cap,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_pdc_mov <> idClass_pdc_cap then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_PDC_V||'.';
            insert into log_fnc_siac_valorizza_tbe_movEntrata
              (movgest_ts_id, elem_id, motivo_scarto,ente_proprietario_id)
            values
              (mov.movgest_ts_id,mov.elem_id,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_SIOPE||'.';
        if idClass_siope_mov is null and idClass_siope_cap is not null  THEN
          	insert into siac_r_movgest_class
  				(movgest_ts_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(mov.movgest_ts_id, idClass_siope_cap,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_siope_mov <> idClass_siope_cap then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_SIOPE||'.';
            insert into log_fnc_siac_valorizza_tbe_movEntrata
              (movgest_ts_id, elem_id, motivo_scarto,ente_proprietario_id)
            values
              (mov.movgest_ts_id,mov.elem_id,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_ASL||'.';
        if idClass_asl_mov is null
        	--and idClass_asl_cap is not null
        THEN
        	if idClass_asl_cap is not null then
              insert into siac_r_movgest_class
                  (movgest_ts_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
              values
                  (mov.movgest_ts_id, idClass_asl_cap,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
            elsif idClass_aslDef is not null then
              -- 19.01.2016 se esiste il valore di default per questo classificatore, lo associamo al movimento.
              insert into siac_r_movgest_class
                  (movgest_ts_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
              values
                  (mov.movgest_ts_id, idClass_aslDef,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
            end if;
        else
          if idClass_asl_mov <> idClass_asl_cap then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_ASL||'.';
            insert into log_fnc_siac_valorizza_tbe_movEntrata
              (movgest_ts_id, elem_id, motivo_scarto,ente_proprietario_id)
            values
              (mov.movgest_ts_id,mov.elem_id,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_TRANSAZIONE_UE||'.';
        if idClass_transazioneUE_mov is null and idClass_transazioneUE_cap is not null THEN
          	insert into siac_r_movgest_class
  				(movgest_ts_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(mov.movgest_ts_id, idClass_transazioneUE_cap,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_transazioneUE_mov <> idClass_transazioneUE_cap then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_TRANSAZIONE_UE||'.';
            insert into log_fnc_siac_valorizza_tbe_movEntrata
              (movgest_ts_id, elem_id, motivo_scarto,ente_proprietario_id)
            values
              (mov.movgest_ts_id,mov.elem_id,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_RICORRENTE||'.';
        if idClass_ricorrente_mov is null and idClass_ricorrente_cap is not null THEN
          	insert into siac_r_movgest_class
  				(movgest_ts_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(mov.movgest_ts_id, idClass_ricorrente_cap,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_ricorrente_mov <> idClass_ricorrente_cap then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_RICORRENTE||'.';
            insert into log_fnc_siac_valorizza_tbe_movEntrata
              (movgest_ts_id, elem_id, motivo_scarto,ente_proprietario_id)
            values
              (mov.movgest_ts_id,mov.elem_id,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

    end loop;

    codicerisultato:=-0;
    messaggioRisultato:=strMessaggioFinale||'Ok.';


exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codicerisultato:=-1;
        return;
	when others  THEN
		raise notice '% % % ERRORE DB: % %',strMessaggioFinale,rec,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||rec||strMessaggio||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codicerisultato:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;