DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO`$$

CREATE PROCEDURE `PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO`( IN oCodigoEmpresa    VARCHAR(3)
, IN oCodigoFilial     VARCHAR(3)
, IN oAnoProcesso      VARCHAR(4)
, IN oNumeroProcesso   VARCHAR(10)
, OUT RESULTADO		      INT(1)
, OUT MENSAGEM         VARCHAR(255)
)
BLOCO1:BEGIN
  # PROCEDURE PARA CANCELAR GSM VIA INTEGRAÇÃO
  # @author Érico Forcinetti <2019/07/15>
  # @Reviser David ruy <2021/12/06> Cancelamento da entrega no TMS (status_entre)  
  # @company Overflash Informática
  
  /** 
   * ------------------------ INFORMAÇÕES ADICIONAIS -----------------------
   *
   *
   * ---------------------- FIM INFORMAÇÕES ADICIONAIS ---------------------
   */
  
  /****************************************************************/
  /**************** DECLARAR VARIÁVEIS AUXILIARES 
  /****************************************************************/
  
  DECLARE _DthrAtual DATETIME DEFAULT NOW();
  
  /****************************************************************/
  /****************DECLARAR CONTROLE DE EXCEÇÃO DE SQL 
  /****************************************************************/
    
	 DECLARE EXIT HANDLER FOR SQLEXCEPTION
  BEGIN
    GET DIAGNOSTICS CONDITION 1 MENSAGEM = MESSAGE_TEXT;
   
    ROLLBACK; 
    SET RESULTADO = 0;
    SET MENSAGEM  = fnMensagemExcecao(MENSAGEM);
  END;
	 
  /****************************************************************/
  /**************** INICIAR TRANSAÇÃO 
  /****************************************************************/
	 
  START TRANSACTION; 
	 
	 
  SET RESULTADO	= 1;
	 
	 
  /****************************************************************/
  /**************** SEPARAÇÃO INICIADA 
  /****************************************************************/
  
  IF EXISTS( SELECT 1 
               FROM tbsolic_saidas 
              WHERE tbsolic_saidas.cod_emp           = oCodigoEmpresa
                AND tbsolic_saidas.cod_fil           = oCodigoFilial
                AND tbsolic_saidas.ano_solic         = oAnoProcesso
                AND tbsolic_saidas.num_solic         = oNumeroProcesso
                AND tbsolic_saidas.dthr_inicio_geral IS NOT NULL 
           )
  THEN 
  BEGIN
    
    /****************************************************************/
    /**************** GRAVAR LOG DE REABERTURA DA CONFIRMAÇÃO 
    /****************************************************************/
 
    INSERT INTO tbsolic_saidas_log_reabertura( cod_emp
                                             , cod_fil
                                             , ano_solic
                                             , num_solic
                                             , dthr_confirm
                                             , usu_confirm
                                             , dthr_log
                                             , usu_log
                                             , usu_log_lider
                                             , form_log
                                             , flg_reabertura_tipo
                                             )
      SELECT tbsolic_saidas.cod_emp                   AS cod_emp
           , tbsolic_saidas.cod_fil                   AS cod_fil
           , tbsolic_saidas.ano_solic                 AS ano_solic
           , tbsolic_saidas.num_solic                 AS num_solic
           , tbsolic_saidas.dthr_confirm              AS dthr_confirm
           , tbsolic_saidas.usu_confirm               AS usu_confirm
           , _DthrAtual                               AS dthr_log
           , '999999'                                 AS usu_log
           , NULL                                     AS usu_log_lider
           , 'PROC_WMS_SAIDA_CANCELAR_GSM_INTEGRACAO' AS form_log
           , 2                                        AS flg_reabertura_tipo 
        FROM tbsolic_saidas
       WHERE tbsolic_saidas.cod_emp      = oCodigoEmpresa
         AND tbsolic_saidas.cod_fil      = oCodigoFilial
         AND tbsolic_saidas.ano_solic    = oAnoProcesso
         AND tbsolic_saidas.num_solic    = oNumeroProcesso
         AND tbsolic_saidas.dthr_confirm IS NOT NULL; 
 
    /****************************************************************/
    /**************** ATUALIZAR TOPO 
    /****************************************************************/
  
    /**
     * CANCELAMENTO DEVERÁ SER GERADO VIA TELA DE SUPERVISÃO DE SEPARAÇÃO
     */ 
     
    UPDATE tbsolic_saidas
       SET tbsolic_saidas.dthr_confirm    = NULL 
         , tbsolic_saidas.usu_confirm     = NULL 
         , tbsolic_saidas.status_processo = 11
         , tbsolic_saidas.num_agrup_geral = NULL
         , tbsolic_saidas.dthr_bloqueio_fin = IF(     tbsolic_saidas.dthr_bloqueio_ini IS NOT NULL 
                                                  AND tbsolic_saidas.dthr_bloqueio_fin IS     NULL 
                                                , _DthrAtual
                                                , tbsolic_saidas.dthr_bloqueio_fin
                                                )
         , tbsolic_saidas.usu_bloqueio_fin  = IF(     tbsolic_saidas.usu_bloqueio_ini IS NOT NULL 
                                                  AND tbsolic_saidas.usu_bloqueio_fin IS     NULL 
                                                , '999999'
                                                , tbsolic_saidas.usu_bloqueio_fin
                                                )
     WHERE tbsolic_saidas.cod_emp         = oCodigoEmpresa
       AND tbsolic_saidas.cod_fil         = oCodigoFilial
       AND tbsolic_saidas.ano_solic       = oAnoProcesso
       AND tbsolic_saidas.num_solic       = oNumeroProcesso
       AND tbsolic_saidas.status_processo <> 11;
    
    /****************************************************************/
    /**************** FINALIZAR RECURSOS
    /****************************************************************/
  
    UPDATE tbrf_recurso
       SET tbrf_recurso.dthr_fin        = _DthrAtual
         , tbrf_recurso.flg_concluido   = 1 
         , tbrf_recurso.usu_desktop_fin = '999999'
     WHERE tbrf_recurso.cod_emp_saida   = oCodigoEmpresa
       AND tbrf_recurso.cod_fil_saida   = oCodigoFilial
       AND tbrf_recurso.ano_solic_saida = oAnoProcesso
       AND tbrf_recurso.num_solic_saida = oNumeroProcesso
       AND tbrf_recurso.cod_funcao      IN (2, 4)
       AND tbrf_recurso.dthr_fin        IS NULL;
   
  END; 
  
  /****************************************************************/
  /**************** SEPARAÇÃO NÃO INICIADA 
  /****************************************************************/
  
  ELSE 
  BEGIN
    
    /**
     * CANCELAMENTO REALIZADO VIA SISTEMA
     */ 
    
    CALL PROC_WMS_SAIDA_CANCELAR_GSM( oCodigoEmpresa  
                                    , oCodigoFilial   
                                    , oAnoProcesso    
                                    , oNumeroProcesso
                                    , '999999'
                                    , RESULTADO		      
                                    , MENSAGEM         
                                    ); 
  
    IF (RESULTADO = 0) THEN 
    BEGIN
    
      ROLLBACK; 
      LEAVE BLOCO1; 
    
    END; 
    END IF; 
    
  END;
  END IF;
  
  
  IF RESULTADO = 1 THEN
     #Cancela a Entrega no TMS
     UPDATE tbprog_entregas
     INNER JOIN tbsolic_saidas ON 
           tbsolic_saidas.chave_integracao = tbprog_entregas.chave_integracao
     #inner join tbnf_clientes on 
     #           tbnf_clientes.id_nf = tbprog_entregas.id_nf
     SET tbprog_entregas.status_entre = 9,
         tbprog_entregas.status_baixa = 4,
         tbprog_entregas.ano_viagem = NULL,
         tbprog_entregas.num_viagem = NULL,
         tbprog_entregas.usu_alt = '999999',
         tbprog_entregas.dthr_alt = NOW(),
         tbprog_entregas.observ_baixa = "Cancelamento via integração"
     WHERE tbsolic_saidas.cod_emp   = oCodigoEmpresa
       AND tbsolic_saidas.cod_fil   = oCodigoFilial
       AND tbsolic_saidas.ano_solic = oAnoProcesso
       AND tbsolic_saidas.num_solic = oNumeroProcesso;
  END IF;
 
  
  #*******************************************************************************************
  #**
  #** Se por ventura houver algum erro em alguma etapa do processamento, cancela o processo
  #** inteiro e sinalizado ao usuario. Caso contrario efetiva informações no banco e sinaliza
  #** usuario.
  #**
  #********************************************************************************************
  SET MENSAGEM  = 'OK';
  SET RESULTADO = 1;
  COMMIT; 
  
END$$

DELIMITER ;