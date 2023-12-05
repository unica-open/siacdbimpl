/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
alter table migr_atto_allegato add numero_titolario varchar(500);
alter table migr_atto_allegato add anno_titolario varchar(4);
alter table migr_atto_allegato add versione integer;
alter table migr_atto_allegato add numero_provvedimento_calcolato varchar(20);
alter table migr_atto_allegato add data_completamento varchar(10);
alter table migr_atto_allegato add settore varchar(50);

alter table migr_doc_spesa add collegato_cec varchar(1);
ALTER TABLE migr_doc_spesa alter numero type varchar(50);
alter table migr_doc_spesa add sede_id integer;
alter table migr_doc_spesa add anno_registro_fatt varchar(4);
alter table migr_doc_spesa add anno_repertorio varchar(4);
--9.12.2015
alter table migr_doc_spesa alter DATA_SCANDENZA_NEW type varchar(19);
alter table migr_doc_spesa alter data_ricezione type varchar(19);
alter table migr_doc_spesa alter data_repertorio type varchar(19);
alter table migr_doc_spesa alter data_sospensione type varchar(19);
alter table migr_doc_spesa alter data_riattivazione type varchar(19);



alter table migr_doc_entrata add anno_registro_fatt varchar(4);
alter table migr_doc_entrata add anno_repertorio varchar(4);
--09.12.2015
alter table migr_doc_entrata alter data_repertorio type varchar(19);

ALTER TABLE migr_docquo_spesa alter numero type varchar(50);
alter table migr_docquo_spesa add sede_id integer;
alter table migr_docquo_spesa add importo_splitreverse	NUMERIC;
alter table migr_docquo_spesa add tipo_iva_splitreverse	varchar(10);
alter table migr_docquo_spesa add data_pagamento_cec	varchar(10);
ALTER TABLE migr_docquo_spesa ALTER COLUMN importo_splitreverse DROP DEFAULT;
ALTER TABLE migr_docquo_spesa ALTER COLUMN importo_splitreverse DROP NOT NULL;
--09.12.2015
alter table migr_docquo_spesa alter data_scadenza_new type varchar(19);
alter table migr_docquo_spesa alter data_riattivazione type varchar(19);
alter table migr_docquo_spesa alter data_sospensione type varchar(19);
alter table migr_docquo_spesa alter data_certif_crediti type varchar(19);
--29.12.2015
alter table migr_docquo_spesa alter COLUMN flag_manuale DROP NOT NULL;
alter table migr_docquo_spesa alter COLUMN flag_manuale DROP DEFAULT;

--29.12.2015
alter table migr_docquo_entrata alter COLUMN flag_manuale DROP NOT NULL;
alter table migr_docquo_entrata alter COLUMN flag_manuale DROP DEFAULT;

--27.05.2016
alter table migr_doc_spesa alter numero_repertorio type NUMERIC;
alter table migr_docquo_spesa_iva alter sezionale type varchar(5);

--- 01.06.2016
ALTER TABLE migr_doc_spesa
  ALTER COLUMN numero_repertorio DROP NOT NULL;
  
-- 05.12.2016
alter table migr_docquo_spesa add codice_pcc     varchar(10);
alter table migr_docquo_spesa add codice_ufficio varchar(10);

-- 03.01.2017
alter table migr_atto_allegato add attoal_flag_ritenute CHAR(1) DEFAULT 'N' NOT NULL;
