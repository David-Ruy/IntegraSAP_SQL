DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarStatusTMS`$$
                  
CREATE PROCEDURE `PROC_INTEGRA_AtualizarStatusTMS`(
   IN oDocEntry      INT
  ,IN oDocTipo       VARCHAR(10)
  ,IN oDocNum        VARCHAR(10)
  ,IN oRefViagem     VARCHAR(100)
  ,IN oStatusEntrega VARCHAR(200)
  ,IN oStatusArmazem VARCHAR(200)
  ,IN oStatusCliente VARCHAR(200)
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2021-12-06>
   #@Reviser David Ruy <2025-07-21> Parametro oStatusCliente
   ********************************************************************************************/
   
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   UPDATE tbintegraSAP_Doc
   SET RefViagem     = oRefViagem,
       StatusEntrega = oStatusEntrega,
       StatusArmazem = oStatusArmazem,
       StatusAux_Cliente = oStatusCliente
   WHERE DocEntry = oDocEntry
     AND DocTipo  = oDocTipo
     AND DocNum   = oDocNum;   
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
   ELSE    
      SET RESULTADO = 1;
      SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   SELECT RESULTADO, MENSAGEM;
   
END$$

DELIMITER ;