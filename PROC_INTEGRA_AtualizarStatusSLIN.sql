DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarStatusSLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarStatusSLIN`(
	IN oCodUsuario				      VARCHAR(10),
	IN oDocEntry            INT,
	IN oDocTipo             VARCHAR(100),
	IN oDocNum              VARCHAR(30),
	IN oNewStatus           INT,
	
	# Parametros de Retorno
	OUT RESULTADO           VARCHAR(5),
	OUT MENSAGEM            VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt    VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodEmp    VARCHAR(03);
   DECLARE xCodFil    VARCHAR(03);
   DECLARE xAnoSolic  VARCHAR(04);
   DECLARE xNumSolic  VARCHAR(10);
   DECLARE XNumAgrup  VARCHAR(10);
   DECLARE xStatusDoc VARCHAR(10);
   DECLARE xflg_obriga_checkout_retornoPV TINYINT;
   DECLARE xcampo_qtde_volumes TINYINT;
   
				
   DECLARE excecao INT DEFAULT 0;
   #Nesta procedure não tem transaction porque é chamada da PROC_INTEGRA_AtualizarStatusDocEntry
   #que controla a transação
   
   #@Reviser David Ruy <2021-07-12>
   #Utilização do agrupamento para atualizar dthr_retorno_integracao (PV)
   #Ajuste quando oNewStatus = 0, limpa o campo de dthr_retorno_integração (PV)
   #@Reviser David Ruy <2021-08-30> Ajuste TD-<E>/<S> para atualizar
   #@Reviser David Ruy <2023-04-24> PA000
   #@Reviser David Ruy <2023-05-02> Atualização tbintegraSAP_ContagemTopo
   #@Reviser David Ruy <2023-06-13> Atualização SAIDA_AVULSA
   #@Reviser David Ruy <2023-07-19> Desconsidera GSM´s que flg_conferencia_volume_check_tp = 1 e que não concluiu o checkout
   #@Reviser David Ruy <2024-07-16> Alteração variável oDocNum Varchar(30)   
   #@Reviser David Ruy <2025/05/21> Ajuste xcampo_qtde_volumes (tbintegraSAP_Parametros.flg_campo_volumes => 0=CHECKOUT / 1=EMB_VOL / 2=STRING_CHECKOUT)
   #@Reviser David Ruy <2025/11/25> Ajuste condição oDocTipo like 'PA%'
   
   SELECT flg_obriga_checkout_retornoPV, flg_campo_volumes
   INTO xflg_obriga_checkout_retornoPV, xcampo_qtde_volumes
   FROM tbintegraSAP_parametros
   LIMIT 1;
   
   
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada - Status não relevante";
   
   IF oDocTipo = 'MOVTO' THEN
      SET MENSAGEM = "Atualização realizada com sucesso";
      UPDATE of_logistica.tbwms_manut_lote tbwmsManut
      SET tbwmsManut.dthr_retorno_integracao = NOW()
      WHERE tbwmsManut.id_manutencao = oDocEntry;
      
   ELSEIF SUBSTRING(oDocTipo,1,12) = 'SAIDA_AVULSA' THEN
  
      SET MENSAGEM = "Atualização realizada com sucesso";
      SET xCodEmp = SUBSTRING(oDocTipo, 13,03);
      SET xCodFil = SUBSTRING(oDocTipo, 16,03);
      SET xAnoSolic = SUBSTRING(oDocTipo, 19,04);
      SET xNumSolic = SUBSTRING(oDocTipo, 23,10);
      
      UPDATE of_logistica.tbsolic_saidas tbSaidas
      SET tbSaidas.dthr_retorno_integracao = NOW()
      WHERE tbSaidas.cod_emp   = xCodEmp
        AND tbSaidas.cod_fil   = xCodFil
        AND tbSaidas.ano_solic = xAnoSolic
        AND tbSaidas.num_solic =xNumSolic;
      
   ELSEIF SUBSTRING(oDocTipo,01,08) = 'CONTAGEM' THEN
   
      SET MENSAGEM = "Atualização realizada com sucesso";
      
      IF oNewStatus = 0 THEN
         #oDocTipo = CONTAGEM + E/S + cod_emp + cod_fil + ano_solic + num_solic
         
         SET xCodEmp = SUBSTRING(oDocTipo, 10,03);
         SET xCodFil = SUBSTRING(oDocTipo, 13,03);
         SET xAnoSolic = SUBSTRING(oDocTipo, 16,04);
         SET xNumSolic = SUBSTRING(oDocTipo, 20,10);
         
         #Criar Contagem
         UPDATE tbintegraSAP_ContagemTopo tbCont
         SET tbCont.Id = oDocEntry
         WHERE tbCont.cod_emp   = xCodEmp
           AND tbCont.cod_fil   = xCodFil
           AND tbCont.ano_solic = xAnoSolic
           AND tbCont.num_solic = xnumSolic;
      ELSE 
         #Confirmar Contagem
         UPDATE tbintegraSAP_ContagemTopo tbCont
         SET tbCont.dthr_retorno_integracao = NOW()
         WHERE tbCont.Id = oDocEntry;
           
      END IF;
      
      
      /*SET xCodEmp = SUBSTRING(oDocTipo, 10,03);
      SET xCodFil = SUBSTRING(oDocTipo, 13,03);
      SET xAnoSolic = SUBSTRING(oDocTipo, 16,04);
      SET xNumSolic = SUBSTRING(oDocTipo, 20,10);
      #Criar e Confirmar Contagem
      UPDATE tbintegraSAP_ContagemTopo tbCont
      SET tbCont.Id = oDocEntry,
          tbCont.dthr_retorno_integracao = NOW()
      WHERE tbCont.cod_emp   = xCodEmp
        AND tbCont.cod_fil   = xCodFil
        AND tbCont.ano_solic = xAnoSolic
        AND tbCont.num_solic = xnumSolic;          
      */
      
        
   #ELSEIF oDocTipo IN ('PV', 'OP') AND oNewStatus = 6 THEN
   ELSEIF oDocTipo IN ('PV', 'OP', 'TD-S') THEN 
   
      SELECT tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic, tbSaidas.num_agrup_geral, 
             tbintegraSAP_Doc.StatusDoc
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, XNumAgrup, xStatusDoc
      FROM of_logistica.tbsolic_saidas tbSaidas
      INNER JOIN tbintegraSAP_Doc ON 
            tbintegraSAP_Doc.cod_emp     = tbSaidas.cod_emp
        AND tbintegraSAP_Doc.cod_fil     = tbSaidas.cod_fil
        AND tbintegraSAP_Doc.ano_solic   = tbSaidas.ano_solic
        AND tbintegraSAP_Doc.num_solic   = tbSaidas.num_solic
        AND tbintegraSAP_Doc.TipoDocSLIN = "S"
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
        

      IF XNumAgrup IS NOT NULL THEN

         UPDATE of_logistica.tbsolic_saidas tbSaidas
         SET tbSaidas.dthr_retorno_integracao = IF(xStatusDoc >= 6, NOW(),NULL)  #IF(oNewStatus=0,NULL,NOW())
         WHERE tbSaidas.num_agrup_geral = XNumAgrup
           AND tbSaidas.status_processo >= 8
           AND tbSaidas.dthr_cancelamento IS NULL
           AND (tbSaidas.dthr_bloqueio_ini IS NULL OR (tbSaidas.dthr_bloqueio_ini IS NOT NULL AND tbSaidas.dthr_bloqueio_fin IS NOT NULL))
           #AND IF(xflg_obriga_checkout_retornoPV = 1, dthr_final_picking IS NOT NULL, TRUE);
           AND IF(xflg_obriga_checkout_retornoPV = 1, dthr_final_picking IS NOT NULL, 
                                                      IF(xcampo_qtde_volumes IN (2,3), IFNULL(tbSaidas.qtde_volume_checkout,0) > 0, TRUE));

      ELSE

         UPDATE of_logistica.tbsolic_saidas tbSaidas
         SET tbSaidas.dthr_retorno_integracao = IF(xStatusDoc >= 6, NOW(),NULL) #IF(oNewStatus=0,NULL,NOW())
         WHERE cod_emp   = xCodEmp
           AND cod_fil   = xCodFil
           AND ano_solic = xAnoSolic
           AND num_solic = xNumSolic;

      END IF;
      
      #@Reviser David Ruy <2020-08-28>
      #Atualiza as quantidades da GSM finalizada no TMS, envia FRETE = Null para não atualizar as informações
      IF oDocTipo IN ('PV','TD-S') AND xStatusDoc = 6 THEN
         CALL PROC_INTEGRA_TMS_GERAR_ENTREGAS(xCodEmp, xCodFil, xAnoSolic, xnumSolic, NULL, NULL, NULL, @R, @M);
      END IF;
      
      SET MENSAGEM = "Atualização (Saída) realizada com sucesso";
  
   ELSEIF (oDocTipo IN ('NE', 'E-RM', 'E-NE', 'DV', 'TD-E') OR oDocTipo LIKE 'PA%') AND oNewStatus = 6 THEN
      SELECT tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic,
             tbintegraSAP_Doc.StatusDoc
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xStatusDoc
      FROM of_logistica.tbsolic_entradas tbEntradas
      INNER JOIN tbintegraSAP_Doc ON 
            tbintegraSAP_Doc.cod_emp     = tbEntradas.cod_emp
        AND tbintegraSAP_Doc.cod_fil     = tbEntradas.cod_fil
        AND tbintegraSAP_Doc.ano_solic   = tbEntradas.ano_solic
        AND tbintegraSAP_Doc.num_solic   = tbEntradas.num_solic
        AND tbintegraSAP_Doc.TipoDocSLIN = "E"
      WHERE DocEntry = oDocEntry
        AND DocTipo  = oDocTipo
        AND DocNum   = oDocNum;
        
      UPDATE of_logistica.tbsolic_entradas tbEntradas
      SET tbEntradas.dthr_retorno_integracao = IF(xStatusDoc >= 6, NOW(),NULL) #NOW()
      WHERE cod_emp   = xCodEmp
        AND cod_fil   = xCodFil
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
        
      SET MENSAGEM = "Atualização (Entrada) realizada com sucesso";
      
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL (PROC_INTEGRA_AtualizarStatusSLIN) - Verifique com o Administrador";
   END IF;
END$$

DELIMITER ;