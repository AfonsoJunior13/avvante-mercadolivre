create or replace procedure desenv.PRC_MLAPI_TP_ANUNCIO_UPDATE
(
  P_MLTA_ID     in MERC_LIVRE_TP_ANUNCIO.MLTA_ID   %type,
  P_MLTA_NAME   in MERC_LIVRE_TP_ANUNCIO.MLTA_NAME %type,

  P_TRANSACTION in number

) is

  V_MERC_LIVRE_TP_ANUNCIO_ID  MERC_LIVRE_TP_ANUNCIO.MERC_LIVRE_TP_ANUNCIO_ID %type;

begin

   begin
     select M.MERC_LIVRE_TP_ANUNCIO_ID
       into V_MERC_LIVRE_TP_ANUNCIO_ID
       from MERC_LIVRE_TP_ANUNCIO M
      where MLTA_ID = P_MLTA_ID;
   exception when NO_DATA_FOUND then
     V_MERC_LIVRE_TP_ANUNCIO_ID := null;
   end;

   if V_MERC_LIVRE_TP_ANUNCIO_ID is null then
     V_MERC_LIVRE_TP_ANUNCIO_ID := GENERATE_NEXT_ID('MERC_LIVRE_TP_ANUNCIO','UserSystem','TermSystem');

     insert into MERC_LIVRE_TP_ANUNCIO(MERC_LIVRE_TP_ANUNCIO_ID   ,MLTA_ID       ,
                                       MLTA_NAME                  ,
                                       USUARIO_INCLUSAO           ,DATA_INCLUSAO ,
                                       STATUS                     )

     values                           (V_MERC_LIVRE_TP_ANUNCIO_ID ,P_MLTA_ID     ,
                                       P_MLTA_NAME                ,
                                       'UserSystem'               ,sysdate       ,
                                       'Ativo'                    );
   else
     update MERC_LIVRE_TP_ANUNCIO
        set MLTA_NAME = P_MLTA_NAME
      where MERC_LIVRE_TP_ANUNCIO_ID = V_MERC_LIVRE_TP_ANUNCIO_ID;
   end if;

   if P_TRANSACTION = 0 then
     commit;
   end if;

end PRC_MLAPI_TP_ANUNCIO_UPDATE;
/

