/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace view siac_v_bko_gestione_ente as
select 
d.ente_proprietario_id,d.ente_denominazione, a.gestione_tipo_code,a.gestione_tipo_desc, b.gestione_livello_code,b.gestione_livello_desc
 from siac_d_gestione_tipo a, siac_d_gestione_livello b, siac_r_gestione_ente c, siac_t_ente_proprietario d
where a.gestione_tipo_id=b.gestione_tipo_id
and c.gestione_livello_id=b.gestione_livello_id
and c.ente_proprietario_id=d.ente_proprietario_id
order by 1,3,5