DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_RetornoSaidaPicking`$$

CREATE PROCEDURE `PROC_INTEGRA_RetornoSaidaPicking`(
   IN oCodUsuario				VARCHAR(10),
   IN oIdRetorno				 VARCHAR(20),
   IN oTipoRetorno   INT     #0 = Criação de Picking no SAP (Criar Lista de Separação) 
   #                          2 = Criação de Picking no SAP (Criar Lista de Separação)  - Alterações  [desabilitado]
   #                          1 = Confirmação de Picking (Separação Confirmada)
   #                          3 = Confirmação de Picking (Transferencia)
   #                          4 = Confirmação Transferencia
   #                          5 = Confirmação Devolução Compras
)
BLOCO1:BEGIN
   /*******************************************************************************************
   #@Author David Ruy 
   #
   #@Reviser David Ruy <2019/12/11> Considerar apenas GMS´ com dthr_final_picking (Checkout concluído) Quando flg_conferencia_volume_check_tp=1
   #@Reviser David Ruy <2020/02/11> Regra para não considerar pedido com data de entrega no passado              
   #@Reviser David Ruy <2021/01/04> Regra para considerar flag flg_conferencia_volume_check_tp (checkout automático)
   #@Reviser David Ruy <2021/01/27> Flags para regras de retorno Checkout e Roteirização / Variáveis Limit e Ordem da Lista
   #@Reviser David Ruy <2021/01/28> Inclusão campos Transportadora / Rota / Janelas de Entrega
   #@Reviser David Ruy <2021/08/05> condição para não listar GSM´ canceladas / Incluído campo idPickingAnt
   #@Reviser David Ruy <2021/08/30> Campos WhareHouse e WhareHouseTransf (TD-S)
   #@Reviser David Ruy <2021/12/24> Campos ManBtchNum, ManSerNum
   #@Reviser David Ruy <2022/01/28> Tratativa campo U_RSD_RplOrder (não gera picking para PV com o campo preenchido)   
   #@Reviser David Ruy <2022-03-21> Retornar apenas as linhas que foram geradas no picking (tbintegraSAP_DocPicking)   
   #@Reviser David Ruy <2022-03-29> AND (tbintegraSAP_Doc.StatusDoc <= 3 OR tbintegraSAP_Doc.StatusDoc = 7) na condição para gerar picking
   #@Reviser David Ruy <2022-04-06> #Não retornar Quando houver divergencia entre itens ou quantidades do SLIN X Integração
   #@Reviser David Ruy <2022-04-20> #Ajuste para não gerar NADA se tiver bloqueado no SLIN
   #@Reviser David Ruy <2022-11-01> #confirmação de PV => Considerar apenas com Uitilização parametrizada
   #@Reviser David Ruy <2023-03-01> Alteração agrupamento linhas TD-S conforme flg_agrupa_transf
   #@Reviser David Ruy <2023/03/06> FatorAgrup e xflg_agrupa_transf para utilização Qtdes Agrupadas TD-S (Elinox)
   #@Reviser David Ruy <2023/04/24> Ajuste OP/TD-S X Não precisa Efetuar Checkout
   #@Reviser David Ruy <2023/04/25> Ajuste oTipoRetorno = 4 (Criar Documento Recebimento)
   #@Reviser David Ruy <2023/05/22> Ajuste Não Gerar retorno de Materiais de Uso/consumo (OONE_USO_CONS)
   #@Reviser David Ruy <2023/07/11> Ajuste xParamDiasEntrega : Só seleciona PV´ com data de entrega até X dias
                                    Ajusta para confirmação de PK até 30 dias passados da data PV
   #@Reviser David Ruy <2023/08/02> Ajuste xcampo_qtde_volumes (tbintegraSAP_Parametros.flg_campo_volumes => 0=CHECKOUT / 1=EMB_VOL / 2=STRING_CHECKOUT)
   #@Reviser David Ruy <2023/09/15> Novos campos qtde_volume_checkout -> QtdeVolManual, 
                                                 peso_liq_checkout -> PesoLiqManual,
                                                 peso_brt_checkout -> PesoBrtManual 
   #@Reviser David Ruy <2023-09-15> Regra Cromo, Não retornar se não tiver preenchido Qtde e Peso Checkout manual
   #@Reviser David Ruy <2023-10-11> <2025-12-23> tbintegraSAP_Doc.StatusEnum = 0 (em aberto para gerar Transferencia) / 1=Processado (Transferencia já gerada)
   #@Reviser David Ruy <2024-01-24> Regra BRW, [xcampo_qtde_volumes=3] Não retornar se não tiver preenchido Qtde e Peso Checkout manual e se checkout não concluído 
   #                                      conforme condição tbsolic_saidas_item.real_est2 = sum(ifnull(tbsolic_saidas_volume_item.qtde_sep_est, 0))
   #@Reviser David Ruy <2024-10-01> Ajuste, Condição para TD-S ao criar tbSaidas quando oTipoRetorno in (1,2,3,4)
   #@Reviser David Ruy <2024-11-18> Só processa o tbsolic_saidas_item_loteAux se qtde registros  > 0
   #@Reviser David Ruy <2024-12-16> Se OpenInvQty > 0 então, FatorConvSap = OpenInvQty / BaseQty, Caso contrário NumInSales
   #@Reviser David Ruy <2025-01-15> Não Gerar PK para DocTipo = 'DC'  Devolução de Compras / oTipoRetorno = 5 'DC'
   #@Reviser David Ruy <2025-12-17> Quando oTipoRetorno : considerar documentos com até 60 dias da data de inclusão   
   #@Reviser David Ruy <2025-07-21> Não utiliza mais Não utiliza mais tbsolic_saidas_item_loteAux
   #@Reviser David Ruy <2025-09-18> Desconsidera DocDate < 90 dias para retorno, retorna qualquer Doc com dthr_confirm até 30 dias
   #@Reviser David Ruy <2026-04-17> Add campos Ordem Produção : DocEntryOrdemProducao, DocNumOrdemProducao
   ********************************************************************************************/
   
   DECLARE xCodEmpWMS			      VARCHAR(03)	DEFAULT '001';
   DECLARE xCodFilWMS			      VARCHAR(03) DEFAULT '001';
   DECLARE xNumSolic 			      VARCHAR(10);
   DECLARE xAnoSolic 			      VARCHAR(04)	DEFAULT YEAR(CURRENT_DATE());
   DECLARE xDocEntry          INT;
   DECLARE xDocTipo           VARCHAR(10);   
   DECLARE xTipoOperSaida 		  VARCHAR(03) DEFAULT '002';
   DECLARE xCodUnidade			     VARCHAR(03) DEFAULT '001';
   DECLARE xCodArmazem			     VARCHAR(02) DEFAULT '01';
   DECLARE xStatusProcesso		  VARCHAR(02) DEFAULT '01';
   DECLARE xCodErro	          INT DEFAULT 0;
   DECLARE excecao 	          INT DEFAULT 0;
   DECLARE RESULTADO          INT DEFAULT 1;
   DECLARE MENSAGEM           VARCHAR(500);
   DECLARE xSTRGEM            TEXT;
   DECLARE xNumProcesso       VARCHAR(20);  
   DECLARE xflg_obriga_checkout_retornoPV TINYINT;
   DECLARE xflg_obriga_roteiriz_retornoPV TINYINT;
   DECLARE xOrdemLista        INT DEFAULT 0;  #0=Crescente / 1 = Decrescente
   DECLARE xQtdeRegistros     INT DEFAULT 0;
   DECLARE xflg_permite_PVParcial INT DEFAULT 0;
   DECLARE xutilizacao_saidas_retorno VARCHAR(200) DEFAULT NULL;
   DECLARE xflg_agrupa_transf TINYINT;
   DECLARE xemb_faturamento   VARCHAR(50);
   DECLARE xcampo_qtde_volumes TINYINT;
   DECLARE xParamDiasEntrega   INT DEFAULT 180;
   
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   
   
   #@Reviser David Ruy <2022-11-01>
   SELECT flg_permite_PVParcial, flg_obriga_checkout_retornoPV, flg_obriga_roteiriz_retornoPV, utilizacao_saidas_retorno,
          flg_agrupa_transf, IFNULL(emb_faturamento,"Volumes"), flg_campo_volumes
   INTO xflg_permite_PVParcial, xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV, xutilizacao_saidas_retorno,
        xflg_agrupa_transf, xemb_faturamento, xcampo_qtde_volumes
   FROM tbintegraSAP_parametros
   LIMIT 1;
   
   
   #Cria tabela temporária com as GSM recebidas que serão separadas
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
   IF IFNULL(oIdRetorno,'') = '' THEN
   
      IF oTipoRetorno = 0 THEN
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
            SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic, tbintegraSAP_Doc.BPLId
                  ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
                  ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
                  ,tbSaidas.status_processo, tbSaidas.observ_solic 
                  ,tbwmsTipoOper.tipo_movto, tbwmsTipoOper.cod_oper_wms
            FROM tbintegraSAP_Doc
            INNER JOIN tbintegraSAP_empresas ON 
                       tbintegraSAP_empresas.id_integracao = IFNULL(tbintegraSAP_Doc.BPLId,1)
            LEFT JOIN of_logistica.tbsolic_saidas tbSaidas ON
                  tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
              AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
              AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
              AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
            LEFT JOIN of_logistica.tbsys_integracao_estoque tbwmsIntegraEstoque ON 
                     tbwmsIntegraEstoque.chave_integracao = tbintegraSAP_Doc.DocTipo
                 AND tbwmsIntegraEstoque.cod_emp = tbintegraSAP_empresas.cod_emp_slin
                 AND tbwmsIntegraEstoque.cod_fil = tbintegraSAP_empresas.cod_fil_slin
            LEFT JOIN of_logistica.tbwms_tipo_oper tbwmsTipoOper ON 
                     tbwmsTipoOper.cod_oper_wms = tbwmsIntegraEstoque.cod_oper_wms
            WHERE tbwmsTipoOper.tipo_movto = 'S'
              AND tbintegraSAP_Doc.IdPicking IS NULL
              AND tbSaidas.dthr_cancelamento IS NULL
              AND (tbintegraSAP_Doc.StatusDoc <= 3 OR tbintegraSAP_Doc.StatusDoc = 7)
              AND (tbSaidas.dthr_bloqueio_ini IS NULL OR (tbSaidas.dthr_bloqueio_ini IS NOT NULL AND tbSaidas.dthr_bloqueio_fin IS NOT NULL))
              AND tbintegraSAP_Doc.dthr_inc >= DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
              AND tbintegraSAP_Doc.DueDate <= DATE_ADD(CURRENT_DATE(), INTERVAL xParamDiasEntrega DAY)
              #@Reviser David Ruy <2025-01-15> Não gerar PK para DC
              AND tbintegraSAP_Doc.DocTipo NOT IN ('DC') 
              #AND IF(oTipoRetorno=0, tbSaidas.cod_emp IS NULL, tbSaidas.cod_emp IS NOT NULL)
              #@Reviser David Ruy <2020/02/11> Regra para não considerar pedido com data de entrega no passado              
              #@Reviser David Ruy <2020/03/26> pedido com entrega no passado mas que já foi separado pode retornar
          #AND IF(tbintegraSAP_Doc.idPickingAnt IS NULL, DATE(tbintegraSAP_Doc.DueDate) >= CURRENT_DATE(), TRUE)
              ;#AND (tbintegraSAP_Doc.U_RSD_RplOrder IS NULL OR
               #   (tbintegraSAP_Doc.U_RSD_RplOrder IS NOT NULL AND tbintegraSAP_Doc.cod_emp IS NOT NULL));
               
         #Ordena Ascendente ou Descendente
         DROP TEMPORARY TABLE IF EXISTS tbTMPX;
         IF xOrdemLista = 0 THEN
            CREATE TEMPORARY TABLE tbTMPX AS
               SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY data_solic;
         ELSE
            CREATE TEMPORARY TABLE tbTMPX AS
               SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY data_solic DESC;
         END IF;
                       
         #Força ficar apenas 10 Registros;
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
         IF xQtdeRegistros = 0 THEN
            INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX;
         ELSE
            INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX LIMIT xQtdeRegistros;
         END IF;
         DROP TEMPORARY TABLE IF EXISTS tbTMPX;      
         
         #select * from tbTMP_INTEGRA_RETORNO_SAIDAS ;         
         #Leave Bloco1;
               
              
      ELSE
      
         DROP TEMPORARY TABLE IF EXISTS tbSaidas;
         CREATE TEMPORARY TABLE tbSaidas
            SELECT tbSaidas.* FROM of_logistica.tbsolic_saidas tbSaidas
            INNER JOIN tbintegraSAP_Doc ON 
                       tbintegraSAP_Doc.chave_integracao = tbSaidas.chave_integracao
            WHERE tbSaidas.status_processo >= 8
              AND tbSaidas.dthr_cancelamento IS NULL
              AND tbSaidas.dthr_retorno_integracao IS NULL
              AND tbSaidas.dthr_confirm >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
              AND IF(xflg_obriga_checkout_retornoPV = 1, dthr_final_picking IS NOT NULL, TRUE)
              AND tbSaidas.chave_integracao IS NOT NULL
              AND IF(oTipoRetorno=4, tbintegraSAP_Doc.StatusDoc = 6 AND tbintegraSAP_Doc.StatusEnum = 0, tbintegraSAP_Doc.StatusDoc = 3)              
            ORDER BY tbSaidas.dthr_confirm DESC
            LIMIT 100
            ;
         ALTER TABLE tbSaidas ADD PRIMARY KEY (chave_integracao);
         #select * from tbSaidas; leave Bloco1; 
          
         DROP TEMPORARY TABLE IF EXISTS tbSaidasVolItem;
         CREATE TEMPORARY TABLE tbSaidasVolItem
            SELECT tbSaidasVolItem.* FROM of_logistica.tbsolic_saidas_volume_item tbSaidasVolItem
            INNER JOIN tbSaidas ON 
                              tbSaidasVolItem.cod_emp   = tbSaidas.cod_emp 
                          AND tbSaidasVolItem.cod_fil   = tbSaidas.cod_fil
                          AND tbSaidasVolItem.ano_solic = tbSaidas.ano_solic
                          AND tbSaidasVolItem.num_solic = tbSaidas.num_solic;
                          
         DROP TEMPORARY TABLE IF EXISTS tbSaidasItem;
         CREATE TEMPORARY TABLE tbSaidasItem
            SELECT tbSaidasItem.* FROM of_logistica.tbsolic_saidas_item tbSaidasItem
            INNER JOIN tbSaidas ON 
                              tbSaidasItem.cod_emp   = tbSaidas.cod_emp 
                          AND tbSaidasItem.cod_fil   = tbSaidas.cod_fil
                          AND tbSaidasItem.ano_solic = tbSaidas.ano_solic
                          AND tbSaidasItem.num_solic = tbSaidas.num_solic;
                   
         CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
            SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic, tbintegraSAP_Doc.BPLId
                  ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
                  ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
                  ,tbSaidas.status_processo, tbSaidas.observ_solic 
                  ,tbSaidas.flg_producao
                  ,tbSaidas.dthr_final_picking 
                  ,tbSaidas.dthr_confirm
                  ,tbEstCli.flg_conferencia_volume_check_tp
                  #
                  
                  #,(SELECT SUM(qtde_sep_est) FROM of_logistica.tbsolic_saidas_volume_item Item
                  ,(SELECT SUM(qtde_sep_est) FROM tbSaidasVolItem Item
                    WHERE Item.cod_emp   = tbSaidas.cod_emp
                      AND Item.cod_fil   = tbSaidas.cod_fil
                      AND Item.ano_solic = tbSaidas.ano_solic
                      AND Item.num_solic = tbSaidas.num_solic) AS QtdeCheckout 
                  #,(SELECT SUM(real_est2) FROM of_logistica.tbsolic_saidas_item Item
                  ,(SELECT SUM(real_est2) FROM tbSaidasItem Item
                    WHERE Item.cod_emp = tbSaidas.cod_emp
                      AND Item.cod_fil = tbSaidas.cod_fil
                      AND Item.ano_solic = tbSaidas.ano_solic
                      AND Item.num_solic = tbSaidas.num_solic) AS QtdeSep
                  #
            FROM tbintegraSAP_Doc
            #INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
            INNER JOIN tbSaidas ON
                  tbSaidas.chave_integracao = tbintegraSAP_Doc.chave_integracao 
              #    tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
              #AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
              #AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
              #AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
              AND tbSaidas.status_processo >= 8
              AND tbSaidas.dthr_cancelamento IS NULL
              AND (tbSaidas.dthr_bloqueio_ini IS NULL OR (tbSaidas.dthr_bloqueio_ini IS NOT NULL AND tbSaidas.dthr_bloqueio_fin IS NOT NULL))              
            INNER JOIN of_logistica.tbwms_estoque_cli tbEstCli ON 
                       tbEstCli.cod_emp      = tbSaidas.cod_emp
                   AND tbEstCli.cod_fil      = tbSaidas.cod_fil
                   AND tbEstCli.cnpj_cpf_cli = tbSaidas.cnpj_cpf_cli
                   AND tbEstCli.cod_estoque  = tbSaidas.cod_estoque
            WHERE tbintegraSAP_Doc.TipoDocSLIN = 'S'
              AND IF(oTipoRetorno=4, tbintegraSAP_Doc.StatusDoc = 6 AND tbintegraSAP_Doc.StatusEnum = 0, tbintegraSAP_Doc.StatusDoc = 3)
              # Só retorna depois de checkout (exceto para Ordem Produção)
              #AND IF(tbSaidas.flg_producao='S', TRUE, 
              #       tbSaidas.dthr_final_picking IS NOT NULL)
              AND tbintegraSAP_Doc.IdPicking IS NOT NULL
              AND IF(oTipoRetorno=1,tbintegraSAP_Doc.DocTipo IN ('PV','OP','NS'), 
                     IF(oTipoRetorno=4,tbintegraSAP_Doc.DocTipo IN ('TD-S'), 
                        IF(oTipoRetorno=5,tbintegraSAP_Doc.DocTipo IN ('DC'), 
                           FALSE
                        )
                     )
                  )
              #AND tbintegraSAP_Doc.DocDate >= DATE_ADD(CURRENT_DATE(), INTERVAL -90 DAY)
              AND tbSaidas.dthr_confirm >= DATE_ADD(CURRENT_DATE(), INTERVAL -30 DAY)
              #@Reviser David Ruy <2023-09-15> Regra Cromo, Não retornar se não tiver preenchido Qtde e Peso Checkout manual
              AND IF(xcampo_qtde_volumes IN (2,3), IFNULL(tbSaidas.qtde_volume_checkout,0) > 0, TRUE)
              AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_liq_checkout,0) > 0, TRUE)  
              AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_brt_checkout,0) > 0, TRUE)
                      #AND tbintegraSAP_Doc.DocNum = 159381
              #ORDER BY tbSaidas.dthr_confirm DESC
              LIMIT 100    #(utilizar LIMIT quando consulta estourar o tempo DO processamento)
              ; 
                      
	      DROP TEMPORARY TABLE IF EXISTS tbSaidas;
	      DROP TEMPORARY TABLE IF EXISTS tbSaidasVolItem;
	      DROP TEMPORARY TABLE IF EXISTS tbSaidasItem;
	      
	      
         #Update (como retornado) para PV´ com utilização diferente da parametrizada
         IF IFNULL(xutilizacao_saidas_retorno,'') <> '' THEN
            UPDATE tbintegraSAP_Doc
            INNER JOIN tbTMP_INTEGRA_RETORNO_SAIDAS ON
                       tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo  = tbintegraSAP_Doc.DocTipo
                   AND tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry = tbintegraSAP_Doc.DocEntry
                   AND tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum   = tbintegraSAP_Doc.DocNum
            SET StatusAnt = StatusDoc,
                StatusDoc = 6
            #where LOCATE(tbintegraSAP_Doc.MainUsage,xutilizacao_saidas_retorno) = 0);
            WHERE EXISTS (SELECT 1 FROM tbintegraSAP_DocItem
                          WHERE tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
                            AND tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
                            AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
                            AND LOCATE(IFNULL(tbintegraSAP_DocItem.Usage_,'XXX'),xutilizacao_saidas_retorno) = 0);
            DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS 
            WHERE EXISTS (SELECT 1 FROM tbintegraSAP_Doc
                          WHERE tbintegraSAP_Doc.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
                            AND tbintegraSAP_Doc.DocEntry  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
                            AND tbintegraSAP_Doc.DocNum = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
                            AND StatusDoc = 6);
         END IF;
               
      END IF;
      
   ELSE
   
      SET xCodEmpWMS	= SUBSTRING(oIdRetorno,01,03);
      SET xCodFilWMS	= SUBSTRING(oIdRetorno,04,03);
      SET xAnoSolic 	= SUBSTRING(oIdRetorno,07,04);
      SET xNumSolic 	= SUBSTRING(oIdRetorno,11,10);    
      SET xSTRGEM = CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|");
      #select xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic;
      /*******************************************************************
      # Validar a existencia da GSM
      *******************************************************************/
      IF NOT EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas 
                     WHERE cod_emp = xCodEmpWMS
                     AND cod_fil = xCodFilWMS
                     AND ano_solic = xAnoSolic
                     AND num_solic = xNumSolic) THEN
         SET xCodErro = 1;
         SET RESULTADO = 0;
         SET MENSAGEM  = 'GSM não localizada';
         SELECT RESULTADO, MENSAGEM;
         LEAVE BLOCO1;
      END IF;
      CREATE TEMPORARY TABLE tbTMP_INTEGRA_RETORNO_SAIDAS AS 
         SELECT DocEntry, DocTipo, DocNum, tbSaidas.num_nf, tbSaidas.data_nf, tbSaidas.data_solic
               ,CONCAT(tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic) NumProcesso
               ,tbSaidas.cod_emp, tbSaidas.cod_fil, tbSaidas.ano_solic, tbSaidas.num_solic
               ,tbSaidas.status_processo, tbSaidas.observ_solic 
         FROM tbintegraSAP_Doc
         INNER JOIN of_logistica.tbsolic_saidas tbSaidas ON
               tbSaidas.cod_emp   = tbintegraSAP_Doc.cod_emp
           AND tbSaidas.cod_fil   = tbintegraSAP_Doc.cod_fil
           AND tbSaidas.ano_solic = tbintegraSAP_Doc.ano_solic
           AND tbSaidas.num_solic = tbintegraSAP_Doc.num_solic
           AND IF(oTipoRetorno = 0, tbSaidas.status_processo = 1, tbSaidas.status_processo >= 8)
           AND IF(oTipoRetorno = 0, tbintegraSAP_Doc.StatusDoc BETWEEN 2 AND 3, tbintegraSAP_Doc.StatusDoc = 5)
         WHERE tbintegraSAP_Doc.cod_emp   = xCodEmpWMS 
           AND tbintegraSAP_Doc.cod_fil   = xCodFilWMS
           AND tbintegraSAP_Doc.ano_solic = xAnoSolic
           AND tbintegraSAP_Doc.num_solic = xNumSolic
           AND tbintegraSAP_Doc.TipoDocSLIN = 'S'
           AND IF(tbSaidas.flg_producao='S', TRUE, tbSaidas.dthr_final_picking IS NOT NULL)
           AND IF(oTipoRetorno = 0, tbintegraSAP_Doc.IdPicking IS NULL, tbintegraSAP_Doc.IdPicking IS NOT NULL)
           #@Reviser David Ruy <2020/02/11> Regra para não considerar pedido com data de entrega no passado
           AND IF(oTipoRetorno = 0, DATE(tbintegraSAP_Doc.DueDate) >= CURRENT_DATE(), TRUE)
           #@Reviser David Ruy <2023-09-15> Regra Cromo, Não retornar se não tiver preenchido Qtde e Peso Checkout manual
           AND IF(xcampo_qtde_volumes IN (2,3), IFNULL(tbSaidas.qtde_volume_checkout,0) > 0, TRUE)
           AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_liq_checkout,0) > 0, TRUE)  
           AND IF(xcampo_qtde_volumes IN (2), IFNULL(tbSaidas.peso_brt_checkout,0) > 0, TRUE);           
   END IF;
   
   
   
   IF (oTipoRetorno IN (1,3,5)) THEN
      #SELECT flg_obriga_checkout_retornoPV, flg_obriga_roteiriz_retornoPV
      #INTO xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV
      #FROM tbintegraSAP_parametros LIMIT 1;
      
           
      #Desconsidera GSM´s que não são de produção e que flg_conferencia_volume_check_tp = 1
      #e que não concluiu o checkout
      IF xflg_obriga_checkout_retornoPV = 1 THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         #WHERE flg_producao = 'N'
         WHERE flg_producao = 'N' AND DocTipo NOT IN ('OP','TD-S') 
           AND flg_conferencia_volume_check_tp = 1
           AND dthr_final_picking IS NULL;
         #select "Aqui", row_count();  LEAVE BLOCO1;
      END IF;
      #select * from tbTMP_INTEGRA_RETORNO_SAIDAS;
             
      #Ordem de Produção não depende de checkout
      UPDATE tbTMP_INTEGRA_RETORNO_SAIDAS
      SET QtdeCheckout = QtdeSep
      WHERE QtdeCheckout IS NULL
        AND DocTipo IN ('OP','TD-S');
        
        
      #Desconsidera GSM´s com Checkout não Realizado quando flg_conferencia_volume_check_tp = 2
      IF xflg_obriga_checkout_retornoPV = 1 THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         WHERE flg_producao = 'N'
           AND flg_conferencia_volume_check_tp = 2
           AND (IFNULL(QtdeSep,0) = 0 
           OR IFNULL(QtdeCheckout,0) < IFNULL(QtdeSep,0));
         #SELECT "Aqui2", ROW_COUNT();  LEAVE BLOCO1;
      END IF;
      
      
      #Não considerar retorno se o checkout não estiver concluido
      IF xcampo_qtde_volumes IN (2,3) THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         WHERE flg_producao = 'N'
           AND (IFNULL(QtdeSep,0) = 0 
           OR IFNULL(QtdeCheckout,0) < IFNULL(QtdeSep,0));
         #SELECT "Aqui2", ROW_COUNT();  LEAVE BLOCO1;
      END IF;
	#SELECT xflg_permite_PVParcial, xflg_obriga_checkout_retornoPV, xflg_obriga_roteiriz_retornoPV, xutilizacao_saidas_retorno,
	#xflg_agrupa_transf, xemb_faturamento, xcampo_qtde_volumes;
	#SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
	#LEAVE BLOCO1;
           
                    
      #Desconsidera GSM´s Pedido em viagem Não Confirmada
      IF xflg_obriga_roteiriz_retornoPV = 1 THEN
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         WHERE flg_producao = 'N'
           AND flg_conferencia_volume_check_tp = 2
           AND EXISTS (SELECT NumProcesso, tbViagens.num_viagem
                       FROM of_logistica.tbsolic_saidas_item tbItem 
                       LEFT JOIN of_logistica.tbprog_entregas tbEntregas ON 
                                 tbEntregas.cod_emp      = tbItem.cod_emp_pedido
                             AND tbEntregas.cod_fil      = tbItem.cod_fil_pedido
                             AND tbEntregas.cnpj_cpf_cli = tbItem.cnpj_cpf_cli
                             AND tbEntregas.num_nf_cli   = tbItem.num_ped_cli
                       LEFT JOIN of_logistica.tbviagens tbViagens ON 
                                 tbViagens.cod_emp    = tbEntregas.cod_emp 
                             AND tbViagens.cod_fil    = tbEntregas.cod_fil
                             AND tbViagens.ano_viagem = tbEntregas.ano_viagem 
                             AND tbViagens.num_viagem = tbEntregas.num_viagem
                       WHERE tbItem.cod_emp   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp 
                         AND tbItem.cod_fil   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil
                         AND tbItem.ano_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic 
                         AND tbItem.num_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic
                         AND tbViagens.data_conf IS NULL
                       GROUP BY NumProcesso);
         #SELECT "Aqui3", ROW_COUNT();  LEAVE BLOCO1;
         
         #@Reviser David Ruy <2022-04-06>
         #Não retornar Quando houver divergencia entre itens ou quantidades do SLIN X Integração
         IF xflg_permite_PVParcial = 0 THEN
            DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
            WHERE EXISTS
                  (SELECT SUM(tbItemSLIN.real_est2) TotalSlin, COUNT(tbItemSLIN.num_item) QtdeSlin, 
                          SUM(IFNULL(tbItem.OpenInvQty,tbItem.BaseQty)) TotalDoc, COUNT(tbItem.LineNum) QtdeDoc
                   FROM tbintegraSAP_DocItem tbItem 
                   LEFT JOIN of_logistica.tbsolic_saidas_item tbItemSLIN ON
                             tbItemSLIN.cod_emp   = tbItem.cod_emp 
                         AND tbItemSLIN.cod_fil   = tbItem.cod_fil
                         AND tbItemSLIN.ano_solic = tbItem.ano_solic
                         AND tbItemSLIN.num_solic = tbItem.num_solic
                         AND tbItemSLIN.num_item  = tbItem.num_item
                   WHERE tbItem.cod_emp   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp 
                     AND tbItem.cod_fil   = tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil
                     AND tbItem.ano_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic 
                     AND tbItem.num_solic = tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic
                     AND tbItem.StatusItem <> 9
                   HAVING TotalSlin <> TotalDoc OR QtdeSlin <> QtdeDoc);
         END IF;
         
         
         
      END IF;
      
      
      #Ordena Ascendente ou Descendente
      DROP TEMPORARY TABLE IF EXISTS tbTMPX;
      IF xOrdemLista = 0 THEN
         CREATE TEMPORARY TABLE tbTMPX AS
            SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY dthr_confirm;
      ELSE
         CREATE TEMPORARY TABLE tbTMPX AS
            SELECT * FROM tbTMP_INTEGRA_RETORNO_SAIDAS ORDER BY dthr_confirm DESC;
      END IF;
                    
      #Força ficar apenas 10 Registros;
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS;
      IF xQtdeRegistros = 0 THEN
         INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX;
      ELSE
         INSERT INTO tbTMP_INTEGRA_RETORNO_SAIDAS SELECT * FROM tbTMPX LIMIT xQtdeRegistros;
      END IF;
      DROP TEMPORARY TABLE IF EXISTS tbTMPX;
      
   END IF;
   
   
   IF oTipoRetorno = 1 THEN  
      #Não Gerar retorno de Materiais de Uso/consumo
      DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      WHERE (SELECT COUNT(*) FROM tbintegraSAP_DocItem
                    WHERE tbintegraSAP_DocItem.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
                      AND tbintegraSAP_DocItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
                      AND tbintegraSAP_DocItem.OONE_USO_CONS = 1);
  END IF;
   
   
   
   IF oTipoRetorno = 0 THEN
   /*******************************************************************
      # Selecionar as informações da GSM
      *******************************************************************/
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry, tbTMP_INTEGRA_RETORNO_SAIDAS.Doctipo, tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum, 
             tbTMP_INTEGRA_RETORNO_SAIDAS.BPLId, 
             tbintegraSAP_Doc.IdPicking, tbintegraSAP_Doc.idPickingAnt,
             topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
             
             #Soma das Qtdes por Item
            (SELECT COUNT(tbItem.LineNum) QtdeSAP
             FROM tbintegraSAP_DocItem tbItem 
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) QtdeSAP,
            (SELECT COUNT(tbItemSLIN.num_item) TotalSlin
             FROM tbintegraSAP_DocItem tbItem 
             LEFT JOIN of_logistica.tbsolic_saidas_item tbItemSLIN ON
                       tbItemSLIN.cod_emp   = tbItem.cod_emp 
                   AND tbItemSLIN.cod_fil   = tbItem.cod_fil
                   AND tbItemSLIN.ano_solic = tbItem.ano_solic
                   AND tbItemSLIN.num_solic = tbItem.num_solic
                   AND tbItemSLIN.num_item  = tbItem.num_item
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) QtdeSlin,
               
             #Contabiliza Qtde de Itens
            (SELECT SUM(IFNULL(tbItem.OpenInvQty,tbItem.BaseQty)) TotalSAP
             FROM tbintegraSAP_DocItem tbItem 
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) TotalSAP,
            (SELECT SUM(tbItemSLIN.real_est) TotalSlin
             FROM tbintegraSAP_DocItem tbItem 
             LEFT JOIN of_logistica.tbsolic_saidas_item tbItemSLIN ON
                       tbItemSLIN.cod_emp   = tbItem.cod_emp 
                   AND tbItemSLIN.cod_fil   = tbItem.cod_fil
                   AND tbItemSLIN.ano_solic = tbItem.ano_solic
                   AND tbItemSLIN.num_solic = tbItem.num_solic
                   AND tbItemSLIN.num_item  = tbItem.num_item
             WHERE tbItem.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbItem.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbItem.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
               AND IFNULL(tbItem.StatusItem,0) <> 9) TotalSlin,
             
             topo.data_solic, IFNULL(topo.data_saida,tbintegraSAP_Doc.DueDate) data_saida, topo.dthr_acons, 
             IFNULL(topo.num_nf, CONCAT(tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo,tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum)) AS num_pedido,
             topo.observ_solic, topo.observ_conf01, topo.status_processo, 
             of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux,
             #Liberação Inicio Processo de Separação, Picking
             topo.dthr_armazem, topo.dthr_armazem_picking, topo.dthr_confer, topo.dthr_confirm,
             #Inicio Processo de Separação, Picking
             topo.dthr_inicio_geral, topo.dthr_inicio_picking, topo.dthr_inicio_carregamento
            ,IFNULL(topo.chave_integracao, CONCAT(tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo,tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum,'-',tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry)) chave_integracao
            ,RESULTADO, MENSAGEM
      FROM tbTMP_INTEGRA_RETORNO_SAIDAS
      INNER JOIN tbintegraSAP_Doc ON 
                tbintegraSAP_Doc.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
            AND tbintegraSAP_Doc.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
            AND tbintegraSAP_Doc.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
      LEFT JOIN of_logistica.tbsolic_saidas topo ON
            tbTMP_INTEGRA_RETORNO_SAIDAS.cod_emp = topo.cod_emp
            AND tbTMP_INTEGRA_RETORNO_SAIDAS.cod_fil = topo.cod_fil
            AND tbTMP_INTEGRA_RETORNO_SAIDAS.ano_solic = topo.ano_solic
            AND tbTMP_INTEGRA_RETORNO_SAIDAS.num_solic = topo.num_solic;
   
      # INFORMAÇÕES DOS ITENS DA GSM
         SELECT tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry, tbTMP_INTEGRA_RETORNO_SAIDAS.Doctipo, tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum, 
               tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao,
               xflg_permite_PVParcial,  #@Reviser David Ruy <2022-04-04>
               #IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale) AS FatorConvSAP,
               #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               #IF(IFNULL(prod.fator_conv_vendas,0)=0,1,prod.fator_conv_vendas) AS FatorConvSAP,
               IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
                 tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale))  AS FatorConvSAP,               
               #prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,
               tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
               topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, 
               IFNULL(ite.num_ped_cli, CONCAT(tbintegraSAP_DocItem.DocTipo, tbintegraSAP_DocItem.DocNum)) num_ped_cli, ite.num_item, 
               IFNULL(ite.cod_produto, tbintegraSAP_DocItem.ItemCode) cod_produto, 
               IFNULL(descr_produto, tbintegraSAP_DocItem.description) AS descr_prod,
               IFNULL(ite.emb_est, tbintegraSAP_DocItem.invntryUom) AS emb_est, 
               ite.emb_frac, ite.emb_vol,ite.fator_conv AS fator_conv,
               #
               ite.local_geral, ite.local_picking,
               IFNULL(ite.qtde_est, tbintegraSAP_DocItem.BaseQty) qtde_est , ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
               ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
               #@Reviser David Ruy <2020/04/29>
               #Se tiver alteração em andamento, envia a nova quantidade
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_est_atu ,ite.real_est2) real_est2,
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_vol_atu ,ite.real_vol2) real_vol2,
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_frac_atu ,ite.real_frac2) real_frac2,
               IF(tbAlt.cod_emp IS NOT NULL, tbAlt.qtde_peso_atu ,ite.real_peso2) real_peso2,
               #ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separação
               #
               ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / Picking
               #
               ite.real_est4, ite.real_vol4, ite.real_frac4, ite.real_peso4,	#Qtde Carregamento
               ite.real_est5, ite.real_vol5, ite.real_frac5, ite.real_peso5,	#Qtde check-carregamento
               #			
               ite.dthr_aconselhamento, ite.dthr_retorno_wms,
               ite.dthr_inicio_baixa_geral, ite.dthr_inicio_picking_carga, ite.dthr_inicio_carregamento,
               ite.dthr_final_baixa_geral, ite.dthr_final_picking_carga, ite.dthr_final_carregamento		
               ,IFNULL(topo.chave_integracao, CONCAT(tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo,tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum,'-',tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry)) chave_integracao
               ,prod.flg_obriga_lote_fornecedor
               ,IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf
               ,tbintegraSAP_DocItem.BaseQty / (SELECT SUM(tbDocItem.BaseQty) FROM tbintegraSAP_DocItem tbDocItem
                     WHERE tbintegraSAP_DocItem.DocTipo = tbDocItem.DocTipo
                       AND tbintegraSAP_DocItem.DocEntry = tbDocItem.DocEntry
                       AND tbintegraSAP_DocItem.ItemCode = tbDocItem.ItemCode
                     ) AS FatorAgrup
               ,RESULTADO, MENSAGEM
         FROM tbTMP_INTEGRA_RETORNO_SAIDAS
         INNER JOIN tbintegraSAP_Doc ON 
                   tbintegraSAP_Doc.DocEntry = tbTMP_INTEGRA_RETORNO_SAIDAS.DocEntry
               AND tbintegraSAP_Doc.DocTipo  = tbTMP_INTEGRA_RETORNO_SAIDAS.DocTipo
               AND tbintegraSAP_Doc.DocNum   = tbTMP_INTEGRA_RETORNO_SAIDAS.DocNum
         INNER JOIN tbintegraSAP_empresas ON 
                    tbintegraSAP_empresas.id_integracao = IFNULL(tbintegraSAP_Doc.BPLId,1)
         LEFT JOIN tbintegraSAP_DocItem ON 
                   tbintegraSAP_DocItem.DocEntry = tbintegraSAP_Doc.DocEntry
               AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
               AND tbintegraSAP_DocItem.DocNum   = tbintegraSAP_Doc.DocNum
         INNER JOIN of_logistica.tbsys_integracao_estoque tbwmsIntegracaoEstoque ON 
                     tbwmsIntegracaoEstoque.chave_integracao = tbintegraSAP_Doc.DocTipo
                 AND tbwmsIntegracaoEstoque.cod_emp  = tbintegraSAP_empresas.cod_emp_slin
                 AND tbwmsIntegracaoEstoque.cod_fil  = tbintegraSAP_empresas.cod_fil_slin
         #INNER JOIN of_logistica.tbwms_tipo_oper tbwmsTipoOper ON 
         #            tbwmsTipoOper.cod_oper_wms = tbwmsIntegracaoEstoque.cod_oper_wms
         #        AND tbwmsTipoOper.tipo_movto = 'S'
         LEFT JOIN of_logistica.tbsolic_saidas topo ON 
                   tbintegraSAP_Doc.cod_emp = topo.cod_emp
               AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
               AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
               AND tbintegraSAP_Doc.num_solic = topo.num_solic
         LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
                   ite.cod_emp = tbintegraSAP_DocItem.cod_emp
               AND ite.cod_fil = tbintegraSAP_DocItem.cod_fil
               AND ite.ano_solic = tbintegraSAP_DocItem.ano_solic
               AND ite.num_solic = tbintegraSAP_DocItem.num_solic
               AND ite.num_item  = tbintegraSAP_DocItem.num_item
         LEFT JOIN of_logistica.tbsolic_saidas_item_integra_alteracao tbAlt ON
                   ite.cod_emp   = tbAlt.cod_emp
               AND ite.cod_fil   = tbAlt.cod_fil
               AND ite.ano_solic = tbAlt.ano_solic
               AND ite.num_solic = tbAlt.num_solic
               AND ite.num_item  = tbAlt.num_item
               AND tbAlt.dthr_realizado IS NULL
         LEFT JOIN of_logistica.tbprodutos prod ON
                   prod.cnpj_cpf = tbwmsIntegracaoEstoque.cnpj_cpf_cli
               AND prod.cod_produto = tbintegraSAP_DocItem.ItemCode
         WHERE IF(ite.cod_emp IS NOT NULL, ite.qtde_nf > 0,  TRUE)
         #@Reviser David Ruy <2021/01/05> Considerar apenas itens não cancelados=>(status=9)
           AND (IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2)
         ORDER BY DocEntry, Doctipo, DocNum, tbintegraSAP_DocItem.LineNum;
   
   ELSEIF oTipoRetorno IN (1,3,4,5) THEN
   
      #Alimenta variavel xSTRGEM com a lista das GSM´s selecionadas
      SET xSTRGEM = '';  
      WHILE EXISTS (SELECT 1 FROM tbTMP_INTEGRA_RETORNO_SAIDAS) DO
         SELECT NumProcesso, cod_emp, cod_fil, ano_solic, num_solic, DocEntry, Doctipo
         INTO xNumProcesso, xCodEmpWMS, xCodFilWMS, xAnoSolic, xNumSolic, xDocEntry, xDoctipo
         FROM tbTMP_INTEGRA_RETORNO_SAIDAS LIMIT 1;         
         
         SET xSTRGEM = CONCAT(xSTRGEM, CONCAT(xCodEmpWMS, "|", xCodFilWMS, "|", xAnoSolic, "|", xNumSolic, "|", xDocEntry, "|"), xDocTipo, "|");
         DELETE FROM tbTMP_INTEGRA_RETORNO_SAIDAS WHERE NumProcesso = xNumProcesso;
      END WHILE;
      
      #Cria tabela temporária auxiliar para inner join com a tbsolic_entradas para gerar seleção das informações
      #da GEM informada no parametro
      CALL PROC_SYS_GerarTabelaComTexto(xSTRGEM,'|',6);        
   
   
   #select * from tTabelaComTexto; #2024-11-14
   #       LEAVE bloco1;   
      /*****************************************************************************/
      #Tabelas Temporarias para Volumes
      /*****************************************************************************/
      SELECT NOW() INTO @Time0;
       
      #Nova tabela Temporária Volumes
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes;
      CREATE TEMPORARY TABLE tbTMPVolumes (
          cod_emp VARCHAR(03), cod_fil VARCHAR(03), ano_solic VARCHAR(04), 
          num_solic VARCHAR(10), num_item VARCHAR(06), id_volume_saida INT,
          qtde_sep_est DECIMAL(18,6),
          INDEX (id_volume_saida)
      );
      #Tabela Gêmea para utilização em 2 campos distintos
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes2;
      CREATE TEMPORARY TABLE tbTMPVolumes2 (
          cod_emp VARCHAR(03), cod_fil VARCHAR(03), ano_solic VARCHAR(04), 
          num_solic VARCHAR(10), num_item VARCHAR(06), id_volume_saida INT,
          qtde_sep_est DECIMAL(18,6),
          INDEX (id_volume_saida)
      );
      
      
       INSERT INTO tbTMPVolumes       
       (   
          SELECT tbsolic_saidas_volume_item.cod_emp, tbsolic_saidas_volume_item.cod_fil, 
                 tbsolic_saidas_volume_item.ano_solic, tbsolic_saidas_volume_item.num_solic, 
                 tbsolic_saidas_volume_item.num_item, tbsolic_saidas_volume_item.id_volume_saida,
                 tbsolic_saidas_volume_item.qtde_sep_est
          FROM of_logistica.tbsolic_saidas_volume_item
          INNER JOIN tTabelaComTexto ON
                tTabelaComTexto.Coluna01 = tbsolic_saidas_volume_item.cod_emp
                AND tTabelaComTexto.Coluna02 = tbsolic_saidas_volume_item.cod_fil
                AND tTabelaComTexto.Coluna03 = tbsolic_saidas_volume_item.ano_solic
                AND tTabelaComTexto.Coluna04 = tbsolic_saidas_volume_item.num_solic
          #WHERE tbsolic_saidas_volume.id_volume_saida = tbsolic_saidas_volume_item.id_volume_saida;
       );
       INSERT INTO tbTMPVolumes2 (SELECT * FROM tbTMPVolumes);
      DROP TEMPORARY TABLE IF EXISTS tbTMPPesosInsumos;
      CREATE TEMPORARY TABLE tbTMPPesosInsumos (
         SELECT tbTMPVolumes.cod_emp, tbTMPVolumes.cod_fil, 
                tbTMPVolumes.ano_solic, tbTMPVolumes.num_solic, 
                SUM(IFNULL(peso_bruto_insumo,0)) PesoInsumos
         FROM of_logistica.tbsolic_saidas_volume
         INNER JOIN tbTMPVolumes ON tbsolic_saidas_volume.id_volume_saida = tbTMPVolumes.id_volume_saida 
         GROUP BY tbTMPVolumes.cod_emp, tbTMPVolumes.cod_fil, 
                  tbTMPVolumes.ano_solic, tbTMPVolumes.num_solic
      );
    
      SELECT NOW() INTO @Time1;
      /*******************************************************************
      # Selecionar as informações da GSM
      *******************************************************************/
      # INFORMAÇÕES DO TOPO DA GSM
      SELECT tTabelaComTexto.Coluna05 AS DocEntry, tTabelaComTexto.Coluna06 AS Doctipo
            ,tbintegraSAP_Doc.IdPicking, tbintegraSAP_Doc.IdPickingAnt
            ,tbintegraSAP_Doc.DocNum, tbintegraSAP_Doc.BPLId
            ,topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic
            ,topo.data_solic, topo.data_saida, topo.dthr_acons, topo.num_nf AS num_pedido
            ,CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem) AS NumViagem
            ,tbRotas.descr_rota RotaCliente
            ,tbDest.hora1_entrega Janela01
            ,tbDest.hora2_entrega Janela02
            ,tbDest.hora3_entrega Janela03
            ,tbDest.hora4_entrega Janela04
            ,CONCAT(tbViagens.cod_emp,'/',tbViagens.cod_fil,'-',tbViagens.ano_viagem,'.',tbViagens.num_viagem,'=>',tbRotas.descr_rota) RefViagem
            ,IF(of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)='Em Aberto',
                     IF(topo.status_processo>=9,of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa),
                                                of_logistica.fnStatusSaidaWms(topo.status_processo)),
                     of_logistica.fnStatusBaixaEntrega(tbEntregas.status_baixa)) StatusEntrega
            ,IFNULL(tbViagens.cnpj_transportador,topo.cnpj_cpf_transp) CodTranspTMS
            ,tbintegraSAP_Doc.CnpjTransp CodTranspOriginal
            ,topo.observ_solic, topo.observ_conf01, topo.status_processo
            ,of_logistica.fnStatusSaidaWms(topo.status_processo) status_processoAux
            #Liberação Inicio Processo de Separação, Picking
            ,topo.dthr_armazem, topo.dthr_armazem_picking, topo.dthr_confer, topo.dthr_confirm
            #Inicio Processo de Separação, Picking
            ,topo.dthr_inicio_geral, topo.dthr_inicio_picking, topo.dthr_inicio_carregamento
            ,xcampo_qtde_volumes
#Totais 1 (OK)
###
            ,(SELECT SUM(tbItem.real_vol) FROM of_logistica.tbsolic_saidas_item tbItem
              WHERE tbItem.cod_emp  = topo.cod_emp
                AND tbItem.cod_fil   = topo.cod_fil
                AND tbItem.ano_solic = topo.ano_solic
                AND tbItem.num_solic = topo.num_solic) QtdeVolumes
            ,(SELECT COUNT(DISTINCT tbVolumesTopo.id_volume_saida) 
               FROM of_logistica.tbsolic_saidas_volume tbVolumesTopo
               INNER JOIN of_logistica.tbsolic_saidas_volume_item tbVolumes ON
                      tbVolumesTopo.id_volume_saida = tbVolumes.id_volume_saida
               WHERE tbVolumes.cod_emp  = topo.cod_emp
                AND tbVolumes.cod_fil   = topo.cod_fil
                AND tbVolumes.ano_solic = topo.ano_solic
                AND tbVolumes.num_solic = topo.num_solic
                #AND tbVolumes.num_item  = ite.num_item
              ) QtdeVolumesPedido
###
            ,topo.qtde_volume_checkout QtdeVolManual
            ,topo.peso_liq_checkout PesoLiqManual
            ,topo.peso_brt_checkout PesoBrtManual
            ,topo.chave_integracao
#Totais 2 (OK)
###
            ,(SELECT SUM(IFNULL(tbAcons.qtde_peso2,0)) FROM of_logistica.tbsolic_saidas_acons tbAcons
              WHERE tbAcons.cod_emp   = topo.cod_emp
                AND tbAcons.cod_fil   = topo.cod_fil
                AND tbAcons.ano_solic = topo.ano_solic
                AND tbAcons.num_solic = topo.num_solic
             ) TotalPesoLiq
            ,(SELECT SUM(IFNULL(tbAcons.qtde_pbrt2,0)) FROM of_logistica.tbsolic_saidas_acons tbAcons
              WHERE tbAcons.cod_emp   = topo.cod_emp
                AND tbAcons.cod_fil   = topo.cod_fil
                AND tbAcons.ano_solic = topo.ano_solic
                AND tbAcons.num_solic = topo.num_solic
             ) TotalPesoBruto
###
             ,tbintegraSAP_Doc.WhareHouse
             ,tbintegraSAP_Doc.WhareHouseTransf
             ,tbintegraSAP_Doc.CardCode
             ,tbintegraSAP_Doc.CardName
             ,CONCAT(tbintegraSAP_Doc.StreetS," - ",tbintegraSAP_Doc.CityS,"-",tbintegraSAP_Doc.StateS,"-",tbintegraSAP_Doc.CountryS,
                     " CEP:",tbintegraSAP_Doc.ZipCodeS) AS Address 
#Totais 3 (OK)
###
             ,IF(xemb_faturamento <> "", xemb_faturamento,
                 fnContarEmbalagens(
                    (SELECT GROUP_CONCAT(tbsolic_saidas_volume.id_volume_saida,IFNULL(sigla_insumo,"vol")) Embalagens
                     FROM of_logistica.tbsolic_saidas_volume_item 
                     INNER JOIN of_logistica.tbsolic_saidas_volume ON 
                         tbsolic_saidas_volume.id_volume_saida = tbsolic_saidas_volume_item.id_volume_saida
                     LEFT JOIN of_logistica.tbwms_insumo ON 
                          tbwms_insumo.id_insumo = tbsolic_saidas_volume.id_insumo
                     WHERE topo.cod_emp = tbsolic_saidas_volume_item.cod_emp
                       AND topo.cod_fil = tbsolic_saidas_volume_item.cod_fil
                       AND topo.ano_solic = tbsolic_saidas_volume_item.ano_solic
                       AND topo.num_solic = tbsolic_saidas_volume_item.num_solic) ) 
               ) Embalagens
###
#Totais 4 (Tabela temporária OK)
###
             ,(SELECT PesoInsumos
               FROM tbTMPPesosInsumos
               WHERE tbTMPPesosInsumos.cod_emp = topo.cod_emp 
                 AND tbTMPPesosInsumos.cod_fil = topo.cod_fil
                 AND tbTMPPesosInsumos.ano_solic = topo.ano_solic
                 AND tbTMPPesosInsumos.num_solic = topo.num_solic
               ) PesoInsumos
###
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      LEFT JOIN of_logistica.tbprog_entregas tbEntregas ON
                tbEntregas.chave_integracao = topo.chave_integracao
      LEFT JOIN of_logistica.tbviagens tbViagens ON 
                tbViagens.cod_emp    = tbEntregas.cod_emp 
            AND tbViagens.cod_fil    = tbEntregas.cod_fil
            AND tbViagens.ano_viagem = tbEntregas.ano_viagem
            AND tbViagens.num_viagem = tbEntregas.num_viagem
      LEFT JOIN of_logistica.tbdestinatarios tbDest ON 
                tbDest.id_destinatario = tbEntregas.id_destinatario
      LEFT JOIN of_logistica.tbrotas tbRotas ON
                tbRotas.cod_emp  = tbDest.emp_rota
            AND tbRotas.cod_fil  = tbDest.fil_rota
            AND tbRotas.cod_rota = tbDest.cod_rota                
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      INNER JOIN tbintegraSAP_Doc ON 
                tbintegraSAP_Doc.cod_emp = topo.cod_emp
            AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
            AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
            AND tbintegraSAP_Doc.num_solic = topo.num_solic
            AND tbintegraSAP_Doc.TipoDocSLIN = 'S';
         
      #select "Teste1"; leave bloco1;
      SELECT NOW() INTO @Time2;
         
      # INFORMAÇÕES DOS ITENS DA GSM
      SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, 
             tbintegraSAP_DocPicking.PkLineNum LineNumPk, #tbintegraSAP_DocItem.LineNumPk,
             xflg_permite_PVParcial, tbintegraSAP_DocItem.Usage_,
            tbintegraSAP_DocItem.BaseQty, tbintegraSAP_DocItem.Price, 
            tbintegraSAP_DocItem.unitMsr,
            tbintegraSAP_DocItem.OpenInvQty,
            tbintegraSAP_DocItem.OpenInvQty/tbintegraSAP_DocItem.BaseQty AS B1_FatorEmbalagem,
            tbintegraSAP_DocItem.ManBtchNum, tbintegraSAP_DocItem.ManSerNum,
            tbintegraSAP_DocItem.DocEntryOrdemProducao, tbintegraSAP_DocItem.DocNumOrdemProducao,
            #IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale) AS FatorConvSAP,
            #tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
            #IF(IFNULL(prod.fator_conv_vendas,0)=0,1,prod.fator_conv_vendas) AS FatorConvSAP,
            IF(IFNULL(tbintegraSAP_DocItem.OpenInvQty,0) > 0, 
              tbintegraSAP_DocItem.OpenInvQty / tbintegraSAP_DocItem.BaseQty,
                 IF(IFNULL(tbintegraSAP_DocItem.NumInSale,1)=0,1,tbintegraSAP_DocItem.NumInSale))  AS FatorConvSAP,
            #prod.emb_compras buyUnitMsr, prod.emb_vendas salUnitMsr, prod.emb_estoque_cli invntryUom,
            tbintegraSAP_DocItem.buyUnitMsr, tbintegraSAP_DocItem.salUnitMsr, tbintegraSAP_DocItem.invntryUom,
            ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            ite.local_geral, ite.local_picking,
            IFNULL(ite.qtde_est,0) qtde_est, ite.qtde_vol, ite.qtde_frac, ite.pliq_item,		#Qtde Pedido
            ite.real_est, ite.real_vol, ite.real_frac, ite.real_peso,		#Qtde Aconselhada
            ite.real_est2, ite.real_vol2, ite.real_frac2, ite.real_peso2,	#Qtde Separação
            ite.real_est3, ite.real_vol3, ite.real_frac3, ite.real_peso3,	#Qtde Conferencia / Picking
            ite.real_est4, ite.real_vol4, ite.real_frac4, ite.real_peso4,	#Qtde Carregamento
            ite.real_est5, ite.real_vol5, ite.real_frac5, ite.real_peso5,	#Qtde check-carregamento
            # Alterado (2024-11-18) subSelect, agora utilizando tbTMPVolumes
            (SELECT GROUP_CONCAT(tbTMPVolumes.id_volume_saida)
             FROM tbTMPVolumes 
             WHERE tbTMPVolumes.cod_emp   = ite.cod_emp
               AND tbTMPVolumes.cod_fil   = ite.cod_fil
               AND tbTMPVolumes.ano_solic = ite.ano_solic
               AND tbTMPVolumes.num_solic = ite.num_solic
               AND tbTMPVolumes.num_item  = ite.num_item) IdVolumesCheckout,
            # Alterado (2024-11-18)subSelect, agora utilizando tbTMPVolumes2
            (SELECT SUM(tbTMPVolumes2.qtde_sep_est)
             FROM tbTMPVolumes2 
             WHERE tbTMPVolumes2.cod_emp   = ite.cod_emp
               AND tbTMPVolumes2.cod_fil   = ite.cod_fil
               AND tbTMPVolumes2.ano_solic = ite.ano_solic
               AND tbTMPVolumes2.num_solic = ite.num_solic
               AND tbTMPVolumes2.num_item  = ite.num_item) QtdeVolCheckout,
            #			
            ite.dthr_aconselhamento, ite.dthr_retorno_wms,
            ite.dthr_inicio_baixa_geral, ite.dthr_inicio_picking_carga, ite.dthr_inicio_carregamento,
            ite.dthr_final_baixa_geral, ite.dthr_final_picking_carga, ite.dthr_final_carregamento				
            ,topo.chave_integracao
            ,prod.flg_obriga_lote_fornecedor
            ,IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,1,0) xflg_agrupa_transf
            ,tbintegraSAP_DocItem.BaseQty / (SELECT SUM(tbDocItem.BaseQty) FROM tbintegraSAP_DocItem tbDocItem
                  WHERE tbintegraSAP_DocItem.DocTipo = tbDocItem.DocTipo
                    AND tbintegraSAP_DocItem.DocEntry = tbDocItem.DocEntry
                    AND tbintegraSAP_DocItem.ItemCode = tbDocItem.ItemCode
                  ) AS FatorAgrup
            ,RESULTADO, MENSAGEM
      FROM of_logistica.tbsolic_saidas topo
      INNER JOIN tbintegraSAP_Doc ON 
                tbintegraSAP_Doc.cod_emp = topo.cod_emp
            AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
            AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
            AND tbintegraSAP_Doc.num_solic = topo.num_solic
            AND tbintegraSAP_Doc.TipoDocSLIN = "S"
      INNER JOIN of_logistica.tbsolic_saidas_item ite ON
            ite.cod_emp = topo.cod_emp
            AND ite.cod_fil = topo.cod_fil
            AND ite.ano_solic = topo.ano_solic
            AND ite.num_solic = topo.num_solic
      INNER JOIN of_logistica.tbprodutos prod ON
            prod.cnpj_cpf = ite.cnpj_cpf_dep
            AND prod.cod_produto = ite.cod_produto
      INNER JOIN tbintegraSAP_DocItem ON 
                tbintegraSAP_DocItem.cod_emp = ite.cod_emp
            AND tbintegraSAP_DocItem.cod_fil = ite.cod_fil
            AND tbintegraSAP_DocItem.ano_solic = ite.ano_solic
            AND tbintegraSAP_DocItem.num_solic = ite.num_solic
            AND tbintegraSAP_DocItem.num_item = ite.num_item
            AND tbintegraSAP_DocItem.DocTipo  = tbintegraSAP_Doc.DocTipo
      #@Reviser David Ruy < 2022-03-21>
      #Retornar apenas as linhas que foram geradas no picking (tbintegraSAP_DocPicking)
      INNER JOIN tbintegraSAP_DocPicking ON 
                 tbintegraSAP_DocPicking.IdPicking  = tbintegraSAP_Doc.idPicking
             AND tbintegraSAP_DocPicking.DocLineNum = tbintegraSAP_DocItem.LineNum
      INNER JOIN tTabelaComTexto ON
            tTabelaComTexto.Coluna01 = topo.cod_emp
            AND tTabelaComTexto.Coluna02 = topo.cod_fil
            AND tTabelaComTexto.Coluna03 = topo.ano_solic
            AND tTabelaComTexto.Coluna04 = topo.num_solic
      #WHERE TRUE; #ite.qtde_nf > 0;
      WHERE IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2;
      #select "Teste2"; leave bloco1;
      SELECT NOW() INTO @Time3;
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes;
      DROP TEMPORARY TABLE IF EXISTS tbTMPVolumes2;
      DROP TEMPORARY TABLE IF EXISTS tbTMPPesosInsumos;
   
      # INFORMAÇÕES DAS UA´S DA GSM
      # @Reviser David Ruy <2020-11-18>
      # Checa se existe a tabela tbsolic_saidas_item_loteAux (Lotes selecionados pelo separador)
      # @Reviser David Ruy <2024-11-18>
      # Só processa o tbsolic_saidas_item_loteAux se qtde registros  > 0
      # @Reviser David Ruy <2025-07-21>
      # Não utiliza mais tbsolic_saidas_item_loteAux
      IF FALSE THEN
      #IF EXISTS (SELECT 1 
      #           FROM INFORMATION_SCHEMA.TABLES
      #           WHERE TABLE_SCHEMA = 'of_logistica'
      #             AND table_name   = 'tbsolic_saidas_item_loteAux') 
      #   AND EXISTS (SELECT 1 FROM of_logistica.tbsolic_saidas_item_loteAux LIMIT 1) THEN
         SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.LineNumPk,
            ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            IFNULL(tbLoteAux.num_lote, tbwms_estoque.num_lote_cli) num_lote_cli,
            SUM(acons.qtde_est) qtde_est, SUM(acons.qtde_vol) qtde_vol, SUM(acons.qtde_frac) qtde_frac, SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_est2), tbLoteAux.qtde_est) qtde_est2, 
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_vol2), tbLoteAux.qtde_vol) qtde_vol2, 
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_frac2), tbLoteAux.qtde_frac) qtde_frac2, 
            IF(tbLoteAux.num_lote IS NULL, SUM(acons.qtde_peso2), tbLoteAux.qtde_peso) qtde_peso2,	#Qtde Separada
            SUM(acons.qtde_est3) qtde_est3, SUM(acons.qtde_vol3) qtde_vol3, SUM(acons.qtde_frac3) qtde_frac3, SUM(acons.qtde_peso3) qtde_frac3,	#(*) Qtde Conferencia/Picking Carga
            #		
            acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
            ,topo.chave_integracao
            ,"SIM" LoteForcado
            ,RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_saidas topo
         LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
               ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic	
         INNER JOIN tbintegraSAP_Doc ON 
                   tbintegraSAP_Doc.cod_emp = topo.cod_emp
               AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
               AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
               AND tbintegraSAP_Doc.num_solic = topo.num_solic
               AND tbintegraSAP_Doc.TipoDocSLIN = 'S'      
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
         LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
               acons.cod_emp = ite.cod_emp
               AND acons.cod_fil = ite.cod_fil
               AND acons.ano_solic = ite.ano_solic
               AND acons.num_solic = ite.num_solic			
               AND acons.num_item  = ite.num_item
         LEFT JOIN of_logistica.tbsolic_saidas_item_loteAux tbLoteAux ON
                    tbLoteAux.cod_emp   = acons.cod_emp
                AND tbLoteAux.cod_fil   = acons.cod_fil
                AND tbLoteAux.ano_solic = acons.ano_solic
                AND tbLoteAux.num_solic = acons.num_solic
                AND tbLoteAux.num_item  = acons.num_item
         LEFT JOIN of_logistica.tbwms_estoque ON  
               tbwms_estoque.cod_emp = acons.cod_emp
               AND tbwms_estoque.cod_fil = acons.cod_fil
               AND tbwms_estoque.num_lote = acons.num_lote
               AND tbwms_estoque.sequencia_lote = acons.sequencia_lote
         INNER JOIN tTabelaComTexto ON
               tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         #WHERE TRUE #acons.qtde_est2 > 0
         WHERE acons.qtde_est2 > 0
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2
         GROUP BY cod_emp, cod_fil, ano_solic, num_solic, 
                  IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,
                     tbintegraSAP_DocItem.LineNum,tbintegraSAP_DocItem.num_item), num_lote_cli;
                     
      ELSE
         #Seleção das UA´/Lotes
         SELECT topo.cod_emp, topo.cod_fil, topo.ano_solic, topo.num_solic, tbintegraSAP_DocItem.LineNum, tbintegraSAP_DocItem.LineNumPk,
            ite.num_ped_cli, ite.num_item, ite.cod_produto, descr_produto,
            ite.emb_est, ite.emb_frac, ite.emb_vol, ite.fator_conv,
            #
            CONCAT(acons.num_lote,acons.sequencia_lote) AS NumUA,
            tbwms_estoque.num_lote_cli,
            SUM(acons.qtde_est) qtde_est, SUM(acons.qtde_vol) qtde_vol, SUM(acons.qtde_frac) qtde_frac, SUM(acons.qtde_peso) qtde_peso,		#Qtde Aconselhada
            SUM(acons.qtde_est2) qtde_est2, SUM(acons.qtde_vol2) qtde_vol2, SUM(acons.qtde_frac2) qtde_frac2, SUM(acons.qtde_peso2) qtde_peso2,	#Qtde Separada
            SUM(acons.qtde_est3) qtde_est3, SUM(acons.qtde_vol3) qtde_vol3, SUM(acons.qtde_frac3) qtde_frac3, SUM(acons.qtde_peso3) qtde_frac3,	#(*) Qtde Conferencia/Picking Carga
            #		
            acons.dthr_conf, acons.dthr_conf_picking, acons.dthr_carregamento
            ,topo.chave_integracao
            ,"NÃO" LoteForcado
            ,RESULTADO, MENSAGEM
         FROM of_logistica.tbsolic_saidas topo
         LEFT JOIN of_logistica.tbsolic_saidas_item ite ON
               ite.cod_emp = topo.cod_emp
               AND ite.cod_fil = topo.cod_fil
               AND ite.ano_solic = topo.ano_solic
               AND ite.num_solic = topo.num_solic	
         INNER JOIN tbintegraSAP_Doc ON 
                   tbintegraSAP_Doc.cod_emp = topo.cod_emp
               AND tbintegraSAP_Doc.cod_fil = topo.cod_fil
               AND tbintegraSAP_Doc.ano_solic = topo.ano_solic
               AND tbintegraSAP_Doc.num_solic = topo.num_solic
               AND tbintegraSAP_Doc.TipoDocSLIN = 'S'      
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
         LEFT JOIN of_logistica.tbsolic_saidas_acons acons ON
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
         INNER JOIN tTabelaComTexto ON
               tTabelaComTexto.Coluna01 = topo.cod_emp
               AND tTabelaComTexto.Coluna02 = topo.cod_fil
               AND tTabelaComTexto.Coluna03 = topo.ano_solic
               AND tTabelaComTexto.Coluna04 = topo.num_solic
         WHERE acons.qtde_est2 > 0
           AND IFNULL(tbintegraSAP_DocItem.StatusItem,0) <= 2
         GROUP BY ite.cod_emp, ite.cod_fil, ite.ano_solic, ite.num_solic, 
                  IF(tbintegraSAP_Doc.DocTipo='TD-S' AND xflg_agrupa_transf=1,
                     tbintegraSAP_DocItem.LineNum,tbintegraSAP_DocItem.num_item), num_lote_cli;
      END IF;
      #select "Teste3"; leave bloco1;
      SELECT NOW() INTO @Time4;
   END IF;
   
   SELECT @Time0, @Time1, @Time2, @Time3, @Time4,
    TIMEDIFF(@Time1,@Time0) "CriarTMP",
    TIMEDIFF(@Time2,@Time1) "Topo",
    TIMEDIFF(@Time3,@Time2) "Item",
    TIMEDIFF(@Time4,@Time3) "Acons";
       
   DROP TEMPORARY TABLE IF EXISTS tbTMP_INTEGRA_RETORNO_SAIDAS;
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