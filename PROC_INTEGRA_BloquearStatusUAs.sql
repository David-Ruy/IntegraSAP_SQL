DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_BloquearStatusUAs`$$

CREATE PROCEDURE `PROC_INTEGRA_BloquearStatusUAs`(
   oCodUsuario    VARCHAR(30),
   oDocTipo            VARCHAR(30),
   oDocEntry           VARCHAR(30),
   oDocNum             VARCHAR(30),
   # Parametros de Retorno
   OUT RESULTADO              INT,
   OUT MENSAGEM               VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************/
  # @Created David Ruy <2026/03/26>
  # Esta procedure atualiza as UA´s de uma GEM (Ordem de Produção) com status para bloquear conforme necessário
  # @Reviser David Ruy <2026-04-17> Atualização de PROC_WMS_ARMAZEM_ALTERAR_STATUS_UA para gerar log da alteração do Status
  /************************************************************************/
   DECLARE excecao 	       INT(6) DEFAULT 0;
   DECLARE _RESULTADO      INT DEFAULT 0;
   DECLARE _MENSAGEM       VARCHAR(500);
   DECLARE xCodEmp         VARCHAR(03);
   DECLARE xCodFil         VARCHAR(03);
   DECLARE xAnoSolic       VARCHAR(04);
   DECLARE xNumSolic       VARCHAR(10);
   DECLARE xNumItem        VARCHAR(06);
   DECLARE xItemCode       VARCHAR(30);
   DECLARE xnum_lote       VARCHAR(30);
   DECLARE xsequencia_lote INT;
   
   DECLARE xDocTipo         VARCHAR(10);
   DECLARE xDocEntry        VARCHAR(30);
   DECLARE xDocNum          VARCHAR(30);
   DECLARE xChaveIntegracao VARCHAR(100);
   DECLARE xdthr_confirm    VARCHAR(20);
   DECLARE xCodigoStatus    VARCHAR(10);
   
   #Verificar se tem transação nas procedures
   #Se tiver, lascou
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       IF xCodEmp IS NOT NULL THEN
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',
             CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao," ",MENSAGEM) );
       ELSE
          SET MENSAGEM  = of_logistica.fnMensagemExcecao(
             CONCAT('ERRO Atualização UA´s : ',MENSAGEM) );
       END IF;
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
   
   #Busca o Status "Próprio para Produção Automática"
   #Isso serve para deixar "bloqueadas" as UA´s, até que o pedido com os lotes vinculados seja integrado
   SELECT cod_status INTO xCodigoStatus 
   FROM tbintegraSAP_DeParaStatus_Armazem
   WHERE descr_armazem = 'Produção automatica';
   
   
   #Pega os dados da GEM / GSM com base no documento referenciado nos parametros
   SELECT cod_emp, cod_fil, ano_solic, num_solic, chave_integracao
   INTO xCodEmp, xCodFil, xAnoSolic, xNumSolic, xChaveIntegracao
   FROM tbintegraSAP_Doc
   WHERE DocTipo = oDocTipo
     AND DocEntry = oDocEntry
     AND DocNum   = oDocNum;
     
     
   IF xCodEmp IS NULL THEN 
      SET RESULTADO = 0;
      SET MENSAGEM  = "Não existem documentos no SLIN vinculados a esse processo - operação não realizada";
      LEAVE BLOCO1;
   END IF;
   

   SELECT dthr_confirm INTO xdthr_confirm
   FROM of_logistica.tbsolic_entradas
   WHERE chave_integracao = xChaveIntegracao;
   
   
   IF xdthr_confirm IS NULL THEN
      SET RESULTADO = 0;
      SET MENSAGEM  = "GEM não confirmada, operação não pode ser realizada";
      LEAVE BLOCO1;   
   END IF;
   
   #Gera tabela com as UA´s a bloquear
   DROP TEMPORARY TABLE IF EXISTS tbTMP_AtuStatus;
   CREATE TEMPORARY TABLE tbTMP_AtuStatus
      SELECT num_lote, sequencia_lote, 0 AS flag FROM of_logistica.tbwms_estoque
      WHERE cod_emp   = xCodEmp
        AND cod_fil   = xCodFil 
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
        
   #Bloqueia as UA´s (Status "Produção Automática")
   WHILE EXISTS (SELECT 1 FROM tbTMP_AtuStatus WHERE flag = 0) DO
      SELECT num_lote, sequencia_lote INTO xnum_lote, xsequencia_lote
      FROM tbTMP_AtuStatus WHERE flag = 0 LIMIT 1;
      
      CALL of_logistica.PROC_WMS_ARMAZEM_ALTERAR_STATUS_UA(xCodEmp, xCodFil, xnum_lote, xsequencia_lote,
                 xCodigoStatus, CONCAT('Integração - Bloqueio UA Reservada OP',oDocNum), '999999', NULL);     
      
      UPDATE tbTMP_AtuStatus 
      SET flag = 1
      WHERE num_lote = xnum_lote AND sequencia_lote = xsequencia_lote;
   
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_AtuStatus;
   
   
   IF excecao = 0 THEN
      #COMMIT;
      SET RESULTADO = 1;
      IF MENSAGEM = "" THEN
         SET MENSAGEM = CONCAT('Atualização Status de UA´s Concluída com sucesso - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      ELSE
         SET MENSAGEM = CONCAT(MENSAGEM," | ",CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      END IF;
   ELSE
      #ROLLBACK;
      
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT('ERRO Atualização Status de UA´s - GEM : ',CAST(xCodEmp AS UNSIGNED),'/',CAST(xCodFil AS UNSIGNED),'-',CAST(xNumSolic AS UNSIGNED),'.',xAnoSolic," ",xChaveIntegracao);
      
      #Verificar Log
      #CALL PROC_INTEGRA_EnviarLog('999999',
      #       IF(oChavePedido IN ("PV","OP","TD-S","NS"), 'PROC_INTEGRA_BloquearStatusUAs', 'PROC_INTEGRA_GerarGEMItem'),
      #         CONCAT('NÃO Inserido/Atualizado ',oChavePedido,oDocEntry,'-',oNumPedido,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);      
   END IF;
   
      
      
   
END$$

DELIMITER ;