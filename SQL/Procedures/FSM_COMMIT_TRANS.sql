CREATE OR REPLACE PROCEDURE RPT_RVA7647.FSM_COMMITS_TRANSFER

AS

BEGIN
  
   EXECUTE IMMEDIATE 'DROP TABLE FSM_COMMITS_TRANS';
   
   EXECUTE IMMEDIATE 'CREATE TABLE FSM_COMMITS_TRANS AS SELECT * FROM FSM_COMMITS';
   
END FSM_COMMITS_TRANSFER;
