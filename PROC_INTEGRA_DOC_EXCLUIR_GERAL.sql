DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_DOC_EXCLUIR_GERAL`$$

CREATE PROCEDURE `PROC_INTEGRA_DOC_EXCLUIR_GERAL`(
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
			DECLARE xStatusProcesso VARCHAR(10);
			DECLARE xProcessar INT DEFAULT 0;
			
   
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
      SET xCodEmp = NULL;
      SET xCodFil = NULL;
      SET xAnoSolic = NULL;
      SET xNumSolic = NULL;
      SET xStatusProcesso = NULL;
      #
      SELECT cod_emp, cod_fil, ano_solic, num_solic, status_processo
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xStatusProcesso
      FROM of_logistica.tbsolic_entradas
      WHERE chave_integracao = oChaveIntegracao;
      
      IF xCodEmp IS NOT NULL THEN
      
         IF IFNULL(xStatusProcesso,0) <= 5 THEN #OR IFNULL(xStatusProcesso,0) = 11 THEN
         
            DELETE FROM of_logistica.tbsolic_entradas
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM tbintegraSAP_Doc
            WHERE chave_integracao = oChaveIntegracao;                 
            SET RESULTADO = 1;
            SET MENSAGEM = "EXCLUSÃO REALIZADA COM SUCESSO";
             
            #Gravar LOG
            CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(@R, " ", @M),  @R, 
                      CONCAT(@M, IFNULL(CONCAT("GEM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), @R, @M);         
         ELSE
           SET RESULTADO = 0;
           SET MENSAGEM = "STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar em conferencia";
         END IF;
                 
      ELSE
         DELETE FROM tbintegraSAP_Doc
         WHERE chave_integracao = oChaveIntegracao;                 
          
         SET RESULTADO = 1;
         SET MENSAGEM = "GEM NÃO LOCALIZADA - Documento excluído apenas da integração";
         #Gravar LOG
         CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(@R, " ", @M),  @R, 
                   CONCAT(@M, IFNULL(CONCAT("GEM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), @R, @M);         
     
      END IF;
   END IF;
   
   IF (oTipoOper = 'S') THEN
   
   
      SET xCodEmp = NULL;
      SET xCodFil = NULL;
      SET xAnoSolic = NULL;
      SET xNumSolic = NULL;
      SET xStatusProcesso = NULL;
      #
      SELECT cod_emp, cod_fil, ano_solic, num_solic, status_processo
      INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xStatusProcesso
      FROM of_logistica.tbsolic_saidas
      WHERE chave_integracao = oChaveIntegracao;
      
      IF xCodEmp IS NOT NULL THEN
      
         IF IFNULL(xStatusProcesso,0) <= 1 THEN #or IFNULL(xStatusProcesso,0) = 11 THEN   
         
            DELETE FROM of_logistica.tbsolic_saidas
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM of_logistica.tbprog_entregas
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM of_logistica.tbnf_clientes
            WHERE chave_integracao = oChaveIntegracao;
            
            DELETE FROM tbintegraSAP_DocPicking
            WHERE EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                          WHERE tbintegraSAP_DocPicking.DocTipo = tbintegraSAP_Doc.DocTipo
                           AND tbintegraSAP_DocPicking.DocEntry = tbintegraSAP_Doc.DocEntry
                           AND chave_integracao = oChaveIntegracao);   
                                         
            DELETE FROM tbintegraSAP_Doc
            WHERE chave_integracao = oChaveIntegracao;                 
            
            SET RESULTADO = 1;
            SET MENSAGEM = "EXCLUSÃO REALIZADA COM SUCESSO";
            #Gravar LOG
            CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(RESULTADO, " ", MENSAGEM),  "OK", 
                      CONCAT(MENSAGEM, IFNULL(CONCAT(" GSM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), RESULTADO, MENSAGEM);         
         ELSE
            SET RESULTADO = 0;
            SET MENSAGEM = "STATUS NÃO PERMITIDO PARA ESSA OPERAÇÃO - Não pode estar aconselhada";
         END IF;
         
      ELSE
         DELETE FROM tbintegraSAP_Doc
         WHERE chave_integracao = oChaveIntegracao;                 
          
         SET RESULTADO = 1;
         SET MENSAGEM = "GSM NÃO LOCALIZADA - Documento excluído apenas da integração";

         #Gravar LOG
         CALL PROC_INTEGRA_EnviarLog('999999', CONCAT('Monitor_EXCLUSÃO ',oChaveIntegracao), CONCAT(RESULTADO, " ", MENSAGEM),  "OK", 
                   CONCAT(MENSAGEM, IFNULL(CONCAT(" GEM=>",xCodEmp,'/',xCodFil,'-',xAnoSolic,'.',xNumSolic),"")), RESULTADO, MENSAGEM);         
      
      END IF;
      
   END IF;
   
   IF (excecao = 0) THEN
      SET RESULTADO = "1";
      COMMIT;
   END IF;
   
END$$

DELIMITER ;