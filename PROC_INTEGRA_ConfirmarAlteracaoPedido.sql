DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ConfirmarAlteracaoPedido`$$

CREATE PROCEDURE `PROC_INTEGRA_ConfirmarAlteracaoPedido`(
   IN oDocEntry      INT,
   IN oDocNum        INT,
   IN oDocTipo       VARCHAR(10),
   IN oLineNum       INT,
   # Parametros de Retorno
   OUT RESULTADO     INT,
   OUT MENSAGEM      VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE excecao 	 INT DEFAULT 0;
   
   /*DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;*/
   
   START TRANSACTION;
   
   UPDATE of_logistica.tbsolic_saidas_item_integra_alteracao tbAlteracao
   INNER JOIN tbintegraSAP_DocItem DocItem ON
              DocItem.cod_emp   = tbAlteracao.cod_emp 
          AND DocItem.cod_fil   = tbAlteracao.cod_fil 
          AND DocItem.ano_solic = tbAlteracao.ano_solic 
          AND DocItem.num_solic = tbAlteracao.num_solic 
          AND DocItem.num_item  = tbAlteracao.num_item
   SET tbAlteracao.dthr_atu_integra = NOW()
   WHERE DocItem.DocEntry = oDocEntry
     AND DocItem.DocTipo  = oDocTipo
     AND DocItem.DocNum   = oDocNum
     AND DocItem.LineNum  = oLineNum;
   UPDATE tbintegraSAP_Doc
   SET  StatusAnt = IF(StatusDoc=7,StatusDoc, StatusAnt)
       ,StatusDoc = IF(StatusDoc=7,3, StatusDoc) 
       ,dthr_alt  = NOW()
       ,usu_alt   = "999999"
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND DocNum   = oDocNum;
     
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ConfirmarAtuAlteracao [",CONCAT(oDocEntry,'-',oDocTipo,oDocNum,'-',oLineNum),"]");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Alterações processadas com sucesso (PROC_INTEGRA_ConfirmarAtuAlteracao) [",CONCAT(oDocEntry,'-',oDocTipo,oDocNum,'-',oLineNum),"]");
   END IF;
END$$

DELIMITER ;