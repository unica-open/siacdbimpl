/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- 22.10.2018 Sofia siac-6336

-- siac_dwh_impegno
-- stato_programma
-- versione_cronop
-- desc_cronop
-- anno_cronop

alter table siac_dwh_impegno
      add stato_programma varchar(200),
      add versione_cronop varchar(200),
      add desc_cronop varchar(500),
      add anno_cronop varchar(4);

-- siac_dwh_accertamento
-- stato_programma
-- versione_cronop
-- desc_cronop
-- anno_cronop
alter table siac_dwh_accertamento
      add stato_programma varchar(200),
      add versione_cronop varchar(200),
      add desc_cronop varchar(500),
      add anno_cronop varchar(4);  