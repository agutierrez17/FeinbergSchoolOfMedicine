CREATE OR REPLACE FUNCTION FSMDegreesList (InID IN VARCHAR2) RETURN VARCHAR2 IS
   DegreeData     VARCHAR2(1000);
   School         VARCHAR2(40);
   DegreeCode     VARCHAR2(5);
   DegreeYear     VARCHAR2(4);
   SchoolCode     VARCHAR2(10);
   DegreeType     CHAR(1);

   CURSOR DegreesCursor IS
      SELECT NVL(TS.SHORT_DESC, 'Unknown') SHORT_DESC,
             DEGREE_CODE,
             DEGREE_YEAR,
             D.SCHOOL_CODE,
             D.DEGREE_TYPE
        FROM DEGREES D,
             TMS_SCHOOL TS
       WHERE ID_NUMBER        = InID
         AND INSTITUTION_CODE = '31173'
         AND D.SCHOOL_CODE    = TS.SCHOOL_CODE (+)  -- 10/30/19 MADE INTO OUTER JOIN; BLANK SCHOOL CAUSED NO RETURN
         AND D.SCHOOL_CODE = 'MED'
       GROUP BY NVL(TS.SHORT_DESC, 'Unknown'),
                DEGREE_CODE,
                DEGREE_YEAR,
                D.SCHOOL_CODE,
                D.DEGREE_TYPE,
                DEGREE_LEVEL_CODE
       ORDER BY DEGREE_YEAR,
                DEGREE_LEVEL_CODE;
                
BEGIN
   IF RTRIM(InID) IS NULL THEN
      RETURN NULL;
   END IF;
   
   OPEN DegreesCursor;
   LOOP
      FETCH DegreesCursor
       INTO School,
            DegreeCode,
            DegreeYear,
            SchoolCode,
            DegreeType;
      EXIT WHEN DegreesCursor%NOTFOUND;
            
      DegreeData := DegreeData || ' ' ||
                    School     || ', ' ||
                    DegreeCode || ', ' ||
                    DegreeYear || ';';
   END LOOP;
   CLOSE DegreesCursor;
   RETURN LTRIM(DegreeData);
END;
