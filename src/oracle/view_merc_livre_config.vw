create or replace force view horus.view_merc_livre_config as
select M.UNIDADE_EMPRESARIAL_ID,
         M.MLCN_CLIENT_ID,
         M.MLCN_CLIENT_SECRET,
         M.MLCN_CODE,
         M.MLCN_REDIRECT_URI,
         M.MLCN_TOKEN,
         M.MLCN_ACCESS_TOKEN,
         M.MLCN_USER_ID,
         M.MLCN_TOKEN_DT_VAL,

         case
            when M.MLCN_TOKEN is null then
              'S'
            when M.MLCN_TOKEN_DT_VAL is null then
              'S'
            when M.MLCN_TOKEN_DT_VAL < sysdate then
              'S'
            else
              'N'
         end EXPIRES

    from MERC_LIVRE_CONFIG M;

