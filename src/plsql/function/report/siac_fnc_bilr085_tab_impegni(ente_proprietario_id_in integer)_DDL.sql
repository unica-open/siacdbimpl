/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
CREATE OR REPLACE FUNCTION siac.fnc_bilr085_tab_impegni (
  ente_proprietario_id_in integer
)
RETURNS TABLE (
  ord_id integer,
  impegni varchar,
  anno_primo_impegno varchar
) AS
$body$
DECLARE
RTN_MESSAGGIO varchar;
elencoImpegni record;
ciclo integer;
trovato boolean;
mif_ord_dispe_valore_loop varchar;

BEGIN
ord_id:=null;
 impegni:='';
trovato:=false;
mif_ord_dispe_valore_loop:='';

        for elencoImpegni in
            SELECT a.mif_ord_dispe_valore, b.mif_ord_ord_id,replace(a.mif_ord_dispe_valore,'-','/') mif_ord_dispe_valore_rep
            , SUBSTRING(a.mif_ord_dispe_valore,1,4) annoimp
            FROM mif_t_ordinativo_spesa_disp_ente a,mif_t_ordinativo_spesa b
            WHERE a.ente_proprietario_id=ente_proprietario_id_in
                AND a.mif_ord_dispe_nome='Impegno quota mandato'
                and b.mif_ord_id=a.mif_ord_id 
                --and b.mif_ord_ord_id =1160
                order by 2,1
        loop
        
 
        
/*       raise notice '1 - ord_id:%', ord_id::varchar;
       raise notice '1 - elencoImpegni.mif_ord_ord_id:%', elencoImpegni.mif_ord_ord_id::varchar;
       raise notice '1 - impegni:%', impegni::varchar;
       raise notice '1 - trovato:%', ord_id::varchar; 
       raise notice '1 - mif_ord_dispe_valore_loop:%', mif_ord_dispe_valore_loop::varchar; */
       
        if 
        ord_id is not null and ord_id<>elencoImpegni.mif_ord_ord_id THEN
        mif_ord_dispe_valore_loop:='';
        return next;
        impegni:='';
        trovato:=false;
        end if;
        
               
        ord_id:=elencoImpegni.mif_ord_ord_id;
        

        
/*       raise notice '2 - ord_id:%', ord_id::varchar;
       raise notice '2 - elencoImpegni.mif_ord_ord_id:%', elencoImpegni.mif_ord_ord_id::varchar;
       raise notice '2 - impegni:%', impegni::varchar;
       raise notice '2 - trovato:%', ord_id::varchar; 
       raise notice '2 - mif_ord_dispe_valore_loop:%', mif_ord_dispe_valore_loop::varchar;  */
        
        if not trovato and elencoImpegni.annoimp<>'' and elencoImpegni is not null THEN
        trovato:=true;
        anno_primo_impegno:=elencoImpegni.annoimp;
        end if;      
        
        if impegni = '' THEN
        mif_ord_dispe_valore_loop:=elencoImpegni.mif_ord_dispe_valore_rep;
        impegni:=mif_ord_dispe_valore_loop;--elencoImpegni.mif_ord_dispe_valore_rep::varchar ;
        else 
          if mif_ord_dispe_valore_loop<>elencoImpegni.mif_ord_dispe_valore_rep then
          mif_ord_dispe_valore_loop:=elencoImpegni.mif_ord_dispe_valore_rep;
          impegni:=impegni||', '||mif_ord_dispe_valore_loop;--elencoImpegni.mif_ord_dispe_valore_rep;
          end if;
        end if;
        
              
        end loop;
        
        

return next;

exception
    when no_data_found THEN
        raise notice 'nessun mandato trovato' ;
        return;
    when others  THEN
         RAISE EXCEPTION '% Errore : %-%.',RTN_MESSAGGIO,SQLSTATE,substring(SQLERRM from 1 for 500);
        return;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;