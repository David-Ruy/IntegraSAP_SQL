DELIMITER $$

DROP FUNCTION IF EXISTS `fnTirarCaracteresEspeciais`$$

CREATE FUNCTION `fnTirarCaracteresEspeciais`( oString	VARCHAR(50)
) RETURNS VARCHAR(50) CHARSET latin1
    NO SQL
BEGIN
	
	IF IFNULL(oString, '') <> '' THEN 
	BEGIN 
	
   SET oString = REPLACE(oString,'.','');
   SET oString = REPLACE(oString,'-','');
   SET oString = REPLACE(oString,'/','');
   SET oString = REPLACE(oString,',','');
   SET oString = REPLACE(oString,'ƒ','');
#TIL
   SET oString = REPLACE(oString,'Ã','A');
   SET oString = REPLACE(oString,'ã','a');
   SET oString = REPLACE(oString,'õ','o');
   SET oString = REPLACE(oString,'Õ','O');
#CIRCUNFLEXO
   SET oString = REPLACE(oString,'â','a');
   SET oString = REPLACE(oString,'Â','A');
   SET oString = REPLACE(oString,'Ê','E');
   SET oString = REPLACE(oString,'ê','e');
   SET oString = REPLACE(oString,'ô','o');
   SET oString = REPLACE(oString,'Ô','O');
#AGUDO
   SET oString = REPLACE(oString,'Á','A');
   SET oString = REPLACE(oString,'á','a');
   SET oString = REPLACE(oString,'É','E');
   SET oString = REPLACE(oString,'é','e');
   SET oString = REPLACE(oString,'Í','I');
   SET oString = REPLACE(oString,'í','i');
   SET oString = REPLACE(oString,'Ó','O');
   SET oString = REPLACE(oString,'ó','o');
   SET oString = REPLACE(oString,'Ú','U');
   SET oString = REPLACE(oString,'ú','u');
#CRASE
   SET oString = REPLACE(oString,'À','A');
   SET oString = REPLACE(oString,'à','a');
   SET oString = REPLACE(oString,'È','E');
   SET oString = REPLACE(oString,'è','e');
   SET oString = REPLACE(oString,'Ì','I');
   SET oString = REPLACE(oString,'ì','i');
   SET oString = REPLACE(oString,'Ò','O');
   SET oString = REPLACE(oString,'ò','o');
   SET oString = REPLACE(oString,'Ù','U');
   SET oString = REPLACE(oString,'ù','u');
#CEDILHA 
   SET oString = REPLACE(oString,'ç','c');
   SET oString = REPLACE(oString,'Ç','c');
#ORDINAIS
   SET oString = REPLACE(oString,'º','');
   SET oString = REPLACE(oString,'ª','');
   SET oString = REPLACE(oString,'€','');
   SET oString = REPLACE(oString,'¡','');
   SET oString = REPLACE(oString,'£','');
   SET oString = REPLACE(oString,'&','');
   SET oString = REPLACE(oString,'*','');
   
   RETURN oString;
	
	END; 
	ELSE 
 BEGIN 
   
   RETURN oString;	
   
 END; 
	END IF;
	
END$$

DELIMITER ;