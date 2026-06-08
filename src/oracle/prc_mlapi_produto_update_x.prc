create or replace procedure horus.PRC_MLAPI_PRODUTO_UPDATE_X
(
  P_MLPD_ID                 in out MERC_LIVRE_PRODUTO.MLPD_ID %type,  
  P_TRANSACTION             in out number

) is
  
  V_MERC_LIVRE_PRODUTO_ID  MERC_LIVRE_PRODUTO.MERC_LIVRE_PRODUTO_ID %type;

begin
   
     V_MERC_LIVRE_PRODUTO_ID := GENERATE_NEXT_ID('MERC_LIVRE_PRODUTO','UserSystem','TermSystem');
       
     insert into MERC_LIVRE_PRODUTO(MERC_LIVRE_PRODUTO_ID   ,MLPD_ID       ,
                                    USUARIO_INCLUSAO        ,DATA_INCLUSAO ,
                                    STATUS                  )
                                         
     values                        (V_MERC_LIVRE_PRODUTO_ID ,P_MLPD_ID      ,
                                    'UserSystem'            ,sysdate        ,
                                    'Ativo'                 );     
  
   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_PRODUTO_UPDATE_X;
/

