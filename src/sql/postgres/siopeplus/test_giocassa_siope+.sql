/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
select *
from mif_d_flusso_elaborato_tipo
where ente_proprietario_id=2

select *
from mif_t_flusso_elaborato mif
where mif.ente_proprietario_id=2
order by mif.flusso_elab_mif_id desc

select *
from mif_t_giornalecassa mif
where mif.flusso_elab_mif_id=1020

update mif_t_giornalecassa set
flusso_elab_mif_id=1020
where flusso_elab_mif_id=1003

begin;
select *
from fnc_mif_flusso_elaborato_giornalecassa
( 2,   --enteProprietarioId integer,
  2017,--annoBilancio integer,
  'REGP',--nomeEnte VARCHAR,
  'GIOCASSA',--tipoFlussoMif varchar,
  1129,--flussoElabMifIdinteger,
  'test_giocassa',--loginOperazione varchar,
  now()::timestamp
);
-- ELABORAZIONE FLUSSO GIORNALE DI CASSA TIPO FLUSSO=GIOCASSA.IDENTIFICATIVO FLUSSO=997.VERIFICA INTEGRITA' FLUSSO. CODIFICHE ENTE.  COD.ERRORE=13
rollback;

select *
from siac_d_oil_ricevuta_errore err
where err.ente_proprietario_id=2

select *
from siac_t_ente_oil
where ente_proprietario_id=2;
-- ente_oil_codice=6220100
--- ente_oil_abi=02008


select *
from mif_t_giornalecassa  mif
where mif.flusso_elab_mif_id=1003
--    and   mif.codice_abi_bt=codiceAbiBt
--    and   mif.codice_ente_bt=codiceEnteBt
limit 1;

begin;
update mif_t_giornalecassa  mif
set   codice_abi_bt='02008',
      codice_ente_bt='6220100'
where mif.flusso_elab_mif_id=997;


select *
from mif_t_elab_giornalecassa  mif
where mif.flusso_elab_mif_id=1003


select *
from mif_t_oil_ricevuta mif
where mif.flusso_elab_mif_id=1003

select err.oil_ricevuta_errore_code, err.oil_ricevuta_errore_desc,
       mif.*
from siac_t_oil_ricevuta mif, siac_d_oil_ricevuta_errore err
where mif.flusso_elab_mif_id=1127
and   err.oil_ricevuta_errore_id=mif.oil_ricevuta_errore_id

-- 613415
select mif.*
from siac_t_oil_ricevuta mif
where mif.flusso_elab_mif_id=1020



select *
from siac_r_prov_cassa_oil_ricevuta r
where r.oil_ricevuta_id=62047

select *
from siac_t_prov_cassa p
where p.provc_id=18315

select *
from siac_d_oil_qualificatore qual
where qual.ente_proprietario_id=2

select *
from siac_d_prov_cassa_tipo tipo
where tipo.ente_proprietario_id=2


select *
from siac_t_prov_cassa p
where p.ente_proprietario_id=2
and   p.provc_anno::integer=2017
and   p.provc_numero::integer=68
and   p.provc_tipo_id=6


select *
from siac_t_prov_cassa p
where p.ente_proprietario_id=2
and   p.provc_anno::integer=2017
and   p.provc_numero::integer in (82,83,84)
and   p.provc_tipo_id=1

select *
from siac_r_ordinativo_prov_cassa r
where r.provc_id=7222


select
          tipo.oil_ricevuta_tipo_id,
          qual.oil_qualificatore_id,
          esito.oil_esito_derivato_id,
          997,
          rr.mif_t_giornalecassa_id,
         (case when tipo.oil_ricevuta_tipo_code='PS' then -1 else null end ),
     	  rr.esercizio,
          rr.numero_documento,
          rr.data_movimento::timestamp,
          qual.oil_qualificatore_segno,
          abs(rr.importo),
          substring(rr.anagrafica_cliente,1,500),
          substring(rr.causale,1,500)
         from
               siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
               mif_t_giornalecassa rr
               left outer join
               (select prov.provc_id,prov.provc_anno, prov.provc_numero, prov.provc_tipo_id
                from siac_t_prov_cassa prov
				where prov.ente_proprietario_id=2
                and   prov.data_cancellazione is null
                and   prov.validita_fine is null) provCassa
                      on (provCassa.provc_anno::integer=rr.esercizio
                      and provCassa.provc_numero::integer=rr.numero_documento
                      and provCassa.provc_tipo_id=6 )
	     where rr.flusso_elab_mif_id=997
      	 and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	 and   qual.oil_qualificatore_segno='U'
	     and   qual.ente_proprietario_id=2
    	 and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
         and   tipo.oil_ricevuta_tipo_code in ( 'P','PS')
         and   tipo.ente_proprietario_id=2
         and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
   	                       where rr1.flusso_elab_mif_id=997
       	                   and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id)


select
          tipo.oil_ricevuta_tipo_id,
          qual.oil_qualificatore_id,
          esito.oil_esito_derivato_id,
          1003,
          rr.mif_t_giornalecassa_id,
         (case when tipo.oil_ricevuta_tipo_code='PS' then -1 else null end ),
     	  rr.esercizio,
          rr.numero_documento,
          rr.data_movimento::timestamp,
          qual.oil_qualificatore_segno,
          qual.oil_qualificatore_code,
          abs(rr.importo),
          substring(rr.anagrafica_cliente,1,500),
          substring(rr.causale,1,500)
         from
               siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo,
               mif_t_giornalecassa rr
               left outer join
               (select prov.provc_id,prov.provc_anno, prov.provc_numero, prov.provc_tipo_id
                from siac_t_prov_cassa prov
				where prov.ente_proprietario_id=2
                and   prov.data_cancellazione is null
                and   prov.validita_fine is null) provCassa
                      on (provCassa.provc_anno::integer=rr.esercizio
                      and provCassa.provc_numero::integer=rr.numero_documento
                      and provCassa.provc_tipo_id=1 )
	     where rr.flusso_elab_mif_id=1003
      	 and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
	     and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
    	 and   qual.oil_qualificatore_segno='E'
	     and   qual.ente_proprietario_id=2
    	 and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
         and   tipo.oil_ricevuta_tipo_code in ( 'P','PS')
         and   tipo.ente_proprietario_id=2
         and   not exists (select distinct 1 from mif_t_oil_ricevuta rr1
   	                       where rr1.flusso_elab_mif_id=997
       	                   and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id)

select
          tipo.oil_ricevuta_tipo_id,
          qual.oil_qualificatore_id,
          esito.oil_esito_derivato_id,
          1020,
          rr.mif_t_giornalecassa_id,
         (case when tipo.oil_ricevuta_tipo_code='PS' then -1 else null end ),
     	  rr.esercizio,
          rr.numero_documento,
          rr.data_movimento::timestamp,
          qual.oil_qualificatore_segno,
          abs(rr.importo),
          substring(rr.anagrafica_cliente,1,500),
          substring(rr.causale,1,500)
from mif_t_giornalecassa rr,
     siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito,siac_d_oil_ricevuta_tipo tipo
where rr.flusso_elab_mif_id=1020
and   substring(rr.tipo_movimento,1,1)='U'
and  rr.tipo_documento='SOSPESO USCITA'
and  qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
and   qual.oil_qualificatore_segno='U'
and   qual.ente_proprietario_id=2
and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
	     and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
         and   tipo.oil_ricevuta_tipo_code in ( 'P','PS')
         and   tipo.ente_proprietario_id=2
order by rr.mif_t_giornalecassa_id


select *
from mif_t_giornalecassa  mif
where mif.flusso_elab_mif_id=1020
and   mif.tipo_movimento='ENTRATA'
and   mif.tipo_documento='SOSPESO ENTRATA'


select *
from mif_t_giornalecassa  mif
where mif.flusso_elab_mif_id=1020
and   mif.tipo_movimento='USCITA'
and   mif.tipo_documento='SOSPESO USCITA'

select *
from siac_d_oil_ricevuta_errore err

rollback;


     with
       ordProvCassa as
       (
       	select r.provc_id
        from siac_r_ordinativo_prov_cassa r, siac_t_ordinativo ord , siac_r_ordinativo_stato rstato , siac_d_ordinativo_stato stato
        where stato.ente_proprietario_id=2
        and   stato.ord_stato_code!='A'
        and   rstato.ord_stato_id=stato.ord_stato_id
        and   ord.ord_id=rstato.ord_id
        and   r.ord_id=ord.ord_id
        and   rstato.data_cancellazione is null
        and   rstato.validita_fine is null
        and   r.data_cancellazione is null
        and   r.validita_fine is null
       ),
       provCassa as
       (
       select errore.oil_ricevuta_errore_id, tipo.oil_ricevuta_tipo_id, qual.oil_qualificatore_id,esito.oil_esito_derivato_id,
              rr.mif_t_giornalecassa_id,
              rr.esercizio,rr.numero_documento,
              rr.data_movimento::timestamp data_movimento,
              substring(rr.tipo_movimento,1,1) tipo_movimento,
              abs(rr.importo) importo,
              substring(rr.anagrafica_cliente,1,500) anagrafica_cliente,
              prov.provc_id
       from  mif_t_giornalecassa rr, siac_d_oil_ricevuta_errore errore,
             siac_d_oil_qualificatore qual, siac_d_oil_esito_derivato esito, siac_d_oil_ricevuta_tipo tipo,
             siac_t_prov_cassa prov
       where rr.flusso_elab_mif_id=1020
       --and   rr.anagrafica_cliente is not null
       --and   rr.anagrafica_cliente!=''
       and   qual.oil_qualificatore_code=rr.tipo_documento||' '||rr.tipo_operazione
       and   qual.oil_qualificatore_segno=substring(rr.tipo_movimento,1,1)
       and   qual.oil_qualificatore_segno='U'
       and   qual.ente_proprietario_id=2
       and   esito.oil_esito_derivato_id=qual.oil_esito_derivato_id
       and   tipo.oil_ricevuta_tipo_id=esito.oil_ricevuta_tipo_id
       and   tipo.oil_ricevuta_tipo_code='PS'
       and   prov.ente_proprietario_id=2
       and   prov.provc_anno::integer=rr.esercizio
       and   prov.provc_numero::integer=rr.numero_documento
       and   prov.provc_tipo_id=1
       and   prov.data_cancellazione is null
       and   prov.validita_fine is null
       and   errore.oil_ricevuta_errore_code=55::varchar
       and   errore.ente_proprietario_id=2
  /*     and not exists (select distinct 1 from mif_t_oil_ricevuta rr1
                       where rr1.flusso_elab_mif_id=flussoElabMifId
                       and   rr1.oil_progr_ricevuta_id=rr.mif_t_giornalecassa_id)*/
      )
      select provCassa.oil_ricevuta_errore_id, provCassa.oil_ricevuta_tipo_id, provCassa.oil_qualificatore_id,provCassa.oil_esito_derivato_id,
             1020,provCassa.mif_t_giornalecassa_id,
             provCassa.esercizio,provCassa.numero_documento,
             provCassa.data_movimento,provCassa.tipo_movimento,
             provCassa.importo,
             provCassa.anagrafica_cliente,
             provCassa.provc_id
      from provCassa, ordProvCassa
      where provCassa.provc_id=ordProvCassa.provc_id

 select *
from mif_t_giornalecassa  mif
where mif.flusso_elab_mif_id=1129
and   mif.tipo_movimento='USCITA'
and   mif.tipo_documento='SOSPESO USCITA'

 select *
from mif_t_giornalecassa  mif
where mif.flusso_elab_mif_id=1129
and   mif.tipo_movimento='ENTRATA'
and   mif.tipo_documento='SOSPESO ENTRATA'


 select *
from mif_t_giornalecassa  mif
where mif.flusso_elab_mif_id=1129
and   mif.tipo_movimento='USCITA'
and   mif.tipo_documento='MANDATO'
-- 58

 select *
from mif_t_giornalecassa  mif
where mif.flusso_elab_mif_id=1129
and   mif.tipo_movimento='ENTRATA'
and   mif.tipo_documento='REVERSALE'
-- 2


begin;
select *
from fnc_mif_flusso_elaborato_giornalecassa
( 2,   --enteProprietarioId integer,
  2017,--annoBilancio integer,
  'REGP',--nomeEnte VARCHAR,
  'GIOCASSA',--tipoFlussoMif varchar,
  1129,--flussoElabMifIdinteger,
  'test_giocassa',--loginOperazione varchar,
  now()::timestamp
);
-- ELABORAZIONE FLUSSO GIORNALE DI CASSA TIPO FLUSSO=GIOCASSA.IDENTIFICATIVO FLUSSO=997.VERIFICA INTEGRITA' FLUSSO. CODIFICHE ENTE.  COD.ERRORE=13
rollback;

select ord.ord_numero::integer, stato.ord_stato_code,
       r.validita_inizio, r.validita_fine,
       det.ord_ts_det_importo
from siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato,
     siac_v_bko_anno_bilancio anno,siac_t_ordinativo_ts ts, siac_t_ordinativo_ts_det det, siac_d_ordinativo_ts_det_tipo tipod
where tipo.ente_proprietario_id=2
and   tipo.ord_tipo_code='I'
and   ord.ord_tipo_id=tipo.ord_tipo_id
and   r.ord_id=ord.ord_id
and   stato.ord_stato_id=r.ord_stato_id
and   anno.bil_id=ord.bil_id
and   anno.anno_bilancio=2017
and   ts.ord_id=ord.ord_id
and   det.ord_ts_id=ts.ord_ts_id
and   tipod.ord_ts_det_tipo_id=det.ord_ts_det_tipo_id
and   tipod.ord_ts_det_tipo_code='A'
and   r.data_cancellazione is null
order by 1 desc,r.validita_inizio,   r.validita_fine

-- 6329  48
-- 6327  25
-- 6313 2500 (150,10+25)
-- 6302 15,12 A
-- 6277 40556,17 non trasmesso
-- 6319, 6322

select err.oil_ricevuta_errore_code, err.oil_ricevuta_errore_desc,
       tipo.oil_ricevuta_tipo_code,
       mif.oil_ricevuta_importo,
       mif.oil_ord_importo,
       mif.oil_ord_importo_quiet,
       mif.oil_ord_importo_quiet_tot,
       mif.*
from siac_t_oil_ricevuta mif, siac_d_oil_ricevuta_errore err, siac_d_oil_ricevuta_tipo tipo
where mif.flusso_elab_mif_id=1127
and   err.oil_ricevuta_errore_id=mif.oil_ricevuta_errore_id
and   tipo.oil_ricevuta_tipo_id=mif.oil_ricevuta_tipo_id

-- 30 ordinativo inesistente ord numero=613415,613435
-- 38 negativo ma su storno va bene 13415, 123
-- 42 58 già  quietanzati

select tipo.oil_ricevuta_tipo_code,
       mif.oil_ricevuta_anno,
       mif.oil_ricevuta_numero,
       mif.oil_ricevuta_data,
       mif.oil_ricevuta_importo,
       mif.oil_ord_numero,
       mif.oil_ord_data_emissione,
       mif.oil_ord_data_firma,
       mif.oil_ord_data_quietanza,
       mif.oil_ord_trasm_oil_data,
       mif.oil_ord_importo,
       mif.oil_ord_importo_quiet,
       mif.oil_ord_importo_quiet_tot,
       g.numero_bolletta_quietanza,
       g.numero_bolletta_quietanza_storno,
       mif.*
from siac_t_oil_ricevuta mif,siac_d_oil_ricevuta_tipo tipo,mif_t_giornalecassa g
where mif.flusso_elab_mif_id=1129
and   mif.oil_ricevuta_errore_id is null
and   tipo.oil_ricevuta_tipo_id=mif.oil_ricevuta_tipo_id
and   g.mif_t_giornalecassa_id=mif.oil_progr_ricevuta_id


select tipo.oil_ricevuta_tipo_code,
       mif.oil_ricevuta_anno,
       mif.oil_ricevuta_numero,
       mif.oil_ricevuta_data,
       mif.oil_ricevuta_importo,
       mif.oil_ord_numero,
       mif.oil_ord_data_emissione,
       mif.oil_ord_data_firma,
       mif.oil_ord_data_quietanza,
       mif.oil_ord_trasm_oil_data,
       mif.oil_ord_importo,
       mif.oil_ord_importo_quiet,
       mif.oil_ord_importo_quiet_tot,
       r.ord_quietanza_numero,
       r.ord_quietanza_data,
       r.ord_quietanza_importo,
       stato.ord_stato_code,
       mif.*
from siac_t_oil_ricevuta mif,siac_d_oil_ricevuta_tipo tipo,siac_r_ordinativo_quietanza r,siac_r_ordinativo_stato rs,
     siac_d_ordinativo_stato stato
where mif.flusso_elab_mif_id=1129
and   mif.oil_ricevuta_errore_id is null
and   tipo.oil_ricevuta_tipo_id=mif.oil_ricevuta_tipo_id
and   r.oil_ricevuta_id=mif.oil_ricevuta_id
and   rs.ord_id=r.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null


select tipo.oil_ricevuta_tipo_code,
       mif.oil_ricevuta_anno,
       mif.oil_ricevuta_numero,
       mif.oil_ricevuta_data,
       mif.oil_ricevuta_importo,
       mif.oil_ord_numero,
       mif.oil_ord_data_emissione,
       mif.oil_ord_data_firma,
       mif.oil_ord_data_quietanza,
       mif.oil_ord_trasm_oil_data,
       mif.oil_ord_importo,
       mif.oil_ord_importo_quiet,
       mif.oil_ord_importo_quiet_tot,
       r.ord_storno_numero,
       r.ord_storno_data,
       r.ord_Storno_importo,
       stato.ord_stato_code,
       mif.*
from siac_t_oil_ricevuta mif,siac_d_oil_ricevuta_tipo tipo,siac_r_ordinativo_storno r,siac_r_ordinativo_stato rs,
     siac_d_ordinativo_stato stato
where mif.flusso_elab_mif_id=1127
and   mif.oil_ricevuta_errore_id is null
and   tipo.oil_ricevuta_tipo_id=mif.oil_ricevuta_tipo_id
and   r.oil_ricevuta_id=mif.oil_ricevuta_id
and   rs.ord_id=r.ord_id
and   stato.ord_stato_id=rs.ord_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null

select err.oil_ricevuta_errore_code::integer,
       err.oil_ricevuta_errore_desc,
       tipo.oil_ricevuta_tipo_code,
       gio.tipo_documento,
       mif.oil_ricevuta_anno,
       mif.oil_ricevuta_numero,
       mif.oil_ricevuta_data,
       mif.oil_ricevuta_importo,
       mif.oil_ord_numero,
       mif.oil_ord_data_emissione,
       mif.oil_ord_data_firma,
       mif.oil_ord_data_quietanza,
       mif.oil_ord_trasm_oil_data,
       mif.oil_ord_importo,
       mif.oil_ord_importo_quiet,
       mif.oil_ord_importo_quiet_tot,
       mif.*
from siac_t_oil_ricevuta mif,siac_d_oil_ricevuta_tipo tipo,siac_d_oil_ricevuta_errore err,
	 mif_t_giornalecassa gio
where mif.flusso_elab_mif_id=1129
and   mif.oil_ricevuta_errore_id is not null
and   tipo.oil_ricevuta_tipo_id=mif.oil_ricevuta_tipo_id
and   err.oil_ricevuta_errore_id=mif.oil_ricevuta_errore_id
and   gio.mif_t_giornalecassa_id=mif.oil_progr_ricevuta_id



select *
from siac_t_oil_ricevuta oil
where oil.oil_ricevuta_id=63288

select *
from siac_r_prov_cassa_oil_ricevuta r
where r.oil_ricevuta_id in (63288,63289)

select *
from siac_t_prov_cassa p
where p.provc_id in (18332,18333)

select *
from mif_t_oil_ricevuta

select *
from mif_t_elab_giornalecassa



/*si richiede di mettere in stato trasmesso i mandati
42101
42102


attualmente sono firmati*/


select err.oil_ricevuta_errore_code,
       err.oil_ricevuta_errore_desc,
       oil.oil_ord_numero,
       oil.*
from siac_t_oil_ricevuta oil,siac_d_oil_ricevuta_errore err
where oil.flusso_elab_mif_id=1739
and   oil.oil_ricevuta_errore_id is not null
and   err.oil_ricevuta_errore_id=oil.oil_ricevuta_errore_id

select ord.ord_numero::integer,ord.ord_emissione_data, ord.ord_trasm_oil_data,
       stato.ord_stato_code, r.validita_inizio, r.validita_fine--,
      -- rfirma.*
from siac_v_bko_anno_bilancio anno, siac_t_ordinativo ord, siac_d_ordinativo_tipo tipo,
     siac_r_ordinativo_stato r, siac_d_ordinativo_stato stato--,siac_r_ordinativo_firma rfirma
where  tipo.ente_proprietario_id=2
and    tipo.ord_tipo_code='I'
and    ord.ord_tipo_id=tipo.ord_tipo_id
and    anno.bil_id=ord.bil_id
and    anno.anno_bilancio=2017
--and    ord.ord_numero::integer in (42101,42102,42023)
and    ord.ord_numero::integer  between 17605 and 17608
and    r.ord_id=ord.ord_id
and    stato.ord_stato_id=r.ord_stato_id
--and    rfirma.ord_id=ord.ord_id
and    r.data_cancellazione is null
--and    rfirma.data_cancellazione is null
--and    rfirma.validita_fine is null
order by 1,r.validita_inizio, r.validita_fine

select *
from mif_t_flusso_elaborato mif
order by mif.flusso_elab_mif_id desc