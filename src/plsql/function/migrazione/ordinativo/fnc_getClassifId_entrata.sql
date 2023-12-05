/*
*SPDX-FileCopyrightText: Copyright 2020 | CSI Piemonte
*SPDX-License-Identifier: EUPL-1.2
*/
create or replace function fnc_getClassifid_entrata(
	p_ord_id          INTEGER,   
	p_classif_tipo_id integer,
	p_classif_tipo_code varchar,
	p_campoDitest varchar , 
	p_numero_accertamento  varchar ,
	p_anno_esercizio  varchar ,
	enteproprietarioid integer,
    loginOperazione    varchar,
	out strMessaggio   varchar,
	out strMessaggioScarto  varchar,
	out codResult integer
    )
RETURNS record AS
$body$
DECLARE
    NVL_STR               			CONSTANT VARCHAR:='';
    v_ord_id						INTEGER			:= 0;
    v_liq_id						INTEGER 		:= 0; 
    v_classif_id				    INTEGER 		:= null; 
	v_classif_tipo_id				INTEGER 		:= null; 
	v_classif_tipo_code				INTEGER 		:= null; 
	strMessaggioFinale				varchar(4000) 	:= '';
	strMessaggioScarto				varchar(4000) 	:= '';
	dataInizioVal                   timestamp       :=null;
BEGIN
	dataInizioVal:=date_trunc('DAY', now());
	v_classif_tipo_id	:= p_classif_tipo_id; 
	v_classif_tipo_code	:= p_classif_tipo_code; 
    v_ord_id:=p_ord_id;
    
	strMessaggioFinale := 'Lettura Classificatore Id.';
		if coalesce(p_campoDitest,NVL_STR)!=NVL_STR then
            strMessaggio:='Inserimento relazione ordinativo classificatore su tab siac_r_ordinativo_class per classificatore tipo '|| v_classif_tipo_code||'.';

            select tipoPdcFinClass.classif_id into v_classif_id
            from siac_t_class tipoPdcFinClass
            where tipoPdcFinClass.classif_code=p_campoDitest and
                  tipoPdcFinClass.ente_proprietario_id=enteProprietarioId and
                  tipoPdcFinClass.data_cancellazione is null and
                  date_trunc('day',dataElaborazione)>=date_trunc('day',tipoPdcFinClass.validita_inizio) and
                  (date_trunc('day',dataElaborazione)<=date_trunc('day',tipoPdcFinClass.validita_fine) or tipoPdcFinClass.validita_fine is null) and
                  tipoPdcFinClass.classif_tipo_id = v_classif_tipo_id;

            if coalesce(v_classif_id,NVL_STR)!=NVL_STR then
            	insert into siac_r_ordinativo_class(classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione )
            	values( v_classif_id,v_ord_id ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione ) ;
			ELSE
            	strMessaggioScarto := 'classificatore non definito per ordinativo pdc_finanziario --> '|| p_campoDitest;
            end if;
         end if;

		if v_classif_id is null then
			strMessaggio:='cerco di reperire il classificatore dall''accertamento associato numero--> '||p_numero_accertamento||' anno -->'|| p_anno_esercizio ||'.';
        select
               siac_r_movgest_class.classif_id into v_classif_id
          from
               migr_accertamento,
               siac_r_migr_accertamento_movgest_ts ,
               siac_r_movgest_class
         where
			   migr_accertamento.migr_accertamento_id =siac_r_migr_accertamento_movgest_ts.migr_accertamento_id 
           and siac_r_migr_accertamento_movgest_ts.movgest_ts_id = siac_r_movgest_class.movgest_ts_id  
           and migr_liquidazione.numero_accertamento = p_numero_accertamento 
           and migr_liquidazione.anno_esercizio = p_anno_esercizio
           and migr_liquidazione.ente_proprietario_id= enteproprietarioid 		   
           and siac_r_migr_accertamento_movgest_ts.ente_proprietario_id= enteproprietarioid 
           and siac_r_movgest_class.ente_proprietario_id= enteproprietarioid 
           and date_trunc('day',dataElaborazione)>=date_trunc('day',siac_r_movgest_class.validita_inizio) 
           and (date_trunc('day',dataElaborazione)<date_trunc('day',siac_r_movgest_class.validita_fine) or siac_r_movgest_class.validita_fine is null);

           if v_classif_id is NULL then
                strMessaggioScarto := 'classificatore non definito per accertamento associato al''ordinativo ';
                codResult :=-1;
	       else
                insert into siac_r_ordinativo_class(classif_id ,ord_id ,validita_inizio ,validita_fine ,ente_proprietario_id ,data_cancellazione ,login_operazione )
                values( v_classif_id ,v_ord_id ,dataInizioVal ,null ,enteproprietarioid ,null ,loginOperazione );
           end if;


        end if;
		codResult :=0;
    exception
	when others  THEN
		raise notice '% % % ERRORE DB: % %',strMessaggioFinale,v_ord_id,strMessaggio,SQLSTATE, substring(upper(SQLERRM) from 1 for 1500);
        codResult :=-1;
	END;
	$body$
LANGUAGE 'plpgsql'
VOLATILE
CALLED ON NULL INPUT
SECURITY INVOKER
COST 100;