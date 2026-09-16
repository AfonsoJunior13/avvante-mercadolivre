create or replace view view_mlapi_estoque as
select TAB.UNIDADE_EMPRESARIAL_ID,
       TAB.MERC_LIVRE_PRODUTO_ID,
       TAB.MLPD_ID,
       TAB.QTDE
  from (select UE.UNIDADE_EMPRESARIAL_ID,
               MLP.MERC_LIVRE_PRODUTO_ID,
               MLP.MLPD_ID,
               min( (ES.ESTQ_QTDE - (nvl(ES.ESTQ_QTDE_RESERVA_VENDA,0) + nvl(ES.ESTQ_QTDE_RESERVA_TRANSF,0))) - nvl(MLPI.MLPT_QTDE_MIN_EST,0) ) QTDE

          from MERC_LIVRE_PRODUTO   MLP,
               MERC_LIVRE_PROD_ITEM MLPI,
               EMBALAGEM_VENDA      EV,
               PRODUTO              PR,
               ESTOQUE              ES,
               SETOR                SE,
               UNIDADE_EMPRESARIAL  UE,
               MERC_LIVRE_CONFIG    MLC

         where MLP.MERC_LIVRE_PRODUTO_ID     = MLPI.MERC_LIVRE_PRODUTO_ID
           and MLPI.EMBALAGEM_VENDA_ID       = EV.EMBALAGEM_VENDA_ID
           and EV.PRODUTO_ID                 = PR.PRODUTO_ID
           and PR.PRODUTO_ID                 = ES.PRODUTO_ID
           and ES.SETOR_ID                   = SE.SETOR_ID
           and SE.UNIDADE_EMPRESARIAL_ID     = UE.UNIDADE_EMPRESARIAL_ID
           and UE.UNIDADE_EMPRESARIAL_ID     = MLC.UNIDADE_EMPRESARIAL_ID
           and nvl(SE.SETR_MERC_LIVRE,'Nao') = 'Sim'

        group by UE.UNIDADE_EMPRESARIAL_ID,
                 MLP.MERC_LIVRE_PRODUTO_ID,
                 MLP.MLPD_ID

        ) TAB;
