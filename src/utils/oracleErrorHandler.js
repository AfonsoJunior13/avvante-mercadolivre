function tratarErroOracle(mensagem) {
    const regex = /ORA-20000:\s*(.*)/;
    const match = mensagem.match(regex);
    if (match && match[1]) {
      return match[1].trim();
    }
    return 'Erro de negócio no Oracle.';
  }
  
  module.exports = { tratarErroOracle };