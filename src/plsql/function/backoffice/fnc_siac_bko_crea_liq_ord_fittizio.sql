/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿

CREATE OR REPLACE FUNCTION siac.fnc_siac_bko_crea_liq_ord_fittizio (
anno_bilancio_in in varchar
)
RETURNS void AS
$body$
DECLARE
ini_validita timestamp;

login_op varchar;

begin
ini_validita:= ('01/01/'||anno_bilancio_in)::timestamp;
login_op:='admin'||to_char(now(),'yyyymmdd');

insert into siac_t_liquidazione
(liq_anno,liq_numero,liq_desc,liq_emissione_data,liq_importo,bil_id, validita_inizio,ente_proprietario_id, login_operazione)
select
9999,999999,'QUOTE DOC SPESA PAGATE',ini_validita,0,a.bil_id,ini_validita,a.ente_proprietario_id,login_op
from
siac_t_bil a, siac_t_periodo b
where a.periodo_id=b.periodo_id and
b.anno=anno_bilancio_in and
 not EXISTS
(select 1 from siac_t_liquidazione z where z.liq_anno=9999
and z.liq_numero=999999
and z.liq_desc='QUOTE DOC SPESA PAGATE'
and z.liq_emissione_data=ini_validita
and z.bil_id=a.bil_id
);

-- CREAZIONE ORDINATIVO FITTIZIO (TESTATA E RELATIVO TS)
insert into siac_t_ordinativo
(ord_anno, ord_numero,ord_desc,ord_tipo_id,ord_cast_cassa,ord_cast_competenza,ord_cast_emessi,ord_beneficiariomult,
ord_emissione_data,bil_id,validita_inizio,ente_proprietario_id, login_operazione, login_creazione)
select
9999,999999,'DOC QUOTE SPESA PAGATE',
d.ord_tipo_id,0,0,0,false,ini_validita,a.bil_id,
ini_validita,a.ente_proprietario_id
,login_op,login_op
from
siac_t_bil a, siac_t_periodo b,siac_d_ordinativo_tipo d
where a.periodo_id=b.periodo_id and
b.anno=anno_bilancio_in
and d.ente_proprietario_id=a.ente_proprietario_id
and d.ord_tipo_code = 'P'
and d.data_cancellazione is null
and date_trunc('day',now()) between date_trunc('day',d.validita_inizio) and coalesce( date_trunc('day',d.validita_fine),date_trunc('day',now()) )
and not exists
(select 1 from siac_t_ordinativo z
where
z.bil_id=a.bil_id AND z.ord_anno=9999 and z.ord_numero=999999 and z.ente_proprietario_id=a.ente_proprietario_id
and z.ord_tipo_id=d.ord_tipo_id
);

insert into siac_t_ordinativo
(ord_anno, ord_numero,ord_desc,ord_tipo_id,ord_cast_cassa,ord_cast_competenza,ord_cast_emessi,ord_beneficiariomult,
ord_emissione_data,bil_id,validita_inizio,ente_proprietario_id, login_operazione, login_creazione)
select
9999,999999,'DOC QUOTE ENTRATA INCASSATE',
d.ord_tipo_id,0,0,0,false,ini_validita,a.bil_id,
ini_validita,a.ente_proprietario_id
,login_op,login_op
from
siac_t_bil a, siac_t_periodo b,siac_d_ordinativo_tipo d
where a.periodo_id=b.periodo_id and
b.anno=anno_bilancio_in
and d.ente_proprietario_id=a.ente_proprietario_id
and d.ord_tipo_code = 'I'
and d.data_cancellazione is null
and date_trunc('day',now()) between date_trunc('day',d.validita_inizio) and coalesce( date_trunc('day',d.validita_fine),date_trunc('day',now()) )
and not exists
(select 1 from siac_t_ordinativo z
where
z.bil_id=a.bil_id AND z.ord_anno=9999 and z.ord_numero=999999 and z.ente_proprietario_id=a.ente_proprietario_id
and z.ord_tipo_id=d.ord_tipo_id
);

insert into siac_t_ordinativo_ts (ord_ts_code, ord_ts_desc,ord_id,validita_inizio,ente_proprietario_id, login_operazione)
select a.ord_numero::varchar,a.ord_desc,
a.ord_id,ini_validita,a.ente_proprietario_id,login_op
from siac_t_ordinativo a
, siac_d_ordinativo_tipo b
where
a.ord_tipo_id=b.ord_tipo_id and
b.ord_tipo_code='P' and
a.ord_desc='DOC QUOTE SPESA PAGATE' and a.ord_numero=999999
and b.data_cancellazione is null
and date_trunc('day',now()) between date_trunc('day',b.validita_inizio) and coalesce( date_trunc('day',b.validita_fine),date_trunc('day',now()) )
and not exists (select 1 FROM siac_t_ordinativo_ts z where z.ord_ts_code=a.ord_numero::varchar
and z.ord_ts_desc=a.ord_desc
and z.ord_id=a.ord_id and z.ente_proprietario_id=a.ente_proprietario_id)
;


insert into siac_t_ordinativo_ts (ord_ts_code, ord_ts_desc,ord_id,validita_inizio,ente_proprietario_id, login_operazione)
select a.ord_numero::varchar,a.ord_desc,
a.ord_id,ini_validita,a.ente_proprietario_id,login_op
from siac_t_ordinativo a
, siac_d_ordinativo_tipo b
where
a.ord_tipo_id=b.ord_tipo_id and
b.ord_tipo_code='I' and
a.ord_desc='DOC QUOTE ENTRATA INCASSATE' and a.ord_numero=999999
and b.data_cancellazione is null
and date_trunc('day',now()) between date_trunc('day',b.validita_inizio) and coalesce( date_trunc('day',b.validita_fine),date_trunc('day',now()) )
and not exists (select 1 FROM siac_t_ordinativo_ts z where z.ord_ts_code=a.ord_numero::varchar
and z.ord_ts_desc=a.ord_desc
and z.ord_id=a.ord_id and z.ente_proprietario_id=a.ente_proprietario_id)
;




exception
    when no_data_found THEN
        raise notice 'nessun valore trovato' ;
        return;
        when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',' altro errore',SQLSTATE,SQLERRM;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;


