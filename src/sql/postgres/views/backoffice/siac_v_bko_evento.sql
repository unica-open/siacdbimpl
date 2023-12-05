/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
drop VIEW siac.siac_v_bko_evento;

CREATE OR REPLACE VIEW siac.siac_v_bko_evento as
 SELECT DISTINCT 
         c.collegamento_tipo_code,
         c.collegamento_tipo_desc,
         b.evento_tipo_code,
         b.evento_tipo_desc,
         a.evento_code,
         a.evento_desc,
         case when c.collegamento_tipo_code='A' then 'siac_t_movgest.movgest_id'  
         when c.collegamento_tipo_code='I' then 'siac_t_movgest.movgest_id'  
         when c.collegamento_tipo_code='SA' then 'siac_t_movgest_ts.movgest_ts_id'  
         when c.collegamento_tipo_code='SI' then 'siac_t_movgest_ts.movgest_ts_id'  
         when c.collegamento_tipo_code='L' then 'siac_t_liquidazione.liq_id'
         when c.collegamento_tipo_code='MMGE' then 'siac_t_modifica.mod_id'    
         when c.collegamento_tipo_code='MMGS' then 'siac_t_modifica.mod_id'    
         when c.collegamento_tipo_code='OI' then 'siac_t_ordinativo.ord_id'         
         when c.collegamento_tipo_code='OP' then 'siac_t_ordinativo.ord_id'                  
         when c.collegamento_tipo_code='SS' then 'siac_t_subdoc.subdoc_id'          
         when c.collegamento_tipo_code='SE' then 'siac_t_subdoc.subdoc_id'     
         when c.collegamento_tipo_code='RE' then 'siac_t_richiesta_econ.ricecon_id'  
         when c.collegamento_tipo_code='RR' then 'siac_t_giustificativo.gst_id'          
         else null end   tabella_campo
  FROM siac_d_evento a,
       siac_d_evento_tipo b,
       siac_d_collegamento_tipo c
  WHERE a.evento_tipo_id = b.evento_tipo_id AND
        a.collegamento_tipo_id = c.collegamento_tipo_id
  ORDER BY 
           c.collegamento_tipo_code,
           b.evento_tipo_code,
           a.evento_code;