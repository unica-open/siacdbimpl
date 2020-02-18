/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
--alter table migr_impegno drop column visto_ragioneria;
alter table migr_impegno add parere_finanziario number(1) default 0;
alter table migr_accertamento add parere_finanziario number(1) default 0;



-- 15.04.2016 Sofia - x reimputazione impegni-accertamenti
alter table migr_impegno_Scarto add fl_migrato varchar2(1) default 'N' not null
alter table migr_accertamento_Scarto add fl_migrato varchar2(1) default 'N' not null
