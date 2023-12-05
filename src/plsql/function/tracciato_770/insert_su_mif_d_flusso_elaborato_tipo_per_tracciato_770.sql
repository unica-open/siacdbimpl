/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
INSERT INTO MIF_D_FLUSSO_ELABORATO_TIPO (
                        flusso_elab_mif_tipo_code,
                        flusso_elab_mif_tipo_desc,
                        flusso_elab_mif_nome_file,
                        validita_inizio,
                        validita_fine,
                        data_creazione,
                        data_modifica,
                        data_cancellazione,
                        ente_proprietario_id,
                        login_operazione,
                        flusso_elab_mif_tipo_dec) 
select 'MOD770',
       'Tracciato Modello 770',
       'MOD770',
       to_date('01/01/2016','dd/mm/yyyy'),
       null, 
       now(),
       now(),
       null,
       a.ente_proprietario_id,
       'SCAI',
       'FALSE'
from siac_t_ente_proprietario a;