create or replace procedure desenv.PRC_MLAPI_ORDEM_END_UPDATE
(
  P_MLOE_ORDER_ID          in  MERC_LIVRE_ORDEM_END.MLOE_ORDER_ID          %type,
  P_MLOE_ENDERECO          in  MERC_LIVRE_ORDEM_END.MLOE_ENDERECO          %type,
  P_MLOE_NUMERO            in  MERC_LIVRE_ORDEM_END.MLOE_NUMERO            %type,
  P_MLOE_COMPLEMENTO       in  MERC_LIVRE_ORDEM_END.MLOE_COMPLEMENTO       %type,
  P_MLOE_BAIRRO            in  MERC_LIVRE_ORDEM_END.MLOE_BAIRRO            %type,
  P_MLOE_CIDADE            in  MERC_LIVRE_ORDEM_END.MLOE_CIDADE            %type,
  P_MLOE_UF                in  MERC_LIVRE_ORDEM_END.MLOE_UF                %type,
  P_MLOE_CEP               in  MERC_LIVRE_ORDEM_END.MLOE_CEP               %type,

  P_TRANSACTION            in  number

) is

  V_MERC_LIVRE_ORDEM_END_ID  MERC_LIVRE_ORDEM_END.MERC_LIVRE_ORDEM_END_ID %type;

begin

   begin
     select M.MERC_LIVRE_ORDEM_END_ID
       into V_MERC_LIVRE_ORDEM_END_ID
       from MERC_LIVRE_ORDEM_END M
      where MLOE_ORDER_ID = P_MLOE_ORDER_ID;
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_ORDEM_END_ID := null;
   end;

   if V_MERC_LIVRE_ORDEM_END_ID is null then
     V_MERC_LIVRE_ORDEM_END_ID := GENERATE_NEXT_ID('MERC_LIVRE_ORDEM_END','UserSystem','TermSystem');

     insert into MERC_LIVRE_ORDEM_END(MERC_LIVRE_ORDEM_END_ID ,MLOE_ORDER_ID     ,
                                      MLOE_ENDERECO           ,MLOE_NUMERO       ,
                                      MLOE_COMPLEMENTO        ,MLOE_BAIRRO       ,
                                      MLOE_CIDADE             ,MLOE_UF           ,
                                      MLOE_CEP                ,
                                      USUARIO_INCLUSAO        ,DATA_INCLUSAO     ,
                                      STATUS                  )

     values                          (V_MERC_LIVRE_ORDEM_END_ID  ,P_MLOE_ORDER_ID     ,
                                      P_MLOE_ENDERECO            ,P_MLOE_NUMERO       ,
                                      P_MLOE_COMPLEMENTO         ,P_MLOE_BAIRRO       ,
                                      P_MLOE_CIDADE              ,P_MLOE_UF           ,
                                      P_MLOE_CEP                 ,
                                      'UserSystem'               ,sysdate             ,
                                      'Ativo'                    );
   else
     update MERC_LIVRE_ORDEM_END
        set MLOE_ENDERECO     = P_MLOE_ENDERECO,
            MLOE_NUMERO       = P_MLOE_NUMERO,
            MLOE_COMPLEMENTO  = P_MLOE_COMPLEMENTO,
            MLOE_BAIRRO       = P_MLOE_BAIRRO,
            MLOE_CIDADE       = P_MLOE_CIDADE,
            MLOE_UF           = P_MLOE_UF,
            MLOE_CEP          = P_MLOE_CEP,
            DATA_ALTERACAO    = sysdate,
            USUARIO_ALTERACAO = 'UserSystem'
      where MERC_LIVRE_ORDEM_END_ID = V_MERC_LIVRE_ORDEM_END_ID;
   end if;

   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_ORDEM_END_UPDATE;
/

