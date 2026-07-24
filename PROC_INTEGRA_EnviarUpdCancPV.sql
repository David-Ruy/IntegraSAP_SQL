DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarUpdCancPV`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarUpdCancPV`(
	 IN oCodUsuario	            VARCHAR(10)
   ,IN oUniqueKey	           VARCHAR(30)	
   ,IN oTipoUpdCanc          VARCHAR(01)
   ,IN oDocumentType	        VARCHAR(10)
   ,IN oDocumentId	          INT(11)	
   ,IN oDocumentNumber	      INT(11)	
   ,IN oDocumentDate	        DATETIME	
   ,IN oDocumentDueDate	     DATETIME	
   ,IN oUpdateDate	          DATETIME	
   ,IN oCardCode	            VARCHAR(15)	
   ,IN oCardName	            VARCHAR(100)	
   ,IN oLineNumber	          INT(11)	
   ,IN oItemCode	            VARCHAR(30)	
   ,IN oFreeText	            VARCHAR(2000)
   ,IN oQuantity	            DECIMAL(18,5)	
   ,IN oInvQuantity	            DECIMAL(18,5)	   
   ,IN oSERIAL	              INT(11)	
   ,IN oAddress2	            VARCHAR(200)	
   ,IN oComments	            VARCHAR(2000)
   ,IN oAddrTypeS	           VARCHAR(20)	
   ,IN oStreetS	             VARCHAR(100)	
   ,IN oStreetNoS	           VARCHAR(30)	
   ,IN oBlockS	              VARCHAR(50)	
   ,IN oBuildingS	           VARCHAR(100)	
   ,IN oCityS	               VARCHAR(100)	
   ,IN oZipCodeS	            VARCHAR(10)	
   ,IN oStateS	              VARCHAR(2)	
   ,IN oCountryS	            VARCHAR(50)	
   ,IN oBatchNumber_Code	    VARCHAR(30)	
   ,IN oBatchNumber_Quantity	DECIMAL(18,5)	
   ,IN oSerialNumber_ManufactureCode	VARCHAR(30)	
   ,IN oManBtchNum	          TINYINT(1)	
   ,IN oManSerNum	           TINYINT(1)	
   ,IN oDescription	         VARCHAR(200)	
   ,IN oPrice	               DECIMAL(18,5)	
   ,IN oDollarQuote          DECIMAL(18,5)
   ,IN oBuyUnitMsr	          VARCHAR(10)	
   ,IN oSalUnitMsr	          VARCHAR(10)	
   ,IN oInvntryUom	          VARCHAR(10)	
   ,IN oNumInSale	           DECIMAL(18,5)	
   ,IN oSlpName              VARCHAR(100)	
   ,IN oIncoterms            VARCHAR(10)	
   ,IN oTransportationCode   VARCHAR(10)	
   ,IN oTrnspName            VARCHAR(100)	
   ,IN oTrnspTaxIdNum        VARCHAR(20)	
   ,IN oRoute                VARCHAR(50)
   ,IN oStartTime1           VARCHAR(20)
   ,IN oEndTime1             VARCHAR(20)
   ,IN oStartTime2           VARCHAR(20)
   ,IN oEndTime2             VARCHAR(20)
	,IN oEndEntrega	        VARCHAR(200)
	   
   # Parametros de Retorno
   ,OUT RESULTADO            INT
   ,OUT MENSAGEM             VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2019-12-20>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_UpdCancPV que faz o controle
   da integração SAP / SLIN dos pedidos Alterados e Cancelados no SAP  
   @#@Reviser David Ruy <2024-06-19> Alteração variável oComments -> VARCHAR(500) -> TEXT
   @Reviser David Ruy <2025-01-16> Novo Parametro oInvQuantity para atualizar QtdeEstoque
   @Reviser David Ruy <2025-01-21> Gravar STATUS = -1 (para não processar inicialmente até que seja feita uma checagem dos itens)
   *******************************************************************************/
   
   DECLARE xIncAlt 	     VARCHAR(01)	DEFAULT 'I';
   DECLARE xStatusAnt    VARCHAR(01);
   DECLARE xStatusAux    VARCHAR(01);
   DECLARE xCodErro	     INT DEFAULT 0;
   DECLARE excecao 	     INT DEFAULT 0;
   
   DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   IF NOT EXISTS (
         SELECT 1 
         FROM tbintegraSAP_UpdCancPV
         WHERE UniqueKey = oUniqueKey
           AND TipoUpdCanc = oTipoUpdCanc
           AND IF(oTipoUpdCanc = 'C', TRUE, UpdateDate = oUpdateDate)) THEN
         
         INSERT INTO tbintegraSAP_UpdCancPV (
            UniqueKey
            ,TipoUpdCanc
            ,DocumentType 
            ,DocumentId 
            ,DocumentNumber 
            ,DocumentDate 
            ,DocumentDueDate
            ,UpdateDate
            ,CardCode 
            ,CardName 
            ,LineNumber 
            ,ItemCode 
            ,FreeText 
            ,Quantity 
            ,QtdeEstoque
            ,SERIAL 
            ,Address2 
            ,Comments 
            ,AddrTypeS 
            ,StreetS 
            ,StreetNoS 
            ,BlockS 
            ,BuildingS 
            ,CityS 
            ,ZipCodeS 
            ,StateS 
            ,CountryS 
            ,BatchNumber_Code 
            ,BatchNumber_Quantity 
            ,SerialNumber_ManufactureCode 
            ,ManBtchNum 
            ,ManSerNum 
            ,Description 
            ,Price 
            ,DollarQuote 
            ,BuyUnitMsr 
            ,SalUnitMsr 
            ,InvntryUom 
            ,NumInSale
            ,SlpName         
            ,Incoterms   
            ,TransportationCode    
            ,TrnspName       
            ,TrnspTaxIdNum
            ,Route
            ,StartTime1
            ,EndTime1
            ,StartTime2
            ,EndTime2
            ,End_Entrega
            ,STATUS) VALUES (
                oUniqueKey
               ,oTipoUpdCanc
               ,oDocumentType 
               ,oDocumentId 
               ,oDocumentNumber 
               ,oDocumentDate
               ,oDocumentDueDate
               ,oUpdateDate
               ,oCardCode 
               ,oCardName 
               ,oLineNumber 
               ,oItemCode 
               ,oFreeText 
               ,oQuantity 
               ,oInvQuantity 
               ,oSERIAL 
               ,oAddress2 
               ,oComments 
               ,oAddrTypeS 
               ,oStreetS 
               ,oStreetNoS 
               ,oBlockS 
               ,oBuildingS 
               ,oCityS 
               ,oZipCodeS 
               ,oStateS 
               ,oCountryS 
               ,oBatchNumber_Code 
               ,oBatchNumber_Quantity 
               ,oSerialNumber_ManufactureCode 
               ,oManBtchNum 
               ,oManSerNum 
               ,oDescription 
               ,oPrice 
               ,oDollarQuote 
               ,oBuyUnitMsr 
               ,oSalUnitMsr 
               ,oInvntryUom 
               ,oNumInSale
               ,oSlpName         
               ,oIncoterms       
               ,oTransportationCode
               ,oTrnspName       
               ,oTrnspTaxIdNum
               ,oRoute
               ,oStartTime1
               ,oEndTime1
               ,oStartTime2
               ,oEndTime2
               ,oEndEntrega
               ,-1);
        SET RESULTADO = 1;
        SET MENSAGEM = "Registro inserido com sucesso";
            
/*            
     #@Reviser David Ruy <2020-08-11> Não há mais necessidade 
     # só insere se não existe e pronto
     ELSEIF EXISTS (SELECT 1 
                    FROM tbintegraSAP_UpdCancPV
                    WHERE UniqueKey = oUniqueKey
                      AND TipoUpdCanc = oTipoUpdCanc
                      AND UpdateDate = oUpdateDate
                      AND STATUS > 0) THEN
                      
        SET RESULTADO = 0;
        SET MENSAGEM = CONCAT("Registro em processo, não foi atualizado");		
   ELSE
      UPDATE tbintegraSAP_UpdCancPV
      SET Quantity   = oQuantity
          ,cod_emp   = NULL
          ,cod_fil   = NULL
          ,ano_solic = NULL
          ,num_solic = NULL
          ,num_item  = NULL          
          ,STATUS    = 1
      WHERE UniqueKey = oUniqueKey
        AND TipoUpdCanc = oTipoUpdCanc
        AND UpdateDate  = oUpdateDate; 
        
      SET RESULTADO = 1;
      SET MENSAGEM = "Registro atualizado com sucesso";   
*/
   ELSE
        SET RESULTADO = 2;
        SET MENSAGEM = "Registro já existe - Atualização não realizada";
   END IF;
    
   /*
   IF RESULTADO = 1 AND oTipoUpdCanc = "U" THEN
      UPDATE tbintegraSAP_UpdCancPV
      SET  cod_emp   = NULL
          ,cod_fil   = NULL
          ,ano_solic = NULL
          ,num_solic = NULL
          ,num_item  = NULL          
      WHERE DocumentId     = oDocumentId
        AND DocumentNumber = oDocumentNumber
        AND DocumentType   = oDocumentType
        AND TipoUpdCanc    = oTipoUpdCanc;   
   END IF;*/
    
    
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
   END IF;
END$$

DELIMITER ;