create or replace procedure PRC_MLAPI_AUNCIOS_ENV
(
  P_MERC_LIVRE_ANUNCIO_ID in MERC_LIVRE_ANUNCIO.MERC_LIVRE_ANUNCIO_ID %type,
  P_MLAN_ID               in MERC_LIVRE_ANUNCIO.MLAN_ID               %type,
  P_MLAN_ERRO             in MERC_LIVRE_ANUNCIO.MLAN_ERRO             %type

) is
begin
  
  if P_MLAN_ERRO is not null then
    update MERC_LIVRE_ANUNCIO M
       set M.MLAN_ERRO = P_MLAN_ERRO
     where M.MERC_LIVRE_ANUNCIO_ID = P_MERC_LIVRE_ANUNCIO_ID;    
  else
    update MERC_LIVRE_ANUNCIO M
       set M.MLAN_DATA_ENVIO = sysdate,
           M.MLAN_ID         = P_MLAN_ID,
           M.MLAN_ACAO       = null,
           M.MLAN_ERRO       = null
     where M.MERC_LIVRE_ANUNCIO_ID = P_MERC_LIVRE_ANUNCIO_ID;
  end if;
       
  commit;

end PRC_MLAPI_AUNCIOS_ENV;
/
