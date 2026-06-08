create or replace procedure horus.PRC_MLAPI_CATEGORIA_UPDATE
(
  P_MLCA_ID     in MERC_LIVRE_CATEGORIA.MLCA_ID   %type,
  P_MLCA_NAME   in MERC_LIVRE_CATEGORIA.MLCA_NAME %type,
  
  P_TRANSACTION in number

) is
  
  V_MERC_LIVRE_CATEGORIA_ID  MERC_LIVRE_CATEGORIA.MERC_LIVRE_CATEGORIA_ID %type;

begin
   
   begin
     select M.MERC_LIVRE_CATEGORIA_ID
       into V_MERC_LIVRE_CATEGORIA_ID
       from MERC_LIVRE_CATEGORIA M
      where MLCA_ID = P_MLCA_ID;      
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_CATEGORIA_ID := null; 
   end;
   
   if V_MERC_LIVRE_CATEGORIA_ID is null then
     V_MERC_LIVRE_CATEGORIA_ID := GENERATE_NEXT_ID('MERC_LIVRE_CATEGORIA','UserSystem','TermSystem');
       
     insert into MERC_LIVRE_CATEGORIA(MERC_LIVRE_CATEGORIA_ID    ,MLCA_ID       ,
                                      MLCA_NAME                  , 
                                      USUARIO_INCLUSAO           ,DATA_INCLUSAO ,
                                      STATUS                     )
                                         
     values                          (V_MERC_LIVRE_CATEGORIA_ID  ,P_MLCA_ID     ,
                                      P_MLCA_NAME                , 
                                      'UserSystem'               ,sysdate       ,
                                      'Ativo'                    );     
   else
     update MERC_LIVRE_CATEGORIA
        set MLCA_NAME = P_MLCA_NAME
      where MERC_LIVRE_CATEGORIA_ID = V_MERC_LIVRE_CATEGORIA_ID;
   end if;   
  
   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_CATEGORIA_UPDATE;
/

