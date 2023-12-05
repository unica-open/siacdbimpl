/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION fnc_inizializza_contatori_iva(enteProprietarioId integer,
                                                    annobilancio varchar,
                                                    loginOperazione varchar,
                                                    dataElaborazione timestamp,
                                                   -- idMin integer,
                                                  --  idMax integer,
                                                    out numeroRecordInseriti integer,
                                                    out messaggioRisultato varchar)
RETURNS record AS
$body$
DECLARE

 strNTrim VARCHAR(1):='1';
 strMessaggio VARCHAR(2500):='';
 strMessaggioFinale VARCHAR(2500):='';
 strMessaggioScarto VARCHAR(1500):='';
 countMigrDoc integer := 0;

 migrDocumento record;
 contatoreProv record;
 dataInizioVal timestamp :=null;

 docId      integer:=null;

 NVL_STR CONSTANT varchar :='';
/*
 FLAG_REGISTRAZIONE_IVA_ATTR  CONSTANT varchar := 'flagRegistrazioneIva';
 FLAG_INTRACOMUNITARIO_ATTR   CONSTANT varchar := 'flagIntracomunitario';
 FLAG_RILEVANTE_IRAP_ATTR 	  CONSTANT varchar := 'flagRilevanteIRAP';
 FLAG_NOTA_CREDITO_ATTR       CONSTANT varchar := 'flagNotaCredito';
 FLAG_RILEVANTE_IVA_ATTR 	  CONSTANT varchar := 'flagRilevanteIVA';

 flagRegistrazioneIvaAttrId integer:=null;
 flagIntracomunitarioAttrId integer:=null;
 flagRilevanteIrapAttrId	integer:=null;
 flagNotaCreditoAttrId		integer:=null;
 flagRilevanteIvaAttrId     integer:=null;
*/
 v_subdociva_numero integer:=null; -- contatore per subdoc_iva

 ivaregid	 integer := null;
 regtipoid	 integer := null;
 docivarid   integer := null;
 subdocivaid integer := null;
 scartoId    integer := null;
 maxsubdocivanumero integer := null;
 count_subdocivanum integer := null;

 affected_rows numeric := 0;

 periodoId   integer := 0;
 count_subdocivaprotprovnum integer := null;
 maxdatachar varchar:='';

BEGIN

	numeroRecordInseriti:=0;
    messaggioRisultato:='';
    dataInizioVal:=date_trunc('DAY', now());
    strMessaggioFinale:='Inizializza contatori iva.';
    -- update del contatore.
    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_num per anno '||annobilancio||'.';
    select i.subdociva_numero into maxsubdocivanumero
    from siac_t_subdoc_iva i
    where i.ente_proprietario_id=enteproprietarioid
    and i.subdociva_anno = annoBilancio
    order by i.subdociva_numero desc limit 1;
	raise notice 'strMessaggio 1%',strMessaggio;

    if maxsubdocivanumero is not null and maxsubdocivanumero > 0 then
       	raise notice 'strMessaggio 2 %',strMessaggio;

		select coalesce (count(*),0) into count_subdocivanum from  siac_t_subdoc_iva_num
        where ente_proprietario_id = enteProprietarioId and subdociva_anno = annobilancio::integer and data_cancellazione is null;
        if count_subdocivanum = 0 then
		    strMessaggio := 'Inserimento del contatore siac_t_subdoc_iva_num per anno '||annobilancio||',numero '||maxsubdocivanumero||'.';
       	raise notice 'strMessaggio 2 a %',strMessaggio;
            insert into siac_t_subdoc_iva_num
            (subdociva_anno,subdociva_numero,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
            values
            (annobilancio::integer, maxsubdocivanumero,dataInizioVal::timestamp,enteproprietarioid,clock_timestamp(),loginOperazione);
        else
		    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_num per anno '||annobilancio||',numero '||maxsubdocivanumero||'.';
       	raise notice 'strMessaggio 2 b %',strMessaggio;
            update siac_t_subdoc_iva_num
            set subdociva_numero = maxsubdocivanumero
            ,data_modifica = clock_timestamp()
            where subdociva_anno = annobilancio::integer
            and ente_proprietario_id = enteproprietarioid;
        end if;
    end if;

    -- update del contatore siac_t_subdoc_iva_prot_prov_num

    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_prot_prov_num.';
           	raise notice 'strMessaggio 3 %',strMessaggio;
    for contatoreProv in
    (
    	select subdoc.*,  reg.ivareg_code,reg.ivareg_desc, ct.ivachi_tipo_code, ct.ivachi_tipo_desc
		 from
          siac_t_iva_registro reg,siac_r_iva_registro_gruppo ig, siac_r_iva_gruppo_chiusura gc, siac_d_iva_chiusura_tipo ct,
            (select iva.ivareg_id, max(subdociva_data_prot_prov) maxData, max(iva.subdociva_prot_prov::numeric) maxNum
            from siac_t_subdoc_iva iva
            where ente_proprietario_id = enteproprietarioid
            and fnc_migr_isnumeric(iva.subdociva_prot_prov)
            group by ivareg_id)subdoc
          where reg.ivareg_id = ig.ivareg_id
          and   ig.ivagru_id=gc.ivagru_id
          and   gc.ivachi_tipo_id=ct.ivachi_tipo_id
          and   subdoc.ivareg_id=reg.ivareg_id
     order by    subdoc.maxdata,subdoc.maxnum  )

    loop
    	strMessaggio := 'Inizio Aggiornamento del contatore siac_t_subdoc_iva_prot_prov_num per ivareg_id '|| contatoreProv.ivareg_id
        || ', data '||quote_nullable(contatoreProv.maxData)
        || ', num '||coalesce(contatoreProv.maxNum,0)
        || ', maxdatachar '|| maxdatachar ||'.';


       	raise notice 'strMessaggio 4 %',strMessaggio;
        -- 30.05.2016 Sofia - modifica effettuata per il caricamento dei documenti di Alessandria
        if contatoreProv.maxData is null then
         continue;
        end if;

        maxdatachar := to_char (contatoreProv.maxData,'dd/mm/yyyy');

        if contatoreProv.ivachi_tipo_code = 'M' then
          select p.periodo_id into strict periodoId
          from siac_t_periodo p where
              p.ente_proprietario_id = enteproprietarioid

              and p.periodo_code = split_part(maxdatachar,'/',2)||split_part(maxdatachar,'/',3);

              --and p.periodo_code = '01'||split_part(maxdatachar,'/',3);
        end if;

        if contatoreProv.ivachi_tipo_code = 'A' then
          select p.periodo_id into strict periodoId
          from siac_t_periodo p where
              p.ente_proprietario_id = enteproprietarioid
              and p.periodo_code = 'anno'||split_part(maxdatachar,'/',3);
        end if;

        if contatoreProv.ivachi_tipo_code = 'T' then

        select p.periodo_id into strict periodoId
          from siac_t_periodo p where
              p.ente_proprietario_id = enteproprietarioid
              and p.periodo_code = 'trim'
                  || case split_part(maxdatachar,'/',2)
                      when '01' then '1'
                      when '02' then '1'
                      when '03' then '1'
                      when '04' then '2'
                      when '05' then '2'
                      when '06' then '2'
                      when '07' then '3'
                      when '08' then '3'
                      when '09' then '3'
                      when '10' then '4'
                      when '11' then '4'
                      when '12' then '4'
                      else '' end || split_part(maxdatachar,'/',3);
                  --and p.periodo_code = 'trim1'|| split_part(maxdatachar,'/',3);
        end if;

		select coalesce (count(*),0) into count_subdocivaprotprovnum from  siac_t_subdoc_iva_prot_prov_num n
        where ente_proprietario_id = enteProprietarioId and n.ivareg_id = contatoreProv.ivareg_id and n.periodo_id = periodoId
        and data_cancellazione is null;
        if count_subdocivaprotprovnum = 0 then
		    strMessaggio := 'Inserimento del contatore siac_t_subdoc_iva_prot_prov_num per ivareg_id '||contatoreProv.ivareg_id||',periodo '||periodoId
            ||',data '||contatoreProv.maxData
            ||',periodo '||contatoreProv.maxNum||'.';
            insert into siac_t_subdoc_iva_prot_prov_num
			(ivareg_id,periodo_id,subdociva_data_prot_prov,subdociva_prot_prov,validita_inizio,ente_proprietario_id,data_creazione,login_operazione)
            values
            (contatoreProv.ivareg_id, periodoId,contatoreProv.maxData,contatoreProv.maxNum::integer,dataInizioVal::timestamp,enteproprietarioid,clock_timestamp(),loginOperazione);
        else
		    strMessaggio := 'Aggiornamento del contatore siac_t_subdoc_iva_prot_prov_num per ivareg_id '||contatoreProv.ivareg_id||',periodo '||periodoId
            ||',data '||contatoreProv.maxData
            ||',periodo '||contatoreProv.maxNum||'.';
            update siac_t_subdoc_iva_prot_prov_num
            set subdociva_data_prot_prov = contatoreProv.maxData
            ,subdociva_prot_prov = contatoreProv.maxNum::integer
            ,data_modifica = clock_timestamp()
            where ivareg_id = contatoreProv.ivareg_id
            and periodo_id = periodoId
            and ente_proprietario_id = enteproprietarioid;
        end if;
    end loop;

    RAISE NOTICE 'numeroRecordInseriti %', numeroRecordInseriti;
    messaggioRisultato:=strMessaggioFinale||' Inseriti '||numeroRecordInseriti||' quote documenti iva.';
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