/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

-- SIAC-8017 - JOB - 22.04.2022 Sofia - inizio

insert into siac_d_gestione_tipo 
(
	gestione_tipo_code,
	gestione_tipo_desc,
	validita_inizio,
	login_operazione,
	ente_proprietario_id 
)
select 'SALDO_SOTTO_CONTI_VINC',
       'Calcolo saldo sotto conti vincolati',
       now(),
       'SIAC-8017',
       ente.ente_proprietario_id 
from siac_t_ente_proprietario ente 
where ente.ente_proprietario_id =3
and   not exists 
(
select 1
from siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id=ente.ente_proprietario_id
and   tipo.gestione_tipo_code='SALDO_SOTTO_CONTI_VINC'
);
	

insert into siac_d_gestione_livello
(
   gestione_livello_code,
   gestione_livello_desc,
   gestione_tipo_id,
   validita_inizio,
   login_operazione ,
   ente_proprietario_id 
)   
select 'GEST_SALDO_SOTTO_CONTI_VINC',
       'Calcolo automatico finale-iniziali in ape gestione',
       tipo.gestione_tipo_id ,
       now(),
       'SIAC-8017',
       ente.ente_proprietario_id 
from siac_d_gestione_tipo  tipo , siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =3
and   tipo.ente_proprietario_id =ente.ente_proprietario_id 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   not exists 
(
select 1 
from siac_d_gestione_livello liv 
where liv.gestione_tipo_id=tipo.gestione_tipo_id 
and   liv.gestione_livello_code='GEST_SALDO_SOTTO_CONTI_VINC'
);


insert into siac_d_gestione_livello
(
   gestione_livello_code,
   gestione_livello_desc,
   gestione_tipo_id,
   validita_inizio,
   login_operazione ,
   ente_proprietario_id 
)   
select 'AGGIORNA_INIZ_SALDO_SOTTO_CONTI_VINC',
       'Aggiornamento automatico saldi iniziali',
       tipo.gestione_tipo_id ,
       now(),
       'SIAC-8017',
       ente.ente_proprietario_id 
from siac_d_gestione_tipo  tipo , siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =3
and   tipo.ente_proprietario_id =ente.ente_proprietario_id 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   not exists 
(
select 1 
from siac_d_gestione_livello liv 
where liv.gestione_tipo_id=tipo.gestione_tipo_id 
and   liv.gestione_livello_code='AGGIORNA_INIZ_SALDO_SOTTO_CONTI_VINC'
);

insert into siac_d_gestione_livello
(
   gestione_livello_code,
   gestione_livello_desc,
   gestione_tipo_id,
   validita_inizio,
   login_operazione ,
   ente_proprietario_id 
)   
select 'AGGIORNA_FINAL_SALDO_SOTTO_CONTI_VINC',
       'Aggiornamento automatico saldi finali',
       tipo.gestione_tipo_id ,
       now(),
       'SIAC-8017',
       ente.ente_proprietario_id 
from siac_d_gestione_tipo  tipo , siac_t_ente_proprietario  ente 
where ente.ente_proprietario_id =3
and   tipo.ente_proprietario_id =ente.ente_proprietario_id 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   not exists 
(
select 1 
from siac_d_gestione_livello liv 
where liv.gestione_tipo_id=tipo.gestione_tipo_id 
and   liv.gestione_livello_code='AGGIORNA_FINAL_SALDO_SOTTO_CONTI_VINC'
);

create table if not exists siac_t_saldo_vincolo_sotto_conto_elab(
	saldo_vincolo_conto_el_id serial NOT NULL,
	vincolo_id integer NOT NULL,
	contotes_id integer NOT NULL,
	saldo_iniziale numeric NULL,
	saldo_finale numeric NULL,
    ripiano_iniziale numeric NULL,
	ripiano_finale numeric NULL,
	bil_id integer NOT NULL,
	tipo_caricamento varchar(1) not null,
	saldo_vincolo_conto_elab_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id integer NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT siac_t_saldo_vincolo_sotto_conto_elab_pk PRIMARY KEY (saldo_vincolo_conto_el_id),
	CONSTRAINT siac_d_contotesoreria_siac_t_saldo_vincolo_sotto_conto_el FOREIGN KEY (contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_bil_siac_t_saldo_vincolo_sotto_conto_el FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_saldo_vincolo_sotto_conto_el FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_saldo_vincolo_sotto_conto_el_siac_t_vincolo FOREIGN KEY (vincolo_id) REFERENCES siac.siac_t_vincolo(vincolo_id)
);

select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_fk_vincolo_id_idx'::text,
  'vincolo_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_fk_contotes_id'::text,
  'contotes_id'::text,
  '',
  false
);

select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_elab'::text,
  'siac_t_saldo_vincolo_sotto_conto_el_elab_id_idx'::text,
  'saldo_vincolo_conto_elab_id'::text,
  '',
  false
);


create table if not exists siac_t_saldo_vincolo_sotto_conto_da_file
(
	saldo_vincolo_conto_da_file_id serial NOT NULL,
	vincolo_code varchar(200) NOT NULL,
	conto_code varchar(200) NOT NULL,
	saldo_iniziale numeric NULL,
	saldo_finale   numeric NULL,
	ripiano_iniziale numeric NULL,
	ripiano_finale numeric NULL,
	anno_bilancio_iniziale integer,
	anno_bilancio_finale   integer,
	tipo_caricamento varchar(10) not null,
	fl_caricato varchar(1) default 'N' not null,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id integer NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT siac_t_saldo_vincolo_sotto_conto_da_f_pk PRIMARY KEY (saldo_vincolo_conto_da_file_id),
	CONSTRAINT siac_t_ente_proprietario_siac_t_saldo_vincolo_sotto_conto_da_f FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id)
);

select fnc_dba_create_index(
'siac_t_saldo_vincolo_sotto_conto_da_file'::text,
  'siac_t_saldo_vincolo_sotto_conto_da_f_fk_ente_propr_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);


drop function if exists siac.fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno
(
  enteproprietarioid   integer,
  annoBilancio         integer
);

DROP FUNCTION if exists siac.fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer, -- indicare per I, E
  annoBilancioFinale   integer, -- indicare per F,E, per I serve ma se omesso viene ricavato
  ricalcoloSaldi       varchar, -- S,N (opzionale a caricamento da tabella)
  caricaDaTabella      varchar, -- S,N|<nome_tabella> (opzionare a ricalcolo saldi)
  tipoAggiornamento    varchar, -- I-iniziale,F-finale,E-entrambi
  checkFinale          boolean,
  loginoperazione      varchar, 
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
);


DROP FUNCTION if exists siac.fnc_siac_aggiorna_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer,
  annoBilancioFinale   integer,
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
);

DROP FUNCTION if exists siac.fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer,
  annoBilancioFinale   integer,
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
);


drop FUNCTION IF EXISTS siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
);


CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno
(
  enteproprietarioid   integer,
  annoBilancio         integer
)
RETURNS table 
(
contotes_code character varying,
contotes_desc character varying,
contotes_disp_id integer,
vincolo_code character varying,
vincolo_id   integer,
ripiano_vincolo_conto numeric,
saldo_vincolo_conto numeric
) 
AS $body$
 
DECLARE


BEGIN
	
raise notice 'fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno in annoBilancio=%',annoBilancio::varchar;

return query	
select vincoli_ordinativi_finale.contotes_code as contotes_code, 
       vincoli_ordinativi_finale.contotes_desc as contotes_desc,  
       vincoli_ordinativi_finale.contotes_disp_id as contotes_disp_id,
       vincoli_ordinativi_finale.vincolo_code as vincolo_code,
       vincoli_ordinativi_finale.vincolo_id as vincolo_id ,
       sum(vincoli_ordinativi_finale.ord_ts_det_importo_ripiano) as ripiano_vincolo_conto, -- sommatoria finale di ripiano
       sum(vincoli_ordinativi_finale.ord_ts_det_importo) as saldo_vincolo_conto -- sommatoria finale  di saldo
from         
(
select vincoli_ordinativi_sommati.contotes_code, 
       vincoli_ordinativi_sommati.contotes_desc, 
       vincoli_ordinativi_sommati.contotes_disp_id,
       vincoli_ordinativi_sommati.vincolo_code,
       vincoli_ordinativi_sommati.vincolo_id,
       vincoli_ordinativi_sommati.ord_tipo_code,
       -- inverti segno pagamenti
       ( case when vincoli_ordinativi_sommati.ord_tipo_code='P' then -vincoli_ordinativi_sommati.ord_ts_det_importo_ripiano else vincoli_ordinativi_sommati.ord_ts_det_importo_ripiano end ) ord_ts_det_importo_ripiano, 
       ( case when vincoli_ordinativi_sommati.ord_tipo_code='P' then -vincoli_ordinativi_sommati.ord_ts_det_importo else vincoli_ordinativi_sommati.ord_ts_det_importo end ) ord_ts_det_importo
       
from 
(
select vincoli_ordinativi.contotes_code, 
       vincoli_ordinativi.contotes_desc, 
       vincoli_ordinativi.contotes_disp_id,
       vincoli_ordinativi.vincolo_code,
       vincoli_ordinativi.vincolo_id,
       vincoli_ordinativi.ord_tipo_code, 
       vincoli_ordinativi.ord_tipo_id,
       sum((case when contotes_nodisp_id is not null then det.ord_ts_det_importo else 0 end)) ord_ts_det_importo_ripiano,
       sum((case when contotes_nodisp_id is null     then det.ord_ts_det_importo else 0 end)) ord_ts_det_importo
    --   sum(det.ord_ts_det_importo) ord_ts_det_importo -- somma per conto , vincolo, pagamenti-incassi
from 
(
    with 
    vincoli as 
    (
    select vinc.vincolo_code,  
           tipo_e.elem_tipo_code, e.elem_code,
           vinc.vincolo_id, e.elem_id 
    from siac_t_vincolo vinc,siac_d_vincolo_tipo tipo,siac_t_periodo per,siac_t_bil bil,
         siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,siac_r_vincolo_bil_elem r,
         siac_t_bil_elem e,siac_d_bil_elem_tipo tipo_e
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.vincolo_tipo_code='G'
    and   vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
    and   per.periodo_id=vinc.periodo_id 
    and   bil.periodo_id=per.periodo_id 
    and   per.anno::integer=annoBilancio
    and   rs.vincolo_id=vinc.vincolo_id 
    and   stato.vincolo_stato_id=rs.vincolo_stato_id 
    and   stato.vincolo_stato_code!='A'
    and   r.vincolo_id=vinc.vincolo_id 
    and   e.elem_id=r.elem_id 
    and   tipo_e.elem_tipo_id=e.elem_tipo_id 
    and   tipo_e.elem_tipo_code in ('CAP-UG','CAP-EG')
    and   r.data_cancellazione is null 
    and   r.validita_fine is null 
    and   rs.data_cancellazione is null 
    and   rs.validita_fine is null 
    order by 1, 2,3
   ),
   ordinativi as
   (
   with 
   ord_conti as 
   (
   select tipo.ord_tipo_code, tipo.ord_tipo_id,ord.ord_numero,
          conto.contotes_code,
          re.elem_id, ord.ord_id , 
          conto.contotes_id,
          --(case when estraiRipiano=true then rconto.contotes_id  else null end) contotes_nodisp_id, 
          rconto.contotes_id contotes_nodisp_id,
          coalesce(conto.per_ripianamento,false) per_ripianamento
   from siac_t_bil bil,siac_t_periodo per,
	    siac_d_ordinativo_tipo tipo, 
        siac_t_ordinativo ord left join siac_r_ordinativo_contotes_nodisp rconto on (rconto.ord_id=ord.ord_id and rconto.data_cancellazione is null and  rconto.validita_fine is null),
        siac_r_ordinativo_stato rs,siac_d_ordinativo_stato stato ,
        siac_d_contotesoreria conto,
        siac_r_ordinativo_bil_elem re
   where tipo.ente_proprietario_id=enteProprietarioId
   and   ord.ord_tipo_id=tipo.ord_tipo_id
   and   rs.ord_id=ord.ord_id 
   and   stato.ord_stato_id=rs.ord_Stato_id 
--   and   stato.ord_stato_code!='A'
   and   stato.ord_stato_code='Q'
   and   conto.contotes_id=ord.contotes_id
   and   ( conto.vincolato=true or conto.per_ripianamento=true )
   and   re.ord_id=ord.ord_id 
   and   bil.bil_id=ord.bil_id 
   and   per.periodo_id=bil.periodo_id 
   and   per.anno::integer=annoBilancio
   and   rs.data_cancellazione is null 
   and   rs.validita_fine is null 
   and   re.data_cancellazione is null 
   and   re.validita_fine is null 
   )
   select ord_conti.ord_tipo_code,ord_conti.ord_tipo_id,ord_conti.ord_numero,
          ord_conti.contotes_code,
          ord_conti.elem_id, ord_conti.ord_id , 
          ord_conti.contotes_id,
          ord_conti.contotes_nodisp_id, 
          ord_conti.per_ripianamento,
--          (case  when ord_conti.contotes_nodisp_id is not null  then ord_conti.contotes_nodisp_id
--                 when estraiRipiano=false and ord_conti.per_ripianamento=false and ord_conti.contotes_nodisp_id is null  then ord_conti.contotes_id
--                 else null end ) contotes_disp_id
          (case  when ord_conti.contotes_nodisp_id is not null  then ord_conti.contotes_nodisp_id
                 when ord_conti.contotes_nodisp_id is null and ord_conti.per_ripianamento=false  then ord_conti.contotes_id
                 else null end ) contotes_disp_id       
   from ord_conti 
   )
   select conto.contotes_code,         -- contotes_code da utilizzare per calcolo disp
          conto.contotes_desc,         -- contotes_desc da utilizzare per calcolo disp  
          ordinativi.contotes_disp_id, -- contotes_id   da utilizzare per calcolo disp
          vincoli.vincolo_code,
          vincoli.vincolo_id,
          ordinativi.ord_tipo_code, 
          ordinativi.ord_tipo_id,
          ordinativi.ord_numero,
          ordinativi.elem_id, 
          ordinativi.ord_id , 
          ordinativi.contotes_code ord_contotes_code, -- contotes diretto su ordinativo 
          ordinativi.contotes_id   ord_contotes_id,   -- contotes diretto su ordinativo
          ordinativi.contotes_nodisp_id,              -- contotes indiretto attraverso ripianamento
          ordinativi.per_ripianamento
   from  vincoli , ordinativi ,siac_d_contotesoreria conto
   where vincoli.elem_id=ordinativi.elem_id 
   and   conto.contotes_id=ordinativi.contotes_disp_id 
) vincoli_ordinativi , siac_t_ordinativo_ts ts,siac_t_ordinativo_ts_det det,siac_d_ordinativo_ts_det_tipo tipo 
where vincoli_ordinativi.ord_id=ts.ord_id 
and   det.ord_ts_id=ts.ord_ts_id 
and   tipo.ord_ts_det_tipo_id=det.ord_ts_Det_tipo_id
and   tipo.ord_ts_det_tipo_code='A'
and   det.data_cancellazione is null 
and   det.validita_fine is null 
-- somma per conto , vincolo, pagamenti-incassi
group by vincoli_ordinativi.contotes_code, 
         vincoli_ordinativi.contotes_desc, 
        vincoli_ordinativi.contotes_disp_id,
        vincoli_ordinativi.vincolo_code,
        vincoli_ordinativi.vincolo_id,
        vincoli_ordinativi.ord_tipo_code,
        vincoli_ordinativi.ord_tipo_id
) vincoli_ordinativi_sommati
) vincoli_ordinativi_finale 
-- sommatoria finale 
group by vincoli_ordinativi_finale.contotes_code, 
       vincoli_ordinativi_finale.contotes_desc, 
       vincoli_ordinativi_finale.contotes_disp_id,
       vincoli_ordinativi_finale.vincolo_code,
       vincoli_ordinativi_finale.vincolo_id;
     
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100 ROWS 1000;


ALTER FUNCTION siac.fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno(integer, integer ) OWNER TO siac;

CREATE OR REPLACE FUNCTION siac.fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  --  i due anni di bilancio devono essere sempre consecutivi
  annoBilancioIniziale integer, -- indicare per I, E
  annoBilancioFinale   integer, -- indicare per F,E, per I serve ma se omesso viene ricavato
  ricalcoloSaldi       varchar, -- S,N (opzionale a caricamento da tabella)
  caricaDaTabella      varchar, -- S,N|<nome_tabella> (opzionare a ricalcolo saldi)
  tipoAggiornamento    varchar, -- I-iniziale,F-finale,E-entrambi
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  checkFinale          boolean default true,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
)
RETURNS record
 AS $body$
DECLARE

-- parametri di input  : ente_proprietario, anno_finale, anno_iniziale, ricalcolo (true,false),
--                       tipo_aggiornamento ( iniziale, finale, entrambi)
--  i due anni di bilancio devono essere sempre consecutivi
--  annoBilancioIniziale integer, -- indicare per I, E
--  annoBilancioFinale   integer, -- indicare per F,E, per I serve ma se omesso viene ricavato
--  ricalcoloSaldi       varchar, -- S,N (opzionale a caricamento da tabella)
--  caricaDaTabella      varchar, -- S,N|<nome_tabella> (opzionare a ricalcolo saldi)
--  tipoAggiornamento    varchar, -- I-iniziale,F-finale,E-entrambi
--  NOTE. 
--  I saldi non possono essere mai ricalcolati, quindi se esistono saldi validi sia iniziali che validi 
--  devono essere prima invalidati manualmente, diversamente la fnc restituisce errore
--  solo se eseguita da fnc di approviazione del bil.prev sono effettuate invalidazioni automatiche
--  Caricamente da Tabella : sono caricati i saldi sia iniziali che finali 
--  in questo caso vengono caricati i saldi così come presenti in tabella 
--  i saldi devono essere positivi, i valori di ripiano devono essere negativi
--  Devono essere caricati valori distinti in tabella per i saldi iniziali e per quelli finali 

strMessaggio VARCHAR(2500):=''; 
strMessaggioBck  VARCHAR(2500):=''; 
strMessaggioFinale VARCHAR(1500):='';
strErrore VARCHAR(1500):='';
strMessaggioLog VARCHAR(2500):='';

codResult integer:=null;
annoBilancio integer:=null;
annoBilancioIni integer:=null;
annoBilancioFin integer:=null;

elabId integer:=null;

elabRec record;
elabResRec record;
   

sql_insert varchar(5000):=null;
flagRicalcoloSaldi boolean:=false;
flagCaricaDaTabella boolean:=false;
nomeTabella varchar(250):=null;

bilFinaleId integer:=null;
bilInizialeId integer:=null;

faseOp varchar(50):=null;


NVL_STR CONSTANT             varchar :='';
BIL_GESTIONE_STR CONSTANT    varchar :='G';
BIL_PROVVISORIO_STR CONSTANT varchar :='E';
BIL_CONSUNTIVO_STR CONSTANT  varchar :='O';


BEGIN

strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati - inizio.';

raise notice '%',strMessaggioFinale;
raise notice 'tipoAggiornamento=%',tipoAggiornamento;
raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;
raise notice 'ricalcoloSaldi=%',ricalcoloSaldi;
raise notice 'caricaDaTabella=%',caricaDaTabella;

outElabId:=null;
codiceRisultato:=0;
messaggioRisultato:='';

strMessaggio:='Verifica valore parametro tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR)=NVL_STR or 
   coalesce(tipoAggiornamento,NVL_STR) not in ('I','F','E') then
   raise exception 'Valore obbligatorio [I,F,E].';
end if;

strMessaggio:='Verifica valore parametro annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR)='I' and coalesce(annoBilancioIniziale,'0')='0' then 
	   raise exception 'Valore obbligatorio.';
end if;

strMessaggio:='Verifica valore parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR)='F' and coalesce(annoBilancioFinale,'0')='0' then 
	   raise exception 'Valore obbligatorio.';
end if;

if coalesce(tipoAggiornamento,NVL_STR)in ( 'I','E') then -- per iniziale devo sempre avere dati finale, quindi se non impostano annoFinale devo ricavarlo da Iniziale
	strMessaggio:='Verifica valore parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
		           ||'annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
	               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
	if  coalesce(annoBilancioIniziale,'0')='0' and coalesce(annoBilancioFinale,'0')='0' then 
		   raise exception 'Valore obbligatorio almeno dei due anni deve essere indicato.';
	end if;
    if  coalesce(annoBilancioIniziale,'0')='0' then
       annoBilancioIniziale:=annoBilancioFinale+1;
    end if;
    if  coalesce(annoBilancioFinale,'0')='0' then
       annoBilancioFinale:=annoBilancioIniziale-1;
    end if;
    raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
    raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;
end if;

strMessaggio:='Verifica congruenza valori parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
		           ||'annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
	               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(annoBilancioIniziale,'0')!='0' and
   coalesce(annoBilancioFinale,'0')!='0' and
   annoBilancioIniziale!=annoBilancioFinale+1 then 
   raise exception 'Anni non consecutivi.';
end if;
   

	              
strMessaggio:='Verifica valore parametro caricaDaTabella='||coalesce(caricaDaTabella,'N')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(caricaDaTabella,NVL_STR)!=NVL_STR then
    flagCaricaDaTabella:=(case when coalesce(split_part(caricaDaTabella,'|',1),'N')='S' then true else false end);
    if flagCaricaDaTabella=true then
    	nomeTabella:=split_part(caricaDaTabella,'|',2);
    	if coalesce(nomeTabella,NVL_STR)=NVL_STR then
    		raise exception 'Valore nomeTabella non impostato';
    	else 
          raise notice '@@@@ VERIFICARE ESISTENZA TABELLA @@@@@@';
          
          codResult:=null;
          select 1 into codResult
	      from pg_tables
	      where tablename=nomeTabella;
	      
	      if not FOUND or codResult is null then 
	      	raise exception ' Tabella=% non esistente',nomeTabella;
	      end if;
	      codResult:=null;
    	end if;
    end if;
end if;

 
flagRicalcoloSaldi:=(case when coalesce(ricalcoloSaldi,'N')='S' then true else false end);

raise notice 'flagRicalcoloSaldi=%',(case when flagRicalcoloSaldi=true then 'S' else 'N' end);
raise notice 'flagCaricaDaTabella=%',(case when flagCaricaDaTabella=true then 'S' else 'N' end);


strMessaggio:='Verifica valori parametri ricalcoloSaldi='||coalesce(ricalcoloSaldi,'N')
             ||' per caricaDaTabella='||coalesce(split_part(caricaDaTabella,'|',1),'N')
             ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if flagCaricaDaTabella=true and flagRicalcoloSaldi=true then 
	   raise exception 'Opzione ricalcolo saldi e caricamento da tabella esclusivi.';
end if;


 

-- controllo stati anni di bilancio
-- finale deve essere in gestione o predisposizione consuntivo
strMessaggio:='Calcolo bilancioId e verifica faseOP per valore parametro annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR) in ('F','E','I') then  -- per calcolare iniziale devo avere i dati del finale
	-- caricamento dati tabella applicativa in annoBilancioFinale
    select bil.bil_id into bilFinaleId
    from siac_t_bil bil,siac_t_periodo per 
    where bil.ente_proprietario_id=enteProprietarioId 
    and   per.periodo_id=bil.periodo_id 
    and   per.anno::integer=annoBilancioFinale;
    if bilFinaleId is null then
    	raise exception 'Identificativo bilancioId non reperito';
    end if;
   
    select fase.fase_operativa_code into faseOp
    from siac_r_bil_fase_operativa r,siac_d_fase_operativa fase 
    where r.bil_id=bilFinaleId
    and   fase.fase_operativa_id=r.fase_operativa_id
    and   r.data_cancellazione is null 
    and   r.validita_fine is null;
    if coalesce(faseOp,NVL_STR) not in (BIL_GESTIONE_STR,BIL_CONSUNTIVO_STR) then
--  	   	raise exception 'Fase operativa non reperita o non ammessa [%-%]', BIL_GESTIONE_STR,BIL_CONSUNTIVO_STR;
    raise notice 'Fase operativa non reperita o non ammessa [%-%]', BIL_GESTIONE_STR,BIL_CONSUNTIVO_STR;
    end if;
end if;

-- inziale deve essere in provvisorio o gestione
strMessaggio:='Calcolo bilancioId e verifica faseOP per valore parametro annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then 
	-- caricamento dati tabella applicativa in annoBilancioFinale
    select bil.bil_id into bilInizialeId
    from siac_t_bil bil,siac_t_periodo per 
    where bil.ente_proprietario_id=enteProprietarioId 
    and   per.periodo_id=bil.periodo_id 
    and   per.anno::integer=annoBilancioIniziale;
    if bilInizialeId is null then
    	raise exception 'Identificativo bilancioId non reperito';
    end if;
   
    faseOp:=null;
    select fase.fase_operativa_code into faseOp
    from siac_r_bil_fase_operativa r,siac_d_fase_operativa fase 
    where r.bil_id=bilInizialeId
    and   fase.fase_operativa_id=r.fase_operativa_id
    and   r.data_cancellazione is null 
    and   r.validita_fine is null;
    if coalesce(faseOp,NVL_STR) not in (BIL_GESTIONE_STR,BIL_PROVVISORIO_STR) then
--    		raise exception 'Fase operativa non reperita o non ammessa [%-%]',BIL_PROVVISORIO_STR,BIL_GESTIONE_STR;
     raise notice 'Fase operativa non reperita o non ammessa [%-%]',BIL_PROVVISORIO_STR,BIL_GESTIONE_STR;    	
    end if;
end if;


if coalesce(tipoAggiornamento,NVL_STR) in ('E','I') then 
    strMessaggio:='Verifica esistenza saldi per  annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
    codResult:=null;
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r 
	where r.ente_proprietario_id=enteProprietarioId 
	and   r.bil_id=bilInizialeId
	and   r.data_cancellazione is null 
	and   r.validita_fine is null;
    if coalesce(codResult,0)!=0  then
    	raise exception ' Saldi gia'' caricati - elaborazione non rieseguibile previa cancellazione.';
    end if;
    
end if;

if coalesce(tipoAggiornamento,NVL_STR) in ('E','F') and checkFinale=true then 
    strMessaggio:='Verifica esistenza  saldi finali per annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
    codResult:=null;
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r 
	where r.ente_proprietario_id=enteProprietarioId 
	and   r.bil_id=bilFinaleId
	and   ( coalesce(r.saldo_finale,0) !=0 or coalesce(r.ripiano_finale,0) !=0)
	and   r.data_cancellazione is null 
	and   r.validita_fine is null;
    if coalesce(codResult,0)!=0  then
    	raise exception ' Saldi gia'' caricati - elaborazione non rieseguibile previa cancellazione.';
    end if;
    
end if;


-- calcolo elab_id
strMessaggio:='Calcolo elabId per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
elabId:=null;
select max(elab.saldo_vincolo_conto_elab_id) into elabId
from siac_t_saldo_vincolo_sotto_conto_elab elab 
where elab.ente_proprietario_id=enteProprietarioId;
if elabId is null or elabId=0 then elabId:=1; 
else    elabId:=elabId+1;
end if;
raise notice 'elabId=%',elabId::varchar;

--- ricalcolo saldi
if elabId is not null and flagRicalcoloSaldi=true  then 
	-- esecuzione ricalcolo saldi su tabella temporanea di elaborazione
   raise notice '*** CALCOLO SALDI DA ORDINATIVI ***';
   if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
   	annoBilancio:=annoBilancioIniziale-1;
   else 
    if coalesce(tipoAggiornamento,NVL_STR) ='F' then
   	 annoBilancio:=annoBilancioFinale;
    end if;	
   end if;
  
  if coalesce(tipoAggiornamento,NVL_STR) in ('F','E') then 
    raise notice '*** CARICAMENTO FINALI siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno=% elabId=%',annoBilancio::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi FINALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incass per anno='||annoBilancio::varchar||' per elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
    insert into siac_t_saldo_vincolo_sotto_conto_elab  
    ( 
      vincolo_id,	
      contotes_id,
      saldo_iniziale,	
      saldo_finale,
      ripiano_iniziale,
      ripiano_finale,
	  bil_id,
	  tipo_caricamento, 
	  saldo_vincolo_conto_elab_id ,
      validita_inizio,
      login_operazione, 
      ente_proprietario_id 
    )
    select fnc_saldi.vincolo_id,
           fnc_saldi.contotes_disp_id,
           0,
           fnc_saldi.saldo_vincolo_conto,
           0,
           fnc_saldi.ripiano_vincolo_conto,
           bilFinaleId,
          'O',
           elabId,
           clock_timestamp(),
          loginOperazione,
          enteProprietarioId
   from fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno(enteProprietarioId,annoBilancio) fnc_saldi;
    
   codResult:=null;
   select count(*) into codResult
   from siac_t_saldo_vincolo_sotto_conto_elab elab 
   where elab.saldo_vincolo_conto_elab_id=elabId 
   and   elab.bil_id=bilFinaleId
   and   elab.data_cancellazione is null 
   and   elab.validita_fine is null;
   raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');
   codResult:=null;
  end if;
  
  if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
    raise notice '*** CARICAMENTO INIZIALI siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno=% elabId=%',annoBilancio::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi INIZIALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno='||annoBilancio::varchar||' per elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
              
    insert into siac_t_saldo_vincolo_sotto_conto_elab  
    ( 
      vincolo_id,	
      contotes_id,
      saldo_iniziale,	
      saldo_finale,
      ripiano_iniziale,	
      ripiano_finale,
	  bil_id,
	  tipo_caricamento, 
	  saldo_vincolo_conto_elab_id ,
      validita_inizio,
      login_operazione, 
      ente_proprietario_id 
    )
    select       
      saldi_vincoli_conti.vincolo_id,
      saldi_vincoli_conti.contotes_disp_id,
      saldi_vincoli_conti.saldo,
      0,
      saldi_vincoli_conti.ripiano,
      0,
      bilInizialeId,
      'O',
      elabId,
      clock_timestamp(),
      loginOperazione,
      enteProprietarioId
    from   
    (
    with 
    vincoli_iniziali as
    (
    select vinc.vincolo_code,
           vinc.vincolo_id
    from siac_t_vincolo vinc, siac_d_vincolo_tipo tipo,
         siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
         siac_t_periodo per 
    where tipo.ente_proprietario_id=enteProprietarioId 
    and   tipo.vincolo_tipo_code='G'
    and   vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
    and   rs.vincolo_id=vinc.vincolo_id 
    and   stato.vincolo_stato_id=rs.vincolo_stato_id 
    and   stato.vincolo_stato_code!='A'
    and   per.periodo_id=vinc.periodo_id 
    and   per.anno::integer=annoBilancioIniziale
    and   vinc.data_cancellazione is null 
    and   vinc.validita_fine is null 
    and   rs.data_cancellazione is null 
    and   rs.validita_fine is null
    ),
    vincoli_finali as
    (
     select 
      vinc.vincolo_code,
      fnc_saldi.vincolo_id,
      fnc_saldi.contotes_disp_id,
      fnc_saldi.saldo_vincolo_conto+coalesce(r.saldo_iniziale,0) saldo,
      fnc_saldi.ripiano_vincolo_conto+coalesce(r.ripiano_iniziale,0) ripiano
    from  
    (
      select fnc_saldi.*
      from fnc_siac_calcolo_saldo_sottoconto_vincolo_in_anno(enteProprietarioId,annoBilancio) fnc_saldi
    ) fnc_saldi left join siac_r_saldo_vincolo_sotto_conto r on 
      (     r.bil_id=bilFinaleId 
       and  r.vincolo_id=fnc_saldi.vincolo_id  
       and  r.contotes_id=fnc_saldi.contotes_disp_id 
       and  r.data_cancellazione is null
       and  r.validita_fine is null 
      ),siac_t_vincolo vinc
    where vinc.vincolo_id=fnc_saldi.vincolo_id
   )
   select vincoli_iniziali.vincolo_id,
	      vincoli_finali.contotes_disp_id,
	      vincoli_finali.saldo,
	      vincoli_finali.ripiano
   from   vincoli_finali , vincoli_iniziali 
   where vincoli_finali.vincolo_code=vincoli_iniziali.vincolo_code 
   ) saldi_vincoli_conti;
   
  strMessaggio:='Inserimento saldi INIZIALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da pagamenti/incassi per anno='||annoBilancio::varchar||' per elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'. Saldi senza movimenti in anno='||annoBilancio::varchar||'.';
    
   insert into siac_t_saldo_vincolo_sotto_conto_elab  
    ( 
      vincolo_id,	
      contotes_id,
      saldo_iniziale,	
      saldo_finale,
      ripiano_iniziale,	
      ripiano_finale,
	  bil_id,
	  tipo_caricamento, 
	  saldo_vincolo_conto_elab_id ,
      validita_inizio,
      login_operazione, 
      ente_proprietario_id 
    )
    select       
      saldi_vincoli_conti.vincolo_id,
      saldi_vincoli_conti.contotes_id,
      saldi_vincoli_conti.saldo,
      0,
      saldi_vincoli_conti.ripiano,
      0,
      bilInizialeId,
      'O',
      elabId,
      clock_timestamp(),
      loginOperazione,
      enteProprietarioId
    from   
    (
    with 
    vincoli_iniziali as
    (
    select vinc.vincolo_code,
           vinc.vincolo_id
    from siac_t_vincolo vinc, siac_d_vincolo_tipo tipo,
         siac_r_vincolo_stato rs,siac_d_vincolo_stato stato,
         siac_t_periodo per 
    where tipo.ente_proprietario_id=enteProprietarioId 
    and   tipo.vincolo_tipo_code='G'
    and   vinc.vincolo_tipo_id=tipo.vincolo_tipo_id 
    and   rs.vincolo_id=vinc.vincolo_id 
    and   stato.vincolo_stato_id=rs.vincolo_stato_id 
    and   stato.vincolo_stato_code!='A'
    and   per.periodo_id=vinc.periodo_id 
    and   per.anno::integer=annoBilancioIniziale
    and   vinc.data_cancellazione is null 
    and   vinc.validita_fine is null 
    and   rs.data_cancellazione is null 
    and   rs.validita_fine is null
    ),
    vincoli_finali as
    (
     select 
      vinc.vincolo_code,
      r.vincolo_id,
      r.contotes_id,
      coalesce(r.saldo_iniziale,0) saldo,
      coalesce(r.ripiano_iniziale,0) ripiano
    from  siac_r_saldo_vincolo_sotto_conto r ,siac_t_vincolo vinc
    where   r.bil_id=bilFinaleId 
   -- and     coalesce(r.saldo_finale,0)=0
    and     vinc.vincolo_id=r.vincolo_id
    and     r.data_cancellazione is null
    and     r.validita_fine is null 
   )
   select vincoli_iniziali.vincolo_id,
	      vincoli_finali.contotes_id,
	      vincoli_finali.saldo,
	      vincoli_finali.ripiano
   from   vincoli_finali , vincoli_iniziali 
   where vincoli_finali.vincolo_code=vincoli_iniziali.vincolo_code 
   and   not exists 
   (
    select 1
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.bil_id=bilInizialeId
    and   elab.saldo_vincolo_conto_elab_id=elabId
    and   elab.vincolo_id=vincoli_iniziali.vincolo_id 
    and   elab.contotes_id=vincoli_finali.contotes_id
   )
   ) saldi_vincoli_conti;
  
    codResult:=null;
    select count(*) into codResult
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.saldo_vincolo_conto_elab_id=elabId 
    and   elab.bil_id=bilInizialeId
    and   elab.data_cancellazione is null 
    and   elab.validita_fine is null;
    raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');          
    codResult:=null;
 end if;

end if;

-- lettura dati da tabella
if elabId is not null and flagCaricaDaTabella=true then
 
  raise notice '*** LETTURA DATI TABELLA ***';
 
  if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
    raise notice '*** CARICAMENTO INIZIALI siac_t_saldo_vincolo_sotto_conto_elab DA % per anno=% elabId=%',nomeTabella,annoBilancioIniziale::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi INIZIALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da '||nomeTabella||' per elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
 
    -- siac_t_saldo_vincolo_sotto_conto_da_file
  	sql_insert:='insert into siac_t_saldo_vincolo_sotto_conto_elab  
                 ( vincolo_id,	contotes_id,
                   saldo_iniziale,	saldo_finale,ripiano_iniziale,	ripiano_finale,
				   bil_id,tipo_caricamento, saldo_vincolo_conto_elab_id ,
                   validita_inizio,login_operazione, ente_proprietario_id )
	             select vinc.vincolo_id, conto.contotes_id, da_file.saldo_iniziale,0,da_file.ripiano_iniziale,0, '
  	          ||'       '||bilInizialeId::varchar||', ''F'','||elabId::varchar||', '
  	          ||'       clock_timestamp(),'''||loginOperazione||''','||enteProprietarioId::varchar||' '
              ||'from '||nomeTabella||' da_file ,
                      siac_t_vincolo vinc,siac_r_vincolo_stato rs,siac_d_vincolo_stato stato, siac_d_vincolo_tipo tipo_vinc,'
              ||'     siac_t_periodo per,siac_d_periodo_tipo tipo , siac_d_contotesoreria conto '
              ||'   where da_file.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and da_file.anno_bilancio_iniziale='||annoBilancioIniziale::varchar
              ||' and da_file.fl_caricato=''N'' ' 
              ||' and vinc.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and vinc.vincolo_code=da_file.vincolo_code and per.periodo_id=vinc.periodo_id '
              ||' and per.anno::integer='||annoBilancioIniziale::varchar
              ||' and tipo.periodo_tipo_id=per.periodo_tipo_id and tipo.periodo_tipo_code=''SY'' '
              ||' and rs.vincolo_id=vinc.vincolo_id and stato.vincolo_stato_id=rs.vincolo_stato_id '
              ||' and stato.vincolo_stato_code!=''A'' '
              ||' and tipo_vinc.vincolo_tipo_id=vinc.vincolo_tipo_id and tipo_vinc.vincolo_tipo_code=''G'' '
              ||' and conto.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and conto.contotes_code=da_file.conto_code '
              ||' and vinc.data_cancellazione is null and vinc.validita_fine is null '
              ||' and conto.data_cancellazione is null and conto.validita_fine is null'
              ||' and rs.data_cancellazione is null and rs.validita_fine is null;';
              
    raise notice 'sql_insert=%', sql_insert;         
    execute sql_insert;
   
    codResult:=null;
    select count(*) into codResult
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.saldo_vincolo_conto_elab_id=elabId 
    and   elab.bil_id=bilInizialeId
    and   elab.data_cancellazione is null 
    and   elab.validita_fine is null;
    raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');
    codResult:=null;
   
  end if;
  
  if coalesce(tipoAggiornamento,NVL_STR) in ('F','E') then
    raise notice '*** CARICAMENTO FINALI siac_t_saldo_vincolo_sotto_conto_elab DA % per anno=% elabId=%',nomeTabella,annoBilancioFinale::varchar,elabId::varchar;
    strMessaggio:='Inserimento saldi FINALI vincolo sottoconto in siac_t_saldo_vincolo_sotto_conto_elab da '||nomeTabella||' per elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
 
    -- siac_t_saldo_vincolo_sotto_conto_da_file
  	sql_insert:='insert into siac_t_saldo_vincolo_sotto_conto_elab  
                 ( vincolo_id,	contotes_id,saldo_iniziale,	saldo_finale,ripiano_iniziale,	ripiano_finale,
				   bil_id,tipo_caricamento, saldo_vincolo_conto_elab_id ,
                   validita_inizio,login_operazione, ente_proprietario_id )
	             select vinc.vincolo_id, conto.contotes_id, 0,da_file.saldo_finale,0,da_file.ripiano_finale,'
  	          ||'       '||bilFinaleId::varchar||', ''F'','||elabId::varchar||', '
  	          ||'       clock_timestamp(),'''||loginOperazione||''','||enteProprietarioId::varchar||' '
              ||'from '||nomeTabella||' da_file ,
                      siac_t_vincolo vinc,siac_r_vincolo_stato rs,siac_d_vincolo_stato stato, siac_d_vincolo_tipo tipo_vinc,'
              ||'     siac_t_periodo per,siac_d_periodo_tipo tipo , siac_d_contotesoreria conto '
              ||'   where da_file.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and da_file.anno_bilancio_finale='||annoBilancioFinale::varchar
              ||' and da_file.fl_caricato=''N'' '              
              ||' and vinc.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and vinc.vincolo_code=da_file.vincolo_code and per.periodo_id=vinc.periodo_id '
              ||' and per.anno::integer='||annoBilancioFinale::varchar
              ||' and tipo.periodo_tipo_id=per.periodo_tipo_id and tipo.periodo_tipo_code=''SY'' '
              ||' and rs.vincolo_id=vinc.vincolo_id and stato.vincolo_stato_id=rs.vincolo_stato_id '
              ||' and stato.vincolo_stato_code!=''A'' '
              ||' and tipo_vinc.vincolo_tipo_id=vinc.vincolo_tipo_id and tipo_vinc.vincolo_tipo_code=''G'' '
              ||' and conto.ente_proprietario_id='||enteProprietarioId::varchar
              ||' and conto.contotes_code=da_file.conto_code '
              ||' and vinc.data_cancellazione is null and vinc.validita_fine is null '
              ||' and conto.data_cancellazione is null and conto.validita_fine is null '
              ||' and rs.data_cancellazione is null and rs.validita_fine is null;';
              
    raise notice 'sql_insert=%', sql_insert;         
    execute sql_insert;
   
    codResult:=null;
    select count(*) into codResult
    from siac_t_saldo_vincolo_sotto_conto_elab elab 
    where elab.saldo_vincolo_conto_elab_id=elabId 
    and   elab.bil_id=bilFinaleId
    and   elab.data_cancellazione is null 
    and   elab.validita_fine is null;
    raise notice '*** INSERITI NUMERO REC=%',coalesce(codResult::varchar,'0');
   codResult:=null;
  end if;
end if;
 

-- ribaltamento dati da tabella di elaborazioni in tabella applicativa
if elabId is not null and codResult is null then 
 if coalesce(tipoAggiornamento,NVL_STR) in ('I','E') then
  strMessaggio:='Inserimento saldi INIZIALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioIniziale='||coalesce(annoBilancioIniziale::varchar,'0')
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
  raise notice '*** CARICAMENTO INIZIALI in siac_r_saldo_vincolo_sotto_conto per anno=% elabId=%',annoBilancioIniziale::varchar,elabId::varchar;
  insert into siac_r_saldo_vincolo_sotto_conto
  (
    vincolo_id,
	contotes_id,
	saldo_iniziale,
	saldo_finale,
	ripiano_iniziale,
	ripiano_finale,
	bil_id,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
  )
  select 
    elab.vincolo_id,
	elab.contotes_id,
	elab.saldo_iniziale,
	0,
	elab.ripiano_iniziale,
	0,
	elab.bil_id,
	clock_timestamp(),
	loginOperazione||'@ELAB-'||elabId::varchar,
	elab.ente_proprietario_id
  from  siac_t_saldo_vincolo_sotto_conto_elab elab 
  where elab.saldo_vincolo_conto_elab_id=elabId
  and   elab.bil_id=bilInizialeId
  and   elab.data_cancellazione is null 
  and   elab.validita_fine is null;
 

 
  codResult:=null;
  select count(*) into codResult 
  from  siac_r_saldo_vincolo_sotto_conto r 
  where  r.ente_proprietario_id=enteProprietarioId 
  and    r.bil_id=bilInizialeId
  and    r.login_operazione=loginOperazione||'@ELAB-'||elabId::varchar
  and    r.data_cancellazione is null
  and    r.validita_fine is null;
  if codResult is null then codResult:=0; end if;
 
  raise notice '*** RECORD INSERITI=%',coalesce(codResult::varchar,'0');

 end if;
 
 if coalesce(tipoAggiornamento,NVL_STR) in ('F','E') then
  raise notice '*** CARICAMENTO FINALI in siac_r_saldo_vincolo_sotto_conto per anno=% elabId=%',annoBilancioFinale::varchar,elabId::varchar;

  strMessaggio:='Inserimento saldi FINALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0') 
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'.';
  insert into siac_r_saldo_vincolo_sotto_conto
  (
    vincolo_id,
	contotes_id,
	saldo_iniziale,
	saldo_finale,
	ripiano_iniziale,
	ripiano_finale,
	bil_id,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
  )
  select 
    elab.vincolo_id,
	elab.contotes_id,
	coalesce(r_iniziale.saldo_iniziale,0),
--	elab.saldo_finale,
	(case when flagRicalcoloSaldi=true then coalesce(r_iniziale.saldo_iniziale,0)+elab.saldo_finale 
	      else elab.saldo_finale end ),
    coalesce(r_iniziale.ripiano_iniziale,0),      
	(case when flagRicalcoloSaldi=true then coalesce(r_iniziale.ripiano_iniziale,0)+elab.ripiano_finale 
	      else elab.ripiano_finale end ),
	elab.bil_id,
	clock_timestamp(),
	loginOperazione||'@ELAB-'||elabId::varchar,
	elab.ente_proprietario_id
  from  siac_t_saldo_vincolo_sotto_conto_elab elab  
          left join siac_r_saldo_vincolo_sotto_conto r_iniziale 
           on (r_iniziale.bil_id=bilFinaleId 
           and r_iniziale.vincolo_id=elab.vincolo_id 
           and r_iniziale.contotes_id=elab.contotes_id
           and r_iniziale.data_cancellazione is null 
           and r_iniziale.validita_fine is null )
  where elab.saldo_vincolo_conto_elab_id=elabId
  and   elab.bil_id=bilFinaleId
  and   elab.data_cancellazione is null 
  and   elab.validita_fine is null;
 
  if  flagRicalcoloSaldi=true then 
   strMessaggio:='Inserimento saldi FINALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0') 
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'. Inserimento finali senza movimenti in anno.';
   insert into siac_r_saldo_vincolo_sotto_conto
   (
    vincolo_id,
	contotes_id,
	saldo_iniziale,
	saldo_finale,
	ripiano_iniziale,
	ripiano_finale,
	bil_id,
	validita_inizio,
	login_operazione,
	ente_proprietario_id
   )
   select r_iniziale.vincolo_id,
          r_iniziale.contotes_id,
          r_iniziale.saldo_iniziale,
          r_iniziale.saldo_iniziale,
          r_iniziale.ripiano_iniziale,
          r_iniziale.ripiano_iniziale,
          r_iniziale.bil_id,
          clock_timestamp(),
          loginOperazione||'@ELAB-'||elabId::varchar,
          r_iniziale.ente_proprietario_id
   from siac_r_saldo_vincolo_sotto_conto r_iniziale 
   where r_iniziale.bil_id=bilFinaleId
   and   r_iniziale.login_operazione!=loginOperazione||'@ELAB-'||elabId::varchar
  -- and   coalesce(r_iniziale.saldo_finale,0)=0
   and   not exists 
   (
   select 1 
   from  siac_r_saldo_vincolo_sotto_conto r1 
   where r1.bil_id=bilFinaleId
   and   r1.vincolo_id=r_iniziale.vincolo_id 
   and   r1.contotes_id=r_iniziale.contotes_id
   and   r1.login_operazione=loginOperazione||'@ELAB-'||elabId::varchar
   and   r1.data_cancellazione is null 
   and   r1.validita_fine is null 
   )
   and   r_iniziale.data_cancellazione is null
   and   r_iniziale.validita_fine is null;
  end if;
 
  strMessaggio:='Inserimento saldi FINALI in siac_r_saldo_vincolo_sotto_conto vincolo sotto-conto elabId='||elabId::varchar
               ||' annoBilancioFinale='||coalesce(annoBilancioFinale::varchar,'0') 
               ||' per tipoAggiornamento='||coalesce(tipoAggiornamento,NVL_STR)||'. Chiusura inziali esistenti.';
  update siac_r_saldo_vincolo_sotto_conto r 
  set    data_cancellazione=now(),
         validita_fine=now(),
         login_operazione=r.login_operazione||'-'||loginOperazione||'@ELAB-'||elabId::varchar
  where r.ente_proprietario_id=enteProprietarioId
  and   r.bil_id=bilFinaleId
  and   r.login_operazione!=loginOperazione||'@ELAB-'||elabId::varchar
  and   r.data_cancellazione is null
  and   r.validita_fine is null;

  codResult:=null;
  select count(*) into codResult 
  from  siac_r_saldo_vincolo_sotto_conto r 
  where  r.ente_proprietario_id=enteProprietarioId 
  and    r.bil_id=bilFinaleId
  and    r.login_operazione=loginOperazione||'@ELAB-'||elabId::varchar
  and    r.data_cancellazione is null
  and    r.validita_fine is null;
  if codResult is null then codResult:=0; end if;
 
  raise notice '*** RECORD INSERITI=%',coalesce(codResult::varchar,'0');

 end if; 
end if;


strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati - fine. ELABORAZIONE OK.';   
outElabId:=elabId;
messaggioRisultato:=strMessaggioFinale;

return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;


        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outElabId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  integer,
  integer,
  integer,
  varchar,
  varchar,
  varchar,
  varchar,
  timestamp,
  boolean,  
  out integer,
  out integer,
  out varchar
) OWNER to siac;

CREATE OR REPLACE FUNCTION siac.fnc_siac_aggiorna_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer,
  annoBilancioFinale   integer,
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
)
RETURNS record
 AS $body$
declare

strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
strMessaggioFinale VARCHAR(1500):='';


elabId integer:=null;
elabRec record;

annoApertura integer:=null;
annoChiusura integer:=null;


-- in apertura saldi sempre calcolati entrambi
RicalcoloSaldi varchar(1):='S';
tipoAggiornamento varchar(1):=null;

issaldiAttivi integer:=null;
codResult integer:=null;

BEGIN
/* 
 * RICALCOLO PER AGGIORNAMENTO SALDI SOTTO CONTI VINCOLATI - SU QUADRATURA CASSA CON TESORIERE
 * I SALDI DEI CONTI SONO RICALCOLATI AUTOMATICAMENTE SU ANNO BILANCIO IN CHIUSURA
 * GLI STESSI SALDI SONO RIPORTATATI COME INIZIALI SU ANNO BILANCIO+1 IN APERTURA
 * LA FNC di CALCOLO VIENE ESEGUITA SOLO SE I PARAMETRI DI SISTEMA AGGIORNA_%_SALDO_SOTTO_CONTI_VINC SI TROVANO  SUL DB
 * ALMENO UNO DEI DUE
 * I SALDI FINALI SONO RICALCOLATI SOLO SI TROVA IL PARAMETRO AGGIORNA_FIN_SALDO_SOTTO_CONTI_VINC SU DB
 * I SALDI INIZIALI SONO RICALCOLATI SOLO SI TROVA IL PARAMETRO AGGIORNA_INIZ_SALDO_SOTTO_CONTI_VINC SU DB
 * I SALDI SONO RICALCOLABILI AUTOMATICAMENTE 
 * SE SONO PRESENTI SALDI VALIDI PRIMA DI ESEGUIRE LA FNC DI RICALCOLO SONO INVALIDATI TUTTI AUTAMATICAMENTE
 * NON RICHIAMABILE DA UNA FNC DI FASE IN QUANTO NON ESISTENTE UNA FASE CHE IDENTIFICA
 * LA QUADRATURA DI CASSA CON TESORIERE
 */
strMessaggioFinale:='Elaborazione aggiornamento saldi sottoconti-vincolati - inizio.';
codiceRisultato:=0;
messaggioRisultato:='';



raise notice '%',strMessaggioFinale;
raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;


annoApertura:=annoBilancioIniziale;
annoChiusura:=annoBilancioFinale;

strMessaggio:='Verifica configurazione ente per aggiornamento saldi sottoconti-vincolati.';
select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code like 'AGGIORNA_%_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 

raise notice 'isSaldiAttivi=%',isSaldiAttivi::varchar;

-- se non attiva - no errore ma non viene effettuato nulla
if isSaldiAttivi is null then 
	messaggioRisultato:='Elaborazione aggiornamento saldi sottoconti-vincolati - fine - gestione non attiva.';
	return;
end if;

strMessaggio:='Verifica configurazione ente per aggiornamento saldi sottoconti-vincolati. Saldi iniziali.';
isSaldiAttivi:=null;
select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code ='AGGIORNA_INIZ_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 
raise notice 'Apertura isSaldiAttivi=%',isSaldiAttivi::varchar;
if isSaldiAttivi is null then 
	annoApertura :=null;
end if;
raise notice 'Apertura annoApertura=%',annoApertura::varchar;

strMessaggio:='Verifica configurazione ente per aggiornamento saldi sottoconti-vincolati. Saldi finali.';
isSaldiAttivi:=null;
select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code ='AGGIORNA_FINAL_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 
raise notice 'Chiusura isSaldiAttivi=%',isSaldiAttivi::varchar;
if isSaldiAttivi is null then 
	annoChiusura :=null;
end if;
raise notice 'Apertura annoChiusura=%',annoChiusura::varchar;

if annoApertura is not null  then 
	strMessaggio:='Verifica esistenza saldi sottoconti-vincolati iniziali per anno='||annoApertura::varchar||'.';
    codResult:=null;
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r ,siac_t_periodo per, siac_t_bil bil 
	where bil.ente_proprietario_id=enteProprietarioId 
	and   per.periodo_id=bil.periodo_id 
	and   per.anno::integer=annoApertura
	and   r.bil_id=bil.bil_id
	and   r.data_cancellazione  is null 
	and   r.validita_fine is null;

	if codResult is not null then 
	    strMessaggio:='Invalidazione saldi sottoconti-vincolati iniziali per anno='||annoApertura::varchar||' pre-esistenti.';
		update siac_r_saldo_vincolo_sotto_conto r
		set    data_cancellazione=now(),
		       validita_fine=now(),
		       login_operazione=r.login_operazione||'-AGGIORN-INIZ-' ||loginOperazione
	    from siac_t_periodo per, siac_t_bil bil 
		where bil.ente_proprietario_id=enteProprietarioId 
		and   per.periodo_id=bil.periodo_id 
		and   per.anno::integer=annoApertura
		and   r.bil_id=bil.bil_id
		and   r.data_cancellazione  is null 
		and   r.validita_fine is null;
	end if;
end if;

/*if annoChiusura is not null  then 
	codResult:=null;
	strMessaggio:='Verifica esistenza saldi sottoconti-vincolati finali per anno='||annoChiusura::varchar||'.';
	select 1 into codResult
	from siac_r_saldo_vincolo_sotto_conto r ,siac_t_periodo per, siac_t_bil bil 
	where bil.ente_proprietario_id=enteProprietarioId 
	and   per.periodo_id=bil.periodo_id 
	and   per.anno::integer=annoChiusura
	and   r.bil_id=bil.bil_id
	and   ( coalesce(r.saldo_finale,0) !=0 or coalesce(r.ripiano_finale,0) !=0 )
	and   r.data_cancellazione  is null 
	and   r.validita_fine is null;

	if codResult is not null then 
	    strMessaggio:='Invalidazione saldi sottoconti-vincolati finali per anno='||annoChiusura::varchar||' pre-esistenti.';
		update siac_r_saldo_vincolo_sotto_conto r
		set    data_cancellazione=now(),
		       validita_fine=now(),
		       login_operazione=r.login_operazione ||'-AGGIORN-FINAL-'||loginOperazione
	    from siac_t_periodo per, siac_t_bil bil 
		where bil.ente_proprietario_id=enteProprietarioId 
		and   per.periodo_id=bil.periodo_id 
		and   per.anno::integer=annoChiusura
		and   r.bil_id=bil.bil_id
--	    and   ( coalesce(r.saldo_finale,0) !=0 or coalesce(r.ripiano_finale,0) !=0 )
		and   r.data_cancellazione  is null 
		and   r.validita_fine is null;
	end if;
end if;*/

strMessaggio:='Calcolo tipoAggiornamento saldi sottoconti-vincolati.';
tipoAggiornamento:=( case when annoApertura is not null and annoChiusura is not null then  'E'
						         when annoApertura is not null and annoChiusura is null     then  'I'	
	   						     when annoApertura is null and annoChiusura is not null     then  'F'
	   						     else null
			 		      end );
strMessaggio:='Calcolo tipoAggiornamento saldi sottoconti-vincolati : tipoAggiornamento='||tipoAggiornamento||'.';				    
raise notice 'strMessaggio=%',strMessaggio;
if tipoAggiornamento  is not null then 			
	strMessaggio:='Elaborazione aggiornamento saldi sottoconti-vincolati - avvio fnc_siac_calcolo_saldo_sottoconto_vincolo.';
	raise notice 'strMessaggio=%',strMessaggio;

	elabRec:=null;
	select * into elabRec
	from 
	fnc_siac_calcolo_saldo_sottoconto_vincolo
	(
	  enteproprietarioid,
	  annoApertura, -- anno in apertura
	  annoChiusura,   -- anno in chiusura
	  ricalcoloSaldi, 	    -- true
	  null,
	  tipoAggiornamento,
	  loginoperazione,
	  dataelaborazione,
	  false
	);
	if elabRec.codiceRisultato=0 then
	    elabId:=elabRec.outElabId;
	else
		strMessaggio:=elabRec.messaggioRisultato;
	    codiceRisultato:=elabRec.codiceRisultato;
	end if;
else 
	strMessaggio:='Elaborazione aggiornamento saldi sottoconti-vincolati - fnc_siac_calcolo_saldo_sottoconto_vincolo non avviata.';
	raise notice 'strMessaggio=%',strMessaggio;
end if;
raise notice 'elabId=%',elabId::varchar;

strMessaggioFinale:='Elaborazione aggiornamento saldi sottoconti-vincolati  - fine.';   


outElabId:=elabId;
messaggioRisultato:=strMessaggioFinale;

return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;


        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outElabId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_siac_aggiorna_saldo_sottoconto_vincolo
(
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER to siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
(
  enteproprietarioid   integer,
  annoBilancioIniziale integer,
  annoBilancioFinale   integer,
  loginoperazione      varchar,
  dataelaborazione     timestamp,
  out outElabId integer,
  out codiceRisultato integer,
  out messaggioRisultato varchar
)
RETURNS record
 AS $body$
declare

strMessaggio VARCHAR(2500):=''; -- 09.10.2019 Sofia
strMessaggioFinale VARCHAR(1500):='';


elabId integer:=null;
elabRec record;
   

-- in apertura saldi sempre calcolati entrambi
RicalcoloSaldi varchar(1):='S';
tipoAggiornamento varchar(1):='E';

isSaldiAttivi integer:=null;

BEGIN
/*
 * APERTURA DI ESERCIZIO PROVVISORIO O DEFINITIVO DA BILANCIO APPROVATO
 * I SALDI DEI CONTI SONO RICALCOLATI AUTOMATICAMENTE SU ANNO BILANCIO IN CHIUSURA
 * GLI STESSI SALDI SONO RIPORTATATI COME INIZIALI SU ANNO BILANCIO+1 IN APERTURA
 * LA FNC di CALCOLO VIENE ESEGUITA SOLO IL PARAMETRO DI SISTEMA GEST_SALDO_SOTTO_CONTI_VINC SI TROVA SUL DB
 * IN QUESTE FASI I SALDI NON SONO RICALCOLABILI AUTOMATICAMENTE
 * QUINDI NON DEVONO ESSERE PRESENTI SALDI VALIDI - SE DEVONO ESSERE RICALCOLATI AUTOMATICAMENTE
 * BISOGNA PRIMA INVALIDARE MANUALMENTE  
 * IL RISULTATO DI QUESTA FNC NON DEVE MAI INVALIDARE ESITO DI APERTURA DEL BILANCIO COMPLESSIVO
 * RICHIAMATA DA fnc_fasi_bil_gest_apertura_all
 */
strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati da fase bilancio  - inizio.';
outElabId:=null;
codiceRisultato:=0;
messaggioRisultato:='';



raise notice '%',strMessaggioFinale;
raise notice 'annoBilancioIniziale=%',annoBilancioIniziale::varchar;
raise notice 'annoBilancioFinale=%',annoBilancioFinale::varchar;




select 1 into isSaldiAttivi
from siac_d_gestione_livello liv ,siac_d_gestione_tipo tipo 
where tipo.ente_proprietario_id =enteProprietarioId 
and   tipo.gestione_tipo_code ='SALDO_SOTTO_CONTI_VINC'
and   liv.gestione_tipo_id =tipo.gestione_tipo_id 
and   liv.gestione_livello_code ='GEST_SALDO_SOTTO_CONTI_VINC'
and   tipo.data_cancellazione  is null 
and   tipo.validita_fine is null
and   liv.data_cancellazione  is null 
and   liv.validita_fine is null; 

raise notice 'isSaldiAttivi=%',isSaldiAttivi::varchar;
-- se non attivo non si da errore ma non fa nulla sui saldi
if isSaldiAttivi is null then 
	messaggioRisultato:='Elaborazione calcolo saldi sottoconti-vincolati da fase bilancio - fine - gestione non attiva.';
    raise notice 'messaggioRisultato=%',messaggioRisultato::varchar;
	return;
end if;

elabRec:=null;
select * into elabRec
from 
fnc_siac_calcolo_saldo_sottoconto_vincolo
(
  enteproprietarioid,
  annoBilancioIniziale, -- anno in apertura
  annoBilancioFinale,   -- anno in chiusura
  ricalcoloSaldi, 	    -- true
  null,
  tipoAggiornamento,
  loginoperazione,
  dataelaborazione
);

raise notice 'elabRec.codiceRisultato=%',elabRec.codiceRisultato::varchar;
raise notice 'elabRec.messaggioRisultato=%',elabRec.messaggioRisultato::varchar;
strMessaggioFinale:='Elaborazione calcolo saldi sottoconti-vincolati da fase bilancio  - fine.';
if elabRec.codiceRisultato=0 then
    elabId:=elabRec.outElabId;
    messaggioRisultato:=strMessaggioFinale||' ELABORAZIONE OK.';
else
	messaggioRisultato:=strMessaggioFinale||' ELABORAZIONE KO.'|| elabRec.messaggioRisultato;
    codiceRisultato:=elabRec.codiceRisultato;
end if;

outElabId:=	elabId;
raise notice 'codiceRisultato=%',codiceRisultato::varchar;
raise notice 'messaggioRisultato=%',messaggioRisultato::varchar;
raise notice 'outElabId=%',outElabId::varchar;

return;
exception
    when RAISE_EXCEPTION THEN
        messaggioRisultato:=
        	coalesce(strMessaggioFinale,'')||coalesce(strMessaggio,'')||'ERRORE:  '||' '||coalesce(substring(upper(SQLERRM) from 1 for 500),'') ;
       	codiceRisultato:=-1;

		messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;


        return;
     when NO_DATA_FOUND THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Nessun dato presente in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
     when TOO_MANY_ROWS THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||' Diverse righe presenti in archivio.';
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
      	outElabId:=-1;
        return;
	when others  THEN
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE DB:'||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        messaggioRisultato:=upper(messaggioRisultato);
       	outElabId:=-1;
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


alter function siac.fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
(
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER to siac;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  annobilancio           integer,
  faseBilancio           varchar,
  stepPartenza           integer,
  checkGest              boolean,
  impostaImporti         boolean,
  enteproprietarioid     integer,
  loginoperazione        varchar,
  dataelaborazione       timestamp,
  out faseBilElabIdRet   integer,
  out codicerisultato    integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

    faseBilElabId     integer:=null;

    strRec record;

    CAP_EP_STR          CONSTANT varchar:='CAP-EP';
    CAP_UP_STR          CONSTANT varchar:='CAP-UP';
    CAP_EG_STR          CONSTANT varchar:='CAP-EG';
    CAP_UG_STR          CONSTANT varchar:='CAP-UG';

    U_STR               CONSTANT varchar:='U';
    E_STR               CONSTANT varchar:='E';


BEGIN
	messaggioRisultato:='';
    codiceRisultato:=0;
    faseBilElabIdRet:=0;


	strMessaggioFinale:='Apertura bilancio gestione per Anno bilancio='||annoBilancio::varchar||
                        '. Fase Bilancio di apertura='||faseBilancio||'.';

    if not (stepPartenza=99 or stepPartenza>=1) then
        strMessaggio:='Step ri-partenza non corretto valori ammessi >=1 99.';
        codiceRisultato:=-1;
    end if;

    -- STEP 1 - capitoli di uscita eseguiro per stepPartenza 1, 99
    if stepPartenza=1 or stepPartenza=99 then
 	 strMessaggio:='Capitolo di uscita.';
     select * into strRec
     from fnc_fasi_bil_gest_apertura
     (annobilancio,
      U_STR,
      CAP_UP_STR,
      CAP_UG_STR,
      faseBilancio,
      checkGest,
      impostaImporti,
      enteProprietarioId,
      loginOperazione,
      dataElaborazione
     );
     if strRec.codiceRisultato=0 then
      	faseBilElabId:=strRec.faseBilElabIdRet;
     else
        strMessaggio:=strRec.messaggioRisultato;
        codiceRisultato:=strRec.codiceRisultato;
     end if;
   end if;

   -- STEP 2 - capitoli di entrata eseguiro per stepPartenza >=2
   if codiceRisultato=0 and stepPartenza>=2 then
    	strMessaggio:='Capitolo di entrata.';
    	select * into strRec
	    from fnc_fasi_bil_gest_apertura
    	(annobilancio,
	     E_STR,
    	 CAP_EP_STR,
	     CAP_EG_STR,
	     faseBilancio,
	     checkGest,
     	 impostaImporti,
	     enteProprietarioId,
    	 loginOperazione,
	     dataElaborazione
    	);
        if strRec.codiceRisultato=0 then
      		faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;
    end if;

    if codiceRisultato=0 then
    	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
        faseBilElabIdRet:=faseBilElabId;
    else
    	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;


    -- STEP 3 -- popolamento dei vincoli di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
		strMessaggio:='Ribaltamento vincoli.';
    	if faseBilancio = 'E' then
	    	select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('GEST-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		else
			select * into strRec from fnc_fasi_bil_gest_ribaltamento_vincoli ('PREV-GEST',annobilancio,enteproprietarioid,loginoperazione, dataelaborazione );
		end if;

	    if strRec.codiceRisultato=0 then
            faseBilElabId:=strRec.faseBilElabIdRet;
	    else
    	    strMessaggio:=strRec.messaggioRisultato;
        	codiceRisultato:=strRec.codiceRisultato;
	    end if;


    end if;

    -- STEP 4 -- popolamento dei programmi-cronop di gestione
    if codiceRisultato=0 and stepPartenza>=2 then
    	if faseBilancio = 'G' then
            strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di gestione da previsione corrente.';
        	select * into strRec
        	from fnc_fasi_bil_gest_apertura_programmi
	             (
				  annoBilancio,
				  enteProprietarioId,
				  'G',
				  loginOperazione,
				  dataElaborazione
                 );
            if  strRec.codiceRisultato!=0 then
            	strMessaggio:=strRec.messaggioRisultato;
        		codiceRisultato:=strRec.codiceRisultato;
            end if;
        end if;
    end if;

   -- 08.04.2022 Sofia SIAC-8017
    -- STEP 6 -- popolamento dei programmi-cronoprogrammi di previsione
	if codiceRisultato=0 and stepPartenza>=2 then    -- deve essere stato eseguito sia spesa che entrata
    	strMessaggio:='Ribaltamento Programmi-Cronoprogrammi di previsione da gestione precedente.';
       	select * into strRec
       	from fnc_fasi_bil_gest_apertura_saldo_sottoconto_vincolo
		(
	     enteProprietarioId,
	     annoBilancio,   -- iniziale
	     annoBilancio-1, -- finale
	     loginOperazione,
	     dataelaborazione);
--       if strRec.codiceRisultato!=0 then
--       	strMessaggio:=strRec.messaggioRisultato;
  --      codiceRisultato:=strRec.codiceRisultato;
    --   end if;
    end if;
    -- 08.04.2022 Sofia SIAC-8017
   
    if codiceRisultato=0 then
	   	messaggioRisultato:=strMessaggioFinale||' Elaborazione terminata con successo.';
	    faseBilElabIdRet:=faseBilElabId;
	else
	  	messaggioRisultato:=strMessaggioFinale||strMessaggio;
    end if;

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

ALTER FUNCTION siac.fnc_fasi_bil_gest_apertura_all
(
  integer,
  varchar,
  integer,
  boolean,
  boolean,
  integer,
  varchar,
  timestamp,
  out integer,
  out integer,
  out varchar
) OWNER TO siac;

-- SIAC-8017 - JOB - 22.04.2022 Sofia - fine 