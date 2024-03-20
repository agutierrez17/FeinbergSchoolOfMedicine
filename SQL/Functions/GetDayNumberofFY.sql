CREATE OR REPLACE FUNCTION GetDayNumberOfFY (InDate IN VARCHAR2,) RETURN VARCHAR2 IS
   DayNumber     VARCHAR2(3);

   CURSOR DateCursor IS
      with x as (
      select 1970 yr from dual
      ),

      fy_starts as (
      SELECT
      TO_DATE(CONCAT('9/1/',yr + (level)),'MM/DD/YYYY') AS dt,
      EXTRACT(YEAR FROM TO_DATE(CONCAT('9/1/',yr + (level)),'MM/DD/YYYY'))+1 as fy
      from x
      connect by level <= extract(year from sysdate)- yr
      ),

      fy AS
      (
      SELECT 
      TO_DATE(InDate,'MM/DD/YYYY') CD,
      CASE WHEN EXTRACT(MONTH FROM TO_DATE(InDate,'MM/DD/YYYY')) >= 9
      THEN EXTRACT(YEAR FROM TO_DATE(InDate,'MM/DD/YYYY'))+1
      ELSE EXTRACT(YEAR FROM TO_DATE(InDate,'MM/DD/YYYY'))
      END FY
      FROM DUAL
      )

      SELECT
      --FY.*,
      --fy_starts.*,
      trunc(FY.CD) - trunc(fy_starts.dt) as DayNumber
      FROM FY
      INNER JOIN fy_starts on FY.FY = fy_starts.FY
                
BEGIN
   IF RTRIM(InDate) IS NULL THEN
      RETURN NULL;
   END IF;
   
   OPEN DateCursor;
   FETCH DateCursor
    INTO DayNumber
   CLOSE DateCursor;
   
   RETURN DayNumber;
END;
