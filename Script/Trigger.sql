-- CREAZIONE TRIGGER
-- TRIGGER PER LE CARDINALITA' MINIME
-- Gestione cardinalità minima in CAMPAGNA (1,N) PUBBLICIZZA (1,N) COLLEZIONE
CREATE OR REPLACE FUNCTION almenoUnPubblicizza() RETURNS TRIGGER AS $$
BEGIN
IF (EXISTS (SELECT codice FROM campagna_pubblicitaria
	WHERE codice NOT IN (SELECT campagna FROM pubblicizza))) THEN
	RAISE EXCEPTION 'ERRORE CAMPAGNA (1,N) PUBBLICIZZA';
END IF;
IF (EXISTS (SELECT id FROM collezione
	WHERE id NOT IN (SELECT collezione FROM pubblicizza))) THEN
	RAISE EXCEPTION 'ERRORE COLLEZIONE (1,N) PUBBLICIZZA';
END IF;
RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS triggerAlmenoUnPubblicizza1 ON campagna_pubblicitaria;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnPubblicizza1
AFTER INSERT ON campagna_pubblicitaria
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnPubblicizza();

DROP TRIGGER IF EXISTS triggerAlmenoUnPubblicizza2 ON collezione;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnPubblicizza2
AFTER INSERT ON collezione
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnPubblicizza();

DROP TRIGGER IF EXISTS triggerAlmenoUnPubblicizza ON pubblicizza;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnPubblicizza
AFTER DELETE OR UPDATE ON pubblicizza
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnPubblicizza();


-- Gestione cardinalità minima in AZIENDA (1,N) RECAPITO (1,1) NUMERO_TELEFONICO
CREATE OR REPLACE FUNCTION almenoUnRecapito() RETURNS TRIGGER AS $$
BEGIN
IF (EXISTS (SELECT partita_IVA FROM azienda
	WHERE partita_IVA NOT IN (SELECT azienda FROM numero_telefonico))) THEN
	RAISE EXCEPTION 'ERRORE AZIENDA (1,N) RECAPITO';
END IF;
RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS triggerAlmenoUnRecapito1 ON azienda;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnRecapito1
AFTER INSERT ON azienda
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnRecapito();

DROP TRIGGER IF EXISTS triggerAlmenoUnRecapito2 ON numero_telefonico;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnRecapito2
AFTER DELETE OR UPDATE ON numero_telefonico
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnRecapito();


-- Gestione cardinalità minima in COLLEZIONE (1,N) COMPOSIZIONE (1,1) PRODOTTO
CREATE OR REPLACE FUNCTION almenoUnaComposizione() RETURNS TRIGGER AS $$
BEGIN
IF (EXISTS (SELECT id FROM collezione
	WHERE id NOT IN (SELECT collezione FROM prodotto))) THEN
	RAISE EXCEPTION 'ERRORE COLLEZIONE (1,N) COMPOSIZIONE';
END IF;
RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS triggerAlmenoUnaComposizione1 ON collezione;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnaComposizione1
AFTER INSERT ON collezione
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnaComposizione();

DROP TRIGGER IF EXISTS triggerAlmenoUnaComposizione2 ON prodotto;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnaComposizione2
AFTER DELETE OR UPDATE ON prodotto
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnaComposizione();


-- Gestione cardinalità minima in PRODOTTO (1,N) COLORI_ASSORTITI (0,N) COLORE
CREATE OR REPLACE FUNCTION almenoUnColore() RETURNS TRIGGER AS $$
BEGIN
IF (EXISTS (SELECT id FROM prodotto
	WHERE id NOT IN (SELECT prodotto FROM colori_assortiti))) THEN
	RAISE EXCEPTION 'ERRORE PRODOTTO (1,N) COLORI_ASSORTITI';
END IF;
RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS triggerAlmenoUnColore1 ON prodotto;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnColore1
AFTER INSERT ON prodotto
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnColore();

DROP TRIGGER IF EXISTS triggerAlmenoUnColore2 ON colori_assortiti;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnColore2
AFTER DELETE OR UPDATE ON colori_assortiti
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnColore();


-- Gestione cardinalità minima in PRODOTTO (1,N) TAGLIE_ASSORTITE (0,N) TAGLIA
CREATE OR REPLACE FUNCTION almenoUnaTaglia() RETURNS TRIGGER AS $$
BEGIN
IF (EXISTS (SELECT id FROM prodotto
	WHERE id NOT IN (SELECT prodotto FROM taglie_assortite))) THEN
	RAISE EXCEPTION 'ERRORE PRODOTTO (1,N) TAGLIE_ASSORTITE';
END IF;
RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS triggerAlmenoUnaTaglia1 ON prodotto;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnaTaglia1
AFTER INSERT ON prodotto
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnaTaglia();

DROP TRIGGER IF EXISTS triggerAlmenoUnaTaglia2 ON taglie_assortite;
CREATE CONSTRAINT TRIGGER triggerAlmenoUnaTaglia2
AFTER DELETE OR UPDATE ON taglie_assortite
DEFERRABLE INITIALLY DEFERRED
FOR EACH ROW EXECUTE PROCEDURE almenoUnaTaglia();


-- Gestione ridondanza numero_iscritti (NEWSLETTER)
CREATE OR REPLACE FUNCTION aggiornaRidondanza() RETURNS TRIGGER AS $$
BEGIN
IF (NEW IS NOT NULL) THEN
	UPDATE newsletter SET numero_iscritti=0 WHERE campagna=NEW.newsletter;
END IF;
IF (OLD IS NOT NULL) THEN
	UPDATE newsletter SET numero_iscritti=0 WHERE campagna=OLD.newsletter;
END IF;
RETURN NULL; 
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TriggerAggiornaRidondanza ON newsletter;
CREATE TRIGGER TriggerAggiornaRidondanza
AFTER INSERT OR DELETE OR UPDATE OF newsletter ON iscrizione
FOR EACH ROW
EXECUTE PROCEDURE aggiornaRidondanza();

CREATE OR REPLACE FUNCTION proteggiRidondanza() RETURNS TRIGGER AS $$
BEGIN
SELECT COUNT(*) INTO NEW.numero_iscritti
FROM iscrizione WHERE newsletter = NEW.campagna;
RETURN NEW;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TriggerProteggiRidondanza ON newsletter;
CREATE TRIGGER TriggerProteggiRidondanza
BEFORE INSERT OR UPDATE OF numero_iscritti ON newsletter
FOR EACH ROW
EXECUTE PROCEDURE proteggiRidondanza();


-- Trigger per il controllo dei vincoli aziendali (RV9) ed (RV10)
-- Zalando deve pubblicizzare una o più collezioni con stesso nome e anno,
-- le altre aziende devono pubblicizzare una sola collezione fornita da loro stesse
CREATE OR REPLACE FUNCTION controlloCampagna() RETURNS TRIGGER AS $$
BEGIN
IF (EXISTS (SELECT azienda_committente FROM campagna_pubblicitaria
		 WHERE codice = NEW.campagna
 AND azienda_committente = '02986180210')) THEN
	IF (EXISTS (SELECT C.nome, C.anno FROM pubblicizza AS P
   			 JOIN collezione AS C ON P.collezione = C.id
			 WHERE NEW.campagna = P.campagna AND
    			 (C.nome <>
 (SELECT nome FROM collezione WHERE id = NEW.collezione)      OR C.anno <>
          (SELECT anno FROM collezione WHERE id = NEW.collezione)))) THEN
RAISE EXCEPTION 'ERRORE CAMPAGNE DI ZALANDO DEVONO PUBBLICIZZARE CAMPAGNE CON NOME E ANNO UGUALI';
	END IF;
END IF;
IF (EXISTS (SELECT azienda_committente FROM campagna_pubblicitaria
		 WHERE codice = NEW.campagna
            AND azienda_committente <> '02986180210')) THEN
	IF ((SELECT count(*) FROM pubblicizza
           WHERE campagna = NEW.campagna) > 1) THEN
RAISE EXCEPTION 'ERRORE CAMPAGNE NON DI ZALANDO DEVONO PUBBLICIZZARE UNA SOLA COLLEZIONE';
	END IF;
	IF ((SELECT azienda_committente FROM campagna_pubblicitaria
WHERE codice = NEW.campagna) <> (SELECT azienda_fornitrice FROM collezione WHERE id = NEW.collezione)) THEN
RAISE EXCEPTION 'ERRORE CAMPAGNE NON DI ZALANDO DEVONO PUBBLICIZZARE COLLEZIONI PROPRIE';
	END IF;
END IF;
RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TriggerControlloCampagna ON pubblicizza;
CREATE TRIGGER TriggerControlloCampagna
AFTER INSERT OR UPDATE ON pubblicizza
FOR EACH ROW
EXECUTE PROCEDURE controlloCampagna();


-- Trigger per il controllo del vincolo aziendale (R2)
-- Gli utenti non possono iscriversi o disiscriversi da una newsletter associata ad una campagna conclusa
CREATE OR REPLACE FUNCTION vietaIscrizioniDisiscrizioni() RETURNS TRIGGER AS $$
BEGIN
IF (NEW IS NOT NULL) THEN
	IF ((SELECT CP.data_fine FROM campagna_pubblicitaria CP
	     WHERE CP.codice = NEW.newsletter) IS NOT NULL) THEN
		RAISE EXCEPTION 'ERRORE ISCRIZIONE/DISISCRIZIONE A CAMPAGNA CONCLUSA';
	END IF;
END IF;
IF (OLD IS NOT NULL) THEN
	IF ((SELECT CP.data_fine FROM campagna_pubblicitaria CP
	     WHERE CP.codice = OLD.newsletter) IS NOT NULL) THEN
		RAISE EXCEPTION 'ERRORE ISCRIZIONE/DISISCRIZIONE A CAMPAGNA CONCLUSA';
	END IF;
END IF;
RETURN NULL;
END $$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS TriggerVietaIscrizioniDisiscrizioni ON iscrizione;
CREATE TRIGGER TriggerVietaIscrizioniDisiscrizioni
AFTER INSERT OR UPDATE OR DELETE ON iscrizione
FOR EACH ROW
EXECUTE PROCEDURE vietaIscrizioniDisiscrizioni();