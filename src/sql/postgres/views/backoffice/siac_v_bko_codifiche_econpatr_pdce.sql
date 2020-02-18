/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create view siac_v_bko_codifiche_econpatr_pdce
as
select 
c.ente_proprietario_id, c.ambito_id,
c.pdce_conto_code, c.ordine,
c.pdce_conto_desc, c.livello,
a.codice_codifica,a.descrizione_codifica,
a.codice_codifica_albero,a.tipo_codifica,a.livello_codifica from 
siac_v_dwh_codifiche_econpatr a, siac_r_pdce_conto_class b,siac_t_pdce_conto c
where b.classif_id=a.classif_id
and c.pdce_conto_id=b.pdce_conto_id
order by 1,2,4,9