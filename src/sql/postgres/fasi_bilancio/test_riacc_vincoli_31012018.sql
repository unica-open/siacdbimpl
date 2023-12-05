/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
﻿
-- 2017/1439778 FPVSC
-- 2017/1567737 FPVCC
-- 2017/1628451 AMM
-- 2017/1559369 accertamento 2017/1566130
-- 2017 1632588 acc  2017/1631022


select av.*
from siac_t_avanzovincolo av
where av.ente_proprietario_id=3

select *
from siac_d_avanzovincolo_tipo tipo
where tipo.ente_proprietario_id=3

select
					   bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code tipo
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo impoInizImpegno
					  ,detts.movgest_ts_det_importo     impoAttImpegno
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
					  ,sum(dettsmod.movgest_ts_det_importo)  importoModifica
				from siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato
				where bil.ente_proprietario_id=3
				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
				and   per.anno::integer=2018-1
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id =  modificaTipo.mod_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code='I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code='A'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
               group by
			bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id

					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo
					  ,detts.movgest_ts_det_importo
					  --,dettsmod.movgest_ts_det_importo  importoModifica
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
				order by
				 		 dettsmod.mtdm_reimputazione_anno::integer
				 		,modificaTipo.mod_tipo_code
				 		--,tsmov.movgest_ts_code::integer    ?? serve????
						,movgest.movgest_anno::integer
                        ,movgest.movgest_numero::integer
                        ,tipo desc




select
					rts.movgest_ts_a_id,
                  rts.avav_id
					   --siac_t_bil_elem
					   ,bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code tipo
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo impoInizImpegno
					  ,detts.movgest_ts_det_importo     impoAttImpegno
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
					  ,sum(dettsmod.movgest_ts_det_importo)  importoModifica
				from siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato, -- 07.02.2018 Sofia siac-5368,
                     siac_r_modifica_vincolo rvinc,
				     siac_r_movgest_ts rts
				where bil.ente_proprietario_id=3
				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
				and   per.anno::integer=2018-1
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id =  modificaTipo.mod_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code='I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code='A'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
               and   rvinc.mod_id=modifica.mod_id
                and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
				and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        		and   rts.movgest_ts_b_id=tsmov.movgest_ts_id
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
               group by
rts.movgest_ts_a_id,
                    rts.avav_id
                      ,bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id

					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo
					  ,detts.movgest_ts_det_importo
					  --,dettsmod.movgest_ts_det_importo  importoModifica
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
				order by
				 		 dettsmod.mtdm_reimputazione_anno::integer
				 		,modificaTipo.mod_tipo_code
				 		--,tsmov.movgest_ts_code::integer    ?? serve????
						,movgest.movgest_anno::integer
                        ,movgest.movgest_numero::integer
                        ,tipo desc



select
					rts.movgest_ts_a_id,
                    mova.movgest_anno, mova.movgest_numero,
                    rts.avav_id
					   --siac_t_bil_elem
					   ,bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id
					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code tipo
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo impoInizImpegno
					  ,detts.movgest_ts_det_importo     impoAttImpegno
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
					  ,sum(dettsmod.movgest_ts_det_importo)  importoModifica
				from siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato, -- 07.02.2018 Sofia siac-5368,
                     siac_r_modifica_vincolo rvinc,
				     siac_r_movgest_ts rts,
                     siac_t_movgest_ts tsa, siac_t_movgest mova
				where bil.ente_proprietario_id=3

				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
				and   per.anno::integer=2018-1
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id =  modificaTipo.mod_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code='I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code='I'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
                and   rvinc.mod_id=modifica.mod_id
                and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
				and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        		and   rts.movgest_ts_b_id=tsmov.movgest_ts_id
                and   tsa.movgest_ts_id=   rts.movgest_ts_a_id
                and   mova.movgest_id=tsa.movgest_id
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
                and   tsa.data_cancellazione is null
                and   tsa.validita_fine is null
                and   mova.data_cancellazione is null
                and   mova.validita_fine is null

                group by
rts.movgest_ts_a_id,
mova.movgest_anno, mova.movgest_numero,
                    rts.avav_id
				      , bilel.bil_id
					  ,bilel.elem_id
					  ,bilel.elem_code
					  ,bilel.elem_code2
					  ,bilel.elem_code3
					  -- siac_t_movgest
					  ,movgest.movgest_id
					  ,movgest.movgest_anno
					  ,movgest.movgest_numero
					  ,movgest.movgest_desc
					  ,movgest.movgest_tipo_id
					  ,movgest.parere_finanziario
					  ,movgest.parere_finanziario_data_modifica
					  ,movgest.parere_finanziario_login_operazione
					  -- siac_t_movgest_ts
					  ,tsmov.movgest_ts_id --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_code --tsmov.movgest_ts_code::integer numero_subimpegno -- se tipo='S' numero_subimpegno
					  ,tsmov.movgest_ts_desc
					  ,tsmov.movgest_ts_tipo_id
					  ,tsmov.movgest_ts_id_padre
					  ,tsmov.ordine
					  ,tsmov.livello
					  ,tsmov.login_operazione
					  ,tsmov.movgest_ts_scadenza_data
					  ,tsmov.siope_tipo_debito_id
					  ,tsmov.siope_assenza_motivazione_id

					  --siac_t_movgest_ts_dett
					  ,tipots.movgest_ts_tipo_code
					  ,tipodet.movgest_ts_det_tipo_code
                      ,modificaTipo.mod_tipo_code
					  ,dettsIniz.movgest_ts_det_tipo_id
					  ,dettsIniz.movgest_ts_det_importo
					  ,detts.movgest_ts_det_importo
					  --,dettsmod.movgest_ts_det_importo  importoModifica
					  ,dettsmod.mtdm_reimputazione_anno::integer
					  ,dettsmod.mtdm_reimputazione_flag
					  ,dbileltip.elem_tipo_code
                      ,rstato.movgest_stato_id -- 07.02.2018 Sofia siac-5368
				order by
				 		 dettsmod.mtdm_reimputazione_anno::integer
				 		,modificaTipo.mod_tipo_code
				 		--,tsmov.movgest_ts_code::integer    ?? serve????
						,movgest.movgest_anno::integer
                        ,movgest.movgest_numero::integer
                        ,tipo desc

------------ esecuzione

rollback;
begin;
select *
from
fnc_fasi_bil_gest_reimputa
(
  3,
  2018,
  'batch',
  now()::timestamp,
  'A',
  'false'
);


select fase.movgest_anno, fase.movgest_numero,
       fase.movgestnew_id,
       fase.movgest_ts_code,
       fase.mod_tipo_code,
       fase.mtdm_reimputazione_anno,
       mov.movgest_anno,
       mov.movgest_numero,
       ts.movgest_ts_code,
       ts.movgest_ts_id,
       fase.importomodifica
from fase_bil_t_reimputazione fase,siac_t_movgest mov,siac_t_movgest_Ts ts
where fase.fasebilelabid=45
and   fase.movgest_anno::integer=2017
and   fase.movgest_numero::Integer=398
and   mov.movgest_id=fase.movgestnew_id
and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   ts.movgest_id=mov.movgest_id


select *
from fase_bil_t_elaborazione fase
where fase.ente_proprietario_id=2
order by fase.fase_bil_elab_id desc
-- 163 22
-- 164 325

select *
from fase_bil_t_reimputazione fase
where fase.fasebilelabid=164
where fase.fasebilelabid=152


select *
from fase_bil_t_reimputazione_vincoli fase
where fase.fasebilelabid=164




select *
from siac_r_movgest_ts r
where r.ente_proprietario_id=3
and   exists
( select 1 from fase_bil_t_reimputazione_vincoli fase
  where fase.ente_proprietario_id=3
 -- and   fase.fasebilelabid=151
  and   fase.movgest_ts_b_new_id=r.movgest_ts_b_id)

rollback;
begin;
update   siac_r_movgest_ts r
set   data_cancellazione=now(),
      validita_fine=now()
where r.ente_proprietario_id=3
and   exists
( select 1 from fase_bil_t_reimputazione_vincoli fase
  where fase.ente_proprietario_id=3
 -- and   fase.fasebilelabid=151
  and   fase.movgest_ts_b_new_id=r.movgest_ts_b_id)

begin;
update fase_bil_t_reimputazione_vincoli fase
set    movgest_ts_a_new_id=null,
       movgest_ts_b_new_id=null,
       movgest_ts_r_new_id=null,
       fl_elab=null
where   fase.fasebilelabid=165

select ts.*
from siac_t_movgest_ts ts, siac_t_movgest mov,siac_d_movgest_tipo tipo,
     fase_bil_t_reimputazione fase,siac_v_bko_anno_bilancio anno
where tipo.ente_proprietario_id=3
--and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
--and   mov.movgest_anno::integer>=2018
--and   mov.login_operazione='batch'
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2018
and   ts.movgest_id=mov.movgest_id
--and   ts.login_operazione='batch'
--and   ts.movgest_ts_id>=78095
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   fase.ente_proprietario_id=3
--and   fase.fasebilelabid>=80
and   fase.movgestnew_ts_id=ts.movgest_ts_id
-- 103

begin;
update siac_t_movgest mov
set    data_cancellazione=now(),
       validita_fine=now()
from siac_t_movgest_ts ts, siac_d_movgest_tipo tipo,
     fase_bil_t_reimputazione fase,siac_v_bko_anno_bilancio anno
where tipo.ente_proprietario_id=3
--and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
--and   mov.movgest_anno::integer>=2018
--and   mov.login_operazione='batch'
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2018
and   ts.movgest_id=mov.movgest_id
--and   ts.login_operazione='batch'
--and   ts.movgest_ts_id>=78095
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   fase.ente_proprietario_id=3
--and   fase.fasebilelabid>=80
and   fase.movgestnew_ts_id=ts.movgest_ts_id

update siac_t_movgest_ts ts
set    data_cancellazione=now(),
      validita_fine=now()
from siac_t_movgest mov,siac_d_movgest_tipo tipo,
     fase_bil_t_reimputazione fase,siac_v_bko_anno_bilancio anno
where tipo.ente_proprietario_id=3
--and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
--and   mov.movgest_anno::integer>=2018
--and   mov.login_operazione='batch'
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2018
and   ts.movgest_id=mov.movgest_id
--and   ts.login_operazione='batch'
--and   ts.movgest_ts_id>=78095
--and   mov.data_cancellazione is null
--and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   fase.ente_proprietario_id=3
--and   fase.fasebilelabid>=80
and   fase.movgestnew_ts_id=ts.movgest_ts_id


select min(fase.movgestnew_ts_id)
from fase_bil_t_reimputazione fase
where fase.ente_proprietario_id=3
and   fase.movgestnew_ts_id is not null


select fase.*
from fase_bil_t_reimputazione fase
where fase.fasebilelabid=150
and   not exists
(select 1
from
where fase1.fasebilelabid=fase.fasebilelabid
and   fase1.reimputazione_id=fase.reimputazione_id)

select tipo.avav_tipo_code,
       av.*
from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo tipo
where av.avav_tipo_id=tipo.avav_tipo_id
and   av.ente_proprietario_id=3

select cTitolo.classif_code::integer titolo_uscita,
    	           ( case when cTitolo.classif_code::integer in (1,4)  -- titolo 1 e 4 - FPVSC corrente
                      then 'FPVSC'
                      when cTitolo.classif_code::integer in (2,3)  -- titolo 2 e 3 - FPVCC in conto capitale
                      then 'FPVCC'
                      else null end ) tipo_avanzo
        	from siac_t_bil_elem e, siac_d_bil_elem_tipo tipo,
            	 siac_r_bil_elem_class rc,siac_t_class cMacro, siac_d_class_tipo tipoMacro,
	             siac_r_class_fam_tree rfam,
    	         siac_t_class cTitolo, siac_d_class_tipo tipoTitolo,
        	     siac_t_bil bil, siac_t_periodo per,
                 siac_r_movgest_bil_elem rmov, fase_bil_t_reimputazione_vincoli fase,
                 siac_t_movgest mov, siac_t_movgest_ts ts
	        where tipo.ente_proprietario_id=3
    	    and   tipo.elem_tipo_code='CAP-UG'
	        and   e.elem_tipo_id=tipo.elem_tipo_id
    	    and   bil.bil_id=e.bil_id
	        and   per.periodo_id=bil.periodo_id
	        and   per.anno::integer=2018
	        and   rc.elem_id=e.elem_id
    	    and   cMacro.classif_id=rc.classif_id
	        and   tipoMacro.classif_tipo_id=cMacro.classif_tipo_id
    	    and   tipomacro.classif_tipo_code='MACROAGGREGATO'
        	and   rfam.classif_id=cMacro.classif_id
	        and   cTitolo.classif_id=rfam.classif_id_padre
    	    and   tipoTitolo.classif_tipo_id=cTitolo.classif_tipo_id
        	and   tipoTitolo.classif_tipo_code='TITOLO_SPESA'
            and   rmov.elem_id=e.elem_id
            and   mov.movgest_id=rmov.movgest_id
            and   ts.movgest_id=mov.movgest_id
            and   ts.movgest_ts_id=fase.movgest_ts_b_new_id
            and   fase.fasebilelabid=116
	        and   e.data_cancellazione is null
    	    and   e.validita_fine is null
        	and   rc.data_cancellazione is null
	        and   rc.validita_fine is null
    	    and   rfam.data_cancellazione is null
	        and   rfam.validita_fine is null


select *
from fase_bil_t_elaborazione fase
where  fase.ente_proprietario_id=3
order by fase.fase_bil_elab_id desc

begin;
select *
from
fnc_fasi_bil_gest_reimputa_provvedimento
(
  3,
  2018,
  'batch',
  now()::timestamp,
  'I'
);


select movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       movnew.movgest_anno anno_impegno_riacc, movnew.movgest_numero numero_impegno_riacc,
       det.movgest_ts_det_importo,
       fase.movgest_ts_id,
       stato.movgest_stato_code
from fase_bil_t_reimputazione fase,
     siac_t_movgest movb,siac_t_movgest_ts tsb,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
--where fase.fasebilelabid=146
--where fase.fasebilelabid=151
where fase.fasebilelabid=164
and  tsb.movgest_ts_id=fase.movgest_ts_id
and  movb.movgest_id=tsb.movgest_id
and  tsnew.movgest_ts_id=fase.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  tsnew.movgest_ts_id=fase.movgestnew_ts_id
and  rs.movgest_ts_id=tsnew.movgest_ts_id
and  stato.movgest_stato_id=rs.movgest_stato_id
and  rs.data_cancellazione is null
and  rs.validita_fine is null

select movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       movnew.movgest_anno anno_impegno_riacc, movnew.movgest_numero numero_impegno_riacc,
       det.movgest_ts_det_importo,
       fase.movgest_ts_id,
       stato.movgest_stato_code
from fase_bil_t_reimputazione fase,
     siac_t_movgest movb,siac_t_movgest_ts tsb,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato ,siac_r_movgest_ts_atto_amm ra
--where fase.fasebilelabid=146
--where fase.fasebilelabid=151
where fase.fasebilelabid=164
and  tsb.movgest_ts_id=fase.movgest_ts_id
and  movb.movgest_id=tsb.movgest_id
and  tsnew.movgest_ts_id=fase.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  tsnew.movgest_ts_id=fase.movgestnew_ts_id
and  rs.movgest_ts_id=tsnew.movgest_ts_id
and  stato.movgest_stato_id=rs.movgest_stato_id
and  ra.movgest_ts_id=tsnew.movgest_ts_id
and  rs.data_cancellazione is null
and  rs.validita_fine is null
and  ra.data_cancellazione is null
and  rA.validita_fine is null


-- 116
begin;
select *
from fnc_fasi_bil_gest_reimputa_vincoli
(
  3,
  2018,
  'batch',
  now()::timestamp
);

select  *
from fase_bil_t_reimputazione_vincoli fase
where fase.fasebilelabid=164
-- 260

select  r.*
from fase_bil_t_reimputazione_vincoli fase,siac_r_movgest_ts r
where fase.fasebilelabid=164
and   fase.movgest_ts_r_new_id is not null
and   fase.movgest_ts_a_id is not null
and   r.movgest_ts_r_id=fase.movgest_ts_r_new_id
and   r.avav_id is not null

-- movimenti riaccertati
select movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       movnew.movgest_anno anno_impegno_riacc, movnew.movgest_numero numero_impegno_riacc,
       det.movgest_ts_det_importo,
       fase.movgest_ts_id
from fase_bil_t_reimputazione fase,
     siac_t_movgest movb,siac_t_movgest_ts tsb,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
--where fase.fasebilelabid=146
where fase.fasebilelabid=164
and  tsb.movgest_ts_id=fase.movgest_ts_id
and  movb.movgest_id=tsb.movgest_id
and  tsnew.movgest_ts_id=fase.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
-- 325


-- movimenti riaccertati con vincoli da creare
select movb.movgest_anno, movb.movgest_numero,
       movnew.movgest_anno, movnew.movgest_numero,
       det.movgest_ts_det_importo,
       rvinc.importo_delta, rts.movgest_ts_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase1.importomodifica,
       fase.avav_id,
       rts.avav_id,
       fase.avav_new_id,
       fase.movgest_ts_b_id,
       fase.movgest_ts_r_new_id,
       fase.movgest_ts_a_new_id,
       fase.movgest_ts_b_new_id
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
where fase.fasebilelabid=164
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and   tsb.movgest_ts_id=fase.movgest_ts_b_id
and   movb.movgest_id=tsb.movgest_id
and   fase1.reimputazione_id=fase.reimputazione_id
and   tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and   movnew.movgest_id=tsnew.movgest_id
and   det.movgest_ts_id=tsnew.movgest_ts_id
and   tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and   tipod.movgest_ts_det_tipo_code='I'
-- 260

-- movimenti riaccertati con vincoli da creare con accertamenti collegati da riaccertare
select movb.movgest_anno, movb.movgest_numero,
       movnew.movgest_anno, movnew.movgest_numero,
       det.movgest_ts_det_importo,
       rvinc.importo_delta, rts.movgest_ts_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase1.importomodifica,
       fase.avav_id,
       rts.avav_id,
       fase.avav_new_id,
       fase.movgest_ts_b_id,
       fase.movgest_ts_A_id,
       fase.movgest_ts_r_new_id,
       fase.movgest_ts_a_new_id,
       fase.movgest_ts_b_new_id
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
where fase.fasebilelabid=164
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and   tsb.movgest_ts_id=fase.movgest_ts_b_id
and   movb.movgest_id=tsb.movgest_id
and   fase1.reimputazione_id=fase.reimputazione_id
and   tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and   movnew.movgest_id=tsnew.movgest_id
and   det.movgest_ts_id=tsnew.movgest_ts_id
and   tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and   tipod.movgest_ts_det_tipo_code='I'

-- impegni riaccertati con vincoli riaccertati
select movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       movnew.movgest_anno anno_impegno_new, movnew.movgest_numero numero_impegno_new,
       det.movgest_ts_det_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       rvinc.importo_delta,
       fase1.importomodifica,
       rts.movgest_ts_importo,
       fase.fl_elab,
       fase.scarto_desc,
       fase.avav_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       fase.movgest_ts_r_new_id,
       fase.movgest_ts_a_new_id,
       fase.movgest_ts_b_new_id,
       rnew.movgest_ts_importo,
       rnew.movgest_ts_r_id,
       rnew.movgest_ts_a_id,
       fase.avav_new_id,
       rnew.avav_id,
       fase.movgest_ts_a_id
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_r_movgest_ts rnew
where fase.fasebilelabid=164
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id
and  fase1.reimputazione_id=fase.reimputazione_id
and  tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  rnew.movgest_ts_b_id=tsnew.movgest_ts_id

--- impegni riaccertati con vincoli riaccerati ad accertamenti riaccertati
select movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       mova.movgest_anno anno_accertamento_orig, mova.movgest_numero numero_accertamento_orig,
       movnew.movgest_anno anno_impegno_new, movnew.movgest_numero numero_impegno_new,
       movanew.movgest_anno anno_accertamento_new, movanew.movgest_numero numero_accertamento_new,
       fase.importo_vincolo, fase.importo_vincolo_new,
       rvinc.importo_delta,
       fase1.importomodifica,
       rts.movgest_ts_importo,
       fase.fl_elab,
       fase.scarto_desc,
       fase.avav_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       det.movgest_ts_det_importo,
       fase.movgest_ts_r_new_id,
       fase.movgest_ts_a_new_id,
       fase.movgest_ts_b_new_id,
       rnew.movgest_ts_importo,
       rnew.movgest_ts_r_id,
       rnew.movgest_ts_a_id,
       fase.avav_new_id,
       rnew.avav_id,
       fase.movgest_ts_a_id

from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_t_movgest_ts tsa, siac_t_movgest mova,
     siac_r_movgest_ts rnew,
     siac_t_movgest_ts tsanew, siac_t_movgest movanew
where fase.fasebilelabid=164
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
--and   fase.movgest_ts_a_id is not null
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id
and  fase1.reimputazione_id=fase.reimputazione_id
and  tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  tsa.movgest_ts_id=fase.movgest_ts_a_id
and  mova.movgest_id=tsa.movgest_id
and  rnew.movgest_ts_b_id=tsnew.movgest_ts_id
and  tsanew.movgest_ts_id=rnew.movgest_ts_a_id
and  movanew.movgest_id=tsanew.movgest_id




select *
from siac_r_movgest_ts r
where r.movgest_ts_r_id=10741


select rvinc.importo_delta, rts.movgest_ts_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase.avav_id,
       fase.avav_new_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       mova.movgest_anno anno_accertamento_orig,
       mova.movgest_numero numero_accertamento_orig,
       movnew.movgest_anno anno_impegno_riacc, movnew.movgest_numero numero_impegno_riacc,
       fase1.importomodifica,
       det.movgest_ts_det_importo
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_t_movgest_ts tsa, siac_t_movgest mova
where fase.fasebilelabid=146
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and   fase.movgest_ts_a_id is not null
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id
and  fase1.reimputazione_id=fase.reimputazione_id
and  tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  tsa.movgest_ts_id=fase.movgest_ts_a_id
and  mova.movgest_id=tsa.movgest_id

select rvinc.importo_delta, rts.movgest_ts_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase.avav_id,
       fase.avav_new_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       movb.movgest_anno, movb.movgest_numero,
       fase1.importomodifica,
       movnew.movgest_anno, movnew.movgest_numero,
       det.movgest_ts_det_importo,
       mova.movgest_anno,
       mova.movgest_numero,
       fase.movgest_ts_r_new_id,
       fase.movgest_ts_a_new_id,
       fase.movgest_ts_b_new_id
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_t_movgest_ts tsa, siac_t_movgest mova
where fase.fasebilelabid=146
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
--and   fase.movgest_ts_a_id is not null
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id
and  fase1.reimputazione_id=fase.reimputazione_id
and  tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  tsa.movgest_ts_id=fase.movgest_ts_a_id
and  mova.movgest_id=tsa.movgest_id


select rvinc.importo_delta, rts.movgest_ts_importo,
       fase.fl_elab,
       fase.scarto_desc,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase.avav_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       mova.movgest_anno anno_accertamento_orig,
       mova.movgest_numero numero_accertamento_orig,
       det.movgest_ts_det_importo,
       fase1.importomodifica,
       movnew.movgest_anno anno_impegno_new, movnew.movgest_numero numero_impegno_new,
       movanew.movgest_anno anno_accertamento_new, movanew.movgest_numero numero_accertamento_new,
       fase.movgest_ts_r_new_id,
       fase.movgest_ts_a_new_id,
       fase.movgest_ts_b_new_id,
       rnew.movgest_ts_importo,
       rnew.movgest_ts_r_id,
       rnew.movgest_ts_a_id,
       fase.avav_new_id,
       rnew.avav_id,
       fase.movgest_ts_a_id

from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_t_movgest_ts tsa, siac_t_movgest mova,
     siac_r_movgest_ts rnew,
     siac_t_movgest_ts tsanew, siac_t_movgest movanew
where fase.fasebilelabid=146
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
--and   fase.movgest_ts_a_id is not null
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id
and  fase1.reimputazione_id=fase.reimputazione_id
and  tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  tsa.movgest_ts_id=fase.movgest_ts_a_id
and  mova.movgest_id=tsa.movgest_id
and  rnew.movgest_ts_b_id=tsnew.movgest_ts_id
and  tsanew.movgest_ts_id=rnew.movgest_ts_a_id
and  movanew.movgest_id=tsanew.movgest_id

2000
3426
67,18
237579,32
500

select rvinc.importo_delta, rts.movgest_ts_importo,
       fase.fl_elab,
       fase.scarto_desc,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase.avav_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       movb.movgest_anno anno_impegno_orig, movb.movgest_numero numero_impegno_orig,
       det.movgest_ts_det_importo,
       fase1.importomodifica,
       movnew.movgest_anno anno_impegno_new, movnew.movgest_numero numero_impegno_new,
       fase.movgest_ts_r_new_id,
       fase.movgest_ts_a_new_id,
       fase.movgest_ts_b_new_id,
       rnew.movgest_ts_importo,
       rnew.movgest_ts_r_id,
       rnew.movgest_ts_a_id,
       fase.avav_new_id,
       rnew.avav_id,
       fase.movgest_ts_a_id
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod,
     siac_r_movgest_ts rnew
where fase.fasebilelabid=146
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id
and  fase1.reimputazione_id=fase.reimputazione_id
and  tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'
and  rnew.movgest_ts_b_id=tsnew.movgest_ts_id

select *
from siac_d_movgest_tipo tipo
where tipo.ente_proprietario_id=3

select *
from fase_bil_t_reimputazione fase
where fase.fasebilelabid=130

-- ero
with
	 accPrec as
	 (-- accertamento vincolato in annoBilancio-1
	  select mov.movgest_anno::integer anno_accertamento,
  			 mov.movgest_numero::integer numero_accertamento,
	         (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
    	     mov.movgest_id, ts.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
    	   siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato
	  where ts.movgest_ts_id=74411
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   mov.movgest_id=ts.movgest_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	 ),
 	 accCurRiacc as
	 (-- accertamenti riaccertati per accPrec in annoBilancio
	  select mov.movgest_anno::integer anno_accertamento,
    	     mov.movgest_numero::integer numero_accertamento,
	 	     (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
		     mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
	  from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
   		   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase,siac_d_movgest_stato stato,
           siac_t_bil bil,siac_t_periodo per
	  where bil.ente_proprietario_id=3
      and   per.periodo_id=bil.periodo_id
      and   per.anno::integer=2018
      and   mov.bil_id=bil.bil_id
	  and   mov.movgest_tipo_id=7
	  and   ts.movgest_id=mov.movgest_id
      and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
	  and   rs.movgest_ts_id=ts.movgest_ts_id
      and   stato.movgest_stato_id=rs.movgest_stato_id
      and   stato.movgest_stato_code!='A'
	  and   fase.fasebilelabid=130
	  and   fase.fl_elab is not null and fase.fl_elab!=''
	  and   fase.fl_elab='S'
	  and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
	  and   mov.movgest_anno::integer<=2018
	  and   rs.data_cancellazione is null
	  and   rs.validita_fine is null
	  and   mov.data_cancellazione is null
	  and   mov.validita_fine is null
	  and   ts.data_cancellazione is null
	  and   ts.validita_fine is null
	),
	accUtilizzabile as
	(-- utlizzabile per accertamento
	 select det.movgest_ts_id, det.movgest_ts_det_importo importo_utilizzabile
	 from siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
	 where tipo.ente_proprietario_id=3
	 and   tipo.movgest_ts_det_tipo_code='U'
	 and   det.movgest_ts_det_tipo_id= tipo.movgest_ts_det_tipo_id
	 and   det.data_cancellazione is null
	 and   det.validita_fine is null
	),
	vincolato as
	(-- vincolato per accertamento
	 select r.movgest_ts_a_id, sum(r.movgest_ts_importo) totale_vincolato
     from siac_r_movgest_ts r
	 where r.ente_proprietario_id=3
	 and   r.data_cancellazione is null
	 and   r.validita_fine is null
     and   r.movgest_ts_a_id is not null
	 group by r.movgest_ts_a_id
	)
	select   accCurRiacc.anno_accertamento,
    	     accCurRiacc.numero_accertamento,
        	 accCurRiacc.numero_subaccertamento,
	         accUtilizzabile.importo_utilizzabile,
    	     coalesce(vincolato.totale_vincolato,0) totale_vincolato,
	         accUtilizzabile.importo_utilizzabile -  coalesce(vincolato.totale_vincolato,0) dispVincolabile,
    	     accCurRiacc.movgest_ts_new_id movgest_ts_riacc_id
	from accPrec, accUtilizzabile,
    	 accCurRiacc
	       left join vincolato on (accCurRiacc.movgest_ts_new_id=vincolato.movgest_ts_a_id)
	where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
    and   accUtilizzabile.movgest_ts_id=accCurRiacc.movgest_ts_new_id
	order by  accCurRiacc.anno_accertamento,
	          accCurRiacc.numero_accertamento,
	          accCurRiacc.numero_subaccertamento




select *
from siac_t_movgest_ts_det det
where det.movgest_ts_id=78163
select bil_id
from siac_v_bko_anno_bilancio anno
where anno.anno_bilancio=2018
and ente_proprietario_id=3

select *
from siac_d_movgest_tipo
select *
from siac_d_movgest_stato
where ente_proprietario_id=3
with
             accPrec as
             (
        	  select mov.movgest_anno::integer anno_accertamento,
              mov.movgest_numero::integer numero_accertamento,
              (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
              mov.movgest_id, ts.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs
              where mov.bil_id=137
              and   mov.movgest_tipo_id=7
              and   ts.movgest_id=mov.movgest_id
              and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
              and   ts.movgest_ts_id=74411 --movGestRec.movgest_ts_a_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=11
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             ),
             accCurRiacc as
             (
              select mov.movgest_anno::integer anno_accertamento,
	                 mov.movgest_numero::integer numero_accertamento,
       			    (case when tstipo.movgest_ts_tipo_code='T' then 0 else ts.movgest_ts_code::integer end) numero_subaccertamento,
	                mov.movgest_id movgest_new_id, ts.movgest_ts_id movgest_ts_new_id,fase.movgest_ts_id
              from siac_t_movgest mov, siac_t_movgest_ts ts,siac_d_movgest_ts_tipo tstipo,
             	   siac_r_movgest_ts_stato rs, fase_bil_t_reimputazione fase
              where mov.bil_id=139
              and   mov.movgest_tipo_id=7
              and   ts.movgest_id=mov.movgest_id
              and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
              and   rs.movgest_ts_id=ts.movgest_ts_id
              and   rs.movgest_stato_id!=11
              and   fase.fasebilelabid=130
              and   fase.fl_elab is not null and fase.fl_elab!=''
	    	  and   fase.fl_elab='S'
              and   ts.movgest_ts_id=fase.movgestnew_ts_id  -- nuovo accertamento riaccertato con anno_accertamento<=anno_impegno nuovo
              and   mov.movgest_anno::integer<=2018
              and   rs.data_cancellazione is null
              and   rs.validita_fine is null
              and   mov.data_cancellazione is null
              and   mov.validita_fine is null
              and   ts.data_cancellazione is null
              and   ts.validita_fine is null
             )
             select  accCurRiacc.movgest_new_id, accCurRiacc.movgest_ts_new_id
             from accPrec, accCurRiacc
             where accPrec.movgest_ts_id=accCurRiacc.movgest_ts_id
             limit 1;






  select
    	siac_r_bil_attr.bil_attr_id,
    	siac_r_bil_attr.boolean
    from
    	siac_t_bil,siac_r_bil_attr,siac_t_attr
    where
    siac_t_bil.bil_id = siac_r_bil_attr.bil_id
    and siac_r_bil_attr.attr_id =  siac_t_attr.attr_id
    and siac_r_bil_attr.data_cancellazione is null
    and siac_t_attr.attr_code like 'flagReimputa%'--Entrate'
    and siac_t_bil.bil_code = 'BIL_2018'
    and siac_t_bil.ente_proprietario_id = 3;

select *
from siac_r_bil_attr r
where r.bil_attr_id in (102,95)

select *
from fase_bil_t_reimputazione fase
where fase.fasebilelabid=116


-- 326
select sum(fase.importomodifica)
from fase_bil_t_reimputazione fase
where fase.fasebilelabid=110
where fase.fasebilelabid=108
-- -13644631,95

select  sum(det.movgest_ts_det_importo)
from fase_bil_t_reimputazione fase,siac_t_movgest mov,siac_t_movgest_ts ts,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
where fase.fasebilelabid=110
--where fase.fasebilelabid=108

and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   mov.movgest_id=ts.movgest_id
and   det.movgest_ts_id=ts.movgest_ts_id
and   tipo.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and   tipo.movgest_ts_det_tipo_code='A'
-- 13644631,95

rollback;
begin;
select *
from
fnc_fasi_bil_gest_reimputa_prod (
  3,
  2018,
  'batch',
  now()::timestamp,
  'A'
);

select *
from fase_bil_t_reimputazione fase
--where fase.fasebilelabid=107
where fase.fasebilelabid=108
-- 326
-- 21
select sum(fase.importomodifica)
from fase_bil_t_reimputazione fase
--where fase.fasebilelabid=107
where fase.fasebilelabid=108
-- -13644631,95
-- -7036016,58

select  sum(det.movgest_ts_det_importo)
from fase_bil_t_reimputazione fase,siac_t_movgest mov,siac_t_movgest_ts ts,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
--where fase.fasebilelabid=107
where fase.fasebilelabid=108

and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   mov.movgest_id=ts.movgest_id
and   det.movgest_ts_id=ts.movgest_ts_id
and   tipo.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and   tipo.movgest_ts_det_tipo_code='A'
-- 13644631,95
-- 7036016,58

select count(*)
from fase_bil_t_reimputazione fase,siac_t_movgest mov,siac_t_movgest_ts ts,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
--where fase.fasebilelabid=107
where fase.fasebilelabid=110

and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   mov.movgest_id=ts.movgest_id
and   det.movgest_ts_id=ts.movgest_ts_id
and   tipo.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and   tipo.movgest_ts_det_tipo_code='A'

select distinct ts.siope_tipo_debito_id
from fase_bil_t_reimputazione fase,siac_t_movgest mov,siac_t_movgest_ts ts,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipo
--where fase.fasebilelabid=107
where fase.fasebilelabid=110

and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   mov.movgest_id=ts.movgest_id
and   det.movgest_ts_id=ts.movgest_ts_id
and   tipo.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and   tipo.movgest_ts_det_tipo_code='A'

select  stato.movgest_stato_code,count(*)
from fase_bil_t_reimputazione fase,siac_t_movgest mov,siac_t_movgest_ts ts,
	 siac_r_movgest_ts_stato rs, siac_d_movgest_Stato stato

--where fase.fasebilelabid=107
where fase.fasebilelabid=116

and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   mov.movgest_id=ts.movgest_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
and   rs.data_cancellazione is null
and   rs.validita_fine is null
group by stato.movgest_stato_code
-- 305 D
-- 21 N

-- 21 D
select count(*)
from fase_bil_t_reimputazione fase,siac_t_movgest mov,siac_t_movgest_ts ts,
	 siac_r_movgest_ts_atto_amm ratto

--where fase.fasebilelabid=107
where fase.fasebilelabid=116

and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   mov.movgest_id=ts.movgest_id
and   ratto.movgest_ts_id=ts.movgest_ts_id

-- 326
-- 21

select av.avav_id, avtipo.avav_tipo_code
			from siac_t_avanzovincolo av, siac_d_avanzovincolo_tipo avtipo
			where avtipo.ente_proprietario_id=3
--			and   avtipo.avav_tipo_code in ('FPVSC','FPVCC')
			and   av.avav_tipo_id=avtipo.avav_tipo_id
			and   extract('year' from av.validita_inizio::timestamp)::integer=2018

select *
from fase_bil_t_elaborazione fase
where fase.ente_proprietario_id=3
order by fase.fase_bil_elab_id desc

select *
from fase_bil_t_reimputazione fase
where fase.fasebilelabid=100




select *
from fase_bil_t_reimputazione_vincoli fase
where fase.fasebilelabid=103
and fase.movgest_ts_a_id is not null

-- 2017/1439778 FPVSC
-- 2017/1567737 FPVCC
-- 2017/1628451 AMM
-- 2017/1559369 accertamento 2017/1566130
-- 2017 1632588 acc  2017/1631022

select rvinc.importo_delta, rts.movgest_ts_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase.avav_id,
       fase.avav_new_id,
       rts.avav_id,
       mov.movgest_anno, mov.movgest_numero,
       ts.movgest_ts_id,
       fase.movgest_ts_b_id,
       movb.movgest_anno, movb.movgest_numero

from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest mov,siac_t_movgest_ts ts,
     siac_t_movgest movb,siac_t_movgest_ts tsb
where fase.fasebilelabid=105
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and fase.movgest_ts_a_id is not null
and  ts.movgest_ts_id=fase.movgest_ts_a_id
and  mov.movgest_id=ts.movgest_id
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id


-- acc 1566130 id=42743
-- acc 1631022 id=74411


select rvinc.importo_delta, rts.movgest_ts_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase.avav_id,
       fase.avav_new_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       movb.movgest_anno, movb.movgest_numero,
       fase1.importomodifica,
       movnew.movgest_anno, movnew.movgest_numero,
       det.movgest_ts_det_importo
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb, fase_bil_t_reimputazione fase1,
     siac_t_movgest movnew, siac_t_movgest_ts tsnew,
     siac_t_movgest_ts_det det, siac_d_movgest_ts_det_tipo tipod
where fase.fasebilelabid=116
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id
and  fase1.reimputazione_id=fase.reimputazione_id
and  tsnew.movgest_ts_id=fase1.movgestnew_ts_id
and  movnew.movgest_id=tsnew.movgest_id
and  det.movgest_ts_id=tsnew.movgest_ts_id
and  tipod.movgest_ts_det_tipo_id=det.movgest_ts_det_tipo_id
and  tipod.movgest_ts_det_tipo_code='I'


select rvinc.importo_delta, rts.movgest_ts_importo,
       fase.importo_vincolo, fase.importo_vincolo_new,
       fase.avav_id,
       fase.avav_new_id,
       rts.avav_id,
       fase.movgest_ts_b_id,
       movb.movgest_anno, movb.movgest_numero
from fase_bil_t_reimputazione_vincoli fase, siac_r_modifica_vincolo rvinc,siac_r_movgest_ts rts,
     siac_t_movgest movb,siac_t_movgest_ts tsb
where fase.fasebilelabid=100
and   rvinc.mod_id=fase.mod_id
and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
and  tsb.movgest_ts_id=fase.movgest_ts_b_id
and  movb.movgest_id=tsb.movgest_id


select mov.movgest_anno::integer, mov.movgest_numero::integer,
       stato.movgest_stato_code,
       fase.attoamm_id,
       fase.movgest_stato_id,
       stato.movgest_stato_id


from fase_bil_t_reimputazione fase,siac_t_movgest mov, siac_t_movgest_Ts ts,siac_r_movgest_ts_stato rs,siac_d_movgest_stato stato--,
--     siac_r_movgest_ts_atto_amm ratto
where fase.fasebilelabid=102
and   ts.movgest_ts_id=fase.movgestnew_ts_id
and   mov.movgest_id=ts.movgest_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_stato_id
--and   ratto.movgest_ts_id=ts.movgest_ts_id



-- accertamenti riaccertati ce ne sono anche altri
-- 38915
-- 47533
-- 47857
-- 52070

select mov.movgest_anno , mov.movgest_numero,
       r.movgest_ts_importo,
       rvinc.importo_delta,
       det.movgest_ts_det_importo,
       fase.importo_vincolo,
       fase.importo_vincolo_new
from siac_t_movgest_Ts ts, siac_t_movgest mov, siac_r_movgest_ts r, siac_r_modifica_vincolo rvinc,
     siac_t_modifica mod, siac_r_modifica_stato rmov, siac_t_movgest_ts_det_mod det, siac_d_modifica_stato stato,
     fase_bil_t_reimputazione_vincoli fase
where ts.movgest_ts_id in (38915,
47533,
47857,
52070,
42743,
74411)
and   mov.movgest_id=ts.movgest_id
and   r.movgest_ts_a_id=ts.movgest_ts_id
and   rvinc.movgest_ts_r_id=r.movgest_ts_r_id
and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
and   mod.mod_id=rvinc.mod_id
and   rmov.mod_id=mod.mod_id
and   stato.mod_stato_id=rmov.mod_stato_id
and   stato.mod_stato_code!='A'
and   det.mod_stato_r_id=rmov.mod_stato_r_id
and   fase.movgest_ts_r_id=rvinc.movgest_ts_r_id
and   fase.movgest_ts_a_id=ts.movgest_ts_id
and   fase.fasebilelabid=105
and   r.data_cancellazione is null
and   r.validita_fine is null
and   rvinc.data_cancellazione is null
and   rvinc.validita_fine is null
and   rmov.data_cancellazione is null
and   rmov.validita_fine is null



select *
from fase_bil_t_reimputazione_vincoli fase
where fase.fasebilelabid=104
and   fase.movgest_ts_a_id is not null
and   exists
(select 1
from
siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato
				where  bil.ente_proprietario_id=3
				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
				and   per.anno::integer=2018-1
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id =  modificaTipo.mod_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
   				and   tsmov.movgest_ts_id=fase.movgest_ts_a_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code='I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code='A'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
)









select  fase.*
from fase_bil_t_reimputazione fase


where fase.fasebilelabid=100
and   not exists
(
select 1
from fase_bil_t_reimputazione_vincoli fase1
where fase1.fasebilelabid=100
and   fase1.reimputazione_id=fase.reimputazione_id

)
and  not exists
(
select 1  from siac_r_movgest_ts rts
where rts.movgest_ts_b_id=fase.movgest_ts_id
)

select  fase.*
from fase_bil_t_reimputazione fase


where fase.fasebilelabid=100
and   not exists
(
select 1
from fase_bil_t_reimputazione_vincoli fase1
where fase1.fasebilelabid=100
and   fase1.reimputazione_id=fase.reimputazione_id

)
and  not exists
(select 1
from
siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato, -- 07.02.2018 Sofia siac-5368,
                     siac_r_modifica_vincolo rvinc,
				     siac_r_movgest_ts rts
				where  bil.ente_proprietario_id=3
				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
				and   per.anno::integer=2018-1
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id =  modificaTipo.mod_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
   				and   tsmov.movgest_ts_id=fase.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code='I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code='I'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
               and   rvinc.mod_id=modifica.mod_id
                and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
				and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        		and   rts.movgest_ts_b_id=tsmov.movgest_ts_id
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
)





------------


select mov.movgest_anno::integer,
       mov.movgest_numero::integer,
       ts.movgest_ts_code,
       ts.movgest_ts_id
from siac_t_movgest mov, siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
     siac_d_movgest_stato stato, siac_d_movgest_ts_tipo tstipo
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2017
and   ts.movgest_id=mov.movgest_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_Stato_id
and   stato.movgest_stato_code='N'
and   mov.movgest_anno::integer=2017
and   mov.movgest_numero::integer=1632588
and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   tstipo.movgest_ts_tipo_code='T'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null

select *
from siac_d_movgest_stato stato
where stato.ente_proprietario_id=3

select *
from siac_r_movgest_ts_stato r
where r.movgest_ts_id=74413



select mov.movgest_anno::integer,
       mov.movgest_numero::integer,
       ts.movgest_ts_code,
       ts.movgest_ts_id
from siac_t_movgest mov, siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
     siac_d_movgest_stato stato, siac_r_movgest_bil_elem re, siac_t_bil_elem e,siac_d_movgest_ts_tipo tstipo
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2017
and   ts.movgest_id=mov.movgest_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_Stato_id
and   stato.movgest_stato_code='D'
and   re.movgest_id=mov.movgest_id
and   e.elem_id=re.elem_id
and   e.elem_code::integer=16209
and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   tstipo.movgest_ts_tipo_code='T'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   re.data_cancellazione is null
and   re.validita_fine is null
and   not exists
(
select 1
				from siac_t_modifica modifica,
                     siac_d_modifica_tipo modificaTipo,
					 siac_t_bil bil ,
					 siac_t_bil_elem bilel,
					 siac_r_movgest_bil_elem rbilel,
					 siac_t_movgest movgest,
					 siac_t_movgest_ts_det detts,
					 siac_t_movgest_ts_det_mod  dettsmod,
					 siac_r_modifica_stato  rmodstato,
					 siac_d_modifica_stato modstato,
					 siac_d_movgest_ts_det_tipo tipodet,
					 siac_t_movgest_ts tsmov,
					 siac_d_movgest_tipo tipomov,
					 siac_d_movgest_ts_tipo tipots,
					 siac_t_movgest_ts_det dettsIniz,
					 siac_d_movgest_ts_det_tipo tipodetIniz,
					 siac_t_periodo per,
					 siac_d_bil_elem_tipo dbileltip,
                     siac_r_movgest_ts_stato rstato, -- 07.02.2018 Sofia siac-5368,
                     siac_r_modifica_vincolo rvinc,
				     siac_r_movgest_ts rts
				where bil.ente_proprietario_id=3

				and   bilel.elem_tipo_id = dbileltip.elem_tipo_id
				-- da siac_t_bil_elem a siac_t_movgest
				and   bilel.elem_id   = rbilel.elem_id
				and   rbilel.movgest_id = movgest.movgest_id
				and   per.periodo_id=bil.periodo_id
				and   per.anno::integer=2018-1
				and   modifica.ente_proprietario_id=bil.ente_proprietario_id
				and   rmodstato.mod_id=modifica.mod_id
				and   dettsmod.mod_stato_r_id=rmodstato.mod_stato_r_id
				and   modstato.mod_stato_id=rmodstato.mod_stato_id
				and   modstato.mod_stato_code='V'
                and   modifica.mod_tipo_id =  modificaTipo.mod_tipo_id
                and   dettsmod.movgest_ts_det_importo<0
				and   tipodet.movgest_ts_det_tipo_id=dettsmod.movgest_ts_det_tipo_id
				and   detts.movgest_ts_det_id=dettsmod.movgest_ts_det_id
				and   tsmov.movgest_ts_id=detts.movgest_ts_id
				and   dettsIniz.movgest_ts_id=tsmov.movgest_ts_id
				and   tipodetIniz.movgest_ts_det_tipo_id=dettsIniz.movgest_ts_det_tipo_id
				and   tipodetIniz.movgest_ts_det_tipo_code='I'
				and   tipots.movgest_ts_tipo_id=tsmov.movgest_ts_tipo_id
				and   movgest.movgest_id=tsmov.movgest_id
				and   movgest.bil_id=bil.bil_id
				and   tipomov.movgest_tipo_id=movgest.movgest_tipo_id
				and   tipomov.movgest_tipo_code='I'
				and   dettsmod.mtdm_reimputazione_anno is not null
				and   dettsmod.mtdm_reimputazione_flag is true
                and   rstato.movgest_ts_id=tsmov.movgest_ts_id  -- 07.02.2018 Sofia siac-5368
                and   tsmov.movgest_ts_id=ts.movgest_ts_id
				and   bilel.validita_fine is null
				and   rbilel.validita_fine is null
				and   rmodstato.validita_fine is null
				and   tsmov.validita_fine is null
				and   dettsIniz.validita_fine is null
				and   bil.validita_fine is null
				and   per.validita_fine is null
				and   modifica.validita_fine is null
				and   bilel.data_cancellazione is null
				and   rbilel.data_cancellazione is null
				and   rmodstato.data_cancellazione is null
				and   tsmov.data_cancellazione is null
				and   dettsIniz.data_cancellazione is null
				and   bil.data_cancellazione is null
				and   per.data_cancellazione is null
				and   modifica.data_cancellazione is null
                and   rstato.data_cancellazione is null -- 07.02.2018 Sofia siac-5368
                and   rstato.validita_fine is null -- 07.02.2018 Sofia siac-5368
                and   rvinc.mod_id=modifica.mod_id
                and   rvinc.modvinc_tipo_operazione='INSERIMENTO'
				and   rts.movgest_ts_r_id=rvinc.movgest_ts_r_id
        		and   rts.movgest_ts_b_id=tsmov.movgest_ts_id
                and   rvinc.data_cancellazione is null
                and   rvinc.validita_fine is null
                and   rts.data_cancellazione is null
                and   rts.validita_fine is null
)

select mov.movgest_anno::integer,
       mov.movgest_numero::integer,
       ts.movgest_ts_code,
       ts.movgest_ts_id
from siac_t_movgest mov, siac_d_movgest_tipo tipo,
     siac_v_bko_anno_bilancio anno,siac_t_movgest_ts ts, siac_r_movgest_ts_stato rs,
     siac_d_movgest_stato stato, siac_r_movgest_bil_elem re, siac_t_bil_elem e,siac_d_movgest_ts_tipo tstipo
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='A'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2017
and   mov.movgest_anno::INTEGER=2017
and   ts.movgest_id=mov.movgest_id
and   rs.movgest_ts_id=ts.movgest_ts_id
and   stato.movgest_stato_id=rs.movgest_Stato_id
and   stato.movgest_stato_code='D'
and   re.movgest_id=mov.movgest_id
and   e.elem_id=re.elem_id
and   tstipo.movgest_ts_tipo_id=ts.movgest_ts_tipo_id
and   tstipo.movgest_ts_tipo_code='T'
and   rs.data_cancellazione is null
and   rs.validita_fine is null
and   mov.data_cancellazione is null
and   mov.validita_fine is null
and   ts.data_cancellazione is null
and   ts.validita_fine is null
and   re.data_cancellazione is null
and   re.validita_fine is null


select r.*
from siac_t_movgest mov, siac_v_bko_anno_bilancio anno, siac_d_movgest_tipo tipo,
     siac_t_movgest_ts ts, siac_r_movgest_ts r
where tipo.ente_proprietario_id=3
and   tipo.movgest_tipo_code='I'
and   mov.movgest_tipo_id=tipo.movgest_tipo_id
and   anno.bil_id=mov.bil_id
and   anno.anno_bilancio=2017
and   mov.movgest_anno::integer=2017
and   mov.movgest_numero::integer=1632588
and   ts.movgest_id=mov.movgest_id
and   r.movgest_ts_b_id=ts.movgest_ts_id
and   r.data_cancellazione is null
and   r.validita_fine is null
begin;
update siac_r_movgest_ts r
set    movgest_ts_importo=700
where r.movgest_ts_r_id=10610




select count(*)
from siac_r_movgest_ts r
where r.ente_proprietario_id=3
and   r.movgest_ts_a_id is not null
and   exists
(
select 1 from siac_t_movgest_ts ts, siac_t_movgest mov, siac_d_movgest_tipo tipo
where ts.movgest_ts_id=r.movgest_ts_a_id
and   mov.movgest_id=ts.movgest_id
and   tipo.movgest_tipo_id=mov.movgest_tipo_id
and   tipo.movgest_tipo_code!='A'
)
and  r.data_cancellazione is null
and  r.validita_fine is null

select count(*)
from siac_r_movgest_ts r
where r.ente_proprietario_id=3
and   r.movgest_ts_b_id is not null
and   exists
(
select 1 from siac_t_movgest_ts ts, siac_t_movgest mov, siac_d_movgest_tipo tipo
where ts.movgest_ts_id=r.movgest_ts_b_id
and   mov.movgest_id=ts.movgest_id
and   tipo.movgest_tipo_id=mov.movgest_tipo_id
and   tipo.movgest_tipo_code!='I'
)
and  r.data_cancellazione is null
and  r.validita_fine is null