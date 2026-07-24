DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarTMS_NFeVendas`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarTMS_NFeVendas`(
   IN oDocEntry      INT
  ,IN oDocTipo       VARCHAR(10)
  ,IN oDocNum        VARCHAR(10)
  ,IN oChaveIntegra  VARCHAR(50)
  ,IN oChaveNFE      VARCHAR(50)
  ,IN oValorNFE      VARCHAR(50)
  ,OUT RESULTADO     INT
  ,OUT MENSAGEM      VARCHAR(100)
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-12-06>
   #@Reviser David Ruy <2024-12-26> #Pega Id_NF para poder atualizar tbprog_entregas
   #@Reviser David Ruy <2026-05-21> #Implementada rotina de Transação e controle de exceção
   ********************************************************************************************/
   DECLARE xIdNF              INT;
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE xNumNFE             VARCHAR(10);
   DECLARE xSerieNFE           VARCHAR(03);
   DECLARE xValorNFE           DECIMAL(18,6) DEFAULT 0;
   #DECLARE RESULTADO          INT DEFAULT 1;
   #DECLARE MENSAGEM           VARCHAR(500);
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
      GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
   END;

   START TRANSACTION;   
   
   
   
   IF IFNULL(oValorNFE,'') <> '' THEN
      SET xValorNFE = CAST(oValorNFE AS DECIMAL(18,6));
   END IF;
   
   IF oChaveNFE = 'IntegraSAP - Chave não localizada' THEN
      SET oChaveNFE = NULL;
      SET xNumNFE = NULL;
   ELSE
      #SET xSerieNFE = SUBSTRING(oChaveNFE, 22, 03); SET xSerieNFE = TRIM(LEADING '0' FROM xSerieNFE);
      SET xNumNFE = SUBSTRING(oChaveNFE, 26, 09); SET xNumNFE = TRIM(LEADING '0' FROM xNumNFE);
   END IF;
   
   IF (oChaveIntegra = "") THEN
      #Pega Id_NF para poder atualizar tbprog_entregas
      SELECT id_nf INTO xIdNF 
      FROM of_logistica.tbnf_clientes
      WHERE chave_nfe = oChaveNFE;  
   
      #Limpa NF´ canceladas
      UPDATE of_logistica.tbnf_clientes
      SET chave_nfe = NULL
      WHERE chave_nfe = oChaveNFE;
      
      UPDATE of_logistica.tbprog_entregas
      SET num_nf_aux = NULL
      #WHERE num_nf_aux = xNumNFE;
      WHERE id_nf = xIdNF;
   ELSE   
      #Atualiza NF / DANFE
      UPDATE of_logistica.tbnf_clientes
      SET chave_nfe = oChaveNFE,
          #vlr_tot_nf = IF(xValorNFE < vlr_tot_nf , vlr_tot_nf, xValorNFE)
          vlr_tot_nf = IFNULL(xValorNFE, vlr_tot_nf)
      WHERE chave_integracao = oChaveIntegra;
      
      UPDATE of_logistica.tbprog_entregas
      SET num_nf_aux = xNumNFE
      WHERE chave_integracao = oChaveIntegra;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
      ROLLBACK;
   ELSE    
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Processo Realizado com sucesso!';
       COMMIT;
   END IF;
   
END$$

DELIMITER ;