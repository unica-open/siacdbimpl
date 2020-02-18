/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_migr_docquo_spesa(enteProprietarioId integer,
                                                 nomeEnte VARCHAR,
                                                 annobilancio varchar,
                                                 loginOperazione varchar,
											     dataElaborazione timestamp,
												 idMin integer,
												 idMax integer,
											     out numeroRecordInseriti integer,
												 out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE

 strMessaggio VARCHAR(1500):='';
 strMessaggioFinale VARCHAR(1500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrDoc integer := 0;

 migrDocumento record;
 migrAttoAmm record;

 --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
 --dataInizioVal timestamp :=annoBilancio||'-01-01';
 dataInizioVal timestamp :=null;

 codBolloId integer:=null;
 subDocId      integer:=null;
 scartoId   integer:=null;
 attoAmmId  integer:=null;
 movGestId  integer:=null;
 movGestTsId integer:=null;
 liqId       integer:=null;
 ordTsId       integer:=null;

 bilancioId integer:=null;
 bilancioPrecId integer:=null;
 movGestTipoId integer:=null;
 movGestTsTipoId_T integer:=null;
 movGestTsTipoId_S integer:=null;
 ordTipoId         integer:=null;

 SUBDOC_TIPO         CONSTANT  varchar :='SS';
 ORD_TIPO            CONSTANT  varchar :='P';

 SPR                   CONSTANT varchar:='SPR||';
 NVL_STR               CONSTANT VARCHAR:='';

 MOVGEST_IMPEGNO		  CONSTANT varchar:='I';  -- codice da ricercare  nella tabella siac_d_movgest_tipo
 MOVGEST_TS_IMPEGNI    CONSTANT varchar:='T';  -- codice da ricercare  nella tabella siac_d_movgest_ts_tipo
 MOVGEST_TS_SUBIMP     CONSTANT varchar:='S';  -- codice da ricercare  nella tabella siac_d_movgest_ts_tipo

 CAUS_SOSP_ATTR        CONSTANT  varchar :='causale_sospensione'; -- new
 DATA_SOSP_ATTR        CONSTANT  varchar :='data_sospensione'; -- new
 DATA_RIATT_ATTR       CONSTANT  varchar :='data_riattivazione'; -- new
 FLAG_ORD_SING_ATTR    CONSTANT  varchar :='flagOrdinativoSingolo';
 FLAG_RIL_IVA_ATTR     CONSTANT  varchar :='flagRilevanteIVA';
 FLAG_AVVISO_ATTR      CONSTANT  varchar :='flagAvviso';
 FLAG_ESPROPRIO_ATTR   CONSTANT  varchar :='flagEsproprio';
 FLAG_ORD_MANUALE_ATTR CONSTANT  varchar :='flagOrdinativoManuale';
 NOTE_ATTR             CONSTANT  varchar :='Note';
 CAUS_ORD_ATTR         CONSTANT  varchar :='causaleOrdinativo';
 NRO_MUTUO_ATTR        CONSTANT  varchar :='numeroMutuo'; -- sostituito da una relazione
 ANNOTAZIONE_CERTIF_CRED_ATTR CONSTANT  varchar :='annotazione'; -- new
 DATA_CERTIF_CRED_ATTR CONSTANT  varchar :='dataCertificazione'; -- new
 NOTE_CERTIF_CRED_ATTR CONSTANT  varchar :='noteCertificazione'; -- new
 NUMERO_CERTIF_CRED_ATTR CONSTANT  varchar :='numeroCertificazione'; -- new
 FLAG_CERTIF_CRED_ATTR CONSTANT  varchar :='flagCertificazione'; -- new
 CUP_ATTR CONSTANT  varchar :='cup';
 CIG_ATTR CONSTANT  varchar :='cig';
 TIPO_AVVISO_CL     CONSTANT  varchar :='TIPO_AVVISO';
 DATA_SCAD_DOPOSOSP_ATTR  CONSTANT  varchar :='dataScadenzaDopoSospensione';


 --ANNO_IMP_FITTIZIO CONSTANT    integer :=9999; --se la quota è pagata non viene legata ad alcun impegno.
 --NUMERO_IMP_FITTIZIO CONSTANT  integer :=999999; --se la quota è pagata non viene legata ad alcun impegno.
 ANNO_LIQ_FITTIZIO CONSTANT    integer :=9999;
 NUMERO_LIQ_FITTIZIO CONSTANT  integer :=999999;
 ANNO_ORD_FITTIZIO CONSTANT    integer :=9999;
 NUMERO_ORD_FITTIZIO CONSTANT  integer :=999999;

 commissioneTipoId       integer:=null;
 subDocTipoId            integer:=null;



 causSospensioneAttrId   integer:=null;
 dataSospensioneAttrId   integer:=null;
 dataRiattivazioneAttrId integer:=null;
 flagOrdSingoloAttrId    integer:=null;
 flagRilIvaAttrId        integer:=null;
 flagAvvisoAttrId        integer:=null;
 flagEsproprioAttrId    integer:=null;
 flagOrdManualeAttrId    integer:=null;
 noteAttrId              integer:=null;
 causaleOrdAttrId        integer:=null;
 nroMutuoAttrId          integer:=null;
 annotazioneCertifCredAttrId integer:=null;
 dataCertifCredAttrId integer:=null;
 noteCertifCredAttrId integer:=null;
 numeroCertifCredAttrId integer:=null;
 flagCertifCredAttrId integer:=null;
 cupAttrId integer:=null;
 cigAttrId integer:=null;
 tipoAvvisoClassTipoId integer:=null;
 dataScadDopoSospAttrId  integer:=null;

-- movGestTsFitId integer :=null;--10.11.2015 Dani, se la quota è pagata non viene legata ad alcun impegno.
 liqFitId       integer :=null;
 ordTsFitId     integer :=null;



 modpagOraId       integer:=null;
 migrModPagId      integer:=null;
 mdpSedeSecondaria varchar(1):=null;
 mdpCessione       varchar(10):=null;
 soggettoOraId     integer:=null;
 sedeOraId         integer:=null;

 soggettoSedeId    integer:=null;
 modPagId          integer:=null;
 soggRelMdpId      integer:=null;
 generaCodiceSog varchar(1):=null;

 docIds record; -- cursore aggiornamento contatore siac_t_subdoc_num
BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';

    --     richiesta Vitelli del 18.09.015 per caricare i bilancio 2016
    dataInizioVal:=date_trunc('DAY', now());

	strMessaggioFinale:='Migrazione quote documenti di spesa da id ['||idMin||'] a id ['||idMin||']';

    strMessaggio:='Lettura quote documenti spesa da migrare.';
	begin
		select distinct 1 into strict countMigrDoc from migr_docquo_spesa ms
		where ms.ente_proprietario_id=enteProprietarioId
        and   ms.fl_elab='N'
		and   ms.migr_docquo_spesa_id >= idMin and ms.migr_docquo_spesa_id <=idMax
        and   exists (select 1 from migr_doc_spesa md
                      where md.docspesa_id=ms.docspesa_id
                        and md.ente_proprietario_id=ms.ente_proprietario_id
                        and md.fl_elab='S');
	exception
		when NO_DATA_FOUND then
		 messaggioRisultato:=strMessaggioFinale||' Archivio migrazione vuoto per ente '||enteProprietarioId||'.';
		 numeroRecordInseriti:=-12;
		 return;
	end;

    -- lettura id bilancio
	strMessaggio:='Lettura id bilancio per anno '||annoBilancio||'.';
    select bilancio.idbilancio, bilancio.messaggiorisultato into bilancioId,messaggioRisultato
	from fnc_get_bilancio(enteProprietarioId,annoBilancio) bilancio;
	if (bilancioid=-1) then
		messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
		numerorecordinseriti:=-13;
		return;
	end if;

    -- lettura id bilancio precedente
	strMessaggio:='Lettura id bilancio per anno '||annoBilancio::INTEGER-1||'.';
    select bilancio.idbilancio, bilancio.messaggiorisultato into bilancioPrecId,messaggioRisultato
	from fnc_get_bilancio(enteProprietarioId,(annoBilancio::INTEGER-1)::varchar) bilancio;
	if (bilancioid=-1) then
		messaggioRisultato:=strMessaggioFinale||messaggioRisultato;
		numerorecordinseriti:=-13;
		return;
	end if;

    begin


        strMessaggio:='Lettura tipo subdocumento  '||SUBDOC_TIPO||'.';

        select tipo.subdoc_tipo_id into strict subDocTipoId
        from siac_d_subdoc_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.subdoc_tipo_code=SUBDOC_TIPO
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

        strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_IMPEGNO||'.';
	    select d.movgest_tipo_id into strict movGestTipoId
    	from siac_d_movgest_tipo d
	    where d.ente_proprietario_id=enteproprietarioid
    	and d.movgest_tipo_code = MOVGEST_IMPEGNO
	    and d.data_cancellazione is null and
            date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
            (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                or d.validita_fine is null);


        strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_TS_IMPEGNI||'.';
    	select d.movgest_ts_tipo_id into strict movGestTsTipoId_T
        from siac_d_movgest_ts_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.movgest_ts_tipo_code = MOVGEST_TS_IMPEGNI
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);

    	strMessaggio:='Lettura tipo movimento per codice '||MOVGEST_TS_SUBIMP||'.';
    	select d.movgest_ts_tipo_id into strict movGestTsTipoId_S
        from siac_d_movgest_ts_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.movgest_ts_tipo_code = MOVGEST_TS_SUBIMP
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);

        strMessaggio:='Lettura tipo ordinativo per codice '||ORD_TIPO||'.';
    	select d.ord_tipo_id into strict ordTipoId
        from siac_d_ordinativo_tipo d
        where d.ente_proprietario_id=enteproprietarioid
        and d.ord_tipo_code = ORD_TIPO
		and d.data_cancellazione is null and
              	date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio) and
                (date_trunc('day',dataElaborazione)<=date_trunc('day',d.validita_fine)
                    or d.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||CAUS_SOSP_ATTR||'.';

        select attr.attr_id into strict causSospensioneAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=CAUS_SOSP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


		strMessaggio:='Lettura identificativo attributo '||DATA_SOSP_ATTR||'.';

        select attr.attr_id into strict dataSospensioneAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_SOSP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||DATA_RIATT_ATTR||'.';

        select attr.attr_id into strict dataRiattivazioneAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_RIATT_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||FLAG_ORD_SING_ATTR||'.';

        select attr.attr_id into strict flagOrdSingoloAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_ORD_SING_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||FLAG_RIL_IVA_ATTR||'.';

        select attr.attr_id into strict flagRilIvaAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_RIL_IVA_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);



        strMessaggio:='Lettura identificativo attributo '||FLAG_AVVISO_ATTR||'.';

        select attr.attr_id into strict flagAvvisoAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_AVVISO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||FLAG_ESPROPRIO_ATTR||'.';

        select attr.attr_id into strict flagEsproprioAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_ESPROPRIO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);



        strMessaggio:='Lettura identificativo attributo '||FLAG_ORD_MANUALE_ATTR||'.';

        select attr.attr_id into strict flagOrdManualeAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_ORD_MANUALE_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||NOTE_ATTR||'.';

        select attr.attr_id into strict noteAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


		strMessaggio:='Lettura identificativo attributo '||CAUS_ORD_ATTR||'.';

        select attr.attr_id into strict causaleOrdAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=CAUS_ORD_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


		strMessaggio:='Lettura identificativo attributo '||NRO_MUTUO_ATTR||'.';

        select attr.attr_id into strict nroMutuoAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NRO_MUTUO_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||ANNOTAZIONE_CERTIF_CRED_ATTR||'.';

        select attr.attr_id into strict annotazioneCertifCredAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=ANNOTAZIONE_CERTIF_CRED_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);



        strMessaggio:='Lettura identificativo attributo '||DATA_CERTIF_CRED_ATTR||'.';

        select attr.attr_id into strict dataCertifCredAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_CERTIF_CRED_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||NOTE_CERTIF_CRED_ATTR||'.';

        select attr.attr_id into strict noteCertifCredAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NOTE_CERTIF_CRED_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);



        strMessaggio:='Lettura identificativo attributo '||NUMERO_CERTIF_CRED_ATTR||'.';

        select attr.attr_id into strict numeroCertifCredAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=NUMERO_CERTIF_CRED_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||FLAG_CERTIF_CRED_ATTR||'.';

        select attr.attr_id into strict flagCertifCredAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=FLAG_CERTIF_CRED_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||CUP_ATTR||'.';

        select attr.attr_id into strict cupAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=CUP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);

        strMessaggio:='Lettura identificativo attributo '||CIG_ATTR||'.';

        select attr.attr_id into strict cigAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=CIG_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo attributo '||DATA_SCAD_DOPOSOSP_ATTR||'.';

        select attr.attr_id into strict dataScadDopoSospAttrId
        from siac_t_attr attr
        where attr.ente_proprietario_id=enteProprietarioId
        and   attr.attr_code=DATA_SCAD_DOPOSOSP_ATTR
        and   attr.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',attr.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',attr.validita_fine) or attr.validita_fine is null);


        strMessaggio:='Lettura identificativo classificatore '||TIPO_AVVISO_CL||'.';

        select tipo.classif_tipo_id into strict tipoAvvisoClassTipoId
        from siac_d_class_tipo tipo
        where tipo.ente_proprietario_id=enteProprietarioId
        and   tipo.classif_tipo_code=TIPO_AVVISO_CL
        and   tipo.data_cancellazione is null
	    and   date_trunc('day',dataElaborazione)>=date_trunc('day',tipo.validita_inizio)
    	and  (date_trunc('day',dataElaborazione)<date_trunc('day',tipo.validita_fine) or tipo.validita_fine is null);

--10.11.2015 Dani, se la quota è pagata non viene legata ad alcun impegno.
/*		strMessaggio:='Lettura identificativo movimento [siac_t_movgest_ts] fittizio.';
        select  dett.movgest_ts_id into strict movGestTsFitId
        from siac_t_movgest mov , siac_t_movgest_ts dett
        where mov.ente_proprietario_id=enteProprietarioId
		  and mov.bil_id=bilancioPrecId
		  and mov.movgest_tipo_id=movGestTipoId
          and mov.movgest_anno = ANNO_IMP_FITTIZIO
          and mov.movgest_numero= NUMERO_IMP_FITTIZIO
          and dett.movgest_id=mov.movgest_id
	      and dett.movgest_ts_tipo_id=movGestTsTipoId_T;*/

        strMessaggio:='Lettura identificativo liquidazione fittizia.';
		select liq.liq_id into strict liqFitId
        from siac_t_liquidazione liq
        where liq.ente_proprietario_id=enteProprietarioId
        and   liq.bil_id=bilancioPrecId
        and   liq.liq_anno=ANNO_LIQ_FITTIZIO
        and   liq.liq_numero=NUMERO_LIQ_FITTIZIO;

		strMessaggio:='Lettura identificativo ordinativo [siac_t_ordinativo_ts] fittizio.';
        select  dett.ord_ts_id into strict ordTsFitId
        from siac_t_ordinativo ord , siac_t_ordinativo_ts dett
        where ord.ente_proprietario_id=enteProprietarioId
		  and ord.bil_id=bilancioPrecId
		  and ord.ord_tipo_id=ordTipoId
          and ord.ord_anno = ANNO_ORD_FITTIZIO
          and ord.ord_numero= NUMERO_ORD_FITTIZIO
          and dett.ord_id=ord.ord_id;


        exception
		when no_data_found then
			RAISE EXCEPTION ' Non presente in archivio';
		when others  THEN
			RAISE EXCEPTION ' %-%.',SQLSTATE,substring(upper(SQLERRM) from 1 for 500);
    end;


    strMessaggio:='Lettura quote documenti spesa da migrare.Inizio ciclo.';
    for migrDocumento IN
    (select ms.*,sogg.soggetto_id, doc.doc_id,doc.doc_tipo_id,
            (case coalesce(ms.flag_manuale,'X')
                     when 'S' then 'S'
                     else 'N' end) flag_ord_manuale,
            (case ms.numero_mandato when 0 then 'N' else 'S' end) flag_pagato
     from migr_docquo_spesa ms
         inner join migr_doc_spesa md on (md.docspesa_id=ms.docspesa_id
                                      and md.ente_proprietario_id=ms.ente_proprietario_id
                                      and md.fl_elab='S')
         inner join siac_r_migr_doc_spesa_t_doc migrRelDocSpesa on (migrRelDocSpesa.migr_doc_spesa_id=md.migr_docspesa_id)
         inner join siac_t_doc doc on (doc.doc_id=migrRelDocSpesa.doc_id
                                    and doc.ente_proprietario_id=ms.ente_proprietario_id
                                    and doc.data_cancellazione is null
                                    and date_trunc('day',dataelaborazione)>=date_trunc('day',doc.validita_inizio)
                                    and (date_trunc('day',dataelaborazione)<=date_trunc('day',doc.validita_fine)
                      						     or doc.validita_fine is null))
         inner join siac_r_doc_sog sogg on ( sogg.doc_id=doc.doc_id
		                                and sogg.ente_proprietario_id=doc.ente_proprietario_id
	                                    and sogg.data_cancellazione is null
    	                                and date_trunc('day',dataelaborazione)>=date_trunc('day',sogg.validita_inizio)
        	                            and (date_trunc('day',dataelaborazione)<=date_trunc('day',sogg.validita_fine)
                      						     or sogg.validita_fine is null))
	 where ms.ente_proprietario_id=enteProprietarioId
     and   ms.fl_elab='N'
     and   ms.migr_docquo_spesa_id >= idMin and ms.migr_docquo_spesa_id <=idMax
     order by ms.migr_docquo_spesa_id
    )
    loop

	    commissioneTipoId:=null;
		subDocId:=null;
        scartoId:=null;
        attoAmmId:=null;
        movGestId:=null;
		movGestTsId:=null;
		liqId:=null;
        ordTsId:=null;


        modpagOraId:=null;
        migrModPagId:=null;
        mdpSedeSecondaria:=null;
        mdpCessione:=null;
        soggettoOraId:=null;
        sedeOraId:=null;

		soggettoSedeId:=null;
        modPagId:=null;
        soggRelMdpId:=null;
        generaCodiceSog:=null;

        -- DAVIDE - 29.09.2016 - se numero_iva = 0 forza null, così come in importo_splitreverse
--        if migrDocumento.numero_iva = 0 then
        if migrDocumento.numero_iva = '0' then -- 18.10.2016 Sofia
		    migrDocumento.numero_iva := null;
        end if;

        if migrDocumento.importo_splitreverse = 0 then
		    migrDocumento.importo_splitreverse := null;
			migrDocumento.tipo_iva_splitreverse := null;
        end if;
        -- DAVIDE - 29.09.2016 - Fine

        -- se quota pagata impegno-liquidazione-ordinativo associati  sono  del bilancio precedente e fittizi
        if migrDocumento.flag_pagato='S' then
--10.11.2015 Dani, se la quota è pagata non viene legata ad alcun impegno.
--        	movGestTsId:=movGestTsFitId;
            liqId:=liqFitId;
            ordTsId:=ordTsFitId;
        end if;

        -- tipo
		-- anno
		-- numero
		-- codice_soggetto
		-- frazione
        -- descrizione
        -- importo
        -- numero_iva
        -- data_scadenza
        -- importo_da_dedurre
		-- commissioni
        -- flag_rilevante_iva
		-- causale_sospensione
        -- data_sospensione
        -- data_riattivazione
        -- flag_ord_singolo
        -- flag_avviso
        -- flag_esproprio
        -- flag_manuale
		-- note
		-- causale_ordinativo
		-- numero_mutuo
        -- annotazione_certif_crediti
        -- data_certif_crediti
		-- note_certif_crediti
		-- numero_certif_crediti
        -- flag_certif_crediti
		-- utente_creazione
		-- utente_modifica
        -- cup
		-- cig
		-- tipo_avviso

		-- anno_provvedimento
		-- numero_provvedimento
		-- tipo_provvedimento
		-- sac_provvedimento
		-- oggetto_provvedimento
		-- note_provvedimento
		-- stato_provvedimento


        -- anno_esercizio
		-- anno_impegno
		-- numero_impegno
		-- numero_subimpegno
		-- numero_liquidazione
		-- numero_mandato

		-- codice_modpag
		-- codice_modpag_del
		-- codice_indirizzo
		-- sede_secondaria

		-- anno_elenco
		-- numero_elenco
		-- elenco_doc_id


		-- da posizionare
		-- data_scandenza_new
		-- codice_soggetto_pag



        strMessaggio:='Lettura commissioni='||quote_nullable(migrDocumento.commissioni)||' per inserimento siac_t_subdoc per migr_docquo_spesa_id='
                      ||migrDocumento.migr_docquo_spesa_id||'.';
    	-- commissioni
        if coalesce(migrDocumento.commissioni,NVL_STR)!=NVL_STR then
 	    	select d.comm_tipo_id into commissioneTipoId
    	    from siac_d_commissione_tipo d
	        where d.comm_tipo_code=migrDocumento.commissioni
    	    and   d.ente_proprietario_id=enteProprietarioId
        	and   d.data_cancellazione is null
	        and   date_trunc('day',dataElaborazione)>=date_trunc('day',d.validita_inizio)
    	    and  (date_trunc('day',dataElaborazione)<date_trunc('day',d.validita_fine) or d.validita_fine is null);

            if commissioneTipoId is null then
                  strMessaggio:=strMessaggio||' Codice commissioni='||migrDocumento.commissioni||' non presente in archivio.';
	       		  INSERT INTO migr_docquo_spesa_scarto
				  (migr_docquo_spesa_id,
	               motivo_scarto,
			       data_creazione,
		           ente_proprietario_id
			      )values(migrDocumento.migr_docquo_spesa_id,
                          strMessaggio,
                          clock_timestamp(),
                          enteProprietarioId);
--                  (select migrDocumento.migr_docquo_spesa_id,
--                          strMessaggio,
--                          clock_timestamp(),
--                          enteProprietarioId
--                   where not exists
--                   (select 1 from migr_docquo_spesa_scarto s
--                    where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                    and   s.ente_proprietario_id=enteProprietarioId));

                  continue;
            end if;
        end if;
		--ATTO AMMINISTRATIVO  ###############
        -- anno_provvedimento
		-- numero_provvedimento
		-- tipo_provvedimento
		-- sac_provvedimento
		-- oggetto_provvedimento
		-- note_provvedimento
		-- stato_provvedimento
        strMessaggio:='Lettura provvedimento per inserimento siac_t_subdoc per migr_docquo_spesa_id='
                      ||migrDocumento.migr_docquo_spesa_id||'.';
        if coalesce(migrDocumento.numero_provvedimento,0)!=0
           or migrDocumento.tipo_provvedimento=SPR
           then

      	     select * into migrAttoAmm
             from fnc_migr_attoamm (migrDocumento.anno_provvedimento,migrDocumento.numero_provvedimento,
                                    migrDocumento.tipo_provvedimento,migrDocumento.sac_provvedimento,
                                    migrDocumento.oggetto_provvedimento,migrDocumento.note_provvedimento,
                                    migrDocumento.stato_provvedimento,
                                    enteProprietarioId,loginOperazione,dataElaborazione, dataInizioVal);
             if migrAttoAmm.codiceRisultato=-1 then
           	  strMessaggio:=strMessaggio||migrAttoAmm.messaggioRisultato;
             ELSE
              attoAmmId := migrAttoAmm.id;
             end if;
       		 if coalesce(attoAmmId,0) = 0 then
 				strMessaggio := strMessaggio||'Atto amm scarto.';
	            INSERT INTO migr_docquo_spesa_scarto
			    (migr_docquo_spesa_id,
	    	     motivo_scarto,
			     data_creazione,
			     ente_proprietario_id
			    )values(migrDocumento.migr_docquo_spesa_id,
     	                strMessaggio,
        	            clock_timestamp(),
                        enteProprietarioId);
--	            (select migrDocumento.migr_docquo_spesa_id,
--     	                strMessaggio,
--        	            clock_timestamp(),
--                        enteProprietarioId
--				 where not exists
--                       (select 1 from migr_docquo_spesa_scarto s
--                        where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                        and   s.ente_proprietario_id=enteProprietarioId));

	            continue;
    	    end if;
        end if;

		-- anno_esercizio
		-- anno_impegno
		-- numero_impegno
		-- numero_subimpegno

        if migrDocumento.flag_pagato='N' and migrDocumento.numero_impegno!=0 then
        	strMessaggio:='Lettura impegno [siac_t_movgest] per inserimento siac_t_subdoc per migr_docquo_spesa_id='
                      ||migrDocumento.migr_docquo_spesa_id||'.';
			select mov.movgest_id into movGestId
            from siac_t_movgest mov
            where mov.ente_proprietario_id=enteProprietarioId
			  and mov.bil_id=bilancioId
 			  and mov.movgest_tipo_id=movGestTipoId
              and mov.movgest_anno = migrDocumento.anno_impegno::INTEGER
              and mov.movgest_numero= migrDocumento.numero_impegno
              and mov.data_cancellazione is null
              and date_trunc('day',dataelaborazione)>=date_trunc('day',mov.validita_inizio) and
                  (date_trunc('day',dataelaborazione)<=date_trunc('day',mov.validita_fine)
                     or mov.validita_fine is null);

            if coalesce(movGestId,0)!=0 then
	            if migrDocumento.numero_subimpegno=0 then
                	-- la quota doc ? legata ad un movimento di tipo IMPEGNO da ricercare nella siac_t_movgest_ts
		            strMessaggio:='Lettura impegno [siac_t_movgest_ts] per inserimento siac_t_subdoc per migr_docquo_spesa_id='
                      ||migrDocumento.migr_docquo_spesa_id||'.';
    		        select coalesce(dett.movgest_ts_id,0) into movGestTsId
        		    from siac_t_movgest_ts dett
            		where dett.ente_proprietario_id=enteProprietarioId
                    and dett.movgest_id=movGestId
	            	and dett.movgest_ts_tipo_id=movGestTsTipoId_T
                    and dett.data_cancellazione is null
                    and date_trunc('day',dataelaborazione)>=date_trunc('day',dett.validita_inizio)
                    and (date_trunc('day',dataelaborazione)<=date_trunc('day',dett.validita_fine)
                           or dett.validita_fine is null);

    	        else
             	   -- la quota doc ? legata ad un movimento di tipo IMPEGNO da ricercare nella siac_t_movgest_ts
		            strMessaggio:='Lettura subimpegno [siac_t_movgest_ts] per inserimento siac_t_subdoc per migr_docquo_spesa_id='
                      ||migrDocumento.migr_docquo_spesa_id||'.';
	               select coalesce(dett.movgest_ts_id,0) into movGestTsId
	               from siac_t_movgest_ts dett
		           where dett.ente_proprietario_id=enteProprietarioId
                     and dett.movgest_id=movGestId
		             and dett.movgest_ts_tipo_id=movGestTsTipoId_S
		  			 and dett.movgest_ts_code=migrDocumento.numero_subimpegno::VARCHAR
                     and dett.data_cancellazione is null
                     and date_trunc('day',dataelaborazione)>=date_trunc('day',dett.validita_inizio)
                     and (date_trunc('day',dataelaborazione)<=date_trunc('day',dett.validita_fine)
                            or dett.validita_fine is null);
        	    end if;

                if coalesce(movGestTsId,0) = 0 then
	                strMessaggio := strMessaggio||'Movimento non valido, presente o migrato.';
	            	INSERT INTO migr_docquo_spesa_scarto
			   		(migr_docquo_spesa_id,
	    	  	   	 motivo_scarto,
			     	 data_creazione,
			     	 ente_proprietario_id
			    	)values(migrDocumento.migr_docquo_spesa_id,
     	            	    strMessaggio,
        	            	clock_timestamp(),
	                        enteProprietarioId);
--	           		(select migrDocumento.migr_docquo_spesa_id,
--     	            	    strMessaggio,
--        	            	clock_timestamp(),
--	                        enteProprietarioId
--					 where not exists
--        	               (select 1 from migr_docquo_spesa_scarto s
--            	            where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                	        and   s.ente_proprietario_id=enteProprietarioId));
		            continue;
                end if;
			else
            	strMessaggio := strMessaggio||'Movimento non valido, presente o migrato.';
	            INSERT INTO migr_docquo_spesa_scarto
			    (migr_docquo_spesa_id,
	    	     motivo_scarto,
			     data_creazione,
			     ente_proprietario_id
			    )values(migrDocumento.migr_docquo_spesa_id,
     	                strMessaggio,
        	            clock_timestamp(),
                        enteProprietarioId);
--	            (select migrDocumento.migr_docquo_spesa_id,
--     	                strMessaggio,
--        	            clock_timestamp(),
--                        enteProprietarioId
--				 where not exists
--                       (select 1 from migr_docquo_spesa_scarto s
--                        where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                        and   s.ente_proprietario_id=enteProprietarioId));
		            continue;
            end if;

        end if;

        -- numero_liquidazione
        if migrDocumento.flag_pagato='N' and migrDocumento.numero_liquidazione!=0 then
	        strMessaggio:='Lettura liquidazione per inserimento siac_t_subdoc per migr_docquo_spesa_id='
                      ||migrDocumento.migr_docquo_spesa_id||'.';
        	select liq.liq_id into liqId
            from migr_liquidazione  migrLiq, siac_r_migr_liquidazione_t_liquidazione migrLiqRel, siac_t_liquidazione liq
            where migrLiq.numero_liquidazione=migrDocumento.numero_liquidazione
            and   migrLiq.anno_esercizio = migrDocumento.anno_esercizio
            and   migrLiq.ente_proprietario_id=enteProprietarioId
            and   migrliqrel.migr_liquidazione_id=migrLiq.migr_liquidazione_id
            and   liq.liq_id=migrliqrel.liquidazione_id
            and   liq.bil_id=bilancioId
            and   liq.data_cancellazione is null
            and   date_trunc('day',dataelaborazione)>=date_trunc('day',liq.validita_inizio)
            and  (date_trunc('day',dataelaborazione)<=date_trunc('day',liq.validita_fine)
                          or liq.validita_fine is null);

            if coalesce(liqId,0) = 0 then
	            strMessaggio := strMessaggio||'Liquidazione non valida, presente o migrata.';
	            INSERT INTO migr_docquo_spesa_scarto
			    (migr_docquo_spesa_id,
	    	     motivo_scarto,
			     data_creazione,
			     ente_proprietario_id
			    )values(migrDocumento.migr_docquo_spesa_id,
     	                strMessaggio,
        	            clock_timestamp(),
                        enteProprietarioId);
--	            (select migrDocumento.migr_docquo_spesa_id,
--     	                strMessaggio,
--        	            clock_timestamp(),
--                        enteProprietarioId
--				 where not exists
--                       (select 1 from migr_docquo_spesa_scarto s
--                        where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                        and   s.ente_proprietario_id=enteProprietarioId));
		            continue;
            end if;

        end if;

        -- codice_modpag
		-- codice_modpag_del
		-- codice_indirizzo
		-- sede_secondaria

        strMessaggio:='Lettura dati MDP  per inserimento siac_t_subdoc per migr_docquo_spesa_id='
                      ||migrDocumento.migr_docquo_spesa_id||'.';

        if  coalesce(migrDocumento.codice_modpag_del::integer,0)=0 and
            coalesce(migrDocumento.codice_modpag::integer,0)!=0 then
	        strMessaggio:='Lettura dati MDP  per inserimento siac_t_subdoc'
                          ||' codice_modpag='||quote_nullable(migrDocumento.codice_modpag)
                          ||' codice_soggetto='||quote_nullable(migrDocumento.codice_soggetto)
                          ||' sede id='||quote_nullable(migrDocumento.sede_id)
                          ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
			if migrDocumento.sede_id is null or migrDocumento.sede_id = 0 then
              select m.migr_modpag_id , m.modpag_id , coalesce(m.sede_secondaria,'N'), m.cessione, mo.soggetto_id ,m.sede_id
              into migrModPagId, modpagOraId, mdpSedeSecondaria, mdpCessione, soggettoOraId , sedeOraId
              from migr_modpag m, migr_soggetto mo
              where  mo.codice_soggetto=migrDocumento.codice_soggetto
                and  mo.ente_proprietario_id=enteProprietarioId
                and   (mo.delegato_id <1 or mo.delegato_id is null)
                and   mo.fl_genera_codice='N'
                and   m.soggetto_id=mo.soggetto_id
                and   m.codice_modpag=migrDocumento.codice_modpag
                and   m.ente_proprietario_id=enteProprietarioId
                and   m.fl_genera_codice='N'
                and   (m.delegato_id <1 or m.delegato_id is null)
                and   m.sede_id is null;
            else
              select m.migr_modpag_id , m.modpag_id , coalesce(m.sede_secondaria,'N'), m.cessione, mo.soggetto_id ,m.sede_id
              into migrModPagId, modpagOraId, mdpSedeSecondaria, mdpCessione, soggettoOraId , sedeOraId
              from migr_modpag m, migr_soggetto mo
              where  mo.codice_soggetto=migrDocumento.codice_soggetto
                and  mo.ente_proprietario_id=enteProprietarioId
                and   (mo.delegato_id <1 or mo.delegato_id is null)
                and   mo.fl_genera_codice='N'
                and   m.soggetto_id=mo.soggetto_id
                and   m.codice_modpag=migrDocumento.codice_modpag
                and   m.ente_proprietario_id=enteProprietarioId
                and   m.fl_genera_codice='N'
                and   (m.delegato_id <1 or m.delegato_id is null)
                and  m.sede_id=migrDocumento.sede_id;
            end if;
        else
          if  coalesce(migrDocumento.codice_modpag_del::integer,0)!=0 and
              coalesce(migrDocumento.codice_modpag::integer,0)!=0 then
            strMessaggio:='Lettura dati MDP  per inserimento siac_t_subdoc'
                          ||' codice_modpag='||quote_nullable(migrDocumento.codice_modpag)
                          ||' codice_modpag_del='||quote_nullable(migrDocumento.codice_modpag_del)
                          ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
            select m.migr_modpag_id, m.modpag_id , coalesce(m.sede_secondaria,'N'), m.cessione, mo.soggetto_id ,m.sede_id
            , mo.fl_genera_codice
            into migrModPagId,modpagOraId, mdpSedeSecondaria, mdpCessione, soggettoOraId , sedeOraId, generaCodiceSog
            from migr_modpag m, migr_soggetto mo
            where  mo.codice_soggetto=migrDocumento.codice_soggetto
              and  mo.ente_proprietario_id=enteProprietarioId
              and   m.soggetto_id=mo.soggetto_id
              and   m.codice_modpag=migrDocumento.codice_modpag
              and   m.codice_modpag_del=migrDocumento.codice_modpag_del
              and   m.ente_proprietario_id=enteProprietarioId
              and   m.fl_genera_codice='S';
           if generaCodiceSog = 'S' then
           	  -- se generaCodode del soggetto = 'S' le info su modpagId (usato come modpagda),sedeId, sede secondaria e cessione devono essere prese dal soggetto principale , quindi quello con generacodice = N
              select  m.modpag_id ,m.sede_id, coalesce(m.sede_secondaria,'N'), m.cessione
              into modpagOraId,sedeOraId, mdpSedeSecondaria, mdpCessione
              from migr_modpag m, migr_soggetto mo
              where  mo.codice_soggetto=migrDocumento.codice_soggetto
                and  mo.ente_proprietario_id=enteProprietarioId
                and   m.soggetto_id=mo.soggetto_id
                and   m.codice_modpag=migrDocumento.codice_modpag
                and   m.codice_modpag_del=migrDocumento.codice_modpag_del
                and   m.ente_proprietario_id=enteProprietarioId
                and   m.fl_genera_codice='N'
                and   mo.fl_genera_codice='N';
           end if;
          end if;
       end if;


       if   coalesce(migrDocumento.codice_modpag_del::integer,0)!=0 or
            coalesce(migrDocumento.codice_modpag::integer,0)!=0 then
        if coalesce(modPagOraId ,0)=0 then
               	 strMessaggio:=strMessaggio||'MDP non migrata o dati incongruenti.';
                 scartoId:=-1;
        else
       	 if mdpSedeSecondaria='S' then
            	-- ricerco soggettoSedeId
        	if migrDocumento.codice_indirizzo=0 then
            	strMessaggio:=strMessaggio||' Ricerca sede secondaria migrata.';
	            select coalesce(soggRel.soggetto_id_a,0) into soggettoSedeId
                from migr_sede_secondaria migrSede, siac_r_migr_sede_secondaria_rel_sede rel, siac_r_soggetto_relaz soggRel
                where migrSede.sede_id=sedeOraId
                and   migrSede.ente_proprietario_id=enteProprietarioId
                and   rel.migr_sede_id=migrsede.migr_sede_id
                and   soggRel.soggetto_relaz_id=rel.soggetto_relaz_id;
            else
                strMessaggio:=strMessaggio||' Ricerca sede secondaria migrata per codice_indirizzo='
                              ||migrDocumento.codice_indirizzo||'.';
                select coalesce(soggRel.soggetto_id_a,0) into soggettoSedeId
                from migr_sede_secondaria migrSede, siac_r_migr_sede_secondaria_rel_sede rel, siac_r_soggetto_relaz soggRel
                where migrSede.sede_id=sedeOraId
                and   migrSede.codice_indirizzo=migrDocumento.codice_indirizzo
                and   migrSede.ente_proprietario_id=enteProprietarioId
                and   rel.migr_sede_id=migrsede.migr_sede_id
                and   soggRel.soggetto_relaz_id=rel.soggetto_relaz_id;
            end if;

            if coalesce(soggettoSedeId,0) = 0 then
            	strMessaggio:=strMessaggio||'Sede secondaria non migrata o dati incrongruenti.';
                scartoId:=-1;
            end if;
         end if;

         if scartoId is null   then
         	if coalesce(mdpCessione ,NVL_STR)!=NVL_STR then
            	-- ricerca MDP cessione
                strMessaggio:=strMessaggio||' Ricerca dati cessione '||mdpCessione||'.';
				if mdpCessione='CSI' then -- 31.12.2015 Sofia relazioni invertite
	                select  coalesce(relMdp.modpag_id,0), COALESCE(relMdp.soggrelmpag_id,0) into modPagId, soggRelMdpId
    	            from migr_relaz_soggetto rel, siac_r_migr_relaz_soggetto_relaz relCessione,
        	             siac_r_soggrel_modpag relMdp
            	    where rel.modpag_id_da=modpagOraId
                	and   rel.ente_proprietario_id=enteProprietarioId
	                and   relCessione.migr_relaz_id=rel.migr_relaz_id
    	            and   relMdp.soggetto_relaz_id=relCessione.soggetto_relaz_id;
                else
                	select  coalesce(relMdp.modpag_id,0), COALESCE(relMdp.soggrelmpag_id,0) into modPagId, soggRelMdpId
    	            from migr_relaz_soggetto rel, siac_r_migr_relaz_soggetto_relaz relCessione,
        	             siac_r_soggrel_modpag relMdp
            	    where rel.modpag_id_a=modpagOraId
                	and   rel.ente_proprietario_id=enteProprietarioId
	                and   relCessione.migr_relaz_id=rel.migr_relaz_id
    	            and   relMdp.soggetto_relaz_id=relCessione.soggetto_relaz_id;
                end if;

                if coalesce(modPagId,0) = 0 then
                	strMessaggio:=strMessaggio||'Dati cessione non migrati e non congruenti.';
                    scartoId:=-1;
                end if;
           else
           	   -- ricerca MDP no cessione
               strMessaggio:=strMessaggio||' Ricerca dati MDP.';

               select coalesce(m.modpag_id,0) into modPagId
               from siac_r_migr_modpag_modpag m
               where m.migr_modpag_id=migrModPagId
               and   m.ente_proprietario_id=enteProprietarioId;

               if coalesce(modPagId,0) = 0 then
                	strMessaggio:=strMessaggio||'MDP non migrata.';
                    scartoId:=-1;
               end if;
           end if;
         end if;
        end if;
       end if;

       if coalesce(scartoId,0)=-1 then
       	-- strMessaggio valorizzato sopra
        INSERT INTO migr_docquo_spesa_scarto
        (migr_docquo_spesa_id,
	     motivo_scarto,
	     data_creazione,
	     ente_proprietario_id
	     )values(migrDocumento.migr_docquo_spesa_id,
                 strMessaggio,
                 clock_timestamp(),
                 enteProprietarioId);
--	     (select migrDocumento.migr_docquo_spesa_id,
--                 strMessaggio,
--                 clock_timestamp(),
--                 enteProprietarioId
--	      where not exists
--                (select 1 from migr_docquo_spesa_scarto s
--                 where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                 and   s.ente_proprietario_id=enteProprietarioId));
		 continue;
       end if;

		-- siac_t_subdoc
	    strMessaggio:='Inserimento siac_t_subdoc per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
        INSERT INTO siac_t_subdoc
		(subdoc_numero,
         subdoc_desc,
         subdoc_importo,
         subdoc_nreg_iva,
         subdoc_data_scadenza,
         subdoc_convalida_manuale,
         subdoc_importo_da_dedurre,
  --       contotes_id,
  --       dist_id,
         comm_tipo_id,
         doc_id,
         subdoc_tipo_id,
  --       notetes_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
         login_operazione,
         login_creazione,
         login_modifica,
         subdoc_data_pagamento_cec,
         subdoc_pagato_cec,
         subdoc_splitreverse_importo
		)
        values
        (migrDocumento.frazione,
         migrDocumento.descrizione,
         abs(migrDocumento.importo),
         migrDocumento.numero_iva,
		 to_timestamp(migrDocumento.data_scadenza,'yyyy-MM-dd'),
         migrDocumento.flag_manuale,
         abs(migrDocumento.importo_da_dedurre),
         commissioneTipoId,
         migrDocumento.doc_id,
         subDocTipoId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione,
         migrDocumento.utente_creazione,
         migrDocumento.utente_modifica,
         to_timestamp(migrDocumento.data_pagamento_cec,'yyyy-MM-dd'),
         case coalesce(migrDocumento.data_pagamento_cec,'') when '' then false else true end,
         migrDocumento.importo_splitreverse
        )
        returning subdoc_id into subDocId;

       if subDocId is null then
       	strMessaggio:=strMessaggio||' Scarto per inserimento non riuscito.';
        INSERT INTO migr_docquo_spesa_scarto
	    (migr_docquo_spesa_id,
   	     motivo_scarto,
	     data_creazione,
	     ente_proprietario_id
	    )values(migrDocumento.migr_docquo_spesa_id,
                strMessaggio,
   	            clock_timestamp(),
                enteProprietarioId);
--        (select migrDocumento.migr_docquo_spesa_id,
--                strMessaggio,
--   	            clock_timestamp(),
--                enteProprietarioId
--      	 where not exists
--               (select 1 from migr_docquo_spesa_scarto s
--                where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                and   s.ente_proprietario_id=enteProprietarioId));

         continue;

       end if;

	   scartoId:=null;
       -- siac_r_subdoc_atto_amm
       if coalesce(attoAmmId,0)!=0 then
        strMessaggio:='Inserimento siac_r_subdoc_atto_amm per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
       	insert into siac_r_subdoc_atto_amm
        (subdoc_id,
         attoamm_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
	     login_operazione )
        values
        (subDocId,
         attoAmmId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione
        )
        returning subdoc_atto_amm_id into scartoId;

        if scartoId is null then
			strMessaggio:=strMessaggio||' Scarto per inserimento attoAmm.';
            INSERT INTO migr_docquo_spesa_scarto
		    (migr_docquo_spesa_id,
    	     motivo_scarto,
		     data_creazione,
		     ente_proprietario_id
		    )values(migrDocumento.migr_docquo_spesa_id,
   	                strMessaggio,
       	            clock_timestamp(),
                    enteProprietarioId);
--            (select migrDocumento.migr_docquo_spesa_id,
--   	                strMessaggio,
--       	            clock_timestamp(),
--                    enteProprietarioId
--			 where not exists
--                   (select 1 from migr_docquo_spesa_scarto s
--                    where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                    and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc inserito.';
             delete from siac_t_subdoc       where subdoc_id=subDocId;

            continue;
        end if;
       end if;

       scartoId:=null;
       -- siac_r_subdoc_movgest_ts
       if coalesce(movGestTsId,0)!=0 then
        strMessaggio:='Inserimento siac_r_subdoc_movgest_ts per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
       	insert into siac_r_subdoc_movgest_ts
        (subdoc_id,
         movgest_ts_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
         login_operazione )
        values
        (subDocId,
         movGestTsId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione
         )
         returning subdoc_movgest_ts_id into scartoId;

         if scartoId is null then
			strMessaggio:=strMessaggio||' Scarto per inserimento movgest_ts.';
	        INSERT INTO migr_docquo_spesa_scarto
			(migr_docquo_spesa_id,
	    	 motivo_scarto,
			 data_creazione,
			 ente_proprietario_id
			 )values(migrDocumento.migr_docquo_spesa_id,
     	             strMessaggio,
        	         clock_timestamp(),
                     enteProprietarioId);
--	         (select migrDocumento.migr_docquo_spesa_id,
--     	             strMessaggio,
--        	         clock_timestamp(),
--                     enteProprietarioId
--			  where not exists
--                    (select 1 from migr_docquo_spesa_scarto s
--                     where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                     and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_t_subdoc          where subdoc_id=subDocId;
             continue;
        end if;

       end if;

       scartoId:=null;
       -- siac_r_subdoc_liquidazione
       if coalesce(liqId,0)!=0 then
	       strMessaggio:='Inserimento siac_r_subdoc_liquidazione per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
	       insert into siac_r_subdoc_liquidazione
           (subdoc_id,
	        liq_id,
            validita_inizio,
            ente_proprietario_id,
            data_creazione,
	        login_operazione )
           values
           (subDocId,
            liqId,
            dataInizioVal::timestamp,
            enteProprietarioId,
            clock_timestamp(),
            loginOperazione
           )
           returning subdoc_liq_id into scartoId;

           if scartoId is null then
			strMessaggio:=strMessaggio||' Scarto per inserimento liquidazione.';
            INSERT INTO migr_docquo_spesa_scarto
		    (migr_docquo_spesa_id,
    	     motivo_scarto,
		     data_creazione,
		     ente_proprietario_id
 		     )values(migrDocumento.migr_docquo_spesa_id,
     	             strMessaggio,
        	         clock_timestamp(),
                     enteProprietarioId);
--             (select migrDocumento.migr_docquo_spesa_id,
--     	             strMessaggio,
--        	         clock_timestamp(),
--                     enteProprietarioId
--			  where not exists
--                    (select 1 from migr_docquo_spesa_scarto s
--                     where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                     and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
             delete from siac_t_subdoc          where subdoc_id=subDocId;
             continue;
          end if;
       end if;

       scartoId:=null;
       -- ordinativo sara quello fittizio
       -- siac_r_subdoc_ordinativo_ts
       if coalesce(ordTsId,0)!=0 then
       		insert into siac_r_subdoc_ordinativo_ts
            (subdoc_id,
	         ord_ts_id,
             validita_inizio,
             ente_proprietario_id,
             data_creazione,
	         login_operazione )
           values
           (subDocId,
            ordTsId,
            dataInizioVal::timestamp,
            enteProprietarioId,
            clock_timestamp(),
            loginOperazione
           )
           returning subdoc_liq_id into scartoId;

       	   if scartoId is null then

       	    strMessaggio:=strMessaggio||' Scarto per inserimento ordinativo.';
            INSERT INTO migr_docquo_spesa_scarto
		    (migr_docquo_spesa_id,
    	     motivo_scarto,
		     data_creazione,
		     ente_proprietario_id
		    )values(migrDocumento.migr_docquo_spesa_id,
   	                strMessaggio,
       	            clock_timestamp(),
                    enteProprietarioId);
--            (select migrDocumento.migr_docquo_spesa_id,
--   	                strMessaggio,
--       	            clock_timestamp(),
--                    enteProprietarioId
--  		     where not exists
--                   (select 1 from migr_docquo_spesa_scarto s
--                    where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                    and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
             delete from siac_r_subdoc_liquidazione where subdoc_id=subDocId;
             delete from siac_t_subdoc          where subdoc_id=subDocId;
             continue;
          end if;
       end if;

       scartoId:=null;
       if coalesce(soggettoSedeId,0) != 0 then
        strMessaggio:='Inserimento siac_r_subdoc_sog per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
        insert into siac_r_subdoc_sog
        (subdoc_id,
	     soggetto_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
	     login_operazione)
        values
        (subDocId,
         soggettoSedeId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione)
        returning subdoc_sog_id into scartoId;

        if scartoId is null then
      	    strMessaggio:=strMessaggio||' Scarto per inserimento soggetto sede sec.';
            INSERT INTO migr_docquo_spesa_scarto
		    (migr_docquo_spesa_id,
    	     motivo_scarto,
		     data_creazione,
		     ente_proprietario_id
		    )values(migrDocumento.migr_docquo_spesa_id,
   	                strMessaggio,
       	            clock_timestamp(),
                    enteProprietarioId);
--            (select migrDocumento.migr_docquo_spesa_id,
--   	                strMessaggio,
--       	            clock_timestamp(),
--                    enteProprietarioId
--			 where not exists
--                   (select 1 from migr_docquo_spesa_scarto s
--                    where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                    and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
             delete from siac_r_subdoc_liquidazione where subdoc_id=subDocId;
             delete from  siac_r_subdoc_ordinativo_ts where subdoc_id=subDocId;
             delete from siac_t_subdoc          where subdoc_id=subDocId;
             continue;
          end if;
       end if;

       scartoId:=null;
       if coalesce(modPagId,0) != 0 then
        strMessaggio:='Inserimento siac_r_subdoc_modpag per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
        insert into siac_r_subdoc_modpag
        (subdoc_id,
	     modpag_id,
         soggrelmpag_id,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
	     login_operazione)
        values
        (subDocId,
         modPagId,
         soggRelMdpId,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione)
        returning subdoc_modpag_id into scartoId;

        if scartoId is null then
      	    strMessaggio:=strMessaggio||' Scarto per inserimento MDP.';
            INSERT INTO migr_docquo_spesa_scarto
		    (migr_docquo_spesa_id,
    	     motivo_scarto,
		     data_creazione,
		     ente_proprietario_id
		     )values(migrDocumento.migr_docquo_spesa_id,
     	             strMessaggio,
        	         clock_timestamp(),
                     enteProprietarioId);
--	         (select migrDocumento.migr_docquo_spesa_id,
--     	             strMessaggio,
--        	         clock_timestamp(),
--                     enteProprietarioId
--			  where not exists
--                    (select 1 from migr_docquo_spesa_scarto s
--                     where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                     and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
             delete from siac_r_subdoc_liquidazione where subdoc_id=subDocId;
             delete from  siac_r_subdoc_ordinativo_ts where subdoc_id=subDocId;
             delete from  siac_r_subdoc_sog where subdoc_id=subDocId;
             delete from siac_t_subdoc          where subdoc_id=subDocId;
             continue;
          end if;
       end if;

	   scartoId:=null;
       if coalesce(migrDocumento.tipo_iva_splitreverse,NVL_STR) != NVL_STR then
        strMessaggio:='Inserimento siac_r_subdoc_splitreverse_iva_tipo per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
        insert into siac_r_subdoc_splitreverse_iva_tipo
        ( subdoc_id,
          sriva_tipo_id,
          validita_inizio,
          ente_proprietario_id,
          data_creazione,
          login_operazione)
        (select
         subDocId
         , d.sriva_tipo_id
         , dataInizioVal::timestamp
         , enteProprietarioId
         , clock_timestamp()
         , loginOperazione
        from siac_d_splitreverse_iva_tipo d
        where d.ente_proprietario_id=enteProprietarioId
        and d.sriva_tipo_code=migrDocumento.tipo_iva_splitreverse
        and d.data_cancellazione is null
        and   date_trunc('day',dataelaborazione)>=date_trunc('day',d.validita_inizio)
        and  (date_trunc('day',dataelaborazione)<=date_trunc('day',d.validita_fine)
                      or d.validita_fine is null))
        returning sdcsrit_id into scartoId;

        if scartoId is null then
      	    strMessaggio:=strMessaggio||' Scarto per inserimento splitreverse_iva_tipo.';
            INSERT INTO migr_docquo_spesa_scarto
		    (migr_docquo_spesa_id,
    	     motivo_scarto,
		     data_creazione,
		     ente_proprietario_id
		     )values(migrDocumento.migr_docquo_spesa_id,
     	             strMessaggio,
        	         clock_timestamp(),
                     enteProprietarioId);
--	         (select migrDocumento.migr_docquo_spesa_id,
--     	             strMessaggio,
--        	         clock_timestamp(),
--                     enteProprietarioId
--			  where not exists
--                    (select 1 from migr_docquo_spesa_scarto s
--                     where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                     and   s.ente_proprietario_id=enteProprietarioId));

			 strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inserito.';

			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
             delete from siac_r_subdoc_liquidazione where subdoc_id=subDocId;
             delete from  siac_r_subdoc_ordinativo_ts where subdoc_id=subDocId;
             delete from  siac_r_subdoc_sog where subdoc_id=subDocId;
             delete from siac_t_subdoc          where subdoc_id=subDocId;
             delete from siac_r_subdoc_modpag where subdoc_id=subDocId;
             continue;
          end if;
       end if;



       -- siac_r_doc_attr
       -- flag_rilevante_iva
        scartoId:=null;


        strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_RIL_IVA_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
        INSERT INTO siac_r_subdoc_attr
	    (subdoc_id,
	     attr_id,
         boolean,
         validita_inizio,
         ente_proprietario_id,
         data_creazione,
	     login_operazione
        )
        values
        (subDocId,
         flagRilIvaAttrId,
         migrDocumento.flag_rilevante_iva,
         dataInizioVal::timestamp,
         enteProprietarioId,
         clock_timestamp(),
         loginOperazione)
         returning subdoc_attr_id into scartoId;


         if scartoId is not null then
          -- causale_sospensione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||CAUS_SOSP_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           causSospensioneAttrId,
           migrDocumento.causale_sospensione,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- data_sospensione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||DATA_SOSP_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           dataSospensioneAttrId,
           migrDocumento.data_sospensione,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- data_riattivazione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||DATA_RIATT_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           dataRiattivazioneAttrId,
           migrDocumento.data_riattivazione,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- -- flag_ord_singolo
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_ORD_SING_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagOrdSingoloAttrId,
           migrDocumento.flag_ord_singolo,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;



         if scartoId is not null then
          -- flag_avviso
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_AVVISO_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagAvvisoAttrId,
           migrDocumento.flag_avviso,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- flag_esproprio
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_ESPROPRIO_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagEsproprioAttrId,
           migrDocumento.flag_esproprio,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- flag_ord_manuale
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||FLAG_ORD_MANUALE_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagOrdManualeAttrId,
           migrDocumento.flag_ord_manuale,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- note
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||NOTE_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           noteAttrId,
           migrDocumento.note,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;




         if scartoId is not null then
          -- causale_ordinativo
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||CAUS_ORD_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           causaleOrdAttrId,
           migrDocumento.causale_ordinativo,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;

		 if scartoId is not null then
          -- numero_mutuo
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||NRO_MUTUO_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           numerico,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           nroMutuoAttrId,
           migrDocumento.numero_mutuo,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- annotazione_certif_crediti
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||ANNOTAZIONE_CERTIF_CRED_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           annotazioneCertifCredAttrId,
           migrDocumento.annotazione_certif_crediti,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- data_certif_crediti
          scartoId:=null;


          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||DATA_CERTIF_CRED_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           dataCertifCredAttrId,
           migrDocumento.data_certif_crediti,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;



         if scartoId is not null then
          -- note_certif_crediti
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||NOTE_CERTIF_CRED_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           noteCertifCredAttrId,
           migrDocumento.note_certif_crediti,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
          returning subdoc_attr_id into scartoId;
         end if;



		if scartoId is not null then
          -- numero_certif_crediti
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||NUMERO_CERTIF_CRED_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           numeroCertifCredAttrId,
           migrDocumento.numero_certif_crediti,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
          returning subdoc_attr_id into scartoId;
         end if;


         if scartoId is not null then
          -- flag_certif_crediti
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||FLAG_CERTIF_CRED_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           boolean,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           flagCertifCredAttrId,
           migrDocumento.flag_certif_crediti,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
          returning subdoc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- cup
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||CUP_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           cupAttrId,
           migrDocumento.cup,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
          returning subdoc_attr_id into scartoId;
         end if;

         if scartoId is not null then
          -- cig
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_doc_attr per attr. '||CIG_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           cigAttrId,
           migrDocumento.cig,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
          returning subdoc_attr_id into scartoId;
         end if;

		if scartoId is not null then
          -- dataScadenzaDopoSospensione
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_attr per attr. '||DATA_SCAD_DOPOSOSP_ATTR
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_attr
	      (subdoc_id,
	       attr_id,
           testo,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
          )
          values
          (subDocId,
           dataScadDopoSospAttrId,
           migrDocumento.data_scadenza_new,
           dataInizioVal::timestamp,
           enteProprietarioId,
           clock_timestamp(),
           loginOperazione)
           returning subdoc_attr_id into scartoId;
         end if;

         -- siac_r_doc_class
	     if   scartoId is not null
              and coalesce(migrDocumento.tipo_avviso,NVL_STR)!=NVL_STR then
          -- tipo_avviso
          scartoId:=null;

          strMessaggio:='Inserimento siac_r_subdoc_class per '||TIPO_AVVISO_CL
                       ||'='||migrDocumento.tipo_avviso
                       ||' per migr_docquo_spesa_id='||migrDocumento.migr_docquo_spesa_id||'.';
          INSERT INTO siac_r_subdoc_class
          (subdoc_id,
           classif_id,
           validita_inizio,
           ente_proprietario_id,
           data_creazione,
	       login_operazione
           )
          (select subDocId,
                  class.classif_id,
                  dataInizioVal::timestamp,
                  enteProprietarioId,
                  clock_timestamp(),
                  loginOperazione
           from siac_t_class class
           where class.classif_tipo_id=tipoAvvisoClassTipoId
           and   class.classif_code=migrDocumento.tipo_avviso
           and   class.data_cancellazione is null
           and   date_trunc('day',dataElaborazione)>=date_trunc('day',class.validita_inizio)
           and  (date_trunc('day',dataElaborazione)<=date_trunc('day',class.validita_fine)
			      or class.validita_fine is null))
          returning subdoc_classif_id into scartoId;

         end if;

         if scartoId is null then
            strMessaggio:=strMessaggio||'Controllare esistenza attributo/classificatore.';
	        INSERT INTO migr_docquo_spesa_scarto
	   	    (migr_docquo_spesa_id,
	         motivo_scarto,
		     data_creazione,
		     ente_proprietario_id
		    )values(migrDocumento.migr_docquo_spesa_id,
     	            strMessaggio,
                    clock_timestamp(),
                    enteProprietarioId);
--	        (select migrDocumento.migr_docquo_spesa_id,
--     	            strMessaggio,
--                    clock_timestamp(),
--                    enteProprietarioId
--		     where not exists
--                  (select 1 from migr_docquo_spesa_scarto s
--                   where s.migr_docquo_spesa_id=migrDocumento.migr_docquo_spesa_id
--                   and   s.ente_proprietario_id=enteProprietarioId));

             strMessaggio:=strMessaggio||' Cancellazione siac_t_subdoc, siac_r_subdoc* inseriti.';

			 delete from siac_r_subdoc_splitreverse_iva_tipo where subdoc_id=subDocId;
			 delete from siac_r_subdoc_atto_amm where subdoc_id=subDocId;
			 delete from siac_r_subdoc_movgest_ts where subdoc_id=subDocId;
             delete from siac_r_subdoc_liquidazione where subdoc_id=subDocId;
             delete from siac_r_subdoc_ordinativo_ts where subdoc_id=subDocId;
             delete from  siac_r_subdoc_sog where subdoc_id=subDocId;
             delete from  siac_r_subdoc_modpag where subdoc_id=subDocId;
             delete from siac_r_subdoc_attr     where subdoc_id=subDocId;
             delete from siac_r_subdoc_class    where subdoc_id=subDocId;
             delete from siac_t_subdoc          where subdoc_id=subDocId;

            continue;
          end if;


	   	strMessaggio:='Inserimento siac_r_migr_docquo_spesa_t_subdoc per migr_docquo_spesa_id= '
                               ||migrDocumento.migr_docquo_spesa_id||'.';
        insert into siac_r_migr_docquo_spesa_t_subdoc
        (migr_docquo_spesa_id,subdoc_id,ente_proprietario_id,data_creazione)
        values
        (migrDocumento.migr_docquo_spesa_id,subDocId,enteProprietarioId,clock_timestamp());

        numeroRecordInseriti:=numeroRecordInseriti+1;

        -- valorizzare fl_elab = 'S'
        update migr_docquo_spesa set fl_elab='S'
        where ente_proprietario_id=enteProprietarioId
        and   migr_docquo_spesa_id = migrDocumento.migr_docquo_spesa_id
        and   fl_elab='N';

	   
        -- DAVIDE - 14.12.2016 - aggiunta gestione flag convalida_manuale su liquidazione collegata
        if coalesce(liqId,0)!=0  and migrDocumento.flag_manuale='M' then
            update siac_t_liquidazione liq
		       set liq_convalida_manuale = migrDocumento.flag_manuale
             where liq.ente_proprietario_id=enteProprietarioId
			   and liq.liq_id=liqId;
        end if;
        -- DAVIDE - 14.12.2016 - Fine
    end loop;


    -- 09.02.2016 Aggiornamento del contatore siac_t_subdoc_num
    strMessaggio:='Aggiornamento contatore siac_t_subdoc_num.';
    for docIds in
      (
      select sub.doc_id, max(sub.subdoc_numero) as maxSubDocNum
      from siac_T_subdoc sub, siac_r_migr_docquo_spesa_t_subdoc rMigr
      where sub.subdoc_id = rMigr.subdoc_id
      and rMigr.migr_docquo_spesa_id  >= idMin and rMigr.migr_docquo_spesa_id <=idMax
      and sub.ente_proprietario_id = enteProprietarioId
      group by doc_id
      )loop

		UPDATE siac_t_subdoc_num
        	SET subdoc_numero = docIds.maxSubDocNum
            , login_operazione =  loginOperazione
            , data_modifica = clock_timestamp()
            WHERE doc_id = docIds.doc_id and ente_proprietario_id = enteProprietarioId;

        INSERT INTO siac_t_subdoc_num  (doc_id, subdoc_numero,validita_inizio,ente_proprietario_id,login_operazione)
        Select docIds.doc_id, docIds.maxSubDocNum, clock_timestamp(),enteProprietarioId, loginOperazione
        where not exists (select 1 from siac_t_subdoc_num where doc_id = docIds.doc_id and ente_proprietario_id = enteProprietarioId);

      end loop;

    RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||'. Inserite '||numeroRecordInseriti||' quote documenti di spesa.';
    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
    when TOO_MANY_ROWS THEN
        raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||' Diverse righe presenti in archivio.';
        numerorecordinseriti:=-1;
        return;
	when others  THEN
		raise notice '% % ERRORE DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||quote_nullable(strMessaggio)||'ERRORE DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        numerorecordinseriti:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;