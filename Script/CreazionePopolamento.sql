-- CREAZIONE TABELLE
--Creazione tabella AZIENDA
DROP TABLE IF EXISTS AZIENDA CASCADE;

CREATE TABLE AZIENDA (
  	partita_IVA VARCHAR(11) PRIMARY KEY CHECK (LENGTH(partita_IVA) = 11),
  	nome VARCHAR(50) NOT NULL,
  	sede_nazione VARCHAR(20),
  	sede_citta VARCHAR(20)
);

--Creazione tabella NUMERO_TELEFONICO
DROP TABLE IF EXISTS NUMERO_TELEFONICO CASCADE;

CREATE TABLE NUMERO_TELEFONICO (
    numero VARCHAR(20) PRIMARY KEY,
    azienda VARCHAR(11) NOT NULL,
    FOREIGN KEY (azienda) REFERENCES AZIENDA(partita_IVA) ON UPDATE CASCADE ON DELETE CASCADE
);

--Creazione tabella CAMPAGNA_PUBBLICITARIA
DROP TABLE IF EXISTS CAMPAGNA_PUBBLICITARIA CASCADE;

CREATE TABLE CAMPAGNA_PUBBLICITARIA (
    codice INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
	-- generated always as identity permette di generare il codice all'inserimento come numero progressivo
	-- e non permette di modificarlo, metodo compliant allo std SQL al contrario di SERIAL
    nome VARCHAR(100) NOT NULL,
    budget BIGINT NOT NULL,
    data_inizio DATE NOT NULL,
    data_fine DATE CHECK (data_fine IS NULL OR data_fine <= CURRENT_DATE),
    azienda_committente VARCHAR(11) NOT NULL,
    FOREIGN KEY (azienda_committente) REFERENCES AZIENDA(partita_IVA) ON UPDATE CASCADE ON DELETE RESTRICT
	--non permettiamo l'eliminazione di aziende che hanno campagne per questione di storico
);

--Creazione tabella KPI
DROP TABLE IF EXISTS KPI CASCADE;

CREATE TABLE KPI (
    nome VARCHAR(50) PRIMARY KEY,
    descrizione VARCHAR(255) NOT NULL,
    formula VARCHAR(70) NOT NULL,
    val_min NUMERIC(4,2),
    val_max NUMERIC(4,2)
);

--Creazione tabella UTENTE
DROP TABLE IF EXISTS UTENTE CASCADE;

CREATE TABLE UTENTE (
	nickname VARCHAR(50) PRIMARY KEY,
	email VARCHAR(100) NOT NULL UNIQUE,
	nome VARCHAR(50) NOT NULL,
	cognome VARCHAR(50) NOT NULL,
	sesso CHAR(1) CHECK (sesso IN ('M', 'F')) NOT NULL,
	data_di_nascita DATE NOT NULL,
	CONSTRAINT check_email_pattern CHECK (email ~ '^[a-zA-Z0-9]+@[a-zA-Z0-9]+\.[a-zA-Z]+$') 
);

--Creazione tabella CATEGORIA
DROP TABLE IF EXISTS CATEGORIA CASCADE;

CREATE TABLE CATEGORIA (
    nome VARCHAR(50) PRIMARY KEY,
    descrizione VARCHAR(255) NOT NULL
);

--Creazione tabella NEWSLETTER
DROP TABLE IF EXISTS NEWSLETTER CASCADE;

CREATE TABLE NEWSLETTER (
    campagna INTEGER PRIMARY KEY,
    numero_iscritti INTEGER DEFAULT 0,
    cadenza INTEGER NOT NULL,
    FOREIGN KEY (campagna) REFERENCES CAMPAGNA_PUBBLICITARIA(codice) ON UPDATE CASCADE ON DELETE CASCADE
	--se viene cancellata la campagna non permettiamo il mantenimento della newsletter associata
);

--Creazione tabella VALUTAZIONE
DROP TABLE IF EXISTS VALUTAZIONE CASCADE;

CREATE TABLE VALUTAZIONE (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    newsletter INTEGER NOT NULL,
    kpi VARCHAR(50) NOT NULL,
    istante_calcolo TIMESTAMP NOT NULL,
    valore NUMERIC(4,2) NOT NULL,
    FOREIGN KEY (newsletter) REFERENCES NEWSLETTER(campagna) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (kpi) REFERENCES KPI(nome) ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (newsletter, kpi, istante_calcolo)
);

--Creazione tabella COLLEZIONE
DROP TABLE IF EXISTS COLLEZIONE CASCADE;

CREATE TABLE COLLEZIONE (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    azienda_fornitrice VARCHAR(11) NOT NULL,
    nome VARCHAR(50) NOT NULL,
    anno NUMERIC(4, 0) NOT NULL,
    descrizione VARCHAR(255) NOT NULL,
    FOREIGN KEY (azienda_fornitrice) REFERENCES AZIENDA(partita_IVA) ON UPDATE CASCADE ON DELETE RESTRICT,
	--decidiamo di utilizzare RESTRICT sia perchè fa parte di una chiave, sia perchè quella collezione potrebbe trovarsi in una campagna di Zalando
    UNIQUE (azienda_fornitrice, nome, anno)
);

--Creazione tabella PRODOTTO
DROP TABLE IF EXISTS PRODOTTO CASCADE;

CREATE TABLE PRODOTTO (
    id INTEGER PRIMARY KEY GENERATED ALWAYS AS IDENTITY,
    collezione INTEGER NOT NULL,
    nome VARCHAR(100) NOT NULL,
    voto_medio DOUBLE PRECISION CHECK (voto_medio >= 0 AND voto_medio <= 5) NOT NULL,
    disponibilita BOOLEAN NOT NULL,
    sezione VARCHAR(7) CHECK (sezione IN ('Uomo', 'Donna', 'Bambino')),
    categoria VARCHAR(50) NOT NULL,
    FOREIGN KEY (collezione) REFERENCES COLLEZIONE(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (categoria) REFERENCES CATEGORIA(nome) ON UPDATE RESTRICT ON DELETE RESTRICT,
	--decidiamo di utilizzare RESTRICT sull'UPDATE perchè la categoria potrebbe cambiare non interessando più quel prodotto,
	--mentre sulla DELETE perchè un prodotto deve per forza appartenere ad una categoria
    UNIQUE (collezione, nome)
);

--Creazione tabella COLORE
DROP TABLE IF EXISTS COLORE CASCADE;

CREATE TABLE COLORE (
    nome VARCHAR(20) PRIMARY KEY
);

--Creazioen tabella COLORI_ASSORTITI
DROP TABLE IF EXISTS COLORI_ASSORTITI CASCADE;

CREATE TABLE COLORI_ASSORTITI (
    prodotto INTEGER,
    colore VARCHAR(20),
    PRIMARY KEY (prodotto, colore),
    FOREIGN KEY (prodotto) REFERENCES PRODOTTO(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (colore) REFERENCES COLORE(nome) ON UPDATE RESTRICT ON DELETE CASCADE
	--decidiamo di utilizzare RESTRICT sull'UPDATE perchè il colore potrebbe cambiare non interessando più quel prodotto, 
	--mentre sulla DELETE usiamo CASCADE perchè i colori possono essere cancellati, basta che ce ne sia almeno uno (controllato dal trigger)
);

--Creazione tabella TAGLIA
DROP TABLE IF EXISTS TAGLIA CASCADE;

CREATE TABLE TAGLIA (
    sigla VARCHAR(3) PRIMARY KEY
);

--Creazione tabella TAGLIE_ASSORTITE
DROP TABLE IF EXISTS TAGLIE_ASSORTITE CASCADE;

CREATE TABLE TAGLIE_ASSORTITE (
    prodotto INTEGER,
    taglia VARCHAR(3),
    PRIMARY KEY (prodotto, taglia),
    FOREIGN KEY (prodotto) REFERENCES PRODOTTO(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (taglia) REFERENCES TAGLIA(sigla) ON UPDATE RESTRICT ON DELETE CASCADE
	--decidiamo di utilizzare RESTRICT sull'UPDATE perchè la taglia potrebbe cambiare non interessando più quel prodotto, 
	--mentre sulla DELETE usiamo CASCADE perchè le taglie possono essere cancellate, basta che ce ne sia almeno una (controllato dal trigger)
);

--Creazione tabella ISCRIZIONE
DROP TABLE IF EXISTS ISCRIZIONE CASCADE;

CREATE TABLE ISCRIZIONE (
    newsletter INTEGER,
    utente VARCHAR(50),
    data_iscrizione DATE NOT NULL,
    PRIMARY KEY (newsletter, utente),
    FOREIGN KEY (newsletter) REFERENCES NEWSLETTER(campagna) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (utente) REFERENCES UTENTE(nickname) ON UPDATE CASCADE ON DELETE CASCADE
);

--Creazione tabella PUBBLICIZZA
DROP TABLE IF EXISTS PUBBLICIZZA CASCADE;

CREATE TABLE PUBBLICIZZA (
    campagna INTEGER,
    collezione INTEGER,
    PRIMARY KEY (campagna, collezione),
    FOREIGN KEY (campagna) REFERENCES CAMPAGNA_PUBBLICITARIA(codice) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (collezione) REFERENCES COLLEZIONE(id) ON UPDATE CASCADE ON DELETE CASCADE
	--per entrambi decidiamo di utilizzare CASCADE sulla DELETE perchè basta che ce ne sia almeno una sia per la collezione che per la campagna (controllati dai trigger)
);



-- POPOLAMENTO
--Popolamento tabella AZIENDA: 11 aziende
DELETE FROM AZIENDA;

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('12345678901', 'Ferrari', 'Italia', 'Maranello');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('23456789012', 'Dior', 'Francia', 'Parigi');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('02986180210', 'Zalando', 'Germania', 'Berlino');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('45678901234', 'Zara', 'Spagna', 'Madrid');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('56789012345', 'Burberry', 'Regno Unito', 'Londra');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('67890123456', 'Gucci', 'Italia', 'Milano');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('78901234567', 'Etam', 'Francia', 'Lione');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('89012345678', 'Tom Tailor', 'Germania', 'Amburgo');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('90123456789', 'Mango', 'Spagna', 'Barcellona');

INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('01234567890', 'Boohoo', 'Regno Unito', 'Manchester');

--Non ha sue campagne, ma fornisce prodotti per quelle cumulative di Zalando
INSERT INTO AZIENDA (partita_IVA, nome, sede_nazione, sede_citta)
VALUES ('01236667890', 'Piazza Italia', 'Italia', 'Pompei');



--Popolamento tabella NUMERO TELEFONICO: un numero che varia tra 1 e 3 per azienda
DELETE FROM NUMERO_TELEFONICO;

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+391234567890', '12345678901'),
       ('+391234567891', '12345678901');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+33123456789', '23456789012');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+491234567890', '02986180210'),
       ('+491234567891', '02986180210'),
       ('+491234567892', '02986180210');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+3476543210', '45678901234');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+441234567890', '56789012345');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+391234567892', '67890123456'),
       ('+391234567893', '67890123456');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+331234567890', '78901234567');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+491234567893', '89012345678');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+34123456789', '90123456789'),
       ('+34123456790', '90123456789'),
       ('+34123456791', '90123456789');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+441234567891', '01234567890');

INSERT INTO NUMERO_TELEFONICO (numero, azienda)
VALUES ('+391234567894', '01236667890');



--Popolamento tabella CAMPAGNA PUBBLICITARIA: 1 in corso e 1 terminata per azienda
DELETE FROM CAMPAGNA_PUBBLICITARIA;

-- Campagne per Ferrari
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Ferrari 2023', 500000.00, '2023-01-01', '12345678901');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Ferrari 2022', 750000.00, '2022-01-01', '2022-12-31', '12345678901');

-- Campagne per Dior
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Dior 2023', 300000.00, '2023-03-01', '23456789012');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Dior 2022', 450000.00, '2022-03-01', '2022-06-30', '23456789012');

-- Campagne per Zalando
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Zalando 2023', 1000000.00, '2023-05-15', '02986180210');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Zalando 2022', 1200000.00, '2022-05-15', '2022-12-15', '02986180210');

-- Campagne per Zara
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Zara 2023', 800000.00, '2021-07-01', '45678901234');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Zara 2022', 900000.00, '2022-07-01', '2022-09-30', '45678901234');

-- Campagne per Burberry
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Burberry 2023', 400000.00, '2023-02-01', '56789012345');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Burberry 2022', 550000.00, '2022-09-01', '2022-12-01', '56789012345');

-- Campagne per Gucci
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Gucci 2023', 600000.00, '2023-04-01', '67890123456');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Gucci 2022', 700000.00, '2022-11-01', '2023-01-31', '67890123456');

-- Campagne per Etam
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Etam 2023', 300000.00, '2022-12-01', '78901234567');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Etam 2022', 400000.00, '2022-02-01', '2022-11-01', '78901234567');

-- Campagne per Tom Tailor
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Tom Tailor 2023', 200000.00, '2023-05-15', '89012345678');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Tom Tailor 2022', 250000.00, '2022-06-15', '2022-10-31', '89012345678');

-- Campagne per Mango
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Mango 2023', 500000.00, '2023-04-10', '90123456789');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Mango 2022', 650000.00, '2022-08-15', '2022-09-15', '90123456789');

-- Campagne per Boohoo
INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, azienda_committente)
VALUES ('Campagna Boohoo 2023', 350000.00, '2023-01-01', '01234567890');

INSERT INTO CAMPAGNA_PUBBLICITARIA (nome, budget, data_inizio, data_fine, azienda_committente)
VALUES ('Campagna Boohoo 2022', 400000.00, '2022-10-01', '2022-12-31', '01234567890');



---Popolamento tabella KPI: i 9 tecnici evidenziati nel WP0
DELETE FROM KPI;

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Tasso di apertura', 'Percentuale di utenti che aprono la newsletter rispetto al numero totale di destinatari', '#Aperture / (#Email inviate - #Email non ricevute)', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Tasso di clic', 'Percentuale di utenti che cliccano sui link presenti nella newsletter rispetto al numero totale di destinatari', '#Clicks / (#Email inviate - #Email non ricevute)', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Tasso di conversione', 'Percentuale di utenti che completano l''acquisto di un prodotto tramite la newsletter rispetto al numero totale di clic effettuati', '#Conversioni / #Clicks', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Tasso di disiscrizione', 'Percentuale di utenti che si disiscrivono dalla newsletter rispetto al numero totale di destinatari', '#Disiscrizioni / (#Email inviate - #Email non ricevute)', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Tasso di forward e condivisione', 'Percentuale di utenti che inoltrano la newsletter ad altre persone o la condividono sui social network rispetto al numero totale di destinatari', '#Condivisioni / (#Email inviate - #Email non ricevute)', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Feedback', 'Giudizio degli utenti espresso tramite valutazioni', 'Voto Medio Newsletter / 5', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Spaccato per device', 'Percentuale di utenti che accedono alla newsletter tramite dispositivi mobili', '#Aperture Su Mobile / #Aperture Totali', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Tasso di risposta', 'Percentuale di utenti che rispondono alla newsletter tramite feedback o contatti diretti con Zalando', '#Utenti Che Rispondono / #Utenti Iscritti', 0, 1);

INSERT INTO KPI (nome, descrizione, formula, val_min, val_max)
VALUES ('Tasso di crescita', 'Tasso di crescita della lista degli iscritti', '((#Iscritti Attuali - #Iscritti Precedenti) / #Iscritti Precedenti)', NULL, NULL);



--Popolamento tabella UTENTE: 31 utenti
DELETE FROM UTENTE;

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user1', 'user1@example.com', 'Gennaro', 'Esposito', 'M', '1990-01-01');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user2', 'user2@example.com', 'Jane', 'Smith', 'F', '1992-03-15');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user3', 'user3@example.com', 'Michael', 'Johnson', 'M', '1985-07-10');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user4', 'user4@example.com', 'Emily', 'Brown', 'F', '1998-12-25');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user5', 'user5@example.com', 'David', 'Taylor', 'M', '1991-06-05');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user6', 'user6@example.com', 'Sarah', 'Wilson', 'F', '1988-09-18');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user7', 'user7@example.com', 'Christopher', 'Anderson', 'M', '1994-02-20');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user8', 'user8@example.com', 'Jessica', 'Thomas', 'F', '1993-11-02');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user9', 'user9@example.com', 'Matteo', 'Gaeta', 'M', '1987-05-08');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user10', 'user10@example.com', 'Mia', 'White', 'F', '1996-07-14');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user11', 'user11@example.com', 'Luca', 'Greco', 'M', '1995-04-28');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user12', 'user12@example.com', 'Olivia', 'Lee', 'F', '1991-09-30');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user13', 'user13@example.com', 'Daniel', 'Lopez', 'M', '1989-12-12');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user14', 'user14@example.com', 'Sophia', 'Harris', 'F', '1997-03-24');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user15', 'user15@example.com', 'James', 'Clarkson', 'M', '1986-08-26');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user16', 'user16@example.com', 'Emma', 'Turner', 'F', '1999-01-04');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user17', 'user17@example.com', 'Benjamin', 'Baker', 'M', '1990-06-16');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user18', 'user18@example.com', 'Ava', 'Gonzalez', 'F', '1988-03-08');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user19', 'user19@example.com', 'William', 'Wright', 'M', '1993-09-22');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user20', 'user20@example.com', 'Isabella', 'Walker', 'F', '1994-11-30');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user21', 'user21@example.com', 'Joshua', 'Scott', 'M', '1993-08-12');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user22', 'user22@example.com', 'Grace', 'Adams', 'F', '1990-02-26');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user23', 'user23@example.com', 'Samuel', 'Murphy', 'M', '1995-07-18');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user24', 'user24@example.com', 'Chloe', 'Kelly', 'F', '1998-05-01');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user25', 'user25@example.com', 'Daniel', 'Barnes', 'M', '1987-12-07');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user26', 'user26@example.com', 'Olivia', 'Parker', 'F', '1991-09-14');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user27', 'user27@example.com', 'James', 'Evans', 'M', '1994-03-22');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user28', 'user28@example.com', 'Sophia', 'Morris', 'F', '1997-11-06');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user29', 'user29@example.com', 'William', 'Turner', 'M', '1992-06-16');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user30', 'user30@example.com', 'Isabella', 'Hill', 'F', '1993-04-30');

INSERT INTO UTENTE (nickname, email, nome, cognome, sesso, data_di_nascita)
VALUES ('user31', 'user31@example.com', 'Antonio', 'D''acierno', 'M', '1989-01-20');



--Popolamento tabella CATEGORIA: 10 categorie
DELETE FROM CATEGORIA;

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Maglie', 'Maglie a manica corta e lunga per uomo e donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Pantaloni', 'Pantaloni eleganti e casual per uomo e donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Gonne', 'Gonne corte e lunghe per donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Camicie', 'Camicie formali e casual per uomo e donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Vestiti', 'Vestiti eleganti e informali per donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Giacche', 'Giacche leggere e pesanti per uomo e donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Jeans', 'Jeans di varie forme e lavaggi per uomo e donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Scarpe', 'Scarpe sportive, casual e formali per uomo e donna');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Accessori', 'Accessori come cinture, borse e gioielli');

INSERT INTO CATEGORIA (nome, descrizione)
VALUES ('Intimo', 'Intimo per uomo e donna, inclusi reggiseni e mutandine');



--Popolamento tabella NEWSLETTER: 1 per ogni campagna
DELETE FROM NEWSLETTER;

-- Newsletter per Ferrari
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (1, 3, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (2, 5, 4);

-- Newsletter per Dior
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (3, 2, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (4, 6, 4);

-- Newsletter per Zalando
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (5, 4, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (6, 1, 4);

-- Newsletter per Zara
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (7, 7, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (8, 3, 4);

-- Newsletter per Burberry
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (9, 5, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (10, 2, 4);

-- Newsletter per Gucci
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (11, 6, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (12, 4, 4);

-- Newsletter per Etam
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (13, 1, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (14, 7, 4);

-- Newsletter per Tom Tailor
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (15, 3, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (16, 5, 4);

-- Newsletter per Mango
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (17, 2, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (18, 6, 4);

-- Newsletter per Boohoo
INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (19, 4, 4);

INSERT INTO NEWSLETTER (campagna, cadenza, numero_iscritti)
VALUES (20, 1, 4);



--Popolamento tabella VALUTAZIONE: visto la numerosità di combinazioni tra newsletter e kpi, popoliamo solo alcuni casi particolari
DELETE FROM VALUTAZIONE;

--Due valutazioni a distanza di due giorni della stessa newsletter
-- Valutazione del Tasso di apertura
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di apertura', NOW() - INTERVAL '2 days', 0.75);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di apertura', NOW(), 0.82);

-- Valutazione del Tasso di clic
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di clic', NOW() - INTERVAL '2 days', 0.45);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di clic', NOW(), 0.53);

-- Valutazione del Tasso di conversione
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di conversione', NOW() - INTERVAL '2 days', 0.12);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di conversione', NOW(), 0.09);

-- Valutazione del Tasso di disiscrizione
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di disiscrizione', NOW() - INTERVAL '2 days', 0.02);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di disiscrizione', NOW(), 0.01);

-- Valutazione del Tasso di forward e condivisione
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di forward e condivisione', NOW() - INTERVAL '2 days', 0.05);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di forward e condivisione', NOW(), 0.08);

-- Valutazione del Feedback
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Feedback', NOW() - INTERVAL '2 days', 0.85);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Feedback', NOW(), 0.88);

-- Valutazione dello Spaccato per device
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Spaccato per device', NOW() - INTERVAL '2 days', 0.68);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Spaccato per device', NOW(), 0.72);

-- Valutazione del Tasso di risposta
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di risposta', NOW() - INTERVAL '2 days', 0.03);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di risposta', NOW(), 0.02);

-- Valutazione del Tasso di crescita
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di crescita', NOW() - INTERVAL '2 days', 0.02);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (1, 'Tasso di crescita', NOW(), 0.03);

-- un pacchetto di valori di una newsletter passata della stessa azienda
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Tasso di apertura', '2022-12-31 00:00:00', 0.75);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Tasso di clic', '2022-12-31 00:00:00', 0.65);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Tasso di conversione', '2022-12-31 00:00:00', 0.5);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Tasso di disiscrizione', '2022-12-31 00:00:00', 0.1);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Tasso di forward e condivisione', '2022-12-31 00:00:00', 0.3);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Feedback', '2022-12-31 00:00:00', 0.8);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Spaccato per device', '2022-12-31 00:00:00', 0.6);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Tasso di risposta', '2022-12-31 00:00:00', 0.2);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (2, 'Tasso di crescita', '2022-12-31 00:00:00', 0.05);

-- un pacchetto di valori per una campagna in corso di un altra azienda
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Tasso di apertura', NOW(), 0.82);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Tasso di clic', NOW(), 0.71);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Tasso di conversione', NOW(), 0.55);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Tasso di disiscrizione', NOW(), 0.08);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Tasso di forward e condivisione', NOW(), 0.32);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Feedback', NOW(), 0.78);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Spaccato per device', NOW(), 0.63);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Tasso di risposta', NOW(), 0.15);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (3, 'Tasso di crescita', NOW(), 0.03);

-- un pacchetto di valori per una campagna passata di un altra azienda
INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Tasso di apertura', '2022-12-15 00:00:00', 0.75);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Tasso di clic', '2022-12-15 00:00:00', 0.62);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Tasso di conversione', '2022-12-15 00:00:00', 0.51);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Tasso di disiscrizione', '2022-12-15 00:00:00', 0.07);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Tasso di forward e condivisione', '2022-12-15 00:00:00', 0.29);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Feedback', '2022-12-15 00:00:00', 0.83);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Spaccato per device', '2022-12-15 00:00:00', 0.68);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Tasso di risposta', '2022-12-15 00:00:00', 0.19);

INSERT INTO VALUTAZIONE (newsletter, kpi, istante_calcolo, valore)
VALUES (6, 'Tasso di crescita', '2022-12-15 00:00:00', 0.02);



--Popolamento tabella COLLEZIONE: 2 per azienda, 1 dello scorso anno, e 1 di quello in corso
DELETE FROM COLLEZIONE;

-- Collezioni 2022
INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('12345678901', 'Collezione Inverno', 2022, 'Collezione invernale per Ferrari');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('23456789012', 'Collezione Estate', 2022, 'Collezione estiva per Dior');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('01236667890', 'Collezione Autunno', 2022, 'Collezione autunnale per Piazza Italia');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('45678901234', 'Collezione Primavera', 2022, 'Collezione primaverile per Zara');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('56789012345', 'Collezione Inverno', 2022, 'Collezione invernale per Burberry');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('67890123456', 'Collezione Estate', 2022, 'Collezione estiva per Gucci');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('78901234567', 'Collezione Autunno', 2022, 'Collezione autunnale per Etam');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('89012345678', 'Collezione Primavera', 2022, 'Collezione primaverile per Tom Tailor');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('90123456789', 'Collezione Inverno', 2022, 'Collezione invernale per Mango');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('01234567890', 'Collezione Estate', 2022, 'Collezione estiva per Boohoo');

-- Collezioni 2023
INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('12345678901', 'Collezione Estate', 2023, 'Collezione estiva per Ferrari');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('23456789012', 'Collezione Autunno', 2023, 'Collezione autunnale per Dior');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('01236667890', 'Collezione Primavera', 2023, 'Collezione primaverile per Piazza Italia');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('45678901234', 'Collezione Inverno', 2023, 'Collezione invernale per Zara');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('56789012345', 'Collezione Estate', 2023, 'Collezione estiva per Burberry');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('67890123456', 'Collezione Autunno', 2023, 'Collezione autunnale per Gucci');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('78901234567', 'Collezione Primavera', 2023, 'Collezione primaverile per Etam');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('89012345678', 'Collezione Inverno', 2023, 'Collezione invernale per Tom Tailor');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('90123456789', 'Collezione Estate', 2023, 'Collezione estiva per Mango');

INSERT INTO COLLEZIONE (azienda_fornitrice, nome, anno, descrizione)
VALUES ('01234567890', 'Collezione Autunno', 2023, 'Collezione autunnale per Boohoo');



--Popolamento tabella PRODOTTO: 2 per collezione
DELETE FROM PRODOTTO;
-- Prodotti per Collezioni 2022
-- Collezione Inverno 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (1, 'Maglia invernale', 4.3, TRUE, 'Uomo', 'Maglie');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (1, 'Giacca invernale', 4.8, TRUE, 'Donna', 'Giacche');

-- Collezione Estate 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (2, 'T-shirt estiva', 4.6, TRUE, 'Uomo', 'Maglie');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (2, 'Gonna estiva floreale', 4.2, TRUE, 'Donna', 'Gonne');

-- Collezione Autunno 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (3, 'Pantaloni autunnali', 4.5, TRUE, 'Uomo', 'Pantaloni');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (3, 'Camicia autunnale a quadri', 4.1, TRUE, 'Donna', 'Camicie');

-- Collezione Primavera 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (4, 'Vestito primaverile', 4.7, TRUE, 'Donna', 'Vestiti');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (4, 'Jeans primaverili a vita alta', 4.4, TRUE, 'Donna', 'Jeans');

-- Collezione Inverno 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (5, 'Scarpe invernali', 4.9, TRUE, 'Uomo', 'Scarpe');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (5, 'Maglia invernale', 4.3, TRUE, 'Donna', 'Maglie');

-- Collezione Estate 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (6, 'Giacca estiva leggera', 4.6, TRUE, 'Uomo', 'Giacche');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (6, 'Pantaloni estivi colorati', 4.2, TRUE, 'Donna', 'Pantaloni');

-- Collezione Autunno 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (7, 'Gonna autunnale a pieghe', 4.5, TRUE, 'Donna', 'Gonne');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (7, 'Camicia autunnale', 4.1, TRUE, 'Uomo', 'Camicie');

-- Collezione Primavera 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (8, 'Jeans primaverili strappati', 4.7, TRUE, 'Uomo', 'Jeans');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (8, 'Vestito primaverile a fiori', 4.4, TRUE, 'Donna', 'Vestiti');

-- Collezione Inverno 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (9, 'Maglia invernale', 4.9, TRUE, 'Uomo', 'Maglie');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (9, 'Giacca invernale', 4.3, TRUE, 'Donna', 'Giacche');

-- Collezione Estate 2022
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (10, 'T-shirt estiva', 4.6, TRUE, 'Uomo', 'Maglie');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (10, 'Gonna estiva a righe', 4.2, TRUE, 'Donna', 'Gonne');

-- Prodotti per Collezioni 2023
-- Collezione Estate 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (11, 'Scarpe estive', 4.9, TRUE, 'Uomo', 'Scarpe');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (11, 'Maglia estiva', 4.3, TRUE, 'Donna', 'Maglie');

-- Collezione Autunno 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (12, 'Giacca autunnale', 4.6, TRUE, 'Uomo', 'Giacche');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (12, 'Pantaloni autunnalii', 4.2, TRUE, 'Donna', 'Pantaloni');

-- Collezione Primavera 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (13, 'Vestito primaverile floreale', 4.7, TRUE, 'Donna', 'Vestiti');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (13, 'Jeans primaverili a zampa', 4.4, TRUE, 'Donna', 'Jeans');

-- Collezione Inverno 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (14, 'Maglia invernale', 4.9, TRUE, 'Uomo', 'Maglie');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (14, 'Giacca invernale', 4.3, TRUE, 'Donna', 'Giacche');

-- Collezione Estate 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (15, 'Giacca estiva leggera', 4.6, TRUE, 'Uomo', 'Giacche');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (15, 'Pantaloni estivi colorati', 4.2, TRUE, 'Donna', 'Pantaloni');

-- Collezione Autunno 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (16, 'Gonna autunnale a quadri', 4.5, TRUE, 'Donna', 'Gonne');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (16, 'Camicia autunnale', 4.1, TRUE, 'Uomo', 'Camicie');

-- Collezione Primavera 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (17, 'Jeans primaverili strappati', 4.7, TRUE, 'Uomo', 'Jeans');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (17, 'Vestito primaverile a righe', 4.4, TRUE, 'Donna', 'Vestiti');

-- Collezione Inverno 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (18, 'Maglia invernale', 4.9, TRUE, 'Uomo', 'Maglie');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (18, 'Giacca invernale', 4.3, TRUE, 'Donna', 'Giacche');

-- Collezione Estate 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (19, 'T-shirt estiva', 4.6, TRUE, 'Uomo', 'Maglie');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (19, 'Gonna estiva a pois', 4.2, TRUE, 'Donna', 'Gonne');

-- Collezione Autunno 2023
INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (20, 'Pantaloni autunnali', 4.5, TRUE, 'Uomo', 'Pantaloni');

INSERT INTO PRODOTTO (collezione, nome, voto_medio, disponibilita, sezione, categoria)
VALUES (20, 'Camicia autunnale a righe', 4.1, TRUE, 'Donna', 'Camicie');



--Popolamento tabella COLORE: 10 colori
DELETE FROM COLORE;

INSERT INTO COLORE (nome) 
VALUES ('Rosso');

INSERT INTO COLORE (nome) 
VALUES ('Verde');

INSERT INTO COLORE (nome) 
VALUES ('Blu');

INSERT INTO COLORE (nome) 
VALUES ('Giallo');

INSERT INTO COLORE (nome) 
VALUES ('Arancione');

INSERT INTO COLORE (nome) 
VALUES ('Viola');

INSERT INTO COLORE (nome) 
VALUES ('Nero');

INSERT INTO COLORE (nome) 
VALUES ('Bianco');

INSERT INTO COLORE (nome) 
VALUES ('Grigio');

INSERT INTO COLORE (nome) 
VALUES ('Marrone');


--Popolamento tabella COLORI ASSORTITI: 1 o 2 per prodotto
DELETE FROM COLORI_ASSORTITI;

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (1, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (2, 'Blu');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (3, 'Rosso');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (3, 'Verde');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (4, 'Viola');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (5, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (6, 'Verde');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (7, 'Rosso');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (7, 'Blu');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (8, 'Bianco');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (9, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (10, 'Verde');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (11, 'Blu');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (11, 'Giallo');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (12, 'Arancione');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (12, 'Viola');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (13, 'Nero');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (13, 'Bianco');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (14, 'Grigio');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (15, 'Marrone');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (16, 'Rosso');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (16, 'Blu');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (17, 'Giallo');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (18, 'Verde');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (19, 'Rosso');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (20, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (21, 'Blu');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (22, 'Verde');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (22, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (23, 'Rosso');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (23, 'Giallo');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (24, 'Viola');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (24, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (25, 'Blu');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (25, 'Bianco');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (26, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (27, 'Blu');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (28, 'Rosso');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (28, 'Giallo');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (29, 'Viola');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (30, 'Blu');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (30, 'Bianco');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (31, 'Arancione');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (31, 'Verde');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (32, 'Bianco');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (33, 'Blu');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (34, 'Rosso');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (35, 'Nero');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (36, 'Giallo');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (37, 'Viola');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (37, 'Bianco');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (38, 'Blu');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (38, 'Giallo');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (39, 'Giallo');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (39, 'Verde');

INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (40, 'Grigio');
INSERT INTO COLORI_ASSORTITI (prodotto, colore)
VALUES (40, 'Marrone');


--Popolamento tabella TAGLIA: dalla XXS alla 3XL
DELETE FROM TAGLIA;

INSERT INTO TAGLIA (sigla)
VALUES ('XXS');

INSERT INTO TAGLIA (sigla)
VALUES ('XS');

INSERT INTO TAGLIA (sigla)
VALUES ('S');

INSERT INTO TAGLIA (sigla)
VALUES ('M');

INSERT INTO TAGLIA (sigla)
VALUES ('L');

INSERT INTO TAGLIA (sigla)
VALUES ('XL');

INSERT INTO TAGLIA (sigla)
VALUES ('XXL');

INSERT INTO TAGLIA (sigla)
VALUES ('3XL');

--Popolamento tabella TAGLIE ASSORTITE: 1 o 2 per prodotto
DELETE FROM TAGLIE_ASSORTITE;

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (1, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (2, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (2, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (3, 'L');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (4, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (4, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (5, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (6, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (6, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (7, 'L');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (8, 'S');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (8, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (9, 'XL');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (10, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (10, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (11, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (12, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (12, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (13, 'L');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (14, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (14, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (15, 'XL');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (16, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (16, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (17, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (18, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (18, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (19, 'L');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (20, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (20, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (21, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (22, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (22, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (23, 'XL');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (24, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (24, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (25, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (26, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (26, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (27, 'L');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia)
VALUES (28, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (28, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (29, 'XL');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (30, 'S');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (30, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (31, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia)
VALUES (32, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (32, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (33, 'L');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (34, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (34, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (35, 'XL');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (36, 'S');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (36, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (37, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (38, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (38, 'M');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (39, 'XL');

INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (40, 'S');
INSERT INTO TAGLIE_ASSORTITE (prodotto, taglia) 
VALUES (40, 'M');



--Popolamento tabella ISCRIZIONE: 4 utenti per newsletter
DELETE FROM ISCRIZIONE;

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (1, 'user1', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (1, 'user2', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (1, 'user3', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (1, 'user4', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (2, 'user3', '2022-11-30');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (2, 'user4', '2022-11-30');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (2, 'user5', '2022-11-30');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (2, 'user6', '2022-11-30');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (3, 'user5', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (3, 'user6', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (3, 'user7', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (3, 'user8', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (4, 'user7', '2022-05-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (4, 'user8', '2022-05-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (4, 'user9', '2022-05-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (4, 'user10', '2022-05-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (5, 'user9', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (5, 'user10', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (5, 'user11', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (5, 'user12', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (6, 'user11', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (6, 'user12', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (6, 'user13', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (6, 'user14', '2022-10-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (7, 'user13', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (7, 'user14', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (7, 'user15', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (7, 'user16', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (8, 'user15', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (8, 'user16', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (8, 'user17', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (8, 'user18', '2022-08-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (9, 'user17', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (9, 'user18', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (9, 'user19', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (9, 'user20', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (10, 'user19', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (10, 'user20', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (10, 'user21', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (10, 'user22', '2022-10-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (11, 'user21', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (11, 'user22', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (11, 'user23', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (11, 'user24', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (12, 'user23', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (12, 'user24', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (12, 'user25', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (12, 'user26', '2022-10-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (13, 'user25', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (13, 'user26', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (13, 'user27', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (13, 'user28', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (14, 'user27', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (14, 'user28', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (14, 'user29', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (14, 'user30', '2022-08-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (15, 'user29', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (15, 'user30', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (15, 'user31', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (15, 'user1', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (16, 'user31', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (16, 'user1', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (16, 'user2', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (16, 'user3', '2022-08-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (17, 'user2', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (17, 'user3', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (17, 'user4', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (17, 'user5', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (18, 'user4', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (18, 'user5', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (18, 'user6', '2022-08-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (18, 'user7', '2022-08-31');

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (19, 'user6', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (19, 'user7', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (19, 'user8', CURRENT_DATE);
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (19, 'user9', CURRENT_DATE);

INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (20, 'user8', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (20, 'user9', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (20, 'user10', '2022-10-31');
INSERT INTO ISCRIZIONE (newsletter, utente, data_iscrizione)
VALUES (20, 'user11', '2022-10-31');



--Popolamento tabella PUBBLICIZZA: ogni azienda pubblicizza la propria colelzione, tranne Zalando che pubblicizza basandosi sulla collezione
DELETE FROM PUBBLICIZZA;

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (1, 11);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (2, 1);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (3, 12);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (4, 2);

--Campagna Zalando Pimavera 2023
INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (5, 13);
INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (5, 17);

--Campagna Zalando Autunno 2022
INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (6, 3);
INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (6, 7);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (7, 14);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (8, 4);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (9, 15);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (10, 5);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (11, 16);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (12, 6);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (13, 17);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (14, 7);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (15, 18);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (16, 8);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (17, 19);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (18, 9);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (19, 20);

INSERT INTO PUBBLICIZZA (campagna, collezione)
VALUES (20, 10);