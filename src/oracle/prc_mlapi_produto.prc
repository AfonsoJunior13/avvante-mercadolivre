create or replace procedure desenv.PRC_MLAPI_PRODUTO
(
  P_MERC_LIVRE_PRODUTO_ID in out MERC_LIVRE_PRODUTO.MERC_LIVRE_PRODUTO_ID %type,
  P_EMBALAGEM_VENDA_ID    in out MERC_LIVRE_PRODUTO.EMBALAGEM_VENDA_ID    %type,
  P_MLPD_QTDE             in out MERC_LIVRE_PRODUTO.MLPD_QTDE             %type,  

  -- Parametros de Controle...
  P_ACTION       in out integer,
  P_STATUS       in out varchar2,
  P_TRANSACTION  in out integer,
  P_USER         in out varchar2,
  P_USER_AUTORIZ in out varchar2,
  P_TERMINAL     in out varchar2,
  P_MESSAGE      in out varchar2

) is
  
  V_ORIG_ACTION  varchar2(50);
  V_PRODUTO_ID   MERC_LIVRE_PRODUTO.PRODUTO_ID %type;
  
begin
  
  V_ORIG_ACTION := GET_ORIGIN_INFO(P_TERMINAL);
  
  if P_ACTION = 101 then   
    
    if P_EMBALAGEM_VENDA_ID is null then
      Raise_application_error(-20000, 'Embalagem de Venda não informado.');
    end if; 
    
    if nvl(P_MLPD_QTDE,0) = 0 then
      P_MLPD_QTDE := 1;  
    end if;
    
    select EV.PRODUTO_ID
      into V_PRODUTO_ID
      from EMBALAGEM_VENDA EV
     where EV.EMBALAGEM_VENDA_ID = P_EMBALAGEM_VENDA_ID;       
  
     update MERC_LIVRE_PRODUTO M
        set M.EMBALAGEM_VENDA_ID = P_EMBALAGEM_VENDA_ID,
            M.PRODUTO_ID         = V_PRODUTO_ID,
            M.MLPD_QTDE          = P_MLPD_QTDE,
            M.DATA_ALTERACAO     = sysdate,
            M.USUARIO_ALTERACAO  = P_USER,
            M.ORIGEM_ALTERACAO   = V_ORIG_ACTION
      where M.MERC_LIVRE_PRODUTO_ID = P_MERC_LIVRE_PRODUTO_ID;
   
   end if;
  
   if P_TRANSACTION = 0 then
     commit;
   end if;

exception 
  when OTHERS then   
      rollback; 
      SYS_TRATA_ERRO;  

end PRC_MLAPI_PRODUTO;
/

