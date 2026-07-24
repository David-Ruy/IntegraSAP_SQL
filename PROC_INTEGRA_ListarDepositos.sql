DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarDepositos`$$

CREATE PROCEDURE PROC_INTEGRA_ListarDepositos(
   IN xDeposito VARCHAR(30)
)   
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy <2023-01-07>
   ********************************************************************************************/
   
   SELECT * FROM of_logistica.tbstatus_lotes
   LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
             tbstatus_lotes_integracao.codigo_status = tbstatus_lotes.codigo
   WHERE tbstatus_lotes.flg_ativo = 1 
     AND (tbstatus_lotes_integracao.deposito_integracao = xDeposito
      OR  tbstatus_lotes.deposito_integracao = xDeposito);
      
END$$

DELIMITER ;