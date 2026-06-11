create or replace procedure desenv.PRC_MLAPI_CLIENTE
(
  -- Parametros relativos aos campos da tabela...
  P_MERC_LIVRE_ORDEM_ID in out MERC_LIVRE_ORDEM.MERC_LIVRE_ORDEM_ID %type,
  P_PARCEIRO_ID         in out PARCEIRO.PARCEIRO_ID                 %type,
  P_ENDERECO_ID         in out ENDERECO.ENDERECO_ID                 %type,

  -- Parametros de Controle... 
  P_ACTION       in out integer, 
  P_STATUS       in out varchar2, 
  P_TRANSACTION  in out integer, 
  P_USER         in out varchar2, 
  P_TERMINAL     in out varchar2, 
  P_MESSAGE      in out varchar2
  
) is

  V_ACTION            number;
  V_TRANSACTION       number;
  V_NULL              varchar2(500);  
  V_PRCR_NR_ENDERECO  PARCEIRO.PRCR_NR_ENDERECO %type;
  V_CEPX_CODIGO       CEP.CEPX_CODIGO           %type;
  V_BRRO_NOME         BAIRRO.BRRO_NOME          %type;
  V_PRCL_LIMCRE       PARAM_CLIENTE.PRCL_LIMCRE %type;

begin

  if P_ACTION = 101 then
    
    -- Lista os dados do pedido...
    for C_TC in (select * from MERC_LIVRE_ORDEM where MERC_LIVRE_ORDEM_ID = P_MERC_LIVRE_ORDEM_ID) loop
       -- Endereço...
       for C_TE in (select * from MERC_LIVRE_ORDEM_END where MLOE_ORDER_ID = C_TC.MLOR_ORDER_ID) loop
         -- Verifica se o parceiro está cadastrado...
         begin
           select P.PARCEIRO_ID,
                  P.PRCR_NR_ENDERECO,
                  C.CEPX_CODIGO,
                  B.BRRO_NOME
             into P_PARCEIRO_ID,
                  V_PRCR_NR_ENDERECO,
                  V_CEPX_CODIGO,
                  V_BRRO_NOME              
             from PARCEIRO P, CEP C, BAIRRO B
            where P.PRCR_CGC_CPF = C_TC.MLOR_CPF_CNPJ
              and P.CEP_ID       = C.CEP_ID(+)
              and P.BAIRRO_ID    = B.BAIRRO_ID(+)
              and P.STATUS       = 'Ativo';
         exception when NO_DATA_FOUND then
           P_PARCEIRO_ID := null;  
         end;
         
         if P_PARCEIRO_ID is null then
           -- Cadastra o parceiro...
           P_ENDERECO_ID := null;
           V_PRCL_LIMCRE := C_TC.MLOR_VALOR + C_TC.MLOR_VLR_FRETE + 10;
           V_NULL        := null;
           V_ACTION      := 101;
           V_TRANSACTION := 1;
           
           PRC_MLAPI_CLIENTE_INSERT(P_UNIDADE_EMPRESARIAL_ID => C_TC.UNIDADE_EMPRESARIAL_ID,
                                    P_PARCEIRO_ID            => P_PARCEIRO_ID,
                                    P_PRCR_CGC_CPF           => C_TC.MLOR_CPF_CNPJ,
                                    P_PRCR_NOME              => C_TC.MLOR_NOME,
                                    P_PRCR_ENDERECO          => C_TE.MLOE_ENDERECO,
                                    P_PRCR_COMPLEMENTO_END   => C_TE.MLOE_COMPLEMENTO,
                                    P_PRCR_NR_ENDERECO       => C_TE.MLOE_NUMERO,
                                    P_CEPX_CODIGO            => C_TE.MLOE_CEP,
                                    P_BRRO_NOME              => C_TE.MLOE_BAIRRO,
                                    P_PRCR_FONE              => V_NULL,
                                    P_PRCR_CELULAR           => V_NULL,
                                    P_PRCR_E_MAIL            => V_NULL,
                                    P_PSJR_INSCRICAO_EST     => V_NULL,
                                    P_PSJR_NOME_FANTASIA     => V_NULL,
                                    P_PRCL_LIMCRE            => V_PRCL_LIMCRE,
                                    P_ACTION                 => V_ACTION,
                                    P_STATUS                 => P_STATUS,
                                    P_TRANSACTION            => V_TRANSACTION,
                                    P_USER                   => P_USER,
                                    P_TERMINAL               => P_TERMINAL,
                                    P_MESSAGE                => P_MESSAGE);      
         
         else
           -- Verifica se o endereço está igual...
           if (nvl(V_PRCR_NR_ENDERECO,'X') <> nvl(C_TE.MLOE_NUMERO,'X')) or
              (nvl(V_CEPX_CODIGO,'X')      <> nvl(C_TE.MLOE_CEP,'X'))    or
              (nvl(V_BRRO_NOME,'X')        <> nvl(C_TE.MLOE_BAIRRO,'X')) then
             
             -- Localiza o endereço de entrega...
             begin
               select E.ENDERECO_ID
                 into P_ENDERECO_ID
                 from ENDERECO E,
                      CEP      C,
                      BAIRRO   B
                where E.PARCEIRO_ID = P_PARCEIRO_ID
                  and E.CEP_ID      = C.CEP_ID
                  and E.BAIRRO_ID   = B.BAIRRO_ID
                  and E.ENDR_NUMERO = C_TE.MLOE_NUMERO
                  and C.CEPX_CODIGO = C_TE.MLOE_CEP
                  and B.BRRO_NOME   = C_TE.MLOE_BAIRRO                
                  and E.STATUS      = 'Ativo'
                  and rownum       <= 1;
             exception when NO_DATA_FOUND then
               P_ENDERECO_ID := null;
             end;
             
             if P_ENDERECO_ID is null then
              -- Cadastra um novo endereço de entrega...
              P_ENDERECO_ID := null;
              V_NULL        := null;
              V_ACTION      := 101;
              V_TRANSACTION := 1;
              
              PRC_MLAPI_ENDERECO_INSERT(P_ENDERECO_ID               => P_ENDERECO_ID,
                                        P_PARCEIRO_ID               => P_PARCEIRO_ID,  
                                        P_CEPX_CODIGO               => C_TE.MLOE_CEP,
                                        P_BRRO_NOME                 => C_TE.MLOE_BAIRRO,
                                        P_ENDR_ENDERECO             => C_TE.MLOE_ENDERECO,
                                        P_ENDR_NUMERO               => C_TE.MLOE_NUMERO,
                                        P_ENDR_COMPLEMENTO_ENDERECO => C_TE.MLOE_COMPLEMENTO,
                                        P_ENDR_REFERENCIA           => V_NULL,
                                        P_ACTION                    => V_ACTION,
                                        P_STATUS                    => P_STATUS,
                                        P_TRANSACTION               => V_TRANSACTION,
                                        P_USER                      => P_USER,
                                        P_TERMINAL                  => P_TERMINAL,
                                        P_MESSAGE                   => P_MESSAGE);
             end if;                          
           end if;
         end if;      
      end loop;      
    end loop;
      
  end if;
  
  if P_TRANSACTION = 0 then
    commit;
  end if;
  
end PRC_MLAPI_CLIENTE;
/

