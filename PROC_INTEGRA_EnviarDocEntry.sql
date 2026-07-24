DELIMITER $$

#Para BRW e Gemmini _20240813 para as demais, tirar oU_BDO_NKIT e oDocEntryRef, oDocNumRef, oDocTotal
DROP PROCEDURE IF EXISTS `PROC_INTEGRA_EnviarDocEntry`$$

CREATE PROCEDURE `PROC_INTEGRA_EnviarDocEntry`(
	IN oCodUsuario	      VARCHAR(10),
	IN oDocEntry	      INT,
	IN oDocTipo	         VARCHAR(10), #'PV / NF / OP / NE Nota Fiscal entrada / DV Devolução de Vendas / TD-<E>/<S> (Transferencia Entre Depósitos)
	IN oDocNum	         VARCHAR(30),
	IN oBPLId           VARCHAR(30),
	IN oIdSales         VARCHAR(30),
	IN oIdCommerce      VARCHAR(30),
	IN oIdRplOrder      VARCHAR(30),
	IN oU_BDO_NKIT      VARCHAR(50),
	
	IN oTipoProducao     VARCHAR(20),
	IN oItemCode	      VARCHAR(30),
	IN oCardCode	      VARCHAR(15),
	IN oCardName	      VARCHAR(100),
	IN oNumCNPJ          VARCHAR(20), 
	IN oNumCPF           VARCHAR(20), 
	IN oSerial           INT,
	IN oAddrTypeS        VARCHAR(20),
	IN oStreetS          VARCHAR(200),
	IN oStreetNoS        VARCHAR(30),
	IN oBuildingS        VARCHAR(100),
	IN oBlockS           VARCHAR(100),
	IN oCityS            VARCHAR(100),
	IN oZipCodeS         VARCHAR(10),
	IN oStateS           VARCHAR(02),
	IN oCountryS         VARCHAR(50),
	
	IN oNomeVendedor     VARCHAR(60),
	IN oCFOP             VARCHAR(10),
	#IN oMainUsage        VARCHAR(30),
	IN oTipoFrete        VARCHAR(5),
	IN oNomeTransp       VARCHAR(150),
	IN oCnpjTransp       VARCHAR(50),
	IN oTransportationCode VARCHAR(10),
	
	IN oRoute             VARCHAR(50),
	IN oStartTime1        VARCHAR(20),
	IN oEndTime1          VARCHAR(20),
	IN oStartTime2        VARCHAR(20),
	IN oEndTime2          VARCHAR(20),
	IN oEnd_Entrega	      VARCHAR(200),
			
	IN oDocDate	         DATETIME,	
	IN oDueDate	         DATETIME,
	IN oStatusDoc	       VARCHAR(10),	# Verificar STATUS EXCLUSÃO
	IN oPlannedQty	      DOUBLE(20,6),
	IN oWhareHouse	      VARCHAR(30),
	IN oWhareHouseTransf VARCHAR(30),
	IN oStatusEnum	      INT,
	IN oid_request       INT,           #Receber idPicking quando DocObjVendas = 'P'
	IN oObservacoes      VARCHAR(2000),
	IN oDocEntryRef      VARCHAR(30),
	IN oDocNumRef        VARCHAR(30),
	IN oDocTotal         DECIMAL(20,6),
	IN oQtdeOriItens     INT,  
	
	# Parametros de Retorno
	OUT RESULTADO         INT,
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /******************************************************************************
   @Author <David Ruy (OVERFLASH)>
   @Creation <2019-07-11>
   @Description <Esta rotina insere e atualiza a tabela tbintegraSAP_Doc que faz o controle
   da integração SAP / SLIN. Considera os status abaixo :
      StatusDoc 
         1 = Importado SAP
         2 = Integrado SLIN
         3 = Integrado SLIN (alteração)
         4 = Iniciado SLIN
         5 = Finalizado SLIN
         6 = Retornado SAP
         7 = Processo de Atualização SAP (Divergencias dentro da tolerancia)
         9 = Cancelado SAP
         10 = OP Externa, processar (Pedido de Transferencia irá gerar o processo de Saída)
   >
   @Reviser David Ruy <2019-11-20> Ajuste xStatusAnt para atualização do registro | SET xStatusAux = IF(xStatusAnt="1","2",xStatusAnt);
   @Reviser David Ruy <2021-08-24> Ajustes oDocTipo = 'TF" : Tranferencia entre filiais
   @Reviser David Ruy <2021-08-30> Ajustes oTipoProducao => PEX/PEC não gerar picking (STATUS=10)
   @Reviser David Ruy <2021-09-22> Ajustes Elinox : Nunca realizar leitura de OP´ pois TODAS serão integradas via transferencia de estoque
   @Reviser David Ruy <2021-09-22> Ajustes Entrada Produção Parcelada PA000, PA001, PA002,....
   @Reviser David Ruy <2022-01-04> Ajustes TD-S/TD-E CardCode e CardName, enviar null quando vier vazio
   @Reviser David Ruy <2022-03-18> Ajustes NumCPF e NumCNPJ
   @Reviser David Ruy <2022-09-24> Novos campos : oBPLId, oIdSales, oIdCommerce, oIdRplOrder
   @Reviser David Ruy <2022-12-01> Status = 0 na inclusão para evitar processamento parcial de itens na PROC_INTEGRA_AtualizarSLIN
   @Reviser David Ruy <2023-06-29> Busca o ultimo registro "PA" em aberto
   @Reviser David Ruy <2023-06-29> No retorno MENSAGEM = xchave_integracao
   @Reviser David Ruy <2023-10-26> Aumento campo oNomeVendedor
   @Reviser David Ruy <2024-06-18> Quando for PA, analisa Serial = DocNum => checa status, caso contrário, checa Serial
   @Reviser David Ruy <2024-06-24> Gravar Registro vindo da leitura de PickList DocNum = concat(DocNum,'-',Sequencia)   
   @Reviser David Ruy <2024-08-13> Novos campos (BRW) oDocEntryRef, oDocNumRef, oDocTotal
   @Reviser David Ruy <2024-08-19> Alteração Parametro oObservacoes varchar(500) -> varchar(2000) 
   @Reviser David Ruy <2025-01-27> oU_BDO_NKIT
   @Reviser David Ruy <2025-11-27> Ajuste para considerar (tbintegraSAP_empresas.CardCode_For, tbintegraSAP_empresas.CardCode_Cli) quando parametro CardCode estiver vazio 
   @Reviser David Ruy <2026-07-24> Novo campo oQtdeOriItens para não liberar o processo com qtde de itens quebrada
   *******************************************************************************/
   DECLARE xIncAlt 	      VARCHAR(01)	DEFAULT 'I';
   DECLARE xStatusAnt      VARCHAR(02);
   DECLARE xStatusAux      VARCHAR(02);
   DECLARE xCodErro	      INT DEFAULT 0;
   DECLARE excecao 	      INT DEFAULT 0;
   DECLARE xflgGeraMovtoTr INT DEFAULT 1;
   DECLARE xcnpj_cpf_cli   VARCHAR(20);
   DECLARE xraz_social     VARCHAR(100);
   DECLARE xOrigem         VARCHAR(30);
   DECLARE xDestino        VARCHAR(20);
   DECLARE xCondicao       VARCHAR(100) DEFAULT ""; 
   DECLARE xTipoDocSLIN    VARCHAR(01);
   DECLARE xStrAux         VARCHAR(10) DEFAULT NULL;
   DECLARE xIntAux         INT DEFAULT 0;
   DECLARE xchave_integracao VARCHAR(50);
   DECLARE xDocNum         VARCHAR(30);
   DECLARE xidPicking      INT(11);
   DECLARE xObjDocVendas   VARCHAR(01);
   DECLARE xSequenciaPV    INT(11);
   
   
   
   DECLARE EXIT HANDLER FOR SQLEXCEPTION
   BEGIN
       GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
       SET excecao   = 1;
       SET RESULTADO = 0;
       SET MENSAGEM  = of_logistica.fnMensagemExcecao(
          CONCAT('ERRO Gerar DocEntry ',oDocTipo,"",oDocNum,"|",oDocEntry," =>",xDocNum," ",MENSAGEM) );
       SELECT MENSAGEM;
       ROLLBACK;
   END;  
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   SET xStatusAnt = NULL;
   SET oCnpjTransp = of_logistica.fnTirarCaracteresEspeciais(oCnpjTransp);
   SET oNomeTransp = SUBSTRING(oNomeTransp,1,50);
   
   
   
   
   -- Buscar Parametros
   SELECT cnpj_cpf_cli, raz_social #, ObjDocVendas
   INTO xcnpj_cpf_cli, xraz_social #, xObjDocVendas
   FROM tbintegraSAP_parametros
   INNER JOIN of_logistica.tbfiliais ON
              tbfiliais.num_cnpj = tbintegraSAP_parametros.cnpj_cpf_cli
   LIMIT 1;
   
   
   
   -- Verificar Status Inicial do Documento
   SELECT StatusDoc INTO xStatusAnt
   FROM tbintegraSAP_Doc
   WHERE DocEntry = oDocEntry 
     AND DocTipo = oDocTipo
     #AND IF(xObjDocVendas='P', idPicking = oid_request, TRUE);
     AND IF(oid_request IS NULL, TRUE, idPicking = oid_request);
     
   SET xIncAlt = 'A';
   #Se oStatusDoc (Status Parametro) = 1 => Cancelado
   #Senão mantem o Status do Documento
   IF oStatusDoc = '1' THEN
      SET xStatusAux = '9';
   ELSE 
      IF xStatusAnt IS NULL THEN
         #SET xStatusAux = '1';
         SET xStatusAux = NULL;
      ELSE
         SET xStatusAux = IF(xStatusAnt="1","2",xStatusAnt);
      END IF;
   END IF;
   
   
   SELECT cnpj_cpf_cli, raz_social 
   INTO xcnpj_cpf_cli, xraz_social
   FROM tbintegraSAP_parametros
   INNER JOIN of_logistica.tbfiliais ON
              tbfiliais.num_cnpj = tbintegraSAP_parametros.cnpj_cpf_cli
   LIMIT 1;
   
   
   SET @cod_deposito = NULL; SET @id_empresa = NULL; SET @cod_emp_slin = NULL; SET @cod_fil_slin = NULL;
   IF oDocTipo = "TD-E" THEN #AND IFNULL(oCardCode,"") = "" THEN
      SET xOrigem  = oWhareHouseTransf;
      SET xDestino = oWhareHouse;
      SELECT TB0.cod_deposito, TB0.id_empresa, TB1.cod_emp_slin, TB1.cod_fil_slin, 
         #IFNULL(oCardCode,IFNULL(TB1.cnpj_empresa,xcnpj_cpf_cli)),
         #IFNULL(oCardName,IFNULL(TB2.raz_social,xraz_social))
         IFNULL(IF(oCardCode='',NULL,oCardCode),TB1.CardCode_For),   #IF(oCardCode='',NULL,oCardCode),
         IFNULL(IF(oCardCode='',NULL,oCardName),TB1.raz_social)      #IF(oCardName='',NULL,oCardName)         
      INTO @cod_deposito, @id_empresa, @cod_emp_slin, @cod_fil_slin, oCardCode, oCardName
      FROM tbintegraSAP_Depositos TB0
      LEFT JOIN tbintegraSAP_empresas TB1 ON 
                TB1.id_integracao = TB0.id_empresa
      LEFT JOIN of_logistica.tbfiliais TB2 ON 
                TB2.cod_empresa = TB1.cod_emp_slin
            AND TB2.cod_filial  = TB1.cod_fil_slin
      WHERE TB0.cod_deposito = oWhareHouse;
      
      SET xflgGeraMovtoTr = @cod_emp_slin IS NOT NULL;
   END IF;
   IF oDocTipo = "TD-S" THEN #AND IFNULL(oCardCode,"") = "" THEN
      SET xOrigem  = oWhareHouse;
      SET xDestino = oWhareHouseTransf;
      SELECT TB0.cod_deposito, TB0.id_empresa, TB1.cod_emp_slin, TB1.cod_fil_slin, 
         #IFNULL(oCardCode,IFNULL(TB1.cnpj_empresa,xcnpj_cpf_cli)),
         #IFNULL(oCardName,IFNULL(TB2.raz_social,xraz_social))
         IFNULL(IF(oCardCode='',NULL,oCardCode),TB1.CardCode_Cli),   #IF(oCardCode='',NULL,oCardCode),
         IFNULL(IF(oCardCode='',NULL,oCardName),TB1.raz_social)      #IF(oCardName='',NULL,oCardName)         
      INTO @cod_deposito, @id_empresa, @cod_emp_slin, @cod_fil_slin, oCardCode, oCardName
      FROM tbintegraSAP_Depositos TB0
      LEFT JOIN tbintegraSAP_empresas TB1 ON 
                TB1.id_integracao = TB0.id_empresa
      LEFT JOIN of_logistica.tbfiliais TB2 ON 
                TB2.cod_empresa = TB1.cod_emp_slin
            AND TB2.cod_filial  = TB1.cod_fil_slin
      WHERE TB0.cod_deposito = oWhareHouse;
      SET xflgGeraMovtoTr = @cod_emp_slin IS NOT NULL;
   END IF;
   
   IF oDocTipo = "PA" THEN
      #Tratativa para Ordem de Produção : Recebimento Parcelado
      #Gerar PA000, PA001, PA002, .....
      SET xStrAux = NULL;
      
      
      #Busca o ultimo registro "PA" em aberto
      SELECT MAX(DocTipo) INTO xStrAux 
      FROM tbintegraSAP_Doc
      WHERE SUBSTRING(DocTipo,1,2)  = "PA"
        AND DocEntry = oDocEntry
        #AND PlannedQty = oPlannedQty;
        #AND StatusDoc < 6;
        #Se Serial = DocNum (Leitura da OP), se não, Leitura da Entrada de Produção
        AND IF(oSerial = oDocNum, StatusDoc < 6, SERIAL = oSerial);
        
        
      #Inclusão
      IF IFNULL(xStrAux,'') = '' THEN 
--          NOT EXISTS (SELECT DocTipo
--                      FROM tbintegraSAP_Doc
--                      WHERE SUBSTRING(DocTipo,1,2)  = "PA"
--                        AND DocEntry = oDocEntry
--                        AND PlannedQty = oPlannedQty) THEN
                       
         SELECT MAX(DocTipo) INTO xStrAux
         FROM tbintegraSAP_Doc
         WHERE SUBSTRING(DocTipo,1,2)  = "PA"
           AND DocEntry = oDocEntry;
           
         IF IFNULL(xStrAux,'') = '' THEN 
            SET xStrAux = 'PA000';
         ELSE 
            SET xStrAux = CONCAT("PA", LPAD(CONVERT(CONVERT(SUBSTR(xStrAux,3,3),SIGNED)+1,CHAR),3,'0'));
         END IF;
         
      ELSE
         #Alteração
         SET xStatusAux = '0'; #NULL;
      END IF;
      SET oDocTipo = xStrAux;
                    
   END IF;
   
   
   
   
   
   #@Reviser David Ruy <2024-06-24> Pedido de Venda Parcial via leitura PickList (DocNum-Sequencia)
   IF oDocTipo = 'PV' AND oid_request IS NOT NULL THEN # and xObjDocVendas = 'P' THEN
      SET xidPicking = oid_request;
      SET xDocNum = NULL;
      IF EXISTS (SELECT 1 FROM tbintegraSAP_Doc 
                 WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND idPicking = xidPicking) THEN
         SELECT DocNum FROM xDocNum tbintegraSAP_Doc 
         WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND idPicking = xidPicking;
      
        
      ELSEIF EXISTS (SELECT 1 FROM tbintegraSAP_Doc 
                     WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo AND StatusDoc = 3) THEN
                     
         SELECT MAX(DocNum) DocNum INTO xDocNum
         FROM tbintegraSAP_Doc 
         WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo
           AND StatusDoc = 3;
         
         -- Cancelar o PV e gerar um novo registro : PROC_Integra_AtuStatusDocEntry
         -- Cancelar GSM (gerar logs de alteração) : PROC_Integra_CancelarGSM
         IF xDocNum IS NULL THEN
            SET xSequenciaPV = 1;
         ELSE
            IF POSITION('.' IN xDocNum) > 0 THEN
               SET xSequenciaPV = CAST(SUBSTRING_INDEX(xDocNum,'.',-1) AS UNSIGNED)+1;
            ELSE
               SET xSequenciaPV = 1;
            END IF;
         END IF;
         
      ELSE
         SELECT MAX(DocNum) DocNum INTO xDocNum
         FROM tbintegraSAP_Doc 
         WHERE DocEntry = oDocEntry AND DocTipo = oDocTipo;
				  
         IF xDocNum IS NULL THEN
            SET xSequenciaPV = 1;
         ELSE
            IF POSITION('.' IN xDocNum) > 0 THEN
               SET xSequenciaPV = CAST(SUBSTRING_INDEX(xDocNum,'.',-1) AS UNSIGNED)+1;
            ELSE
               SET xSequenciaPV = 1;
            END IF;
         END IF;
         
				  END IF;
				  
				  SET xDocNum = CONCAT(oDocNum,'.',xSequenciaPV);        
				  SET oDocNum = xDocNum;  
   END IF;
      
   SET xchave_integracao = CONCAT(oDocTipo, oDocNum,'-',oDocEntry);
   IF IFNULL(xStatusAux,'1') = '1' AND xflgGeraMovtoTr = 1 THEN
      #Inclusão
      INSERT INTO tbintegraSAP_Doc
         (DocEntry, DocTipo, DocNum, TipoProducao, ItemCode, DocDate, DueDate, 
          CardCode, CardName, NumCNPJ, NumCPF, SERIAL,
          BPLId, IdSales, IdCommerce, U_RSD_RplOrder, U_BDO_NKIT,
          AddrTypeS, StreetS, StreetNoS, BuildingS, BlockS, CityS, ZipCodeS, StateS, CountryS, 
          NomeVendedor, CFOP, TipoFrete, NomeTransp, CnpjTransp,	TransportationCode,
          Route, StartTime1, EndTime1, StartTime2, EndTime2, End_Entrega,
          StatusDoc, PlannedQty,
          DocEntryRef, DocNumRef, DocTotal, QtdeOriItens,
          WhareHouse, WhareHouseTransf, StatusEnum, id_request, Observacoes, 
          dthr_inc, usu_inc, idPicking,chave_integracao)
      VALUES (oDocEntry, oDocTipo, oDocNum, oTipoProducao, oItemCode, oDocDate, oDueDate, 
          oCardCode, oCardName, oNumCNPJ, oNumCPF, oSerial,
          oBPLId, oIdSales, oIdCommerce, oIdRplOrder, oU_BDO_NKIT,
          oAddrTypeS, oStreetS, oStreetNoS, oBuildingS, oBlockS, oCityS, oZipCodeS, oStateS, oCountryS, 
          oNomeVendedor, oCFOP, oTipoFrete, oNomeTransp, oCnpjTransp, oTransportationCode,
          oRoute, oStartTime1, oEndTime1, oStartTime2, oEndTime2, oEnd_Entrega,          
          xStatusAux, oPlannedQty, 
          oDocEntryRef, oDocNumRef, oDocTotal, oQtdeOriItens, 
          oWhareHouse, oWhareHouseTransf, oStatusEnum, oid_request, oObservacoes, NOW(), oCodUsuario,
          #Temporariamente, até que XNET resolva a criação de picking para TD-S
          #IF(oDocTipo='TD-S',0,NULL),
          #Alterado pois o picking é gerado pelo serviço OVERFLASH
          xidPicking,
          xchave_integracao ); 
      SET RESULTADO = 1;
      SET MENSAGEM = CONCAT("Registro inserido com sucesso - chave_integracao:",xchave_integracao);
      
   ELSEIF xStatusAux = '9' AND (xStatusAux <> xStatusAnt) THEN
      #Cancelamento / Preserva a hora do cancelamento
      CALL PROC_INTEGRA_AtualizarStatusDocEntry('999999', oDocEntry, oDocTipo, oDocNum, oStatusDoc, @R, @M);
      SET RESULTADO = 9;
      SET MENSAGEM = CONCAT("Registro CANCELADO com sucesso - chave_integracao:",xchave_integracao);
      
   #ELSEIF xStatusAnt < "4" THEN
   ELSEIF xStatusAnt IS NULL THEN
      #Se Status Anterior : Não iniciado SLIN, então atualiza
      #@Reviser David Ruy <2020/02/28> Nunca atualizar a integração pois já 
      #                                existem endpoints de atualização / cancelamento
      UPDATE tbintegraSAP_Doc SET 
         DocNum     = oDocNum 
         ,TipoProducao = oTipoProducao
         ,ItemCode  = oItemCode 
         ,DocDate   = oDocDate
         ,DueDate   = oDueDate 
         ,CardCode  = oCardCode 
         ,CardName  = oCardName 
         ,NumCNPJ   = oNumCNPJ
         ,NumCPF    = oNumCPF
         ,SERIAL    	= oSerial
         
         ,BPLId = oBPLId
         ,IdSales = oIdSales
         ,IdCommerce = oIdCommerce
         ,U_RSD_RplOrder = oIdRplOrder         
         ,U_BDO_NKIT = oU_BDO_NKIT
         
         ,AddrTypeS 	= oAddrTypeS
         ,StreetS   	= oStreetS
         ,StreetNoS 	= oStreetNoS
         ,BuildingS 	= oBuildingS
         ,BlockS    	= oBlockS
         ,CityS     	= oCityS
         ,ZipCodeS  	= oZipCodeS 
         ,StateS    	= oStateS 
         ,CountryS  	= oCountryS 
         ,NomeVendedor  = oNomeVendedor
         ,CFOP          = oCFOP
         ,TipoFrete     = oTipoFrete
         ,NomeTransp    = oNomeTransp
         ,CnpjTransp    = oCnpjTransp    
         ,TransportationCode = oTransportationCode
              
         ,Route       	= oRoute 
         ,StartTime1  	= oStartTime1
         ,EndTime1    	= oEndTime1
         ,StartTime2  	= oStartTime2
         ,EndTime2    	= oEndTime2
         ,End_Entrega 	= oEnd_Entrega
         
         #,StatusDoc = oStatusDoc 
         ,PlannedQty 	= oPlannedQty
         
         ,DocEntryRef = oDocEntryRef
         ,DocNumRef   = oDocNumRef
         ,DocTotal    = oDocTotal
         
         ,WhareHouse 	= oWhareHouse
         ,WhareHouseTransf = oWhareHouseTransf
         ,StatusEnum 	= oStatusEnum
         ,id_request 	= oid_request
         ,Observacoes   = IF(LENGTH(IFNULL(oObservacoes,''))=0,NULL, oObservacoes)
         ,dthr_alt      = NOW()
         ,usu_alt       = oCodUsuario

      WHERE DocEntry = oDocEntry 
        AND DocTipo = oDocTipo
        AND IF(xidPicking IS NULL, TRUE, idPicking = xidPicking);
        
      SET RESULTADO = xStatusAux;
      SET MENSAGEM = CONCAT("Registro atualizado com sucesso  - chave_integracao:",xchave_integracao);
      
   ELSE
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT("Registro não atualizado - Status Pedido => Ant=",xStatusAnt," <> Novo=",xStatusAux," chave_integracao:",xchave_integracao);		
   END IF;
   
   
   #Excluir do processamento as OP´s com TipoProducao Externa
   #Elinox : Nunca realizar leitura de OP´ pois TODAS serão integradas via transferencia de estoque
   #Demais clientes : Se o flag na tbintegraSAP_TipoDoc = E/S, gera SE OP Externa (PEX,PEC)
   SELECT Condicao, TipoDocSLIN INTO xCondicao, xTipoDocSLIN 
   FROM tbintegraSAP_TipoDoc
   WHERE DocTipo = oDocTipo LIMIT 1;
   
   
   #Monta script UPDATE
   SET @SQL = CONCAT("UPDATE tbintegraSAP_Doc ",
                     "SET tbintegraSAP_Doc.StatusAnt = tbintegraSAP_Doc.StatusDoc, ",
                     "    tbintegraSAP_Doc.StatusDoc = 10 ",
                     "WHERE tbintegraSAP_Doc.DocEntry = ",oDocEntry," ",
                     "  AND tbintegraSAP_Doc.DocTipo  = '",oDocTipo,"' ",
                     IF(xidPicking IS NULL, "",CONCAT(" AND  tbintegraSAP_Doc.idPicking = ",xidPicking)),
                     "  AND tbintegraSAP_Doc.StatusDoc = '1' ",
                     IF(xTipoDocSLIN NOT IN ('E','S'), 
                        #Se XtipoDocSLin != E/S, então dá update para ignorar o processamento
                        "",
                        IF(xCondicao = '',
                           #Se nao tem condição, não dá update, ou seja, processa
                           "and false", 
                           #se tem condição, dá update no inverso da condição
                           CONCAT(" and not ",xCondicao)
                           )
                        ));
   #select xCondicao, xTipoDocSLIN ;
   #select @SQL;
   
   
   #Executa o UpDATE
   PREPARE stmt1 FROM @SQL;
   EXECUTE stmt1;
   DEALLOCATE PREPARE stmt1;   
   
   
   IF xflgGeraMovtoTr <> 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - ERRO Transferencia não inserida =>",oDocTipo, oDocNum,'-',oDocEntry,"(",xOrigem,'/',xDestino,")"); 
   END IF;
   
   IF excecao = 1 THEN
      ROLLBACK;
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - ERRO SQL - Verifique com o Administrador");
      #SELECT RESULTADO, MENSAGEM;
   ELSE
      COMMIT;
   END IF;
END$$

DELIMITER ;