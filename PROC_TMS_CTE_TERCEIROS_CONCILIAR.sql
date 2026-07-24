DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_TMS_CTE_TERCEIROS_CONCILIAR`$$

CREATE PROCEDURE `PROC_TMS_CTE_TERCEIROS_CONCILIAR`(
    IN oTipoOperacao        VARCHAR (1)
   ,IN oCodEmp              VARCHAR (3)
   ,IN oCodFil              VARCHAR (3)
   ,IN oDataInicio          DATETIME
   ,IN oDataFim             DATETIME
   ,IN oTransportador       VARCHAR(14)
   ,IN oNumCte              VARCHAR(9)
   ,IN oNumNfe              VARCHAR(9)
   ,IN oStatusConciliacao   VARCHAR(1)
   ,IN oCodUsuario          VARCHAR(6)
   ,IN oFlgAnalise          VARCHAR(1)
   ,IN oObservAnalise       VARCHAR(300)
   ,IN oStatusAnalise       VARCHAR(30)
   ,IN oIdCtrcTercNf        INT
   ,OUT RESULTADO           VARCHAR (5)
   ,OUT MENSAGEM            VARCHAR (500)
)
BLOCO1 :
BEGIN
  #******************************************************************************************
  # oTipoOpercao = 1 ==> consulta
  #                2 ==> Atualiza conciliacao
  #******************************************************************************************
  
  DECLARE xQtdeAtualizada INT DEFAULT 0 ;
  DECLARE excecao INT DEFAULT 0 ;
  SET RESULTADO = "1" ;
  SET MENSAGEM = "Conciliação realizada com sucesso" ;
  
  IF (oTipoOperacao = 1) THEN
  BEGIN
     SELECT  
         tbCTE.cod_emp
       , tbCTE.cod_fil
       , tbCTE.cnpj_cpf_emi AS cnpj_transportadora
       , tbCTE.raz_soc_emi AS raz_transportadora
       , tbCTE.num_ctrc
       , tbCTE.serie_ctrc
       , tbCTE.dthr_emiss
       , tbCTE.vlr_tot_ctrc AS vlr_frete
       , tbCTE_NF.num_nf
       , tbCTE_NF.serie_nf
       , tbCTE_NF.data_nf
       , tbCTE_NF.peso_brt
       , tbCTE_NF.chave_nfe
       , tbCTE_NF.id_ctrc_terc_nf
       , tbprog_entregas.num_entrega
       , tbprog_entregas.ano_entrega
       , tbprog_entregas.ano_viagem
       , tbprog_entregas.num_viagem
       , tbprog_entregas.valor_entrega
       , tbprog_entregas.peso_brt_entre
       , tbviagens.carro_dia
       , tbviagens.data_viagem
       , tbusuarios.nome_usuario
       , CASE tbCTE_NF.flg_analise   #Nulo=Em Aberto, 0=Reprovado, 1=Aprovado
           WHEN 0 THEN "REPROVADO"
           WHEN 1 THEN "APROVADO"
         ELSE 
           "EM ABERTO"
         END AS flg_analise_aux
       , tbCTE_NF.flg_analise
       , tbCTE_NF.status_analise
       , tbCTE_NF.usu_analise
       , tbCTE_NF.observ_analise
       , tbCTE_NF.dthr_analise       
       , tbusuarios.nome_usuario
       , "N" AS selecionar
       , tbCTE_NF.id_ctrc_terc_nf
       , tbCTE_NF.valor_nf
            FROM tbtms_ctrc_terc2 tbCTE_NF 
      INNER JOIN tbtms_ctrc_terc tbCTE 
              ON tbCTE_NF.cod_emp = tbCTE.cod_emp 
             AND tbCTE_NF.cod_fil = tbCTE.cod_fil 
             AND tbCTE_NF.cnpj_cpf_emi = tbCTE.cnpj_cpf_emi 
             AND tbCTE_NF.num_ctrc = tbCTE.num_ctrc 
             AND tbCTE_NF.serie_ctrc = tbCTE.serie_ctrc 
       LEFT JOIN tbprog_entregas 
              ON tbCTE_NF.cod_emp_entrega = tbprog_entregas.cod_emp
             AND tbCTE_NF.cod_fil_entrega = tbprog_entregas.cod_fil
             AND tbCTE_NF.ano_entrega     = tbprog_entregas.ano_entrega
             AND tbCTE_NF.num_entrega     = tbprog_entregas.num_entrega
       LEFT JOIN tbviagens
              ON tbprog_entregas.cod_emp  = tbviagens.cod_emp
             AND tbprog_entregas.cod_fil  = tbviagens.cod_fil
             AND tbprog_entregas.ano_viagem = tbviagens.ano_viagem
             AND tbprog_entregas.num_viagem = tbviagens.num_viagem
       LEFT JOIN tbusuarios 
              ON tbCTE_NF.usu_analise = tbusuarios.cod_usu
              
     WHERE tbCTE.cod_emp = oCodEmp
       AND tbCTE.cod_fil = oCodFil
       AND tbCTE.dthr_emiss >= oDataInicio
       AND tbCTE.dthr_emiss <= oDataFim 
       AND IF(oTransportador IS NULL, 1 = 1, tbCTE.cnpj_cpf_emi = oTransportador)
       AND IF(oNumCte IS NULL, 1=1, tbCTE.num_ctrc = oNumCte)
       AND IF(oNumNfe IS NULL, 1=1, tbCTE_NF.num_nf = oNumNfe)
       AND IF(oStatusConciliacao > 1, IF(oStatusConciliacao = 2, 1=1, tbCTE_NF.flg_analise IS NULL ),
                tbCTE_NF.flg_analise = oStatusConciliacao);
  END;
  ELSEIF (oTipoOperacao = '2') THEN   
  BEGIN  
     UPDATE tbtms_ctrc_terc2 tbCTE_NF 
        SET tbCTE_NF.status_analise = oStatusAnalise,
            tbCTE_NF.observ_analise = oObservAnalise,
            tbCTE_NF.flg_analise = oflgAnalise,
            tbCTE_NF.usu_analise = oCodUsuario,
            tbCTE_NF.dthr_analise = NOW()
      WHERE tbCTE_NF.id_ctrc_terc_nf = oIdCtrcTercNf;
      
     SET MENSAGEM = 'Entrega Conciliada com Sucesso!!!';
     SET RESULTADO = '1';
  END;
  END IF;
  
  
  IF excecao = 1 THEN 
    SET RESULTADO = "0" ;
    SET MENSAGEM = "Erro SQL - Verifique com o Administrador" ;
  END IF ;
END$$

DELIMITER ;