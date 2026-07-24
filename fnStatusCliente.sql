DELIMITER $$

DROP FUNCTION IF EXISTS `fnStatusCliente`$$

CREATE FUNCTION `fnStatusCliente`(
   oStatusProcesso    VARCHAR(20),
   oStatusEntrega     VARCHAR(20),
   oStatusBaixa       VARCHAR(20)
   #oDescrStatusBaixa  VARCHAR(50)
) RETURNS TEXT CHARSET latin1
    NO SQL
BEGIN
   /************************************************************************************/
   # Author David Ruy <2024-11-22> Função que monta instrução CASE para condições de Status do Cliente
   /************************************************************************************/
   DECLARE xidStatusSAP INT;
   DECLARE xCodStatusSAP VARCHAR(20);
   DECLARE xDescrStatusSAP VARCHAR(100);
   DECLARE xFormatoRetorno INT;
   DECLARE xStatusProcessoSLIN VARCHAR(50);
   DECLARE xStatusEntregaSLIN VARCHAR(50);
   DECLARE xStatusBaixaSLIN VARCHAR(50);
   DECLARE xCondStatusSAP VARCHAR(200);
   DECLARE xStrCase TEXT;
   DECLARE xStatusCliente TEXT;
   DECLARE xCaseLinha TEXT;
   
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   CREATE TEMPORARY TABLE tbTMPAux (SELECT * FROM tbintegraSAP_StatusWMS ORDER BY IdStatusSAP);
   
   SET xStrCase = " Case True ";
   WHILE EXISTS (SELECT 1 FROM tbTMPAux) DO
   
      SELECT idStatusSAP, CodStatusSAP, DescrStatusSAP, FormatoRetorno, StatusProcessoSLIN, StatusEntregaSLIN, StatusBaixaSLIN, CondStatusSAP
      INTO xidStatusSAP, xCodStatusSAP, xDescrStatusSAP, xFormatoRetorno, xStatusProcessoSLIN, xStatusEntregaSLIN, xStatusBaixaSLIN, xCondStatusSAP
      FROM tbTMPAux
      LIMIT 1;
      
      SET xCaseLinha = '';
      
      SET xDescrStatusSAP = REPLACE(xDescrStatusSAP,"DescrStatusBaixa",of_logistica.fnStatusBaixaEntrega(oStatusBaixa));
      
      IF xStatusProcessoSLIN IS NOT NULL THEN
         #SET xStrCase = CONCAT(xStrCase, CONCAT(' when oStatusProcesso ',xStatusProcessoSLIN,' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"'));
         SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when oStatusProcesso ',xStatusProcessoSLIN));
      END IF;
      
      IF xStatusEntregaSLIN IS NOT NULL THEN
         #SET xStrCase = CONCAT(xStrCase, CONCAT(' when oStatusEntrega ',xStatusEntregaSLIN,' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"'));
         IF xCaseLinha = '' THEN
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when oStatusEntrega ',xStatusEntregaSLIN));
         ELSE
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' and oStatusEntrega ',xStatusEntregaSLIN));
         END IF;
      END IF;
      IF xStatusBaixaSLIN IS NOT NULL THEN 
         #SET xStrCase = CONCAT(xStrCase, CONCAT(' when oStatusBaixa ',xStatusBaixaSLIN,' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"'));
         IF xCaseLinha = '' THEN
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when oStatusBaixa ',xStatusBaixaSLIN));
         ELSE
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' and oStatusBaixa ',xStatusBaixaSLIN));
         END IF;
      END IF;
      
      IF xCondStatusSAP IS NOT NULL THEN
         IF xCaseLinha = '' THEN
            SET xCaseLinha = CONCAT(xCaseLinha, CONCAT(' when ', xCondStatusSAP));
         ELSE
            SET xCaseLinha = CONCAT(xCaseLinha, ' and ', xCondStatusSAP);
         END IF;
      END IF;
      
      IF xFormatoRetorno = 1 THEN
         SET xStrCase = CONCAT(xStrCase, xCaseLinha, ' then "',xCodStatusSAP,'"');
      ELSEIF xFormatoRetorno = 2 THEN
         SET xStrCase = CONCAT(xStrCase, xCaseLinha, ' then "',xDescrStatusSAP,'"');
      ELSEIF xFormatoRetorno = 3 THEN
         SET xStrCase = CONCAT(xStrCase, xCaseLinha, ' then "',CONCAT(xCodStatusSAP,' - ',xDescrStatusSAP),'"');
      END IF;
      
      DELETE FROM tbTMPAux WHERE idStatusSAP = xidStatusSAP;
      
   END WHILE;
   
   SET xStrCase = CONCAT(xStrCase, ' ELSE "N/A"');
   SET xStrCase = CONCAT(xStrCase,' end into @xStatusCliente');
     
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   
   SET xStatusCliente = CONCAT('SELECT ',xStrCase);
   #PREPARE SQL_StatusCliente FROM @xStatusCliente;
   #EXECUTE SQL_StatusCliente; #USING @a, @b;
   #DEALLOCATE PREPARE SQL_StatusCliente;
   RETURN xStatusCliente;
   
END$$

DELIMITER ;