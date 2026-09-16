# Controle de Lançamento de Estoque na Padaria Pão Pão

A ideia desse projeto surgiu de um problema q eu tenho enfrentado no trabalho. Atualmente atuo como Analista Financeiro e Auxiliar de Escritorio em uma grande padaria. 
Todos os dias o time de produção anota em uma planilha impressa todos os itens que eles vao precisar pra producao do dia de hoje, nisso o nosso funcionario da expedição faz a entrega dos itens e a coleta da planilha. Na maioria das vezes ele acumula 7 dias de planilha antes de me entregar pra eu fazer o lançamento do estoque das materias primas da produção. Porem como esses papeis acumulam, as vezes falta um dia dos 7 que talvez ele guardou em outro lugar e nao encontrou naquele momento. 

Por Muito tempo eu tento controlar quais ja foram lançados e quais não, porem as vezes me confundo e nao sei se algum dia ja foi lançado ou não, ou ate lançado duas vezes, por conta dessa confusao. Decidi então montar uma estrutura simples para resolver isso de vez, e aproveitei para transformar essa solução em um projeto de portfólio, já que estou no terceiro semestre de Análise e Desenvolvimento de Sistemas na FIAP e queria algo que unisse um problema real com prática de ferramentas de dados. 

## O problema

Cada planilha de estoque impressa tem uma data de referência e precisa ser lançada no Datamaxi em algum momento depois. Sem um controle, era comum descobrir tarde demais que uma folha antiga ainda estava pendente e entao ocasionar uma diferença no estoque no final do mes,ou simplesmente perder o histórico de quantas folhas já tinham sido processadas em um mês. Eu precisava de uma forma rápida de olhar e responder duas perguntas: quantas folhas estão pendentes agora, e quais são elas.

## Como resolvi

O projeto foi montado em três etapas, cada uma resolvendo uma coisa e se conversando entre si.

### Captura dos dados no Google Sheets

A primeira etapa foi criar uma planilha para registrar cada folha de estoque. Optei pelo Google Sheets porque não tenho licença do Office na padaria (só existe uma versão bem antiga do Excel disponível por lá), e também porque nunca tinha trabalhado a fundo com Sheets antes, então virou um desafio pra mim aprender a ferramenta na prática.

A planilha tem uma aba por mês. Cada linha representa uma folha de estoque, com um ID gerado automaticamente por fórmula, a data da folha, o status (lançada ou não lançada) através de uma lista suspensa com formatação condicional, e a data em que o lançamento foi feito no Datamaxi. Usei a lista suspensa em vez de digitação livre no campo de status propositalmente, para evitar erro de digitação, o que facilita muito na hora de tratar esses dados depois.

### Tratamento e armazenamento no MySQL

Com os dados sendo capturados, precisava levar isso para um banco de dados de verdade, tanto para ter um histórico consistente quanto para reforçar e praticar meu SQL.

Criei o banco padaria_estoque com duas tabelas. Uma tabela de staging (staging_estoque), que recebe os dados brutos exportados da planilha em CSV, com todas as colunas em formato texto. E uma tabela final (folhas_estoque), já com os tipos corretos: id_folha como inteiro com incremento automático, data_folha e data_lancamento como datas, e status como texto.

A ideia de usar uma tabela intermediária de staging foi para separar a etapa de importação bruta da etapa de tratamento. Os dados chegam confusos, sem tipo, e às vezes com campos vazios (quando uma folha ainda não foi lançada, por exemplo, a data de lançamento vem em branco). Criei uma stored procedure para facilitar a conversão:

```sql
DELIMITER $$

CREATE PROCEDURE sp_importar_staging()
BEGIN
    INSERT INTO folhas_estoque (data_folha, status, data_lancamento)
    SELECT
        STR_TO_DATE(col2, '%d/%m/%Y'),
        col3,
        STR_TO_DATE(NULLIF(col4, ''), '%d/%m/%Y')
    FROM staging_estoque;

    TRUNCATE TABLE staging_estoque;
END$$

DELIMITER //
```

Ela converte as datas do formato brasileiro para o formato do banco, trata o campo de data de lançamento vazio com NULLIF (senão o STR_TO_DATE quebra tentando converter uma string vazia), insere tudo na tabela final e limpa para o próximo lote. Assim, todo mês eu só preciso exportar a planilha em CSV, carregar na staging com um LOAD DATA e rodar a procedure. E é reutilizavel pros proximos meses, entao não vou ter que fazer mais nada no proximo mes.

### Visualização no Power BI

Por fim, montei um dashboard no Power BI conectado direto no banco MySQL, com três indicadores no topo mostrando o total de folhas, quantas já foram lançadas e quantas ainda estão pendentes. Abaixo tem uma tabela filtrada só com as folhas pendentes, para eu saber exatamente quais preciso lançar, e um gráfico de colunas comparando lançadas contra pendentes mês a mês.

## Por que ficou simples assim

Esse dashboard não tem medidas complexas em DAX, nem filtros interativos, nem um tema visual customizado. Optei por isso, não foi uma limitação. O objetivo aqui era resolver o meu problema real de trabalho da forma mais rápida possível: ter uma visão clara do que está pendente sem precisar abrir planilha nenhuma. Preferi entregar algo funcional rápido do que passar tempo demais deixando bonito antes de validar se a solução realmente resolvia o problema no dia a dia. Com o uso real, dá para ver com mais clareza o que realmente vale a pena melhorar depois.

## Tecnologias usadas

* Google Sheets, para captura estruturada dos dados
* MySQL Server e MySQL Workbench, para armazenamento e tratamento dos dados
* Power BI Desktop, para o dashboard final

## Próximos passos

Algumas melhorias que ficaram de fora dessa primeira versão e que pretendo incluir com calma:

* Medida em DAX para calcular o percentual de folhas pendentes automaticamente
* Filtro (slicer) por mês no dashboard, para não depender só do gráfico
* Ajuste de tema visual e cores do Power BI
* Automatizar a atualização dos dados, hoje ainda feita de forma manual

## Sobre o projeto

Esse é um projeto pessoal que comecei para resolver um problema real do meu trabalho na Padaria Pão Pão e que também uso como parte do meu portfólio enquanto estudo Análise e Desenvolvimento de Sistemas na FIAP.
