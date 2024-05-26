--12.Formulați în  limbaj  natural și  implementați 5 cereri  SQL  complexece  vor  utiliza,  în ansamblul lor, următoarele elemente:
--•	subcereri sincronizate în care intervin cel puțin 3 tabele
--•	subcereri nesincronizate în clauza FROM
--•	grupări de date cu  subcereri  nesincronizate  in  care  intervin  cel  putin  3  tabele, funcții grup, filtrare la nivel de grupuri(in cadrul aceleiasi cereri)
--•	ordonări si utilizarea funcțiilor NVL și DECODE (in cadrul aceleiasi cereri)
--•	utilizarea a cel puțin 2 funcții pe șiruri de caractere, 2 funcții pe date calendaristice,  a cel puțin unei expresii CASE
--•	utilizarea a cel puțin 1 bloc de cerere(clauza WITH)


-- AFISEAZA VEHICULELE DIN SHOWROOM-URI CARE AU PRETUL PESTE MEDIE
-- (NUME_SHOWROOM, ID_VEHICUL, MARCA, MODEL, AN_FABRICATIE, PRET, TIP_CAROSERIE, MARCA_MOTOR, MODEL_MOTOR)
-- a) subcereri sincronizate in care intervin cel putin 3 tabele

SELECT
    S.NUME AS NUME_SHOWROOM,
    V.ID_VEHICUL,
    V.MARCA,
    V.MODEL,
    V.AN_FABRICATIE,
    V.PRET,
    C.NUME AS TIP_CAROSERIE,
    M.MARCA AS MARCA_MOTOR,
    M.MODEL AS MODEL_MOTOR
FROM VEHICUL V
JOIN SHOWROOM S ON V.ID_SHOWROOM = S.ID_SHOWROOM
JOIN CAROSERIE C ON V.ID_CAROSERIE = C.ID_CAROSERIE
JOIN MOTOR M ON V.ID_MOTOR = M.ID_MOTOR
WHERE V.PRET > (
                    SELECT
                        AVG(PRET)
                    FROM VEHICUL
                )
ORDER BY V.PRET DESC;


-- AFISATI ID_UL, MODELUL SI PRETUL VEHICULELOR CARE AU MODELUL LOGAN SAU SANDERO,
-- IAR IN CAZ CONTRAR AFISATI ID_UL VEHICULULUI, MESAJUL 'Nu este Logan sau Sandero' IN CADRUL COLOANEI MODEL,
-- SI PRETUL EGAL CU 0. ORDONATI LEXICOGRAFIC DESCRESCATOR DUPA MODEL
-- d) ordonări și utilizarea funcțiilor NVL și DECODE (în cadrul aceleiași cereri)

SELECT *
FROM
(
    SELECT
        ID_VEHICUL,
        NVL(DECODE(UPPER(MODEL), 'LOGAN', 'Logan', 'SANDERO', 'Sandero', NULL), '! Nu este Logan sau Sandero !') AS MODEL,
        NVL(DECODE(UPPER(MODEL), 'LOGAN', PRET, 'SANDERO', PRET, NULL), 0) AS PRET
    FROM VEHICUL
    JOIN CAROSERIE C ON VEHICUL.ID_CAROSERIE = C.ID_CAROSERIE
) V
ORDER BY V.MODEL DESC;


-- AFISATI PE O COLOANA MARCA MODELUL SI MOTORIZAREA SEPARATE PRINTR-UN SPATIU ('Marca Model Motorizare'),
-- VECHIMEA VEHICULULUI IN ANI SI LUNI FORMATATE ('"VECHHIME_ANI" ani si "(VECHIME_LUNI % 12)" luni'),
-- SI VARSTA VEHICULULUI ('Nou' < 1 AN, 'Aproape nou' APARTINE [2,3] ANI, 'Vechi' > 3 ANI)
-- e) utilizarea a cel puțin 2 funcții pe șiruri de caractere, 2 funcții pe date calendaristice,  a cel puțin unei expresii CASE

SELECT
    -- 'Marca Model Motorizare'
    CONCAT(CONCAT(CONCAT(CONCAT(UPPER(V.MARCA), ' '), UPPER(V.MODEL)), ' '), M.MODEL) AS MARCA_MODEL_MOTORIZARE,
    -- '"VECHHIME_ANI" ani si "(VECHIME_LUNI % 12)" luni'
    CONCAT(CONCAT(CONCAT(CONCAT(EXTRACT(YEAR FROM CURRENT_DATE) - V.AN_FABRICATIE, ' ani si'), ' '),
                  FLOOR((MOD(MONTHS_BETWEEN(CURRENT_DATE, TO_DATE(V.AN_FABRICATIE || '-01-01', 'YYYY-MM-DD'))
                      , 12)))), ' luni') AS VECHIME_ANI,
    (CASE
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - V.AN_FABRICATIE <= 1 THEN 'Nou'
        WHEN EXTRACT(YEAR FROM CURRENT_DATE) - V.AN_FABRICATIE BETWEEN 2 AND 3 THEN 'Aproape nou'
        ELSE 'Vechi'
    END) AS VARSTA_VEHICUL
FROM VEHICUL V
JOIN MOTOR M ON V.ID_MOTOR = M.ID_MOTOR;


-- SA SE AFISEZE ID_VEHICUL, MARCA, MODEL, MODELUL MOTORULUI, ANUL DE FABRICATIE, PRETUL
-- SI SUMA TOTALA A TRANZACTIILOR CE CONTIN VEHICULUL RESPECTIV, IMPREUNA CU NUMARUL DE TRANZACTII CE CONTIN VEHICULUL RESPECTIV
-- (DE CATE ORI A FOST VANDUT ACEST MODEL)
-- b) subcereri nesincronizate în clauza FROM

SELECT V.ID_VEHICUL,
       V.MARCA,
       V.MODEL,
       M.MODEL AS MODEL_MOTOR,
       V.AN_FABRICATIE,
       V.PRET,
       V.VANZARI AS SUMA_TOTALA_TRANZACTII_PER_VEHICUL,
       V.NR_VANZARI AS NR_TRANZACTII_PER_VEHICUL
FROM (
         SELECT
             VINT.ID_VEHICUL,
             VINT.MARCA,
             VINT.MODEL,
             VINT.ID_MOTOR,
             VINT.AN_FABRICATIE,
             VINT.PRET,
             (
              SELECT
                  NVL(SUM(TRANZACTIE.SUMA), 0)
              FROM TRANZACTIE
              WHERE TRANZACTIE.ID_VEHICUL = VINT.ID_VEHICUL
             ) AS VANZARI,
             (
              SELECT
                  COUNT(*)
              FROM TRANZACTIE
              WHERE TRANZACTIE.ID_VEHICUL = VINT.ID_VEHICUL
             ) AS NR_VANZARI
         FROM VEHICUL VINT
     ) V
JOIN MOTOR M ON V.ID_MOTOR = M.ID_MOTOR
ORDER BY V.VANZARI DESC;


-- AFISEAZA MARCA, MODELUL, SUMA VANZARILOR SI NUMARUL DE TRANZACTII PENTRU FIECARE VEHICUL
-- CARE A GENERAT TRANZACTII CU SUMA MAI MARE DECAT MEDIA SUMELOR TUTUROR TRANZACTIILOR,
-- SI CARE A FOST VANDUT DE CATRE UN SHOWROOM CU UN NUMAR DE ANGAJATI MAI MARE DECAT
-- MEDIA NUMARULUI DE ANGAJATI DIN TOATE SHOWROOM-URILE

-- c) grupari de date, functii grup, filtrare la nivel de grupuri cu subcereri nesincronizate
-- (in clauza de HAVING) in care intervin cel putin 3 tabele (in cadrul aceleiasi cereri)
-- f) utilizarea a cel putin 1 bloc de cerere (clauza WITH)

WITH VANZARI_PER_VEHICUL AS
(
    SELECT
        V.ID_VEHICUL,
        V.ID_SHOWROOM,
        V.MARCA,
        V.MODEL,
        SUM(T.SUMA) AS SUMA_VANZARI,
        COUNT(T.ID_TRANZACTIE) AS NR_TRANZACTII
    FROM VEHICUL V
    LEFT JOIN TRANZACTIE T ON V.ID_VEHICUL = T.ID_VEHICUL
    GROUP BY V.ID_VEHICUL, V.ID_SHOWROOM, V.MARCA, V.MODEL
)
SELECT
    VPV.MARCA,
    VPV.MODEL,
    VPV.SUMA_VANZARI,
    VPV.NR_TRANZACTII,
    COUNT(A.ID_ANGAJAT) AS NR_ANGAJATI
FROM VANZARI_PER_VEHICUL VPV
LEFT JOIN SHOWROOM S ON VPV.ID_SHOWROOM = S.ID_SHOWROOM
LEFT JOIN ANGAJAT_SHOWROOM A ON S.ID_SHOWROOM = A.ID_SHOWROOM
GROUP BY VPV.MARCA, VPV.MODEL, VPV.SUMA_VANZARI, VPV.NR_TRANZACTII
HAVING
VPV.SUMA_VANZARI >
(
    SELECT
        AVG(T1.SUMA)
    FROM TRANZACTIE T1
)
AND
COUNT(A.ID_ANGAJAT) >
(
    SELECT
        AVG(NR_ANGAJATI1)
    FROM
    (
        SELECT
            COUNT(A2.ID_ANGAJAT) AS NR_ANGAJATI1
        FROM ANGAJAT_SHOWROOM A2
        GROUP BY A2.ID_SHOWROOM
    ) A1
);



-- 13. Implementarea a 3 operații de actualizare și de suprimare a datelor utilizând subcereri.

-- APLICATI O REDUCERE DE 10% TUTOROR VEHICULELOR CARE AU MOTOR ELECTRIC
UPDATE VEHICUL
SET PRET = PRET * 0.9
WHERE ID_VEHICUL IN
(
    SELECT
        V.ID_VEHICUL
    FROM VEHICUL V
    WHERE V.ID_MOTOR IN
    (
        SELECT
            ME.ID_MOTOR
        FROM MOTOR_ELECTRIC ME
    )
);


-- APLICATI O MARIRE DE SALARIU DE 10% ANGAJATILOR CARE AU EFECTUAT MAI MULTE DE O TRANZACTIE
UPDATE ANGAJAT_SHOWROOM
SET SALARIU = SALARIU * 1.1
WHERE ID_ANGAJAT IN
(
        SELECT
            A.ID_ANGAJAT
        FROM ANGAJAT_SHOWROOM A
        JOIN TRANZACTIE T ON A.ID_ANGAJAT = T.ID_ANGAJAT
        GROUP BY A.ID_ANGAJAT
        HAVING COUNT(T.ID_TRANZACTIE) > 1
);

-- STERGETI TOATE VEHICULELE DIN SHOWROOM-URI CARE FOLOSESC MOTORINA
DELETE FROM VEHICUL
WHERE ID_MOTOR IN
(
    SELECT
        M.ID_MOTOR
    FROM MOTOR M
    WHERE M.ID_MOTOR IN
    (
        SELECT
            MC.ID_MOTOR
        FROM MOTOR_CARBURANT MC
        WHERE MC.ID_CARBURANT IN
        (
            SELECT
                C.ID_CARBURANT
            FROM CARBURANT C
            WHERE C.TIP = 'Motorina'
        )
    )
);
