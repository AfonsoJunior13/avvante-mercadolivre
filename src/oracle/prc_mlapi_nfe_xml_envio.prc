create or replace procedure desenv.PRC_MLAPI_NFE_XML_ENVIO
(
  P_UNIDADE_EMPRESARIAL_ID in  MERC_LIVRE_ORDEM.UNIDADE_EMPRESARIAL_ID %type,
  P_MLOR_ORDER_ID          in  MERC_LIVRE_ORDEM.MLOR_ORDER_ID          %type,

  P_TRANSACTION            in  number
) is

  V_MERC_LIVRE_ORDEM_ID  MERC_LIVRE_ORDEM.MERC_LIVRE_ORDEM_ID %type;

begin

   begin
     select M.MERC_LIVRE_ORDEM_ID
       into V_MERC_LIVRE_ORDEM_ID
       from MERC_LIVRE_ORDEM M
      where M.MLOR_ORDER_ID          = P_MLOR_ORDER_ID
        and M.UNIDADE_EMPRESARIAL_ID = P_UNIDADE_EMPRESARIAL_ID;
   exception when NO_DATA_FOUND then
     Raise_application_error(-20000, 'Ordem não encontrada');
   end;

   update MERC_LIVRE_ORDEM
      set MLOR_XML_DT_ENVIO   = sysdate,
          DATA_ALTERACAO      = sysdate,
          USUARIO_ALTERACAO   = 'UserSystem'
    where MERC_LIVRE_ORDEM_ID = V_MERC_LIVRE_ORDEM_ID;

   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_NFE_XML_ENVIO;
/
