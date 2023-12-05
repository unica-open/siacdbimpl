/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿/*drop function  fnc_mif_ordinativo_spesa_predisponi_invio_email
( enteProprietarioId integer,
  annoBilancio integer,
  nomeEnte VARCHAR,
  tipoFlussoMif varchar,
  flussoElabMifId integer,
  ordinativoId    integer,
  ricevutaId      integer,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out flussoElabMifRetId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar);*/

CREATE OR REPLACE FUNCTION fnc_mif_ordinativo_spesa_predisponi_invio_email
( enteProprietarioId integer,
  annoBilancio integer,
  nomeEnte VARCHAR,
  tipoFlussoMif varchar,
  flussoElabMifId integer,
  flussoElabQuietMifId integer,
  ordinativoId    integer,
  ricevutaId      integer,
  ordDataQuiet    timestamp,
  loginOperazione varchar,
  dataElaborazione timestamp,
  out flussoElabMifRetId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE
    strMessaggio VARCHAR(1500):='';
    strMessaggioFinale VARCHAR(1500):='';

    flussoMifTipoId         integer:=null;
    nomeFileMif             varchar(50):=null;
    flussoElabMifNewId      integer:=null;
    oilRicevutaId           integer:=null;
    codResult               integer :=null;
    email_soggetto          varchar(500):=null;
    ordAnno                 integer:=null;
    ordNumero               numeric:=null;
    ordDescr                varchar(1500):=null;
    ordImporto              numeric:=null;
    soggettoId              integer :=null;
    modpagId                integer :=null;
    soggettoRelazId         integer:=null;
    accreditoTipoId         integer :=null;
    nRighe                  integer:=null;
    accreditoTipoCode       varchar(500):=null;
    accreditoTipoDesc       varchar(500):=null;
    codiceIban              varchar(100):=null;
    oggettoMail             varchar(2000):=null;
    testoMail               text:=null;
    mittenteMail            varchar(250):=null;
	ordImportoStr           varchar(250):=null;
    fattImportoStr          varchar(250):=null;
    sogDesc                 varchar(250):=null;
    strFatt                 varchar(250):=null;
    accreditoGruppoCode     varchar(250):=null;

    paramMail               record;
    fattRec                 record;

    EMAIL_SOGGETTO_TIPO     CONSTANT  varchar :='email';
    ELAB_MIF_ESITO_IN       CONSTANT  varchar :='IN';

    -- costante tipo flusso presenti nella mif_d_flusso_elaborato_tipo
    -- valori di parametro tipoFlussoMif devono essere presenti in mif_d_flusso_elaborato_tipo
    INVIO_AVVISO_EMAIL_BONIF_TIPO   CONSTANT  varchar :='INVIO_AVVISO_EMAIL_BONIF';    -- invii avvisi per quietanzamento

    OGGETTO_MAIL_TIPO               CONSTANT  varchar :='Oggetto_Email_Bonif';
    TESTO_MAIL_TIPO                 CONSTANT  varchar :='Testo_Email_Bonif';
    FATTURE_TESTO_MAIL_TIPO         CONSTANT  varchar :='Fatture_Testo_Email_Bonif';

    ENTE_OGGETTO_EMAIL_BONIF         CONSTANT  varchar :='Ente_Oggetto_Email_Bonif';
    AVVISO_OGGETTO_EMAIL_BONIF       CONSTANT  varchar :='Avviso_Oggetto_Email_Bonif';
    MITTENTE_MAIL_TIPO               CONSTANT  varchar :='Mittente_Testo_Email_Bonif';
    IMPORTO_TESTO_EMAIL_BONIF        CONSTANT  varchar :='Importo_Testo_Email_Bonif';
    CAUSALE_TESTO_EMAIL_BONIF        CONSTANT  varchar :='Causale_Testo_Email_Bonif';
    MODPAG_TESTO_EMAIL_BONIF         CONSTANT  varchar :='ModPag_Testo_Email_Bonif';
    IBAN_TESTO_EMAIL_QUIET_BONIF     CONSTANT  varchar :='Iban_Testo_Email_Quiet_Bonif';
    NOTA_TESTO_EMAIL_BONIF           CONSTANT  varchar :='Nota_Testo_Email_Bonif';
    ENTE_CODA_TESTO_EMAIL_BONIF      CONSTANT  varchar :='Ente_Coda_Testo_Email_Bonif';
    SEDE_ENTE_CODA_TESTO_EMAIL_BONIF CONSTANT  varchar :='Sede_Ente_Coda_Testo_Email_Bonif';
    TEL_ENTE_CODA_TESTO_EMAIL_BONIF  CONSTANT  varchar :='Tel_Ente_Coda_Testo_Email_Bonif';
    CODFISC_ENTE_CODA_TESTO_EMAIL_BONIF CONSTANT varchar:='Codfisc_Ente_Coda_Testo_Email_Bonif';


    ACCREDITO_GRUPPO_CODE_CB        CONSTANT  varchar :='CB';
    MAX_LENGTH                      CONSTANT  integer:=130;

	dataInizioVal timestamp;

BEGIN
    strMessaggioFinale:='Elaborazione predisposizione dati per invio email '||tipoFlussoMif
    					||'. Inserimento dati per ordinativo ord_id='||ordinativoId||' [mif_t_oil_ricevuta_invio_email].';

    flussoElabMifRetId:=null;
    codiceRisultato:=0;
    messaggioRisultato:='';

	dataInizioVal:=clock_timestamp();

    strMessaggio:='Lettura identificativo tipo flusso.';
    select tipo.flusso_elab_mif_tipo_id, tipo.flusso_elab_mif_nome_file
	into flussoMifTipoId, nomeFileMif
    from mif_d_flusso_elaborato_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
      and tipo.flusso_elab_mif_tipo_code=tipoFlussoMif
      and tipo.data_cancellazione is null
      and tipo.validita_fine is null;
	if flussoMifTipoId is null then
    	raise exception ' Errore in lettura.';
    end if;

/*  Sofia spostato sotto
    strMessaggio:='Lettura identificativo tipo flusso.';
    if flussoElabMifId is null then
        -- se non ne esistono altre in corso
        -- inserisci mif_t_flusso_elaborato per tipoFlussoMif in corso
        flussoElabMifNewId:=null;

        strMessaggio:='Inserimento mif_t_flusso_elaborato per '||tipoFlussoMif||'.';

        insert into mif_t_flusso_elaborato
        (flusso_elab_mif_data ,
         flusso_elab_mif_esito,
         flusso_elab_mif_esito_msg,
         flusso_elab_mif_file_nome,
         flusso_elab_mif_tipo_id,
         flusso_elab_mif_quiet_id,
         validita_inizio,
         ente_proprietario_id,
         login_operazione
        )
        values
        (dataElaborazione,
         ELAB_MIF_ESITO_IN,
         'Elaborazione in corso per '||tipoFlussoMif||'.',
         nomeFileMif,
         flussoMifTipoId,
         flussoElabQuietMifId,
         dataElaborazione,
         enteProprietarioId,
         loginOperazione
        )
        returning flusso_elab_mif_id into flussoElabMifNewId; -- valore da restituire

        if flussoElabMifNewId is null then
            raise exception ' Inserimento non effettuato.';
        end if;
    else
        -- controlla esistenza , deve esistere in mif_t_flusso_elaborato per tipoFlussoMif in corso
        strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_flusso_elaborato].';
        select distinct 1 into codResult
          from mif_t_flusso_elaborato mif
         where mif.flusso_elab_mif_id=flussoElabMifId
           and mif.flusso_elab_mif_tipo_id=flussoMifTipoId
           and mif.data_cancellazione is null
           and mif.validita_fine is null
           and mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN;


        if codResult is null then
        	raise exception ' Elaborazione non esistente per identificativo=%.',flussoElabMifId;
        else
            -- utilizza   flussoElabMifId
            flussoElabMifNewId:=flussoElabMifId;
        end if;
    end if;
*/
    strMessaggio:='Lettura estremi MDP [siac_r_ordinativo_modpag].';
    select rmdp.modpag_id, rmdp.soggetto_relaz_id
    into   modpagId, soggettoRelazId
    from siac_r_ordinativo_modpag rmdp
    where rmdp.ord_id=ordinativoId
    and   rmdp.data_cancellazione is null
    and   rmdp.validita_fine is null;

    if modpagId is null and  soggettoRelazId  is null then
    	raise exception ' Errore in lettura.';
    end if;

    strMessaggio:='Lettura estremi MDP [siac_r_soggrel_modpag].';
    if soggettoRelazId is not null then
  	 	select rel.modpag_id into modPagId
        from siac_r_soggrel_modpag rel
        where rel.soggetto_relaz_id=soggettoRelazId
        and   rel.data_cancellazione is null
        and   rel.validita_fine is null
        limit 1;

    end if;
    if modpagId is null then
    	raise exception ' Errore in lettura.';
    end if;

    strMessaggio:='Lettura estremi soggetto e accredito.';
	select gruppo.accredito_gruppo_code,
           mdp.soggetto_id,
           tipo.accredito_tipo_id,
           tipo.accredito_tipo_code,
           tipo.accredito_tipo_desc,
           mdp.iban
    into   accreditoGruppoCode,
           soggettoId,
           accreditoTipoId,
           accreditoTipoCode,
           accreditoTipoDesc,
           codiceIban
    from siac_t_modpag mdp, siac_d_accredito_tipo tipo, siac_d_accredito_gruppo gruppo
    where mdp.modpag_id=modpagId
    and   tipo.accredito_tipo_id=mdp.accredito_tipo_id
    and   gruppo.accredito_gruppo_id=tipo.accredito_gruppo_id
  --  and   gruppo.accredito_gruppo_code=ACCREDITO_GRUPPO_CODE_CB
    and   mdp.data_cancellazione is null
    and   mdp.validita_fine is null;

    raise notice 'accreditoGruppoCode=%',accreditoGruppoCode;
    if accreditoGruppoCode is null or
       accreditoGruppoCode!=ACCREDITO_GRUPPO_CODE_CB then
       	messaggioRisultato:=strMessaggioFinale||' Tipo accredito='||accreditoGruppoCode||'.';
        codiceRisultato:=0;
        return;
    end if;


    if soggettoId is null or
       accreditoTipoId is null or
       accreditoTipoCode is null or
       accreditoTipoDesc is null or
       codiceIban is null then
		raise exception ' Errore in reperimento tipo accredito e IBAN.';
    end if;

    strMessaggio:='Lettura estremi indirizzo email [siac_t_recapito_soggetto].';
    select recMail.recapito_desc  into email_soggetto
    from siac_t_recapito_soggetto recMail
    where recMail.soggetto_id=soggettoId
      and recMail.recapito_code=EMAIL_SOGGETTO_TIPO
      and recMail.data_cancellazione is null
      and recMail.validita_fine is null
    limit 1;

    raise notice 'email_soggetto=%', email_soggetto;
    if email_soggetto is not null then
	    email_soggetto:='sofia.sterchele@csi.it';
--        email_soggetto:=null;
    end if;

    if email_soggetto is null  then
    	messaggioRisultato:=strMessaggioFinale||' Email del soggetto non valorizzata. Email non inviabile.';
        codiceRisultato:=0;
        return;
    end if;




    -- ricavo i dati dell'ordinativo
    strMessaggio:='Lettura estremi ordinativo.';
    select ord.ord_anno, ord.ord_numero, ord.ord_desc, det.ord_ts_det_importo
    into ordAnno, ordNumero, ordDescr, ordImporto
    from siac_t_ordinativo ord, siac_t_ordinativo_ts tsord,
         siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipo
    where ord.ord_id=ordinativoId
    and   tsord.ord_id=ord.ord_id
    and   det.ord_ts_id=tsord.ord_ts_id
    and   tipo.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
    and   tipo.ord_ts_det_tipo_code='A'
    and   ord.data_cancellazione is null
    and   ord.validita_fine is null
    and   tsord.data_cancellazione is null
    and   tsord.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null;

    if ordAnno is null or
       ordNumero is null or
       ordDescr is null or
       ordImporto is null  then
       raise exception ' Errore in lettura dati.';
    end if;

	raise notice 'ordImporto=%',ordImporto*100;
	ordImportoStr:=
    (
    substring(replace(to_char(ordImporto*100::numeric,'9G999G999G999G999,99'),',','.')
	          from 1 for length(replace(to_char(ordImporto*100::numeric,'9G999G999G999G999,99'),',','.')) -3)
	||','||
	substring(replace(to_char(ordImporto*100::numeric,'9G999G999G999G999,99'),',','.')
              from length(replace(to_char(ordImporto*100::numeric,'9G999G999G999G999,99'),',','.')) - 1  for 2)
    )::text;

	raise notice 'ordImportoStr=%',ordImportoStr;

    -- Trova i dati per il campo text ( testo della mail ) e l'oggetto
    -- per il campo text usare la seguente query
    -- usare mif_d_flusso_elaborato per tipo = tipoFlussoMif
    strMessaggio:='Lettura estremi ordinativo.';

    for paramMail IN
    (select mif.flusso_elab_mif_code,
            --mif.flusso_elab_mif_desc,
            mif.flusso_elab_mif_code_padre,
           -- mif.flusso_elab_mif_ordine,
           -- mif.flusso_elab_mif_ordine_elab,
          --  mif.flusso_elab_mif_elab,
          --  mif.flusso_elab_mif_attivo,
           -- mif.flusso_elab_mif_xml_out,
           -- concat(mif.flusso_elab_mif_default,mif.flusso_elab_mif_param) as valore
           mif.flusso_elab_mif_default valore
      from mif_d_flusso_elaborato_tipo tipo, mif_d_flusso_elaborato mif
     where tipo.ente_proprietario_id=enteProprietarioId
       and tipo.flusso_elab_mif_tipo_code=INVIO_AVVISO_EMAIL_BONIF_TIPO
       and mif.flusso_elab_mif_tipo_id=tipo.flusso_elab_mif_tipo_id
       and mif.flusso_elab_mif_attivo=true
       order by mif.flusso_elab_mif_ordine
    )
    loop
		if
          paramMail.flusso_elab_mif_code = ENTE_OGGETTO_EMAIL_BONIF then
         	oggettoMail:= paramMail.valore;
        elsif paramMail.flusso_elab_mif_code = AVVISO_OGGETTO_EMAIL_BONIF then
	        oggettoMail:=oggettoMail||' '||paramMail.valore||' '||ordAnno::varchar||'/'||ordNumero::varchar;
		elsif paramMail.flusso_elab_mif_code = MITTENTE_MAIL_TIPO then
            mittenteMail := paramMail.valore;
        elseif paramMail.flusso_elab_mif_code = IMPORTO_TESTO_EMAIL_BONIF then
            testoMail:=paramMail.valore::text||' '||ordImportoStr||' Euro'||chr(13)||chr(13);
        elseif paramMail.flusso_elab_mif_code = CAUSALE_TESTO_EMAIL_BONIF then
            if length(ordDescr)<MAX_LENGTH then
            	testoMail:=testoMail||paramMail.valore::text||' '||ordDescr::text||chr(13)||chr(13);
            else
                nRighe:=0;
                testoMail:=testoMail||paramMail.valore::text||chr(13);
                loop
                	testoMail:=testoMail||
                               substring(ordDescr from (MAX_LENGTH*nRighe)+1 for MAX_LENGTH)::text||chr(13);
                    exit when MAX_LENGTH*(nRighe+1)>length(ordDescr);
                    nRighe:=nRighe+1;
                end loop;
				testoMail:=testoMail||chr(13);
            end if;
        elseif paramMail.flusso_elab_mif_code = MODPAG_TESTO_EMAIL_BONIF then
            testoMail:=testoMail||paramMail.valore::text||' '||accreditoTipoDesc::text||chr(13)||chr(13);
        elseif paramMail.flusso_elab_mif_code = IBAN_TESTO_EMAIL_QUIET_BONIF then
            testoMail:=testoMail||paramMail.valore::text||' '||codiceIban::text||chr(13)||chr(13);
        elseif paramMail.flusso_elab_mif_code = NOTA_TESTO_EMAIL_BONIF then
            testoMail:=testoMail||paramMail.valore::text||chr(13)||chr(13);
        elseif paramMail.flusso_elab_mif_code = ENTE_CODA_TESTO_EMAIL_BONIF then
            testoMail:=testoMail||paramMail.valore::text||chr(13);
        elseif paramMail.flusso_elab_mif_code = SEDE_ENTE_CODA_TESTO_EMAIL_BONIF then
            testoMail:=testoMail||paramMail.valore::text||chr(13);
        elseif paramMail.flusso_elab_mif_code = TEL_ENTE_CODA_TESTO_EMAIL_BONIF then
            testoMail:=testoMail||paramMail.valore::text||chr(13);
        elseif paramMail.flusso_elab_mif_code = CODFISC_ENTE_CODA_TESTO_EMAIL_BONIF then
            testoMail:=testoMail||paramMail.valore::text||chr(13)||chr(13)||chr(13);
        elseif paramMail.flusso_elab_mif_code =  FATTURE_TESTO_MAIL_TIPO THEN
            -- ero qui qui
            -- verifica esistenza fatture
            strMessaggio:=strMessaggio||'Verifica esistenza documenti collegati.';
            codResult:=null;
            select 1 into codResult
            from siac_t_ordinativo_ts ts,
                 siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato,
                 siac_r_subdoc_ordinativo_ts rts, siac_t_subdoc sub, siac_t_doc doc,
                 siac_r_doc_stato rdoc, siac_d_doc_stato statodoc
            where ts.ord_id=ordinativoId
            and   rts.ord_ts_id=ts.ord_ts_id
            and   r.ord_id=ts.ord_id
            and   stato.ord_stato_id=r.ord_stato_id
            and   stato.ord_stato_code!='A'
            and   sub.subdoc_id=rts.subdoc_id
            and   doc.doc_id=sub.doc_id
            and   rdoc.doc_id=doc.doc_id
            and   statodoc.doc_stato_id=rdoc.doc_stato_id
            and   statodoc.doc_stato_code!='A'
            and   rts.data_cancellazione is null
            and   rts.validita_fine is null
            and   ts.data_cancellazione is null
            and   ts.validita_fine is null
            and   r.data_cancellazione is null
            and   r.validita_fine is null
            and   sub.data_cancellazione is null
            and   sub.validita_fine is null
            and   doc.data_cancellazione is null
            and   doc.validita_fine is null
            and   rdoc.data_cancellazione is null
            and   rdoc.validita_fine is null
            limit 1;

            if codResult is not null then
             strMessaggio:='Lettura estremi ordinativo.Lettura documenti collegati.';
             testoMail:=testoMail||paramMail.valore::text||chr(13)||chr(13);

             for fattRec in
             (select tipo.doc_tipo_code tipoDoc,
                     doc.doc_anno annoDoc,
                     doc.doc_numero numeroDoc,
                     to_char(doc.doc_data_emissione,'dd/mm/yyyy') dataEmissioneDoc,
                     sub.subdoc_importo importoDoc,
                     rsog.soggetto_id soggettoIdDoc
              from siac_t_ordinativo_ts ts,
                   siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato,
                   siac_r_subdoc_ordinativo_ts rts, siac_t_subdoc sub, siac_t_doc doc,
                   siac_r_doc_stato rdoc, siac_d_doc_stato statodoc,
                   siac_d_doc_tipo tipo,
                   siac_r_doc_sog rsog
             where ts.ord_id=ordinativoId
             and   rts.ord_ts_id=ts.ord_ts_id
             and   r.ord_id=ts.ord_id
             and   stato.ord_stato_id=r.ord_stato_id
             and   stato.ord_stato_code!='A'
             and   sub.subdoc_id=rts.subdoc_id
             and   doc.doc_id=sub.doc_id
             and   rdoc.doc_id=doc.doc_id
             and   statodoc.doc_stato_id=rdoc.doc_stato_id
             and   statodoc.doc_stato_code!='A'
             and   tipo.doc_tipo_id=doc.doc_tipo_id
             and   rsog.doc_id=doc.doc_id
             and   rts.data_cancellazione is null
             and   rts.validita_fine is null
             and   ts.data_cancellazione is null
             and   ts.validita_fine is null
             and   r.data_cancellazione is null
             and   r.validita_fine is null
             and   sub.data_cancellazione is null
             and   sub.validita_fine is null
             and   doc.data_cancellazione is null
             and   doc.validita_fine is null
             and   rdoc.data_cancellazione is null
             and   rdoc.validita_fine is null
             and   rsog.data_cancellazione is null
             and   rsog.validita_fine is null
             order by 2,1,3
             )
             loop
             	sogDesc:=null;
             	if fattRec.soggettoIdDoc!=soggettoId then
                	select sog.soggetto_desc into sogDesc
                    from siac_t_soggetto sog
                    where sog.soggetto_id=fattRec.soggettoIdDoc
                    and   sog.data_cancellazione is null
                    and   sog.validita_fine is null;
                end if;

                fattImportoStr:=
    			(
    				substring(replace(to_char(fattRec.importoDoc*100::numeric,'9G999G999G999G999,99'),',','.')
	          		          from 1 for length(replace(to_char(fattRec.importoDoc*100::numeric,'9G999G999G999G999,99'),',','.')) -3)
					||','||
					substring(replace(to_char(fattRec.importoDoc*100::numeric,'9G999G999G999G999,99'),',','.')
              		          from length(replace(to_char(fattRec.importoDoc*100::numeric,'9G999G999G999G999,99'),',','.')) - 1  for 2)
                );
				raise notice 'fattRec.dataEmissioneDoc=%',fattRec.dataEmissioneDoc;
                strFatt:=fattRec.tipoDoc||' '||
                         fattRec.annoDoc||' '||
                         fattRec.numeroDoc||' '||
                         fattRec.dataEmissioneDoc||' '||
                         fattImportoStr||' Euro ';
                if sogDesc is not null then
                 strFatt:=strFatt||substring(sogDesc from 1 for 50);
                end if;

                testoMail:=testoMail||strFatt::text||chr(13);

             end loop;
            end if;

            if strFatt is not null then
            	testoMail:=testoMail||chr(13)||chr(13);
            end if;

        end if;

    end loop;


    ---- Sofia sposto qui inserimento elaborazione prima potrebbe inserire elaborazione
    ---- senza inserire record
    strMessaggio:='Lettura identificativo tipo flusso.';
    if flussoElabMifId is null then
        -- se non ne esistono altre in corso
        -- inserisci mif_t_flusso_elaborato per tipoFlussoMif in corso
        flussoElabMifNewId:=null;

        strMessaggio:='Inserimento mif_t_flusso_elaborato per '||tipoFlussoMif||'.';

        insert into mif_t_flusso_elaborato
        (flusso_elab_mif_data ,
         flusso_elab_mif_esito,
         flusso_elab_mif_esito_msg,
         flusso_elab_mif_file_nome,
         flusso_elab_mif_tipo_id,
         flusso_elab_mif_quiet_id,
         validita_inizio,
         ente_proprietario_id,
         login_operazione
        )
        values
        (dataElaborazione,
         ELAB_MIF_ESITO_IN,
         'Elaborazione in corso per '||tipoFlussoMif||'.',
         nomeFileMif,
         flussoMifTipoId,
         flussoElabQuietMifId,
         dataElaborazione,
         enteProprietarioId,
         loginOperazione
        )
        returning flusso_elab_mif_id into flussoElabMifNewId; -- valore da restituire

        if flussoElabMifNewId is null then
            raise exception ' Inserimento non effettuato.';
        end if;
    else
        -- controlla esistenza , deve esistere in mif_t_flusso_elaborato per tipoFlussoMif in corso
        strMessaggio:='Verifica esistenza elaborazioni precedenti in sospeso [mif_t_flusso_elaborato].';
        select distinct 1 into codResult
          from mif_t_flusso_elaborato mif
         where mif.flusso_elab_mif_id=flussoElabMifId
           and mif.flusso_elab_mif_tipo_id=flussoMifTipoId
           and mif.data_cancellazione is null
           and mif.validita_fine is null
           and mif.flusso_elab_mif_esito=ELAB_MIF_ESITO_IN;


        if codResult is null then
        	raise exception ' Elaborazione non esistente per identificativo=%.',flussoElabMifId;
        else
            -- utilizza   flussoElabMifId
            flussoElabMifNewId:=flussoElabMifId;
        end if;
    end if;


	strMessaggio:='Inserimento dati predisposizione invio email [mif_t_oil_ricevuta_invio_email].';
    -- insert sulla mif_t_oil_ricevuta_invio_email
    INSERT INTO mif_t_oil_ricevuta_invio_email
    (
        flusso_elab_mif_id,
        flusso_elab_mif_quiet_id,
        oil_ricevuta_id,
        oil_ricevuta_data,
        ord_id,
        ord_anno,
        ord_numero,
        ord_importo,
        ord_desc,
        soggetto_id,
        modpag_id,
        accredito_tipo_id,
        accredito_tipo_code,
        accredito_tipo_desc,
        codice_iban,
        codice_email,
        oggetto_email,
        testo_email,
        validita_inizio,
        ente_proprietario_id,
        data_creazione,
        login_operazione,
        mittente_email
    )
    VALUES
    (   flussoElabMifNewId,
    	flussoElabQuietMifId,
        ricevutaId,
        ordDataQuiet,
        ordinativoId,
        ordAnno,
        ordNumero,
        ordImporto,
        ordDescr,
        soggettoId,
        modpagId,
        accreditoTipoId,
        accreditoTipoCode,
        accreditoTipoDesc,
        codiceIban,
        email_soggetto,
        oggettoMail,
        testoMail,
        dataInizioVal,
        enteProprietarioId,
        dataElaborazione,
        loginOperazione,
        mittenteMail
    )
    returning oil_ricevuta_email_id into oilRicevutaId; -- valore da restituire

    if oilRicevutaId is null then
        raise exception ' Errore in fase di inserimento.';
    end if;

    flussoElabMifRetId:=flussoElabMifNewId;
    messaggioRisultato:=upper(strMessaggioFinale||' Predisposizione email OK.');
    return;

exception
    when RAISE_EXCEPTION THEN
         messaggioRisultato:=
            coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
         codiceRisultato:=-1;

        messaggioRisultato:=upper(messaggioRisultato);
        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
    when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);

        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;