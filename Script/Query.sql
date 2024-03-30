-- QUERY
-- Query con operatore di aggregazione e join
-- Associa al codice e al nome di ogni campagna la media dei valiori registrati nel tempo dei KPI
-- i :: in postgreSQL sono utilizzati per eseguire un casting esplicito di un valore da un tipo ad un altro
--la funzione ROUND si occupa di arrotondare la media alle 4 cifre dopo la virgola come specificato
SELECT CP.codice AS codice_campagna, CP.nome AS nome_campagna,
ROUND(AVG(VA.valore)::numeric,4) AS media_tasso_conversione
FROM CAMPAGNA_PUBBLICITARIA CP
JOIN NEWSLETTER NS ON CP.codice = NS.campagna
JOIN VALUTAZIONE VA ON NS.campagna = VA.newsletter
JOIN KPI K ON VA.kpi = K.nome
WHERE K.nome = 'Tasso di conversione'
GROUP BY CP.codice, CP.nome
ORDER BY media_tasso_conversione DESC;


-- Query nidificata complessa: campagne in corso che pubblicizano almeno un prodotto disponibile in categoria "maglie"
-- Restituisce informazioni sulle campagne pubblicitarie attive che promuovono almeno un prodotto della categoria "Maglie" che risulti disponibile
SELECT CP.codice, CP.nome, CP.data_inizio, CP.budget, CP.azienda_committente
FROM CAMPAGNA_PUBBLICITARIA CP
    WHERE CP.data_fine IS NULL AND EXISTS (
        SELECT *
        FROM PUBBLICIZZA P
        JOIN PRODOTTO PR ON P.collezione = PR.collezione
        JOIN CATEGORIA C ON PR.categoria = C.nome
        WHERE P.campagna = CP.codice
            AND PR.disponibilita = TRUE
            AND C.nome = 'Maglie'
    )
ORDER BY CP.data_inizio;


-- Query insiemistica: Collezioni pubblicizzate da Zalando ma non frornite da Etam
SELECT CO.id, CO.nome, CO.anno, CO.azienda_fornitrice, CO.descrizione
FROM COLLEZIONE AS CO
JOIN PUBBLICIZZA AS P ON CO.id = P.collezione
JOIN CAMPAGNA_PUBBLICITARIA AS CP ON P.campagna = CP.codice
JOIN AZIENDA AS A ON CP.azienda_committente = A.partita_IVA
WHERE A.partita_IVA = '02986180210' -- partita IVA di Zalando
EXCEPT
SELECT CO.id, CO.nome, CO.anno, CO.azienda_fornitrice, CO.descrizione
FROM COLLEZIONE AS CO
JOIN AZIENDA AS A ON CO.azienda_fornitrice = A.partita_IVA
WHERE A.partita_IVA = '78901234567' -- partita IVA di Etam
ORDER BY anno;



--Query che seleziona tutti gli utenti che sono iscritti a più di una newsletter a tema estivo ordinandoli per cognome.
--Utile a scopi di profilazione.
SELECT U.cognome, U.nome, U.email, COUNT(I.newsletter) AS numero_iscrizioni
FROM UTENTE AS U
JOIN ISCRIZIONE AS I ON U.nickname = I.utente
JOIN NEWSLETTER AS N ON I.newsletter = N.campagna
JOIN CAMPAGNA_PUBBLICITARIA AS CP ON N.campagna = CP.codice
JOIN PUBBLICIZZA AS P ON CP.codice = P.campagna
JOIN COLLEZIONE AS C ON P.collezione = C.id
WHERE C.nome LIKE '%Estate%'
GROUP BY U.nome, U.cognome, U.email
HAVING COUNT(I.newsletter) > 1
ORDER BY U.cognome;



-- Vista che riassume le informazioni delle campagne pubblicitarie di Ferrari
DROP VIEW IF EXISTS VistaAziendaNewsletterMediaValutazioni;

CREATE VIEW VistaAziendaNewsletterMediaValutazioni AS
SELECT CP.codice AS codice_campagna, CP.nome AS nome_campagna, CP.budget, CP.data_inizio, CP.data_fine,
	   N.cadenza AS cadenza_newsletter, N.numero_iscritti AS num_iscritti_newsletter,
       V.kpi, ROUND(AVG(V.valore):: numeric, 4) AS media_valutazione
FROM CAMPAGNA_PUBBLICITARIA CP
JOIN AZIENDA A ON CP.azienda_committente = A.partita_IVA
JOIN NEWSLETTER N ON CP.codice = N.campagna
JOIN VALUTAZIONE V ON N.campagna = V.newsletter
WHERE A.partita_IVA = '12345678901' -- partita IVA di Ferrari
GROUP BY CP.codice, CP.nome, CP.budget, CP.data_inizio, CP.data_fine,
         N.campagna, N.cadenza, N.numero_iscritti, V.kpi
ORDER BY CP.codice;


-- Query sulla vista che prende la campagna pubblicitaria di quell'azienda che risulta essere non conclusa
-- e presenta il feedback più elevato.
SELECT *
FROM VistaAziendaNewsletterMediaValutazioni V
WHERE V.data_fine IS NULL -- Solo campagne pubblicitarie non ancora concluse
  AND V.kpi = 'Feedback' -- Considera solo il KPI di feedback
  AND V.media_valutazione = (SELECT MAX(media_valutazione)
                             FROM VistaAziendaNewsletterMediaValutazioni
                             WHERE kpi = 'Feedback');
