/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/



/*
Sezioni:
- conto tesoreria
- ordinativo
- tabella saldo iniziale 
- livello sull'ente

*/

/*
	
                                                                                               
  ####   ####  #    # #####  ####     ##### ######  ####   ####  #####  ###### #####  #   ##   
 #    # #    # ##   #   #   #    #      #   #      #      #    # #    # #      #    # #  #  #  
 #      #    # # #  #   #   #    #      #   #####   ####  #    # #    # #####  #    # # #    # 
 #      #    # #  # #   #   #    #      #   #           # #    # #####  #      #####  # ###### 
 #    # #    # #   ##   #   #    #      #   #      #    # #    # #   #  #      #   #  # #    # 
  ####   ####  #    #   #    ####       #   ######  ####   ####  #    # ###### #    # # #    # 
                                                                                               

*/
select * from fnc_dba_add_column_params('siac_d_contotesoreria'::text, 'vincolato'::text, 'boolean'::text);
select * from fnc_dba_add_column_params('siac_d_contotesoreria'::text, 'per_ripianamento'::text, 'boolean'::text);

/*

                                                            
  ####  #####  #####  # #    #   ##   ##### # #    #  ####  
 #    # #    # #    # # ##   #  #  #    #   # #    # #    # 
 #    # #    # #    # # # #  # #    #   #   # #    # #    # 
 #    # #####  #    # # #  # # ######   #   # #    # #    # 
 #    # #   #  #    # # #   ## #    #   #   #  #  #  #    # 
  ####  #    # #####  # #    # #    #   #   #   ##    ####  
                                                            

*/

/*ALTERNATIVE: 2 TABELLA*/
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

/*

                                                                                
  ####    ##   #      #####   ####     # #    # # ###### #   ##   #      ###### 
 #       #  #  #      #    # #    #    # ##   # #     #  #  #  #  #      #      
  ####  #    # #      #    # #    #    # # #  # #    #   # #    # #      #####  
      # ###### #      #    # #    #    # #  # # #   #    # ###### #      #      
 #    # #    # #      #    # #    #    # #   ## #  #     # #    # #      #      
  ####  #    # ###### #####   ####     # #    # # ###### # #    # ###### ###### 
                                                                                

*/


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


/*

                                                                           
 #      # #    # ###### #      #       ####     ###### #    # ##### ###### 
 #      # #    # #      #      #      #    #    #      ##   #   #   #      
 #      # #    # #####  #      #      #    #    #####  # #  #   #   #####  
 #      # #    # #      #      #      #    #    #      #  # #   #   #      
 #      #  #  #  #      #      #      #    #    #      #   ##   #   #      
 ###### #   ##   ###### ###### ######  ####     ###### #    #   #   ###### 
                                                                           

*/
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
