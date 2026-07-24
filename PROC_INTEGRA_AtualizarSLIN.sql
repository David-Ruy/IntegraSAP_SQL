DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_AtualizarSLIN Verificar_20240813`$$

CREATE PROCEDURE `PROC_INTEGRA_AtualizarSLIN Verificar_20240813`(
	IN oCodUsuario				  VARCHAR(10),
	IN oDocTipo         VARCHAR(50),
	# Parametros de Retorno
	OUT RESULTADO       INT,
	OUT MENSAGEM        VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************
  * @Created David Ruy <2019/04/11>
  * Esta procedure realiza a atualização do SLIN de registros pendentes na base de dados intermediária da integração
  *
  *@Reviser David Ruy <2021/03/24> Cadastrar transportadora na tbclientes (PROC_INTEGRA_CAD_Fornecedor)
  *@Reviser David Ruy <2021/04/14> Gravar o campo SERIAL (xSerialNum -> NumNF Fornecedor) na GEM
  *@Reviser David Ruy <2021/08/24> Tratativa para DocTipo = "TD-<E>/<S>" Transferencia entre Depósitos
  *@Reviser David Ruy <2022/02/10> Agrupamento de SKU para TD-S quando flg_agrupa_transf=1 (Produção)
  #@Reviser David Ruy <2022/03/17> Ajuste para atualizar tbsolic_saidas_item2->deposito_integracao    (PROC_INTEGRA_GerarGSMItem)
  #@Reviser David Ruy <2022/05/11> Ajuste para atualizar tbsolic_entradas_item2->deposito_integracao  (PROC_INTEGRA_GerarGEMItem) 
  #@Reviser David Ruy <2022-08-08> Atualizar Valor (PRICE) do Item quando foi em caixas  
  #@Reviser David Ruy <2023-01-11> Alteração ifNull(UomCode,buyUnitMsr) e ifNull(UomCode,salUnitMsr)
                                   Alteração envio gerarGEM/gerarGSM xBaseQty em vez de xOpenInvQty
  #@Reviser David Ruy <2023-02-07> Alteração PROC_INTEGRA_GerarGSMItem (Parametros xBaseQty, e xOpenInvQty)
  #@Reviser David Ruy <2023-02-08> Alteração PROC_INTEGRA_GerarGEMItem (Parametros xBaseQty, e xOpenInvQty)
  #@Reviser David Ruy <2023-03-01> Alteração agrupamento linhas TD-S conforme flg_agrupa_transf
  #@Reviser David Ruy <2023-04-22> Alteração agrupamento linhas TD-S group by
  #@Reviser David Ruy <2023-07-07> Não grava numero de GEM/GSM que não tenha sido inserida corretamente  
  #@Reviser David Ruy <2023-07-14> Devolução de Vendas pegar Embalagem de Vendas
  #@Reviser David Ruy <2024-02-19> Parametro oDocTipo para isolar criação de Documentos para cada serviço
  #@Reviser David Ruy <2024-03-25> Transaction e chamada da inserção de itens  
  #@Reviser David Ruy <2024-06-19> Alteração variável xObservacoes -> SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) 
  #@Reviser David Ruy <2024-08-29> Correção join tTabelaComTexto => tbTMPTipoDoc, tbTMPTipoDoc2
  #@Reviser David Ruy <2024-10-17> Variaveis xDepositoOrigem/xDepositoDestino (se precisar para alguma regra)
  #@Reviser David Ruy <2024-10-17> xCNPJEmpresa <> xNumCPFouCNPJ para não gerar Entregas
  #@Reviser David Ruy <2025-01-15> DocTipo = 'DC'  Devolução de Compras
  #@Reviser David Ruy <2025-01-27> xDocNumRef e xBDO_NKIT + Call Proc_IntegraSAP_GerarGEM (Versão_20240813)
  #@Reviser David Ruy <2025-07-21> #xDocNumRef, xBDO_NKIT,  Já tratados direto no GerarGEM
  #@Reviser David Ruy <2025-10-03> Não gerar TMS para TD-S
  #@Reviser David Ruy <2025-10-29> Considerar PA000 até PA099
  *************************************************************************/
   DECLARE excecao         INT DEFAULT 0;
   DECLARE xVarAux         INT DEFAULT 0;
   DECLARE xGerouGuia      BOOLEAN;
   DECLARE xDocTipo        VARCHAR(10);
   DECLARE xDocEntry       INT;
   DECLARE xDocNum         VARCHAR(20);
   DECLARE xSerialNum      INT;
   DECLARE xDocDate        DATETIME;
   DECLARE xDueDate        DATETIME;
   DECLARE xStatusDoc      VARCHAR(10);
   DECLARE xStatusEnum     INT;
   DECLARE xWhareHouse     VARCHAR(30);
   DECLARE xCardCode       VARCHAR(15);
   DECLARE xCardName       VARCHAR(100);
   DECLARE xAddrTypeS      VARCHAR(20);
   DECLARE xStreetS        VARCHAR(200);
   DECLARE xStreetNoS      VARCHAR(30);
   DECLARE xBuildingS      VARCHAR(100);
   DECLARE xBlockS         VARCHAR(100);
   DECLARE xCityS          VARCHAR(100);
   DECLARE xZipCodeS       VARCHAR(10);
   DECLARE xStateS         VARCHAR(02);
   DECLARE xCountryS       VARCHAR(50);
   DECLARE xTipoFrete      VARCHAR(05);
   DECLARE xNomeTransp     VARCHAR(50);
   DECLARE xCnpjTransp     VARCHAR(20);
   DECLARE xCFOP           VARCHAR(10);
   DECLARE xObservacoes    TEXT;
   DECLARE xNomeVendedor   VARCHAR(200)   DEFAULT "Nome Vendedor";
   DECLARE xValorPedido    DOUBLE   DEFAULT 0;
   DECLARE xFlgInclusao    BOOLEAN;
   
   DECLARE xLineNum           INT;
   DECLARE xItemCode          VARCHAR(30);
   DECLARE xBaseQty           DOUBLE;
   DECLARE xOpenInvQty        DOUBLE;
   DECLARE xVlrUnitario       DOUBLE;
   DECLARE xCambio            DOUBLE;
   DECLARE xWhareHouseIte     VARCHAR(10); 
   DECLARE xStatusItem        VARCHAR(10);
   DECLARE xObservacoesIte    VARCHAR(300); 
   DECLARE xdescription       VARCHAR(100); 
   DECLARE xbuyUnitMsr        VARCHAR(30); 
   DECLARE xsalUnitMsr        VARCHAR(30); 
   DECLARE xinvntryUom        VARCHAR(30); 
   DECLARE xNumInSale         DECIMAL(18,6);
   DECLARE xNumInBuy          DECIMAL(18,6);
   DECLARE xBatchCode         VARCHAR(30); 
   DECLARE xCodEmpWMS			      VARCHAR(03);
   DECLARE xCodFilWMS			      VARCHAR(03);
   DECLARE xAnoSolic 			      VARCHAR(04);
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xRefGuia           VARCHAR(30);
   DECLARE xCodErro           INT;
   DECLARE _VlrUnitario       DOUBLE   DEFAULT 1;
   DECLARE xNumItem           VARCHAR(06);
   DECLARE xStatusSlin        INT;
   DECLARE xMensagemSlin      VARCHAR(500);
   
   DECLARE xStrAux            VARCHAR(200);
   DECLARE xLog               VARCHAR(30);
   DECLARE xEndereco          VARCHAR(100);
   DECLARE xNumEnde           VARCHAR(30);
   DECLARE xComplEnde         VARCHAR(200);
   DECLARE xBairroEnde        VARCHAR(50);
   DECLARE xCidadeEnde        VARCHAR(50);
   DECLARE xCepEnde           VARCHAR(10);
   DECLARE xUFEnde            VARCHAR(02);
   DECLARE xPaisEnde          VARCHAR(50);
   DECLARE xhora1_entrega     VARCHAR(20);
   DECLARE xhora2_entrega     VARCHAR(20);
   DECLARE xhora3_entrega     VARCHAR(20);
   DECLARE xhora4_entrega     VARCHAR(20);
   DECLARE xEnd_Entrega       VARCHAR(200);
   DECLARE xTipoProducao      VARCHAR(10);
   DECLARE xflg_agrupa_transf TINYINT;
   
   DECLARE xTipoPessoa        VARCHAR(01);
   DECLARE xNumCPF            VARCHAR(20);
   DECLARE xNumCNPJ           VARCHAR(20);
   DECLARE xNumCPFouCNPJ      VARCHAR(20);
   DECLARE xCNPJCPFCLI        VARCHAR(20);
   DECLARE xCodEmpSLIN        VARCHAR(03);
   DECLARE xCodFilSLIN        VARCHAR(03);
   DECLARE xCNPJEmpresa       VARCHAR(20);
   DECLARE xDepositoOrigem    VARCHAR(20);
   DECLARE xDepositoDestino   VARCHAR(20);
   
   DECLARE xDocTipoAux        VARCHAR(50);
   DECLARE xDocNumRef         VARCHAR(50);
   DECLARE xBDO_NKIT          VARCHAR(50);
   
   SELECT flg_agrupa_transf INTO xflg_agrupa_transf 
   FROM tbintegraSAP_parametros LIMIT 1;
   
   
   IF oDocTipo = "" THEN
      CREATE TEMPORARY TABLE tTabelaComTexto (Coluna01 VARCHAR(100));
      INSERT INTO tTabelaComTexto SELECT DocTipo FROM tbintegraSAP_TipoDoc;

      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
      CREATE TEMPORARY TABLE tbTMPTipoDoc (SELECT * FROM tTabelaComTexto);

      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc2;
      CREATE TEMPORARY TABLE tbTMPTipoDoc2 (SELECT * FROM tTabelaComTexto);

   ELSE
      CALL PROC_SYS_GerarTabelaComTexto(oDocTipo,'|',1);
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
      CREATE TEMPORARY TABLE tbTMPTipoDoc (SELECT * FROM tTabelaComTexto);
      
      #Insere PA000 até PA099
      IF EXISTS (SELECT 1 FROM tbTMPTipoDoc WHERE Coluna01 = 'PA') THEN
         SET xVarAux = 0;
         WHILE xVarAux <= 99 DO
            INSERT INTO tbTMPTipoDoc (Coluna01) VALUES (CONCAT('PA',LPAD(xVarAux,3,'0')));
            SET xVarAux = xVarAux + 1;
         END WHILE;
      END IF;
      #select * from tbTMPTipoDoc; leave BLOCO1;
      
      DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc2;
      CREATE TEMPORARY TABLE tbTMPTipoDoc2 (SELECT * FROM tbTMPTipoDoc);

   END IF;
   
 
   #1a fase - Inserir documentos sem id-SLIN
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo;
   CREATE TEMPORARY TABLE tbtmp_IntegraDocTopo 
      SELECT tbintegraSAP_Doc.*,
             tbintegraSAP_empresas.cod_emp_slin AS CodEmpSLIN,
             tbintegraSAP_empresas.cod_fil_slin AS CodFilSLIN,
             tbintegraSAP_empresas.cnpj_empresa AS CNPJEmpresa,
             tbDepOri.cod_deposito DepositoOrigem, tbDepDest.cod_deposito DepositoDestino
      FROM tbintegraSAP_Doc
      INNER JOIN tbTMPTipoDoc ON
                 tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
      INNER JOIN tbintegraSAP_empresas ON 
                 tbintegraSAP_empresas.id_integracao = tbintegraSAP_Doc.BPLId
      LEFT JOIN tbintegraSAP_Depositos tbDepOri ON
                tbintegraSAP_Doc.WhareHouse = tbDepOri.cod_deposito
      LEFT JOIN tbintegraSAP_Depositos tbDepDest ON
                tbintegraSAP_Doc.WhareHouseTransf = tbDepDest.cod_deposito
      #WHERE cod_emp IS NULL
      #WHERE StatusDoc <= "3"
      WHERE StatusDoc < "3"      
      # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
      AND IF(Doctipo IN ('PV','OP','TD-S','NS'), idPicking IS NOT NULL, TRUE)
      ORDER BY DocTipo, DocEntry, DocNum;
      
   #Tabela Gemea para Union
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo2;
   CREATE TEMPORARY TABLE tbtmp_IntegraDocTopo2 
      SELECT tbintegraSAP_Doc.*,
             tbintegraSAP_empresas.cod_emp_slin AS CodEmpSLIN,
             tbintegraSAP_empresas.cod_fil_slin AS CodFilSLIN,
             tbintegraSAP_empresas.cnpj_empresa AS CNPJEmpresa,
             tbDepOri.cod_deposito DepositoOrigem, tbDepDest.cod_deposito DepositoDestino
      FROM tbintegraSAP_Doc
      INNER JOIN tbTMPTipoDoc ON
                 tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
      INNER JOIN tbintegraSAP_empresas ON 
                 tbintegraSAP_empresas.id_integracao = tbintegraSAP_Doc.BPLId
      LEFT JOIN tbintegraSAP_Depositos tbDepOri ON
                tbintegraSAP_Doc.WhareHouse = tbDepOri.cod_deposito
      LEFT JOIN tbintegraSAP_Depositos tbDepDest ON
                tbintegraSAP_Doc.WhareHouseTransf = tbDepDest.cod_deposito
      #WHERE cod_emp IS NULL
      #WHERE StatusDoc <= "3"
      WHERE StatusDoc < "3"      
      # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
      AND IF(Doctipo IN ('PV','OP','TD-S','NS'), idPicking IS NOT NULL, TRUE)
      ORDER BY DocTipo, DocEntry, DocNum;
      
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   IF xflg_agrupa_transf = 0 THEN   
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         SELECT tbintegraSAP_DocItem.* FROM tbintegraSAP_DocItem
         INNER JOIN tbtmp_IntegraDocTopo Topo ON
                    Topo.DocEntry = tbintegraSAP_DocItem.DocEntry
                AND Topo.DocTipo  = tbintegraSAP_DocItem.DocTipo                 
                AND Topo.DocNum   = tbintegraSAP_DocItem.DocNum
         INNER JOIN tbintegraSAP_Doc ON
             tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
         AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
         AND tbintegraSAP_Doc.DocNum   = tbintegraSAP_DocItem.DocNum
         INNER JOIN tbTMPTipoDoc ON
                    tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
         #WHERE tbintegraSAP_Doc.cod_emp IS NULL
         WHERE TRUE #StatusDoc <= "3"
         # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
         AND IF(tbintegraSAP_DocItem.Doctipo IN ('PV','OP','TD-S','NS'), tbintegraSAP_Doc.idPicking IS NOT NULL, TRUE)
         AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '2'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
         ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum;
   ELSE
      CREATE TEMPORARY TABLE tbtmp_IntegraDocItem
         (
            #SELECT tbintegraSAP_DocItem.* 
            SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                   tbintegraSAP_DocItem.LineNum, 
                   tbintegraSAP_DocItem.ItemCode, tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.OpenInvQty,
                   (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price,              
                   tbintegraSAP_DocItem.DollarQuote,
                   tbintegraSAP_DocItem.WhareHouse, 
                   tbintegraSAP_DocItem.StatusItem, 
                   tbintegraSAP_DocItem.UomCode,
                   #SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                   tbintegraSAP_DocItem.Observacoes,
                   tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                   tbintegraSAP_DocItem.invntryUom, 
                   tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode  
            FROM tbintegraSAP_DocItem
            INNER JOIN tbtmp_IntegraDocTopo Topo ON
                       Topo.DocEntry = tbintegraSAP_DocItem.DocEntry
                   AND Topo.DocTipo  = tbintegraSAP_DocItem.DocTipo                 
                   AND Topo.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tbintegraSAP_Doc ON
                tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
            AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
            AND tbintegraSAP_Doc.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tbTMPTipoDoc2 ON
                       tbTMPTipoDoc2.Coluna01 = tbintegraSAP_Doc.DocTipo
            #WHERE tbintegraSAP_Doc.cod_emp IS NULL
            WHERE NOT (tbintegraSAP_DocItem.Doctipo = 'TD-S')
            # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
            AND IF(tbintegraSAP_DocItem.Doctipo IN ('PV','OP','TD-S','NS'), tbintegraSAP_Doc.idPicking IS NOT NULL, TRUE)
            #Verificar : estava antes IFNULL(tbintegraSAP_DocItem.StatusItem,'2') 
            AND IFNULL(tbintegraSAP_DocItem.StatusItem,'0') <= '1'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
            ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.LineNum
         )
         UNION
         (
            #SELECT tbintegraSAP_DocItem.* FROM tbintegraSAP_DocItem
            SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
                   tbintegraSAP_DocItem.LineNum, 
                   tbintegraSAP_DocItem.ItemCode, SUM(tbintegraSAP_DocItem.BaseQty) BaseQty, SUM(tbintegraSAP_DocItem.OpenInvQty) OpenInvQty,
                   (tbintegraSAP_DocItem.Price*IF(IFNULL(tbintegraSAP_DocItem.DollarQuote,0)=0,1,tbintegraSAP_DocItem.DollarQuote)) Price, 
                   tbintegraSAP_DocItem.DollarQuote,
                   tbintegraSAP_DocItem.WhareHouse, 
                   tbintegraSAP_DocItem.StatusItem, 
                   tbintegraSAP_DocItem.UomCode,
                   #SUBSTRING(tbintegraSAP_DocItem.Observacoes,1,300) AS Observacoes, 
                   tbintegraSAP_DocItem.Observacoes,
                   tbintegraSAP_DocItem.description, tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, 
                   tbintegraSAP_DocItem.invntryUom, 
                   tbintegraSAP_DocItem.NumInSale, tbintegraSAP_DocItem.NumInBuy, tbintegraSAP_DocItem.BatchNumbersCode
            FROM tbintegraSAP_DocItem
            INNER JOIN tbtmp_IntegraDocTopo2 Topo ON
                       Topo.DocEntry = tbintegraSAP_DocItem.DocEntry
                   AND Topo.DocTipo  = tbintegraSAP_DocItem.DocTipo                 
                   AND Topo.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tbintegraSAP_Doc ON
                tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
            AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
            AND tbintegraSAP_Doc.DocNum   = tbintegraSAP_DocItem.DocNum
            INNER JOIN tTabelaComTexto ON
                       tTabelaComTexto.Coluna01 = tbintegraSAP_Doc.DocTipo
            #WHERE tbintegraSAP_Doc.cod_emp IS NULL
            WHERE (tbintegraSAP_DocItem.Doctipo = 'TD-S')
            # Se PV ou OP precisa ter criado o picking (validação de saldo no SAP) para poder gerar no SLIN
            AND IF(tbintegraSAP_DocItem.Doctipo IN ('PV','OP','TD-S','NS'), tbintegraSAP_Doc.idPicking IS NOT NULL, TRUE)
            #Verificar : estava antes IFNULL(tbintegraSAP_DocItem.StatusItem,'2') 
            AND IFNULL(tbintegraSAP_DocItem.StatusItem,'2') <= '1'  #Traz os itens com status nulo (a inserir) e 1 = A atualizar
            GROUP BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocNum, tbintegraSAP_DocItem.ItemCode
            ORDER BY tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocNum, tbintegraSAP_DocItem.LineNum
         );
         
         #select * from tbtmp_IntegraDocTopo ;
         #SELECT * from tbtmp_IntegraDocTopo2;
         DELETE FROM tbtmp_IntegraDocTopo 
         WHERE Doctipo IN ('TD-S');
         
         INSERT INTO tbtmp_IntegraDocTopo 
            SELECT * FROM tbtmp_IntegraDocTopo2
            WHERE Doctipo IN ('TD-S')
            GROUP BY Doctipo, DocEntry;
         
   END IF;
   #select * from tbtmp_IntegraDocTopo;
   #select * from tbtmp_IntegraDocItem;
   #leave BLOCO1;

   
   
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc2;
   
   
   #Atualizar Valor do Item quando for em caixas
   UPDATE tbtmp_IntegraDocItem
   SET Price = Price * IFNULL(BaseQty,1) / IFNULL(OpenInvQty,BaseQty)
   WHERE IFNULL(OpenInvQty,0) > 0 AND IFNULL(BaseQty,0) > 0;
   
   
   #Varre a lista de Documentos para inserir no SLIN   
   SET xEnd_Entrega = NULL;
   WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraDocTopo) DO
      SELECT DocTipo, DocEntry, DocNum, DocDate, DueDate, StatusDoc, StatusEnum, WhareHouse, 
             CardCode, CardName, NumCPF, NumCNPJ, SERIAL,
             AddrTypeS, SUBSTRING(StreetS,1,50), StreetNoS, SUBSTRING(BuildingS,1,50), SUBSTRING(BlockS,1,50), SUBSTRING(CityS,1,50), ZipCodeS, StateS, CountryS, 
             NomeVendedor, TipoFrete, NomeTransp, SUBSTRING(CnpjTransp,1,14), CFOP,
             StartTime1, EndTime1, StartTime2, EndTime2, End_Entrega,
             Observacoes, IFNULL(TipoProducao,"PEX"),
             CodEmpSLIN, CodFilSLIN, CNPJEmpresa, DepositoOrigem, DepositoDestino,             
             DocNumRef, U_BDO_NKIT,
             CodEmpSLIN, CodFilSLIN
      INTO xDocTipo, xDocEntry, xDocNum, xDocDate, xDueDate, xStatusDoc, xStatusEnum, xWhareHouse, 
             xCardCode, xCardName, xNumCPF, xNumCNPJ, xSerialNum,
             xAddrTypeS, xStreetS, xStreetNoS, xBuildingS, xBlockS, xCityS, xZipCodeS, xStateS, xCountryS,
             xNomeVendedor, xTipoFrete, xNomeTransp, xCnpjTransp, xCFOP,
             xhora1_entrega, xhora2_entrega, xhora3_entrega, xhora4_entrega, xEnd_Entrega,
             xObservacoes, xTipoProducao,
             xCodEmpSLIN, xCodFilSLIN, xCNPJEmpresa, xDepositoOrigem, xDepositoDestino,             
             xDocNumRef, xBDO_NKIT,
             xCodEmpSLIN, xCodFilSLIN
      FROM tbtmp_IntegraDocTopo 
      LIMIT 1;
      
      #Valores dos campos em letra maiúscula
      SET xCardName = UPPER(xCardName);
      SET xAddrTypeS = UPPER(xAddrTypeS);
      SET xStreetS = UPPER(xStreetS);
      SET xBuildingS = UPPER(xBuildingS);
      SET xStreetNoS = UPPER(xStreetNoS);
      SET xBlockS = UPPER(xBlockS);
      SET xCityS = UPPER(xCityS);
      SET xStateS = UPPER(xStateS);
      SET xCountryS = UPPER(xCountryS);
      SET xNumCPF  = of_logistica.fnTirarCaracteresEspeciais(xNumCPF);
      SET xNumCNPJ = of_logistica.fnTirarCaracteresEspeciais(xNumCNPJ);
      SET xNumCPFouCNPJ = IFNULL(IFNULL(xNumCPF,xNumCNPJ),'');
      #SET xTipoPessoa = IF(LENGTH(xNumCPFouCNPJ)=0,'',IF(LENGTH(xNumCPFouCNPJ)=14,'J','F'));
      SET xTipoPessoa = IF(LENGTH(IFNULL(xNumCPF,''))>0,'F', IF(LENGTH(IFNULL(xNumCNPJ,''))>0,'J', ''));
            
      
      #Nomes das Variáveis de Endereço SLIN
      #IF xEnd_Entrega IS NULL THEN
         SET xEndereco   = CONCAT(IFNULL(xAddrTypeS,''), IF(IFNULL(xStreetS,'')='','',' '), IFNULL(xStreetS,''));
         SET xNumEnde    = xStreetNoS;
         SET xComplEnde  = xBuildingS;
         SET xBairroEnde = xBlockS;
         SET xCidadeEnde = xCityS;
         SET xCepEnde    = fnSoNumeros(xZipCodeS,'');
         SET xUFEnde     = xStateS;
         SET xPaisEnde   = xCountryS;
      /*ELSE
         #logradouro,numero <newline> complemento <newline> Bairro <newline> cep - Cidade - Estado <newline> pais         
         CALL PROC_INTEGRA_MontaEndereco(xEnd_Entrega, xLog, xEndereco, xNumEnde, xComplEnde, xBairroEnde, xCepEnde, xCidadeEnde, xUFEnde, xPaisEnde);
         SET xEndereco   = IFNULL(CONCAT(xLog,' ',xEndereco), CONCAT('*',IFNULL(xAddrTypeS,''), IF(IFNULL(xStreetS,'')='','',' '), IFNULL(xStreetS,'')));
         SET xNumEnde    = IFNULL(xNumEnde, CONCAT('*',xStreetNoS));
         SET xComplEnde  = IFNULL(xComplEnde, CONCAT('*',xBuildingS));
         SET xBairroEnde = IFNULL(xBairroEnde, CONCAT('*',xBlockS));
         SET xCidadeEnde = IFNULL(xCidadeEnde, CONCAT('*',xCityS));
         SET xCepEnde    = IFNULL(xCepEnde, xZipCodeS);
         SET xUFEnde     = IFNULL(xUFEnde, CONCAT('*',xStateS));
         SET xPaisEnde   = IFNULL(xPaisEnde, CONCAT('*',xCountryS));
         
         SET xCepEnde    = fnSoNumeros(xCepEnde,'');
      END IF;*/
      SET xCnpjTransp = fnTirarCaracteresEspeciais(xCnpjTransp);
      
      
      #IF xDocTipo IN ("PV","NFD","DEV","OP") THEN
      SET xFlgInclusao = FALSE;
      IF xDocTipo IN ('PV','OP','TD-S','NS','DC') THEN
         CALL PROC_INTEGRA_GerarGSM(oCodUsuario, xCodEmpSLIN, xCodFilSLIN, xDocTipo, xDocEntry, xDocNum, xDocDate, xDueDate, 
                                    xCardCode, xCardName, xObservacoes, xNomeVendedor, xValorPedido, 
                                    xTipoFrete, xNomeTransp, xCnpjTransp, @R, @M);
      #ELSEIF xDocTipo IN ("REC","NFE","PC","NE") THEN
      ELSEIF xDocTipo IN ('NE','E-RM','E-NE','DV','TD-E') OR (xDocTipo LIKE "PA%") THEN
         CALL PROC_INTEGRA_GerarGEM(oCodUsuario, xCodEmpSLIN, xCodFilSLIN, xDocTipo, xDocEntry, xDocNum, xSerialNum, xDocDate, 
                                    xCardCode, xCardName, xCFOP, xObservacoes, 
                                    #Reviser David Ruy <2025-01-27> 
                                    #Reviser David Ruy <2025-07-21> Já tratados direto no GerarGEM
                                    #xDocNumRef, xBDO_NKIT, 
                                    @R, @M);
         SET xFlgInclusao = IF(@R=0,FALSE,TRUE);                                                                        
         #select oCodUsuario, xCodEmpSLIN, xCodFilSLIN, xDocTipo, xDocEntry, xDocNum, xSerialNum, xDocDate, 
         #                           xCardCode, xCardName, xCFOP, xObservacoes, @R, @M;
      END IF;   
      SET xStatusSlin = @R;
      SET xMensagemSlin = @M;
      
      CALL PROC_INTEGRA_EnviarLog('999999', 
           #20230526 -> Ajuste Log para apresentar xMensagemSlin
           IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'), 'PROC_INTEGRA_GerarGSM', 'PROC_INTEGRA_GerarGEM'),
           CONCAT(CONCAT(xDocTipo,xDocEntry," ",xMensagemSlin), @R, @M ), "0", @M, xStatusSlin, @M);
      SET xGerouGuia = FALSE;
      
      IF xStatusSlin <> 0 THEN
         SET xGerouGuia = TRUE;
         SET xRefGuia   = SUBSTRING(xMensagemSlin,01,20);
         SET xCodEmpWMS	= SUBSTRING(xRefGuia,01,03);
         SET xCodFilWMS	= SUBSTRING(xRefGuia,04,03);
         SET xAnoSolic 	= SUBSTRING(xRefGuia,07,04);
         SET xNumSolic 	= SUBSTRING(xRefGuia,11,10);
         #Variavel atualizada pela rotina que insere o topo
         #SET xFlgInclusao = FALSE;
         
         #@Reviser David Ruy <2023-07-07> Não grava numero de GEM/GSM que não tenha sido inserida corretamente
         #Evita de gravar a mensagem de retorno nos campos cod_emp/cod_fil/ano_solic/num_solic
         IF (xNumSolic = fnSonumeros(xNumSolic,'')) THEN
            UPDATE tbintegraSAP_Doc
            SET cod_emp   = xCodEmpWMS
               ,cod_fil   = xCodFilWMS
               ,ano_solic = xAnoSolic
               ,num_solic = xNumSolic
               ,TipoDocSLIN = IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'),"S","E")
               ,StatusAnt  = StatusDoc
               ,StatusDoc  = IF(StatusDoc <= '2', '3', StatusDoc)
               ,StatusSlin = xStatusSlin
            WHERE DocTipo  = xDocTipo
              AND DocEntry = xDocEntry
              AND DocNum   = xDocNum;
         END IF;
           
           
/*************************************************************************************************/
#
/*************************************************************************************************/
           
         #Insere / Atualiza Itens  
         WHILE FALSE DO
         #WHILE EXISTS (SELECT 1 FROM tbtmp_IntegraDocItem
         #              WHERE DocTipo  = xDocTipo
         #                AND DocEntry = xDocEntry
         #              ORDER BY LineNum) DO
                       
            #SELECT LineNum, ItemCode, BaseQty, (Price*IF(IFNULL(DollarQuote,0)=0,1,DollarQuote)), WhareHouse, StatusItem, Observacoes, 
            #@Reviser David Ruy <2023-01-11> considerar BaseQty, nova variável  "xOpenInvQty"
            #SELECT LineNum, ItemCode, IF(IFNULL(OpenInvQty,0)=0,BaseQty,OpenInvQty), 
            SELECT LineNum, ItemCode, BaseQty, IFNULL(OpenInvQty, BaseQty),
                   (Price*IF(IFNULL(DollarQuote,0)=0,1,DollarQuote)), WhareHouse, StatusItem, Observacoes, 
                   #description, buyUnitMsr, salUnitMsr, invntryUom, 
                   #description, IFNULL(UomCode,buyUnitMsr), IFNULL(UomCode,salUnitMsr), invntryUom, 
                   description, IFNULL(buyUnitMsr,UomCode), IFNULL(salUnitMsr,UomCode), invntryUom, 
                   NumInSale, NumInBuy, BatchNumbersCode
            INTO xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, xWhareHouseIte, xStatusItem, xObservacoesIte,
                 xdescription, xbuyUnitMsr, xsalUnitMsr, xinvntryUom, 
                 xNumInSale, xNumInBuy, xBatchCode
            FROM tbtmp_IntegraDocItem
            WHERE DocTipo  = xDocTipo
              AND DocEntry = xDocEntry
              AND DocNum   = xDocNum
            ORDER BY LineNum LIMIT 1;
            
            SET xVlrUnitario = IF(IFNULL(xVlrUnitario,1)=0,1,IFNULL(xVlrUnitario,1));
            SET xdescription = IFNULL(xdescription,'');
            SET xbuyUnitMsr = IFNULL(xbuyUnitMsr,'');
            SET xsalUnitMsr = IFNULL(xsalUnitMsr,'');
            SET xinvntryUom = IFNULL(xinvntryUom,'');
            SET xObservacoesIte = SUBSTRING(xObservacoesIte,1,300);
           
            #@Reviser David Ruy <2023-07-14> Devolução de Vendas pegar Embalagem de Vendas
            #SELECT "===>",xItemCode, xSalUnitMsr, xbuyUnitMsr, xinvntryUom, xNumInSale, xNumInBuy, xBaseQty, xOpenInvQty;
            IF xDocTipo = 'DV' THEN
		SET xbuyUnitMsr = xSalUnitMsr;
	    END IF;
            
            IF xDocTipo IN ('PV','OP','TD-S','NS','DC') THEN
               -- CALL PROC_INTEGRA_GerarGSMItem(oCodUsuario, xRefGuia, CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
               --             xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, xCardCode, xCardName, xBatchCode, xWhareHouseIte, @R, @M);
               SET @R = 1;
               SET @M = CONCAT("Item Inserido pela nova rotina L=",xLineNum," It=", xItemCode, " Desc=", xdescription);
            ELSEIF xDocTipo IN ('NE','E-RM','E-NE','DV','TD-E') OR (xDocTipo LIKE "PA%") THEN
               -- CALL PROC_INTEGRA_GerarGEMItem(oCodUsuario, xRefGuia, CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xBaseQty, xOpenInvQty, xVlrUnitario, 
               --             xStatusItem, xObservacoesIte, xdescription, xbuyUnitMsr, xinvntryUom, xNumInBuy, xWhareHouseIte, @R, @M);            
               SET @R = 1;
               SET @M = CONCAT("Item Inserido pela nova rotina L=",xLineNum," It=", xItemCode, " Desc=", xdescription);
               
               #Se teve inclusão de Itens para gerar aconselhamento               
               #IF NOT xFlgInclusao  THEN
               #   SET xFlgInclusao = IF(@R=0,FALSE,SUBSTRING(@M,08,01)="I");                                    
               #END IF;
               
            END IF;
            
            #select oCodUsuario, xRefGuia, CONCAT(xDocNum,'(',xDocEntry,')'), xLineNum, xItemCode, xdescription, xBaseQty, xOpenInvQty, xVlrUnitario, 
            #               xsalUnitMsr, xinvntryUom, xNumInsale, xStatusItem, xObservacoesIte, xCardCode, xCardName, xBatchCode, xWhareHouseIte, @R, @M;
                        
            SET xStatusItem = @R;
            SET xNumItem    = SUBSTRING(@M,01,06);  #Numero do item no retorno da proc
            CALL PROC_INTEGRA_EnviarLog('999999',
                   IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'), 'PROC_INTEGRA_GerarGSMItem', 'PROC_INTEGRA_GerarGEMItem'),
                     CONCAT('Inserido/Atualizado ',xDocTipo,xDocEntry,'-',xDocNum,' | ', xRefGuia, '| Prd:', xItemCode), "200", @M, @R, @M);
            
            IF (xStatusItem <> 0) AND (@R = 1) THEN
               UPDATE tbintegraSAP_DocItem
               SET cod_emp     = xCodEmpWMS
                  ,cod_fil     = xCodFilWMS
                  ,ano_solic   = xAnoSolic
                  ,num_solic   = xNumSolic
                  ,num_item    = xNumItem
                  ,StatusItem  = '0'    #Volta para Zero para identificar que já atualizou no SLIN
               WHERE DocTipo  = xDocTipo
                 AND DocEntry = xDocEntry
                 AND DocNum   = xDocNum
                 AND IF(xflg_agrupa_transf=0 OR xDocTipo <> "TD-S", LineNum  = xLineNum, ItemCode = xItemCode);            
            ELSE
                CALL PROC_INTEGRA_EnviarLog('999999',
                      IF(xDocTipo IN ('PV','OP','TD-S','DC'),'PROC_INTEGRA_GerarGSMItem','PROC_INTEGRA_GerarGEMItem'), 
                        CONCAT('NÃO Inserido/Atualizado ',xDocTipo,xDocEntry,'-',xDocNum,' | ', xRefGuia, '| Prd:', xItemCode), "0", @M, @R, @M);
            END IF;
            
-- Aqui Novo IF   (desabilitado)         
--            END IF;
            
            DELETE FROM tbtmp_IntegraDocItem
            WHERE DocTipo  = xDocTipo
              AND DocEntry = xDocEntry
              AND LineNum  = xLineNum;
                            
         END WHILE;
/*************************************************************************************************/
#
/*************************************************************************************************/
         
         #@Reviser David Ruy <2020-11-25>
         #Aconselhamento de Entradas com endereçamento
         IF xFlgInclusao THEN
            CALL of_logistica.PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_TOTAL(1, xCodEmpWMS	, xCodFilWMS	, xAnoSolic, xNumSolic, 1, '999999', @R, @M);
            CALL PROC_INTEGRA_EnviarLog('999999',
                  'PROC_WMS_DESCARGA_GERAR_ACONSELHAMENTO_TOTAL', 
                    CONCAT('Aconselhamento Endereço =>',xCodEmpWMS	, xCodFilWMS	, xAnoSolic, xNumSolic), "1", @M, @R, @M);            
         END IF;
         
      ELSE
          CALL PROC_INTEGRA_EnviarLog('999999',
                IF(xDocTipo IN ('PV','OP','TD-S','NS','DC'),'PROC_INTEGRA_GerarGSM','PROC_INTEGRA_GerarGEM'), 
                  CONCAT('Não Inserido ', xDocTipo, CAST(xDocEntry AS CHAR), '-', xDocNum,'|', xCardName), "0", @M, @R, @M);
      END IF;
      
      SELECT cnpj_cpf_cli INTO xCNPJCPFCLI FROM of_logistica.tbsolic_saidas
      WHERE cod_emp   = xCodEmpWMS 
        AND cod_fil   = xCodFilWMS
        AND ano_solic = xAnoSolic
        AND num_solic = xNumSolic;
        
      IF xGerouGuia AND (IFNULL(xCnpjTransp,'') <> '') AND (xDocTipo IN ('PV','NS') ) THEN
         #Atualizar cadastro de Transportadores (tbwms_terceiros)
         CALL PROC_INTEGRA_CAD_Terceiro('999999', xCNPJCPFCLI, xCnpjTransp, '1', xNomeTransp, xNomeTransp, 1, @R, @M);
         #Atualizar cadastro de Transportadores (tbclientes)
         CALL PROC_INTEGRA_CAD_Fornecedor('999999', xCnpjTransp, xNomeTransp, xNomeTransp, @R, @M);
         
         
         /*#Cadastro de Fornecedores (Transportadora para o TMS)
         CALL PROC_INTEGRA_CAD_ClienteFornecedor('999999',
                                                   xCnpjTransp, "J", "F", 
                                                   xNomeTransp, xNomeTransp, 
                                                   'x', #oInscrEstadual			VARCHAR(20),
                                                   '9', #oIndicadorIE			  VARCHAR(1),	
                                                   'x', #oEndereco				VARCHAR(50),
                                                   'x', #oNumEnde					VARCHAR(10),
                                                   NULL,#oComplEnde				VARCHAR(20),
                                                   'x', #oBairroEnde				VARCHAR(50),
                                                   'x', #oCidadeEnde				VARCHAR(50),
                                                   'x', #oUFEnde					VARCHAR(02),
                                                   '00000000', #oCepEnde		VARCHAR(08),
                                                   NULL,#oContato01				VARCHAR(20),
                                                   NULL,#oFone01 					VARCHAR(20),
                                                   NULL,#oEmail01 				VARCHAR(40),
                                                   NULL,#oContato02 				VARCHAR(20),
                                                   NULL,#oFone02 					VARCHAR(20),
                                                   NULL,#oEmail02 				VARCHAR(40),
                                                   NULL,#oContato03 				VARCHAR(20),
                                                   NULL,#oFone03 					VARCHAR(20),
                                                   NULL,#oEmail03 				VARCHAR(40),
                                                   NULL,#oEmail_fiscal 			VARCHAR(500),
                                                   'S',#oStatusAtivo				VARCHAR(01),
                                                   @R, @M);
         */
         
            # Desabilitado em 14/12/2020
            # Atualizar cadastro de destinatarios (Transportadora)
            /*CALL PROC_INTEGRA_CAD_Destinatario(oCodUsuario, xCNPJCPFCLI, xCnpjTransp, "J", 
                               SUBSTRING(xNomeTransp,1,60), SUBSTRING(xNomeTransp,1,40),
                               NULL, 9,
                               'x', 'x', xComplEnde, 'x',
                               'x', 'x', '00000000', NULL,
                               NULL, NULL, 'S',
                               # Parametros de Retorno
                               @RESULTADO, @MENSAGEM);
            */
      END IF;    
      
      IF xGerouGuia THEN
         #IF xDocTipo IN ("PV","TD-S","NS") AND (xTipoProducao IN ("PEX","PEC") AND (xCNPJEmpresa <> xNumCPFouCNPJ)) THEN
         #2025-10-03 Não gerar Transporte para TD-S
         IF xDocTipo IN ("PV","NS") AND (xTipoProducao IN ("PEX","PEC") AND (xCNPJEmpresa <> xNumCPFouCNPJ)) THEN
            # Atualizar cadastro de destinatarios
            CALL PROC_INTEGRA_CAD_Destinatario(oCodUsuario, xCNPJCPFCLI, xCardCode, xTipoPessoa, 
                               SUBSTRING(xCardName,1,60), SUBSTRING(xCardName,1,50),
                               IFNULL(@oInscrEstadual,'123'), IFNULL(@oIndicadorIE,9),
                               xEndereco, xNumEnde, xComplEnde, xBairroEnde,
                               xCidadeEnde, xUFEnde, xCepEnde, @oContato01,
                               @oFone01, @oEmail01, @oStatusAtivo, 
                               xhora1_entrega, xhora2_entrega, xhora3_entrega, xhora4_entrega,
                               # Parametros de Retorno
                               @RESULTADO, @MENSAGEM);
                               
            # Alimentar TMS com o pedido
            CALL PROC_INTEGRA_TMS_GERAR_ENTREGAS(xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xTipoFrete, xCnpjTransp, xNomeTransp, @RESULTADO, @MENSAGEM);
         END IF;
      END IF;
      
      DELETE FROM tbtmp_IntegraDocTopo
      WHERE DocTipo  = xDocTipo
        AND DocEntry = xDocEntry
        AND DocNum   = xDocNum;
        
   END WHILE;
   
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocItem;
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo;
   DROP TEMPORARY TABLE IF EXISTS tbtmp_IntegraDocTopo2;
   
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