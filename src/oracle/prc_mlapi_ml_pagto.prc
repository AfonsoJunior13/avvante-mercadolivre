create or replace procedure desenv.PRC_MLAPI_ML_PAGTO
(
  P_UNIDADE_EMPRESARIAL_ID in  MERC_LIVRE_ORDEM.UNIDADE_EMPRESARIAL_ID %type,
  P_MLOR_ORDER_ID          in  MERC_LIVRE_ORDEM.MLOR_ORDER_ID          %type,
  P_MLOR_PAGTO_ML_DATA     in  MERC_LIVRE_ORDEM.MLOR_PAGTO_ML_DATA     %type,
  P_MLOR_PAGTO_ML_STATUS   in  MERC_LIVRE_ORDEM.MLOR_PAGTO_ML_STATUS   %type,
  P_MLOR_PAGTO_ML_VLR      in  MERC_LIVRE_ORDEM.MLOR_PAGTO_ML_VLR      %type,

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
     V_MERC_LIVRE_ORDEM_ID := null;
   end;
   
   -- Pedido já gerado não requer modificações...
   if V_MERC_LIVRE_ORDEM_ID is not null then
     Raise_application_error(-20000, 'Ordem não encontrada');
   end if;
   
   update MERC_LIVRE_ORDEM
      set MLOR_PAGTO_ML_DATA    = P_MLOR_PAGTO_ML_DATA,
          MLOR_PAGTO_ML_STATUS  = P_MLOR_PAGTO_ML_STATUS,
          MLOR_PAGTO_ML_VLR     = P_MLOR_PAGTO_ML_VLR,
          MLOR_PAGTO_ML_DT_PROC = sysdate,
          DATA_ALTERACAO        = sysdate,
          USUARIO_ALTERACAO     = 'UserSystem'
    where MERC_LIVRE_ORDEM_ID = V_MERC_LIVRE_ORDEM_ID;

   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_ML_PAGTO;
/

