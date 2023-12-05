/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
-- SIAC-4961 INIZIO

update siac_d_gestione_livello liv
set    gestione_livello_desc='CB'
where liv.ente_proprietario_id=2
and   liv.gestione_livello_code='ACCREDITO_CONTO_BANCA';

update siac_d_gestione_livello liv
set    gestione_livello_desc='CT'
where liv.ente_proprietario_id=2
and   liv.gestione_livello_code='ACCREDITO_CONTANTI';

-- SIAC-4961 FINE