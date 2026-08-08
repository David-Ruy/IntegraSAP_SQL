/*
StatusDoc
1 = Importado SAP
2 = Integrado SLIN
3 = Integrado SLIN (alteração)
4 = Iniciado SLIN
5 = Finalizado SLIN
6 = Retornado SAP
10 = Retornado / Gerar Transferencia
9 = Cancelado SAP
*/

#SET @oResponseStatus=0;
#CALL PROC_INTEGRA_EnviarLog('999999','oJsonRequest', 'oJsonResponse', @oResponseStatus, 'oResponseStatusDescr', @R, @M); SELECT @R, @M;

CALL PROC_INTEGRA_ListarParametros();
CALL PROC_INTEGRA_SetarStatusProcesso('999999',0,1,@R,@M);


SELECT * FROM tbintegraSAP_Doc ORDER BY DocTipo,DocEntry;
SELECT * FROM tbintegraSAP_DocItem ORDER BY DocTipo,DocEntry, LineNum;
SELECT * FROM tbintegraSAP_log_request;
#DESC tbintegraSAP_Doc
DELETE FROM tbintegraSAP_log_request;
DELETE FROM tbintegraSAP_Doc;
DELETE FROM tbintegraSAP_DocItem;

SELECT * FROM of_jrichard.tbsolic_saidas


1000.000000
CALL PROC_INTEGRA_AtualizarSLIN('999999',@R, @M); SELECT @R, @M;


DROP TABLE tbintegraSAP_DocItem;
DROP TABLE tbintegraSAP_Doc;

SELECT * FROM tbwms_barcode_padrao


SELECT * FROM of_logistica.tbsolic_entradas WHERE ano_solic = '2019';
SELECT * FROM of_logistica.tbsolic_entradas_item WHERE ano_solic = '2019';
SELECT * FROM of_logistica.tbsolic_saidas WHERE ano_solic = '2019';
SELECT * FROM of_logistica.tbsolic_saidas_item WHERE ano_solic = '2019';


CALL PROC_INTEGRA_AtualizarSLIN('999999', @R, @M);
SELECT @R, @M;

/*
delete FROM of_logistica.tbsolic_saidas WHERE ano_solic = '2019';
update tbintegraSAP_Doc 
set cod_emp = null, cod_fil = NULL, ano_solic = NULL, num_solic = NULl;
*/


/***********************************************************/
DROP TABLE IF EXISTS tbintegraSAP_Doc;
CREATE TABLE `tbintegraSAP_Doc` (
  `DocEntry` INT(11) NOT NULL DEFAULT '0',
  `DocTipo` VARCHAR(3) NOT NULL DEFAULT '' COMMENT 'PedidoVenda-ConfPV / NotaFiscalRecebimento-ConfNF / OrdemProducao-ConfOP / ',
  `DocNum` INT(11) NOT NULL DEFAULT '0',
  `ItemCode` VARCHAR(30) DEFAULT NULL,
  `DocDate` DATETIME DEFAULT NULL,
  `DueDate` DATETIME DEFAULT NULL,
  `TaxDate` DATETIME DEFAULT NULL,
  `StatusAnt` VARCHAR(10) DEFAULT NULL,
  `StatusDoc` VARCHAR(10) DEFAULT NULL,
  `StatusSLIN` VARCHAR(10) DEFAULT NULL,
  `PlannedQty` DOUBLE(20,6) DEFAULT NULL,
  `WhareHouse` VARCHAR(30) DEFAULT NULL,
  `StatusEnum` INT(11) DEFAULT NULL,
  `CardCode` VARCHAR(15) DEFAULT NULL,
  `CardName` VARCHAR(100) DEFAULT NULL,
   AddrTypeS     VARCHAR(10) COMMENT 'Tipo Endereço Entrega',
   StreetS       VARCHAR(100) COMMENT 'Logradouro Entrega',
   StreetNoS     VARCHAR(30) COMMENT 'Numero Entrega',
   BuildingS     VARCHAR(50) COMMENT 'Bairro Entrega',
   BlockS        VARCHAR(50) COMMENT 'Complemento Entrega',
   CityS         VARCHAR(100) COMMENT 'Cidade Entrega',
   ZipCodeS      VARCHAR(10) COMMENT 'CEP Entrega',
   StateS        VARCHAR(02) COMMENT 'Estado Entrega',
   CountryS      VARCHAR(50) COMMENT 'Pais Entrega',
  `id_request` INT(11) DEFAULT NULL,
  `TipoDocSLIN` VARCHAR(3) DEFAULT NULL,
  `cod_emp` VARCHAR(3) DEFAULT NULL,
  `cod_fil` VARCHAR(3) DEFAULT NULL,
  `ano_solic` VARCHAR(4) DEFAULT NULL,
  `num_solic` VARCHAR(10) DEFAULT NULL,
  `Observacoes` TEXT,
  `dthr_inc` DATETIME DEFAULT NULL,
  `usu_inc` VARCHAR(6) DEFAULT NULL,
  `dthr_alt` DATETIME DEFAULT NULL,
  `usu_alt` VARCHAR(6) DEFAULT NULL,
  PRIMARY KEY (`DocEntry`,`DocTipo`,`DocNum`),
  KEY `idx_tbintegraSAP_Doc` (`TipoDocSLIN`,`cod_emp`,`cod_fil`,`ano_solic`,`num_solic`),
  KEY `idx_tbintegraSAP_Doc2` (`dthr_inc`)
) ENGINE=INNODB DEFAULT CHARSET=latin1;

ALTER TABLE tbintegraSAP_Doc
ADD COLUMN idPicking INT AFTER DocNum;

ALTER TABLE tbintegraSAP_Doc
ADD COLUMN idPickingAnt INT AFTER idPicking;

#@David Ruy <2020/01/26>
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN NomeVendedor VARCHAR(50) AFTER CountryS,
ADD COLUMN TipoFrete    VARCHAR(05) AFTER NomeVendedor,
ADD COLUMN NomeTransp   VARCHAR(50) AFTER TipoFrete,
ADD COLUMN CnpjTransp   VARCHAR(20) AFTER NomeTransp;


#@David Ruy <2020/02/24>
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN dthr_cancel DATETIME DEFAULT NULL AFTER CnpjTransp,
ADD COLUMN dthr_cancel_slin DATETIME DEFAULT NULL AFTER num_solic;



#@David Ruy <2021-01-02>
ALTER TABLE tbintegraSAP_Doc
MODIFY COLUMN StreetS       VARCHAR(200) COMMENT 'Logradouro Entrega',
MODIFY COLUMN BuildingS     VARCHAR(100) COMMENT 'Bairro Entrega',
MODIFY COLUMN CityS         VARCHAR(100) COMMENT 'Cidade Entrega';





DROP TABLE IF EXISTS tbintegraSAP_DocItem;
CREATE TABLE `tbintegraSAP_DocItem` (
  `DocEntry` INT(11) NOT NULL DEFAULT '0',
  `DocTipo` VARCHAR(3) NOT NULL DEFAULT '' COMMENT 'PedidoVenda-ConfPV / NotaFiscalRecebimento-ConfNF / OrdemProducao-ConfOP / ',
  `DocNum` INT(11) NOT NULL DEFAULT '0',
  `LineNum` INT(11) NOT NULL DEFAULT '0',
  `ItemCode` VARCHAR(30) DEFAULT NULL,
  `BaseQty` DOUBLE(20,6) DEFAULT NULL,
  `PlannedQty` DOUBLE(20,6) DEFAULT NULL,
  `IssuedQty` DOUBLE(20,6) DEFAULT NULL,
  `WhareHouse` VARCHAR(30) DEFAULT NULL,
   Price DOUBLE(20,6) DEFAULT 0 COMMENT 'Valor Unitario',
  `IssueType` VARCHAR(1) DEFAULT NULL,
  `StatusAnt` VARCHAR(10) DEFAULT NULL,
  `StatusItem` VARCHAR(10) DEFAULT NULL,
  `Observacoes` TEXT,
   description VARCHAR(100) COMMENT 'Descrição do produto no Pedido',
   buyUnitMsr  VARCHAR(10)  COMMENT 'Unidade de medida para Compras',
   salUnitMsr  VARCHAR(10)  COMMENT 'Unidade de medida para Vendas',
   invntryUom  VARCHAR(10)  COMMENT 'Unidade de medida para Estoque', 
  `cod_emp` VARCHAR(3) DEFAULT NULL,
  `cod_fil` VARCHAR(3) DEFAULT NULL,
  `ano_solic` VARCHAR(4) DEFAULT NULL,
  `num_solic` VARCHAR(10) DEFAULT NULL,
  `num_item` VARCHAR(6) DEFAULT NULL,
  `dthr_inc` DATETIME DEFAULT NULL,
  `usu_inc` VARCHAR(6) DEFAULT NULL,
  `dthr_alt` DATETIME DEFAULT NULL,
  `usu_alt` VARCHAR(6) DEFAULT NULL,
  PRIMARY KEY (`DocEntry`,`DocTipo`,`DocNum`,`LineNum`),
  CONSTRAINT `tbintegraSAP_DocItem_ibfk_1` FOREIGN KEY (`DocEntry`, `DocTipo`) REFERENCES `tbintegraSAP_Doc` (`DocEntry`, `DocTipo`) ON DELETE CASCADE
) ENGINE=INNODB DEFAULT CHARSET=latin1;

ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN ManBtchNum  INT  COMMENT 'Flag SAP Retorna Numero Lotes' AFTER invntryUom,
ADD COLUMN ManSerNum   INT  COMMENT 'Flag SAP Retorna Numero Series' AFTER ManBtchNum;

ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN NumInSale  DECIMAL(18,5) COMMENT 'Fator de Conversão SAP' AFTER invntryUom;

ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN BatchNumbersCode VARCHAR(30) COMMENT 'Numero Lote solicitado' AFTER NumInSale;




DROP TABLE tbintegraSAP_log_request;
CREATE TABLE `tbintegraSAP_log_request` (
  `id_request` INT(11) NOT NULL AUTO_INCREMENT,
  `jsonRequest` TEXT,
  `jsonResponse` TEXT,
  `ResponseStatus` VARCHAR(50) DEFAULT NULL,
  `ResponseStatusDescr` VARCHAR(300) DEFAULT NULL,
  `dthr_inc` DATETIME DEFAULT NULL,
  `usu_inc` VARCHAR(6) DEFAULT NULL,
  PRIMARY KEY (`id_request`),
  KEY `idx_tbintegraSAP_log_request` (`dthr_inc`)
) ENGINE=INNODB AUTO_INCREMENT=1214 DEFAULT CHARSET=latin1;

ALTER TABLE tbintegraSAP_log_request
MODIFY COLUMN jsonRequest MEDIUMTEXT,
MODIFY COLUMN jsonResponse MEDIUMTEXT;



CREATE TABLE tbintegraSAP_parametros (
  `cod_emp` VARCHAR(03) NOT NULL,
  `cod_fil` VARCHAR(03) NOT NULL,
  `cnpj_cpf_cli` VARCHAR(14) NOT NULL,
  `cnpj_cpf_dep` VARCHAR(14) NOT NULL,
  `cod_estoque` VARCHAR(03) NOT NULL,
  `cod_unidade` VARCHAR(03) NOT NULL,
  `cod_armazem` VARCHAR(02) NOT NULL,
  `qtde_dias` INT NOT NULL,
  `ultima_atu` DATETIME,
  `flg_status` INT COMMENT '0=Aguardando, 1=Em processo',   
  `flg_ativo` INT NOT NULL COMMENT '0=Inativo, 1=Ativo'
);
#INSERT INTO tbintegraSAP_parametros VALUES ('001','001', '04330905000180', '04330905000180', '001', '001', '01', 90, NULL, 0, 1);

CALL PROC_INTEGRA_ListarParametros();
CALL PROC_INTEGRA_SetarStatusProcesso('999999',0,1,@R,@M);



CREATE TABLE of_logistica.tbsolic_saidas_item2 (
  `cod_emp` VARCHAR(3) NOT NULL,
  `cod_fil` VARCHAR(3) NOT NULL,
  `ano_solic` VARCHAR(4) NOT NULL DEFAULT '',
  `num_solic` VARCHAR(10) NOT NULL DEFAULT '',
  `num_item` VARCHAR(6) NOT NULL DEFAULT '',
  `num_item_cli` VARCHAR(10) DEFAULT NULL,
  `observacoes` VARCHAR(300) DEFAULT NULL,
  PRIMARY KEY (`cod_emp`,`cod_fil`,`ano_solic`,`num_solic`,`num_item`),
  CONSTRAINT `FK_tbsolic_saidas_item2` FOREIGN KEY (`cod_emp`, `cod_fil`, `ano_solic`, `num_solic`, `num_item`) REFERENCES `tbsolic_saidas_item` (`cod_emp`, `cod_fil`, `ano_solic`, `num_solic`, `num_item`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=INNODB DEFAULT CHARSET=latin1;

CREATE TABLE of_logistica.tbsolic_entradas_item2 (
  `cod_emp` VARCHAR(3) NOT NULL,
  `cod_fil` VARCHAR(3) NOT NULL,
  `ano_solic` VARCHAR(4) NOT NULL DEFAULT '',
  `num_solic` VARCHAR(10) NOT NULL DEFAULT '',
  `num_item` VARCHAR(6) NOT NULL DEFAULT '',
  `num_item_cli` VARCHAR(10) DEFAULT NULL,
  `observacoes` VARCHAR(300) DEFAULT NULL,
  PRIMARY KEY (`cod_emp`,`cod_fil`,`ano_solic`,`num_solic`,`num_item`),
  CONSTRAINT `FK_tbsolic_entradas_item2` FOREIGN KEY (`cod_emp`, `cod_fil`, `ano_solic`, `num_solic`, `num_item`) REFERENCES `tbsolic_entradas_item` (`cod_emp`, `cod_fil`, `ano_solic`, `num_solic`, `num_item`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=INNODB DEFAULT CHARSET=latin1;



CREATE TABLE tbintegraSAP_DeParaStatus_Armazem (
   cod_status  VARCHAR(03)
  ,cod_armazem VARCHAR(10)
  ,flg_ativo TINYINT NOT NULL DEFAULT 1
);
INSERT INTO tbintegraSAP_DeParaStatus_Armazem  VALUES ('001', 'RV01', 1);
INSERT INTO tbintegraSAP_DeParaStatus_Armazem  VALUES ('002', 'RV02', 1);
INSERT INTO tbintegraSAP_DeParaStatus_Armazem  VALUES ('003', 'RV03', 1);
INSERT INTO tbintegraSAP_DeParaStatus_Armazem  VALUES ('011', 'RV04', 1);


CREATE TABLE `tbintegraSAP_DeParaOperTMS` (
  `Incoterms` TINYINT(4) NOT NULL,
  `cod_oper_tms` VARCHAR(03) DEFAULT NULL,
  `flg_ativo` TINYINT(4) NOT NULL DEFAULT '1'
) ENGINE=INNODB DEFAULT CHARSET=latin1;
INSERT INTO tbintegraSAP_DeParaOperTMS  VALUES (0, '001', 1);
INSERT INTO tbintegraSAP_DeParaOperTMS  VALUES (1, '999', 1);
INSERT INTO tbintegraSAP_DeParaOperTMS  VALUES (2, '999', 1);
INSERT INTO tbintegraSAP_DeParaOperTMS  VALUES (3, '001', 1);
INSERT INTO tbintegraSAP_DeParaOperTMS  VALUES (4, '001', 1);
INSERT INTO tbintegraSAP_DeParaOperTMS  VALUES (9, '001', 1);


/*
DROP TABLE tbintegraSAP_Contagem;
CREATE TABLE tbintegraSAP_Contagem (
  Id INT NOT NULL DEFAULT 0,
  LineNum INT,
  Reference VARCHAR(200),
  CountingDate DATETIME,
  ItemCode VARCHAR(20) NOT NULL,
  WarehouseCode VARCHAR(30) NOT NULL,
  BinCode VARCHAR(30) NOT NULL,
  BatchNumber_Code VARCHAR(30),
  BatchNumber_Quantity DECIMAL(18,5),
  SerialNumber_ManufactureCode VARCHAR(30),
  ContedQuantity DECIMAL(18,5),
  TipoDocSLIN VARCHAR(03),
  cod_emp	VARCHAR(03),
  cod_fil	VARCHAR(03),
  ano_solic	VARCHAR(04),
  num_solic	VARCHAR(10),
  num_item	VARCHAR(06),
  num_lote	VARCHAR(10),
  sequencia_lote INT,
  observacoes   VARCHAR(200),
  dthr_inc DATETIME,
  dthr_retorno_integracao DATETIME,
  #2020-02-26
  #PRIMARY KEY (cod_emp, cod_fil, ano_solic, num_solic, num_item, num_lote, sequencia_lote),
  #PRIMARY KEY (Id),
  INDEX tbintegraSAP_ContagemIDX1 (Id, LineNum),
  INDEX tbintegraSAP_ContagemIDX2 (WarehouseCode, TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic, num_item, BatchNumber_Code));
*/




DROP TABLE IF EXISTS tbintegraSAP_ContagemTopo;
CREATE TABLE tbintegraSAP_ContagemTopo(
  TipoDocSLIN VARCHAR(03),
  cod_emp	VARCHAR(03),
  cod_fil	VARCHAR(03),
  ano_solic	VARCHAR(04),
  num_solic	VARCHAR(10),
  Id INT NOT NULL DEFAULT 0,
  Reference VARCHAR(200),
  CountingDate DATETIME,
  observacoes   VARCHAR(200),
  dthr_inc DATETIME,
  dthr_retorno_integracao DATETIME,
  PRIMARY KEY tbintegraSAP_ContagemTopoPK (TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic),
  INDEX tbintegraSAP_ContagemTopoIDX1 (Id)  );
  
DROP TABLE IF EXISTS tbintegraSAP_ContagemItens;
CREATE TABLE tbintegraSAP_ContagemItens(
  TipoDocSLIN VARCHAR(03),
  cod_emp	VARCHAR(03),
  cod_fil	VARCHAR(03),
  ano_solic	VARCHAR(04),
  num_solic	VARCHAR(10),
  num_item VARCHAR(06),
  ItemCode VARCHAR(20) NOT NULL,
  WarehouseCode VARCHAR(30) NOT NULL,
  BinCode VARCHAR(30) NOT NULL,
  BatchNumber_Code VARCHAR(30),
  BatchNumber_Quantity DECIMAL(18,5),
  SerialNumber_ManufactureCode VARCHAR(30),
  ContedQuantity DECIMAL(18,5),
  #PRIMARY KEY tbintegraSAP_ContagemItensPK (TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic, num_item, BatchNumber_Code),
  PRIMARY KEY tbintegraSAP_ContagemItensPK (TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic, num_item, BatchNumber_Code, WarehouseCode),
  FOREIGN KEY tbintegraSAP_ContagemItensFK (TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic) 
      REFERENCES tbintegraSAP_ContagemTopo (TipoDocSLIN, cod_emp, cod_fil, ano_solic, num_solic) ON DELETE CASCADE);



CREATE TABLE tbintegraSAP_UpdCancPV (
   UniqueKey         VARCHAR(30) NOT NULL, 
   TipoUpdCanc       VARCHAR(01) NOT NULL,
   DocumentType      VARCHAR(3),
   DocumentId        INT,
   DocumentNumber    INT,
   DocumentDate      DATETIME,
   CardCode          VARCHAR(15), 
   CardName          VARCHAR(100), 
   LineNumber        INT,
   ItemCode          VARCHAR(30), 
   FreeText          VARCHAR(300), 
   Quantity          DECIMAL(18,5),
   SERIAL            INT,
   Address2          VARCHAR(100), 
   Comments          VARCHAR(300), 
   AddrTypeS         VARCHAR(10), 
   StreetS           VARCHAR(100), 
   StreetNoS         VARCHAR(30), 
   BlockS            VARCHAR(50), 
   BuildingS         VARCHAR(50), 
   CityS             VARCHAR(50), 
   ZipCodeS          VARCHAR(10), 
   StateS            VARCHAR(02), 
   CountryS          VARCHAR(50), 
   BatchNumber_Code  VARCHAR(30), 
   BatchNumber_Quantity DECIMAL(18,5),
   SerialNumber_ManufactureCode VARCHAR(30), 
   ManBtchNum        BOOL,
   ManSerNum         BOOL ,
   Description       VARCHAR(100),
   Price             DECIMAL(18,5),
   BuyUnitMsr        VARCHAR(10), 
   SalUnitMsr        VARCHAR(10), 
   InvntryUom        VARCHAR(10), 
   NumInSale         DECIMAL(18,5),
   SlpName           VARCHAR(100),
   Incoterms         VARCHAR(10),	
   TrnspName         VARCHAR(100),	
   TrnspTaxIdNum     VARCHAR(20),	
   TipoDocSLIN       VARCHAR(10), 
   cod_emp           VARCHAR(03), 
   cod_fil           VARCHAR(03),
   ano_solic         VARCHAR(04),
   num_solic         VARCHAR(10),
   num_item          VARCHAR(06),
PRIMARY KEY (UniqueKey, TipoUpdCanc),
INDEX tbintegraSAP_UpdCancPVIdx1 (DocumentType, DocumentId, DocumentNumber, TipoUpdCanc),   
INDEX tbintegraSAP_UpdCancPVIdx2 (cod_emp, cod_fil, ano_solic, num_solic, num_item)    
);


ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN flg_deleted INT NOT NULL DEFAULT 0;

ALTER TABLE tbintegraSAP_UpdCancPV
#ADD COLUMN STATUS INT NOT NULL DEFAULT 0 COMMENT "0=EM ABERTO, 1=A PROCESSAR, 2=EM PROCESSAMENTO, 3=PROCESSADO";
MODIFY COLUMN STATUS INT NOT NULL DEFAULT 0 COMMENT "0=EM ABERTO, 1=A PROCESSAR, 2=EM PROCESSAMENTO, 3=PROCESSADO";

ALTER TABLE tbintegraSAP_UpdCancPV
DROP PRIMARY KEY,
DROP INDEX tbintegraSAP_UpdCancPVIdx1,
DROP INDEX tbintegraSAP_UpdCancPVIdx2;


ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN UpdateDate DATETIME NOT NULL AFTER TipoUpdCanc,
ADD PRIMARY KEY (UniqueKey, TipoUpdCanc,UpdateDate),
ADD INDEX tbintegraSAP_UpdCancPVIdx1 (DocumentType, DocumentId, DocumentNumber, TipoUpdCanc,UpdateDate),   
ADD INDEX tbintegraSAP_UpdCancPVIdx2 (cod_emp, cod_fil, ano_solic, num_solic, num_item,UpdateDate);  

UPDATE tbintegraSAP_UpdCancPV
SET UpdateDate = IFNULL(DocumentDate,NOW());

ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN dthr_inc DATETIME DEFAULT NOW();

ALTER TABLE tbintegraSAP_UpdCancPV
DROP COLUMN dthr_update;

#2020-12-23
ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN DocumentDueDate DATETIME AFTER DocumentDate



ALTER TABLE tbwms_manut_lote
ADD COLUMN dthr_retorno_integracao DATETIME;



DROP TABLE IF EXISTS of_logistica.tbsolic_saidas_item_integra_alteracao;
CREATE TABLE of_logistica.tbsolic_saidas_item_integra_alteracao
( id_log INT(11) NOT NULL AUTO_INCREMENT PRIMARY KEY
, cod_emp VARCHAR(03) NOT NULL
, cod_fil VARCHAR(03) NOT NULL
, ano_solic VARCHAR(04) NOT NULL
, num_solic VARCHAR(10) NOT NULL
, num_item VARCHAR(06) NOT NULL
, UniqueKey VARCHAR(30) NOT NULL
, dthr_inc DATETIME NOT NULL
, qtde_est_ant DECIMAL(18,5) NULL
, qtde_vol_ant DECIMAL(18,5) NULL
, qtde_frac_ant DECIMAL(18,5) NULL
, qtde_peso_ant DECIMAL(18,5) NULL
, qtde_est_atu DECIMAL(18,5) NULL
, qtde_vol_atu DECIMAL(18,5) NULL
, qtde_frac_atu DECIMAL(18,5) NULL
, qtde_peso_atu DECIMAL(18,5) NULL
, dthr_atu_integra DATETIME NULL
, dthr_realizado DATETIME NULL
, usu_realizado VARCHAR(06) NULL
, CONSTRAINT fk_tbsolic_saidas_item_integra_alteracaoTopo FOREIGN KEY (cod_emp, cod_fil, ano_solic, num_solic, num_item)
REFERENCES of_logistica.tbsolic_saidas_item (cod_emp, cod_fil, ano_solic, num_solic, num_item)
ON DELETE CASCADE
ON UPDATE RESTRICT
, CONSTRAINT fk_tbsolic_saidas_item_integra_alteracaoUsu FOREIGN KEY (usu_realizado)
REFERENCES of_logistica.tbusuarios (cod_usu)
ON DELETE RESTRICT
ON UPDATE RESTRICT
);

ALTER TABLE of_logistica.tbsolic_saidas_item_integra_alteracao
ADD KEY idx_tbsolic_saidas_item_integra_alteracao (UniqueKey, dthr_inc);


#select * from of_logistica.tbstatus_lotes
/*
IMPORTAÇÕES EM ANDAMENTO =
EM PODER DE TERCEIROS = 
DEPÓSITO DE IMPRODUTIVOS = 
DEPÓSITO DE INVENTÁRIO = 
ENVIO DIRETO = NÃO MOVIMENTA O ESTOQUE
QUARENTENA = 
MERCADORIA PARA REVENDA = 
"DEPÓSITO" WMS ESTOQUE 1
*/


/*
Procedures necessárias
************SLIN**********************
* Cadastro de Produtos (PROC_INTEGRA_CAD_Produtos)
* Cadastro de Clientes (PROC_INTEGRA_CAD_ClienteFornecedor)
* Cadastro de Destinatarios (PROC_INTEGRA_CAD_Destinatario)

* Enviar Topo Pedido de Separação (PROC_INTEGRA_EnviarPedidoSaida)
* Enviar Itens Pedido de Separação (PROC_INTEGRA_EnviarPedidoSaidaItem)
Enviar Itens Pedido de Separação (alteração) => travar a separação e aguardar reabertura de itens em andamento

Enviar Topo NF Entrada
Enviar Itens NF Entrada

* Retorno Topo Pedido de Separação
* Retorno Itens Pedido de Separação

Retorno Topo Recebimento
Retorno Itens Recebimento

Retorno Status SKU / UA

Retorno Status Carregamento


************INTERFACE**********************
* Inserir LOG Interface (PROC_INTEGRA_EnviarLog)
* Inserir/Atualizar DOCEntry (PROC_INTEGRA_EnviarDocEntry)
* Inserir/Atualizar DOCEntry_Item (PROC_INTEGRA_EnviarDocEntry_Item)
Proc AbreGEM -> Leitura DocEntry
Proc AbreGSM -> Leitura DocEntry
Proc StopGSM -> Leitura DocEntry (Alterção)
Proc AtuDocEntry -> Status GEM / GSM


************TRATATIVAS SLIN**********************
travar conferencia quando tiver alteração de pedido
travar exclusão de GEM / GSM quando integração SAP
*/






#Flag Produção
ALTER TABLE of_logistica.tbsolic_saidas ADD COLUMN flg_producao CHAR(1) NOT NULL DEFAULT 'N' AFTER flg_emite_nf;
UPDATE tbsolic_saidas
LEFT JOIN tbwms_tipo_oper ON 
      tbwms_tipo_oper.cod_oper_wms = tbsolic_saidas.flg_tipo_oper
SET tbsolic_saidas.flg_producao = tbwms_tipo_oper.flg_producao;
 
ALTER TABLE of_logistica.tbsolic_entradas ADD COLUMN flg_producao CHAR(1) NOT NULL DEFAULT 'N' AFTER flg_devol; 
UPDATE tbsolic_entradas
LEFT JOIN tbwms_tipo_oper ON 
      tbwms_tipo_oper.cod_oper_wms = tbsolic_entradas.flg_tipo_oper
SET tbsolic_entradas.flg_producao = tbwms_tipo_oper.flg_producao;




#2020-10-22
ALTER TABLE tbintegraSAP_Doc
MODIFY COLUMN DocTipo VARCHAR(10) NOT NULL;

ALTER TABLE tbintegraSAP_DocItem
MODIFY COLUMN DocTipo VARCHAR(10) NOT NULL;

ALTER TABLE tbintegraSAP_UpdCancPV
MODIFY COLUMN UniqueKey VARCHAR(50) NOT NULL,
MODIFY COLUMN DocumentType VARCHAR(10);



/*=============================================================*/
#2020-10-29
ALTER TABLE tbsolic_entradas
MODIFY flg_tipo_doc VARCHAR(05) DEFAULT NULL,
MODIFY num_nf VARCHAR(20);

ALTER TABLE tbsolic_entradas_fiscal
MODIFY flg_tipo_doc VARCHAR(05) DEFAULT NULL,
MODIFY num_nf VARCHAR(20);

ALTER TABLE tbsolic_entradas_item
MODIFY num_nf_vda VARCHAR(20);

ALTER TABLE tbsolic_saidas
MODIFY num_nf VARCHAR(20);

ALTER TABLE tbsolic_saidas_item
MODIFY num_ped_aux VARCHAR(20),
MODIFY num_ped_cli VARCHAR(20);

ALTER TABLE tbprodutos
MODIFY descr_produto VARCHAR(60),
MODIFY descr_abrev VARCHAR(60),
MODIFY descr_estrangeiro VARCHAR(60);


#============================================================================================
#2020-11-20
#Criação campos chave_integração

ALTER TABLE tbsolic_saidas
ADD COLUMN chave_integracao VARCHAR(50),
ADD INDEX idx_tbsolic_saidas_integracao (chave_integracao);

ALTER TABLE tbsolic_entradas
ADD COLUMN chave_integracao VARCHAR(50),
ADD INDEX idx_tbsolic_entradas_integracao (chave_integracao);

ALTER TABLE tbprog_entregas
ADD COLUMN chave_integracao VARCHAR(50),
ADD INDEX idx_proc_entregas_integracao (chave_integracao);

ALTER TABLE tbnf_clientes
ADD COLUMN chave_integracao VARCHAR(50),
ADD INDEX idx_tbnf_clientes_integracao (chave_integracao);


ALTER TABLE tbintegraSAP_Doc
ADD COLUMN chave_integracao VARCHAR(50) AFTER DocNum,
ADD INDEX idx_tbintegraSAP_Doc_integracao (chave_integracao);
UPDATE tbintegraSAP_Doc
SET chave_integracao = CONCAT(DocTipo,DocNum,'-',DocEntry);



UPDATE of_logistica.tbsolic_saidas
INNER JOIN tbintegraSAP_Doc ON 
           tbintegraSAP_Doc.cod_emp   = tbsolic_saidas.cod_emp 
       AND tbintegraSAP_Doc.cod_fil   = tbsolic_saidas.cod_fil
       AND tbintegraSAP_Doc.ano_solic = tbsolic_saidas.ano_solic 
       AND tbintegraSAP_Doc.num_solic = tbsolic_saidas.num_solic
       AND tbintegraSAP_Doc.TipoDocSLIN = "S"
SET tbsolic_saidas.chave_integracao = CONCAT(tbintegraSAP_Doc.DocTipo,tbintegraSAP_Doc.DocNum,'-',tbintegraSAP_Doc.DocEntry);

UPDATE of_logistica.tbsolic_entradas
INNER JOIN tbintegraSAP_Doc ON 
           tbintegraSAP_Doc.cod_emp   = tbsolic_entradas.cod_emp 
       AND tbintegraSAP_Doc.cod_fil   = tbsolic_entradas.cod_fil
       AND tbintegraSAP_Doc.ano_solic = tbsolic_entradas.ano_solic 
       AND tbintegraSAP_Doc.num_solic = tbsolic_entradas.num_solic
       AND tbintegraSAP_Doc.TipoDocSLIN = "E"
SET tbsolic_entradas.chave_integracao = CONCAT(tbintegraSAP_Doc.DocTipo,tbintegraSAP_Doc.DocNum,'-',tbintegraSAP_Doc.DocEntry);


UPDATE of_logistica.tbprog_entregas
INNER JOIN of_logistica.tbsolic_saidas_item ON 
           tbprog_entregas.cod_emp      = tbsolic_saidas_item.cod_emp_pedido
       AND tbprog_entregas.cod_fil      = tbsolic_saidas_item.cod_fil_pedido
       AND tbprog_entregas.cnpj_cpf_cli = tbsolic_saidas_item.cnpj_cpf_cli
       AND tbprog_entregas.num_nf_cli   = tbsolic_saidas_item.num_ped_cli
INNER JOIN of_logistica.tbsolic_saidas ON 
           tbsolic_saidas.cod_emp   = tbsolic_saidas_item.cod_emp
       AND tbsolic_saidas.cod_fil   = tbsolic_saidas_item.cod_fil
       AND tbsolic_saidas.ano_solic = tbsolic_saidas_item.ano_solic
       AND tbsolic_saidas.num_solic = tbsolic_saidas_item.num_solic
INNER JOIN tbintegraSAP_Doc ON 
           tbintegraSAP_Doc.cod_emp   = tbsolic_saidas.cod_emp   
       AND tbintegraSAP_Doc.cod_fil   = tbsolic_saidas.cod_fil
       AND tbintegraSAP_Doc.ano_solic = tbsolic_saidas.ano_solic
       AND tbintegraSAP_Doc.num_solic = tbsolic_saidas.num_solic
       AND tbintegraSAP_Doc.TipoDocSLIN = "S"
SET tbprog_entregas.chave_integracao = CONCAT(tbintegraSAP_Doc.DocTipo,tbintegraSAP_Doc.DocNum,'-',tbintegraSAP_Doc.DocEntry);

UPDATE of_logistica.tbnf_clientes
INNER JOIN of_logistica.tbprog_entregas ON
      tbnf_clientes.id_nf = tbprog_entregas.id_nf
SET tbnf_clientes.chave_integracao = tbprog_entregas.chave_integracao;




/************************************************************************************************************************/


DELETE FROM of_logistica.tbsolic_saidas;
DELETE FROM of_logistica.tbwms_mov_pallets;
DELETE FROM of_logistica.tbwms_estoque;
DELETE FROM of_logistica.tbsolic_entradas;
DELETE FROM of_logistica.tbprog_entregas;
DELETE FROM of_logistica.tbnf_clientes;

UPDATE tbintegraSAP_Doc
SET StatusDoc = 1,
cod_emp = NULL, cod_fil = NULL, ano_solic = NULL, num_solic = NULL, TipoDocSLIN = NULL;

CALL PROC_INTEGRA_AtualizarSLIN('999999',@R, @M);
SELECT @R, @M;

SELECT * FROM tbintegraSAP_Doc;
SELECT * FROM of_logistica.tbsolic_saidas;
SELECT * FROM of_logistica.tbsolic_saidas_item;
SELECT * FROM of_logistica.tbsolic_entradas;
SELECT * FROM of_logistica.tbsolic_entradas_item;
SELECT * FROM of_logistica.tbprog_entregas;
SELECT * FROM of_logistica.tbprog_ite_entregas;
SELECT * FROM of_logistica.tbnf_clientes;
SELECT * FROM of_logistica.tbnf_ite_clientes;





/************************************************************************************************************************/
#2021/01/05
CREATE TABLE tbintegraSAP_empresas (
id_empresa INT AUTO_INCREMENT,
id_integracao VARCHAR(20) NOT NULL,
cnpj_empresa  VARCHAR(20),
raz_social    VARCHAR(100) NOT NULL,
endereco      VARCHAR(100),
complemento   VARCHAR(100),
bairro        VARCHAR(100),
cidade        VARCHAR(100),
estado        VARCHAR(10),
flg_ativo     INT DEFAULT 1 NOT NULL,
PRIMARY KEY (id_empresa),
UNIQUE KEY idx_tbintegraSAP_empresas (id_integracao));

INSERT INTO tbintegraSAP_empresas (id_integracao, raz_social) VALUES 
(1,'MISTRAL IMPORTADORA LTDA (Guarulhos)'),
(2,	'MISTRAL IMPORTADORA LTDA (Rocha)'),
(3,	'MISTRAL IMPORTADORA LTDA (Iguatemi)'),
(4,	'MISTRAL IMPORTADORA LTDA (NET)'),
(5,	'MISTRAL IMPORTADORA LTDA (JK)'),
(6,	'MISTRAL IMPORTADORA LTDA (São Mateus)'),
(7,	'MISTRAL IMPORTADORA LTDA (Eventos)'),
(8,	'VINCI IMPORTADORA E EXPORTADORA DE BEBIDAS LTDA (Belém)'),
(23,	'MISTRAL IMPORTADORA LTDA (Alamenda Santos)'),
(10,	'MV EXPRESS DISTRIBUIDORA DE BEBIDAS LTDA (Cambuci)'),
(11,	'MV EXPRESS DISTRIBUIDORA DE BEBIDAS LTDA (Rocha)'),
(12,	'MV EXPRESS DISTRIBUIDORA DE BEBIDAS LTDA (Pamplona)'),
(13,	'MV RIO DE JANEIRO DISTRIBUIDORA DE BEBIDAS LTDA (Santo Cristo)'),
(14,	'MV RIO DE JANEIRO DISTRIBUIDORA DE BEBIDAS LTDA (Gávea)'),
(15,	'MV BAHIA DISTRIBUIDORA DE BEBIDAS LTDA (Lauro de Freitas)'),
(16,	'MISTRAL BH DISTRIBUIDORA DE BEBIDAS LTDA (Savassi)'),
(17,	'MISTRAL COMERCIO DE VINHOS LTDA (Lago Azul)'),
(18,	'MISTRAL RJ DISTRIBUIDORA DE BEBIDAS LTDA (Gávea)'),
(19,	'MV BRASILIA DISTRIBUIDORA DE BEBIDAS LTDA (Núcleo Band.)'),
(20,	'MISTRAL WINE BAR (backoffice)'),
(9	, 'MISTRAL IMPORTADORA LTDA (Pamplona)'),
(24,	'MISTRAL IMPORTADORA LTDA (Belém)');


ALTER TABLE tbintegraSAP_DeParaStatus_Armazem
ADD descr_armazem VARCHAR(100) AFTER cod_armazem;



/************************************************************************************************************************/
#2021/01/14
ALTER TABLE tbintegraSAP_Doc
MODIFY COLUMN AddrTypeS VARCHAR(20);

ALTER TABLE tbintegraSAP_UpdCancPV
MODIFY COLUMN AddrTypeS VARCHAR(20);

ALTER TABLE tbintegraSAP_UpdCancPV
MODIFY COLUMN Address2 VARCHAR(200);

ALTER TABLE tbintegraSAP_UpdCancPV
MODIFY COLUMN BuildingS VARCHAR(100);


/************************************************************************************************************************/
#2021/01/17
ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN QtdeEstoque DECIMAL(18,6) AFTER Quantity

ALTER TABLE tbprodutos
ADD COLUMN emb_estoque_cli VARCHAR(10) AFTER fator_conversao,
ADD COLUMN emb_compras VARCHAR(10) AFTER emb_estoque_cli,
ADD COLUMN fator_conv_compras DECIMAL(18,6) AFTER emb_compras,
ADD COLUMN emb_vendas VARCHAR(10) AFTER fator_conv_compras,
ADD COLUMN fator_conv_vendas DECIMAL(18,6) AFTER emb_vendas;

START TRANSACTION;
UPDATE tbprodutos 
SET emb_compras = IFNULL(emb_compras, emb_vol), 
    fator_conv_compras = IFNULL(fator_conv_compras ,fator_conversao), 
    emb_vendas = IFNULL(emb_vendas , emb_estoque), 
    fator_conv_vendas = IFNULL(fator_conv_vendas ,1), 
    emb_estoque_cli = IFNULL(emb_estoque_cli ,emb_estoque);
COMMIT;                      


ALTER TABLE tbintegraSAP_DocItem
MODIFY COLUMN buyUnitMsr VARCHAR(30),
MODIFY COLUMN salUnitMsr VARCHAR(30),
MODIFY COLUMN invntryUom VARCHAR(30);

ALTER TABLE tbprodutos
MODIFY COLUMN emb_estoque_cli VARCHAR(30),
MODIFY COLUMN emb_compras VARCHAR(30),
MODIFY COLUMN emb_vendas VARCHAR(30);

ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN NumInBuy  DECIMAL(18,5) COMMENT 'Fator de Conversão Compras SAP' AFTER NumInSale;

#criar fnTirarCaracteresEspeciais na of_integraSAP



/************************************************************************************************************************/
#2021/01/27
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN flg_retorno_entrada_ENE TINYINT DEFAULT 1,
ADD COLUMN flg_retorno_entrada_ERM TINYINT DEFAULT 1,
ADD COLUMN flg_retorno_entrada_NE TINYINT DEFAULT 1,
ADD COLUMN flg_retorno_entrada_PD TINYINT DEFAULT 1,
ADD COLUMN flg_obriga_checkout_retornoPV TINYINT DEFAULT 1,
ADD COLUMN flg_obriga_roteiriz_retornoPV TINYINT DEFAULT 1;




/************************************************************************************************************************/
#2021/01/27
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN emb_faturamento VARCHAR(50) DEFAULT 'Volumes';

ALTER TABLE tbintegraSAP_Doc
ADD COLUMN Route      VARCHAR(50) AFTER CnpjTransp,
ADD COLUMN StartTime1 VARCHAR(20) AFTER Route,
ADD COLUMN EndTime1   VARCHAR(20) AFTER StartTime1,
ADD COLUMN StartTime2 VARCHAR(20) AFTER EndTime1,
ADD COLUMN EndTime2   VARCHAR(20) AFTER StartTime2;



/************************************************************************************************************************/
#2021/02/08
ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN DollarQuote DECIMAL(18,5) AFTER Price,
ADD COLUMN LineNumPk INT AFTER LineNum

UPDATE tbintegraSAP_DocItem
SET LineNumPk = LineNum;

ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN DollarQuote DECIMAL(18,5) AFTER Price;



/************************************************************************************************************************/
#2021/02/11
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN CFOP VARCHAR(10) AFTER NomeVendedor



/************************************************************************************************************************/
#2021/02/19
ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN Route      VARCHAR(50) AFTER TrnspTaxIdNum,
ADD COLUMN StartTime1 VARCHAR(20) AFTER Route,
ADD COLUMN EndTime1   VARCHAR(20) AFTER StartTime1,
ADD COLUMN StartTime2 VARCHAR(20) AFTER EndTime1,
ADD COLUMN EndTime2   VARCHAR(20) AFTER StartTime2;





/************************************************************************************************************************/
#2021/02/19
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN SERIAL INT DEFAULT 0 AFTER CardName



/************************************************************************************************************************/
#2021/04/29
ALTER TABLE tbintegraSAP_UpdCancPV
ADD INDEX tbintegraSAP_UpdCancPVIdx3 (TipoUpdCanc, STATUS, UpdateDate)



/************************************************************************************************************************/
#2021/08/20
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN End_Entrega VARCHAR(200) AFTER EndTime2;


ALTER TABLE tbintegraSAP_empresas
ADD COLUMN cod_emp_slin VARCHAR(03) AFTER estado,
ADD COLUMN cod_fil_slin VARCHAR(03) AFTER cod_emp_slin;
UPDATE tbintegraSAP_empresas SET cod_emp_slin = '001', cod_fil_slin = '001' LIMIT 1


/************************************************************************************************************************/
#2021/08/30
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN TipoProducao VARCHAR(20) AFTER idPickingAnt;

ALTER TABLE tbintegraSAP_Doc
MODIFY COLUMN idPickingAnt VARCHAR(200);

ALTER TABLE tbintegraSAP_Doc
ADD COLUMN WhareHouseTransf VARCHAR(30) COMMENT "Quando Entrada WHEntrada, quando Saida WHDestino" AFTER WhareHouse;


ALTER TABLE tbintegraSAP_parametros
ADD COLUMN flg_retorno_entrada_TD TINYINT(4) DEFAULT 1 AFTER flg_retorno_entrada_PD;


#Criar Operações de Entrada e Saída por Transferencia entre depósitos
INSERT INTO of_logistica.tbwms_tipo_oper (cod_oper_wms, descr_oper_wms, tipo_movto) VALUES 
('013','Entrada por Transferencia entre depósitos','E'),
('014','Saída por Transferencia entre depósitos','S');

#Criar Parametros para Operações de Entrada e Saída por Transferencia entre depósitos
INSERT INTO of_logistica.tbsys_integracao_estoque (id_integracao, id_estoque, cod_emp, cod_fil, cnpj_cpf_cli, cod_estoque, cod_oper_wms, chave_integracao)
VALUES (1,0, '001', '001', 'CNPJ', '001', '013','TD-E'),(1,0, '001', '001', 'CNPJ', '001', '014','TD-S');



/************************************************************************************************************************/
#2021/08/31
CREATE TABLE tbintegraSAP_Depositos (
   cod_deposito VARCHAR(10) NOT NULL,
   id_empresa VARCHAR(20) DEFAULT NULL,
PRIMARY KEY (cod_deposito),
CONSTRAINT FK_tbintegraSAP_Depositos_empresa FOREIGN KEY (id_empresa) REFERENCES tbintegraSAP_empresas(id_integracao) ON DELETE SET NULL);
INSERT INTO tbintegraSAP_Depositos VALUES ('01', 1);



/************************************************************************************************************************/
#2021/09/22
DROP TABLE tbintegraSAP_TipoDoc;
CREATE TABLE tbintegraSAP_TipoDoc (
   DocTipo VARCHAR(10)
   ,Condicao        VARCHAR(50)
   ,Descr_DocTipo   VARCHAR(50)
   ,Observ_DocTipo  VARCHAR(200)
   ,TipoDocSLIN     VARCHAR(1)    COMMENT '<E>ntrada, <S>aida, <-> Não Processar'
   ,GeraRetornoSAP  INT
   ,PRIMARY KEY (DocTipo, Condicao)
 );
INSERT INTO tbintegraSAP_TipoDoc VALUES
('NE',   '', 'NF Entrada Futura'                 , 'Compras : NF Entrada Futura'              , 'E',1),
('PV',   '', 'Pedido de Vendas'                  , 'Vendas : Pedido de Vendas'                , 'S',1),
('PA',   '', 'Produto Acabado'                   ,'Produção : Entrada de Produto Acabado'     , 'E',1),
('E-RM', '', 'Esboço Recebimento de Mercadoria'  , NULL                                       , 'E',1),
('E-NE', '', 'Esboço NF Entrada de Mercadorias'  , NULL                                       , 'E',1), 
('DV',   '', 'Pedido de Devolução de Vendas'     , 'Entrada por Devolução de Vendas'          , 'E',1),
#('OP',   null, 'Ordem de Produção'                 , 'Produção : Saída de Matéria Prima'        , 'S',1),
('OP',   "tbintegraSAP_Doc.TipoProducao IN ('PEX','PEC')", 'Ordem de Produção'                 , 'Produção : Saída de Matéria Prima'        , 'S',1),
('TD-S', '', 'Pedido de Transferencia (Saída)'   , 'Transferencia entre Depósitos : Saida'    , 'S',1),
('TD-E', '', 'Pedido de Transferencia (Entrada)' , 'Transferencia entre Depósitos : Entrada'  , 'E',1),
('NS', '', 'NF Entrega Futura' , 'Nota Fiscal Entrega Futura'  , 'S',1);



/************************************************************************************************************************/
#2021/09/30
ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN End_Entrega VARCHAR(200) AFTER EndTime2;







/************************************************************************************************************************/
#2021/11/04
ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN UgpEntry     INT AFTER DollarQuote,
ADD COLUMN UomCode      VARCHAR(30) AFTER UgpEntry,
ADD COLUMN unitMsr      VARCHAR(30) AFTER UomCode,
ADD COLUMN OpenInvQty   DECIMAL(20,6) AFTER unitMsr;

ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN UgpEntry     INT AFTER DollarQuote,
ADD COLUMN UomCode      VARCHAR(30) AFTER UgpEntry,
ADD COLUMN unitMsr      VARCHAR(30) AFTER UomCode,
ADD COLUMN OpenInvQty   DECIMAL(20,6) AFTER unitMsr;




/********************************************************************************************************************************/
#2021/12/06
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN RefViagem VARCHAR(50) AFTER Observacoes,
ADD COLUMN StatusEntrega VARCHAR(50) AFTER RefViagem,
ADD COLUMN StatusArmazem VARCHAR(50) AFTER StatusEntrega;







/********************************************************************************************************************************/
#2022/01/14
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN U_RSD_RplOrder VARCHAR(20) AFTER TipoProducao;





/********************************************************************************************************************************/
#2022/02/10
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN flg_agrupa_transf TINYINT DEFAULT 1 COMMENT "Flag agrupar transferencias referentes OP´"





/*******************************************************/
#2022/03-18
ALTER TABLE tbintegraSAP_Doc
DROP COLUMN tipo_pessoa;

ALTER TABLE tbintegraSAP_Doc
ADD COLUMN NumCPF  VARCHAR(20) AFTER CardCode,
ADD COLUMN NumCNPJ VARCHAR(20) AFTER CardCode;

DROP TABLE IF EXISTS tbintegraSAP_TipoFrete;
/*CREATE TABLE tbintegraSAP_TipoFrete (
   Incoterms VARCHAR(05) NOT NULL,
   TipoFrete VARCHAR(05) DEFAULT 'C' COMMENT "<C>IF ou <F>OB ou R<E>TIRA",
   CodTipoOper VARCHAR(03) DEFAULT '001',
   PRIMARY KEY (Incoterms));
SELECT * FROM tbintegraSAP_TipoFrete;
*/

ALTER TABLE tbintegraSAP_DeParaOperTMS
ADD COLUMN TipoFrete VARCHAR(05) DEFAULT 'C' COMMENT "<C>IF ou <F>OB ou R<E>TIRA" AFTER cod_oper_tms;
SELECT * FROM tbintegraSAP_DeParaOperTMS




/*******************************************************/
#2022/03-21
DROP TABLE IF EXISTS tbintegraSAP_DocPicking;
CREATE TABLE tbintegraSAP_DocPicking (
   DocEntry    INT, 
   Doctipo     VARCHAR(10), 
   DocNum      INT, 
   IdPicking   INT, 
   PkLineNum   INT, 
   DocLineNum  INT,
   dthr_inc    DATETIME,
   PRIMARY KEY (IdPicking, PkLineNum),
   UNIQUE KEY (DocEntry, DocTipo, DocNum, IdPicking, PkLineNum),
   FOREIGN KEY (DocEntry, DocTipo, DocNum, DocLineNum) REFERENCES tbintegraSAP_DocItem (DocEntry, DocTipo, DocNum, LineNum)
   );


INSERT IGNORE INTO tbintegraSAP_DocPicking
   SELECT tbintegraSAP_DocItem.DocEntry, tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum, 
          tbintegraSAP_Doc.idPicking, tbintegraSAP_DocItem.LineNumPk, tbintegraSAP_DocItem.LineNum
   FROM tbintegraSAP_DocItem
   INNER JOIN tbintegraSAP_Doc ON
              tbintegraSAP_Doc.DocEntry = tbintegraSAP_DocItem.DocEntry
          AND tbintegraSAP_Doc.DocTipo  = tbintegraSAP_DocItem.DocTipo
   WHERE IFNULL(tbintegraSAP_Doc.idPicking,0) > 0
     AND tbintegraSAP_Doc.TipoDocSLIN = 'S'
     AND tbintegraSAP_Doc.StatusDoc <= 3;



/********************************************************************************/
#2022-03-29
ALTER TABLE tbintegraSAP_UpdCancPV
MODIFY COLUMN Description VARCHAR(200);



/********************************************************************************/
#2022-04-03
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN UpdateDate DATETIME AFTER TaxDate;

ALTER TABLE tbintegraSAP_parametros
ADD COLUMN flg_permite_PVParcial TINYINT(4) DEFAULT 0,
ADD COLUMN flg_RplOrdr VARCHAR(03) COMMENT 'Se origem PV S<A>P, <C>ommerce, <S>ales';



#2022-07-04
ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN Usage_ VARCHAR(10) AFTER DollarQuote


/*****************************************************************************/
#2022/01/29
# Limpar lista do PROC_INTEGRA_RetornoTMS(0)
CREATE TEMPORARY TABLE tbTMP
SELECT DISTINCT DocEntry, DocTipo, DocNum, 
       tbRotas.descr_rota RotaCliente, 
       CASE IFNULL(tbEntregas.status_entre,-1)
          WHEN -1 THEN "A roteirizar"
          WHEN 0 THEN "Em Roteirização"
          WHEN 1 AND tbEntregas.status_baixa IS NULL THEN
                     IF(tbViagens.dthr_liberacao IS NULL, "Roteirizado - Entrega em aberto",
                                                          "Em Rota para entrega") 
       ELSE of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)
       END AS StatusEntrega,
       IF(tbSaidas.status_processo < 5, "Em Preparação", 
          of_logistica.fnStatusSaidaWms(tbSaidas.status_processo)) AS StatusArmazem,
       IF(tbViagens.data_conf IS NULL, "",
          CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem,'=>',
          IFNULL(tbRotas.descr_rota,IFNULL(tbRotas2.descr_rota,"")))) RefViagem,
       tbViagens.cnpj_transportador CodTranspTMS,
       tbViagens.data_conf, tbViagens.dthr_liberacao,
       tbEntregas.status_entre, tbEntregas.status_baixa,
       tbintegraSAP_Doc.RefViagem RefViagemAux,
       tbintegraSAP_Doc.StatusEntrega StatusEntregaAux
FROM tbintegraSAP_Doc
INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
      tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
  AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
  AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
  AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
INNER JOIN of_logistica.tbprog_entregas tbEntregas ON
          tbEntregas.chave_integracao = tbSaidas.chave_integracao
LEFT JOIN of_logistica.tbdestinatarios tbDest ON 
          tbDest.id_destinatario = tbEntregas.id_destinatario
LEFT JOIN of_logistica.tbrotas tbRotas ON
          tbRotas.cod_emp  = tbDest.emp_rota
      AND tbRotas.cod_fil  = tbDest.fil_rota
      AND tbRotas.cod_rota = tbDest.cod_rota                
LEFT JOIN of_logistica.tbviagens tbViagens ON 
          tbViagens.cod_emp    = tbEntregas.cod_emp 
      AND tbViagens.cod_fil    = tbEntregas.cod_fil
      AND tbViagens.ano_viagem = tbEntregas.ano_viagem
      AND tbViagens.num_viagem = tbEntregas.num_viagem
LEFT JOIN of_logistica.tbrotas tbRotas2 ON
          tbRotas2.cod_emp  = tbViagens.emp_rota
      AND tbRotas2.cod_fil  = tbViagens.fil_rota
      AND tbRotas2.cod_rota = tbViagens.cod_rota                
WHERE tbintegraSAP_Doc.DocTipo IN ("PV","TD-S","NS")
  AND tbSaidas.dthr_cancelamento IS NULL
  AND (tbEntregas.status_baixa IS NULL OR 
       DATE(tbEntregas.dthr_baixa) = CURRENT_DATE());
       
       
UPDATE tbintegraSAP_Doc TbTopo
INNER JOIN tbTMP ON
       tbTMP.DocEntry = TbTopo.DocEntry
   AND tbTMP.DocTipo  = TbTopo.DocTipo
   AND tbTMP.DocNum   = TbTopo.DocNum
SET TbTopo.RefViagem = tbTMP.RefViagem ,
    TbTopo.StatusEntrega = tbTMP.StatusEntrega;
    
DROP TEMPORARY TABLE tbTMP;


/*******************************************************/
# Limpar lista do PROC_INTEGRA_RetornoTMS(1)
UPDATE tbnf_clientes 
SET chave_nfe = num_nf
WHERE chave_nfe IS NULL;






/*******************************************************/
# 2022-05-04
ALTER TABLE tbintegraSAP_Doc
MODIFY COLUMN BlockS VARCHAR(100);





/*******************************************************/
# 2022-05-11
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN dthr_email_monitor DATETIME;
UPDATE tbintegraSAP_parametros SET dthr_email_monitor = NOW();







/*******************************************************/
# 2022-05-11
ALTER TABLE tbsolic_entradas_item2 
ADD COLUMN deposito_integracao VARCHAR(10);
UPDATE tbsolic_entradas_item2 
LEFT JOIN tbsolic_entradas_acons ON 
          tbsolic_entradas_acons.cod_emp   = tbsolic_entradas_item2.cod_emp 
      AND tbsolic_entradas_acons.cod_fil   = tbsolic_entradas_item2.cod_fil
      AND tbsolic_entradas_acons.ano_solic = tbsolic_entradas_item2.ano_solic
      AND tbsolic_entradas_acons.num_solic = tbsolic_entradas_item2.num_solic
      AND tbsolic_entradas_acons.num_item  = tbsolic_entradas_item2.num_item
LEFT JOIN tbstatus_lotes ON 
          tbstatus_lotes.codigo = tbsolic_entradas_acons.cod_status_lote
SET tbsolic_entradas_item2.deposito_integracao = tbstatus_lotes.deposito_integracao;







#2022-09-23
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN BPLId INT AFTER DocNum,
ADD COLUMN IdSales VARCHAR(30) AFTER U_RSD_RplOrder,
ADD COLUMN IdCommerce VARCHAR(30) AFTER IdSales;
#DROP COLUMN 'USAGE'; # varchar(10) After CFOP;


ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN U_RSD_RplOrder VARCHAR(20) AFTER DocumentNumber,
ADD COLUMN BPLId INT AFTER U_RSD_RplOrder,
ADD COLUMN IDSales VARCHAR(30) AFTER BPLId,
ADD COLUMN IDCommerce VARCHAR(30) AFTER IDSales,
ADD COLUMN Usage_ VARCHAR(10) AFTER IDCommerce;


#2022-10-04
ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN TaxCode VARCHAR(15) AFTER Usage_;
ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN CFOPCode VARCHAR(15) AFTER TaxCode;



#2022-10-10
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN dthr_updcanc DATETIME



#2022-10-17
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN utilizacao_entradas VARCHAR(200),
ADD COLUMN utilizacao_saidas VARCHAR(200);



#2022-10-22
ALTER TABLE tbintegraSAP_CTe
ADD COLUMN dthr_cancel DATETIME;




#2022-11-01
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN utilizacao_entradas_retorno VARCHAR(200),
ADD COLUMN utilizacao_saidas_retorno VARCHAR(200);




#2022-11-02
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN MainUsage VARCHAR(30) AFTER CFOP;

ALTER TABLE tbintegraSAP_parametros
ADD COLUMN flg_ItensEstrutura INT DEFAULT 0 COMMENT '0=Não considera itens com estrutura, 1=Considera';




#2022-11-10
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN U_RSD_RplOrder INT DEFAULT 0 COMMENT 'Mistral Tabela OITM->U_RSD_RplOrder',
ADD COLUMN U_RSD_PreVenda INT DEFAULT 0 COMMENT 'Mistral Tabela OITM->U_RSD_PreVenda(Y/N)';




#2022-12-20
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN flg_alterar_apos_retorno INT DEFAULT 0 COMMENT 'Considerar alterações do PV após retorno ao SAP (0=não processar, 1=processar)';


ALTER TABLE tbintegraSAP_CTe
ADD COLUMN dthr_integracao DATETIME COMMENT "DtHr Ultima Integração SAP",
#*****add column dthr_analise datetime COMMENT "DtHr Ultima Análise FRETE SLIN" 
ADD COLUMN status_analise INT COMMENT "Null=Em Aberto, 1=Aprovado, 0=Reprovado", 
ADD COLUMN vlr_calculado DECIMAL(18,6) COMMENT "Valor Frete Calculado SLIN",
ADD COLUMN observ_analise VARCHAR(200);






#2023-08-03
#Parametro para retorno dos volumes para NF (PROC_INTEGRA_RetornoSaidaPicking)
ALTER TABLE tbintegraSAP_parametros
ADD COLUMN flg_campo_volumes INT DEFAULT 0 COMMENT "0=CHECKOUT / 1=EMB_VOL / 2=STRING_CHECKOUT"




/******************************************************/
#Erico 2023-08-04
ALTER TABLE tbsolic_saidas_volume
ADD COLUMN `id_insumo` INT(11) DEFAULT NULL,
ADD COLUMN `peso_bruto_insumo` DECIMAL(8,3) DEFAULT NULL,
ADD KEY `fk_tbsolic_saidas_volume` (`id_insumo`),
ADD CONSTRAINT `fk_tbsolic_saidas_volume` FOREIGN KEY (`id_insumo`) REFERENCES `tbwms_insumo` (`id_insumo`) ON UPDATE CASCADE




/******************************************************/
#Panizzon 2023-10-23
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN TransportationCode VARCHAR(10) AFTER TipoFrete;

ALTER TABLE tbintegraSAP_UpdCancPV
ADD COLUMN TransportationCode VARCHAR(10) AFTER Incoterms;





/******************************************************/
#Panizzon 2023-10-25
ALTER TABLE tbintegraSAP_Doc
MODIFY COLUMN NomeVendedor VARCHAR(60);



/******************************************************/
#Leme 2023-11-07 | Campos de conversão da Quantidade no Documento
ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN MeasureUnit VARCHAR(30) AFTER salUnitMsr,
ADD COLUMN UnitsOfMeasurment DECIMAL(18,5) AFTER NumInBuy;





/******************************************************/
#Panizzon 2023-11-27 | Log de Leitura de Etiquetas Produção
CREATE TABLE tbintegraSAP_EtiquetaUA (
    idEtiquetaUA INT AUTO_INCREMENT,
    cod_emp VARCHAR(03),
    cod_fil VARCHAR(03),
    num_lote VARCHAR(20),
    sequencia_lote INT,
    barcode_etiqueta VARCHAR(80),
    dthr_inc DATETIME,
    PRIMARY KEY (idEtiquetaUA),
    INDEX idx_tbintegraSAP_EtiquetaUA (cod_emp, cod_fil, num_lote, sequencia_lote),
    INDEX idx_tbintegraSAP_EtiquetaUA2 (barcode_etiqueta)
);
#Listar
CALL PROC_INTEGRA_MovtoEtiquetaProducao(1, xCodEmp, xCodFil, xNumLote, xSeqLote);
#Atualizar / Inserir
CALL PROC_INTEGRA_MovtoEtiquetaProducao(2, xCodEmp, xCodFil, xNumLote, xSeqLote);








/******************************************************************/
#Panizzon 2023-12-28 
ALTER TABLE tbintegraSAP_TipoFrete
ADD COLUMN TransportationCode VARCHAR(30);







/******************************************************************/
#BRW 2024-01-24  (Ajustes comments)
ALTER TABLE `tbintegraSAP_parametros`
MODIFY COLUMN  `emb_faturamento` VARCHAR(50) DEFAULT 'Volumes'  COMMENT 'Embalagens=>Elinox (fnContarEmbalagens)',
MODIFY COLUMN  `flg_campo_volumes` INT(11) DEFAULT '0' COMMENT '0=CHECKOUT / 1=EMB_ESTOQUE / 2,3=CampoTopo->QtdeVolManual'







/******************************************************************/
#BRW 2024-02-08 Definição Matriz / Filiais
ALTER TABLE tbintegraSAP_empresas
ADD COLUMN flgMatriz TINYINT DEFAULT 0






/******************************************************************/
#BRW 2024-02-10 Campo de usuário no SAP : Indicador (U_CVA_Indicador)
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN StatusAux_Cliente VARCHAR(200) AFTER StatusArmazem








/******************************************************************/
#2024-04-03 Tabela de SALDOS DE ESTOQUE
DROP TABLE IF EXISTS integraSAP_SaldoEstoque;
CREATE TABLE integraSAP_SaldoEstoque (
dthr_base   DATETIME    NOT NULL,
IdBase      INT         NOT NULL,
BPLId       VARCHAR(50) NOT NULL,
WhsCode     VARCHAR(50) NOT NULL,
ItemCode    VARCHAR(50) NOT NULL,
ItemName    VARCHAR(200) NOT NULL,
OnHand      DECIMAL(20,6),
OnOrder     DECIMAL(20,6),
IsCommited  DECIMAL(20,6),
Consig      DECIMAL(20,6),
Counted     DECIMAL(20,6),
dthr_inc    DATETIME,
PRIMARY KEY (dthr_base, IdBase, BPLId, WhsCode, ItemCode))

INSERT INTO integraSAP_SaldoEstoque (dthr_base, idBase, BPLId, WhsCode, ItemCode, ItemName, OnHand, OnOrder, IsCommited, Consig, Counted, dthr_inc)
VALUES (xdthr_base, xidBase, xBPLId, xWhsCode, xItemCode, xItemName, xOnHand, xOnOrder, xIsCommited, xConsig, xCounted, NOW())



UPDATE integraSAP_SaldoEstoque
INNER JOIN tbintegraSAP_empresas ON 
           tbintegraSAP_empresas.idBase        = integraSAP_SaldoEstoque.IdBase
       AND tbintegraSAP_empresas.id_integracao = integraSAP_SaldoEstoque.BPLId
INNER JOIN tbintegraSAP_DeParaStatus_Armazem ON 
           tbintegraSAP_DeParaStatus_Armazem.cod_armazem = integraSAP_SaldoEstoque.WhsCode
SET QtdeEstSLIN = (SELECT SUM(IFNULL(sld_fisico_est,0)) FROM of_lemelub.tbwms_estoque
                   WHERE tbwms_estoque.cod_emp      = tbintegraSAP_empresas.cod_emp_slin
                     AND tbwms_estoque.cod_fil      = tbintegraSAP_empresas.cod_fil_slin
                     AND tbwms_estoque.cnpj_cpf_dep = tbintegraSAP_empresas.cnpj_empresa
                     AND tbwms_estoque.cod_produto  = integraSAP_SaldoEstoque.ItemCode
                     AND tbwms_estoque.status_lote  = tbintegraSAP_DeParaStatus_Armazem.cod_status
                     AND tbwms_estoque.sld_fisico_est > 0),
    QtdeVolSLIN = (SELECT SUM(IFNULL(sld_fisico_vol,0)) FROM of_lemelub.tbwms_estoque
                   WHERE tbwms_estoque.cod_emp      = tbintegraSAP_empresas.cod_emp_slin
                     AND tbwms_estoque.cod_fil      = tbintegraSAP_empresas.cod_fil_slin
                     AND tbwms_estoque.cnpj_cpf_dep = tbintegraSAP_empresas.cnpj_empresa
                     AND tbwms_estoque.cod_produto  = integraSAP_SaldoEstoque.ItemCode
                     AND tbwms_estoque.status_lote  = tbintegraSAP_DeParaStatus_Armazem.cod_status
                     AND tbwms_estoque.sld_fisico_est > 0),
    dthrSLIN = NOW()
WHERE dthrSLIN IS NULL;
                     
    










/******************************************************************/
#2024-04-03 Inclusão do numero do Pedido de compras (Purchase Order) na GEM
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN DocEntryRef  VARCHAR(30) AFTER IdCommerce,
ADD COLUMN DocNumRef VARCHAR(30) AFTER DocEntryRef,
ADD COLUMN DocTotal DECIMAL(18,6) AFTER DocNumRef






/******************************************************************/
#2024-08-20 Observações até 2000 caracteres

ALTER TABLE tbintegraSAP_Doc
MODIFY Observacoes VARCHAR(2000);

ALTER TABLE tbintegraSAP_DocItem
MODIFY Observacoes VARCHAR(2000);


ALTER TABLE tbintegraSAP_UpdCancPV
MODIFY FreeText VARCHAR(2000),
MODIFY Comments VARCHAR(2000),
ADD COLUMN ObservItem VARCHAR(2000) AFTER FreeText;

ALTER TABLE of_logistica.tbsolic_saidas
MODIFY observ_solic VARCHAR(2000);






/******************************************************************/
#2024-09-11 Vlr_FreteCliente (Adto Frete do Cliente => Mistral)
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN Vlr_FreteCliente DECIMAL(20,6) AFTER TransportationCode







/******************************************************************/
#2024-11-22 Tabela Utilizada na fnStatusCliente (ATU_TMS)
DROP TABLE IF EXISTS tbintegraSAP_StatusWMS ;
CREATE TABLE tbintegraSAP_StatusWMS (
   IdStatusSAP INT,
   CodStatusSAP VARCHAR(20),
   DescrStatusSAP VARCHAR(100),
   FormatoRetorno INT DEFAULT 1    COMMENT '1=Codigo, 2=Descricao, 3=Codigo - Descricao',
   StatusProcessoSLIN VARCHAR(100) COMMENT 'Condição para status_processo, ex: >= 1 ou is null',
   StatusEntregaSLIN VARCHAR(100)  COMMENT 'Condição para status_entre, ex: >= 1 ou is null',
   StatusBaixaSLIN VARCHAR(100)    COMMENT 'Condição para status_baixa, ex: >= 1 ou is null',
   CondStatusSAP VARCHAR(500),
   PRIMARY KEY (IdStatusSAP),
   UNIQUE UK_tbintegraSAP_StatusWMS (CodStatusSAP,DescrStatusSAP) );






/******************************************************************/
#2025-02-23 NKIT (Gemmini)
ALTER TABLE tbintegraSAP_Doc
ADD COLUMN U_BDO_NKIT VARCHAR(50) AFTER U_RSD_RplOrder






/******************************************************************/
#2025-07-24 Pagador CTE
ALTER TABLE tbintegraSAP_CTe 
ADD COLUMN IdPagador INT AFTER IbgeCodeMuniFim;



ALTER TABLE tbintegraSAP_empresas
ADD COLUMN id_invent VARCHAR(10) AFTER id_integracao;








/**************************************************************************/
#David Ruy <2026-04-06>
#OP Vinculada ao PV (MasterMares -> PROC_INTEGRA_EnviarDocEntry_Producao)
ALTER TABLE tbintegraSAP_DocItem
ADD COLUMN DocEntryOrdemProducao VARCHAR(30) AFTER CFOPCode,
ADD COLUMN DocNumOrdemProducao VARCHAR(30) AFTER DocEntryOrdemProducao,
ADD COLUMN SerialOrdemProducao VARCHAR(30) AFTER DocNumOrdemProducao;






/**************************************************************************/
#David Ruy <2026-07-24>
#Melhoria nas Procedures EnviarDocEntry e EnviarDocEntryItem
#Atualizar statusDoc (liberar para processo) apenas quando qtde de 
#registros tbintegraSAP_DocItem = QtdeOriItens
ALTER TABLE tbintegraSAP_Doc
ADD  `QtdeOriItens` INT DEFAULT 0 AFTER DocTotal;




