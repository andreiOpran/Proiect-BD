


-- PENTRU RESTANTA AM DE REFACUT EXERCITIUL 12



--12.Formulați în  limbaj  natural și  implementați 5 cereri  SQL  complexece  vor  utiliza,  în ansamblul lor, următoarele elemente:
--•	subcereri sincronizate în care intervin cel puțin 3 tabele
--•	subcereri nesincronizate în clauza FROM
--•	grupări de date cu  subcereri  nesincronizate  in  care  intervin  cel  putin  3  tabele, funcții grup, filtrare la nivel de grupuri(in cadrul aceleiasi cereri)
--•	ordonări si utilizarea funcțiilor NVL și DECODE (in cadrul aceleiasi cereri)
--•	utilizarea a cel puțin 2 funcții pe șiruri de caractere, 2 funcții pe date calendaristice,  a cel puțin unei expresii CASE
--•	utilizarea a cel puțin 1 bloc de cerere(clauza WITH)


-- AFISATI PENTRU FIECARE CLIENT ID-UL SAU, NUMARUL DE TRANZACTII ALE CLIENTULUI SI NR DE PLATI ALE CLIENTULUI
-- a) subcereri sincronizate in care intervin cel putin 3 tabele

SELECT
    C.ID_CLIENT,
    (
        SELECT
            COUNT(*)
        FROM TRANZACTIE T
        WHERE T.ID_CLIENT = C.ID_CLIENT
    ) NR_TRANZACTII_CLIENT,
    (
        SELECT
            COUNT(*)
        FROM PLATA P
        WHERE P.ID_CLIENT = C.ID_CLIENT
    ) NR_PLATI_CLIENT
FROM CLIENT C
ORDER BY  C.ID_CLIENT;



-- AFISEAZA ID_VEHICUL, MARCA, MODEL, ID_MOTOR SI MESAJUL 'ARE MOTOR CU TURBINA' RESPECTIV 'NU ARE MOTOR
-- CU TURBINA' INTR-O COLOANA SEPARATA PENTRU FIECARE VEHICUL DIN TABELUL 'VEHICUL'
-- d) ordonări și utilizarea funcțiilor NVL și DECODE (în cadrul aceleiași cereri)

SELECT
    V.ID_VEHICUL,
    V.MARCA,
    V.MODEL,
    V.ID_MOTOR,
    NVL(DECODE(UPPER(MC.ASPIRATIE), 'TURBINA', 'ARE MOTOR CU TURBINA', NULL),'NU ARE MOTOR CU TURBINA') AS TURBINA
FROM VEHICUL V
JOIN MOTOR_CARBURANT MC ON V.ID_MOTOR = MC.ID_MOTOR
ORDER BY V.ID_VEHICUL;



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



-- AFISEAZA SHOWROOM-URILE (ID, NUME), IN CARE EXISTA CEL PUTIN 1 MODEL DE PICK-UP DISPONIBIL
-- b) subcereri nesincronizate în clauza FROM

SELECT
    T.ID_SR,
    T.NUM
FROM (
        SELECT
            S.ID_SHOWROOM AS ID_SR,
            S.NUME AS NUM,
        (
            SELECT
                COUNT(*)
            FROM VEHICUL V
            WHERE V.ID_SHOWROOM = S.ID_SHOWROOM AND UPPER(V.MODEL) = 'PICK-UP'
        ) AS CONT
        FROM SHOWROOM S
        WHERE S.ID_SHOWROOM IN (
            SELECT
                V.ID_SHOWROOM
            FROM VEHICUL V
            WHERE UPPER(V.MODEL) = 'PICK-UP'
        )
     ) T
WHERE CONT >= 1;



-- AFISEAZA PENTRU FIECARE ANGAJAT ID-UL, SALARIUL, NR DE TRANZACTII EFECTUATE, MEDIA SUMELOR TRANZACTIILOR EFECTUATE
-- SI NR DE ANGAJATI DIN SHOWROOM UL UNDE LUCREAZA ANGAJATUL RESPECTIV, PENTRU ANGAJATII A CAROR
-- MEDIE A SUMELOR TRANZACTIILOR EFECTUATE ESTE MAI MARE CA MEDIA TUTUROR CELORLALTI VANZATORI

-- c) grupari de date, functii grup, filtrare la nivel de grupuri cu subcereri nesincronizate
-- (in clauza de HAVING) in care intervin cel putin 3 tabele (in cadrul aceleiasi cereri)
-- f) utilizarea a cel putin 1 bloc de cerere (clauza WITH)

WITH PERFORMANTE_VANZATORI AS (
    SELECT
        V.ID_ANGAJAT,
        (
            SELECT
                COUNT(*)
            FROM TRANZACTIE T1
            WHERE T1.ID_ANGAJAT = V.ID_ANGAJAT
        ) AS TRANZACTII_EFECTUATE,
        (
            SELECT
                NVL(SUM(T2.SUMA), 0)
            FROM TRANZACTIE T2
            WHERE T2.ID_ANGAJAT = V.ID_ANGAJAT
        ) AS SUMA_TRANZACTII_EFECTUATE,
        (
            SELECT
                AVG(NVL(T3.SUMA, 0))
            FROM TRANZACTIE T3
            WHERE T3.ID_ANGAJAT = V.ID_ANGAJAT
        ) AS MEDIA_TRANZACTII_EFECTUATE
    FROM VANZATOR V
)
SELECT
    V2.ID_ANGAJAT,
    ASHOW.SALARIU,
    PV.TRANZACTII_EFECTUATE,
    PV.MEDIA_TRANZACTII_EFECTUATE,
    COUNT(ANGCONT.ID_ANGAJAT) AS NR_ANGAJATI_IN_SHOWROOMUL_UNDE_LUCREAZA_VANZATORUL
FROM VANZATOR V2
JOIN ANGAJAT_SHOWROOM ASHOW ON V2.ID_ANGAJAT = ASHOW.ID_ANGAJAT
JOIN PERFORMANTE_VANZATORI PV ON PV.ID_ANGAJAT = V2.ID_ANGAJAT
JOIN ANGAJAT_SHOWROOM ANGCONT ON ANGCONT.ID_SHOWROOM = (
    SELECT
        ASAUX.ID_SHOWROOM
    FROM ANGAJAT_SHOWROOM ASAUX
    WHERE ASAUX.ID_ANGAJAT = V2.ID_ANGAJAT
    )
GROUP BY V2.ID_ANGAJAT, ASHOW.SALARIU, PV.TRANZACTII_EFECTUATE, PV.MEDIA_TRANZACTII_EFECTUATE
HAVING PV.MEDIA_TRANZACTII_EFECTUATE >= (
    SELECT
        AVG(MEDIA_TRANZACTII_EFECTUATE)
    FROM PERFORMANTE_VANZATORI
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