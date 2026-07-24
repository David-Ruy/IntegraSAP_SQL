DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_TMS_CTE_TERCEIROS_VINCULAR_ENTREGA`$$

CREATE PROCEDURE `PROC_TMS_CTE_TERCEIROS_VINCULAR_ENTREGA`(
	IN oCodUsuario				    VARCHAR(10),
	# Parametros de Retorno
	OUT RESULTADO         VARCHAR(5),
	OUT MENSAGEM          VARCHAR(500)
)
BLOCO1:BEGIN
   /***********************************************************************************************************************************************/
   #@Reviser David Ruy <2023-11-17> Ajuste para atualizar o valor_frete (rateio pelo peso) tbtms_ctrc_terc2
   #@Reviser David Ruy <2025-11-14> Ajuste para considerar o processamento apenas dos ultimos 6 meses (180 dias)
   /***********************************************************************************************************************************************/
   DECLARE xQtdeAtualizada INT DEFAULT 0;
   DECLARE excecao         INT DEFAULT 0;
   #DECLARE CONTINUE HANDLER FOR SQLEXCEPTION SET excecao = 1;
   DECLARE xdata_viagem      VARCHAR(30);
   DECLARE xcod_emp          VARCHAR(03);
   DECLARE xcod_fil          VARCHAR(03);
   DECLARE xchave_integracao VARCHAR(30);
   SET RESULTADO = "1";
   SET MENSAGEM = "Conciliação realizada com sucesso";
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE_Terc;
   CREATE TEMPORARY TABLE tbTMPCTE_Terc
      SELECT tbCTE.id_remessa AS chave_CTE,
             tbCTE.cod_emp, tbCTE.cod_fil, tbCTE.cnpj_cpf_emi, tbCTE.num_ctrc, tbCTE.serie_ctrc,
             tbCTE_NF.id_ctrc_terc_nf,
             tbCTE_NF.chave_nfe, tbCTE_NF.num_nf, tbCTE_NF.serie_nf,
             tbCTE.vlr_tot_ctrc, 0 flg_processado
      FROM tbtms_ctrc_terc2 tbCTE_NF
      INNER JOIN tbtms_ctrc_terc tbCTE ON 
            tbCTE_NF.cod_emp      = tbCTE.cod_emp
        AND tbCTE_NF.cod_fil      = tbCTE.cod_fil
        AND tbCTE_NF.cnpj_cpf_emi = tbCTE.cnpj_cpf_emi
        AND tbCTE_NF.num_ctrc     = tbCTE.num_ctrc
        AND tbCTE_NF.serie_ctrc   = tbCTE.serie_ctrc
      WHERE tbCTE.dthr_emiss >= DATE_SUB(CURRENT_DATE(), INTERVAL 180 DAY)
        AND tbCTE_NF.cod_emp_entrega IS NULL
        AND tbCTE.data_cancel IS NULL;
      
   UPDATE tbtms_ctrc_terc2 tbCTE_NF
   INNER JOIN tbTMPCTE_Terc ON
         tbCTE_NF.id_ctrc_terc_nf = tbTMPCTE_Terc.id_ctrc_terc_nf 
   INNER JOIN tbnf_clientes ON 
              tbnf_clientes.chave_nfe = tbTMPCTE_Terc.chave_nfe
   INNER JOIN tbprog_entregas ON 
              tbprog_entregas.id_nf = tbnf_clientes.id_nf
   SET  tbCTE_NF.cod_emp_entrega = tbprog_entregas.cod_emp
       ,tbCTE_NF.cod_fil_entrega = tbprog_entregas.cod_fil
       ,tbCTE_NF.ano_entrega     = tbprog_entregas.ano_entrega
       ,tbCTE_NF.num_entrega     = tbprog_entregas.num_entrega;
       #,tbprog_entregas.valor_entrega = tbTMPCTE_Terc.vlr_tot_ctrc;
       
   SELECT ROW_COUNT() INTO xQtdeAtualizada;
   SET MENSAGEM = CONCAT("Conciliação realizada com sucesso - Registros Atualizados : ",xQtdeAtualizada);
   
   
   
   
   #Calcular o Rateio do FRETE das entregas vinculadas
   DROP TEMPORARY TABLE IF EXISTS tbTMSCTE_Calcular;
   CREATE TEMPORARY TABLE tbTMSCTE_Calcular
   SELECT tbCTE.cod_emp, tbCTE.cod_fil, tbCTE.cnpj_cpf_emi, tbCTE.num_ctrc, tbCTE.serie_ctrc, tbCTE.vlr_tot_ctrc,
          (SELECT SUM(tbprog_entregas.peso_brt_entre)
           FROM tbprog_entregas
           INNER JOIN tbtms_ctrc_terc2 ON 
                      tbtms_ctrc_terc2.cod_emp     = tbprog_entregas.cod_emp
                  AND tbtms_ctrc_terc2.cod_fil     = tbprog_entregas.cod_fil
                  AND tbtms_ctrc_terc2.ano_entrega = tbprog_entregas.ano_entrega 
                  AND tbtms_ctrc_terc2.num_entrega = tbprog_entregas.num_entrega
           WHERE tbCTE_NF.cod_emp       = tbtms_ctrc_terc2.cod_emp
             AND tbCTE_NF.cod_fil       = tbtms_ctrc_terc2.cod_fil
             AND tbCTE_NF.cnpj_cpf_emi  = tbtms_ctrc_terc2.cnpj_cpf_emi
             AND tbCTE_NF.num_ctrc      =  tbtms_ctrc_terc2.num_ctrc
             AND tbCTE_NF.serie_ctrc    = tbtms_ctrc_terc2.serie_ctrc
          ) PesoTotNFs,
          (SELECT SUM(tbnf_clientes.vlr_tot_nf)
           FROM tbprog_entregas
           INNER JOIN tbtms_ctrc_terc2 ON 
                      tbtms_ctrc_terc2.cod_emp     = tbprog_entregas.cod_emp
                  AND tbtms_ctrc_terc2.cod_fil     = tbprog_entregas.cod_fil
                  AND tbtms_ctrc_terc2.ano_entrega = tbprog_entregas.ano_entrega 
                  AND tbtms_ctrc_terc2.num_entrega = tbprog_entregas.num_entrega
           INNER JOIN tbnf_clientes ON tbnf_clientes.id_nf = tbprog_entregas.id_nf
           WHERE tbCTE_NF.cod_emp       = tbtms_ctrc_terc2.cod_emp
             AND tbCTE_NF.cod_fil       = tbtms_ctrc_terc2.cod_fil
             AND tbCTE_NF.cnpj_cpf_emi  = tbtms_ctrc_terc2.cnpj_cpf_emi
             AND tbCTE_NF.num_ctrc      =  tbtms_ctrc_terc2.num_ctrc
             AND tbCTE_NF.serie_ctrc    = tbtms_ctrc_terc2.serie_ctrc
          ) ValorTotNFs
   FROM tbTMPCTE_Terc tbCTE
   INNER JOIN tbtms_ctrc_terc2 tbCTE_NF ON 
         tbCTE_NF.cod_emp      = tbCTE.cod_emp
     AND tbCTE_NF.cod_fil      = tbCTE.cod_fil
     AND tbCTE_NF.cnpj_cpf_emi = tbCTE.cnpj_cpf_emi
     AND tbCTE_NF.num_ctrc     = tbCTE.num_ctrc
     AND tbCTE_NF.serie_ctrc   = tbCTE.serie_ctrc
   WHERE tbCTE_NF.cod_emp IS NOT NULL 
   AND tbCTE_NF.valor_frete IS NULL
   GROUP BY cod_emp, cod_fil, cnpj_cpf_emi, num_ctrc, serie_ctrc
   ; 
   
   #select * from tbTMSCTE_Calcular;   
   
   UPDATE tbtms_ctrc_terc2
   INNER JOIN tbprog_entregas ON 
              tbtms_ctrc_terc2.cod_emp     = tbprog_entregas.cod_emp 
          AND tbtms_ctrc_terc2.cod_fil     = tbprog_entregas.cod_fil
          AND tbtms_ctrc_terc2.ano_entrega = tbprog_entregas.ano_entrega 
          AND tbtms_ctrc_terc2.num_entrega = tbprog_entregas.num_entrega
   INNER JOIN tbTMSCTE_Calcular ON
         tbtms_ctrc_terc2.cod_emp      = tbTMSCTE_Calcular.cod_emp
     AND tbtms_ctrc_terc2.cod_fil      = tbTMSCTE_Calcular.cod_fil
     AND tbtms_ctrc_terc2.cnpj_cpf_emi = tbTMSCTE_Calcular.cnpj_cpf_emi
     AND tbtms_ctrc_terc2.num_ctrc     = tbTMSCTE_Calcular.num_ctrc
     AND tbtms_ctrc_terc2.serie_ctrc   = tbTMSCTE_Calcular.serie_ctrc
   SET tbtms_ctrc_terc2.valor_frete = ROUND(tbTMSCTE_Calcular.vlr_tot_ctrc / PesoTotNFs * tbprog_entregas.peso_brt_entre,2);
   
   SET xQtdeAtualizada = ROW_COUNT();
   SET MENSAGEM = CONCAT(MENSAGEM," / Fretes Rateio : ",xQtdeAtualizada);
  
   #Calcular o frete das entregas vinculadas
   DROP TEMPORARY TABLE IF EXISTS tbTMSCTE_Calcular;
   CREATE TEMPORARY TABLE tbTMSCTE_Calcular
      SELECT IFNULL(data_viagem, data_progr) data_viagem, tbprog_entregas.cod_emp, tbprog_entregas.cod_fil, tbprog_entregas.chave_integracao
      FROM tbTMPCTE_Terc
      INNER JOIN tbnf_clientes ON 
                 tbnf_clientes.chave_nfe = tbTMPCTE_Terc.chave_nfe
      INNER JOIN tbprog_entregas ON 
                 tbprog_entregas.id_nf = tbnf_clientes.id_nf
      LEFT JOIN tbviagens ON 
                 tbprog_entregas.cod_emp    = tbviagens.cod_emp 
             AND tbprog_entregas.cod_fil    = tbviagens.cod_fil
             AND tbprog_entregas.ano_viagem = tbviagens.ano_viagem 
             AND tbprog_entregas.num_viagem = tbviagens.num_viagem
      WHERE tbprog_entregas.valor_entrega IS NULL; 
   
   SET xQtdeAtualizada = 0;
   WHILE EXISTS (SELECT 1 FROM tbTMSCTE_Calcular) DO
   
      SELECT data_viagem, cod_emp, cod_fil, chave_integracao 
      INTO xdata_viagem, xcod_emp, xcod_fil, xchave_integracao 
      FROM tbTMSCTE_Calcular LIMIT 1;
   
      CALL PROC_TMS_FRETE_TERCEIROS_BUSCAR(xdata_viagem, xcod_emp, xcod_fil, xchave_integracao, 3);
       
      DELETE FROM tbTMSCTE_Calcular
      WHERE chave_integracao = xchave_integracao;
      SET xQtdeAtualizada= xQtdeAtualizada + 1;
   END WHILE;
   SET MENSAGEM = CONCAT(MENSAGEM," / Fretes Calculados : ",xQtdeAtualizada);
   
   DROP TEMPORARY TABLE IF EXISTS tbTMSCTE_Calcular;
   DROP TEMPORARY TABLE IF EXISTS tbTMPCTE_Terc;
   
   IF excecao = 1 THEN
      SET RESULTADO = "0";
      SET MENSAGEM = "Erro SQL - Verifique com o Administrador";
   END IF;
   
END$$

DELIMITER ;