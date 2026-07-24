DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarCTE_Valor`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarCTE_Valor`(
	IN oCodUsuario		VARCHAR(10),
	
   IN oidAddOn       INT,
   #IN oId            INT,
   IN oDescription   VARCHAR(100),
   IN oValor         DECIMAL(18,6),

	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN

   DECLARE oid_documento   INT DEFAULT 0;
	DECLARE excecao         INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   SET RESULTADO = "1";
   SET MENSAGEM = "Inclusão realizada com sucesso";
   
   SELECT id_documento INTO oid_documento FROM tbintegraSAP_CTe
   WHERE idAddOn = oidAddOn;


   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_CTeVlr
                  WHERE id_documento = oid_documento
                  AND descr_despesa = oDescription) THEN
      INSERT INTO tbintegraSAP_CTeVlr (
         id_documento, tipo_despesa, descr_despesa, valor_despesa) VALUES (
         oid_documento, 1, oDescription, oValor);
   ELSE
   BEGIN
      SET MENSAGEM = "Atualização realizada com sucesso";
      UPDATE tbintegraSAP_CTeVlr
      SET  id_documento   = oid_documento
          ,tipo_despesa   = 1
          ,descr_despesa  = oDescription
          ,valor_despesa  = oValor
      WHERE id_documento = oid_documento AND descr_despesa = oDescription;
   END;
   END IF;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;