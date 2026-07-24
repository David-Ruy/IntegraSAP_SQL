DELIMITER $$

DROP FUNCTION IF EXISTS `fnContarEmbalagens`$$

CREATE FUNCTION `fnContarEmbalagens`( 
   oString VARCHAR(500)
) RETURNS VARCHAR(500) CHARSET latin1
    NO SQL
BEGIN
   DECLARE xvar_str VARCHAR(500) DEFAULT oString;
   DECLARE xstr VARCHAR(500);
   DECLARE xvar_retorno VARCHAR(100);
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   CREATE TEMPORARY TABLE tbTMPAux (Coluna01 VARCHAR(30));
   
   SET @x1 = 0;
   WHILE LENGTH(xvar_str) > 0 DO
      IF LOCATE(',',xvar_str) > 0 THEN
         SET xstr = SUBSTR(xvar_str,01,LOCATE(',',xvar_str)-1);
      ELSE
         SET xstr = SUBSTR(xvar_str,01,LENGTH(xvar_str));
      END IF;
      
      SET xvar_str = SUBSTRING(REPLACE(xvar_str, xstr, ''),2,100);
      
      IF LENGTH(xstr) > 0 THEN
         INSERT INTO tbTMPAux VALUES (xstr);
      END IF;
      
      #if @X1 = 3 then
      #   return concat('aqui',xstr,"|",xvar_str);
      #end if;
      #set @X1 =@X1 + 1;
      
   END WHILE;
   
   
   #select group_concat(Coluna01) into xvar_str from tbTMPAux;
   #return xvar_str;
   
   SELECT GROUP_CONCAT(EmbAux) INTO xvar_str
   FROM (
         (SELECT CONCAT(COUNT(Emb),SUBSTRING(Emb,1,1)) EmbAux FROM
            (SELECT DISTINCT coluna01, REPLACE(coluna01, fnSoNumeros(coluna01,''),"") Emb
             FROM tbTMPAux) tbAux
         GROUP BY Emb) 
         ) Tb2;
   
   DROP TEMPORARY TABLE IF EXISTS tbTMPAux;
   
   RETURN TRIM(REPLACE(xvar_str,',',''));
   
END$$

DELIMITER ;