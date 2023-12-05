/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/


--SIAC-8017-CMTO- sql per online INIZIO
select * from fnc_dba_add_column_params('siac_d_contotesoreria'::text, 'vincolato'::text, 'boolean'::text);
select * from fnc_dba_add_column_params('siac_d_contotesoreria'::text, 'per_ripianamento'::text, 'boolean'::text);

create table if not exists siac_r_ordinativo_contotes_nodisp(
	ord_contotes_id serial NOT NULL,
	ord_id integer NOT NULL,
	contotes_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id integer NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT pk_siac_r_ordinativo_contotes_nodisp PRIMARY KEY (ord_contotes_id),
	CONSTRAINT siac_d_contotesoreria_siac_r_ordinativo_contotes_nodisp FOREIGN KEY (contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_ordinativo_contotes_nodisp FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_t_ordinativo_siac_r_ordinativo_contotes_nodisp FOREIGN KEY (ord_id) REFERENCES siac.siac_t_ordinativo(ord_id)
);
select fnc_dba_create_index(
'siac_r_ordinativo_contotes_nodisp'::text,
  'idx_siac_r_ordinativo_contotes_nodisp_1'::text,
  'ord_id, contotes_id,  validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);
select fnc_dba_create_index(
'siac_r_ordinativo_contotes_nodisp'::text,
  'siac_r_ordinativo_contotes_nodisp_fk_ord_id_idx'::text,
  'ord_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_r_ordinativo_contotes_nodisp'::text,
  'siac_r_ordinativo_contotes_nodisp_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_r_ordinativo_contotes_nodisp'::text,
  'siac_r_ordinativo_contotes_nodisp_fk_contotes_id'::text,
  'contotes_id'::text,
  '',
  false
);

alter table siac.siac_r_ordinativo_contotes_nodisp  OWNER to siac;

create table if not exists siac_r_saldo_vincolo_sotto_conto(
	saldo_vincolo_conto_id serial NOT NULL,
	vincolo_id integer NOT NULL,
	contotes_id integer NOT NULL,
	saldo_iniziale numeric NULL,
	saldo_finale numeric NULL,
	saldo_iniziale numeric NULL,
	saldo_finale numeric NULL,
	bil_id integer NOT NULL,
	validita_inizio timestamp NOT NULL,
	validita_fine timestamp NULL,
	ente_proprietario_id integer NOT NULL,
	data_creazione timestamp NOT NULL DEFAULT now(),
	data_modifica timestamp NOT NULL DEFAULT now(),
	data_cancellazione timestamp NULL,
	login_operazione varchar(200) NOT NULL,
	CONSTRAINT siac_r_saldo_vincolo_sotto_conto_pk PRIMARY KEY (saldo_vincolo_conto_id),
	CONSTRAINT siac_d_contotesoreria_siac_r_saldo_vincolo_sotto_conto FOREIGN KEY (contotes_id) REFERENCES siac.siac_d_contotesoreria(contotes_id),
	CONSTRAINT siac_t_bil_siac_r_saldo_vincolo_sotto_conto FOREIGN KEY (bil_id) REFERENCES siac.siac_t_bil(bil_id),
	CONSTRAINT siac_t_ente_proprietario_siac_r_saldo_vincolo_sotto_conto FOREIGN KEY (ente_proprietario_id) REFERENCES siac.siac_t_ente_proprietario(ente_proprietario_id),
	CONSTRAINT siac_r_saldo_vincolo_sotto_conto_siac_t_vincolo FOREIGN KEY (vincolo_id) REFERENCES siac.siac_t_vincolo(vincolo_id)
);
alter table siac.siac_r_ordinativo_contotes_nodisp  OWNER to siac;


select fnc_dba_create_index(
'siac_r_saldo_vincolo_sotto_conto'::text,
  'idx_siac_r_saldo_vincolo_sotto_conto_1'::text,
  'vincolo_id, contotes_id, bil_id,  validita_inizio, ente_proprietario_id'::text,
  'data_cancellazione IS NULL',
  true
);
select fnc_dba_create_index(
'siac_r_saldo_vincolo_sotto_conto'::text,
  'siac_r_saldo_vincolo_sotto_conto_fk_vincolo_id_idx'::text,
  'vincolo_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_r_saldo_vincolo_sotto_conto'::text,
  'siac_r_saldo_vincolo_sotto_conto_fk_ente_proprietario_id_idx'::text,
  'ente_proprietario_id'::text,
  '',
  false
);
select fnc_dba_create_index(
'siac_r_saldo_vincolo_sotto_conto'::text,
  'siac_r_saldo_vincolo_sotto_conto_fk_contotes_id'::text,
  'contotes_id'::text,
  '',
  false
);

INSERT INTO siac_d_gestione_tipo (gestione_tipo_code, gestione_tipo_desc, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, to_timestamp('2022-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
CROSS JOIN (VALUES ('GESTIONE_CONTI_VINCOLATI', 'Gestione vincolata dei conti tesoreria')) AS tmp(code, descr)
WHERE NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_tipo dgt
	WHERE dgt.ente_proprietario_id = tep.ente_proprietario_id
	AND dgt.gestione_tipo_code = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_d_gestione_livello (gestione_livello_code, gestione_livello_desc, gestione_tipo_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT tmp.code, tmp.descr, dgt.gestione_tipo_id, to_timestamp('2022-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_tipo dgt ON dgt.ente_proprietario_id = tep.ente_proprietario_id
CROSS JOIN (VALUES ('TRUE',  'codice TRUE per abilitare FALSE per disabilitare', 'GESTIONE_CONTI_VINCOLATI')) AS tmp(code, descr, tipo)
WHERE dgt.gestione_tipo_code = tmp.tipo
AND NOT EXISTS (
	SELECT 1
	FROM siac_d_gestione_livello dgl
	WHERE dgl.ente_proprietario_id = tep.ente_proprietario_id
	AND dgl.gestione_tipo_id = dgt.gestione_tipo_id
	and dgl.gestione_livello_code  = tmp.code
)
ORDER BY tep.ente_proprietario_id, tmp.code;

INSERT INTO siac_r_gestione_ente (gestione_livello_id, validita_inizio, ente_proprietario_id, login_operazione)
SELECT dgl.gestione_livello_id, to_timestamp('2019-01-01', 'YYYY-MM-DD'), tep.ente_proprietario_id, 'admin'
FROM siac_t_ente_proprietario tep
JOIN siac_d_gestione_livello dgl ON dgl.ente_proprietario_id = tep.ente_proprietario_id
join siac_d_gestione_tipo tipo on tipo.gestione_tipo_id  = dgl.gestione_tipo_id 
CROSS JOIN (VALUES ('GESTIONE_CONTI_VINCOLATI', '01907990012')) AS tmp(livello, ente)
WHERE tep.codice_fiscale = tmp.ente
AND tipo.gestione_tipo_code = tmp.livello
AND NOT EXISTS (
	SELECT 1
	FROM siac_r_gestione_ente rge
	WHERE rge.ente_proprietario_id = tep.ente_proprietario_id
	AND rge.gestione_livello_id = dgl.gestione_livello_id
	AND rge.data_cancellazione IS NULL
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_disp_incassare_sottoconto_vincolo(
  contotes_id_in integer,
  elem_id_in integer,
  ente_proprietario_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
vincolo_id_cap int;
ripiano_vincolo_sottoconto numeric;
somma_ordinativi_pagamento_non_annullati numeric;
somma_ordinativi_incasso_non_annullati numeric;
disponibileincassare_sottoconto numeric;

TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_EG constant varchar:='CAP-EG';

BEGIN

disponibileincassare_sottoconto :=0.0; 

select rvincolo.vincolo_id into vincolo_id_cap
from siac_r_vincolo_bil_elem rvincolo
where rvincolo.elem_id = elem_id_in and 
rvincolo.ente_proprietario_id = ente_proprietario_id_in and 
rvincolo.data_cancellazione is null and
now() between rvincolo.validita_inizio and coalesce(rvincolo.validita_fine, now());

select rsaldo.ripiano_iniziale into ripiano_vincolo_sottoconto
from siac_r_saldo_vincolo_sotto_conto rsaldo
where rsaldo.vincolo_id = vincolo_id_cap and 
	rsaldo.contotes_id = contotes_id_in and
	rsaldo.data_cancellazione is null and
	now() between rsaldo.validita_inizio and coalesce(rsaldo.validita_fine, now());

with capitoli_uscita as (
	select cap.elem_id
	from siac_t_bil_elem cap,
		siac_d_bil_elem_tipo tipo_cap,
		siac_r_vincolo_bil_elem rvinc,
		siac_r_bil_elem_stato rst,
		siac_d_bil_elem_stato st
	where tipo_cap.elem_tipo_id  = cap.elem_tipo_id and
		rvinc.elem_id  = cap.elem_id and
		rst.elem_id  = cap.elem_id and
		st.elem_stato_id  = rst.elem_stato_id and
		rvinc.vincolo_id =vincolo_id_cap and
		--capitolo non annullato
		st.elem_stato_code <> 'A' and
		rvinc.ente_proprietario_id = ente_proprietario_id_in and 
		tipo_cap.elem_tipo_code = TIPO_CAP_UG and
		cap.data_cancellazione is null and
		now() between cap.validita_inizio and coalesce(cap.validita_fine, now()) and
		rvinc.data_cancellazione is null and
		now() between rvinc.validita_inizio and coalesce(rvinc.validita_fine, now()) and
		rst.data_cancellazione is null and
		now() between rst.validita_inizio and coalesce(rst.validita_fine, now()) and
		st.data_cancellazione is null and
		now() between st.validita_inizio and coalesce(st.validita_fine, now())
)
select coalesce(sum(ord_ts_det.ord_ts_det_importo), 0) into somma_ordinativi_pagamento_non_annullati
from siac_r_ordinativo_bil_elem rcap,
      siac_t_ordinativo_ts ord_ts,
      siac_t_ordinativo_ts_det ord_ts_det,
      siac_d_ordinativo_ts_det_tipo tipo_det,
      siac_t_ordinativo ordin,
      siac_d_ordinativo_stato st,
      siac_r_ordinativo_stato r_st, 
	  siac_d_contotesoreria conto_ord, 
	  capitoli_uscita
where 
    rcap.ord_id = ordin.ord_id and
    ord_ts_det.ord_ts_id = ord_ts.ord_ts_id and
    ord_ts_det.ord_ts_det_tipo_id = tipo_det.ord_ts_det_tipo_id and
    tipo_det.ord_ts_det_tipo_code = 'A' and
    ordin.ord_id = ord_ts.ord_id and
    ordin.ord_id = r_st.ord_id and
    r_st.ord_stato_id = st.ord_stato_id and
    conto_ord.contotes_id  = ordin.contotes_id and
	capitoli_uscita.elem_id = rcap.elem_id and 
    --ordinativi sul conto 100
    conto_ord.per_ripianamento =true and 
    --ordinativi emessi (quietanzate ed emesse escluse le annullate, 
	--verificare cosa effettivamente si intenda 
    st.ord_stato_code != 'A' and
	exists (
      select 1 
      from siac_r_ordinativo_contotes_nodisp rdisp, 
	  	siac_d_contotesoreria conto_vinc
	  where conto_vinc.contotes_id = rdisp.contotes_id and
	  rdisp.contotes_id = contotes_id_in and 
	  rdisp.ord_id = ordin.ord_id and
      rdisp.data_cancellazione  is null and
	  conto_vinc.vincolato = true and
      now() between st.validita_inizio and coalesce(st.validita_fine, now())
	) and
    rcap.data_cancellazione is null and
    now() between rcap.validita_inizio and coalesce(rcap.validita_fine, now()) and
    ord_ts.data_cancellazione is null and
    now() between ord_ts.validita_inizio and coalesce(ord_ts.validita_fine, now()) and
    ord_ts_det.data_cancellazione is null and
    now() between ord_ts_det.validita_inizio and coalesce(ord_ts_det.validita_fine, now()) and
    tipo_det.data_cancellazione is null and
    now() between tipo_det.validita_inizio and coalesce(tipo_det.validita_fine, now()) and
    ordin.data_cancellazione is null and 
    now() between ordin.validita_inizio and coalesce(ordin.validita_fine, now()) and
    st.data_cancellazione is null and
    now() between st.validita_inizio and coalesce(st.validita_fine, now()) and
    r_st.data_cancellazione is null and 
	now() between r_st.validita_inizio and coalesce(r_st.validita_fine, now())
    ;  

with capitoli_entrata as (
	select cap.elem_id
	from siac_t_bil_elem cap,
		siac_d_bil_elem_tipo tipo_cap,
		siac_r_vincolo_bil_elem rvinc,
		siac_r_bil_elem_stato rst,
		siac_d_bil_elem_stato st
	where tipo_cap.elem_tipo_id  = cap.elem_tipo_id and
		rvinc.elem_id  = cap.elem_id and
		rst.elem_id  = cap.elem_id and
		st.elem_stato_id  = rst.elem_stato_id and
		rvinc.vincolo_id =vincolo_id_cap and
		--capitolo non annullato
		st.elem_stato_code <> 'A' and
		rvinc.ente_proprietario_id = ente_proprietario_id_in and 
		tipo_cap.elem_tipo_code = TIPO_CAP_EG and
		cap.data_cancellazione is null and
		now() between cap.validita_inizio and coalesce(cap.validita_fine, now()) and
		rvinc.data_cancellazione is null and
		now() between rvinc.validita_inizio and coalesce(rvinc.validita_fine, now()) and
		rst.data_cancellazione is null and
		now() between rst.validita_inizio and coalesce(rst.validita_fine, now()) and
		st.data_cancellazione is null and
		now() between st.validita_inizio and coalesce(st.validita_fine, now())
)
select coalesce(sum(ord_ts_det.ord_ts_det_importo), 0) into somma_ordinativi_incasso_non_annullati
from siac_r_ordinativo_bil_elem rcap,
      siac_t_ordinativo_ts ord_ts,
      siac_t_ordinativo_ts_det ord_ts_det,
      siac_d_ordinativo_ts_det_tipo tipo_det,
      siac_t_ordinativo ordin,
      siac_d_ordinativo_stato st,
      siac_r_ordinativo_stato r_st, 
	  siac_d_contotesoreria conto_ord, 
	  capitoli_entrata
where 
    rcap.ord_id = ordin.ord_id and
    ord_ts_det.ord_ts_id = ord_ts.ord_ts_id and
    ord_ts_det.ord_ts_det_tipo_id = tipo_det.ord_ts_det_tipo_id and
    tipo_det.ord_ts_det_tipo_code = 'A' and
    ordin.ord_id = ord_ts.ord_id and
    ordin.ord_id = r_st.ord_id and
    r_st.ord_stato_id = st.ord_stato_id and
    conto_ord.contotes_id  = ordin.contotes_id and
	capitoli_entrata.elem_id = rcap.elem_id and 
    --ordinativi sul conto 100
    conto_ord.per_ripianamento =true and 
    --ordinativi emessi (quietanzate ed emesse escluse le annullate, 
	--verificare cosa effettivamente si intenda 
    st.ord_stato_code != 'A' and
	exists (
      select 1 
      from siac_r_ordinativo_contotes_nodisp rdisp,

	       siac_d_contotesoreria conto_vinc
	  where conto_vinc.contotes_id = rdisp.contotes_id and
	  rdisp.contotes_id = contotes_id_in and 
	  rdisp.ord_id = ordin.ord_id and
      rdisp.data_cancellazione  is null and
	  conto_vinc.vincolato = true and
      now() between st.validita_inizio and coalesce(st.validita_fine, now())
	) and
    rcap.data_cancellazione is null and
    now() between rcap.validita_inizio and coalesce(rcap.validita_fine, now()) and
    ord_ts.data_cancellazione is null and
    now() between ord_ts.validita_inizio and coalesce(ord_ts.validita_fine, now()) and
    ord_ts_det.data_cancellazione is null and
    now() between ord_ts_det.validita_inizio and coalesce(ord_ts_det.validita_fine, now()) and
    tipo_det.data_cancellazione is null and
    now() between tipo_det.validita_inizio and coalesce(tipo_det.validita_fine, now()) and
    ordin.data_cancellazione is null and 
    now() between ordin.validita_inizio and coalesce(ordin.validita_fine, now()) and
    st.data_cancellazione is null and
    now() between st.validita_inizio and coalesce(st.validita_fine, now()) and
    r_st.data_cancellazione is null and 
	now() between r_st.validita_inizio and coalesce(r_st.validita_fine, now())
    ;  

if somma_ordinativi_pagamento_non_annullati is null then somma_ordinativi_pagamento_non_annullati:=0; end if;

if somma_ordinativi_incasso_non_annullati is null then somma_ordinativi_incasso_non_annullati:=0; end if;

if ripiano_vincolo_sottoconto is null then ripiano_vincolo_sottoconto:=0; end if;


disponibileincassare_sottoconto:=somma_ordinativi_incasso_non_annullati - somma_ordinativi_pagamento_non_annullati - abs(ripiano_vincolo_sottoconto);

return disponibileincassare_sottoconto;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_siac_disp_pagare_sottoconto_vincolo(
  contotes_id_in integer,
  elem_id_in integer,
  ente_proprietario_id_in integer
)
RETURNS numeric AS
$body$
DECLARE
vincolo_id_cap int;

saldo_vincolo_sottoconto numeric;
somma_ordinativi_pagamento_quietanzati numeric;
somma_ordinativi_pagamento_emessi numeric;
somma_ordinativi_incasso_quietanzati numeric;
disponibilepagare_sottoconto numeric;

TIPO_CAP_UG constant varchar:='CAP-UG';
TIPO_CAP_EG constant varchar:='CAP-EG';

BEGIN

disponibilepagare_sottoconto :=0.0; 

select  rvincolo.vincolo_id into vincolo_id_cap
from siac_r_vincolo_bil_elem rvincolo
where rvincolo.elem_id = elem_id_in and 
	rvincolo.data_cancellazione is null and
	rvincolo.ente_proprietario_id = ente_proprietario_id_in and 
	now() between rvincolo.validita_inizio and coalesce(rvincolo.validita_fine, now());


select rsaldo.saldo_iniziale into saldo_vincolo_sottoconto
from siac_r_saldo_vincolo_sotto_conto rsaldo
where rsaldo.vincolo_id = vincolo_id_cap and 
	rsaldo.contotes_id = contotes_id_in and
	rsaldo.data_cancellazione is null and
	now() between rsaldo.validita_inizio and coalesce(rsaldo.validita_fine, now());

with capitoli_uscita as (
	select cap.elem_id
	from siac_t_bil_elem cap,
		siac_d_bil_elem_tipo tipo_cap,
		siac_r_vincolo_bil_elem rvinc,
		siac_r_bil_elem_stato rst,
		siac_d_bil_elem_stato st
	where tipo_cap.elem_tipo_id  = cap.elem_tipo_id and
		rvinc.elem_id  = cap.elem_id and
		rst.elem_id  = cap.elem_id and
		st.elem_stato_id  = rst.elem_stato_id and
		rvinc.vincolo_id =vincolo_id_cap and
		rvinc.ente_proprietario_id = ente_proprietario_id_in and 
		--capitolo non annullato
		st.elem_stato_code <> 'A' and
		tipo_cap.elem_tipo_code = TIPO_CAP_UG and
		cap.data_cancellazione is null and
		now() between cap.validita_inizio and coalesce(cap.validita_fine, now()) and
		rvinc.data_cancellazione is null and
		now() between rvinc.validita_inizio and coalesce(rvinc.validita_fine, now()) and
		rst.data_cancellazione is null and
		now() between rst.validita_inizio and coalesce(rst.validita_fine, now()) and
		st.data_cancellazione is null and
		now() between st.validita_inizio and coalesce(st.validita_fine, now())
)
select coalesce(sum(ord_ts_det.ord_ts_det_importo), 0) into somma_ordinativi_pagamento_emessi
from siac_r_ordinativo_bil_elem rcap,
      siac_t_ordinativo_ts ord_ts,
      siac_t_ordinativo_ts_det ord_ts_det,
      siac_d_ordinativo_ts_det_tipo tipo_det,
      siac_t_ordinativo ordin,
      siac_d_ordinativo_stato st,
      siac_r_ordinativo_stato r_st, 
	  siac_d_contotesoreria conto_ord, 
	  capitoli_uscita
where 
    rcap.ord_id = ordin.ord_id and
    ord_ts_det.ord_ts_id = ord_ts.ord_ts_id and
    ord_ts_det.ord_ts_det_tipo_id = tipo_det.ord_ts_det_tipo_id and
    tipo_det.ord_ts_det_tipo_code = 'A' and
    ordin.ord_id = ord_ts.ord_id and
    ordin.ord_id = r_st.ord_id and
    r_st.ord_stato_id = st.ord_stato_id and
    conto_ord.contotes_id  = ordin.contotes_id and
	capitoli_uscita.elem_id = rcap.elem_id and 
    --ordinativi emessi (quietanzate ed emesse escluse le annullate, 
	--verificare cosa effettivamente si intenda 
    st.ord_stato_code not in ('A') and 
	conto_ord.contotes_id = contotes_id_in and
	conto_ord.vincolato = true and
    rcap.data_cancellazione is null and
    now() between rcap.validita_inizio and coalesce(rcap.validita_fine, now()) and
    ord_ts.data_cancellazione is null and
    now() between ord_ts.validita_inizio and coalesce(ord_ts.validita_fine, now()) and
    ord_ts_det.data_cancellazione is null and
    now() between ord_ts_det.validita_inizio and coalesce(ord_ts_det.validita_fine, now()) and
    tipo_det.data_cancellazione is null and
    now() between tipo_det.validita_inizio and coalesce(tipo_det.validita_fine, now()) and
    ordin.data_cancellazione is null and 
    now() between ordin.validita_inizio and coalesce(ordin.validita_fine, now()) and
    st.data_cancellazione is null and
    now() between st.validita_inizio and coalesce(st.validita_fine, now()) and
    r_st.data_cancellazione is null and 
	now() between r_st.validita_inizio and coalesce(r_st.validita_fine, now())
    ;  

with capitoli_entrata as (
	select cap.elem_id
	from siac_t_bil_elem cap,
		siac_d_bil_elem_tipo tipo_cap,
		siac_r_vincolo_bil_elem rvinc,
		siac_r_bil_elem_stato rst,
		siac_d_bil_elem_stato st
	where tipo_cap.elem_tipo_id  = cap.elem_tipo_id and
		rvinc.elem_id  = cap.elem_id and
		rst.elem_id  = cap.elem_id and
		st.elem_stato_id  = rst.elem_stato_id and
		rvinc.vincolo_id =vincolo_id_cap and
		rvinc.ente_proprietario_id = ente_proprietario_id_in and 
		--capitolo non annullato
		st.elem_stato_code <> 'A' and
		tipo_cap.elem_tipo_code = TIPO_CAP_EG and
		cap.data_cancellazione is null and
		now() between cap.validita_inizio and coalesce(cap.validita_fine, now()) and
		rvinc.data_cancellazione is null and
		now() between rvinc.validita_inizio and coalesce(rvinc.validita_fine, now()) and
		rst.data_cancellazione is null and
		now() between rst.validita_inizio and coalesce(rst.validita_fine, now()) and
		st.data_cancellazione is null and
		now() between st.validita_inizio and coalesce(st.validita_fine, now())
)
select coalesce(sum(ord_ts_det.ord_ts_det_importo), 0) into somma_ordinativi_incasso_quietanzati
from siac_r_ordinativo_bil_elem rcap,
      siac_t_ordinativo_ts ord_ts,
      siac_t_ordinativo_ts_det ord_ts_det,
      siac_d_ordinativo_ts_det_tipo tipo_det,
      siac_t_ordinativo ordin,
      siac_d_ordinativo_stato st,
      siac_r_ordinativo_stato r_st, 
	  siac_d_contotesoreria conto_ord, 
	  capitoli_entrata
where 
    rcap.ord_id = ordin.ord_id and
    ord_ts_det.ord_ts_id = ord_ts.ord_ts_id and
    ord_ts_det.ord_ts_det_tipo_id = tipo_det.ord_ts_det_tipo_id and
    tipo_det.ord_ts_det_tipo_code = 'A' and
    ordin.ord_id = ord_ts.ord_id and
    ordin.ord_id = r_st.ord_id and
    r_st.ord_stato_id = st.ord_stato_id and
    conto_ord.contotes_id  = ordin.contotes_id and
	capitoli_entrata.elem_id = rcap.elem_id and 
    --ordinativi emessi (quietanzate ed emesse escluse le annullate, 
	--verificare cosa effettivamente si intenda 
    st.ord_stato_code = 'Q' and
    conto_ord.contotes_id = contotes_id_in and
	conto_ord.vincolato = true and
    rcap.data_cancellazione is null and
    now() between rcap.validita_inizio and coalesce(rcap.validita_fine, now()) and
    ord_ts.data_cancellazione is null and
    now() between ord_ts.validita_inizio and coalesce(ord_ts.validita_fine, now()) and
    ord_ts_det.data_cancellazione is null and
    now() between ord_ts_det.validita_inizio and coalesce(ord_ts_det.validita_fine, now()) and
    tipo_det.data_cancellazione is null and
    now() between tipo_det.validita_inizio and coalesce(tipo_det.validita_fine, now()) and
    ordin.data_cancellazione is null and 
    now() between ordin.validita_inizio and coalesce(ordin.validita_fine, now()) and
    st.data_cancellazione is null and
    now() between st.validita_inizio and coalesce(st.validita_fine, now()) and
    r_st.data_cancellazione is null and 
	now() between r_st.validita_inizio and coalesce(r_st.validita_fine, now())
    ;  

if somma_ordinativi_pagamento_quietanzati is null then somma_ordinativi_pagamento_quietanzati:=0; end if;

if somma_ordinativi_incasso_quietanzati is null then somma_ordinativi_incasso_quietanzati:=0; end if;

if somma_ordinativi_pagamento_emessi is null then somma_ordinativi_pagamento_emessi:=0; end if;

if saldo_vincolo_sottoconto is null then saldo_vincolo_sottoconto:=0; end if;




disponibilepagare_sottoconto:=saldo_vincolo_sottoconto + somma_ordinativi_incasso_quietanzati - somma_ordinativi_pagamento_quietanzati - somma_ordinativi_pagamento_emessi;

return disponibilepagare_sottoconto;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

-- siac_8017 - SQL PER ONLINE FINE