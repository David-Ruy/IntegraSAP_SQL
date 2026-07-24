DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarLog`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarLog`(
    IN oCodUsuario				       VARCHAR(10),
    IN oJsonRequest				      MEDIUMTEXT,
    IN oJsonResponse			      MEDIUMTEXT,
    IN oResponseStatus			    VARCHAR(10),
    IN oResponseStatusDescr		VARCHAR(300),
    # Parametros de Retorno
    OUT RESULTADO            INT,
    OUT MENSAGEM             VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xIncAlt 	     VARCHAR(01)	DEFAULT 'I';
   DECLARE xCodErro	     INT DEFAULT 0;
   DECLARE excecao 	     INT DEFAULT 0;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   #START TRANSACTION;
   
   INSERT INTO tbintegraSAP_log_request (
    jsonRequest,jsonResponse, ResponseStatus, ResponseStatusDescr, usu_inc, dthr_inc)
   VALUES (oJsonRequest, oJsonResponse, oResponseStatus, oResponseStatusDescr, 
     oCodUsuario, NOW()
    );
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
   ELSE
      #COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = "LOG gerado com sucesso";
   END IF;
   #SELECT RESULTADO, MENSAGEM;
END$$

DELIMITER ;