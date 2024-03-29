/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
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