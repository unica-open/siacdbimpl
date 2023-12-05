/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
REATE OR REPLACE FUNCTION fnc_mif_ordinativo_quote(    ordinativoId integer,
														ordinativoTsDetTipoId integer,
														movgestTsTipoSubId integer,
                                                        classCdrTipoId integer,
                                                        classCdcTipoId integer,
                                                        enteProprietarioId integer,
                                                        dataElaborazione timestamp,
                                                        dataFineVal timestamp)
RETURNS table
(
    ordTsId     integer,
    numeroQuota varchar(50),
    descriQuota VARCHAR(500),
    dataScadenzaQuota varchar(20),
    importoQuota varchar(100),
    documentoCollQuota varchar(250),
    movgestQuota varchar(50),
    movgestDescriQuota varchar(500),
    movgestAttoAmmQuota varchar(100)
) AS
$body$
DECLARE

strMessaggio varchar(1500):=null;

ordinativoTsRec record;
annoMovGest varchar(10):=null;
numeroMovGest varchar(100):=null;
descMovGest varchar(500):=null;
numeroSubMovGest varchar(10):=null;
descSubMovGest varchar(500):=null;
annoAttoAmm varchar(10):=null;
numeroAttoAmm varchar(100):=null;
oggettoAttoAmm varchar(500):=null;
tipoAttoAmm varchar(20):=null;
documentoColl varchar(100):=null;
movGestTsTipoId integer :=null;
movGestId integer:=null;

sacAttoAmm varchar(50):=null;
attoAmmId integer :=null;

BEGIN

 ordTsId:=null;
 numeroQuota:=null;
 descriQuota:=null;
 dataScadenzaQuota :=null;
 importoQuota :=null;
 documentoCollQuota :=null;
 movgestQuota :=null;
 movgestDescriQuota :=null;
 movgestAttoAmmQuota :=null;

 strMessaggio:='Lettura quote ordinativo.';

 for ordinativoTsRec in
 ( select ts.ord_ts_id ordTsId, ts.ord_ts_code numeroQuota, ts.ord_ts_desc descriQuota,
          ts.ord_ts_data_scadenza dataScadenzaQuota,det.ord_ts_det_importo importoQuota,
          mov.movgest_ts_id movgestTsId
    from siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_r_liquidazione_ord rliq, siac_t_liquidazione liq,
         siac_r_liquidazione_movgest mov
    where ts.ord_id=ordinativoId
    and   det.ord_ts_id=ts.ord_ts_id
    and   det.ord_ts_det_tipo_id=ordinativoTsDetTipoId
    and   rliq.sord_id=ts.ord_ts_id
    and   liq.liq_id=rliq.liq_id
    and   mov.liq_id=liq.liq_id
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   det.data_cancellazione is null
    and   det.validita_fine is null
    and   rliq.data_cancellazione is null
    and   rliq.validita_fine is null
    and   liq.data_cancellazione is null
    and   liq.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
   order by ts.ord_ts_code
 )
 loop
    ordTsId:=null;
 	numeroQuota:=null;
	descriQuota:=null;
	dataScadenzaQuota :=null;
	importoQuota :=null;
	documentoCollQuota :=null;
	movgestQuota :=null;
	movgestDescriQuota :=null;
	movgestAttoAmmQuota :=null;


	annoMovGest:=null;
    numeroMovGest:=null;
    descMovGest:=null;
	numeroSubMovGest:=null;
    descSubMovGest:=null;
    annoAttoAmm:=null;
    numeroAttoAmm:=null;
    sacAttoAmm:=null;
    attoAmmId:=null;
    oggettoAttoAmm:=null;
    tipoAttoAmm:=null;
    documentoColl:=null;
    movGestTsTipoId:=null;
    movGestId:=null;

    strMessaggio:='Lettura quote ordinativo.Quota numero='||ordinativoTsRec.numeroQuota
    			   ||'.Lettura siac_t_movgest_ts.';

    /* 17.02.2016 Sofia - la descrizione dei movimenti sempre su record ts
    select ts.movgest_id, ts.movgest_ts_code, ts.movgest_ts_desc, ts.movgest_ts_tipo_id
           into movGestId, numeroSubMovGest, descSubMovGest, movGestTsTipoId
    from siac_t_movgest_ts ts
    where ts.movgest_ts_id=ordinativoTsRec.movgestTsId;*/

	select ts.movgest_id, ts.movgest_ts_code, ts.movgest_ts_desc, ts.movgest_ts_tipo_id
           into movGestId, numeroSubMovGest, descMovGest, movGestTsTipoId
    from siac_t_movgest_ts ts
    where ts.movgest_ts_id=ordinativoTsRec.movgestTsId;

	if movGestId is null then
    	RAISE EXCEPTION ' Dato non reperito.';
    end if;

    strMessaggio:='Lettura quote ordinativo.Quota numero='||ordinativoTsRec.numeroQuota
    			   ||'.Lettura siac_t_movgest.';
/*     17.02.2016 Sofia - la descrizione dei movimenti sempre su record ts
select m.movgest_anno::varchar , m.movgest_numero::varchar, m.movgest_desc
           into annoMovGest,numeroMovGest,  descMovGest
    from siac_t_movgest m
    where m.movgest_id=movGestId; */

    select m.movgest_anno::varchar , m.movgest_numero::varchar
           into annoMovGest,numeroMovGest
    from siac_t_movgest m
    where m.movgest_id=movGestId;


    if numeroMovGest is null then
    	RAISE EXCEPTION ' Dato non reperito.';
    end if;

  /*    17.02.2016 Sofia
  if movGestTsTipoId=movgestTsTipoSubId then
    	descMovGest:=descSubMovGest;
    else
        numeroSubMovGest:=null;
    end if; */
    -- 17.02.2016 Sofia
    if movGestTsTipoId!=movgestTsTipoSubId then
	    numeroSubMovGest:=null;
    end if;

    strMessaggio:='Lettura quote ordinativo.Quota numero='||ordinativoTsRec.numeroQuota
    			   ||'.Lettura siac_t_atto_amm.';

	select a.attoamm_id, a.attoamm_anno, a.attoamm_numero::varchar, a.attoamm_oggetto, tipo.attoamm_tipo_code
           into attoAmmId, annoAttoAmm,numeroAttoAmm, oggettoAttoAmm, tipoAttoAmm
    from siac_r_movgest_ts_atto_amm r, siac_t_atto_amm a, siac_d_atto_amm_tipo tipo
    where r.movgest_ts_id=ordinativoTsRec.movgestTsId
    and   a.attoamm_id=r.attoamm_id
    and   tipo.attoamm_tipo_id=a.attoamm_tipo_id
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   a.data_cancellazione is null
    and   a.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;

   if attoAmmId is not null then
	    strMessaggio:='Lettura quote ordinativo.Quota numero='||ordinativoTsRec.numeroQuota
    			   ||'.Lettura SAC per Atto Amministrativo legato al movimento di gestione.';
        select c.classif_code into sacAttoAmm
	    from siac_r_atto_amm_class class, siac_t_class  c
        where class.attoamm_id=attoAmmId
        and   c.classif_id=class.classif_id
       	and   c.classif_tipo_id=classCdcTipoId
        and   class.data_cancellazione is null
        and   class.validita_fine is null
   	    and   c.data_cancellazione is null
       	and   c.validita_fine is null;

        if sacAttoAmm is null then
        	select c.classif_code into sacAttoAmm
	    	from siac_r_atto_amm_class class, siac_t_class  c
      		where class.attoamm_id=attoAmmId
	        and   c.classif_id=class.classif_id
    	   	and   c.classif_tipo_id=classCdrTipoId
	        and   class.data_cancellazione is null
	        and   class.validita_fine is null
   		    and   c.data_cancellazione is null
	       	and   c.validita_fine is null;
        end if;

    end if;
   strMessaggio:='Lettura quote ordinativo.Quota numero='||ordinativoTsRec.numeroQuota
    			   ||'.Lettura documento collegato.';

   select distinct doc.doc_anno::varchar ||'/'|| doc.doc_numero ||'-'||tipo.doc_tipo_code ||'-'||
          lpad(extract('day' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          lpad(extract('month' from doc.doc_data_emissione)::varchar,2,'0')||'/'||
          extract('year' from doc.doc_data_emissione) into documentoColl
   from siac_t_doc doc, siac_t_subdoc subdoc, siac_r_subdoc_ordinativo_ts subdocTs, siac_d_doc_tipo tipo
   where subdocts.ord_ts_id=ordinativoTsRec.ordTsId
   and   subdoc.subdoc_id=subdocts.subdoc_id
   and   doc.doc_id=subdoc.doc_id
   and   tipo.doc_tipo_id=doc.doc_tipo_id
   and   subdocts.data_cancellazione is null AND subdocts.validita_fine is null
   and   subdoc.data_cancellazione is null and subdoc.validita_fine is null
   and   doc.data_cancellazione is null and doc.validita_fine is null
   and   tipo.data_cancellazione is null
   and   tipo.validita_fine is null;


   ordTsId:=ordinativoTsRec.ordTsId;
   numeroQuota:=ordinativoTsRec.numeroQuota;
   descriQuota:=ordinativoTsRec.descriQuota;
   if ordinativoTsRec.dataScadenzaQuota is not null then
	   dataScadenzaQuota :=extract('year' from ordinativoTsRec.dataScadenzaQuota)||'-'||
    	                    lpad(extract('month' from ordinativoTsRec.dataScadenzaQuota)::varchar,2,'0')||'-'||
				            lpad(extract('day' from ordinativoTsRec.dataScadenzaQuota)::varchar,2,'0');
   end if;

   importoQuota :=trunc(ordinativoTsRec.importoQuota*100)::varchar;
   documentoCollQuota :=documentoColl;

   movgestQuota :=annoMovGest||'-'||numeroMovGest;
   if numeroSubMovGest is not null and numeroSubMovGest!='' then -- 17.02.2016 Sofia
    	movgestQuota :=movgestQuota||'-'||numeroSubMovGest;
   end if;

   movgestDescriQuota :=descMovGest;

   if numeroAttoAmm is not null then
		movgestAttoAmmQuota :=annoAttoAmm||'-'||numeroAttoAmm||'-'||tipoAttoAmm;
        if oggettoAttoAmm is not null then
        	movgestAttoAmmQuota:=movgestAttoAmmQuota||'-'||substring(oggettoAttoAmm from 1 for 150);
        end if;
   end if;

    return next;
 end loop;



 return;


exception
    when RAISE_EXCEPTION THEN
        RAISE EXCEPTION '%',coalesce(strMessaggio,'')||' '||coalesce(substring(upper(SQLERRM) from 1 for 1000),'');
        return;
    when TOO_MANY_ROWS THEN
        RAISE EXCEPTION '% Diverse righe lette.',coalesce(strMessaggio,'');
        return;
   when no_data_found then
	    RAISE EXCEPTION '% Non presente in archivio.',coalesce(strMessaggio,'');
        return;
	when others  THEN
 		RAISE EXCEPTION '% Errore DB % %',coalesce(strMessaggio,''),SQLSTATE,substring(SQLERRM from 1 for 1000);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;