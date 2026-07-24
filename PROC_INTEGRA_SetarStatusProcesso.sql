DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_SetarStatusProcesso`$$

CREATE PROCEDURE `PROC_INTEGRA_SetarStatusProcesso`(
	IN oCodUsuario				VARCHAR(10),
	IN oNewStatus           INT,
	IN oStatusAtivo         INT,
	
	# Parametros de Retorno
	OUT RESULTADO             	VARCHAR(5),
	OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
	DECLARE xIncAlt VARCHAR(01)	DEFAULT 'I';
	DECLARE excecao INT DEFAULT 0;
	#DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   UPDATE tbintegraSAP_parametros
   SET  flg_status = oNewStatus
        ,ultima_atu = IF(oNewStatus=1,NOW(), ultima_atu)
        ,flg_ativo  = IFNULL(oStatusAtivo,1);
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
END$$

DELIMITER ;