/*

 ###### Valda entiteter: Agent, Hjälpmedel, Fältagent, Gruppledare, Operation, Incident, Rapport ######

Agent(PKEY [Namn, Nr], Lön, Ursprungligt_namn) 
Agent.Fältagent(Kompetens, Specialite, *Totalt antal operationer, *Antal lyckade operationer)
-> SAMBANDSTABELL FÄLTAGENTER_I_OPERATIONER(PKEY[Agent.Namn, Agent.Nr, Operation.Kodnamntyp, Operation.Startdatum, Incident.Namn, Incident.Nr])

Agent.Gruppledare(*Antal operationer med lyckad utgång, *Antal operationer, *%lyckade operationer) 

Hjälpmedel(PKEY[Namn, Nr], Beskrivning)
-> SAMBANDSTABELL FÄLTAGENTERS_FAVORITHJÄLPMEDEL(Hjälpmedel.Namn, Hjälpmedel.Nr, Fältagent.Namn, Fältagent.Nr)
-> SAMBANDSTABELL HJÄLPMEDEL_I_OPERATIONER(Hjälpmede.Namn, Hjälpmedel.Nr, Operation.Kodnamntyp, Operation.Slutdatum, Incident.Namn, Incident.Nr)

Operation(PKEY[Kodnamntyp, Startdatum, Incident], Slutdatum, Sucessrate) -> FK[Gruppledare]

Incident(PKEY[Namn], PKEY[Nr], Plats, *Medelvärde observationers grad)

Rapport(PKEY[Datm, Titel], *Radantal, *Antal_uppföljningar) FK[Incident + Agent]

*/

drop database a15oloal;
create database a15oloal;
use a15oloal;

# Här väljs incidentnamn som primary key, och nr som möjlig kandidatnyckel.
create table Incident(
    Namn varchar(30),
    Nr int UNIQUE NOT NULL,
    Plats varchar(30) NOT NULL,
    primary key(Namn)
)engine=innodb;

CREATE INDEX INCIDENTNUMMER ON Incident(Nr ASC) USING BTREE;

# Extra tabell för att lagra ordningsnummer och typ av redskap för olika typer. Typkod är kod för objektet. Minskar redundans i Hjälpmedel.
create table Hjälpmedelstyper(
	Typkod smallint,
    Ordningsnummer tinyint(2),
    Typ varchar(20),
    CHECK(Ordningsnummer >= 1 AND Ordningsnummer <= 15),
    primary key(Typkod, Ordningsnummer)
)engine=innodb;

create table Hjälpmedel(
	Namn varchar(20),
    Nr smallint,
    Beskrivning varchar(30),
    Typkod smallint,
    Ordningsnummer tinyint(2),
    primary key(Namn, Nr),
    foreign key(Typkod, Ordningsnummer) references Hjälpmedelstyper(Typkod, Ordningsnummer)
)engine=innodb;

create table Gruppledare(
	Namn char(1),
    Nr tinyint(2),
    Lön int,
    Förnamn varchar(25),
    Efternamn varchar(25),
    lyckade_operationer int,
    n_operationer int,
    andel_lyckade_op decimal(3, 2),
    CHECK(NOT (Förnamn = 'Leif Loket' AND Efternamn = 'Olsson') OR NOT (Förnamn = 'Greger' AND Efternamn = 'Puckowitz') OR NOT (Förnamn = 'Greve' AND Efternamn = 'Dracula')),
    CHECK(Lön >= 12000 AND Lön <= 35000),
    CHECK(Nr >= 0 AND Nr != 13 AND Nr <= 99),
    CHECK(lyckade_operationer >= 0),
    primary key(Namn, Nr)
)engine=innodb;

/* Trigger to set Lön to 13k if no value is inserted on Gruppledare. */
DELIMITER //
 
CREATE TRIGGER LÖNECHECK_Gruppledare BEFORE INSERT ON Gruppledare
FOR EACH ROW BEGIN
 
  IF(NEW.Lön IS NULL) THEN
    SET NEW.Lön=13000;
  END IF;
 
END;
 
//
DELIMITER ;


create table Fältagent(
	Namn char(1),
    Nr tinyint(2),
    Lön int,
    Förnamn varchar(25),
    Efternamn varchar(25),
    Kompetens varchar(30) NOT NULL,
    Specialite varchar(30) NOT NULL,
    CHECK(Lön >= 12000 AND Lön <= 25000),
    CHECK(NOT(Förnamn = 'Leif Loket' AND Efternamn = 'Olsson') OR NOT (Förnamn = 'Greger' AND Efternamn = 'Puckowitz') OR NOT (Förnamn = 'Greve' AND Efternamn = 'Dracula')),
    CHECK(Nr > 0 AND Nr != 13 AND Nr <= 99),
    CHECK(lyckade_operationer >= 0),
    primary key(Namn, Nr)
)engine=innodb;

# INDEX FOR QUERY SELECT Namn, Nummer, Specialite, Kompetens FROM Fältagent ORDER BY Kompetens; 
CREATE INDEX Fältagentinfo ON Fältagent(Namn, Nr, Specialite, Kompetens ASC) USING BTREE;

/* Trigger to set Lön to 13k if no value is inserted on Fältagent. */
DELIMITER //
 
CREATE TRIGGER LÖNECHECK_Fältagent BEFORE INSERT ON Fältagent
FOR EACH ROW BEGIN
 
  IF(NEW.Lön IS NULL) THEN
    SET NEW.Lön=13000;
  END IF;
 
END;
 
//
DELIMITER ;

create table Operation_Pågående(
    Kodnamn char(3),
    Operationstyp varchar(40),
    Startdatum date,
    Slutdatum date,
    Incidentnamn varchar(30),
    Gruppledarnamn char(1),
    Gruppledarnr tinyint(2),
    Hjälpmedelnamn varchar(20),
    Hjälpmedelnr smallint,
    Fältagentnamn char(1),
    Fältagentnr tinyint(2),
    CHECK (Kodnamn LIKE '[A-Z][0-9][0-9]'),
    CHECK ((DAY(Slutdatum) > DAY(Startdatum) AND (YEAR(Slutdatum) = YEAR(Startdatum))) OR (YEAR(Slutdatum) > YEAR(Startdatum))),
    primary key(Kodnamn, Operationstyp, Startdatum, Incidentnamn, Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr),
    foreign key(Incidentnamn) references Incident(Namn),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr),
    foreign key(Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr),
    foreign key (Gruppledarnamn, Gruppledarnr) references Gruppledare(Namn, Nr)
)engine=innodb;

create table Operation_Avslutad(
    Kodnamn char(3),
    Operationstyp varchar(40),
    Startdatum date,
    Slutdatum date,
    Incidentnamn varchar(30),
    Sucess_Rate tinyint(1),
    Gruppledarnamn char(1),
    Gruppledarnr tinyint(2),
    Hjälpmedelnamn varchar(20),
    Hjälpmedelnr smallint,
    Fältagentnamn char(1),
    Fältagentnr tinyint(2),
    CHECK (Kodnamn LIKE '[A-Z][0-9][0-9]'),
    CHECK ((DAY(Slutdatum) > DAY(Startdatum) AND (YEAR(Slutdatum) = YEAR(Startdatum))) OR (YEAR(Slutdatum) > YEAR(Startdatum))),
    primary key(Kodnamn, Operationstyp, Startdatum, Incidentnamn, Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr),
    foreign key(Incidentnamn) references Incident(Namn),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr),
    foreign key(Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr),
    foreign key (Gruppledarnamn, Gruppledarnr) references Gruppledare(Namn, Nr)
)engine=innodb;
  
-- INDEX FOR QUERY SELECT * FROM Operation_Avslutad ORDER BY Slutdatum; 
CREATE INDEX Operationer_Slutdatum ON Operation_Avslutad(Slutdatum ASC) USING BTREE;


/* Trigger för att hantera om start- och slutdatum är mindre än 5 veckor mellan varandra */
DELIMITER //
 
CREATE TRIGGER DATUMCHECK_Operation_Pågående BEFORE INSERT ON Operation_Pågående
FOR EACH ROW BEGIN
 
  IF((WEEK(NEW.Slutdatum) - WEEK(NEW.Startdatum)) > 5 ) THEN
    SET NEW.Slutdatum = (DATE_ADD(NEW.Startdatum, INTERVAL 5 WEEK));
  END IF;
 
END;
 
//
DELIMITER ;

DELIMITER //
 
CREATE TRIGGER DATUMCHECK_Operation_Avslutad BEFORE INSERT ON Operation_Avslutad
FOR EACH ROW BEGIN
 
  IF((WEEK(NEW.Slutdatum) - WEEK(NEW.Startdatum)) > 5 ) THEN
    SET NEW.Slutdatum = (DATE_ADD(NEW.Startdatum, INTERVAL 5 WEEK));
  END IF;
 
END;
 
//
DELIMITER ;

create table Fältagenters_hjälpmedel(
	Hjälpmedelnamn varchar(20),
    Hjälpmedelnr smallint,
    Fältagentnamn char(1),
    Fältagentnr tinyint(2),
    primary key(Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr),
    foreign key(Hjälpmedelnamn, Hjälpmedelnr) references Hjälpmedel(Namn, Nr),
    foreign key(Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr)
)engine=innodb;

create table Slutrapport(
    Datum date,
    Titel varchar(30),
    n_rader int,
    Kommentar varchar(25),
    Fältagentnamn char(1),
    Fältagentnr tinyint(2),
    Gruppledarnamn char(1),
    Gruppledarnr tinyint(2),
    Incidentnamn varchar(30),
    CHECK(n_uppföljningar >= 0),
    CHECK((Typ = 'Ledningsrapport') OR (Typ = 'Fältrapport')),
    primary key(Datum, Titel),
    foreign key (Fältagentnamn, Fältagentnr) references Fältagent(Namn, Nr),
    foreign key (Gruppledarnamn, Gruppledarnr) references Gruppledare(Namn, Nr),
    foreign key (Incidentnamn) references Incident(Namn)
)engine=innodb;

/*Tabellen som lagrar loggar om incidentinsättningar*/
create table Incident_logg(
	Anvandarnamn varchar(25),
    Tid datetime,
	Namn varchar(30),
    Nr int UNIQUE NOT NULL,
    Plats varchar(30) NOT NULL,
    primary key(Namn)
)engine=innodb;

/*Loggar nya incidenter*/
DELIMITER //
CREATE TRIGGER Incident_Logg AFTER INSERT ON Incident
FOR EACH ROW BEGIN 
   INSERT INTO Incident_logg(Anvandarnamn,Tid,Namn,Nr,Plats) 
      values(USER(),NOW(),NEW.Namn,NEW.Nr,NEW.Plats);
END;
// DELIMITER ;

/* Incident "Ulvahändelsen" */
insert into Gruppledare (Namn, Nr, Lön, Förnamn, Efternamn) values ('A', 12, 26000, 'Richard', 'Lionmane');
insert into Fältagent (Namn, Nr, Lön, Förnamn, Efternamn, Specialite, Kompetens) values ('D', 18, 15500, 'Siegfried', 'Schultz', 'Krypskytte', 'Hög');
insert into Hjälpmedelstyper (Typkod, Ordningsnummer, Typ) values (5566, 1, 'Långdistansgevär');
insert into Hjälpmedel (Namn, Nr, Beskrivning, Typkod, Ordningsnummer) values ('AXD Sniper', 423, 'Amerikansk modell', 5566, 1);
insert into Fältagenters_hjälpmedel (Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr) values ('AXD Sniper', 423, 'D', 18);
insert into Incident (Namn, Nr, Plats) values ('Ulvahändelsen', 5, 'Töreboda');
insert into Operation_Pågående (Startdatum, Slutdatum, Incidentnamn, Gruppledarnamn, Gruppledarnr, Operationstyp, Kodnamn, Fältagentnamn, Fältagentnr, Hjälpmedelnamn, Hjälpmedelnr) values ('2017-01-01', '2017-05-05', 'Ulvahändelsen', 'A', 12, 'Uppstädningsoperation', 'ABD', 'D', 18, 'AXD Sniper', 423);

insert into Gruppledare (Namn, Nr, Lön, Förnamn, Efternamn) values ('B', 2, 29000, 'Peter', 'Bass');
insert into Fältagent (Namn, Nr, Lön, Förnamn, Efternamn, Specialite, Kompetens) values ('C', 4, 16000, 'Gottfried', 'Stark', 'Krypskytte', 'Låg');
insert into Hjälpmedelstyper (Typkod, Ordningsnummer, Typ) values (5566, 2, 'Långdistansgevär');
insert into Hjälpmedel (Namn, Nr, Beskrivning, Typkod, Ordningsnummer) values ('AXD Sniper', 425, 'Rysk modell', 5566, 2);
insert into Fältagenters_hjälpmedel (Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr) values ('AXD Sniper', 425, 'C', 4);
insert into Operation_Pågående (Operationstyp, Startdatum, Slutdatum, Incidentnamn, Gruppledarnamn, Gruppledarnr, Kodnamn, Fältagentnamn, Fältagentnr, Hjälpmedelnamn, Hjälpmedelnr) values ('Uppstädningsoperation', '2017-01-01', '2017-02-05', 'Ulvahändelsen', 'B', 2, 'ABC', 'C', 4, 'AXD Sniper', 425);

/* Incident "Läcköläckan" */
insert into Gruppledare (Namn, Nr, Lön, Förnamn, Efternamn) values ('T', 8, 8000, 'Wolfgang', 'Vlk');
insert into Fältagent (Namn, Nr, Lön, Förnamn, Efternamn, Specialite, Kompetens) values ('R', 6, 5000, 'Frida', 'Ekdahl', 'Manipulation', 'Medel');
insert into Hjälpmedelstyper (Typkod, Ordningsnummer, Typ) values (23, 1, 'Sanningsserum');
insert into Hjälpmedel (Namn, Nr, Beskrivning, Typkod, Ordningsnummer) values ('Klarvätska Pfizer', 156, 'Prövades under Ulvahändelsen', 23, 1);
insert into Hjälpmedelstyper (Typkod, Ordningsnummer, Typ) values (120, 1, 'Glock');
insert into Hjälpmedel (Namn, Nr, Beskrivning, Typkod, Ordningsnummer) values ('Pistol 88', 1010, 'Standardpistol', 120, 1);
insert into Fältagenters_hjälpmedel (Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr) values ('Klarvätska Pfizer', 156, 'R', 6);
insert into Fältagenters_hjälpmedel (Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr) values ('Pistol 88', 1010, 'R', 6);
insert into Incident (Namn, Nr, Plats) values ('Läcköläckan', 1888, 'Lidköping');
insert into Operation_Avslutad (Operationstyp, Startdatum, Slutdatum, Incidentnamn, Gruppledarnamn, Gruppledarnr, Kodnamn, Fältagentnamn, Fältagentnr, Hjälpmedelnamn, Hjälpmedelnr, Sucess_Rate) values ('Desinformationsuppdrag', '2011-06-22', '2011-06-29', 'Läcköläckan', 'T', 8, 'DRR', 'R', 6, 'Klarvätska Pfizer', 156, 1);
insert into Operation_Avslutad (Operationstyp, Startdatum, Slutdatum, Incidentnamn, Gruppledarnamn, Gruppledarnr, Kodnamn, Fältagentnamn, Fältagentnr, Hjälpmedelnamn, Hjälpmedelnr, Sucess_Rate) values ('Desinformationsuppdrag', '2011-06-22', '2011-06-29', 'Läcköläckan', 'T', 8, 'DRR', 'R', 6, 'Pistol 88', 1010, 1);

insert into Slutrapport (Datum, Titel, n_rader, Kommentar, Fältagentnamn, Fältagentnr, Gruppledarnamn, Gruppledarnr, Incidentnamn) values ('2011-06-29', 'Läcköchefen förhörd', 10, 'All info erhölls', 'R', 6, 'T', 8, 'Läcköläckan');

/* Incident "Annunakimötet" */
insert into Gruppledare (Namn, Nr, Lön, Förnamn, Efternamn) values ('E', 14, 29550, 'Hermann', 'Brandt');
insert into Fältagent (Namn, Nr, Lön, Förnamn, Efternamn, Specialite, Kompetens) values ('G', 89, 22300, 'Freja', 'Stenhammar', 'Strategisk analys', 'Hög');
insert into Fältagent (Namn, Nr, Lön, Förnamn, Efternamn, Specialite, Kompetens) values ('G', 88, 20100, 'Sven', 'Persson', 'Personskydd', 'Medel');
insert into Hjälpmedelstyper (Typkod, Ordningsnummer, Typ) values (45, 1, 'Satelitdator');
insert into Hjälpmedel (Namn, Nr, Beskrivning, Typkod, Ordningsnummer) values ('Satelitdator', 189, 'Oberoende av marknät', 45, 1);
insert into Hjälpmedelstyper (Typkod, Ordningsnummer, Typ) values (120, 2, 'Glock');
insert into Hjälpmedel (Namn, Nr, Beskrivning, Typkod, Ordningsnummer) values ('Pistol 88', 1011, 'Standardpistol', 120, 2);
insert into Fältagenters_hjälpmedel (Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr) values ('Satelitdator', 189, 'G', 89);
insert into Fältagenters_hjälpmedel (Hjälpmedelnamn, Hjälpmedelnr, Fältagentnamn, Fältagentnr) values ('Pistol 88', 1011, 'G', 88);
insert into Incident (Namn, Nr, Plats) values ('Annunakimötet', 1566, 'Kungsbacka');
insert into Operation_Avslutad (Operationstyp, Startdatum, Slutdatum, Incidentnamn, Gruppledarnamn, Gruppledarnr, Kodnamn, Fältagentnamn, Fältagentnr, Hjälpmedelnamn, Hjälpmedelnr, Sucess_Rate) values ('Diplomatiskt möte', '2016-07-15', '2016-07-16', 'Annunakimötet', 'E', 14, 'TRI', 'G', 89, 'Satelitdator', 189, 1);
insert into Operation_Avslutad (Operationstyp, Startdatum, Slutdatum, Incidentnamn, Gruppledarnamn, Gruppledarnr, Kodnamn, Fältagentnamn, Fältagentnr, Hjälpmedelnamn, Hjälpmedelnr, Sucess_Rate) values ('Diplomatiskt möte', '2016-07-15', '2016-07-16', 'Annunakimötet', 'E', 14, 'TRI', 'G', 88, 'Pistol 88', 1011, 1);

insert into Slutrapport (Datum, Titel, n_rader, Kommentar, Fältagentnamn, Fältagentnr, Gruppledarnamn, Gruppledarnr, Incidentnamn) values ('2011-07-17', 'Möte med Annunaki', 20, 'Inga fler besök', 'G', 89, 'E', 14, 'Annunakimötet');

/* Incident "Kinnekullechocken */
insert into Incident (Namn, Nr, Plats) values ('Kinnekullechocken', 1288, 'Götene');
insert into Operation_Avslutad (Operationstyp, Startdatum, Slutdatum, Incidentnamn, Gruppledarnamn, Gruppledarnr, Kodnamn, Fältagentnamn, Fältagentnr, Hjälpmedelnamn, Hjälpmedelnr, Sucess_Rate) values ('Vittnestystnad', '2013-12-24', '2014-01-2', 'Kinnekullechocken', 'E', 14, 'XXT', 'G', 88, 'Pistol 88', 1011, 0);

insert into Slutrapport (Datum, Titel, n_rader, Kommentar, Fältagentnamn, Fältagentnr, Gruppledarnamn, Gruppledarnr, Incidentnamn) values ('2014-01-09', 'Läcka till press', 10, 'SvD skrev artikel', 'G', 88, 'E', 14, 'Kinnekullechocken');

/*
select * from Gruppledare;
select * from Fältagent;
select * from Incident;
select * from Incident_logg;
select * from Hjälpmedelstyper;
SELECT * FROM Hjälpmedel;
SELECT * FROM Fältagenters_hjälpmedel;
SELECT * FROM Operation_Pågående;
SELECT * FROM Operation_Avslutad;
SELECT * FROM Slutrapport;
*/

/* CREATING USER RIGHTS FOR THE SYSTEM */

/*** USER GRUPPLEDARE ***/
# Create a user for the gruppledare application
drop user 'gruppledare'@'localhost';
flush privileges;
CREATE USER 'gruppledare'@'localhost' IDENTIFIED BY 'password';
 
# Gives select & update access to Fältagent table to gruppledare
GRANT SELECT, UPDATE ON a15oloal.Fältagent TO gruppledare;

# Gives select & update, insert access to Operation, Slutrapport & Incident tables to gruppledare
GRANT SELECT, UPDATE, INSERT ON a15oloal.Operation_Pågående TO gruppledare;
GRANT SELECT, UPDATE, INSERT ON a15oloal.Operation_Avslutad TO gruppledare;
GRANT SELECT, UPDATE, INSERT ON a15oloal.Incident TO gruppledare;
GRANT SELECT, INSERT ON a15oloal.Slutrapport TO gruppledare;

# Gives select & update, insert, delete access to Hjälpmedel, operationers_hjälpmedel & Fältagenters_hjälpmedel tables to gruppledare
GRANT SELECT, UPDATE, INSERT ON a15oloal.Hjälpmedel TO gruppledare;
GRANT SELECT, UPDATE, INSERT ON a15oloal.Hjälpmedelstyper TO gruppledare;
GRANT SELECT, UPDATE, INSERT ON a15oloal.Fältagenters_hjälpmedel TO gruppledare;

 
# Create a view that permits access to gruppledare.namn
CREATE VIEW GRUPPLEDARE AS SELECT Namn, lyckade_operationer, n_operationer, andel_lyckade_op FROM Gruppledare;
 
# Give select permission to gruppledare in the GRUPPLEDARE view
GRANT SELECT ON a15oloal.GRUPPLEDARE to gruppledare;

/***** USER FÄLTAGENT *****/
# Create a user for the fältagent application
drop user 'fältagent'@'localhost';
CREATE USER 'fältagent'@'localhost' IDENTIFIED BY 'password';
 
 # Create a view that permits access to gruppledare.namn
CREATE VIEW GRUPPLEDARNAMN AS SELECT Namn FROM Gruppledare; 
# Gives select access to FÄLT_GRUPPLEDARE VIEW to Fältagent
GRANT SELECT ON a15oloal.GRUPPLEDARNAMN TO fältagent;

 # Create a view that permits access to historic operations
CREATE VIEW FÄLT_OPERATION AS SELECT Kodnamn, Operationstyp, Startdatum, Incidentnamn, Slutdatum, Sucess_Rate, Gruppledarnamn 
FROM Operation_Avslutad;
# Gives select access to FÄLT_OPERATION VIEW to Fältagent
GRANT SELECT ON a15oloal.FÄLT_OPERATION TO fältagent;

# Create a view of historic incidents
CREATE VIEW 
	HISTORISKA_INCIDENTER
AS
	SELECT Namn, Incidentnamn
    FROM Incident, Operation_Avslutad
    WHERE Incident.Namn = Operation_Avslutad.Incidentnamn;

# Grant all privileges on the view to fältagent user
GRANT ALL ON HISTORISKA_INCIDENTER TO fältagent;

# Gives access to insert and select Slutrapport table to Fältagent
GRANT SELECT, INSERT ON a15oloal.Slutrapport TO fältagent;

# Gives select access to Fältagenters_operationer table to Fältagent 						 Hur ska jag skapa den här lösningen?
/*CREATE VIEW TEAM_OPERATION AS SELECT * ON a15oloal.Fältagenters_hjälpmedel TO fältagent
WHERE Fältagenters_hjälpmedel.Fältagentnamn = user() AND Fältagenters_hjälpmedel.Fältagentnr = user(); */

CREATE VIEW
	AGENT_HÄRLEDD
AS
	SELECT Fältagentnamn, Fältagentnr, CONCAT(CAST((AVG(Sucess_Rate)*100) as DECIMAL(3, 0)), ' %') AS 'Lyckade Operationer', 
    COUNT(Kodnamn) AS 'Antal Operationer'
    FROM Operation_Avslutad
    GROUP BY Fältagentnr;

select * from Fältagent;
select * from Operation_Avslutad;
select * from AGENT_HÄRLEDD

/* Procedur för att snabbt höja lön */
DELIMITER //

CREATE PROCEDURE BONUS(procent TINYINT, gräns int)

BEGIN
	SET SQL_SAFE_UPDATES = 0;
	UPDATE Fältagent
	SET Lön = Lön + (Lön * (procent/100))
    WHERE Lön < gräns;
END;
//

DELIMITER ;

CALL BONUS(10, 60000);
