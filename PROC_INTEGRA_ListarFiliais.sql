DELIMITER $$

DROP PROCEDURE IF EXISTS `PROC_INTEGRA_ListarFiliais`$$

CREATE PROCEDURE `PROC_INTEGRA_ListarFiliais`()
BLOCO1:BEGIN
   /*
   #@Author David Ruy <2023/03/20>
   #@Reviser David Ruy <2023/04/05> Join tbintegrasap_depositos
   */
   
   
   DECLARE xIdEmpresa TINYINT DEFAULT 0;
   DECLARE xidBase    TINYINT DEFAULT 1;
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPFiliais ;
   CREATE TEMPORARY TABLE tbTMPFiliais 
      SELECT id_integracao chave_integracao, cnpj_empresa CnpjCpfCli, 
             idBase, SeqCode_NF, 
             cod_emp_slin CodEmpSlin, cod_fil_slin CodFilSlin, 
             raz_social nome_fantasia, raz_social, CardCode_For, CardCode_Cli, estado UF,
             flgMatriz
      FROM tbintegraSAP_empresas
      WHERE flg_ativo = 1;
      #SELECT chave_integracao, num_cnpj CnpjCpfCli, cod_empresa CodEmpSlin, cod_filial CodFilSlin, 
      #       cod_nome nome_fantasia, raz_social
      #FROM of_logistica.tbfiliais
      #WHERE flg_ativo = 'S';
      
   #SELECT * FROM tbTMPFiliais ;   
   
   SELECT chave_integracao, nome_fantasia, raz_social, CnpjCpfCli, tbTMPFiliais.UF,
          CodEmpSlin, CodFilSlin, CardCode_For, CardCode_Cli,
          chave_integracao IdEmpresa, tbintegraSAP_Depositos.cod_deposito,
          tbTMPFiliais.SeqCode_NF, tbTMPFiliais.flgMatriz, 
          tbintegraSAP_bases.*
   FROM tbTMPFiliais 
   LEFT JOIN tbintegraSAP_bases ON
              tbTMPFiliais.idBase = tbintegraSAP_bases.idBase
   LEFT JOIN tbintegraSAP_Depositos ON 
             TRUE #tbintegraSAP_Depositos.idBase = tbTMPFiliais.idBase
         AND tbintegraSAP_Depositos.id_empresa = tbTMPFiliais.chave_integracao
   WHERE IF(xIdEmpresa = 0, TRUE, xIdEmpresa = tbTMPFiliais.chave_integracao AND xidBase = tbTMPFiliais.idBase)
     AND flgAtivo = 1
   GROUP BY chave_integracao;
   #SELECT chave_integracao FROM of_logistica.tbfiliais 
   #WHERE IFNULL(chave_integracao,'') <> '' AND flg_ativo = 'S';
   
END$$

DELIMITER ;