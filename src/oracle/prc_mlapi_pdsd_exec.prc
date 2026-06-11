create or replace procedure desenv.PRC_MLAPI_PDSD_EXEC
(
  -- Parametros relativos aos campos da tabela...
  P_MERC_LIVRE_ORDEM_ID in out MERC_LIVRE_ORDEM.MERC_LIVRE_ORDEM_ID %type,

  -- Parametros de Controle... 
  P_ACTION       in out integer, 
  P_STATUS       in out varchar2, 
  P_TRANSACTION  in out integer, 
  P_USER         in out varchar2, 
  P_TERMINAL     in out varchar2, 
  P_MESSAGE      in out varchar2
) 
is
  V_ACTION         number;
  V_TRANSACTION    number;
  V_MLOR_OBS_ERRO  varchar2(4000);
begin
  
  if P_ACTION = 101 then
    
    V_ACTION        := 101;
    V_TRANSACTION   := 0;
    V_MLOR_OBS_ERRO := null;
    
    begin
      PRC_MLAPI_PDSD_INSERT(P_MERC_LIVRE_ORDEM_ID ,
                            V_ACTION              ,P_STATUS       , 
                            V_TRANSACTION         ,P_USER         , 
                            P_TERMINAL            ,P_MESSAGE      );     
    exception when others then
      rollback;
      V_MLOR_OBS_ERRO := substr(sqlerrm,1,4000);     
    end;
    
    update MERC_LIVRE_ORDEM M
       set M.MLOR_OBS_ERRO  = V_MLOR_OBS_ERRO,
           M.MLOR_DATA_PDSD = sysdate
     where M.MERC_LIVRE_ORDEM_ID = P_MERC_LIVRE_ORDEM_ID;

  end if;

  if P_TRANSACTION = 0 then
    commit;  
  end if;  
  
end PRC_MLAPI_PDSD_EXEC;
/

