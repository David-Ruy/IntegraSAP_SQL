DROP TABLE IF EXISTS tbintegraSAP_Service;
CREATE TABLE tbintegraSAP_Service (
			ServiceId INT AUTO_INCREMENT,
			ServiceName VARCHAR(100),
			ServiceDescr VARCHAR(100),
			ServiceHost VARCHAR(500),
			ServiceStatus INT DEFAULT 0 COMMENT "0=Desativado, 1=Ativado",
			ServiceObserv VARCHAR(500),
			ServiceLastCheck  DATETIME,
			ServiceLastStatus VARCHAR(50) COMMENT "Running, Stopped, StopPending",
			dthr_inc DATETIME,
			ServiceLastStart DATETIME,
			ServiceLastExec DATETIME,
			ServiceReiniciar INT DEFAULT 0 COMMENT "0=NÃO, 1=SIM",
			PRIMARY KEY (ServiceId),
			UNIQUE KEY (ServiceName)
);

DELETE FROM tbintegraSAP_Service;
ALTER TABLE tbintegraSAP_Service AUTO_INCREMENT = 1;


INSERT INTO tbintegraSAP_Service (ServiceName, ServiceDescr, ServiceStatus, dthr_inc)
VALUES 
   ('OOne_Service_IntegraSAP_GET_PV0','Leitura PV´s e Criar PK',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_PK','Confirmação de PK',0, NOW()),
			('OOne_Service_IntegraSAP_GET_UPDPV','Leitura de alterações PV',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_DEV_VENDAS','Leitura Dev Vendas',0, NOW()),
			('OOne_Service_IntegraSAP_GET_ENT','Ler Docs Entradas (Esboços, NF Entrada)',0, NOW()),
			('OOne_Service_IntegraSAP_GET_DEV_COMPRAS','Leitura/Confirmação Devol Compras',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_TMS','Atualizar Status no SAP',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_NFE','Leitura NF Vendas / Grava TMS',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_TRANSF','Transferencias entre Depósitos SLIN -> SAP',0, NOW()),
			('OOne_Service_IntegraSAP_GET_PED_TRANSF','Leitura Ped Transferencia (Entrada/Saída)',0, NOW()),
			('OOne_Service_IntegraSAP_GET_OP','Leitura Ordens de Produção',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_COUNT','Gera Contagem para ajuste de estoque no SAP',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_ETIQ_PRODUCAO','Atualiza flag Etiqueta Lida na Produção',0, NOW()),
			('OOne_Service_IntegraSAP_GET_CANC_COMPRAS','Leitura de Cancelamento de compras',0, NOW()),
			('OOne_Service_IntegraSAP_GET_OP2','Leitura Entradas (OP)',0, NOW()),
			('OOne_Service_IntegraSAP_GET_PK0','Leitura PK (Faturamento Parcial)',0, NOW()),
			('OOne_Service_IntegraSAP_GET_UPDPK','Leitura de alterações PK (Faturamento Parcial)',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_TRACKING','Leitura e Atualização STATUS PV´s WebEleven',0, NOW()),
			
			('OOne_Service_IntegraSAP_GET_CTE','Leitura CTE de Terceiros Invent',0, NOW()),
			('OOne_IntegraSAP_ATU_NFSERV','Gera NF Serviço',0, NOW()),
			('OOne_IntegraSAP_ATU_STATUS_FRETE','Atualização Status FRETE no SAP - Liberação Pagto',0, NOW()),
			('OOne_IntegraSAP_GET_ESTOQUE','Histórico de Estoque',0, NOW()),

			('OOne_Service_IntegraSAP_ATU_ENT','Confirmação Recebimentos',0, NOW()),
			('OOne_Service_IntegraSAP_ATU_DEV_COMPRAS','Confirmação Devol Compras',0, NOW())		
			;		
			
SELECT * FROM tbintegraSAP_Service;



SET @ServiceName = 'OOne_IntegraSAP_ATU_NFE';
SET @Campo = 'ServiceLastStatus';
SET @Valor = "Stopped";
CALL PROC_Integra_AtualizarService(@ServiceName, @Campo, @Valor, @R, @M); SELECT @R, @M;


SET @ServiceName = 'OOne_IntegraSAP_GET_OP2|OOne_IntegraSAP_ATU_ETIQ_PRODUCAO|OOne_IntegraSAP_GET_PK0';
#SET @ServiceName = 'LASTCHECK';
#SET @ServiceName = 'TODOS';
CALL PROC_Integra_ListarService(@ServiceName );


        
         




			
			



/**************************************************************************************************/
DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_Integra_AtualizarService`$$

CREATE PROCEDURE `PROC_Integra_AtualizarService`(
	IN oServiceName   VARCHAR(100),
	IN oCampo         VARCHAR(1000),
	IN oValor         TEXT,
	
	# Parametros de Retorno
	OUT RESULTADO     VARCHAR(5),
	OUT MENSAGEM      VARCHAR(500)
)
BLOCO1:BEGIN
	/*****************************************************************************************/
	#@Author <2025-01-29> : David Ruy
	/*****************************************************************************************/
   
   DECLARE excecao   INT DEFAULT 0;
   DECLARE xIncAlt   VARCHAR(5);
  

   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(MENSAGEM);
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   

   START TRANSACTION;
   
   SET RESULTADO = "1";
   SET MENSAGEM = "Atualização realizada com sucesso";
   
   IF NOT EXISTS (SELECT 1 FROM tbintegraSAP_Service
			   WHERE ServiceName = oServiceName) THEN
        SET xIncAlt = 'X';
   ELSE
        SET xIncAlt = 'A';
   END IF;
	
   IF xIncAlt = 'X' THEN	
      SET RESULTADO = "0";
      SET MENSAGEM  = "Serviço não localizado - Atualização Impossível";
   ELSE
      
      IF oCampo = 'ServiceStatus' THEN
         UPDATE tbintegraSAP_Service
         SET ServiceStatus = oValor
         WHERE ServiceName = oServiceName;
      ELSEIF oCampo = 'ServiceObserv' THEN
         UPDATE tbintegraSAP_Service
         SET ServiceObserv = oValor
         WHERE ServiceName = oServiceName;
      ELSEIF oCampo = 'ServiceLastCheck' THEN
         UPDATE tbintegraSAP_Service
         SET ServiceLastCheck = NOW() #oValor
         WHERE ServiceName = oServiceName;
      ELSEIF oCampo = 'ServiceLastStatus' THEN
         UPDATE tbintegraSAP_Service
         SET ServiceLastStatus = oValor
         WHERE ServiceName = oServiceName;
      ELSEIF oCampo = 'ServiceLastStart' THEN
         UPDATE tbintegraSAP_Service
         SET ServiceLastStart = NOW() #oValor
         WHERE ServiceName = oServiceName;
      ELSEIF oCampo = 'ServiceLastExec' THEN
         UPDATE tbintegraSAP_Service
         SET ServiceLastExec = NOW() #oValor
         WHERE ServiceName = oServiceName;
      ELSEIF oCampo = 'ServiceReiniciar' THEN
         UPDATE tbintegraSAP_Service
         SET ServiceReiniciar = IF(ServiceReiniciar=1 AND oValor=1,2,oValor)
         WHERE ServiceName = oServiceName;
      END IF;
      
      IF ROW_COUNT() = 0 THEN
         SET RESULTADO = "0";
         SET MENSAGEM = "Atualização NÃO realizada : 0 Registros atualizados";
      END IF;

   END IF;
    
			COMMIT;

END$$

DELIMITER ;




/****************************************************************************************************/
DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_Integra_ListarService`$$

CREATE PROCEDURE PROC_Integra_ListarService(
    IN oServiceNames VARCHAR(1000)
)
BEGIN

    IF oServiceNames = 'LASTCHECK' THEN
        SELECT MAX(ServiceLastCheck) ServiceLastCheck FROM tbintegraSAP_Service
        WHERE ServiceStatus = 1;
    ELSEIF oServiceNames = 'TODOS' THEN
        SELECT * FROM tbintegraSAP_Service
        WHERE ServiceStatus = 1;
    ELSE
        -- Variável para armazenar a query dinâmica
        SET @query = CONCAT('SELECT * FROM tbintegraSAP_Service WHERE ServiceStatus = 1 AND ServiceName IN ( "', REPLACE(oServiceNames, '|', '","'), '")');
        
        -- Preparação da query dinâmica
        PREPARE stmt FROM @query;
        -- Execução da query dinâmica
        EXECUTE stmt;
        -- Liberação do statement preparado
        DEALLOCATE PREPARE stmt;
    END IF;
END $$

DELIMITER ;





