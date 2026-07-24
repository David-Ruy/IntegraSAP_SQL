DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_CancelarEntrada`$$

CREATE PROCEDURE `PROC_INTEGRA_CancelarEntrada`(
   IN  oIdEntrada            INT,
   IN  oDocTipo              VARCHAR(10),
   IN  oTipoRetorno          INT,   #0=Retorna Chave (emp/fil/ano/num) | 1=Update dthr_cancel
   # Parametros de Retorno
   OUT RESULTADO             INT,
   OUT MENSAGEM              VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE xCodEmpWMS			     VARCHAR(03);
   DECLARE xCodFilWMS			     VARCHAR(03);
   DECLARE xAnoSolic 			     VARCHAR(04);
   DECLARE xNumSolic 			     VARCHAR(10);
   DECLARE xstatus_processo  INT;
   
   DECLARE excecao 	         INT DEFAULT 0;
   
   /*DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       ROLLBACK;
   END;*/
   
   #Transação tratada pela procedure "Pai"   
   START TRANSACTION;
   IF oTipoRetorno = 0 THEN
      SELECT TopoWMS.cod_emp, TopoWMS.cod_fil, TopoWMS.ano_solic, TopoWMS.num_solic, TopoWMS.status_processo
      INTO xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xstatus_processo
      FROM tbintegraSAP_Doc TopoDoc
      INNER JOIN of_logistica.tbsolic_entradas TopoWMS ON 
                 TopoWMS.cod_emp   = TopoDoc.cod_emp
             AND TopoWMS.cod_fil   = TopoDoc.cod_fil
             AND TopoWMS.ano_solic = TopoDoc.ano_solic
             AND TopoWMS.num_solic = TopoDoc.num_solic
      WHERE TopoDoc.DocEntry = oIdEntrada
        AND TopoDoc.DocTipo  = oDocTipo
        AND TopoDoc.TipoDocSLIN = "E";
      SET RESULTADO = 1;
      #SET MENSAGEM  = CONCAT("Cancelamento Realizado com sucesso [",xCodEmpWMS, '/', xCodFilWMS, '-', xAnoSolic, '.', xNumSolic,"]");
      IF xstatus_processo = 11  THEN #Cancelado
         SET RESULTADO = 0;
         SET MENSAGEM  = CONCAT("GEM já está Cancelada [",xCodEmpWMS, '/', xCodFilWMS, '-', xAnoSolic, '.', xNumSolic,"] - Cancelamento impossível");
      ELSEIF xstatus_processo >= 6  THEN #Conferencia
         SET RESULTADO = 0;
         SET MENSAGEM  = CONCAT("GEM em Conferencia [",xCodEmpWMS, '/', xCodFilWMS, '-', xAnoSolic, '.', xNumSolic,"] - Cancelamento impossível");
      ELSE   
         SET MENSAGEM = CONCAT(xCodEmpWMS, '|', xCodFilWMS, '|', xAnoSolic, '|', xNumSolic);    
      END IF;
   ELSE
   
      #set RESULTADO = 0;
      #set MENSAGEM = "";
      #CALL of_logistica.PROC_WMS_DESCARGA_CANCELAR_GEM_INTEGRACAO(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, RESULTADO, MENSAGEM);
      
      #if RESULTADO = 1 then
         UPDATE tbintegraSAP_Doc
         SET dthr_cancel = NOW(),
             StatusDoc   = 9
         WHERE DocEntry = oIdEntrada
           AND DocTipo  = oDocTipo;      
       #end if;
   END IF;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_CancelarEntrada [",xQtdeRegs,"]");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 1;
      #SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- (PROC_INTEGRA_CancelarEntrada) processamento com sucesso [",xQtdeRegs,"]");
   END IF;
END$$

DELIMITER ;