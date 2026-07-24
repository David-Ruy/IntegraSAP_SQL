DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_UpdCancSLIN`$$

CREATE PROCEDURE `PROC_INTEGRA_UpdCancSLIN`(
	IN oCodUsuario				  VARCHAR(10),
	# Parametros de Retorno
	OUT RESULTADO       INT,
	OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
   DECLARE excecao         INT DEFAULT 0;
   DECLARE xUniqueKey	VARCHAR(30);
   DECLARE xTipoUpdCanc VARCHAR(01);
   DECLARE xDocumentType	VARCHAR(10);
   DECLARE xDocumentId	INT(11);
   DECLARE xDocumentNumber	INT(11);
   DECLARE xDocumentDate	DATETIME;
   DECLARE xCardCode	VARCHAR(15);
   DECLARE xCardName	VARCHAR(100);
   DECLARE xLineNumber	INT(11);
   DECLARE xItemCode	VARCHAR(30);
   DECLARE xFreeText	VARCHAR(300);
   DECLARE xOpenQuantity	DECIMAL(18,5);
   DECLARE xSERIAL	INT(11);
   DECLARE xAddress2	VARCHAR(200);
   DECLARE xComments	VARCHAR(300);
   DECLARE xAddrTypeS	VARCHAR(20);
   DECLARE xStreetS	VARCHAR(100);
   DECLARE xStreetNoS	VARCHAR(30);
   DECLARE xBlockS	VARCHAR(50);
   DECLARE xBuildingS	VARCHAR(50);
   DECLARE xCityS	VARCHAR(50);
   DECLARE xZipCodeS	VARCHAR(10);
   DECLARE xStateS	VARCHAR(2);
   DECLARE xCountryS	VARCHAR(50);
   DECLARE xBatchNumber_Code	VARCHAR(30);
   DECLARE xBatchNumber_Quantity	DECIMAL(18,5);
   DECLARE xSerialNumber_ManufactureCode	VARCHAR(30);
   DECLARE xManBtchNum	TINYINT(1);
   DECLARE xManSerNum	TINYINT(1);
   DECLARE xDescription	VARCHAR(100);
   DECLARE xPrice	DECIMAL(18,5);
   DECLARE xBuyUnitMsr	VARCHAR(10);
   DECLARE xSalUnitMsr	VARCHAR(10);
   DECLARE xInvntryUom	VARCHAR(10);
   DECLARE xNumInSale	DECIMAL(18,5);
   
   DECLARE xcod_emp        VARCHAR(03);
   DECLARE xcod_fil        VARCHAR(03);
   DECLARE xano_solic      VARCHAR(03);
   DECLARE xnum_solic      VARCHAR(03);
   DECLARE xflgInicioSep   VARCHAR(03);
   DECLARE flgInicioCarga  VARCHAR(03);
   
   DECLARE xGerouGuia      BOOLEAN;
   DECLARE xRefGuia        VARCHAR(20);
   DECLARE xCodEmpWMS	     VARCHAR(03);
   DECLARE xCodFilWMS	     VARCHAR(03); 
   DECLARE xAnoSolic 	     VARCHAR(04);
   DECLARE xNumSolic 	     VARCHAR(10);
   
   #1a fase - Inserir documentos sem id-SLIN
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraUpdCanc;
   CREATE TEMPORARY TABLE tbtmp_IntegraUpdCanc 
      SELECT * FROM tbintegraSAP_UpdCancPV
      WHERE cod_emp IS NULL;
            
   #Varre a lista de Documentos para inserir no SLIN   
   WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraUpdCanc) DO
      SELECT tbUpdCanc.UniqueKey
            ,tbUpdCanc.TipoUpdCanc
            ,tbUpdCanc.DocumentType 
            ,tbUpdCanc.DocumentId 
            ,tbUpdCanc.DocumentNumber 
            ,tbUpdCanc.LineNumber 
            ,tbUpdCanc.ItemCode 
            ,tbUpdCanc.OpenQuantity 
            ,tbUpdCanc.SERIAL 
            ,tbUpdCanc.BatchNumber_Code 
            ,tbUpdCanc.BatchNumber_Quantity 
            ,tbUpdCanc.SerialNumber_ManufactureCode 
            ,tbUpdCanc.Price 
            ,tbUpdCanc.NumInSale       
            ,tbItem.cod_emp
            ,tbItem.cod_fil
            ,tbItem.ano_solic
            ,tbItem.num_solic
            ,IF(tbItemSlin.dthr_inicio_baixa_geral IS NULL,0,1) AS flgInicioSep
            ,IF(tbItemSlin.dthr_inicio_carregamento IS NULL,0,1) AS flgInicioCarga
      INTO  xUniqueKey	
            ,xTipoUpdCanc 
            ,xDocumentType
            ,xDocumentId
            ,xDocumentNumber
            ,xLineNumber
            ,xItemCode 
            ,xOpenQuantity
            ,xBatchNumber_Code
            ,xBatchNumber_Quantity
            ,xSerialNumber_ManufactureCode
            ,xPrice
            ,xNumInSale     
            ,xcod_emp        
            ,xcod_fil        
            ,xano_solic      
            ,xnum_solic      
            ,xflgInicioSep   
            ,flgInicioCarga  
      FROM tbtmp_IntegraUpdCanc tbUpdCanc
      INNER JOIN tbintegraSAP_DocItem tbItem ON
            tbItem.DocumentType = tbUpdCanc.DocumentType
        AND tbItem.DocumentId	= tbUpdCanc.DocumentId	
        AND tbItem.DocumentNumber = tbUpdCanc.DocumentNumber	
        AND tbItem.LineNumber = tbUpdCanc.LineNumber
      INNER JOIN of_logistica.tbsolic_saidas_item tbItemSlin ON
               tbItemSlin.cod_emp   = tbItem.cod_emp
           AND tbItemSlin.cod_fil   = tbItem.cod_fil
           AND tbItemSlin.ano_solic = tbItem.ano_solic
           AND tbItemSlin.num_solic = tbItem.num_solic
           AND tbItemSlin.num_item  = tbItem.num_item
      LIMIT 1;
      
      #IF xflgInicioSep = 0 THEN
         
      #END IF;
      CALL PROC_INTEGRA_EnviarLog('999999', 
           CONCAT('PROC_INTEGRA_UpdCancSLIN=>',xTipoUpdCanc),
           CONCAT(xDocumentType,xDocumentNumber,'(',CAST(xDocumentId AS CHAR),') =>',xItemCode, '|', @R, @M), "0", @M, CONCAT('flgInicioSep=>',xflgInicioSep), @M);
      
      IF xStatusSlin <> 0 THEN
         SET xGerouGuia = TRUE;
         SET xRefGuia   = SUBSTRING(xMensagemSlin,01,20);
         SET xCodEmpWMS	= SUBSTRING(xRefGuia,01,03);
         SET xCodFilWMS	= SUBSTRING(xRefGuia,04,03);
         SET xAnoSolic 	= SUBSTRING(xRefGuia,07,04);
         SET xNumSolic 	= SUBSTRING(xRefGuia,11,10);
         
         UPDATE tbintegraSAP_Doc
         SET cod_emp   = xCodEmpWMS
            ,cod_fil   = xCodFilWMS
            ,ano_solic = xAnoSolic
            ,num_solic = xNumSolic
            ,TipoDocSLIN = IF(xDocumentType IN ("PV","OP"),"S","E")
            ,StatusAnt  = StatusDoc
            ,StatusDoc  = IF(StatusDoc <= '2', '3', StatusDoc)
            ,StatusSlin = xStatusSlin
         WHERE DocTipo  = xDocumentType
           AND DocEntry = xDocEntry;
           
      ELSE
          CALL PROC_INTEGRA_EnviarLog('999999',
                CONCAT('PROC_INTEGRA_UpdCancSLIN=>',xTipoUpdCanc),
                  CONCAT('Não Atualizado ', xDocumentType,xDocumentNumber,'(',CAST(xDocumentId AS CHAR),') =>',xItemCode,'|', @R, @M), "0", @M, @R, @M);
      END IF;
      
   END WHILE;
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraUpdCanc;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
      SET RESULTADO = 0;
      SET MENSAGEM = "Atualização realizada com sucesso";
   END IF;
END$$

DELIMITER ;