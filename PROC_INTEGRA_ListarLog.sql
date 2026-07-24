DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarLog`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarLog`( IN oDataInicio				   VARCHAR(20)
, IN oDataFinal				    VARCHAR(20)
, IN oMetodo           VARCHAR(50)
, IN oTipoOper				     VARCHAR(50)
, IN oTipoOper2        VARCHAR(50)
, IN oStatusSLIN       VARCHAR(50)
, IN oSucesso          VARCHAR(1)
)
BEGIN
   /*************************************************************************************************
   #@Reviser David Ruy <2022/04/29> Novo Status = 8-> Forçar Picking
   #@Reviser David Ruy <2022/04/29> Buscar por PK / ID
   #@Reviser David Ruy <2023/03/01> Campo BPLId
   #@Reviser David Ruy <2023/07/25> Filtro oTipoOper like PA%
   #@Reviser Erico Forcinetti <2024/04/20> Melhorias nos Selects
   #@Reviser David Ruy <2024-09-04> Condição TOPO : IF(tbTopo.DocTipo IN ('PV','DC','TD-S','OP'),'S','' )) = 'S'
   #@Reviser David Ruy <2024-09-04> Condição TOPO : IF(tbTopo.DocTipo IN ('E-RM','E-NE','NE','DV','TD-E','PA000'),'S','' )) = 'E'
   #
   #
   #
   #
   #PV - Liberados para Picking
   1 'GET', 'inventory/Picking', '', null);
   #PV - Reabertura de Picking
   2 'DELETE', 'inventory/Picking', 'PV571', 0);
   #Criação de Picking
   3 'POST', 'inventory/Picking/Create','PV571', 0);
   #Confirmação de Picking
   4 'POST', 'inventory/Picking', 'Confirm', 0);
   #Vendas - Alteração de Pedido de Vendas
   5 'GET', 'inventory/Updated', '', 0);
     'PROC', 'tbintegraSAP_UpdCancPV', '', 0);
   #Vendas - Atualização de Pedido de Vendas
   7 'POST', 'inventory/Order', 'ChangeQuantity', 0);
   #Vendas - Cancelamento Pedido de Vendas
   8 'ObterDocumento', 'inventory/Canceled', '', 0);
   #Vendas - NF retorno - Devolução de Vendas
   9 'GET', 'inventory/CreditNote', '', 0);
   9 'POST', 'inventory/CreditNote', '', 0);
   #Compras - NF Entrega Futura
   10 'GET', 'purchase', '', 0);
   10 'POST', 'purchase', '', 0);
   #Compras - Cancelamento Entrega Futura
   11 'ObterListaRecebimentoCancelado', 'ReverseInvoice', '', 0);
   #Contagem
   12 'POST','inventory/Counting/Confirm', xcod_produto   
   *************************************************************************************************/
   
   DECLARE xTipoDoc    VARCHAR(20) DEFAULT '';
   DECLARE _DataInicio DATETIME; 
   DECLARE _DataFinal  DATETIME; 
   
   SET _DataInicio = oDataInicio; 
   SET _DataFinal  = oDataFinal; 
   
   IF LOCATE('PK',oTipoOper2)>0 THEN
      SET xTipoDoc = 'PK';
      SET oTipoOper2 = REPLACE(oTipoOper2, "PK","");
   END IF;
   IF LOCATE('ID',oTipoOper2)>0 THEN
      SET xTipoDoc = 'ID';
      SET oTipoOper2 = REPLACE(oTipoOper2, "ID","");
   END IF;
   
   #Cria tabela Temporária com Status das operações
   SET @String = 'Confirmed|OK|Created|200|1|2|3';
   CALL PROC_SYS_GerarTabelaComTexto(@String,"|",1);
   
   
  IF oTipoOper = "/api/inventory/Picking/Create" THEN
     SET oTipoOper = "Pick_Create";
  END IF;
  IF oTipoOper = "/api/inventory/Picking/Confirm" THEN
     SET oTipoOper = "Pick_Confirm";
  END IF;
  IF oTipoOper = "/api/inventory/Canceled" THEN
     SET oTipoOper = "Pick_Delete";
  END IF;
  #IF oTipoOper = "/api/Stock/Transfers/Confirm" THEN
  IF oTipoOper LIKE "%Transfer%" THEN
     SET oTipoOper = "Transfer";
  END IF;
  IF oTipoOper LIKE "/api/purchase%" THEN
     SET oTipoOper = "Purchase";
  END IF;
   
   
  IF UPPER(oMetodo) = 'TOPO' THEN
  BEGIN 
  
    SELECT tbTopo.DocTipo                   AS DocTipo
         , tbTopo.DocEntry                  AS DocEntry
         , CONCAT( tbTopo.DocTipo
                 , tbTopo.DocNum
                 , '(',tbTopo.DocEntry,')'
                 )                          AS DocSAP
         , tbTopo.IdPicking                 AS IdPicking 
         , tbTopo.IdPickingAnt              AS IdPickingAnt
         , tbTopo.DocDate                   AS DocDate   
         , tbTopo.DueDate                   AS DueDate
         , tbTopo.StatusAnt                 AS StatusAnt
         , tbTopo.StatusDoc                 AS StatusDoc 
         , tbTopo.StatusSLIN                AS StatusSLIN
         , tbTopo.DocNum                    AS DocNum
         , CASE tbTopo.StatusAnt
                WHEN "1" THEN "Importado SAP"
                WHEN "2" THEN "Integrado SLIN"
                WHEN "3" THEN "Integrado SLIN (alteração)"
                WHEN "4" THEN "Iniciado SLIN"
                WHEN "5" THEN "Finalizado SLIN"
                WHEN "6" THEN "Retornado SAP"
                WHEN "7" THEN "Em Alteração WMS"
                WHEN "8" THEN "Forçar Novo Picking"
                WHEN "9" THEN "Cancelado SAP"
           END                              AS DescStatusAnt
         , CASE tbTopo.StatusDoc
                WHEN "1" THEN "Importado SAP"
                WHEN "2" THEN "Integrado SLIN"
                WHEN "3" THEN "Integrado SLIN (alteração)"
                WHEN "4" THEN "Iniciado SLIN"
                WHEN "5" THEN "Finalizado SLIN"
                WHEN "6" THEN "Retornado SAP"
                WHEN "7" THEN "Em Alteração WMS"
                WHEN "8" THEN "Forçar Novo Picking"
                WHEN "9" THEN "Cancelado SAP"
           END                              AS DescStatus
         , of_logistica.fnStatusSaidaWms(IFNULL(tbSaidas.status_processo,99)) StatusSlin
         , tbTopo.CardCode                  AS CardCode
         , tbTopo.CardName                  AS CardName
         , CONCAT( 'GSM:'
                 , TRIM(LEADING '0' FROM tbTopo.cod_emp)
                 , "/"
                 , TRIM(LEADING '0' FROM tbTopo.cod_fil)
                 , '-'
                 , TRIM(LEADING '0' FROM tbTopo.num_solic)
                 , "|"
                 , tbTopo.ano_solic
                 )                          AS DocSLIN
         , tbTopo.dthr_cancel_slin          AS dthr_cancel_slin
         , tbTopo.Observacoes               AS Observacoes
         , tbTopo.dthr_inc                  AS dthr_inc
         , tbTopo.dthr_alt                  AS dthr_alt  
         , tbSaidas.dthr_inc                AS dthr_inc_slin
         , tbSaidas.dthr_retorno_integracao AS dthr_retorno
         , IF(     ( SELECT SUM(IFNULL(Item.real_est2, 0)) 
                       FROM of_logistica.tbsolic_saidas_item Item
                      WHERE Item.cod_emp   = tbSaidas.cod_emp   
                        AND Item.cod_fil   = tbSaidas.cod_fil
                        AND Item.ano_solic = tbSaidas.ano_solic
                        AND Item.num_solic = tbSaidas.num_solic
                   )  
                 - ( SELECT SUM(IFNULL(Item.qtde_sep_est, 0)) 
                       FROM of_logistica.tbsolic_saidas_volume_item Item
                      WHERE Item.cod_emp   = tbSaidas.cod_emp   
                        AND Item.cod_fil   = tbSaidas.cod_fil
                        AND Item.ano_solic = tbSaidas.ano_solic
                        AND Item.num_solic = tbSaidas.num_solic
                   ) = 0 
               AND IFNULL( ( SELECT SUM(IFNULL(Item.qtde_sep_est, 0)) 
                               FROM of_logistica.tbsolic_saidas_volume_item Item
                              WHERE Item.cod_emp   = tbSaidas.cod_emp   
                                AND Item.cod_fil   = tbSaidas.cod_fil
                                AND Item.ano_solic = tbSaidas.ano_solic
                                AND Item.num_solic = tbSaidas.num_solic
                           ) 
                         , 0
                         ) > 0 
               AND ( tbSaidas.status_processo >= 8
                   )
             , TRUE
             , FALSE
             )                              AS FlgCheckout
         , IF( EXISTS( SELECT tbViagens.num_viagem
                         FROM of_logistica.tbprog_entregas tbEntregas 
                              INNER JOIN of_logistica.tbviagens tbViagens  ON tbViagens.cod_emp    = tbEntregas.cod_emp 
                                                                          AND tbViagens.cod_fil    = tbEntregas.cod_fil
                                                                          AND tbViagens.ano_viagem = tbEntregas.ano_viagem 
                                                                          AND tbViagens.num_viagem = tbEntregas.num_viagem
                        WHERE tbEntregas.chave_integracao = tbSaidas.chave_integracao
                          AND tbViagens.data_conf IS NOT NULL
                     )
             , TRUE
             , FALSE
             )                             AS FlgRotaConf
         , ( SELECT CONCAT(tbEntregas.num_viagem , '/', tbEntregas.ano_viagem) 
               FROM of_logistica.tbprog_entregas tbEntregas
              WHERE tbEntregas.chave_integracao = tbSaidas.chave_integracao
           )                               AS NumViagem
         , tbTopo.chave_integracao         AS chave_integracao
         , tbnfCli.chave_nfe               AS chave_nfe 
         , tbTopo.BPLId                    AS BPLId
         , ( SELECT SUM(Item.qtde_sep_est) 
               FROM of_logistica.tbsolic_saidas_volume_item Item
              WHERE Item.cod_emp   = tbSaidas.cod_emp
                AND Item.cod_fil   = tbSaidas.cod_fil
                AND Item.ano_solic = tbSaidas.ano_solic
                AND Item.num_solic = tbSaidas.num_solic
           )                               AS QtdeCheckout 
         , ( SELECT SUM(Item.real_est2) 
               FROM of_logistica.tbsolic_saidas_item Item
              WHERE Item.cod_emp   = tbSaidas.cod_emp
                AND Item.cod_fil   = tbSaidas.cod_fil
                AND Item.ano_solic = tbSaidas.ano_solic
                AND Item.num_solic = tbSaidas.num_solic
           )                               AS QtdeSep
         , tbSaidas.qtde_volume_checkout  AS QtdeVolumesApontamento
      FROM tbintegraSAP_Doc tbTopo
           LEFT JOIN of_logistica.tbsolic_saidas tbSaidas  ON tbSaidas.cod_emp         = tbTopo.cod_emp 
                                                          AND tbSaidas.cod_fil         = tbTopo.cod_fil
                                                          AND tbSaidas.ano_solic       = tbTopo.ano_solic
                                                          AND tbSaidas.num_solic       = tbTopo.num_solic
           LEFT JOIN of_logistica.tbnf_clientes tbnfCli    ON tbnfCli.chave_integracao = tbTopo.chave_integracao
     WHERE tbTopo.DocDate     BETWEEN _DataInicio AND _DataFinal
       AND IFNULL(tbTopo.TipoDocSLIN, IF(tbTopo.DocTipo IN ('PV','DC','TD-S','OP'),'S','' )) = 'S'
       AND IF( IFNULL(oTipoOper,'') = ''
             , TRUE
             , DocTipo LIKE CONCAT(oTipoOper,'%')
             )
       AND IF( IFNULL(oTipoOper2,'') = ''
             , TRUE
             , IF( xTipoDoc='PK'
                 , IdPicking = oTipoOper2
                 , IF( xTipoDoc='ID'
                     , DocEntry = oTipoOper2
                     , CAST(DocNum AS CHAR) = oTipoOper2
                     )
                 )
             )
       AND IF( IFNULL(oSucesso,'T') = 'T'
             , TRUE
             , oSucesso = StatusDoc
             )
       AND IF( oStatusSLIN='T'
             , TRUE
             , IF( oStatusSLIN = '1'
                 , tbSaidas.status_processo <= 1 
                 , IF( oStatusSLIN = '2'
                     , tbSaidas.status_processo BETWEEN 2 AND 5
                     , IF( oStatusSLIN = '3'
                         , tbSaidas.status_processo >= 6
                         , FALSE
                         )
                 )
              )
           )
        
     UNION ALL 
      
     SELECT tbTopo.DocTipo                     AS DocTipo
          , tbTopo.DocEntry                    AS DocEntry
          , CONCAT( tbTopo.DocTipo
                  , tbTopo.DocNum
                  , '(',tbTopo.DocEntry,')'
                  )                            AS DocSAP
          , tbTopo.IdPicking                   AS IdPicking 
          , tbTopo.IdPickingAnt                AS IdPickingAnt
          , tbTopo.DocDate                     AS DocDate   
          , tbTopo.DueDate                     AS DueDate
          , tbTopo.StatusAnt                   AS StatusAnt
          , tbTopo.StatusDoc                   AS StatusDoc 
          , tbTopo.StatusSLIN                  AS StatusSLIN
          , tbTopo.DocNum                      AS DocNum
          , CASE tbTopo.StatusAnt
                 WHEN "1" THEN "Importado SAP"
                 WHEN "2" THEN "Integrado SLIN"
                 WHEN "3" THEN "Integrado SLIN (alteração)"
                 WHEN "4" THEN "Iniciado SLIN"
                 WHEN "5" THEN "Finalizado SLIN"
                 WHEN "6" THEN "Retornado SAP"
                 WHEN "7" THEN "Em Alteração WMS"
                 WHEN "8" THEN "Forçar Novo Picking"
                 WHEN "9" THEN "Cancelado SAP"
            END                                AS DescStatusAnt
          , CASE tbTopo.StatusDoc
                 WHEN "1" THEN "Importado SAP"
                 WHEN "2" THEN "Integrado SLIN"
                 WHEN "3" THEN "Integrado SLIN (alteração)"
                 WHEN "4" THEN "Iniciado SLIN"
                 WHEN "5" THEN "Finalizado SLIN"
                 WHEN "6" THEN "Retornado SAP"
                 WHEN "7" THEN "Em Alteração WMS"
                 WHEN "8" THEN "Forçar Novo Picking"
                 WHEN "9" THEN "Cancelado SAP"
            END                                AS DescStatus
          , of_logistica.fnStatusProcessoWms(IFNULL(tbEntradas.status_processo,99)) StatusSlin
          , tbTopo.CardCode                    AS CardCode
          , tbTopo.CardName                    AS CardName
          , CONCAT( 'GEM:'
                  , TRIM(LEADING '0' FROM tbTopo.cod_emp)
                  , "/"
                  , TRIM(LEADING '0' FROM tbTopo.cod_fil)
                  , '-'
                  , TRIM(LEADING '0' FROM tbTopo.num_solic)
                  , "|"
                  , tbTopo.ano_solic
                  )                            AS DocSLIN
          , tbTopo.dthr_cancel_slin            AS dthr_cancel_slin
          , tbTopo.Observacoes                 AS Observacoes
          , tbTopo.dthr_inc                    AS dthr_inc
          , tbTopo.dthr_alt                    AS dthr_alt  
          , tbEntradas.dthr_inc                AS dthr_inc_slin
          , tbEntradas.dthr_retorno_integracao AS dthr_retorno
          , FALSE                              AS FlgCheckout
          , FALSE                              AS FlgRotaConf
          , NULL                               AS NumViagem
          , tbTopo.chave_integracao            AS chave_integracao
          , NULL                               AS chave_nfe 
          , tbTopo.BPLId                       AS BPLId
          , NULL                               AS QtdeCheckout 
          , NULL                               AS QtdeSep
          , NULL                               AS QtdeVolumesApontamento
       FROM tbintegraSAP_Doc tbTopo  
       LEFT JOIN of_logistica.tbsolic_entradas tbEntradas  ON tbEntradas.cod_emp   = tbTopo.cod_emp 
                                                          AND tbEntradas.cod_fil   = tbTopo.cod_fil
                                                          AND tbEntradas.ano_solic = tbTopo.ano_solic
                                                          AND tbEntradas.num_solic = tbTopo.num_solic
      WHERE tbTopo.DocDate     BETWEEN _DataInicio AND _DataFinal
        AND IFNULL(tbTopo.TipoDocSLIN, IF(tbTopo.DocTipo IN ('E-RM','E-NE','NE','DV','TD-E','PA000'),'S','' )) = 'E'
        AND IF( IFNULL(oTipoOper,'') = ''
              , TRUE
              , DocTipo LIKE CONCAT(oTipoOper,'%')
              )
        AND IF( IFNULL(oTipoOper2,'') = ''
              , TRUE
              , IF( xTipoDoc='PK'
                  , IdPicking = oTipoOper2
                  , IF( xTipoDoc='ID'
                      , DocEntry = oTipoOper2
                      , CAST(DocNum AS CHAR) = oTipoOper2
                      )
                  )
              )
        AND IF( IFNULL(oSucesso,'T') = 'T'
              , TRUE
              , oSucesso = StatusDoc
              )
        AND IF( oStatusSLIN='T'
              , TRUE
              , IF( oStatusSLIN = '1'
                  , tbEntradas.status_processo <= 3
                  , IF( oStatusSLIN = '2'
                      , tbEntradas.status_processo BETWEEN 4 AND 7
                      , IF( oStatusSLIN = '3'
                          , tbEntradas.status_processo >= 8
                          , FALSE
                          )
                  )
               )
            ); 
  
  END; 
  ELSEIF UPPER(oMetodo) IN ('PATCH', 'GET','POST','PROC','DELETE') THEN
  BEGIN  
  
     IF oTipoOper = 'Last' THEN
     BEGIN 
     
        SELECT * FROM tbintegraSAP_log_request
        LEFT JOIN tTabelaComTexto ON
                 tTabelaComTexto.coluna01 = ResponseStatus
        WHERE dthr_inc > CURRENT_DATE()
        AND IF(oMetodo='PROC', SUBSTRING(jsonrequest,01,04) = oMetodo,
               IF(oMetodo='GET',(SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'ObterDocumento' OR 
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo OR
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'GET1') ,
                     
                     IF(oMetodo='PATCH',
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo OR
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'PATCH1',
                                 
                                 SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo)
                                 
              ))
        AND IF(oSucesso='T', TRUE, IF(oSucesso=1, tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL))
        ORDER BY dthr_inc DESC 
        LIMIT 50;
       
     END; 
     ELSE
     BEGIN 
     
        SELECT tbintegraSAP_log_request.* 
          FROM tbintegraSAP_log_request
               LEFT JOIN tTabelaComTexto ON tTabelaComTexto.coluna01 = tbintegraSAP_log_request.ResponseStatus
         WHERE tbintegraSAP_log_request.dthr_inc BETWEEN _DataInicio AND _DataFinal
           AND IF( oMetodo='PROC'
                 , SUBSTRING(jsonrequest, 01, 04) = oMetodo
                 , IF( ( oMetodo = 'GET'
                       )  
                     , (    SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'ObterDocumento' 
                         OR SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo 
                         OR SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'GET1'
                       ) 
                     , IF( oMetodo = 'PATCH'
                         ,    SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo 
                           OR SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = 'PATCH1'
                         , SUBSTRING(jsonrequest,01,LOCATE("|",jsonrequest)-1) = oMetodo
                         )
                     )
                 )
           AND tbintegraSAP_log_request.jsonrequest LIKE CONCAT('%',oTipoOper,'%')
           AND IF( oMetodo='POST'
                 , tbintegraSAP_log_request.jsonrequest  LIKE CONCAT('%',oTipoOper2,'%')
                 , tbintegraSAP_log_request.jsonResponse LIKE CONCAT('%',oTipoOper2,'%')
                 )
           AND IF( oSucesso='T'
                 , TRUE
                 , IF( oSucesso=1
                     , tTabelaComTexto.coluna01 IS NOT NULL, tTabelaComTexto.coluna01 IS NULL
                     )
                 );      
        
        SELECT oTipoOper, oTipoOper2, oMetodo;
     
     END; 
     END IF;
  
  END; 
  ELSEIF UPPER(oMetodo) = 'LAST' THEN 
  BEGIN 
  
     #Ultimo registro de log
     SELECT tbintegraSAP_log_request.*,
            CASE 
               WHEN LOCATE('purchase',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Compras"
               WHEN LOCATE('transfer',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Transferencias"
               WHEN LOCATE('ReverseInvoice',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Cancelamento de Compras"
               WHEN LOCATE('CreditNote',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Devoluções Pedido de Vendas"
               WHEN LOCATE('picking',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Criação e Confirmaçao de Picking"
               WHEN LOCATE('Production',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Ordem de Produção"
               WHEN LOCATE('Update',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Alterações de Pedidos de Vendas"
               WHEN LOCATE('PROC_INTEGRA_EnviarUpdCancPV',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Alterações de Pedidos de Vendas"
               WHEN LOCATE('PROC_INTEGRA_AtualizarSLIN',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Atualizar SLIN (GEM e GSM)"
               WHEN LOCATE('PATCHTMS',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Atualizar Status Entregas -> SAP"
               WHEN LOCATE('GetDiAPI_InventChaveDanfe',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Buscar N° NF Vendas (AddOn Invent)"
               #WHEN LOCATE('',tbintegraSAP_log_request.jsonRequest) > 0 THEN "Buscar CT-e´s (AddOn Invent)"
             ELSE "N/A"
             END AS ProcessoAtual
     FROM tbintegraSAP_log_request
     ORDER BY dthr_inc DESC LIMIT 1;
  
  END; 
  END IF;
  
  
  DROP TEMPORARY TABLE IF EXISTS tTabelaComTexto;
END$$

DELIMITER ;