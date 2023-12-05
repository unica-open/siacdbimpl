/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace view  siac_v_bko_pdce_conto as  
select a.ente_proprietario_id,
d.pdce_fam_code,
d.pdce_fam_desc,
b.pdce_ct_tipo_code,
b.pdce_ct_tipo_desc,
a.pdce_conto_code,
a.pdce_conto_desc,
a.pdce_conto_id_padre,
a.pdce_conto_a_partita,
a.livello,
a.ordine,
a.cescat_id,
a.validita_inizio,
a.validita_fine,
a.data_creazione,
a.data_modifica,
a.data_cancellazione,
a.login_operazione,
a.login_creazione,
a.login_modifica,
a.login_cancellazione
 from siac_t_pdce_conto a, siac_d_pdce_conto_tipo b,siac_t_pdce_fam_tree c, siac_d_pdce_fam d
where a.pdce_ct_tipo_id=b.pdce_ct_tipo_id
and c.pdce_fam_tree_id=a.pdce_fam_tree_id
and d.pdce_fam_id=c.pdce_fam_id
order by a.ente_proprietario_id,d.pdce_fam_code,a.ordine;