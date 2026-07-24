DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoEntrada`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoEntrada`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 VARCHAR(20),
   IN oTipoDoc       VARCHAR(10)  #NE = Compras NE / Compras E-RM / Compras E-NE
                                  #DV = Devoluções de Compras
   # Parametros de Retorno
   #OUT RESULTADO             	INT,
   #OUT MENSAGEM              	VARCHAR(500)
)
BLOCO1:BEGIN
   /***************************************************************************
   #@Reviser David Ruy <2019/12/11>
   # Busca informações do tipo de operação para não retornar GEM de Produção 
   #@Reviser David Ruy <2020/02/27>
   # oTipoRetorno = 1 (Entradas Quaisquer), oTipoRetorno = 2 (Entradas Devoluções)
   #@Reviser David Ruy <2021/08/24>
   # oTipoDoc "TD-E" Transferencia entre depósitos <Entrada>
   #@Reviser David Ruy <2021/12/24> Campos ManBtchNum, ManSerNum
   #@Reviser David Ruy <2022-11-04> #confirmação de PV => Considerar apenas com Uitilização parametrizada   
   #@Reviser David Ruy <2023-03-10> #Confirmação de Entradas : Unificação retorno DV => XDV, NE => XNE
   #                                 Isso por conta de utilização do serviço OOne e não mais XNET
   #@Reviser David Ruy <2024-12-11> Se OpenInvQty > 0 então, 
                FatorConvSap = OpenInvQty / BaseQty 
                Caso contrário para Devolução = NumInSales, senão = NumInBuy 2024-12-11
   #@Reviser David Ruy <2024-12-12> Inclusão campos : acons.data_fabr, acons.data_valid (retorno nos lotes/series)   
   #@Reviser David Ruy <2025-01-27> U_BDO_NKIT (Gemmini)
   #@Reviser David Ruy <2025-04-04> IF(tbintegraSAP_Doc.DocTipo IN ('DV','PA','PA000','PA001','PA002'),
   ****************************************************************************/
   DECLARE xCodEmpWMS			      VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			      VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xAnoSolic 			      VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(10);
   DECLARE xTipoOperSaida 		  VARCHAR(03) DEFAULT '001';
   DECLARE xCodUnidade			     VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			     VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		  VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	          INT DEFAULT 0;
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xSTRGEM            TEXT;
   DECLARE xNumProcesso       VARCHAR(20); 
   DECLARE xutilizacao_entradas_retorno VARCHAR(200) DEFAULT NULL;
   
   DECLARE xFlg_RetornoEntradas VARCHAR(20); 
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   #@Reviser David Ruy <2021-01-27> Força para não retornar nenhum registro para SAP   
   SELECT CONCAT(IF(flg_retorno_entrada_ENE=1,'E-NE','X'), '|', 
                 IF(flg_retorno_entrada_ERM=1,'E-RM','X'), '|', 
                 IF(flg_retorno_entrada_NE=1 ,'NE','X'), '|', 
                 IF(flg_retorno_entrada_PD=1 ,'DV','X'), '|', 
                 IF(flg_retorno_entrada_TD=1 ,'TD-E','X')) 
           ,utilizacao_entradas_retorno
   INTO xFlg_RetornoEntradas, xutilizacao_entradas_retorno
   FROM tbintegraSAP_parametros LIMIT 1;
   
   CALL PROC_SYS_GerarTabelaComTexto(xFlg_RetornoEntradas,"|",1);
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
   CREATE TEMPORARY TABLE tbTMPTipoDoc 
          SELECT * FROM tTabelaComTexto WHERE Coluna01 <> 'X';
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
   
   
   
   #Cria tabela temporária com as GEM que estão liberadas para retorno à integração
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_ENTRADAS;
   IF IFNULL(oIdRetorno,'') = '' THEN
   
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_ENTRADAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
               ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
               ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
               ,tbEntradas.status_processo, tbEntradas.observ_solic, U_BDO_NKIT 
               #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
               tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbEntradas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         INNER JOIN of_logistica.tbwms_tipo_oper tbOperacoesWMS ON 
               tbOperacoesWMS.cod_oper_wms = tbEntradas.flg_tipo_oper
         INNER JOIN tbTMPTipoDoc ON
                    tbTMPTipoDoc.Coluna01 = tbintegraSAP_Doc.DocTipo
         WHERE tbintegraSAP_Doc.TipoDocSLIN = 'E'
           AND tbintegraSAP_Doc.DocTipo     = oTipoDoc
           #AND tbOperacoesWMS.flg_producao = 'N';
           AND tbEntradas.flg_producao      = 'N'
           AND tbEntradas.flg_devol         = IF(oTipoDoc='DV','S','N')
           #and tbintegraSAP_Doc.DocEntry in (863, 950,951)
           ;
                      
   ELSE
   
      SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
      SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
      SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
      SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
      #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
      /*******************************************************************
      # Validar a existencia da GEM
      *******************************************************************/
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_entradas 
                     WHERE cod_emp = xCodEmpWMS
                     AND cod_fil = xCodFilWMS
                     AND ano_solic = xAnoSolic
                     AND num_solic = xNumSolic) THEN
         SET xCodErro = 1;
         SET RESULTADO = 0;
         SET MENSAGEM  = 'GEM não localizada';
         SELECT RESULTADO, MENSAGEM;
         LEAVE BLOCO1;         
      END IF;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_ENTRADAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbEntradas.num_nf, tbEntradas.data_nf, tbEntradas.data_solic
               ,CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic) NumProcesso
               ,tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic
               ,tbEntradas.status_processo, tbEntradas.observ_solic, U_BDO_NKIT
               #,CONCAT('CALL PROC_INTEGRA_RetornoEntrada("999999","',CONCAT(tbEntradas.cod_emp, tbEntradas.cod_fil, tbEntradas.ano_solic, tbEntradas.num_solic),'");') _call
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_entradas tbEntradas ON
               tbEntradas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbEntradas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbEntradas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbEntradas.num_solic = tbintegraSAP_Doc.num_solic
           AND tbEntradas.status_processo >= 8
           AND tbintegraSAP_Doc.StatusDoc = 3
         WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
           AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
           AND tbintegraSAP_Doc.ano_solic = xAnoSolic
           AND tbintegraSAP_Doc.num_solic = xNumSolic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'E';
   
   END IF;
    
    
   #select * from tbTMP_INTEGRA_RETORNO_ENTRADAS;
      
   DROP TEMPORARY TABLE IF EXISTS tbTMPTipoDoc;
   
   
   #select IFNULL(xutilizacao_entradas_retorno,'Vazio');
   
   #select * from tbTMP_INTEGRA_RETORNO_ENTRADAS;
    
   #Update (como retornado) para Documentos com utilização diferente da parametrizada
   IF IFNULL(xutilizacao_entradas_retorno,'') <> '' THEN
      UPDATE tbintegraSAP_Doc
      INNER JOIN tbTMP_INTEGRA_RETORNO_ENTRADAS ON
                 tbTMP_INTEGRA_RETORNO_ENTRADAS.DocTipo  = tbintegraSAP_Doc.DocTipo
             AND tbTMP_INTEGRA_RETORNO_ENTRADAS.DocEntry = tbintegraSAP_Doc.DocEntry
             AND tbTMP_INTEGRA_RETORNO_ENTRADAS.DocNum   = tbintegraSAP_Doc.DocNum
      SET StatusAnt = StatusDoc,
          StatusDoc = 6
      #where LOCATE(tbintegraSAP_Doc.MainUsage,xutilizacao_entradas_retorno) = 0);
      WHERE EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                    WHERE tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
                      AND tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
                      AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
                      AND LOCATE(IFNULL(tbintegraSAP_DocItem.Usage_,'XXX'),xutilizacao_entradas_retorno) = 0);
                      
                      
      DELETE FROM tbTMP_INTEGRA_RETORNO_ENTRADAS 
      WHERE EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                    WHERE tbintegraSAP_Doc.DocTipo = tbTMP_INTEGRA_RETORNO_ENTRADAS.DocTipo
                      AND tbintegraSAP_Doc.DocEntry  = tbTMP_INTEGRA_RETORNO_ENTRADAS.DocEntry
                      AND tbintegraSAP_Doc.DocNum = tbTMP_INTEGRA_RETORNO_ENTRADAS.DocNum
                      AND StatusDoc = 6);
   END IF;
   
   
   #Alimenta variavel xSTRGEM com a lista das GEM´s selecionadas
   SET xSTRGEM = '';  
   WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_ENTRADAS) DO
      SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
      INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
      FROM tbTMP_INTEGRA_RETORNO_ENTRADAS LIMIT 1;         
      
      SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
      DELETE FROM tbTMP_INTEGRA_RETORNO_ENTRADAS WHERE NumProcesso = xNumProcesso;
   END WHILE;
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_ENTRADAS;
   #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
   #da GEM informada no parametro
   CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);
    
    
   /*******************************************************************
   # Selecionar as informações da GEM
   *******************************************************************/
   IF oTipoDoc IN ('DV','NE','E-RM','E-NE','TD-E') THEN
   
      # INFORMAÇÕES DO TOPO DA GEM
      #IF oTipoDoc IN ('NE','DV') THEN
      IF oTipoDoc IN ('XNE','xDV') THEN
         SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
               topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
               topo.observ_solic, topo.observ_conf01, topo.status_processo, 
               of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
               #Liberação Inicio Processo de Separação, Picking
               topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
               #Inicio Processo de Separação, Picking
               topo.dthr_chegada, topo.final_descarga,
         # INFORMAÇÕES INTEGRAÇÃO
               tbintegraSAP_Doc.DocNum,
               tbintegraSAP_Doc.DocDate,
               tbintegraSAP_Doc.CardCode, tbintegraSAP_Doc.CardName, 
               CONCAT(tbintegraSAP_Doc.StreetS," - ",tbintegraSAP_Doc.CityS,"-",tbintegraSAP_Doc.StateS,"-",tbintegraSAP_Doc.CountryS,
                      " CEP:",tbintegraSAP_Doc.ZipCodeS) AS Address,
               tbintegraSAP_DocItem.LineNum,
               tbintegraSAP_Doc.ItemCode, 
               tbintegraSAP_Doc.Observacoes,
               tbintegraSAP_Doc.SERIAL,
               tbintegraSAP_Doc.StreetS,
               tbintegraSAP_Doc.AddrTypeS,
               tbintegraSAP_Doc.StreetNoS,
               tbintegraSAP_Doc.BlockS,
               tbintegraSAP_Doc.BuildingS,
               tbintegraSAP_Doc.CityS,
               tbintegraSAP_Doc.ZipCodeS,
               tbintegraSAP_Doc.StateS,
               tbintegraSAP_Doc.CountryS,
               "Employee" Employee,
               tbintegraSAP_Doc.U_BDO_NKIT,
         # INFORMAÇÕES DOS ITENS DA GEM
               #FatorConvSap para Devolução = NumInSales, senão = NumInBuy 2024-12-11
               IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
                 tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 #IF(tbintegraSAP_Doc.DocTipo IN ('DV'),
                 IF(tbintegraSAP_Doc.DocTipo IN ('DV','PA','PA000','PA001','PA002'),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInBuy,1)=0,1,tbintegraSAP_DocItem.NumInBuy)))  AS FatorConvSAP,
               #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               #Desabilitado em 2024-12-11
               #IF(IFNULL(prod.fator_conv_compras,1)=0,1,prod.fator_conv_compras) AS FatorConvSAP,
               prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,  
               tbintegraSAP_DocItem.ManBtchNum, tbintegraSAP_DocItem.ManSerNum,            
               ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
               ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
               #
               ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
               ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
               ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
               ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
               #			
               ite.dthr_conf_ini, ite.dthr_conf_fin,
               tbintegraSAP_DocItem.Usage_,
               topo.chave_integracao,
               prod.flg_obriga_lote_fornecedor,
               tbintegraSAP_Doc.BPLId, tbintegraSAP_Doc.CFOP,
               RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_entradas topo
         INNER JOIN tTabelaComTexto ON
                   tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         LEFT JOIN tbintegraSAP_Doc ON 
                  tbintegraSAP_Doc.cod_emp = topo.cod_emp
              AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
              AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
              AND tbintegraSAP_Doc.num_solic = topo.num_solic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
         LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                   ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic
         INNER JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.cod_emp = ite.cod_emp
               AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
               AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
               AND tbintegraSAP_DocItem.num_solic = ite.num_solic
               AND tbintegraSAP_DocItem.num_item = ite.num_item
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
         LEFT JOIN of_logistica.tbprodutos prod ON
                   prod.cnpj_cpf = ite.cnpj_cpf_dep
               AND prod.cod_produto = ite.cod_produto
         WHERE ite.real_est > 0;
      ELSE
      
         #Topo
         SELECT DISTINCT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo, 
               topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,
               topo.observ_solic, topo.observ_conf01, topo.status_processo, 
               of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
               #Liberação Inicio Processo de Separação, Picking
               topo.dthr_endereco, topo.dthr_confer, topo.dthr_confirm,
               #Inicio Processo de Separação, Picking
               topo.dthr_chegada, topo.final_descarga,
         # INFORMAÇÕES INTEGRAÇÃO
               tbintegraSAP_Doc.DocNum,
               tbintegraSAP_Doc.DocDate,
               tbintegraSAP_Doc.CardCode, tbintegraSAP_Doc.CardName, 
               CONCAT(tbintegraSAP_Doc.StreetS," - ",tbintegraSAP_Doc.CityS,"-",tbintegraSAP_Doc.StateS,"-",tbintegraSAP_Doc.CountryS,
               " CEP:",tbintegraSAP_Doc.ZipCodeS) AS Address, 
               tbintegraSAP_Doc.Observacoes,
               tbintegraSAP_Doc.SERIAL,
               tbintegraSAP_Doc.StreetS,
               tbintegraSAP_Doc.AddrTypeS,
               tbintegraSAP_Doc.StreetNoS,
               tbintegraSAP_Doc.BlockS,
               tbintegraSAP_Doc.BuildingS,
               tbintegraSAP_Doc.CityS,
               tbintegraSAP_Doc.ZipCodeS,
               tbintegraSAP_Doc.StateS,
               tbintegraSAP_Doc.CountryS,
               tbintegraSAP_Doc.WhareHouse,
               tbintegraSAP_Doc.WhareHouseTransf,
               "Employee" Employee,
               topo.chave_integracao,
               tbintegraSAP_Doc.BPLId, tbintegraSAP_Doc.CFOP,
               tbintegraSAP_Doc.U_BDO_NKIT,
               RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_entradas topo
         INNER JOIN tTabelaComTexto ON
                   tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         LEFT JOIN tbintegraSAP_Doc ON 
                  tbintegraSAP_Doc.cod_emp = topo.cod_emp
              AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
              AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
              AND tbintegraSAP_Doc.num_solic = topo.num_solic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
         LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                   ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic
         WHERE ite.real_est > 0;
         
         #Itens
         SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               topo.data_solic, topo.dthr_acons, topo.num_nf AS num_pedido,               
         # INFORMAÇÕES DA INTEGRACAO
               tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.WhareHouse,
               tbintegraSAP_DocItem.Observacoes, tbintegraSAP_DocItem.Price,
               #IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale) AS FatorConvSAP,
               #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               #Desabilitado em 2024-12-11
               #IF(IFNULL(prod.fator_conv_compras,1)=0,1,prod.fator_conv_compras) AS FatorConvSAP,
               IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
                 tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 #IF(tbintegraSAP_Doc.DocTipo IN ('DV'),
                 IF(tbintegraSAP_Doc.DocTipo IN ('DV','PA','PA000','PA001','PA002'),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale),
                    IF(IFNULL(tbintegraSAP_DocItem.NumInBuy,1)=0,1,tbintegraSAP_DocItem.NumInBuy)))  AS FatorConvSAP,
               prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,  
               tbintegraSAP_DocItem.ManBtchNum, tbintegraSAP_DocItem.ManSerNum,
         # INFORMAÇÕES DOS ITENS DA GEM
               ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
               ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
               #
               ite.qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
               ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
               ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Conferencia
               ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / ???
               #			
               ite.dthr_conf_ini, ite.dthr_conf_fin,
               tbintegraSAP_DocItem.Usage_, tbintegraSAP_DocItem.TaxCode, tbintegraSAP_DocItem.CFOPCode, 
               topo.chave_integracao,
               prod.flg_obriga_lote_fornecedor,
               
               RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_entradas topo
         INNER JOIN tTabelaComTexto ON
                   tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         LEFT JOIN tbintegraSAP_Doc ON 
                  tbintegraSAP_Doc.cod_emp = topo.cod_emp
              AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
              AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
              AND tbintegraSAP_Doc.num_solic = topo.num_solic
              AND tbintegraSAP_Doc.TipoDocSLIN = 'E'
         LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
                   ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic
         INNER JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.cod_emp = ite.cod_emp
               AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
               AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
               AND tbintegraSAP_DocItem.num_solic = ite.num_solic
               AND tbintegraSAP_DocItem.num_item = ite.num_item
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
         LEFT JOIN of_logistica.tbprodutos prod ON
                   prod.cnpj_cpf = ite.cnpj_cpf_dep
               AND prod.cod_produto = ite.cod_produto
         WHERE ite.real_est > 0;         
      END IF;
      
            
      # INFORMAÇÕES DAS UA´S DA GEM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
            ite.num_nf_vda AS num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            acons.data_fabr, acons.data_valid,
            tbwms_estoque.num_lote_cli,
            SUM(acons.qtde_est) qtde_est, 
            SUM(acons.qtde_vol) qtde_vol, 
            SUM(acons.qtde_frac) qtde_frac, 
            SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
            #Qtde Conferencia (SAP não recebe Qtde Entrada a maior, PROC_INTEGRA_RetornoContagem gera registro de complementos)
            #if(acons.qtde_est2 > acons.qtde_est, acons.qtde_est, acons.qtde_est2) as qtde_est2, 
            #if(acons.qtde_vol2 > acons.qtde_vol, acons.qtde_vol, acons.qtde_vol2) as qtde_vol2, 
            #if(acons.qtde_frac2 > acons.qtde_frac, acons.qtde_frac, acons.qtde_frac2) as qtde_frac2, 
            #if(acons.qtde_peso2 > acons.qtde_peso, acons.qtde_peso, acons.qtde_peso2) as qtde_peso2,
            #@Reviser David Ruy <2019/12/30> Alterado para enviar a quantidade Real Conferida
            #Qtde Conferencia (SAP não recebe Qtde Entrada a maior, PROC_INTEGRA_RetornoContagem gera registro de complementos)
            SUM(acons.qtde_est2) AS qtde_est2, 
            SUM(acons.qtde_vol2) AS qtde_vol2, 
            SUM(acons.qtde_frac2) AS qtde_frac2, 
            SUM(acons.qtde_peso2) AS qtde_peso2,
            SUM(acons.qtde_est3) AS qtde_est3, 
            SUM(acons.qtde_vol3) AS qtde_vol3, 
            SUM(acons.qtde_frac3) AS qtde_frac3, 
            SUM(acons.qtde_peso3) AS qtde_peso3,	#(*) Qtde Conferencia/???
            #		
            acons.dthr_conf, acons.dthr_armaz
            #,tbIntegraDeposito.cod_armazem WarehouseCode,
            ,tbstatus_lotes_integracao.deposito_integracao WarehouseCode,
            topo.chave_integracao,
            RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_entradas topo
      LEFT JOIN of_logistica.tbsolic_entradas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic			
      LEFT JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      LEFT JOIN of_logistica.tbsolic_entradas_acons acons ON
            acons.cod_emp = ite.cod_emp
            AND acons.cod_fil = ite.cod_fil
            AND acons.ano_solic = ite.ano_solic
            AND acons.num_solic = ite.num_solic			
            AND acons.num_item  = ite.num_item
      LEFT JOIN of_logistica.tbwms_estoque ON  
            tbwms_estoque.cod_emp = acons.cod_emp
            AND tbwms_estoque.cod_fil = acons.cod_fil
            AND tbwms_estoque.num_lote = acons.num_lote
            AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
      #LEFT JOIN tbintegraSAP_DeParaStatus_Armazem tbIntegraDeposito ON 
      #      tbIntegraDeposito.cod_status =  tbwms_estoque.status_lote
      LEFT JOIN of_logistica.tbstatus_lotes_integracao ON
                tbstatus_lotes_integracao.cod_emp = topo.cod_emp
            AND tbstatus_lotes_integracao.cod_fil = topo.cod_fil
            AND tbstatus_lotes_integracao.codigo_status = tbwms_estoque.status_lote
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      WHERE acons.qtde_est2  > 0
      GROUP BY chave_integracao, num_item, num_lote_cli;
            
   END IF; 
   
   DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
    
   IF excecao = 1 THEN
      SET RESULTADO = 0;
      SET MENSAGEM = CONCAT(xCodErro," - Erro SQL - Verifique com o Administrador");
      SELECT RESULTADO, MENSAGEM;
   ELSE    
      SET RESULTADO = 1;
      #SET MENSAGEM  = 'Processo Realizado com sucesso!';
   END IF;
   
END$$

DELIMITER ;