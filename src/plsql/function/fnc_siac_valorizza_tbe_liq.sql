/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_siac_valorizza_tbe_liq (
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
    CL_COFOG CONSTANT varchar:= 'GRUPPO_COFOG';
    CL_SIOPE CONSTANT varchar:= 'SIOPE_SPESA_I';
    CL_ASL CONSTANT varchar:= 'PERIMETRO_SANITARIO_SPESA';
    CL_TRANSAZIONE_UE CONSTANT varchar:= 'TRANSAZIONE_UE_SPESA';
    CL_RICORRENTE CONSTANT varchar:= 'RICORRENTE_SPESA';
    CL_POL_REG_UNITARIE CONSTANT varchar:= 'POLITICHE_REGIONALI_UNITARIE';
    ATTR_CUP CONSTANT varchar:= 'cup';
    ATTR_CIG CONSTANT varchar:= 'cig';

    idTipoClass_pdc integer := 0;
    idTipoClass_cofog integer := 0;
    idTipoClass_siope integer := 0;
    idTipoClass_asl integer := 0;
    idTipoClass_transazioneUE integer := 0;
    idTipoClass_ricorrente integer := 0;
    idTipoClass_polRegUnitarie integer := 0;
    idAttr_cup integer := 0;
    idAttr_cig integer := 0;

    liquidazione record;
    liqAnomala record;

	-- id classificatori per liquidazione
    idClass_pdc_liq integer := NULL;
    idClass_cofog_liq integer := NULL;
    idClass_siope_liq integer := NULL;
    idClass_asl_liq integer := NULL;
    idClass_transazioneUE_liq integer := NULL;
    idClass_ricorrente_liq integer := NULL;
    idClass_polRegUnitarie_liq integer := NULL;
	testoAttr_cup_liq varchar := NULL;
	testoAttr_cig_liq varchar := NULL;
    -- pk relazione liquidazione/classificatore
    idRClass_pdc_liq integer := NULL;
    idRClass_cofog_liq integer := NULL;
    idRClass_siope_liq integer := NULL;
    idRClass_asl_liq integer := NULL;
    idRClass_transazioneUE_liq integer := NULL;
    idRClass_ricorrente_liq integer := NULL;
    idRClass_polRegUnitarie_liq integer := NULL;
    idAttr_cup_liq integer := NULL;
    idAttr_cig_liq integer := NULL;

    idClass_pdc_mov integer := NULL;
    idClass_cofog_mov integer := NULL;
    idClass_siope_mov integer := NULL;
    idClass_asl_mov integer := NULL;
    idClass_transazioneUE_mov integer := NULL;
    idClass_ricorrente_mov integer := NULL;
    idClass_polRegUnitarie_mov integer := NULL;
    testoAttr_cup_mov varchar := NULL;
    testoAttr_cig_mov varchar := NULL;

    nAnomalie integer := 0;

begin
	strMessaggioFinale := 'Aggiornamento transazione elementare per liquidazioni.';

--    if dataElaborazione is null then
--    	dataElaborazione := now();
--    end if;

	begin

	    strMessaggio:='Lettura classificatore tipo_code '||CL_PDC_V||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_pdc
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_PDC_V
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

	    strMessaggio:='Lettura classificatore tipo_code '||CL_COFOG||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_cofog
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_COFOG
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

	    strMessaggio:='Lettura classificatore tipo_code '||CL_POL_REG_UNITARIE||'.';
        select tipoPdcFin.classif_tipo_id into strict idTipoClass_polRegUnitarie
        from siac_d_class_tipo tipoPdcFin
              where tipoPdcFin.ente_proprietario_id=enteProprietarioId
              and tipoPdcFin.classif_tipo_code=CL_POL_REG_UNITARIE
              and tipoPdcFin.data_cancellazione is null and
              date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFin.validita_inizio) and
              (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFin.validita_fine)
                        or tipoPdcFin.validita_fine is null);

	    strMessaggio:='Lettura attributo attr_code '||ATTR_CUP||'.';
		select  attr.attr_id into strict idAttr_cup
          from siac_t_attr attr
          where attr.ente_proprietario_id=enteProprietarioId and
                attr.attr_code= ATTR_CUP and
                attr.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attr.validita_fine)
			              or attr.validita_fine is null);

	    strMessaggio:='Lettura attributo attr_code '||ATTR_CIG||'.';
		select  attr.attr_id into strict idAttr_cig
          from siac_t_attr attr
          where attr.ente_proprietario_id=enteProprietarioId and
                attr.attr_code= ATTR_CIG and
                attr.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attr.validita_fine)
			              or attr.validita_fine is null);

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
    DELETE FROM log_fnc_siac_valorizza_tbe_liq WHERE ente_proprietario_id = enteproprietarioid;

    strMessaggio := 'Select liquidazioni anomale con classificatore valido multiplo.';
    -- liquidazioni legate ad un movimento in stato != ANNULLATO (quindi per cui aggiornare la tbe) che hanno per medesimo classificatore della tbe piu di un valore valido.';
    for liqAnomala in
        (select l.liq_id, l.liq_anno, l.liq_numero, tipoClass.classif_tipo_code, count(*)
        from
        siac_t_liquidazione l, siac_r_liquidazione_movgest m, siac_r_liquidazione_stato st, siac_d_liquidazione_stato ds
        , siac_r_liquidazione_class r, siac_t_class c , siac_d_class_tipo tipoClass
          where l.ente_proprietario_id=enteproprietarioid
          and l.liq_id=m.liq_id
          and m.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',m.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',m.validita_fine)
                    or m.validita_fine is null)
          and st.liq_id=l.liq_id and
          st.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',st.validita_inizio) and
          (date_trunc('day',dataElaborazione)<date_trunc('day',st.validita_fine)
                    or st.validita_fine is null)
          and ds.liq_stato_id=st.liq_stato_id and ds.liq_stato_code != 'A' and ds.ente_proprietario_id = enteproprietarioid
          and r.liq_id = l.liq_id
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
          (CL_PDC_V, CL_COFOG, CL_SIOPE, CL_ASL, CL_TRANSAZIONE_UE, CL_RICORRENTE, CL_POL_REG_UNITARIE)
          and tipoClass.ente_proprietario_id=enteproprietarioid
          and tipoClass.data_cancellazione is null and
                date_trunc('day',dataElaborazione)>=date_trunc('day',tipoClass.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoClass.validita_fine)
                          or tipoClass.validita_fine is null)
          group by l.liq_id, l.liq_anno, l.liq_numero, tipoClass.classif_tipo_code
          having count(*)>1 order by 1)
          LOOP
          	strMessaggioScarto := liqAnomala.classif_tipo_code||' : piu di un valore valido.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liqAnomala.liq_id,liqAnomala.liq_anno,liqAnomala.liq_numero,strMessaggioScarto,enteproprietarioid);

          	nAnomalie := nAnomalie + 1;
    end loop;
    strMessaggio := 'Select liquidazioni anomale con attributo valido multiplo.';
    for liqAnomala in
    	(select l.liq_id, l.liq_anno, l.liq_numero, attr.attr_code, count(*)
        from
        siac_t_liquidazione l, siac_r_liquidazione_movgest m, siac_r_liquidazione_stato st, siac_d_liquidazione_stato ds
        , siac_t_attr attr, siac_r_liquidazione_attr r
          where l.ente_proprietario_id=enteproprietarioid
          and l.liq_id=m.liq_id
          and m.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',m.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',m.validita_fine)
                    or m.validita_fine is null)
          and st.liq_id=l.liq_id and
          st.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',st.validita_inizio) and
          (date_trunc('day',dataElaborazione)<date_trunc('day',st.validita_fine)
                    or st.validita_fine is null)
          and ds.liq_stato_id=st.liq_stato_id and ds.liq_stato_code != 'A' and ds.ente_proprietario_id = enteproprietarioid
          and r.liq_id=l.liq_id
          and r.attr_id=attr.attr_id
          and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
		  and attr.ente_proprietario_id=enteproprietarioid
          and attr.attr_code in (ATTR_CUP,ATTR_CIG) and
                attr.data_cancellazione is null and
	            date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio) and
	 		   (date_trunc('day',dataElaborazione)<=date_trunc('day',attr.validita_fine)
			              or attr.validita_fine is null)
		  group by l.liq_id, l.liq_anno, l.liq_numero, attr.attr_code
          having count(*) > 1 order by 1)
    loop

      strMessaggioScarto := liqAnomala.attr_code||' : piu di un valore valido.';
      insert into log_fnc_siac_valorizza_tbe_liq
        (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
      values
        (liqAnomala.liq_id,liqAnomala.liq_anno,liqAnomala.liq_numero,strMessaggioScarto,enteproprietarioid);

      nAnomalie := nAnomalie + 1;
    end loop;

    if nAnomalie > 0 then
      codicerisultato := -1;
      messaggioRisultato:=strMessaggioFinale||' Trovate  '||nAnomalie||' anomalie.';
      return;
    end if;

    FOR liquidazione in
	    (select l.liq_id, l.liq_anno, l.liq_numero, m.movgest_ts_id
          from
          siac_t_liquidazione l, siac_r_liquidazione_movgest m, siac_r_liquidazione_stato st, siac_d_liquidazione_stato ds
          where l.ente_proprietario_id=enteproprietarioid
          and l.liq_id=m.liq_id
          and m.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',m.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',m.validita_fine)
                    or m.validita_fine is null)
          and st.liq_id=l.liq_id and
          st.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',st.validita_inizio) and
          (date_trunc('day',dataElaborazione)<date_trunc('day',st.validita_fine)
                    or st.validita_fine is null)
          and ds.liq_stato_id=st.liq_stato_id and ds.liq_stato_code != 'A' and ds.ente_proprietario_id = enteproprietarioid
          )
    loop
    	strMessaggioScarto := null;

        idClass_pdc_liq := NULL;
        idClass_cofog_liq := NULL;
        idClass_siope_liq := NULL;
        idClass_asl_liq := NULL;
        idClass_transazioneUE_liq := NULL;
        idClass_ricorrente_liq := NULL;
        idClass_polRegUnitarie_liq := NULL;
        testoAttr_cup_liq := NULL;
        testoAttr_cig_liq := NULL;

        idRClass_pdc_liq := NULL;
        idRClass_cofog_liq := NULL;
        idRClass_siope_liq := NULL;
        idRClass_asl_liq := NULL;
        idRClass_transazioneUE_liq := NULL;
        idRClass_ricorrente_liq := NULL;
        idRClass_polRegUnitarie_liq := NULL;
		idAttr_cup_liq := NULL;
        idAttr_cig_liq := NULL;

        idClass_pdc_mov := NULL;
        idClass_cofog_mov := NULL;
        idClass_siope_mov := NULL;
        idClass_asl_mov := NULL;
        idClass_transazioneUE_mov := NULL;
        idClass_ricorrente_mov := NULL;
        idClass_polRegUnitarie_mov := NULL;
        testoAttr_cup_mov := NULL;
        testoAttr_cig_mov := NULL;

    	rec := 'Liq. '||liquidazione.liq_anno||'\'||liquidazione.liq_numero||', id '||liquidazione.liq_id||'.';

        strMessaggio := 'Lettura classificatore '||CL_PDC_V||' per liquidazione.';
        select r.liq_classif_id, r.classif_id into idRClass_pdc_liq, idClass_pdc_liq
        from siac_r_liquidazione_class r, siac_t_class c
        where r.liq_id = liquidazione.liq_id
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


        strMessaggio := 'Lettura classificatore '||CL_COFOG||' per liquidazione.';
        select r.liq_classif_id, r.classif_id into idRClass_cofog_liq,idClass_cofog_liq
        from siac_r_liquidazione_class r, siac_t_class c
        where r.liq_id = liquidazione.liq_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_cofog
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_SIOPE||' per liquidazione.';
        select r.liq_classif_id,r.classif_id into idRClass_siope_liq, idClass_siope_liq
        from siac_r_liquidazione_class r, siac_t_class c
        where r.liq_id = liquidazione.liq_id
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

        strMessaggio := 'Lettura classificatore '||CL_ASL||' per liquidazione.';
        select r.liq_classif_id,r.classif_id into idRClass_asl_liq, idClass_asl_liq
        from siac_r_liquidazione_class r, siac_t_class c
        where r.liq_id = liquidazione.liq_id
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

        strMessaggio := 'Lettura classificatore '||CL_TRANSAZIONE_UE||' per liquidazione.';
        select r.liq_classif_id,r.classif_id into idRClass_transazioneUE_liq,idClass_transazioneUE_liq
        from siac_r_liquidazione_class r, siac_t_class c
        where r.liq_id = liquidazione.liq_id
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

        strMessaggio := 'Lettura classificatore '||CL_RICORRENTE||' per liquidazione.';
        select r.liq_classif_id,r.classif_id into idRClass_ricorrente_liq, idClass_ricorrente_liq
        from siac_r_liquidazione_class r, siac_t_class c
        where r.liq_id = liquidazione.liq_id
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

        strMessaggio := 'Lettura classificatore '||CL_POL_REG_UNITARIE||' per liquidazione.';
        select r.liq_classif_id, r.classif_id into idRClass_polRegUnitarie_liq, idClass_polRegUnitarie_liq
        from siac_r_liquidazione_class r, siac_t_class c
        where r.liq_id = liquidazione.liq_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_polRegUnitarie
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura attributo '||ATTR_CUP||' per liquidazione.';
        select r.liq_attr_id, r.testo into idAttr_cup_liq, testoAttr_cup_liq
        from siac_r_liquidazione_attr r
        where r.liq_id= liquidazione.liq_id
        and r.attr_id=idAttr_cup
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null);

        strMessaggio := 'Lettura attributo '||ATTR_CIG||' per liquidazione.';
        select r.liq_attr_id, r.testo into idAttr_cig_liq, testoAttr_cig_liq
        from siac_r_liquidazione_attr r
        where r.liq_id= liquidazione.liq_id
        and r.attr_id=idAttr_cig
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_PDC_V||' per movimento.';
        select r.classif_id into idClass_pdc_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = liquidazione.movgest_ts_id
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

        strMessaggio := 'Lettura classificatore '||CL_COFOG||' per movimento.';
        select r.classif_id into idClass_cofog_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = liquidazione.movgest_ts_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_cofog
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura classificatore '||CL_SIOPE||' per movimento.';
        select r.classif_id into idClass_siope_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = liquidazione.movgest_ts_id
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
        select r.classif_id into idClass_asl_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = liquidazione.movgest_ts_id
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
        select r.classif_id into idClass_transazioneUE_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = liquidazione.movgest_ts_id
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
        select r.classif_id into idClass_ricorrente_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = liquidazione.movgest_ts_id
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

        strMessaggio := 'Lettura classificatore '||CL_POL_REG_UNITARIE||' per movimento.';
        select r.classif_id into idClass_polRegUnitarie_mov
        from siac_r_movgest_class r, siac_t_class c
        where r.movgest_ts_id = liquidazione.movgest_ts_id
        and r.classif_id = c.classif_id
        and c.classif_tipo_id=idTipoClass_polRegUnitarie
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null)
        and c.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',c.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',c.validita_fine)
                    or c.validita_fine is null);

        strMessaggio := 'Lettura attributo '||ATTR_CUP||' per movimento.';
        select r.testo into testoAttr_cup_mov
        from siac_r_movgest_ts_attr r
        where r.movgest_ts_id= liquidazione.movgest_ts_id
        and r.attr_id=idAttr_cup
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null);

        strMessaggio := 'Lettura attributo '||ATTR_CIG||' per movimento.';
        select r.testo into testoAttr_cig_mov
        from siac_r_movgest_ts_attr r
        where r.movgest_ts_id= liquidazione.movgest_ts_id
        and r.attr_id=idAttr_cig
        and r.data_cancellazione is null and
          date_trunc('day',dataElaborazione)>=date_trunc('day',r.validita_inizio) and
          (date_trunc('day',dataElaborazione)<=date_trunc('day',r.validita_fine)
                    or r.validita_fine is null);

		/* 12.01.2016 Nessun classificatore obbligatorio
        strMessaggio := 'Verifica completezza transazione elementare.';

        if (idClass_pdc_liq is null or setNull_tbe='S') and idClass_pdc_mov is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_PDC_V||'.';
        elsif (idClass_cofog_liq is null or setNull_tbe='S') and idClass_cofog_mov is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_COFOG||'.';
        elsif (idClass_siope_liq is null or setNull_tbe='S') and idClass_siope_mov is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_SIOPE||'.';
        elsif (idClass_transazioneUE_liq is null or setNull_tbe='S') and idClass_transazioneUE_mov is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_TRANSAZIONE_UE||'.';
        elsif (idClass_ricorrente_liq is null or setNull_tbe='S') and idClass_ricorrente_mov is null then
        	strMessaggioScarto := 'Transazione elementare incompleta, definire '|| CL_RICORRENTE||'.';
        end if;

        if strMessaggioScarto is not null then
        	-- saltare alla liquidazione successiva e segnalare in tabella log
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
        	continue;
        end if;
		*/
        if setNull_tbe is not null and setNull_tbe = 'S' then
			strMessaggio := 'Set Null della tbe presente, classificatori.';
            Update siac_r_liquidazione_class
              set data_cancellazione = dataElaborazione
              , validita_fine = dataElaborazione
              , login_operazione = loginoperazione
            where ente_proprietario_id = enteproprietarioid
            and liq_classif_id in (idRClass_pdc_liq,
							         idRClass_cofog_liq,
                                     idRClass_siope_liq,
                                     idRClass_asl_liq,
                                     idRClass_transazioneUE_liq,
                                     idRClass_ricorrente_liq,
                                     idRClass_polRegUnitarie_liq);

			strMessaggio := 'Set Null della tbe presente, attributi.';
            Update siac_r_liquidazione_attr
              set data_cancellazione = dataElaborazione
              , validita_fine = dataElaborazione
              , login_operazione = loginoperazione
            where ente_proprietario_id = enteproprietarioid
            and liq_attr_id in (idAttr_cup_liq, idAttr_cig_liq);

            idClass_pdc_liq := NULL;
            idClass_cofog_liq := NULL;
            idClass_siope_liq := NULL;
            idClass_asl_liq := NULL;
            idClass_transazioneUE_liq := NULL;
            idClass_ricorrente_liq := NULL;
            idClass_polRegUnitarie_liq := NULL;
            testoAttr_cup_liq := NULL;
            idAttr_cup_liq := NULL;
            testoAttr_cig_liq := NULL;
            idAttr_cig_liq := NULL;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_PDC_V||'.';
        if idClass_pdc_liq is null and idClass_pdc_mov is not null THEN
          	insert into siac_r_liquidazione_class
  				(liq_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(liquidazione.liq_id, idClass_pdc_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_pdc_liq <> idClass_pdc_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_PDC_V||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;


        strMessaggio := 'Inserimento classificatore '||CL_COFOG||'.';
        if idClass_cofog_liq is null and idClass_cofog_mov is not null THEN
          	insert into siac_r_liquidazione_class
  				(liq_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(liquidazione.liq_id, idClass_cofog_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_cofog_liq <> idClass_cofog_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_COFOG||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_SIOPE||'.';
        if idClass_siope_liq is null and idClass_siope_mov is not null THEN
          	insert into siac_r_liquidazione_class
  				(liq_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(liquidazione.liq_id, idClass_siope_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_siope_liq <> idClass_siope_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_SIOPE||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_ASL||'.';
        if idClass_asl_liq is null and idClass_asl_mov is not null  THEN
          	insert into siac_r_liquidazione_class
  				(liq_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(liquidazione.liq_id, idClass_asl_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_asl_liq <> idClass_asl_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_ASL||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_TRANSAZIONE_UE||'.';
        if idClass_transazioneUE_liq is null and idClass_transazioneUE_mov is not null THEN
          	insert into siac_r_liquidazione_class
  				(liq_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(liquidazione.liq_id, idClass_transazioneUE_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_transazioneUE_liq <> idClass_transazioneUE_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_TRANSAZIONE_UE||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_RICORRENTE||'.';
        if idClass_ricorrente_liq is null and idClass_ricorrente_mov is not null THEN
          	insert into siac_r_liquidazione_class
  				(liq_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(liquidazione.liq_id, idClass_ricorrente_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_ricorrente_liq <> idClass_ricorrente_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_RICORRENTE||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento classificatore '||CL_POL_REG_UNITARIE||'.';
        if idClass_polRegUnitarie_liq is null and idClass_polRegUnitarie_mov is not null THEN
          	insert into siac_r_liquidazione_class
  				(liq_id,classif_id,validita_inizio,ente_proprietario_id,login_operazione)
			values
            	(liquidazione.liq_id, idClass_polRegUnitarie_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if idClass_polRegUnitarie_liq <> idClass_polRegUnitarie_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Classificatore non coerente '||CL_POL_REG_UNITARIE||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento attributo '||ATTR_CUP||'.';
        if (testoAttr_cup_liq is null or testoAttr_cup_liq='') and (testoAttr_cup_mov is not null and testoAttr_cup_mov!='') THEN
			-- se attributo cup definito per liquidazione deve essere chiuso.
        	if idAttr_cup_liq is not null then
              Update siac_r_liquidazione_attr
                set data_cancellazione = dataElaborazione
                , validita_fine = dataElaborazione
                , login_operazione = loginoperazione
              where ente_proprietario_id = enteproprietarioid
              and liq_attr_id = idAttr_cup_liq;
			end if;
            insert into siac_r_liquidazione_attr
                (liq_id,attr_id,testo,validita_inizio,ente_proprietario_id,login_operazione)
            values
                (liquidazione.liq_id,idAttr_cup,testoAttr_cup_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if testoAttr_cup_liq <> testoAttr_cup_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Attributo non coerente '||ATTR_CUP||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
          end if;
        end if;

        strMessaggio := 'Inserimento attributo '||ATTR_CIG||'.';
        if (testoAttr_cig_liq is null or testoAttr_cig_liq='') and (testoAttr_cig_mov is not null and testoAttr_cig_mov!='') THEN
			-- se attributo cig definito per liquidazione deve essere chiuso.
        	if idAttr_cig_liq is not null then
              Update siac_r_liquidazione_attr
                set data_cancellazione = dataElaborazione
                , validita_fine = dataElaborazione
                , login_operazione = loginoperazione
              where ente_proprietario_id = enteproprietarioid
              and liq_attr_id = idAttr_cig_liq;
			end if;
            insert into siac_r_liquidazione_attr
                (liq_id,attr_id,testo,validita_inizio,ente_proprietario_id,login_operazione)
            values
                (liquidazione.liq_id,idAttr_cig,testoAttr_cig_mov,date_trunc('DAY', dataElaborazione),enteproprietarioid,loginoperazione);
        else
          if testoAttr_cig_liq <> testoAttr_cig_mov then
          -- inserimento in tabella log
          	strMessaggioScarto := 'Attributo non coerente '||ATTR_CIG||'.';
            insert into log_fnc_siac_valorizza_tbe_liq
              (liq_id, liq_anno, liq_numero, motivo_scarto,ente_proprietario_id)
            values
              (liquidazione.liq_id,liquidazione.liq_anno,liquidazione.liq_numero,strMessaggioScarto,enteproprietarioid);
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