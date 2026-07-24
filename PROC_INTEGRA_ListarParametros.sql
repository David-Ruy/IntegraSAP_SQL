DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarParametros`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarParametros`(
)
BLOCO1:BEGIN
/**************************************************************************************/
#@Reviser David Ruy <2025-07-21> Buscar DataUpdCanc da tabela de parametros
#                                Listar tbintegraSAP_utilizacao
#
/**************************************************************************************/
   DECLARE xIncAlt VARCHAR(01)	DEFAULT 'I';
   DECLARE excecao INT DEFAULT 0;
   DECLARE DataUpdCanc DATETIME;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;

   #Data e Hora da ultima alteração recuperada do SAP
   #SELECT MAX(updatedate) INTO DataUpdCanc 
   #FROM tbintegraSAP_UpdCancPV
   #WHERE DATE(dthr_inc) = CURRENT_DATE()
   #AND TipoUpdCanc = 'U';
   #
   #SET DataUpdCanc = IFNULL(DATE_ADD(DataUpdCanc, INTERVAL -30 MINUTE),
   #                         DATE_ADD(NOW(), INTERVAL -2 HOUR));
                            
                            
   SELECT tbintegraSAP_parametros .*
         ,IFNULL(TIMESTAMPDIFF(MINUTE, ultima_atu, NOW()),0) AS ElapsedAtu
         ,NOW() AS dthr_now, 
         IFNULL(DATE_ADD(dthr_updcanc, INTERVAL -30 MINUTE),
                         DATE_ADD(NOW(), INTERVAL -2 HOUR)) DataUpdCanc
         ,tbfiliais.raz_social
         #,DATE_SUB(ultima_atu, INTERVAL 30 MINUTE) DataUpdCanc2
         ,dthr_updcanc DataUpdCanc2
   FROM tbintegraSAP_parametros
   LEFT JOIN of_logistica.tbfiliais ON 
             tbfiliais.num_cnpj = cnpj_cpf_cli;
             
             
   SELECT * FROM tbintegraSAP_utilizacao;
             
   #IF excecao = 1 THEN
      #SET RESULTADO = "0";
      #SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   #END IF;
   
END$$

DELIMITER ;