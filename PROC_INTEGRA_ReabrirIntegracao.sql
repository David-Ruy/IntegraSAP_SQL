DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ReabrirIntegracao`$$

CREATE PROCEDURE `PROC_INTEGRA_ReabrirIntegracao`(
   IN xCodEmpWMS			   VARCHAR(03),
   IN xCodFilWMS			   VARCHAR(03),
   IN xAnoSolic 			   VARCHAR(04),
   IN xNumSolic 			   VARCHAR(10),
   IN xTipoDoc        VARCHAR(01),    #E=Entrada / S=Saída
   # Parametros de Retorno
   OUT RESULTADO      INT,
   OUT MENSAGEM       VARCHAR(500)
)
BLOCO1:BEGIN
   /*
   #@Reviser David Ruy <2022/04/29> Ajuste LPAD para variaveis xCodEmpWMS/xCodFilWMS/xNumSolic
   #Reviser David Ruy <2022/04/29> Ajuste Retorno SET MENSAGEM = CONCAT(xCodEmpWMS,'/',xCodFilWMS,'-',xNumSolic,'.',xAnoSolic);   
   #Reviser David Ruy <20230606> Ajuste condição update status tbsolic_saidas
   */

   DECLARE xVarOK        INT DEFAULT 0;
   DECLARE excecao 	    INT DEFAULT 0;   
   DECLARE xCodUsuario   VARCHAR(06) DEFAULT "999999";


   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       #ROLLBACK;
   END;
   
   #Transação tratada pela procedure "Pai"   
   #START TRANSACTION;
   
   SET xCodEmpWMS	= LPAD(xCodEmpWMS, 3, '0');
   SET xCodFilWMS = LPAD(xCodFilWMS, 3, '0');
   SET xNumSolic  = LPAD(xNumSolic, 10, '0');
   
   IF xTipoDoc = 'E' THEN  
      UPDATE of_logistica.tbsolic_entradas tbTopo 
      SET tbTopo.dthr_retorno_integracao = NULL
      WHERE tbTopo.cod_emp   = xCodEmpWMS
        AND tbTopo.cod_fil   = xCodFilWMS
        AND tbTopo.ano_solic = xAnoSolic
        AND tbTopo.num_solic = xNumSolic;
        
      IF ROW_COUNT() > 0 THEN        
         #Atualizar Status na tbIntegra_DOC apenas se dthr_retorno_integracao não estiver Nulo
         UPDATE tbintegraSAP_Doc tbTopo
         SET StatusAnt  = StatusDoc,
             StatusDoc  = IF(StatusDoc = 6, 3, StatusDoc),
             StatusSLIN = 1
         WHERE tbTopo.cod_emp   = xCodEmpWMS
           AND tbTopo.cod_fil   = xCodFilWMS
           AND tbTopo.ano_solic = xAnoSolic
           AND tbTopo.num_solic = xNumSolic
           AND tbTopo.TipoDocSLIN = xTipoDoc;
      END IF;
        
   ELSE
      
      SET xVarOK = EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas tbTopo 
                          WHERE tbTopo.cod_emp   = xCodEmpWMS
                            AND tbTopo.cod_fil   = xCodFilWMS
                            AND tbTopo.ano_solic = xAnoSolic
                            AND tbTopo.num_solic = xNumSolic
                            AND tbTopo.dthr_retorno_integracao IS NOT NULL);
   
      IF xVarOK THEN
      
         UPDATE of_logistica.tbsolic_saidas tbTopo 
         SET tbTopo.dthr_retorno_integracao = NULL,
             tbTopo.dthr_confirm    = NULL,
             tbTopo.usu_confirm     = NULL,
             tbTopo.dthr_alt        = NOW(),
             tbTopo.usu_alt         = '999999',
             tbTopo.status_solic    = IF(tbTopo.status_solic<2,tbTopo.status_solic,2),
             tbTopo.status_processo = IF(tbTopo.status_processo<6,tbTopo.status_processo,6)
         WHERE tbTopo.cod_emp   = xCodEmpWMS
           AND tbTopo.cod_fil   = xCodFilWMS
           AND tbTopo.ano_solic = xAnoSolic
           AND tbTopo.num_solic = xNumSolic;
        
         #Atualizar Status na tbIntegra_DOC apenas se dthr_retorno_integracao não estiver Nulo
         UPDATE tbintegraSAP_Doc tbTopo
         SET StatusAnt  = StatusAnt,
             StatusDoc  = IF(StatusDoc = 6, 3, StatusDoc),
             StatusSLIN = 1
         WHERE tbTopo.cod_emp     = xCodEmpWMS
           AND tbTopo.cod_fil     = xCodFilWMS
           AND tbTopo.ano_solic   = xAnoSolic
           AND tbTopo.num_solic   = xNumSolic
           AND tbTopo.TipoDocSLIN = xTipoDoc;
           
         INSERT INTO of_logistica.tbsolic_saidas_log_reabertura( cod_emp
                                                      , cod_fil
                                                      , ano_solic
                                                      , num_solic
                                                      , dthr_confirm
                                                      , usu_confirm
                                                      , dthr_log
                                                      , usu_log
                                                      , usu_log_lider
                                                      , form_log
                                                      , flg_reabertura_tipo
                                                      )
               SELECT tbsolic_saidas.cod_emp                          AS cod_emp
                    , tbsolic_saidas.cod_fil                          AS cod_fil
                    , tbsolic_saidas.ano_solic                        AS ano_solic
                    , tbsolic_saidas.num_solic                        AS num_solic
                    , tbsolic_saidas.dthr_confirm                     AS dthr_confirm
                    , tbsolic_saidas.usu_confirm                      AS usu_confirm
                    , NOW()                                           AS dthr_log
                    , XCodUsuario                                     AS usu_log
                    , NULL                                            AS usu_log_lider
                    , 'PROC_INTEGRA_REABRIRINTEGRACAO'                AS form_log
                    , 3                                               AS flg_reabertura_tipo 
                 FROM of_logistica.tbsolic_saidas
                WHERE tbsolic_saidas.cod_emp      = xCodEmpWMS
                  AND tbsolic_saidas.cod_fil      = xCodFilWMS
                  AND tbsolic_saidas.ano_solic    = xAnoSolic
                  AND tbsolic_saidas.num_solic    = xNumSolic
                  AND tbsolic_saidas.dthr_confirm IS NOT NULL;                       
      END IF;
   END IF;
   
   
   IF excecao = 1 THEN
      #ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- Erro PROC_INTEGRA_ReabrirIntegracao");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      #COMMIT;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(xCodEmpWMS,'/',xCodFilWMS,'-',xNumSolic,'.',xAnoSolic);
      SET MENSAGEM = CONCAT(IFNULL(MENSAGEM,""),"- PROC_INTEGRA_ReabrirIntegracao processada com sucesso");
   END IF;
   
END$$

DELIMITER ;