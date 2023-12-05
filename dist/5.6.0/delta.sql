/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--SIAC-8017-CMTO- sql per online INIZIO
select * from fnc_dba_add_column_params('siac_d_contotesoreria'::text, 'vincolato'::text, 'boolean'::text);
select * from fnc_dba_add_column_params('siac_d_contotesoreria'::text, 'per_ripianamento'::text, 'boolean'::text);

update siac_d_contotesoreria set per_ripianamento = true where contotes_code = '0000100';

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
	ripiano_iniziale numeric NULL,
	ripiano_finale numeric NULL,
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
   data_cancellazione,
   login_operazione ,
   ente_proprietario_id 
)   
select 'GEST_SALDO_SOTTO_CONTI_VINC',
       'Calcolo automatico finale-iniziali in ape gestione',
       tipo.gestione_tipo_id ,
       now(),
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



-- SIAC-8640   Viste JPartecipate 26.04.2022 Haitham inizio

 create table if not exists siac_t_soc_partecipate
 (
  codice varchar(20) NOT NULL,
  nome varchar(500) NOT NULL,
  codice_fiscale varchar(16) null,
  partita_iva varchar(20) NULL
 );

 
insert into  siac_t_soc_partecipate (codice, nome, codice_fiscale, partita_iva )
select distinct 
       sog.soggetto_code, 
       sog.soggetto_desc,
       sog.codice_fiscale ,
       sog.partita_iva 
from siac_t_soggetto sog,
     siac_r_soggetto_stato rs,
     siac_d_soggetto_stato stato
where rs.soggetto_id = sog.soggetto_id 
and rs.soggetto_stato_id = stato.soggetto_stato_id 
--and stato.soggetto_stato_code not in ('ANNULLATO', 'BLOCCATO', 'SOSPESO')
--and stato.soggetto_stato_code = 'VALIDO'
and rs.data_cancellazione is null 
and rs.validita_fine is null 
and sog.codice_fiscale in (
    '00120490032',
    '00161450069',
    '00167340041',
    '00229020037',
    '03404440046',
    '00499000016',
    '00505900019',
    '00562650010',
    '00749090015',
    '00772450011',
    '00871010039',
    '00971620067',
    '01191650058',
    '01215120039',
    '01359310016',
    '01430400034',
    '01491490023',
    '01550320061',
    '01648650032',
    '01699930010',
    '01701830067',
    '01791360025',
    '01828300069',
    '01868740026',
    '01900780022',
    '01907070021',
    '01947660013',
    '01995120019',
    '02019530068',
    '02115110062',
    '02148710045',
    '02167450036',
    '02199110020',
    '02345150045',
    '02513140042',
    '02566350035',
    '02581260011',
    '02597450044',
    '02622940233',
    '02654340047',
    '02693930048',
    '02702400025',
    '02799890047',
    '02823950049',
    '02885170049',
    '03007420049',
    '03079030015',
    '03421950043',
    '03430040042',
    '03577780046',
    '03717710010',
    '03719310017',
    '04256970015',
    '04301050011',
    '04704500018',
    '04848010015',
    '05160100011',
    '05841010019',
    '06360270018',
    '06398410016',
    '06407440012',
    '06608260011',
    '06806680010',
    '07154400019',
    '07157100012',
    '07176380017',
    '07401840017',
    '07571460018',
    '07614800014',
    '07739430010',
    '07793080016',
    '07844090014',
    '08336420016',
    '08445410015',
    '08462090013',
    '08480110017',
    '08613620015',
    '08645111009',
    '08701850011',
    '08762960014',
    '08886870016',
    '08925090014',
    '09000640012',
    '09007180012',
    '09219460012',
    '09438920010',
    '09489220013',
    '09585670012',
    '09665690013',
    '09693360019',
    '09740180014',
    '09969560011',
    '80004290054',
    '80082050016',
    '80084650011',
    '80084690017',
    '80103360014',
    '82000990034',
    '82004870018',
    '83004360034',
    '90022960018',
    '90036020049',
    '91006800022',
    '92019680039',
    '92022260050',
    '92116650349',
    '93011210049',
    '93032990041',
    '94000090038',
    '94031260030',
    '94040690045',
    '94062420362',
    '94506780017',
    '94562210016',
    '95000120063',
    '96009220045',
    '96029620067',
    '96071910044',
    '96182010585',
    '97500570011',
    '97523990014',
    '97534070012',
    '97543620013',
    '97547570016',
    '97562370011',
    '97590910010',
    '97595380011',
    '97601340017',
    '97629700010',
    '97634160010',
    '97639830013',
    '97649340011',
    '97656000011',
    '97662370010',
    '97670460019',
    '97677210011',
    '97680850019',
    '97694170016',
    '97700560010',
    '97704430012',
    '97741140012',
    '97750400018',
    '97807600016',
    '97823270018',
    '97844290011',
    '97633910019',
    '05418960018'
  )
and sog.soggetto_code not in (select codice from siac_t_soc_partecipate);
  


-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------
-----------------------------------------------------------                      V_SIMOP_FATT_RICEV                     -----------------------------------------------------------
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------

CREATE OR REPLACE VIEW siac.V_SIMOP_FATT_RICEV
as WITH SAC as (select r.doc_id,
                       cl.classif_code as codice_sac
               from siac_r_doc_class r, 
                    siac_t_class cl,
                    siac_d_class_tipo tipo 
              where r.ente_proprietario_id = 2
                and r.classif_id = cl.classif_id 
                and cl.classif_tipo_id = tipo.classif_tipo_id 
                and tipo.classif_tipo_code  in ('CDC', 'CDR')
                and r.data_cancellazione is null
                and r.validita_fine  is null
               ),
        CUP AS ( 
				select sub.subdoc_id,
					   rattr.testo codice_CUP
				  from  siac_t_subdoc sub,
						siac_t_doc doc,
						siac_t_attr attr, 
						siac_r_subdoc_attr  rattr        
				where   sub.ente_proprietario_id = 2
                  and   sub.doc_id = doc.doc_id
				  and   rattr.subdoc_id = sub.subdoc_id 
				  and   rattr.testo is not null
				  and   rattr.testo != ''
				  and   attr.attr_id=rattr.attr_id
				  and   attr.attr_code='cup'
				  and   rattr.data_cancellazione is null
				  and   rattr.validita_fine  is null
                ),  
        CIG AS  ( 
				select sub.subdoc_id,
					   rattr.testo codice_CIG
				  from  siac_t_subdoc sub,
						siac_t_doc doc,
						siac_t_attr attr, 
						siac_r_subdoc_attr  rattr        
				where   sub.ente_proprietario_id = 2
                  and   sub.doc_id = doc.doc_id
				  and   rattr.subdoc_id = sub.subdoc_id 
				  and   rattr.testo is not null
				  and   rattr.testo != ''
				  and   attr.attr_id=rattr.attr_id
				  and   attr.attr_code='cig'
				  and   rattr.data_cancellazione is null
				  and   rattr.validita_fine is null
            ),
        impegno as (
               select  rimp.subdoc_id,
                       imp.movgest_anno,
                       imp.movgest_numero,
                       imp.movgest_subnumero
                from siac_r_subdoc_movgest_ts rimp,
                     siac_v_bko_impegno_valido imp
                where rimp.ente_proprietario_id = 2
                  and rimp.movgest_ts_id = imp.movgest_ts_id
                  and rimp.data_cancellazione is null
                  and rimp.validita_fine is null
             ),
        liquidazione as ( select rsubliq.subdoc_id,
                           liq.liq_anno,
                           liq.liq_numero,
                           liq.liq_importo
                    from siac_r_subdoc_liquidazione rsubliq,
                    siac_t_liquidazione liq
                    where rsubliq.ente_proprietario_id = 2
                      and rsubliq.liq_id = liq.liq_id
                      and rsubliq.data_cancellazione is null
                      and rsubliq.validita_fine  is null
                   ),
        mandato as (select rso.subdoc_id ,
                     mand.ord_anno , 
                     mand.ord_numero,
                     mand.ord_emissione_data, 
                     det.ord_ts_det_importo ImportoMandato
              from siac_t_ordinativo_ts_det det, 
                   siac_d_ordinativo_tipo tipo,
                   siac_t_ordinativo mand, 
                   siac_t_ordinativo_ts ts,
                   siac_r_subdoc_ordinativo_ts rso,
                   siac_d_ordinativo_ts_det_tipo tipoImporto
              where mand.ente_proprietario_id = 2
                and mand.ord_tipo_id = tipo.ord_tipo_id
                and tipo.ord_tipo_code = 'P'
                and mand.ord_id = ts.ord_id
                and ts.ord_ts_id = det.ord_ts_id
                and det.ord_ts_det_tipo_id = tipoImporto.ord_ts_det_tipo_id
                and tipoImporto.ord_ts_det_tipo_code = 'A'
                and ts.ord_ts_id  = rso.ord_ts_id 
                and rso.data_cancellazione is null
                and rso.validita_fine  is null
)
select distinct 
       sog.soggetto_code CODICE_ANAGRAFICO_FORNITORE, 
       sog.soggetto_desc NOME_PARTECIPATA,
       sog.codice_fiscale CODICE_FISCALE_PARTECIPATA,
       sog.partita_iva P_IVA_PARTECIPATA,
       'RE' STATO_DOCUMENTO,   
       ufficio.pccuff_code IPA_STRUTTURA_CAPITOLINA,
       SAC.codice_sac RESPONSABILE_PROCEDURA,
       doc.doc_sdi_lotto_siope IDENTIFICATIVO_SDI,
       to_char(doc.doc_data_emissione, 'YYYYMMDD') DATA_RICEZIONE_SDI,
       to_char(doc.data_creazione , 'YYYYMMDD') DATA_REGISTRAZIONE,
       tipo.doc_tipo_code TIPO_DOCUMENTO, 
       to_char(doc.doc_data_emissione, 'YYYYMMDD') DATA_FATTURA,
       doc.doc_numero N_FATTURA,
       doc.doc_anno ANNO_FATTURA,
       doc.doc_importo IMPORTO_TOTALE_FATTURA,
       ronere.importo_imponibile IMPORTO_IMPONIBILE,
       ivamov.ivamov_totale IMPORTO_IVA,
       sosp.subdoc_sosp_causale ,
       to_char(sosp.subdoc_sosp_data, 'YYYYMMDD') DATA_SOSPENSIONE,
       CIG.CODICE_CIG,
       CUP.CODICE_CUP ,
       impegno.movgest_anno ANNO_IMPEGNO,
       impegno.movgest_numero NUMERO_IMPEGNO,
       impegno.movgest_subnumero NUMERO_SUB_IMPEGNO,
       sub.subdoc_importo IMPORTO_RATA_FATTURA,  
        CASE
              WHEN sosp.subdoc_sosp_data != null  THEN 'CN'
                ELSE ''
        END AS CODICE_DI_NON_PAGABILITA,
       liquidazione.liq_anno ||'/'||liquidazione.liq_numero  NUMERO_LIQUIDAZIONE,
       liquidazione.liq_importo IMPORTO_LIQUIDATO,
        CASE
              WHEN to_char(mandato.ord_emissione_data, 'YYYY') = to_char(sub.data_creazione, 'YYYY')  THEN mandato.ImportoMandato
                ELSE 0
        END AS IMPORTO_PAGATO_ENTRO,
        CASE
              WHEN to_char(mandato.ord_emissione_data, 'YYYY') != to_char(sub.data_creazione, 'YYYY')  THEN mandato.ImportoMandato
                ELSE 0
        END AS IMPORTO_PAGATO_OLTRE,
       mandato.ord_emissione_data,
       mandato.ord_numero NUMERO_MANDATO,
       sub.subdoc_numero ID,
        CASE
              WHEN stato.doc_stato_code = 'EM'  THEN to_char(stato.data_creazione, 'YYYYMMDD')
                ELSE NULL
        END AS DATA_CHIUSURA
from siac_d_doc_tipo tipo,
     siac_d_doc_fam_tipo fam,
     siac_r_doc_sog rsog,
     siac_t_soggetto sog,
     siac_t_soc_partecipate part,
     siac_r_doc_stato rs,
     siac_d_doc_stato stato,
     siac_t_doc doc     
left join siac_d_pcc_ufficio ufficio on doc.pccuff_id = ufficio.pccuff_id 
left join SAC on doc.doc_id = SAC.doc_id
left JOIN siac_r_doc_onere ronere ON doc.doc_id = ronere.doc_id
                                             and ronere.data_cancellazione is null
                                             and ronere.validita_fine is null
left JOIN siac_r_doc_iva riva ON doc.doc_id = riva.doc_id
                                             and riva.data_cancellazione is null
                                             and riva.validita_fine is null                                             
left JOIN siac_t_subdoc_iva subiva on riva.dociva_r_id = subiva.dociva_r_id
left JOIN siac_r_ivamov rimavo on  subiva.subdociva_id = rimavo.subdociva_id 
                                             and rimavo.data_cancellazione is null
                                             and rimavo.validita_fine is null
left JOIN siac_t_ivamov ivamov on rimavo.ivamov_id = ivamov.ivamov_id
left JOIN siac_t_subdoc sub ON doc.doc_id = sub.doc_id
left join CIG on sub.subdoc_id = CIG.subdoc_id
left join CUP on sub.subdoc_id = CUP.subdoc_id
left join siac_t_subdoc_sospensione sosp on sub.subdoc_id = sosp.subdoc_id
left join impegno on sub.subdoc_id = impegno.subdoc_id
left join liquidazione on sub.subdoc_id = liquidazione.subdoc_id
left join mandato on sub.subdoc_id = mandato.subdoc_id
where  doc.ente_proprietario_id=2
  and  doc.doc_tipo_id=tipo.doc_tipo_id
  and  tipo.doc_tipo_code  = 'FAT'
  and  tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id 
  and fam.doc_fam_tipo_code = 'S'
  and  rsog.doc_id=doc.doc_id
  and  sog.soggetto_id=rsog.soggetto_id
  and  sog.soggetto_code = part.codice  
  and  rs.doc_id = doc.doc_id 
  and  rs.doc_stato_id = stato.doc_stato_id 
  and  stato.doc_stato_code != 'A'
  and  rsog.data_cancellazione is null
  and  rsog.validita_fine is null
  and  rs.data_cancellazione is null
  and  rs.validita_fine is null;  

 
 
 
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------
-----------------------------------------------------------                      V_SIMOP_FATT_DARICEV                   -----------------------------------------------------------
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------
 
CREATE OR REPLACE VIEW siac.V_SIMOP_FATT_DARICEV
as select distinct 
       sog.soggetto_code CODICE_ANAGRAFICO_FORNITORE, 
       sog.soggetto_desc NOME_PARTECIPATA,
       sog.codice_fiscale CODICE_FISCALE_PARTECIPATA,
       sog.partita_iva P_IVA_PARTECIPATA,
       'RE' STATO_DOCUMENTO,  
       fat.codice_destinatario IPA_STRUTTURA_CAPITOLINA,
       ' ' RESPONSABILE_PROCEDURA,
       portale.identificativo_sdi IDENTIFICATIVO_SDI,
       '' PROGRESSIVO_INVIO_SDI,
       '' DATA_RICEZIONE_SDI,
       '' DATA_REGISTRAZIONE,
       '' TIPO_DOCUMENTO,
       '' DATA_FATTURA,
       fat.numero N_FATTURA,       
       to_char(fat.data, 'YYYY')  ANNO_FATTURA,
       fat.importo_totale_documento  IMPORTO_TOTALE_FATTURA,
       fat.importo_totale_netto IMPORTO_IMPONIBILE,
       (fat.importo_totale_documento - fat.importo_totale_netto)  IMPORTO_IVA,
       '' CODICE_SOSPENSIONE ,
       '' DATA_SOSPENSIONE,
       '' CODICE_CIG,
       '' CODICE_CUP ,
       '' ANNO_IMPEGNO,
       '' NUMERO_IMPEGNO,
       '' NUMERO_SUB_IMPEGNO,
       '' IMPORTO_RATA_FATTURA,  
       '' CODICE_DI_NON_PAGABILITA,
       ''  NUMERO_LIQUIDAZIONE,
       '' IMPORTO_LIQUIDATO,
       '' IMPORTO_PAGATO_ENTRO,
       '' IMPORTO_PAGATO_OLTRE,
       '' NUMERO_MANDATO,
       '' ID,
       '' DATA_CHIUSURA
     from sirfel_t_fattura fat,
          siac_t_soc_partecipate part,
          siac_t_soggetto sog,
          sirfel_t_prestatore stp,
          sirfel_t_portale_fatture portale
where  fat.stato_fattura = 'N'
and stp.id_prestatore = fat.id_prestatore 
and portale.id_fattura = fat.id_fattura 
and   portale.esito_utente_codice = part.codice_fiscale 
and   portale.esito_utente_codice = sog.codice_fiscale 
        

  ; -- ALE FIX

 
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------
-----------------------------------------------------------                      V_SIMOP_FATT_POSDEB                    -----------------------------------------------------------
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------

CREATE OR REPLACE VIEW siac.V_SIMOP_FATT_POSDEB
as WITH SAC as (select r.doc_id,
                       cl.classif_code as codice_sac
               from siac_r_doc_class r, 
                    siac_t_class cl,
                    siac_d_class_tipo tipo 
              where r.ente_proprietario_id = 2
                and r.classif_id = cl.classif_id 
                and cl.classif_tipo_id = tipo.classif_tipo_id 
                and tipo.classif_tipo_code  in ('CDC', 'CDR')
                and r.data_cancellazione is null
                and r.validita_fine  is null
               ),
        CUP AS ( 
				select sub.subdoc_id,
					   rattr.testo codice_CUP
				  from  siac_t_subdoc sub,
						siac_t_doc doc,
						siac_t_attr attr, 
						siac_r_subdoc_attr  rattr        
				where   sub.ente_proprietario_id = 2
                  and   sub.doc_id = doc.doc_id
				  and   rattr.subdoc_id = sub.subdoc_id 
				  and   rattr.testo is not null
				  and   rattr.testo != ''
				  and   attr.attr_id=rattr.attr_id
				  and   attr.attr_code='cup'
				  and   rattr.data_cancellazione is null
				  and   rattr.validita_fine  is null
                ),  
        CIG AS  ( 
				select sub.subdoc_id,
					   rattr.testo codice_CIG
				  from  siac_t_subdoc sub,
						siac_t_doc doc,
						siac_t_attr attr, 
						siac_r_subdoc_attr  rattr        
				where   sub.ente_proprietario_id = 2
                  and   sub.doc_id = doc.doc_id
				  and   rattr.subdoc_id = sub.subdoc_id 
				  and   rattr.testo is not null
				  and   rattr.testo != ''
				  and   attr.attr_id=rattr.attr_id
				  and   attr.attr_code='cig'
				  and   rattr.data_cancellazione is null
				  and   rattr.validita_fine is null
            ),
        impegno as (
               select  rimp.subdoc_id,
                       imp.movgest_anno,
                       imp.movgest_numero,
                       imp.movgest_subnumero
                from siac_r_subdoc_movgest_ts rimp,
                     siac_v_bko_impegno_valido imp
                where rimp.ente_proprietario_id = 2
                  and rimp.movgest_ts_id = imp.movgest_ts_id
                  and rimp.data_cancellazione is null
                  and rimp.validita_fine is null
             ),
        liquidazione as ( select rsubliq.subdoc_id,
                           liq.liq_anno,
                           liq.liq_numero,
                           liq.liq_importo
                    from siac_r_subdoc_liquidazione rsubliq,
                    siac_t_liquidazione liq
                    where rsubliq.ente_proprietario_id = 2
                      and rsubliq.liq_id = liq.liq_id
                      and rsubliq.data_cancellazione is null
                      and rsubliq.validita_fine  is null
                   ),
        mandato as (select rso.subdoc_id ,
                     mand.ord_anno , 
                     mand.ord_numero,
                     mand.ord_emissione_data, 
                     det.ord_ts_det_importo ImportoMandato
              from siac_t_ordinativo_ts_det det, 
                   siac_d_ordinativo_tipo tipo,
                   siac_t_ordinativo mand, 
                   siac_t_ordinativo_ts ts,
                   siac_r_subdoc_ordinativo_ts rso,
                   siac_d_ordinativo_ts_det_tipo tipoImporto
              where mand.ente_proprietario_id = 2
                and mand.ord_tipo_id = tipo.ord_tipo_id
                and tipo.ord_tipo_code = 'P'
                and mand.ord_id = ts.ord_id
                and ts.ord_ts_id = det.ord_ts_id
                and det.ord_ts_det_tipo_id = tipoImporto.ord_ts_det_tipo_id
                and tipoImporto.ord_ts_det_tipo_code = 'A'
                and ts.ord_ts_id  = rso.ord_ts_id 
                and rso.data_cancellazione is null
                and rso.validita_fine  is null
)
select distinct 
       sog.soggetto_code CODICE_ANAGRAFICO_FORNITORE, 
       sog.soggetto_desc NOME_PARTECIPATA,
       sog.codice_fiscale CODICE_FISCALE_PARTECIPATA,
       sog.partita_iva P_IVA_PARTECIPATA,
       'RE' STATO_DOCUMENTO,  --stato.doc_stato_code, 
       ufficio.pccuff_code IPA_STRUTTURA_CAPITOLINA,
       SAC.codice_sac RESPONSABILE_PROCEDURA,
       doc.doc_sdi_lotto_siope IDENTIFICATIVO_SDI,
       to_char(doc.doc_data_emissione, 'YYYYMMDD') DATA_RICEZIONE_SDI,
       to_char(doc.data_creazione , 'YYYYMMDD') DATA_REGISTRAZIONE,
       tipo.doc_tipo_code TIPO_DOCUMENTO, 
       to_char(doc.doc_data_emissione, 'YYYYMMDD') DATA_FATTURA,
       doc.doc_numero N_FATTURA,
       doc.doc_anno ANNO_FATTURA,
       doc.doc_importo IMPORTO_TOTALE_FATTURA,
       ronere.importo_imponibile IMPORTO_IMPONIBILE,
       ivamov.ivamov_totale IMPORTO_IVA,
       sosp.subdoc_sosp_causale ,
       to_char(sosp.subdoc_sosp_data, 'YYYYMMDD') DATA_SOSPENSIONE,
       CIG.CODICE_CIG,
       CUP.CODICE_CUP ,
       impegno.movgest_anno ANNO_IMPEGNO,
       impegno.movgest_numero NUMERO_IMPEGNO,
       impegno.movgest_subnumero NUMERO_SUB_IMPEGNO,
       sub.subdoc_importo IMPORTO_RATA_FATTURA,  
        CASE
              WHEN sosp.subdoc_sosp_data != null  THEN 'CN'
                ELSE ''
        END AS CODICE_DI_NON_PAGABILITA,
       liquidazione.liq_anno ||'/'||liquidazione.liq_numero  NUMERO_LIQUIDAZIONE,
       liquidazione.liq_importo IMPORTO_LIQUIDATO,
        CASE
              WHEN to_char(mandato.ord_emissione_data, 'YYYY') = to_char(sub.data_creazione, 'YYYY')  THEN mandato.ImportoMandato
                ELSE 0
        END AS IMPORTO_PAGATO_ENTRO,
        CASE
              WHEN to_char(mandato.ord_emissione_data, 'YYYY') != to_char(sub.data_creazione, 'YYYY')  THEN mandato.ImportoMandato
                ELSE 0
        END AS IMPORTO_PAGATO_OLTRE,
       mandato.ord_emissione_data,
       mandato.ord_numero NUMERO_MANDATO,
       sub.subdoc_numero ID,
        CASE
              WHEN stato.doc_stato_code = 'EM'  THEN to_char(stato.data_creazione, 'YYYYMMDD')
                ELSE NULL
        END AS DATA_CHIUSURA
from siac_d_doc_tipo tipo,
     siac_d_doc_fam_tipo fam,
     siac_r_doc_sog rsog,
     siac_t_soggetto sog,
     siac_t_soc_partecipate part,
     siac_r_doc_stato rs,
     siac_d_doc_stato stato,
     siac_t_doc doc     
left join siac_d_pcc_ufficio ufficio on doc.pccuff_id = ufficio.pccuff_id 
left join SAC on doc.doc_id = SAC.doc_id
left JOIN siac_r_doc_onere ronere ON doc.doc_id = ronere.doc_id
                                             and ronere.data_cancellazione is null
                                             and ronere.validita_fine is null
left JOIN siac_r_doc_iva riva ON doc.doc_id = riva.doc_id
                                             and riva.data_cancellazione is null
                                             and riva.validita_fine is null                                             
left JOIN siac_t_subdoc_iva subiva on riva.dociva_r_id = subiva.dociva_r_id
left JOIN siac_r_ivamov rimavo on  subiva.subdociva_id = rimavo.subdociva_id 
                                             and rimavo.data_cancellazione is null
                                             and rimavo.validita_fine is null
left JOIN siac_t_ivamov ivamov on rimavo.ivamov_id = ivamov.ivamov_id
left JOIN siac_t_subdoc sub ON doc.doc_id = sub.doc_id
left join CIG on sub.subdoc_id = CIG.subdoc_id
left join CUP on sub.subdoc_id = CUP.subdoc_id
left join siac_t_subdoc_sospensione sosp on sub.subdoc_id = sosp.subdoc_id
left join impegno on sub.subdoc_id = impegno.subdoc_id
left join liquidazione on sub.subdoc_id = liquidazione.subdoc_id
left join mandato on sub.subdoc_id = mandato.subdoc_id
where  doc.ente_proprietario_id=2
  and  doc.doc_tipo_id=tipo.doc_tipo_id
  and  tipo.doc_tipo_code  != 'FAT'
  and  tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id 
  and fam.doc_fam_tipo_code = 'S'
  and  rsog.doc_id=doc.doc_id
  and  sog.soggetto_id=rsog.soggetto_id
  and  sog.soggetto_code = part.codice  
  and  rs.doc_id = doc.doc_id 
  and  rs.doc_stato_id = stato.doc_stato_id 
  and  stato.doc_stato_code != 'A'
  and  rsog.data_cancellazione is null
  and  rsog.validita_fine is null
  and  rs.data_cancellazione is null
  and  rs.validita_fine is null;  

 

 
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------
-----------------------------------------------------------                      V_SIMOP_FATT_POSCRE                    -----------------------------------------------------------
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------

CREATE OR REPLACE VIEW siac.V_SIMOP_FATT_POSCRE
as WITH SAC as (select r.doc_id,
                       cl.classif_code as codice_sac
               from siac_r_doc_class r, 
                    siac_t_class cl,
                    siac_d_class_tipo tipo 
              where r.ente_proprietario_id = 2
                and r.classif_id = cl.classif_id 
                and cl.classif_tipo_id = tipo.classif_tipo_id 
                and tipo.classif_tipo_code  in ('CDC', 'CDR')
                and r.data_cancellazione is null
                and r.validita_fine  is null
               ),
        CUP AS ( 
				select sub.subdoc_id,
					   rattr.testo codice_CUP
				  from  siac_t_subdoc sub,
						siac_t_doc doc,
						siac_t_attr attr, 
						siac_r_subdoc_attr  rattr        
				where   sub.ente_proprietario_id = 2
                  and   sub.doc_id = doc.doc_id
				  and   rattr.subdoc_id = sub.subdoc_id 
				  and   rattr.testo is not null
				  and   rattr.testo != ''
				  and   attr.attr_id=rattr.attr_id
				  and   attr.attr_code='cup'
				  and   rattr.data_cancellazione is null
				  and   rattr.validita_fine  is null
                ),  
        CIG AS  ( 
				select sub.subdoc_id,
					   rattr.testo codice_CIG
				  from  siac_t_subdoc sub,
						siac_t_doc doc,
						siac_t_attr attr, 
						siac_r_subdoc_attr  rattr        
				where   sub.ente_proprietario_id = 2
                  and   sub.doc_id = doc.doc_id
				  and   rattr.subdoc_id = sub.subdoc_id 
				  and   rattr.testo is not null
				  and   rattr.testo != ''
				  and   attr.attr_id=rattr.attr_id
				  and   attr.attr_code='cig'
				  and   rattr.data_cancellazione is null
				  and   rattr.validita_fine is null
            ),
        accertamento as (
               select  rimp.subdoc_id,
                       imp.movgest_anno,
                       imp.movgest_numero,
                       imp.movgest_subnumero
                from siac_r_subdoc_movgest_ts rimp,
                     siac_v_bko_accertamento_valido imp
                where rimp.ente_proprietario_id = 2
                  and rimp.movgest_ts_id = imp.movgest_ts_id
                  and rimp.data_cancellazione is null
                  and rimp.validita_fine is null
             ),
        reversale as (select rso.subdoc_id ,
                     rev.ord_anno , 
                     rev.ord_numero,
                     rev.ord_emissione_data, 
                     det.ord_ts_det_importo Importoreversale
              from siac_t_ordinativo_ts_det det, 
                   siac_d_ordinativo_tipo tipo,
                   siac_t_ordinativo rev, 
                   siac_t_ordinativo_ts ts,
                   siac_r_subdoc_ordinativo_ts rso,
                   siac_d_ordinativo_ts_det_tipo tipoImporto
              where rev.ente_proprietario_id = 2
                and rev.ord_tipo_id = tipo.ord_tipo_id
                and tipo.ord_tipo_code = 'P'
                and rev.ord_id = ts.ord_id
                and ts.ord_ts_id = det.ord_ts_id
                and det.ord_ts_det_tipo_id = tipoImporto.ord_ts_det_tipo_id
                and tipoImporto.ord_ts_det_tipo_code = 'A'
                and ts.ord_ts_id  = rso.ord_ts_id 
                and rso.data_cancellazione is null
                and rso.validita_fine  is null
)
select distinct 
       sog.soggetto_code CODICE_ANAGRAFICO_FORNITORE, 
       sog.soggetto_desc NOME_PARTECIPATA,
       sog.codice_fiscale CODICE_FISCALE_PARTECIPATA,
       sog.partita_iva P_IVA_PARTECIPATA,
       'RE' STATO_DOCUMENTO,   
       ufficio.pccuff_code IPA_STRUTTURA_CAPITOLINA,
       SAC.codice_sac RESPONSABILE_PROCEDURA,
       doc.doc_sdi_lotto_siope IDENTIFICATIVO_SDI,
       to_char(doc.doc_data_emissione, 'YYYYMMDD') DATA_RICEZIONE_SDI,
       to_char(doc.data_creazione , 'YYYYMMDD') DATA_REGISTRAZIONE,
       tipo.doc_tipo_code TIPO_DOCUMENTO, 
       to_char(doc.doc_data_emissione, 'YYYYMMDD') DATA_FATTURA,
       doc.doc_numero N_FATTURA,
       doc.doc_anno ANNO_FATTURA,
       doc.doc_importo IMPORTO_TOTALE_FATTURA,
       ronere.importo_imponibile IMPORTO_IMPONIBILE,
       ivamov.ivamov_totale IMPORTO_IVA,
       CIG.CODICE_CIG,
       CUP.CODICE_CUP ,
       accertamento.movgest_anno ANNO_accertamento,
       accertamento.movgest_numero NUMERO_accertamento,
       accertamento.movgest_subnumero NUMERO_SUB_accertamento,
       sub.subdoc_importo IMPORTO_RATA_FATTURA,  
        CASE
              WHEN to_char(reversale.ord_emissione_data, 'YYYY') = to_char(sub.data_creazione, 'YYYY')  THEN reversale.Importoreversale
                ELSE 0
        END AS IMPORTO_REVERSALE_ENTRO,
        CASE
              WHEN to_char(reversale.ord_emissione_data, 'YYYY') != to_char(sub.data_creazione, 'YYYY')  THEN reversale.Importoreversale
                ELSE 0
        END AS IMPORTO_REVERSALE_OLTRE,
       sub.subdoc_numero ID,
        CASE
              WHEN stato.doc_stato_code = 'EM'  THEN to_char(stato.data_creazione, 'YYYYMMDD')
                ELSE null                
        END AS DATA_CHIUSURA
from siac_d_doc_tipo tipo,
     siac_d_doc_fam_tipo fam,
     siac_r_doc_sog rsog,
     siac_t_soggetto sog,
     siac_t_soc_partecipate part,
     siac_r_doc_stato rs,
     siac_d_doc_stato stato,
     siac_t_doc doc     
left join siac_d_pcc_ufficio ufficio on doc.pccuff_id = ufficio.pccuff_id 
left join SAC on doc.doc_id = SAC.doc_id
left JOIN siac_r_doc_onere ronere ON doc.doc_id = ronere.doc_id
                                             and ronere.data_cancellazione is null
                                             and ronere.validita_fine is null
left JOIN siac_r_doc_iva riva ON doc.doc_id = riva.doc_id
                                             and riva.data_cancellazione is null
                                             and riva.validita_fine is null                                             
left JOIN siac_t_subdoc_iva subiva on riva.dociva_r_id = subiva.dociva_r_id
left JOIN siac_r_ivamov rimavo on  subiva.subdociva_id = rimavo.subdociva_id 
                                             and rimavo.data_cancellazione is null
                                             and rimavo.validita_fine is null
left JOIN siac_t_ivamov ivamov on rimavo.ivamov_id = ivamov.ivamov_id
left JOIN siac_t_subdoc sub ON doc.doc_id = sub.doc_id 
                           and sub.data_cancellazione is null
                           and sub.validita_fine is null
left join CIG on sub.subdoc_id = CIG.subdoc_id
left join CUP on sub.subdoc_id = CUP.subdoc_id
left join accertamento on sub.subdoc_id = accertamento.subdoc_id
left join reversale on sub.subdoc_id = reversale.subdoc_id
where  doc.ente_proprietario_id=2
  and  doc.doc_tipo_id=tipo.doc_tipo_id
  and  tipo.doc_fam_tipo_id = fam.doc_fam_tipo_id 
  and fam.doc_fam_tipo_code = 'E'
  and  rsog.doc_id=doc.doc_id
  and  sog.soggetto_id=rsog.soggetto_id
  and  sog.soggetto_code = part.codice  
  and  rs.doc_id = doc.doc_id 
  and  rs.doc_stato_id = stato.doc_stato_id 
  and  stato.doc_stato_code != 'A'
  and  rsog.data_cancellazione is null
  and  rsog.validita_fine is null
  and  rs.data_cancellazione is null
  and  rs.validita_fine is null;  



 
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------
-----------------------------------------------------------                      V_SIMOP_RESIDUI_PASSIVI                -----------------------------------------------------------
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------

CREATE OR REPLACE VIEW siac.V_SIMOP_RESIDUI_PASSIVI
as WITH SAC as (select r.movgest_ts_id,
                       cl.classif_code as codice_sac
               from siac_r_movgest_class r,
                    siac_t_class cl,
                    siac_d_class_tipo tipo
              where r.ente_proprietario_id = 2
                and r.classif_id = cl.classif_id 
                and cl.classif_tipo_id = tipo.classif_tipo_id 
                and tipo.classif_tipo_code  in ('CDC', 'CDR')
                and r.data_cancellazione is null
                and r.validita_fine  is null
               ),
        liquidato as ( select --rliqmov.movgest_ts_id ,
                           imp.movgest_anno , imp.movgest_numero ,
                           periodo.anno, 
                           liq.liq_anno  ANNO_EMIS,
                           sum(liq.liq_importo) tot_liq
                    from siac_r_liquidazione_movgest  rliqmov,
                         siac_t_liquidazione liq,
                         siac_r_liquidazione_stato rs,
                         siac_d_liquidazione_stato stato,
                         siac_t_bil bil,
                         siac_t_periodo periodo, 
                         siac_v_bko_impegno_valido imp
                    where rliqmov.liq_id = liq.liq_id
                      and rliqmov.movgest_ts_id = imp.movgest_ts_id 
                      --and liq.liq_anno = imp.movgest_anno 
                      and liq.bil_id = bil.bil_id 
                      and bil.periodo_id = periodo.periodo_id 
                      and periodo.anno::integer = liq.liq_anno
                      and rs.liq_id = liq.liq_id 
                      and rs.liq_stato_id = stato.liq_stato_id 
                      and stato.liq_stato_code != 'A'
--                      and liq.data_cancellazione is null 
--                      and liq.validita_fine  is null 
                      and rliqmov.data_cancellazione is null
                      and rliqmov.validita_fine  is null
                      and rs.data_cancellazione is null
                      and rs.validita_fine  is null
                    group by imp.movgest_anno , imp.movgest_numero , periodo.anno, ANNO_EMIS
                   ),
        pagato as (select --rliqmov.movgest_ts_id ,
                           imp.movgest_anno , imp.movgest_numero ,
                           mand.ord_anno ANNO_EMIS,
                           sum(ImportoPag.ord_ts_det_importo) tot_pag
                    from siac_r_liquidazione_movgest  rliqmov,
                         siac_t_liquidazione liq,
                         siac_r_liquidazione_ord rliqord,
                         siac_t_ordinativo mand,
                         siac_d_ordinativo_tipo tipo,
                         siac_t_ordinativo_ts ts,
                         siac_t_ordinativo_ts_det ImportoPag,
                         siac_d_ordinativo_ts_det_tipo tipoPag, 
                         siac_v_bko_impegno_valido imp 
                    where rliqmov.liq_id = liq.liq_id
                      and rliqmov.movgest_ts_id = imp.movgest_ts_id 
                      and rliqord.liq_id = liq.liq_id 
                      and rliqord.sord_id = ts.ord_ts_id 
                      and ts.ord_id = mand.ord_id 
                      and mand.ord_tipo_id = tipo.ord_tipo_id
                      and tipo.ord_tipo_code = 'P'
                      and mand.ord_id = ts.ord_id 
                      and ImportoPag.ord_ts_id = ts.ord_ts_id 
                      and tipoPag.ord_ts_det_tipo_id = ImportoPag.ord_ts_det_tipo_id
                      and tipoPag.ord_ts_det_tipo_code = 'A'
                      and rliqmov.data_cancellazione is null
                      and rliqmov.validita_fine  is null
                    group by imp.movgest_anno , imp.movgest_numero ,   ANNO_EMIS
                  ),
       documenti as (select  imp.anno_bilancio, imp.movgest_anno, imp.movgest_numero, 
                             sum(sub.subdoc_importo ) tot_quote
                         from siac_r_subdoc_movgest_ts r,
                              siac_v_bko_impegno_valido imp, 
                              siac_t_subdoc sub,
                              siac_t_doc doc
                         where imp.ente_proprietario_id = 2
                           and r.movgest_ts_id = imp.movgest_ts_id
                           and r.subdoc_id = sub.subdoc_id
                           and sub.doc_id = doc.doc_id
                           and sub.data_cancellazione is null
                           and sub.validita_fine  is null
                           and r.data_cancellazione is null
                           and r.validita_fine  is null
                           group by imp.anno_bilancio, imp.movgest_anno, imp.movgest_numero
                    )
select distinct 
       sog.soggetto_code CODICE_ANAGRAFICO_FORNITORE, 
       sog.soggetto_desc NOME_PARTECIPATA,
       sog.codice_fiscale CODICE_FISCALE_PARTECIPATA,
       sog.partita_iva P_IVA_PARTECIPATA,
       SAC.codice_sac RESPONSABILE_PROCEDURA,
       imp.movgest_anno ANNO_IMPEGNO,
       imp.movgest_numero NUMERO_IMPEGNO,
       imp.movgest_subnumero NUMERO_SUB_IMPEGNO,
       imp.movgest_desc,  
       ImportiImpIniz.movgest_ts_det_importo IMPORTO_ORIGINE_IMPEGNO,  
       ImportiImpAtt.movgest_ts_det_importo IMPORTO_ASSESTATO_IMPEGNO_3112,  
       COALESCE(LIQ_3112.tot_liq,null, 0) LIQUIDATO_3112,
       COALESCE(PAGATO_3112.tot_pag,null, 0) PAGAMENTI_3112,
       (ImportiImpAtt.movgest_ts_det_importo - COALESCE(PAGATO_3112.tot_pag,null, 0) ) DISPONIBILITA_3112,
       COALESCE(RATE_3112.tot_quote,null, 0) RATE_3112,
       ImportiImpAtt.movgest_ts_det_importo ASSESTATO_IMPEGNO_OGGI,         
       COALESCE(LIQ_OLTRE_3112.tot_liq,null, 0) LIQUIDATO_OLTRE_3112,
       COALESCE(PAGATO_OLTRE_3112.tot_pag,null, 0) PAGAMENTI_OLTRE_3112,       
       COALESCE(RATE_OLTRE_3112.tot_quote,null, 0) RATE_OLTRE_3112,
       imp.anno_bilancio ESERCIZIO, 
        ' ' MANTENIMENTO
from 
    siac_r_movgest_ts_sog rsog,  
    siac_t_movgest_ts_det ImportiImpIniz,
    siac_d_movgest_ts_det_tipo tipoImportiIniz, 
    siac_t_movgest_ts_det ImportiImpAtt,
    siac_d_movgest_ts_det_tipo tipoImportiAtt,
    siac_t_soggetto sog,
    siac_t_soc_partecipate part,
    siac_v_bko_impegno_valido imp
left join SAC on imp.movgest_ts_id  = SAC.movgest_ts_id 
left join liquidato LIQ_3112 on imp.movgest_anno = LIQ_3112.movgest_anno and 
                                imp.movgest_numero = LIQ_3112.movgest_numero and  
                                imp.movgest_anno = LIQ_3112.ANNO_EMIS   and
                                imp.anno_bilancio = LIQ_3112.anno::integer 
left join liquidato LIQ_OLTRE_3112 on imp.movgest_anno = LIQ_OLTRE_3112.movgest_anno and 
                                      imp.movgest_numero = LIQ_OLTRE_3112.movgest_numero   and  
                                      imp.movgest_anno < LIQ_OLTRE_3112.ANNO_EMIS 
left join pagato PAGATO_3112 on imp.movgest_anno = PAGATO_3112.movgest_anno and 
                                imp.movgest_numero = PAGATO_3112.movgest_numero and  
                                imp.movgest_anno = PAGATO_3112.ANNO_EMIS 
left join pagato PAGATO_OLTRE_3112 on imp.movgest_anno = PAGATO_OLTRE_3112.movgest_anno and 
                                      imp.movgest_numero = PAGATO_OLTRE_3112.movgest_numero and  
                                      imp.movgest_anno < PAGATO_OLTRE_3112.ANNO_EMIS 
left join documenti RATE_3112 on imp.movgest_anno = RATE_3112.movgest_anno and 
                                 imp.movgest_numero = RATE_3112.movgest_numero and  
                                 imp.anno_bilancio = RATE_3112.anno_bilancio 
left join documenti RATE_OLTRE_3112 on imp.movgest_anno = RATE_OLTRE_3112.movgest_anno and 
                                       imp.movgest_numero = RATE_OLTRE_3112.movgest_numero and  
                                       imp.anno_bilancio < RATE_OLTRE_3112.anno_bilancio 
where rsog.movgest_ts_id = imp.movgest_ts_id
  and rsog.soggetto_id = sog.soggetto_id 
  and sog.soggetto_code = part.codice  
  and ImportiImpIniz.movgest_ts_id = imp.movgest_ts_id 
  and ImportiImpIniz.movgest_ts_det_tipo_id = tipoImportiIniz.movgest_ts_det_tipo_id
  and tipoImportiIniz.movgest_ts_det_tipo_code = 'I'
  and ImportiImpAtt.movgest_ts_id = imp.movgest_ts_id 
  and ImportiImpAtt.movgest_ts_det_tipo_id = tipoImportiAtt.movgest_ts_det_tipo_id
  and tipoImportiAtt.movgest_ts_det_tipo_code = 'A'
  and rsog.data_cancellazione is null
  and rsog.validita_fine is null
  and imp.anno_bilancio = imp.movgest_anno 
    
  
  ; -- ALE FIX
 

-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------
-----------------------------------------------------------                      V_SIMOP_RESIDUI_ATTIVI                 -----------------------------------------------------------
-----------------------------------------------------------  ---------------------------------------------------------  -----------------------------------------------------------

CREATE OR REPLACE VIEW siac.V_SIMOP_RESIDUI_ATTIVI
as WITH SAC as (select r.movgest_ts_id,
                       cl.classif_code as codice_sac
               from siac_r_movgest_class r,
                    siac_t_class cl,
                    siac_d_class_tipo tipo
              where r.ente_proprietario_id = 2
                and r.classif_id = cl.classif_id 
                and cl.classif_tipo_id = tipo.classif_tipo_id 
                and tipo.classif_tipo_code  in ('CDC', 'CDR')
                and r.data_cancellazione is null
                and r.validita_fine  is null
               ),
        incassato as (select 
                           acc.movgest_anno , acc.movgest_numero ,
                           rev.ord_anno ANNO_EMIS,
                           sum(ImportoPag.ord_ts_det_importo) tot_pag
                    from siac_r_ordinativo_ts_movgest_ts raccrev,
                         siac_t_ordinativo  rev,
                         siac_r_ordinativo_stato rs,
                         siac_d_ordinativo_stato stato,
                         siac_d_ordinativo_tipo tipo,
                         siac_t_ordinativo_ts ts,
                         siac_t_ordinativo_ts_det ImportoPag,
                         siac_d_ordinativo_ts_det_tipo tipoPag, 
                         siac_v_bko_accertamento_valido acc 
                    where raccrev.movgest_ts_id = acc.movgest_ts_id 
                      and raccrev.ord_ts_id = ts.ord_ts_id 
                      and ts.ord_id = rev.ord_id 
                      and rev.ord_tipo_id = tipo.ord_tipo_id
                      and rs.ord_id = rev.ord_id 
                      and rs.ord_stato_id = stato.ord_stato_id 
                      and stato.ord_stato_code != 'A'
                      and tipo.ord_tipo_code = 'I'
                      and ImportoPag.ord_ts_id = ts.ord_ts_id 
                      and tipoPag.ord_ts_det_tipo_id = ImportoPag.ord_ts_det_tipo_id
                      and tipoPag.ord_ts_det_tipo_code = 'A'
                      and raccrev.data_cancellazione is null
                      and raccrev.validita_fine  is null
                      and rs.data_cancellazione is null
                      and rs.validita_fine  is null
--                      and acc.anno_bilancio = 2020
                    group by acc.movgest_anno, acc.movgest_numero,   ANNO_EMIS
                  ),
       documenti as (select  acc.anno_bilancio, acc.movgest_anno, acc.movgest_numero, 
                             sum(sub.subdoc_importo ) tot_quote
                         from siac_r_subdoc_movgest_ts r,
                              siac_v_bko_accertamento_valido acc, 
                              siac_t_subdoc sub,
                              siac_t_doc doc
                         where acc.ente_proprietario_id = 2
                           and r.movgest_ts_id = acc.movgest_ts_id
                           and r.subdoc_id = sub.subdoc_id
                           and sub.doc_id = doc.doc_id
                           and sub.data_cancellazione is null
                           and sub.validita_fine  is null
                           and r.data_cancellazione is null
                           and r.validita_fine  is null
                           group by acc.anno_bilancio, acc.movgest_anno, acc.movgest_numero
                    )
select distinct 
       sog.soggetto_code CODICE_ANAGRAFICO_FORNITORE, 
       sog.soggetto_desc NOME_PARTECIPATA,
       sog.codice_fiscale CODICE_FISCALE_PARTECIPATA,
       sog.partita_iva P_IVA_PARTECIPATA,
       SAC.codice_sac RESPONSABILE_PROCEDURA,
       acc.movgest_anno ANNO_ACCERTAMENTO,
       acc.movgest_numero NUMERO_ACCERTAMENTO,
       acc.movgest_subnumero NUMERO_SUB_ACCERTAMENTO,
       acc.movgest_desc,  
       ImportiImpIniz.movgest_ts_det_importo IMPORTO_ORIGINE_ACCERTAMENTO,  
       ImportiImpAtt.movgest_ts_det_importo IMPORTO_ASSESTATO_ACCERTAMENTO_3112,  
       COALESCE(REVERSALI_3112.tot_pag,null, 0) REVERSALI_3112,
       (ImportiImpAtt.movgest_ts_det_importo - COALESCE(REVERSALI_3112.tot_pag,null, 0) ) DISPONIBILITA_3112,
--       COALESCE(RATE_3112.tot_quote,null, 0) RATE_3112,
       ImportiImpAtt.movgest_ts_det_importo ASSESTATO_ACCERTAMENTO_OGGI,         
       COALESCE(REVERSALI_OLTRE_3112.tot_pag,null, 0) REVERSALI_OLTRE_3112,       
       COALESCE(RATE_OLTRE_3112.tot_quote,null, 0) RATE_OLTRE_3112,
       acc.anno_bilancio ESERCIZIO, 
        ' ' MANTENIMENTO
from 
    siac_r_movgest_ts_sog rsog,  
    siac_t_movgest_ts_det ImportiImpIniz,
    siac_d_movgest_ts_det_tipo tipoImportiIniz, 
    siac_t_movgest_ts_det ImportiImpAtt,
    siac_d_movgest_ts_det_tipo tipoImportiAtt,
    siac_t_soggetto sog,
    siac_t_soc_partecipate part,
    siac_v_bko_accertamento_valido acc
left join SAC on acc.movgest_ts_id  = SAC.movgest_ts_id 
left join incassato REVERSALI_3112 on acc.movgest_anno = REVERSALI_3112.movgest_anno and 
                                acc.movgest_numero = REVERSALI_3112.movgest_numero and  
                                acc.movgest_anno = REVERSALI_3112.ANNO_EMIS 
left join incassato REVERSALI_OLTRE_3112 on acc.movgest_anno = REVERSALI_OLTRE_3112.movgest_anno and 
                                      acc.movgest_numero = REVERSALI_OLTRE_3112.movgest_numero and  
                                      acc.movgest_anno < REVERSALI_OLTRE_3112.ANNO_EMIS 
/*left join documenti RATE_3112 on acc.movgest_anno = RATE_3112.movgest_anno and 
                                 acc.movgest_numero = RATE_3112.movgest_numero and  
                                 acc.anno_bilancio = RATE_3112.anno_bilancio*/ 
left join documenti RATE_OLTRE_3112 on acc.movgest_anno = RATE_OLTRE_3112.movgest_anno and 
                                       acc.movgest_numero = RATE_OLTRE_3112.movgest_numero and  
                                       acc.anno_bilancio < RATE_OLTRE_3112.anno_bilancio 
where rsog.movgest_ts_id = acc.movgest_ts_id
  and rsog.soggetto_id = sog.soggetto_id 
  and sog.soggetto_code = part.codice  
  and ImportiImpIniz.movgest_ts_id = acc.movgest_ts_id 
  and ImportiImpIniz.movgest_ts_det_tipo_id = tipoImportiIniz.movgest_ts_det_tipo_id
  and tipoImportiIniz.movgest_ts_det_tipo_code = 'I'
  and ImportiImpAtt.movgest_ts_id = acc.movgest_ts_id 
  and ImportiImpAtt.movgest_ts_det_tipo_id = tipoImportiAtt.movgest_ts_det_tipo_id
  and tipoImportiAtt.movgest_ts_det_tipo_code = 'A'
  and rsog.data_cancellazione is null
  and rsog.validita_fine is null
  and acc.anno_bilancio = acc.movgest_anno 
    
  
  
  ; -- ALE FIX
 

-- SIAC-8640   Viste JPartecipate 26.04.2022 Haitham fine


--SIAC-8634 - Maurizio - INIZIO

DROP FUNCTION if exists siac."BILR147_dettaglio_colonne_nuovo"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR259_Allegato_B_FPV_Rendiconto_dettaglio_BILR147"(p_ente_prop_id integer, p_anno varchar);
DROP FUNCTION if exists siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011"(p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar);

--cambiato un commento:
CREATE OR REPLACE FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend_new" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  bil_anno varchar,
  missione_tipo_code varchar,
  missione_tipo_desc varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_tipo_code varchar,
  programma_tipo_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  fondo_plur_anno_prec_a numeric,
  spese_impe_anni_prec_b numeric,
  quota_fond_plur_anni_prec_c numeric,
  spese_da_impeg_anno1_d numeric,
  spese_da_impeg_anno2_e numeric,
  spese_da_impeg_anni_succ_f numeric,
  riacc_colonna_x numeric,
  riacc_colonna_y numeric,
  fondo_plur_anno_g numeric
) AS
$body$
DECLARE

classifBilRec record;
var_fondo_plur_anno_prec_a numeric;
var_spese_impe_anni_prec_b numeric;

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
bilancio_id integer;
bilancio_id_anno1 integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

annoBilInt=p_anno::INTEGER;

bil_anno='';
missione_tipo_code='';
missione_tipo_desc='';
missione_code='';
missione_desc='';
programma_tipo_code='';
programma_tipo_desc='';
programma_code='';
programma_desc='';

var_fondo_plur_anno_prec_a=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;
spese_da_impeg_anni_succ_f=0;
fondo_plur_anno_g=0;
var_fondo_plur_anno_prec_a:=0;
var_spese_impe_anni_prec_b=0;
quota_fond_plur_anni_prec_c=0;
spese_da_impeg_anno1_d=0;
spese_da_impeg_anno2_e=0;  
spese_da_impeg_anni_succ_f=0;

--Leggo l'id dell'anno bilancio
select bil.bil_id
into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;    

--Leggo l'id dell'anno bilancio +1
select bil.bil_id
into bilancio_id_anno1
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = annoCapImp1
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;   
            
/*
	11/11/2021 SIAC-8250.
Funzione riscritta per rendere le query piu' leggibili.
In seguito sono state applicate le nuove regole per i vari campi indicate 
nella Jira.

Colonna A: NON MODIFICATA.
	Stanziamento Capitoli di Spesa FPV in Spesa (Anno Bilancio -1).
	Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
    eventualmente caricato sulle variabili.

Colonna B: NON MODIFICATA. 
	Somma Importo VINCOLO Impegni definitivi (D, N) con anno bilancio 
	corrente e anno impegno = anno bilancio con Vincolo FPVCC+ FPVSC.
    
Colonna X: MODIFICATA
	Somma importo Modifiche non annullate su Impegni definitivi (D, N) 
	con anno bilancio corrente e anno impegno = anno bilancio 
    con Vincolo FPVCC o FPVSC
	Modifiche tipo: tutti  tranne ROR reimputazione, REANNO, AGG, RidCoi   
     
Colonna Y: MODIFICATA
	Somma importo Modifiche non annullate su Impegni definitivi (D, N) 
	con anno bilancio corrente e  anno impegno > anno bilancio 
    con Vincolo FPVCC o FPVSC
	Modifiche tipo: tutti  tranne ROR reimputazione, REANNO, AGG, RidCoi.
 
Colonna D: MODIFICATA
    Importo VINCOLO degli impegni con:
    Anno Bilancio corrente, Anno competenza dell’impegno = anno bilancio + 1
    con vincolo verso Accertamento competenza anno bilancio oppure con vinciolo AMM 
    +
    Impegni non nati da aggiudicazione e
    Anno di bilancio= anno corrente +1 e
    Anno di impegno = anno corrente +1 e
    Anno Riaccertamento = anno corrente (SIA DA ROR CHE REANNO).

    Il valore da considerare e' l'importo iniziale dell’impegno 
    con Impegno origine esercizio anno bilancio SENZA VINCOLO O CON VINCOLO VERSO 
    ACCERTAMENTO /AMM 
    (COMPET. anno bilancio -cioe' verso anno accertamento anno bilancio) 
    QUINDI NON SONO DA PRENDERE GLI IMPEGNI REIMPUTATI IL CUI IMPEGNO ORIGINE 
    ERA VINCOLATO A FPVCC/FPVSC  E NON SONO DA CONSIDERARE GLI IMPEGNI CHE 
    NASCONO NEL anno bilancio+1 A SEGUITO DI RIDUZIONE PER AGGIUDICAZIONE  
       
Colonna E: MODIFICATA
	Come colonna D ma gli anni sono anno bilancio +2
    
Colonna F: MODIFICATA
	Come colonna D ma gli anni sono > anno bilancio +2    

Colonna G: NON MODIFICATA
	La formula non e' cambiata (colonna_G =colonna_C+colonna_D+colonna_E+colonna_F)
    ma e' cambiato il modo di calcolare gli addendi.
    
*/        

/*
	Attenzione!
    Se si modifica questa funzione occorre modificare anche la funzione
    BILR259_Allegato_B_FPV_Rendiconto_dettaglio_BILR147 che estrae il 
    dettaglio delle colonne 
    B, D, E, F, X, Y.

*/

return query           
with struttura as (
  select v1.missione_tipo_desc			missione_tipo_desc,
          v1.missione_code				missione_code,
          v1.missione_desc				missione_desc,
          v1.programma_tipo_desc		programma_tipo_desc,
          v1.programma_code				programma_code,
          v1.programma_desc				programma_desc,
          v1.programma_id					programma_id,
          v1.ente_proprietario_id
  from "fnc_bilr_struttura_cap_bilancio_spese"(p_ente_prop_id, 
                                                      p_anno, '') v1
		/* 03/08/2021: il seguente controllo era stato inserito nella
           versione originale della procedura.
           Viene lasciato anche se non sono sicuro sia corretto */
        /* ANNA 31-05 inizio */
  where  v1.missione_code::integer <= 19
 		/* ANNA 31-05 fine */  
  group by v1.missione_tipo_desc, v1.missione_code, v1.missione_desc, 
            	v1.programma_tipo_desc, v1.programma_code, v1.programma_desc,
                v1.programma_id,
                v1.ente_proprietario_id 
            order by missione_code,programma_code  ),                      
fpv_anno_prec_da_variabili as (
select  
  importi.repimp_desc programma_code,
 sum(coalesce(importi.repimp_importo,0)) spese_fpv_anni_prec     
from 	siac_t_report					report,
		siac_t_report_importi 			importi,
		siac_r_report_importi 			r_report_importi,		
        siac_t_periodo 					anno_comp
where 	r_report_importi.rep_id			=	report.rep_id
        and r_report_importi.repimp_id		=	importi.repimp_id	
        and importi.periodo_id 				=	anno_comp.periodo_id              	
        and report.ente_proprietario_id		=	p_ente_prop_id
		and importi.bil_id					=	bilancio_id 			
      	and report.rep_codice				=	'BILR147'   				
      	and report.data_cancellazione IS NULL
        and importi.data_cancellazione IS NULL
        and r_report_importi.data_cancellazione IS NULL
        and anno_comp.data_cancellazione IS NULL
        group by importi.repimp_desc),
/*
	22/02/2019: SIAC-6623.
    	E' stato richiesto di estrarre gli importi FPV dell'anno precedente dai capitoli.
        Se per un codice PROGRAMMA non esiste un valore allora si prende il valore
        eventualmente caricato sulle variabili (fpv_anno_prec_da_variabili). 
*/        
 fpv_anno_prec_da_capitoli as (               
select 	 t_class.classif_code programma_code,
	sum(capitolo_importi.elem_det_importo) importo_fpv_anno_prec
from 		siac_t_bil_elem_det 		capitolo_importi,
         	siac_d_bil_elem_det_tipo 	capitolo_imp_tipo,
         	siac_t_periodo 				capitolo_imp_periodo,
            siac_t_bil_elem 			capitolo,
            siac_t_bil					t_bil,
            siac_t_periodo				t_periodo_bil,
            siac_d_bil_elem_tipo 		tipo_elemento,
	 		siac_d_bil_elem_stato 		stato_capitolo, 
     		siac_r_bil_elem_stato 		r_capitolo_stato,
	 		siac_d_bil_elem_categoria 	cat_del_capitolo,
     		siac_r_bil_elem_categoria 	r_cat_capitolo,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class t_class, 
            siac_d_class_tipo d_class_tipo
where capitolo.elem_id = capitolo_importi.elem_id 
	and	capitolo.bil_id = t_bil.bil_id
	and t_periodo_bil.periodo_id =t_bil.periodo_id	
	and	capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id
	and	capitolo_importi.elem_det_tipo_id = capitolo_imp_tipo.elem_det_tipo_id 		
	and	capitolo_imp_periodo.periodo_id = capitolo_importi.periodo_id 
	and	capitolo.elem_id = r_capitolo_stato.elem_id			
	and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id
	and	capitolo.elem_id = r_cat_capitolo.elem_id				
	and	r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id	
    and d_class_tipo.classif_tipo_id=t_class.classif_tipo_id
    and capitolo.elem_id = r_bil_elem_class.elem_id
    and r_bil_elem_class.classif_id = t_class.classif_id
	and capitolo_importi.ente_proprietario_id = p_ente_prop_id 					
	and	tipo_elemento.elem_tipo_code = 'CAP-UG' -- prendere i capitoli di GESTIONE
	and	t_periodo_bil.anno = annoPrec	--anno bilancio -1	
	and	capitolo_imp_periodo.anno = annoPrec	--anno bilancio -1		  	
	and	stato_capitolo.elem_stato_code = 'VA'								
	and	cat_del_capitolo.elem_cat_code in ('FPV','FPVC')
	and capitolo_imp_tipo.elem_det_tipo_code = 'STA'	
    and d_class_tipo.classif_tipo_code='PROGRAMMA'			
	and	capitolo_importi.data_cancellazione 		is null
	and	capitolo_imp_tipo.data_cancellazione 		is null
	and	capitolo_imp_periodo.data_cancellazione 	is null
	and	capitolo.data_cancellazione 				is null
	and	tipo_elemento.data_cancellazione 			is null
	and	stato_capitolo.data_cancellazione 			is null 
	and	r_capitolo_stato.data_cancellazione 		is null
	and cat_del_capitolo.data_cancellazione 		is null
	and	r_cat_capitolo.data_cancellazione 			is null
	and t_bil.data_cancellazione 					is null
	and t_periodo_bil.data_cancellazione 			is null
    and r_bil_elem_class.data_cancellazione 		is null
    and t_class.data_cancellazione 					is null
    and d_class_tipo.data_cancellazione 		is null        
GROUP BY t_class.classif_code ),
tbimpaprec as (
select 
--sum(coalesce(f.movgest_ts_det_importo,0)) spese_impe_anni_prec
--Spese impegnate negli esercizi precedenti e imputate all'esercizio N e coperte dal fondo pluriennale vincolato
-- si prendono le quote di impegni di competenza   
-- gli impegni considerati devono inoltre essere vincolati a fondo
-- l'importo considerato e' quello attuale
sum(coalesce(r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec,
 class.classif_code programma_code
          from siac_t_movgest mov,              
            siac_t_movgest_ts mov_ts, 
            siac_t_movgest_ts_det mov_ts_det,
            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
            siac_t_bil_elem bil_elem, 
            siac_r_movgest_bil_elem r_mov_bil_elem,
            siac_r_movgest_ts_stato r_mov_ts_stato, 
            siac_d_movgest_stato d_mov_stato,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class class, 
            siac_d_class_tipo d_class_tipo, 
            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
            siac_t_atto_amm atto,
            siac_d_movgest_tipo d_mov_tipo,
            siac_r_movgest_ts r_movgest_ts, 
            siac_t_avanzovincolo av_vincolo, 
            siac_d_avanzovincolo_tipo av_vincolo_tipo
          where mov.movgest_id = mov_ts.movgest_id  
          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = class.classif_id
          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
          and bil_elem.elem_id=r_mov_bil_elem.elem_id
          and r_mov_bil_elem.movgest_id=mov.movgest_id 
          and r_movgest_ts.avav_id=av_vincolo.avav_id     
          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id            
          and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and mov.ente_proprietario_id= p_ente_prop_id    
          and mov.bil_id = bilancio_id            
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and mov.movgest_anno = annoBilInt 
          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_mov_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and av_vincolo_tipo.avav_tipo_code like'FPV%'
          and mov_ts.movgest_ts_id_padre is NULL  
          and r_mov_bil_elem.data_cancellazione is null
          and r_mov_bil_elem.validita_fine is NULL          
          and r_mov_ts_stato.data_cancellazione is null
          and r_mov_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and r_mov_ts_atto.data_cancellazione is null
          and r_mov_ts_atto.validita_fine is null          
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null            
          	--21/05/2020 SIAC-7643 
            --aggiunti i test sulle date che mancavano
          and mov.data_cancellazione is null
          and mov.validita_fine is NULL
          and mov_ts.data_cancellazione is null
          and mov_ts.validita_fine is NULL   
          and mov_ts_det.data_cancellazione is null
          and mov_ts_det.validita_fine is NULL   
          and d_mov_ts_det_tipo.data_cancellazione is null
          and d_mov_ts_det_tipo.validita_fine is NULL   
          and bil_elem.data_cancellazione is null
          and bil_elem.validita_fine is NULL   
          and d_mov_stato.data_cancellazione is null
          and d_mov_stato.validita_fine is NULL   
          and class.data_cancellazione is null
          and class.validita_fine is NULL   
          and d_class_tipo.data_cancellazione is null
          and d_class_tipo.validita_fine is NULL   
          and atto.data_cancellazione is null
          and atto.validita_fine is NULL   
          and av_vincolo.data_cancellazione is null
          --and av_vincolo.validita_fine is NULL 
          and av_vincolo_tipo.data_cancellazione is null
          and av_vincolo_tipo.validita_fine is NULL              
          group by class.classif_code
          ),
tbriaccx as (
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno)
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                                 
  select --sum(COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x,
  	(sum((COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_x,
   class.classif_code programma_code
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         mov_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */
      		left join (select r_mod_vinc.mod_id,
                    sum(r_mod_vinc.importo_delta) importo_delta 
              from siac_r_movgest_ts r_mov_ts,
                  siac_r_modifica_vincolo r_mod_vinc
              where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                and r_mov_ts.data_cancellazione IS NULL
                and r_mod_vinc.data_cancellazione IS NULL
              group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      	siac_t_movgest_ts_det_mod mov_ts_det_mod,
      	siac_t_movgest_ts mov_ts, 
      	siac_d_modifica_stato d_mod_stato,
        siac_t_movgest mov, 
        siac_d_movgest_tipo d_mov_tipo,       
        siac_t_modifica modif, 
        siac_d_modifica_tipo d_modif_tipo,
        siac_d_modifica_stato d_modif_stato, 
        siac_t_bil_elem t_bil_elem, 
        siac_r_movgest_bil_elem r_mov_bil_elem,
        siac_r_bil_elem_class r_bil_elem_class, 
        siac_t_class class, 
        siac_d_class_tipo d_class_tipo,
        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
        siac_t_atto_amm atto_amm ,
        siac_r_movgest_ts_stato r_mov_ts_stato, 
        siac_d_movgest_stato d_mov_stato    
      where mov_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and mov_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_modif_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_movgest_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_movgest_ts_atto_amm.attoamm_id = atto_amm.attoamm_id
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mov_ts_stato.movgest_ts_id = mov_ts_det_mod.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id        
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno = anno del bilancio
        and mov.movgest_anno = annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I' 
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione 
      /*  and 
        ( d_modif_tipo.mod_tipo_code like  'ECON%'
           or d_modif_tipo.mod_tipo_desc like  'ROR%'
        )      
        and d_modif_tipo.mod_tipo_code <> 'REIMP' */          
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM') 
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and mov_ts_det_mod.data_cancellazione is null
        and mov_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_modif_tipo.data_cancellazione is null
        and d_modif_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_movgest_ts_atto_amm.data_cancellazione is null
        and r_movgest_ts_atto_amm.validita_fine is null
        and d_mov_stato.data_cancellazione is null
        and d_mov_stato.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                      siac_t_avanzovincolo av_vincolo, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id                                 
                  and mov_ts_det_mod.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%' 
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null 
                 )
      group by class.classif_code
      ),
tbriaccy as 
--Riaccertamento degli impegni di cui alla lettera b) effettuata nel corso dell'eserczio N (cd. economie di impegno) su impegni pluriennali finanziati dal FPV e imputati agli esercizi successivi  a N
--riduzioni su impegni di competenza con anno atto minore dell'anno di bilancio 
--e coperti anche solo parzialmente da fondo                 
( select --sum(COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y,
	(sum((COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_y,
	class.classif_code programma_code
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         movgest_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
                    sum(r_mod_vinc.importo_delta) importo_delta 
              from siac_r_movgest_ts r_mov_ts,
                  siac_r_modifica_vincolo r_mod_vinc
              where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                and r_mov_ts.data_cancellazione IS NULL
                and r_mod_vinc.data_cancellazione IS NULL
              group by r_mod_vinc.mod_id) vincoli_acc
        on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      siac_t_movgest_ts_det_mod movgest_ts_det_mod,
      siac_t_movgest_ts mov_ts, 
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest mov, 
      siac_d_movgest_tipo d_mov_tipo, 
      siac_t_modifica modif, 
      siac_d_modifica_tipo d_mod_tipo,
      siac_d_modifica_stato d_modif_stato, 
      siac_t_bil_elem t_bil_elem, 
      siac_r_movgest_bil_elem r_mov_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class class, 
      siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_mov_ts_atto_amm, 
      siac_t_atto_amm atto_amm ,
      siac_r_movgest_ts_stato r_mov_ts_stato, 
      siac_d_movgest_stato d_mov_stato    
      where movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and movgest_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_mod_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_mov_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_mov_ts_atto_amm.attoamm_id = atto_amm.attoamm_id        
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno > anno del bilancio
        and mov.movgest_anno > annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I'
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione         
  /*      and 
        ( d_mod_tipo.mod_tipo_code like  'ECON%'
           or d_mod_tipo.mod_tipo_desc like  'ROR%'
        )
        and d_mod_tipo.mod_tipo_code <> 'REIMP' */
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM')         
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ts_stato.movgest_ts_id = mov_ts.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and movgest_ts_det_mod.data_cancellazione is null
        and movgest_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_mod_tipo.data_cancellazione is null
        and d_mod_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_mov_ts_atto_amm.data_cancellazione is null
        and r_mov_ts_atto_amm.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                  siac_t_avanzovincolo av_vincolo, 
                  siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                  and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%'                                      
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null )
      group by class.classif_code
      ),
imp_colonna_d as 
      -- Spese impegnate nell'esercizio N con imputazione all'esercizio N+1 e 
      -- coperte dal fondo pluriennale vincolato
      -- impegni anno + 1 con atto nell'anno legati ad accertamenti 
      -- di competenza oppure ad avanzo
      
      -- SIAC-8682 - 07/04/2022.
      --E' necessario NON estrarre gli impegni con anno successivo all'anno 
      --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
      --anno = all'anno dell'impegno.     
      (
      select sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d, 
      x.programma_code as programma_code from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 1
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_d, 
                          class.classif_code as programma_code
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 1
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id 
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                   
              select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_d, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 1
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              --non esiste su siac_r_movgest_ts 
                              --SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)                                                            
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id = NULL
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo 
                                --SIAC-8682 - 07/04/2022.
                                --il legame e' con l'impegno e non quello origine del riaccertamento.
                                --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id                                  
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id                                        
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL)))
                                   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +1).
                                AND  not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +1
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)
				--SIAC-8690 12/04/2022
                --devo escludere gli impegni riaccertati il cui impegno origine
                --l'anno precedente era vincolato verso FPV. 
                --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null  
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null                                    
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                           
                   )) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code)    
              ) as x
                group by x.programma_code 
            ),
imp_colonna_e as (      
    select sum(x.spese_da_impeg_anno2_e) as spese_da_impeg_anno2_e , 
           x.programma_code as programma_code from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio
              select sum(COALESCE(r_movgest_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno2_e, 
                     		 class.classif_code as programma_code
                        from siac_t_movgest mov,  
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_movgest_ts, 
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato rstacc,
                        siac_d_movgest_stato dstacc
                where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id 
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                        and r_movgest_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and rstacc.movgest_ts_id=acc_ts.movgest_ts_id
                        and rstacc.movgest_stato_id=dstacc.movgest_stato_id                        
                        and mov.ente_proprietario_id=p_ente_prop_id
                        and mov.bil_id = bilancio_id
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 2
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' 
                        and acc.movgest_anno = annoBilInt
                        and dstacc.movgest_stato_code in ('D', 'N')
                        --and atto.attoamm_anno = p_anno   
                        and mov.data_cancellazione is null
                        and mov_ts.data_cancellazione is null
                        and mov_ts.movgest_ts_id_padre is NULL                            
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_movgest_ts.data_cancellazione is null
                        and r_movgest_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null
                        and rstacc.validita_fine is null
                        and rstacc.data_cancellazione is null
                            --21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano                        
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and d_mov_stato.validita_fine is null
                        and d_mov_stato.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code )
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                      		spese_da_impeg_anno2_e, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato,
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id                          
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id     
                          and mov.bil_id = bilancio_id  
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null  
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                                                  
                     group by class.classif_code
              )  
               union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id   
        
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                   
				select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno2_e, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                        	  --SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
									--non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL                                     
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo
								--SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id                                                                                                      
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
									--SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id                                                                                                                    
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
								   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)                                                                               
				  --SIAC-8690 12/04/2022
                  --devo escludere gli impegni riaccertati il cui impegno origine
                  --l'anno precedente era vincolato verso FPV. 
                  --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null  
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
									  --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null                                        
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                        
                       ))
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                   AND   (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code                 
              ) 
              ) as x
                group by x.programma_code 
                ),
imp_colonna_f as (
      select sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f , x.programma_code as programma_code from (
               (
 				 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio               
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      		as spese_da_impeg_anni_succ_f, 
                      		class.classif_code as programma_code
                        from siac_t_movgest mov,  
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_movgest_ts acc_ts,
                          siac_t_movgest acc,
                          siac_r_movgest_ts_stato r_acc_ts_stato,
                          siac_d_movgest_stato d_acc_stato
                        where mov.movgest_id = mov_ts.movgest_id  
                            and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                            and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                            and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                            and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                            and r_bil_elem_class.classif_id = class.classif_id
                            and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                            and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                            and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                            and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                            and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id
                            and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                            and acc_ts.movgest_id = acc.movgest_id
                            and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                            and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id
                            and r_mov_bil_elem.movgest_id=mov.movgest_id 
                            and mov.ente_proprietario_id= p_ente_prop_id 
                            and mov.bil_id = bilancio_id     
                            and d_class_tipo.classif_tipo_code='PROGRAMMA'
                            and mov.movgest_anno > annoBilInt + 2
                            and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and d_mov_stato.movgest_stato_code in ('D', 'N')
                            and d_mov_tipo.movgest_tipo_code='I' 
                            and acc.movgest_anno = annoBilInt
                            and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                            --and atto.attoamm_anno = p_anno   
                            and mov_ts.movgest_ts_id_padre is NULL  
                            and mov_ts.data_cancellazione is null
                            and mov_ts.validita_fine is NULL                           
                            and r_mov_bil_elem.data_cancellazione is null
                            and r_mov_bil_elem.validita_fine is NULL          
                            and r_mov_ts_stato.data_cancellazione is null
                            and r_mov_ts_stato.validita_fine is null
                            and mov_ts_det.data_cancellazione is null
                            and mov_ts_det.validita_fine is null
                            and d_mov_tipo.data_cancellazione is null
                            and d_mov_tipo.validita_fine is null              
                            and r_bil_elem_class.data_cancellazione is null
                            and r_bil_elem_class.validita_fine is null
                            and r_mov_ts_atto.data_cancellazione is null
                            and r_mov_ts_atto.validita_fine is null                         
                            and r_mov_ts.data_cancellazione is null
                            and r_mov_ts.validita_fine is null                         
                            and acc_ts.movgest_ts_id_padre is null                        
                            and acc.validita_fine is null
                            and acc.data_cancellazione is null
                            and acc_ts.validita_fine is null
                            and acc_ts.data_cancellazione is null                                                
                            and r_acc_ts_stato.validita_fine is null
                            and r_acc_ts_stato.data_cancellazione is null                                                
                                --21/05/2020 SIAC-7643 
                                --aggiunti i test sulle date che mancavano                        
                            and mov.validita_fine is null
                            and mov.data_cancellazione is null
                            and d_mov_ts_det_tipo.validita_fine is null
                            and d_mov_ts_det_tipo.data_cancellazione is null
                            and t_bil_elem.validita_fine is null
                            and t_bil_elem.data_cancellazione is null
                            and d_mov_stato.validita_fine is null
                            and d_mov_stato.data_cancellazione is null
                            and class.validita_fine is null
                            and class.data_cancellazione is null
                            and d_class_tipo.validita_fine is null
                            and d_class_tipo.data_cancellazione is null 
                            and atto.validita_fine is null
                            and atto.data_cancellazione is null                                                                                                                                                   
                           group by class.classif_code)
              union(
              	 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anni_succ_f, 
                          class.classif_code as programma_code
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
						  siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 	
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id  
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id    
                          and mov.bil_id = bilancio_id   
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno > annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM' 
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL    
                          and mov_ts.data_cancellazione is null
                          and mov_ts.validita_fine is NULL   
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null   
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                       
                  group by class.classif_code
              )
              union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno > anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  

    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.   
                    
             select sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anni_succ_f, 
                    class.classif_code as programma_code
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno > annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null  
                  	--impegni che arrivano da reimputazione       
                  and ((mov_ts.movgest_ts_id in  (
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo  
                                  --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id 
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
								   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con anno > dell'anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno > annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)                                              
				  --SIAC-8690 12/04/2022
                  --devo escludere gli impegni riaccertati il cui impegno origine
                  --l'anno precedente era vincolato verso FPV. 
                  --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null  
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                        
                      )) --fine impegni che arrivano da reimputazione 
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                   AND   (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code
              )   
              ) as x
                group by x.programma_code 
                )                               
select 
p_anno::varchar  bil_anno ,
''::varchar  missione_tipo_code ,
struttura.missione_tipo_desc ,
struttura.missione_code ,
struttura.missione_desc ,
''::varchar programma_tipo_code ,
struttura.programma_tipo_desc ,
struttura.programma_code ,
struttura.programma_desc ,
	--22/02/2019: SIAC-6623. 
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0) as fondo_plur_anno_prec_a,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)) fondo_plur_anno_prec_a,
--coalesce(var_spese_impe_anni_prec_b,0) as spese_impe_anni_prec_b,
coalesce(tbimpaprec.spese_impe_anni_prec,0) as spese_impe_anni_prec_b,
	--22/02/2019: SIAC-6623. 
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0)  as quota_fond_plur_anni_prec_c,
coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) spese_da_impeg_anno1_d,
coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0) spese_da_impeg_anno2_e,
coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0) spese_da_impeg_anni_succ_f,
coalesce(tbriaccx.riacc_colonna_x,0) riacc_colonna_x,
coalesce(tbriaccy.riacc_colonna_y,0) riacc_colonna_y,
	--22/02/2019: SIAC-6623.
--coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0)-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
--coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) + coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0)+coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0)
COALESCE(fpv_anno_prec_da_capitoli.importo_fpv_anno_prec,
	coalesce(fpv_anno_prec_da_variabili.spese_fpv_anni_prec,0))-coalesce(tbimpaprec.spese_impe_anni_prec,0)-coalesce(tbriaccx.riacc_colonna_x,0) - coalesce(tbriaccy.riacc_colonna_y,0) +
coalesce(imp_colonna_d.spese_da_impeg_anno1_d,0) + 
coalesce(imp_colonna_e.spese_da_impeg_anno2_e,0)+
coalesce(imp_colonna_f.spese_da_impeg_anni_succ_f,0)
as fondo_plur_anno_g 
from struttura left join tbimpaprec     
	on struttura.programma_code=tbimpaprec.programma_code
left join fpv_anno_prec_da_variabili 
	on struttura.programma_code=fpv_anno_prec_da_variabili.programma_code
left join tbriaccx     
	on struttura.programma_code=tbriaccx.programma_code
left join tbriaccy   
	on struttura.programma_code=tbriaccy.programma_code
left join imp_colonna_d   
	on struttura.programma_code=imp_colonna_d.programma_code
left join imp_colonna_e   
	on struttura.programma_code=imp_colonna_e.programma_code
left join imp_colonna_f   
	on struttura.programma_code=imp_colonna_f.programma_code
    	--22/02/2019: SIAC-6623.
left join fpv_anno_prec_da_capitoli
	on struttura.programma_code=fpv_anno_prec_da_capitoli.programma_code;
          

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato per struttura bilancio';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='struttura bilancio altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR147_Allegato_B_Fondo_Pluriennale_vincolato_Rend_new" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;
  
CREATE OR REPLACE FUNCTION siac."BILR259_Allegato_B_FPV_Rendiconto_dettaglio_BILR147" (
  p_ente_prop_id integer,
  p_anno varchar
)
RETURNS TABLE (
  colonna varchar,
  missione_programma varchar,
  capitolo varchar,
  anno_impegno integer,
  numero_impegno numeric,
  numero_modifica varchar,
  motivo_modifica_code varchar,
  motivo_modifica_desc varchar,
  importo numeric
) AS
$body$
DECLARE

annoCapImp varchar;
annoCapImp1 varchar;
annoCapImp2 varchar;
tipoImpComp varchar;
tipoImpCassa varchar;
tipoImpRes varchar;
elemTipoCode varchar;
DEF_NULL	constant varchar:=''; 
RTN_MESSAGGIO varchar(1000):=DEF_NULL;
annoPrec varchar;
annoProspInt integer;
annoBilInt integer;
conflagfpv boolean ;
a_dacapfpv boolean ;
h_dacapfpv boolean ;
flagretrocomp boolean ;

h_count integer :=0;
v_fam_missioneprogramma varchar :='00001';
v_fam_titolomacroaggregato varchar := '00002';
bilancio_id integer;
bilancio_id_anno1 integer;

BEGIN

annoCapImp:= p_anno; 
annoCapImp1:= ((p_anno::INTEGER)+1)::VARCHAR;   
annoCapImp2:= ((p_anno::INTEGER)+2)::VARCHAR; 
annoPrec:= ((p_anno::INTEGER)-1)::VARCHAR; 

TipoImpComp='STA';  -- competenza
TipoImpCassa='SCA'; -- cassa
TipoImpRes='STR';   -- residui
elemTipoCode:='CAP-UG'; -- tipo capitolo gestione

annoBilInt=p_anno::INTEGER;


missione_programma:='';
colonna:='';
capitolo:='';
anno_impegno:=0;
numero_impegno:=0;
numero_modifica:='';
motivo_modifica_code:='';
motivo_modifica_desc:='';
importo=0;

--Leggo l'id dell'anno bilancio
select bil.bil_id
into bilancio_id
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = p_anno
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;    

--Leggo l'id dell'anno bilancio +1
select bil.bil_id
into bilancio_id_anno1
from siac_t_bil bil,
	siac_t_periodo per
where bil.periodo_id=per.periodo_id
	and bil.ente_proprietario_id=p_ente_prop_id
    and per.anno = annoCapImp1
    and bil.data_cancellazione IS NULL
    and per.data_cancellazione IS NULL;   
            
raise notice 'Id bilancio anno % = % - Id bilancio anno % = %',
	p_anno, bilancio_id, annoCapImp1, bilancio_id_anno1;
        
/*
	15/02/2022. 
Questa funzione serve per estrarre il dettaglio degli impegni che popolano
le colonne del report BILR147.
Serve per soddisfare le richieste di dettaglio che arrivano dal CSI.
Per ora le colonne estratte sono: B, D, E, F, X e Y.

Le query eseguite sono quelle del report BILR147 nuovo, attualmente presente 
nel menu' 7.
    
	22/04/2022 SIAC-8634:
Procedura utilizzata per il report BILR259.
    
*/        

return query 
--Dati della Colonna B.
select 'colonna_B'::VARCHAR, class.classif_code missione_programma,
  bil_elem.elem_code capitolo, mov.movgest_anno anno_impegno, 
  mov.movgest_numero numero_impegno, 
  ''::varchar numero_modifica,
  ''::varchar motivo_modif_code,
  ''::varchar motivo_modif_desc,
	sum(coalesce( r_movgest_ts.movgest_ts_importo ,0)) spese_impe_anni_prec
          from siac_t_movgest mov,              
            siac_t_movgest_ts mov_ts, 
            siac_t_movgest_ts_det mov_ts_det,
            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
            siac_t_bil_elem bil_elem, 
            siac_r_movgest_bil_elem r_mov_bil_elem,
            siac_r_movgest_ts_stato r_mov_ts_stato, 
            siac_d_movgest_stato d_mov_stato,
            siac_r_bil_elem_class r_bil_elem_class,
            siac_t_class class, 
            siac_d_class_tipo d_class_tipo, 
            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
            siac_t_atto_amm atto,
            siac_d_movgest_tipo d_mov_tipo,
            siac_r_movgest_ts r_movgest_ts, 
            siac_t_avanzovincolo av_vincolo, 
            siac_d_avanzovincolo_tipo av_vincolo_tipo
          where mov.movgest_id = mov_ts.movgest_id  
          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
          and r_bil_elem_class.classif_id = class.classif_id
          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
          and bil_elem.elem_id=r_mov_bil_elem.elem_id
          and r_mov_bil_elem.movgest_id=mov.movgest_id 
          and r_movgest_ts.avav_id=av_vincolo.avav_id     
          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id            
          and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
          and mov.ente_proprietario_id= p_ente_prop_id    
          and mov.bil_id = bilancio_id            
          and d_class_tipo.classif_tipo_code='PROGRAMMA'
          and mov.movgest_anno = annoBilInt 
          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I'
          and d_mov_stato.movgest_stato_code in ('D', 'N')
          and d_mov_tipo.movgest_tipo_code='I' --Impegni      
          and av_vincolo_tipo.avav_tipo_code like'FPV%'
          and mov_ts.movgest_ts_id_padre is NULL  
          and r_mov_bil_elem.data_cancellazione is null
          and r_mov_bil_elem.validita_fine is NULL          
          and r_mov_ts_stato.data_cancellazione is null
          and r_mov_ts_stato.validita_fine is null
          and d_mov_tipo.data_cancellazione is null
          and d_mov_tipo.validita_fine is null              
          and r_bil_elem_class.data_cancellazione is null
          and r_bil_elem_class.validita_fine is null
          and r_mov_ts_atto.data_cancellazione is null
          and r_mov_ts_atto.validita_fine is null          
          and r_movgest_ts.data_cancellazione is null
          and r_movgest_ts.validita_fine is null            
          and mov.data_cancellazione is null
          and mov.validita_fine is NULL
          and mov_ts.data_cancellazione is null
          and mov_ts.validita_fine is NULL   
          and mov_ts_det.data_cancellazione is null
          and mov_ts_det.validita_fine is NULL   
          and d_mov_ts_det_tipo.data_cancellazione is null
          and d_mov_ts_det_tipo.validita_fine is NULL   
          and bil_elem.data_cancellazione is null
          and bil_elem.validita_fine is NULL   
          and d_mov_stato.data_cancellazione is null
          and d_mov_stato.validita_fine is NULL   
          and class.data_cancellazione is null
          and class.validita_fine is NULL   
          and d_class_tipo.data_cancellazione is null
          and d_class_tipo.validita_fine is NULL   
          and atto.data_cancellazione is null
          and atto.validita_fine is NULL   
          and av_vincolo.data_cancellazione is null
          and av_vincolo_tipo.data_cancellazione is null
          and av_vincolo_tipo.validita_fine is NULL              
        group by class.classif_code ,bil_elem.elem_code , 
        	mov.movgest_anno , mov.movgest_numero,
            numero_modifica,
            motivo_modif_code, motivo_modif_desc
union
--Colonna X		
select 'colonna_X'::varchar,  class.classif_code programma_code, 
		t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
        modif.mod_num::varchar numero_modifica,
        d_modif_tipo.mod_tipo_code || ' - '|| d_modif_tipo.mod_tipo_desc motivo_modif_code,
        modif.mod_desc motivo_modif_desc, 
	--sum(COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_x
        (sum((COALESCE(mov_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_x
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         mov_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
                    sum(r_mod_vinc.importo_delta) importo_delta 
              from siac_r_movgest_ts r_mov_ts,
                  siac_r_modifica_vincolo r_mod_vinc
              where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                and r_mov_ts.data_cancellazione IS NULL
                and r_mod_vinc.data_cancellazione IS NULL
              group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      	siac_t_movgest_ts_det_mod mov_ts_det_mod,
      	siac_t_movgest_ts mov_ts, 
      	siac_d_modifica_stato d_mod_stato,
        siac_t_movgest mov, 
        siac_d_movgest_tipo d_mov_tipo,       
        siac_t_modifica modif, 
        siac_d_modifica_tipo d_modif_tipo,
        siac_d_modifica_stato d_modif_stato, 
        siac_t_bil_elem t_bil_elem, 
        siac_r_movgest_bil_elem r_mov_bil_elem,
        siac_r_bil_elem_class r_bil_elem_class, 
        siac_t_class class, 
        siac_d_class_tipo d_class_tipo,
        siac_r_movgest_ts_atto_amm r_movgest_ts_atto_amm,
        siac_t_atto_amm atto_amm ,
        siac_r_movgest_ts_stato r_mov_ts_stato, 
        siac_d_movgest_stato d_mov_stato    
      where mov_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and mov_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_modif_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_movgest_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_movgest_ts_atto_amm.attoamm_id = atto_amm.attoamm_id
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mov_ts_stato.movgest_ts_id = mov_ts_det_mod.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id        
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno = anno del bilancio
        and mov.movgest_anno = annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I' 
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione 
      /*  and 
        ( d_modif_tipo.mod_tipo_code like  'ECON%'
           or d_modif_tipo.mod_tipo_desc like  'ROR%'
        )      
        and d_modif_tipo.mod_tipo_code <> 'REIMP' */                  
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_modif_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM') 
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and mov_ts_det_mod.data_cancellazione is null
        and mov_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_modif_tipo.data_cancellazione is null
        and d_modif_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_movgest_ts_atto_amm.data_cancellazione is null
        and r_movgest_ts_atto_amm.validita_fine is null
        and d_mov_stato.data_cancellazione is null
        and d_mov_stato.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                      siac_t_avanzovincolo av_vincolo, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id                                 
                  and mov_ts_det_mod.movgest_ts_id = r_movgest_ts.movgest_ts_b_id 
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%' 
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null 
                 )        
      group by class.classif_code ,t_bil_elem.elem_code , 
      mov.movgest_anno , mov.movgest_numero,
      modif.mod_num,
      motivo_modif_code,
      motivo_modif_desc
union    
--colonna Y
select 'colonna_Y'::varchar, class.classif_code programma_code, 
	t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
    modif.mod_num::varchar numero_modifica,
    d_mod_tipo.mod_tipo_code || ' - '|| d_mod_tipo.mod_tipo_desc motivo_modif_code,
    modif.mod_desc motivo_modif_desc, 
	--sum(COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)*-1) riacc_colonna_y
    (sum((COALESCE(movgest_ts_det_mod.movgest_ts_det_importo,0)-
    	COALESCE(vincoli_acc.importo_delta,0))*-1)) riacc_colonna_y  
      from siac_r_modifica_stato r_mod_stato
      /* SIAC-8676 24/03/2022.
      	 Nel caso in cui gli impegni siano vincolati sia ad accertamento che a 
         Fpv, e su tali impegni vengano effettuate delle cancellazioni (sia in
         Ror che in Reanno) occorre sottrare dall'importo della modifica 
         movgest_ts_det_mod.movgest_ts_det_importo l'importo della modifica del 
         vincolo vincoli_acc.importo_delta.      
      */      
      	left join (select r_mod_vinc.mod_id,
            				sum(r_mod_vinc.importo_delta) importo_delta 
                      from siac_r_movgest_ts r_mov_ts,
                          siac_r_modifica_vincolo r_mod_vinc
                      where r_mod_vinc.movgest_ts_r_id=r_mov_ts.movgest_ts_r_id 
                        and r_mov_ts.ente_proprietario_id=p_ente_prop_id                       
                        and r_mov_ts.movgest_ts_a_id IS NOT NULL --legato ad accertamento
                        and r_mov_ts.data_cancellazione IS NULL
                        and r_mod_vinc.data_cancellazione IS NULL
                      group by r_mod_vinc.mod_id) vincoli_acc
            on vincoli_acc.mod_id= r_mod_stato.mod_id, 
      siac_t_movgest_ts_det_mod movgest_ts_det_mod,
      siac_t_movgest_ts mov_ts, 
      siac_d_modifica_stato d_mod_stato,
      siac_t_movgest mov, 
      siac_d_movgest_tipo d_mov_tipo, 
      siac_t_modifica modif, 
      siac_d_modifica_tipo d_mod_tipo,
      siac_d_modifica_stato d_modif_stato, 
      siac_t_bil_elem t_bil_elem, 
      siac_r_movgest_bil_elem r_mov_bil_elem,
      siac_r_bil_elem_class r_bil_elem_class, 
      siac_t_class class, 
      siac_d_class_tipo d_class_tipo,
      siac_r_movgest_ts_atto_amm r_mov_ts_atto_amm, 
      siac_t_atto_amm atto_amm ,
      siac_r_movgest_ts_stato r_mov_ts_stato, 
      siac_d_movgest_stato d_mov_stato    
      where movgest_ts_det_mod.mod_stato_r_id=r_mod_stato.mod_stato_r_id
        and movgest_ts_det_mod.movgest_ts_id = mov_ts.movgest_ts_id
        and mov.movgest_tipo_id=d_mov_tipo.movgest_tipo_id
        and d_mod_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and mov.movgest_id=mov_ts.movgest_id        
        and modif.mod_id=r_mod_stato.mod_id
        and modif.mod_tipo_id=d_mod_tipo.mod_tipo_id
        and d_modif_stato.mod_stato_id=r_mod_stato.mod_stato_id
        and r_mov_ts_atto_amm.movgest_ts_id=mov_ts.movgest_ts_id
        and r_mov_ts_atto_amm.attoamm_id = atto_amm.attoamm_id        
        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
        and r_mov_bil_elem.movgest_id=mov.movgest_id
        and r_bil_elem_class.elem_id=t_bil_elem.elem_id
        and r_bil_elem_class.classif_id=class.classif_id
        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
        and r_mod_stato.ente_proprietario_id=p_ente_prop_id
        and mov.bil_id = bilancio_id
        	--anno dell'impegno > anno del bilancio
        and mov.movgest_anno > annoBilInt 
        and d_mod_stato.mod_stato_code='V'
        and d_mov_tipo.movgest_tipo_code='I'
        and d_modif_stato.mod_stato_code='V'
        --11/11/2021 SIAC-8250.
        --cambiano i filtri sul tipo modifica.
        -- devo prendere le Modifiche tipo:
        --tutte  tranne ROR reimputazione, REANNO, AGG, RidCoi.
        --REIMP e' ROR - Reimputazione         
  /*      and 
        ( d_mod_tipo.mod_tipo_code like  'ECON%'
           or d_mod_tipo.mod_tipo_desc like  'ROR%'
        )
        and d_mod_tipo.mod_tipo_code <> 'REIMP' */
/* 18/03/2022 - SIAC-8670.
	Devono essere esclusi i seguenti codici:
      --REANNO - REANNO - Reimputazione in corso d'anno
      --AGG - Aggiudicazione
      --RIDCOI - riduzione con contestuale prenotazione/impegno
      --RIU - Riutilizzo
      --REIMP -ROR - Reimputazione
      --RORM - ROR - Da mantenere
      
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
          'RIDCOI', 'AGG') 

*/        
        and d_mod_tipo.mod_tipo_code not in('REIMP', 'REANNO',
        		'RIDCOI', 'AGG','RIU', 'RORM')       
        and d_class_tipo.classif_tipo_code='PROGRAMMA'
        and r_mov_ts_stato.movgest_ts_id = mov_ts.movgest_ts_id
        and r_mov_ts_stato.movgest_stato_id = d_mov_stato.movgest_stato_id
        and d_mov_stato.movgest_stato_code in ('D', 'N')
        and r_mov_ts_stato.data_cancellazione is NULL
        and r_mov_ts_stato.validita_fine is null
        and mov_ts.movgest_ts_id_padre is null
        and r_mod_stato.data_cancellazione is null
        and r_mod_stato.validita_fine is null
        and movgest_ts_det_mod.data_cancellazione is null
        and movgest_ts_det_mod.validita_fine is null
        and mov_ts.data_cancellazione is null
        and mov_ts.validita_fine is null
        and d_mod_stato.data_cancellazione is null
        and d_mod_stato.validita_fine is null
        and mov.data_cancellazione is null
        and mov.validita_fine is null
        and d_mov_tipo.data_cancellazione is null
        and d_mov_tipo.validita_fine is null
        and modif.data_cancellazione is null
        and modif.validita_fine is null
        and d_mod_tipo.data_cancellazione is null
        and d_mod_tipo.validita_fine is null
        and d_modif_stato.data_cancellazione is null
        and d_modif_stato.validita_fine is null
        and t_bil_elem.data_cancellazione is null
        and t_bil_elem.validita_fine is null
        and r_mov_bil_elem.data_cancellazione is null
        and r_mov_bil_elem.validita_fine is null
        and r_bil_elem_class.data_cancellazione is null
        and r_bil_elem_class.validita_fine is null
        and class.data_cancellazione is null
        and class.validita_fine is null
        and d_class_tipo.data_cancellazione is null
        and d_class_tipo.validita_fine is null
        and r_mov_ts_atto_amm.data_cancellazione is null
        and r_mov_ts_atto_amm.validita_fine is null
        and exists (select 
                  1 
                  from siac_r_movgest_ts r_movgest_ts, 
                  siac_t_avanzovincolo av_vincolo, 
                  siac_d_avanzovincolo_tipo av_vincolo_tipo
              where r_movgest_ts.avav_id=av_vincolo.avav_id     
                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                  and mov_ts.movgest_ts_id = r_movgest_ts.movgest_ts_b_id
                  and r_movgest_ts.ente_proprietario_id=p_ente_prop_id
                  and av_vincolo_tipo.avav_tipo_code like'FPV%'                                      
                  and r_movgest_ts.data_cancellazione is null
                  and r_movgest_ts.validita_fine is null )
      group by class.classif_code ,t_bil_elem.elem_code , 
      	mov.movgest_anno , mov.movgest_numero,
        modif.mod_num,
        motivo_modif_code,
        motivo_modif_desc        
union
--colonna D		
select 'colonna_D'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno, 
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
  		''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,        
		sum(x.spese_da_impeg_anno1_d) as spese_da_impeg_anno1_d from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_d
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 1
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code ,t_bil_elem.elem_code , 
                           mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              	mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_d
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 1
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = '2021'   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code ,t_bil_elem.elem_code , 
                      	mov.movgest_anno , mov.movgest_numero
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_d
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 1
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                  and ((mov_ts.movgest_ts_id in  (
                          --impegni che arrivano da reimputazione 
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                    		--16/03/2022: corretto id del bilancio.
                        --and reimp.bil_id=147  --anno bilancio 
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--non esiste su siac_r_movgest_ts 
                              --SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)                              
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id = NULL
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure esiste con un vincolo di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                  --SIAC-8682 - 07/04/2022.
                                  --il legame e' con l'impegno e non quello origine del riaccertamento.
                                --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure esiste con un vincolo con accertamento anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                    --il legame e' con l'impegno e non quello origine del riaccertamento.
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL)))
								   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +1).
                              AND  not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +1
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)
				--SIAC-8690 12/04/2022
                --devo escludere gli impegni riaccertati il cui impegno origine
                --l'anno precedente era vincolato verso FPV. 
                --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null                                      
                                      and upper(r_mov_attr1.testo) <> 'NULL'
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr2.testo) <> 'NULL'
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                          
                             )) AND
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                      (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code ,t_bil_elem.elem_code , 
              mov.movgest_anno , mov.movgest_numero)    
              ) as x
     group by x.programma_code ,x.elem_code, 
     	x.movgest_anno,x.movgest_numero,
        numero_modifica,
        motivo_modif_code, motivo_modif_desc      
union
--colonna E		
select 'colonna_E'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno,         
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
        ''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,
		sum(x.spese_da_impeg_anno1_e) as spese_da_impeg_anno1_e from (
               ( --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati accertamenti con anno = anno bilancio
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      as spese_da_impeg_anno1_e
                        from siac_t_movgest mov,                           
                        siac_t_movgest_ts mov_ts, 
                        siac_t_movgest_ts_det mov_ts_det,
                        siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                        siac_t_bil_elem t_bil_elem, 
                        siac_r_movgest_bil_elem r_mov_bil_elem,
                        siac_r_movgest_ts_stato r_mov_ts_stato, 
                        siac_d_movgest_stato d_mov_stato,
                        siac_r_bil_elem_class r_bil_elem_class,
                        siac_t_class class, 
                        siac_d_class_tipo d_class_tipo, 
                        siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                        siac_t_atto_amm atto, 
                        siac_d_movgest_tipo d_mov_tipo,
                        siac_r_movgest_ts r_mov_ts,                          
                        siac_t_movgest_ts acc_ts,
                        siac_t_movgest acc,
                        siac_r_movgest_ts_stato r_acc_ts_stato,
                        siac_d_movgest_stato d_acc_stato
                      where mov.movgest_id = mov_ts.movgest_id  
                        and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                        and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                        and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                        and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                        and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                        and r_bil_elem_class.classif_id = class.classif_id
                        and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                        and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                        and r_mov_ts_atto.movgest_ts_id=mov_ts_det.movgest_ts_id
                        and r_mov_ts_atto.attoamm_id = atto.attoamm_id                        
                        and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                        and r_mov_bil_elem.movgest_id=mov.movgest_id 
                        and mov_ts_det.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                        and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                        and acc_ts.movgest_id = acc.movgest_id
                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id                                                
                        and mov.ente_proprietario_id= p_ente_prop_id    
                        and mov.bil_id = bilancio_id  
                        and d_class_tipo.classif_tipo_code='PROGRAMMA'
                        and mov.movgest_anno = annoBilInt + 2
                        and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                        and d_mov_stato.movgest_stato_code in ('D', 'N')
                        and d_mov_tipo.movgest_tipo_code='I' --Impegno
                        and acc.movgest_anno = annoBilInt
                        and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                        and mov_ts.movgest_ts_id_padre is NULL                         
                        and r_mov_bil_elem.data_cancellazione is null
                        and r_mov_bil_elem.validita_fine is NULL          
                        and r_mov_ts_stato.data_cancellazione is null
                        and r_mov_ts_stato.validita_fine is null
                        and mov_ts_det.data_cancellazione is null
                        and mov_ts_det.validita_fine is null
                        and d_mov_tipo.data_cancellazione is null
                        and d_mov_tipo.validita_fine is null              
                        and r_bil_elem_class.data_cancellazione is null
                        and r_bil_elem_class.validita_fine is null
                        and r_mov_ts_atto.data_cancellazione is null
                        and r_mov_ts_atto.validita_fine is null                        
                        and r_mov_ts.data_cancellazione is null
                        and r_mov_ts.validita_fine is null                         
                        and acc_ts.movgest_ts_id_padre is null                        
                        and acc.validita_fine is null
                        and acc.data_cancellazione is null
                        and acc_ts.validita_fine is null
                        and acc_ts.data_cancellazione is null                                                
                        and r_acc_ts_stato.validita_fine is null
                        and r_acc_ts_stato.data_cancellazione is null
                        	--21/05/2020 SIAC-7643 
            				--aggiunti i test sulle date che mancavano
                        and mov.validita_fine is null
                        and mov.data_cancellazione is null
                        and mov_ts.validita_fine is null
                        and mov_ts.data_cancellazione is null
                        and d_mov_ts_det_tipo.validita_fine is null
                        and d_mov_ts_det_tipo.data_cancellazione is null
                        and t_bil_elem.validita_fine is null
                        and t_bil_elem.data_cancellazione is null
                        and class.validita_fine is null
                        and class.data_cancellazione is null
                        and d_class_tipo.validita_fine is null
                        and d_class_tipo.data_cancellazione is null
                        and atto.validita_fine is null
                        and atto.data_cancellazione is null                        
                           group by class.classif_code ,t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno = anno bilancio + 1
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato
              select class.classif_code programma_code, t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anno1_e
                        from siac_t_movgest mov,  
                            siac_t_movgest_ts mov_ts, 
                            siac_t_movgest_ts_det mov_ts_det,
                            siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                            siac_t_bil_elem t_bil_elem, 
                            siac_r_movgest_bil_elem r_mov_bil_elem,
                            siac_r_movgest_ts_stato r_mov_ts_stato, 
                            siac_d_movgest_stato d_mov_stato,
                            siac_r_bil_elem_class r_bil_elem_class,
                            siac_t_class class, 
                            siac_d_class_tipo d_class_tipo, 
                            siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                            siac_t_atto_amm atto, 
                            siac_d_movgest_tipo d_mov_tipo,
                            siac_r_movgest_ts r_mov_ts, 
                            siac_t_avanzovincolo av_vincolo, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo 
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id     
                          and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id 
                          and mov.ente_proprietario_id= p_ente_prop_id      
                          and mov.bil_id = bilancio_id            
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno = annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and av_vincolo_tipo.avav_tipo_code = 'AAM'
                          --and r.attoamm_anno = '2021'   
                          and mov_ts.movgest_ts_id_padre is NULL                              
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null                                                                               
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and av_vincolo_tipo.validita_fine is null
                          and av_vincolo_tipo.data_cancellazione is null
                      group by class.classif_code ,t_bil_elem.elem_code , mov.movgest_anno , mov.movgest_numero
              )--- Impegni da riaccertamento - reimputazione nel bilancio successivo 
    		union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno=anno corrente +1
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  .
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.            
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              		sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anno1_e
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno = annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null    
                  	--impegni che arrivano da reimputazione    
                  and ((mov_ts.movgest_ts_id in  (                          
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                 --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                     --SIAC-8682 - 07/04/2022.
                                     --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
                                   --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con lo stesso anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno = annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL) 
          --SIAC-8690 12/04/2022
          --devo escludere gli impegni riaccertati il cui impegno origine
          --l'anno precedente era vincolato verso FPV. 
          --AAM e' accettato.                                       
              AND  not exists (select 1                          
                    from siac_t_movgest_ts t_mov_ts1                                                            
                     join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                            from siac_r_movgest_ts_attr r_mov_attr1,
                             siac_t_attr attr1
                            where r_mov_attr1.attr_id=attr1.attr_id
                                and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                and upper(r_mov_attr1.testo) <> 'NULL'                                
                                and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                            on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                      join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                            from siac_r_movgest_ts_attr r_mov_attr2,
                             siac_t_attr attr2
                            where r_mov_attr2.attr_id=attr2.attr_id
                                and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                and upper(r_mov_attr2.testo) <> 'NULL'                                
                                and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                          on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                      siac_r_movgest_ts r_mov_ts1,
                      siac_t_movgest_ts imp_ts1,
                      siac_t_movgest imp1,
                      siac_t_avanzovincolo av_vincolo1, 
                      siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                     where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                     and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                      and imp_ts1.movgest_id=imp1.movgest_id
                      and r_mov_ts1.avav_id=av_vincolo1.avav_id
                      and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                      and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                      and imp1.bil_id=bilancio_id --anno bilancio
                      and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                      and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                      and av_vincolo_tipo1.avav_tipo_code<>'AAM'
                          --se movgest_ts_a_id = NULL
                          --il vincolo non e' verso accertamento.
                      and r_mov_ts1.movgest_ts_a_id IS NULL
                      and r_mov_ts1.data_cancellazione IS NULL   
                      and imp_ts1.data_cancellazione IS NULL 
                      and imp1.data_cancellazione IS NULL
                      and av_vincolo1.data_cancellazione IS NULL)                                                                                      
                  )))--fine impegni che arrivano da reimputazione  
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                    AND  (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL))                                                                                                          
              group by class.classif_code ,t_bil_elem.elem_code , 
              	mov.movgest_anno , mov.movgest_numero)    
              ) as x
        group by x.programma_code ,x.elem_code, x.movgest_anno,
            x.movgest_numero,
            numero_modifica,
            motivo_modif_code,
            motivo_modif_desc   
union                   
--Colonna F
select 'colonna_F'::varchar, x.programma_code missione_programma,
		x.elem_code capitolo, x.movgest_anno anno_impegno,         
		x.movgest_numero numero_impegno,
        ''::varchar numero_modifica,
        ''::varchar motivo_modif_code,
  		''::varchar motivo_modif_desc,
		sum(x.spese_da_impeg_anni_succ_f) as spese_da_impeg_anni_succ_f from (
               (
 				 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati accertamenti con anno = anno bilancio               
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              	sum(COALESCE(r_mov_ts.movgest_ts_importo,0))
                      		as spese_da_impeg_anni_succ_f
                        from siac_t_movgest mov,  
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
                          siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_movgest_ts acc_ts,
                          siac_t_movgest acc,
                          siac_r_movgest_ts_stato r_acc_ts_stato,
                          siac_d_movgest_stato d_acc_stato
                        where mov.movgest_id = mov_ts.movgest_id  
                            and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                            and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                            and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                            and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                            and r_bil_elem_class.classif_id = class.classif_id
                            and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                            and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                            and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                            and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                            and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                            and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id
                            and r_mov_ts.movgest_ts_a_id = acc_ts.movgest_ts_id
                            and acc_ts.movgest_id = acc.movgest_id
                            and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                            and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id
                            and r_mov_bil_elem.movgest_id=mov.movgest_id 
                            and mov.ente_proprietario_id= p_ente_prop_id 
                            and mov.bil_id = bilancio_id     
                            and d_class_tipo.classif_tipo_code='PROGRAMMA'
                            and mov.movgest_anno > annoBilInt + 2
                            and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                            and d_mov_stato.movgest_stato_code in ('D', 'N')
                            and d_mov_tipo.movgest_tipo_code='I' 
                            and acc.movgest_anno = annoBilInt
                            and d_acc_stato.movgest_stato_code in ('D', 'N')                        
                            --and atto.attoamm_anno = p_anno   
                            and mov_ts.movgest_ts_id_padre is NULL  
                            and mov_ts.data_cancellazione is null
                            and mov_ts.validita_fine is NULL                           
                            and r_mov_bil_elem.data_cancellazione is null
                            and r_mov_bil_elem.validita_fine is NULL          
                            and r_mov_ts_stato.data_cancellazione is null
                            and r_mov_ts_stato.validita_fine is null
                            and mov_ts_det.data_cancellazione is null
                            and mov_ts_det.validita_fine is null
                            and d_mov_tipo.data_cancellazione is null
                            and d_mov_tipo.validita_fine is null              
                            and r_bil_elem_class.data_cancellazione is null
                            and r_bil_elem_class.validita_fine is null
                            and r_mov_ts_atto.data_cancellazione is null
                            and r_mov_ts_atto.validita_fine is null                         
                            and r_mov_ts.data_cancellazione is null
                            and r_mov_ts.validita_fine is null                         
                            and acc_ts.movgest_ts_id_padre is null                        
                            and acc.validita_fine is null
                            and acc.data_cancellazione is null
                            and acc_ts.validita_fine is null
                            and acc_ts.data_cancellazione is null                                                
                            and r_acc_ts_stato.validita_fine is null
                            and r_acc_ts_stato.data_cancellazione is null                                                
                                --21/05/2020 SIAC-7643 
                                --aggiunti i test sulle date che mancavano                        
                            and mov.validita_fine is null
                            and mov.data_cancellazione is null
                            and d_mov_ts_det_tipo.validita_fine is null
                            and d_mov_ts_det_tipo.data_cancellazione is null
                            and t_bil_elem.validita_fine is null
                            and t_bil_elem.data_cancellazione is null
                            and d_mov_stato.validita_fine is null
                            and d_mov_stato.data_cancellazione is null
                            and class.validita_fine is null
                            and class.data_cancellazione is null
                            and d_class_tipo.validita_fine is null
                            and d_class_tipo.data_cancellazione is null 
                            and atto.validita_fine is null
                            and atto.data_cancellazione is null                                                                                                                                                   
                           group by class.classif_code,
                             t_bil_elem.elem_code , 
                              mov.movgest_anno , mov.movgest_numero)
              union(
              	 --impegni dell'anno bilancio con anno > anno bilancio + 2
               	 -- legati a vincoli di tipo AAM - Avanzo Vincolato              
              select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
              sum(COALESCE(r_mov_ts.movgest_ts_importo,0)) AS
                          spese_da_impeg_anni_succ_f
                        from siac_t_movgest mov,                            
                          siac_t_movgest_ts mov_ts, 
                          siac_t_movgest_ts_det mov_ts_det,
                          siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                          siac_t_bil_elem t_bil_elem, 
                          siac_r_movgest_bil_elem r_mov_bil_elem,
                          siac_r_movgest_ts_stato r_mov_ts_stato, 
                          siac_d_movgest_stato d_mov_stato,
                          siac_r_bil_elem_class r_bil_elem_class,
                          siac_t_class class, 
                          siac_d_class_tipo d_class_tipo, 
                          siac_r_movgest_ts_atto_amm r_mov_ts_atto,
                          siac_t_atto_amm atto, 
						  siac_d_movgest_tipo d_mov_tipo,
                          siac_r_movgest_ts r_mov_ts, 
                          siac_t_avanzovincolo av_vincolo, 
                          siac_d_avanzovincolo_tipo d_av_vincolo_tipo 	
                        where mov.movgest_id = mov_ts.movgest_id  
                          and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                          and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                          and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                          and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                          and r_bil_elem_class.classif_id = class.classif_id
                          and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                          and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                          and r_mov_ts_atto.movgest_ts_id=mov_ts.movgest_ts_id
                          and r_mov_ts_atto.attoamm_id = atto.attoamm_id
                          and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                          and av_vincolo.avav_tipo_id=d_av_vincolo_tipo.avav_tipo_id 
                          and mov_ts.movgest_ts_id = r_mov_ts.movgest_ts_b_id 
                          and r_mov_ts.avav_id=av_vincolo.avav_id  
                          and r_mov_bil_elem.movgest_id=mov.movgest_id 
                          and mov.ente_proprietario_id= p_ente_prop_id    
                          and mov.bil_id = bilancio_id   
                          and d_class_tipo.classif_tipo_code='PROGRAMMA'
                          and mov.movgest_anno > annoBilInt + 2
                          and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='A'
                          and d_mov_stato.movgest_stato_code in ('D', 'N')
                          and d_mov_tipo.movgest_tipo_code='I' 
                          and d_av_vincolo_tipo.avav_tipo_code = 'AAM' 
                          --and atto.attoamm_anno = p_anno   
                          and mov_ts.movgest_ts_id_padre is NULL    
                          and mov_ts.data_cancellazione is null
                          and mov_ts.validita_fine is NULL   
                          and r_mov_bil_elem.data_cancellazione is null
                          and r_mov_bil_elem.validita_fine is NULL          
                          and r_mov_ts_stato.data_cancellazione is null
                          and r_mov_ts_stato.validita_fine is null
                          and mov_ts_det.data_cancellazione is null
                          and mov_ts_det.validita_fine is null
                          and d_mov_tipo.data_cancellazione is null
                          and d_mov_tipo.validita_fine is null              
                          and r_bil_elem_class.data_cancellazione is null
                          and r_bil_elem_class.validita_fine is null
                          and r_mov_ts_atto.data_cancellazione is null
                          and r_mov_ts_atto.validita_fine is null
                          and r_mov_ts.data_cancellazione is null
                          and r_mov_ts.validita_fine is null 
                              --21/05/2020 SIAC-7643 
                              --aggiunti i test sulle date che mancavano                        
                          and mov.validita_fine is null
                          and mov.data_cancellazione is null
                          and d_mov_ts_det_tipo.validita_fine is null
                          and d_mov_ts_det_tipo.data_cancellazione is null
                          and t_bil_elem.validita_fine is null
                          and t_bil_elem.data_cancellazione is null
                          and d_mov_stato.validita_fine is null
                          and d_mov_stato.data_cancellazione is null
                          and class.validita_fine is null
                          and class.data_cancellazione is null
                          and d_class_tipo.validita_fine is null
                          and d_class_tipo.data_cancellazione is null
                          --and av_vincolo.validita_fine is null
                          and av_vincolo.data_cancellazione is null
                          and d_av_vincolo_tipo.validita_fine is null
                          and d_av_vincolo_tipo.data_cancellazione is null   
                          and atto.validita_fine is null
                          and atto.data_cancellazione is null                       
                  group by class.classif_code,
                  	t_bil_elem.elem_code , 
              				mov.movgest_anno , mov.movgest_numero)
              union(
    --   Importo iniziale di impegni in
    --    anno_bilancio=anno corrente +1
    --    anno_impegno > anno corrente +2
    --    che arrivano da rimputazione impegni in anno_bilancio=anno corrente 
    --    esiste movgest_Ts_id in fase_bil_t_reimputazione.movgestnew_ts_id
    --    e fase_bil_t_reimputazione.movgest_ts_id per cui 
    --    non esiste siac_r_movgest_ts, su movgest_ts_b_id (senza vincolo )
    --    oppure esiste vincolo AAM
    --    oppure esiste vincolo su accertamento con anno_accertamento=anno corrente  
	-- Ed inoltre Importo iniziale di impegni in
	--anno_bilancio=anno corrente +1
	--anno_impegno=anno corrente+1
	--che non siano nati da riaggiudicazione quindi movgest_Ts_id che non sia 
    --presente in siac_r_movgest_aggiudicazione.movgest_ts_b_id  
    
    -- SIAC-8682 - 07/04/2022.
    --E' necessario NON estrarre gli impegni con anno successivo all'anno 
    --bilancio che, anche se riaccertati, sono collegati ad accertamenti con 
    --anno = all'anno dell'impegno.                  
             select class.classif_code programma_code, t_bil_elem.elem_code , 
              		mov.movgest_anno , mov.movgest_numero,
             sum(COALESCE(mov_ts_det.movgest_ts_det_importo,0)) AS
                    spese_da_impeg_anni_succ_f
                from siac_t_movgest mov,  
                siac_t_movgest_ts mov_ts, 
                siac_t_movgest_ts_det mov_ts_det,
                siac_d_movgest_ts_det_tipo d_mov_ts_det_tipo, 
                siac_t_bil_elem t_bil_elem, 
                siac_r_movgest_bil_elem r_mov_bil_elem,
                siac_r_movgest_ts_stato r_mov_ts_stato, 
                siac_d_movgest_stato d_mov_stato,
                siac_r_bil_elem_class r_bil_elem_class,
                siac_t_class class, 
                siac_d_class_tipo d_class_tipo, 
                siac_d_movgest_tipo d_mov_tipo
                where mov.movgest_id = mov_ts.movgest_id  
                  and mov_ts.movgest_ts_id = mov_ts_det.movgest_ts_id
                  and mov_ts_det.movgest_ts_det_tipo_id =d_mov_ts_det_tipo.movgest_ts_det_tipo_id
                  and d_mov_tipo.movgest_tipo_id=mov.movgest_tipo_id
                  and r_mov_ts_stato.movgest_ts_id=mov_ts.movgest_ts_id
                  and r_mov_ts_stato.movgest_stato_id=d_mov_stato.movgest_stato_id
                  and r_bil_elem_class.classif_id = class.classif_id
                  and class.classif_tipo_id=d_class_tipo.classif_tipo_id
                  and r_bil_elem_class.elem_id = r_mov_bil_elem.elem_id
                  and t_bil_elem.elem_id=r_mov_bil_elem.elem_id
                  and r_mov_bil_elem.movgest_id=mov_ts.movgest_id                                                  
                  and mov.ente_proprietario_id= p_ente_prop_id  
                  and mov.bil_id = bilancio_id_anno1 --anno successivo     
                  and d_class_tipo.classif_tipo_code='PROGRAMMA'
                  and mov.movgest_anno > annoBilInt + 2
                  and d_mov_ts_det_tipo.movgest_ts_det_tipo_code='I' --importo iniziale
                  and d_mov_stato.movgest_stato_code <> 'A'
                  and d_mov_tipo.movgest_tipo_code='I'   
                  and mov_ts.movgest_ts_id_padre is NULL    
                  and r_mov_bil_elem.data_cancellazione is null
                  and r_mov_bil_elem.validita_fine is NULL          
                  and r_mov_ts_stato.data_cancellazione is null
                  and r_mov_ts_stato.validita_fine is null
                  and mov_ts_det.data_cancellazione is null
                  and mov_ts_det.validita_fine is null
                  and d_mov_tipo.data_cancellazione is null
                  and d_mov_tipo.validita_fine is null              
                  and r_bil_elem_class.data_cancellazione is null
                  and r_bil_elem_class.validita_fine is null                 
                  and mov.validita_fine is null
                  and mov.data_cancellazione is null
                  and d_mov_ts_det_tipo.validita_fine is null
                  and d_mov_ts_det_tipo.data_cancellazione is null
                  and t_bil_elem.validita_fine is null
                  and t_bil_elem.data_cancellazione is null
                  and d_mov_stato.validita_fine is null
                  and d_mov_stato.data_cancellazione is null
                  and class.validita_fine is null
                  and class.data_cancellazione is null
                  and d_class_tipo.validita_fine is null
                  and d_class_tipo.data_cancellazione is null       
                     --impegni che arrivano da reimputazione 
                  and ((mov_ts.movgest_ts_id in  (
                    select reimp.movgestnew_ts_id
                    from fase_bil_t_reimputazione reimp
                    where reimp.ente_proprietario_id=p_ente_prop_id
                        and reimp.bil_id=bilancio_id  --anno bilancio       
                        and ((--SIAC-8682 - 07/04/2022
                              --l'impegno origine del riaccertamento 
                        	  --non deve avere un vincolo verso FPV
                              --quindi non esiste su siac_r_movgest_ts 
                              --con r_mov_ts.movgest_ts_a_id = NULL (accertamento)
                              not exists (select 1
                                from siac_r_movgest_ts r_mov_ts
                                where r_mov_ts.movgest_ts_b_id= reimp.movgest_ts_id
                                    and r_mov_ts.ente_proprietario_id=p_ente_prop_id
                                    --non deve esistere un vincolo verso FPV, 
                                    --quello verso accertamento e' accettato.
                                    and r_mov_ts.movgest_ts_a_id IS NULL 
                                    and r_mov_ts.data_cancellazione IS NULL)) OR
                              (--oppure l'impegno riaccertato ha un vincolo 
                               --di tipo AAM
                               exists ( select 1
                                from siac_r_movgest_ts r_mov_ts1,
                                  siac_t_avanzovincolo av_vincolo, 
                                  siac_d_avanzovincolo_tipo av_vincolo_tipo   
                                  --SIAC-8682 - 07/04/2022.
                                 --il legame e' con l'impegno e non quello origine del riaccertamento.
                                 --where r_mov_ts1.movgest_ts_b_id= reimp.movgest_ts_id
                                where r_mov_ts1.movgest_ts_b_id= reimp.movgestnew_ts_id
                                  and r_mov_ts1.avav_id=av_vincolo.avav_id    
                                  and av_vincolo.avav_tipo_id=av_vincolo_tipo.avav_tipo_id
                                  and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                                  and av_vincolo_tipo.avav_tipo_code='AAM'
                                  and r_mov_ts1.data_cancellazione IS NULL
                                  and av_vincolo.data_cancellazione IS NULL)) OR
                                (--oppure l'impegno riaccertato
                                 --ha un vincolo con accertamento 
                                 --con anno = anno bilancio
                                 exists (select 1
                                    from siac_r_movgest_ts r_mov_ts2,
                                        siac_t_movgest_ts acc_ts,
                                        siac_t_movgest acc,
                                        siac_r_movgest_ts_stato r_acc_ts_stato,
                                        siac_d_movgest_stato d_acc_stato
                                    --SIAC-8682 - 07/04/2022.
                                     --il legame e' con l'impegno e non quello origine del riaccertamento.                                
                                    --where r_mov_ts2.movgest_ts_b_id=reimp.movgest_ts_id
                                    where r_mov_ts2.movgest_ts_b_id=reimp.movgestnew_ts_id
                                        and r_mov_ts2.movgest_ts_a_id = acc_ts.movgest_ts_id
                                        and acc_ts.movgest_id = acc.movgest_id
                                        and r_acc_ts_stato.movgest_ts_id=acc_ts.movgest_ts_id
                                        and r_acc_ts_stato.movgest_stato_id=d_acc_stato.movgest_stato_id 
                                        and r_mov_ts2.ente_proprietario_id=p_ente_prop_id
                                        and acc.movgest_anno = annoBilInt 
                                        and d_acc_stato.movgest_stato_code in ('D', 'N') 
                                        and acc_ts.data_cancellazione IS NULL
                                        and acc.data_cancellazione IS NULL
                                        and r_acc_ts_stato.data_cancellazione IS NULL
                                        and d_acc_stato.data_cancellazione IS NULL))) AND
                                  --SIAC-8682 - 07/04/2022.
                                   --anche se riaccertato NON deve avere un vincolo verso accertamento
                                   --con anno > dell'anno dell'impegno (annoBilInt +2).
                                not exists (select 1
                                    from siac_r_movgest_ts r_mov_ts3,
                                        siac_t_movgest_ts acc_ts3,
                                        siac_t_movgest acc3,
                                        siac_r_movgest_ts_stato r_acc_ts_stato3,
                                        siac_d_movgest_stato d_acc_stato3
                                    where r_mov_ts3.movgest_ts_b_id=reimp.movgestnew_ts_id--reimp.movgest_ts_id---QUI
                                        and r_mov_ts3.movgest_ts_a_id = acc_ts3.movgest_ts_id
                                        and acc_ts3.movgest_id = acc3.movgest_id
                                        and r_acc_ts_stato3.movgest_ts_id=acc_ts3.movgest_ts_id
                                        and r_acc_ts_stato3.movgest_stato_id=d_acc_stato3.movgest_stato_id 
                                        and r_mov_ts3.ente_proprietario_id=p_ente_prop_id
                                        and acc3.movgest_anno > annoBilInt +2
                                        and d_acc_stato3.movgest_stato_code in ('D', 'N') 
                                        and acc_ts3.data_cancellazione IS NULL
                                        and acc3.data_cancellazione IS NULL
                                        and r_acc_ts_stato3.data_cancellazione IS NULL
                                        and d_acc_stato3.data_cancellazione IS NULL)  
                  --SIAC-8690 12/04/2022
                  --devo escludere gli impegni riaccertati il cui impegno origine
                  --l'anno precedente era vincolato verso FPV. 
                  --AAM e' accettato.                                       
					AND  not exists (select 1                          
                          from siac_t_movgest_ts t_mov_ts1                                                            
                           join (select r_mov_attr1.movgest_ts_id, r_mov_attr1.testo annoRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr1,
                                   siac_t_attr attr1
                                  where r_mov_attr1.attr_id=attr1.attr_id
                                      and r_mov_attr1.ente_proprietario_id=p_ente_prop_id
                                      and attr1.attr_code='annoRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr1.testo) <> 'NULL'                                      
                                      and r_mov_attr1.data_cancellazione IS NULL) annoRiacc
                                  on annoRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id
                            join (select r_mov_attr2.movgest_ts_id, r_mov_attr2.testo numeroRiaccertamento               
                                  from siac_r_movgest_ts_attr r_mov_attr2,
                                   siac_t_attr attr2
                                  where r_mov_attr2.attr_id=attr2.attr_id
                                      and r_mov_attr2.ente_proprietario_id=p_ente_prop_id
                                      and attr2.attr_code='numeroRiaccertato'
                                      --INC000006096414 aggiunto test
                                      --perche' ci sono record 
                                      --che contengono il testo null
                                      and upper(r_mov_attr2.testo) <> 'NULL'                                      
                                      and r_mov_attr2.data_cancellazione IS NULL) numeroRiacc
                                on numeroRiacc.movgest_ts_id=t_mov_ts1.movgest_ts_id,                                
                            siac_r_movgest_ts r_mov_ts1,
                            siac_t_movgest_ts imp_ts1,
                            siac_t_movgest imp1,
                            siac_t_avanzovincolo av_vincolo1, 
                            siac_d_avanzovincolo_tipo av_vincolo_tipo1 
                           where t_mov_ts1.movgest_ts_id=reimp.movgestnew_ts_id
                           and r_mov_ts1.movgest_ts_b_id=imp_ts1.movgest_ts_id
                            and imp_ts1.movgest_id=imp1.movgest_id
                            and r_mov_ts1.avav_id=av_vincolo1.avav_id
                            and av_vincolo1.avav_tipo_id=av_vincolo_tipo1.avav_tipo_id
                            and r_mov_ts1.ente_proprietario_id=p_ente_prop_id
                            and imp1.bil_id=bilancio_id --anno bilancio
                            and imp1.movgest_anno=annoRiacc.annoriaccertamento::integer
                            and imp1.movgest_numero=numeroRiacc.numeroriaccertamento::numeric --mov.movgest_numero
                            and av_vincolo_tipo1.avav_tipo_code<>'AAM'
								--se movgest_ts_a_id = NULL
                                --il vincolo non e' verso accertamento.
                            and r_mov_ts1.movgest_ts_a_id IS NULL
                            and r_mov_ts1.data_cancellazione IS NULL   
                            and imp_ts1.data_cancellazione IS NULL 
                            and imp1.data_cancellazione IS NULL
                            and av_vincolo1.data_cancellazione IS NULL)                                        
                 ))--fine impegni che arrivano da reimputazione 
              --OPPURE impegni che non devono essere nati da riaggiudicazione
                  AND    (not exists(select 1
                                   from siac_r_movgest_aggiudicazione riagg
                                   where riagg.movgest_id_da=mov_ts.movgest_ts_id
                                    and riagg.ente_proprietario_id=p_ente_prop_id
                                    and riagg.data_cancellazione IS NULL)))
              group by class.classif_code,
              	t_bil_elem.elem_code, mov.movgest_anno,
              	mov.movgest_numero)   
            ) as x
        group by x.programma_code ,x.elem_code, x.movgest_anno,
            x.movgest_numero, numero_modifica,
            motivo_modif_code, motivo_modif_desc                                 
order by 1,2,3,4,5;          

raise notice 'fine OK';
    exception
    when no_data_found THEN
    raise notice 'nessun dato trovato ';
    return;
    when others  THEN
  	RTN_MESSAGGIO:='altro errore';
 	RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
    return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR259_Allegato_B_FPV_Rendiconto_dettaglio_BILR147" (p_ente_prop_id integer, p_anno varchar)
  OWNER TO siac;
  
  
CREATE OR REPLACE FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (
  p_ente_prop_id integer,
  p_anno varchar,
  p_anno_prospetto varchar
)
RETURNS TABLE (
  anno_prospetto varchar,
  missione_code varchar,
  missione_desc varchar,
  programma_code varchar,
  programma_desc varchar,
  elem_id integer,
  numero_capitolo varchar,
  anno_impegno integer,
  numero_impegno numeric,
  spese_impegnate numeric,
  importo_avanzo numeric,
  importo_colonna_d_anno_prec numeric
) AS
$body$
DECLARE

RTN_MESSAGGIO text;
bilancio_id integer;
bilancio_id_prec integer;
cod_fase_operativa varchar;
anno_esercizio varchar;
anno_esercizio_prec varchar;
annoimpimpegni_int integer;
annoprospetto_int integer;
annoprospetto_prec_int varchar;

BEGIN

/*
	26/04/2022: SIAC-8634.
    	Funzione che estrae i dati di dettaglio relativi al report BILR011
        per la sola colonna B utilizzata dal report BILR260.
*/



bilancio_id := null;
bilancio_id_prec := null;

select bil.bil_id, fase_operativa.fase_operativa_code
into   bilancio_id, cod_fase_operativa
from  siac_d_fase_operativa fase_operativa, 
      siac_r_bil_fase_operativa bil_fase_operativa, 
      siac_t_bil bil, 
      siac_t_periodo periodo
where fase_operativa.fase_operativa_id = bil_fase_operativa.fase_operativa_id
and   bil_fase_operativa.bil_id = bil.bil_id
and   periodo.periodo_id = bil.periodo_id
and   fase_operativa.fase_operativa_code in ('P','E','G') -- SIAC-5778 Aggiunto G
and   bil.ente_proprietario_id = p_ente_prop_id
and   periodo.anno = p_anno
and   fase_operativa.data_cancellazione is null
and   bil_fase_operativa.data_cancellazione is null 
and   bil.data_cancellazione is null 
and   periodo.data_cancellazione is null;
 
 
anno_esercizio := ((p_anno::integer)-1)::varchar;   

select a.bil_id 
into bilancio_id 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio;
  
annoprospetto_int := p_anno_prospetto::integer;
  
annoprospetto_prec_int := ((p_anno_prospetto::integer)-1)::varchar;

-- anno_esercizio_prec := ((anno_esercizio::integer)-1)::varchar;
anno_esercizio_prec := ((p_anno::integer)-1)::varchar;

select a.bil_id
into bilancio_id_prec 
from siac_t_bil a,siac_t_periodo b
where a.ente_proprietario_id = p_ente_prop_id 
and b.periodo_id = a.periodo_id
and b.anno = anno_esercizio_prec;

raise notice 'bilancio_id = % - bilancio_id_prec = %',bilancio_id, bilancio_id_prec;
raise notice 'anno_esercizio_prec = % - annoprospetto_int = %- annoprospetto_prec_int = %', 
anno_esercizio_prec, annoprospetto_int, annoprospetto_prec_int;


return query
with tutto as (
with struttura as (
select *
from fnc_bilr_struttura_cap_bilancio_spese (p_ente_prop_id,anno_esercizio,null)
),
capitoli as (
select 	programma.classif_id programma_id,
		macroaggr.classif_id macroaggregato_id,
       	capitolo.elem_code, capitolo.elem_desc, capitolo.elem_code2,
        capitolo.elem_desc2, capitolo.elem_code3, capitolo.elem_id
from siac_t_bil_elem capitolo,
	 siac_d_bil_elem_tipo tipo_elemento,
     siac_r_bil_elem_stato r_capitolo_stato,
     siac_d_bil_elem_stato stato_capitolo,      
     siac_r_bil_elem_class r_capitolo_programma,
     siac_r_bil_elem_class r_capitolo_macroaggr, 	 
	 siac_d_bil_elem_categoria cat_del_capitolo,
     siac_r_bil_elem_categoria r_cat_capitolo,
     siac_d_class_tipo programma_tipo,
     siac_t_class programma,
     siac_d_class_tipo macroaggr_tipo,
     siac_t_class macroaggr
where capitolo.elem_tipo_id = tipo_elemento.elem_tipo_id 						
and capitolo.elem_id = r_capitolo_stato.elem_id							
and	r_capitolo_stato.elem_stato_id = stato_capitolo.elem_stato_id		
and	capitolo.elem_id = r_capitolo_programma.elem_id							
and capitolo.elem_id = r_capitolo_macroaggr.elem_id							
and programma.classif_tipo_id = programma_tipo.classif_tipo_id 				
and programma.classif_id = r_capitolo_programma.classif_id					
and macroaggr.classif_tipo_id = macroaggr_tipo.classif_tipo_id 				
and macroaggr.classif_id = r_capitolo_macroaggr.classif_id					
and	capitolo.elem_id = r_cat_capitolo.elem_id				
and r_cat_capitolo.elem_cat_id = cat_del_capitolo.elem_cat_id		
and capitolo.ente_proprietario_id = p_ente_prop_id							
and capitolo.bil_id = bilancio_id													
and programma_tipo.classif_tipo_code = 'PROGRAMMA'							
and	macroaggr_tipo.classif_tipo_code = 'MACROAGGREGATO'						
and	tipo_elemento.elem_tipo_code = 'CAP-UG'						     		
and stato_capitolo.elem_stato_code = 'VA' 
-- and cat_del_capitolo.elem_cat_code in ('FPV','FPVC')    
and	programma_tipo.data_cancellazione 			is null
and	programma.data_cancellazione 				is null
and	macroaggr_tipo.data_cancellazione 			is null
and	macroaggr.data_cancellazione 				is null
and	capitolo.data_cancellazione 				is null
and	tipo_elemento.data_cancellazione 			is null
and	r_capitolo_programma.data_cancellazione 	is null
and	r_capitolo_macroaggr.data_cancellazione 	is null 
and	stato_capitolo.data_cancellazione 			is null 
and	r_capitolo_stato.data_cancellazione 		is null
and	cat_del_capitolo.data_cancellazione 		is null
and	r_cat_capitolo.data_cancellazione           is null
),
dati_impegni as (
with importo_impegni as (
with   impegni as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_impegno
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.movgest_anno  >= annoprospetto_int
-- and    movimento.movgest_anno  >= annoImpImpegni_int
and    movimento.bil_id = bilancio_id
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno
),
imp_impegni_accertamenti as (
select ts_impegni_legati.movgest_ts_b_id,
       movimento.movgest_anno anno_accertamento,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo       
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_a_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    ts_impegni_legati.avav_id is null
and    movimento.bil_id = bilancio_id
and    movimento.movgest_anno <= annoprospetto_int+2
-- and    movimento.movgest_anno <= annoImpImpegni_int+2
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    ts_movimento.data_cancellazione is null
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
imp_impegni_avanzo as (
select ts_impegni_legati.movgest_ts_b_id,
       sum(ts_impegni_legati.movgest_ts_importo) movgest_ts_importo,
       movimento.movgest_anno        
from   siac_r_movgest_ts ts_impegni_legati
inner  join siac_t_avanzovincolo avanzovincolo on ts_impegni_legati.avav_id = avanzovincolo.avav_id
inner  join siac_d_avanzovincolo_tipo tipo_avanzovincolo on avanzovincolo.avav_tipo_id = tipo_avanzovincolo.avav_tipo_id
inner  join siac_t_movgest_ts ts_movimento on ts_impegni_legati.movgest_ts_b_id = ts_movimento.movgest_ts_id
inner  join siac_t_movgest movimento on ts_movimento.movgest_id = movimento.movgest_id
inner  join siac_r_movgest_ts_stato ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
inner  join siac_d_movgest_stato stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
where  ts_impegni_legati.ente_proprietario_id = p_ente_prop_id
and    movimento.bil_id = bilancio_id
and    ts_impegni_legati.movgest_ts_a_id is null
and    tipo_avanzovincolo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
and    movimento.movgest_anno >= annoprospetto_int
-- and    movimento.movgest_anno >= annoImpImpegni_int
and    stato.movgest_stato_code in ('D','N')-- SIAC-5778
and    ts_impegni_legati.data_cancellazione is null
and    avanzovincolo.data_cancellazione is null 
and    tipo_avanzovincolo.data_cancellazione is null
and    ts_movimento.data_cancellazione is null 
and    movimento.data_cancellazione is null
and    ts_impegni_legati.validita_fine is null
and    ts_stato.data_cancellazione is null-- SIAC-5778
and    stato.data_cancellazione is null-- SIAC-5778 
group by ts_impegni_legati.movgest_ts_b_id, movimento.movgest_anno 
),
dettaglio_impegni AS(
select impegno.movgest_anno anno_impegno,
	impegno.movgest_numero numero_impegno, impegno_ts.movgest_ts_id
from siac_t_movgest impegno,
	siac_t_movgest_ts impegno_ts,
    siac_d_movgest_tipo movgest_tipo
where impegno.movgest_id=impegno_ts.movgest_id
	and impegno.movgest_tipo_id=movgest_tipo.movgest_tipo_id
	and impegno.ente_proprietario_id= p_ente_prop_id
    and impegno.bil_id=bilancio_id
    and movgest_tipo.movgest_tipo_code='I'
    and impegno.data_cancellazione IS NULL
    and impegno_ts.data_cancellazione IS NULL)    
select impegni.movgest_ts_b_id,
	   dettaglio_impegni.anno_impegno,
       dettaglio_impegni.numero_impegno,
       case 
        when impegni.anno_impegno = annoprospetto_int and imp_impegni_accertamenti.anno_accertamento <= annoprospetto_int-1 then
             sum(imp_impegni_accertamenti.movgest_ts_importo)
       end spese_impegnate,         
       case 
        when impegni.anno_impegno = annoprospetto_int then
             sum(imp_impegni_avanzo.movgest_ts_importo)
       end importo_avanzo                           
from   impegni
left   join imp_impegni_accertamenti on impegni.movgest_ts_b_id = imp_impegni_accertamenti.movgest_ts_b_id
left   join imp_impegni_avanzo on impegni.movgest_ts_b_id = imp_impegni_avanzo.movgest_ts_b_id
left   join dettaglio_impegni on dettaglio_impegni.movgest_ts_id = impegni.movgest_ts_b_id
group by impegni.movgest_ts_b_id, impegni.anno_impegno, imp_impegni_accertamenti.anno_accertamento,
	dettaglio_impegni.anno_impegno, dettaglio_impegni.numero_impegno
), --importo_impegni
    capitoli_impegni as (
    select capitolo.elem_id, ts_movimento.movgest_ts_id,
    	capitolo.elem_code numero_capitolo
    from  siac_t_bil_elem                 capitolo
    inner join siac_r_movgest_bil_elem    r_mov_capitolo on r_mov_capitolo.elem_id = capitolo.elem_id
    inner join siac_d_bil_elem_tipo       t_capitolo on capitolo.elem_tipo_id = t_capitolo.elem_tipo_id
    inner join siac_t_movgest             movimento on r_mov_capitolo.movgest_id = movimento.movgest_id
    inner join siac_t_movgest_ts          ts_movimento on movimento.movgest_id = ts_movimento.movgest_id
    inner join siac_r_movgest_ts_stato    ts_stato on ts_stato.movgest_ts_id = ts_movimento.movgest_ts_id-- SIAC-5778
    inner join siac_d_movgest_stato       stato on stato.movgest_stato_id = ts_stato.movgest_stato_id-- SIAC-5778
    where capitolo.ente_proprietario_id = p_ente_prop_id
    and   capitolo.bil_id =	bilancio_id
    and   movimento.bil_id = bilancio_id
    and   t_capitolo.elem_tipo_code = 'CAP-UG'
    and   movimento.movgest_anno >= annoprospetto_int
    -- and   movimento.movgest_anno >= annoImpImpegni_int
    and   stato.movgest_stato_code in ('D','N')-- SIAC-5778
    and   capitolo.data_cancellazione is null 
    and   r_mov_capitolo.data_cancellazione is null 
    and   t_capitolo.data_cancellazione is null
    and   movimento.data_cancellazione is null 
    and   ts_movimento.data_cancellazione is null
    and   ts_stato.data_cancellazione is null-- SIAC-5778
    and   stato.data_cancellazione is null-- SIAC-5778 
    )
select 
capitoli_impegni.elem_id,
capitoli_impegni.numero_capitolo,
importo_impegni.anno_impegno, 
importo_impegni.numero_impegno,
sum(importo_impegni.spese_impegnate) spese_impegnate,
sum(importo_impegni.importo_avanzo) importo_avanzo
from capitoli_impegni
left join importo_impegni on capitoli_impegni.movgest_ts_id = importo_impegni.movgest_ts_b_id
group by capitoli_impegni.elem_id,capitoli_impegni.numero_capitolo,
importo_impegni.anno_impegno, importo_impegni.numero_impegno
) --dati_impegni
select 
p_anno_prospetto::varchar anno_prosp,
struttura.missione_code::varchar,
struttura.missione_desc::varchar,
struttura.programma_code::varchar,
struttura.programma_desc::varchar,
dati_impegni.elem_id::integer,
dati_impegni.numero_capitolo,
dati_impegni.anno_impegno, 
dati_impegni.numero_impegno,
COALESCE(dati_impegni.spese_impegnate,0)::numeric spese_impegnate,
COALESCE(dati_impegni.importo_avanzo,0)::numeric importo_avanzo,
0::numeric importo_colonna_d_Anno_prec
from struttura
	left join capitoli on  struttura.programma_id = capitoli.programma_id
                   and struttura.macroag_id = capitoli.macroaggregato_id
	left join dati_impegni on  capitoli.elem_id = dati_impegni.elem_id
where dati_impegni.elem_id is not null
--estraggo i dati della colonna D dello stesso anno bilancio ma con
--anno prospetto precedente.
--Vale solo quando il prospetto e' > dell'anno bilancio.
union 
select p_anno_prospetto::varchar anno_prosp,
''::varchar missione_code,
''::varchar missione_desc, 
cl2.classif_code programma_code,
''::varchar programma_desc, 
0::integer elem_id,
crono_elem.cronop_elem_code numero_capitolo,
0::integer anno_impegno,
0::integer numero_impegno,
0::numeric spese_impegnate,
0::numeric importo_avanzo,
COALESCE(sum(crono_elem_det.cronop_elem_det_importo),0) importo_colonna_d_Anno_prec
from siac_t_programma pr, siac_t_cronop crono, 
     siac_t_bil bil, siac_t_periodo anno_bil,
     siac_t_cronop_elem crono_elem, siac_d_bil_elem_tipo crono_elem_tipo,
     siac_t_cronop_elem_det crono_elem_det, siac_t_periodo anno_crono_elem_det,
     siac_r_cronop_elem_class rcl2, siac_d_class_tipo clt2, siac_t_class cl2,
     siac_r_cronop_stato stc , siac_d_cronop_stato stct,
     siac_r_programma_stato stpr, siac_d_programma_stato stprt
where pr.programma_id=crono.programma_id
      and crono.bil_id = bil.bil_id
      and bil.periodo_id=anno_bil.periodo_id
      and crono_elem.cronop_id=crono.cronop_id
      and crono_elem.cronop_elem_id=crono_elem_det.cronop_elem_id
      and crono_elem_tipo.elem_tipo_id=crono_elem.elem_tipo_id
      and rcl2.cronop_elem_id = crono_elem.cronop_elem_id
      and rcl2.classif_id=cl2.classif_id
      and cl2.classif_tipo_id=clt2.classif_tipo_id
      and crono_elem_det.periodo_id = anno_crono_elem_det.periodo_id
      and stc.cronop_id=crono.cronop_id
      and stc.cronop_stato_id=stct.cronop_stato_id
      and stpr.programma_id=pr.programma_id
      and stpr.programma_stato_id=stprt.programma_stato_id                          
      and pr.ente_proprietario_id= p_ente_prop_id
      and anno_bil.anno=p_anno -- anno bilancio
      and crono.usato_per_fpv::boolean = true
      and crono_elem_det.anno_entrata = (p_anno_prospetto::integer -1)::varchar -- anno prospetto           
      and anno_crono_elem_det.anno::integer=p_anno_prospetto::integer  -- anno prospetto
      and clt2.classif_tipo_code='PROGRAMMA'
      and stct.cronop_stato_code='VA'
      and stprt.programma_stato_code='VA'
      and stpr.data_cancellazione is null
      and stc.data_cancellazione is null
      and crono.data_cancellazione is null
      and pr.data_cancellazione is null
      and bil.data_cancellazione is null
      and anno_bil.data_cancellazione is null
      and crono_elem.data_cancellazione is null
      and crono_elem_det.data_cancellazione is null
      and rcl2.data_cancellazione is null
group by cl2.classif_code ,crono_elem.cronop_elem_code  ) 
select * from tutto 
union 
--aggiungo la riga dei totali
select tutto.anno_prosp anno_prospetto,
 '' missione_code,
 '' missione_desc,
 'Totale' programma_code ,
 '' programma_desc,  
 0 elem_id,
 '' numero_capitolo,
 0 anno_impegno,
 0 numero_impegno,
 sum(tutto.spese_impegnate) spese_impegnate,
 sum(tutto.importo_avanzo) importo_avanzo,
 sum(tutto.importo_colonna_d_Anno_prec) importo_colonna_d_Anno_prec
from tutto
group by anno_prospetto;

exception
when no_data_found THEN
raise notice 'Nessun dato trovato';
return;
when others  THEN
RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
PARALLEL UNSAFE
COST 100 ROWS 1000;

ALTER FUNCTION siac."BILR260_Allegato_B_FPV_Previsione_dettaglio_BILR011" (p_ente_prop_id integer, p_anno varchar, p_anno_prospetto varchar)
  OWNER TO siac;

--SIAC-8634 - Maurizio - FINE

-- SIAC-8489 - Sofia  - inizio 
drop FUNCTION if exists siac.fnc_fasi_bil_gest_reimputa_popola 
(
  p_fasebilelabid integer,
  p_enteproprietarioid integer,
  p_annobilancio integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  componentefittiziaid integer,
  componentefrescoid integer,
  componentefpvid integer,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

drop FUNCTION if exists siac.fnc_fasi_bil_gest_reimputa_vincoli 
(
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
);

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_popola (
  p_fasebilelabid integer,
  p_enteproprietarioid integer,
  p_annobilancio integer,
  p_loginoperazione varchar,
  p_dataelaborazione timestamp,
  p_movgest_tipo_code varchar,
  motivo varchar,
  componentefittiziaid integer,
  componentefrescoid integer,
  componentefpvid integer,
  out outfasebilelabretid integer,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE

	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';
	codResult          integer;
    v_faseBilElabId    integer;
    v_bil_attr_id      integer;
    v_attr_code        varchar;
-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio     integer;
-- SIAC-6997 ---------------- FINE --------------------
    MOVGEST_TS_T_TIPO  CONSTANT varchar:='T';
    MOVGEST_TS_S_TIPO  CONSTANT varchar:='S';
    CAP_UG_TIPO        CONSTANT varchar:='CAP-UG';
    CAP_EG_TIPO        CONSTANT varchar:='CAP-EG';
    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';

    MOVGEST_IMP_TIPO    CONSTANT  varchar:='I';
    MACROAGGREGATO_TIPO CONSTANT varchar:='MACROAGGREGATO';
    TITOLO_SPESA_TIPO   CONSTANT varchar:='TITOLO_SPESA';

    faseRec record;
    faseElabRec record;
    recmovgest  record;

    attoAmmId integer:=null;

    -- 05.06.2020 Sofia Jira SIAC-7593
    totModCollegAcc numeric:=null;
    codEsito       varchar(10):=null;
    mod_rec        record;
    faseReimpFrescoId integer:=null;
    faseReimpFpvId integer:=null;


    motivoREIMP   CONSTANT varchar:='REIMP';
    motivoREANNO  CONSTANT varchar:='REANNO';
BEGIN

    codiceRisultato:=null;
    messaggioRisultato:=null;
    strMessaggioFinale:='Inizio.';

    strMessaggio := 'prima del loop';

-- SIAC-6997 ---------------- INIZIO --------------------
    v_annobilancio := p_annoBilancio;
    if motivo = motivoREIMP then
       v_annobilancio := p_annoBilancio - 1;
    end if;
-- SIAC-6997 ----------------  FINE --------------------

    for recmovgest in (select
					   --siac_t_bil_elem
					   bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code tipo
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo impoInizImpegno
					  ,detts.movgest_ts_det_importo     impoAttImpegno
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
					  ,sum(dettsmod.movgest_ts_det_importo)  importoModifica
				from siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato -- 07.02.2018 Sofia siac-5368
				where bil.ente_proprietario_id=p_enteProprietarioId
				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--				and   per.anno::integer=p_annoBilancio-1
                and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id = modificaTipo.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
                and   modifica.elab_ror_reanno = FALSE
                and   modificaTipo.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code=p_movgest_tipo_code--'I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code=p_movgest_tipo_code--'I' -- 'A'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
               	group by

				       bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo
					  ,detts.movgest_ts_det_importo
					  --,dettsmod.movgest_ts_det_importo  importoModifica
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
				order by
				 		 dettsmod.mtdm_reimputazione_anno::integer
				 		,modificaTipo.mod_tipo_code
				 		--,tsmov.movgest_ts_code::integer    ?? serve????
						,movgest.movgest_anno::integer
                        ,movgest.movgest_numero::integer
                        ,tipo desc --tipots.movgest_ts_tipo_code desc,



    --Raggruppate per anno reimputazione, motivo anno/numero impegno/sub,


    ) loop

		-- 07.02.2018 Sofia siac-5368
       	strMessaggio := 'Lettura attoamm_id prima di inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
        		raise notice 'strMessaggio=%',strMessaggio;

        attoAmmId:=null;
        select r.attoamm_id into attoAmmId
        from siac_r_movgest_ts_atto_amm r
        where r.movgest_ts_id=recmovgest.movgest_ts_id
        and   r.data_cancellazione is null
        and   r.validita_fine is null;

        -- 05.06.2020 Sofia SIAC-7593
		-- calcolo della quota di reimp che deve rimanere su componente Fresco
        -- modifica di impegno collegata a modifiche di accertamento con Vincolo verso acc.
        -- se esiste collegamento ma non il vincolo verso accertamento deve andare su
        -- componente FPV
        -- 23.07.2020 Sofia vedi commento successivo su componente Fresco anche in assenza di vincolo
        -- basta la presenza di colleg. spesa-entrata
        if p_movgest_tipo_code=MOVGEST_IMP_TIPO then
          strMessaggio := 'Calcolo totale entrate collegate a impegno per calcolo Fresco '
                        ||' prima di inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='
                        ||recmovgest.movgest_ts_id::varchar
                        ||' Componente '
                        ||(case when componenteFittiziaId is not null then 'Fittizia' else 'Fresca'  end )
                        ||' ID= '
                        ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFrescoId::varchar  end )
                        ||'.';
          raise notice 'strMessaggio=%',strMessaggio;
          totModCollegAcc:=0;
          -- SIAC-8489 15.04.2022
          faseReimpFrescoId:=null;
          faseReimpFpvId :=null;
         
          /*select coalesce(sum(rmod.movgest_ts_det_mod_importo),0) into totModCollegAcc
          from siac_t_bil bil ,
               siac_t_periodo per,
               siac_t_movgest mov,siac_d_movgest_tipo tipo,
               siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
               siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
               siac_t_movgest_ts_det_mod  dettsmod,
               siac_t_modifica mod,siac_d_modifica_tipo tipomod,
               siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
               siac_r_movgest_ts_det_mod rmod,
               siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
               siac_t_modifica modAcc,
               siac_r_movgest_Ts rvincAcc
          where bil.ente_proprietario_id=p_enteProprietarioId  -- ente_proprietario
          and   per.periodo_id=bil.periodo_id
          and   per.anno::integer=v_annoBilancio              -- anno_bilancio
          and   tipo.ente_proprietario_id=bil.ente_proprietario_id
          and   tipo.movgest_tipo_code=p_movgest_tipo_code     -- tipo_impegno
          and   mov.movgest_tipo_id=tipo.movgest_tipo_id
          and   mov.bil_id=bil.bil_id
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- impegno
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   detts.movgest_ts_id=ts.movgest_ts_id
          and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
          and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
          and   dettsmod.movgest_ts_det_importo<0
          and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
          and   modstato.mod_stato_id=rmodstato.mod_stato_id
          and   modstato.mod_stato_code='V'
          and   mod.mod_id=rmodstato.mod_id
          and   tipomod.mod_tipo_id =  mod.mod_tipo_id
          and   mod.elab_ror_reanno = FALSE
          and   tipomod.mod_tipo_code = motivo  -- motivo
          and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code -- mod_tipo_code
          and   dettsmod.mtdm_reimputazione_anno is not null
          and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   dettsmod.mtdm_reimputazione_flag is true -- ROR
          and   rmod.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id   -- spesa_id collegata a entrata_id
          and   detmodAcc.movgest_ts_det_mod_id=rmod.movgest_ts_det_mod_entrata_id
          and   rsModAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
          and   rsmodAcc.mod_stato_id=modstato.mod_stato_id -- V
          and   modAcc.mod_id=rsModAcc.mod_id
          and   modAcc.mod_tipo_id=tipomod.mod_tipo_id -- motivo entrata uguale spesa
          and   modAcc.elab_ror_reanno = FALSE
          and   detmodAcc.mtdm_reimputazione_anno is not null
          and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   detmodAcc.mtdm_reimputazione_flag is true -- ROR
          and   rvincAcc.movgest_Ts_b_Id=recmovgest.movgest_ts_id
          and   rvincacc.movgest_ts_a_id=detmodAcc.movgest_ts_id
          and   rmodstato.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   detts.data_cancellazione is null
          and   detts.validita_fine is null
          and   dettsmod.data_cancellazione is null
          and   dettsmod.validita_fine is null
          and   rmodstato.data_cancellazione is null
          and   rmodstato.validita_fine is null
          and   mod.data_cancellazione is null
          and   mod.validita_fine is null
          and   rmod.data_cancellazione is null
          and   rmod.validita_fine is null
          and   detmodAcc.data_cancellazione is null
          and   detmodAcc.validita_fine is null
          and   rsModAcc.data_cancellazione is null
          and   rsModAcc.validita_fine is null
          and   modacc.data_cancellazione is null
          and   modAcc.validita_fine is null
          and   rvincacc.data_cancellazione is null
          and   rvincacc.validita_fine is null;*/

          -- 23.07.2020 Sofia SIAC-7593 in seguito a scambio mail con Gambino e test in collaudo
          -- emerge che il fresco si calcola sul collegamento tra modifiche spesa-entrata
          -- anche in assenza di vincoli
          select coalesce(sum(rmod.movgest_ts_det_mod_importo),0) into totModCollegAcc
          from siac_t_bil bil ,
               siac_t_periodo per,
               siac_t_movgest mov,siac_d_movgest_tipo tipo,
               siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
               siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
               siac_t_movgest_ts_det_mod  dettsmod,
               siac_t_modifica mod,siac_d_modifica_tipo tipomod,
               siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
               siac_r_movgest_ts_det_mod rmod,
               siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
               siac_t_modifica modAcc--,
               --siac_r_movgest_Ts rvincAcc
          where bil.ente_proprietario_id=p_enteProprietarioId  -- ente_proprietario
          and   per.periodo_id=bil.periodo_id
          and   per.anno::integer=v_annoBilancio              -- anno_bilancio
          and   tipo.ente_proprietario_id=bil.ente_proprietario_id
          and   tipo.movgest_tipo_code=p_movgest_tipo_code     -- tipo_impegno
          and   mov.movgest_tipo_id=tipo.movgest_tipo_id
          and   mov.bil_id=bil.bil_id
          and   ts.movgest_id=mov.movgest_id
          and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- impegno
          and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
          and   detts.movgest_ts_id=ts.movgest_ts_id
          and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
          and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
          and   dettsmod.movgest_ts_det_importo<0
          and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
          and   modstato.mod_stato_id=rmodstato.mod_stato_id
          and   modstato.mod_stato_code='V'
          and   mod.mod_id=rmodstato.mod_id
          and   tipomod.mod_tipo_id =  mod.mod_tipo_id
          and   mod.elab_ror_reanno = FALSE
          and   tipomod.mod_tipo_code = motivo  -- motivo
          and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code -- mod_tipo_code
          and   dettsmod.mtdm_reimputazione_anno is not null
          and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   dettsmod.mtdm_reimputazione_flag is true -- ROR
          and   rmod.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id   -- spesa_id collegata a entrata_id
          and   detmodAcc.movgest_ts_det_mod_id=rmod.movgest_ts_det_mod_entrata_id
          and   rsModAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
          and   rsmodAcc.mod_stato_id=modstato.mod_stato_id -- V
          and   modAcc.mod_id=rsModAcc.mod_id
          and   modAcc.mod_tipo_id=tipomod.mod_tipo_id -- motivo entrata uguale spesa
          and   modAcc.elab_ror_reanno = FALSE
          and   detmodAcc.mtdm_reimputazione_anno is not null
          and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
          and   detmodAcc.mtdm_reimputazione_flag is true -- ROR
          --and   rvincAcc.movgest_Ts_b_Id=recmovgest.movgest_ts_id
          --and   rvincacc.movgest_ts_a_id=detmodAcc.movgest_ts_id
          and   rmodstato.validita_fine is null
          and   mov.data_cancellazione is null
          and   mov.validita_fine is null
          and   ts.data_cancellazione is null
          and   ts.validita_fine is null
          and   detts.data_cancellazione is null
          and   detts.validita_fine is null
          and   dettsmod.data_cancellazione is null
          and   dettsmod.validita_fine is null
          and   rmodstato.data_cancellazione is null
          and   rmodstato.validita_fine is null
          and   mod.data_cancellazione is null
          and   mod.validita_fine is null
          and   rmod.data_cancellazione is null
          and   rmod.validita_fine is null
          and   detmodAcc.data_cancellazione is null
          and   detmodAcc.validita_fine is null
          and   rsModAcc.data_cancellazione is null
          and   rsModAcc.validita_fine is null
          and   modacc.data_cancellazione is null
          and   modAcc.validita_fine is null;
          --and   rvincacc.data_cancellazione is null
          --and   rvincacc.validita_fine is null;

        end if;

        raise notice 'totModCollegAcc per componente fresc=%',totModCollegAcc;
		-- COMPONENTE FRESCA
        -- se il totale collegato a modifiche accertamenti !=0
        -- si passa come importo reimputazione totModCollegAcc
        -- se passata la componente Fittizia si passa Fittizia
        -- diversamente si passa Fresco
        if totModCollegAcc is not null and totModCollegAcc!=0 then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='
                        ||recmovgest.movgest_ts_id::varchar
                        ||' Componente '
                        ||(case when componenteFittiziaId is not null then 'Fittizia' else 'Fresca'  end )
                        ||' ID= '
                        ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFrescoId::varchar  end )
                        ||'.';
          raise notice 'strMessaggio=%',strMessaggio;
          --codResult:=null;
          faseReimpFrescoId:=null;
          insert into  fase_bil_t_reimputazione (
           --siac_t_bil_elem
           faseBilElabId
          ,bil_id
          ,elemId_old
          ,elem_code
          ,elem_code2
          ,elem_code3
          ,elem_tipo_code
          -- siac_t_movgest
          ,movgest_id
          ,movgest_anno
          ,movgest_numero
          ,movgest_desc
          ,movgest_tipo_id
          ,parere_finanziario
          ,parere_finanziario_data_modifica
          ,parere_finanziario_login_operazione
          -- siac_t_movgest_ts
          ,movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,movgest_ts_desc
          ,movgest_ts_tipo_id
          ,movgest_ts_id_padre
          ,ordine
          ,livello
          ,movgest_ts_scadenza_data
          ,siope_tipo_debito_id
          ,siope_assenza_motivazione_id
          --siac_t_movgest_ts_dett
          ,tipo
          ,movgest_ts_det_tipo_code
          ,mod_tipo_code
          ,movgest_ts_det_tipo_id
          ,impoInizImpegno
          ,impoAttImpegno
          ,importoModifica
          ,mtdm_reimputazione_anno
          ,mtdm_reimputazione_flag
          , attoamm_id        -- 07.02.2018 Sofia siac-5368
          , movgest_stato_id  -- 07.02.2018 Sofia siac-5368
          , importo_reimputato -- 05.06.2020 Sofia siac-7593
          , importo_modifica_entrata -- 05.06.2020 Sofia siac-7593
          , coll_mod_entrata      -- 05.06.2020 Sofia siac-7593
          , coll_det_mod_entrata    -- 08.06.2020 Sofia siac-7593
          ,elem_det_comp_tipo_id    -- 05.06.2020 Sofia siac-7593
          ,login_operazione
          ,ente_proprietario_id
          ,data_creazione
          ,fl_elab
          ,scarto_code
          ,scarto_desc
          ) values (
          --siac_t_bil_elem
          --siac_t_bil_elem
           p_faseBilElabId
          ,recmovgest.bil_id
          ,recmovgest.elem_id
          ,recmovgest.elem_code
          ,recmovgest.elem_code2
          ,recmovgest.elem_code3
          ,recmovgest.elem_tipo_code
          -- siac_t_movgest
          ,recmovgest.movgest_id
          ,recmovgest.movgest_anno
          ,recmovgest.movgest_numero
          ,recmovgest.movgest_desc
          ,recmovgest.movgest_tipo_id
          ,recmovgest.parere_finanziario
          ,recmovgest.parere_finanziario_data_modifica
          ,recmovgest.parere_finanziario_login_operazione
          -- siac_t_movgest_ts
          ,recmovgest.movgest_ts_id
          ,recmovgest.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
          ,recmovgest.movgest_ts_desc
          ,recmovgest.movgest_ts_tipo_id
          ,recmovgest.movgest_ts_id_padre
          ,recmovgest.ordine
          ,recmovgest.livello
          ,recmovgest.movgest_ts_scadenza_data
          ,recmovgest.siope_tipo_debito_id
          ,recmovgest.siope_assenza_motivazione_id
          --siac_t_movgest_ts_dett
          ,recmovgest.tipo
          ,recmovgest.movgest_ts_det_tipo_code
          ,recmovgest.mod_tipo_code
          ,recmovgest.movgest_ts_det_tipo_id
          ,recmovgest.impoInizImpegno
          ,recmovgest.impoAttImpegno
          ,recmovgest.importoModifica
          ,recmovgest.mtdm_reimputazione_anno
          ,recmovgest.mtdm_reimputazione_flag
          , attoAmmId                    -- 07.02.2018 Sofia siac-5368
          , recmovgest.movgest_stato_id  -- 07.02.2018 Sofia siac-5368
          , totModCollegAcc -- 05.06.2020 Sofia siac-7593 importo_reimputato
          , totModCollegAcc -- 05.06.2020 Sofia siac-7593 importo_modifica_entrata
          , true            -- 05.06.2020 Sofia siac-7593 colleg_mod_entrata
          , true            -- 05.06.2020 Sofia siac-7593 colleg_det_mod_entrata
          , (case when componenteFittiziaId is not null then componenteFittiziaId else componenteFrescoId  end ) -- 05.06.2020 Sofia siac-7593
          ,p_loginoperazione
          ,p_enteProprietarioId
          ,p_dataElaborazione
          ,'N'
          ,null
          ,null
          )
          -- 09.06.2020 Sofia Jira SIAC-7593
          --returning reimputazione_id into codResult;
          --raise notice 'dopo inserimento codResult=%',codResult;
		  returning reimputazione_id into faseReimpFrescoId;
          raise notice 'dopo inserimento faseReimpFrescoId=%',faseReimpFrescoId;
        end if;

		-- 05.06.2020 Sofia SIAC-7593
        -- COMPONENTE FPV
        -- si passa come importo di reimputazione
        -- l'importo di modifica - il totale collegato a modifiche accertamenti
        -- se totModCollegAcc=0 o nullo e non ci sono collegamenti
        -- l' importo di reimputazione resta importo di modifica
        -- se passata la componente Fittizia si passa Fittizia
        -- diversamente si passa FPV
        -- 08.06.2020 Sofia siac-7593
        -- se (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))!=0 si procede con inserimento

        if (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))!=0 then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFPVId::varchar  end )
                          ||'.';
          raise notice 'strMessaggio=%',strMessaggio;
          --codResult:=null; -- 31.01.2018 Sofia siac-5368
          faseReimpFpvId:=null; -- 09.06.2020 Sofia SIAC-7593
          insert into  fase_bil_t_reimputazione
          (
             --siac_t_bil_elem
             faseBilElabId
            ,bil_id
            ,elemId_old
            ,elem_code
            ,elem_code2
            ,elem_code3
            ,elem_tipo_code
            -- siac_t_movgest
            ,movgest_id
            ,movgest_anno
            ,movgest_numero
            ,movgest_desc
            ,movgest_tipo_id
            ,parere_finanziario
            ,parere_finanziario_data_modifica
            ,parere_finanziario_login_operazione
            -- siac_t_movgest_ts
            ,movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
            ,movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
            ,movgest_ts_desc
            ,movgest_ts_tipo_id
            ,movgest_ts_id_padre
            ,ordine
            ,livello
            ,movgest_ts_scadenza_data
            ,siope_tipo_debito_id
            ,siope_assenza_motivazione_id
            --siac_t_movgest_ts_dett
            ,tipo
            ,movgest_ts_det_tipo_code
            ,mod_tipo_code
            ,movgest_ts_det_tipo_id
            ,impoInizImpegno
            ,impoAttImpegno
            ,importoModifica
            ,mtdm_reimputazione_anno
            ,mtdm_reimputazione_flag
            , attoamm_id        -- 07.02.2018 Sofia siac-5368
            , movgest_stato_id  -- 07.02.2018 Sofia siac-5368
            , importo_reimputato -- 05.06.2020 Sofia siac-7593
            , importo_modifica_entrata -- 05.06.2020 Sofia siac-7593
            , coll_mod_entrata      -- 05.06.2020 Sofia siac-7593
            , coll_det_mod_entrata    -- 08.06.2020 Sofia siac-7593
            , elem_det_comp_tipo_id    -- 05.06.2020 Sofia siac-7593
            ,login_operazione
            ,ente_proprietario_id
            ,data_creazione
            ,fl_elab
            ,scarto_code
            ,scarto_desc
        ) values (
        --siac_t_bil_elem
            --siac_t_bil_elem
             p_faseBilElabId
            ,recmovgest.bil_id
            ,recmovgest.elem_id
            ,recmovgest.elem_code
            ,recmovgest.elem_code2
            ,recmovgest.elem_code3
            ,recmovgest.elem_tipo_code
            -- siac_t_movgest
            ,recmovgest.movgest_id
            ,recmovgest.movgest_anno
            ,recmovgest.movgest_numero
            ,recmovgest.movgest_desc
            ,recmovgest.movgest_tipo_id
            ,recmovgest.parere_finanziario
            ,recmovgest.parere_finanziario_data_modifica
            ,recmovgest.parere_finanziario_login_operazione
            -- siac_t_movgest_ts
            ,recmovgest.movgest_ts_id
            ,recmovgest.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
            ,recmovgest.movgest_ts_desc
            ,recmovgest.movgest_ts_tipo_id
            ,recmovgest.movgest_ts_id_padre
            ,recmovgest.ordine
            ,recmovgest.livello
            ,recmovgest.movgest_ts_scadenza_data
            ,recmovgest.siope_tipo_debito_id
            ,recmovgest.siope_assenza_motivazione_id
            --siac_t_movgest_ts_dett
            ,recmovgest.tipo
            ,recmovgest.movgest_ts_det_tipo_code
            ,recmovgest.mod_tipo_code
            ,recmovgest.movgest_ts_det_tipo_id
            ,recmovgest.impoInizImpegno
            ,recmovgest.impoAttImpegno
            ,recmovgest.importoModifica
            ,recmovgest.mtdm_reimputazione_anno
            ,recmovgest.mtdm_reimputazione_flag
            , attoAmmId                    -- 07.02.2018 Sofia siac-5368
            , recmovgest.movgest_stato_id  -- 07.02.2018 Sofia siac-5368
            , (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))     -- 05.06.2020 Sofia siac-7593 importo_reimputato
            , totModCollegAcc     -- 05.06.2020 Sofia siac-7593 importo_modifica_entrata
            , (case when coalesce(totModCollegAcc,0)!=0 then true else false  end) -- 05.06.2020 Sofia siac-7593 colleg_mod_entrata
            , false               -- 08.06.2020 Sofia siac-7593 colleg_det_mod_entrata
            , (case when componenteFittiziaId is not null then componenteFittiziaId else componenteFPVId  end ) -- 05.06.2020 Sofia siac-7593
            ,p_loginoperazione
            ,p_enteProprietarioId
            ,p_dataElaborazione
            ,'N'
            ,null
            ,null
      )
      -- 09.06.2020 Sofia SIAC-7593
      --returning reimputazione_id into codResult; -- 31.01.2018 Sofia siac-5788
      --raise notice 'dopo inserimento codResult=%',codResult;
      returning reimputazione_id into faseReimpFpvId;
      raise notice 'dopo inserimento faseReimpFpvId=%',faseReimpFpvId;
    end if;


    -- 08.06.2020 Sofia Jira siac-7593 - inizio - aggiornamento vincoli non aggiornati da Contabilia
    if p_movgest_tipo_code=MOVGEST_IMP_TIPO then
      strMessaggio := 'Aggiornamento vincoli non aggiornati da contabilia - esec fnc_siac_riaccertamento_reimp - inizio.';
      raise notice 'strMessaggio=%',strMessaggio;
      for mod_rec in
      (
       select mod.mod_id
       from  siac_t_bil bil ,
             siac_t_periodo per,
             siac_t_movgest mov,siac_d_movgest_tipo tipo,
             siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
             siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
             siac_t_movgest_ts_det_mod  dettsmod,
             siac_t_modifica mod,siac_d_modifica_tipo tipomod,
             siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato
        where bil.ente_proprietario_id=p_enteProprietarioId  -- ente_proprietario
        and   per.periodo_id=bil.periodo_id
        and   per.anno::integer=v_annoBilancio              -- anno_bilancio
        and   tipo.ente_proprietario_id=bil.ente_proprietario_id
        and   tipo.movgest_tipo_code=p_movgest_tipo_code     -- tipo_impegno
        and   mov.movgest_tipo_id=tipo.movgest_tipo_id
        and   mov.bil_id=bil.bil_id
        and   ts.movgest_id=mov.movgest_id
        and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- impegno
        and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
        and   detts.movgest_ts_id=ts.movgest_ts_id
        and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
        and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
        and   dettsmod.movgest_ts_det_importo<0
        and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
        and   modstato.mod_stato_id=rmodstato.mod_stato_id
        and   modstato.mod_stato_code='V'
        and   mod.mod_id=rmodstato.mod_id
        and   tipomod.mod_tipo_id =  mod.mod_tipo_id
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo  -- motivo
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code -- mod_tipo_code
        and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- anno_reimputazione
        and   dettsmod.mtdm_reimputazione_flag is true -- ROR
        and   rmodstato.validita_fine is null
        and   mov.data_cancellazione is null
        and   mov.validita_fine is null
        and   ts.data_cancellazione is null
        and   ts.validita_fine is null
        and   detts.data_cancellazione is null
        and   detts.validita_fine is null
        and   dettsmod.data_cancellazione is null
        and   dettsmod.validita_fine is null
        and   rmodstato.data_cancellazione is null
        and   rmodstato.validita_fine is null
        and   mod.data_cancellazione is null
        and   mod.validita_fine is null
        order by 1
      )
      loop
         codEsito:=null;
         strMessaggio := 'Aggiornamento vincoli non aggiornati da contabilia - esec fnc_siac_riaccertamento_reimp mod_id='
         ||mod_rec.mod_id::varchar||'.';
         raise notice 'strMessaggio=%',strMessaggio;
         select
         fnc_siac_riaccertamento_reimp -- da implementare
         (
          mod_rec.mod_id,
          p_loginoperazione||'-'||motivo,
          'INSERIMENTO'
         ) into codEsito;
         strMessaggio:=strMessaggio||'Esito='||codEsito||'.';
         raise notice 'strMessaggio=%',strMessaggio;
         --codEsito:='ko';
         if codEsito='ko' then
         	raise exception '%',strMessaggio;
         end if;
     end loop;
     strMessaggio := 'Aggiornamento vincoli non aggiornati da contabilia - esec fnc_siac_riaccertamento_reimp - fine.';
     raise notice 'strMessaggio=%',strMessaggio;
     end if;
    -- 08.06.2020 Sofia Jira siac-7593 - fine


    -- 08.06.2020 Sofia Jira siac-7593 - inizio
    -- mod spesa collegata a mod entrata con quadratura ( importo_mod_spesa=tot.coll. importo_mod_entrata)
    --- A
    if ( faseReimpFrescoId is not null or faseReimpFpvId is not null ) and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then
        -- A.1
        -- con o senza vincolo verso accertamento : si creano impegni reimputati su componente fresco,
        -- con vincolo verso l'accertamento collegato tramite modifica
        -- dall'acc collegato in partenza
        -- impostare il caso di accertamento (come adesso ) per farlo andare al nuovo accertamento o FPV come adesso
        -- caso A.2 non esiste 23.07.2020 Sofia
        -- A.2
        -- senza vincolo verso accertamento : si creano impegni reimputati su componente FPV
        -- A.2.1 se ROR vincolo verso FPV ( anche se in partenza non esiste )
        -- A.2.2 se REANNO vincolo verso accertamento reimputato da accertamento collegato
        -- tramite modifica di importo
        -- se AAM potrebbe andare a FPV ma al momento non gestire in quanto potrebbe non verificarsi mai
        -- A.3 - annegato negli altri
        -- senza vincolo si crea nuovo vincolo a FPV
        -- gestito con A.2

        if faseReimpFrescoId is not null then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'Fresca'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFrescoId::varchar  end )
                          ||'. Caso A.1 modfica spesa-modifica entra e vincolo entrata.';
          raise notice 'A.1 strMessaggio=%',strMessaggio;
          codResult:=null;
          -- A.1 faseReimpFrescoId
          insert into   fase_bil_t_reimputazione_vincoli
          (
            reimputazione_id,
            fasebilelabid,
            bil_id,
            mod_id,
            mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
            reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
            movgest_ts_r_id,
            movgest_ts_b_id,
            movgest_ts_a_id,
            importo_vincolo,
            avav_new_id,
            importo_vincolo_new,
            data_creazione,
            login_operazione,
            ente_proprietario_id
          )
          (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 --rts.movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
                 detmodAcc.movgest_ts_id movgest_ts_a_id,    -- movgest_ts_a_id
                 --rts.movgest_ts_a_id,            -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 --coalesce(rts.movgest_ts_importo,0) importo_vincolo,
                 -- abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
                 rmodAcc.movgest_ts_det_mod_importo  importo_vincolo_new -- 23.07.2020 Sofia
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                    -- siac_r_movgest_ts rts,
                     siac_r_movgest_ts_det_mod rmodAcc,
                     siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                     siac_t_modifica modAcc--,
                     --siac_r_modifica_vincolo rvinc -- inserito da mod.entrata
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
  			    and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   detmodAcc.movgest_ts_det_mod_id=rmodAcc.movgest_ts_det_mod_entrata_id
                and   detmodAcc.mtdm_reimputazione_anno is not null
                and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   detmodAcc.mtdm_reimputazione_flag is true
                and   rsmodAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
                and   rsmodAcc.mod_stato_id=modstato.mod_stato_id
                and   modAcc.mod_id=rsmodAcc.mod_id
                and   modAcc.mod_tipo_id=mod.mod_tipo_id
                and   modAcc.elab_ror_reanno = FALSE
               -- and   rts.movgest_ts_a_id=detmodAcc.movgest_ts_id
               -- and   rts.movgest_ts_b_id=ts.movgest_ts_id
               -- and   rvinc.movgest_ts_r_id=rts.movgest_ts_r_id
               -- and   rvinc.mod_Id=modAcc.mod_id
               -- and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                --and   rvinc.data_cancellazione is null
                --and   rvinc.validita_fine is null
               -- and   rts.data_cancellazione is null
               -- and   rts.validita_fine is null
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                and   rsmodAcc.data_cancellazione is null
                and   rsmodAcc.validita_fine is null
                and   detmodAcc.data_cancellazione is null
                and   detmodAcc.validita_fine is null
                and   modAcc.data_cancellazione is null
                and   modAcc.validita_fine is null
            )
            select faseReimpFrescoId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo A.1=%',codResult;
       end if;

       /* 23.07.2020 Sofia vedasi confronto con Gambino per cui
          se esiste collegamento tra modifica di spesa-entrata
          sempre Fresco e vincolo verso accertamento
          anche se non esiste vincolo in partenza
       if faseReimpFpvId is not null then
         -- A.2 faseReimpFpvId
         -- senza vincolo verso accertamento : si creano impegni reimputati su componente FPV
         -- A.2.1 se ROR vincolo verso FPV ( anche se in partenza non esiste )
         if motivo=motivoREIMP then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso A.2.1 modfica spesa-modifica entra senza vincolo entrata '||motivoREIMP||'.';
          raise notice 'A.2.1 strMessaggio=%',strMessaggio;
          codResult:=null;
          insert into   fase_bil_t_reimputazione_vincoli
          (
            reimputazione_id,
            fasebilelabid,
            bil_id,
            mod_id,
            mod_tipo_code,
            reimputazione_anno,
            movgest_ts_r_id,
            movgest_ts_b_id,
            movgest_ts_a_id,
            importo_vincolo,
            avav_new_id,
            importo_vincolo_new,
            data_creazione,
            login_operazione,
            ente_proprietario_id
          )
          (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 NULL::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,  -- movgest_ts_b_id
                 NULL::integer movgest_ts_a_id,              -- movgest_ts_a_id
                 NULL::numeric importo_vincolo,
                 sum(rmodAcc.movgest_ts_det_mod_importo)  importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_r_movgest_ts_det_mod rmodAcc,
                     siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                     siac_t_modifica modAcc
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   detmodAcc.movgest_ts_det_mod_id=rmodAcc.movgest_ts_det_mod_entrata_id
                and   rsmodAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
                and   rsmodAcc.mod_stato_id=modstato.mod_stato_id
                and   modAcc.mod_id=rsmodAcc.mod_id
                and   modAcc.mod_tipo_id=mod.mod_tipo_id
				and   modAcc.elab_ror_reanno = FALSE
                and   detmodAcc.mtdm_reimputazione_anno is not null
                and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   detmodAcc.mtdm_reimputazione_flag is true
                and   not exists
                (
                select 1
                from siac_r_movgest_ts rts
                where rts.movgest_ts_b_id=ts.movgest_ts_id
                and   rts.movgest_ts_a_id=detmodAcc.movgest_ts_id
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                and   rsmodAcc.data_cancellazione is null
                and   rsmodAcc.validita_fine is null
                and   detmodAcc.data_cancellazione is null
                and   detmodAcc.validita_fine is null
                and   modAcc.data_cancellazione is null
                and   modAcc.validita_fine is null
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new::numeric,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo A.2.1=%',codResult;
        end if; -- motivo=motivoREIMP


        -- A.2 faseReimpFpvId
        -- senza vincolo verso accertamento : si creano impegni reimputati su componente FPV
        -- A.2.2 se REANNO vincolo verso accertamento reimputato da accertamento collegato
        if motivo=motivoREANNO then
          strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso A.2.2 modfica spesa-modifica entra senza vincolo entrata '||motivoREANNO||'.';
          raise notice 'A.2.2 strMessaggio=%',strMessaggio;
		  codResult:=null;
          insert into   fase_bil_t_reimputazione_vincoli
          (
            reimputazione_id,
            fasebilelabid,
            bil_id,
            mod_id,
            mod_tipo_code,
            reimputazione_anno,
            movgest_ts_r_id,
            movgest_ts_b_id,
            movgest_ts_a_id,
            importo_vincolo,
            avav_new_id,
            importo_vincolo_new,
            data_creazione,
            login_operazione,
            ente_proprietario_id
          )
          (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,                     -- movgest_ts_b_id
                 detmodAcc.movgest_ts_id movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 sum(rmodAcc.movgest_ts_det_mod_importo)  importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_r_movgest_ts_det_mod rmodAcc,
                     siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                     siac_t_modifica modAcc
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   detmodAcc.movgest_ts_det_mod_id=rmodAcc.movgest_ts_det_mod_entrata_id
                and   rsmodAcc.mod_stato_r_id=detmodAcc.mod_stato_r_id
                and   rsmodAcc.mod_stato_id=modstato.mod_stato_id
                and   modAcc.mod_id=rsmodAcc.mod_id
                and   modAcc.mod_tipo_id=mod.mod_tipo_id
                and   modAcc.elab_ror_reanno = FALSE
                and   detmodAcc.mtdm_reimputazione_anno is not null
                and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   detmodAcc.mtdm_reimputazione_flag is true
                and   not exists
                (
                select 1
                from siac_r_movgest_ts rts
                where rts.movgest_ts_b_id=ts.movgest_ts_id
                and   rts.movgest_ts_a_id=detmodAcc.movgest_ts_id
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                and   rsmodAcc.data_cancellazione is null
                and   rsmodAcc.validita_fine is null
                and   detmodAcc.data_cancellazione is null
                and   detmodAcc.validita_fine is null
                and   modAcc.data_cancellazione is null
                and   modAcc.validita_fine is null
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         detmodAcc.movgest_ts_id
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo A.2.2=%',codResult;
        end if;
      end if; --  faseReimpFpvId is not null */

    end if; -- A fine


    -- 08.06.2020 Sofia Jira siac-7593
    -- mod spesa collegata a mod entrata con squadratura ( importo_mod_spesa!=tot.coll. importo_mod_entrata)
    -- B
    -- si creano impegni reimputati su componente FPV,  tutti i vincoli vengono reimputati a FPV
    -- anche se avevano AAM, accertamento e se non avevano vincolo
    -- quindi so ho creato sia fresco che FPV
    -- collegamento a mod. entrata parziale
    if faseReimpFrescoId is not null or faseReimpFpvId is not null  and
       coalesce(totModCollegAcc,0)!=0 and
       (-recmovgest.importoModifica-coalesce(totModCollegAcc,0))!=0 and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then
       -- 12.04.2022 Sofia Jira SIAC-8489 - inizio 
       if motivo=motivoREIMP then 
        strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                              ||recmovgest.movgest_ts_id::varchar
                              ||' Componente '
                              ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                              ||' ID= '
                              ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                              ||'. Caso B modifica spesa-modifica entrata parte residua non collegata.';

        raise notice 'B strMessaggio=%',strMessaggio;
		codResult:=null;
        insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,                     -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                -- -recmovgest.importoModifica - sum(rmodAcc.movgest_ts_det_mod_importo)  importo_vincolo_new
                 -dettsmod.movgest_Ts_det_importo - coalesce(sum(query_entrata.movgest_ts_det_mod_importo),0)  importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts_det_mod  dettsmod left join
                     (
                     select rmodAcc.movgest_ts_det_mod_spesa_id, coalesce(sum(rmodAcc.movgest_ts_det_mod_importo),0) movgest_ts_det_mod_importo
                     from siac_r_movgest_ts_det_mod rmodAcc,
                          siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                          siac_t_modifica modAcc,siac_d_modifica_stato statoAcc,siac_d_modifica_tipo tipoAcc
                     where statoAcc.ente_proprietario_id=p_enteProprietarioId
                     and   statoAcc.mod_stato_code!='A'
                     and   rsmodAcc.mod_stato_id=statoAcc.mod_stato_id
                     and   detmodAcc.mod_stato_r_id=rsmodAcc.mod_stato_r_id
                     and   modAcc.mod_id=rsmodAcc.mod_id
                     and   modAcc.elab_ror_reanno = FALSE
                     and   detmodAcc.mtdm_reimputazione_anno is not null
                     and   detmodAcc.mtdm_reimputazione_flag is true
                     and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                    -- and   rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                     and   rmodAcc.movgest_ts_det_mod_entrata_id=detmodAcc.movgest_ts_det_mod_id
                     and   tipoacc.mod_tipo_id=modAcc.mod_tipo_id
                     and   tipoacc.mod_tipo_code=motivo
                     and   rmodAcc.data_cancellazione is null
                     and   rmodAcc.validita_fine is null
                     and   rsmodAcc.data_cancellazione is null
                     and   rsmodAcc.validita_fine is null
                     and   detmodAcc.data_cancellazione is null
                     and   detmodAcc.validita_fine is null
                     and   modAcc.data_cancellazione is null
                     and   modAcc.validita_fine is null
                     group by rmodAcc.movgest_ts_det_mod_spesa_id
                     ) query_entrata on (query_entrata.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id)
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true

                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                group by bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 ts.movgest_ts_id,
                -- recmovgest.importoModifica
                 dettsmod.movgest_Ts_det_importo
               -- having -recmovgest.importoModifica - sum(rmodAcc.movgest_ts_det_mod_importo)!=0
                having -dettsmod.movgest_Ts_det_importo - coalesce(sum(query_entrata.movgest_ts_det_mod_importo),0)!=0
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new, -- -recmovgest.importoModifica-coalesce(totModCollegAcc,0), -- vincolo nuovo per la quota di differenza
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo B=%',codResult;
       end if;
       -- 12.04.2022 Sofia Jira SIAC-8489 - fine 
       -- 12.04.2022 Sofia Jira SIAC-8489 - inizio
       if motivo=motivoREANNO then 
        -- 19.04.2022 Sofia Jira SIAC-8489
        -- la modifica che diff di collegamento rispetto a modif acc.
        -- deve essere trattata come prima
        -- quindi la differenza va a FPV
       	strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                              ||recmovgest.movgest_ts_id::varchar
                              ||' Componente '
                              ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                              ||' ID= '
                              ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                              ||'. Caso modifica spesa-modifica entrata parte residua non collegata.Vincolo verso fpv.';

        raise notice 'strMessaggio=%',strMessaggio;
		codResult:=null;
        insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,                     -- movgest_ts_b_id
--                 rr.movgest_ts_a_id movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric movgest_ts_a_id, 
                 null::numeric importo_vincolo,
                 -dettsmod.movgest_Ts_det_importo - coalesce(sum(query_entrata.movgest_ts_det_mod_importo),0) importo_residuo_vincolare,
--                  coalesce(sum(-rvinc.importo_delta),0) importo_vincolo_new
                 -dettsmod.movgest_Ts_det_importo - coalesce(sum(query_entrata.movgest_ts_det_mod_importo),0) importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts_det_mod  dettsmod  join
                     (
                     select rmodAcc.movgest_ts_det_mod_spesa_id, coalesce(sum(rmodAcc.movgest_ts_det_mod_importo),0) movgest_ts_det_mod_importo
                     from siac_r_movgest_ts_det_mod rmodAcc,
                          siac_t_movgest_ts_det_mod detmodAcc,siac_r_modifica_stato rsModAcc,
                          siac_t_modifica modAcc,siac_d_modifica_stato statoAcc,siac_d_modifica_tipo tipoAcc
                     where statoAcc.ente_proprietario_id=p_enteProprietarioId
                     and   statoAcc.mod_stato_code!='A'
                     and   rsmodAcc.mod_stato_id=statoAcc.mod_stato_id
                     and   detmodAcc.mod_stato_r_id=rsmodAcc.mod_stato_r_id
                     and   modAcc.mod_id=rsmodAcc.mod_id
                     and   modAcc.elab_ror_reanno = FALSE
                     and   detmodAcc.mtdm_reimputazione_anno is not null
                     and   detmodAcc.mtdm_reimputazione_flag is true
                     and   detmodAcc.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                     and   rmodAcc.movgest_ts_det_mod_entrata_id=detmodAcc.movgest_ts_det_mod_id
                     and   tipoacc.mod_tipo_id=modAcc.mod_tipo_id
                     and   tipoacc.mod_tipo_code=motivo
                     and   rmodAcc.data_cancellazione is null
                     and   rmodAcc.validita_fine is null
                     and   rsmodAcc.data_cancellazione is null
                     and   rsmodAcc.validita_fine is null
                     and   detmodAcc.data_cancellazione is null
                     and   detmodAcc.validita_fine is null
                     and   modAcc.data_cancellazione is null
                     and   modAcc.validita_fine is null
                     group by rmodAcc.movgest_ts_det_mod_spesa_id
                     ) query_entrata on (query_entrata.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id)
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                group by bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 ts.movgest_ts_id,
                -- recmovgest.importoModifica
                 dettsmod.movgest_Ts_det_importo
                 --rr.movgest_ts_a_id
                having -dettsmod.movgest_Ts_det_importo - coalesce(sum(query_entrata.movgest_ts_det_mod_importo),0)!=0
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new, 
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
             from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo B=%',codResult;
         
         -- il loop principale per emissione impegni
         -- totalizza senza distinguere per mod_id
         -- e inserisce i due impegni per totale fresco e non fresco
         -- le insert per vincoli distinguono per mod_id quindi bisogna
         -- ulteriormente distinguere i casi sotto
         -- gestione casi di modifiche che non sono associate a modif. acc
		 
         -- Vincolo accertamento
        strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                              ||recmovgest.movgest_ts_id::varchar
                              ||' Componente '
                              ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                              ||' ID= '
                              ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                              ||'. Caso modifica spesa non collegata modifica entrata.Vincolo verso accertamento.';

        raise notice 'strMessaggio=%',strMessaggio;
		codResult:=null;
        insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,                     -- movgest_ts_b_id
                 rr.movgest_ts_a_id movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 coalesce(sum(-rvinc.importo_delta),0) importo_vincolo_new
                 from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_r_movgest_ts rr,siac_r_modifica_vincolo rvinc
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rr.movgest_ts_b_id=recmovgest.movgest_ts_id
                and   rr.movgest_ts_a_id is not null
                and   rvinc.movgest_ts_r_id=rr.movgest_ts_r_id 
                and   rvinc.mod_id=mod.mod_id
                and   rvinc.modvinc_tipo_operazione ='INSERIMENTO'
                -- la specifica modifica di spesa non deve avere associazioni a entrata
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rmodAcc 
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id 
                and   rmodAcc.data_cancellazione is null 
                and   rmodAcc.validita_Fine is null 
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rr.data_cancellazione is null
                and   rr.validita_fine is null
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                group by bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 ts.movgest_ts_id,
                -- recmovgest.importoModifica
--                 dettsmod.movgest_Ts_det_importo,
                 rr.movgest_ts_a_id
                having coalesce(sum(-rvinc.importo_delta),0)!=0
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   -1,
                   vincPrec.importo_vincolo_new, 
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
             from vincPrec
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo B=%',codResult;
        
         -- Vincolo AAM/FPV
         strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                              ||recmovgest.movgest_ts_id::varchar
                              ||' Componente '
                              ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                              ||' ID= '
                              ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                              ||'. Caso modifica spesa non collegata modifica entrata.Vincolo AAM/FPV.';

         raise notice 'strMessaggio=%',strMessaggio;
		 codResult:=null;
         insert into   fase_bil_t_reimputazione_vincoli
         (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annobilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,    -- movgest_ts_a_id
                 rr.avav_id avav_id,               -- avav_id
                 null::numeric importo_vincolo,
                 coalesce(sum(-rvinc.importo_delta),0) importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_r_movgest_ts rr,siac_r_modifica_vincolo rvinc
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rr.movgest_ts_b_id=recmovgest.movgest_ts_id
                and   rr.avav_id is not null
                and   rvinc.movgest_ts_r_id=rr.movgest_ts_r_id 
                and   rvinc.mod_id=mod.mod_id
                and   rvinc.modvinc_tipo_operazione ='INSERIMENTO'
                -- la specifica modifica di spesa non deve avere associazioni a entrata
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rmodAcc 
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id 
                and   rmodAcc.data_cancellazione is null 
                and   rmodAcc.validita_Fine is null 
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rr.data_cancellazione is null
                and   rr.validita_fine is null
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                group by bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 ts.movgest_ts_id,
                -- recmovgest.importoModifica
                 dettsmod.movgest_Ts_det_importo,
                 rr.avav_id
                having coalesce(sum(-rvinc.importo_delta),0) !=0
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   vincPrec.avav_id,
                   vincPrec.importo_vincolo_new, 
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec, avanzoTipo
            where vincPrec.avav_id=avanzoTipo.avav_id
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo B=%',codResult;
        
         -- Nessun Vincolo o differenza ancora da caricare rispetto a 
         -- tot modifica-tot.collegato-tot.inserito per vincoli
         strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                              ||recmovgest.movgest_ts_id::varchar
                              ||' Componente '
                              ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                              ||' ID= '
                              ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                              ||'. Caso modifica spesa non collegata modifica entrata.Nessun Vincolo.';

         raise notice 'strMessaggio=%',strMessaggio;
		 codResult:=null;
         insert into   fase_bil_t_reimputazione_vincoli
         (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annobilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,    -- movgest_ts_a_id
                 null::integer avav_id,               -- avav_id
                 null::numeric importo_vincolo,
                 abs(dettsmod.movgest_Ts_det_importo) importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_modifica mod,siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts_det_mod  dettsmod
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   not exists 
                (
                select 1 
                from siac_r_movgest_ts rr,siac_r_modifica_vincolo rvinc
                where rr.movgest_ts_b_id=recmovgest.movgest_ts_id
                and   rr.avav_id is not null
                and   rvinc.movgest_ts_r_id=rr.movgest_ts_r_id 
                and   rvinc.mod_id=mod.mod_id
                and   rvinc.modvinc_tipo_operazione ='INSERIMENTO'
                and   rr.data_cancellazione is null
                and   rr.validita_fine is null
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                )
                -- la specifica modifica di spesa non deve avere associazioni a entrata
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rmodAcc 
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id 
                and   rmodAcc.data_cancellazione is null 
                and   rmodAcc.validita_Fine is null 
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                 group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         dettsmod.movgest_ts_det_importo
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new, 
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec, avanzoTipo, titoloNew
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
         );
         GET DIAGNOSTICS codResult = ROW_COUNT;
         raise notice 'Inserimeno quota vincolo B=%',codResult;
        
       end if;
      -- 12.04.2022 Sofia Jira SIAC-8489 - fine 
      
	end if;


    -- 08.06.2020 Sofia Jira siac-7593
    -- mod spesa non collegata a mod entrata
    -- in questo caso tutto come prima di questa jira
    -- C
    -- si creano impegni reimputati su componente FPV,  tutti i vincoli vengono reimputati a FPV
    -- anche se avevano AAM, accertamento e se non avevano vincolo
    if faseReimpFrescoId is null and faseReimpFpvId is not null  and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then
       
       --- 12.04.2022 Sofia JIRA SIAC-8489 -- inizio
       if motivo = motivoREIMP then 
       strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso C modfica spesa-modifica entrata non collegata.';
        raise notice 'C strMessaggio=%',strMessaggio;
		codResult:=null;
       insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,  -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 (case when coalesce(sum(abs(rvinc.importo_delta)),0)!=0 then
                            coalesce(sum(abs(rvinc.importo_delta)),0)
                       else abs(dettsmod.movgest_ts_det_importo) end ) -- se non esiste neanche un vincolo lo crea per importo della modifica
                  importo_vincolo_new -- importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts ts,
                     siac_t_modifica mod
                      left join  siac_r_modifica_vincolo rvinc -- se non esiste neanche un vincolo lo crea per importo della modifica
                           join  siac_r_movgest_ts rr
                           on (rr.movgest_ts_r_id=rvinc.movgest_ts_r_id
                               and rr.data_cancellazione is null
                               and rr.validita_fine is null )
                      on (rvinc.mod_id=mod.mod_id and rvinc.modvinc_tipo_operazione='INSERIMENTO'
                         and rvinc.data_cancellazione is null
                         and rvinc.validita_fine is null)
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rModAcc
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         dettsmod.movgest_ts_det_importo
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'Inserimeno quota vincolo B=%',codResult;
       end if;
       --- 12.04.2022 Sofia JIRA SIAC-8489 -- fine
      
       --- 12.04.2022 Sofia JIRA SIAC-8489 -- inizio 
       if motivo=motivoREANNO then 
        raise notice '**REANNO SENZA ASSOCIAZIONI ***';
       	-- vincolo accertamento 
        strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso modifica spesa-modifica entrata non collegata - vincolo accertamento.';
        raise notice 'strMessaggio=%',strMessaggio;
		codResult:=null;
        insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,  -- movgest_ts_b_id
                 rr.movgest_ts_a_id,     -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 coalesce(sum(abs(rvinc.importo_delta)),0) importo_vincolo_new -- importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts ts,
                     siac_t_modifica mod,
                     siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rr
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rr.movgest_ts_b_id=ts.movgest_ts_id
                and   rr.movgest_ts_a_id is not null
                and   rvinc.movgest_ts_r_id=rr.movgest_ts_r_id
                and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
                and   rvinc.mod_id=mod.mod_id 
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rModAcc
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
			    and   rr.data_cancellazione is null
                and   rr.validita_fine is null                          
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         rr.movgest_ts_a_id
                having coalesce(sum(abs(rvinc.importo_delta)),0)!=0
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   -1,--avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'Inserimeno quota vincolo C=%',codResult;
       
        -- vincolo AAM ,FPV
        strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso moodfica spesa non collegata a modifica entrata - AAM,FPV.';
        raise notice 'strMessaggio=%',strMessaggio;
		codResult:=null;
        insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('AAM','FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annobilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,  -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,     -- movgest_ts_a_id
                 rr.avav_id,  -- avav_id
                 null::numeric importo_vincolo,
                 coalesce(sum(abs(rvinc.importo_delta)),0) importo_vincolo_new -- importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts ts,
                     siac_t_modifica mod,
                     siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rr
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   rr.movgest_ts_b_id=ts.movgest_ts_id
                and   rr.avav_id is not null
                and   rvinc.movgest_ts_r_id=rr.movgest_ts_r_id
                and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
                and   rvinc.mod_id=mod.mod_id 
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rModAcc
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
			    and   rr.data_cancellazione is null
                and   rr.validita_fine is null                          
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         rr.avav_id
                having coalesce(sum(abs(rvinc.importo_delta)),0)!=0
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,avanzoTipo
            where avanzoTipo.avav_id=vincPrec.avav_id
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'Inserimeno quota vincolo C=%',codResult;

       -- nessun vincolo
       strMessaggio := 'Inserimento in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='
                          ||recmovgest.movgest_ts_id::varchar
                          ||' Componente '
                          ||(case when componenteFittiziaId is not null then 'Fittizia' else 'FPV'  end )
                          ||' ID= '
                          ||(case when componenteFittiziaId is not null then componenteFittiziaId::varchar else componenteFpvId::varchar  end )
                          ||'. Caso modifica spesa non collegata a modifica di entrata. Nessun Vincolo.';
        raise notice 'strMessaggio=%',strMessaggio;
		codResult:=null;
       insert into   fase_bil_t_reimputazione_vincoli
        (
          reimputazione_id,
          fasebilelabid,
          bil_id,
          mod_id,
          mod_tipo_code,
          reimputazione_anno,
          movgest_ts_r_id,
          movgest_ts_b_id,
          movgest_ts_a_id,
          importo_vincolo,
          avav_new_id,
          importo_vincolo_new,
          data_creazione,
          login_operazione,
          ente_proprietario_id
        )
        (
            with
            titoloNew as
            (
                select cTitolo.classif_code::integer titolo_uscita,
                       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                          then 'FPVSC'
                          when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                          then 'FPVCC'
                          else null end ) tipo_avanzo
                from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
                     siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
                     siac_r_class_fam_tree rfam,
                     siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
                     siac_t_bil bil, siac_t_periodo per
                where tipo.ente_proprietario_id=p_enteProprietarioId
                and   tipo.elem_tipo_code=CAP_UG_TIPO
                and   e.elem_tipo_id=tipo.elem_tipo_id
                and   bil.bil_id=e.bil_id
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=p_annoBilancio
                and   e.elem_code::integer=recmovgest.elem_code::integer
                and   e.elem_code2::integer=recmovgest.elem_code2::integer
                and   e.elem_code3::integer=recmovgest.elem_code3::integer
                and   rc.elem_id=e.elem_id
                and   cMacro.classif_id=rc.classif_id
                and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
                and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
                and   rfam.classif_id=cMacro.classif_id
                and   cTitolo.classif_id=rfam.classif_id_padre
                and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
                and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
                and   e.data_cancellazione is null
                and   e.validita_fine is null
                and   rc.data_cancellazione is null
                and   rc.validita_fine is null
                and   rfam.data_cancellazione is null
                and   rfam.validita_fine is null
            ),
            avanzoTipo as
            (
                select av.avav_id, avtipo.avav_tipo_code
                from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
                where avtipo.ente_proprietario_id=p_enteProprietarioId
                and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
                and   av.avav_tipo_id=avtipo.avav_tipo_id
                and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
            ),
            vincPrec as
            (
                select
                 bil.bil_id,
                 mod.mod_id,
                 tipomod.mod_tipo_code,
                 dettsmod.mtdm_reimputazione_anno::integer,
                 null::integer movgest_ts_r_id,
                 ts.movgest_ts_id movgest_ts_b_id,  -- movgest_ts_b_id
                 null::integer movgest_ts_a_id,              -- movgest_ts_a_id
                 null::numeric importo_vincolo,
                 abs(dettsmod.movgest_ts_det_importo) importo_vincolo_new -- importo_vincolo_new
                from siac_t_bil bil ,
                     siac_t_periodo per,
                     siac_t_movgest mov,siac_d_movgest_tipo tipo,
                     siac_d_movgest_ts_tipo tipots,
                     siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
                     siac_t_movgest_ts_det_mod  dettsmod,
                     siac_d_modifica_tipo tipomod,
                     siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
                     siac_t_movgest_ts ts,
                     siac_t_modifica mod
                where bil.ente_proprietario_id=p_enteProprietarioId
                and   per.periodo_id=bil.periodo_id
                and   per.anno::integer=v_annoBilancio
                and   tipo.ente_proprietario_id=bil.ente_proprietario_id
                and   tipo.movgest_tipo_code=p_movgest_tipo_code
                and   mov.movgest_tipo_id=tipo.movgest_tipo_id
                and   mov.bil_id=bil.bil_id
                and   ts.movgest_id=mov.movgest_id
                and   ts.movgest_ts_id=recmovgest.movgest_ts_id
                and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
                and   detts.movgest_ts_id=ts.movgest_ts_id
                and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
                and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
                and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
                and   modstato.mod_stato_id=rmodstato.mod_stato_id
                and   modstato.mod_stato_code='V'
                and   mod.mod_id=rmodstato.mod_id
                and   tipomod.mod_tipo_id =  mod.mod_tipo_id
                and   mod.elab_ror_reanno = FALSE
                and   tipomod.mod_tipo_code = motivo
                and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code
                and   dettsmod.mtdm_reimputazione_anno is not null
                and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno
                and   dettsmod.mtdm_reimputazione_flag is true
                and   not exists
                (
                select 1
                from siac_r_movgest_ts_det_mod rModAcc
                where rmodAcc.movgest_ts_det_mod_spesa_id=dettsmod.movgest_ts_det_mod_id
                and   rmodAcc.data_cancellazione is null
                and   rmodAcc.validita_fine is null
                )
                and   not exists 
                (
                select 1
                from siac_r_movgest_ts rr ,siac_r_modifica_vincolo rvinc
                where rr.movgest_ts_b_id=recmovgest.movgest_ts_id
                and   rvinc.movgest_ts_r_id=rr.movgest_ts_r_id 
                and   rvinc.mod_id=mod.mod_id 
                and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
                and   rr.data_cancellazione is null 
                and   rr.validita_fine is null 
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                )
                and   rmodstato.validita_fine is null
                and   mov.data_cancellazione is null
                and   mov.validita_fine is null
                and   ts.data_cancellazione is null
                and   ts.validita_fine is null
                and   detts.data_cancellazione is null
                and   detts.validita_fine is null
                and   dettsmod.data_cancellazione is null
                and   dettsmod.validita_fine is null
                and   rmodstato.data_cancellazione is null
                and   rmodstato.validita_fine is null
                and   mod.data_cancellazione is null
                and   mod.validita_fine is null
                group by bil.bil_id,
                         mod.mod_id,
                         tipomod.mod_tipo_code,
                         dettsmod.mtdm_reimputazione_anno::integer,
                         ts.movgest_ts_id,
                         dettsmod.movgest_ts_det_importo
            )
            select faseReimpFpvId,
                   p_faseBilElabId,
                   vincPrec.bil_id,
                   vincPrec.mod_id,
                   vincPrec.mod_tipo_code,
                   vincPrec.mtdm_reimputazione_anno,
                   vincPrec.movgest_ts_r_id,
                   vincPrec.movgest_ts_b_id,
                   vincPrec.movgest_ts_a_id,
                   vincPrec.importo_vincolo,
                   avanzoTipo.avav_id,
                   vincPrec.importo_vincolo_new,
                   clock_timestamp(),
                   p_loginoperazione,
                   p_enteProprietarioId
            from vincPrec,titoloNew,avanzoTipo
            where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
        );
        GET DIAGNOSTICS codResult = ROW_COUNT;
        raise notice 'Inserimeno quota vincolo B=%',codResult;
       
       end if;
      
	end if;

    -- 08.06.2020 Sofia Jira siac-7593 - fine

/*  09.06.2020 Sofia SIAC-7593 - commentato tutta la parte di vincoli precedentemente implementata

    /* 31.01.2018 Sofia siac-5788 -
       inserimento in fase_bil_t_reimputazione_vincoli per traccia delle modifiche legata a vincoli
       con predisposizione dei dati utili per il successivo job di elaborazione dei vincoli riaccertati
    */
    if codResult is not null  and
       p_movgest_tipo_code=MOVGEST_IMP_TIPO then

        /* caso 1
   	       se il vincolo abbattuto era del tipo FPV ->
           creare analogo vincolo nel nuovo bilancio per la quote di vincolo
           abbattuta */
    	strMessaggio := 'Inserimento caso 1 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;
        -- 23.03.2018 Sofia dopo elaborazione riacc_vincoli su CMTO
		-- per bugprod : aggiungere condizione su
        -- anno_reimputazione e tipo_modifica presi da recmovgest
        -- recmovgest.mtdm_reimputazione_anno
        -- recmovgest.mod_tipo_code
        -- si dovrebbe raggruppare e totalizzare ma su questa tabella nn si puo per il mod_id
        -- quindi bisogna poi modificare la logica nella creazione dei vincoli totalizzando
        -- per recmovgest.mtdm_reimputazione_anno
        -- recmovgest.mod_tipo_code ovvero per movimento reimputato
        -- controllare poi anche le altre casistiche
		-- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	    insert into   fase_bil_t_reimputazione_vincoli
		(
			reimputazione_id,
		    fasebilelabid,
		    bil_id,
		    mod_id,
            mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
            reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
		    movgest_ts_r_id,
		    movgest_ts_b_id,
		    avav_id,
		    importo_vincolo,
		    avav_new_id,
		    importo_vincolo_new,
		    data_creazione,
		    login_operazione,
		    ente_proprietario_id
		)
		(select
		 codResult,
		 p_faseBilElabId,
		 bil.bil_id,
		 mod.mod_id,
         tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
         dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
		 rvinc.movgest_ts_r_id,
		 ts.movgest_ts_id, -- movgest_ts_b_id
		 av.avav_id,
		 rts.movgest_ts_importo,
		 avnew.avav_id,       -- avav_new_id
		 abs(rvinc.importo_delta), -- importo_vincolo_new
		 clock_timestamp(),
		 p_loginoperazione,
		 p_enteProprietarioId
		from siac_t_bil bil ,
		     siac_t_periodo per,
		     siac_t_movgest mov,siac_d_movgest_tipo tipo,
		     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
			 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
			 siac_t_movgest_ts_det_mod  dettsmod,
			 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
			 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
			 siac_r_modifica_vincolo rvinc,
		     siac_r_movgest_ts rts,
		     siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav,
		     siac_t_avanzovincolo avnew
		where bil.ente_proprietario_id=p_enteProprietarioId
		and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--		and   per.anno::integer=p_annoBilancio-1
        and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
		and   tipo.ente_proprietario_id=bil.ente_proprietario_id
		and   tipo.movgest_tipo_code=p_movgest_tipo_code
		and   mov.movgest_tipo_id=tipo.movgest_tipo_id
		and   mov.bil_id=bil.bil_id
		and   ts.movgest_id=mov.movgest_id
		and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
		and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
		and   detts.movgest_ts_id=ts.movgest_ts_id
		and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
		and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
		and   dettsmod.movgest_ts_det_importo<0
		and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
		and   modstato.mod_stato_id=rmodstato.mod_stato_id
		and   modstato.mod_stato_code='V'
		and   mod.mod_id=rmodstato.mod_id
		and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
		and   rvinc.mod_id=mod.mod_id
		and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
		and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
		and   av.avav_id=rts.avav_id
		and   tipoav.avav_tipo_id=av.avav_tipo_id
		and   tipoav.avav_tipo_code in ('FPVCC','FPVSC')
		and   avnew.avav_tipo_id=tipoav.avav_tipo_id
		and   extract('year' from avnew.validita_inizio::timestamp)::integer=p_annoBilancio
		and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
		and   dettsmod.mtdm_reimputazione_flag is true
		and   rmodstato.validita_fine is null
		and   mov.data_cancellazione is null
		and   mov.validita_fine is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   detts.data_cancellazione is null
		and   detts.validita_fine is null
		and   dettsmod.data_cancellazione is null
		and   dettsmod.validita_fine is null
		and   rmodstato.data_cancellazione is null
		and   rmodstato.validita_fine is null
		and   mod.data_cancellazione is null
		and   mod.validita_fine is null
		and   rvinc.data_cancellazione is null
		and   rvinc.validita_fine is null
		and   rts.data_cancellazione is null
		and   rts.validita_fine is null
	   );

    	strMessaggio := 'Inserimento caso 2 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

	  /* caso 2
		 se il vincolo abbattuto era del tipo Avanzo -> creare un vincolo nel nuovo bilancio di tipo FPV
		 per la quote di vincolo abbattuta con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno
		 (vedi algoritmo a seguire) */
	  -- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	  insert into   fase_bil_t_reimputazione_vincoli
	  (
		reimputazione_id,
    	fasebilelabid,
	    bil_id,
    	mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
	    movgest_ts_r_id,
	    movgest_ts_b_id,
	    avav_id,
	    importo_vincolo,
	    avav_new_id,
	    importo_vincolo_new,
	    data_creazione,
	    login_operazione,
    	ente_proprietario_id
	   )
	   (
		with
		titoloNew as
	    (
    	  	select cTitolo.classif_code::integer titolo_uscita,
        	       ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
	        from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
    	         siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
        	     siac_r_class_fam_tree rfam,
            	 siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
	             siac_t_bil bil, siac_t_periodo per
    	    where tipo.ente_proprietario_id=p_enteProprietarioId
	        and   tipo.elem_tipo_code=CAP_UG_TIPO
	        and   e.elem_tipo_id=tipo.elem_tipo_id
    	    and   bil.bil_id=e.bil_id
	        and   per.periodo_id=bil.periodo_id
	        and   per.anno::integer=p_annoBilancio
	        and   e.elem_code::integer=recmovgest.elem_code::integer
	        and   e.elem_code2::integer=recmovgest.elem_code2::integer
	        and   e.elem_code3=recmovgest.elem_code3
	        and   rc.elem_id=e.elem_id
	        and   cMacro.classif_id=rc.classif_id
	        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
	        and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
	        and   rfam.classif_id=cMacro.classif_id
	        and   cTitolo.classif_id=rfam.classif_id_padre
	        and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
    	    and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
	        and   e.data_cancellazione is null
	        and   e.validita_fine is null
	        and   rc.data_cancellazione is null
	        and   rc.validita_fine is null
	        and   rfam.data_cancellazione is null
	        and   rfam.validita_fine is null
	   ),
	   avanzoTipo as
   	   (
		 select av.avav_id, avtipo.avav_tipo_code
		 from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
		 where avtipo.ente_proprietario_id=p_enteProprietarioId
		 and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
		 and   av.avav_tipo_id=avtipo.avav_tipo_id
	     and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
	   ),
	   vincPrec as
	   (
		select
		 bil.bil_id,
		 mod.mod_id,
         tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
         dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
		 rvinc.movgest_ts_r_id,
		 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
		 av.avav_id,
		 rts.movgest_ts_importo importo_vincolo,
		 abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
		from siac_t_bil bil ,
		     siac_t_periodo per,
		     siac_t_movgest mov,siac_d_movgest_tipo tipo,
		     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
			 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
			 siac_t_movgest_ts_det_mod  dettsmod,
			 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
			 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
			 siac_r_modifica_vincolo rvinc,
		     siac_r_movgest_ts rts,
		     siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipoav
		where bil.ente_proprietario_id=p_enteProprietarioId
		and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--		and   per.anno::integer=p_annoBilancio-1
        and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
        and   tipo.ente_proprietario_id=bil.ente_proprietario_id
		and   tipo.movgest_tipo_code=p_movgest_tipo_code
		and   mov.movgest_tipo_id=tipo.movgest_tipo_id
		and   mov.bil_id=bil.bil_id
		and   ts.movgest_id=mov.movgest_id
		and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
		and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
		and   detts.movgest_ts_id=ts.movgest_ts_id
		and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
		and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
		and   dettsmod.movgest_ts_det_importo<0
		and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
		and   modstato.mod_stato_id=rmodstato.mod_stato_id
		and   modstato.mod_stato_code='V'
		and   mod.mod_id=rmodstato.mod_id
		and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
        and   mod.elab_ror_reanno = FALSE
        and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
        and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
		and   rvinc.mod_id=mod.mod_id
		and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
		and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
		and   av.avav_id=rts.avav_id
		and   tipoav.avav_tipo_id=av.avav_tipo_id
		and   tipoav.avav_tipo_code  ='AAM'
		and   dettsmod.mtdm_reimputazione_anno is not null
        and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
		and   dettsmod.mtdm_reimputazione_flag is true
		and   rmodstato.validita_fine is null
		and   mov.data_cancellazione is null
		and   mov.validita_fine is null
		and   ts.data_cancellazione is null
		and   ts.validita_fine is null
		and   detts.data_cancellazione is null
		and   detts.validita_fine is null
		and   dettsmod.data_cancellazione is null
		and   dettsmod.validita_fine is null
		and   rmodstato.data_cancellazione is null
		and   rmodstato.validita_fine is null
		and   mod.data_cancellazione is null
		and   mod.validita_fine is null
		and   rvinc.data_cancellazione is null
		and   rvinc.validita_fine is null
		and   rts.data_cancellazione is null
		and   rts.validita_fine is null
	 )
	  select codResult,
	 	     p_faseBilElabId,
	         vincPrec.bil_id,
    	     vincPrec.mod_id,
             vincPrec.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             vincPrec.mtdm_reimputazione_anno,  -- 06.04.2018 Sofia JIRA SIAC-6054
	         vincPrec.movgest_ts_r_id,
	         vincPrec.movgest_ts_b_id,
    	     vincPrec.avav_id,
	         vincPrec.importo_vincolo,
	         avanzoTipo.avav_id,
	         vincPrec.importo_vincolo_new,
	         clock_timestamp(),
	         p_loginoperazione,
	         p_enteProprietarioId
	  from vincPrec,titoloNew,avanzoTipo
	  where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
      );

    	strMessaggio := 'Inserimento caso 3,4 in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

      /* caso 3
  		 se il vincolo abbattuto era legato ad un accertamento
		 che non presenta quote riaccertate esso stesso:
		 creare un vincolo nel nuovo bilancio di tipo FPV per la quote di vincolo abbattuta
		 con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno (vedi algoritmo a seguire)*/

	  /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
      -- 06.04.2018 Sofia JIRA SIAC-6054 - aggiunto filtri per tipo_modifica e anno_reimputazione
	  insert into   fase_bil_t_reimputazione_vincoli
  	  (
		reimputazione_id,
	    fasebilelabid,
    	bil_id,
	    mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
    	movgest_ts_r_id,
	    movgest_ts_b_id,
    	movgest_ts_a_id,
	    importo_vincolo,
    	avav_new_id,
	    importo_vincolo_new,
    	data_creazione,
	    login_operazione,
    	ente_proprietario_id
	 )
     (
		with
		titoloNew as
        (
  	    	select cTitolo.classif_code::integer titolo_uscita,
    	           ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        	from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
            	 siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
	             siac_r_class_fam_tree rfam,
    	         siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
        	     siac_t_bil bil, siac_t_periodo per
	        where tipo.ente_proprietario_id=p_enteProprietarioId
    	    and   tipo.elem_tipo_code=CAP_UG_TIPO
	        and   e.elem_tipo_id=tipo.elem_tipo_id
    	    and   bil.bil_id=e.bil_id
	        and   per.periodo_id=bil.periodo_id
	        and   per.anno::integer=p_annoBilancio
    	    and   e.elem_code::integer=recmovgest.elem_code::integer
	        and   e.elem_code2::integer=recmovgest.elem_code2::integer
    	    and   e.elem_code3::integer=recmovgest.elem_code3::integer
	        and   rc.elem_id=e.elem_id
    	    and   cMacro.classif_id=rc.classif_id
	        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
    	    and   tipomacro.classif_tipo_code=MACROAGGREGATO_TIPO
        	and   rfam.classif_id=cMacro.classif_id
	        and   cTitolo.classif_id=rfam.classif_id_padre
    	    and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        	and   tipoTitolo.classif_tipo_code=TITOLO_SPESA_TIPO
	        and   e.data_cancellazione is null
    	    and   e.validita_fine is null
        	and   rc.data_cancellazione is null
	        and   rc.validita_fine is null
    	    and   rfam.data_cancellazione is null
	        and   rfam.validita_fine is null
		),
		avanzoTipo as
		(
			select av.avav_id, avtipo.avav_tipo_code
			from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
			where avtipo.ente_proprietario_id=p_enteProprietarioId
			and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
			and   av.avav_tipo_id=avtipo.avav_tipo_id
			and   extract('year' from av.validita_inizio::timestamp)::integer=p_annoBilancio
		),
		vincPrec as
		(
			select
			 bil.bil_id,
			 mod.mod_id,
             tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
			 rvinc.movgest_ts_r_id,
			 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
			 rts.movgest_ts_a_id,              -- movgest_ts_a_id
			 rts.movgest_ts_importo importo_vincolo,
			 abs(rvinc.importo_delta) importo_vincolo_new -- importo_vincolo_new
			from siac_t_bil bil ,
			     siac_t_periodo per,
			     siac_t_movgest mov,siac_d_movgest_tipo tipo,
			     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
				 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
				 siac_t_movgest_ts_det_mod  dettsmod,
				 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
				 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
				 siac_r_modifica_vincolo rvinc,
			     siac_r_movgest_ts rts
			where bil.ente_proprietario_id=p_enteProprietarioId
			and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--			and   per.anno::integer=p_annoBilancio-1
            and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
			and   tipo.ente_proprietario_id=bil.ente_proprietario_id
			and   tipo.movgest_tipo_code=p_movgest_tipo_code
			and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			and   mov.bil_id=bil.bil_id
			and   ts.movgest_id=mov.movgest_id
			and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
			and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			and   detts.movgest_ts_id=ts.movgest_ts_id
			and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
			and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
			and   dettsmod.movgest_ts_det_importo<0
			and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
			and   modstato.mod_stato_id=rmodstato.mod_stato_id
			and   modstato.mod_stato_code='V'
			and   mod.mod_id=rmodstato.mod_id
			and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
            and   mod.elab_ror_reanno = FALSE
            and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
            and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   rts.movgest_ts_a_id is not null -- legato ad accertamento
			and   dettsmod.mtdm_reimputazione_anno is not null
            and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
			and   dettsmod.mtdm_reimputazione_flag is true
			and   rmodstato.validita_fine is null
			and   mov.data_cancellazione is null
			and   mov.validita_fine is null
			and   ts.data_cancellazione is null
			and   ts.validita_fine is null
			and   detts.data_cancellazione is null
			and   detts.validita_fine is null
			and   dettsmod.data_cancellazione is null
			and   dettsmod.validita_fine is null
			and   rmodstato.data_cancellazione is null
			and   rmodstato.validita_fine is null
			and   mod.data_cancellazione is null
			and   mod.validita_fine is null
			and   rvinc.data_cancellazione is null
			and   rvinc.validita_fine is null
			and   rts.data_cancellazione is null
			and   rts.validita_fine is null
		)
		select codResult,
	    	   p_faseBilElabId,
	           vincPrec.bil_id,
	  	       vincPrec.mod_id,
               vincPrec.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
               vincPrec.mtdm_reimputazione_anno,  -- 06.04.2018 Sofia JIRA SIAC-6054
	  	   	   vincPrec.movgest_ts_r_id,
	           vincPrec.movgest_ts_b_id,
	  	       vincPrec.movgest_ts_a_id,
	      	   vincPrec.importo_vincolo,
	           avanzoTipo.avav_id,
	           vincPrec.importo_vincolo_new,
	           clock_timestamp(),
	           p_loginoperazione,
       	       p_enteProprietarioId
        from vincPrec,titoloNew,avanzoTipo
		where titoloNew.tipo_avanzo=avanzoTipo.avav_tipo_code
	   );


       /* gestione scarti
       */
    	strMessaggio := 'Inserimento scarti in in fase_bil_t_reimputazione_vincoli per movimento movgest_ts_id='||recmovgest.movgest_ts_id::varchar||'.';
	    raise notice 'strMessaggio=%',strMessaggio;

       insert into   fase_bil_t_reimputazione_vincoli
  	  (
		reimputazione_id,
	    fasebilelabid,
    	bil_id,
	    mod_id,
        mod_tipo_code,      -- 06.04.2018 Sofia JIRA SIAC-6054
        reimputazione_anno, -- 06.04.2018 Sofia JIRA SIAC-6054
    	movgest_ts_r_id,
	    movgest_ts_b_id,
    	movgest_ts_a_id,
	    importo_vincolo,
	    importo_vincolo_new,
        scarto_code,
        scarto_desc,
    	data_creazione,
	    login_operazione,
    	ente_proprietario_id
	 )
     (
			select
             codResult,
             p_faseBilElabId,
			 bil.bil_id,
			 mod.mod_id,
             tipomod.mod_tipo_code,  -- 06.04.2018 Sofia JIRA SIAC-6054
             dettsmod.mtdm_reimputazione_anno::integer, -- 06.04.2018 Sofia JIRA SIAC-6054
			 rvinc.movgest_ts_r_id,
			 ts.movgest_ts_id movgest_ts_b_id, -- movgest_ts_b_id
			 rts.movgest_ts_a_id,              -- movgest_ts_a_id
			 rts.movgest_ts_importo,  -- importo_vincolo
			 abs(rvinc.importo_delta), -- importo_vincolo_new
             '99',
             'VINCOLO NON CLASSIFICATO',
             clock_timestamp(),
             p_loginoperazione,
     	     p_enteProprietarioId
			from siac_t_bil bil ,
			     siac_t_periodo per,
			     siac_t_movgest mov,siac_d_movgest_tipo tipo,
			     siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
				 siac_t_movgest_ts_det detts,siac_d_movgest_ts_det_tipo tipodet,
				 siac_t_movgest_ts_det_mod  dettsmod,
				 siac_t_modifica mod,siac_d_modifica_tipo tipomod,
				 siac_r_modifica_stato  rmodstato,siac_d_modifica_stato modstato,
				 siac_r_modifica_vincolo rvinc,
			     siac_r_movgest_ts rts
			where bil.ente_proprietario_id=p_enteProprietarioId
			and   per.periodo_id=bil.periodo_id
-- SIAC-6997 ---------------- INIZIO --------------------
--			and   per.anno::integer=p_annoBilancio-1
            and   per.anno::integer=v_annoBilancio
-- SIAC-6997 ---------------- INIZIO --------------------
			and   tipo.ente_proprietario_id=bil.ente_proprietario_id
			and   tipo.movgest_tipo_code=p_movgest_tipo_code
			and   mov.movgest_tipo_id=tipo.movgest_tipo_id
			and   mov.bil_id=bil.bil_id
			and   ts.movgest_id=mov.movgest_id
			and   ts.movgest_ts_id=recmovgest.movgest_ts_id        -- movgest_ts_id --> di impegno-sub appena gestito
			and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
			and   detts.movgest_ts_id=ts.movgest_ts_id
			and   dettsmod.movgest_ts_det_id=detts.movgest_ts_det_id
			and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
			and   dettsmod.movgest_ts_det_importo<0
			and   rmodstato.mod_stato_r_id=dettsmod.mod_stato_r_id
			and   modstato.mod_stato_id=rmodstato.mod_stato_id
			and   modstato.mod_stato_code='V'
			and   mod.mod_id=rmodstato.mod_id
			and   tipomod.mod_tipo_id =  mod.mod_tipo_id
-- SIAC-6997 ----------------  INIZIO --------------------
            and   mod.elab_ror_reanno = FALSE
            and   tipomod.mod_tipo_code = motivo
-- SIAC-6997 ----------------  FINE --------------------
            and   tipomod.mod_tipo_code=recmovgest.mod_tipo_code  -- 06.04.2018 Sofia JIRA SIAC-6054 - filtro modifiche per mod_tipo
			and   rvinc.mod_id=mod.mod_id
			and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
			and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
            and   rts.movgest_ts_b_id=ts.movgest_ts_id             -- vincolo legato a impegno riaccertato
			and   dettsmod.mtdm_reimputazione_anno is not null
            and   dettsmod.mtdm_reimputazione_anno=recmovgest.mtdm_reimputazione_anno -- 06.04.2018 Sofia JIRA SIAC-6054 filtro modifiche per anno_reimputazione
			and   dettsmod.mtdm_reimputazione_flag is true
            and   not exists
            (
            select 1
            from fase_bil_t_reimputazione_vincoli fase
            where fase.fasebilelabid=p_faseBilElabId
            and   fase.movgest_ts_r_id=rts.movgest_ts_r_id
            and   fase.movgest_ts_b_id=ts.movgest_ts_id
            and   fase.mod_tipo_code=recmovgest.mod_tipo_code -- 06.04.2018 Sofia JIRA SIAC-6054
            and   fase.reimputazione_anno=recmovgest.mtdm_reimputazione_anno::integer -- 06.04.2018 Sofia JIRA SIAC-6054
            )
			and   rmodstato.validita_fine is null
			and   mov.data_cancellazione is null
			and   mov.validita_fine is null
			and   ts.data_cancellazione is null
			and   ts.validita_fine is null
			and   detts.data_cancellazione is null
			and   detts.validita_fine is null
			and   dettsmod.data_cancellazione is null
			and   dettsmod.validita_fine is null
			and   rmodstato.data_cancellazione is null
			and   rmodstato.validita_fine is null
			and   mod.data_cancellazione is null
			and   mod.validita_fine is null
			and   rvinc.data_cancellazione is null
			and   rvinc.validita_fine is null
			and   rts.data_cancellazione is null
			and   rts.validita_fine is null
	   );


    end if;
09.06.2020 Sofia SIAC-7593 - fine */



    end loop;

    strMessaggio := 'fine del loop';

    outfaseBilElabRetId:=p_faseBilElabId;
    codiceRisultato:=0;
    messaggioRisultato:=strMessaggioFinale||' FINE';

    return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,strMessaggio,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,strMessaggio;
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,strMessaggio,SQLSTATE,substring(upper(SQLERRM) from 1 for 1500);
        messaggioRisultato:=strMessaggioFinale||strMessaggio||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 1500) ;
        codiceRisultato:=-1;
        outfaseBilElabRetId:=p_faseBilElabId;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

CREATE OR REPLACE FUNCTION siac.fnc_fasi_bil_gest_reimputa_vincoli (
  enteproprietarioid integer,
  annobilancio integer,
  loginoperazione varchar,
  dataelaborazione timestamp,
  out codicerisultato integer,
  out messaggiorisultato varchar
)
RETURNS record AS
$body$
DECLARE
	strMessaggio VARCHAR(1500):='';
	strMessaggioFinale VARCHAR(1500):='';

	codResult         integer:=null;

	tipoMovGestId      integer:=null;
    tipoMovGestAccId   integer:=null;

    movGestTsTipoId    integer:=null;

    bilancioId        integer:=null;
  	bilancioPrecId    integer:=null;

    periodoId         integer:=null;
    periodoPrecId     integer:=null;

    movGestStatoAId   integer:=null;

    movGestRec        record;
    resultRec        record;

    faseBilElabId     integer;
	movGestTsRIdRet   integer;
    numeroVincAgg     integer:=0;


	faseBilElabReimpId integer;
    faseBilElabReAccId integer;

    movgestAccCurRiaccId integer;
    movgesttsAccCurRiaccId  integer;

	bCreaVincolo boolean;
    -- tipo periodo annuale
    SY_PER_TIPO       CONSTANT varchar:='SY';
    -- tipo anno ordinario annuale
	BIL_ORD_TIPO      CONSTANT varchar:='BIL_ORD';


	IMP_MOVGEST_TIPO CONSTANT varchar:='I';
    ACC_MOVGEST_TIPO CONSTANT varchar:='A';


    APE_GEST_REIMP     CONSTANT varchar:='APE_GEST_REIMP';
    APE_GEST_REIMP_VINC     CONSTANT varchar:='APE_GEST_REIMP_VINC';


    A_MOV_GEST_STATO  CONSTANT varchar:='A';


BEGIN
    codiceRisultato:=null;
    messaggioRisultato:=null;


	strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';

    strMessaggio:='Verifica esistenza fase elaborazione '||APE_GEST_REIMP_VINC||' IN CORSO.';
    select 1 into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito like 'IN%'
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if codResult is not null then
        strMessaggio :=' Esistenza elaborazione reimputazione vincoli in corso.';
    	raise exception ' Esistenza elaborazione reimputazione vincoli in corso.';
    	return;
    end if;


    strMessaggio:='Inserimento fase elaborazione [fase_bil_t_elaborazione].';
    insert into fase_bil_t_elaborazione
    (fase_bil_elab_esito, fase_bil_elab_esito_msg,
    fase_bil_elab_tipo_id,
    ente_proprietario_id,validita_inizio, login_operazione)
    (select 'IN','ELABORAZIONE REIMPUTAZIONE VINCOLI IN CORSO.',tipo.fase_bil_elab_tipo_id,ente_proprietario_id, dataElaborazione, loginOperazione
    from fase_bil_d_elaborazione_tipo tipo
    where tipo.ente_proprietario_id=enteproprietarioid
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP_VINC
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null)
    returning fase_bil_elab_id into faseBilElabId;

     if faseBilElabId is null then
        strMessaggio  :=' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	raise exception ' Inserimento elaborazione per tipo APE_GEST_REIMP_VINC non effettuato.';
     	return;
    end if;

    codResult:=null;
    strMessaggio:='Inserimento LOG.';
    raise notice 'strMesasggio=%',strMessaggio;
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' - INIZO.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    -- per I
    strMessaggio:='Lettura id identificativo per tipoMovGest='||IMP_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=IMP_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
    if tipoMovGestId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

/* -- SIAC-6997 ---------------- INIZIO --------------------
	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio-1='||(annoBilancio-1)::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioPrecId, periodoPrecId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio-1
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
    if bilancioPrecId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;
*/ -- SIAC-6997 --------------- FINE ------------------------

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per impegni.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

  	codResult:=null;
    select fase.fase_bil_elab_id, fasereimp.bil_id into codResult, bilancioPrecId
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
-- SIAC-6997 --------------- INIZIO ------------------------
--    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
-- SIAC-6997 --------------- FINE ------------------------
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

    if codResult is null then
        strMessaggio :='Elaborazione non effettuabile - Reimputazione impegni non eseguita.';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - ELABORAZIONE REIMPUTAZIONE IMPEGNI NON ESEGUITA.',
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    else faseBilElabReimpId:=codResult;
    end if;


    -- per A
    strMessaggio:='Lettura id identificativo per tipoMovGest='||ACC_MOVGEST_TIPO||'.';
    select tipo.movgest_tipo_id into tipoMovGestAccId
    from siac_d_movgest_tipo tipo
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code=ACC_MOVGEST_TIPO
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null;
	if tipoMovGestAccId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

	codResult:=null;
    strMessaggio:='Verifica elaborazione fase='||APE_GEST_REIMP||' per accertamenti.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    codResult:=null;
    select fase.fase_bil_elab_id into codResult
    from fase_bil_t_elaborazione fase, fase_bil_d_elaborazione_tipo tipo,
         fase_bil_t_reimputazione fasereimp
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.fase_bil_elab_tipo_code=APE_GEST_REIMP
    and   fase.fase_bil_elab_tipo_id=tipo.fase_bil_elab_tipo_id
    and   fase.fase_bil_elab_esito='OK'
    and   fasereimp.fasebilelabid=fase.fase_bil_elab_id
    and   fasereimp.movgest_tipo_id=tipoMovGestAccId
    and   fasereimp.fl_elab is not null and fasereimp.fl_elab='S'
    and   fasereimp.bil_id=bilancioPrecId -- bilancio precedente per elaborazione reimputazione su annoBilancio
    and   fase.data_cancellazione is null
    and   fase.validita_fine is null
    and   tipo.data_cancellazione is null
    and   tipo.validita_fine is null
    order by fase.fase_bil_elab_id desc
    limit 1;

	if codResult is not null then
		 faseBilElabReaccId:=codResult;
    end if;



	strMessaggio:='Lettura bilancioId e periodoId  per annoBilancio='||annoBilancio::varchar||'.';
    select bil.bil_id , per.periodo_id into bilancioId, periodoId
    from siac_t_bil bil, siac_t_periodo per
    where bil.ente_proprietario_id=enteProprietarioId
    and   per.periodo_id=bil.periodo_id
    and   per.anno::INTEGER=annoBilancio
    and   bil.data_cancellazione is null
    and   per.data_cancellazione is null;
	if bilancioId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;

    strMessaggio:='Lettura id identificativo per movGestStatoA='||A_MOV_GEST_STATO||'.';
    select stato.movgest_stato_id into  movGestStatoAId
    from siac_d_movgest_stato stato
    where stato.ente_proprietario_id=enteProprietarioId
    and   stato.movgest_stato_code=A_MOV_GEST_STATO
    and   stato.data_cancellazione is null
    and   stato.validita_fine is null;

	if movGestStatoAId is null then
	    strMessaggio :=strMessaggio||'- Errore in lettura identificativo';
		--- chiusura
        update fase_bil_t_elaborazione fase
        set    fase_bil_elab_esito='KO',
               fase_bil_elab_esito_msg='ELABORAZIONE REIMPUTAZIONE VINCOLI - '||upper(strMessaggio),
               validita_fine=clock_timestamp(),
               data_cancellazione=clock_timestamp()
        where fase.fase_bil_elab_id=faseBilElabId;
        codiceRisultato:=-1;
	    messaggioRisultato:=strMessaggioFinale||strMessaggio;
    	return;
    end if;


    strMessaggio:='Inizio ciclo per elaborazione.';
    codResult:=null;
    insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

     for movGestRec in
     (select  mov.movgest_anno::integer anno_impegno,
              mov.movgest_numero::integer numero_impegno,
              (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subimpegno,
              fasevinc.movgest_ts_b_id,
              fasevinc.movgest_ts_a_id,
              fasevinc.movgest_ts_r_id,
              fasevinc.mod_id,
              fasevinc.importo_vincolo,
              fasevinc.avav_id,
              fasevinc.avav_new_id,
              coalesce(fasevinc.importo_vincolo_new,0) importo_vincolo_new, -- 12.04.2022 Sofia Jira SIAC-8489
              mov.movgest_id,ts.movgest_ts_id,
              fasevinc.reimputazione_vinc_id
	  from siac_t_movgest mov ,
	       siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tipots,
	       siac_r_movgest_ts_stato rs,
	       fase_bil_t_reimputazione fase, fase_bil_t_reimputazione_vincoli fasevinc
	  where mov.bil_id=bilancioId
	  and   mov.movgest_tipo_id=tipoMovGestId
	  and   ts.movgest_id=mov.movgest_id
	  and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   rs.movgest_stato_id!=movGestStatoAId
	  and   fase.fasebilelabid=faseBilElabReImpId
	  and   fase.movgestnew_ts_id=ts.movgest_ts_id
	  and   fase.movgest_tipo_id=mov.movgest_tipo_id
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
      and   fasevinc.fasebilelabid=fase.fasebilelabid
      and   fasevinc.reimputazione_id=fase.reimputazione_id
      and   fasevinc.fl_elab is null -- non elaborato e non scartato
      and   fasevinc.mod_tipo_code=fase.mod_tipo_code -- 09.0.2018 Sofia JIRA SIAC-6054
      and   fasevinc.reimputazione_anno=fase.mtdm_reimputazione_anno::integer -- 09.0.2018 Sofia JIRA SIAC-6054
      and   fasevinc.reimputazione_anno=mov.movgest_anno::integer -- 09.0.2018 Sofia JIRA SIAC-6054
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
      order by mov.movgest_anno::integer ,
               mov.movgest_numero::integer,
               (case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end),
               fasevinc.movgest_ts_b_id,
               coalesce(fasevinc.movgest_ts_a_id,0)
     )
     loop

        codResult:=null;
	    movgestAccCurRiaccId:=null;
	    movgesttsAccCurRiaccId :=null;
	    movGestTsRIdRet:=null;
		bCreaVincolo:=false;

        strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||coalesce(movGestRec.movgest_ts_r_id,0)||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - INIZIO.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

        -- caso 1,2
		if movGestRec.movgest_ts_a_id is null then
            bCreaVincolo:=true;
        end if;

        -- JIRA SIAC-8489 12.04.2022 Sofia
        -- caso REANNO di vincolo verso acceramento che deve essere mantenuto
        if movGestRec.movgest_ts_a_id is NOT null AND  movGestRec.avav_new_id=-1 then
            bCreaVincolo:=true;
        end if;
       
        /* caso 3
  		   se il vincolo abbattuto era legato ad un accertamento
		   che non presenta quote riaccertate esso stesso:
		   creare un vincolo nel nuovo bilancio di tipo FPV per la quote di vincolo abbattuta
		   con tipo spesa corrente o conto capitale in base al titolo di spesa dell'impegno (vedi algoritmo a seguire)
        */
        /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
        -- JIRA SIAC-8489 12.04.2022 Sofia - esclusione caso REANNO vi vincolo verso acceramento che deve essere mantenuto
        if movGestRec.movgest_ts_a_id is not null AND bCreaVincolo=false then       
--        if movGestRec.movgest_ts_a_id is not null then
            codResult:=null;
            strMessaggio:=strMessaggio||' - caso con accertamento verifica esistenza quota riacc.';
            raise notice 'strMessaggio=%',strMessaggio;
        	insert into fase_bil_t_elaborazione_log
	    	(fase_bil_elab_id,fase_bil_elab_log_operazione,
	    	 validita_inizio, login_operazione, ente_proprietario_id
		    )
		    values
	    	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
		    returning fase_bil_elab_log_id into codResult;

		    if codResult is null then
    		 	raise exception ' Errore in inserimento LOG.';
	    	end if;

        	with
             accPrec as
             (
        	  select mov.movgest_anno::integer anno_accertamento,
              mov.movgest_numero::integer numero_accertamento,
              (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
              mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs
              where mov.bil_id=bilancioPrecId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   ts.movgest_ts_id=movGestRec.movgest_ts_a_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             ),
             accCurRiacc as
             (
              select mov.movgest_anno::integer anno_accertamento,
	                 mov.movgest_numero::integer numero_accertamento,
       			    (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
	                mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase
              where mov.bil_id=bilancioId
              and   mov.movgest_tipo_id=tipoMovGestAccId
              and   ts.movgest_id=mov.movgest_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=movGestStatoAId
              and   fase.fasebilelabid=faseBilElabReAccId
              and   fase.fl_elab is not null and fase.fl_elab!=''
	    	  and   fase.fl_elab='S'
              and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
              and   mov.movgest_anno::integer<=movGestRec.anno_impegno
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             )
             select  accCurRiacc.movgest_new_id, accCurRiacc.movgest_ts_new_id
                     into movgestAccCurRiaccId, movgesttsAccCurRiaccId
             from accPrec, accCurRiacc
             where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
             limit 1;


			 if movgestAccCurRiaccId is null or movgesttsAccCurRiaccId is null then
             	-- caso 3
                bCreaVincolo:=true;

             else
   	            codResult:=null;
	            strMessaggio:=strMessaggio||' - caso con accertamento e quota riacc.';
                            raise notice 'strMessaggio=%',strMessaggio;

    	    	insert into fase_bil_t_elaborazione_log
		    	(fase_bil_elab_id,fase_bil_elab_log_operazione,
		    	 validita_inizio, login_operazione, ente_proprietario_id
			    )
		    	values
		    	(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
			    returning fase_bil_elab_log_id into codResult;

			    if codResult is null then
    			 	raise exception ' Errore in inserimento LOG.';
		    	end if;


                -- caso 4
                -- inserire nuovi vincoli con algoritmo descritto in JIRA per il caso 4
                --- vedere algoritmo
                /* caso 4
		 se il vincolo abbattuto era legato ad un accertamento che presenta quote riaccertate:
		 creare un vincolo nel nuovo bilancio per la parte di vincolo abbattuta a capienza dell'utilizzabile
		 (utilizzabile - somma altri vincoli) del ogni nuovo acc. riaccertato con anno_accertamento<=anno_impegno
		 Per la restante parte creare un vincolo di tipo FPV con tipo spesa corrente o conto capitale in base al titolo di
		 spesa dell'impegno (vedi algoritmo a seguire) */
               select * into resultRec
               from  fnc_fasi_bil_gest_reimputa_vincoli_acc
               (
				  enteProprietarioId,
				  annoBilancio,
				  faseBilElabId,
				  movGestRec.anno_impegno,        -- annoImpegnoRiacc integer,   -- annoImpegno riaccertato
				  movGestRec.movgest_ts_id,       -- movgestTsImpNewId integer,  -- movgest_id_id impegno riaccertato
				  movGestRec.avav_new_id,         -- avavRiaccImpId   integer,        -- avav_id nuovo
				  movGestRec.importo_vincolo_new, -- importoVincoloRiaccertato numeric, -- importo totale vincolo impegno riaccertato
				  faseBilElabReAccId,             -- faseId di elaborazione riaccertmaento Acc
				  tipoMovGestAccId,               -- tipoMovGestId Accertamenti
				  movGestRec.movgest_ts_a_id,     -- movgestTsAccPrecId integer, -- movgest_ts_id accertamento anno precedente vincolato a impegno riaccertato
				  loginOperazione,
				  dataElaborazione
                );
                if resultRec.codiceRisultato=0 then
                	numeroVincAgg:=numeroVincAgg+resultRec.numeroVincoliCreati;

                    strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                	update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='S',
    	                   movgest_ts_b_new_id=movGestRec.movgest_ts_id,
    --    	               movgest_ts_r_new_id=movGestTsRIdRet, non impostato poiche multiplo verso diversi accertamenti pluri
            	       	   bil_new_id=bilancioId
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                else
                	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            		update fase_bil_t_reimputazione_vincoli fase
	                set    fl_elab='X',
			               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
        	        	   bil_new_id=bilancioId,
	        	           scarto_code='99',
                	       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
	            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
                end if;
	         end if;

        end if;


	   if bCreaVincolo=true then
	    -- 12.04.2022 Sofia Jira SIAC-8489
	   	if  movGestRec.avav_new_id is not null and movGestRec.avav_new_id<>-1 then 
			codResult:=null;
			strMessaggio:=strMessaggio||' - inserimento vincolo senza accertamento vincolato.';
			insert into fase_bil_t_elaborazione_log
			(fase_bil_elab_id,fase_bil_elab_log_operazione,
			 validita_inizio, login_operazione, ente_proprietario_id
			)
			values
			(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
			returning fase_bil_elab_log_id into codResult;
			
			if codResult is null then
			 	raise exception ' Errore in inserimento LOG.';
			end if;
			
			movGestTsRIdRet:=null;
			-- 17.06.2020 Sofia SIAC-7593
			update  siac_r_movgest_ts r
			set     movgest_ts_importo=r.movgest_ts_importo+movGestRec.importo_vincolo_new,
			        data_modifica=clock_timestamp()
			where r.movgest_ts_b_id=movGestRec.movgest_ts_id
			and   r.avav_id=movGestRec.avav_new_id
			and   r.data_cancellazione is null
			and   r.validita_fine is null
			returning r.movgest_ts_r_id into movGestTsRIdRet;
			
			
			-- 17.06.2020 Sofia SIAC-7593
			if movGestTsRIdRet is null and movGestRec.importo_vincolo_new !=0 then -- 12.04.2022 Sofia Jira SIAC-8489
			
			-- inserimento siac_t_movgest_ts_r nuovo con i dati presenti in fase_bil_t_reimputazione_vincoli
			-- aggiornamento di fase_bil_t_reimputazione_vincoli
			    insert into siac_r_movgest_ts
			    (
			        movgest_ts_b_id,
				    movgest_ts_importo,
			        avav_id,
			        validita_inizio,
			        login_operazione,
			        ente_proprietario_id
			    )
			    values
			    (
			    	movGestRec.movgest_ts_id,
			        movGestRec.importo_vincolo_new,
			        movGestRec.avav_new_id,
			        clock_timestamp(),
			        loginOperazione,
			        enteProprietarioId
			    )
			    returning movgest_ts_r_id into movGestTsRIdRet;
			  end if;

	      
	      else 
	         if movGestRec.avav_new_id is not null and movGestRec.avav_new_id=-1 then 
	         	codResult:=null;
				strMessaggio:=strMessaggio||' - inserimento vincolo con accertamento vincolato - no reimp.';
				insert into fase_bil_t_elaborazione_log
				(fase_bil_elab_id,fase_bil_elab_log_operazione,
				 validita_inizio, login_operazione, ente_proprietario_id
				)
				values
				(faseBilElabId,strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
				returning fase_bil_elab_log_id into codResult;
			
				if codResult is null then
				 	raise exception ' Errore in inserimento LOG.';
				end if;
			
				movGestTsRIdRet:=null;
				update  siac_r_movgest_ts r
				set     movgest_ts_importo=r.movgest_ts_importo+movGestRec.importo_vincolo_new,
				        data_modifica=clock_timestamp()
				where r.movgest_ts_b_id=movGestRec.movgest_ts_id
				and   r.movgest_ts_a_id=movGestRec.movgest_ts_a_id
				and   r.data_cancellazione is null
				and   r.validita_fine is null
				returning r.movgest_ts_r_id into movGestTsRIdRet;
				
				if movGestTsRIdRet is null and movGestRec.importo_vincolo_new!=0 then
			
				-- inserimento siac_t_movgest_ts_r nuovo con i dati presenti in fase_bil_t_reimputazione_vincoli
				-- aggiornamento di fase_bil_t_reimputazione_vincoli
			    insert into siac_r_movgest_ts
			    (
			        movgest_ts_b_id,
			        movgest_ts_a_id,			        
				    movgest_ts_importo,
			        validita_inizio,
			        login_operazione,
			        ente_proprietario_id
			    )
			    values
			    (
			    	movGestRec.movgest_ts_id,
			    	movGestRec.movgest_ts_a_id,
			        movGestRec.importo_vincolo_new,
			        clock_timestamp(),
			        loginOperazione,
			        enteProprietarioId
			    )
			    returning movgest_ts_r_id into movGestTsRIdRet;
			   end if;
			  
	        end if;
	       
	      end if;
	      
          if movGestTsRIdRet is null then
            	strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli per scarto in fase di reimputazione nuovo vincolo.';
            	update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='X',
		               movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                	   bil_new_id=bilancioId,
	                   scarto_code='99',
                       scarto_desc='VINCOLO NUOVO NON CREATO IN FASE DI REIMPUTAZIONE'
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;

            else
            	numeroVincAgg:=numeroVincAgg+1;
                strMessaggio:='Aggiornamento fase_bil_t_reimputazione_vincoli in fase di reimputazione nuovo vincolo.';
                update fase_bil_t_reimputazione_vincoli fase
                set    fl_elab='S',
                       movgest_ts_b_new_id=movGestRec.movgest_ts_id,
                       movgest_ts_r_new_id=movGestTsRIdRet,
                   	   bil_new_id=bilancioId
            	where fase.reimputazione_vinc_id=movGestRec.reimputazione_vinc_id;
           end if;
       end if;



       strMessaggio:='Impegno anno='||movGestRec.anno_impegno||
                      ' numero='||movGestRec.numero_impegno||
                      ' subnumero='||movGestRec.numero_subimpegno||
                      ' movgest_ts_new_id='||movGestRec.movgest_ts_id||
                      ' movgest_ts_id='||movGestRec.movgest_ts_b_id||
                      ' movgest_ts_r_id='||coalesce(movGestRec.movgest_ts_r_id,0)||
                      ' movgest_ts_a_id='||coalesce(movGestRec.movgest_ts_a_id,0)||'.';

        raise notice 'strMessaggio=%  movGestRec.movgest_new_id=%', strMessaggio, movGestRec.movgest_ts_id;
		insert into fase_bil_t_elaborazione_log
	    (fase_bil_elab_id,fase_bil_elab_log_operazione,
    	 validita_inizio, login_operazione, ente_proprietario_id
	    )
	    values
    	(faseBilElabId,strMessaggio||' - FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
	    returning fase_bil_elab_log_id into codResult;

	    if codResult is null then
    	 	raise exception ' Errore in inserimento LOG.';
	    end if;

     end loop;

    -- 23.06.2020 Sofia jira SIAC-SIAC-7663 - inizio
    codResult:=null;
    strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';
    strMessaggio:=' Inserimento SIAC_R_MOVGEST_TS_STORICO_IMP_ACC.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||strMessaggio,clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

    insert into SIAC_R_MOVGEST_TS_STORICO_IMP_ACC
    (
        movgest_ts_id,
        movgest_anno_acc,
        movgest_numero_acc,
        movgest_subnumero_acc,
        validita_inizio,
        login_operazione,
        ente_proprietario_id
    )
    select query.movgestnew_ts_id,
           query.movgest_anno_acc,
           query.movgest_numero_acc,
           query.movgest_subnumero_acc,
           clock_timestamp(),
           loginOperazione,
           enteProprietarioId
    FROM
    (
    with
    impegni_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           ts.movgest_ts_id movgestnew_ts_id, fase.movgest_ts_id
    from siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         fase_bil_t_reimputazione fase,siac_t_movgest mov
    where fase.fasebilelabid=faseBilElabReimpId
    and   fase.movgestnew_ts_id is not null
    and   fase.fl_elab='S'
    and   ts.movgest_ts_id=fase.movgestnew_ts_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   tipots.movgest_ts_tipo_code='T'
    and   mov.movgest_id=ts.movgest_id
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    ),
    impegni_prec as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           mov_a.movgest_anno::integer movgest_anno_acc, mov_a.movgest_numero::integer movgest_numero_acc,
           ( case when tipots_a.movgest_ts_tipo_code='T' then 0 else ts_a.movgest_ts_code::integer end ) movgest_subnumero_acc,
           ts.movgest_ts_id movgest_ts_b_id,
           ts_a.movgest_ts_id movgest_ts_a_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r,
         siac_t_movgest mov_a,siac_d_movgest_tipo tipo_a,siac_t_movgest_Ts ts_a,siac_d_movgest_ts_tipo tipots_a,
         siac_r_movgest_ts_stato rs_a,siac_d_movgest_stato stato_a,
         fase_bil_t_reimputazione fase
    where fase.fasebilelabid=faseBilElabReimpId
    and   fase.movgestnew_ts_id is not null
    and   fase.fl_elab='S'
    and   ts.movgest_ts_id=fase.movgest_ts_id
    and   tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='I'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioPrecId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_b_id=ts.movgest_ts_id
    and   ts_a.movgest_ts_id=r.movgest_ts_a_id
    and   mov_a.movgest_id=ts_a.movgest_id
    and   tipots_a.movgest_ts_tipo_id=ts_a.movgest_ts_tipo_id
    and   tipo_a.movgest_tipo_id=mov_a.movgest_tipo_id
    and   tipo_a.movgest_tipo_code='A'
    and   mov_a.bil_id=bilancioPrecId
    and   rs_a.movgest_ts_id=ts_a.movgest_ts_id
    and   stato_a.movgest_stato_id=rs_a.movgest_stato_id
    and   stato_a.movgest_stato_code!='A'
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    and   rs_a.data_cancellazione is null
    and   rs_a.validita_fine is null
    and   mov_a.data_cancellazione is null
    and   mov_a.validita_fine is null
    and   ts_a.data_cancellazione is null
    and   ts_a.validita_fine is null
    ),
    acc_cur as
    (
    select mov.movgest_anno::integer, mov.movgest_numero::integer,
           ( case when tipots.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end ) movgest_subnumero,
           r.movgest_ts_a_id,
           r.movgest_ts_b_id
    from siac_t_movgest mov,siac_d_movgest_tipo tipo,siac_t_movgest_Ts ts,siac_d_movgest_ts_tipo tipots,
         siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato,
         siac_r_movgest_ts r
    where tipo.ente_proprietario_id=enteProprietarioId
    and   tipo.movgest_tipo_code='A'
    and   mov.movgest_tipo_id=tipo.movgest_tipo_id
    and   mov.bil_id=bilancioId
    and   ts.movgest_id=mov.movgest_id
    and   tipots.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
    and   rs.movgest_ts_id=ts.movgest_ts_id
    and   stato.movgest_stato_id=rs.movgest_stato_id
    and   stato.movgest_stato_code!='A'
    and   r.movgest_ts_a_id=ts.movgest_ts_id
    and   r.movgest_ts_b_id is not null
    and   rs.data_cancellazione is null
    and   rs.validita_fine is null
    and   mov.data_cancellazione is null
    and   mov.validita_fine is null
    and   ts.data_cancellazione is null
    and   ts.validita_fine is null
    and   r.data_cancellazione is null
    and   r.validita_fine is null
    )
    select distinct
           impegni_cur.movgestnew_ts_id,
           impegni_prec.movgest_anno_acc,
           impegni_prec.movgest_numero_acc,
           impegni_prec.movgest_subnumero_acc
    from impegni_cur, impegni_prec
    where impegni_cur.movgest_ts_id=impegni_prec.movgest_ts_b_id
    and   not exists
    (select 1
     from acc_cur
     where acc_cur.movgest_ts_b_id=impegni_cur.movgestnew_ts_id
     and   acc_cur.movgest_anno=impegni_prec.movgest_anno_acc
     and   acc_cur.movgest_numero=impegni_prec.movgest_numero_acc
     and   acc_cur.movgest_subnumero=impegni_prec.movgest_subnumero_acc )
     ) query
     where
     not exists
     (select 1
      from SIAC_R_MOVGEST_TS_STORICO_IMP_ACC rStorico
      where rStorico.ente_proprietario_id=enteProprietarioId
      and   rStorico.movgest_ts_id=query.movgestnew_ts_id
      and   rStorico.movgest_anno_acc=query.movgest_anno_acc
      and   rStorico.movgest_numero_acc=query.movgest_numero_acc
      and   rStorico.movgest_subnumero_acc=query.movgest_subnumero_acc
      and   rStorico.data_cancellazione is null
      and   rStorico.validita_fine is null);
    codResult:=null;
    GET DIAGNOSTICS codResult = ROW_COUNT;
    raise notice '% codResult=%',strMessaggio, codResult;
    -- 23.06.2020 Sofia jira SIAC-SIAC-7663 - fine

-- SIAC-6997 ---------------- INIZIO --------------------

    strMessaggioFinale:='Apertura bilancio gestione.Reimputazione vincoli. Anno bilancio='||annoBilancio::varchar||'.';
	insert into fase_bil_t_elaborazione_log
    (fase_bil_elab_id,fase_bil_elab_log_operazione,
     validita_inizio, login_operazione, ente_proprietario_id
    )
    values
    (faseBilElabId,strMessaggioFinale||' - FINE.',clock_timestamp(),loginOperazione,enteProprietarioId)
    returning fase_bil_elab_log_id into codResult;

    if codResult is null then
    	raise exception ' Errore in inserimento LOG.';
    end if;

-- SIAC-6997 ---------------- FINE --------------------

     strMessaggio:='Aggiornamento stato fase bilancio OK.';
     update fase_bil_t_elaborazione
     set fase_bil_elab_esito='OK',
         fase_bil_elab_esito_msg='ELABORAZIONE FASE BILANCIO '||APE_GEST_REIMP_VINC||
                                 ' OK. INSERITI NUOVI VINCOLI NUM='||
                                 coalesce(numeroVincAgg,0)||'.'
     where fase_bil_elab_id=faseBilElabId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. impegni.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReimpId;

     strMessaggio:='Aggiornamento fase_bil_elab_coll_id su elaborazione riacc. accertamenti.';
	 update fase_bil_t_elaborazione fase
     set    fase_bil_elab_coll_id=faseBilElabId,
            data_modifica=now()
     where fase.fase_bil_elab_id=faseBilElabReAccId;


     codiceRisultato:=0;
     messaggioRisultato:=strMessaggioFinale||' FINE';
     return;

exception
    when RAISE_EXCEPTION THEN
    	raise notice '% % ERRORE : %',strMessaggioFinale,coalesce(strMessaggio,''),
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'ERRORE :'||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

	when no_data_found THEN
		raise notice ' % % Nessun elemento trovato.' ,strMessaggioFinale,coalesce(strMessaggio,'');
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Nessun elemento trovato.' ;
        codiceRisultato:=-1;
		return;
	when others  THEN
		raise notice '% % Errore DB % %',strMessaggioFinale,coalesce(strMessaggio,''),SQLSTATE,
	        	substring(upper(SQLERRM) from 1 for 500);
        messaggioRisultato:=strMessaggioFinale||coalesce(strMessaggio,'')||'Errore DB '||SQLSTATE||' '||substring(upper(SQLERRM) from 1 for 500) ;
        codiceRisultato:=-1;
        return;

END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;

ALTER FUNCTION siac.fnc_fasi_bil_gest_reimputa_popola 
(
  integer,
  integer,
  integer,
  varchar,
  timestamp,
  varchar,
  varchar,
  integer,
  integer,
  integer,
  out integer,
  out integer,
  out varchar
) OWNER TO siac;

ALTER FUNCTION siac.fnc_fasi_bil_gest_reimputa_vincoli 
(
  integer,
  integer,
  varchar,
  timestamp,
  out integer,
  out varchar
) OWNER TO siac;


-- SIAC-8489 - Sofia  - fine 

