DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_TMS_GERAR_ENTREGAS`$$

CREATE PROCEDURE `PROC_INTEGRA_TMS_GERAR_ENTREGAS`( IN oCodEmpWMS   VARCHAR(03)
, IN oCodFilWMS   VARCHAR(03)
, IN oAnoSolic    VARCHAR(04)
, IN oNumSolic    VARCHAR(10)
, IN oTipoFrete   VARCHAR(05)
, IN oCnpjTransp  VARCHAR(20)
, IN oNomeTransp  VARCHAR(50)
, OUT RESULTADO   VARCHAR(40)
, OUT MENSAGEM    VARCHAR(500)
)
BLOCO1:BEGIN
  /************************************************************************
  * @Created David Ruy <2018/04/11>
  * Esta procedure realiza a inserção de registros na base de dados SLIN
  * para o módulo TMS (analisa tbprog_entregas, tbnf_clientes)
  *
  *@Reviser David Ruy <2020/01/26> Considerar TipoFrete (SAP) e Transportadora Coleta
  *@Reviser David Ruy <2020/02/11> Considerar DEPARA para tipo Operação de Transporte/Incoterms
  *@Reviser David Ruy <2020/08/28> Atualizar quantidades no TMS com base no FECHAMENTO da GSM, 
  *                                além de considerar oTipoFrete = null para não atualizar essas informações
  *@Reviser David Ruy <2020/12/14> Não considerar mais Coletas
  *@Reviser David Ruy <2021/03/24> Atualizar a transportadora na tbprog_entregas->cnpj_cpf_terceiro not null
  *                                Rotina de roteirização : tbviagens->cnpj_transportador quando não for retirada
  *
  *@Reviser David Ruy <2022/01/12> Ajuste para atualizar peso bruto
  *@Reviser David Ruy <2023/01/05> Ajuste correção Year(now()) para oAnoSolic (evita Duplicar a entrega e fica no mesmo ano da GSM)
  *@Reviser David Ruy <2023/01/30> Ajuste Calculo Peso Bruto Variavel xtot_pesobrt : pesoLiq+(Vol*(tara))
                                   Alterado tbsolic_saidas_item.dthr_final_baixa_geral por tbsolic_saidas.dthr_final_geral 
  *@Reviser David Ruy <2023/01/31> Ajuste Calculo Peso Bruto Variavel xtot_pesobrt : com base na UA
  *@Reviser David Ruy <2023/10/23> Parametrização tabela novo formato tbintegraSAP_TipoFrete.TransportationCode
  *@Reviser David Ruy <2023/12/27> Atualização campo num_nf_aux com xNumPedido
  *@Reviser David Ruy <2024/08/07> Correção calculo Valor NF pela soma dos itens (Sub Select inserido)
  *************************************************************************/
  
  /**
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /****************DECLARAR VARIÁVEIS AUXILIARES
  /****************************************************************/
  
  DECLARE xRetornoTMS         VARCHAR(500);
  DECLARE xId_nf				          INT;
  DECLARE xCnpjCliWMS         VARCHAR(14);
  DECLARE xNumPedido          VARCHAR(20);
  DECLARE xChaveIntegracao    VARCHAR(50);
  DECLARE xSerPedido          VARCHAR(03) DEFAULT '1';
  DECLARE xDataSolic          DATE;
  DECLARE xDataSaida          DATE;
  DECLARE xCodUsuario         VARCHAR(06);
  DECLARE xTipoFrete          VARCHAR(01) DEFAULT 'C';
  DECLARE xCodTipoOper        VARCHAR(03) DEFAULT '001';
  DECLARE xFlgCross           VARCHAR(01) DEFAULT 'N';
  DECLARE xvlr_tot_nf         DECIMAL(20,6);
  DECLARE xtot_pesoliq        DECIMAL(20,6);
  DECLARE xtot_pesobrt        DECIMAL(20,6);
  DECLARE xPLiqItem           DECIMAL(20,6);
  DECLARE xPBrtItem           DECIMAL(20,6); 
  #Destinatário (Local Entrega)
  DECLARE _IDDestinatario     INT(11); 
  DECLARE _dest_CNPJ          VARCHAR(14);
  DECLARE _dest_CPF      	    VARCHAR(14);
  DECLARE _dest_RazSocial     VARCHAR(200);
  DECLARE _dest_NomeFant      VARCHAR(200);
  DECLARE _dest_InscrEst      VARCHAR(20);
  DECLARE _dest_Endereco      VARCHAR(60);
  DECLARE _dest_Nro           VARCHAR(10);
  DECLARE _dest_Compl         VARCHAR(200);
  DECLARE _dest_Bairro        VARCHAR(100);
  DECLARE _dest_Cidade        VARCHAR(50);
  DECLARE _dest_UF            VARCHAR(20);
  DECLARE _dest_CEP           VARCHAR(10);
  DECLARE _dest_CidadeCod     VARCHAR(10);
  #Variaveis para tbprog_entregas
  DECLARE xCodEmp             VARCHAR(03);
  DECLARE xCodFil             VARCHAR(03);
  DECLARE xAno_entrega        VARCHAR(04);
  DECLARE xNum_entrega        VARCHAR(10);
  DECLARE xTemtbprog_entregas INT DEFAULT 0;
  DECLARE xCNPJ_Dest_Aux      VARCHAR(14);
  DECLARE xHora1_entrega      VARCHAR(05);
  DECLARE xHora2_entrega      VARCHAR(05);
  DECLARE xHora3_entrega      VARCHAR(05);
  DECLARE xHora4_entrega      VARCHAR(05);
  DECLARE xtempo_entrega      DECIMAL(6,2);
  DECLARE xCodUnidade			VARCHAR(03);
  DECLARE xCodArmazem 		   VARCHAR(02);
  DECLARE xObservacoes        VARCHAR(200);
  DECLARE xinstr_entrega      VARCHAR(200);
  DECLARE xCNPJColeta         VARCHAR(20);
  DECLARE xidDestinoColeta    INT;
  DECLARE xNomeColeta         VARCHAR(50);
  
  DECLARE xOperadorLogistico  BOOLEAN;
  DECLARE xTabelaFrete        INT DEFAULT 0;   #0 = tbintegraSAP_DeParaOperTMS; 1 = tbintegraSAP_TipoFrete
  
  /****************************************************************/
  /****************CONTROLE DE EXCEÇÃO DE SQL
  /****************************************************************/
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
  
    ROLLBACK;
    SET RESULTADO = '0';
    SET MENSAGEM  = MENSAGEM;
  END;
  
  #****************************************************************
  #*******************INICIAR VARIÁVEIS
  #****************************************************************
  
  SET xCodUsuario = '999999';
  
  
  /*
  #Incoterms - SAP => 0,1,2,9 Coleta/Retirada | => 3,4 (Nosso Carro/Distribuição/CIF)
  #SET xTipoFrete = IF(oTipoFrete IN (0,1,2,9), "E", "C");
  #Incoterms - SAP => 0,1,2 Coleta | 9 => Retirada | => 3,4 (Nosso Carro/Distribuição/CIF)
  SET xidDestinoColeta = NULL;
  #SET xTipoFrete = IF(oTipoFrete IN (0,1,2),"O", IF(oTipoFrete=9, "E", "C"));
  SET xTipoFrete = IF(oTipoFrete IN (0,1,2,9),"E", "C");
  IF xTipoFrete = "E" THEN
     SET xCodTipoOper = "999";
  END IF;
  */
  
  
   IF EXISTS (SELECT 1 FROM tbintegraSAP_TipoFrete LIMIT 1) THEN
      SET xTabelaFrete = 1;
   END IF;
  
  
  #*******************Seleciona o Destinatário do pedido da GSM
  SELECT of_logistica.tbsolic_saidas.cnpj_cpf_cli
       , of_logistica.tbsolic_saidas.cnpj_cpf_for
       , IFNULL(of_logistica.tbsolic_saidas_item.num_ped_cli, of_logistica.tbsolic_saidas.num_nf)
       , of_logistica.tbsolic_saidas.data_solic
       , of_logistica.tbsolic_saidas.data_saida
       #Peso_Item : 2023-01-30
       , SUM(tbsolic_saidas_item.pliq_item)
       , SUM(tbsolic_saidas_item.pbrt_item)
       #Peso_Aconselhamento 2023-01-31
       , IF(tbsolic_saidas.dthr_final_geral IS NULL, SUM(of_logistica.tbsolic_saidas_acons.qtde_peso), SUM(of_logistica.tbsolic_saidas_acons.qtde_peso2))
       , IF(tbsolic_saidas.dthr_final_geral IS NULL, SUM(of_logistica.tbsolic_saidas_acons.qtde_pbrt), SUM(of_logistica.tbsolic_saidas_acons.qtde_pbrt2))
       #
       , IF(xTabelaFrete = 0, 
            IFNULL(tbintegraSAP_DeParaOperTMS.cod_oper_tms, '001'),
            IFNULL(tbintegraSAP_TipoFrete.CodTipoOper, '001')) CodTipoOper
       , IF(xTabelaFrete = 0, 
            IFNULL(tbintegraSAP_DeParaOperTMS.TipoFrete, 'C'),
            IFNULL(tbintegraSAP_TipoFrete.TipoFrete, 'C'))  TipoFrete
       , of_logistica.tbsolic_saidas.id_destinatario
       
       #@Reviser David Ruy <2024/08/07> 
       #, IF(tbsolic_saidas.dthr_final_geral IS NULL, SUM(of_logistica.tbsolic_saidas_item.vlr_item), SUM(of_logistica.tbsolic_saidas_item.vlr_item / tbsolic_saidas_item.qtde_est * real_est2))
       , IF(tbsolic_saidas.dthr_final_geral IS NULL, 
             (SELECT SUM(tbItemAux.vlr_item) 
                      FROM of_logistica.tbsolic_saidas_item tbItemAux
                      WHERE tbItemAux.cod_emp   = tbsolic_saidas_item.cod_emp 
                        AND tbItemAux.cod_fil   = tbsolic_saidas_item.cod_fil 
                        AND tbItemAux.ano_solic = tbsolic_saidas_item.ano_solic
                        AND tbItemAux.num_solic = tbsolic_saidas_item.num_solic)  ,
             (SELECT SUM(tbItemAux.vlr_item) 
                      FROM of_logistica.tbsolic_saidas_item tbItemAux
                      WHERE tbItemAux.cod_emp   = tbsolic_saidas_item.cod_emp 
                        AND tbItemAux.cod_fil   = tbsolic_saidas_item.cod_fil 
                        AND tbItemAux.ano_solic = tbsolic_saidas_item.ano_solic
                        AND tbItemAux.num_solic = tbsolic_saidas_item.num_solic) / tbsolic_saidas_item.qtde_est * real_est2) VlrNF
       , tbsolic_saidas.chave_integracao
       , SUBSTRING(tbintegraSAP_Doc.Observacoes,1,200)
    INTO xCnpjCliWMS
       , _dest_CNPJ
       , xNumPedido
       , xDataSolic
       , xDataSaida
       , xPLiqItem
       , xPBrtItem
       , xtot_pesoliq
       , xtot_pesobrt
       , xCodTipoOper
       , xTipoFrete
       , _IDDestinatario
       , xvlr_tot_nf
       , xChaveIntegracao
       , xObservacoes
    FROM of_logistica.tbsolic_saidas
    LEFT JOIN tbintegraSAP_Doc              ON tbintegraSAP_Doc.cod_emp             = tbsolic_saidas.cod_emp
                                           AND tbintegraSAP_Doc.cod_fil             = tbsolic_saidas.cod_fil
                                           AND tbintegraSAP_Doc.ano_solic           = tbsolic_saidas.ano_solic
                                           AND tbintegraSAP_Doc.num_solic           = tbsolic_saidas.num_solic
                                           AND tbintegraSAP_Doc.TipoDocSLIN         = 'S'
    LEFT JOIN tbintegraSAP_DeParaOperTMS    ON tbintegraSAP_DeParaOperTMS.Incoterms = tbintegraSAP_Doc.TipoFrete
    LEFT JOIN tbintegraSAP_TipoFrete        ON tbintegraSAP_TipoFrete.TransportationCode = tbintegraSAP_Doc.TransportationCode
    LEFT JOIN of_logistica.tbsolic_saidas_item ON tbsolic_saidas_item.cod_emp          = tbsolic_saidas.cod_emp
                                           AND tbsolic_saidas_item.cod_fil          = tbsolic_saidas.cod_fil
                                           AND tbsolic_saidas_item.ano_solic        = tbsolic_saidas.ano_solic
                                           AND tbsolic_saidas_item.num_solic        = tbsolic_saidas.num_solic
    LEFT JOIN of_logistica.tbsolic_saidas_acons ON tbsolic_saidas_acons.cod_emp      = tbsolic_saidas_item.cod_emp
                                           AND tbsolic_saidas_acons.cod_fil          = tbsolic_saidas_item.cod_fil
                                           AND tbsolic_saidas_acons.ano_solic        = tbsolic_saidas_item.ano_solic
                                           AND tbsolic_saidas_acons.num_solic        = tbsolic_saidas_item.num_solic
                                           AND tbsolic_saidas_acons.num_item         = tbsolic_saidas_item.num_item
   WHERE tbsolic_saidas.cod_emp   = oCodEmpWMS
     AND tbsolic_saidas.cod_fil   = oCodFilWMS
     AND tbsolic_saidas.ano_solic = oAnoSolic
     AND tbsolic_saidas.num_solic = oNumSolic
   LIMIT 1;
   
   #Se ainda não tem aconselhamento, pega o peso do item
   IF xtot_pesoliq IS NULL THEN
      SET xtot_pesoliq = xPLiqItem;
      SET xtot_pesobrt = xPBrtItem;
   END IF;
   
   
   #Desabilitado em 14/12/2020
   #Se for Coleta, Buscar na tabela de Destinatarios a Transportadora
   #Se for retira também
   /*IF xTipoFrete IN ("O","E") THEN
      SET xCNPJColeta  = oCnpjTransp;
      SET xNomeColeta  = oNomeTransp;
      SELECT id_destinatario INTO xidDestinoColeta
      FROM of_logistica.tbdestinatarios
      WHERE of_logistica.tbdestinatarios.cnpj_cpf_cliente = xCnpjCliWMS
        AND of_logistica.tbdestinatarios.cod_integracao   = xCNPJColeta;
   END IF;   
   */
   
   
   #Se não gravou o ID Destinatário na tbSolicSaidas
   #Busca o destinatário pelo Codigo de Integração
   IF IFNULL(_IDDestinatario,'') = '' THEN
      SELECT id_destinatario INTO _IDDestinatario
      FROM of_logistica.tbdestinatarios
      WHERE of_logistica.tbdestinatarios.cnpj_cpf_cliente = xCnpjCliWMS
        AND of_logistica.tbdestinatarios.cod_integracao   = _dest_CNPJ;
        
      # Atualiza a GSM com o ID do Destinatário identificado pelo codigo de integração
      UPDATE of_logistica.tbsolic_saidas tbSaidas
      SET tbSaidas.id_destinatario = _IDDestinatario
      WHERE tbSaidas.cod_emp   = oCodEmpWMS
        AND tbSaidas.cod_fil   = oCodFilWMS
        AND tbSaidas.ano_solic = oAnoSolic
        AND tbSaidas.num_solic = oNumSolic;
   END IF;
   
   
   #*******************Informações do Destinatário
   SELECT of_logistica.tbdestinatarios.cnpj_cpf
       , of_logistica.tbdestinatarios.raz_social
       , of_logistica.tbdestinatarios.nome_fantasia
       , of_logistica.tbdestinatarios.inscr_estadual
       , of_logistica.tbdestinatarios.endereco
       , of_logistica.tbdestinatarios.num_ende
       , of_logistica.tbdestinatarios.compl_ende
       , of_logistica.tbdestinatarios.bairro
       , of_logistica.tbdestinatarios.nome_cidade
       , of_logistica.tbdestinatarios.sig_estado
       , of_logistica.tbdestinatarios.cep_ende
   INTO _dest_CNPJ
       , _dest_RazSocial
       , _dest_NomeFant
       , _dest_InscrEst
       , _dest_Endereco
       , _dest_Nro
       , _dest_Compl
       , _dest_Bairro
       , _dest_Cidade
       , _dest_UF
       , _dest_CEP
   FROM of_logistica.tbdestinatarios
   WHERE id_destinatario = _IDDestinatario; 
   
   #@Reviser David Ruy <2022-03-15>
   SET _dest_Endereco = SUBSTRING(CONCAT(_dest_Endereco, IF(IFNULL(_dest_Nro,'')='','', CONCAT(' ',_dest_Nro))),1,50);   
   SET _dest_Endereco = UPPER(_dest_Endereco);
   SET _dest_RazSocial = UPPER(_dest_RazSocial);
   SET _dest_NomeFant = UPPER(_dest_NomeFant);
   SET _dest_InscrEst = UPPER(_dest_InscrEst);
   SET _dest_Nro = UPPER(_dest_Nro);
   SET _dest_Compl = UPPER(_dest_Compl);
   SET _dest_Bairro = UPPER(_dest_Bairro);
   SET _dest_Cidade = UPPER(_dest_Cidade);
   SET _dest_UF = UPPER(_dest_UF);
   
   
   
  #***************************************************************************
  #***************Verica se já existe um numero e ano de entrega se não cria
  #***************************************************************************
  SELECT num_entrega, ano_entrega
    INTO xNum_entrega, xAno_entrega
    FROM of_logistica.tbprog_entregas
   WHERE cod_emp          = oCodEmpWMS
     AND cod_fil          = oCodFilWMS
     AND cnpj_cpf_cli     = xCnpjCliWMS   #_emi_CNPJ
     #AND num_nf_cli      = xNumPedido
     #AND serie_nf_cli    = xSerPedido
     AND chave_integracao = xChaveIntegracao     
     #Temporariamente desabilitado o Ano nessa Busca
     #AND ano_entrega      = oAnoSolic     #YEAR(NOW())
     AND num_entre_ant IS NULL;
     
  SET xTemtbprog_entregas = (IFNULL(xNum_entrega,'') <> '');
  
  IF NOT xTemtbprog_entregas THEN
     SELECT LPAD((CAST(MAX(num_entrega) AS UNSIGNED)+1),'10','0') AS num_entrega
          #, YEAR(NOW())                                           AS ano_entrega
          ,oAnoSolic                                              AS ano_entrega  
     INTO xNum_entrega, xAno_entrega
     FROM of_logistica.tbprog_entregas
     WHERE cod_emp     = oCodEmpWMS
       AND cod_fil     = oCodFilWMS
       AND ano_entrega = oAnoSolic;  #YEAR(NOW());
     IF (xNum_entrega IS NULL) THEN
        SET xNum_entrega = '0000000001';
     END IF;
     SET xRetornoTMS = CONCAT('Entrega N° ',xNum_entrega, ' gerada com sucesso ! (',xNumPedido,')');
  END IF;
  
  
  #****************************************************************
  #***************Insere / atualiza tbnf_clientes
  #****************************************************************
  
  IF NOT EXISTS( SELECT 1
                   FROM of_logistica.tbnf_clientes
                  WHERE cod_emp          = oCodEmpWMS
                    AND cod_fil          = oCodFilWMS
                    AND cnpj_cpf         = xCnpjCliWMS    #_emi_CNPJ
                    AND chave_integracao = xChaveIntegracao
                    #AND num_nf          = xNumPedido
                    #AND serie_nf        = xSerPedido
                    AND ano_entrega      = xAno_entrega
               )
  THEN
  BEGIN 
     
     INSERT INTO of_logistica.tbnf_clientes( cod_emp
                                        , cod_fil
                                        , cnpj_cpf
                                        , num_nf
                                        , serie_nf
                                        , ano_entrega
                                        , cnpj_cpf_rem
                                        , data_nf
                                        , cnpj_cpf_destino
                                        , loc_destino
                                        , id_destinatario
                                        , valor_nf
                                        , vlr_tot_nf
                                        , peso_liq_nf
                                        , peso_brt_nf
                                        , dthr_inc
                                        , usu_inc
                                        , chave_integracao
                                        )
                                 VALUES ( oCodEmpWMS
                                        , oCodFilWMS
                                        , xCnpjCliWMS
                                        , xNumPedido
                                        , xSerPedido
                                        , xAno_entrega
                                        , xCnpjCliWMS
                                        , CAST(SUBSTRING(xDataSolic, 1, 10) AS DATE)
                                        , _dest_CNPJ
                                        , _IDDestinatario
                                        , _IDDestinatario
                                        , xvlr_tot_nf
                                        , xvlr_tot_nf
                                        , xtot_pesoliq
                                        , xtot_pesobrt
                                        , NOW()
                                        , xCodUsuario
                                        , xChaveIntegracao
                                        );
     SET xid_nf = LAST_INSERT_ID();
  
  END; 
  ELSE
  BEGIN 
  
    SELECT of_logistica.tbnf_clientes.id_nf
      INTO xid_nf
      FROM of_logistica.tbnf_clientes
     WHERE of_logistica.tbnf_clientes.cod_emp          = oCodEmpWMS
       AND of_logistica.tbnf_clientes.cod_fil          = oCodFilWMS
       AND of_logistica.tbnf_clientes.cnpj_cpf         = xCnpjCliWMS
       #AND of_logistica.tbnf_clientes.num_nf          = xNumPedido
       #AND of_logistica.tbnf_clientes.serie_nf        = xSerPedido
       AND of_logistica.tbnf_clientes.chave_integracao = xChaveIntegracao
       AND of_logistica.tbnf_clientes.ano_entrega      = xAno_entrega
     LIMIT 1;
    UPDATE of_logistica.tbnf_clientes
       SET of_logistica.tbnf_clientes.cnpj_cpf_rem     = xCnpjCliWMS
         , of_logistica.tbnf_clientes.data_nf          = CAST(SUBSTRING(xDataSolic, 1, 10) AS DATE)
         , of_logistica.tbnf_clientes.cnpj_cpf_destino = _dest_CNPJ
         , of_logistica.tbnf_clientes.id_destinatario  = _IDDestinatario
         , of_logistica.tbnf_clientes.loc_destino      = _IDDestinatario
         , of_logistica.tbnf_clientes.valor_nf         = xvlr_tot_nf
         , of_logistica.tbnf_clientes.vlr_tot_nf       = xvlr_tot_nf
         , of_logistica.tbnf_clientes.peso_liq_nf      = xtot_pesoliq
         , of_logistica.tbnf_clientes.peso_brt_nf      = xtot_pesobrt
         , of_logistica.tbnf_clientes.dthr_alt         = NOW()
         , of_logistica.tbnf_clientes.usu_alt          = xCodUsuario
     WHERE of_logistica.tbnf_clientes.id_nf            = xid_nf;
  
  END; 
  END IF; 
     
  #****************************************************************
  #***********************Insere tbprog_entregas
  #****************************************************************
  #Verifica se a nota já esta cadastrada na tbprog_entregas, caso não cadastrada inclui
  SELECT hora1_entrega
       , hora2_entrega
       , hora3_entrega
       , hora4_entrega
       , tempo_entrega
       , instr_entrega
  INTO xHora1_entrega
     , xHora2_entrega
     , xHora3_entrega
     , xHora4_entrega
     , xtempo_entrega
     , xinstr_entrega
   FROM of_logistica.tbdestinatarios
   WHERE id_destinatario = _IDDestinatario; 
  IF (NOT xTemtbprog_entregas) THEN
  BEGIN 
  
        INSERT INTO of_logistica.tbprog_entregas(id_nf,
                                     cod_emp,
                                     cod_fil,
                                     ano_entrega,
                                     num_entrega,
                                     flg_roteiriza,
                                     cnpj_cpf_cli,
                                     cnpj_cpf_centralizador,
                                     num_ped_aux,
                                     num_nf_cli,
                                     serie_nf_cli,
                                     num_nf_aux,
                                     id_destinatario, 
                                     cnpj_cpf_destino,
                                     ie_destino,
                                     nome_destino,
                                     ende_destino,
                                     bairro_destino,
                                     cidade_destino,
                                     estado_destino,
                                     local_entrega,
                                     cnpj_cpf_coleta,
                                     id_destinatario_coleta,
                                     cnpj_cpf_terceiro,
                                     cnpj_cpf_redesp,
                                     ie_redesp,
                                     nome_redesp,
                                     ende_redesp,
                                     cep_redesp,
                                     bairro_redesp,
                                     cidade_redesp,
                                     estado_redesp,
                                     data_redesp,
                                     tipo_frete,
                                     num_ctrc_redesp,
                                     valor_redesp,
                                     peso_liq_entre,
                                     peso_brt_entre,
                                     peso_liq_ori,
                                     peso_brt_ori,
                                     cubagem_entre,
                                     data_progr,
                                     data_separa,
                                     cep_ende,
                                     flg_zmrc,
                                     num_ende,
                                     flg_cobra_entrega,
                                     cod_serv,
                                     cod_tipo_oper,
                                     compl_ende,
                                     hora1_entre,
                                     hora2_entre,
                                     hora3_entre,
                                     hora4_entre,
                                     tempo_entre,
                                     observ_entre,
                                     flg_cobra_var,
                                     flg_cdock,
                                     usu_inc,
                                     dthr_inc,
                                     chave_integracao)
        VALUES (xid_nf,
                oCodEmpWMS,
                oCodFilWMS,
                xAno_entrega,
                xNum_entrega,
                "S",
                xCnpjCliWMS,
                xCnpjCliWMS, 
                xNumPedido,
                xNumPedido,
                xSerPedido,
                xNumPedido,  #@NumNF,
                _IDDestinatario, 
                _dest_CNPJ,
                _dest_InscrEst,
                SUBSTRING(_dest_RazSocial,1,50),
                _dest_Endereco,
                SUBSTRING(_dest_Bairro,1,50),
                _dest_Cidade,
                _dest_UF,
                _IDDestinatario, # cod_loja
                xCNPJColeta,
                xidDestinoColeta,
                oCnpjTransp,
                NULL, # cnpj_redesp
                NULL, # ie_redesp
                NULL, # raz_soc_redesp
                NULL, # ende_redesp
                NULL, # cep_redesp
                NULL, # bairro_redesp
                NULL, # cidade_redesp
                NULL, # estado_redesp
                NULL, # data_redesp
                xTipoFrete, # Parametro
                NULL, # num_ctrc_redesp,
                NULL, # valor_redesp
                xtot_pesoliq,
                xtot_pesobrt,
                xtot_pesoliq,
                xtot_pesobrt,
                NULL,       # cubagem
                xDataSaida, # Parametro
                xDataSaida, # Parametro
                _dest_CEP,
                '', # xflgZMRC,
                _dest_Nro,
                'S', # flg_cobra_entrega
                NULL,     # cod_serv
                xCodTipoOper,  # Parametro
                SUBSTRING(_dest_Compl, 1, 20),
                xHora1_entrega,
                xHora2_entrega,
                xHora3_entrega,
                xHora4_entrega,
                xtempo_entrega,
                xObservacoes,
                NULL, # xflg_cobra_var,  (Verificar Tabela de Preços)
                xFlgCross, # Parametro
                xCodUsuario,
                NOW(),
                xChaveIntegracao);
  
  END; 
  ELSE
  BEGIN 
  
        UPDATE of_logistica.tbprog_entregas
        SET cod_emp           = oCodEmpWMS,
            cod_fil           = oCodFilWMS,
            ano_entrega       = xAno_entrega,
            num_entrega       = xNum_entrega,
            flg_roteiriza     = "S",
            cnpj_cpf_cli      = xCnpjCliWMS,  #_emi_CNPJ,
            num_ped_aux       = xNumPedido,
            num_nf_cli        = xNumPedido,
            serie_nf_cli      = xSerPedido,
            id_destinatario   = _IDDestinatario, 
            cnpj_cpf_destino  = _dest_CNPJ,
            ie_destino        = _dest_InscrEst,
            nome_destino      = SUBSTRING(_dest_RazSocial,1,50),
            ende_destino      = _dest_Endereco,
            bairro_destino    = SUBSTRING(_dest_Bairro,1,50),
            cidade_destino    = _dest_Cidade,
            estado_destino    = _dest_UF,
            local_entrega     = _IDDestinatario,
            cnpj_cpf_coleta   = IF(oTipoFrete IS NULL, cnpj_cpf_coleta, xCNPJColeta),
            id_destinatario_coleta = IF(oTipoFrete IS NULL, id_destinatario_coleta, xidDestinoColeta),
            cnpj_cpf_terceiro = oCnpjTransp,
            cnpj_cpf_redesp   = NULL,
            ie_redesp         = NULL,
            nome_redesp       = NULL,
            ende_redesp       = NULL,
            cep_redesp        = NULL,
            bairro_redesp     = NULL,
            cidade_redesp     = NULL,
            estado_redesp     = NULL,
            data_redesp       = NULL,
            tipo_frete        = IF(oTipoFrete IS NULL, tipo_frete, xTipoFrete),   #<@Reviser David - 2020-07-23> tipo_frete,  # Não Atualiza, utiliza o conteúdo do campo
            num_ctrc_redesp   = NULL,
            valor_redesp      = NULL,
            peso_liq_entre    = xtot_pesoliq,
            peso_brt_entre    = xtot_pesobrt,
            peso_liq_ori      = xtot_pesoliq,
            peso_brt_ori      = xtot_pesobrt,
            cubagem_entre     = cubagem_entre,                              # Não Atualiza, utiliza o conteúdo do campo
            cep_ende          = _dest_CEP,
            flg_zmrc          = flg_zmrc,                                        # Não Atualiza, utiliza o conteúdo do campo
            num_ende          = _dest_Nro,
            flg_cobra_entrega = flg_cobra_entrega,         # Não Atualiza, utiliza o conteúdo do campo
            cod_serv          = cod_serv,                                      # Não Atualiza, utiliza o conteúdo do campo
            cod_tipo_oper     = IF(oTipoFrete IS NULL, cod_tipo_oper, xCodTipoOper), #<@Reviser David - 2020-07-23>  cod_tipo_oper,                   # Não Atualiza, utiliza o conteúdo do campo
            compl_ende        = SUBSTRING(_dest_Compl, 1, 20),
            hora1_entre       = xHora1_entrega,
            hora2_entre       = xHora2_entrega,
            hora3_entre       = xHora3_entrega,
            hora4_entre       = xHora4_entrega,
            tempo_entre       = xtempo_entrega,
            observ_entre      = xObservacoes,
            flg_cobra_var     = flg_cobra_var,                        # Não Atualiza, utiliza o conteúdo do campo
            flg_cdock         = flg_cdock,                                     # Não Atualiza, utiliza o conteúdo do campo
            dthr_alt          = NOW(),
            usu_alt           = xCodUsuario
        WHERE id_nf = xid_nf
          AND num_entre_ant IS NULL;
    
     SET xRetornoTMS = CONCAT('Entrega N° ',xNum_entrega, ' atualizada com sucesso ! (',xNumPedido,'-',xSerPedido,')');
  
  END; 
  END IF;
  #****************************************************************
  #********Insere tbnf_ite_clientes (Itens da NF)
  #****************************************************************
  DELETE
    FROM of_logistica.tbnf_ite_clientes
   WHERE of_logistica.tbnf_ite_clientes.id_nf = xid_nf; 
  INSERT INTO of_logistica.tbnf_ite_clientes (id_nf, cod_emp,
                                 cod_fil,
                                 cnpj_cpf,
                                 num_nf,
                                 serie_nf,
                                 num_item,
                                 ano_entrega,
                                 cod_produto,
                                 qtde_ori,
                                 emb_ori,
                                 peso_liq_item,
                                 peso_brt_item,
                                 vlr_unitario,
                                 vlr_item,
                                 #vlr_ipi_item,
                                 #vlr_icms_item,
                                 qtde_vol,
                                 emb_vol,
                                 qtde_frac,
                                 emb_frac,
                                 emb_maior,
                                 fator_conv,
                                 #num_lote_cli,
                                 #data_fabr,
                                 dthr_inc,
                                 usu_inc)
             (SELECT xid_nf, oCodEmpWMS,
                     oCodFilWMS,
                     xCnpjCliWMS,  #_emi_CNPJ,
                     xNumPedido,
                     xSerPedido,
                     LPAD(num_item,6,'0'),
                     xAno_Entrega,
                     cod_produto,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_est, real_est2),
                     emb_est,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pliq_item, real_peso2),
                     #IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pbrt_item, real_vol2 * tbsolic_saidas_item.peso_volume_brt),
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, 
                         of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.pliq_item, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.qtde_vol),
                         of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.real_peso2, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.real_vol2)
                         ),
                     vlr_unitario,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, vlr_item, vlr_item / qtde_est * real_est2),
                     #vlr_ipi_item,
                     #vlr_icms_item,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_vol, real_vol2),
                     emb_vol,
                     IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_frac, real_frac2),
                     emb_frac,
                     emb_vol,
                     fator_conv,
                     #NULL, #num_lote_cli
                     #NULL, #data_fabr
                     NOW(),
                     xCodUsuario
              FROM of_logistica.tbsolic_saidas_item
              WHERE cod_emp = oCodEmpWMS
                AND cod_fil = oCodEmpWMS
                AND ano_solic = oAnoSolic
                AND num_solic = oNumSolic
                AND IFNULL(tbsolic_saidas_item.qtde_est,0) > 0);
  
  #****************************************************************
  #***********Insere tbprog_ite_entregas (Itens da Entrega)
  #****************************************************************
  DELETE
    FROM of_logistica.tbprog_ite_entregas
   WHERE of_logistica.tbprog_ite_entregas.cod_emp     = oCodEmpWMS
     AND of_logistica.tbprog_ite_entregas.cod_fil     = oCodFilWMS
     AND of_logistica.tbprog_ite_entregas.ano_entrega = xAno_entrega
     AND of_logistica.tbprog_ite_entregas.num_entrega = xnum_entrega;
  INSERT INTO of_logistica.tbprog_ite_entregas( cod_emp
                                           , cod_fil
                                           , ano_entrega
                                           , num_entrega
                                           , num_item
                                           , cod_produto
                                           , qtde_ori
                                           , emb_ori
                                           , qtde_vol
                                           , emb_vol
                                           , peso_liq_item
                                           , peso_brt_item
                                           , qtde_frac
                                           , emb_frac
                                           , cubagem
                                           , dthr_inc
                                           , usu_inc
                                           )
    SELECT oCodEmpWMS
         , oCodFilWMS
         , xAno_entrega
         , xNum_entrega
         , LPAD(num_item,6,'0')
         , cod_produto
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_est, real_est2)
         , emb_est
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_vol, real_vol2)
         , emb_vol
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pliq_item, real_peso2)
         #, IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, pbrt_item, real_vol2 * tbsolic_saidas_item.peso_volume_brt)
         ,IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, 
              of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.pliq_item, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.qtde_vol),
              of_logistica.fnCalcPesoBrt( tbsolic_saidas_item.real_peso2, tbsolic_saidas_item.real_tara, tbsolic_saidas_item.real_vol2)
              )
         , IF(tbsolic_saidas_item.dthr_final_baixa_geral IS NULL, qtde_frac, real_frac2)
         , emb_frac
         , NULL
         , NOW()
         , xCodUsuario
      FROM of_logistica.tbsolic_saidas_item
     WHERE cod_emp = oCodEmpWMS
       AND cod_fil = oCodEmpWMS
       AND ano_solic = oAnoSolic
       AND num_solic = oNumSolic
       AND IFNULL(tbsolic_saidas_item.qtde_est,0) > 0;
  /***********************************************************************
  # Integração TMS X WMS
  ***********************************************************************/
  IF (xDataSaida IS NOT NULL) THEN
     CALL of_logistica.PROC_TMS_SAIDA_ATUALIZAR_ENTREGA_UNIDADE_ARMAZEM(oCodEmpWMS, oCodFilWMS, IFNULL(xCnpjCliWMS, xCnpjCliWMS), xDataSolic, xDataSaida, @R, @M);
  END IF;
  /****************************************************************/
  /******** FINALIZA PROCEDURE E ENVIA RETORNO
  /****************************************************************/
  SET RESULTADO = 1;
  SET mensagem = CONCAT(xRetornoTMS);
  COMMIT;
   
END$$

DELIMITER ;