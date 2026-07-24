DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_LimparPicking`$$

CREATE PROCEDURE `PROC_INTEGRA_LimparPicking`(
   IN oIdPicking       INT,
   # Parametros de Retorno
   OUT RESULTADO       INT,
   OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   #@Reviser David Ruy <2022/04/29> Concatenar IdPickingAnt para armazenar histórico de Pickings
   */
   
   
   DECLARE xQtdeRegs   INT DEFAULT 0;
   DECLARE excecao 	   INT DEFAULT 0;
   
   /*
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;
   */
   
   START TRANSACTION;
   
   
   UPDATE tbintegraSAP_Doc
   SET idPickingAnt = CONCAT(IFNULL(idPickingAnt,''),IF(idPickingAnt IS NULL, '','/'),idPicking),
       idPicking = NULL,
       StatusAnt = StatusDoc,
       StatusDoc = 7      #Processo de Atualização SAP (Divergencias dentro da tolerancia)
   WHERE idPicking = oIdPicking; 
 
    IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_LimparPicking");
      #SELECT RESULTADO, MENSAGEM;
      ROLLBACK;
   ELSE
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- PROC_INTEGRA_LimparPicking [",xQtdeRegs,"]");
      COMMIT;
   END IF;
END$$

DELIMITER ;