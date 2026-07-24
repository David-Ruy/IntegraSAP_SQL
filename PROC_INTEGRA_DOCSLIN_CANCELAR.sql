DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_DOCSLIN_CANCELAR`$$

CREATE PROCEDURE `PROC_INTEGRA_DOCSLIN_CANCELAR`(
	IN oTipoOper				     VARCHAR(10),
	IN oChaveIntegracao  VARCHAR(100),
	# Parametros de Retorno
	OUT RESULTADO           VARCHAR(5),
	OUT MENSAGEM            VARCHAR(500)
)
BLOCO1:BEGIN
   #@Author David Ruy <2023-07-02>
   #Cancelar Documentos de Entradas e Saídas no SLIN
   #Documento não pode estar em conferencia
   DECLARE xDthrAux   DATETIME DEFAULT NOW();
			DECLARE excecao INT DEFAULT 0;
			DECLARE xCodEmp VARCHAR(03);
			DECLARE xCodFil VARCHAR(03);
			DECLARE xAnoSolic VARCHAR(04);
			DECLARE xNumSolic VARCHAR(10);
			
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   START TRANSACTION;
   
   
   IF (oTipoOper = 'E') THEN
      IF EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas
                 WHERE chave_integracao = oChaveIntegracao AND status_processo <= 5) 
         OR EXISTS (SELECT 1 FROM tbintegraSAP_Doc WHERE chave_integracao = oChaveIntegracao AND StatusDoc <= 1) THEN
          
          UPDATE of_logistica.tbsolic_entradas
          SET status_processo = 11, status_solic = 9,
              dthr_cancelamento = xDthrAux, 
              usu_cancelamento = "999999",
              observ_conf01 = "Cancelamento via Monitor de Integração (1)"
          WHERE chave_integracao = oChaveIntegracao;
          
          DELETE FROM of_logistica.tbsolic_entradas_acons
          WHERE EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas 
                        WHERE tbsolic_entradas.cod_emp   = tbsolic_entradas_acons.cod_emp
                          AND tbsolic_entradas.cod_fil   = tbsolic_entradas_acons.cod_fil
                          AND tbsolic_entradas.ano_solic = tbsolic_entradas_acons.ano_solic
                          AND tbsolic_entradas.num_solic = tbsolic_entradas_acons.num_solic
                          AND chave_integracao = oChaveIntegracao);
          
          UPDATE tbintegraSAP_Doc
          SET StatusDoc = 9, 
              StatusSLIN = 9,
              dthr_cancel = xDthrAux,
              Observacoes = CONCAT(IFNULL(Observacoes,''),' Cancelamento via monitor de integração(1)')
          WHERE chave_integracao = oChaveIntegracao;
          
          SET RESULTADO = 1;
          SET MENSAGEM = "CANCELAMENTO REALIZADO COM SUCESSO";
      ELSE
          SET RESULTADO = 0;
          SET MENSAGEM = "GEM NÃO LOCALIZADA OU STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar em conferencia";
      END IF;
   END IF;
   
   IF (oTipoOper = 'S') THEN
      IF EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas
                 WHERE chave_integracao = oChaveIntegracao AND status_processo <= 1) 
         OR EXISTS (SELECT 1 FROM tbintegraSAP_Doc WHERE chave_integracao = oChaveIntegracao AND StatusDoc <= 1) THEN
                
         SET xCodEmp = NULL;
         SET xCodFil = NULL;
         SET xAnoSolic = NULL;
         SET xNumSolic = NULL;
         #
         SELECT cod_emp, cod_fil, ano_solic, num_solic 
         INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic
         FROM of_logistica.tbsolic_saidas
         WHERE chave_integracao = oChaveIntegracao;
         
         CALL of_logistica.PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO(xCodEmp, xCodFil, xAnoSolic, xNumSolic, @R, @M);
          
          #Bloco Subistituido pelo chamada da procedure acima
          /*
          UPDATE of_logistica.tbsolic_saidas
          SET status_processo = 11, status_solic = 9,
              dthr_cancelamento = xDthrAux, 
              usu_cancelamento = "999999",
              observ_conf01 = "Cancelamento via Monitor de Integração (1)"
          WHERE chave_integracao = oChaveIntegracao;
          
          DELETE FROM of_logistica.tbsolic_saidas_acons
          WHERE EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas 
                        WHERE tbsolic_saidas.cod_emp   = tbsolic_saidas_acons.cod_emp
                          AND tbsolic_saidas.cod_fil   = tbsolic_saidas_acons.cod_fil
                          AND tbsolic_saidas.ano_solic = tbsolic_saidas_acons.ano_solic
                          AND tbsolic_saidas.num_solic = tbsolic_saidas_acons.num_solic
                          AND chave_integracao = oChaveIntegracao);

          UPDATE of_logistica.tbprog_entregas
          SET tbprog_entregas.status_entre = 9,
              tbprog_entregas.status_baixa = 4,
              tbprog_entregas.ano_viagem = NULL,
              tbprog_entregas.num_viagem = NULL,
              tbprog_entregas.usu_alt = '999999',
              tbprog_entregas.dthr_alt = xDthrAux,
              tbprog_entregas.observ_baixa = "Cancelamento via Monitor de Integração (1)"
          WHERE chave_integracao = oChaveIntegracao;

          */
          
         IF (@M = "OK" OR xCodEmp IS NULL) THEN
            UPDATE tbintegraSAP_Doc
            SET StatusDoc = 9, 
                StatusSLIN = 9,
                dthr_cancel = xDthrAux,
                Observacoes = CONCAT(IFNULL(Observacoes,''),' Cancelamento via monitor de integração(1)')
            WHERE chave_integracao = oChaveIntegracao;
            
            
            SET RESULTADO = 1;
            SET MENSAGEM = "CANCELAMENTO REALIZADO COM SUCESSO";
         ELSE
            SET RESULTADO = 0;
            SET MENSAGEM = @M;
         END IF;
       
      ELSE
          SET RESULTADO = 0;
          SET MENSAGEM = "GSM NÃO LOCALIZADA OU STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar aconselhada";
      END IF;
   END IF;
   IF (excecao = 0) THEN
      SET RESULTADO = "1";
      COMMIT;
   END IF;
END$$

DELIMITER ;