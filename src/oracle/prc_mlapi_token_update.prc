create or replace procedure horus.PRC_MLAPI_TOKEN_UPDATE
(
  P_UNIDADE_EMPRESARIAL_ID in varchar2,
  P_MLCN_TOKEN             in varchar2,
  P_MLCN_ACCESS_TOKEN      in varchar2,
  P_MLCN_USER_ID           in varchar2,
  P_TIME_SEC               in number,
  
  P_TRANSACTION            in number
) is
begin

  update MERC_LIVRE_CONFIG M
     set M.MLCN_TOKEN        = P_MLCN_TOKEN,
         M.MLCN_USER_ID      = P_MLCN_USER_ID,
         M.MLCN_ACCESS_TOKEN = P_MLCN_ACCESS_TOKEN,
         M.MLCN_TOKEN_DT_VAL = SYSDATE + NUMTODSINTERVAL(P_TIME_SEC, 'SECOND'),
         M.DATA_ALTERACAO    = sysdate,
         M.USUARIO_ALTERACAO = 'UserSystem',
         M.ORIGEM_ALTERACAO  = 'token'
   where M.UNIDADE_EMPRESARIAL_ID = P_UNIDADE_EMPRESARIAL_ID;

  if P_TRANSACTION = 0 then
    commit;
  end if;
    
end PRC_MLAPI_TOKEN_UPDATE;
/

