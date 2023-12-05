/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/

drop FUNCTION if exists siac.fnc_siac_gsa_ordinativo
(
  p_anno_bilancio varchar,
  p_tipo_ord           varchar,
  p_ente_proprietario_id integer,
  p_data timestamp
);

CREATE OR REPLACE FUNCTION siac.fnc_siac_gsa_ordinativo
(p_anno_bilancio varchar, 
 p_tipo_ord           varchar,
 p_ente_proprietario_id integer, 
 p_data timestamp without time zone)
RETURNS TABLE (
  esito varchar
) AS
$body$
DECLARE
v_user_table varchar;
params varchar;
p_bilancio_id integer:=null;


annoBilancio integer;
annoBilancio_ini integer;
codResult integer:=null;
annoRec record;

ESERCIZIO_GESTIONE_ST    CONSTANT  varchar :='G'; -- esercizio gestione
ESERCIZIO_CONSUNTIVO_ST    CONSTANT  varchar :='O'; -- esercizio consuntivo

BEGIN


select fnc_siac_random_user()
into	v_user_table;


IF p_ente_proprietario_id IS NULL THEN
   RAISE EXCEPTION 'Errore: Parametro Ente Propietario nullo';
   RETURN;
END IF;


if p_tipo_ord is not null and   p_tipo_ord not in ('I','P','E') then 
	RAISE EXCEPTION 'Errore: Parametro Tipo Ordinativo non valido [I,P]';
    RETURN;
 else 
     if p_tipo_ord is null then p_tipo_ord:='E';  
     end if;
 end if;

IF p_data IS NULL THEN
   p_data := now();
END IF;

if p_anno_bilancio is null then 
    annoBilancio:=extract('YEAR' from now())::integer;
else 
    annoBilancio:=p_anno_bilancio::integer;
end if;
annoBilancio_ini:=annoBilancio;


 params := annoBilancio::varchar||' - '||p_tipo_ord||' - '||p_ente_proprietario_id::varchar||' - '||p_data::varchar;

 esito:= 'Inizio funzione carico ordinativi  GSA (fnc_siac_gsa_ordinativo) - '||clock_timestamp(); 
 RETURN NEXT;
 insert into
 siac_gsa_ordinativi_log_elab 
 (
 ente_proprietario_id,
 fnc_name ,
 fnc_parameters ,
 fnc_elaborazione_inizio ,
 fnc_user
 )
 values 
 (
 p_ente_proprietario_id,
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 ); 

 esito:='Parametri='||params; 
 RETURN next;
 insert into
 siac_gsa_ordinativi_log_elab 
 (  
 ente_proprietario_id,
 fnc_name ,
 fnc_parameters ,
 fnc_elaborazione_inizio ,
 fnc_user
 )
 values 
 (
 p_ente_proprietario_id,
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 );

esito:= '  Inizio eliminazione dati pregressi into siac_gsa_ordinativo - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

DELETE FROM siac.siac_gsa_ordinativo
WHERE ente_proprietario_id = p_ente_proprietario_id;

esito:= '  Fine eliminazione dati pregressi into siac_gsa_ordinativo - '||clock_timestamp();
return next;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

 esito:='  Verifica fase bilancio annoBilancio-1='||(annoBilancio-1)::varchar||'.';
 -- Aggiungere parametro per non estrarre anno-1
 select 1 into codResult
 from siac_t_bil bil,siac_t_periodo per,
	       siac_r_bil_fase_operativa r, siac_d_fase_operativa fase
 where per.ente_proprietario_id=p_ente_proprietario_id  
 and     per.anno::integer=annoBilancio-1
 and     bil.periodo_id=per.periodo_id
 and     r.bil_id=bil.bil_id 
 and     fase.fase_operativa_id=r.fase_operativa_id
 and     fase.fase_operativa_code in (ESERCIZIO_GESTIONE_ST,ESERCIZIO_CONSUNTIVO_ST);
 if codResult is not null then
        codResult:=null;
        select 1 into codResult
        from siac_d_gestione_livello liv,siac_d_gestione_tipo tipo
        where tipo.ente_proprietario_id=p_ente_proprietario_id
        and      tipo.gestione_tipo_code='SCARICO_GSA_ORD_ANNO_PREC'  
        and      liv.gestione_tipo_id=tipo.gestione_tipo_id
        and      liv.gestione_livello_code=(annoBilancio-1)::varchar
        and      tipo.data_cancellazione is null 
        and      tipo.validita_fine is null 
        and      liv.data_cancellazione is null 
        and      liv.validita_fine is null;
		if codResult is not null then
			    	annoBilancio_ini:=annoBilancio-1;
	    end if;  
 end if;	   
 if   codResult is not null then
	           esito:=esito||'  Carico ordinativi GSA annoBilancio='||annoBilancio_ini::varchar||' e annoBilancio='||annoBilancio::varchar||'.';
 else       esito:=esito||'  Carico ordinativi GSA annoBilancio='||annoBilancio::varchar||'.';
 end if;
 RETURN next;

 insert into
 siac_gsa_ordinativi_log_elab 
 (  
 ente_proprietario_id,
 fnc_name ,
 fnc_parameters ,
 fnc_elaborazione_inizio ,
 fnc_user
 )
 values 
 (
 p_ente_proprietario_id,
 'fnc_siac_gsa_ordinativo',
 esito,
 clock_timestamp(),
 v_user_table
 );  


 esito:='  Carico ordinativi GSA annoBilancio='||annoBilancio_ini::varchar||' e annoBilancio='||annoBilancio::varchar||'. Prima di inizio ciclo.';
 RETURN next;
 for annoRec in
 (
    select *
    from
   	(select annoBilancio_ini anno_elab
     union
     select annoBilancio anno_elab
    ) query
    order by 1
)
loop
    esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo.';
    RETURN next;
   
    if p_tipo_ord in ('I','E') then 
   	 -- scarico ordinativi di incasso
     esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo per incassi.';
     RETURN next;
     return query  select fnc_siac_gsa_ordinativo_incasso (annoRec.anno_elab::varchar,p_ente_proprietario_id, p_data);
     
     esito:= '  Inizio caricamento incassi into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;	
     insert into siac_gsa_ordinativo 
     (
	     ente_proprietario_id,
   	     anno_bilancio,
   	     ord_tipo,
	     ord_anno,
		 ord_numero,
		 ord_desc,
		 ord_stato_code,
	 	 ord_data_emissione,
		 ord_data_firma,
		 ord_data_quietanza,
		 ord_data_annullo,
   	 	 numero_capitolo,
    	 numero_articolo,
      	 capitolo_desc,
    	 soggetto_code,
    	 soggetto_desc,
		 pdc_fin_liv_1,
		 pdc_fin_liv_2,
		 pdc_fin_liv_3,
		 pdc_fin_liv_4,
		 pdc_fin_liv_5,
	 	 ord_sub_numero, 
	 	 ord_sub_importo,
	  	 ord_sub_desc,
	     movgest_anno,
	     movgest_numero,
	     movgest_sub_numero,
	     movgest_gsa,
	     movgest_attoamm_tipo_code,
	     movgest_attoamm_anno,
	     movgest_attoamm_numero,
	     movgest_attoamm_sac,
	     liq_attoamm_tipo_code,
	     liq_attoamm_anno,
	     liq_attoamm_numero,
	     liq_attoamm_sac
     )
     select 
         inc.ente_proprietario_id,
   	     inc.anno_bilancio,
   	     'E',
	     inc.ord_anno,
		 inc.ord_numero,
		 inc.ord_desc,
		 inc.ord_stato_code,
	 	 to_char(inc.ord_data_emissione,'YYYYMMDD'),
		 to_char(inc.ord_data_firma,'YYYYMMDD'),
		 to_char(inc.ord_data_quietanza,'YYYYMMDD'),
		 to_char(inc.ord_data_annullo,'YYYYMMDD'),
   	 	 inc.numero_capitolo,
    	 inc.numero_articolo,
      	 inc.capitolo_desc,
    	 inc.soggetto_code,
    	 inc.soggetto_desc,
		 inc.pdc_fin_liv_1,
 		 inc.pdc_fin_liv_2,
		 inc.pdc_fin_liv_3,
 		 inc.pdc_fin_liv_4,
 		 inc.pdc_fin_liv_5,
	 	 inc.ord_sub_numero, 
	 	 inc.ord_sub_importo,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	  	 --inc.ord_sub_desc,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	 	 --replace(replace(substring( inc.ord_desc,1,255),chr(10),''),chr(13),''),
translate
( 
substring( inc.ord_desc,1,255),
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar||
chr(59)::varchar, -- 06.09.2023 Sofia SIAC-TASK-174 ;  con , 
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(44)::varchar), -- 06.09.2023 Sofia SIAC-TASK-174 ;  con ,
	     inc.movgest_anno,
	     inc.movgest_numero,
	     inc.movgest_sub_numero,
	     inc.movgest_gsa,
	     inc.movgest_attoamm_tipo_code,
	     inc.movgest_attoamm_anno,
	     inc.movgest_attoamm_numero,
	     inc.movgest_attoamm_sac,
	     inc.ord_attoamm_tipo_code,
	     inc.ord_attoamm_anno,
	     inc.ord_attoamm_numero,
	     inc.ord_attoamm_sac
     from siac_gsa_ordinativo_incasso inc 
     where inc.anno_bilancio =annoRec.anno_elab
     and     inc.ente_proprietario_id =p_ente_proprietario_id ;
     
     esito:= '  Fine caricamento incassi into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;	
    end if;
    if p_tipo_ord in ('P','E') then 
      	-- scarico ordinativi di pagamento
     esito:='  Carico ordinativi GSA annoBilancio='||annoRec.anno_elab::varchar||'. In ciclo per pagamenti.';
     RETURN next;
     return query select fnc_siac_gsa_ordinativo_pagamento (annoRec.anno_elab::varchar,p_ente_proprietario_id, p_data);
     
    esito:= '  Inizio caricamento pagamenti into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
 	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;
     insert into siac_gsa_ordinativo 
     (
	     ente_proprietario_id,
   	     anno_bilancio,
   	     ord_tipo,
	     ord_anno,
		 ord_numero,
		 ord_desc,
		 ord_stato_code,
	 	 ord_data_emissione,
		 ord_data_firma,
		 ord_data_quietanza,
		 ord_data_annullo,
   	 	 numero_capitolo,
    	 numero_articolo,
      	 capitolo_desc,
    	 soggetto_code,
    	 soggetto_desc,
		 pdc_fin_liv_1,
		 pdc_fin_liv_2,
		 pdc_fin_liv_3,
		 pdc_fin_liv_4,
		 pdc_fin_liv_5,
	 	 ord_sub_numero, 
	 	 ord_sub_importo,
	  	 ord_sub_desc,
	     movgest_anno,
	     movgest_numero,
	     movgest_sub_numero,
	     movgest_gsa,
	     movgest_attoamm_tipo_code,
	     movgest_attoamm_anno,
	     movgest_attoamm_numero,
	     movgest_attoamm_sac,
	     liq_anno,
	     liq_numero,
	     liq_attoamm_tipo_code,
	     liq_attoamm_anno,
	     liq_attoamm_numero,
	     liq_attoamm_sac
     )
     select 
         pag.ente_proprietario_id,
   	     pag.anno_bilancio,
   	     'U',
	     pag.ord_anno,
		 pag.ord_numero,
		 pag.ord_desc,
		 pag.ord_stato_code,
	 	 to_char(pag.ord_data_emissione,'YYYYMMDD'),
		 to_char(pag.ord_data_firma,'YYYYMMDD'),
		 to_char(pag.ord_data_quietanza,'YYYYMMDD'),
		 to_char(pag.ord_data_annullo,'YYYYMMDD'),
   	 	 pag.numero_capitolo,
    	 pag.numero_articolo,
      	 pag.capitolo_desc,
    	 pag.soggetto_code,
    	 pag.soggetto_desc,
		 pag.pdc_fin_liv_1,
		 pag.pdc_fin_liv_2,
		 pag.pdc_fin_liv_3,
		 pag.pdc_fin_liv_4,
		 pag.pdc_fin_liv_5,
	 	 pag.ord_sub_numero, 
	 	 pag.ord_sub_importo,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
	  	 -- pag.ord_sub_desc,
	 	 -- SIAC-TASK-135 28.06.2023 Sofia
--	 	 replace(replace(substring( pag.ord_desc,1,255),chr(10),''),chr(13),''),
translate
( 
substring( pag.ord_desc,1,255),
chr(1)::varchar||
chr(2)::varchar||
chr(3)::varchar||
chr(4)::varchar||
chr(5)::varchar||
chr(6)::varchar||
chr(7)::varchar||
chr(8)::varchar||
chr(9)::varchar||
chr(10)::varchar||
chr(11)::varchar||
chr(12)::varchar||
chr(13)::varchar||
chr(14)::varchar||
chr(15)::varchar||
chr(16)::varchar||
chr(17)::varchar||
chr(18)::varchar||
chr(19)::varchar||
chr(20)::varchar||
chr(21)::varchar||
chr(22)::varchar||
chr(23)::varchar||
chr(24)::varchar||
chr(25)::varchar||
chr(26)::varchar||
chr(27)::varchar||
chr(28)::varchar||
chr(29)::varchar||
chr(30)::varchar||
chr(31)::varchar||
chr(126)::varchar||
chr(127)::varchar,
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar||
chr(32)::varchar),	 	 
	     pag.movgest_anno,
	     pag.movgest_numero,
	     pag.movgest_sub_numero,
	     pag.movgest_gsa,
	     pag.movgest_attoamm_tipo_code,
	     pag.movgest_attoamm_anno,
	     pag.movgest_attoamm_numero,
	     pag.movgest_attoamm_sac,
	     pag.liq_anno,
	     pag.liq_numero,
	     pag.liq_attoamm_tipo_code,
	     pag.liq_attoamm_anno,
	     pag.liq_attoamm_numero,
	     pag.liq_attoamm_sac
     from siac_gsa_ordinativo_pagamento pag 
     where pag.anno_bilancio =annoRec.anno_elab
     and     pag.ente_proprietario_id =p_ente_proprietario_id;
     
     esito:= '  Fine caricamento pagamenti into siac_gsa_ordinativo  annoBilancio='||annoRec.anno_elab::varchar||'-'||clock_timestamp();
     insert into
     siac_gsa_ordinativi_log_elab 
     (  
     	ente_proprietario_id,
	    fnc_name ,
	    fnc_parameters ,
	    fnc_elaborazione_inizio ,
	    fnc_user
 	 )
	 values 
	 (
	    p_ente_proprietario_id,
	    'fnc_siac_gsa_ordinativo',
	    esito,
	    clock_timestamp(),
	    v_user_table
	 );  
     return next;
    
    end if;
end loop;
   

esito:= 'Fine funzione carico ordinativi  GSA (fnc_siac_gsa_ordinativo) - '||clock_timestamp();
RETURN NEXT;
insert into
siac_gsa_ordinativi_log_elab 
(
ente_proprietario_id,
fnc_name ,
fnc_parameters ,
fnc_elaborazione_inizio ,
fnc_user
)
values 
(
p_ente_proprietario_id,
'fnc_siac_gsa_ordinativo',
esito,
clock_timestamp(),
v_user_table
);

 
update siac_gsa_ordinativi_log_elab  set fnc_elaborazione_fine = clock_timestamp(),
fnc_durata=clock_timestamp()- fnc_elaborazione_inizio
where fnc_user=v_user_table;

EXCEPTION
WHEN others THEN
  esito:='Funzione carico ordinativi GSA (fnc_siac_gsa_ordinativi terminata con errori '||sqlstate||'-'||SQLERRM;
  raise notice 'esito=%',esito;
--  RAISE NOTICE '% %-%.',esito, SQLSTATE,SQLERRM;
  return next;
END;
$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY DEFINER
COST 100 ROWS 1000;

alter function  siac.fnc_siac_gsa_ordinativo (  varchar, varchar,integer, timestamp) owner to siac;